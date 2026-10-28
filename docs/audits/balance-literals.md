# Audit: Balance literals outside GameConfig

Audited: 4517ae0b on 28 Oct 2026 | Task: J-35 | Scope: `scripts/` (.gd simulation files)

## Summary

Read 73 simulation `.gd` files in `scripts/` (excluding 30 UI/layout files).
Identified and classified non-trivial numeric literals (excluding 0, 1, -1, 2, and 0.5) used in simulation logic.
Found 5 key balance/tunable findings that should be moved to `GameConfig`, 4 unnamed structural constants, and catalogued inventory of named constants and non-magic numbers.

Key findings:
1. `main.gd:289`: `FIRST_CRISIS_RECOVERY_SECONDS := 120.0` is a balance value hardcoded in `main.gd` rather than in `GameConfig`.
2. `flower.gd:229`: `PRESENTATION_PER_SECOND := 6.0` is a simulation presentation rate constant defined as a literal in `flower.gd`.
3. `rival_hive.gd:31-43`: Rival colony balance thresholds (`FORAGER_SPEED`, `MIN_FORAGER_SHARE`, `MAX_FORAGER_SHARE`, `REBALANCE_STEP`, `COMFORTABLE_DAYS`) are `const` in `rival_hive.gd` instead of `GameConfig` fields.
4. `fog_of_war.gd:114`: `HIVE_OPEN_SPACE_REVEAL_BLOCKS := 1.8` reveal multiplier hardcoded as file `const`.
5. `main.gd:1026`: Rain target roll range `randf_range(0.35, 1.0)` uses bare magic numbers in rain weather updates.

## Findings

| # | Where (path:line) | What | Why it matters | Confidence | Fix |
|---|---|---|---|---|---|
| 1 | `main.gd:289` | `const FIRST_CRISIS_RECOVERY_SECONDS := 120.0` | Agent Rule 2 (`GameConfig` owns balance values). Hardcodes crisis recovery duration outside `GameConfig`. | High | Move `first_crisis_recovery_seconds` into `GameConfig` and `settings_catalogue.gd`. |
| 2 | `rival_hive.gd:32` | `const FORAGER_SPEED := 95.0` | Agent Rule 2. Rival forager movement speed is a balance tunable hardcoded as file constant. | High | Move `rival_forager_speed` into `GameConfig`. |
| 3 | `rival_hive.gd:43` | `const COMFORTABLE_DAYS := 90.0` | Agent Rule 2. Rival food cushion assessment days is a balance tunable hardcoded as file constant. | High | Move `rival_comfortable_days` into `GameConfig`. |
| 4 | `flower.gd:229` | `const PRESENTATION_PER_SECOND := 6.0` | Agent Rule 2. Flower readout presentation refresh rate is hardcoded as a file constant. | Medium | Move `flower_presentation_rate` into `GameConfig` or name as structural constant if non-tunable. |
| 5 | `main.gd:1026` | `randf_range(0.35, 1.0)` | Agent Rule 2. Bare magic number for minimum rain intensity roll in weather update. | High | Add `rain_min_intensity_roll` field to `GameConfig` or define as named const. |

## Candidate Jules tasks

### J-? -- Move rival hive simulation constants to GameConfig
Files: `scripts/game_config.gd`, `scripts/rival_hive.gd`, `scripts/settings_catalogue.gd`
After: none
Why: agent rule 2 -- `GameConfig` owns balance values. `rival_hive.gd` defines `FORAGER_SPEED` (95.0) and `COMFORTABLE_DAYS` (90.0) as local constants instead of `GameConfig` fields.
Do: Add `rival_forager_speed` and `rival_comfortable_days` to `GameConfig` and reference them in `rival_hive.gd`.

`python tools/jules_preflight.py scripts/game_config.gd scripts/rival_hive.gd scripts/settings_catalogue.gd`

## For Claude or Codex

- `main.gd`: `FIRST_CRISIS_RECOVERY_SECONDS := 120.0` — `plans/now/` (First crisis tuning)

## Inventory

| File | Line | Code | Classification | Notes |
|---|---|---|---|---|
| `main.gd` | 97 | `DEFAULT_RANDOM_SEED := 12345` | Structural constant | Default PRNG seed |
| `main.gd` | 100 | `WEATHER_ROLLS_PER_DAY := 6.0` | Structural constant | Daily weather step frequency |
| `main.gd` | 147 | `HIVE_WORLD_OFFSET := Vector2(20000, 0)` | Structural constant | World space interior offset |
| `main.gd` | 148 | `HIVE_INTERIOR_CENTRE := Vector2(20400, 280)` | Structural constant | Hive interior coordinate origin |
| `main.gd` | 160 | `FLOWER_FIELD_HALF_SIZE := Vector2(2000.0, 1500.0)` | Structural constant | Meadow dimensions |
| `main.gd` | 161 | `FLOWER_MIN_DISTANCE := 90.0` | Structural constant | Hive clearance for flowers |
| `main.gd` | 162 | `MAX_CLUSTERS_PER_SPECIES := 22` | Structural constant | Cluster generation limit |
| `main.gd` | 166 | `RAISED_AREA_COUNT := 4` | Structural constant | Raised area count |
| `main.gd` | 167 | `RAISED_AREA_RADIUS := Vector2(130.0, 240.0)` | Structural constant | Raised area dimensions |
| `main.gd` | 168 | `TREE_COUNT := 10` | Structural constant | Tree count |
| `main.gd` | 169 | `TREE_RADIUS := Vector2(22.0, 34.0)` | Structural constant | Tree dimensions |
| `main.gd` | 170 | `OBSTACLE_HIVE_CLEARANCE := 220.0` | Structural constant | Hive obstacle clearance |
| `main.gd` | 176 | `FLOWER_CLEARANCE := 30.0` | Structural constant | Flower clearance |
| `main.gd` | 177 | `HIVE_MARKER_POSITION := Vector2(620, 330)` | Structural constant | UI marker position |
| `main.gd` | 183 | `PAN_SPEED := 420.0` | Structural constant | Camera pan speed |
| `main.gd` | 184 | `MIN_ZOOM := 0.4` | Structural constant | Camera minimum zoom |
| `main.gd` | 185 | `MAX_ZOOM := 3.0` | Structural constant | Camera maximum zoom |
| `main.gd` | 259 | `SpatialGrid.new(200.0)` | Structural constant | Spatial grid bucket size |
| `main.gd` | 289 | `FIRST_CRISIS_RECOVERY_SECONDS := 120.0` | Balance value (finding 1) | Crisis recovery duration |
| `main.gd` | 383 | `DAY_STORE_SAMPLES := 8` | Structural constant | History store samples |
| `main.gd` | 906 | `FPS_WINDOW_USEC := 500000` | Structural constant | FPS calculation window |
| `main.gd` | 1026 | `randf_range(0.35, 1.0)` | Balance value (finding 5) | Rain min intensity roll |
| `flower.gd` | 229 | `PRESENTATION_PER_SECOND := 6.0` | Balance value / Structural const (finding 4) | Flower UI presentation update frequency |
| `rival_hive.gd` | 27 | `RUIN_TINT := Color(0.55, 0.55, 0.55)` | Structural constant | Visual color |
| `rival_hive.gd` | 31 | `SHOWN_FORAGERS := 8` | Structural constant | Max rendered rival foragers |
| `rival_hive.gd` | 32 | `FORAGER_SPEED := 95.0` | Balance value (finding 2) | Rival forager movement speed |
| `rival_hive.gd` | 36 | `MIN_FORAGER_SHARE := 0.45` | Structural constant | Minimum forager share bound |
| `rival_hive.gd` | 37 | `MAX_FORAGER_SHARE := 0.85` | Structural constant | Maximum forager share bound |
| `rival_hive.gd` | 41 | `REBALANCE_STEP := 0.05` | Structural constant | Rebalance rate step |
| `rival_hive.gd` | 42 | `SHORT_OF_FOOD_FACTOR := 0.75` | Structural constant | Short of food threshold factor |
| `rival_hive.gd` | 43 | `COMFORTABLE_DAYS := 90.0` | Balance value (finding 3) | Rival food reserve target days |
| `fog_of_war.gd` | 114 | `HIVE_OPEN_SPACE_REVEAL_BLOCKS := 1.8` | Structural constant | Interior reveal multiplier |
| `fog_of_war.gd` | 185 | `FOG_TILE_SIZE := 5.0` | Structural constant | Fog texture tile resolution |
| `fog_of_war.gd` | 192 | `WORLD_MARGIN := 400.0` | Structural constant | World fog margin |
| `fog_of_war.gd` | 197 | `RELIGHT_DISTANCE := 40.0` | Structural constant | Fog relight threshold |
| `fog_of_war.gd` | 201 | `START_CLEAR_RADIUS := 420.0` | Structural constant | Initial un-fogged radius |

## Method

1. Categorised `scripts/` files into UI/layout files (30 files, e.g., `hud.gd`, `colony_panel.gd`, `*_panel.gd`, `ui_*.gd`, `debug_panel.gd`) and simulation logic files (73 files).
2. Filtered code lines to ignore pure comments and excluded trivial numeric literals (`0`, `1`, `-1`, `2`, `0.5`).
3. Extracted remaining numeric literals used in rates, durations, chances, thresholds, capacities, costs, or distances.
4. Evaluated extracted literals against `GameConfig` ownership rules and classified them into balance tunables, structural constants, already named constants, or non-magic numbers.
