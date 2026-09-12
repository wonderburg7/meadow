# Meadow UI — open slices and durable rules

<!-- CONTEXT: plan | LAYER: immediate-task -->
Status: active | Owner: Dave / Claude Code | Next: UI-W-2 -- see `plans/now/ui-w.md` | Dependency: none | Verified: 2026-09-12

**Objective.** The HUD and pre-run menu are legible, correctly placed and
accessible, and every persistent panel takes its rectangle from one owner.

**State.** UI-A through UI-O, UI-P-1 to UI-P-4, UI-P-6 to UI-P-8, UI-Q,
UI-R-1 to UI-R-3 and UI-S-1 to UI-S-4 are shipped and archived
(`plans/archive/UI_SHIPPED_2026-09-01.md`,
`plans/archive/UI_SHIPPED_2026-09-03.md`). Dave's 8 Sep 2026 hands-on pass
confirmed C-3, C-16, C-4, C-8, and the greater part of C-9, C-11 and C-13,
and produced the UI-T group below. Dave's second 9 Sep 2026 pass added
UI-U-1, a developer control for reaching a late Challenge stage without
replaying the whole Challenge, shipped 12 Sep 2026; see
`plans/archive/UI-U-1_2026-09-12.md`. Dave's 10 Sep 2026 pass added UI-M-2 (the
pre-run menu's hexagon titles spilling outside their tiles), shipped the same
day -- see `plans/archive/UI-M-2_2026-09-10.md`. UI-P-5's 12 Sep live
reproduction showed its placeholder visibly present, so it closed with no code
change; see `plans/archive/UI-P-5_2026-09-12.md`. Dave's 12 Sep 2026 pass
found the whole HUD missing -- a `Rect2` method that does not exist in Godot 4
failed `hud.gd`'s compile and took `main.gd` down with it -- and added two
smaller findings about the settings window. All three shipped the same day as
UI-B-1, together with a Godot boot stage in `tools/verify.ps1` so a parse
error cannot reach `master` again; see `plans/archive/UI-B-1_2026-09-12.md`.

## Open slices at a glance

Dave's 12 Sep 2026 pass opened the UI-W group: the settings window's width,
stage row and Controls list (UI-W-1), Challenge 2's missing Forager to raise
(UI-W-2), a cell tray's third column (UI-W-3) and Dr Gallerin's bubble height
(UI-W-4). Specifications and dependencies: `plans/now/ui-w.md`.

## UI-U-1 — step back and forth through a Challenge's stages

Shipped 12 Sep 2026. Full specification and delivery record:
`plans/archive/UI-U-1_2026-09-12.md`.

## Durable rules

- Presentation may be skipped; simulation and player commands may not.
- `UiTheme` owns palette/type variation rules. Do not add hard-coded
  dark-palette text colours to HUD panels.
- Use one responsive layout value from `ui_layout.gd` for repeated panel
  widths and top-bar geometry; do not size a persistent panel from transient
  label text.
- **No persistent panel may extend past a viewport edge at any supported
  size.** A panel whose content does not fit scrolls inside its own rectangle
  (`ScrollContainer`), exactly as the three left-side windows already do.
  Added 8 Sep 2026, after Dave's pass found the command tray running off the
  bottom edge with its `More…` button unreachable. Setting `Control.size`
  smaller than a control's combined minimum size does not shrink the control
  -- Godot silently keeps the minimum -- so a "cap the height" assignment is
  never on its own enough to satisfy this rule.
- **`custom_minimum_size` is a floor, never a ceiling.** It can only make a
  control bigger. To cap a persistent panel, put the cap on a
  `ScrollContainer` inside it -- the one control allowed to be smaller than
  its contents -- and never on the panel itself. Added 8 Sep 2026: the
  summary panel is capped this way and is pushed over the command tray by any
  child with a wider minimum (C-18).
- **A `ScrollContainer` reports no minimum on the axis it scrolls.** Measure
  content through its child, never through the `ScrollContainer` itself.
  Added 8 Sep 2026: `_resize_command_tray` measured the scroller, got ~0, and
  capped the command tray to nothing (C-18).
- **A layout budget is an outer rectangle.** `UiTheme.panel_stylebox()` adds
  20px vertically and 24px horizontally outside whatever an inner control is
  given, so subtract the panel's chrome before applying a budget inside it.
  Added 8 Sep 2026: this is the missing 20px that ate C-19's 16px gap.
- **Panels resolve in one order** -- command tray, then the bottom row's side
  bands, then the left-side windows, then transient popups -- separated by
  16px and nothing else. `plans/archive/LAY-1_2026-09-08.md` holds the
  hierarchy and the slice that enforced it, now shipped: `ui_layout.gd`
  returns each rectangle and `ui_panel_layout.gd::apply()` is the one place
  that sizes a persistent panel from it.
- **A persistent panel's rectangle is written through offsets, never through
  `size`, `position` or `reset_size()`.** `Control.set_size()` recomputes all
  four anchor offsets from the control's cached position, so any of those
  three converts a bottom-anchored panel into a top-anchored one and it then
  regrows downwards off the screen. Added 9 Sep 2026, after the command tray
  left the viewport for the fourth time (C-18). Only
  `ui_panel_layout.gd::apply()` may write those offsets; a panel script calls
  it and does nothing else to its own geometry.
- **A slice that changes a persistent panel's rectangle ships the
  deterministic assertion with it.** A hands-on check is the wrong instrument
  for runtime geometry: it costs a day per round trip and it caught the same
  defect four times without ever stating the cause. Added 9 Sep 2026; LAY-5
  and LAY-6 (`plans/archive/LAYOUT_REGRESSION_2026-09-09.md`) built the
  harness that makes this cheap -- a geometry slice extends
  `tests/fixtures/layout_panels.json` rather than filing a check.
- **Every persistent panel's outer rectangle now comes from `ui_layout.gd`,
  with no exception left.** Dr Gallerin's bubble was the last one managing
  its own anchor instead: `ui_layout.gd::gallerin_rect()` existed but said so
  in its own comment ("not yet wired to a caller"). HC-14 (10 Sep 2026,
  `plans/archive/HC-14_2026-09-10.md`) wired it through
  `ui_panel_layout.gd::apply()` like every other panel. A new persistent
  panel that sizes or positions itself outside this path is the same mistake
  repeating, not a new one.
- Accessibility settings must work before a run when a menu exposes them, and
  use the existing `Session`/profile preference path.
- A visual/UI slice requires a targeted hands-on check even when static checks
  and a Godot boot pass.

## UI-P — remaining fixes from Dave's 30 Aug hands-on pass

UI-P-1 to P-4 and P-6 to P-8 shipped; see the archive. UI-P-5's 12 Sep live
reproduction found the requested placeholder visibly present, so it closed with
no implementation change; see `plans/archive/UI-P-5_2026-09-12.md`.

### UI-P-5 — pre-run placeholder live reproduction

**Shipped 12 Sep 2026 — no code change; see
`plans/archive/UI-P-5_2026-09-12.md`.** Dave's supplied maximised 1920×1080
capture at default text scale visibly shows `Choose a Challenge or Scenario on
the left.` below the Settings cog. The symptom did not reproduce.

**Symptom (Dave, 30 Aug):** the placeholder text can't be found anywhere on
screen before a Challenge/Scenario is picked.

**Diagnosed, not yet confirmed live:** `main_menu.gd` builds
`detail_placeholder` once (~line 243-252) and adds it as `_detail_column`'s
only initial child. Whatever populates the right pane once something is
selected (the loop at ~line 466 that clears `_detail_column.get_children()`
before adding a stage's own title/blurb/controls) is the prime suspect if it
ever runs before a real selection exists — that would destroy the
placeholder with nothing put back in its place. Check first whether that
populate function runs during `_ready()`/`open()` with no stage chosen yet;
if so, either skip the clear-and-rebuild when nothing is selected (leaving
the placeholder alone) or re-add an equivalent placeholder in that
no-selection branch.

**If that isn't it:** check `right_scroll`'s own rect at first paint — since
UI-O's fix disabled its horizontal scroll (`SCROLL_MODE_DISABLED`) without
giving it an explicit minimum height, it's possible the container computes
a zero-height rect before any child forces it wider, though this is less
likely than the clear-on-populate path above.

**Action:** reproduce live (boot to the menu, don't touch anything, look
for the placeholder) and check `_detail_column`'s children/visibility at
that exact moment before changing code — two plausible causes named above,
pick whichever the live state actually shows.

**Both named causes checked and ruled out (Claude, 10 Sep 2026, UI-M-2
session).** Static reading: `_select_stage`/`_rebuild_detail_pane` (the
clear-and-rebuild loop) are only ever called from a hex tile's
`button.pressed` or a difficulty-preset button's `pressed` — both need a
prior selection to exist, so nothing clears `_detail_column` before a real
pick. A temporary print added to `open()` (`await get_tree().process_frame`
x2, then log `_detail_column`'s child count/visibility and both its own and
`right_scroll`'s `get_global_rect()`, reverted afterwards, not shipped) and
run through a plain headless boot (`Godot.exe --headless --path .`, no
`--scenario` arg, so `Session.menu_pending`'s default `true` opens the menu
the same way a fresh launch does) showed: one child, `visible = true`, rect
`(151, 54)` size `(390, 22)` inside `right_scroll`'s `(151, 54)`-`(541, 894)`
— present, visible, sized, and on-screen. Neither of this heading's two
theories reproduces. The placeholder's `text_secondary` colour
(`ui_theme.gd`'s DARK/LIGHT/HIGH_CONTRAST palettes) all read as reasonably
legible against the backdrop by eye, so that's not an obvious third cause
either, though it was not measured for contrast. Godot's `--resolution` flag
had no effect on the measured rect in headless mode, so the 800x600 edge
case is still unverified this way. Dave's subsequent live capture at 1920×1080
with the default text scale visibly showed the placeholder below the Settings
cog. The symptom did not reproduce, so no code change is warranted.

## Closed groups — pointers only

**UI-D (Challenge top-bar hit areas)** closed 8 Sep 2026: C-3 passed, the
1 Sep `mouse_filter` fix was the cause and the cure, and the `stage_gate.gd`
theory is retired. Diagnosis and the unused geometry fallback are in
`plans/archive/UI_D_CLOSED_2026-09-08.md`.

**UI-R (Dave's 2 Sep 2026 pass)** is entirely shipped and every check has come
back. UI-R-1 was re-specified the same day by UI-S-1. UI-R-3 (the "Fire test
warnings" button) shipped 3 Sep; its check C-4 passed on 8 Sep and the dwell
asymmetry it exposed is UI-Q-3 above. UI-R-2 (the pre-run menu's left inset)
shipped 3 Sep on `codex/UI-R-2`; its check C-16 passed on 8 Sep. The hexagon
clipping Dave reported on the same screen is UI-T-4, not a regression in
UI-R-2. Specifications: `plans/archive/UI_SHIPPED_2026-09-03.md`.

## Deferred decisions

The panel texture needs Dave’s visual direction. Pre-run menu restructuring
and the shared accessibility surface need a separately chosen product slice;
they are not implied by UI-A through UI-D.

The skill-tree UI is no longer an open UI question. Its honeycomb grid, node
states, panel behaviour and the row-2 HUD Skills button are fully specified in
`plans/design/progression.md` sections 8.1-8.5, and belong to the progression
build rather than a UI slice. Read that file before touching
`hud.gd::_build_top_right_bar` or `ui_icon.gd` for skill-tree work.
