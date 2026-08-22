# Next steps

Read this first in a new session, before anything else in CLAUDE.md. This
file holds only the next 1-3 concrete actions -- it is rewritten (not
appended to) at the end of every build session, so it should never grow
into a history. Full history lives in `git log`.

## Next up

1. **Challenge 1 revamp + trigger-property convention -- planned, not
   built, 22 Aug 2026.** Full bundle-by-bundle implementation plan in
   `CHALLENGE1_REVAMP_PLAN.md` (written this session, from a design pass
   with Dave). Rewrites `challenge_runner.gd`'s `STAGES_1` into a much
   longer sequence (an auto-mined tunnel intro, a locked-down opening
   with summary-only bee selection, a reusable "visit N flagged points"
   stage helper, manual meadow foraging before the auto-role reveals,
   and -- new decision -- folds Challenge 2's laying/nursing/first-hatch
   content (`STAGES_2` 2.1/2.2) into Challenge 1, which means Challenge 2
   needs trimming afterwards so nothing repeats (Bundle G). Also adds a
   small `trigger` tag (`design`/`skill`/`stage`/`event`/`interaction`)
   to `challenge_runner.gd`'s own unlocks -- Challenge-scoped only, per
   Dave's own call; `stage_gate.gd` and the fuller cross-mode resolver
   already designed in `SKILL_TREE_PLAN.md` are explicitly out of scope
   here. The plan's own "What already exists" table is the important
   part to read first -- most of what the new flow asks for (mining,
   manual bee commands, permanent-reveal fog, egg-laying/nursing, the
   selection-panel/command-tray split) is already-built machinery being
   resequenced, not new systems. **Next concrete action:** start Bundle A
   (stage-array skeleton + the trigger tag) then Bundle B (the auto-mine
   sequence, the one genuinely tricky new mechanic) -- see the plan's
   "Suggested session grouping" for the rest.
2. **UI Plan slices 1-7 and 9 are built** (`UI_PLAN.md` section 15).
   Slices 1-7 are as before -- see `git log` for the slice-by-slice
   detail, or an earlier version of this file for slice 7's full
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
   **Concrete action once picked back up:** finish the slice-1b
   migration for `hud.gd` and `debug_panel.gd` (the two files that
   matter most -- `game_over.gd` and `gallerin_panel.gd` are much
   smaller and can follow). This is real build work, not another
   verification pass -- worth treating as its own slice.
   Everything visual/behavioural from slices 1-7 (rendering at each
   resolution/theme/scale, the narrow-window reflow, the bottom-row
   grows-taller rule, the Challenge-completion screen's actual play
   test) is still only checked as far as source-reading and a clean
   boot can confirm -- all of it still needs Dave's hands-on pass; see
   `git log` for the per-slice hands-on-check lists, all still open.
   Slice 8 (the skill tree) stays superseded by `SKILL_TREE_PLAN.md`'s
   own build sequence.
3. **Game model slices 1-4 are built** (`DESIGN_BACKLOG.md` section 13).
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
4. **Bumble flight is built** -- outdoor flying bees drift on a small
   two-sine wander instead of beelining, eased in/out so landing and
   taking off read as smooth. Toggle + tuning in the debug panel under
   "Bee life" (`GameConfig.bumble_flight_on`). **Not yet hands-on
   played** -- load the game, watch outdoor foragers fly, confirm the
   wander reads as bee-like.
5. **Recruitment competition fix and the crab-spider second-round
   fixes are both still waiting on Dave's hands-on re-check** -- see
   `git log` (commit `103d716`) and `CRAB_SPIDER_PLAN.md`'s 20 Aug
   "Confirmed" entry respectively.
6. **AI playtest harness is built through slice 7** (the headless action
   driver). All of slices 1-7 still await review -- see `git log` for
   the slice-by-slice detail.
7. **A foraging ecology overhaul is proposed, slices 0-1 refined**
   (`FORAGING_ECOLOGY_PLAN.md`, `DESIGN_BACKLOG.md` section 14). Slice 0
   (seed the meadow layout per scenario) is the next concrete action for
   that plan once the hands-on-check backlog above has room.
8. **`CHATGPT_INSIGHTS_PLAN.md` -- Group C and B1-B2 built and verified,
   22 Aug.** Full detail (what each slice fixed, how it was verified) is
   in the plan file itself, not repeated here -- read that before
   picking the next slice back up. **Next concrete action:** B3
   (postcondition evidence for the remaining verbs --
   `_do_designate_cell`, `_do_queue_build`, `_do_queue_mine` in
   `scenario_actions.gd`), then B4 (live settings in analysis,
   `tools/analyze_session.py`) and B5 -- see the plan's Group B section.
   Group A (harness speed/token efficiency) can follow in either order
   once B is done.
