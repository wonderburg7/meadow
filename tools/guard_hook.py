"""PreToolUse policy for Meadow's small set of closeout-breaking commands.

The hook deliberately recognises only the established hazards.  It is not a
shell parser and does not police ordinary setup such as ``cd … &&``.
"""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

import hook_log  # noqa: E402


DENIED_READ_PATHS = (".godot", "_backups", "docs/archive", "plans/archive")
TREE_READERS = frozenset({
    "cat", "head", "tail", "sed", "grep", "rg", "select-string",
    "get-content", "type", "ls", "dir", "get-childitem",
})

# A filter that removes a denied path reads nothing from it: an inverted
# match on piped input, or an exclude/glob-negation argument.
STDIN_FILTERS = frozenset({"grep", "rg", "select-string"})
INVERT_FLAG = re.compile(r"(?<!\S)(?:-[a-z]*v[a-z]*|--invert-match|-notmatch)(?!\S)")
EXCLUSION_ARGUMENT = re.compile(
    r"""(?<!\S)(?:--exclude(?:-dir)?(?:=|\s+)|(?:-g|--glob)(?:=|\s+)['"]?!|['"]?:(?:!|\(exclude\)))\S*"""
)


def _is_worktree(cwd: str) -> bool:
    normalised_cwd = cwd.replace("\\", "/")
    return ".worktrees" in {part.lower() for part in Path(normalised_cwd).parts}


def _reads_tree(command: str) -> bool:
    """Recognise a direct file reader with a denied path as an argument."""
    for line in command.splitlines():
        pieces = re.split(r"(&&|\|\||[;|])", line)
        for index in range(0, len(pieces), 2):
            words = pieces[index].strip().split(None, 1)
            if not words or words[0].lower() not in TREE_READERS:
                continue
            reader = words[0].lower()
            arguments = words[1].lower().replace("\\", "/") if len(words) > 1 else ""
            piped = index > 0 and pieces[index - 1] == "|"
            if piped and reader in STDIN_FILTERS and INVERT_FLAG.search(arguments):
                continue
            arguments = EXCLUSION_ARGUMENT.sub(" ", arguments)
            if any(path in arguments for path in DENIED_READ_PATHS):
                return True
    return False


def _reason(command: str, cwd: str) -> str:
    """Return the refusal reason for one known unsafe command, or an empty string."""
    lowered = command.lower()
    normalised = lowered.replace("\\", "/")

    if re.search(r"\bstop-process\b[^\r\n]*(?:-name\s+(?:godot|python(?:3)?|pwsh)|-(?:id|processid)\s+)", lowered):
        return "Do not stop Godot or Python; use slice.ps1 stop-verify or slice.ps1 status."
    if re.search(r"\bslice\.ps1\b[^\r\n]*\bfinish\b[^\r\n]*2>&1\s*\|", lowered):
        return "Do not pipe slice.ps1 finish; run it directly so closeout can complete."
    if _is_worktree(cwd) and re.search(r"\bslice\.ps1\b[^\r\n]*\bfinish\b", lowered):
        return "Run slice.ps1 finish from the primary checkout, not this worktree."
    if _is_worktree(cwd) and "../../tools/" in normalised:
        return "Run tools/… from inside the worktree, not ../../tools/… ."
    if _reads_tree(command):
        return "Do not read this denied path."
    return ""


def _deny(reason: str) -> None:
    print(json.dumps({
        "hookSpecificOutput": {
            "hookEventName": "PreToolUse",
            "permissionDecision": "deny",
            "permissionDecisionReason": reason,
        }
    }))


def main() -> int:
    try:
        payload = json.load(sys.stdin)
    except (json.JSONDecodeError, TypeError):
        return 0

    command = str((payload.get("tool_input") or {}).get("command", ""))
    cwd = str(payload.get("cwd") or Path.cwd())
    reason = _reason(command, cwd)
    if not reason:
        return 0

    hook_log.write_event(
        "guard_refusal",
        root=cwd,
        session=payload.get("session_id", ""),
        reason=reason,
    )
    _deny(reason)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
