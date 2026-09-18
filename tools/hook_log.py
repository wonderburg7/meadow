"""Claude Code hook entry point: record that a session opened or closed.

Wired to SessionStart and Stop in .claude/settings.json. It is what gives
tools/session_cost.py a session-to-branch join, and so a per-slice cost --
a transcript records neither its branch nor the slice it was claimed for.
Also wired to PostToolUse and PostToolUseFailure for Bash (WD-4): every
shell call records its first word and whether it failed, which is the one
count of retried commands that costs no tokens to collect. PostToolUse runs
only after a tool call succeeds, so a failed command reaches this script
through PostToolUseFailure as `tool_bash_failed`; both write one `tool_bash`
event and differ only in `ok`.

Two hard rules, because this runs on every session:
  * print nothing. A hook's stdout is fed back into the model's context, so
    any output here would be charged to every session that ever starts.
  * exit 0 whatever happens. A hook that fails blocks the session.

Usage: python tools/hook_log.py <session_start|session_end|tool_bash|tool_bash_failed>
"""

from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from diagnostics import write_event  # noqa: E402


def _branch(cwd: str) -> str:
    """The branch the session is on -- the join key. Falls back to this
    process's own directory, for the same reason diagnostics.log_path does."""
    for candidate in (cwd, str(Path.cwd())):
        try:
            result = subprocess.run(
                ["git", "-C", candidate, "rev-parse", "--abbrev-ref", "HEAD"],
                capture_output=True,
                text=True,
                timeout=10,
            )
            if result.returncode == 0 and result.stdout.strip():
                return result.stdout.strip()
        except Exception:
            continue
    return ""


def main() -> int:
    kind = sys.argv[1] if len(sys.argv) > 1 else "session_start"
    if kind not in ("session_start", "session_end", "tool_bash", "tool_bash_failed"):
        return 0

    payload = {}
    try:
        raw = sys.stdin.read()
        if raw.strip():
            payload = json.loads(raw)
    except Exception:
        payload = {}

    cwd = payload.get("cwd") or str(Path.cwd())
    if kind in ("tool_bash", "tool_bash_failed"):
        # Only the command's first word: a full line can hold a path or a
        # commit message, and answers no question the first word does not.
        command = str((payload.get("tool_input", {}) or {}).get("command", ""))
        words = command.split()
        failed = kind == "tool_bash_failed" or bool(
            (payload.get("tool_response", {}) or {}).get("is_error", False)
        )
        write_event(
            "tool_bash",
            root=cwd,
            session=payload.get("session_id", ""),
            cmd=words[0] if words else "",
            ok=not failed,
        )
        return 0

    write_event(
        kind,
        root=cwd,
        session=payload.get("session_id", ""),
        branch=_branch(cwd),
        source=payload.get("source", ""),
    )
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except SystemExit:
        raise
    except Exception:
        raise SystemExit(0)
