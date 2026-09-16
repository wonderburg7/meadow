# Archived — Tutorial and Challenges routing snapshot

<!-- CONTEXT: historical-record | LAYER: history -->
Archived: 2026-08-28. Its live boundaries are now in
`plans/archive/CHALLENGE1_2026-09-15.md`. Challenge 1 is playable and Bundles A–G are
delivered. The historical
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
