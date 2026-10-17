# Sprite table

Status: current | Owner: Dave / Claude Code | Next: SP-8a builds the block terrain; HM-1 and HM-2 (`plans/now/hive-and-menu-art.md`) export the hive and menu rows | Dependency: tools/sprites.py | Verified: 2026-10-13

One row per sprite family. `python tools/sprites.py` reads this table and the
art beside it, writes a `<name>_sheet.png` next to each source (with a 1-px
gutter around every frame) and regenerates `scripts/sprite_catalogue.gd`.
`python tools/sprites.py --check` fails on anything stale; `tools/verify.ps1`
runs it. Scale, sizes and the file conventions are in
`plans/design/pixel-art.md`; this file does not repeat them.

To add a sprite: save the file under `assets/sprites/comb/`, `meadow/`,
`bees/` or `menu/`, add one row below (the file name without its extension is the
family), run `python tools/sprites.py`, and commit the results. The exporter
refuses an art file with no row.

Columns:

- **File**: path under `assets/sprites/`.
- **View**: `hive`, `meadow` or `menu` (the top bar's buttons).
- **Layout**: `layers` (bottom layer is the base, each other layer one state;
  frame 0 is the base alone, frame N the base plus layer N), `frames` (every
  layer is a whole frame on its own, with no base: overlays such as the wax
  caps, or stages such as a crumbling soil block), `single` (one image: the
  visible layers flattened, hidden ones left out), `tile` (a repeating tile,
  exported without a gutter),
  `grid WxH rows=a,b,...` (a layer named `sheet` cut into WxH frames, one
  named row each) or `unexported` (kept in the table, not built).
- **Frames**: how many frames the file must give.
- **Levels**: for `layers`, the upper bound in percent of each state layer
  above the base, rising, as `10/25/...`; `-` otherwise.

Comb levels follow one rule (Dave, 12 Oct 2026): the top frame is the full
cell, so its bound is 100 and the frame below it ends at 99; the other
frames share the rest equally, so a cell filled at a steady rate changes
frame at a steady rate. Brood is the exception: the larva's last frame is
still growing (at 100 % the bee emerges), so all nine stages share 0-100
equally.

Block anchors sit at the middle of the block's top face, where the floor
and anything growing on it stand. A full block's side is 14 art pixels
tall and a half block's 7, so a block stacked on another draws that much
higher. How the terrain stacks them is `plans/now/meadow-terrain.md`, SP-8.
- **Anchor**: `x,y` in art pixels within one frame; `-` means the centre.
- **Variants**: recolours the exporter applies, `name: RRGGBB>RRGGBB,...`
  separated by `;`; each adds `<name>_<variant>_sheet.png`. `-` for none.

| Family | File | Shows | View | Layout | Frames | Levels | Anchor | Variants |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| wax_cell_nectar | comb/wax_cell_nectar.aseprite | nectar cell: empty cup, then seven fill levels | hive | layers | 8 | 17/33/50/67/83/99/100 | 16,22 | - |
| wax_cell_nectar_fermented | comb/wax_cell_nectar_fermented.aseprite | fermented nectar: empty cup, then seven fill levels | hive | layers | 8 | 17/33/50/67/83/99/100 | 16,22 | - |
| wax_cell_pollen | comb/wax_cell_pollen.aseprite | pollen cell: empty cup, then five fill levels | hive | layers | 6 | 25/50/75/99/100 | 16,22 | - |
| wax_cell_honey | comb/wax_cell_honey.aseprite | honey cell: empty cup, then seven fill levels | hive | layers | 8 | 17/33/50/67/83/99/100 | 16,22 | - |
| wax_cell_royal_jelly | comb/wax_cell_royal_jelly.aseprite | royal jelly cell: empty cup, then six fill levels | hive | layers | 7 | 20/40/60/80/99/100 | 16,22 | - |
| wax_cell_bee_bread | comb/wax_cell_bee_bread.aseprite | unfermented bee bread, filling and ripening: empty cup, then five fill levels | hive | layers | 6 | 25/50/75/99/100 | 16,22 | - |
| wax_cell_bee_bread_ripe | comb/wax_cell_bee_bread_ripe.aseprite | ripe (fermented) bee bread: empty cup, then five fill levels | hive | layers | 6 | 25/50/75/99/100 | 16,22 | - |
| wax_cell_larva | comb/wax_cell_larva.aseprite | brood: empty cup, then nine growth stages, the last until the bee emerges | hive | layers | 10 | 11/22/33/44/56/67/78/89/100 | 16,22 | - |
| wax_cell_sealed | comb/wax_cell_sealed.aseprite | the wax cap going on, eight stages drawn over a full cell | hive | frames | 8 | - | 16,22 | - |
| hive_skep | meadow/hive_skep.png | the straw skep, your hive in the meadow | meadow | single | 1 | - | - | rival: EBAB3F>8A4A52,563604>2A1216,DDA037>7C424A,B58027>62343B,D39732>723C45,EFBD68>9C5A62,915E0A>4A2A2E,714804>3A1D22 |
| grass_base | meadow/grass_base.png | the repeating meadow grass tile | meadow | tile | 1 | - | - | - |
| grass_block | meadow/grass_block.aseprite | full-height block with the grass top: the floor's top layer | meadow | single | 1 | - | 16,9 | - |
| grass_block_half | meadow/grass_block_half.aseprite | half-height block with the grass top | meadow | single | 1 | - | 16,16 | - |
| soil_block | meadow/soil_block.aseprite | full-height soil block under the top layer, breaking down: frames 1, 2, 4, 5 (5 whole) | meadow | frames | 4 | - | 16,9 | - |
| soil_block_half | meadow/soil_block_half.aseprite | half-height soil block under the top layer | meadow | single | 1 | - | 16,16 | - |
| foragers_meadow_view | bees/foragers_meadow_view.png | meadow forager, 8 directions x 4 wing frames; columns on a 12-px pitch, rows not yet on a grid (SP-6 waits for it on a 16x16 `sheet` layer) | meadow | unexported | 32 | - | - | - |
| hive_meadow_view_large | meadow/hive_meadow_view_large.aseprite | your hive in the meadow, to replace hive_skep (HM-1; layer 0 has art outside the 54x41 canvas) | meadow | unexported | 1 | - | - | - |
| hive_meadow_view_small | meadow/hive_meadow_view_small.aseprite | a rival colony's hive in the meadow, to replace the rival skep (HM-1) | meadow | unexported | 1 | - | - | - |
| menu_icon_forager_window | menu/menu_icon_forager_window.aseprite | top-bar icon: the Foraging window (HM-2) | menu | unexported | 1 | - | - | - |
| menu_icon_hive | menu/menu_icon_hive.aseprite | top-bar icon: switch to the Hive view (HM-2) | menu | unexported | 1 | - | - | - |
| menu_icon_meadow | menu/menu_icon_meadow.aseprite | top-bar icon: switch to the Meadow view (HM-2) | menu | unexported | 1 | - | - | - |
| menu_icon_nursery | menu/menu_icon_nursery.aseprite | top-bar icon: the Nursery window (HM-2) | menu | unexported | 1 | - | - | - |
| menu_icon_skill | menu/menu_icon_skill.aseprite | top-bar icon: the skill tree (HM-2) | menu | unexported | 1 | - | - | - |
