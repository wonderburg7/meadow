# Settings window and corner HUD -- findings from the 1 Oct 2026 hands-on pass

<!-- CONTEXT: plan | LAYER: immediate-task -->
Status: complete | Owner: Dave / Claude Code | Next: nothing further -- SC-4 landed, awaiting its hands-on check | Dependency: SC-2 follows UT-1 and UT-3 (`plans/now/ui-texture-polish.md`, `scripts/ui_theme.gd`); SC-4 follows SR-4 in the Claude lane (SR-4 moved there by Dave, 2 Oct 2026; both edit `scripts/hud.gd`) and runs before UT-4 | Verified: 2026-10-03

**Objective.** Four defects seen while running C-69 to C-73 by computer use on
1 Oct 2026 are fixed: C-72 failed once in three runs, cycling the typeface
logs an engine error, the project boots with GDScript warnings, and the
top-left corner overlaps itself and the left windows. Presentation only --
nothing here changes simulation (`plans/archive/ui_2026-09-20.md`, "Durable
rules"). The owning HUD plan, `plans/archive/hud-followups_2026-09-30.md`, is
archived, so these start a fresh plan (`plans/README.md`, "Plan schema").

| Slice | Files | Level | Lane | Startable | Depends on |
| --- | --- | --- | --- | --- | --- |

**Neighbouring plan.** `plans/now/ui-texture-polish.md` (UT-1 to UT-5) came
from the same day's pass over C-57 to C-68 and shares two files: UT-1 and
UT-3 edit `scripts/ui_theme.gd` (SC-2 goes after them) and UT-4 edits
`scripts/hud.gd` (SC-4 and UT-4 run one after the other, either order).

A slice reads its own section and nothing else. Not planned: the hive view
swapping the last top-bar icon (it shows the view the button switches to,
which reads as intended), and C-60/C-71, which UT-1 now owns (Dave, 2 Oct 2026).

SC-1 shipped 2026-10-02; its specification is `plans/archive/SC-1_2026-10-02.md`.

SC-2 shipped 2026-10-02; its specification is `plans/archive/SC-2_2026-10-02.md`.

SC-3 shipped 2026-10-02; its specification is `plans/archive/SC-3_2026-10-02.md`.

SC-4 shipped 2026-10-03; its specification is `plans/archive/SC-4_2026-10-03.md`.
