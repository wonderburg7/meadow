# Stop readout — rank the steps that actually stopped a command

<!-- CONTEXT: plan | LAYER: immediate-task -->
Status: active | Owner: Dave / Codex | Next: ST-1 -- preflight refusals stop crowding the step ranking | Dependency: none | Verified: 2026-09-20

**Objective.** `python tools/session_cost.py --stops` exists to name the
closeout *step* that costs the most retries, because that is what decides
whether automating a gate is worth it. Its ranking currently leads with a
bucket that is not a step, so the decision it was built to support is taken
against a skewed list. Fix the readout, not the ledger.

**State.** Measured 20 Sep 2026 from `.git/meadow-slice-stops.jsonl`,
53 records spanning 18-20 Sep 2026:

- **19 of 53 stops carry an empty `step`.** `run_stops` folds them into a
  single `"(no step recorded)"` bucket, which is then the largest entry in
  "most expensive steps" -- 19 against 8 for the real leader, the archive
  gate. Every one of the 19 is a *preflight* refusal that happened before any
  step ran: 14 from `start`, 5 from `finish`. They are not unrecorded steps.
- **Their causes are real signal, and are currently invisible.** Tallied by
  cause: 10 `slice lifecycle is busy`, and 9 `<lane> lane already has an open
  worktree` (`SF-1` 3, `SM-1` 2, `T-3` 2, `UI-X-2` 1, `PERF-1` 1). The second
  group is a finished-but-unmerged worktree blocking the next claim -- the
  condition that blocked the Codex lane on 20 Sep 2026.
- **This is load-bearing.** `plans/now/agent-lifecycle.md` gates L-12 on
  `--stops` showing "the refill step among the two most frequent stops". A
  real step must therefore outrank a bucket that is not a step at all. On the
  present ledger the two refill steps stand at 1 each, so the gate is not met
  either way, but it cannot be read fairly until the bucket is separated.

`plans/archive/workflow-telemetry_2026-09-20.md` is complete and is not
reopened; this finding surfaced after it was archived, so it starts here.

## Open slices at a glance

| Slice | Outcome | Files owned | Startable | Level |
| --- | --- | --- | --- | --- |
| ST-1 | `--stops` ranks only steps, and reports preflight refusals by cause beside them | `tools/session_cost.py`, new `tests/test_session_cost_stops.py` | yes | low |

**Files this plan may not take.** `tools/slice.ps1` writes the ledger and is
not edited here -- the records already carry everything needed, and changing
the writer would re-date the 53 existing stops. `tools/verify.ps1`,
`tools/update_function_map.py` and the six `scripts/*.gd` files V-3 headers
are the Claude lane's (`plans/now/verification-cost.md`).

**Required reading.** ST-1's section below, and `run_stops` in
`tools/session_cost.py` (`python tools/func.py tools/session_cost.py run_stops`).

## ST-1 — preflight refusals stop crowding the step ranking

A stop with an empty `step` did not fail in a step: `tools/slice.ps1` refused
the command in preflight, before the first step ran. Counting those as a
pseudo-step puts them at the top of a list whose whole purpose is to rank
steps.

Requirements:

1. `run_stops` splits the ledger in two on whether `step` is set. The "most
   expensive steps" list contains only records with a step, so its ranking is
   a ranking of steps.
2. Records with no step are reported separately, under their own heading,
   tallied by `cause` rather than discarded -- the preflight causes are the
   evidence that a lane is being blocked by an open worktree. Group them by
   cause; a cause that names a worktree keeps that name.
3. Both totals are printed, and they sum to `stops recorded`, so no record is
   silently dropped by the split.
4. The existing decode fallback (UTF-8 then CP1252, per record) is unchanged;
   this slice does not touch how the ledger is read or written.
5. `tests/test_session_cost_stops.py` builds a small fixture ledger holding
   both kinds of record and asserts that a preflight record cannot appear in
   the step ranking, and that the two reported totals sum to the record count.

Level: low. One function, one new test, no runtime or save surface.

Check: `python tools/session_cost.py --stops` on the real ledger prints a
"most expensive steps" list whose entries are all genuine steps, with the
preflight refusals shown separately by cause and the two totals summing to
`stops recorded`; `python tools/check_docs.py` and `.\tools\verify.ps1` green.

Proof: `present: tools/session_cost.py :: (no step recorded)`

Next after: none -- stop-readout is complete once ST-1 ships. Whether the
`lane already has an open worktree` count then justifies a lifecycle change
is a separate question, recorded in
`plans/observations/system-improvement-signals.md` and not owned here.
