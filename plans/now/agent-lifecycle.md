# Agent lifecycle — make closeout survive interruption and two lanes

<!-- CONTEXT: plan | LAYER: immediate-task -->

Status: active | Owner: Dave / Claude / Codex | Next: L-38 (Codex lane) to count worker edits made from a worktree-relative shell command | Dependency: L-38 follows L-37 in the Codex lane | Verified: 2026-10-24

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
| L-37 | the guard hook lets `git show`/`git grep` read archived plans | `tools/guard_hook.py`, `tests/test_guard_hook.py` | low |
| L-38 | count worker product edits from worktree-relative shell commands | `tools/session_cost.py`, `tests/test_session_cost_scope.py` | medium |

L-31 to L-36 come from the 22 Oct 2026 workflow comparison (Dave asked
whether a hooks, state-machine and multi-agent-review setup would help;
Codex listed twelve recurring blockers). Its finding: almost none of the
190 stops in 21 days were correctness escapes, so no extra review agents
are added; the cost is in verify ambiguity, queue bookkeeping and
prose-only rules. L-35 and L-36 both edit `tools/slice.ps1` and
`tools/check_docs.py`, so they run in id order in the Claude lane.
Judging a borderline item with a cheap model was considered and
rejected: lanes hold five items, far below the break-even the source
setup measured.

L-16 to L-26 shipped 2 to 13 Oct 2026, each with its record in
`plans/archive/` named by id and date; WC-1 to WC-5 shipped with
`plans/archive/workflow-checks_2026-10-10.md`. The 16 Oct 2026
agent-workflow review measured the mechanisms behind L-27, L-28 and L-29. L-27 and L-28 share a
test file, so L-28 follows L-27. Each slice's acceptance names a
before-figure from that review and one real canary closeout.

L-27 shipped 2026-10-17; its specification is `plans/archive/L-27_2026-10-17.md`.

**Code health (`plans/now/code-health.md`, 18 Oct 2026).** CQ-L1 added a `gdscript style` stage to `tools/verify.ps1` straight after `godot boot`, after L-30, which also edits `verify.ps1`; it landed 22 Oct 2026.

L-28 shipped 2026-10-18; its specification is `plans/archive/L-28_2026-10-18.md`.

L-30 shipped 2026-10-18; its specification is `plans/archive/L-30_2026-10-18.md`.

L-31 shipped 2026-10-22; its specification is `plans/archive/L-31_2026-10-22.md`.

L-32 shipped 2026-10-22; its specification is `plans/archive/L-32_2026-10-22.md`.

L-33 shipped 2026-10-23; its specification is `plans/archive/L-33_2026-10-23.md`.

L-34 shipped 2026-10-23; its specification is `plans/archive/L-34_2026-10-23.md`.

L-35 shipped 2026-10-24; its specification is `plans/archive/L-35_2026-10-24.md`.

L-36 shipped 2026-10-24; its specification is `plans/archive/L-36_2026-10-24.md`.

## L-37 -- the guard hook lets `git show`/`git grep` read archived plans

**Now.** `CLAUDE.md` ("Why a built system is the way it is") and the review
contract send a session to `git grep -n <id> HEAD -- plans/archive` for a
shipped slice's record. `tools/guard_hook.py::_reason` refuses any shell
command whose text contains `plans/archive`, `docs/archive`, `_backups` or
`.godot`, so that route is denied ("Do not read this denied path.") and the
session retries or reads around it, which costs requests. A heredoc or
commit message that merely names an archived path is refused the same way
(`plans/observations/system-improvement-signals.md`, 23 Oct 2026 entry).

**Target.** The denied-path test applies only to a command that reads the
working tree at that path: `cat`, `head`, `tail`, `sed`, `grep`/`rg`/`Select-String`,
`Get-Content`, `type`, `ls`/`dir`/`Get-ChildItem` on it. A command whose first
word is `git` (so `git show HEAD:plans/archive/x.md`, `git grep ... HEAD --
plans/archive`, `git log -- plans/archive`) is allowed, as is `git commit -m`
text naming a path. The file tools stay denied on purpose (the `Read`
deny list is untouched), and the four existing denial cases keep passing.

**Open decisions:** none.

The change relaxes a deny rule only for read-only `git` history commands,
which `CLAUDE.md` already prescribes.

```queue
**[Codex] L-37 -- the guard hook lets `git show`/`git grep` read archived plans**
- Plan: `plans/now/agent-lifecycle.md` -- "L-37 -- the guard hook lets `git show`/`git grep` read archived plans"
- Files: `tools/guard_hook.py`, `tests/test_guard_hook.py`
- Check: `python -m unittest tests.test_guard_hook` passes with new cases: `git show HEAD:plans/archive/x.md`, `git grep -n L-31 HEAD -- plans/archive` and `git commit -m "see plans/archive/x"` are allowed; `Get-Content plans/archive/x.md`, `cat docs/archive/x.md`, `rg foo _backups` and `ls .godot` are still denied; `.\tools\verify.ps1` is green
- Proof: `absent: tools/guard_hook.py :: def _reads_tree`
- Next after: L-38 -- count worker product edits from worktree-relative shell commands
```

## L-38 -- count worker product edits from worktree-relative shell commands

**Now.** After L-29, `tools/session_cost.py --phases` finds product edits in
only 11 of 52 slice-worker subagent transcripts. Its Bash edit check requires
an explicit `.worktrees/<id>/<product dir>/` path in the same command. A worker
that changes into its worktree and then runs `sed -i` or `cp` on a relative
product path is counted as making no product edit. The current unit cases
cover only absolute worktree paths.

**Target.** Extend the existing `session_cost.py` edit classifier to resolve
worktree-relative shell write targets in a worker transcript, including a
`cd` in the same command and an established worktree cwd. Count only writes
under the listed product directories. Keep read-only commands, notes and
edits outside the worktree uncounted. Add transcript-level tests for both
counted and uncounted forms, then report the before/after worker count from
`--phases` if local transcripts are available. This measures work; it changes
no game or closeout behaviour.

**Open decisions:** none.

```queue
**[Codex] L-38 -- count worker product edits from worktree-relative shell commands**
- Plan: `plans/now/agent-lifecycle.md` -- "L-38 -- count worker product edits from worktree-relative shell commands"
- Files: `tools/session_cost.py`, `tests/test_session_cost_scope.py`
- Check: `python -m unittest tests.test_session_cost_scope` passes, including `cd .worktrees/L-38; sed -i ... tools/session_cost.py`, `cd .worktrees/L-38; cp ... scripts/bee.gd`, established worktree cwd, and read-only/non-product countercases; `python tools/session_cost.py --phases` reports the worker count when transcripts are available
- Proof: `absent: tools/session_cost.py :: def _shell_product_edit`
- Next after: none -- agent-lifecycle plan complete
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
