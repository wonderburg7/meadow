# Agent lifecycle — make closeout survive interruption and two lanes

<!-- CONTEXT: plan | LAYER: immediate-task -->

Status: active | Owner: Dave / Claude | Next: L-6 -- two lanes closing out at once is a test, not a hope | Dependency: none | Verified: 2026-09-14

## Objective

`tools/slice.ps1 finish` fails often enough that retrying it is normal, and
every failure after its first push leaves work merged with cleanup
outstanding. Make closeout a transaction that is safe to interrupt and safe
to re-run, prove it under two concurrent lanes, and measure the result.

The second objective is cost, and it is the larger one. Writing code is 25.6%
of a session's context spend; 47.1% falls after the last product edit, in
closeout and document curation, and a further 17.4% goes to sessions that
make no product edit at all. **Target: raise the implementing share above
40%**, measured the same way at L-9. Nothing in this plan may buy that by
removing a check.

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

## Open slices

| Slice | Outcome | Owns | Startable | Reasoning |
| --- | --- | --- | --- | --- |
| L-6 | two lanes closing out at once is a test, not a hope | `tests/test_source_checks.py` | yes | high |
| L-7 | the queue cannot contradict itself | `tools/check_docs.py` | yes | low |
| L-8 | a Godot failure names which of five things broke | `tools/slice.ps1`, `docs/headless-run-contract.md` | yes | medium |
| L-9 | the floor and the phase split are measured, and gate this plan | `tools/session_cost.py`, this plan | yes | medium |

Dependencies, stated rather than implied: L-1 was the prerequisite for
everything else, because nothing else in this plan could be trusted while
its tests did not run -- it shipped 12 September 2026 (archived at
`plans/archive/AGENT_LIFECYCLE_L1_2026-09-12.md`), so L-2, L-3, L-7 and L-8
became startable; L-2 and L-3 have since shipped too (archived at
`plans/archive/L-2_2026-09-12.md` and `plans/archive/L-3_2026-09-13.md`).
L-4 shipped 14 September 2026 (archived at
`plans/archive/L-4_2026-09-14.md`), and L-5 shipped the same day (archived at
`plans/archive/L-5_2026-09-14.md`), so L-6 is now startable -- it tests the
transaction L-5 just built. L-9 is last and is the gate.

**Do not change** `plans/workstreams.md`'s format or `NEXTSTEPS.md`'s item
schema in this plan. Both are parsed by `tools/slice.ps1` and
`tools/check_docs.py` with regular expressions that have each been fixed
twice; a format change turns into a silent parse failure. Extend the parsers,
never the formats.

**Read for any slice here:** this plan's own section and nothing else. F1 to
F12 in the review are the evidence and do not need rereading to implement.

This file exceeds the 260-line soft limit and holds no delivered slice. Nine
slices each carry an algorithm specific enough to implement without a design
decision, which is the point; the length is the specification, not history.
It shortens as slices ship and their specifications move to the archive.

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

## L-6 — two lanes closing out at once is a test

**Objective.** State the concurrency contract as a test, over the five cases
that actually happened.

**Non-goals.** Do not remove the lifecycle lock. Do not make the lanes share
a worktree.

**Files.** `tests/test_source_checks.py`.

**Prerequisite.** L-5.

**Algorithm.** One test class, five tests, each building a fixture with a
queue holding one `[Claude]` and one `[Codex]` item that share no file:

1. `test_two_lanes_close_out_independently` — claim both, finish both in
   sequence, assert both merged, both worktrees gone, both rows gone, the
   queue refilled twice.
2. Simultaneous claims: run two `start` calls concurrently; assert exactly
   one wins the lock and the other exits non-zero with the busy message, and
   that re-running the loser then succeeds.
3. One lane finishing while the other works: claim both, finish one, assert
   the other's worktree, branch and row are untouched and its `finish` then
   succeeds with no rebase.
4. Remote ahead: push an unrelated commit to the bare remote, then finish;
   assert closeout either integrates it or fails with a message naming the
   remote state, and never leaves a half-pushed transaction.
5. Dirty coordination files, and the conflict Dave's 12 Sep decision
   allows: leave uncommitted edits in `plans/workstreams.md` in the primary
   checkout, then finish, and assert the transaction refuses before the merge
   with a message naming the file. Then have both lanes refill
   `NEXTSTEPS.md` on their own branches and merge in sequence; assert the
   second merge either succeeds or fails naming the queue, and never leaves a
   half-pushed transaction.
6. Retry after a push succeeded and cleanup failed: inject failure after
   `pushed`, assert `resume` completes and the end state matches an
   uninterrupted run.

**Tests and failure injection.** The slice is the test. Every case that fails
on first run is a real defect and is fixed in this slice or, if it changes
the transaction's design, escalated per `plans/README.md` rule 8.

**Proof.** `absent: tests/test_source_checks.py :: def test_two_lanes_close_out_independently`

**Risk.** High to discover, low to land: it adds no production code unless a
case fails.

**Expected improvement.** The 10 lifecycle-busy collisions and the 5 queue
drift refusals become a covered contract rather than a surprise.

**Next slice.** L-7.

## L-7 — the queue cannot contradict itself

**Objective.** `NEXTSTEPS.md` currently lists `UI-U-1` as ready and also
explains that it is not startable. Make that a verification failure.

**Non-goals.** Do not change the queue's schema or its size bounds. Do not
promote the existing cross-lane file-overlap warning in this slice.

**Files.** `tools/check_docs.py`.

**Prerequisite.** L-1.

**Algorithm.**

1. Add `check_queue_section_agreement(errors)`. Parse the ids in `## Next up`
   with the existing item parser. Parse the `## Not in the queue, and why`
   section's bolded entry names. An id appearing in both is an error naming
   the id and both sections.
2. Match on the bolded lead of each bullet, not the whole paragraph: the
   prose legitimately mentions other ids as reasons.
3. Register the check in the same list as the other queue checks so it runs
   in `verify.ps1`'s doc stage.
4. Fix the live contradiction in the same commit: `UI-U-1` is either ready or
   it is not. The queue holds it as the Codex lane's leading item, so remove
   its "not in the queue" bullet and correct the paragraph that names `A1` as
   filling a slot `A2` occupies.

**Tests and failure injection.** Add
`test_an_id_in_both_queue_sections_is_rejected` in the existing
`QueueSchemaChecksTest`, with a fixture naming one id in both sections.

**Proof.** `absent: tools/check_docs.py :: def check_queue_section_agreement`

**Risk.** Low.

**Expected improvement.** The stale-queue class that the 3 September review
ranked critical, and that recurred 9 days later, becomes enforced rather than
described.

**Next slice.** L-8.

## L-8 — a Godot failure names which of five things broke

**Objective.** Distinguish MCP unavailable, editor unavailable, baseline
environment crash, scenario failure and product failure. Today all five share
one exit path, and one of them is a false alarm about the game.

**Non-goals.** Do not fix the Windows headless access violation. Do not
change any scenario or assertion. This slice only classifies.

**Files.** `tools/slice.ps1`, `docs/headless-run-contract.md`.

**Prerequisite.** L-1.

**Algorithm.**

1. Add `Get-GodotCapability` to `slice.ps1`, returning one of five states
   with a one-line reason: `mcp_unavailable` (the configured MCP command
   cannot be resolved), `editor_unavailable` (no executable found on PATH, in
   `GODOT_PATH`, or in `.codex/config.toml` — the check
   `Get-ConfiguredGodotPath` already performs), `environment_crash` (the
   executable runs but a minimal `--headless --quit` exits non-zero or with
   an access violation), `import_cache_missing` (the repository has no
   `.godot` directory, which makes a fresh worktree's run fail to compile and
   misreport as a gameplay collapse), and `ready`.
2. Call it from `doctor` and report it as `godot_capability`. Do not make
   anything but `editor_unavailable` a doctor failure — it is the only one
   that already is.
3. In `docs/headless-run-contract.md`, replace the current triage prose with
   the five state names and what each means for the reader. Delete whatever
   the five states now make redundant; do not add a section alongside it.

**Tests and failure injection.** Add
`test_godot_capability_names_each_failure_state`, driving all five: an
unresolvable MCP command, a missing executable, an executable that exits
non-zero, a fixture with no `.godot`, and the real configuration.

**Proof.** `absent: tools/slice.ps1 :: function Get-GodotCapability`

**Risk.** Medium. A wrong classification is worse than none, so each state
needs its own test.

**Expected improvement.** 36 failed headless runs stop starting their triage
from scratch, and the import-cache false alarm is named on sight.

**Next slice.** L-9.

## L-9 — the floor is measured and split, and this plan is gated

**Objective.** W-2 targeted a session-opening floor of 45,000 tokens, never
measured itself, and the floor is 77,322 today. Make the measurement separate
what the repository owns from what it does not, add the phase split F13
reports so the plan's cost target is checkable, then gate this plan on both.

**Non-goals.** Do not add or remove any deny rule in
`.claude/settings.json`. This slice measures; a later slice may act.

**Files.** `tools/session_cost.py`, this plan.

**Prerequisite.** L-5, so that the routing fixes and the transaction are both
in place before the after-measurement is taken.

**Algorithm.**

0. Add `--phases` to `session_cost.py`, printing the four-row table F13
   reports: requests, context and share for the phases before the first
   product edit, between the first and last, after the last, and for sessions
   with no product edit. Bound the phases by edits to `scripts/`, `scenes/`,
   `shaders/`, `tests/`, `tools/` and `test_scenarios/`, and reproduce F13's
   figures for 4 to 12 September 2026 within 10% before trusting it.
1. In `session_cost.py`, split the session-opening context into two figures:
   `repository context`, the tokens attributable to reads of files under the
   repository root in the session's first request, and `host context`, the
   remainder — system prompt, tool schemas, MCP server definitions, plugin
   and skill listings.
2. Print both, with the total, under `--days N`. Keep the existing
   single-figure line so nothing that parses the output breaks.
3. Record here, in a three-row table: the 3 September before, today's
   77,322 split into its two parts, and the after.

**Completion gate.** This plan is not complete, and its `Next:` does not
read `None — plan complete`, until all four hold:

1. `python tools/session_cost.py --days 1` has been run in a session opened
   after L-5 merged, and both the before and after figures are recorded in
   the table above.
2. `python tools/session_cost.py --days 7 --classify` shows zero
   `lifecycle_failure` outcomes across that window.
3. One real product slice — not a fixture — has been claimed, implemented and
   closed out end to end by each lane, in a session opened after the
   configuration changes, with a single `finish` call and no manual repair.
   Name both canary slices here.
4. The phase split has been re-measured over the sessions since L-5 merged,
   the same way F13 measured it, and the implementing share is above 40%.
   Record the four phase figures beside F13's. A share that has not moved
   means the queue and document work went somewhere else rather than away.

**Proof.** `absent: tools/session_cost.py :: host context`

**Risk.** Medium. The attribution in step 1 is a heuristic; state its rule in
the code so a later reader can judge it.

**Expected improvement.** W-2's failure mode — a target set against a number
the repository could not move, and never checked — cannot repeat.

**Next slice.** None. L-9 is the gate; when it passes, this plan is complete
and moves to `plans/archive/`.
