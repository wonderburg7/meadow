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

   **23 Aug, later same day -- root cause found from a real session log,
   remedy deliberately deferred.** Dave supplied the real
   `session_*.jsonl` from the "Thirty strong" playthrough (found in
   Downloads, not the userdata logs folder -- the latter only ever held
   short headless test runs with zero deaths). It has 580 real death
   events, 53 of them starvation, and points to a genuine gap:
   `bee_survival.gd`'s `sip_from_crop` (the self-rescue drink) only
   fires if the bee is carrying nectar -- a forager flying with an
   **empty crop** (still searching, hasn't found a flower) has no
   fallback at all, and 81% of the starvation deaths (43/53) died in
   `SEEK_FLOWER`/`TO_FLOWER`/`INSPECTING` -- i.e. still hunting, crop
   empty. Deaths came in three bursts, not a steady drip: day ~5-10 (6
   deaths, `food_stores` genuinely at 0.0 -- a young-colony ramp-up
   problem), day ~51-63 (40 deaths, peaking 58-61, alongside a
   season-boundary food dip from ~2,134 to ~1,152 despite 150+ healthy
   bees), and day ~109-115 (7 deaths, food_stores huge at 23k+, but
   `unique_flowers_visited` up to ~6,900 -- individual foragers ranging
   too far from a depleted local patch). Caveat: this log's config
   snapshot has no `forage_perception_radius`/`local_search_drift_rate`
   keys, so it predates Slice 5's local search/spiral -- bursts 2 and 3
   are exactly the "nothing nearby, wanders" scenario Slice 5 targets
   and may already be partly fixed; burst 1 (empty hive stores in the
   first ~10 days) is unrelated to Slice 5 and is a separate gap.
   **Decision (Dave, 23 Aug):** don't fix this now -- keep drafting the
   rest of `FORAGING_ECOLOGY_PLAN.md`'s remaining slices first (6
   onward: probabilistic choice, handling experience, finite pollen,
   proximity recruitment), then re-review starvation once all of them
   are in, since some may remedy this incidentally.

   **23 Aug, later still -- Slice 6 (probabilistic choice and memory)
   built and simulated.** Both pieces Dave steered on: heading-weighted
   probabilistic flower choice applies everywhere `nearest_flower` is
   called (not just while `SEARCHING`), and patch memory is the small
   ring-buffer option (`bee.known_patches`, max 4, consulted only when a
   search bout gives up), with the fuller per-patch quality score
   explicitly deferred rather than built. Both gated behind a new
   `probabilistic_choice_on` toggle, off by default -- a toggled-off run
   is byte-for-byte the old nearest-wins code. `probabilistic_choice_heading_weight`
   simulation-swept and locked at 0.5 (the provisional value, confirmed
   best on seed 12345 and cross-checked on seed 7 -- see
   `FORAGING_ECOLOGY_PLAN.md`'s Slice 6 results). `known_patches_max`/
   `known_patch_min_spacing` weren't separately swept, flagged rather
   than silently left. **Needs Dave's hands-on check**: watch a forager
   pick the flower ahead of her over a nearer one behind, and watch her
   head back to a known patch on a later search. Also found (not a Slice
   6 bug): this sandbox's `project.godot` has `config/name="Meadow -
   Claude"`, so `tools/run_scenario.py`'s hardcoded `log_dir()` looks in
   the wrong `app_userdata` folder -- every run was actually completing
   and writing correctly, just to a differently-named folder. Worked
   around with a local driver script rather than editing the tool; will
   recur next session doing headless verification in this sandbox.

   **23 Aug, later still -- visibility cues added, both hands-on checks
   were genuinely blocked before this.** Dave flagged he had no way to
   see a bee's facing direction (needed for the Slice 6 heading-choice
   check) or to spot a SEARCHING bee at a glance (needed for Slice 5's
   spiral check) -- confirmed real gaps, not oversights: `bee.heading`
   (`bee.gd:244`) was tracked purely as scoring data for
   `bee_foraging.gd`'s probabilistic choice, never drawn; `role_letter()`
   only ever showed N/P for foragers, so SEARCHING looked identical to
   SEEK_FLOWER/TO_FLOWER outside the selection panel's
   `task_description()` text. Both fixed, presentation-only (rule 3, same
   `is_on_screen` gating as `_update_label`/`_update_alarm_ring`): a
   bright white wedge on every outdoor forager now points along
   `bee.heading`, and a pulsing purple ring now shows only in
   `State.SEARCHING`. `source_checks.py`/`balance_tests.py` pass, a
   `mcp__godot__run_project` boot is clean, a `run_scenario.py --full`
   run against `c2_no_jelly_cell_test.json` completed with no errors.
   **Still needs Dave's hands-on check**, now that both cues actually
   exist to look at.

   Also: the `perf.gd` "bee_search" reading was never actually taken --
   `NEXTSTEPS`'s "I thought I'd submitted it" turned out to be a false
   memory, confirmed against this file and the plan's own Slice 5
   results (only the two `GameConfig` sweeps are recorded, no fps-star
   numbers). Still Dave's hands-on only, no headless path exists to it.
   Separately, the perf/diagnostic tooling itself got extended this same
   session (Dave's request, not part of Slice 5/6): `perf.gd` gained a
   cheap `percentile_ms()` reader, the "fps" star's breakdown line
   (`perf_breakdown.gd`) now shows a p95-worst-frame figure alongside the
   existing average/worst lines, the fps corner readout
   (`hud.gd::update_fps`) now folds in game speed, and
   `diagnostic_log.gd`'s hourly snapshot gained a `"performance"` block
   (fps, game_speed, paused always; `worst_frame_ms`/`p95_worst_frame_ms`/
   top-8 section averages only when the "fps" star is already on) so a
   `bee_search` reading (or any other) can be read back from a log
   afterwards instead of needing to be caught live. Verified landing
   correctly in a real `run_scenario.py --full` snapshot line.
   `FUNCTION_MAP.md` regenerated (`bee.gd`, `hud.gd`, `main.gd` touched).

   **23 Aug, later still -- Dave's hands-on check for Slices 5 and 6,
   both confirmed good.** Foragers pick the flower ahead of them over a
   nearer one behind more often than not (Slice 6), and the SEARCHING
   spiral behaves as expected (Slice 5). The owed `bee_search` perf
   reading was taken (verbally reported); it prompted one steer --
   `forage_perception_radius` read as too generous, taken down ~20%
   (400 -> 320, `game_config.gd`), a playtest-informed adjustment rather
   than a fresh simulation sweep. Both check suites re-run clean (66/66,
   15/15). Slices 5 and 6 are now fully closed. Full detail in
   `FORAGING_ECOLOGY_PLAN.md`'s "Dave's hands-on check, Slices 5 and 6"
   section.

   **23 Aug, later still -- Slice 7 (handling experience and adaptive
   constancy) built.** Both design questions Dave steered on: handling
   experience is faster-only (no yield change), and adaptive constancy is
   a new toggle alongside the existing `floral_constancy_on` pin, not a
   replacement. Two `GameConfig` toggles (`handling_experience_on`,
   `adaptive_constancy_on`), both off by default, plus per-bee
   `species_experience`/`species_confidence` dictionaries, save/load,
   settings-panel entries, and diagnostic-snapshot fields. Simulated
   before locking (rule 4): handling experience shows a real, flagged
   trade-off (fewer flower_visits, more stall_recoveries, still in normal
   range) at its provisional defaults; adaptive constancy showed *zero*
   effect at any weight in the first sweep (diagnosed, not shrugged
   off) -- it's mathematically inert whenever `floral_constancy_on` has
   already pinned a bee to one species, since a uniform per-candidate
   rescale can't change weighted-random odds. Confirmed working (+18%
   flower_visits) once re-tested without the species pin. Also fixed two
   pre-existing gaps found while wiring this up: `probabilistic_choice_on`
   (Slice 6) had no settings-panel toggle at all, and eight Slice 5/6
   `GameConfig` keys were missing from `save_game.gd`'s `SAVED_SETTINGS`
   list (same "missing from this list" bug shape as three earlier finds
   in this plan). `source_checks.py`/`balance_tests.py` pass (66/66,
   15/15), a `mcp__godot__run_project` boot is clean, `FUNCTION_MAP.md`
   regenerated. **Needs Dave's hands-on check** -- both new toggles plus
   Weighted flower choice are off by default, so nothing changes until
   he turns them on. Full detail in `FORAGING_ECOLOGY_PLAN.md`'s Slice 7
   section.

   Next session: once Slice 7's hands-on check is back, Slice 8 (finite
   pollen and ecological time) is next per the 23 Aug decision to draft
   the rest of the plan's slices before re-reviewing starvation -- see
   `FORAGING_ECOLOGY_PLAN.md`'s "Next physical step".
