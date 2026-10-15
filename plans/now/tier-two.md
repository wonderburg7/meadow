# Tier-two skills -- step 8: the second ring of the tree, Shiver Cluster and bodies

<!-- CONTEXT: plan | LAYER: immediate-task -->
Status: active | Owner: Dave / Claude Code | Next: T2-11 (T2-10 landed 16 Oct 2026: a miner wakes when Automation is bought, C-135) (from Dave's 14 Oct 2026 pass: miners on Dig on its own, comb workers building unevenly); T2-12 waits for `hud.gd`; T2-13 (a role change drops a carried body; gameplay review, 15 Oct 2026) waits for T2-10; then T2-7b (T2-9 landed 12 Oct 2026: branch-tier progress counts only the lower-tier skills the run offers, C-113) -- the tier-2 price sweep T2-7 deferred (Dave, 11 Oct 2026: the alpha arc makes no honey, so no median can land in band until AR-4's arc buys a Honey worker) | Dependency: COL-4, COL-6, T2-4a, T2-4b, T2-6 and T2-7 landed (T2-7 on 11 Oct 2026, as the rule, snapshot field and pacing row); T2-7b waits for AR-4 (`plans/now/alpha-route-evidence.md`) | Verified: 2026-10-14

## Objective

`plans/design/progression.md` section 11, step 8: the tier-2 skills that
already have behaviour become purchases, and the alpha's new tier-2
behaviour (rain recall, associative learning, Shiver Cluster, cleaning the
dead) is built. Every design decision is recorded once, in
`plans/design/progression.md` step 8 ("Decisions", 6 and 7 Oct 2026) and
section 5.6 ("Shiver Cluster"); slices here restate them in a sentence and
never re-argue them.

## Current state

Verified 15 Oct 2026 against master `b5e6751`. T2-1 to T2-6, T2-8b, T2-9 and
COL-4 have landed (T2-7 too, as the rule, snapshot field and pacing row).
What the open slices build on:

- Comb worker and Miner are skill-gated roles (`roles.gd`:
  `skill.colony.comb_worker`, `skill.colony.miner`), read by
  `availability.gd::role_query` and `action_query`.
- The Miner's "Dig on its own" (`actions.gd`'s `mine_automine_block`) and
  Comb workers' outward building (`comb_build_outward`) need
  `skill.hive_mind.automation`.
- A tier opens only when the lower-tier skills the run offers in that branch
  are owned (`progression.gd::branch_tier_open`, T2-9).
- Bodies of bees who die inside the hive lie in `hive.gd`'s `bodies`
  (`scripts/hive_body.gd`); a Comb worker in "maintain" mode carries them
  out (`bee_building.gd`), and they count towards disease.

## Open slices

| Slice | What it does | Files it owns | Startable | Level |
| --- | --- | --- | --- | --- |
| T2-10 | a miner on Dig on its own starts as soon as Automation is bought; idle miners and comb workers say they need Automation (Dave's 14 Oct 2026 pass) | `scripts/bee.gd`, tests | yes | medium |
| T2-11 | investigation: why comb workers build unevenly, one bounded question | tests, this plan | yes, after T2-10 | high |
| T2-12 | Dig on its own offered only once Automation is owned | `scripts/hud.gd`, tests | no -- after FC-2 releases `hud.gd` (GP-4 released it 15 Oct 2026) | low |
| T2-13 | a bee whose role changes while it carries a body puts the body down (gameplay review, 15 Oct 2026) | `scripts/bee.gd`, tests | no -- after T2-10 releases `scripts/bee.gd` | low |
| T2-7b | The tier-2 price sweep T2-7 deferred: tier-2 costs set so the arc's first tier-2 purchase lands around day 5 | `scripts/skills.gd`, `plans/design/progression.md`, tests; specified when AR-4 lands | no -- after AR-4 (`plans/now/alpha-route-evidence.md`), whose arc buys a Honey worker | medium |

**Dependencies.** T2-10 and T2-13 both edit `scripts/bee.gd`, so T2-13
opens when T2-10 lands; T2-11 runs after T2-10, whose miner fix its
question assumes. T2-12 waits for FC-2 (`plans/now/crisis-readiness.md`,
Codex lane) to release `scripts/hud.gd`. T2-7b waits for AR-4
(`plans/now/alpha-route-evidence.md`): the alpha arc makes no honey, so the
sweep's median cannot land in band before AR-4's arc buys a Honey worker
(Dave, 11 Oct 2026); it prices NF-4's Colony tier-2 node and includes
BB-2's 15-day unfed-worker rule. Open when T2-7b is specified: whether
BB-4's Challenge routes are re-checked at the new prices.

**Reads.** A slice reads its own section below and the step 8 decisions in
`plans/design/progression.md` (`python tools/heading.py
plans/design/progression.md "11. Implementation sequence"`, step 8 only).

T2-1 to T2-6, T2-8b, T2-9 and COL-4 shipped 7-12 Oct 2026; each has its record in `plans/archive/`, named by id and date.

## T2-10 -- a miner on Dig on its own starts as soon as Automation is bought

Level: medium (one guard on the idle think path; no new per-tick work).
Dave's 14 Oct 2026 pass: "dig on their own" miners do not dig without
the player stepping in.

**True now** (verified 14 Oct 2026 against master `3e37ea6`).

- `actions.gd`'s `mine_automine_block` row (and `comb_build_outward`)
  names `skill.hive_mind.automation`; without it the row is skipped, by
  design since T2-2.
- `bee.gd::_try_role_work` remembers a miner's failed search in
  `_mining_no_work_epoch` / `_mining_no_work_automine` and returns false
  without searching while `hive.mining_work_epoch` and `automine` are
  unchanged. Buying a skill calls `Availability.invalidate()`
  (`skill_tree_panel.gd`), which advances `Availability.gate_epoch`, not
  the mining epoch. So a miner that looked while Automation was unowned
  stays idle after it is bought until something advances the mining
  epoch: the player marking a block is what wakes it.
- `bee.gd::idle_reason`, `State.MINE_IDLE` with `automine` on, says "No
  soil left within reach" even when the real cause is Automation not
  being owned. `State.BUILD_IDLE` in Build mode returns "" when there is
  room to build, so a comb worker idle for want of Automation says nothing.

**True afterwards.**

- `bee.gd` adds `_mining_no_work_gate_epoch`, set beside the other two
  where a search fails, and the guard also requires it to equal
  `Availability.gate_epoch`. Nothing else in the guard changes.
- `idle_reason`, `MINE_IDLE`, `automine` on and the
  `mine_automine_block` row unavailable (`_action_available`): "Dig on its
  own needs the Automation skill. Until then, mark blocks with Mine."
- `idle_reason`, `BUILD_IDLE`, Build or Both mode, `hive.create_next_cell_site`
  finds a site but `comb_build_outward` is unavailable: "Nothing marked to
  build. Mark cells to build, or get the Automation skill so comb workers
  build outward on their own."
- The test pair follows `tests/t2_2_automation_gate_test.gd` and
  `tests/test_t2_2_automation_gate.py`.

**Invariants.** The no-work guard still stops an idle miner walking the
soil every think tick (`tests/source_checks.py` keeps its
`_try_role_work` rule green); marked blocks still come before automine.

**Escalate** if a granted Automation still leaves the miner idle with the
guard fixed: the cause is then elsewhere and this section is wrong.

**Hands-on check on landing** (move from `checks/blocked.md` to ready):
C-135.

```queue
**[Claude] T2-10 -- a miner on Dig on its own starts as soon as Automation is bought, and an idle miner or comb worker says it needs Automation**
- Plan: `plans/now/tier-two.md` -- "T2-10 -- a miner on Dig on its own starts as soon as Automation is bought"
- Files: `scripts/bee.gd`, `tests/t2_10_automine_wake_test.gd`, `tests/test_t2_10_automine_wake.py`
- Check: `python -m unittest tests.test_t2_10_automine_wake` passes: a miner with `automine` on and Automation not owned finds no work and its `idle_reason()` names Automation; Automation is then granted and `Availability.invalidate()` called, with no block marked and `hive.mining_work_epoch` unchanged, and the miner's next `_try_role_work(Role.MINER)` returns true; a comb worker in Build mode with nothing marked, room to build and no Automation gives an `idle_reason()` naming Automation.
- Proof: `absent: scripts/bee.gd :: _mining_no_work_gate_epoch`
- Next after: T2-11 -- why comb workers build comb unevenly (investigation)
```

## T2-11 -- why comb workers build comb unevenly (investigation)

Level: high (ambiguous bug). Dave, 14 Oct 2026: comb workers "seem to
not be creating combs automatically in a consistent way". Not yet
diagnosed. Two hypotheses, neither confirmed: (a) without Automation a
comb worker only finishes half-built sites and builds marked ones, so it
builds some cells and then stops, which reads as uneven; (b) with
Automation, `hive.create_next_cell_site` returns null once the open floor
is full, which happens sooner while miners stay idle (T2-10's bug).

**The one question.** In a Colony Run started from the menu's defaults,
with Automation owned from the start, two comb workers in Build mode and
two miners on Dig on its own, over five game-days: does a comb worker
ever sit idle for more than 10 game-seconds while
`hive.create_next_cell_site` would return a site? If yes, which finder
row refused and why (file::function). If no, hypothesis (b) or (a)
explains what Dave saw, and the fix is T2-10 plus T2-12.

Write the result as a line starting `T2-11 answer:` here, then specify
the fix slice (or none) below it. Do not change game code in this slice.

```queue
**[Claude] T2-11 -- why comb workers build comb unevenly (investigation)**
- Plan: `plans/now/tier-two.md` -- "T2-11 -- why comb workers build comb unevenly (investigation)"
- Files: `tests/t2_11_comb_cadence_test.gd`, `tests/test_t2_11_comb_cadence.py`, `plans/now/tier-two.md`
- Check: `python -m unittest tests.test_t2_11_comb_cadence` runs and prints, for each idle spell longer than 10 game-seconds, the comb worker's mode, `idle_reason()` and which finder returned nothing; the answer and the fix slice it implies are written into this section.
- Proof: `present: scripts/bee.gd :: func idle_reason() -> String:`
- Next after: T2-12 -- Dig on its own is offered only once Automation is owned
```

## T2-12 -- Dig on its own is offered only once Automation is owned

Level: low. Dave, 14 Oct 2026: hide the toggle until Automation is owned,
as Fermenting waits for Bee bread. **Gate:** `scripts/hud.gd` is next
held by FC-2 (Codex lane; GP-4 released it 15 Oct 2026); queue this once FC-2 releases it.

**True now.** `hud.gd`'s mode column skips a mode whose `mode_query`
fails only for Honey and Comb worker; its comment says the Miner's toggle
"has shown regardless" since T2-2. `hud.gd::_fill_hatch_menu` filters
options by stage gate only, so "Miner — Dig on its own" is offered without
Automation.

**True afterwards.** The mode-column condition also covers
`Roles.MINER`, with the comment rewritten to say all three wait for
their skill. `_fill_hatch_menu` also skips an option whose mode fails
`Availability.mode_query(role_value, mode, null, Session.progression)`,
which hides an unowned Comb worker Stocking option the same way.
Levels that start miners with `automine` on (`levels.gd`) are unchanged:
T2-10's idle reason explains them.

**Hands-on check on landing** (move from `checks/blocked.md` to ready):
C-136.

```queue-gated
**[Claude] T2-12 -- Dig on its own is offered only once Automation is owned**
- Plan: `plans/now/tier-two.md` -- "T2-12 -- Dig on its own is offered only once Automation is owned"
- Files: `scripts/hud.gd`, `tests/t2_12_automine_offer_test.gd`, `tests/test_t2_12_automine_offer.py`
- Check: `python -m unittest tests.test_t2_12_automine_offer` passes: without Automation a selected miner's Job panel shows no "Dig on its own" toggle and a cell's raise menu offers no "Miner — Dig on its own"; with Automation owned both are offered.
- Proof: `present: scripts/hud.gd :: the Miner's "Dig on its own" has shown regardless`
- Next after: T2-7b -- the tier-2 price sweep T2-7 deferred
```

## T2-13 -- a bee whose role changes while it carries a body puts the body down

Level: low (one helper on the role-change choke point). Gameplay review
15 Oct 2026, finding F3 (Dave's decision D3 put it here, beside T2-4b's
bodies). **Gate:** `scripts/bee.gd` is held by T2-10; open this fence when
T2-10 has landed.

**True now** (verified 15 Oct 2026 against master `9c490df`). Only
`bee_building.gd::builder_dump_waste` clears `carrying_corpse` and
`corpse_is_bee`. `bee.gd::_apply_role` and `_release_everything` never do,
so a comb worker carrying a body that is given a new role keeps the flags
for good, and `bee.gd::carrying_text` (which checks `carrying_corpse`
first) says "Carrying: a dead bee, for disposal outside" over any real load
she later takes on. The review's probe: a comb worker carrying a body, made
a Forager with 30 nectar, showed exactly that. The body itself has already
left `hive.bodies` (`bee_building.gd::_lift_body`), so it is lost.

**True afterwards.** `bee.gd` gains `func _put_down_body() -> void`, called
in `_apply_role` beside `_return_nurse_food()` and `_return_bee_bread()`.
If `carrying_corpse` is false it returns. If `corpse_is_bee` and the bee is
inside the hive (`_is_inside_hive()`) and `hive` is valid, it calls
`hive.add_body(hive.nearest_walkable_point(position), Session.sim_time)`,
so another cleaner can pick it up. A dead larva, or a body carried outside
(the bee is already dumping it), is simply gone: its cell was already
cleared. Either way both flags end false. A comment cites T2-13.

**Invariants.** `builder_dump_waste` is unchanged. The body cap
(`GameConfig.max_hive_bodies`) still applies through `add_body`. The
restored body's `died_at` is the time it is put down (the lifted body's
own `died_at` is not kept). Save
format unchanged. No per-tick work.

**Escalate** if `carrying_corpse` is read anywhere outside `bee.gd`,
`bee_building.gd` and the save files by then.

```queue-gated
**[Claude] T2-13 -- a bee whose role changes while it carries a body puts the body down**
- Plan: `plans/now/tier-two.md` -- "T2-13 -- a bee whose role changes while it carries a body puts the body down"
- Files: `scripts/bee.gd`, `tests/t2_13_carried_body_test.gd`, `tests/test_t2_13_carried_body.py`
- Check: `python -m unittest tests.test_t2_13_carried_body` passes: a comb worker inside the hive that has lifted a body, made a Forager, has `carrying_corpse` and `corpse_is_bee` false, `hive.bodies` is one longer, and once given 30 nectar its `carrying_text()` names the nectar, not a dead bee; a comb worker carrying a dead larva, made a Forager, has `carrying_corpse` false and `hive.bodies` unchanged; `python -m unittest tests.test_t2_4b_bodies` still passes.
- Proof: `absent: scripts/bee.gd :: func _put_down_body(`
- Next after: T2-7b -- the tier-2 price sweep T2-7 deferred
```

## Not in the queue, and why

- **T2-12** -- hide "Dig on its own" until Automation is owned (Dave, 14 Oct 2026); waits for FC-2 (Codex lane) to release `scripts/hud.gd` (GP-4 released it 15 Oct 2026).
- **T2-13** -- a bee whose role changes while it carries a body puts the body down (gameplay review, 15 Oct 2026); waits for T2-10 to release `scripts/bee.gd`.
- **T2-7b** -- the deferred tier-2 price sweep (first tier-2 purchase around day 5); waits for AR-4 (`plans/now/alpha-route-evidence.md`), whose arc buys a Honey worker, and is specified when it lands.
