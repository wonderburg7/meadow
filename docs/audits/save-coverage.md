# Audit: save and restore coverage

Audited: 5d8fada2 on 31 Oct 2026 | Task: J-32 | Scope: scripts/*.gd

## Summary

Audited 12 scripts and 215 member variable declarations across saving.gd, save_game.gd and domain owner scripts.
Found 3 findings across medium and low severities.

Top findings:
1. `scripts/bee.gd:128`: Queen's `nuptial_flights` toggle and progress flags are neither saved nor restored.
2. `scripts/rival_hive.gd:61`: Rival hive's `tick_timer` phase offset is neither saved nor restored.
3. `scripts/bee.gd:424`: Partial coordinate fallback logic for `forage_start_point` restore in `saving.gd:435`.

## Findings

| # | Where (path:line) | What | Why it matters | Confidence | Fix |
|---|---|---|---|---|---|
| 1 | `scripts/bee.gd:128` | `nuptial_flights` (and `nuptial_phase`, `nuptial_flight_day`, `nuptial_flights_flown`) are neither saved in `save_game.gd::_bees_data` nor restored in `saving.gd::_restore_bees`. | `.claude/rules/saving.md`: player toggled state or active nuptial flight state is lost after reload. | High | Save `nuptial_flights`, `nuptial_phase`, `nuptial_flight_day`, and `nuptial_flights_flown` under `bees` dict in `save_game.gd` and restore in `saving.gd`. |
| 2 | `scripts/rival_hive.gd:61` | `tick_timer` phase offset is neither saved in `rival_hive.gd::save_data` nor restored in `rival_hive.gd::restore`. | `docs/known-pitfalls.md`: rival tick timer re-randomises on reload, shifting rival tick cadence. | High | Add `tick_timer` to `rival_hive.gd::save_data` and restore it in `rival_hive.gd::restore`. |
| 3 | `scripts/bee.gd:424` | `forage_start_point` restore in `saving.gd:435` reads `start_x` and `start_y` independently with `INF` fallbacks, allowing asymmetric Vector2 construction if only one key is present. | Defensive coding contract in `.claude/rules/saving.md`. | High | Guard coordinate extraction in `saving.gd::_restore_bees` to ensure both `x` and `y` are valid numbers before constructing Vector2. |

## Candidate Jules tasks

None. Save format additions or field restorations alter save structure/behaviour, so all fixes are assigned to Claude or Codex per rule.

## For Claude or Codex

- `scripts/bee.gd:128`, `set_nuptial_flights()`: Save and restore `nuptial_flights` state and flight counters (`plans/now/run-repairs.md`).
- `scripts/rival_hive.gd:61`, `save_data()` / `restore()`: Save and restore `tick_timer` phase offset (`plans/now/run-repairs.md`).
- `scripts/saving.gd:435`, `_restore_bees()`: Guard asymmetric `start_x`/`start_y` restore fallbacks (`plans/now/run-repairs.md`).

## Inventory

| Script | Line | Member Var | Saved Key | Restored Line | Classification / Reason |
|---|---|---|---|---|---|
| `scripts/main.gd` | 230 | `presentation_timer` | None | None | Presentation only (visual timer) |
| `scripts/main.gd` | 395 | `day` | `clock.day` | `saving.gd:68` | Saved & restored |
| `scripts/main.gd` | 396 | `next_bee_id` | `clock.next_bee_id` | `saving.gd:69` | Saved & restored |
| `scripts/main.gd` | 397 | `first_gyne_seen` | `clock.first_gyne_seen` | `saving.gd:70` | Saved & restored |
| `scripts/main.gd` | 400 | `rain_target` | `weather.target` | `saving.gd:74` | Saved & restored |
| `scripts/main.gd` | 401 | `rain_seconds_left` | `weather.seconds_left` | `saving.gd:75` | Saved & restored |
| `scripts/main.gd` | 404 | `first_crisis` | `first_crisis` | `saving.gd:137` | Saved & restored |
| `scripts/session.gd` | 30 | `sim_time` | `clock.sim_time` | `saving.gd:67` | Saved & restored |
| `scripts/session.gd` | 35 | `rain_intensity` | `weather.intensity` | `saving.gd:73` | Saved & restored |
| `scripts/session.gd` | 40 | `winter_coming` | `session.winter_coming` | `saving.gd:83` | Saved & restored |
| `scripts/session.gd` | 41 | `winter_starts_day` | `session.winter_starts_day` | `saving.gd:84` | Saved & restored |
| `scripts/session.gd` | 42 | `winter_here` | `session.winter_here` | `saving.gd:85` | Saved & restored |
| `scripts/session.gd` | 43 | `winter_ends_day` | `session.winter_ends_day` | `saving.gd:86` | Saved & restored |
| `scripts/session.gd` | 45 | `gynes_released` | `session.gynes_released` | `saving.gd:87` | Saved & restored |
| `scripts/session.gd` | 48 | `crab_spider_preferred_species` | `session.crab_spider_species` | `saving.gd:88` | Saved & restored |
| `scripts/session.gd` | 52 | `backup_order_default` | `session.backup_order_default` | `saving.gd:90` | Saved & restored |
| `scripts/hive.gd` | 40 | `lifetime_nectar_collected` | `totals.nectar` | `saving.gd:78` | Saved & restored |
| `scripts/hive.gd` | 41 | `lifetime_pollen_collected` | `totals.pollen` | `saving.gd:79` | Saved & restored |
| `scripts/hive.gd` | 42 | `lifetime_births` | `totals.births` | `saving.gd:80` | Saved & restored |
| `scripts/hive.gd` | 45 | `lifetime_honey_made` | None | `saving.gd:124` | Derived/restarted window (reset on restore) |
| `scripts/hive.gd` | 50 | `keep_clear_tiles` | `hive.keep_clear` | `saving.gd:279` | Saved & restored |
| `scripts/hive.gd` | 52 | `_tier_credit` | `hive.tier_credit` | `saving.gd:283` | Saved & restored |
| `scripts/hive.gd` | 54 | `_brood_pointer` | `hive.brood_pointer` | `saving.gd:284` | Saved & restored |
| `scripts/hive.gd` | 58 | `bodies` | `hive.bodies` | `saving.gd:289` | Saved & restored |
| `scripts/hive_cell.gd` | 40 | `content_type` | `cells[].content` | `saving.gd:212` | Saved & restored |
| `scripts/hive_cell.gd` | 41 | `amount` | `cells[].amount` | `saving.gd:213` | Saved & restored |
| `scripts/hive_cell.gd` | 42 | `designated_type` | `cells[].designated` | `saving.gd:214` | Saved & restored |
| `scripts/hive_cell.gd` | 43 | `designation_is_explicit` | `cells[].designation_explicit` | `saving.gd:215` | Saved & restored |
| `scripts/hive_cell.gd` | 44 | `keep_empty` | `cells[].keep_empty` | `saving.gd:216` | Saved & restored |
| `scripts/hive_cell.gd` | 45 | `evict_requested` | `cells[].evict` | `saving.gd:217` | Saved & restored |
| `scripts/hive_cell.gd` | 46 | `evict_mode` | `cells[].evict_mode` | `saving.gd:218` | Saved & restored |
| `scripts/hive_cell.gd` | 47 | `is_built` | `cells[].built` | `saving.gd:219` | Saved & restored |
| `scripts/hive_cell.gd` | 48 | `build_progress` | `cells[].build_progress` | `saving.gd:220` | Saved & restored |
| `scripts/hive_cell.gd` | 49 | `brood_progress` | `cells[].brood_progress` | `saving.gd:221` | Saved & restored |
| `scripts/hive_cell.gd` | 50 | `brood_fed_seconds` | `cells[].brood_fed` | `saving.gd:222` | Saved & restored |
| `scripts/hive_cell.gd` | 51 | `unfed_seconds` | `cells[].unfed` | `saving.gd:223` | Saved & restored |
| `scripts/hive_cell.gd` | 52 | `brood_is_gyne` | `cells[].gyne` | `saving.gd:224` | Saved & restored |
| `scripts/hive_cell.gd` | 53 | `brood_is_drone` | `cells[].drone` | `saving.gd:227` | Saved & restored |
| `scripts/hive_cell.gd` | 55 | `brood_food` | `cells[].brood_food` | `saving.gd:231` | Saved & restored |
| `scripts/hive_cell.gd` | 57 | `clean_progress` | `cells[].clean` | `saving.gd:232` | Saved & restored |
| `scripts/hive_cell.gd` | 58 | `ripen_progress` | `cells[].ripen` | `saving.gd:233` | Saved & restored |
| `scripts/hive_cell.gd` | 60 | `nectar_since` | `cells[].nectar_since` | `saving.gd:238` | Saved & restored |
| `scripts/hive_cell.gd` | 62 | `bee_bread_sealed_at` | `cells[].bee_bread_sealed_at` | `saving.gd:243` | Saved & restored |
| `scripts/hive_cell.gd` | 64 | `hatch_role` | `cells[].hatch_role` | `saving.gd:245` | Saved & restored |
| `scripts/hive_cell.gd` | 65 | `hatch_focus` | `cells[].hatch_focus` | `saving.gd:246` | Saved & restored |
| `scripts/hive_cell.gd` | 66 | `hatch_automine` | `cells[].hatch_automine` | `saving.gd:247` | Saved & restored |
| `scripts/hive_cell.gd` | 67 | `hatch_role_locked` | `cells[].hatch_locked` | `saving.gd:248` | Saved & restored |
| `scripts/hive_cell.gd` | 68 | `hatch_gyne` | `cells[].hatch_gyne` | `saving.gd:255` | Saved & restored |
| `scripts/hive_cell.gd` | 69 | `hatch_drone` | `cells[].hatch_drone` | `saving.gd:256` | Saved & restored |
| `scripts/hive_cell.gd` | 71 | `priority_cell` | `cells[].priority_cell` | `saving.gd:258` | Saved & restored |
| `scripts/hive_cell.gd` | 72 | `nursery_priority` | `cells[].priority` | `saving.gd:259` | Saved & restored |
| `scripts/hive_cell.gd` | 73 | `is_closed` | `cells[].closed` | `saving.gd:260` | Saved & restored |
| `scripts/hive_cell.gd` | 74 | `fill_then_close` | `cells[].fill_close` | `saving.gd:261` | Saved & restored |
| `scripts/soil_block.gd` | 25 | `marked_for_mining` | `soil.marked[].marked` | `saving.gd:178` | Saved & restored |
| `scripts/soil_block.gd` | 26 | `mine_progress` | `soil.marked[].progress` | `saving.gd:177` | Saved & restored |
| `scripts/flower.gd` | 35 | `nectar_amount` | `flowers[].nectar` | `saving.gd:341` | Saved & restored |
| `scripts/flower.gd` | 36 | `pollen_amount` | `flowers[].pollen` | `saving.gd:342` | Saved & restored |
| `scripts/flower.gd` | 37 | `age_seconds` | `flowers[].age` | `saving.gd:343` | Saved & restored |
| `scripts/flower.gd` | 40 | `lifespan_seconds` | `flowers[].lifespan` | `saving.gd:346` | Saved & restored |
| `scripts/flower.gd` | 42 | `compatible_visits` | `flowers[].compatible` | `saving.gd:348` | Saved & restored |
| `scripts/flower.gd` | 43 | `incompatible_visits` | `flowers[].incompatible` | `saving.gd:349` | Saved & restored |
| `scripts/flower.gd` | 44 | `award_ready_at` | `flowers[].award_ready_at` | `saving.gd:350` | Saved & restored |
| `scripts/bee.gd` | 89 | `role` | `bees[].role` | `saving.gd:378` | Saved & restored |
| `scripts/bee.gd` | 90 | `state` | `bees[].state` | `saving.gd:395` | Saved & restored |
| `scripts/bee.gd` | 96 | `is_queen` | `bees[].queen` | `saving.gd:362` | Saved & restored |
| `scripts/bee.gd` | 104 | `is_gyne` | `bees[].gyne` | `saving.gd:363` | Saved & restored |
| `scripts/bee.gd` | 110 | `is_drone` | `bees[].drone` | `saving.gd:368` | Saved & restored |
| `scripts/bee.gd` | 120 | `is_mated` | `bees[].mated` | `saving.gd:369` | Saved & restored |
| `scripts/bee.gd` | 128 | `nuptial_flights` | None | None | Finding #1: Neither saved nor restored |
| `scripts/bee.gd` | 133 | `nuptial_phase` | None | None | Finding #1: Neither saved nor restored |
| `scripts/bee.gd` | 137 | `nuptial_flight_day` | None | None | Finding #1: Neither saved nor restored |
| `scripts/bee.gd` | 139 | `nuptial_flights_flown` | None | None | Finding #1: Neither saved nor restored |
| `scripts/bee.gd` | 153 | `nurse_mode` | `bees[].nurse_mode` | `saving.gd:408` | Saved & restored |
| `scripts/bee.gd` | 156 | `nurse_jelly` | `bees[].nurse_jelly` | `saving.gd:406` | Saved & restored |
| `scripts/bee.gd` | 160 | `resource_type` | `bees[].resource` | `saving.gd:378` | Saved & restored |
| `scripts/bee.gd` | 161 | `current_load` | `bees[].load` | `saving.gd:398` | Saved & restored |
| `scripts/bee.gd` | 162 | `current_load_type` | `bees[].load_type` | `saving.gd:399` | Saved & restored |
| `scripts/bee.gd` | 164 | `bee_id` | `bees[].id` | `saving.gd:378` | Saved & restored |
| `scripts/bee.gd` | 172 | `bee_name` | `bees[].name` | `saving.gd:385` | Saved & restored |
| `scripts/bee.gd` | 173 | `bee_fact` | `bees[].fact` | `saving.gd:393` | Saved & restored |
| `scripts/bee.gd` | 174 | `trait_stat` | `bees[].trait_stat` | `saving.gd:386` | Saved & restored |
| `scripts/bee.gd` | 175 | `trait_percent` | `bees[].trait_pct` | `saving.gd:387` | Saved & restored |
| `scripts/bee.gd` | 184 | `brood_outcome` | `bees[].brood_outcome` | `saving.gd:392` | Saved & restored |
| `scripts/bee.gd` | 188 | `is_favourite` | `bees[].favourite` | `saving.gd:394` | Saved & restored |
| `scripts/bee.gd` | 195 | `energy` | `bees[].energy` | `saving.gd:396` | Saved & restored |
| `scripts/bee.gd` | 207 | `age_seconds` | `bees[].age` | `saving.gd:397` | Saved & restored |
| `scripts/bee.gd` | 217 | `move_target` | None | `saving.gd:437` | Unsaved: forager heads for start point |
| `scripts/bee.gd` | 253 | `automine` | `bees[].automine` | `saving.gd:410` | Saved & restored |
| `scripts/bee.gd` | 258 | `architect_mode` | `bees[].architect_mode` | `saving.gd:409` | Saved & restored |
| `scripts/bee.gd` | 271 | `finish_task_first` | `bees[].finish_first` | `saving.gd:422` | Saved & restored |
| `scripts/bee.gd` | 272 | `pending_role` | `bees[].pending_role` | `saving.gd:423` | Saved & restored |
| `scripts/bee.gd` | 273 | `dirt_load` | `bees[].dirt` | `saving.gd:403` | Saved & restored |
| `scripts/bee.gd` | 274 | `pollen_eaten` | `bees[].pollen_eaten` | `saving.gd:404` | Saved & restored |
| `scripts/bee.gd` | 278 | `honey_load` | `bees[].honey_load` | `saving.gd:400` | Saved & restored |
| `scripts/bee.gd` | 283 | `fermenting` | `bees[].fermenting` | `saving.gd:401` | Saved & restored |
| `scripts/bee.gd` | 284 | `bee_bread_load` | `bees[].bee_bread_load` | `saving.gd:402` | Saved & restored |
| `scripts/bee.gd` | 296 | `nurse_pollen` | `bees[].nurse_pollen` | `saving.gd:405` | Saved & restored |
| `scripts/bee.gd` | 297 | `nurse_carb` | `bees[].nurse_carb` | `saving.gd:405` | Saved & restored |
| `scripts/bee.gd` | 298 | `nurse_carb_type` | `bees[].nurse_carb_type` | `saving.gd:405` | Saved & restored |
| `scripts/bee.gd` | 301 | `nurse_bee_bread` | `bees[].nurse_bee_bread` | `saving.gd:407` | Saved & restored |
| `scripts/bee.gd` | 327 | `secondary_role` | `bees[].secondary` | `saving.gd:411` | Saved & restored |
| `scripts/bee.gd` | 363 | `backup_order` | `bees[].backup_order` | `saving.gd:419` | Saved & restored |
| `scripts/bee.gd` | 418 | `preferred_species` | `bees[].preferred` | `saving.gd:424` | Saved & restored |
| `scripts/bee.gd` | 424 | `forage_start_point` | `bees[].start_x/start_y` | `saving.gd:435` | Finding #3: Partial key fallback logic |
| `scripts/bee.gd` | 438 | `local_search_anchor` | `bees[].search_anchor_x/y` | `saving.gd:443` | Saved & restored |
| `scripts/bee.gd` | 492 | `known_patches` | `bees[].known_patches` | `saving.gd:453` | Saved & restored |
| `scripts/bee.gd` | 500 | `species_experience` | `bees[].species_experience` | `saving.gd:458` | Saved & restored |
| `scripts/bee.gd` | 509 | `species_confidence` | `bees[].species_confidence` | `saving.gd:459` | Saved & restored |
| `scripts/bee.gd` | 550 | `avg_collection_rate` | `bees[].avg_collection_rate` | `saving.gd:464` | Saved & restored |
| `scripts/bee.gd` | 558 | `grace_rate_sum` | `bees[].grace_rate_sum` | `saving.gd:465` | Saved & restored |
| `scripts/bee.gd` | 571 | `trips_scored` | `bees[].trips_scored` | `saving.gd:466` | Saved & restored |
| `scripts/bee.gd` | 648 | `tipsy_time_left` | `bees[].tipsy` | `saving.gd:398` | Saved & restored |
| `scripts/bee.gd` | 664 | `manual_build_hex` | `bees[].build_queue[0]` | `saving.gd:472` | Re-derived from build_queue on restore |
| `scripts/bee.gd` | 669 | `build_queue` | `bees[].build_queue` | `saving.gd:469` | Saved & restored |
| `scripts/bee.gd` | 671 | `mine_queue` | `bees[].mine_queue` | `saving.gd:473` | Saved & restored |
| `scripts/bee.gd` | 677 | `home_hex` | `bees[].home_hex` | `saving.gd:476` | Saved & restored |
| `scripts/bee.gd` | 681 | `mine_home_hex` | `bees[].mine_home` | `saving.gd:479` | Saved & restored |
| `scripts/bee.gd` | 2130 | `restock_targets` | `bees[].restock_targets` | `saving.gd:483` | Saved & restored |
| `scripts/bee.gd` | 2131 | `restock_resource` | `bees[].restock_resource` | `saving.gd:482` | Saved & restored |
| `scripts/bee.gd` | 2133 | `restock_sources` | `bees[].restock_sources` | `saving.gd:484` | Saved & restored |
| `scripts/bee.gd` | 2134 | `restock_blocked` | `bees[].restock_blocked` | `saving.gd:485` | Saved & restored |
| `scripts/rival_hive.gd` | 49 | `population` | `rival.population` | `rival_hive.gd:113` | Saved & restored |
| `scripts/rival_hive.gd` | 50 | `nectar` | `rival.nectar` | `rival_hive.gd:114` | Saved & restored |
| `scripts/rival_hive.gd` | 51 | `pollen` | `rival.pollen` | `rival_hive.gd:115` | Saved & restored |
| `scripts/rival_hive.gd` | 52 | `brood` | `rival.brood` | `rival_hive.gd:116` | Saved & restored |
| `scripts/rival_hive.gd` | 53 | `forager_share` | `rival.forager_share` | `rival_hive.gd:117` | Saved & restored |
| `scripts/rival_hive.gd` | 54 | `alive` | `rival.alive` | `rival_hive.gd:118` | Saved & restored |
| `scripts/rival_hive.gd` | 61 | `tick_timer` | None | None | Finding #2: Neither saved nor restored |
| `scripts/fog_of_war.gd` | 123 | `explored` | `fog` | `fog_of_war.gd:683` | Saved & restored |
| `scripts/guidance_policy.gd` | 8 | `facts` | `guidance.shown` | `guidance_policy.gd:50` | Saved & restored |
| `scripts/guidance_policy.gd` | 9 | `_shown` | `guidance.shown` | `guidance_policy.gd:51` | Saved & restored |
| `scripts/guidance_policy.gd` | 10 | `_order` | `guidance.order` | `guidance_policy.gd:60` | Saved & restored |
| `scripts/colony_milestones.gd` | 120 | `met_days` | `colony_milestones` | `colony_milestones.gd:192` | Saved & restored |
| `scripts/colony_milestones.gd` | 123 | `genetic_points` | `colony_milestones` | `colony_milestones.gd:200` | Saved & restored |
| `scripts/colony_milestones.gd` | 126 | `favourites` | `colony_milestones` | `colony_milestones.gd:223` | Saved & restored |
| `scripts/pollination.gd` | 73 | `points` | `pollination.points` | `pollination.gd:254` | Saved & restored |
| `scripts/pollination.gd` | 74 | `contribution` | `pollination.contribution` | `pollination.gd:255` | Saved & restored |
| `scripts/pollination.gd` | 76 | `seed_counts` | `seed_bank.seed_counts` | `pollination.gd:278` | Saved & restored |
| `scripts/pollination.gd` | 79 | `spring_counts` | `seed_bank.spring_counts` | `pollination.gd:279` | Saved & restored |
| `scripts/pollination.gd` | 80 | `spring_of` | `seed_bank.spring_of` | `pollination.gd:280` | Saved & restored |
| `scripts/pollination.gd` | 83 | `gaps` | `pollination.gaps` | `pollination.gd:281` | Saved & restored |

## Method

1. Listed member variables in target scripts (`scripts/main.gd`, `scripts/session.gd`, `scripts/hive.gd`, `scripts/hive_cell.gd`, `scripts/soil_block.gd`, `scripts/flower.gd`, `scripts/bee.gd`, `scripts/rival_hive.gd`, `scripts/fog_of_war.gd`, `scripts/guidance_policy.gd`, `scripts/colony_milestones.gd`, `scripts/pollination.gd`) via AST pattern search.
2. Cross-referenced save logic in `scripts/save_game.gd` and owner `save_data` methods against restore logic in `scripts/saving.gd` and owner `restore` methods.
3. Classified each member variable by saved key, restore line, or reason for exclusion (cache, derived state, or presentation only).
4. Validated findings against `.claude/rules/saving.md` and `docs/known-pitfalls.md`.
