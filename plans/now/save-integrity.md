# Save integrity -- what a load must bring back, and a write that cannot half-finish

<!-- CONTEXT: plan | LAYER: immediate-task -->
Status: complete | Owner: Dave / Claude Code | Next: nothing further -- SI-1 to SI-3 landed | Dependency: none (shares `scripts/save_game.gd` and `scripts/saving.gd` with NF-2 in `plans/now/nectar-fermentation.md`, so never in the other lane at the same time) | Verified: 2026-10-09

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
| SI-3 | save, checkpoint and index writes are all-or-nothing | `scripts/save_slots.gd`, `scripts/save_game.gd`, `tests/si3_atomic_write_test.gd`, `tests/test_si3_atomic_write.py` | yes -- SI-2 landed 9 Oct 2026 | medium |

Dependencies: SI-1, SI-2 and SI-3 share `saving.gd`/`save_game.gd`, so they
run one after another in that order (most player-visible first). Each slice
reads only its own section below, plus `.claude/rules/saving.md`, which loads
itself. The GDScript test pattern to copy is
`tests/bs14_saved_skill_policy_test.gd` with its runner
`tests/test_bs14_saved_skill_policy.py` (boot `Main.tscn`, act, print
`<ID> PASS`, exit 0 or 1; the runner skips where no Godot is installed).

SI-1 shipped 2026-10-08; its specification is `plans/archive/SI-1_2026-10-08.md`.

SI-2 shipped 2026-10-09; its specification is `plans/archive/SI-2_2026-10-09.md`.

## SI-3 -- save, checkpoint and index writes are all-or-nothing

<!-- LAYER: immediate-task -->

Level: medium (one write helper, two readers and one headless test).

**True now.** `save_game.gd::save` and `save_slots.gd::_write_index` open
their target with `FileAccess.WRITE`, which empties it first, and neither
checks that `store_string` succeeded (it returns a bool in Godot 4.7). A
crash or full disk mid-write leaves a half file: a named save then reads as
"could not be read", and a half `index.json` reads as "no saves", so every
run vanishes from the Saves window although its files are still on disk.
`save()` also reports "Run saved." after a failed store.

**True afterwards.**
- `save_slots.gd` gains `static func write_atomic(path: String, text: String) -> bool`:
  write `path + ".tmp"`, return false (with `push_error`, after removing the
  `.tmp`) if the open or `store_string` fails, close it, then
  `DirAccess.rename_absolute(path + ".tmp", path)` and return whether that
  was `OK`. Godot's rename replaces an existing target.
- `save_game.gd::save` (preloading `save_slots.gd`) and
  `save_slots.gd::_write_index` write through it and return or report its
  result.
- `save_game.gd::read` and `save_slots.gd::_load_index_file`: when `path`
  does not exist but `path + ".tmp"` does, read that instead (a crash between
  the replace's remove and rename). A `.tmp` beside an existing target is
  ignored.
- `tutorial_checkpoint.gd` and `saving.gd` need no change: they call
  `SaveGame.save`.

**Must not change.** Paths, file names and the JSON written; `has_save`;
the legacy adoption in `_prepare`; `delete` (it does not need to remove a
`.tmp`, but may).

**Check.** `tests/si3_atomic_write_test.gd` (no world needed; `extends
SceneTree`, statics only) under `user://si3_test/`: `write_atomic` over an
existing file replaces it and leaves no `.tmp`; with a target and a garbage
`.tmp` beside it, `SaveGame.read` returns the target's contents; with only a
valid `.tmp`, `SaveGame.read` returns its contents; the same two cases for
`SaveSlots._load_index_file` with `SaveSlots.root` pointed at the test
folder (restore it after). Removes the folder at the end. Register
`tests.test_si3_atomic_write` in `$unitModules`.
`python -m unittest tests.test_si3_atomic_write` passes with `SI3 PASS`, and
`python tools/run_scenario.py test_scenarios/sv1_named_saves_test.json`
still passes.

**Escalate** if `DirAccess.rename_absolute` does not replace an existing
file on Windows (then the choice between remove-then-rename and a backup
file is Dave's).

```queue
**[Claude] SI-3 -- save, checkpoint and index writes are all-or-nothing**
- Plan: `plans/now/save-integrity.md` -- "SI-3 -- save, checkpoint and index writes are all-or-nothing"
- Files: `scripts/save_slots.gd`, `scripts/save_game.gd`, `tests/si3_atomic_write_test.gd`, `tests/test_si3_atomic_write.py`
- Check: `python -m unittest tests.test_si3_atomic_write` passes with `SI3 PASS`; `python tools/run_scenario.py test_scenarios/sv1_named_saves_test.json` passes; `.\tools\verify.ps1` is green
- Proof: `absent: scripts/save_slots.gd :: write_atomic`
- Next after: none -- plans/now/save-integrity.md is complete once SI-3 lands
```
