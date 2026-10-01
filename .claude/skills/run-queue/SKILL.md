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

`$ARGUMENTS` is the maximum number of slices to land (default 3). Run the
slices **one at a time**. The lane allows one open branch (`plans/workstreams.md`
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
   run.
2. **Claim.** Run `start`. Keep its JSON, and note `advice.level`.
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
     branch (args `low <branch>` for medium, `medium <branch>` for high).
     It reads the diff itself, so don't also read it. A correctness finding
     inside the slice's files goes back to the worker (SendMessage) once;
     anything else goes in the trial note. Skip it for a `low` slice.
   - If the stat looks wrong, read the full diff of the code files (not the
     docs) and check it against `proof`.
   - Spot-check one claim from the worker's `check_run` by rerunning that
     single command.
6. **Finish.** Run `finish` from the slice worktree as a background Bash
   call: `(cd <ROOT>/.worktrees/<id> && powershell.exe -NoProfile -ExecutionPolicy Bypass -File tools/slice.ps1 finish)`.
   Never pipe it through `2>&1 |`. Wait for the notification. It has ended
   only when it prints `Slice landed:` or a `slice finish stopped` block.
   - On a stop, read only the stop block. A verify failure inside the
     slice's files goes back to the worker once, then rerun `finish`. A
     stale branch: merge master into it, regenerate `FUNCTION_MAP.md`,
     rerun. The refill gate (backlog dry) means specifying the owning
     plan's next slice. That is planning work, so do it yourself in the
     worktree, at high reasoning, then rerun. Anything else stops the run.
7. **Record.** Keep only the `Slice landed:` block and the worker's
   one-line summary. Drop everything else from your working notes.

Stop early if the lane is empty, a `start` refuses, or the maximum is
reached.

## Final report

For each slice: the CLAUDE.md end-of-slice block, plus the worker type used
and any reviews or retries. Then a one-paragraph trial note covering what
the worker got wrong, where you had to step in, and any change the worker
brief or this skill needs. Fill in `Connectors: active now` from your own
tool list.
