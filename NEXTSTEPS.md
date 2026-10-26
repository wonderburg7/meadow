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

1. **[Claude] AC-4 -- the Foraging card follows FR-2**
   - Plan: `plans/now/agent-context.md` -- "AC-4 -- the Foraging card follows FR-2"
   - Files: `GAME_MODEL.md`
   - Check: every `file.gd::name` and backticked field in the two cards is found by grep in the file it names; `python tools/check_docs.py` passes
   - Proof: `present: GAME_MODEL.md :: unlocks first;`
   - Next after: None -- plan complete

2. **[Claude] CT-1 -- sealed cells take a faint tone of what they hold**
   - Plan: `plans/now/cell-content-tones.md` -- "CT-1 -- sealed cells take a faint tone of what they hold"
   - Files: `scripts/hive_cell.gd`, `scripts/scenario_actions.gd`, `test_scenarios/ct1_cell_tones.json`, `tests/test_ct1_cell_tones.py`
   - Check: `python -m unittest tests.test_ct1_cell_tones` passes, asserting full honey and pollen tone at 0.28, quarter-full honey between 0.10 and 0.13 and an empty cell at 0; `.\tools\verify.ps1` is green. Hands-on: in the CT-1 scenario, the closed honey, pollen and nectar cells and the sealed bee bread cell each show a faint, different tint, and the full honey cell's tint is stronger than the quarter-full one's.
   - Proof: `absent: scripts/hive_cell.gd :: func content_tone(`
   - Next after: none -- `plans/now/cell-content-tones.md` is complete

3. **[Claude] DR-2 -- the cell popup's drone box**
   - Plan: `plans/now/drones.md` -- "DR-2 -- the cell popup's drone box"
   - Files: `scripts/hud.gd`, `scripts/main.gd`, `scripts/nursery_panel.gd`, `scripts/orders_zones.gd`, `tests/test_layout_regression.py`
   - Check: `tests/test_layout_regression.py` passes with the popup's new row; `python -m unittest tests.test_display_text_golden` passes; `.\tools\verify.ps1` is green; Dave's hands-on check is filed in `checks/ready.md`
   - Proof: `absent: scripts/hud.gd :: cell_drone_requested`
   - Next after: None -- plan complete

4. **[Claude] PP-6 -- the sweep prices points and tier-3/4 so Gyne rearing is affordable after the first winter**
   - Plan: `plans/now/pollination.md` -- "PP-6 -- the sweep prices points and tier-3/4 so Gyne rearing is affordable after the first winter"
   - Files: `scripts/skills.gd`, `scripts/game_config.gd`, `test_scenarios/alpha_arc_test.json`, `tools/pacing_gates.py`, `tests/test_pacing_gates.py`
   - Check: `python -m unittest tests.test_pacing_gates` passes; `pacing_gates.py` reports the day Gyne rearing first becomes affordable in the reference Colony Run, and its median falls from the first winter's end to 11 days after it (days 42 to 52); the sweep's table is recorded in this section; `.\tools\verify.ps1` is green
   - Proof: `absent: tools/pacing_gates.py :: gyne_rearing_affordable`
   - Next after: none -- the pollination plan is complete; AR-4 in `plans/now/alpha-route-evidence.md` then starts in the Codex lane, and FR-3 in `plans/now/forager-recruitment.md` follows

5. **[Claude] RR-13 -- the pre-ferment warning shows 1.5 game days ahead and stands out**
   - Plan: `plans/now/run-repairs.md` -- "RR-13 -- the pre-ferment warning shows 1.5 game days ahead and stands out"
   - Files: `scripts/game_config.gd`, `scripts/settings_catalogue.gd`, `scripts/hive_cell.gd`, `tests/rr11_pre_fermented_test.gd`
   - Check: `python -m unittest tests.test_rr11_pre_fermented` passes with the boundary at 36 h; `python -m unittest tests.test_display_text_golden` passes; `.\tools\verify.ps1` is green; Dave's hands-on check is filed
   - Proof: `absent: scripts/hive_cell.gd :: Color(0.78, 0.86, 0.35)`
   - Next after: none -- the pre-ferment warning is complete

### Codex lane

Up to five items, worked top to bottom. No file here may appear in the Claude
lane. Refilled by `python tools/refill_lane.py --top-up --lane Codex`.

1. **[Codex] CQ-R10 -- decompose input selection**
   - Plan: `plans/now/code-health.md` -- "CQ-R10 -- decompose input selection"
   - Files: `scripts/input_selection.gd`, `FUNCTION_MAP.md`, `checks/ready.md`
   - Check: `python tools/equivalence.py test_scenarios/e1_placement_exclusion_test.json master`, `python tools/equivalence.py test_scenarios/hr2_click_view_switch_test.json master` and `python tools/equivalence.py test_scenarios/rr1_queen_builds_test.json master` report no differences; `python tools/prefinish.py` passes; a hands-on check covers the untested inputs
   - Proof: `present: scripts/input_selection.gd :: func _unhandled_input(event: InputEvent) -> void:`
   - Next after: CQ-R14 -- split the mid-size visual builders

2. **[Codex] CQ-R14 -- split the mid-size visual builders**
   - Plan: `plans/now/code-health.md` -- "CQ-R14 -- split the mid-size visual builders"
   - Files: `scripts/main_menu.gd`, `scripts/challenge_complete.gd`, `scripts/flower.gd`, `scripts/bee.gd`, `FUNCTION_MAP.md`
   - Check: `python -m unittest tests.test_sp1_pixel_sprite tests.test_ho15_menu_hex_fit` and `python tools/equivalence.py test_scenarios/sf1_founding_flower_mix_test.json master` pass with no differences; `python tools/prefinish.py` passes
   - Proof: `present: scripts/flower.gd :: func setup(index: int, starting_age: float = -1.0) -> void:`
   - Next after: CQ-M6 -- name selection green and caste appearance (gated on CT-1)

## Not in the queue, and why

One line each: the id, its plan, and the single thing it waits for.

- **AR-4** (`plans/now/alpha-route-evidence.md`) -- a scripted Colony Run reaches and records all five gates; waits for playable Tier 2 automation and the gyne route (Bee Bread finished 11 Oct 2026).
- **CQ-R6** (`plans/now/code-health.md`) -- extract the HUD bee-command rows; waits for the Claude lane's GP-5 to release `scripts/hud.gd`.
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
- **CQ-S1** (`plans/now/code-health.md`) -- Flower owns its save fields, the first entity to own its `to_save()`/`from_save()`; waits for the save slices of the alpha chain (ED-1, ED-2, RR-12, SP-8a in `plans/now/drones.md`; WP-2 landed 21 Oct 2026 and WP-3 landed 22 Oct 2026) and ED-3 (Dave, 18 Oct 2026); CQ-S0's round-trip harness landed 22 Oct 2026.
- **CQ-R2** (`plans/now/code-health.md`) -- the first crisis moves out of `scripts/main.gd` into a new first_crisis.gd, touching the save files; waits, gated with CQ-S1, for the save slices of the alpha chain (ED-1, ED-2, RR-12, SP-8a in `plans/now/drones.md`; WP-2 landed 21 Oct 2026) and ED-3 (Dave, 18 Oct 2026); its plan section is written when that gate clears.
- **CQ-R8** (`plans/now/code-health.md`) -- hud builders shortened (the designation button table); needs its section and block; prepare before CQ-T3.
- **CQ-T3** (`plans/now/code-health.md`) -- the UI scripts typed and the untyped warning made an error; needs its section and block after CQ-R8 (CQ-L2 released `tests/source_checks.py` 24 Oct 2026).
- **CQ-M6** (`plans/now/code-health.md`) -- selection green and caste appearance named; waits for CT-1 to release `scripts/hive_cell.gd`.
- **CQ-M7** (`plans/now/code-health.md`) -- world draw order named; waits for CQ-M6 and then needs its section and block.
- **CQ-S2** (`plans/now/code-health.md`) -- HiveCell owns its save fields; waits for CQ-S1, which sets the `to_save()`/`from_save()` pattern and shares the save files.
- **FR-4** (`plans/now/forager-recruitment.md`) -- a headless assertion replaces the C-143 hands-on check; `scripts/scenario_actions.gd` was released 25 Oct 2026, but `tools/admission.py` reads C-143, the check it retires, as an unlanded slice, so its block stays `queue-gated` until admission ignores check ids.
- **RR-21** (`plans/now/run-repairs.md`) -- no ordinary rain in the first two days, and rain warnings in plain words; waits for which owns `scripts/main.gd`.
- **RR-22** (`plans/now/run-repairs.md`) -- select a number of bees from a multi-selection; waits for GP-5 and which own `scripts/hud.gd` and `scripts/main.gd`.

## Copy-paste prompts

Claude, implementing: `Implement the next slice.`

Codex, implementing: `Implement the next [Codex] slice: run tools/slice.ps1 start -Lane Codex, run the read command it prints, implement, run tools/verify.ps1, then close out per CHATGPT.md's "Risk-proportional closeout".`

Claude, integrating a high-risk Codex branch: `Integrate the finished Codex branch and close it out.`

Claude, after a hands-on pass: `I've done a hands-on pass. Here's what I found: <notes>. Update the checks, plans and queue.`

Claude, when a gate has cleared: `<what happened, e.g. "UI-F-2 has landed">. Move whatever it unblocks into its lane: clear its line under "Not in the queue, and why" (or open its fence from queue-gated to queue), then run python tools/refill_lane.py --top-up.`

Claude, when a lane is short and the backlog is dry (high reasoning): `The <Codex|Claude> lane is short and the backlog has nothing it can take. Plan the next <Codex|Claude> slices: write a queue block in the live plans for each one (it must touch no file in the other lane), put anything not ready yet under "Not in the queue, and why", then run python tools/refill_lane.py --top-up --lane <Codex|Claude>.`

Claude, looking ahead (high reasoning): `/plan-ahead [optional focus area]` -- surveys what needs a plan or slicing, ranks it, asks Dave the design questions and stores the answers in the plans.
