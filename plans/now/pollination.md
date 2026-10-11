# Pollination -- Pollinator Points, seed set and the route to Gyne rearing

<!-- CONTEXT: plan | LAYER: immediate-task -->
Status: active | Owner: Dave / Claude Code | Next: PP-2 -- points are spendable and shown, with a +1 at the flower, next in the Claude lane (PP-1 landed 11 Oct 2026: `scripts/pollination.gd` is the ledger); PP-3 -- Gyne rearing and Royal jelly become real gates, in the Codex lane | Dependency: none left for PP-2 or PP-4 -- PP-1's ledger landed 11 Oct 2026; AR-4 (`plans/now/alpha-route-evidence.md`) waits for PP-6 | Verified: 2026-10-11

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
  `cell_gyne_requested` -> `orders_zones.gd::_on_cell_gyne_requested`)
  with no skill check. Nurses' "Making jelly" mode (`roles.gd`) and the
  jelly rows in `actions.gd` carry no skill either.
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
| PP-1 | bees earn Pollinator Points and Contribution; flowers count compatible and incompatible pollen | `scripts/pollination.gd`, `scripts/main.gd`, `scripts/bee.gd`, `scripts/bee_foraging.gd`, `scripts/flower.gd`, `scripts/skills.gd`, `scripts/save_game.gd`, `scripts/saving.gd`, `scripts/debug_panel.gd`, tests | yes -- leads the Claude lane (T2-6 and BB-4 landed 11 Oct 2026) | high |
| PP-2 | points are spendable and shown, with a +1 at the flower | `scripts/skill_tree_panel.gd`, `scripts/hud.gd`, `scripts/pollination.gd`, `scripts/pollination_pop.gd`, tests | no -- after PP-1 | medium |
| PP-3 | Gyne rearing gates gyne cells and Royal jelly gates jelly | `scripts/roles.gd`, `scripts/actions.gd`, `scripts/orders_zones.gd`, `scripts/run_availability.gd`, tests | yes -- Codex lane | medium |
| PP-4 | seed set: pollinated flowers replant nearby and the meadow remembers through winter | `scripts/flower.gd`, `scripts/world_building.gd`, `scripts/flower_species.gd`, `scripts/pollination.gd`, `scripts/levels.gd`, `scripts/save_game.gd`, `scripts/saving.gd`, tests | no -- after PP-1 | high |
| PP-5 | Priority cells: marked brood cells are fed first | `scripts/bee_nursery.gd`, `scripts/hive_cell.gd`, `scripts/hud.gd`, `scripts/orders_zones.gd`, `scripts/main.gd`, `scripts/skills.gd`, `scripts/save_game.gd`, `scripts/saving.gd`, tests | no -- after PP-3 releases `orders_zones.gd` | high |
| PP-6 | the sweep prices points and tier-3/4 so Gyne rearing is affordable after the first winter | `scripts/skills.gd`, `scripts/game_config.gd`, `test_scenarios/alpha_arc_test.json`, `tools/pacing_gates.py`, tests | no -- after PP-1 to PP-5 (T2-7 landed 11 Oct 2026) | medium |

**Dependencies.** PP-1 needs T2-6 owned-able (foraging tier 3 opens only
once Associative learning is owned) and shares `bee_foraging.gd`, `bee.gd`,
`skills.gd` and the save files with T2-6, so it ran after
it in the Claude lane (T2-6 landed 11 Oct 2026; BB-2 and NF-4, which shared them too, landed 10 Oct 2026). PP-2 and PP-4 build on PP-1's ledger; PP-2's
`skill_tree_panel.gd` is free since BB-3 landed (10 Oct 2026). PP-3 shares no file with the Claude
lane and runs in the Codex lane now. PP-5 shares `orders_zones.gd` with PP-3
and `bee_nursery.gd` with BB-2 and NF-4, both landed 10 Oct 2026. PP-6 balances everything above; T2-7
(`plans/now/tier-two.md`), which it followed, landed 11 Oct 2026 without moving
prices. AR-4 (`plans/now/alpha-route-evidence.md`) waits for PP-6, and T2-7b,
the tier-2 price sweep on the same arc, waits for AR-4.

**Reads.** A slice reads its own section, product-scope §10's 10 Oct 2026
decisions (`python tools/heading.py plans/design/product-scope.md "10.
Pollination and ecology"`), and `.claude/rules/performance.md` for PP-1,
PP-2 and PP-4, which touch a per-visit path.

## PP-1 -- bees earn Pollinator Points and Contribution

<!-- LAYER: immediate-task -->

**Owner of the ledger.** A new `scripts/pollination.gd`, created and saved
by `main.gd` exactly as `colony_milestones.gd` is: spendable `points`,
never-spent `contribution`, and the `points_earned` signal PP-2's "+1"
listens to. It is the only writer of both counters. Flowers own their own
pollen counts; bees own only their trip's last flower.

**Change.**

1. `bee.gd`: `trip_last_flower`, cleared whenever the bee enters the hive
   (she grooms her pollen off) and not saved -- a load starts a fresh trip.
2. `bee_foraging.gd::finish_collecting`: if `trip_last_flower` is another
   flower of the same species, this flower takes one compatible delivery
   (`flower.compatible_visits`) and `contribution` rises by one; if it is a
   flower of another species, this flower takes one incompatible delivery.
   A compatible delivery earns one point only while the colony owns
   Pollinator points and only when `Session.sim_time` has reached the
   flower's `award_ready_at`, which is then set to the flower's refill time
   (`seconds_until_full` for the resource taken, as `flower_cooldowns`
   uses). Then `trip_last_flower` becomes this flower. Once per finished
   visit; nothing per frame.
3. `skills.gd`: Pollinator points gains an `enable_behaviour` effect
   (`pollinator_points_on`) read through a `pollination.gd` helper in the
   `tarsal_markers_on()` pattern, and its status becomes `existing`.
4. `flower.gd`: `compatible_visits`, `incompatible_visits`,
   `award_ready_at`, saved with the flower; a save without them loads zero.
5. `debug_panel.gd`: points and contribution in the developer readout.

**Must not change.** Foraging choice, handling and yields; any run's
behaviour while Pollinator points is unowned except the two flower counts
and Contribution.

```queue
**[Claude] PP-1 -- bees earn Pollinator Points and Contribution**
- Plan: `plans/now/pollination.md` -- "PP-1 -- bees earn Pollinator Points and Contribution"
- Files: `scripts/pollination.gd`, `scripts/main.gd`, `scripts/bee.gd`, `scripts/bee_foraging.gd`, `scripts/flower.gd`, `scripts/skills.gd`, `scripts/save_game.gd`, `scripts/saving.gd`, `scripts/debug_panel.gd`, `tests/test_pp1_pollination_ledger.py`, `test_scenarios/pp1_pollination_ledger.json`
- Check: `python -m unittest tests.test_pp1_pollination_ledger` passes (two same-species flowers in one trip earn one point only once Pollinator points is owned and not again from that flower until it has refilled; a trip's first flower earns nothing; arriving from another species counts one incompatible delivery; Contribution rises whether or not the skill is owned; the counters and flower counts survive save and restore); `.\tools\verify.ps1` is green
- Proof: `absent: scripts/flower.gd :: compatible_visits`
- Next after: PP-2 -- points are spendable and shown, with a +1 at the flower
```

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

```queue-gated
**[Claude] PP-2 -- points are spendable and shown, with a +1 at the flower**
- Plan: `plans/now/pollination.md` -- "PP-2 -- points are spendable and shown, with a +1 at the flower"
- Files: `scripts/skill_tree_panel.gd`, `scripts/hud.gd`, `scripts/pollination.gd`, `scripts/pollination_pop.gd`, `tests/test_pp2_points_spendable.py`, `test_scenarios/pp2_points_spendable.json`
- Check: `python -m unittest tests.test_pp2_points_spendable` passes (a tier-4 skill is refused with too few points, bought once enough are earned, and the ledger loses exactly the recipe's points); the frame-time comparison is recorded in this section; `.\tools\verify.ps1` is green
- Proof: `absent: scripts/skill_tree_panel.gd :: Skills.POLLINATOR_POINTS`
- Next after: PP-4 -- seed set: pollinated flowers replant nearby and the meadow remembers through winter
```

## PP-3 -- Gyne rearing gates gyne cells and Royal jelly gates jelly

<!-- LAYER: immediate-task -->

**Change.**

1. `orders_zones.gd::_on_cell_gyne_requested`: marking a cell for a gyne
   is refused unless Gyne rearing is owned, with a one-line message in the
   pattern of `_warn_bee_bread_stays`; unmarking is always allowed.
2. `roles.gd`: the Nurse's "Making jelly" mode names
   `skill.brood.royal_jelly` (the T2-2 mode-skill pattern, which the HUD
   already greys); `actions.gd`: `nurse_make_jelly` and `nurse_store_jelly`
   name it too, so "Anything" nurses cannot make jelly without it.
3. `run_availability.gd`: a run whose level row is not `"run_type":
   "colony"` owns Gyne rearing and Royal jelly from the start, exactly as
   it owns Shiver Cluster.

**Must not change.** Gyne raising in every Challenge and Scenario; a save
whose cells are already marked keeps them (marking is refused, not undone).

```queue
**[Codex] PP-3 -- Gyne rearing gates gyne cells and Royal jelly gates jelly**
- Plan: `plans/now/pollination.md` -- "PP-3 -- Gyne rearing gates gyne cells and Royal jelly gates jelly"
- Files: `scripts/roles.gd`, `scripts/actions.gd`, `scripts/orders_zones.gd`, `scripts/run_availability.gd`, `tests/test_pp3_gyne_gate.py`, `test_scenarios/pp3_gyne_gate.json`
- Check: `python -m unittest tests.test_pp3_gyne_gate` passes (in a Colony Run a gyne-cell request is refused until Gyne rearing is owned and accepted after; nurses make no jelly until Royal jelly is owned; a Scenario run owns both from the start and raises a gyne as today); `tools/verify.ps1` is green
- Proof: `absent: scripts/roles.gd :: skill.brood.royal_jelly`
- Next after: PP-6 -- the sweep prices points and tier-3/4 so Gyne rearing is affordable after the first winter
```

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

```queue-gated
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

Specified when PP-1 to PP-5 have landed (T2-7 landed 11 Oct 2026). Intent (Dave, 10 Oct
2026): a reasonably played Colony Run first affords Gyne rearing after the
first winter. The reference player in `alpha_arc_test.json` buys along the
route; `pacing_gates.py` reports the day Gyne rearing becomes affordable;
the point awards and tier-3/4 recipes in `skills.gd` are set to the intent.
Its end opens AR-4.

## Not in the queue, and why

- **PP-2** and **PP-4** wait for PP-1's ledger (`scripts/pollination.gd`).
- **PP-5** waits for PP-3 (Codex lane) to release `scripts/orders_zones.gd`.
- **PP-6** waits for PP-1 to PP-5, and is specified when they land.
