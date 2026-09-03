# Slice tooling — complete, 3 Sep 2026

<!-- CONTEXT: archive | LAYER: history -->
Status: complete | Owner: Dave / Claude Code | Next: None — plan complete | Dependency: none | Verified: 2026-09-03

One slice, S-1, opened and shipped on 3 Sep 2026 (commits 50d531c, dfe2d18,
merged as 2c999eb). Successor to plans/archive/AGENT_WORKFLOW_2026-09-03.md.
Durable rules also recorded in docs/known-pitfalls.md.

## Index

**Objective.** Keep `tools/slice.ps1 finish` correct when it is run the way
`CLAUDE.md` mandates: from inside the slice worktree that the command itself
deletes. `finish` is the only closeout route for both lanes, so a defect in
its tail costs a manual repair on every slice that lands.

**Symptom, as found.** `finish` exited 1 at the end of an otherwise successful
closeout and leaves the ledger row behind. Reproduced closing out W-7 on
3 Sep 2026 and again in a rehearsal repo the same day (see "The W-7 failure",
below). The merge, push and branch delete all succeed; only the tail fails.

**Successor plan.** `plans/now/agent-workflow.md` built `slice.ps1` (W-1..W-7)
and is complete and archived at `plans/archive/AGENT_WORKFLOW_2026-09-03.md`.
An archived plan is never reopened, so this file owns findings against
`slice.ps1` from 3 Sep 2026 onwards.

| Slice | Outcome | Files owned | Startable | Min. reasoning |
| --- | --- | --- | --- | --- |
| S-1 | `finish` survives deleting the worktree it is run from, and actually removes the ledger row. | `tools/slice.ps1` | yes | medium |

No slice here depends on another; S-1 is the only open slice.

**A slice in this plan reads** this file's section and `tools/slice.ps1`, and
nothing else. It does not need any `plans/now/` gameplay plan, the archive, or
Git history.

**Do not change** `Invoke-SliceStart`'s `Push-Location`/`Pop-Location` pair.
That one is correct: `start` pushes from the primary checkout and the
directory it returns to still exists when it pops. Only `Invoke-SliceFinish`
destroys its own starting directory.

<!-- LAYER: durable-rules -->

## Durable rules

1. **A command that deletes a directory must not depend on returning to it.**
   `Push-Location`/`Pop-Location` encodes "go back where we started", which is
   a promise `finish` cannot keep — it deletes where it started. Use
   `Set-Location $root` and let the shell end up somewhere that still exists.
2. **Never `Pop-Location` (or any other throwing statement) in a `finally`
   that wraps destructive work.** An exception raised in `finally` *replaces*
   the exception being propagated, so the real failure is lost and the visible
   error names the cleanup instead. This masked S-1's actual cause for a full
   closeout cycle.
3. **A backtick is the escape character in a PowerShell wildcard.** Markdown
   ledger rows wrap paths in backticks, so `"*``$path``*"` passed to `-like`
   asks for a *literal asterisk* and never matches. Match ledger rows with an
   ordinal substring test (`String.IndexOf(..., StringComparison::Ordinal)`),
   never with `-like`/`-notlike`.
4. **An empty `git commit` is a failure signal, not a no-op.** `git commit`
   exits 1 on "nothing to commit". Any step that commits a computed edit must
   first ask `git diff --cached --quiet` whether there is anything staged, and
   treat "nothing" as benign rather than throwing.

## S-1 — `finish` dies on the worktree it deletes

**The defect, from the player's seat.** An agent finishes a slice, runs
`tools/slice.ps1 finish` from inside its worktree as `CLAUDE.md` instructs,
and watches the merge, the push and the branch delete all succeed. The command
then prints a `Pop-Location` error and exits 1, and the slice's row is still
in `plans/workstreams.md` — which fails `tools/check_docs.py` on master until
somebody removes it by hand.

**The W-7 failure, established by instrumentation.** A rehearsal repo (bare
remote, primary checkout on master, `.worktrees/W-7` on `claude/W-7`, a stub
`verify.ps1`) reproduces it exactly. Tracing every statement of the block that
runs under `Push-Location $root` gives:

```
after git branch -d              LASTEXITCODE=0
after git ls-remote              LASTEXITCODE=0
after push origin --delete gate  LASTEXITCODE=0
ledger read                      LASTEXITCODE=0
ledger written                   LASTEXITCODE=0
git add staged                   LASTEXITCODE=0
ledger commit done               LASTEXITCODE=1   <-- the real failure
Pop-Location : Cannot find path '...\.worktrees\W-7' because it does not exist.
```

So there are two independent defects, and the second hides the first:

- **The ledger row is never matched.** The filter
  `$_ -notlike "*``$worktreeRelative``*"` builds the wildcard
  `` *`.worktrees/W-7`* ``, whose trailing `` `* `` is an *escaped asterisk*
  — it demands a literal `*` in the line. No row has one, so nothing is
  filtered, `Set-Content` rewrites the file byte-identical, `git add` stages
  nothing, and `git commit` exits 1 with "nothing to commit". Verified
  against the real `plans/workstreams.md`: 62 lines in, 62 lines kept, 0
  removed. The escape semantics, minimally: `'a*b' -like 'a`*b'` is True and
  `'axxb' -like 'a`*b'` is False.
- **`Pop-Location` throws over the top of it.** `Push-Location $root` leaves
  the worktree path on the location stack; the block then deletes that
  worktree, so the `finally`'s `Pop-Location` cannot find it. Because it
  throws inside `finally`, it replaces the "git commit failed" exception, and
  the run reports the cleanup error while the true cause disappears.

**Does.** In `Invoke-SliceFinish` only:

1. Replaces `Push-Location $root` / `try { … } finally { Pop-Location }` with
   a plain `Set-Location -LiteralPath $root` before the destructive work, so
   nothing depends on a directory the run itself invalidates and a real
   failure propagates unmasked.
2. Replaces the wildcard row filter with an ordinal substring match on
   `` `<worktree path>` ``, and says so when no row matched rather than
   silently rewriting the file unchanged.
3. Guards the ledger commit and push with `git diff --cached --quiet`, so an
   already-clean ledger ends the run successfully instead of throwing.

Nothing outside `Invoke-SliceFinish` changes; `Invoke-SliceStart` keeps its
(correct) `Push-Location` pair.

**Acceptance.** Running `tools/slice.ps1 finish` from inside a slice worktree
merges, pushes, deletes the branch, removes that slice's row from
`plans/workstreams.md`, commits and pushes that removal, prints the
end-of-slice report and exits 0 — with the worktree gone and no error.

**Check.** `tools/verify.ps1`, plus an end-to-end rehearsal in a throwaway
repo (bare remote + primary checkout + worktree) which must exit 0 and show
the ledger row gone. No hands-on check for Dave: `finish` is agent-run
closeout tooling with no player-visible surface, and the rehearsal exercises
the whole path including the two failure modes above.

<!-- LAYER: on-demand -->

## Read on demand

- `tools/slice.ps1` — `Invoke-SliceFinish` only.
- `plans/archive/AGENT_WORKFLOW_2026-09-03.md` — provenance for why `finish`
  is shaped the way it is. Search only; do not reopen or extend it.

## Outcome

Shipped as specified: `Set-Location -LiteralPath $root` replaces the
Push/Pop pair, the ledger row is matched with an ordinal `String.IndexOf`,
and the ledger commit is guarded by `git diff --cached --quiet`.
`Invoke-SliceStart`'s Push/Pop pair was left alone.

Validation: `tools/verify.ps1` green; end-to-end rehearsal in a throwaway
repo exits 0 with the row removed, the removal commit pushed, and the
worktree and branch gone locally and on the remote; the already-clean-ledger
path exercised separately also exits 0.

No follow-ups open. No `checks/ready.md` entry: `finish` is agent-run
closeout tooling with no player-visible surface.
