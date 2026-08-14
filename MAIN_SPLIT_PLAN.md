# Splitting main.gd: what was done and why

Written 14 Aug 2026, same session the split shipped. Read this before
touching any of the six new files, or before splitting `bee.gd` next.

## What changed

`main.gd` was 2,825 lines. Six plain Nodes were pulled out of it --
`world_building.gd`, `saving.gd`, `input_selection.gd`, `orders_zones.gd`,
`year_winter.gd`, `camera_view.gd` -- each created in `main.gd::_ready()`
and kept as a field (`main.world_building`, and so on). None of them are
wired into `Main.tscn`; they're parented with `add_child()` at the top of
`_ready()`, the same way the HUD and cameras already were.

`main.gd` is now about 650 lines: field declarations, `_ready()`, the
per-frame dispatch (`_process` and what it calls directly), a handful of
small helpers several of the six files share, and a thin public-API layer
(below).

## The one rule that made this safe to do in one pass

**`main.gd` keeps every field and every method that anything outside the
split touches.** Nothing changed in `bee.gd`, `hud.gd`, `season.gd`,
`rival_hive.gd`, `hive.gd`, `hive_cell.gd`, `colony_panel.gd`,
`nursery_panel.gd`, `winter_panel.gd`, `main_menu.gd` or `debug_panel.gd`.

Two kinds of script reach into `main` from outside:

- `bee.gd` (and only `bee.gd`) holds `main` as `world` and calls six
  methods on it directly: `is_on_screen`, `hive_entrance_inside`,
  `move_bee_into_hive`, `move_bee_out_of_hive`, `mark_death`,
  `finish_mining`. It also reads `world.day`, `world.hive`,
  `world.hive_root`, `world.next_bee_id`, `world.obstacles`,
  `world.rain_seconds_left`, `world.rain_target`, `world.season`,
  `world.flower_grid` -- all still plain vars on `main.gd`.
- `debug_panel.gd` finds `main` via `get_tree().get_nodes_in_group("world")`
  and calls `save_run()` and `begin_winter_countdown()` on it.
- `season.gd` and `rival_hive.gd` hold `world` too, but only read vars
  (`world.hive`, `world.day`, `world.get_tree()`) -- no methods.

That's the whole external surface: eight methods, nine vars. `main.gd`
keeps all nine vars as-is, and keeps a one-line wrapper for each of the
eight methods, forwarding to whichever of the six files now holds the
real body:

```gdscript
func is_on_screen(node: Node2D) -> bool:
    return world_building.is_on_screen(node)
```

Grep `scripts/*.gd` for `world\.[a-zA-Z_]*` or `main\.[a-zA-Z_]*` (outside
`main.gd` itself) before ever removing one of these wrappers or renaming
a var main.gd still owns -- that grep *is* the external API, and it's
cheap to re-run to check it hasn't grown.

## The six files hold no state of their own

Every one of them is `extends Node` with a single `var main: Node2D`
field, set right after `.new()` in `main.gd::_ready()`. They read and
write `main`'s fields exactly the way `bee.gd` always has --
`main.selected_bees`, `main.hive`, `main.Bee.Role.FORAGER`, and so on --
rather than holding copies. Two small exceptions, both genuinely private
and untouched by anything else: `world_building`'s `_view_rect` /
`_view_frame` (only `is_on_screen` uses them), and `orders_zones`'s
`_designation_undo` (only its own remember/undo pair uses it).

Calling from one of the six files into another goes through `main`:
`main.camera_view._apply_view()`, `main.world_building._flower_at(...)`.
Calling a sibling function within the *same* file stays a bare call, same
as it always was.

## What stayed on main.gd rather than moving

A short list of small, heavily shared, or lifecycle-trivial functions
were left on `main.gd` rather than forced into one of the six files,
because moving them would have meant more cross-file calls for less
benefit: `_process` and everything it calls directly every frame
(`_sample_fps`, `_reseed_meadow`, `_hatch_ready_brood`, `_advance_weather`,
`_apply_rain_overlay`, `_check_for_loss`, `_check_colony_energy`,
`_prune_selection`), plus `_update_population_readout`, `_role_counts`,
`_record_emergence` (called from three or more of the six files each),
and `_on_restart_after_loss` / `_on_level_chosen` (five lines each,
wired directly to a signal in `_ready()`).

## `_unhandled_input` -- the one real trap in this pattern

`input_selection.gd` defines its own `_unhandled_input(event)`. Because
it's `add_child()`-ed onto `main` in `_ready()`, Godot calls it directly
-- `_unhandled_input`, `_process` and friends are auto-dispatched to
every Node in the tree that defines them, no wiring needed. `main.gd`
does **not** also define `_unhandled_input` and forward to it; doing both
would process every click and keypress twice. If a future split adds a
node with `_process`, `_physics_process`, `_input`, `_unhandled_input` or
`_unhandled_key_input`, check whether `main.gd` (or anything else in the
tree) already defines the same one before assuming a forward is needed.

## State migration was deliberately *not* attempted

An earlier version of this plan considered moving the state itself into
the six files (each owning its own vars, not just its own functions).
Rejected: it would have meant rewriting every `world.X` /
`main.X` touch point in `bee.gd` and the others too, which is a bigger
and riskier change than "split main.gd" ever meant, and not one that can
be checked without Godot running. If a good reason to do it turns up
later, do it one field at a time, each field its own commit, each
followed by a full read of every file that touches it -- not in bulk.

## Verification

`python3 tests/source_checks.py` and `python3 tests/balance_tests.py`
both pass. `source_checks.py` catches bare-call resolution failures
within a file, which is most of what a mechanical extraction like this
can get wrong. It does **not** check dotted calls (`main.foo()`), so
every `main.` / `main.<node>.` reference in the six new files was
additionally checked by hand against `main.gd`'s actual declarations
before this shipped.

**Not yet done: Dave's hands-on playtest.** Nothing here proves the game
still plays the same -- only that it still parses and the balance numbers
still hold. Click-driven things (placement modes, popups, control groups,
the comb overlay cycle, save/load) all moved files and all need running
in Godot before this is trusted.
