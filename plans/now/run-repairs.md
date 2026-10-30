# Run repairs -- faults the 10-11 Oct 2026 hands-on pass found in archived areas

<!-- CONTEXT: plan | LAYER: active -->
Status: active | Owner: Dave / Claude Code | Next: RR-21 built on claude/RR-21, 30 Oct 2026, awaiting Dave's hands-on check; RR-20 built on claude/RR-20, 30 Oct 2026, awaiting Dave's hands-on check; RR-18 implemented on codex/RR-18, awaiting high-risk review and integration (Dave, 30 Oct 2026); RR-12 waits for ED-3 (RR-17 verified on codex/RR-17, 29 Oct 2026; RR-19 on claude/RR-19, 28 Oct 2026; RR-16 on claude/RR-16, 27 Oct 2026; RR-15 on claude/RR-15, 27 Oct 2026; RR-14 on claude/RR-14, 27 Oct 2026; RR-13 landed 27 Oct 2026; RR-11 landed 21 Oct 2026; RR-10 18 Oct, RR-8 17 Oct, RR-6 15 Oct, RR-1 to RR-5 13 Oct) | Dependency: none left (PP-3 landed 12 Oct 2026) | Verified: 2026-10-30

## Objective

Five faults the 10-11 Oct 2026 check pass confirmed in areas whose plans are
archived (Colony Run, saving, scenario reds), so they start here
(`plans/README.md`, "Plan schema"). Each slice comes from one failed check and
Dave's decision in that session (11 Oct 2026).
RR-9 to RR-11 come from the 15 Oct 2026 gameplay review
(`docs/gameplay-review-2026-10-15.md`) and Dave's decisions that day, recorded
in `.claude/rules/simulation.md` ("Nothing ferments over winter", "Fermented
nectar is not currency").

## Current state

Verified 11 Oct 2026 against master `8a7e5ac`:

- The queen's "Build cell" button is Challenge 1 only:
  `challenge_runner.gd::_enter_stage` calls
  `hud.set_queen_build_button_visible(Session.starting_level == 1)` and the
  Challenge's end sets it false. Outside Challenge 1 the queen can build only
  as a Comb worker, a role gated by `skill.colony.comb_worker`
  (`roles.gd`), which a lone Colony Run queen cannot buy: she has no cell to
  store its price in. So a Colony Run never gets its first cell (C-109).
- On a fresh boot `main.gd::_ready` returns at `if Session.menu_pending:`
  before `hud = Hud.new()`. The main menu's cog -> "Saves..." runs
  `debug_panel.gd::_on_load_pressed`, which reads
  `worlds[0].hud.saves_panel` and errors on a null `hud` (C-108).
- `Session.run_name` defaults to "My colony" and `reset_run_state` keeps it,
  so every unnamed run shares one slot. `game_over.gd` offers the newest
  checkpoint in that slot -- a day-30 one from an earlier run, on a run that
  died on day 3 (C-111).
- Nothing sets a minimum window size (`project.godot` has no display
  section; no `min_size` in `scripts/`), though `ui_layout.gd`'s
  `MIN_SUPPORTED_WIDTH` is 800. The window drags to 803x408 and the cell
  tray runs off the bottom (C-103).

## Open slices

| Slice | What it does | Files it owns | Startable | Level |
| --- | --- | --- | --- | --- |
| RR-12 | a loaded run keeps its readout history (graphs, emergence, day stores, foraging counters) | `scripts/save_game.gd`, `scripts/saving.gd`, `scripts/foraging_stats.gd`, `scripts/main.gd`, tests | no -- after ED-3 releases the save files | medium |
| RR-18 | skip saves for the long checks C-140 and C-142 | `tools/run_scenario.py`, `tests/test_scenario_save_install.py`, `test_scenarios/`, `checks/ready/C-140.md`, `checks/ready/C-142.md` | yes | high |
| RR-22 | select a number of bees from a multi-selection, youngest and oldest | `scripts/hud.gd`, `scripts/input_selection.gd`, `scripts/main.gd`, tests | no -- after the Codex lane's CQ-R6 releases `scripts/hud.gd` (CQ-R10 landed 27 Oct 2026; GP-5 and SG-4 landed 26 Oct 2026) | medium |

RR-9 and RR-10 are Codex-lane slices (Dave, 15 Oct 2026, plan review D3:
the Claude lane was full and the Codex backlog dry); RR-7 and RR-11 stay in
the Claude lane, and RR-11 opens only once SP-11 and RR-10 have both landed.

Each slice reads its own section only. Do not change skill prices, the
branch-tier rule (settled by `plans/now/tier-two.md` T2-9, landed 12 Oct 2026), or the save
format.

RR-6 shipped 2026-10-15; its specification is `plans/archive/RR-6_2026-10-15.md`.

RR-7 shipped 2026-10-16; its specification is `plans/archive/RR-7_2026-10-16.md`.

RR-8 shipped 2026-10-17; its specification is `plans/archive/RR-8_2026-10-17.md`.

RR-9 shipped 2026-10-17; its specification is `plans/archive/RR-9_2026-10-17.md`.

**Code health (`plans/now/code-health.md`, 18 Oct 2026).** CQ-L1 (gdlint fixes in `hive.gd` and `skill_tree_panel.gd`) landed 22 Oct 2026. Its save moves (CQ-S1 to CQ-S5, CQ-R2) wait for this plan's slices that edit `scripts/save_game.gd`/`scripts/saving.gd` (RR-12); add new save fields the current way, and the round-trip goldens of CQ-S0 are re-captured by whichever slice adds a field.

RR-10 shipped 2026-10-18; its specification is `plans/archive/RR-10_2026-10-18.md`.

RR-11 shipped 2026-10-21; its specification is `plans/archive/RR-11_2026-10-21.md`.

## RR-12 -- a loaded run keeps its readout history

Level: medium (one additive save key, four collections, an exactness test).
UI review 16 Oct 2026, hand-off from the save review; Dave's decision D1:
"A -- save all four as additive optional fields".

**True now** (verified 16 Oct 2026). `save_game.gd::save` writes no readout
history, so after a load `main.gd`'s `history_samples` (colony graph; entries
`{t, bees, nectar, pollen, honey}`), `emergence_log` (`{t, key}`),
`day_store_totals` (`{day, nectar, pollen, nectar_collected,
pollen_collected}`, read by `conditions.gd` and `colony_milestones.gd`) and
`foraging_stats.gd`'s counters (`trips_recorded`, `total_flowers_visited`,
`total_search_flight_seconds`, `total_handling_seconds`, `total_trip_seconds`,
`empty_returns`, `_by_species`) all start empty. The comment above
`day_store_totals` in `main.gd` says "Not saved".

**True afterwards.** `save_game.gd::save` writes
`"readout_history": {"history_samples": [...], "emergence_log": [...],
"day_store_totals": [...], "foraging": world.foraging_stats.save_data()}`.
`foraging_stats.gd` gains `save_data() -> Dictionary` (the six counters and
`_by_species`) and `restore(data) -> void`. `saving.gd`'s restore reads
`data.get("readout_history", {})` and assigns each collection, each through a
`.get(key, [])` default, trimmed to its cap (`GameConfig.history_points`,
`DAY_STORE_SAMPLES`, and the emergence window as `_trim_emergence_log`
does). The `t` values are `Session.sim_time` values, which a load already
restores, so no re-basing is needed. The `day_store_totals` comment in
`main.gd` is corrected. No `FORMAT_VERSION` bump and no migration
(`.claude/rules/saving.md`, additive fields).

**Must not change.** `FORMAT_VERSION` (6); an old save with no key loads and
starts the four empty exactly as today; a malformed entry (wrong type) is
skipped, never an error; the checkpoint restore stays exact; nothing in
`foraging_stats.gd::record_trip`'s behaviour.

**Check.** `python -m unittest tests.test_rr12_readout_history` runs
`tests/rr12_readout_history_test.gd` (model on `tests/bs14_saved_skill_policy_test.gd`):
run a seeded scene long enough to hold at least three history samples and two
day-store entries and one recorded trip, save, load, and the four collections
equal what was saved; load a save with the key deleted and all four are empty
and the load succeeds. `python -m unittest tests.test_save_migrations` still passes.

**Stop and escalate** if the saved size grows by more than about 20 KB, or a
test shows `day_store_totals` changing a condition's result across a load
(report the figures; do not tune).

```queue-gated
**[Claude] RR-12 -- a loaded run keeps its readout history**
- Plan: `plans/now/run-repairs.md` -- "RR-12 -- a loaded run keeps its readout history"
- Files: `scripts/save_game.gd`, `scripts/saving.gd`, `scripts/foraging_stats.gd`, `scripts/main.gd`, `tests/rr12_readout_history_test.gd`, `tests/test_rr12_readout_history.py`
- Check: `python -m unittest tests.test_rr12_readout_history` passes: after a save and load of a run holding history samples, day-store entries, an emergence entry and a recorded trip, `history_samples`, `emergence_log`, `day_store_totals` and `foraging_stats.save_data()` equal their saved values, and a save with `readout_history` removed loads with all four empty; `python -m unittest tests.test_save_migrations` still passes.
- Proof: `absent: scripts/save_game.gd :: readout_history`
- Next after: none -- `plans/now/run-repairs.md` is complete once RR-8 and RR-11 have landed
```

RR-13 shipped 2026-10-27; its specification is `plans/archive/RR-13_2026-10-27.md`.

RR-14 shipped 2026-10-27; its specification is `plans/archive/RR-14_2026-10-27.md`.

RR-15 shipped 2026-10-27; its specification is `plans/archive/RR-15_2026-10-27.md`.

RR-16 shipped 2026-10-27; its specification is `plans/archive/RR-16_2026-10-27.md`.

RR-17 shipped 2026-10-29; its specification is `plans/archive/RR-17_2026-10-29.md`.

## RR-18 -- skip saves for the long checks C-140 and C-142

Level: high -- player save ownership and atomic catalogue installation; high-risk review/integration required.

**True now.** Checks C-140 (the first crisis, warned) and C-142 (work
priorities) take more than five minutes of play to reach, so they break the
five-minute rule (`plans/reference/check-loop.md` rule 3). Templates:
`test_scenarios/fc2_first_crisis_prepared.json` and
`test_scenarios/wp3_backup_order_ui.json`.

**Decision (Dave, 30 Oct 2026).** The specified commands initially produced
only isolated scratch saves: verified against tools/run_scenario.py's
private_user_env and scripts/save_slots.gd's ROOT/SCRATCH_ROOT.
Dave authorised an explicit opt-in runner installation mechanism followed by
the original checks. tools/run_scenario.py owns headless orchestration and
is extended here; the runtime save owner and schema remain unchanged.
Ordinary runs stay isolated. Installation runs once after a successful
single headless verdict, with the game closed. Validate the source named
slot and current-format payload, preserve existing player catalogue entries,
refuse name/slug/file collisions, and expose the copied payload through an
atomic index replacement. Serialise installers and refuse catalogue changes
detected during copying. Keep this mechanism in a separate commit from the
fixtures and check instructions. This expands the original no-script scope;
the player catalogue write makes closeout high risk despite no schema change.
The coordinator verified ownership of the runner is clear.

**When done:**

1. `test_scenarios/c140_first_crisis_warned.json` copies the first, with a
   `when: {first_crisis_state: "warned"}` action `save_run` named "C140 warned".
2. `test_scenarios/c142_work_priorities.json` grants
   `skill.hive_mind.work_priorities`, hatches three or more bees in mixed
   roles (as the second template does), then runs `save_run` named
   "C142 work priorities".
3. `checks/ready/C-140.md` and `checks/ready/C-142.md` have "What this checks"
   rewritten to: run the scenario once headless from the repo root (home: `cd
   C:\Users\david\Documents\Meadow\meadow`; work: `cd
   C:\Users\dl13860\Documents\Meadow\meadow`; in PowerShell, the exact
   `python tools/run_scenario.py test_scenarios/<file>.json` line with --install-save and the named save), with the game closed, then open the
   named save from the cog menu > Saves and carry on from there.
4. Each scenario is run with its explicit --install-save name and the
   save is seen in the player's save catalogue. Focused temporary-directory
   tests cover preservation, collisions, malformed source/index/payload,
   failed index replacement, concurrent installers/catalogue changes, and
   isolation for ordinary or unsuccessful runs.

**Invariants.** The checks' pass conditions are unchanged; only the way to
reach them. No runtime saving-code, save-schema or simulation changes.

**Open decisions:** none.

```queue
**[Codex] RR-18 -- skip saves for the long checks C-140 and C-142**
- Plan: `plans/now/run-repairs.md` -- "RR-18 -- skip saves for the long checks C-140 and C-142"
- Files: `tools/run_scenario.py`, `tests/test_scenario_save_install.py`, `test_scenarios/c140_first_crisis_warned.json`, `test_scenarios/c142_work_priorities.json`, `checks/ready/C-140.md`, `checks/ready/C-142.md`
- Check: `python tests/test_scenario_save_install.py`; `python tools/run_scenario.py test_scenarios/c140_first_crisis_warned.json --install-save "C140 warned"` and `python tools/run_scenario.py test_scenarios/c142_work_priorities.json --install-save "C142 work priorities"` each finish and leave their named save in the saves list; `python tools/check_docs.py` passes; `.\tools\verify.ps1` is green
- Proof: `absent: checks/ready/C-140.md :: run_scenario`
- Next after: none -- the long-check skip saves are complete
```

RR-19 shipped 2026-10-28; its specification is `plans/archive/RR-19_2026-10-28.md`.

RR-20 shipped 2026-10-30; its specification is `plans/archive/RR-20_2026-10-30.md`.

RR-21 shipped 2026-10-30; its specification is `plans/archive/RR-21_2026-10-30.md`.

## RR-22 -- select a number of bees from a multi-selection

Level: medium -- claude-sonnet-5-5 at medium effort.

**True now.** Dave: a button to select n bees, "select 1 bee as default for n,
with '<<' '<' '>' '>>' buttons to change n by +/- 1 or 5. Also adds buttons
for 'Select youngest bee', and 'Select oldest bee'". The multi-selection
summary is the `else` branch of the identity-label code in
`hud.gd::update_selection` (near l.3739, "%d bees selected",
`_set_summary_cog_kind("multiple")`). The selection list is
`main.selected_bees`, set in `input_selection.gd` (near l.168-184) and shown
through `hud.update_selection`. A bee's age is `Bee.age_seconds`.

**When done:**

1. The multi-selection summary has a "Select n" row: `<<`, `<`, a count, `>`,
   `>>` (steps of 5 and 1), n starting at 1 and clamped to 1..the selection
   size, and a "Select" button that narrows `selected_bees` to n bees
   through a new hud signal handled in `input_selection.gd` (wired in
   `main.gd`), deselecting the rest with `set_selected(false)`.
2. Which n bees are kept: the n nearest the selection's centre. This is
   provisional, Dave to confirm at the hands-on check.
3. "Select youngest bee" and "Select oldest bee" narrow the selection to the one
   bee with the least or greatest `age_seconds`.
4. The row follows `plans/reference/ui-rules.md` and fits at the minimum
   width (`tests/test_layout_regression.py`); a new test checks the narrowing,
   the clamp and both extremes.
5. Dave's hands-on check is filed at closeout: drag-select a crowd, narrow it
   by n, youngest and oldest.

**Invariants.** A single selection shows no row. Selecting never alters the
simulation. Presentation and selection state only.

**Open decisions:** which n bees `Select n` keeps (nearest the centre is
provisional; Dave answers it at the hands-on check).

```queue-gated
**[Claude] RR-22 -- select a number of bees from a multi-selection**
- Plan: `plans/now/run-repairs.md` -- "RR-22 -- select a number of bees from a multi-selection"
- Files: `scripts/hud.gd`, `scripts/input_selection.gd`, `scripts/main.gd`, `tests/test_layout_regression.py`, `tests/rr22_select_n_test.gd`, `tests/test_rr22_select_n.py`
- Check: `python -m unittest tests.test_rr22_select_n` passes (n is clamped to 1..selection size, `>>` steps by 5, Select keeps n bees, youngest and oldest keep the one bee with the least or greatest age); `python -m unittest tests.test_layout_regression` passes; `.\tools\verify.ps1` is green; Dave's hands-on check is filed
- Proof: `absent: scripts/hud.gd :: select_youngest`
- Next after: none -- multi-selection narrowing is complete
```

## Not in the queue, and why

- **Save audit observations, 29 Oct 2026** -- evidence and correction criteria:
  `plans/reference/jules-integration-2026-10-29.md` (J-32). `bee.gd:125`
  explicitly documents resetting nuptial flights on load; retain that
  contract until Dave chooses whether a future save should resume the full
  flight (including phase, timer, position and day) or return safely home.
  `rival_hive.gd::save_data`/`restore` omit `tick_timer`; decide whether exact
  cadence must survive reload before adding a save field. In
  `saving.gd::_restore_bees`, a malformed entry with only `start_x` produces
  an infinite y coordinate; reproduce it in an isolated save fixture and
  agree whether to reject the record or fall back to an unset start point
  before admitting a repair. No save schema or fallback changes are part
  of the Jules integration, and its incomplete Inventory is not accepted.

- **RR-22** -- select a number of bees from a multi-selection; waits for the Codex lane's CQ-R6 (`plans/now/code-health.md`) to release `scripts/hud.gd`, which both name (gated 27 Oct 2026 to clear check_docs' lane collision).
- **RR-12** -- a loaded run keeps its readout history; waits for ED-3, the last of the alpha chain, because SG-2 to ED-3 share `scripts/main.gd`, `scripts/save_game.gd` and `scripts/saving.gd`.
