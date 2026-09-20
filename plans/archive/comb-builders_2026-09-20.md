# Comb builders — at most six to a site, one to a wall

<!-- CONTEXT: plan | LAYER: immediate-task -->
Status: archived | Owner: Dave / Claude Code | Next: None — plan complete; C-46 (checks/ready/C-46.md) is ready to re-run | Dependency: none -- G2 shipped 17 Sep 2026 | Verified: 2026-09-20

**Objective.** When idle comb workers build on their own, no more than six
work one unfinished cell, each stands at a different wall, and a seventh
starts a second site.

**State.** HCB-4 set out to do exactly this. It merged on 12 Sep 2026 in
`3d475c7`, and its plan is archived at `plans/archive/HIVE_COMB_2026-09-12.md`,
which is never reopened. C-46 failed in Dave's 12 Sep 2026 pass: "the comb
workers do not position themselves around the six walls" and "more than 6 comb
workers contribute to building a single cell". This is the second visible
failure of builder placement, so the first slice builds the instrument rather
than guessing at a fix (`CLAUDE.md`, "Working style").

## Open slices at a glance

| Slice | Outcome | Files owned | Startable | Level |
| --- | --- | --- | --- | --- |

CB-2 depended on CB-1 and on **G2** (`plans/design/architecture-review.md`),
which rewrote `bee.gd`'s dispatch and the `bee_*.gd` modules CB-2's fix
edits. Both have shipped -- CB-1 on 19 Sep 2026, G2 on 17 Sep 2026 -- so CB-2
is startable and is queued in the Claude lane. Neither slice changes balance
values.

**`scripts/hive.gd` is not CB-2's to edit.** The Codex lane's PERF-1 owns it
while it measures `find_food_cell`, and no file may sit in both lanes. CB-2
may call `hive.nearest_walkable_point()` and `hive.tile_is_walkable()`, which
are already public and read-only; if the fix turns out to need a change
inside `hive.gd`, stop and escalate rather than taking the file.

CB-1 shipped 2026-09-19; its specification is `plans/archive/CB-1_2026-09-19.md`.

CB-2 shipped 2026-09-20; its specification is `plans/archive/CB-2_2026-09-20.md`.
