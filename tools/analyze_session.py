"""Turn a session_*.jsonl into the richer analysis AI_PLAYTEST_PLAN.md's
slice 5 asks for, rather than just the summary line slices 1-4 printed.

Not a script in its own right -- imported by run_scenario.py. Kept
separate because it's pure parsing/aggregation with no subprocess or
Godot-path concerns, unlike run_scenario.py.
"""

from __future__ import annotations

import json
from pathlib import Path
from typing import Any


def load_entries(session_file: Path) -> list[dict[str, Any]]:
    entries: list[dict[str, Any]] = []
    with session_file.open(encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            entries.append(json.loads(line))
    return entries


def analyze(entries: list[dict[str, Any]]) -> dict[str, Any]:
    """One run's entries -> the analysis dict slice 5 asks for.

    Kept as plain dicts/lists (not a class) so a batch run can hand a list
    of these straight to json.dumps or to aggregate_runs() below.
    """
    config = next((e for e in entries if e["type"] == "config"), None)
    settings: dict[str, Any] = config["settings"] if config else {}
    snapshots = [e for e in entries if e["type"] == "snapshot"]
    deaths = [e for e in entries if e["type"] == "death"]
    actions = [e for e in entries if e["type"] == "action"]
    summary = next((e for e in entries if e["type"] == "summary"), None)

    return {
        "population_curve": _population_curve(snapshots),
        "deaths_over_time": _deaths_over_time(deaths),
        "honey_fill_vs_winter": _honey_fill_vs_winter(snapshots),
        "flower_mix_by_day": _flower_mix_by_day(snapshots),
        "milestones": _milestones(snapshots, settings),
        "milestone_times": _milestone_times(snapshots, settings),
        "alpha_route": _alpha_route(snapshots),
        "mechanic_firing": _mechanic_firing(settings, summary, actions),
        "actions": _action_summary(actions),
        "summary": summary,
    }


def _last_snapshot_per_day(snapshots: list[dict[str, Any]]) -> list[dict[str, Any]]:
    """One snapshot per in-game day (the last one seen for that day),
    instead of every snapshot in the file.

    A day-resolution curve is all population/rate charts actually need --
    the numbers barely move between one snapshot and the next at the
    hourly cadence a normal run logs at, and a compressed-day test
    scenario (see DiagnosticLog.snapshot_interval_override) can log
    dozens of snapshots per day, which used to mean --full's output (and
    the token cost of reading it) scaled with how compressed the test's
    days were rather than with anything informative.
    """
    by_day: dict[int, dict[str, Any]] = {}
    for s in snapshots:
        by_day[s["day"]] = s   # last write for a given day wins
    return [by_day[day] for day in sorted(by_day)]


def _population_curve(snapshots: list[dict[str, Any]]) -> list[dict[str, Any]]:
    # Slice 3 profiles may intentionally request population.total without
    # the old full by-role section. Partial snapshots are valid evidence, not
    # malformed logs, so legacy expanded reports simply omit unavailable
    # points rather than crashing the compact verdict path.
    return [
        {"day": s["day"], "total": s["population"]["total"],
         "by_role": s["population"].get("by_role", {})}
        for s in _last_snapshot_per_day(snapshots)
        if isinstance(s.get("population"), dict) and "total" in s["population"]
    ]


def _deaths_over_time(deaths: list[dict[str, Any]]) -> list[dict[str, Any]]:
    """One entry per death, in order, each carrying its own running tally
    so a caller can see *when* deaths of a given cause/role started
    piling up rather than only the summary's final totals.
    """
    running_cause: dict[str, int] = {}
    running_role: dict[str, int] = {}
    out = []
    for d in deaths:
        running_cause[d["cause"]] = running_cause.get(d["cause"], 0) + 1
        running_role[d["role"]] = running_role.get(d["role"], 0) + 1
        out.append({
            "game_time": d["game_time"],
            "cause": d["cause"],
            "role": d["role"],
            "running_by_cause": dict(running_cause),
            "running_by_role": dict(running_role),
        })
    return out


def _honey_fill_vs_winter(snapshots: list[dict[str, Any]]) -> list[dict[str, Any]]:
    """Honey-cell fill fraction alongside winter_here, so a fill rate that
    stalls right as winter arrives is visible without cross-referencing
    two separate series by hand.
    """
    out = []
    for s in _last_snapshot_per_day(snapshots):
        if not all(isinstance(s.get(key), dict) for key in ("cells", "environment")):
            continue
        if "total" not in s["cells"] or "by_contents" not in s["cells"] or "winter_here" not in s["environment"]:
            continue
        total_cells = s["cells"]["total"]
        honey_cells = s["cells"]["by_contents"].get("honey", 0)
        fraction = (honey_cells / total_cells) if total_cells > 0 else 0.0
        out.append({
            "day": s["day"],
            "honey_fraction": fraction,
            "winter_here": s["environment"]["winter_here"],
        })
    return out


def _flower_mix_by_day(snapshots: list[dict[str, Any]]) -> dict[int, dict[str, Any]]:
    """First flower mix for each elapsed day, beginning with founding day 0."""
    mixes: dict[int, dict[str, Any]] = {}
    first_day: int | None = None
    for snapshot in snapshots:
        day = snapshot.get("day")
        environment = snapshot.get("environment")
        if (
            isinstance(day, int)
            and not isinstance(day, bool)
            and isinstance(environment, dict)
            and isinstance(environment.get("flowers_by_species"), dict)
        ):
            if first_day is None:
                first_day = day
            mixes.setdefault(day - first_day, environment["flowers_by_species"])
    return mixes


def _milestone_states(snapshot: dict[str, Any], settings: dict[str, Any],
                      winter_seen: bool) -> tuple[dict[str, bool], bool]:
    """Return the milestones true in one snapshot and the next winter state.

    Both day-resolution compatibility output and elapsed-time pacing evidence
    use this one predicate, so they cannot silently assign different meanings
    to a milestone. Food security and winter survival require a living colony:
    zero bees otherwise make the calculated winter requirement zero.
    """
    population = snapshot.get("population")
    resources = snapshot.get("resources")
    environment = snapshot.get("environment")
    total = population.get("total") if isinstance(population, dict) else None
    has_population = (
        not isinstance(total, bool)
        and isinstance(total, (int, float))
        and total >= 1
    )
    states = {
        "first_worker_day": has_population and total > 1,
        "winter_entered_day": False,
        "winter_survived_day": False,
        "food_secure_day": False,
        # T2-7: the snapshot says the stores cover the cheapest first tier-2 path.
        "first_tier2_day": (has_population and isinstance(resources, dict)
                            and resources.get("first_tier2_affordable") is True),
    }
    winter_here = environment.get("winter_here") if isinstance(environment, dict) else None
    if winter_here is True:
        winter_seen = True
        states["winter_entered_day"] = True
    elif winter_here is False and winter_seen and has_population:
        states["winter_survived_day"] = True

    food_stores = resources.get("food_stores") if isinstance(resources, dict) else None
    required_food = _winter_food_requirement(settings, total)
    states["food_secure_day"] = (
        has_population
        and not isinstance(food_stores, bool)
        and isinstance(food_stores, (int, float))
        and required_food is not None
        and food_stores >= required_food
    )
    return states, winter_seen


def _number(value: Any) -> float | None:
    if isinstance(value, bool) or not isinstance(value, (int, float)):
        return None
    return float(value)


def _skipped_winter(previous: dict[str, Any] | None, snapshot: dict[str, Any],
                    settings: dict[str, Any]) -> bool:
    """True when the clock jumps by winter's length between two snapshots.

    season.gd resolves a skipped winter in one tick, so winter_here is never
    true in a snapshot; the jump in game_time is the only trace it leaves.
    """
    if previous is None:
        return False
    length = _number(settings.get("winter_length_days"))
    seconds_per_day = _number(settings.get("seconds_per_day"))
    before = _number(previous.get("game_time"))
    after = _number(snapshot.get("game_time"))
    if None in (length, seconds_per_day, before, after) or length <= 0 or seconds_per_day <= 0:
        return False
    return after - before >= length * seconds_per_day


def _has_population(snapshot: dict[str, Any]) -> bool:
    population = snapshot.get("population")
    total = population.get("total") if isinstance(population, dict) else None
    return _number(total) is not None and total >= 1


def _milestones(snapshots: list[dict[str, Any]], settings: dict[str, Any]) -> dict[str, int]:
    """The first day each pacing milestone became true."""
    milestones: dict[str, int] = {}
    winter_seen = False
    previous: dict[str, Any] | None = None
    for snapshot in _last_snapshot_per_day(snapshots):
        day = snapshot.get("day")
        if not isinstance(day, int):
            continue
        if _skipped_winter(previous, snapshot, settings):
            milestones.setdefault("winter_entered_day", previous.get("day", day))
            if _has_population(snapshot):
                milestones.setdefault("winter_survived_day", day)
        previous = snapshot
        states, winter_seen = _milestone_states(snapshot, settings, winter_seen)
        for name, reached in states.items():
            if reached:
                milestones.setdefault(name, day)
    return milestones


def _milestone_times(snapshots: list[dict[str, Any]], settings: dict[str, Any]) -> dict[str, float]:
    """The elapsed day of the first snapshot where each milestone is true."""
    seconds_per_day = settings.get("seconds_per_day")
    has_game_time = any(
        not isinstance(snapshot.get("game_time"), bool)
        and isinstance(snapshot.get("game_time"), (int, float))
        for snapshot in snapshots
    )
    if (isinstance(seconds_per_day, bool) or not isinstance(seconds_per_day, (int, float))
            or seconds_per_day <= 0 or not has_game_time):
        return {}

    milestone_times: dict[str, float] = {}
    winter_seen = False
    previous = None
    for snapshot in snapshots:
        game_time = snapshot.get("game_time")
        if isinstance(game_time, bool) or not isinstance(game_time, (int, float)):
            continue
        if _skipped_winter(previous, snapshot, settings):
            # The jump is winter's whole length, so winter began that far back from
            # here (never before the earlier snapshot); the earlier snapshot's own
            # time would put the row up to a snapshot gap too early.
            began = max(previous["game_time"], game_time - settings["winter_length_days"] * seconds_per_day)
            milestone_times.setdefault("winter_entered_day", began / seconds_per_day)
            if _has_population(snapshot):
                milestone_times.setdefault("winter_survived_day", game_time / seconds_per_day)
        previous = snapshot
        states, winter_seen = _milestone_states(snapshot, settings, winter_seen)
        for name, reached in states.items():
            if reached:
                milestone_times.setdefault(name, game_time / seconds_per_day)
    return milestone_times


def _alpha_route(snapshots: list[dict[str, Any]]) -> dict[str, int]:
    """Return the Colony Run gate days copied into diagnostic snapshots.

    Unlike pacing milestones, these are the game's recorded milestone days.
    A selected snapshot can arrive after the fact it records, so its own day
    is not evidence for the gate; only the copied integer record is used.
    """
    facts: dict[str, int] = {}
    record_names = {
        "first_worker": "first_worker_day",
        "first_automation": "first_automation_day",
        "first_gyne": "first_gyne_day",
        "victory": "victory_day",
    }
    for snapshot in snapshots:
        colony = snapshot.get("colony")
        milestone_days = colony.get("milestone_days") if isinstance(colony, dict) else None
        if not isinstance(milestone_days, dict):
            continue
        for record_name, fact_name in record_names.items():
            day = milestone_days.get(record_name)
            if isinstance(day, int) and not isinstance(day, bool):
                facts.setdefault(fact_name, day)
    return facts


def _winter_food_requirement(settings: dict[str, Any], population: Any) -> float | None:
    """Return one population's winter requirement in honey-store units."""
    if isinstance(population, bool) or not isinstance(population, (int, float)):
        return None
    keys = ("energy_burn_rate", "winter_burn_factor", "winter_length_days",
            "seconds_per_day", "honey_energy_factor")
    values = [settings.get(key) for key in keys]
    if any(isinstance(value, bool) or not isinstance(value, (int, float)) for value in values):
        return None
    energy_burn_rate, winter_burn_factor, winter_length_days, seconds_per_day, honey_energy_factor = values
    if honey_energy_factor <= 0:
        return None
    return (
        population * energy_burn_rate * winter_burn_factor
        * winter_length_days * seconds_per_day / honey_energy_factor
    )


def _action_summary(actions: list[dict[str, Any]]) -> dict[str, Any]:
    """scenario_actions.gd's headless action driver (contract:
    docs/headless-run-contract.md) logs one "action" entry per action
    attempted, whatever the result. `problems` surfaces anything that
    wasn't a clean "accepted" -- a rejected action, or one whose "when"
    never fired before the run ended -- so a scenario author doesn't have
    to grep the raw jsonl to find out a strategy script didn't do what it
    said.
    """
    by_result: dict[str, int] = {}
    for a in actions:
        by_result[a["result"]] = by_result.get(a["result"], 0) + 1
    problems = [
        {"do": a["do"], "target": a["target"], "result": a["result"], "reason": a["reason"]}
        for a in actions if a["result"] != "accepted"
    ]
    return {"total": len(actions), "by_result": by_result, "problems": problems}


# Config keys that gate a mechanic, mapped to the summary/event-count keys
# that should be nonzero if that mechanic actually fired. Checked against
# the run's own settings snapshot (not the scenario file) since
# config_overrides can change these before the summary is written.
_MECHANIC_TOGGLES = {
    "predators_on": "crab_spider_events",
    "auto_recruitment_on": "recruitment_matches",
    "scouting_on": "scouting_settled",
    "orientation_flight_on": "orientation_flights",
    "tarsal_markers_on": "tarsal_marks",
}


def _parse_set_config_value(raw: str) -> Any:
    """Undo scenario_actions.gd::_do_set_config's "%s = %s" % [key, value]
    formatting -- the action log has no structured value field, just that
    string, since it's a debug line first and a data source second."""
    if raw == "true":
        return True
    if raw == "false":
        return False
    try:
        return int(raw)
    except ValueError:
        pass
    try:
        return float(raw)
    except ValueError:
        pass
    return raw


def _settings_timeline(actions: list[dict[str, Any]]) -> list[tuple[float, str, Any]]:
    """Every accepted set_config action, in log order, as (game_time, key,
    value). A mid-run set_config changes what a later mechanic-firing check
    should compare against -- the boot config snapshot alone goes stale the
    moment a scenario flips a toggle after boot."""
    timeline: list[tuple[float, str, Any]] = []
    for a in actions:
        if a.get("do") != "set_config" or a.get("result") != "accepted":
            continue
        target = a.get("target", "")
        if " = " not in target:
            continue
        key, _, raw_value = target.partition(" = ")
        timeline.append((a["game_time"], key, _parse_set_config_value(raw_value)))
    return timeline


def _live_value(key: str, settings: dict[str, Any],
                 timeline: list[tuple[float, str, Any]], cutoff: float) -> Any:
    """The value `key` actually held at `cutoff` game_time: the boot
    setting, overridden by the last set_config for that key at or before
    cutoff."""
    value = settings.get(key)
    for game_time, tkey, tvalue in timeline:
        if tkey == key and game_time <= cutoff:
            value = tvalue
    return value


def _mechanic_firing(settings: dict[str, Any], summary: dict[str, Any] | None,
                      actions: list[dict[str, Any]]) -> dict[str, Any]:
    result: dict[str, Any] = {}
    if summary is None:
        return result
    timeline = _settings_timeline(actions)
    cutoff = summary.get("game_time", float("inf"))
    for toggle_key, count_key in _MECHANIC_TOGGLES.items():
        if toggle_key not in settings:
            continue
        toggle_on = bool(_live_value(toggle_key, settings, timeline, cutoff))
        count = summary.get(count_key, 0)
        # crab_spider_events is a dict of outcome -> count, everything else
        # is a plain int.
        total = sum(count.values()) if isinstance(count, dict) else count
        result[toggle_key] = {
            "toggle_on": toggle_on,
            "event_count": total,
            "fired": (not toggle_on) or total > 0,
        }
    return result


# Which of analyze()'s top-level keys each report profile prints
# (CHATGPT_INSIGHTS_PLAN.md's A5). "brief" is the default, AI-facing one
# -- summary numbers plus anything that went wrong with the scenario's
# own actions, without the token cost of the full per-day series a human
# skimming a chart would want instead.
REPORT_PROFILES = {
    "brief": ["summary", "actions"],
    "balance": ["summary", "population_curve", "deaths_over_time", "honey_fill_vs_winter", "flower_mix_by_day", "milestones", "milestone_times"],
    "behaviour": ["summary", "mechanic_firing", "actions"],
    "full": ["population_curve", "deaths_over_time", "honey_fill_vs_winter", "flower_mix_by_day", "milestones", "milestone_times",
             "mechanic_firing", "actions", "summary"],
}


def report(analysis: dict[str, Any], profile: str = "brief") -> dict[str, Any]:
    keys = REPORT_PROFILES.get(profile, REPORT_PROFILES["brief"])
    return {k: analysis[k] for k in keys}


def aggregate_runs(analyses: list[dict[str, Any]]) -> dict[str, Any]:
    """N single-run analyses -> a range report, not a single point.

    Bee behaviour has randomness (scouting, trait rolls) per
    AI_PLAYTEST_PLAN.md, so a batch of repeats needs min/mean/max on the
    headline numbers rather than trusting any one run.
    """
    summaries = [a["summary"] for a in analyses if a["summary"] is not None]
    n = len(summaries)

    def stats(values: list[float]) -> dict[str, float]:
        if not values:
            return {"min": 0, "mean": 0, "max": 0}
        return {"min": min(values), "mean": sum(values) / len(values), "max": max(values)}

    total_deaths = stats([s["total_deaths"] for s in summaries])
    gynes = stats([s["gynes_released"] for s in summaries])

    all_causes: set[str] = set()
    all_roles: set[str] = set()
    for s in summaries:
        all_causes.update(s["deaths_by_cause"].keys())
        all_roles.update(s["deaths_by_role"].keys())
    deaths_by_cause = {
        cause: stats([s["deaths_by_cause"].get(cause, 0) for s in summaries])
        for cause in sorted(all_causes)
    }
    deaths_by_role = {
        role: stats([s["deaths_by_role"].get(role, 0) for s in summaries])
        for role in sorted(all_roles)
    }

    outcomes: dict[str, int] = {}
    for s in summaries:
        outcomes[s["outcome"]] = outcomes.get(s["outcome"], 0) + 1

    # Mechanic firing: across the batch, did every run that had the
    # toggle on actually log at least one event? A single unlucky run not
    # firing is expected sometimes; every run failing to fire points at
    # the mechanic being unwired rather than bad luck.
    mechanic_firing: dict[str, Any] = {}
    for toggle_key in _MECHANIC_TOGGLES:
        runs_with_toggle_on = [a["mechanic_firing"][toggle_key] for a in analyses
                                if toggle_key in a["mechanic_firing"]
                                and a["mechanic_firing"][toggle_key]["toggle_on"]]
        if not runs_with_toggle_on:
            continue
        fired_count = sum(1 for r in runs_with_toggle_on if r["fired"])
        mechanic_firing[toggle_key] = {
            "runs_with_toggle_on": len(runs_with_toggle_on),
            "runs_that_fired": fired_count,
            "all_fired": fired_count == len(runs_with_toggle_on),
        }

    return {
        "runs": n,
        "outcomes": outcomes,
        "total_deaths": total_deaths,
        "gynes_released": gynes,
        "deaths_by_cause": deaths_by_cause,
        "deaths_by_role": deaths_by_role,
        "mechanic_firing": mechanic_firing,
    }
