# Skill screen — the tree as a full-screen, paused view

<!-- CONTEXT: plan | LAYER: immediate-task -->
Status: active | Owner: Dave / Claude Code | Next: SK-1 -- the skill tree opens full-screen and pauses the game, startable after BS-2 (see Dependencies) | Dependency: BS-2 in `plans/now/brood-spine.md` edits `skill_tree_panel.gd` first | Verified: 2026-09-28

**Objective.** The in-run skill tree is a full-screen view that pauses the
game, with each skill's name written in its hexagon, as
`plans/design/progression.md` section 8.4 already specifies ("opens as a
full-screen overlay with the simulation paused").

**State, verified 28 Sep 2026.** AP-3 built it as a 400 px left-shelf window
instead (`skill_tree_panel.gd::_ready`: `build_left_window(400)`), with
`TILE_SIZE := 11.0` hexes that carry no text, and a text list under the grid
holding each skill's state and its Buy button (`_rebuild_list`). The Skills
button (`hud.gd::_build_top_right_bar`) opens it through
`year_winter._toggle_panel`, so it closes and is closed by the other left
windows. C-64 passed on that version on 28 Sep 2026.

**Decisions (Dave, 28 Sep 2026).** Full-screen, paused; names in the hexes,
like the main menu's Challenge and scenario tiles; the list goes -- cost,
reason and Buy come from hovering or clicking a tile; hexes are big enough to
read, and the player drags to pan and scrolls to zoom out to the whole tree.

## Open slices at a glance

| Slice | Outcome from the player's seat | Files owned | Startable | Level |
| --- | --- | --- | --- | --- |
| SK-1 | Skills opens a full-screen, paused view; click a tile to see and buy it | `scripts/skill_tree_panel.gd`, `scripts/hud.gd`, `scripts/scenario_actions.gd`, `test_scenarios/ap3_skill_tree_window_test.json` | after BS-2 | medium |
| SK-2 | Names sit in big hexes; drag to pan, wheel to zoom | `scripts/skill_tree_panel.gd` | after SK-1 | medium |

**Dependencies.** BS-2 (`plans/now/brood-spine.md`) edits
`skill_tree_panel.gd` (a waived skill shows "Free" for its cost) and is ahead
of SK-1 in the Claude lane; SK-1 keeps that "Free" wording in the tile
tooltip and the detail strip. SK-2 needs SK-1's full-screen view.
**Required reading:** the slice's own section, `progression.md` section 8.4,
and the functions named. **Do not change** `buy_skill`'s signature (the
`buy_skill` scenario verb calls it) or the once-per-open tile resolution in
`_rebuild` (section 8.4's performance rule).

## SK-1 — the skill tree opens full-screen and pauses the game

Level: medium.

**Change.**

- `skill_tree_panel.gd::_ready`: `setup_layer("skills", "skill_tree_panel", 15)`
  (first confirm with `grep -n "layer = \|setup_layer(" scripts/*.gd` that
  nothing else uses 15), then `_build_panel(0)` and
  `panel.set_anchors_preset(Control.PRESET_FULL_RECT)` in place of
  `build_left_window(400)`, `build_scroll_body()` and
  `connect_left_window_reflow()`. The column: header (title, close ×), the
  intro line, the grid (`size_flags_vertical = SIZE_EXPAND_FILL`), and a
  detail strip at the bottom. Delete `list_box` and `_rebuild_list`.
- Pause: `open()` stores `get_tree().paused` in `_was_paused`, sets it true
  and calls `main.camera_view._refresh_speed_display()`; `close()` restores
  it and refreshes again. Add `_input(event)`: while open, Escape closes, and
  every key event is marked handled (`get_viewport().set_input_as_handled()`)
  so Space or Tab cannot act on the paused game behind it.
- Selecting: `SkillGrid` handles a left click with
  `Shapes.pixel_to_hex`, and for a `"skill"` tile emits `tile_selected(hex)`.
  The strip then shows that skill's name, tier, state text
  (`_state_text`), cost and reason, and a Buy button enabled only when the
  state is affordable, which calls `buy_skill(id)`. After a purchase
  `_rebuild` re-resolves and the strip re-reads the same tile.
- `hud.gd`: the Skills button calls `skill_tree_panel.toggle()`, not
  `year_winter._toggle_panel`, so it no longer touches the left windows.
- `scenario_actions.gd`: `_do_open_window` opens `"skills"` directly (as it
  does `"settings"`), and `_do_assert` gains `{"tree_paused": bool}`. Update
  `ap3_skill_tree_window_test.json`: after opening skills assert
  `inside_viewport` and `tree_paused: true`; close it before opening Colony.
- Regenerate `FUNCTION_MAP.md` (`python tools/update_function_map.py`).

Runtime policy: nothing per frame; the grid redraws on open, on a click and
after a purchase.

**Acceptance (checks filed at closeout, one condition each).** Pressing
Skills fills the screen with the tree and the game stops; closing it resumes
at the speed it had. Clicking an affordable skill and pressing Buy spends the
stores and marks it owned.

```queue
**[Claude] SK-1 -- the skill tree opens full-screen and pauses the game**
- Plan: `plans/now/skill-screen.md` -- "SK-1 — the skill tree opens full-screen and pauses the game"
- Files: `scripts/skill_tree_panel.gd`, `scripts/hud.gd`, `scripts/scenario_actions.gd`, `test_scenarios/ap3_skill_tree_window_test.json`
- Check: `python tools/run_scenario.py test_scenarios/ap3_skill_tree_window_test.json` passes (skills full-screen, tree paused), `test_scenarios/ap6_bought_tarsal_test.json` still passes, and `tools/verify.ps1` is green
- Proof: `present: scripts/skill_tree_panel.gd :: build_left_window(400)`
- Next after: SK-2 -- skill names in big hexes, with drag and zoom
```

## SK-2 — skill names in big hexes, with drag and zoom

Level: medium. Gated until SK-1 has merged: SK-1's closeout changes the
fence below to `queue` and deletes SK-2's line from `NEXTSTEPS.md`'s "Not in
the queue, and why".

**Change, `skill_tree_panel.gd` only.** `TILE_SIZE` becomes `56.0` (the main
menu's original hex size, `main_menu.gd` HEX_SIZE's comment). `SkillGrid`
sets `clip_contents = true` and gains `pan: Vector2` and `zoom: float`
(1.0 on open, centred on the colony tile). `_draw` starts with
`draw_set_transform(size / 2.0 + pan, 0.0, Vector2(zoom, zoom))`; each skill
tile draws its name with `draw_multiline_string` (theme font, the "Small"
variation's size, `HORIZONTAL_ALIGNMENT_CENTER`, width `tile_size * 1.4`,
at most 3 lines), in `text_primary` over locked tiles and a readable
contrast colour over the coloured ones (`UiTheme.readable_accent` pattern).
Sector title tiles draw their sector label the same way. Left-drag beyond 6
px pans (a shorter press stays a click); the wheel zooms about the pointer,
clamped between the zoom that fits the whole grid and 1.5. Tooltip and click
hit-tests invert the same transform. Redraw only on input.

**Acceptance (check filed at closeout).** Every skill's name is readable
inside its hexagon at 1.0 zoom; dragging moves the tree and the wheel zooms
out until the whole tree is visible.

```queue-gated
**[Claude] SK-2 -- skill names in big hexes, with drag and zoom**
- Plan: `plans/now/skill-screen.md` -- "SK-2 — skill names in big hexes, with drag and zoom"
- Files: `scripts/skill_tree_panel.gd`
- Check: `python tools/run_scenario.py test_scenarios/ap3_skill_tree_window_test.json` passes, and `tools/verify.ps1` is green
- Proof: `present: scripts/skill_tree_panel.gd :: const TILE_SIZE := 11.0`
- Next after: none -- plans/now/skill-screen.md is complete
```
