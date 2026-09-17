"""Report what a window of Claude Code sessions on this project cost."""

import argparse
import json
import re
import statistics
import subprocess
import time
from collections import Counter
from datetime import datetime
from pathlib import Path

OUTCOME_CLASSES = (
    "expected_no_match",
    "partially_denied",
    "diagnostic_in_success",
    "test_failure",
    "environment_failure",
    "lifecycle_failure",
    "agent_mistake",
)

# A file edited under any of these directories is a "product edit" -- the
# boundary F13 (docs/agent-workflow-review-2026-09-12.md) uses to split a
# session into orienting, implementing and closeout phases.
PRODUCT_DIRS = ("scripts/", "scenes/", "shaders/", "tests/", "tools/", "test_scenarios/")

PHASE_NAMES = ("after_last", "implementing", "no_edit", "before_first")
PHASE_LABELS = {
    "after_last": "After the last product edit: verify, closeout, queue and docs",
    "implementing": "Implementing: first product edit to last",
    "no_edit": "Sessions that made no product edit at all",
    "before_first": "Before the first product edit: orient and claim",
}

# CLAUDE.md, memory and rules files are inlined into a session's opening
# turn as "Contents of <path> (...):\n<file text>" blocks (see the
# <system-reminder> wrapper this tool itself runs inside). A block whose
# path falls under the session's own repository/worktree root is
# "repository context"; everything else in the opening request -- system
# prompt, tool schemas, MCP/plugin/skill listings -- is "host context",
# recovered as the remainder rather than measured directly, since neither
# is logged on its own. Token counts are estimated at 4 characters per
# token, the standard rough ratio for English/code text; treat the split
# as an estimate, not an exact accounting.
_CONTENTS_MARKER = re.compile(r"Contents of (.+):\n")
_CHARS_PER_TOKEN = 4


def _row_texts(row):
    """Yield every plain-text string a row carries (message content, attachments)."""
    message = row.get("message")
    if isinstance(message, dict):
        content = message.get("content")
        if isinstance(content, str):
            yield content
        elif isinstance(content, list):
            for block in content:
                if isinstance(block, dict) and isinstance(block.get("text"), str):
                    yield block["text"]
    for block in row.get("rendered") or []:
        if isinstance(block, dict) and isinstance(block.get("content"), str):
            yield block["content"]


def _repo_context_chars(rows, repo_root):
    """Characters of "Contents of <path>" blocks under `repo_root`, before the
    first assistant reply -- see the module-level note on repository/host
    context above."""
    if not repo_root:
        return 0
    repo_root = repo_root.lower()
    total = 0
    for row in rows:
        if row.get("type") == "assistant" and row.get("message", {}).get("usage"):
            break
        for text in _row_texts(row):
            matches = list(_CONTENTS_MARKER.finditer(text))
            for i, m in enumerate(matches):
                path = re.sub(r"\s*\([^)]*\)\s*$", "", m.group(1)).strip()
                if not path.lower().startswith(repo_root):
                    continue
                start = m.end()
                end = matches[i + 1].start() if i + 1 < len(matches) else len(text)
                total += end - start
    return total


def _product_edit(block, repo_root):
    """True if an assistant content block is a file edit under a product dir."""
    if not isinstance(block, dict) or block.get("type") != "tool_use":
        return False
    if block.get("name") not in ("Edit", "Write", "NotebookEdit"):
        return False
    path = (block.get("input", {}) or {}).get("file_path") or (
        block.get("input", {}) or {}
    ).get("notebook_path")
    if not path:
        return False
    path = path.replace("\\", "/")
    if repo_root:
        repo_root_norm = repo_root.replace("\\", "/").rstrip("/") + "/"
        if path.lower().startswith(repo_root_norm.lower()):
            path = path[len(repo_root_norm):]
    return any(f"/{d}" in f"/{path}".lower() or path.lower().startswith(d) for d in PRODUCT_DIRS)


def _extract_text(content):
    """Flatten a tool_result's `content` (a string or a list of blocks) to text."""
    if isinstance(content, str):
        return content
    if isinstance(content, list):
        parts = []
        for block in content:
            if isinstance(block, dict) and isinstance(block.get("text"), str):
                parts.append(block["text"])
        return "\n".join(parts)
    return ""


def classify_outcome(command: str, result: str, is_error: bool) -> str:
    """Bucket one tool-call outcome into one of seven classes, first match wins.

    Distinguishes an expected non-zero exit or a diagnostic line inside a
    successful run from a real failure, so a measurement over raw exit codes
    does not overcount blockers that were never blockers -- see F12 in
    docs/agent-workflow-review-2026-09-12.md.
    """
    command = command or ""
    result = result or ""

    if is_error and (not result.strip() or ("ls-remote" in command and "--exit-code" in command)):
        return "expected_no_match"

    if re.search(r"Permission to use .* has been denied", result) and any(
        op in command for op in ("&&", "||", ";")
    ):
        return "partially_denied"

    if not is_error and "doc checks: FAILED" in result:
        return "diagnostic_in_success"

    if (
        is_error
        and re.search(r"AssertionError|\bFAILED\b|Traceback \(most recent call last\)", result)
        and "slice.ps1" not in command
        and "slice.ps1" not in result
    ):
        return "test_failure"

    if is_error and re.search(
        r"(godot|python|powershell)[^\n]{0,60}"
        r"(not found|not recognized|cannot be loaded|no such file)",
        result,
        re.IGNORECASE,
    ):
        return "environment_failure"

    if is_error and ("slice.ps1" in command or "slice.ps1" in result):
        return "lifecycle_failure"

    return "agent_mistake"


def _iter_tool_outcomes(files):
    """Yield (command, result, is_error) for every tool_use/tool_result pair."""
    for f in files:
        try:
            with f.open("r", encoding="utf-8") as fh:
                rows = [json.loads(line) for line in fh if line.strip()]
        except Exception:
            continue

        pending = {}
        for row in rows:
            if row.get("type") == "assistant":
                for block in row.get("message", {}).get("content", []) or []:
                    if isinstance(block, dict) and block.get("type") == "tool_use":
                        pending[block.get("id")] = block
            elif row.get("type") == "user":
                content = row.get("message", {}).get("content")
                if not isinstance(content, list):
                    continue
                for block in content:
                    if not isinstance(block, dict) or block.get("type") != "tool_result":
                        continue
                    tool_use = pending.pop(block.get("tool_use_id"), None)
                    command = ""
                    if tool_use:
                        command = (tool_use.get("input", {}) or {}).get("command", "") or ""
                    result = _extract_text(block.get("content"))
                    is_error = bool(block.get("is_error", False))
                    yield command, result, is_error


def _first_timestamp(path):
    """The session's own first-message time, not the file's mtime.

    A worktree checkout or backup pass can touch every .jsonl's mtime
    without changing what it records, which silently doubled the session
    count a file-mtime cutoff selected -- see L-2 in
    plans/now/agent-lifecycle.md.
    """
    try:
        with path.open("r", encoding="utf-8") as fh:
            for line in fh:
                line = line.strip()
                if not line:
                    continue
                ts = json.loads(line).get("timestamp")
                if ts:
                    return datetime.fromisoformat(ts.replace("Z", "+00:00")).timestamp()
    except Exception:
        return None
    return None


def run_classify(files):
    """Print the count of flagged tool outcomes in each of the seven classes."""
    counts = Counter()
    for command, result, is_error in _iter_tool_outcomes(files):
        if not is_error and "doc checks: FAILED" not in result:
            continue
        counts[classify_outcome(command, result, is_error)] += 1

    for name in OUTCOME_CLASSES:
        print(f"{name:22s}{counts.get(name, 0)}")


def run_phases(files):
    """Print the four-row phase table F13 reports (requests, context, share).

    A session's assistant requests, in order, are split around its first and
    last product edit -- see PRODUCT_DIRS. A session with no product edit is
    counted whole, in its own row, rather than split.
    """
    requests = Counter()
    context = Counter()

    for f in files:
        try:
            with f.open("r", encoding="utf-8") as fh:
                rows = [json.loads(line) for line in fh if line.strip()]
        except Exception:
            continue

        if len(rows) < 4:
            continue

        repo_root = next((r.get("cwd") for r in rows if r.get("cwd")), None)

        sizes = []
        edit_indices = []
        for row in rows:
            if row.get("type") != "assistant":
                continue
            message = row.get("message", {})
            usage = message.get("usage")
            if not usage:
                continue
            sizes.append(
                usage.get("input_tokens", 0)
                + usage.get("cache_read_input_tokens", 0)
                + usage.get("cache_creation_input_tokens", 0)
            )
            if any(_product_edit(b, repo_root) for b in message.get("content", []) or []):
                edit_indices.append(len(sizes) - 1)

        if not sizes:
            continue

        if not edit_indices:
            requests["no_edit"] += len(sizes)
            context["no_edit"] += sum(sizes)
            continue

        first_edit, last_edit = min(edit_indices), max(edit_indices)
        for i, size in enumerate(sizes):
            if i < first_edit:
                phase = "before_first"
            elif i <= last_edit:
                phase = "implementing"
            else:
                phase = "after_last"
            requests[phase] += 1
            context[phase] += size

    total_context = sum(context.values()) or 1
    for phase in PHASE_NAMES:
        share = 100 * context[phase] / total_context
        print(f"{PHASE_LABELS[phase]:58s}{requests[phase]:>7d}{context[phase]:>14d}{share:>7.1f}%")


NO_EDIT_LABELS = {
    "read_only": "Read-only: a question, review or investigation that wrote nothing",
    "docs_only": "Documentation, plan or queue edits only -- no product file",
    "other": "Edited something outside both the product dirs and Markdown",
}


def _edit_paths(rows, repo_root):
    """Every file path an Edit/Write/NotebookEdit touched, repository-relative."""
    paths = []
    for row in rows:
        if row.get("type") != "assistant":
            continue
        for block in row.get("message", {}).get("content", []) or []:
            if not isinstance(block, dict) or block.get("type") != "tool_use":
                continue
            if block.get("name") not in ("Edit", "Write", "NotebookEdit"):
                continue
            raw = (block.get("input", {}) or {}).get("file_path") or (
                block.get("input", {}) or {}
            ).get("notebook_path")
            if not raw:
                continue
            path = raw.replace("\\", "/")
            if repo_root:
                root = repo_root.replace("\\", "/").rstrip("/") + "/"
                if path.lower().startswith(root.lower()):
                    path = path[len(root):]
            paths.append(path)
    return paths


def run_no_edit_reasons(files):
    """Split the 'no product edit' sessions into why they made none.

    That row is a quarter of the project's context spend, and as one number it
    is unactionable: a planning session that legitimately wrote no code and a
    session that failed before it could both land in it. Costing them apart is
    what says whether the quarter is waste or work.
    """
    requests = Counter()
    context = Counter()
    sessions = Counter()

    for f in files:
        try:
            with f.open("r", encoding="utf-8") as fh:
                rows = [json.loads(line) for line in fh if line.strip()]
        except Exception:
            continue
        if len(rows) < 4:
            continue

        repo_root = next((r.get("cwd") for r in rows if r.get("cwd")), None)

        sizes = []
        made_product_edit = False
        for row in rows:
            if row.get("type") != "assistant":
                continue
            message = row.get("message", {})
            usage = message.get("usage")
            if not usage:
                continue
            sizes.append(
                usage.get("input_tokens", 0)
                + usage.get("cache_read_input_tokens", 0)
                + usage.get("cache_creation_input_tokens", 0)
            )
            if any(_product_edit(b, repo_root) for b in message.get("content", []) or []):
                made_product_edit = True

        if not sizes or made_product_edit:
            continue

        edits = _edit_paths(rows, repo_root)
        if not edits:
            reason = "read_only"
        elif all(path.lower().endswith(".md") for path in edits):
            reason = "docs_only"
        else:
            reason = "other"

        sessions[reason] += 1
        requests[reason] += len(sizes)
        context[reason] += sum(sizes)

    total_context = sum(context.values()) or 1
    print(f"{'':68s}{'sessions':>9s}{'requests':>10s}{'context':>14s}{'share':>8s}")
    for reason in ("read_only", "docs_only", "other"):
        share = 100 * context[reason] / total_context
        print(
            f"{NO_EDIT_LABELS[reason]:68s}{sessions[reason]:>9d}"
            f"{requests[reason]:>10d}{context[reason]:>14d}{share:>7.1f}%"
        )


def _stops_ledger_path():
    """tools/slice.ps1 writes its stop ledger into the git common directory,
    beside the closeout journal and the pending-deletions queue -- outside any
    worktree, so every lane appends to the same file."""
    try:
        out = subprocess.run(
            ["git", "rev-parse", "--git-common-dir"],
            cwd=Path(__file__).resolve().parent.parent,
            capture_output=True,
            text=True,
        )
    except OSError:
        return None
    if out.returncode != 0 or not out.stdout.strip():
        return None
    common = Path(out.stdout.strip())
    if not common.is_absolute():
        common = Path(__file__).resolve().parent.parent / common
    return common / "meadow-slice-stops.jsonl"


def run_stops():
    """Tally tools/slice.ps1's recorded stops by the step that raised them.

    `--classify` counts lifecycle_failure outcomes but cannot say which phase
    produced them, so the fix was always chosen by anecdote. This names the
    step, which is what decides whether automating a gate is worth it.
    """
    path = _stops_ledger_path()
    if path is None or not path.exists():
        print("no stop ledger yet -- tools/slice.ps1 writes one the next time a command stops")
        return

    by_step = Counter()
    by_command = Counter()
    total = 0
    for line in path.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if not line:
            continue
        try:
            record = json.loads(line)
        except Exception:
            continue
        total += 1
        by_command[record.get("command") or "?"] += 1
        by_step[record.get("step") or "(no step recorded)"] += 1

    print(f"stops recorded               {total}")
    print(f"by command                   " + ", ".join(f"{c}={n}" for c, n in by_command.most_common()))
    print("")
    print("most expensive steps (each stop is a read, a fix and a retry):")
    for step, count in by_step.most_common(10):
        print(f"{count:>5d}  {step}")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--days", type=int, default=7)
    parser.add_argument("--classify", action="store_true")
    parser.add_argument("--phases", action="store_true")
    parser.add_argument("--no-edit-reasons", action="store_true")
    parser.add_argument("--stops", action="store_true")
    args = parser.parse_args()

    # The stop ledger is repository state, not session transcripts, so it is
    # readable even when no session directory exists.
    if args.stops:
        run_stops()
        return 0

    project_dir = Path.home() / ".claude" / "projects" / "C--Users-dl13860-Documents-Meadow-meadow"
    if not project_dir.exists():
        print(f"session directory not found: {project_dir}")
        return 0

    cutoff = time.time() - args.days * 86400
    files = [f for f in project_dir.glob("*.jsonl") if (_first_timestamp(f) or 0) >= cutoff]

    if args.classify:
        run_classify(files)
        return 0

    if args.phases:
        run_phases(files)
        return 0

    if args.no_edit_reasons:
        run_no_edit_reasons(files)
        return 0

    session_count = 0
    assistant_requests = 0
    context_sizes = []
    output_tokens_sum = 0
    session_opening_contexts = []
    session_repo_contexts = []
    session_host_contexts = []
    tool_counts = Counter()

    for f in files:
        rows = []
        try:
            with f.open("r", encoding="utf-8") as fh:
                for line in fh:
                    try:
                        rows.append(json.loads(line))
                    except Exception:
                        continue
        except Exception:
            continue

        if len(rows) < 4:
            continue

        session_count += 1
        first_context = None
        repo_root = next((r.get("cwd") for r in rows if r.get("cwd")), None)

        for row in rows:
            if row.get("type") != "assistant":
                continue
            message = row.get("message", {})
            usage = message.get("usage")
            if not usage:
                continue

            assistant_requests += 1
            context_size = (
                usage.get("input_tokens", 0)
                + usage.get("cache_read_input_tokens", 0)
                + usage.get("cache_creation_input_tokens", 0)
            )
            context_sizes.append(context_size)
            output_tokens_sum += usage.get("output_tokens", 0)
            if first_context is None:
                first_context = context_size

            for block in message.get("content", []) or []:
                if isinstance(block, dict) and block.get("type") == "tool_use":
                    tool_counts[block.get("name", "?")] += 1

        if first_context is not None:
            session_opening_contexts.append(first_context)
            repo_chars = _repo_context_chars(rows, repo_root)
            repo_tokens = min(first_context, repo_chars // _CHARS_PER_TOKEN)
            session_repo_contexts.append(repo_tokens)
            session_host_contexts.append(first_context - repo_tokens)

    def median(values):
        return statistics.median(values) if values else 0

    def p90(values):
        if not values:
            return 0
        s = sorted(values)
        return s[int(len(s) * 0.9)]

    top_tools = ", ".join(f"{name}={count}" for name, count in tool_counts.most_common(6))

    print(f"sessions                     {session_count}")
    print(f"assistant requests           {assistant_requests}")
    print(f"context volume (tokens)      {sum(context_sizes)}")
    print(f"output tokens                {output_tokens_sum}")
    print(f"context/request median       {median(context_sizes)}")
    print(f"context/request p90          {p90(context_sizes)}")
    print(f"session-opening context      {median(session_opening_contexts)}")
    print(f"session-opening repository   {median(session_repo_contexts)}")
    print(f"session-opening host context {median(session_host_contexts)}")
    print(f"tool calls                   {sum(tool_counts.values())}")
    print(f"top tools                    {top_tools}")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
