# Bee Bread -- fermented larval food, the tier-3 currency, and what it makes of a worker

<!-- CONTEXT: plan | LAYER: immediate-task -->
Status: active | Owner: Dave / Claude Code | Next: BB-4 -- Challenges 1 and 2 and the Colony Run re-paced for 15-day unfed workers, specified below and queued fifth in the Claude lane, after T2-7 sets the tier-2 prices it plays against | Dependency: none -- COL-4, NF-2, T2-2, T2-3, BB-1, BB-2 and BB-3 have landed | Verified: 2026-10-10

## Objective

`plans/design/progression.md` section 11, step 12 (Phase C): Bee Bread is
the Brood tier-2 node every tier-3 purchase needs, and
`plans/design/product-scope.md` section 6.1 lists its production, larval
use and adult consequences as essential for the alpha. The design is
`product-scope.md` section 9 with Dave's decisions of 6-7 Oct 2026 beneath
it (every run, old saves, about two days' ferment, a Fermenter mode, cells
like any store). This plan restates none of them.

## Current state

Verified 7 Oct 2026 against master; BB-1 (9 Oct 2026) has since built Bee Bread making, and BB-2's own section says what is true for it now:

- `skills.gd` reserves the resource key `BEE_BREAD` (tier 3's ladder row)
  and the node `skill.brood.bee_bread` (Brood tier 2, status `new`, so the
  tree marks it "Not built yet"). Weighted flower choice's recipe already
  names `BEE_BREAD`. Nothing makes it.
- Honey workers (`roles.gd` `HONEY`) have no modes; Miner's `automine` is
  the pattern a mode follows. `hive_cell.gd::designated_type` takes
  "nectar", "pollen", "honey" or "brood", explicit or set by a first
  deposit.
- Nurses (`bee_nursery.gd`) feed larvae pollen (`brood_feed_pollen`).
  Every worker lives `bee_lifespan_days` (25) at full speed and capacity.
  (BB-2, 10 Oct 2026, has since made nurses feed ripe Bee Bread in place of
  pollen and fixed each new worker's outcome at emergence.)
- Nectar fermentation (`plans/archive/nectar-fermentation_2026-10-10.md`) is a different
  mechanism -- raw nectar spoiling with age -- and shares only files.

## Open slices

| Slice | What it does | Files it owns | Startable | Level |
| --- | --- | --- | --- | --- |
| BB-4 | Challenges 1 and 2 and the Colony Run re-paced for 15-day unfed workers | `scripts/challenge_stages.gd`, `docs/challenge-stages.md`, `scripts/scenario_actions.gd`, `test_scenarios/bb4_challenge1_route.json`, `test_scenarios/bb4_challenge2_route.json`, tests | yes -- queued in the Claude lane behind T2-7 and T2-6 | medium |

**Dependencies.** BB-1, BB-2 and BB-3 have landed (BB-3 on 10 Oct 2026,
releasing `skill_tree_panel.gd`). BB-4 follows BB-2, whose rule it balances around, and T2-7
(`plans/now/tier-two.md`), whose tier-two prices the Challenges are played at. Every slice
changes balance, so each is simulated first with PE-2's arc
(`tools/pacing_gates.py`). Cross-plan: `plans/archive/nectar-fermentation_2026-10-10.md`
NF-2 and `plans/now/tier-two.md` T2-3, which had to land first, have, and
NF-5 (`plans/archive/nectar-fermentation_2026-10-10.md`), which shared `hud.gd`, landed
9 Oct 2026, and so did SP-3 (`plans/now/sprites.md`), which shared
`hive_cell.gd` and `bee.gd`. BB-2 released
`bee_nursery.gd` and `bee_survival.gd` to NF-4, `bee.gd` to CD-3
(`plans/now/diagnostic-readiness.md`) and the save files and `hud.gd` to
FC-2 (`plans/now/crisis-readiness.md`) on 10 Oct 2026;
`plans/design/progression.md` step 13 (tier-3 content) no longer waits on
this plan, and `plans/now/pollination.md` PP-2 waits only for PP-1, since
BB-3 landed 10 Oct 2026.

**Reads.** A slice reads its own section here and `product-scope.md`
section 9 (`python tools/heading.py plans/design/product-scope.md "9. Bee
Bread"`).

BB-1 shipped 2026-10-09; its specification is `plans/archive/BB-1_2026-10-09.md`.

BB-2 shipped 2026-10-10; its specification is `plans/archive/BB-2_2026-10-10.md`.

BB-3 shipped 2026-10-10; its specification is `plans/archive/BB-3_2026-10-10.md`.

## BB-4 -- Challenges 1 and 2 and the Colony Run re-paced for 15-day unfed workers

<!-- LAYER: immediate-task -->

**True now** (verified 10 Oct 2026 against master). A worker raised on
pollen alone lives `pollen_raised_lifespan_factor` (0.6: 15 of 25 days) at
`pollen_raised_stat_factor` (0.95) of speed and load
(`bee.gd::outcome_lifespan_days`); founders keep 25 days. Bee Bread needs
`skill.brood.bee_bread`, so every worker the Challenges raise is pollen-only.
Challenge 2's interim, completion, stability, failure and rescue thresholds
are the `C2_*` constants in `scripts/challenge_stages.gd`, whose comment
calls them "first guesses" made before BB-2; Challenge 1's are the `C1_*`
constants beside them. No fixture plays either Challenge through: the
Challenge fixtures jump stages with `advance_challenge_stage`, so nothing yet
says whether a stage is still reachable with 15-day workers. The Colony
Run's arc is `tools/pacing_gates.py` (PE-2), which T2-7 runs under BB-2's
rule when it prices tier two.

**True afterwards.**

- Two routes play the Challenges as a player would, with no
  `advance_challenge_stage` after their start: Challenge 1 from its first
  egg (1.16, where the queen lays the colony's first egg) to completion, and
  Challenge 2 from 2.1 (the nectar stores fall, then recover) to 2.9 (the
  full colony goal), hatching roles, buying Nurses, designating cells and
  mining with the actions `scripts/scenario_actions.gd` already has (it gains
  one only if a stage needs an action it lacks). Each route runs on three
  seeds under BB-2's rule, and as a control with both pollen-raised factors
  set to 1.0 by `set_config`, which is the colony from before BB-2. Each
  stage's reach day, for both, is recorded in this section.
- A stage is unreachable when the route under the rule has not reached it
  by twice the day the control did. Only such a stage's threshold moves, by
  the least that lets the route reach it on all three seeds; its goal text,
  `docs/challenge-stages.md` (`python tools/stage_reference.py`) and the
  "first guesses" comment then cite this evidence. If no stage is
  unreachable, no threshold moves and the comment says so.
- The Colony Run: `python tools/pacing_gates.py` is run once and its five
  rows recorded here. BB-4 changes nothing the Colony Run reads, so a gate
  out of band goes to Dave with its options (T2-7's or PP-6's prices, BB-2's
  factors) rather than being tuned here.
- Runtime: no repeating work is added; the slice adds fixtures, a test and
  constants.

**Must not change.** Any skill price (T2-7 and PP-6 own them; Dave, 10 Oct
2026); BB-2's five tunables and product-scope section 9's decisions behind
them; a threshold whose stage the route still reaches; the Colony Run's
gates.

**Out of scope.** Making BB-2's five tunables run settings. They are
`persist: "none"`; changing that adds them to `tests/source_checks.py`'s
`ORIGINAL_SAVED_SETTINGS`, which that file allows only as a deliberate
reclassification with its own save `FORMAT_VERSION` bump. That is a save
decision for Dave, open as of 10 Oct 2026, not part of a pacing slice.
Stage prompts and the Challenge UI are untouched.

```queue
**[Claude] BB-4 -- Challenges 1 and 2 and the Colony Run re-paced for 15-day unfed workers**
- Plan: `plans/now/bee-bread.md` -- "BB-4 -- Challenges 1 and 2 and the Colony Run re-paced for 15-day unfed workers"
- Files: `scripts/challenge_stages.gd`, `docs/challenge-stages.md`, `scripts/scenario_actions.gd`, `test_scenarios/bb4_challenge1_route.json`, `test_scenarios/bb4_challenge2_route.json`, `tests/test_bb4_challenge_pacing.py`
- Check: `python -m unittest tests.test_bb4_challenge_pacing` passes (each route, run once on its pinned seed, reaches its Challenge's completion under BB-2's rule with no stage jumped after its start, and the test reads the thresholds from `scripts/challenge_stages.gd` rather than restating them); the three-seed reach days under the rule and with both pollen-raised factors at 1.0, and `python tools/pacing_gates.py`'s five rows, are recorded in the plan; `python tools/stage_reference.py --check` is clean; `.\tools\verify.ps1` is green
- Proof: `present: scripts/challenge_stages.gd :: the rescue threshold -- first guesses`
- Next after: none -- Bee Bread is complete
```

## Outline

<!-- LAYER: design -->

- **BB-1.** A Honey worker mode "Fermenting", gated by
  `skill.brood.bee_bread`, seals pollen and honey into a `bee_bread` cell
  (designated, else the nearest empty one, which the first deposit marks).
  It ripens after a `GameConfig` duration of about two game-days; until
  then it is not food or currency. The recipe (pollen and honey per load,
  cell capacity) comes from a headless sweep. Per-cell ripening state is
  an additive save field; an older save has no Bee Bread. Runtime: ripening
  is read from the stamp on demand, like NF-2's age, never advanced per
  frame. The node's status becomes `existing`.
- **BB-2.** Nurses feed ripe Bee Bread when the colony holds it (pollen
  otherwise; Priority Cells, tier 3, later steers scarce supply). A larva
  fed it at least once (the ration is set by the sweep) emerges as a
  "with" worker: 25 days, 105% speed and capacity; otherwise "without":
  15 days, 95%. The outcome is a saved per-bee field; a save without it
  loads its adults as today's workers (25 days, 100%) for life.
- **BB-3.** `BEE_BREAD` joins the stores dictionary the resolver prices
  against, spent from ripe cells on purchase (section 4.2's rule: the
  recipe is spent).
- **BB-4.** With the rule in every run, Challenges 1 and 2's stage pacing
  and the Colony Run's arc are re-simulated; stage thresholds move only
  where the evidence says a stage became unreachable, and the affected
  hands-on checks are filed again. It never changes a skill price: T2-7
  (`plans/now/tier-two.md`, queued after BB-2) prices tier two against
  BB-2's rule (Dave, 10 Oct 2026). Follow-up from BB-2: its five tunables
  (`brood_feed_bee_bread`, `bee_bread_raised_lifespan_factor`,
  `bee_bread_raised_stat_factor`, `pollen_raised_lifespan_factor`,
  `pollen_raised_stat_factor`) are `persist: "none"` rather than `"run"`,
  because `"run"` needs each key added to `tests/source_checks.py`'s
  `ORIGINAL_SAVED_SETTINGS`. BB-4's section leaves that reclassification
  out as a save decision for Dave.
