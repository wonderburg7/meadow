# Short-term goals -- optional outcomes the colony's state suggests

<!-- CONTEXT: plan | LAYER: active -->
Status: active | Owner: Dave / Claude Code | Next: SG-3 -- the goals in the Goals drop-down, with progress, reward, star and Dismiss (startable now SG-2 has landed; it should follow straight on, since SG-2 alone pays rewards the player cannot see) | Dependency: SG-2 landed 26 Oct 2026; GP-2 landed 13 Oct 2026 | Verified: 2026-10-26

## Objective

`plans/design/product-scope.md` §7 sets four goal layers. Long-term goals,
milestones (`scripts/colony_milestones.gd`, CR-2) and urgent problems
(`scripts/problem_messages.gd`) exist. Short-term goals -- optional,
context-sensitive outcomes such as "establish a pollen surplus", stating an
outcome rather than a click sequence, with no failure penalty -- do not.
§6.1 lists the goal layers as essential for the closed alpha.

**Supersedes** `plans/archive/goal-presentation_2026-10-15.md` decisions 5 and 6 and its
GP-3 (Dave, 13 Oct 2026, choosing these answers over his 12 Oct ones). That
plan still owns the Goals drop-down (GP-1, GP-2) that SG-3 draws into.

## Current state

Verified 13 Oct 2026 against master `06bd26c`:

- `colony_milestones.gd` evaluates data milestones (id, label, a
  `conditions.gd` condition) from `main.gd`'s day-change and
  population-change hooks, never per frame, and saves met days as an
  additive field. It runs only where the level row has
  `"run_type": "colony"`.
- `conditions.gd` has keys for net income, cell counts, role counts, brood
  stage, winter readiness and more; `colony_diagnostics.gd::compute`
  derives hungry brood, blocked work, missing workforce, waiting and
  travelling bees.

## Decisions (Dave, 13 Oct 2026, plan-ahead session)

1. **Up to two at a time, picked by the game** from a small catalogue
   according to the colony's current state (low pollen income offers "build
   a pollen surplus"). Each states an outcome and shows its progress. The
   player can dismiss one; a new one is offered the next day. Selection and
   progress reuse `conditions.gd`'s leaves and the `ColonyDiagnostics`
   snapshot -- no second condition evaluator -- evaluated on
   `year_winter.gd::_refresh_signals`' one-second refresh after its Challenge
   early return, never per frame.
2. **Finishing one gives a small reward in the goal's own resource**
   (a pollen goal pays pollen), worth about a quarter of a day of the
   colony's income of it, so it stays small for five bees or five hundred.
   No failure penalty (§7). "Income" here is gross production over the last
   day, not net: the pollen goal is offered when net income is at or below
   zero, where a net figure would pay nothing. The amount is fixed when the
   goal is offered and shown on it. A headless sweep confirms the quarter-day
   intent and sets any floor in `GameConfig`.
3. **Shown in the Colony Run and in Scenarios**, in the Goals drop-down
   (`plans/archive/goal-presentation_2026-10-15.md` decision 2) under the milestone, so
   long-term, milestone, short-term and urgent read top to bottom. Each goal
   line carries a favourite star like the others (its decision 4). A
   Scenario, which has no milestones, shows the drop-down with its
   short-term goals alone.
   Challenges keep their own stage goals. Offered, dismissed and completed
   goals are saved with the run; a save without them starts with none.

4. **The starting catalogue: six goals.** Each is offered only while its
   trigger holds.

   | Goal | Offered when | Done when | Pays |
   | --- | --- | --- | --- |
   | Build a pollen surplus | pollen net income at or below zero | pollen net income positive for a whole day | pollen |
   | Clear blocked work | blocked cells or blocked work above zero | none blocked | honey |
   | Make room | few free cells | that many cells built | nectar |
   | Feed every larva | hungry brood above zero | no hungry brood for a whole day | pollen |
   | Put waiting bees to work | many bees waiting for work | few waiting | nectar |
   | Lay in honey for winter | winter coming and not winter-ready | winter-ready | honey |

   The "few" and "many" thresholds are balance values in `GameConfig`, set by
   the same sweep.
5. **Pacing is measured with goals on.** The scripted reference player
   earns whatever goals it happens to finish, as a real player would, and
   the 5/10/20/60/90-minute gates are judged with the rewards in
   (`plans/now/alpha-route-evidence.md`).

## Open slices

| Slice | What it does | Files it owns | Startable | Level |
| --- | --- | --- | --- | --- |
| SG-2 | Goals offered, completed and paid in Colony Runs and Scenarios, and saved | `scripts/short_term_goals.gd`, `scripts/year_winter.gd`, `scripts/main.gd`, `scripts/conditions.gd`, `scripts/hive.gd`, `scripts/bee_honey.gd`, `scripts/game_config.gd`, `scripts/save_game.gd`, `scripts/saving.gd`, `test_scenarios/sg2_short_term_goals.json`, `tests/test_sg2_short_term_goals.py` | yes (WP-3 landed 22 Oct 2026; SG-1 landed 14 Oct 2026; FC-2 released the save files 17 Oct 2026) | high |
| SG-3 | The goals in the Goals drop-down, with progress, reward, star and Dismiss | `scripts/hud.gd`, `scripts/colony_milestones.gd`, `scripts/main.gd`, `scripts/guidance_catalogue.gd`, `test_scenarios/sg3_goal_shelf.json`, `tests/test_sg3_goal_shelf.py` | no -- after SG-2 | medium |
| GP-5 | a Goals button in the second HUD row replaces the Goals header | `scripts/hud.gd`, tests | yes | low |
| SG-4 | opening milestones (first cell, first stores, first egg) lead the player to the first worker | `scripts/colony_milestones.gd`, `scripts/main.gd`, tests | yes | low |

SG-1 supplies the standalone catalogue and rules. SG-2 and SG-3 are Claude lane, after Work
Priorities (Dave's order, 13 Oct 2026: tier 3, then short-term goals, then
Easy); they should land back to back, since SG-2 alone pays rewards the
player cannot yet see. GP-2 added stars to the drop-down GP-1 built
(both landed 13 Oct 2026). Do not change milestones, urgent problems or the
Challenge goal shelf's behaviour.

**Reads.** A slice reads its own section only; SG-2 also reads
`.claude/rules/saving.md`, SG-3 `plans/reference/ui-rules.md`.

**Code health (`plans/now/code-health.md`, 18 Oct 2026).** Its save moves (CQ-S1 to CQ-S5, CQ-R2) wait for this plan's slices that edit `scripts/save_game.gd`/`scripts/saving.gd` (SG-2); add new save fields the current way, and the round-trip goldens of CQ-S0 are re-captured by whichever slice adds a field.

## Not in the queue, and why

SG-3's gate cleared when SG-2 landed (26 Oct 2026).
CQ-S0b (`plans/now/code-health.md`) also edits `scripts/saving.gd`'s bee
restore, and DR-1 (`plans/now/drones.md`) both save files; whichever is
queued first runs first.

SG-1 shipped 2026-10-14; its specification is `plans/archive/SG-1_2026-10-14.md`.

## SG-2 -- goals offered, completed and paid in Colony Runs and Scenarios, and saved

<!-- LAYER: immediate-task -->

**Change.** `year_winter.gd::_refresh_signals` builds the facts on its
one-second refresh, after its Challenge early return, in a Colony Run or
Scenario, and passes them to SG-1's functions; never per frame. Gross daily
income per resource is counted where income already is (`main.gd`). A finished goal
pays its reward into the hive's stores. `GameConfig` gains the reward
fraction (0.25) and the few/many thresholds; a headless sweep over the
reference Colony Run records, in this section, how often each goal is
offered and finished and what it pays, and sets the thresholds to decision
4's intent. Offered, dismissed and finished goals are saved as an additive
field; a save without it starts with none.

SG-1's `available(facts, state, day, thresholds, reward_fraction)` returns
entries for vacant slots. `accept` records one; `dismiss` leaves its slot
empty until the next day; `progress(entry, facts, state, day, thresholds,
at_day_change)` records a whole-day condition from a day boundary; `finish`
removes the entry and returns the reward fixed at offer. Facts add
`net_daily_income` and `gross_daily_income` resource maps, `built_cells`,
`winter_coming` and `winter_ready` to the diagnostics snapshot. Thresholds
are `few_free_cells`, `many_waiting_bees` and `few_waiting_bees`.

**Where the facts come from** (architecture review, 15 Oct 2026; decision 1
says no second condition evaluator). Each added fact already has one
authority in `conditions.gd`; read it there, never recompute it.

- `conditions.gd` gains two public wrappers and one leaf, and nothing else:
  `income(main, resource, days) -> Dictionary` returns `_net_income`'s result
  (`{net, collected}`, or `{}` while the window is not full), and
  `built_cell_count(main) -> int` returns `_built_cell_count`. The milestone
  leaves keep their behaviour.
- `net_daily_income[r]` is `income(main, r, 1).net`; `gross_daily_income[r]`
  is its `collected`. Nectar and pollen are already sampled
  (`main.gd::_sample_day_stores`, from `hive.gd`'s lifetime counters).
  Honey has no counter yet: `hive.gd::record_collection` gains a `"honey"`
  branch adding to a new `lifetime_honey_made`; `bee_honey.gd::honey_deposit`
  calls it with the amount each deposit adds to the cell (the change in
  `bee.honey_load`); `_sample_day_stores` adds `"honey"` (`hive.total`) and
  `"honey_collected"` (`lifetime_honey_made`), so `_net_income`'s
  `resource + "_collected"` reads honey unchanged.
- **The window is not saved.** `day_store_totals` refills over the first day
  of a run and after every load, and `income()` returns `{}` until it does.
  A resource with no window is left out of both income maps, and
  `short_term_goals.gd` treats a missing key as unknown, not zero:
  `available` offers no goal whose resource's gross income is missing (the
  reward is fixed at offer, so it would pay nothing), and `_trigger` and
  `progress` for `pollen_surplus` neither offer nor advance on a missing net.
  Today `_trigger` reads a missing net as 0.0, which would offer "Build a
  pollen surplus" on every load.
- `built_cells` is `built_cell_count(main)`.
- **Winter on track** (Dave, 15 Oct 2026, architecture review D1: option B).
  `conditions.gd` gains a `winter_on_track` leaf in `_met_key`, backed by a
  new `_winter_on_track(main) -> bool`: false unless `Session.winter_coming`
  and not `Session.winter_here`; otherwise the same forecast comparison
  `_winter_ready` makes (`held_energy >= required_energy` from
  `main.year_winter._winter_forecast(bees)`, bees counted as `_winter_ready`
  counts them) on **any** countdown day, with no `days_left` gate.
  `_winter_ready` keeps its last-day rule unchanged, so the CR-2 milestone
  and every Challenge or scenario spec reading `winter_ready` behave as
  before; it may call `_winter_on_track` after its `days_left` check. The
  SG-1 fact keeps its name: `facts.winter_ready` is
  `Conditions.met(main, {"winter_on_track": true})`, so "Lay in honey for
  winter" finishes on the first day the comb holds what winter needs, and
  `short_term_goals.gd` is unchanged by this. `winter_coming` is
  `Session.winter_coming`.

**As built (26 Oct 2026).** The goals' state is `main.gd::short_term_goals`
(with `short_term_goal_day`, which marks the first refresh of a new day as
the day boundary); `year_winter.gd::_refresh_short_term_goals` runs after the
Challenge early return and also skips levels 1 and 2, so a finished Challenge
offers none either. A finished goal pays through `hive.gd::pay_reward`, which
fills cells as `deposit` does but puts honey in ripe, so a honey reward never
re-wets a ripe cell. The goals write nothing to the session log: the sweep
counted offers and finishes through a temporary trace line in
`_refresh_short_term_goals`, not kept, since an action line in every
non-Challenge scenario fails the scenario tests that reject any action not
"accepted" (`test_col6_winter_skip`, `test_rr1_queen_builds`,
`test_t2_1_comb_miner_gate`). `_winter_ready` keeps its own copy of the
forecast comparison rather than calling `_winter_on_track`, because
`tests/test_conditions.py` pins that body's text. The save field is written only while the state is non-empty, so a run with
no goals saves exactly as before and the CQ-S0 goldens stand unchanged; the
goals' own round trip is `tests/test_sg2_short_term_goals.py`. The four
`GameConfig` values' settings rows (`goal_*`, World & start, persist none)
are in `scripts/settings_catalogue.gd`, which every `GameConfig` field needs.

**The sweep (26 Oct 2026).** Three seeds (20260923-25) of the reference
Colony Run, `test_scenarios/alpha_arc_test.json` (to day 43, the first winter
over), with the values below. Rewards are in the goal's own resource.

| Goal | Offered (per run) | Finished | Days open (median) | Reward at offer (min / median / max) | Paid per run | First offered (day) |
| --- | --- | --- | --- | --- | --- | --- |
| Build a pollen surplus | 8 (2.7) | 8 | 11 | 5.0 / 5.0 / 5.0 | 10.0 | 3, 3, 3 |
| Clear blocked work | 3 (1.0) | 3 | 0 | 5.0 / 5.0 / 5.0 | 5.0 | 26, 17, - |
| Make room | 10 (3.3) | 7 | 2 | 5.0 / 24.1 / 36.1 | 55.3 | 3, 3, 3 |
| Feed every larva | 0 | 0 | - | - | 0 | - |
| Put waiting bees to work | 0 | 0 | - | - | 0 | - |
| Lay in honey for winter | 5 (1.7) | 2 | 0 | 5.0 / 5.0 / 5.0 | 3.3 | 29, 26, 21 |

The reference colony stays tiny (the queen alone to about day 20, at most
seven bees, five cells), so its pollen and honey income is a few units a day
and a quarter of it is close to nothing: before the floor, six of seven pollen
offers and every honey offer paid 0. **`goal_reward_floor` = 5** makes each
pay something while staying under a third of one forager's pollen load (15);
nectar rewards (Make room, 20-36) are the quarter-day figure itself. Pollen
paid less than offered (10.0 a run against 13.3 offered) because the five
cells were full when it landed: a full comb keeps the rest, by design.

The waiting-bees thresholds needed a larger colony than the reference one,
whose waiting count never passed one. In `test_scenarios/colony_30_bees_test.json`
(31 bees, a Scenario, seeds 1-3) six to eleven bees wait for work at some
point every day, so the first trial's 4 / 1 offered "Put waiting bees to
work" on day 3 of every run and never finished it, holding a slot for the
rest of the run. **`goal_many_waiting_bees` = 8, `goal_few_waiting_bees` = 4**
offer it once in three runs, finished after 11 days for 34.5 nectar, and
leave the second slot free for the others (pollen surplus 4 offers / 1
finished, Feed every larva 4 / 4, Make room 3 / 0 within the 20 short days).
**`goal_few_free_cells` = 1**: the reference colony sits at zero or one free
cell most of its run, and "Make room" asking for one more cell finished 7 of
10 times, two days after the offer. **`goal_reward_fraction` = 0.25**, as
decision 2 set it.

```queue
**[Claude] SG-2 -- goals offered, completed and paid in Colony Runs and Scenarios, and saved**
- Plan: `plans/now/short-term-goals.md` -- "SG-2 -- goals offered, completed and paid in Colony Runs and Scenarios, and saved"
- Files: `scripts/short_term_goals.gd`, `scripts/year_winter.gd`, `scripts/main.gd`, `scripts/conditions.gd`, `scripts/hive.gd`, `scripts/bee_honey.gd`, `scripts/game_config.gd`, `scripts/save_game.gd`, `scripts/saving.gd`, `test_scenarios/sg2_short_term_goals.json`, `tests/test_sg2_short_term_goals.py`
- Check: `python -m unittest tests.test_sg2_short_term_goals` passes (in a Colony Run with no pollen income the pollen goal is offered, and finishing it pays pollen worth about a quarter of a day's gross income; "Lay in honey for winter" can finish before the countdown's last day while the CR-2 winter milestone still waits for it; no goal is offered in Challenge 1 or 2; offered and finished goals survive save and restore; an old save loads with none); the sweep's table is recorded in this section; `.\tools\verify.ps1` is green
- Proof: `absent: scripts/save_game.gd :: short_term_goals`
- Next after: SG-3 -- the goals in the Goals drop-down, with progress, reward, star and Dismiss
```

## SG-3 -- the goals in the Goals drop-down, with progress, reward, star and Dismiss

<!-- LAYER: immediate-task -->

**Change.** `hud.gd` shows each offered goal in GP-1's Goals drop-down,
under the milestone: its outcome, its progress, what it pays, GP-2's star,
and a Dismiss button reachable by keyboard. `colony_milestones.gd`'s
favourites restore keeps short-term ids. In a Scenario the drop-down shows
the short-term goals alone. Finishing one shows a brief completion note and a Dr Gallerin line
(`guidance_catalogue.gd`), shown once per goal per run. Goals never open a
modal or pause the game. The completion lines are their own table in
`guidance_catalogue.gd`, keyed by goal id, not rows of `ENTRIES`: `ENTRIES`
holds diagnostic explanations keyed by `ColonyDiagnostics` fact ids, and
`explanation()`'s evidence line covers only the two workforce facts (its
`else` branch is the comb one), so a goal row there would show comb evidence.

```queue
**[Claude] SG-3 -- the goals in the Goals drop-down, with progress, reward, star and Dismiss**
- Plan: `plans/now/short-term-goals.md` -- "SG-3 -- the goals in the Goals drop-down, with progress, reward, star and Dismiss"
- Files: `scripts/hud.gd`, `scripts/colony_milestones.gd`, `scripts/main.gd`, `scripts/guidance_catalogue.gd`, `test_scenarios/sg3_goal_shelf.json`, `tests/test_sg3_goal_shelf.py`
- Check: `python -m unittest tests.test_sg3_goal_shelf` passes (an offered goal appears in the Goals drop-down under the milestone with its progress and reward, in a Colony Run and in a Scenario; a starred goal stays when the drop-down is collapsed; Dismiss removes it and nothing replaces it until the next day; finishing one shows the completion note and the Dr line once); `.\tools\verify.ps1` is green
- Proof: `absent: scripts/hud.gd :: short_term`
- Next after: none -- the short-term goals plan is complete; ED-1 in `plans/now/difficulty.md` follows in Dave's order
```

## GP-5 -- a Goals button in the second HUD row replaces the Goals header

Level: low -- claude-sonnet-5-5 at low effort.

**True now.** Dave (C-131): "Have a goals button in the second HUD row (with
skills etc) instead of the goals header, selecting that opens and closes the
goals list". The second row is built in `hud.gd` (near l.836-865) from
`_icon_button(icon, label, TOP_BAR_BUTTON_WIDTH, tip)`; Skills sits at
about l.850. The Goals toggle is `goals_header`, a flat Button in `goal_shelf`
(near l.937), shown when the shelf shows (near l.1088), hidden in a Challenge
(near l.1035), labelled by `_apply_goals_collapsed` ("Goals [+]"/"Goals [-]",
near l.1092) and pressed through `_on_goals_header_pressed` (near l.1168),
which flips `Session.goals_collapsed` and calls `save_preferences()`.
SG-3 (`plans/now/short-term-goals.md`) also edits the Goals drop-down in
`hud.gd` and should rebase on this.

**When done:**

1. `hud.gd` adds `goals_button` to the second row beside Skills, text-only
   (or with an existing `UiIcon` if one fits), calling the same handler, with
   a tip "Opens and closes the Goals list." It is visible exactly when the
   header used to be, and registered with `_register_gated_control` so a
   Challenge's UI gates still apply.
2. `goals_header` is removed. `_apply_goals_collapsed` keeps hiding or showing
   the lines and favourites, and the button reads "Goals" with a pressed state
   for open. The saved `goals_collapsed` preference carries over unchanged.
3. `tests/gp1_goals_dropdown_test.gd` points at `goals_button`;
   `tests/test_layout_regression.py` passes with the extra button at the
   minimum supported width (800), the row not overflowing.
4. Dave's hands-on check is filed at closeout: press Goals in the second row,
   the list opens and closes, and a restart remembers the state.

**Invariants.** A Challenge's goal shelf is unchanged. No new setting. Follows
`plans/reference/ui-rules.md`.

**Open decisions:** none.

```queue
**[Claude] GP-5 -- a Goals button in the second HUD row replaces the Goals header**
- Plan: `plans/now/short-term-goals.md` -- "GP-5 -- a Goals button in the second HUD row replaces the Goals header"
- Files: `scripts/hud.gd`, `tests/gp1_goals_dropdown_test.gd`, `tests/test_layout_regression.py`
- Check: `python -m unittest tests.test_gp1_goals_dropdown` passes against `goals_button`; `python -m unittest tests.test_layout_regression` passes at the minimum width; `.\tools\verify.ps1` is green; Dave's hands-on check is filed
- Proof: `absent: scripts/hud.gd :: goals_button`
- Next after: none -- the Goals toggle move is complete
```

## SG-4 -- opening milestones lead the player to the first worker

Level: low -- claude-sonnet-5-5 at low effort.

**True now.** C-139 failed: "needs more incremental goals before 'Raise your
first worker'". `colony_milestones.gd` `MILESTONES` (near l.36) opens with
`first_worker`, so a new Colony Run's Goals line reads "Raise your first
worker" from the first second, with nothing between an empty hive and a
hatched bee. The shelf already shows the first unmet milestone only
(`show_next`). `evaluate()` runs on day change, a death, a gyne and a hatch
(`main.gd`, near l.676-697 and l.959), so a state-based step could show late.
`Conditions` already has `built_cells_at_least`, `hive_total` and
`brood_stage`, and `_brood_stage` takes `"egg"` (the winter-recovery
milestone uses it).

**When done:**

1. Three milestones go in front of `first_worker`, in this order, each shown
   alone until met (Dave, 24 Oct 2026):
   - `first_cell`, "Build your first cell": `{"built_cells_at_least": 1}`.
   - `first_stores`, "Bring in nectar and pollen": `all_of` of `hive_total`
     nectar and pollen, each `at_least` N. The implementer picks N by running
     `test_scenarios/alpha_arc_test.json`, printing the hive's nectar and
     pollen totals when the first egg is laid, and taking that figure rounded
     down (at least 1); the figure is written in the closeout.
   - `first_egg`, "Let the queen lay an egg":
     `{"brood_stage": {"stage": "egg", "at_least": 1}}`.
2. The steps evaluate promptly. No event fires today when a cell is finished
   or an egg is laid (`hive.gd` has only `storage_changed`, which covers
   stores but not the other two), so the cheapest hook is a one-second
   accumulator in `main.gd::_process`, next to where `Session.sim_time` is
   advanced, that calls `colony_milestones.evaluate()` only while a Colony Run
   has an unmet opening step. It stops once all three are met, so there is
   no steady per-frame cost.
3. The saved record is unchanged in shape: `restore()` drops unknown ids, and
   an older save missing the three ids loads them unmet and they tick on the
   next evaluate, since their conditions are state-based.
4. `tests/gp1_goals_dropdown_test.gd` (near l.84) and
   `tests/gp2_goal_favourites_test.gd` (near l.89 and l.105), which assert the
   "Raise your first worker" line at the start, assert "Build your first
   cell" instead, and a new case walks the four lines in order. The wording
   "six milestones" in `tests/test_conditions.py` and the milestone comment is
   brought up to nine.
5. Dave's hands-on check is the C-139 re-run: a first worker within about ten
   minutes, each step readable.

**Invariants.** Colony Run only; a Challenge and a Scenario shelf are
unchanged. No balance value. SG-3 (`plans/now/short-term-goals.md`, gated)
also edits `colony_milestones.gd`, `hud.gd` and `main.gd`: it rebases on this.

**Open decisions:** none.

```queue
**[Claude] SG-4 -- opening milestones lead the player to the first worker**
- Plan: `plans/now/short-term-goals.md` -- "SG-4 -- opening milestones lead the player to the first worker"
- Files: `scripts/colony_milestones.gd`, `scripts/main.gd`, `tests/gp1_goals_dropdown_test.gd`, `tests/gp2_goal_favourites_test.gd`, `tests/test_conditions.py`
- Check: `python -m unittest tests.test_gp1_goals_dropdown tests.test_gp2_goal_favourites tests.test_conditions` pass (a new run reads "Build your first cell", then the stores step, then the egg step, then "Raise your first worker", each within a second of its condition holding; a save without the three ids loads and ticks them); `.\tools\verify.ps1` is green; Dave's hands-on check is filed
- Proof: `absent: scripts/colony_milestones.gd :: first_egg`
- Next after: none -- the opening milestones are complete
```

## Open questions

None. The sweep in SG-2 sets the numbers decisions 2 and 4 leave to it.
