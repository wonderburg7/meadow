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

TS-1 -> TS-2. TS-1 runs after RR-7's fix (`plans/now/run-repairs.md`), which owns the menu hexagon fit TS-1's `base` feeds, and keeps `tests.test_rr7_silkscreen_fit` green, so its block is gated until that fix lands. A slice reads its own section only.

TS-1 shipped 2026-10-18; its specification is `plans/archive/TS-1_2026-10-18.md`.

TS-2 shipped 2026-10-21; its specification is `plans/archive/TS-2_2026-10-21.md`.

## Not in the queue, and why

- Nothing: TS-2 is queued.
