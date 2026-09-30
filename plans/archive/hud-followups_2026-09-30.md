# HUD follow-ups — Dave's 28 Sep 2026 pass

<!-- CONTEXT: plan | LAYER: immediate-task -->
Status: complete | Owner: Dave / Claude Code | Next: None — plan complete; follow-up: C-57 (checks/ready/C-57.md) -- HF-6's fixture found Pollen at 2.2 on every headless route, so Dave's re-check names the route it missed | Dependency: none | Verified: 2026-09-30

**Objective.** Fix what Dave's 28 Sep 2026 hands-on batch found wrong or
awkward in the HUD, each as a small slice a low- or medium-level model can
finish without deciding anything. Every decision below was taken with Dave
in the session that processed the batch (28 Sep 2026).

**State.** Fifteen checks passed that day and are archived. C-60 failed
outright and C-57 half-failed; both corrected checks wait in
`checks/blocked.md` for HF-1 and HF-6. The rest are Dave's requests from the
same run. `plans/archive/saves-access_2026-09-30.md` (SA-1) and
`plans/now/skill-screen.md` (SK-1) hold the two larger requests, and
`plans/archive/hive-readouts_2026-09-29.md` (HR-1 to HR-3) the hive-view clicks and readouts.

## Open slices at a glance

| Slice | Outcome from the player's seat | Files owned | Startable | Level |
| --- | --- | --- | --- | --- |

**Dependencies.** None between slices; several share `hud.gd`,
`scenario_actions.gd` or `year_winter.gd` (as do HR-1 and HR-2 in
`plans/archive/hive-readouts_2026-09-29.md`), so they run one at a time in the Claude lane. **Required reading:** the slice's own section below, then only
the functions it names. **Do not change** `UiLayout.panel_chrome()`'s
result (HF-1) or any left window's rectangle (HF-4 adds one, moves none).

HF-1 shipped 2026-09-30; its specification is `plans/archive/HF-1_2026-09-30.md`.

HF-2 shipped 2026-09-30; its specification is `plans/archive/HF-2_2026-09-30.md`.

HF-3 shipped 2026-09-30; its specification is `plans/archive/HF-3_2026-09-30.md`.

HF-4 shipped 2026-09-30; its specification is `plans/archive/HF-4_2026-09-30.md`.

HF-5 shipped 2026-09-30; its specification is `plans/archive/HF-5_2026-09-30.md`.

HF-6 shipped 2026-09-30; its specification is `plans/archive/HF-6_2026-09-30.md`.
