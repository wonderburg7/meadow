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
`version` is newer than `FORMAT_VERSION` — don't weaken that check.
Older versions are bridged one step at a time in `save_migrations.gd`.

**A new field is additive unless an old save would load wrong without it**
(Dave, 7 Oct 2026, save review). Add it with a `.get()` default that matches
how an old save behaved, with no `FORMAT_VERSION` bump and no migration, as
CR-1's `starting_level` and BS-14's `skill_policy` did. Bump and add a
`_migrate_N_to_N+1` step only when a field's meaning or shape changes.

**A loaded run keeps its readout history** (Dave, 16 Oct 2026, UI review D1).
`history_samples`, `emergence_log`, `day_store_totals` and the foraging
counters in `foraging_stats.gd` are saved under one additive `readout_history`
key, so the colony graphs, the nursery's recent-emergence figures, the
net-income condition and the foraging window continue across a load. An old
save has no key and starts them empty, as before (slice RR-12 in
`plans/now/run-repairs.md`; it lands after the alpha chain releases the save files).

**A checkpoint restore is exact** (Dave, 7 Oct 2026, save review). An
in-place `_restore` (Challenge 2's rollback, the `restore_slot` scenario
action) must leave the world as the checkpoint recorded it, soil included,
not merely remove what the checkpoint lacks.

**A save survives its own round-trip** (CQ-S0, 22 Oct 2026). `python -m
unittest tests.test_save_roundtrip` runs `tests/save_roundtrip_test.gd`: it
replays each golden in `tests/fixtures/saves/` by the load route and by an
in-place `saving._restore`, re-saves it in the same frame and compares the two
as canonical JSON, then loads and re-saves `save_v1.json`, `save_v2.json` and a
v6 save. Refactoring the save code leaves the goldens untouched; only a
deliberate format change recaptures them, from `test_scenarios/cq_s0_*_capture.json`
(the test's docstring says how). A difference a route makes today is named in
the test's `KNOWN_DIFFERENCES` and escalated to Dave, never silently accepted:
one stands now -- with orientation flight on, a bee switched into Forager and
saved before her first trip gains a start point on reload.

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
first (see `DESIGN_BACKLOG.md`, "Deferred product decisions", for the deferred
alternative).

**`TutorialCheckpoint.clear()` runs once, near the top of
`main.gd::_ready()`**, because every Challenge exit path (menu, restart,
load, post-game-over restart) already reloads the scene. If a future
exit path is added that *doesn't* reload the scene, it needs its own
explicit `clear()` call — don't assume the boot-time clear covers it.

**`GameConfig` writes are allowlisted.** The allowlist lives in one place,
`GAMECONFIG_WRITE_ALLOWLIST` in `tests/source_checks.py`, and
`check_gameconfig_writes` enforces it -- read the list there rather than
from a copy here. A Challenge-local override
(e.g. a fast build time) belongs on the object it affects (see
`HiveCell.build_time_override`/`effective_build_time()`), never on the
shared autoload.
