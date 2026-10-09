# Nectar fermentation -- unprocessed nectar ferments, and tipsy bees pay for it

<!-- CONTEXT: plan | LAYER: immediate-task -->
Status: active | Owner: Dave / Claude Code | Next: NF-5 -- clear fermented cells, queued in the Claude lane; NF-4 -- the detection skill, outlined below and gated on Dave's nurse and Restocking answers (NF-3 built 9 Oct 2026, with Dave's 300-second tipsiness from its sweep) | Dependency: none (NF-2 landed 9 Oct 2026); NF-4 follows NF-3 | Verified: 2026-10-09

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
- **Whether Restocking may draw from a fermented cell** (NF-4). NF-5 stops
  every eviction from moving fermented nectar into another cell, but a
  restock order (`bee_building.gd::may_draw_from`) still takes from one
  and tops up its target, which keeps the target's younger stamp. NF-4
  decides whether the detection skill, or the restock order itself, skips
  fermented sources.

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
| NF-3 | a bee that drinks fermented nectar goes tipsy (decision 3) | `scripts/bee.gd`, `scripts/bee_enums.gd`, `scripts/bee_survival.gd`, `scripts/bee_movement.gd`, `scripts/bee_foraging.gd`, `scripts/bee_status.gd`, `scripts/game_config.gd`, `scripts/settings_catalogue.gd`, `scripts/save_game.gd`, `scripts/saving.gd`, `tests/test_nf3_tipsy.py`, `test_scenarios/nf3_tipsy.json` | yes -- queued in the Claude lane (NF-2 landed 9 Oct 2026) | high |
| NF-4 | the detection skill: bees avoid fermented nectar, and honey makers take the oldest first; without it, closest first (decisions 4-5) | specified after NF-3 | no -- after NF-3 | high |
| NF-5 | an order to clear fermented cells, built on the cell popup's eviction orders (decision 6) | `scripts/bee_building.gd`, `scripts/orders_zones.gd`, `scripts/hud.gd`, `scripts/main.gd`, `scripts/scenario_actions.gd`, `tests/test_nf5_clear_fermented.py`, `test_scenarios/nf5_clear_fermented.json` | yes -- queued in the Claude lane (specified 9 Oct 2026) | medium |

**Dependencies.** NF-1, then NF-2, both landed. NF-3 and NF-5 each follow
NF-2, and NF-4 follows NF-3. Bee Bread's BB-1 (`plans/now/bee-bread.md`)
shares `hive.gd`, `game_config.gd`, `settings_catalogue.gd` and the save
files with NF-3, and `orders_zones.gd` and `hud.gd` with NF-5; all three
are in the Claude lane, which runs them one branch at a time, so none may
move to the Codex lane while another is queued (T2-4b, which shared them
too, landed 9 Oct 2026). NF-5's `hud.gd`, `main.gd` and
`scenario_actions.gd` are also in `plans/now/crisis-readiness.md` FC-2's
files, so FC-2 waits for it. NF-4's node joins Colony tier 2, which
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

**Sweep (9 Oct 2026, built on the branch).** Base: 20 cells, 8 nectar and
2 pollen foragers, 2 nurses, 1 builder, no honey makers, default 200-second
days, `nectar_ferment_hours` 1 (so stored nectar is nearly all fermented),
4 days, matched seeds, forage per day = `forager_delivery_amount` / days.
First finding: with default settings foragers refuel at flowers
(`forager_drink_threshold` 0.7) and never ate in the hive in 3 days, so no
setting changed forage at all. The sweep therefore also set
`forager_drink_threshold` 0, so foragers eat at home: the "colony eating
mostly fermented nectar" case. A trip then takes about 66 s (10 foragers,
121 deliveries in 800 s), and a forager eats about once every six trips, so
a 60 s tipsiness keeps it tipsy 13% of the time (counted from saves).

| tipsy_seconds | speed / vision / wobble | forage per day vs off, 5 seeds (401-405) |
| --- | --- | --- |
| 60 | 0.6 / 0.5 / 35 deg | -1.8% (every seed lower, -0.6 to -3.2) |
| 60 | 0.5 / 0.4 / 45 deg | -2.3% (-0.8 to -3.7) |
| 60 | 0.4 / 0.4 / 45 deg | -2.2% (-1.1 to -4.8) |
| 180 | 0.6 / 0.5 / 35 deg | -4.7% (-2.3 to -7.2) |
| 300 | 0.6 / 0.5 / 35 deg | -6.4% (-3.0 to -9.0) |

Strength barely matters, because a forager is tipsy for only one trip in
six; duration does. The two targets conflict: one sip costing a single
trip (about 60 s) loses about 2% of forage a day, which is not visible,
while a visible loss (5% or more) needs 180-300 s, three to five trips per
sip. Dave chose the visible loss (9 Oct 2026): built with `tipsy_seconds`
300 (about five trips per sip, -6.4% forage a day), speed 0.6, vision 0.5,
wobble 35 degrees, wander 0.05 a second for 6 s. Indoor workers carry a
visible cost too: a tipsy nurse, builder or honey maker walks at 0.6 and
breaks off into a wander about three times a minute.

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

## NF-4 -- the detection skill: bees avoid fermented nectar, and honey makers take the oldest first

<!-- LAYER: immediate-task -->

Level: high (a new skill node, which cells every eater and honey maker
chooses, and a cost set by simulation). Outlined 9 Oct 2026 when NF-3
landed; gated until Dave settles its nurse and Restocking questions under
"Still open".

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
- Nurses and restocking follow whatever Dave decides for the two open
  questions under "Still open".
- The skill's cost comes from a headless comparison run in this slice and
  recorded here: the same fermenting colony with and without the skill.
- `test_scenarios/nf4_fermentation_sense.json` and
  `tests/test_nf4_fermentation_sense.py` show from the run that, with the
  skill, no bee goes tipsy while fresh food is left and honey makers empty
  the oldest cell first, and, without it, honey makers take the closest.

**Must not change.** Fermentation itself, tipsiness (NF-3), honey ripening,
and what a colony without the skill eats.

```queue-gated
**[Claude] NF-4 -- the detection skill: bees avoid fermented nectar, and honey makers take the oldest first**
- Plan: `plans/now/nectar-fermentation.md` -- "NF-4 -- the detection skill: bees avoid fermented nectar, and honey makers take the oldest first"
- Files: `scripts/skills.gd`, `scripts/hive.gd`, `scripts/bee_honey.gd`, `scripts/bee_survival.gd`, `scripts/bee_nursery.gd`, `scripts/bee_building.gd`, `plans/design/progression.md`, `tests/test_nf4_fermentation_sense.py`, `test_scenarios/nf4_fermentation_sense.json`
- Check: `python -m unittest tests.test_nf4_fermentation_sense` passes (with the skill no bee goes tipsy while fresh food is left and honey makers take the oldest nectar first; without it honey makers take the closest); `tools/verify.ps1` is green
- Proof: `absent: scripts/skills.gd :: skill.colony.fermentation_sense`
- Next after: none -- nectar fermentation is complete once NF-5 has landed too
```

## NF-5 -- clear fermented cells

<!-- LAYER: immediate-task -->

Level: medium (one bounded order on existing machinery, no save field and no
per-frame work, with a deterministic scenario check). Specified 9 Oct 2026
by the queue steward, after NF-2 landed; verified against master that day.

**True now.** Rule 3's check, done: the cell popup's "Empty cell" controls
(`hud.gd::_build_empty_controls` -> `orders_zones.gd::_empty_one`) set
`hive_cell.evict_requested` and `evict_mode`, both already saved, and a comb
worker picks the cell up (`bee_building.gd::find_cell_needing_eviction`,
then `builder_go_to_haul_source`). "Discard outside" already hauls a cell's
nectar out of the hive, fermented or not, so decision 6 is half built. Two
things are missing:

- **Moving launders it.** "To another cell", "Empty this cell"
  (`bee.gd::command_empty_cell`, the move path) and a comb worker clearing a
  re-designated cell all carry the load to `hive.find_cell_for("nectar")`.
  An empty destination is stamped fresh by `hive_cell.add_resource`, and a
  part-full one keeps its own younger stamp, so fermented nectar comes out
  as fresh nectar. That breaks decision 2: fermented nectar can only be
  drunk or hauled out.
- **No order reaches every fermented cell.** The player must find and
  select each murky cell by hand.

The owner is that eviction path, not the restock orders: restocking moves
stores between cells and never takes anything out of the hive. This
supersedes the earlier line in "Current state" that NF-5 extends the
restock orders.

**True afterwards.**

- In `bee_building.gd::builder_go_to_haul_source`, a load lifted from a
  cell that was fermented goes to the waste exit, whatever `evict_mode`
  says. Check `is_fermented()` before the take, since a take that empties
  the cell clears its stamp. It never reaches another cell, so fermented
  nectar can't be laundered by any eviction or re-designation.
- The cell popup's Emptying column shows one more button, "Discard all sour
  nectar", while the popup's cell is fermented. Its tooltip says comb
  workers will carry every fermented cell's nectar out of the hive. Pressing
  it marks every fermented cell in the hive for discard: `evict_requested`
  set and `evict_mode = "discard"`, through one new `orders_zones.gd`
  handler on a new `hud.gd` signal connected in `main.gd` beside
  `cell_empty_requested`. Cells that ferment later aren't marked: this is
  an order, not a standing rule.
  "To another cell"'s tooltip says fermented nectar is always thrown out.
- No new state and no save change: the marks are the existing saved
  eviction fields, so an order in progress survives save and restore.
- Runtime policy: the order is one pass over `hive.cells` on a button
  press. The fermented check runs once per lifted load. Nothing runs per
  frame.
- `scripts/scenario_actions.gd` gains a `clear_fermented` action that calls
  the same handler and logs how many cells it marked.
  `test_scenarios/nf5_clear_fermented.json` uses a short
  `nectar_ferment_hours` with comb workers and no honey makers. It
  ferments three nectar cells, then stocks a fresh control cell and leaves
  some empty comb. It saves, runs `clear_fermented`, saves while the
  workers are partway through, restores that save, and lets them finish.
  Then it ferments one more cell, empties it with `empty_cell` (the move
  path), and saves. `tests/test_nf5_clear_fermented.py` asserts from the
  saves that:
  - exactly the three fermented cells were marked, and the marks survived
    the restore;
  - all three end empty;
  - the control cell kept its nectar and its stamp;
  - no empty cell gained nectar;
  - the moved cell's nectar went outside, not into another cell.

**Must not change.** Emptying and moving any other content, the existing
Discard and Empty controls' behaviour for fresh nectar, fermentation itself,
what bees eat or make honey from, and the restock orders.

**Not in this slice.** Whether Restocking may draw from a fermented cell is
NF-4's to decide, under "Still open".

```queue
**[Claude] NF-5 -- clear fermented cells**
- Plan: `plans/now/nectar-fermentation.md` -- "NF-5 -- clear fermented cells"
- Files: `scripts/bee_building.gd`, `scripts/orders_zones.gd`, `scripts/hud.gd`, `scripts/main.gd`, `scripts/scenario_actions.gd`, `tests/test_nf5_clear_fermented.py`, `test_scenarios/nf5_clear_fermented.json`
- Check: `python -m unittest tests.test_nf5_clear_fermented` passes (the order marks exactly the fermented cells, comb workers carry them out, the marks survive save and restore, a fresh cell is untouched, and moving a fermented cell puts nothing into another cell); `.\tools\verify.ps1` is green
- Proof: `absent: scripts/orders_zones.gd :: is_fermented`
- Next after: NF-4 -- the detection skill: bees avoid fermented nectar, and honey makers take the oldest first
```

## Not in the queue, and why

- **NF-4** waits for Dave's answers to its two questions under "Still
  open": whether the skill also steers nurses away from fermented nectar,
  and whether Restocking may draw from a fermented cell. (Its cost is set by
  simulation inside the slice.) When both are in, recheck its `Files:` line
  against the skill tree's own files, then open the fence to `queue`.
