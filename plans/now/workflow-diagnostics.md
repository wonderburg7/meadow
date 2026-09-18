# Workflow diagnostics — the log that says where the system loses time and tokens

<!-- CONTEXT: plan | LAYER: immediate-task -->
Status: active | Owner: Dave / Claude Code | Next: WD-4 -- Dave pastes the PostToolUse hook into .claude/settings.json | Dependency: none -- the hook script half of WD-4 landed 18 Sep 2026 | Verified: 2026-09-18

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
`slice doctor`) and `tool_bash` (WD-4's script half, `tools/hook_log.py`);
`--events` also joins each claimed slice's plan level to the models its
sessions ran at (WD-3). Records: `plans/archive/WD-0_2026-09-17.md`,
`plans/archive/WD-1_2026-09-18.md`, `plans/archive/WD-2_2026-09-18.md`
(its `doctor` check is still to be run on Windows -- see the record),
`plans/archive/WD-3_2026-09-18.md`.

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

| Slice | Outcome | Files owned | Startable | Level |
| --- | --- | --- | --- | --- |
| WD-4 | Every Bash tool call records its exit status, at no token cost | `.claude/settings.json` | Dave only -- see below | low |

**Read for the slice here:** this section. **Do not change** the event
schema (`ts`, `kind`, then the caller's own fields) or the file's location,
and the writer never fails its caller.

## WD-4 — every Bash tool call records its exit status, at no token cost

**Purpose.** The largest single category of wasted requests is a tool call
that fails and is retried in a slightly different form. `--classify` sees only
the ones a transcript makes obvious; a hook sees all of them, for free.

**What exists (18 Sep 2026).** `tools/hook_log.py` accepts `tool_bash`: it
reads the hook's JSON payload and writes one `tool_bash` event carrying the
session id, the command's **first word** only (`git`, `python`, `grep` -- a
full line can hold a path or a commit message and answers no question the
first word does not) and `ok`, false when the tool response reports an
error. It prints nothing and exits 0 on any input, including malformed JSON;
`tests/test_source_checks.py`'s `DiagnosticWritersTest` proves both.

**What remains, and why it is Dave's.** The hook is not wired: a Claude Code
session is refused edits to `.claude/settings.json` (the harness treats the
file as its own configuration), so the block below has to be pasted by hand.
In `.claude/settings.json`, inside `"hooks"`, after the `"Stop"` entry's
closing `]`, add a comma and then:

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

In the same file, under `"permissions"` → `"allow"`, after the
`"Bash(python tools/heading.py*)",` line, add the three closeout tools that
sessions now run so they stop producing permission prompts:

```json
      "Bash(python tools/func.py*)",
      "Bash(python tools/archive_slice.py*)",
      "Bash(python tools/refill_lane.py*)",
```

**The one rule this slice must not break.** The hook prints nothing to stdout
and exits 0 whatever happens. A `PostToolUse` hook's stdout is fed back into
the model's context on *every tool call*, so one stray `print` here would be
the most token-expensive line in the repository. `tools/hook_log.py`'s
docstring already says so; keep it true.

**Volume.** This kind is written hundreds of times a session.
`tools/diagnostics.py`'s 1 MB rotation is what makes that safe; do not raise
`MAX_BYTES` to keep more history.

**Check.** With the block pasted, start a session and run `git status` and
`git nosuchcommand`. `python tools/session_cost.py --events` then shows
`tool_bash=2`, and the session's transcript contains no hook output -- which
is the proof the token cost is nil. When that holds, move this section to
plans/archive/WD-4_(date).md, set this plan's `Next:` to
`None -- plan complete` and move the file to `plans/archive/`.

**Level: low.** A paste at a named anchor.
