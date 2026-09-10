# Meadow UI — open slices and durable rules

<!-- CONTEXT: plan | LAYER: immediate-task -->
Status: active | Owner: Dave / Claude Code | Next: UI-M-2, a hexagon's title fits inside it | Dependency: UI-U-1 waits for both lanes to vacate `debug_panel.gd` and `challenge_runner.gd`; UI-P-5 wants a live reproduction | Verified: 2026-09-10

**Objective.** The HUD and pre-run menu are legible, correctly placed and
accessible, and every persistent panel takes its rectangle from one owner.

**State.** UI-A through UI-O, UI-P-1 to UI-P-4, UI-P-6 to UI-P-8, UI-Q,
UI-R-1 to UI-R-3 and UI-S-1 to UI-S-4 are shipped and archived
(`plans/archive/UI_SHIPPED_2026-09-01.md`,
`plans/archive/UI_SHIPPED_2026-09-03.md`). Dave's 8 Sep 2026 hands-on pass
confirmed C-3, C-16, C-4, C-8, and the greater part of C-9, C-11 and C-13,
and produced the UI-T group below. Dave's second 9 Sep 2026 pass added
UI-U-1, a developer control for reaching a late Challenge stage without
replaying the whole Challenge. Dave's 10 Sep 2026 pass added UI-M-2: the
pre-run menu's hexagon titles now spill outside their tiles, because the tile
sizes text from the theme and its label box from a fixed constant. Everything
still open is on this page.

## Open slices at a glance

| Slice | Outcome | Owns | Startable | Reasoning |
| --- | --- | --- | --- | --- |
| UI-M-2 | Hexagon titles spill outside their tiles (C-33) | `main_menu.gd` | yes | low |
| UI-P-5 | The pre-run menu's placeholder text is missing | `main_menu.gd` | no — live repro | medium |
| UI-U-1 | No way to reach a late Challenge stage without replaying it | `debug_panel.gd`, `challenge_runner.gd` | no — both files are in use | medium |

UI-M-2 and UI-P-5 both own `scripts/main_menu.gd`, but UI-P-5 is not
startable, so UI-M-2 has the file to itself.

## UI-M-2 — a hexagon's title fits inside it, at every text size

**Reasoning level: low.** One label box and two strings, in one file, behind
a clear interface.

**Purpose and intended outcome.** Every Challenge and Scenario tile on the
pre-run menu shows its whole title inside its own hexagon, at every text-size
setting, and the titles read the way Dave wants them to.

**Status and dependencies.** Ready. No dependency. Nothing else open touches
`scripts/main_menu.gd` except UI-P-5, which wants a live reproduction and is
not startable, so there is no contention.

**Observable problems (Dave, 10 Sep 2026).**

- C-33, otherwise a pass: "there's some text spilling over in the main menu
  hexagons."
- A separate ask on the same screen: "In the main menu, in the scenario and
  challenge titles, remove the dash after the scenario number, and remove the
  colon after the challenge number."

**Confirmed root cause.** `main_menu.gd::_make_hex_tile` gives the tile's
label a fixed pixel rectangle: `label.position = Vector2(10.0, 8.0)` and
`label.size = Vector2(bbox.x - 20.0, bbox.y - 16.0)`, where `bbox` comes from
the constant `HEX_SIZE`. The hexagon does not scale with the text-size
setting and neither does that box, but the label's text does — it is
`theme_type_variation = "Small"`, which `ui_theme.gd` scales from
`Session.text_scale`, and which HC-4 raised by 2px for everyone on 9 Sep
2026. The label also has no clipping, so once the wrapped text is taller than
the box it simply paints outside the hexagon. The longest title, "Challenge 2:
Brood, Roles and Expansion", is the first to go.

**Current authoritative owner.** `scripts/main_menu.gd`: the `STAGES` table
owns the titles, `_make_hex_tile` owns the tile's geometry, and `HEX_SIZE`
owns the hexagon's radius.

**Required reading.** This heading and `main_menu.gd::_make_hex_tile`, plus
the `STAGES` table's title entries near the top of the same file.

**Files likely to change.** `scripts/main_menu.gd`.

**Files that must not be changed.** `scripts/ui_theme.gd` — the text sizes
are correct and it is the hexagon that has to accommodate them.
`scripts/hex_hit_area.gd` and `HEX_SIZE` itself — the click regions and the
tessellation both depend on that constant, and changing it moves every tile.

**Requirements.**

1. The tile's title never paints outside its hexagon. Set
   `label.clip_text = true` — or `clip_contents` on the tile — so that
   overflow is impossible by construction rather than by the strings
   happening to be short enough.
2. The title fits rather than being clipped, at the default and the largest
   text scale. Give the label `autowrap` (it already has it) plus a smaller
   type variation or a scaled-down font when the text does not fit, and pick
   *one* mechanism. State in a comment which one and why. Requirement 1 is
   the safety net; requirement 2 is the fix.
3. Titles lose their punctuation after the number:
   `"Challenge 1: First Stores"` becomes `"Challenge 1 First Stores"`, and
   `"Scenario 1 — Queen alone"` becomes `"Scenario 1 Queen alone"`. Change
   all seven entries in the `STAGES` table. The tooltip and the detail-pane
   heading both read `stage.title`, so they follow with no further change.
4. The `✓` completion tick keeps its corner and is not overlapped by a
   wrapped title at the largest text scale.

**Constraints and invariants.** `HEX_SIZE`, `HEX_STEP_X` and
`HEX_BORDER_OVERLAP` do not change: the tiles' positions, the strip's scroll
width and `HexHitArea`'s hit test all derive from them, and C-21 passed on
the current tessellation. The left pane and the detail pane are not in scope.

**Existing patterns to reuse.** `theme_type_variation` for sizing, as every
other label in the file does. `Shapes.hexagon_points` is untouched.

**State-transition and cleanup behaviour.** Tiles are built once per menu
open. If requirement 2 chooses a font size from the current text scale, it
must be recomputed when the appearance settings change while the menu is
open, in whatever the file already does on that signal.

**Runtime policy.** Menu construction only. Nothing per frame.

**Edge cases.** The longest Challenge title and the longest Scenario title at
the largest text scale at 800x600. A completed stage, where the tick is
present. The narrow strip, where the Scenarios row scrolls horizontally.

**Automated acceptance checks.** A LAY-6 `control_rect` fixture entry over
the pre-run menu asserting each tile label's rectangle sits inside its tile's
bounding box, at the default and largest text scales. This is the assertion
that makes requirement 1 provable without Dave.

**Regression checks.** C-21's condition — the leftmost hexagon of both strips
is unclipped and every tile selects its own stage — and C-16's left-pane
inset. Neither may change.

**Save/load.** None.

**Completion and documentation updates.** Update this plan's glance table and
Status line, archive this heading, and file one check covering the longest
title at the largest text scale plus the new title punctuation.

**Escalate rather than guess if:** requirement 2 cannot fit the longest title
without a font so small it is unreadable. That would mean the hexagons need
to be bigger, which moves `HEX_SIZE` and therefore the whole menu layout —
Dave's call, not the implementer's.

## UI-U-1 — step back and forth through a Challenge's stages

**Reasoning level: medium.** The forward seam exists; the backward one does
not, and stepping backwards has to leave the run in a state the stage can
actually be replayed from.

**What Dave asked (9 Sep 2026).** "Add a way for me to skip through stages in
challenges through an option in Game Settings > World and Start which gives
arrows to skip back and forth through a challenge's phases."

**Why it is worth building now.** Four of the seven checks in Dave's second 9
Sep pass sit at stages 1.12 to 1.14, and reaching them takes a full
playthrough each time. `plans/reference/check-loop.md`'s rule that "a rare
condition ships with the way to trigger it" applies to a stage that is
fifteen stages in. This is the instrument for the whole Challenge 1 group.

**What already exists.** `challenge_runner.gd::debug_advance_stage()`
(`:559`) steps forward through the ordinary `_advance()` path, so gates,
prompts, checkpoints, markers and completion are all exercised rather than
bypassed. The settings window builds its own grouped sections
(`debug_panel.gd::_make_section`) and already holds a "Triggers" group.

**Current authoritative owner.** `scripts/debug_panel.gd` for the settings
window; `scripts/challenge_runner.gd` for stage sequencing.

**Required reading.** This heading; `debug_panel.gd`'s section builder and
its existing Triggers group; `challenge_runner.gd`'s `_advance`,
`_enter_stage`, `_run_stage_effects` and `debug_advance_stage`;
`docs/challenge-stages.md`.

**Files likely to change.** `scripts/debug_panel.gd`,
`scripts/challenge_runner.gd`.

**Files that must not be changed.** `scripts/challenge_stages.gd` — stage
data does not change to make stepping possible. `scripts/saving.gd`.

**Requirements.**

1. In the settings window's "World and Start" group, add one row: a `◀`
   button, the current stage's id and goal text, and a `▶` button. The row is
   present only while a Challenge run is active, and hidden otherwise rather
   than disabled with no explanation.
2. `▶` calls the existing `debug_advance_stage()`. Do not add a second
   forward path.
3. `◀` is new: add `debug_retreat_stage()` beside it, stepping `_stage_index`
   back one and re-entering through the same `_enter_stage()` the forward
   path uses, so gates, prompts and markers are rebuilt identically.
4. Before leaving a stage in either direction, run that stage's `on_exit`
   effects, then `_run_stage_effects(["camera_follow_off",
   "speed_multiplier:1.0"])` unconditionally — the same belt-and-braces
   Slice 19 put on `_complete()`. A skipped stage must never leave 4x speed
   or a followed camera behind.
5. Disable `◀` on the first stage and `▶` on the last, so the ends are
   visible rather than silent.

**Constraints and invariants.**

- The runner owns stage state. The settings window calls two public methods
  and reads the current stage; it never writes `_stage_index`.
- Stepping backwards does **not** undo world state — the hive, the cells and
  the bees stay as they are. Say so in the row's tooltip, because a stage
  whose goal is already satisfied will immediately advance again, and that is
  correct behaviour rather than a bug.
- This is a developer control. It must not appear in a Scenario or open play,
  and it must not be reachable when no Challenge is running.

**State-transition and cleanup behaviour.** Both directions go through
`_enter_stage()`. Any per-stage state the runner resets there
(`_c1_forage_effects_done`, the pollen-prompt timer, the ordered-visit
cursor) is reset by that same call; if any of it is reset only in `_advance`
rather than in `_enter_stage`, move it so both directions get it.

**Edge cases.** Stepping back into a stage whose goal is still satisfied — it
advances again on the next frame, which is expected. Stepping back past a
checkpoint. Stepping forward onto the completion stage. Holding the button
down.

**Automated acceptance checks.** A headless test that steps forward to the
last stage and back to the first, asserting after every step that the stage
id is what was expected, that `main.following_bee` is null and that the speed
multiplier is 1.

**Regression checks.** The existing Challenge stage-sequence tests; C-5,
which uses the same settings window.

**Completion and documentation.** Note the control in
`plans/reference/check-loop.md`'s list of developer triggers, so the next
check that needs a late stage finds it.

**Note on ownership.** `scripts/debug_panel.gd` is also the Codex lane's
C2-2 file, and `scripts/challenge_runner.gd` is Challenge 1's. This slice
must not be queued while either lane has a branch open in those files.

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
- `plans/archive/PANEL_LAYOUT_2026-09-09.md` — **every slice landed and C-19 and C-26 passed.** LAY-2 to LAY-4, from
  Dave's 9 Sep pass, and the Godot behaviour that made the command tray fail
  four times in a row, all shipped 2026-09-09; the file moves to
  `plans/archive/` once the ledger clears.
- `plans/archive/LAYOUT_REGRESSION_2026-09-09.md` — **delivered.** LAY-5 and
  LAY-6, the headless checks that fail when a panel leaves the viewport or a
  control inside one has no usable size, both shipped 2026-09-09.
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
