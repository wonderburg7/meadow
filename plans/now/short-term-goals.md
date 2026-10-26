# Short-term goals -- optional outcomes the colony's state suggests

<!-- CONTEXT: plan | LAYER: active -->
Status: active | Owner: Dave / Claude Code | Next: SG-3 -- the goals in the Goals drop-down, with progress, reward, star and Dismiss (startable now SG-2 has landed; it should follow straight on, since SG-2 alone pays rewards the player cannot see) | Dependency: SG-2 landed 26 Oct 2026; GP-2 landed 13 Oct 2026; GP-5 landed 26 Oct 2026 | Verified: 2026-10-26

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
| SG-3 | The goals in the Goals drop-down, with progress, reward, star and Dismiss | `scripts/hud.gd`, `scripts/colony_milestones.gd`, `scripts/main.gd`, `scripts/guidance_catalogue.gd`, `test_scenarios/sg3_goal_shelf.json`, `tests/test_sg3_goal_shelf.py` | yes -- SG-2 landed 26 Oct 2026 | medium |

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

SG-2 shipped 2026-10-26; its specification is `plans/archive/SG-2_2026-10-26.md`.

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

GP-5 shipped 2026-10-26; its specification is `plans/archive/GP-5_2026-10-26.md`.

SG-4 shipped 2026-10-26; its specification is `plans/archive/SG-4_2026-10-26.md`.

## Open questions

None. The sweep in SG-2 sets the numbers decisions 2 and 4 leave to it.
