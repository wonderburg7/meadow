---
name: run-queue
description: Coordinate several Claude-lane Meadow slices in a row. This session claims each slice, hands it to a slice-worker subagent at the plan's reasoning level, reviews the result and runs finish. Use when Dave asks to run, work through or coordinate the queue or several slices without his input.
argument-hint: "[max slices, default 3]"
---

# Run the Claude lane as a coordinator

You are the coordinator. You claim, dispatch, review, finish and report. A
`slice-worker-<level>` subagent does the implementing. Its routine is
`plans/reference/slice-worker.md`, which you don't need to read. Keep your
own context small: never read plan sections or code that a worker will read.

`$ARGUMENTS` is the maximum number of slices to land (default 3). It is the
whole instruction: the stop rules, refills and report below need no extra
prompt. Run the slices **one at a time**. The lane allows one open branch (`plans/workstreams.md`
§ Lanes), and Godot runs from two sessions at once kill each other.

`ROOT` is the primary checkout: `C:\Users\dl13860\Documents\Meadow\meadow`.
Run every lifecycle command in a subshell, so that no tool's shell is left
sitting in a `.worktrees/` directory:
`(cd <ROOT> && powershell.exe -NoProfile -ExecutionPolicy Bypass -File tools/slice.ps1 <cmd> -Lane Claude)`.

## Loop, once per slice

1. **Preflight.** Run `doctor`. If it reports that another worktree holds
   the lane, check `mcp__ccd_session_mgmt__list_sessions` for a running
   session on that branch. If one is running, stop the run and say which
   session holds the lane. Never `abort` a worktree you didn't open in this
   run. If none is running and `doctor` says the branch has commits ahead
   and a clean worktree, an earlier run stopped before `finish`: adopt it.
   Take its level from the plan section's reasoning line
   (`python tools/heading.py <plan> "<heading>" | grep -i reasoning`, not
   the whole section), go to 5 with that level, and count it toward the
   maximum. Any other held state stops the run. If the lane is empty,
   dispatch the steward with `JOB=refill` (below), plus `gates` and the
   ids landed so far if there are any, then rerun `doctor`.
2. **Claim.** Read `advice.dry_after` from `doctor`. When it is true, dispatch the
   steward with `JOB=gates refill` and the ids landed so far (below) or ask
   Dave *before* `start`, never after:
   a slice built with nothing admissible behind it is stranded at `finish`'s
   refill gate (BS-12, 4 Oct 2026). Then run
   `tools/slice.ps1 start -Lane Claude -Dispatched`. `-Dispatched` tells it a
   worker implements the slice, so it does not check this session's own
   model against the plan level. Keep its JSON, and note `advice.level`.
3. **Dispatch.** Spawn the worker in the foreground
   (`run_in_background: false`). Its `subagent_type` comes from the level:
   `slice-worker-low` (Haiku 5.5), `-medium` (Sonnet 5.5) or `-high`
   (Opus 5.5). If the level is `unstated`, use
   medium and say so in the report. The prompt is the `start` JSON
   verbatim, plus `ROOT=<ROOT>` and `WORKTREE=<ROOT>\.worktrees\<id>`.
   Nothing else: the worker's brief says what to do.
4. **Act on its result.**
   - `ready`: go to 5.
   - `blocked`: ask Dave with AskUserQuestion. Give the worker's question,
     options and costs, and recommend one. Send his answer to the same
     worker (SendMessage, keeping its context) and go back to 4.
   - `failed`: if the failure is inside the slice's own files, send it back
     to the worker once with the failing lines. A second failure, or a
     failure outside the slice, stops the run. Leave the branch in place
     and report it.
5. **Review.** Read `git -C <ROOT> diff --stat master...<branch>`.
   - Every changed file must be in `files`, or be the owning plan, a test,
     `checks/` or `FUNCTION_MAP.md`. Anything else goes back to the worker
     as a question.
   - Review every slice through a `slice-reviewer` subagent, in the
     foreground. Its prompt is `ROOT=<ROOT>`, `BRANCH=<branch>`,
     `LEVEL=<level>` and the `files` and `proof` from the `start` JSON.
     `LEVEL` is `low` for a low or medium slice and `medium` for a high
     one, going by the plan's level, not your own sense of the risk. Never
     run `code-review` in this session or read the diff for it: a review
     run here re-sent its reading on every later request, about a sixth of
     a run's context (8 Oct 2026). A low slice is reviewed too, because
     its worker is Haiku and a cheap tier is only cheap when checked.
     A correctness finding with `in_slice: true` goes back to the worker
     (SendMessage) once; anything else goes in the trial note. The
     reviewer's reply is one step of this loop, not the end of your turn:
     carry straight on (a run on 1 Oct stopped after a review and left
     L-16 unfinished for six hours).
   - If the stat looks wrong, read the full diff of the code files (not the
     docs) and check it against `proof`.
   - Spot-check one claim from the worker's `check_run` by rerunning that
     single command, but only when it is a scenario run or a single test.
     When the check is a whole test module, skip it: `finish` runs
     `verify.ps1`, which runs every module again.
6. **Finish.** Run `finish` from the slice worktree as a background Bash
   call: `(cd <ROOT>/.worktrees/<id> && powershell.exe -NoProfile -ExecutionPolicy Bypass -File tools/slice.ps1 finish)`.
   Never pipe it through `2>&1 |`. Wait for the notification. It has ended
   only when it prints `Slice landed:` or a `slice finish stopped` block.
   - Never run `verify.ps1` yourself, to diagnose a stop or otherwise:
     the stop block names the saved `meadow-slice-verify.log`, and
     `finish` reruns verify itself (20 coordinator runs, 28 Sep-5 Oct).
   - On a stop, read only the stop block. A verify failure inside the
     slice's files goes back to the worker once, then rerun `finish`. A
     stale branch: merge master into it, regenerate `FUNCTION_MAP.md`,
     rerun. The refill gate (backlog dry), or a block whose `Proof:`
     fails on master or names a successor with no block, is planning work:
     dispatch the steward with `JOB=finish-stop`, the stop block and the
     slice worktree, then rerun. Add `gates` with the ids landed so far, so
     the lane does not run dry one slice later.
     The lifecycle lock held by another lane's `finish` (the cause names
     its PID): wait for it and rerun in one background call,
     `powershell.exe -NoProfile -Command "Wait-Process -Id <pid>"; (cd <ROOT>/.worktrees/<id> && powershell.exe -NoProfile -ExecutionPolicy Bypass -File tools/slice.ps1 finish)`.
     Anything else stops the run.
7. **Record.** Keep only the `Slice landed:` block and the worker's
   one-line summary. Drop everything else from your working notes.
8. **Clear stale gates once per run, not once per slice.** Add the id to
   the run's list of landed ids. Dispatch the steward with `JOB=gates` and
   that whole list only once, after the run's last slice, or earlier only
   if the lane needs it now: `finish` left the lane short, or the next
   `doctor` says `advice.dry_after`. Then send `JOB=gates refill` together,
   and clear the list. `finish` never rewrites those lines (T2-4a, 7 Oct
   2026). Gates after every slice cost three master commits and a steward
   dispatch each time, while housekeeping was a median 28.5% of a
   coordinator's context (14 Oct 2026). A gate one slice cleared waits for
   the batch; a short lane is the one case that cannot wait.

An empty or short lane is not a reason to stop: refill it. Stop only when
the maximum is reached, a `start` refuses for any reason but an empty lane,
or the steward returns `blocked` (below).

## The queue steward

A `queue-steward` subagent (Opus 5.5, `plans/reference/queue-steward.md`)
does all plan and queue editing, so this session never reads a plan section.
Dispatch it in the foreground (`run_in_background: false`) with `ROOT=<ROOT>`,
`JOB=<gates | refill | finish-stop, one or more>`, and what the job needs:
the ids landed, the `finish` stop block and slice worktree, or this session's
worktree path. It returns one JSON line. Its docs-only edits on this
session's worktree branch register no ledger row (`plans/reference/closeout.md`,
"Branches follow the lanes").

- `done`: check it with `git -C <ROOT> show --stat <commit>` and rerun
  `python tools/check_docs.py`. Do not read the plan sections it touched.
  Then go back to Preflight.
- `blocked`: ask Dave with AskUserQuestion (its question, options and costs,
  recommending its pick), send his answer to the same steward with
  SendMessage, and go back to this step. It blocks only when no live plan in
  `plans/now/` has work left, or when specifying the slice would change an
  ownership boundary, save compatibility, a gameplay outcome, or more than
  one later slice (CLAUDE.md rule 5). Those are the only times a refill
  stops the run.

The stale-branch stop in step 6 (merge master, regenerate `FUNCTION_MAP.md`)
stays here: it is three commands and needs no plan reading.

## Final report

For each slice: the CLAUDE.md end-of-slice block, plus the worker type used
and any reviews or retries. For a low slice, say whether the Haiku worker
needed a retry or a review fix: that is the evidence for keeping it on
Haiku or moving it back to Sonnet. For each refill: the plan it came from (the steward's `note`), the
ids it added, and why that slice came next. Then a one-paragraph trial note covering what
the worker got wrong, where you had to step in, and any change the worker
brief or this skill needs. Fill in `Connectors: active now` from your own
tool list. Then run
`python tools/session_cost.py --coordinator --days 1` and paste the newest row
(this session's), so the trial note carries its own number.
