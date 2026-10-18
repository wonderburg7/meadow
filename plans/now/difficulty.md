# Difficulty -- Easy rules, a Standard baseline, and the choice at run start

<!-- CONTEXT: plan | LAYER: active -->
Status: active | Owner: Dave / Claude Code | Next: ED-1 -- every bee has health, then ED-2 and ED-3, all gated (specified 13 Oct 2026) | Dependency: ED-1 waits for SG-3 (`plans/now/short-term-goals.md`) in Dave's order (FC-2, `plans/archive/crisis-readiness_2026-10-17.md`, released the save files 17 Oct 2026) | Verified: 2026-10-12

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

## Open slices

| Slice | What it does | Files it owns | Startable | Level |
| --- | --- | --- | --- | --- |
| ED-1 | Every bee has health; exhaustion drains it; spiders take it; rest restores it; a spent bee crawls home | `scripts/bee.gd`, `scripts/bee_survival.gd`, `scripts/bee_movement.gd`, `scripts/crab_spider.gd`, `scripts/game_config.gd`, `scripts/hud.gd`, `scripts/save_game.gd`, `scripts/saving.gd`, `test_scenarios/ed1_exhaustion.json`, `tests/ed1_health_test.gd`, `tests/test_ed1_health.py` | no -- after SG-3 (FC-2 released the save files 17 Oct 2026) | high |
| ED-2 | A run's difficulty, and Easy's rules: health floors at one, the queen cannot die, brood waits, winter spares | `scripts/session.gd`, `scripts/bee_survival.gd`, `scripts/bee_nursery.gd`, `scripts/season.gd`, `scripts/crab_spider.gd`, `scripts/save_game.gd`, `scripts/saving.gd`, `tests/ed2_easy_rules_test.gd`, `tests/test_ed2_easy_rules.py` | no -- after ED-1 | high |
| ED-3 | Choosing Easy: the Colony Run tile, Relaxed and Custom, and the Saves window | `scripts/main_menu.gd`, `scripts/scenario_presets.gd`, `scripts/main.gd`, `scripts/levels.gd`, `scripts/saves_panel.gd`, `tests/test_ed3_difficulty_choice.py` | no -- after ED-2 | medium |

ED-1, then ED-2, then ED-3: each needs the one before. Dave's order (13 Oct
2026) puts this plan last: tier 3 (`plans/archive/tier-three_2026-10-14.md`,
`plans/now/work-priorities.md`), then `plans/now/short-term-goals.md`, then
Easy. ED-1 changes Standard in one way only, exhaustion (decision 5);
nothing else Standard does may change. Challenges stay Standard.

**Reads.** A slice reads its own section only; ED-1 and ED-2 also read
`.claude/rules/simulation.md`, `.claude/rules/saving.md` and
`.claude/rules/performance.md` (health is per bee, per frame), ED-3
`plans/reference/ui-rules.md`.

## ED-1 -- every bee has health

<!-- LAYER: immediate-task -->

**Change.** `bee.gd` gains `health` (full at birth). `bee_survival.gd`: at
zero energy a bee no longer dies on the spot; it loses health at a rate set
so a bee lasts about half a game-day (decision 3), and dies at zero health.
A bee at zero energy, or at minimum health, moves at 25% speed
(`bee_movement.gd`) and heads home; inside it eats and rests, regaining
health, and leaves only once health and energy clear minimum thresholds.
`crab_spider.gd`: an ambush takes health -- all of it on every difficulty
for now, so Standard ambushes still kill. Rates and thresholds live in
`GameConfig`; a headless sweep (`ed1_exhaustion.json`) sets the drain to the
half-day intent and records its table here. The selection panel shows
health beside energy. Health is saved per bee; a save without it loads
every bee at full health. Every existing scenario still passes, or its
changed expectation is recorded here with the exhaustion reason.

```queue-gated
**[Claude] ED-1 -- every bee has health**
- Plan: `plans/now/difficulty.md` -- "ED-1 -- every bee has health"
- Files: `scripts/bee.gd`, `scripts/bee_survival.gd`, `scripts/bee_movement.gd`, `scripts/crab_spider.gd`, `scripts/game_config.gd`, `scripts/hud.gd`, `scripts/save_game.gd`, `scripts/saving.gd`, `test_scenarios/ed1_exhaustion.json`, `tests/ed1_health_test.gd`, `tests/test_ed1_health.py`
- Check: `python -m unittest tests.test_ed1_health` passes (a bee out of energy crawls at 25% speed, loses health and dies after about half a game-day unless it eats first; resting restores health and it leaves only past the thresholds; an ambush still kills; health survives save and restore and an old save loads at full health); the sweep's table is recorded in this section; `.\tools\verify.ps1` is green
- Proof: `absent: scripts/bee.gd :: var health`
- Next after: ED-2 -- a run's difficulty, and Easy's rules
```

## ED-2 -- a run's difficulty, and Easy's rules

<!-- LAYER: immediate-task -->

**Change.** `Session` gains the run's difficulty, `"standard"` or
`"easy"`, reset with the run and saved; a save without it loads as
Standard. On Easy: a worker's health stops at one (exhaustion and ambush
alike); the queen cannot die of anything; an unfed larva stops developing
and resumes when fed instead of starving (`bee_nursery.gd`); the winter bill
(`season.gd`) still empties the stores, but the bees it cannot feed reach
spring at one health and no energy. Old age, disease-shortened or not,
still kills (decision 2). On Standard nothing differs from ED-1. Until ED-3
nothing sets Easy except a headless scenario.

```queue-gated
**[Claude] ED-2 -- a run's difficulty, and Easy's rules**
- Plan: `plans/now/difficulty.md` -- "ED-2 -- a run's difficulty, and Easy's rules"
- Files: `scripts/session.gd`, `scripts/bee_survival.gd`, `scripts/bee_nursery.gd`, `scripts/season.gd`, `scripts/crab_spider.gd`, `scripts/save_game.gd`, `scripts/saving.gd`, `tests/ed2_easy_rules_test.gd`, `tests/test_ed2_easy_rules.py`
- Check: `python -m unittest tests.test_ed2_easy_rules` passes (on Easy an exhausted or ambushed worker stops at one health and crawls home; the queen survives starvation, ambush and winter; an unfed larva waits and then develops; a short winter leaves bees at one health, not dead; a bee past its lifespan still dies; on Standard every one of these behaves as ED-1; the difficulty survives save and restore and an old save is Standard); `.\tools\verify.ps1` is green
- Proof: `absent: scripts/session.gd :: difficulty`
- Next after: ED-3 -- choosing Easy: the Colony Run tile, Relaxed and Custom, and the Saves window
```

## ED-3 -- choosing Easy: the Colony Run tile, Relaxed and Custom, and the Saves window

<!-- LAYER: immediate-task -->

**Change.** The main menu's Colony Run tile offers Easy and Standard
(Standard selected by default). Scenario's Relaxed preset sets Easy's rules
as well as its numbers; Standard and Demanding set Standard; Custom gains an
"Easy rules" checkbox. Challenges always start Standard. The choice reaches
`Session` at run start (`main.gd`, `levels.gd`) and the Saves window shows
each run's difficulty. Each choice names Easy's rules in its tooltip, so
they stay visible preset rules (product-scope §11).

```queue-gated
**[Claude] ED-3 -- choosing Easy: the Colony Run tile, Relaxed and Custom, and the Saves window**
- Plan: `plans/now/difficulty.md` -- "ED-3 -- choosing Easy: the Colony Run tile, Relaxed and Custom, and the Saves window"
- Files: `scripts/main_menu.gd`, `scripts/scenario_presets.gd`, `scripts/main.gd`, `scripts/levels.gd`, `scripts/saves_panel.gd`, `tests/test_ed3_difficulty_choice.py`
- Check: `python -m unittest tests.test_ed3_difficulty_choice` passes (choosing Easy on the Colony Run tile, or Relaxed or Custom with Easy rules ticked, starts an Easy run; Standard, Demanding and both Challenges start Standard; the Saves window names each run's difficulty); `.\tools\verify.ps1` is green
- Proof: `absent: scripts/main_menu.gd :: easy_rules`
- Next after: none -- the difficulty plan is complete
```

## Open questions

- Easy's "event timing follows player readiness more strongly than calendar
  day" needs the event director (`NEXTSTEPS.md`, "Not in the queue"), which
  has no design yet. It is out of this plan until that pass exists.
