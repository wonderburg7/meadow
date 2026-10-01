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

from analyze_session import analyze, load_entries  # noqa: E402
from run_scenario import DEFAULT_FIXED_FPS, DEFAULT_GODOT_PATH, DEFAULT_TIMEOUT, run_once  # noqa: E402


DEFAULT_REPEAT = 3
BAND_FRACTION = 0.25
SCENARIO = ROOT / "test_scenarios" / "alpha_arc_test.json"


@dataclass(frozen=True)
class Gate:
    label: str
    metric: str
    target_minutes: int


# These are the observable counterparts of product-scope.md section 3. The
# 90-minute target is winter emergence, the prerequisite to its later gyne
# release, which the current diagnostic log does not yet timestamp.
GATES = (
    Gate("first worker", "first_worker_day", 5),
    Gate("food secure", "food_secure_day", 10),
    Gate("winter entered", "winter_entered_day", 60),
    Gate("winter survived", "winter_survived_day", 90),
)


def target_day(target_minutes: int, day_length_seconds: float) -> float:
    """Convert the product timing budget to this run's in-game days."""
    return target_minutes * 60 / day_length_seconds


def in_band(day: float | None, target: float, fraction: float = BAND_FRACTION) -> bool:
    """True when a completed milestone is within the inclusive timing band."""
    return day is not None and target * (1 - fraction) <= day <= target * (1 + fraction)


def build_rows(analyses: list[dict[str, Any]], day_length_seconds: float) -> list[dict[str, Any]]:
    """Return one display-ready row for each measurable pacing gate."""
    rows = []
    for gate in GATES:
        values = [analysis.get("milestone_times", {}).get(gate.metric) for analysis in analyses]
        complete = all(isinstance(value, (int, float)) and not isinstance(value, bool) for value in values)
        median_day = statistics.median(values) if complete else None
        target = target_day(gate.target_minutes, day_length_seconds)
        rows.append({
            "milestone": gate.label,
            "median_day": median_day,
            "target_day": target,
            "inside_band": in_band(median_day, target),
        })
    return rows


def render_table(rows: list[dict[str, Any]], day_length_seconds: float, repeat: int) -> str:
    """Render the compact, human-readable pacing report."""
    lines = [
        "Pacing gates (%d runs, %.0fs/day, +/-%.0f%%)" % (repeat, day_length_seconds, BAND_FRACTION * 100),
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


def run(repeat: int, godot_path: str, timeout: int,
        runner: Callable[..., Path | None] = run_once) -> tuple[list[dict[str, Any]], float]:
    """Run the fixed-seed arc repeatedly and return its analyses and cadence."""
    analyses: list[dict[str, Any]] = []
    day_length_seconds: float | None = None
    for index in range(repeat):
        print("run %d/%d" % (index + 1, repeat))
        session_file = runner(SCENARIO, godot_path, timeout, DEFAULT_FIXED_FPS)
        if session_file is None:
            raise RuntimeError("alpha arc did not finish")
        entries = load_entries(session_file)
        analysis = analyze(entries)
        config = next((entry for entry in entries if entry.get("type") == "config"), {})
        analysis["settings"] = config.get("settings", {})
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

    try:
        analyses, day_length_seconds = run(args.repeat, args.godot_path, args.timeout)
    except (RuntimeError, ValueError) as error:
        print("error: %s" % error, file=sys.stderr)
        return 1
    print(render_table(build_rows(analyses, day_length_seconds), day_length_seconds, args.repeat))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
