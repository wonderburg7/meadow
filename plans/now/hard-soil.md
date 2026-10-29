# Hard soil -- the hive's outer soil needs Mighty Mandible to dig

<!-- CONTEXT: plan | LAYER: immediate-task -->
Status: active | Owner: Dave / Claude Code | Next: HS-2 -- its temporary deferral is over; RR-17 landed 29 Oct 2026, releasing `scripts/bee.gd` | Dependency: none left; HS-1, DR-1 and CQ-S0b landed 25 Oct 2026; PP-6 and FR-3 also edit `scripts/skills.gd` later | Verified: 2026-10-29

## Objective

Dave (24 Oct 2026): stonier, slightly greyer soil blocks replace ordinary
soil from roughly halfway between the cavity and the bedrock outwards, in a
rough (not exact) hexagon. Miners can dig them only once a skill is owned.

## Decisions (Dave, 24 Oct 2026)

1. Every soil block past the rough halfway line is hard, out to the bedrock
   -- not a band.
2. Once the skill is owned, a hard block takes 2.5 times a normal block's
   miner-time.
3. The skill is **Mighty Mandible**, `skill.colony.mighty_mandible`: Colony
   sector, one tier above Miner, requires Miner.
4. Hard soil appears in every mode, Challenge stages included. Where a run
   has no progression (`Session.progression == null`) skills count as owned,
   so there hard soil is only slower.
5. (Planning session, flagged to Dave at approval.) Hardness is a pure
   function of a block's hex and `GameConfig`, worked out when the block is
   set up and never saved. No save field, no format bump: an old save
   reloads with hard soil in the outer half it has not dug yet.

## Current state

Verified 24 Oct 2026 against master `248da728`.

- One soil type: `scripts/soil_block.gd` (`SOIL_COLOR`, `setup(hex)`,
  `set_marked`, `effective_mine_time`, `_tint`, `_refresh_art`). Its only
  creator is `world_building.gd::_add_soil_block`, which calls `setup`, for
  both a new hive and a save restore.
- Default geometry (`GameConfig`): `hive_interior_rings = 6`,
  `hive_soil_depth = 12`, then `hive_rock_rings = 2` of unminable
  `RockBlock` (`ROCK_COLOR` 0.28, 0.28, 0.32). Soil spans rings 6 to 18.
- Digging routes: the player marks blocks (`set_marked`); a direct miner
  order calls `bee.gd::set_mine_target` / `queue_mine_target`, which mark
  the block and queue it; automine asks `hive.gd::find_nearest_edge_block`,
  which filters on `_is_markable_block`.
- `Skills.MINER` is tier 2 at `Vector2i(1, -5)`; tier 3 sits on ring 7.

## Open slices

| Slice | Outcome | Files | Startable | Level |
| --- | --- | --- | --- | --- |
| HS-2 | Hard soil generated, greyer, 2.5x slower, gated on Mighty Mandible | `scripts/soil_block.gd`, `scripts/hive.gd`, `scripts/bee.gd`, `scripts/game_config.gd`, `scripts/settings_catalogue.gd`, `test_scenarios/hs2_hard_soil.json`, `tests/test_hs2_hard_soil.py` | yes -- HS-1, DR-1 and CQ-S0b landed 25 Oct 2026 | medium |

HS-2 needs HS-1's skill id. Neither slice touches `world_building.gd`,
`save_game.gd` or `saving.gd`. A slice reads its own section only.

HS-1 shipped 2026-10-25; its specification is `plans/archive/HS-1_2026-10-25.md`.

## HS-2 -- hard soil fills the outer half of the hive's soil

Level: medium.

**Gate:** none left: HS-1, DR-1 (`plans/now/drones.md`, which owned
`scripts/hive.gd`) and CQ-S0b (`plans/now/code-health.md`, which owned
`scripts/bee.gd`) all landed 25 Oct 2026.

**Build.**
1. `scripts/game_config.gd`, beside `block_mine_time`, with a settings row
   each in `scripts/settings_catalogue.gd` next to `hive_soil_depth`'s (read
   that file's header comment first): `hard_soil_start_fraction: float = 0.5`
   (how far into the soil band hard soil begins) and
   `hard_soil_mine_time_multiplier: float = 2.5`.
2. `scripts/soil_block.gd` constants (structural): `HARD_SOIL_COLOR :=
   Color(0.355, 0.314, 0.258)` (OKLab 0.083 from `SOIL_COLOR`, 0.054 from
   `ROCK_COLOR`), `HARD_SOIL_SPRITE_TINT := Color(0.86, 0.88, 0.95)`, and
   `HARD_SOIL_WOBBLE := 0.15` (edge wobble as a fraction of soil depth).
3. `var is_hard := false`, and these statics:
   ```gdscript
   ## HS-2. The ring at which hard soil starts along this hex's bearing: about
   ## halfway through the soil band, wobbling smoothly with the angle so the
   ## edge is a rough hexagon, with odd tiles notched out.
   static func hard_soil_start_ring(hex: Vector2i) -> int:
   	var interior: int = GameConfig.hive_interior_rings
   	var depth: int = GameConfig.hive_soil_depth
   	var base: int = interior + roundi(depth * GameConfig.hard_soil_start_fraction)
   	var bearing: float = atan2(hex.y * 0.866, hex.x + hex.y * 0.5)
   	var wobble: float = depth * HARD_SOIL_WOBBLE * (0.6 * sin(5.0 * bearing + 1.3) + 0.4 * sin(11.0 * bearing + 0.4))
   	var notch: int = 1 if absf(sin(float(hex.x) * 12.9898 + float(hex.y) * 78.233)) > 0.85 else 0
   	return clampi(base + roundi(wobble) + notch, interior + 2, interior + depth)

   static func is_hard_at(hex: Vector2i) -> bool:
   	return Shapes.hex_ring_index(hex) >= hard_soil_start_ring(hex)

   static func hard_soil_unlocked() -> bool:
   	return Session.progression == null or Session.progression.is_owned(Skills.MIGHTY_MANDIBLE)

   func can_be_dug() -> bool:
   	return not is_hard or hard_soil_unlocked()
   ```
   At the defaults the start ring runs from 10 to 15 around ring 12; the clamp
   keeps the first two soil rings soft and the outermost always hard.
4. `setup(hex)`: set `is_hard = is_hard_at(hex)`; when hard, set
   `soil_sprite.modulate = HARD_SOIL_SPRITE_TINT` and call `_tint()` so the
   flat look starts grey too (`setup` runs after `_ready`).
5. `_tint()`: lerp from `HARD_SOIL_COLOR if is_hard else SOIL_COLOR`.
6. `set_marked(value)`: return before changing anything when `value` is true
   and `not can_be_dug()`. This covers the player's marking.
7. `effective_mine_time()`: multiply its current result (override included)
   by `GameConfig.hard_soil_mine_time_multiplier` when `is_hard`.
8. `scripts/hive.gd::_is_markable_block`: add `and node.can_be_dug()`, so
   automine never picks a locked hard block.
9. `scripts/bee.gd::set_mine_target` and `queue_mine_target`: treat a block
   that `not can_be_dug()` like an invalid one (no queue entry, no mark).
10. `test_scenarios/hs2_hard_soil.json`, modelled on
    `test_scenarios/t3_2_restocking_gate.json` (which uses `grant_skill`):
    `set_config` `hard_soil_start_fraction` to 0.0 so the clamp puts hard soil
    at ring `interior + 2`, next to the cavity; `grant_skill`
    `skill.colony.miner` if the run does not own it, then hatch a Miner; `queue_mine` a
    soft block on ring `interior` (accepted) and a hard block on ring
    `interior + 2` (rejected); `grant_skill` `skill.colony.mighty_mandible`;
    `queue_mine` the same hard block again (accepted). Its `expect` allows
    exactly that one rejection rather than `actions_clean`. It doubles as the
    hands-on skip save.
11. `tests/test_hs2_hard_soil.py`: runs the scenario as
    `tests/test_t3_2_restocking_gate.py` does; asserts the OKLab distances
    (copy the helper style of `tests/test_sp3_content_colours.py`):
    `HARD_SOIL_COLOR` at least 0.06 from `SOIL_COLOR` and 0.05 from
    `ROCK_COLOR`; and mirrors `hard_soil_start_ring` in Python (a comment
    names the GDScript function) to assert, at the defaults, that every start
    ring lies in 8 to 18, ring 18 is always hard, ring 9 is never hard, and
    at least three different start rings occur (the edge is rough).

**True afterwards.**
- A new hive has a rough hexagonal line of greyer soil about halfway out,
  and everything beyond it up to the bedrock is hard.
- Without Mighty Mandible a hard block cannot be marked, ordered or
  automined; with it, it digs at 2.5x the miner-time.
- Runtime: hardness is worked out once per block in `setup`; automine's scan
  gains one bool per candidate; nothing new per frame.

**Must not change.** The cavity shape (`world_building.gd::_is_open_tile`),
rock blocks, routing (`hive.gd::_is_solid` -- hard soil is still a
`SoilBlock`), and the save format. Challenge 2.8 (raise a Miner, dig new
space and build a cell in it; `docs/challenge-stages.md`) must still pass: its
digging happens in the soft inner rings.

**Open decisions:** none.

```queue
**[Claude] HS-2 -- hard soil fills the outer half of the hive's soil**
- Plan: `plans/now/hard-soil.md` -- "HS-2 -- hard soil fills the outer half of the hive's soil"
- Files: `scripts/soil_block.gd`, `scripts/hive.gd`, `scripts/bee.gd`, `scripts/game_config.gd`, `scripts/settings_catalogue.gd`, `test_scenarios/hs2_hard_soil.json`, `tests/test_hs2_hard_soil.py`
- Check: `python -m unittest tests.test_hs2_hard_soil` passes, asserting a hard block refuses a dig order before Mighty Mandible and accepts one after, the hard-soil colour distances, and the rough halfway edge; `.\tools\verify.ps1` is green. Hands-on: in the HS-2 scenario, the hard soil next to the cavity looks greyer than ordinary soil and different from the bedrock, and clicking it to dig does nothing until Mighty Mandible is bought.
- Proof: `absent: scripts/soil_block.gd :: func hard_soil_start_ring(`
- Next after: none -- `plans/now/hard-soil.md` is complete
```
