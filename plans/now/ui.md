# Meadow UI — open slices and durable rules

<!-- CONTEXT: plan | LAYER: immediate-task -->
Status: active | Owner: Dave / Claude Code | Next: UI-P-5, the only slice this file still owns | Dependency: UI-P-5 wants a live reproduction; the rest of the 8 Sep group has all shipped | Verified: 2026-09-08

**Objective.** The HUD and pre-run menu are legible, correctly placed and
accessible, and every persistent panel takes its rectangle from one owner.

**State.** UI-A through UI-O, UI-P-1 to UI-P-4, UI-P-6 to UI-P-8, UI-Q,
UI-R-1 to UI-R-3 and UI-S-1 to UI-S-4 are shipped and archived
(`plans/archive/UI_SHIPPED_2026-09-01.md`,
`plans/archive/UI_SHIPPED_2026-09-03.md`). Dave's 8 Sep 2026 hands-on pass
confirmed C-3, C-16, C-4, C-8, and the greater part of C-9, C-11 and C-13,
and produced the UI-T group below. Everything still open is on this page.

## Open slices at a glance

| Slice | Outcome | Owns | Startable | Reasoning |
| --- | --- | --- | --- | --- |
| UI-P-5 | The pre-run menu's placeholder text is missing | `main_menu.gd` | no — live repro | medium |

**Where the rest of the open UI work is.** Dave's 8 Sep 2026 hands-on pass
produced seven slices, split by lane so the two can run in parallel without
sharing a file:

- `plans/archive/ui-bottom-row_2026-09-08.md` — UI-Q-3 and UI-T-6, both
  shipped 2026-09-08; C-7 is unblocked and back in `checks/ready.md`.
- `plans/archive/UI-WINDOWS_2026-09-08.md` — UI-W-1 to UI-W-4, from Dave's
  second 8 Sep pass, all shipped 2026-09-08. The left-side windows and the
  settings window.
- `plans/archive/LAY-1_2026-09-08.md` — why five separate panel-placement
  checks failed since 3 Sep, the panel hierarchy Dave asked for on 8 Sep,
  and LAY-1, which shipped one owner of it, 2026-09-08.
- `plans/archive/ui-small-fixes_2026-09-08.md` — delivered UI-T-3, UI-T-4
  and UI-T-5. One script each, independent in the other lane.

Each of those files is archived whole when its group is done; this file keeps
the objective, the durable rules and whatever outlives a single pass.

**Required reading for any slice here.** This file's own section, and
`scripts/ui_layout.gd` for anything touching a persistent panel's rectangle.
Nothing else -- the archives are provenance only.

**Do not change** `scripts/hex_hit_area.gd`, `HEX_SIZE`, `HEX_STEP_X` or tile
centres in any pre-run-menu slice: UI-M's exact-hexagon hit test is built
against the tile's real hexagon at its real position, and every reported
"tiles look wrong" symptom so far has had a cause elsewhere.

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
- Accessibility settings must work before a run when a menu exposes them, and
  use the existing `Session`/profile preference path.
- A visual/UI slice requires a targeted hands-on check even when static checks
  and a Godot boot pass.

## UI-P — remaining fixes from Dave's 30 Aug hands-on pass

UI-P-1 to P-4 and P-6 to P-8 shipped; see the archive. P-5 is all that is
left, and it needs a live reproduction before any code. Dave's 8 Sep pass did
not report on it, so it stays where it is.

### UI-P-5 — pre-run menu: "Choose a Challenge or Scenario on the left." isn't visible

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
