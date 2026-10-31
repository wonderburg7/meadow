# Workflow friction -- six small fixes from the 25 Oct 2026 friction review

<!-- CONTEXT: plan | LAYER: immediate-task -->

Status: complete | Owner: Dave / Codex (moved to the Codex lane by Dave, 30 Oct 2026) | Next: none -- workflow-friction plan complete | Dependency: none | Verified: 2026-10-31

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
| FX-6 | Codex skills derive `ROOT`; Codex run-queue probes `.git` | `.agents/skills/run-queue/SKILL.md`, `.agents/skills/plan-ahead/SKILL.md` | yes | low |

No slice depends on another. They are chained by `Next after:` in id order
only so the lane refills itself. **Do not change** any behaviour this plan
does not name: each slice's "Do not" line says what a past fix relied on.

**Read for any slice here:** its own section below and nothing else.

FX-1 shipped 2026-10-30; its specification is `plans/archive/FX-1_2026-10-30.md`.

FX-2 shipped 2026-10-30; its specification is `plans/archive/FX-2_2026-10-30.md`.

FX-3 shipped 2026-10-30; its specification is `plans/archive/FX-3_2026-10-30.md`.

FX-4 shipped 2026-10-30; its specification is `plans/archive/FX-4_2026-10-30.md`.

FX-5 shipped 2026-10-30; its specification is `plans/archive/FX-5_2026-10-30.md`.

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
