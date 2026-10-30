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

1. **[Claude] RR-20 -- a comb worker carrying a body visibly leaves, stays out one second, and comes back**
   - Plan: `plans/now/run-repairs.md` -- "RR-20 -- a comb worker carrying a body visibly leaves, stays out one second, and comes back"
   - Files: `scripts/bee_building.gd`, `scripts/bee_movement.gd`, `scripts/game_config.gd`, `scripts/settings_catalogue.gd`, `tests/t2_4b_bodies_test.gd`, `tests/t2_13_carried_body_test.gd`
   - Check: `python -m unittest tests.test_t2_4b_bodies tests.test_t2_13_carried_body` pass (the body-carrying bee is outside the hive for 1 s then inside again); `.\tools\verify.ps1` is green; Dave's hands-on check is filed
   - Proof: `absent: scripts/game_config.gd :: body_drop_seconds`
   - Next after: none -- the body drop is complete

2. **[Claude] RR-21 -- no ordinary rain in a run's first two days, and rain warnings say when in plain words**
   - Plan: `plans/now/run-repairs.md` -- "RR-21 -- no ordinary rain in a run's first two days, and rain warnings say when in plain words"
   - Files: `scripts/main.gd`, `scripts/game_config.gd`, `scripts/settings_catalogue.gd`, `tests/test_fc2_first_crisis.py`, `tests/test_rr21_rain_free_days.py`
   - Check: `python -m unittest tests.test_rr21_rain_free_days tests.test_fc2_first_crisis tests.test_display_text_golden` pass (no random rain before day 2 even at a chance of 1.0; rain rolls again after; the first crisis still fires; warnings read "soon", "later today", "by the end of the day" or "tomorrow"); the before/after `alpha_arc_test.json` outputs are recorded in the closeout; `.\tools\verify.ps1` is green; Dave's hands-on check is filed
   - Proof: `absent: scripts/game_config.gd :: rain_free_days`
   - Next after: none -- the rain rule is complete

3. **[Claude] SP-13 -- foragers come and go at the skep's door**
   - Plan: `plans/now/sprites.md` -- "SP-13 -- foragers come and go at the skep's door"
   - Files: `scripts/hive.gd`, `scripts/rival_hive.gd`, `scripts/sprite_catalogue.gd`
   - Check: `python tools/prefinish.py` is green (boot check clean); the skep sprite's door lands on `hive.position` in a headless scene (the sprite's position plus the door offset equals zero); `.\tools\verify.ps1` is green; Dave's hands-on check is filed
   - Proof: `absent: scripts/sprite_catalogue.gd :: HIVE_SKEP_DOOR`
   - Next after: none -- `plans/now/sprites.md` is complete once SP-6, SP-12 and SP-14 have landed

4. **[Claude] SP-14 -- no outline on an unselected comb cell while the cell art is on**
   - Plan: `plans/now/sprites.md` -- "SP-14 -- no outline on an unselected comb cell while the cell art is on"
   - Files: `scripts/hive_cell.gd`
   - Check: `python -m unittest tests.test_sp11_cell_rim` passes; with cell art on, a cell holding nectar has `outline.visible` false and a cell under an overlay has it true; `.\tools\verify.ps1` is green; Dave's hands-on check is filed
   - Proof: `absent: scripts/hive_cell.gd :: outline.visible = content_type != "" and not`
   - Next after: none -- `plans/now/sprites.md` is complete once SP-6, SP-12 and SP-13 have landed

5. **[Claude] HS-2 -- hard soil fills the outer half of the hive's soil**
   - Plan: `plans/now/hard-soil.md` -- "HS-2 -- hard soil fills the outer half of the hive's soil"
   - Files: `scripts/soil_block.gd`, `scripts/hive.gd`, `scripts/bee.gd`, `scripts/game_config.gd`, `scripts/settings_catalogue.gd`, `test_scenarios/hs2_hard_soil.json`, `tests/test_hs2_hard_soil.py`
   - Check: `python -m unittest tests.test_hs2_hard_soil` passes, asserting a hard block refuses a dig order before Mighty Mandible and accepts one after, the hard-soil colour distances, and the rough halfway edge; `.\tools\verify.ps1` is green. Hands-on: in the HS-2 scenario, the hard soil next to the cavity looks greyer than ordinary soil and different from the bedrock, and clicking it to dig does nothing until Mighty Mandible is bought.
   - Proof: `absent: scripts/soil_block.gd :: func hard_soil_start_ring(`
   - Next after: none -- `plans/now/hard-soil.md` is complete

### Codex lane

Up to five items, worked top to bottom. No file here may appear in the Claude
lane. Refilled by `python tools/refill_lane.py --top-up --lane Codex`.

1. **[Codex] RR-18 -- skip saves for the long checks C-140 and C-142**
   - Plan: `plans/now/run-repairs.md` -- "RR-18 -- skip saves for the long checks C-140 and C-142"
   - Files: `test_scenarios/c140_first_crisis_warned.json`, `test_scenarios/c142_work_priorities.json`, `checks/ready/C-140.md`, `checks/ready/C-142.md`
   - Check: `python tools/run_scenario.py test_scenarios/c140_first_crisis_warned.json` and `python tools/run_scenario.py test_scenarios/c142_work_priorities.json` each finish and leave their named save in the saves list; `python tools/check_docs.py` passes; `.\tools\verify.ps1` is green
   - Proof: `absent: checks/ready/C-140.md :: run_scenario`
   - Next after: none -- the long-check skip saves are complete

2. **[Codex] FX-6 -- Codex skills derive `ROOT`; Codex run-queue probes `.git`**
   - Plan: `plans/now/workflow-friction.md` -- "FX-6 -- Codex skills derive `ROOT`; Codex run-queue probes `.git`"
   - Files: `.agents/skills/run-queue/SKILL.md`, `.agents/skills/plan-ahead/SKILL.md`
   - Check: `git grep -n dl13860 -- .agents/skills` prints nothing; `git grep -n "refs/meadow/write-probe" -- .agents/skills/run-queue/SKILL.md` prints one line; `python tools/check_docs.py` passes
   - Proof: `absent: .agents/skills/run-queue/SKILL.md :: refs/meadow/write-probe`
   - Next after: none -- workflow-friction plan complete

## Not in the queue, and why

One line each: the id, its plan, and the single thing it waits for.

- **AR-4** (`plans/now/alpha-route-evidence.md`) -- a scripted Colony Run reaches and records all five gates; waits for playable Tier 2 automation and the gyne route (Bee Bread finished 11 Oct 2026).
- **CQ-M5b** (`plans/now/code-health.md`) -- the last CanvasLayer readers and the bare-layer source check; waits for RR-21 to release `scripts/main.gd` and the Jules J-14 branch to settle `scripts/game_panel.gd`.
- **CQ-M4** (`plans/now/code-health.md`) -- name Challenge level ids; waits for the Claude lane to release `scripts/save_game.gd` and `scripts/saving.gd`.
- **RR-22** (`plans/now/run-repairs.md`) -- select a number of bees from a multi-selection; waits for the Codex lane's CQ-R6 to release `scripts/hud.gd`, which both name.
- **RR-12** (`plans/now/run-repairs.md`) -- a loaded run keeps its readout history (Dave, 16 Oct 2026); waits for ED-3, the last of the alpha chain, which shares `scripts/main.gd` and the save files.
- **SP-8a** (`plans/now/meadow-terrain.md`) -- the meadow floor drawn in blocks, with everything on it lifted (Dave, 12 Oct 2026); waits for ED-3, the last of the alpha chain (SG-3 to ED-3; WP-2 landed 21 Oct 2026, WP-3 landed 22 Oct 2026 and SG-2 landed 26 Oct 2026), which shares `scripts/main.gd` and the save files (Dave, 16 Oct 2026).
- **HM-2** (`plans/now/hive-and-menu-art.md`) -- five top-bar buttons drawn from Dave's menu icons; waits for Dave to queue it (his call, 13 Oct 2026); its gated block is written.
- **HM-1** (`plans/now/hive-and-menu-art.md`) -- your hive and rival hives drawn from Dave's meadow hive art; waits for Dave to fit the large hive's layer 0 on its 54x41 canvas in Aseprite.
- **T2-7b** (`plans/now/tier-two.md`) -- the deferred tier-2 price sweep (first tier-2 purchase around day 5); waits for AR-4, whose arc buys a Honey worker, and is specified when it lands.
- **ED-1** (`plans/now/difficulty.md`) -- every bee has health; waits for SG-3 (Dave's order; FC-2 landed 17 Oct 2026, freeing the save files).
- **ED-2** (`plans/now/difficulty.md`) -- a run's difficulty and Easy's rules; waits for ED-1.
- **ED-3** (`plans/now/difficulty.md`) -- choosing Easy at run start; waits for ED-2.
- **The event director** (`plans/design/product-scope.md` §6.2) -- needs its own design pass before a slice can be written; `plans/reference/colony-diagnostics.md` is the model for what that pass produces.
- **FR-3** (`plans/now/forager-recruitment.md`) -- owning Auto-recruitment switches it on, passing species with Adaptive constancy; waits for PP-10 (`plans/now/pollination.md`, after PP-11; PP-9 landed 27 Oct 2026), which shares `scripts/skills.gd`.
- **CQ-S1** (`plans/now/code-health.md`) -- Flower owns its save fields, the first entity to own its `to_save()`/`from_save()`; waits for the save slices of the alpha chain (ED-1, ED-2, RR-12, SP-8a in `plans/now/drones.md`; WP-2 landed 21 Oct 2026 and WP-3 landed 22 Oct 2026) and ED-3 (Dave, 18 Oct 2026); CQ-S0's round-trip harness landed 22 Oct 2026.
- **CQ-R2** (`plans/now/code-health.md`) -- the first crisis moves out of `scripts/main.gd` into a new first_crisis.gd, touching the save files; waits, gated with CQ-S1, for the save slices of the alpha chain (ED-1, ED-2, RR-12, SP-8a in `plans/now/drones.md`; WP-2 landed 21 Oct 2026) and ED-3 (Dave, 18 Oct 2026); its plan section is written when that gate clears.
- **CQ-R8** (`plans/now/code-health.md`) -- hud builders shortened (the designation button table); needs its section and block; prepare before CQ-T3.
- **CQ-T3** (`plans/now/code-health.md`) -- the UI scripts typed and the untyped warning made an error; needs its section and block after CQ-R8 (CQ-L2 released `tests/source_checks.py` 24 Oct 2026).
- **CQ-M6** (`plans/now/code-health.md`) -- selection green and caste appearance named; waits for the Claude lane's SP-14 to release `scripts/hive_cell.gd` and HS-2 to release `scripts/bee.gd` and `scripts/soil_block.gd` (CT-1, RR-13 and RR-19 landed 26-28 Oct 2026).
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
