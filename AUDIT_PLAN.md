# Technical audit — current contracts

Status: reference | Owner: Dave / Claude Code | Next: measure before any new
hot-path work | Dependency: a named measured bottleneck | Verified: 2026-08-26

The Aug 2026 audit bundles are complete or deliberately measurement-gated. The
full implementation record is archived at
`docs/archive/AUDIT_PLAN_AUG_2026.md`; it is not a session starting point.

## Contracts retained from the audit

- Profile before changing a hot path. Keep the baseline, population and
  measurement window comparable; a lower FPS number alone is not causal
  evidence. See `docs/performance.md` and `docs/PERFORMANCE_BASELINE.md`.
- Restore is all-or-nothing. Do not query deferred-freed groups while a restore
  is rebuilding; follow `.claude/rules/saving.md`.
- `GameConfig` writes remain allowlisted and Challenge-local overrides stay
  on the affected instance.
- Fog changes require identical-tile checks plus a visible moving-bee check.
  The current row-span relight contract is in `docs/PERFORMANCE_BASELINE.md`.

## Deferred work

Fog storage compression, BitMap experiments and new masking approaches are not
planned work. Reopen one only after a fresh comparable profile identifies a
specific bottleneck and the smallest path is written as a new, focused slice.
