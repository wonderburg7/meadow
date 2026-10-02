# Settings window and corner HUD -- findings from the 1 Oct 2026 hands-on pass

<!-- CONTEXT: plan | LAYER: immediate-task -->
Status: active | Owner: Dave / Claude Code | Next: SC-1 -- the settings window does not move under a Text scale click (startable; waits for room in the Claude lane) | Dependency: SC-2 follows UT-1 and UT-3 (`plans/now/ui-texture-polish.md`, `scripts/ui_theme.gd`); SC-4 waits for SR-4 (Codex lane, `scripts/hud.gd`) and runs one after the other with UT-4 | Verified: 2026-10-01

**Objective.** Four defects seen while running C-69 to C-73 by computer use on
1 Oct 2026 are fixed: C-72 failed once in three runs, cycling the typeface
logs an engine error, the project boots with GDScript warnings, and the
top-left corner overlaps itself and the left windows. Presentation only --
nothing here changes simulation (`plans/archive/ui_2026-09-20.md`, "Durable
rules"). The owning HUD plan, `plans/archive/hud-followups_2026-09-30.md`, is
archived, so these start a fresh plan (`plans/README.md`, "Plan schema").

| Slice | Files | Level | Lane | Startable | Depends on |
| --- | --- | --- | --- | --- | --- |
| SC-1 | `scripts/debug_panel.gd`, `checks/ready/C-72.md` | high | Claude | yes | none |
| SC-2 | `scripts/ui_theme.gd`, `test_scenarios/sc2_typeface_cycle_test.json` | medium | Claude | yes, after UT-1 and UT-3 (share `ui_theme.gd`) | UT-1, UT-3 |
| SC-3 | `scripts/saves_panel.gd`, `scripts/debug_panel.gd`, `scripts/input_selection.gd` | low | Claude | yes, after SC-1 (shares `debug_panel.gd`) | SC-1 |
| SC-4 | `scripts/hud.gd`, `scripts/game_panel.gd` | medium | Claude | no | SR-4 landing; not alongside UT-4 (all edit `scripts/hud.gd`) |

**Neighbouring plan.** `plans/now/ui-texture-polish.md` (UT-1 to UT-5) came
from the same day's pass over C-57 to C-68 and shares two files: UT-1 and
UT-3 edit `scripts/ui_theme.gd` (SC-2 goes after them) and UT-4 edits
`scripts/hud.gd` (SC-4 and UT-4 run one after the other, either order).

A slice reads its own section and nothing else. Not planned: the hive view
swapping the last top-bar icon (it shows the view the button switches to,
which reads as intended), and C-60/C-71, which UT-1 now owns (Dave, 2 Oct 2026).

## SC-1 -- the settings window does not move under a Text scale click

<!-- LAYER: immediate-task -->

Level: high (ambiguous bug: the cause below is an inference, not a repro).

**True now.** `debug_panel.gd::_adjust` debounces Text scale correctly: each
click restarts `_text_scale_timer` (`TEXT_SCALE_APPLY_DELAY` 0.8 s) and only
the timeout calls `UiTheme.refresh_for_setting("text_scale")`. Observed on
1 Oct 2026 (C-72, run 1): Text scale 2.0, one − click, then four quick −
clicks (1.90 to 1.50, applied once, fine). Seconds later, four quick + clicks
from 1.50: the first counted (1.60), then the rows inside `panel_scroll`
moved down by one row (~27 px) before the timer fired, so the next three
clicks hit Typeface ▸ and changed the typeface three times. Two later runs
from 1.60 passed. 2 Oct 2026: four uninterrupted + clicks from 1.60
reached 2.0 cleanly. A run with a capture of about 1 s after the second
click let the apply fire (1.80), and the re-laid window sent clicks three and
four to Typeface ▸. That is the debounce working, not run 1's early move, so
C-72 was left open for this slice rather than confirmed. Inference: after an apply shrinks the content,
`panel_scroll.scroll_vertical` is left past the new maximum until the next
re-sort; the value-label change on the next click triggers that sort and the
clamp moves every row.

**True afterwards.** After the debounced apply, the scroll position is
settled in the same pass (for example: wait one frame after
`refresh_for_setting`, then clamp `scroll_vertical` to the bar's maximum), so
a later click on any row moves nothing until its own apply. Reproduce run 1
before changing anything; if it does not reproduce, stop and report rather
than guess. `plans/now/ui-texture-polish.md` ("Source") puts a similar
"arrows stepped the other row" sighting down to the capture tool; this one
is different because the game's own state changed -- Typeface really did
become Open Sans, and the boot log carries SC-2's error from `_cycle_option`. Rewrite `checks/ready/C-72.md`'s "What this checks" to start from
Text scale 2.0, step it to 1.50 with five − clicks, wait two seconds, then
click + four times quickly -- 2.0 is the maximum, so the old wording could
not be run from the default -- and point its Owner line at this plan.

**Must not change.** `TEXT_SCALE_APPLY_DELAY`, the hold-to-repeat timer in
`_wire_repeat_button`, and every other setting's immediate apply.

```queue
**[Claude] SC-1 -- the settings window does not move under a Text scale click**
- Plan: `plans/now/settings-and-corner.md` -- "SC-1 -- the settings window does not move under a Text scale click"
- Files: `scripts/debug_panel.gd`, `checks/ready/C-72.md`
- Check: run 1's sequence in `checks/ready/C-72.md` reproduces before the change and not after it, and `tools/verify.ps1` is green
- Proof: `present: scripts/debug_panel.gd :: _text_scale_timer.timeout.connect(func() -> void: UiTheme.refresh_for_setting("text_scale"))`
- Next after: SC-2 -- cycling the typeface logs no engine error
```

## SC-2 -- cycling the typeface logs no engine error

<!-- LAYER: immediate-task -->

Level: medium (one function, with a backtrace; escalate if it will not
reproduce headlessly).

**True now.** Cycling Typeface (options `sans`, `atkinson`, `opensans`,
`opendyslexic`, `munro`, `silkscreen`) printed `ERROR: Parameter "fd" is
null` from `text_server_adv.cpp` `_shape_run`, backtrace
`ui_theme.gd::_refresh_button_stylebox` <- `refresh` <-
`refresh_for_setting` <- `debug_panel.gd::_cycle_option`. Inference:
`refresh()` mutates the shared Theme's font per variation and then each
button StyleBox; every mutation emits `changed`, so controls re-shape text
part-way through a font swap.

**True afterwards.** A new fixture `test_scenarios/sc2_typeface_cycle_test.json`
sets `ui_typeface` to each option in turn with `set_config` (it reaches
`UiTheme.refresh_for_setting`, C-53) and settles between them; it shows the
error before the fix and not after. The fix lives in `UiTheme.refresh()` --
for example, block the Theme's and StyleBoxes' signals while mutating and
emit `changed` once at the end. No new refresh path.

```queue
**[Claude] SC-2 -- cycling the typeface logs no engine error**
- Plan: `plans/now/settings-and-corner.md` -- "SC-2 -- cycling the typeface logs no engine error"
- Files: `scripts/ui_theme.gd`, `test_scenarios/sc2_typeface_cycle_test.json`
- Check: `python tools/run_scenario.py test_scenarios/sc2_typeface_cycle_test.json` passes and its output has no `Parameter "fd" is null`, and `tools/verify.ps1` is green
- Proof: `absent: scripts/ui_theme.gd :: set_block_signals`
- Next after: SC-3 -- the project boots without GDScript warnings outside the HUD
```

## SC-3 -- the project boots without GDScript warnings outside the HUD

<!-- LAYER: immediate-task -->

Level: low (mechanical, behaviour identical).

**True now.** A boot prints: integer division in `saves_panel.gd`'s "min
ago"/"h ago"/"days ago" lines; `debug_panel.gd`'s Triggers section declares
a local `var challenge_advance_btn` that shadows the member at the top of the
file (the member is the ▶ button whose `disabled` state is refreshed); and
`input_selection.gd::_place_keep_clear` never uses `keep_adding`.

**True afterwards.** The integer divisions are explicit with identical
results; the local is renamed (e.g. `stage_trigger_btn`), so the member stays
the ▶ button; the parameter becomes `_keep_adding`, matching
`_place_home_cell`. `hud.gd`'s two warnings belong to SC-4.

```queue
**[Claude] SC-3 -- the project boots without GDScript warnings outside the HUD**
- Plan: `plans/now/settings-and-corner.md` -- "SC-3 -- the project boots without GDScript warnings outside the HUD"
- Files: `scripts/saves_panel.gd`, `scripts/debug_panel.gd`, `scripts/input_selection.gd`
- Check: a headless boot prints no `GDScript::reload` warning for the three files, and `tools/verify.ps1` is green
- Proof: `present: scripts/saves_panel.gd :: "%d min ago" % (seconds / 60)`
- Next after: SC-4 -- the corner column holds PAUSED and its problem lines, and left windows follow its height
```

## SC-4 -- the corner column holds PAUSED and its problem lines, and left windows follow its height

<!-- LAYER: immediate-task -->

Level: medium (layout; the owner of each piece is named below).

**True now.** `hud.gd` builds `pause_label` at a fixed `Vector2(16, 300)`,
so it draws over whichever readout line reaches y 300 (seen over
"Recruiting" in Silkscreen and "Average energy" in Open Sans). The problem
strip's lines are Buttons in `corner_column` with no width limit, so at the
default window they run off the right edge. `game_panel.gd` places a left
window below `hud.corner_bottom()`, but reflows only on a viewport resize and
`bottom_row_changed`; when the corner grows (text scale, typeface, a new
problem line) the Colony window covers the strip. `hud.gd` also warns on the
`set_stage_marker` parameter `visible` and the marker-arrow loop's `offset`.

**True afterwards.** `pause_label` is the last child of `corner_column`
(kept across `_refresh_corner` rebuilds like `perf_breakdown`), so pausing
only appends a line. Strip lines wrap within the viewport width minus the
corner's margins, recomputed on corner rebuild and viewport resize, not per
frame. `hud.gd` emits a corner-height signal from `corner_column.resized`,
and `connect_left_window_reflow` connects it the same way as
`bottom_row_changed` (extend that path; add no second one). The two `hud.gd`
locals are renamed.

**Must not change.** `camera_view.gd`'s `pause_label.visible` interface,
`corner_bottom()`, and the problem strip's click-to-select behaviour.

```queue-gated
**[Claude] SC-4 -- the corner column holds PAUSED and its problem lines, and left windows follow its height**
- Plan: `plans/now/settings-and-corner.md` -- "SC-4 -- the corner column holds PAUSED and its problem lines, and left windows follow its height"
- Files: `scripts/hud.gd`, `scripts/game_panel.gd`
- Check: a hands-on check is filed for PAUSED, the wrapped strip and the Colony window at Text scale 2 in Open Sans, and `tools/verify.ps1` is green
- Proof: `present: scripts/hud.gd :: pause_label = _make_label(Vector2(16, 300), "Heading")`
- Next after: none -- plans/now/settings-and-corner.md is complete
```
