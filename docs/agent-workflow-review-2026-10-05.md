# Agent workflow review -- 5 Oct 2026

<!-- CONTEXT: review-record | LOAD: on-demand -->
Reviewed: c4e7a7d | Since: 241f2ee (the 30 Sep record) | Scope: Claude-lane sessions and everything both lanes share (NEXTSTEPS.md lanes, checks/, plans/workstreams.md, the signals intake, the slice.ps1 lifecycle), 28 Sep to 5 Oct | Previous: docs/agent-workflow-review-2026-09-30.md

**Measurement.** This ran locally, so the stop ledger and event log were readable.
`session_cost.py --days/--classify/--phases` printed zeros (F1), so cost figures
come from the same transcripts read across every worktree directory, usage
fields only: 69 sessions and 43 subagent workers, 1,412M context tokens over 7
days. The modes are exclusive: combining the flags prints only `--stops`.

## Follow-through

| Previous finding | Disposition |
| --- | --- |
| F1 -- push rejected when origin is ahead | Shipped -- L-16, merged 2 Oct; `slice.ps1::Sync-PrimaryMaster` present. Two Codex pushes still failed on 2 Oct (SR-2, SR-3), none in any lane since (hand-off) |
| F2 -- cp1252 em dashes mangled | Shipped -- L-17, merged 2 Oct; `tests/test_slice_lifecycle.py::ConsoleEncodingTest` present |
| F3 -- half of all merges bypass the lifecycle | Rejected -- re-measured: 54 of 81 first-parent merges are lifecycle (was 56 of 117); the other 27 are reviews, check passes and run-queue follow-ups by branch name, which are not slices |
| F4 -- cloud sessions lack PowerShell 7 and Godot | Decided -- Dave's action 2 of the 30 Sep record; no repository change; not checkable from a local session |
| F5 -- four read-only commands prompt | Shipped -- all four in `.claude/settings.json` |
| F6 -- source_checks misses inner-class signals | Shipped -- `tests/test_source_checks.py::InnerClassCallChecksTest` |
| F7 -- func.py crashes on cp1252 | Shipped -- `tools/func.py` reconfigures stdout to UTF-8 |
| F8 -- completion gate unread since 17 Sep | Queued -- still unreadable, now for a local reason: F1 below, L-20 |
| F9 -- level drift unreadable | Queued -- readable now but wrong: F1 below, L-20 |
| Hand-off -- closeout.md's hand `git pull` text | Shipped -- the text is gone from `plans/reference/closeout.md` |

## Findings

| Id | Finding | Evidence | Severity | Disposition |
| --- | --- | --- | --- | --- |
| F1 | **The workflow cannot measure itself.** `--days`, `--classify`, `--phases` read the primary transcript directory only, which holds 1 of 70 sessions since 28 Sep (desktop sessions write to `...--claude-worktrees-<name>`). `--events` level drift ignores `subagents/` transcripts, so it reports Opus for every slice: all 36 claims since 28 Sep were /run-queue-coordinated, and the workers ran Sonnet for low/medium and Opus for high, as specified. `verify failures lifecycle tests=82` is skips: 36 skipped, 0 failed since 28 Sep | `session_cost.py::main` (primary `project_dir`), `::_session_totals` (`*.jsonl` glob), `::run_events` (`not e.get("ok")`); `python tools/session_cost.py --days 7` prints `sessions 0` | high | Queued -- L-20 in `plans/now/agent-lifecycle.md` (Proof run: `def _transcript_files` absent) |
| F2 | **Check passes are the biggest single cost.** 9 hands-on/check sessions were 486M of 1,412M context (34%). One pass ran 630 requests and took 256 screenshots, and its context grew from 64K to 486K per request, because every screenshot stays in context | transcript usage fields, worktrees `meadow-hands-on-checks-157c79`, `meadow-checks-verify-32404f` | high | Queued -- L-22 in `plans/now/agent-lifecycle.md`, Dave's choice of 5 Oct (a check-runner subagent; options were a 6-check cap or no change) |
| F3 | **Planning happens inside `finish`.** 15 of about 40 Claude slices since 30 Sep wrote their successor's specification mid-closeout (e.g. `a64364f`, `b38828d`, `a9346af`): `refill_lane.py` refused 13 times, the refill gate stopped twice, and 8 more queue edits were made by hand on master. Plans keep one slice specified ahead, and L-18 only warns | stop ledger since 30 Sep; `git log 241f2ee..HEAD` subjects `<id> -- specify/queue ...`; the 1 Oct signal "a lone Codex item blocks its own finish" (second occurrence) | medium | Gated -- L-23 in `plans/now/agent-lifecycle.md`, waits for L-18; Dave's choice of 5 Oct (a lookahead warning plus specify-before-claim; options were L-18 alone or an on-demand planning pass) |
| F4 | **Verify stops cannot be told apart.** 17 of the 67 stops since 30 Sep were verify failures (9 branch, 8 primary). Their cause names no stage, and `meadow-slice-verify.log` is overwritten each time, so "the same reason twice" cannot be answered. No primary-scope stage event failed in the same window, so the 8 primary stops failed somewhere that logs nothing (inference) | `slice.ps1::Invoke-SliceFinish` verify `Stop-Slice` causes; `Save-VerifyLog`; event log `verify_stage` by scope | medium | Queued -- L-21 in `plans/now/agent-lifecycle.md` (Proof run: `function Get-VerifyFailureSummary` absent) |
| F5 | **The /run-queue coordinator costs three times its workers.** 9 coordinator sessions used 259M context against 87M for their 43 workers: 41 coordinator requests per slice, 69 `finish` calls for 43 dispatches, and 20 direct `verify.ps1` runs that `finish` repeats anyway. Code review stays in the coordinator by design (24 runs, levels as specified). Re-reading code was negligible (2 Reads of tools/tests) | transcript tool counts, `run-queue-*` worktrees | medium | Fixed -- `.claude/skills/run-queue/SKILL.md` step 6 now forbids running `verify.ps1` directly; the extra `finish` calls are F3's and F4's stops |
| F6 | **Stale desktop worktrees.** 46 fully merged `.claude/worktrees/*` sat idle, and `claude/adoring-grothendieck-f9a90f` holds an unmerged test-isolation commit (`255860c`, 1 Oct). The ledger itself matches: `.worktrees/GC-3` is its only row and only live slice worktree | `git worktree list`; `git rev-list --count master..<branch>` | low | Fixed -- with Dave's yes, 40 idle merged worktrees deregistered, branches kept (17 left empty folders behind a Windows lock: Dave's action 1); 6 kept (5 active in the last day, 1 unmerged); the orphan commit is handed off |
| F7 | **Memory workarounds the tooling has retired.** `project_slice_owner_merge_base_warning` (fixed 1 Oct, `Read-GitText` since L-17) and `project_meadow_boot_regression_2026-09` (its Codex-lane and dangling-link claims are no longer true) | `grep -c Read-GitText tools/slice.ps1` = 6; `git show HEAD:ROADMAP.md \| grep -c plans/now/flowers.md` = 0 | low | Fixed -- both memories and their MEMORY.md lines deleted |
| F8 | The 1 Oct signal "a lone Codex item blocks its own finish" was untriaged | `plans/observations/system-improvement-signals.md` | low | Fixed -- promoted to L-18 and L-23 there |

### Answers

- **A Implementation -- as expected.** 54 lifecycle merges, all through `finish` (verify first); every Claude slice archived by `archive_slice.py`; no slice claimed twice (40 claims, 38 finished, the other 2 are Codex and were finished by hand). End-of-slice reports were not checked (that would need transcripts).
- **B Planning -- drifting.** No stop shows a worker deciding a design question. But F3: the specifying moved into closeout, and COL-3 took Dave's year decisions mid-slice (`551445c`).
- **C Lanes -- as expected.** Claude 5, Codex 2, above the floor, no file in both lanes. Refill runs at `finish`, except F3's hand edits. Ledger matches; stale worktrees: F6.
- **D Running the queue -- as expected on levels, drifting on cost (F5).** `finish` stopped 67 times: refill 15, verify 17, owner merge-base 9 (fixed 1 Oct, none since), push 5, merge 4, lock wait over 600 s 4.
- **E Checks -- as expected.** 25 filed since 30 Sep, each saying where to go, what to do and what PASS looks like; none is a decision; 19 ready, the oldest from 30 Sep. C-103's resize could become a headless assertion (noted below).
- **G Memory -- F7.**

## Waste, top five (7 days)

| Sink | Evidence | Cost | Disposition |
| --- | --- | --- | --- |
| Check-pass screenshots | 9 sessions, up to 486K context per request | 486M tokens (34%) | Queued -- L-22 |
| Long planning/review sessions on Opus | 42 "other" sessions, up to 266K per request, each opening at 63-64K | 526M tokens (37%) | Hand-off -- context review (opening floor) |
| Coordinator overhead | 259M vs 87M worker; 20 direct verifies | ~170M tokens beyond the workers (inference) | Fixed -- F5 |
| `finish` stops and reruns | 67 stops; 26 extra `finish` calls in coordinator runs | Wall-clock and one coordinator turn each | Queued/Gated -- L-21, L-23 (L-18, L-19 already queued) |
| Lifecycle lock waits | 4 waits over 600 s; lifecycle suite median 398 s holding the lock | ~40 min of waiting | Rejected -- the bounded wait is L-15's design; L-19 narrows the queue-write race |

## Hand-offs

- **Verification review:** `claude/adoring-grothendieck-f9a90f` commit `255860c` stops `tests/test_headless_efficiency_baseline.py` re-executing `run_scenario.py` into `sys.modules`; master still has `_load_module`.
- **Context review:** every session opens at 63-64K context, the multiplier behind F5 and the waste table's second row; `Get-SliceAdvice` prints `claude-sonnet-5` where the current id is `claude-sonnet-5-5`.
- **Codex workflow review:** two Codex pushes failed after L-16 (SR-2, SR-3, 2 Oct), and Codex closeouts archived by hand (BS-8, PE-1, SR-2, SR-3) rather than through `archive_slice.py`.

## Dave's actions

1. **Delete the 17 empty worktree folders.** In Windows PowerShell 5.1, run
   `cd C:\Users\dl13860\Documents\Meadow\meadow` and then
   `Get-ChildItem .claude\worktrees -Directory | Where-Object { -not (Get-ChildItem $_.FullName -Force) } | Remove-Item`.
   It removes only empty folders. To stop them piling up again, turn on
   auto-archive in the Code tab's settings.
2. **After L-22 lands**, open the hands-on check processor prompt in Notion
   ("Meadow review prompt library") and add this as its first step: `Run each
   check with the check-runner subagent (Agent tool, subagent_type
   check-runner), one check per dispatch, passing ROOT=C:\Users\dl13860\Documents\Meadow\meadow
   and the check id. Record only its JSON verdict, and take no screenshots in
   this session.`

## Noted, not pursued

- C-103 (the tray at 800x600) might be a `scenario_actions.gd` layout assertion; a real window drag is what it tests.
- 120 failed headless runs since 28 Sep (65 product, 54 compile) took 0.2 h in total: iteration, not waste.
- PowerShell tool calls failed 32 of 154 times, against 84 of 3,820 for Bash; most are `slice.ps1` stops.
- `plans/now/agent-lifecycle.md` is now over the 260-line soft limit; L-16 to L-23 archive as they land.

## Not reviewed

- End-of-slice report presence, and permission-prompt counts: both need raw transcripts.
- Codex sessions beyond the shared lifecycle.

## Patterns deliberately not applied

- L-20 widens `--days/--classify/--phases` past L-9's primary-only baseline. The reason for keeping it (stable numbers) no longer holds when it measures 1 session in 70.
- No second admission check in L-23: it imports L-18's dry run (plans/README.md rule 4).
