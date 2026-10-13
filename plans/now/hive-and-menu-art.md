# Hive and menu art -- Dave's meadow hives and top-bar icons in the game

<!-- CONTEXT: plan | LAYER: immediate-task -->
Status: active | Owner: Dave / Claude Code | Next: HM-1 waits for Dave to fit the large hive's art on its canvas; HM-2 is specified and waits for Dave to queue it (his call, 13 Oct 2026) | Dependency: the sprite exporter and table (`plans/now/sprites.md`, SP-2); HM-1 shares `scripts/hive.gd` and `scripts/rival_hive.gd` with SP-8a | Verified: 2026-10-13

## Objective

Dave drew two meadow hives and five top-bar icons on 10 Oct 2026. They are
committed with `unexported` rows in `assets/sprites/SPRITES.md`. This plan
puts them on screen. Scale, file conventions and the exporter route are in
`plans/design/pixel-art.md` and `plans/now/sprites.md`; this plan does not
repeat them.

## Decisions (Dave, 13 Oct 2026)

1. The large hive is the player's hive in the meadow; the small hive is
   every rival colony's hive. Both replace the straw skep (SP-5).
2. The menu icons replace the procedural icons on five top-bar buttons:
   Foraging (`menu_icon_forager_window`), the Hive/Meadow toggle
   (`menu_icon_hive` / `menu_icon_meadow`), Nursery (`menu_icon_nursery`)
   and Skills (`menu_icon_skill`). Colony and Winter keep their procedural
   shapes until Dave draws theirs.
3. Files follow the underscore naming convention; the original dotted
   names were renamed on commit.

## Current state

Verified 13 Oct 2026 against master `59608ae` plus this plan's commit.

- `hive_meadow_view_large.aseprite`: 54x41 canvas (the skep's size), one
  frame, ten layers. Layer 0 has 67 drawn pixels outside the canvas
  (x -2 to 54, y 35 to 46), so `tools/sprites.py` refuses it as anything
  but `unexported`.
- `hive_meadow_view_small.aseprite`: 24x21, one layer.
- `menu/menu_icon_*.aseprite`: five 32x32 one-frame files, one to nine
  layers each; `single` flattens the visible layers.
- `scripts/hive.gd::_ready` draws `SpriteCatalogue.HIVE_SKEP_SHEET` as
  `SkepSprite` at `PixelSprite.MEADOW_SCALE` over a transparent 60x60 hit
  square. `scripts/rival_hive.gd::_ready` draws `HIVE_SKEP_RIVAL_SHEET`
  (the skep's `rival` recolour) over a transparent 52x52 hit square.
  `tests/test_sp5_skep.py` asserts both.
- `scripts/hud.gd::_icon_button` builds each top-bar button from a
  procedural `UiIcon` (`scripts/ui_icon.gd`, a 16x16 `Control` drawing a
  named shape) and a label hidden by default, so the buttons show icons
  only. Shapes: Colony `bee`, Nursery `hex`, Foraging `flower`, Winter
  `snow`, Skills `arrow_up`, the view toggle `hive`. The toggle's icon
  swaps between `flower` and `hive` in `hud.gd` (`view_icon.shape`), so
  Foraging and the Meadow toggle share `flower` today. Only `hud.gd`
  uses `UiIcon`.

## Open slices

| Slice | What it does | Files it owns | Startable | Level |
| --- | --- | --- | --- | --- |
| HM-1 | your hive and rival hives drawn from Dave's meadow hive art | sprite table and catalogue, `scripts/hive.gd`, `scripts/rival_hive.gd`, tests | no -- waits for Dave to fit the large hive on its canvas | medium |
| HM-2 | five top-bar buttons drawn from Dave's menu icons | sprite table and catalogue, `scripts/ui_icon.gd`, `scripts/hud.gd`, tests | no -- waits for Dave to queue it | medium |

Dependencies: HM-2 -> HM-1 by queue order only (HM-2 needs no art fixed
first); neither reads the other's code. HM-1 and
SP-8a (`plans/now/sprites.md`) both edit `scripts/hive.gd` and
`scripts/rival_hive.gd`; both are Claude lane, so the second to land merges
master first. HM-2 edits `scripts/hud.gd`, which the Claude lane's queued
items also edit; it runs after them in the same lane.

## HM-1 -- your hive and rival hives drawn from Dave's meadow hive art

Level: medium.

**Gate:** Dave opens `assets/sprites/meadow/hive_meadow_view_large.aseprite`
in Aseprite and either enlarges the canvas to hold layer 0 (Sprite >
Canvas Size, at least 57x47) or erases layer 0's pixels outside 54x41,
then commits it. `python tools/sprites.py` then reads it without
"art outside the 54x41 canvas".

**True afterwards.**

- Both rows in `SPRITES.md` are `single` with anchors Dave confirms (the
  centre by default) and are exported; `sprite_catalogue.gd` has
  `HIVE_MEADOW_VIEW_LARGE_*` and `HIVE_MEADOW_VIEW_SMALL_*`.
- `hive.gd` draws the large hive and `rival_hive.gd` the small one, each
  at `PixelSprite.MEADOW_SCALE`, footprint centred, as the skep is now.
- `hive_skep`'s row, its art, sheets and the `rival` variant are removed
  once nothing reads them; `tests/test_sp5_skep.py` moves to the new
  constants.
- Runtime: textures are set once in `_ready`; nothing per frame.

**Must not change.** The hit squares (60x60 and 52x52) and so what a click
selects, rival behaviour, and every scenario baseline `verify.ps1` runs.

```queue-gated
**[Claude] HM-1 -- your hive and rival hives drawn from Dave's meadow hive art**
- Plan: `plans/now/hive-and-menu-art.md` -- "HM-1 -- your hive and rival hives drawn from Dave's meadow hive art"
- Files: `assets/sprites/SPRITES.md`, `scripts/sprite_catalogue.gd`, `scripts/hive.gd`, `scripts/rival_hive.gd`, `tests/test_sp5_skep.py`
- Check: `python tools/sprites.py --check` is clean with both hive rows exported and no `hive_skep` row; `python -m unittest tests.test_sp5_skep` passes and asserts `hive.gd` reads `HIVE_MEADOW_VIEW_LARGE_SHEET` and `rival_hive.gd` reads `HIVE_MEADOW_VIEW_SMALL_SHEET`; `.\tools\verify.ps1` is green. Hands-on: in a Colony Run's meadow, your hive shows the large art and a rival's the small art, both crisp.
- Proof: `absent: scripts/sprite_catalogue.gd :: HIVE_MEADOW_VIEW_LARGE_SHEET`
- Next after: none -- `plans/now/hive-and-menu-art.md` is complete
```

## HM-2 -- five top-bar buttons drawn from Dave's menu icons

Level: medium.

**True afterwards.**

- The five `menu_icon_*` rows are `single`, view `menu`, exported to
  `assets/sprites/menu/*_sheet.png` and in `sprite_catalogue.gd`.
- `UiIcon` can draw a catalogue texture in place of its shape: crisp
  (nearest filter), at 1:1, so the icon control is 32x32 (art is never
  scaled by a non-integer, `plans/design/pixel-art.md`). The icon-only
  button width (`icon_width` in `_icon_button`) grows to fit.
- Foraging, Nursery and Skills show their icons; the view toggle shows
  `menu_icon_meadow` while in the hive and `menu_icon_hive` in the
  meadow. Colony and Winter are unchanged.
- Runtime: the texture is set when the bar is built and when the view
  toggles; nothing per frame.

**Must not change.** What each button opens, tooltips, the label toggle
(`Session.show_interface_labels`), and the bar fitting the narrowest
window `plans/reference/ui-rules.md` names.

```queue-gated
**[Claude] HM-2 -- five top-bar buttons drawn from Dave's menu icons**
- Plan: `plans/now/hive-and-menu-art.md` -- "HM-2 -- five top-bar buttons drawn from Dave's menu icons"
- Files: `assets/sprites/SPRITES.md`, `scripts/sprite_catalogue.gd`, `scripts/ui_icon.gd`, `scripts/hud.gd`, `tests/hm2_menu_icons_test.gd`, `tests/test_hm2_menu_icons.py`
- Check: `python tools/sprites.py --check` is clean with the five menu rows exported; `python -m unittest tests.test_hm2_menu_icons` passes and asserts the Foraging, Nursery and Skills buttons hold their menu textures, the view toggle swaps `MENU_ICON_MEADOW_SHEET` and `MENU_ICON_HIVE_SHEET`, and Colony and Winter keep their shapes; `.\tools\verify.ps1` is green. Hands-on: the top bar shows the five icons crisp at 1:1 and still fits the narrowest window.
- Proof: `absent: scripts/sprite_catalogue.gd :: MENU_ICON_HIVE_SHEET`
- Next after: HM-1 -- your hive and rival hives drawn from Dave's meadow hive art
```

## Read on demand

- `plans/design/pixel-art.md`: scales and file conventions
- `scripts/hive.gd::_ready`, `scripts/rival_hive.gd::_ready` (HM-1)
- `scripts/hud.gd::_icon_button` and its `view_icon` swap, `scripts/ui_icon.gd` (HM-2)
- `plans/reference/ui-rules.md` before HM-2
