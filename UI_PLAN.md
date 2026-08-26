# Meadow UI — active slices and durable rules

Status: active | Owner: Dave / Claude Code | Next: UI-A HUD integrity batch |
Dependency: none | Verified: 2026-08-26

The delivered redesign and hands-on investigation records are archived at
`docs/archive/UI_PLAN_2026-08-26.md`,
`docs/archive/UI_BUGFIX_PLAN_2026-08-24.md` and
`docs/archive/UI_SETTINGS_PLAN_2026-08-24.md`. This is the only current UI
execution plan.

## Durable rules

- Presentation may be skipped; simulation and player commands may not.
- `UiTheme` owns palette/type variation rules. Do not add hard-coded
  dark-palette text colours to HUD panels.
- Use one responsive layout value from `ui_layout.gd` for repeated panel
  widths and top-bar geometry; do not size a persistent panel from transient
  label text.
- Accessibility settings must work before a run when a menu exposes them, and
  use the existing `Session`/profile preference path.
- A visual/UI slice requires a targeted hands-on check even when static checks
  and a Godot boot pass.

## UI-A — HUD integrity batch

**Scope:** top-right tooltips/icons/consistent sizing, palette-aware
hover/pressed/focus text, remaining HUD summary text contrast, stale scent-mark
text, and optionally the favourite-header icon.

**Files:** `hud.gd`, `ui_theme.gd`; `debug_panel.gd` only for a directly
related category/setting adjustment.

**Acceptance:** all top-right controls have useful tooltips and a consistent
measured height; labels remain readable in Dark, Light and High Contrast while
hovered; expired marks disappear; a favourite action still updates the Colony
view. Acquire typeface assets as a separate asset/licensing commit.

## UI-B — fixed panel widths

**Scope:** make summary and command/cell trays use viewport-derived widths
which update only on layout changes.

**Files:** `hud.gd`, `ui_layout.gd`.

**Acceptance:** bee and cell content cannot change panel width; summary/tray
overlap is absent at normal and enlarged text scales.

## UI-C — nursery removal and two-column cell tray

**Dependency:** UI-B. **Risk:** medium, because nursery reservation participates
in queen laying logic.

**Scope:** remove the nursery-zone reservation mechanic and redesign the tray
around Reserve for / Nursery, with destructive or infrequent controls under
More.

**Acceptance:** the queen’s laying behaviour remains intentional and
deterministic; all cell actions remain reachable; no stale nursery-zone data
or tooltip remains.

## UI-D — Challenge top-bar hit-area diagnosis

Investigate with the observed Challenge-only reproduction before changing
layout. `stage_gate.gd` visibility is a lead, not a conclusion. Keep this
separate from cosmetic top-bar work.

## Deferred decisions

The panel texture needs Dave’s visual direction. Pre-run menu restructuring,
shared accessibility surface and later skill-tree UI need a separately chosen
product slice; they are not implied by UI-A through UI-D.
