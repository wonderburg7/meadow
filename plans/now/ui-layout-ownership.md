# One owner for every persistent HUD rectangle

<!-- CONTEXT: plan | LAYER: immediate-task -->
Status: active | Owner: Dave / Claude Code | Next: LAY-1 -- ui_layout.gd returns outer rectangles, not fragments | Dependency: LAY-1 waits on UI-T-6 and UI-W-1, so it consolidates working arithmetic rather than racing it | Verified: 2026-09-08

**Objective.** A persistent HUD panel's rectangle is decided in one place,
applied through one helper, and cannot be widened or heightened by its own
contents. Dave, 8 Sep 2026: "a lot of ongoing issues relate to the windows
and panels, particularly the command panel -- diagnose why this is having so
many issues, ensure an approach, architecture and organisation that mitigates
the risks."

## Why this keeps happening -- the diagnosis, 8 Sep 2026

Five hands-on checks across 3-8 Sep 2026 have reported a panel that is off
screen, over its neighbour, or the wrong size: C-11, C-12, C-13, C-18, C-19.
Each was fixed in the panel that showed the symptom, and the symptom moved.
Reading the four sites together gives four causes, and none of them is a
mistake anyone made twice through carelessness -- each is a Godot behaviour
the code does not currently state anywhere.

### Cause 1 -- `custom_minimum_size` is a floor, and is used as a ceiling

Three separate places compute a budget and then assign it to
`custom_minimum_size`:

| Site | Assigns | Works? |
| --- | --- | --- |
| `hud.gd::_apply_selection_tray_width` | `selection_panel.custom_minimum_size.x` | **no** |
| `hud.gd::_resize_command_tray` | `command_scroll.custom_minimum_size.y` | by accident |
| `_apply_left_window_rect` in colony/foraging/nursery panel | `scroll_container.custom_minimum_size.y` | by accident |

`custom_minimum_size` raises a control's minimum. It never lowers it. The
second and third work only because the control they are set on is a
`ScrollContainer` whose own minimum on its scrolling axis is near zero, so
the floor happens to land exactly on the intended value. The first is set on
a `PanelContainer` whose children have real minimum widths, so a long label
or a wide button pushes the summary panel straight through the 16px gap and
over the command tray -- which is exactly what Dave saw in C-18.

`plans/now/ui.md` already records the sibling half of this ("setting
`Control.size` smaller than a control's combined minimum size does not shrink
it"). The floor/ceiling half was never written down.

### Cause 2 -- a ScrollContainer reports ~0 minimum on the axis it scrolls

`_resize_command_tray` measures the content it is about to cap with
`command_scroll.get_combined_minimum_size().y` -- and `command_scroll` is the
scroll container itself, with `vertical_scroll_mode = SCROLL_MODE_AUTO`.
Godot's `ScrollContainer::get_minimum_size()` deliberately omits a child's
minimum on any axis it can scroll, so that measurement returns roughly zero
whatever the tray holds. `minf(0, ceiling)` is 0, the cap is set to nothing,
and the tray renders as its own chrome with no visible content.

That is the whole of Dave's C-18 report: "a flat bar at the bottom of the
screen ... only a few pixels high and doesn't display any buttons/choices."
It is a regression introduced by UI-T-1, which fixed the previous symptom
(the tray running off the bottom edge) with a cap that measures the wrong
control.

### Cause 3 -- nobody subtracts the panel's own chrome

`UiTheme.panel_stylebox()` gives every persistent panel a 2px border and
8px/10px content margins: **20px vertically and 24px horizontally** that sit
outside whatever the inner control is given. Every budget in `ui_layout.gd`
is written for the panel's outer rectangle and then applied to an inner
control, so every capped panel finishes 20px taller than its budget.

`left_window_max_height` subtracts the 16px gap it is meant to preserve; the
panel then eats 20px of it and ends up 4px *into* the summary panel. That is
C-19's "the menu does not react to the size of the summary panel to make the
appropriate gap, and at times this overlaps" -- the reaction is there, the
arithmetic is 20px short.

### Cause 4 -- there is no owner, so there is nowhere for the rule to live

`ui_layout.gd` holds arithmetic; it does not hold rectangles. Each panel asks
the HUD for its neighbours' edges (`hud.corner_bottom()`,
`hud.selection_panel_top()`) and finishes the sum itself, differently. Five
persistent rectangles, five private conventions, and no statement anywhere of
which panel yields to which. A fix therefore lands wherever the symptom
appeared, which is why the symptom keeps moving.

## The hierarchy, decided

Dave asked for "a hierarchy which dictates the sizes of panels, e.g. command
panel > summary panel > left-hand panel, with consistent buffer areas". This
is that hierarchy, and it is the order every rectangle function resolves in:

1. **The command tray**, bottom centre. Sized by its own content up to
   `command_tray_max_height`; scrolls internally beyond that. Nothing else
   may move or shrink it. It is first because its contents are the player's
   controls -- an unreachable button is a dead run, which is what blocked
   C-5 and C-7 twice.
2. **The bottom row's side bands** -- the summary panel on the left, Dr
   Gallerin on the right. They take the width the tray leaves and may not
   grow past it, whatever their contents ask for.
3. **The left-side windows** -- Colony, Foraging, Nursery. They take the
   height the corner readout above and the bottom row below leave, and
   scroll inside it.
4. **Transient popups** -- cell popup, tooltips, menus. Free to overlap
   anything; they are dismissed by the next click.

**One gap value.** `UiLayout.PANEL_GAP` (16px) separates any two of the above
and any one of them from a screen edge. There is no second spacing constant.
`SELECTION_TRAY_GAP`, `SELECTION_TRAY_LEFT_MARGIN` and `BOTTOM_ROW_MARGIN`
are all already 16 and all become aliases of it.

## What to change so this cannot recur

The two live bugs were fixed first, in the plans that owned them: UI-T-6
(shipped 2026-09-08, `plans/archive/UI-T-6_2026-09-08.md`) and UI-W-1
(shipped 2026-09-08, `plans/archive/UI-WINDOWS_2026-09-08.md`); they were
urgent and could not wait behind a refactor. LAY-1 now consolidates the
arithmetic both got right, and adds the guard.

### LAY-1 -- ui_layout.gd returns outer rectangles, and one helper applies them

**Reasoning level: medium.** It moves existing, by-then-correct arithmetic
into one owner and adds a source check. It decides nothing new: the hierarchy
above is already decided, and the two bug-fix slices will have established
the chrome arithmetic.

**Startable when** UI-T-6 and UI-W-1 have both landed. Before then it would
be consolidating two known-wrong sums.

**Deliver, in `scripts/ui_layout.gd`:**

- `const PANEL_GAP := 16.0`, with `SELECTION_TRAY_GAP`,
  `SELECTION_TRAY_LEFT_MARGIN` and `BOTTOM_ROW_MARGIN` redefined as
  `PANEL_GAP` so the three existing names keep working and there is one
  number to change.
- `static func panel_chrome() -> Vector2` returning the horizontal and
  vertical chrome of `UiTheme.panel_stylebox()`, read from the stylebox
  (`content_margin_*` plus `get_border_width(...)`) rather than written out
  again as a literal. Every "outer rectangle -> inner budget" conversion in
  the project goes through this.
- One function per persistent rectangle, each returning the panel's **outer**
  `Rect2` for a given viewport, resolved in the hierarchy order above:
  `command_tray_rect`, `summary_panel_rect`, `gallerin_rect`,
  `left_window_rect`. The existing width/edge/height helpers become their
  internals rather than being called directly by panels.

**Deliver, in a new script at scripts/ui_panel_layout.gd (~40 lines):**

- `static func apply(panel: PanelContainer, scroll: ScrollContainer, rect: Rect2) -> void`.
  It sets the panel's anchors/offsets from `rect`, subtracts
  `UiLayout.panel_chrome()`, and puts the remainder on `scroll`'s
  `custom_minimum_size` -- the one control in the tree allowed to be smaller
  than its contents. `scroll` may be null for a panel that does not scroll,
  in which case the panel's own size is set and its children are expected to
  wrap.
- It must never read a control's own `get_combined_minimum_size()` through a
  ScrollContainer (Cause 2). Where content height is genuinely needed, it
  measures `scroll.get_child(0)`.

**Then change the five callers to use it, changing no behaviour:**
`hud.gd::_apply_selection_tray_width`, `hud.gd::_resize_command_tray`, and
`_apply_left_window_rect` in each of `colony_panel.gd`, `foraging_panel.gd`
and `nursery_panel.gd`.

**Deliver, in `tests/source_checks.py`:** a check that fails if
`custom_minimum_size` is assigned in `hud.gd`, `colony_panel.gd`,
`foraging_panel.gd` or `nursery_panel.gd` on any control those files declare
as a persistent panel or its scroll container, outside `ui_panel_layout.gd`.
The message must name Cause 1 and point at the new helper's `apply`. Existing
assignments on ordinary content controls (a fixed-height row, the donut's
300x150 canvas) are untouched -- the check is limited to the panel/scroll
variables listed in those four files' own `var` declarations.

**Do not change** what any panel *contains*, `ui_theme.gd`'s stylebox values,
or the pre-run menu. LAY-1 is a move, not a redesign, and a visual difference
anywhere is a bug in it.

**Check to file:** C-28 -- at 1920x1080, 1280x720 and 800x600, with a bee and
then a cell selected, and with each left-side window open in turn, every
persistent panel is wholly on screen with a visible 16px gap from its
neighbours and from the screen edge, and nothing looks different from the day
before.

<!-- LAYER: on-demand -->

## Durable rules this produces

These are added to `plans/now/ui.md`'s "Durable rules" by LAY-1, and are
already in force for UI-T-6 and UI-W-1:

- **`custom_minimum_size` is a floor.** It can only make a control bigger. To
  cap a persistent panel, put the cap on a `ScrollContainer` inside it -- the
  one control allowed to be smaller than its contents -- and never on the
  panel itself.
- **A ScrollContainer reports no minimum on the axis it scrolls.** Measure
  content through its child, never through the ScrollContainer.
- **A budget is an outer rectangle.** Subtract `UiLayout.panel_chrome()`
  before applying it to anything inside a panel.
- **Panels resolve in one order** -- command tray, then bottom-row side
  bands, then left-side windows, then popups -- separated by `PANEL_GAP` and
  nothing else.
