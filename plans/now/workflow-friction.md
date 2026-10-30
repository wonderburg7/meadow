# Workflow friction -- six small fixes from the 25 Oct 2026 friction review

<!-- CONTEXT: plan | LAYER: immediate-task -->

Status: active | Owner: Dave / Codex (moved to the Codex lane by Dave, 30 Oct 2026) | Next: FX-2, finish checks the primary is on master before verifying | Dependency: none; FX-1 to FX-6 share no file and run in id order | Verified: 2026-10-26

## Objective

Remove the workflow friction that Jules's proposal (commit `cdc3a03` on
`origin/jules/workflow-friction-recommendations-5502329343734512397`,
plans/proposals/workflow-friction-recommendations.md on that branch) found and this plan
re-verified against master at `0fa85bd`. Every slice is low reasoning: the
exact edit, its place and its acceptance commands are written here, so a
worker reads this plan's own section and nothing else.

## Current state

What the 26 Oct 2026 re-verification found, cluster by cluster:

- **A (finish ordering).** Mostly already fixed. `Assert-PrimaryIndexMatchesHead`
  has run before branch verification since `1595a8b` (25 Oct 2026), and
  `-Scope primary` runs only `doc checks` (median 3.3 s), not 8 to 11
  minutes. The one gap left: the "primary checkout is on master" check runs
  only under the lock, after branch verification. FX-2 moves it in front too.
  A bounded retry in `/run-queue` is not specified: a dirty primary is a
  person's work, not a transient state, and the stop already names the fix.
  The L-37 staged files were J-12's, staged by a Jules merge done in the
  primary checkout; FX-3 moves that merge into a worktree.
- **B (guard hook).** Confirmed live: on 26 Oct the hook refused
  `... | grep -v "^plans/archive"`. 65 of the 107 recorded refusals
  (23 to 24 Oct) were "denied path"; FX-1. The `cd ../.. && ... finish`
  case has no recorded refusal, so it is not specified.
- **C (verification scope).** The `jules.md` claim is wrong: Jules runs on
  Linux and never runs `verify.ps1` (step 8 lists it under `Not run:`). The
  job root is required to sit under the system temp directory
  (`validate_job_root`), so redirecting `TEMP` is a design change, not a fix.
  `tests/test_headless_jobs.py` did error twice in recorded verify runs
  (L-30 branch, `worktree-cleanup-diagnostics`), cause not recorded; FX-4
  stops a cleanup error failing a test.
- **D (environment).** The Godot skip-when-missing is deliberate and
  documented in `tools/verify.ps1` and asserted by
  `tests/test_godot_compile_check.py`; making it fail is Dave's decision,
  not a slice. The hard-coded `C:\Users\dl13860\...` `ROOT` is real in five
  skill files. `git rev-parse --show-toplevel` (the proposal's fix) is wrong
  from a worktree; the parent of `git rev-parse --path-format=absolute
  --git-common-dir` is right from both (checked 26 Oct). FX-5 and FX-6.
- **E (blocked checks).** Ten checks wait only for shipped slices, but Dave
  declined automatic release in `finish` on 16 Oct 2026
  (`docs/agent-workflow-review-2026-10-16.md`, "Patterns deliberately not
  applied"). Moving them is the check processor's first step. Not specified.
- **F (permissions, effort).** `slice-worker-low.md`'s `effort: medium` is
  deliberate (`aba5823`, 8 Oct 2026: "Haiku 5.5 at medium effort"). Not
  specified. The Codex write probe is FX-6.

## Open slices

| Slice | What it does | Files it owns | Startable | Level |
| --- | --- | --- | --- | --- |
| FX-2 | finish checks the primary is on master before verifying | `tools/slice.ps1`, `tests/test_slice_lifecycle.py` | yes | low |
| FX-3 | Jules merges happen in a worktree | `plans/reference/jules.md` | yes | low |
| FX-4 | headless job tests ignore temp cleanup errors | `tests/test_headless_jobs.py` | yes | low |
| FX-5 | Claude skills derive `ROOT` | `.claude/skills/run-queue/SKILL.md`, `.claude/skills/run-reviews/SKILL.md`, `.claude/skills/plan-ahead/SKILL.md` | yes | low |
| FX-6 | Codex skills derive `ROOT`; Codex run-queue probes `.git` | `.agents/skills/run-queue/SKILL.md`, `.agents/skills/plan-ahead/SKILL.md` | yes | low |

No slice depends on another. They are chained by `Next after:` in id order
only so the lane refills itself. **Do not change** any behaviour this plan
does not name: each slice's "Do not" line says what a past fix relied on.

**Read for any slice here:** its own section below and nothing else.

FX-1 shipped 2026-10-30; its specification is `plans/archive/FX-1_2026-10-30.md`.

## FX-2 -- finish checks the primary is on master before verifying

**Now.** In `tools/slice.ps1`, `Invoke-SliceFinish` checks the primary
checkout's branch only under the lock (the four lines after
`Set-SliceStep "primary checkout checks"`), after `Invoke-SliceFinishVerify`
has already run the branch's `verify.ps1` (unit tests median 376 s).
7 Oct 2026: a finish stopped there with the primary on `codex/refill-ar3`.

**Edit `tools/slice.ps1`.**

1. Directly after the closing `}` of `function Assert-PrimaryIndexMatchesHead`,
   add:

   ```powershell
   function Assert-PrimaryOnMaster {
       # finish merges into master from the primary checkout. Checked before
       # the branch verify as well as under the lock, so a primary left on
       # another branch stops finish in seconds, not after verify.ps1
       # (7 Oct 2026: 'codex/refill-ar3').
       param([object]$Target)
       $primaryBranch = (Invoke-GitText -C $Target.Root rev-parse --abbrev-ref HEAD).Text.Trim()
       if ($primaryBranch -ne "master") {
           Stop-Slice -Cause "primary checkout is on '$primaryBranch', not master" -Fix "in the primary checkout run git switch master (commit or stash-by-WIP-commit anything there first), then retry"
       }
   }
   ```

2. In `function Invoke-SliceFinishVerify`, insert
   `        Assert-PrimaryOnMaster -Target $target` on its own line between
   `$target = Get-SliceFinishTarget` and `Assert-PrimaryIndexMatchesHead -Target $target`.
3. In `function Invoke-SliceFinish`, replace the four lines starting
   `    $primaryBranch = (git rev-parse --abbrev-ref HEAD).Trim()` and ending
   with that `if` block's closing `}` with `    Assert-PrimaryOnMaster -Target $target`.
4. In the header index line `Invoke-SliceFinishVerify/BranchVerify (finish's
   branch verify, before the lock)`, no change is needed.

**Edit `tests/test_slice_lifecycle.py`.** Copy
`test_finish_stops_before_verifying_on_a_staged_file_in_the_primary_checkout`
to a new method directly below it, named
`test_finish_stops_before_verifying_when_the_primary_checkout_is_off_master`,
with these changes only: docstring "A primary left on another branch stops
finish before the branch verify (7 Oct 2026)."; replace the two lines that
write and git-add the someone_elses.py fixture file with
`subprocess.run(["git", "switch", "-q", "-c", "side"], cwd=self.root, check=True)`;
replace the `assertIn("staged changes ...")` line with
`self.assertIn("primary checkout is on 'side', not master", output)`; keep
`assertNotIn("verify.ps1 (-Scope branch) failed", output)`; replace the final
`staged = ...` and its assertion with an assertion that
`git rev-parse --abbrev-ref HEAD` in `self.root` still prints `side`.

**Do not** move the dirty-lifecycle-products check or the second
`Assert-PrimaryIndexMatchesHead` call: both must stay under the lock.

**Acceptance.** `python -m unittest tests.test_slice_lifecycle.SliceDoctorTest.test_finish_stops_before_verifying_when_the_primary_checkout_is_off_master tests.test_slice_lifecycle.SliceDoctorTest.test_finish_stops_before_verifying_on_a_staged_file_in_the_primary_checkout`
passes; `python tools/prefinish.py` passes (finish's `verify.ps1` then runs
the whole lifecycle suite).

**Open decisions:** none.

```queue
**[Codex] FX-2 -- finish checks the primary is on master before verifying**
- Plan: `plans/now/workflow-friction.md` -- "FX-2 -- finish checks the primary is on master before verifying"
- Files: `tools/slice.ps1`, `tests/test_slice_lifecycle.py`
- Check: `python -m unittest tests.test_slice_lifecycle.SliceDoctorTest.test_finish_stops_before_verifying_when_the_primary_checkout_is_off_master tests.test_slice_lifecycle.SliceDoctorTest.test_finish_stops_before_verifying_on_a_staged_file_in_the_primary_checkout` passes; `python tools/prefinish.py` passes
- Proof: `absent: tools/slice.ps1 :: function Assert-PrimaryOnMaster`
- Next after: FX-3 -- Jules merges happen in a worktree
```

## FX-3 -- Jules merges happen in a worktree

**Now.** `plans/reference/jules.md` § "Keeping this list", bullet
"**Before merging a Jules pull request**", says to run
`git checkout origin/jules/<branch> -- <those files>` but not where. Done in
the primary checkout it stages them on master; J-12's files staged that way
stopped L-37's finish on 25 Oct 2026 (`1595a8b`).

**Edit `plans/reference/jules.md`.** At the end of that bullet (after "as J-3,
J-8 and J-9 each needed."), append this text as part of the same bullet:

> Do all of it in a worktree of its own, never in the primary checkout:
> `git worktree add .claude/worktrees/jules-J-<n> -b claude/jules-J-<n> origin/master`,
> check out the files and commit there, then merge that branch into master.
> A `git checkout <ref> -- <files>` in the primary checkout stages them on
> master, and the next `tools/slice.ps1 finish` stops on "staged changes"
> (L-37, 25 Oct 2026).

Wrap at about 76 columns like the lines around it. **Do not** edit the
"How to work" steps: they are Jules's, and Jules never merges.

**Acceptance.** `python tools/check_docs.py` passes;
`git grep -n "never in the primary checkout" -- plans/reference/jules.md`
prints one line.

**Open decisions:** none.

```queue
**[Codex] FX-3 -- Jules merges happen in a worktree**
- Plan: `plans/now/workflow-friction.md` -- "FX-3 -- Jules merges happen in a worktree"
- Files: `plans/reference/jules.md`
- Check: `python tools/check_docs.py` passes; `git grep -n "never in the primary checkout" -- plans/reference/jules.md` prints one line in the "Before merging a Jules pull request" bullet
- Proof: `absent: plans/reference/jules.md :: never in the primary checkout`
- Next after: FX-4 -- headless job tests ignore temp cleanup errors
```

## FX-4 -- headless job tests ignore temp cleanup errors

**Now.** All six `with tempfile.TemporaryDirectory() as directory:` blocks
in `tests/test_headless_jobs.py` delete the job directory as the test ends.
On Windows a just-finished runner can still hold `process.log` open, and the
deletion error fails the test as an ERROR (recorded twice in verify runs).
The cause is not proved; this removes the one candidate a test should not
fail on, since cleanup is not what the tests assert.

**Edit `tests/test_headless_jobs.py`.** Replace every
`tempfile.TemporaryDirectory()` with
`tempfile.TemporaryDirectory(ignore_cleanup_errors=True)` (six places; CI
runs Python 3.12, local 3.14, both have it). Above the first one add:
`# A runner that has just exited can still hold process.log open on Windows;`
`# deleting the temp tree is not what these tests assert.` (two comment lines).

**Do not** change any assertion, timeout or `tools/headless/jobs.py`.

**Acceptance.** `python -m unittest tests.test_headless_jobs` passes five
times running. Git Bash, from the slice worktree:
`for i in 1 2 3 4 5; do python -m unittest tests.test_headless_jobs || break; done`.
If it errors after this change, the cause is not cleanup: report it as
`failed` with the traceback rather than editing further.

**Open decisions:** none.

```queue
**[Codex] FX-4 -- headless job tests ignore temp cleanup errors**
- Plan: `plans/now/workflow-friction.md` -- "FX-4 -- headless job tests ignore temp cleanup errors"
- Files: `tests/test_headless_jobs.py`
- Check: `python -m unittest tests.test_headless_jobs` passes five runs in a row with all six temp directories created with `ignore_cleanup_errors=True`; no assertion changed
- Proof: `absent: tests/test_headless_jobs.py :: ignore_cleanup_errors`
- Next after: FX-5 -- Claude skills derive `ROOT`
```

## FX-5 -- Claude skills derive `ROOT`

**Now.** Three Claude skills hard-code the primary checkout as
`C:\Users\dl13860\Documents\Meadow\meadow`.

**Edit, replacing only the quoted text:**

1. `.claude/skills/run-queue/SKILL.md` and `.claude/skills/run-reviews/SKILL.md`,
   the line beginning `` `ROOT` is the primary checkout: ``: replace
   `` `C:\Users\dl13860\Documents\Meadow\meadow`. `` with
   `` the parent of `git rev-parse --path-format=absolute --git-common-dir`, the same from the primary checkout and any worktree (PowerShell: `Split-Path -Parent (git rev-parse --path-format=absolute --git-common-dir)`). Work it out once, at the start of the run. ``
2. `.claude/skills/plan-ahead/SKILL.md`: replace
   `` (`C:\Users\dl13860\Documents\Meadow\meadow`). `` with
   `` (the parent of `git rev-parse --path-format=absolute --git-common-dir`). ``

Rewrap the changed paragraph at about 76 columns. **Do not** touch
`.agents/skills/` (FX-6) or any other line.

**Acceptance.** `git grep -n dl13860 -- .claude/skills` prints nothing;
`python -m unittest tests.test_cx2_queue_steward` passes;
`python tools/check_docs.py` passes.

**Open decisions:** none.

```queue
**[Codex] FX-5 -- Claude skills derive `ROOT`**
- Plan: `plans/now/workflow-friction.md` -- "FX-5 -- Claude skills derive `ROOT`"
- Files: `.claude/skills/run-queue/SKILL.md`, `.claude/skills/run-reviews/SKILL.md`, `.claude/skills/plan-ahead/SKILL.md`
- Check: `git grep -n dl13860 -- .claude/skills` prints nothing; `python -m unittest tests.test_cx2_queue_steward` passes; `python tools/check_docs.py` passes
- Proof: `present: .claude/skills/run-queue/SKILL.md :: dl13860`
- Next after: FX-6 -- Codex skills derive `ROOT`; Codex run-queue probes `.git`
```

## FX-6 -- Codex skills derive `ROOT`; Codex run-queue probes `.git`

**Now.** `.agents/skills/run-queue/SKILL.md` hard-codes `ROOT` (the
`` `ROOT` is the primary checkout: `` line, and the `ROOT=` and `WORKTREE=`
lines of the worker prompt in step 3), as does
`.agents/skills/plan-ahead/SKILL.md`. A Codex session started under the
`:workspace` profile overrides `.codex/config.toml`'s
`default_permissions = "meadow"` and cannot write `.git`, which surfaces
only when `start` fails.

**Edit `.agents/skills/run-queue/SKILL.md`.**

1. The `ROOT` line: same replacement as FX-5 step 1.
2. In the step 3 worker prompt, replace
   `ROOT=C:\Users\dl13860\Documents\Meadow\meadow` with `ROOT=<ROOT>` and
   `WORKTREE=C:\Users\dl13860\Documents\Meadow\meadow\.worktrees\<id>` with
   `WORKTREE=<ROOT>\.worktrees\<id>`.
3. Directly after the paragraph that ends
   `` `powershell.exe -NoProfile -ExecutionPolicy Bypass -File tools/slice.ps1 <cmd> -Lane Codex`. ``,
   add a new paragraph:

   > **Before the first `doctor`, prove `.git` is writable.** From `ROOT`,
   > run `git update-ref refs/meadow/write-probe HEAD; git update-ref -d refs/meadow/write-probe`.
   > If either fails, claim nothing and tell Dave: "This session cannot
   > write `.git`: choose `meadow` in this session's Permissions dropdown,
   > then rerun `$run-queue`." A `:workspace` profile overrides
   > `.codex/config.toml`'s `default_permissions = "meadow"`.

**Edit `.agents/skills/plan-ahead/SKILL.md`:** same replacement as FX-5 step 2.

**Do not** touch `.claude/skills/` or `.codex/config.toml`.

**Acceptance.** `git grep -n dl13860 -- .agents/skills` prints nothing;
`git grep -n "refs/meadow/write-probe" -- .agents/skills/run-queue/SKILL.md`
prints one line; `python tools/check_docs.py` passes.

**Open decisions:** none.

```queue
**[Codex] FX-6 -- Codex skills derive `ROOT`; Codex run-queue probes `.git`**
- Plan: `plans/now/workflow-friction.md` -- "FX-6 -- Codex skills derive `ROOT`; Codex run-queue probes `.git`"
- Files: `.agents/skills/run-queue/SKILL.md`, `.agents/skills/plan-ahead/SKILL.md`
- Check: `git grep -n dl13860 -- .agents/skills` prints nothing; `git grep -n "refs/meadow/write-probe" -- .agents/skills/run-queue/SKILL.md` prints one line; `python tools/check_docs.py` passes
- Proof: `absent: .agents/skills/run-queue/SKILL.md :: refs/meadow/write-probe`
- Next after: none -- workflow-friction plan complete
```
