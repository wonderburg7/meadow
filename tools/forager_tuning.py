#!/usr/bin/env python3
"""Sweep existing foraging settings on FR-1's four stages and five seeds.

Keep the colony, window, skills and stage toggles fixed. Results are cached
under build/fr1b-tuning and recorded in the owning plan, including failed
sweeps. Exit 2 means the measured candidates need Dave's decision; it is not
evidence that every possible real-valued configuration is impossible.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import subprocess
import sys
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path
from statistics import median

try:
    from tools import forager_stages as stages
except ModuleNotFoundError:
    import forager_stages as stages

ROOT = stages.ROOT
PLAN = ROOT / "plans/now/forager-recruitment.md"
OUTPUT = ROOT / "build/fr1b-tuning"
START = "<!-- FR-1b tuning evidence -->"
END = "<!-- /FR-1b tuning evidence -->"
DEFAULTS = {
    "forage_start_radius": 450.0,
    "recruit_wait_seconds": 15.0,
    "recruit_lower_threshold_nectar": 0.27,
    "recruit_upper_threshold_nectar": 0.45,
    "recruit_lower_threshold_pollen": 0.23,
    "recruit_upper_threshold_pollen": 0.31,
    "recruit_start_point_jitter": 150.0,
    "recruit_grace_trips": 3.0,
}
RADII = (100.0, 200.0, 450.0, 900.0, 1500.0)
SCREEN_RADII = (300.0, 600.0, 1200.0)
BANDS = (
    (0.27, 0.45, 0.23, 0.31),  # current calibrated thresholds
    (0.10, 0.25, 0.08, 0.18),  # fewer seekers, more mentors
    (0.35, 0.55, 0.25, 0.40),  # more seekers, stronger mentors
)
BAND_KEYS = ("recruit_lower_threshold_nectar", "recruit_upper_threshold_nectar",
             "recruit_lower_threshold_pollen", "recruit_upper_threshold_pollen")


def figures(values: list[list[float]]) -> tuple[list[float], list[float]]:
    middles = [median(row) for row in values]
    ratios = [b / a if a > 0 else 0.0 for a, b in zip(middles, middles[1:])]
    return middles, ratios


def accepted(values: list[list[float]]) -> bool:
    """Use unrounded medians: every row rises, recruitment gains >=30%."""
    middles, _ = figures(values)
    return (len(middles) == 4 and all(b > a > 0 for a, b in zip(middles, middles[1:]))
            and middles[2] >= 1.3 * middles[1])


def rank(result: dict) -> tuple[float, float]:
    middles, ratios = figures(result["values"])
    return min(ratios[0], ratios[1] / 1.3, ratios[2]), middles[2]


def scenario(settings: dict, stage: int, seed: int) -> dict:
    result = stages._scenario(stages.STAGES[stage][1], seed)
    result["config_overrides"].update(settings)
    return result


def effective_settings(settings: dict, stage: int) -> dict:
    # go_to_exit/wait_at_entrance alone read wait/bands/jitter. _score_trip
    # also reads grace for scouting's EMA, so retain it for stage 1.
    if stage == 0:
        return {"forage_start_radius": settings["forage_start_radius"]}
    if stage == 1:
        return {key: settings[key] for key in ("forage_start_radius", "recruit_grace_trips")}
    return settings


def fingerprint() -> str:
    digest = hashlib.sha256(b"fr1b-metric-v2-fixed-fps-30")
    tracked = subprocess.run(["git", "ls-files", "--", "*.gd", "*.tscn", "*.tres"],
                             cwd=ROOT, capture_output=True, text=True, check=True)
    sources = [ROOT / name for name in tracked.stdout.splitlines()]
    for path in [stages.SCENARIO, Path(stages.__file__), ROOT / "project.godot", *sources]:
        digest.update(str(path.relative_to(ROOT)).encode())
        digest.update(path.read_bytes())
    return digest.hexdigest()


def run_one(settings: dict, stage: int, seed: int, output: Path,
            identity: str, godot: str | None) -> float:
    active = effective_settings(settings, stage)
    key = hashlib.sha256(json.dumps([identity, godot, stage, seed, active], sort_keys=True).encode()).hexdigest()
    run_root = output / "runs" / key
    cached = run_root / "measurement.json"
    if cached.exists():
        return json.loads(cached.read_text(encoding="utf-8"))["food_per_forager_day"]
    run_root.mkdir(parents=True, exist_ok=True)
    path = run_root / "scenario.json"
    path.write_text(json.dumps(scenario(active, stage, seed)), encoding="utf-8")
    command = [sys.executable, str(ROOT / "tools/run_scenario.py"), str(path),
               "--fixed-fps", "30", "--result-root", str(run_root / "results")]
    if godot:
        command.extend(("--godot-path", godot))
    completed = subprocess.run(command, capture_output=True, text=True, check=False)
    (run_root / "runner.log").write_text(completed.stdout + "\n" + completed.stderr, encoding="utf-8")
    match = stages.RESULT_PATTERN.search(completed.stdout)
    if completed.returncode or "status=passed" not in completed.stdout or not match:
        raise RuntimeError(f"stage {stage}, seed {seed} failed; see {run_root / 'runner.log'}")
    report = Path(match.group(1)).parent / "report.json"
    summary = json.loads(report.read_text(encoding="utf-8"))["summary"]
    toggles = stages.STAGES[stage][1]
    for toggle, metric in (("orientation_flight_on", "orientation_flights"), ("scouting_on", "scouting_settled")):
        if not toggles[toggle] and summary.get(metric, 0) > 0:
            raise RuntimeError(f"stage {stage}, seed {seed}: {metric} leaked; see {report}")
    value = stages.delivery_per_forager_day(summary)
    cached.write_text(json.dumps({"food_per_forager_day": value, "report": str(report)}), encoding="utf-8")
    return value


def measure(settings: dict, output: Path, identity: str, godot: str | None, jobs: int,
            stage_count: int = 4) -> dict:
    pairs = [(stage, seed) for stage in range(stage_count) for seed in stages.SEEDS]
    with ThreadPoolExecutor(max_workers=jobs) as pool:
        values = list(pool.map(lambda pair: run_one(settings, *pair, output, identity, godot), pairs))
    width = len(stages.SEEDS)
    return {"settings": settings, "values": [values[i:i + width] for i in range(0, len(values), width)]}


def band_candidates(settings: dict) -> list[dict]:
    return [dict(settings, recruit_wait_seconds=wait, **dict(zip(BAND_KEYS, band)))
            for wait in (1.0, 5.0, 15.0) for band in BANDS]


def refinement_candidates(settings: dict) -> list[dict]:
    return [dict(settings, recruit_start_point_jitter=jitter, recruit_grace_trips=grace)
            for jitter in (0.0, 75.0, 150.0, 300.0) for grace in (0.0, 1.0, 3.0, 6.0)]


def render(results: list[dict], identity: str, screens: list[dict] | None = None) -> str:
    passing = [result for result in results if accepted(result["values"])]
    best = max(passing or results, key=rank)
    lines = ["### Tuning sweep evidence", "",
             f"Simulation fingerprint: `{identity}`. Seeds: {', '.join(map(str, stages.SEEDS))}.",
             "Window: days 1–20; food is nectar plus pollen delivered / (20 days × 11 starting foragers).",
             "Each candidate uses the same settings for all four stages; only FR-1's stage toggles differ.", "",
             "Search: five full start-radius trials and three intermediate radii screened on the first two stages;",
             "wait × threshold-band sweep at every radius where scouting improves;",
             "then spread × grace refinement of the two strongest distinct candidates.",
             "The finite sweep does not prove that no other real-valued combination could work.",
             "Closest means the strongest minimum of scouting/orientation, recruitment/scouting ÷ 1.3,",
             "and species-passing/recruitment; ties favour recruitment's median food delivery.", "",
             f"Measured {len(results)} distinct configurations. " +
             ("**PASS**: all four median rows rise and recruitment gains at least 30%." if passing else
              "**DECISION REQUIRED**: no measured configuration meets both requirements; FR-2 remains blocked."), "",
             ("Selected existing values:" if passing else "Closest measured values (not selected for gameplay):"), "",
             "```json", json.dumps(best["settings"], indent=2), "```", "",
             "| Stage | Median food per forager per day | Per seed (7, 555, 2026, 12345, 90210) | vs previous |",
             "| --- | --- | --- | --- |"]
    for (name, _), values, (middle, ratio) in zip(stages.STAGES, best["values"], stages.stage_rows(best["values"])):
        lines.append(f"| {name} | {middle:.4f} | {', '.join(f'{value:.4f}' for value in values)} | {ratio} |")
    lines.extend(["", "All candidates below use those same five seeds. Ratios are rounded for display only.", "",
                  "| Candidate | Radius | Wait | Nectar band | Pollen band | Spread | Grace | Stage medians | Ratios | Pass |",
                  "| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |"])
    for i, result in enumerate(results, 1):
        settings = result["settings"]
        middles, ratios = figures(result["values"])
        row = [str(i), str(settings["forage_start_radius"]), str(settings["recruit_wait_seconds"]),
               f'{settings[BAND_KEYS[0]]}/{settings[BAND_KEYS[1]]}',
               f'{settings[BAND_KEYS[2]]}/{settings[BAND_KEYS[3]]}',
               str(settings["recruit_start_point_jitter"]), str(settings["recruit_grace_trips"]),
               ", ".join(f"{value:.4f}" for value in middles),
               ", ".join(f"{value:.3f}x" for value in ratios), str(accepted(result["values"]))]
        lines.append("| " + " | ".join(row) + " |")
    if screens:
        lines.extend(["", "Intermediate-radius first-gate screen (same colony, window and five seeds):", "",
                      "| Radius | Orientation flight, per seed | Auto scouting, per seed | Median ratio |",
                      "| --- | --- | --- | --- |"])
        for result in screens:
            _, ratios = figures(result["values"])
            cells = [str(result["settings"]["forage_start_radius"])]
            cells.extend(", ".join(f"{value:.4f}" for value in row) for row in result["values"])
            cells.append(f"{ratios[0]:.3f}x")
            lines.append("| " + " | ".join(cells) + " |")
    return "\n".join(lines) + "\n"


def record_plan(report: str, path: Path = PLAN) -> None:
    text = path.read_text(encoding="utf-8")
    section = "## FR-1b -- tune the measured foraging-stage order"
    start = text.index(section)
    end = text.index("\n## ", start + len(section))
    existing = text[start:end]
    block = START + "\n" + report + END + "\n"
    if START in existing:
        before, rest = existing.split(START, 1)
        _, after = rest.split(END, 1)
        existing = before + block.rstrip("\n") + after
    else:
        existing = existing.rstrip() + "\n\n" + block + "\n"
    path.write_text(text[:start] + existing + text[end:], encoding="utf-8")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--godot-path")
    parser.add_argument("--jobs", type=int, default=4)
    parser.add_argument("--output", type=Path, default=OUTPUT)
    args = parser.parse_args()
    if args.jobs < 1:
        parser.error("--jobs must be positive")
    identity = fingerprint()
    args.output.mkdir(parents=True, exist_ok=True)
    results: list[dict] = []
    seen: set[str] = set()

    def campaign(candidates: list[dict]) -> None:
        for settings in candidates:
            key = json.dumps(settings, sort_keys=True)
            if key in seen:
                continue
            result = measure(settings, args.output, identity, args.godot_path, args.jobs)
            seen.add(key)
            results.append(result)
            (args.output / "sweep.json").write_text(json.dumps({"fingerprint": identity, "results": results}, indent=2), encoding="utf-8")
            middles, ratios = figures(result["values"])
            print(f"Candidate {len(results)}: medians {[round(v, 4) for v in middles]}; "
                  f"ratios {[round(v, 3) for v in ratios]}; pass={accepted(result['values'])}", flush=True)

    campaign([dict(DEFAULTS, forage_start_radius=radius) for radius in RADII])
    screens = [measure(dict(DEFAULTS, forage_start_radius=radius), args.output, identity,
                       args.godot_path, args.jobs, stage_count=2) for radius in SCREEN_RADII]
    (args.output / "radius_screen.json").write_text(
        json.dumps({"fingerprint": identity, "results": screens}, indent=2), encoding="utf-8")
    campaign([result["settings"] for result in screens if figures(result["values"])[1][0] > 1.0])
    improving = [result for result in results if figures(result["values"])[1][0] > 1.0]
    campaign([candidate for result in improving for candidate in band_candidates(result["settings"])])
    strongest = sorted(results, key=rank, reverse=True)[:2]
    campaign([candidate for result in strongest for candidate in refinement_candidates(result["settings"])])
    report = render(results, identity, screens)
    (args.output / "report.md").write_text(report, encoding="utf-8")
    record_plan(report)
    print(f"Evidence: {args.output / 'report.md'}; recorded in {PLAN}", flush=True)
    return 0 if any(accepted(result["values"]) for result in results) else 2


if __name__ == "__main__":
    raise SystemExit(main())
