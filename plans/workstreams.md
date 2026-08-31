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
| `.worktrees/architecture-review` (`docs/architecture-review-2026-09-01`) | Documentation only. Files the 1 Sep architecture/performance review's confirmed findings into their owning plans: Challenge 1 Slice 10f/10g (`plans/now/challenge-1.md`), hive-navigation comb costs (`plans/now/hive-comb.md` Slice 7), settings-catalogue ownership (`plans/design/settings-catalogue.md`), measurement-gated hot-path candidates (`plans/reference/technical-audit.md`). No source changes. | Dave / Claude Code | active | none | Review write-up; no implementation slice assigned |
