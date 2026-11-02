# Jules integration -- 2 November 2026

Status: reference | Owner: Dave / Codex | Next: verify and integrate this prepared batch; J-31 and J-44 to J-53 hold the remaining corrections | Dependency: L-39 and L-40 in plans/now/agent-lifecycle.md | Baseline: a5c49644e2d48b0510af0fbf9ec2e17e414b0d42 | Verified: 2026-11-02

Dave authorised the implementation plans, merges and pushes following
the [full review](jules-review-2026-11-02.md). This record distinguishes
selected content from whole-branch merging: no Jules snapshot is merged.
Reviewed PR tips remain unchanged. PR #85 arrived after the review and is
not covered or integrated by this batch; it retains its published sequence
trailer and awaits its own review.

## Selected implementation

- PR #54: corrected J-42 contract tests, importing modules rather than
  exported TestCase aliases. They run with no tests-directory PYTHONPATH.
- PRs #62, #64, #66 to #70, #73, #74, #80, #81, #83: their named helper
  test file only.
- PR #65: helper tests, except the assertion endorsing primary-only finish.
  L-39 owns the pre-existing guard/closeout contract mismatch.
- PR #71: the standalone variable-shadow guard and its test. Its coverage
  is the explicit class/property map, not all Godot inheritance.
- PR #78: only the scenario-sweep helper test. Its fourteen unrelated
  files are excluded.
- PR #63: only the four-line uncalled is_mastered deletion applied to
  current progression.gd, preserving all other current code.

The combined named-test run passes **119 tests**. Expected error/timeout
output from mocked scenario-sweep cases is not a failed test. No save
field, balance value, simulation path, cache, validity guard or profiling
call changes. The remaining returned guards are not introduced.

## Processed reports and implementation plans

PR #56's qualified facts are in docs/save-review-2026-11-02.md; no blanket
runtime round-trip claim is accepted. PR #57's verified administrative
finding is in docs/verification-review-2026-11-02.md: C-84, C-109, C-110,
C-111, C-114 to C-118 and C-130 move from blocked to ready with their same
ids, instructions, owners and runners. No check is executed or marked
passed.

PR #61's qualified record is docs/context-review-2026-11-02.md. Two
startable medium-reasoning specifications are added to the existing
agent-lifecycle plan, with proofs and normal queue blocks:

| Slice | Outcome | Files | Next action |
| --- | --- | --- | --- |
| L-39 | Guard permits documented worktree closeout; other denials survive | tools/guard_hook.py and the two guard suites | Admit through normal Codex lane refill; no lane claimed here. |
| L-40 | Codex coordinator delegates gates/refill/finish-stop to its existing steward | .agents/skills/run-queue/SKILL.md | Follow L-39, preserving current worker/model/cap policy and Codex syntax. |

Correction to the earlier Codex report: plans/README.md's Directory
contract deliberately reserves plans/active/ while empty. The missing
directory is not a dead-reference defect. That cleanup recommendation is
withdrawn; the 111-line warning alone does not justify a rule rewrite.
The earlier review remains historical evidence, read with this correction.

The code-health plan has a live CQ-R16 owner and is not edited. Existing
UI/profile observations remain under its established reopening conditions;
no unsupported geometry or performance fix is scheduled.

## Jules corrections

The ledger now records each processed branch and reviewed tip, including
returned and superseded work. J-42's completed block is pruned only because
the corrected test actually enters this batch. The unaccepted J-31 audit
remains a returned correction. Ten additional bounded briefs refill the
ordinary task list, without changing either integrated lane:

| Task | Exact responsibility | Source review |
| --- | --- | --- |
| J-44 | Numeric provenance / loop scope in the JSON guard | F5 / PR #72 |
| J-45 | Semantic reach arithmetic in the navigation guard | F7 / PR #75 |
| J-46 | Enclosing debounce condition in the steering guard | F6 / PR #76 |
| J-47 | One executable-code marker guard, with visit points and missing-input failure | F4 / PR #79; #77 superseded |
| J-48 | Actual flower rejection and cooldown assignment | F6 / PR #84 |
| J-49 | Windows-portable terminal-line expected paths, tests only | F3 / PR #82 |
| J-50 | Fail closed on nonexistent explicit shadow-check inputs | Accepted #71's CLI skips missing paths; no simulation changes |
| J-51 | Correct gameplay report's causal evidence, contracts and checks | F2 / PR #55 |
| J-52 | Correct UI report's colour/text and visual-verification claims | F9 / PR #59 |
| J-53 | Correct architecture report's protected-API and task claims | F10 / PR #60 |

The new source guards are absent from master, so correction tasks add only
their two allowlisted files from the rejected starting point; they cannot
import a branch snapshot. Report corrections change only the named report.
Task alternation and sequence trailers remain under the newly integrated
efficiency policy. No reviewed pre-policy PR supplies a Jules-Sequence
trailer; no trailer is invented or renumbered. No remote branch is deleted.

## Product and save decisions

The adaptation/skill API reservation, queen/death cargo policy and exact
flight/rival-tick persistence questions were presented to Dave in this
session. Until answered, existing behaviour and the documented reservation
remain; silence is not a decision. No implementation slice changes those
outcomes. The owning places are plans/design/progression.md and
plans/now/run-repairs.md, as the full review names.

## Verification and integration

- Latest preparation baseline: a5c4964; master then received only the
  required registration for this review-lane integration worktree.
- Initial selected suites: 119 tests pass together on Windows/Python 3.14.7.
- Numbered scope checks and mutation evidence are in the full review.
- Full tools/verify.ps1 result: pending. This branch must not be merged
  until the combined gate succeeds; any import-cache fault is repaired
  without editing source.
- Risk tier: low -- tests, bounded offline tooling, qualified records and
  plans, check administration and a proven uncalled-function deletion;
  no gameplay/save/balance change or cross-lane source overlap.
- No Jules PR is closed through GitHub. The ledger distinguishes actual
  selected-content integration from unaccepted/superseded source branches.
