# Meadow — ChatGPT/Codex policy

This file applies to every ChatGPT and Codex session opened in the Meadow
repository. Read it before project orientation, plans or source files.

## Purpose and operating modes

ChatGPT/Codex may work with Meadow in either of two modes:

- **Advisory mode:** inspect the project, explain behaviour, identify risks,
  develop insights and make recommendations without editing implementation
  files.
- **Isolated implementation mode:** implement an explicitly assigned task in
  a dedicated Git worktree and `codex/...` branch, then hand committed changes
  to Claude for risk-proportional integration.

Claude Project and Claude Code own the primary Meadow worktree and the
integration branch. Codex must never implement directly in Claude's worktree.

## Worktree editing boundary

Codex may enter isolated implementation mode only when all of these conditions
are true:

1. Dave has explicitly asked Codex to implement or change the project, rather
   than only analyse, diagnose, review, test, plan or recommend.
2. The current branch name begins with `codex/`.
3. `git worktree list` confirms that the current directory is a dedicated
   worktree separate from the primary worktree holding `master`.
4. Codex has checked the status of both worktrees and confirmed that its task
   does not overlap files currently being edited by Dave or Claude. If overlap
   is uncertain, stop and ask Dave before editing.

When any condition is not met, the repository is read-only except for:

- `CHATGPT.md` and `AGENTS.md`, only when Dave explicitly asks to change the
  ChatGPT policy itself;
- Markdown files whose filename begins with `CHATGPT_`;
- `insights_from_ChatGPT.md`.

In isolated implementation mode, Codex may edit only the files reasonably
needed for the assigned task, run relevant checks, remove disposable artifacts
created by its own commands and commit its changes on its own `codex/...`
branch. It must keep changes focused and preserve all pre-existing work.

### Documentation and project-state ownership

Documentation that describes or is directly affected by an assigned change is
part of that change. In isolated implementation mode, Codex should update the
relevant README, design, architecture, testing and feature-plan Markdown files
on its `codex/...` branch when leaving them unchanged would make the branch
incomplete or inaccurate. Those documentation edits travel in the same focused
commit or commit series as the implementation and follow the same
risk-proportional integration path.

Canonical coordination files describe the state of the integrated `master`
branch, so their ownership is stricter:

- `NEXTSTEPS.md` is the canonical integrated-project queue. Claude, or whoever
  is acting as integrator, updates it on `master` after reviewing and
  integrating a Codex branch.
- Codex must not independently curate, reorder or complete `NEXTSTEPS.md` from
  its private work queue. It may edit the file on its branch only when Dave
  explicitly includes that exact update in the assignment. Such an edit is a
  proposal until the integrator confirms it still describes `master` at merge
  time.
- `CHATGPT_NEXTSTEPS.md` is Codex's separate hand-off and never establishes the
  state of unmerged work as integrated project truth.
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
4. risk tier and short evidence-based reason; and
5. remaining risk, manual check or explicit `none` -- Claude copies any
   manual-check item into `HANDS_ON_CHECKS.md` on integration, so state
   it as a concrete, checkable action rather than a vague "needs
   testing".

Deterministic check output and the committed diff are the evidence; a second
agent need not re-derive the implementation narrative. After integration,
Claude updates canonical project-state files only when the merged state makes
that necessary.

Codex must not:

- edit files in the primary worktree, switch the primary worktree's branch or
  stage, commit, discard, clean or otherwise manipulate its changes;
- merge its branch into `master`, push changes or rewrite shared history unless
  Dave explicitly requests that specific action;
- edit `CLAUDE.md`, Claude-owned plans or `NEXTSTEPS.md` unless Dave explicitly
  asks for that exact documentation change; ordinary task-relevant Markdown is
  governed by the documentation rule above;
- adopt work from Claude plans as its own work queue; or
- run broad formatters, generators or cleanup commands that affect files
  outside the assigned task.

Claude remains responsible for merging or cherry-picking Codex commits into
the integration branch, using the risk tier above rather than applying a
blanket full-review requirement.

### Worktree setup exception

When Dave explicitly asks Codex to set up or maintain this isolation, Codex
may work from the primary worktree only to:

- inspect repository and worktree state;
- edit and commit `CHATGPT.md` and `AGENTS.md` when the request includes a
  policy change, plus `CLAUDE.md` and directly affected `CHATGPT_*.md`
  hand-offs when Dave explicitly asks for a cross-tool policy or orientation
  change to be reconciled; and
- create or remove a separate worktree and its `codex/...` branch.

Before doing so, verify the exact target path and existing worktrees. Never
stage or commit any other primary-worktree file under this exception, switch
its branch, or disturb uncommitted Dave/Claude changes. This exception does not
permit feature, game or canonical project-state documentation changes on
`master`. Worktree removal is allowed only after Dave explicitly requests it
or the branch has been integrated and its recoverability has been verified.

## Headless-check work

When Dave asks Codex to continue an active slice from
`CHATGPT_HEADLESS_CHECK_PLAN.md`, the work must still use isolated
implementation mode. Limit it to the existing headless harness, diagnostic
observations needed by the check and `test_scenarios` fixtures, plus the
smallest source, runner, test and scenario changes necessary to make the named
check causal and runnable. Do not expand into unrelated gameplay, balance, UI,
asset, project-plan or Claude-work-queue changes.

Record the result in the relevant `CHATGPT_` plan and keep the resulting
commits distinct from Claude's work.

## Session routing

- For current ChatGPT work, read `CHATGPT_NEXTSTEPS.md` rather than
  `NEXTSTEPS.md`. In implementation mode, work only from Dave's explicit task
  or an active `CHATGPT_` plan that Dave explicitly asks Codex to continue.
- Read other Meadow files only as evidence needed for the requested analysis.
- Do not adopt or complete tasks from Claude's plans.
- Keep recommendations clearly labelled as recommendations, not completed
  changes.
- If useful implementation is blocked by the hard editing boundary, record
  the durable, evidence-backed recommendation in `insights_from_ChatGPT.md`
  before finishing. Do this automatically; do not leave the only copy in the
  conversation, a temporary plan or `CHATGPT_NEXTSTEPS.md`. Keep execution
  detail in the relevant `CHATGPT_` plan and put only the current finding,
  consequence and recommended next action in the insights file.
- Do not duplicate transient notes or completed/rejected work in
  `insights_from_ChatGPT.md`. Update or remove an existing related insight
  when new evidence supersedes it; Git history is the archive.
- Before implementation, record the current branch, baseline commit, both
  worktree statuses and the task scope. Before finishing, run relevant checks,
  review the diff, commit the result on the `codex/...` branch and report the
  concise hand-off required by the risk-proportional integration section.
- In advisory mode, before finishing, check the working tree and make sure the
  session changed only allowed ChatGPT-specific Markdown files.
- Never alter or clean up pre-existing changes belonging to Dave or Claude.

This boundary is intentionally stricter than general repository permissions.
If implementation cannot be isolated safely in a dedicated Codex worktree,
stop at advice or a handoff for Claude.
