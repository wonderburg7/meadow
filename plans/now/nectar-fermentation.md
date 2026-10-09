# Nectar fermentation -- unprocessed nectar ferments, and tipsy bees pay for it

<!-- CONTEXT: plan | LAYER: immediate-task -->
Status: active | Owner: Dave / Claude Code | Next: NF-4 -- the detection skill, specified below and queued in the Claude lane after BB-2 now that Dave has answered its nurse and Restocking questions (9 Oct 2026; NF-3 built 9 Oct 2026, with Dave's 300-second tipsiness from its sweep; NF-5 built 9 Oct 2026) | Dependency: none (NF-2 landed 9 Oct 2026); NF-4 follows NF-3 | Verified: 2026-10-09

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
- **Whether nurses may carry fermented nectar to brood** (NF-4) --
  answered by Dave, 9 Oct 2026: **only without the skill.** Nurses use
  fermented nectar until the detection skill is bought, then avoid it.
  (NF-2 left nurses taking nectar through `hive.find_cell_with("nectar")`,
  which still offers fermented cells; only honey makers use NF-2's
  `hive.find_honey_source()`, which skips them.)
- **Whether Restocking may draw from a fermented cell** (NF-4) --
  answered by Dave, 9 Oct 2026: **only without the skill.** Restocking
  takes it until the detection skill is bought, then leaves it alone.
  (NF-5 stops every eviction from moving fermented nectar into another
  cell, but a restock order, `bee_building.gd::may_draw_from`, still takes
  from one and tops up its target, which keeps the target's younger
  stamp.)

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
  between cells. NF-5 does not extend them: restocking never takes
  anything out of the hive, so NF-5 builds on the cell eviction orders
  instead (superseded 9 Oct 2026; see NF-5).

## Open slices

| Slice | What it does | Files it owns | Startable | Level |
| --- | --- | --- | --- | --- |
| NF-4 | the detection skill: bees avoid fermented nectar, and honey makers take the oldest first; without it, closest first (decisions 4-5) | see its `Files:` line below | yes -- queued in the Claude lane after BB-2, which shares `bee_nursery.gd` and `bee_survival.gd` (NF-3 and NF-5 landed 9 Oct 2026; Dave answered its questions 9 Oct 2026) | high |

**Dependencies.** NF-1, then NF-2, both landed. NF-3 and NF-5 each follow
NF-2, and NF-4 follows NF-3. Bee Bread's BB-1 (`plans/now/bee-bread.md`)
shared `hive.gd`, `game_config.gd`, `settings_catalogue.gd` and the save
files with NF-3 and `orders_zones.gd` and `hud.gd` with NF-5 (both
landed 9 Oct 2026), and shares `hive.gd` and `bee_honey.gd` with NF-4.
Bee Bread's BB-2 shares `bee_nursery.gd` and `bee_survival.gd` with NF-4
and is queued ahead of it. All are in the Claude lane, which runs them one
branch at a time, so none may move to the Codex lane while another is
queued (T2-4b, which shared them too, landed 9 Oct 2026). NF-5 has
released `hud.gd`, `main.gd` and `scenario_actions.gd` to
`plans/now/crisis-readiness.md` FC-2. NF-4's node joins Colony tier 2, which
`plans/now/tier-two.md` T2-7 prices if NF-4 has landed by then.

NF-1 shipped 2026-10-06; its specification is `plans/archive/NF-1_2026-10-06.md`.

NF-2 shipped 2026-10-09; its specification is `plans/archive/NF-2_2026-10-09.md`.

NF-3 shipped 2026-10-09; its specification is `plans/archive/NF-3_2026-10-09.md`.

## NF-4 -- the detection skill: bees avoid fermented nectar, and honey makers take the oldest first

<!-- LAYER: immediate-task -->

Level: high (a new skill node, which cells every eater and honey maker
chooses, and a cost set by simulation). Outlined 9 Oct 2026 when NF-3
landed; specified and queued 9 Oct 2026 once Dave answered its nurse and
Restocking questions under "Still open" (only without the skill, both).

**True now.** Bees cannot tell fermented nectar from fresh (decision 4):
`hive.find_food_cell` and `hive.find_cell_with("nectar")` both offer a
fermented cell, so a hungry bee eats there and goes tipsy (NF-3), and a
nurse can carry it to brood. Only honey makers skip it, through NF-2's
`hive.find_honey_source()`, which takes the first indexed fresh cell rather
than the closest (decision 5 wants closest). `skill.colony.fermentation_sense`
is a working id in `plans/design/progression.md` section 5.3, Colony tier 2,
and is not yet in `scripts/skills.gd`.

**True afterwards.**

- `skill.colony.fermentation_sense` is a Colony tier 2 node in
  `scripts/skills.gd` beside Comb worker and Miner, costing honey at the
  figure the simulation below sets, and its row in
  `plans/design/progression.md` section 5.3 loses "working id".
- Without the skill, honey makers take the closest fresh nectar cell to
  where they stand (decision 5); hungry bees eat as they do now.
- With the skill, hungry bees skip fermented cells while any other food is
  left, so a colony with sense eats fresh nectar or honey first; honey
  makers take the oldest fresh nectar first, so less of it reaches the
  threshold.
- Without the skill, nurses and restock orders take fermented nectar as
  they do now. With it, nurses never fetch carbohydrate from a fermented
  cell: they take honey, then fresh nectar, and when only fermented nectar
  is stored they act as if no nectar were stored (`bee_nursery.gd`'s
  errand check and `nurse_restock_errand` both). With it, a restock order
  never draws from a fermented cell (`bee_building.gd::may_draw_from`), so
  fermented nectar stays where it is until a clear order (NF-5) or an
  eater empties it. What fermented nectar does to a larva is unchanged:
  nothing, today.
- The skill's cost comes from a headless comparison run in this slice and
  recorded here: the same fermenting colony with and without the skill.
- `test_scenarios/nf4_fermentation_sense.json` and
  `tests/test_nf4_fermentation_sense.py` show from the run that, with the
  skill, no bee goes tipsy while fresh food is left, no nurse or restock
  order takes from a fermented cell, and honey makers empty the oldest
  cell first, and, without it, nurses and restock orders still take
  fermented nectar and honey makers take the closest.

**Must not change.** Fermentation itself, tipsiness (NF-3), honey ripening,
and what a colony without the skill eats.

```queue
**[Claude] NF-4 -- the detection skill: bees avoid fermented nectar, and honey makers take the oldest first**
- Plan: `plans/now/nectar-fermentation.md` -- "NF-4 -- the detection skill: bees avoid fermented nectar, and honey makers take the oldest first"
- Files: `scripts/skills.gd`, `scripts/hive.gd`, `scripts/bee_honey.gd`, `scripts/bee_survival.gd`, `scripts/bee_nursery.gd`, `scripts/bee_building.gd`, `plans/design/progression.md`, `tests/test_nf4_fermentation_sense.py`, `test_scenarios/nf4_fermentation_sense.json`
- Check: `python -m unittest tests.test_nf4_fermentation_sense` passes (with the skill no bee goes tipsy while fresh food is left, nurses and restock orders never take from a fermented cell, and honey makers take the oldest nectar first; without it nurses and restock orders still take fermented nectar and honey makers take the closest); `tools/verify.ps1` is green
- Proof: `absent: scripts/skills.gd :: skill.colony.fermentation_sense`
- Next after: none -- nectar fermentation is complete
```

NF-5 shipped 2026-10-09; its specification is `plans/archive/NF-5_2026-10-09.md`.
