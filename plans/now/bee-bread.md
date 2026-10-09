# Bee Bread -- fermented larval food, the tier-3 currency, and what it makes of a worker

<!-- CONTEXT: plan | LAYER: immediate-task -->
Status: active | Owner: Dave / Claude Code | Next: BB-2 -- Nurses feed Bee Bread; a worker's outcome is fixed at emergence and saved, then BB-3 -- Bee Bread is spendable on tier-3 recipes, from the cells that hold it, both specified below and queued in the Claude lane now BB-1 has landed (9 Oct 2026); BB-4 is specified when BB-2 lands | Dependency: none -- COL-4, NF-2, T2-2, T2-3 and BB-1 have landed | Verified: 2026-10-09

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
| BB-2 | Nurses feed Bee Bread; a worker's outcome is fixed at emergence and saved; every run | `scripts/bee_nursery.gd`, `scripts/hive_cell.gd`, `scripts/bee.gd`, `scripts/bee_survival.gd`, `scripts/bee_foraging.gd`, `scripts/world_building.gd`, `scripts/game_config.gd`, `scripts/settings_catalogue.gd`, `scripts/save_game.gd`, `scripts/saving.gd`, `scripts/hud.gd`, `tests/test_bb2_bee_bread_nursing.py`, `test_scenarios/bb2_bee_bread_nursing.json` | yes -- BB-1 has landed; queued in the Claude lane | high |
| BB-3 | Bee Bread is spendable on tier-3 recipes, from the cells that hold it | `scripts/skill_tree_panel.gd`, `tests/test_bb3_bee_bread_currency.py`, `test_scenarios/bb3_bee_bread_currency.json` | yes -- BB-1 has landed; queued in the Claude lane after BB-2 | medium |
| BB-4 | Challenges 1 and 2 and the Colony Run re-paced for 15-day unfed workers | specified when BB-2 lands | no -- after BB-2 | medium |

**Dependencies.** BB-1 has landed; BB-2 and BB-3 may run in either order
(BB-2 owns nursing and `bee.gd`, BB-3 the skill window's stores in
`skill_tree_panel.gd`; they share no file). BB-4 follows BB-2, whose rule it balances around. Every slice
changes balance, so each is simulated first with PE-2's arc
(`tools/pacing_gates.py`). Cross-plan: `plans/now/nectar-fermentation.md`
NF-2 and `plans/now/tier-two.md` T2-3, which had to land first, have. BB-2
shares `hud.gd` with NF-5 (`plans/now/nectar-fermentation.md`) and
`hive_cell.gd` and `bee.gd` with SP-3 (`plans/now/sprites.md`), all in the
Claude lane ahead of it; CD-3 (`plans/now/diagnostic-readiness.md`, for
`bee.gd`) and FC-2 (`plans/now/crisis-readiness.md`, for the save files and
`hud.gd`) wait for BB-2 to release them;
`plans/design/progression.md` step 13 (tier-3 content) waits for BB-3.

**Reads.** A slice reads its own section here and `product-scope.md`
section 9 (`python tools/heading.py plans/design/product-scope.md "9. Bee
Bread"`).

BB-1 shipped 2026-10-09; its specification is `plans/archive/BB-1_2026-10-09.md`.

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

## BB-3 -- Bee Bread is spendable on tier-3 recipes, from the cells that hold it

<!-- LAYER: immediate-task -->

Level: medium (one file and an acceptance check; the recipes and the
spending rule are already decided). Specified 9 Oct 2026 by the queue
steward, from this plan's outline, after reading the files named below.

**True now.** `skills.gd` already prices tier-3 and later skills in
`Skills.BEE_BREAD` (for example 12 to 30 per skill), so the resolver
(`progression.gd::can_afford` / `purchase`) asks for it, but nothing ever
supplies it: `skill_tree_panel.gd::_stores()` builds the snapshot the window
prices against from `STORE_CONTENT`, which maps only nectar, pollen, honey
and royal jelly to cell contents. Every Bee Bread recipe is therefore
unaffordable, however much the comb holds. `buy_skill` takes exactly what
`purchase` deducted from the comb with `hive.gd::take()`, which walks the
cells; BB-1's `hive_cell.gd::take_resource("bee_bread", ...)` already
refuses an unripe cell, and `is_ripe_bee_bread()` says when one is ripe.

**True afterwards.**

- `STORE_CONTENT` maps `Skills.BEE_BREAD` to `Resources.BEE_BREAD`, and
  `_stores()` counts a Bee Bread cell only when `is_ripe_bee_bread()` (as it
  counts honey only when ripe), so the snapshot holds exactly what `take()`
  can reach and the take cannot fall short.
- Buying a skill with Bee Bread in its recipe spends it from the ripe cells
  (section 4.2: the recipe is spent); the stores list in the window shows
  "Bee bread" with the rest.
- `test_scenarios/bb3_bee_bread_currency.json` makes or seeds a sealed Bee
  Bread cell with the prerequisites of one Bee Bread-priced skill in place:
  buying it while the cell is unripe is refused (`buy_skill` with
  `expect_refused`); after `bee_bread_ripen_hours` it is bought, and the
  cell holds that recipe's Bee Bread less. `tests/test_bb3_bee_bread_currency.py`
  asserts both from the run.

**Runtime.** None added: `_stores()` runs on opening the window and per
purchase, as now, and ripeness is read from BB-1's stamp on demand.

**Must not change.** The recipes in `skills.gd`, Bee Bread making (BB-1),
nursing (BB-2), and the other currencies' counting.

**Out of scope.** New tier-3 content (`plans/design/progression.md` step 13,
which waits for this slice), Priority Cells, and any price change.

```queue
**[Claude] BB-3 -- Bee Bread is spendable on tier-3 recipes, from the cells that hold it**
- Plan: `plans/now/bee-bread.md` -- "BB-3 -- Bee Bread is spendable on tier-3 recipes, from the cells that hold it"
- Files: `scripts/skill_tree_panel.gd`, `tests/test_bb3_bee_bread_currency.py`, `test_scenarios/bb3_bee_bread_currency.json`
- Check: `python -m unittest tests.test_bb3_bee_bread_currency` passes (a Bee Bread-priced skill is refused while the colony's only Bee Bread is unripe, is bought once it ripens, and the ripe cell loses exactly the recipe's Bee Bread); `.\tools\verify.ps1` is green
- Proof: `absent: scripts/skill_tree_panel.gd :: Skills.BEE_BREAD`
- Next after: BB-4 -- Challenges 1 and 2 and the Colony Run re-paced for 15-day unfed workers
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
