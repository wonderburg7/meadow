# Audit: pitfall guard coverage
Audited: 058dcc3d on 27 Oct 2026 | Task: J-29 | Scope: docs/known-pitfalls.md, tests/, tools/, scripts/

## Summary

This audit evaluates the test, check, and tool enforcement across all 57 pitfall entries (15 section headings and 42 bullet items) in `docs/known-pitfalls.md`. Each pitfall was checked against unit tests, source checks (`tests/source_checks.py`), scenario assertions (`scripts/scenario_actions.gd`), and standalone tools (`tools/*.py`). Out of 57 entries, 20 are enforced by automated checks, 2 are partially enforced, and 35 are documentation-only rules or environment notes. 5 findings were identified regarding missing or partial guard coverage.

The five key findings are:
1. Direct `.size =`, `.set_size()`, and `.position =` assignments in UI layout code lack static lint enforcement (`docs/known-pitfalls.md:20`).
2. JSON parsed data passed to `Array.has()` or dictionary lookups without `int()` coercion is not statically checked (`docs/known-pitfalls.md:155`).
3. Blank labels (`text = ""`) remaining visible and consuming line height lack static AST checks (`docs/known-pitfalls.md:57`).
4. `theme_type_variation` omissions causing accessibility text scale mismatches are unmonitored by static analysis (`docs/known-pitfalls.md:65`).
5. Discrepancies between doc comments naming narrow cases and predicates testing wide cases have no automated consistency check (`docs/known-pitfalls.md:256`).

## Findings

| # | Where (path:line) | What | Why it matters | Confidence | Fix |
|---|---|---|---|---|---|
| 1 | docs/known-pitfalls.md:20 | `Control.set_size()` / `.position` setters in layout scripts lack AST check | "Control.set_size() destroys the anchor you set" (recursed 4 times in command tray) | High | Write static check `tools/layout_setter_check.py` to ban direct `.size =`, `.set_size()`, `.position =`, `.reset_size()` in `scripts/ui_panel_layout.gd`. |
| 2 | docs/known-pitfalls.md:155 | JSON number parsing with `Array.has()` or dict key lookup lacks type coercion check | "JSON numbers come back as floats, and Array.has() is type-strict" | High | Write static check `tools/json_has_int_check.py` verifying JSON parsed data passed to `.has()`, `.find()`, or dict keys is cast with `int()`. |
| 3 | docs/known-pitfalls.md:57 | Empty `Label` controls (`text = ""`) remaining visible and taking vertical layout space | "An empty Label is a full line tall" | High | Add scenario assertion or AST check flagging `text = ""` assignments in UI scripts without setting `visible = false`. |
| 4 | docs/known-pitfalls.md:65 | Omitted `theme_type_variation` on newly added UI controls | "A theme_type_variation left unset is not neutral" | High | Add static check verifying UI control constructors or factory helpers in layout rows specify a variation. |
| 5 | docs/known-pitfalls.md:256 | Discrepancies between doc comments naming narrow cases and predicates testing wide cases | "A restriction that lives in the comment and not in the predicate" | Medium | Add AST check or docstring-predicate alignment check for stage effect conditions. |

## Candidate Jules tasks

### S-3 -- Add layout setter check for control offset compliance
- Files: tools/layout_setter_check.py (new), tests/test_layout_setter_check.py (new)
- After: none
- Why: `docs/known-pitfalls.md` warns that `Control.set_size()` and direct position writes destroy control anchors in `scripts/ui_panel_layout.gd`, but no static check enforces offset-only modifications.
- Do: write `tools/layout_setter_check.py` to parse GDScript layout files and fail if `scripts/ui_panel_layout.gd` uses `.size`, `.set_size()`, `.position`, or `.reset_size()`. Add a unit test in `tests/test_layout_setter_check.py` covering passing and failing layout patterns.

```
free  tools/layout_setter_check.py
free  tests/test_layout_setter_check.py
```

### S-3 -- Add JSON integer coercion check for Array.has lookups
- Files: tools/json_has_int_check.py (new), tests/test_json_has_int_check.py (new)
- After: none
- Why: `docs/known-pitfalls.md` notes `JSON.parse_string` produces floats (`1.0`) which fail type-strict `Array.has(1)` lookups, but no check flags uncoerced JSON array lookups.
- Do: write `tools/json_has_int_check.py` to detect JSON-parsed array lookups missing explicit `int()` conversion before `.has()`, `.find()`, or dictionary key indexing. Add a unit test in `tests/test_json_has_int_check.py`.

```
free  tools/json_has_int_check.py
free  tests/test_json_has_int_check.py
```

## For Claude or Codex

None — all findings represent documentation or guard coverage gaps suitable for Jules standing tasks.

## Inventory

| Section / Item | Where (file & function) | Classification | Notes |
|---|---|---|---|
| ## UI layout and theme | none | documentation-only | Section heading grouping UI layout pitfalls. |
| Wrapping Label in HBox without expand flag | scripts/scenario_actions.gd:_check_no_collapsed_controls:1379 | enforced | Validated by scenario assertions in `tests/test_layout_regression.py`. |
| Control.set_size() destroys anchor | tests/source_checks.py:check_offset_rect_literals:180 | partial | Checks literal offset setters, but size/position assignment bans are documentation-only. |
| Container minimum size zero-triggers | scripts/scenario_actions.gd:_check_no_collapsed_controls:1379 | partial | Checked at runtime in scenario tests; no static AST check for `clip_text` wrapping buttons. |
| Rectangle with two owners / dead code | tools/uncalled.py:find_uncalled_functions:110 | enforced | Enforced by uncalled GDScript function analysis in `tests/test_uncalled.py`. |
| Empty Label is full line tall | none | documentation-only | Guidelines on setting visibility alongside text updates. |
| theme_type_variation left unset | none | documentation-only | Convention to assign type variation to all row controls. |
| Centring control with unequal reserves | none | documentation-only | Mathematical layout rule for reserved edges. |
| ScrollContainer child minimum width | scripts/scenario_actions.gd:_check_control_rect:1320 | enforced | Enforced by scenario assertions in `tests/test_layout_regression.py`. |
| ScrollContainer leaks child minimum on disabled scroll | tests/test_layout_regression.py:15 | enforced | Caught by Godot headless boot scenario assertions in `scripts/scenario_actions.gd`. |
| Shared theme scales variations not base types | none | documentation-only | Design rule for theme accessibility and text scaling. |
| Script _draw on StyleBoxFlat subclass | tests/source_checks.py:check_stylebox_no_script_draw:479 | enforced | Enforced by AST check in `tests/test_source_checks.py`. |
| Overlay placed on node origin instead of art | none | documentation-only | Sprite alignment guideline for selection overlays and markers. |
| ## GDScript language and editing | none | documentation-only | Section heading grouping language and editing traps. |
| Bulk renames hitting identifiers | tests/source_checks.py:check_declarations:42 | enforced | AST declaration and call verification catches syntax and identifier breaks. |
| JSON numbers come back as floats | none | documentation-only | Requirement to convert JSON numbers with `int()` before lookup. |
| Variable shadowing built-in properties | tools/gdscript_warnings.py:check_warnings:6 | enforced | Headless boot warning scraper fails on shadowed property warnings. |
| Typed Array[T] bare [] assignment | tools/typed_array_assign_check.py:check_typed_array_assignments:32 | enforced | Enforced by AST check in `tests/test_typed_array_assign_check.py`. |
| Leftover line surviving multi-step edit | none | documentation-only | Code review guideline to re-read whole function after edits. |
| ## Simulation and behaviour | none | documentation-only | Section heading grouping simulation bug classes. |
| Bee on State.IDLING never dispatches | none | documentation-only | Rule that role assignment or explicit order wake idling bees. |
| Coordinate spaces | none | documentation-only | Hive-local vs meadow-global coordinate conversion rule. |
| Nearest-thing searches picking standing tile | none | documentation-only | Spatial search exclusion requirement. |
| Commitments dropped on single frame | none | documentation-only | Hysteresis rule for state commitment checks. |
| Refactor leaves function calling itself | tools/self_call_check.py:check_self_calls:49 | enforced | Enforced by recursive call detector in `tests/test_self_call_check.py`. |
| Navigable-area loop one ring wider | none | documentation-only | Bound agreement rule between world building and navigation loops. |
| Marker reparented by some branches only | none | documentation-only | Single reparenting ownership rule for shared stage markers. |
| Bee under hive_root vs meadow flower coordinates | none | documentation-only | Space normalization rule before distance checks. |
| ## Checks and rules that pass without proving anything | none | documentation-only | Section heading for predicate and test quality pitfalls. |
| Restriction in comment not predicate | none | documentation-only | Specification alignment rule for predicate conditions. |
| Forgotten flag check across call sites | tests/source_checks.py:check_autonomous_transitions:422 | enforced | Enforced by choke point check in `tests/test_source_checks.py`. |
| Goal asking "is any of them X" | tests/source_checks.py:check_designation_goals_explicit:1055 | enforced | Enforced by explicit designation goal check in `tests/test_source_checks.py`. |
| Godot test skipping itself | tools/godot_compile_check.py:find_godot:70 | enforced | Enforced by multi-path Godot executable search in `tests/test_godot_compile_check.py`. |
| ## Performance | none | documentation-only | Section heading for performance and optimization traps. |
| Optimising set too small to need it | none | documentation-only | Profiling and call-rate check rule before adding spatial index. |
| Allocation churn reads as jitter | none | documentation-only | Allocation vs frame-time diagnosis guidance. |
| ## PowerShell tooling: three ways slice.ps1 finish broke | none | documentation-only | Section heading for PowerShell closeout traps. |
| Directory deletion depending on return | none | documentation-only | Guidance on `Set-Location` usage in scripts. |
| Throwing statement in destructive finally | none | documentation-only | Exception handling guideline for cleanup blocks. |
| Backtick as escape char in wildcard | none | documentation-only | Wildcard string handling rule in PowerShell. |
| git commit exits 1 on nothing to commit | none | documentation-only | Guidance on checking `git diff --cached --quiet`. |
| ## PowerShell tooling: a finish that looked stopped | none | documentation-only | Section heading for sandbox and job closeout traps. |
| Codex sandbox makes Test-Path throw | tests/test_admission_helpers.py:12 | enforced | Doctor excludes test validates denied folder handling. |
| Codex sandbox denies %APPDATA% | tools/godot_compile_check.py:ensure_writable_user_dir:26 | enforced | Environment redirection helper tested in `tests/test_godot_compile_check.py`. |
| tempfile hangs in denied folder | none | documentation-only | Writability probe guideline. |
| Receive-Job ErrorAction SilentlyContinue | none | documentation-only | Redirect and error action guideline for PowerShell jobs. |
| Shell call returning early | none | documentation-only | Timing and process liveness tracking rule in `plans/reference/closeout.md`. |
| ## Environment quirk: exit 4294967295 is killing Godot | none | documentation-only | Section heading for process kill diagnosis. |
| Godot failing to open log | tests/test_source_checks.py:FinishGodotScopeTest:13 | enforced | Tested by `FinishGodotScopeTest` and `ensure_writable_user_dir()`. |
| ## Environment quirk: a stale git lock | none | documentation-only | Guidance on moving `.git/index.lock` aside on lock errors. |
| ## Environment quirk: %USERNAME% is not who Codex runs as | none | documentation-only | Principal resolution rule using SID via `whoami.exe`. |
| ## Environment quirk: os.kill(pid, 0) is Ctrl+C on Windows | tests/test_headless_jobs.py:test_liveness_probe_signals_nothing_and_answers_for_this_process:50 | enforced | Liveness probe verified in `tests/test_headless_jobs.py`. |
| ## Environment quirk: headless run inherits profile | scripts/player_profile.gd:_isolated:52 | enforced | Isolation mode tested in `tests/test_headless_profiles.py:20`. |
| ## Environment quirk: parallel headless runs shared user:// | tools/run_scenario.py:private_user_env:69 | enforced | Private user directory isolation tested in `tests/test_run_scenario_launch.py:37`. |
| ## Agent cost: cd prefix turns denial into wasted turn | none | documentation-only | Command formatting rule for agent tool calls. |
| Four paths denied to Read tool | .claude/settings.json:1 | enforced | Deny list configuration in `.claude/settings.json`. |
| ## Agent cost: verify run through ../../ path | tools/verify.ps1:1 | enforced | Wrong checkout guard tested in `tests/test_wrong_checkout_guard.py:23`. |

## Method

- Parsed all 57 pitfall entries (15 `##` headings and 42 bold bullet items) from `docs/known-pitfalls.md` at origin/master commit `058dcc3d`.
- Cross-referenced each item against `tests/source_checks.py`, `tools/*.py`, `tests/test_*.py`, `scripts/scenario_actions.gd`, and `.claude/settings.json`.
- Opened and verified guard functions for every claim in `docs/known-pitfalls.md` stating a guard exists.
- Ran `python tools/check_docs.py` to validate document structure and cross-references.
- Uncovered areas not statically guarded: Godot interactive rendering and hands-on play cannot be tested via static analysis alone.
