# Codex guidance -- keep Codex-only instructions executable

<!-- CONTEXT: plan | LAYER: immediate-task -->
Status: active | Owner: Dave / Codex | Next: L-20 -- make Codex's closeout directions agree with `finish` | Dependency: none | Verified: 2026-10-05

## Objective

Keep the Codex-only policy concise and accurate so an implementation session
does not repeat closeout work that the lifecycle already performs.

## Current state

`CHATGPT.md` orders archive and refill before `finish`; the lifecycle contract
says `finish` performs both. No source or queue behaviour is changed here.

## Open slices

| Slice | What it does | Files it owns | Level |
| --- | --- | --- | --- |

L-20 shipped 2026-10-07; its specification is `plans/archive/L-20_2026-10-07.md`.
