# Next steps

Read this first in a new session, before anything else in CLAUDE.md.
Only the next 1-3 actions belong here -- full detail lives in the named
plan file, full history in `git log`.

## Next up

1. **UI settings & polish plan** -- new, from Dave's 22 Aug second pass
   (screenshots of the settings window and a bee selected). Full detail
   in `UI_SETTINGS_PLAN.md`. Two root causes explain most symptoms:
   `UiTheme.build_theme()` is only ever applied once per panel at
   construction, so theme/typeface/text-scale changes need a Restart
   Run to show; and `build_theme()` never sets a font colour at all, so
   light mode falls back to invisible white text. Dave's chosen order
   (his call, not the plan's default suggestion): **start with Slice 3
   (settings reorganised into Game Settings / Hive / Meadow collections,
   plus a content audit -- e.g. foraging-behaviour tunables currently
   filed under "Flowers")**, then Slice 1 (live theme apply), Slice 2
   (light contrast), Slice 4 (control alignment/sizing), Slice 6
   (favourite as a header icon), Slice 5 (panel texture, needs Dave's
   steer on look before building). Three open questions for Dave are in
   the plan's "Open decisions" section -- check before Slice 3 if they
   haven't been answered yet.
2. **UI bugfix plan** -- Slice 4 and the popup-repositioning part of
   Slice 5 are done, **not yet Dave-verified in-game**. Slices 6
   (resize overlap), 7 (Meadow/Hive hit-area) and 8 (follow-bee-stops)
   are the remaining, unrelated slices. Full detail in
   `UI_BUGFIX_PLAN.md`.
3. **Challenge 1 revamp** -- start Bundle A (stage-array skeleton +
   trigger tag), then Bundle B (auto-mine sequence). Full plan:
   `CHALLENGE1_REVAMP_PLAN.md`; read "What already exists" first.
4. **Foraging ecology plan -- Slices 0-3 done and fully Dave-verified.**
   Two rounds of playtest fixes landed and were re-confirmed in-game
   (22 Aug): Bramble/Dandelion's recharge rate (`recharge_scale`,
   0.7/1.4), Bramble now genuinely seeding 2-4 flower units as one bush
   (`bush_min_units`/`bush_max_units`, `world_building.gd`'s
   `_seed_flower`), Clover recoloured pinky-purple so it's no longer
   the same yellow as Dandelion, and a new unused-for-now `microhabitat`
   column on all six species for Slice 4 to build on. **Note for
   balance, not yet simulated**: Bramble seeding several flowers per
   weighted pick makes its real meadow share noticeably higher than
   `weight: 18.0` alone suggests -- worth checking if it reads as
   over-abundant with more play. Full detail in
   `FORAGING_ECOLOGY_PLAN.md`. Dave still separately owes a
   hand-recorded `perf.gd` baseline from Slice 0 -- the only open item
   before this plan is cleanly caught up.
   Slice 4 onward (patchy meadow, local search, probabilistic choice,
   handling experience, finite pollen, proximity recruitment) stays
   scope-indexed only until Dave picks the next one to refine.
