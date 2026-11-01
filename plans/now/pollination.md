# Pollination -- Pollinator Points, seed set and the route to Gyne rearing

<!-- CONTEXT: plan | LAYER: immediate-task -->
Status: active | Owner: Dave / Claude Code | Next: PP-10 (PP-11 landed 1 Nov 2026: the reference route owns Pollinator points on every seed and first affords Gyne rearing on days 54.95, 58.96 and 66.20) -- the sweep prices the route so Gyne rearing is first affordable after the first winter (Dave split PP-9, 27 Oct 2026: PP-9 builds the route, PP-10 the sweep; Dave narrowed PP-9 to its headless tools later that day and moved the route to PP-11) | Dependency: PP-6 followed FR-2 (Dave 14 Oct 2026; landed 25 Oct 2026); PP-9 follows PP-6; PP-11 follows PP-9; PP-10 follows PP-11; AR-4 (`plans/now/alpha-route-evidence.md`), T2-7b (through AR-4) and FR-3 wait for PP-10 | Verified: 2026-11-01

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
| PP-11 | snapshots log bee bread, royal jelly and Pollinator Points; the reference route owns Pollinator points and reaches Gyne rearing on every seed | `scripts/headless/diagnostic_probes.gd`, `tools/headless/profiles.py`, `test_scenarios/alpha_arc_test.json`, tests | yes -- PP-9 landed 27 Oct 2026 | high |
| PP-10 | the sweep prices the route so Gyne rearing is first affordable after the first winter | `scripts/skills.gd`, `scripts/game_config.gd`, tests | yes -- PP-11 landed 1 Nov 2026 | high |

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
scouting to the route. PP-9 follows PP-6 and lands the headless tools a
route needs; PP-11 builds the route with them, which must reach PP-6's probe
and pacing row; PP-10 follows PP-11 and sweeps that route. FR-3 shares
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

PP-9 shipped 2026-10-27; its specification is `plans/archive/PP-9_2026-10-27.md`.

## PP-11 -- the reference route owns Pollinator points and reaches Gyne rearing on every seed

<!-- LAYER: design -->

Queued by Dave, 27 Oct 2026, when he narrowed PP-9 to its headless tools.
PP-11 builds the route PP-9 set out to build ("What the route needs" in
PP-9's section above), with PP-9's `skill_affordable` trigger, `every_days`
repeat and `keep_role` verb.

**True now (27 Oct 2026, PP-9's runs).** Seed 20260923 holds 736-1197 honey,
933-1200 nectar and 4229-4977 pollen on days 60-69, owns Pollinator points
and Royal jelly from day 26.3, yet reports no `gyne_rearing_affordable` day.
Its shortfall is among bee bread, royal jelly and Pollinator Points, which
the snapshots do not log: `scripts/headless/diagnostic_probes.gd`
`SNAPSHOT_FIELDS` and the matching whitelist in `tools/headless/profiles.py`
hold neither store nor the points. Seeds 20260924 and 20260925 reach Auto
scouting but never own Pollinator points. First worker is in band on all
three (8.41, 7.56 and 8.68). `test_scenarios/alpha_arc_test.json` still holds
the weak baseline PP-9 recorded.

**The work.**

1. **Snapshots first.** Add `resources.stored_bee_bread`,
   `resources.stored_royal_jelly` and `resources.pollinator_points` to
   `SNAPSHOT_FIELDS` in `scripts/headless/diagnostic_probes.gd` and to the
   whitelist in `tools/headless/profiles.py`, reading the same values
   `gyne_rearing_affordable` already passes (`hive.total("bee_bread")`,
   `hive.total("jelly")` and `world.pollination.points`), so the strong seed's
   shortfall shows in a run's snapshots. A new
   `tests/test_pp11_route_snapshots.py` checks both whitelists carry the
   three fields and a short run logs them.
2. **Then the route.** Build the reference route in
   `test_scenarios/alpha_arc_test.json` so all 3 seeds own Pollinator points
   (`skill.foraging.pollinator_points`) and report a
   `gyne_rearing_affordable` day (any day, no band), with the first-worker
   row in band (median by day 17).

Best candidate so far: PP-9's scratch file
`C:\Users\dl13860\AppData\Local\Temp\claude\C--Users-dl13860-Documents-Meadow-meadow--claude-worktrees-run-queue-7-14dc3a\53357001-01b6-49bb-b43c-f18266536e2f\scratchpad\pp9_best_route_candidate_v23.json`.
It is in a session scratchpad and may vanish; PP-9's route numbers above
describe it if it does.

**Known blockers.** Weak seeds starve when staffing moves foragers off nectar
early (floors from four adults starved all three queens by day 27), and the
winter bill kills late buyers (seed 20260924 lost 18 bees and its queen one
purchase short of Pollinator points).

**Limits (Dave, 27 Oct 2026).** No price changes (that is PP-10), no
`config_overrides` entry that redefines what is measured, and no
`grant_skill` of a Foraging node. The route uses PP-9's verbs: one that is
missing is a scope change to raise with Dave, not an edit to
`scripts/scenario_actions.gd`. If no route reaches all 3 seeds, stop and
escalate with the per-seed numbers (`docs/agent-rules.md` rule 5). If the
band PP-10 sweeps for still looks out of reach once the route owns
Pollinator points, record that here and land anyway: pricing is PP-10's job.

Reasoning level high: the route sets the arc AR-4, T2-7b and FR-3 measure.

**Result (PP-11 worker, 1 Nov 2026).** Snapshots now log
`resources.stored_bee_bread`, `resources.stored_royal_jelly` and
`resources.pollinator_points`. They showed PP-9's strong seed short of
royal jelly (0 all run: no cell was pinned to jelly, so a jelly nurse had
nowhere to put it) and of bee bread (45, one partly spent cell, against the
path's 46), with 2107 Pollinator Points held. The route that replaced PP-9's
candidate, in `test_scenarios/alpha_arc_test.json` (63 actions, PP-9's verbs
only, `config_overrides` unchanged, no `grant_skill`, no `set_config` or
`set_cell_contents`), runs to day 70, the end of the second summer:

- PP-9's opening, then the queen's second and third batches of comb, both
  held to the first summer (a late third batch had taken the laying queen
  off laying after winter).
- Staffing by daily `keep_role` top-ups from the nectar foragers: pollen
  foragers 20% (25% after winter, 30% once Pollinator points is owned),
  nurses 15%, honey makers 25% before winter (8% after, 20% with Pollinator
  points), a builder and a clearer once Comb worker is owned (the clearer
  empties a re-designated cell, which a builder does not).
- Three thermostats, each a `keep_role` that moves a role's bees back to
  nectar foraging while a store is full: honey makers at 700 honey (the
  skill tree's costs are mostly nectar, and honey makers left none), pollen
  foragers at 500 pollen, fermenters at 200 bee bread (bee bread had filled
  20 cells on one seed and starved it). Above 1500 nectar, honey makers rise
  to 30%.
- Purchases in order, each when `skill_affordable`: Honey worker (at 300
  nectar), Bee bread (its 25-day bees), Cell capacity, Comb worker, Backup
  roles, Shiver Cluster; then Miner and Automation before winter only with
  700 honey held and winter on track; then Tarsal secretions, Orientation
  flight, Associative learning, Adaptive constancy, Auto scouting,
  Pollinator points and Royal jelly, before winter only with 600 nectar held
  and winter on track. After winter nothing is bought before day 44: the
  meadow regrows over 3 days, and a colony that spent its stores on day 40
  starved before it did.
- Bee bread from one fermenter set when Bee bread is bought and when
  Pollinator points is, kept topped up from Auto scouting on. Hex (0, 0) is
  pinned to jelly from Royal jelly on, retried daily until the comb has room
  for what it holds, with one nurse kept making jelly. Once 10 jelly is in,
  the queen stops laying until 450 pollen and 60 bee bread are back.

`python tools/pacing_gates.py` over seeds 20260923-25 (1 Nov 2026): first
worker 8.41, 7.56, 8.68 (median 8.41, in band); Pollinator points bought on
days 53.33, 56.42, 63.79; Gyne rearing first affordable on days 54.95, 58.96
and 66.20 (median 58.96, out of PP-10's 42-52 band); all three colonies live
to day 70 (46, 35 and 30 bees); first automation now has a day (median 45.0)
where it had none. About 70 three-seed trials found the route chaotic: one
change of threshold could kill a seed that had passed, which PP-10's price
sweep will meet too. PP-10's band looks reachable only by cheaper prices,
since no seed owns Pollinator points before day 53: that is PP-10's job.

**Open decisions:** none

```queue
**[Claude] PP-11 -- the reference route owns Pollinator points and reaches Gyne rearing on every seed**
- Plan: `plans/now/pollination.md` -- "PP-11 -- the reference route owns Pollinator points and reaches Gyne rearing on every seed"
- Files: `scripts/headless/diagnostic_probes.gd`, `tools/headless/profiles.py`, `test_scenarios/alpha_arc_test.json`, `tests/test_pp11_route_snapshots.py`
- Check: `python -m unittest tests.test_pp11_route_snapshots tests.test_pp6_gyne_rearing_affordable` passes (both snapshot whitelists carry `resources.stored_bee_bread`, `resources.stored_royal_jelly` and `resources.pollinator_points`, and a run logs them); over 3 seeds of the reference Colony Run (`python tools/pacing_gates.py`) every seed owns Pollinator points (`skill.foraging.pollinator_points`), the Gyne-rearing row reports a day on each seed (any day, no band), and the first-worker row stays in band (median by day 17); no price, recipe, `config_overrides` entry that redefines what is measured, or `grant_skill` of a Foraging node; `.\tools\verify.ps1` is green
- Proof: `absent: scripts/headless/diagnostic_probes.gd :: stored_bee_bread`
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

What is true now (1 Nov 2026): PP-11's route buys Pollinator points on
every seed (days 53.33, 56.42, 63.79) and first affords Gyne rearing on days
54.95, 58.96 and 66.20 (median 58.96); see PP-11's result above. `pacing_gates.py` already prints the
Gyne-rearing row with its band (`GYNE_AFFORDABLE_AFTER_WINTER_DAYS`).

**The work.** Sweep `scripts/skills.gd` (point awards, the tier-3/4
recipes, Auto scouting) and `scripts/game_config.gd` (including
`flower_regrow_seconds`, per PP-4's note above) over 3 seeds of PP-11's
route until the median `gyne_rearing_affordable` day falls in the band, and
record the sweep's table (each trial's values and per-seed days) in this
section. Change prices and balance values only: PP-11's route stays as it
landed, and no `config_overrides` entry redefines what is measured. If no
price in these files can reach the band, stop and escalate to Dave
(`docs/agent-rules.md` rule 5) rather than redefine it.

Reasoning level high: a balance sweep that sets a gameplay outcome.

**Open decisions:** none

```queue-gated
**[Claude] PP-10 -- the sweep prices the route so Gyne rearing is first affordable after the first winter**
- Plan: `plans/now/pollination.md` -- "PP-10 -- the sweep prices the route so Gyne rearing is first affordable after the first winter"
- Files: `scripts/skills.gd`, `scripts/game_config.gd`, `tests/test_pacing_gates.py`
- Check: over 3 seeds of PP-11's reference Colony Run, `python tools/pacing_gates.py`'s Gyne-rearing row reports a median day from the first winter's end to 11 days after it (days 42 to 52); the sweep's table is recorded in this section; a `PP-10` test in `tests/test_pacing_gates.py` pins the swept values, so a price moved without a fresh sweep fails it; `python -m unittest tests.test_pacing_gates tests.test_pp6_gyne_rearing_affordable` passes; `.\tools\verify.ps1` is green
- Proof: `absent: tests/test_pacing_gates.py :: PP-10`
- Next after: none -- the pollination plan is complete; AR-4 in `plans/now/alpha-route-evidence.md` then starts in the Codex lane, and FR-3 in `plans/now/forager-recruitment.md` follows
```

## Not in the queue, and why

- **PP-10** -- the sweep prices the route so Gyne rearing is first affordable after the first winter; waited for PP-11, whose reference route it sweeps against (PP-11 landed 1 Nov 2026).
