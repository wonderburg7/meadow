"""Append-only diagnostic event log -- the Python half of tools/diagnostics.ps1.

Same file, same schema, same guarantee: one JSON object per line at
<git-common-dir>/meadow-diagnostics.jsonl, and writing an event never raises.
See tools/diagnostics.ps1 for why the file lives in the git common directory
and who reads it.
"""

from __future__ import annotations

import json
import os
import subprocess
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Iterator

MAX_BYTES = 1024 * 1024
_MAX_FIELD_CHARS = 300

# The whole event vocabulary. A reader that does not recognise a kind ignores
# it, so adding one here is safe; renaming one silently drops history.
KINDS = (
    "session_start",
    "session_end",
    "slice_claimed",
    "slice_finished",
    # Not "slice_stop": tools/slice.ps1 records stops in its own
    # meadow-slice-stops.jsonl ledger, read by session_cost.py --stops.
    "verify_stage",
    "headless_run",
    "env_capability",
    "tool_bash",
)


def log_path(root: str | Path | None = None) -> Path | None:
    """The shared log's path, or None when this is not a git working tree.

    `root` is tried first and the process's own directory second: a hook is
    handed a working directory by its host, and a form git cannot resolve
    would otherwise drop the event silently.
    """
    for candidate in ([root] if root else []) + [Path.cwd()]:
        try:
            candidate = Path(candidate)
            common = subprocess.run(
                ["git", "-C", str(candidate), "rev-parse", "--git-common-dir"],
                capture_output=True,
                text=True,
                timeout=10,
            )
            if common.returncode != 0:
                continue
            path = Path(common.stdout.strip())
            if not path.is_absolute():
                path = candidate / path
            return path / "meadow-diagnostics.jsonl"
        except Exception:
            continue
    return None


def write_event(kind: str, root: str | Path | None = None, **fields: Any) -> None:
    """Append one event. Swallows every error -- see the module docstring."""
    try:
        path = log_path(root)
        if path is None:
            return
        try:
            if path.exists() and path.stat().st_size > MAX_BYTES:
                os.replace(path, path.with_suffix(path.suffix + ".1"))
        except Exception:
            pass

        event: dict[str, Any] = {
            "ts": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
            "kind": kind,
        }
        for key in sorted(fields):
            value = fields[key]
            if value is None or value == "":
                continue
            if isinstance(value, str) and len(value) > _MAX_FIELD_CHARS:
                value = value[:_MAX_FIELD_CHARS]
            event[key] = value

        # A single short append in "a" mode is atomic enough on both platforms
        # for the rate this log is written at; the reader skips any line that
        # does not parse, so an interleave costs one event, never the file.
        with path.open("a", encoding="utf-8") as fh:
            fh.write(json.dumps(event, separators=(",", ":")) + "\n")
    except Exception:
        pass


def read_events(root: str | Path | None = None) -> Iterator[dict[str, Any]]:
    """Yield every parseable event, oldest first, across both generations."""
    path = log_path(root)
    if path is None:
        return
    for candidate in (path.with_suffix(path.suffix + ".1"), path):
        if not candidate.exists():
            continue
        try:
            with candidate.open("r", encoding="utf-8") as fh:
                for line in fh:
                    line = line.strip()
                    if not line:
                        continue
                    try:
                        row = json.loads(line)
                    except Exception:
                        continue
                    if isinstance(row, dict) and row.get("kind"):
                        yield row
        except Exception:
            continue
