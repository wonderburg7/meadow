# Hands-on check backlog

Flat checklist of shipped work that's only been checked as far as source
reading and automated tests can confirm. Nothing here needs more building
-- it needs Dave to actually play it. Tick items off (or delete them) as
they're checked; this file is meant to shrink, not accumulate write-ups.
See `git log` for the commit that shipped each item if more detail is
needed.

## UI Plan slices 1-7 (see `UI_PLAN.md`)
- [ ] Rendering at each resolution/theme/scale.
- [ ] Narrow-window reflow.
- [ ] Bottom-row grows-taller rule.
- [ ] Challenge-completion screen's actual play test.
- [ ] Whether a `Button` using a `Label`-registered theme type variation
      actually picks up the scaled font size (untestable without running
      the game).

## Game model slices 1-4 (see `DESIGN_BACKLOG.md` section 13)
- [ ] Slice 3's prerequisite cascade: open Settings, toggle Orientation
      flight / Auto scouting / Floral constancy / Auto-recruitment on and
      off and confirm the cascade walks correctly both ways; same for
      Predators / Crab-spider suppression / Alarm pheromone.
- [ ] Decision needed, not just a check: is the forager-history save gap
      (`avg_collection_rate`, `trips_scored`, `scout_*` fields,
      `hive.entrance_mentors` missing from `save_game.gd`'s per-bee
      block) worth its own slice? Ask Dave.

## Bumble flight
- [ ] Load the game, watch outdoor foragers fly, confirm the two-sine
      wander reads as bee-like, not mechanical. Toggle/tuning is in the
      debug panel under "Bee life" (`GameConfig.bumble_flight_on`).

## Recruitment and crab-spider fixes
- [ ] Re-check the recruitment competition fix (commit `103d716`).
- [ ] Re-check the crab-spider second-round fixes (`CRAB_SPIDER_PLAN.md`,
      20 Aug "Confirmed" entry).

## AI playtest harness (slices 1-7, the headless action driver)
- [ ] Review all seven slices end to end -- see `git log` for the
      slice-by-slice detail.
