# Candidate features and improvements

Grouped by what they'd buy you. Each has a rough size and my honest view
of whether it's worth doing, because a list of everything possible isn't
much use on its own.

Sizes: **S** an evening, **M** a few sessions, **L** a substantial piece
of work.

Last updated: 14 Aug 2026 — a pass to mark what's shipped since this was
first written, after several items were found done while looking for
something else, plus the 4fps investigation closing out the same day.
See `PERF_PLAN.md` for that writeup.

---

## Performance and scale — resolved, see PERF_PLAN.md

**Was:** the frame rate dropped as low as 4fps with 29 bees, sustained,
in both views. **Found and fixed 14 Aug**, confirmed by Dave's
playtest at 60fps: `bee.gd::_grounded()` called itself instead of
checking rain (`if _grounded(): return true`, almost certainly lost in
a refactor), which recursed until GDScript's call stack errored out,
called from `_seek_flower` and `_go_to_exit` as their first line. Full
writeup, the `perf.gd` measuring method, and the Notion Performance
Map are in `PERF_PLAN.md`. That method — instrument the widest scope
first, then split by whatever dimension could explain the cost one
playtest at a time — is now documented in `CLAUDE.md` for the next
performance question, rather than being specific to this one.

**A\* pathfinding, the original leading suspect, was cleared** — it
measured at ~0ms throughout thanks to the existing tile-pair cache in
`path_between`. Moving it to a coarser graph is not needed.

| | Size | Status |
|---|---|---|
| **Update budgeting** — bees think a few times a second rather than every frame, keeping only movement per-frame | M | **Shipped 13 Aug.** `THINKS_PER_SECOND` in `bee.gd` |
| **Spatial grid for flowers** — bucket the meadow so "nearest flower" checks a handful of candidates instead of all 250 | M | **Shipped 13 Aug.** Kept. |
| **Spatial grid for obstacles** — same idea, applied to the 14 obstacles | M | **Shipped 13 Aug, reverted 14 Aug.** Wrong call: 14 objects asked 60 times a second per bee lost to the scan it replaced — the grid's own bucket-lookup and allocation cost more than iterating 14 items. See the Decisions Log entry and the "optimising a set too small to need it" bug class in `CLAUDE.md`. |
| **Stop drawing what isn't on screen** — bees, cells and flowers outside the camera skip label/colour updates | S | **Shipped.** Bees 13 Aug (`is_on_screen`); cells and flowers throttled to 6/sec and skipped off-screen entirely on 14 Aug, which turned out to be the bigger of the two real jitter causes that day. |
| **Pool the death markers and rain streaks** | S | Not done. Rain is already pooled; death markers not profiled as worth it yet. |
| **Move the hive's A\* to a coarser graph** | L | **Not needed.** Cleared as a suspect 14 Aug — `bee_path` measured ~0ms throughout the investigation. |
| **The `_grounded()` recursion bug** | — | **Fixed 14 Aug**, commit `6488415`. Was the entire cause of the 4fps drop. |

**A permanent fixture now, not a one-off measurement:** `perf.gd` and
the fps-starred breakdown stay in the project. Give any new hot
per-frame system its own `Perf.begin`/`Perf.end` pair — see `CLAUDE.md`.

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
| **A frame rate readout** — average, last frame, worst frame in the window | S | **Shipped 14 Aug**, starred like the colony window's stats. The frame-time plot and per-section breakdown (`perf.gd`) shipped the same day and are a permanent fixture now, not a one-off — see `CLAUDE.md`. |
| **A tutorial or first-run guidance** | M | Not built. Named as the next interface thing on 13 Aug, still outstanding. |
| **Rebindable keys and a settings screen** | S | Not built. |

## Structural work (see LANGUAGE_REVIEW.md for detail)

| | Size | Status |
|---|---|---|
| **One `roles.gd` instead of role constants in four files** | S | **Shipped 13 Aug.** |
| **Split `GameConfig` into balance vs session state** | S | **Shipped 13 Aug.** `session.gd`. |
| **Save the things that currently aren't** (keep-clear tiles, build/mine queues, restocking orders, priority credit) | S | **Shipped 13 Aug.** |
| **Break up `main.gd`** (world building, input/selection, saving, orders/zones, the year/winter, camera) | M | **Shipped 14 Aug, confirmed working 14 Aug** ("Seems to be working ok"). Six new files, each a plain Node created in `_ready()` and reached as `main.world_building` etc. `main.gd` still holds every field and every method something outside the split touches (`bee.gd`, `debug_panel.gd`) — see `MAIN_SPLIT_PLAN.md`. Passes `source_checks.py` and `balance_tests.py`. Two follow-up fixes needed once it actually ran: a `:=` type-inference failure across loosely-typed refs, and a `_build_cameras()` ordering bug — both documented in `MAIN_SPLIT_PLAN.md`'s sibling notes so the `bee.gd` split avoids repeating them. |
| **Break up `bee.gd`** (3,162 lines — survival/eating, foraging, nursery/jelly, building, mining, honey, egg laying, movement, plus a shared `bee_enums.gd`) | M | **In progress 14 Aug.** Full plan in `BEE_SPLIT_PLAN.md`. `bee_enums.gd` (Role/State/ROLE_PERF_SECTIONS, a leaf file, no circular preload) and `bee_movement.gd` (steering and obstacle avoidance, the hottest path in the file) are both split out and passing `source_checks.py`/`balance_tests.py`. Neither has been run in Godot yet — needs Dave's hands-on check, and `bee_movement.gd` specifically is worth re-measuring with `perf.gd` against a decent-sized colony before trusting the static-call pattern is free there. Five role-specific files remain: `bee_survival`, `bee_foraging`, `bee_nursery`, `bee_building`, `bee_mining`, `bee_honey`, `bee_egg_laying` (foraging first is the plan's suggested next pick, easiest to playtest in isolation). |
| **Automated tests for the balance rules** | M | **Shipped 13 Aug.** `tests/balance_tests.py`, extended to `tests/source_checks.py` on the same day after the balance suite didn't catch a syntax error that blanked the game. |

---

## If I had to pick five (14 Aug: all five now shipped)

1. ~~Update budgeting~~ — shipped 13 Aug
2. ~~One `roles.gd`~~ — shipped 13 Aug
3. ~~Winter proper~~ — shipped 13 Aug
4. ~~Forage seasonality~~ — shipped 13 Aug
5. ~~"Why is this bee idle?"~~ — shipped 13 Aug

**Picking five again, 14 Aug:**

1. ~~Resolve the 4fps drop~~ — **fixed and confirmed 14 Aug**, `PERF_PLAN.md`. `_grounded()` recursion; see the bug class in `CLAUDE.md`.
2. ~~Break up `main.gd`~~ — shipped and confirmed working 14 Aug.
2a. **Break up `bee.gd`** — plan approved 14 Aug (`BEE_SPLIT_PLAN.md`). `bee_enums.gd` and `bee_movement.gd` split out and tests passing, not yet played. Five role-specific files left (foraging suggested next); needs Dave's hands-on check on what's already split before more moves.
3. **Foraging memory** — the most-requested-feeling gap in what's built; cheap relative to its payoff.
4. **A tutorial** — named as next on 13 Aug, still outstanding, and the game has grown a lot of surface area since it was last considered.
5. **Comb temperature** — the deepest of the "depth in what exists" items and the one that would make comb layout an actual decision.
