# Meadow — ChatGPT/Codex policy

This file applies to every ChatGPT and Codex session opened in the Meadow
repository. Read it before project orientation, plans or source files.

## Purpose and operating modes

ChatGPT/Codex may work with Meadow in either of two modes:

- **Advisory mode:** inspect the project, explain behaviour, identify risks,
  develop insights and make recommendations without editing implementation
  files.
- **Implementation mode:** implement an explicitly assigned task, with the
  same rights to read and edit Meadow's game/source files — including in the
  primary worktree — as Claude Code, then close the slice out with
  `tools/slice.ps1 finish` exactly as Claude does, or, for a high-risk slice,
  push the branch and hand it to Claude for review-then-closeout.

In implementation mode, Codex may edit the files reasonably needed for the
assigned task, run relevant checks, remove disposable artifacts created by its
own commands and commit its changes on a work branch (a `codex/...` branch,
or a dedicated worktree if one is already set up). It must keep changes
focused, preserve all pre-existing work, and follow the same branch discipline
as Claude: never leave or commit edits directly on `master`.

Dave authorises Codex to commit and push authorised work automatically,
without asking for confirmation again (5 Nov 2026). This includes pushing
`master` after integrating Codex's own completed changes through the permitted
closeout path, and committing and publishing explicitly requested policy or
queue updates. Keep work-branch discipline, verification, other lanes'
ownership and the high-risk review requirement; this grants no permission
to force-push, rewrite shared history or include unrelated work.

Run `tools/slice.ps1 start -Lane Codex` to claim the lane's leading item and
register its worktree in `plans/workstreams.md` atomically -- it also checks
the item's `Proof:` line still holds and refuses a lane that already has an
open worktree, so the same fix or investigation cannot be duplicated across
branches. Close it out with `tools/slice.ps1 finish`, run from inside that
worktree the moment the slice is green: the same command, and the same
timing, as Claude. It verifies, gates on any hands-on check the `Check:` line
named, commits, merges to `master`, pushes, removes the worktree and branch, and
deletes the ledger row. **Codex has the same commit, merge and push rights as
Claude for its own lane's branch** and does not wait for Dave or Claude to do
any of it.

The one exception is a **high-risk** slice (triggers listed under
"Risk-proportional closeout" below). There, Codex commits and pushes the
branch but does not merge it: it hands the branch to Claude with the hand-off
block, and Claude reviews the full diff and then runs `finish`. A hands-on
check outstanding is never a reason to hold a branch open -- file it in
`checks/ready.md` and finish.

Before running `finish`, update the owning plan's Status and `Next:` and
make sure the item's `Next after:` successor has a fenced `queue` block in its
plan section, or a line under "Not in the queue, and why" if it is not
startable (`plans/reference/closeout.md`, "Closeout order" step 2). Do not
promote it into the lane by hand. Never edit the `[Claude]` lane's entries.
`finish` performs the archive and refill: its `archived` and
`refilled` phases move the shipped specification into `plans/archive/`, remove
the delivered item from `## Next up`, and put both commits inside the merge.
There is no separate archive or queue-refresh step before or after `finish`,
and no window where the merge lands but the refill does not.

### Documentation and project-state ownership

Documentation that describes or is directly affected by an assigned change is
part of that change. In implementation mode, Codex should update the relevant
README, design, architecture, testing and feature-plan Markdown files on its
work branch when leaving them unchanged would make the branch incomplete or
inaccurate. Those documentation edits travel in the same focused commit or
commit series as the implementation and follow the same risk-proportional
integration path.

Canonical coordination files describe the state of the integrated `master`
branch, so their ownership is stricter:

- `NEXTSTEPS.md` is the canonical integrated-project queue. `finish` edits
  it on the slice's own branch (deleting the item and topping the lane up),
  so the refill travels into `master` inside the merge commit it makes, with
  no separate step on `master` afterwards and no window where the two
  disagree.
- `NEXTSTEPS.md` and `plans/` are shared with Claude. They state the
  integrated project priority.
- `CLAUDE.md`, `CHATGPT.md` and `AGENTS.md` are tool-policy and orientation
  files, not ordinary feature documentation. Change them only when Dave
  explicitly requests the corresponding policy or orientation change.

In short: an implementation branch documents what it changes; the integrator
records what is true on `master`.

### Independent Codex queue priorities

Dave delegates Codex-lane scheduling to Codex (5 Nov 2026). When asked to
implement the next slice, Codex may select, specify, refill and reorder
unclaimed Codex work without asking Dave to choose priorities. An empty lane
is a reason to refill it, not to stop while agreed, startable work remains.

- Prefer work that unblocks agreed dependencies, fixes a verified defect or
  completes an active plan; weigh player value, evidence, readiness and scope.
  Follow live plans' Status and `Next:` sections and explicit dependencies.
  Scheduling authority does not settle open product, architecture, save or
  balance decisions covered by `docs/agent-rules.md` rule 5.
- Before changing priorities, inspect the current queue's lane entries,
  `plans/workstreams.md` and lifecycle status. Check each proposed `Files:`
  path with `tools/slice.ps1 owner <path>`, and check queued and active work
  in other lanes for file, dependency and shared-contract overlap. Read only
  the relevant plan sections if those checks need more context.
- Change only unclaimed Codex entries and their owning plan sections. Never
  move, reorder, remove or rewrite another lane's entries, take over claimed
  work, or queue work that would invalidate another lane's assumptions.
  Choose another independent slice when there is overlap; if none is safe,
  report the exact conflict rather than changing another lane's scope.
  Refilling (below) adds two record edits outside the Codex lane, both
  shown by the refill's gate review: correcting a `## Not in the queue, and
  why` line or `queue-gated` fence whose gate has cleared, and retagging an
  unqueued Claude-backlog block the review says this lane may take.
- Make priority edits on a work branch, keeping the queue and plan blocks
  consistent. Read `plans/README.md`, "Writing or editing a plan", before
  specifying work. Use `tools/refill_lane.py --top-up --lane Codex` for
  admission, preserve its lifecycle locking and proof checks, and run
  `tools/check_docs.py`. Reordering must preserve dependencies and the
  existing admission checks. Recheck current ownership and queue state
  before integrating; preserve concurrent edits. Integrate the scheduling
  update before claiming it with `tools/slice.ps1 start -Lane Codex`.
- In the slice output, add `Priority change: <what was selected, added or
  reordered and why; other lanes checked and unaffected>`. Include this in
  both the normal end-of-slice report and a high-risk hand-off, even though
  `finish` does not print it. If a scheduling change cannot be followed by
  implementation, disclose it and the blocker in that session's output.
  Use `Priority change: none` when no independent scheduling change was made.

### Refilling an empty or gated Codex lane

When `tools/slice.ps1 start -Lane Codex` stops with "no unclaimed [Codex]
item", or `doctor`'s `advice.dry_after` is true, refill the lane in the same
session and then claim; do not stop or ask Dave first (5 Nov 2026: the lane
sat empty behind gates that had cleared, because nothing on this route
reread them).

1. In a `codex/refill-<date>` worktree, run `plans/reference/queue-steward.md`'s
   `JOB: gates` and then `JOB: refill` yourself with `LANE=Codex` -- the
   routine the `run-queue` skill dispatches to a steward. It starts with
   `python tools/refill_lane.py --top-up --lane Codex --dry-run`, whose gate
   review rechecks every recorded gate against today's branches and queue:
   open the stale ones, take any Claude-backlog block it lists, and only
   then specify new `[Codex]` blocks from agreed work in live plans.
2. Admit through `python tools/refill_lane.py --top-up --lane Codex` (or
   `--add <id>` per slice, to set the order), run `python tools/check_docs.py`,
   commit, merge to `master` and push in the same sitting (a docs-only edit
   takes no ledger row), then run `start -Lane Codex` again and implement
   the slice it claims. Report the refill on the `Priority change:` line.
3. If nothing is admissible after that, stop with `Lane blocked:` and, for
   each candidate, the review's `now:` line and the one event or decision
   that would clear it -- the routine's `blocked` result, asked of Dave.

### Risk-proportional closeout

The risk tier decides **who closes the branch out**, and how much review
effort a hand-off is worth. Codex classifies its own completed branch at the
lowest tier whose conditions it meets, and says why in one line:

- **Low risk:** documentation, tests, fixtures, tooling or a small mechanical
  change with no intended runtime-behaviour change; no save-format,
  cross-system, balance, hot-path, dependency, generated-file or player-facing
  impact; no ownership overlap or merge conflict; and every relevant
  deterministic check passes. **Codex runs `finish` itself.**
- **Medium risk:** a bounded gameplay or UI change with clear ownership,
  focused tests and no high-risk trigger. **Codex runs `finish` itself.**
- **High risk:** save/schema/migration work, simulation architecture,
  cross-system behaviour, balance-sensitive logic, performance hot paths,
  dependencies, broad refactors, large/generated diffs, unresolved failures,
  ownership overlap or merge conflicts. **Codex commits and pushes the branch
  but does not merge it**, and hands it to Claude, who reviews the full diff
  and the relevant validation before running `finish`.

Uncertainty alone is not a reason to default everything to high risk: use the
lowest tier supported by the concrete diff and evidence. Escalate when a named
trigger is present, checks are missing or failing, or `finish` reveals a merge
conflict -- a conflict between lanes is evidence the queue's `Files:` lines
were wrong, so fix them in the same pass. Claude may raise a tier when
reviewing, but should state the specific trigger rather than repeat Codex's
work by default.

**`finish` takes about a minute, or 4-10 minutes when the branch touches
workflow tooling** (its branch verify then runs the lifecycle suite, one
worktree at a time; `finish` is the verify, so do not run `verify.ps1`
first). **`finish` is the last, expensive step, not the first test.** Before
it, run `python tools/prefinish.py` in the slice's worktree: the boot check,
`tests/source_checks.py`, then the unit tests that name a file the branch
changed, stopping at the first failure, in about a minute. On 12 Oct 2026
PP-3 lost a 98-minute `finish` to a parse error and another to a
source-check rule; this finds both in seconds. Exit 3 ("not a code fault")
is the Godot import cache: change no code, run the Fix command it prints. **Run it outside the sandbox from the first call**
(`sandbox_permissions: "require_escalated"`): its verify runs as PowerShell
background jobs, which the sandbox can deny (`Receive-Job : Access is
denied`; PP-3, 12 Oct 2026). Give the shell call a timeout of at least 20
minutes (`timeout_ms: 1200000`, or `yield_time_ms: 1200000` on
`exec_command`; a 30 s yield lost PP-3's output), and keep polling the
same process until it prints one of its two closing blocks: `Slice landed:`
or `slice finish stopped`. A call that returns with neither has **not**
stopped -- `finish` is still running. Do not rerun it, and do not report it
as stopped without a diagnosis. Instead run
`tools/slice.ps1 status -Lane Codex`: `running` names the lifecycle command
in progress and its PID (wait for it with `Wait-Process -Id <pid>`), and
`last_run` says how the last one ended (`outcome`, `step`, `cause`). While
finish verifies the branch, `state` says so and `verifying` gives its PID:
wait for that one. **Never stop a Godot or Python process** -- headless Godot
runs are a live verify's unit tests, and stopping one fails that run
(PP-3's escalated finish, 12 Oct 2026). A failed
verify's full output is saved to `.git/meadow-slice-verify.log` in the
primary checkout, and the stop block names that path. A
`slice lifecycle is busy` message that names a `finish` run from your own
worktree is your own earlier call (27 Sep 2026: FB-3's closeout was retried
twice into its own still-running `finish`).

**A slice Codex closed out itself ends with the end-of-slice report** in
`CLAUDE.md`, "End-of-slice report" -- `finish` prints it, including the
`Next model` and `Toggle` lines; fill in `Connectors: active now` with the
connectors this Codex session has. Dave should not be
able to tell from the report which agent ran the slice. Post it in the chat
unprompted; there is no hand-off block for a slice nobody has to integrate.

**A high-risk hand-off** must contain only the information Claude needs to
review and integrate it:

1. task and exact scope;
2. baseline and final commit hash, plus changed-file summary;
3. checks run and their results;
4. risk tier and short evidence-based reason;
5. remaining risk, manual check or explicit `none` -- Claude copies any
   manual-check item into `checks/ready.md` on integration, so state
   it as a concrete, checkable action rather than a vague "needs
   testing"; and
6. whether this hand-off completes the plan's final slice -- if so, name it
   and list every follow-up; if not, name the next slice; and
7. the next-slice block below, so Dave learns what happens next without
   opening a file.

Finish a high-risk hand-off with this block, unprompted:

```
Slice done:   <id> -- <name>
Branch:       codex/<slice-id>  (pushed)  |  verify.ps1: green
Risk tier:    high -- <the specific trigger>
Hands-on:     <concrete check for Claude to file in checks/ready.md>  (or: none)
Next in my lane: <id> -- <one line on what it does>
Priority change: <what changed and why; other lanes checked and unaffected, or none>
Ready to merge: yes -- Claude reviews the full diff, then runs 'finish'
```

"Ready to merge" is a statement that the conditions in
`plans/reference/closeout.md` ("When to merge") are met, not an action taken. Push
the branch before handing it over, so the diff is reviewable without the
worktree.

Deterministic check output and the committed diff are the evidence; a second
agent need not re-derive the implementation narrative.

Codex must not:

- rewrite shared history (no force-push, no rebase of a pushed branch, no
  amending a merged commit) unless Dave explicitly requests that action;
- merge, push or delete a branch belonging to the `[Claude]` lane, or edit
  that lane's queue entries;
- edit `CLAUDE.md`, unless Dave explicitly
  asks for that exact documentation change; ordinary task-relevant Markdown is
  governed by the documentation rule above;
- run broad formatters, generators or cleanup commands that affect files
  outside the assigned task.

Claude reviews and integrates only the high-risk tier, using the specific
trigger rather than a blanket full-review requirement. Everything else,
Codex lands itself.

## Headless-check work

When Dave asks Codex to continue a named diagnostic slice, the work must still use
implementation mode. Limit it to the existing headless harness, diagnostic
observations needed by the check and `test_scenarios` fixtures, plus the
smallest source, runner, test and scenario changes necessary to make the named
check causal and runnable. Do not expand into unrelated gameplay, balance, UI,
asset, project-plan or Claude-work-queue changes.

Record the result in the relevant shared `plans/` file and keep the resulting
commits distinct.

## Session routing

- Normally use the existing queue to find your work. `tools/slice.ps1 start -Lane
  Codex` claims the first unclaimed **[Codex]** item and prints it as JSON:
  `id`, `plan`, `heading`, `files`, `check`, `proof`, `next_after`, and a
  `read` field holding the exact command that prints that slice's plan
  section and nothing else. Run the `read` command; that is the whole
  briefing. `doctor -Lane Codex` prints the same thing without claiming
  anything. An empty lane is refilled first ("Refilling an empty or gated
  Codex lane", above), in the same session. Read queue entries only when selecting or checking priorities
  under "Independent Codex queue priorities"; do not read it whole.
- Do not read the Claude lane's plan, the archive or Git history to work out
  what to do. `NEXTSTEPS.md` holds two independent lanes, `### Claude lane`
  and `### Codex lane`, up to five items each (`tools/check_docs.py`
  enforces it); normally your lane's leading item is already the decision.
  Independent scheduling may inspect other lanes' queue and ownership records
  and relevant plan sections solely to avoid disrupting their work. At
  closeout, edit only the `### Codex lane` subsection.
- No file appears in both lanes (`tools/check_docs.py` proves
  it), so a Codex branch and a Claude branch can run at the same time without
  conflicting. If the slice you are on turns out to need a file the other
  lane's leading item names, stop and say so rather than editing it -- that
  means the queue is wrong.
- Update the owning shared plan and queue at a real slice transition or an
  independent scheduling change under the policy above. Update player checks
  only at a real slice transition; archive terminal execution records in `plans/archive/`
  rather than retaining them at the root.
- Read other Meadow files only as evidence needed for the requested analysis.
- Keep recommendations clearly labelled as recommendations, not completed
  changes.
- Before implementation, record the current branch, baseline commit, and the
  task scope. Before finishing, run relevant checks, review the diff and
  commit on the work branch. Then close out per "Risk-proportional closeout":
  low or medium risk, update the plan and give the successor its `queue` block, then run
  `tools/slice.ps1 finish` (which archives the slice and refills the lane),
  and post the end-of-slice report;
  high risk, push the branch and post the hand-off block instead.
- In advisory mode, before finishing, check the working tree and make sure the
  session changed only allowed ChatGPT-specific Markdown files.
