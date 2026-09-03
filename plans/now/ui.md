# Meadow UI — open slices and durable rules

<!-- CONTEXT: plan | LAYER: immediate-task -->
Status: active | Owner: Dave / Claude Code | Next: UI-R-2 (pre-run menu left margin), Codex lane | Dependency: UI-S-1 before UI-S-3; check-loop P-3 before UI-R-3; UI-D and UI-P-5 need a live repro | Verified: 2026-09-03

**Objective.** The HUD and pre-run menu are legible, correctly placed and
accessible, and every persistent panel takes its rectangle from one owner.

**State.** UI-A through UI-O, UI-P-1 to UI-P-4, UI-P-6 to UI-P-8, UI-Q and
UI-R-1 are shipped and archived (`plans/archive/UI_SHIPPED_2026-09-01.md`,
`plans/archive/UI_SHIPPED_2026-09-03.md`). Everything still open is below.

## Open slices at a glance

| Slice | Outcome | Owns | Startable | Reasoning |
| --- | --- | --- | --- | --- |
| UI-R-2 | Pre-run menu's left pane clears the screen edge | `main_menu.gd` | yes | low |
| UI-R-3 | A developer button that fires three warning-banner cases | `debug_panel.gd` | after check-loop P-3 | low |
| UI-S-1 | The bottom row re-specified: tray at 50%, neighbours fill the rest | `ui_layout.gd`, `hud.gd` | yes | medium |
| UI-S-2 | Colony/foraging/nursery windows clear the corner readout and scroll | `ui_layout.gd`, `hud.gd`, the three panel scripts | yes | medium |
| UI-S-3 | The command tray shrinks again and never runs off the bottom | `hud.gd` | after UI-S-1 | medium |
| UI-S-4 | A refused command says so, at one instrumented choke point | `input_selection.gd`, `diagnostic_log.gd` | yes | medium |
| UI-D | Challenge-only top-bar hit areas | unknown | no — code shipped, awaiting check C-3 | high |
| UI-P-5 | The pre-run menu's placeholder text is missing | `main_menu.gd` | no — live repro | medium |

**Dependencies, stated rather than implied.** UI-S-1 moves the numbers UI-S-3
clamps, so it goes first. UI-R-3 adds a button to the developer Triggers
section that `plans/now/check-loop.md` P-3 creates, so P-3 goes first --
otherwise UI-R-3 writes a row that P-3 immediately rewrites. UI-S-2 and
`plans/now/check-loop.md` P-2 both name the panel scripts: P-2 enforces what
UI-S-1 and UI-S-2 land, so it runs after both. Nothing else here is ordered.

**Required reading for any slice here.** This file's own section, and
`scripts/ui_layout.gd` for anything in UI-S. Nothing else -- the archives are
provenance only, and no UI slice needs the whole of this file.

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
- Accessibility settings must work before a run when a menu exposes them, and
  use the existing `Session`/profile preference path.
- A visual/UI slice requires a targeted hands-on check even when static checks
  and a Godot boot pass.

## UI-D — Challenge top-bar hit-area diagnosis

**Confirmed reproduction (hands-on, 28 Aug):** In a Challenge, only a thin
strip along the top of the second-row top-bar buttons responds to a click; the
same controls are fully clickable in a Scenario.

**Cause:** Challenge stage entry calls `hud.gd::set_challenge_goal()`, making
the goal shelf visible. Its `offset_top = 46` overlaps the second top-bar row
(roughly y=40–68), and the shelf itself retains Godot's default input-blocking
mouse filter. Because it is added after the top bar, it receives clicks over
that overlap, leaving only the exposed button top clickable. Scenarios keep
the goal shelf hidden. `stage_gate.gd` controls which buttons are visible, but
is not the cause of the hit-area loss.

**Delivered:** the goal shelf's `mouse_filter` was set to
`Control.MOUSE_FILTER_IGNORE`, restoring full-button clickability under the
overlap. UI-E and UI-F shipped alongside it and are archived at
`plans/archive/UI_SHIPPED_2026-09-01.md`.

**What is actually outstanding is the check, not the code.** C-3 in
`checks/ready.md` is the one thing that will say whether this is fixed. Write
no code here until it comes back failing -- and if it does, the old
`stage_gate.gd` theory is not the established cause.

**If C-3 fails, the fallback is geometry, not another mouse filter.** Place
the shelf below the *full* two-row bar, deriving its top from
`ui_layout.gd`'s shared top-bar geometry rather than the literal
`offset_top = 46` (durable rule: `plans/README.md` guardrail 11), and keep it
input-transparent unless it gains interactive children. Re-check every
top-right control in a Challenge *and* a Scenario, at normal and enlarged
text scales -- enlarged text is what makes the two rows grow into the shelf.
Do not fold this into cosmetic top-bar work.

## UI-P — remaining fixes from Dave's 30 Aug hands-on pass

UI-P-1 to P-4 and P-6 to P-8 shipped; see the archive. P-5 is all that
is left, and it needs a live reproduction before any code.

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

## UI-R — from Dave's 2 Sep 2026 hands-on pass

UI-R-1 shipped 3 Sep and was re-specified the same day by UI-S-1; see the
archive. UI-R-2 and UI-R-3 remain.

### UI-R-2 — pre-run menu: the left edge still needs more room

**Ask (Dave, 2 Sep):** UI-P-4 shipped and the left pane no longer starts at
pixel 0, but the buffer is too small.

**Fix.** `main_menu.gd`'s `const LEFT_PANE_MARGIN := 16` is the whole
mechanism (a `MarginContainer` with `margin_left`). Raise it to `32`.
Change nothing else — not `HEX_SIZE`, `HEX_STEP_X`, tile centres or the
right pane — so UI-M's hit-testing and UI-P-3's border overlap are
untouched.

**Acceptance:** the leftmost hex tile and the left-aligned text sit a
clearly comfortable distance from the screen edge; tile spacing, borders
and click hit-testing are visibly unchanged.

**Files:** `scripts/main_menu.gd`.

### UI-R-3 — no way to trigger a warning-banner case on demand

**Symptom (Dave, 2 Sep):** "I don't have a way to trigger two
warning-banner cases and verify unrelated notifications do not overwrite
each other." The UI-Q-1/UI-Q-2 check has therefore never been runnable and
is now in `checks/blocked.md` with this slice named as its unblocker.

**Why it is a real gap, not just this one check.** The banner's throttle
lives in `hud.gd::show_warning`'s `key -> last shown` dictionary, and the
whole point of slice C2 was arbitration *between* producers. Any future
change to it has the same problem: the only way to see two events collide
is to wait for the simulation to produce a death, a spider escape and a
low-energy warning within eight seconds of each other.

**Fix.** Add a second button to `debug_panel.gd`'s existing `challenge_row`
(the row that already holds "Advance Challenge stage", built just below the
save/load row), labelled "Fire test warnings" and styled with the same
`_style_button` + `UI.with_info` pattern as its neighbour. It calls
`hud.show_warning` three times
through a short scripted sequence: an epitaph-keyed message at t=0, a
crab-spider-escape-keyed message at t=+8s, and a "Run saved."-style
unkeyed confirmation at t=+10s, using the real `problem_messages.gd`
entries and the real `GameConfig` gaps rather than literals. Drive the
delays with one `SceneTreeTimer` chain, not a per-frame state machine.
Keep it in the developer section so it is not reachable in ordinary play.

**Acceptance:** pressing the row once shows all three messages, the first
two do not wipe each other, and the confirmation survives the ambient
event that follows it. `tools/verify.ps1` passes.

**Depends on:** `plans/now/check-loop.md` P-3, which builds the developer
"Triggers" group this button goes into. Do not start UI-R-3 first and add
the button to `challenge_row` -- P-3 would only move it again, and both
slices own this file so they cannot run in parallel lanes.

**Reasoning level:** low. One file, one existing pattern; the message
contents come from `problem_messages.gd` and `GameConfig`, not from a
judgement call.

**Files:** `scripts/debug_panel.gd`.

## UI-S — from Dave's 3 Sep 2026 hands-on pass

Five reports, all about panels sharing the screen with each other. UI-R-1
shipped on 3 Sep and its own check is superseded by UI-S-1 below: Dave's
answer to "is the summary panel too cramped at 800?" was to re-specify the
whole bottom row, so the tray now leads and its neighbours follow, instead
of the tray taking what two fixed reserves leave it.

### UI-S-1 — the bottom row: the command tray leads, the summary panel and Dr Gallerin follow

**Ask (Dave, 3 Sep, two reports, one design).**

1. "The buffer gap between summary window and command window is gone --
   bring it back."
2. "Command window should be positioned in the centre, taking up 50% of
   screen width. The summary panel and Dr's speech bubble should react to
   the command panel's size and fill up the available space if needed, but
   with the 16px buffer. As the screen is resized, the command window
   should resize to get smaller and the summary panel and Dr's speech
   bubble react accordingly."

That is the opposite dependency from what `ui_layout.gd` has today: the
tray is currently sized from what two fixed reserves (`SELECTION_TRAY_RESERVE
= 390`, Gallerin's 544) leave over, then its left edge is clamped, and at
narrow widths the clamp eats the summary panel's own gap -- which is why
the 16px buffer disappeared at the width Dave was testing.

**Fix — rewrite `ui_layout.gd`'s bottom-row block around one rule: the tray
is half the viewport, centred; the two neighbours fill what is left, each
one `SELECTION_TRAY_GAP` clear of it.**

- a) Constants. Add `const COMMAND_TRAY_WIDTH_FRACTION := 0.5`,
  `const SELECTION_TRAY_MIN_WIDTH := 160.0` and
  `const GALLERIN_BUBBLE_MIN_WIDTH := 200.0`. Keep
  `SELECTION_TRAY_LEFT_MARGIN` (16), `SELECTION_TRAY_GAP` (16) and
  `COMMAND_TRAY_MIN_WIDTH` (200). Delete `SELECTION_TRAY_RESERVE`,
  `SELECTION_TRAY_RESERVE_NARROW`, `COMMAND_TRAY_SIDE_GAP` and
  `command_tray_left_reserve()` -- nothing outside this file reads them
  (`grep -rn` to confirm before deleting). `NARROW_BREAKPOINT`/`is_narrow`
  survive only if something else still calls them; if not, delete those too.
- b) `static func command_tray_width(viewport_width: float) -> float`:
  the smaller of `viewport_width * COMMAND_TRAY_WIDTH_FRACTION` and the
  widest tray that still leaves each side band its own minimum, floored at
  `COMMAND_TRAY_MIN_WIDTH`. One side band's minimum is
  `SELECTION_TRAY_GAP + GALLERIN_BUBBLE_MIN_WIDTH + GallerinPanel.BUBBLE_GAP
  + GallerinPanel.ICON_SIZE.x + GallerinPanel.ICON_MARGIN` (= 300 with
  today's constants) -- use the wider of the two sides' minimums for both,
  since the tray is centred and the bands are equal by construction.
- c) `static func command_tray_left_edge(viewport_width: float) -> float`:
  `(viewport_width - command_tray_width(viewport_width)) * 0.5`. Centred on
  the viewport, which is now correct precisely because the two neighbours
  are derived from it rather than fixed.
- d) `selection_tray_width()`: `maxf(0.0, command_tray_left_edge(vw) -
  SELECTION_TRAY_GAP - SELECTION_TRAY_LEFT_MARGIN)`. Unchanged in shape;
  it simply reads the new edge.
- e) `gallerin_bubble_width()`: the right band less the icon and its gaps,
  clamped between `GALLERIN_BUBBLE_MIN_WIDTH` and
  `GallerinPanel.BUBBLE_WIDTH` -- i.e.
  `viewport_width - (left_edge + tray_width) - SELECTION_TRAY_GAP -
  GallerinPanel.ICON_SIZE.x - GallerinPanel.BUBBLE_GAP -
  GallerinPanel.ICON_MARGIN`. `gallerin_reserve_width()` keeps its current
  shape and picks the new bubble width up for free.
- f) `hud.gd::_update_command_tray_width()`: replace
  `UiLayout.command_tray_max_width(...)` with
  `UiLayout.command_tray_width(...)` for both
  `custom_minimum_size.x` and `size.x`; the `offset_left` line already
  reads `command_tray_left_edge`. Delete `command_tray_max_width` once
  nothing calls it. `_apply_selection_tray_width()` and
  `gallerin_panel.gd`'s `gallerin_bubble_width()` call need no change --
  they follow automatically. Make sure both are called on a viewport
  resize, not only on selection change.

**Worked numbers to check the implementation against** (viewport width →
tray width, tray left edge, summary panel width, bubble width):

- 1920 → 960, 480, 448, 380
- 1600 → 800, 400, 368, 300
- 1280 → 640, 320, 288, 220
- 1000 → 500, 250, 218, 150 → bubble floors at 200, so the tray must shrink
  to 400 at this width; recheck the (b) clamp gives that, and correct the
  arithmetic here rather than the rule if it does not
- 800 → 200 (the floor), 300, 268, 200

**Acceptance.** At 1920, 1280 and 800: the command tray is horizontally
centred, is about half the window wide above the floor, and is fully on
screen. There is a visible, equal 16px gap between the summary panel and
the tray, and between the tray and Dr Gallerin's bubble. Dragging the
window narrower shrinks the tray continuously and the panel and bubble
re-fill the space; nothing overlaps at any width down to 800. UI-P-8's rule
still holds: a tray too narrow for its three groups wraps them onto more
rows rather than growing wider.

**Check:** `tools/verify.ps1`. One hands-on check to file, replacing the
"Command tray placement (UI-R-1)" entry in `checks/ready.md`.

**Files:** `scripts/ui_layout.gd`, `scripts/hud.gd`.

### UI-S-2 — the colony, foraging and nursery windows sit on top of the corner readout

**Ask (Dave, 3 Sep).** "Left side panel windows are still overlapping with
summary windows, rather than the panel windows fitting the space, with a
buffer and scroll bar." And: "Colony/nursery windows overlap with summary.
These should appear under the top-left text (under the nectar/pollen/summary
line details) and have a slight buffer between the summary window and a
scroll bar if this means that all the content can't be seen. The buffer
space should be the same as the buffer space used between the summary
window and the command panel." Plus: "Opening the colony/foraging/nursery
panel should close any others of these panels."

**Diagnosed.** Each of the three panels places itself with a literal:
`colony_panel.gd` and `foraging_panel.gd` set `offset_top = 60`,
`nursery_panel.gd` sets `offset_top = 150`, all three `offset_left = 16`,
all three `PRESET_TOP_LEFT`, none with a height cap or a `ScrollContainer`.
The thing they must clear is `hud.gd`'s `corner_column` -- a `VBoxContainer`
at `(16, 12)` whose height changes with how many readouts the player has
starred, which is exactly why a fixed 60 or 150 cannot be right.

**Fix.**

- a) `ui_layout.gd`: add
  `static func left_window_top(corner_bottom: float) -> float` returning
  `corner_bottom + SELECTION_TRAY_GAP`, and
  `static func left_window_max_height(viewport_height: float, top: float) -> float`
  returning `maxf(120.0, viewport_height - top - SELECTION_TRAY_GAP)`. One
  gap constant for all three edges, which is what "the same buffer as
  between the summary window and the command panel" means.
- b) `hud.gd`: add `func corner_bottom() -> float` returning
  `corner_column.position.y + corner_column.size.y`, so the panels ask the
  HUD rather than reaching into its nodes.
- c) All three panels: wrap the existing content `VBoxContainer` in a
  `ScrollContainer` (`horizontal_scroll_mode = SCROLL_MODE_DISABLED`,
  vertical automatic) inside the `PanelContainer`, and give each a
  `func _apply_left_window_rect() -> void` that sets `panel.offset_top`
  from `left_window_top(main.hud.corner_bottom())` and the
  ScrollContainer's `custom_minimum_size.y` from
  `left_window_max_height(...)`. Call it when the panel is opened, and on
  `get_viewport().size_changed`. Keep `offset_left = 16` and each panel's
  existing `custom_minimum_size.x`.
- d) `year_winter.gd::_toggle_panel()` and `_on_nursery_window_requested()`:
  before opening any one of the three, close the other two. One list, walked
  once -- do not add a third pairwise special case.
- e) No literal `offset_top` may remain in the three panel files.

**Acceptance.** With several readouts starred (a tall corner block) and
with none, opening Colony, Foraging or Nursery puts the window's top edge
one 16px gap below the last line of corner text, never over it. A window
whose content is taller than the space left scrolls inside itself and stays
on screen. Opening any one of the three closes whichever of the other two
was open. The nursery window still opens the hive view and its zone glow
as before.

**Check:** `tools/verify.ps1`. One hands-on check to file.

**Files:** `scripts/ui_layout.gd`, `scripts/hud.gd`,
`scripts/colony_panel.gd`, `scripts/foraging_panel.gd`,
`scripts/nursery_panel.gd`, `scripts/year_winter.gd`.

### UI-S-3 — the command tray grows but never shrinks, and can run off the bottom of the screen

**Ask (Dave, 3 Sep).** "When tapping the 'more…' option in the command
panel, the panel resizes accordingly, but doesn't go back to its original
height when 'more…' is selected again." And: "Sometimes the cell command
panel extends past the bottom of the screen."

**Diagnosed.** `command_tray` is a `PanelContainer` anchored
`PRESET_BOTTOM_LEFT` with `grow_vertical = GROW_DIRECTION_BEGIN` and
`offset_bottom = -16`, so its height comes from its content's combined
minimum size. Both `More…` buttons (`more_button` for a bee,
`cell_more_button` for a cell) only flip a child's `visible` flag; nothing
asks the tray to recompute its own rect afterwards, so it keeps the larger
size it grew to. The same missing recompute is the likely cause of the
second report: `show_cell_popup` already works around a stale
`HFlowContainer` sort with a `queue_sort()` and a deferred
`_update_command_tray_width()`, which is the same class of bug seen from
the other side -- rows drawn outside the rect the panel thinks it has.

**Fix.**

- a) `hud.gd`: add `func _resize_command_tray() -> void` that, on the next
  frame (`await get_tree().process_frame`, or `call_deferred` on a plain
  helper -- match whichever style the file already uses), calls
  `command_tray.reset_size()` and then `_update_command_tray_width()`.
- b) Call it from both `More…` handlers, from `show_cell_popup`, from
  `update_selection` and from the viewport `size_changed` handler. Delete
  `show_cell_popup`'s bespoke `call_deferred("_update_command_tray_width")`
  in favour of the one helper.
- c) Clamp the height as well as the width, in the same helper: if
  `command_tray.size.y` exceeds
  `viewport_height - SELECTION_TRAY_GAP * 2.0`, cap it there. A tray that
  tall is already a design problem, but it must not leave the screen.

**Acceptance.** Open `More…` on a bee's tray and close it again: the tray
returns to exactly its previous height. The same for a selected cell's
`More…`. Select a cell with every action row available at 800x600 and the
whole tray stays on screen. Resizing the window while the tray is open
re-lays it out rather than leaving a stale rect.

**Check:** `tools/verify.ps1`. One hands-on check to file.

**Files:** `scripts/hud.gd`.

### UI-S-4 — a second right-click sometimes does nothing and drops the selection

**Symptom (Dave, 3 Sep).** "Sometimes when I try to move the queen twice
(i.e. a right-click followed by a second right-click) -- and this may count
for other bees -- she doesn't move and becomes unselected."

**What has been ruled out by reading the code, so the next session does not
repeat it.** `input_selection.gd::_issue_command` is reached on every
right-click press (`_unhandled_input`, `MOUSE_BUTTON_RIGHT`, `event.pressed`),
does not clear the selection on any branch, and `Bee.command_move_to` is
re-entrant (it re-derives the target and re-assigns the state; the
`_release_everything()` after it does not touch `move_target`). No
right-click path calls `set_selected(false)` or `selected_bees.clear()`.
`ClickMarker` is a plain `Node2D` and cannot swallow input.

**Two candidate causes, both reachable from a second right-click.**

1. **The command was rejected, and the rejection reads as a deselection.**
   `_issue_command` returns early when every selected bee is filtered out
   by `challenge_runner.is_bee_command_locked(b)`, and
   `hud.update_selection` hides the whole command tray for a locked
   selection (`command_tray.visible = ... and not
   _selection_has_command_lock(bees)`). A bee that stays selected but loses
   her tray looks unselected.
2. **A stage or panel refresh rebuilt the selection under the click.**
   `challenge_runner._apply_stage_gate_to_ui()` ends with
   `main.hud.update_selection(main.selected_bees)`, which is also what
   clears camera-follow (see `plans/now/challenge-1.md` Slice 14). If a
   command completes a stage, the refresh lands in the same frame as the
   second click.

**Fix — make the answer visible first, then act on it. Both parts ship
together.**

- a) Instrument the choke point: in `_issue_command`, log one
  `DiagnosticLog` event per right-click with the selected count, the
  commandable count, the branch taken (exit / return / cell / flower /
  move), and each target bee's id and state before and after. Follow the
  shape of an existing `DiagnosticLog.log_*` helper; this is a diagnostic
  event, not a `print`.
- b) Fix what is already provably wrong regardless of which cause it is: a
  right-click that commands nothing must not silently do nothing. When
  `commandable` is empty, do not draw the click marker, and show the
  existing warning-banner channel's "she cannot take orders right now"
  message (`hud.show_warning`, keyed so it throttles). When a selected bee
  has become invalid, prune it from `main.selected_bees` and refresh the
  selection rather than filtering it out silently on every click.

**Acceptance.** `tools/verify.ps1` passes. A right-click that cannot be
obeyed says so instead of appearing to do nothing. The diagnostic log
records every command issue, so Dave's next reproduction pins the cause to
one branch.

**Check:** `tools/verify.ps1`. One hands-on check to file: reproduce the
double right-click, then send the run's diagnostic log; the follow-up fix
is scoped from that, not guessed.

**Files:** `scripts/input_selection.gd`, `scripts/diagnostic_log.gd`,
`scripts/hud.gd`.

## UI-Q — the warning banner: one open decision

UI-Q-1 and UI-Q-2 landed 1 Sep 2026 (archive). What they deliberately
left undone:

**Deliberately not done:** a priority/dwell rule so a transactional
confirmation can't be wiped mid-display by an unrelated ambient event (or
vice versa) — that needs its own severity/priority design, not a second
overlapping concept bolted onto the key/gap shape above.

## Deferred decisions

The panel texture needs Dave’s visual direction. Pre-run menu restructuring
and the shared accessibility surface need a separately chosen product slice;
they are not implied by UI-A through UI-D.

The skill-tree UI is no longer an open UI question. Its honeycomb grid, node
states, panel behaviour and the row-2 HUD Skills button are fully specified in
`plans/design/progression.md` sections 8.1-8.5, and belong to the progression
build rather than a UI slice. Read that file before touching
`hud.gd::_build_top_right_bar` or `ui_icon.gd` for skill-tree work.
