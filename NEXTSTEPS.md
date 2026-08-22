# Next steps

Read this first in a new session, before anything else in CLAUDE.md. This
file holds only the next 1-3 concrete actions -- it is rewritten (not
appended to) at the end of every build session, so it should never grow
into a history. Full history lives in `git log`.

## Next up

1. **UI Plan slices 1-5 are built** (`UI_PLAN.md` section 15). Slices
   1-4 are as before (tokens/text-scale foundation, two-row top bar plus
   goal shelf, selection/command trays, Colony/Nursery drawer restyle
   and brood stages -- see `git log` for the slice-by-slice detail, or
   the previous version of this file for slice 4's full description).
   **Slice 5** splits the settings window's overloaded "Interface"
   category into **Appearance** and **Accessibility** (`debug_panel.gd`
   `CATEGORIES`/`TUNABLES`), and adds a row for every `Session` field
   slices 1-3 introduced that didn't already have one:
   - **Appearance**: history/plot settings, the low-energy warning
     trio, "Frame rate" (star), "Dr Gallerin" (all moved from
     "Interface" unchanged), plus two new rows -- **Theme**
     (dark/light/high contrast) and **Show 8x speed button**
     (`Session.show_speed_8x`, live -- see below).
   - **Accessibility**: "Show info icons" and "Colour-blind labels"
     (moved from "Interface" unchanged), plus five new rows --
     **Typeface**, **Text scale** (100-200%), **Reduced motion**,
     **Screen shake** (off/reduced/full), **Tooltip delay**.
   Where an existing row went (which of the two categories it landed
   in) was my judgement call, not something the plan pinned down --
   worth a glance in case any of it reads wrong to you.
   New control type: a small "‹ label ›" row (`_make_options_row`) for
   settings whose value is one of a fixed set of strings, alongside the
   existing toggle/star/+-numeric rows -- nothing like it existed
   before, since every prior string-valued setting was still a plain
   number or bool.
   **What's actually live vs. a reserved slot:** Show 8x speed button is
   fully wired -- `hud.gd`'s speed row now always builds the 8x button
   and only toggles `.visible`, and a new `hud.gd::refresh_speed_
   visibility()` (dispatched the same way `pinned_stats_changed()` is)
   makes the settings-window toggle apply immediately rather than only
   on the next reload. Tooltip delay is wired to Godot's own
   `ProjectSettings` tooltip timer, applied on every +/- press and once
   at boot. Theme/Typeface/Text scale change `Session` immediately but
   only reach a panel the next time it's built (`colony_panel.gd`/
   `nursery_panel.gd`/`winter_panel.gd` each build their `UiTheme.
   build_theme()`/stylebox once in `_ready()`, and `hud.gd`'s own top
   bar doesn't consume `UiTheme` yet) -- deliberately not wiring a
   cross-panel live-refresh broadcast this slice, since two of those
   three panels are drawers that are invisible until reopened anyway, so
   in practice this is very close to "immediate" already; flag to Dave
   if it should be tightened further. Reduced motion and Screen shake
   are genuinely inert placeholders still -- nothing in the codebase
   reads either yet (screen shake because no shake effect exists at
   all; reduced motion because nothing has wired it to the existing
   pulse/flash effects in `bee.gd`/`flower.gd`/`crab_spider.gd` despite
   `UI_PLAN.md` section 7 describing that as the intent) -- both are
   explicitly reserved slots per their own `session.gd` doc comments, so
   this isn't a regression, but it's a real gap if Dave expected them to
   do something yet.
   `source_checks.py`, `balance_tests.py` and `FUNCTION_MAP.md`
   (regenerated) all pass/are clean. **No `mcp__godot__` boot check this
   session** -- the Godot MCP tools weren't available, so this slice has
   had no real GDScript parse, only the two Python check suites (which
   are not a real parser -- see `.claude/rules/gdscript.md`).
   **Not yet hands-on checked, any of slices 2-5** (slice 1 has had a
   partial check; see `git log`). Open the settings window and confirm:
   "Appearance" and "Accessibility" both appear where "Interface" used
   to, each with the rows listed above and nothing missing; the Theme/
   Typeface/Screen shake rows cycle correctly with the ‹/› buttons and
   show a sensible label; Text scale and Tooltip delay step correctly
   between their stated min/max; toggling "Show 8x speed button" adds/
   removes the 8x button in the top-right bar straight away, with no
   change to 1x/2x/4x's layout; every row's info badge reads sensibly.
   Also still outstanding from before: slice 4's Colony/Nursery drawer
   checks, and slices 2-3's top bar/goal shelf/selection tray/command
   tray checks -- see the previous version of this file (`git log` /
   `git show`) for those full lists, all of it still applies. Also
   worth a look at a narrow window width (~800px) to confirm nothing
   clips.
   **Next slice** is slice 6 (main menu honeycomb layout, Challenges/
   Scenarios rename, scenario presets, and the new `player_profile.gd`
   persistence layer) -- `UI_PLAN.md` section 15 has the detail; likely
   files `main_menu.gd`, `levels.gd`, new `player_profile.gd`,
   `session.gd`, `debug_panel.gd`.
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
