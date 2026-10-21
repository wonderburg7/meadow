#!/usr/bin/env python3
"""Measure the headless alpha arc against the closed-alpha pacing targets.

The twenty-minute forage/weather crisis is a player-experience outcome, not an
event the headless log currently records. This command distinguishes that
hands-on question from measured gates and facts the scripted route has not yet
reached, rather than inventing an in-band result.
"""

from __future__ import annotations

import argparse
import statistics
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Callable


TOOLS = Path(__file__).resolve().parent
ROOT = TOOLS.parent
sys.path.insert(0, str(TOOLS))

import godot_cache  # noqa: E402
from analyze_session import analyze, load_entries  # noqa: E402
from run_scenario import DEFAULT_FIXED_FPS, DEFAULT_GODOT_PATH, DEFAULT_TIMEOUT, run_once  # noqa: E402


DEFAULT_REPEAT = 3
# One seed per repeat, so three runs are three different colonies (PE-2).
# The first is the scenario's own pinned seed.
DEFAULT_SEEDS = (20260923, 20260924, 20260925)
BAND_FRACTION = 0.25
WINTER_BAND_DAYS = 1
FIRST_WORKER_BY_DAY = 17.0
FIRST_AUTOMATION_DAYS = (5.0, 8.0)
SCENARIO = ROOT / "test_scenarios" / "alpha_arc_test.json"


@dataclass(frozen=True)
class Gate:
    label: str
    metric: str
    target_minutes: int
    source: str | None = "milestone_times"
    required_metrics: tuple[str, ...] = ()


# These are the product-scope gates.  Food security remains a useful
# per-seed diagnostic, but it is not a substitute for the automation gate.
GATES = (
    Gate("first worker", "first_worker_day", 5),
    Gate("first automation", "first_automation_day", 10, "alpha_route"),
    Gate("crisis response", "", 20, None),
    Gate("winter survival", "winter_survived_day", 60),
    Gate("gyne/victory", "victory_day", 90, "alpha_route", ("first_gyne_day", "victory_day")),
)

# T2-7: the first tier-2 purchase is a diagnostic beside the five gates, not a sixth.
TIER2_TARGET_DAY = 5

DIAGNOSTIC_METRICS = ("first_worker_day", "food_secure_day", "winter_entered_day", "winter_survived_day")


def target_day(target_minutes: int, day_length_seconds: float) -> float:
    """Convert the product timing budget to this run's in-game days."""
    return target_minutes * 60 / day_length_seconds


def in_band(day: float | None, target: float, fraction: float = BAND_FRACTION) -> bool:
    """True when a completed milestone is within the inclusive timing band."""
    return day is not None and target * (1 - fraction) <= day <= target * (1 + fraction)


def in_days(day: float | None, target: float, days: float = WINTER_BAND_DAYS) -> bool:
    """True when a completed milestone is within `days` of a scheduled day."""
    return day is not None and abs(day - target) <= days


def winter_schedule(analyses: list[dict[str, Any]]) -> tuple[float, float]:
    """Return winter's first and first-following-spring days from logged settings."""
    schedules = set()
    for analysis in analyses:
        settings = analysis.get("settings", {})
        season_days = settings.get("season_length_days")
        winter_days = settings.get("winter_length_days")
        if (isinstance(season_days, bool) or not isinstance(season_days, (int, float)) or season_days <= 0
                or isinstance(winter_days, bool) or not isinstance(winter_days, (int, float)) or winter_days <= 0):
            raise ValueError("run did not record positive season_length_days and winter_length_days")
        schedules.add((float(season_days) + 1.0, float(season_days) + float(winter_days) + 1.0))
    if len(schedules) != 1:
        raise ValueError("alpha arc runs recorded different winter schedules")
    return schedules.pop()


def build_rows(analyses: list[dict[str, Any]], day_length_seconds: float) -> list[dict[str, Any]]:
    """Return one display-ready row for each measurable pacing gate."""
    rows = []
    _winter_entered_day, winter_ended_day = winter_schedule(analyses)
    for gate in GATES:
        source_values = [analysis.get(gate.source, {}) if gate.source else {} for analysis in analyses]
        required_metrics = gate.required_metrics or (gate.metric,)
        complete = gate.source is not None and all(
            isinstance(source.get(metric), (int, float)) and not isinstance(source.get(metric), bool)
            for source in source_values for metric in required_metrics
        )
        values = [source.get(gate.metric) for source in source_values]
        median_day = statistics.median(values) if complete else None
        if gate.metric == "first_worker_day":
            target = target_day(gate.target_minutes, day_length_seconds)
            inside = median_day is not None and median_day <= FIRST_WORKER_BY_DAY
        elif gate.metric == "first_automation_day":
            target = target_day(gate.target_minutes, day_length_seconds)
            inside = (median_day is not None
                      and FIRST_AUTOMATION_DAYS[0] <= median_day <= FIRST_AUTOMATION_DAYS[1])
        elif gate.metric == "winter_survived_day":
            target = winter_ended_day
            inside = in_days(median_day, target)
        else:
            target = target_day(gate.target_minutes, day_length_seconds)
            inside = in_band(median_day, target)
        status = "in band" if inside else "out of band" if complete else "unavailable"
        boundary = "hands-on question" if gate.source is None else "measured fact" if complete else "unavailable"
        rows.append({
            "milestone": gate.label,
            "median_day": median_day,
            "target_day": target,
            "inside_band": inside,
            "status": status,
            "boundary": boundary,
        })
    return rows


SEED_COLUMNS = ("1st worker", "food safe", "w entered", "w survived")


def seed_rows(analyses: list[dict[str, Any]]) -> list[dict[str, Any]]:
    """One row per run: its seed, each gate's day, and whether the colony lived."""
    rows = []
    for analysis in analyses:
        times = analysis.get("milestone_times", {})
        colony = analysis.get("colony", {})
        rows.append({
            "seed": analysis.get("seed"),
            "days": [times.get(metric) for metric in DIAGNOSTIC_METRICS],
            "lived": bool(colony.get("lived")),
            "population": colony.get("population"),
        })
    return rows


def render_seed_rows(rows: list[dict[str, Any]], winter_entered_day: float,
                     winter_ended_day: float) -> str:
    """The per-seed evidence block: every seed's days and whether it lived."""
    lines = [
        "Per seed (day each gate was met; winter %.0f-%.0f, from run settings)"
        % (winter_entered_day, winter_ended_day),
        "seed        " + "  ".join("%10s" % name for name in SEED_COLUMNS) + "  colony",
    ]
    for row in rows:
        days = "  ".join("%10s" % ("missing" if day is None else "%.2f" % day) for day in row["days"])
        verdict = "lived (%s bees)" % row["population"] if row["lived"] else "died"
        lines.append("%-10s  %s  %s" % (row["seed"], days, verdict))
    return "\n".join(lines)


def tier2_row(analyses: list[dict[str, Any]]) -> dict[str, Any]:
    """The first tier-2 purchase day against day 5, using the same band as the gates."""
    values = [analysis.get("milestone_times", {}).get("first_tier2_day") for analysis in analyses]
    complete = bool(values) and all(isinstance(v, (int, float)) and not isinstance(v, bool) for v in values)
    median_day = statistics.median(values) if complete else None
    inside = in_band(median_day, float(TIER2_TARGET_DAY))
    return {
        "milestone": "first tier-2",
        "median_day": median_day,
        "target_day": float(TIER2_TARGET_DAY),
        "inside_band": inside,
        "status": "in band" if inside else "out of band" if complete else "unavailable",
        "days": values,
    }


def render_tier2_row(row: dict[str, Any]) -> str:
    median = "missing" if row["median_day"] is None else "%.2f" % row["median_day"]
    days = ", ".join("missing" if d is None else "%.2f" % d for d in row["days"])
    return "Diagnostic (not a gate): %-12s  %10s  %10.2f  %-11s  per seed: %s" % (
        row["milestone"], median, row["target_day"], row["status"], days)


def render_table(rows: list[dict[str, Any]], day_length_seconds: float, repeat: int) -> str:
    """Render the compact, human-readable pacing report."""
    lines = [
        "Pacing gates (%d runs, %.0fs/day, +/-%.0f%%; winter rows +/-%d day of the recorded schedule)" % (
            repeat, day_length_seconds, BAND_FRACTION * 100, WINTER_BAND_DAYS),
        "milestone         median day  target day  result       evidence boundary",
        "----------------  ----------  ----------  -----------  -----------------",
    ]
    for row in rows:
        median = "missing" if row["median_day"] is None else "%.2f" % row["median_day"]
        lines.append("%-16s  %10s  %10.2f  %-11s  %s" % (
            row["milestone"], median, row["target_day"], row["status"], row["boundary"],
        ))
    lines.append("Not instrumented: 20m forage/weather crisis; 90m gyne release.")
    return "\n".join(lines)


def _day_length(analysis: dict[str, Any]) -> float:
    settings = analysis.get("settings", {})
    value = settings.get("seconds_per_day")
    if isinstance(value, bool) or not isinstance(value, (int, float)) or value <= 0:
        raise ValueError("run did not record a positive settings.seconds_per_day")
    return float(value)


def colony_lived(entries: list[dict[str, Any]], analysis: dict[str, Any]) -> dict[str, Any]:
    """The queen alive and workers present after winter, from one run's log."""
    summary = analysis.get("summary") or {}
    snapshots = [entry for entry in entries if entry.get("type") == "snapshot"]
    population = None
    if snapshots:
        population = (snapshots[-1].get("population") or {}).get("total")
    numeric = isinstance(population, (int, float)) and not isinstance(population, bool)
    lived = (summary.get("queen_alive") is True and numeric and population >= 2
             and analysis.get("milestone_times", {}).get("winter_survived_day") is not None)
    return {"lived": lived, "population": population if numeric else None}


def run(repeat: int, godot_path: str, timeout: int,
        runner: Callable[..., Path | None] = run_once,
        seeds: tuple[int, ...] = DEFAULT_SEEDS) -> tuple[list[dict[str, Any]], float]:
    """Run the arc once per seed and return its analyses and cadence."""
    analyses: list[dict[str, Any]] = []
    day_length_seconds: float | None = None
    for index in range(repeat):
        print("run %d/%d" % (index + 1, repeat))
        seed = seeds[index] if index < len(seeds) else seeds[-1] + index
        print("seed %d" % seed)
        session_file = runner(SCENARIO, godot_path, timeout, DEFAULT_FIXED_FPS, seed)
        if session_file is None:
            raise RuntimeError("alpha arc did not finish")
        entries = load_entries(session_file)
        analysis = analyze(entries)
        config = next((entry for entry in entries if entry.get("type") == "config"), {})
        analysis["settings"] = config.get("settings", {})
        analysis["seed"] = seed
        analysis["colony"] = colony_lived(entries, analysis)
        current_day_length = _day_length(analysis)
        if day_length_seconds is None:
            day_length_seconds = current_day_length
        elif day_length_seconds != current_day_length:
            raise ValueError("alpha arc runs recorded different day lengths")
        analyses.append(analysis)
    return analyses, day_length_seconds if day_length_seconds is not None else 0.0


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--repeat", type=int, default=DEFAULT_REPEAT,
                        help="number of runs (default: %(default)s; use explicitly for more)")
    parser.add_argument("--godot-path", default=DEFAULT_GODOT_PATH)
    parser.add_argument("--timeout", type=int, default=DEFAULT_TIMEOUT,
                        help="real-world timeout per run in seconds")
    args = parser.parse_args()
    if args.repeat < 1:
        parser.error("--repeat must be at least 1")

    # run_once launches Godot directly, so seed the import cache the way
    # run_scenario.py's own entry point does: a worktree without one stalls
    # at boot and reads as a timeout (1 Oct 2026).
    if Path(args.godot_path).is_file():
        cache_ok, cache_line = godot_cache.ensure_cache(ROOT, args.godot_path)
        print(cache_line, file=sys.stderr)
        if not cache_ok:
            return 1

    try:
        analyses, day_length_seconds = run(args.repeat, args.godot_path, args.timeout)
    except (RuntimeError, ValueError) as error:
        print("error: %s" % error, file=sys.stderr)
        return 1
    rows = build_rows(analyses, day_length_seconds)
    print(render_table(rows, day_length_seconds, args.repeat))
    winter_entered_day, winter_ended_day = winter_schedule(analyses)
    print(render_seed_rows(seed_rows(analyses), winter_entered_day, winter_ended_day))
    print(render_tier2_row(tier2_row(analyses)))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
