#!/usr/bin/env python3
"""Measure the headless alpha arc against the closed-alpha pacing targets.

The twenty-minute forage/weather crisis and the ninety-minute gyne release are
player-experience outcomes, not events the headless log currently records.
This command therefore reports the four truthful, instrumented proxies rather
than inventing a time for either one.
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
# WO-1's schedule (plans/archive/winter-onset_2026-10-01.md): the countdown
# opens by itself and winter falls on days 21 to 41. A winter row is judged
# against these days, within a day either side, not against 1x minutes.
WINTER_ENTERED_DAY = 21
WINTER_ENDED_DAY = 41
WINTER_BAND_DAYS = 1
SCENARIO = ROOT / "test_scenarios" / "alpha_arc_test.json"


@dataclass(frozen=True)
class Gate:
    label: str
    metric: str
    target_minutes: int
    # A gate with a fixed day is judged against that day, not target_minutes.
    schedule_day: int | None = None


# These are the observable counterparts of product-scope.md section 3. The
# 90-minute target is winter emergence, the prerequisite to its later gyne
# release, which the current diagnostic log does not yet timestamp.
GATES = (
    Gate("first worker", "first_worker_day", 5),
    Gate("food secure", "food_secure_day", 10),
    Gate("winter entered", "winter_entered_day", 60, WINTER_ENTERED_DAY),
    Gate("winter survived", "winter_survived_day", 90, WINTER_ENDED_DAY),
)


def target_day(target_minutes: int, day_length_seconds: float) -> float:
    """Convert the product timing budget to this run's in-game days."""
    return target_minutes * 60 / day_length_seconds


def in_band(day: float | None, target: float, fraction: float = BAND_FRACTION) -> bool:
    """True when a completed milestone is within the inclusive timing band."""
    return day is not None and target * (1 - fraction) <= day <= target * (1 + fraction)


def in_days(day: float | None, target: float, days: float = WINTER_BAND_DAYS) -> bool:
    """True when a completed milestone is within `days` of a scheduled day."""
    return day is not None and abs(day - target) <= days


def build_rows(analyses: list[dict[str, Any]], day_length_seconds: float) -> list[dict[str, Any]]:
    """Return one display-ready row for each measurable pacing gate."""
    rows = []
    for gate in GATES:
        values = [analysis.get("milestone_times", {}).get(gate.metric) for analysis in analyses]
        complete = all(isinstance(value, (int, float)) and not isinstance(value, bool) for value in values)
        median_day = statistics.median(values) if complete else None
        if gate.schedule_day is not None:
            target = float(gate.schedule_day)
            inside = in_days(median_day, target)
        else:
            target = target_day(gate.target_minutes, day_length_seconds)
            inside = in_band(median_day, target)
        rows.append({
            "milestone": gate.label,
            "median_day": median_day,
            "target_day": target,
            "inside_band": inside,
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
            "days": [times.get(gate.metric) for gate in GATES],
            "lived": bool(colony.get("lived")),
            "population": colony.get("population"),
        })
    return rows


def render_seed_rows(rows: list[dict[str, Any]]) -> str:
    """The per-seed evidence block: every seed's days and whether it lived."""
    lines = [
        "Per seed (day each gate was met; winter %d-%d, WO-1)" % (WINTER_ENTERED_DAY, WINTER_ENDED_DAY),
        "seed        " + "  ".join("%10s" % name for name in SEED_COLUMNS) + "  colony",
    ]
    for row in rows:
        days = "  ".join("%10s" % ("missing" if day is None else "%.2f" % day) for day in row["days"])
        verdict = "lived (%s bees)" % row["population"] if row["lived"] else "died"
        lines.append("%-10s  %s  %s" % (row["seed"], days, verdict))
    return "\n".join(lines)


def render_table(rows: list[dict[str, Any]], day_length_seconds: float, repeat: int) -> str:
    """Render the compact, human-readable pacing report."""
    lines = [
        "Pacing gates (%d runs, %.0fs/day, +/-%.0f%%; winter rows +/-%d day of WO-1's schedule)" % (
            repeat, day_length_seconds, BAND_FRACTION * 100, WINTER_BAND_DAYS),
        "milestone        median day  target day  in band",
        "---------------  ----------  ----------  -------",
    ]
    for row in rows:
        median = "missing" if row["median_day"] is None else "%.2f" % row["median_day"]
        result = "yes" if row["inside_band"] else "no"
        lines.append("%-15s  %10s  %10.2f  %7s" % (
            row["milestone"], median, row["target_day"], result,
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
    print(render_table(build_rows(analyses, day_length_seconds), day_length_seconds, args.repeat))
    print(render_seed_rows(seed_rows(analyses)))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
