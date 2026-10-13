# Short-term goals -- optional outcomes the colony's state suggests

<!-- CONTEXT: plan | LAYER: active -->
Status: active | Owner: Dave / Claude Code | Next: SG-1 -- the goal catalogue and its rules, as a standalone module (Codex lane, queued 13 Oct 2026), then SG-2 and SG-3 (Claude lane) | Dependency: SG-2 waits for SG-1, for WP-3 (`plans/now/work-priorities.md`) in Dave's order, and for FC-2 (`plans/now/crisis-readiness.md`, Codex lane) to release the save files; SG-3 waits for SG-2 | Verified: 2026-10-13

## Objective

`plans/design/product-scope.md` §7 sets four goal layers. Long-term goals,
milestones (`scripts/colony_milestones.gd`, CR-2) and urgent problems
(`scripts/problem_messages.gd`) exist. Short-term goals -- optional,
context-sensitive outcomes such as "establish a pollen surplus", stating an
outcome rather than a click sequence, with no failure penalty -- do not.
§6.1 lists the goal layers as essential for the closed alpha.

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
   progress reuse `colony_diagnostics.gd` and `conditions.gd`, evaluated on
   the same hooks as milestones, never per frame.
2. **Finishing one gives a small reward in the goal's own resource**
   (a pollen goal pays pollen), worth about a quarter of a day of the
   colony's income of it, so it stays small for five bees or five hundred.
   No failure penalty (§7). "Income" here is gross production over the last
   day, not net: the pollen goal is offered when net income is at or below
   zero, where a net figure would pay nothing. The amount is fixed when the
   goal is offered and shown on it. A headless sweep confirms the quarter-day
   intent and sets any floor in `GameConfig`.
3. **Shown in the Colony Run and in Scenarios**, under the milestone shelf,
   so long-term, milestone, short-term and urgent read top to bottom.
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
| SG-1 | The six-goal catalogue and its offer, progress and reward rules, as a standalone module | `scripts/short_term_goals.gd`, `tests/sg1_short_term_goals_test.gd`, `tests/test_sg1_short_term_goals.py` | yes (Codex lane) | medium |
| SG-2 | Goals offered, completed and paid in Colony Runs and Scenarios, and saved | `scripts/short_term_goals.gd`, `scripts/main.gd`, `scripts/game_config.gd`, `scripts/save_game.gd`, `scripts/saving.gd`, `test_scenarios/sg2_short_term_goals.json`, `tests/test_sg2_short_term_goals.py` | no -- after SG-1 and WP-3, and once the Codex lane's FC-2 releases the save files | high |
| SG-3 | The goals under the milestone shelf, with progress, reward and Dismiss | `scripts/hud.gd`, `scripts/main.gd`, `scripts/guidance_catalogue.gd`, `test_scenarios/sg3_goal_shelf.json`, `tests/test_sg3_goal_shelf.py` | no -- after SG-2 | medium |

SG-1, then SG-2, then SG-3. SG-1 touches no file either lane holds, so it
runs in the Codex lane now. SG-2 and SG-3 are Claude lane, after Work
Priorities (Dave's order, 13 Oct 2026: tier 3, then short-term goals, then
Easy); they should land back to back, since SG-2 alone pays rewards the
player cannot yet see. Do not change milestones, urgent problems or the
Challenge goal shelf's behaviour.

**Reads.** A slice reads its own section only; SG-2 also reads
`.claude/rules/saving.md`, SG-3 `plans/reference/ui-rules.md`.

## SG-1 -- the goal catalogue and its rules, as a standalone module

<!-- LAYER: immediate-task -->

**Change.** A new `scripts/short_term_goals.gd`, data first, as
`colony_milestones.gd` is: the six goals of decision 4, each with an id, a
label stating the outcome, its trigger, its done test and its resource.
Static functions take a plain facts dictionary (the keys
`colony_diagnostics.gd::compute` returns, plus net and gross daily income
per resource, free cells and winter state) and a state dictionary, and
return: which goals may be offered (trigger holds, not already offered, not
dismissed or finished since the start of the current day), at most two;
whether an offered goal is done, counting "for a whole day" from the day
change its condition first held; and its reward, `fraction` times the gross
daily income of its resource, fixed at offer. Thresholds and the fraction
are arguments, not `GameConfig` reads, so SG-2 can wire them without this
slice touching `game_config.gd`. Nothing calls the module yet.

```queue
**[Codex] SG-1 -- the goal catalogue and its rules, as a standalone module**
- Plan: `plans/now/short-term-goals.md` -- "SG-1 -- the goal catalogue and its rules, as a standalone module"
- Files: `scripts/short_term_goals.gd`, `tests/sg1_short_term_goals_test.gd`, `tests/test_sg1_short_term_goals.py`
- Check: `python -m unittest tests.test_sg1_short_term_goals` passes (for fixture facts, each of the six goals is offered only while its trigger holds and never more than two at once; a dismissed goal is not offered again the same day; a whole-day goal is done only after a full day of its condition; the reward is the fraction times that resource's gross daily income, fixed at offer); `.\tools\verify.ps1` is green
- Proof: `absent: scripts/main.gd :: ShortTermGoals`
- Next after: SG-2 -- goals offered, completed and paid in Colony Runs and Scenarios, and saved
```

## SG-2 -- goals offered, completed and paid in Colony Runs and Scenarios, and saved

<!-- LAYER: immediate-task -->

**Change.** `main.gd` builds the facts on its existing day-change and
population-change hooks (never per frame) in a Colony Run or Scenario --
not in Challenges -- and passes them to SG-1's functions. Gross daily
income per resource is counted where income already is. A finished goal
pays its reward into the hive's stores. `GameConfig` gains the reward
fraction (0.25) and the few/many thresholds; a headless sweep over the
reference Colony Run records, in this section, how often each goal is
offered and finished and what it pays, and sets the thresholds to decision
4's intent. Offered, dismissed and finished goals are saved as an additive
field; a save without it starts with none.

```queue-gated
**[Claude] SG-2 -- goals offered, completed and paid in Colony Runs and Scenarios, and saved**
- Plan: `plans/now/short-term-goals.md` -- "SG-2 -- goals offered, completed and paid in Colony Runs and Scenarios, and saved"
- Files: `scripts/short_term_goals.gd`, `scripts/main.gd`, `scripts/game_config.gd`, `scripts/save_game.gd`, `scripts/saving.gd`, `test_scenarios/sg2_short_term_goals.json`, `tests/test_sg2_short_term_goals.py`
- Check: `python -m unittest tests.test_sg2_short_term_goals` passes (in a Colony Run with no pollen income the pollen goal is offered, and finishing it pays pollen worth about a quarter of a day's gross income; no goal is offered in Challenge 1 or 2; offered and finished goals survive save and restore; an old save loads with none); the sweep's table is recorded in this section; `.\tools\verify.ps1` is green
- Proof: `absent: scripts/save_game.gd :: short_term_goals`
- Next after: SG-3 -- the goals under the milestone shelf, with progress, reward and Dismiss
```

## SG-3 -- the goals under the milestone shelf, with progress, reward and Dismiss

<!-- LAYER: immediate-task -->

**Change.** `hud.gd` shows each offered goal under the milestone shelf: its
outcome, its progress, what it pays, and a Dismiss button reachable by
keyboard. Finishing one shows a brief completion note and a Dr Gallerin line
(`guidance_catalogue.gd`), shown once per goal per run. Goals never open a
modal or pause the game.

```queue-gated
**[Claude] SG-3 -- the goals under the milestone shelf, with progress, reward and Dismiss**
- Plan: `plans/now/short-term-goals.md` -- "SG-3 -- the goals under the milestone shelf, with progress, reward and Dismiss"
- Files: `scripts/hud.gd`, `scripts/main.gd`, `scripts/guidance_catalogue.gd`, `test_scenarios/sg3_goal_shelf.json`, `tests/test_sg3_goal_shelf.py`
- Check: `python -m unittest tests.test_sg3_goal_shelf` passes (an offered goal appears under the milestone shelf with its progress and reward; Dismiss removes it and nothing replaces it until the next day; finishing one shows the completion note and the Dr line once); `.\tools\verify.ps1` is green
- Proof: `absent: scripts/hud.gd :: short_term`
- Next after: none -- the short-term goals plan is complete; ED-1 in `plans/now/difficulty.md` follows in Dave's order
```

## Open questions

None. The sweep in SG-2 sets the numbers decisions 2 and 4 leave to it.
