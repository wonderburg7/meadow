# Architecture patterns review (Jules) -- 04 Nov 2026

Reviewed: 8dc78d36 | Since: 9c490df | Review: architecture-review | Rota: R-architecture | Previous: docs/architecture-review-2026-10-15.md | Scope: scripts/, project.godot, scenes/ (142 commits, 86 watched files)

## Summary

- Findings: 0 high, 2 medium, 1 low.
- Dispositions: 1 Decide, 1 Hand-off, 1 Candidate Jules task.
- Most significant findings:
  1. `bee.gd` and `hive.gd` retain uncalled queue management and tile query dead code (`clear_build_queue`, `clear_mine_queue`, `tile_is_interior`).
  2. Legacy adaptation selection helpers (`eligible_adaptation_ids`, `choose_adaptation`, `chosen_adaptation_ids`) in `progression.gd` remain uncalled; Dave's decision D1 (2 Nov 2026) resolved to retain reserved adaptation/skill APIs until progression work resumes.
  3. `skills.gd` and `adaptations.gd` contain uncalled lookup helpers (`for_sector`, `ring_for_tier`, `for_group`, `milestone_ids`), also reserved under D1 and `plans/design/progression.md`.
- Decisions for Dave: 1 (re-confirming D1 progression API retention timeline vs active queue priorities).
- Unverified items: Godot display server headless boot, UI layout measurements, interactive mouse/keyboard navigation.

## Follow-through

| Previous finding | Now | Evidence | Proposed disposition |
| --- | --- | --- | --- |
| F1 -- SG-2 missing facts sources | Shipped | SG-2 merged in 5aab5264 (`scripts/conditions.gd`, `plans/archive/short-term-goals_2026-11-01.md`) | Shipped -- SG-2 |
| F2 -- Winter-ready definition scope | Shipped | SG-2 merged in 5aab5264 (`conditions.gd::winter_on_track`) | Shipped -- SG-2 |
| F3 -- Conditions header inaccurate | Shipped | 9c490df (`scripts/conditions.gd:1`) | Shipped |
| F4 -- Guidance catalogue explanation fallback | Shipped | SG-3 merged in 7dc5d6fd (`scripts/hud_goal_shelf.gd`) | Shipped -- SG-3 |
| F5 -- World & start settings dev_only | Shipped | `scripts/settings_catalogue.gd:12` | Shipped |

## Findings

| Id | Finding | Evidence | Severity | Status | Proposed disposition |
| --- | --- | --- | --- | --- | --- |
| F1 | `bee.gd` and `hive.gd` hold 3 uncalled functions (`clear_build_queue`, `clear_mine_queue`, `tile_is_interior`) | `scripts/bee.gd:2276`, `scripts/bee.gd:2312`, `scripts/hive.gd:243`, `python tools/uncalled.py` | medium | verified | Hand-off -- code-health.md |
| F2 | `progression.gd`, `skills.gd`, and `adaptations.gd` retain 7 uncalled functions (`eligible_adaptation_ids`, `choose_adaptation`, `chosen_adaptation_ids`, `for_sector`, `sector_label`, `ring_for_tier`, `for_group`, `milestone_ids`) reserved under D1 | `scripts/progression.gd:541`, `scripts/skills.gd:673`, `scripts/adaptations.gd:314`, `python tools/uncalled.py` | medium | verified | Decide (D1) |
| F3 | `hud_goal_shelf.gd` and `hud_command_rows.gd` extraction successfully decoupled HUD sub-panels from `hud.gd` | `scripts/hud_goal_shelf.gd:1`, `scripts/hud_command_rows.gd:1`, `git log --stat -n 1 393c0d66` | low | verified | Reject -- architectural improvement already delivered |

## Recommendations

None required. (No Queue or Gate rows requiring slice extraction).

## Decisions for Dave

### D1 -- Planned adaptation/skill APIs retention
- Question: Should the uncalled adaptation/skill query helpers (`eligible_adaptation_ids`, `choose_adaptation`, `chosen_adaptation_ids`, `for_sector`, `sector_label`, `ring_for_tier`, `for_group`, `milestone_ids`) remain in the codebase until progression work resumes, or be removed with git history preserving them?
- Options:
  1. Retain as reserved APIs per decision D1 of 2 Nov 2026 and `plans/design/progression.md` (Cost: 7 uncalled functions remain flagged by `tools/uncalled.py`).
  2. Purge uncalled helpers from source (Cost: will need re-addition when adaptation selection slice is scheduled).
- Recommendation: Option 1 (retain as decided by Dave on 2 Nov 2026).
- Findings waiting: F2.
- File for answer: `plans/design/progression.md`, section 3.

## Hands-on checks to file

None.

## Candidate Jules tasks

None. (No behaviour-preserving tasks that meet all file availability and reservation rules: `bee.gd` and `hive.gd` are owned by active plans, and adaptation/skill functions are reserved under D1).

## Hand-offs

- code-health.md: `bee.gd::clear_build_queue`, `bee.gd::clear_mine_queue`, and `hive.gd::tile_is_interior` uncalled helper evaluation (files currently owned by active slices in `plans/now/`).

## Noted, not pursued

- `hud_command_rows.gd` and `hud_goal_shelf.gd` extractions: cleanly divided the monolithic HUD into smaller helper scripts while keeping scene bindings working.
- `input_selection.gd`: drag and pan state cleanly encapsulated from `main.gd`.
- `canvas_layers.gd`: centralized layer numbering avoids magic numbers across UI nodes.

## Not reviewed

- Godot headless execution and hands-on gameplay verification.

## Patterns deliberately not applied

The 15 Oct 2026 list still stands:
- **One goal interface** for Challenge stages, milestones and short-term goals.
- **Rewriting SG-1's match blocks as `conditions.gd` specs**.
- **A difficulty rules table, or Easy's rules as `GameConfig` keys**.
- **Saving `day_store_totals`**.
- **Splitting `bee.gd` further**.
- **Converting `bee.gd` or `hive.gd` into full ECS components**: functional script helpers continue to serve current performance and navigability needs without ECS indirection overhead.

## Method

```bash
python tools/review_due.py architecture-review
python tools/uncalled.py
git log --stat 9c490df..HEAD -- scripts/ project.godot scenes/
python tools/jules_preflight.py scripts/bee.gd scripts/hive.gd scripts/progression.gd scripts/skills.gd scripts/adaptations.gd
python tools/check_docs.py
```
