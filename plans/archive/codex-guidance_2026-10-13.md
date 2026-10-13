# Codex guidance -- keep Codex-only instructions executable

<!-- CONTEXT: plan | LAYER: immediate-task -->
Status: complete | Owner: Dave / Codex | Next: None — plan complete (L-25 closed 13 Oct 2026; L-20 shipped 7 Oct 2026) | Dependency: none | Verified: 2026-10-13

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

L-20 shipped 2026-10-07; its specification is `plans/archive/L-20_2026-10-07.md`.

L-25 shipped 2026-10-13; its specification is `plans/archive/L-25_2026-10-13.md`.
