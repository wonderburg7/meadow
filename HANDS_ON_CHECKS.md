# Hands-on check backlog

Flat checklist of shipped work that's only been checked as far as source
reading and automated tests can confirm. Nothing here needs more building
-- it needs Dave to actually play it. Tick items off (or delete them) as
they're checked; this file is meant to shrink, not accumulate write-ups.
See `git log` for the commit that shipped each item if more detail is
needed.

## UI Plan slices 1-7 (see `UI_PLAN.md`)
**Checked 22 Aug by Dave -- found broken, not just unconfirmed.** Text
scale, font choice, dark/light theme toggle, colour-blind labels beyond
the nursery ring, panel background/frame/spacing, settings-window
sections, cell popup position, meadow/hive button hit area, and
follow-bee-on-view-change all failed. Root cause and an eight-slice fix
plan are in `UI_BUGFIX_PLAN.md` -- don't re-check these again here until
that plan lands; re-check against that plan's own acceptance notes
instead.
- [x] Challenge-completion screen's actual play test -- confirmed 22 Aug,
      Challenge 1 completes as intended.
- [ ] Narrow-window reflow and panel-overlap-on-resize -- still open,
      see `UI_BUGFIX_PLAN.md` Slice 6.

## Game model slices 1-4 (see `DESIGN_BACKLOG.md` section 13)
- [x] Slice 3's prerequisite cascade -- confirmed 22 Aug by Dave, both
      chains (Orientation flight/Scouting/Floral constancy/Auto-
      recruitment and Predators/Crab-spider suppression/Alarm pheromone)
      walk correctly both ways.
- [ ] Decision needed, not just a check: is the forager-history save gap
      (`avg_collection_rate`, `trips_scored`, `scout_*` fields,
      `hive.entrance_mentors` missing from `save_game.gd`'s per-bee
      block) worth its own slice? Ask Dave.

## Bumble flight
- [x] Confirmed 22 Aug by Dave -- the two-sine wander reads as bee-like.

## Recruitment and crab-spider fixes
- [ ] Recruitment competition fix (commit `103d716`) -- **not** re-checked;
      Dave is deferring this until the planned recruitment update lands
      (see `FORAGING_ECOLOGY_PLAN.md`), so don't chase it before then.
- [x] Crab-spider second-round fixes -- confirmed 22 Aug by Dave, predator
      behaviour works as intended.

## AI playtest harness (slices 1-7, the headless action driver)
- [ ] Review all seven slices end to end -- see `git log` for the
      slice-by-slice detail.
