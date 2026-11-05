# Play notes, HUD side -- follow-ups from Dave's 30 Oct 2026 hands-on pass

<!-- CONTEXT: plan | LAYER: immediate-task -->
Status: active | Owner: Dave / Claude Code | Next: PN-7 -- the cell popup and selection text batch, once the unmerged Jules E-14 branch is merged or closed (SG-3 landed 1 Nov 2026) | Dependency: the slices here wait for the unmerged Jules E-14 branch (`scripts/hud.gd`, `scripts/colony_milestones.gd`) and S-3 marker-reparent branch to be merged or closed; PN-17 needs only PN-16; PN-16 also waits for PN-6 in `plans/now/play-notes.md` | Verified: 2026-10-31

## Objective

The part of Dave's 30 and 31 Oct 2026 hands-on findings that edits
`scripts/hud.gd`, `scripts/colony_milestones.gd` or the selection input that
the HUD summarises. They are split from `plans/now/play-notes.md` by file
ownership: SG-3 owns `hud.gd`, `main.gd` and `colony_milestones.gd`.

## Current state

Verified 2026-10-31 by `tools/slice.ps1 owner` (SG-3 owns `hud.gd`, `main.gd`
and `colony_milestones.gd`) and grep on this branch.

- Clear to edit: `colony_panel.gd`, `session.gd`, `input_selection.gd`,
  `camera_view.gd`, `hud_command_rows.gd` (check with `owner` before starting).

## Open slices

| Id | Outcome | Files | Startable | Level / model |
| --- | --- | --- | --- | --- |
| PN-7 | cell popup wording, Empty controls, a warning box that stays | `hud.gd` | after the Jules E-14 branch (SG-3 landed 1 Nov 2026) | medium / sonnet |
| PN-8 | Warning history in the Colony window | `hud.gd`, `colony_panel.gd`, `session.gd` | after PN-7 | medium / sonnet |
| PN-10 | opening goal text a new player can act on | `colony_milestones.gd` | after the Jules E-14 branch (SG-3 landed 1 Nov 2026) | low / haiku |
| PN-14 | text no longer shrinks when unpausing | `hud.gd`, `camera_view.gd` | after PN-8 | high / sonnet |
| PN-15 | a day dial beside "Day N" | new `hud_day_dial.gd`, `hud.gd` | after PN-14 | medium / sonnet |
| PN-16 | double-click a cell selects all of its type | `input_selection.gd`, `hud.gd` | after PN-15 and PN-6 | medium / sonnet |
| PN-17 | Shift queues build and dig orders | `input_selection.gd` | after PN-16 | medium / sonnet |

## Dependencies

- SG-3 landed 1 Nov 2026; all seven now wait for the unmerged Jules E-14 and S-3 marker-reparent branches to be merged or closed. Same-file slices run in turn (the chain below):
  PN-7, PN-8, PN-10, PN-14 and PN-15 touch `hud.gd` or its neighbours;
  PN-16 and PN-17 touch `input_selection.gd`.
- PN-16 needs PN-6 (`plans/now/play-notes.md`), which also edits
  `input_selection.gd`.
- PN-17 edits only `input_selection.gd` (corrected 5 Nov 2026: it never needed
  `main.gd`), so it waits for PN-16 alone, not for the S-3 branch.
- CQ-R15 and CQ-R8 (`plans/now/code-health.md`) also edit `hud.gd` after SG-3;
  re-run `owner` before each slice. Do not touch `availability.gd` (jules J-13).

## PN-7 -- cell popup and selection text batch

**True now.** `hud.gd::_selection_identity_text` appends "(does not die of old
age)" to a bee's Age line. `_build_empty_controls` offers "To another cell"
and "Discard outside"; `clear_fermented_btn` ("Discard all sour nectar") shows
whenever `active_cell.is_fermented()` (set in `_refresh_cell_popup`). The
Reserve for row (`_build_cell_group`) lacks Keep empty, which is a separate
"Leave empty" checkbox. `show_warning` uses `WARNING_SECONDS = 18.0`,
decremented by scaled `_delta` in `_process`, so it lasts about 4.5 s at 4x
speed (C-140: "it disappears quickly (particularly at high speed) and there's no
way to bring it back").

**Change.**
- Remove "   (does not die of old age)".
- Rename "To another cell" to "Empty to other cells" and "Discard outside" to
  "Empty to outside".
- Show "Discard all sour nectar" only when the run owns both
  `skill.hive_mind.cleaning` and `Skills.FERMENTATION_SENSE`.
- "Keep empty" joins the Reserve for row, emitting
  `cell_keep_empty_requested(cell, true)`; fold the "Leave empty" checkbox into
  it. Do not add an `Availability.UI_GATES` key.
- The warning box dwells 18 real seconds: divide by `Engine.time_scale` or use a
  real-time clock.

**Invariants.** `tests/display_text_golden_test.gd` and its fixture may change;
update them in the slice. Simulation is untouched.

**Acceptance (player seat, and the hands-on check).** Select a bee: the Age line
has no old-age remark. Open an empty cell's popup: the buttons read "Empty to
other cells" and "Empty to outside", and Keep empty sits in the Reserve row.
Without Cleaning, no sour-nectar button. At 4x speed a warning stays about 18
real seconds.

**Open decisions:** none.

```queue-gated
**[Claude] PN-7 -- cell popup and selection text batch**
- Plan: `plans/now/play-notes-hud.md` -- "PN-7 -- cell popup and selection text batch"
- Files: `scripts/hud.gd`, `tests/display_text_golden_test.gd`, `tests/test_pn7_cell_popup.py`
- Check: `python -m unittest tests.test_pn7_cell_popup` passes (labels, the sour-nectar gate, Keep empty in the Reserve row, warning dwell at 4x); the display-text golden test is regenerated; `.\tools\verify.ps1` is green. Hands-on: the cell popup reads as above and a warning at 4x lasts about 18 seconds
- Proof: `present: scripts/hud.gd :: does not die of old age`
- Next after: PN-8 -- Warning history in the Colony window
```

## PN-8 -- Warning history in the Colony window

**True now.** `hud.gd::_show_warning_now` shows a warning and keeps nothing.
`colony_panel.gd::_rebuild_needing_attention` renders the Needing attention
section.

**Change.** Session keeps the last 10 warnings (text, severity, game day and
time) as run state that is **not saved**: a loaded run starts with an empty
history. `_show_warning_now` records each; `_rebuild_needing_attention` renders
them under a "Warning history" heading, newest first.

**Invariants.** No save field or version change. Recording is on an event, not
per frame; the list is capped at 10.

**Acceptance (player seat, and the hands-on check).** After a few warnings, open
the Colony window: Warning history lists them with day and time. After loading
a save it is empty.

**Open decisions:** none.

```queue-gated
**[Claude] PN-8 -- Warning history in the Colony window**
- Plan: `plans/now/play-notes-hud.md` -- "PN-8 -- Warning history in the Colony window"
- Files: `scripts/hud.gd`, `scripts/colony_panel.gd`, `scripts/session.gd`, `tests/test_pn8_warning_history.py`
- Check: `python -m unittest tests.test_pn8_warning_history` passes (10 kept, newest first, empty after load); `.\tools\verify.ps1` is green. Hands-on: Warning history shows recent warnings in the Colony window
- Proof: `absent: scripts/colony_panel.gd :: Warning history`
- Next after: PN-10 -- opening goal text a new player can act on
```

## PN-10 -- opening goal text a new player can act on

**True now.** `colony_milestones.gd` `first_stores` reads "Bring in nectar and
pollen". C-139: a new player would not know that means making the queen a
Forager.

**Change.** Reword it to "Make the queen a Forager to bring in nectar and
pollen" (confirm the label in `roles.gd`: it is "Forager"), and review the
other three milestones for the same gap. `tests/gp1_goals_dropdown_test.gd`
asserts the strings and changes with them.

**Invariants.** Milestone ids and their completion checks do not change.

**Acceptance (player seat, and the hands-on check).** Start a Colony Run: the
first goal tells you what to do, not only what to achieve.

**Open decisions:** none.

```queue-gated
**[Claude] PN-10 -- opening goal text a new player can act on**
- Plan: `plans/now/play-notes-hud.md` -- "PN-10 -- opening goal text a new player can act on"
- Files: `scripts/colony_milestones.gd`, `tests/gp1_goals_dropdown_test.gd`
- Check: `python -m unittest tests.test_gp1_goals_dropdown` passes with the new strings; `.\tools\verify.ps1` is green. Hands-on: the first goal names the Forager role
- Proof: `present: scripts/colony_milestones.gd :: Bring in nectar and pollen`
- Next after: PN-14 -- text no longer shrinks when unpausing
```

## PN-14 -- text no longer shrinks when unpausing

**True now (cause unknown).** Dave: "when pressing space to pause, the text
shrinks when unpausing". Space goes `input_selection.gd` to
`camera_view.gd::_toggle_pause`, then `_refresh_speed_display` (shows
`hud.pause_label`, theme variation "Heading", calls `hud.set_speed_display`).
Suspects: `hud.gd::_corner_signature` / `_rebuild_corner_labels` rebuilding
corner labels with `UiTheme.font_px(CORNER_SIZES)`; the fps and speed text; the
speed buttons' pressed state.

**Change.** Reproduce first: a headless test records the font sizes of the HUD
labels before pausing and after unpausing, and fails. Then fix the cause, and
leave a `PN-14` comment at the fix.

**Invariants.** Pause and unpause behaviour is unchanged; no per-frame rebuild
is added (`.claude/rules/performance.md`). If the cause is outside these files,
stop and say so.

**Acceptance (player seat, and the hands-on check).** Press Space to pause and
again to resume: no text changes size.

**Open decisions:** none.

```queue-gated
**[Claude] PN-14 -- text no longer shrinks when unpausing**
- Plan: `plans/now/play-notes-hud.md` -- "PN-14 -- text no longer shrinks when unpausing"
- Files: `scripts/hud.gd`, `scripts/camera_view.gd`, `tests/pn14_pause_font_test.gd`, `tests/test_pn14_pause_font.py`
- Check: `python -m unittest tests.test_pn14_pause_font` passes (HUD label font sizes equal before pause and after unpause; failing before the fix); `.\tools\verify.ps1` is green. Hands-on: Space to pause and resume leaves text size alone
- Proof: `absent: scripts/hud.gd :: PN-14`
- Next after: PN-15 -- a day dial beside "Day N"
```

## PN-15 -- a day dial beside "Day N"

**True now.** `hud.gd::update_day` builds the day text. Nothing shows the time
through the day.

**Change.** A new `scripts/hud_day_dial.gd`, a small Control drawing the upper
half of a semicircle with `draw_arc` and a hand at
`fposmod(Session.sim_time, GameConfig.seconds_per_day) / seconds_per_day`.
Redraw each tick with `queue_redraw` only while visible, without changing
`hud.gd::_corner_signature`, so no corner rebuild per frame
(`.claude/rules/performance.md`). Hud places it beside the day text.

**Invariants.** Presentation only; nothing in the simulation reads it.

**Acceptance (player seat, and the hands-on check).** Beside "Day N" a
half-dial hand sweeps once a day, left at dawn to right at dusk, and stops
when paused.

**Open decisions:** none.

```queue-gated
**[Claude] PN-15 -- a day dial beside "Day N"**
- Plan: `plans/now/play-notes-hud.md` -- "PN-15 -- a day dial beside "Day N""
- Files: `scripts/hud_day_dial.gd`, `scripts/hud.gd`, `tests/test_pn15_day_dial.py`
- Check: `python -m unittest tests.test_pn15_day_dial` passes (hand fraction matches the time of day; corner signature unchanged); `.\tools\verify.ps1` is green. Hands-on: the dial hand sweeps through the day
- Proof: `absent: scripts/hud.gd :: HudDayDial`
- Next after: PN-16 -- double-click a cell selects all of its type
```

## PN-16 -- double-click a cell selects all of its type

**True now.** Cells select singly. `input_selection.gd` detects `double_click`;
PN-6 adds the bee version.

**Change.** Double-click a cell to select every cell of that type (contents:
honey, nectar, pollen, bee bread, brood, empty), across the whole comb, and show
their total contents in the HUD summary. Existing single-cell actions stay
single-cell.

**Invariants.** One selected cell behaves as now; the summary is rebuilt on
selection change, not per frame.

**Acceptance (player seat, and the hands-on check).** Double-click a honey cell:
all honey cells are selected and the summary shows the total honey.

**Open decisions:** none.

```queue-gated
**[Claude] PN-16 -- double-click a cell selects all of its type**
- Plan: `plans/now/play-notes-hud.md` -- "PN-16 -- double-click a cell selects all of its type"
- Files: `scripts/input_selection.gd`, `scripts/hud.gd`, `tests/test_pn16_select_cell_type.py`
- Check: `python -m unittest tests.test_pn16_select_cell_type` passes (all cells of the type selected, totals right, single-cell actions unchanged); `.\tools\verify.ps1` is green. Hands-on: double-clicking a honey cell selects all honey cells and totals them
- Proof: `absent: scripts/input_selection.gd :: _select_cells_of_type`
- Next after: PN-17 -- Shift queues build and dig orders
```

## PN-17 -- Shift queues build and dig orders

**True now** (re-verified 5 Nov 2026, `docs/architecture-review-2026-11-04.md` F4). Queues live in
`bee.gd` (`queue_build_target`, `queue_mine_target`, `_next_queued_block`).
Ctrl already queues: `input_selection.gd::_finish_drag` passes only
`event.ctrl_pressed` to `_place_with_active_tool(ctrl_held)`, whose
`keep_adding` (a tool with `"queues": true` and Ctrl held) makes
`_place_build_cell`/`_place_mine_target` append and leaves the tool armed; a
click without Ctrl places once and disarms. Shift (`additive`) is ignored while
a placement tool is armed. Dave: "Pressing shift while doing certain tasks,
like Build cell, mine soil block, should make it so you can queue tasks that
the bee will do in sequence".

**Change.** In `_finish_drag`, pass `additive or add_to_group_selection` to
`_place_with_active_tool`, and rename its parameter `ctrl_held` to
`queue_held`. Shift then does exactly what Ctrl does today, for every tool
whose catalogue row has `"queues": true` (build cell, mine target, keep
clear). No `main.gd` or `hud_command_rows.gd` change.

**Invariants.** Ctrl-click queueing and a plain click are unchanged; Shift
outside placement (additive selection) is unchanged; queue limits are
unchanged.

**Acceptance (player seat, and the hands-on check).** Hold Shift, Build cell and
click three places: the bee builds them in order. The same for marking soil to
dig.

**Open decisions:** none.

```queue-gated
**[Claude] PN-17 -- Shift queues build and dig orders**
- Plan: `plans/now/play-notes-hud.md` -- "PN-17 -- Shift queues build and dig orders"
- Files: `scripts/input_selection.gd`, `tests/test_pn17_shift_queue.py`
- Check: `python -m unittest tests.test_pn17_shift_queue` passes (Shift keeps the mode armed and appends); `.\tools\verify.ps1` is green. Hands-on: Shift-clicking three build sites queues all three
- Proof: `absent: scripts/input_selection.gd :: queue_held`
- Next after: none -- `plans/now/play-notes-hud.md` is complete
```
