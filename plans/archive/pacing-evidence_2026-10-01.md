# Pacing evidence — the headless gates can read in band

<!-- CONTEXT: plan | LAYER: immediate-task -->
Status: complete | Owner: Dave / Codex | Next: None -- plan complete; follow-ups: the arc's hourly snapshot cadence is filed in WO-1 (`plans/now/winter-onset.md`), PE-2 in `plans/design/product-scope.md` §6.2 | Dependency: none | Verified: 2026-10-01

**Objective.** `python tools/pacing_gates.py` can say truthfully whether the
headless alpha arc meets each timing budget in `plans/design/product-scope.md`
§3, so a balance change can be judged against the 5/10/60/90-minute gates
without a playthrough.

**State.** `tools/pacing_gates.py` runs `test_scenarios/alpha_arc_test.json`
and compares four `milestone_times` values from `analyze_session.py` with a
+/-25% band around each target. Each value is the elapsed in-game day of the
first qualifying snapshot; legacy `milestones` retains its whole-day,
last-snapshot compatibility values. Food security and winter survival now
require a population of at least one, so an extinct colony cannot read secure.
The arc's `balance` diagnostics profile snapshots once a day
(`diagnostic_profile.gd::_default_snapshots`), not hourly, so on the arc
these values still fall on day boundaries until the scenario asks for an
hourly cadence (filed in WO-1, which already edits that scenario).

**Measured 30 Sep 2026** (product review, `docs/product-review-2026-09-30.md`):
first worker missing (target day 1.5), food secure day 4.0 (target 3.0),
winter entered missing (18.0), winter survived missing (27.0). Precision is
the smaller problem. `alpha_arc_test.json` sets no starting colony and no
actions, so the run is a lone, unplayed queen who starves at game time 589 s
and the log idles to day 36; nothing but the debug panel starts winter (WO-1,
`plans/now/winter-onset.md`); and a colony with no bees reads food secure,
because its winter requirement is 0 (PE-1 fixes that below). PE-2, outlined
under "Later", makes the arc a played colony.

**Probe 1 Oct 2026** (`python tools/pacing_gates.py --repeat 1`, 99 s wall
time): every gate reads `missing` against targets 1.50 / 3.00 / 18.00 /
27.00. The queen still starves alone and winter never starts, and food secure
no longer counts an empty hive. An earlier attempt timed out because the
worktree had no Godot import cache and `pacing_gates.py`, unlike
`run_scenario.py`'s entry point, did not seed one; it now does.

## Open slices at a glance

| Slice | Outcome | Files owned | Startable | Level |
| --- | --- | --- | --- | --- |

**Required reading.** PE-1's section below only.

PE-1 shipped 2026-10-01; its specification is `plans/archive/PE-1_2026-10-01.md`.

## Later, not yet specified

- **The 10-minute gate measures a proxy.** `pacing_gates.py` times "food
  secure" against §3's "first useful automation", which a headless run with no
  player cannot perform. Replacing the proxy needs a decision on what counts as
  automation in a scripted run.
- **The 20-minute crisis and the 90-minute gyne release are not instrumented**
  (`render_table`'s last line). Each waits for its feature: a readiness-aware
  forage/weather crisis, and Gyne rearing (`plans/design/progression.md`
  Phase C step 15).
- **PE-2 -- the arc is a played colony.** Specified by the Colony Run
  definition pass, because the arc's start is the Colony Run's start
  (`plans/design/product-scope.md` §6.2, "Next design pass"). What it must
  settle is listed there, so it survives this plan being archived after PE-1.
  `plans/now/gameplay-consistency.md` GC-3 (honey stops creating energy)
  waits for this arc as its before-and-after evidence.
