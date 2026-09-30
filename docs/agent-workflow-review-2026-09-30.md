# Agent workflow review -- 30 Sep 2026

<!-- CONTEXT: review-record | LOAD: on-demand -->
Reviewed: 241f2ee | Since: 53e549c (the 12 Sep record) | Scope: lifecycle tooling, permission friction, session cost, reasoning-level fit, the signals intake; Claude-only, no Codex block | Previous: docs/agent-workflow-review-2026-09-12.md

**Measurement caveat.** This ran in a cloud session. The transcripts,
`meadow-slice-stops.jsonl` and `meadow-diagnostics.jsonl` live on Dave's
machine, so `session_cost.py`'s five modes could not run (`--days` prints
"session directory not found"; `--stops` and `--events` see only this
session). Every figure below is derived from Git history, 12 to 30 Sep,
after deepening the shallow clone. The completion gate in
`plans/now/agent-lifecycle.md` stays unmeasured until Dave runs the commands
under "Dave's actions".

## Follow-through

| Previous finding | Disposition |
| --- | --- |
| F1 -- closeout one long non-resumable transaction | Shipped -- L-4, L-5 (`plans/archive/L-5_2026-09-14.md`); `$script:ClosingPhaseOrder` and `Invoke-SlicePostMergeCleanup` in `tools/slice.ps1`; one push per closeout confirmed in the code |
| F2 -- lifecycle suite unverified and red | Shipped -- L-1; `verify.ps1::$lifecycleModules` (10 modules), 101 tests OK here under PowerShell 7 |
| F3 -- one lane's mess fails the other's branch | Shipped -- L-3; `verify.ps1 -Scope branch` and `-Scope primary`, both called from `Invoke-SliceFinish` |
| F4 -- lanes serialise on master commits | Shipped -- L-6 `TwoLaneCloseoutTest`; `start` still commits the ledger row on master by design, and L-16 now pushes it |
| F5 -- Codex could not run resume | Shipped -- WF-1, 12 Sep; `tests/test_codex_environment.py` |
| F6 -- invocation shape wrapped and denied | Shipped -- WF-1 pinned the Codex shape; the Claude half stayed a habit and is not measurable here (see F5 below) |
| F7 -- opening floor regressed, unmeasured | Shipped -- L-9 split host from repository context in `session_cost.py`; the target itself was last read 17 Sep (F7 below) |
| F8 -- refill interrupts Dave | Shipped -- L-12, L-13: `finish` runs `archive_slice.py` and `refill_lane.py` itself; 56 lifecycle closeouts since 12 Sep produced no hand refill commit after 21 Sep |
| F9 -- queue prose contradicts the queue | Shipped -- L-7 `check_docs.py::check_queue_section_agreement` |
| F10 -- Godot failures unclassified | Shipped -- L-8 `Get-GodotCapability`; the verification review of 30 Sep took the scenario-runner side |
| F11 -- a quarter of sessions do no product work | Rejected as a mechanism, 12 Sep (a habit); re-measured here as F3 below: half of all merges now come from branches outside the lifecycle |
| F12 -- expected results counted as failures | Shipped -- L-2 `OUTCOME_CLASSES` in `session_cost.py`; its baseline never reconciled with Part 1 within 10% (`plans/archive/L-2_2026-09-12.md`), left there |
| F13 -- lifecycle costs three times implementation | Queued -- the completion gate of `plans/now/agent-lifecycle.md`; last figure 17 Sep (23% over 21 days), not re-measured since L-12/L-13 shipped; Dave's action 1 |

## Findings

Grouped by root cause. Claude-only, so the Codex-evidence column is what Git shows for `codex/` branches.

| Id | Finding | Evidence | Severity | Disposition |
| --- | --- | --- | --- | --- |
| F1 | **Repository workflow defect.** `finish` pushes only after merging, removing the worktree and deleting the ledger row, and neither `start` nor `finish` fetches first; when origin is ahead the push is rejected and the session pulls by hand and resumes. Since 30 Sep five cloud review sessions push master directly, so this is now routine. Codex: `codex/SF-2` needed `Merge branch 'master' into codex/SF-2` (`e23fa4a`) before its finish | `git log --merges --first-parent --since=2026-09-12`: 7 pull-type merges on master, latest `c0f751d` right after HF-1's closeout; `slice.ps1::Get-DefaultSliceFix` ("run git pull --no-rebase"); `Invoke-SliceStart` has no fetch or push; `tests/test_two_lane_closeout.py::test_remote_ahead_integrates_or_fails_naming_remote_state` accepts failure. Earlier fix: L-5's single push solved the double-push, moved the failure to the end of the transaction | high | Queued -- L-16 in `plans/now/agent-lifecycle.md` (Proof run: `Sync-PrimaryMaster` absent) |
| F2 | **Repository workflow defect.** Windows PowerShell 5.1's cp1252 console mangles em dashes in coordination files; fixed seven times at seven call sites, never once with a test | `git log --since=2026-09-12 -- tools/slice.ps1 tools/archive_slice.py`: `0da665e`, `7a48997`, `aedb0d0`, `9153793`, two on 18 Sep in the Python tools, plus three hand ledger repairs on 18 Sep; `tools/slice.ps1` lines 27-28 versus the per-call block at its `git show master:NEXTSTEPS.md`. Earlier fixes: each solved one call site | medium | Queued -- L-17 in `plans/now/agent-lifecycle.md` (Proof run: `ConsoleEncodingTest` absent) |
| F3 | **Claude-only / controlled by Dave.** Half of all merges come from branches the lifecycle never saw, and their closeouts are typed by hand on master | 117 first-parent merges since 12 Sep: 56 lifecycle (`claude/<ID>` or `codex/<ID>`), 30 cloud-style `claude/<slug>-<hash>`, 16 id-like branches never claimed (`claude/C1F-1..4`, `G3`, `E1`, `F1s`, `F2s`, `UI-X-1`, `UI-X-4`, `codex/G2`), 10 other, 5 `ccr-*`; 23 hand closeout or queue-repair commits on master (`git log --first-parent --no-merges`, e.g. `388daf5`, `dcf8d44`); HR-3 delivered on `claude/hr3-bee-waiting-message-eab8ba` and archived by hand in three commits | medium | Rejected as a slice for now -- no transcript here can say whether those sessions were reviews, hands-on batches or slices started without `start`; Dave's action 1 pastes `--no-edit-reasons` and `--events` so the next run can decide between a `land` command for ad-hoc branches and a rule; recorded in the plan's "Current state" |
| F4 | **Local machine or external service.** The cloud environment has no PowerShell 7 or Godot; every cloud review installs both into scratch (this one: 2 downloads, 90 s) before it can run `verify.ps1` or `slice.ps1 owner`, and the review contract's `owner` step is otherwise unrunnable there | `docs/gameplay-review-2026-09-30.md` and `docs/verification-review-2026-09-30.md` headers; this session: `which pwsh godot` empty; `verify.ps1` green here once installed (72 unit, 101 lifecycle with 3 skips, boot OK) | medium | Decided -- Dave's action 2 (environment setup script); no repository change |
| F5 | **Claude-only, permission friction.** The allow-list lacked four read-only commands the queue's own `Check:` lines and the review contract instruct sessions to run, so each prompts | `.claude/settings.json` before this pass; `NEXTSTEPS.md` Check lines name `python tools/run_scenario.py`; `plans/reference/review-contract.md` rule 2 names `git ls-files`; this session was denied `ls plans/archive/` under the deny rule and used `git ls-files` instead. Denial counts are not measurable here | low | Fixed -- `Bash(git ls-files*)`, `Bash(python tools/run_scenario.py*)`, `Bash(python tools/backlog.py*)`, `Bash(python tests/source_checks.py*)` added; JSON parses; takes effect at the next session start (Dave's action 3) |
| F6 | **Repository workflow defect** (from the intake, SK-1). `tests/source_checks.py::collect_names` matched `signal` only at column 0 and `KNOWN` lacked `draw_polyline` and `accept_event`, so an inner class's own signal and two engine calls failed the branch verify at `finish` and the code was bent to pass | the SK-1 stop block, 30 Sep; `scripts/skill_tree_panel.gd::SkillGrid` now uses `draw_line` and `set_input_as_handled` instead | low | Fixed -- `^\s*signal`, two names added, `tests/test_source_checks.py::InnerClassCallChecksTest`; 94 scripts still pass |
| F7 | **Repository workflow defect** (from the intake, HF-6). `tools/func.py` raised `UnicodeEncodeError` on a cp1252 console for any function carrying an em dash, pushing sessions back to whole-file reads | `PYTHONIOENCODING=cp1252 python3 tools/func.py scripts/hud.gd hatch_options` exit 1 before, 0 after; `tools/heading.py` already had the fix | low | Fixed -- the same `reconfigure(encoding="utf-8", errors="replace")` as `heading.py` |
| F8 | **Controlled by Dave.** The agent-lifecycle completion gate (zero `lifecycle_failure` in seven days, one canary per lane, implementing share above 40%) has not been read since 17 Sep, and a cloud review cannot read it | `plans/now/agent-lifecycle.md` Status line; `session_cost.py::main` reads `~/.claude/projects/C--Users-dl13860-...` only | medium | Decided -- Dave's action 1; the plan's Status line now says so |
| F9 | Reasoning levels: every queued slice states `Level: medium` and `Get-SliceAdvice` maps it to the routine model; whether sessions honoured it is the `level drift` line of `--events`, unreadable here | `grep -n "Level:" plans/now/*.md`; `tools/slice.ps1::Get-SliceAdvice` | low | Rejected -- nothing to act on without the drift readout; covered by Dave's action 1 |

## Hand-offs

- **Verification review.** `tests/source_checks.py` gained an inner-class rule (F6); the checker's coverage of inner classes generally (members, consts) was not examined.
- **Context review.** `plans/reference/closeout.md` still tells a session facing a rejected push to `git pull --no-rebase` by hand; L-16 makes that text stale when it ships.

## Dave's actions

1. **Paste the local measurement into the next agent-workflow review.** In Windows PowerShell 5.1, from `cd C:\Users\dl13860\Documents\Meadow\meadow`, on or after 6 Oct 2026, run `python tools/session_cost.py --days 7; python tools/session_cost.py --days 7 --classify; python tools/session_cost.py --days 7 --phases; python tools/session_cost.py --days 7 --no-edit-reasons; python tools/session_cost.py --stops; python tools/session_cost.py --days 7 --events` and paste the whole output into the review prompt under a `CLAUDE MEASURES` fence, next to the `CODEX FINDINGS` one (Notion, "Meadow review prompt library", agent-workflow-review). Without it the gate in `plans/now/agent-lifecycle.md` cannot be read.
2. **Give cloud sessions PowerShell 7 and Godot.** In the Claude Code web app, open this environment's settings (the cloud environment menu in the session's title bar, then Edit), and under **Setup script** paste:
   `mkdir -p /opt/tools && cd /opt/tools && curl -sSL -o pwsh.tar.gz https://github.com/PowerShell/PowerShell/releases/download/v7.5.2/powershell-7.5.2-linux-x64.tar.gz && mkdir -p pwsh && tar -xzf pwsh.tar.gz -C pwsh && chmod +x pwsh/pwsh && ln -sf /opt/tools/pwsh/pwsh /usr/local/bin/pwsh && curl -sSL -o godot.zip https://github.com/godotengine/godot/releases/download/4.7-stable/Godot_v4.7-stable_linux.x86_64.zip && python3 -c "import zipfile; zipfile.ZipFile('godot.zip').extractall('godot')" && chmod +x godot/Godot_v4.7-stable_linux.x86_64 && ln -sf /opt/tools/godot/Godot_v4.7-stable_linux.x86_64 /usr/local/bin/godot`
   and under environment variables add `MEADOW_GODOT_PATH=/usr/local/bin/godot`. Both URLs returned 200 through this session's proxy. New sessions then run `verify.ps1` and `slice.ps1 owner` without installing anything.
3. **Restart open Claude Code sessions** after this merge so `.claude/settings.json`'s four new allow entries load; a running session keeps the old list.
4. **Before the next local `finish`, run** `git pull --no-rebase` in Windows PowerShell 5.1 from `cd C:\Users\dl13860\Documents\Meadow\meadow`: six cloud merges landed on origin today, and until L-16 ships the push at the end of `finish` will otherwise be rejected once.

## Noted, not pursued

- `plans/now/agent-lifecycle.md` is 297 lines against the 260 soft limit; it holds only open work, and L-16 and L-17 will shrink it as they archive.
- Four ledger rows from before L-5 (`UI-X-2`, `C4`, `C3`, `L-3`) were claimed and never removed by `finish`; all were cleared by hand at the time and no row is stale today.
- `session_cost.py` hard-codes Dave's project directory; a cloud session could only ever read a pasted snapshot, so a portable path buys nothing.

## Not reviewed

- Codex sessions (no Codex block this run); Windows file locks; the three-minute worktree deletion retry (L-4 moved it out of the lock and no pending-deletion residue is visible in Git).
- Session cost, denial counts, stop causes and level drift: all need Dave's machine (action 1).

## Patterns deliberately not applied

- No Python port of `slice.ps1 owner` for cloud sessions: action 2 makes the existing command runnable there, and two implementations of the ownership rule is the worse outcome.
- No `.gitattributes` merge driver and no rebase anywhere in L-16: history is never rewritten by the lifecycle.
