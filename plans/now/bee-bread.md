# Bee Bread -- fermented larval food, the tier-3 currency, and what it makes of a worker

<!-- CONTEXT: plan | LAYER: immediate-task -->
Status: active | Owner: Dave / Claude Code | Next: BB-1 -- Fermenters make Bee Bread in a store cell, specified once its gates clear | Dependency: NF-2, queued in the Claude lane (COL-4 has landed; `game_config.gd`, `settings_catalogue.gd`, `hive_cell.gd`, `hive.gd`, the save files); T2-2 and T2-3 (`roles.gd`, `actions.gd`, `skills.gd`) | Verified: 2026-10-07

## Objective

`plans/design/progression.md` section 11, step 12 (Phase C): Bee Bread is
the Brood tier-2 node every tier-3 purchase needs, and
`plans/design/product-scope.md` section 6.1 lists its production, larval
use and adult consequences as essential for the alpha. The design is
`product-scope.md` section 9 with Dave's decisions of 6-7 Oct 2026 beneath
it (every run, old saves, about two days' ferment, a Fermenter mode, cells
like any store). This plan restates none of them.

## Current state

Verified 7 Oct 2026 against master:

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
| BB-1 | Fermenters make Bee Bread in a store cell, ripe after about two days; recipe from a sweep; saved | specified when its gates clear | no -- after COL-4 and NF-2 (shared `game_config.gd`, `settings_catalogue.gd`, `hive_cell.gd`, `hive.gd`, save files) and T2-3 (`roles.gd`, `actions.gd`, `skills.gd`) | high |
| BB-2 | Nurses feed Bee Bread; a worker's outcome is fixed at emergence and saved; every run | specified when BB-1 lands | no -- after BB-1 | high |
| BB-3 | Bee Bread is spendable on tier-3 recipes, from the cells that hold it | specified when BB-1 lands | no -- after BB-1 | medium |
| BB-4 | Challenges 1 and 2 and the Colony Run re-paced for 15-day unfed workers | specified when BB-2 lands | no -- after BB-2 | medium |

**Dependencies.** BB-1 first; BB-2 and BB-3 each follow it and may run in
either order (BB-2 owns nursing and `bee.gd`, BB-3 `progression.gd`'s
stores). BB-4 follows BB-2, whose rule it balances around. Every slice
changes balance, so each is simulated first with PE-2's arc
(`tools/pacing_gates.py`). Cross-plan: `plans/now/nectar-fermentation.md`
NF-2 and `plans/now/tier-two.md` T2-3 must land first (files);
`plans/design/progression.md` step 13 (tier-3 content) waits for BB-3.

**Reads.** A slice reads its own section here and `product-scope.md`
section 9 (`python tools/heading.py plans/design/product-scope.md "9. Bee
Bread"`).

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
