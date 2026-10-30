# Jules integration review — 30 October 2026

Status: reference | Owner: Dave / Codex | Next: Jules corrections below | Dependency: none | Baseline: `361abcc` | Verified: 2026-10-30

Reviewed all 41 unmerged origin/jules branch refs from origin/master `361abcc`. Seven accepted branches, 21 previously integrated branches, and 13 sent back. No origin branch was deleted.

The full verification run passed compile, style, source, balance and 91 unit modules; J-42 failed its named module import. A named-test bisect identified `544e18e`, reverted by `db64a09`. The reviewer’s standalone `PYTHONPATH=tests` had masked the incompatibility. Post-revert source checks pass. No second full run was made.

No audit candidates met the acceptance criteria, so no new Jules tasks were added. J-16, J-40, J-41 and J-43 are removed from the open task list; J-42 remains open.

## Branches requiring Jules corrections

Decision and Reason are copied verbatim from the final reviewer reports. Existing correction criteria remain in `plans/reference/jules-integration-2026-10-29.md`.

| Branch | Decision | Reason |
| --- | --- | --- |
| `origin/jules/audit-workflow-token-savings-6565171343466416243` | SEND BACK | Finding 1 incorrectly says lifecycle/game tests run indiscriminately: audited verify.ps1 already filters both.<br>Finding 6 incorrectly treats prefinish’s selected tests as identical to full verify; J-2 could skip unexecuted tests and trusts unchanged HEAD despite working-tree changes.<br>J-1 overlooks existing path filtering and omits lifecycle fixture dependencies; no candidate is presently safe and sufficiently supported.<br>Report is not on origin/master; no workflow recommendations executed. |
| `origin/jules/j-29-pitfall-guard-coverage-17758229234258061777` | SEND BACK | Report still labels uncalled scanning as rectangle-ownership enforcement. Two live rectangle writers produce no finding. check_declarations catches malformed declarations but accepts renamed identifiers inside strings. Source has 15 headings and 40 bold-led bullets; claimed 57 entries remains unreconciled. |
| `origin/jules/j-30-ui-rectangles-6379343624088707089` | SEND BACK | Finding 1 incorrectly identifies a ScrollContainer child as an HFlowContainer child and recommends removing required expansion. Finding 4 treats a label’s explicit 270-pixel minimum as a layout defect without reproduction. Both errors persist in Summary and candidates. |
| `origin/jules/j-31-coordinate-spaces-7902036955716962807` | SEND BACK | Honey finding still misclassifies global/global distance; changing its argument to local would break the documented contract.<br>Camera finding provides no demonstrated parent-transform mismatch; both cameras are children of main.<br>Audit date remains implausible: 24 May 2024. |
| `origin/jules/j-32-save-coverage-9194610013395303275` | SEND BACK | Audit still dates itself 31 Oct 2026. Inventory omits nuptial_timer and lacks the required complete member/fallback coverage.<br>Bee finding contradicts bee.gd:125–127’s explicit nuptial reset contract.<br>Rival tick_timer omission is verified, but persistence needs a decision before prescribing save changes.<br>Declared revision resolves correctly; no runtime/save changes imported. |
| `origin/jules/j-33-signal-wiring-10069084102049606120` | SEND BACK | Finding 5 and its candidate still incorrectly claim saves_panel.gd lacks an is_connected guard; lines 88–89 already guard line 91. Finding 4 assumes repeated calls despite the documented once-in-_ready lifecycle. main.gd explicitly documents rain_changed as an intentional event boundary without current listeners; its removal candidate disregards that contract. |
| `origin/jules/j-34-per-frame-paths-875237027435561307` | SEND BACK | Debug finding conflates guarded pollination work with unguarded navigation work. HUD helper already guards absent, hidden and other-world markers. Rain already exits when hidden and redraws after moving drops. Cache and bee cadence recommendations lack profiling. |
| `origin/jules/j-35-balance-literals-5386586949733054081` | SEND BACK | The report still labels named presentation constants FORAGER_SPEED and PRESENTATION_PER_SECOND as balance findings. The flower display throttle is explicitly documented. Its candidate also proposes GameConfig balance changes outside Jules authority. No source or balance changes made. |
| `origin/jules/j-36-role-runstate-ownership-5879758852814510240` | SEND BACK | Findings #2/#3 mistake player command routing for forbidden presentation mutation; rule 2 prohibits presentation gating simulation. No gating violation is demonstrated. Candidate J-37 requires main/hive receivers outside its HUD-only Files scope. Audit date also conflicts with its revision. |
| `origin/jules/j-37-vacuous-tests-9463619649162809978` | SEND BACK | Explicit unittest skips are misclassified as passes; both boot helpers assert execution results.<br>source_checks.py propagates wiring failures through problems.extend.<br>J-101 incorrectly requires real-tree dead code; its fixture already checks detection.<br>J-103 overlooks helper assertions and the cadence harness’s documented diagnostic purpose. |
| `origin/jules/j-38-duplicate-rules-16003263335438632552` | SEND BACK | Finding 3 still incorrectly treats slice branch validation, Jules task extraction and changed-file enumeration as equivalent parsers.<br>Finding 2 still demands parity between a general queue-fence recogniser and a lane/id-specific gated-successor search.<br>No differing example or intentional-contract explanation supplied; candidates J-40/J-41 retain these errors. |
| `origin/jules/j-39-instruction-drift-16519072405257210859` | SEND BACK | Finding 1 calls verify.ps1 stale although line 13 supplies .\tools\verify.ps1 before line 18 uses its basename. Finding 2 treats the existing tests/source_checks.py basename as a stale path without showing ambiguity or a failed instruction. These remain high-confidence findings and dominate the Summary. |
| `origin/jules/j-42-godot-helper-contracts-16251171298534805398` | SEND BACK | The named verifier invocation fails. Reviewer standalone PYTHONPATH=tests masked import incompatibility. Responsible commit reverted without further implementation changes. |

## Follow-up routing

- **Workflow token-savings audit**: docs/audits/workflow-token-savings.md Findings 1/6 and Candidates J-1/J-2 need correction; Jules report remit.
- **J-29**: docs/audits/pitfall-guards.md Inventory/Summary/Method — apply J-29 correction in plans/reference/jules-integration-2026-10-29.md.
- **J-30**: docs/audits/ui-rectangles.md Summary/Findings/Candidate Jules tasks — correct parentage, retain ScrollContainer expansion, distinguish fixed-width observations from demonstrated faults; owning record plans/reference/jules-integration-2026-10-29.md.
- **J-31**: Revise report findings, date and candidate justification; existing bee_honey/find_honey_source follow-up names plans/now/code-health.md but establishes no defect.
- **J-32**: docs/audits/save-coverage.md — complete J-32 correction row. scripts/rival_hive.gd save_data/restore — persistence decision, report names plans/now/run-repairs.md but ownership unverified.
- **J-33**: docs/audits/signals.md Summary/Findings/Candidate Jules tasks — correct guards and lifecycles; distinguish unused interfaces from demonstrated defects, per plans/reference/jules-integration-2026-10-29.md, “Why the audits need correction”.
- **J-34**: docs/audits/per-frame-paths.md Summary/Findings/Candidate Jules tasks — correct under plans/reference/jules.md J-34 and integration correction row.
- **J-35**: docs/audits/balance-literals.md, Findings/Summary/Candidate Jules tasks — reclassify by consumers and remove unsupported settings proposal; owning record plans/reference/jules-integration-2026-10-29.md, J-35 correction row.
- **J-36**: docs/audits/ownership.md Findings #2/#3 and Candidate J-37 — correct command-routing classification and supply complete ownership bounds before proposing changes; owning record: plans/reference/jules-integration-2026-10-29.md, J-36 correction row.
- **J-37**: Revise audit Summary/Findings/Candidates per plans/reference/jules-integration-2026-10-29.md, “Why the audits need correction”, J-37 row.
- **J-38**: Correct docs/audits/duplicate-rules.md Findings 2/3 and candidates under plans/reference/jules.md J-38; retain only tests for demonstrated common contracts.
- **J-39**: docs/audits/instruction-drift.md Summary/Findings — re-audit references contextually under plans/reference/jules-integration-2026-10-29.md, J-39 correction row; preserve valid instructions.
- **J-42**: tests/test_godot_helper_contracts.py imports — Jules J-42 remit; support verifier invocation before resubmission.

Report corrections are linked from `plans/observations/system-improvement-signals.md`. The rival tick timer persistence question is already recorded in `plans/now/run-repairs.md`, “Not in the queue, and why”; this review adds no save change or new decision. The J-31 honey finding establishes no code defect, so it does not admit a code-health task. J-42 must pass `python -m unittest tests.test_godot_helper_contracts` without an added tests-directory import path before resubmission.
