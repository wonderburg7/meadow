# Performance plan: find and fix the 4fps problem

Written 14 Aug 2026. Agreed with Dave.

**Steps 1-4 done, 14 Aug 2026** (`01098cb` through `6488415`, see the
Build Log for the full session-by-session list). Root cause found and
fixed: `bee.gd::_grounded()` called itself instead of checking rain --
unconditional recursion until GDScript's call stack errored out,
called from `_seek_flower` and `_go_to_exit` as their first line,
which is exactly what three rounds of narrowing the instrumentation
kept naming. Fixed in `6488415`, committed separately from the
instrumentation per the rule below. Notion **Performance Map** written
with the measured pre-fix figures.

**Confirmed, 14 Aug 2026: 60fps.** Dave's re-measure after the fix --
16.6ms average, 17ms worst, same colony that was reading 4-18fps
before. Step 4 fully closed. The `main.gd` six-file split (parked
below) is now unblocked. `_backups/` is also gone (Dave deleted it),
so the "Also outstanding" note further down is done too.

The measuring method itself (instrument the widest scope first, then
split by role/state/function one playtest at a time) is now written
up in `CLAUDE.md` under "Measuring performance, not guessing at it",
since Dave asked for it to be reusable for whatever's slow next
rather than specific to this one investigation. `perf.gd` and the
fps-starred breakdown stay in the project permanently -- see that
section for the convention on giving new hot per-frame code its own
section.

The plan below is left as written, for the record of what was agreed
and why -- the "current status" is the block above, not this line.

Read this before starting. It exists so the session doing the work does
not have to rediscover any of it.

---

## The situation

The frame rate drops as low as **4fps with only 29 bees**.

Two rounds of fixes have already landed today (`0cb23c3`, `7433a42`):
the spatial grid was taken back off the obstacles, cell and flower
redrawing was throttled from 60 to 6 times a second, and three
once-a-second colony sweeps were given random phases. Those were real
improvements worth perhaps 30% each.

4fps means something is costing roughly **250 milliseconds in a single
frame**. That is not death by a thousand cuts. It is one pathological
thing, and it has not been found yet.

**Do not guess at it.** Both performance regressions this project has
had were caused by confident estimates that turned out to be wrong. This
plan builds a measuring tool first and uses it.

---

## Order of work

Dave originally asked for the plot, then the Notion map, then
correlation tooling. The order below is deliberately different:
instrumentation comes first, because it makes the Notion map accurate
(measured rather than estimated) and because it is what tells us what to
fix. The plot shares the sampling code, so it comes along with it.

1. Instrumentation and the plot
2. Find the cause
3. Write the Notion performance map from what was measured
4. Fix, then re-measure

---

## Step 1: Instrumentation and the plot

### New file: `scripts/perf.gd`, registered as an autoload

Register it in `project.godot` under `[autoload]` alongside `GameConfig`
and `Session`. `tests/source_checks.py` checks that autoloads are
registered, so forgetting this will fail the suite, which is the check
working correctly.

- API: `Perf.begin("cells")` / `Perf.end("cells")`, timed with
  `Time.get_ticks_usec()`.
- Accumulates microseconds per named section per frame into a
  dictionary.
- At frame end, rolls per-section totals into a rolling average and
  records the frame's total.
- `Perf.mark("disease tick")` for one-off events, so we can see which
  periodic sweeps fired on which frame.
- Must be nearly free when off. Gate it behind a `Session.perf_enabled`
  flag so a shipped build pays nothing.

### Sections to instrument

About a dozen `begin` / `end` pairs. Keep each pair adjacent and inside
the same function: a `begin` without a matching `end` is the obvious way
for this to go wrong.

| Section | Where |
|---|---|
| `bees` | `bee.gd::_process`, whole body |
| `bee_move` | `bee.gd::_move_towards` |
| `bee_path` | `hive.gd::path_between` (the A* search) |
| `cells` | `hive_cell.gd::_process` |
| `flowers` | `flower.gd::_process` |
| `signals` | `main.gd::_refresh_signals` |
| `season` | `season.gd::_process` |
| `rival` | `rival_hive.gd::_process` |
| `hatch` | `main.gd::_hatch_ready_brood` |
| `draw` | `main.gd::_draw_selection_box` and `_draw_hive_orders` |
| `hud` | `hud.gd::_process` |
| `nav_rebuild` | `hive.gd::build_navigation` |

### The plot

A new `Control` subclass with a `_draw`, added to `hud.gd`'s
`corner_column` when `"fps"` is starred, sitting under the three
numbers that are already there.

- Ring buffer of the **worst** frame time in each 0.25s window, 120
  slots, so about 30 seconds of history.
- 140 x 40 px. Y axis autoscaled with a floor, plus reference lines at
  16.7ms (60fps) and 33ms (30fps).
- **Bars, not a line.** Spikes are the whole point and a line chart
  hides single-frame ones.
- Coloured green under 16.7ms, amber under 33ms, red above.
- `queue_redraw()` only when a new sample lands, four times a second. A
  plot that redrew every frame would be part of the problem it is
  measuring.

### Breakdown overlay

When `"fps"` is starred, show the top five sections by average ms under
the plot:

```
bee_path 180ms  ·  cells 12ms  ·  flowers 4ms
```

This is the part that answers "which process correlates with the drop".
About ten lines once `perf.gd` exists.

**Open decision:** one star for all of it (numbers, plot, breakdown), or
separate stars. Default is one, since Dave asked for the plot "with the
frame rate toggle".

---

## Step 2: Find the cause

Run with the overlay on, in both views, with a colony big enough to
reproduce it. The breakdown names the culprit directly.

**First, establish whether 4fps is sustained or a spike.** Sustained
points at suspects 1 or 2 below. Spiky points at 3, 4, or a periodic
sweep. The plot shows which at a glance.

### Suspect list, in order

1. **A\* pathfinding running per bee per frame inside the hive.**
   `bee.gd::_move_towards` calls `hive.path_between()` whenever the
   target has moved more than 6 units from `path_goal`. If a bee's
   target is itself moving, or if the path comes back empty and is
   therefore never cached, that is a full A* search over the hive grid
   every frame, per bee. 29 bees indoors would do it on its own.
   **Check:** instrument `bee_path` and count *calls per frame*, not
   just time.

2. **Draw calls.** The project uses the GL Compatibility renderer,
   which batches 2D poorly. Each `obstacle.gd` raised area spawns up to
   about 22 decoration polygons, 250 flowers have roughly 5 nodes each,
   and every cell has a polygon, an outline, a designation ring, a fill
   shape and a label. Total CanvasItems could be several thousand.
   **Check:** Godot's Debug -> Monitors, "Draw Calls" and "Objects". If
   draw calls are in the thousands this is it, and the fix is different
   in kind: merge static decoration into fewer polygons, or draw
   flowers with a single `_draw` on a parent rather than one node each.

3. **`selection_layer.queue_redraw()` every frame** in
   `main.gd::_process`, triggering `_draw_hive_orders()`, which walks
   every bee and its order chain.

4. **`_hatch_ready_brood()`** walking every cell every frame.

5. **`rain_effect.gd::_draw`** if the drop count is high.

---

## Step 3: The Notion performance map

New page under the Meadow database, alongside Build Log and Decisions
Log: **"Performance Map"**.

One row per process:

| Process | File and function | Cadence | Scales with | Measured ms | Notes |
|---|---|---|---|---|---|

- **Cadence**: every frame / 8 per second / once a second / on event /
  on load.
- **Scales with**: x bees, x cells, x flowers, x obstacles, or fixed.
- **Measured ms**: taken from `perf.gd`, not estimated. Record the
  colony size and view at the top of the page, or the figures mean
  nothing.

Below the table, a short **crunch points** section: which rows scale
with something that grows during a run, since those are the ones that
bite later. Sprites will multiply the draw-call row specifically, so
note that now.

Write this page **after** Step 2, so it records what was measured rather
than what was assumed.

---

## Step 4: Fix, then re-measure

Fix whatever Step 2 names. Run the same test. Record before and after in
the Performance Map.

Commit the fix **separately** from the instrumentation, so the two can
be judged independently.

---

## Verification

- `python3 tests/source_checks.py` and `python3 tests/balance_tests.py`
  after every file change.
- `perf.gd` must be in `[autoload]` in `project.godot`.
- **The instrumentation must not be measurable.** Star the readout, note
  the numbers, unstar, confirm the average does not change.

## Risks

- An autoload touching hot paths is exactly where an unmatched `begin`
  leaks. Keep pairs adjacent.
- The overlay is new drawing on the thing being measured. Hence 4Hz.
- **The `main.gd` six-file split stays parked** until this is done.
  Refactoring while chasing a 250ms frame makes the chase harder. It is
  still agreed and still queued, and `bee.gd` (3,098 lines) follows it.

## Also outstanding

- ~~`_backups/`~~ Deleted by Dave, 14 Aug 2026.
