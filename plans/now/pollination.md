# Pollination -- Pollinator Points, seed set and the route to Gyne rearing

<!-- CONTEXT: plan | LAYER: immediate-task -->
Status: active | Owner: Dave / Claude Code | Next: PP-5 -- Priority cells: marked brood cells are fed first, then PP-6 (PP-4 landed 12 Oct 2026: a flower that set seed replants its own species nearby, the year's seed weights spring regrowth, and saves carry a `seed_bank` record and each flower's lifespan; PP-2 landed 12 Oct 2026, its hands-on check is C-129); PP-3 landed 12 Oct 2026, releasing `orders_zones.gd` for PP-5 | Dependency: none left for PP-5 or PP-6 beyond the slices before them; AR-4 (`plans/now/alpha-route-evidence.md`) waits for PP-6 | Verified: 2026-10-12

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
  `pp1_pollination_ledger.json`'s restore). PP-4 saves the lifespan
  (12 Oct 2026).

## Open slices

| Slice | What it does | Files it owns | Startable | Level |
| --- | --- | --- | --- | --- |
| PP-4 | seed set: pollinated flowers replant nearby and the meadow remembers through winter | `scripts/flower.gd`, `scripts/world_building.gd`, `scripts/flower_species.gd`, `scripts/pollination.gd`, `scripts/levels.gd`, `scripts/save_game.gd`, `scripts/saving.gd`, tests | yes -- Claude backlog, after PP-2 (PP-1 landed 11 Oct 2026) | high |
| PP-5 | Priority cells: marked brood cells are fed first | `scripts/bee_nursery.gd`, `scripts/hive_cell.gd`, `scripts/hud.gd`, `scripts/orders_zones.gd`, `scripts/main.gd`, `scripts/skills.gd`, `scripts/save_game.gd`, `scripts/saving.gd`, tests | yes -- PP-3 released `orders_zones.gd` (12 Oct 2026) | high |
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

PP-2 shipped 2026-10-12; its specification is `plans/archive/PP-2_2026-10-12.md`.

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

**As built (12 Oct 2026).**

- `levels.gd` rows 3 to 8 (every Scenario and the Colony Run) carry
  `"seed_set": true`; Challenges 1 and 2 do not, and
  `Levels.seed_set_enabled` reads it. A headless scenario file asks for it
  with its own `"seed_set": true`.
- A flower dying of age calls `pollination.gd::flower_withered`, which
  queues the gap it leaves (`gaps`, oldest first): a seed of its species
  where it stood if it set seed (and counts it), an empty gap if not.
  `world_building.gd::_seed_flower` fills the oldest gap first. A seed comes
  up as one unit of its species 20 to 60 px away (`SEED_DISTANCE`, a
  placement distance), clamped into the flower field and at least
  `FLOWER_MIN_DISTANCE` from the hive (`_in_field`, `_random_field_point`'s
  rules), so a lineage cannot drift out over the years. An empty gap takes
  the seasonal draw. So does a seed whose species is out of season when its
  gap comes up (`flower_species.gd::in_season`), so a Foxglove past its
  window does not hold a slot an in-season species would get. Queuing the
  empty gaps too keeps the order the flowers died in, so waiting seeds
  never crowd the seasonal draw out. A bushy seasonal draw also takes the
  empty gaps at the front for its extra units, never a seed.
  At the game's own pace the queue sits at the meadow's unfilled room
  (about 550 gaps), so a gap is filled several minutes after its flower
  dies. That is the existing replant rate, not a new delay.
- Founders and seasonal draws keep their old placement (cluster anchors may
  still spill up to `GRASS_MARGIN` past the field), so a seeded run's
  founding meadow is unchanged. Every flower now goes in through one
  `_add_flower` (obstacle clearance, setup, crab spider), seed or not.
- The spring weighting, read from the Change paragraph: during COL-8's
  regrowth (`Flower.regrowth_factor` below 1) each species' draw weight is
  its seasonal weight plus its share of last year's seed times the seasonal
  weights' total (`flower_species.gd::species_weights`). Half a weighted
  draw follows the season and half the seed; no species falls below its
  seasonal weight. No new balance value: if the half-and-half split proves
  too strong or weak, PP-6 or a later sweep gives it a `GameConfig` weight.
  The first death or replacement after a winter, whichever comes first,
  moves the counts to `spring_counts` and restarts `seed_counts`
  (`pollination.gd::_roll_spring`). Waiting seeds can neither delay that
  swap nor stop the weighting, and a seed set in early spring counts
  toward next year.
- `flower_species.gd::pick_from_weights` falls back to the first species
  not excluded, as `pick_species_index` always did.
- Saves: the counts, `spring_counts` and the waiting gaps go under a
  top-level `"seed_bank"` record, beside `"pollination"` rather than in it,
  so PP-1's record keeps its shape; each flower saves its `"lifespan"`.
  Both additive.
- Dev-only `"forager_species"` on a scenario file makes every starting
  forager prefer one species (`world_building.gd::_spawn_starting_foragers`),
  which is how the runs below show a colony working one species.

**Species shares, simulated 12 Oct 2026** (share of the meadow's flowers by
species; Clover / Borage / Foxglove / Poppy / Bramble / Dandelion). "Pinned"
is thirty foragers all preferring Clover; "free" is the same colony choosing
its own species; "off" is pinned with seed set off, which is how the meadow
behaved before PP-4. Fast runs are `pp4_seed_set.json` (20-second days,
10-day seasons, summer read on day 10, spring on day 25); real runs keep the
game's own 200-second days and 30-day seasons (summer on day 30, spring on
day 45). The real free run's colony starved before day 30 and is left out.
The fast rows were measured again after the review fixes (gap queue,
in-season fallback, field clamp). The real rows are from the first build:
re-running them, the fixture's brood-less colony starved before day 30
(with or without longer bee lifespans), so they could not be repeated. The
fast rows moved by at most a few points, the free-colony spring excepted
(below).

| Run | When | Flowers | Clover | Borage | Foxglove | Poppy | Bramble | Dandelion | Seed counted |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| fast, pinned | end of summer | 604 | 26% | 33% | 2% | 1% | 36% | 2% | Clover 48 |
| fast, pinned | second spring | 526 | 63% | 6% | 1% | 12% | 4% | 14% | |
| fast, free | end of summer | 566 | 19% | 35% | 1% | 2% | 40% | 2% | Dandelion 39, Bramble 16, Clover 1 |
| fast, free | second spring | 475 | 31% | 8% | 0% | 13% | 25% | 22% | |
| fast, off | end of summer | 575 | 22% | 36% | 1% | 3% | 34% | 4% | none |
| fast, off | second spring | 509 | 42% | 9% | 1% | 21% | 5% | 21% | |
| real, pinned | end of summer | 252 | 6% | 58% | 3% | 8% | 10% | 14% | Clover 225 |
| real, pinned | second spring | 255 | 42% | 4% | 2% | 17% | 2% | 34% | |
| real, off | end of summer | 255 | 9% | 67% | 2% | 6% | 9% | 7% | none |
| real, off | second spring | 244 | 25% | 5% | 0% | 20% | 3% | 47% | |

Read: the species the colony worked comes back about one and a half times
as strong in spring (Clover 42% against 25% at real pace, 63% against 42%
fast; the free colony, which set mostly Dandelion and Bramble seed, brings
back Bramble at 25% against 5% but Dandelion only at 22% against 21% -- "off"
is the baseline for any colony, since without seed set foragers do not shape
the meadow), every species is
still present, and summer's shares barely move, because seed replants are a
small part of a summer's deaths. Found while simulating, not PP-4's to fix:
at the game's own pace the meadow holds about 250 flowers, not
`flower_count`'s 800, with or without seed set, because one replacement
every `flower_regrow_seconds` (2 s) is slower than flowers die; worth a look
in PP-6's sweep, since fewer flowers means fewer points.

## PP-5 -- Priority cells: marked brood cells are fed first

<!-- LAYER: immediate-task -->

**Change.** Once Priority cells is owned, the HUD cell menu offers "Feed
first" on a brood cell (beside the gyne toggle); `hive_cell.gd` keeps
`priority_cell`, saved, defaulting to false. Nurses choosing a hungry larva
take a marked one before any unmarked one, for every food a larva takes
(pollen, nectar or honey, Bee Bread, jelly); ties inside each group keep
today's order. `skills.gd`: Priority cells' status becomes `existing`.
Without the skill nothing changes.

```queue
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
Its end opens AR-4. PP-4's simulation found the meadow at about 250 flowers
at the game's own pace (see PP-4's table): the sweep should see whether
`flower_regrow_seconds` holds Pollinator Points back.

```queue-gated
**[Claude] PP-6 -- the sweep prices points and tier-3/4 so Gyne rearing is affordable after the first winter**
- Plan: `plans/now/pollination.md` -- "PP-6 -- the sweep prices points and tier-3/4 so Gyne rearing is affordable after the first winter"
- Files: `scripts/skills.gd`, `scripts/game_config.gd`, `test_scenarios/alpha_arc_test.json`, `tools/pacing_gates.py`, `tests/test_pacing_gates.py`
- Check: `python -m unittest tests.test_pacing_gates` passes; `pacing_gates.py` reports the day Gyne rearing first becomes affordable in the reference Colony Run, and that day falls after the first winter; the sweep's table is recorded in this section; `.\tools\verify.ps1` is green
- Proof: `absent: tools/pacing_gates.py :: gyne_rearing_affordable`
- Next after: none -- the pollination plan is complete; AR-4 in `plans/now/alpha-route-evidence.md` then starts in the Codex lane
```

## Not in the queue, and why

- **PP-6** waits for PP-5 (PP-1 to PP-4 landed 11-12 Oct 2026); its gated block is written, and its sweep settles the final numbers.
