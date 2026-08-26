# Archived — recommendation Slice 2: fog relight

Status: implemented, pending integration | Branch: `codex/recommendation-slice-2` | Baseline: `59a00ab`

## Isolation record

Before editing, the primary `master` worktree at
`C:\Users\dl13860\Documents\Meadow\meadow` had only untracked
`.claude/settings.local.json` and `CHATGPT_RECOMMENDATION_SLICES.md`.
The predecessor worktree on `codex/recommendation-slice-0` was clean at
`59a00ab`; its committed Slice 0/1 work is the parent of this branch. This
dedicated worktree was clean before this slice, so no edited files overlap
the primary worktree's local files.

## Scope and result

Replace the moved-fog-disc membership scan with exact row-span differences;
preserve temporary-source reference counting and permanent exploration; make
radius changes remove old contributions before rebuilding the shared shape.
The persistent fog mask now writes lit as well as explored pixels.

## Verification

- `tests/source_checks.py`: passed (69 scripts).
- `python -m unittest tests.test_source_checks tests.test_headless_efficiency_baseline`: passed (8 tests).
- Pinned Slice-0 scenario: Godot loaded the scenario and ended with
  `performance_capture_complete` at day 1. The runner could not find the new
  `user://` JSONL in this desktop sandbox, so it could not emit the required
  performance table. Re-run the documented scenario in the integration
  environment before claiming a measured improvement.

## Manual acceptance

At target zoom with fog enabled, move a bee one tile horizontally and
diagonally; overlap two bees and send one indoors. There must be no flicker,
the remaining bee's coverage must stay lit, and both bees' departed coverage
must remain explored.
