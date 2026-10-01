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

**One slice, one branch, one merge, merged as soon as it is green.** There is
never a reason to hold a finished branch open or to batch two slices into a
single merge.

A branch is ready to merge when all three are true:

1. `tools/verify.ps1` passes on the branch.
2. Any hands-on check it produced is written into `checks/ready.md` -- filing
   the check is what closes the branch. **A branch is never held open waiting
   for Dave to play-test it.**
3. Its row here is ready to delete.

Merge order between the two lanes does not matter: whichever finishes first
merges first, and the other merges on top with no rebase, because the lanes
share no file. If `git merge` reports a conflict anyway, that is evidence the
queue's `Files:` lines were wrong -- fix them in the same pass.

Both agents merge, push and close out their own lane's branch with
`tools/slice.ps1 finish`, and neither touches the other lane's. The one
exception is a **high-risk** Codex branch: Codex pushes it and hands it over,
and Claude reviews the full diff before running `finish` (`CHATGPT.md`,
"Risk-proportional closeout"). Dave does not need to decide merge timing; the
end-of-slice report states what was merged and what is next.

| Worktree path (branch) | Lane | Scope | Owner | Status | Depends on | Plan / slice |
| --- | --- | --- | --- | --- | --- | --- |
| `.worktrees/UI-F-2` (`codex/UI-F-2`) | Codex | warnings carry a severity and a pending one is never lost | Codex | in progress | none | `plans/now/ui-feedback.md` UI-F-2 -- warnings carry a severity and a pending one is never lost |
