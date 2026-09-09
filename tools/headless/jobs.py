"""Bounded background execution for the headless runner.

Jobs run the existing foreground ``tools/run_scenario.py`` command in a small
worker process.  The worker owns only its job directory and lets the foreground
runner keep ownership of Godot, its timeout and its normal result artefacts.
There is deliberately no "kill arbitrary PID" command in this module.
"""

from __future__ import annotations

import argparse
import contextlib
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile
import time
import uuid
from dataclasses import dataclass
from pathlib import Path
from typing import Any


DEFAULT_JOB_ROOT = Path(tempfile.gettempdir()) / "meadow-headless-jobs"
MARKER_NAME = ".meadow-headless-job-root"
JOB_NAME = re.compile(r"^job-[0-9]+-[0-9a-f]{12}$")
TERMINAL_STATUSES = frozenset({"passed", "failed", "contract_error", "timed_out", "crashed", "stale"})
# On Windows, process identity queries start a short PowerShell child.  Under
# concurrent test or desktop load that can outlast the original two-second
# terminal serialisation window even though the worker is finishing normally.
# Fifteen seconds stays bounded while allowing several identity-query retries.
TERMINAL_WRITE_GRACE_SECONDS = 15


@dataclass(frozen=True)
class HeadlessRunOutcome:
    """The complete, bounded outcome of one foreground Godot invocation.

    ``kind`` deliberately separates a product exit from an environment
    failure: callers can trust that this wrapper either reaped the process
    tree or reported why it could not start it.
    """

    kind: str  # completed | timed_out | environment_failure
    pid: int | None
    returncode: int | None
    stdout: str
    stderr: str
    wall_seconds: float
    message: str | None = None


def _terminate_process_tree(process: subprocess.Popen[str]) -> None:
    """Synchronously stop the child and every process it launched."""
    if os.name == "nt":
        # /T includes child processes; /F makes a hung native Godot process
        # bounded even when it ignores its console control group.
        subprocess.run(["taskkill", "/PID", str(process.pid), "/T", "/F"],
                       stdin=subprocess.DEVNULL, stdout=subprocess.DEVNULL,
                       stderr=subprocess.DEVNULL, check=False, timeout=10)
        return
    try:
        os.killpg(process.pid, 9)
    except ProcessLookupError:
        pass


def run_headless_process(command: list[str], timeout: int) -> HeadlessRunOutcome:
    """Run one Godot command, returning a typed result within ``timeout``.

    A distinct process group/session lets timeout cleanup include helpers Godot
    may have started.  ``communicate`` after cleanup reaps the direct child so
    this function never reports while its Godot process remains behind.
    """
    started_at = time.monotonic()
    kwargs: dict[str, Any] = {
        "stdin": subprocess.DEVNULL, "stdout": subprocess.PIPE,
        "stderr": subprocess.PIPE, "text": True,
    }
    if os.name == "nt":
        kwargs["creationflags"] = (getattr(subprocess, "CREATE_NO_WINDOW", 0) |
                                    getattr(subprocess, "CREATE_NEW_PROCESS_GROUP", 0))
    else:
        kwargs["start_new_session"] = True
    try:
        process = subprocess.Popen(command, **kwargs)
    except OSError as error:
        return HeadlessRunOutcome("environment_failure", None, None, "", "",
                                  time.monotonic() - started_at, str(error))
    try:
        stdout, stderr = process.communicate(timeout=timeout)
        return HeadlessRunOutcome("completed", process.pid, process.returncode,
                                  stdout, stderr, time.monotonic() - started_at)
    except subprocess.TimeoutExpired as error:
        try:
            _terminate_process_tree(process)
        except (OSError, subprocess.TimeoutExpired) as cleanup_error:
            # The direct child is still reaped below; preserve cleanup trouble
            # as environment evidence without extending the caller's timeout.
            message = "timeout cleanup failed: %s" % cleanup_error
        else:
            message = None
        # Do not turn a failed tree-cleanup command into an unbounded second
        # wait.  Killing the direct child is the final fallback that lets us
        # reap it and return a classified failure on every path.
        if process.poll() is None:
            process.kill()
        try:
            stdout, stderr = process.communicate(timeout=5)
        except subprocess.TimeoutExpired as reap_error:
            stdout = reap_error.stdout.decode() if isinstance(reap_error.stdout, bytes) else (reap_error.stdout or "")
            stderr = reap_error.stderr.decode() if isinstance(reap_error.stderr, bytes) else (reap_error.stderr or "")
            message = (message + "; " if message else "") + "child did not reap within 5 seconds"
        if not stdout:
            stdout = error.stdout.decode() if isinstance(error.stdout, bytes) else (error.stdout or "")
        if not stderr:
            stderr = error.stderr.decode() if isinstance(error.stderr, bytes) else (error.stderr or "")
        return HeadlessRunOutcome("timed_out", process.pid, process.returncode,
                                  stdout, stderr, time.monotonic() - started_at, message)


class JobError(ValueError):
    """A requested background job cannot be safely created or inspected."""


def _is_within(path: Path, parent: Path) -> bool:
    try:
        path.relative_to(parent)
        return True
    except ValueError:
        return False


def validate_job_root(root: Path) -> Path:
    """Restrict managed jobs to a dedicated directory under the OS temp root."""
    resolved = root.resolve()
    temp_root = Path(tempfile.gettempdir()).resolve()
    if not _is_within(resolved, temp_root):
        raise JobError("job root must be inside the system temporary directory")
    if resolved == temp_root:
        raise JobError("job root must be a dedicated directory below the system temporary directory")
    return resolved


def ensure_job_root(root: Path) -> Path:
    root = validate_job_root(root)
    root.mkdir(parents=True, exist_ok=True)
    marker = root / MARKER_NAME
    if marker.exists() and marker.read_text(encoding="utf-8") != "meadow-headless-jobs-v1\n":
        raise JobError("job root marker does not belong to Meadow headless jobs")
    if not marker.exists():
        marker.write_text("meadow-headless-jobs-v1\n", encoding="utf-8")
    return root


def _validate_job_dir(job_dir: Path, root: Path) -> Path:
    root = ensure_job_root(root)
    resolved = job_dir.resolve()
    if resolved.parent != root or not JOB_NAME.fullmatch(resolved.name):
        raise JobError("job directory must be a direct managed child of the job root")
    return resolved


def _atomic_json(path: Path, data: dict[str, Any]) -> None:
    temporary = path.with_suffix(path.suffix + ".tmp")
    temporary.write_text(json.dumps(data, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    os.replace(temporary, path)


def _read_json(path: Path) -> dict[str, Any]:
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        raise JobError("invalid job metadata: %s" % error) from error
    if not isinstance(data, dict):
        raise JobError("job metadata must be a JSON object")
    return data


def _process_start_token(pid: int) -> str | None:
    """Return a platform process-start token for identity checks, if available."""
    if pid <= 0:
        return None
    if os.name == "nt":
        command = [
            "powershell", "-NoProfile", "-NonInteractive", "-Command",
            "(Get-Process -Id %d -ErrorAction Stop).StartTime.ToUniversalTime().Ticks" % pid,
        ]
        try:
            result = subprocess.run(command, capture_output=True, text=True, timeout=2, check=False)
        except (OSError, subprocess.TimeoutExpired):
            return None
        token = result.stdout.strip()
        return token if result.returncode == 0 and token.isdigit() else None
    try:
        # Field 22 (zero-based 21) of /proc/<pid>/stat is the kernel start tick.
        fields = (Path("/proc") / str(pid) / "stat").read_text(encoding="utf-8").split()
        return fields[21] if len(fields) > 21 else None
    except OSError:
        return None


def _pid_is_live(pid: int) -> bool:
    if pid <= 0:
        return False
    try:
        os.kill(pid, 0)
    except OSError:
        return False
    return True


def _write_status(job_dir: Path, status: dict[str, Any]) -> None:
    status["updated_at"] = time.time()
    _atomic_json(job_dir / "status.json", status)


def _job_line(status: dict[str, Any], job_dir: Path) -> str:
    return "status=%s job_id=%s status_file=%s" % (
        status["status"], status["job_id"], job_dir / "status.json",
    )


@contextlib.contextmanager
def _submission_lock(root: Path):
    """Serialize the short check-and-launch window for the one-job limit."""
    lock = root / ".submission.lock"
    try:
        descriptor = os.open(lock, os.O_CREAT | os.O_EXCL | os.O_WRONLY)
    except FileExistsError as error:
        raise JobError("another background job submission is already in progress") from error
    try:
        os.write(descriptor, str(os.getpid()).encode("ascii"))
        yield
    finally:
        os.close(descriptor)
        try:
            lock.unlink()
        except FileNotFoundError:
            pass


def _has_active_job(root: Path) -> bool:
    for candidate in root.iterdir():
        if candidate.is_dir() and JOB_NAME.fullmatch(candidate.name):
            status = refresh_status(candidate, root)
            if status.get("status") in {"queued", "running"}:
                return True
    return False


def submit_job(command: list[str], job_root: Path = DEFAULT_JOB_ROOT) -> tuple[Path, dict[str, Any]]:
    """Create one job and return immediately after starting its hidden worker."""
    if not command or any(not isinstance(part, str) or not part for part in command):
        raise JobError("background command must be a non-empty string argument list")
    if "--background" in command:
        raise JobError("background worker command must not recursively request --background")
    root = ensure_job_root(job_root)
    with _submission_lock(root):
        if _has_active_job(root):
            raise JobError("one background headless job is already active")
        return _submit_job_locked(command, root)


def _submit_job_locked(command: list[str], root: Path) -> tuple[Path, dict[str, Any]]:
    """Write and launch a job while the caller holds the submission lock."""
    job_id = uuid.uuid4().hex[:12]
    job_dir = root / ("job-%d-%s" % (int(time.time() * 1000), job_id))
    job_dir.mkdir()
    now = time.time()
    job = {"schema_version": 1, "job_id": job_id, "command": command, "submitted_at": now}
    status = {
        "schema_version": 1, "job_id": job_id, "status": "queued", "submitted_at": now,
        "worker": {"pid": None, "start_token": None}, "result": None,
    }
    _atomic_json(job_dir / "job.json", job)
    _write_status(job_dir, status)
    log = (job_dir / "process.log").open("w", encoding="utf-8")
    if os.name == "nt":
        # Keep the worker windowless and separate from an interactive console.
        # Its foreground child retains normal stdio redirection and timeout
        # behaviour through the existing runner.
        creationflags = (getattr(subprocess, "CREATE_NO_WINDOW", 0) |
                         getattr(subprocess, "CREATE_NEW_PROCESS_GROUP", 0))
    else:
        creationflags = 0
    worker_command = [sys.executable, str(Path(__file__).resolve()), "worker",
                      "--job-root", str(root), "--job-dir", str(job_dir)]
    try:
        worker = subprocess.Popen(worker_command, stdin=subprocess.DEVNULL, stdout=log,
                                  stderr=subprocess.STDOUT, creationflags=creationflags)
    except OSError as error:
        log.close()
        status.update({"status": "crashed", "reason": {"kind": "launch", "message": str(error)}})
        _write_status(job_dir, status)
        _atomic_json(job_dir / "result.json", {"schema_version": 1, "status": "crashed",
                                                  "job_id": job_id, "reason": status["reason"]})
        return job_dir, status
    finally:
        if not log.closed:
            log.close()
    _atomic_json(job_dir / "launcher.json", {
        "pid": worker.pid, "start_token": _process_start_token(worker.pid),
    })
    # This parent deliberately does not wait for the detached worker.  Marking
    # the local Popen object reaped prevents Python from issuing a misleading
    # ResourceWarning when it is collected; it does not change the child.
    worker.returncode = 0
    # The worker records its own PID/start token.  Leaving the initial state
    # alone avoids a fast worker completing and then being overwritten by a
    # stale parent-side ``queued`` write.
    return job_dir, status


def refresh_status(job_dir: Path, job_root: Path = DEFAULT_JOB_ROOT) -> dict[str, Any]:
    """Read state without tailing logs; identify a vanished/reused worker safely."""
    job_dir = _validate_job_dir(job_dir, job_root)
    status = _read_json(job_dir / "status.json")
    if status.get("status") not in {"queued", "running"}:
        return status
    # The worker writes its durable result before its final status update.  On
    # Windows, a monitor may be unable to query a just-exited worker owned by
    # another process, so prefer that durable terminal record to labelling a
    # completed job stale during this small write window.
    result_path = job_dir / "result.json"
    if result_path.is_file():
        result = _read_json(result_path)
        terminal_status = result.get("status")
        if terminal_status in TERMINAL_STATUSES:
            status.update({"status": terminal_status, "result": "result.json"})
            if isinstance(result.get("reason"), dict):
                status["reason"] = result["reason"]
            _write_status(job_dir, status)
            return status
    worker = status.get("worker") if isinstance(status.get("worker"), dict) else {}
    pid = worker.get("pid")
    expected = worker.get("start_token")
    if not isinstance(pid, int):
        # A just-submitted worker may not have reached its first metadata
        # write yet.  Do not call a normal launch race a stale job.
        launcher_path = job_dir / "launcher.json"
        if launcher_path.is_file():
            launcher = _read_json(launcher_path)
            launcher_pid = launcher.get("pid")
            launcher_token = launcher.get("start_token")
            if isinstance(launcher_pid, int) and _pid_is_live(launcher_pid):
                actual = _process_start_token(launcher_pid)
                if launcher_token is None or actual == launcher_token:
                    return status
        if (status.get("status") == "queued"
                and time.time() - status.get("submitted_at", 0) < TERMINAL_WRITE_GRACE_SECONDS):
            return status
        status.update({"status": "stale", "reason": {"kind": "worker_missing"}})
        _write_status(job_dir, status)
        return status
    if not _pid_is_live(pid):
        # The foreground child can finish just before the worker serialises
        # result.json/status.json.  Give that tiny terminal-write window time
        # to settle before classifying a genuinely vanished worker as stale.
        if (time.time() - status.get("updated_at", status.get("started_at", 0))
                < TERMINAL_WRITE_GRACE_SECONDS):
            return status
        status.update({"status": "stale", "reason": {"kind": "worker_missing"}})
        _write_status(job_dir, status)
        return status
    actual = _process_start_token(pid)
    if expected is not None and actual != expected:
        status.update({"status": "stale", "reason": {"kind": "worker_identity_mismatch"}})
        _write_status(job_dir, status)
    return status


def prune_terminal_jobs(job_root: Path = DEFAULT_JOB_ROOT, older_than_seconds: float = 0) -> int:
    """Remove only terminal direct-child job directories under a marked temp root."""
    if older_than_seconds < 0:
        raise JobError("older_than_seconds must be non-negative")
    root = ensure_job_root(job_root)
    cutoff = time.time() - older_than_seconds
    removed = 0
    for candidate in root.iterdir():
        if not candidate.is_dir() or not JOB_NAME.fullmatch(candidate.name):
            continue
        status = refresh_status(candidate, root)
        if status.get("status") not in TERMINAL_STATUSES:
            continue
        # A zero retention period means "prune every terminal job now".  Do
        # not race the terminal status write against a filesystem timestamp.
        if older_than_seconds > 0 and candidate.stat().st_mtime > cutoff:
            continue
        # _validate_job_dir above proves this is a direct child of our marked
        # temp root. No process is stopped as part of cleanup.
        shutil.rmtree(candidate)
        removed += 1
    return removed


def run_worker(job_dir: Path, job_root: Path = DEFAULT_JOB_ROOT) -> int:
    """Execute one persisted foreground command and write terminal job state."""
    job_dir = _validate_job_dir(job_dir, job_root)
    job = _read_json(job_dir / "job.json")
    command = job.get("command")
    if not isinstance(command, list) or not command or any(not isinstance(item, str) for item in command):
        raise JobError("job command is invalid")
    if "--background" in command or "--result-root" in command:
        raise JobError("job command is not a foreground runner command")
    status = _read_json(job_dir / "status.json")
    status.update({"status": "running", "started_at": time.time(),
                   "worker": {"pid": os.getpid(), "start_token": _process_start_token(os.getpid())}})
    _write_status(job_dir, status)

    command = list(command) + ["--result-root", str(job_dir / "runs")]
    returncode: int | None = None
    reason: dict[str, Any] | None = None
    try:
        with (job_dir / "process.log").open("a", encoding="utf-8") as log:
            log.write("worker command: %s\n" % " ".join(command))
            completed = subprocess.run(command, stdin=subprocess.DEVNULL, stdout=log, stderr=subprocess.STDOUT)
            returncode = completed.returncode
    except OSError as error:
        reason = {"kind": "launch", "message": str(error)}

    run_results = sorted((job_dir / "runs").glob("**/result.json"))
    run_result: dict[str, Any] | None = None
    run_result_path: Path | None = None
    if run_results:
        run_result_path = run_results[-1]
        try:
            run_result = _read_json(run_result_path)
        except JobError as error:
            reason = {"kind": "result", "message": str(error)}
    if run_result is not None and isinstance(run_result.get("status"), str):
        terminal_status = run_result["status"]
    elif reason is not None:
        terminal_status = "crashed"
    elif returncode == 0:
        terminal_status = "crashed"
        reason = {"kind": "missing_result", "message": "foreground runner returned no result.json"}
    else:
        terminal_status = "crashed"
        reason = {"kind": "runner_exit", "exit_code": returncode}
    result = {
        "schema_version": 1, "status": terminal_status, "job_id": job["job_id"],
        "process": {"exit_code": returncode},
        "verdict": run_result_path.relative_to(job_dir).as_posix() if run_result_path else None,
    }
    if reason is not None:
        result["reason"] = reason
    _atomic_json(job_dir / "result.json", result)
    status.update({"status": terminal_status, "finished_at": time.time(), "result": "result.json"})
    if reason is not None:
        status["reason"] = reason
    _write_status(job_dir, status)
    return 0 if terminal_status == "passed" else 1


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    subparsers = parser.add_subparsers(dest="operation", required=True)
    worker = subparsers.add_parser("worker", help=argparse.SUPPRESS)
    worker.add_argument("--job-root", type=Path, required=True)
    worker.add_argument("--job-dir", type=Path, required=True)
    status_parser = subparsers.add_parser("status", help="print one job status without reading logs")
    status_parser.add_argument("job_dir", type=Path)
    status_parser.add_argument("--job-root", type=Path, default=DEFAULT_JOB_ROOT)
    prune = subparsers.add_parser("prune", help="remove old terminal jobs from the marked temporary root")
    prune.add_argument("--job-root", type=Path, default=DEFAULT_JOB_ROOT)
    prune.add_argument("--older-than-seconds", type=float, default=0)
    args = parser.parse_args(argv)
    try:
        if args.operation == "worker":
            return run_worker(args.job_dir, args.job_root)
        if args.operation == "status":
            status = refresh_status(args.job_dir, args.job_root)
            print(_job_line(status, args.job_dir))
            return 0 if status["status"] == "passed" else 1 if status["status"] in TERMINAL_STATUSES else 0
        removed = prune_terminal_jobs(args.job_root, args.older_than_seconds)
        print("status=pruned removed=%d job_root=%s" % (removed, args.job_root))
        return 0
    except JobError as error:
        print("error: %s" % error, file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
