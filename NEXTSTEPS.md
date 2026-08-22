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
4. **Foraging ecology plan -- Slices 0 and 1 both done, awaiting Dave's
   hands-on check.** `foraging_stats.gd` (trip timing, flowers/trip,
   empty-return rate, per-species breakdown) plus a new read-only
   Foraging panel (press **G**, or the button next to Nursery) --
   `source_checks.py`/`balance_tests.py` pass and a Godot boot is clean,
   but nothing headless can see `foraging_stats.gd`'s numbers (it's
   never written to the `.jsonl` log), so this needs Dave to open a run
   with Auto scouting or Auto-recruitment on and sanity-check the panel
   against what he sees happening. Full detail in
   `FORAGING_ECOLOGY_PLAN.md`'s "Slice 1 results". Dave still separately
   owes a hand-recorded `perf.gd` baseline from Slice 0 (no
   `mcp__godot__*` tools were available in that session). Slice 2
   onward (species registry, new species, patchy meadow, local search...)
   stays scope-indexed only until Dave picks the next one to refine.
