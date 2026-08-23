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
4. **Foraging ecology plan -- Slice 5 (local search) built and
   simulated, needs Dave's hands-on check.** All five tasks done (23
   Aug): `nearest_flower` takes a radius; `bee.local_search_anchor`
   tracks and drifts; the new `State.SEARCHING` flies a real expanding
   spiral when nothing's in sight, with two real stall-watchdog bugs
   found and fixed along the way (see `FORAGING_ECOLOGY_PLAN.md`'s Slice
   5 results for the detail -- one made `stall_recoveries` spike to 500
   before the fixes); `forage_perception_radius` (400) and
   `local_search_drift_rate` (0.3) simulation-swept and locked; the full
   5-seed on/off re-run shows deaths flat and flower_visits close to
   Slice 4's baseline (on ≈235 vs ≈244, off actually up to ≈432 from
   ≈370). **Two things still owed, both Dave's hands-on only:** watch a
   foraging bee fly a widening search loop when nothing's immediately
   visible, and take the `perf.gd` "bee_search" reading at ~29 bees (no
   headless path to perf timing exists). `FUNCTION_MAP.md` regenerated.
   Slices 6 onward (probabilistic choice, handling experience, finite
   pollen, proximity recruitment) stay scope-indexed only, not yet
   refined -- pick the next one once Slice 5's hands-on check is back.
