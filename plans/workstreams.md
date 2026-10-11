# Active workstreams

<!-- CONTEXT: parallel-work-ledger | LOAD: before creating or integrating a branch/worktree -->

Edit this file only from the primary checkout (never from inside a feature
branch/worktree -- parallel branches editing this file will conflict on
merge). Add a row when a branch/worktree is created; remove it the moment
that work is integrated and closed out. `tools/check_docs.py` fails
verification if a row's worktree/branch no longer exists, or if a registered
`.worktrees/*` worktree has no row here.

## Lanes

`NEXTSTEPS.md` splits ready work into a **Claude lane** and a **Codex lane**,
and `tools/check_docs.py` proves the leading item in each lane names no file
in common. That is what makes simultaneous work safe: two open branches, one
per lane, cannot conflict by construction.

- One branch per lane at a time. A second branch in the same lane means the
  lane is being worked out of order -- finish or abandon the first.
- Overlap inside a lane is impossible if each slice is taken from the top of
  the queue. Overlap across lanes means the queue is wrong: fix
  `NEXTSTEPS.md`'s `Files:` lines rather than starting the branch.
- Deliberate overlap (comparing two approaches) is the one exception: mark
  both rows `competing`, note the comparison criterion in Scope, and delete
  the loser's branch/worktree the moment the decision is made.
- **Never start new work from a branch that has diverged.** A stale branch
  usually carries a queue/plan snapshot and unrelated commits alongside the
  work worth keeping, and building on it drags both into the new slice. Take
  the evidence commits you want onto a fresh `master`-based branch, leave the
  canonical-document snapshot behind, and close the old branch in the same
  pass (`codex/hive-comb-slice-4-repro`, 1 Sep 2026).

## When to merge

When a branch is ready to merge, and why it is never held for a hands-on
check: `plans/reference/closeout.md`, "When to merge". Its row here is
deleted by `finish`.

Both agents merge, push and close out their own lane's branch with
`tools/slice.ps1 finish`, and neither touches the other lane's. The one
exception is a **high-risk** Codex branch: Codex pushes it and hands it over,
and Claude reviews the full diff before running `finish` (`CHATGPT.md`,
"Risk-proportional closeout"). Dave does not need to decide merge timing; the
end-of-slice report states what was merged and what is next.

| Worktree path (branch) | Lane | Scope | Owner | Status | Depends on | Plan / slice |
| --- | --- | --- | --- | --- | --- | --- |
| `.worktrees/PP-3` (`codex/PP-3`) | Codex | Gyne rearing gates gyne cells and Royal jelly gates jelly | Codex | in progress | none | `plans/now/pollination.md` PP-3 -- Gyne rearing gates gyne cells and Royal jelly gates jelly |
| `.worktrees/T2-6` (`claude/T2-6`) | Claude | Associative learning | Claude | in progress | none | `plans/now/tier-two.md` T2-6 -- Associative learning |
