# Meadow UI — open slices and durable rules

<!-- CONTEXT: plan | LAYER: immediate-task -->
Status: active | Owner: Dave / Claude Code | Next: UI-U-1 -- step back and forth through Challenge stages | Dependency: UI-U-1's former `debug_panel.gd`/`challenge_runner.gd` lane hold cleared when Challenge 1 Slice 7 shipped; H4 is already integrated. UI-P-5 still wants a live reproduction | Verified: 2026-09-12

**Objective.** The HUD and pre-run menu are legible, correctly placed and
accessible, and every persistent panel takes its rectangle from one owner.

**State.** UI-A through UI-O, UI-P-1 to UI-P-4, UI-P-6 to UI-P-8, UI-Q,
UI-R-1 to UI-R-3 and UI-S-1 to UI-S-4 are shipped and archived
(`plans/archive/UI_SHIPPED_2026-09-01.md`,
`plans/archive/UI_SHIPPED_2026-09-03.md`). Dave's 8 Sep 2026 hands-on pass
confirmed C-3, C-16, C-4, C-8, and the greater part of C-9, C-11 and C-13,
and produced the UI-T group below. Dave's second 9 Sep 2026 pass added
UI-U-1, a developer control for reaching a late Challenge stage without
replaying the whole Challenge. Dave's 10 Sep 2026 pass added UI-M-2 (the
pre-run menu's hexagon titles spilling outside their tiles), shipped the same
day -- see `plans/archive/UI-M-2_2026-09-10.md`. UI-P-5 and UI-U-1 are what
remains, and neither is startable.

## Open slices at a glance

| Slice | Outcome | Owns | Startable | Reasoning |
| --- | --- | --- | --- | --- |
| UI-P-5 | The pre-run menu's placeholder text is missing | `main_menu.gd` | no — live repro | medium |
| UI-U-1 | No way to reach a late Challenge stage without replaying it | `debug_panel.gd`, `challenge_runner.gd` | yes — the former lane hold cleared | medium |

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
(`:599`) steps forward through the ordinary `_advance()` path, so gates,
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
multiplier is 1. **That test cannot be written today** -- no headless run can
start a Challenge, because `challenge_runner.start()` fires only for
`Session.starting_level` 1 or 2 and a `--scenario` launch always sets it to
`Levels.SCENARIO_LEVEL_ID` (found 11 Sep 2026).
`plans/design/architecture-review.md`'s **H4** builds that capability on the
same forward seam this slice extends, and Dave scheduled it on 11 Sep 2026
between Challenge 1's Slices 22 and 24, so it lands first and this slice
extends its seam rather than adding a second. The regression line below
names "the existing Challenge stage-sequence tests", which also do not
exist.

**Regression checks.** The existing Challenge stage-sequence tests; C-5,
which uses the same settings window.

**Completion and documentation.** Note the control in
`plans/reference/check-loop.md`'s list of developer triggers, so the next
check that needs a late stage finds it.

**Note on ownership.** `scripts/debug_panel.gd` is also the Codex lane's
C2-2 file, and `scripts/challenge_runner.gd` is Challenge 1's. This slice
must not be queued while either lane has a branch open in those files.
`plans/README.md`'s sequencing guardrail 14 holds the full list of what is
queued against `challenge_runner.gd` and in what order; this slice is behind
Challenge 1's Slices 22, 23, 24 and 26 in it.

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
  four times in a row, all shipped 2026-09-09; archived.
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
case is still unverified this way. The real cause is still open; it needs
Dave's own screen (headless geometry can't see contrast, DPI, or whatever
about his actual boot differs from a fresh worktree's), not more static
reading.

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
