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
        "mechanic_firing": _mechanic_firing(settings, summary),
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
    return [
        {"day": s["day"], "total": s["population"]["total"],
         "by_role": s["population"]["by_role"]}
        for s in _last_snapshot_per_day(snapshots)
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
        total_cells = s["cells"]["total"]
        honey_cells = s["cells"]["by_contents"].get("honey", 0)
        fraction = (honey_cells / total_cells) if total_cells > 0 else 0.0
        out.append({
            "day": s["day"],
            "honey_fraction": fraction,
            "winter_here": s["environment"]["winter_here"],
        })
    return out


def _action_summary(actions: list[dict[str, Any]]) -> dict[str, Any]:
    """scenario_actions.gd's headless action driver (see
    insights_from_ChatGPT.md's 22 Aug 2026 entry and
    AI_PLAYTEST_PLAN.md's extension) logs one "action" entry per action
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


def _mechanic_firing(settings: dict[str, Any], summary: dict[str, Any] | None) -> dict[str, Any]:
    result: dict[str, Any] = {}
    if summary is None:
        return result
    for toggle_key, count_key in _MECHANIC_TOGGLES.items():
        if toggle_key not in settings:
            continue
        toggle_on = bool(settings[toggle_key])
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
