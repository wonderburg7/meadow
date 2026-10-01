# Next steps

<!-- CONTEXT: current-queue | LOAD: never whole; tools/slice.ps1 reads it -->

Do not read this file to find work: `tools/slice.ps1 start -Lane Claude|Codex`
claims your lane's first item and prints the one `read` command you need.
This file holds the queue only -- detail lives in each item's `Plan:` section,
and history in Git and `plans/archive/` (the old log is
`plans/archive/NEXTSTEPS_LOG_2026-09-17.md`). Rules: `.claude/rules/documentation.md`.

Neither lane is written by hand any more. A lane refills itself from the
backlog: the fenced `queue` blocks in the plans, each holding the exact item
its slice would be queued as (`tools/backlog.py`). `tools/slice.ps1 finish`
deletes the closing item and tops its lane back up towards five in the same
run. Five is a ceiling the backlog reaches when it has admissible work, not a
number this file is padded out to -- a lane the backlog cannot fill stays
short and says which candidate it refused and why.

## Next up

### Claude lane

Up to five items, worked top to bottom. No file here may appear in the Codex
lane. Refilled by `python tools/refill_lane.py --top-up --lane Claude`.

1. **[Claude] WO-1 -- winter's countdown opens by itself on a set day**
   - Plan: `plans/now/winter-onset.md` -- "WO-1 — winter's countdown opens by itself on a set day"
   - Files: `scripts/season.gd`, `scripts/game_config.gd`, `scripts/settings_catalogue.gd`, `scripts/scenario_actions.gd`, `test_scenarios/wo1_winter_onset_test.json`, `test_scenarios/alpha_arc_test.json`, `test_scenarios/a3_fixedfps_benchmark_test.json`, `test_scenarios/a5_actions_resolved_test.json`, `test_scenarios/a5_stop_when_test.json`, `test_scenarios/slice3_timescale_8x_test.json`, `test_scenarios/slice3_timescale_16x_test.json`, `test_scenarios/slice3_timescale_30x_test.json`, `test_scenarios/sv1_named_saves_test.json`
   - Check: `python tools/run_scenario.py test_scenarios/wo1_winter_onset_test.json` passes (countdown open by day 7, winter here by day 22 and not before day 21), the hands-on check is filed, and `tools/verify.ps1` is green
   - Proof: `absent: scripts/game_config.gd :: winter_countdown_start_day`
   - Next after: none -- plans/now/winter-onset.md is complete

### Codex lane

Up to five items, worked top to bottom. No file here may appear in the Claude
lane. Refilled by `python tools/refill_lane.py --top-up --lane Codex`.

1. **[Codex] UI-F-1 -- the game-over screen takes the theme and text scale**
   - Plan: `plans/now/ui-feedback.md` -- "UI-F-1 -- the game-over screen takes the theme and text scale"
   - Files: `scripts/game_over.gd`
   - Check: `grep -c "add_theme_font_size_override" scripts/game_over.gd` prints `0`, and `tools/verify.ps1` is green
   - Proof: `present: scripts/game_over.gd :: add_theme_font_size_override("font_size", 28)`
   - Next after: UI-F-3 -- comb cell labels follow text scale

2. **[Codex] UI-F-3 -- comb cell labels follow text scale**
   - Plan: `plans/now/ui-feedback.md` -- "UI-F-3 -- comb cell labels follow text scale"
   - Files: `scripts/hive_cell.gd`
   - Check: `grep -c "_label_font_size" scripts/hive_cell.gd` prints at least 2, and `tools/verify.ps1` is green
   - Proof: `present: scripts/hive_cell.gd :: info_label.add_theme_font_size_override("font_size", 9)`
   - Next after: UI-F-2 -- warnings carry a severity and a pending one is never lost

## Not in the queue, and why

One line each: the id, its plan, and the single thing it waits for.

- **BS-6** (`plans/now/brood-spine.md`) -- specified 1 Oct 2026; waits for BS-8 (Codex lane) to land, since both edit `scripts/run_availability.gd`.
- **L-16, L-17** (`plans/now/agent-lifecycle.md`) -- both edit `tools/slice.ps1`, whose suite skips off Windows, so each waits for a local Windows session: there, open its fence from `queue-gated` to `queue` and run `python tools/refill_lane.py --top-up --lane Claude` (plan review, 30 Sep 2026).
- **Colony Run definition** (`plans/design/product-scope.md` §6.2, "Next design pass") -- a high-reasoning design pass Dave put next on 30 Sep 2026; it waits for BS-4 to land, and it specifies PE-2.
- **PE-2** (`plans/design/product-scope.md` §6.2) -- the played pacing arc waits for the Colony Run definition, which specifies it.
- **GC-3** (`plans/now/gameplay-consistency.md`) -- raising `nectar_per_honey` to 4.0 (Dave, 30 Sep 2026) waits for PE-2's arc as the multi-season evidence `.claude/rules/simulation.md` requires.
- **Progression Phase B step 8 onwards, and Phase C** (`plans/design/progression.md`) -- step 7 is `plans/now/brood-spine.md`; step 8 waits for BS-4 to prove a tier-2 purchase in a run, then for the Colony Run definition, which Dave put first (30 Sep 2026).
- **Dr Gallerin guidance and the event director** (`plans/design/product-scope.md` §6.2) -- each needs its own design pass before a slice can be written; `plans/reference/colony-diagnostics.md` is the model for what that pass produces. The four goal layers now belong to the Colony Run definition (Dave, 30 Sep 2026).
- **The cell-art rings' last pixel** -- rides with the next slice that opens the cell-art drawing (C-20 in `docs/archive/HANDS_ON_CHECKS_ARCHIVE.md`).
## Copy-paste prompts

Claude, implementing: `Implement the next slice.`

Codex, implementing: `Implement the next [Codex] slice: run tools/slice.ps1 start -Lane Codex, run the read command it prints, implement, run tools/verify.ps1, then close out per CHATGPT.md's "Risk-proportional closeout".`

Claude, integrating a high-risk Codex branch: `Integrate the finished Codex branch and close it out.`

Claude, after a hands-on pass: `I've done a hands-on pass. Here's what I found: <notes>. Update the checks, plans and queue.`
