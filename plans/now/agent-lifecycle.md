# Agent lifecycle — make closeout survive interruption and two lanes

<!-- CONTEXT: plan | LAYER: immediate-task -->

Status: active | Owner: Dave / Claude | Next: L-10 -- the delivered slice's plan section archives itself | Dependency: none | Verified: 2026-09-17

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

Re-measured 17 Sep 2026 over calendar windows rather than a session count,
which counts every session including the ones that write no code: over 21
days implementing is 23.0% against 41.3% after the last product edit, and
over 7 days it is 19.0% against 47.4%. The two framings are not comparable
figures, but neither shows the target met, and the calendar one is moving
the wrong way. L-10 to L-13 below are the response: they attack the closeout
share directly, by making `finish`'s hand-authored gates into actions.

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
- Instrumentation and permission work landed on
  `claude/slice-automation-opportunities` (17 Sep 2026), outside the slice
  queue, because it is what tells L-10 to L-13 where to aim:
  `tools/slice.ps1` records every stop to `meadow-slice-stops.jsonl` in the
  git common directory and `session_cost.py --stops` tallies them by step;
  `session_cost.py --no-edit-reasons` splits the no-product-edit quarter
  (over 7 days: 30.1% read-only, 36.3% Markdown-only, 33.6% other);
  `tools/new_check.py` allocates the next free `C-<n>` and writes the record
  skeleton, reading `docs/archive/` which an agent's own file tools cannot;
  `.claude/settings.json` allow-lists the read-only commands that produced
  most denials, and `docs/known-pitfalls.md` records the `cd … && …` habit
  that caused ~58 of them.
- The completion gate stands at: 39 `lifecycle_failure` outcomes over the 7
  days to 17 Sep 2026 against a required zero, no canary slice named per
  lane, and the implementing share below 40% on every window measured. Only
  the measurement-ran-once condition is met.

## Open slices

`finish` has gates, not actions. Its `archived` and `refilled` phases check
that a session performed an edit by hand, print a stop block when it has not,
and make it retry. Every gate is a place where a script could have done the
work instead of verifying it, and the verifying is what the 41-47% closeout
share is mostly made of.

| Slice | What it does | Files it owns | Level |
| --- | --- | --- | --- |
| L-10 | The delivered slice's plan section moves itself to `plans/archive/` | tools/archive_slice.py, `tools/heading.py`, `tests/test_slice_lifecycle.py` | medium |
| L-11 | The delivered item leaves its lane without being retyped | tools/refill_lane.py, `tests/test_source_checks.py` | medium |
| L-12 | A plan's slice section carries the queue lines it is refilled from | `tools/check_docs.py`, `plans/now/*.md` | high |
| L-13 | Closeout is one command: the gates become actions | `tools/slice.ps1`, `tests/test_two_lane_closeout.py` | high |

Dependencies, stated rather than implied: L-10 and L-11 are independent of
each other, and either may ship first. L-13 is their integration and needs
both merged. **L-12 is deliberately gated** -- do not start it until
`python tools/session_cost.py --stops` shows the refill step among the two
most frequent stops over at least ten recorded stops. It is the only slice
here that touches every live plan, and the instrument that would justify it
only started recording on 17 Sep 2026. None of the four may be bought by
removing a check.

**L-10 -- the delivered slice's plan section moves itself to the archive.**
`finish`'s `archived` phase checks that the section named by the item's
`Plan:`/`Heading:` has been moved by hand into plans/archive/<id>_<date>.md
with a one-line pointer left behind. The move is a verbatim cut and paste, so
the session pays to read the section and then pays again, in output tokens,
to reproduce it -- and `plans/archive/**` is denied to the file tools, so the
reproduction goes through a Bash heredoc, which breaks past about forty
lines. Build tools/archive_slice.py <id>: resolve `Plan:` and `Heading:`
from master's queue, cut the section using `heading.py`'s existing boundary
logic (export it rather than copying it), write the archive file, leave the
pointer. It must refuse to run on a dirty working tree, so that `git checkout
--` always undoes it; a bad move destroys a plan section otherwise.
*Non-goals:* it does not commit, does not touch `NEXTSTEPS.md` (L-11), and
does not change `finish` (L-13).
*Acceptance:* a test builds a fixture plan of two sections, runs the tool for
the first id, and asserts the archive file holds that section verbatim, the
live plan keeps exactly a one-line pointer where the heading was, the second
section is unchanged byte-for-byte, and a dirty tree exits non-zero.
- Proof: `absent: tools/slice.ps1 :: archive_slice`
- Next after: L-11 -- the delivered item leaves its lane without being retyped.

**L-11 -- the delivered item leaves its lane without being retyped.**
The other half of the same retry loop: deleting the delivered item from its
lane and renumbering the survivors is Markdown editing with no judgment in it
at all. Build tools/refill_lane.py --delete <id>: remove the item from its
own lane, renumber that lane from 1, and leave the other lane's bytes
identical -- the two lanes are separate subsections precisely so two merges
stay clean, and a tool that reflows both would undo that. Run `check_docs.py`'s
queue checks over the result before writing, and refuse rather than write a
queue that would fail verification.
*Non-goals:* it does not add the successor -- that is prose judgment until
L-12 exists -- and it does not touch `## Not in the queue, and why`.
*Acceptance:* a test over a two-lane fixture asserts the delivered id is
gone, the lane is renumbered contiguously from 1, the other lane is unchanged
byte-for-byte, and `check_docs.py` passes on the result; a fixture whose
deletion would drop the whole queue below three exits non-zero instead.
- Proof: `absent: tools/slice.ps1 :: refill_lane`
- Next after: L-13 -- closeout is one command.

**L-12 -- a plan's slice section carries the queue lines it is refilled from.**
*Gated: see the dependency note above.* Adding the successor means reading its
plan section and hand-writing five queue lines from prose, which is where the
refill gate usually stops a closeout. Give each open slice section in
`plans/now/**` a fenced block holding the exact `Plan:`, `Files:`, `Check:`,
`Proof:` and `Next after:` lines it would be queued with; teach
`check_docs.py` to prove the block and any live queue entry for that id agree;
teach `refill_lane.py --add <id>` to copy the block in. The second prize is
larger than the refill saving: a `Proof:` line written and validated when the
plan is written is one that cannot be improvised at closeout.
**This does not change `NEXTSTEPS.md`'s item schema.** The block lives in plan
files; the queue's own format, and the two regexes that parse it, are
untouched. That is the distinction this plan's standing rule below draws --
extend the parsers, never the formats.
*Risk to design against:* a refill that copies a stale block queues work that
no longer needs doing, which is the X3 failure again. `--add` must re-run the
proof check and refuse an item whose `Proof:` no longer holds.
*Acceptance:* `check_docs.py` fails a fixture whose block and queue entry
disagree and passes when they match; `--add` reproduces an existing queue
entry byte-for-byte from its plan's block; `--add` exits non-zero on a slice
whose proof no longer holds.
- Proof: `absent: tools/check_docs.py :: check_plan_queue_blocks`
- Next after: L-13 -- closeout is one command.

**L-13 -- closeout is one command: the gates become actions.**
With L-10 and L-11 merged, fold them into `finish` so that the archive move
and the lane deletion happen rather than being demanded. Add one journal
phase that runs both tools and commits, ordered before the existing
`archived` and `refilled` gates -- the gates stay, as the proof that the
action worked and as the path for a branch merged by hand.
*The hazard is the journal, not the tools.* `Test-ClosingPhaseDone` compares
positions in `$script:ClosingPhaseOrder`, so a new phase inserted in the
middle changes what a journal written by the previous version means on
resume. Decide explicitly what an in-flight journal from the old order does,
and cover it: an interrupted closeout that resumes into a different phase
order is exactly the class of defect L-5 and L-6 were built to stop.
*Acceptance:* every injected-failure phase in `tests/test_slice_lifecycle.py`
and `tests/test_two_lane_closeout.py` still resumes to a clean merge on
master; a closeout over the fixture repository completes from `verify` to
`merge` with no hand edit in between; a journal written in the old phase order
resumes without skipping a durable step.
- Proof: `absent: tools/slice.ps1 :: Invoke-SliceArchiveAndRefill`
- Next after: none -- agent-lifecycle is complete.

**Do not change** `plans/workstreams.md`'s format or `NEXTSTEPS.md`'s item
schema in this plan. Both are parsed by `tools/slice.ps1` and
`tools/check_docs.py` with regular expressions that have each been fixed
twice; a format change turns into a silent parse failure. Extend the parsers,
never the formats.

**Read for any slice here:** this plan's own section and nothing else. F1 to
F12 in the review are the evidence and do not need rereading to implement.

Shipped, one pointer each -- the full specification and outcome of every one
is in its archive record, and none of them needs rereading to work on L-10 to
L-13:

- L-1, the lifecycle suite is green and runs in verification (12 Sep) --
  `plans/archive/AGENT_LIFECYCLE_L1_2026-09-12.md`.
- L-2, every outcome classified and every closeout phase injectable (12 Sep);
  its classify baseline does not agree with the review's Part 1 figures
  within 10%, left as a follow-up -- `plans/archive/L-2_2026-09-12.md`.
- L-3, branch and primary verification are separate scopes (13 Sep) --
  `plans/archive/L-3_2026-09-13.md`.
- L-4, the worktree is deleted outside the lock, survivors queued (14 Sep) --
  `plans/archive/L-4_2026-09-14.md`.
- L-5, closeout is one transaction: phase journal, one push, archive and
  refill committed on the branch before merge (14 Sep) --
  `plans/archive/L-5_2026-09-14.md`.
- L-6, the concurrency contract as `TwoLaneCloseoutTest` (14 Sep); it found
  that nothing refused an uncommitted edit to a coordination file in the
  primary checkout before merging -- `plans/archive/L-6_2026-09-14.md`.
- L-7, the queue cannot contradict itself (14 Sep) --
  `plans/archive/L-7_2026-09-14.md`.
- L-8, a Godot failure names which of five things broke (17 Sep) --
  `plans/archive/L-8_2026-09-17.md`.
- L-9, the floor is measured and split, and this plan is gated (17 Sep) --
  `plans/archive/L-9_2026-09-17.md`.
