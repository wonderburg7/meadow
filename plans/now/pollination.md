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

PP-4 shipped 2026-10-12; its specification is `plans/archive/PP-4_2026-10-12.md`.

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
