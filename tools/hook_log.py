"""Claude Code hook entry point: record that a session opened or closed.

Wired to SessionStart and Stop in .claude/settings.json. It is what gives
tools/session_cost.py a session-to-branch join, and so a per-slice cost --
a transcript records neither its branch nor the slice it was claimed for.
Also wired to PostToolUse and PostToolUseFailure for Bash (WD-4) and, since
25 Sep 2026, PowerShell: every shell call records a short token for the
command that ran and whether it failed, which is the one count of retried
commands that costs no tokens to collect. PostToolUse runs
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
import re
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


def _bash_command_token(command: str) -> str:
    """Return the first program that can do work, without retaining input.

    A leading directory change and environment assignments describe setup,
    rather than the command whose retries the event log is meant to tally.
    This deliberately recognises only the shell separators Codex commonly
    emits; it is a compact classifier, not a shell parser.
    """
    for segment in re.split(r"&&|;|\|", command):
        words = segment.split()
        if not words or words[0] == "cd":
            continue

        index = 0
        while index < len(words) and re.match(r"^[A-Za-z_][A-Za-z0-9_]*=", words[index]):
            index += 1
        if index == len(words):
            continue

        # PowerShell's call operator introduces the program rather than being one.
        if words[index] == "&" and index + 1 < len(words):
            index += 1
        program = words[index].strip("'\"")
        # A script run directly (`.\tools\slice.ps1 owner`) is named by its
        # file, never by the path that reached it.
        if program.lower().endswith((".ps1", ".py")):
            return program.rsplit('/', 1)[-1].rsplit('\\', 1)[-1]
        if program in ("python", "python3", "powershell", "pwsh"):
            script_suffix = ".py" if program in ("python", "python3") else ".ps1"
            script = next(
                (word for word in words[index + 1:] if word.lower().endswith(script_suffix)),
                "",
            )
            if script:
                return f"{program} {script.rsplit('/', 1)[-1].rsplit('\\', 1)[-1]}"
        return program
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
        # Keep one short command token, never a command line: paths, arguments
        # and commit messages do not belong in the diagnostic event log.
        command = str((payload.get("tool_input", {}) or {}).get("command", ""))
        failed = kind == "tool_bash_failed" or bool(
            (payload.get("tool_response", {}) or {}).get("is_error", False)
        )
        write_event(
            "tool_bash",
            root=cwd,
            session=payload.get("session_id", ""),
            cmd=_bash_command_token(command),
            ok=not failed,
            # The kind stays `tool_bash` so history keeps one series; a
            # PowerShell tool call is marked, a Bash one carries no field.
            shell="powershell" if payload.get("tool_name") == "PowerShell" else "",
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
