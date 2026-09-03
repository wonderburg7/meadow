# Agent workflow W-5 -- `tools/slice.ps1 finish` closes it atomically

Delivered 2026-09-03.

## What shipped

`tools/slice.ps1 finish`, run from inside a slice worktree, in this order,
stopping at the first failure:

1. Runs `tools/verify.ps1` on the branch (passing `-Quiet` once W-7 adds that
   switch; the script detects it rather than assuming it exists). Non-zero →
   print its output and exit 1 without touching anything.
2. Reads the branch's slice id from its own name (`claude/<id>` or
   `codex/<id>`) and looks it up in `NEXTSTEPS.md`. If its `Check:` line
   names a hands-on check, exits 1 unless `checks/ready.md` gained a new
   `### C-<n>` entry since `master`.
3. Commits anything outstanding on the branch.
4. Stops any running `Godot*` process before touching the worktree -- a
   running instance holding `.worktrees/<id>` blocked two sessions the week
   this plan was written.
5. From the primary checkout: `git merge --no-ff` the branch, pushes,
   removes the worktree, deletes the branch locally and on the remote (if
   pushed), deletes its `plans/workstreams.md` row, and commits that
   deletion.
6. Prints the end-of-slice report block, with `Slice landed`, `Branch`,
   `Merged`, `Hands-on` and `Queue` filled from what it just did; `Next
   slice`, `Other lane` and `Start it with` are left for the session to
   fill by hand, since deriving them needs the owning plan, not just the
   ledger.

`CLAUDE.md`'s six-step closeout checklist was cut to one paragraph naming
this command; archiving the delivered slice's spec and refilling the queue
stay manual, since `finish` does not touch `plans/now/` or `NEXTSTEPS.md`.

This slice was itself finished with `tools/slice.ps1 finish`, run from
`.worktrees/W-5` -- the first real use of the command.

## Follow-up

W-6 (routing table, `tools/heading.py`) is the next slice in
`plans/now/agent-workflow.md`.
