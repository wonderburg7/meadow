# UI-X — Dave's 12 Sep 2026 pass: settings window, cell tray, Dr Gallerin

<!-- CONTEXT: plan | LAYER: immediate-task -->
Status: active | Owner: Dave / Claude Code | Next: UI-X-4 -- Dr Gallerin's bubble grows to a third of the window's height | Dependency: none | Verified: 2026-09-18

**Objective.** The findings from Dave's 12 Sep 2026 hands-on pass that belong
to the HUD and the settings window, each fixed at its owner and each with a
headless assertion so the same class of fault fails verification next time.

**State.** UI-X-1, UI-X-2 and UI-X-3 have shipped (`plans/archive/UI-X-1_2026-09-18.md`,
`plans/archive/UI-X-2_2026-09-18.md`, `plans/archive/UI-X-3_2026-09-18.md`).
`plans/now/ui.md` keeps the durable UI rules and points here. The checks
these slices re-open are all back in `checks/ready.md` (C-18's cell half,
C-34, C-52, C-53); C-49's own PASS is about what the stage arrows do and
stays ready.

## Open slices at a glance

| Slice | Outcome from the player's seat | Files owned | Startable | Level |
| --- | --- | --- | --- | --- |
| UI-X-4 | Dr Gallerin's bubble shows a long line in full, up to a third of the window's height, and makes way for an open settings window | `scripts/gallerin_panel.gd`, `scripts/ui_layout.gd` | yes | medium |

**Renamed from UI-W to UI-X on 17 Sep 2026.** The four UI-W ids belonged to
unrelated slices that shipped from the since-archived ui-windows plan on
8 Sep 2026 and are archived under those names, so grepping the archive for
this group's ids found the wrong records, and `tools/slice.ps1`'s archive
gate could be satisfied by an old namesake. The checks these slices re-open
(C-18, C-34, C-52, C-53) name the new ids.

**Required reading for any slice.** Its own section below, and the functions it
names. Never `plans/archive/`.

**Do not change in any slice here.** `scripts/ui.gd::with_info()` (dozens of
callers; changing its size flags reflows every settings row), the `TOP_BAR_*`
constants in `scripts/hud.gd`, `scripts/settings_catalogue.gd`, and Challenge
stage data in `scripts/challenge_stages.gd`.

**UI-X-1** -- delivered; see `plans/archive/UI-X-1_2026-09-18.md`.

**UI-X-2** -- delivered; see `plans/archive/UI-X-2_2026-09-18.md`.

**UI-X-3** -- delivered; see `plans/archive/UI-X-3_2026-09-18.md`.

## UI-X-4 — Dr Gallerin's bubble grows to a third of the window's height

**Purpose.** Dave, 12 Sep 2026: "Dr Gallerin's bubble should be able to take
up [more] vertical space. make it so it can take up to a third of the height of
the window." His screenshot shows about four lines and a scrollbar.

**Root cause.**
- *Confirmed:* the ceiling is not what caps it. `UiLayout.gallerin_rect()`
  already allows `command_tray_max_height()`, nearly the full window.
- *Probable:* `_show_bubble()` sets `visible_characters = 0` and then calls
  `_apply_layout()`. `UiPanelLayout.apply()` sizes the scroll from the label's
  combined minimum height. `_bubble_label` leaves `visible_characters_behavior`
  at Godot's default, `VC_CHARS_BEFORE_SHAPING`, which shapes only the visible
  characters. So the height is measured for an empty line, and it is not
  measured again as the line types out, since layout runs only on show and on
  resize, by design. The comment in `_show_bubble` assumes the opposite.

**Files.** `scripts/gallerin_panel.gd`, `scripts/ui_layout.gd`, and a new
test_scenarios/uiw4_gallerin_bubble_height_test.json.

**Requirements.**
1. Confirm the cause first: `show_gallerin_prompt` with a line of about 400
   characters, then `panel_rect gallerin`. Record the height.
2. Set `gallerin_rect` height to
   `minf(command_tray_max_height(h), h * GALLERIN_MAX_HEIGHT_FRACTION)`, with
   the constant equal to `1.0 / 3.0`.
3. Set `_bubble_label.visible_characters_behavior = TextServer.VC_CHARS_AFTER_SHAPING`.
   Typing still reveals one character at a time, but layout uses the whole
   line. Correct the `_show_bubble` comment.
4. A line taller than the ceiling scrolls, using the existing scroll.
5. Make way for the settings window (Dave, 17 Sep 2026: "unless the settings
   window is in the way, in which case shorten and use the scroll bar"). The
   settings panel sits top-right and the bubble bottom-right, so they share a
   column. Give `UiLayout.gallerin_rect()` an optional `avoid: Rect2`
   (default empty). When it is non-empty and overlaps the bubble's horizontal
   span, the height ceiling becomes
   `minf(ceiling, bubble_bottom - (avoid.end.y + PANEL_GAP))`, floored at one
   line's height. `gallerin_panel.gd` passes the settings panel's global rect
   while it is visible (reach it through the `"debug_panel"` group, as
   `main.gd` documents), and re-applies layout from that panel's
   `visibility_changed` and `resized` signals -- not from `_process`.

**Constraints.** `_process` gains no layout work. Bubble width, bottom edge,
pointer position, typing speed and paging (C-38, C-39) are unchanged.

**Acceptance.** At 1920x1080:
- a 400-character prompt gives a bubble taller than three lines and at most
  360px;
- a 2,000-character prompt gives 360±1px, with the scroll active;
- a short prompt hugs its content.

At 800x600 the bubble is at most 200px, and at every size it stays inside the
viewport. With the settings window open (`open_window` `settings`, which
already exists), a 2,000-character prompt's bubble top is at least 16px below
the settings panel's bottom and its scroll is active; closing settings
returns it to 360±1px.

**Edge cases.** Text scale 1.5. Paging back to a shorter or longer line
re-applies layout; check `_apply_layout`'s callers. A window resize mid-line.

**Regression.** `tools/verify.ps1` and the gallerin LAY fixtures.
**Completion.** File a check: "Dr Gallerin's long lines show in full, up to a
third of the screen". Archive this section. **Level:** medium.

**Escalate if** a third of the height overlaps the summary panel or the command
tray at 800x600, or if `VC_CHARS_AFTER_SHAPING` visibly changes wrapping while
the line types out.
