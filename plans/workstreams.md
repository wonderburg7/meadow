# Active workstreams

<!-- CONTEXT: parallel-work-ledger | LOAD: before creating or integrating a branch/worktree -->

Edit this file only from the primary checkout (never from inside a feature
branch/worktree — parallel branches editing this file will conflict on
merge). Add a row when a branch/worktree is created; remove it the moment
that work is integrated and closed out (see `CLAUDE.md`, "Coordinating and
closing out workstreams"). `tools/check_docs.py` fails verification if a
row's worktree/branch no longer exists, or if a registered `.worktrees/*`
worktree has no row here.

Before starting new work, scan the Scope column for overlap with what
you're about to do. No overlap: add a row and start. Deliberate overlap
(comparing two approaches): mark both rows `competing` and note the
comparison criterion in Scope; once decided, delete the losing row and its
branch/worktree in the same pass. Accidental overlap: don't start a new
branch — extend the existing row's work instead.

| Branch (worktree path) | Scope | Owner | Status | Depends on | Plan / slice |
| --- | --- | --- | --- | --- | --- |
| `codex/challenge-1-slice-10` (`.worktrees/challenge-1-slice-10`) | Implement Slice 10a/10c/10f/10g (queen role-lock, pollen freeze, real collection counter, guard-order fix) | Claude Code | active | none | `plans/now/challenge-1.md` Slice 10 |
