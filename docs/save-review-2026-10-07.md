# Save, restore and migration review -- 7 Oct 2026

<!-- CONTEXT: review-record | LOAD: on-demand -->
Reviewed: b9854e5 | Since: first run | Scope: everything the review owns -- `save_game.gd`, `saving.gd`, `save_migrations.gd`, `save_slots.gd`, `tutorial_checkpoint.gd` and Challenge 2's rollback, every system's durable state, `tests/test_save_migrations.py` | Previous: none

## Follow-through

None (first run).

## State inventory

Built from `save_game.gd::save`/`saving.gd::_restore`, each system's `var`
list (`grep -n "^var " scripts/<file>.gd`) and its writers. "Lost" means a
load resets it to a fresh-world value.

| System | Saved (authoritative) | Rebuilt or derived on restore | Lost or runtime-only |
| --- | --- | --- | --- |
| Run and clock | `sim_time`, `day`, `next_bee_id`, `first_gyne_seen`, `starting_level`, skill grants/bans, skills bought, `developer_changes` | `Session.year_has_winter` (from the level), starting-role skills (from the run definition), branch tiers | -- |
| Settings | `GameConfig` rows tagged `persist:"run"` | -- | `persist:"player"` stays with the player by design |
| Year and winter | `Session.winter_*`, `gynes_released` | season text | `season.disease` (F1); `season.bees_at_winter_start` (F8) |
| Weather | `rain_intensity`, `rain_target`, `rain_seconds_left` | -- | `weather_timer` (re-rolled; harmless) |
| Hive | every cell field, soil present/marked, `keep_clear`, `_tier_credit`, `_brood_pointer`, lifetime totals | content index, stock totals, A* graph and path cache, edge flags | entrance/dance mentor lists (runtime) |
| Bees | identity, caste, role, state, loads, nurse/forage memory, every player order (queues, homes, restock lists) | stats from trait (`_apply_stats`), cell and block refs by tile | movement, path, scout bout, dance and flower-handling state (re-derived from `state`); Challenge-only flags (Challenge 1 never restores) |
| Flowers | position, species, nectar, pollen, age | `flower_grid` | visit cooldowns |
| Fog of war | `explored` | lit counts (relit per bee id next frame) | mask textures |
| Colony milestones | `met_days` (load path) | goal shelf | -- |
| Crab spiders | -- | -- | `Session.crab_spider_preferred_species` (F2) |
| Rival colony | -- | rebuilt at starting size | `population`, stores, `alive` (F3) |
| Readout history | -- | -- | `foraging_stats`, `history_samples`, `emergence_log`, `day_store_totals` (hand-off) |
| Session UI state | -- | -- | `control_groups` carried over from the previous run (F2) |
| Challenge | checkpoint file = a full save | stage, gate and prompts stay live in `challenge_runner.gd` | save/load is disabled during a Challenge by design |
| Save catalogue | `index.json`: names, days, checkpoint rotation | slot list | -- |

`FORMAT_VERSION` is 6; `save_migrations.gd` bridges 1 to 6 in single steps,
and a newer save is refused. All versions the game has written are covered.

## Findings

| Id | Finding | Evidence | Severity | Disposition |
| --- | --- | --- | --- | --- |
| F1 | Disease pressure (on by default; slows brood, shortens lives) is not saved, so a load cures the colony | `season.gd::disease`, `_advance_disease`; `grep -c '"disease"' scripts/save_game.gd` is 0 | medium -- drift, every Colony Run | Queued -- SI-1 in plans/now/save-integrity.md (Dave chose additive fields with no version bump; written into `.claude/rules/saving.md`) |
| F2 | Crab-spider species is not saved, and the load path reloads the scene without `Session.reset_run_state()`, so the species and the control groups (bee ids) come from whatever run was played before | `session.gd::reset_run_state`, `saves_panel.gd::reload_from`, `crab_spider.gd` rolls only when `""` | low -- drift; spiders off by default | Queued -- SI-1 in plans/now/save-integrity.md |
| F3 | Rival colony state is not saved: a load rebuilds it at its starting size and revives a collapsed one | `rival_hive.gd` vars `population`..`alive`, `_collapse`; no `rival` key in `save_game.gd` | low -- drift; rival off by default | Queued -- SI-1 in plans/now/save-integrity.md |
| F4 | An in-place checkpoint restore removes soil the checkpoint lacks but never puts back soil dug since, so Challenge 2's rollback keeps the dig and stage 2.8's "dig new space" half already counts as met | `saving.gd::_restore_soil`; `challenge_runner.gd::_check_c2_failure` restore path; `_goal_check_miner_expansion` compares with `_c2_soil_blocks_at_stage_entry`, which the restore does not retake | medium -- drift, Challenge 2 outcome | Queued -- SI-2 in plans/now/save-integrity.md (Dave chose an exact rollback; written into `.claude/rules/saving.md`) |
| F5 | Saves, checkpoints and `index.json` are written in place with `FileAccess.WRITE` and an unchecked `store_string`; a crash or full disk leaves a half file, and a half index makes every run vanish from the Saves window although the files remain; `save()` reports success after a failed store | `save_game.gd::save`, `save_slots.gd::_write_index`, `_load_index_file` ("treating it as no saves") | medium -- loss, low probability | Queued -- SI-3 in plans/now/save-integrity.md |
| F6 | `_restore` drew the day label's season text before putting back the winter fields and `gynes_released`, so after a load it showed the previous run's season (for example "Winter, N days left") until the next day boundary | `saving.gd::_restore`; `year_winter.gd::_season_text` reads `Session.winter_here`; the only other caller is `day_changed` | low -- drift, UI readout | Fixed -- `update_day` moved below the session block; verified by `.\tools\verify.ps1` (boot included) |
| F7 | The migration tests' Python mirror still held `season_length_days: 60.0` after COL-4 made it 30, and passed, because it tested the mirror rather than the game | `tests/test_save_migrations.py::GAME_CONFIG_DEFAULTS`; `grep -n "var season_length_days" scripts/game_config.gd` | low -- recurring false assurance | Fixed -- the defaults are now read from `game_config.gd`, and a new test ties the key list to `save_migrations.gd::MIGRATED_SETTINGS_V5`; `python -m unittest tests.test_save_migrations` passes (36 tests) |
| F8 | `bees_at_winter_start` is not saved, so a load during a played winter ends it with "no losses" | `season.gd::_advance_winter`, `year_winter.gd::_on_winter_survived` | low -- drift, one message | Rejected -- COL-6 (queued, Claude lane) resolves winter in one step on arrival, so no save sits inside a played winter once it lands |
| F9 | `.claude/rules/saving.md` still said not to build a migration framework, beside the five-step one in `save_migrations.gd` | `.claude/rules/saving.md` first rule | low -- misleading rule, loads on every save edit | Fixed -- rule rewritten alongside Dave's two decisions |

## Hand-offs

- UI review: readout history (`foraging_stats`, the colony graphs'
  `history_samples`, `emergence_log`, `day_store_totals`) starts empty after a
  load. Whether the player should see it continue is a presentation call; if
  so, it comes back here as a schema question.
  Signal log: "2026-10-07 — readout history starts empty after every load".

## Noted, not pursued

- `_restore_soil` and `_restore_cells` use bare `queue_free()` rather than
  `_retire_node`; nothing queries those groups in the same frame today.
- The `restore_slot` scenario action does not put back colony milestones;
  test harness only.
- COL-4 changed `season_length_days` from "the whole year" to "the playable
  season". A save written before 6 Oct carries 60, so it now plays a 60-day
  season plus a recurring winter; consistent, and only Dave's own saves.
- Only v1 and v2 have JSON fixtures; v3 to v5 are tested as inline
  dictionaries. The GDScript steps are trivial and source-checked.

## Not reviewed

- `player_profile.gd` (player preferences, not run state).
- Headless runs: none were needed; every finding is read from code.

## Patterns deliberately not applied

- A `FORMAT_VERSION` bump for additive fields (Dave, 7 Oct 2026).
- Rebuilding `index.json` from a directory scan: SI-3's atomic writes remove
  the cause.
