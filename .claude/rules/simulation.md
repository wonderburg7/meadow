---
paths:
  - "scripts/bee*.gd"
  - "scripts/hive*.gd"
  - "scripts/flower.gd"
  - "scripts/season.gd"
  - "scripts/spatial_grid.gd"
---

# Simulation rules

Full bug catalogue: `docs/known-pitfalls.md`.

**Presentation may be skipped; simulation may not.**
`main.gd.is_on_screen(node)` gates label and colour updates only. Never
gate a decision, a state change or a resource move behind it — bees off
screen must behave identically to bees on screen, or the game changes
depending on where the camera points.

**Role data lives in `roles.gd`, nowhere else.** Every role's id, label,
colour, letter, tooltip and sub-modes are in one table. If you find
yourself typing a role name as a string literal here, stop — read from
`roles.gd` instead. Note the enum in `bee.gd` still uses old internal
names (`Role.BUILDER` is the Comb worker, `Role.NURSERY` is the Nurse);
don't rename it without a good reason, the save format depends on it.

**`GameConfig` is balance numbers, read-only from here.** `Session` is
run/UI state. The test: would a designer tune it to change how the game
plays? Then `GameConfig` (written only by `game_config.gd`,
`debug_panel.gd`, `save_game.gd`, `levels.gd` — see
`.claude/rules/saving.md`). Does it describe *this* run or *this*
player? Then `Session`.

**Coordinate spaces.** `hive_root` and `meadow_root` sit at different
world offsets, so a local `position` matches a global point only by
coincidence in the meadow. Convert once, deliberately, rather than
assuming a coordinate carries over between them.

**Nearest-thing searches picking the thing you're standing on.** A
flower recharges every frame, so the one a bee just drained keeps
winning at distance zero. Any "find the nearest X" needs an exclusion
for whatever the caller just left.

**A refactor can leave a function calling itself** without an obvious
crash — see `bee_status.gd::grounded()`'s history in
`docs/known-pitfalls.md`. Worth a beat of suspicion any time a doc
comment describes two things a function does but only one appears to
happen in the body.

**Two loops that are meant to cover "the same" range can drift apart**
if each computes its own bound instead of sharing a constant — see the
hex-ring navigation bug in `docs/known-pitfalls.md`. Worth checking
`hive.gd`'s navigation build against `world_building.gd`'s dig loops if
either changes.
