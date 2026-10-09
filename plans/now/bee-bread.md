# Bee Bread -- fermented larval food, the tier-3 currency, and what it makes of a worker

<!-- CONTEXT: plan | LAYER: immediate-task -->
Status: active | Owner: Dave / Claude Code | Next: BB-2 -- Nurses feed Bee Bread; a worker's outcome is fixed at emergence and saved, specified below now BB-1 has landed (9 Oct 2026); BB-3 is specified when BB-2 lands | Dependency: none -- COL-4, NF-2, T2-2, T2-3 and BB-1 have landed | Verified: 2026-10-09

## Objective

`plans/design/progression.md` section 11, step 12 (Phase C): Bee Bread is
the Brood tier-2 node every tier-3 purchase needs, and
`plans/design/product-scope.md` section 6.1 lists its production, larval
use and adult consequences as essential for the alpha. The design is
`product-scope.md` section 9 with Dave's decisions of 6-7 Oct 2026 beneath
it (every run, old saves, about two days' ferment, a Fermenter mode, cells
like any store). This plan restates none of them.

## Current state

Verified 7 Oct 2026 against master; BB-1 (9 Oct 2026) has since built Bee Bread making, and BB-2's own section says what is true for it now:

- `skills.gd` reserves the resource key `BEE_BREAD` (tier 3's ladder row)
  and the node `skill.brood.bee_bread` (Brood tier 2, status `new`, so the
  tree marks it "Not built yet"). Weighted flower choice's recipe already
  names `BEE_BREAD`. Nothing makes it.
- Honey workers (`roles.gd` `HONEY`) have no modes; Miner's `automine` is
  the pattern a mode follows. `hive_cell.gd::designated_type` takes
  "nectar", "pollen", "honey" or "brood", explicit or set by a first
  deposit.
- Nurses (`bee_nursery.gd`) feed larvae pollen (`brood_feed_pollen`).
  Every worker lives `bee_lifespan_days` (25) at full speed and capacity.
- Nectar fermentation (`plans/now/nectar-fermentation.md`) is a different
  mechanism -- raw nectar spoiling with age -- and shares only files.

## Open slices

| Slice | What it does | Files it owns | Startable | Level |
| --- | --- | --- | --- | --- |
| BB-1 | Fermenters make Bee Bread in a store cell, ripe after about two days; recipe from a sweep; saved | `scripts/resources.gd`, `scripts/hive_cell.gd`, `scripts/hive.gd`, `scripts/roles.gd`, `scripts/bee.gd`, `scripts/bee_enums.gd`, `scripts/bee_honey.gd`, `scripts/actions.gd`, `scripts/skills.gd`, `scripts/availability.gd`, `scripts/hud.gd`, `scripts/orders_zones.gd`, `scripts/diagnostic_log.gd`, `scripts/game_config.gd`, `scripts/settings_catalogue.gd`, `scripts/save_game.gd`, `scripts/saving.gd`, `tests/test_bb1_bee_bread.py`, `test_scenarios/bb1_bee_bread.json` | yes -- COL-4, NF-2, T2-2 and T2-3 have landed; queued in the Claude lane | high |
| BB-2 | Nurses feed Bee Bread; a worker's outcome is fixed at emergence and saved; every run | `scripts/bee_nursery.gd`, `scripts/hive_cell.gd`, `scripts/bee.gd`, `scripts/bee_survival.gd`, `scripts/bee_foraging.gd`, `scripts/world_building.gd`, `scripts/game_config.gd`, `scripts/settings_catalogue.gd`, `scripts/save_game.gd`, `scripts/saving.gd`, `scripts/hud.gd`, `tests/test_bb2_bee_bread_nursing.py`, `test_scenarios/bb2_bee_bread_nursing.json` | yes -- BB-1 has landed | high |
| BB-3 | Bee Bread is spendable on tier-3 recipes, from the cells that hold it | specified when BB-1 lands | no -- after BB-1 | medium |
| BB-4 | Challenges 1 and 2 and the Colony Run re-paced for 15-day unfed workers | specified when BB-2 lands | no -- after BB-2 | medium |

**Dependencies.** BB-1 first; BB-2 and BB-3 each follow it and may run in
either order (BB-2 owns nursing and `bee.gd`, BB-3 `progression.gd`'s
stores). BB-4 follows BB-2, whose rule it balances around. Every slice
changes balance, so each is simulated first with PE-2's arc
(`tools/pacing_gates.py`). Cross-plan: `plans/now/nectar-fermentation.md`
NF-2 and `plans/now/tier-two.md` T2-3, which had to land first, have; BB-1
shared `hive.gd`, `bee.gd`, `game_config.gd`, `settings_catalogue.gd` and
the save files with NF-3 (landed 9 Oct 2026), and shares `orders_zones.gd`
and `hud.gd` with NF-5, both in the Claude lane (T2-4b, which shared them too, landed 9 Oct
2026);
`plans/design/progression.md` step 13 (tier-3 content) waits for BB-3.

**Reads.** A slice reads its own section here and `product-scope.md`
section 9 (`python tools/heading.py plans/design/product-scope.md "9. Bee
Bread"`).

## BB-1 -- Fermenters make Bee Bread in a store cell

<!-- LAYER: immediate-task -->

Level: high (a new cell content kind, a role's first mode, a save field and
a recipe set by a sweep). Specified 9 Oct 2026 by the queue steward, after
NF-2 landed; verified against master that day.

**True now.** `skills.gd` reserves `BEE_BREAD` and `skill.brood.bee_bread`
(Brood tier 2, cost honey 30 and pollen 150, status `new`); nothing makes
Bee Bread and no file but `skills.gd` names it. The Honey role
(`roles.gd`) has no modes. Royal jelly is the precedent this slice copies:
a nurse mode (`nurse_make_jelly`, `nurse_store_jelly` in `actions.gd`), a
`resources.gd` row (`jelly_cell_capacity`, storable, designatable), a cell
colour in `hive_cell.gd` and a `jelly_designation` row in
`availability.gd::UI_GATES`. NF-2's `hive_cell.nectar_since` stamp, read on
demand by `is_fermented()`, is the precedent for ripening.

**True afterwards.**

- **The content kind.** `bee_bread` is a `resources.gd` row: storable,
  designatable, not energy, not evictable (nothing moves it in BB-1; BB-2
  and BB-3 spend it), capacity `GameConfig.bee_bread_cell_capacity`. It
  joins the hand lists that file's header names: the cell popup's
  Reserve-for buttons and their gating in `hud.gd`, a
  `bee_bread_designation` row in `availability.gd::UI_GATES` shown once
  the skill is bought, `hive_cell.gd`'s colour constants and content
  branches, and `diagnostic_log.gd`'s cells-by-content loop. Hungry adults
  never eat it: `hive.find_food_cell` is unchanged. Its colour sits at
  least 0.10 (OKLab) from every other cell-content colour; SP-3's test
  (`plans/now/sprites.md`) checks that whichever of the two lands second.
- **Sealing and ripening.** A `bee_bread` cell that reaches capacity is
  sealed: it takes no more deposits, and `hive_cell.gd` stamps
  `bee_bread_sealed_at` with `Session.sim_time`. `is_ripe_bee_bread()` is
  derived from that stamp on every call, as `is_fermented()` is, so ripening
  costs no per-frame work. Ripe after `GameConfig.bee_bread_ripen_hours`
  (about two game-days: 48, confirmed by the sweep). Until ripe it is
  neither food nor currency; the cell shows sealed and ripe states apart.
- **The Fermenting mode.** Honey gets its first `roles.gd` mode,
  `{"key": "ferment", "skill": "skill.brood.bee_bread", "label":
  "Fermenting"}`, a toggle as the Miner's "Dig on its own" is, wired
  through every place `roles.gd`'s header lists for a sub-mode (a
  `fermenting` bee field, `bee.gd::_action_mode_for_role` and
  `role_name_text`, `hud.gd::_mode_is_active`,
  `orders_zones.gd::_apply_mode`, and the field in `save_game.gd` and
  `saving.gd`). Honey workers never ferment unless the player turns it on.
  A Fermenting bee takes `GameConfig.bee_bread_pollen_per_load` pollen and
  `GameConfig.bee_bread_honey_per_load` ripe honey from the comb, carries
  them to a cell designated `bee_bread` (else an empty cell found through
  `hive.find_cell_for`, which the first deposit marks, as nectar, pollen
  and honey find theirs today) and
  deposits `GameConfig.bee_bread_per_load`. Its work is new `actions.gd`
  rows ahead of the honey rows, found by `bee_honey.gd`, with any new
  states in `bee_enums.gd`; when it cannot ferment (no ripe honey, no
  pollen, or no cell with room) it makes honey as before.
- **The skill.** `skill.brood.bee_bread`'s status becomes `existing`, and
  its comment no longer calls the recipe open.
- **Saves.** Each cell's `bee_bread_sealed_at` and each bee's `fermenting`
  are additive fields (`.claude/rules/saving.md`); a save from before
  BB-1 has neither, so it restores no Bee Bread and no Fermenting bees.
- **The recipe, from a sweep run in this slice and recorded here.**
  `test_scenarios/bb1_bee_bread.json` starts a colony with the skill bought,
  stocked honey and pollen, a designated `bee_bread` cell and two honey
  workers set to Fermenting. The sweep picks the per-load amounts and cell
  capacity so that the cell fills, seals and ripens within about three
  game-days of the run's start while the colony's honey and pollen never
  reach zero. `tests/test_bb1_bee_bread.py` asserts from that run that the
  cell fills, seals, is not ripe before `bee_bread_ripen_hours` and is ripe
  after, that no adult ate from it, and that the cell's stamp and contents
  and the bees' Fermenting flag survive a save and restore.

**Sweep record (9 Oct 2026, BB-1).** `test_scenarios/bb1_bee_bread.json`:
8 cells, the cell at hex (0, 0) reserved for bee bread, 600 pollen and 600
wet honey stocked, the queen laying, 200-second days, two Fermenting honey
workers. Recipes as pollen / honey / bee bread per load, cell capacity:

| Recipe | Reserved cell sealed | Ripe | Lowest pollen |
| --- | --- | --- | --- |
| 2 / 1 / 2, 60 | 92 s | 492 s | 201 |
| **3 / 1 / 3, 60** | 67 s | 468 s | 202 |
| 4 / 2 / 4, 80 | 67 s | 468 s | 0 by day 3 |
| 3 / 1 / 3, 90 | 92 s | 492 s | 15 |

Chosen: 3 / 1 / 3 into 60-unit cells (`bee_bread_pollen_per_load`,
`bee_bread_honey_per_load`, `bee_bread_per_load`, `bee_bread_cell_capacity`),
with `bee_bread_ripen_hours` 48: one unit of pollen per unit of bee bread and
a third of a unit of ripe honey. Seeds 11, 23 and 37 gave the same seal and
ripe times. Ripe honey never ran out once the first cell was fanned. A
fermenter in a small hive packs a load every few seconds, so its pollen draw
is set by how many spare cells it can fill; BB-4's re-pacing, with foragers
in the loop, revisits that. The first sweep found that `find_cell_for`'s
"practically full" skip left every cell just short of sealing, so
`hive.gd::find_bee_bread_target` tops an unsealed bee bread cell up to the
brim before starting another.

**Built beside the specification.** Fermenting is offered on the Doing row
only once Bee bread is owned (`hud.gd::_build_doing_row`; the Miner's "Dig on
its own" is left as it was); the Bee bread "Reserve for" button reads the
skill from its `UI_GATES` row (`Availability.designation_owned`); and the
cell popup's Raises menu offers a plain honey maker, never a Fermenting one.
After review: a cell holding bee bread refuses re-reservation for another
kind, emptying and keep-empty (`orders_zones.gd`, `bee.gd::command_empty_cell`),
since nothing may move it yet; a bee bread cell's size is fixed by its first
deposit, so a later capacity change cannot leave it unable to seal (restore
re-sizes it and seals one already full); a honey maker leaving the role puts
its carried bee bread back into the comb; one holding bee bread with no cell
waits rather than fanning or fetching nectar; and pressing Fermenting sets
every selected bee to the state the button showed.

**Must not change.** Honey making for a honey worker not set to
Fermenting, nursing (nurses still feed pollen; BB-2 changes that), adult
eating order, the stores the skills window prices against (BB-3), and
PE-2's pacing arc (`python tools/pacing_gates.py`), which runs no
Fermenting bee.

**Out of scope.** Nurses feeding it and adult outcomes (BB-2), spending it
(BB-3), re-pacing (BB-4), a hatch-cell Fermenting option, and emptying or
moving Bee Bread.

```queue
**[Claude] BB-1 -- Fermenters make Bee Bread in a store cell**
- Plan: `plans/now/bee-bread.md` -- "BB-1 -- Fermenters make Bee Bread in a store cell"
- Files: `scripts/resources.gd`, `scripts/hive_cell.gd`, `scripts/hive.gd`, `scripts/roles.gd`, `scripts/bee.gd`, `scripts/bee_enums.gd`, `scripts/bee_honey.gd`, `scripts/actions.gd`, `scripts/skills.gd`, `scripts/availability.gd`, `scripts/hud.gd`, `scripts/orders_zones.gd`, `scripts/diagnostic_log.gd`, `scripts/game_config.gd`, `scripts/settings_catalogue.gd`, `scripts/save_game.gd`, `scripts/saving.gd`, `tests/test_bb1_bee_bread.py`, `test_scenarios/bb1_bee_bread.json`
- Check: `python -m unittest tests.test_bb1_bee_bread` passes (Fermenting honey workers fill a Bee Bread cell, it seals, ripens only after `bee_bread_ripen_hours`, no adult eats it, and the cell and the bees' mode survive save and restore); `.\tools\verify.ps1` is green
- Proof: `absent: scripts/game_config.gd :: bee_bread_ripen_hours`
- Next after: BB-2 -- Nurses feed Bee Bread; a worker's outcome is fixed at emergence and saved
```

## BB-2 -- Nurses feed Bee Bread; a worker's outcome is fixed at emergence and saved

<!-- LAYER: immediate-task -->

Level: high (a balance rule in every run, a per-bee save field with an
old-save rule, and the hatch path). Specified 9 Oct 2026 by BB-1's worker,
from this plan's outline and `product-scope.md` section 9's decisions.

**True now.** BB-1 makes Bee Bread: `hive_cell.gd::is_ripe_bee_bread()`
says when a sealed cell is ready, and `take_resource("bee_bread", ...)`
refuses anything unripe. Nurses (`bee_nursery.gd`) load pollen and nectar or
honey from the comb and feed larvae `brood_feed_pollen` per feed. Every
worker lives `bee_lifespan_days` (`bee_survival.gd`) at the speed and carrying
capacity `bee.gd::_apply_stats` and `bee_foraging.gd::max_capacity` give it.
A larva becomes a bee in `world_building.gd::_spawn_hatched_bee`, which is
handed its cell.

**True afterwards.**

- **Nursing.** When the colony holds ripe Bee Bread, a nurse loads
  `GameConfig.brood_feed_bee_bread` per feed from a ripe cell and feeds it in
  place of pollen; with none ripe she feeds pollen as today. The queen's
  backup nursing follows the same rule. Gyne larvae still take royal jelly as
  well. The larva's cell records that it was fed Bee Bread (an additive
  per-cell save field).
- **The outcome.** At emergence the new worker's outcome is fixed from its
  cell and saved with it: raised with Bee Bread, it lives 25 days at 105%
  speed and carrying capacity; raised without, 15 days at 95%. The numbers
  are `GameConfig` values in `settings_catalogue.gd`. The selection panel
  says which (`hud.gd`).
- **Saves.** The per-bee outcome is additive; a save from before BB-2 loads
  its adults as today's workers (25 days, 100%) for the rest of their lives,
  and only larvae raised after loading follow the rule.
- **The ration, from a sweep run in this slice and recorded here.**
  `test_scenarios/bb2_bee_bread_nursing.json` raises brood beside a ripe Bee
  Bread cell and beside none; the sweep sets `brood_feed_bee_bread` so a
  ripe 60-unit cell raises a useful handful of larvae.
  `tests/test_bb2_bee_bread_nursing.py` asserts from that run that a larva
  fed Bee Bread emerges "with" and one fed only pollen "without", that each
  outcome's lifespan, speed and capacity apply, and that the outcome survives
  a save and restore while a pre-BB-2 save loads its adults unchanged.

**Must not change.** Nursing with no ripe Bee Bread, gyne feeding, the stores
the skills window prices against (BB-3), and Bee Bread making (BB-1).

**Out of scope.** Priority Cells (tier 3), spending Bee Bread (BB-3), and
re-pacing the Challenges and the Colony Run (BB-4), which this rule makes
necessary.

```queue
**[Claude] BB-2 -- Nurses feed Bee Bread; a worker's outcome is fixed at emergence and saved**
- Plan: `plans/now/bee-bread.md` -- "BB-2 -- Nurses feed Bee Bread; a worker's outcome is fixed at emergence and saved"
- Files: `scripts/bee_nursery.gd`, `scripts/hive_cell.gd`, `scripts/bee.gd`, `scripts/bee_survival.gd`, `scripts/bee_foraging.gd`, `scripts/world_building.gd`, `scripts/game_config.gd`, `scripts/settings_catalogue.gd`, `scripts/save_game.gd`, `scripts/saving.gd`, `scripts/hud.gd`, `tests/test_bb2_bee_bread_nursing.py`, `test_scenarios/bb2_bee_bread_nursing.json`
- Check: `python -m unittest tests.test_bb2_bee_bread_nursing` passes (a larva fed Bee Bread emerges with the 25-day, 105% outcome and one fed only pollen with the 15-day, 95% one; the outcome survives save and restore; a pre-BB-2 save loads its adults unchanged); `.\tools\verify.ps1` is green
- Proof: `absent: scripts/game_config.gd :: brood_feed_bee_bread`
- Next after: BB-3 -- Bee Bread is spendable on tier-3 recipes, from the cells that hold it
```

## Outline

<!-- LAYER: design -->

- **BB-1.** A Honey worker mode "Fermenting", gated by
  `skill.brood.bee_bread`, seals pollen and honey into a `bee_bread` cell
  (designated, else the nearest empty one, which the first deposit marks).
  It ripens after a `GameConfig` duration of about two game-days; until
  then it is not food or currency. The recipe (pollen and honey per load,
  cell capacity) comes from a headless sweep. Per-cell ripening state is
  an additive save field; an older save has no Bee Bread. Runtime: ripening
  is read from the stamp on demand, like NF-2's age, never advanced per
  frame. The node's status becomes `existing`.
- **BB-2.** Nurses feed ripe Bee Bread when the colony holds it (pollen
  otherwise; Priority Cells, tier 3, later steers scarce supply). A larva
  fed it at least once (the ration is set by the sweep) emerges as a
  "with" worker: 25 days, 105% speed and capacity; otherwise "without":
  15 days, 95%. The outcome is a saved per-bee field; a save without it
  loads its adults as today's workers (25 days, 100%) for life.
- **BB-3.** `BEE_BREAD` joins the stores dictionary the resolver prices
  against, spent from ripe cells on purchase (section 4.2's rule: the
  recipe is spent).
- **BB-4.** With the rule in every run, Challenges 1 and 2's stage pacing
  and the Colony Run's arc are re-simulated; stage thresholds move only
  where the evidence says a stage became unreachable, and the affected
  hands-on checks are filed again.
