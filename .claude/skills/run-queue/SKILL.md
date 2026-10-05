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
   refill it (below), then rerun `doctor`.
2. **Claim.** If the lane holds only the item you are about to claim, first
   run `python tools/refill_lane.py --top-up --lane Claude --dry-run`. If it
   would add nothing, refill the lane (below) or ask Dave before you claim:
   a slice built with nothing admissible behind it is stranded at `finish`'s
   refill gate (BS-12, 4 Oct 2026). Then run `start`. Keep its JSON, and note
   `advice.level`.
3. **Dispatch.** Spawn the worker in the foreground
   (`run_in_background: false`). Its `subagent_type` comes from the level:
   `slice-worker-low`, `-medium` or `-high`. If the level is `unstated`, use
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
   - For a `medium` or `high` slice, run the `code-review` skill on the
     branch (args `low <branch>` for medium, `medium <branch>` for high),
     going by the plan's level, not your own sense of the risk. It reads
     the diff itself, so don't also read it. A correctness finding inside
     the slice's files goes back to the worker (SendMessage) once; anything
     else goes in the trial note. Skip it for a `low` slice.
     **The review ends with a `ReportFindings` call. That is one step of
     this loop, not the end of your turn: in the same turn, carry straight
     on.** A run on 1 Oct ended its turn there and left L-16 reviewed but
     unfinished for six hours.
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
     rerun. The refill gate (backlog dry) means specifying the owning
     plan's next slice. That is planning work, so do it yourself in the
     slice worktree, as in steps 2-3 of the refill below, then rerun.
     The same stop also comes when a block the worker wrote has a
     `Proof:` that fails on master, or names a successor with no block:
     fix the block. While there, open any `queue-gated` fence whose gate
     a slice landed earlier in this run has now cleared (its gate line
     under `## Not in the queue, and why` goes too), so the lane does
     not run dry one slice later.
     The lifecycle lock held by another lane's `finish` (the cause names
     its PID): wait for it and rerun in one background call,
     `powershell.exe -NoProfile -Command "Wait-Process -Id <pid>"; (cd <ROOT>/.worktrees/<id> && powershell.exe -NoProfile -ExecutionPolicy Bypass -File tools/slice.ps1 finish)`.
     Anything else stops the run.
7. **Record.** Keep only the `Slice landed:` block and the worker's
   one-line summary. Drop everything else from your working notes.

An empty or short lane is not a reason to stop: refill it. Stop only when
the maximum is reached, a `start` refuses for any reason but an empty lane,
or a refill needs Dave (below).

## Refilling the lane

Do this when `doctor` finds the lane empty, or when `finish` lands it with
no admissible block left in the backlog. It is planning work, so do it at
high reasoning, and read only what specifying the slice needs. Don't read
plan history or `plans/archive/`.

1. **Find the owner.** In `plans/now/`, find a live plan whose Status is
   not terminal and whose `Next:` names work that hasn't been specified
   yet. Read its Status line and the section that `Next:` points to.
2. **Specify** its next slice, or two if they are plainly sequential. Read
   `plans/README.md` § "Writing or editing a plan" first. Each slice gets
   a fenced `queue` block in its plan section, which is what
   `.claude/rules/documentation.md` calls the backlog. It holds the
   `**[Claude] <id> -- <title>**` line and its `Plan:`/`Files:`/`Check:`/
   `Proof:`/`Next after:` lines. Never edit the Codex lane. Use only files
   the Codex lane doesn't own (`tools/slice.ps1 owner <path>` for each one). State a reasoning
   level and a deterministic `Check:` where one exists. Write a `Proof:`
   that holds on master today. Fence a slice that can't start yet as
   `queue-gated`, with its one line under `## Not in the queue, and why`.
3. **Queue it.** Inside a slice worktree at a `finish` stop, edit there
   (step 6 above). Otherwise -- including while the lane's one slice branch
   is open -- a docs-only refill goes on this coordinator session's own
   worktree branch, not a second lane branch: add its row to
   `plans/workstreams.md` (lane "Claude (docs only)") before editing, and
   remove the row once the merge is pushed. Run
   `python tools/refill_lane.py --top-up --lane Claude`, then
   `python tools/check_docs.py`. Commit, merge to master and push, then
   go back to Preflight.

Stop the run and ask Dave with AskUserQuestion (give the options and their
costs, and recommend one) only if either of these is true:
- No live plan in `plans/now/` has work left to specify. In that case,
  propose which `ROADMAP.md` or `DESIGN_BACKLOG.md` item should become a
  new plan. Read those two files with `git -C <ROOT> show master:ROADMAP.md`
  and `git -C <ROOT> show master:DESIGN_BACKLOG.md`: every file tool, and
  Bash on their paths, is denied.
- Specifying the slice would change an ownership boundary, save
  compatibility, a gameplay outcome, or more than one later slice, and
  the plan leaves that open (CLAUDE.md rule 5).

## Final report

For each slice: the CLAUDE.md end-of-slice block, plus the worker type used
and any reviews or retries. For each refill: the plan it came from, the
ids it added, and why that slice came next. Then a one-paragraph trial note covering what
the worker got wrong, where you had to step in, and any change the worker
brief or this skill needs. Fill in `Connectors: active now` from your own
tool list.
