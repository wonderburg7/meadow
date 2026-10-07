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
first). Give the shell call a timeout of at least 20 minutes
(`timeout_ms: 1200000` where the shell tool takes one), and keep polling the
same process until it prints one of its two closing blocks: `Slice landed:`
or `slice finish stopped`. A call that returns with neither has **not**
stopped -- `finish` is still running. Do not rerun it, and do not report it
as stopped without a diagnosis. Instead run
`tools/slice.ps1 status -Lane Codex`: `running` names the lifecycle command
in progress and its PID (wait for it with `Wait-Process -Id <pid>`), and
`last_run` says how the last one ended (`outcome`, `step`, `cause`). A failed
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

- Do not read `NEXTSTEPS.md` to find your work. `tools/slice.ps1 start -Lane
  Codex` claims the first unclaimed **[Codex]** item and prints it as JSON:
  `id`, `plan`, `heading`, `files`, `check`, `proof`, `next_after`, and a
  `read` field holding the exact command that prints that slice's plan
  section and nothing else. Run the `read` command; that is the whole
  briefing. `doctor -Lane Codex` prints the same thing without claiming
  anything. Reading the queue file itself is never needed to start.
- Do not read the Claude lane's plan, the archive or Git history to work out
  what to do. `NEXTSTEPS.md` holds two independent lanes, `### Claude lane`
  and `### Codex lane`, up to five items each (`tools/check_docs.py`
  enforces it); your lane's leading item is already the decision. At
  closeout, edit only the `### Codex lane` subsection.
- No file appears in both lanes (`tools/check_docs.py` proves
  it), so a Codex branch and a Claude branch can run at the same time without
  conflicting. If the slice you are on turns out to need a file the other
  lane's leading item names, stop and say so rather than editing it -- that
  means the queue is wrong.
- Update the owning shared plan, the queue and any player check only at a real
  slice transition; archive terminal execution records in `plans/archive/`
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
