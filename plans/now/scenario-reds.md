# Scenario reds -- the four red scenarios and the red SF-1 test

<!-- CONTEXT: plan | LAYER: immediate-task -->
Status: active | Owner: Dave / Codex | Next: SR-5 -- the SF-1 flower-mix test passes, or is shown to be a simulation question (Codex lane); SR-4 is built on branch claude/SR-4 (the settle chain stopped inside one deferred flush before the content finished re-wrapping; the tray now re-applies on the content's minimum_size_changed; hands-on check C-103 filed) | Dependency: none -- UI-F-2's warning changes accompany this five-slice lane refill | Verified: 2026-10-02

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
| SR-5 | the SF-1 flower-mix test passes, or is shown to be a simulation question | `tests/test_sf1_founding_flower_mix.py`, `tests/source_checks.py`, `test_scenarios/sf1_founding_flower_mix_test.json`, `tools/verify.ps1` | yes | medium |

All five run in the Codex lane and share no file with the Claude lane
(BS-9, L-16, L-17). SR-2 and SR-4 both list `scripts/scenario_actions.gd`
and SR-4 shares `scripts/hud.gd` with UI-F-2; one lane worked top to bottom
never has two of them open. SR-4 and SR-5 were chosen by Dave on 1 Oct 2026
("chase it"; "a diagnosis slice"). A slice reads its own section and
nothing else. SR-4 moved to the Claude lane (Dave, 2 Oct 2026): SC-4
(`plans/archive/settings-and-corner_2026-10-03.md`) and UT-4
(`plans/now/ui-texture-polish.md`) share `scripts/hud.gd` with it, so they
queue behind it in that one lane, and UT-5 follows them.

SR-1 shipped 2026-10-02; its specification is `plans/archive/SR-1_2026-10-02.md`.

SR-2 shipped 2026-10-02; its specification is `plans/archive/SR-2_2026-10-02.md`.

SR-3 shipped 2026-10-02; its specification is `plans/archive/SR-3_2026-10-02.md`.

SR-4 shipped 2026-10-02; its specification is `plans/archive/SR-4_2026-10-02.md`.

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
- Files: `tests/test_sf1_founding_flower_mix.py`, `tests/source_checks.py`, `test_scenarios/sf1_founding_flower_mix_test.json`, `tools/verify.ps1`
- Check: `python -m unittest tests.test_sf1_founding_flower_mix` passes with its `TESTS_NOT_IN_VERIFY` entry removed and `tools/verify.ps1` is green, or the slice stops with the evidence that the flower lifecycle is wrong
- Proof: `present: tests/source_checks.py :: "test_sf1_founding_flower_mix":`
- Next after: none -- plans/now/scenario-reds.md is complete
```
