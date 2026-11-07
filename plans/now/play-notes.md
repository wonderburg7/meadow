# Play notes -- follow-ups from Dave's 30 Oct 2026 hands-on pass

<!-- CONTEXT: plan | LAYER: immediate-task -->
Status: active | Owner: Dave / Claude Code | Next: PN-3 and PN-4 in the Claude lane (PN-2 landed), behind PN-11 and ED-2 on the alpha route; PN-5 and PN-6 are startable and wait for room | Dependency: PN-3 follows ED-2 (`plans/now/difficulty.md`), which edits the same save files; PN-16 (`plans/now/play-notes-hud.md`, Codex) follows PN-6 | Verified: 2026-11-05

## Objective

Dave played on 30 and 31 Oct 2026 and filed findings against checks C-137,
C-139, C-142, C-147, C-150, C-151 and C-159, plus loose notes. This plan holds
the slices whose files are clear now; files owned by HS-2 and SP-6 are split
into `plans/now/play-notes-config.md` and files owned by SG-3 into
`plans/now/play-notes-hud.md`.

## Current state

Verified 2026-10-31 by `tools/slice.ps1 owner` and grep on this branch.
`ui_theme.gd`, `saves_panel.gd`, `save_slots.gd`, `save_game.gd`, `saving.gd`,
`session.gd`, `input_selection.gd`, `bee_building.gd`, `bee_survival.gd` and
`orders_zones.gd` are clear. Already fixed on the branch
`claude/dave-hands-on-checks-784f2a`, with no slice: cell tints, labels and
rings; Colony window readouts and queen row; the new-run resets; the skill
tree's "held but not spendable" note; the drone tray rows; the false "nowhere
to put nectar" warning; Dr Gallerin's bubble behaviour; drones skipped by
`orders_zones.gd::_assign_role`.

## Open slices

| Id | Outcome | Files | Startable | Level |
| --- | --- | --- | --- | --- |
| PN-3 | a save remembers whether Goals was open | `save_game.gd`, `saving.gd`, `session.gd` | yes -- queued after ED-2 | high |
| PN-4 | the queen finishes a cell she was told to build | `bee_survival.gd`, `orders_zones.gd`, `bee_building.gd` | yes -- queued | high |
| PN-5 | a cell or soil block is clicked by its top face | `input_selection.gd` | yes | medium |
| PN-6 | double-click selects bees of the same role | `input_selection.gd` | after PN-5 | low |

## Dependencies

PN-6 follows PN-5, and PN-16 (`plans/now/play-notes-hud.md`, Codex lane)
follows PN-6: all three edit `scripts/input_selection.gd`, as SP-12
(`plans/now/sprites.md`) and CQ-M6b (`plans/now/code-health.md`), both Codex,
do: whichever is queued first runs first.
PN-3 follows ED-2 (`plans/now/difficulty.md`) in the Claude lane; both edit
`save_game.gd`, `saving.gd` and `session.gd`, so PN-3 re-captures the CQ-S0
goldens after ED-2's. A slice reads its own section and nothing else.

PN-1 shipped 2026-11-05; its specification is `plans/archive/PN-1_2026-11-05.md`.

PN-2 shipped 2026-11-07; its specification is `plans/archive/PN-2_2026-11-07.md`.

## PN-3 -- a save remembers whether Goals was open

**True now.** `Session.goals_collapsed` (`scripts/session.gd`) is a profile
preference written by `hud.gd::_on_goals_button_pressed`; `reset_run_state`
sets it false on a new run (done today). `scripts/save_game.gd` does not
mention it. `tests/gp1_goals_dropdown_test.gd` covers the profile round trip.

**Change (Dave, 31 Oct 2026: "Yes, store it in the save").** One optional save
key, `goals_collapsed`, written on save and applied on load following
`save_game.gd`'s `apply_settings` pattern; a missing key means shown. Do not
edit `hud.gd`: the HUD already reads `Session.goals_collapsed` when it
rebuilds, and a load rebuilds it. If that proves untrue, stop and note a
HUD-plan slice rather than editing the file.

**Invariants.** An old save loads unchanged (no version bump, the key is
optional); the profile preference still works for a new run.

**Acceptance (player seat, and the hands-on check).** Close the Goals list,
save, load that save: Goals is closed. Open it, save, load: open. Re-run C-150
after it.

**Open decisions:** none.

```queue
**[Claude] PN-3 -- a save remembers whether Goals was open**
- Plan: `plans/now/play-notes.md` -- "PN-3 -- a save remembers whether Goals was open"
- Files: `scripts/save_game.gd`, `scripts/saving.gd`, `scripts/session.gd`, `tests/test_gp1_goals_dropdown.py`, `tests/gp1_goals_dropdown_test.gd`
- Check: `python -m unittest tests.test_gp1_goals_dropdown` passes with a save round trip of the Goals state and an old save with no key loading as shown; `.\tools\verify.ps1` is green. Hands-on: close Goals, save, load; it is closed (re-run C-150)
- Proof: `absent: scripts/save_game.gd :: goals_collapsed`
- Next after: PN-4 -- the queen finishes a cell she was told to build
```

## PN-4 -- the queen finishes a cell she was told to build

**True now (inferred, not yet reproduced).** Dave: "I ask queen to build a
cell, but at the time she is assigned a different role (e.g. forager), she
starts building it but eventually changes back", and the queen "got stuck
outside 'Building a new cell'" when asked from the meadow.
`orders_zones.gd::queen_build_at` only sets `target_cell` and `TO_BUILD_SITE`;
`bee_survival.gd::begin_feeding_self` overwrites `target_cell`, and
`after_feeding` returns to `_default_state_for_role()`, forgetting the site.
Outdoors, `bee_building.gd::builder_go_to_site` moves straight at the cell with
no hive-entrance leg; the stall watchdog sets `BUILD_IDLE`, which a
non-builder role never leaves.

**Change.** First reproduce both in test scenarios (a Forager queen who must
eat mid-build; a queen ordered to build while outside). Then remember the
ordered site across a meal (a field `ordered_site` on the bee, cleared on
arrival or a new order), or re-issue it through the `manual_build_hex` queue
(`bee_building.gd::create_cell_site_at`); and when not inside the hive, route
via the entrance (`TO_HIVE` first) before heading for the site.

**Invariants.** Other roles' builders are unchanged; no `bee.gd` edit (if one
is unavoidable, stop: HS-2 and SP-6 own it). The queen's eating and fatigue
rules are unchanged.

**Acceptance (player seat, and the hands-on check).** With the queen set to
Forager, order Build cell: she finishes it even after eating. With the queen
in the meadow, order Build cell: she walks home and builds it.

**Open decisions:** none.

```queue
**[Claude] PN-4 -- the queen finishes a cell she was told to build**
- Plan: `plans/now/play-notes.md` -- "PN-4 -- the queen finishes a cell she was told to build"
- Files: `scripts/bee_survival.gd`, `scripts/orders_zones.gd`, `scripts/bee_building.gd`, `test_scenarios/pn4_queen_build_after_meal.json`, `test_scenarios/pn4_queen_build_from_meadow.json`, `tests/test_pn4_queen_build.py`
- Check: `python -m unittest tests.test_pn4_queen_build` passes (both scenarios fail before the fix and finish the cell after it); `python -m unittest tests.test_rr1_queen_builds` still passes; `.\tools\verify.ps1` is green. Hands-on: a Forager queen ordered to build finishes the cell after eating; one ordered from the meadow walks in and builds
- Proof: `absent: scripts/orders_zones.gd :: ordered_site`
- Next after: PN-5 -- a cell or soil block is clicked by its top face
```

## PN-5 -- a cell or soil block is clicked by its top face

**True now.** `input_selection.gd::_cell_at` and `::_soil_at` pick the first
node within a circle of radius `cell_size` / `block_size` of `global_position`.

**Change (Dave's rule).** The target is the top hexagon (the rim, lifted by the
sprite height as the selection ring is). When no cell or block sits in front
of it, the floor hexagon where it meets the floor counts too. Use a
point-in-hexagon test (add a helper beside the existing hexagon helpers in
`scripts/shapes.gd` only if `Shapes` has none; the file is read-only otherwise
and `hive.cell_at_tile` is read, not edited). The soil lift is
`soil_block.gd::SIDE_HEIGHT_PX`, read only. Same rule for soil blocks.

**Invariants.** Right-click orders still reach the same cell; a cell in front
wins over the floor space of one behind it; hit-testing stays on input events,
never per frame.

**Acceptance (player seat, and the hands-on check).** Click inside a cell's top
ring: it selects. Click just below a front cell's ring on its side face: the
cell behind (if any) is not picked. Click the floor space of a cell with
nothing in front: it selects. Soil blocks behave the same.

**Open decisions:** none.

```queue
**[Claude] PN-5 -- a cell or soil block is clicked by its top face**
- Plan: `plans/now/play-notes.md` -- "PN-5 -- a cell or soil block is clicked by its top face"
- Files: `scripts/input_selection.gd`, `tests/pn5_top_face_pick_test.gd`, `tests/test_pn5_top_face_pick.py`
- Check: `python -m unittest tests.test_pn5_top_face_pick` passes (top face picks, a covered floor hexagon does not, an uncovered one does, soil follows the same rule); `.\tools\verify.ps1` is green. Hands-on: clicking inside a cell's top ring selects it
- Proof: `absent: scripts/input_selection.gd :: _point_in_hex`
- Next after: PN-6 -- double-click selects bees of the same role
```

## PN-6 -- double-click selects bees of the same role

**True now.** `input_selection.gd` already detects `double_click` (it uses it
to avoid issuing an order twice); nothing acts on it for bees.

**Change.** Double-clicking a bee selects every bee currently inside the
camera's visible rect, in the current view (hive or meadow), with the same role
and the same sub-role. Shift+double-click adds them to the selection.

**Invariants.** A single click and the double-click order guard are unchanged;
bees in the other view are never picked.

**Acceptance (player seat, and the hands-on check).** With several Foragers on
screen, double-click one: all on-screen Foragers with that sub-role are
selected, and nothing else. Shift+double-click a Nurse: they join the selection.

**Open decisions:** none.

```queue
**[Claude] PN-6 -- double-click selects bees of the same role**
- Plan: `plans/now/play-notes.md` -- "PN-6 -- double-click selects bees of the same role"
- Files: `scripts/input_selection.gd`, `tests/pn6_double_click_select_test.gd`, `tests/test_pn6_double_click_select.py`
- Check: `python -m unittest tests.test_pn6_double_click_select` passes (same role and sub-role, on screen only, Shift adds); `.\tools\verify.ps1` is green. Hands-on: double-click a Forager selects the on-screen Foragers
- Proof: `absent: scripts/input_selection.gd :: _select_same_role`
- Next after: PN-9 -- early spring: fast queen building, no souring before day 15
```
