# Coordinator context -- keep the /run-queue session small

<!-- CONTEXT: plan | LAYER: immediate-task -->
Status: active | Owner: Dave / Claude | Next: CX-1 -- session_cost.py reports what each /run-queue coordinator spends, and where | Dependency: none; CX-2 follows CX-1, whose report is CX-2's before-and-after measure | Verified: 2026-10-08

## Objective

A `/run-queue` run costs most in its coordinator, not its workers. Every
request re-sends the coordinator's whole conversation, and that conversation
grows with each slice. This plan moves the coordinator's longest stretch of
self-contained work -- the queue housekeeping after each `finish` -- into a
fresh-context subagent, so that only its conclusion reaches the coordinator.
It is the second half of the 8 Oct 2026 model-routing change (Haiku 5.5 for
low workers; every slice reviewed by a `slice-reviewer` subagent), whose
measurements are below.

**Done when** CX-1 and CX-2 have shipped and the first `/run-queue` run of
two or more slices after CX-2 reports, through CX-1's tool, coordinator
context per worker dispatch below 2.0M tokens (baseline 3.1M, below).

## Current state

Measured 8 Oct 2026 over 14 days of transcripts in
`~/.claude/projects/*eadow*` (a scratch script, not yet a tool -- that is
CX-1). A coordinator session is a top-level transcript whose `subagents/`
folder holds a `slice-worker-*` dispatch.

- 13 coordinator sessions, 1,373 requests, 196M tokens of context in all,
  63 worker dispatches: **3.1M of coordinator context per dispatch**. The
  workers' own transcripts came to about 96M in the same window, so the
  coordinator costs two to three times what it delegates.
- Median context per coordinator request was 120K-190K by session; the
  largest run peaked at 330K. A session opens at about 63K.
- Split by the last tool call before each request: from a `finish` call to
  the next worker dispatch, 668 requests and about 47% of the context (the
  split counted any command containing "finish", so treat it as an upper
  bound); reviews about 16%; queue and plan edits about 15%. The
  post-`finish` stretch is mostly `grep`/`sed` reads of plans and
  `NEXTSTEPS.md`, `git` calls, gate clearing (run-queue step 8) and refills.
- Baseline from `python tools/session_cost.py --coordinator --days 14`
  (8 Oct 2026, CX-1): 13 sessions, 1,374 requests, 196M context, 54
  dispatches (the scratch script's 63 counted differently): about 3.6M per
  dispatch; median per request 124K; median housekeeping share 9.3% per
  session (0% to 55%), well under the scratch 47% upper bound, which counted
  any "finish" command.
- No single tool result is large (each adds about 1-2K); the cost is many
  small reads carried at a large context.
- Since 8 Oct 2026 the reviews run in a `slice-reviewer` subagent
  (`.claude/agents/slice-reviewer.md`), so the 16% has already moved out.
  The housekeeping has not: `.claude/skills/run-queue/SKILL.md` steps 1, 2,
  6 (the refill-gate stop) and 8, and its "Refilling the lane" section, all
  run in the coordinator.

## Open slices

| Slice | What it does | Files it owns | Startable | Level |
| --- | --- | --- | --- | --- |
| CX-1 | `session_cost.py --coordinator` reports each coordinator run's cost and its post-`finish` share | `tools/session_cost.py`, `tests/test_cx1_coordinator_cost.py`, `.claude/skills/run-queue/SKILL.md` | yes | medium |
| CX-2 | a `queue-steward` subagent does the post-`finish` housekeeping and every refill | `.claude/agents/queue-steward.md`, `plans/reference/queue-steward.md`, `.claude/skills/run-queue/SKILL.md`, `tests/test_cx2_queue_steward.py` | after CX-1 | medium |

**Dependencies.** CX-2 after CX-1: CX-1 records the baseline that CX-2's
"Done when" is measured against, and both edit the run-queue skill.
`tools/session_cost.py` is also named by WC-5 in
`plans/now/workflow-checks.md` (Codex lane, gated); `refill_lane.py` refuses
to queue both at once, so whichever is queued second waits.

**Reads.** A slice reads its own section below and the functions it names
(`python tools/func.py <file> <function>`), nothing else.

**Must not change.** The coordinator alone talks to Dave (AskUserQuestion)
and alone runs `start` and `finish`. `plans/reference/slice-worker.md` and
the Codex coordinator (`.agents/skills/`) are out of scope.

## CX-1 -- session_cost.py reports what each /run-queue coordinator spends, and where

<!-- LAYER: immediate-task -->

Level: medium (a transcript report with a test; the transcript format is
already handled by the functions it reuses).

**True now.** `session_cost.py` reports cost by phase, stop and branch, and
`_subagent_models` joins a worker dispatch to its transcript, but nothing
picks out coordinator sessions. The numbers under "Current state" came from
a throwaway script and cannot be rerun.

**True afterwards.** `python tools/session_cost.py --coordinator --days N`
prints one row per coordinator session (a top-level transcript whose
`subagents/*.meta.json` names a `slice-worker-*` agent type): its first
timestamp, requests, median and peak context per request, total context,
worker dispatches, context per dispatch, and the share of context in
requests made after a call to `slice.ps1 finish` and before the next
`slice-worker-*` dispatch (the housekeeping share). Context per request is
`input_tokens + cache_read_input_tokens + cache_creation_input_tokens` from
each assistant message's `usage`, counted once per message `id`. A `finish`
call is a Bash or PowerShell command containing both `slice.ps1` and
`finish`, so a `grep finish` is not one. A footer gives the medians across
sessions. It reuses `_transcript_files` for the window rather than
re-walking `~/.claude/projects`.

The run-queue skill's "Final report" gains one line: run
`python tools/session_cost.py --coordinator --days 1` and paste the row for
this session (the newest), so that every trial note carries its own number.

The test builds a temporary home with one coordinator transcript (two
dispatches, one `finish`, known `usage` values, one duplicated message id),
one ordinary session and one subagent transcript, and proves: only the
coordinator is reported; the totals, median and dispatch count match by
hand; the housekeeping share counts only the requests between the `finish`
and the next dispatch; a `grep finish` command does not open that stretch.

After it lands, record the 14-day baseline the tool prints in "Current
state" above, replacing the scratch-script figures if they differ.

**Must not change.** Every existing `session_cost.py` option's output.

```queue
**[Claude] CX-1 -- session_cost.py reports what each /run-queue coordinator spends, and where**
- Plan: `plans/now/coordinator-context.md` -- "CX-1 -- session_cost.py reports what each /run-queue coordinator spends, and where"
- Files: `tools/session_cost.py`, `tests/test_cx1_coordinator_cost.py`, `.claude/skills/run-queue/SKILL.md`
- Check: `python -m unittest tests.test_cx1_coordinator_cost` passes (only the coordinator is reported; totals, median and dispatches match by hand; the housekeeping share runs from a `slice.ps1 finish` call to the next dispatch and a `grep finish` does not open it); `python tools/session_cost.py --coordinator --days 14` prints the baseline, recorded in the plan; `tools/verify.ps1` is green
- Proof: `absent: tools/session_cost.py :: --coordinator`
- Next after: CX-2 -- a queue-steward subagent does the post-finish housekeeping and every refill
```

## CX-2 -- a queue-steward subagent does the post-finish housekeeping and every refill

<!-- LAYER: immediate-task -->

Level: medium (a subagent brief and a rewiring of one skill, with the
decisions below already taken).

**True now.** After each `finish`, and whenever `doctor` reports
`dry_after` or an empty lane, the coordinator itself reads plans, specifies
slices, edits `NEXTSTEPS.md` and plan tables, and commits, at 120K-190K of
context per request (run-queue steps 1, 2, 6 and 8 and "Refilling the
lane").

**True afterwards.** A `queue-steward` subagent does that work in a fresh
context and returns a few lines of JSON.

- `.claude/agents/queue-steward.md`: `model: claude-opus-5-5`,
  `effort: high` (refills are planning work, which the skill already runs
  at high), tools `Bash, Read, Write, Edit, Grep, Glob` -- no Agent, no
  AskUserQuestion. Its body is a pointer to its brief, as
  `slice-worker-*.md` is.
- `plans/reference/queue-steward.md` is the brief. It takes one `JOB`:
  - `gates` -- given the ids landed in this run, update every line under
    `## Not in the queue, and why` and every plan slice-table row that names
    one of them (today's step 8), and open any `queue-gated` fence whose
    gate has cleared.
  - `refill` -- today's "Refilling the lane" steps 1-3, moved into the brief
    verbatim rather than restated (`plans/README.md` rule 6), on the
    coordinator's worktree branch, ending with the commit, merge to master
    and push the skill already asks for.
  - `finish-stop` -- the refill-gate stop in step 6: given the stop block
    and the slice worktree, specify the owning plan's next slice or fix the
    block's `Proof:`/successor there, and commit on that branch without
    merging.
  One dispatch may name `gates` and `refill` together; that is the normal
  case after a `finish` that leaves the lane short.
- Its final message is only
  `{"status": "done", "added": [ids], "cleared": [ids], "commit": "<sha>", "note": "<one line>"}`
  or `{"status": "blocked", "question": "...", "options": [{"choice": "...", "cost": "..."}], "recommend": "..."}`.
  It returns `blocked` exactly where the skill today stops to ask Dave (no
  live plan with work left; a CLAUDE.md rule 5 question). It never asks
  Dave itself.
- `.claude/skills/run-queue/SKILL.md`: steps 1, 2, 6 (refill-gate stop
  only) and 8 dispatch the steward in the foreground instead of doing the
  work. On `blocked` the coordinator asks Dave with AskUserQuestion and
  sends the answer back with SendMessage, as it does for a worker. "Refilling
  the lane" shrinks to when to dispatch and the two stop conditions; its
  steps move to the brief. The coordinator never reads a plan section to
  check the steward's work: it reads `git -C <ROOT> show --stat <commit>`
  and reruns `python tools/check_docs.py`.
- `tests/test_cx2_queue_steward.py` proves the wiring: the agent file pins
  `claude-opus-5-5` and lists neither `Agent` nor `AskUserQuestion`; the
  brief names all three jobs and both JSON shapes; the skill names
  `queue-steward` and no longer contains the refill steps
  (`Read \`plans/README.md\` § "Writing or editing a plan" first`).

**Decided in this plan** (8 Oct 2026, so that the slice does not stop to
ask): the steward commits, merges and pushes a docs-only refill itself,
because the skill already has the coordinator do exactly that and `finish`
remains the only path for code; the stale-branch stop in step 6 (merge
master, regenerate `FUNCTION_MAP.md`) stays in the coordinator, since it is
three commands and needs no plan reading.

**Must not change.** When the coordinator stops and asks Dave; the queue
rules in `.claude/rules/documentation.md`; `tools/refill_lane.py` and
`tools/check_docs.py`.

**Measured afterwards.** The first `/run-queue` run of two or more slices
after CX-2 pastes its `--coordinator` row in its trial note. The plan is
done when context per dispatch is below 2.0M; if it is not, the trial note
says which stretch still dominates, and that becomes this plan's next
slice.

```queue
**[Claude] CX-2 -- a queue-steward subagent does the post-finish housekeeping and every refill**
- Plan: `plans/now/coordinator-context.md` -- "CX-2 -- a queue-steward subagent does the post-finish housekeeping and every refill"
- Files: `.claude/agents/queue-steward.md`, `plans/reference/queue-steward.md`, `.claude/skills/run-queue/SKILL.md`, `tests/test_cx2_queue_steward.py`
- Check: `python -m unittest tests.test_cx2_queue_steward` passes (the agent pins claude-opus-5-5 without Agent or AskUserQuestion; the brief names the gates, refill and finish-stop jobs and both JSON shapes; the skill dispatches queue-steward and no longer holds the refill steps); `python tools/check_docs.py` passes; `tools/verify.ps1` is green
- Proof: `absent: .claude/skills/run-queue/SKILL.md :: queue-steward`
- Next after: none -- plans/now/coordinator-context.md is complete
```
