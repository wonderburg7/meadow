# Gameplay systems consistency review (Jules) -- 30 Oct 2026

Reviewed: 251a1e0c | Since: 9c490df | Review: gameplay-review | Rota: R-gameplay | Previous: docs/gameplay-review-2026-10-15.md | Scope: follow-through of the 15 Oct record, then a sweep over gameplay systems changed since 9c490df (scripts/ directory: bee, hive_cell, hive, orders_zones, season, year_winter, bee_nursery, bee_building)

## Summary
- 3 verified findings: 2 medium, 1 low severity; 0 decisions for Dave required.
- 3 proposed for Queue (plans/now/run-repairs.md) / candidate Jules tasks.
- Top 3 issues:
  1. Queen's carried nurse food (pollen/nectar/jelly) is destroyed on role transition instead of being returned to colony stores.
  2. Backup role dispatch (_dispatch_backup_list) fails to clear held corpse or nurse food when taking up a secondary job.
  3. BeeSurvival.die does not return carried nurse food or bee bread when a bee dies inside the hive.
- Unverified: Hands-on Godot play and interactive UI drag operations (Jules VM environment).

## Follow-through

| Previous finding | Now | Evidence | Proposed disposition |
| --- | --- | --- | --- |
| F1 -- skipped winter ferments nectar and ripens sealed bee bread | Shipped | RR-9, commit 878ec982 (`season.gd::_resolve_winter` shifts cell stamps) | Shipped -- RR-9 |
| F2 -- fermented nectar buys skills | Shipped | RR-10 & RR-11, commit 6634ad1f (`skill_tree_panel.gd` and `hive.gd::take` skip fermented cells) | Shipped -- RR-10 |
| F3 -- bee changing role keeps carrying_corpse | Shipped | T2-13, commit d597ab4f (`bee.gd::_apply_role` calls `_put_down_body()`) | Shipped -- T2-13 |

## Findings

| Id | Finding | Evidence | Severity | Status | Proposed disposition |
| --- | --- | --- | --- | --- | --- |
| F1 | Queen's carried nurse food is destroyed on role transition instead of being returned to colony stores | `scripts/bee.gd::_return_nurse_food` | medium | verified | Queue -- plans/now/run-repairs.md (R1) |
| F2 | Backup role dispatch fails to clear held corpse or nurse food when a bee takes up a secondary job | `scripts/bee.gd::_dispatch_backup_list` | medium | verified | Queue -- plans/now/run-repairs.md (R2) |
| F3 | BeeSurvival.die does not return carried nurse food or bee bread when a bee dies inside the hive | `scripts/bee_survival.gd::die` | low | verified | Queue -- plans/now/run-repairs.md (R3) |

## Recommendations

### R1 -- Queen's nurse food returned to comb on role transition (F1)
- Plan: plans/now/run-repairs.md
- Files: scripts/bee.gd
- Reasoning: low, isolated return logic fix in `_return_nurse_food`
- True now: `_return_nurse_food()` guards resource deposits with `if not is_queen and hive != null:`, wiping pollen, nectar and jelly carried by a queen performing backup nurse duties when her role changes.
- Do:
  1. In `scripts/bee.gd::func _return_nurse_food()`, change `if not is_queen and hive != null:` to `if hive != null:` so that the queen deposits carried nurse food back into comb cells when switching off the Nurse role.
- True afterwards: A queen leaving the Nurse role returns carried pollen, nectar and jelly to comb cells rather than destroying them.
- Must not change: Save format, `GameConfig` values.
- Check: `python -m unittest tests.test_bee`
- Proof: `present: scripts/bee.gd :: if not is_queen and hive != null:`
- Stop and escalate if: Queen egg laying is interrupted by returning nurse food.
- Open decisions: none

### R2 -- Backup role dispatch resets carried corpse and nurse food (F2)
- Plan: plans/now/run-repairs.md
- Files: scripts/bee.gd
- Reasoning: low, reset state before taking secondary job
- True now: `_dispatch_backup_list()` assigns a secondary job without calling `_put_down_body()`, `_return_nurse_food()`, or `_return_bee_bread()`, leaving carried corpses or brood food on bees working secondary roles.
- Do:
  1. In `scripts/bee.gd::func _dispatch_backup_list()`, invoke `_put_down_body()`, `_return_nurse_food()`, and `_return_bee_bread()` before trying secondary roles.
- True afterwards: Taking a secondary job cleanly returns carried brood food and puts down carried corpses.
- Must not change: `working_secondary` dispatch order or priorities.
- Check: `python -m unittest tests.test_bee`
- Proof: `absent: scripts/bee.gd :: _dispatch_backup_list`
- Stop and escalate if: Secondary role search loop triggers infinite role switching.
- Open decisions: none

### R3 -- Death inside hive deposits carried nurse food and bee bread to comb (F3)
- Plan: plans/now/run-repairs.md
- Files: scripts/bee_survival.gd
- Reasoning: low, add return calls on bee death
- True now: `BeeSurvival.die()` places the bee's body inside the hive but does not invoke `_return_nurse_food()` or `_return_bee_bread()`, losing carried food items.
- Do:
  1. In `scripts/bee_survival.gd::func die()`, call `bee._return_nurse_food()` and `bee._return_bee_bread()` if the bee is inside the hive before logging death.
- True afterwards: A nurse or worker dying indoors deposits carried nurse food and bee bread back into comb cells.
- Must not change: Death body placement or death log structure.
- Check: `python -m unittest tests.test_bee`
- Proof: `absent: scripts/bee_survival.gd :: _return_nurse_food`
- Stop and escalate if: Dying bee resurrects or throws on missing hive reference.
- Open decisions: none

## Decisions for Dave
None.

## Hands-on checks to file
None.

## Candidate Jules tasks

### J-? -- Return queen nurse food on role transition
Files: scripts/bee.gd
After: J-38
Why: Queen acting as backup nurse loses carried pollen, nectar and jelly on role transition because `_return_nurse_food()` skips queens.
Do: Remove `not is_queen` check from `_return_nurse_food()` in `scripts/bee.gd`.

### J-? -- Clear carried items in backup role dispatch
Files: scripts/bee.gd
After: J-38
Why: Bees taking a secondary job retain carried corpses or nurse food because `_dispatch_backup_list()` does not clear carried items.
Do: Add `_put_down_body()`, `_return_nurse_food()`, and `_return_bee_bread()` calls inside `_dispatch_backup_list()` in `scripts/bee.gd`.

## Hand-offs
None.

## Noted, not pursued
- `year_winter.gd::begin_winter_countdown` reads the level's `"winter"` key from `starting_level` rather than `Session.year_has_winter`; they agree in current levels.
- `working_secondary` boolean on `bee.gd` is not serialized in `saving.gd`; on reload, bees re-assess idle dispatch cleanly.

## Not reviewed
- Hands-on Godot interactive play, UI drag and drop, and visual theme rendering (requires Godot display server).

## Patterns deliberately not applied
None.

## Method
```bash
python tools/review_due.py gameplay-review
git log --stat 9c490df..HEAD -- scripts/
grep -rn "_apply_role" scripts/
grep -rn "is_on_screen" scripts/
python tests/source_checks.py
python tools/check_docs.py
```
