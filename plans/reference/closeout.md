# Closing a slice — branches, merges, checks and the queue

<!-- CONTEXT: reference | LAYER: reference | LOAD: at closeout only -->
Status: reference | Owner: Dave / Claude Code | Next: nothing further -- durable rules moved out of CLAUDE.md so they load only at closeout | Dependency: none | Verified: 2026-10-14

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

A docs-only edit to `NEXTSTEPS.md` or `plans/` that is merged and pushed in
the same sitting needs no row: the queue steward's `gates` and `refill`
jobs, and similar coordinator bookkeeping (Dave, 14 Oct 2026). The
register/remove pair was two of every three commits such an edit made.
`tools/slice.ps1 owner` still reports the work through its unmerged branch.
Only the row a Codex session or Dave would read is lost, which is why the
edit must not outlive the sitting. Code, and any docs work held open, still
register.

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
renumbers it, refusing a queue that would fail `tools/check_docs.py`. Both
go in one `<id> -- closeout: ...` commit on the branch. The
`archived` and `refilled` gates then prove both happened. After the merge,
the ledger row's removal, any finished plan's archive and the regenerated
ready-check index share one `<id> -- closeout on master: ...` commit, and
one push carries it with the merge (14 Oct 2026: a commit each had made
bookkeeping half of master's history). **Before running it, on the branch:**

1. Update the owning plan's Status line and `Next:` field. After a plan's
   last slice, set `Next: None — plan complete` and list every follow-up with
   where it was filed. Leave the plan where it is: after the merge, once its
   queue item and ledger row are gone, `finish` runs `python
   tools/archive_slice.py --complete-plans`, which moves every plan
   check_docs calls terminal to plans/archive/(name)_(date).md and repoints
   each reference to it, in the same closeout commit. A finding from the plan's own checks becomes its next
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

**`finish` takes about a minute when the branch reaches no game file and no
lifecycle tooling, 4-6 minutes when it touches lifecycle tooling, and 6-10
when it reaches the game** (14 Oct 2026, on Dave's laptop). Its branch verify
runs the game tests (the modules that boot Godot) only when a changed file
can reach them, and the lifecycle suite only when the branch touches a file
its fixtures copy; the suite waits if another worktree's is already running,
since only one runs at a time. `verify.ps1 -Full` runs both regardless. Do not run
`verify.ps1` yourself before it -- `finish` is the verify. The long case is
past the 10-minute cap on a foreground Bash call, so always run it with
`run_in_background` and wait for the notification. It has ended only when it prints `Slice landed:` or a `slice finish stopped` block; a
shell that returns without either left it running, so never start a second
lifecycle command on top of it (27 Sep 2026: a Codex session did, twice, and
was told only "busy" by its own run). `finish` verifies the branch before
it takes the lifecycle lock, so the other lane is not held up meanwhile;
a second `finish` in the same worktree during that verify is refused.
`tools/slice.ps1 status` shows the slice's state as "finish verifying the
branch" then, `running` (the command holding the lifecycle lock, with its
PID) after it, and `last_run` (how the last one ended: `outcome`, `step`,
`cause`). A failed
verify's full output is also saved to `meadow-slice-verify.log` in the
primary checkout's `.git` directory; the stop block names the path.

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
sentence or two, one `PASS:` line stating the single condition, one `Runner:`
line (who runs it in a pass: `plans/reference/check-runner.md`, "Choosing a
runner"), one `Owner:` line naming the plan;
`python tools/new_check.py --name "<name>" --owner <plan> --runner <runner>`
writes the skeleton with the next free id. Dave replies by id. Move blocked
checks to `checks/blocked.md`; archive confirmed ones with
`python tools/new_check.py --confirm C-<n>`, which also regenerates the
index and lists the live lines that still name the id. Three admission
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

## Recording a system-improvement signal

Before `finish`, take one short decision: did this slice hit friction in the
workflow itself -- a lifecycle stop, a check that failed for a reason
unrelated to the slice, an instruction that misled, a tool that had to be
worked around -- that is likely to recur? If so, append one entry to
`plans/observations/system-improvement-signals.md` in its entry format;
otherwise record nothing. Most slices record nothing. Do not act on the
signal in the slice. Until 25 Sep 2026 nothing on the slice route pointed
here, and every entry came from maintenance passes.
