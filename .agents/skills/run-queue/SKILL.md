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

`ROOT` is the primary checkout: the parent of
`git rev-parse --path-format=absolute --git-common-dir`, the same from the
primary checkout and any worktree (PowerShell:
`Split-Path -Parent (git rev-parse --path-format=absolute --git-common-dir)`).
Work it out once, at the start of the run.
Run every lifecycle command with the shell's working directory set to
`ROOT` (or to the slice worktree for `finish`), never with a `cd` that
leaves a shell sitting in `.worktrees/`:
`powershell.exe -NoProfile -ExecutionPolicy Bypass -File tools/slice.ps1 <cmd> -Lane Codex`.

**Before the first `doctor`, prove `.git` is writable.** From `ROOT`,
run `git update-ref refs/meadow/write-probe HEAD; git update-ref -d refs/meadow/write-probe`.
If either fails, claim nothing and tell Dave: "This session cannot
write `.git`: choose `meadow` in this session's Permissions dropdown,
then rerun `$run-queue`." A `:workspace` profile overrides
`.codex/config.toml`'s `default_permissions = "meadow"`.

## Workers keep contained contexts

Every subagent you start (worker, reviewer or steward) is started with
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
   the run. If the lane is empty, dispatch the steward with `JOB=refill`
   (below), adding `gates` and the ids landed so far if any, then rerun
   `doctor` after `done`.
2. **Claim.** Read `advice.dry_after` from `doctor`. When it is true, dispatch
   the steward with `JOB=gates refill` and the ids landed so far (below)
   before `start`. Admission plans ahead; since L-32, a dry lane is a
   warning after landing, but that is the backstop. After `done`, rerun
   `doctor`, then run `start`. Keep its JSON, and note
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
   ROOT=<ROOT>
   WORKTREE=<ROOT>\.worktrees\<id>
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
     rerun. A refill-gate stop, a block whose `Proof:` fails on master,
     or a successor with no block is planning work: dispatch the steward
     with `JOB=finish-stop`, the exact stop block and slice worktree.
     After `done`, rerun `finish` in that worktree, not Preflight. Keep
     any pending landed ids for the next batched `gates` dispatch.
   - A dry lane is not a stop (L-32): after `Slice landed:`, `finish`
     may print `lane dry: Codex`, `queue short: n of the 3-item floor`
     or `successor gated: <id>`. A dry or short Codex lane needs
     `JOB=gates refill` (step 8) before the next `doctor`;
     `successor gated` alone needs nothing now.
     The lifecycle lock held by the other lane's `finish` (the cause names
     its PID): `Wait-Process -Id <pid>`, then rerun `finish`.
     Anything else stops the run.
7. **Record.** Keep only the `Slice landed:` block and the worker's
   one-line summary. Drop everything else from your working notes.
8. **Batch stale gates.** Add the landed id to the run's pending list.
   Dispatch the steward with `JOB=gates` and the whole list after the
   run's last slice, even when the maximum has been reached. Dispatch
   earlier only when the lane needs it now: a dry/short warning or
   `doctor`'s `advice.dry_after`. Then send `JOB=gates refill` together.
   Include any ids `check_docs.py` warns "waits for a shipped slice",
   including landings outside this run. Clear the pending list only after
   `done`. `finish` never rewrites those gates.

An empty or short lane is not a reason to stop: refill it. Stop only when
the maximum is reached, a `start` refuses for any reason but an empty lane,
a slice is high risk, or the steward returns `blocked` (below).

## Refilling the lane

The existing `queue-steward` does all gate/refill/finish-stop plan and
queue editing. Never sweep plans or refill manually in this session.
Use `spawn_agent` with `agent_type: "queue-steward"`,
`fork_turns: "none"` (its configured reasoning is high), and this message:

```
ROOT=<ROOT>
LANE=Codex
JOB=<gates | refill | finish-stop, one or more>
LANDED=<pending landed ids, or none>
SHIPPED_WARNINGS=<ids from check_docs.py warnings, or none>
COORDINATOR_WORKTREE=<this session's worktree path>
SLICE_WORKTREE=<slice worktree for finish-stop, otherwise none>
STOP_BLOCK=<exact finish stop block for finish-stop, otherwise none>
Read plans/reference/queue-steward.md and use its job/result contract.
For this Codex dispatch, substitute Codex for the working Claude lane
and Claude for the protected Codex lane in that shared routine: create
[Codex] queue blocks, top up --lane Codex, protect Claude-owned files.
Use a codex/ branch for docs-only edits in the coordinator worktree;
check ownership before editing, register no ledger row, and merge/push
in this dispatch. For finish-stop, edit and commit only in the supplied
slice worktree; do not merge or push. Return only the routine's JSON.
```

Wait with `wait_agent`; never overlap the steward with a worker or
`finish`. It returns one of these JSON results:

```
{"status":"done","added":["<id>"],"cleared":["<id>"],"commit":"<sha>","note":"<one line>"}
{"status":"blocked","question":"...","options":[{"choice":"...","cost":"..."}],"recommend":"..."}
```

- `done`: inspect `git -C <ROOT> show --stat <commit>` and rerun
  `python tools/check_docs.py` in the edited worktree. Do not read the
  plan sections it touched. Keep `added`, `cleared` and `note` for the
  report. After a `gates` job, remove the submitted ids from the pending
  list. Resume the calling step: `finish-stop` retries worktree-local
  `finish`; refill returns to `doctor`; final gates proceeds to the report.
- `blocked`: ask Dave its question, options and costs, recommending its
  pick, and stop the run while awaiting his answer. Send the answer to
  the same steward with `followup_task`, then handle its result here.
  It blocks when no live plan has work left to specify, or when an open
  decision falls under `docs/agent-rules.md` rule 5. Keep the branch and
  pending ids intact; do not guess or implement a separate refill.

The stale-branch stop in step 6 stays with the coordinator; it needs no
plan reading.

## Final report

For each slice: the end-of-slice block from `CLAUDE.md` § "End-of-slice
report" (`finish` prints most of it; fill in `Connectors: active now` from
your own tool list), or the high-risk hand-off block, plus the worker's
reasoning level and any reviews or retries. For each refill: the plan it
came from (the steward's `note`), the ids it added, and why that slice came
next. Include the steward's cleared gates. Then a
one-paragraph trial note covering what the worker got wrong, where you had
to step in, and any change the worker brief or this skill needs.
