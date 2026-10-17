# Agent lifecycle — make closeout survive interruption and two lanes

<!-- CONTEXT: plan | LAYER: immediate-task -->

Status: active | Owner: Dave / Claude | Next: L-28 -- archiving a slice leaves another slice's queue block in the plan | Dependency: L-30 waits for `claude/terminal-plan-state-field` to merge | Verified: 2026-10-17

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
lifecycle scripts. L-16 and L-17 (shipped 2 Oct 2026) answered that
evidence; the ad-hoc-branch share stays a finding with no slice until a
measurement says what those sessions were doing.

## Open slices

| Slice | What it does | Files it owns | Level |
| --- | --- | --- | --- |
| L-28 | Archiving a slice leaves another slice's queue block in the plan | `tools/archive_slice.py`, `tests/test_slice_lifecycle.py` | medium |
| L-30 | Released work is visible: finish shows doc warnings, and a blocked check whose unblockers landed is named | `tools/verify.ps1`, `tools/check_docs.py`, `tests/test_wc1_stale_deferrals.py` | medium |

L-16 to L-26 shipped 2 to 13 Oct 2026, each with its record in
`plans/archive/` named by id and date; WC-1 to WC-5 shipped with
`plans/archive/workflow-checks_2026-10-10.md`. The 16 Oct 2026
agent-workflow review measured the mechanisms behind L-27, L-28 and L-29. L-27 and L-28 share a
test file, so L-28 follows L-27. Each slice's acceptance names a
before-figure from that review and one real canary closeout.

L-27 shipped 2026-10-17; its specification is `plans/archive/L-27_2026-10-17.md`.

## L-28 -- archiving a slice leaves another slice's queue block in the plan

<!-- LAYER: immediate-task -->

Level: medium. **Now:** `tools/archive_slice.py::archive` moves everything
from the slice's heading to the next heading into the archive. A plan that
writes slice N+1's `queue` (or `queue-gated`) block at the end of slice
N's section loses it with N: RR-6's archive took RR-7's
block and SP-10's took SP-11's (15 Oct 2026, the second recurrence;
`plans/README.md` rule 11 is the written rule).

**After:** new `def _foreign_queue_blocks(section_text, slice_id)` returns
each fenced `queue` or `queue-gated` block in the cut section whose first
line's id (check_docs' `QUEUE_ITEM_HEAD`, `**[Lane] <id> --`) is not
`slice_id`. `archive` writes the section to the archive without those
blocks and leaves them in the live plan directly below the one-line
pointer, byte for byte, and prints `kept in plan: <id>'s queue block` for
each. The slice's own block still goes to the archive.

**Must not change:** the archived text apart from the removed blocks; the
dirty-tree refusal; the open-slices-table row removal; `tools/check_docs.py`
(a branch, `claude/terminal-plan-state-field`, owns it; its half of the
signal, failing a block under the wrong heading, waits for that branch).

**Tests** in `tests/test_slice_lifecycle.py`: a section holding its own
`queue` block and a following slice's `queue-gated` block archives only its
own; the live plan keeps the pointer then the other block unchanged.

**Acceptance:** the next closeout of a slice whose section ends with its
successor's block leaves that block live (before: two lost on 15 Oct).

```queue
**[Claude] L-28 -- archiving a slice leaves another slice's queue block in the plan**
- Plan: `plans/now/agent-lifecycle.md` -- "L-28 -- archiving a slice leaves another slice's queue block in the plan"
- Files: `tools/archive_slice.py`, `tests/test_slice_lifecycle.py`
- Check: `python -m unittest tests.test_slice_lifecycle` passes, including the case where a section ends with the next slice's queue-gated block; `.\tools\verify.ps1` is green
- Proof: `absent: tools/archive_slice.py :: def _foreign_queue_blocks`
- Next after: L-29 -- session_cost.py counts subagent transcripts and scripted edits
```

L-29 shipped 2026-10-17; its specification is `plans/archive/L-29_2026-10-17.md`.

## L-30 -- released work is visible to the sessions that release it

<!-- LAYER: immediate-task -->

Level: medium. Dave's choice, 16 Oct 2026 (D1 of that day's agent-workflow
review, option A): surface it, don't automate it. The queue steward's
`gates` job clears the deferrals and fences (`plans/reference/queue-steward.md`)
and the check processor moves the checks (`plans/reference/reviews/check-processor.md`);
this slice gives both something to read.

**Now:** `tools/check_docs.py::check_stale_deferrals` has warned since
WC-1 (9 Oct) when a `## Not in the queue` line waits for a shipped slice,
but `finish` runs `tools/verify.ps1 -Quiet`, whose `Invoke-PythonStage`
prints only `doc checks: OK` on a pass, so no closing session sees it (three
such warnings, TS-1, T2-13 and RR-11, on 16 Oct). Nothing checks
`checks/blocked.md`: on 16 Oct ten entries (C-84, C-109 to C-111, C-114 to
C-118, C-130) waited only on archived slices, eight of them since RR-1
landed on 13 Oct.

**After:**

- `tools/verify.ps1` `Invoke-PythonStage`: under `-Quiet`, a passing stage
  also prints each captured line that starts with `WARNING:`, after its
  `<name>: OK` line. Failing stages unchanged.
- New `def check_released_blocked_checks(warnings, text=None, root=None)` in
  `tools/check_docs.py`, called beside `check_stale_deferrals`. For each
  `### C-<n>` entry in `checks/blocked.md`, take its `Blocked by:` line up to
  the first ` -- `. Collect the slice ids in it (`check_stale_deferrals`'
  id pattern). Warn only when there is at least one id, every id has a
  `plans/archive/<id>_*.md`, and nothing else is left once the ids,
  backticked spans, parentheses, commas, full stops and the word "and" are
  removed (so "RR-7 and the fix it specifies" never warns). Text:
  `checks/blocked.md: C-<n> waits only for shipped slices <ids> -- move it to checks/ready/ (the check processor's first step)`.

**Must not change:** every existing warning and error; `-Quiet`'s single
line for a passing stage with no warnings; the blocked file's format.

**Tests** in `tests/test_wc1_stale_deferrals.py`: an entry blocked by one
archived id warns; one also naming an unarchived id does not; one whose lead
has prose besides the ids does not; an entry with no ids does not.

**Acceptance:** on master as of 16 Oct, `python tools/check_docs.py` names
exactly the ten checks above (fewer if the check processor has moved some),
and the next `finish`'s output shows the doc-check warnings; the next check
pass moves the released checks first.

```queue-gated
**[Claude] L-30 -- released work is visible to the sessions that release it**
- Plan: `plans/now/agent-lifecycle.md` -- "L-30 -- released work is visible to the sessions that release it"
- Files: `tools/verify.ps1`, `tools/check_docs.py`, `tests/test_wc1_stale_deferrals.py`
- Check: `python -m unittest tests.test_wc1_stale_deferrals` passes, including the four blocked-check cases; `python tools/check_docs.py` warns for each blocked check whose unblockers have all shipped; `.\tools\verify.ps1 -Quiet` prints the doc-check WARNING lines after `doc checks: OK`; `.\tools\verify.ps1` is green
- Proof: `absent: tools/check_docs.py :: def check_released_blocked_checks`
- Next after: None -- plan complete once L-27 to L-29 land
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

Shipped: L-1 to L-26, one archive record each in `plans/archive/`, named
by id and date (L-1's is `plans/archive/AGENT_LIFECYCLE_L1_2026-09-12.md`).
L-2's classify baseline still disagrees with the 12 Sep review's Part 1
figures by more than 10%, an open follow-up recorded there.
