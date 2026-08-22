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
import random
import subprocess
import sys
import tempfile
import time
import uuid
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from analyze_session import aggregate_runs, analyze, load_entries  # noqa: E402

ROOT = Path(__file__).resolve().parent.parent
DEFAULT_GODOT_PATH = r"C:\Program Files\Godot\Godot.exe"
DEFAULT_TIMEOUT = 300
# CHATGPT_INSIGHTS_PLAN.md's A3: the largest (fewest-steps-per-second)
# --fixed-fps value the benchmark in that section found still matches
# ordinary wall-clock timing on population/deaths/resources outcomes,
# while running noticeably faster in wall-clock terms since real-time
# sync is off. 0 (via --fixed-fps 0 on the CLI) falls back to ordinary
# wall-clock timing.
DEFAULT_FIXED_FPS = 30


def log_dir() -> Path:
    # Matches diagnostic_log.gd's LOG_DIR ("user://logs"), resolved the
    # same way Godot resolves user:// for this project on Windows.
    appdata = os.environ.get("APPDATA")
    if not appdata:
        raise RuntimeError("%APPDATA% not set -- can't find the Godot user:// dir")
    return Path(appdata) / "Godot" / "app_userdata" / "Meadow" / "logs"


def _scenario_declares_seed(scenario_path: Path) -> bool:
    """True if the scenario JSON pins its own "random_seed" -- in which
    case run_once leaves it alone so every repeat (and either side of a
    paired A/B comparison naming the same value) replays identically.
    Absent, run_once hands each launch a fresh seed instead of letting
    every run silently share main.gd's DEFAULT_RANDOM_SEED
    (CHATGPT_INSIGHTS_PLAN.md's A2).
    """
    try:
        data = json.loads(scenario_path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError):
        return False
    return isinstance(data, dict) and "random_seed" in data


def session_file_for_run_id(run_id: str) -> Path | None:
    """The session_*.jsonl this exact run wrote, found by the --run-id we
    passed at launch (CHATGPT_INSIGHTS_PLAN.md's A1) rather than by
    newest mtime -- two runs can share a filesystem mtime, and mtime alone
    can't tell this run's log apart from a stale file or Dave's own live
    play session either.
    """
    d = log_dir()
    if not d.is_dir():
        return None
    candidates = list(d.glob("session_*_%s.jsonl" % run_id))
    if not candidates:
        return None
    return candidates[0]


def _report_failure(label: str, stdout: str, stderr: str, tail_lines: int = 15) -> None:
    """A one-line classified error plus a short tail, not the full raw
    stdout/stderr (CHATGPT_INSIGHTS_PLAN.md's A4) -- a native crash's own
    traceback can be enormous, and dumping it straight to the terminal
    (or an AI caller's context window) buries the one line that actually
    says what went wrong. The full text still goes somewhere -- a temp
    file whose path is printed -- for whenever it's actually needed.
    """
    fd, path = tempfile.mkstemp(prefix="meadow_scenario_failure_", suffix=".log")
    with os.fdopen(fd, "w", encoding="utf-8") as f:
        f.write("--- stdout ---\n%s\n--- stderr ---\n%s\n" % (stdout, stderr))
    tail_source = stderr.strip() or stdout.strip()
    tail = tail_source.splitlines()[-tail_lines:]
    print("error: %s" % label, file=sys.stderr)
    print("  full output saved to: %s" % path, file=sys.stderr)
    for line in tail:
        print("  %s" % line, file=sys.stderr)


def run_once(scenario_path: Path, godot_path: str, timeout: int,
             fixed_fps: int | None = None) -> Path | None:
    """Launch one headless run and return the session_*.jsonl it wrote,
    or None (with an error already printed to stderr) if it didn't
    produce one.
    """
    run_id = uuid.uuid4().hex[:12]
    cmd = [godot_path, "--headless"]
    if fixed_fps is not None:
        # Godot's own built-in engine flag (CHATGPT_INSIGHTS_PLAN.md's A3),
        # not one of our own -- forces every frame to advance the engine by
        # exactly 1/fixed_fps of simulated time and disables real-time
        # sync, instead of measuring real wall-clock elapsed time each
        # frame the way an ordinary run (fixed_fps=None) does. Runs as fast
        # as the CPU allows rather than throttled to real time, and removes
        # the wall-clock scheduling jitter A2 found perturbing same-seed
        # reproducibility.
        cmd += ["--fixed-fps", str(fixed_fps)]
    cmd += ["--path", str(ROOT), "--",
            "--scenario=%s" % scenario_path, "--run-id=%s" % run_id]
    if not _scenario_declares_seed(scenario_path):
        # No pinned seed -- hand this launch its own, so N repeats of the
        # same scenario are genuinely independent draws instead of N
        # identical replays of main.gd's DEFAULT_RANDOM_SEED.
        cmd.append("--random-seed=%d" % random.randint(0, 2**31 - 1))
    print("running: %s" % " ".join(cmd))

    start = time.time()
    try:
        result = subprocess.run(cmd, timeout=timeout, capture_output=True, text=True)
    except subprocess.TimeoutExpired:
        print("error: scenario run exceeded %ds timeout, killed" % timeout, file=sys.stderr)
        return None
    except OSError as e:
        # e.g. godot_path doesn't exist or isn't executable -- no
        # stdout/stderr was ever captured, so there's nothing to save.
        print("error: could not launch Godot at %r: %s" % (godot_path, e), file=sys.stderr)
        return None
    print("wall time: %.1fs" % (time.time() - start))

    session_file = session_file_for_run_id(run_id)
    if session_file is None:
        label = ("Godot exited with code %d and " % result.returncode if result.returncode != 0
                  else "") + "no session_*_%s.jsonl written after this run" % run_id
        _report_failure(label, result.stdout, result.stderr)
        return None

    # A non-zero exit that still produced a valid session file is only
    # worth a short heads-up, not the capped-artifact treatment above --
    # the run's own data is intact either way.
    if result.returncode != 0:
        print("warning: Godot exited with code %d (session file still written)" % result.returncode,
              file=sys.stderr)

    return session_file


def _warn_on_action_problems(analysis: dict) -> None:
    """Prints a short, hard-to-miss warning when a scenario's actions
    block (scenario_actions.gd) didn't go cleanly -- a rejected action, an
    action whose "when" never fired, or a failed "assert" ending the run.
    Printed even when --full is off, since a strategy script silently not
    doing what it said is exactly the failure mode
    insights_from_ChatGPT.md's 22 Aug 2026 entry asked assertions to catch
    loudly.
    """
    problems = analysis.get("actions", {}).get("problems", [])
    if not problems:
        return
    print("warning: %d scenario action(s) did not complete cleanly:" % len(problems),
          file=sys.stderr)
    for p in problems:
        print("  %s (%s): %s -- %s" % (p["do"], p["target"], p["result"], p["reason"]),
              file=sys.stderr)


def run_scenario(scenario_path: Path, godot_path: str, timeout: int, repeat: int,
                  full: bool, fixed_fps: int | None = None) -> int:
    if not scenario_path.is_file():
        print("error: scenario file not found: %s" % scenario_path, file=sys.stderr)
        return 1

    analyses = []
    for i in range(repeat):
        if repeat > 1:
            print("--- run %d/%d ---" % (i + 1, repeat))
        session_file = run_once(scenario_path, godot_path, timeout, fixed_fps)
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
        _warn_on_action_problems(analysis)
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
    parser.add_argument("--fixed-fps", type=int, default=DEFAULT_FIXED_FPS,
                         help="advance the engine by a fixed 1/N seconds per frame instead of "
                              "measuring real wall-clock time (Godot's own --fixed-fps flag) -- "
                              "runs at full CPU speed and removes the timing jitter that made "
                              "same-seed reruns diverge (CHATGPT_INSIGHTS_PLAN.md's A2/A3). "
                              "Pass 0 to fall back to ordinary wall-clock timing "
                              "(default: %(default)s)")
    args = parser.parse_args()

    if args.repeat < 1:
        print("error: --repeat must be at least 1", file=sys.stderr)
        return 1

    fixed_fps = args.fixed_fps if args.fixed_fps != 0 else None
    return run_scenario(args.scenario, args.godot_path, args.timeout, args.repeat, args.full,
                         fixed_fps)


if __name__ == "__main__":
    sys.exit(main())
