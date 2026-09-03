# Agent workflow W-7 -- `verify.ps1` is quiet on success

Delivered 3 Sep 2026. Full spec was `plans/now/agent-workflow.md`'s "W-7 --
`verify.ps1` is quiet on success"; that plan is complete and now lives at
`plans/archive/AGENT_WORKFLOW_2026-09-03.md`.

## What landed

`tools/verify.ps1` gained two switches. Nothing about what any stage checks
changed, and a plain `.\tools\verify.ps1` prints exactly what it always did.

- **`-Quiet`** captures each stage and prints one line per stage --
  `source checks: OK`, `balance tests: OK`, `function map: OK`,
  `doc checks: OK`. A stage that fails prints `<stage>: FAILED` followed by
  everything it printed, so nothing is lost by being quiet on success.
- **`-Docs`** runs `tools/check_docs.py` alone and skips the source, balance
  and function-map stages. It completes in about 0.8s against roughly 12s for
  a full run, which is what makes a documentation-only pass cheap to re-check.
- A failing doc stage is headed `doc checks: FAILED (planning/ledger, not
  code)`. That is the point of the slice: the corpus's most common error
  signature was `verify.ps1` exiting 1 after both code suites passed, which
  read as a code failure. Under `-Quiet` the three `OK` lines sit directly
  above the heading, so the distinction is visible in one screen.

## Shape of the change

Two helpers carry the switch behaviour so the no-switch path stays literally
the one that was there before:

- `Write-StageResult` prints the `OK` line under `-Quiet`, and the `FAILED`
  heading whenever either switch was passed. With no switch it prints nothing
  -- the stage has already streamed its own output.
- `Invoke-PythonStage` runs one Python check, capturing its output only under
  `-Quiet`. The capture sets `$ErrorActionPreference = "Continue"` for the
  duration: in Windows PowerShell 5.1, redirecting a native command's stderr
  with `2>&1` under `"Stop"` turns each stderr line into a terminating
  `NativeCommandError`, which would abort the run before the captured output
  could be replayed.

The two concurrent jobs keep their existing structure; only the branch that
receives them is new.

## Evidence

Run in the `claude/W-7` worktree, 3 Sep 2026:

- no switch: full source, balance, function-map and doc output, unchanged.
- `-Quiet`, all green: four `OK` lines and nothing else, exit 0.
- `-Quiet` with a deliberately broken `plans/workstreams.md` row in the
  primary checkout: the three code stages print `OK`, then `doc checks:
  FAILED (planning/ledger, not code)` followed by both stale-row errors and
  the two standing warnings in full. Exit 1.
- `-Docs`: 0.81s against roughly 12s for a full run, code suites skipped,
  `check_docs.py` output followed by the labelled heading.

## Follow-ups

None. `tools/slice.ps1 finish` already passed `-Quiet` when the parameter
existed, so closeout picked the switch up with no change to `slice.ps1`.
