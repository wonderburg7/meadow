# Typeface size -- every typeface the same width at the same text scale

<!-- CONTEXT: plan | LAYER: immediate-task -->
Status: complete | Owner: Dave / Claude Code | Next: nothing further -- TS-1 landed 17 Oct 2026, TS-2 (the HUD's own size overrides) landed 21 Oct 2026 | Dependency: none | Verified: 2026-10-21

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
| TS-2 | the same for `hud.gd`'s own size overrides | `scripts/hud.gd`, tests | yes (TS-1 landed 18 Oct 2026; FC-2 released `hud.gd` 17 Oct 2026) | low |

TS-1 -> TS-2. TS-1 runs after RR-7's fix (`plans/now/run-repairs.md`), which owns the menu hexagon fit TS-1's `base` feeds, and keeps `tests.test_rr7_silkscreen_fit` green, so its block is gated until that fix lands. A slice reads its own section only.

TS-1 shipped 2026-10-18; its specification is `plans/archive/TS-1_2026-10-18.md`.

## TS-2 -- the HUD's own size overrides

Level: low. **Gate** (cleared): TS-1 landed 18 Oct 2026, and FC-2 released
`scripts/hud.gd` on 17 Oct 2026.

**True afterwards.** Each `base * Session.text_scale` font size in
`hud.gd` (the completed goal line, the goal lines, the corner readouts)
is `UiTheme.font_px(base)`, and the corner `signature` adds
`Session.ui_typeface` so a typeface change rebuilds the corner.

```queue
**[Claude] TS-2 -- the HUD's own size overrides follow the typeface too**
- Plan: `plans/now/typeface-size.md` -- "TS-2 -- the HUD's own size overrides"
- Files: `scripts/hud.gd`, `tests/ts2_hud_typeface_size_test.gd`, `tests/test_ts2_hud_typeface_size.py`
- Check: `python -m unittest tests.test_ts2_hud_typeface_size` passes: with OpenDyslexic at text scale 1, the corner readouts and goal lines carry `UiTheme.font_px` of their base sizes, and switching typeface rebuilds the corner.
- Proof: `absent: scripts/hud.gd :: UiTheme.font_px`
- Next after: none -- plans/now/typeface-size.md is complete
```

## Not in the queue, and why

- Nothing: TS-2 is queued.
