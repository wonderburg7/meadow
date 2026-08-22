# Next steps

Read this first in a new session, before anything else in CLAUDE.md. This
file holds only the next 1-3 concrete actions -- it is rewritten (not
appended to) at the end of every build session, so it should never grow
into a history. Full history lives in `git log` and the Notion Build Log.

## Next up

1. **Bumble flight is built** (`ROADMAP.md`'s "Depth in what exists" row)
   -- outdoor flying bees now drift on a small two-sine wander instead of
   beelining. `bee.gd` gained a `visual_root` child node that every
   visual piece (rings, body, label) now hangs off, so the wander offsets
   *drawing* only -- `bee.position` itself, and everything that reads it
   (arrival checks, obstacle steering, the stall watchdog), is untouched.
   `bee_movement.gd::move_towards`'s outdoor branch sets one flag
   (`bee.flying_outdoors`); `bee.gd::_update_wander_flight()` reads it and
   is gated on-screen the same way `_update_label`/`_update_alarm_ring`
   already are, so it costs nothing off screen or indoors. New toggle +
   amplitude/frequency in the debug panel under "Bee life"
   (`GameConfig.bumble_flight_on`, on by default). Both check suites and
   `update_function_map.py --check` pass; no Godot instance was available
   this session to boot-test it, and nothing hands-on played yet --
   that's the next thing to do: load the game, watch outdoor foragers
   fly, and confirm the wander reads as bee-like rather than distracting
   or making bees look like they're missing their targets.
2. **Recruitment competition fix from the previous session is still
   waiting on Dave's hands-on re-check** -- `bee_foraging.gd::wait_at_entrance`
   now removes a mentor from the list the instant she's matched. Both
   check suites pass; see `git log` (commit `103d716`) for the full
   quantification.
3. **AI playtest harness is built through slice 6**, still waiting on
   review -- see `git log` for the slice-by-slice detail.
4. **Crab spiders: a second round of playtest fixes**, still waiting on
   Dave's hands-on re-check -- see `CRAB_SPIDER_PLAN.md`'s 20 Aug
   "Confirmed" entry.
5. **A full UI redesign is planned, not started** -- `UI_PLAN.md` (20 Aug
   2026), nine build slices, lower priority than the above.
