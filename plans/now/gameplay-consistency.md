# Gameplay consistency — a job change keeps the bee and her load, and honey stores energy without creating it

<!-- CONTEXT: plan | LAYER: immediate-task -->
Status: active | Owner: Dave / Claude Code | Next: GC-3 -- honey stops creating energy (gated on PE-2); GC-4 -- a nurse's brood food survives a job change (startable, Dave chose (b) 2 Oct 2026); C-89 and C-90 passed 2 Oct 2026 | Dependency: GC-3 waits for PE-2 (`plans/archive/pacing-evidence_2026-10-01.md`); GC-4 none | Verified: 2026-10-02

**Objective.** Three rules that the code breaks today hold again: an Idle bee
does what the Idle tooltip says, a change of job never loses what the bee is
carrying, and making honey follows `.claude/rules/simulation.md` ("must not
create energy"). Found by `docs/gameplay-review-2026-09-30.md` (F2 to F4),
each demonstrated in a headless run.

## Open slices at a glance

| Slice | Outcome from the player's seat | Files owned | Startable | Level |
| --- | --- | --- | --- | --- |
| GC-3 | a colony that turns nectar into honey has the same energy afterwards, stored four times as densely | `scripts/game_config.gd`, `scripts/settings_catalogue.gd`, `tests/source_checks.py` | gated: waits for PE-2's played arc | medium |
| GC-4 | a nurse moved to another job does not lose the brood food she carries | `scripts/bee.gd`, `test_scenarios/gc4_nurse_role_change_keeps_food_test.json` | yes -- queued | high |

GC-1 and GC-2 are independent in behaviour but share `bee.gd`, so they run in
that order in one lane. GC-3 is independent of both. **Required reading:**
the slice's own section and the functions it names. **Must not change:** the
queen's behaviour anywhere (Challenge 1 owns her loads and her `IDLING`
freeze, `bee_foraging.gd::autonomous_state`); `bee_status.gd::works_indoors`
(winter grounding and the entrance read it); `scripts/roles.gd` (Codex lane,
BS-8); the save format.

GC-1 shipped 2026-10-01; its specification is `plans/archive/GC-1_2026-10-01.md`.

GC-2 shipped 2026-10-01; its specification is `plans/archive/GC-2_2026-10-01.md`.

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
(`plans/archive/pacing-evidence_2026-10-01.md`), is the multi-season evidence the rule asks
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

## GC-4 — a nurse moved to another job does not lose the brood food she carries

<!-- LAYER: immediate-task -->

**True now.** `bee.gd::_apply_role` zeroes `nurse_pollen`, `nurse_carb`
and `nurse_jelly` on every role change ("brood food a nurse was carrying
isn't any use in another job"). Seen on 2 Oct 2026, Scenario 4: a nurse
carrying "6 pollen and 12 nectar for the brood" was set to Idle, and her
Carrying line read "Nothing" at once. That is the loss GC-2 removed for
foragers, kept for nurses on purpose.

**Decision (Dave, 2 Oct 2026): option (b).** The food goes back into the
comb before she takes up the new job, as GC-2's forager does.

Level: high (energy conservation in the simulation; `.claude/rules/simulation.md`).

**True afterwards.** On any job change, a nurse's `nurse_pollen`,
`nurse_carb` (as `nurse_carb_type`, nectar or honey) and `nurse_jelly` are
returned to the comb before they are cleared, so the hive's stored totals
are the same just before and just after the change. Owner: the choke point
GC-2 built (`_deliver_held_load` and `_apply_pending_role` in `bee.gd`)
rather than a second mechanism. A nurse is always inside the hive, so the
return may be immediate through `hive.deposit`, which spreads an amount over
any cells with room. Whatever finds no room is recorded through
`DiagnosticLog` rather than dropped silently. Escalate if conservation
needs a walk to a cell (a new state) instead. Runtime policy: on the role
change only; nothing per frame. A headless fixture,
`gc4_nurse_role_change_keeps_food_test.json`, modelled on
`gc2_role_change_delivers_load_test.json`, proves the totals for a nurse
carrying pollen and nectar who is set to Idle and to Forager. The queen is
untouched (this plan's "Must not change"; she keeps her own backup nursing,
BS-9).

**Must not change.** GC-1's Idle behaviour and GC-2's forager delivery
(C-89 and C-90, passed 2 Oct 2026); the save format.

```queue
**[Claude] GC-4 -- a nurse moved to another job does not lose the brood food she carries**
- Plan: `plans/now/gameplay-consistency.md` -- "GC-4 — a nurse moved to another job does not lose the brood food she carries"
- Files: `scripts/bee.gd`, `test_scenarios/gc4_nurse_role_change_keeps_food_test.json`
- Check: `test_scenarios/gc4_nurse_role_change_keeps_food_test.json` passes headless, a Godot boot is clean, and `tools/verify.ps1` is green
- Proof: `present: scripts/bee.gd :: brood food a nurse was carrying isn't any use in another job`
- Next after: GC-3 -- honey stops creating energy
```
