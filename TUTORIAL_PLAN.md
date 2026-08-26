# Tutorial and Challenges — current plan

Status: active design reference | Owner: Dave / Claude Code | Next: continue
Challenge 1 only when explicitly selected | Dependency: Challenge 1 revamp
sequence | Verified: 2026-08-26

Challenge 1 is playable; its revamp has delivered Bundles A-C. The historical
Challenge 1/2 design and delivered mechanics are preserved in
`docs/archive/TUTORIAL_PLAN_2026-08-24.md`.

## Current boundaries

- `CHALLENGE1_REVAMP_PLAN.md` owns the remaining Challenge 1 sequence.
  It must keep each bundle playable and checkpointed.
- Challenge 2 begins after the first worker exists once Challenge 1’s revised
  opening proves that hand-off. Its old opening is not to be duplicated.
- `challenge_runner.gd`, `stage_gate.gd`, `tutorial_checkpoint.gd` and
  `gallerin_panel.gd` are shared Challenge infrastructure. Reuse them rather
  than creating Challenge-specific parallel state.
- Ordinary save/load remains disabled during an active Challenge until a
  dedicated Challenge-aware save format exists.

## Validation

Every tutorial slice needs deterministic checks, a Godot boot and a hands-on
playthrough of the teaching sequence. Record concrete visual/timing checks in
`HANDS_ON_CHECKS.md`; do not represent an unplayed sequence as confirmed.
