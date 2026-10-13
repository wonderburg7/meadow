# Agent lifecycle — make closeout survive interruption and two lanes

<!-- CONTEXT: plan | LAYER: immediate-task -->

Status: active | Owner: Dave / Claude | Next: the completion-gate measurement only (L-26 makes short-lane warnings use the refill admission test; the seven-day outcome and cost gate remains) | Dependency: none | Verified: 2026-10-13

## Objective

`tools/slice.ps1 finish` fails often enough that retrying it is normal, and
every failure after its first push leaves work merged with cleanup
outstanding. Make closeout a transaction that is safe to interrupt and safe
to re-run, prove it under two concurrent lanes, and measure the result.

The second objective is cost, and it is the larger one. Writing code was
25.6% of a session's context spend at F13's measurement; 47.1% fell after
the last product edit, in closeout and document curation, and a further
17.4% went to sessions that made no product edit at all. **Target: raise the
implementing share above 40%** (`session_cost.py --phases`, built by L-9).
Re-measured 17 Sep 2026 over calendar windows: 23.0% implementing over 21
days and 19.0% over 7, against 41.3% and 47.4% after the last product edit.
L-10 to L-13 were the response: they made `finish`'s hand-authored gates
into actions. Nothing in this plan may buy the target by removing a check.

The evidence is in `docs/agent-workflow-review-2026-09-12.md`; findings are
cited as F1 to F12 and are not restated here. The 3 September plan is
complete and archived at `plans/archive/AGENT_WORKFLOW_2026-09-03.md`. It is
not reopened: this is a new plan for defects that surfaced after it shipped.

## Current state

L-1 to L-15 have shipped (one archive record each, under "Standing rules"
below): closeout is a journaled transaction whose `archived` and `refilled`
phases are actions (`tools/archive_slice.py`, `tools/refill_lane.py`), and a
lane refills itself from the plans' `queue` blocks. The completion gate in
"Objective" has not been met on any window measured; the evidence is
`docs/agent-workflow-review-2026-09-12.md`, not this section.

Re-read 30 Sep 2026 from Git alone, because the review ran in a cloud
session with no transcripts, stop ledger or event log
(`docs/agent-workflow-review-2026-09-30.md`): 75 claims and 71 closes
between 12 and 30 Sep, no slice claimed twice since 20 Sep, a median
claim-to-close of 26 minutes; but 7 pull-type merges on master, 56 of 117
merges from branches the lifecycle never saw, 23 hand-written closeout or
queue-repair commits on master, and seven ad-hoc encoding fixes to the
lifecycle scripts. L-16 and L-17 below are the two mechanisms that evidence
supports; the ad-hoc-branch share is recorded there as a finding with no
slice until the next measurement says what those sessions were doing.

## Open slices

| Slice | What it does | Files it owns | Level |
| --- | --- | --- | --- |
| L-26 | Warn only for queue blocks the refill can actually admit | `tools/check_docs.py`, `tests/test_queue_lookahead.py` | medium |

WC-1 to WC-5 (`plans/archive/workflow-checks_2026-10-10.md`, Codex lane, 7 Oct 2026) extend
this plan's `tools/check_docs.py` and `tools/refill_lane.py` without changing
`tools/slice.ps1` or any format: stale deferrals, the dry-lane report,
Codex's hooks, spaced ids and level-to-model parity.

L-21 to L-24 come from `docs/agent-workflow-review-2026-10-05.md` (F1 to F5);
L-23 and L-24 are Dave's 5 Oct 2026 choices. L-22 follows L-19 and L-24
follows L-18 (shared `tools/slice.ps1`; L-18's machine-readable dry run).

L-15 shipped 2026-09-29; its specification is `plans/archive/L-15_2026-09-29.md`.

L-18 and L-19 change `tools/slice.ps1`, whose suite skips off Windows
(`workflow_test_support.windows_powershell`), so each is implemented in a
local Windows session, never a cloud one; L-19 follows L-18 (both edit
`tools/slice.ps1` and `tools/refill_lane.py`).

L-16 shipped 2026-10-02; its specification is `plans/archive/L-16_2026-10-02.md`.

L-17 shipped 2026-10-02; its specification is `plans/archive/L-17_2026-10-02.md`.

L-18 shipped 2026-10-05; its specification is `plans/archive/L-18_2026-10-05.md`.

L-19 shipped 2026-10-05; its specification is `plans/archive/L-19_2026-10-05.md`.

L-21 shipped 2026-10-06; its specification is `plans/archive/L-21_2026-10-06.md`.

L-22 shipped 2026-10-06; its specification is `plans/archive/L-22_2026-10-06.md`.

L-23 shipped 2026-10-06; its specification is `plans/archive/L-23_2026-10-06.md`.

L-24 shipped 2026-10-06; its specification is `plans/archive/L-24_2026-10-06.md`.

## L-26 -- queue readiness warnings use the refill admission test

<!-- LAYER: immediate-task -->

Level: medium. On 13 Oct 2026, `python tools/check_docs.py` warned that the
Codex backlog offered GD-2b while `python tools/refill_lane.py --top-up
--lane Codex --dry-run --root .` refused it: the Claude lane owns
`scripts/save_game.gd` and `scripts/saving.gd` for PP-5. The warning counts
open `queue` blocks without applying the refill admission test.

Make the short-lane warning name only blocks that a refill would actually
admit at that moment, reusing `refill_lane.py`'s admission path rather than
adding a second set of rules. Keep it a warning. A blocked block still
appears in the refill's dry-lane report with its reason. Test both the
file-overlap case and a genuinely admissible block. Do not change queue
format, lane ownership or the minimum queue size.

```queue
**[Codex] L-26 -- queue readiness warnings use the refill admission test**
- Plan: `plans/now/agent-lifecycle.md` -- "L-26 -- queue readiness warnings use the refill admission test"
- Files: `tools/check_docs.py`, `tests/test_queue_lookahead.py`
- Check: `python -m unittest tests.test_queue_lookahead` passes, proving the warning omits an overlapping block and names an admissible block; `python tools/check_docs.py` no longer claims GD-2b is offered while PP-5 owns its save files; `tools/verify.ps1` is green
- Proof: `absent: tools/check_docs.py :: def refill_ready_ids`
- Next after: GD-2b -- the shown ledger and Why history saved with the run, after PP-5 releases its save files
```

## Standing rules

**A second log now exists beside this plan's, and the boundary between them
is fixed.** `plans/archive/WORKFLOW_DIAGNOSTICS_2026-09-18.md` added an event log written by
the scripts themselves (`meadow-diagnostics.jsonl`) and a `--events` mode to
`tools/session_cost.py`, covering verify stages, sessions and cost by branch.
**Stops are not in it.** `tools/slice.ps1`'s own `meadow-slice-stops.jsonl`
and `--stops` stay the single record of what stopped, because L-12's gate is
written against them; `--events` prints a pointer to `--stops` rather than a
second count. `--days`, `--classify` and `--phases` read every worktree's transcripts
since L-21 (before it, the primary directory alone) and stay this plan's and L-9's measures.

**Do not change** `plans/workstreams.md`'s format or `NEXTSTEPS.md`'s item
schema in this plan. Both are parsed by `tools/slice.ps1` and
`tools/check_docs.py` with regular expressions that have each been fixed
twice; a format change turns into a silent parse failure. Extend the parsers,
never the formats.

**Read for any slice here:** this plan's own section and nothing else. F1 to
F12 in the 12 Sep review and F1, F2 in the 30 Sep review are the evidence and
do not need rereading to implement.

Shipped: L-1 to L-15, one archive record each in `plans/archive/`, named
by id and date (L-1's is `plans/archive/AGENT_LIFECYCLE_L1_2026-09-12.md`).
None needs rereading to
work on L-16 or L-17; L-2's classify baseline still disagrees with the 12 Sep
review's Part 1 figures by more than 10%, an open follow-up recorded there.
