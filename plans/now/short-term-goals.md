# Short-term goals -- optional outcomes the colony's state suggests

<!-- CONTEXT: plan | LAYER: active -->
Status: active | Owner: Dave / Claude Code | Next: decisions being recorded in the 13 Oct 2026 plan-ahead session; slices follow | Dependency: none to design; the HUD and save slices wait for the Claude lane to release `scripts/hud.gd`, `scripts/main.gd`, `scripts/save_game.gd` and `scripts/saving.gd` | Verified: 2026-10-13

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
2. **Finishing one gives a small resource reward.** No failure penalty
   (§7).
3. **Shown in the Colony Run and in Scenarios**, under the milestone shelf,
   so long-term, milestone, short-term and urgent read top to bottom.
   Challenges keep their own stage goals. Offered, dismissed and completed
   goals are saved with the run; a save without them starts with none.

## Open questions

Being asked in the same session.
