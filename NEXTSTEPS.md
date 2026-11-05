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

1. **[Claude] PN-2 -- rename a save in the saves list**
   - Plan: `plans/now/play-notes.md` -- "PN-2 -- rename a save in the saves list"
   - Files: `scripts/saves_panel.gd`, `scripts/save_slots.gd`, `tests/pn2_save_rename_test.gd`, `tests/test_pn2_save_rename.py`
   - Check: `python -m unittest tests.test_pn2_save_rename` passes (rename updates the index name only, survives a reload, refuses empty and duplicate names); `.\tools\verify.ps1` is green. Hands-on: rename a save, quit, restart; the new name shows and it loads
   - Proof: `absent: scripts/save_slots.gd :: func rename(`
   - Next after: PN-3 -- a save remembers whether Goals was open

2. **[Claude] PN-3 -- a save remembers whether Goals was open**
   - Plan: `plans/now/play-notes.md` -- "PN-3 -- a save remembers whether Goals was open"
   - Files: `scripts/save_game.gd`, `scripts/saving.gd`, `scripts/session.gd`, `tests/test_gp1_goals_dropdown.py`, `tests/gp1_goals_dropdown_test.gd`
   - Check: `python -m unittest tests.test_gp1_goals_dropdown` passes with a save round trip of the Goals state and an old save with no key loading as shown; `.\tools\verify.ps1` is green. Hands-on: close Goals, save, load; it is closed (re-run C-150)
   - Proof: `absent: scripts/save_game.gd :: goals_collapsed`
   - Next after: PN-4 -- the queen finishes a cell she was told to build

3. **[Claude] PN-4 -- the queen finishes a cell she was told to build**
   - Plan: `plans/now/play-notes.md` -- "PN-4 -- the queen finishes a cell she was told to build"
   - Files: `scripts/bee_survival.gd`, `scripts/orders_zones.gd`, `scripts/bee_building.gd`, `test_scenarios/pn4_queen_build_after_meal.json`, `test_scenarios/pn4_queen_build_from_meadow.json`, `tests/test_pn4_queen_build.py`
   - Check: `python -m unittest tests.test_pn4_queen_build` passes (both scenarios fail before the fix and finish the cell after it); `python -m unittest tests.test_rr1_queen_builds` still passes; `.\tools\verify.ps1` is green. Hands-on: a Forager queen ordered to build finishes the cell after eating; one ordered from the meadow walks in and builds
   - Proof: `absent: scripts/orders_zones.gd :: ordered_site`
   - Next after: PN-5 -- a cell or soil block is clicked by its top face

4. **[Claude] PN-5 -- a cell or soil block is clicked by its top face**
   - Plan: `plans/now/play-notes.md` -- "PN-5 -- a cell or soil block is clicked by its top face"
   - Files: `scripts/input_selection.gd`, `tests/pn5_top_face_pick_test.gd`, `tests/test_pn5_top_face_pick.py`
   - Check: `python -m unittest tests.test_pn5_top_face_pick` passes (top face picks, a covered floor hexagon does not, an uncovered one does, soil follows the same rule); `.\tools\verify.ps1` is green. Hands-on: clicking inside a cell's top ring selects it
   - Proof: `absent: scripts/input_selection.gd :: _point_in_hex`
   - Next after: PN-6 -- double-click selects bees of the same role

5. **[Claude] PN-6 -- double-click selects bees of the same role**
   - Plan: `plans/now/play-notes.md` -- "PN-6 -- double-click selects bees of the same role"
   - Files: `scripts/input_selection.gd`, `tests/pn6_double_click_select_test.gd`, `tests/test_pn6_double_click_select.py`
   - Check: `python -m unittest tests.test_pn6_double_click_select` passes (same role and sub-role, on screen only, Shift adds); `.\tools\verify.ps1` is green. Hands-on: double-click a Forager selects the on-screen Foragers
   - Proof: `absent: scripts/input_selection.gd :: _select_same_role`
   - Next after: PN-9 -- early spring: fast queen building, no souring before day 15

### Codex lane

Up to five items, worked top to bottom. No file here may appear in the Claude
lane. Refilled by `python tools/refill_lane.py --top-up --lane Codex`.

## Not in the queue, and why

One line each: the id, its plan, and the single thing it waits for.

- **AR-4** (`plans/now/alpha-route-evidence.md`) -- a scripted Colony Run reaches and records all five gates; waits for playable Tier 2 automation and the gyne route (Bee Bread finished 11 Oct 2026).
- **CQ-M5b** (`plans/now/code-health.md`) -- the last CanvasLayer readers and the bare-layer source check; waits for the unmerged Jules S-3 branches to settle `scripts/main.gd` and the Jules J-14 branch to settle `scripts/game_panel.gd` (CQ-R16 landed 2 Nov 2026; ED-1b landed 3 Nov 2026, releasing `scripts/hud.gd`).
- **CQ-M4** (`plans/now/code-health.md`) -- name Challenge level ids; waits for the Claude lane to release `scripts/save_game.gd` and `scripts/saving.gd`.
- **RR-12** (`plans/now/run-repairs.md`) -- a loaded run keeps its readout history (Dave, 16 Oct 2026); waits for ED-3, the last of the alpha chain, which shares `scripts/main.gd` and the save files.
- **SP-8a** (`plans/now/meadow-terrain.md`) -- the meadow floor drawn in blocks, with everything on it lifted (Dave, 12 Oct 2026); waits for ED-3, the last of the alpha chain (ED-2 to ED-3; ED-1 landed 2 Nov 2026, ED-1b landed 3 Nov 2026, ED-1c landed 4 Nov 2026, WP-2 landed 21 Oct 2026, WP-3 landed 22 Oct 2026, SG-2 landed 26 Oct 2026), which shares `scripts/main.gd` and the save files (Dave, 16 Oct 2026).
- **HM-2** (`plans/now/hive-and-menu-art.md`) -- five top-bar buttons drawn from Dave's menu icons; waits for Dave to queue it (his call, 13 Oct 2026); its gated block is written.
- **HM-1** (`plans/now/hive-and-menu-art.md`) -- your hive and rival hives drawn from Dave's meadow hive art; waits for Dave to fit the large hive's layer 0 on its 54x41 canvas in Aseprite.
- **T2-7b** (`plans/now/tier-two.md`) -- the deferred tier-2 price sweep (first tier-2 purchase around day 5); waits for AR-4, whose arc buys a Honey worker, and is specified when it lands.
- **ED-2** (`plans/now/difficulty.md`) -- a run's difficulty and Easy's rules; waits for the unmerged Jules E-14 and S-3 marker-reparent branches to be merged or closed, which change `scripts/bee_survival.gd`, `scripts/crab_spider.gd` and `scripts/save_game.gd` (ED-1c landed 4 Nov 2026); its gated block is written.
- **ED-3** (`plans/now/difficulty.md`) -- choosing Easy at run start; waits for ED-2.
- **The event director's events** (`plans/now/event-director.md`, EV-1 onward) -- designed 1 Nov 2026 (`plans/design/event-director.md`); wait for CQ-R2, which creates event_director.gd (in `scripts/`), and ED-3, and are specified then.
- **FR-3** (`plans/now/forager-recruitment.md`) -- owning Auto-recruitment switches it on, passing species with Adaptive constancy; waits for PP-10 (`plans/now/pollination.md`, after EV-0), which shares `scripts/skills.gd`.
- **EV-0** (`plans/now/event-director.md`) -- one Calendar and events settings group, and winter a week later; waits for PN-11, which re-pins the first crisis to days 12-15 on `claude/dave-hands-on-checks-784f2a`.
- **PP-10** (`plans/now/pollination.md`) -- the sweep prices the route so Gyne rearing is first affordable after the first winter; waits for EV-0, so it prices the route once, on the new calendar (Dave, 1 Nov 2026).
- **CQ-S1** (`plans/now/code-health.md`) -- Flower owns its save fields, the first entity to own its `to_save()`/`from_save()`; waits for the save slices of the alpha chain (ED-2, RR-12, SP-8a in `plans/now/drones.md`; WP-2 landed 21 Oct 2026 and WP-3 landed 22 Oct 2026) and ED-3 (Dave, 18 Oct 2026); CQ-S0's round-trip harness landed 22 Oct 2026.
- **CQ-R2** (`plans/now/code-health.md`) -- the first crisis moves out of `scripts/main.gd` into a new event_director.gd (in `scripts/`) as the shared event cycle's first record (`plans/design/event-director.md` decisions 2 and 15), touching the save files; waits, gated with CQ-S1, for the save slices of the alpha chain (ED-2, RR-12, SP-8a in `plans/now/drones.md`; WP-2 landed 21 Oct 2026) and ED-3 (Dave, 18 Oct 2026); its plan section is written when that gate clears.
- **CQ-R13** (`plans/now/code-health.md`) -- `main.gd::_ready` into build steps; waits for CQ-R2, which shares `scripts/main.gd`, and then needs its slice specification.
- **CQ-R3** (`plans/now/code-health.md`) -- bee display text moves into a new bee_readout.gd; waits for the unmerged Jules S-1 and S-3 branches, which change `scripts/bee.gd`, to be merged or closed (ED-1 landed 2 Nov 2026).
- **CQ-T4** (`plans/now/code-health.md`) -- the remaining scripts and tests typed and `untyped_declaration` made an error; waits for the unmerged Jules E-14, E-34 and S-3 marker-reparent branches, which change `scripts/bee_survival.gd`, `scripts/soil_block.gd`, `tests/source_checks.py` and five of its tests, to be merged or closed (CQ-T3 landed 5 Nov 2026; `claude/dave-hands-on-checks-784f2a` merged 4 Nov 2026).
- **CQ-M6** (`plans/now/code-health.md`) -- selection green and caste appearance named; waits for the unmerged Jules S-1 and S-3 branches (`scripts/bee.gd`, `scripts/soil_block.gd`) and `claude/dave-hands-on-checks-784f2a` (`scripts/hive_cell.gd`) to be merged or closed (ED-1 and CQ-R16 landed 2 Nov 2026).
- **CQ-M7** (`plans/now/code-health.md`) -- world draw order named; waits for CQ-M6 and then needs its section and block.
- **CQ-S2** (`plans/now/code-health.md`) -- HiveCell owns its save fields; waits for CQ-S1, which sets the `to_save()`/`from_save()` pattern and shares the save files.
- **PN-7** (`plans/now/play-notes-hud.md`) -- cell popup wording, Empty controls and a warning box that stays 18 real seconds; waits for the unmerged Jules E-14 branch, which changes `scripts/hud.gd`, to be merged or closed (SG-3 landed 1 Nov 2026).
- **PN-8** (`plans/now/play-notes-hud.md`) -- Warning history in the Colony window; waits for PN-7, which shares `scripts/hud.gd`.
- **PN-9** (`plans/now/play-notes-config.md`) -- early spring: the queen builds three times faster for 10 days and nectar does not sour before day 15 and the turning warning comes a day before it sours; waits for the unmerged Jules E-14 and S-3 marker-reparent branches, which change `scripts/game_config.gd` and `scripts/settings_catalogue.gd`, to be merged or closed (HS-2 landed 1 Nov 2026), and needs its alpha_arc simulation first.
- **PN-10** (`plans/now/play-notes-hud.md`) -- opening goal text a new player can act on; waits for the unmerged Jules E-14 branch, which changes `scripts/colony_milestones.gd`, to be merged or closed (SG-3 landed 1 Nov 2026).
- **PN-11** (`plans/now/play-notes-config.md`) -- rain from day 10 and the first crisis on days 12-15; waits for the unmerged Jules E-14 and S-3 marker-reparent branches, which change `scripts/game_config.gd`, to be merged or closed (HS-2 landed 1 Nov 2026; RR-18 landed 31 Oct 2026).
- **PN-12** (`plans/now/play-notes-config.md`) -- developer mode buys any skill; waits for the unmerged Jules E-14 and S-3 marker-reparent branches, which change `scripts/settings_catalogue.gd`, to be merged or closed (HS-2 landed 1 Nov 2026).
- **PN-13** (`plans/now/play-notes-config.md`) -- a Show bee labels switch and a calmer queen flight; waits for the unmerged Jules E-14 and S-3 marker-reparent branches, which change `scripts/bee.gd`, `scripts/game_config.gd` and `scripts/settings_catalogue.gd`, to be merged or closed (HS-2 and SP-6 landed 1 Nov 2026).
- **PN-14** (`plans/now/play-notes-hud.md`) -- text no longer shrinks when unpausing; waits for the unmerged Jules E-14 branch, which changes `scripts/hud.gd`, to be merged or closed (SG-3 landed 1 Nov 2026).
- **PN-15** (`plans/now/play-notes-hud.md`) -- a day dial beside Day N; waits for the unmerged Jules E-14 branch, which changes `scripts/hud.gd`, to be merged or closed (SG-3 landed 1 Nov 2026).
- **PN-16** (`plans/now/play-notes-hud.md`) -- double-click a cell selects every cell of that type; waits for the unmerged Jules E-14 branch, which changes `scripts/hud.gd`, to be merged or closed (SG-3 landed 1 Nov 2026), and for PN-6, which shares `scripts/input_selection.gd`.
- **PN-17** (`plans/now/play-notes-hud.md`) -- Shift queues build and dig orders; waits for the unmerged Jules S-3 marker-reparent branch, which changes `scripts/main.gd`, to be merged or closed (SG-3 landed 1 Nov 2026).
- **PN-18** (`plans/now/play-notes-config.md`) -- the queen discards sour nectar when told to empty a cell; waits for the unmerged Jules E-14 and S-3 marker-reparent branches, which change `scripts/bee.gd`, to be merged or closed (HS-2 and SP-6 landed 1 Nov 2026).
- **PN-19** (`plans/now/play-notes-config.md`) -- the soil block selection ring closes; waits for the unmerged Jules S-3 marker-reparent branch, which changes `scripts/soil_block.gd`, to be merged or closed (HS-2 landed 1 Nov 2026).
- **Lay an egg order** (`plans/now/play-notes-config.md`) -- click a cell and the queen gathers what an egg needs; needs a design pass first (resources up front or as she goes, cancelling, Laying job, saved reservations).
- **Colony window tabs** (`plans/now/play-notes-config.md`) -- Colony, Nursing and Foraging tabs; needs a design pass first, and waits for HM-2 (SG-3 landed 1 Nov 2026).
- **Work priorities by role** (`plans/now/play-notes-config.md`) -- reorderable comb-worker priorities and sub-roles in the fallback list, both changing the save format; needs a plan-ahead pass first.

## Copy-paste prompts

Claude, implementing: `Implement the next slice.`

Codex, implementing: `Implement the next [Codex] slice: run tools/slice.ps1 start -Lane Codex, run the read command it prints, implement, run tools/verify.ps1, then close out per CHATGPT.md's "Risk-proportional closeout".`

Claude, integrating a high-risk Codex branch: `Integrate the finished Codex branch and close it out.`

Claude, after a hands-on pass: `I've done a hands-on pass. Here's what I found: <notes>. Update the checks, plans and queue.`

Claude, when a gate has cleared: `<what happened, e.g. "UI-F-2 has landed">. Move whatever it unblocks into its lane: clear its line under "Not in the queue, and why" (or open its fence from queue-gated to queue), then run python tools/refill_lane.py --top-up.`

Claude, when a lane is short and the backlog is dry (high reasoning): `The <Codex|Claude> lane is short and the backlog has nothing it can take. Plan the next <Codex|Claude> slices: write a queue block in the live plans for each one (it must touch no file in the other lane), put anything not ready yet under "Not in the queue, and why", then run python tools/refill_lane.py --top-up --lane <Codex|Claude>.`

Claude, looking ahead (high reasoning): `/plan-ahead [optional focus area]` -- surveys what needs a plan or slicing, ranks it, asks Dave the design questions and stores the answers in the plans.
