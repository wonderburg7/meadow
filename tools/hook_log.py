"""Claude Code hook entry point: record that a session opened or closed.

Wired to SessionStart and Stop in .claude/settings.json. It is what gives
tools/session_cost.py a session-to-branch join, and so a per-slice cost --
a transcript records neither its branch nor the slice it was claimed for.

Two hard rules, because this runs on every session:
  * print nothing. A hook's stdout is fed back into the model's context, so
    any output here would be charged to every session that ever starts.
  * exit 0 whatever happens. A hook that fails blocks the session.

Usage: python tools/hook_log.py <session_start|session_end>
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
    if kind not in ("session_start", "session_end"):
        return 0

    payload = {}
    try:
        raw = sys.stdin.read()
        if raw.strip():
            payload = json.loads(raw)
    except Exception:
        payload = {}

    cwd = payload.get("cwd") or str(Path.cwd())
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
