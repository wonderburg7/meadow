# Tier three -- skills over behaviour that already ships

<!-- CONTEXT: plan | LAYER: active -->
Status: complete | Owner: Dave / Claude Code | Next: nothing further -- the plan is complete (T3-1 landed 13 Oct 2026, T3-2 on branch claude/T3-2) | Dependency: none (GP-1 and GP-2 landed 13 Oct 2026) | Verified: 2026-10-13

## Objective

`plans/design/progression.md` §11 step 13 lists the tier-3 content. Two of
its nodes, Weighted flower choice (Foraging) and Restocking (Colony), cover
behaviour the game already has, which nothing gates. As tier 2 did for the
five behaviours that existed (`plans/now/tier-two.md`), they become
purchases. Priority cells and Pollinator points belong to
`plans/now/pollination.md`; Work Priorities to `plans/archive/work-priorities_2026-10-22.md`.

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

## Open slices

| Slice | What it does | Files it owns | Startable | Level |
| --- | --- | --- | --- | --- |

T3-1 and T3-2 share no file and may land in either order; Dave's order
(13 Oct 2026) is tier 3 first -- this plan and Work Priorities
(`plans/archive/work-priorities_2026-10-22.md`) -- then short-term goals, then Easy. PP-6 (`plans/now/pollination.md`) prices tier-3 recipes, so landing
these first lets its sweep price them. Neither changes a skill's price.

**Reads.** A slice reads its own section only; T3-1 also reads
`.claude/rules/performance.md`, since flower choice is a per-trip path.

T3-1 shipped 2026-10-13; its specification is `plans/archive/T3-1_2026-10-13.md`.

T3-2 shipped 2026-10-14; its specification is `plans/archive/T3-2_2026-10-14.md`.
