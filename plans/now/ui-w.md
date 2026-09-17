# UI-W — Dave's 12 Sep 2026 pass: settings window, cell tray, Dr Gallerin

<!-- CONTEXT: plan | LAYER: immediate-task -->
Status: active | Owner: Dave / Claude Code | Next: UI-W-2 -- Challenge 2's cell tray offers a Forager to raise | Dependency: none | Verified: 2026-09-17

**Objective.** The findings from Dave's 12 Sep 2026 hands-on pass that belong
to the HUD and the settings window, each fixed at its owner and each with a
headless assertion so the same class of fault fails verification next time.

**State.** Nothing here has shipped. `plans/now/ui.md` keeps the durable UI
rules and points here. The checks these slices re-open wait in
`checks/blocked.md` (C-18, C-34, C-52, C-53); C-49's own PASS is about what the
stage arrows do and stays ready.

## Open slices at a glance

| Slice | Outcome from the player's seat | Files owned | Startable | Level |
| --- | --- | --- | --- | --- |
| UI-W-1 | The settings window is a quarter of the screen and its Controls list has no gaps | `scripts/debug_panel.gd`, `scripts/ui_layout.gd`, `tests/fixtures/settings_stage_row.json` | yes | medium |
| UI-W-2 | At Challenge 2's 2.2 a cell's tray offers Forager — Pollen to raise | `scripts/hud.gd`, `scripts/scenario_actions.gd`, `scripts/challenge_runner.gd` | yes | medium |
| UI-W-3 | A comb cell's tray has three columns and is shorter | `scripts/hud.gd` | after UI-W-2 | medium |
| UI-W-4 | Dr Gallerin's bubble shows a long line in full, up to a third of the window's height, and makes way for an open settings window | `scripts/gallerin_panel.gd`, `scripts/ui_layout.gd` | after UI-W-1 | medium |

**Dependencies.** UI-W-1 no longer touches `scripts/scenario_actions.gd`, so
it shares no file with UI-W-2 and can follow it straight away in the Claude
lane. UI-W-3 follows UI-W-2 (`scripts/hud.gd`, and it uses UI-W-2's
`select_cell` action). UI-W-4 follows UI-W-1 (`scripts/ui_layout.gd`).
UI-W-2 leads because it is the only one that stops a Challenge being
finished; UI-W-1 comes next because it shares no file with anything and
returns two blocked checks to Dave (17 Sep 2026 plan review).

**Required reading for any slice.** Its own section below, and the functions it
names. Never `plans/archive/`.

**Do not change in any slice here.** `scripts/ui.gd::with_info()` (dozens of
callers; changing its size flags reflows every settings row), the `TOP_BAR_*`
constants in `scripts/hud.gd`, `scripts/settings_catalogue.gd`, and Challenge
stage data in `scripts/challenge_stages.gd`.

## UI-W-1 — the settings window: a quarter of the screen, a readable stage row, a tight Controls list

**Purpose.** C-52 partly passed ("about a fifth ... could be bigger, up to 25%
of the screen's width") and C-53 failed ("still too big a gap between each
item"). Both are one window's layout.

**Scope.** The stage row and the wrapping-label instrument are done, so
this slice is the window's width and the Controls list only. The instrument
they left is `tests/fixtures/settings_stage_row.json`, driven by
`tests/test_layout_regression.py`, which runs `no_collapsed_controls` on the
settings window during Challenge 1; `open_window` already accepts
`"settings"`. Extend that fixture rather than writing a new one.

**Root causes.**
- *Width, confirmed.* `debug_panel.gd` sets `PANEL_WIDTH := 320.0` on the panel
  and its scroll. 320px is a sixth of 1920. No function in `ui_layout.gd` owns
  this rectangle, against `plans/now/ui.md`'s one-owner rule.
- *Controls gap, hypothesis.* UI-B-1 removed the blank lines. What remains is
  line pitch: the `Small` (13px) type with the active pixel font, plus Label's
  default `line_spacing`. It has not been measured. Also,
  `custom_minimum_size.x = 270` stops the list reflowing at a wider window.

**Owner.** `scripts/debug_panel.gd` builds the window. `scripts/ui_layout.gd`
owns persistent rectangles.

**Required reading.** In `debug_panel.gd`: the panel/scroll build (every
`PANEL_WIDTH` use), `_make_controls_help`, `_add_action_row`. In
`ui_layout.gd`: its constants and `left_window_rect`. Nothing in
`scenario_actions.gd` needs reading: the fixture's actions and conditions all
exist. Find how `main` reaches the settings window with
`grep -n debug_panel scripts/main.gd`.

**Files likely to change.** `scripts/debug_panel.gd`, `scripts/ui_layout.gd`,
`tests/fixtures/settings_stage_row.json` (add the width and Controls
assertions there).

**Requirements.**
1. Add `UiLayout.settings_window_width(viewport_width)`:
   `maxf(SETTINGS_WINDOW_MIN_WIDTH, viewport_width * SETTINGS_WINDOW_WIDTH_FRACTION)`,
   with the minimum at 320.0 and the fraction at 0.25 (Dave: "up to 25%"), so
   1920 gives 480. `debug_panel.gd` uses it for the panel and the scroll, and
   re-applies it from `get_viewport().size_changed`, as `gallerin_panel.gd`
   does. Remove `PANEL_WIDTH`.
2. Controls list: first log the label's `get_line_height()` and font size from
   the fixture, and record both numbers in the delivery note. Replace the fixed
   270 with `SIZE_EXPAND_FILL`, and set a `line_spacing` theme override on this
   label only, so the line pitch is at most the font size plus 2px. Do not
   change the theme-wide `Small` variation.

**Constraints and invariants.** Horizontal scrolling stays disabled. The
`ROW_LABEL_WIDTH` row layout is unchanged. The panel's top offset is unchanged.
`_process` gains no layout work. C-22 (sections reset closed) still holds.

**State and cleanup.** `_refresh_challenge_stage_navigation` still owns the
row's visibility. A hidden row is not collapsed, because the collector already
skips invisible controls.

**Edge cases.** At 800x600 the 320 floor is 40% of the width, which is
accepted. At text scale 1.5 the stage label wraps to two or three lines and
the arrows stay 24px. With no Challenge running the row is hidden. With info
badges on, no row overflows.

**Automated acceptance.** Extend `tests/fixtures/settings_stage_row.json`
(1920x1080, `"challenge": 1`, World & start and Controls expanded) so that it
asserts:
- `panel_rect settings` is inside the viewport, with width 480±1. **This is
  the assertion that fails on master**, where `PANEL_WIDTH` is 320: record
  that failure message before the fix.
- `no_collapsed_controls` still passes on `settings`. It passes on master
  too, since the stage-row fix landed; it is a regression guard here, not the
  failing assertion.
- the same fixture passes at 800x600.

**Regression checks.** `tools/verify.ps1`, the existing LAY fixtures in
`test_scenarios/` and `h4_challenge1_stage_advance_test.json`. No save/load or
hot-path impact.

**Completion.** Move C-52 and C-53 from `checks/blocked.md` back to ready, with
PASS lines as written there. Archive this section and update the index above.
(The autowrap pitfall is already in `docs/known-pitfalls.md`, and C-49's
stage-row re-run note is already filed.)

**Escalate if** any row at 800x600 overflows at the new width, if the row can
only be fixed by changing `UI.with_info()` for every caller, or if the line
pitch can only be fixed theme-wide.

## UI-W-2 — Challenge 2's cell tray offers a Forager to raise

**Purpose.** Stage 2.2 asks the player to raise a pollen Forager. In Dave's
12 Sep 2026 run a selected cell's tray had no Forager control beside
"Raises:" at all. He confirmed in session on 13 Sep 2026 that the button was
missing, not overlooked. Stage 2.2 cannot be finished the way it is taught.

**Confirmed.** The Raises controls are built once, in
`hud.gd::_build_nursery_controls`, while `allowed_role_keys` is empty, so a
"Forager…" menu (`_make_hatch_menu`) does get built. Its visibility is set by
`_apply_cell_popup_gating()`, which runs on every `_refresh_cell_popup()` and
from both `set_allowed_role_keys` and `set_allowed_designation_keys`, so
**stale gating is ruled out**. Stage 2.2's `unlocked_keys` include
`"forager"`.

**Hypotheses, to test in this order.**
- H1: `"forager"` is not unlocked when the cell is shown.
  `stage_gate._unlocked` lacks it, for example because
  `_apply_stage_gate_to_ui` runs before stage 2.2's unlocks are applied.
- H2: the menu is visible but has no usable rectangle. `hatch_row` is an
  HFlowContainer that "skips sorting while hidden", and the Nursery column's
  equal share may push the menu out of the tray's clipped scroll area.
- H3: another path hides the Nursery column or `hatch_row` in Challenge 2.
  Search for `hatch_row.visible` and the column wrappers' `visible`.
- H4: the control was never built. `_build_nursery_controls` skips any
  `hatch_options()` entry whose role is not in `allowed_role_keys`
  (`continue`, just above `_make_hatch_menu`), and gating afterwards only
  shows or hides what that loop built. Today `_build_command_tray` runs from
  `hud.gd::_ready`, when the list is empty, so this only bites if some path
  rebuilds the tray after the gate is applied -- a Challenge restart or a
  resumed run. Check `_build_command_tray`'s callers before the others; it is
  the cheapest of the four to rule out.

**Also wrong: the check's wording.** C-34 asked for nectar Foragers during
2.1, but 2.1 does not unlock `"forager"`, and `_apply_cell_popup_gating` hides
the colony-default entry whenever keys are restricted. 2.1 therefore offers
nothing to raise by that route. Re-word C-34 before moving it back to ready.

**Owner.** `challenge_runner.gd::_apply_stage_gate_to_ui` decides what is
unlocked, and `hud.gd` only applies it. Keep it that way.

**Required reading.** In `hud.gd`: `_build_nursery_controls`,
`_make_hatch_menu`, `show_cell_popup`, `_refresh_cell_popup`,
`_apply_cell_popup_gating`, `set_allowed_role_keys`. In `challenge_runner.gd`:
`_stage_unlock_keys`, `_enter_stage`, `_apply_stage_gate_to_ui`. Stages
2.1-2.3 in `challenge_stages.gd`. The fixture
`test_scenarios/h4_challenge1_stage_advance_test.json`. In
`scenario_actions.gd`: `_execute`, `_do_select_soil`, the `control` condition.
Find what a left-click on a comb cell calls with
`grep -n show_cell_popup scripts/input_selection.gd`.

**Files likely to change.** `scripts/scenario_actions.gd`, `scripts/hud.gd`,
`scripts/challenge_runner.gd` (`_apply_stage_gate_to_ui` only, and only for
H1), new test_scenarios/uiw2_challenge2_raises_forager_test.json.

**Must not change.** `scripts/challenge_stages.gd`, `Roles.ROLES`, the shape
of `hatch_options()`. `scripts/challenge_runner.gd` **is** available now -- C2
shipped, and no open Codex-lane slice names it -- but only
`_apply_stage_gate_to_ui` may change, and only if H1 is what the fixture's
failure message confirms. Nothing else in that file, and no stage record.

**Requirements.**
1. *Instrument first.* Add a `select_cell` action,
   `{"do": "select_cell", "built_index": 0}`, that calls the same function a
   left-click on a comb cell calls. Do not copy its logic. Give the `control`
   condition an optional `"visible": true`, so a hidden control fails instead
   of passing silently. Name the menu `hatch_<role key>_menu`, for example
   `hatch_forager_menu`, in `_make_hatch_menu`.
2. The fixture uses `"challenge": 2`, advances to `2.2`, runs `select_cell`,
   then asserts: `control` on
   `command_tray/.../hatch_forager_menu` is visible, has `min_size [40, 16]`,
   and is `inside command_tray`; `no_collapsed_controls` passes on
   `command_tray`. Run it on master, where it must fail, and record the failure
   message.
3. Fix whichever hypothesis the message confirms, at its owner. The fixture
   must pass afterwards.

**Constraints.** Outside a Challenge every Raises option stays visible. At 2.1
Forager stays hidden, which is the design. The gyne row stays hidden while
roles are restricted.

**State transitions.** A stage change while the tray is open re-gates through
the setters. A stage change while it is closed gates on the next show. Both
paths must keep working. No per-frame work is added.

**Edge cases.** A debug step back from 2.2 to 2.1 hides Forager again. The menu
lists both Nectar and Pollen. Text scale 1.5.

**Regression checks.** `tools/verify.ps1`, the H4 fixture,
`c2_no_jelly_cell_test.json` and the LAY fixtures. No save/load impact:
Challenge runs are not saved.

**Completion.** Re-word C-34 so its 2.1 half is achievable, and move it back to
ready. Archive this section, and name UI-W-3 next.

**Level:** medium. The four hypotheses below are enumerated and the fixture's
failure message picks between them, which is bounded work. **Hand the slice to
a high-reasoning model** if that message matches none of H1-H4, or if the fix
needs more of `challenge_runner.gd` than `_apply_stage_gate_to_ui`.

**Escalate if** `select_cell` cannot reuse the click path without copying
selection logic, or if the fix would change a stage record.

## UI-W-3 — a comb cell's tray uses three columns

**Purpose.** The bee half of C-18 passed. For a comb cell the tray shows two
columns, and Dave wants three so it uses less height. **Decision (Dave, 13 Sep
2026, in session):** split Nursery into two columns, giving *Reserve for |
Priority | Raises*. More… (Emptying, Sealing) is unchanged.

**Root cause, confirmed.** `_build_cell_group` makes two
`_build_cell_action_column` calls into `cell_primary_columns`: "Reserve for"
and "Nursery". `_build_nursery_controls` stacks Priority, Open nursery window,
Raises, Keep for every bee and the gyne row in one column, and that stack is
the tray's height. `_update_command_tray_width` already runs
`_apply_even_column_widths(cell_primary_columns.get_children())`, so a third
column gets an equal share with no further change.

**Files.** `scripts/hud.gd` and a new test_scenarios/uiw3_cell_tray_columns_test.json.

**Requirements.**
- Split `_build_nursery_controls` in two:
  - `_build_priority_controls(column)`: the Priority row and Open nursery window;
  - `_build_raises_controls(column)`: the Raises row, Keep for every bee, and gyne.
- Build three columns titled "Reserve for", "Priority" and "Raises".
- Keep the field names `hatch_row`, `lock_row` and `gyne_row` (gating reads
  them), the `live_buttons` keys, and `show_cell_popup`'s
  `hatch_row.queue_sort()`.
- Name `cell_primary_columns` so the fixture can address it.

**Constraints.** A column whose controls are all gated off keeps its slot, the
same rule the bee tray follows (Dave, 10 Sep 2026). `_apply_cell_popup_gating`
is unchanged.

**Acceptance.** The fixture runs at 1920x1080, then `select_cell`, then:
- `even_columns` on `command_tray/.../cell_primary_columns` finds three columns;
- `panel_rect command_tray` passes with `matches_content`;
- `no_collapsed_controls` passes;
- the tray's height for the same cell is lower than before the change, with
  both numbers recorded.

The fixture also passes at 800x600, where the columns may wrap.

**Regression.** `tools/verify.ps1`, the UI-W-2 fixture and the LAY fixtures.
C-41 and C-43 (the tray fits its content) must still hold.

**Completion.** Move C-18 from blocked back to ready (the cell half only), and
archive this section.

**Level:** medium. **Escalate if** three columns do not fit at 1920x1080
without wrapping.

## UI-W-4 — Dr Gallerin's bubble grows to a third of the window's height

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
