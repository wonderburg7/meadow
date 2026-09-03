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
  primary worktree — as Claude Code, then hand committed changes to Claude for
  risk-proportional integration.

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
branches. Closing out a Codex branch or worktree once it is integrated —
including deleting it — is Claude's responsibility, consistent with Codex not
merging, pushing or deleting shared branches itself.

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

- `NEXTSTEPS.md` is the canonical integrated-project queue. Update it on `master` after reviewing and
  integrating a Codex branch.
- `NEXTSTEPS.md` and `plans/` are shared with Claude. They state the
  integrated project priority.
- `CLAUDE.md`, `CHATGPT.md` and `AGENTS.md` are tool-policy and orientation
  files, not ordinary feature documentation. Change them only when Dave
  explicitly requests the corresponding policy or orientation change.

In short: an implementation branch documents what it changes; the integrator
records what is true on `master`.

### Risk-proportional hand-off and integration

Claude does not need to perform a full model review of every Codex diff. Codex
must classify the completed branch at the lowest tier whose conditions it
meets, explain the classification and provide reproducible evidence. Claude
uses that tier to spend review effort where it can change the outcome:

- **Low risk:** documentation, tests, fixtures, tooling or a small mechanical
  change with no intended runtime-behaviour change; no save-format,
  cross-system, balance, hot-path, dependency, generated-file or player-facing
  impact; no ownership overlap or merge conflict; and every relevant
  deterministic check passes. Claude may use the fast path: verify the commit
  and clean integration state, read the hand-off and `git show --stat`, rerun a
  cheap check if useful, then integrate without rereading the full diff.
- **Medium risk:** a bounded gameplay or UI change with clear ownership,
  focused tests and no high-risk trigger. Claude reviews only changed
  interfaces, surprising logic, reported weak spots and any manual acceptance
  requirement before integrating.
- **High risk:** save/schema/migration work, simulation architecture,
  cross-system behaviour, balance-sensitive logic, performance hot paths,
  dependencies, broad refactors, large/generated diffs, unresolved failures,
  ownership overlap or merge conflicts. Claude performs a full diff review and
  the relevant validation before integration.

Uncertainty alone is not a reason to default everything to high risk: use the
lowest tier supported by the concrete diff and evidence. Escalate when a named
trigger is present, checks are missing or failing, the hand-off does not match
the diff, or integration reveals a conflict. Claude may raise a tier, but should
state the specific trigger rather than repeat Codex's work by default.

Every implementation hand-off must contain only the information needed to
integrate it:

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

Finish every implementation hand-off with this block, unprompted:

```
Slice done:   <id> -- <name>
Branch:       codex/<slice-id>  |  verify.ps1: green
Risk tier:    <low|medium|high> -- <one-line reason>
Hands-on:     <concrete check for Claude to file in checks/ready.md>  (or: none)
Next in my lane: <id> -- <one line on what it does>
Ready to merge: yes -- Claude integrates and closes the branch out
```

Codex never merges, pushes or deletes the branch. "Ready to merge" is a
statement that the three conditions in `plans/workstreams.md` ("When to
merge") are met, not an action taken.

Deterministic check output and the committed diff are the evidence; a second
agent need not re-derive the implementation narrative. After integration,
Claude updates canonical project-state files only when the merged state makes
that necessary.

Codex must not:

- merge its branch into `master`, push changes or rewrite shared history unless
  Dave explicitly requests that specific action;
- edit `CLAUDE.md`, unless Dave explicitly
  asks for that exact documentation change; ordinary task-relevant Markdown is
  governed by the documentation rule above;
- run broad formatters, generators or cleanup commands that affect files
  outside the assigned task.

Claude is usually responsible for merging or cherry-picking Codex commits into
the integration branch, using the risk tier above rather than applying a
blanket full-review requirement.

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

- Treat `NEXTSTEPS.md` as the only canonical current queue. It holds five
  ready slices split into a **[Claude] lane** and a **[Codex] lane**. Take the
  first unclaimed **[Codex]** item and nothing else -- "implement the next
  slice" means exactly that. Read only the `Plan:` file and heading that item
  names; do not read the Claude lane's plan, the archive or Git history to
  work out what to do.
- The lanes are guaranteed not to share a file (`tools/check_docs.py` proves
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
  task scope. Before finishing, run relevant checks, review the diff, commit
  the result on the work branch and report the concise hand-off required by
  the risk-proportional integration section.
- In advisory mode, before finishing, check the working tree and make sure the
  session changed only allowed ChatGPT-specific Markdown files.
