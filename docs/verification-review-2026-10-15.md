# Verification, test and build health review -- 15 Oct 2026

<!-- CONTEXT: review-record | LOAD: on-demand -->
Reviewed: 0be134c | Since: b9854e5 | Scope: a full verify.ps1 run and the diagnostic log since the 14 Oct verify rebuild, follow-through of the 7 Oct record, scenarios nothing runs (with two mutation checks), the nine ready hands-on checks, and a real alpha build. Run on Windows with Godot 4.7.2, as a `/run-reviews` subagent | Previous: docs/verification-review-2026-10-07.md

## Follow-through

| Previous finding | Disposition |
| --- | --- |
| F1 -- verify.ps1 edited for every new test module | Shipped -- `$unitModules` globs `tests/test_*.py` (`grep -n unitModules tools/verify.ps1`); `check_test_modules_are_run` present. No merge since 7 Oct changed verify.ps1 only for a module list |
| F2 -- lifecycle suite is the cost of verify | Shipped -- and bettered by the 14 Oct rebuild (a212e42, 956e7a3, b03a2b0): lifecycle runs only when the branch touches lifecycle tooling, game tests only when a change reaches them |
| F3 -- fixture commit noise | Shipped -- no flood in any run seen |
| F4 -- newer-save guard could not fail | Shipped -- `tests.test_save_migrations` green in this run |
| F5 -- test `.gd.uid` files | Shipped -- `scripts_missing_uid` covers `tests/`; the boot left the worktree clean |
| F6 -- alpha build never worked | Shipped -- `tools/build_alpha.ps1` built a 39 MB zip in 31 s today |
| F7 -- flaky layout/timeouts | Rejected last run; the only failures since are 6 on one branch (below), no recurrence |
| Hand-offs of 7 Oct (finish lock, Codex sandbox) | Not mine to confirm; they live in the signal log |

## Findings

| Id | Finding | Evidence | Severity | Disposition |
| --- | --- | --- | --- | --- |
| F1 | `test_scenarios/gd2a_guidance.json` asserts the Why button is visible and clear of the bubble (GD-2a), but ran nowhere: `scenario_sweep.py` globs only `*_test.json` and no test names it. A mutation (`"visible": false`) makes it fail with `assert_failed`, so it can fail; nobody asked it to | `git grep gd2a_guidance -- tests tools` empty; `python tools/run_scenario.py` passes the file and fails the mutant | medium | Fixed -- renamed `gd2a_guidance_test.json`, so the sweep takes it. New `source_checks.py::check_asserting_scenarios_are_run` fails any asserting fixture that is not `*_test.json`, named in a test or listed (with a reason) in `SCENARIOS_RUN_BY_NOTHING`. Mutation: restoring the old name makes `python tests/source_checks.py` fail |
| F2 | Verify cost fell. Branch-scope unit stage on slices: 320-435 s (GP-4, PP-7, RR-6, SP-10); a docs-only branch 22 s; my full run 5 m 32 s with lifecycle skipped, 113 unit ids in 268 s. Before 14 Oct the unit stage was 675-746 s | `python tools/session_cost.py --events` (medians still show the old era); the diagnostic log filtered to 14 Oct 18:00 onward | info | Rejected -- no action; recorded so the next review compares against it |
| F3 | The only red stages since 7 Oct are 3 unit and 3 lifecycle failures on `verify-performance-optimization-3a7cae`, the branch that rebuilt verify, between 22:33 and 23:24 on 14 Oct (1,052-1,768 s each). That branch's own fixes (956e7a3, b03a2b0) answered them. Inference: they were load, from timeouts it then raised | Diagnostic log, stage `unit tests` | low | Rejected -- fixed on that branch; none on the next 6 runs. Revisit if a worker-count timeout recurs |
| F4 | Slowest tests in this run: `test_bb4_challenge_pacing.ChallengeTwoRouteTest` 71 s, `test_nf3_tipsy` 43 s, `ChallengeOneRouteTest` 42 s, `test_ho10` 38 s. Three workers share 268 s, so the longest single test is a quarter of the wall time | verify log `ok  <s>  tests.*` lines | low | Rejected -- each is a real route or arc; splitting would not shorten the wall time enough to pay for itself |
| F5 | Ready hands-on load fell from 19 to 9 checks, the oldest C-103 (2 Oct, 13 days). C-131 and C-132 both exercise the Goals drop-down (GP-1 and GP-2) and are both `Runner: dave` | `checks/ready/*.md` Runner lines, `git log --diff-filter=A` | low | Rejected -- both have different failure routes and C-131 includes a restart; a merge saves Dave a minute, not worth rewriting filed checks |

## Hand-offs

- **Plan review.** `check_docs.py` warns that `plans/now/sprites.md` is 326 lines (soft limit 260) and `check-loop.md` is 36 days past verification. Signal log: "2026-10-15 — `plans/now/sprites.md` is over its soft limit".

## Noted, not pursued

- The `is_on_screen` rule and the self-calling-function pitfall still have no guard; no break since 7 Oct.
- `hive_comb_spiral_repro` asserts, runs nowhere and ends on `max_days` today (status=failed); it is now listed in `SCENARIOS_RUN_BY_NOTHING` with that reason.
- `foraging_evidence_*`, `proximity_recruitment_evidence_x2`, `recommendation_slice*`, `spr1/2_render_*` carry no assertions: evidence runs, correctly outside the sweep.
- `session_cost.py --events` medians still blend the pre- and post-14 Oct eras; read the filtered log for current cost.
- A Godot import leaves `.import` line-ending noise (unchanged); `godot-copy-all-errors-*/` is now excluded from the export by `exclude_filter`.

## Not reviewed

- The long scenarios outside the sweep, and a full `scenario_sweep.py` run (a large headless batch; only the two fixtures in F1 were run).
- Whether the 36-day-old `check-loop.md` still matches practice.

## Patterns deliberately not applied

- No verify stage for the scenario sweep (Dave, 30 Sep 2026): F1's guard is a static source check, not a run.
- `$testsNotInVerify` stays empty-by-default with reasons written down (7 Oct decision).
