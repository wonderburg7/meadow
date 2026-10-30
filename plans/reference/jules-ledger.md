# Jules ledger -- what happened to each Jules branch

<!-- CONTEXT: reference | LAYER: reference | LOAD: through `python tools/jules_preflight.py --ledger`; append a row, never read the whole file -->
Status: reference | Owner: Dave / Claude Code / Codex | Next: add a row for each Jules branch you process; `--ledger` lists any left unreviewed | Dependency: `tools/jules_preflight.py` | Verified: 2026-10-30

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
| friction | jules/workflow-friction-recommendations-5502329343734512397 | closed | 2026-10-26 | Claude | Proposal re-verified into `plans/now/workflow-friction.md` FX-1 to FX-6 (cc56822); the proposal file itself was not merged |
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
