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
  to Claude for review and integration.

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

Codex must not:

- edit files in the primary worktree, switch the primary worktree's branch or
  stage, commit, discard, clean or otherwise manipulate its changes;
- merge its branch into `master`, push changes or rewrite shared history unless
  Dave explicitly requests that specific action;
- edit `CLAUDE.md`, Claude plans or `NEXTSTEPS.md` unless Dave explicitly asks
  for that exact documentation change;
- adopt work from Claude plans as its own work queue; or
- run broad formatters, generators or cleanup commands that affect files
  outside the assigned task.

Claude remains responsible for reviewing and merging or cherry-picking Codex
commits into the integration branch.

### Worktree setup exception

When Dave explicitly asks Codex to set up or maintain this isolation, Codex
may work from the primary worktree only to:

- inspect repository and worktree state;
- edit and commit only `CHATGPT.md` and `AGENTS.md` when the request includes a
  policy change; and
- create or remove a separate worktree and its `codex/...` branch.

Before doing so, verify the exact target path and existing worktrees. Never
stage or commit any other primary-worktree file, switch its branch, or disturb
uncommitted Dave/Claude changes. Worktree removal is allowed only after Dave
explicitly requests it or the branch has been integrated and its recoverability
has been verified.

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
  commit hash plus any remaining risks to Dave and Claude.
- In advisory mode, before finishing, check the working tree and make sure the
  session changed only allowed ChatGPT-specific Markdown files.
- Never alter or clean up pre-existing changes belonging to Dave or Claude.

This boundary is intentionally stricter than general repository permissions.
If implementation cannot be isolated safely in a dedicated Codex worktree,
stop at advice or a handoff for Claude.
