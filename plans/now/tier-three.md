# Tier three -- skills over behaviour that already ships

<!-- CONTEXT: plan | LAYER: active -->
Status: active | Owner: Dave / Claude Code | Next: T3-1 and T3-2, specified below once the plan-ahead session of 13 Oct 2026 closes | Dependency: both slices touch `scripts/skills.gd`, which PP-5 (Claude lane) holds | Verified: 2026-10-13

## Objective

`plans/design/progression.md` §11 step 13 lists the tier-3 content. Two of
its nodes, Weighted flower choice (Foraging) and Restocking (Colony), cover
behaviour the game already has, which nothing gates. As tier 2 did for the
five behaviours that existed (`plans/now/tier-two.md`), they become
purchases. Priority cells and Pollinator points belong to
`plans/now/pollination.md`; Work Priorities to `plans/now/work-priorities.md`.

## Current state

Verified 13 Oct 2026 against master `06bd26c`:

- Weighted flower choice is `bee_foraging.gd::_weighted_flower_choice`,
  used only while `GameConfig.probabilistic_choice_on` is true. That
  defaults to false and is a player setting ("Weighted flower choice",
  `settings_catalogue.gd`). Its node is status "new" in `skills.gd`; its
  prerequisite, Associative learning, landed as T2-6.
- Restocking is the Comb worker's "Stocking" mode (`roles.gd`, mode key
  `restock`) and the orders that keep a cell full of one resource
  (`orders_zones.gd`). Its node is status "existing" but no mode or order
  checks ownership. Other gated modes carry a `"skill"` key in `roles.gd`.

## Decisions (Dave, 13 Oct 2026, plan-ahead session)

1. **Weighted flower choice: the skill drives it.** Owning the skill turns
   weighted choice on for that run; unowned, bees pick nearest-first as
   today's default does. The setting moves behind Developer mode as a
   force-on for testing.
2. **Restocking: no stocking orders without it.** Unowned, the Stocking mode
   and the keep-full orders are hidden, as other skill-gated modes are.
   Keep-empty orders and Clearing stay free (Cleaning, tier 2, already gates
   clearing). Headless scenarios that set stocking orders are granted the
   skill.
