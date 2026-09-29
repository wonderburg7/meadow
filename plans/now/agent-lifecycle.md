# Agent lifecycle — make closeout survive interruption and two lanes

<!-- CONTEXT: plan | LAYER: immediate-task -->

Status: active | Owner: Dave / Claude | Next: no open slice -- L-15 shipped 29 Sep 2026; what remains is the completion gate in "Objective" (zero `lifecycle_failure` outcomes over seven days, a canary slice named per lane, the implementing share above 40%), measured with `python tools/session_cost.py --stops` and `--phases` from 6 Oct 2026; if `--stops` still shows lock waits long enough to matter, narrowing the lock to the shared-state phases (the "Not in scope" note in L-15's archive record) is the next slice | Dependency: none | Verified: 2026-09-29

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

`finish`'s `archived` and `refilled` phases became actions with L-13
(18-19 Sep 2026) and L-12 closed the last hand-written step on 21 Sep 2026: a
lane now refills itself from the ```queue blocks in the plans, so the five
lines a session used to write out of prose at closeout are a copy. L-15 was
added 25 Sep 2026 from two triaged system-improvement signals, both about
the two lanes blocking each other.

| Slice | What it does | Files it owns | Level |
| --- | --- | --- | --- |
| L-15 | A busy lifecycle lock is waited for, not refused; an open-worktree stop says whether that branch is finished | `tools/slice.ps1`, `tests/test_two_lane_closeout.py`, `tests/test_slice_lifecycle.py` | high |

### L-15 — the other lane's lifecycle command waits for the lock, and an open-worktree stop says what to do

**Why.** Promoted from `plans/observations/system-improvement-signals.md`
(25 Sep "a finish holds the lifecycle lock through verification" and 20 Sep
"a finished-but-unmerged worktree blocks its lane's next claim"). 49 of 118
recorded stops are `slice lifecycle is busy`, 39 of them `finish` retried
roughly once a minute over three hours on 23 Sep; 14 are `<lane> lane
already has an open worktree`, 5 of them since the 20 Sep signal.

**True now.** `Invoke-WithLifecycleLock` opens
`meadow-slice-lifecycle.lock` with `FileShare.None` and, if that fails,
throws `slice lifecycle is busy` at once. It wraps the whole of `start`,
`finish`, `resume` and `abort`, so a `finish` holds it through branch and
primary `tools/verify.ps1` (lifecycle tests: median 231 s). The refusal
names neither the holder nor the slice. L-6's `TwoLaneCloseoutTest`
asserts that the loser of a race sees this refusal
(`tests/test_two_lane_closeout.py`, "slice lifecycle is busy"). Separately,
`Invoke-SliceStart` throws `<lane> lane already has an open worktree (...)
-- finish or abandon it first` with no word on which of the two applies.

**True when done.**

1. A lifecycle command that finds the lock held waits for it, re-trying
   about every 5 s, for at most 10 minutes (a script parameter, so tests can
   set it to seconds). It prints one line when it starts waiting, naming
   the holder's command and slice id and when it took the lock, and stays
   silent while it waits. The holder writes that line into the lock file,
   which is opened for others to read but not write. Past the bound, the
   existing refusal is thrown, now naming the holder, and the stop ledger
   row records it. Runtime policy: the polling runs only while a lifecycle
   command is blocked, never otherwise.
2. The open-worktree stop adds whether the blocking branch has commits
   ahead of master and whether its worktree has uncommitted changes, and
   says which applies: "finish it (`tools/slice.ps1 finish` from inside
   `<worktree>`)" if it is ahead and clean, otherwise "abandon it or finish
   the work in it". It does not run verification to decide.
3. `TwoLaneCloseoutTest`'s race is changed on purpose: the loser now waits
   and then completes. A new case with a near-zero bound keeps the refusal
   covered. `tests/test_slice_lifecycle.py` covers the new open-worktree
   wording for an ahead-and-clean and for a dirty worktree.

**Not in scope.** Narrowing the lock to the shared-state phases (merge,
archive, refill, ledger) so verification runs outside it. That is the larger
fix and changes L-5's transaction ordering; take it only if, after L-15,
`--stops` still shows waits long enough to matter.

**Read:** this section and `Invoke-WithLifecycleLock`, `Invoke-SliceStart`
in `tools/slice.ps1` (by `grep -n "^function"`), and the race test in
`tests/test_two_lane_closeout.py`.

```queue
**[Claude] L-15 -- a busy lifecycle lock is waited for, not refused, and an open-worktree stop says what to do**
- Plan: `plans/now/agent-lifecycle.md` -- "L-15 — the other lane's lifecycle command waits for the lock, and an open-worktree stop says what to do"
- Files: `tools/slice.ps1`, `tests/test_two_lane_closeout.py`, `tests/test_slice_lifecycle.py`
- Check: a second `finish` started while another holds the lock prints one waiting line naming the holder and completes after it, `start` against an open worktree says whether to finish or abandon it, and `tools/verify.ps1` is green
- Proof: `present: tools/slice.ps1 :: slice lifecycle is busy; retry this command`
- Next after: none -- agent-lifecycle is complete once L-15 ships and the Objective's completion gate is met
```

**L-12 shipped ahead of its gate.** It was held until
`python tools/session_cost.py --stops` ranked the refill step among the two
most frequent stops, because the measurement was the only thing that could
justify touching every live plan. Dave asked for the lane refill directly on
21 Sep 2026, which settles the question the gate existed to answer; the gate
is not weakened for anything else, and nothing here was bought by removing a
check. What the ranking would have told us is still worth reading once ST-1
makes `--stops` legible.

L-10 shipped 2026-09-18; its specification is `plans/archive/L-10_2026-09-18.md`.

L-11 shipped 2026-09-18; its specification is `plans/archive/L-11_2026-09-18.md`.

L-14 shipped 2026-09-20; its specification is `plans/archive/L-14_2026-09-20.md`.

L-12 shipped 2026-09-21; its specification is `plans/archive/L-12_2026-09-21.md`.

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
