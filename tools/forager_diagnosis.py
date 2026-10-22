#!/usr/bin/env python3
"""Isolate entrance-wait and scouting-species costs without editing the game.

Targets are provisional. The controls test causes, not candidate balance
settings: the deliberately unreachable mentor thresholds are never selected
for gameplay. Reports and raw runs survive disposable worktree removal.
"""

from __future__ import annotations

import argparse
import json
import hashlib
import subprocess
import sys
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path
from statistics import mean, median

try:
    from tools import forager_stages as stages, forager_tuning as tuning
except ModuleNotFoundError:
    import forager_stages as stages
    import forager_tuning as tuning

ROOT = stages.ROOT
PRIMARY = ROOT.parents[1] if ROOT.parent.name == ".worktrees" else ROOT
EVIDENCE = PRIMARY / "build/forager-evidence"
BASELINE = EVIDENCE / "fr1b-baseline"
OUTPUT = EVIDENCE / "fr1c-diagnosis"
NO_MENTORS = {"recruit_upper_threshold_nectar": 1e9, "recruit_upper_threshold_pollen": 1e9}
CASES = [(name, dict(toggles)) for name, toggles in stages.STAGES] + [
    ("Recruitment, 1-second wait", dict(stages.STAGES[2][1], recruit_wait_seconds=1.0)),
    ("No mentors, 15-second wait", dict(stages.STAGES[2][1], **NO_MENTORS)),
    ("No mentors, 1-second wait", dict(stages.STAGES[2][1], **NO_MENTORS, recruit_wait_seconds=1.0)),
    ("Scouting with species restrictions, no recruitment",
     dict(stages.STAGES[3][1], auto_recruitment_on=False)),
]


def scenario(case: int, seed: int) -> dict:
    result = stages._scenario(stages.STAGES[0][1], seed)
    result["config_overrides"].update(tuning.DEFAULTS)
    result["config_overrides"].update(CASES[case][1])
    return result


def extract(folder: Path) -> dict:
    verdict = json.loads((folder / "result.json").read_text(encoding="utf-8"))
    if verdict["status"] != "passed" or verdict["outcome"] != "max_days":
        raise ValueError(f"Incomplete campaign window: {folder}")
    summary = json.loads((folder / "report.json").read_text(encoding="utf-8"))["summary"]
    if summary["day"] != stages.DAYS:
        raise ValueError(f"Expected day {stages.DAYS}: {folder}")
    rows = [json.loads(line) for line in (folder / "session.jsonl").read_text(encoding="utf-8").splitlines() if line.strip()]
    snapshots = [row for row in rows if row.get("type") == "snapshot"]
    if not snapshots:
        raise ValueError(f"No population/queue samples: {folder}")
    settled = [row["game_time"] for row in rows if row.get("type") == "scouting_settled"]
    return {
        "seed": verdict["seed"],
        "food": stages.delivery_per_forager_day(summary),
        "deliveries": summary["forager_deliveries"],
        "matches": summary["recruitment_matches"],
        "settled": summary["scouting_settled"],
        "settlement_day": 1 + median(settled) / 20 if settled else None,
        "peak_foragers": max(row["population"]["by_role"]["forager"] for row in snapshots),
        "seeking_sample_mean": mean(row["population"]["by_state"]["AT_ENTRANCE_SEEKING"] for row in snapshots),
        "mentoring_sample_mean": mean(row["population"]["by_state"]["AT_ENTRANCE_MENTORING"] for row in snapshots),
        "delivery_events_per_sim_minute": summary["forager_deliveries"] / summary["game_time"] * 60,
        "folder": str(folder),
    }


def baseline_case(case: int, seed: int, identity: str, baseline: Path) -> dict | None:
    manifest = baseline / "manifest.json"
    if not manifest.exists() or case >= len(stages.STAGES):
        return None
    data = json.loads(manifest.read_text(encoding="utf-8"))
    if data["fingerprint"] != identity or data["settings"] != tuning.DEFAULTS:
        return None
    row = next(row for row in data["cases"] if row["stage"] == case and row["seed"] == seed)
    return extract(baseline / row["directory"])


def run_case(case: int, seed: int, identity: str, baseline: Path, output: Path, godot: str | None) -> dict:
    archived = baseline_case(case, seed, identity, baseline)
    if archived is not None:
        return archived
    payload = scenario(case, seed)
    key = hashlib.sha256(json.dumps([identity, godot, payload], sort_keys=True).encode()).hexdigest()
    folder = output / "runs" / key
    cached = folder / "completed.json"
    if cached.exists():
        return extract(Path(json.loads(cached.read_text(encoding="utf-8"))["folder"]))
    folder.mkdir(parents=True, exist_ok=True)
    path = folder / "scenario.json"
    path.write_text(json.dumps(payload), encoding="utf-8")
    command = [sys.executable, str(ROOT / "tools/run_scenario.py"), str(path),
               "--fixed-fps", "30", "--result-root", str(folder / "results")]
    if godot:
        command.extend(("--godot-path", godot))
    completed = subprocess.run(command, capture_output=True, text=True, check=False)
    (folder / "runner.log").write_text(completed.stdout + "\n" + completed.stderr, encoding="utf-8")
    match = stages.RESULT_PATTERN.search(completed.stdout)
    if completed.returncode or "status=passed" not in completed.stdout or not match:
        raise RuntimeError(f"Case {case}, seed {seed} failed: {folder / 'runner.log'}")
    result_folder = Path(match.group(1)).parent
    result = extract(result_folder)
    cached.write_text(json.dumps({"folder": str(result_folder)}), encoding="utf-8")
    return result


def paired_changes(before: list[dict], after: list[dict]) -> list[float | None]:
    if any([row["seed"] for row in rows] != list(stages.SEEDS) for rows in (before, after)):
        raise ValueError("Every comparison needs the same five ordered seeds")
    return [(b["food"] / a["food"] - 1) * 100 if a["food"] > 0 else None
            for a, b in zip(before, after)]


def render(values: list[list[dict]], identity: str) -> str:
    if any(row["matches"] != 0 for case in (5, 6, 7) for row in values[case]):
        raise ValueError("A no-mentor/no-recruitment control unexpectedly matched")
    lines = ["### FR-1c controlled diagnosis", "",
             f"Simulation fingerprint: `{identity}`. Seeds: {', '.join(map(str, stages.SEEDS))}.",
             "Same FR-1 colony, default radius 450, days 1–20, fixed FPS 30; food / (20 × 11 starting foragers).",
             "Only the stated toggles/wait/mentor-eligibility overrides differ. No gameplay setting is selected.", "",
             "| Case | Median food | Food per seed | Matches per seed | Settled per seed |",
             "| --- | --- | --- | --- | --- |"]
    for (name, _), rows in zip(CASES, values):
        lines.append(f"| {name} | {median(row['food'] for row in rows):.4f} | "
                     + ", ".join(f"{row['food']:.4f}" for row in rows) + " | "
                     + ", ".join(str(row["matches"]) for row in rows) + " | "
                     + ", ".join(str(row["settled"]) for row in rows) + " |")
    lines.extend(["", "Paired food changes (each seed compared with itself):", "",
                  "| Controlled comparison | Per-seed change | Median paired change |",
                  "| --- | --- | --- |"])
    for title, before, after in (("Wait 1s vs 15s, recruitment enabled", 2, 4),
                                 ("Wait 1s vs 15s, mentors disabled in both", 5, 6),
                                 ("Species restrictions on vs off, recruitment disabled in both", 1, 7),
                                 ("Recruitment on vs off, species restrictions enabled in both", 7, 3)):
        changes = paired_changes(values[before], values[after])
        numeric = [value for value in changes if value is not None]
        middle = f"{median(numeric):+.1f}%" if numeric else "undefined (zero baseline)"
        lines.append(f"| {title} | " + ", ".join("undefined" if v is None else f"{v:+.1f}%" for v in changes) + f" | {middle} |")
    lines.extend(["", "Queue/population samples (means are sampled occupancy, not exact dwell time):", "",
                  "| Case | Peak foragers per seed | Mean seekers per seed | Mean mentors per seed | Delivery events/min per seed |",
                  "| --- | --- | --- | --- | --- |"])
    for (name, _), rows in zip(CASES, values):
        cells = [name, ", ".join(str(row["peak_foragers"]) for row in rows)]
        cells.extend(", ".join(f"{row[key]:.2f}" for row in rows) for key in
                     ("seeking_sample_mean", "mentoring_sample_mean", "delivery_events_per_sim_minute"))
        lines.append("| " + " | ".join(cells) + " |")
    lines.extend(["", "Limits: snapshot occupancy is coarse; delivered trips are a lower bound on scoring calls.",
                  "Existing logs do not capture every scored bout's sampled flowers/start point, so patch-selection",
                  "correctness still needs a focused runtime probe. The fourth original row combines species",
                  "restriction with recruitment; it does not isolate the effect of mentor species passing.",
                  "Shortening waits also changes later trips and random draws. These are paired finite-window",
                  "mechanism tests, not a recommendation to set the global wait to one second.", ""])
    return "\n".join(lines)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--baseline", type=Path, default=BASELINE)
    parser.add_argument("--output", type=Path, default=OUTPUT)
    parser.add_argument("--godot-path")
    parser.add_argument("--jobs", type=int, default=4)
    args = parser.parse_args()
    if args.jobs < 1:
        parser.error("--jobs must be positive")
    identity = tuning.fingerprint()
    args.output.mkdir(parents=True, exist_ok=True)
    values = []
    for case, (name, _) in enumerate(CASES):
        with ThreadPoolExecutor(max_workers=args.jobs) as pool:
            rows = list(pool.map(lambda seed: run_case(case, seed, identity, args.baseline, args.output, args.godot_path), stages.SEEDS))
        if [row["seed"] for row in rows] != list(stages.SEEDS):
            raise ValueError(f"Case {case}: result seeds do not match the requested seeds")
        values.append(rows)
        (args.output / "measurements.json").write_text(json.dumps({"fingerprint": identity, "values": values}, indent=2), encoding="utf-8")
        print(f"{name}: food={[round(row['food'], 4) for row in rows]}; matches={[row['matches'] for row in rows]}", flush=True)
    report = render(values, identity)
    (args.output / "report.md").write_text(report, encoding="utf-8")
    print(f"Evidence: {args.output / 'report.md'}", flush=True)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
