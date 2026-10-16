# Agent lifecycle — make closeout survive interruption and two lanes

<!-- CONTEXT: plan | LAYER: immediate-task -->

Status: active | Owner: Dave / Claude | Next: L-27 -- a resumed finish re-verifies a branch that gained commits | Dependency: none | Verified: 2026-10-16

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
| L-27 | A resumed `finish` re-verifies a branch that gained code commits | `tools/slice.ps1`, `tests/test_slice_lifecycle.py` | medium |
| L-28 | Archiving a slice leaves another slice's queue block in the plan | `tools/archive_slice.py`, `tests/test_slice_lifecycle.py` | medium |
| L-29 | `session_cost.py` counts subagent transcripts and scripted edits | `tools/session_cost.py`, `tests/test_session_cost_scope.py` | medium |

L-16 to L-26 shipped 2 to 13 Oct 2026, each with its record in
`plans/archive/` named by id and date; WC-1 to WC-5 shipped with
`plans/archive/workflow-checks_2026-10-10.md`. The 16 Oct 2026
agent-workflow review measured the mechanisms behind L-27, L-28 and L-29. L-27 and L-28 share a
test file, so L-28 follows L-27. Each slice's acceptance names a
before-figure from that review and one real canary closeout.

## L-27 -- a resumed finish re-verifies a branch that gained commits

<!-- LAYER: immediate-task -->

Level: medium. **Now:** `Write-ClosingJournal` (`tools/slice.ps1`) writes
`{id, branch, lane, phase}`. `Test-BranchVerified` returns true as soon as
the journal's phase is `verified` or later, before it reads the
`meadow-slice-verified.json` record that 4499fb6 (12 Oct 2026) tied to
HEAD. A finish that stops after its branch verify (at the refill gate, at
primary verification: 7 primary stops from 5 to 16 Oct) keeps that journal,
so a fix committed on the branch, or master merged into it, lands with
"already passed this closeout; skipping" (T2-4a, 9 Oct, twice).

**After:**

- `Write-ClosingJournal` also writes `head`: the worktree's
  `git rev-parse HEAD` at the moment it writes (after finish's own commit for
  that phase, if any). The `merged` and `queue-reapplying` writes, made in
  the primary checkout, record it the same way; nothing reads it there.
- New `function Test-JournalVerifiedHead` (params `$Journal`,
  `$WorktreeRoot`) returns true only when the journal has a `head` and either
  it equals the worktree's HEAD, or `git diff --name-only <head> HEAD` lists
  only `*.md` paths (a queue or plan fix after a refill refusal, which
  `refill_lane.py` has already run `check_docs` over).
- `Test-BranchVerified`: a journal phase at `verified` or later counts only
  when `Test-JournalVerifiedHead` is true; otherwise it falls through to the
  record check as now. A journal written before this slice (no `head`)
  therefore costs one extra verify, once.

**Must not change:** `$script:ClosingPhaseOrder`, the journal's path, the
record's format, and the skipping of every phase after `verified` on resume
(archive and refill must never run twice). No new stop.

**Tests** in `tests/test_slice_lifecycle.py`, using the fixture's existing
`Invoke-InjectedLifecycleFailure` phases to stop a finish after `verified`:
(1) then commit a change to a non-Markdown file on the branch and rerun
`finish`: verify runs again; (2) the same with only a `.md` change: verify
is skipped; (3) a journal without `head`: verify runs.

**Acceptance:** the next real finish that is retried after a branch commit
prints a verify run, not "already passed this closeout; skipping" (before:
T2-4a skipped twice on 9 Oct). Stop and return `blocked` if the fixture
cannot stop a finish after `verified` without a new injection point.

```queue
**[Claude] L-27 -- a resumed finish re-verifies a branch that gained commits**
- Plan: `plans/now/agent-lifecycle.md` -- "L-27 -- a resumed finish re-verifies a branch that gained commits"
- Files: `tools/slice.ps1`, `tests/test_slice_lifecycle.py`
- Check: `python -m unittest tests.test_slice_lifecycle` passes, including the three resume cases (code commit re-verifies, Markdown-only commit skips, a journal without head re-verifies); `.\tools\verify.ps1` is green
- Proof: `absent: tools/slice.ps1 :: function Test-JournalVerifiedHead`
- Next after: L-28 -- archiving a slice leaves another slice's queue block in the plan
```

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
- Next after: None -- L-29 is independent
```

## L-29 -- session_cost.py counts subagent transcripts and scripted edits

<!-- LAYER: immediate-task -->

Level: medium. **Now:** `_transcript_files` returns top-level transcripts
only. From 5 to 16 Oct 2026, 185 subagent transcripts held 1,053M of the
2,339M context tokens and were outside `--days`, `--classify` and
`--phases`. Slice workers cannot use Edit in `.worktrees/` and edit through
Python scripts written to their scratchpad (0 Edit, 255 Write, 2,538 Bash
calls in 59 dispatches), so `_product_edit` saw 11 implementing requests in
11,700. `--phases`' 11.0% implementing and 55.1% "no product edit" is an
artefact, and this plan's completion gate cannot be judged.

**After:**

- New `def _subagent_transcripts(files)`: each top-level file's
  `<stem>/subagents/agent-*.jsonl`. `--days`, `--classify` and `--phases`
  read top-level plus subagent files; the header prints
  `transcripts  N sessions (P primary, W worktree directories) + S subagent transcripts`.
- `_product_edit` also counts (a) a Write or Edit outside the repository
  whose `content` names a `.worktrees/<id>/` path followed by one of
  `PRODUCT_DIRS` (a scratchpad edit script), and (b) a Bash command holding
  `sed -i` or `cp ` and such a path.
- After the `--phases` table, one line:
  `slice workers (subagents named slice-worker-*): <tokens> = <share>% of all context`,
  the type read from each transcript's `.meta.json` `agentType`.

**Must not change:** `--coordinator`, `--events`, `--stops` and
`--model-check` output; the four phase rows and their order.

**Tests** in `tests/test_session_cost_scope.py` with fixture transcripts: a
subagent file is counted; each of (a) and (b) counts as a product edit; a
scratchpad script naming no worktree path does not.

**Acceptance:** `python tools/session_cost.py --days 11 --phases` prints a
subagent count above zero and a slice-worker share (before, 16 Oct: 80
sessions, 1,286M, 11.0% implementing; workers 447M, 19% of 2,339M), and the
next agent-workflow review judges the completion gate from it.

```queue
**[Claude] L-29 -- session_cost.py counts subagent transcripts and scripted edits**
- Plan: `plans/now/agent-lifecycle.md` -- "L-29 -- session_cost.py counts subagent transcripts and scripted edits"
- Files: `tools/session_cost.py`, `tests/test_session_cost_scope.py`
- Check: `python -m unittest tests.test_session_cost_scope` passes, including subagent files and both scripted-edit forms; `python tools/session_cost.py --days 11 --phases` prints a subagent transcript count and a slice-worker share; `.\tools\verify.ps1` is green
- Proof: `absent: tools/session_cost.py :: def _subagent_transcripts`
- Next after: None -- plan complete once L-27 and L-28 land
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
