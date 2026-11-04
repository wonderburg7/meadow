# Gameplay systems consistency review -- 4 Nov 2026

<!-- CONTEXT: review-record | LOAD: on-demand -->
Reviewed: e8cc5401 | Since: 9c490df | Scope: Jules report `docs/jules-reviews/gameplay-review-2026-11-04.md` (R-gameplay, branch `jules/r-gameplay-review-2026-11-04-12219810295421638867`), processed by Claude: follow-through of the 15 Oct record, the three findings of the returned 30 Oct report, and a sweep over nine scripts only (see "Not reviewed") | Previous: `docs/gameplay-review-2026-10-15.md`

## Follow-through

| Previous finding | Disposition |
| --- | --- |
| F1 -- skipped winter ferments nectar and ripens sealed bee bread | Shipped -- RR-9 (`season.gd::_resolve_winter`; `tests/test_rr9_winter_ages_nothing.py`) |
| F2 -- fermented nectar buys skills | Shipped -- RR-10 (`skill_tree_panel.gd`, `hive.gd::take`; `tests/test_rr10_fermented_not_currency.py`) |
| F3 -- bee changing role keeps carrying_corpse | Shipped -- T2-13 (`bee.gd::_apply_role` calls `_put_down_body()`; `tests/test_t2_13_carried_body.py`) |

## Findings

| Id | Finding | Evidence | Severity | Disposition |
| --- | --- | --- | --- | --- |
| F1 | Queen's carried nurse food is not deposited on role change | `scripts/bee.gd::_return_nurse_food` (`if not is_queen`); spot-checked 4 Nov | medium | Rejected -- the BS-9 queen exception is documented in the function's comment and Dave retained it (D2, `plans/now/run-repairs.md` "Not in the queue, and why") |
| F2 | Backup dispatch keeps cargo while working a secondary job | `scripts/bee.gd::_dispatch_backup_list` | medium | Rejected -- a secondary job does not change `role`, and no causal loss or overwrite was reproduced, which D2 requires before any change |
| F3 | A bee dying inside the hive does not return carried food to the comb | `scripts/bee_survival.gd::die` (only `hive.add_body`); spot-checked 4 Nov | low | Rejected -- resource recovery on death is a design choice D2 left unscheduled, not a defect |

## Hand-offs

- Jules's R-gameplay sweep read nine scripts out of 85 changed since
  `9c490df`, against `plans/reference/jules-reviews.md` step 3 ("Read every
  file in scope, not a sample"): entry of 4 Nov 2026 in
  `plans/observations/system-improvement-signals.md`.

## Noted, not pursued

- `year_winter.gd::begin_winter_countdown` reads the level's `"winter"` key
  rather than `Session.year_has_winter`; `world_building.gd` sets the latter
  from the same key, so they agree. A duplicate source that currently
  agrees is the architecture review's (Hand-offs line of the review file).
- `bee.gd`'s `working_secondary` is not saved; on load bees re-assess idle
  dispatch. Within the save review's lane; not a defect on this evidence.
- Both `verified` findings were spot-checked against the code (contract
  step 3 of "Processing a Jules review"); both hold as described.

## Not reviewed

The report swept only `bee.gd`, `hive_cell.gd`, `hive.gd`,
`orders_zones.gd`, `season.gd`, `year_winter.gd`, `bee_nursery.gd`,
`bee_building.gd` and `bee_survival.gd`. `Reviewed:` is still set to the
report's commit, as processing requires, so the next run must sweep these
(`plans/reference/jules-reviews.md` step 3 takes in this list). Ranked by
lines changed in `9c490df..e8cc5401`, the ones this review owns first:

- Selection and orders that act on the simulation: `input_selection.gd`
  (441, includes RR-22's multi-selection count), `main.gd` (630),
  `hud_command_rows.gd` (588).
- Challenge and Scenario paths: `challenge_runner.gd` (241),
  `conditions.gd` (147), `colony_milestones.gd` (202),
  `short_term_goals.gd` (53), `challenge_stage_setup.gd` (20).
- Stage and run transitions: `world_building.gd` (190), `session.gd` (72),
  `availability.gd` (33), `run_availability.gd` (24), `progression.gd`
  (68), `skills.gd` (52).
- Other simulation: `bee_foraging.gd` (135), `soil_block.gd` (68),
  `rival_hive.gd` (52), `flower.gd` (28), `game_config.gd` (79).
- Presentation that could gate simulation (rule 2): `hud.gd` (1401),
  `hud_goal_shelf.gd` (344), `colony_panel.gd` (180), `gallerin_panel.gd`
  (44), `skill_tree_panel.gd` (20).

Hands-on Godot play was not possible for Jules (headless VM) and was not
needed for three rejections.

## Patterns deliberately not applied

None.
