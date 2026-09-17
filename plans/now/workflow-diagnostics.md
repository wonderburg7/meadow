# Workflow diagnostics — the log that says where the system loses time and tokens

<!-- CONTEXT: plan | LAYER: immediate-task -->
Status: active | Owner: Dave / Claude Code | Next: WD-1 -- a headless run records what it cost and whether it worked | Dependency: none -- WD-0 shipped 17 Sep 2026 | Verified: 2026-09-17

**Objective.** A review of how the development system itself is running --
which automation stops, which check fails, what a slice costs -- should be a
one-command query over recorded events, not an archaeology session over
transcripts. Scripts write every event, so measuring costs the model nothing
until someone asks.

**Not the colony diagnostic log.** `scripts/diagnostic_log.gd` and
`plans/reference/colony-diagnostics.md` record what the bees did. This plan is
the development workflow and touches no game code; they never share a file.

**State.** WD-0 shipped 17 September 2026 and built the spine:
`tools/diagnostics.ps1` and `tools/diagnostics.py` append one JSON object per
line to `<git-common-dir>/meadow-diagnostics.jsonl`; `tools/slice.ps1` records
`slice_claimed` and `slice_finished`; `tools/verify.ps1` records `verify_stage`
with a duration; `.claude/settings.json`'s SessionStart and Stop hooks record
`session_start`/`session_end` through `tools/hook_log.py`; and
`python tools/session_cost.py --events` prints the summary. Four of the eight
kinds in `tools/diagnostics.py`'s `KINDS` have no writer yet, and the four
slices below write them. Specification and outcome:
`plans/archive/WD-0_2026-09-17.md`.

**This log does not record stops.** `tools/slice.ps1` writes them to its own
`meadow-slice-stops.jsonl` and `python tools/session_cost.py --stops` tallies
them by step; `plans/now/agent-lifecycle.md`'s L-12 is gated on that output.
No slice here may add a `slice_stop` kind, move that ledger, or change
`--stops`. Two answers to "what stopped" is the outcome this plan exists to
avoid, not a redundancy worth having.

**Against `plans/now/agent-lifecycle.md`.** That plan owns
`tools/session_cost.py`'s `--days`, `--classify`, `--phases` and `--stops`,
the L-9 gate and the open slices L-10 to L-13. This plan adds `--events`
beside those and changes none of them. Where the two could overlap, that plan
wins: it was there first and its gates are written against its own numbers.
L-13 rewrites `tools/slice.ps1`'s closeout, so a slice here that touches that
file says so in its delivery note.

## Open slices at a glance

| Slice | Outcome | Files owned | Startable | Level |
| --- | --- | --- | --- | --- |
| WD-1 | Every headless scenario run records its fixture, verdict and wall time | `tools/run_scenario.py` | yes | low |
| WD-2 | `slice doctor` records which of the environment classes was in the way | `tools/slice.ps1` | yes | low |
| WD-3 | `--events` reports the model a slice was actually worked at against the level its plan states | `tools/session_cost.py` | yes | medium |
| WD-4 | Every Bash tool call records its exit status, at no token cost | `.claude/settings.json`, `tools/hook_log.py` | yes | medium |

The four are independent and may land in any order: each writes one event
kind and none reads another's. All depend only on WD-0, which has shipped.
None owns a file in either lane of `NEXTSTEPS.md` today.

**Read for any slice here:** this plan's own section, plus
`tools/diagnostics.py`'s module docstring and `KINDS`. Nothing else -- each
slice names the one function it changes, so neither `tools/slice.ps1` nor
`tools/session_cost.py` is ever read whole.

**Do not change** the event schema (`ts`, `kind`, then the caller's own
fields) or the file's location: both writers and the reader agree on it, and a
rename silently drops recorded history. Add a kind to `KINDS`; never rename
one. **And the writer never fails its caller** -- `Write-Diagnostic` and
`write_event` swallow every error by design, return nothing, and no slice here
may add a path where a logging failure stops a run.

## WD-1 — a headless run records what it cost and whether it worked

**Purpose.** A headless Godot run is the most expensive automated action in
the project and the one that fails silently: a worktree without the `.godot`
import cache reports a compile failure as a gameplay collapse
(`docs/known-pitfalls.md`). Nothing records how often runs fail, how long they
take, or which fixture is the slow one.

**Current state.** `run_verdict_scenario` in `tools/run_scenario.py` builds a
`result` dictionary, writes it with `_write_json(result_path, result)`, prints
one terminal line and returns. Nobody sees those numbers again unless they
open the result file.

**Change.** In `tools/run_scenario.py`:

1. After the existing `from pathlib import Path` (`sys` is already imported;
   if not, import it beside `time`):
   ```python
   sys.path.insert(0, str(Path(__file__).resolve().parent))
   from diagnostics import write_event
   ```
2. In `run_verdict_scenario`, immediately after `_write_json(result_path, result)`
   and before the `line = _terminal_line(` line:
   ```python
   write_event(
       "headless_run",
       fixture=Path(metadata["path"]).name,
       status=status,
       classification=classification,
       ms=int(result["process"]["wall_seconds"] * 1000),
       exit_code=returncode if returncode is not None else -1,
       ok=(status == "passed"),
   )
   ```

Change nothing else. Do not log from `run_baseline_probe` or
`run_experiment_manifest`: a manifest run calls `run_verdict_scenario` per
scenario, so logging the manifest too would double-count.

**Invariant.** A run's exit code, printed line and result file are what they
were before, byte for byte, and the event is written after the result file.

**Check.** `python tools/run_scenario.py test_scenarios/slice1_smoke_test.json`
then `python tools/session_cost.py --events` shows a `headless_run=1` entry
under `by kind`. Run it a second time and the count is 2. `.\tools\verify.ps1`
stays green.

**Level: low.** One import and one call at a named anchor.

## WD-2 — `slice doctor` records which of the environment classes was in the way

**Purpose.** `Get-GodotCapability` already classifies a Godot problem into one
of five named causes and `Get-DoctorEnvironmentFailures` lists the rest, but
both are printed and forgotten, so "how often does the environment rather than
the code block a session?" has no answer -- and it is the cheapest class of
problem to fix if the rate is high.

**Current state.** In `tools/slice.ps1`, `Invoke-SliceDoctor` computes
`$failures` from `Get-DoctorEnvironmentFailures`, prints them and exits 1 when
there are any; on the ready path it calls `Get-GodotCapability -Root $root`
inline inside the result hashtable.

**Change.** In `Invoke-SliceDoctor` only:

1. Immediately after the existing line
   `$failures = @(Get-DoctorEnvironmentFailures -Root $root -RequestedPythonPath $PythonPath)`,
   add:
   ```powershell
   $godotCapability = Get-GodotCapability -Root $root
   Write-Diagnostic -Root $root -Kind "env_capability" -Fields @{
       lane     = $Lane
       godot    = $godotCapability
       failures = $failures.Count
       ok       = ($failures.Count -eq 0)
       detail   = if ($failures.Count -gt 0) { ($failures[0] -split ':')[0] } else { "" }
   }
   ```
   `detail` is the text before the first colon of the first failure -- the
   category, never the path or message, which would grow the log without
   making it more answerable.
2. Replace the hashtable line `godot_capability = Get-GodotCapability -Root $root`
   with `godot_capability = $godotCapability`, so the probe runs once per
   `doctor` and not twice. It can boot Godot, so this matters.

**Invariant.** `doctor`'s JSON output and exit codes are unchanged, and it
performs no more Godot boots than before.

**Check.** `.\tools\slice.ps1 doctor -Lane Claude` then
`python tools/session_cost.py --events` shows `env_capability=1`. Run
`python -m unittest tests.test_slice_lifecycle tests.test_two_lane_closeout`
and it stays green -- those suites run `doctor` and assert on its JSON.

**Level: low.** Two edits in one function, both at named anchors.

## WD-3 — `--events` reports what a slice was worked at against what its plan asked for

**Purpose.** `CLAUDE.md` rule 4 says to take the level the plan states, and
that escalating past it is as much a mistake as ignoring it. Nothing can tell
whether that happens in either direction: the plan's level and the model
actually used are recorded in different places and never joined.

**Current state.** Every piece exists and none are joined. `slice_claimed`
carries `id`, `lane`, `branch` and `level` (what `Get-SliceLevel` read from
the owning plan); `session_start` carries `session` and `branch`; a transcript's
assistant rows carry `message.model`; and `_session_totals` in
`tools/session_cost.py` already walks those transcripts, keyed by session id.

**Change.** In `tools/session_cost.py` only:

1. Extend `_session_totals` to also collect the models seen: return
   `(requests, context, output, models)` where `models` is a `Counter` of each
   assistant row's `message.model` value, skipping rows with no model. Update
   its one existing caller in `run_events` to unpack four values and ignore
   the fourth where it is not needed.
2. Add a module-level mapping beside `PHASE_LABELS`, and a comment saying it
   mirrors `Get-SliceAdvice` in `tools/slice.ps1`, which is where the rule
   actually lives:
   ```python
   # The model each stated level asks for -- mirrors Get-SliceAdvice in
   # tools/slice.ps1. A model outside its level's entry is drift, in whichever
   # direction; CLAUDE.md rule 4 treats both as mistakes.
   LEVEL_MODELS = {
       "low": ("claude-sonnet-5", "claude-haiku-4-5"),
       "medium": ("claude-sonnet-5",),
       "high": ("claude-opus-5",),
   }
   ```
   Match a transcript's model against an entry by `startswith`, because a
   transcript records a dated id such as `claude-sonnet-5-20260401`.
3. Add a `level_drift` section at the end of `run_events`. For each
   `slice_claimed` event with a `level` in `LEVEL_MODELS`, find every
   `session_start` on the same `branch`, take those sessions' models, and
   print one line per slice where a model was used that its level does not
   allow:
   ```
   level drift (slice, plan level, models actually used)
     UI-W-2                          medium   claude-opus-5=31, claude-sonnet-5=4
   ```
   A slice whose level is `unstated`, or which joined no transcript, is
   counted in a trailing `not assessable: N` line rather than guessed at.
   Print `level drift               none` when every slice matches.

**Invariant.** `--days`, `--classify` and `--phases` print exactly what they
printed before; `plans/now/agent-lifecycle.md` owns those and L-9 published
their baselines. Only `--events` gains output.

**Check.** On a log with at least one `slice_claimed` event,
`python tools/session_cost.py --events` prints either the drift table or
`none`; with no such event it prints `not assessable: 0` and does not raise.
`.\tools\verify.ps1` stays green.

**Level: medium.** A join across three sources that can silently report
nothing, which is why the check distinguishes the empty case from the
matching one.

## WD-4 — every Bash tool call records its exit status, at no token cost

**Purpose.** The largest single category of wasted requests is a tool call
that fails and is retried in a slightly different form. `--classify` sees only
the ones a transcript makes obvious; a hook sees all of them, for free.

**Current state.** `.claude/settings.json` has `SessionStart` and `Stop`
hooks, both running `tools/hook_log.py`. There is no `PostToolUse` hook.
`tools/hook_log.py` accepts exactly `session_start` and `session_end` and
returns 0 for anything else.

**Change.**

1. In `tools/hook_log.py`, accept a third argument value, `tool_bash`. For it,
   read the hook's JSON payload from stdin and write:
   ```python
   write_event(
       "tool_bash",
       root=cwd,
       session=payload.get("session_id", ""),
       cmd=(payload.get("tool_input", {}) or {}).get("command", "").split()[0:1],
       ok=not (payload.get("tool_response", {}) or {}).get("is_error", False),
   )
   ```
   Record only the command's **first word** -- `git`, `python`, `grep`. A full
   command line can hold a file path or a commit message, would make the log
   grow by an order of magnitude, and answers no question the first word does
   not. Pass it as a string, not a list: use
   `command.split()[0] if command.split() else ""`.
2. Add to `.claude/settings.json`, beside the existing `SessionStart` and
   `Stop` entries:
   ```json
   "PostToolUse": [
     {
       "matcher": "Bash",
       "hooks": [
         {
           "type": "command",
           "command": "python \"$CLAUDE_PROJECT_DIR/tools/hook_log.py\" tool_bash",
           "timeout": 10
         }
       ]
     }
   ]
   ```
3. Change nothing in `tools/session_cost.py`. Its `by kind` line already
   reports any kind it finds, which is the whole reader this slice needs.

**The one rule this slice must not break.** The hook prints nothing to stdout
and exits 0 whatever happens. A `PostToolUse` hook's stdout is fed back into
the model's context on *every tool call*, so one stray `print` here would be
the most token-expensive line in the repository. `tools/hook_log.py`'s
docstring already says so; keep it true.

**Volume.** Unlike the others this kind is written hundreds of times a
session. `tools/diagnostics.py`'s 1 MB rotation is what makes that safe; do
not raise `MAX_BYTES` to keep more history.

**Check.** With the hook added, start a session and run `git status` and
`git nosuchcommand`. `python tools/session_cost.py --events` then shows
`tool_bash=2`, and the session's transcript contains no hook output -- which
is the proof the token cost is nil. `.\tools\verify.ps1` stays green.

**Level: medium.** A small change, but the only one here that can cost tokens
if got wrong, and it edits the harness configuration.
