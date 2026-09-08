# The HUD bottom row — Dave's 8 Sep 2026 pass

<!-- CONTEXT: plan | LAYER: immediate-task -->
Status: active | Owner: Dave / Claude Code | Next: UI-T-6 -- the command tray fills its rectangle again | Dependency: none -- UI-T-6 is startable now, behind UI-Q-3 in the same lane because both edit scripts/hud.gd | Verified: 2026-09-08

**Objective.** No persistent HUD panel leaves the screen or covers another,
and a double right-click stops closing the panels behind a selection that is
still there.

**UI-T-1 shipped 2026-09-08 and its check C-18 came back failing.** The tray
no longer runs off the bottom edge -- that half is fixed and stays fixed --
but the cap it introduced collapsed the tray to a bar a few pixels high with
no buttons in it at all. UI-T-6 below owns the fix, and C-5 and C-7 remain
unrunnable until it lands.

**Why the rest are one file.** Every one of them edits `scripts/hud.gd`, so
they are a single lane worked top to bottom. The three one-file fixes from the
same pass are archived in `plans/archive/ui-small-fixes_2026-09-08.md`; they
shared no file with these.

**UI-S-4b shipped 2026-09-08** (`plans/archive/UI-S-4b_2026-09-08.md`): the
duplicate `double_click` event is now ignored at the input boundary, and
`hud.gd`'s panel-hide sites are logged. C-23 replaces C-14 in
`checks/ready.md`.

## Open slices at a glance

| Slice | Outcome | Owns | Startable | Reasoning |
| --- | --- | --- | --- | --- |
| UI-Q-3 | Warning dwell: a short message is no longer cut to 1-2s | `hud.gd` | yes | medium |
| UI-T-6 | The command tray shows its buttons and keeps its 16px gaps | `hud.gd`, `ui_layout.gd` | yes | medium |

**Dependencies, stated rather than implied.** The order in the table is the
order to work in, and the only reason for it is that both edit
`scripts/hud.gd`. No slice here depends on another's behaviour.

**Required reading for any slice here.** This file's own section and nothing
else -- the archives are provenance only, and no slice here needs the whole
of this file. `plans/now/ui.md`'s "Durable rules" apply to all of them.

**Check ids C-18 to C-25 are reserved** across this file,
`plans/archive/ui-small-fixes_2026-09-08.md` and `plans/now/season-balance.md`, so two lanes
filing checks at once cannot collide: C-18 UI-T-1, C-19 UI-T-2, C-20 UI-T-3,
C-21 UI-T-4, C-22 UI-T-5, C-23 UI-S-4b, C-24 SB-1, C-25 SB-2. C-26 to C-28
were reserved by Dave's 8 Sep second pass: C-26 UI-W-2, C-27 UI-W-3/UI-W-4,
C-28 LAY-1 (`plans/now/ui-windows.md`, `plans/now/ui-layout-ownership.md`).
UI-Q-3 re-files C-4 and UI-T-6 re-files C-18, rather than taking new ids.

UI-T-2's completed specification: `plans/archive/UI-T-2_2026-09-08.md`.

## UI-T — the bottom row's rectangles

UI-T-1 and UI-T-2 shipped 8 Sep 2026; both of their checks came back with
faults, and the two faults have the same shape. `plans/now/ui-layout-ownership.md`
holds the full four-cause diagnosis and the panel hierarchy Dave asked for on
8 Sep 2026; this slice is the bottom row's half of the repair, and LAY-1 in
that file consolidates it afterwards.

### UI-T-6 — the command tray fills its rectangle again, and the bottom row keeps its gaps

**Reasoning level: medium.** Two bounded changes in one file, both with a
named cause and a stated correct expression. It blocks C-5 and C-7 and the
back half of every Challenge run, so it is the highest item in its lane after
UI-Q-3.

**Evidence (Dave, 8 Sep 2026, C-18).** "The command bar now appears as a flat
bar at the bottom of the screen. It doesn't go off screen, which is good, so
the lowest level of the panel is correct, but it is only a few pixels high
and doesn't display any buttons/choices." And: "Width seems appropriate at
different screen sizes, but the summary window still overlaps and there's no
16px gap between the summary window and command panel."

**Fault 1 — the tray is capped to zero.** `_resize_command_tray` reads

```gdscript
var content_height: float = command_scroll.get_combined_minimum_size().y
command_scroll.custom_minimum_size.y = minf(content_height, ceiling)
```

`command_scroll` is a `ScrollContainer` with
`vertical_scroll_mode = SCROLL_MODE_AUTO`. Godot omits a child's minimum on
any axis a ScrollContainer can scroll, so `get_combined_minimum_size().y` is
approximately zero however much the tray holds. The cap is therefore set to
zero every time and the tray renders as its own chrome.

**Fix 1.** Measure the scrolled content, not the scroller. `command_scroll`
has exactly one child, the `VBoxContainer` built in `_build_command_tray` as
`column`. Store it in a `var command_content: VBoxContainer` field when it is
built, and measure `command_content.get_combined_minimum_size().y`. Then
subtract the tray panel's own chrome from `ceiling` before the `minf`, since
`command_tray_max_height` is a budget for the panel's outer rectangle and the
value is being applied inside it:

```gdscript
var chrome: float = UiLayout.panel_chrome_height()
var content_height: float = command_content.get_combined_minimum_size().y
command_scroll.custom_minimum_size.y = minf(content_height, maxf(0.0, ceiling - chrome))
```

Add `panel_chrome_height()` to `scripts/ui_layout.gd` as a static function
reading `UiTheme.panel_stylebox()` -- `content_margin_top + content_margin_bottom`
plus the top and bottom border widths -- rather than writing `20.0` out as a
literal. LAY-1 later generalises it to a `Vector2`; do not pre-empt that here.

**Fault 2 — the summary panel can grow through its gap.**
`_apply_selection_tray_width` sets only

```gdscript
selection_panel.custom_minimum_size.x = width
selection_column.custom_minimum_size.x = width
```

`custom_minimum_size` is a floor. `UiLayout.selection_tray_width` already
leaves the correct 16px gap, but a child whose own minimum width is larger --
the cog row, a soil button, an unwrapped word -- makes the panel wider than
the floor and pushes it over the tray.

**Fix 2.** Keep both assignments (they still set the intended width when the
content is narrower) and add, after them:

- `selection_panel.size.x = width`, so the anchored panel takes the width now
  rather than only when its content happens to agree; and
- a hard cap on the content: set `selection_column.custom_minimum_size.x` to
  `width - UiLayout.panel_chrome_width()` rather than to `width`, so the
  column is sized for the space inside the panel's 10px margins and 2px
  border instead of the panel's outer width. Add `panel_chrome_width()`
  alongside `panel_chrome_height()`.
- Give `soil_mark_btn` and `soil_clear_btn`
  `autowrap_mode = TextServer.AUTOWRAP_WORD_SMART` and
  `clip_text = true`, and the cog `MenuButton` a fixed
  `custom_minimum_size.x` of 24, so no single child can raise the column's
  minimum width above the space it has been given. The labels already
  autowrap and need no change.

**Verify the gap arithmetically, not by eye.** After both fixes,
`selection_panel.position.x + selection_panel.size.x + UiLayout.SELECTION_TRAY_GAP`
must be less than or equal to `command_tray.position.x` at 1920x1080,
1280x720 and 800x600. Add that as an assertion in `tests/source_checks.py`
only if it can be expressed against `ui_layout.gd`'s pure functions; if it
needs a live viewport, leave it to C-18 rather than writing a test that
cannot run headless.

**Do not change** `UiLayout.command_tray_width`,
`command_tray_left_edge` or `selection_tray_width` -- Dave confirmed the
widths are right at every screen size, and all three are pure functions with
balance tests behind them. Do not change what the tray contains, and do not
touch `more_panel`'s open/close behaviour.

**Check to file:** re-file C-18, adding the two clauses Dave's report added:
the tray shows its Job/Focus/Orders buttons at every tested size, and the
16px gap to the summary panel is present with a long bee name selected.

## UI-S — from Dave's 3 Sep 2026 hands-on pass

UI-S-1, UI-S-2 and UI-S-3 shipped 3 Sep 2026 and are archived in
`plans/archive/UI_SHIPPED_2026-09-03.md`. Their checks came back on 8 Sep
2026: C-13's window behaviour passed except for the summary-panel overlap now
owned by UI-T-2, and C-11/C-12 failed on the vertical containment now owned
by UI-T-1.

UI-S-4 shipped 3 Sep 2026 and its check C-14 came back failing. The
diagnostic it added did its job: UI-S-4b shipped 2026-09-08 off the back of
it (`plans/archive/UI-S-4b_2026-09-08.md`).

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

**Check to file:** re-file C-4 against the new dwell rule.

