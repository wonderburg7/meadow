# Workflow checks -- say what a waiting lane is waiting for, and catch latent tooling drift

<!-- CONTEXT: plan | LAYER: immediate-task -->
Status: active | Owner: Dave / Codex | Next: WC-2 -- a dry-lane warning names the missing deferral and the specified blocks that could serve the lane, in the Codex lane | Dependency: WC-1 and WC-3 landed; WC-4 follows WC-2 because both edit `tools/check_docs.py`; WC-5 is ready to close | Verified: 2026-10-09

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

Verified 9 Oct 2026 against master `4ca584c`:

- `NEXTSTEPS.md`'s "Not in the queue, and why" names shipped gates including
  COL-4 and NF-1 for NF-2. `python tools/check_docs.py` now warns once per
  archived gate, while preserving an explicit `landed` or `shipped` note as
  historical context; `plans/README.md` rule 9 names that expiry rule.
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
| WC-2 | a dry-lane warning names the missing deferral and the specified blocks that could serve the lane | `tools/refill_lane.py`, `tools/check_docs.py`, `tests/test_wc2_dry_lane_report.py` | yes -- WC-1 landed and the Codex lane has room | medium |
| WC-4 | a queue id with whitespace fails the documentation check | `tools/check_docs.py`, `tests/test_wc4_spaced_ids.py` | after WC-2 and room in the Codex lane | low |

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

WC-1 shipped 2026-10-09; its specification is `plans/archive/WC-1_2026-10-09.md`.

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

```queue
**[Codex] WC-2 -- a dry-lane warning names the missing deferral and the specified blocks that could serve the lane**
- Plan: `plans/now/workflow-checks.md` -- "WC-2 -- a dry-lane warning names the missing deferral and the specified blocks that could serve the lane"
- Files: `tools/refill_lane.py`, `tools/check_docs.py`, `tests/test_wc2_dry_lane_report.py`
- Check: `python -m unittest tests.test_wc2_dry_lane_report` passes (an undeferred successor is named; a file-disjoint low/medium other-lane block is listed as borrowable; a high-level, gated, colliding or already-queued one is not; the existing keys are unchanged); `python -m unittest tests.test_slice_lifecycle` passes; `tools/verify.ps1` is green
- Proof: `absent: tools/refill_lane.py :: borrowable`
- Next after: WC-4 -- a queue id with whitespace fails the documentation check
```

WC-3 shipped 2026-10-09; its specification is `plans/archive/WC-3_2026-10-09.md`.

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

WC-5 shipped 2026-10-09; its specification is `plans/archive/WC-5_2026-10-09.md`.
