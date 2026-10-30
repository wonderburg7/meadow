# Architecture patterns review (Jules) -- 30 Oct 2026

Reviewed: e76d6be | Since: 9c490df | Review: architecture-review | Rota: R-architecture | Previous: docs/architecture-review-2026-10-15.md | Scope: scripts/, project.godot, scenes/ (107 commits, 82 watched files)

## Summary

- Findings: 1 high, 2 medium, 2 low.
- Dispositions: 1 Gate, 1 Decide, 1 Jules task, 2 Hand-off.
- Most significant findings:
  1. `bee.gd` and `hive.gd` hold uncalled queue management and tile query dead code (`clear_build_queue`, `clear_mine_queue`, `tile_is_interior`).
  2. `progression.gd` retains unused adaptation selection and mastery helpers (`is_mastered`, `eligible_adaptation_ids`, `choose_adaptation`, `chosen_adaptation_ids`).
  3. `skills.gd` and `adaptations.gd` contain uncalled lookup helpers (`for_sector`, `ring_for_tier`, `for_group`, `milestone_ids`).
  4. HUD command row extraction (`hud_command_rows.gd`) successfully reduced `hud.gd` complexity; input selection modularized (`input_selection.gd`).
  5. Visual builders split improved maintainability across visual components.
- Decisions for Dave: 1 (D1: Purging unused legacy adaptation/mastery functions in `progression.gd`).
- Unverified items: None (all findings verified via AST/grep tools and code inspection).

## Follow-through

| Previous finding | Now | Evidence | Proposed disposition |
| --- | --- | --- | --- |
| F1 -- SG-2 missing facts sources | Still queued | SG-2 in `plans/now/short-term-goals.md` | Gate -- SG-2 |
| F2 -- Winter-ready definition scope | Decided | CR-2 milestone in `plans/now/short-term-goals.md` | Decided (D1) |
| F3 -- Conditions header inaccurate | Shipped | 9c490df | Shipped |
| F4 -- Guidance catalogue explanation fallback | Still queued | SG-3 in `plans/now/short-term-goals.md` | Gate -- SG-3 |
| F5 -- World & start settings dev_only | Decided | `scripts/settings_catalogue.gd` | Decided |

## Findings

| Id | Finding | Evidence | Severity | Status | Proposed disposition |
| --- | --- | --- | --- | --- | --- |
| F1 | `progression.gd` contains 4 dead functions for legacy adaptation selection (`is_mastered`, `eligible_adaptation_ids`, `choose_adaptation`, `chosen_adaptation_ids`) | `scripts/progression.gd:149`, `python tools/uncalled.py` | medium | verified | Jules task (T1) |
| F2 | `skills.gd` and `adaptations.gd` retain 4 uncalled query helpers (`for_sector`, `ring_for_tier`, `for_group`, `milestone_ids`) | `scripts/skills.gd:673`, `scripts/adaptations.gd:314`, `python tools/uncalled.py` | low | verified | Jules task (T2) |
| F3 | `bee.gd` and `hive.gd` hold dead functions (`clear_build_queue`, `clear_mine_queue`, `tile_is_interior`) | `scripts/bee.gd:2255`, `scripts/hive.gd:243`, `python tools/uncalled.py` | medium | verified | Hand-off -- code-health.md |
| F4 | Legacy adaptation selection logic in `progression.gd` needs Dave's decision on whether future adaptation systems will re-use this interface | `scripts/progression.gd:545` | high | verified | Decide (D1) |
| F5 | Canvas layer names centralized in `canvas_layers.gd` cleanly decouple HUD layering | `scripts/canvas_layers.gd:1` | low | verified | Hand-off -- ui-review |

## Recommendations

None required (no Queue or Gate disposition rows requiring new plan sections).

## Decisions for Dave

### D1 -- Legacy adaptation API in `progression.gd`
- Question: Should the uncalled adaptation helpers (`eligible_adaptation_ids`, `choose_adaptation`, `chosen_adaptation_ids`) in `progression.gd` be purged or retained for future adaptation rework?
- Options:
  1. Purge now (reduces dead code in `progression.gd`).
  2. Keep as placeholder API for upcoming adaptation features.
- Recommendation: Option 1 (Purge now; version control preserves historical implementation if needed).
- Findings waiting: F4.
- File for answer: `plans/now/code-health.md`.

## Hands-on checks to file

None.

## Candidate Jules tasks

### J-43 -- Remove dead adaptation and skill lookup helpers in progression.gd and skills.gd
Files: `scripts/progression.gd`, `scripts/skills.gd`, `scripts/adaptations.gd`
After: J-30
Why: `python tools/uncalled.py` identifies 8 uncalled functions across `progression.gd`, `skills.gd`, and `adaptations.gd` that have no callers or references in the project.
Do:
1. Remove `is_mastered`, `eligible_adaptation_ids`, `choose_adaptation`, and `chosen_adaptation_ids` from `scripts/progression.gd`.
2. Remove `for_sector` and `ring_for_tier` from `scripts/skills.gd`.
3. Remove `for_group` and `milestone_ids` from `scripts/adaptations.gd`.
4. Run `python tools/uncalled.py` and `python tests/source_checks.py`.

`python tools/jules_preflight.py scripts/progression.gd scripts/skills.gd scripts/adaptations.gd` output:
free  scripts/progression.gd
free  scripts/skills.gd
free  scripts/adaptations.gd

## Hand-offs

- code-health.md: `bee.gd::clear_build_queue`, `bee.gd::clear_mine_queue`, and `hive.gd::tile_is_interior` dead code cleanup (owned files).
- ui-review: `canvas_layers.gd` centralization evaluation.

## Noted, not pursued

- `hud.gd` modularization (`hud_command_rows.gd`) successfully reduced file complexity without breaking contracts.
- `input_selection.gd` decomposition cleanly separated selection logic from UI rendering.

## Not reviewed

- Godot headless execution and hands-on gameplay verification.

## Patterns deliberately not applied

- Converting `bee.gd` or `hive.gd` into full ECS components (monolithic design with functional script helpers continues to serve current performance and navigability needs).

## Method

- Ran `python tools/review_due.py architecture-review`.
- Ran `python tools/uncalled.py`.
- Checked path availability using `python tools/jules_preflight.py`.
