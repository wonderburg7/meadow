# Next steps

Read this first in a new session, before anything else in CLAUDE.md. This
file holds only the next 1-3 concrete actions -- it is rewritten (not
appended to) at the end of every build session, so it should never grow
into a history. Full history lives in `git log`.

## Next up

1. **UI Plan slice 1 is built** (`UI_PLAN.md` section 15) -- the shared
   design-token/layout/text-scale foundation the other eight slices sit
   on. New `scripts/ui_theme.gd` (dark/light/high-contrast palettes per
   the doc's section 6, a seven-state stylebox builder, and a Theme
   resource with named type variations -- Heading/Body/Small/Tiny --
   scaled by `Session.text_scale` and swapped by `Session.ui_typeface`
   per section 7) and `scripts/ui_layout.gd` (the Gallerin-reserve
   constant and responsive breakpoints from section 2). `session.gd`
   gained the six new interface-preference fields (`ui_theme`,
   `ui_typeface`, `text_scale`, `reduced_motion`, `screen_shake`,
   `tooltip_delay`) and `show_info_badges` now defaults off, per section
   9. `winter_panel.gd` -- the smallest existing panel, as the doc
   proposed -- is the first demonstration restyle: its panel background,
   close button and three labels now all read from `UiTheme` instead of
   hardcoding a StyleBoxFlat/font size/colour each.
   `source_checks.py`, `balance_tests.py` and a Godot boot all pass
   clean (same pre-existing warnings as before, nothing new).
   **Not yet hands-on checked** -- open the winter forecast panel (the
   "Winter" corner readout when one is starred, or the winter button
   once scheduled) and confirm it still looks right; then, since there's
   no settings-window UI for the new fields yet (that's slice 5), the
   quickest way to see the other two themes and 200% text scale working
   is to temporarily set `Session.ui_theme = "light"` (or
   `"high_contrast"`) and `Session.text_scale = 2.0` in code and reopen
   the panel, then revert. Typeface switching has no visible effect yet
   for any option other than the default -- the three font files
   (Atkinson Hyperlegible, a dyslexia-friendly face, Pixel Operator)
   aren't sourced (section 8), so `ui_theme.gd` falls back to the
   default font until they're added under `assets/fonts/`, by design.
   **Next slice** is slice 2 (`hud.gd`'s top-right bar into two rows
   with icon placeholders and an explicit Pause button, the goal shelf)
   -- `UI_PLAN.md` section 15 has the detail, and per its own "working
   through these slices" note, only `hud.gd`, `challenge_runner.gd` and
   `session.gd` should need opening for it.
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
