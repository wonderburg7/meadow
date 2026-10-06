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
| L-20 | make Codex's closeout directions agree with what `finish` does | `CHATGPT.md` | low |

## L-20 -- make Codex's closeout directions agree with what `finish` does

<!-- LAYER: immediate-task -->

Level: low (one policy sentence and a documentation check).

**True now** (verified 5 Oct 2026). `CHATGPT.md` tells Codex to run
`archive_slice.py` and `refill_lane.py` before `finish`, while
`plans/reference/closeout.md` says `finish` performs those actions itself.

**True afterwards.** `CHATGPT.md` directs Codex to update the plan and
successor before `finish`, then lets `finish` archive and refill; it retains
the existing risk-tier and end-of-slice-report rules.

**Must not change.** Lane ownership, queue floor, risk tiers, or Claude's
instructions. Stop and escalate if `tools/slice.ps1 finish` no longer matches
`plans/reference/closeout.md`.

```queue
**[Codex] L-20 -- make Codex's closeout directions agree with what `finish` does**
- Plan: `plans/now/codex-guidance.md` -- "L-20 -- make Codex's closeout directions agree with what `finish` does"
- Files: `CHATGPT.md`
- Check: `python tools/check_docs.py` passes, and `CHATGPT.md` says `finish` performs archive and refill rather than ordering them before `finish`
- Proof: `present: CHATGPT.md :: run both, for your own lane only, **before** running`
- Next after: none -- L-20 completes this plan
```
