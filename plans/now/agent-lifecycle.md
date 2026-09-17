# Agent lifecycle — make closeout survive interruption and two lanes

<!-- CONTEXT: plan | LAYER: immediate-task -->

Status: active | Owner: Dave / Claude | Next: None -- L-9 shipped, but the completion gate is unmet; wait for future sessions' evidence, no further slice | Dependency: none | Verified: 2026-09-17

## Objective

`tools/slice.ps1 finish` fails often enough that retrying it is normal, and
every failure after its first push leaves work merged with cleanup
outstanding. Make closeout a transaction that is safe to interrupt and safe
to re-run, prove it under two concurrent lanes, and measure the result.

The second objective is cost, and it is the larger one. Writing code was
25.6% of a session's context spend at F13's measurement; 47.1% fell after
the last product edit, in closeout and document curation, and a further
17.4% went to sessions that made no product edit at all. **Target: raise the
implementing share above 40%.** L-9 built the re-measurement
(`session_cost.py --phases`); over the seven sessions since L-5 merged the
share is 40.0% -- the threshold itself, not yet above it, on too small a
sample to call moved. Nothing in this plan may buy that by removing a check.

The evidence is in `docs/agent-workflow-review-2026-09-12.md`; findings are
cited as F1 to F12 and are not restated here. The 3 September plan is
complete and archived at `plans/archive/AGENT_WORKFLOW_2026-09-03.md`. It is
not reopened: this is a new plan for defects that surfaced after it shipped.

## Current state

- 97 `finish` calls produced 54 closeouts. 39 exited non-zero; 24 of 54
  sessions retried; 10 never got a clean exit. Codex: 20 of 20 non-zero.
- `Invoke-SliceFinish` holds one exclusive lock across verification, the
  merge and a single push, with up to 180 seconds of Windows deletion
  retries. Archival and queue refill are still authored by hand, but as of
  L-5 they happen on the branch and are gated, not manual-and-unenforced,
  before `finish` will merge.
- The four small fixes of 12 September 2026 landed on `claude/WF-1`: Codex
  may run `resume`; declared actions are single unchained commands; `start`
  and `doctor` print a `read` command and `next_after`; `doctor` reports
  whether the global Git excludes file is readable.
- L-1 shipped 12 September 2026: `tests/test_source_checks.py` is 32/32
  green and `tools/verify.ps1` runs it as a third parallel job. Landing it
  also required a `Get-DoctorEnvironmentFailures` fix outside the slice's
  stated Non-goals (a native git call's stderr crashed the doctor's
  environment check under Windows PowerShell 5.1) -- full record at
  `plans/archive/AGENT_LIFECYCLE_L1_2026-09-12.md`.
- L-3 shipped 13 September 2026: `verify.ps1 -Scope branch|primary|all`
  separates a branch's own suites from the primary checkout's ledger check.
  Closeout surfaced the exact defect L-4 targets -- the worktree directory
  stayed locked after verification and failed to delete -- full record at
  `plans/archive/L-3_2026-09-13.md`.
- L-9 shipped 17 September 2026: `session_cost.py --phases` and the
  repository/host context split exist and were checked against live
  sessions, but the completion gate is unmet on three of its four
  conditions, so the plan is not yet complete -- full record at
  `plans/archive/L-9_2026-09-17.md`.

## Open slices

None. L-9, this plan's last slice, shipped 17 September 2026; the
completion gate it checks is not yet satisfied, so the plan stays `active`
without a further slice to implement -- see `plans/archive/L-9_2026-09-17.md`.

Dependencies, stated rather than implied: L-1 was the prerequisite for
everything else, because nothing else in this plan could be trusted while
its tests did not run -- it shipped 12 September 2026 (archived at
`plans/archive/AGENT_LIFECYCLE_L1_2026-09-12.md`), so L-2, L-3, L-7 and L-8
became startable; L-2 and L-3 have since shipped too (archived at
`plans/archive/L-2_2026-09-12.md` and `plans/archive/L-3_2026-09-13.md`).
L-4 shipped 14 September 2026 (archived at
`plans/archive/L-4_2026-09-14.md`), L-5 shipped the same day (archived at
`plans/archive/L-5_2026-09-14.md`), L-6 shipped the same day too (archived
at `plans/archive/L-6_2026-09-14.md`), and L-7 shipped the same day too
(archived at `plans/archive/L-7_2026-09-14.md`), so L-8 became startable.
L-8 shipped 17 September 2026 (archived at `plans/archive/L-8_2026-09-17.md`),
so L-9 became startable. L-9 shipped the same day (archived at
`plans/archive/L-9_2026-09-17.md`), leaving no further slice in this plan.

**Do not change** `plans/workstreams.md`'s format or `NEXTSTEPS.md`'s item
schema in this plan. Both are parsed by `tools/slice.ps1` and
`tools/check_docs.py` with regular expressions that have each been fixed
twice; a format change turns into a silent parse failure. Extend the parsers,
never the formats.

**Read for any slice here:** this plan's own section and nothing else. F1 to
F12 in the review are the evidence and do not need rereading to implement.

L-1 (the lifecycle suite is green and runs in verification) shipped 12
September 2026. Full specification, actual outcome and the two unrelated
findings its closeout surfaced: `plans/archive/AGENT_LIFECYCLE_L1_2026-09-12.md`.

**L-2 — every outcome is classified, every closeout phase is injected.**
Landed 2026-09-12. `classify_outcome` and `--classify` shipped in
`tools/session_cost.py`; all seven injected closeout phases resume cleanly
with the merge landing on master. The classify baseline does not agree with
the review's Part 1 figures within 10% -- see
`plans/archive/L-2_2026-09-12.md` for the numbers and why that is left as a
follow-up rather than force-fit here.

L-3 (branch verification and bookkeeping validation are separate scopes)
shipped 13 September 2026. Full specification and outcome:
`plans/archive/L-3_2026-09-13.md`.

L-4 (the worktree is deleted out of process, outside the lock) shipped 14
September 2026: `Invoke-SliceFinish` now tries one `git worktree remove` and
queues a survivor in `meadow-slice-pending-deletions` instead of retrying
inside the lock; `doctor` reports the queue and `check_docs.py` skips listed
paths. Full specification and outcome: `plans/archive/L-4_2026-09-14.md`.

L-5 (closeout is one transaction: a phase journal, one push, and
archive+refill committed on the branch before merge) shipped 14 September
2026. Full specification and outcome: `plans/archive/L-5_2026-09-14.md`.

L-6 (the concurrency contract, over the five cases that actually happened,
as `TwoLaneCloseoutTest`'s six tests) shipped 14 September 2026. One real
defect surfaced and was fixed: nothing refused an uncommitted edit to
`plans/workstreams.md` or `checks/ready.md` in the primary checkout before
merging; `Invoke-SliceFinish` now does. Full specification and outcome:
`plans/archive/L-6_2026-09-14.md`.

L-7 (the queue cannot contradict itself) shipped 14 September 2026.
`check_queue_section_agreement` in `tools/check_docs.py` rejects an id that
is both ready in `## Next up` and named in `## Not in the queue, and why`,
matching only each bullet's bolded lead so legitimate prose mentions of
other ids stay allowed. The plan's own `UI-U-1`/`A1`/`A2` contradiction had
already been overtaken by later slices by the time this landed, so there
was nothing live left to fix. Full specification and outcome:
`plans/archive/L-7_2026-09-14.md`.

L-8 (a Godot failure names which of five things broke) shipped 17
September 2026. `Get-GodotCapability` in `tools/slice.ps1` returns one of
`mcp_unavailable`, `editor_unavailable`, `import_cache_missing`,
`environment_crash` or `ready`, checked in that order so the import-cache
false alarm is ruled out before the boot probe that would otherwise
misreport it; `doctor` reports it as `godot_capability`, and only
`editor_unavailable` still blocks `doctor` itself. Full specification and
outcome: `plans/archive/L-8_2026-09-17.md`.

L-9 (the floor is measured and split, and this plan is gated) shipped 17
September 2026. `tools/session_cost.py` gained `--phases` (F13's four-row
requests/context/share table, reproduced within 10% for 4-12 Sep) and split
`--days N`'s session-opening figure into `repository context` and `host
context`. The completion gate was checked the same session: of its four
conditions, only the measurement-ran-once condition is met; the other three
(zero `lifecycle_failure` over 7 days, a named canary slice per lane, and an
implementing share re-measured above 40%) are not yet, so the plan stays
`active` with no further slice pending future sessions' evidence. Full
specification, the before/12-Sep/after table and the gate check:
`plans/archive/L-9_2026-09-17.md`.
