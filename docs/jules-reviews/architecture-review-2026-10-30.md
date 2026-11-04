# Architecture patterns review (Jules) -- 30 Oct 2026

Reviewed: e8cc5401 | Since: 9c490df | Review: architecture-review | Rota: R-architecture | Previous: docs/architecture-review-2026-10-15.md | Scope: scripts/, project.godot, scenes/ (130 commits, 86 watched files)

## Summary

- Findings: 1 high, 2 medium, 2 low.
- Dispositions: 1 Gate, 1 Decide, 1 Hand-off, 2 Noted (positive patterns).
- Most significant findings:
  1. `bee.gd` and `hive.gd` hold uncalled queue management and tile query dead code (`clear_build_queue`, `clear_mine_queue`, `tile_is_interior`).
  2. Legacy adaptation selection helpers in `progression.gd` (`eligible_adaptation_ids`, `choose_adaptation`, `chosen_adaptation_ids`) and lookup helpers in `skills.gd` (`for_sector`, `ring_for_tier`) and `adaptations.gd` (`for_group`, `milestone_ids`) are uncalled observations but reserved under `plans/design/progression.md` and `plans/reference/jules.md`.
  3. `is_mastered` in `scripts/progression.gd` was an eligible uncalled deletion and was separately removed in the 2 Nov integration (PR #63).
  4. HUD command row extraction (`hud_command_rows.gd`) successfully reduced `hud.gd` complexity; input selection modularized (`input_selection.gd`).
  5. Canvas layer names centralized in `canvas_layers.gd` cleanly decouple HUD layering.
- Decisions for Dave: 1 (D1: Retaining reserved adaptation and skill APIs as resolved by Dave on 2 Nov 2026).
- Unverified items: None (all findings verified via AST/grep tools and source inspection).

## Follow-through

| Previous finding | Now | Evidence | Proposed disposition |
| --- | --- | --- | --- |
| F1 -- SG-2 missing facts sources | Shipped | SG-2 delivered in `plans/now/short-term-goals.md` | Shipped -- SG-2 |
| F2 -- Winter-ready definition scope | Decided | CR-2 milestone in `plans/now/short-term-goals.md` | Decided (D1) |
| F3 -- Conditions header inaccurate | Shipped | 9c490df | Shipped |
| F4 -- Guidance catalogue explanation fallback | Shipped | SG-3 delivered in `plans/now/short-term-goals.md` | Shipped -- SG-3 |
| F5 -- World & start settings dev_only | Decided | `scripts/settings_catalogue.gd` | Decided |

## Findings

| Id | Finding | Evidence | Severity | Status | Proposed disposition |
| --- | --- | --- | --- | --- | --- |
| F1 | `progression.gd`, `skills.gd`, and `adaptations.gd` retain uncalled query and selection helpers (`eligible_adaptation_ids`, `choose_adaptation`, `chosen_adaptation_ids`, `for_sector`, `ring_for_tier`, `for_group`, `milestone_ids`), while `is_mastered` was separately removed in the 2 Nov integration | `scripts/progression.gd:541`, `scripts/skills.gd:673`, `scripts/adaptations.gd:314`, `python tools/uncalled.py` | medium | verified | Decide (D1) |
| F2 | `bee.gd` and `hive.gd` hold uncalled helper functions (`clear_build_queue`, `clear_mine_queue`, `tile_is_interior`) | `scripts/bee.gd:2276`, `scripts/hive.gd:243`, `python tools/uncalled.py` | medium | verified | Hand-off -- code-health.md |
| F3 | Reserved adaptation/skill APIs require product decision rather than automatic removal | `plans/design/progression.md`, `plans/reference/jules.md` | high | verified | Gate -- progression (D1) |
| F4 | HUD command row and input selection extraction cleanly separates presentation components | `scripts/hud_command_rows.gd:1`, `scripts/input_selection.gd:1` | low | verified | Noted, not pursued |
| F5 | Canvas layer names centralized in `canvas_layers.gd` decouple layering without altering behaviour | `scripts/canvas_layers.gd:1` | low | verified | Noted, not pursued |

## Recommendations

None required (no Queue or Gate disposition rows requiring new plan sections; F3 is gated on resolved product decision D1).

## Decisions for Dave

### D1 -- Reserved adaptation and skill APIs in `progression.gd`, `skills.gd`, and `adaptations.gd`
- Question: Should the uncalled adaptation and skill helpers (`eligible_adaptation_ids`, `choose_adaptation`, `chosen_adaptation_ids`, `for_sector`, `ring_for_tier`, `for_group`, `milestone_ids`) be purged as dead code or retained for planned progression work?
- Options:
  1. Retain the reserved APIs until progression work resumes (`plans/design/progression.md` section 3).
  2. Purge uncalled helpers now.
- Dave's resolution (2 Nov 2026): Option 1 (Retain the reserved APIs; no broad removal from the Jules architecture report; `is_mastered` separately removed under #63).
- Findings waiting: F1, F3.
- File where answer is recorded: `plans/reference/jules-review-2026-11-02.md`, `plans/design/progression.md`.

## Hands-on checks to file

None.

## Candidate Jules tasks

None (reserved adaptation and skill APIs must not be deleted without product rework; uncalled functions in `bee.gd` and `hive.gd` belong to owned files in `plans/now/code-health.md`; positive extraction observations do not produce defect tasks; delivered task id J-43 is not reused).

## Hand-offs

- code-health.md: `bee.gd::clear_build_queue`, `bee.gd::clear_mine_queue`, and `hive.gd::tile_is_interior` uncalled observations for owned files.

## Noted, not pursued

- HUD command row modularization (`hud_command_rows.gd`) successfully reduced `hud.gd` complexity without breaking contracts.
- Input selection extraction (`input_selection.gd`) cleanly separated selection logic from UI rendering.
- Canvas layer centralization (`canvas_layers.gd`) cleanly organized node ordering.

## Not reviewed

- Godot headless execution and hands-on gameplay verification.

## Patterns deliberately not applied

- Converting `bee.gd` or `hive.gd` into full ECS components (monolithic design with functional script helpers continues to serve current performance and navigability needs).

## Method

- Ran `python tools/review_due.py architecture-review`.
- Ran `python tools/uncalled.py`.
- Checked path availability using `python tools/jules_preflight.py`.
