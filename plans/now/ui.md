# Meadow UI — open slices and durable rules

<!-- CONTEXT: plan | LAYER: immediate-task -->
Status: active | Owner: Dave / Claude Code | Next: None — plan complete (UI-Y shipped; hands-on check C-60) | Dependency: none | Verified: 2026-09-19

**Objective.** The HUD and pre-run menu are legible, correctly placed and
accessible, and every persistent panel takes its rectangle from one owner.

**State.** Every UI group before UI-W has shipped and is archived: UI-A to
UI-O, UI-P, UI-Q, UI-R, UI-S, UI-T, UI-U-1, UI-M-2 and UI-B-1. The archive
records are named under "Closed groups" below. `tools/verify.ps1` has run a
Godot boot since 12 Sep 2026, so a parse error cannot reach `master` the way
UI-B-1's did.

## Open slices at a glance

- **UI-Y** -- toggleable panel background texture (comb relief / colour
  grain), per Dave's 19 Sep 2026 visual direction. See below.

Dave's 12 Sep 2026 pass (UI-X-1 through UI-X-4: the settings window's
width, stage row and Controls list, Challenge 2's missing Forager to raise, a
cell tray's third column and Dr Gallerin's bubble height) shipped 18 Sep
2026 -- see `plans/archive/UI-X_2026-09-18.md`.

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

All closed. UI-P-1 to P-4 and P-6 to P-8 shipped
(`plans/archive/UI_SHIPPED_2026-09-01.md`,
`plans/archive/UI_SHIPPED_2026-09-03.md`). UI-P-5 closed with no code change
after its live reproduction showed the placeholder present; the diagnosis,
the two ruled-out causes and the measurement are in
`plans/archive/UI-P-5_2026-09-12.md`.

UI-Y shipped 2026-09-19; its specification is `plans/archive/UI-Y_2026-09-19.md`.

## Closed groups — pointers only

- **UI-D** (Challenge top-bar hit areas), closed 8 Sep 2026:
  `plans/archive/UI_D_CLOSED_2026-09-08.md`.
- **UI-R** (Dave's 2 Sep 2026 pass), entirely shipped with every check back:
  `plans/archive/UI_SHIPPED_2026-09-03.md`.

## Deferred decisions

Dave's 19 Sep 2026 pass answered all three questions this section used to
defer:

- **Panel texture** -- specified and queued as UI-Y above, no longer
  deferred.
- **Pre-run menu restructuring** -- not a problem; closed with no slice.
- **Shared accessibility surface** -- already shipped, no new surface
  needed. `main_menu.gd`'s Settings button (UI-M) opens the same settings
  window, expanded straight to Accessibility/Appearance, before a run
  starts (`main_menu.gd:290-296`). Every Accessibility key it edits --
  `colour_blind_mode`, `text_scale` and the rest -- is a field on the
  `Session` singleton (e.g. `session.gd:116`), which no preset's or
  Challenge's `keys_to_reset()` touches (`scenario_presets.gd:112`), so a
  choice made in the main menu carries unchanged into the run and into a
  Challenge.

The skill-tree UI is no longer an open UI question. Its honeycomb grid, node
states, panel behaviour and the row-2 HUD Skills button are fully specified in
`plans/design/progression.md` sections 8.1-8.5, and belong to the progression
build rather than a UI slice. Read that file before touching
`hud.gd::_build_top_right_bar` or `ui_icon.gd` for skill-tree work.
