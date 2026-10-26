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

1. **[Claude] SG-2 -- goals offered, completed and paid in Colony Runs and Scenarios, and saved**
   - Plan: `plans/now/short-term-goals.md` -- "SG-2 -- goals offered, completed and paid in Colony Runs and Scenarios, and saved"
   - Files: `scripts/short_term_goals.gd`, `scripts/year_winter.gd`, `scripts/main.gd`, `scripts/conditions.gd`, `scripts/hive.gd`, `scripts/bee_honey.gd`, `scripts/game_config.gd`, `scripts/save_game.gd`, `scripts/saving.gd`, `test_scenarios/sg2_short_term_goals.json`, `tests/test_sg2_short_term_goals.py`
   - Check: `python -m unittest tests.test_sg2_short_term_goals` passes (in a Colony Run with no pollen income the pollen goal is offered, and finishing it pays pollen worth about a quarter of a day's gross income; "Lay in honey for winter" can finish before the countdown's last day while the CR-2 winter milestone still waits for it; no goal is offered in Challenge 1 or 2; offered and finished goals survive save and restore; an old save loads with none); the sweep's table is recorded in this section; `.\tools\verify.ps1` is green
   - Proof: `absent: scripts/save_game.gd :: short_term_goals`
   - Next after: SG-3 -- the goals in the Goals drop-down, with progress, reward, star and Dismiss

2. **[Claude] GP-5 -- a Goals button in the second HUD row replaces the Goals header**
   - Plan: `plans/now/short-term-goals.md` -- "GP-5 -- a Goals button in the second HUD row replaces the Goals header"
   - Files: `scripts/hud.gd`, `tests/gp1_goals_dropdown_test.gd`, `tests/test_layout_regression.py`
   - Check: `python -m unittest tests.test_gp1_goals_dropdown` passes against `goals_button`; `python -m unittest tests.test_layout_regression` passes at the minimum width; `.\tools\verify.ps1` is green; Dave's hands-on check is filed
   - Proof: `absent: scripts/hud.gd :: goals_button`
   - Next after: none -- the Goals toggle move is complete

3. **[Claude] SG-4 -- opening milestones lead the player to the first worker**
   - Plan: `plans/now/short-term-goals.md` -- "SG-4 -- opening milestones lead the player to the first worker"
   - Files: `scripts/colony_milestones.gd`, `scripts/main.gd`, `tests/gp1_goals_dropdown_test.gd`, `tests/gp2_goal_favourites_test.gd`, `tests/test_conditions.py`
   - Check: `python -m unittest tests.test_gp1_goals_dropdown tests.test_gp2_goal_favourites tests.test_conditions` pass (a new run reads "Build your first cell", then the stores step, then the egg step, then "Raise your first worker", each within a second of its condition holding; a save without the three ids loads and ticks them); `.\tools\verify.ps1` is green; Dave's hands-on check is filed
   - Proof: `absent: scripts/colony_milestones.gd :: first_egg`
   - Next after: none -- the opening milestones are complete

4. **[Claude] AC-4 -- the Foraging card follows FR-2**
   - Plan: `plans/now/agent-context.md` -- "AC-4 -- the Foraging card follows FR-2"
   - Files: `GAME_MODEL.md`
   - Check: every `file.gd::name` and backticked field in the two cards is found by grep in the file it names; `python tools/check_docs.py` passes
   - Proof: `present: GAME_MODEL.md :: unlocks first;`
   - Next after: None -- plan complete

5. **[Claude] CT-1 -- sealed cells take a faint tone of what they hold**
   - Plan: `plans/now/cell-content-tones.md` -- "CT-1 -- sealed cells take a faint tone of what they hold"
   - Files: `scripts/hive_cell.gd`, `scripts/scenario_actions.gd`, `test_scenarios/ct1_cell_tones.json`, `tests/test_ct1_cell_tones.py`
   - Check: `python -m unittest tests.test_ct1_cell_tones` passes, asserting full honey and pollen tone at 0.28, quarter-full honey between 0.10 and 0.13 and an empty cell at 0; `.\tools\verify.ps1` is green. Hands-on: in the CT-1 scenario, the closed honey, pollen and nectar cells and the sealed bee bread cell each show a faint, different tint, and the full honey cell's tint is stronger than the quarter-full one's.
   - Proof: `absent: scripts/hive_cell.gd :: func content_tone(`
   - Next after: none -- `plans/now/cell-content-tones.md` is complete

### Codex lane

Up to five items, worked top to bottom. No file here may appear in the Claude
lane. Refilled by `python tools/refill_lane.py --top-up --lane Codex`.

1. **[Codex] CQ-R11 -- split flower seeding without changing RNG order**
   - Plan: `plans/now/code-health.md` -- "CQ-R11 -- split flower seeding without changing RNG order"
   - Files: `scripts/world_building.gd`, `FUNCTION_MAP.md`
   - Check: `python tools/equivalence.py test_scenarios/sf1_founding_flower_mix_test.json master`, `python tools/equivalence.py test_scenarios/pp4_seed_set.json master` and `python tools/equivalence.py test_scenarios/pp1_pollination_ledger.json master` report no differences; `python tools/prefinish.py` passes
   - Proof: `present: scripts/world_building.gd :: func _seed_flower(`
   - Next after: CQ-R6 -- extract the HUD bee-command rows

2. **[Codex] CQ-M6 -- name selection green and caste appearance**
   - Plan: `plans/now/code-health.md` -- "CQ-M6 -- name selection green and caste appearance"
   - Files: `scripts/world_draw.gd`, `scripts/bee.gd`, `scripts/death_marker.gd`, `scripts/flower.gd`, `scripts/hive_cell.gd`, `scripts/input_selection.gd`, `scripts/obstacle.gd`, `scripts/soil_block.gd`, `FUNCTION_MAP.md`
   - Check: `python -m unittest tests.test_sp11_cell_rim tests.test_sp9_soil_art tests.test_col9_drones` and `python tools/prefinish.py` pass; rendered selection alphas and caste sizes remain unchanged
   - Proof: `present: scripts/obstacle.gd :: selection_ring.default_color = Color(0.2, 1.0, 0.4, 0.95)`
   - Next after: CQ-M7 -- name world draw order

## Not in the queue, and why

One line each: the id, its plan, and the single thing it waits for.

- **AR-4** (`plans/now/alpha-route-evidence.md`) -- a scripted Colony Run reaches and records all five gates; waits for playable Tier 2 automation and the gyne route (Bee Bread finished 11 Oct 2026).
- **CQ-R6** (`plans/now/code-health.md`) -- extract the HUD bee-command rows after CQ-R11; waits for the Claude lane's GP-5 to release `scripts/hud.gd`.
- **CQ-M4** (`plans/now/code-health.md`) -- name Challenge level ids; waits for the Claude lane to release `scripts/save_game.gd` and `scripts/saving.gd`.
- **RR-12** (`plans/now/run-repairs.md`) -- a loaded run keeps its readout history (Dave, 16 Oct 2026); waits for ED-3, the last of the alpha chain, which shares `scripts/main.gd` and the save files.
- **SP-8a** (`plans/now/meadow-terrain.md`) -- the meadow floor drawn in blocks, with everything on it lifted (Dave, 12 Oct 2026); waits for ED-3, the last of the alpha chain (SG-2 to ED-3; WP-2 landed 21 Oct 2026 and WP-3 landed 22 Oct 2026), which shares `scripts/main.gd` and the save files (Dave, 16 Oct 2026).
- **HM-2** (`plans/now/hive-and-menu-art.md`) -- five top-bar buttons drawn from Dave's menu icons; waits for Dave to queue it (his call, 13 Oct 2026); its gated block is written.
- **HM-1** (`plans/now/hive-and-menu-art.md`) -- your hive and rival hives drawn from Dave's meadow hive art; waits for Dave to fit the large hive's layer 0 on its 54x41 canvas in Aseprite.
- **T2-7b** (`plans/now/tier-two.md`) -- the deferred tier-2 price sweep (first tier-2 purchase around day 5); waits for AR-4, whose arc buys a Honey worker, and is specified when it lands.
- **SG-3** (`plans/now/short-term-goals.md`) -- the goals shown in the Goals drop-down; waits for SG-2 (GP-2 landed 13 Oct 2026).
- **ED-1** (`plans/now/difficulty.md`) -- every bee has health; waits for SG-3 (Dave's order; FC-2 landed 17 Oct 2026, freeing the save files).
- **ED-2** (`plans/now/difficulty.md`) -- a run's difficulty and Easy's rules; waits for ED-1.
- **ED-3** (`plans/now/difficulty.md`) -- choosing Easy at run start; waits for ED-2.
- **The event director** (`plans/design/product-scope.md` §6.2) -- needs its own design pass before a slice can be written; `plans/reference/colony-diagnostics.md` is the model for what that pass produces.
- **FR-3** (`plans/now/forager-recruitment.md`) -- owning Auto-recruitment switches it on, passing species with Adaptive constancy; waits for PP-6, which shares `scripts/skills.gd`.
- **CQ-S1** (`plans/now/code-health.md`) -- Flower owns its save fields, the first entity to own its `to_save()`/`from_save()`; waits for the save slices of the alpha chain (SG-2, ED-1, ED-2, RR-12, SP-8a in `plans/now/drones.md`; WP-2 landed 21 Oct 2026 and WP-3 landed 22 Oct 2026) and ED-3 (Dave, 18 Oct 2026); CQ-S0's round-trip harness landed 22 Oct 2026.
- **CQ-R2** (`plans/now/code-health.md`) -- the first crisis moves out of `scripts/main.gd` into a new first_crisis.gd, touching the save files; waits, gated with CQ-S1, for the save slices of the alpha chain (SG-2, ED-1, ED-2, RR-12, SP-8a in `plans/now/drones.md`; WP-2 landed 21 Oct 2026) and ED-3 (Dave, 18 Oct 2026); its plan section is written when that gate clears.
- **CQ-R8** (`plans/now/code-health.md`) -- hud builders shortened (the designation button table); needs its section and block; prepare before CQ-T3.
- **CQ-T3** (`plans/now/code-health.md`) -- the UI scripts typed and the untyped warning made an error; needs its section and block after CQ-R8 (CQ-L2 released `tests/source_checks.py` 24 Oct 2026).
- **CQ-R10** (`plans/now/code-health.md`) -- input selection decomposed and sectioned; needs its section and block.
- **CQ-S2** (`plans/now/code-health.md`) -- HiveCell owns its save fields; waits for CQ-S1, which sets the `to_save()`/`from_save()` pattern and shares the save files.
- **FR-4** (`plans/now/forager-recruitment.md`) -- a headless assertion replaces the C-143 hands-on check; `scripts/scenario_actions.gd` was released 25 Oct 2026, but `tools/admission.py` reads C-143, the check it retires, as an unlanded slice, so its block stays `queue-gated` until admission ignores check ids.
- **RR-21** (`plans/now/run-repairs.md`) -- no ordinary rain in the first two days, and rain warnings in plain words; waits for SG-4, which owns `scripts/main.gd`.
- **RR-22** (`plans/now/run-repairs.md`) -- select a number of bees from a multi-selection; waits for GP-5 and SG-4, which own `scripts/hud.gd` and `scripts/main.gd`.

## Copy-paste prompts

Claude, implementing: `Implement the next slice.`

Codex, implementing: `Implement the next [Codex] slice: run tools/slice.ps1 start -Lane Codex, run the read command it prints, implement, run tools/verify.ps1, then close out per CHATGPT.md's "Risk-proportional closeout".`

Claude, integrating a high-risk Codex branch: `Integrate the finished Codex branch and close it out.`

Claude, after a hands-on pass: `I've done a hands-on pass. Here's what I found: <notes>. Update the checks, plans and queue.`

Claude, when a gate has cleared: `<what happened, e.g. "UI-F-2 has landed">. Move whatever it unblocks into its lane: clear its line under "Not in the queue, and why" (or open its fence from queue-gated to queue), then run python tools/refill_lane.py --top-up.`

Claude, when a lane is short and the backlog is dry (high reasoning): `The <Codex|Claude> lane is short and the backlog has nothing it can take. Plan the next <Codex|Claude> slices: write a queue block in the live plans for each one (it must touch no file in the other lane), put anything not ready yet under "Not in the queue, and why", then run python tools/refill_lane.py --top-up --lane <Codex|Claude>.`

Claude, looking ahead (high reasoning): `/plan-ahead [optional focus area]` -- surveys what needs a plan or slicing, ranks it, asks Dave the design questions and stores the answers in the plans.
