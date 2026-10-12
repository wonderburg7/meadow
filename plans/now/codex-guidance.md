# Codex guidance -- keep Codex-only instructions executable

<!-- CONTEXT: plan | LAYER: immediate-task -->
Status: active | Owner: Dave / Codex | Next: L-25 -- verify and prefinish refuse to check a different checkout (found closing CD-3, 12 Oct 2026; L-20 shipped 7 Oct 2026) | Dependency: none | Verified: 2026-10-12

## Objective

Keep the Codex-only policy concise and accurate so an implementation session
does not repeat closeout work that the lifecycle already performs.

## Current state

`CHATGPT.md` orders archive and refill before `finish`; the lifecycle contract
says `finish` performs both. No source or queue behaviour is changed here.

Sandbox probe, decided by Dave 7 Oct 2026: Codex's sandbox configuration
stays as it is. `codex sandbox -P meadow` now launches (the 5 Oct review's F3
blocker no longer reproduces). A probe that runs Python passes
`-c 'windows.sandbox="unelevated"'`; the recipe and why are in
`docs/known-pitfalls.md`.

## Open slices

| Slice | What it does | Files it owns | Level |
| --- | --- | --- | --- |
| L-25 | verify and prefinish refuse to check a different checkout | `tools/verify.ps1`, `tools/prefinish.py`, `tests/test_wrong_checkout_guard.py` | medium |

L-20 shipped 2026-10-07; its specification is `plans/archive/L-20_2026-10-07.md`.

## L-25 -- verify and prefinish refuse to check a different checkout

<!-- LAYER: immediate-task -->

Found closing CD-3 on 12 Oct 2026. Codex ran the primary checkout's `tools/verify.ps1` and
`tools/prefinish.py`, by relative path, from `.worktrees/CD-3`. Both resolve their
repository root from their own location, so they checked the primary
checkout, not the branch: verify failed on Dave's uncommitted sprite files
(`tests.test_sp2_sprites`), and prefinish passed without seeing CD-3 at all.

When the current directory is inside a git checkout whose top level differs
from the script's own root, each script stops before running anything. The
message names both paths and the command to run instead (`.\tools\verify.ps1`
or `python tools/prefinish.py` from the worktree). Run from the script's own
checkout, or from outside any checkout, behaviour is unchanged. `finish` and
the lifecycle tests call these scripts by absolute path from the right
worktree, so they must keep passing untouched.

```queue
**[Codex] L-25 -- verify and prefinish refuse to check a different checkout**
- Plan: `plans/now/codex-guidance.md` -- "L-25 -- verify and prefinish refuse to check a different checkout"
- Files: `tools/verify.ps1`, `tools/prefinish.py`, `tests/test_wrong_checkout_guard.py`
- Check: `python -m unittest tests.test_wrong_checkout_guard` passes, showing both scripts refuse when run from another worktree and run normally from their own; `tools/verify.ps1` is green
- Proof: `absent: tools/prefinish.py :: different checkout`
- Next after: none -- Codex guidance is complete
```
