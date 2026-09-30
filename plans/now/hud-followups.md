# HUD follow-ups — Dave's 28 Sep 2026 pass

<!-- CONTEXT: plan | LAYER: immediate-task -->
Status: active | Owner: Dave / Claude Code | Next: HF-4 -- the Winter forecast is a left-hand window | Dependency: none | Verified: 2026-09-30

**Objective.** Fix what Dave's 28 Sep 2026 hands-on batch found wrong or
awkward in the HUD, each as a small slice a low- or medium-level model can
finish without deciding anything. Every decision below was taken with Dave
in the session that processed the batch (28 Sep 2026).

**State.** Fifteen checks passed that day and are archived. C-60 failed
outright and C-57 half-failed; both corrected checks wait in
`checks/blocked.md` for HF-1 and HF-6. The rest are Dave's requests from the
same run. `plans/now/saves-access.md` (SA-1) and
`plans/now/skill-screen.md` (SK-1) hold the two larger requests, and
`plans/archive/hive-readouts_2026-09-29.md` (HR-1 to HR-3) the hive-view clicks and readouts.

## Open slices at a glance

| Slice | Outcome from the player's seat | Files owned | Startable | Level |
| --- | --- | --- | --- | --- |
| HF-4 | The Winter forecast is a left-hand window | `scripts/winter_panel.gd`, `scripts/year_winter.gd`, `scripts/main.gd`, `scripts/game_panel.gd`, `scripts/scenario_actions.gd`, `test_scenarios/hf4_winter_left_window_test.json` | yes | medium |
| HF-5 | Opening Nursery keeps the view you are in | `scripts/year_winter.gd` | yes | low |
| HF-6 | Why Raises lacks Pollen at 2.2 (C-57) | `scripts/scenario_actions.gd`, `scripts/hud.gd`, `scripts/challenge_runner.gd`, `test_scenarios/hf6_challenge2_raises_test.json` | yes | high |

**Dependencies.** None between slices; several share `hud.gd`,
`scenario_actions.gd` or `year_winter.gd` (as do HR-1 and HR-2 in
`plans/archive/hive-readouts_2026-09-29.md`), so they run one at a time in the Claude lane. **Required reading:** the slice's own section below, then only
the functions it names. **Do not change** `UiLayout.panel_chrome()`'s
result (HF-1) or any left window's rectangle (HF-4 adds one, moves none).

HF-1 shipped 2026-09-30; its specification is `plans/archive/HF-1_2026-09-30.md`.

HF-2 shipped 2026-09-30; its specification is `plans/archive/HF-2_2026-09-30.md`.

HF-3 shipped 2026-09-30; its specification is `plans/archive/HF-3_2026-09-30.md`.

## HF-4 — the Winter forecast is a left-hand window

Level: medium. Dave (28 Sep 2026): the forecast should use the left side
"like the other windows use (with the same rules)"; today it sits top right
over the bar.

**Change.** `winter_panel.gd::_ready`: `build_left_window(330)` in place of
`build_top_right_window(330, 44, -12)`, then `connect_left_window_reflow()`
as `skill_tree_panel.gd` does. `main.gd`: the `winter_window_requested`
handler calls `year_winter._toggle_panel(winter_panel)`, not
`winter_panel.toggle()`. `year_winter.gd::begin_winter_countdown`: call
`_close_other_left_windows(main.winter_panel)` before `open()` (same rule
for the automatic open), and change the warning's "The forecast in the top
right" to "The Winter window on the left". `game_panel.gd`'s header: the
winter window now joins "left_window". `scenario_actions.gd`: delete the
"winter window has no left-window toggle" comment (the filter now admits
it), and in `_check_panel_rect` accept `"open": false`, passing when the
panel is hidden. Fixture: open `colony`, then `winter`; assert `winter`
`inside_viewport` and `colony` `open: false`.

**Acceptance (check filed at closeout).** With Colony open, pressing Winter
opens the forecast where Colony was and closes Colony; nothing covers the
top-right bar.

```queue
**[Claude] HF-4 -- the Winter forecast is a left-hand window**
- Plan: `plans/now/hud-followups.md` -- "HF-4 — the Winter forecast is a left-hand window"
- Files: `scripts/winter_panel.gd`, `scripts/year_winter.gd`, `scripts/main.gd`, `scripts/game_panel.gd`, `scripts/scenario_actions.gd`, `test_scenarios/hf4_winter_left_window_test.json`
- Check: `python tools/run_scenario.py test_scenarios/hf4_winter_left_window_test.json` passes, and `tools/verify.ps1` is green
- Proof: `present: scripts/winter_panel.gd :: build_top_right_window(`
- Next after: HF-5 -- opening Nursery keeps the view you are in
```

## HF-5 — opening Nursery keeps the view you are in

Level: low. Dave (28 Sep 2026): the Nursery window should not take you to
the hive view. `year_winter.gd::_on_nursery_window_requested` sets
`main.in_hive_view = true` and calls `camera_view._apply_view()`. Replace
those three lines with `main.orders_zones._apply_zone_glow()`, which already
shows the glow only when the Nursery is open *and* the hive view is showing,
and which `_apply_view` re-runs on every later view switch.

**Acceptance (check filed at closeout).** In the meadow view, pressing
Nursery opens the window and the meadow stays on screen.

```queue
**[Claude] HF-5 -- opening Nursery keeps the view you are in**
- Plan: `plans/now/hud-followups.md` -- "HF-5 — opening Nursery keeps the view you are in"
- Files: `scripts/year_winter.gd`
- Check: `tools/verify.ps1` is green, and `_on_nursery_window_requested` no longer writes `main.in_hive_view`
- Proof: `present: scripts/year_winter.gd :: _close_other_left_windows(main.nursery_panel)`
- Next after: HF-6 -- why Raises lacks Pollen at 2.2 (C-57)
```

## HF-6 — why Raises lacks Pollen at 2.2 (C-57)

Level: high (investigation). Dave (28 Sep 2026): at Challenge 2's 2.2 (raise
a pollen Forager, `docs/challenge-stages.md`) the cell's Raises menu offered
no Pollen. Traced statically without finding the fault: 2.2's
`unlocked_keys` include `"pollen"`; `challenge_runner.gd::_apply_stage_gate_to_ui`
pushes it through `hud.set_allowed_mode_keys`; `show_cell_popup` always
reaches `_apply_cell_popup_gating`, which refills the menu via
`_fill_hatch_menu`. **Bounded question:** does the Forager Raises menu hold
"Forager — Pollen" once 2.2 is entered, and if not, which step drops it?

**Steps.** Add a `"menu_items"` assert condition to `scenario_actions.gd`
(`{"control": path, "menu_items": [labels]}`, comparing a `MenuButton`'s
popup item texts). Fixture: Challenge 2, `select_cell`, assert
`hud/**/hatch_forager_menu` offers only nectar at 2.1;
`advance_challenge_stage`; `select_cell`; assert both. If it fails, fix that
step, keep the fixture and move C-57 back to `checks/ready/`. If it passes,
repeat via the settings stage arrows (`retreat_challenge_stage`) and after a
save/restore; if still passing, report to Dave: the fault is on a path not
yet exercised. Do not change gating rules. A fix belongs in
`hud.gd::_fill_hatch_menu`/`_apply_cell_popup_gating` or
`challenge_runner.gd::_apply_stage_gate_to_ui`; if it needs anything else,
escalate with the options.

```queue
**[Claude] HF-6 -- why Raises lacks Pollen at 2.2 (C-57)**
- Plan: `plans/now/hud-followups.md` -- "HF-6 — why Raises lacks Pollen at 2.2 (C-57)"
- Files: `scripts/scenario_actions.gd`, `scripts/hud.gd`, `scripts/challenge_runner.gd`, `test_scenarios/hf6_challenge2_raises_test.json`
- Check: `python tools/run_scenario.py test_scenarios/hf6_challenge2_raises_test.json` passes with the fix, or its failure names the step that drops Pollen, and `tools/verify.ps1` is green
- Proof: `absent: scripts/scenario_actions.gd :: "menu_items"`
- Next after: none -- plans/now/hud-followups.md is complete
```
