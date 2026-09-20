# Workflow telemetry — make the instruments answer the questions they were built for

<!-- CONTEXT: plan | LAYER: immediate-task -->
Status: active | Owner: Dave / Codex | Next: T-3 -- a headless run that did not compile fails as a compile failure | Dependency: none | Verified: 2026-09-20

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
| T-3 | A headless run that did not compile fails as a compile failure | `tools/run_scenario.py`, `docs/headless-run-contract.md` | yes | medium |

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

## T-3 — a headless run that did not compile fails as a compile failure

`tools/run_scenario.py` decides a run succeeded from Godot's exit code. Godot
exits 0 when a script fails to compile: it logs `SCRIPT ERROR:` and carries on
with the node missing. The session then reads a session file full of zeroes
and diagnoses a gameplay or balance collapse. `tools/godot_compile_check.py`
already knows the patterns to look for -- `run_scenario.py` simply never looks
at the `process.log` it writes.

Fixed now:

- **Invariants.**
  - An honest gameplay collapse still reports as a gameplay collapse. Only a
    compile or load failure is reclassified.
  - A run that compiled cleanly is not slowed: one pass over a log file
    already on disk.
  - The existing `process.log` path, session file and artefact names are
    unchanged, so every caller in `tools/headless/` keeps working.
- **Guidance, not decisions.** Reuse `godot_compile_check.py`'s patterns
  rather than writing a second list -- if that means exporting them from that
  module, do it there and import, do not copy. `godot_compile_check.py` is
  the Claude lane's V-1 neighbour but not one of its files; confirm that
  before editing it, and if it has been taken, keep the patterns in
  `run_scenario.py` and say so.
- **Say what to do about it.** The failure message must name the first
  `SCRIPT ERROR:` line and the `process.log` path, and, when the repository is
  a worktree with no `.godot/` import cache, say that is the usual cause --
  that is the specific failure this has cost the most time to.
- **Contract.** Record the new failure class in
  `docs/headless-run-contract.md` so a scenario author knows a run can now
  fail this way.
- **Proof it worked.** Introduce a deliberate parse error in a script, run a
  scenario, and the run fails naming the script and the error rather than
  writing a session file of zeroes. Revert.
- **Completion.** Archive this plan with `Next: None — plan complete`.

Level: medium -- a bounded change to a shared tool with an acceptance check.
