# Pollination -- Pollinator Points, seed set and the route to Gyne rearing

<!-- CONTEXT: plan | LAYER: immediate-task -->
Status: active | Owner: Dave / Claude Code | Next: PP-7 -- pollination-logging scenarios stop reporting failed, and C-129 gets a watchable run (14 Oct 2026 pass); then PP-6 -- the sweep prices points and tier-3/4 so Gyne rearing is affordable after the first winter (PP-5 landed 13 Oct 2026: once Priority cells is owned, the cell popup's "Feed first" box marks a brood cell, nurses feed a hungry larva there before any unmarked one, and saves carry each cell's `priority_cell`; PP-4 landed 12 Oct 2026: a flower that set seed replants its own species nearby, the year's seed weights spring regrowth, and saves carry a `seed_bank` record and each flower's lifespan; PP-2 landed 12 Oct 2026, its hands-on check is C-129) | Dependency: PP-6 waits for FR-2 (`plans/now/forager-recruitment.md`, Dave 14 Oct 2026); AR-4 (`plans/now/alpha-route-evidence.md`) waits for PP-6 | Verified: 2026-10-15

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
| PP-7 | pollination-logging scenarios stop reporting failed, and C-129 gets a run Dave can watch | `tools/analyze_session.py`, `docs/headless-run-contract.md`, `test_scenarios/pp2_points_watch.json`, tests | yes | low |
| PP-6 | the sweep prices points and tier-3/4 so Gyne rearing is affordable after the first winter | `scripts/skills.gd`, `scripts/game_config.gd`, `test_scenarios/alpha_arc_test.json`, `tools/pacing_gates.py`, tests | no -- after FR-2 (`plans/now/forager-recruitment.md`) puts Auto scouting on the route; PP-5 landed 13 Oct 2026 | medium |

**Dependencies.** PP-1 needs T2-6 owned-able (foraging tier 3 opens only
once Associative learning is owned) and shares `bee_foraging.gd`, `bee.gd`,
`skills.gd` and the save files with T2-6, so it ran after
it in the Claude lane (T2-6 landed 11 Oct 2026; BB-2 and NF-4, which shared them too, landed 10 Oct 2026). PP-2 and PP-4 build on PP-1's ledger; PP-2's
`skill_tree_panel.gd` is free since BB-3 landed (10 Oct 2026). PP-3 shares no file with the Claude
lane and ran in the Codex lane. PP-5 shares `orders_zones.gd` with PP-3
and `bee_nursery.gd` with BB-2 and NF-4, both landed 10 Oct 2026. PP-6 balances everything above; T2-7
(`plans/now/tier-two.md`), which it followed, landed 11 Oct 2026 without moving
prices. AR-4 (`plans/now/alpha-route-evidence.md`) waits for PP-6, and T2-7b,
the tier-2 price sweep on the same arc, waits for AR-4. PP-6 itself waits for FR-2
(`plans/now/forager-recruitment.md`), which adds Auto scouting to the route.

**Reads.** A slice reads its own section, product-scope §10's 10 Oct 2026
decisions (`python tools/heading.py plans/design/product-scope.md "10.
Pollination and ecology"`), and `.claude/rules/performance.md` for PP-1,
PP-2 and PP-4, which touch a per-visit path.

PP-1 shipped 2026-10-11; its specification is `plans/archive/PP-1_2026-10-11.md`.

PP-2 shipped 2026-10-12; its specification is `plans/archive/PP-2_2026-10-12.md`.

PP-4 shipped 2026-10-12; its specification is `plans/archive/PP-4_2026-10-12.md`.

PP-5 shipped 2026-10-13; its specification is `plans/archive/PP-5_2026-10-13.md`.

```queue
**[Claude] PP-7 -- pollination-logging scenarios stop reporting failed, and C-129 gets a run Dave can watch**
- Plan: `plans/now/pollination.md` -- "PP-7 -- pollination-logging scenarios stop reporting failed"
- Files: `tools/analyze_session.py`, `docs/headless-run-contract.md`, `test_scenarios/pp2_points_watch.json`, `tests/test_pp7_recorded_actions.py`
- Check: `python -m unittest tests.test_pp7_recorded_actions` passes: an action entry with result "recorded" is counted in `by_result` but is not in `problems`, while "rejected" and "unresolved" still are; and `python tools/run_scenario.py test_scenarios/pp2_points_spendable.json` prints `status=passed`.
- Proof: `absent: tools/analyze_session.py :: "recorded"`
- Next after: PP-6 -- the sweep prices points and tier-3/4 so Gyne rearing is affordable after the first winter
```
## PP-7 -- pollination-logging scenarios stop reporting failed

Level: low. Found by C-129 on 14-15 Oct 2026: Dave's run of its command
printed `status=failed ... reason=action`, and a runner saw the window close
within 20-30 s, too fast to watch.

**True now** (verified 15 Oct 2026 against master `191e5ed`).

- `pollination.gd` writes its log through `DiagnosticLog.log_action(...,
  "recorded", ...)` (six calls; `pollination_withered` is one). Nothing
  else uses "recorded", and `docs/headless-run-contract.md` does not list it.
- `analyze_session.py::_action_summary` puts every entry whose result is not
  "accepted" into `problems`, and `run_scenario.py` turns a passed run with
  any problem into `failed` with `reason.kind == "action"`. So every
  scenario with `"pollination_log": true` fails: `pp2_points_spendable.json`
  ran 430 simulated seconds, 1209 entries "recorded", none failed, and
  still reported failed.
- `pp2_points_spendable.json` stops when its actions resolve (430
  simulated seconds), and `--windowed` keeps the default `--fixed-fps 30`,
  which runs faster than real time (`run_scenario.py`, `DEFAULT_FIXED_FPS`).

**True afterwards.**

- `_action_summary` leaves "recorded" out of `problems` (it still counts
  it in `by_result`); the docstring and the contract's list of action
  results say "recorded" is a log entry, never a problem.
- `test_scenarios/pp2_points_watch.json`: the same setup as
  `pp2_points_spendable.json` up to and including the two `grant_skill`
  actions, no buy, assert or save steps, and `"stop": {"max_days": 6}`.
- Measure once: `python tools/run_scenario.py
  test_scenarios/pp2_points_watch.json --windowed --fixed-fps 0` should
  take roughly as long in wall time as it simulates. Record the two
  figures here. If it still runs much faster than real time, find what
  sets `Engine.time_scale` on that path and **escalate** with it rather
  than changing it.
- Measured 15 Oct 2026 with `--windowed --fixed-fps 0` (Windows, local clock):
  `pp2_points_watch.json` simulated 1000.1 seconds (6 days, `status=passed`,
  `outcome=max_days`) between about 10:45:50 and 10:46:30, roughly 40 s of wall
  time. `pp2_points_spendable.json` (430 simulated seconds) took about the same
  40 s. So the run is far faster than real time and is not watchable yet.
  Nothing in `scripts/scenario_actions.gd` or the run path sets
  `Engine.time_scale`; the only setters are the speed buttons
  (`scripts/camera_view.gd`, `_on_speed_requested`) and resets to 1.0
  (`scripts/main.gd`, `scripts/debug_panel.gd`). The cause is not in game code on
  this path; the likely suspect is the `--fixed-fps` pacing, not yet verified.
  Escalated: C-129 stays in `checks/blocked.md` until Dave chooses how the
  watch run is paced.
  Re-measured 15 Oct 2026 without `--fixed-fps` (Dave chose option A): the same
  scenario simulated 1000.75 seconds in about 19 s wall time (16:46:33 to 16:46:52),
  still far faster than real time, so C-129 is not yet rewritten or moved.
- On landing, rewrite C-129's command in `checks/blocked.md` to that one,
  then move C-129 to `checks/ready.md` (`--runner dave`).

## PP-6 -- the sweep prices points and tier-3/4 so Gyne rearing is affordable after the first winter

<!-- LAYER: design -->

Its block is gated: it waits for FR-2 (`plans/now/forager-recruitment.md`), which puts Auto scouting on the route (Dave, 14 Oct 2026). PP-5 landed 13 Oct 2026 (PP-1 to PP-4 and T2-7 landed 11-12 Oct 2026). Intent (Dave, 10 Oct
2026): a reasonably played Colony Run first affords Gyne rearing after the
first winter. The reference player in `alpha_arc_test.json` buys along the
route; `pacing_gates.py` reports the day Gyne rearing becomes affordable;
the point awards and tier-3/4 recipes in `skills.gd` are set to the intent.
Its end opens AR-4. PP-4's simulation found the meadow at about 250 flowers
at the game's own pace (see PP-4's table): the sweep should see whether
`flower_regrow_seconds` holds Pollinator Points back.

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
  buys it before Pollinator points: PP-6 waits for FR-2 to add it and
  prices it with the rest of the route. Auto-recruitment (tier 4, off the
  route) is priced by FR-3's own sweep; PP-6 leaves its cost as it is.

```queue-gated
**[Claude] PP-6 -- the sweep prices points and tier-3/4 so Gyne rearing is affordable after the first winter**
- Plan: `plans/now/pollination.md` -- "PP-6 -- the sweep prices points and tier-3/4 so Gyne rearing is affordable after the first winter"
- Files: `scripts/skills.gd`, `scripts/game_config.gd`, `test_scenarios/alpha_arc_test.json`, `tools/pacing_gates.py`, `tests/test_pacing_gates.py`
- Check: `python -m unittest tests.test_pacing_gates` passes; `pacing_gates.py` reports the day Gyne rearing first becomes affordable in the reference Colony Run, and its median falls from the first winter's end to 11 days after it (days 42 to 52); the sweep's table is recorded in this section; `.\tools\verify.ps1` is green
- Proof: `absent: tools/pacing_gates.py :: gyne_rearing_affordable`
- Next after: none -- the pollination plan is complete; AR-4 in `plans/now/alpha-route-evidence.md` then starts in the Codex lane, and FR-3 in `plans/now/forager-recruitment.md` follows
```

## Not in the queue, and why

- Nothing: PP-6, the plan's last slice, is startable since PP-5 landed (13 Oct 2026), and its sweep settles the final numbers.
