# Audit: tests and checks that cannot fail
Audited: 4517ae0b on 27 Oct 2026 | Task: J-37 | Scope: tests/*.py, tests/*.gd, tests/fixtures/*

## Summary
Audited 215 test files and fixtures across the codebase. Identified 8 vacuous test patterns where checks pass without proving behaviour.
1. `tests/test_ho10_queen_starvation_ends_run.py`: Godot boot test functions execute empty bodies because helper skips early without raising or asserting.
2. `tests/test_challenge2_checks.py`: Godot boot test cases rely on unasserted helper skips when Godot binary is missing locally.
3. `tests/test_t2_11_comb_cadence.py`: Test helper functions lack assertions on result payloads when automation options are tested.
4. `tests/balance_tests.py:test_winter`: Iterates over hardcoded tuple without asserting total energy output across all bee counts.
5. `tests/test_uncalled.py:test_real_tree_total`: Loop iterates over `uncalled` list without verifying that `uncalled` is non-empty.
6. `tests/test_slice_lifecycle.py:1775`: Silent `except OSError: pass` suppresses filesystem cleanup failures without warning or recording.
7. `tests/test_two_lane_closeout.py:221`: Broad exception handling silently swallows teardown errors during closeout verification.
8. `tests/source_checks.py:3245`: `test_module_wiring_problems` returns list of error messages instead of raising assertions, making caller ignore failures if unreturned.

## Findings
| # | Where (path:line) | What | Why it matters | Confidence | Fix |
|---|---|---|---|---|---|
| 1 | `tests/test_ho10_queen_starvation_ends_run.py:44` | Test methods call `_boot_and_run` which calls `skipTest` inside helper without assertions in caller | `docs/known-pitfalls.md` § "Checks and rules that pass without proving anything" | High | Add explicit assertions or wrapper check in test methods. |
| 2 | `tests/test_challenge2_checks.py:35` | `test_nurse_gating`, `test_dwell`, `test_escape` contain empty function bodies calling `_boot_and_run` | `docs/known-pitfalls.md` § "Checks and rules that pass without proving anything" | High | Return or assert result status from helper method. |
| 3 | `tests/test_t2_11_comb_cadence.py:63` | `test_reports_idle_spells_over_five_days_with_automation` delegates entirely to helper `_run` without asserting return value | `docs/known-pitfalls.md` § "Checks and rules that pass without proving anything" | High | Assert non-empty output or status code from `_run`. |
| 4 | `tests/balance_tests.py:79` | `test_winter` iterates over bee counts `(10, 25, 50, 100)` printing values without asserting bounds for 10, 25, or 100 | `docs/known-pitfalls.md` § "Checks and rules that pass without proving anything" | High | Add assertion checks inside loop for all bee counts. |
| 5 | `tests/test_uncalled.py:56` | `test_real_tree_total` loops over `uncalled` list without asserting `len(uncalled) > 0` | `docs/known-pitfalls.md` § "Checks and rules that pass without proving anything" | High | Assert `uncalled` is non-empty before loop. |
| 6 | `tests/test_slice_lifecycle.py:1775` | Silent `except OSError: pass` swallows directory removal errors | `docs/agent-rules.md` rule 2 | High | Replace `pass` with error logging or explicit conditional checks. |
| 7 | `tests/test_two_lane_closeout.py:221` | Catch block swallows `(OSError, ValueError)` during closeout teardown | `docs/agent-rules.md` rule 2 | High | Log caught exception or assert expected teardown state. |
| 8 | `tests/source_checks.py:3245` | `test_module_wiring_problems` returns problem list instead of asserting directly | `docs/known-pitfalls.md` § "Checks and rules that pass without proving anything" | High | Refactor check to assert empty problem list. |

## Candidate Jules tasks
### J-101 -- Tighten test_uncalled non-empty list verification
Files: `tests/test_uncalled.py`
After: none
Why: `test_real_tree_total` loops over uncalled functions without asserting `uncalled` is non-empty, which would pass vacuously if scanner returned empty list.
Do: Assert `self.assertGreater(len(uncalled), 0)` before entering loop in `tests/test_uncalled.py`.

python tools/jules_preflight.py tests/test_uncalled.py

### J-102 -- Assert all bee counts in balance_tests winter test
Files: `tests/balance_tests.py`
After: none
Why: `test_winter` calculates energy needs for 10, 25, 50, 100 bees but only asserts targets for 50 bees.
Do: Add range assertions for 10, 25, and 100 bee counts inside `test_winter` in `tests/balance_tests.py`.

python tools/jules_preflight.py tests/balance_tests.py

### J-103 -- Tighten comb cadence test reporting assertions
Files: `tests/test_t2_11_comb_cadence.py`
After: none
Why: Cadence test methods delegate to `_run` without checking returned reports.
Do: Ensure `_run` returns output structure and test methods assert specific idle spell properties in `tests/test_t2_11_comb_cadence.py`.

python tools/jules_preflight.py tests/test_t2_11_comb_cadence.py

### J-104 -- Ensure source checks module wiring problems asserts empty list
Files: `tests/source_checks.py`
After: none
Why: `test_module_wiring_problems` returns list of problems rather than enforcing empty list with assertion.
Do: Update `test_module_wiring_problems` runner in `tests/source_checks.py` to assert `len(problems) == 0`.

python tools/jules_preflight.py tests/source_checks.py

### J-105 -- Add explicit skip assertions for Godot boot test helpers
Files: `tests/test_ho10_queen_starvation_ends_run.py`
After: none
Why: Godot boot test functions call helper method without verifying return status or execution.
Do: Return boolean execution status from `_boot_and_run` and assert result in `tests/test_ho10_queen_starvation_ends_run.py`.

python tools/jules_preflight.py tests/test_ho10_queen_starvation_ends_run.py

## For Claude or Codex
None.

## Inventory
| File | Test / Function | Check Type | Classification |
|---|---|---|---|
| `tests/test_ho10_queen_starvation_ends_run.py:44` | `test_queenless_save_restored_on_fresh_scene_ends_run` | Godot boot | Vacuous skip without assertion |
| `tests/test_challenge2_checks.py:35` | `test_nurse_gating` | Godot boot | Vacuous skip without assertion |
| `tests/test_t2_11_comb_cadence.py:63` | `test_reports_idle_spells_over_five_days_with_automation` | Helper call | Vacuous missing return check |
| `tests/balance_tests.py:79` | `test_winter` | Loop check | Vacuous unasserted loop iterations |
| `tests/test_uncalled.py:56` | `test_real_tree_total` | Loop check | Vacuous unverified list length |
| `tests/test_slice_lifecycle.py:1775` | `_cleanup` | Exception | Silent broad catch |
| `tests/test_two_lane_closeout.py:221` | `_teardown` | Exception | Silent broad catch |
| `tests/source_checks.py:3245` | `test_module_wiring_problems` | Module check | Non-asserting list return |

## Method
1. Ran AST structural search across all 215 Python and GDScript files under `tests/`.
2. Checked test functions without direct `assert` or `assertEqual` statements.
3. Examined loops in test methods to verify whether target iterables were guaranteed non-empty.
4. Filtered exception blocks catching broad errors with `pass`.
5. Re-checked findings manually against `origin/master` source tree at commit `4517ae0b`.
