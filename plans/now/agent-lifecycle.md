# Agent lifecycle — make closeout survive interruption and two lanes

<!-- CONTEXT: plan | LAYER: immediate-task -->

Status: active | Owner: Dave / Claude | Next: L-3 -- branch verification and bookkeeping validation are separate scopes | Dependency: none | Verified: 2026-09-12

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
  merge, a push, up to 180 seconds of Windows deletion retries, and a second
  push. Archival and queue refill are manual, outside the lock, by design.
- `tests/test_source_checks.py` holds the only tests of any of this. It has
  27 tests, 3 red on `master`, and `tools/verify.ps1` does not run it.
- The four small fixes of 12 September 2026 landed on `claude/WF-1`: Codex
  may run `resume`; declared actions are single unchained commands; `start`
  and `doctor` print a `read` command and `next_after`; `doctor` reports
  whether the global Git excludes file is readable.

## Open slices

| Slice | Outcome | Owns | Startable | Reasoning |
| --- | --- | --- | --- | --- |
| L-1 | the lifecycle suite is green and runs in verification | `tests/test_source_checks.py`, `tools/verify.ps1` | yes | medium |
| L-2 | one command classifies every session outcome, and every closeout phase has an injected-failure test | `tools/session_cost.py`, `tests/test_source_checks.py` | after L-1 | medium |
| L-3 | branch verification and primary-checkout validation are separate scopes | `tools/verify.ps1`, `tools/slice.ps1` | after L-1 | medium |
| L-4 | the worktree is deleted out of process, with no retry loop inside the lock | `tools/slice.ps1` | after L-3 | high |
| L-5 | closeout is an idempotent resumable transaction that refills the queue | `tools/slice.ps1`, `tools/check_docs.py`, `CHATGPT.md` | after L-4 | high |
| L-6 | two lanes closing out at once is a test, not a hope | `tests/test_source_checks.py` | after L-5 | high |
| L-7 | the queue cannot contradict itself | `tools/check_docs.py` | after L-1 | low |
| L-8 | a Godot failure names which of five things broke | `tools/slice.ps1`, `docs/headless-run-contract.md` | after L-1 | medium |
| L-9 | the floor and the phase split are measured, and gate this plan | `tools/session_cost.py`, this plan | after L-5 | medium |

Dependencies, stated rather than implied: L-1 is the prerequisite for
everything, because nothing else in this plan can be trusted while its tests
do not run. L-3 must precede L-4 and L-5, because both change what runs
inside the lock. L-4 must precede L-5, because the transaction cannot be
short-lived while a three-minute retry sits inside it. L-6 must follow L-5,
because it tests the transaction. L-2, L-7 and L-8 need only L-1 and may be
taken in any order relative to L-3 to L-6. L-9 is last and is the gate.

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

## L-1 — the lifecycle suite is green and runs in verification

**Objective.** Fix the three failing tests in `tests/test_source_checks.py`,
then add that file to `tools/verify.ps1` so it can never silently rot again.

**Non-goals.** Do not change `slice.ps1`'s behaviour. Do not add the other 14
`tests/test_*.py` files to verification; several drive Godot and belong to a
later decision.

**Files.** `tests/test_source_checks.py`, `tools/verify.ps1`. Read
`scripts/debug_panel.gd` to find the renamed function; do not edit it --
`UI-U-1` in the Codex lane owns it.

**Prerequisite.** None.

**Algorithm.**

1. `test_mock_slice_can_claim_commit_and_close` fails at "could not
   regenerate checks/ready.md". In that test's `setUp`, create
   `checks/ready` as a directory and write `checks/ready.md` with the header
   `check_docs.py --write-ready-index` expects, before the fixture commit.
   Run `python tools/check_docs.py --write-ready-index` once in the real
   repository to see the exact header it writes, and copy that shape.
2. `test_doctor_reports_all_environment_failures_together` asserts `Python:`
   is in stderr, but a `git ls-remote` failure now reaches stderr first. The
   test's intent is that all environment failures are reported together, so
   assert each expected prefix is present with `assertIn`, in no particular
   order, rather than relying on which came first.
3. `test_orientation_flight_and_scouting_are_symmetric_alternatives` raises
   `IndexError` because `scripts/debug_panel.gd` no longer contains
   `_cascade_prerequisites_on_static`. Find the function that now performs
   the prerequisite cascade by grepping `debug_panel.gd` for `prerequisite`,
   and split on its name. If no such function remains, the contract has moved
   and the test must be deleted with a one-line comment saying where the
   behaviour went — do not weaken it to pass.
4. In `tools/verify.ps1`, add a third `Start-Job` alongside "source checks"
   and "balance tests", named "lifecycle tests", running
   `& $interpreter -m unittest tests.test_source_checks`. Follow the two
   existing jobs exactly, including the `$LASTEXITCODE` throw.

**Tests and failure injection.** All 27 tests pass. Then break `slice.ps1` on
purpose — delete the `throw` after `git merge` — and confirm
`tools/verify.ps1` exits non-zero and names "lifecycle tests". Restore it.

**Proof.** `absent: tools/verify.ps1 :: test_source_checks`

**Risk.** Medium. It turns a currently-green gate red for anyone whose tree
has an unrelated lifecycle regression, which is the point.

**Expected improvement.** The 3 red tests become 0, and any future change to
`slice.ps1`, the Codex permission profile or the verifier's Python
resolution fails verification instead of shipping.

**Next slice.** L-2.

**L-2 — every outcome is classified, every closeout phase is injected.**
Landed 2026-09-12. `classify_outcome` and `--classify` shipped in
`tools/session_cost.py`; all seven injected closeout phases resume cleanly
with the merge landing on master. The classify baseline does not agree with
the review's Part 1 figures within 10% -- see
`plans/archive/L-2_2026-09-12.md` for the numbers and why that is left as a
follow-up rather than force-fit here.

## L-3 — branch verification and bookkeeping validation are separate scopes

**Objective.** A branch's verification must not fail because of the other
lane's leftover state.

**Non-goals.** Do not delete any check. Every check that runs today still
runs; only where it runs changes.

**Files.** `tools/verify.ps1`, `tools/slice.ps1`.

**Prerequisite.** L-1.

**Algorithm.**

1. Add `-Scope` to `verify.ps1`, a `ValidateSet` of `branch`, `primary` and
   `all`, defaulting to `all` so every existing caller is unchanged.
2. `branch` runs source checks, balance tests, the function map, the stage
   reference and the lifecycle tests. `primary` runs `check_docs.py` only.
   `all` runs both, in the present order and with the present output.
3. In `check_docs.py`, nothing changes. The split is entirely in the caller.
4. In `Invoke-SliceFinish`, call `verify.ps1 -Scope branch` from the worktree
   where it calls `verify.ps1` today. After `Set-Location` to the primary
   root and before the merge, call `verify.ps1 -Scope primary` there. Its
   failure message must say which scope failed and that the branch is
   untouched.

**Tests and failure injection.** In `tests/test_source_checks.py`, add
`test_branch_verification_ignores_another_lanes_stale_ledger_row`: build the
fixture, add a ledger row naming a worktree that does not exist, and assert
`verify.ps1 -Scope branch` in the worktree exits zero while
`verify.ps1 -Scope primary` in the primary checkout exits non-zero.

**Proof.** `absent: tools/verify.ps1 :: -Scope`

**Risk.** Medium. Every caller of `verify.ps1` is affected if the default
changes; it must not.

**Expected improvement.** The 10 `finish` calls that died inside
verification, and the 2 sessions that never recovered, become 0 for causes
belonging to the other lane.

**Next slice.** L-4.

## L-4 — the worktree is deleted out of process, outside the lock

**Objective.** Remove the 60-attempt, 3-second retry loop from inside the
lifecycle lock. Deletion happens after the process holding the directory has
exited.

**Non-goals.** Do not try to identify or kill whatever holds the directory
beyond the existing `Godot*` stop. Do not leave a registered worktree behind:
git's own bookkeeping must be correct even when the directory survives.

**Files.** `tools/slice.ps1`.

**Prerequisite.** L-3.

**Algorithm.**

1. In `Invoke-SliceFinish`, replace the retry loop with: `git worktree
   remove` once; if the directory still exists, `git worktree prune` so git's
   records are correct, then write the path into a queue file
   a queue file beside the lifecycle lock, named meadow-slice-pending-deletions (one path per line, appended, no
   duplicates) and continue. Closeout does not fail because a directory
   survived.
2. Add a `Remove-PendingWorktreeDirectories` function, called at the start of
   every `start`, `finish`, `resume` and `doctor`, before the lock is taken.
   It reads the queue file, tries `Remove-Item -Recurse -Force` on each path
   once, and rewrites the file with only the paths that still exist.
3. `doctor` reports the queue as a `pending_deletions` array so a surviving
   directory is visible rather than silent.
4. `check_docs.py`'s orphan-directory check must not fail on a directory
   listed in the queue file. Read the queue file, skip those paths, and say
   so in the check's message.

**Tests and failure injection.** Add
`test_finish_completes_when_the_worktree_directory_cannot_be_deleted`: hold
an open file handle inside the fixture worktree, run `finish`, assert it
exits zero, assert the branch merged and the ledger row is gone, assert the
path is in the queue file, and assert `check_docs.py` passes. Then release
the handle, run `doctor`, and assert the directory is gone and the queue file
is empty.

**Proof.** `present: tools/slice.ps1 :: $maxAttempts = 60`

**Risk.** High. It changes what "closeout succeeded" means. The invariant to
hold: git's worktree registry and the ledger are always correct; only the
directory may lag.

**Expected improvement.** 13 deletion failures in 11 sessions, up to 180
seconds each inside the lock, become 0 failures and no lock time.

**Next slice.** L-5.

## L-5 — closeout is an idempotent resumable transaction

**Objective.** One closeout, one recorded phase journal, one push, and the
queue refilled and the specification archived inside the transaction.

**Non-goals.** Do not change the queue's item schema or the ledger's row
format. Do not decide where the refill is committed — see the decision below.

**Files.** `tools/slice.ps1`, `tools/check_docs.py`, `CHATGPT.md`.

**Prerequisite.** L-4. The ownership question is settled: Dave, 12 Sep 2026 --
**the refill is committed in the slice's worktree, so it travels into
`master` inside the merge commit.** One push, one atomic state, and a failed
closeout leaves `master` untouched. Two consequences this slice carries:
`CHATGPT.md`'s "never on the branch" rule is deleted in the same commit, and
two lanes refilling at once can conflict in `NEXTSTEPS.md`, which L-6 case 3
must then cover.

**Algorithm.**

1. Write a phase journal at a closeout journal beside the lifecycle lock in the shared git directory, named meadow-slice-closeout.json holding `id`,
   `branch`, `lane` and the last completed phase, using the phase names the
   injection hook already uses. Write it after each phase. Delete it when the
   transaction completes.
2. On entry, if a journal exists for this branch, skip every phase up to and
   including the recorded one. Each phase must be individually idempotent:
   the merge checks whether it has already landed with
   `Test-SliceBranchMerged`; the ledger edit already tolerates an absent row;
   the branch deletion already checks the ref exists.
3. Add the two manual steps as phases, on the branch, before the merge, so
   both land inside the merge commit. `archived`: move the delivered slice's
   specification out of its `plans/now/` file into the archive, as
   ID_date.md, leaving the one-line pointer `plans/README.md` requires.
   `refilled`: remove the delivered item from `## Next up` and promote the
   item its `Next after:` names; if `Next after:` says
   `none -- <plan> is complete`, do not promote, and print that the lane
   needs a new item. Commit both onto the slice branch, then merge. Delete
   `CHATGPT.md`'s rule that the queue is updated on `master` and never on the
   branch, and `CLAUDE.md`'s matching sentence if it disagrees.
4. Push once, after `refilled`, with every commit the transaction made.
   Remove the second and third pushes.
5. If any phase throws, print the journal's phase and the exact recovery
   command, which is `tools/slice.ps1 resume -Lane <lane>`.
6. Fill the whole end-of-slice report rather than three quarters of it. The
   `Next slice`, `Other lane` and `Start it with` lines were left for the
   session to derive by hand because deriving them needed the owning plan;
   `next_after` is now parsed and the successor has just been promoted, so
   all three are lookups. Print the branch diffstat the merge produced in the
   same block. Between them these are what 639 hand-run `git` calls after the
   last product edit were reconstructing.

**Tests and failure injection.** Extend L-2's injected-phase test to the two
new phases and assert `resume` completes them. Add
`test_closeout_pushes_exactly_once`, counting pushes with a local bare remote
and its reflog. Add `test_refill_promotes_the_named_successor`, asserting the
queue is one item shorter, the successor is present, and the specification
moved.

**Proof.** `present: tools/slice.ps1 :: queue not refilled by 'finish'`

**Risk.** High. Save-and-schema class: it writes the queue and moves plan
files. Every step is a file move or a text edit with a test.

**Expected improvement.** 43 surplus `finish` calls and 10 never-finished
sessions become 0 retries from partial state. 8 of Dave's 18 mid-session
questions disappear, because promotion becomes a lookup. And the cost
objective: 845 queue, plan, check and ledger calls after the last product
edit, roughly 156M tokens or 13% of the window, become one command; the 639
hand-run `git` calls lose their reason to exist. This is the slice the 40%
target rests on.

**Next slice.** L-6.

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
