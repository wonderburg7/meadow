# Coordinator context -- keep the /run-queue session small

<!-- CONTEXT: plan | LAYER: immediate-task -->
Status: complete | Owner: Dave / Claude | Next: None -- plan complete (CX-1 and CX-2 shipped 8 Oct 2026) | Dependency: none | Verified: 2026-10-12

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

**Dependencies.** CX-2 after CX-1: CX-1 records the baseline that CX-2's
"Done when" is measured against, and both edit the run-queue skill.
`tools/session_cost.py` is also named by WC-5 in
`plans/archive/workflow-checks_2026-10-10.md` (Codex lane, gated); `refill_lane.py` refuses
to queue both at once, so whichever is queued second waits.

**Reads.** A slice reads its own section below and the functions it names
(`python tools/func.py <file> <function>`), nothing else.

**Must not change.** The coordinator alone talks to Dave (AskUserQuestion)
and alone runs `start` and `finish`. `plans/reference/slice-worker.md` and
the Codex coordinator (`.agents/skills/`) are out of scope.

CX-1 shipped 2026-10-08; its specification is `plans/archive/CX-1_2026-10-08.md`.

CX-2 shipped 2026-10-08; its specification is `plans/archive/CX-2_2026-10-08.md`.
