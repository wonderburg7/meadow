# Candidate features and improvements

Grouped by what they'd buy you. Each has a rough size and my honest view
of whether it's worth doing, because a list of everything possible isn't
much use on its own.

Sizes: **S** an evening, **M** a few sessions, **L** a substantial piece
of work.

Last updated: 14 Aug 2026 — a pass to mark what's shipped since this was
first written, after several items were found done while looking for
something else. See `PERF_PLAN.md` for the active investigation.

---

## Performance and scale — active investigation, see PERF_PLAN.md

The frame rate drops as low as 4fps with only 29 bees. That is not
explained by anything below; it means one thing is costing roughly
250ms in a single frame, and it hasn't been found yet. `PERF_PLAN.md`
in the repo root has the plan: build a `perf.gd` timing autoload and a
frame-time plot, measure rather than guess, then fix. Read that file
before starting on anything performance-related — this table is the
history, not the live plan.

| | Size | Status |
|---|---|---|
| **Update budgeting** — bees think a few times a second rather than every frame, keeping only movement per-frame | M | **Shipped 13 Aug.** `THINKS_PER_SECOND` in `bee.gd` |
| **Spatial grid for flowers** — bucket the meadow so "nearest flower" checks a handful of candidates instead of all 250 | M | **Shipped 13 Aug.** Kept. |
| **Spatial grid for obstacles** — same idea, applied to the 14 obstacles | M | **Shipped 13 Aug, reverted 14 Aug.** Wrong call: 14 objects asked 60 times a second per bee lost to the scan it replaced — the grid's own bucket-lookup and allocation cost more than iterating 14 items. See the Decisions Log entry and the "optimising a set too small to need it" bug class in `CLAUDE.md`. |
| **Stop drawing what isn't on screen** — bees, cells and flowers outside the camera skip label/colour updates | S | **Shipped.** Bees 13 Aug (`is_on_screen`); cells and flowers throttled to 6/sec and skipped off-screen entirely on 14 Aug, which turned out to be the bigger of the two real jitter causes that day. |
| **Pool the death markers and rain streaks** | S | Not done. Rain is already pooled; death markers not profiled as worth it yet. |
| **Move the hive's A\* to a coarser graph** | L | Not yet. Currently the leading suspect for the 4fps drop — see `PERF_PLAN.md` suspect #1. |

**The measurement this file used to say was worth taking first, still is:** `PERF_PLAN.md` is that measurement, now underway.

## Making the middle game interesting

| | Size | Status |
|---|---|---|
| **Winter proper** — foraging stops, stores burn, bees die if it runs out, survivors emerge in spring | M | **Shipped 13 Aug.** `season.gd` |
| **Gynes leaving and scoring** — gynes fly off at season's end and are the score | M | **Shipped 13 Aug.** Supersedes the old "day 90 resource score" win condition. |
| **Disease and parasites** — an uncleaned hive gets sick; clearing becomes preventative | M | **Shipped 13 Aug.** Corpses and crowding drive it; four balance numbers had to be retuned after simulating (see Decisions Log). |
| **Forage seasonality** — species come into flower at different times | M | **Shipped 13 Aug.** `Flower.SPECIES`, `season_strength()`. |
| **Predators** — something that eats foragers in the meadow | M | Not built. Still an open question whether it adds pressure or just noise, given the colony already has disease, winter and a rival hive. |
| **A second hive site to move to** | L | Not built. Deferred on purpose (13 Aug decision). |

## Depth in what exists

Nothing in this section is built yet. All deferred on purpose on 13 Aug,
alongside the tutorial, so the systems already in could stabilise first.

| | Size | Worth it? |
|---|---|---|
| **Nurse-mediated caste switching** — what a larva becomes is set by feeding, not by the cell | M | Yes, as a later-level unlock. Changes how an existing system works rather than adding a new one. |
| **Comb temperature** — brood develops faster in a warm cluster; bees fan or huddle | M | Strong. Comb layout barely matters right now. |
| **Bee individuality** — small inherited variation in speed, capacity, lifespan; gynes carry it forward | S | Cheap, adds texture. |
| **Foraging memory** — a bee that found a good patch returns and recruits others | M | Yes. The most famous thing bees do and the game doesn't have it. |
| **Cell depth / multi-storey comb** | L | No. Doubles the UI problem for little gain. |

## Interface

| | Size | Status |
|---|---|---|
| **A "why is this bee idle?" answer** | S | **Shipped 13 Aug.** `idle_reason()` in `bee.gd`. |
| **Alerts you can click through to** — problem strip lines select what they're about | S | **Shipped 13 Aug.** `signal_clicked` in `hud.gd`. |
| **Saved selections / control groups** (Ctrl+1–9) | S | **Shipped 13 Aug.** |
| **Comb overlay modes** — colour the whole comb by contents, fill, age, assignment | M | **Shipped 13 Aug.** Press O to cycle; `_cycle_comb_overlay()` in `main.gd`. |
| **Undo for cell designation** (Ctrl+Z) | S | **Shipped 13 Aug.** |
| **Zoom-to-fit** (F) | S | **Shipped 13 Aug.** |
| **A frame rate readout** — average, last frame, worst frame in the window | S | **Shipped 14 Aug**, starred like the colony window's stats. A frame-time plot is in progress, see `PERF_PLAN.md`. |
| **A tutorial or first-run guidance** | M | Not built. Named as the next interface thing on 13 Aug, still outstanding. |
| **Rebindable keys and a settings screen** | S | Not built. |

## Structural work (see LANGUAGE_REVIEW.md for detail)

| | Size | Status |
|---|---|---|
| **One `roles.gd` instead of role constants in four files** | S | **Shipped 13 Aug.** |
| **Split `GameConfig` into balance vs session state** | S | **Shipped 13 Aug.** `session.gd`. |
| **Save the things that currently aren't** (keep-clear tiles, build/mine queues, restocking orders, priority credit) | S | **Shipped 13 Aug.** |
| **Break up `main.gd`** (world building, input/selection, saving, orders/zones, the year/winter, camera) | M | **Agreed, not started.** Six-file split agreed with Dave 14 Aug, held until the frame-rate investigation in `PERF_PLAN.md` is resolved, so any breakage stays attributable to one change at a time. `bee.gd` (3,098 lines, the larger file) queued behind it. |
| **Automated tests for the balance rules** | M | **Shipped 13 Aug.** `tests/balance_tests.py`, extended to `tests/source_checks.py` on the same day after the balance suite didn't catch a syntax error that blanked the game. |

---

## If I had to pick five (14 Aug: all five now shipped)

1. ~~Update budgeting~~ — shipped 13 Aug
2. ~~One `roles.gd`~~ — shipped 13 Aug
3. ~~Winter proper~~ — shipped 13 Aug
4. ~~Forage seasonality~~ — shipped 13 Aug
5. ~~"Why is this bee idle?"~~ — shipped 13 Aug

**Picking five again, 14 Aug:**

1. **Resolve the 4fps drop** — `PERF_PLAN.md`. Nothing else matters much until a 29-bee colony is playable.
2. **Break up `main.gd`** — agreed, waiting on #1 so the two changes aren't tangled together.
3. **Foraging memory** — the most-requested-feeling gap in what's built; cheap relative to its payoff.
4. **A tutorial** — named as next on 13 Aug, still outstanding, and the game has grown a lot of surface area since it was last considered.
5. **Comb temperature** — the deepest of the "depth in what exists" items and the one that would make comb layout an actual decision.
