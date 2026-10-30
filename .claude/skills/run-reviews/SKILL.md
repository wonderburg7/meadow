---
name: run-reviews
description: Run several of Dave's Meadow reviews in one session. This session picks the reviews that are due, hands each to a review-runner subagent at the review's reasoning level in its own worktree, merges each result, asks Dave the batch's decisions together, and reports. Use when Dave asks to run the reviews, run the due reviews, or run a batch of named reviews.
argument-hint: "[max reviews, default 3] [review keys ...]"
---

# Run a batch of reviews as a coordinator

You are the coordinator. You choose, dispatch, merge, ask and report. A
`review-runner-<level>` subagent does each review in its own context. Its
routine is `plans/reference/review-runner.md`, which you don't need to read.
Keep your own context small: never read a review file, a record, a plan or
code. You hold only `review_due.py`'s output and each runner's result block.
The coordinator decides little, so Sonnet or Opus at low effort is enough.

`$ARGUMENTS` is an optional maximum (default 3) and optional record keys.
Run the reviews **one at a time**: reviews edit shared plans, and Godot runs
from two sessions at once kill each other.

`ROOT` is the primary checkout: the parent of
`git rev-parse --path-format=absolute --git-common-dir`, the same from the
primary checkout and any worktree (PowerShell:
`Split-Path -Parent (git rev-parse --path-format=absolute --git-common-dir)`).
Work it out once, at the start of the run.
Run git and tool commands as `git -C <ROOT> ...` or in a subshell
`(cd <ROOT> && ...)`, so that no shell is left sitting in a worktree.

## 1. Preflight

- No Godot may be running from another session:
  `Get-Process -Name Godot* -ErrorAction SilentlyContinue` (PowerShell).
  If one is, check `mcp__ccd_session_mgmt__list_sessions` for a running
  `/run-queue` or check pass, and stop and tell Dave which.
- `git -C <ROOT> fetch`, then confirm `ROOT` is on `master` and
  `git -C <ROOT> merge --ff-only origin/master` succeeds. Otherwise stop.
- Run `(cd <ROOT> && python tools/review_due.py)`.

## 2. Choose the batch

- **Keys named:** run exactly those, up to the maximum.
- **Nothing named:** take reviews marked `moved`, most watched files changed
  first, oldest record breaking ties, from product, architecture, gameplay,
  performance, save, UI and verification. If the batch would hold two or
  more, the last place goes to `plan-review`, so it folds in their slices.
  Leave out `context-review` and `agent-workflow-review` (they run on their
  own schedule) and any review marked `first` unless Dave names them.
- Never batch the hands-on check processor (it needs computer use and Dave)
  or workflow stage 1 (Codex only). A named `agent-workflow-review` runs
  Claude-only; say so in the report.
- Order: `product-review` first, the others in ranked order, `plan-review`
  last. State the batch and the reason in one line, then go on.

## 3. Each review except plan-review, in order

1. Read its `SINCE` and level:
   `(cd <ROOT> && python tools/review_due.py <key>)` -- keep only the
   `prompt:` and `SINCE:` lines.
2. Create its worktree: `(cd <ROOT> && git worktree add
   .claude/worktrees/review-<key> -b claude/review-<key>-<YYYYMMDD> master)`.
   Not under `.worktrees/`: `check_docs.py` fails any worktree there that
   has no ledger row, and the runner runs `check_docs.py`.
3. Dispatch in the foreground (`run_in_background: false`),
   `subagent_type` `review-runner-high` or `review-runner-medium` from the
   level, with a prompt of these lines only: `KEY=<key>`, `ROOT=<ROOT>`,
   `WORKTREE=<ROOT>\.claude\worktrees\review-<key>`, `SINCE=<commit or first run>`,
   `PHASE=review`, and `HANDOFFS=` followed by any hand-off lines earlier
   runners aimed at this review. Keep the agent's id for step 5.
4. Act on its block:
   - `done`: merge (below) and remove the worktree.
   - `decisions`: merge what it committed, keep the worktree and the agent,
     and collect its D-questions under its key.
   - `failed`: leave the branch, note it, and go on to the next review. A
     second failure, or one in shared state (a check failing on master,
     Godot crashing), stops the batch.
   - Hand-off lines naming a review later in the batch go into that
     review's `HANDOFFS`.
5. **Merge:** `git -C <ROOT> merge --no-ff -m "Merge <branch>: <review
   name>, <date>" <branch>`, then `git -C <ROOT> push origin master`. On a
   conflict, `git -C <ROOT> merge --abort` and stop the batch. A review
   branch is merged within the sitting, so it takes no
   `plans/workstreams.md` row (`plans/reference/closeout.md`, "Branches
   follow the lanes"); `tools/slice.ps1 owner` still sees it while open.

## 4. Decisions, once for the batch

Ask Dave every collected D-question with AskUserQuestion, at most four per
call, the review key as each header, each option's cost as its
description, and the runner's recommendation first with "(Recommended)".
Then send each runner its answers with SendMessage (keeping its context):
`PHASE=decide` and one line per question, `D1: <letter or Dave's words>`.
Act on its block as in 3.4, and merge.

## 5. Plan review last

Run `plan-review`, if it is in the batch, as in section 3 with every
hand-off aimed at it. If it returns decisions, ask them at once as in
section 4, send them back, and merge.

## 6. Clean up and report

Remove each finished worktree and its merged branch from a subshell in
`ROOT`: `git worktree remove .claude/worktrees/review-<key>` and
`git branch -d <branch>`. Leave a failed one in place and name it.

Then report:

- one line per review: key, runner model, dispositions, slices added (id,
  plan, level), decisions asked and Dave's answers, record path; and any
  failure with its branch;
- hand-offs that went to the signals file rather than to a batch review;
- `(cd <ROOT> && python tools/review_due.py)` again, so the reviews just run
  show `quiet`;
- a one-paragraph trial note: where a runner went wrong, where you stepped
  in, any change the runner brief or this skill needs;
- the newest row of `python tools/session_cost.py --coordinator --days 1`.

If you name a next slice, add `CLAUDE.md`'s `Next model` and `Toggle` lines.
