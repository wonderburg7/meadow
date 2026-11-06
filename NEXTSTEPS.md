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

1. **[Claude] PN-11 -- rain later: first rain on day 10, crisis days 12-15**
   - Plan: `plans/now/play-notes-config.md` -- "PN-11 -- rain later: first rain on day 10, crisis days 12-15"
   - Files: `scripts/game_config.gd`, `test_scenarios/fc2_first_crisis_prepared.json`, `test_scenarios/fc2_first_crisis_unprepared.json`, `test_scenarios/c140_first_crisis_warned.json`, `tests/test_rr21_rain_free_days.py`, `tests/test_fc2_first_crisis.py`
   - Check: `python -m unittest tests.test_rr21_rain_free_days tests.test_fc2_first_crisis` pass with the new days; the fc2 onset days before and after are recorded; `.\tools\verify.ps1` is green
   - Proof: `present: scripts/game_config.gd :: var first_crisis_window_open: float = 1080.0`
   - Next after: EV-0 -- one Calendar and events settings group, and winter a week later

2. **[Claude] ED-2 -- a run's difficulty, saved**
   - Plan: `plans/now/difficulty.md` -- "ED-2 -- a run's difficulty, saved"
   - Files: `scripts/session.gd`, `scripts/save_game.gd`, `scripts/saving.gd`, `tests/ed2_difficulty_save_test.gd`, `tests/test_ed2_difficulty_save.py`
   - Check: `python -m unittest tests.test_ed2_difficulty_save` passes (a new run is Standard; Easy set by a headless scenario survives save and restore; a save without the key loads as Standard; the CQ-S0 round-trip goldens are re-captured with the new field); `.\tools\verify.ps1` is green
   - Proof: `absent: scripts/session.gd :: difficulty`
   - Next after: ED-2b -- Easy's rules

3. **[Claude] PN-2 -- rename a save in the saves list**
   - Plan: `plans/now/play-notes.md` -- "PN-2 -- rename a save in the saves list"
   - Files: `scripts/saves_panel.gd`, `scripts/save_slots.gd`, `tests/pn2_save_rename_test.gd`, `tests/test_pn2_save_rename.py`
   - Check: `python -m unittest tests.test_pn2_save_rename` passes (rename updates the index name only, survives a reload, refuses empty and duplicate names); `.\tools\verify.ps1` is green. Hands-on: rename a save, quit, restart; the new name shows and it loads
   - Proof: `absent: scripts/save_slots.gd :: func rename(`
   - Next after: PN-3 -- a save remembers whether Goals was open

4. **[Claude] PN-3 -- a save remembers whether Goals was open**
   - Plan: `plans/now/play-notes.md` -- "PN-3 -- a save remembers whether Goals was open"
   - Files: `scripts/save_game.gd`, `scripts/saving.gd`, `scripts/session.gd`, `tests/test_gp1_goals_dropdown.py`, `tests/gp1_goals_dropdown_test.gd`
   - Check: `python -m unittest tests.test_gp1_goals_dropdown` passes with a save round trip of the Goals state and an old save with no key loading as shown; `.\tools\verify.ps1` is green. Hands-on: close Goals, save, load; it is closed (re-run C-150)
   - Proof: `absent: scripts/save_game.gd :: goals_collapsed`
   - Next after: PN-4 -- the queen finishes a cell she was told to build

5. **[Claude] PN-4 -- the queen finishes a cell she was told to build**
   - Plan: `plans/now/play-notes.md` -- "PN-4 -- the queen finishes a cell she was told to build"
   - Files: `scripts/bee_survival.gd`, `scripts/orders_zones.gd`, `scripts/bee_building.gd`, `test_scenarios/pn4_queen_build_after_meal.json`, `test_scenarios/pn4_queen_build_from_meadow.json`, `tests/test_pn4_queen_build.py`
   - Check: `python -m unittest tests.test_pn4_queen_build` passes (both scenarios fail before the fix and finish the cell after it); `python -m unittest tests.test_rr1_queen_builds` still passes; `.\tools\verify.ps1` is green. Hands-on: a Forager queen ordered to build finishes the cell after eating; one ordered from the meadow walks in and builds
   - Proof: `absent: scripts/orders_zones.gd :: ordered_site`
   - Next after: PN-5 -- a cell or soil block is clicked by its top face

### Codex lane

Up to five items, worked top to bottom. No file here may appear in the Claude
lane. Refilled by `python tools/refill_lane.py --top-up --lane Codex`.

1. **[Codex] CQ-R3 -- bee display text becomes scripts/bee_readout.gd**
   - Plan: `plans/now/code-health.md` -- "CQ-R3 -- bee display text becomes scripts/bee_readout.gd"
   - Files: `scripts/bee.gd`, `scripts/bee_readout.gd`, `tests/test_t2_14_idle_reason_pure.py`, `FUNCTION_MAP.md`
   - Check: `python -m unittest tests.test_display_text_golden tests.test_t2_14_idle_reason_pure tests.test_t2_11_comb_cadence` passes with no expected string changed; `.\tools\verify.ps1` is green
   - Proof: `present: scripts/bee.gd :: func _task_line(`
   - Next after: CQ-R4

2. **[Codex] SP-12 -- every outline on a comb cell sits on the cup's rim, proved against the drawn pixels**
   - Plan: `plans/now/sprites.md` -- "SP-12 -- every outline on a comb cell sits on the cup's rim, proved against the drawn pixels"
   - Files: `scripts/input_selection.gd`, `scripts/hive_cell.gd`, `scripts/scenario_actions.gd`, `test_scenarios/sp_outline_rim.json`, `tests/test_sp_outline_rim.py`, `tests/sp11_cell_rim_test.gd`, `tests/test_sp11_cell_rim.py`
   - Check: `python -m unittest tests.test_sp_outline_rim` passes (the `cell_outline_matches_sprite` assertion holds for the selection ring and the tile outline within 1.5 px, and fails when the outline is moved 10 px); `python -m unittest tests.test_sp11_cell_rim` passes; `.\tools\verify.ps1` is green; Dave's hands-on check is filed
   - Proof: `absent: scripts/scenario_actions.gd :: cell_outline_matches_sprite`
   - Next after: PN-7 -- cell popup and selection text batch

3. **[Codex] PN-7 -- cell popup and selection text batch**
   - Plan: `plans/now/play-notes-hud.md` -- "PN-7 -- cell popup and selection text batch"
   - Files: `scripts/hud.gd`, `tests/display_text_golden_test.gd`, `tests/test_pn7_cell_popup.py`
   - Check: `python -m unittest tests.test_pn7_cell_popup` passes (labels, the sour-nectar gate, Keep empty in the Reserve row, warning dwell at 4x); the display-text golden test is regenerated; `.\tools\verify.ps1` is green. Hands-on: the cell popup reads as above and a warning at 4x lasts about 18 seconds
   - Proof: `present: scripts/hud.gd :: does not die of old age`
   - Next after: PN-14 -- text no longer shrinks when unpausing

4. **[Codex] PN-14 -- text no longer shrinks when unpausing**
   - Plan: `plans/now/play-notes-hud.md` -- "PN-14 -- text no longer shrinks when unpausing"
   - Files: `scripts/hud.gd`, `scripts/camera_view.gd`, `tests/pn14_pause_font_test.gd`, `tests/test_pn14_pause_font.py`
   - Check: `python -m unittest tests.test_pn14_pause_font` passes (HUD label font sizes equal before pause and after unpause; failing before the fix); `.\tools\verify.ps1` is green. Hands-on: Space to pause and resume leaves text size alone
   - Proof: `absent: scripts/hud.gd :: PN-14`
   - Next after: PN-15 -- a day dial beside "Day N"

5. **[Codex] PN-15 -- a day dial beside "Day N"**
   - Plan: `plans/now/play-notes-hud.md` -- "PN-15 -- a day dial beside "Day N""
   - Files: `scripts/hud_day_dial.gd`, `scripts/hud.gd`, `tests/test_pn15_day_dial.py`
   - Check: `python -m unittest tests.test_pn15_day_dial` passes (hand fraction matches the time of day; corner signature unchanged); `.\tools\verify.ps1` is green. Hands-on: the dial hand sweeps through the day
   - Proof: `absent: scripts/hud.gd :: HudDayDial`
   - Next after: PN-8 -- Warning history in the Colony window

## Not in the queue, and why

One line each: the id, its plan, and the single thing it waits for.

- **PN-5** (`plans/now/play-notes.md`) -- startable, but the Claude lane is full.
- **PN-6** (`plans/now/play-notes.md`) -- startable, but the Claude lane is full.
- **PN-9** (`plans/now/play-notes-config.md`) -- startable, but the Claude lane is full.
- **PN-12** (`plans/now/play-notes-config.md`) -- startable, but the Claude lane is full.
- **PN-13** (`plans/now/play-notes-config.md`) -- bee labels switch and a calmer queen flight; waits for the Codex lane's PN-18 to release `scripts/bee.gd`.
- **EV-0** (`plans/now/event-director.md`) -- one Calendar and events settings group, a new `RunCalendar` and a 35-day season (winter on day 36); waits for PN-11, whose crisis window it converts to days.
- **EV-0b** (`plans/now/event-director.md`) -- the flowers read EV-0's calendar; waits for EV-0, and for CQ-M6 (Codex lane), which edits `scripts/flower.gd`.
- **PP-10** (`plans/now/pollination.md`) -- the gyne route keeps its order on the new calendar; waits for EV-0, so the route is checked once, on the new calendar (Dave, 1 Nov 2026).
- **AR-4** (`plans/now/alpha-route-evidence.md`) -- a scripted Colony Run reaches and records all five gates; waits for PP-10, which checks the gyne route's order on EV-0's calendar.
- **FR-3** (`plans/now/forager-recruitment.md`) -- owning Auto-recruitment switches it on, passing species with Adaptive constancy; waits for PP-10 (`plans/now/pollination.md`), which shares `scripts/skills.gd`.
- **ED-2b** (`plans/now/difficulty.md`) -- Easy's rules: health floors at one, the queen cannot die, brood waits, winter spares; waits for ED-2, which adds the difficulty they read.
- **ED-3** (`plans/now/difficulty.md`) -- choosing Easy at run start; waits for ED-2b.
- **CQ-R2** (`plans/now/code-health.md`) -- the first crisis moves out of `scripts/main.gd` into a new event_director.gd (in `scripts/`) as the shared event cycle's first record (`plans/design/event-director.md` decisions 2 and 15), touching the save files; waits for ED-3 alone (Dave, 5 Nov 2026), and its plan section is written as ED-3 nears.
- **EV-1 onward** (`plans/now/event-director.md`) -- the event director's events, designed 1 Nov 2026 (`plans/design/event-director.md`); wait for CQ-R2, which creates event_director.gd (in `scripts/`), and are specified then.
- **RR-12** (`plans/now/run-repairs.md`) -- a loaded run keeps its readout history (Dave, 16 Oct 2026); waits for CQ-R2 (Dave, 5 Nov 2026), which shares `scripts/main.gd` and the save files.
- **SP-8a** (`plans/now/meadow-terrain.md`) -- the meadow floor drawn in blocks, with everything on it lifted; waits for CQ-R2, which follows ED-3, the end of the alpha chain (Dave, 16 Oct and 5 Nov 2026), and shares `scripts/main.gd` and the save files.
- **SP-8b** (`plans/now/meadow-terrain.md`) -- height's effects: flight cost, where flowers grow, scouting reach; waits for SP-8a and AR-4, and is cut then.
- **CQ-S1** (`plans/now/code-health.md`) -- Flower owns its save fields, the first entity to own its `to_save()`/`from_save()`; waits for the save slices ED-2, ED-3, RR-12 and SP-8a (Dave, 18 Oct 2026); CQ-S0's round-trip harness landed 22 Oct 2026.
- **CQ-S2** (`plans/now/code-health.md`) -- HiveCell owns its save fields; waits for CQ-S1, which sets the `to_save()`/`from_save()` pattern and shares the save files.
- **CQ-R13** (`plans/now/code-health.md`) -- `main.gd::_ready` into build steps; waits for CQ-R2, which shares `scripts/main.gd`, and then needs its slice specification.
- **CQ-R4** (`plans/now/code-health.md`) -- `bee.gd::_process` into four helpers, profiled (high); needs its section and block, written by the session that claims CQ-R3 (HP-3 landed 18 Oct 2026).
- **CQ-T4** (`plans/now/code-health.md`) -- the remaining scripts and tests typed and `untyped_declaration` made an error; waits for the Codex lane's PN-8 and PN-14, which hold two of its files.
- **CQ-L3** (`plans/now/code-health.md`) -- one-off `gdformat` over every `.gd` file, then `--check` joins verify; waits for both lanes to empty.
- **CQ-M4** (`plans/now/code-health.md`) -- name Challenge level ids; waits for the Claude lane to release `scripts/save_game.gd` and `scripts/saving.gd`.
- **CQ-M6b** (`plans/now/code-health.md`) -- the cell ring and the selection layer read the selection green; waits for the Claude lane's PN-5, PN-6 and PN-9, which edit `scripts/input_selection.gd` and `scripts/hive_cell.gd`.
- **CQ-M7** (`plans/now/code-health.md`) -- world draw order named; waits for CQ-M6b and then needs its section and block.
- **PN-8** (`plans/now/play-notes-hud.md`) -- Warning history in the Colony window; waits for PN-3 and ED-2 (Claude lane) to release `scripts/session.gd`.
- **PN-10** (`plans/now/play-notes-hud.md`) -- opening goal text a new player can act on; waits for PN-3 (Claude lane) to release `tests/gp1_goals_dropdown_test.gd`.
- **PN-16** (`plans/now/play-notes-hud.md`) -- double-click a cell selects every cell of that type; waits for PN-6 (Claude lane), which shares `scripts/input_selection.gd`.
- **PN-17** (`plans/now/play-notes-hud.md`) -- Shift queues build and dig orders; waits for PN-16, which shares `scripts/input_selection.gd`.
- **HM-2** (`plans/now/hive-and-menu-art.md`) -- five top-bar buttons drawn from Dave's menu icons; waits for Dave to queue it (his call, 13 Oct 2026); its gated block is written.
- **HM-1** (`plans/now/hive-and-menu-art.md`) -- your hive and rival hives drawn from Dave's meadow hive art; waits for Dave to fit the large hive's layer 0 on its 54x41 canvas in Aseprite.
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
