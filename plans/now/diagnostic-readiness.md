# Diagnostic readiness -- make the colony state behind a player decision explicit

<!-- CONTEXT: plan | LAYER: active -->
Status: active | Owner: Dave / Codex | Next: CD-3 -- waiting and travel diagnostic boundary | Dependency: extends `plans/reference/colony-diagnostics.md`; no player-facing copy or balance change | Verified: 2026-10-09

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
| CD-2 | missing workforce and blocked work become named, tested facts | `scripts/colony_diagnostics.gd`, `scripts/year_winter.gd`, `tests/test_colony_diagnostics.py` | yes | medium |
| CD-3 | waiting and travel get a deterministic diagnostic boundary | same diagnostics files and focused tests | yes | medium |

**Must not change.** The one-Hz cadence, existing warning text and severity,
or any simulation, role-assignment or balance rule.

## CD-2 -- missing workforce and blocked work become named, tested facts

<!-- LAYER: immediate-task -->

**True now.** `year_winter.gd` computes role facts and lets
`problem_messages.gd` infer a few warnings, but there is no reusable answer
to whether work is blocked because its workforce is absent.

**True afterwards.** `ColonyDiagnostics` returns documented, non-negative
facts for a missing required workforce and blocked cells/work, and
`year_winter.gd` passes them through its existing one-Hz snapshot. Focused
tests cover empty and populated colonies without adding UI copy.

```queue
**[Codex] CD-2 -- missing workforce and blocked work become named, tested facts**
- Plan: `plans/now/diagnostic-readiness.md` -- "CD-2 -- missing workforce and blocked work become named, tested facts"
- Files: `scripts/colony_diagnostics.gd`, `scripts/year_winter.gd`, `tests/test_colony_diagnostics.py`
- Check: `python -m unittest tests.test_colony_diagnostics` passes with empty, staffed and blocked-cell fixtures; `tools/verify.ps1` is green
- Proof: `present: scripts/colony_diagnostics.gd :: static func compute`
- Next after: CD-3 -- waiting and travel get a deterministic diagnostic boundary
```

## CD-3 -- waiting and travel get a deterministic diagnostic boundary

<!-- LAYER: immediate-task -->

Specify and test only the boundary between waiting/travel and no available
work. It must reuse CD-2 facts and must not add a per-bee scan outside the
existing refresh.

```queue
**[Codex] CD-3 -- waiting and travel get a deterministic diagnostic boundary**
- Plan: `plans/now/diagnostic-readiness.md` -- "CD-3 -- waiting and travel get a deterministic diagnostic boundary"
- Files: `scripts/colony_diagnostics.gd`, `scripts/year_winter.gd`, `tests/test_colony_diagnostics.py`
- Check: `python -m unittest tests.test_colony_diagnostics` passes with waiting, travelling and no-work fixtures; `tools/verify.ps1` is green
- Proof: `present: scripts/year_winter.gd :: func _refresh_signals`
- Next after: none -- diagnostic readiness is complete
```
