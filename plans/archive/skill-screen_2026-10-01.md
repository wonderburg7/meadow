# Skill screen — the tree as a full-screen, paused view

<!-- CONTEXT: plan | LAYER: immediate-task -->
Status: complete | Owner: Dave / Claude Code | Next: None — plan complete (SK-2 shipped 1 Oct 2026; hands-on check C-88) | Dependency: none | Verified: 2026-10-01

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

**Dependencies.** None open: BS-2 and SK-1 both shipped by 30 Sep 2026. The
"Free" wording BS-2 gave a waived skill stays in the tile tooltip and the
detail strip.
**Required reading:** the slice's own section, `progression.md` section 8.4,
and the functions named. **Do not change** `buy_skill`'s signature (the
`buy_skill` scenario verb calls it) or the once-per-open tile resolution in
`_rebuild` (section 8.4's performance rule).

SK-1 shipped 2026-09-30; its specification is `plans/archive/SK-1_2026-09-30.md`.

SK-2 shipped 2026-10-01; its specification is `plans/archive/SK-2_2026-10-01.md`.
