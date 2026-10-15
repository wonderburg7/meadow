# Tier-two skills -- step 8: the second ring of the tree, Shiver Cluster and bodies

<!-- CONTEXT: plan | LAYER: immediate-task -->
Status: active | Owner: Dave / Claude Code | Next: T2-10, then T2-11 (from Dave's 14 Oct 2026 pass: miners on Dig on its own, comb workers building unevenly); T2-12 waits for `hud.gd`; then T2-7b (T2-9 landed 12 Oct 2026: branch-tier progress counts only the lower-tier skills the run offers, C-113) -- the tier-2 price sweep T2-7 deferred (Dave, 11 Oct 2026: the alpha arc makes no honey, so no median can land in band until AR-4's arc buys a Honey worker) | Dependency: COL-4, COL-6, T2-4a, T2-4b, T2-6 and T2-7 landed (T2-7 on 11 Oct 2026, as the rule, snapshot field and pacing row); T2-7b waits for AR-4 (`plans/now/alpha-route-evidence.md`) | Verified: 2026-10-14

## Objective

`plans/design/progression.md` section 11, step 8: the tier-2 skills that
already have behaviour become purchases, and the alpha's new tier-2
behaviour (rain recall, associative learning, Shiver Cluster, cleaning the
dead) is built. Every design decision is recorded once, in
`plans/design/progression.md` step 8 ("Decisions", 6 and 7 Oct 2026) and
section 5.6 ("Shiver Cluster"); slices here restate them in a sentence and
never re-argue them.

## Current state

Verified 7 Oct 2026 against master:

- Only Nurses and Honey worker gate a role (`roles.gd` `skill` field, read
  by `availability.gd::role_query` and `action_query`). Comb worker and
  Miner carry `"skill": ""`.
- `action_query` lets the queen nurse without Nurses (BS-9) through an
  inline `Roles.NURSE` check. `role_query`, which the HUD's Job row
  (`hud.gd::_role_offered`) and `orders_zones.gd::_role_permitted` read,
  has no bee argument and no queen exemption.
- `mode_query` checks stage gates only; no mode is skill-gated. The Miner's
  "Dig on its own" is `actions.gd`'s `mine_automine_block` row; Comb
  workers' outward building is `comb_build` over `hive.gd`'s outward hex
  spiral.
- Value-switch skills use `enable_behaviour` effects read through a helper
  such as `bee_foraging.gd::tarsal_markers_on`. Adaptive constancy reads
  `GameConfig.adaptive_constancy_on` directly (three places in
  `bee_foraging.gd`, off by default).
- "Seeding implies owning" (`run_availability.gd::_seeded_skills`) is
  generic over every role with a skill and a `start_count_key`, so a run
  that seeds builders or miners will own their skills with no new code.
- Challenge 2 introduces Comb worker at stage 2.7 and Miner, with "Dig on
  its own", at 2.8 (`challenge_stages.gd`). A stage's `free_skills` waive
  cost while it is current; a skill must also be in `unlocked_keys` to be
  permitted. A tier opens only when every node of the tier below in that
  branch is owned (`progression.gd::branch_tier_open`), so Hive Mind tier 2
  needs Backup roles owned.
- Clearing (`comb_clean_cell`, Comb worker "maintain" mode, gated on
  Cleaning) clears dead larvae first and then, since T2-4b, carries out the
  bodies of bees who died inside the hive (`hive.gd`'s `bodies`,
  `scripts/hive_body.gd`), which count towards disease like dead larvae.
  A meadow death still leaves only the presentation-only death marker.
- Rain runs only while `GameConfig.weather_on` (false by default) and the
  level row allow it (`main.gd`, weather advance). `bee_status.gd` keeps
  bees in above `rain_forage_limit`.

## Open slices

| Slice | What it does | Files it owns | Startable | Level |
| --- | --- | --- | --- | --- |
| T2-10 | a miner on Dig on its own starts as soon as Automation is bought; idle miners and comb workers say they need Automation (Dave's 14 Oct 2026 pass) | `scripts/bee.gd`, tests | yes | medium |
| T2-11 | investigation: why comb workers build unevenly, one bounded question | tests, this plan | yes, after T2-10 | high |
| T2-12 | Dig on its own offered only once Automation is owned | `scripts/hud.gd`, tests | no -- after FC-2 releases `hud.gd` (GP-4 released it 15 Oct 2026) | low |
| T2-7b | The tier-2 price sweep T2-7 deferred: tier-2 costs set so the arc's first tier-2 purchase lands around day 5 | `scripts/skills.gd`, `plans/design/progression.md`, tests; specified when AR-4 lands | no -- after AR-4 (`plans/now/alpha-route-evidence.md`), whose arc buys a Honey worker | medium |

**Dependencies.** T2-1, T2-2 and T2-3 run in that order in the Claude lane:
T2-1 and T2-2 share `roles.gd`, `availability.gd` and `challenge_stages.gd`,
and each adds a test module. They depend on
nothing else. T2-4a follows T2-2 (`actions.gd`, `challenge_stages.gd`).
T2-4b landed 9 Oct 2026, so it no longer shares files with NF-3
(`plans/archive/nectar-fermentation_2026-10-10.md`) or Bee Bread's BB-1
(`plans/archive/bee-bread_2026-10-11.md`).
T2-7 (landed 11 Oct 2026) measures the gates T2-1 to T2-3 built; T2-7b prices them. T2-6 shared `skills.gd` with
T2-7, so it ran after it in the Claude lane (NF-4 and BB-2, which shared
`skills.gd`, `bee_foraging.gd`, `game_config.gd` and `settings_catalogue.gd`, landed 10 Oct 2026).
Pollinator Points (`plans/now/pollination.md` PP-1) needs T2-6: foraging
tier 3 opens only when Associative learning is owned. T2-8 multiplies COL-6's one-step winter (landed 7 Oct 2026).
NF-4 (`plans/archive/nectar-fermentation_2026-10-10.md`) added a Colony tier-2 node in
`skills.gd` and landed 10 Oct 2026, before T2-7b, which prices it. T2-7b runs after
BB-2 (`plans/archive/bee-bread_2026-10-11.md`), so its sweep includes the 15-day
unfed-worker rule; BB-4 moves stage thresholds only, never prices.
T2-7b waits for AR-4 (`plans/now/alpha-route-evidence.md`): the alpha arc
makes no honey, so the sweep's median cannot land in band before AR-4's arc
buys a Honey worker (Dave, 11 Oct 2026). Open when T2-7b is specified:
whether BB-4's Challenge routes are re-checked at the new prices. A new test module no longer edits
`tools/verify.ps1`, which finds them itself since 7 Oct 2026, so adding a
test puts no shared file in either lane.

**Reads.** A slice reads its own section below and the step 8 decisions in
`plans/design/progression.md` (`python tools/heading.py
plans/design/progression.md "11. Implementation sequence"`, step 8 only).

T2-1 shipped 2026-10-07; its specification is `plans/archive/T2-1_2026-10-07.md`.

T2-2 shipped 2026-10-07; its specification is `plans/archive/T2-2_2026-10-07.md`.

T2-3 shipped 2026-10-07; its specification is `plans/archive/T2-3_2026-10-07.md`.

COL-4 shipped 2026-10-07; its specification is `plans/archive/COL-4_2026-10-07.md`.

T2-4a shipped 2026-10-08; its specification is `plans/archive/T2-4a_2026-10-08.md`.

T2-5 shipped 2026-10-09; its specification is `plans/archive/T2-5_2026-10-09.md`.

T2-4b shipped 2026-10-09; its specification is `plans/archive/T2-4b_2026-10-09.md`.

T2-6 shipped 2026-10-11; its specification is `plans/archive/T2-6_2026-10-11.md`.

T2-9 shipped 2026-10-12; its specification is `plans/archive/T2-9_2026-10-12.md`.

```queue
**[Claude] T2-10 -- a miner on Dig on its own starts as soon as Automation is bought, and an idle miner or comb worker says it needs Automation**
- Plan: `plans/now/tier-two.md` -- "T2-10 -- a miner on Dig on its own starts as soon as Automation is bought"
- Files: `scripts/bee.gd`, `tests/t2_10_automine_wake_test.gd`, `tests/test_t2_10_automine_wake.py`
- Check: `python -m unittest tests.test_t2_10_automine_wake` passes: a miner with `automine` on and Automation not owned finds no work and its `idle_reason()` names Automation; Automation is then granted and `Availability.invalidate()` called, with no block marked and `hive.mining_work_epoch` unchanged, and the miner's next `_try_role_work(Role.MINER)` returns true; a comb worker in Build mode with nothing marked, room to build and no Automation gives an `idle_reason()` naming Automation.
- Proof: `absent: scripts/bee.gd :: _mining_no_work_gate_epoch`
- Next after: T2-11 -- why comb workers build comb unevenly (investigation)
```
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
**[Claude] T2-11 -- why comb workers build comb unevenly (investigation)**
- Plan: `plans/now/tier-two.md` -- "T2-11 -- why comb workers build comb unevenly (investigation)"
- Files: `tests/t2_11_comb_cadence_test.gd`, `tests/test_t2_11_comb_cadence.py`, `plans/now/tier-two.md`
- Check: `python -m unittest tests.test_t2_11_comb_cadence` runs and prints, for each idle spell longer than 10 game-seconds, the comb worker's mode, `idle_reason()` and which finder returned nothing; the answer and the fix slice it implies are written into this section.
- Proof: `present: scripts/bee.gd :: func idle_reason() -> String:`
- Next after: T2-12 -- Dig on its own is offered only once Automation is owned
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

```queue-gated
**[Claude] T2-12 -- Dig on its own is offered only once Automation is owned**
- Plan: `plans/now/tier-two.md` -- "T2-12 -- Dig on its own is offered only once Automation is owned"
- Files: `scripts/hud.gd`, `tests/t2_12_automine_offer_test.gd`, `tests/test_t2_12_automine_offer.py`
- Check: `python -m unittest tests.test_t2_12_automine_offer` passes: without Automation a selected miner's Job panel shows no "Dig on its own" toggle and a cell's raise menu offers no "Miner — Dig on its own"; with Automation owned both are offered.
- Proof: `present: scripts/hud.gd :: the Miner's "Dig on its own" has shown regardless`
- Next after: T2-7b -- the tier-2 price sweep T2-7 deferred
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

## Not in the queue, and why

- **T2-12** -- hide "Dig on its own" until Automation is owned (Dave, 14 Oct 2026); waits for FC-2 (Codex lane) to release `scripts/hud.gd` (GP-4 released it 15 Oct 2026).
- **T2-7b** -- the deferred tier-2 price sweep (first tier-2 purchase around day 5); waits for AR-4 (`plans/now/alpha-route-evidence.md`), whose arc buys a Honey worker, and is specified when it lands.

T2-8b shipped 2026-10-09; its specification is `plans/archive/T2-8b_2026-10-09.md`.
