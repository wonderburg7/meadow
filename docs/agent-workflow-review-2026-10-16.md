# Agent workflow review -- 16 Oct 2026

<!-- CONTEXT: review-record | LOAD: on-demand -->
Reviewed: 948be3e | Since: c4e7a7d | Scope: Claude sessions and subagents 5-16 Oct 2026 (80 sessions, 185 subagent transcripts), the stop ledger, verify stages since 9 Oct, the signals intake; Claude-only (no Codex stage 1 in this batch) | Previous: docs/agent-workflow-review-2026-10-05.md

## Follow-through

| Previous finding | Disposition |
| --- | --- |
| F1 -- the workflow cannot measure itself | Shipped -- L-21, `_transcript_files` reads every worktree directory; subagents still unseen (F9 below) |
| F2 -- check passes the biggest cost | Shipped -- L-23, check-runner subagents; single runs still run away (F8) |
| F3 -- planning inside `finish` | Shipped -- L-18 and L-24; successor-specifying closeout commits fell from 15 of ~40 slices to 5 of 89 merges |
| F4 -- verify stops cannot be told apart | Shipped -- L-22 for branch scope only; primary scope was still unreadable (F1 below) |
| F5 -- the coordinator costs three times its workers | Shipped -- now ~23 requests per dispatch (was 41); coordinators 145M against 447M for workers |
| F6 -- stale desktop worktrees | Shipped -- one unmerged branch left, `claude/terminal-plan-state-field` (D2) |
| F7 -- retired memory workarounds | Shipped -- deleted 5 Oct |
| F8 -- untriaged 1 Oct signal | Shipped -- promoted to L-18 and L-24, both landed |

## Findings

Baseline, 5 to 16 Oct: 2,339M context tokens (1,286M top-level, 1,053M
subagents); 51 slices claimed and finished; 112 stops (52 verify, 27 refill,
19 preflight); unit-test stage median 543 s, 22 h of verify in 7 days.

| Id | Finding | Evidence | Severity | Disposition |
| --- | --- | --- | --- | --- |
| F1 | `finish` ran its primary verify without `-Quiet`, so under slice.ps1's `Stop` the first Python stderr line aborted verify.ps1 as a NativeCommandError: all 7 primary stops since 5 Oct named no stage, and the stage logged no event (the previous F4's "fails somewhere that logs nothing") | `slice.ps1::Invoke-SliceFinish` primary-verify args; `verify.ps1::Invoke-PythonStage` unquiet branch; `meadow-slice-verify.log` of RR-7's stop | high | Fixed -- `-Quiet` passed as on the branch run; verify.ps1 green |
| F2 | 17 refill refusals record only "its reason is printed above", so the stop class cannot be classified; one cause was a branch 40 commits behind master (signal of 7 Oct) | stop ledger since 5 Oct; `slice.ps1::Invoke-SliceArchiveAndRefill` | medium | Fixed -- `Get-RefillRefusalReason` puts the reason in the cause; `Get-BranchBehindNote` on both refill stops; helpers tested in a throwaway repository |
| F3 | A prose mention in NEXTSTEPS.md kept a finished plan live, failing the next closeout's primary verify: twice (T2-8a 8 Oct; GD-3's plan stopped RR-7 on 16 Oct, hand fix 4cf2bfc) | `archive_slice.py::archive_plan` `IN_FLIGHT_CITERS` | medium | Fixed -- `_queue_holds`; test `test_repoints_a_prose_mention_in_the_queue_file` |
| F4 | Archiving a plan repointed its routing row into `plans/archive/` (16 of 30 rows by 15 Oct; GD-3's again on 16 Oct) | `archive_slice.py::archive_plan`; `plans/README.md` "Current routing" | low | Fixed -- `_drop_routing_rows` and its test; the stale GD-3 row removed |
| F5 | A resumed `finish` skips branch verify through the closing journal, so a fix or master merge committed after a stop lands unverified (T2-4a, 9 Oct, twice); 4499fb6 fixed only the record | `slice.ps1::Test-BranchVerified`, `::Write-ClosingJournal` | high | Queued -- L-27 in `plans/now/agent-lifecycle.md` |
| F6 | Archiving a slice carries the next slice's queue block into the archive (RR-6, SP-10; second recurrence) | `archive_slice.py::archive`; `git show HEAD:plans/archive/SP-10_2026-10-15.md` | medium | Queued -- L-28 in `plans/now/agent-lifecycle.md` |
| F7 | Nothing releases work whose unblocker landed: 10 of 15 blocked checks wait only on archived slices (C-84, C-109 to C-111, C-114 to C-118, C-130); check_docs' shipped-slice deferral warning (WC-1, 9 Oct) is hidden by `finish`'s `-Quiet` verify; GD-2b's finish stalled a day unseen | `checks/blocked.md` `Blocked by:` lines; `check_docs.py::check_stale_deferrals`; `verify.ps1::Write-StageResult` | high | Decided -- `plans/reference/queue-steward.md` and `plans/reference/reviews/check-processor.md` (D1: A, surface it); slice L-30 in `plans/now/agent-lifecycle.md`, gated on D2 |
| F8 | Single check runs run away: C-109 (Opus, 81M, four Colony Runs that RR-1 made impossible) and C-113 (Opus, 73M, 112 screenshots) were 6.6% of the period's context | subagent transcripts, `check-runner-opus` | medium | Fixed -- two-attempt limit in `plans/reference/check-runner.md`; canary is the next pass's per-dispatch context |
| F9 | `--days/--classify/--phases` cannot see subagent transcripts (45% of context), and workers edit through scratchpad scripts (0 Edit calls in 59 dispatches), so "11.0% implementing" is an artefact and the plan's completion gate cannot be judged | `session_cost.py::_transcript_files`, `::_product_edit` | high | Queued -- L-29 in `plans/now/agent-lifecycle.md` |
| F10 | `--stops` ignored `--days`, so each review wrote its own window filter | `session_cost.py::run_stops` | low | Fixed -- explicit `--days` windows the ledger; test in `tests/test_session_cost_stops.py` |
| F11 | Signal: sessions still try the denied paths (42 refusals in 11 days, 32 naming `plans/archive/`, queue steward 9) | transcript scan | low | Rejected -- about four turns a day; the steward's brief already forbids it |
| F12 | Signal: "primary checkout is not on master" names no holder | stop of 7 Oct | low | Rejected -- one occurrence |
| F13 | Signal: a ledger row committed off master fails the other lane's verify | 1863881 | low | Rejected -- one occurrence |
| F14 | Signal: a lane move split a file-sharing sequence | 59d60d5 | low | Rejected -- one occurrence, in a lane move Dave authorised |
| F15 | Signal: a worker settled an open gameplay point | e170c3e | low | Rejected -- the worker brief has forbidden it since 1 Oct, and the slice reviewer caught it |

Signals triage: 16 untriaged entries read. Fixed 4 (above), promoted 3
(L-27, L-28, L-30), merged 1 (the stalled Codex finish into F7), superseded
1 (primary import cache, ca6f34c), rejected 5, and 3 left for their own
reviews (Hand-offs).

## Hand-offs

- **Plan review:** signals "the panel-rectangle rule has a home again" and "slice file lists miss the UI file a readout needs" (7 Oct), each marked as that review's lane.
- **UI review:** signal "readout history starts empty after every load" (7 Oct), marked as that review's lane.

## Dave's actions

1. **D2 (A): finish `claude/terminal-plan-state-field`.** It has 1 commit
   from 14 Oct, is 108 commits behind master, sits in worktree
   `.claude/worktrees/dazzling-hertz-6dbe66` and owns `tools/check_docs.py`,
   which L-30 waits for. In a new Claude session opened on that worktree,
   type: `Merge master into this branch, run .\tools\verify.ps1, and merge
   it to master as plans/reference/closeout.md describes.`

## Noted, not pursued

- Opus slice workers cost 318M over 16 high-level dispatches (about 20M each, against 3M for medium). Every level cites a save field, hot path or event ordering, as rule 4 allows.
- Unit-test stage median 543 s (max 7,308 s on 12 Oct), down to about 400 s since 15 Oct. Test design belongs to the verification review.
- Codex-only stops from 10 to 12 Oct: the WindowsApps `python.exe` stub (6) and the sandbox's background-job `Win32Exception` (6). None since. No Codex stage ran.
- Check-pass coordinators peaked at 270K context, with 147 Bash calls in one session.
- `slice.ps1 status` threw a null-valued error 3 times on 8 Oct. It runs cleanly now.
- "git merge failed" 3 times. Each retry succeeded within a minute.
- Prompt fix (contract rule 10): none needed. `--stops --days` is now available for step 1.

## Not reviewed

- End-of-slice reports in transcripts.
- Codex sessions (no stage 1 block).
- `.codex/hooks.json` behaviour.

## Patterns deliberately not applied

- Automatic release of blocked checks or fences in `finish` (D1 option B). Dave chose to surface the warnings and leave the moves to the steward and the check processor.
- No `check_docs.py` half for F6 yet. An unmerged branch owns the file. L-28 fixes the source and leaves the check for after D2.
