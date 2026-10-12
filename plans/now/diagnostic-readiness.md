# Diagnostic readiness -- make the colony state behind a player decision explicit

<!-- CONTEXT: plan | LAYER: active -->
Status: complete | Owner: Dave / Codex | Next: None — plan complete; CD-3 reviewed and merged 12 Oct 2026, no follow-ups filed | Dependency: extends `plans/reference/colony-diagnostics.md`; no player-facing copy or balance change | Verified: 2026-10-12

## Objective

Give the later guidance and crisis work a small, shared vocabulary for why the
colony cannot progress. Facts are derived at the existing one-Hz refresh; the
HUD and warning policy remain consumers, not owners.

## Current state

`ColonyDiagnostics.compute` records energy, role and cell facts. The product
scope also requires missing-workforce, blocked-work, waiting and travel
diagnostics, but none has a named data contract.

## Open slices

| Slice | What it does | Files it owns | Startable | Level |
| --- | --- | --- | --- | --- |

**Must not change.** The one-Hz cadence, existing warning text and severity,
or any simulation, role-assignment or balance rule.

CD-2 shipped 2026-10-09; its specification is `plans/archive/CD-2_2026-10-09.md`.

CD-3 shipped 2026-10-12; its specification is `plans/archive/CD-3_2026-10-12.md`.

## Not in the queue, and why

- None: CD-3's gate cleared when BB-2 landed (10 Oct 2026).
