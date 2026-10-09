# Workflow checks -- say what a waiting lane is waiting for, and catch latent tooling drift

<!-- CONTEXT: plan | LAYER: immediate-task -->
Status: active | Owner: Dave / Codex | Next: WC-1 -- a deferral whose gate has cleared is flagged, in the Codex lane | Dependency: none; WC-1 to WC-5 run in order in the Codex lane (WC-1, WC-2 and WC-4 share `tools/check_docs.py`) | Verified: 2026-10-07

## Objective

The Codex lane stalls in three ways: its last item cannot close because
nothing admissible follows it, its successor waits on a gate nobody
re-checks, or the gate it names has already cleared. This plan makes the
tooling say which of those is true, and with what to do, before a session
reaches `finish`. It also clears three latent tooling defects that were
logged as untriaged signals in `plans/observations/system-improvement-signals.md`.

Nothing here changes a queue rule, lowers a floor, reassigns a slice
between lanes, or changes `NEXTSTEPS.md`'s or a `queue` block's format
(`plans/now/agent-lifecycle.md`, "Standing rules": extend the parsers, never
the formats). Each slice adds a warning, an error for a shape that already
cannot work, or a test.

## Current state

Verified 7 Oct 2026 against master `27b645e`:

- `NEXTSTEPS.md`'s "Not in the queue, and why" names COL-4 as the gate for
  NF-2, T2-5 to T2-7, BB-1 and the event director, and NF-1 for NF-2. Both
  shipped (`plans/archive/COL-4_2026-10-07.md`,
  `plans/archive/NF-1_2026-10-06.md`); `python tools/check_docs.py` says
  nothing. `plans/README.md` rule 9 says it warns about the archived-id case,
  but `check_queue_ids_are_unused` covers queued ids only.
- `refill_lane.py --delete AR-3 --top-up --lane Codex --dry-run` refuses
  with "no [Codex] item -- both lanes must have work", and
  `check_queue_lookahead`'s warning says only "specify the owning plan's next
  slice". It does not say that AR-3's successor, AR-4, is missing from
  "Not in the queue, and why" (the refill gate's second requirement). It
  does not name specified blocks elsewhere that could serve the lane. This is
  the third time a lone Codex item has blocked its own `finish` (PERF-3,
  UI-F-3, AR-3; signal of 1 Oct 2026).
- `.git/meadow-diagnostics.jsonl` holds 168 events on `codex/*` branches,
  every one script-emitted (`verify_stage`, `slice_claimed`,
  `slice_finished`) and none from a hook (`session_start`, `session_end`,
  `tool_bash`). Every `.codex/hooks.json` command calls
  `python "$CLAUDE_PROJECT_DIR/tools/hook_log.py"`.
- `check_docs.py` accepts a queue id containing a space, which
  `slice.ps1 start` would turn into a branch and worktree path with spaces.
- `tools/session_cost.py::LEVEL_MODELS` mirrors `slice.ps1::Get-SliceAdvice`'s
  `switch` by hand, with no test comparing them.

## Open slices

| Slice | What it does | Files it owns | Startable | Level |
| --- | --- | --- | --- | --- |
| WC-1 | a deferral whose gate has cleared is flagged | `tools/check_docs.py`, `tests/test_wc1_stale_deferrals.py` | in the Codex lane (queued 9 Oct 2026, after T2-4a landed) | medium |
| WC-2 | a dry-lane warning names the missing deferral and the specified blocks that could serve the lane | `tools/refill_lane.py`, `tools/check_docs.py`, `tests/test_wc2_dry_lane_report.py` | after WC-1 and room in the Codex lane | medium |
| WC-3 | Codex's hooks log its sessions | `.codex/hooks.json`, `tests/test_wc3_codex_hooks.py` | in the Codex lane (queued 9 Oct 2026, after T2-4a landed) | medium |
| WC-4 | a queue id with whitespace fails the documentation check | `tools/check_docs.py`, `tests/test_wc4_spaced_ids.py` | after WC-2 and room in the Codex lane | low |
| WC-5 | the two level-to-model tables are tested against each other | `tools/session_cost.py`, `tests/test_wc5_level_model_parity.py` | yes -- the Codex lane has room (9 Oct 2026) | low |

**Dependencies.** WC-1, WC-2 and WC-4 edit `tools/check_docs.py` and run in
that order; WC-3 and WC-5 depend on nothing. None edits `tools/slice.ps1`,
so each can be built and tested in any session. WC-5 shares `tools/session_cost.py` with CX-1 (`plans/now/coordinator-context.md`, Claude lane); `refill_lane.py` refuses to queue both at once. `tools/check_docs.py` and
`tools/refill_lane.py` are lifecycle tooling owned by
`plans/now/agent-lifecycle.md`, which has no open slice; it points here.

**Queue state.** The current Codex lane retains the higher-priority
gameplay, save-integrity and Tier-two slices already on `master`; every block
below is deliberately gated until a lane slot opens.

**Reads.** A slice reads its own section below and the functions it names
(`python tools/func.py <file> <function>`), nothing else.

## WC-1 -- a deferral whose gate has cleared is flagged

<!-- LAYER: immediate-task -->

Level: medium (a regex over prose with one deliberate exemption).

**True now.** A bullet under `NEXTSTEPS.md`'s "Not in the queue, and why"
can keep naming a slice as its gate long after that slice shipped; nothing
compares the ids in a bullet's reason with `plans/archive/`.

**True afterwards.** A new `check_docs.py` function, called from `main()`
beside `check_not_in_queue_reasons`, warns once per bullet for each id in
the bullet's reason (the text after its bolded lead) that has a
`plans/archive/<id>_*.md` record. The warning contains `waits for a shipped
slice` and names the id, its archive file and the bullet's lead, and points
at `plans/README.md` rule 9. An id followed within its clause by `landed` or
`shipped` is exempt, because that sentence already records the gate as
cleared. The id pattern matches the ids the queue uses (`COL-4`, `T2-4a`,
`NF-1`, `L-24`). The test builds a temporary root with a `NEXTSTEPS.md` and
archive files and proves: a stale gate warns; an unshipped gate does not;
"T2-2 landed 7 Oct 2026" does not; the bolded lead's own id is never checked.

**Must not change.** It is a warning, never an error: a shipped gate can
still be a correct historical pointer in a sentence this rule cannot read.
Do not edit the existing bullets to make the warning quiet; their owning
plans re-verify their gates.

```queue
**[Codex] WC-1 -- a deferral whose gate has cleared is flagged**
- Plan: `plans/now/workflow-checks.md` -- "WC-1 -- a deferral whose gate has cleared is flagged"
- Files: `tools/check_docs.py`, `tests/test_wc1_stale_deferrals.py`
- Check: `python -m unittest tests.test_wc1_stale_deferrals` passes (a stale gate warns, an unshipped gate and a "landed" clause do not); `python tools/check_docs.py` on master prints the warning for NF-2's COL-4 and NF-1; `tools/verify.ps1` is green
- Proof: `absent: tools/check_docs.py :: waits for an archived slice`
- Next after: WC-2 -- a dry-lane warning names the missing deferral and the specified blocks that could serve the lane
```

## WC-2 -- a dry-lane warning names the missing deferral and the specified blocks that could serve the lane

<!-- LAYER: immediate-task -->

Level: medium (extends L-18's `dry_after_report` and L-24's lookahead; slice.ps1 reads the same report).

**True now.** `refill_lane.dry_after_report` returns `dry_after`, the ids
the top-up would add, and the lane's gated ids. `check_queue_lookahead`
turns it into one sentence that does not say what would clear it.

**True afterwards.** `dry_after_report` gains three additive keys:
`successor` (the closing item's `Next after:` id, or empty for
`none -- ... complete`), `successor_deferred` (whether that id leads a
bullet under "Not in the queue, and why", by the rule `finish`'s refill gate
uses) and `borrowable`. `borrowable` lists the other lane's backlog blocks
that are fenced `queue`, not queued, not deferred, whose proof holds, whose
plan states level low or medium, and whose files appear in no item of the
other lane. Each entry has its id, its plan and its level. `top_up`'s short-lane log and
`check_queue_lookahead`'s warning print all three: "AR-4 is neither queued
nor deferred -- add its bullet", and "the Claude backlog holds T2-4a
(medium) that this lane could take if Dave reassigns it". The warning says
that reassignment is Dave's decision; nothing here retags a block.

**Must not change.** The keys `dry_after`, `gated`, `lane_after`,
`queue_after` and `would_add` keep their meaning, because `slice.ps1`'s
`Get-SliceDryAfter` reads them. No block is moved or retagged by any code
path.

```queue-gated
**[Codex] WC-2 -- a dry-lane warning names the missing deferral and the specified blocks that could serve the lane**
- Plan: `plans/now/workflow-checks.md` -- "WC-2 -- a dry-lane warning names the missing deferral and the specified blocks that could serve the lane"
- Files: `tools/refill_lane.py`, `tools/check_docs.py`, `tests/test_wc2_dry_lane_report.py`
- Check: `python -m unittest tests.test_wc2_dry_lane_report` passes (an undeferred successor is named; a file-disjoint low/medium other-lane block is listed as borrowable; a high-level, gated, colliding or already-queued one is not; the existing keys are unchanged); `python -m unittest tests.test_slice_lifecycle` passes; `tools/verify.ps1` is green
- Proof: `absent: tools/refill_lane.py :: borrowable`
- Next after: WC-3 -- Codex's hooks log its sessions
```

## WC-3 -- Codex's hooks log its sessions

<!-- LAYER: immediate-task -->

Level: medium (an environment fault diagnosed from evidence, with a mechanical fix).

**True now.** No hook event has ever been logged from a `codex/*` branch
(see "Current state"). Every `.codex/hooks.json` command names
`$CLAUDE_PROJECT_DIR`, which `.claude/settings.json` can rely on and Codex
may not set; with it empty the command runs `python "/tools/hook_log.py"`.

**True afterwards.** Every `.codex/hooks.json` command finds
`tools/hook_log.py` without `CLAUDE_PROJECT_DIR`, by a form Codex resolves
on Windows (`tools/hook_log.py` already takes the event's root from the
payload's `cwd`). The test reads `.codex/hooks.json`, asserts no command
names `CLAUDE_PROJECT_DIR`, and runs each `session_start`/`session_end`
command from a temporary Git checkout holding a copy of `tools/hook_log.py`,
with the variable unset, finding the event in that checkout's log. Record
the cause found in this section. Hooks load at session start, so the live
confirmation is the next Codex session's own `session_start` event under
`python tools/session_cost.py --events`. That is a reading for the next
agent-workflow review, not a gate on this slice. If Codex does not run
`.codex/hooks.json` at all, stop: say so in the plan with the evidence, and
leave the file unchanged.

**Must not change.** `.claude/settings.json`'s hooks; `tools/hook_log.py`'s
event shape; what is logged (one command token, never a command line).

```queue
**[Codex] WC-3 -- Codex's hooks log its sessions**
- Plan: `plans/now/workflow-checks.md` -- "WC-3 -- Codex's hooks log its sessions"
- Files: `.codex/hooks.json`, `tests/test_wc3_codex_hooks.py`
- Check: `python -m unittest tests.test_wc3_codex_hooks` passes with `CLAUDE_PROJECT_DIR` unset; `tools/verify.ps1` is green
- Proof: `present: .codex/hooks.json :: $CLAUDE_PROJECT_DIR/tools/hook_log.py`
- Next after: WC-4 -- a queue id with whitespace fails the documentation check
```

## WC-4 -- a queue id with whitespace fails the documentation check

<!-- LAYER: immediate-task -->

Level: low (one validation and its test).

**True now.** `check_docs.py` accepts a `**[Lane] <id> -- <title>**` line
whose id contains a space, in `NEXTSTEPS.md` and in a plan's `queue` or
`queue-gated` block; `slice.ps1 start` would build `git branch <lane>/<id>`
and `.worktrees/<id>` from it (signal of 7 Oct 2026).

**True afterwards.** Both places fail with an error containing
`id contains whitespace`, naming the item or the plan. The test covers a
spaced id in each place and a hyphenated one that passes.

**Must not change.** `Get-NextUpItems`'s parsing in `tools/slice.ps1`.

```queue-gated
**[Codex] WC-4 -- a queue id with whitespace fails the documentation check**
- Plan: `plans/now/workflow-checks.md` -- "WC-4 -- a queue id with whitespace fails the documentation check"
- Files: `tools/check_docs.py`, `tests/test_wc4_spaced_ids.py`
- Check: `python -m unittest tests.test_wc4_spaced_ids` passes; `python tools/check_docs.py` passes on master; `tools/verify.ps1` is green
- Proof: `absent: tools/check_docs.py :: id contains whitespace`
- Next after: WC-5 -- the two level-to-model tables are tested against each other
```

## WC-5 -- the two level-to-model tables are tested against each other

<!-- LAYER: immediate-task -->

Level: low (one parity test and a comment).

**True now.** `session_cost.py::LEVEL_MODELS` says it "mirrors
Get-SliceAdvice"; nothing fails when the two disagree.

**True afterwards.** A test reads the Claude-lane `switch` in
`tools/slice.ps1::Get-SliceAdvice` with a regex and asserts that each of
`high`, `medium` and `low` names a model that starts with an entry of
`LEVEL_MODELS[level]`. It fails with both values when they drift. The
comment above `LEVEL_MODELS` names the test instead of the word "mirrors".

**Must not change.** Either table's values; `tools/slice.ps1`.

```queue
**[Codex] WC-5 -- the two level-to-model tables are tested against each other**
- Plan: `plans/now/workflow-checks.md` -- "WC-5 -- the two level-to-model tables are tested against each other"
- Files: `tools/session_cost.py`, `tests/test_wc5_level_model_parity.py`
- Check: `python -m unittest tests.test_wc5_level_model_parity` passes, and fails when one `LEVEL_MODELS` entry is edited by hand; `tools/verify.ps1` is green
- Proof: `present: tools/session_cost.py :: mirrors Get-SliceAdvice in`
- Next after: none -- plans/now/workflow-checks.md is complete
```
