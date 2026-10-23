"""Name a stop cause instead of rediagnosing it (L-35).

Two jobs, both driven by a table:

* `classify` sorts a saved verify log or a stop's stderr into one category
  (code, baseline, sandbox, approval-policy, credentials, import-cache, lock,
  cwd-holder), each with one remedy line. slice.ps1 prints both in its stop
  block. Adding a pattern is one row in CAUSES.
* `baseline` reads a unittest log and says whether every failing test is listed,
  unexpired, in tests/baseline_failures.json. verify.ps1 then leaves the stage
  green with a "baseline, not this branch" note. check_docs fails on an
  expired entry (`expired_entries`), so the quarantine cannot rot.

Usage:
    python tools/stop_causes.py classify <log-file | ->
    python tools/stop_causes.py baseline <log-file | ->   # exit 0: all baseline
"""
from __future__ import annotations

from datetime import date
from pathlib import Path
import json
import re
import sys

ROOT = Path(__file__).resolve().parent.parent
BASELINE_FILE = ROOT / "tests" / "baseline_failures.json"

# (category, regex, remedy). First match wins, so the specific rows come first;
# `baseline` and `code` are the fallbacks, not rows.
CAUSES: list[tuple[str, str, str]] = [
    ("import-cache", r"godot cache: FAILED|import cache|\.godot/imported|Could not load .*\.import",
     "change no code: run the Fix command the stop printed (tools/godot_cache.py), then retry"),
    ("sandbox", r"Receive-Job.*Access is denied|could not read this background job|Win32Exception|0xC0000142|New-TemporaryFile.*(?:not recognized|not found)|APPDATA.*(?:denied|sandbox)|sandbox_permissions",
     "change no code: rerun the same command outside the sandbox (Codex: sandbox_permissions require_escalated)"),
    ("approval-policy", r"auto-?approval|approval policy|requires approval|permission to run this command was denied|was denied by .*polic",
     "change no code: the command needs approving; ask for it in the session that needs it, once"),
    ("credentials", r"Authentication failed|could not read Username|Permission denied \(publickey\)|remote: Invalid username or password|HTTP 40[13]\b|fatal: unable to access .*(?:403|401)|! \[remote rejected\]|refusing to (?:update|allow)|push declined|protected branch hook declined",
     "change no code: the push or sign-in was refused; sign in again (git credential) and retry, or ask Dave to push"),
    ("cwd-holder", r"being used by another process.*(?:worktree|\.worktrees|\.claude)|Directory not empty|could not (?:remove|delete) .*worktree|cannot remove .*: Permission denied",
     "change no code: cd the shell out of the worktree (and stop its Godot) before finish; then rerun"),
    ("lock", r"lifecycle is busy|another finish is already verifying|index\.lock|Unable to create .*\.lock|waiting for another worktree|timed out waiting for .*lock|fixture lock",
     "change no code: another run holds the lock; wait for it (slice.ps1 status), do not start a second"),
]

REMEDY_BASELINE = "change no code: these tests fail on master too; they are listed in tests/baseline_failures.json -- do not fix them on this branch"
REMEDY_CODE = "a real failure on this branch: read the failing test's function, fix it, commit and retry"

_FAIL_LINE = re.compile(r"^(?:FAIL|ERROR): (\S+) \(([^)]+)\)", re.M)


def failing_tests(text: str) -> list[str]:
    """Test ids from unittest's FAIL:/ERROR: lines, as `module.Class.test`."""
    ids = []
    for method, cls in _FAIL_LINE.findall(text):
        ids.append(cls if cls.endswith(method) else f"{cls}.{method}")
    return ids


def load_baseline(path: Path | None = None) -> dict:
    try:
        data = json.loads((path or BASELINE_FILE).read_text(encoding="utf-8"))
    except (OSError, ValueError):
        return {"failures": []}
    return data if isinstance(data, dict) else {"failures": []}


def live_ids(baseline: dict | None = None, today: date | None = None) -> set[str]:
    today = today or date.today()
    baseline = load_baseline() if baseline is None else baseline
    out = set()
    for entry in baseline.get("failures", []):
        try:
            if date.fromisoformat(entry["expires"]) >= today:
                out.add(entry["test"])
        except (KeyError, ValueError):
            continue
    return out


def unlisted(failing: list[str], baseline: dict | None = None, today: date | None = None) -> list[str]:
    live = live_ids(baseline, today)
    return [t for t in failing if t not in live]


def classify(text: str, baseline: dict | None = None, today: date | None = None) -> tuple[str, str]:
    """(category, remedy) for a log. An environment cause beats baseline, which
    beats code: a sandbox denial hides every other failure behind it."""
    for category, pattern, remedy in CAUSES:
        if re.search(pattern, text, re.I):
            return category, remedy
    failing = failing_tests(text)
    if failing and not unlisted(failing, baseline, today):
        return "baseline", REMEDY_BASELINE
    return "code", REMEDY_CODE


def expired_entries(baseline: dict | None = None, today: date | None = None) -> list[str]:
    """Problems with the baseline file, for check_docs: expired or malformed."""
    today = today or date.today()
    baseline = load_baseline() if baseline is None else baseline
    problems = []
    for index, entry in enumerate(baseline.get("failures", []), 1):
        missing = [k for k in ("test", "disposition", "owner", "expires") if not entry.get(k)]
        if missing:
            problems.append(f"entry {index} is missing {', '.join(missing)}")
            continue
        try:
            expiry = date.fromisoformat(entry["expires"])
        except ValueError:
            problems.append(f"{entry['test']}: expires must be YYYY-MM-DD")
            continue
        if expiry < today:
            problems.append(f"{entry['test']}: expired {entry['expires']} (owner {entry['owner']}) -- fix the test or renew with a reason")
    return problems


def _read(arg: str) -> str:
    if arg == "-":
        return sys.stdin.read()
    return Path(arg).read_text(encoding="utf-8", errors="replace")


def main(argv: list[str]) -> int:
    if len(argv) != 3 or argv[1] not in ("classify", "baseline"):
        print(__doc__)
        return 2
    text = _read(argv[2])
    if argv[1] == "classify":
        category, remedy = classify(text)
        print(f"cause: {category}")
        print(f"remedy: {remedy}")
        return 0
    failing = failing_tests(text)
    if not failing or unlisted(failing):
        return 1
    print(f"baseline, not this branch: {', '.join(failing)}")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
