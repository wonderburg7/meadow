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
