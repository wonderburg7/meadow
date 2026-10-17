#!/usr/bin/env python3
"""Measure four foraging stages on the same five Colony Run seeds.

Each figure is food delivered per starting forager per day during days 1--20.
The runner writes temporary scenario and result files only; the table is the
reviewable evidence and belongs in the FR-1 plan section after a campaign.
"""

from __future__ import annotations

import argparse
import copy
import json
import re
import subprocess
import sys
import tempfile
from pathlib import Path
from statistics import median
from typing import Any

ROOT = Path(__file__).resolve().parent.parent
SCENARIO = ROOT / "test_scenarios" / "fr1_forager_stages_test.json"
SEEDS = (7, 555, 2026, 12345, 90210)
DAYS = 20
FORAGERS = 11
RESULT_PATTERN = re.compile(r"\bresult=(\S+)")
STAGES = (
    ("Orientation flight", {"orientation_flight_on": True, "scouting_on": False,
                            "auto_recruitment_on": False, "floral_constancy_on": False}),
    ("Auto scouting", {"orientation_flight_on": False, "scouting_on": True,
                        "auto_recruitment_on": False, "floral_constancy_on": False}),
    ("Auto scouting + Auto-recruitment", {"orientation_flight_on": False, "scouting_on": True,
                                            "auto_recruitment_on": True, "floral_constancy_on": False}),
    ("Auto scouting + Auto-recruitment + species passing",
     {"orientation_flight_on": False, "scouting_on": True,
      "auto_recruitment_on": True, "floral_constancy_on": True}),
)


def delivery_per_forager_day(summary: dict[str, Any]) -> float:
    """Return the FR-1 figure from a passed scenario report summary."""
    return float(summary["forager_delivery_amount"]) / (DAYS * FORAGERS)


def stage_rows(values: list[list[float]]) -> list[tuple[float, str]]:
    """Return each median and its ratio to the preceding stage."""
    rows: list[tuple[float, str]] = []
    previous: float | None = None
    for stage_values in values:
        current = median(stage_values)
        ratio = "--" if previous is None else f"{current / previous:.2f}x"
        rows.append((current, ratio))
        previous = current
    return rows


def _scenario(stage_toggles: dict[str, bool], seed: int) -> dict[str, Any]:
    scenario = json.loads(SCENARIO.read_text(encoding="utf-8"))
    scenario["config_overrides"].update(stage_toggles)
    scenario["random_seed"] = seed
    return scenario


def _run_one(stage: str, toggles: dict[str, bool], seed: int, root: Path, godot: str | None) -> float:
    scenario_path = root / f"{stage}-{seed}.json"
    scenario_path.write_text(json.dumps(_scenario(toggles, seed)), encoding="utf-8")
    command = [sys.executable, str(ROOT / "tools" / "run_scenario.py"), str(scenario_path),
               "--result-root", str(root / "results")]
    if godot:
        command.extend(("--godot-path", godot))
    completed = subprocess.run(command, capture_output=True, text=True, check=False)
    match = RESULT_PATTERN.search(completed.stdout)
    if completed.returncode or "status=passed" not in completed.stdout or not match:
        raise RuntimeError(f"{stage}, seed {seed} failed:\n{completed.stdout}\n{completed.stderr}")
    result_path = Path(match.group(1))
    summary = json.loads((result_path.parent / "report.json").read_text(encoding="utf-8"))["summary"]
    if not toggles["orientation_flight_on"] and summary.get("orientation_flights", 0) > 0:
        raise RuntimeError(f"{stage}, seed {seed}: orientation flights leaked while disabled")
    if not toggles["scouting_on"] and summary.get("scouting_settled", 0) > 0:
        raise RuntimeError(f"{stage}, seed {seed}: scouting settled while disabled")
    return delivery_per_forager_day(summary)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--godot-path", help="path passed through to run_scenario.py")
    args = parser.parse_args()
    values: list[list[float]] = []
    with tempfile.TemporaryDirectory(prefix="meadow-fr1-") as temporary:
        root = Path(temporary)
        for name, toggles in STAGES:
            values.append([_run_one(name.replace(" ", "_"), toggles, seed, root, args.godot_path) for seed in SEEDS])
    print(f"Window: days 1--{DAYS}; divisor: {DAYS} days x {FORAGERS} starting foragers.")
    print("| Stage | Food per forager per day (median; five seeds) | vs stage before |")
    print("| --- | --- | --- |")
    for (name, _), stage_values, (middle, ratio) in zip(STAGES, values, stage_rows(values)):
        rendered = ", ".join(f"{value:.4f}" for value in stage_values)
        print(f"| {name} | {middle:.4f} ({rendered}) | {ratio} |")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
