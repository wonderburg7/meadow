# Agent lifecycle — make closeout survive interruption and two lanes

<!-- CONTEXT: plan | LAYER: immediate-task -->

Status: active | Owner: Dave / Claude | Next: L-18 -- the claim warns when it takes a lane's last item into a dry backlog, then L-19 -- queue writes wait for a running finish, and finish re-applies its own queue edit over a sibling's (Dave, 5 Oct 2026, from the 4-5 Oct run-queue run; L-16 and L-17 shipped; the canaries still to be seen are one slice per lane closed out while origin is ahead, and one whose queue title carries an em dash closed out from a `chcp 1252` console with `git log -1 --format=%s master` showing the dash intact); the completion gate in "Objective" (zero `lifecycle_failure` outcomes over seven days, a canary slice named per lane, the implementing share above 40%) is measured on Dave's machine with `python tools/session_cost.py --stops`, `--phases` and `--events` from 6 Oct 2026 (not met on 5 Oct 2026: the seven-day window opens 6 Oct, so the earliest reading is 13 Oct 2026) and pasted into the next agent-workflow review, which cannot read those files from a cloud session (`docs/agent-workflow-review-2026-09-30.md`, Dave's actions) | Dependency: none | Verified: 2026-10-05

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
| L-18 | the claim warns when it takes a lane's last item into a dry backlog | `tools/slice.ps1`, `tools/refill_lane.py`, `tests/test_slice_lifecycle.py` | medium |
| L-19 | queue writes wait for a running finish, and finish re-applies its own queue edit over a sibling's | `tools/refill_lane.py`, `tools/slice.ps1`, `tests/test_two_lane_closeout.py` | high |

L-15 shipped 2026-09-29; its specification is `plans/archive/L-15_2026-09-29.md`.

L-18 and L-19 change `tools/slice.ps1`, whose suite skips off Windows
(`workflow_test_support.windows_powershell`), so each is implemented in a
local Windows session, never a cloud one; L-19 follows L-18 (both edit
`tools/slice.ps1` and `tools/refill_lane.py`).

L-16 shipped 2026-10-02; its specification is `plans/archive/L-16_2026-10-02.md`.

L-17 shipped 2026-10-02; its specification is `plans/archive/L-17_2026-10-02.md`.

## L-18 -- the claim warns when it takes a lane's last item into a dry backlog

<!-- LAYER: immediate-task -->

Level: medium (one script and its suite, with a deterministic check).
Specified 5 Oct 2026: Dave chose this and L-19 from four refill-gate
options; counting a `queue-gated` block toward the floor, and refusing the
claim, were declined, and the floor stays 3.

**True now** (verified 5 Oct 2026). On 4-5 Oct the run-queue coordinator
claimed BS-12, the Claude lane's only item, with nothing admissible behind
it; BS-12 was built, and then `finish` refused to close it at the refill
gate, because deleting it would empty the lane and take the whole queue
under `check_docs.QUEUE_SIZE_MIN`. Nothing warned before the claim: `doctor`
and `start` print `advice` (model and connectors, `Get-SliceAdvice`) but
nothing about what follows the item, and `refill_lane.py --top-up
--dry-run` prints prose only.

**True afterwards.**
- `refill_lane.py --top-up --dry-run` can report in a machine-readable form
  (the lane's count, the ids it would add, the gated ids waiting).
- `doctor` and `start` add `advice.dry_after`: true when closing the item
  would empty its lane or take the whole queue under the floor and the dry
  run would add nothing. `start` prints one warning line naming the item and
  the gated blocks waiting, and still claims: the warning never blocks.

**Must not change.** The floor; `finish`'s refill gate; what `start` claims.

```queue
**[Claude] L-18 -- the claim warns when it takes a lane's last item into a dry backlog**
- Plan: `plans/now/agent-lifecycle.md` -- "L-18 -- the claim warns when it takes a lane's last item into a dry backlog"
- Files: `tools/slice.ps1`, `tools/refill_lane.py`, `tests/test_slice_lifecycle.py`
- Check: `python -m unittest tests.test_slice_lifecycle` passes with a new case (a one-item lane over a dry backlog shows `dry_after` true; the same lane with an admissible block behind it shows false); `tools/verify.ps1` is green
- Proof: `absent: tools/slice.ps1 :: dry_after`
- Next after: L-19 -- queue writes wait for a running finish, and finish re-applies its own queue edit over a sibling's
```

## L-19 -- queue writes wait for a running finish, and finish re-applies its own queue edit over a sibling's

<!-- LAYER: immediate-task -->

Level: high (lock ordering between two processes, and a merge path).
Specified 5 Oct 2026 with L-18.

**True now** (verified 5 Oct 2026). `finish` holds
`<git common dir>/meadow-slice-lifecycle.lock` (`Invoke-WithLifecycleLock`)
and edits `NEXTSTEPS.md` through `refill_lane.py --delete` and `--top-up`.
`refill_lane.py`, run by hand or by another session, takes no lock. On 4-5
Oct a sibling session moved COL-4 between lanes and pushed while a `finish`
was running; the finish's merge then conflicted in `NEXTSTEPS.md` and was
merged by hand.

**True afterwards.**
- `refill_lane.py`'s writing modes wait for the lifecycle lock with
  `Invoke-WithLifecycleLock`'s bounded wait and message (L-15), except when
  `slice.ps1` runs them while it holds the lock (an environment variable it
  sets for the child, never a flag a person types).
- When `finish`'s merge into master conflicts in `NEXTSTEPS.md` and nowhere
  else, it takes master's copy, re-runs its own `--delete <id>` and
  `--top-up` on it, runs `check_docs.py`, and carries on. A conflict in any
  other file stops as today.
- The re-apply is journaled like the other closing phases, so an
  interrupted finish re-runs safely (L-13).

**Must not change.** The floor; a conflict outside `NEXTSTEPS.md` stopping
`finish`; `NEXTSTEPS.md`'s format ("Standing rules" below).

```queue
**[Claude] L-19 -- queue writes wait for a running finish, and finish re-applies its own queue edit over a sibling's**
- Plan: `plans/now/agent-lifecycle.md` -- "L-19 -- queue writes wait for a running finish, and finish re-applies its own queue edit over a sibling's"
- Files: `tools/refill_lane.py`, `tools/slice.ps1`, `tests/test_two_lane_closeout.py`
- Check: `python -m unittest tests.test_two_lane_closeout` passes with two new cases (a hand `--top-up` while the lock is held waits, then writes; a finish whose master moved a lane item meanwhile merges with both edits kept); `tools/verify.ps1` is green
- Proof: `absent: tools/refill_lane.py :: meadow-slice-lifecycle.lock`
- Next after: none -- L-19 is plans/now/agent-lifecycle.md's last slice; its completion gate is a measurement, not a slice
```

## Standing rules

**A second log now exists beside this plan's, and the boundary between them
is fixed.** `plans/archive/WORKFLOW_DIAGNOSTICS_2026-09-18.md` added an event log written by
the scripts themselves (`meadow-diagnostics.jsonl`) and a `--events` mode to
`tools/session_cost.py`, covering verify stages, sessions and cost by branch.
**Stops are not in it.** `tools/slice.ps1`'s own `meadow-slice-stops.jsonl`
and `--stops` stay the single record of what stopped, because L-12's gate is
written against them; `--events` prints a pointer to `--stops` rather than a
second count. `--days`, `--classify` and `--phases` are likewise untouched and
stay this plan's and L-9's measures.

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
