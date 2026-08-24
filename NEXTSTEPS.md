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
   `FORAGING_ECOLOGY_PLAN.md`; summary of where things stand:
   - **Slice 5 (local search):** `nearest_flower` takes a radius,
     `bee.local_search_anchor` tracks and drifts, `State.SEARCHING`
     flies an expanding spiral when nothing's in sight.
     `forage_perception_radius` (locked at 320 after Dave's playtest
     read it as too generous, down from a simulation-swept 400) and
     `local_search_drift_rate` (0.3) are locked. **Dave-verified.**
   - **Slice 6 (probabilistic choice and memory):** heading-weighted
     flower choice (`probabilistic_choice_on`) and a small patch-memory
     ring buffer (`bee.known_patches`), both off by default.
     `probabilistic_choice_heading_weight` locked at 0.5. **Dave-verified**
     (a forager picks the one ahead of her over a nearer one behind, and
     returns to a known patch on a later search).
   - **Slice 7 (handling experience and adaptive constancy):**
     `handling_experience_on` (faster handling with practice) and
     `adaptive_constancy_on` (a continuous per-species confidence score,
     separate from the existing `floral_constancy_on` pin), both off by
     default. Locked at their provisional defaults. **Still needs Dave's
     hands-on check** -- watch a forager get visibly quicker at a
     familiar species, and watch an unpinned forager gravitate toward
     whatever's been paying off (only visible with Weighted flower choice
     also on).
   - **Slice 8 (flower senescence):** a flower's recharge slows as it
     nears the end of its life (`flower_senescence_on`, floor 0.3), off
     by default -- most of the slice's original "finite pollen and
     ecological time" title turned out to already exist (pollen, flower
     lifespan and season windows were all already built), so this slice
     was scoped down to just senescence per Dave's steer, skipping a
     day/night mechanic he judged unnecessary. Simulated single-seed
     on/off: flower_visits down 20%, stall_recoveries up 42%, deaths
     flat -- a real, one-directional effect, not swept further per the
     small-batch steer. **Still needs Dave's hands-on check** -- watch an
     old flower stay half-drained longer than a young one nearby.

   All four slices' checks pass (`source_checks.py` 67/67,
   `balance_tests.py` 15/15), `FUNCTION_MAP.md` is current, and every new
   toggle is off by default so nothing about today's default experience
   has changed. `tools/run_scenario.py`'s hardcoded `log_dir()` still
   assumes `config/name="Meadow"`; this sandbox's `project.godot` says
   "Meadow - Claude", so headless scenario runs here need a small
   `log_dir()`-monkeypatch driver script (not part of the repo) -- will
   recur next session doing headless verification here.

   **Root cause found from a real session log (23 Aug), remedy
   deliberately deferred until now.** Dave's real "Thirty strong"
   playthrough log had 580 death events, 53 starvation, 81% of them
   (43/53) died still hunting with an empty crop -- `bee_survival.gd`'s
   `sip_from_crop` self-rescue only fires if the bee is already carrying
   nectar. Bursts at day ~5-10 (young-colony ramp-up, unrelated to
   Slices 5-8), day ~51-63 (nothing-nearby wandering -- Slice 5's
   target), and day ~109-115 (foragers ranging too far from a depleted
   local patch). **Decision (Dave, 23 Aug):** draft the rest of the
   plan's slices first, then re-review starvation once they're all in,
   since some may remedy this incidentally. **That point has now been
   reached** -- Slices 5-8 are all built (5 and 6 Dave-verified; 7 and 8
   still owed). Next session, once 7 and 8's checks are back: either
   re-review starvation against this same log now that local
   search/probabilistic choice/senescence are all available, or start
   Slice 9 (proximity recruitment, the last slice, superseding today's
   entrance-wait mechanism only after a proven A/B win) -- Dave's call
   which comes first.
