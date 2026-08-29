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
| codex/challenge1-slice8a-full-storage (`.worktrees/challenge1-slice8a`) | full-storage bug that silently discards a forager's carried resource | Codex | in progress | — | `plans/now/challenge-1.md` Slice 8a |
| codex/challenge1-slice8b-manual-collection (`.worktrees/challenge1-slice8b`) | queen waits at the flower during manual nectar collection instead of auto-flying home | Codex | in progress | 8a lands first | `plans/now/challenge-1.md` Slice 8b |
| codex/challenge1-slice8d-role-guard (`.worktrees/challenge1-slice8d`) | guard the "If idle" backup-role menu so the queen's backup role can't become Comb Worker | Codex | in progress | 8a lands first | `plans/now/challenge-1.md` Slice 8d |
| codex/challenge1-slice8e-forage-presentation (`.worktrees/challenge1-slice8e`) | camera-follow/4x-speed presentation for automatic nectar foraging | Codex | in progress | 8a, 8b, 8d land first | `plans/now/challenge-1.md` Slice 8e |
