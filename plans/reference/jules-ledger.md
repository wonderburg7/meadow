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
| J-31 | jules/j-31-coordinate-spaces-13284476037409319937 | returned | 2026-11-02 | Codex | Corrected date/honey/camera conclusions, but audit still lacks operand parents and complete expression coverage; see F8. Details: plans/reference/jules-review-2026-11-02.md; correction task J-31 |
| R-gameplay | jules/r-gameplay-review-2026-10-30-8334134721198376116 | returned | 2026-11-02 | Codex | Reject automatic gameplay fixes; supply causal reproductions, honour queen contract, fix R2 proof and missing test module; see F2. Details: plans/reference/jules-review-2026-11-02.md; correction task J-51 |
| R-ui | jules/r-ui-2026-10-30-4481302975311752886 | returned | 2026-11-02 | Codex | Weather state already has non-colour wording; separate proposed layout coverage from demonstrated defects and remove visual-verification claim. Details: plans/reference/jules-review-2026-11-02.md; correction task J-52 |
| R-architecture | jules/r-architecture-review-2026-10-30-13822823161316074019 | returned | 2026-11-02 | Codex | Respect planned adaptation/skill APIs and D1; separate the eligible is_mastered cleanup (#63), remove reused J-43 and unsupported all-free claim. Details: plans/reference/jules-review-2026-11-02.md; correction task J-53 |
| S-3 | jules/s-3-json-number-check-9881808165647906092 | returned | 2026-11-02 | Codex | Fix false positives on string membership and loop-scope leakage; cover or narrow direct .get/equality claims; see F5. Details: plans/reference/jules-review-2026-11-02.md; correction task J-44 |
| S-3 | jules/s-3-nav-reach-check-guard-9967578517215891885 | returned | 2026-11-02 | Codex | Verify arithmetic of reach, rather than presence of field names; subtraction mutation currently passes; see F7. Details: plans/reference/jules-review-2026-11-02.md; correction task J-45 |
| S-3 | jules/s-3-skirt-commitment-check-16220641419636133711 | returned | 2026-11-02 | Codex | Track enclosing debounce scope, not any earlier comparison; real unguarded-clear mutation passes; see F6. Details: plans/reference/jules-review-2026-11-02.md; correction task J-46 |
| S-3 | jules/s-3-marker-reparent-check-9499576018780718307 | returned | 2026-11-02 | Codex | Rebuild clean two-file branch and detect commented-out reparent calls; retain visit-point coverage; see F1/F4. Details: plans/reference/jules-review-2026-11-02.md; correction task J-47 |
| S-1 | jules/s-1-run-scenario-helpers-13225724011224739330 | returned | 2026-11-02 | Codex | Use host-native str(result_path) in expected terminal lines and rerun on Windows; two of nine tests fail; see F3. Details: plans/reference/jules-review-2026-11-02.md; correction task J-49 |
| S-3 | jules/s-3-drained-flower-exclusion-17983441332586359927 | returned | 2026-11-02 | Codex | Require an actual rejecting cooldown predicate and assignment, not token presence; accepting-cooled-flower mutation passes; see F6. Details: plans/reference/jules-review-2026-11-02.md; correction task J-48 |
| R-gameplay | jules/r-gameplay-review-2026-11-04-12219810295421638867 | merged | 2026-11-04 | Claude | record docs/gameplay-review-2026-11-04.md; 0 queued, 0 gated, 0 decided, 3 rejected; sweep covered 9 of 85 changed scripts, the rest carried forward under "Not reviewed" |
| S-1 | jules/s-1-jules-efficiency-helpers-6778388655859661860 | merged | 2026-11-05 | Codex | #85 at ed281d8dfb86734df44f5474854be1f6c97904c5: Only tests/test_jules_efficiency_helpers.py; five tests pass. Details: plans/reference/jules-integration-2026-11-04.md |
| E-2 | jules/e-2-slice-briefs-criteria-5253806536691950342 | closed | 2026-11-05 | Codex | #86 at 8a537906b483f6cc89e14eec7bfd3945e9d0c054: Superseded by selected E14/#105 evidence once; neither feature implemented. Details: plans/reference/jules-integration-2026-11-04.md |
| S-3 | jules/s-3-freeze-bee-restart-check-10011546828397471687 | merged | 2026-11-05 | Codex | #87 at f90a7199eae5547449b52036de0b90b47c99743e: Corrected consolidated tools/freeze_bee_check.py and tests; actual idle assignment and executable stage command path required. Details: plans/reference/jules-integration-2026-11-04.md |
| S-3 | jules/s-3-nearest-exclusion-check-7376882027535310623 | closed | 2026-11-05 | Codex | #88 at 7cb66a77f0a1a8c9b20aa278d7d47c3657aa6837: Superseded by corrected J-48; cooled-flower rejection coverage consolidated, duplicate tool excluded. Details: plans/reference/jules-integration-2026-11-04.md |
| S-1 | jules/s-1-backlog-helpers-4079110550795510746 | merged | 2026-11-05 | Codex | #89 at 20f45029652a52ff49de042ea18342eb6a0cb2dd: Only tests/test_backlog_helpers.py; ten tests pass. Details: plans/reference/jules-integration-2026-11-04.md |
| S-3 | jules/s-3-nearest-standing-check-12917755967047407471 | closed | 2026-11-05 | Codex | #90 at faec3f29a77995d80a3e536a5fc6e9fc38495b76: Superseded by corrected J-48; comments and predator-cooldown tokens cannot satisfy personal cooldown rejection. Details: plans/reference/jules-integration-2026-11-04.md |
| S-3 | jules/s-3-bee-idle-dispatch-guard-1752987530741265881 | closed | 2026-11-05 | Codex | #91 at 20a823b1a9f8349925671b279e4d5b08eac0d89e: Consolidated into corrected #87 guard; workstreams snapshot and duplicate guard excluded. Details: plans/reference/jules-integration-2026-11-04.md |
| J-31 | jules/j-31-coordinate-spaces-5352726798831459091 | merged | 2026-11-05 | Codex | #92 at 1a8732d33c6e4aba242fb813f51b1b7de6491207: Corrected J-31 report only: actual critical parent traces, honest low-confidence unknowns, pinned reproducible candidate inventory. No blanket clean conclusion. Details: plans/reference/jules-integration-2026-11-04.md |
| E-4 | jules/e-4-navigation-ownership-3889998738527950591 | merged | 2026-11-05 | Codex | #93 at c9d21a5fa691e5231e08be249de09ec6f265842a: Selected E4 evidence combined with #104 in docs/jules-efficiency/e-4.md; proposals routed to plans/reference/developer-navigation.md. Details: plans/reference/jules-integration-2026-11-04.md |
| J-44 | jules/j-44-json-number-guard-16720143125338076236 | merged | 2026-11-05 | Codex | #94 at 205292e8b895d550b50fe59082db0623a29c1ab5: Corrected J-44 two-file guard; executable numeric provenance, comment/string handling and loop/function boundaries tested. Details: plans/reference/jules-integration-2026-11-04.md |
| E-6 | jules/e-6-game-slice-contracts-16904795982988752181 | closed | 2026-11-05 | Codex | #95 at 3ed2925f909ac863c9d4c383dc34bf6fc08cfc2a: False source-check omission rejected; qualified rule-routing proposal retained with #103 dispositions in e-6.md and closeout reference. No efficiency feature implemented. Details: plans/reference/jules-integration-2026-11-04.md |
| J-45 | jules/j-45-nav-reach-arithmetic-15721183918715233601 | merged | 2026-11-05 | Codex | #96 at 0c4da9b31a8fef57c664bb9e59476b1800eac336: Only J-45 tools/nav_reach_check.py and tests; four actual-source reach mutations rejected. Details: plans/reference/jules-integration-2026-11-04.md |
| E-8 | jules/e-8-verification-failure-diagnosis-6959932918896562494 | merged | 2026-11-05 | Codex | #97 at d2194de77710846faed6af0e07e74a130dec72fb: Qualified E8 report: bounded empty-selection evidence and optional final summary; false interleaving/run_pool claims removed; closeout reference. Details: plans/reference/jules-integration-2026-11-04.md |
| J-46 | jules/j-46-obstacle-commitment-nesting-16290218844411391879 | merged | 2026-11-05 | Codex | #98 at 4691d8246fbe83c9fe40038fef543eb862129268: Corrected J-46 two-file guard rejects zero/single-frame, unknown constants, bypass and out-of-scope clears. Details: plans/reference/jules-integration-2026-11-04.md |
| E-10 | jules/e-10-handoffs-2330467120363349948 | merged | 2026-11-05 | Codex | #99 at 7b223d3fa8f5e840c91535cc3aa33936bfd3fd44: Selected E10 formatter proposal only; correction-instruction gap rejected; closeout reference. Details: plans/reference/jules-integration-2026-11-04.md |
| J-47 | jules/j-47-marker-reparent-check-9719546980713594969 | merged | 2026-11-05 | Codex | #100 at 85f71a2e78dc867677f73cdf0a5b5fe548992798: Corrected J-47 two-file guard; quoted/commented/branch-local calls fail; both marker functions/order/stages/missing-input tests retained. Details: plans/reference/jules-integration-2026-11-04.md |
| E-12 | jules/e-12-tools-docs-setup-793071273883827496 | merged | 2026-11-05 | Codex | #101 at b5a085ffa19d3f7d206ec1f469c52737a3487796: Qualified E12 report; correct provenance and helpers; optional heading listing and shared unit discovery routed to navigation/closeout references. Details: plans/reference/jules-integration-2026-11-04.md |
| J-48 | jules/j-48-drained-flower-exclusion-check-17335276923350667350 | merged | 2026-11-05 | Codex | #102 at 9ff79b5521f50c03491773c564743785281b724f: Corrected J-48 two-file guard rejects accepting-cooled flowers, strict-gated rejection, comparison/read/comment/string updates; one guard replaces duplicates. Details: plans/reference/jules-integration-2026-11-04.md |
| E-6 | jules/e-6-game-slice-contracts-2168704635154320974 | closed | 2026-11-05 | Codex | #103 at df578335e9c74dde86dd76f7eed01225bd8e755f: Existing RR-10 coverage and finder bool contract acknowledged; unsupported gap/defect claims rejected alongside #95. No game feature implemented. Details: plans/reference/jules-integration-2026-11-04.md |
| E-4 | jules/e-4-code-navigation-7869406311791392932 | merged | 2026-11-05 | Codex | #104 at dfdfb245e8fc93be18869e173c33cc22750d0c57: Complementary selected E4 evidence combined with #93, not overwritten; historical counts/savings/ownership qualified. Details: plans/reference/jules-integration-2026-11-04.md |
| E-14 | jules/e-14-slice-briefs-5523427098625137402 | merged | 2026-11-05 | Codex | #105 at 31f517e8ea2f55b6d7f0a330a7ed2c710f55d531: Qualified E14 report only; 42 snapshot paths excluded. E2 proposals adopted once as unscheduled closeout contracts. Details: plans/reference/jules-integration-2026-11-04.md |
| J-49 | jules/j-49-portable-run-scenario-tests-9096174314304782303 | merged | 2026-11-05 | Codex | #106 at 17f65d673d027e734b9c3b909d34e30380ec9fd5: J-49 test file only; nine tests pass on Windows with native str(result_path); Linux unavailable. Details: plans/reference/jules-integration-2026-11-04.md |
| J-50 | jules/j-50-fail-closed-missing-inputs-7617937781064947169 | merged | 2026-11-05 | Codex | #108 at 3bbd44dbd35809a0d542132d7f65e89df8e60500: J-50 incremental missing-input and real-tree tests/tool change only; eleven tests pass. Original class/property map boundary retained. Details: plans/reference/jules-integration-2026-11-04.md |
| J-51 | jules/j-51-correct-gameplay-review-3492990058968866443 | merged | 2026-11-05 | Codex | #110 at 3cb7c818c21d8e91e2190bf2e16e08b9707f2152: J-51 report only, further qualified: D2 resolved; no causal loss/overwrite reproduction; no source/save change. Details: plans/reference/jules-integration-2026-11-04.md |
| J-52 | jules/j-52-ui-review-correction-7702919887724336091 | merged | 2026-11-05 | Codex | #112 at 5aa7fd4e2025de2bd0ce7e97965feec4e89f72f9: J-52 report only, further qualified: distinct weather text; More coverage observation, no rendered-verification claim. Details: plans/reference/jules-integration-2026-11-04.md |
| J-53 | jules/j-53-correct-architecture-review-1329968156573293049 | merged | 2026-11-05 | Codex | #114 at 8f25e87f070cd20e7b46e2285a2e4ee8435b6367: J-53 report only, further qualified: D1 resolved; is_mastered already delivered; no uncalled-to-safe-deletion inference. Details: plans/reference/jules-integration-2026-11-04.md |
| J-31 | jules/j-31-coordinate-spaces-13284476037409319937 | closed | 2026-11-05 | Codex | Corrected report delivered under #92; old clean conclusion not accepted. Details: plans/reference/jules-integration-2026-11-04.md |
| R-gameplay | jules/r-gameplay-review-2026-10-30-8334134721198376116 | closed | 2026-11-05 | Codex | Superseded by corrected J-51/#110; D2 retained. New #116 processing by Claude in 8dc78d3 is preserved. Details: plans/reference/jules-integration-2026-11-04.md |
| R-ui | jules/r-ui-2026-10-30-4481302975311752886 | closed | 2026-11-05 | Codex | Superseded by corrected J-52/#112; no visual result inferred. Details: plans/reference/jules-integration-2026-11-04.md |
| R-architecture | jules/r-architecture-review-2026-10-30-13822823161316074019 | closed | 2026-11-05 | Codex | Superseded by corrected J-53/#114; D1 resolved, no API deletion. Details: plans/reference/jules-integration-2026-11-04.md |
| S-3 | jules/s-3-json-number-check-9881808165647906092 | closed | 2026-11-05 | Codex | Superseded by corrected J-44/#94 two-file guard. Details: plans/reference/jules-integration-2026-11-04.md |
| S-3 | jules/s-3-nav-reach-check-guard-9967578517215891885 | closed | 2026-11-05 | Codex | Superseded by J-45/#96. Details: plans/reference/jules-integration-2026-11-04.md |
| S-3 | jules/s-3-skirt-commitment-check-16220641419636133711 | closed | 2026-11-05 | Codex | Superseded by corrected J-46/#98. Details: plans/reference/jules-integration-2026-11-04.md |
| S-3 | jules/s-3-marker-reparent-check-9499576018780718307 | closed | 2026-11-05 | Codex | Superseded by corrected J-47/#100; unrelated snapshot excluded. Details: plans/reference/jules-integration-2026-11-04.md |
| S-1 | jules/s-1-run-scenario-helpers-13225724011224739330 | closed | 2026-11-05 | Codex | Superseded by Windows-verified J-49/#106; Linux unavailable. Details: plans/reference/jules-integration-2026-11-04.md |
| S-3 | jules/s-3-drained-flower-exclusion-17983441332586359927 | closed | 2026-11-05 | Codex | Superseded by corrected J-48/#102; no duplicate guard delivered. Details: plans/reference/jules-integration-2026-11-04.md |
