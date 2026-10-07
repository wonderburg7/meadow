# Nectar fermentation -- unprocessed nectar ferments, and tipsy bees pay for it

<!-- CONTEXT: plan | LAYER: immediate-task -->
Status: active | Owner: Dave / Claude Code | Next: NF-1 is built (nectar age is measured); NF-2 is specified and gated on COL-4 (Codex lane, `plans/now/colony-run.md`), which holds `scripts/game_config.gd` and `scripts/settings_catalogue.gd` | Dependency: COL-4 for NF-2 onwards | Verified: 2026-10-06

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
| NF-2 | nectar ferments past an age, changes colour, and is lost to honey makers | `scripts/game_config.gd`, `scripts/settings_catalogue.gd`, `scripts/hive_cell.gd`, `scripts/hive.gd`, `scripts/save_game.gd`, `scripts/saving.gd`, `tests/test_nf2_fermentation.py`, `test_scenarios/nf2_fermentation.json`, `tools/verify.ps1` | no -- after COL-4 (shares `game_config.gd`, `settings_catalogue.gd`) and NF-1 (its threshold comes from NF-1's numbers) | high |
| NF-3 | a bee that drinks fermented nectar goes tipsy (decision 3) | specified after NF-2 | no -- after NF-2 | high |
| NF-4 | the detection skill: bees avoid fermented nectar, and honey makers take the oldest first; without it, closest first (decisions 4-5) | specified after NF-3 | no -- after NF-3 | high |
| NF-5 | an order to clear fermented cells, extending today's restock orders (decision 6) | specified after NF-2 | no -- after NF-2 | medium |

**Dependencies.** NF-1, then NF-2. NF-3 and NF-5 each follow NF-2, and
NF-4 follows NF-3. NF-2 waits for COL-4 in the Codex lane, which edits
`scripts/game_config.gd` and `scripts/settings_catalogue.gd`. COL-6 and
COL-11 (`plans/now/colony-run.md`) also edit `tools/verify.ps1`, and are
gated on COL-4 too. Whichever is queued second waits for the other's merge,
as the one-branch lane already ensures. Bee Bread's BB-1
(`plans/now/bee-bread.md`) waits for NF-2: it shares `hive_cell.gd`,
`hive.gd` and the save files. SI-1 to SI-3 (`plans/now/save-integrity.md`)
also edit `save_game.gd` and `saving.gd`, so NF-2 is never in the other
lane while one of them is queued. NF-4's node joins Colony tier 2, which
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
- `hive.find_cell_with("nectar")`, for honey makers, skips fermented
  cells. `find_food_cell` still offers them: bees cannot tell (decision 4),
  and the debuff is NF-3's.
- `nectar_since` is saved per cell as an additive field. An older save
  loads with the stamp at the restore time, following
  `.claude/rules/saving.md`.
- `test_scenarios/nf2_fermentation.json` uses a short threshold through
  `config_overrides`, with no honey makers. `tests/test_nf2_fermentation.py`
  asserts that a nectar cell ferments, a honey maker never takes from it,
  fresh nectar added to it leaves it fermented, and its stamp survives a
  save and restore.

**Must not change.** Ripe-honey ripening, eating order, and every other
cell content type.

```queue-gated
**[Claude] NF-2 -- nectar ferments past an age, changes colour, and is lost to honey makers**
- Plan: `plans/now/nectar-fermentation.md` -- "NF-2 -- nectar ferments past an age, changes colour, and is lost to honey makers"
- Files: `scripts/game_config.gd`, `scripts/settings_catalogue.gd`, `scripts/hive_cell.gd`, `scripts/hive.gd`, `scripts/save_game.gd`, `scripts/saving.gd`, `tests/test_nf2_fermentation.py`, `test_scenarios/nf2_fermentation.json`, `tools/verify.ps1`
- Check: `python -m unittest tests.test_nf2_fermentation` passes (a cell ferments, honey makers skip it, a top-up leaves it fermented, its stamp survives save and restore); `tools/verify.ps1` is green
- Proof: `absent: scripts/hive_cell.gd :: func is_fermented`
- Next after: NF-3 -- a bee that drinks fermented nectar goes tipsy
```
