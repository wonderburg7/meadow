# Codex execution reliability — make slice runs startable and recoverable

<!-- CONTEXT: plan | LAYER: immediate-task -->

Status: active | Owner: Dave / Codex | Next: CR-2 -- make the standard runtime self-discovering | Dependency: CR-1 implemented; permission-profile changes may require the machine administrator | Verified: 2026-09-08

**Objective.** A fresh `Implement the next slice` task either completes the
assigned slice, or stops once with a precise external blocker. It must not
spend a second task rediscovering Python, retrying a half-created worktree, or
recovering an earlier task's partial closeout.

## Evidence from recent tasks

This diagnosis sampled the 15 most recent Meadow implementation tasks visible
in Codex on 8 September 2026 and compared them with the 27 August–3 September
workflow audit. Categories overlap because one failed lifecycle often caused
several follow-on errors.

| Symptom | Recent tasks affected | Interpretation |
| --- | ---: | --- |
| Python missing or inaccessible | 12 / 15 | `verify.ps1` searches `PATH`, but Codex's bundled Python is available outside `PATH` |
| Lane already has an open worktree | 10 / 15 | Usually a consequence of an earlier partial or blocked run, not the original cause |
| Git metadata write denied | 8 / 15 | The slice lifecycle writes `.git`, while the effective Codex profile exposes it read-only |
| Wrong path or lifecycle command guessed during recovery | 7 / 15 | Recovery is undocumented and not encoded as an idempotent command |
| Dirty-primary merge or `checks/ready.md` conflict | 5 / 15 | Both lanes mutate a shared file that their `Files:` declarations omit |
| Git `safe.directory` mismatch | 4 / 15 | The Windows sandbox user differs from the repository owner |
| Worktree directory held open | 2 / 15 | Godot, indexing, or sync can outlive the command that used the worktree |
| Malformed queue proof | 2 / 15 | The two newest runs both stopped before claim on SB-1 |

Only two of the 15 sampled tasks landed a slice in that task. This is not a
slice-quality rate: several tasks were retries of the same open lane, one
correctly found no work, and balance work correctly refused to land without
its mandatory headless evidence. It is the user-visible reliability rate of
starting a fresh Codex task and receiving a completed landing.

The earlier audit found the same foundations at larger scale: 48 sandboxed
Git-write failures across 39 sessions, 20 `safe.directory` mismatches, repeated
runtime discovery, and stale queue/branch state. `tools/slice.ps1` and quiet
verification were the right response, but the lifecycle is only partly
encoded and is not yet failure-atomic.

## Diagnosed causes

### 1. The execution profile and the workflow disagree

The project requires `slice.ps1 start` and `finish` to create branches,
worktrees, commits, merges and pushes. Those operations write shared Git
metadata. The current effective permission profile permits repository content
writes but exposes `.git` read-only, so the normal first attempt predictably
fails on `index.lock` or refs. The elevated Windows sandbox itself is enabled;
the issue is the narrower effective filesystem policy, not absence of a
sandbox.

Agents then improvise environment variables, aliases and one-off elevated
commands. That produces the `safe.directory`, command-shape and approval churn
seen in the sample.

### 2. Claim and closeout are multi-step, but not transactional or resumable

`start` appends and commits the ledger row before creating the worktree.
`finish` verifies, commits, merges, pushes, removes the worktree and branch,
then removes the ledger row in another commit and push. A failure between any
two steps leaves a real intermediate state. The only available commands are
`start` and `finish`; there is no `status`, `resume`, `repair` or `abort`.

The lane lock is therefore doing its safety job, but subsequent tasks can only
report the lock or manually reverse-engineer the interrupted phase. The live
review also observed a normal closeout temporarily showing a merged branch,
dirty primary coordination files, an empty ledger and a still-registered
worktree. That state settled, but another task starting in that window would
reasonably diagnose drift.

### 3. Queue validation has a concrete schema hole

SB-1 currently says `Proof: see the named plan heading`. `slice.ps1` requires
a backticked `present|absent: path :: substring` value and rejects it. However,
`tools/check_docs.py` reports success: its required-field check sees the text
`- Proof:`, while `check_queue_proofs` silently skips a proof that does not
match the backticked regex under the mistaken assumption that the first check
already reported it.

`Files: see the named plan heading` has the same design smell. SB-1 actually
owns `game_config.gd`, `flower.gd`, and `settings_catalogue.gd`, but the
cross-lane overlap check cannot discover those files from the queue entry.

### 4. Runtime and acceptance checks do not fail fast

Codex exposes a bundled Python executable, but `verify.ps1` only searches
`python`, `python3`, and `py` on `PATH`; `slice.ps1 finish` also provides no
way to pass `-PythonPath`. This caused repeated discovery in almost every
recent task.

FL-2 additionally showed that the mandatory Godot comparison can detach,
crash with `0xC0000005`, or exit without a summary. Multiple tasks waited for
or retried the same unavailable evidence. SB-1 is currently first in the
Codex lane and also requires a full-year baseline/branch comparison, so fixing
only its proof would expose the next known blocker immediately.

### 5. Supposedly independent lanes still share mutable integration files

The queue checks declared implementation files, but omitted always-shared
artifacts such as `checks/ready.md` and sometimes generated documentation.
Several branches therefore passed the ownership check and later conflicted in
`checks/ready.md`. The conflict is structural, not bad luck: parallel slices
are both expected to append to that file.

## Remediation slices

### CR-1 — make the queue reject unclaimable work

Completed 2026-09-08; archived at `plans/archive/CR-1_2026-09-08.md`.

### CR-2 — make the standard runtime self-discovering

Small Windows tooling slice.

1. Extend `verify.ps1::Resolve-Python` to locate the bundled interpreter from
   the running Codex PowerShell dependency tree when ordinary `PATH` lookup
   fails. Keep `-PythonPath` as the explicit override.
2. Thread `-PythonPath` through `slice.ps1 finish` for non-Codex callers and
   tests, even though normal Codex use should need no argument.
3. Add a `doctor` check for Python, Godot, Git identity, repository ownership,
   remote reachability when a push will be required, and Git-metadata write
   capability. Report all failures together.
4. Add a project local-environment setup/action for the canonical verification
   command so a worktree starts with the same toolchain every time.

Acceptance: verification and closeout succeed in a clean Codex task with no
PATH edits, aliases, runtime search, or generated bytecode left in the tree.

### CR-3 — align permissions with the intended Git lifecycle

Machine configuration, kept least-privilege.

1. Keep the elevated Windows sandbox. Create a named Meadow permission profile
   extending the workspace profile, with write access only to this repository,
   its exact shared Git metadata and the chosen worktree root.
2. Permit network access only to the configured Git remote endpoints needed by
   `git fetch/push`; do not use full-access mode.
3. Add a narrow rule/approval for the canonical `tools/slice.ps1 start` and
   `tools/slice.ps1 finish` invocations. If managed policy prevents `.git`
   writes, make one upfront approval the documented prerequisite instead of
   discovering the denial midway through every task.
4. Configure Git safe-directory handling for the primary checkout and the
   worktree parent once at environment setup, not ad hoc per command.

Acceptance: `doctor` can create and remove a disposable lock/ref probe, and a
mock slice can claim, commit and close without an approval turn after setup.

### CR-4 — make the lifecycle failure-atomic and idempotent

Medium tooling slice; complete before adding more lifecycle prose.

1. Add explicit states and commands: `status`, `resume`, and `abort` (the last
   only before merge). Derive state from branch, worktree, ledger, master and
   remote truth rather than trusting one file.
2. Run every preflight before changing the ledger. On a failed `start`, roll
   back only artifacts created by that invocation.
3. Make `finish` resume safely after verification, branch commit, merge, push,
   worktree removal, branch deletion, ledger deletion, or queue closeout.
4. Use a repository lifecycle lock so two agents cannot mutate master-side
   coordination at the same time. A busy lock should produce one clear
   retryable result rather than apparent corruption.
5. Move worktrees to a non-synced, non-indexed project-specific directory, or
   use Codex-managed worktrees, to reduce Windows file-handle races.

Acceptance: inject a failure after every lifecycle phase, rerun `resume`, and
finish with one merge, one clean ledger, no orphan worktree/branch and no
manual Git repair.

### CR-5 — remove cross-lane shared-file conflicts

Medium coordination change.

1. Stop editing `checks/ready.md` independently on both feature branches.
   Prefer one file per check under an append-only `checks/ready/` directory,
   with the existing page generated or indexed on master. An integration-only
   append is the fallback if migration cost is too high.
2. Treat generated/shared documentation as an integration product, or declare
   it automatically in both lanes' ownership calculation.
3. Make `doctor` expand implicit lifecycle files when checking lane overlap;
   do not trust only the human-written `Files:` line.

Acceptance: two mock lane branches can each file a check and close in either
order with no merge conflict.

### CR-6 — make headless evidence bounded and causal

Medium test-runner slice, required before SB-1 returns to the queue.

1. Add a short baseline smoke mode that proves Godot starts, produces a
   session file and exits synchronously before a balance slice is claimable.
2. Give every run a unique output directory, capture stdout/stderr and the
   child PID, enforce one timeout, kill the process tree on timeout, and return
   a typed result: pass, product failure, environment failure, or timeout.
3. Run baseline and branch serially through the same wrapper. Never infer that
   a detached process is healthy merely because it still consumes CPU.
4. Keep a small deterministic scenario for infrastructure qualification; run
   the expensive full-year comparison only after that gate passes.

Acceptance: the runner always returns a summary or one classified failure
within its stated bound, leaves no Godot process behind, and the current
master baseline completes before SB-1 is advertised as ready.

## Order and success measure

Do CR-1 and CR-2 first; they remove the two blockers guaranteed to affect the
next Codex slice. Apply CR-3 in parallel with machine administration. Then do
CR-4, CR-5 and CR-6 before resuming balance-sensitive queue work.

Afterwards, run ten representative throwaway lifecycle exercises, including
parallel lanes and injected failures. Success is:

- 10/10 tasks either land or return one correctly classified external blocker;
- zero Python or `safe.directory` discovery attempts;
- zero raw Git-metadata permission failures after setup;
- zero stale ledger rows, orphan worktrees or duplicate branches;
- zero `checks/ready` merge conflicts; and
- no second Codex task needed merely to recover the first task's lifecycle.
