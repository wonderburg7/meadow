# Scenario reds -- the four red scenarios and the red SF-1 test

<!-- CONTEXT: plan | LAYER: immediate-task -->
Status: active | Owner: Dave / Codex | Next: SR-1 -- a freed queen no longer breaks the problem messages (Codex lane, queued 1 Oct 2026) | Dependency: none -- UI-F-2's warning changes accompany this five-slice lane refill | Verified: 2026-10-01

**Objective.** Every short scenario in `python tools/scenario_sweep.py` is
green again, and the one exempt unit test either passes or its failure is
proved to be a simulation question for Dave. Source:
`docs/verification-review-2026-09-30.md`, Hand-offs (F4's four reds, and the
SF-1 test). Dave chose a sweep run by reviews rather than a verify stage
(F4), so nothing here adds a scenario to `tools/verify.ps1`.

**Current state** (each red rerun on this branch, 1 Oct 2026, with
`python tools/run_scenario.py <fixture>`): `forage_radius_wide_test` ends
`compile_error`, the other three `assert_failed`. SR-2's and SR-3's fixes
were tried on throwaway copies of their fixtures and both ended
`status=passed`.

| Slice | Outcome | Files owned | Startable | Level |
| --- | --- | --- | --- | --- |
| SR-1 | a freed queen no longer breaks the problem messages | `scripts/problem_messages.gd` | yes | low |
| SR-2 | the G3 fixture owns the Honey worker skill | `test_scenarios/g3_actions_offered_test.json`, `scripts/scenario_actions.gd` | yes | low |
| SR-3 | the disease-off fixture starts every bee newborn | `test_scenarios/h5_disease_off_test.json` | yes | low |
| SR-4 | the command tray fits its content after a resize to 800x600 | `scripts/hud.gd`, `scripts/ui_layout.gd`, `scripts/scenario_actions.gd`, `test_scenarios/uiw3_cell_tray_columns_test.json` | yes -- UI-F-2 closes with this refill | high |
| SR-5 | the SF-1 flower-mix test passes, or is shown to be a simulation question | `tests/test_sf1_founding_flower_mix.py`, `tests/source_checks.py`, `test_scenarios/sf1_founding_flower_mix_test.json` | yes | medium |

All five run in the Codex lane and share no file with the Claude lane
(BS-9, L-16, L-17). SR-2 and SR-4 both list `scripts/scenario_actions.gd`
and SR-4 shares `scripts/hud.gd` with UI-F-2; one lane worked top to bottom
never has two of them open. SR-4 and SR-5 were chosen by Dave on 1 Oct 2026
("chase it"; "a diagnosis slice"). A slice reads its own section and
nothing else. Two Claude-lane slices wait on this plan: UT-4
(`plans/now/ui-texture-polish.md`) for SR-4, which edits `scripts/hud.gd`,
and UT-5 for SR-2 and SR-4, which edit `scripts/scenario_actions.gd`.

## SR-1 -- a freed queen no longer breaks the problem messages

<!-- LAYER: immediate-task -->

Level: low (one file, two signatures).

**True now.** `problem_messages.gd::no_foragers(queen: Node2D)` and
`no_free_cells(bees: Array, queen: Node2D)` already handle a missing queen
with `is_instance_valid`, but the typed parameter raises first: Godot
refuses a previously freed object for a `Node2D` argument.
`year_winter.gd` builds the message state with `"queen": main.queen`, which
is a freed node once the queen has died, so `forage_radius_wide_test` logs
hundreds of `SCRIPT ERROR: Invalid type in function 'no_foragers'` lines
and ends `compile_error`.

**Done when.** Both functions take an untyped `queen` and keep their
`is_instance_valid` branch, so a dead queen gets the existing queenless
wording. Presentation only; no producer changes.

**Check.** `python tools/run_scenario.py test_scenarios/forage_radius_wide_test.json`
ends `status=passed`.

```queue
**[Codex] SR-1 -- a freed queen no longer breaks the problem messages**
- Plan: `plans/now/scenario-reds.md` -- "SR-1 -- a freed queen no longer breaks the problem messages"
- Files: `scripts/problem_messages.gd`
- Check: `python tools/run_scenario.py test_scenarios/forage_radius_wide_test.json` ends `status=passed`, and `tools/verify.ps1` is green
- Proof: `present: scripts/problem_messages.gd :: static func no_foragers(queen: Node2D)`
- Next after: SR-2 -- the G3 fixture owns the Honey worker skill
```

## SR-2 -- the G3 fixture owns the Honey worker skill

<!-- LAYER: immediate-task -->

Level: low (a fixture key and a comment).

**True now.** `g3_actions_offered_test` asserts `all_actions_available` on
day 1 with no skills owned. Since BS-3 made the honey actions need the bought
Honey worker skill, it fails with `honey_deposit_load (skill_not_owned)`,
`honey_fan_cell` and `honey_fetch_nectar`. The gate is intended; the fixture
is stale. The docstring above `scenario_actions.gd::_check_all_actions_available`
still calls "no skills owned" the "ordinary play is unchanged" invariant.

**Done when.** The fixture adds `"skill_grants": ["skill.brood.honey_worker"]`
(the run-definition key `run_availability.gd` reads), and the docstring says
the condition holds once the run owns the skills its actions need. The
condition itself does not change: it must still fail on any other refusal.

**Check.** `python tools/run_scenario.py test_scenarios/g3_actions_offered_test.json`
ends `status=passed`.

```queue
**[Codex] SR-2 -- the G3 fixture owns the Honey worker skill**
- Plan: `plans/now/scenario-reds.md` -- "SR-2 -- the G3 fixture owns the Honey worker skill"
- Files: `test_scenarios/g3_actions_offered_test.json`, `scripts/scenario_actions.gd`
- Check: `python tools/run_scenario.py test_scenarios/g3_actions_offered_test.json` ends `status=passed`, and `tools/verify.ps1` is green
- Proof: `absent: test_scenarios/g3_actions_offered_test.json :: skill.brood.honey_worker`
- Next after: SR-3 -- the disease-off fixture starts every bee newborn
```

## SR-3 -- the disease-off fixture starts every bee newborn

<!-- LAYER: immediate-task -->

Level: low (one fixture key).

**True now.** `h5_disease_off_test` sets a 10-day lifespan and asserts no
old-age death by day 7. Disease really is off (`season.gd::_advance_disease`
honours the level's `"disease": false`, so `lifespan_factor()` is 1), but
`GameConfig.starter_age_spread` (0.5) starts bees up to half-way through
their lives: bee 5 died of old age at 117.75 s aged 200.2 s, its full
lifespan. The fixture is stale, not the simulation.

**Done when.** The fixture's `config_overrides` sets
`"starter_age_spread": 0.0`, so any old-age death before day 10 can only
come from a shortened lifespan, which is what the test is for.

**Check.** `python tools/run_scenario.py test_scenarios/h5_disease_off_test.json`
ends `status=passed`.

```queue
**[Codex] SR-3 -- the disease-off fixture starts every bee newborn**
- Plan: `plans/now/scenario-reds.md` -- "SR-3 -- the disease-off fixture starts every bee newborn"
- Files: `test_scenarios/h5_disease_off_test.json`
- Check: `python tools/run_scenario.py test_scenarios/h5_disease_off_test.json` ends `status=passed`, and `tools/verify.ps1` is green
- Proof: `absent: test_scenarios/h5_disease_off_test.json :: starter_age_spread`
- Next after: SR-4 -- the command tray fits its content after a resize to 800x600
```

## SR-4 -- the command tray fits its content after a resize to 800x600

<!-- LAYER: immediate-task -->

Level: high (an ambiguous layout bug in `hud.gd`'s deferred settle chain).

**True now.** `uiw3_cell_tray_columns_test` passes its 1920x1080 asserts,
then after `viewport_size` 800x600 and 20 settle ticks fails
`matches_content`: the tray is 249 px tall at (300, 335), 200 px wide, and
its content wants 287 px. The ceiling is not the cause
(`ui_layout.gd::command_tray_max_height(600)` is far above 287).
`hud.gd::_on_viewport_size_changed` is connected, and `_resize_command_tray`
re-applies until `COMMAND_TRAY_SETTLE_STABLE_STREAK` reads agree. Dave
accepted "a residual few pixels" of settle drift on 10 Sep (the comment
above `COMMAND_TRAY_SETTLE_STABLE_STREAK`); 38 px is not that, and Dave
chose to chase it (1 Oct 2026). Unknown: whether the fault is the resize
path, the settle chain, the panel chrome HF-1 changed on 30 Sep, or the
harness's `viewport_size` action. The test passed when UI-X-3 shipped
(18 Sep), so bisecting between `b709238` and `master` is the cheap first
step.

**Done when.** The cause is named in the commit message and fixed where it
lives; the fixture's 800x600 asserts stay as they are. If the cause is in
Godot's own layout timing and needs another bounded compromise, stop and
give Dave the options (CLAUDE.md rule 5) rather than loosening the assert.

**Check.** `python tools/run_scenario.py test_scenarios/uiw3_cell_tray_columns_test.json`
ends `status=passed`; Dave's hands-on check resizes the game window to its
smallest with a comb cell selected and sees the whole tray.

```queue
**[Codex] SR-4 -- the command tray fits its content after a resize to 800x600**
- Plan: `plans/now/scenario-reds.md` -- "SR-4 -- the command tray fits its content after a resize to 800x600"
- Files: `scripts/hud.gd`, `scripts/ui_layout.gd`, `scripts/scenario_actions.gd`, `test_scenarios/uiw3_cell_tray_columns_test.json`
- Check: `python tools/run_scenario.py test_scenarios/uiw3_cell_tray_columns_test.json` ends `status=passed` with its 800x600 asserts unchanged, and `tools/verify.ps1` is green
- Proof: `present: test_scenarios/uiw3_cell_tray_columns_test.json :: {"do": "viewport_size", "w": 800, "h": 600}`
- Next after: SR-5 -- the SF-1 flower-mix test passes, or is shown to be a simulation question
```

## SR-5 -- the SF-1 flower-mix test passes, or is shown to be a simulation question

<!-- LAYER: immediate-task -->

Level: medium (a bounded diagnosis with an escalation exit).

**True now.** `tests/test_sf1_founding_flower_mix.py` has been red since it
was added: flowers fall from 945 to 49 over 7 days and the out-of-season
share differs by 0.22 against a 0.05 tolerance.
`tests/source_checks.py::TESTS_NOT_IN_VERIFY` exempts it ("waits on its
owner"). SF-1 and SF-2 are archived (`plans/archive/SF-1_2026-09-19.md`,
`plans/archive/SF-2_2026-09-30.md`); SF-2 changed the flower season after
the test was written.

**Done when.** One of two outcomes, decided by evidence from the fixture's
own session log:

1. The test asserts something SF-2 deliberately changed: the test and
   fixture are brought in line with the archived SF-2 specification, it
   passes, and its `TESTS_NOT_IN_VERIFY` entry is removed.
2. The flower lifecycle does something neither plan intended: change no
   simulation code; stop and give Dave the evidence and the options (a
   gameplay outcome, CLAUDE.md rule 5).

**Check.** Outcome 1: `python -m unittest tests.test_sf1_founding_flower_mix`
passes and `python -m unittest tests.test_source_checks` passes without the
exemption.

```queue
**[Codex] SR-5 -- the SF-1 flower-mix test passes, or is shown to be a simulation question**
- Plan: `plans/now/scenario-reds.md` -- "SR-5 -- the SF-1 flower-mix test passes, or is shown to be a simulation question"
- Files: `tests/test_sf1_founding_flower_mix.py`, `tests/source_checks.py`, `test_scenarios/sf1_founding_flower_mix_test.json`
- Check: `python -m unittest tests.test_sf1_founding_flower_mix` passes with its `TESTS_NOT_IN_VERIFY` entry removed and `tools/verify.ps1` is green, or the slice stops with the evidence that the flower lifecycle is wrong
- Proof: `present: tests/source_checks.py :: "test_sf1_founding_flower_mix":`
- Next after: none -- plans/now/scenario-reds.md is complete
```
