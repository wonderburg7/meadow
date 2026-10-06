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

## Still open -- decide before the slice that needs it is unfenced

- **Topping up a fermented cell** (NF-2): this plan's reading is that a
  fermented cell takes no fresh nectar until it is emptied, so fresh
  deposits aren't spoilt by mixing. Dave to confirm before NF-2 is opened.
- **How long tipsiness lasts, and how strong it is** (NF-3): set from a
  headless sweep in NF-3, not guessed.
- **Where the detection skill sits in the tree, and what it costs** (NF-4):
  `plans/design/progression.md` owns the tree.

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
| NF-1 | headless runs report how long raw nectar sits in the comb | `scripts/hive_cell.gd`, `scripts/diagnostic_log.gd`, `tests/test_nf1_nectar_age.py`, `test_scenarios/nf1_nectar_age.json`, `tools/verify.ps1` | yes | medium |
| NF-2 | nectar ferments past an age, changes colour, and is lost to honey makers | `scripts/game_config.gd`, `scripts/settings_catalogue.gd`, `scripts/hive_cell.gd`, `scripts/hive.gd`, `scripts/save_game.gd`, `scripts/saving.gd`, `tests/test_nf2_fermentation.py`, `test_scenarios/nf2_fermentation.json`, `tools/verify.ps1` | no -- after COL-4 (shares `game_config.gd`, `settings_catalogue.gd`) and NF-1 (its threshold comes from NF-1's numbers) | high |
| NF-3 | a bee that drinks fermented nectar goes tipsy (decision 3) | specified after NF-2 | no -- after NF-2 | high |
| NF-4 | the detection skill: bees avoid fermented nectar, and honey makers take the oldest first; without it, closest first (decisions 4-5) | specified after NF-3 | no -- after NF-3 | high |
| NF-5 | an order to clear fermented cells, extending today's restock orders (decision 6) | specified after NF-2 | no -- after NF-2 | medium |

**Dependencies.** NF-1, then NF-2. NF-3 and NF-5 each follow NF-2, and
NF-4 follows NF-3. NF-2 waits for COL-4 in the Codex lane, which edits
`scripts/game_config.gd` and `scripts/settings_catalogue.gd`. COL-6 and
COL-11 (`plans/now/colony-run.md`) also edit `tools/verify.ps1`, and are
gated on COL-4 too. Whichever is queued second waits for the other's merge,
as the one-branch lane already ensures.

## NF-1 -- headless runs report how long raw nectar sits in the comb

<!-- LAYER: immediate-task -->

Level: medium (one transient cell field, a diagnostic summary and one
recorded measurement, with a test).

**True now.** See "Current state": no nectar age exists anywhere.

**True afterwards.**

- `hive_cell.gd` records `nectar_since: float`, the `Session.sim_time` at
  which an empty (or non-nectar) cell first took nectar, set in
  `add_resource`. Topping up keeps the stamp, so the age is the age of the
  oldest nectar in the cell. Emptying the cell resets it. Age is computed
  on demand as `Session.sim_time - nectar_since`. **Runtime policy:** an
  event stamp (on deposit), no per-frame work.
- **Not saved in this slice.** On restore the stamp is the restore time.
  NF-2 adds the save field with its migration, because only the rule
  needs it to survive a reload.
- `diagnostic_log.gd`'s run summary gains `nectar_age`: at each day
  change, the p50, p95 and max age (in in-game hours) over nectar cells
  holding stock, and the share of stored nectar older than one in-game day.
  It is read once per day change, never per frame.
- `test_scenarios/nf1_nectar_age.json` runs an ordinary colony for at
  least five days with foragers and honey makers, following an existing
  forager scenario's shape. `tests/test_nf1_nectar_age.py` (registered in
  `tools/verify.ps1`'s `$unitModules`) runs it and asserts that the
  summary carries `nectar_age` with a p95 at or above its p50, and a max
  above 0.
- This section gains an "Evidence" paragraph giving the numbers from that
  scenario and from one with honey makers removed (`honey_makers: 0`, or
  the scenario's equivalent). That paragraph is what NF-2's threshold is
  chosen from.

**Must not change.** Any gameplay: no cell ferments, eating and honey
making are untouched, and there is no new save field.

**Evidence (6 Oct 2026, built).** `test_scenarios/nf1_nectar_age.json` is
20 cells, 6 nectar and 2 pollen foragers, 2 nurses, 1 builder, 2 honey
makers, seed 5101, 20 s days, 10 days. Ages are in in-game hours, taken
at each day change over nectar cells holding stock. The summary reports
the worst day for each figure plus a `daily` list. The colony is small, so
only one or two cells hold nectar at a time, and p50 and p95 are close.
With honey makers: days 5, 7, 8, 9 had one nectar cell each, aged 1.2,
16.8, 40.8 and 64.8 h; the share of stock older than a day went 0, 0, 1,
1. Without honey makers (`honey_makers: 0`): days 4 to 9 had 1 or 2 cells,
p95 4.8, 28.8, 52.8, 76.8, 100.8 and 124.8 h; older than a day went 0,
0.25, then 1.0. In both runs a cell that keeps its nectar ages
linearly with no ceiling, so any threshold up to a few days is reached;
honey makers did not clear the old cell here (it was the same cell on
days 7 to 9), so they do not by themselves keep nectar younger than
about 1 to 3 in-game days at this colony size. NF-2 should pick its
threshold knowing this is a one-colony, one-seed reading.

```queue
**[Claude] NF-1 -- headless runs report how long raw nectar sits in the comb**
- Plan: `plans/now/nectar-fermentation.md` -- "NF-1 -- headless runs report how long raw nectar sits in the comb"
- Files: `scripts/hive_cell.gd`, `scripts/diagnostic_log.gd`, `tests/test_nf1_nectar_age.py`, `test_scenarios/nf1_nectar_age.json`, `tools/verify.ps1`
- Check: `python -m unittest tests.test_nf1_nectar_age` passes (the summary carries `nectar_age` with p95 >= p50 and max > 0); the plan's NF-1 "Evidence" paragraph records both runs; `tools/verify.ps1` is green
- Proof: `absent: scripts/hive_cell.gd :: nectar_since`
- Next after: NF-2 -- nectar ferments past an age, changes colour, and is lost to honey makers
```

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
  A fermented cell draws its nectar in a distinct colour, and takes no
  fresh nectar until emptied ("Still open", to be confirmed).
- `hive.find_cell_with("nectar")`, for honey makers, skips fermented
  cells. `find_food_cell` still offers them: bees cannot tell (decision 4),
  and the debuff is NF-3's.
- `nectar_since` is saved per cell as an additive field. An older save
  loads with the stamp at the restore time, following
  `.claude/rules/saving.md`.
- `test_scenarios/nf2_fermentation.json` uses a short threshold through
  `config_overrides`, with no honey makers. `tests/test_nf2_fermentation.py`
  asserts that a nectar cell ferments, a honey maker never takes from it,
  and its stamp survives a save and restore.

**Must not change.** Ripe-honey ripening, eating order, and every other
cell content type.

```queue-gated
**[Claude] NF-2 -- nectar ferments past an age, changes colour, and is lost to honey makers**
- Plan: `plans/now/nectar-fermentation.md` -- "NF-2 -- nectar ferments past an age, changes colour, and is lost to honey makers"
- Files: `scripts/game_config.gd`, `scripts/settings_catalogue.gd`, `scripts/hive_cell.gd`, `scripts/hive.gd`, `scripts/save_game.gd`, `scripts/saving.gd`, `tests/test_nf2_fermentation.py`, `test_scenarios/nf2_fermentation.json`, `tools/verify.ps1`
- Check: `python -m unittest tests.test_nf2_fermentation` passes (a cell ferments, honey makers skip it, its stamp survives save and restore); `tools/verify.ps1` is green
- Proof: `absent: scripts/hive_cell.gd :: func is_fermented`
- Next after: NF-3 -- a bee that drinks fermented nectar goes tipsy
```
