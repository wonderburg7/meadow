---
paths:
  - "fog_of_war.gd"
  - "perf.gd"
  - "bee_movement.gd"
  - "spatial_grid.gd"
---

# Measure first on the hot path

Full method and current do-not-change list: `docs/performance.md`. The
short version: **profile before changing.** This project has twice
disproved a confident guess about what was slow (A* pathfinding cleared
as a suspect; the real 4fps cause was a recursive `_grounded()` call —
`docs/archive/PERF_PLAN.md`) and found the real bug by measuring with
`perf.gd` instead.

**Give any new hot per-frame system its own `Perf.begin("name")` /
`Perf.end("name")` pair** at the point that covers its whole per-frame
cost. It costs nothing when perf is off. Every exit path of the
function needs a matching `end` — a missed one just under-counts rather
than crashing, so check by counting `return` statements. Never reuse a
section name for two spans that can be active at once in the same
function.

**Check the count *and* the call rate before adding an index.** The
spatial grid was applied to 14 obstacles as well as 250 flowers and made
steering *slower* — querying 25-121 buckets and allocating an Array per
bee per frame beats a 14-item linear scan that allocates nothing. Only
the flowers (250 objects, 8 queries/sec) were worth indexing; the
obstacles (14 objects, 60/sec) were not. Don't re-add obstacle indexing
without a fresh measurement showing it's worth it.

**Allocation churn reads as jitter, not as a lower FPS number.**
Movement is `speed * delta`, so uneven frame times show up as bees
lurching rather than as a clean slowdown. If something looks twitchy
before it looks slow, suspect per-frame allocation first.

**Fog-of-war is currently mid-investigation** (`AUDIT_PLAN.md` Bundle
C) — instrumentation is split into `fog_of_war_update` and
`fog_of_war_draw`, but the baseline measurement is still pending. Don't
write optimisation code for it without a fresh baseline showing a real
cost; "measured, not a bottleneck" is a valid outcome.
