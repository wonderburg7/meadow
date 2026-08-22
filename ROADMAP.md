# Candidate features and improvements

Grouped by what they'd buy you. Each has a rough size and my honest view
of whether it's worth doing, because a list of everything possible isn't
much use on its own.

Sizes: **S** an evening, **M** a few sessions, **L** a substantial piece
of work.

Latest update, 22 Aug 2026 (evening) -- Dave's hands-on pass found that
several UI Plan slice-1-7 items don't actually work in-game, despite
`NEXTSTEPS.md` previously marking them built: text scale, font choice
and the dark/light theme toggle do nothing visible; panels lack the
intended background/frame/spacing; the settings window isn't split into
sections; the cell popup appears at the mouse instead of a fixed
position; the meadow/hive view button only half-responds to clicks; and
following a bee stops when it flies from hive to meadow (not the other
way). Root cause and an eight-slice fix plan, ordered for token
efficiency and tagged with a suggested model per slice, are in
`UI_BUGFIX_PLAN.md`. Treat "UI Plan slices 1-7 built" below as
unconfirmed until that plan lands. Confirmed working the same session:
bumble flight, the settings-window prerequisite cascades, and the
crab-spider predator behaviour.

Last updated: 22 Aug 2026 -- bumble flight built (see the "Depth in what
exists" row), waiting on Dave's hands-on check.

Later same day, 22 Aug 2026 -- added a row under "Depth in what exists"
for the foraging ecology overhaul (patchy meadow, local search,
probabilistic choice, species registry, proximity recruitment). Full
plan in `FORAGING_ECOLOGY_PLAN.md`, detail in `DESIGN_BACKLOG.md`
section 14. Slices 0-1 refined, nothing built.

Previous update, 20 Aug 2026 -- added a row below for the AI playtest
harness (Claude running its own headless, unattended scenarios to check
balance and behaviour, rather than every question needing Dave's own
hands-on play), now agreed and building, first slice in `NEXTSTEPS.md`.
Full design in `AI_PLAYTEST_PLAN.md`.

Previous update, 20 Aug 2026 -- the Predators row now points at a full
design, `CRAB_SPIDER_PLAN.md`. Not started.

Previous update, 19 Aug 2026 — added a row below for the diagnostic
logging system (post-run `.jsonl` files Claude can read back to help
diagnose deaths/imbalance), now fully planned in
`DIAGNOSTIC_LOGGING_PLAN.md`. Not started.

Previous update, 19 Aug 2026 — added a row below for the two-report technical
audit and its resulting `AUDIT_PLAN.md`, covering a confirmed state-leak
bug, save/restore determinism, fog-of-war performance, and Claude Code
context efficiency. Nothing in it is started yet.

Previous update, 19 Aug 2026 — the tutorial row now reads "built", not
"ready to build": Challenge 1 is playable end to end, after two rounds
of hands-on-testing fixes. See `TUTORIAL_PLAN.md` and `NEXTSTEPS.md`.

Previous update, 18 Aug 2026 — the tutorial row now points at
`TUTORIAL_PLAN.md`, a complete Challenge 1/2 design ready to build.

Previous update, 14 Aug 2026 (evening) — added rows for the hex-hive
redesign, the winter energy/lifespan fix, and the interface changes
from the same day's blueprint-then-implement pass
(`docs/archive/NEW_FEATURES_BLUEPRINT.md`).

Previous update, same day: a pass to mark what's shipped since this
was first written, after several items were found done while looking
for something else, plus the 4fps investigation closing out the same
day. See `docs/archive/PERF_PLAN.md` for that writeup.

---

## Performance and scale — resolved, see docs/archive/PERF_PLAN.md

**Was:** the frame rate dropped as low as 4fps with 29 bees, sustained,
in both views. **Found and fixed 14 Aug**, confirmed by Dave's
playtest at 60fps: `bee.gd::_grounded()` called itself instead of
checking rain (`if _grounded(): return true`, almost certainly lost in
a refactor), which recursed until GDScript's call stack errored out,
called from `_seek_flower` and `_go_to_exit` as their first line. Full
writeup, the `perf.gd` measuring method, and the Notion Performance
Map are in `docs/archive/PERF_PLAN.md`. That method — instrument the widest scope
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

## Technical audit findings — see AUDIT_PLAN.md

Two external audits (19 Aug) reviewed the whole repo against runtime
performance, maintainability, AI-agent context efficiency, and dead code.
Conclusion: no broad refactor needed, but a handful of concentrated
bundles are worth doing. Full detail, file lists, and validation steps in
`AUDIT_PLAN.md` — this row is a summary only, update status there, not here.

| | Size | Status |
|---|---|---|
| **Challenge 1's fast build time can leak into normal play/saves** — a global `GameConfig` write that's only restored on completion, not on abandon/restart | S | **Confirmed bug, not yet fixed.** `AUDIT_PLAN.md` Bundle A. |
| **Save/restore isn't deterministic** — flower/bee grid rebuilds can briefly see nodes just queued for deletion, because Godot defers `queue_free()` to end of frame | M | Not started. `AUDIT_PLAN.md` Bundle B. |
| **Fog-of-war performance is unmeasured since the 5-unit rework** — the file itself says so; static analysis suggests a real but unconfirmed cost at higher bee counts | S (measure) + M (fix if needed) | Not started, gated on measurement. `AUDIT_PLAN.md` Bundle C. |
| **Claude Code context restructure** — root `CLAUDE.md` is ~550 lines against guidance of ~200; move history/bug-catalogue to `docs/`, add path-scoped `.claude/rules/`, fix the `.claudeignore` claim | M | Not started, highest-leverage single item. `AUDIT_PLAN.md` Bundle D. |
| **Small housekeeping** — cache `Season` ref instead of a per-frame group lookup in `hive_cell.gd`; delete retired `egg.gd`/`queen.gd` | S | Done. `AUDIT_PLAN.md` Bundle E. |

## Diagnostic logging — see DIAGNOSTIC_LOGGING_PLAN.md

Post-run `.jsonl` files (one per run, last 5 kept) capturing a config
snapshot, every death, hourly population/resource/cell snapshots, and
a session summary — so Dave can hand Claude a file after a playtest and
get back correlated findings (e.g. "foragers keep dying shortly after a
long trip") instead of just a population number going down. Fully
planned against the actual code (death-cause tracking doesn't exist yet
and needs a small fix first; no hive-temperature or weather-string
systems exist yet, so those spec fields are substituted with what the
game actually tracks). Full detail in `DIAGNOSTIC_LOGGING_PLAN.md` —
update status there, not here.

| | Size | Status |
|---|---|---|
| **Diagnostic logging system** — `DiagnosticLog` autoload, death-cause fix in `bee_survival.gd`, hourly snapshots, session summary | S/M | **Done.** Built and confirmed by Dave 19 Aug, reading a real `session_*.jsonl` back after a playtest. `DIAGNOSTIC_LOGGING_PLAN.md`. |

## AI playtest harness — see AI_PLAYTEST_PLAN.md

Grew out of Dave asking whether Claude could "play the game" itself to
gather insight and check things are working as intended, including
choosing its own bespoke test scenarios. `DiagnosticLog` and `levels.gd`
already cover two of the three pieces a real answer needs; the missing
one is a way to drive an unattended run and turn its output into a
verdict rather than a human reading raw JSON. Design: a `--scenario=`
boot argument (skips the main menu, applies a `levels.gd`-shaped starting
state plus a small `GameConfig`-allowlisted override, auto-quits via
`DiagnosticLog.end_session()` on queen death or a day limit), run
headless and faster than the player-facing 8x speed cap, plus a
`tools/run_scenario.py` that launches it, waits, and parses the log into
population curves, deaths, and whether specific mechanics actually
fired. Explicitly not attempting real input injection or literal screen
control — the installed Godot MCP server doesn't support it and it's a
much bigger lift for a narrower payoff than the headless route. Full
detail in `AI_PLAYTEST_PLAN.md` — update status there, not here.

| | Size | Status |
|---|---|---|
| **Headless scenario boot path** — `--scenario=` arg, `levels.gd`-shaped starting state, auto-quit via `DiagnosticLog` | S | **Agreed 20 Aug 2026, building.** First slice, see `NEXTSTEPS.md`. `AI_PLAYTEST_PLAN.md`. |
| **Config-override block + allowlist check** | S | Not started, second slice. |
| **Time_scale past the 8x player cap** — needs testing for steering/physics artifacts first | S | Not started, third slice. |
| **`tools/run_scenario.py`** — headless launch, wait, parse the log | S | Not started, fourth slice. |
| **N-repeat batch mode + richer analysis** (population curves, mechanic-firing checks) | M | Not started, fifth slice. |

## Making the middle game interesting

| | Size | Status |
|---|---|---|
| **Winter proper** — foraging stops, stores burn, bees die if it runs out, survivors emerge in spring | M | **Shipped 13 Aug.** `season.gd` |
| **Gynes leaving and scoring** — gynes fly off at season's end and are the score | M | **Shipped 13 Aug.** Supersedes the old "day 90 resource score" win condition. |
| **Disease and parasites** — an uncleaned hive gets sick; clearing becomes preventative | M | **Shipped 13 Aug.** Corpses and crowding drive it; four balance numbers had to be retuned after simulating (see Decisions Log). |
| **Forage seasonality** — species come into flower at different times | M | **Shipped 13 Aug.** `Flower.SPECIES`, `season_strength()`. |
| **Predators** — something that eats foragers in the meadow | M | Not built. **Full design done 20 Aug** -- crab spiders, an ambush predator, ready to build against the code as it stands. See `CRAB_SPIDER_PLAN.md` and `DESIGN_BACKLOG.md` §7.3. |
| **A second hive site to move to** | L | Not built. Deferred on purpose (13 Aug decision). |
| **Winter energy/lifespan bug fix** — bees now actually burn less and live longer through winter, matching what the forecast display already claimed | S | **Shipped 14 Aug.** `bee_survival.gd::age_and_burn` was missing `winter_burn_factor` entirely; new `GameConfig.winter_lifespan_factor` (4.0x, not yet fully modelled — see `DESIGN_BACKLOG.md` §9) applied in `season.gd::lifespan_factor()`. |

## Hive geometry

| | Size | Status |
|---|---|---|
| **Flat-top hex hive + single-column corner entrance** — comb/soil/rock hexagons flipped from pointy-top to flat-top, entrance moved to a top corner as one tile wide instead of the old "1, 2, 1, 2" pattern | M | **Shipped 14 Aug.** Confined almost entirely to `shapes.gd`; save format bumped to `FORMAT_VERSION 2`. See `docs/archive/NEW_FEATURES_BLUEPRINT.md`. |

## Depth in what exists

Nothing in this section is built yet. All deferred on purpose on 13 Aug,
alongside the tutorial, so the systems already in could stabilise first.

| | Size | Worth it? |
|---|---|---|
| **Nurse-mediated caste switching** — what a larva becomes is set by feeding, not by the cell | M | Yes, as a later-level unlock. Changes how an existing system works rather than adding a new one. |
| **Comb temperature** — brood develops faster in a warm cluster; bees fan or huddle | M | Strong. Comb layout barely matters right now. |
| **Bee individuality** — small variation in speed/capacity, a generated name and fact, gynes carry it forward | S | Cheap, adds texture. Detailed and ready to build, see `docs/archive/BEE_INDIVIDUALITY_PLAN.md`. |
| **Foraging memory / recruitment** — a bee that found a good patch returns and recruits others | M | **Built 17 Aug** as a combined scouting/floral-constancy/recruitment mechanism (`GameConfig.auto_foraging_on`), still unconfirmed against a real playtest and still not measured against the baseline per rule 4. **Being split 18 Aug** into three independent toggles — see `docs/archive/SCOUTING_TOGGLE_PLAN.md`, ready to build. |
| **Cell depth / multi-storey comb** | L | No. Doubles the UI problem for little gain. |
| **Bumble flight** — outdoor flying bees drift on a small wander instead of beelining, so movement reads as bee-like | S | **Built 22 Aug 2026**, waiting on Dave's hands-on check. A two-sine Lissajous offset on a new `visual_root` child node (not `bee.position`), so arrival checks, obstacle steering and the stall watchdog are untouched. `bee_movement.gd::move_towards`'s outdoor branch sets `bee.flying_outdoors = true`; `bee.gd::_update_wander_flight()` (called from `_process`, same on-screen-gated pattern as `_update_label`/`_update_alarm_ring`) reads that flag and skips the `sin()` calls entirely off screen or indoors. Toggle plus amplitude/frequency under debug panel's "Bee life" (`GameConfig.bumble_flight_on`, on by default). |
| **Foraging ecology overhaul** — patchy meadow, local perception + expanding-loop search, probabilistic flower choice, species registry, proximity recruitment | L | Worth doing -- foraging is the most-played-with system and currently uses omniscient nearest-flower choice on a near-uniform meadow. **Proposed 22 Aug 2026, ten slices, only Slices 0-1 refined so far.** See `FORAGING_ECOLOGY_PLAN.md` and `DESIGN_BACKLOG.md` §14. Not started. |

## Interface

**A full interface redesign is now planned (not built)** — warm/cosy
honeycomb visual language, theming and accessibility (text scale,
typefaces, reduced motion), a configurable selection/command tray
layout, a scenario-preset system, and a skill-tree framework. See
`UI_PLAN.md` for the full spec and its nine-slice build sequence. The
skill-tree framework's catalogue, Colony Adaptations and campaign meta
progression now have a full reconciled design of their own —
`SKILL_TREE_PLAN.md` (22 Aug 2026), not started. Everything below this
line is what has actually shipped so far, under the interface as it
currently looks.

| | Size | Status |
|---|---|---|
| **A "why is this bee idle?" answer** | S | **Shipped 13 Aug.** `idle_reason()` in `bee.gd`. |
| **Alerts you can click through to** — problem strip lines select what they're about | S | **Shipped 13 Aug.** `signal_clicked` in `hud.gd`. |
| **Saved selections / control groups** (Ctrl+1–9) | S | **Shipped 13 Aug.** |
| **Comb overlay modes** — colour the whole comb by contents, fill, age, assignment | M | **Shipped 13 Aug.** Press O to cycle; `_cycle_comb_overlay()` in `main.gd`. |
| **Undo for cell designation** (Ctrl+Z) | S | **Shipped 13 Aug.** |
| **Zoom-to-fit** (F) | S | **Shipped 13 Aug.** |
| **A frame rate readout** — average, last frame, worst frame in the window | S | **Shipped 14 Aug**, starred like the colony window's stats. The frame-time plot and per-section breakdown (`perf.gd`) shipped the same day and are a permanent fixture now, not a one-off — see `CLAUDE.md`. |
| **A tutorial or first-run guidance** | M | **Challenge 1 built and playable, 19 Aug.** Both prerequisites from `DESIGN_BACKLOG.md` §1/§5 (the `levels.gd` restructure, the tutorial checkpoint system) are done, plus the new machinery `TUTORIAL_PLAN.md` called for: `stage_gate.gd` (UI unlock/lock), `gallerin_panel.gd` (the mentor popup), `challenge_runner.gd` (the seven sub-stages). Two rounds of hands-on-testing fixes landed the same day — a real navigation off-by-one that let bees wander outside the hive's rock wall, a forager defaulting to the wrong resource, a load-destroying deposit bug, and others; see `NEXTSTEPS.md` for the full list. Challenge 2 has no stage data yet — same menu entry, still a plain level preset underneath. |
| **Rebindable keys and a settings screen** | S | Not built. |
| **Settings window (cog icon)** — replaced the "Tuning ▾" text button; called "the settings window" from here on | S | **Shipped 14 Aug.** `debug_panel.gd`. |
| **Dynamic top-right button layout** — the speed/Colony/Nursery/Winter/Hive row now positions itself off the settings cog's actual measured width instead of a hardcoded constant, so a future font-size setting won't silently break it | S | **Shipped 14 Aug.** `hud.gd::set_settings_button_width`, driven by the cog button's `resized` signal in `debug_panel.gd`. |
| **Per-bee "work from here" scoping + all-comb-workers button** — was accidentally moving the whole selection; now targets one bee, with an explicit button for the old broadcast behaviour | S | **Shipped 14 Aug.** `hud.gd`, `input_selection.gd`. |
| **Home-cell marker** — shows a selected builder/miner's assigned cell | S | **Shipped 14 Aug.** |
| **Build-here hover border** — outlines a clear, buildable hex under the mouse while placing a build order | S | **Shipped 14 Aug.** |

## Structural work (see LANGUAGE_REVIEW.md for detail)

| | Size | Status |
|---|---|---|
| **One `roles.gd` instead of role constants in four files** | S | **Shipped 13 Aug.** |
| **Split `GameConfig` into balance vs session state** | S | **Shipped 13 Aug.** `session.gd`. |
| **Save the things that currently aren't** (keep-clear tiles, build/mine queues, restocking orders, priority credit) | S | **Shipped 13 Aug.** |
| **Break up `main.gd`** (world building, input/selection, saving, orders/zones, the year/winter, camera) | M | **Shipped 14 Aug, confirmed working 14 Aug** ("Seems to be working ok"). Six new files, each a plain Node created in `_ready()` and reached as `main.world_building` etc. `main.gd` still holds every field and every method something outside the split touches (`bee.gd`, `debug_panel.gd`) — see `docs/archive/MAIN_SPLIT_PLAN.md`. Passes `source_checks.py` and `balance_tests.py`. Two follow-up fixes needed once it actually ran: a `:=` type-inference failure across loosely-typed refs, and a `_build_cameras()` ordering bug — both documented in `docs/archive/MAIN_SPLIT_PLAN.md`'s sibling notes so the `bee.gd` split avoids repeating them. |
| **Break up `bee.gd`** (3,162 lines — survival/eating, foraging, nursery/jelly, building, mining, honey, egg laying, movement, plus a shared `bee_enums.gd`) | M | **Shipped and confirmed working 14 Aug** ("seems to work as intended"). Full plan in `docs/archive/BEE_SPLIT_PLAN.md`. All nine files split out: `bee_enums.gd`, `bee_movement.gd`, `bee_survival.gd`, `bee_foraging.gd`, `bee_nursery.gd`, `bee_building.gd`, `bee_mining.gd`, `bee_honey.gd`, `bee_egg_laying.gd`, plus `bee_status.gd` (a small leaf the plan didn't anticipate — `grounded`/`works_indoors`, needed from both bee_survival and bee_foraging, would otherwise have made the two preload each other). `bee.gd` is 3,138 → 1,399 lines. `source_checks.py`/`balance_tests.py` pass. Still outstanding: `bee_movement.gd` (the hottest path — steering, obstacle avoidance) hasn't been specifically re-measured with `perf.gd` against a decent-sized colony (~29 bees) since the static-call pattern went in. |
| **Automated tests for the balance rules** | M | **Shipped 13 Aug.** `tests/balance_tests.py`, extended to `tests/source_checks.py` on the same day after the balance suite didn't catch a syntax error that blanked the game. |

---

## If I had to pick five (14 Aug: all five now shipped)

1. ~~Update budgeting~~ — shipped 13 Aug
2. ~~One `roles.gd`~~ — shipped 13 Aug
3. ~~Winter proper~~ — shipped 13 Aug
4. ~~Forage seasonality~~ — shipped 13 Aug
5. ~~"Why is this bee idle?"~~ — shipped 13 Aug

**Picking five again, 14 Aug:**

1. ~~Resolve the 4fps drop~~ — **fixed and confirmed 14 Aug**, `docs/archive/PERF_PLAN.md`. `_grounded()` recursion; see the bug class in `CLAUDE.md`.
2. ~~Break up `main.gd`~~ — shipped and confirmed working 14 Aug.
2a. **Break up `bee.gd`** — done and confirmed working 14 Aug (`docs/archive/BEE_SPLIT_PLAN.md`), all nine files plus `bee_status.gd` split out. Still worth re-measuring `bee_movement.gd` with `perf.gd` before trusting the static-call pattern is free on the hottest path.
3. **Foraging memory** — the most-requested-feeling gap in what's built; cheap relative to its payoff.
4. **A tutorial** — named as next on 13 Aug, plan complete 18 Aug (`TUTORIAL_PLAN.md`). **Challenge 1 built and playable, 19 Aug** — see `NEXTSTEPS.md` for what's still open (Challenge 2's stage data, and Dave's hands-on confirmation of the latest fixes).
5. **Comb temperature** — the deepest of the "depth in what exists" items and the one that would make comb layout an actual decision.
