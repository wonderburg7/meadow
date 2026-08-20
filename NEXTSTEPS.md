# Next steps

Read this first in a new session, before anything else in CLAUDE.md. This
file holds only the next 1-3 concrete actions -- it is rewritten (not
appended to) at the end of every build session, so it should never grow
into a history. Full history lives in `git log` and the Notion Build Log.

## Next up

1. **Crab spiders: a second round of playtest fixes.** Death marks
   (confirmed working) and the first round of dev-marker/alarm-ring/
   logging fixes (confirmed) turned up three more issues plus a settings
   gap, all fixed this session -- see `CRAB_SPIDER_PLAN.md`'s 20 Aug
   "Confirmed" entry for the full detail:
   - `crab_spider_attack_success_chance` is now in the settings window
     (it was the one crab-spider number that wasn't).
   - **Real bug**: an escaped bee's cooldown on the exact flower she was
     attacked at lived in the same dictionary `nearest_flower()`'s
     scarcity fallback deliberately ignores (right for an ordinary
     rejection, wrong for a predator memory that should hold regardless
     of what else is nearby) -- bees were walking straight back into the
     same spider. Fixed with a separate `predator_flower_cooldowns` dict,
     checked unconditionally.
   - A bee who's actually attacked and escapes (not just alarm-avoids)
     had no visual at all -- only `alarm_ring`'s precognitive-avoidance
     case flashed. Added `attack_ring` (red, vs. alarm_ring's orange) so
     both outcomes are now visible and distinguishable.
   - The dev marker's large filled disc visually dwarfed the flower it
     sat on, reading as a separate object bees "beelined for" -- changed
     to an unfilled ring (`Line2D`) so it frames the flower instead.
   `source_checks.py`/`balance_tests.py` pass, `FUNCTION_MAP.md`
   regenerated, a Godot boot is clean. **Needs Dave's re-check** on all
   four: the new setting does something, an escaped bee's flower stays
   off-limits even when forage is tight, every attack (not just
   alarm-triggered avoidance) flashes red, and the dev marker now reads
   as a ring rather than a blob. Bundle 3 (recruitment suppression) and
   Bundle 4's original checklist item still haven't had their own
   hands-on check; Bundle 6 (closeout) is last, once all of this settles.
2. **A backlog of earlier hands-on checks is building up** -- none of
   these are blocked on anything, just not yet played:
   - Two Challenge 1/2 fixes from two sessions ago (corner problem strip
     hidden during a Challenge; backup building/mining now breaks off
     promptly when primary work turns up) -- both boot clean, neither
     played.
   - Challenge 2's ten sub-stages -- built and checked, never played
     start to finish (see `TUTORIAL_PLAN.md`'s checklist).
   - Two older audit bundles: Bundle A (abandon Challenge 1 mid-build,
     confirm a fresh run's build time/Save-Load state reset cleanly) and
     Bundle B (save/load a few times, check population/flower counts and
     the queen panel's plain-comb checkbox stay in sync).

## Waiting, lower priority

- The non-fog worst-frame cost (a genuine engine/render-thread cost, not
  anything in GDScript) -- `perf.gd` has hit its ceiling on it; next step
  is Godot's own Debugger > Profiler, not more work in `perf.gd`.
- Scouting/recruitment split and bee individuality -- shipped, exercised
  incidentally, never explicitly confirmed.
- Re-measure `bee_movement.gd` with `perf.gd`.
- Depth in what exists: nurse-mediated caste switching, comb temperature,
  multi-storey comb.
- A second hive site to move to.
