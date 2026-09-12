# Agent lifecycle L-1 — the lifecycle suite is green and runs in verification

Shipped 12 Sep 2026 to `master` (merge `d295b6d`, branch `claude/L-1`).
Archived out of `plans/now/agent-lifecycle.md`, which owns the plan's
remaining slices (L-2 onward).

**Objective.** Fix the three failing tests in `tests/test_source_checks.py`,
then add that file to `tools/verify.ps1` so it can never silently rot again.

**Non-goals.** Do not change `slice.ps1`'s behaviour. Do not add the other 14
`tests/test_*.py` files to verification; several drive Godot and belong to a
later decision.

**Files.** `tests/test_source_checks.py`, `tools/verify.ps1`. Read
`scripts/debug_panel.gd` to find the renamed function; do not edit it --
`UI-U-1` in the Codex lane owns it.

**Prerequisite.** None.

**Algorithm as specified.**

1. `test_mock_slice_can_claim_commit_and_close` fails at "could not
   regenerate checks/ready.md". In that test's `setUp`, create
   `checks/ready` as a directory and write `checks/ready.md` with the header
   `check_docs.py --write-ready-index` expects, before the fixture commit.
2. `test_doctor_reports_all_environment_failures_together` asserts `Python:`
   is in stderr, but a `git ls-remote` failure now reaches stderr first. The
   test's intent is that all environment failures are reported together, so
   assert each expected prefix is present with `assertIn`, in no particular
   order, rather than relying on which came first.
3. `test_orientation_flight_and_scouting_are_symmetric_alternatives` raises
   `IndexError` because `scripts/debug_panel.gd` no longer contains
   `_cascade_prerequisites_on_static`. Find the function that now performs
   the prerequisite cascade and split on its name.
4. In `tools/verify.ps1`, add a third `Start-Job` alongside "source checks"
   and "balance tests", named "lifecycle tests", running
   `& $interpreter -m unittest tests.test_source_checks`.

**What actually shipped, and where it departed from the spec.**

1. As specified: `SliceDoctorTest.setUp` now creates `checks/ready/` and
   writes `checks/ready.md` with the real header, and also copies
   `tools/check_docs.py` into the fixture's `tools/` directory -- the plan's
   repro only found the missing directory; the fixture's `tools/` never had
   `check_docs.py` at all, so `& $python $indexGenerator --write-ready-index`
   had nothing to run.
2. As specified: `assertIn` per prefix, unordered.
3. The function moved to `scripts/settings_catalogue.gd` (still named
   `_cascade_prerequisites_on_static`), not deleted. The test now reads that
   file instead of `debug_panel.gd`.
4. As specified.

**Departure from the plan's Non-goal.** Step 2's fix alone was not
sufficient in this environment: with only Windows PowerShell 5.1 available
(no `pwsh`), `git ls-remote`'s stderr, redirected via `2>&1`, is promoted to
a terminating error under `$ErrorActionPreference = "Stop"`. This aborted
`Get-DoctorEnvironmentFailures` at the first failing native call and lost
every failure gathered before it (Python, Godot, Git identity) -- the exact
condition the "reports failures together" test exists to catch, and
unreachable by reordering the assertion alone. Dave confirmed fixing
`slice.ps1` was in scope for this finding (12 Sep 2026); the fix scopes
`$ErrorActionPreference = "Continue"` to `Get-DoctorEnvironmentFailures`
only, the same pattern `verify.ps1`'s `Invoke-PythonStage` already uses for
this class of bug.

**Tests and failure injection, as run.** All 32 tests in
`tests/test_source_checks.py` pass (not 27 -- the file has grown since the
plan was written). Deleting `slice.ps1`'s post-merge `if ($LASTEXITCODE -ne
0) { throw "git merge failed" }` and rerunning the suite did **not** turn
any test red: no fixture in `SliceDoctorTest` exercises a genuine `git
merge` conflict, so the throw's absence is currently unobserved by any
assertion. The throw was restored unchanged. This is a real coverage gap,
not this slice's to close -- flagged here rather than silently claimed as
covered.

**Two unrelated findings surfaced while landing this slice, both fixed in
the same pass since they blocked `tools/verify.ps1` / `slice.ps1 finish`:**

- A fresh `.worktrees/*` checkout has no `.godot/imported/` cache (it's
  gitignored, per-checkout state), so the headless Godot boot stage failed
  with `SCRIPT ERROR: Parse Error: Could not preload resource file
  "res://assets/sprites/environment/wax.cell.empty.png"` -- unrelated to any
  code change. Fixed by copying `.godot/imported/` from the primary checkout
  into the worktree.
- `.worktrees/godot-boot-fix` (branch `codex/godot-boot-fix`) was registered
  with Git but had no `plans/workstreams.md` row, failing `doc checks`. The
  branch had no commits ahead of `master` (fully merged already); removed
  the worktree and deleted the branch from the primary checkout.
- `slice.ps1 finish`'s worktree-removal retry loop hit `Permission denied`
  when run with the shell's own working directory still inside
  `.worktrees/L-1` (a known Windows cwd-lock issue). The merge and push had
  already succeeded by that point; `resume` also failed once more because
  Git had already pruned the worktree registration internally, leaving only
  a directory prune, branch delete and ledger-row removal to finish by hand.

**Proof.** `absent: tools/verify.ps1 :: test_source_checks` -- holds.

**Risk realised.** Medium, as predicted: the added "lifecycle tests" stage,
plus the doctor fix, turned two previously-invisible problems (the crash on
any git stderr, and the two closeout/worktree hygiene issues above) visible
during this slice's own closeout.

**Expected improvement, delivered.** The 3 red tests are 0 (32/32 pass), and
`tools/verify.ps1` now runs `tests/test_source_checks.py` as a third
parallel job, so a future regression in `slice.ps1`, the Codex permission
profile or the verifier's Python resolution fails verification instead of
shipping quietly.

**Follow-ups filed, not fixed here:**
- No test currently fails if `slice.ps1`'s post-merge `git merge` throw is
  deleted -- a real merge-conflict fixture is missing from `SliceDoctorTest`.
  Not filed as a queue item; left for whoever next touches merge-failure
  handling in this plan (L-3 to L-6 all touch `slice.ps1`'s closeout path).
