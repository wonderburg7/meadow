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

1. **[Claude] AC-1 -- every rule glob matches a file**
   - Plan: `plans/now/agent-context.md` -- "AC-1 -- every rule glob matches a file"
   - Files: `tools/check_docs.py`, `tests/test_rule_globs.py`
   - Check: `python -m unittest tests.test_rule_globs` passes (a dead glob and a missing front matter are errors, a 101-line rule warns, the real repository is clean); `python tools/check_docs.py` passes; `.\tools\verify.ps1` is green
   - Proof: `absent: tools/check_docs.py :: def check_rule_globs`
   - Next after: AC-2 -- `.claude/rules/ui.md` loads with the UI scripts

2. **[Claude] AC-2 -- `.claude/rules/ui.md` loads with the UI scripts**
   - Plan: `plans/now/agent-context.md` -- "AC-2 -- `.claude/rules/ui.md` loads with the UI scripts"
   - Files: `.claude/rules/ui.md`, `plans/reference/ui-rules.md`
   - Check: `python -m unittest tests.test_rule_globs` passes with the new rule's six globs each matching a file; `.claude/rules/ui.md` is under 40 lines; `python tools/check_docs.py` passes
   - Proof: `absent: plans/reference/ui-rules.md :: .claude/rules/ui.md`
   - Next after: AC-3 -- `.claude/rules/headless.md` loads with the harness

3. **[Claude] AC-3 -- `.claude/rules/headless.md` loads with the harness**
   - Plan: `plans/now/agent-context.md` -- "AC-3 -- `.claude/rules/headless.md` loads with the harness"
   - Files: `.claude/rules/headless.md`, `docs/headless-run-contract.md`
   - Check: `python -m unittest tests.test_rule_globs` passes with the new rule's six globs each matching a file; `.claude/rules/headless.md` is under 40 lines; `python tools/check_docs.py` passes
   - Proof: `absent: docs/headless-run-contract.md :: .claude/rules/headless.md`
   - Next after: AC-4 -- the Foraging card follows FR-2

4. **[Claude] SG-2 -- goals offered, completed and paid in Colony Runs and Scenarios, and saved**
   - Plan: `plans/now/short-term-goals.md` -- "SG-2 -- goals offered, completed and paid in Colony Runs and Scenarios, and saved"
   - Files: `scripts/short_term_goals.gd`, `scripts/year_winter.gd`, `scripts/main.gd`, `scripts/conditions.gd`, `scripts/hive.gd`, `scripts/bee_honey.gd`, `scripts/game_config.gd`, `scripts/save_game.gd`, `scripts/saving.gd`, `test_scenarios/sg2_short_term_goals.json`, `tests/test_sg2_short_term_goals.py`
   - Check: `python -m unittest tests.test_sg2_short_term_goals` passes (in a Colony Run with no pollen income the pollen goal is offered, and finishing it pays pollen worth about a quarter of a day's gross income; "Lay in honey for winter" can finish before the countdown's last day while the CR-2 winter milestone still waits for it; no goal is offered in Challenge 1 or 2; offered and finished goals survive save and restore; an old save loads with none); the sweep's table is recorded in this section; `.\tools\verify.ps1` is green
   - Proof: `absent: scripts/save_game.gd :: short_term_goals`
   - Next after: SG-3 -- the goals in the Goals drop-down, with progress, reward, star and Dismiss

5. **[Claude] GP-5 -- a Goals button in the second HUD row replaces the Goals header**
   - Plan: `plans/now/short-term-goals.md` -- "GP-5 -- a Goals button in the second HUD row replaces the Goals header"
   - Files: `scripts/hud.gd`, `tests/gp1_goals_dropdown_test.gd`, `tests/test_layout_regression.py`
   - Check: `python -m unittest tests.test_gp1_goals_dropdown` passes against `goals_button`; `python -m unittest tests.test_layout_regression` passes at the minimum width; `.\tools\verify.ps1` is green; Dave's hands-on check is filed
   - Proof: `absent: scripts/hud.gd :: goals_button`
   - Next after: none -- the Goals toggle move is complete

### Codex lane

Up to five items, worked top to bottom. No file here may appear in the Claude
lane. Refilled by `python tools/refill_lane.py --top-up --lane Codex`.

1. **[Codex] L-38 -- count worker product edits from worktree-relative shell commands**
   - Plan: `plans/now/agent-lifecycle.md` -- "L-38 -- count worker product edits from worktree-relative shell commands"
   - Files: `tools/session_cost.py`, `tests/test_session_cost_scope.py`
   - Check: `python -m unittest tests.test_session_cost_scope` passes, including `cd .worktrees/L-38; sed -i ... tools/session_cost.py`, `cd .worktrees/L-38; cp ... scripts/bee.gd`, established worktree cwd, and read-only/non-product countercases; `python tools/session_cost.py --phases` reports the worker count when transcripts are available
   - Proof: `absent: tools/session_cost.py :: def _shell_product_edit`
   - Next after: none -- agent-lifecycle plan complete

## Not in the queue, and why

One line each: the id, its plan, and the single thing it waits for.

- **AR-4** (`plans/now/alpha-route-evidence.md`) -- a scripted Colony Run reaches and records all five gates; waits for playable Tier 2 automation and the gyne route (Bee Bread finished 11 Oct 2026).
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
- **PP-6** (`plans/now/pollination.md`) -- the sweep prices the gyne route so Gyne rearing is first affordable in the 11 days after the first winter; waits for which puts Auto scouting on the route (Dave, 14 Oct 2026); AR-5 landed 21 Oct 2026 (`plans/now/alpha-route-evidence.md`: its reference queen lays early).
- **FR-3** (`plans/now/forager-recruitment.md`) -- owning Auto-recruitment switches it on, passing species with Adaptive constancy; waits for PP-6, which shares `scripts/skills.gd`.
- **CQ-S1** (`plans/now/code-health.md`) -- Flower owns its save fields, the first entity to own its `to_save()`/`from_save()`; waits for the save slices of the alpha chain (SG-2, ED-1, ED-2, RR-12, SP-8a in `plans/now/drones.md`; WP-2 landed 21 Oct 2026 and WP-3 landed 22 Oct 2026) and ED-3 (Dave, 18 Oct 2026); CQ-S0's round-trip harness landed 22 Oct 2026.
- **CQ-R2** (`plans/now/code-health.md`) -- the first crisis moves out of `scripts/main.gd` into a new first_crisis.gd, touching the save files; waits, gated with CQ-S1, for the save slices of the alpha chain (SG-2, ED-1, ED-2, RR-12, SP-8a in `plans/now/drones.md`; WP-2 landed 21 Oct 2026) and ED-3 (Dave, 18 Oct 2026); its plan section is written when that gate clears.
- **CQ-R8** (`plans/now/code-health.md`) -- hud builders shortened (the designation button table); needs its section and block; prepare before CQ-T3.
- **CQ-T3** (`plans/now/code-health.md`) -- the UI scripts typed and the untyped warning made an error; needs its section and block after CQ-R8, and Codex admission waits for CQ-L2 to release `tests/source_checks.py`.
- **CQ-R10** (`plans/now/code-health.md`) -- input selection decomposed and sectioned; needs its section and block.
- **CQ-S2** (`plans/now/code-health.md`) -- HiveCell owns its save fields; waits for CQ-S1, which sets the `to_save()`/`from_save()` pattern and shares the save files.
- **DR-2** (`plans/now/drones.md`) -- the cell popup's "Raise a drone" box (Dave, 22 Oct 2026: player-marked drone cells, no skill); waits for DR-1 (Claude backlog), whose saved drone cells it marks; CQ-R7 landed 22 Oct 2026, freeing `scripts/hud.gd`. Its block is `queue-gated` until DR-1 lands.
- **SP-12** (`plans/now/sprites.md`) -- every outline on a comb cell sits on the cup's rim, proved by a new pixel assertion; waits for which owns `scripts/hive_cell.gd` and `scripts/scenario_actions.gd`.
- **SP-13** (`plans/now/sprites.md`) -- foragers come and go at the skep's door; waits for which owns `scripts/hive.gd`.
- **SP-14** (`plans/now/sprites.md`) -- no outline on an unselected comb cell while cell art is on; waits for which owns `scripts/hive_cell.gd`.
- **RR-13** (`plans/now/run-repairs.md`) -- the pre-ferment warning shows 1.5 game days ahead in a stronger colour; waits for which owns `scripts/hive_cell.gd`.
- **RR-14** (`plans/now/run-repairs.md`) -- a sour cell given a new designation is emptied by a comb worker, not at once; waits for which owns `scripts/orders_zones.gd`.
- **RR-15** (`plans/now/run-repairs.md`) -- Fermentation sense keeps fresh nectar out of sour cells for every depositing bee; waits for which owns `scripts/hive.gd`.
- **RR-16** (`plans/now/run-repairs.md`) -- the queen can resume building a part-built cell; waits for which owns `scripts/orders_zones.gd`.
- **RR-17** (`plans/now/run-repairs.md`) -- a queen on comb work discards sour nectar on command; waits for which owns `scripts/bee.gd`.
- **FR-4** (`plans/now/forager-recruitment.md`) -- a headless assertion replaces the C-143 hands-on check; waits for which owns `scripts/scenario_actions.gd`.
- **T2-15** (`plans/now/tier-two.md`) -- with Fermentation sense and Cleaning owned, cleaning comb workers discard sour nectar unasked; waits for DR-1 and which own `scripts/hive.gd` and `scripts/bee_building.gd`.
- **RR-19** (`plans/now/run-repairs.md`) -- comb workers seal and unseal cells over time; waits for DR-1 and which own `scripts/hive_cell.gd`, `scripts/hive.gd`, `scripts/save_game.gd`, `scripts/saving.gd` and `scripts/bee_building.gd`.
- **RR-20** (`plans/now/run-repairs.md`) -- a comb worker carrying a body leaves, stays out one second, and comes back; waits for which owns `scripts/bee_building.gd` and `scripts/bee_movement.gd`.
- **RR-21** (`plans/now/run-repairs.md`) -- no ordinary rain in the first two days, and rain warnings in plain words; waits for SG-4, which owns `scripts/main.gd`.
- **RR-22** (`plans/now/run-repairs.md`) -- select a number of bees from a multi-selection; waits for GP-5 and SG-4, which own `scripts/hud.gd` and `scripts/main.gd`.
- **CT-1** (`plans/now/cell-content-tones.md`) -- cells and their caps take a faint tone of their contents (Dave, 24 Oct 2026); waits for which owns `scripts/hive_cell.gd` and `scripts/scenario_actions.gd`.
- **AC-4** (`plans/now/agent-context.md`) -- `GAME_MODEL.md`'s Foraging card follows FR-2; waits for FR-2, which removes `scouting_on`.
- **HS-2** (`plans/now/hard-soil.md`) -- hard soil fills the outer half of the hive's soil (Dave, 24 Oct 2026); waits for HS-1 and which own the skill id, `scripts/hive.gd` and `scripts/bee.gd`.

## Copy-paste prompts

Claude, implementing: `Implement the next slice.`

Codex, implementing: `Implement the next [Codex] slice: run tools/slice.ps1 start -Lane Codex, run the read command it prints, implement, run tools/verify.ps1, then close out per CHATGPT.md's "Risk-proportional closeout".`

Claude, integrating a high-risk Codex branch: `Integrate the finished Codex branch and close it out.`

Claude, after a hands-on pass: `I've done a hands-on pass. Here's what I found: <notes>. Update the checks, plans and queue.`

Claude, when a gate has cleared: `<what happened, e.g. "UI-F-2 has landed">. Move whatever it unblocks into its lane: clear its line under "Not in the queue, and why" (or open its fence from queue-gated to queue), then run python tools/refill_lane.py --top-up.`

Claude, when a lane is short and the backlog is dry (high reasoning): `The <Codex|Claude> lane is short and the backlog has nothing it can take. Plan the next <Codex|Claude> slices: write a queue block in the live plans for each one (it must touch no file in the other lane), put anything not ready yet under "Not in the queue, and why", then run python tools/refill_lane.py --top-up --lane <Codex|Claude>.`

Claude, looking ahead (high reasoning): `/plan-ahead [optional focus area]` -- surveys what needs a plan or slicing, ranks it, asks Dave the design questions and stores the answers in the plans.
