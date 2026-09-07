# The HUD bottom row — Dave's 8 Sep 2026 pass

<!-- CONTEXT: plan | LAYER: immediate-task -->
Status: active | Owner: Dave / Claude Code | Next: UI-T-1 -- keep the command tray wholly on screen | Dependency: none -- UI-T-1 is startable now; the rest follow it in this file's order | Verified: 2026-09-08

**Objective.** No persistent HUD panel leaves the screen or covers another,
and a double right-click stops closing the panels behind a selection that is
still there.

**Why these four are one file.** Every one of them edits `scripts/hud.gd`, so
they are a single lane worked top to bottom. The three one-file fixes from the
same pass are in `plans/now/ui-small-fixes.md` and run in the other lane in
parallel; they share no file with these.

**What this unblocks.** C-5 and C-7 are in `checks/blocked.md` naming UI-T-1,
because both need buttons that are currently below the bottom edge of the
screen. Both move straight back to `checks/ready.md`, unchanged, the moment
UI-T-1 ships.

## Open slices at a glance

| Slice | Outcome | Owns | Startable | Reasoning |
| --- | --- | --- | --- | --- |
| UI-T-1 | The command tray is always wholly on screen | `hud.gd`, `ui_layout.gd` | yes | medium |
| UI-T-2 | Left-side windows shorten instead of covering the summary panel | `ui_layout.gd`, `hud.gd`, the three left panels | after UI-T-1 | medium |
| UI-S-4b | A double right-click stops closing the bee panels | `input_selection.gd`, `hud.gd`, `diagnostic_log.gd` | after UI-T-2 | medium |
| UI-Q-3 | Warning dwell: a short message is no longer cut to 1-2s | `hud.gd` | after UI-S-4b | medium |

**Dependencies, stated rather than implied.** The order in the table is the
order to work in, and the only reason for it is that all four edit
`scripts/hud.gd`. No slice here depends on another's behaviour.

**Required reading for any slice here.** This file's own section and nothing
else -- the archives are provenance only, and no slice here needs the whole
of this file. `plans/now/ui.md`'s "Durable rules" apply to all of them.

**Check ids C-18 to C-25 are reserved** across this file,
`plans/now/ui-small-fixes.md` and `plans/now/season-balance.md`, so two lanes
filing checks at once cannot collide: C-18 UI-T-1, C-19 UI-T-2, C-20 UI-T-3,
C-21 UI-T-4, C-22 UI-T-5, C-23 UI-S-4b, C-24 SB-1, C-25 SB-2. UI-Q-3 re-files
C-4 rather than taking a new id.

### UI-T-1 — the command tray must stay wholly on screen

**Reasoning level: medium.** One file's geometry behind a clear interface,
with an acceptance a player can see.

**Symptom (Dave, 8 Sep 2026, C-11 and C-12).** With a bee or a cell
selected, the command tray runs off the bottom edge of the screen. Its top
starts too low, so the upper rows are cut, and the `More…` button — which
sits below the action columns in the tray's own `VBoxContainer` — is off
screen and unclickable. At the same time the 16px gap between the tray and
the summary panel disappears and the two overlap. Resizing between widths
otherwise behaves as UI-S-1 intended.

**Cause, read off the code (`scripts/hud.gd::_resize_command_tray`, ~line
2502).** The function runs in this order:

```gdscript
command_tray.reset_size()          # size := combined minimum size at the CURRENT width
_update_command_tray_width()       # ...then the width is changed underneath it
var maximum_height := viewport_height - UiLayout.SELECTION_TRAY_GAP * 2.0
command_tray.size.y = minf(command_tray.size.y, maximum_height)
```

Two separate faults, and both have to be fixed:

1. **The order is wrong.** `reset_size()` computes the tray's minimum height
   for whatever width it happens to have at that moment.
   `_update_command_tray_width()` then narrows it. `command_columns` is an
   `HFlowContainer`, so a narrower width means *more wrapped rows*, so the
   real minimum height goes up after the height has already been fixed. The
   `PanelContainer`'s rectangle is now shorter than its content. Because the
   tray is anchored `PRESET_BOTTOM_LEFT` with
   `grow_vertical = GROW_DIRECTION_BEGIN` and a fixed `offset_bottom = -16`,
   a rectangle that is too short has its *top* edge too low, and the
   `VBoxContainer` inside it lays its children out from that top downwards
   and spills past the bottom of the screen. That is precisely Dave's "the
   start/top of the command panel is too low, so some of it can't be seen"
   plus "goes off screen off the bottom".
2. **The height cap does nothing.** `Control.set_size()` clamps the value it
   is given *up* to `get_combined_minimum_size()`. Assigning a smaller
   `size.y` therefore cannot make the tray shorter than its content, so the
   `maximum_height` line has never once limited anything. A cap has to be
   expressed as a scroll region, not as an assignment to `size`.

**Deliver.**

1. In `scripts/ui_layout.gd`, add one function beside the existing
   `left_window_*` helpers, so the tray and the left windows take their
   ceiling from the same place:

   ```gdscript
   ## The tallest the bottom-row command tray may be: everything between the
   ## top of the screen and its own bottom margin, less the shared clearance.
   ## Nothing in the bottom row may exceed this -- see plans/now/ui.md's
   ## "No persistent panel may extend past a viewport edge" rule.
   static func command_tray_max_height(viewport_height: float) -> float:
       return maxf(120.0, viewport_height - BOTTOM_ROW_MARGIN - SELECTION_TRAY_GAP)
   ```

2. In `scripts/hud.gd::_build_command_tray` (~line 936), put the tray's
   existing content `VBoxContainer` (the local `column`) inside a
   `ScrollContainer` instead of adding it to `command_tray` directly:

   - create `command_scroll := ScrollContainer.new()`;
   - `command_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED`
     (the tray's width is owned by `_update_command_tray_width`; it must never
     grow a horizontal bar);
   - `command_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO`;
   - `command_tray.add_child(command_scroll)`, then
     `command_scroll.add_child(column)`;
   - store it in a new `var command_scroll: ScrollContainer` field beside the
     existing `var command_tray: PanelContainer` (~line 358).

   Everything that currently adds to `column` keeps doing so unchanged.

3. Rewrite `_resize_command_tray` so width is settled *before* height, and the
   ceiling is applied to the scroll region rather than to the panel:

   ```gdscript
   func _resize_command_tray() -> void:
       if command_tray == null or not command_tray.visible:
           return
       # Width first: command_columns is an HFlowContainer, so its wrapped row
       # count -- and therefore the tray's real minimum height -- depends on
       # the width it is given. Measuring height at the old width was what put
       # the tray's top edge too low and spilled `More…` off the bottom edge
       # (Dave, 8 Sep 2026, C-11/C-12).
       _update_command_tray_width()
       command_scroll.custom_minimum_size.y = 0.0
       command_tray.reset_size()
       var ceiling: float = UiLayout.command_tray_max_height(
           get_viewport().get_visible_rect().size.y
       )
       # A PanelContainer cannot be made shorter than its content (set_size
       # clamps up to the combined minimum), so the cap goes on the scroll
       # region: it is the one child allowed to be smaller than what it holds.
       var content_height: float = command_scroll.get_combined_minimum_size().y
       command_scroll.custom_minimum_size.y = minf(content_height, ceiling)
       command_tray.reset_size()
   ```

4. Leave `_update_command_tray_width` otherwise as it is. Do **not** remove
   its `command_tray.offset_left` assignment: that is what centres the tray,
   and UI-S-1's summary-panel and Gallerin widths are derived from it.

**Acceptance (what Dave does and sees).** At 1920x1080, 1280x720 and
800x600, select a bee and then a comb cell. In every case the whole command
tray is on screen: its top edge is visible, `More…` is clickable, and opening
`More…` either grows the tray upwards or gives it a scrollbar — never pushes
anything below the bottom of the window. The 16px gap between the tray and
the summary panel on its left, and between the tray and Dr Gallerin's bubble
on its right, is visible at every one of those sizes and while dragging
between them.

**Check to file:** C-18, replacing C-11 and C-12, which this supersedes.

**Unblocks:** C-5 and C-7 move from `checks/blocked.md` back to
`checks/ready.md` the moment this ships — both were unrunnable only because
the buttons they need were below the bottom of the screen.

### UI-T-2 — left-side windows shorten instead of covering the summary panel

**Reasoning level: medium.** Follows UI-T-1 (same file) and touches four
files, but each edit is small.

**Symptom (Dave, 8 Sep 2026, C-13).** Everything else in C-13 passed —
mutual closing, the Nursery hive view and its zone glow, scrolling, and
starring. The one failure: the Colony, Foraging and Nursery windows still sit
on top of, and overlap with, the bee summary panel when one is open at the
same time. Dave's call: "these should not overlap. left-side windows should
shorten in response to the summary window size."

**Cause.** `scripts/ui_layout.gd::left_window_max_height` reserves space
against the top of the screen and the bottom edge, but knows nothing about
the bottom row:

```gdscript
static func left_window_max_height(viewport_height: float, top: float) -> float:
    return maxf(120.0, viewport_height - top - SELECTION_TRAY_GAP)
```

The summary panel is anchored bottom-left, in the same column, so a tall left
window and a visible summary panel claim the same pixels.

**Deliver.**

1. In `scripts/hud.gd`, add an accessor beside the existing `corner_bottom()`
   (~line 1938):

   ```gdscript
   ## The y the bottom row starts at, for the left-side windows to stop
   ## above. Zero when nothing is selected, so a window gets the full height
   ## back the moment the summary panel closes. Mirrors corner_bottom().
   func selection_panel_top() -> float:
       if selection_panel == null or not selection_panel.visible:
           return 0.0
       return selection_panel.position.y
   ```

2. Give `left_window_max_height` a third parameter and subtract the occupied
   bottom row from the space available:

   ```gdscript
   ## `bottom_row_top` is hud.selection_panel_top(): 0 when nothing is
   ## selected, otherwise the y the summary panel starts at. A left-side
   ## window shortens to clear it rather than covering it (Dave, 8 Sep 2026).
   static func left_window_max_height(
       viewport_height: float, top: float, bottom_row_top: float = 0.0
   ) -> float:
       var floor_y: float = viewport_height
       if bottom_row_top > 0.0:
           floor_y = bottom_row_top
       return maxf(120.0, floor_y - top - SELECTION_TRAY_GAP)
   ```

   The default keeps every existing call compiling; all three are updated
   below regardless.

3. Update the three identical `_apply_left_window_rect()` bodies —
   `scripts/colony_panel.gd:371`, `scripts/foraging_panel.gd:113`,
   `scripts/nursery_panel.gd:280` — to pass the new argument:

   ```gdscript
   scroll_container.custom_minimum_size.y = UiLayout.left_window_max_height(
       get_viewport().get_visible_rect().size.y, top, main.hud.selection_panel_top()
   )
   ```

4. The three windows currently only recompute their rectangle in `open()`.
   Selecting a bee while one is already open must reflow it. Add one signal
   `bottom_row_changed` on `hud.gd`, emitted at the end of
   `update_selection()` and of `show_cell_popup()`, and connect each of the
   three panels to it with a handler that calls `_apply_left_window_rect()`
   only when `panel.visible`. Do not have `hud.gd` reach into the three
   panels directly.

**Acceptance.** Open Colony (then Foraging, then Nursery) at a short viewport
height with nothing selected: each fills down to 16px above the bottom edge,
as now. With one still open, select a bee: the window shortens so its bottom
edge sits clear above the summary panel, and its contents scroll inside the
smaller rectangle. Deselect: it grows back. No window ever draws over the
summary panel or the command tray.

**Check to file:** C-19.

## UI-S — from Dave's 3 Sep 2026 hands-on pass

UI-S-1, UI-S-2 and UI-S-3 shipped 3 Sep 2026 and are archived in
`plans/archive/UI_SHIPPED_2026-09-03.md`. Their checks came back on 8 Sep
2026: C-13's window behaviour passed except for the summary-panel overlap now
owned by UI-T-2, and C-11/C-12 failed on the vertical containment now owned
by UI-T-1.

UI-S-4 shipped 3 Sep 2026 and its check C-14 came back failing. The
diagnostic it added did its job: see UI-S-4b.

### UI-S-4b — a double right-click closes the bee panels; the command is not lost

**Reasoning level: medium.** The remaining unknown is presentational, and
the fix is at the input boundary.

**Symptom (Dave, 8 Sep 2026, C-14).** Still happening after UI-S-4. It
affects any bee, not only the queen. "it clocks off their summary
window/command panel so it's as if you're selecting off the bee."

**What the diagnostic log proves — read this before writing code.** UI-S-4's
`command_issue` entries were recovered from
`%APPDATA%\Godot\app_userdata\Meadow - Claude\logs\session_1788822502.jsonl`
(the 7 Sep 2026, ~23:35 run). Seventeen right-clicks, and **every single one
recorded `selected_count: 1`, `commandable_count: 1` and a correct state
transition.** Two pairs are 0.62s and 0.72s apart in `game_time` — those are
the double-clicks, and in both the second command was accepted
(`MOVE_TO_POINT -> MOVE_TO_POINT`).

That rules out the theory UI-S-4 was built on. The selection is **not** lost,
the command is **not** refused, and no bee is pruned. What Dave sees is the
two panels being hidden while the selection behind them is still intact.

**Deliver, in this order.**

1. **Stop processing the duplicate event.** In
   `scripts/input_selection.gd::_unhandled_input` (~line 60), Godot delivers a
   rapid second right-click as a further `InputEventMouseButton` with
   `pressed == true` *and* `double_click == true`, so `_issue_command` runs
   twice. Re-issuing the same order 0.6s later is never useful, and it is the
   only thing that distinguishes a double right-click from two spaced ones:

   ```gdscript
   MOUSE_BUTTON_RIGHT:
       # Godot delivers a fast second right-click as a further pressed
       # event with double_click set, so the same order was issued twice.
       # That duplicate is the only difference between a double right-click
       # and two spaced ones, which is exactly what C-14's symptom tracks
       # (Dave, 8 Sep 2026).
       if event.pressed and not event.double_click:
           _issue_command(main.get_global_mouse_position())
   ```

2. **Log the panel hide, so if the symptom survives step 1 the next session
   does not have to guess again.** Every place that sets
   `selection_panel.visible` or `command_tray.visible` to `false` must say so.
   In `scripts/hud.gd` those are `update_selection` (~line 1974),
   `_refresh_selection_text` (~line 2389) and `show_cell_popup` (~line 1526).
   Add to `scripts/diagnostic_log.gd`, in the same shape as
   `log_command_issue`:

   ```gdscript
   ## Which code path hid the bee summary panel or the command tray, and how
   ## many bees the HUD thought were selected at the time. C-14's symptom is
   ## the panels closing while the selection behind them is provably intact,
   ## so "who hid it" is the one fact the command_issue entries cannot give.
   func log_selection_panels_hidden(source: String, shown_count: int, selected_count: int) -> void:
   ```

   Emit it only on a true -> false transition, so an idle frame does not fill
   the log.

3. Do **not** change `_prune_invalid_selected_bees`, `_finish_drag` or
   `update_selection`'s clearing logic. The log shows none of them is
   involved.

**Acceptance.** Select any bee. Right-click twice in quick succession on a
point in the meadow, on a flower, on the hive marker, and in the hive view on
a comb cell. In every case the bee stays selected, its summary panel and
command tray stay open, and one command is carried out. Right-clicking twice
slowly still works as it does today.

**Check to file:** C-23, replacing C-14.

## UI-Q — the warning banner: dwell and priority

UI-Q-1 and UI-Q-2 landed 1 Sep 2026 (archive). C-4 came back **passing** on
8 Sep 2026: all three messages appeared and none wiped another out. But Dave
timed them — "The first stays for ~6 seconds, the second for ~1-2, the third
for around ~12" — which is the evidence the deferred decision below was
waiting for.

### UI-Q-3 — a message may not be cut to a fraction of its dwell

**Reasoning level: medium.** It is a rule about ordering and severity, not a
layout change, and it decides how every later warning behaves.

**Evidence (Dave, 8 Sep 2026, C-4).** Firing the three test messages eight
and two seconds apart gave dwell times of ~6s, ~1-2s and ~12s. The second —
the crab-spider escape — was cut to a fraction of the time the other two got,
because "Run saved." arrived two seconds later and took the banner.

**Deliver.** The severity/priority design UI-Q-1 explicitly deferred:

- Give each message a minimum dwell it is guaranteed regardless of what
  arrives next, and a severity. A lower- or equal-severity message arriving
  inside another's minimum dwell queues behind it rather than replacing it; a
  strictly higher-severity one still pre-empts immediately.
- Keep the existing key/gap throttle unchanged — it solves a different
  problem (the same message repeating), and C-4 confirmed it works.
- The three test messages must end up with comparable dwell times when fired
  through `debug_panel.gd`'s "Fire test warnings" button.

**Start this only after UI-S-4b**, which is also in `scripts/hud.gd`.

**Check to file:** re-file C-4 against the new dwell rule.

