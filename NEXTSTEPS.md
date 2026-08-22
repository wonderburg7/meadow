# Next steps

Read this first in a new session, before anything else in CLAUDE.md. This
file holds only the next 1-3 concrete actions -- it is rewritten (not
appended to) at the end of every build session, so it should never grow
into a history. Full history lives in `git log`.

## Next up

1. **UI Plan slices 1-4 are built** (`UI_PLAN.md` section 15). Slices
   1-3 are as before (tokens/text-scale foundation, two-row top bar plus
   goal shelf, selection/command trays). **Slice 4** restyles the Colony
   and Nursery drawers under `ui_theme.gd`'s tokens and reorders each
   per section 5's priority list. Colony drawer: a new "Needing
   attention" section now leads (repurposing `main.hud.shown_signals` --
   the same list the corner problem strip already builds from -- as a
   clickable, severity-coloured list via a new shared
   `UI.signal_line_button()` helper), then "Who is doing what", then
   "Readouts", then "Favourites", then "Over time" last. Nursery drawer:
   a new "Brood needing attention" section leads (the same signals list,
   filtered to a new "brood" category tag `year_winter.gd` now attaches
   to the hungry-brood/dead-cell/no-pollen/no-nurse lines), then "The
   zone" (now capacity only -- cell counts, not the by-role breakdown),
   then a new **"Brood stages"** row (egg/larva/capped counts from a new
   `Hive.brood_stage_counts()`, which buckets each cell's existing
   `development_percent()` into thirds -- presentation only, no new
   simulation state), then "Priority tiers", "The colony now" (ring),
   "Emerging", and "Intended roles" (the by-role breakdown, moved to its
   own section) last. Both drawers' new signal sections share one click
   handler (`colony_panel.gd`/`nursery_panel.gd`'s new `signal_clicked`
   signal, wired in `main.gd` to `year_winter.gd::_on_signal_clicked`,
   the same handler the corner strip already uses).
   **While boot-checking this slice, found and fixed a real parser bug
   in `hud.gd` left over from slice 3** (never boot-tested until this
   session, since no Godot MCP tools were available before now): a local
   variable named `trait` at `hud.gd:2066` (`trait` is a reserved
   GDScript word) plus a `:=` type-inference failure on the same line
   once renamed (the documented landmine in `.claude/rules/gdscript.md`
   -- `b` isn't statically typed as `Bee`) were both blocking the whole
   project from parsing at all. Fixed by renaming to `trait_line` and
   giving it an explicit `: String` type. This means **slices 2 and 3
   have now had their first real boot check too**, not just slice 4 --
   the project loads and runs with no parser/compile errors and no new
   warnings.
   `source_checks.py`, `balance_tests.py` and `FUNCTION_MAP.md`
   (regenerated) all pass/are clean; a full `mcp__godot__run_project`
   boot was clean (no errors, only pre-existing warnings unrelated to
   this session's files).
   **Not yet hands-on checked, any of slices 2-4** -- a boot check only
   confirms the game loads and runs, not that any of this looks or
   behaves right. Start or continue Challenge 1 and a Starter-mode run
   and confirm, for slice 4 specifically: opening the Colony drawer
   shows "Needing attention" first with real problems (or the "nothing
   needs attention" message when the colony's fine), and clicking a line
   selects/focuses what it's about; the Nursery drawer's "Brood needing
   attention" only shows brood-relevant problems (not the full list);
   "Brood stages" shows sensible egg/larva/capped counts against a
   manual count in a small colony, and its star still pins it to the
   corner; "The zone" and "Intended roles" between them still show
   everything the old combined "zone" block used to; nothing in either
   drawer looks wrong in light/high-contrast theme or at 200% text
   scale. For slices 2-3 (first real check of any kind this session):
   the two-row top-right bar, the goal shelf's strikethrough/progress,
   the bottom-left selection tray's four fields and cog, the
   bottom-centre command tray's primary buttons and "More…" panel, and
   "Follow bee" -- see the previous version of this file (`git log` /
   `git show`) for the full acceptance list, all of it still applies.
   Also worth a look at a narrow window width (~800px) to confirm
   nothing clips.
   **Next slice** is slice 5 (Settings drawer: split "Interface" into
   Appearance/Accessibility, add rows for every new `Session` field from
   slices 1-4) -- `UI_PLAN.md` section 15 has the detail; likely file
   `debug_panel.gd`.
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
