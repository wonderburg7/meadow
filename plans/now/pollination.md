# Pollination -- Pollinator Points, seed set and the route to Gyne rearing

<!-- CONTEXT: plan | LAYER: immediate-task -->
Status: active | Owner: Dave / Claude Code | Next: PP-9 -- the reference route reaches Gyne rearing, then PP-10 -- the sweep prices the route so Gyne rearing is first affordable after the first winter (Dave split PP-9, 27 Oct 2026: PP-9 builds the route, PP-10 the sweep) | Dependency: PP-6 followed FR-2 (Dave 14 Oct 2026; landed 25 Oct 2026); PP-9 follows PP-6; PP-10 follows PP-9; AR-4 (`plans/now/alpha-route-evidence.md`), T2-7b (through AR-4) and FR-3 wait for PP-10 | Verified: 2026-10-27

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
  Priority cells had no behaviour until PP-5 (13 Oct 2026), which gave it
  the "Feed first" mark. An unbuilt node can still be bought.
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
| PP-9 | the reference route reaches Gyne rearing (route only since Dave's split, 27 Oct 2026) | `test_scenarios/alpha_arc_test.json`, `scripts/conditions.gd`, tests | yes -- claimed 27 Oct 2026 | high |
| PP-10 | the sweep prices the route so Gyne rearing is first affordable after the first winter | `scripts/skills.gd`, `scripts/game_config.gd`, tests | no -- after PP-9 | high |

**Dependencies.** PP-1 needs T2-6 owned-able (foraging tier 3 opens only
once Associative learning is owned) and shares `bee_foraging.gd`, `bee.gd`,
`skills.gd` and the save files with T2-6, so it ran after
it in the Claude lane (T2-6 landed 11 Oct 2026; BB-2 and NF-4, which shared them too, landed 10 Oct 2026). PP-2 and PP-4 build on PP-1's ledger; PP-2's
`skill_tree_panel.gd` is free since BB-3 landed (10 Oct 2026). PP-3 shares no file with the Claude
lane and ran in the Codex lane. PP-5 shares `orders_zones.gd` with PP-3
and `bee_nursery.gd` with BB-2 and NF-4, both landed 10 Oct 2026. PP-10 balances everything above; T2-7
(`plans/now/tier-two.md`), which it followed, landed 11 Oct 2026 without moving
prices. AR-4 (`plans/now/alpha-route-evidence.md`) waits for PP-10, and T2-7b,
the tier-2 price sweep on the same arc, waits for AR-4. PP-6 followed FR-2
(`plans/now/forager-recruitment.md`, landed 25 Oct 2026), which added Auto
scouting to the route. PP-9 follows PP-6, whose probe and pacing row its
route must reach; PP-10 follows PP-9 and sweeps that route. FR-3 shares
`skills.gd` with PP-10 and follows it.

**Reads.** A slice reads its own section, product-scope §10's 10 Oct 2026
decisions (`python tools/heading.py plans/design/product-scope.md "10.
Pollination and ecology"`), and `.claude/rules/performance.md` for PP-1,
PP-2 and PP-4, which touch a per-visit path.

PP-1 shipped 2026-10-11; its specification is `plans/archive/PP-1_2026-10-11.md`.

PP-2 shipped 2026-10-12; its specification is `plans/archive/PP-2_2026-10-12.md`.

PP-4 shipped 2026-10-12; its specification is `plans/archive/PP-4_2026-10-12.md`.

PP-5 shipped 2026-10-13; its specification is `plans/archive/PP-5_2026-10-13.md`.

PP-7 shipped 2026-10-15; its specification is `plans/archive/PP-7_2026-10-15.md`.

PP-8 shipped 2026-10-16; its specification is `plans/archive/PP-8_2026-10-16.md`.

PP-6 shipped 2026-10-27; its specification is `plans/archive/PP-6_2026-10-27.md`.

## PP-9 -- the reference route reaches Gyne rearing, then the sweep prices it after the first winter

<!-- LAYER: design -->

Split by Dave, 27 Oct 2026: PP-9 builds the reference route only, and PP-10
below runs the sweep this title names. PP-9 moves no price or recipe and
adds no `config_overrides` that redefine what is measured.

What was true before PP-9 (verified 26 Oct 2026 on PP-6's branch). A one-seed
reference run (seed 20260923) reached its first worker on day 22.18 against
a 1.5 target, never afforded a tier-2 skill, and came out of winter with 4
bees alive. `alpha_arc_test.json` assigns only comb worker, forager (nectar,
pollen) and laying roles and buys no skill, so the reference player makes
no bee bread or royal jelly and earns no Pollinator Points: the path PP-6
measures is unreachable and no price sweep can move it. AR-5
(`plans/archive/AR-5_2026-10-21.md`) gave the reference queen early laying,
yet the first-worker day says it may not be having that effect here.

**Step 1, the weak baseline's cause (PP-9 worker, 27 Oct 2026).** AR-5's
early laying never reached the file: AR-5 tried that opening on 20-21 Oct,
all three colonies died, and Dave revised the first-worker target instead,
so `alpha_arc_test.json` kept its day-17 `laying` action
(`plans/archive/AR-5_2026-10-21.md`, "Revised-target run"). On seed
20260923 the queen forages and builds alone until day 17; by then her five
cells (200 each) hold 459 nectar and 215 pollen, so she has no empty cell
and lays her first egg on day 22 (first worker 22.18). Nothing ever makes
honey (no Honey worker), the five cells cap the colony at 7 bees, and the
winter bill (`season.gd::_resolve_winter`) leaves 4. The cause is the route,
not the simulation.

**Step 2, what a scripted route meets (27 Oct 2026, about 25 three-seed runs
to day 30-34).**

- An early-laying opening works on all three seeds: the queen builds
  `[0,0]`, forages nectar, builds three more cells at 150 nectar, forages
  nectar to 240 and pollen to 100, then lays. First worker on days 8.41,
  7.56 and 8.68 (seeds 20260923-25). Smaller reserves fail: 180 nectar
  spills into the egg cell, and 150 at laying starves the queen and larva.
- Workers cannot build until Cell capacity and Comb worker are bought (20
  ripe honey), so the queen draws two more batches of comb. Locked hatch
  roles (`hatch_role` with `"locked": true`) keep nurses, honey makers and
  pollen foragers coming as bees die at 15 days. The best variant reached
  31-49 bees by day 30 on two seeds.
- `buy_skill` fires once, and the only store trigger is `hive_total`. That
  counts unripe honey and fermented nectar, and the skill tree's stores
  count neither. So purchases were refused 1-4 times a run: Honey worker was
  refused on seed 20260924 with 284-713 nectar held, and Comb worker with
  140-228 honey held. A refusal costs days, the stores pile up, and the
  piled nectar ferments after 96 hours. Only a comb worker (the queen,
  until Comb worker is bought) can discard it.
- Winter is a bill: 51 nectar-equivalent per bee at the scenario's 0.17
  burn, doubled without Shiver Cluster. Pollen, bee bread and jelly are not
  billed. In the 40-bee runs it took 20-44 bees on day 30.
- No variant bought Pollinator points by day 30, so no `gyne_rearing_affordable`
  day existed yet. `alpha_arc_test.json`, `skills.gd` and `game_config.gd`
  were unchanged on the branch when this was recorded.

Escalated to Dave (rule 5), because the reference player is also AR-4's,
T2-7b's and FR-3's arc; he split the slice on 27 Oct 2026 (above).

**What PP-9 builds (Dave, 27 Oct 2026).** In `test_scenarios/alpha_arc_test.json`:

1. **The opening step 2 found**, which put the first worker on days 8.41,
   7.56 and 8.68 over the three seeds.
2. **Locked hatch-role cells for staffing.** Bees die at 15 days and role
   assignments fire once, so locked `hatch_role` cells keep nurses, honey
   makers and pollen foragers coming. Honey makers and nurses work
   `honey_ferment` and `nurse_jelly` (`assign_role`'s role_mode keys), so the
   colony makes bee bread and royal jelly.
3. **Purchases along the path**: Honey worker, Cell capacity and Comb
   worker, Bee bread and Royal jelly, the tier-2 nodes Pollinator points
   needs (Auto scouting among them), then Pollinator points
   (`skill.foraging.pollinator_points`) -- bought, or granted with the reason
   recorded here (Dave, 26 Oct 2026). PP-6's probe counts the whole path from
   zero even after the route owns part of it (Dave's meaning, 26 Oct 2026).
4. **Shiver Cluster bought before the first winter.** Without it the winter
   bill is an instant cost of about 102 nectar-equivalent per bee.

In `scripts/conditions.gd`, a headless-only **`skill_affordable`** leaf
(`"skill_affordable": "<skill id>"`) for the route's `buy_skill` triggers,
so a purchase fires when the Buy button would accept it rather than being
refused. It is true when `Progression.purchase_blocker` returns `""` for the
stores the skill tree's Buy button passes. `scenario_actions.gd`'s
`buy_skill` refusal reason already reads that pair
(`purchase_blocker(skill_id, skill_tree_panel._stores())`); the leaf reads
the same pair rather than counting stores a second way. Owner (rule 4):
`conditions.gd` is the one evaluator scenario triggers use, so this extends
it by one leaf; `Progression` owns the check and the leaf only reads it. No
Challenge stage goal or Colony Run milestone uses it. Runtime: it is
evaluated where scenario triggers already are, and adds no tick of its own.

**Route attempts after the split (27 Oct 2026, eight three-seed runs to day
60, `skill_affordable` committed).** With the leaf, every `buy_skill` fires
without a refusal. The best candidate keeps the opening, adds the queen's
two comb batches, six locked brood cells (pollen x2, nurse, honey capped at
300 stored honey, nectar x2), Shiver Cluster, Miner and Automation, and
`clear_fermented` every three days from day 9. Seed 20260923 owns
Pollinator points and Royal jelly by day 26.3 and comes out of winter with
25 bees, growing to 55 by day 52. It still reports no Gyne-rearing day by
day 60: stores reach 4000 nectar and 2145 pollen, but honey swings between
0 and 671. Seed 20260924 stalls after Backup roles with no honey (12 bees).
Seed 20260925 stalls after Comb worker on day 17.3, holding no nectar or
pollen, and its queen is alone by day 56. Changes that rescue one seed sink
another: removing the second comb batch, drawing less comb, or adding
pollen cells each flipped seed 20260923 from owning Pollinator points to
stalling. `alpha_arc_test.json` is unchanged; the candidate is in the
worker's hand-off.

If the band PP-10 sweeps for still looks out of reach once the route owns
Pollinator points, PP-9 records that here and lands anyway: pricing is
PP-10's job.

Reasoning level high: the route sets the arc AR-4, T2-7b and FR-3 measure.

**Open decisions:** none

```queue
**[Claude] PP-9 -- the reference route reaches Gyne rearing, then the sweep prices it after the first winter**
- Plan: `plans/now/pollination.md` -- "PP-9 -- the reference route reaches Gyne rearing, then the sweep prices it after the first winter"
- Files: `test_scenarios/alpha_arc_test.json`, `scripts/conditions.gd`, `tests/test_conditions.py`
- Check: `python -m unittest tests.test_conditions tests.test_pp6_gyne_rearing_affordable` passes (`skill_affordable` has its match arm and reads `Progression.purchase_blocker` with the Buy button's stores); over 3 seeds of the reference Colony Run (`python tools/pacing_gates.py`) the run owns Pollinator points (`skill.foraging.pollinator_points`), the Gyne-rearing row reports a day on each seed (any day, no band), and the first-worker row stays in band (median by day 17); the weak baseline's cause stays recorded in this section; no price, recipe or `config_overrides` entry that redefines what is measured moves; `.\tools\verify.ps1` is green
- Proof: `absent: scripts/conditions.gd :: skill_affordable`
- Next after: PP-10 -- the sweep prices the route so Gyne rearing is first affordable after the first winter
```

## PP-10 -- the sweep prices the route so Gyne rearing is first affordable after the first winter

<!-- LAYER: design -->

Split from PP-9 by Dave, 27 Oct 2026: PP-9 builds the reference route,
PP-10 prices it. Intent (Dave, 10 Oct 2026): a reasonably played Colony Run
first affords Gyne rearing after the first winter. The reference player in
`alpha_arc_test.json` buys along the route; `pacing_gates.py` reports the
day Gyne rearing becomes affordable; the point awards and tier-3/4 recipes
in `skills.gd` are set to the intent. PP-10's end opens AR-4. PP-4's
simulation found the meadow at about 250 flowers at the game's own pace
(see PP-4's table): the sweep should see whether `flower_regrow_seconds`
holds Pollinator Points back.

Decisions (Dave, 14 Oct 2026):

- **The band is the first 11 days after winter.** The reference run's
  median day Gyne rearing first becomes affordable falls from the day the
  first winter ends to 11 days after it -- days 42 to 52 on today's
  calendar (30-day season, 10-day winter, so winter ends on day 41). That
  leaves room to raise a gyne (about 2.4 days) and send her inside the
  second summer's mating window (about days 47 to 65); a late buyer may
  send after its midsummer peak and earn fewer genetic points. The band
  is measured from the run's own winter schedule, as `pacing_gates.py`
  already reads it, not fixed day numbers.
- **Price-only, no calendar gate.** Nothing stops a player who is ahead
  buying Gyne rearing before winter; the sweep prices it so the reference
  player cannot. Victory already waits for the first winter
  (`colony_milestones.gd::check_victory`), so an early buyer gets a head
  start and first-summer genetic points, never an early win.
- **Auto scouting is on the route; Auto-recruitment is not.** Dave made
  Auto scouting a Foraging tier-2 node that replaces Orientation flight
  (`plans/now/forager-recruitment.md` decision 1), so every route player
  buys it before Pollinator points: FR-2 added it (25 Oct 2026) and PP-10
  prices it with the rest of the route. Auto-recruitment (tier 4, off the
  route) is priced by FR-3's own sweep; PP-10 leaves its cost as it is.

What is true now (27 Oct 2026): no reference run has bought Pollinator
points, so no `gyne_rearing_affordable` day exists to sweep against; PP-9
builds the route that produces one. `pacing_gates.py` already prints the
Gyne-rearing row with its band (`GYNE_AFFORDABLE_AFTER_WINTER_DAYS`).

**The work.** Sweep `scripts/skills.gd` (point awards, the tier-3/4
recipes, Auto scouting) and `scripts/game_config.gd` (including
`flower_regrow_seconds`, per PP-4's note above) over 3 seeds of PP-9's
route until the median `gyne_rearing_affordable` day falls in the band, and
record the sweep's table (each trial's values and per-seed days) in this
section. Change prices and balance values only: PP-9's route stays as it
landed, and no `config_overrides` entry redefines what is measured. If no
price in these files can reach the band, stop and escalate to Dave
(`docs/agent-rules.md` rule 5) rather than redefine it.

Reasoning level high: a balance sweep that sets a gameplay outcome.

**Open decisions:** none

```queue-gated
**[Claude] PP-10 -- the sweep prices the route so Gyne rearing is first affordable after the first winter**
- Plan: `plans/now/pollination.md` -- "PP-10 -- the sweep prices the route so Gyne rearing is first affordable after the first winter"
- Files: `scripts/skills.gd`, `scripts/game_config.gd`, `tests/test_pacing_gates.py`
- Check: over 3 seeds of PP-9's reference Colony Run, `python tools/pacing_gates.py`'s Gyne-rearing row reports a median day from the first winter's end to 11 days after it (days 42 to 52); the sweep's table is recorded in this section; a `PP-10` test in `tests/test_pacing_gates.py` pins the swept values, so a price moved without a fresh sweep fails it; `python -m unittest tests.test_pacing_gates tests.test_pp6_gyne_rearing_affordable` passes; `.\tools\verify.ps1` is green
- Proof: `absent: tests/test_pacing_gates.py :: PP-10`
- Next after: none -- the pollination plan is complete; AR-4 in `plans/now/alpha-route-evidence.md` then starts in the Codex lane, and FR-3 in `plans/now/forager-recruitment.md` follows
```

## Not in the queue, and why

- **PP-10** -- the sweep prices the route so Gyne rearing is first affordable after the first winter; waits for PP-9, whose reference route it sweeps against.
