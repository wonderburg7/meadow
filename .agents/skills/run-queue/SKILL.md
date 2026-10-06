---
name: run-queue
description: Coordinate several Codex-lane Meadow slices in a row. This session claims each slice, hands it to a fresh-context worker subagent at the plan's reasoning level, has the diff reviewed, and runs finish. Use when Dave asks to run, work through or coordinate the queue or several slices without his input (for example "$run-queue 4").
---

# Run the Codex lane as a coordinator

You are the coordinator. You claim, dispatch, review, finish and report. A
worker subagent does the implementing; its routine is
`plans/reference/slice-worker.md`, which you don't need to read. Keep your
own context small: never read plan sections or code that a worker will read.
This skill replaces `CHATGPT.md` § "Session routing" for the run; its
"Risk-proportional closeout" still decides who closes each branch out.

The number Dave gives with the request is the maximum number of slices to
land (default 3). It is the whole instruction: the stop rules, refills and
report below need no extra prompt. Run the slices **one at a time**. The
lane allows one open branch (`plans/workstreams.md` § Lanes), and two Godot
runs at once kill each other. Don't end your turn between steps: end it
only to ask Dave a question or to give the final report.

`ROOT` is the primary checkout: `C:\Users\dl13860\Documents\Meadow\meadow`.
Run every lifecycle command with the shell's working directory set to
`ROOT` (or to the slice worktree for `finish`), never with a `cd` that
leaves a shell sitting in `.worktrees/`:
`powershell.exe -NoProfile -ExecutionPolicy Bypass -File tools/slice.ps1 <cmd> -Lane Codex`.

## Workers keep contained contexts

Every subagent you start (worker or reviewer) is started with
`spawn_agent` and **`fork_turns: "none"`**, plus the `reasoning_effort`
named below. This skill is the explicit instruction that permits the
override. A full-history fork (`fork_turns` omitted or `"all"`) copies your
whole conversation into the worker and ignores `reasoning_effort`: that
defeats the point, so never use one. Wait with `wait_agent` and long waits
(minutes), not busy polling. Send a follow-up to the same worker with
`followup_task`, so it keeps its own context. Never start a second worker
while one is active.

## Loop, once per slice

1. **Preflight.** Run `doctor`. If it reports that another worktree holds
   the lane, you can't see other sessions: ask Dave whether a session is
   still working on that branch. Never `abort` a worktree you didn't open
   in this run. If Dave says none is, and `doctor` says the branch has
   commits ahead and a clean worktree, an earlier run stopped before
   `finish`: adopt it. Take its level from the plan section's reasoning
   line (`python tools/heading.py <plan> "<heading>"` piped through
   `Select-String -Pattern reasoning`, not the whole section), go to 5 with
   that level, and count it toward the maximum. Any other held state stops
   the run. If the lane is empty, refill it (below), then rerun `doctor`.
2. **Claim.** Read `advice.dry_after` from `doctor`. When it is true, run
   "Refilling the lane" (below) or ask Dave *before* `start`, never after:
   a slice built with nothing admissible behind it is stranded at
   `finish`'s refill gate. Then run `start`. Keep its JSON, and note
   `advice.level`.
3. **Dispatch.** Start the worker (`fork_turns: "none"`,
   `reasoning_effort` = the level: `low`, `medium` or `high`; if the level
   is `unstated`, use `medium` and say so in the report). Its message is
   exactly this, with the `start` JSON pasted verbatim:

   ```
   You are a Meadow slice worker. The slice below is already claimed.
   Read plans/reference/slice-worker.md (its "Codex workers" note covers
   your tools) and follow it exactly. Skip CHATGPT.md, never run
   tools/slice.ps1, and end with only the JSON that file asks for.
   ROOT=C:\Users\dl13860\Documents\Meadow\meadow
   WORKTREE=C:\Users\dl13860\Documents\Meadow\meadow\.worktrees\<id>
   <start JSON>
   ```
4. **Act on its result.**
   - `ready`: go to 5.
   - `blocked`: ask Dave in the chat and end your turn. Give the worker's
     question, the options and their costs, and recommend one. When he
     answers, send it to the same worker with `followup_task` and go back
     to 4.
   - `failed`: if the failure is inside the slice's own files, send it back
     to the worker once with the failing lines. A second failure, or a
     failure outside the slice, stops the run. Leave the branch in place
     and report it.
5. **Review.** Read `git -C <ROOT> diff --stat master...<branch>`.
   - Every changed file must be in `files`, or be the owning plan, a test,
     `checks/` or `FUNCTION_MAP.md`. Anything else goes back to the worker
     as a question.
   - For a `medium` or `high` slice, start a reviewer subagent
     (`fork_turns: "none"`, `reasoning_effort` `low` for a medium slice,
     `medium` for a high one, going by the plan's level, not your own sense
     of the risk). Its message: "Review `git -C <ROOT> diff master...<branch>`
     for correctness bugs only, in these files: <files>. The intent is:
     <proof>. Read only the diff and the functions it touches. Return only
     a JSON list of findings, each `{file, line, bug, scenario}`, or `[]`."
     Don't read the diff yourself as well. A correctness finding inside the
     slice's files goes back to the worker (`followup_task`) once; anything
     else goes in the trial note. Skip this for a `low` slice.
   - If the stat looks wrong, read the full diff of the code files (not the
     docs) and check it against `proof`.
   - Spot-check one claim from the worker's `check_run` by rerunning that
     single command, but only when it is a scenario run or a single test.
     When it is a whole test module, skip it: `finish` runs `verify.ps1`.
   - **Classify the risk tier** (`CHATGPT.md` § "Risk-proportional
     closeout"; read that section once per run with
     `python tools/heading.py CHATGPT.md "Risk-proportional closeout"`)
     from the stat, the plan's level and the reviewer's findings, in one
     line. **High:** push the branch, post that section's hand-off block,
     and stop the run: the lane's one branch now waits for Claude.
6. **Finish** (low or medium tier). With the shell's working directory set
   to `<ROOT>\.worktrees\<id>`, run
   `powershell.exe -NoProfile -ExecutionPolicy Bypass -File tools/slice.ps1 finish`
   with a timeout of at least 20 minutes (`timeout_ms: 1200000`). Never
   redirect its stderr. It has ended only when it prints `Slice landed:` or
   a `slice finish stopped` block. A call that returns with neither is still
   running: don't rerun it; run `status -Lane Codex` and wait for the PID it
   names (`Wait-Process -Id <pid>`).
   - Never run `verify.ps1` yourself, to diagnose a stop or otherwise: the
     stop block names the saved `.git/meadow-slice-verify.log`, and
     `finish` reruns verify itself.
   - On a stop, read only the stop block. A verify failure inside the
     slice's files goes back to the worker once, then rerun `finish`. A
     stale branch: merge master into it, regenerate `FUNCTION_MAP.md`,
     rerun. The refill gate (backlog dry) means specifying the owning
     plan's next slice. That is planning work, so do it yourself in the
     slice worktree, as in steps 2-3 of the refill below, then rerun. The
     same stop also comes when a block the worker wrote has a `Proof:` that
     fails on master, or names a successor with no block: fix the block.
     While there, open any `queue-gated` fence whose gate a slice landed
     earlier in this run has now cleared (its gate line under
     `## Not in the queue, and why` goes too).
     The lifecycle lock held by the other lane's `finish` (the cause names
     its PID): `Wait-Process -Id <pid>`, then rerun `finish`.
     Anything else stops the run.
7. **Record.** Keep only the `Slice landed:` block and the worker's
   one-line summary. Drop everything else from your working notes.

An empty or short lane is not a reason to stop: refill it. Stop only when
the maximum is reached, a `start` refuses for any reason but an empty lane,
a slice is high risk, or a refill needs Dave (below).

## Refilling the lane

Do this when `doctor` finds the lane empty, or when `finish` lands it with
no admissible block left in the backlog. It is planning work, so do it
yourself at your own (high) reasoning, and read only what specifying the
slice needs. Don't read plan history or `plans/archive/`.

1. **Find the owner.** In `plans/now/`, find a live plan whose Status is
   not terminal and whose `Next:` names work that hasn't been specified
   yet. Read its Status line and the section that `Next:` points to.
2. **Specify** its next slice, or two if they are plainly sequential. Read
   `plans/README.md` § "Writing or editing a plan" first. Each slice gets
   a fenced `queue` block in its plan section (the backlog), holding the
   `**[Codex] <id> -- <title>**` line and its `Plan:`/`Files:`/`Check:`/
   `Proof:`/`Next after:` lines. Never edit the Claude lane. Use only files
   the Claude lane doesn't own (`tools/slice.ps1 owner <path>` for each
   one). State a reasoning level and a deterministic `Check:` where one
   exists. Write a `Proof:` that holds on master today. Fence a slice that
   can't start yet as `queue-gated`, with its one line under
   `## Not in the queue, and why`.
3. **Queue it.** Inside a slice worktree at a `finish` stop, edit there
   (step 6 above). Otherwise a docs-only refill goes on a `codex/` work
   branch of its own, never on master and never as a second lane slice
   branch: add its row to `plans/workstreams.md` (lane "Codex (docs
   only)") before editing, and remove the row once the merge is pushed.
   Run `python tools/refill_lane.py --top-up --lane Codex`, then
   `python tools/check_docs.py`. Commit, merge to master and push, then go
   back to Preflight.

Stop the run and ask Dave (give the options and their costs, and recommend
one) only if either of these is true:
- No live plan in `plans/now/` has work left to specify. In that case,
  propose which `ROADMAP.md` or `DESIGN_BACKLOG.md` item should become a
  new plan, reading them with `git -C <ROOT> show master:ROADMAP.md` and
  `git -C <ROOT> show master:DESIGN_BACKLOG.md`.
- Specifying the slice would change an ownership boundary, save
  compatibility, a gameplay outcome, or more than one later slice, and
  the plan leaves that open (CLAUDE.md rule 5).

## Final report

For each slice: the end-of-slice block from `CLAUDE.md` § "End-of-slice
report" (`finish` prints most of it; fill in `Connectors: active now` from
your own tool list), or the high-risk hand-off block, plus the worker's
reasoning level and any reviews or retries. For each refill: the plan it
came from, the ids it added, and why that slice came next. Then a
one-paragraph trial note covering what the worker got wrong, where you had
to step in, and any change the worker brief or this skill needs.
