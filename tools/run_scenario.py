#!/usr/bin/env python3
"""Run one headless scenario and print its summary -- once, or N times.

Slice 4 of AI_PLAYTEST_PLAN.md built the single-run wrapper around the
`--scenario=` boot path slices 1-3 built in scripts/main.gd. Slice 5
adds `--repeat N` (bee behaviour has randomness -- scouting, trait rolls
-- so one run isn't enough to conclude anything about balance from) and
`--full` (the richer per-run analysis analyze_session.py builds:
population curve, deaths over time, honey-fill vs winter, and whether
crab_spider_event/recruitment_match/scouting_settled counts are nonzero
when their toggles are on).

Still shells out to Godot directly (the installed MCP server has no
headless mode or argument passthrough -- see AI_PLAYTEST_PLAN.md's
"What's missing"), waits with a real-world timeout per run so a runaway
or hung sim can't hang a session, then finds the session_*.jsonl each
run just wrote.

Usage:
    python3 tools/run_scenario.py test_scenarios/slice1_smoke_test.json
    python3 tools/run_scenario.py test_scenarios/foo.json --timeout 120
    python3 tools/run_scenario.py test_scenarios/foo.json --repeat 5
    python3 tools/run_scenario.py test_scenarios/foo.json --full
"""

import argparse
import json
import os
import subprocess
import sys
import time
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from analyze_session import aggregate_runs, analyze, load_entries  # noqa: E402

ROOT = Path(__file__).resolve().parent.parent
DEFAULT_GODOT_PATH = r"C:\Program Files\Godot\Godot.exe"
DEFAULT_TIMEOUT = 300


def log_dir() -> Path:
    # Matches diagnostic_log.gd's LOG_DIR ("user://logs"), resolved the
    # same way Godot resolves user:// for this project on Windows.
    appdata = os.environ.get("APPDATA")
    if not appdata:
        raise RuntimeError("%APPDATA% not set -- can't find the Godot user:// dir")
    return Path(appdata) / "Godot" / "app_userdata" / "Meadow" / "logs"


def newest_session_file(after: float) -> Path | None:
    """The session_*.jsonl with the newest mtime, if it's newer than `after`.

    `after` should be the wall-clock time just before the run started, so
    a stale file left over from an earlier run (or Dave's own play)
    doesn't get mistaken for this run's output.
    """
    d = log_dir()
    if not d.is_dir():
        return None
    candidates = [p for p in d.glob("session_*.jsonl") if p.stat().st_mtime >= after]
    if not candidates:
        return None
    return max(candidates, key=lambda p: p.stat().st_mtime)


def run_once(scenario_path: Path, godot_path: str, timeout: int) -> Path | None:
    """Launch one headless run and return the session_*.jsonl it wrote,
    or None (with an error already printed to stderr) if it didn't
    produce one.
    """
    start = time.time()
    cmd = [godot_path, "--headless", "--path", str(ROOT), "--",
           "--scenario=%s" % scenario_path]
    print("running: %s" % " ".join(cmd))

    try:
        result = subprocess.run(cmd, timeout=timeout, capture_output=True, text=True)
    except subprocess.TimeoutExpired:
        print("error: scenario run exceeded %ds timeout, killed" % timeout, file=sys.stderr)
        return None

    if result.returncode != 0:
        print("warning: Godot exited with code %d" % result.returncode, file=sys.stderr)
        if result.stderr.strip():
            print(result.stderr, file=sys.stderr)

    session_file = newest_session_file(start)
    if session_file is None:
        print("error: no session_*.jsonl written after this run", file=sys.stderr)
        if result.stdout.strip():
            print("--- Godot stdout ---", file=sys.stderr)
            print(result.stdout, file=sys.stderr)
        return None

    return session_file


def run_scenario(scenario_path: Path, godot_path: str, timeout: int, repeat: int,
                  full: bool) -> int:
    if not scenario_path.is_file():
        print("error: scenario file not found: %s" % scenario_path, file=sys.stderr)
        return 1

    analyses = []
    for i in range(repeat):
        if repeat > 1:
            print("--- run %d/%d ---" % (i + 1, repeat))
        session_file = run_once(scenario_path, godot_path, timeout)
        if session_file is None:
            return 1

        entries = load_entries(session_file)
        analysis = analyze(entries)
        if analysis["summary"] is None:
            print("error: %s has no summary line -- run may not have finished" % session_file,
                  file=sys.stderr)
            return 1

        print("session file: %s" % session_file)
        if full or repeat == 1:
            print(json.dumps(analysis if full else analysis["summary"], indent=2))
        analyses.append(analysis)

    if repeat > 1:
        print("--- aggregate over %d runs ---" % repeat)
        print(json.dumps(aggregate_runs(analyses), indent=2))

    return 0


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__,
                                      formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("scenario", type=Path, help="path to a scenario JSON file")
    parser.add_argument("--timeout", type=int, default=DEFAULT_TIMEOUT,
                         help="real-world seconds to wait before giving up, per run (default: %(default)s)")
    parser.add_argument("--godot-path", default=DEFAULT_GODOT_PATH,
                         help="path to the Godot executable (default: %(default)s)")
    parser.add_argument("--repeat", type=int, default=1,
                         help="run the scenario this many times and report a range, not a "
                              "single point (default: %(default)s)")
    parser.add_argument("--full", action="store_true",
                         help="print the full per-run analysis (population curve, deaths "
                              "over time, honey fill vs winter, mechanic-firing check) "
                              "instead of just the summary line")
    args = parser.parse_args()

    if args.repeat < 1:
        print("error: --repeat must be at least 1", file=sys.stderr)
        return 1

    return run_scenario(args.scenario, args.godot_path, args.timeout, args.repeat, args.full)


if __name__ == "__main__":
    sys.exit(main())
