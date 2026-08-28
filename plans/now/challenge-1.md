# Challenge 1 — current slice

<!-- CONTEXT: plan | LAYER: immediate-task -->
Status: active | Owner: Dave / Claude Code | Next: Bundle H copy and documentation pass | Dependency: selected in `NEXTSTEPS.md` | Verified: 2026-08-28

## Bundle H — copy and current-doc pass

**Scope:** review the new/changed Gallerin lines for a consistent voice;
update current user-facing Challenge 1 and UI-unlock documentation to match
Bundles A–G; regenerate `FUNCTION_MAP.md` only if its indexed scripts changed.
Do not change Challenge mechanics or use this pass to re-open completed
bundles.

**Acceptance:** the tutorial boundary is true in current documentation,
trigger-property terminology is described once, status summaries no longer say
Bundles A–C, and automated documentation checks pass. Add a focused item to
`checks/ready.md` only for behaviour that needs a new hands-on confirmation.

## Current boundary

Challenge 1 now owns the opening through the first worker leaving. Challenge 2
starts after the first worker exists, avoiding duplicated teaching. Shared
infrastructure is `challenge_runner.gd`, `stage_gate.gd`,
`tutorial_checkpoint.gd`, and `gallerin_panel.gd`; do not create
Challenge-specific parallel state. Ordinary save/load stays unavailable during
an active Challenge until a Challenge-aware schema exists.

## Read on demand

- Exact Bundle H checklist and all A–G delivery evidence:
  `plans/archive/CHALLENGE1_REVAMP_PLAN.md` (search `Bundle H`).
- Historical Challenge 1/2 design: `plans/archive/TUTORIAL_PLAN_2026-08-24.md`.
- Current top-bar follow-up: `plans/now/ui.md` (only if the work touches UI
  geometry).
- Current player checks: `checks/ready.md` (search `Challenge 1`).

<!-- LAYER: durable-rules -->

Use bare `unlocked_keys` strings for ordinary stage triggers. Use
`{"key": ..., "trigger": ...}` only when the cause matters to teaching or
future implementation; `stage_gate.gd` remains key-based and the broader
cross-mode resolver belongs to the unscheduled progression design.
