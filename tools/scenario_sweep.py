"""Run every short headless scenario and print one line each.

No verify.ps1 stage runs a scenario (Dave, 30 Sep 2026: about 190 s for 54 of
them is too much for every closeout), so a red scenario stays unseen until
someone runs this. The verification review does; so should any slice that
edits scripts/ behaviour a fixture asserts on, or test_scenarios/.

    python tools/scenario_sweep.py                 # all short scenarios
    python tools/scenario_sweep.py --only h5_      # names containing h5_

Exit code 0 when every scenario passed, 1 otherwise. Where Godot is found is
godot_compile_check.find_godot's business (MEADOW_GODOT_PATH, GODOT_PATH, the
Windows default, then PATH).
"""

from __future__ import annotations

import argparse
import re
import subprocess
import sys
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "tools"))

from godot_compile_check import find_godot  # noqa: E402

# Patterns for fixtures that are evidence campaigns or long arcs, not checks:
# each takes minutes, so the sweep leaves them to whoever asked for them.
LONG_RUNNING = (
    r"^foraging_features_", r"^alpha_arc_", r"^a2_seed_", r"^a3_fixedfps_",
    r"^perf2_", r"^slice3_timescale_", r"^recommendation_slice5_", r"^fr1_", r"evidence",
)


def short_scenarios(only: str) -> list[Path]:
    found = []
    for path in sorted((ROOT / "test_scenarios").glob("*_test.json")):
        if any(re.search(pattern, path.name) for pattern in LONG_RUNNING):
            continue
        if only and only not in path.name:
            continue
        found.append(path)
    return found


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    parser.add_argument("--only", default="", help="run only scenarios whose file name contains this")
    parser.add_argument("--timeout", type=int, default=200, help="seconds allowed per scenario")
    args = parser.parse_args()
    godot = find_godot()
    if not godot:
        print("error: no Godot found -- set MEADOW_GODOT_PATH", file=sys.stderr)
        return 2
    scenarios = short_scenarios(args.only)
    red = []
    started = time.time()
    for path in scenarios:
        try:
            finished = subprocess.run(
                [sys.executable, str(ROOT / "tools" / "run_scenario.py"), str(path), "--godot-path", godot],
                capture_output=True, text=True, timeout=args.timeout)
            verdict = next((line for line in finished.stdout.splitlines() if line.startswith("status=")), "no status line")
        except subprocess.TimeoutExpired:
            verdict = "status=timeout"
        verdict = re.sub(r" (run_id|result)=\S+", "", verdict)
        if not verdict.startswith("status=passed"):
            red.append(path.name)
        print("%-58s %s" % (path.name, verdict))
    print("\n%d scenarios, %d red, %.0f s" % (len(scenarios), len(red), time.time() - started))
    return 1 if red else 0


if __name__ == "__main__":
    sys.exit(main())
