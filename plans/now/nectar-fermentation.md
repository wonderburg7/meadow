# Nectar fermentation -- unprocessed nectar ferments, and tipsy bees pay for it

<!-- CONTEXT: plan | LAYER: immediate-task -->
Status: active | Owner: Dave / Claude Code | Next: NF-3 -- a bee that drinks fermented nectar goes tipsy, queued in the Claude lane; NF-5 -- the clear-fermented-cells order, to be specified now that NF-2 has landed | Dependency: none (NF-2 landed 9 Oct 2026); NF-4 follows NF-3 | Verified: 2026-10-09

## Objective

ROADMAP "Later": player-managed stocking routes and nectar spoilage. Dave
chose it as the next Claude-lane plan on 6 Oct 2026, from `/run-queue`.
Raw nectar left too long in the comb ferments. A bee that drinks fermented
nectar goes tipsy for a while. A skill teaches the colony to detect
fermented nectar, and stocking controls let the player keep it from
happening.

## Decisions (Dave, 6 Oct 2026)

1. **Fermentation.** Raw nectar that sits in a cell past an age threshold
   ferments, and the cell's nectar changes colour.
2. **Lost to honey.** A honey maker cannot turn fermented nectar into
   honey. It can only be drunk (see 3) or hauled out (see 6).
3. **Tipsy.** A bee that drinks fermented nectar gets a temporary debuff.
   It moves slower and more "bumbly" (erratic heading), and its vision
   radius shrinks. It cannot dance or recruit. It can still nurse brood,
   build and make honey, but does each ineffectively: it stops partway
   through a task and wanders the hive confused before it returns to the
   task. Other effects may be added later.
4. **No detection by default.** Bees cannot tell fermented nectar from
   fresh. A skill lets them, and then they avoid it.
5. **Oldest first comes with that skill.** Without it, honey makers take
   whichever nectar cell is closest. With it, they take the oldest nectar
   first.
6. **Clear fermented cells.** A player order sends builders to haul
   fermented nectar out of the comb.
7. **Order.** Evidence first, then the rule, gated on COL-4 for its
   `GameConfig` value (CLAUDE.md rule 2: balance values live in
   `GameConfig`, and balance changes are simulated first).

## Decisions (Dave, 7 Oct 2026, plan-ahead session)

8. **Topping up spoils the fresh nectar.** A fermented cell still takes
   fresh nectar, and the whole cell stays fermented: topping up keeps the
   cell's oldest stamp (NF-1), so nothing new is needed to make it so.
   Without the detection skill, foragers waste loads into spoilt cells.
   This replaces the plan's earlier reading that a fermented cell refuses
   fresh nectar.
9. **The detection skill is Colony tier 2**, beside Comb worker and Miner,
   costing honey; Colony tier 3's Restocking then follows it. Its row and
   any later numbers live in `plans/design/progression.md` section 5.3.

## Still open -- decide before the slice that needs it is unfenced

- **How long tipsiness lasts, and how strong it is** (NF-3): set from a
  headless sweep in NF-3, not guessed.
- **What the detection skill costs** (NF-4): set by simulation when NF-4
  is specified; its slot is decision 9.
- **Whether nurses may carry fermented nectar to brood** (NF-4). NF-2
  left nurses as they were: they take nectar through
  `hive.find_cell_with("nectar")`, which still offers fermented cells
  (decision 4); only honey makers use NF-2's `hive.find_honey_source()`,
  which skips them. NF-4 decides whether the detection skill also steers
  nurses away from it.

## Current state

Verified 6 Oct 2026 against master:

- A cell holds one content type (`scripts/hive_cell.gd`). Nectar goes in
  through `add_resource` and comes out through `take_resource`. Honey
  makers (`scripts/bee_honey.gd`) take nectar from
  `hive.find_cell_with("nectar")`, which returns the first indexed cell
  with stock, neither the closest nor the oldest. They spit honey into a
  cell and fan it until `ripen_progress` reaches
  `GameConfig.honey_ripen_time`.
- Hungry bees eat through `hive.find_food_cell`: ripe honey first, then
  raw nectar.
- Nothing records how long nectar has sat in a cell. `bee_honey.gd`'s
  comment says nectar "ferments", but no code does.
- `Session.sim_time` is the simulation clock, and it is saved
  (`save_game.gd`, restored in `saving.gd`).
- Restock orders (`orders_zones.gd`) already let the player steer stores
  between cells. NF-5 extends them, and adds no parallel mechanism.

## Open slices

| Slice | What it does | Files it owns | Startable | Level |
| --- | --- | --- | --- | --- |
| NF-3 | a bee that drinks fermented nectar goes tipsy (decision 3) | `scripts/bee.gd`, `scripts/bee_enums.gd`, `scripts/bee_survival.gd`, `scripts/bee_movement.gd`, `scripts/bee_foraging.gd`, `scripts/bee_status.gd`, `scripts/game_config.gd`, `scripts/settings_catalogue.gd`, `scripts/save_game.gd`, `scripts/saving.gd`, `tests/test_nf3_tipsy.py`, `test_scenarios/nf3_tipsy.json` | yes -- queued in the Claude lane (NF-2 landed 9 Oct 2026) | high |
| NF-4 | the detection skill: bees avoid fermented nectar, and honey makers take the oldest first; without it, closest first (decisions 4-5) | specified after NF-3 | no -- after NF-3 | high |
| NF-5 | an order to clear fermented cells, extending today's restock orders (decision 6) | to be specified; first check what the cell popup's Empty / Discard order (`orders_zones.gd::_empty_one`) already covers (`plans/README.md` rule 3) | no -- NF-2 has landed; waits only to be specified | medium |

**Dependencies.** NF-1, then NF-2, both landed. NF-3 and NF-5 each follow
NF-2, and NF-4 follows NF-3. Bee Bread's BB-1 (`plans/now/bee-bread.md`)
and T2-4b (`plans/now/tier-two.md`) share `hive.gd`, `game_config.gd`,
`settings_catalogue.gd` and the save files with NF-3; all three are in the
Claude lane, which runs them one branch at a time, so none may move to the
Codex lane while another is queued. NF-4's node joins Colony tier 2, which
`plans/now/tier-two.md` T2-7 prices if NF-4 has landed by then.

NF-1 shipped 2026-10-06; its specification is `plans/archive/NF-1_2026-10-06.md`.

NF-2 shipped 2026-10-09; its specification is `plans/archive/NF-2_2026-10-09.md`.

## NF-3 -- a bee that drinks fermented nectar goes tipsy

<!-- LAYER: immediate-task -->

Level: high (a per-bee hot path, a save field, and a balance value set by a
sweep).

**True now.** NF-2's `hive_cell.is_fermented()` exists, and hungry bees
still eat from fermented cells through `hive.find_food_cell` (decision 4).
Nothing happens to a bee that does.

**True afterwards.**

- A bee that eats from a fermented cell (`bee_survival.gd`, checked before
  the take, since a take that empties the cell clears its stamp) becomes
  tipsy for `GameConfig.tipsy_seconds`, with its `settings_catalogue.gd`
  row. Eating again while tipsy restarts the timer, not stacks it.
- While tipsy (decision 3): the bee moves at `GameConfig.tipsy_speed_factor`
  of its speed, its heading wobbles (`bee_movement.gd`), its forage
  perception radius shrinks by `GameConfig.tipsy_vision_factor`, and it is
  never dance-eligible, so it cannot dance or recruit
  (`bee_foraging.gd::_update_dance_eligibility`). In a work state it
  sometimes breaks off into a short confused wander inside the hive and then
  resumes the task: one shared interlude in `bee.gd`, with its state in
  `bee_enums.gd` and its status line in `bee_status.gd`, not a change to
  each role's routine.
- The remaining tipsy seconds are saved per bee as an additive field; an
  older save loads every bee sober (`.claude/rules/saving.md`).
- The duration and strengths come from a headless sweep run in this slice
  and recorded here, not guessed (the plan's open question): long and
  strong enough that a colony eating mostly fermented nectar visibly loses
  forage per day, short enough that one sip costs a single trip.
- `test_scenarios/nf3_tipsy.json` stocks a fermented cell through a short
  `nectar_ferment_hours` and no other food. `tests/test_nf3_tipsy.py`
  asserts from the run that a bee that eats there goes tipsy, moves slower,
  is never dance-eligible while tipsy, recovers after the set time, and that
  its remaining time survives a save and restore.

**Must not change.** Eating order, honey ripening, fermentation itself, and
a sober bee's movement and work.

```queue
**[Claude] NF-3 -- a bee that drinks fermented nectar goes tipsy**
- Plan: `plans/now/nectar-fermentation.md` -- "NF-3 -- a bee that drinks fermented nectar goes tipsy"
- Files: `scripts/bee.gd`, `scripts/bee_enums.gd`, `scripts/bee_survival.gd`, `scripts/bee_movement.gd`, `scripts/bee_foraging.gd`, `scripts/bee_status.gd`, `scripts/game_config.gd`, `scripts/settings_catalogue.gd`, `scripts/save_game.gd`, `scripts/saving.gd`, `tests/test_nf3_tipsy.py`, `test_scenarios/nf3_tipsy.json`
- Check: `python -m unittest tests.test_nf3_tipsy` passes (a bee that eats fermented nectar goes tipsy, moves slower, cannot dance, recovers, and its tipsiness survives save and restore); `tools/verify.ps1` is green
- Proof: `absent: scripts/game_config.gd :: tipsy_seconds`
- Next after: NF-4 -- the detection skill: bees avoid fermented nectar, and honey makers take the oldest first
```
