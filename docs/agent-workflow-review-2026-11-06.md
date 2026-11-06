# Agent workflow review, stage 2 -- 6 Nov 2026

<!-- CONTEXT: review-record | LOAD: on-demand -->
Reviewed: 11cb62c | Since: 948be3e | Scope: Claude only (no CODEX FINDINGS block was supplied); session cost, stops and events for 16 Oct to 6 Nov; signals added since 16 Oct | Previous: docs/agent-workflow-review-2026-10-16.md

## Follow-through

| Previous finding | Disposition |
| --- | --- |
| F1 -- primary verify without `-Quiet` | Shipped -- fixed 16 Oct |
| F2, F3, F4, F8, F10 | Shipped -- fixed 16 Oct |
| F5 -- resumed finish skipped branch verify | Shipped -- L-27 (`git log --grep=^L-27 master`, 3c86533) |
| F6 -- archive carried the next block | Shipped -- L-28 (af54230) |
| F7 -- landed unblockers released nothing | Shipped -- L-30 (1ff91ed) |
| F9 -- subagents invisible to cost tools | Shipped -- L-29 (b1778c5); `--days` now reads 236 subagent transcripts |
| F11 to F15 | Rejected -- unchanged; no second occurrence found |

## Findings

Baseline, 16 Oct to 6 Nov (`python tools/session_cost.py --days 21` with `--stops`, `--events`, `--slices`, `--coordinator`, `--classify`): 1,966M context tokens over 339 sessions (103 top-level, 236 subagents); 56 slices claimed, 51 finished; 85 stops (23 branch verify, 9 primary verify, 21 preflight); unit-test stage median 691 s (543 s on 16 Oct), lifecycle tests 479 s; coordinator housekeeping median 27.7%.

| Id | Finding | Evidence | Severity | Disposition |
| --- | --- | --- | --- | --- |
| F1 | `slice.ps1 owner` counted every unmerged `origin/jules/*` branch and never read the ledger, so merged J-50, returned S-3 and closed E-28 "owned" `code-health.md` and the signals file; this review hit it twice and the 5 Nov signal names a dead-helper fix it blocked | `slice.ps1::Invoke-SliceOwner` (before); `jules_preflight.py::owners` / `::unprocessed`; ledger rows J-50, S-3, E-28 | high | Fixed -- `owner` reads `plans/reference/jules-ledger.md` at origin/master and skips merged, returned and closed branches; new test fails on 11cb62c and passes; canary: `owner plans/now/code-health.md plans/observations/system-improvement-signals.md` owned before, clear after |
| F2 | `tests/test_guard_hook.py` wrote every refusal it provoked into the shared `meadow-diagnostics.jsonl`: 135 of 138 `guard_refusal` events are `session: guard-test`, so `--events` overstates refusals per test run | `grep -c guard-test <git-common-dir>/meadow-diagnostics.jsonl` | medium | Fixed -- `diagnostics.py::log_path` honours `MEADOW_DIAGNOSTICS_LOG`; `run_hook` points it at a temp file and asserts the event landed there; the shared count stayed 135 across a full run of both guard test modules |
| F3 | Four high-level slices (PP-9 365 requests, RR-19 337, PP-11 327, ED-1 192) were 70% of Claude-lane slice cost (39.9M of 56.6M) and all over the 150-request budget | `session_cost.py --slices` | medium | Rejected -- already acted on: ED-1 was cut into ED-1b and ED-1c, ED-2 into ED-2 and ED-2b (plan review 5 Nov F8), and the 8-file budget warns; no high slice has been claimed since ED-1 to test it against |
| F4 | Codex-lane runs stop on the WindowsApps `python.exe` alias (12 stops in 21 days, none in the Claude lane) | `--stops` preflight causes; stop ledger rows with `WindowsApps` all `lane: Codex` | medium | Rejected here -- Codex-only and needs `codex sandbox` to verify; signal of 6 Nov 2026 for stage 1 |

Signals triage (since 16 Oct): fixed 1 (returned Jules branch owns files, F1); read and left for the Jules programme review 5 (29 Oct audit scope, 30 Oct corrections on origin, 30 Oct standalone imports, 30 Oct reverted task, 4 Nov R-gameplay sampling); added 1 (F4). The 4 Nov director save-shape entry went to the save review, decided the same day.

## Hand-offs

- Jules programme review: the five Jules signals above, each marked on its entry in `plans/observations/system-improvement-signals.md`.
- agent-workflow stage 1 (Codex): the WindowsApps alias signal of 6 Nov 2026 in the same file.

## Noted, not pursued

- `--events` reports `guard_refusal=1529` while the log holds 138 such rows; the count likely spans more than the shared log (inference, unchecked).
- `review_due.py agent-workflow-review` printed "handoffs: none untriaged" with six untriaged entries in the intake: it matches only entries that name a review.
- The 135 `guard-test` rows already in the shared log stay until it is rotated.
- The 6 Nov gate rewrite for CQ-M6 left "waits for and for the Claude lane's PN-5" on CQ-M6b's `NEXTSTEPS.md` line, a second shape of the fragment L-30 fixed; corrected by hand. Reopen on a third.

## Not reviewed

- Codex metrics and failure classes (no stage 1 block); transcripts were not opened.

## Patterns deliberately not applied

- No second ledger parser in a shared module: `owner` parses the six-cell row inline, as `jules_preflight.py::parse_ledger` does.
