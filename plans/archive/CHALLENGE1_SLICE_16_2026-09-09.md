# Challenge 1 — Slice 16, delivered 9 September 2026

Extracted from `plans/archive/CHALLENGE1_2026-09-15.md` on landing. See that file for the
plan's current state and open slices (17-19, then 7).

## Slice 16 — the queen works more than one flower at 1.11 — DONE 9 Sep 2026

**Reasoning level: low.** Delete one stage effect and its counterpart.

**What Dave reported.** At 1.11, "automate nectar gathering", the queen works
one flower, flies home, deposits, and goes straight back to the *same*
flower, for the whole stage.

**Cause.** `scripts/challenge_stages.gd`, stage `1.11`, carries
`"on_enter": ["lock_flower_target:queen"]`. That effect sets
`Bee.flower_switch_locked`, and every autonomous transition in
`scripts/bee_foraging.gd` that would otherwise pick a new flower reads it:
lines 454, 485, 636 and 717 all send her to `State.TO_HIVE` instead of
`State.SEEK_FLOWER` while it is set. The lock is right for the manual arc
(1.8 to 1.10), where the player picks each flower; it is exactly wrong for
the stage whose whole point is that she now chooses for herself.

**Delivered, in `scripts/challenge_stages.gd`.**

- Removed `"on_enter": ["lock_flower_target:queen"]` from stage `1.11`.
- Removed `"unlock_flower_target:queen"` from stage `1.11`'s `on_exit`,
  leaving the other three effects in place and in their current order.
- Left the `lock_flower_target:queen` and `unlock_flower_target:queen` cases
  in `challenge_runner.gd::_run_stage_effects()`. They are still the
  documented mechanism, and `_run_stage_effects` pushes an error for an
  unknown effect, so a later stage can use them without re-adding code.

`flower_switch_locked` itself was not touched. No other stage sets it, and
the field is what a future "work this one flower" order would use.

**Acceptance.** At 1.11 the queen fills up at one flower, flies home,
deposits, and then flies to a *different* flower, repeating until the nectar
cell is full. The same for pollen once Slice 17 lands.

**Check:** covered by C-7's rewritten first condition, in `checks/ready.md`.
C-7 as a whole stays open -- its `Owner:` line names Slice 18, since the
pollen-stage half of the acceptance still needs Slices 17-19.

**Landed:** commit `55ca47f` on `claude/C1-16`, merged to `master` at
`e29038f`.
