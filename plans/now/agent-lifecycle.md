# Agent lifecycle — make closeout survive interruption and two lanes

<!-- CONTEXT: plan | LAYER: immediate-task -->

Status: active | Owner: Dave / Claude / Codex | Next: L-33 -- one admission check shared by check_docs, start and closeout (Claude lane); L-34 -- command guard (Codex lane, reassigned by Dave 23 Oct 2026); separately, after L-29 (17 Oct 2026), `tools/session_cost.py` finds product edits in only 11 of 52 slice-worker subagent transcripts, so worker edits are probably still undercounted (likely paths built with `cd`, or other Bash forms) -- a follow-up slice to specify | Dependency: L-33, L-35 and L-36 run in order in Claude; L-34's L-31 prerequisite landed 22 Oct 2026 | Verified: 2026-10-23

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
| L-35 | known baseline failures and stop causes are named, not rediagnosed | `tools/verify.ps1`, `tools/slice.ps1`, `tools/stop_causes.py`, `tests/test_stop_causes.py`, `tests/baseline_failures.json`, `tools/check_docs.py` | medium |
| L-36 | clean checkouts pass the doc checks; stray worktrees are reported | `tools/check_docs.py`, `tools/slice.ps1`, `tests/test_slice_lifecycle.py` | low |

L-31 to L-36 come from the 22 Oct 2026 workflow comparison (Dave asked
whether a hooks, state-machine and multi-agent-review setup would help;
Codex listed twelve recurring blockers). Its finding: almost none of the
190 stops in 21 days were correctness escapes, so no extra review agents
are added; the cost is in verify ambiguity, queue bookkeeping and
prose-only rules. The Claude slices run in id order, one file set at a time: every one
but L-34 edits `tools/slice.ps1`. L-31 and L-35 followed CQ-L1
(`plans/now/code-health.md`), which also edits `tools/verify.ps1`; it landed 22 Oct 2026. L-34
waited for L-31, whose `stop-verify` it names; L-31 landed 22 Oct 2026.
Dave reassigned L-34 from the unqueued Claude backlog to Codex on
23 Oct 2026. Its four files are disjoint from every queued Claude item,
so it may run independently of L-33, L-35 and L-36. Its `Next after:`
still names L-35 in Claude; this does not transfer L-35's ownership.
Judging a borderline item
with a cheap model was considered and rejected: lanes hold five items,
far below the break-even the source setup measured.

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

## L-35 -- known baseline failures and stop causes are named, not rediagnosed

**Now.** Unit tests stopped `finish` 23 times in 21 days. Among them were
fixture lock timeouts, an unavailable `New-TemporaryFile`, NF2's sandboxed
`APPDATA` and sprite-catalogue failures in CD-3. A failure that also occurs
on master stops a branch just like a regression. Sandbox, auto-approval and
credential failures (`Receive-Job: Access is denied`, refused pushes,
authentication) read as code faults. Dave is asked about the same apparent
blocker again and again. Only the import cache already gets a "not a code
fault" line.

**Target.**
1. `tests/baseline_failures.json` lists confirmed baseline failures. Each
   entry has a test id, a disposition, an owner and an expiry date.
2. `verify.ps1` reports a listed, unexpired failure as
   `baseline, not this branch` and does not fail the stage on it.
   `check_docs` fails on an expired entry, so the quarantine cannot rot.
3. `tools/stop_causes.py` sorts a saved verify log or a stop's stderr into
   one of `code`, `baseline`, `sandbox`, `approval-policy`, `credentials`,
   `import-cache`, `lock` or `cwd-holder`, using a regex table. Each
   category carries one remedy line. `slice.ps1` prints both in its stop
   block.
4. Adding a pattern is one table row.

**Open decisions:** none.

```queue
**[Claude] L-35 -- known baseline failures and stop causes are named, not rediagnosed**
- Plan: `plans/now/agent-lifecycle.md` -- "L-35 -- known baseline failures and stop causes are named, not rediagnosed"
- Files: `tools/verify.ps1`, `tools/slice.ps1`, `tools/stop_causes.py`, `tests/test_stop_causes.py`, `tests/baseline_failures.json`, `tools/check_docs.py`
- Check: `python -m unittest tests.test_stop_causes` passes, classifying sample logs for each category (including `Receive-Job: Access is denied`, a refused push and an import-cache boot failure); a listed baseline failure leaves its stage green with a `baseline` note, and an expired entry fails `check_docs`; `.\tools\verify.ps1` is green
- Proof: `absent: tools/verify.ps1 :: baseline_failures`
- Next after: L-36
```

## L-36 -- clean checkouts pass the doc checks; stray worktrees are reported

**Now.** COL-12, SI-1 and T2-5 failed `check_docs` in fresh worktrees
because a document names the gitignored `.claude/settings.local.json`
(`docs/context-review-2026-10-07.md`). Agents created empty placeholders
to get past it. An unregistered `.worktrees/L-28` folder, held by another
session, blocked RR-10's integration. Removal deferred by a Windows lock
was found only by the next closeout.

**Target.**
1. `check_docs.py` skips a referenced path that `git check-ignore`
   matches.
2. `slice.ps1 start` and `doctor` sweep the pending-deletions queue and
   list any unregistered `.worktrees/*` folder, naming the process that
   holds it. The holder lookup landed on 20 Oct; reuse it.

**Open decisions:** none.

```queue
**[Claude] L-36 -- clean checkouts pass the doc checks; stray worktrees are reported**
- Plan: `plans/now/agent-lifecycle.md` -- "L-36 -- clean checkouts pass the doc checks; stray worktrees are reported"
- Files: `tools/check_docs.py`, `tools/slice.ps1`, `tests/test_slice_lifecycle.py`
- Check: in a fresh worktree without `.claude/settings.local.json`, `python tools/check_docs.py` passes; `tests/test_slice_lifecycle.py` covers `doctor` listing an unregistered `.worktrees/*` folder and sweeping a pending deletion; `.\tools\verify.ps1` is green
- Proof: `absent: tools/check_docs.py :: check-ignore`
- Next after: none -- the L-31 to L-36 set is complete
```

**Measure after L-36.** Run `python tools/session_cost.py --stops --days 14`
and compare it with the 22 Oct baseline: 190 stops in 21 days, 60 in branch
verification and 16 at the refill gate. Separately, before changing
`/run-queue`'s reviewer rule, count the `in_slice` correctness findings per
slice level in its trial notes. Skip the reviewer for low slices only if
those findings are near zero.

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
