# Gameplay systems consistency review (Jules) -- 04 Nov 2026

Reviewed: e8cc5401 | Since: 9c490df | Review: gameplay-review | Rota: R-gameplay | Previous: docs/gameplay-review-2026-10-15.md | Scope: follow-through of the 15 Oct record, then a sweep over gameplay systems changed since 9c490df (scripts/: bee.gd, hive_cell.gd, hive.gd, orders_zones.gd, season.gd, year_winter.gd, bee_nursery.gd, bee_building.gd, bee_survival.gd)

## Summary
- 3 prior findings evaluated from PR #55 and F2 of plans/reference/jules-review-2026-11-02.md: 0 queued, 0 gated, 0 decided, 3 rejected.
- 0 new decisions for Dave required: Dave resolved decision D2 on 2 Nov 2026 (plans/now/run-repairs.md), retaining current contracts.
- Dispositions:
  1. Queen backup nursing (BS-9) retention is an intentional contract, not an omission; rejected (plans/archive/brood-spine_2026-10-05.md, scripts/bee.gd:1855).
  2. Backup job dispatch is secondary-job search, not primary role change; no causal loss/overwrite reproduction; rejected.
  3. Inside-hive bee death food recovery is a gameplay design decision, not a Jules fix; rejected.
- Unverified: Hands-on Godot interactive play and UI drag operations (headless Linux VM environment).

## Follow-through

| Previous finding | Now | Evidence | Proposed disposition |
| --- | --- | --- | --- |
| F1 -- skipped winter ferments nectar and ripens sealed bee bread | Shipped | RR-9, commit 215d5c44 (`season.gd::_resolve_winter` shifts stamps; `tests/test_rr9_winter_ages_nothing.py`) | Shipped -- RR-9 |
| F2 -- fermented nectar buys skills | Shipped | RR-10, commit 1a865334 (`skill_tree_panel.gd` and `hive.gd::take` skip fermented cells; `tests/test_rr10_fermented_not_currency.py`) | Shipped -- RR-10 |
| F3 -- bee changing role keeps carrying_corpse | Shipped | T2-13, commit 23dc6c5e (`bee.gd::_apply_role` calls `_put_down_body()`; `tests/test_t2_13_carried_body.py`) | Shipped -- T2-13 |

## Findings

| Id | Finding | Evidence | Severity | Status | Proposed disposition |
| --- | --- | --- | --- | --- | --- |
| F1 | Queen's carried nurse food is not deposited on role change | `scripts/bee.gd::_return_nurse_food` | medium | verified | Reject -- documented BS-9 exception (`scripts/bee.gd:1855`); Dave D2 retained existing behaviour |
| F2 | Backup role dispatch retains cargo when taking a secondary job | `scripts/bee.gd::_dispatch_backup_list` | medium | suspected | Reject -- secondary job assignment does not change primary role; no causal loss/overwrite reproduction shown |
| F3 | Bee death inside hive does not return carried food to comb | `scripts/bee_survival.gd::die` | low | verified | Reject -- resource recovery is a gameplay design decision, not a defect; Dave D2 rejected changes |

## Recommendations
None.

## Decisions for Dave
None. Dave answered the relevant questions on 2 Nov 2026 (plans/reference/jules-review-2026-11-02.md, plans/now/run-repairs.md):
- D2: Retain current queen backup-nursing and death cargo outcomes. Require a causal reproduction of loss or overwrite before changing backup dispatch; the gameplay report's proposed cleanup alone is not defect evidence.

## Hands-on checks to file
None.

## Candidate Jules tasks
None.

## Hand-offs
None.

## Noted, not pursued
- Documented BS-9 queen nursing exception: `scripts/bee.gd:1855` explicitly notes: "The queen's backup nursing (BS-9) is left exactly as it was: she simply stops carrying it." Removing this check would alter colony resource totals and breach the BS-9 design contract.
- Primary role change vs secondary-job dispatch: `_apply_role` governs primary role transitions and cleanly calls `_deliver_held_load`, `_return_nurse_food`, `_return_bee_bread`, and `_put_down_body`. In contrast, `_dispatch_backup_list` temporarily checks secondary jobs without altering the primary `role`.
- `_return_bee_bread` role guard: in `scripts/bee.gd:1914`, `if bee_bread_load <= 0.0 or role == Role.HONEY_MAKER or hive == null: return`. A primary Honey Maker retains her bee bread load while working her primary role; returning it during secondary dispatch would disrupt honey making.
- Bee death cargo recovery: `scripts/bee_survival.gd::die` places the bee corpse inside the hive when dying indoors (`hive.add_body`), but carried food is deliberately dropped with the dead bee rather than automatically returned to stores. Changing this requires gameplay balance consideration.
- `year_winter.gd::begin_winter_countdown` reads the level's `"winter"` key from `starting_level` rather than `Session.year_has_winter`; they agree in current levels.
- `working_secondary` boolean on `bee.gd` is not serialized in `saving.gd`; on reload, bees re-assess idle dispatch cleanly.

## Not reviewed
- Hands-on Godot interactive play, UI drag and drop, and visual theme rendering (requires Godot display server).

## Patterns deliberately not applied
None.

## Method
```bash
python tools/review_due.py gameplay-review
git log --stat 9c490df..e8cc5401 -- scripts/
python tools/func.py scripts/bee.gd _return_nurse_food
python tools/func.py scripts/bee.gd _return_bee_bread
python tools/func.py scripts/bee.gd _dispatch_backup_list
python tools/func.py scripts/bee_survival.gd die
python tests/source_checks.py
python tools/check_docs.py
```
