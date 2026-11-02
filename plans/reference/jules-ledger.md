# Jules ledger -- what happened to each Jules branch

<!-- CONTEXT: reference | LAYER: reference | LOAD: through `python tools/jules_preflight.py --ledger`; append a row, never read the whole file -->
Status: reference | Owner: Dave / Claude Code / Codex | Next: add a row for each Jules branch you process; `--ledger` lists any left unreviewed | Dependency: `tools/jules_preflight.py` | Verified: 2026-11-02

Jules's pull requests are often integrated by checking out their files rather
than merging the branch, so Git alone cannot say which branches someone has
already dealt with: on 30 Oct 2026 forty-one `origin/jules/*` branches were
unmerged, seventeen of them long since integrated and eleven reviewed and
sent back. This table is the missing record. `python tools/jules_preflight.py
--ledger` joins it with the remote branches and lists each one as:

- **unreviewed** -- no row, and it is neither merged by a `J-<n>:` line on
  master nor already identical to master in every file it changes. Someone
  needs to check it.
- **merged** -- integrated, by a row here or one of those two signs.
- **returned** -- not merged; its task (or review) is free for Jules again,
  and `--next` prints this row's Outcome with it as what to correct.
- **closed** -- not merged and finished with: its findings went elsewhere,
  something else superseded it, or it was rejected. A closed task is never
  offered again; a closed review report counts as that review's last run.

A branch with a row takes no task and owns no file in the preflight's eyes.

**Keeping it.** Whoever processes a Jules branch -- Claude, Codex or Dave --
adds one row at the bottom of the table in the same commit as the merge,
return or closure: the branch name without `origin/`, today's date, who, and
an Outcome a later reader can act on (for a returned branch, exactly what to
correct). A branch merged with a `J-<n>:` line needs no row. Jules reads this
file but never edits it. Prune a row once its branch is deleted from
`origin`.

| Item | Branch | State | Date | By | Outcome |
| --- | --- | --- | --- | --- | --- |
| S-1 | jules/s1-prefinish-helpers-17765387290738127663 | merged | 2026-10-27 | Claude | Taken as 545c0cd (`tests/test_prefinish_helpers.py`) |
| S-1 | jules/s-1-heading-helpers-12730515454291603165 | merged | 2026-10-29 | Codex | Taken with added cases as afffeab; `plans/reference/jules-integration-2026-10-29.md` |
| S-1 | jules/s-1-stage-reference-helpers-14091259932105731355 | merged | 2026-10-29 | Codex | Taken with added cases as f1dedb4; same review |
| friction | jules/workflow-friction-recommendations-5502329343734512397 | closed | 2026-10-26 | Claude | Proposal re-verified into `plans/archive/workflow-friction_2026-10-31.md` FX-1 to FX-6 (cc56822); the proposal file itself was not merged |
| J-29 | jules/j-29-pitfall-guard-coverage-17758229234258061777 | closed | 2026-10-30 | Claude | Sent back 29 and 30 Oct (jules-integration reviews); superseded by R-verification step 2, whose method carries the correction |
| J-30 | jules/j-30-ui-rectangles-6379343624088707089 | closed | 2026-10-30 | Claude | Sent back 29 and 30 Oct; superseded by R-ui; useful guard salvaged as J-40 |
| J-31 | jules/j-31-coordinate-spaces-7902036955716962807 | returned | 2026-10-30 | Claude | Redo from a fresh branch (sent back 29 and 30 Oct). Drop the honey finding: bee_honey.gd and hive.gd both use global positions, and making the argument local would break the documented contract. The two cameras are both children of main: show a parent-transform mismatch before calling year_winter.gd:146 a fault. Use today's date and the commit you audited (the last report said 24 May 2024) |
| J-32 | jules/j-32-save-coverage-9194610013395303275 | closed | 2026-10-30 | Claude | Sent back 29 and 30 Oct; superseded by R-save. Verified observations already routed to `plans/now/run-repairs.md` "Not in the queue, and why" |
| J-33 | jules/j-33-signal-wiring-10069084102049606120 | closed | 2026-10-30 | Claude | Sent back 29 and 30 Oct; superseded by R-gameplay (event ordering and connection lifecycles) |
| J-34 | jules/j-34-per-frame-paths-875237027435561307 | closed | 2026-10-30 | Claude | Sent back 29 and 30 Oct; per-frame cost needs a profile first (agent rule 3), so it stays with the performance review, which is not on the Jules rota |
| J-35 | jules/j-35-balance-literals-5386586949733054081 | closed | 2026-10-30 | Claude | Sent back 29 and 30 Oct; classifying balance values needs their consumers judged, so it stays with the data-catalogue review |
| J-36 | jules/j-36-role-runstate-ownership-5879758852814510240 | closed | 2026-10-30 | Claude | Sent back 29 and 30 Oct; superseded by R-architecture. Verified observations already routed to `plans/now/code-health.md` |
| J-37 | jules/j-37-vacuous-tests-9463619649162809978 | closed | 2026-10-30 | Claude | Sent back 29 and 30 Oct; superseded by R-verification step 3; salvaged as J-42 |
| J-38 | jules/j-38-duplicate-rules-16003263335438632552 | closed | 2026-10-30 | Claude | Sent back 29 and 30 Oct; superseded by R-architecture (duplicated definitions); salvaged as J-41 |
| J-39 | jules/j-39-instruction-drift-16519072405257210859 | closed | 2026-10-30 | Claude | Sent back 29 and 30 Oct; superseded by R-context step 3 |
| J-42 | jules/j-42-godot-helper-contracts-16251171298534805398 | returned | 2026-10-30 | Codex | Merged then reverted (db64a09): the test failed its own module import, masked by a standalone PYTHONPATH=tests. It must pass `python -m unittest tests.test_godot_helper_contracts` with no added tests-directory import path |
| token audit | jules/audit-workflow-token-savings-6565171343466416243 | closed | 2026-10-30 | Codex | Sent back: Findings 1 and 6 misread verify.ps1's existing test filtering and prefinish's test selection, so no candidate is safe. No task asks for a redo; `plans/reference/jules-integration-2026-10-30.md` holds the reasons |
| S-1 | jules/s-1-diagnostics-helpers-4600050507060882082 | merged | 2026-10-30 | Codex | Taken with edits as 592573b; `plans/reference/jules-integration-2026-10-30.md` |
| S-1 | jules/s-1-hook-log-helpers-3127326564944141059 | merged | 2026-10-30 | Codex | Taken with edits as b991c00; same review |
| report | jules/architecture-context-report-2353694383991347374 | merged | 2026-10-30 | Codex | Kept as a historical assessment, c9adfb9 (`docs/system-architecture-and-context-report-2026-10-24.md`) |
| R-modularity | jules/modularity-review-2026-10-30-962141701101776885 | merged | 2026-10-30 | Claude | record docs/modularity-review-2026-10-30.md; 0 queued, 3 gated (MOD-01 to MOD-03 as CQ-R15, CQ-R8, CQ-R3, CQ-R16 in plans/now/code-health.md), 0 decided, 5 rejected (MOD-04 to MOD-08) |
| superseded J-31 | jules/j-31-coordinate-spaces-7902036955716962807 | closed | 2026-11-02 | Codex | Superseded by corrective PR #53; #53 still needs the operand-parent inventory correction; the distinct item label keeps the active J-31 correction free |
| J-42 | jules/j-42-godot-helper-contracts-16251171298534805398 | closed | 2026-11-02 | Codex | Superseded by corrected PR #54, integrated in the 2 Nov batch; do not reapply reverted 544e18e |
| J-31 | jules/j-31-coordinate-spaces-13284476037409319937 | returned | 2026-11-02 | Codex | Corrected date/honey/camera conclusions, but audit still lacks operand parents and complete expression coverage; see F8. Details: plans/reference/jules-review-2026-11-02.md; correction task J-31 |
| J-42 | jules/j-42-godot-helper-contracts-17504292275885835697 | merged | 2026-11-02 | Codex | PR #54, tip cdca82b7ee27: selected in the 2 Nov batch; plans/reference/jules-integration-2026-11-02.md |
| R-gameplay | jules/r-gameplay-review-2026-10-30-8334134721198376116 | returned | 2026-11-02 | Codex | Reject automatic gameplay fixes; supply causal reproductions, honour queen contract, fix R2 proof and missing test module; see F2. Details: plans/reference/jules-review-2026-11-02.md; correction task J-51 |
| R-save | jules/r-save-review-2026-10-30-12942222504359307257 | merged | 2026-11-02 | Codex | PR #56, tip bf556ebe0eb0: qualified processing record docs/save-review-2026-11-02.md; 0 queued, 0 gated, 0 decided, 2 rejected, 1 fixed; only qualified evidence adopted |
| R-verification | jules/r-verification-review-2026-10-30-14160929869471362887 | merged | 2026-11-02 | Codex | PR #57, tip 06c2e16f678a: qualified processing record docs/verification-review-2026-11-02.md; 0 queued, 0 gated, 0 decided, 2 rejected, 2 fixed; only qualified evidence adopted |
| R-ui | jules/r-ui-2026-10-30-4481302975311752886 | returned | 2026-11-02 | Codex | Weather state already has non-colour wording; separate proposed layout coverage from demonstrated defects and remove visual-verification claim. Details: plans/reference/jules-review-2026-11-02.md; correction task J-52 |
| R-architecture | jules/r-architecture-review-2026-10-30-13822823161316074019 | returned | 2026-11-02 | Codex | Respect planned adaptation/skill APIs and D1; separate the eligible is_mastered cleanup (#63), remove reused J-43 and unsupported all-free claim. Details: plans/reference/jules-review-2026-11-02.md; correction task J-53 |
| R-context | jules/r-context-review-2026-10-30-8314794974428438666 | merged | 2026-11-02 | Codex | PR #61, tip d3ad926ae289: qualified processing record docs/context-review-2026-11-02.md; 2 queued (L-39/L-40), 0 gated, 0 decided, 4 rejected; only qualified evidence adopted |
| S-1 | jules/s-1-analyze-session-helpers-12625715772046531915 | merged | 2026-11-02 | Codex | PR #62, tip 54886f6cd633: selected in the 2 Nov batch; plans/reference/jules-integration-2026-11-02.md |
| S-2 | jules/s-2-remove-is-mastered-5993954817498403275 | merged | 2026-11-02 | Codex | PR #63, tip 5e51970e7633: selected in the 2 Nov batch; plans/reference/jules-integration-2026-11-02.md |
| S-1 | jules/s-1-godot-cache-helpers-15542004621871323425 | merged | 2026-11-02 | Codex | PR #64, tip 469295a8e195: selected in the 2 Nov batch; plans/reference/jules-integration-2026-11-02.md |
| S-1 | jules/s-1-guard-hook-helpers-1793409129-12470490033094166669 | merged | 2026-11-02 | Codex | PR #65, tip 898676ead864: selected in the 2 Nov batch; plans/reference/jules-integration-2026-11-02.md; omit stale worktree-finish test; L-39 owns the existing contract mismatch |
| S-1 | jules/s-1-preflight-helpers-10037757402133702881 | merged | 2026-11-02 | Codex | PR #66, tip d063392a71ff: selected in the 2 Nov batch; plans/reference/jules-integration-2026-11-02.md |
| S-1 | jules/s-1-stop-causes-helpers-16041979090131156673 | merged | 2026-11-02 | Codex | PR #67, tip 0cd859c4df1a: selected in the 2 Nov batch; plans/reference/jules-integration-2026-11-02.md |
| S-1 | jules/s-1-self-call-check-helpers-9751669171139684916 | merged | 2026-11-02 | Codex | PR #68, tip c5c2cd5a6205: selected in the 2 Nov batch; plans/reference/jules-integration-2026-11-02.md |
| S-1 | jules/s-1-godot-compile-check-helpers-13650035314090603756 | merged | 2026-11-02 | Codex | PR #69, tip 595e220ad7f6: selected in the 2 Nov batch; plans/reference/jules-integration-2026-11-02.md |
| S-1 | jules/s-1-foraging-evidence-report-helpers-14810445619902395796 | merged | 2026-11-02 | Codex | PR #70, tip 694fe16f2138: selected in the 2 Nov batch; plans/reference/jules-integration-2026-11-02.md |
| S-3 | jules/s-3-variable-shadow-check-4550002245138056927 | merged | 2026-11-02 | Codex | PR #71, tip fe604cc115c4: selected in the 2 Nov batch; plans/reference/jules-integration-2026-11-02.md |
| S-3 | jules/s-3-json-number-check-9881808165647906092 | returned | 2026-11-02 | Codex | Fix false positives on string membership and loop-scope leakage; cover or narrow direct .get/equality claims; see F5. Details: plans/reference/jules-review-2026-11-02.md; correction task J-44 |
| S-1 | jules/s-1-check-docs-helpers-9669511251849698836 | merged | 2026-11-02 | Codex | PR #73, tip df51a1d3a2b0: selected in the 2 Nov batch; plans/reference/jules-integration-2026-11-02.md |
| S-1 | jules/s-1-forager-tuning-helpers-13162614551103306493 | merged | 2026-11-02 | Codex | PR #74, tip e0f9e9381a1e: selected in the 2 Nov batch; plans/reference/jules-integration-2026-11-02.md |
| S-3 | jules/s-3-nav-reach-check-guard-9967578517215891885 | returned | 2026-11-02 | Codex | Verify arithmetic of reach, rather than presence of field names; subtraction mutation currently passes; see F7. Details: plans/reference/jules-review-2026-11-02.md; correction task J-45 |
| S-3 | jules/s-3-skirt-commitment-check-16220641419636133711 | returned | 2026-11-02 | Codex | Track enclosing debounce scope, not any earlier comparison; real unguarded-clear mutation passes; see F6. Details: plans/reference/jules-review-2026-11-02.md; correction task J-46 |
| S-3 | jules/s-3-marker-reparent-check-guard-11214790423381160683 | closed | 2026-11-02 | Codex | Superseded by PR #79; J-47 owns one corrected two-file marker guard; neither current implementation is accepted |
| S-1 | jules/s-1-scenario-sweep-helpers-17495932287149803494 | merged | 2026-11-02 | Codex | PR #78, tip 0bd54cc2f296: selected in the 2 Nov batch; plans/reference/jules-integration-2026-11-02.md; only tests/test_scenario_sweep_helpers.py, discard fourteen unrelated files |
| S-3 | jules/s-3-marker-reparent-check-9499576018780718307 | returned | 2026-11-02 | Codex | Rebuild clean two-file branch and detect commented-out reparent calls; retain visit-point coverage; see F1/F4. Details: plans/reference/jules-review-2026-11-02.md; correction task J-47 |
| S-1 | jules/s-1-seed-set-evidence-helpers-15248905811653166071 | merged | 2026-11-02 | Codex | PR #80, tip 2ec983f302ee: selected in the 2 Nov batch; plans/reference/jules-integration-2026-11-02.md |
| S-1 | jules/s-1-equivalence-helpers-11773666711536226406 | merged | 2026-11-02 | Codex | PR #81, tip 7e37a65527bc: selected in the 2 Nov batch; plans/reference/jules-integration-2026-11-02.md |
| S-1 | jules/s-1-run-scenario-helpers-13225724011224739330 | returned | 2026-11-02 | Codex | Use host-native str(result_path) in expected terminal lines and rerun on Windows; two of nine tests fail; see F3. Details: plans/reference/jules-review-2026-11-02.md; correction task J-49 |
| S-1 | jules/s-1-pacing-gates-helpers-10804032720064866768 | merged | 2026-11-02 | Codex | PR #83, tip 0d9f7a25fd3d: selected in the 2 Nov batch; plans/reference/jules-integration-2026-11-02.md |
| S-3 | jules/s-3-drained-flower-exclusion-17983441332586359927 | returned | 2026-11-02 | Codex | Require an actual rejecting cooldown predicate and assignment, not token presence; accepting-cooled-flower mutation passes; see F6. Details: plans/reference/jules-review-2026-11-02.md; correction task J-48 |
