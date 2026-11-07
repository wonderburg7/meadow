# Outstanding Jules review — 7 November 2026

Status: reference | Owner: Dave / Codex | Next: complete selected-test integration, then record actual delivery and closures | Dependency: plans/reference/jules-coverage-2026-11-07.md | Verified: 2026-11-07

## Result and scope

The older work has already been checked. Reconciliation found **14 new submissions**, **four still-open PRs already integrated**, **one still-open final rejection**, and **one unchanged returned report**. Every one of the 20 open items has a disposition in the [complete 157-item coverage table](jules-coverage-2026-11-07.md). Of those 20: two ready, six selected-content integrations, five returns, seven closures/superseded items. Ready/selected describes review acceptance; it does not by itself mean delivered.

Read AGENTS.md, docs/agent-rules.md and CHATGPT.md first; this was Dave's assigned review, with no unrelated queue claim. Refreshed origin with prune, enumerated every GitHub PR including drafts and closed items, fetched all PR heads, and ran jules_preflight --ledger. Used the 5 November review/coverage/follow-up records and actual integrations 7a3e836, 3c0121f and **7736d79 (6 November)** as the starting point. All 137 closed/merged Jules heads match their latest completed record; none conceals a newer tip. The 80 live remote Jules branches all map to PRs. GitHub has zero submitted review objects across all 158 PRs; discussion and repository records supply the review history. No arbitrary age cutoff was used. PR #1's old external audit text remains unavailable; its unchanged empty tip has no new content to review.

Reviewed on refreshed master **dbfced3e9cedf100c4f43a01762540072b786154**, in isolated worktrees. Before writing changes, recorded the task, branch and baseline; the retained review worktree is registered on primary by f8bbf16. The initially unregistered disposable worktree caused check_docs errors; it was removed and the retained worktree registered, after which check_docs passed. No pre-existing worktree was changed. Other active lanes PN-12/PN-15 were preserved.

## Findings, most severe first

| Id / severity | Evidence and concrete consequence | Disposition |
| --- | --- | --- |
| F1 — P1 | [#145 tools/overflow_discard_check.py:136](https://github.com/wonderburg7/meadow/blob/c572b3d7b32f1fda9415d3123c69a17b32e8b464/tools/overflow_discard_check.py#L136) searches for `in C1_DISCARD_STAGES` anywhere in the body. Actual-source mutations `not in`, moving membership into an unused local, and appending `or true` all return **[]**, although each removes/reverses the intended restriction. `parse_stages_constant` also accepts a commented-out declaration. A green guard would allow the queen's overflow nectar to be discarded outside the pollen-automation stage. This is a defective proposed guard, not evidence that current game code has the runtime bug. | **Returned #145**: enforce executable declaration and return/control flow with these negative fixtures; no guard integrated. |
| F3 — P1 if merged wholesale | **#146** has 11 out-of-task files plus its test. Its complete authored diff carries CQ-M6 world presentation code, FUNCTION_MAP/queue/archive/plan changes. Its endpoint diff differs in 149 files; 142 are master-only changes since its merge base. The CQ-M6 material is inherited, not a new S-1 delivery, and does not authorise overwriting current game code/plans. #130/#133 also retain known excluded policy/runtime snapshots. | **Selected #146 only**: one pure off_line case. All inherited source/coordination changes excluded; #130/#133 close as already integrated. |
| F2 — P2 | [#147 tools/check_scenarios.py:28](https://github.com/wonderburg7/meadow/blob/7ec755508414b627a95abc1c31942a717c0eb33e/tools/check_scenarios.py#L28) hard-codes sequence verbs. Renaming every `"settle"` occurrence in a source fixture to `"rest"` leaves `settle` accepted and `rest` absent. Inserting a blank line before the first _execute arm raises `No string match arms found`, despite unchanged valid GDScript. The count test uses the same extractor, so does not prove independent completeness. Baseline's derived set has 36 verbs; a numeric count is not pinned. | **Returned #147 / J-54**: derive run_pending comparisons as well as _execute arms from executable source, preserve formatting, and add independent source-mutation fixtures. Nested disabled/mock bad actions are correctly rejected. No validator integrated. |
| F4 — P2 | S-1 permits untested **pure** helpers. #146's reviewed_state runs git; #148 tests git/CLI; #152 tests traversal/CLI (its two pure cases name a function already covered on master); every #153 case reads files, including build_file transitively; #154 includes discover_sources; #155 is all I/O-backed; #158 includes ledger/glob wrappers. Mocking I/O does not change the called helper's contract. #149/#156 repeat code-stripping cases already in test_indoor_flower_check.py:51-59. | **Selected/returned/closed individually** in coverage. Deliver 38 eligible cases in seven files from #146/#148/#149/#150/#151/#154/#156/#158. #152 closed without delivery; #153/#155 returned. |
| F5 — P2 | [#155 tests/test_check_docs_backticked_paths_helpers.py:103](https://github.com/wonderburg7/meadow/blob/74a6d9065161a2d050985fcf13a9a6f18de67afb/tests/test_check_docs_backticked_paths_helpers.py#L103) expects the fixture prefix "docs/broken.md"; Windows emits "docs\broken.md". Its suite runs six tests with **one failure** despite Linux CI green. | **Returned #155**: use native str(Path(...)) in diagnostics expectations, and respect S-1 purity; do not change production output to fit this assertion. |
| F6 — P2, pre-existing unresolved | Current **tools/indoor_flower_check.py:73-90**, _extract_func_body, stops at a column-zero comment. Appending an unguarded `state = State.SEEK_FLOWER` after such a comment inside the real set_focus body makes check_bee_focus still return **[]**. This was explicitly retained in the 6 November ledger outcome; the new helper suites omit that case. It is a guard blind spot, not a newly proved gameplay defect. | **Unresolved, bounded correction criterion retained here**: ignore comment-only lines when deciding the function boundary; reject this real-source mutation, retain correct line numbers and all existing 15 guard cases. Do not reopen #133's integrated disposition or infer full guard coverage from these helper additions. |
| F7 — P2 evidence quality | **#134 E34-1/E34-2** still names no actual orphaned handoff or failed fixture. Rule 4's registration requirement is real; the claimed recurring incident and model provenance are unsupported, and plans/now/agent-lifecycle.md is not a live destination. Its report blob is unchanged since the 5 November return. **#109**'s additive-save syntax proposal cannot prove GDScript restore semantics; FORMAT_VERSION/contiguous-ladder checks already exist at tests/test_save_migrations.py:212-220, and that module explicitly says it is a Python mirror. | **#134 remains returned**, under the existing jules-review-followups-2026-11-05.md reopening contract. **#109 close final rejection**, already decided on 6 November. No new save/model/workflow decision for Dave. |
| F8 — P2 coordination | **#157** reuses `Jules-Sequence: 58 ordinary` from earlier #155; its scope CI fails. **#156** inherits #149's sequence 52, its body still says 52, but its new commit carries 59; its scope CI fails too. Importing the #156 file wholesale also overwrites complementary #149 cases. | **#157 close later duplicate**, preserving published 58 without renumbering. **#156 take three complementary cases only**; retain 52 once and actual 59 in integration history, close source after delivery. |

## Prior reports and corrective updates

- #126: qualified E-30 report is on master; the hand-kept catalogue was rejected and the validator became J-54. Its corrected report omits a then-recognised verb; master already carries the qualification. No report reapplication.
- #130: both allowed files are byte-identical to master. Current 12-test guard suite passes, including its single-quoted/bad-explicit cases; the old return is resolved.
- #133: both allowed files are byte-identical to master. Current 15-test guard suite passes; the known column-zero-comment limitation above remains. Exclude 27 stale files, including source_checks content that would remove current canvas-layer coverage.
- #135: corrected six-test pure-helper file is byte-identical to master. Its previous I/O/CLI return is resolved.
- #109/#134: checked report claims against current save tests and review contract. Unsupported claims remain rejected/returned; no new game, architecture, balance or save decision arises.
- All older audits, review reports, numbered/standing tasks and their corrective submissions remain covered by unchanged-tip matching to the complete 5 November coverage plus subsequent ledger/integration entries. Prior D1/D2/D3 decisions and reopening criteria remain in force; this review does not assert that every historical audit limitation was fixed.

## Checks

Every new submission's complete allowed test suite was run separately against baseline master in a disposable isolated worktree. Thirteen passed; #155 failed one assertion. All fourteen --scope commands were rerun: thirteen passed file-shape scope; #146 failed with eleven off files. Scope is not proof of semantic correctness or sequence validity. Baseline/negative probes above used temporary copies, never changed game files.

| PR | Local submitted suite | Local file scope | GitHub current-tip checks |
| --- | --- | --- | --- |
| #109 | Prior exact-tip review reused; current-master suites below | Previously processed; snapshot limits retained | No checks reported at this tip; CI unverified. |
| #126 | Prior exact-tip review reused; current-master suites below | Previously processed; snapshot limits retained | Jules scope: SUCCESS, Python checks: SUCCESS, Godot headless boot: SUCCESS |
| #130 | Prior exact-tip review reused; current-master suites below | Previously processed; snapshot limits retained | No checks reported at this tip; CI unverified. |
| #133 | Prior exact-tip review reused; current-master suites below | Previously processed; snapshot limits retained | No checks reported at this tip; CI unverified. |
| #134 | Prior exact-tip review reused; current-master suites below | Previously processed; snapshot limits retained | Python checks: SUCCESS, Godot headless boot: SUCCESS, Jules scope: SUCCESS |
| #135 | Prior exact-tip review reused; current-master suites below | Previously processed; snapshot limits retained | Python checks: SUCCESS, Godot headless boot: SUCCESS, Jules scope: SUCCESS |
| #145 | 9 tests: PASS | PASS | Jules scope: SUCCESS, Python checks: SUCCESS, Godot headless boot: SUCCESS |
| #146 | 5 tests: PASS | FAIL (11 out-of-scope files) | No checks reported at this tip; CI unverified. |
| #147 | 8 tests: PASS | PASS | Python checks: SUCCESS, Godot headless boot: SUCCESS, Jules scope: SUCCESS |
| #148 | 6 tests: PASS | PASS | Python checks: SUCCESS, Godot headless boot: SUCCESS, Jules scope: SUCCESS |
| #149 | 9 tests: PASS | PASS | Python checks: SUCCESS, Godot headless boot: SUCCESS, Jules scope: SUCCESS |
| #150 | 9 tests: PASS | PASS | Jules scope: SUCCESS, Python checks: SUCCESS, Godot headless boot: SUCCESS |
| #151 | 8 tests: PASS | PASS | Python checks: SUCCESS, Godot headless boot: SUCCESS, Jules scope: SUCCESS |
| #152 | 10 tests: PASS | PASS | Python checks: SUCCESS, Godot headless boot: SUCCESS, Jules scope: SUCCESS |
| #153 | 4 tests: PASS | PASS | Python checks: SUCCESS, Godot headless boot: SUCCESS, Jules scope: SUCCESS |
| #154 | 6 tests: PASS | PASS | Python checks: SUCCESS, Godot headless boot: SUCCESS, Jules scope: SUCCESS |
| #155 | 6 tests: FAIL (one Windows path assertion) | PASS | Python checks: SUCCESS, Godot headless boot: SUCCESS, Jules scope: SUCCESS |
| #156 | 11 tests: PASS | PASS | Python checks: SUCCESS, Godot headless boot: SUCCESS, Jules scope: FAILURE |
| #157 | 8 tests: PASS | PASS | Python checks: SUCCESS, Godot headless boot: SUCCESS, Jules scope: FAILURE |
| #158 | 7 tests: PASS | PASS | Python checks: SUCCESS, Godot headless boot: SUCCESS, Jules scope: SUCCESS |

Additional current-master checks: tests.test_goal_default_check, tests.test_indoor_flower_check, tests.test_forager_diagnosis_helpers, tests.test_save_migrations and tests.test_save_roundtrip.GoldenContentsTest: **86 tests passed**. Selected helper batch: **38 tests passed**. tests/source_checks.py: **111 scripts passed**. tests/balance_tests.py: **15 checks passed**. check_docs: **passed**, with existing stale-date, lane-floor/deferral and file-size warnings left unchanged. Full verify result and final publication are recorded below once observed.

Limitations: no hands-on play, rendered UI QA or performance profiling was needed or performed for the selected pure Python tests; no gameplay, per-frame path, save field, GameConfig balance value, validity guard or Perf instrumentation is changed. CI absence on #109/#130/#133/#146 is explicitly unverified, not a pass. Linux PR runs were inspected as GitHub status evidence, not reproduced locally; the Windows failure is independent evidence. Rejected raw runtime snapshots were inspected/classified, not executed as potential integration candidates. Existing historical report caveats are not converted into verified defects.

## Integration order and decisions

1. One batch of the 38 selected tests, preserving all existing tests and only combining complementary #149/#156 cases; full verify once. No game/source/policy/queue snapshot is admissible.
2. After that batch actually reaches master: append exact-tip ledger rows, close the eight delivered source PRs and the seven final-rejection/already-integrated/duplicate PRs. Keep #134/#145/#147/#153/#155 returned with concrete correction criteria. Preserve every published sequence trailer before any deletion; no remote branch deletion is required for this review.
3. Re-review corrected guard tips, not old approvals. Correct J-54's source derivation before adding it to verification; correct #145's control-flow proof before using it. The pre-existing indoor guard limitation has the precise reopening check in F6.

**Decisions for Dave: none.** This is implementation-neutral test/report triage, not authority to change gameplay, save compatibility, reserved APIs or earlier decisions. No Codex queue priorities changed.

## Publication

Selected test batch: prepared on codex/jules-review-20261107; not yet claimed integrated. Ledger rows are deliberately absent from this preparation branch. Final delivery, actual PR states and full verification will be recorded only after they are observed.
