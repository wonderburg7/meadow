# Typeface size -- every typeface the same width at the same text scale

<!-- CONTEXT: plan | LAYER: immediate-task -->
Status: active | Owner: Dave / Claude Code | Next: TS-1 (theme, menu, comb and Dr Gallerin sizes); TS-2 (the HUD's own size overrides) waits for FC-2 to release `scripts/hud.gd` (GP-4 released it 15 Oct 2026) | Dependency: TS-1 after RR-7's fix (`plans/now/run-repairs.md`); TS-2 after TS-1 | Verified: 2026-10-15

## Objective

Dave's 14 Oct 2026 pass: "some fonts are a lot bigger than others when
the text scale is at the same level, e.g. OpenDyslexic". He chose (in the
pass session) that a typeface is scaled so its text is **the same width**
as Standard at the same text scale, so layouts and hexagon fits hold in
every typeface; OpenDyslexic's letters come out shorter as a result.

## Current state

Verified 14 Oct 2026 against master `3e37ea6`.

- `ui_theme.gd::_refresh_theme_resource` sets every type variation's
  `font_size` to `round(TYPE_SIZES[v] * Session.text_scale)` whatever
  `Session.ui_typeface` is. Typefaces differ in glyph width and x-height
  at one em size, so OpenDyslexic draws far larger than Standard.
- Sizes computed outside the theme, each `base * Session.text_scale`:
  `main_menu.gd::_fit_hex_label` (`base`), `gallerin_panel.gd`
  (`_bubble_label`, `BUBBLE_TEXT_SIZE`), `hive_cell.gd` (the cell label,
  `9.0 * minf(Session.text_scale, 1.5)`), and in `hud.gd` the completed
  goal line, the goal lines (`normal_font_size` 12 and 14) and the corner
  readouts (`CORNER_SIZES`). `hud.gd`'s corner `signature` holds the scale
  but not the typeface.

## Open slices

| Slice | What it does | Files it owns | Startable | Level |
| --- | --- | --- | --- | --- |
| TS-1 | width-matched size per typeface, applied to the theme, menu hexes, comb labels and Dr Gallerin | `scripts/ui_theme.gd`, `scripts/main_menu.gd`, `scripts/gallerin_panel.gd`, `scripts/hive_cell.gd`, tests | no -- after RR-7's fix (`plans/now/run-repairs.md`), and after SP-11, which shares `hive_cell.gd` (SP-10 landed 15 Oct 2026) | medium |
| TS-2 | the same for `hud.gd`'s own size overrides | `scripts/hud.gd`, tests | no -- after TS-1, and after FC-2 releases `hud.gd` (GP-4 released it 15 Oct 2026) | low |

TS-1 -> TS-2. TS-1 runs after RR-7's fix (`plans/now/run-repairs.md`), which owns the menu hexagon fit TS-1's `base` feeds, and keeps `tests.test_rr7_silkscreen_fit` green, so its block is gated until that fix lands. A slice reads its own section only.

```queue-gated
**[Claude] TS-1 -- every typeface is the same width as Standard at the same text scale**
- Plan: `plans/now/typeface-size.md` -- "TS-1 -- width-matched typeface sizes"
- Files: `scripts/ui_theme.gd`, `scripts/main_menu.gd`, `scripts/gallerin_panel.gd`, `scripts/hive_cell.gd`, `tests/ts1_typeface_size_test.gd`, `tests/test_ts1_typeface_size.py`
- Check: `python -m unittest tests.test_ts1_typeface_size` passes: at text scale 1 and 2, for every typeface in the Typeface setting, `REFERENCE_TEXT` drawn at `UiTheme.font_px(TYPE_SIZES["Body"])` in that face is within 8 % of its width in Standard; `python -m unittest tests.test_ho15_menu_hex_fit tests.test_rr5_hex_refit` still pass.
- Proof: `absent: scripts/ui_theme.gd :: typeface_size_factor`
- Next after: TS-2 -- the HUD's own size overrides follow the typeface too
```
## TS-1 -- width-matched typeface sizes

Level: medium.

**True afterwards.**

- `ui_theme.gd` gains `const REFERENCE_TEXT := "The quick brown fox jumps
  over the lazy dog 0123456789"` and `static func
  typeface_size_factor(typeface: String) -> float`: 1.0 for `"sans"` or a
  missing font; otherwise the width of `REFERENCE_TEXT` at size 64 in
  `ThemeDB.fallback_font` divided by its width at size 64 in
  `_typeface_font(typeface)` (`Font.get_string_size`). Cached in a static
  Dictionary per typeface: measured once, never per frame.
- `static func font_px(base: float) -> int` returns
  `int(round(base * Session.text_scale *
  typeface_size_factor(Session.ui_typeface)))`, with a floor of 1.
- `_refresh_theme_resource` uses `font_px` for every size it sets;
  `main_menu.gd::_fit_hex_label`'s `base`, `gallerin_panel.gd`'s bubble
  size and `hive_cell.gd`'s cell label use it too (the cell label keeps
  its 1.5 cap on the scale part: `9.0 * minf(Session.text_scale, 1.5) *
  typeface_size_factor(...)`).
- The test pair follows `tests/rr5_hex_refit_test.gd` and
  `tests/test_rr5_hex_refit.py`.

**Invariants.** Standard ("sans") sizes are exactly what they are today.
A typeface change still refreshes through `UiTheme.refresh()` and
re-fits the menu hexes (RR-5). Nothing is measured per frame.

**Escalate** if a pixel typeface (Munro, Silkscreen) comes out blurred at
its matched size: Dave then chooses between snapping it to its native
multiple and the exact width.

**Hands-on check on landing** (move from `checks/blocked.md` to ready):
C-137.

```queue-gated
**[Claude] TS-2 -- the HUD's own size overrides follow the typeface too**
- Plan: `plans/now/typeface-size.md` -- "TS-2 -- the HUD's own size overrides"
- Files: `scripts/hud.gd`, `tests/ts2_hud_typeface_size_test.gd`, `tests/test_ts2_hud_typeface_size.py`
- Check: `python -m unittest tests.test_ts2_hud_typeface_size` passes: with OpenDyslexic at text scale 1, the corner readouts and goal lines carry `UiTheme.font_px` of their base sizes, and switching typeface rebuilds the corner.
- Proof: `absent: scripts/hud.gd :: UiTheme.font_px`
- Next after: none -- plans/now/typeface-size.md is complete
```
## TS-2 -- the HUD's own size overrides

Level: low. **Gate:** TS-1 landed, and `scripts/hud.gd` released by FC-2
(Codex lane; GP-4 released it 15 Oct 2026).

**True afterwards.** Each `base * Session.text_scale` font size in
`hud.gd` (the completed goal line, the goal lines, the corner readouts)
is `UiTheme.font_px(base)`, and the corner `signature` adds
`Session.ui_typeface` so a typeface change rebuilds the corner.

## Not in the queue, and why

- **TS-1** -- width-matched typeface sizes; waits for RR-7's fix (`plans/now/run-repairs.md`), which owns the menu hexagon fit TS-1's `base` feeds.
- **TS-2** -- the HUD's size overrides; waits for TS-1 and for FC-2 to release `scripts/hud.gd` (GP-4 released it 15 Oct 2026).
