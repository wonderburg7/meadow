# Agent workflow review, stage 1: Codex sessions

<!-- CONTEXT: review-prompt | LOAD: only when running this review -->
Record key: none (stage 2 writes the `agent-workflow-review` record)
Reasoning: medium

Run this in Codex. It measures Codex's recent sessions and returns a compact
findings block, which Dave pastes into stage 2 (`agent-workflow-review.md`,
run in Claude Code). Change no files and write no record. Contract rules 1
and 3 apply; the rest are stage 2's.

**Period:** since the `Reviewed:` date of the latest agent workflow record
(`python tools/review_due.py agent-workflow-review`), unless the launcher sets
PERIOD.

## Steps

1. **Numbers before reading.** Codex rollouts are
   `~/.codex/sessions/YYYY/MM/DD/rollout-*.jsonl`. Rows with `type:
   event_msg` and `payload.type: item_completed` carry `item.command` and
   `item.aggregated_output`; `turn_context` rows give the sandbox policy.
   Parse the period with a short script, never by reading the files; keep
   it in your scratch directory so the next run can reuse it. Per task:
   slice id; whether it ran under the Codex `run-queue` skill (`.agents/skills/run-queue/SKILL.md`) as coordinator or
   worker; duration; turns; tool calls; calls and minutes before the first
   edit; the largest file reads, and whether `tools/heading.py` or
   `tools/func.py` could have served; verifier runs (focused, `prefinish`,
   full); failed calls by class (step 2); retries, waits, timeouts; sandbox
   or permission interruptions; whether it reached its outcome; reasoning
   level used against the slice's plan level.
2. **Classify every failed call** as: expected probe (a search with no
   match); agent mistake or malformed command; product or test failure;
   environment (Godot, dependencies, MCP); workflow or lifecycle
   (`tools/slice.ps1`, merge, worktree, queue); permissions or sandbox;
   network or external service; collision with concurrent work. Only the
   last five count as friction.
3. **Group symptoms under causes.** Repeat attempts at one slice, clean-up
   tasks, excess verification and stale branches often share one incomplete
   lifecycle mechanism. Rank causes by cost divided by likely effort to fix.
4. **Confirm only the top findings** in transcripts: at most five tasks,
   targeted excerpts.
5. **Check each finding against the current repository** before calling it
   active: the latest `docs/agent-workflow-review-*.md` and
   `plans/now/agent-lifecycle.md`. A fix that exists but is bypassed is a
   finding in its own right; say why it is bypassed.

## Output

Only one fenced block labelled `CODEX FINDINGS`, at most 60 lines:

- period, sample size, and a baseline table (median and 90th percentile for
  each step 1 metric);
- findings, each with: id; evidence (task ids and counts); recurrence; cost
  in time, tokens or Dave's attention; probable root cause; status of any
  earlier fix (effective, partial, regressed, bypassed, unverified, new);
  the smallest mechanism likely to prevent it; files likely involved;
- causes you suspect are shared with Claude, for stage 2 to verify;
- Codex-only configuration problems, and any action only Dave can take,
  with the exact file, place and text.

Do not recommend changes to Dave's ordinary "implement the next slice" prompt
unless the evidence shows the prompt itself causes the problem.
