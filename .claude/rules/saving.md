---
paths:
  - "scripts/saving.gd"
  - "scripts/save_game.gd"
  - "scripts/save_migrations.gd"
  - "scripts/tutorial_checkpoint.gd"
  - "scripts/challenge_runner.gd"
---

# Save/restore safety

On-demand background and completed writeups: `plans/reference/technical-audit.md`
and `plans/archive/AUDIT_PLAN_AUG_2026.md` Bundles A and B.

**Restore is all-or-nothing.** A save either fails validation and
changes nothing, or succeeds and leaves every collection, index,
cross-reference and UI readout mutually consistent. `SaveGame.read()`
rejects (returns `{}`, `push_error`, no world mutation) a save whose
`version` is newer than `FORMAT_VERSION` — don't weaken that check, and
don't build a migration framework for older versions beyond the existing
defensive-restore behaviour without a concrete second format to bridge.

**`queue_free()` is deferred, not immediate.** Godot doesn't remove a
freed node from the tree or its groups until end of frame, so a
`get_nodes_in_group(...)` call taken mid-restore can catch old and new
objects together. `_restore_flowers()`/`_restore_bees()` in `saving.gd`
return the explicit array of nodes they just created — pass that
straight to `flower_grid.rebuild()` / population readouts instead of
re-querying a group afterwards. Use `_retire_node(node, group_name)`
(removes from group and parent, then `queue_free()`) for any restore
path that still wants to iterate old nodes before disposal.

**Ordinary player save/load is unavailable during an active
Challenge.** `SaveGame` doesn't record Challenge stage/gate/prompt
state, so a load mid-Challenge would silently drop it.
`debug_panel.gd::set_save_load_enabled(false)` is called from
`challenge_runner.gd::start()` and re-enabled in `_complete()` — don't
bypass this without also giving `SaveGame` a Challenge-aware schema
first (see `DESIGN_BACKLOG.md` §11 for the deferred alternative).

**`TutorialCheckpoint.clear()` runs once, near the top of
`main.gd::_ready()`**, because every Challenge exit path (menu, restart,
load, post-game-over restart) already reloads the scene. If a future
exit path is added that *doesn't* reload the scene, it needs its own
explicit `clear()` call — don't assume the boot-time clear covers it.

**`GameConfig` writes are allowlisted.** Only `game_config.gd`,
`debug_panel.gd`, `save_game.gd` and `levels.gd` may assign into
`GameConfig` fields — `tests/source_checks.py`'s
`check_gameconfig_writes` enforces this. A Challenge-local override
(e.g. a fast build time) belongs on the object it affects (see
`HiveCell.build_time_override`/`effective_build_time()`), never on the
shared autoload.
