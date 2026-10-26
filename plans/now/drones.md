# Drones -- a mated queen lays drones in cells the player marks

<!-- CONTEXT: plan | LAYER: immediate-task -->
Status: active | Owner: Dave / Claude Code | Next: nothing further -- DR-2 landed 26 Oct 2026; Dave's hands-on check C-153 remains | Dependency: none left -- DR-1 has landed and CQ-R7 (`plans/now/code-health.md`) released `scripts/hud.gd` 22 Oct 2026 | Verified: 2026-10-26

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

**Dependencies.** DR-1 edits `scripts/save_game.gd` and `scripts/saving.gd`.
SG-2 (`plans/now/short-term-goals.md`), ED-1 and ED-2 (`plans/now/difficulty.md`)
and CQ-S0b (`plans/now/code-health.md`) edit them too. All are Claude lane, so
they run one at a time in queue order, and each re-captures the CQ-S0 goldens
it changes. The save moves CQ-S1 to CQ-S5 and CQ-R2 (`plans/now/code-health.md`)
wait for DR-1, as for the alpha chain's save slices. DR-2 waited also for CQ-R7, the
Claude slice that reshaped the cell popup in `scripts/hud.gd`; it landed 22 Oct 2026.

DR-1 shipped 2026-10-25; its specification is `plans/archive/DR-1_2026-10-25.md`.

DR-2 shipped 2026-10-26; its specification is `plans/archive/DR-2_2026-10-26.md`.

## Not in the queue, and why

- Nothing: DR-2, the last slice, is queued now that DR-1 has landed
  (25 Oct 2026).

## Read on demand

- `plans/design/pixel-art.md`: drone sprite sizes, for when drone art exists.
- `.claude/rules/saving.md`: additive save keys and the round-trip goldens.
