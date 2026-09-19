# Next steps

<!-- CONTEXT: current-queue | LOAD: never whole; tools/slice.ps1 reads it -->

Do not read this file to find work: `tools/slice.ps1 start -Lane Claude|Codex`
claims your lane's first item and prints the one `read` command you need.
This file holds the queue only -- detail lives in each item's `Plan:` section,
and history in Git and `plans/archive/` (the old log is
`plans/archive/NEXTSTEPS_LOG_2026-09-17.md`). Rules: `.claude/rules/documentation.md`.

## Next up

### Claude lane

Up to five items, worked top to bottom. No file here may appear in the Codex lane.

1. **[Claude] C1F-1 -- each Challenge 1 stage sets up the world it starts from**
   - Plan: `plans/now/c1-followups.md` -- "C1F-1 — each Challenge 1 stage sets up the world it starts from"
   - Files: `scripts/challenge_stage_setup.gd`, `scripts/challenge_stages.gd`, `scripts/challenge_runner.gd`, `scripts/scenario_actions.gd`
   - Check: a new test_scenarios/c1f1_stage_setup_test.json steps forward to 1.19 and back to 1.1 and asserts each stage stays put for 2 seconds; it fails on master at the first retreat into a met goal
   - Proof: `absent: scripts/challenge_runner.gd :: ChallengeStageSetup`
   - Next after: C1F-2 -- a headless run proves the queen's pollen departure and no discard loop.

2. **[Claude] CB-1 -- measure where comb builders stand and how many work one site**
   - Plan: `plans/now/comb-builders.md` -- "CB-1 — measure where comb builders stand and how many work one site"
   - Files: `scripts/scenario_actions.gd`, `test_scenarios/cb1_comb_builders_per_site_test.json`
   - Check: two headless runs of the new fixture report identical per-site builder counts and stand points, and the delivery note names which of H1-H3 the numbers support
   - Proof: `absent: scripts/scenario_actions.gd :: builders_per_site`
   - Next after: CB-2 -- the fix CB-1 identifies.

3. **[Claude] L-13 -- closeout is one command, and the gates become actions**
   - Plan: `plans/now/agent-lifecycle.md` -- "L-13 — closeout is one command, and the gates become actions"
   - Files: `tools/slice.ps1`, `tests/test_two_lane_closeout.py`
   - Check: every injected-failure phase in `tests/test_slice_lifecycle.py` and `tests/test_two_lane_closeout.py` still resumes to a clean merge on master, a closeout over the fixture repository completes from `verify` to `merge` with no hand edit in between, and a journal written in the old phase order resumes without skipping a durable step
   - Proof: `absent: tools/slice.ps1 :: Invoke-SliceArchiveAndRefill`
   - Next after: L-12 -- a plan's slice section carries the queue lines it is refilled from, once its gate is met.

4. **[Claude] UI-Y -- toggleable panel background texture**
   - Plan: `plans/now/ui.md` -- "UI-Y — toggleable panel background texture"
   - Files: `scripts/ui_theme.gd`, `scripts/settings_catalogue.gd`, `scripts/session.gd`
   - Check: a hands-on pass with each theme palette (dark/light/high-contrast) -- set the new Appearance option to `comb`, then `grain`, then back to `flat`, confirm the panel edge and text position never move and text stays legible
   - Proof: `absent: scripts/settings_catalogue.gd :: panel_texture`
   - Next after: none -- UI-Y is complete.

### Codex lane

Up to five items, worked top to bottom. No file here may appear in the Claude lane.

1. **[Codex] SF-1 -- a new run's meadow starts with the season mix it will settle into**
   - Plan: `plans/now/season-feel.md` -- "SF-1 — a new run's meadow starts with the season mix it will settle into"
   - Files: `scripts/world_building.gd`, `scripts/flower.gd`, `scripts/flower_species.gd`, `scripts/diagnostic_log.gd`, `test_scenarios/sf1_founding_flower_mix_test.json`
   - Check: the fixture's run summary at Season days 5 -- the day-0 out-of-season share of flowers is within 5 points of the day-5 share and below 15%, asserted in a Python test that reads the two new DiagnosticLog counters; hands-on check C-25 moves to ready
   - Proof: `present: scripts/flower_species.gd :: static func season_weight(species: Dictionary) -> float:`
   - Next after: none -- season-feel is complete.

2. **[Codex] PERF-1 -- measure `find_food_cell` before changing it**
   - Plan: `plans/reference/technical-audit.md` -- "PERF-1 — measure `find_food_cell` before changing it"
   - Files: `scripts/hive.gd`, `docs/PERFORMANCE_BASELINE.md`
   - Check: two runs of `test_scenarios/recommendation_slice0_baseline.json` at `--fixed-fps 60` with perf enabled report the new `hive_find_food` section within 10% of each other, and the delivery note says whether it is trivial or worth a follow-up slice, with the numbers
   - Proof: `absent: scripts/hive.gd :: hive_find_food`
   - Next after: none -- technical-audit section A is complete unless PERF-1's numbers open a follow-up.

## Not in the queue, and why

One line each: the id, its plan, and the single thing it waits for.

- **CB-2** (`plans/now/comb-builders.md`) -- its cause is what CB-1 measures, and its fix waits for G2 to finish with the `bee_*.gd` modules.
- **C1F-2** (`plans/now/c1-followups.md`) -- starts its run through C1F-1's stage setup.
- **F1s, F2s, G3** (`plans/design/architecture-review.md`) -- F1s needs `scripts/scenario_actions.gd` clear of the Claude lane; F2s follows F1s; G3 follows F2s now that G2 has shipped.
- **Progression Phase B step 6 onwards** (`plans/design/progression.md`) -- wants a clear run of the UI work above.
- **L-12** (`plans/now/agent-lifecycle.md`) -- gated until `tools/session_cost.py --stops` shows the refill step among the two most frequent over ten or more stops.
- **The cell-art rings' last pixel** -- rides with the next slice that opens the cell-art drawing (C-20 in `docs/archive/HANDS_ON_CHECKS_ARCHIVE.md`).
## Copy-paste prompts

Claude, implementing: `Implement the next slice.`

Codex, implementing: `Implement the next [Codex] slice: run tools/slice.ps1 start -Lane Codex, run the read command it prints, implement, run tools/verify.ps1, then close out per CHATGPT.md's "Risk-proportional closeout".`

Claude, integrating a high-risk Codex branch: `Integrate the finished Codex branch and close it out.`

Claude, after a hands-on pass: `I've done a hands-on pass. Here's what I found: <notes>. Update the checks, plans and queue.`
