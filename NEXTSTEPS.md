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
7. **`CHATGPT_INSIGHTS_PLAN.md` -- C1, C2 and C3 built, 22 Aug.** C1 fixed
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
   **Still open:** all three slices' own verification steps (2-Feed-vs-
   2-Anything for C1; a headless run with no jelly cell marked for C2;
   a 1-fanner-vs-4-fanner comparison for C3) -- worth doing together as
   C6's combined re-run rather than three separate scenario runs.
   **Next concrete action:** C4 (Stocking hatch fallback) -- see
   `CHATGPT_INSIGHTS_PLAN.md` Group C. Groups B and A (action-driver
   correctness, then harness speed/token efficiency) can follow in
   either order.
