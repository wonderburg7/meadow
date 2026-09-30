# Verification, test and build health review -- 30 Sep 2026

<!-- CONTEXT: review-record | LOAD: on-demand -->
Reviewed: 9ec0faf | Since: first run | Scope: verify.ps1 stages and timings, tests/*.py, source checks, test_scenarios/ and the scenario runner, the alpha build configuration. Run with Godot 4.7 and PowerShell 7 on Linux | Previous: none

## Follow-through

None -- first run. Four hand-offs from the architecture, gameplay and product reviews of 30 Sep are findings F3, F5, F6 and F7 below.

## Findings

| Id | Finding | Evidence | Severity | Disposition |
| --- | --- | --- | --- | --- |
| F1 | 15 of 25 test modules ran nowhere; two were already red, a third (sf1) is in Hand-offs | `verify.ps1::$lifecycleModules` names 10 modules; `grep -rl test_<name>` finds no other runner. `test_signal_catalogue` asserted a `Callable(...)` line `_dispatch` replaced; `test_headless_efficiency_baseline` recorded 808 bytes for a profile now 884 (budget 1024) | high | Fixed -- `$unitModules` job in `verify.ps1` (72 tests, 36 s with Godot, 2 s without); both stale assertions repaired; `source_checks.py::check_test_modules_are_run` fails a module named in neither list nor in `TESTS_NOT_IN_VERIFY`. Mutation: a throwaway orphan test module failed the check. Layout, hc8 and hc16 (Godot, about 30 s) included per Dave's answer, 30 Sep |
| F2 | Three scenario asserts passed without checking anything | `scenario_actions.gd::_legacy_when_spec` dropped keys outside `LEGACY_WHEN_KEY_MAP`: `role_count` (bs3), `hive_total` (f2s), `built_cells_at_least` (e1). `e1`'s was also `at_least: 0`, true for any colony | high | Fixed -- unknown keys now go to `Conditions`, which fails them (`LOCAL_WHEN_KEYS` lists the local ones); `check_scenario_condition_keys` checks every fixture statically (mutation `role_countz` failed it); e1's vacuous line removed. Proof: bs3, f2s and e1 pass under Godot, and bs3 with 99 nurses now ends `assert_failed` |
| F3 | `hook_log.py` had a backslash in an f-string expression, a SyntaxError before Python 3.12; hooks logged nothing and 8 `DiagnosticWritersTest` tests failed | `python3 -m unittest tests.test_source_checks` on 3.11 | medium | Fixed -- split hoisted out of the f-string; 59 tests pass |
| F4 | No stage runs a scenario; 4 of 54 short scenarios are red | `python tools/scenario_sweep.py`: forage_radius_wide (`compile_error`), g3_actions_offered, h5_disease_off, uiw3_cell_tray_columns (`assert_failed`), all red on clean HEAD too | high | Decided -- Dave chose a sweep tool run by reviews, not a verify stage (54 scenarios take 188 s; verify takes 6 s). Written into `tools/scenario_sweep.py`'s docstring. The four reds are Hand-offs |
| F5 | `run_scenario.py::log_dir` needed `%APPDATA%`, so no scenario could be read on Linux; three tools found Godot three ways (`MEADOW_GODOT_PATH`, `GODOT_PATH`, a Windows-only default) | `python tools/run_scenario.py <any>` -> `status=crashed reason=environment` | medium | Fixed -- `log_dir` uses `XDG_DATA_HOME` off Windows; `find_godot` accepts both variables; `run_scenario --godot-path` and the four Godot tests use it |
| F6 | The lifecycle suite cannot pass off Windows: `slice.ps1` calls `Get-CimInstance`; 38 false failures in a cloud session (46 with F3), identical on HEAD | `MEADOW_LIFECYCLE_SUITE=1 python3 -m unittest tests.test_two_lane_closeout` | medium | Fixed -- `workflow_test_support.windows_powershell` returns None off Windows, so the modules skip (19 tests: OK, skipped=3) |
| F7 | A runtime `push_error` fails no headless run | `godot_compile_check.py::FAILURE_PATTERNS` matches four compile-time shapes (architecture hand-off; GDT-1 never queued) | medium | Rejected -- `SCRIPT ERROR` is matched and did fail forage_radius_wide. Adding `^ERROR:` would fail on `--import` noise and on the runner's own deliberate `bogus_key_not_allowed` message. A test that needs it names its own pattern |
| F8 | Test failure output can flood context: `assertIn(snippet, SOURCE)` prints the whole file (10 KB for signal_catalogue) | `python3 -m unittest tests.test_signal_catalogue` before the repair | low | Rejected -- 7 call sites, fires only on failure, and the failing one now asserts a short per-message string |
| F9 | The boot stage false-fails on a fresh checkout without `.godot` | First `verify.ps1` here: "Could not resolve script colony_panel.gd"; green after `godot --import` | low | Rejected -- observed once, on a cloud checkout; Dave's machine keeps its cache. A cloud session runs `godot --headless --path . --import` first |

## Hand-offs

- **Gameplay review.** `tests/test_sf1_founding_flower_mix.py` has been red since it was added (run at `934f06d` and at HEAD): flowers fall from 945 to 49 over 7 days, shares differ by 0.22 against 0.05. It is exempt in `TESTS_NOT_IN_VERIFY` until its owner decides whether the test or the flower lifecycle is wrong.
- **Gameplay review.** `g3_actions_offered_test`: `all_actions_available` fails with `honey_* (skill_not_owned)` since BS-3's gate went live (079c6c7); the fixture is probably stale. `h5_disease_off_test`: the assert fails at day 120 (`disease_at_most`, `event_count_at_most`, old-age deaths).
- **Gameplay or UI review.** `forage_radius_wide_test`: 487 `SCRIPT ERROR: Invalid type in function 'no_foragers'` lines: `problem_messages.gd::no_foragers(queen: Node2D)` receives a freed queen.
- **UI review.** `uiw3_cell_tray_columns_test`: `command_tray` is 249 px high, its content wants 287 px.
- **Plan review.** `docs/headless-run-contract.md` is owned by PE-1 (Codex lane); add a pointer to `tools/scenario_sweep.py` there when PE-1 merges.
- **Plan review.** The Claude lane holds 2 of 5 and the Codex lane 1 of 5 while admissible blocks wait (`check_docs.py` warning).

## Noted, not pursued

- `FUNCTION_MAP.md` was stale at HEAD; `verify.ps1` regenerates it (this branch carries the regenerated file).
- `input_selection.gd` (712 lines) has no `# --- section ---` header; `check_docs` warns on every run.
- The four Godot-backed tests still import `DEFAULT_GODOT_PATH`, `os` and `shutil`, which their resolver no longer uses.

## Not reviewed

- Stage timings from diagnostic events: the log held 10 headless events and no verify stages. Measured directly: verify 41 s here, 6 s without the Godot tests.
- Guard coverage of `.claude/rules/*.md` and `docs/known-pitfalls.md` (step 2), and mutation spot-checks beyond F1 and F2's own guards (step 3).
- Hands-on check load: 22 ready checks in `checks/ready.md`, not assessed for automation (step 5).
- The alpha export: `test_alpha_build.py` only reads text from `export_presets.cfg`, `.gitignore` and `build_alpha.ps1`; no export templates are installed here, so `build_alpha.ps1` was not run.
- The 12 long scenarios excluded by `scenario_sweep.py::LONG_RUNNING` (foraging campaigns, alpha arc, seeds, timescales).

## Patterns deliberately not applied

- No verify stage for the scenario sweep (Dave, 30 Sep 2026): cost against a 6 s verify.
- No auto-discovery of test modules in `verify.ps1`: an explicit list plus `check_test_modules_are_run` keeps each exemption's reason in view.
