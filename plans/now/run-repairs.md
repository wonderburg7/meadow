# Run repairs -- faults the 10-11 Oct 2026 hands-on pass found in archived areas

<!-- CONTEXT: plan | LAYER: active -->
Status: active | Owner: Dave / Claude Code | Next: RR-1 -- the queen can build a cell in every run | Dependency: none outside this plan; RR-1 to RR-4 run in order (shared `hud.gd` and `main.gd`) | Verified: 2026-10-11

## Objective

Five faults the 10-11 Oct 2026 check pass confirmed in areas whose plans are
archived (Colony Run, saving, scenario reds), so they start here
(`plans/README.md`, "Plan schema"). Each slice comes from one failed check and
Dave's decision in that session (11 Oct 2026).

## Current state

Verified 11 Oct 2026 against master `8a7e5ac`:

- The queen's "Build cell" button is Challenge 1 only:
  `challenge_runner.gd::_enter_stage` calls
  `hud.set_queen_build_button_visible(Session.starting_level == 1)` and the
  Challenge's end sets it false. Outside Challenge 1 the queen can build only
  as a Comb worker, a role gated by `skill.colony.comb_worker`
  (`roles.gd`), which a lone Colony Run queen cannot buy: she has no cell to
  store its price in. So a Colony Run never gets its first cell (C-109).
- On a fresh boot `main.gd::_ready` returns at `if Session.menu_pending:`
  before `hud = Hud.new()`. The main menu's cog -> "Saves..." runs
  `debug_panel.gd::_on_load_pressed`, which reads
  `worlds[0].hud.saves_panel` and errors on a null `hud` (C-108).
- `Session.run_name` defaults to "My colony" and `reset_run_state` keeps it,
  so every unnamed run shares one slot. `game_over.gd` offers the newest
  checkpoint in that slot -- a day-30 one from an earlier run, on a run that
  died on day 3 (C-111).
- Nothing sets a minimum window size (`project.godot` has no display
  section; no `min_size` in `scripts/`), though `ui_layout.gd`'s
  `MIN_SUPPORTED_WIDTH` is 800. The window drags to 803x408 and the cell
  tray runs off the bottom (C-103).

## Open slices

| Slice | What it does | Files it owns | Startable | Level |
| --- | --- | --- | --- | --- |
| RR-1 | The queen can build a cell in every Challenge, Scenario and Colony Run | `scripts/challenge_runner.gd`, `scripts/hud.gd`, `scripts/input_selection.gd`, `scripts/orders_zones.gd`, `scripts/scenario_actions.gd`, `test_scenarios/rr1_queen_builds_test.json`, `tests/test_rr1_queen_builds.py` | yes | medium |
| RR-2 | "Saves..." works on the main menu at boot | `scripts/main.gd`, `scripts/hud.gd`, `scripts/saves_panel.gd`, `scripts/debug_panel.gd`, `tests/rr2_boot_saves_test.gd`, `tests/test_rr2_boot_saves.py` | after RR-1 (shared `hud.gd`) | medium |
| RR-3 | A new run from the menu gets its own default name | `scripts/save_slots.gd`, `scripts/main.gd`, `tests/test_rr3_fresh_run_name.py` | after RR-2 (shared `main.gd`) | medium |
| RR-4 | The window cannot be made smaller than 800x600 | `scripts/ui_layout.gd`, `scripts/main.gd`, `tests/test_rr4_min_window.py` | after RR-3 (shared `main.gd`) | low |
| RR-5 | Hexagon names re-fit when the typeface changes | `scripts/main_menu.gd`, `tests/rr5_hex_refit_test.gd`, `tests/test_rr5_hex_refit.py` | yes (no shared file) | low |

Each slice reads its own section only. Do not change skill prices, the
branch-tier rule (`plans/now/tier-two.md` T2-9 owns that), or the save
format.

## RR-1 -- the queen can build a cell in every run

<!-- LAYER: immediate-task -->

**Decision (Dave, 11 Oct 2026).** The queen must always be able to build a
cell, in any Challenge, Scenario or Colony Run. She must not raise a worker
without the player: the player coordinates collection and times the first
worker. This slice gives her the build; it does not automate founding.

**True now.** See "Current state". `input_selection.gd::_place_queen_build_cell`
hands the hex to `challenge_runner.gd::on_queen_build_site_chosen`, which
checks `hive.can_build_on`, calls `hive.create_cell_site_at`, applies the
Challenge's `FAST_BUILD_TIME` (and Challenge 1's nectar capacity), then sets
`queen.target_cell` and `queen.state = TO_BUILD_SITE`.

**True afterwards.**

- `orders_zones.gd` (owner of player orders) has
  `queen_build_at(hex: Vector2i) -> Node2D`: the three general steps (valid
  queen and `can_build_on`, `create_cell_site_at`, queen target and
  `TO_BUILD_SITE`), returning the site or null.
- `challenge_runner.on_queen_build_site_chosen` calls it, then applies its
  Challenge overrides to the returned site. Challenge behaviour is unchanged.
- `_place_queen_build_cell` calls the Challenge function when
  `main.challenge_runner.active`, otherwise `orders_zones.queen_build_at`.
  Outside a Challenge the site keeps the normal build time and capacity.
- `hud.show_queen_build_button` defaults to true; `_enter_stage` sets it
  true for every Challenge; the Challenge's end no longer hides it. The
  "Challenge 1 only" comments on `show_queen_build_button`,
  `set_queen_build_button_visible`, `_build_queen_build_row`, the
  `hud.gd` signal note and `challenge_runner.gd`'s note say "every run".
- `scenario_actions.gd`'s assertion checks gain `queen_build_offered`
  (reads `main.hud.show_queen_build_button`) and `built_cells_at_least`
  (counts built cells in `main.hive.cells`).

**Runtime.** On a click only; nothing per frame.

**Must not change.** Challenge 1's stage flow and its fast build; the Comb
worker skill gate; the queen's energy cost of building.

**Escalate** if a non-Challenge site never completes because the queen's
`BUILDING` state depends on Challenge state: that is a simulation question,
not this slice's to decide.

**Test.** `test_scenarios/rr1_queen_builds_test.json`: `"cells": 0`, no
workers, so the queen is alone as in a Colony Run. Actions: assert
`queen_build_offered` true; `select_bees` the queen alone; `request_placement_tool`
`queen_build_cell`; `click_world` at view `hive`, `x` 0, `y` 0; stop after
two game days; assert `built_cells_at_least` 1. `tests/test_rr1_queen_builds.py`
runs it the way `tests/test_col6_winter_skip.py` runs its scenario.

```queue
**[Claude] RR-1 -- The queen can build a cell in every run**
- Plan: `plans/now/run-repairs.md` -- "RR-1 -- the queen can build a cell in every run"
- Files: `scripts/challenge_runner.gd`, `scripts/hud.gd`, `scripts/input_selection.gd`, `scripts/orders_zones.gd`, `scripts/scenario_actions.gd`, `test_scenarios/rr1_queen_builds_test.json`, `tests/test_rr1_queen_builds.py`
- Check: `python -m unittest tests.test_rr1_queen_builds` passes (a lone queen outside any Challenge is offered Build cell and builds one cell within two days); `tools/verify.ps1` is green
- Proof: `absent: scripts/orders_zones.gd :: func queen_build_at`
- Next after: RR-2 -- "Saves..." works on the main menu at boot
```

## RR-2 -- "Saves..." works on the main menu at boot

<!-- LAYER: immediate-task -->

**True now.** See "Current state". `hud.gd` builds the Saves window
(`saves_panel = SavesPanel.new()`, added to `main`), so it does not exist
until a run is built. `saves_panel.gd` calls `main.hud.confirm_discard`,
`main.hud.show_warning` and `main.saving.save_run`; the last two are also
missing at boot. `main.gd` already builds `debug_panel` before the
early return for the same reason (UI-M).

**True afterwards.**

- `main.gd::_ready` builds the Saves window before the `menu_pending`
  return, beside `debug_panel`, and `hud.gd` uses that instance instead of
  making its own.
- At boot the window lists saves and loads one; its Save row stays hidden
  on the menu (it already is: "Hidden on the main menu"). Any `main.hud`
  call it makes with no `hud` falls back to `push_warning` with the same
  text.
- `_on_load_pressed` opens it on the main menu whether or not a run is
  built behind the menu; no null access.

**Must not change.** Loading by scene reload (`Session.load_pending`), a
Challenge in progress loading its latest named slot, and the Saves
window's behaviour in a run.

**Test.** `tests/rr2_boot_saves_test.gd`, booting as
`tests/col7_gyne_window_test.gd::_boot` does but with
`menu_pending = true`, calls `debug_panel._on_load_pressed()` and asserts
the Saves window is open, with no script error in the output.
`tests/test_rr2_boot_saves.py` runs it.

```queue
**[Claude] RR-2 -- "Saves..." works on the main menu at boot**
- Plan: `plans/now/run-repairs.md` -- "RR-2 -- \"Saves...\" works on the main menu at boot"
- Files: `scripts/main.gd`, `scripts/hud.gd`, `scripts/saves_panel.gd`, `scripts/debug_panel.gd`, `tests/rr2_boot_saves_test.gd`, `tests/test_rr2_boot_saves.py`
- Check: `python -m unittest tests.test_rr2_boot_saves` passes (on a fresh boot the menu's Saves... opens the Saves window with no script error); `tools/verify.ps1` is green
- Proof: `absent: scripts/main.gd :: SavesPanel`
- Next after: RR-3 -- A new run from the menu gets its own default name
```

## RR-3 -- a new run from the menu gets its own default name

<!-- LAYER: immediate-task -->

**Decision (Dave, 11 Oct 2026).** Each new run gets its own default name
("My colony", "My colony 2", ...), so slots never mix. Nothing is deleted.

**True now.** See "Current state". Slots are keyed by
`SaveSlots.slugify(Session.run_name)`; `SaveSlots.list_slots()` lists every
slot with a named save or checkpoints.

**True afterwards.**

- `save_slots.gd` has `static func fresh_run_name(base: String) -> String`:
  `base` if no listed slot has its slug, else `"%s %d" % [base, n]` for the
  lowest `n >= 2` whose slug is free.
- `main.gd::_on_level_chosen` and `_on_scenario_chosen` set
  `Session.run_name = SaveSlots.fresh_run_name("My colony")` before the
  reload. Loading a save, Restart Run and the restart after a loss keep the
  current name.

**Must not change.** The save and index formats; the name a loaded run
keeps; Challenges' own checkpoints.

**Test.** `tests/test_rr3_fresh_run_name.py`: on `SaveSlots.use_scratch_root()`,
no slots gives "My colony"; a recorded "My colony" gives "My colony 2"; a
recorded "My colony" and "My colony 2" gives "My colony 3".

```queue
**[Claude] RR-3 -- A new run from the menu gets its own default name**
- Plan: `plans/now/run-repairs.md` -- "RR-3 -- a new run from the menu gets its own default name"
- Files: `scripts/save_slots.gd`, `scripts/main.gd`, `tests/test_rr3_fresh_run_name.py`
- Check: `python -m unittest tests.test_rr3_fresh_run_name` passes (the three naming cases above); `tools/verify.ps1` is green
- Proof: `absent: scripts/save_slots.gd :: func fresh_run_name`
- Next after: RR-4 -- The window cannot be made smaller than 800x600
```

## RR-4 -- the window cannot be made smaller than 800x600

<!-- LAYER: immediate-task -->

**Decision (Dave, 11 Oct 2026).** Enforce an 800x600 minimum window.

**True afterwards.** `ui_layout.gd` adds `MIN_SUPPORTED_HEIGHT := 600.0`
beside `MIN_SUPPORTED_WIDTH`. `main.gd::_ready`, before the `menu_pending`
return, sets `get_window().min_size` to those two values. A test reads both
constants and the `min_size` assignment from source.

```queue
**[Claude] RR-4 -- The window cannot be made smaller than 800x600**
- Plan: `plans/now/run-repairs.md` -- "RR-4 -- the window cannot be made smaller than 800x600"
- Files: `scripts/ui_layout.gd`, `scripts/main.gd`, `tests/test_rr4_min_window.py`
- Check: `python -m unittest tests.test_rr4_min_window` passes; `tools/verify.ps1` is green
- Proof: `absent: scripts/ui_layout.gd :: MIN_SUPPORTED_HEIGHT`
- Next after: RR-5 -- Hexagon names re-fit when the typeface changes
```

## RR-5 -- hexagon names re-fit when the typeface changes

<!-- LAYER: immediate-task -->

**True now (C-99, Dave, 11 Oct 2026).** Hexagon names fit at every scale
when the scale is raised with the typeface already chosen. But raising the
scale to 2 in Munro and then switching to OpenDyslexic splits words across
lines. `main_menu.gd::_fit_hex_label` skips the refit when its cache key is
unchanged. The key starts with `font.get_rid().get_id()`, which is 0 for
every `FontFile` (a headless probe on 11 Oct 2026 printed 0 for Munro,
OpenDyslexic, Silkscreen and Atkinson). So a typeface change at the same
scale keeps the previous face's shrunken size. No other script keys on
`get_rid().get_id()`.

**True afterwards.** The key uses `font.get_instance_id()`, so any typeface
change refits. Nothing else changes.

**Runtime.** Unchanged: the fit runs on the label's `draw` and returns early
on a matching key.

**Test.** `tests/rr5_hex_refit_test.gd` builds the main menu as
`tests/col7_gyne_window_test.gd::_boot` does, with `menu_pending = true`.
It sets text scale 2 and Munro, waits two frames, then switches to
OpenDyslexic through the Typeface setting's own apply path
(`settings_catalogue.gd`'s `ui_typeface` row) and waits two frames. It
asserts each hexagon label's font size equals
`MainMenu.hex_fit_size` for OpenDyslexic. `tests/test_rr5_hex_refit.py`
runs it. This is the instrument for this failure: it fails on today's code.

```queue
**[Claude] RR-5 -- Hexagon names re-fit when the typeface changes**
- Plan: `plans/now/run-repairs.md` -- "RR-5 -- hexagon names re-fit when the typeface changes"
- Files: `scripts/main_menu.gd`, `tests/rr5_hex_refit_test.gd`, `tests/test_rr5_hex_refit.py`
- Check: `python -m unittest tests.test_rr5_hex_refit` passes (switching Munro to OpenDyslexic at scale 2 refits every hexagon name); `tools/verify.ps1` is green
- Proof: `present: scripts/main_menu.gd :: font.get_rid().get_id()`
- Next after: none -- plan complete
```

## Not in the queue, and why

- **RR-1 to RR-5** are admissible; `finish`'s top-up queues them in order.
