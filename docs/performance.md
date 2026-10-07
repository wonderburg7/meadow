# Measuring performance, not guessing at it

Moved out of root `CLAUDE.md` in the Aug 2026 context restructure
(`plans/reference/technical-audit.md`) so the always-loaded file stays short. Read
this before touching `fog_of_war.gd`, `bee_movement.gd`, or anything else
on the hot per-frame path — `.claude/rules/performance.md` also points
here automatically when those files are opened.

`perf.gd` is an autoload that times named sections of code and shows
the worst frame times as a plot plus a top-8 breakdown in the corner,
behind the "fps" star (`Session.perf_enabled`, kept in sync by
`hud.gd::pinned_stats_changed`). It exists because this project has
had two performance regressions caused by confident guesses that were
wrong — see `plans/archive/PERF_PLAN.md` for the full writeup of the
second one, a 4fps drop that turned out to be `_grounded()` calling
itself instead of checking rain -- that function is
`bee_status.gd::grounded()` now, moved there in the bee.gd split, but
the bug and the method that found it predate the move.

**The method that found it, worth repeating for the next one:**

1. Wrap the suspect at its widest scope first (a whole `_process`),
   not the function you already suspect — the plan's own leading
   suspect (A\* pathfinding) turned out to be measured at ~0ms
   throughout, and guessing would have wasted the session chasing it.
2. Ask Dave to star "fps", play until it's bad, and screenshot the
   corner. The breakdown names the worst sections directly; the plot
   shows whether it's sustained or a spike.
3. Split whichever section is worst along whatever dimension could
   explain it — role, then state, then the specific function — one
   round per playtest. Each split is a small, safe edit: wrap a
   narrower scope in its own `Perf.begin`/`Perf.end` pair, nested
   inside the wider one that's already there (different names nest
   fine; the same name nested twice does not — see the warning
   below). Two or three rounds is normal; this investigation took
   three (role → the eight forager states → ruling out a side theory)
   before the exact function fell out.
4. Only once a specific function is named, go and read it. Don't read
   speculatively before that — it's exactly the guessing this exists
   to avoid.

**Adding a new hot per-frame system?** Give it a `Perf.begin("name")`
/ `Perf.end("name")` pair at the point that covers its whole per-frame
cost, the same way the existing dozen-plus sections do. It costs
nothing when perf is off (both functions check
`Session.perf_enabled` and return immediately). This keeps the
breakdown complete rather than silently blind to whatever's newest —
grep `scripts/**/*.gd` for `Perf.begin(` to see the current full list
rather than trusting a copy of it here, since that list will drift.

**The one way this goes wrong**: a `begin` with no matching `end` on
every exit path of the function it's in. `Perf.end` silently no-ops
if there's no matching `begin` open, so a missed exit path just
under-counts that call rather than crashing or corrupting later
frames — safe, but worth actually checking (count `return` statements
in the function, make sure each has an `end` before it) rather than
assuming. Never reuse a section name for two spans that can be
active at once in the same function; a second `begin` under the same
name overwrites the first one's start time.

## Explicitly do not change

Carried forward from `plans/archive/PERF_PLAN.md`'s own findings, and
reaffirmed by the Aug 2026 technical audit (`plans/reference/technical-audit.md`):

- Don't re-add spatial indexing for obstacles (14 objects; already
  measured as slower than a linear scan — see `ROADMAP.md`).
- Don't touch A* pathfinding or move it to a coarser graph — cleared as a
  suspect, measures at ~0ms.
- Don't remove or weaken `perf.gd` — it has already paid for itself many
  times over.
- Don't turn the bee behaviour helper modules (`bee_movement.gd` etc.)
  into per-bee child Nodes — the static-`RefCounted` pattern is correct
  for something instantiated hundreds of times.
- Don't introduce object pooling, MultiMesh rendering, or reduce
  off-screen simulation fidelity without a specific measured bottleneck
  pointing at exactly that.

## Canvas cost by colony size (SPR-1, SPR-2)

Measured 7 Oct 2026 with `python tools/run_scenario.py <file> [--windowed] --report full`
(480 frames after 120 warm-up, one run each). Frame times are ms, mean / p95.
SPR-2 scenarios use 100 cells (500 bees) and 150 cells (1,000 bees).

| Bees | Draw calls (mean) | Render objects (mean) | Nodes | Windowed frame | Headless frame |
| --- | --- | --- | --- | --- | --- |
| 200 | 253 | 409 | 15,812 | 9.8 / 11.0 | 7.5 / 8.7 |
| 500 | 253 | 409 | 20,112 | 17.1 / 19.4 | 33.2-39.4 / 62.0-69.7 |
| 1,000 | 1,181 | 1,337 | 27,112 | 32.1 / 39.4 | 26.4 / 33.5 |

The slow 500-bee headless frame reproduced in two runs (33.2 and 39.4 ms mean) and is slower than the
1,000-bee headless frame, so it is not noise. The cause is not yet known; one candidate is cell
density (500 bees in 100 cells, 1,000 bees in 150). Separately, the 500-bee draw calls equal the
200-bee figure, which is an observation only. The windowed p95 first passes 16.7 ms at 500 bees.
