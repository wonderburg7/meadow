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

1. **[Claude] PP-9 -- the reference route reaches Gyne rearing, then the sweep prices it after the first winter**
   - Plan: `plans/now/pollination.md` -- "PP-9 -- the reference route reaches Gyne rearing, then the sweep prices it after the first winter"
   - Files: `scripts/skills.gd`, `scripts/game_config.gd`, `test_scenarios/alpha_arc_test.json`, `tools/pacing_gates.py`, `tests/test_pacing_gates.py`
   - Check: the weak baseline's cause is recorded in this section; `python -m unittest tests.test_pacing_gates tests.test_pp6_gyne_rearing_affordable` passes; over 3 seeds of the reference Colony Run, `pacing_gates.py`'s Gyne-rearing row reports a median day from the first winter's end to 11 days after it (days 42 to 52); the sweep's table is recorded in this section; `.\tools\verify.ps1` is green
   - Proof: `absent: test_scenarios/alpha_arc_test.json :: skill.foraging.pollinator_points`
   - Next after: none -- the pollination plan is complete; AR-4 in `plans/now/alpha-route-evidence.md` then starts in the Codex lane, and FR-3 in `plans/now/forager-recruitment.md` follows

2. **[Claude] RR-19 -- comb workers seal and unseal cells over time**
   - Plan: `plans/now/run-repairs.md` -- "RR-19 -- comb workers seal and unseal cells over time"
   - Files: `scripts/hive_cell.gd`, `scripts/orders_zones.gd`, `scripts/actions.gd`, `scripts/bee_building.gd`, `scripts/hive.gd`, `scripts/game_config.gd`, `scripts/settings_catalogue.gd`, `scripts/save_game.gd`, `scripts/saving.gd`, `test_scenarios/rr19_sealing_stocked.json`, `tests/test_rr19_sealing.py`, `tests/test_save_migrations.py`
   - Check: `python -m unittest tests.test_rr19_sealing` passes (Seal on a full cell leaves it open until a comb worker has spent 15 s, then closed; Open takes 5 s; "Fill then seal" seals a cell filled by honey conversion, jelly and brood; winter's close is instant); `python -m unittest tests.test_save_migrations` passes with an old save; the before/after `alpha_arc_test.json` outputs are recorded in the closeout; `.\tools\verify.ps1` is green; Dave's hands-on check is filed
   - Proof: `absent: scripts/game_config.gd :: cell_seal_seconds`
   - Next after: none -- cell sealing is complete

3. **[Claude] RR-20 -- a comb worker carrying a body visibly leaves, stays out one second, and comes back**
   - Plan: `plans/now/run-repairs.md` -- "RR-20 -- a comb worker carrying a body visibly leaves, stays out one second, and comes back"
   - Files: `scripts/bee_building.gd`, `scripts/bee_movement.gd`, `scripts/game_config.gd`, `scripts/settings_catalogue.gd`, `tests/t2_4b_bodies_test.gd`, `tests/t2_13_carried_body_test.gd`
   - Check: `python -m unittest tests.test_t2_4b_bodies tests.test_t2_13_carried_body` pass (the body-carrying bee is outside the hive for 1 s then inside again); `.\tools\verify.ps1` is green; Dave's hands-on check is filed
   - Proof: `absent: scripts/game_config.gd :: body_drop_seconds`
   - Next after: none -- the body drop is complete

4. **[Claude] RR-21 -- no ordinary rain in a run's first two days, and rain warnings say when in plain words**
   - Plan: `plans/now/run-repairs.md` -- "RR-21 -- no ordinary rain in a run's first two days, and rain warnings say when in plain words"
   - Files: `scripts/main.gd`, `scripts/game_config.gd`, `scripts/settings_catalogue.gd`, `tests/test_fc2_first_crisis.py`, `tests/test_rr21_rain_free_days.py`
   - Check: `python -m unittest tests.test_rr21_rain_free_days tests.test_fc2_first_crisis tests.test_display_text_golden` pass (no random rain before day 2 even at a chance of 1.0; rain rolls again after; the first crisis still fires; warnings read "soon", "later today", "by the end of the day" or "tomorrow"); the before/after `alpha_arc_test.json` outputs are recorded in the closeout; `.\tools\verify.ps1` is green; Dave's hands-on check is filed
   - Proof: `absent: scripts/game_config.gd :: rain_free_days`
   - Next after: none -- the rain rule is complete

5. **[Claude] RR-22 -- select a number of bees from a multi-selection**
   - Plan: `plans/now/run-repairs.md` -- "RR-22 -- select a number of bees from a multi-selection"
   - Files: `scripts/hud.gd`, `scripts/input_selection.gd`, `scripts/main.gd`, `tests/test_layout_regression.py`, `tests/rr22_select_n_test.gd`, `tests/test_rr22_select_n.py`
   - Check: `python -m unittest tests.test_rr22_select_n` passes (n is clamped to 1..selection size, `>>` steps by 5, Select keeps n bees, youngest and oldest keep the one bee with the least or greatest age); `python -m unittest tests.test_layout_regression` passes; `.\tools\verify.ps1` is green; Dave's hands-on check is filed
   - Proof: `absent: scripts/hud.gd :: select_youngest`
   - Next after: none -- multi-selection narrowing is complete

### Codex lane

Up to five items, worked top to bottom. No file here may appear in the Claude
lane. Refilled by `python tools/refill_lane.py --top-up --lane Codex`.

1. **[Codex] CQ-R14 -- split the mid-size visual builders**
   - Plan: `plans/now/code-health.md` -- "CQ-R14 -- split the mid-size visual builders"
   - Files: `scripts/main_menu.gd`, `scripts/challenge_complete.gd`, `scripts/flower.gd`, `scripts/bee.gd`, `FUNCTION_MAP.md`
   - Check: `python -m unittest tests.test_sp1_pixel_sprite tests.test_ho15_menu_hex_fit` and `python tools/equivalence.py test_scenarios/sf1_founding_flower_mix_test.json master` pass with no differences; `python tools/prefinish.py` passes
   - Proof: `present: scripts/flower.gd :: func setup(index: int, starting_age: float = -1.0) -> void:`
   - Next after: CQ-R6 -- extract the HUD bee-command rows

2. **[Codex] CQ-R6 -- extract the HUD bee-command rows**
   - Plan: `plans/now/code-health.md` -- "CQ-R6 -- extract the HUD bee-command rows"
   - Files: `scripts/hud.gd`, `scripts/hud_command_rows.gd`, `FUNCTION_MAP.md`
   - Check: `python -m unittest tests.test_layout_regression tests.test_hc8_tray_first_open tests.test_hc16_tray_reselect` and `python tools/prefinish.py` pass; a hands-on check covers the command buttons
   - Proof: `present: scripts/hud.gd :: func _rebuild_role_controls(`
   - Next after: CQ-M5a -- name every CanvasLayer in scripts/canvas_layers.gd

3. **[Codex] CQ-M5a -- name every CanvasLayer in `canvas_layers.gd`**
   - Plan: `plans/now/code-health.md` -- "CQ-M5a -- name every CanvasLayer in `canvas_layers.gd`"
   - Files: `scripts/canvas_layers.gd`, `scripts/main_menu.gd`, `scripts/challenge_complete.gd`, `scripts/game_over.gd`, `scripts/debug_panel.gd`, `scripts/saves_panel.gd`, `scripts/gallerin_panel.gd`, `scripts/skill_tree_panel.gd`, `plans/reference/ui-rules.md`, `FUNCTION_MAP.md`
   - Check: `python -m unittest tests.test_ho15_menu_hex_fit tests.test_layout_regression` and `python tools/prefinish.py` pass; `git grep -nE "layer = [0-9]|:= 14$" -- scripts/main_menu.gd scripts/challenge_complete.gd scripts/game_over.gd scripts/debug_panel.gd scripts/saves_panel.gd scripts/gallerin_panel.gd scripts/skill_tree_panel.gd` finds nothing
   - Proof: `present: scripts/game_over.gd :: layer = 25`
   - Next after: CQ-M5b -- the last CanvasLayer readers and the bare-layer source check

## Not in the queue, and why

One line each: the id, its plan, and the single thing it waits for.

- **AR-4** (`plans/now/alpha-route-evidence.md`) -- a scripted Colony Run reaches and records all five gates; waits for playable Tier 2 automation and the gyne route (Bee Bread finished 11 Oct 2026).
- **CQ-M5b** (`plans/now/code-health.md`) -- the last CanvasLayer readers and the bare-layer source check; waits for RR-21 to release `scripts/main.gd` and the Jules J-14 branch to settle `scripts/game_panel.gd`.
- **CQ-M4** (`plans/now/code-health.md`) -- name Challenge level ids; waits for the Claude lane to release `scripts/save_game.gd` and `scripts/saving.gd`.
- **RR-12** (`plans/now/run-repairs.md`) -- a loaded run keeps its readout history (Dave, 16 Oct 2026); waits for ED-3, the last of the alpha chain, which shares `scripts/main.gd` and the save files.
- **SP-8a** (`plans/now/meadow-terrain.md`) -- the meadow floor drawn in blocks, with everything on it lifted (Dave, 12 Oct 2026); waits for ED-3, the last of the alpha chain (SG-3 to ED-3; WP-2 landed 21 Oct 2026, WP-3 landed 22 Oct 2026 and SG-2 landed 26 Oct 2026), which shares `scripts/main.gd` and the save files (Dave, 16 Oct 2026).
- **HM-2** (`plans/now/hive-and-menu-art.md`) -- five top-bar buttons drawn from Dave's menu icons; waits for Dave to queue it (his call, 13 Oct 2026); its gated block is written.
- **HM-1** (`plans/now/hive-and-menu-art.md`) -- your hive and rival hives drawn from Dave's meadow hive art; waits for Dave to fit the large hive's layer 0 on its 54x41 canvas in Aseprite.
- **T2-7b** (`plans/now/tier-two.md`) -- the deferred tier-2 price sweep (first tier-2 purchase around day 5); waits for AR-4, whose arc buys a Honey worker, and is specified when it lands.
- **ED-1** (`plans/now/difficulty.md`) -- every bee has health; waits for SG-3 (Dave's order; FC-2 landed 17 Oct 2026, freeing the save files).
- **ED-2** (`plans/now/difficulty.md`) -- a run's difficulty and Easy's rules; waits for ED-1.
- **ED-3** (`plans/now/difficulty.md`) -- choosing Easy at run start; waits for ED-2.
- **The event director** (`plans/design/product-scope.md` §6.2) -- needs its own design pass before a slice can be written; `plans/reference/colony-diagnostics.md` is the model for what that pass produces.
- **FR-3** (`plans/now/forager-recruitment.md`) -- owning Auto-recruitment switches it on, passing species with Adaptive constancy; waits for PP-9 (the sweep Dave split from 26 Oct 2026), which shares `scripts/skills.gd`.
- **CQ-S1** (`plans/now/code-health.md`) -- Flower owns its save fields, the first entity to own its `to_save()`/`from_save()`; waits for the save slices of the alpha chain (ED-1, ED-2, RR-12, SP-8a in `plans/now/drones.md`; WP-2 landed 21 Oct 2026 and WP-3 landed 22 Oct 2026) and ED-3 (Dave, 18 Oct 2026); CQ-S0's round-trip harness landed 22 Oct 2026.
- **CQ-R2** (`plans/now/code-health.md`) -- the first crisis moves out of `scripts/main.gd` into a new first_crisis.gd, touching the save files; waits, gated with CQ-S1, for the save slices of the alpha chain (ED-1, ED-2, RR-12, SP-8a in `plans/now/drones.md`; WP-2 landed 21 Oct 2026) and ED-3 (Dave, 18 Oct 2026); its plan section is written when that gate clears.
- **CQ-R8** (`plans/now/code-health.md`) -- hud builders shortened (the designation button table); needs its section and block; prepare before CQ-T3.
- **CQ-T3** (`plans/now/code-health.md`) -- the UI scripts typed and the untyped warning made an error; needs its section and block after CQ-R8 (CQ-L2 released `tests/source_checks.py` 24 Oct 2026).
- **CQ-M6** (`plans/now/code-health.md`) -- selection green and caste appearance named; waits for the Claude lane's RR-19 to release `scripts/hive_cell.gd` (CT-1 and RR-13 landed 26-27 Oct 2026).
- **CQ-M7** (`plans/now/code-health.md`) -- world draw order named; waits for CQ-M6 and then needs its section and block.
- **CQ-S2** (`plans/now/code-health.md`) -- HiveCell owns its save fields; waits for CQ-S1, which sets the `to_save()`/`from_save()` pattern and shares the save files.
- **FR-4** (`plans/now/forager-recruitment.md`) -- a headless assertion replaces the C-143 hands-on check; `scripts/scenario_actions.gd` was released 25 Oct 2026, but `tools/admission.py` reads C-143, the check it retires, as an unlanded slice, so its block stays `queue-gated` until admission ignores check ids.

## Copy-paste prompts

Claude, implementing: `Implement the next slice.`

Codex, implementing: `Implement the next [Codex] slice: run tools/slice.ps1 start -Lane Codex, run the read command it prints, implement, run tools/verify.ps1, then close out per CHATGPT.md's "Risk-proportional closeout".`

Claude, integrating a high-risk Codex branch: `Integrate the finished Codex branch and close it out.`

Claude, after a hands-on pass: `I've done a hands-on pass. Here's what I found: <notes>. Update the checks, plans and queue.`

Claude, when a gate has cleared: `<what happened, e.g. "UI-F-2 has landed">. Move whatever it unblocks into its lane: clear its line under "Not in the queue, and why" (or open its fence from queue-gated to queue), then run python tools/refill_lane.py --top-up.`

Claude, when a lane is short and the backlog is dry (high reasoning): `The <Codex|Claude> lane is short and the backlog has nothing it can take. Plan the next <Codex|Claude> slices: write a queue block in the live plans for each one (it must touch no file in the other lane), put anything not ready yet under "Not in the queue, and why", then run python tools/refill_lane.py --top-up --lane <Codex|Claude>.`

Claude, looking ahead (high reasoning): `/plan-ahead [optional focus area]` -- surveys what needs a plan or slicing, ranks it, asks Dave the design questions and stores the answers in the plans.
