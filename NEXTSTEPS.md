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

1. **[Codex] AR-6 -- the pacing report's draft targets in one place, matched to product-scope §3**
   - Plan: `plans/now/alpha-route-evidence.md` -- "AR-6 -- the pacing report's draft targets in one place, matched to product-scope §3"
   - Files: `tools/pacing_gates.py`, `tests/test_pacing_gates.py`
   - Check: `python -m unittest tests.test_pacing_gates` passes (first worker 9.0 in band and 9.5 out; automation in band on days 20.0 to 25.0 only; the table prints "<= 9" and "20-25", not "1.50"); `.\tools\verify.ps1` is green
   - Proof: `present: tools/pacing_gates.py :: FIRST_WORKER_BY_DAY = 17.0`
   - Next after: AR-4 -- a scripted Colony Run reaches and records all five gates (gated on PP-10)

2. **[Codex] CQ-M5b -- the last CanvasLayer readers and the bare-layer source check**
   - Plan: `plans/now/code-health.md` -- "CQ-M5b -- the last CanvasLayer readers and the bare-layer source check"
   - Files: `scripts/hud.gd`, `scripts/main.gd`, `scripts/game_panel.gd`, `tests/source_checks.py`, `FUNCTION_MAP.md`
   - Check: `python tests/source_checks.py` passes and fails on a planted `layer = 3` in a scratch copy of `scripts/hud.gd`; `python -m unittest tests.test_layout_regression` and `python tools/prefinish.py` pass
   - Proof: `present: scripts/main.gd :: weather_layer.layer = 5`
   - Next after: CQ-M4 -- gated until the Claude lane releases the save files

3. **[Codex] CQ-M6 -- name selection green and caste appearance**
   - Plan: `plans/now/code-health.md` -- "CQ-M6 -- name selection green and caste appearance"
   - Files: `scripts/world_draw.gd`, `scripts/bee.gd`, `scripts/death_marker.gd`, `scripts/flower.gd`, `scripts/obstacle.gd`, `scripts/soil_block.gd`, `FUNCTION_MAP.md`
   - Check: `python -m unittest tests.test_sp9_soil_art tests.test_col9_drones` and `python tools/prefinish.py` pass; rendered selection alphas and caste sizes remain unchanged
   - Proof: `present: scripts/obstacle.gd :: selection_ring.default_color = Color(0.2, 1.0, 0.4, 0.95)`
   - Next after: CQ-M6b -- the cell ring and the selection layer read the selection green

4. **[Codex] PN-18 -- the queen discards sour nectar when told to empty a cell**
   - Plan: `plans/now/play-notes-config.md` -- "PN-18 -- the queen discards sour nectar when told to empty a cell"
   - Files: `scripts/bee.gd`, `test_scenarios/pn18_queen_empties_sour.json`, `tests/test_pn18_queen_empties_sour.py`
   - Check: `python -m unittest tests.test_pn18_queen_empties_sour` passes (lone queen, sour cell, no Cleaning: the cell ends empty and the nectar is discarded); `.\tools\verify.ps1` is green. Hands-on: the queen empties a sour cell on command
   - Proof: `absent: scripts/bee.gd :: PN-18`
   - Next after: PN-19 -- the soil block's selection ring closes

5. **[Codex] PN-19 -- the soil block's selection ring closes**
   - Plan: `plans/now/play-notes-config.md` -- "PN-19 -- the soil block's selection ring closes"
   - Files: `scripts/soil_block.gd`, `tests/test_sp10_soil_depth.py`, `tests/test_sp9_soil_art.py`
   - Check: `python -m unittest tests.test_sp10_soil_depth tests.test_sp9_soil_art` pass with an assertion that the ring is closed; `.\tools\verify.ps1` is green. Hands-on: a selected soil block's outline has no gap
   - Proof: `present: scripts/soil_block.gd :: selection_ring.add_point(ring_points[0])`
   - Next after: none -- `plans/now/play-notes-config.md` is complete

## Not in the queue, and why

One line each: the id, its plan, and the single thing it waits for.

- **AR-4** (`plans/now/alpha-route-evidence.md`) -- a scripted Colony Run reaches and records all five gates; waits for PP-10 (`plans/now/pollination.md`), which prices the gyne route once EV-0 has re-set the calendar.
- **CQ-M4** (`plans/now/code-health.md`) -- name Challenge level ids; waits for the Claude lane to release `scripts/save_game.gd` and `scripts/saving.gd`.
- **CQ-M6b** (`plans/now/code-health.md`) -- the cell ring and the selection layer read the selection green; waits for CQ-M6, and for the Claude lane's PN-5, PN-6 and PN-9, which edit `scripts/input_selection.gd` and `scripts/hive_cell.gd`.
- **CQ-R4** (`plans/now/code-health.md`) -- `bee.gd::_process` into four helpers, profiled (high); needs its section and block, written by the session that claims CQ-R3 (HP-3 landed 18 Oct 2026).
- **CQ-L3** (`plans/now/code-health.md`) -- one-off `gdformat` over every `.gd` file, then `--check` joins verify; waits for both lanes to empty.
- **RR-12** (`plans/now/run-repairs.md`) -- a loaded run keeps its readout history (Dave, 16 Oct 2026); waits for ED-3, the last of the alpha chain, which shares `scripts/main.gd` and the save files.
- **SP-8a** (`plans/now/meadow-terrain.md`) -- the meadow floor drawn in blocks, with everything on it lifted (Dave, 12 Oct 2026); waits for ED-3, the last of the alpha chain (ED-2 to ED-3; ED-1 landed 2 Nov 2026, ED-1b landed 3 Nov 2026, ED-1c landed 4 Nov 2026, WP-2 landed 21 Oct 2026, WP-3 landed 22 Oct 2026, SG-2 landed 26 Oct 2026), which shares `scripts/main.gd` and the save files (Dave, 16 Oct 2026).
- **HM-2** (`plans/now/hive-and-menu-art.md`) -- five top-bar buttons drawn from Dave's menu icons; waits for Dave to queue it (his call, 13 Oct 2026); its gated block is written.
- **HM-1** (`plans/now/hive-and-menu-art.md`) -- your hive and rival hives drawn from Dave's meadow hive art; waits for Dave to fit the large hive's layer 0 on its 54x41 canvas in Aseprite.
- **T2-7b** (`plans/now/tier-two.md`) -- the deferred tier-2 price sweep (first tier-2 purchase around day 5); waits for AR-4, whose arc buys a Honey worker, and is specified when it lands.
- **ED-3** (`plans/now/difficulty.md`) -- choosing Easy at run start; waits for ED-2.
- **The event director's events** (`plans/now/event-director.md`, EV-1 onward) -- designed 1 Nov 2026 (`plans/design/event-director.md`); wait for CQ-R2, which creates event_director.gd (in `scripts/`), and ED-3, and are specified then.
- **FR-3** (`plans/now/forager-recruitment.md`) -- owning Auto-recruitment switches it on, passing species with Adaptive constancy; waits for PP-10 (`plans/now/pollination.md`, after EV-0), which shares `scripts/skills.gd`.
- **EV-0** (`plans/now/event-director.md`) -- one Calendar and events settings group, and winter a week later; waits for PN-11, which re-pins the first crisis to days 12-15 on `claude/dave-hands-on-checks-784f2a`.
- **PP-10** (`plans/now/pollination.md`) -- the sweep prices the route so Gyne rearing is first affordable after the first winter; waits for EV-0, so it prices the route once, on the new calendar (Dave, 1 Nov 2026).
- **CQ-S1** (`plans/now/code-health.md`) -- Flower owns its save fields, the first entity to own its `to_save()`/`from_save()`; waits for the save slices of the alpha chain (ED-2, RR-12, SP-8a in `plans/now/drones.md`; WP-2 landed 21 Oct 2026 and WP-3 landed 22 Oct 2026) and ED-3 (Dave, 18 Oct 2026); CQ-S0's round-trip harness landed 22 Oct 2026.
- **CQ-R2** (`plans/now/code-health.md`) -- the first crisis moves out of `scripts/main.gd` into a new event_director.gd (in `scripts/`) as the shared event cycle's first record (`plans/design/event-director.md` decisions 2 and 15), touching the save files; waits, gated with CQ-S1, for the save slices of the alpha chain (ED-2, RR-12, SP-8a in `plans/now/drones.md`; WP-2 landed 21 Oct 2026) and ED-3 (Dave, 18 Oct 2026); its plan section is written when that gate clears.
- **CQ-R13** (`plans/now/code-health.md`) -- `main.gd::_ready` into build steps; waits for CQ-R2, which shares `scripts/main.gd`, and then needs its slice specification.
- **CQ-T4** (`plans/now/code-health.md`) -- the remaining scripts and tests typed and `untyped_declaration` made an error; waits for the Codex lane's CQ-M5b, CQ-M6 and PN-19, which hold `tests/source_checks.py`, `scripts/obstacle.gd` and `scripts/soil_block.gd` (its Jules gates cleared 5 Nov 2026).
- **CQ-M7** (`plans/now/code-health.md`) -- world draw order named; waits for CQ-M6b and then needs its section and block.
- **CQ-S2** (`plans/now/code-health.md`) -- HiveCell owns its save fields; waits for CQ-S1, which sets the `to_save()`/`from_save()` pattern and shares the save files.
- **PN-8** (`plans/now/play-notes-hud.md`) -- Warning history in the Colony window; waits for PN-7, which shares `scripts/hud.gd`.
- **PN-11** (`plans/now/play-notes-config.md`) -- rain from day 10 and the first crisis on days 12-15; waits for PN-9, which shares `scripts/game_config.gd` (its Jules gates cleared 5 Nov 2026; RR-18 landed 31 Oct 2026).
- **PN-12** (`plans/now/play-notes-config.md`) -- developer mode buys any skill; waits for PN-11, the plan's config slices running in turn (its Jules gates cleared 5 Nov 2026).
- **PN-14** (`plans/now/play-notes-hud.md`) -- text no longer shrinks when unpausing; waits for PN-8, which shares `scripts/hud.gd` (its Jules gate cleared 5 Nov 2026).
- **PN-15** (`plans/now/play-notes-hud.md`) -- a day dial beside Day N; waits for PN-14, which shares `scripts/hud.gd` (its Jules gate cleared 5 Nov 2026).
- **PN-16** (`plans/now/play-notes-hud.md`) -- double-click a cell selects every cell of that type; waits for PN-15, which shares `scripts/hud.gd`, and PN-6, which shares `scripts/input_selection.gd`.
- **PN-17** (`plans/now/play-notes-hud.md`) -- Shift queues build and dig orders; waits for PN-16, which shares `scripts/input_selection.gd` (its Jules gate cleared 5 Nov 2026).
- **Lay an egg order** (`plans/now/play-notes-config.md`) -- click a cell and the queen gathers what an egg needs; needs a design pass first (resources up front or as she goes, cancelling, Laying job, saved reservations).
- **Colony window tabs** (`plans/now/play-notes-config.md`) -- Colony, Nursing and Foraging tabs; needs a design pass first, and waits for HM-2 (SG-3 landed 1 Nov 2026).
- **Work priorities by role** (`plans/now/play-notes-config.md`) -- reorderable comb-worker priorities and sub-roles in the fallback list, both changing the save format; needs a plan-ahead pass first.

## Copy-paste prompts

Claude, implementing: `Implement the next slice.`

Codex, implementing: `Implement the next [Codex] slice: run tools/slice.ps1 start -Lane Codex (if the lane is empty, refill it first per CHATGPT.md's "Refilling an empty or gated Codex lane", then start again), run the read command it prints, implement, run python tools/prefinish.py, then close out per CHATGPT.md's "Risk-proportional closeout".`

Claude, integrating a high-risk Codex branch: `Integrate the finished Codex branch and close it out.`

Claude, after a hands-on pass: `I've done a hands-on pass. Here's what I found: <notes>. Update the checks, plans and queue.`

Claude, when a gate has cleared: `<what happened, e.g. "UI-F-2 has landed">. Move whatever it unblocks into its lane: clear its line under "Not in the queue, and why" (or open its fence from queue-gated to queue), then run python tools/refill_lane.py --top-up.`

Claude, when a lane is short and the backlog is dry (high reasoning): `The <Codex|Claude> lane is short and the backlog has nothing it can take. Plan the next <Codex|Claude> slices: write a queue block in the live plans for each one (it must touch no file in the other lane), put anything not ready yet under "Not in the queue, and why", then run python tools/refill_lane.py --top-up --lane <Codex|Claude>.`

Claude, looking ahead (high reasoning): `/plan-ahead [optional focus area]` -- surveys what needs a plan or slicing, ranks it, asks Dave the design questions and stores the answers in the plans.
