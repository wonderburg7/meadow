"""Report what a window of Claude Code sessions on this project cost."""

import argparse
import json
import re
import statistics
import subprocess
import sys
import time
from collections import Counter
from datetime import datetime, timedelta, timezone
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from diagnostics import read_events


def _cutoff_iso(days: int) -> str:
    """The oldest `ts` an event may carry to be in the window.

    Event timestamps are "YYYY-MM-DDTHH:MM:SSZ", so comparing them as strings
    is the same as comparing the instants -- no parsing per event.
    """
    return (datetime.now(timezone.utc) - timedelta(days=days)).strftime("%Y-%m-%dT%H:%M:%SZ")

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
# The model each stated level asks for -- checked against Get-SliceAdvice in
# tools/slice.ps1 by tests/test_wc5_level_model_parity.py. A model outside
# its level's entry is drift in either direction; CLAUDE.md rule 4 treats
# both as mistakes. Matched by prefix,
# because a transcript records a dated id such as claude-sonnet-5-20260401.
LEVEL_MODELS = {
    "low": ("claude-sonnet-5", "claude-haiku-5-5"),
    "medium": ("claude-sonnet-5",),
    "high": ("claude-opus-5",),
}

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


def _transcript_files(days, home=None):
    """Top-level session transcripts of every worktree directory in the window.

    Since L-21 this is the scope of --days, --classify, --phases and
    --no-edit-reasons: desktop sessions write to
    C--Users-dl13860-Documents-Meadow-meadow--claude-worktrees-<name>, so the
    primary directory alone saw 1 session in 70. Returns (files, primary
    directory count, worktree directory count), the counts being the
    directories that contributed a file. Subagent transcripts live below
    <session>/subagents and are not top-level, so they are not counted here.
    """
    home = Path(home) if home else Path.home() / ".claude" / "projects"
    cutoff = time.time() - days * 86400
    files = []
    primary = worktree = 0
    if not home.exists():
        return files, primary, worktree
    for project_dir in sorted(home.glob(PROJECT_SLUG + "*")):
        found = [f for f in project_dir.glob("*.jsonl") if (_first_timestamp(f) or 0) >= cutoff]
        if not found:
            continue
        files.extend(found)
        if project_dir.name == PROJECT_SLUG:
            primary += 1
        else:
            worktree += 1
    return files, primary, worktree


def _is_coordinator(path):
    """A top-level transcript whose subagents/*.meta.json names a slice-worker-* agent."""
    for meta in (path.parent / path.stem / "subagents").glob("*.meta.json"):
        try:
            agent_type = json.loads(meta.read_text(encoding="utf-8")).get("agentType", "")
        except Exception:
            continue
        if str(agent_type).startswith("slice-worker-"):
            return True
    return False


def _is_finish_call(block):
    if block.get("name") not in ("Bash", "PowerShell"):
        return False
    command = str((block.get("input") or {}).get("command", ""))
    return "slice.ps1" in command and "finish" in command


def _is_worker_dispatch(block):
    if block.get("name") not in ("Agent", "Task"):
        return False
    return str((block.get("input") or {}).get("subagent_type", "")).startswith("slice-worker-")


def _coordinator_stats(path):
    """(first timestamp, per-request contexts, dispatches, housekeeping context) for one session.

    Context per request is counted once per assistant message id. The
    housekeeping stretch opens after a `slice.ps1 finish` call and closes at
    the next slice-worker dispatch; the request that issues either is not in it.
    """
    seen = set()
    contexts = []
    dispatches = housekeeping = 0
    first_ts = None
    is_open = False
    with path.open("r", encoding="utf-8") as fh:
        for line in fh:
            try:
                row = json.loads(line)
            except Exception:
                continue
            if first_ts is None and row.get("timestamp"):
                first_ts = row["timestamp"]
            if row.get("type") != "assistant":
                continue
            message = row.get("message", {})
            usage = message.get("usage")
            if not usage:
                continue
            msg_id = message.get("id")
            if msg_id:
                if msg_id in seen:
                    continue
                seen.add(msg_id)
            context = (
                usage.get("input_tokens", 0)
                + usage.get("cache_read_input_tokens", 0)
                + usage.get("cache_creation_input_tokens", 0)
            )
            contexts.append(context)
            blocks = [
                b for b in (message.get("content") or []) if isinstance(b, dict) and b.get("type") == "tool_use"
            ]
            dispatched = [b for b in blocks if _is_worker_dispatch(b)]
            if is_open and not dispatched:
                housekeeping += context
            if dispatched:
                dispatches += len(dispatched)
                is_open = False
            if any(_is_finish_call(b) for b in blocks):
                is_open = True
    return first_ts, contexts, dispatches, housekeeping


def run_coordinator(files):
    """One row per /run-queue coordinator session: what it spends and the housekeeping share."""
    rows = []
    for f in files:
        if not _is_coordinator(f):
            continue
        try:
            first_ts, contexts, dispatches, housekeeping = _coordinator_stats(f)
        except Exception:
            continue
        if contexts:
            rows.append((first_ts or "", contexts, dispatches, housekeeping))
    rows.sort(key=lambda r: r[0])
    if not rows:
        print("no coordinator sessions in the window")
        return
    print("first request        reqs   median     peak       total  disp  ctx/disp  housekeeping")
    shares, medians, totals, per_dispatch = [], [], [], []
    for first_ts, contexts, dispatches, housekeeping in rows:
        total = sum(contexts)
        median = int(statistics.median(contexts))
        per = total // dispatches if dispatches else 0
        share = 100.0 * housekeeping / total if total else 0.0
        print(
            f"{first_ts[:19]:20s}{len(contexts):>5d}{median:>9d}{max(contexts):>9d}{total:>12d}"
            f"{dispatches:>6d}{per:>10d}{share:>12.1f}%"
        )
        shares.append(share)
        medians.append(median)
        totals.append(total)
        if dispatches:
            per_dispatch.append(per)

    def med(values):
        return int(statistics.median(values)) if values else 0

    print(
        f"median of {len(rows)} sessions: median/request {med(medians)}, total {med(totals)}, "
        f"context/dispatch {med(per_dispatch)}, housekeeping {statistics.median(shares):.1f}%"
    )


def _subagent_models(session, slice_id, home=None):
    """Models of the session's subagent transcripts dispatched for `slice_id`.

    A subagent's first user message is the coordinator's dispatch prompt, which
    carries the claim JSON, so it is matched on `"id": "<slice id>"`.
    """
    home = Path(home) if home else Path.home() / ".claude" / "projects"
    pattern = re.compile(r'"id"\s*:\s*"' + re.escape(slice_id) + '"')
    models = Counter()
    if not home.exists():
        return models
    for project_dir in home.glob(PROJECT_SLUG + "*"):
        for f in (project_dir / session / "subagents").glob("agent-*.jsonl"):
            first_user = ""
            file_models = Counter()
            try:
                with f.open("r", encoding="utf-8") as fh:
                    for line in fh:
                        if not line.strip():
                            continue
                        try:
                            row = json.loads(line)
                        except Exception:
                            continue
                        if row.get("type") == "user" and not first_user:
                            first_user = _extract_text(row.get("message", {}).get("content"))
                        elif row.get("type") == "assistant":
                            model = row.get("message", {}).get("model")
                            if model:
                                file_models[model] += 1
            except Exception:
                continue
            if pattern.search(first_user):
                models.update(file_models)
    return models


def _session_totals(home=None):
    """session id -> (requests, context tokens, output tokens, models), across worktrees.

    `models` is a Counter of each assistant row's message.model, which is
    what --events joins against the slice's plan level (WD-3).

    A worktree session's transcript lands in its own ~/.claude/projects
    directory, keyed by the worktree path, so the join globs every directory
    whose name starts with this project's slug. Since L-21 the --days,
    --classify, --phases and --no-edit-reasons modes read the same scope
    through _transcript_files; figures published before then (L-9) were
    measured on the primary directory alone.
    """
    totals = {}
    home = Path(home) if home else Path.home() / ".claude" / "projects"
    if not home.exists():
        return totals
    for project_dir in home.glob(PROJECT_SLUG + "*"):
        for f in project_dir.glob("*.jsonl"):
            requests = context = output = 0
            models = Counter()
            try:
                with f.open("r", encoding="utf-8") as fh:
                    for line in fh:
                        if not line.strip():
                            continue
                        try:
                            row = json.loads(line)
                        except Exception:
                            continue
                        if row.get("type") != "assistant":
                            continue
                        model = row.get("message", {}).get("model")
                        if model:
                            models[model] += 1
                        usage = row.get("message", {}).get("usage")
                        if not usage:
                            continue
                        requests += 1
                        context += (
                            usage.get("input_tokens", 0)
                            + usage.get("cache_read_input_tokens", 0)
                            + usage.get("cache_creation_input_tokens", 0)
                        )
                        output += usage.get("output_tokens", 0)
            except Exception:
                continue
            if requests:
                totals[f.stem] = (requests, context, output, models)
    return totals


def run_events(days: int):
    """Print the diagnostic log's summary: what ran, what stopped, what it cost.

    Reads <git-common-dir>/meadow-diagnostics.jsonl -- see tools/diagnostics.py.
    Nothing here reads a transcript body, so it stays cheap to run often.
    """
    events = [e for e in read_events() if e.get("ts", "") >= _cutoff_iso(days)]
    if not events:
        print(f"no diagnostic events in the last {days} days")
        print("the log is written by tools/slice.ps1, tools/verify.ps1 and the")
        print("SessionStart/Stop hooks in .claude/settings.json")
        return

    kinds = Counter(e["kind"] for e in events)
    print(f"window                       last {days} days, {len(events)} events")
    print(f"by kind                      {', '.join(f'{k}={v}' for k, v in kinds.most_common())}")
    print()

    claimed = [e for e in events if e["kind"] == "slice_claimed"]
    finished = [e for e in events if e["kind"] == "slice_finished"]
    print(f"slices claimed / finished    {len(claimed)} / {len(finished)}")
    # Stops are not reported here. tools/slice.ps1 records them in its own
    # ledger and `--stops` tallies them by step; agent-lifecycle.md's L-12 is
    # gated on that output, so it stays the single answer to "what stopped".
    print("lifecycle stops              see: python tools/session_cost.py --stops")
    print()

    stages = [e for e in events if e["kind"] == "verify_stage"]
    if stages:
        failures = Counter(
            e.get("stage", "?") for e in stages if not e.get("ok") and not e.get("skipped")
        )
        skips = Counter(e.get("stage", "?") for e in stages if e.get("skipped"))
        runs = Counter(e.get("stage", "?") for e in stages)
        print(f"verify stages run            {len(stages)}")
        if failures:
            print(f"verify failures              {', '.join(f'{k}={v}' for k, v in failures.most_common())}")
        else:
            print("verify failures              none")
        if skips:
            print(f"verify skips                 {', '.join(f'{k}={v}' for k, v in skips.most_common())}")
        durations = {}
        for e in stages:
            if e.get("ms"):
                durations.setdefault(e.get("stage", "?"), []).append(e["ms"])
        for stage in sorted(durations, key=lambda s: -statistics.median(durations[s]))[:6]:
            median_s = statistics.median(durations[stage]) / 1000
            print(f"  {stage:32s}{runs[stage]:>4d} runs   median {median_s:6.1f}s")
        print()

    totals = _session_totals()
    by_branch = {}
    for e in events:
        if e["kind"] != "session_start":
            continue
        branch = e.get("branch") or "(unknown branch)"
        hit = totals.get(e.get("session", ""))
        if not hit:
            continue
        requests, context, output, _ = hit
        row = by_branch.setdefault(branch, [0, 0, 0, 0])
        row[0] += 1
        row[1] += requests
        row[2] += context
        row[3] += output

    claimed_branches = {e.get("branch"): e.get("id") for e in claimed}
    if by_branch:
        print("cost by branch (sessions / requests / context tokens / output tokens)")
        for branch, (sessions, requests, context, output) in sorted(
            by_branch.items(), key=lambda kv: -kv[1][2]
        )[:12]:
            label = claimed_branches.get(branch) or branch
            print(f"  {label:32s}{sessions:>4d}{requests:>8d}{context:>12d}{output:>10d}")
    else:
        print("cost by branch               no session joined a transcript yet")
        print("  (the SessionStart hook has to have run at least once)")

    _print_level_drift(claimed, events, totals)
    _print_bash_calls(events)


def _print_bash_calls(events):
    """WD-4: how many Bash tool calls ran, how many failed, and which commands
    fail most -- the retry cost --classify can only guess at."""
    calls = [e for e in events if e["kind"] == "tool_bash"]
    if not calls:
        return
    failed = [e for e in calls if not e.get("ok", True)]
    print()
    print(f"bash tool calls              {len(calls)} run, {len(failed)} failed")
    powershell = [e for e in calls if e.get("shell") == "powershell"]
    if powershell:
        ps_failed = sum(1 for e in powershell if not e.get("ok", True))
        print(f"  of which PowerShell tool   {len(powershell)} run, {ps_failed} failed")
    if failed:
        top = Counter(e.get("cmd") or "?" for e in failed).most_common(6)
        print(f"  failing commands           {', '.join(f'{c}={n}' for c, n in top)}")


PROJECT_SLUG = "C--Users-dl13860-Documents-Meadow-meadow"


def _level_allows(level: str, model: str) -> bool:
    return any(model.startswith(prefix) for prefix in LEVEL_MODELS[level])


def _print_level_drift(claimed, events, totals, home=None):
    """WD-3: each claimed slice's plan level against the models its sessions
    actually ran at. A slice with no stated level, no session join key, or no
    transcript is counted rather than guessed at."""

    drift = []
    not_assessable = 0
    historical = []
    keyed_dates = []
    for e in claimed:
        session = e.get("session", "")
        if session:
            keyed_dates.append(e.get("ts", ""))
        else:
            # Claims written before T-2 have no common key with the hook.
            # They remain visible as a finite, dated backlog instead of
            # looking like current sessions that failed to report a model.
            historical.append(e)
            not_assessable += 1
            continue
        level = e.get("level", "unstated")
        if level not in LEVEL_MODELS:
            not_assessable += 1
            continue
        models = _subagent_models(session, e.get("id", ""), home) if e.get("id") else Counter()
        if models:
            models = Counter({"worker:" + m: n for m, n in models.items()})
        else:
            hit = totals.get(session)
            if hit:
                models.update(hit[3])
        if not models:
            not_assessable += 1
            continue
        if any(not _level_allows(level, model.removeprefix("worker:")) for model in models):
            drift.append((e.get("id", "?"), level, models))

    print()
    if drift:
        print("level drift (slice, plan level, models actually used)")
        for slice_id, level, models in drift:
            used = ", ".join(f"{m}={n}" for m, n in models.most_common())
            print(f"  {slice_id:32s}{level:8s} {used}")
    else:
        print("level drift                  none")
    print(f"  not assessable: {not_assessable}")
    if historical:
        dated = [date for date in keyed_dates if date]
        cutoff = min(dated)[:10] if dated else "the session-join rollout"
        print(f"  not assessable: {len(historical)} (before {cutoff})")
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
    preflight_by_cause = Counter()
    step_total = 0
    preflight_total = 0
    by_command = Counter()
    total = 0
    # The ledger predates its explicit UTF-8 writer: Windows PowerShell 5.1
    # used its ANSI code page (CP1252 here) for older entries. Decode each
    # JSONL record independently so one legacy/corrupt byte cannot hide every
    # later stop.
    for raw_line in path.read_bytes().splitlines():
        try:
            line = raw_line.decode("utf-8")
        except UnicodeDecodeError:
            try:
                line = raw_line.decode("cp1252")
            except UnicodeDecodeError:
                continue
        line = line.strip()
        if not line:
            continue
        try:
            record = json.loads(line)
        except Exception:
            continue
        total += 1
        by_command[record.get("command") or "?"] += 1
        step = record.get("step")
        if step:
            step_total += 1
            by_step[step] += 1
        else:
            preflight_total += 1
            preflight_by_cause[record.get("cause") or "?"] += 1

    print(f"stops recorded               {total}")
    print(f"stops in steps               {step_total}")
    print(f"preflight refusals           {preflight_total}")
    print(f"by command                   " + ", ".join(f"{c}={n}" for c, n in by_command.most_common()))
    print("")
    print("preflight refusals by cause:")
    for cause, count in preflight_by_cause.most_common():
        print(f"{count:>5d}  {cause}")
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
    parser.add_argument(
        "--coordinator",
        action="store_true",
        help="one row per /run-queue coordinator session: context, dispatches, housekeeping share",
    )
    parser.add_argument(
        "--events",
        action="store_true",
        help="summarise the diagnostic event log: verify stages, sessions, cost by branch",
    )
    args = parser.parse_args()

    # The stop ledger is repository state, not session transcripts, so it is
    # readable even when no session directory exists.
    if args.stops:
        run_stops()
        return 0

    # --events reads the diagnostic event log, likewise not the transcripts.
    if args.events:
        run_events(args.days)
        return 0

    projects = Path.home() / ".claude" / "projects"
    if not projects.exists():
        print(f"session directory not found: {projects}")
        return 0

    files, primary_dirs, worktree_dirs = _transcript_files(args.days)
    print(f"transcripts  {len(files)} sessions ({primary_dirs} primary, {worktree_dirs} worktree directories)")

    if args.classify:
        run_classify(files)
        return 0

    if args.phases:
        run_phases(files)
        return 0

    if args.no_edit_reasons:
        run_no_edit_reasons(files)
        return 0

    if args.coordinator:
        run_coordinator(files)
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
