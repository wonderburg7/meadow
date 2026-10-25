# Workflow Friction Recommendations

Summary of recommendations addressing recent workflow issues and friction points for Claude Code and Codex sessions in Meadow.

## Summary Table

| Issue | Cluster | Recommendation | Effort | Priority |
| --- | --- | --- | --- | --- |
| Claude F1 / Codex F1 (Primary contention & late finish check) | Cluster A: Finish Execution Ordering & Primary Checkout Contention | Perform preflight index/branch/merge state checks early in `slice.ps1 finish` before primary verification; adapt `/run-queue` to retry boundedly on dirty primary checkout before asking Dave. | Medium | High |
| Claude F2 (Guard hook false refusals) | Cluster B: Guard Hook False Refusals & CWD Resolution | Update `tools/guard_hook.py` regexes to ignore path exclusions (`-v`, `--exclude`, `:!`) and evaluate worktree context using effective directory. | Extra Small | High |
| Claude F3 / Codex F3 (Verification scope & Windows test flakiness) | Cluster C: Verification Scope & Background Test Isolation | Update `plans/reference/jules.md` to instruct `-Scope branch`; scope `ensure_job_root()` to worktree-local TEMP; resolve process.log handle release in `tests/test_headless_jobs.py`. | Small | High |
| Claude F4 / Codex Python aliases (Environment & hardcoded paths) | Cluster D: Host Environment Inconsistencies & Hardcoded Paths | Make `godot_compile_check.py` fail explicitly when Godot is missing; derive `ROOT` dynamically in skill files using `git rev-parse --show-toplevel`; resolve Python binary path in Codex helpers. | Small | Medium |
| Claude F5 / Codex F4 (Shipped-slice blocked checks) | Cluster E: Shipped-Slice Blocked-Check Hand-off | Automatically invoke `tools/check_processor.py` (or dispatch check steward) in `tools/refill_lane.py` / `slice.ps1` when released checks are detected. | Extra Small | Medium |
| Codex F2 (Permission profile bypass) | Cluster F: Permission Profiles & Queue Metadata | Add startup preflight check in `run-queue` to verify `.git` write access and halt before claiming if running under read-only profile. | Extra Small | Medium |
| Claude F6 (Effort drift) | Cluster F: Permission Profiles & Queue Metadata | Align `slice-worker-low.md` header prompt with low reasoning level and fix dispatch parameters in `run-queue`. | Extra Small | Low |
| Claude F7 (Agent mistake calls) | N/A | Accept as normal operational noise (do nothing). | None | Low |

---

## Issue Cluster A: Finish Execution Ordering & Primary Checkout Contention (Claude F1, Codex F1)

### 1. Root Cause
- **Verified in repo:**
  - In `tools/slice.ps1` (lines 1420–1430, 1461–1485), `Invoke-SliceFinish` executes full primary verification (`Invoke-SliceFinishVerify` -> `tools/verify.ps1 -Scope primary`) *before* checking whether the primary checkout on `master` has staged or conflicting changes (`Assert-PrimaryIndexMatchesHead` or checking `primaryBranch`).
  - `Assert-PrimaryIndexMatchesHead` (lines 1391–1405) is only called *inside* `Invoke-SliceFinishVerify`, which runs *after* primary verification.
  - When the primary checkout is dirty or off `master` (e.g., from unmerged Jules wrap-ups or Codex stashes), 8–11 minutes of heavy primary verification execute first, only to fail at the merge step or index assertion.
  - `/run-queue` skill (`.claude/skills/run-queue/SKILL.md` / `.agents/skills/run-queue/SKILL.md`) immediately prompts Dave upon receiving a finish refusal instead of performing a bounded retry or clearing transient lock/stash states.

### 2. Options
- **Option 1: Do nothing / accept current behaviour.**
  - *Cost:* High token burn (~21.8M tokens across coordinators), prolonged idle wait times (up to 13.7 hours), repeated stops during queue runs.
  - *Unfixed:* Primary checkout lock contention, stashes interrupting concurrent sessions.
- **Option 2: Preflight primary checkout state before primary verification & update run-queue retry logic.**
  - *Cost:* Low (a few lines of preflight checks in `slice.ps1 finish`).
  - *Unfixed:* Does not eliminate manual intervention if Dave intentionally leaves uncommitted work on master.
- **Option 3: Isolate primary verification and merges into temporary throwaway worktrees.**
  - *Cost:* High complexity, risk of breaking git hook triggers, potential edge cases in nested worktrees.
  - *Unfixed:* Over-engineers git operations for a single-user local repository.

### 3. Recommendation
**Option 2.** Preflight the primary checkout's branch (`master`), clean status, and index state in `slice.ps1` as step 0 of `finish` before invoking any verification suites. Update `/run-queue` to attempt a bounded retry when the primary checkout is temporarily busy.

### 4. Slice Sketch
- **Files to edit:** `tools/slice.ps1`, `.claude/skills/run-queue/SKILL.md`, `.agents/skills/run-queue/SKILL.md`, `plans/reference/jules.md`.
- **Behaviour change:** Move `Assert-PrimaryIndexMatchesHead` and primary branch verification to the very start of `Invoke-SliceFinishVerify` (before `verify.ps1`). In `plans/reference/jules.md`, instruct Jules wrap-ups to execute inside dedicated throwaway worktrees rather than on the primary checkout.
- **Acceptance check:**
  ```powershell
  python -m unittest tests.test_slice_lifecycle tests.test_two_lane_closeout
  ```
- **Suggested reasoning level:** Medium.
- **Lane:** Claude lane. No collision with active product slices.

### 5. Risk
- Could fail early if legitimate temporary files exist in primary checkout; mitigated because `Assert-PrimaryIndexMatchesHead` checks staged changes (`diff --cached`), leaving untracked/unstaged edits unaffected.

---

## Issue Cluster B: Guard Hook False Refusals & Directory Resolution (Claude F2)

### 1. Root Cause
- **Verified in repo:**
  - `tools/guard_hook.py` (lines 28–39) implements `_reads_tree()`, checking if any word in `TREE_READERS` (`grep`, `rg`, `ls`, etc.) contains any path in `DENIED_READ_PATHS` (`.godot`, `_backups`, `docs/archive`, `plans/archive`).
  - The check is a naive string inclusion test (`any(path in arguments for path in DENIED_READ_PATHS)`). Exclusion filters such as `grep -v _backups`, `rg -g '!:plans/archive'`, or `':!plans/archive'` contain the substring and are incorrectly flagged as reading the denied path.
  - Line 46 checks `_is_worktree(cwd)` against `payload.get("cwd")`. When a tool call is executed from a worktree directory with a command like `cd ../.. && powershell ... finish`, `cwd` is still reported as the worktree, triggering a false "Run slice.ps1 finish from the primary checkout" refusal.

### 2. Options
- **Option 1: Do nothing / accept current behaviour.**
  - *Cost:* ~10 false refusals per day, frustrating agent search commands and closeout steps.
  - *Unfixed:* Denied commands force agents to construct awkward workarounds.
- **Option 2: Refine argument parsing in `tools/guard_hook.py` to recognise negative pathspecs/exclusion flags and resolve effective cwd.**
  - *Cost:* Extra small code change (~20 lines of Python), zero runtime overhead.
  - *Unfixed:* None.
- **Option 3: Remove `_reads_tree()` entirely and rely solely on `CLAUDE.md` / `AGENTS.md` instructions.**
  - *Cost:* Risk of agents re-reading massive archive/backup trees and blowing token context window (~500K tokens per session).
  - *Unfixed:* Loss of automated protection against accidental huge reads.

### 3. Recommendation
**Option 2.** Update `tools/guard_hook.py` to parse exclusion patterns (`-v`, `--exclude`, `-g !...`, `:!...`) and evaluate `cwd` based on command-level `cd` navigation.

### 4. Slice Sketch
- **Files to edit:** `tools/guard_hook.py`, `tests/test_guard_hook.py`.
- **Behaviour change:** Strip negative/exclusion arguments before evaluating `DENIED_READ_PATHS` in `_reads_tree()`. Calculate effective CWD if the command begins with `cd <dir> &&`.
- **Acceptance check:**
  ```bash
  python -m unittest tests.test_guard_hook
  ```
- **Suggested reasoning level:** Low.
- **Lane:** Claude lane.

### 5. Risk
- Regexes for exclusion flags might miss a unusual shell syntax, potentially allowing an actual read of `_backups/`. Mitigated by comprehensive unit tests in `tests/test_guard_hook.py`.

---

## Issue Cluster C: Verification Scope & Background Test Flakiness (Claude F3, Codex F3)

### 1. Root Cause
- **Verified in repo:**
  - `plans/reference/jules.md` section "How to work" step 6 directs Jules to run unit tests without specifying `-Scope branch`. Jules tasks default to running full-scope verification, taking 9–10 minutes for simple one-function changes.
  - In `tests/test_headless_jobs.py` (line 101), `test_submitted_job_returns_promptly_and_persists_normal_verdict` creates background jobs that write to `process.log`. Under Windows PowerShell 5.1 / background job execution, file handles on `process.log` remain open briefly during process teardown, causing intermittent `PermissionError: [WinError 32] Access denied` or `ResourceWarning` errors during temp directory cleanup.
  - In `tools/headless/jobs.py` (lines 50–65), `ensure_job_root()` defaults to system `%TEMP%` when unconfigured, which can cause permission collisions under restricted sandbox profiles.

### 2. Options
- **Option 1: Do nothing / accept current behaviour.**
  - *Cost:* 9–10 min unnecessary wait per Jules task; random test suite failures under parallel/Windows execution.
  - *Unfixed:* High closeout variance, flaky CI runs.
- **Option 2: Update `jules.md` to specify `-Scope branch`, configure worktree-scoped TEMP in `verify.ps1`, and add retry/release logic in `test_headless_jobs.py`.**
  - *Cost:* Small documentation and test adjustment.
  - *Unfixed:* None.

### 3. Recommendation
**Option 2.** Explicitly instruct `-Scope branch` in `jules.md`, scope headless job roots to worktree-local temporary folders in `tools/verify.ps1`, and ensure proper file handle release in `tests/test_headless_jobs.py`.

### 4. Slice Sketch
- **Files to edit:** `plans/reference/jules.md`, `tools/verify.ps1`, `tests/test_headless_jobs.py`.
- **Behaviour change:** `jules.md` explicitly calls `.\tools\verify.ps1 -Scope branch`. `verify.ps1` sets `$env:TEMP` / `$env:TMP` to a worktree-local directory. `test_headless_jobs.py` retries file handle closure before teardown.
- **Acceptance check:**
  ```bash
  python -m unittest tests.test_headless_jobs
  ```
- **Suggested reasoning level:** Small / Low.
- **Lane:** Claude or Codex lane.

### 5. Risk
- Worktree-local TEMP folders could accumulate if not cleaned up; mitigated by `tools/slice.ps1` worktree cleanup logic.

---

## Issue Cluster D: Host Environment Inconsistencies & Hardcoded Paths (Claude F4, Codex Python aliases)

### 1. Root Cause
- **Verified in repo:**
  - In `tools/godot_compile_check.py` (lines 35–48) / `tools/verify.ps1` (lines 530–540), if Godot is not installed or found on `PATH`, the boot check stage exits prematurely or returns success/skip rather than raising a hard failure.
  - Skill files (`.claude/skills/run-queue/SKILL.md:19`, `.claude/skills/plan-ahead/SKILL.md:20`, `.claude/skills/run-reviews/SKILL.md:20`, and `.agents/skills/*/SKILL.md`) hardcode `C:\Users\dl13860\Documents\Meadow\meadow`. When run on alternative user accounts or paths, scripts encounter path mismatches.
  - Codex helper commands on Windows sometimes invoke WindowsApps stub aliases for `python.exe` when PATH resolution fails.

### 2. Options
- **Option 1: Do nothing / accept current behaviour.**
  - *Cost:* Silent green verifications when Godot is missing; broken skill execution on non-standard user profiles.
  - *Unfixed:* Environment divergence between work PC and home PC.
- **Option 2: Explicitly fail `godot_compile_check.py` when executable is missing; replace hardcoded paths in skills with dynamic `git rev-parse --show-toplevel`.**
  - *Cost:* Small code/skill text changes.
  - *Unfixed:* None.

### 3. Recommendation
**Option 2.** Enforce strict failure when Godot binary is missing during verification, replace hardcoded user paths in skill files with dynamic top-level git directory resolution, and ensure helper commands use resolved Python paths.

### 4. Slice Sketch
- **Files to create/edit:** `tools/godot_compile_check.py`, `tools/verify.ps1`, `.claude/skills/*/SKILL.md`, `.agents/skills/*/SKILL.md`.
- **Behaviour change:** `godot_compile_check.py` exits with non-zero code if Godot executable cannot be resolved. Skill files compute `ROOT` via `git rev-parse --show-toplevel`.
- **Acceptance check:**
  ```bash
  python tests/source_checks.py
  ```
- **Suggested reasoning level:** Low.
- **Lane:** Claude lane.

### 5. Risk
- Machine environments without Godot installed will no longer pass `verify.ps1`. This is intended: Godot 4.7 is a required dependency for full verification.

---

## Issue Cluster E: Shipped-Slice Blocked-Check Hand-off (Claude F5, Codex F4)

### 1. Root Cause
- **Verified in repo:**
  - `checks/blocked.md` contains checks (e.g., C-109..118, C-84, C-130) that wait on slices that have already shipped (e.g. RR-1, SP-10).
  - `tools/check_docs.py` emits warnings (`checks/blocked.md: C-118 waits only for shipped slices...`), but no automated step in `slice.ps1 finish` or `tools/refill_lane.py` automatically unblocks or routes these checks to `checks/ready/`.
  - Sessions treat these warnings as pre-existing noise, leaving checks unreviewed until manual human intervention.

### 2. Options
- **Option 1: Do nothing / accept current behaviour.**
  - *Cost:* Persistent noisy warnings across every `check_docs.py` run; delayed hands-on checks.
  - *Unfixed:* Requires Dave to manually triage blocked checks.
- **Option 2: Auto-promote released checks in `tools/refill_lane.py` or dispatch the check processor during closeout.**
  - *Cost:* Minimal.
  - *Unfixed:* None.

### 3. Recommendation
**Option 2.** Incorporate an automatic check release step into `tools/refill_lane.py` or `tools/slice.ps1` post-merge cleanup so that when a slice ships, any check in `checks/blocked.md` waiting *only* on that slice is automatically moved to `checks/ready/`.

### 4. Slice Sketch
- **Files to edit:** `tools/refill_lane.py`, `tools/check_docs.py`, `plans/reference/queue-steward.md`.
- **Behaviour change:** When `refill_lane.py` or `slice.ps1` processes a landed slice, inspect `checks/blocked.md` and move any newly unblocked checks to `checks/ready/`.
- **Acceptance check:**
  ```bash
  python tools/check_docs.py
  ```
- **Suggested reasoning level:** Low / Medium.
- **Lane:** Claude lane.

### 5. Risk
- Automatically promoting checks might surface a hands-on check before its dependent features are fully ready if dependency tags in `checks/blocked.md` were incomplete.

---

## Issue Cluster F: Permission Profile & Effort Drift (Codex F2, Claude F6, Claude F7)

### 1. Root Cause
- **Verified in repo:**
  - Codex sessions started with `:workspace` profile override `.codex/config.toml` (`default_permissions = "meadow"`), causing read-only `.git` access errors.
  - `.claude/agents/slice-worker-low.md` states `effort: medium` in its system prompt text, conflicting with low-effort worker expectations for Haiku.
  - Claude F7 mistakes (heredoc quotes, wrong function arguments) occur at ~1 per task and represent standard LLM operational variance.

### 2. Options
- **Option 1: Do nothing.**
  - *Cost:* Continued minor effort drift and rare permission profile mistakes.
- **Option 2: Add preflight permission check in `run-queue` startup and fix prompt text in `slice-worker-low.md`.**
  - *Cost:* Extra small documentation and prompt fix.

### 3. Recommendation
**Option 2.** Update `slice-worker-low.md` prompt text to reflect low effort. Add a preflight git-write test in `run-queue` skill startup to verify writable `.git` access before claiming a slice. Accept F7 agent mistakes as standard noise.

### 4. Slice Sketch
- **Files to edit:** `.claude/agents/slice-worker-low.md`, `.claude/skills/run-queue/SKILL.md`, `.agents/skills/run-queue/SKILL.md`.
- **Behaviour change:** Fix system prompt reasoning level in `slice-worker-low.md`. Add `git update-ref` write probe to `run-queue` preflight.
- **Acceptance check:** Manual verification of prompt text and skill script inspection.
- **Suggested reasoning level:** Low.
- **Lane:** Claude lane.

### 5. Risk
- Minimal risk.

---

## Needs Dave's Decision

1. **Unmerged Local Worktrees / Fix Branches:**
   - Two worktrees hold unmerged fixes (`claude/amazing-leavitt-7606db` for fixture pins and `claude/finish-staged-index-guard` for index checks).
   - *Decision:* Dave should open a session on each branch to merge master, verify, and complete closeout to master.

2. **Work PC Diagnostic Data Collection (16–23 Oct):**
   - Transcripts on the current machine cover only 24–25 Oct.
   - *Decision:* Optional run on work PC: `python tools/session_cost.py --days 10 --classify` and `--phases` to complete historical data set.

3. **Codex Workspace Permissions Selector:**
   - If a future Codex session starts under `:workspace` instead of `meadow`, Dave must manually select `meadow` in the session's Permissions dropdown.

---

## Could Not Verify

1. **Windows-Specific Process Log Locking:**
   - Behavior where `process.log` in `tests/test_headless_jobs.py` fails file removal due to Windows background file handle retention could not be reproduced directly in the Linux sandbox environment.
2. **Godot Headless Boot Performance on Windows:**
   - Headless Godot boot timing (8–12 seconds on Windows vs Linux execution) relies on transcript log evidence.
