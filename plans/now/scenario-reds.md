# Scenario reds -- the four red scenarios and the red SF-1 test

<!-- CONTEXT: plan | LAYER: immediate-task -->
Status: active | Owner: Dave / Codex | Next: None — plan complete (SR-5 landed 4 Oct 2026: the SF-1 flower-mix test passes and runs in verify; SR-4 landed earlier with hands-on check C-103 filed); no follow-ups filed | Dependency: none -- UI-F-2's warning changes accompany this five-slice lane refill | Verified: 2026-10-04

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

All five run in the Codex lane and share no file with the Claude lane
(BS-9, L-16, L-17). SR-2 and SR-4 both list `scripts/scenario_actions.gd`
and SR-4 shares `scripts/hud.gd` with UI-F-2; one lane worked top to bottom
never has two of them open. SR-4 and SR-5 were chosen by Dave on 1 Oct 2026
("chase it"; "a diagnosis slice"). A slice reads its own section and
nothing else. SR-4 moved to the Claude lane (Dave, 2 Oct 2026): SC-4
(`plans/archive/settings-and-corner_2026-10-03.md`) and UT-4
(`plans/archive/ui-texture-polish_2026-10-03.md`) share `scripts/hud.gd` with it, so they
queue behind it in that one lane, and UT-5 follows them.

SR-1 shipped 2026-10-02; its specification is `plans/archive/SR-1_2026-10-02.md`.

SR-2 shipped 2026-10-02; its specification is `plans/archive/SR-2_2026-10-02.md`.

SR-3 shipped 2026-10-02; its specification is `plans/archive/SR-3_2026-10-02.md`.

SR-4 shipped 2026-10-02; its specification is `plans/archive/SR-4_2026-10-02.md`.

SR-5 shipped 2026-10-04; its specification is `plans/archive/SR-5_2026-10-04.md`.
