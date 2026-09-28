# Hive readouts — Dave's 28 Sep 2026 pass

<!-- CONTEXT: plan | LAYER: immediate-task -->
Status: active | Owner: Dave / Claude Code | Next: HR-1 -- a kept-clear tile says so when clicked, startable, its block below | Dependency: none | Verified: 2026-09-28

**Objective.** Make the hive view say what it shows and answer the clicks a
player naturally tries, from Dave's 28 Sep 2026 hands-on batch. Decisions
were taken with Dave in that session.

**State.** Nothing built yet. The sibling HUD fixes from the same batch are
in `plans/now/hud-followups.md`.

## Open slices at a glance

| Slice | Outcome from the player's seat | Files owned | Startable | Level |
| --- | --- | --- | --- | --- |
| HR-1 | A kept-clear tile says so when clicked | `scripts/input_selection.gd`, `scripts/hud.gd`, `scripts/main.gd` | yes | medium |
| HR-2 | Clicking the hive or the exit switches view | `scripts/input_selection.gd`, `scripts/scenario_actions.gd`, `test_scenarios/hr2_click_view_switch_test.json` | yes | medium |
| HR-3 | A bee waiting for room says it is waiting | `scripts/bee.gd` | yes | low |

**Dependencies.** None; HR-1 and HR-2 share `input_selection.gd`, so they
run one at a time. **Required reading:** the slice's own section, then only
the functions it names. **Do not change** any simulation behaviour: HR-3 is
words only.

## HR-1 — a kept-clear tile says so when clicked

Level: medium. Dave chose (28 Sep 2026) "click shows a summary". The dashed
red outline (`input_selection.gd::_draw_tile_outline`, `dashed = true`) is
deliberate and stays.

**Change.** `input_selection.gd::_finish_drag`, hive-view short click: after
the death-marker test and before clearing, if
`main.hive.is_keep_clear(_hex_at(main.drag_start))`, call
`main.hud.show_object_summary("keep_clear", {"hex": hex})`, remember the hex
in a new `selected_keep_clear_hex`, and return. `hud.gd`: add a
`"keep_clear"` branch to `show_object_summary` calling a new
`_show_keep_clear_summary()` (identity "Kept clear", activity "No cell will
be built on this tile; comb workers leave it empty.") and a
`keep_clear_summary_row` holding one "Clear the mark" button, built beside
`soil_summary_row` and shown only for this kind. The button emits a new
`keep_clear_clear_requested` signal; `main.gd` connects it to a new
`input_selection._on_keep_clear_clear_requested()` that calls
`main.hive.set_keep_clear(selected_keep_clear_hex, false)` and clears the
summary. Regenerate `FUNCTION_MAP.md`.

**Acceptance (check filed at closeout).** Clicking a kept-clear tile shows
"Kept clear" in the summary; "Clear the mark" removes its red outline.

```queue
**[Claude] HR-1 -- a kept-clear tile says so when clicked**
- Plan: `plans/now/hive-readouts.md` -- "HR-1 — a kept-clear tile says so when clicked"
- Files: `scripts/input_selection.gd`, `scripts/hud.gd`, `scripts/main.gd`
- Check: `tools/verify.ps1` is green, and `show_object_summary("keep_clear", ...)` shows `keep_clear_summary_row` and hides `soil_summary_row`
- Proof: `absent: scripts/hud.gd :: _show_keep_clear_summary`
- Next after: HR-2 -- clicking the hive or the exit switches view
```

## HR-2 — clicking the hive or the exit switches view

Level: medium. Dave (28 Sep 2026): left-clicking the hive in the meadow opens
the hive view; left-clicking the exit in the hive opens the meadow.

**Change.** Add `input_selection.gd::_click_switches_view(point) -> bool`,
called in `_finish_drag`'s short-click branch after `_bee_at` finds no bee
(a bee under the pointer still wins). In the meadow, a click within
`HIVE_CLICK_RADIUS` of `main.hive.global_position` calls
`main.camera_view._toggle_view()`. In the hive, a click within
`EXIT_CLICK_RADIUS` of `main.hive_root.to_global(main.hive_entrance_inside())`
does the same, only if `main.stage_gate.is_unlocked("meadow_view")` (the
View button's own gate). Right-click commands are untouched. In
`scenario_actions.gd`, let `click_world` take `"target": "hive"` or
`"hive_exit"` for those two points, and add an assert condition
`{"in_hive_view": bool}`. Fixture: meadow → click hive → assert true →
click exit → assert false.

**Acceptance (check filed at closeout).** Clicking the hive in the meadow
shows the hive; clicking the exit inside shows the meadow.

```queue
**[Claude] HR-2 -- clicking the hive or the exit switches view**
- Plan: `plans/now/hive-readouts.md` -- "HR-2 — clicking the hive or the exit switches view"
- Files: `scripts/input_selection.gd`, `scripts/scenario_actions.gd`, `test_scenarios/hr2_click_view_switch_test.json`
- Check: `python tools/run_scenario.py test_scenarios/hr2_click_view_switch_test.json` passes, and `tools/verify.ps1` is green
- Proof: `absent: scripts/input_selection.gd :: _click_switches_view`
- Next after: HR-3 -- a bee waiting for room says it is waiting
```

## HR-3 — a bee waiting for room says it is waiting

Level: low. Dave saw bees standing still in the hive whose Now line read
"Carrying [resource] to a cell". **Cause, confirmed in code:**
`bee_foraging.gd::go_to_deposit_cell` deliberately keeps a bee in
`IN_HIVE_TO_CELL`, holding her load, when `hive.find_cell_for` finds no cell
with room (or no cell is built), and `bee.gd::task_description` prints
"carrying %s to a cell" for that state whatever the target. Behaviour is
right; the words are not. In `task_description`'s `IN_HIVE_TO_CELL` case,
when `target_cell` is null or invalid, return "waiting with %s: no cell has
room for it" (or "waiting with %s until the first cell is built" when
`hive.cells` is empty). No simulation change.

**Acceptance (check filed at closeout).** A bee standing still with a load
because the comb is full reads "waiting ... no cell has room for it".

```queue
**[Claude] HR-3 -- a bee waiting for room says it is waiting**
- Plan: `plans/now/hive-readouts.md` -- "HR-3 — a bee waiting for room says it is waiting"
- Files: `scripts/bee.gd`
- Check: `tools/verify.ps1` is green, and `task_description` returns the waiting text when `state == IN_HIVE_TO_CELL` and `target_cell == null`
- Proof: `absent: scripts/bee.gd :: no cell has room for it`
- Next after: none -- plans/now/hive-readouts.md is complete
```
