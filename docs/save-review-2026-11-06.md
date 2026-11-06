# Save, restore and migration review -- 6 Nov 2026

<!-- CONTEXT: review-record | LOAD: on-demand -->
Reviewed: 11cb62c | Since: 251a1e0c | Scope: save writers and readers changed since 2 Nov (ED-1c, C-140 fix), state added to scripts since then, and the architecture review's hand-off on the director's event records | Previous: docs/save-review-2026-11-02.md

## Follow-through

| Previous finding | Disposition |
| --- | --- |
| S1 -- existing additive fields | Rejected -- unchanged; no implementation was owed |
| S2 -- PR #56 overstated runtime safety | Fixed -- the 2 Nov record kept only the qualified facts |
| S3 -- rival tick and flight continuation | Rejected -- Dave's 2 Nov D3 stands; no new evidence |

## Findings

| Id | Finding | Evidence | Severity | Disposition |
| --- | --- | --- | --- | --- |
| S1 | Where the director's later event records live in the save was undecided; the first EV slice would have chosen alone (architecture review hand-off, 4 Nov) | `save_game.gd` `"first_crisis"` key; `plans/design/event-director.md` decisions 12 and 15 | medium | Decided -- Dave, 6 Nov: one additive `director` key, records by id, `first_crisis` unchanged, no format bump; written as decision 16 in `plans/design/event-director.md`, and CQ-R2's row cites it |
| S2 | ED-1c's `health` per bee: authoritative, saved, additive, defaulted to full and clamped; restored after `setup()`, so `_ready`'s reset to capacity does not overwrite it | `git diff 251a1e0c..HEAD -- scripts/saving.gd` (`_restore_bees`, after `bee.setup`); `bee.gd::_ready`; `tests.test_save_migrations.BeeHealthSaveTest` | info | Rejected -- correct as built; no defect |
| S3 | C-140's `scenario_level` row: saved only in a scenario run (level 999), restored with whole numbers back to ints | `save_game.gd::save`, `::apply_starting_level`, `::_whole_numbers_as_ints` | info | Rejected -- correct as built; S1's restore reuses the same int conversion |

Inventory since `SINCE` (`git diff 251a1e0c..11cb62c -- scripts/ | grep -cE '^\+(static )?var '`: 49 member lines, most of them UI nodes): saved -- `bee.health`, `scenario_level`; derived and rebuilt -- `soil_block.is_hard` (from the hex and `GameConfig.hard_soil_start_fraction`); UI-only and lost on load -- the HUD goal shelf, `hud.select_n`, `hive_cell` label and glow fields, `colony_milestones.short_term_notes`; `GameConfig` health and rest values are settings.

## Hand-offs

None.

## Noted, not pursued

- `colony_milestones.short_term_notes` ("<goal> -- done" lines) is lost on load; it lasts only until the day ends.
- `soil_block.is_hard` is derived from a setting, so changing `hard_soil_start_fraction` mid-run re-hardens loaded soil; a developer setting only.

## Not reviewed

- Checkpoints and `save_slots.gd`: unchanged since `SINCE`.

## Patterns deliberately not applied

- No format bump or migration for the director (S1, Dave's choice).
- No headless round trip: the CQ-S0 goldens already carry `health` (`BeeHealthSaveTest`).
