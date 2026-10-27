# Run repairs -- faults the 10-11 Oct 2026 hands-on pass found in archived areas

<!-- CONTEXT: plan | LAYER: active -->
Status: active | Owner: Dave / Claude Code | Next: RR-12, the last slice, waits for ED-3 (RR-13 landed 27 Oct 2026; RR-11 landed 21 Oct 2026; RR-10 18 Oct, RR-8 17 Oct, RR-6 15 Oct, RR-1 to RR-5 13 Oct) | Dependency: none left (PP-3 landed 12 Oct 2026) | Verified: 2026-10-24

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
| RR-14 | a sour cell given a new designation is emptied by a comb worker, not at once | `scripts/orders_zones.gd`, `scripts/hud.gd`, tests | yes -- DR-1 landed 25 Oct 2026 | low |
| RR-15 | Fermentation sense keeps fresh nectar out of sour cells for every depositing bee | `scripts/hive.gd`, tests | yes -- DR-1 landed 25 Oct 2026 | medium |
| RR-16 | the queen can resume building a part-built cell | `scripts/orders_zones.gd`, tests | yes -- DR-1 landed 25 Oct 2026 | low |
| RR-17 | a queen on comb work discards sour nectar on command | `scripts/bee.gd`, tests | yes -- CQ-S0b landed 25 Oct 2026 | medium |
| RR-18 | skip saves for the long checks C-140 and C-142 | `test_scenarios/`, `checks/ready/C-140.md`, `checks/ready/C-142.md` | yes | low |
| RR-19 | comb workers seal and unseal cells over time (15 s to cap, 5 s to uncap) | `scripts/hive_cell.gd`, `scripts/orders_zones.gd`, `scripts/actions.gd`, `scripts/bee_building.gd`, `scripts/hive.gd`, `scripts/game_config.gd`, `scripts/save_game.gd`, `scripts/saving.gd`, tests | yes -- DR-1 and CQ-M8 landed 25 Oct 2026 | high |
| RR-20 | a comb worker carrying a body leaves, stays out one second, and comes back | `scripts/bee_building.gd`, `scripts/bee_movement.gd`, `scripts/game_config.gd`, tests | yes -- CQ-M8 landed 25 Oct 2026 | medium |
| RR-21 | no ordinary rain in the first two days; rain warnings in plain words | `scripts/main.gd`, `scripts/game_config.gd`, `scripts/settings_catalogue.gd`, tests | yes -- SG-4 landed 26 Oct 2026 | medium |
| RR-22 | select a number of bees from a multi-selection, youngest and oldest | `scripts/hud.gd`, `scripts/input_selection.gd`, `scripts/main.gd`, tests | no -- after the Codex lane's CQ-R10 releases `scripts/input_selection.gd` (GP-5 and SG-4 landed 26 Oct 2026) | medium |

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

## RR-14 -- a sour cell given a new designation is emptied by a comb worker, not at once

Level: low -- claude-sonnet-5-5 at low effort.

**True now.** Dave: "when designating a sour nectar cell as a honey cell, it
instantly emptied, when bees should be doing that task".
`orders_zones.gd::_designate_one` (near l.262) calls `cell.clear_cell()` on a
conflicting cell, and `hud.gd::_apply_discard` (near l.2683) does the same after
the discard warning. "Discard all sour nectar" (`_on_clear_fermented_requested`)
instead marks the cell `evict_mode = "discard"`, `evict_requested = true`, and a
comb worker's `comb_evict_cell` task empties it.

**When done:**

1. In `_designate_one`, when `cell.is_fermented()` and the cell holds stock,
   the cell takes the designation, is marked `evict_mode = "discard"` and
   `evict_requested = true`, `bump_display_epoch()` runs, and the function
   returns before the clear or warning branches.
2. `hud.gd::_apply_discard` follows the same rule for a sour pending cell (one
   shared helper in `orders_zones.gd`, not two copies).
3. A cell that is not sour behaves exactly as today.

**Invariants.** Uses the existing saved eviction fields; no new field, no save
change. A sour cell with no comb worker stays full until one is free.

**Open decisions:** none.

```queue
**[Claude] RR-14 -- a sour cell given a new designation is emptied by a comb worker, not at once**
- Plan: `plans/now/run-repairs.md` -- "RR-14 -- a sour cell given a new designation is emptied by a comb worker, not at once"
- Files: `scripts/orders_zones.gd`, `scripts/hud.gd`, `tests/test_nf5_clear_fermented.py`
- Check: `python -m unittest tests.test_nf5_clear_fermented` passes with a new case (designating a sour nectar cell as honey leaves its stock and sets `evict_requested`, and a comb worker then empties it; a fresh nectar cell behaves as before); `.\tools\verify.ps1` is green
- Proof: `absent: scripts/orders_zones.gd :: is_fermented() and`
- Next after: none -- the sour-cell designation is complete
```

## RR-15 -- Fermentation sense keeps fresh nectar out of sour cells for every depositing bee

Level: medium -- claude-sonnet-5-5 at medium effort (a gameplay outcome).

**True now.** Dave: "Queen set to forager still adds nectar to sour nectar
cells even with fermentation sense". NF-4's rule is that fresh nectar is never
poured into sour. `hive.gd::find_cell_for` (near l.328), called from
`bee_foraging.gd` (near l.948 and l.984), never calls `avoids_as_sour`, so any
depositing bee, the queen included, can top up a fermented cell.

**When done:**

1. In `find_cell_for`, when `resource_type == "nectar"` and
   `senses_fermentation()`, cells where `avoids_as_sour(cell)` is true are
   skipped.
2. `find_cell_for` is shared by haul and evict, so sour nectar can still be
   moved: `bee_building.gd` (near l.161) already discards rather than moves, and
   the slice proves that no haul path loses its destination.
3. The closeout runs the reference arc before and after
   (`python tools/run_scenario.py test_scenarios/alpha_arc_test.json`) and
   reports the difference. Do not tune anything.

**Invariants.** Without Fermentation sense nothing changes. Honey, pollen and
bee bread deposits are untouched.

**Stop and escalate** if the arc's outcome changes by more than a day on any
gate.

**Open decisions:** none.

```queue
**[Claude] RR-15 -- Fermentation sense keeps fresh nectar out of sour cells for every depositing bee**
- Plan: `plans/now/run-repairs.md` -- "RR-15 -- Fermentation sense keeps fresh nectar out of sour cells for every depositing bee"
- Files: `scripts/hive.gd`, `tests/test_nf4_fermentation_sense.py`
- Check: `python -m unittest tests.test_nf4_fermentation_sense` passes with a new case (a forager, and the queen set to forage, with Fermentation sense never deposit nectar into a sour cell; without the sense they still can); `python -m unittest tests.test_nf5_clear_fermented` passes; the before/after `alpha_arc_test.json` outputs are recorded in the closeout; `.\tools\verify.ps1` is green
- Proof: `absent: scripts/hive.gd :: avoids_as_sour(cell)`
- Next after: none -- the fermentation-sense deposit rule is complete
```

## RR-16 -- the queen can resume building a part-built cell

Level: low -- claude-sonnet-5-5 at low effort.

**True now.** Dave: "the queen's build cell behaviour should be able to be
applied to an incomplete cell, which she then continues to build".
`orders_zones.gd::queen_build_at` (near l.24) needs `hive.can_build_on(hex)`,
which fails on a tile that already holds a site, so she cannot be sent to
finish one.

**When done:**

1. If `hive.cell_at_tile(hex)` is an unbuilt cell, `queen_build_at` uses it as
   `target_cell` and sets `TO_BUILD_SITE`, creating nothing. A tile with no cell
   behaves as today.
2. A tile holding a finished cell still returns null.

**Invariants.** A Challenge's overrides in `challenge_runner.gd` still apply
afterwards. No save change.

**Open decisions:** none.

```queue
**[Claude] RR-16 -- the queen can resume building a part-built cell**
- Plan: `plans/now/run-repairs.md` -- "RR-16 -- the queen can resume building a part-built cell"
- Files: `scripts/orders_zones.gd`, `tests/test_rr1_queen_builds.py`
- Check: `python -m unittest tests.test_rr1_queen_builds` passes with a new case (a part-built site is returned and the queen heads to it; a finished cell returns null; an empty tile still makes a site); `.\tools\verify.ps1` is green
- Proof: `absent: scripts/orders_zones.gd :: cell_at_tile`
- Next after: none -- the queen's build is complete
```

## RR-17 -- a queen on comb work discards sour nectar on command

Level: medium -- claude-sonnet-5-5 at medium effort (cause unconfirmed).

**True now.** Dave: "The queen doesn't respond appropriately when set to comb
worker and selecting 'Discard all sour nectar'". The command marks cells
`evict_requested`; comb workers take `comb_evict_cell` (`actions.gd`, near l.74,
via `bee_building.gd::find_cell_needing_eviction`, near l.38). No queen
exclusion was found. Suspects: the queen never reaches `bee.gd::_idle_dispatch`
while laying or feeding, or her `architect_mode` skips the evict row.

**When done:**

1. First a failing repro: `test_scenarios/rr17_queen_discards_sour.json`, a
   headless scenario with the queen in the comb-worker role, one sour cell and
   the command issued, asserting the cell is emptied by her within a stated
   number of seconds. `tests/test_nf5_clear_fermented.py` gains a case that runs it and fails
   before the fix.
2. The smallest fix in `scripts/bee.gd` that makes it pass.
3. Dave's hands-on check is filed at closeout: queen on comb work, press
   "Discard all sour nectar", she empties a sour cell.

**Invariants.** Her laying and feeding priorities are unchanged. If the cause
turns out to be a design question (should the queen ever leave egg-laying?),
stop and escalate with the options.

**Open decisions:** none.

```queue
**[Claude] RR-17 -- a queen on comb work discards sour nectar on command**
- Plan: `plans/now/run-repairs.md` -- "RR-17 -- a queen on comb work discards sour nectar on command"
- Files: `scripts/bee.gd`, `test_scenarios/rr17_queen_discards_sour.json`, `tests/test_nf5_clear_fermented.py`
- Check: `python -m unittest tests.test_nf5_clear_fermented` (its new queen case) fails before the fix and passes after it (the queen, set to comb work, empties a sour cell after the command); `.\tools\verify.ps1` is green; Dave's hands-on check is filed
- Proof: `absent: tests/test_nf5_clear_fermented.py :: queen`
- Next after: none -- the sour-nectar repairs are complete
```

## RR-18 -- skip saves for the long checks C-140 and C-142

Level: low -- claude-haiku-5-5 (run each scenario and confirm the save appears).

**True now.** Checks C-140 (the first crisis, warned) and C-142 (work
priorities) take more than five minutes of play to reach, so they break the
five-minute rule (`plans/reference/check-loop.md` rule 3). Templates:
`test_scenarios/fc2_first_crisis_prepared.json` and
`test_scenarios/wp3_backup_order_ui.json`.

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
   `python tools/run_scenario.py test_scenarios/<file>.json` line), then open the
   named save from the cog menu > Saves and carry on from there.
4. Each scenario is run and the save is seen to appear.

**Invariants.** The checks' pass conditions are unchanged; only the way to
reach them. No script changes.

**Open decisions:** none.

```queue
**[Claude] RR-18 -- skip saves for the long checks C-140 and C-142**
- Plan: `plans/now/run-repairs.md` -- "RR-18 -- skip saves for the long checks C-140 and C-142"
- Files: `test_scenarios/c140_first_crisis_warned.json`, `test_scenarios/c142_work_priorities.json`, `checks/ready/C-140.md`, `checks/ready/C-142.md`
- Check: `python tools/run_scenario.py test_scenarios/c140_first_crisis_warned.json` and `python tools/run_scenario.py test_scenarios/c142_work_priorities.json` each finish and leave their named save in the saves list; `python tools/check_docs.py` passes; `.\tools\verify.ps1` is green
- Proof: `absent: checks/ready/C-140.md :: run_scenario`
- Next after: none -- the long checks have skip saves
```

## RR-19 -- comb workers seal and unseal cells over time

Level: high -- claude-sonnet-5-5 at high effort (saves, event ordering, a gameplay outcome).

**True now.** C-127 failed. `hive_cell.gd::set_closed` (near l.1063) flips
`is_closed` at once, called from `orders_zones.gd` (near l.105).
`set_fill_then_close` (near l.1070) only converts to closed in `add_resource`
(near l.908-912), on `amount >= capacity - 0.001` right after a deposit, so a
cell filled by nectar-to-honey conversion, royal jelly or brood never seals
(the bug). `take_resource` and `can_withdraw` (near l.1028 and l.1058) lock
from the moment a flag is set. Bee bread's ripening cap (BB-1, near l.915) is
intended and stays. The winter close (`season.gd`, near l.299-306) calls
`set_closed` and stays instant. Eviction is the pattern to follow: a saved
`evict_requested` flag, the `comb_evict_cell` row in `actions.gd`, and a
finder in `bee_building.gd`.

**When done** (a comb worker, over time; 15 s to cap and 5 s to uncap at x1,
Dave, 24 Oct 2026):

1. Seal, Open and "Fill then seal" set a saved pending flag (`pending_seal`,
   `pending_open`) instead of flipping `is_closed`. "Fill then seal" sets
   `pending_seal` as soon as the cell is full, tested wherever `amount`
   changes (not only after a deposit), so converted honey, jelly and brood
   cells seal too.
2. A comb worker (the `Roles.COMB_WORKER` role, the queen on comb work as well)
   takes a new action row beside `comb_evict_cell` (band 1), finds the cell
   through a new finder in `bee_building.gd`, walks to it, and spends
   `GameConfig.cell_seal_seconds` (15.0) capping or
   `GameConfig.cell_unseal_seconds` (5.0) uncapping, both with settings rows.
   The queen follows RR-17's finding about her reaching the dispatch.
3. While she works the cap art steps through its `WAX_CELL_SEALED` frames
   (`_refresh`, near l.1382; `_show_cap`, near l.1448), forwards to seal and
   backwards to open. Stores stay usable until the cap closes and become
   usable once it is open.
4. Saves: the two flags are new fields in `save_game.gd` and `saving.gd` (near
   l.200-207), defaulting to false for old saves. `tests/test_save_migrations.py`
   covers an old save.
5. The closeout runs the reference arc before and after
   (`python tools/run_scenario.py test_scenarios/alpha_arc_test.json`) and
   reports the difference. Do not tune anything.
6. `test_scenarios/rr19_sealing_stocked.json` stocks a full honey cell, a full
   jelly cell and a full brood cell with `set_cell_contents` and ends with
   `save_run` named "C127 stocked", so Dave's hands-on check (the C-127 re-run)
   starts from that save and not from five minutes of play.

**Invariants.** With no comb worker free, a cell stays as it is. Winter's close
is unchanged. A cell that is already closed and asked to Seal does nothing.

**Stop and escalate** if the reference arc's honey outcome moves by more than
a day on any gate.

**Open decisions:** none.

```queue
**[Claude] RR-19 -- comb workers seal and unseal cells over time**
- Plan: `plans/now/run-repairs.md` -- "RR-19 -- comb workers seal and unseal cells over time"
- Files: `scripts/hive_cell.gd`, `scripts/orders_zones.gd`, `scripts/actions.gd`, `scripts/bee_building.gd`, `scripts/hive.gd`, `scripts/game_config.gd`, `scripts/settings_catalogue.gd`, `scripts/save_game.gd`, `scripts/saving.gd`, `test_scenarios/rr19_sealing_stocked.json`, `tests/test_rr19_sealing.py`, `tests/test_save_migrations.py`
- Check: `python -m unittest tests.test_rr19_sealing` passes (Seal on a full cell leaves it open until a comb worker has spent 15 s, then closed; Open takes 5 s; "Fill then seal" seals a cell filled by honey conversion, jelly and brood; winter's close is instant); `python -m unittest tests.test_save_migrations` passes with an old save; the before/after `alpha_arc_test.json` outputs are recorded in the closeout; `.\tools\verify.ps1` is green; Dave's hands-on check is filed
- Proof: `absent: scripts/game_config.gd :: cell_seal_seconds`
- Next after: none -- cell sealing is complete
```

## RR-20 -- a comb worker carrying a body visibly leaves, stays out one second, and comes back

Level: medium -- claude-sonnet-5-5 at medium effort.

**True now.** Dave: "make it a 1 second pause, where the bee actually leaves
the nest, stays out for one second, then comes back in". Today
`bee_building.gd::builder_go_to_waste_exit` (near l.449) walks to
`world.hive_entrance_inside()`, and within 8 px calls
`world.move_bee_out_of_hive` and sets `timer = GameConfig.dirt_dump_time`
(2.0) in `DUMPING_WASTE`. Dave saw her "wait at the inside entrance", so she
reads as waiting inside, not outside. Suspects: an empty path returning early
in `bee_movement.gd` (near l.387-389) so she never reaches the 8 px test, or
the hive view still drawing her.

**When done:**

1. The slice first finds why she reads as waiting inside and says in the
   closeout what it was.
2. For a body, a new `GameConfig.body_drop_seconds` (1.0, settings row) is the
   time outside; `dirt_dump_time` still governs spoil and stores. The bee is
   visibly outside the skep for that second, then re-enters.
3. `tests/t2_4b_bodies_test.gd` and `tests/t2_13_carried_body_test.gd` assert
   she is outside for the second and inside again after it.
4. Dave's hands-on check is filed at closeout: watch a comb worker carry a body
   out, wait one second outside and return.

**Invariants.** Stores and spoil dumps keep `dirt_dump_time`. If the cause is
in `bee.gd` (CQ-S0b's file) stop and escalate with the options.

**Open decisions:** none.

```queue
**[Claude] RR-20 -- a comb worker carrying a body visibly leaves, stays out one second, and comes back**
- Plan: `plans/now/run-repairs.md` -- "RR-20 -- a comb worker carrying a body visibly leaves, stays out one second, and comes back"
- Files: `scripts/bee_building.gd`, `scripts/bee_movement.gd`, `scripts/game_config.gd`, `scripts/settings_catalogue.gd`, `tests/t2_4b_bodies_test.gd`, `tests/t2_13_carried_body_test.gd`
- Check: `python -m unittest tests.test_t2_4b_bodies tests.test_t2_13_carried_body` pass (the body-carrying bee is outside the hive for 1 s then inside again); `.\tools\verify.ps1` is green; Dave's hands-on check is filed
- Proof: `absent: scripts/game_config.gd :: body_drop_seconds`
- Next after: none -- the body drop is complete
```

## RR-21 -- no ordinary rain in a run's first two days, and rain warnings say when in plain words

Level: medium -- claude-sonnet-5-5 at medium effort (a gameplay outcome).

**True now.** Dave: rain must not "happen at the very start of a game, or in
the first 2 days, unless rain coming sooner is a part of a scenario or
challenge", and warnings should "use more general terms, like soon or 'by the
end of the day'". `main.gd::_advance_weather` (near l.981-1012) rolls six
times a day at `rain_chance_per_day / 6` while `_first_crisis_holds_weather()`
is false, from time zero. The first crisis schedules and starts its own rain
(`_advance_first_crisis`), outside the roll. Warnings give clock times:
`_first_crisis_warning_text` (near l.1148, "coming in about %s"),
`_show_first_crisis_note` (near l.1179, "Heavy rain due in %s") through
`_minutes_text`, and the generic "Rain is coming in" warning (near l.1008) has
no time at all.

**When done:**

1. `GameConfig.rain_free_days` (2.0, settings row): the random roll is skipped
   while `Session.sim_time < rain_free_days * seconds_per_day`. The first crisis
   and any scenario or Challenge that starts rain itself are unaffected, and
   a scenario that wants an early random roll sets `rain_free_days` to 0 with
   `set_config` (Dave, 24 Oct 2026).
2. One helper turns the time left and the time of day into a plain phrase:
   "soon" (within about a game hour), "later today", "by the end of the day",
   "tomorrow". The first-crisis warning and corner note use it instead of
   minutes and seconds, and the generic rain warning says when it is due only
   if a time is known.
3. `tests/test_fc2_first_crisis.py` and the display-text golden
   (`python -m unittest tests.test_display_text_golden`) are updated for the
   new wording.
4. The closeout runs the reference arc before and after and reports the
   difference in rain timing. Do not tune anything.
5. Dave's hands-on check is filed at closeout; C-140 (the first crisis)
   re-runs after it from its skip save (RR-18).

**Invariants.** The first crisis keeps its schedule and bounds. No save change.
Shares `scripts/main.gd` with SG-4 and the Select-n slice RR-22: whichever is
queued first runs first.

**Open decisions:** none.

```queue
**[Claude] RR-21 -- no ordinary rain in a run's first two days, and rain warnings say when in plain words**
- Plan: `plans/now/run-repairs.md` -- "RR-21 -- no ordinary rain in a run's first two days, and rain warnings say when in plain words"
- Files: `scripts/main.gd`, `scripts/game_config.gd`, `scripts/settings_catalogue.gd`, `tests/test_fc2_first_crisis.py`, `tests/test_rr21_rain_free_days.py`
- Check: `python -m unittest tests.test_rr21_rain_free_days tests.test_fc2_first_crisis tests.test_display_text_golden` pass (no random rain before day 2 even at a chance of 1.0; rain rolls again after; the first crisis still fires; warnings read "soon", "later today", "by the end of the day" or "tomorrow"); the before/after `alpha_arc_test.json` outputs are recorded in the closeout; `.\tools\verify.ps1` is green; Dave's hands-on check is filed
- Proof: `absent: scripts/game_config.gd :: rain_free_days`
- Next after: none -- the rain rule is complete
```

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

```queue
**[Claude] RR-22 -- select a number of bees from a multi-selection**
- Plan: `plans/now/run-repairs.md` -- "RR-22 -- select a number of bees from a multi-selection"
- Files: `scripts/hud.gd`, `scripts/input_selection.gd`, `scripts/main.gd`, `tests/test_layout_regression.py`, `tests/rr22_select_n_test.gd`, `tests/test_rr22_select_n.py`
- Check: `python -m unittest tests.test_rr22_select_n` passes (n is clamped to 1..selection size, `>>` steps by 5, Select keeps n bees, youngest and oldest keep the one bee with the least or greatest age); `python -m unittest tests.test_layout_regression` passes; `.\tools\verify.ps1` is green; Dave's hands-on check is filed
- Proof: `absent: scripts/hud.gd :: select_youngest`
- Next after: none -- multi-selection narrowing is complete
```

## Not in the queue, and why

- **RR-12** -- a loaded run keeps its readout history; waits for ED-3, the last of the alpha chain, because SG-2 to ED-3 share `scripts/main.gd`, `scripts/save_game.gd` and `scripts/saving.gd`.
