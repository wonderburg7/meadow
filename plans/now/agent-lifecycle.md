# Agent lifecycle — make closeout survive interruption and two lanes

<!-- CONTEXT: plan | LAYER: immediate-task -->

Status: active | Owner: Dave / Claude | Next: L-13 -- closeout is one command, and the gates become actions | Dependency: none -- L-10 and L-11 landed 18 Sep 2026 | Verified: 2026-09-18

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

L-1 to L-11 have shipped (one pointer each under "Standing rules" below);
closeout is a journaled transaction whose `archived` and `refilled` phases
are performed by `tools/archive_slice.py` and `tools/refill_lane.py`
(L-10, L-11); L-12 and L-13 turn what is still typed by hand into actions. The
instruments those slices aim at landed on 17 Sep 2026: the stops ledger
(`session_cost.py --stops`), `--no-edit-reasons`, `tools/new_check.py` and
the allow-listed read-only commands in `.claude/settings.json`. The
completion gate stands at 39 `lifecycle_failure` outcomes in the seven days
to 17 Sep against a required zero, no canary slice named per lane, and the
implementing share below 40% on every window measured; only the
measurement-ran-once condition is met. The measured evidence is
`docs/agent-workflow-review-2026-09-12.md`, not this section.

## Open slices

`finish` has gates, not actions. Its `archived` and `refilled` phases check
that the two closeout edits were made -- since 18 Sep 2026 by
`tools/archive_slice.py` and `tools/refill_lane.py`, which the stop blocks
name -- print a stop block when they have not, and make the session retry.
L-13 folds the two tools into `finish` itself, so the gates become proof
rather than instruction; that is what the 41-47% closeout share is mostly
made of.

| Slice | What it does | Files it owns | Level |
| --- | --- | --- | --- |
| L-12 | A plan's slice section carries the queue lines it is refilled from | `tools/check_docs.py`, `plans/now/*.md` | high |
| L-13 | Closeout is one command, and the gates become actions | `tools/slice.ps1`, `tests/test_two_lane_closeout.py` | high |

Dependencies, stated rather than implied: L-10 and L-11 have shipped, so
L-13, their integration, is startable. **L-12 is deliberately gated** -- do not start it until
`python tools/session_cost.py --stops` shows the refill step among the two
most frequent stops over at least ten recorded stops. It is the only slice
here that touches every live plan, and the instrument that would justify it
only started recording on 17 Sep 2026. Neither may be bought by removing a check.

L-10 shipped 2026-09-18; its specification is `plans/archive/L-10_2026-09-18.md`.

L-11 shipped 2026-09-18; its specification is `plans/archive/L-11_2026-09-18.md`.

### L-12 — a plan's slice section carries the queue lines it is refilled from

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
Level: high
- Proof: `absent: tools/check_docs.py :: check_plan_queue_blocks`
- Next after: L-13 -- closeout is one command.

### L-13 — closeout is one command, and the gates become actions

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
Level: high
- Proof: `absent: tools/slice.ps1 :: Invoke-SliceArchiveAndRefill`
- Next after: none -- agent-lifecycle is complete.

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
F12 in the review are the evidence and do not need rereading to implement.

Shipped, one pointer each -- the full specification and outcome of every one
is in its archive record, and none of them needs rereading to work on L-12 or
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
- L-10, `tools/archive_slice.py` moves a closing slice's plan section to the
  archive (18 Sep) -- `plans/archive/L-10_2026-09-18.md`.
- L-11, `tools/refill_lane.py --delete` removes a queue item and renumbers
  its lane (18 Sep) -- `plans/archive/L-11_2026-09-18.md`.
