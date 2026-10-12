# Difficulty -- Easy rules, a Standard baseline, and the choice at run start

<!-- CONTEXT: plan | LAYER: active -->
Status: active | Owner: Dave / Claude Code | Next: decisions being recorded in the 12 Oct 2026 plan-ahead session; slices follow | Dependency: none to design; the save and menu slices wait for the Claude lane to release `scripts/save_game.gd`, `scripts/saving.gd` and `scripts/main.gd` | Verified: 2026-10-12

## Objective

`plans/design/product-scope.md` §6.1 lists "Easy difficulty rules, a
standard difficulty baseline" as essential for the closed alpha, and §11
writes Easy's rules. Nothing builds them. This plan makes Easy a real,
visible preset rule set, chosen at the start of a Colony Run or Scenario and
fixed for the run, and keeps Standard as today's game.

## Current state

Verified 12 Oct 2026 against master `06bd26c`:

- A bee dies in three ways: energy reaching zero (`bee_survival.gd::age_and_burn`
  and winter's `season.gd`, cause "starvation"), age past
  `lifespan_seconds` (which disease shortens), and a crab-spider ambush
  (`crab_spider.gd`, cause "crab spider ambush"). All go through
  `bee_survival.gd::die`. The queen never dies of old age; she can starve.
- There is no health stat.
- `scripts/scenario_presets.gd` gives the main menu's Scenario group
  Relaxed/Standard/Demanding/Custom presets: four `GameConfig` multipliers
  each, applied through `levels.gd::apply_config_overrides`. The Colony Run
  tile has no preset (`"presets": false`).
- Nothing records a run's difficulty in `Session` or the save.

## Decisions (Dave, 12 Oct 2026, plan-ahead session)

1. **Offered in the Colony Run and in Scenarios; chosen at run start; fixed
   for the run.** The Colony Run tile gains an Easy/Standard choice.
   Scenario's presets gain Easy's survival rules: Relaxed is Easy's rules
   plus Relaxed's numbers. Challenges are always Standard: they teach fixed
   lessons. The run's difficulty is saved with it; a save without one loads
   as Standard.
2. **Disease still shortens lives on Easy.** A disease-shortened life still
   ends as old age, which Easy allows. Easy blocks every other cause.
3. **Every bee has health, on every difficulty.** Two things lower it: a
   crab-spider ambush, and running out of energy (health then drains over
   time rather than the bee dying at once). Resting in the hive restores it.
   At zero health a bee dies on Standard; on Easy health stops at one. A
   worker at one health or without energy crawls home at 25% speed, rests,
   and leaves only once it clears minimum health and energy thresholds
   (product-scope §11). Intent for the drain: on Standard a bee out of
   energy lasts about half a game-day -- long enough to crawl home from
   mid-meadow and eat, short enough that a colony with empty stores still
   loses bees within a day. A headless sweep sets the `GameConfig` rate to
   that intent; it is not guessed. Health is saved per bee; a save without it loads
   every bee at full health.
4. **Brood is protected on Easy.** An unfed larva stops developing and
   waits; it resumes when fed. Neglect costs time, not lives. On Standard
   larvae starve as today.
5. **Standard changes in one way only: exhaustion.** A bee out of energy
   loses health over time instead of dying on the spot, so it may reach
   food first. Every other Standard outcome a headless scenario records
   today must still hold.
6. **Easy winter:** the one-step winter bill (`season.gd`) empties the
   stores as today, but the bees it cannot feed come through to spring at
   one health and no energy instead of dying, and crawl to food. A short
   winter costs a slow, weak spring, not a dead colony. No new balance
   value.
7. **Scenario presets:** Relaxed is Easy's rules plus Relaxed's numbers;
   Standard and Demanding use Standard's rules; Custom gains an "Easy rules"
   checkbox. No new preset name.

## Open questions

- Easy's "event timing follows player readiness more strongly than calendar
  day" needs the event director (`NEXTSTEPS.md`, "Not in the queue"), which
  has no design yet. It is out of this plan until that pass exists.
