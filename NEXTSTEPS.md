# Next steps

Read this first in a new session, before anything else in CLAUDE.md. This
file holds only the next 1-3 concrete actions -- it is rewritten (not
appended to) at the end of every build session, so it should never grow
into a history. Full history lives in `git log`.

## Next up

1. **UI Plan slices 1-6 are built** (`UI_PLAN.md` section 15). Slices 1-5
   are as before -- see `git log` for the slice-by-slice detail, or the
   previous version of this file for slice 5's full description.
   **Slice 6** builds the main menu's honeycomb layout, the Challenges/
   Scenarios rename, the Scenario difficulty-preset system, and a new
   `player_profile.gd` persistence layer:
   - `main_menu.gd` is rebuilt: each Challenge/Scenario is now a
     hex-shaped tile (`Polygon2D` fill/border, same "flat shapes, no
     imported art" placeholder approach as Dr Gallerin) laid out in a
     short honeycomb strip per group, restyled under `ui_theme.gd`.
     Clicking a tile opens a detail pane below (title, blurb, a
     completion tick if it's been finished/played before, a Start
     button). Group headings read "Challenges" and "Scenarios" with
     Dave's exact one-line descriptors.
   - New `scenario_presets.gd`: Relaxed/Standard/Demanding/Custom, each
     an explicit (not delta) value for four `GameConfig` fields
     (`energy_burn_rate`, `nectar_recharge_rate`, `pollen_recharge_rate`,
     `winter_burn_factor`) plus a plain-English description per preset.
     Applied via `levels.gd`'s existing `apply_config_overrides` (same
     allowlisted-write mechanism the headless playtest harness uses).
     Custom exposes the same four fields as +/- rows in the detail pane.
     Only reachable from a Scenario tile, never a Challenge.
   - New `player_profile.gd`: a second `user://` JSON file, separate
     from `save_game.gd`'s per-colony save. Holds completed Challenge
     levels, played Scenario+preset combinations, and a durable copy of
     every interface preference from slices 1-5 (theme, typeface, text
     scale, pinned stats, and the rest -- `control_groups`/`comb_overlay`
     stay Session-only, run-scoped). `Session` keeps every existing
     field and call site unchanged; it now loads from the profile in a
     new `_ready()` and writes back via `Session.save_preferences()`,
     called from `debug_panel.gd::setting_set` (the settings window's
     existing choke point) plus the handful of preferences set outside
     it (the pinned-stat stars in `colony_panel.gd`/`nursery_panel.gd`/
     `debug_panel.gd`, the selection-tray field cog and the discard-
     warning "don't show again" checkbox, both in `hud.gd`).
   **Judgement calls made this slice, worth a look:**
   - Scenarios have no win condition, so "completion" for them means
     "started at least once", not "won" -- the honeycomb tick reads
     "Played before." for a Scenario and "Completed." for a Challenge.
   - The honeycomb is one row per group (2 Challenge tiles, 3 Scenario
     tiles), not a packed multi-row grid -- reasonable for how few
     entries either group has today, but would need revisiting if a
     group ever grows past what one row comfortably fits.
   - Each hex tile's click area is its full rectangular bounding box,
     not the exact hexagon outline -- tiles are given a horizontal gap
     specifically so neighbouring bounding boxes never overlap, at the
     cost of true edge-to-edge honeycomb tessellation. Reasonable
     placeholder-art tradeoff, flagged in case Dave wants true
     tessellation once real art exists.
   - Standard's preset restates the baseline value for all four fields
     (rather than an empty override dict) specifically so picking
     Standard after Relaxed/Demanding/Custom always resets those fields,
     rather than leaving the previous preset's numbers sitting in
     `GameConfig` -- this was a real correctness risk worth getting
     right rather than reusing the dev `--scenario=` boot path's
     leak-is-fine assumption as-is.
   `source_checks.py`, `balance_tests.py` and `FUNCTION_MAP.md`
   (regenerated) all pass/are clean. **A `mcp__godot__run_project` boot
   check was clean this session** -- no new parse/runtime errors beyond
   pre-existing warnings unrelated to this slice's files.
   **Not yet hands-on checked.** Open the main menu and confirm: both
   groups show as hex tiles with the right titles; clicking a tile opens
   the detail pane with its blurb; a Scenario tile shows the four preset
   buttons plus plain-English bullets, and Custom shows working +/- rows;
   Start actually launches the chosen level (and, for a Scenario, with
   the chosen preset's numbers actually in effect -- check via the
   settings window's Appearance/Accessibility... actually the relevant
   numbers are un-categorised `GameConfig` fields, so check via a fresh
   colony's forager behaviour, or add a temporary star). Completing
   Challenge 1 or 2, or starting any Scenario, then fully restarting the
   game (not just Restart Run) should show a tick on that tile next time
   the menu opens. Toggling any interface preference (a star, a settings
   row, colour-blind mode) and fully restarting the game should keep
   that preference. Also worth a look: the honeycomb at a narrow window
   width (~800px) and at 200% text scale, per section 14's usual checks
   -- not specifically verified this session.
   Also still outstanding from before: slices 2-5's hands-on checks --
   see `git log` for those lists, all of it still applies.
   **Next slice** is slice 7 (a new Challenge-completion screen, plus a
   restyle-only pass on the winter forecast) -- `UI_PLAN.md` section 15
   has the detail; likely files a new completion-screen script (shape:
   `game_over.gd`), `challenge_runner.gd`, `winter_panel.gd`.
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
