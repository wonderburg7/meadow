# Sprite table

Status: current | Owner: Dave / Claude Code | Next: SP-5 adds the skep to the meadow | Dependency: tools/sprites.py | Verified: 2026-10-10

One row per sprite family. `python tools/sprites.py` reads this table and the
art beside it, writes a `<name>_sheet.png` next to each source (with a 1-px
gutter around every frame) and regenerates `scripts/sprite_catalogue.gd`.
`python tools/sprites.py --check` fails on anything stale; `tools/verify.ps1`
runs it. Scale, sizes and the file conventions are in
`plans/design/pixel-art.md`; this file does not repeat them.

To add a sprite: save the file under `assets/sprites/comb/`, `meadow/` or
`bees/`, add one row below (the file name without its extension is the
family), run `python tools/sprites.py`, and commit the results. The exporter
refuses an art file with no row.

Columns:

- **File**: path under `assets/sprites/`.
- **View**: `hive` or `meadow`.
- **Layout**: `layers` (bottom layer is the base, each other layer one state;
  frame 0 is the base alone, frame N the base plus layer N), `single` (one
  image), `tile` (a repeating tile, exported without a gutter),
  `grid WxH rows=a,b,...` (a layer named `sheet` cut into WxH frames, one
  named row each) or `unexported` (kept in the table, not built).
- **Frames**: how many frames the file must give.
- **Levels**: for `layers`, the upper bound in percent of each state layer
  above the base, rising, as `10/25/...`; `-` otherwise.
- **Anchor**: `x,y` in art pixels within one frame; `-` means the centre.
- **Variants**: recolours the exporter applies, `name: RRGGBB>RRGGBB,...`
  separated by `;`; each adds `<name>_<variant>_sheet.png`. `-` for none.

| Family | File | Shows | View | Layout | Frames | Levels | Anchor | Variants |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| wax_cell_nectar | comb/wax_cell_nectar.aseprite | nectar cell: empty cup, then seven fill levels | hive | layers | 8 | 10/25/40/55/70/85/100 | 16,22 | fermented: 487908>8CAD63 |
| wax_cell_pollen | comb/wax_cell_pollen.aseprite | pollen cell: empty cup, then five fill levels | hive | layers | 6 | 20/40/60/80/100 | 16,22 | - |
| hive_skep | meadow/hive_skep.png | the straw skep, your hive in the meadow | meadow | single | 1 | - | - | - |
| grass_base | meadow/grass_base.png | the repeating meadow grass tile | meadow | tile | 1 | - | - | - |
| bee_forager_meadow | bees/bee_forager_meadow.aseprite | meadow forager, 8 directions x 4 wing frames (waits for the repacked sheet, SP-6) | meadow | unexported | 32 | - | - | - |
