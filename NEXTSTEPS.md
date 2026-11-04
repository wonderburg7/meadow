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

1. **[Claude] ED-1c -- health is saved per bee**
   - Plan: `plans/now/difficulty.md` -- "ED-1c -- health is saved per bee"
   - Files: `scripts/save_game.gd`, `scripts/saving.gd`, `tests/ed1c_health_save_test.gd`, `tests/test_ed1c_health_save.py`, `tests/test_save_migrations.py`, `tests/fixtures/saves/cq_s0_early.json`, `tests/fixtures/saves/cq_s0_mid.json`, `tests/fixtures/saves/cq_s0_winter.json`, `tests/fixtures/saves/cq_s0_challenge2.json`, `tests/fixtures/saves/cq_s0_orientation.json`
   - Check: `python -m unittest tests.test_ed1c_health_save tests.test_save_migrations` passes (a bee's health survives save and restore; an old save without the key loads every bee at full health); `.\tools\verify.ps1` is green
   - Proof: `absent: scripts/save_game.gd :: "health"`
   - Next after: ED-2 -- a run's difficulty, and Easy's rules

2. **[Claude] RR-22 -- select a number of bees from a multi-selection**
   - Plan: `plans/now/run-repairs.md` -- "RR-22 -- select a number of bees from a multi-selection"
   - Files: `scripts/hud.gd`, `scripts/input_selection.gd`, `scripts/main.gd`, `tests/test_layout_regression.py`, `tests/rr22_select_n_test.gd`, `tests/test_rr22_select_n.py`
   - Check: `python -m unittest tests.test_rr22_select_n` passes (n is clamped to 1..selection size, `>>` steps by 5, Select keeps n bees, youngest and oldest keep the one bee with the least or greatest age); `python -m unittest tests.test_layout_regression` passes; `.\tools\verify.ps1` is green; Dave's hands-on check is filed
   - Proof: `absent: scripts/hud.gd :: select_youngest`
   - Next after: none -- multi-selection narrowing is complete

3. **[Claude] CQ-T3 -- the free UI scripts typed**
   - Plan: `plans/now/code-health.md` -- "CQ-T3 -- the free UI scripts typed"
   - Files: `scripts/hud.gd`, `scripts/debug_panel.gd`, `scripts/ui_theme.gd`, `scripts/main_menu.gd`, `scripts/nursery_panel.gd`, `scripts/saves_panel.gd`, `scripts/hud_goal_shelf.gd`, `scripts/challenge_complete.gd`, `scripts/ui.gd`, `scripts/run_availability_panel.gd`, `scripts/ui_icon.gd`, `scripts/game_over.gd`, `scripts/foraging_panel.gd`, `scripts/succession_panel.gd`, `scripts/winter_panel.gd`, `scripts/stage_gate.gd`, `scripts/perf_plot.gd`, `scripts/perf_breakdown.gd`, `tests/source_checks.py`, `FUNCTION_MAP.md`
   - Check: `python tests/source_checks.py` passes with all 18 scripts in `TYPED_FILES`; `python tools/prefinish.py` boots without an `untyped_declaration` warning from them; `.\tools\verify.ps1` is green
   - Proof: `absent: tests/source_checks.py :: "scripts/debug_panel.gd"`
   - Next after: CQ-T4 -- the rest typed; the warning becomes an error

5. **[Claude] FR-4 -- a headless assertion replaces the C-143 hands-on check**
   - Plan: `plans/now/forager-recruitment.md` -- "FR-4 -- a headless assertion replaces the C-143 hands-on check"
   - Files: `scripts/scenario_actions.gd`, `test_scenarios/fr4_scout_entrance.json`, `tests/test_fr4_scout_entrance.py`, `checks/ready/C-143.md`
   - Check: `python -m unittest tests.test_fr4_scout_entrance` passes (an unmatched scout is not in `AT_ENTRANCE_SEEKING` after its walk and leaves the hive; an established forager below the lower threshold waits there); C-143 is archived; `.\tools\verify.ps1` is green
   - Proof: `absent: scripts/scenario_actions.gd :: "bee_states"`
   - Next after: FR-3 -- owning Auto-recruitment switches it on, passing species with Adaptive constancy (it does not depend on FR-4)

### Codex lane

Up to five items, worked top to bottom. No file here may appear in the Claude
lane. Refilled by `python tools/refill_lane.py --top-up --lane Codex`.

## Not in the queue, and why

One line each: the id, its plan, and the single thing it waits for.

- **AR-4** (`plans/now/alpha-route-evidence.md`) -- a scripted Colony Run reaches and records all five gates; waits for playable Tier 2 automation and the gyne route (Bee Bread finished 11 Oct 2026).
- **CQ-M5b** (`plans/now/code-health.md`) -- the last CanvasLayer readers and the bare-layer source check; waits for the unmerged Jules S-3 branches to settle `scripts/main.gd` and the Jules J-14 branch to settle `scripts/game_panel.gd` (CQ-R16 landed 2 Nov 2026; ED-1b landed 3 Nov 2026, releasing `scripts/hud.gd`).
- **CQ-M4** (`plans/now/code-health.md`) -- name Challenge level ids; waits for the Claude lane to release `scripts/save_game.gd` and `scripts/saving.gd`.
- **RR-12** (`plans/now/run-repairs.md`) -- a loaded run keeps its readout history (Dave, 16 Oct 2026); waits for ED-3, the last of the alpha chain, which shares `scripts/main.gd` and the save files.
- **SP-8a** (`plans/now/meadow-terrain.md`) -- the meadow floor drawn in blocks, with everything on it lifted (Dave, 12 Oct 2026); waits for ED-3, the last of the alpha chain (ED-1c to ED-3; ED-1 landed 2 Nov 2026, ED-1b landed 3 Nov 2026, WP-2 landed 21 Oct 2026, WP-3 landed 22 Oct 2026, SG-2 landed 26 Oct 2026), which shares `scripts/main.gd` and the save files (Dave, 16 Oct 2026).
- **HM-2** (`plans/now/hive-and-menu-art.md`) -- five top-bar buttons drawn from Dave's menu icons; waits for Dave to queue it (his call, 13 Oct 2026); its gated block is written.
- **HM-1** (`plans/now/hive-and-menu-art.md`) -- your hive and rival hives drawn from Dave's meadow hive art; waits for Dave to fit the large hive's layer 0 on its 54x41 canvas in Aseprite.
- **T2-7b** (`plans/now/tier-two.md`) -- the deferred tier-2 price sweep (first tier-2 purchase around day 5); waits for AR-4, whose arc buys a Honey worker, and is specified when it lands.
- **ED-2** (`plans/now/difficulty.md`) -- a run's difficulty and Easy's rules; waits for ED-1c.
- **ED-3** (`plans/now/difficulty.md`) -- choosing Easy at run start; waits for ED-2.
- **The event director** (`plans/design/product-scope.md` §6.2) -- needs its own design pass before a slice can be written; `plans/reference/colony-diagnostics.md` is the model for what that pass produces.
- **FR-3** (`plans/now/forager-recruitment.md`) -- owning Auto-recruitment switches it on, passing species with Adaptive constancy; waits for PP-10 (`plans/now/pollination.md`, after EV-0), which shares `scripts/skills.gd`.
- **EV-0** (`plans/now/event-director.md`) -- one Calendar and events settings group, and winter a week later; waits for PN-11, which re-pins the first crisis to days 12-15 on `claude/dave-hands-on-checks-784f2a`.
- **PP-10** (`plans/now/pollination.md`) -- the sweep prices the route so Gyne rearing is first affordable after the first winter; waits for EV-0, so it prices the route once, on the new calendar (Dave, 1 Nov 2026).
- **CQ-S1** (`plans/now/code-health.md`) -- Flower owns its save fields, the first entity to own its `to_save()`/`from_save()`; waits for the save slices of the alpha chain (ED-1c, ED-2, RR-12, SP-8a in `plans/now/drones.md`; WP-2 landed 21 Oct 2026 and WP-3 landed 22 Oct 2026) and ED-3 (Dave, 18 Oct 2026); CQ-S0's round-trip harness landed 22 Oct 2026.
- **CQ-R2** (`plans/now/code-health.md`) -- the first crisis moves out of `scripts/main.gd` into a new first_crisis.gd, touching the save files; waits, gated with CQ-S1, for the save slices of the alpha chain (ED-1c, ED-2, RR-12, SP-8a in `plans/now/drones.md`; WP-2 landed 21 Oct 2026) and ED-3 (Dave, 18 Oct 2026); its plan section is written when that gate clears.
- **CQ-R13** (`plans/now/code-health.md`) -- `main.gd::_ready` into build steps; waits for CQ-R2, which shares `scripts/main.gd`, and then needs its slice specification.
- **CQ-R3** (`plans/now/code-health.md`) -- bee display text moves into a new bee_readout.gd; waits for the unmerged Jules S-1 and S-3 branches, which change `scripts/bee.gd`, to be merged or closed (ED-1 landed 2 Nov 2026).
- **CQ-T4** (`plans/now/code-health.md`) -- the remaining scripts and tests typed and `untyped_declaration` made an error; waits for CQ-T3 and for `claude/dave-hands-on-checks-784f2a` and the Jules S-1/S-3 branches to be merged or closed.
- **CQ-M6** (`plans/now/code-health.md`) -- selection green and caste appearance named; waits for the unmerged Jules S-1 and S-3 branches (`scripts/bee.gd`, `scripts/soil_block.gd`) and `claude/dave-hands-on-checks-784f2a` (`scripts/hive_cell.gd`) to be merged or closed (ED-1 and CQ-R16 landed 2 Nov 2026).
- **CQ-M7** (`plans/now/code-health.md`) -- world draw order named; waits for CQ-M6 and then needs its section and block.
- **CQ-S2** (`plans/now/code-health.md`) -- HiveCell owns its save fields; waits for CQ-S1, which sets the `to_save()`/`from_save()` pattern and shares the save files.
- **PN-7** (`plans/now/play-notes-hud.md`) -- cell popup wording, Empty controls and a warning box that stays 18 real seconds; waits for SG-3 to release `scripts/hud.gd`.
- **PN-8** (`plans/now/play-notes-hud.md`) -- Warning history in the Colony window; waits for PN-7, which shares `scripts/hud.gd`.
- **PN-9** (`plans/now/play-notes-config.md`) -- early spring: the queen builds three times faster for 10 days and nectar does not sour before day 15 and the turning warning comes a day before it sours; waits for HS-2 to release `scripts/game_config.gd`, `scripts/settings_catalogue.gd`, and needs its alpha_arc simulation first.
- **PN-10** (`plans/now/play-notes-hud.md`) -- opening goal text a new player can act on; waits for SG-3 to release `scripts/colony_milestones.gd`.
- **PN-11** (`plans/now/play-notes-config.md`) -- rain from day 10 and the first crisis on days 12-15; waits for HS-2 to release `scripts/game_config.gd` and for the Codex lane's RR-18 (C-140 skip save).
- **PN-12** (`plans/now/play-notes-config.md`) -- developer mode buys any skill; waits for HS-2 to release `scripts/settings_catalogue.gd`.
- **PN-13** (`plans/now/play-notes-config.md`) -- a Show bee labels switch and a calmer queen flight; waits for HS-2 and SP-6 to release `scripts/bee.gd`, `scripts/game_config.gd` and `scripts/settings_catalogue.gd`.
- **PN-14** (`plans/now/play-notes-hud.md`) -- text no longer shrinks when unpausing; waits for SG-3 to release `scripts/hud.gd`.
- **PN-15** (`plans/now/play-notes-hud.md`) -- a day dial beside Day N; waits for SG-3 to release `scripts/hud.gd`.
- **PN-16** (`plans/now/play-notes-hud.md`) -- double-click a cell selects every cell of that type; waits for SG-3 to release `scripts/hud.gd` and PN-6, which shares `scripts/input_selection.gd`.
- **PN-17** (`plans/now/play-notes-hud.md`) -- Shift queues build and dig orders; waits for SG-3 to release `scripts/hud.gd` and `scripts/main.gd`.
- **PN-18** (`plans/now/play-notes-config.md`) -- the queen discards sour nectar when told to empty a cell; waits for HS-2 and SP-6 to release `scripts/bee.gd`.
- **PN-19** (`plans/now/play-notes-config.md`) -- the soil block selection ring closes; waits for HS-2 to release `scripts/soil_block.gd`.
- **Lay an egg order** (`plans/now/play-notes-config.md`) -- click a cell and the queen gathers what an egg needs; needs a design pass first (resources up front or as she goes, cancelling, Laying job, saved reservations).
- **Colony window tabs** (`plans/now/play-notes-config.md`) -- Colony, Nursing and Foraging tabs; needs a design pass first, and waits for SG-3 and HM-2.
- **Work priorities by role** (`plans/now/play-notes-config.md`) -- reorderable comb-worker priorities and sub-roles in the fallback list, both changing the save format; needs a plan-ahead pass first.

## Copy-paste prompts

Claude, implementing: `Implement the next slice.`

Codex, implementing: `Implement the next [Codex] slice: run tools/slice.ps1 start -Lane Codex, run the read command it prints, implement, run tools/verify.ps1, then close out per CHATGPT.md's "Risk-proportional closeout".`

Claude, integrating a high-risk Codex branch: `Integrate the finished Codex branch and close it out.`

Claude, after a hands-on pass: `I've done a hands-on pass. Here's what I found: <notes>. Update the checks, plans and queue.`

Claude, when a gate has cleared: `<what happened, e.g. "UI-F-2 has landed">. Move whatever it unblocks into its lane: clear its line under "Not in the queue, and why" (or open its fence from queue-gated to queue), then run python tools/refill_lane.py --top-up.`

Claude, when a lane is short and the backlog is dry (high reasoning): `The <Codex|Claude> lane is short and the backlog has nothing it can take. Plan the next <Codex|Claude> slices: write a queue block in the live plans for each one (it must touch no file in the other lane), put anything not ready yet under "Not in the queue, and why", then run python tools/refill_lane.py --top-up --lane <Codex|Claude>.`

Claude, looking ahead (high reasoning): `/plan-ahead [optional focus area]` -- surveys what needs a plan or slicing, ranks it, asks Dave the design questions and stores the answers in the plans.
