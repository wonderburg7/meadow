# Closing a slice — branches, merges, checks and the queue

<!-- CONTEXT: reference | LAYER: reference | LOAD: at closeout only -->
Status: reference | Owner: Dave / Claude Code | Next: nothing further -- durable rules moved out of CLAUDE.md so they load only at closeout | Dependency: none | Verified: 2026-09-19

Read this when a slice's code is done, or when integrating a Codex branch.
`tools/slice.ps1 finish` enforces the phases below; this file says why.
It moved out of `CLAUDE.md` on 17 Sep 2026, where it was re-sent on every
request of every session, including the ones that never reach closeout.

## Branches follow the lanes

One `[Claude]`-lane branch and one `[Codex]`-lane branch may be open at once;
`tools/check_docs.py` proves the two lanes in `NEXTSTEPS.md` share no file, so
they cannot conflict. Two branches in the same lane means the lane is being
worked out of order -- finish or abandon the first. `tools/slice.ps1 start`
adds the `plans/workstreams.md` row from the primary checkout; that file is
never edited from inside a feature branch. Deliberate overlap (comparing two
approaches) is the one exception: mark both rows `competing` with the
comparison criterion, and delete the loser's branch/worktree the moment the
decision is made.

## When to merge

**One slice, one branch, one merge, as soon as it is green.** Never batch two
slices into one merge, and never hold a finished branch open. A branch is
ready the moment `tools/verify.ps1` passes and any hands-on check it produced
is filed -- *waiting for Dave to play-test is never a reason to delay a
merge*. Merge order between lanes does not matter. A merge conflict between
lanes is evidence the queue's `Files:` lines were wrong -- fix them in the
same pass.

## Closeout order

Run `tools/slice.ps1 finish` from inside the slice's worktree immediately
after integrating any branch, never deferred. It commits outstanding work,
then (L-13) does the two mechanical edits itself and commits each:
`python tools/archive_slice.py <id>` moves the delivered slice's
specification into plans/archive/(id)_(date).md, leaves a one-line pointer
and drops its row from the plan's open-slices table; `python
tools/refill_lane.py --delete <id>` removes the item from its lane and
renumbers it, refusing a queue that would fail `tools/check_docs.py`. The
`archived` and `refilled` gates then prove both happened. **Before running
it, on the branch:**

1. Update the owning plan's Status line and `Next:` field. After a plan's
   last slice, set `Next: None — plan complete` and list every follow-up with
   where it was filed. A finding from the plan's own checks becomes its next
   slice while the plan is open; one that surfaces after it is archived
   starts a new plan.
2. Make sure the item's `Next after:` successor has a fenced `queue` block in
   its own plan section -- the `**[Lane] <id> -- <title>**` line and its five
   fields, which is what the refill copies in. If it is not startable yet,
   fence it `queue-gated` and put one line under `## Not in the queue, and
   why` saying what it waits for. `finish` then deletes the closing item and
   tops the lane back up towards five from every admissible block in the
   backlog, successor first. If `refill_lane.py` refuses, `finish` stops
   naming this step; do it and retry.

   The top-up is best-effort: it never queues a slice whose `Proof:` no longer
   holds or whose files the other lane owns, so a lane can land short of five.
   That is not a closeout failure and is not a reason to hold the merge --
   `finish` prints which candidate it refused and why, and which gated blocks
   are waiting. A lane short with nothing in the backlog is a signal that the
   owning plan needs its next slice specified, which is plan work, not
   closeout work.

Either edit may be left uncommitted: `finish` commits it first. A branch that
did the archive or the deletion by hand passes straight through, because each
tool runs only when its step is still owed.

Edit only your own lane's subsection of `NEXTSTEPS.md`; the other lane's
branch is editing the other one, and separate subsections keep the two merges
clean. A worktree is never kept open because a hands-on check is outstanding.

## Each lane closes out its own branch

Codex has the same commit, merge and push rights as Claude and runs `finish`
on its own slices. The exception is a **high-risk** Codex slice: it is pushed
and handed over, and Claude reviews the full diff before running `finish`.
`CHATGPT.md`'s "Risk-proportional closeout" decides the tier. When reviewing a
hand-off, read it and `git show --stat` first, then use the lowest tier the
evidence supports:

- **Low:** documentation, tests, fixtures or runtime-neutral tooling with
  passing checks and no overlap. Verify the commit/stat and hand-off.
- **Medium:** bounded UI/gameplay change. Inspect interfaces, surprising logic,
  weak spots and manual-check needs.
- **High:** save/schema, simulation architecture, hot paths, dependencies,
  broad refactors, failed/missing checks, overlap or conflict. Review the full
  diff and validation.

## Filing a hands-on check

Every needed hands-on check is one `C-<n>.md` record in `checks/ready/`, surfaced in
`checks/ready.md`, in that format: `### C-<n> -- <name>`, the action in a
sentence or two, one `PASS:` line stating the single condition, one `Owner:`
line naming the plan. Dave replies by id. Move blocked checks to
`checks/blocked.md` and confirmed entries to the archive. Three admission
rules (evidence in `plans/reference/check-loop.md`):

- **Write the acceptance from the player's seat, once.** A slice's
  `Acceptance` and the check it files are the same sentences. If it cannot be
  written as something Dave does and sees, the slice is not specified yet.
- **A rare condition ships with the way to trigger it.** A check nobody can
  run on demand goes to `checks/blocked.md` with its unblocker named.
- **File a check only if failing it would change something.** Say in the
  entry what a failure would cause.

Decisions never go in `checks/ready.md`; ask Dave in the session that needs
the answer.
