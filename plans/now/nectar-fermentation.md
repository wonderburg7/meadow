# Nectar fermentation -- unprocessed nectar ferments, and tipsy bees pay for it

<!-- CONTEXT: plan | LAYER: immediate-task -->
Status: active | Owner: Dave / Claude Code | Next: NF-3 -- a bee that drinks fermented nectar goes tipsy, specified below and queued once NF-2 lands (NF-2 is on its branch) | Dependency: none for NF-3 once NF-2 lands; NF-4 follows NF-3, NF-5 follows NF-2 | Verified: 2026-10-09

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
| NF-2 | nectar ferments past an age, changes colour, and is lost to honey makers | `scripts/game_config.gd`, `scripts/settings_catalogue.gd`, `scripts/hive_cell.gd`, `scripts/hive.gd`, `scripts/save_game.gd`, `scripts/saving.gd`, `tests/test_nf2_fermentation.py`, `test_scenarios/nf2_fermentation.json` | yes -- COL-4 (7 Oct 2026) and NF-1 (6 Oct 2026) have landed | high |
| NF-3 | a bee that drinks fermented nectar goes tipsy (decision 3) | `scripts/bee.gd`, `scripts/bee_enums.gd`, `scripts/bee_survival.gd`, `scripts/bee_movement.gd`, `scripts/bee_foraging.gd`, `scripts/bee_status.gd`, `scripts/game_config.gd`, `scripts/settings_catalogue.gd`, `scripts/save_game.gd`, `scripts/saving.gd`, `tests/test_nf3_tipsy.py`, `test_scenarios/nf3_tipsy.json` | yes, once NF-2 lands | high |
| NF-4 | the detection skill: bees avoid fermented nectar, and honey makers take the oldest first; without it, closest first (decisions 4-5) | specified after NF-3 | no -- after NF-3 | high |
| NF-5 | an order to clear fermented cells, extending today's restock orders (decision 6) | specified after NF-2 | no -- after NF-2 | medium |

**Dependencies.** NF-1, then NF-2. NF-3 and NF-5 each follow NF-2, and
NF-4 follows NF-3. NF-2's gates, COL-4 and COL-11 (both in
`plans/archive/colony-run_2026-10-08.md`), have landed. Bee Bread's BB-1
(`plans/now/bee-bread.md`) waits for NF-2: it shares `hive_cell.gd`,
`hive.gd` and the save files. T2-4b (`plans/now/tier-two.md`) also edits
`save_game.gd`, `saving.gd` and `hive.gd`; it sits behind NF-2 in the Claude
lane, which runs them one branch at a time, so neither may move to the Codex
lane while the other is queued (SI-3, which shared the save files, landed
9 Oct 2026). NF-4's node joins Colony tier 2, which
`plans/now/tier-two.md` T2-7 prices if NF-4 has landed by then.

NF-1 shipped 2026-10-06; its specification is `plans/archive/NF-1_2026-10-06.md`.

## NF-2 -- nectar ferments past an age, changes colour, and is lost to honey makers

<!-- LAYER: immediate-task -->

Level: high (a save field with its migration, and a gameplay rule).

**True now.** NF-1's `nectar_since` exists but is not saved. No nectar
ferments.

**True afterwards.**

- `GameConfig.nectar_ferment_hours` (in-game hours, with its
  `settings_catalogue.gd` entry) is chosen from NF-1's evidence: above the
  p95 age of a colony with honey makers, so a staffed colony rarely sees
  fermentation, and below the age reached without them.
- `hive_cell.is_fermented()` is derived: nectar content older than that
  threshold. It changes no state of its own, so it costs nothing per frame.
  A fermented cell draws its nectar in a distinct colour. It still takes
  fresh nectar, and stays fermented (decision 8).
- Honey makers skip fermented cells. As built (review, 9 Oct 2026), this is
  a dedicated `hive.find_honey_source()` that `bee_honey.gd` calls, leaving
  the shared `find_cell_with("nectar")`, which nurses and `bee.gd`'s status
  line also use, unchanged. `find_food_cell` still offers fermented cells:
  bees cannot tell (decision 4), and the debuff is NF-3's.
- `nectar_since` is saved per cell as an additive field. An older save
  loads with the stamp at the restore time, following
  `.claude/rules/saving.md`.
- `test_scenarios/nf2_fermentation.json` uses a short threshold through
  `config_overrides`, with no honey makers. `tests/test_nf2_fermentation.py`
  asserts that a nectar cell ferments, a honey maker never takes from it,
  fresh nectar added to it leaves it fermented, and its stamp survives a
  save and restore.

**Evidence (9 Oct 2026, on the NF-2 branch).** NF-1's fixture
(`test_scenarios/nf1_nectar_age.json`, 20-second days) run for 20 days:
with two honey makers (seeds 5101 and 77) and four (seed 5101), the p95 of
the 24 daily nectar-age samples was 94 in-game hours (one cell reached 118);
with none, the oldest nectar grew 24 hours a day, to 120 by day 9 and 360 by
day 19. `GameConfig.nectar_ferment_hours` is 96 (four in-game days). Its
settings row is tagged `persist: "none"`: `tests/source_checks.py` freezes
the set a save carries until D1's second half.

**As built.** The fixture turns two miners into honey makers (granting
`skill.brood.honey_worker`) once the stocked cell has fermented, and stocks
a fresh control cell they do turn into honey. The test reads the run's own
saves back from the scenario scratch root. A honey maker that chose a cell
before it fermented still empties it on arrival (`bee_honey.gd` is not
NF-2's); the window is the walk, against a 96-hour threshold.

**Must not change.** Ripe-honey ripening, eating order, and every other
cell content type.

```queue
**[Claude] NF-2 -- nectar ferments past an age, changes colour, and is lost to honey makers**
- Plan: `plans/now/nectar-fermentation.md` -- "NF-2 -- nectar ferments past an age, changes colour, and is lost to honey makers"
- Files: `scripts/game_config.gd`, `scripts/settings_catalogue.gd`, `scripts/hive_cell.gd`, `scripts/hive.gd`, `scripts/save_game.gd`, `scripts/saving.gd`, `tests/test_nf2_fermentation.py`, `test_scenarios/nf2_fermentation.json`
- Check: `python -m unittest tests.test_nf2_fermentation` passes (a cell ferments, honey makers skip it, a top-up leaves it fermented, its stamp survives save and restore); `tools/verify.ps1` is green
- Proof: `absent: scripts/hive_cell.gd :: func is_fermented`
- Next after: NF-3 -- a bee that drinks fermented nectar goes tipsy
```

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
