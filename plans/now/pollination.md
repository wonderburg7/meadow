# Pollination -- Pollinator Points, seed set and the route to Gyne rearing

<!-- CONTEXT: plan | LAYER: immediate-task -->
Status: active | Owner: Dave / Claude Code | Next: PP-4 -- seed set: pollinated flowers replant nearby and the meadow remembers through winter, next in the Claude lane (PP-2 landed 12 Oct 2026: points are spent through `pollination.gd::spend`; its hands-on check is C-129); PP-3 landed 12 Oct 2026, releasing `orders_zones.gd` for PP-5 | Dependency: none left for PP-4 -- PP-1's ledger landed 11 Oct 2026; AR-4 (`plans/now/alpha-route-evidence.md`) waits for PP-6 | Verified: 2026-10-12

## Objective

`plans/design/product-scope.md` §6.1, "one selected route to Gyne Rearing",
and §10: bees earn Pollinator Points by moving between flowers of one
species, the points buy every tier-4 skill, and pollination decides how the
meadow replants. Gyne rearing becomes a real tier-4 purchase, reached after
the first winter. The design and Dave's decisions are product-scope §10's
"Decisions (Dave, 10 Oct 2026)"; this plan restates none of them.

## Current state

Verified 10 Oct 2026 against master:

- `skills.gd` prices every tier-4 node in `POLLINATOR_POINTS` and carries
  the Pollinator points node (Foraging tier 3, status `new`). Nothing in
  the game awards, stores or spends points.
- Flowers never set seed. When a flower dies `world_building.gd::_seed_flower`
  plants a replacement of a random seasonal species somewhere in the meadow.
- A bee's per-flower recharge wait is `bee.flower_cooldowns`, set in
  `bee_foraging.gd::finish_collecting` from `flower.seconds_until_full`.
- Gyne cells are marked from the HUD cell menu (`hud.gd`
  `cell_gyne_requested` -> `orders_zones.gd::_on_cell_gyne_requested`) only
  after Gyne rearing is owned. Nurses' "Making jelly" mode (`roles.gd`) and
  both jelly rows in `actions.gd` require Royal jelly; non-Colony runs own
  both skills from the start.
- Brood tier 4 opens only when every Brood tier-3 node is owned
  (`progression.gd::branch_tier_open`): Royal jelly and Priority cells.
  Priority cells has no behaviour. An unbuilt node can still be bought.
- Non-Colony runs already own Shiver Cluster from the start
  (`run_availability.gd`); that is the pattern for owning a skill by run
  type.
- `colony_milestones.gd` is a main-owned, saved, colony-level ledger
  (genetic points) -- the precedent for the Pollinator Points ledger.
- PP-1 (11 Oct 2026): `pollination.gd` holds `points` and `contribution`;
  flowers save `compatible_visits`, `incompatible_visits` and
  `award_ready_at`. Found while testing it: a flower's `lifespan_seconds`
  is not saved, so a load or checkpoint restore re-rolls it and a flower
  now older than its new lifespan dies at once (123 of 545 in
  `pp1_pollination_ledger.json`'s restore). PP-4, which replants on death,
  should save the lifespan or expect those deaths.

## Open slices

| Slice | What it does | Files it owns | Startable | Level |
| --- | --- | --- | --- | --- |
| PP-2 | points are spendable and shown, with a +1 at the flower | `scripts/skill_tree_panel.gd`, `scripts/hud.gd`, `scripts/pollination.gd`, `scripts/pollination_pop.gd`, tests | yes -- Claude lane (PP-1 landed 11 Oct 2026) | medium |
| PP-4 | seed set: pollinated flowers replant nearby and the meadow remembers through winter | `scripts/flower.gd`, `scripts/world_building.gd`, `scripts/flower_species.gd`, `scripts/pollination.gd`, `scripts/levels.gd`, `scripts/save_game.gd`, `scripts/saving.gd`, tests | yes -- Claude backlog, after PP-2 (PP-1 landed 11 Oct 2026) | high |
| PP-5 | Priority cells: marked brood cells are fed first | `scripts/bee_nursery.gd`, `scripts/hive_cell.gd`, `scripts/hud.gd`, `scripts/orders_zones.gd`, `scripts/main.gd`, `scripts/skills.gd`, `scripts/save_game.gd`, `scripts/saving.gd`, tests | no -- after PP-3 releases `orders_zones.gd` | high |
| PP-6 | the sweep prices points and tier-3/4 so Gyne rearing is affordable after the first winter | `scripts/skills.gd`, `scripts/game_config.gd`, `test_scenarios/alpha_arc_test.json`, `tools/pacing_gates.py`, tests | no -- after PP-2 to PP-5 (PP-1 and T2-7 landed 11 Oct 2026) | medium |

**Dependencies.** PP-1 needs T2-6 owned-able (foraging tier 3 opens only
once Associative learning is owned) and shares `bee_foraging.gd`, `bee.gd`,
`skills.gd` and the save files with T2-6, so it ran after
it in the Claude lane (T2-6 landed 11 Oct 2026; BB-2 and NF-4, which shared them too, landed 10 Oct 2026). PP-2 and PP-4 build on PP-1's ledger; PP-2's
`skill_tree_panel.gd` is free since BB-3 landed (10 Oct 2026). PP-3 shares no file with the Claude
lane and ran in the Codex lane. PP-5 shares `orders_zones.gd` with PP-3
and `bee_nursery.gd` with BB-2 and NF-4, both landed 10 Oct 2026. PP-6 balances everything above; T2-7
(`plans/now/tier-two.md`), which it followed, landed 11 Oct 2026 without moving
prices. AR-4 (`plans/now/alpha-route-evidence.md`) waits for PP-6, and T2-7b,
the tier-2 price sweep on the same arc, waits for AR-4.

**Reads.** A slice reads its own section, product-scope §10's 10 Oct 2026
decisions (`python tools/heading.py plans/design/product-scope.md "10.
Pollination and ecology"`), and `.claude/rules/performance.md` for PP-1,
PP-2 and PP-4, which touch a per-visit path.

PP-1 shipped 2026-10-11; its specification is `plans/archive/PP-1_2026-10-11.md`.

## PP-2 -- points are spendable and shown, with a +1 at the flower

<!-- LAYER: immediate-task -->

**Change.** `skill_tree_panel.gd::_stores` adds `Skills.POLLINATOR_POINTS`
from the ledger, and a purchase takes what it deducted from the ledger
(the comb stays owner of everything else). The HUD's stores readout shows
points once the skill is owned. A new presentation-only
`pollination_pop.gd` draws a small rising "+1" over the flower on
`points_earned`, from a small fixed pool; it never reads or writes
simulation state. Measure frame time at 500 and 1,000 bees with the SPR-2
windowed baseline before and after, and record both here.

**Frame time (12 Oct 2026).** `python tools/run_scenario.py
test_scenarios/spr2_render_<n>.json --windowed --report full`, before on
the base commit and after on the branch, interleaved, mean / p95 ms:

| Bees | Before | After |
| --- | --- | --- |
| 500 | 16.6 / 18.2, 19.8 / 21.9, 26.1 / 42.0, 18.8 / 19.8 | 18.2 / 19.5, 23.5 / 27.5, 19.1 / 20.0, 19.7 / 21.9 |
| 1,000 | 29.0 / 32.0, 33.7 / 38.0 | 34.8 / 43.1, 31.8 / 36.0 |

No difference outside the run-to-run spread (500-bee medians 19.3 and
19.4; other sessions were loading the machine). Draw calls and node counts
are unchanged bar the one pop node. Both fixtures are nurses only, so no
point is earned and the pop stays idle: what they measure is that the idle
cost is nil. A "+1" processes only while one shows, from an eight-slot pool.

```queue
**[Claude] PP-2 -- points are spendable and shown, with a +1 at the flower**
- Plan: `plans/now/pollination.md` -- "PP-2 -- points are spendable and shown, with a +1 at the flower"
- Files: `scripts/skill_tree_panel.gd`, `scripts/hud.gd`, `scripts/pollination.gd`, `scripts/pollination_pop.gd`, `tests/test_pp2_points_spendable.py`, `test_scenarios/pp2_points_spendable.json`
- Check: `python -m unittest tests.test_pp2_points_spendable` passes (a tier-4 skill is refused with too few points, bought once enough are earned, and the ledger loses exactly the recipe's points); the frame-time comparison is recorded in this section; `.\tools\verify.ps1` is green
- Proof: `absent: scripts/skill_tree_panel.gd :: Skills.POLLINATOR_POINTS`
- Next after: PP-4 -- seed set: pollinated flowers replant nearby and the meadow remembers through winter
```

PP-3 shipped 2026-10-12; its specification is `plans/archive/PP-3_2026-10-12.md`.

## PP-4 -- seed set: pollinated flowers replant nearby and the meadow remembers through winter

<!-- LAYER: immediate-task -->

**Change.** Only in a run whose level row sets `"seed_set": true` (the
Colony Run and Scenario levels; never Challenges). A flower `sets_seed()`
when `compatible_visits >= 1` and `compatible_visits > incompatible_visits`.
When it dies, a flower that set seed is replaced by its own species near
it; one that did not is replaced by today's seasonal draw. `pollination.gd`
counts seed-setting deaths per species (saved); where COL-8 regrows the
meadow after winter, the species pick is weighted by those counts over
today's seasonal weights, with today's weights as the floor so no species
disappears, and the counts then reset. Simulated first: record the meadow's
species shares at the end of the first summer and in the second spring,
with and without a colony working one species.

```queue
**[Claude] PP-4 -- seed set: pollinated flowers replant nearby and the meadow remembers through winter**
- Plan: `plans/now/pollination.md` -- "PP-4 -- seed set: pollinated flowers replant nearby and the meadow remembers through winter"
- Files: `scripts/flower.gd`, `scripts/world_building.gd`, `scripts/flower_species.gd`, `scripts/pollination.gd`, `scripts/levels.gd`, `scripts/save_game.gd`, `scripts/saving.gd`, `tests/test_pp4_seed_set.py`, `test_scenarios/pp4_seed_set.json`
- Check: `python -m unittest tests.test_pp4_seed_set` passes (a flower that set seed is replaced by its species nearby; one that did not is replaced by the seasonal draw; spring regrowth favours the species that set seed without losing any species; a Challenge replants as today; seed counts survive save and restore); the species-share table is recorded in this section; `.\tools\verify.ps1` is green
- Proof: `absent: scripts/levels.gd :: seed_set`
- Next after: PP-6 -- the sweep prices points and tier-3/4 so Gyne rearing is affordable after the first winter
```

## PP-5 -- Priority cells: marked brood cells are fed first

<!-- LAYER: immediate-task -->

**Change.** Once Priority cells is owned, the HUD cell menu offers "Feed
first" on a brood cell (beside the gyne toggle); `hive_cell.gd` keeps
`priority_cell`, saved, defaulting to false. Nurses choosing a hungry larva
take a marked one before any unmarked one, for every food a larva takes
(pollen, nectar or honey, Bee Bread, jelly); ties inside each group keep
today's order. `skills.gd`: Priority cells' status becomes `existing`.
Without the skill nothing changes.

```queue-gated
**[Claude] PP-5 -- Priority cells: marked brood cells are fed first**
- Plan: `plans/now/pollination.md` -- "PP-5 -- Priority cells: marked brood cells are fed first"
- Files: `scripts/bee_nursery.gd`, `scripts/hive_cell.gd`, `scripts/hud.gd`, `scripts/orders_zones.gd`, `scripts/main.gd`, `scripts/skills.gd`, `scripts/save_game.gd`, `scripts/saving.gd`, `tests/test_pp5_priority_cells.py`, `test_scenarios/pp5_priority_cells.json`
- Check: `python -m unittest tests.test_pp5_priority_cells` passes (with food for one larva, a nurse feeds the marked larva first for each food type; unowned, the mark cannot be set and feeding order is today's; the mark survives save and restore); `.\tools\verify.ps1` is green
- Proof: `absent: scripts/hive_cell.gd :: priority_cell`
- Next after: PP-6 -- the sweep prices points and tier-3/4 so Gyne rearing is affordable after the first winter
```

## PP-6 -- the sweep prices points and tier-3/4 so Gyne rearing is affordable after the first winter

<!-- LAYER: design -->

Specified when PP-2 to PP-5 have landed (PP-1 and T2-7 landed 11 Oct 2026). Intent (Dave, 10 Oct
2026): a reasonably played Colony Run first affords Gyne rearing after the
first winter. The reference player in `alpha_arc_test.json` buys along the
route; `pacing_gates.py` reports the day Gyne rearing becomes affordable;
the point awards and tier-3/4 recipes in `skills.gd` are set to the intent.
Its end opens AR-4.

## Not in the queue, and why

- **PP-5** waits for PP-3 (Codex lane) to release `scripts/orders_zones.gd`.
- **PP-6** waits for PP-2 to PP-5 (PP-1 landed 11 Oct 2026), and is specified when they land.
