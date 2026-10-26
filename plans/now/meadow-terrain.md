# Meadow terrain -- the meadow floor in stacked blocks, then height's effects

<!-- CONTEXT: plan | LAYER: active -->
Status: active | Owner: Dave / Claude Code | Next: SP-8a -- the meadow floor drawn in blocks, with everything on it lifted, gated until the alpha chain (FC-2 landed 17 Oct 2026) has landed -- SG-3 and ED-1 to ED-3 (WP-2 landed 21 Oct 2026, WP-3 22 Oct 2026, SG-2 26 Oct 2026) -- since all of them and SP-8a edit `scripts/main.gd` or the save files (Dave, 16 Oct 2026, product review D3); height's simulation effects are cut after it and wait for AR-4 | Dependency: ED-3 (`plans/now/difficulty.md`), the last of that chain; the block art is exported (`plans/now/sprites.md`, SP-2 and SP-9 landed) | Verified: 2026-10-16

## Objective

Dave drew full and half-height grass and soil blocks (10-11 Oct 2026) and
decided on 12 Oct 2026 that the meadow floor is built from them, with height
as simulation state. This plan builds that floor. It split from
`plans/now/sprites.md` on 15 Oct 2026 (plan review), which keeps the comb
and bee art; the slice ids stay SP-8 and SP-8a.

## Current state

Verified 15 Oct 2026 against master `b5e6751`: the meadow floor is one flat
`Polygon2D` (`world_building.gd::_build_meadow`) and nothing in `scripts/`
names `MeadowTerrain`. SP-8a's "True now" has the detail.

## Open slices

| Slice | What it does | Files it owns | Startable | Level |
| --- | --- | --- | --- | --- |
| SP-8a | the meadow floor drawn in blocks, with everything on it lifted | see its `Files:` line below | no -- after ED-3, the last of the alpha chain SG-3 to ED-3 (WP-2 landed 21 Oct 2026, WP-3 22 Oct 2026, SG-2 26 Oct 2026; Dave, 16 Oct 2026) | high |
| SP-8 (rest) | height's effects: flight cost, where flowers grow, scouting reach | to be cut after SP-8a | no -- after SP-8a and AR-4 (`plans/now/alpha-route-evidence.md`) | high (balance) |

**Dependencies.** SP-8a waits for the alpha chain that followed FC-2 (`plans/archive/crisis-readiness_2026-10-17.md`, landed 17 Oct 2026): WP-2 and WP-3 (`plans/archive/work-priorities_2026-10-22.md`), SG-2 and SG-3 (`plans/now/short-term-goals.md`) and ED-1 to ED-3 (`plans/now/difficulty.md`), in Dave's order, because the closed alpha runs on placeholder art (Dave, 16 Oct 2026, product review D3). Height's simulation effects (SP-8's rest) wait for AR-4 (`plans/now/alpha-route-evidence.md`), so they cannot move balance under PP-6's and T2-7b's price sweeps.
SP-8a and HM-1 (`plans/now/hive-and-menu-art.md`) both edit `scripts/hive.gd`
and `scripts/rival_hive.gd`; both are Claude lane, so whichever lands second
merges master first.

**Reads.** SP-8a reads the SP-8 decisions and its own section below, and
`.claude/rules/performance.md` and `.claude/rules/saving.md`.

**Code health (`plans/now/code-health.md`, 18 Oct 2026).** Its save moves (CQ-S1 to CQ-S5, CQ-R2) wait for this plan's slices that edit `scripts/save_game.gd`/`scripts/saving.gd` (SP-8a); add new save fields the current way, and the round-trip goldens of CQ-S0 are re-captured by whichever slice adds a field.

## SP-8 -- the meadow floor from stacked blocks (not yet cut)

Dave drew full and half-height grass blocks and soil blocks (10-11 Oct
2026), exported as `grass_block`, `grass_block_half`, `soil_block` (four
crumbling stages: 5 whole, 4, 2, 1) and `soil_block_half`.

Decisions (Dave, 12 Oct 2026):

1. **Look.** Grass blocks are not animated. The top layer is a grass block
   whose top face is the floor; flowers grow on it. Blocks stack, full or
   half height; only the top layer has the grass top, and the layers under
   it are soil or half soil blocks. Each block's anchor is the middle of
   its top face; a full block's side is 14 art px and a half block's 7, so
   each block in a stack draws that much higher than the one below.
2. **Height is simulation, not just drawing.** It changes flight cost
   (climbing costs a bee more, downhill less), where flowers grow (species
   favour high or low ground), water and wet ground (low ground collects
   it, high ground dries) and scouting reach (further from high ground).
3. **Shape.** Generated per run (gentle seeded hills and hollows), saved
   with the run.
4. **Range.** A few steps: about -2 to +3 blocks, in half-block steps.
5. **The flat `grass_base` tile goes** once blocks cover the meadow.
6. Meadow blocks are not dug; soil blocks crumble only in the hive (SP-9).

Decisions (Dave, 12 Oct 2026, answering the /run-queue question on how to
cut SP-8):

7. **Grid.** One block per 32-art-px top face (48 world units across),
   heights -2 to +3 blocks in half steps, and a full block lifts what stands
   on it by 14 art px (21 world units).
8. **First cut.** SP-8a draws the height map *and* lifts everything on the
   ground -- flowers, the hive, landed bees, click targets included -- in
   one slice. Height's simulation effects follow as their own slices.

Cut so far: SP-8a, the height map with its drawing and the lift, below.
Still to cut, each its own slice after SP-8a lands: flight cost (balance,
which `GameConfig` owns and which is simulated first), where flowers grow,
and scouting reach. Water in the meadow does not exist yet; that effect
waits for it.

## SP-8a -- the meadow floor drawn in blocks, with everything on it lifted

Level: high (save field, per-bee hot path, click targets). Decisions: SP-8
above, items 1, 3-5 and 7-8. Height has no simulation effect in this slice.

**True now** (verified 12 Oct 2026 against master `01002c2`).

- `world_building.gd::_build_meadow` draws the meadow floor as one flat
  `Polygon2D` of `main.MEADOW_COLOR`, centred on `HIVE_MARKER_POSITION`,
  `FLOWER_FIELD_HALF_SIZE + GRASS_MARGIN` each way (4400 x 3400 world
  units). `grass_base` is in `sprite_catalogue.gd` but nothing draws it.
- `grass_block`, `grass_block_half`, `soil_block` and `soil_block_half` are
  exported and in `sprite_catalogue.gd` (`*_ANCHOR` is the top face's
  middle). The full block's top face is 32 x 16 art px with a 14 art px
  side under it; the half block's side is 7 art px.
- No height exists anywhere: nothing in `scripts/` names `MeadowTerrain`
  or `meadow_heights`. The RAISED obstacles (`obstacle.gd`, plateaus no bee
  may enter) are a separate mechanism and stay as they are.
- The meadow layout comes from the global RNG, seeded in `main.gd`
  (`seed(DEFAULT_RANDOM_SEED)`, or a scenario's `random_seed` in its
  scenario setup);
  flowers are saved (`save_game.gd` `"flowers"`), and obstacles are rebuilt
  from the seed.

**Owner.** Nothing owns meadow height today. A new
`scripts/meadow_terrain.gd` (`class_name MeadowTerrain`) owns it: the
height grid, its generation, `height_at(world_point)` and
`lift_at(world_point)` (world units), and `save_data()`/`restore(data)`.
It is simulation state: later SP-8 slices read the same map for flight cost,
flower placement and scouting reach. Presentation reads `lift_at` and
never writes the map.

**True afterwards.**

- **Grid.** One column per 48 x 24 world units (the 32 x 16 art px top face
  at the meadow's 1.5 world units per art px), covering the area today's
  flat polygon covers. Heights run from -2 to +3 blocks in half-block steps.
  A full block lifts what stands on it by 21 world units (14 art px) and a
  half block by 10.5, so `lift_at` = height x 21. Height 0 draws exactly
  where the flat meadow does today.
- **Generation.** Gentle seeded hills and hollows (a few broad rises and
  dips, not noise per column), made by the terrain's own
  `RandomNumberGenerator`, seeded from the run's random seed, which
  `main.gd` keeps in a field. The global RNG is never drawn from, so for any
  seed the flowers, obstacles and starting foragers are where they are on
  master today. The hive's column, and every column within
  `FLOWER_MIN_DISTANCE` of `HIVE_MARKER_POSITION`, are height 0. The
  steward chose this so that bees go in and out of the entrance on level
  ground; Dave may change it at the hands-on check.
- **Drawing.** The flat polygon goes. Each column draws as a stack: a
  grass block (full or half) on top, and under it the soil blocks needed to
  show its side down to the column in front. It is drawn back to front, so
  a nearer column covers the one behind it. The floor is static: it is
  built once, when the meadow is built and when a save is restored, never
  per frame. It uses batched layers (for example one `TileMapLayer` per
  half-step level, offset by its lift), not a node per block. Record the
  meadow-view frame time before and after in this section
  (`docs/performance.md`).
- **Lifting.** Everything that stands on the ground draws raised by
  `lift_at` of its position, and its children move with it: each flower
  (with its crab-spider marker), the hive, the rival hive, trees and
  plateaus, and every bee that is on the ground or on a flower (load dot,
  rings and speech bubble included). A flying bee's lift eases toward the
  ground under it, over about 0.25 s, so it never jumps at a block edge.
  The lift is a drawing offset only: positions, distances, the spatial
  grids and every simulation result stay what they are on master. Bees work
  out the lift in their existing display update, by one grid lookup, and
  set it only when it changes (`.claude/rules/performance.md`; profile
  before and after).
- **Click targets.** Clicking or drag-selecting compares against where a
  thing is drawn, not its flat position: `input_selection.gd`'s bee, flower,
  obstacle and hive hit tests, and the drag box. A command on open ground
  goes to the column whose drawn top face is under the cursor, checking the
  nearest column first.
- **Save.** `meadow_heights` is an additive field in the save
  (`.claude/rules/saving.md`): an old save without it loads flat, with no
  `FORMAT_VERSION` bump. A checkpoint restore brings back the exact map.
- **Hands-on** (filed at closeout): in a Colony Run's meadow, the floor
  reads as Dave's stacked blocks, with hills up to three blocks high and
  hollows two deep. Flowers, the hive, trees and landed bees sit on their
  block's top face. Clicking a flower or a bee on a hill selects it.

**Must not change.** Flight, foraging, flower placement and scouting
results (the scenario baselines `verify.ps1` runs stay green), the hive
interior, and the RAISED obstacles' blocking.

```queue-gated
**[Claude] SP-8a -- the meadow floor drawn in blocks, with everything on it lifted**
- Plan: `plans/now/meadow-terrain.md` -- "SP-8a -- the meadow floor drawn in blocks, with everything on it lifted"
- Files: `scripts/meadow_terrain.gd`, `scripts/main.gd`, `scripts/world_building.gd`, `scripts/flower.gd`, `scripts/hive.gd`, `scripts/rival_hive.gd`, `scripts/obstacle.gd`, `scripts/bee.gd`, `scripts/input_selection.gd`, `scripts/save_game.gd`, `scripts/saving.gd`, `tests/sp8a_meadow_height_test.gd`, `tests/test_sp8a_meadow_height.py`
- Check: `python -m unittest tests.test_sp8a_meadow_height` passes. It checks that a seeded map lies in -2 to +3 in half steps, that the same seed gives the same map, and that the hive's ground is 0. For the default seed, flower and obstacle positions match master. A flower and a landed bee on a raised column draw lifted by height x 21, and a click at the drawn point selects them. The map survives save and restore, and an old save loads flat. The frame-time comparison is recorded in this section, and `.\tools\verify.ps1` is green.
- Proof: `absent: scripts/world_building.gd :: MeadowTerrain`
- Next after: SP-6 -- meadow foragers drawn from the sheet: eight directions, flapping wings
```
