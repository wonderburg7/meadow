# Workflow diagnostics — the log that says where the system loses time and tokens

<!-- CONTEXT: plan | LAYER: immediate-task -->
Status: complete | Owner: Dave / Claude Code | Next: None -- plan complete; every kind in `tools/diagnostics.py`'s `KINDS` has a writer and `--events` reads them all | Dependency: none | Verified: 2026-09-18

**Objective.** A review of how the development system itself is running --
which automation stops, which check fails, what a slice costs -- should be a
one-command query over recorded events, not an archaeology session over
transcripts. Scripts write every event, so measuring costs the model nothing
until someone asks.

**Not the colony diagnostic log.** `scripts/diagnostic_log.gd` and
`plans/reference/colony-diagnostics.md` record what the bees did. This plan is
the development workflow and touches no game code; they never share a file.

**State.** WD-0 (17 Sep 2026) built the spine: `tools/diagnostics.ps1` and
`tools/diagnostics.py` append one JSON object per line to
`<git-common-dir>/meadow-diagnostics.jsonl`, and
`python tools/session_cost.py --events` prints the summary. Every kind in
`tools/diagnostics.py`'s `KINDS` now has a writer: `slice_claimed`,
`slice_finished` (`tools/slice.ps1`), `verify_stage` (`tools/verify.ps1`),
`session_start`/`session_end` (`tools/hook_log.py` via `.claude/settings.json`),
`headless_run` (WD-1, `tools/run_scenario.py`), `env_capability` (WD-2,
`slice doctor`) and `tool_bash` (WD-4, `tools/hook_log.py` from PostToolUse and PostToolUseFailure);
`--events` also joins each claimed slice's plan level to the models its
sessions ran at (WD-3). Records: `plans/archive/WD-0_2026-09-17.md`,
`plans/archive/WD-1_2026-09-18.md`, `plans/archive/WD-2_2026-09-18.md`
(its `doctor` check passed on Windows on 18 Sep 2026),
`plans/archive/WD-3_2026-09-18.md`, `plans/archive/WD-4_2026-09-18.md`.

**This log does not record stops.** `tools/slice.ps1` writes them to its own
`meadow-slice-stops.jsonl` and `python tools/session_cost.py --stops` tallies
them by step; `plans/now/agent-lifecycle.md`'s L-12 is gated on that output.
No slice here may add a `slice_stop` kind, move that ledger, or change
`--stops`.

**Against `plans/now/agent-lifecycle.md`.** That plan owns
`tools/session_cost.py`'s `--days`, `--classify`, `--phases` and `--stops`
and the open slices L-12 and L-13. This plan owns `--events` and changes none
of them.

## Open slices at a glance

None open. WD-0 to WD-4 have all shipped; their records are the
`plans/archive/WD-*_2026-09-1*.md` files named above. A new finding against
the workflow log starts a fresh `plans/now/` file rather than reopening this
one (`plans/README.md`). **Do not change** the event schema (`ts`, `kind`,
then the caller's own fields) or the file's location, and the writer never
fails its caller.

WD-4 shipped 2026-09-18; its specification is `plans/archive/WD-4_2026-09-18.md`.

