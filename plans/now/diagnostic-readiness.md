# Diagnostic readiness -- make the colony state behind a player decision explicit

<!-- CONTEXT: plan | LAYER: active -->
Status: active | Owner: Dave / Codex | Next: CD-3 -- waiting and travel diagnostic boundary, after the `scripts/bee.gd` owners land | Dependency: extends `plans/reference/colony-diagnostics.md`; waits for BB-2 (Claude lane) to release `scripts/bee.gd` (BB-1, NF-3 and SP-3 landed 9 Oct 2026); no player-facing copy or balance change | Verified: 2026-10-10

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
| CD-3 | waiting and travel get a deterministic diagnostic boundary | diagnostics, existing bee work dispatch and focused tests | after BB-2 releases `scripts/bee.gd` (BB-1, NF-3 and SP-3 have) | high |

**Must not change.** The one-Hz cadence, existing warning text and severity,
or any simulation, role-assignment or balance rule.

CD-2 shipped 2026-10-09; its specification is `plans/archive/CD-2_2026-10-09.md`.

## CD-3 -- waiting and travel get a deterministic diagnostic boundary

<!-- LAYER: immediate-task -->

Specify and test only the boundary between waiting/travel and no available
work. Dave chose actual work availability on 9 Oct 2026: capture the result
where `bee.gd::_idle_dispatch` / `_try_role_work` already search for work,
then let diagnostics read that result. A bee state alone can mistake an idle
bee with available work for a bee waiting on work. Do not repeat a mutable
work search in diagnostics or add a per-bee scan outside the existing refresh.
`scripts/bee.gd` is owned by BB-2 (`plans/now/bee-bread.md`), in the
Claude lane (BB-1, NF-3 and SP-3 landed 9 Oct 2026); recheck ownership and
the file list after it lands.

```queue-gated
**[Codex] CD-3 -- waiting and travel get a deterministic diagnostic boundary**
- Plan: `plans/now/diagnostic-readiness.md` -- "CD-3 -- waiting and travel get a deterministic diagnostic boundary"
- Files: `scripts/bee.gd`, `scripts/colony_diagnostics.gd`, `scripts/year_winter.gd`, `tests/test_colony_diagnostics.py`
- Check: `python -m unittest tests.test_colony_diagnostics` passes with waiting, travelling and no-work fixtures; `tools/verify.ps1` is green
- Proof: `present: scripts/year_winter.gd :: func _refresh_signals`
- Next after: none -- diagnostic readiness is complete
```

## Not in the queue, and why

- **CD-3** waits for BB-2 (Claude lane) to release `scripts/bee.gd` (BB-1, NF-3 and SP-3 landed 9 Oct 2026); its file list and ownership must be rechecked before admission.
