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
4. **Foraging ecology plan -- Slice 4 tasks 1-3 are now all done (22
   Aug).** Task 1: Dave's `perf.gd` "fps" star readings at flower_count
   500/750/1000 came in (flower work mean/p95 8.33/11.42ms ->
   14.08/17.54ms, whole-frame 27.32/36.70ms -> 34.89/42.39ms, 36.6fps ->
   28.7fps) -- a real, rising cost that clears the plan's own gate for
   task 3. Task 2 (microhabitat zones, built last session) is unchanged.
   Task 3 (lazy flower recharge): built this session, scoped to recharge
   only -- `flower.gd`'s `nectar_amount`/`pollen_amount` are now
   computed properties that catch up via `_sync_recharge()` on read/write
   instead of accumulating every frame for every flower. One deliberate
   approximation, chosen by Dave's own steer over the alternatives
   offered: uses the *instantaneous* `season_strength()` at read-time
   rather than an exact integral across the elapsed gap, since
   `season_strength()` turned out to be a time-varying `sin` curve, not
   constant -- bounded, capacity-capped drift only during a season's
   ramp-in/out, silent the rest of the year. Also fixed a
   `tests/source_checks.py` false positive along the way (GDScript 4's
   `set(value):` inline-property syntax was being flagged as an
   undefined call -- added `get`/`set` to the checker's keyword list).
   Checks pass (66/66, 15/15), a Godot boot showed only pre-existing
   warnings, and a `run_scenario.py --full` run gave identical
   flower-visit numbers to before the change (62/34). **Needs Dave's
   hands-on check, two things**: (a) open a run and confirm a species
   reads as more common in one part of the meadow than another (task 2,
   still outstanding from last session); (b) re-take the same
   500/750/1000 `perf.gd` readings from task 1 to see how much the
   flower-work numbers actually improved -- `run_scenario.py` has no
   headless path to `perf.gd`, so this can only be measured the same
   hands-on way task 1 was. Task 4 (full 5-seed on/off re-run) is still
   owed once both of those land. Full detail in
   `FORAGING_ECOLOGY_PLAN.md`'s "Slice 4 results so far" section.
   Slice 5 onward (local search, probabilistic choice, handling
   experience, finite pollen, proximity recruitment) stays
   scope-indexed only until Dave picks the next one to refine.
