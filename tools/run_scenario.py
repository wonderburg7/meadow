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
import ctypes
import hashlib
import json
import os
import random
import re
import subprocess
import sys
import tempfile
import time
import uuid
from contextlib import contextmanager
from pathlib import Path
from typing import Any

sys.path.insert(0, str(Path(__file__).resolve().parent))
from diagnostics import write_event  # noqa: E402
from analyze_session import REPORT_PROFILES, aggregate_runs, analyze, load_entries, report  # noqa: E402
from godot_compile_check import failing_lines  # noqa: E402
import godot_cache  # noqa: E402
from headless.contracts import SCHEMA_VERSION, fits_stdout_budget  # noqa: E402
from headless.experiments import (ContractError as ExperimentContractError, aggregate_case_metrics,
                                  compose_case_scenario, evaluate_aggregate_expectations,
                                  required_metrics, validate_manifest)  # noqa: E402
from headless.jobs import (DEFAULT_JOB_ROOT, HeadlessRunOutcome, JobError,
                           run_headless_process, submit_job)  # noqa: E402
from headless.profiles import validate_diagnostics  # noqa: E402
from headless.route import ROUTING_CARD  # noqa: E402
from headless.verdicts import ContractError, evaluate_expectations, validate_expectations  # noqa: E402

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
DEFAULT_RESULT_ROOT = Path(tempfile.gettempdir()) / "meadow-headless-results"
BASELINE_PROBE_TIMEOUT = 30
_WINDOWS_HEADLESS_ERROR_MODE = 0x0001 | 0x0002  # SEM_FAILCRITICALERRORS | SEM_NOGPFAULTERRORBOX


@contextmanager
def _suppress_windows_crash_dialogs():
    """Keep a crashed unattended Godot child from opening a Windows modal.

    The process error mode is inherited when subprocess starts Godot. It is
    restored immediately afterwards so the Python runner does not alter the
    caller's normal error-dialog behaviour.
    """
    if os.name != "nt":
        yield
        return
    kernel32 = ctypes.windll.kernel32
    kernel32.GetErrorMode.restype = ctypes.c_uint
    kernel32.SetErrorMode.argtypes = [ctypes.c_uint]
    kernel32.SetErrorMode.restype = ctypes.c_uint
    previous = kernel32.GetErrorMode()
    kernel32.SetErrorMode(previous | _WINDOWS_HEADLESS_ERROR_MODE)
    try:
        yield
    finally:
        kernel32.SetErrorMode(previous)


def log_dir() -> Path:
    # Matches diagnostic_log.gd's LOG_DIR ("user://logs"), resolved from the
    # project name rather than a stale literal.  Godot uses config/name for
    # the app_userdata directory, and a renamed project must not make a
    # completed scenario look as though it wrote no result.
    appdata = os.environ.get("APPDATA")
    if not appdata:
        raise RuntimeError("%APPDATA% not set -- can't find the Godot user:// dir")
    project_text = (ROOT / "project.godot").read_text(encoding="utf-8")
    name_match = re.search(r'^config/name="([^"]+)"$', project_text, re.MULTILINE)
    if name_match is None:
        raise RuntimeError("project.godot has no config/name -- can't find the Godot user:// dir")
    return Path(appdata) / "Godot" / "app_userdata" / name_match.group(1) / "logs"


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
             fixed_fps: int | None = None, seed_override: int | None = None) -> Path | None:
    """Launch one headless run and return the session_*.jsonl it wrote,
    or None (with an error already printed to stderr) if it didn't
    produce one.
    """
    run_id = uuid.uuid4().hex[:12]
    cmd = [godot_path, "--headless", "--disable-crash-handler"]
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
    if seed_override is not None:
        cmd.append("--random-seed=%d" % seed_override)
    elif not _scenario_declares_seed(scenario_path):
        # No pinned seed -- hand this launch its own, so N repeats of the
        # same scenario are genuinely independent draws instead of N
        # identical replays of main.gd's DEFAULT_RANDOM_SEED.
        cmd.append("--random-seed=%d" % random.randint(0, 2**31 - 1))
    print("running: %s" % " ".join(cmd))

    start = time.time()
    try:
        with _suppress_windows_crash_dialogs():
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


def _scenario_metadata(scenario_path: Path, seed: int | None) -> dict[str, Any]:
    content = scenario_path.read_bytes()
    return {"path": str(scenario_path), "sha256": hashlib.sha256(content).hexdigest(), "seed": seed}


def _write_json(path: Path, data: dict[str, Any]) -> None:
    path.write_text(json.dumps(data, indent=2, sort_keys=True) + "\n", encoding="utf-8")


def _exit_code_detail(returncode: int | None) -> dict[str, Any]:
    """Keep Windows' signed process status and its native exception code."""
    detail: dict[str, Any] = {"exit_code": returncode}
    if returncode is not None and returncode < 0:
        detail["windows_exception"] = "0x%08X" % (returncode & 0xFFFFFFFF)
    return detail


def run_baseline_probe(godot_path: str, result_dir: Path, timeout: int) -> dict[str, Any]:
    """Record a minimal executable/project boot before a smoke scenario.

    This is deliberately not a scenario verdict.  It establishes whether the
    installed engine can report its version and open this project far enough
    to initialise the editor, keeping a native Godot exit distinct from a
    gameplay expectation failure.
    """
    version_command = [godot_path, "--version"]
    launch_command = [godot_path, "--headless", "--disable-crash-handler",
                      "--path", str(ROOT), "--editor", "--quit"]
    log_path = result_dir / "baseline_probe.log"
    started_at = time.monotonic()
    probe: dict[str, Any] = {
        "kind": "baseline_probe", "timeout_seconds": timeout,
        "godot_path": godot_path, "version_command": version_command,
        "launch_command": launch_command, "artefacts": {"log": log_path.name},
    }
    try:
        with _suppress_windows_crash_dialogs():
            version = run_headless_process(version_command, timeout)
            launch = run_headless_process(launch_command, timeout)
    except OSError as error:
        probe.update({"classification": "environment_failure", "status": "launch_error",
                      "reason": {"kind": "launch", "message": str(error)}})
        log_path.write_text(str(error) + "\n", encoding="utf-8")
    else:
        log_path.write_text(
            "--- version stdout ---\n%s\n--- version stderr ---\n%s\n"
            "--- launch stdout ---\n%s\n--- launch stderr ---\n%s\n" %
            (version.stdout, version.stderr, launch.stdout, launch.stderr), encoding="utf-8"
        )
        version_info = {"execution": version.kind, "output": version.stdout.strip()}
        version_info.update(_exit_code_detail(version.returncode))
        launch_info = {"execution": launch.kind}
        launch_info.update(_exit_code_detail(launch.returncode))
        probe.update({"version": version_info, "launch": launch_info,
                      "wall_seconds": round(time.monotonic() - started_at, 6)})
        if version.kind != "completed" or version.returncode != 0:
            probe.update({"classification": "environment_failure", "status": "version_failed",
                          "reason": {"kind": "version", "message": version.message}})
        elif launch.kind == "timed_out":
            probe.update({"classification": "timeout", "status": "timed_out",
                          "reason": {"kind": "timeout", "message": launch.message}})
        elif launch.kind != "completed" or launch.returncode != 0:
            probe.update({"classification": "environment_failure", "status": "native_exit",
                          "reason": {"kind": "native_exit", "message": launch.message}})
        else:
            probe.update({"classification": "pass", "status": "passed"})
    _write_json(result_dir / "baseline_probe.json", probe)
    return probe


def _failure_capsule(*, status: str, run_id: str, reason: dict[str, Any],
                     entries: list[dict[str, Any]], artefacts: dict[str, str]) -> dict[str, Any]:
    """Bounded evidence for an unsuccessful run; raw data stays on disk."""
    capsule = {
        "schema_version": SCHEMA_VERSION, "status": status, "run_id": run_id, "reason": reason,
        "actions": [entry for entry in entries if entry.get("type") == "action"][-5:],
        "events": [entry for entry in entries if entry.get("type") not in
                   {"config", "snapshot", "summary", "action"}][-5:],
        "snapshot": next((entry for entry in reversed(entries)
                          if entry.get("type") == "snapshot"), None),
        "artefacts": artefacts, "truncated": False,
    }
    if len(json.dumps(capsule, separators=(",", ":")).encode("utf-8")) > 4096:
        capsule["actions"] = []
        capsule["events"] = []
        capsule["snapshot"] = None
        capsule["truncated"] = True
    return capsule


def _write_failure(run_dir: Path, *, status: str, run_id: str, reason: dict[str, Any],
                   entries: list[dict[str, Any]], artefacts: dict[str, str]) -> Path:
    capsule = _failure_capsule(status=status, run_id=run_id, reason=reason,
                               entries=entries, artefacts=artefacts)
    path = run_dir / "failure.json"
    _write_json(path, capsule)
    if not fits_stdout_budget(path.read_bytes(), failed=True):
        capsule["actions"] = []
        capsule["events"] = []
        capsule["snapshot"] = None
        capsule["truncated"] = True
        _write_json(path, capsule)
    return path


def _terminal_line(status: str, run_id: str, result_path: Path, *,
                   outcome: str | None = None, reason: str | None = None) -> str:
    fields = ["status=%s" % status, "run_id=%s" % run_id]
    if outcome is not None:
        fields.append("outcome=%s" % outcome)
    if reason is not None:
        fields.append("reason=%s" % reason)
    fields.append("result=%s" % result_path)
    return " ".join(fields)


def _compile_failure_details(process_log: Path) -> tuple[str, str | None] | None:
    """Return the primary build failure and its script, if it did not compile.

    Use the boot-time compile check's exact matcher so the two headless entry
    points cannot drift over which Godot diagnostics make a build unrunnable.
    """
    output = process_log.read_text(encoding="utf-8")
    hits = failing_lines(output)
    if not hits:
        return None
    # Godot's SCRIPT ERROR line is the useful primary diagnosis. A following
    # Parse Error or load failure supplies context, but is not a better first
    # action for someone repairing the broken script.
    error_line = next((line for line in hits if line.startswith("SCRIPT ERROR:")), hits[0])
    script_match = re.search(r"res://[A-Za-z0-9_./-]+\.gd", output)
    return error_line, script_match.group(0) if script_match else None


def _report_compile_failure(error_line: str, script: str | None, process_log: Path) -> None:
    print("error: compile failure: %s" % error_line, file=sys.stderr)
    if script is not None:
        print("  script: %s" % script, file=sys.stderr)
    print("  process log: %s" % process_log, file=sys.stderr)
    # New worktrees normally have no imported cache; an unrelated parse error
    # becomes visible on their first headless boot, rather than being hidden by
    # an existing cache from an older checkout.
    if ROOT.joinpath(".git").is_file() and not ROOT.joinpath(".godot").is_dir():
        print("  note: this worktree has no .godot import cache; its first headless boot "
              "commonly exposes a pre-existing script compile error.", file=sys.stderr)


def run_verdict_scenario(scenario_path: Path, godot_path: str, timeout: int,
                         fixed_fps: int | None, result_root: Path,
                         seed_override: int | None = None, emit: bool = True) -> int:
    """Launch one scenario into its own artefact directory and print one verdict."""
    run_id = uuid.uuid4().hex[:12]
    run_dir = result_root / ("run-%d-%s" % (int(time.time() * 1000), run_id))
    run_dir.mkdir(parents=True, exist_ok=False)
    process_log = run_dir / "process.log"
    session_path = run_dir / "session.jsonl"
    result_path = run_dir / "result.json"
    artefacts = {"session": session_path.name, "process_log": process_log.name}
    metadata: dict[str, Any] = {"path": str(scenario_path), "sha256": "", "seed": None}
    entries: list[dict[str, Any]] = []
    diagnostics: dict[str, Any] = validate_diagnostics(None)

    try:
        if not scenario_path.is_file():
            raise ContractError("scenario file not found: %s" % scenario_path)
        data = json.loads(scenario_path.read_text(encoding="utf-8"))
        if not isinstance(data, dict):
            raise ContractError("scenario must be a JSON object")
        expectations = validate_expectations(data.get("expect"))
        diagnostics = validate_diagnostics(data.get("diagnostics"))
        raw_seed = data.get("random_seed")
        requested_seed = raw_seed if isinstance(raw_seed, int) and not isinstance(raw_seed, bool) else None
        metadata = _scenario_metadata(scenario_path, requested_seed)
    except (OSError, json.JSONDecodeError, ContractError) as error:
        reason = {"kind": "contract", "message": str(error)}
        failure_path = _write_failure(run_dir, status="contract_error", run_id=run_id,
                                      reason=reason, entries=entries, artefacts=artefacts)
        result = {
            "schema_version": SCHEMA_VERSION, "status": "contract_error", "run_id": run_id,
            "scenario": {"path": metadata["path"], "sha256": metadata["sha256"]},
            "seed": metadata["seed"], "diagnostics": {"profile": diagnostics["profile"], "version": diagnostics["version"]},
            "outcome": None, "simulated": {"seconds": None, "day": None},
            "actions": {"rejected": 0, "failed": 0, "unresolved": 0},
            "expectations": {"passed": [], "failed": []}, "process": {"exit_code": None},
            "artefacts": dict(artefacts, failure=failure_path.name),
        }
        _write_json(result_path, result)
        line = _terminal_line("contract_error", run_id, result_path, reason="contract")
        assert fits_stdout_budget(line + "\n", failed=True)
        if emit:
            print(line)
        return 1

    if data.get("baseline_probe") is True:
        probe = run_baseline_probe(godot_path, run_dir, min(timeout, BASELINE_PROBE_TIMEOUT))
        artefacts["baseline_probe"] = "baseline_probe.json"
        if probe["classification"] != "pass":
            reason = {"kind": "baseline_probe", "probe_status": probe["status"]}
            result = {
                "schema_version": SCHEMA_VERSION, "status": "crashed", "run_id": run_id,
                "classification": probe["classification"],
                "scenario": {"path": metadata["path"], "sha256": metadata["sha256"]},
                "seed": metadata["seed"], "diagnostics": {"profile": diagnostics["profile"], "version": diagnostics["version"]},
                "outcome": None, "simulated": {"seconds": None, "day": None},
                "actions": {"rejected": 0, "failed": 0, "unresolved": 0},
                "expectations": {"passed": [], "failed": []},
                "process": {"exit_code": None, "pid": None, "execution": "baseline_probe", "wall_seconds": 0},
                "artefacts": artefacts,
            }
            failure_path = _write_failure(run_dir, status="crashed", run_id=run_id, reason=reason,
                                          entries=entries, artefacts=artefacts)
            result["artefacts"] = dict(artefacts, failure=failure_path.name)
            _write_json(result_path, result)
            line = _terminal_line(probe["classification"], run_id, result_path,
                                  reason="baseline_probe")
            assert fits_stdout_budget(line + "\n", failed=True)
            if emit:
                print(line)
            return 1

    seed = seed_override if seed_override is not None else (
        requested_seed if requested_seed is not None else random.randint(0, 2**31 - 1)
    )
    metadata["seed"] = seed
    # An unattended check must fail through its captured exit status rather
    # than leave Godot's native crash UI open on the desktop.  The process log
    # remains the diagnostic artefact when an engine crash occurs.
    cmd = [godot_path, "--headless", "--disable-crash-handler"]
    if fixed_fps is not None:
        cmd += ["--fixed-fps", str(fixed_fps)]
    cmd += ["--path", str(ROOT), "--", "--scenario=%s" % scenario_path,
            "--run-id=%s" % run_id, "--random-seed=%d" % seed,
            "--headless-session-path=%s" % session_path]
    process_outcome: HeadlessRunOutcome | None = None
    returncode: int | None = None
    process_stdout = ""
    status = "passed"
    reason: dict[str, Any] | None = None
    started_at = time.monotonic()
    try:
        with _suppress_windows_crash_dialogs():
            process_outcome = run_headless_process(cmd, timeout)
            # A worktree cache left stale by a merge cannot resolve a new
            # script: refresh it from the primary and run once more.
            if process_outcome.kind not in ("timed_out", "environment_failure"):
                first_output = process_outcome.stdout + "\n" + process_outcome.stderr
                if failing_lines(first_output):
                    retry, line = godot_cache.refresh_after_failure(ROOT, godot_path, first_output)
                    if line:
                        print(line, file=sys.stderr)
                    if retry:
                        session_path.unlink(missing_ok=True)
                        process_outcome = run_headless_process(cmd, timeout)
        returncode = process_outcome.returncode
        process_stdout = process_outcome.stdout
        process_output = "--- stdout ---\n%s\n--- stderr ---\n%s" % (
            process_outcome.stdout, process_outcome.stderr
        )
        process_log.write_text(process_output, encoding="utf-8")
        if process_outcome.kind == "timed_out":
            status = "timed_out"
            reason = {"kind": "timeout", "timeout_seconds": timeout}
            if process_outcome.message:
                reason["cleanup"] = process_outcome.message
        elif process_outcome.kind == "environment_failure":
            status = "crashed"
            reason = {"kind": "environment", "message": process_outcome.message}
        else:
            compile_details = _compile_failure_details(process_log)
            if compile_details is not None:
                compile_error, compile_script = compile_details
                status = "compile_error"
                reason = {"kind": "compile", "message": compile_error}
                if compile_script is not None:
                    reason["script"] = compile_script
                _report_compile_failure(compile_error, compile_script, process_log)
    except OSError as error:
        status = "crashed"
        reason = {"kind": "crash", "message": str(error)}
        process_log.write_text(str(error) + "\n", encoding="utf-8")

    # Godot can exit cleanly after a script fails to compile and leave a
    # zero-filled session. That file is evidence, not scenario data.
    if status != "compile_error" and session_path.is_file():
        try:
            entries = load_entries(session_path)
        except (OSError, json.JSONDecodeError) as error:
            status = "crashed"
            reason = {"kind": "crash", "message": "invalid session JSONL: %s" % error}
    if status == "passed" and not session_path.is_file():
        status = "crashed"
        reason = {"kind": "missing_summary", "message": "Godot wrote no session file"}
    if status == "passed" and "MEADOW_RESULT_PATH=%s" % session_path not in process_stdout:
        status = "crashed"
        reason = {"kind": "crash", "message": "Godot did not confirm the requested session path"}
    analysis: dict[str, Any] | None = analyze(entries) if entries else None
    if status == "passed" and (analysis is None or analysis["summary"] is None):
        status = "crashed"
        reason = {"kind": "missing_summary", "message": "session has no final summary"}
    if status == "passed" and returncode != 0:
        status = "crashed"
        reason = {"kind": "crash", "exit_code": returncode}

    expectation_results = []
    if status == "passed" and analysis is not None:
        try:
            expectation_results = evaluate_expectations(analysis, expectations)
        except ContractError as error:
            status = "contract_error"
            reason = {"kind": "contract", "message": str(error)}
        action_problems = analysis["actions"]["problems"]
        if status == "passed" and action_problems:
            status = "failed"
            reason = {"kind": "action", "action": action_problems[0]}
        failed_expectations = [item for item in expectation_results if not item.passed]
        if status == "passed" and failed_expectations:
            item = failed_expectations[0]
            status = "failed"
            reason = {"kind": "expectation", "id": item.identifier,
                      "expected": item.expected, "actual": item.actual}

    summary = analysis["summary"] if analysis is not None else None
    actions = analysis["actions"] if analysis is not None else {"problems": []}
    action_counts = {"rejected": 0, "failed": 0, "unresolved": 0}
    for problem in actions.get("problems", []):
        problem_kind = {"assert_failed": "failed", "never_fired": "unresolved"}.get(
            problem["result"], problem["result"]
        )
        action_counts[problem_kind] = action_counts.get(problem_kind, 0) + 1
    classification = ("pass" if status == "passed" else
                      "timeout" if status == "timed_out" else
                      "compile_failure" if status == "compile_error" else
                      "environment_failure" if status == "crashed" else
                      "product_failure")
    result = {
        "schema_version": SCHEMA_VERSION, "status": status, "run_id": run_id,
        "classification": classification,
        "scenario": {"path": metadata["path"], "sha256": metadata["sha256"]},
        "seed": metadata["seed"], "diagnostics": {"profile": diagnostics["profile"], "version": diagnostics["version"]},
        "outcome": summary.get("outcome") if summary else None,
        "simulated": {"seconds": summary.get("game_time") if summary else None,
                      "day": summary.get("day") if summary else None},
        "actions": action_counts,
        "expectations": {"passed": [item.identifier for item in expectation_results if item.passed],
                         "failed": [item.identifier for item in expectation_results if not item.passed]},
        "process": {"exit_code": returncode,
                    "pid": process_outcome.pid if process_outcome else None,
                    "execution": process_outcome.kind if process_outcome else "environment_failure",
                    "wall_seconds": round(time.monotonic() - started_at, 6)}, "artefacts": artefacts,
    }
    if status != "passed":
        failure_path = _write_failure(run_dir, status=status, run_id=run_id,
                                      reason=reason or {"kind": "crash"}, entries=entries,
                                      artefacts=artefacts)
        result["artefacts"] = dict(artefacts, failure=failure_path.name)
    elif analysis is not None:
        _write_json(run_dir / "report.json", report(analysis, "brief"))
        result["artefacts"] = dict(artefacts, report="report.json")
    _write_json(result_path, result)
    # WD-1: the one record of how often headless runs fail and how long they
    # take. Written after the result file, never before it, and never from
    # the manifest runner, which calls this once per scenario already.
    write_event(
        "headless_run",
        fixture=Path(metadata["path"]).name,
        status=status,
        classification=classification,
        ms=int(result["process"]["wall_seconds"] * 1000),
        exit_code=returncode if returncode is not None else -1,
        ok=(status == "passed"),
    )
    line = _terminal_line(status, run_id, result_path, outcome=result["outcome"],
                          reason=reason.get("kind") if reason else None)
    assert fits_stdout_budget(line + "\n", failed=status != "passed")
    if emit:
        print(line)
    return 0 if status == "passed" else 1


def _experiment_terminal_line(status: str, name: str, result_path: Path, *, reason: str | None = None) -> str:
    fields = ["status=%s" % status, "experiment=%s" % name]
    if reason is not None:
        fields.append("reason=%s" % reason)
    fields.append("result=%s" % result_path)
    return " ".join(fields)


def run_experiment_manifest(manifest_path: Path, godot_path: str, timeout: int,
                            fixed_fps: int | None, result_root: Path) -> int:
    """Run every named case/seed quietly, then print one aggregate verdict."""
    result_root.mkdir(parents=True, exist_ok=True)
    experiment_id = uuid.uuid4().hex[:12]
    experiment_dir = result_root / ("experiment-%d-%s" % (int(time.time() * 1000), experiment_id))
    experiment_dir.mkdir(parents=True, exist_ok=False)
    result_path = experiment_dir / "result.json"
    manifest_sha = ""
    name = manifest_path.stem
    try:
        raw_manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
        manifest_sha = hashlib.sha256(manifest_path.read_bytes()).hexdigest()
        manifest = validate_manifest(raw_manifest)
        name = manifest.name
        base_path = Path(manifest.base_scenario)
        if not base_path.is_absolute():
            base_path = (manifest_path.parent / base_path).resolve()
            if not base_path.is_file():
                base_path = (ROOT / manifest.base_scenario).resolve()
        base = json.loads(base_path.read_text(encoding="utf-8"))
        if not isinstance(base, dict):
            raise ExperimentContractError("base scenario must be a JSON object")
        # Validate every merge before the first launch: a malformed base
        # config block is a manifest contract error, never a partial
        # experiment that has already spent a case/seed run.
        for overlay in manifest.cases.values():
            compose_case_scenario(base, overlay)
    except (OSError, json.JSONDecodeError, ExperimentContractError) as error:
        result = {"schema_version": SCHEMA_VERSION, "status": "contract_error", "experiment_id": experiment_id,
                  "name": name, "manifest": {"path": str(manifest_path), "sha256": manifest_sha},
                  "reason": {"kind": "contract", "message": str(error)}, "cases": {}, "expectations": []}
        _write_json(result_path, result)
        line = _experiment_terminal_line("contract_error", name, result_path, reason="contract")
        assert fits_stdout_budget(line + "\n", failed=True)
        print(line)
        return 1

    summaries: dict[str, list[dict[str, Any]]] = {case: [] for case in manifest.cases}
    case_runs: dict[str, list[dict[str, Any]]] = {case: [] for case in manifest.cases}
    run_failed = False
    for case_name, overlay in manifest.cases.items():
        scenario = compose_case_scenario(base, overlay)
        for seed in manifest.seeds:
            seed_dir = experiment_dir / "cases" / case_name / ("seed-%d" % seed)
            seed_dir.mkdir(parents=True, exist_ok=False)
            scenario_path = seed_dir / "scenario.json"
            scenario_path.write_text(json.dumps(scenario, indent=2, sort_keys=True) + "\n", encoding="utf-8")
            exit_code = run_verdict_scenario(scenario_path, godot_path, timeout, fixed_fps,
                                             seed_dir, seed_override=seed, emit=False)
            run_dirs = sorted(seed_dir.glob("run-*/result.json"))
            if len(run_dirs) != 1:
                raise RuntimeError("experiment run did not create exactly one result artefact")
            run_result_path = run_dirs[0]
            run_result = json.loads(run_result_path.read_text(encoding="utf-8"))
            case_runs[case_name].append({"seed": seed, "status": run_result["status"],
                                         "result": str(run_result_path.relative_to(experiment_dir))})
            if exit_code != 0:
                run_failed = True
                continue
            report_path = run_result_path.parent / "report.json"
            report_data = json.loads(report_path.read_text(encoding="utf-8"))
            summary = report_data.get("summary")
            if not isinstance(summary, dict):
                run_failed = True
                continue
            summaries[case_name].append(summary)

    aggregate: dict[str, Any] = {}
    expectation_results: list[dict[str, Any]] = []
    reason: dict[str, Any] | None = None
    status = "passed"
    try:
        if run_failed:
            status = "failed"
            reason = {"kind": "run", "message": "one or more case runs failed"}
        else:
            aggregate = aggregate_case_metrics(summaries, required_metrics(manifest))
            expectation_results = evaluate_aggregate_expectations(aggregate, manifest.expectations)
            failed = [item["id"] for item in expectation_results if not item["passed"]]
            if failed:
                status = "failed"
                reason = {"kind": "expectation", "id": failed[0]}
    except ExperimentContractError as error:
        status = "contract_error"
        reason = {"kind": "contract", "message": str(error)}

    report_data = {"mode": manifest.report["mode"], "metrics": manifest.report["metrics"],
                   "aggregate": aggregate}
    _write_json(experiment_dir / "report.json", report_data)
    result = {
        "schema_version": SCHEMA_VERSION, "status": status, "experiment_id": experiment_id, "name": manifest.name,
        "manifest": {"path": str(manifest_path), "sha256": manifest_sha}, "seeds": list(manifest.seeds),
        "cases": case_runs, "aggregate": aggregate, "expectations": expectation_results,
        "artefacts": {"report": "report.json"},
    }
    if reason is not None:
        result["reason"] = reason
    _write_json(result_path, result)
    line = _experiment_terminal_line(status, manifest.name, result_path,
                                     reason=reason.get("kind") if reason else None)
    assert fits_stdout_budget(line + "\n", failed=status != "passed")
    print(line)
    if manifest.report["mode"] == "table":
        print(json.dumps(aggregate, sort_keys=True, separators=(",", ":")))
    return 0 if status == "passed" else 1


def _warn_on_action_problems(analysis: dict) -> None:
    """Prints a short, hard-to-miss warning when a scenario's actions
    block (scenario_actions.gd) didn't go cleanly -- a rejected action, an
    action whose "when" never fired, or a failed "assert" ending the run.
    Printed even when --full is off, and run_scenario returns a failing exit
    status when any are present, since a strategy script silently not doing
    what it said is exactly the failure mode the action assertions exist to
    catch loudly (contract: docs/headless-run-contract.md).
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
                  profile: str, fixed_fps: int | None = None,
                  seeds: list[int] | None = None) -> int:
    if not scenario_path.is_file():
        print("error: scenario file not found: %s" % scenario_path, file=sys.stderr)
        return 1

    analyses = []
    had_action_problems = False
    run_count = len(seeds) if seeds is not None else repeat
    for i in range(run_count):
        if run_count > 1:
            print("--- run %d/%d ---" % (i + 1, run_count))
        seed_override = seeds[i] if seeds is not None else None
        session_file = run_once(scenario_path, godot_path, timeout, fixed_fps, seed_override)
        if session_file is None:
            return 1

        entries = load_entries(session_file)
        analysis = analyze(entries)
        if analysis["summary"] is None:
            print("error: %s has no summary line -- run may not have finished" % session_file,
                  file=sys.stderr)
            return 1

        print("session file: %s" % session_file)
        # A brief profile mid-repeat is redundant with the aggregate
        # printed at the end -- only print it per-run when repeat == 1,
        # or always for a profile a human/AI actually asked to see in
        # full each time.
        if profile != "brief" or run_count == 1:
            print(json.dumps(report(analysis, profile), indent=2))
        _warn_on_action_problems(analysis)
        had_action_problems = had_action_problems or bool(
            analysis.get("actions", {}).get("problems", []))
        analyses.append(analysis)

    if run_count > 1:
        print("--- aggregate over %d runs ---" % run_count)
        print(json.dumps(aggregate_runs(analyses), indent=2))

    return 1 if had_action_problems else 0


def _background_command(argv: list[str]) -> list[str]:
    """Re-run this exact request in a worker, minus job-only arguments."""
    command = [sys.executable, str(Path(__file__).resolve())]
    skip_value = False
    for argument in argv:
        if skip_value:
            skip_value = False
            continue
        if argument == "--background":
            continue
        if argument == "--job-root":
            skip_value = True
            continue
        if argument.startswith("--job-root="):
            continue
        command.append(argument)
    return command


def submit_background_job(argv: list[str], job_root: Path) -> int:
    """Submit the normal foreground command and print its compact job handle."""
    try:
        job_dir, status = submit_job(_background_command(argv), job_root)
    except JobError as error:
        print("error: %s" % error, file=sys.stderr)
        return 1
    print("status=%s job_id=%s status_file=%s" % (
        status["status"], status["job_id"], job_dir / "status.json",
    ))
    return 0 if status["status"] == "queued" else 1


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__,
                                      formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("scenario", type=Path, nargs="?", help="path to a scenario JSON file")
    parser.add_argument("--experiment", type=Path,
                        help="run an experiment manifest with matched seeds and one aggregate verdict")
    parser.add_argument("--route-help", action="store_true",
                        help="print the deterministic headless routing card and exit")
    parser.add_argument("--timeout", type=int, default=DEFAULT_TIMEOUT,
                         help="real-world seconds to wait before giving up, per run (default: %(default)s)")
    parser.add_argument("--godot-path", default=DEFAULT_GODOT_PATH,
                         help="path to the Godot executable (default: %(default)s)")
    parser.add_argument("--repeat", type=int, default=1,
                         help="run the scenario this many times and report a range, not a "
                              "single point (default: %(default)s)")
    parser.add_argument("--seeds", type=lambda value: [int(seed) for seed in value.split(",")],
                         help="comma-separated seeds for matched causal runs; overrides a "
                              "scenario's random_seed and cannot be combined with --repeat")
    parser.add_argument("--report", choices=sorted(set(REPORT_PROFILES) | {"verdict"}), default=None,
                         help="which report profile to print: verdict (one-line default), brief (summary + action "
                              "problems, the default -- meant for an AI caller), balance "
                              "(summary + population/deaths/honey-fill series), behaviour "
                              "(summary + mechanic-firing + actions), or full (everything) "
                              "(CHATGPT_INSIGHTS_PLAN.md's A5)")
    parser.add_argument("--result-root", type=Path, default=DEFAULT_RESULT_ROOT,
                        help="directory for isolated verdict artefacts (default: %(default)s)")
    parser.add_argument("--background", action="store_true",
                        help="submit this foreground run as one managed background job")
    parser.add_argument("--job-root", type=Path, default=DEFAULT_JOB_ROOT,
                        help="managed temporary root for --background job state (default: %(default)s)")
    parser.add_argument("--full", action="store_true",
                         help="shorthand for --report full")
    parser.add_argument("--fixed-fps", type=int, default=DEFAULT_FIXED_FPS,
                         help="advance the engine by a fixed 1/N seconds per frame instead of "
                              "measuring real wall-clock time (Godot's own --fixed-fps flag) -- "
                              "runs at full CPU speed and removes the timing jitter that made "
                              "same-seed reruns diverge (CHATGPT_INSIGHTS_PLAN.md's A2/A3). "
                              "Pass 0 to fall back to ordinary wall-clock timing "
                              "(default: %(default)s)")
    args = parser.parse_args()

    if args.route_help:
        print(ROUTING_CARD)
        return 0
    if args.scenario is None and args.experiment is None:
        parser.error("scenario or --experiment is required unless --route-help is used")
    if args.scenario is not None and args.experiment is not None:
        parser.error("scenario and --experiment cannot be combined")

    if args.repeat < 1:
        print("error: --repeat must be at least 1", file=sys.stderr)
        return 1
    if args.seeds is not None and args.repeat != 1:
        print("error: --seeds cannot be combined with --repeat", file=sys.stderr)
        return 1
    if args.background:
        if args.result_root != DEFAULT_RESULT_ROOT:
            print("error: --background owns its result root; do not combine it with --result-root", file=sys.stderr)
            return 1
        return submit_background_job(sys.argv[1:], args.job_root)

    # A worktree's missing or stale .godot would otherwise fail every run
    # below as a compile error or a fake collapse. Stderr keeps stdout's
    # one-line verdict contract.
    if Path(args.godot_path).is_file():
        cache_ok, cache_line = godot_cache.ensure_cache(ROOT, args.godot_path)
        print(cache_line, file=sys.stderr)
        if not cache_ok:
            return 1

    fixed_fps = args.fixed_fps if args.fixed_fps != 0 else None
    if args.experiment is not None:
        if args.repeat != 1 or args.seeds is not None or args.report is not None or args.full:
            print("error: --experiment controls seeds and report through its manifest", file=sys.stderr)
            return 1
        return run_experiment_manifest(args.experiment, args.godot_path, args.timeout,
                                       fixed_fps, args.result_root)
    profile = args.report or ("full" if args.full else ("brief" if args.repeat > 1 or args.seeds else "verdict"))
    if profile == "verdict":
        if args.repeat != 1 or args.seeds is not None:
            print("error: verdict accepts one run; use --report brief for repeats", file=sys.stderr)
            return 1
        return run_verdict_scenario(args.scenario, args.godot_path, args.timeout,
                                    fixed_fps, args.result_root)
    return run_scenario(args.scenario, args.godot_path, args.timeout, args.repeat, profile,
                         fixed_fps, args.seeds)


if __name__ == "__main__":
    sys.exit(main())
