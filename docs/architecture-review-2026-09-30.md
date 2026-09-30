# Architecture patterns review -- 30 Sep 2026

<!-- CONTEXT: review-record | LOAD: on-demand -->
Reviewed: c751f6a | Since: e61fc57 (23 Sep, the finished plan's archive commit) | Scope: everything this review owns, judged against the internal alpha (`plans/design/product-scope.md` §3, §6.1) and the Colony Run definition that comes after BS-4 | Previous: none as a record; first-run baseline `plans/archive/architecture-review_2026-09-24.md` and `docs/codebase-review-2026-09-18.md` §D, §E

## Follow-through

| Previous finding | Disposition |
| --- | --- |
| F1-F18 (24 Sep plan) | Shipped -- A1-A4, B1-B3, C1-C4, D1, E1, F1s, F2s, G1-G3, H1-H4; 16 re-checked in code this run |
| G3 follow-up: a skill purchase invalidates the availability cache | Shipped -- AP-4; all four ownership paths call `Availability.invalidate()` (`skill_tree_panel.gd`, `main.gd`, `save_game.gd`, `saving.gd`) |
| G3 follow-up: the queen's `role_restricted_to` becomes stage-named actions | Rejected -- Challenge 1 only, and already derived from the stage's own keys (`challenge_runner.gd::_queen_allowed_role_ids`); it goes with CH-2 |
| G3 follow-up: `feature` and `season` gate fields get a query | Rejected -- no alpha row needs one: winter grounds foragers through `bee_status.gd::grounded`, and a source check keeps both fields empty until a row does |
| D-1: make the pattern-per-category table explicit | Rejected -- CLAUDE.md rule 2 and `.claude/rules/simulation.md` already state it; the drift found this run (F3) came from a row lacking a field, which a table would not have prevented |
| D-2: `GOAL_CADENCE` beside the stage records (CH-3) | Rejected -- with CH-2: the second table costs something only for a new Challenge, or if the Colony Run reuses the runner (F1) |
| D-2: `HATCH_ROLES` in `hud.gd` | Shipped -- no longer in `hud.gd` |
| D-3: GDT-1, a GDScript test boot | Rejected -- test infrastructure is the verification review's lane; never queued since 18 Sep, handed off below |
| D-4: a role's starting count in six places | Queued -- BS-8 (F3 below) |
| E-1: CH-1, a Challenge is a level-record field | Decided -- folded into F1: the Colony Run definition owns run identity (Dave); `plans/design/product-scope.md` §6.2 |
| E-1: CH-2, stage-id branches become stage keys | Rejected -- all eight branches are Challenge 1's (`challenge_runner.gd::_enter_stage`); worth it when a third Challenge is designed, or with CH-1 if the pass reuses the runner |

## Findings

| Id | Finding | Evidence | Severity | Disposition |
| --- | --- | --- | --- | --- |
| F1 | A run's identity is an integer: compared 24 times, resolved 12 times and absent from the save, so a load rebuilds whichever level is current. The Colony Run adds a run type with its own policy, and the only goal runner is sequential and starts for levels 1 and 2 alone. | `grep -rnE '(starting_level\|challenge_id)\s*(==\|!=\|in)\s*(\[\|[0-9])' scripts/` (24; 17 in `challenge_runner.gd`); `grep -rn 'get_level(Session.starting_level)' scripts/` (12 live); `save_game.gd` writes no level; `main.gd::_ready` builds, then `saving.gd::_restore` replays | high | Decided -- Dave: the Colony Run definition owns it; `plans/design/product-scope.md` §6.2, "the run's identity" |
| F2 | Level 0 is never started, yet six starting settings (five shown under World & start) shape only its throwaway world, built when a fresh boot loads a save; every `levels.gd` row carries `win_conditions` and `unlocks`, which nothing reads | `world_building.gd::_spawn_starting_foragers`, `_spawn_hive_occupants` (GameConfig only when `level.is_empty()`); `main_menu.gd` offers levels 1-7; `main.gd::_apply_scenario_boot_arg` only defaults the two keys | medium | Decided -- Dave: the Colony Run definition settles both with the start state; the same §6.2 bullet |
| F3 | Role data outside `roles.gd`: which level key seeds a role is spelled in `run_availability.gd::SEED_COUNT_KEYS` and three other places. A gated role missing there is silently not seeded, and step 8 gates Comb worker and Miner, which levels 4-6 seed. Files per newly gated role 2 to 1; per newly seeded role 4 to 2. | `run_availability.gd::_seeded_skills`; `tools/godot_compile_check.py::FAILURE_PATTERNS` ignores `push_error`; `tests/source_checks.py::check_stage_role_skills` parses the table | high | Queued -- BS-8 in `plans/now/brood-spine.md`, Codex lane; its Proof holds |
| F4 | Both catalogue headers misstated what a new entry costs: `roles.gd` said "one entry below" (a role touches up to thirteen files); `resources.gd` said nothing reads its rows (B2 and B3 do), while `designatable` is read by nothing | `grep -rn designatable scripts/` finds only definitions; `hud.gd::_build_cell_group` builds the Reserve-for buttons by hand | medium | Fixed -- both headers now list what a new role or kind still touches |
| F5 | Dead code naming the wrong authority: `challenge_runner.gd::run_skill_grants`/`bans`/`delays` (policy goes through `run_availability.gd` since BS-1), `_brood_cell_count` (claimed to be the shared egg count; goals use `conditions.gd`), `bee.gd::nurse_mode_name` (a second, differing copy of the nurse mode labels) | a whole-repo name search (`scripts/`, `scenes/`, `tests/`, `tools/`, `test_scenarios/`) finds no caller | low | Fixed -- deleted, with the stale comments in `progression.gd` and `check_run_skill_policy`; source checks pass |
| F6 | A role's sub-mode is read and written through four role switches plus a save line per field; Bee Bread's Fermenter is the next mode | `bee.gd::_action_mode_for_role`, `role_name_text`; `hud.gd::_mode_is_active`; `orders_zones.gd::_apply_mode`; `save_game.gd` | low | Rejected -- one planned mode does not pay for an accessor, and Work Priorities (tier 3) redesigns per-bee job state; `_action_mode_for_role` is the seam, listed in `roles.gd`'s header |
| F7 | The cell popup's Reserve-for row is a hand-built copy of the unread `designatable` flag | `hud.gd::_build_cell_group`, `_apply_cell_popup_gating`, `_light_current_options`; `availability.gd::UI_GATES` | low | Rejected -- Bee Bread is the one planned new kind; its slice builds the row from the catalogue when it adds a sixth button, listed in `resources.gd`'s header |

## Hand-offs

- **Save review.** The save does not record `Session.starting_level`, so
  `saving.gd::_restore`'s re-grant of `RunAvailability.starting_skills` and
  its `in [1, 2]` checkpoint branch read whichever level is current, not the
  saved run's. Harmless while levels 3-7 share one policy; F1's pass owns
  the fix, which is a schema change.
- **Verification review.** A runtime `push_error` fails no headless run
  (`godot_compile_check.py::FAILURE_PATTERNS` matches script, parse, load and
  compile errors only). GDT-1 (`docs/codebase-review-2026-09-18.md` §4.2) was
  never queued. `tools/hook_log.py` line 87 puts a backslash in an f-string
  expression, a SyntaxError before Python 3.12: on this container's 3.11 the
  `.claude/settings.json` hooks log nothing and `DiagnosticWritersTest` fails
  8 tests, on master as on this branch.
- **Performance review.** `Availability.gate_epoch` is invalidated by a
  convention four callers keep by hand, with no source check; the hive stock
  cache has one (`check_hive_stock_epoch_cache`).
- **UI review.** `hud.gd::update_population` names four roles' counts (no
  miners). Resources use two palettes (`resources.gd`'s `colour`, and
  `hive_cell.gd`'s constants: nectar is amber in panels, pale blue in comb).

## Noted, not pursued

- 21 more functions have no caller. Most are deliberate extension points
  (the adaptation API in `adaptations.gd` and `progression.gd`, the grid
  helpers in `skills.gd`, `Availability.is_suppressed`/`resource_query`);
  the rest are a few lines each (`bee.gd::clear_build_queue`,
  `hive.gd::tile_is_interior`, `game_panel.gd::build_top_right_window`).
  `main_menu.gd::close` has no caller either.
- `hud.gd` is 3,450 lines (+124 since 23 Sep). `FUNCTION_MAP.md` keeps it
  navigable; its real cost is lane contention, which is the plan review's.
- `input_selection.gd` passed 700 lines with no section headers; the
  function map covers it.
- E-2's safeguards all stand: `check_stage_effects_order`,
  `check_goal_cadence_registry` and the generated `docs/challenge-stages.md`.

## Not reviewed

- A Godot boot: this container has neither Godot nor PowerShell, so
  `verify.ps1`'s Python stages were run directly.
- Save schema, presentation and per-frame cost, beyond the hand-offs above.
- Scene files, beyond a search for callers.

## Patterns deliberately not applied

The 24 Sep list still stands. Added this run:

- **More action catalogue.** `actions.gd`, `Availability.action_query` and
  `roles.gd`'s `skill` already gate work by role, skill, Challenge stage and
  config, which is Dave's standing idea. `season` and `feature` get a query
  when the first row needs one.
- **A per-bee mode accessor, or generic mode storage** (F6).
- **Catalogue-built hand lists** (F7): each list is a different subset
  (designatable, restockable, starting stock, forager loads), which Bee
  Bread's design settles.
- **One "changes over time" mechanism** for honey ripening and Bee Bread
  fermentation: fanning bees drive the first, the clock the second.
- **A predator or attacker base class**: one predator exists, and Guard bee,
  Combat and Nectar robbing each get their own design pass
  (`plans/design/progression.md` §11).
- **CH-1 to CH-3 before a third Challenge**, unless the Colony Run pass
  reuses the runner (F1).
- **Removing level 0 now**: it needs a save `FORMAT_VERSION` bump
  (`tests/source_checks.py::ORIGINAL_SAVED_SETTINGS`); the pass decides (F2).
- **A pattern table in a rules file** (D-1).
