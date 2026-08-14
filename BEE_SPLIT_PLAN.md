# Splitting bee.gd: the plan

Written 14 Aug 2026, after the main.gd split (see `MAIN_SPLIT_PLAN.md`) shipped
and needed two follow-up fixes once it actually ran in Godot. This plan is
written to avoid repeating both of those mistakes, plus one new one that's
specific to `bee.gd`. **Not started -- Dave to review and approve first.**

## Why this is a different shape of problem than main.gd

`main.gd` is one object that exists once. `bee.gd` is a class that gets
instantiated a few dozen to a few hundred times in a single run -- it's the
thing the whole 4fps investigation was about. That changes the right
approach in one important way:

**No child nodes.** The main.gd split gave each concern its own small Node,
created once and reached as `main.world_building` etc. Doing the same for
bee.gd -- five or six extra child Nodes per bee -- would multiply that
overhead by the bee count for no reason, since none of these helpers need
their own state. Godot supports calling a function on a script without
instantiating it at all (`static func`), and this codebase already leans on
that pattern hard: `Shapes`, `Roles`, `UI`, `SaveGame`, and parts of
`flower.gd`, `hud.gd` and `nursery_panel.gd` are all called this way. The
split below follows that existing convention rather than inventing a new
one -- new files `extends RefCounted` and hold only `static func`s, called
as `BeeForaging.seek_flower(bee)` rather than instantiated.

## What stays on bee.gd

Same rule as main.gd: **everything something outside `bee.gd` touches
directly stays on `bee.gd`.** For `bee.gd` that's a much bigger share of the
file than it was for `main.gd`, because almost every non-underscore method
is called constantly from `hud.gd`, `colony_panel.gd`, `input_selection.gd`,
`orders_zones.gd`, `save_game.gd` and the other split files -- `b.energy`,
`b.set_role()`, `b.idle_reason()`, `b.task_description()`, and so on.

Handily, the file already marks this boundary itself: every function
without a leading underscore is something else calls; every function *with*
one is private to `bee.gd`. Checked this by grepping every other script for
a call to an underscore-prefixed method on a bee -- there are none. So the
line is exactly the existing naming convention, not a new judgement call:

- **All vars.** No exceptions -- more of them are read externally here than
  main.gd's were.
- **`_ready`, `setup`, `_process`**, and the "how often a bee thinks"
  throttle right under it -- Godot's own entry points, same reason
  `main.gd` kept `_process`.
- **The idle dispatcher** (`_apply_pending_role`, `_is_busy`,
  `_idle_dispatch`, `_try_role_work`) -- it's the switchboard that calls
  into every one of the new files below, so keeping it central avoids the
  new files calling into each other.
- **"Player commands"** (`command_move_to`, `set_role`, `set_focus`,
  `set_home_hex`, `set_restock_targets`, and the rest of that section) --
  the whole thing is the public API `input_selection.gd` and `orders_zones.gd`
  drive bees through.
- **"Display"** (`role_letter`, `idle_reason`, `task_description`,
  `role_name_text`, `age_days`, and the rest) -- what `hud.gd` reads to
  build every popup and label.

Net effect: `bee.gd` goes from 3,162 lines to roughly 1,300 -- a smaller cut
than main.gd's (2,825 -> 650), because the public surface here is a much
bigger fraction of the whole file. Worth saying plainly rather than
oversold.

## The new files

Named after the role or system they cover, matching how the file's own
section headers already divide it:

| New file | What moves in | ~lines |
|---|---|---|
| `bee_enums.gd` | `Role`, `State`, `ROLE_PERF_SECTIONS` -- see below, this one's special | 40 |
| `bee_survival.gd` | life support, eating, stall watchdog (`_age_and_burn` through `_die`) | 315 |
| `bee_foraging.gd` | foraging plus entering/leaving the hive (`_seek_flower` through `_deposit_everything_remotely`) | 365 |
| `bee_nursery.gd` | nursery work and royal jelly (`_nurse_go_to_brood` through `_abandon_food_errand`) | 290 |
| `bee_building.gd` | building and restocking (`_builder_go_to_site` through `_builder_dump_waste`) | 295 |
| `bee_mining.gd` | mining (`_miner_go_to_site` through `_miner_dump`) | 70 |
| `bee_honey.gd` | honey making (`_honey_go_to_nectar` through `_honey_fan`) | 100 |
| `bee_egg_laying.gd` | queen egg laying (`_pollen_needed_for_next_egg` through `_queen_lay`) | 90 |
| `bee_movement.gd` | obstacle avoidance and steering (`_avoid_obstacles` through `_move_towards`) | 310 |

`bee_mining.gd`, `bee_honey.gd` and `bee_egg_laying.gd` are small enough
that combining them was tempting, but each is a distinct caste with its own
section already, matching CLAUDE.md's "one responsibility per script" --
keeping them apart costs nothing and makes each easy to find.

Every function keeps its exact current name, `static`, with `bee: Node2D`
added as the first parameter. Calls from `bee.gd` become
`BeeForaging.seek_flower(self)` where they used to be bare `_seek_flower()`.
Calls between two functions in the *same* new file stay bare, same as
main.gd's split. Calls from one new file into another go through the name
directly (`BeeMovement.move_towards(bee, ...)`), same pattern as
`main.world_building.X()`.

## The one new landmine: `Role` and `State`

`bee.gd` declares `enum Role` and `enum State` itself, and 36 places across
six other files (`hud.gd`, `main.gd`, `world_building.gd`,
`input_selection.gd`, `orders_zones.gd`, `year_winter.gd`) reference them as
`Bee.Role.FORAGER` or `Bee.State.X`. Every one of the new files needs those
same names to do anything -- `_seek_flower` alone sets `state =
State.TO_FLOWER`.

That's a straight circular preload if handled carelessly: `bee.gd` would
need to preload `bee_foraging.gd` to call it, and `bee_foraging.gd` would
need to preload `bee.gd` for the enum. Godot does not support that -- it's
the kind of thing that would produce exactly the sort of blank-screen
failure the main.gd split hit twice.

Fix: `Role`, `State` and `ROLE_PERF_SECTIONS` move into their own file,
`bee_enums.gd`, `extends RefCounted`, with no dependencies of its own --
a leaf, same shape as `roles.gd`. `bee.gd` preloads it and aliases the
names straight back (`const Role = BeeEnums.Role`, `const State =
BeeEnums.State`), so every external `Bee.Role.X` / `Bee.State.X` reference
keeps working completely unchanged -- this is the same "external surface
doesn't move" rule as main.gd's eight wrapper methods, applied to an enum
instead of a function. Every new `bee_*.gd` file preloads `bee_enums.gd`
directly, not `bee.gd`, so there's no cycle anywhere in the graph.

(`roles.gd` -- a different file, the one with role labels/colours/tips for
the UI -- already explains it keeps its own separate role-id constants
"so files that only need to name a role don't have to preload bee.gd,
which pulls in the whole state machine." Same instinct, same fix, this
time for the enum bee.gd's own logic needs directly rather than for
outside files.)

## The other lesson from main.gd's two follow-up fixes

Both bugs that got past `source_checks.py` and only showed up when the
game actually ran:

1. **`:=` type inference breaks across a loosely-typed reference.** Any
   `var x := bee.something()` inside a new file will fail to compile,
   the same way `var cam := main.camera_view._active_camera()` did,
   because `bee`'s declared type (`Node2D`) doesn't statically expose
   `.something()`. Every local var whose value comes from `bee.` (or from
   `bee.hive.`, `bee.world.`) in the new files needs a plain `=` or an
   explicit type (`var x: Vector2 = bee.something()`), never `:=`. This
   rule gets checked by hand before anything ships, the same way it was
   checked for the six main.gd files -- `source_checks.py` doesn't catch it.

2. **Ordering matters, and static analysis won't catch a wrong order.**
   The camera bug wasn't a syntax error, it was code that compiled fine
   and crashed the instant a bee got created before a camera existed.
   `bee.gd`'s equivalent risk is anything called from early in `setup()`
   or the first `_process()` tick that assumes some other piece of state
   is already in place. Worth specifically re-reading `setup()` and the
   first few lines of `_process()` against whatever moved, once the
   actual extraction is underway, rather than assuming order doesn't matter
   because nothing looked wrong on paper last time either.

## Performance: the one section worth re-measuring

`bee_movement.gd` is the hottest path in the file -- steering and obstacle
avoidance run every frame for every moving bee, and it's the code the 4fps
investigation was chasing before the real cause turned out to be
`_grounded()`'s recursion. A `static func` call through a preloaded script
is a cheap, ordinary thing in GDScript, not the kind of change that caused
either of this project's two real perf regressions (an infinite recursion
bug, and a spatial-grid abstraction that cost more than the scan it
replaced) -- but "should be cheap" is exactly the kind of claim this
project's own rule says not to trust without measuring. Recommendation:
give `bee_movement.gd`'s functions their own `Perf.begin`/`Perf.end` pair
(the convention `PERF_PLAN.md` and `CLAUDE.md` already establish), and
compare the fps-starred breakdown before and after with a colony large
enough to have mattered the first time (the 4fps repro was 29 bees).

## Suggested order of work, once approved

Extract and commit one file at a time, not all nine in one pass -- bee.gd
is instantiated hundreds of times and sits in the simulation's hot path, so
a subtle bug here is both more likely to matter and harder to spot on
sight than anything in the main.gd split. After each file: run
`source_checks.py` and `balance_tests.py`, then actually run the game with
a decent-sized colony before moving to the next one, not just after the
last one.

1. `bee_enums.gd` first, on its own -- it's the one every other file
   depends on, and the aliasing is worth confirming compiles and every
   external `Bee.Role.X` / `Bee.State.X` reference still resolves before
   anything else moves.
2. `bee_movement.gd` next, precisely because it's the highest-stakes one --
   better to find out early if the static-call pattern has any cost here,
   while it's the only thing that changed.
3. The five role-specific files (`bee_survival`, `bee_foraging`,
   `bee_nursery`, `bee_building`, `bee_mining`, `bee_honey`,
   `bee_egg_laying`) in any order -- each is close to self-contained once
   `bee_enums.gd` exists, so the order between them doesn't matter much.
   Foraging first is a reasonable default since it's the easiest to
   playtest in isolation (start a run, watch a forager).

## What this does not do

Same as main.gd: no state moves off `bee.gd` itself, and the public API
(`set_role`, `idle_reason`, `command_move_to`, and everything else the
other files already call) is untouched in name and behaviour. This is a
file-organisation change, not a redesign of how bees work.
