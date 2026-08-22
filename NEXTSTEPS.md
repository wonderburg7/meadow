# Next steps

Read this first in a new session, before anything else in CLAUDE.md. This
file holds only the next 1-3 concrete actions -- it is rewritten (not
appended to) at the end of every build session, so it should never grow
into a history. Full history lives in `git log`.

## Next up

1. **UI Plan slices 1-7 are built** (`UI_PLAN.md` section 15). Slices 1-6
   are as before -- see `git log` for the slice-by-slice detail, or the
   previous version of this file for slice 6's full description.
   **Slice 7** adds the Challenge-completion screen; the winter forecast
   restyle it was paired with turned out to already be done (slice 1
   restyled `winter_panel.gd` as its own demonstration panel, so there
   was nothing left for this slice to do there):
   - New `challenge_complete.gd` (`CanvasLayer`, `game_over.gd`'s shape:
     backdrop + centred panel, `get_tree().paused = true` while open) --
     shown once a Challenge's final sub-stage completes. Unlike
     `game_over.gd` the colony hasn't ended, so its two buttons are
     "Continue playing" (unpauses, keeps playing the same now-fully-
     unlocked colony) and "Main menu" (opens the main menu, same as
     `game_over.gd`'s own menu button) -- no restart option, since
     there's nothing to restart from.
   - `challenge_runner.gd::_complete()` now calls
     `main.challenge_complete.open(headline, flavour, day, bees, nectar,
     pollen)` instead of showing Dr Gallerin's old "complete" bubble --
     kept the same headline/flavour text, moved it into the new screen
     rather than showing both (they'd otherwise say the same thing
     twice in a row).
   - `main.gd` instantiates and wires it the same way as `game_over`
     (const preload, `var challenge_complete`, signal connections in
     `_ready()`).
   `source_checks.py` and `balance_tests.py` both pass. **No
   `mcp__godot__` boot check this session** -- the Godot MCP tools
   weren't available; say so rather than treating this as verified.
   **Not yet hands-on checked.** Play (or dev-warp) through Challenge 1
   or 2 to its final sub-stage and confirm: the new screen appears,
   paused, with the right headline/flavour/summary numbers; "Continue
   playing" unpauses and leaves the colony exactly as it was, now fully
   unlocked; "Main menu" opens the menu as expected. Also worth a look:
   the screen at 200% text scale and in all three themes, per section
   14's usual checks -- not specifically verified this session.
   Also still outstanding from before: slices 2-6's hands-on checks --
   see `git log` for those lists, all of it still applies.
   **Next slice** is slice 9 (final feature-gating/accessibility/layout
   verification pass) -- slice 8 (the skill tree) is superseded by
   `SKILL_TREE_PLAN.md`'s own build sequence, so slice 9 is next unless
   Dave wants the skill tree prioritised first.
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
7. **`CHATGPT_INSIGHTS_PLAN.md` is new, not started** -- 16 small slices
   turning `insights_from_ChatGPT.md`'s 22 Aug entries into real fixes.
   Suggested first move: Group C (real gameplay bugs -- Anything-mode
   nurses feeding after jelly instead of before, honey fanning not
   stacking, undesignated jelly spill, Stocking hatch fallback), since
   those affect the game as it plays today, not just the headless
   harness. Groups B and A (action-driver correctness, then harness
   speed/token efficiency) can follow in either order.
