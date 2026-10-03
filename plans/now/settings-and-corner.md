# Settings window and corner HUD -- findings from the 1 Oct 2026 hands-on pass

<!-- CONTEXT: plan | LAYER: immediate-task -->
Status: complete | Owner: Dave / Claude Code | Next: nothing further -- SC-4 landed, awaiting its hands-on check | Dependency: SC-2 follows UT-1 and UT-3 (`plans/now/ui-texture-polish.md`, `scripts/ui_theme.gd`); SC-4 follows SR-4 in the Claude lane (SR-4 moved there by Dave, 2 Oct 2026; both edit `scripts/hud.gd`) and runs before UT-4 | Verified: 2026-10-03

**Objective.** Four defects seen while running C-69 to C-73 by computer use on
1 Oct 2026 are fixed: C-72 failed once in three runs, cycling the typeface
logs an engine error, the project boots with GDScript warnings, and the
top-left corner overlaps itself and the left windows. Presentation only --
nothing here changes simulation (`plans/archive/ui_2026-09-20.md`, "Durable
rules"). The owning HUD plan, `plans/archive/hud-followups_2026-09-30.md`, is
archived, so these start a fresh plan (`plans/README.md`, "Plan schema").

| Slice | Files | Level | Lane | Startable | Depends on |
| --- | --- | --- | --- | --- | --- |
| SC-4 | `scripts/hud.gd`, `scripts/game_panel.gd` | medium | Claude | yes -- queued behind SR-4 (same lane) | SR-4 first; not alongside UT-4 (all edit `scripts/hud.gd`) |

**Neighbouring plan.** `plans/now/ui-texture-polish.md` (UT-1 to UT-5) came
from the same day's pass over C-57 to C-68 and shares two files: UT-1 and
UT-3 edit `scripts/ui_theme.gd` (SC-2 goes after them) and UT-4 edits
`scripts/hud.gd` (SC-4 and UT-4 run one after the other, either order).

A slice reads its own section and nothing else. Not planned: the hive view
swapping the last top-bar icon (it shows the view the button switches to,
which reads as intended), and C-60/C-71, which UT-1 now owns (Dave, 2 Oct 2026).

SC-1 shipped 2026-10-02; its specification is `plans/archive/SC-1_2026-10-02.md`.

SC-2 shipped 2026-10-02; its specification is `plans/archive/SC-2_2026-10-02.md`.

SC-3 shipped 2026-10-02; its specification is `plans/archive/SC-3_2026-10-02.md`.

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

```queue
**[Claude] SC-4 -- the corner column holds PAUSED and its problem lines, and left windows follow its height**
- Plan: `plans/now/settings-and-corner.md` -- "SC-4 -- the corner column holds PAUSED and its problem lines, and left windows follow its height"
- Files: `scripts/hud.gd`, `scripts/game_panel.gd`
- Check: `python tools/gdscript_warnings.py scripts/hud.gd` passes, a hands-on check is filed for PAUSED, the wrapped strip and the Colony window at Text scale 2 in Open Sans, and `tools/verify.ps1` is green
- Proof: `present: scripts/hud.gd :: pause_label = _make_label(Vector2(16, 300), "Heading")`
- Next after: none -- plans/now/settings-and-corner.md is complete
```
