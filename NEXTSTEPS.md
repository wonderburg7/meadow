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
4. **Foraging ecology plan -- Slices 5-8 built, needs Dave's hands-on
   check.** Full detail and results tables for every slice are in
   `FORAGING_ECOLOGY_PLAN.md`; all four pass `source_checks.py` (67/67)
   and `balance_tests.py` (15/15). Slices 5 and 6 are Dave-verified;
   Slices 7 (handling experience / adaptive constancy) and 8 (flower
   senescence) still need his hands-on check -- see
   `HANDS_ON_CHECKS.md`. `tools/run_scenario.py`'s hardcoded `log_dir()`
   still assumes `config/name="Meadow"`; this sandbox's `project.godot`
   says "Meadow - Claude", so headless scenario runs here need a small
   `log_dir()`-monkeypatch driver script (not part of the repo) -- will
   recur next session doing headless verification here.

   Slice 9 (proximity recruitment) is the last slice, still only
   scope-indexed -- no implementation-ready section written yet, and it
   should only replace the current mentor-consumption recruitment after
   an A/B comparison shows an actual improvement (see the plan's "Next
   physical step"). Pick it up once Slice 8's check is back.
5. **Starvation fix shipped 24 Aug, needs Dave's hands-on check.** The
   23 Aug real-session root cause (43/53 starvation deaths were foragers
   still hunting with an empty crop -- `sip_from_crop`'s self-rescue only
   fires once a bee is carrying nectar) is fixed:
   `bee_survival.gd::check_critical_recall`, called from `age_and_burn`,
   sends a bee still hunting (`SEEK_FLOWER`/`SEARCHING`/`TO_FLOWER`/
   `MOVE_TO_POINT`) with nothing to sip home once she drops below
   `GameConfig.critical_recall_threshold` (0.20 of capacity, a starting
   guess -- not simulation-swept). A 150-day headless re-run of the
   "Thirty strong" setup went from 2 starvation deaths to 0 after the
   fix. Note: the original 23 Aug log itself no longer exists in this
   sandbox (it was on Dave's own machine), so this was a fresh re-run
   against the same starting setup, not a direct diff of that log.
   Check added to `HANDS_ON_CHECKS.md`.
