# Agent lifecycle — make closeout survive interruption and two lanes

<!-- CONTEXT: plan | LAYER: immediate-task -->

Status: active | Owner: Dave / Claude | Next: L-18 -- the claim warns when it takes a lane's last item into a dry backlog, then L-19 -- queue writes wait for a running finish, and finish re-applies its own queue edit over a sibling's (Dave, 5 Oct 2026, from the 4-5 Oct run-queue run), then L-21, L-20, L-22 and L-23 from `docs/agent-workflow-review-2026-10-05.md` (L-23 gated on L-18; until L-20 lands `session_cost.py --days` reads 1 of every 70 sessions, so the gate below is unreadable locally too; L-16 and L-17 shipped; the canaries still to be seen are one slice per lane closed out while origin is ahead, and one whose queue title carries an em dash closed out from a `chcp 1252` console with `git log -1 --format=%s master` showing the dash intact); the completion gate in "Objective" (zero `lifecycle_failure` outcomes over seven days, a canary slice named per lane, the implementing share above 40%) is measured on Dave's machine with `python tools/session_cost.py --stops`, `--phases` and `--events` from 6 Oct 2026 (not met on 5 Oct 2026: the seven-day window opens 6 Oct, so the earliest reading is 13 Oct 2026) and pasted into the next agent-workflow review, which cannot read those files from a cloud session (`docs/agent-workflow-review-2026-09-30.md`, Dave's actions) | Dependency: none | Verified: 2026-10-05

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
| L-20 | session_cost reads every worktree's transcripts, judges level drift on the worker, and stops counting skipped stages as failures | `tools/session_cost.py`, `tests/test_session_cost_scope.py` | medium |
| L-21 | a verify stop names the stage that failed | `tools/slice.ps1`, `tests/test_slice_lifecycle.py` | medium |
| L-22 | a hands-on check pass runs each check in a check-runner subagent | `.claude/agents/check-runner.md`, `plans/reference/check-runner.md` | medium |
| L-23 | the queue warns before a lane's backlog runs dry, and /run-queue specifies the successor before it claims | `tools/check_docs.py`, `tests/test_queue_lookahead.py`, `.claude/rules/documentation.md`, `.claude/skills/run-queue/SKILL.md` | medium |

L-20 to L-23 come from `docs/agent-workflow-review-2026-10-05.md` (F1 to F5);
L-22 and L-23 are Dave's 5 Oct 2026 choices. L-21 follows L-19 and L-23
follows L-18 (shared `tools/slice.ps1`; L-18's machine-readable dry run).

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
- Next after: L-21 -- a verify stop names the stage that failed
```

## L-20 -- session_cost reads every worktree's transcripts, judges level drift on the worker, and stops counting skipped stages as failures

<!-- LAYER: immediate-task -->

Level: medium (one script and a new test module, deterministic fixtures).

**True now** (verified 5 Oct 2026, `docs/agent-workflow-review-2026-10-05.md` F1).
- `tools/session_cost.py::main` builds `files` from the primary directory
  `C--Users-dl13860-Documents-Meadow-meadow` alone, so `--days`,
  `--classify`, `--phases` and `--no-edit-reasons` see 1 of the 70
  sessions of 28 Sep to 5 Oct: desktop sessions write to
  `C--Users-dl13860-Documents-Meadow-meadow--claude-worktrees-<name>`.
  `python tools/session_cost.py --days 7` prints `sessions 0`.
- `_session_totals` globs `<dir>/*.jsonl` only; a /run-queue worker's
  transcript is `<dir>/<session>/subagents/agent-*.jsonl`, so
  `_print_level_drift` judges every slice on the coordinator's Opus rows.
  All 36 claims since 28 Sep were coordinated; the workers ran Sonnet for
  low/medium and Opus for high, as `.claude/agents/slice-worker-*.md` says.
- `run_events` counts a `verify_stage` event with `skipped: true` as a
  failure (`not e.get("ok")`): "lifecycle tests=82" is skips, not failures.

**True afterwards.**
- New `_transcript_files(days, home=None)` returns the top-level `*.jsonl`
  of every `C--Users-dl13860-Documents-Meadow-meadow*` directory under
  `home` (default `Path.home() / ".claude" / "projects"`) whose first
  timestamp is inside the window; `main` uses it for all four modes and
  prints first `transcripts  <n> sessions (<p> primary, <w> worktree directories)`.
- `_print_level_drift`: when the claim's session has subagent transcripts,
  it judges only those whose first `user` message text matches
  `"id"\s*:\s*"<slice id>"` and labels the models `worker:`; with none it
  judges the session as today.
- `run_events` prints `verify failures` from events with neither `ok` nor
  `skipped`, and a separate `verify skips` line.
- `_session_totals`' docstring and this plan's "Standing rules" sentence on
  `--days`/`--classify`/`--phases` say the scope is every worktree's
  transcripts since L-20.

**Must not change.** `--stops`; the event log's format; `OUTCOME_CLASSES`;
any report's column layout.

**Stop and escalate** if a subagent transcript's first user message is not
the dispatch prompt (the id join then needs another key).

```queue
**[Claude] L-20 -- session_cost reads every worktree's transcripts, judges level drift on the worker, and stops counting skipped stages as failures**
- Plan: `plans/now/agent-lifecycle.md` -- "L-20 -- session_cost reads every worktree's transcripts, judges level drift on the worker, and stops counting skipped stages as failures"
- Files: `tools/session_cost.py`, `tests/test_session_cost_scope.py`
- Check: `python -m unittest tests.test_session_cost_scope` passes with three cases built in a temporary `home` (a worktree directory's session is counted; a coordinator session with a worker subagent for the slice reports the worker's model; a skipped stage is a skip, not a failure); `python tools/session_cost.py --days 7` prints a non-zero `sessions`; `tools/verify.ps1` is green
- Proof: `absent: tools/session_cost.py :: def _transcript_files`
- Next after: L-22 -- a hands-on check pass runs each check in a check-runner subagent
```

## L-21 -- a verify stop names the stage that failed

<!-- LAYER: immediate-task -->

Level: medium (one function and two call sites in a script with a suite).

**True now** (verified 5 Oct 2026, the review's F4). `Invoke-SliceFinish`'s
two verify stops in `tools/slice.ps1` record the cause `<id> --
tools/verify.ps1 (-Scope branch|primary) failed; branch left untouched`.
`verify.ps1` prints `<stage>: FAILED` for the failing stage, but the stop
ledger keeps only the cause, and `Save-VerifyLog` overwrites
`meadow-slice-verify.log` each time. 17 of the 67 stops from 30 Sep to 5 Oct
were verify stops whose stage nobody can now name.

**True afterwards.** New `Get-VerifyFailureSummary -Output <string[]>`
returns `failed: <stage>, <stage>` from lines matching `^(.+): FAILED$`, or
`last line: <last non-empty line, cut to 120 characters>` when none match.
Both stops append ` (<summary>)` to `-Cause`, so `--stops` groups them by
stage.

**Must not change.** The `-Fix` texts; `Save-VerifyLog`; the stop ledger's
fields.

```queue
**[Claude] L-21 -- a verify stop names the stage that failed**
- Plan: `plans/now/agent-lifecycle.md` -- "L-21 -- a verify stop names the stage that failed"
- Files: `tools/slice.ps1`, `tests/test_slice_lifecycle.py`
- Check: `python -m unittest tests.test_slice_lifecycle` passes with a new case modelled on `test_mock_slice_can_claim_commit_and_close` whose mock `verify.ps1` prints `unit tests: FAILED` and exits 1, and whose `finish` output and stop-ledger cause contain `failed: unit tests`; `tools/verify.ps1` is green
- Proof: `absent: tools/slice.ps1 :: function Get-VerifyFailureSummary`
- Next after: L-20 -- session_cost reads every worktree's transcripts, judges level drift on the worker, and stops counting skipped stages as failures
```

## L-22 -- a hands-on check pass runs each check in a check-runner subagent

<!-- LAYER: immediate-task -->

Level: medium (two new instruction files; no code).

**True now** (verified 5 Oct 2026, the review's F2; Dave chose this on 5 Oct
2026). A check pass runs every check in its own context: 9 such sessions
were 486M of the week's 1,412M context tokens, and one reached 630 requests
and 256 screenshots, its context rising from 64K to 486K per request.

**True afterwards.**
- `.claude/agents/check-runner.md`: frontmatter `name: check-runner`, a
  description saying it runs one filed check from `checks/ready/` with
  computer use and returns a verdict, dispatched by a check pass and not for
  direct use; `model: opus`, `effort: medium`, and no `tools:` line (it
  needs the computer-use tools). Its body tells it to read
  `git -C <ROOT> show HEAD:plans/reference/check-runner.md` and follow it,
  and that its final message is only that brief's JSON.
- `plans/reference/check-runner.md` (under 80 lines, the reference Status
  line): inputs `ROOT` and one check id; read only the check's own file under `checks/ready/`;
  launch and act as its "What this checks" says, with Git Bash
  `"/c/Program Files/Godot/Godot.exe" --path .` from `ROOT` as the launch
  fallback; the computer-use access name is `Godot.exe`; never press "Back
  to the run" on a fresh boot; a 1-2 s capture lag and a few pixels of click
  offset are tool artefacts, not findings; a synthetic Escape is no evidence,
  so a check that needs a real key returns `cannot-run`; close the game
  before returning. Result:
  `{"id": "C-<n>", "verdict": "pass|fail|cannot-run", "evidence": "<one sentence of what was on screen>", "needs_dave": "<what only Dave's keyboard or eye can confirm, or empty>"}`.
- The runner never edits `checks/`, never runs `tools/new_check.py`, and
  never asks Dave anything: the pass does those.

**Must not change.** `checks/` records and their format; who confirms a check.

```queue
**[Claude] L-22 -- a hands-on check pass runs each check in a check-runner subagent**
- Plan: `plans/now/agent-lifecycle.md` -- "L-22 -- a hands-on check pass runs each check in a check-runner subagent"
- Files: `.claude/agents/check-runner.md`, `plans/reference/check-runner.md`
- Check: `python tools/check_docs.py` passes; `grep -c "name: check-runner" .claude/agents/check-runner.md` prints 1; `grep -c "cannot-run" plans/reference/check-runner.md` prints at least 2
- Proof: `absent: .claude/agents/check-runner.md :: name: check-runner`
- Next after: L-23 -- the queue warns before a lane's backlog runs dry, and /run-queue specifies the successor before it claims
```

## L-23 -- the queue warns before a lane's backlog runs dry, and /run-queue specifies the successor before it claims

<!-- LAYER: immediate-task -->

Level: medium (one check function reusing L-18's dry run, two rule texts).

**True now** (verified 5 Oct 2026, the review's F3; Dave chose this on 5 Oct
2026). 15 of about 40 Claude slices since 30 Sep wrote their successor's
specification mid-`finish` (`refill_lane.py` refused 13 times, the refill
gate stopped twice). L-18 adds `advice.dry_after` at claim, a warning only.

**True afterwards.**
- New `check_queue_lookahead(warnings)` in `tools/check_docs.py`, called from
  `main` after `check_queue_successors`: for each lane, it calls the
  function behind L-18's machine-readable `refill_lane.py --top-up
  --dry-run` (imported, not re-implemented) and warns `lookahead: closing
  <id> would leave the <Lane> lane short with nothing admissible behind
  it; specify the owning plan's next slice` when deleting the lane's first
  item would empty the lane or take the queue under `QUEUE_SIZE_MIN` and
  the dry run would add nothing. It never adds an error.
- `.claude/rules/documentation.md`, after the paragraph ending "is what
  makes a lane refill itself by lookup.", gains: "A lane item is not
  claimed while `advice.dry_after` is true: specify its successor first, so
  planning happens before the build, not inside `finish` (Dave, 5 Oct
  2026)."
- `.claude/skills/run-queue/SKILL.md` step 2: the dry-run test becomes
  `advice.dry_after` from `doctor`; when true, run "Refilling the lane" before
  `start`, never after.

**Must not change.** `QUEUE_SIZE_MIN`; the refill gate; any existing error.

**Stop and escalate** if L-18 exposed no importable function for its dry run.

```queue-gated
**[Claude] L-23 -- the queue warns before a lane's backlog runs dry, and /run-queue specifies the successor before it claims**
- Plan: `plans/now/agent-lifecycle.md` -- "L-23 -- the queue warns before a lane's backlog runs dry, and /run-queue specifies the successor before it claims"
- Files: `tools/check_docs.py`, `tests/test_queue_lookahead.py`, `.claude/rules/documentation.md`, `.claude/skills/run-queue/SKILL.md`
- Check: `python -m unittest tests.test_queue_lookahead` passes with two cases (a one-item lane over a dry backlog warns; the same lane with an admissible block behind it does not); `python tools/check_docs.py` still exits 0 on today's queue; `tools/verify.ps1` is green
- Proof: `absent: tools/check_docs.py :: def check_queue_lookahead`
- Next after: none -- plans/now/agent-lifecycle.md is complete once L-23 lands; its completion gate is a measurement, not a slice
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
