# Verification, test and build health review -- 7 Oct 2026

<!-- CONTEXT: review-record | LOAD: on-demand -->
Reviewed: b9854e5 | Since: 9ec0faf | Scope: verify.ps1 stage timings and failures from the diagnostic log (10 days, 1,593 stage events), the lifecycle suite's per-test durations, guard coverage of the rules files and known pitfalls, mutation spot-checks, unrun scenarios, the ready hands-on checks, and an attempted alpha export. Run on Windows with Godot 4.7.2 | Previous: docs/verification-review-2026-09-30.md

## Follow-through

| Previous finding | Disposition |
| --- | --- |
| F1 -- 15 test modules ran nowhere | Shipped -- `$unitModules` ran 27 modules; F1 below replaces the list with a glob |
| F2 -- three scenario asserts checked nothing | Shipped -- `source_checks.py::check_scenario_condition_keys` present and green |
| F3 -- `hook_log.py` SyntaxError before Python 3.12 | Shipped -- parses with `feature_version=(3, 10)` |
| F4 -- no stage runs a scenario | Shipped -- Dave's decision is in `tools/scenario_sweep.py`'s docstring |
| F5 -- scenario runner needed `%APPDATA%` | Shipped -- `run_scenario.py` reads `XDG_DATA_HOME` off Windows |
| F6 -- lifecycle suite cannot pass off Windows | Shipped -- `workflow_test_support.windows_powershell` |
| F7, F8, F9 | Rejected last run; no new evidence |
| Hand-off: sf1 red | Shipped -- c4cbb6a (SR-5) fixed it; it runs in verify |
| Hand-off: g3, h5 red | Shipped -- d040a58, 6f5e863 |
| Hand-off: forage_radius_wide, uiw3 red | Shipped -- both pass under `scenario_sweep.py --only` today |
| Hand-off: headless-run-contract pointer to the sweep | Rejected -- still absent and still the plan review's; repeated under Hand-offs |

## Findings

| Id | Finding | Evidence | Severity | Disposition |
| --- | --- | --- | --- | --- |
| F1 | Every slice that added a test module edited `verify.ps1`'s `$unitModules`. That put verify.ps1 in T2-1 to T2-3, COL-6, COL-11 and NF-2, so those slices could not sit in both lanes. The edit also set off the lifecycle suite: 12 of its 28 runs since 1 Oct were triggered by nothing else | `git log --first-parent --merges --since=2026-10-01 -- tools/verify.ps1`: 12 of 13 merges change only that line; `slice.ps1 owner tools/verify.ps1` named four queued slices | high | Fixed -- Dave chose it, 7 Oct. `$unitModules` now globs `tests/test_*.py`; `$testsNotInVerify` holds exemptions; `check_test_modules_are_run` fails if the glob goes (mutation: a listed set failed it). verify.ps1 removed from the six slices' Files lines, `plans/reference/slice-worker.md` and the 7 Oct signal |
| F2 | The lifecycle suite is the cost of verify: median 453 s, p90 735 s, run serially. Its trigger was all of `tools/` | `session_cost.py --events`; diagnostic log since 1 Oct; `unittest --durations`: 169 tests in 530 s. 8 of the 10 modules take 11 s together | high | Fixed -- Dave chose it, 7 Oct. The two heavy modules run as parallel jobs: 297 s alone; in the full verify run here 383 s and 258 s side by side, 395 s for the whole of verify, green. The 8 fast modules moved to the unit job. The trigger is now the files the fixtures copy (`verify.ps1::Test-LifecycleTouched`) |
| F3 | A failed lifecycle stage replayed about 270 lines of fixture `git commit` summaries into the agent's context | Suite output: 200 of 277 lines were `[branch sha] msg` / `create mode` | medium | Fixed -- `-q` on every fixture commit in `test_slice_lifecycle.py` and `test_two_lane_closeout.py`; each shard now prints 5 lines |
| F4 | The newer-save rejection guard could not fail. It searched the whole file for `return {}`, which appears elsewhere in `read()` | Deleting the branch's `return {}` in `save_game.gd::read` left `tests.test_save_migrations` green (35 OK) | medium | Fixed -- the test now finds the rejection branch and asserts its own `return {}`. The same mutation now fails it |
| F5 | Seven GDScript tests had no tracked `.gd.uid`, so every Godot boot left untracked files in the worktree. The uid check covered only `scripts/` | `git ls-files '*.gd'` against `*.gd.uid`; `source_checks.py::scripts_missing_uid` | medium | Fixed -- the check covers `tests/` too, with a unit test; the seven uids are committed |
| F6 | The alpha build has never worked on Dave's machine. `godot` is not on PATH. Godot.exe is a GUI program that returns without an exit code. PowerShell 5.1 under "Stop" aborted on Godot's first stderr line. The preset lacked `include_filter`/`exclude_filter`. The 4.7.2 export templates are not installed | `.\tools\build_alpha.ps1` gave "exit code ."; Godot_console.exe gave the filter-key errors, then "No export template found" | high | Fixed -- `build_alpha.ps1` resolves Godot the way `godot_compile_check.find_godot` does and prefers `Godot_console.exe`. It checks for templates first and says how to install them, and judges the export by exit code. Filter keys added; `test_alpha_build.py` guards all three. With stand-in templates the export packed a 2.2 MB archive. Installing the real templates is Dave's step |
| F7 | `test_layout_panels_fixture_passes` failed 6 times, and Godot-backed unit tests hit the 120 s scenario timeout 5 times, all on 1 and 3 Oct | Diagnostic log `verify_stage ok=false`, stage `unit tests` | low | Rejected -- none since 3 Oct across about 40 unit runs. The timeouts coincided with concurrent closeouts. F2's parallel jobs add load, so a recurrence is the signal to revisit |

## Hand-offs

- **Plan review.** `docs/headless-run-contract.md` still has no pointer to `tools/scenario_sweep.py`. PE-1 merged, so nothing is now waiting on it.
- **Agent workflow review.** `finish` still holds the lifecycle lock through branch verification. F2 cuts how long it holds it, but not the coupling.
- **Agent workflow review.** The Codex sandbox probe fails resolving its home directory before Godot launches (Codex feedback, 7 Oct). It is an environment decision.

## Noted, not pursued

- The rule "presentation may be skipped; simulation may not" has no guard. `is_on_screen` is called in 7 `bee.gd` functions, and no break is recorded.
- The pitfall "a refactor leaves a function calling itself" has no guard. It broke once (PERF plan).
- Five fixtures are run by nothing: `foraging_evidence_base`, `hive_comb_spiral_repro`, `proximity_recruitment_evidence_x2` and `recommendation_slice5_automation_off`/`_on`. The static key check still covers them.
- Hands-on load: 19 ready checks, 13 filed 2-4 Oct; the oldest, C-60 (panel texture), waits 18 days and is truly visual (UT-5 checks contrast arithmetic, not drawing). Every check states what a failure reopens.
- A Godot import rewrites 7 `assets/**/*.import` files with LF line endings, so a worktree reads dirty with an empty diff.
- `godot-copy-all-errors-*/` is a tracked copy of an editor addon at the repo root, and the export packs it.

## Not reviewed

- The 12 long scenarios outside the sweep.
- Whether C-81 (Nurse locked until bought) can be proved headlessly: the role menu has no scenario query today.
- A real-template alpha boot: it needs F6's install.

## Patterns deliberately not applied

- No verify stage for the scenario sweep (Dave, 30 Sep 2026), unchanged.
- The 30 Sep record kept an explicit module list "to keep each exemption's reason in view". F1's lane evidence reopened that decision. Exemptions are still written down, with reasons, in `$testsNotInVerify`.
