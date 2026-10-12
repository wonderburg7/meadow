# Run repairs -- faults the 10-11 Oct 2026 hands-on pass found in archived areas

<!-- CONTEXT: plan | LAYER: active -->
Status: complete | Owner: Dave / Claude Code | Next: None — plan complete | Dependency: none outside this plan; RR-1 to RR-4 run in order (shared `hud.gd` and `main.gd`) | Verified: 2026-10-12

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

RR-2 shipped 2026-10-11; its specification is `plans/archive/RR-2_2026-10-11.md`.

RR-3 shipped 2026-10-12; its specification is `plans/archive/RR-3_2026-10-12.md`.

RR-4 shipped 2026-10-12; its specification is `plans/archive/RR-4_2026-10-12.md`.

RR-5 shipped 2026-10-12; its specification is `plans/archive/RR-5_2026-10-12.md`.

## Not in the queue, and why

- **RR-1** waits for PP-3 (Codex lane) to release `scripts/orders_zones.gd`; RR-5 is in the Claude lane (RR-2 landed 11 Oct 2026, RR-3 and RR-4 landed 12 Oct 2026).
