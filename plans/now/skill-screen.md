# Skill screen — the tree as a full-screen, paused view

<!-- CONTEXT: plan | LAYER: immediate-task -->
Status: active | Owner: Dave / Claude Code | Next: SK-2 -- skill names in big hexes, with drag and zoom | Dependency: none | Verified: 2026-09-30

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
| SK-2 | Names sit in big hexes; drag to pan, wheel to zoom | `scripts/skill_tree_panel.gd` | yes (SK-1 shipped 30 Sep 2026) | medium |

**Dependencies.** None open: BS-2 and SK-1 both shipped by 30 Sep 2026. The
"Free" wording BS-2 gave a waived skill stays in the tile tooltip and the
detail strip.
**Required reading:** the slice's own section, `progression.md` section 8.4,
and the functions named. **Do not change** `buy_skill`'s signature (the
`buy_skill` scenario verb calls it) or the once-per-open tile resolution in
`_rebuild` (section 8.4's performance rule).

SK-1 shipped 2026-09-30; its specification is `plans/archive/SK-1_2026-09-30.md`.

## SK-2 — skill names in big hexes, with drag and zoom

Level: medium. Startable: SK-1 merged on 30 Sep 2026.

**What SK-1 left (30 Sep 2026).** The view is on CanvasLayer 14, not 15:
Gallerin already draws on 15, and 14 keeps its prompts above the tree. The
column sits in GamePanel's vertical scroll body, because at first layout the
intro label wraps at 300 px and measured 261 px tall, which pushed the
column past a 720 px window. Once the grid clips and pans, give it a small
`custom_minimum_size` (it no longer needs room for every ring) so the view
never scrolls at 800x600. Scenario actions do not run while the tree is
paused (`main.gd` skips `run_pending`), so a fixture opens, asserts and
closes the skill view in one tick, with no `settle` between.

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

```queue
**[Claude] SK-2 -- skill names in big hexes, with drag and zoom**
- Plan: `plans/now/skill-screen.md` -- "SK-2 — skill names in big hexes, with drag and zoom"
- Files: `scripts/skill_tree_panel.gd`
- Check: `python tools/run_scenario.py test_scenarios/ap3_skill_tree_window_test.json` passes, and `tools/verify.ps1` is green
- Proof: `present: scripts/skill_tree_panel.gd :: const TILE_SIZE := 11.0`
- Next after: none -- plans/now/skill-screen.md is complete
```
