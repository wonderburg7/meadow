# Save integrity -- what a load must bring back, and a write that cannot half-finish

<!-- CONTEXT: plan | LAYER: immediate-task -->
Status: complete | Owner: Dave / Claude Code | Next: nothing further -- SI-1 to SI-3 landed | Dependency: none (shares `scripts/save_game.gd` and `scripts/saving.gd` with NF-2 in `plans/archive/nectar-fermentation_2026-10-10.md`, so never in the other lane at the same time) | Verified: 2026-10-09

## Objective

Make a load put back every piece of run state the player can see change, make
Challenge 2's rollback exact, and make every save-family write all-or-nothing.
Found by the first save review (`docs/save-review-2026-10-07.md`). Dave's two
decisions from that review are in `.claude/rules/saving.md`: new fields are
additive with no `FORMAT_VERSION` bump, and a checkpoint restore is exact.

## Current state

Verified 7 Oct 2026 at `b9854e5`. `FORMAT_VERSION` is 6. A load replays
`SaveGame.save`'s dictionary onto a freshly built world (`saving.gd::_restore`);
Challenge 2's rollback and the `restore_slot` scenario action replay one over
the live world instead. Writes go straight to the target path with
`FileAccess.open(path, FileAccess.WRITE)`.

## Open slices

| Slice | What it does | Files it owns | Startable | Level |
| --- | --- | --- | --- | --- |

Dependencies: SI-1, SI-2 and SI-3 share `saving.gd`/`save_game.gd`, so they
run one after another in that order (most player-visible first). Each slice
reads only its own section below, plus `.claude/rules/saving.md`, which loads
itself. The GDScript test pattern to copy is
`tests/bs14_saved_skill_policy_test.gd` with its runner
`tests/test_bs14_saved_skill_policy.py` (boot `Main.tscn`, act, print
`<ID> PASS`, exit 0 or 1; the runner skips where no Godot is installed).

SI-1 shipped 2026-10-08; its specification is `plans/archive/SI-1_2026-10-08.md`.

SI-2 shipped 2026-10-09; its specification is `plans/archive/SI-2_2026-10-09.md`.

SI-3 shipped 2026-10-09; its specification is `plans/archive/SI-3_2026-10-09.md`.
