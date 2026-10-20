# Tier-two skills -- step 8: the second ring of the tree, Shiver Cluster and bodies

<!-- CONTEXT: plan | LAYER: immediate-task -->
Status: active | Owner: Dave / Claude Code | Next: T2-14, once RR-10 (Codex lane) releases `scripts/hive.gd`; T2-13 landed 20 Oct 2026 (a role change puts a carried body down; gameplay review, 15 Oct 2026) (T2-11 answered 17 Oct 2026: a comb worker's idle reason starts a site, so without Automation comb grows outward only while one is selected); T2-12 landed 20 Oct 2026 (Dig on its own waits for Automation; C-136 awaits Dave's check); then T2-7b (T2-9 landed 12 Oct 2026: branch-tier progress counts only the lower-tier skills the run offers, C-113) -- the tier-2 price sweep T2-7 deferred (Dave, 11 Oct 2026: the alpha arc makes no honey, so no median can land in band until AR-4's arc buys a Honey worker) | Dependency: COL-4, COL-6, T2-4a, T2-4b, T2-6 and T2-7 landed (T2-7 on 11 Oct 2026, as the rule, snapshot field and pacing row); T2-7b waits for AR-4 (`plans/now/alpha-route-evidence.md`) | Verified: 2026-10-20

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
| T2-14 | a comb worker's idle reason asks whether there is room to build without starting a site (found by T2-11) | `scripts/bee.gd`, `scripts/hive.gd`, tests | no -- after T2-13 (`scripts/bee.gd`) and once RR-10 (Codex lane) releases `scripts/hive.gd` | low |
| T2-13 | a bee whose role changes while it carries a body puts the body down (gameplay review, 15 Oct 2026) | `scripts/bee.gd`, tests | yes (T2-10 landed 16 Oct 2026) | low |
| T2-7b | The tier-2 price sweep T2-7 deferred: tier-2 costs set so the arc's first tier-2 purchase lands around day 5 | `scripts/skills.gd`, `plans/design/progression.md`, tests; specified when AR-4 lands | no -- after AR-4 (`plans/now/alpha-route-evidence.md`), whose arc buys a Honey worker | medium |

**Dependencies.** T2-10 and T2-13 both edit `scripts/bee.gd`; T2-10
landed 16 Oct 2026, so T2-13 is open. T2-14 edits `scripts/bee.gd` too,
so it runs after T2-13, and `scripts/hive.gd`, held by RR-10 (Codex
lane). T2-12 landed 20 Oct 2026 (FC-2 released `scripts/hud.gd` on 17 Oct 2026). T2-7b waits for AR-4
(`plans/now/alpha-route-evidence.md`): the alpha arc makes no honey, so the
sweep's median cannot land in band before AR-4's arc buys a Honey worker
(Dave, 11 Oct 2026); it prices NF-4's Colony tier-2 node and includes
BB-2's 15-day unfed-worker rule. Open when T2-7b is specified: whether
BB-4's Challenge routes are re-checked at the new prices.

**Reads.** A slice reads its own section below and the step 8 decisions in
`plans/design/progression.md` (`python tools/heading.py
plans/design/progression.md "11. Implementation sequence"`, step 8 only).

T2-1 to T2-6, T2-8b, T2-9 and COL-4 shipped 7-12 Oct 2026; each has its record in `plans/archive/`, named by id and date.

T2-10 shipped 2026-10-16; its specification is `plans/archive/T2-10_2026-10-16.md`.

T2-11 shipped 2026-10-17; its specification is `plans/archive/T2-11_2026-10-17.md`.

**Code health (`plans/now/code-health.md`, 18 Oct 2026).** CQ-R3 moves `bee.gd`'s display text (`idle_reason`, `_task_line`) to scripts/bee_readout.gd and waits for T2-14, which removes `idle_reason`'s comb-site side effect; T2-12 and T2-13 share `hud.gd`/`bee.gd` with code-health slices in the same lane, one after the other.

## T2-14 -- a comb worker's idle reason asks whether there is room to build, without starting a site

Level: low (one query split out of one function, two files). Found by
T2-11 (17 Oct 2026). T2-2 already decided the player-visible outcome:
building comb outward is Automation's. This slice removes a way round
that gate; it decides nothing new. **Gate:** it runs after T2-13, which
also edits `scripts/bee.gd`, and `scripts/hive.gd` is held by RR-10
(Codex lane); queue this once both are done.

**True now** (verified 17 Oct 2026 against master `ea181c9`).
`bee.gd::idle_reason`'s BUILD_IDLE branch tests
`hive.create_next_cell_site(home_hex if has_home_hex else Vector2i.ZERO) == null`.
`hive.gd::create_next_cell_site` starts a site (`_start_site_at`) at the
first buildable spiral tile. `hud.gd::_refresh_selection_text` calls
`idle_reason()` on its refresh cadence while one bee is selected. So
selecting an idle Build-mode comb worker without Automation starts
outward sites, which `comb_build` then builds
(`bee_building.gd::create_cell_site_at` falls back to
`hive.find_unfinished_cell`). `tests.test_t2_11_comb_cadence`'s
no-Automation case prints "0 sites started that day" for day 1, with
nothing selected, and "5 sites started that day" for day 2, with one comb
worker selected.

**True afterwards.** `hive.gd` gains
`func has_room_to_build(around: Vector2i = Vector2i.ZERO) -> bool`. The
spiral walk moves into one private helper that both it and
`create_next_cell_site` call, so the two cannot drift
(`.claude/rules/simulation.md`, two loops over the same range).
`create_next_cell_site` keeps its behaviour and its `_no_room_frame`
memo. `idle_reason` calls `hive.has_room_to_build(...)`, with the same
argument, in place of `create_next_cell_site`; its wording does not
change. A comment cites T2-14.

**Invariants.** Save format unchanged. No per-tick work added:
`idle_reason` runs only from the HUD and tests. Building with Automation
is unchanged. `python -m unittest tests.test_t2_10_automine_wake` still
passes.

```queue-gated
**[Claude] T2-14 -- a comb worker's idle reason asks whether there is room to build, without starting a site**
- Plan: `plans/now/tier-two.md` -- "T2-14 -- a comb worker's idle reason asks whether there is room to build, without starting a site"
- Files: `scripts/bee.gd`, `scripts/hive.gd`, `tests/t2_14_idle_reason_pure_test.gd`, `tests/test_t2_14_idle_reason_pure.py`
- Check: `python -m unittest tests.test_t2_14_idle_reason_pure` passes: a comb worker in Build mode without Automation, in BUILD_IDLE with room to build, gives the Automation idle reason, and `hive.cells.size()` is unchanged after 20 `idle_reason()` calls; `hive.has_room_to_build()` is true exactly when `create_next_cell_site()` then returns a site; in `python -m unittest tests.test_t2_11_comb_cadence`'s no-Automation case the DAY 2 line, with a comb worker selected, says "0 sites started that day".
- Proof: `present: scripts/bee.gd :: if hive.create_next_cell_site(home_hex if has_home_hex else Vector2i.ZERO) == null:`
- Next after: T2-7b -- the tier-2 price sweep T2-7 deferred
```

T2-12 shipped 2026-10-20; its specification is `plans/archive/T2-12_2026-10-20.md`.

## T2-13 -- a bee whose role changes while it carries a body puts the body down

Level: low (one helper on the role-change choke point). Gameplay review
15 Oct 2026, finding F3 (Dave's decision D3 put it here, beside T2-4b's
bodies). Opened when T2-10 landed (16 Oct 2026), which held
`scripts/bee.gd`.

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

```queue
**[Claude] T2-13 -- a bee whose role changes while it carries a body puts the body down**
- Plan: `plans/now/tier-two.md` -- "T2-13 -- a bee whose role changes while it carries a body puts the body down"
- Files: `scripts/bee.gd`, `tests/t2_13_carried_body_test.gd`, `tests/test_t2_13_carried_body.py`
- Check: `python -m unittest tests.test_t2_13_carried_body` passes: a comb worker inside the hive that has lifted a body, made a Forager, has `carrying_corpse` and `corpse_is_bee` false, `hive.bodies` is one longer, and once given 30 nectar its `carrying_text()` names the nectar, not a dead bee; a comb worker carrying a dead larva, made a Forager, has `carrying_corpse` false and `hive.bodies` unchanged; `python -m unittest tests.test_t2_4b_bodies` still passes.
- Proof: `absent: scripts/bee.gd :: func _put_down_body(`
- Next after: T2-7b -- the tier-2 price sweep T2-7 deferred
```

## Not in the queue, and why

- **T2-14** -- a comb worker's idle reason asks whether there is room to build, without starting a site (found by T2-11, 17 Oct 2026); runs after T2-13 (both edit `scripts/bee.gd`) and waits for RR-10 (Codex lane) to release `scripts/hive.gd`.
- **T2-7b** -- the deferred tier-2 price sweep (first tier-2 purchase around day 5); waits for AR-4 (`plans/now/alpha-route-evidence.md`), whose arc buys a Honey worker, and is specified when it lands.
