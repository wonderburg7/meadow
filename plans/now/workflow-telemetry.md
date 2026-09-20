# Workflow telemetry — make the instruments answer the questions they were built for

<!-- CONTEXT: plan | LAYER: immediate-task -->
Status: complete | Owner: Dave / Codex | Next: None -- plan complete | Dependency: none | Verified: 2026-09-20

**Objective.** `plans/now/agent-lifecycle.md` sets a measured target -- raise
the implementing share of a session's context above 40% -- and every decision
about how to get there is read off `tools/session_cost.py`. Three of its
readouts are silently empty or wrong, so the decisions they were built to
support are being taken blind. Fix the instruments, not the numbers.

**State.** Measured on 20 Sep 2026 from `.git/meadow-diagnostics.jsonl`,
1220 records, and `python tools/session_cost.py --events`:

- **`tool_bash` recorded `cd`.** 519 of 551 records had `cmd` = `cd`, because
  worktree commands begin `cd <path> && ...`. T-1 now skips leading `cd` and
  `NAME=value` setup, records the first operative program (with the script
  basename for Python and PowerShell), and leaves the event count unchanged.
- **Level drift has never assessed a single slice.** `--events` prints
  `level drift none / not assessable: 12`. `slice_claimed.branch` is the
  slice's branch (`claude/UI-X-2`, `codex/SF-1`); `session_start.branch` is
  the session's own branch (`claude/next-slice-f61cd2`). The two sets are
  disjoint, so `sessions_by_branch.get(e.get("branch"))` is empty for every
  claim and all 12 fall through to `not_assessable`. All 12 claims do carry a
  level, so the defect is entirely in the join.
- **A headless run cannot tell a compile failure from a collapsed colony.**
  `tools/run_scenario.py` judges a run by `returncode` and writes
  `process.log` without reading it. Godot exits 0 with scripts that failed to
  compile, so a fresh worktree with no import cache produces a run that looks
  successful and reports numbers that read as a gameplay or balance
  regression. This has cost at least one full investigation.

The first of these is recorded as a signal in
`plans/observations/system-improvement-signals.md`; the other two were found
while triaging it, and this plan is where all three are owned.

## Open slices at a glance

| Slice | Outcome | Files owned | Startable | Level |
| --- | --- | --- | --- | --- |

Dependencies, stated rather than implied. T-2 and T-1 both edit
`tools/session_cost.py` and `tests/test_source_checks.py`, and T-2 also edits
`tools/slice.ps1`, so both queue behind **L-14**
(`plans/now/agent-lifecycle.md`), which owns those two files first, and run in
the order above. T-3 shares no file with either and could run at any point.
None of the three depends on the Claude lane.

**Files this plan may not take.** `tools/verify.ps1`,
`tools/update_function_map.py` and `tools/stage_reference.py` are the Claude
lane's (`plans/now/verification-cost.md`), as are the six `scripts/*.gd`
files V-3 headers. Nothing here needs them.

T-2 shipped 2026-09-20; its specification is `plans/archive/T-2_2026-09-20.md`.

T-1 shipped 2026-09-20; its specification is `plans/archive/T-1_2026-09-20.md`.

T-3 shipped 2026-09-20; its specification is `plans/archive/T-3_2026-09-20.md`.
