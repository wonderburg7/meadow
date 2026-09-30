# Agent lifecycle — make closeout survive interruption and two lanes

<!-- CONTEXT: plan | LAYER: immediate-task -->

Status: active | Owner: Dave / Claude | Next: L-16 (master is synchronised with origin before a claim and before a merge), then L-17 (one console-encoding contract for the lifecycle); the completion gate in "Objective" (zero `lifecycle_failure` outcomes over seven days, a canary slice named per lane, the implementing share above 40%) is measured on Dave's machine with `python tools/session_cost.py --stops`, `--phases` and `--events` from 6 Oct 2026 and pasted into the next agent-workflow review, which cannot read those files from a cloud session (`docs/agent-workflow-review-2026-09-30.md`, Dave's actions) | Dependency: none | Verified: 2026-09-30

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
| L-16 | master is synchronised with origin before a claim and before a merge | `tools/slice.ps1`, `tests/test_two_lane_closeout.py`, `tests/test_slice_lifecycle.py` | medium |
| L-17 | one console-encoding contract for the lifecycle, tested once | `tools/slice.ps1`, `tests/test_slice_lifecycle.py`, `tests/test_source_checks.py` | medium |

L-15 shipped 2026-09-29; its specification is `plans/archive/L-15_2026-09-29.md`.

Both slices change `tools/slice.ps1`, whose suite skips off Windows
(`workflow_test_support.windows_powershell`), so **each is implemented in a
local Windows session**, never a cloud one. Their blocks are fenced
`queue-gated` until such a session opens them (plan review, 30 Sep 2026:
a cloud claim could not run either slice's check, and `verify.ps1` would
pass with the tests skipped). `NEXTSTEPS.md` "Not in the queue, and why"
carries the two commands.

### L-16 — master is synchronised with origin before a claim and before a merge

Level: medium (the algorithm and every test outcome are given below; escalate
only if implementing it needs the closing-phase order changed, which it must
not -- synchronising is idempotent and is not a journaled phase).

**Why.** `docs/agent-workflow-review-2026-09-30.md` F1. Since 12 Sep master
carries 7 pull-type merges ("Merge branch 'master' ...", `c0f751d` on 30 Sep
after HF-1's closeout), each one a session running `git pull --no-rebase` by
hand because `finish` had already merged, removed the worktree and deleted
the ledger row before its one push was rejected. On 30 Sep five cloud review
sessions pushed master directly, so origin will now be ahead of Dave's
checkout as a matter of course, not by accident.

**True now.** `Invoke-SliceStart` reads the queue and commits the ledger row
on local master without fetching, and never pushes. `Invoke-SliceFinish`
merges into local master without fetching. `Invoke-SlicePostMergeCleanup`
pushes once at the end and throws `git push failed`; `Get-DefaultSliceFix`
then tells the session to `git pull --no-rebase` and retry, and `resume`
reaches the same push and fails the same way until someone has pulled.
`TwoLaneCloseoutTest.test_remote_ahead_integrates_or_fails_naming_remote_state`
accepts either outcome.

**True when done.**

1. A function `Sync-PrimaryMaster -Root -Reason` in `tools/slice.ps1`: runs
   `git fetch origin master` through `Invoke-GitQuiet` with the same
   `-c http.sslBackend=openssl` the push uses; on a fetch failure it prints
   one line (`<reason>: could not fetch origin; continuing offline`) and
   returns, so an offline machine behaves exactly as today. If `origin/master`
   is already contained in `master`, it does nothing. If `master` is an
   ancestor of `origin/master`, it fast-forwards (`git merge --ff-only
   origin/master`). Otherwise it merges with `git merge --no-edit
   origin/master`, message `Merge origin/master into master before <reason>`;
   if that merge reports a conflict it runs `git merge --abort` and stops
   with the step `synchronising master with origin` and a fix naming the
   conflicting files and the hand command (`git pull --no-rebase` in the
   primary checkout). It runs only when the primary checkout is on master and
   its coordination files are clean, which the callers already check.
2. It is called three times: at the top of `Invoke-SliceStart`, before the
   queue is read, so a claim is made from the queue origin holds; in
   `Invoke-SliceFinish` after the dirty-coordination check and before
   `primary verification`, so the primary verify and the merge see the
   integrated master; and in `Invoke-SlicePostMergeCleanup` immediately
   before the push, which also covers `resume`. Runtime policy: one fetch per
   lifecycle command, never a poll.
3. `Invoke-SliceStart` pushes its ledger-row commit after creating the
   worktree, through `Invoke-GitQuiet`; a failed push prints one line and is
   not a stop (the closeout push carries the row). With that, local master is
   ahead of origin only by hand commits, so case 1's merge commit is the
   exception, not the rule.
4. `Get-DefaultSliceFix`'s `git push` branch says what is now true: the
   command has already integrated origin, so a rejected push means a push
   landed between the sync and this one -- retry once; if it fails again,
   read git's message for an auth or network error.
5. Tests, all Windows-only like the rest of the suite. The existing
   remote-ahead case becomes strict: `finish` returns 0, `unrelated.txt` is
   on master and the slice landed. New cases in
   `tests/test_two_lane_closeout.py`: `start` while the remote is ahead
   claims and leaves `unrelated.txt` on master; a diverged local (one
   unpushed hand commit on master plus the remote commit) closes out with a
   merge commit whose subject starts `Merge origin/master into master before
   finish`; a genuine conflict (the same line of `sample.gd` changed on the
   remote and in an unpushed local commit) stops naming the step and the
   file, leaves `git status` clean and master unmerged, and `resume` after a
   hand `git pull --no-rebase` completes. In `tests/test_slice_lifecycle.py`:
   `start` with the remote path removed still claims and prints the
   offline line; a successful `start` leaves `origin/master` equal to
   `master`.

**Invariants.** The closing-phase order and journal are unchanged. Nothing
rewrites history: no rebase, no force. `plans/workstreams.md` is still
edited only from the primary checkout. A merge conflict is never resolved by
the script.

**Check.** `python -m unittest tests.test_two_lane_closeout
tests.test_slice_lifecycle` passes with the six cases above, and
`tools/verify.ps1` is green. **Canary:** one real slice in each lane closed
out while origin is ahead (push any small commit to master from a cloud
session first), with no `git pull` typed by the session, and `python
tools/session_cost.py --stops` showing no `git push failed` stop for it.

**Read:** this section; `Invoke-SliceStart`, `Invoke-SliceFinish` from
`primary checkout checks` down, `Invoke-SlicePostMergeCleanup`,
`Invoke-GitQuiet` and `Get-DefaultSliceFix` in `tools/slice.ps1` (by
`grep -n "^function"`); the remote-ahead test in
`tests/test_two_lane_closeout.py`.

```queue-gated
**[Claude] L-16 -- master is synchronised with origin before a claim and before a merge**
- Plan: `plans/now/agent-lifecycle.md` -- "L-16 — master is synchronised with origin before a claim and before a merge"
- Files: `tools/slice.ps1`, `tests/test_two_lane_closeout.py`, `tests/test_slice_lifecycle.py`
- Check: `python -m unittest tests.test_two_lane_closeout tests.test_slice_lifecycle` passes with the remote-ahead case strict and the five new cases, and `tools/verify.ps1` is green
- Proof: `absent: tools/slice.ps1 :: Sync-PrimaryMaster`
- Next after: L-17 -- one console-encoding contract for the lifecycle, tested once
```

### L-17 — one console-encoding contract for the lifecycle, tested once

Level: medium (one fixture, one test, one source rule; the call sites to
fold are listed).

**Why.** `docs/agent-workflow-review-2026-09-30.md` F2. Seven commits
between 18 and 29 Sep each fixed one place where Windows PowerShell 5.1's
cp1252 console mangled an em dash or curly quote in a coordination file:
`0da665e` (archive gate), `7a48997` (ledger row), `aedb0d0` (stop causes),
`9153793` (master's queue read at closeout), two in `archive_slice.py` and
`refill_lane.py` (18 Sep), and three hand repairs of mangled ledger rows on
18 Sep. Each was found by a production stop and fixed at that call site;
nothing proves the next call site is safe.

**True now.** `tools/slice.ps1` sets `[Console]::OutputEncoding` and
`$OutputEncoding` to UTF-8 at lines 27-28 (since `0da665e`), and the
`git show master:NEXTSTEPS.md` read in `Invoke-SliceFinish` still needed
its own save-set-restore block on 29 Sep (`9153793`), so the top-of-file
setting does not cover every native-command read. No lifecycle test runs
under a cp1252 console; the fixtures' only non-ASCII is the em dash in a
few plan headings of `tests/test_slice_lifecycle.py`.

**True when done.**

1. The slice first establishes, in a comment above the top-of-file
   encoding lines, why `9153793` was needed despite them (the likely
   answer, to be confirmed by reproducing it: PowerShell decodes a native
   command's piped output with `[Console]::OutputEncoding` as it was when
   the pipeline started, and the value at line 27 is not in force inside
   `Invoke-WithLifecycleLock`'s script block on every host). Whatever the
   cause, the fix is one place: a `Read-GitText` helper that runs a git
   command and returns its stdout decoded as UTF-8 bytes, used by every
   `git show`, `git log` and `git status --porcelain` read in the file, and
   the per-call save-set-restore block in `Invoke-SliceFinish` is deleted.
2. One test, `ConsoleEncodingTest` in `tests/test_slice_lifecycle.py`,
   Windows-only, runs `start` and `finish` through `powershell -NoProfile`
   after `chcp 1252` with a queue title, a plan heading, a ledger scope, an
   archive heading and a deliberate stop cause each carrying an em dash, a
   curly apostrophe and `é`, and asserts that the ledger row, the merge
   commit subject, the archive file's heading, the refilled queue line and
   the stop-ledger record all round-trip byte for byte.
3. A rule in `tests/test_source_checks.py`: `tools/slice.ps1` assigns
   `OutputEncoding` only at the top of the file, so the next encoding fix
   has one place to go.

**Invariants.** No format of any coordination file changes. Existing
records in `meadow-slice-stops.jsonl` are not rewritten (`run_stops` still
decodes legacy cp1252 lines).

**Check.** `python -m unittest tests.test_slice_lifecycle.ConsoleEncodingTest
tests.test_source_checks` passes, and `tools/verify.ps1` is green.
**Canary:** one real slice whose queue title carries an em dash closed out
from a `chcp 1252` console with `git log -1 --format=%s master` showing the
dash intact.

**Read:** this section; lines 1-30 and the `git show master:NEXTSTEPS.md`
block of `Invoke-SliceFinish` in `tools/slice.ps1`; the `Invoke-GitQuiet`
function; the fixture helpers at the top of `SliceLifecycleTest` in
`tests/test_slice_lifecycle.py`.

```queue-gated
**[Claude] L-17 -- one console-encoding contract for the lifecycle, tested once**
- Plan: `plans/now/agent-lifecycle.md` -- "L-17 — one console-encoding contract for the lifecycle, tested once"
- Files: `tools/slice.ps1`, `tests/test_slice_lifecycle.py`, `tests/test_source_checks.py`
- Check: `python -m unittest tests.test_slice_lifecycle.ConsoleEncodingTest tests.test_source_checks` passes and `tools/verify.ps1` is green
- Proof: `absent: tests/test_slice_lifecycle.py :: ConsoleEncodingTest`
- Next after: none -- agent-lifecycle is complete once L-17 ships and the Objective's completion gate is met
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
