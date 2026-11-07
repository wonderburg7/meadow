# Play notes, HUD side -- follow-ups from Dave's 30 Oct 2026 hands-on pass

<!-- CONTEXT: plan | LAYER: immediate-task -->
Status: active | Owner: Dave / Codex | Next: PN-14 -- text no longer shrinks when unpausing, then PN-15 | Dependency: all seven share `hud.gd` or `input_selection.gd` and run in turn; PN-8 and PN-10 wait for the Claude lane's PN-3 and ED-2 to release `session.gd` and the Goals test; PN-16 waits for PN-6 (`plans/now/play-notes.md`) | Verified: 2026-11-05

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

| Id | Outcome | Files | Startable | Level |
| --- | --- | --- | --- | --- |
| PN-14 | text no longer shrinks when unpausing | `hud.gd`, `camera_view.gd` | yes | high |
| PN-15 | a day dial beside "Day N" | new `hud_day_dial.gd`, `hud.gd` | yes | medium |
| PN-8 | Warning history in the Colony window | `hud.gd`, `colony_panel.gd`, `session.gd` | after PN-3 and ED-2 (Claude lane) release `session.gd` | medium |
| PN-10 | opening goal text a new player can act on | `colony_milestones.gd` | after PN-3 (Claude lane) releases `tests/gp1_goals_dropdown_test.gd` | low |
| PN-16 | double-click a cell selects all of its type | `input_selection.gd`, `hud.gd` | after PN-6 (Claude lane) | medium |
| PN-17 | Shift queues build and dig orders | `input_selection.gd` | after PN-16 | medium |

## Dependencies

- **Lane (Dave, 5 Nov 2026, plan review).** These slices run in the Codex
  lane, so `hud.gd` is that lane's while they are queued. HM-2
  (`plans/now/hive-and-menu-art.md`) and CQ-R2 (`plans/now/code-health.md`),
  Claude slices that also edit it, follow them.
- Same-file slices run in turn: PN-7, PN-14, PN-15, PN-8 and PN-10 touch
  `hud.gd` or its neighbours; PN-16 and PN-17 touch `input_selection.gd`.
- PN-8 waits for PN-3 and ED-2 (Claude lane), which edit `session.gd`; PN-10
  waits for PN-3, which edits `tests/gp1_goals_dropdown_test.gd`.
- PN-16 needs PN-6 (`plans/now/play-notes.md`), which also edits
  `input_selection.gd`; PN-17 edits only `input_selection.gd` and waits for
  PN-16 alone.
- CQ-T4 (`plans/now/code-health.md`) types `colony_panel.gd` and
  `camera_view.gd` after PN-8 and PN-14 have landed.

PN-7 shipped 2026-11-07; its specification is `plans/archive/PN-7_2026-11-07.md`.

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
**[Codex] PN-8 -- Warning history in the Colony window**
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
**[Codex] PN-10 -- opening goal text a new player can act on**
- Plan: `plans/now/play-notes-hud.md` -- "PN-10 -- opening goal text a new player can act on"
- Files: `scripts/colony_milestones.gd`, `tests/gp1_goals_dropdown_test.gd`
- Check: `python -m unittest tests.test_gp1_goals_dropdown` passes with the new strings; `.\tools\verify.ps1` is green. Hands-on: the first goal names the Forager role
- Proof: `present: scripts/colony_milestones.gd :: Bring in nectar and pollen`
- Next after: PN-16 -- double-click a cell selects all of its type
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

```queue
**[Codex] PN-14 -- text no longer shrinks when unpausing**
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

```queue
**[Codex] PN-15 -- a day dial beside "Day N"**
- Plan: `plans/now/play-notes-hud.md` -- "PN-15 -- a day dial beside "Day N""
- Files: `scripts/hud_day_dial.gd`, `scripts/hud.gd`, `tests/test_pn15_day_dial.py`
- Check: `python -m unittest tests.test_pn15_day_dial` passes (hand fraction matches the time of day; corner signature unchanged); `.\tools\verify.ps1` is green. Hands-on: the dial hand sweeps through the day
- Proof: `absent: scripts/hud.gd :: HudDayDial`
- Next after: PN-8 -- Warning history in the Colony window
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
**[Codex] PN-16 -- double-click a cell selects all of its type**
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
**[Codex] PN-17 -- Shift queues build and dig orders**
- Plan: `plans/now/play-notes-hud.md` -- "PN-17 -- Shift queues build and dig orders"
- Files: `scripts/input_selection.gd`, `tests/test_pn17_shift_queue.py`
- Check: `python -m unittest tests.test_pn17_shift_queue` passes (Shift keeps the mode armed and appends); `.\tools\verify.ps1` is green. Hands-on: Shift-clicking three build sites queues all three
- Proof: `absent: scripts/input_selection.gd :: queue_held`
- Next after: none -- `plans/now/play-notes-hud.md` is complete
```
