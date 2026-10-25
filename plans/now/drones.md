# Drones -- a mated queen lays drones in cells the player marks

<!-- CONTEXT: plan | LAYER: immediate-task -->
Status: active | Owner: Dave / Claude Code | Next: DR-2 -- the cell popup's drone box (Claude lane; DR-1 landed 25 Oct 2026) | Dependency: none left -- DR-1 has landed and CQ-R7 (`plans/now/code-health.md`) released `scripts/hud.gd` 22 Oct 2026 | Verified: 2026-10-25

## Objective

Real queens choose to lay drone eggs. In Meadow today a queen lays drones only
while she is unmated (COL-9 to COL-11). Dave wants the player to be able to have
a mated queen lay drones too. This plan adds a per-cell "drone cell" mark, like
the gyne mark. It also gives the CQ-S0 round-trip harness the drones its mid
golden lacks.

## Decisions (Dave, 22 Oct 2026)

1. "Bee queens can selectively lay drone eggs, so there should still be an
   option for mated queens to produce drones." The player chooses. It is a
   cell mark set from the cell popup, and the queen does not decide on her own.
2. **No skill.** The toggle is there from the start of a run. This supersedes
   the `skill.brood.drones` row of `plans/design/progression.md` §5.2 (a
   tier-4 skill needing Royal jelly to unlock "drone designation and drone
   bees"). That row now points here.

**What the slices settle without a new decision.** A drone egg costs what a
worker egg costs, as an unmated queen's does today (COL-9). A drone is Idle and
ages out as a worker, as he does today. A cell carries at most one mark: marking
it for a drone clears its gyne mark, and marking it for a gyne clears its drone
mark. An unmated queen still lays only drones, whatever a cell asks for.

## Current state

Verified 22 Oct 2026 against master `7398865`.

- `bee_egg_laying.gd::queen_lay`: `as_drone` is `not bee.is_mated`, and
  `as_gyne` is `hatch_gyne and not as_drone`. `pollen_needed_for_next_egg`
  prices a gyne egg only for a mated queen.
- `hive_cell.gd`: `hatch_gyne` and `priority_cell` are cell settings. They are
  set from the cell popup, outlast the larva and are saved. A larva's caste is
  in `brood_is_drone`/`brood_is_gyne`, also saved. Nothing records a drone mark.
- `hive.gd::find_empty_cell` counts a cell with `hatch_role >= 0` or
  `hatch_gyne` as configured. The free-cell readout keys a gyne cell as
  `"gyne"`.
- `orders_zones.gd::_on_cell_gyne_requested` sets the gyne mark on the
  selected cells, after checking Gyne rearing, and reserves them for brood.
  `nursery_panel.gd::colour_for`/`tag_for` draw the mark.
- Saves already carry a bee's `drone` and a cell's brood `drone`
  (`save_game.gd`, `saving.gd`, additive since COL-9).
- No scenario action can mark a cell for a gyne or a drone. The CQ-S0 mid
  golden (`tests/fixtures/saves/cq_s0_mid.json`, captured by
  `test_scenarios/cq_s0_mid_capture.json`) has no drones. The module docstring
  of `tests/test_save_roundtrip.py` says so and points here ("The mid golden
  has no drones yet ... recaptured with drones once it lands").
  `tests/col9_drones_test.gd` round-trips the drone fields meanwhile.

## Open slices

| Slice | What it does | Files it owns | Startable | Level |
| --- | --- | --- | --- | --- |
| DR-1 | a mated queen lays drones in cells marked for them; saved; goldens re-captured | see its `Files:` line | yes | high (save field, simulation, golden re-capture) |
| DR-2 | the cell popup's drone box | `scripts/hud.gd`, `scripts/main.gd`, `scripts/nursery_panel.gd`, `scripts/orders_zones.gd` | yes -- DR-1 landed 25 Oct 2026 | medium |

**Dependencies.** DR-1 edits `scripts/save_game.gd` and `scripts/saving.gd`.
SG-2 (`plans/now/short-term-goals.md`), ED-1 and ED-2 (`plans/now/difficulty.md`)
and CQ-S0b (`plans/now/code-health.md`) edit them too. All are Claude lane, so
they run one at a time in queue order, and each re-captures the CQ-S0 goldens
it changes. The save moves CQ-S1 to CQ-S5 and CQ-R2 (`plans/now/code-health.md`)
wait for DR-1, as for the alpha chain's save slices. DR-2 waited also for CQ-R7, the
Claude slice that reshaped the cell popup in `scripts/hud.gd`; it landed 22 Oct 2026.

## DR-1 -- a mated queen lays drones in cells marked for them, saved

Level: high.

**True now.** See "Current state". A mated queen cannot lay a drone.

**When done:**

1. `hive_cell.gd` has `hatch_drone: bool`, a cell setting like `hatch_gyne`.
   It outlasts the larva and is cleared by `hatch_gyne` being set (and the
   reverse).
2. `bee_egg_laying.gd::queen_lay` lays a drone when the queen is unmated *or*
   the cell is marked for a drone. A drone egg costs `egg_pollen_cost`.
   `pollen_needed_for_next_egg` never asks gyne pollen for a drone-marked cell.
3. `hive.gd::find_empty_cell` treats a drone-marked cell as configured, as it
   does a gyne cell. The free-cell readout keys it `"drone"`.
4. `orders_zones.gd` gains `_on_cell_drone_requested(anchor, as_drone)`, the
   gyne handler's twin without a skill check: it marks the selected cells and
   reserves them for brood. DR-2 connects the popup to it.
5. A scenario action `mark_drone_cell` (`{"do": "mark_drone_cell", "hex": [q, r]}`)
   in `scripts/scenario_actions.gd` calls that handler and logs accepted or
   rejected like `designate_cell`.
6. The mark is saved as the cell's `hatch_drone`. The key is additive (false in
   an older save) with no `FORMAT_VERSION` bump, per `.claude/rules/saving.md`.
7. `test_scenarios/cq_s0_mid_capture.json` marks a drone cell early enough that
   its save holds an emerged drone (`drone: true` on a bee) and a drone larva
   (`drone: true` on a brood cell). If none can emerge by day 4, it marks a
   cell sooner rather than lengthening the run, and the commit says what it
   changed. Every CQ-S0 golden that gains `hatch_drone` is re-captured on the
   branch, as the goldens' capture route says. The "no drones yet" passage in
   `tests/test_save_roundtrip.py`'s docstring is replaced by a line saying the
   mid golden carries a drone and a drone larva.
8. `tests/dr1_drone_cells_test.gd` (run by `tests/test_dr1_drone_cells.py`)
   checks four things. A mated queen lays a drone in a marked cell and a worker
   in an unmarked one. Marking a gyne cell for a drone clears its gyne mark. An
   unmated queen still lays a drone in a gyne-marked cell. The mark survives a
   save and load.

**Invariants.** An unmarked cell under a mated queen raises exactly what it does
today. Egg-laying runs on the queen's lay events only: no per-frame work is
added. A balance value is not introduced, because a drone egg reuses
`egg_pollen_cost`.

```queue
**[Claude] DR-1 -- a mated queen lays drones in cells marked for them, saved**
- Plan: `plans/now/drones.md` -- "DR-1 -- a mated queen lays drones in cells marked for them, saved"
- Files: `scripts/hive_cell.gd`, `scripts/bee_egg_laying.gd`, `scripts/hive.gd`, `scripts/orders_zones.gd`, `scripts/scenario_actions.gd`, `scripts/save_game.gd`, `scripts/saving.gd`, `test_scenarios/cq_s0_mid_capture.json`, `tests/fixtures/saves/cq_s0_early.json`, `tests/fixtures/saves/cq_s0_mid.json`, `tests/fixtures/saves/cq_s0_winter.json`, `tests/fixtures/saves/cq_s0_challenge2.json`, `tests/fixtures/saves/cq_s0_orientation.json`, `tests/test_save_roundtrip.py`, `tests/dr1_drone_cells_test.gd`, `tests/test_dr1_drone_cells.py`
- Check: `python -m unittest tests.test_dr1_drone_cells` passes (a mated queen lays a drone in a marked cell and a worker in an unmarked one; the gyne and drone marks clear each other; an unmated queen still lays drones; the mark survives a save and load); `python -m unittest tests.test_save_roundtrip` passes on the re-captured goldens, and `tests/fixtures/saves/cq_s0_mid.json` holds a bee and a brood cell with `"drone": true`; `tests/test_save_migrations.py` passes; `.\tools\verify.ps1` is green
- Proof: `absent: scripts/hive_cell.gd :: hatch_drone`
- Next after: DR-2 -- the cell popup's drone box
```

## DR-2 -- the cell popup's drone box

Level: medium.

**True now.** After DR-1 a drone mark exists, but only a scenario can set it.
The cell popup in `hud.gd` has the "Raise a gyne (a future queen)" box
(`gyne_box`, signal `cell_gyne_requested`, connected in `main.gd`) and the
"Feed first" box.

**When done:**

1. The cell popup has a "Raise a drone (a male)" box under the gyne box, shown
   for a nursery cell with no skill needed. It emits `cell_drone_requested`,
   which `main.gd` connects to `orders_zones.gd::_on_cell_drone_requested`.
   Ticking one box unticks the other, as DR-1's marks do.
2. A drone-marked cell is drawn with its own colour and tag in the nursery
   zones overlay (`nursery_panel.gd::colour_for`/`tag_for`, called from
   `orders_zones.gd`). The colour is the drone's own `DRONE_COLOUR`, not a new
   one.
3. Dave's hands-on check is filed at closeout, because the slice is
   click-driven: tick the box on an empty nursery cell, see the cell's drone
   tag, and see a drone hatch from it.

**Invariants.** Presentation only: the simulation is DR-1's. The popup's layout
passes `tests/test_layout_regression.py`. The box follows
`plans/reference/ui-rules.md`.

```queue
**[Claude] DR-2 -- the cell popup's drone box**
- Plan: `plans/now/drones.md` -- "DR-2 -- the cell popup's drone box"
- Files: `scripts/hud.gd`, `scripts/main.gd`, `scripts/nursery_panel.gd`, `scripts/orders_zones.gd`, `tests/test_layout_regression.py`
- Check: `tests/test_layout_regression.py` passes with the popup's new row; `python -m unittest tests.test_display_text_golden` passes; `.\tools\verify.ps1` is green; Dave's hands-on check is filed in `checks/ready.md`
- Proof: `absent: scripts/hud.gd :: cell_drone_requested`
- Next after: None -- plan complete
```

## Not in the queue, and why

- Nothing: DR-2, the last slice, is queued now that DR-1 has landed
  (25 Oct 2026).

## Read on demand

- `plans/design/pixel-art.md`: drone sprite sizes, for when drone art exists.
- `.claude/rules/saving.md`: additive save keys and the round-trip goldens.
