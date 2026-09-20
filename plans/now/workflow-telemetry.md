# Workflow telemetry — make the instruments answer the questions they were built for

<!-- CONTEXT: plan | LAYER: immediate-task -->
Status: active | Owner: Dave / Codex | Next: T-2 -- level drift joins on something that exists, queued in the Codex lane behind L-14 | Dependency: none | Verified: 2026-09-20

**Objective.** `plans/now/agent-lifecycle.md` sets a measured target -- raise
the implementing share of a session's context above 40% -- and every decision
about how to get there is read off `tools/session_cost.py`. Three of its
readouts are silently empty or wrong, so the decisions they were built to
support are being taken blind. Fix the instruments, not the numbers.

**State.** Measured on 20 Sep 2026 from `.git/meadow-diagnostics.jsonl`,
1220 records, and `python tools/session_cost.py --events`:

- **`tool_bash` records `cd`.** 519 of 551 `tool_bash` records have
  `cmd` = `cd`. `tools/hook_log.py` stores `words[0]` of the command on the
  stated assumption that "the first word answers no question the first word
  does not"; in a worktree every Bash call is prefixed `cd <path> && ...`, so
  the first word is the shell prelude 94% of the time. `--events`' one
  derived line is `failing commands cd=10`.
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
| T-2 | `--events` reports level drift for real slices instead of `not assessable: 12` | `tools/slice.ps1`, `tools/session_cost.py`, `tests/test_source_checks.py` | yes | medium |
| T-1 | `tool_bash` records the command that ran, not the `cd` in front of it | `tools/hook_log.py`, `tools/session_cost.py`, `tests/test_source_checks.py` | yes | medium |
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

## T-2 — level drift joins on something that exists

`_print_level_drift` in `tools/session_cost.py` joins a claim to its sessions
by branch name. It cannot work: `tools/slice.ps1` writes `slice_claimed` with
the branch it just created for the slice, and `tools/hook_log.py` writes
`session_start` with the branch the session's own cwd is on, which is the
session branch the harness made. WD-3's readout has therefore been `none`
since it shipped, and that `none` reads as "no drift" rather than "no data".

Give the join a key that both sides have. Fixed now:

- **Invariants.**
  - The JSONL schema stays append-only and backward compatible: an older
    record missing the new key still parses, and still counts as not
    assessable rather than raising.
  - A slice with no stated level is still counted, not guessed at.
  - `--events` still prints in one screen; this adds no new section.
- **Guidance, not decisions.** The cheapest key is the session id, which
  `hook_log.py` already writes on every record and which `slice.ps1` can
  learn from the same hook environment, or from the most recent
  `session_start` in the ledger at claim time. A worktree-path key or a
  time-window join are the alternatives; prefer whichever needs no new
  guessing, and say in the delivery note which you took and why.
- **Honesty about the past.** The 12 existing claims have no such key and
  cannot be repaired. Print `not assessable: N (before <date>)` for them, so
  the backlog of unjoinable records is visibly finite and shrinks.
- **Proof it worked.** Claim a slice, run a request, then
  `python tools/session_cost.py --events` names that slice under level drift
  or reports it assessed and in-level -- not `not assessable`.

Level: medium -- two writers and one reader, an acceptance check, no
ownership boundary moved.

## T-1 — `tool_bash` records the command that ran

`tools/hook_log.py` stores `words[0]` of each Bash command. Its comment says
the first word "answers no question the first word does not". The data
falsifies it: 519 of 551 records are `cd`, because CLAUDE.md's own convention
is that every command states its directory, so every call begins
`cd <worktree> && ...`.

Record the first word of the first **operative** segment instead. Fixed now:

- **Invariants.**
  - Still one short token, not the command line. No paths, no arguments, no
    commit messages, no URLs -- the reason the original stored one word is
    sound and does not change.
  - Still a PostToolUse hook with nil measurable cost; no extra process.
  - `tool_bash_failed` keeps recording the same field, so the failing-command
    tally improves with it.
- **What "operative" means.** Skip leading `cd <path>` segments and leading
  `NAME=value` assignments, then take the program. For `python`,
  `python3`, `powershell` and `pwsh`, take the script's basename too
  (`python tools/verify.ps1` -> `python verify.ps1`), because "which tool did
  the session run" is the question the field exists to answer and `python`
  alone does not answer it. Split on `&&`, `;` and `|` for the segment, and on
  nothing else -- do not attempt a shell parse.
- **Proof it worked.** Run a handful of ordinary worktree commands, then
  `python tools/session_cost.py --events`: `bash tool calls` is unchanged in
  count, and the failing-command tally names real programs. Re-reading the
  ledger a week later should show `cd` at a few per cent, not 94%.
- **Test.** Extend `tests/test_source_checks.py`'s existing `hook_log.py`
  cases with a `cd X && python tools/foo.py` payload and a
  `VAR=1 git status` payload.

Level: medium -- one extraction function and its tests, but the field feeds
every later cost query, so getting the token vocabulary right matters more
than the code does.

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
