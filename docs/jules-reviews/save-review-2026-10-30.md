# Save, restore and migration review (Jules) -- 30 Oct 2026

Reviewed: 251a1e0c | Since: b9854e5 | Review: save-review | Rota: R-save | Previous: docs/save-review-2026-10-07.md | Scope: scripts/save_game.gd, scripts/saving.gd, scripts/save_migrations.gd, scripts/save_slots.gd, scripts/tutorial_checkpoint.gd, tests/test_save_migrations.py, .claude/rules/saving.md

## Summary

- Findings by severity: 0 critical, 0 high, 0 medium, 0 low.
- Findings by disposition: 0 queued, 0 gated, 0 decide, 0 Jules task, 0 hand-off, 0 reject.
- Decisions for Dave: none.
- Unverified items: none.
- Save integrity and version ladder are clean at FORMAT_VERSION 7. 20 state fields added or modified since b9854e5 are all properly accounted for in writers and readers or re-derived on restore.

## Follow-through

| Previous finding | Now | Evidence | Proposed disposition |
| --- | --- | --- | --- |
| F1: Disease pressure not saved | Shipped | commit 1a9d9e94 (`saving.gd::131`) | Closed |
| F2: Crab spider preferred species not saved | Shipped | commit 1a9d9e94 (`saving.gd::121`) | Closed |
| F3: Rival colony state not saved | Shipped | commit 1a9d9e94 (`saving.gd::133`) | Closed |
| F4: Checkpoint soil rollback missing dug soil | Shipped | commit fe807135 (`saving.gd::201`) | Closed |
| F5: Non-atomic save/index writes | Shipped | commit 121183b3 (`save_slots.gd::38`) | Closed |
| F6: Day label season text update order | Shipped | 7 Oct 2026 (`saving.gd::122`) | Closed |
| F7: Save migration Python mirror drift | Shipped | 7 Oct 2026 (`tests/test_save_migrations.py::29`) | Closed |
| F8: bees_at_winter_start not saved | Rejected | COL-6 resolves winter in 1 step | Closed -- Rejected |
| F9: Outdated .claude/rules/saving.md rule | Shipped | 7 Oct 2026 (`.claude/rules/saving.md::1`) | Closed |

## State inventory

Count: 20 members added or modified since `b9854e5` (`git diff b9854e5..HEAD -- scripts/save_game.gd scripts/saving.gd scripts/save_migrations.gd`).

| Member / Field | System | Category | Status on Restore | Notes |
| --- | --- | --- | --- | --- |
| `hive.bodies` (`died_at`, `clear`) | Hive | Authoritative durable | Saved | T2-4b: dead bees on hive floor saved in `_bodies_data` and restored in `_restore_hive_state`. |
| `Session.crab_spider_preferred_species` | Session / Spiders | Authoritative durable | Saved | 1a9d9e94: saved under `session` dict, restored in `_restore`. |
| `Session.backup_order_default` | Session / Roles | Authoritative durable | Saved | WP-2: default backup order saved under `session` dict, restored in `_restore`. |
| `bee.tipsy_time_left` | Bees | Authoritative durable | Saved | NF-3: tipsy seconds saved on bee, restored in `_restore_bees`. |
| `bee.fermenting`, `bee.bee_bread_load` | Bees | Authoritative durable | Saved | BB-1: fermenting state and bee bread load saved on bee, restored in `_restore_bees`. |
| `bee.nurse_bee_bread` | Bees | Authoritative durable | Saved | BB-2: ripe bee bread carried by nurse saved on bee, restored in `_restore_bees`. |
| `bee.backup_order` | Bees | Authoritative durable | Saved | WP-2: ordered backup roles saved on bee, restored in `_restore_bees`. |
| `bee.brood_outcome` | Bees | Authoritative durable | Saved | BB-2: worker brood outcome saved on bee, restored in `_restore_bees`. |
| `cell.bee_bread_sealed_at` | Hive Cells | Authoritative durable | Saved | BB-1: seal timestamp saved on cell, restored in `_restore_cells`. |
| `cell.hatch_drone` | Hive Cells | Authoritative durable | Saved | DR-1: drone mark saved on cell, restored in `_restore_cells`. |
| `cell.priority_cell` | Hive Cells | Authoritative durable | Saved | PP-5: "Feed first" mark saved on cell, restored in `_restore_cells`. |
| `cell.pending_seal`, `cell.pending_open` | Hive Cells | Authoritative durable | Saved | RR-19: capping/uncapping orders saved on cell, restored in `_restore_cells`. |
| `flower.lifespan_seconds` | Meadow | Authoritative durable | Saved | PP-4: flower lifespan saved on flower, restored in `_restore_flowers`. |
| `flower.compatible_visits`, `flower.incompatible_visits`, `flower.award_ready_at` | Meadow | Authoritative durable | Saved | PP-1: pollination visit counters saved on flower, restored in `_restore_flowers`. |
| `first_crisis` dict | Weather / Run | Authoritative durable | Saved | FC-2: first crisis state saved under `first_crisis`, restored in `_restore`. Bumps `FORMAT_VERSION` to 7. |
| `short_term_goals` dict | Short-term Goals | Authoritative durable | Saved | SG-2: short term goals saved under `short_term_goals`, restored via `SaveGame.short_term_goals`. |
| `guidance` dict | Gallerin Panel | Authoritative durable | Saved | GD-2b: guidance policy state saved under `guidance`, restored in `_restore`. |
| `spring_regrowth_days` | GameConfig / Season | Temporary (`persist: "none"`) | Rebuilt / Default | COL-8: meadow regrowth duration setting in GameConfig. Documented as un-saved run tuning. |
| `Flower.regrowth_factor` | Meadow / Season | Derived | Rebuilt on tick | COL-8: re-derived every tick in `season.gd::_update_regrowth` from `Session.sim_time` and `Session.winter_ends_day`. |
| `winter_cost_multiplier` | Season / Skills | Derived | Rebuilt on restore | T2-8a: re-derived from purchased skills (`progression.gd`) on restore. |

## Findings

None. All 20 added or changed state members are cleanly handled. Save schema migrations (v1 through v7) and Python regression test mirror in `tests/test_save_migrations.py` are in full alignment and green.

## Recommendations

None.

## Decisions for Dave

None.

## Hands-on checks to file

None.

## Candidate Jules tasks

None.

## Hand-offs

None.

## Noted, not pursued

- `spring_regrowth_days` in `settings_catalogue.gd` is tagged `persist: "none"`, so it stays at the level's or GameConfig's default upon restore. This is intentional per COL-8 design.
- Additive fields without a `FORMAT_VERSION` bump (`bodies`, `backup_order`, `short_term_goals`, `guidance`, etc.) all provide safe fallback defaults when loading older save files.

## Not reviewed

- Godot GUI / hands-on play (verified headlessly via unit test suite).

## Patterns deliberately not applied

- Bumping `FORMAT_VERSION` for safe additive fields (Dave's decision, 7 Oct 2026).

## Method

- `git log --stat b9854e5..HEAD -- scripts/`
- `git diff b9854e5..HEAD -- scripts/save_game.gd scripts/saving.gd scripts/save_migrations.gd`
- `python -m unittest tests.test_save_migrations` (passed 43/43 tests)
- `python tests/source_checks.py` (passed)
- `python tests/balance_tests.py` (passed)
