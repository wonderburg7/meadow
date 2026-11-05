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
| R-architecture | jules/r-architecture-2026-11-04-15367879663082408149 | closed | 2026-11-05 | Claude | superseded by docs/architecture-review-2026-11-04.md (full Claude sweep of 8dc78d3); report spot-checked sound but thin (8 of 86 files); its findings: dead helpers rejected (below the bar), D1 already decided 2 Nov, HUD extraction noted; side find PN-17 plan corrected; Jules-Sequence: 29 ordinary |
