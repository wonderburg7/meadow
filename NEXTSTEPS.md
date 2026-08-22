# Next steps

Read this first in a new session, before anything else in CLAUDE.md. This
file holds only the next 1-3 concrete actions -- it is rewritten (not
appended to) at the end of every build session, so it should never grow
into a history. Full history lives in `git log`.

## Next up

1. **UI Plan slices 1-7 and 9 are built** (`UI_PLAN.md` section 15).
   Slices 1-7 are as before -- see `git log` for the slice-by-slice
   detail, or the previous version of this file for slice 7's full
   description (the Challenge-completion screen).
   **Slice 9** (22 Aug) is the verification pass -- ran both check
   suites and a `mcp__godot__` boot (clean, only pre-existing warnings),
   regenerated a stale `FUNCTION_MAP.md`, and added the seven missing
   accessibility keys (`ui_theme`, `text_scale`, `ui_typeface`,
   `reduced_motion`, `screen_shake`, `tooltip_delay`,
   `show_info_badges`) to `stage_gate.gd::ACCESSIBILITY_KEYS`, which
   section 10 already specified but slice 1 never actually added.
   **The pass surfaced one real, unfixed gap, not just a checklist
   pass:** the slice-1b Theme/text-scale migration only ever reached
   `colony_panel.gd`, `nursery_panel.gd`, `main_menu.gd`,
   `winter_panel.gd`, `challenge_complete.gd` and `ui.gd`. `hud.gd` --
   the file slices 2 and 3 both built, and the single biggest source of
   on-screen UI text -- still has all 50 of its original
   `add_theme_font_size_override` calls and none converted to
   `theme_type_variation`; `debug_panel.gd` (8 calls), `game_over.gd`
   (3) and `gallerin_panel.gd` (1) are the same. **This means
   `Session.text_scale` at 200% does nothing to the top-right controls,
   goal shelf, selection tray, command tray or settings window today**
   -- most of what's actually on screen during play. See `UI_PLAN.md`
   slice 9's writeup for the full detail, including one more thing that
   needs Dave's own eyes rather than more reading (whether a `Button`
   using a `Label`-registered type variation actually picks up the
   scaled font size at all -- untestable without running the game).
   **Next concrete action:** finish the slice-1b migration for `hud.gd`
   and `debug_panel.gd` (the two files that matter most -- `game_over.gd`
   and `gallerin_panel.gd` are much smaller and can follow). This is
   real build work, not another verification pass -- worth treating as
   its own slice.
   Everything visual/behavioural from slices 1-7 (rendering at each
   resolution/theme/scale, the narrow-window reflow, the bottom-row
   grows-taller rule, the Challenge-completion screen's actual play
   test) is still only checked as far as source-reading and a clean
   boot can confirm -- all of it still needs Dave's hands-on pass; see
   `git log` for the per-slice hands-on-check lists, all still open.
   Slice 8 (the skill tree) stays superseded by `SKILL_TREE_PLAN.md`'s
   own build sequence.
2. **Game model slices 1-4 are built** (`DESIGN_BACKLOG.md` section 13).
   **Not yet hands-on checked** -- slice 3's prerequisite cascade only
   fires from the settings-window checkboxes, which nothing automated
   here drives: open Settings, toggle Orientation flight / Auto scouting
   / Floral constancy / Auto-recruitment on and off and confirm the
   cascade still walks correctly both ways, and the same for
   Predators / Crab-spider suppression / Alarm pheromone.
   The forager-history save gap (trip-history state like
   `avg_collection_rate`, `trips_scored`, `scout_*` fields and
   `hive.entrance_mentors` isn't in `save_game.gd`'s per-bee block) is
   still unactioned -- ask Dave whether it's worth its own slice.
3. **Bumble flight is built** -- outdoor flying bees drift on a small
   two-sine wander instead of beelining, eased in/out so landing and
   taking off read as smooth. Toggle + tuning in the debug panel under
   "Bee life" (`GameConfig.bumble_flight_on`). **Not yet hands-on
   played** -- load the game, watch outdoor foragers fly, confirm the
   wander reads as bee-like.
4. **Recruitment competition fix and the crab-spider second-round
   fixes are both still waiting on Dave's hands-on re-check** -- see
   `git log` (commit `103d716`) and `CRAB_SPIDER_PLAN.md`'s 20 Aug
   "Confirmed" entry respectively.
5. **AI playtest harness is built through slice 7** (the headless action
   driver). All of slices 1-7 still await review -- see `git log` for
   the slice-by-slice detail.
6. **A foraging ecology overhaul is proposed, slices 0-1 refined**
   (`FORAGING_ECOLOGY_PLAN.md`, `DESIGN_BACKLOG.md` section 14). Slice 0
   (seed the meadow layout per scenario) is the next concrete action for
   that plan once the hands-on-check backlog above has room.
7. **`CHATGPT_INSIGHTS_PLAN.md` -- C1 through C5 built, 22 Aug.** C1 fixed
   `_try_role_work`'s nurse dispatch in [bee.gd](scripts/bee.gd:1027)
   (the plan named `bee_nursery.gd`, but the actual match-statement
   dispatch lives in `bee.gd`) -- Anything-mode nurses now check for
   hungry brood before falling back to jelly work, instead of trying
   jelly first and starving larvae almost like Jelly mode does. C2
   stopped jelly spilling into undesignated comb: added
   [hive.gd](scripts/hive.gd:227) `find_designated_cell_for`, which
   mirrors `find_cell_for` but never falls back to an ordinary empty
   cell, and a `jelly_storage_cell` helper in
   [bee_nursery.gd](scripts/bee_nursery.gd:161) that both
   `can_make_jelly` and `nurse_go_to_jelly_cell` now call -- with no
   gyne brood pending, jelly can only be made or stored in a cell the
   player has explicitly designated for it; a pending gyne need still
   overrides this and can use any cell, same as before. C3 made honey
   fanning stack: replaced [hive_cell.gd](scripts/hive_cell.gd)'s
   `being_fanned` boolean (every fanner set the same flag, so the cell
   only ever advanced by one `delta` a frame) with an
   `add_fanning_progress(delta)` call, mirroring the existing
   `add_build_progress` pattern -- [bee_honey.gd](scripts/bee_honey.gd)'s
   `honey_fan` now calls it once per fanning bee each frame, so several
   fanners genuinely add up instead of duplicating one bee's contribution.
   `source_checks.py`, `balance_tests.py`, `FUNCTION_MAP.md` regeneration
   and a `mcp__godot__` boot (clean, only pre-existing warnings) all pass.
   C4 fixed the Stocking hatch fallback: [world_building.gd:412](scripts/world_building.gd:412)'s
   `_spawn_hatched_bee` only accepted `["build", "maintain", "both"]` as a
   valid `architect_mode`, so a nursery cell configured to hatch a Stocking
   worker silently hatched an Anything comb worker instead -- `"restock"`
   is now in the accepted list, matching the mode `orders_zones.gd` already
   sets when a player manually assigns Stocking. **One open question for
   Dave, not decided here:** `orders_zones.gd`'s
   `architect_mode != "build"` condition already lets Stocking-mode comb
   workers do maintenance work (clearing dead larvae, evicting redesignated
   cells) ahead of restocking -- is that wanted, or should Stocking be
   restock-only?
   **Still open:** C2's headless run with no jelly cell marked, and
   C4's hatch test confirming a Stocking-configured cell produces a
   Stocking worker.
   C5 (role outcome telemetry, 22 Aug) added ten cumulative counters --
   brood feeds, jelly batches, larval deaths, cells completed/cleaned/
   evicted/restocked, blocks mined, honey batches deposited, cells
   ripened -- to [diagnostic_log.gd](scripts/diagnostic_log.gd)'s
   summary line, plus a live `role_outcomes` snapshot section (the same
   ten as running totals, plus a live exposed/marked soil-block count
   read off the `soil_blocks` group). Bumped from the actual completion
   point in [bee_nursery.gd](scripts/bee_nursery.gd) (feed_brood,
   nurse_make_jelly), [hive_cell.gd](scripts/hive_cell.gd) (_larva_dies,
   add_build_progress, take_resource's eviction-drain branch,
   add_fanning_progress's ripen-transition check),
   [bee_building.gd](scripts/bee_building.gd) (architect_clean,
   restock_go_to_target), [bee_honey.gd](scripts/bee_honey.gd)
   (honey_deposit) and [bee_mining.gd](scripts/bee_mining.gd)
   (miner_dig) -- additive only, no new log file or format.
   `source_checks.py`, `balance_tests.py`, `FUNCTION_MAP.md`
   regeneration and a `mcp__godot__` boot (clean, only the same
   pre-existing warnings as before) all pass. **Verified with an actual
   headless run** (`tools/run_scenario.py test_scenarios/slice1_smoke_test.json`):
   a 2-day run logged 8 brood feeds and 3 cells completed in its summary,
   all other new counters correctly zero for a run with no mining/honey/
   eviction activity, and the first snapshot's `role_outcomes` showed
   73 exposed soil blocks with every cumulative counter still at zero.
   **C6 (re-run the balance comparisons) is done, 22 Aug.** New
   scenarios in `test_scenarios/c6_*.json`. Before the comparison could
   even run, found and fixed a follow-on bug C1 itself introduced:
   [bee.gd:1067](scripts/bee.gd:1067) checked `nurse_mode == "anything"`,
   but the sub-mode's real key is `"both"` (`roles.gd`) -- no code ever
   assigns the literal `"anything"`, so C1's "fall back to jelly when
   idle" half was dead code (an Anything-mode nurse with no hungry
   brood just stood idle). Fixed the string; C1's headline fix (feed
   before jelly) was unaffected, since that's a separate branch. With
   the fix in: nurse comparison shows Anything (112 feeds, 0 deaths
   over 10 days) tracking Feed (118 feeds, 2 deaths) instead of lagging
   it; fanner comparison shows honey batches deposited and cells
   ripened both rising with fanner count (27/27, 39/27, 55/34 for
   1/2/4 fanners over 6 days) instead of staying flat, though not a
   clean linear multiplier -- see `CHATGPT_INSIGHTS_PLAN.md`'s C6
   writeup for why. `source_checks.py`, `balance_tests.py`,
   `FUNCTION_MAP.md` regeneration and a `mcp__godot__` boot (clean,
   only the same pre-existing warnings) all pass.
   **Next concrete action:** C2's and C4's own still-open verification
   steps (a headless run with no jelly cell marked; a hatch test for a
   Stocking-configured cell), then Groups B and A (action-driver
   correctness, then harness speed/token efficiency) in either order.
