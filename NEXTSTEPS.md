# Next steps

Read this first in a new session, before anything else in CLAUDE.md. This
file holds only the next 1-3 concrete actions -- it is rewritten (not
appended to) at the end of every build session, so it should never grow
into a history. Full history lives in `git log`.

## Next up

1. **UI Plan slices 1-3 are built** (`UI_PLAN.md` section 15). Slice 1
   is the shared design-token/layout/text-scale foundation
   (`scripts/ui_theme.gd`, `scripts/ui_layout.gd`, the six new
   `Session` interface-preference fields, `show_info_badges` defaulting
   off, `winter_panel.gd` restyled as the demonstration panel). Slice 2
   reworks `hud.gd`'s top-right bar into two rows (pause/speed, then
   Colony/Nursery/Winter/view-switch via icon-plus-label buttons) and
   extends the goal shelf with a struck-through last-completed goal and
   optional progress bar. Slice 3 splits the old selection panel into
   two trays (`UI_PLAN.md` section 5): a bottom-left **selection tray**
   with four independently hideable fields (identity/job, energy/load,
   activity, trait/quote -- toggled from a `⚙` cog, new `Session`
   fields `show_selection_*`), and a bottom-centre **command tray**
   whose primary row (Doing/Orders/restock/queen-build/the new "Follow
   bee" toggle) wraps in an `HFlowContainer` capped to
   `ui_layout.gd::command_tray_max_width()` so it can never grow into
   Dr Gallerin's reserve; Job, backup role, finish-first and Favourite
   moved into a collapsible "More…" panel below. `gallerin_panel.gd`
   now exposes `RESERVE_WIDTH` as a real constant, which `ui_layout.gd`
   reads instead of duplicating the number. "Follow bee" is new
   camera-tracking behaviour in `camera_view.gd`
   (`_handle_follow`/`_on_follow_bee_toggled`, driven by `main.gd`'s new
   `following_bee` field) -- continuous centring, not a one-off snap;
   it stops automatically on any selection change.
   `source_checks.py`, `balance_tests.py` and `FUNCTION_MAP.md`
   (regenerated) all pass/are clean. **No Godot MCP tools were available
   this session, so slice 3 has not had even a boot-level check** --
   worth doing before the hands-on pass below.
   **Not yet hands-on checked, any of slices 2-3** -- start or continue
   Challenge 1 and confirm: the two-row top-right bar looks right and
   doesn't overlap the settings cog; the goal shelf's strikethrough and
   progress bar behave across a sub-stage transition; selecting a bee
   shows the new bottom-left tray with all four fields, and the cog
   actually hides/shows each one and remembers the choice for the rest
   of the session; the bottom-centre command tray shows the right
   primary buttons per role and never visually overlaps Dr Gallerin's
   bottom-right corner, including at 200% text scale (Settings ->
   Appearance, once slice 5 adds a toggle -- for now `Session.text_scale`
   can be set directly); "More…" reveals Job/backup-role/Favourite and
   remembers open/closed across reselection within the session; "Follow
   bee" (single-bee selection only) keeps the camera centred as the bee
   moves and switches meadow/hive view with it, and turns itself off the
   moment you select something else. Also worth a look at a narrow
   window width (~800px) to confirm nothing clips.
   **Next slice** is slice 4 (Colony/Nursery drawer restyle plus a new
   colony-wide brood-stage count) -- `UI_PLAN.md` section 15 has the
   detail; likely files `colony_panel.gd`, `nursery_panel.gd`,
   `hive.gd`, `hive_cell.gd`.
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
