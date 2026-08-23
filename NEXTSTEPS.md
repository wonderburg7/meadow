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
4. **Foraging ecology plan -- Slice 4 tasks 1-3 done, plus an unplanned
   field-size/overspill fix (23 Aug).** Task 1-3 detail unchanged from
   before, see `FORAGING_ECOLOGY_PLAN.md`'s "Slice 4 results so far"
   section. New this session, from Dave's own `perf.gd` screenshots at
   700/1000/1200 flowers plus a look at the meadow itself: he wanted more
   spread between good and bad patches, so `main.FLOWER_FIELD_HALF_SIZE`
   went from (1350, 990) to (2000, 1500) (matches the grass background,
   ~2.24x area) and `GameConfig.flower_count` from 500 to 800 (~1.6x --
   deliberately below the area increase, so density is lower, per his
   steer). That surfaced two follow-on bugs, both fixed: the grass
   polygon was a hardcoded 4000x3000 at a separately hand-picked offset,
   now out of sync with the field size it's meant to contain -- it's now
   derived from `FLOWER_FIELD_HALF_SIZE` plus a margin and centred on the
   actual hive marker (`world_building.gd::_build_meadow`). That alone
   didn't fully fix it -- the real cause of continuing overspill was
   microhabitat zones (task 2, last session): a zone's centre was picked
   anywhere in the field with no clearance kept for its own radius
   (300-450px), so a zone rolled near the boundary put flowers up to
   450px past the grass. Fixed with a new `_random_zone_centre()` that
   keeps the whole zone circle inside the field rectangle. Both fixes
   Dave-confirmed in-game (no overspill). Checks pass (66/66, 15/15).
   **Still open, from before**: Task 2's own claim (a species reading as
   more common in one part of the meadow) hasn't had its own hands-on
   check yet, separate from the overspill fix. Task 4 (full 5-seed
   on/off re-run) is still owed. Re-running the 500/750/1000 `perf.gd`
   comparison to see how much task 3 (lazy recharge) actually helped is
   also still owed -- this session's readings were at different counts
   (700/1000/1200) so aren't a like-for-like comparison to the pre-task-3
   table. Slice 5 onward (local search, probabilistic choice, handling
   experience, finite pollen, proximity recruitment) stays scope-indexed
   only until Dave picks the next one to refine.
