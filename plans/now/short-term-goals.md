# Short-term goals -- optional outcomes the colony's state suggests

<!-- CONTEXT: plan | LAYER: active -->
Status: active | Owner: Dave / Claude Code | Next: SG-2 -- goals offered, met and paid in Colony Runs and Scenarios, and saved (Claude lane, gated), then SG-3 | Dependency: SG-2 waits for WP-3 (`plans/now/work-priorities.md`) in Dave's order (FC-2, `plans/archive/crisis-readiness_2026-10-17.md`, released the save files 17 Oct 2026); SG-3 waits for SG-2 (GP-2 landed 13 Oct 2026) | Verified: 2026-10-13

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
| SG-2 | Goals offered, completed and paid in Colony Runs and Scenarios, and saved | `scripts/short_term_goals.gd`, `scripts/year_winter.gd`, `scripts/main.gd`, `scripts/conditions.gd`, `scripts/hive.gd`, `scripts/bee_honey.gd`, `scripts/game_config.gd`, `scripts/save_game.gd`, `scripts/saving.gd`, `test_scenarios/sg2_short_term_goals.json`, `tests/test_sg2_short_term_goals.py` | no -- after WP-3 (SG-1 landed 14 Oct 2026; FC-2 released the save files 17 Oct 2026) | high |
| SG-3 | The goals in the Goals drop-down, with progress, reward, star and Dismiss | `scripts/hud.gd`, `scripts/colony_milestones.gd`, `scripts/main.gd`, `scripts/guidance_catalogue.gd`, `test_scenarios/sg3_goal_shelf.json`, `tests/test_sg3_goal_shelf.py` | no -- after SG-2 | medium |

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

SG-2 is gated until WP-3 lands in Dave's order (FC-2 released the save
files 17 Oct 2026). SG-3 waits for SG-2.

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

```queue-gated
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

```queue-gated
**[Claude] SG-3 -- the goals in the Goals drop-down, with progress, reward, star and Dismiss**
- Plan: `plans/now/short-term-goals.md` -- "SG-3 -- the goals in the Goals drop-down, with progress, reward, star and Dismiss"
- Files: `scripts/hud.gd`, `scripts/colony_milestones.gd`, `scripts/main.gd`, `scripts/guidance_catalogue.gd`, `test_scenarios/sg3_goal_shelf.json`, `tests/test_sg3_goal_shelf.py`
- Check: `python -m unittest tests.test_sg3_goal_shelf` passes (an offered goal appears in the Goals drop-down under the milestone with its progress and reward, in a Colony Run and in a Scenario; a starred goal stays when the drop-down is collapsed; Dismiss removes it and nothing replaces it until the next day; finishing one shows the completion note and the Dr line once); `.\tools\verify.ps1` is green
- Proof: `absent: scripts/hud.gd :: short_term`
- Next after: none -- the short-term goals plan is complete; ED-1 in `plans/now/difficulty.md` follows in Dave's order
```

## Open questions

None. The sweep in SG-2 sets the numbers decisions 2 and 4 leave to it.
