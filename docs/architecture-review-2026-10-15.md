# Architecture patterns review -- 15 Oct 2026

<!-- CONTEXT: review-record | LOAD: on-demand -->
Reviewed: 9c490df (8f59de0 adds no watched file) | Since: c751f6a | Scope: what changed in `scripts/` since 30 Sep (183 commits, 90 watched files), judged against the internal alpha's next slices: Work Priorities (WP-2, WP-3), short-term goals (SG-2, SG-3), difficulty (ED-1 to ED-3) and FC-2 | Previous: `docs/architecture-review-2026-09-30.md`

## Follow-through

| Previous finding | Disposition |
| --- | --- |
| F1 -- a run's identity is an integer, absent from the save | Shipped -- CR-1 saves `starting_level`; the Colony Run is a `levels.gd` row with `"run_type": "colony"` (colony-run plan decision 1, `plans/archive/colony-run_2026-10-08.md`) |
| F2 -- level 0 and its starting settings; unread level keys | Shipped -- in part: COL-5 removed `win_conditions` and `unlocks`. The level-0 half was left open by the Colony Run pass and archived with it: F5 below |
| F3 -- role seeding keys outside `roles.gd` | Shipped -- BS-8; `tests/source_checks.py` forbids `SEED_COUNT_KEYS` returning |
| F4 -- catalogue headers misstated a new entry's cost | Shipped -- both headers still hold; `resources.gd`'s lists Bee bread's hand lists |
| F5 -- dead code naming the wrong authority | Shipped -- none of the three names is back |
| F6 -- a role's sub-mode through four switches | Rejected -- stands; WP-2 redesigns per-bee job state |
| F7 -- Reserve-for row hand-built beside `designatable` | Rejected -- stands: BB-1 added the Bee bread button by hand, not from the catalogue as the record expected; no further cell kind is planned, and `resources.gd`'s header lists the row |

## Findings

| Id | Finding | Evidence | Severity | Disposition |
| --- | --- | --- | --- | --- |
| F1 | SG-2 leaves the source of its facts open, though decision 1 forbids a second evaluator and `conditions.gd` already owns built cells and nectar/pollen income. Gross honey income has no counter, and the only place to add one is outside SG-2's Files. The income window is not saved, and SG-1's `_trigger` reads a missing net as 0.0, so it would offer "Build a pollen surplus" with a zero reward after every load. | `conditions.gd::_net_income`, `_built_cell_count`; `main.gd::_sample_day_stores` (nectar and pollen only, "Not saved"); `hive.gd::record_collection`; `bee_honey.gd::honey_deposit`; `short_term_goals.gd::_trigger` (`.get("pollen", 0.0)`) | high | Gated -- SG-2 in `plans/now/short-term-goals.md`: Files gain `conditions.gd`, `hive.gd`, `bee_honey.gd`; "Where the facts come from" names each source and the missing-means-unknown rule; Proof re-run (absent) |
| F2 | "Winter-ready" already means one thing: `conditions.gd::_winter_ready` is true only on the countdown's last day. Used as is, "Lay in honey for winter" is offered for the whole countdown and can finish only on its last day. | `conditions.gd::_winter_ready` (`days_left > 1.0` returns false); `short_term_goals.gd::_trigger`, `progress` | medium | Decided -- `plans/now/short-term-goals.md`, SG-2 "Winter on track": Dave chose a new `winter_on_track` leaf in `conditions.gd`, true on any countdown day the comb holds what winter needs; the CR-2 milestone keeps `_winter_ready`'s last-day rule; SG-2's Check gains the case |
| F3 | `conditions.gd`'s header said nothing calls it; three systems do | `grep -rn "Conditions\.\(met\|progress\)" scripts/` | low | Fixed -- header names its three callers and says new colony-state rules are leaves there |
| F4 | `guidance_catalogue.gd::explanation` gives every id that is not the nurse fact the comb workforce's evidence; SG-3, a medium slice, adds Dr Gallerin lines to this file | `guidance_catalogue.gd::explanation` (`else:` branch) | low | Gated -- SG-3 in `plans/now/short-term-goals.md` now says the goal lines are their own table, not `ENTRIES` rows |
| F5 | Level 0 and five "World & start" settings (Starting cells, foragers, nurses, builders, honey makers) still shape only the throwaway world built before a load replays a save; no startable run reads them, yet they show in the settings window | `world_building.gd` (`level.is_empty()` fallbacks); `settings_catalogue.gd` "World & start" rows, none `dev_only`; `tests/source_checks.py::ORIGINAL_SAVED_SETTINGS` | medium | Decided -- `scripts/settings_catalogue.gd`: Dave chose to mark the five rows `dev_only` (shown only with Developer mode on), with a comment above the section giving the reason; they stay saved (`persist: run`), so `ORIGINAL_SAVED_SETTINGS` is unchanged |

## Hand-offs

None.

## Noted, not pursued

- `bee.gd` grew 2,413 to 3,019 lines (nuptial flights, the tipsy wander, Bee bread and drones live in it, not in `bee_*` modules); `hud.gd` 3,450 to 3,962. `FUNCTION_MAP.md` indexes both; WP-2, ED-1 and T2-10 each add to `bee.gd`. Lane contention is the plan review's.
- Uncalled functions: still 21. New: `pollination_pop.gd::active_count`. `roles.gd::tip_for` and `mode_tip` have no caller (readers use `entry.tip`).
- WP-2's "roles the run has not unlocked are skipped" already has its query: `Availability.role_query`.
- ED-1's crawl speed has one step site, `bee_movement.gd::move_towards`, beside the tipsy factor.
- ED-2's Easy rules become `Session` checks in four files: Easy is one bundle (difficulty decision 7, one checkbox), so a rules table would have one row.
- `plans/archive/crisis-readiness_2026-10-17.md` FC-2 says `colony_diagnostics.gd` is held by CD-3, while `NEXTSTEPS.md` says FC-2 waits only for GD-2b; FC-2 rechecks ownership itself.
- A new short-term goal touches four places in `short_term_goals.gd` (row, `_trigger`, `progress`, the whole-day list): one file, acceptable.

## Not reviewed

- A Godot boot: the code changes are a comment and five `"dev_only": true` keys in a constant table; `verify.ps1` covers them.
- World (weather, the year, winter die-back, seed set): changed since SINCE, but no next slice adds an instance there; one line only.
- Save schema, presentation and per-frame cost.

## Patterns deliberately not applied

The 24 Sep and 30 Sep lists still stand. Added this run:

- **One goal interface** for Challenge stages, milestones and short-term goals: three lifecycles (sequential, sticky, offered-dismissed-paid). They share `conditions.gd`'s leaves, which is the part worth sharing.
- **Rewriting SG-1's match blocks as `conditions.gd` specs**: SG-1's pure facts keep it unit-testable without a scene; reuse lives in the facts builder (F1).
- **A difficulty rules table, or Easy's rules as `GameConfig` keys**: one bundle, one checkbox.
- **Saving `day_store_totals`**: once a missing window means unknown (F1), nothing needs it; the save review owns the schema.
- **Splitting `bee.gd` further**: the function map keeps it navigable, and no next slice is blocked by its size.
