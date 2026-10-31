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

1. **[Claude] HS-2 -- hard soil fills the outer half of the hive's soil**
   - Plan: `plans/now/hard-soil.md` -- "HS-2 -- hard soil fills the outer half of the hive's soil"
   - Files: `scripts/soil_block.gd`, `scripts/hive.gd`, `scripts/bee.gd`, `scripts/game_config.gd`, `scripts/settings_catalogue.gd`, `test_scenarios/hs2_hard_soil.json`, `tests/test_hs2_hard_soil.py`
   - Check: `python -m unittest tests.test_hs2_hard_soil` passes, asserting a hard block refuses a dig order before Mighty Mandible and accepts one after, the hard-soil colour distances, and the rough halfway edge; `.\tools\verify.ps1` is green. Hands-on: in the HS-2 scenario, the hard soil next to the cavity looks greyer than ordinary soil and different from the bedrock, and clicking it to dig does nothing until Mighty Mandible is bought.
   - Proof: `absent: scripts/soil_block.gd :: func hard_soil_start_ring(`
   - Next after: none -- `plans/now/hard-soil.md` is complete

2. **[Claude] PP-11 -- the reference route owns Pollinator points and reaches Gyne rearing on every seed**
   - Plan: `plans/now/pollination.md` -- "PP-11 -- the reference route owns Pollinator points and reaches Gyne rearing on every seed"
   - Files: `scripts/headless/diagnostic_probes.gd`, `tools/headless/profiles.py`, `test_scenarios/alpha_arc_test.json`, `tests/test_pp11_route_snapshots.py`
   - Check: `python -m unittest tests.test_pp11_route_snapshots tests.test_pp6_gyne_rearing_affordable` passes (both snapshot whitelists carry `resources.stored_bee_bread`, `resources.stored_royal_jelly` and `resources.pollinator_points`, and a run logs them); over 3 seeds of the reference Colony Run (`python tools/pacing_gates.py`) every seed owns Pollinator points (`skill.foraging.pollinator_points`), the Gyne-rearing row reports a day on each seed (any day, no band), and the first-worker row stays in band (median by day 17); no price, recipe, `config_overrides` entry that redefines what is measured, or `grant_skill` of a Foraging node; `.\tools\verify.ps1` is green
   - Proof: `absent: scripts/headless/diagnostic_probes.gd :: stored_bee_bread`
   - Next after: PP-10 -- the sweep prices the route so Gyne rearing is first affordable after the first winter

3. **[Claude] SG-3 -- the goals in the Goals drop-down, with progress, reward, star and Dismiss**
   - Plan: `plans/now/short-term-goals.md` -- "SG-3 -- the goals in the Goals drop-down, with progress, reward, star and Dismiss"
   - Files: `scripts/hud.gd`, `scripts/colony_milestones.gd`, `scripts/main.gd`, `scripts/guidance_catalogue.gd`, `test_scenarios/sg3_goal_shelf.json`, `tests/test_sg3_goal_shelf.py`
   - Check: `python -m unittest tests.test_sg3_goal_shelf` passes (an offered goal appears in the Goals drop-down under the milestone with its progress and reward, in a Colony Run and in a Scenario; a starred goal stays when the drop-down is collapsed; Dismiss removes it and nothing replaces it until the next day; finishing one shows the completion note and the Dr line once); `.\tools\verify.ps1` is green
   - Proof: `absent: scripts/hud.gd :: short_term`
   - Next after: none -- the short-term goals plan is complete; ED-1 in `plans/now/difficulty.md` follows in Dave's order

4. **[Claude] SP-6 -- meadow foragers drawn from the sheet**
   - Plan: `plans/now/sprites.md` -- "SP-6 -- meadow foragers drawn from the sheet"
   - Files: `scripts/bee.gd`, `tests/sp6_forager_sprite_test.gd`, `tests/test_sp6_forager_sprite.py`
   - Check: `python -m unittest tests.test_sp6_forager_sprite` passes: an outdoor worker heading into each of the eight octants shows that direction's row, its frame advances with the wing clock, and its body circles are hidden outdoors and shown indoors; a before/after profile of the display update is recorded in the plan; `.	ools
   erify.ps1` is green
   - Proof: `absent: scripts/bee.gd :: FORAGERS_MEADOW_VIEW`
   - Next after: None -- plan complete

### Codex lane

Up to five items, worked top to bottom. No file here may appear in the Claude
lane. Refilled by `python tools/refill_lane.py --top-up --lane Codex`.

1. **[Codex] EE-1 -- measure summer seed-set replacement across five seeds**
   - Plan: `plans/now/ecology-evidence.md` -- "EE-1 -- measure summer seed-set replacement across five seeds"
   - Files: `tools/seed_set_evidence.py`, `test_scenarios/ee1_seed_set_summer.json`, `tests/test_seed_set_evidence.py`, `plans/reference/seed-set-evidence.md`
   - Check: `python tests/test_seed_set_evidence.py` passes; `python tools/seed_set_evidence.py summer` completes ten serial runs and writes the paired report; `python tools/check_docs.py` passes
   - Proof: `absent: plans/reference/seed-set-evidence.md :: ## Summer measurements`
   - Next after: EE-2

2. **[Codex] EE-2 -- measure seed-set carryover into spring**
   - Plan: `plans/now/ecology-evidence.md` -- "EE-2 -- measure seed-set carryover into spring"
   - Files: `tools/seed_set_evidence.py`, `test_scenarios/ee2_seed_set_spring.json`, `tests/test_seed_set_evidence.py`, `plans/reference/seed-set-evidence.md`
   - Check: `python tests/test_seed_set_evidence.py` passes; `python tools/seed_set_evidence.py spring` completes ten serial runs and writes the paired spring report; `python tools/check_docs.py` passes
   - Proof: `absent: plans/reference/seed-set-evidence.md :: ## Spring measurements`
   - Next after: none -- seed-set evidence complete; further ecology needs an evidence-backed design decision

## Not in the queue, and why

One line each: the id, its plan, and the single thing it waits for.

- **AR-4** (`plans/now/alpha-route-evidence.md`) -- a scripted Colony Run reaches and records all five gates; waits for playable Tier 2 automation and the gyne route (Bee Bread finished 11 Oct 2026).
- **CQ-M5b** (`plans/now/code-health.md`) -- the last CanvasLayer readers and the bare-layer source check; waits for SG-3 to release `scripts/main.gd` and the Jules J-14 branch to settle `scripts/game_panel.gd`.
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
- **CQ-R15** (`plans/now/code-health.md`) -- the Goals drop-down moves out of `scripts/hud.gd` into a new hud_goal_shelf.gd; waits for SG-3 to release `scripts/hud.gd` (modularity review, 30 Oct 2026).
- **CQ-R8** (`plans/now/code-health.md`) -- hud builders shortened and hud sections re-headed; waits for CQ-R15, which shares `scripts/hud.gd`.
- **CQ-R3** (`plans/now/code-health.md`) -- bee display text moves into a new bee_readout.gd; waits for HS-2 and SP-6 to release `scripts/bee.gd`.
- **CQ-R16** (`plans/now/code-health.md`) -- drag and pan state moves from `scripts/main.gd` to `scripts/input_selection.gd`; waits for SG-3 to release `scripts/main.gd`.
- **CQ-T3** (`plans/now/code-health.md`) -- the UI scripts typed and the untyped warning made an error; needs its section and block after CQ-R8 (CQ-L2 released `tests/source_checks.py` 24 Oct 2026).
- **CQ-M6** (`plans/now/code-health.md`) -- selection green and caste appearance named; waits for the Claude lane's HS-2 to release `scripts/bee.gd` and `scripts/soil_block.gd` and SP-6 to release `scripts/bee.gd`.
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
