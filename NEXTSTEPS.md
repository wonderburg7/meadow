# Next steps

Read this first in a new session, before anything else in CLAUDE.md. This
file holds only the next 1-3 concrete actions -- it is rewritten (not
appended to) at the end of every build session, so it should never grow
into a history. Full history lives in `git log`.

## Next up

1. **UI Plan slices 1-2 are built** (`UI_PLAN.md` section 15). Slice 1
   is the shared design-token/layout/text-scale foundation
   (`scripts/ui_theme.gd`, `scripts/ui_layout.gd`, the six new
   `Session` interface-preference fields, `show_info_badges` defaulting
   off, `winter_panel.gd` restyled as the demonstration panel).
   Slice 2 reworks `hud.gd`'s top-right bar into two rows per section
   2: row one is an explicit Pause button (split out of the old speed
   button group, which now reads `SPEEDS` for 1x/2x/4x only) plus the
   speed multipliers, with 8x now dev-only and hidden unless
   `Session.show_speed_8x` is set (new field, off by default, same
   pattern as `show_crab_spiders`); row two is Colony/Nursery/Winter/
   view-switch, with the first three plus the view switch now built via
   a new `_icon_button()` helper pairing a small procedural shape
   (new `scripts/ui_icon.gd`, a placeholder per section 8 -- bee, hex,
   flower, hive -- until bespoke art exists) with its existing text
   label, since a rough drawn shape alone isn't legible yet. The goal
   shelf (`set_challenge_goal`) now takes an optional completed-goal
   string (struck through via a `RichTextLabel`, shown underneath the
   current goal) and optional numeric progress (a compact bar), and
   `challenge_runner.gd` feeds both -- the previous stage's `goal_text`
   as "just completed", and progress for the three goals with a
   countable target (`nectar_target`, `pollen_target`, Challenge 2's
   `eggs_laid`). `source_checks.py`, `balance_tests.py`,
   `FUNCTION_MAP.md` (regenerated) and a Godot boot all pass/are clean
   (same pre-existing warnings as before, nothing new).
   **Not yet hands-on checked** -- start or continue Challenge 1 and
   confirm: the two-row bar looks right and doesn't overlap the
   settings cog; the Colony/Nursery/Winter/Hive buttons' icon
   placeholders are at least legible next to their labels; the goal
   shelf shows the current goal, and once 1.4 finishes and 1.5 begins,
   shows "Goal: collect a little nectar." struck through underneath
   once you're on to 1.6, with a progress bar while 1.5/1.6 are active;
   the explicit Pause button toggles correctly and 8x stays hidden
   until `Session.show_speed_8x` is set true in code (no settings-UI
   toggle for it yet -- that's slice 5, same as slice 1's theme/scale
   fields). Also worth a look at a narrow window width (~800px) to
   confirm the two rows don't clip against the corner.
   **Next slice** is slice 3 (selection/command trays and Dr Gallerin's
   reserved width) -- `UI_PLAN.md` section 15 has the detail; per its
   own "working through these slices" note, only `hud.gd`,
   `ui_layout.gd` and (only if its reserved width needs to become a
   named constant) `gallerin_panel.gd` should need opening for it.
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
