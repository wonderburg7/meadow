# Next steps

Read this first in a new session, before anything else in CLAUDE.md. This
file holds only the next 1-3 concrete actions -- it is rewritten (not
appended to) at the end of every build session, so it should never grow
into a history. Full history lives in `git log`.

## Next up

1. **Game model slice 3 is built** (`DESIGN_BACKLOG.md` section 13,
   the only slice that touches code) -- `TOGGLE_PREREQUISITE` and the
   two lookups its cascade needs (`direct_parent`, `direct_dependents`)
   are extracted out of `debug_panel.gd` into
   `scripts/prerequisites.gd`, a plain `RefCounted` catalogue in the
   `roles.gd` style. `debug_panel.gd` now reads from it instead of
   owning the dictionary; the actual toggling and checkbox sync
   (`_cascade_prerequisites_on`, `_cascade_dependents_off`) stayed
   there, since that part needs `setting_get`/`setting_set` and the
   live `toggle_boxes` widgets that only the settings window has.
   Cascade behaviour itself is unchanged -- checked by comparing old
   and new function bodies line for line, not just by the suites
   passing. `source_checks.py`, `balance_tests.py` and a Godot boot (no
   new warnings, same pre-existing ones as before) all pass;
   `FUNCTION_MAP.md` regenerated and `--check` clean. `GAME_MODEL.md`
   and `DESIGN_BACKLOG.md` §13 updated to match.
   **Not yet hands-on checked** -- the cascade only fires from clicking
   the settings-window checkboxes, which nothing automated here
   drives, so that's the one thing left: open Settings, toggle
   Orientation flight / Auto scouting / Floral constancy /
   Auto-recruitment on and off and confirm the cascade still
   walks correctly both ways, and the same for
   Predators / Crab-spider suppression / Alarm pheromone.
   The forager-history save gap slice 2 also surfaced (trip-history
   state like `avg_collection_rate`, `trips_scored`, `scout_*` fields
   and `hive.entrance_mentors` isn't in `save_game.gd`'s per-bee
   block) is still unactioned -- ask Dave whether it's worth its own
   slice.
2. **Bumble flight is built** (`ROADMAP.md`'s "Depth in what exists" row)
   -- outdoor flying bees now drift on a small two-sine wander instead of
   beelining. `bee.gd` gained a `visual_root` child node that every
   visual piece (rings, body, label) now hangs off, so the wander offsets
   *drawing* only -- `bee.position` itself, and everything that reads it
   (arrival checks, obstacle steering, the stall watchdog), is untouched.
   `bee_movement.gd::move_towards`'s outdoor branch sets one flag
   (`bee.flying_outdoors`); `bee.gd::_update_wander_flight()` reads it and
   is gated on-screen the same way `_update_label`/`_update_alarm_ring`
   already are, so it costs nothing off screen or indoors. New toggle +
   amplitude/frequency/settle-time in the debug panel under "Bee life"
   (`GameConfig.bumble_flight_on`, on by default). **Second pass same
   session**, after Dave caught it visually: bees were snapping onto the
   flower on arrival, because the offset used to be set outright rather
   than eased -- `_update_wander_flight` now lerps `visual_root.position`
   towards its target over `bumble_flight_settle_seconds` instead, so
   landing (and taking off) reads as smooth. Amplitude also raised
   6 -> 14px and the two sines' rate ratio widened (1.3 -> 1.7) so the
   drift is a more visible deviation from the flight line, per Dave's
   ask. `exp()` was missing from `source_checks.py`'s bare-call
   allowlist -- added, not worked around. Both check suites and
   `update_function_map.py --check` pass; no Godot instance was available
   either session to boot-test it, and nothing hands-on played yet --
   that's the next thing to do: load the game, watch outdoor foragers
   fly, and confirm the wander reads as bee-like and the landing as
   smooth, not just as a smaller/slower snap.
3. **Recruitment competition fix from a previous session is still
   waiting on Dave's hands-on re-check** -- `bee_foraging.gd::wait_at_entrance`
   now removes a mentor from the list the instant she's matched. Both
   check suites pass; see `git log` (commit `103d716`) for the full
   quantification.
4. **AI playtest harness is built through slice 6**, still waiting on
   review -- see `git log` for the slice-by-slice detail.
5. **Crab spiders: a second round of playtest fixes**, still waiting on
   Dave's hands-on re-check -- see `CRAB_SPIDER_PLAN.md`'s 20 Aug
   "Confirmed" entry.
6. **A full UI redesign is planned, not started** -- `UI_PLAN.md` (20 Aug
   2026), nine build slices, lower priority than the above.
7. **A foraging ecology overhaul is proposed, Slices 0-1 refined** -- Dave's
   22 Aug design brief (patchy meadow, local search, probabilistic choice,
   species registry, proximity recruitment) is now `FORAGING_ECOLOGY_PLAN.md`,
   with `DESIGN_BACKLOG.md` section 14 as the summary. Two corrections made
   against the brief as written: the recruitment fix it calls "uncommitted"
   is item 3 above, already shipped; `recruit_start_point_jitter` is 150, not
   250. Slice 0 (seed the meadow layout per scenario, re-run the existing
   on/off comparison across several seeds) is the next concrete action once
   the hands-on-check backlog above has room -- it's a single small session,
   lower priority than items 2-5 but worth queuing next since it's the
   prerequisite for everything else in that plan.
