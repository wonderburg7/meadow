# Gameplay consistency — a job change keeps the bee and her load, and honey stores energy without creating it

<!-- CONTEXT: plan | LAYER: immediate-task -->
Status: active | Owner: Dave / Claude Code | Next: GC-2 -- a bee changing job puts down what she carries (startable); GC-3 -- honey stops creating energy (gated on PE-2) | Dependency: GC-3 waits for PE-2 (`plans/now/pacing-evidence.md`) | Verified: 2026-10-01

**Objective.** Three rules that the code breaks today hold again: an Idle bee
does what the Idle tooltip says, a change of job never loses what the bee is
carrying, and making honey follows `.claude/rules/simulation.md` ("must not
create energy"). Found by `docs/gameplay-review-2026-09-30.md` (F2 to F4),
each demonstrated in a headless run.

## Open slices at a glance

| Slice | Outcome from the player's seat | Files owned | Startable | Level |
| --- | --- | --- | --- | --- |
| GC-2 | a forager moved to an indoor job, or a Comb worker left holding a remnant, puts the load in the comb before anything else | `scripts/bee.gd`, `scripts/bee_foraging.gd`, `scripts/bee_building.gd`, `scripts/bee_honey.gd`, `scripts/diagnostic_log.gd`, `scripts/scenario_actions.gd`, `test_scenarios/gc2_role_change_delivers_load_test.json` | yes (GC-1 landed) | medium |
| GC-3 | a colony that turns nectar into honey has the same energy afterwards, stored four times as densely | `scripts/game_config.gd`, `scripts/settings_catalogue.gd`, `tests/source_checks.py` | gated: waits for PE-2's played arc | medium |

GC-1 and GC-2 are independent in behaviour but share `bee.gd`, so they run in
that order in one lane. GC-3 is independent of both. **Required reading:**
the slice's own section and the functions it names. **Must not change:** the
queen's behaviour anywhere (Challenge 1 owns her loads and her `IDLING`
freeze, `bee_foraging.gd::autonomous_state`); `bee_status.gd::works_indoors`
(winter grounding and the entrance read it); `scripts/roles.gd` (Codex lane,
BS-8); the save format.

GC-1 shipped 2026-10-01; its specification is `plans/archive/GC-1_2026-10-01.md`.

## GC-2 — a bee changing job puts down what she carries

Level: medium (a simulation change on the idle dispatch, with a scenario).

**Now.** A bee has one carried-load slot, `current_load`/`current_load_type`.
`bee.gd::_apply_role` keeps it, and only the forager's `IN_HIVE_TO_CELL`
delivers it: `bee_foraging.gd::enter_hive` starts an indoor role at its idle
state, so a Nurse or Miner carries a former forager's load for good (review
probe B: 30 nectar still aboard 75 s after forager to Miner, through
`orders_zones.gd::_assign_role` with "Finish the job first" off, its default).
A lift overwrites it: `bee_building.gd::builder_go_to_haul_source` and
`restock_go_to_source`, and `bee_honey.gd::honey_go_to_nectar`, assign
`current_load = lifted`. A Comb worker reaches `BUILD_IDLE` holding a
remnant whenever `restock_go_to_target` places part of a load or finds all
six walls busy, and her next restock lift erases it.

**Change.** One choke point, as `docs/known-pitfalls.md` ("A rule enforced by
remembering to check a flag") asks, not a guard per job:

- `scripts/bee.gd`: a new `func _deliver_held_load() -> bool`, called in
  `_idle_dispatch` straight after `if _apply_pending_role(): return`. It
  returns false when `is_queen`, when `current_load <= 0.0` or
  `current_load_type == ""`, when not `_is_inside_hive()`, or when
  `deposit_blocked_epoch == hive.index_epoch` (no cell had room and none has
  changed since); otherwise it sets `state = State.IN_HIVE_TO_CELL` and
  returns true. Runtime policy: four comparisons inside the idle dispatch the
  bee already runs; no search is added.
- `scripts/bee_foraging.gd`: a new `static func _after_delivery_state(bee)`
  returning `bee._default_state_for_role()` when
  `BeeStatus.works_indoors(bee) and not bee.is_queen`, else
  `State.IN_HIVE_TO_EXIT`. Use it, inside `autonomous_state(bee, ...)`, as the
  last line of `finish_depositing` and in `go_to_deposit_cell`'s
  `current_load <= 0.0` branch. In `go_to_deposit_cell`'s three "nowhere to
  put it" exits (no cells built, the `deposit_blocked_epoch` early return,
  and the branch that sets `deposit_blocked_epoch`), an indoor non-queen bee
  sets `bee.deposit_blocked_epoch = bee.hive.index_epoch` and goes to
  `autonomous_state(bee, bee._default_state_for_role())`, so a full comb
  never stops her own job; a forager still waits holding her load, exactly
  as today (C-69's wording).
- `scripts/bee_building.gd::find_cell_needing_eviction` and
  `find_restock_job`, and `scripts/bee_honey.gd::find_cell_with`: first line
  `if bee.current_load > 0.0: return false`, the same guard `bee_honey.gd`
  already keeps for `honey_load`, so a bee still holding a load (the comb
  full) never lifts over it.
- `scripts/diagnostic_log.gd::event_count`: a `"forager_delivery"` case
  returning `_forager_deliveries` (every placement `finish_depositing`
  makes, whatever the bee's role).
- `scripts/scenario_actions.gd`: a `"set_bee_load"` action,
  `{"do": "set_bee_load", "target": <bee selector>, "resource": "nectar",
  "amount": 30}`, writing `current_load` and `current_load_type` on every bee
  `_resolve_bees` returns (rejected when none match), logged like
  `_do_set_queen_load`, which stays as it is.
- `test_scenarios/gc2_role_change_delivers_load_test.json`: `"cells": 7`,
  `"nectar_foragers": 1`, `"builders": 1`, nothing else, weather, disease,
  rival hive and winter off, `"random_seed": 4242`. Actions:
  `set_cell_contents` nectar 200 into `built_index` 0; `settle` 30 ticks;
  `set_bee_load` 30 nectar on `{"current_role": "forager", "count": 1}`;
  `assign_role` the same selector to `"miner"`; `set_bee_load` 20 nectar on
  `{"current_role": "comb_worker", "count": 1}`; then `assert`
  `"when": {"day_at_least": 2}`, `{"event_count_at_least": {"type":
  "forager_delivery", "count": 2}}`. `"stop": {"when_actions_resolved":
  true, "max_days": 3}`. No real trip can deliver by day 2: the one forager
  is a Miner from the first second.

**Invariants.** The queen is untouched by every new branch. A role change
still takes effect at once (`set_role`, `pending_role` and
`finish_task_first` unchanged); `_apply_role` still drops a nurse's brood
food. No saved field is added.

**Acceptance, from the player's seat** (file it with `python
tools/new_check.py --name "A forager moved indoors unloads first" --owner
plans/now/gameplay-consistency.md`): in Scenario 4, click a forager on her
way home and make her a Miner. PASS: once in the hive she walks to a cell,
her "Carrying" line drops to nothing, and she starts mining. A failure means
the colony still loses the load.

**Escalate** if a Challenge 1 fixture fails: the queen is excluded, so a
failure means a path this plan did not foresee.

```queue
**[Claude] GC-2 -- a bee changing job puts down what she carries**
- Plan: `plans/now/gameplay-consistency.md` -- "GC-2 — a bee changing job puts down what she carries"
- Files: `scripts/bee.gd`, `scripts/bee_foraging.gd`, `scripts/bee_building.gd`, `scripts/bee_honey.gd`, `scripts/diagnostic_log.gd`, `scripts/scenario_actions.gd`, `test_scenarios/gc2_role_change_delivers_load_test.json`
- Check: `python tools/run_scenario.py test_scenarios/gc2_role_change_delivers_load_test.json` passes (two deliveries by day 2), `python tools/run_scenario.py test_scenarios/c1f2_queen_pollen_departure_test.json` still passes, the hands-on check is filed, and `tools/verify.ps1` is green
- Proof: `absent: scripts/bee.gd :: _deliver_held_load`
- Next after: GC-3 -- honey stops creating energy (gated on PE-2)
```

## GC-3 — honey stops creating energy

Level: medium (one balance value, a source check and a before-and-after
comparison; a failed gate is escalated, never retuned here).

**Now.** `scripts/game_config.gd` has `nectar_per_honey` 2.0 and
`honey_energy_factor` 4.0. `bee_honey.gd::honey_chew` makes one unit of honey
from two of nectar, and `bee_survival.gd::feed_self` gives four energy for
it, so every unit converted doubles its nectar's energy; the winter forecast
(`year_winter.gd::_winter_forecast`) counts honey the same way. That breaks
`.claude/rules/simulation.md`'s settled rule (Dave, 26 Aug 2026), which also
says the value changes only after the whole colony and winter economy is
modelled over several seasons.

**Decision (Dave, 30 Sep 2026, `docs/gameplay-review-2026-09-30.md` F4).**
Raise `nectar_per_honey` to 4.0, equal to `honey_energy_factor`: honey keeps
its fourfold density, and each unit of honey costs four nectar, so a skill
priced in honey costs twice the nectar it does today. The decision is
recorded in `.claude/rules/simulation.md`.

**Gate.** PE-2, the played pacing arc through winter
(`plans/now/pacing-evidence.md`), is the multi-season evidence the rule asks
for. When it exists, fence this block `queue`.

**Change.**

- `scripts/game_config.gd`: `var nectar_per_honey: float = 4.0`, its comment
  saying it equals `honey_energy_factor` so honey stores energy without
  creating it (`.claude/rules/simulation.md`).
- `scripts/settings_catalogue.gd`: the `nectar_per_honey` tip adds that at
  the honey energy multiplier making honey neither gains nor loses energy.
  Its `"persist": "run"` stays, so an older save keeps its own value.
- `tests/source_checks.py`: `check_honey_conserves_energy`, reading both
  defaults from `game_config.gd` and failing when `honey_energy_factor`
  exceeds `nectar_per_honey`.
- Evidence: PE-2's arc at both values, on PE-2's seeds, compared on winter
  survival, ripe honey at winter's start and the day
  `test_scenarios/bs4_honey_gate_test.json` buys Comb worker; the table goes
  in this slice's closeout. If the new value fails a gate the old one
  passed, stop and take the numbers to Dave.

```queue-gated
**[Claude] GC-3 -- honey stops creating energy**
- Plan: `plans/now/gameplay-consistency.md` -- "GC-3 — honey stops creating energy"
- Files: `scripts/game_config.gd`, `scripts/settings_catalogue.gd`, `tests/source_checks.py`
- Check: `python tests/source_checks.py` passes with the new check, PE-2's arc and `test_scenarios/bs4_honey_gate_test.json` pass at 4.0 with the comparison recorded, and `tools/verify.ps1` is green
- Proof: `present: scripts/game_config.gd :: var nectar_per_honey: float = 2.0`
- Next after: none -- plans/now/gameplay-consistency.md is complete
```
