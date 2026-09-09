# A deterministic check for persistent panel geometry

<!-- CONTEXT: plan | LAYER: immediate-task -->
Status: active | Owner: Dave / Claude Code | Next: LAY-5, the headless panel-rectangle assertion | Dependency: none — LAY-2 has shipped, so this is startable today | Verified: 2026-09-09

**Objective.** A persistent HUD panel leaving the viewport, or losing its
16px gap, fails `tools/verify.ps1` instead of costing a hands-on pass.

**State.** Four of Dave's hands-on passes since 3 Sep 2026 have been spent on
one panel's rectangle: C-11, C-12, C-13, C-18 and C-19, across UI-T-1, UI-T-6,
LAY-1 and now LAY-2 (`plans/now/panel-layout.md`). Each cost a day of
round trip and none could have been caught by a static check, because the
failure is a runtime geometry fact rather than a source pattern. The headless
scenario runner already boots the real game and runs assertions
(`docs/headless-run-contract.md`), so the geometry is reachable without a
human being in front of the screen. Nothing else in this file is open.

## Open slices at a glance

| Slice | Outcome | Owns | Startable | Reasoning |
| --- | --- | --- | --- | --- |
| LAY-5 | A headless check fails when a persistent panel leaves the viewport | `scenario_actions.gd`, `tests/fixtures/`, `tests/` | yes | medium |

**Required reading for this slice.** This file's own section,
`docs/headless-run-contract.md`, and `scripts/scenario_actions.gd`'s existing
verb and assertion helpers. Do not read `plans/now/panel-layout.md` — LAY-2's
behaviour is stated in the acceptance below.

**Do not change** any layout code. This slice adds a check and nothing else;
if the check fails on landing, the failure is a finding for
`plans/now/panel-layout.md`, not a licence to edit `ui_layout.gd` here.

## LAY-5 — a headless check that fails when a panel leaves the viewport

**Minimum reasoning level: medium.**

**Change 1 — a scenario verb that sets the window size.** In
`scripts/scenario_actions.gd`, add a `viewport_size` action taking
`{"w": int, "h": int}` that sets `main.get_window().size = Vector2i(w, h)`.
Set the root window's size directly rather than relying on Godot's
`--resolution` command-line flag: the direct assignment works under
`--headless`, where the flag's behaviour is not guaranteed. Follow the file's
existing verb shape — resolve on the tick it fires, mark `"_resolved": true`,
and log through the same helper the other verbs use.

**Change 2 — a `panel_rect` assertion.** Add an assertion taking
`{"panel": "<name>", "inside_viewport": true, "gap_below": <px>}`, where
`<name>` is one of `command_tray`, `summary`, `colony`, `foraging` or
`nursery`, resolved through `main.hud` and the three window scripts. It reads
the panel's `get_global_rect()` and fails the run when the rectangle is not
wholly inside `get_viewport().get_visible_rect()`, or when the distance from
its bottom edge to the viewport's bottom edge is not `gap_below` within 1px.
The failure message must name the panel and print both rectangles, so the
next session can see which edge went where without re-running anything.
`gap_below` is optional; omit it and only the containment clause runs.

**Change 3 — one fixture covering the three supported sizes.** Add
a `layout_panels.json` fixture under `tests/fixtures/`. For each of 1920x1080, 1280x720 and
800x600 in turn: set the viewport size, select a bee, assert `command_tray`
and `summary` with `gap_below: 16`, open Colony, Foraging and Nursery in turn
and assert each with `inside_viewport`, then open the tray's `More…` and
assert `command_tray` again. 800x600 is the supported floor
(`UiLayout.MIN_SUPPORTED_WIDTH`); do not add a smaller size.

**Change 4 — wire it into the suite.** Add a test in `tests/` that runs the
fixture through `tools/run_scenario.py`, following the pattern of the existing
`test_headless_*.py` files, and skips with a clear message naming the missing
executable when Godot is not on the path. `tools/verify.ps1` picks up `tests/`
already; confirm it runs and reports, and do not restructure the runner.

**Acceptance.** Reintroduce LAY-2's bug on purpose — put a
`command_tray.reset_size()` back as the last line of
`hud.gd::_resize_command_tray()` — and the new test fails, naming
`command_tray` and printing both rectangles. Remove that line and the test
passes. Put that before-and-after in the commit message.

**No hands-on check is filed for this slice.** The point of it is that none is
needed; filing one would contradict the slice.

**Proof the defect is present:** `absent: scripts/scenario_actions.gd :: panel_rect`
