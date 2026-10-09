# Workflow checks -- say what a waiting lane is waiting for, and catch latent tooling drift

<!-- CONTEXT: plan | LAYER: immediate-task -->
Status: active | Owner: Dave / Codex | Next: WC-4 -- a queue id with whitespace fails the documentation check, in the Codex lane | Dependency: WC-1, WC-3 and WC-5 landed; WC-4 follows WC-2 because both edit `tools/check_docs.py` | Verified: 2026-10-09

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

WC-2 shipped 2026-10-09; its specification is `plans/archive/WC-2_2026-10-09.md`.

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

```queue
**[Codex] WC-4 -- a queue id with whitespace fails the documentation check**
- Plan: `plans/now/workflow-checks.md` -- "WC-4 -- a queue id with whitespace fails the documentation check"
- Files: `tools/check_docs.py`, `tests/test_wc4_spaced_ids.py`
- Check: `python -m unittest tests.test_wc4_spaced_ids` passes; `python tools/check_docs.py` passes on master; `tools/verify.ps1` is green
- Proof: `absent: tools/check_docs.py :: id contains whitespace`
- Next after: none -- workflow checks are complete
```

WC-5 shipped 2026-10-09; its specification is `plans/archive/WC-5_2026-10-09.md`.
