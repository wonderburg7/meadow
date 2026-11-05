# Hard soil -- the hive's outer soil needs Mighty Mandible to dig

<!-- CONTEXT: plan | LAYER: immediate-task -->
Status: complete | Owner: Dave / Claude Code | Next: None -- plan complete; HS-1 landed 25 Oct 2026 and HS-2 1 Nov 2026; hard soil and Mighty Mandible are alpha content (product review D3, 5 Nov 2026) | Dependency: none | Verified: 2026-11-05

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

HS-2 needs HS-1's skill id. Neither slice touches `world_building.gd`,
`save_game.gd` or `saving.gd`. A slice reads its own section only.

HS-1 shipped 2026-10-25; its specification is `plans/archive/HS-1_2026-10-25.md`.

HS-2 shipped 2026-11-01; its specification is `plans/archive/HS-2_2026-11-01.md`.
