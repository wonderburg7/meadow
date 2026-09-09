# A deterministic check for persistent panel geometry

<!-- CONTEXT: plan | LAYER: immediate-task -->
Status: active | Owner: Dave / Claude Code | Next: LAY-5, the headless panel-rectangle assertion | Dependency: none — LAY-5 is startable today; LAY-6 follows it | Verified: 2026-09-09

**Objective.** A persistent HUD panel leaving the viewport, or losing its
16px gap, fails `tools/verify.ps1` instead of costing a hands-on pass.

**State.** Four of Dave's hands-on passes since 3 Sep 2026 have been spent on
one panel's rectangle: C-11, C-12, C-13, C-18 and C-19, across UI-T-1, UI-T-6,
LAY-1 and now LAY-2 (`plans/archive/PANEL_LAYOUT_2026-09-09.md`). Each cost a day of
round trip and none could have been caught by a static check, because the
failure is a runtime geometry fact rather than a source pattern. The headless
scenario runner already boots the real game and runs assertions
(`docs/headless-run-contract.md`), so the geometry is reachable without a
human being in front of the screen. Nothing else in this file is open.

## Open slices at a glance

| Slice | Outcome | Owns | Startable | Reasoning |
| --- | --- | --- | --- | --- |
| LAY-5 | A headless check fails when a persistent panel leaves the viewport | `scenario_actions.gd`, `tests/fixtures/`, `tests/` | yes | medium |
| LAY-6 | A headless check fails when a control inside a panel has no usable size | `scenario_actions.gd`, `tests/fixtures/`, `tests/` | after LAY-5 | medium |

**Required reading for this slice.** This file's own section,
`docs/headless-run-contract.md`, and `scripts/scenario_actions.gd`'s existing
verb and assertion helpers. Do not read `plans/archive/PANEL_LAYOUT_2026-09-09.md` — LAY-2's
behaviour is stated in the acceptance below.

**Do not change** any layout code. This slice adds a check and nothing else;
if the check fails on landing, the failure is a finding for
`plans/now/hud-controls.md`, not a licence to edit `ui_layout.gd` here.

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

## LAY-6 — a headless check that fails when a built control has no usable size

**Minimum reasoning level: medium.** Depends on LAY-5, which builds the
`viewport_size` verb and the rectangle-reading helper this reuses.

**Why this exists.** LAY-5 catches a *panel* leaving the viewport. Dave's 9
Sep 2026 pass then found three separate defects one level down, in the
controls inside those panels, none of which LAY-5 would see:

- The command tray's three columns bunched against its left edge, leaving
  most of the tray empty (`plans/now/hud-controls.md` HC-1).
- The soil panel's two buttons collapsed to about 10px wide and stretched
  down the panel, with their text clipped away
  (`plans/now/hud-controls.md` HC-2).
- The "Change to…" menu drawing as bare text with no button behind it
  (`plans/now/hud-controls.md` HC-3).

All three are the same class as the anchor bug: a Godot container gives a
child its minimum size, and a child that asks for nothing gets nothing. Every
one was found by a person looking at a screenshot. That is the round trip
this slice removes.

**Change 1 — a `control_rect` assertion.** In `scripts/scenario_actions.gd`,
add an assertion taking
`{"control": "<path>", "min_size": [w, h], "inside": "<path>"}`.

- `<path>` is a slash-separated path from `main.hud`, resolved with
  `get_node_or_null` against a small allowlist of named roots (`hud`,
  `selection_panel`, `command_tray`, `gallerin_panel`), so a fixture cannot
  reach arbitrary scene nodes.
- The assertion fails when the control is visible in the tree and its
  `get_global_rect()` is smaller than `min_size` on either axis, or when
  `inside` is given and the control's rectangle is not wholly within that
  ancestor's.
- An invisible control passes silently: visibility is what
  `_rebuild_role_controls` legitimately toggles, and asserting on hidden
  controls would make every fixture a list of which columns happen to be
  shown.
- The failure message names the control's path and prints its rectangle and
  the expected minimum.

**Change 2 — an `even_columns` assertion.** Add an assertion taking
`{"container": "<path>", "children": <n>, "tolerance": <px>}` that fails when
the container's first `<n>` visible children do not have widths equal within
`tolerance`, or when the gaps between them are not equal within `tolerance`.
This is the one HC-1 needs, and it is the assertion no per-control minimum
can express.

**Change 3 — extend the LAY-5 fixture rather than adding a second one.** In
the `layout_panels.json` fixture LAY-5 adds under `tests/fixtures/`, at
1920x1080 and again at 800x600:

- Select a bee and assert `even_columns` on the tray's `command_columns` with
  three children, tolerance 2px, at 1920x1080 only. At 800x600 the columns are
  allowed to wrap, so assert `control_rect` on each of the three wrappers
  instead, with a minimum of 60x20.
- Select a soil block and assert `control_rect` on both soil buttons with a
  minimum of 80x20, `inside` the summary panel.
- Assert `control_rect` on the "Change to…" menu with a minimum of 60x20.

**Change 4 — a sweep, not just named controls.** Add a `no_collapsed_controls`
assertion taking `{"root": "<path>"}` that walks every visible `Button` and
`MenuButton` under `root` and fails on any whose global rectangle is under
8x8 px. Run it over `hud` once per viewport size in the fixture. A named
assertion proves the control someone thought about; the sweep is what catches
the next one nobody did.

**Do not assert on colours, fonts or styleboxes.** HC-3's flat-button defect
is a drawing property, not a geometry one, and the sweep above does not catch
it. Say so plainly in the assertion's own comment so the next session does not
assume the check is wider than it is, and leave HC-3 to a screenshot.

**Acceptance.** With `plans/now/hud-controls.md` HC-1 and HC-2 still
unfixed, the new assertions fail and name the tray columns and both soil
buttons. Apply HC-1 and HC-2 and they pass. Put that before-and-after in the
commit message. If HC-1 and HC-2 have already landed by the time this slice
runs, reintroduce each defect on purpose instead, one at a time.

**No hands-on check is filed for this slice.** Its purpose is that none is
needed.

**Proof the defect is present:** `absent: scripts/scenario_actions.gd :: no_collapsed_controls`

