# Comb builders — at most six to a site, one to a wall

<!-- CONTEXT: plan | LAYER: immediate-task -->
Status: active | Owner: Dave / Claude Code | Next: CB-2 -- the H1 fix (builders bunch: stand points overlap), waiting on G2 | Dependency: none | Verified: 2026-09-17

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
| CB-2 | The fix CB-1's numbers point to; C-46 passes | decided by CB-1 | no -- its cause is not yet known, and its files wait on G2 | decided by CB-1 |

CB-2 depends on CB-1, and also on the Codex lane's **G2**
(`plans/design/architecture-review.md`), which is rewriting `bee.gd`'s
dispatch and touches the `bee_*.gd` modules CB-2's fix would edit. Neither
slice changes balance values.

CB-1 shipped 2026-09-19; its specification is `plans/archive/CB-1_2026-09-19.md`.

## CB-2 — the fix CB-1 identifies

**CB-1 result (2026-09-19, fixture `cb1_comb_builders_per_site_test.json`,
seed 4242, 12 comb workers on Building, one day, 200 samples, identical over
two runs).** `max_builders_per_site` 6 (pass), `building_without_slot` 0
(pass), `min_builder_spacing_px` 11.47 against the 13.6 needed (fail).
The numbers support **H1**: the slot cap holds and nobody builds without a
slot, but two builders at one site stand closer than 0.8 of a cell size apart,
which matches builders bunching rather than ringing the six walls. H2 is not
supported. H3 is not separated by these numbers. CB-1 did not record the
snapped stand points themselves, so CB-2 starts by confirming the snap
(`hive.nearest_walkable_point()` on each `slot_position`) is what merges them.

CB-2 is the H1 fix; startable once G2 has merged. Fixed now:

- **Invariants.**
  - CB-1's assertions pass.
  - One builder still contributes the same build progress per second.
  - The six-slot cap for depositing and feeding is unchanged.
  - A site with a free wall is still found by `find_unfinished_cell()`.
- **Guidance, not decisions.**
  - For H1: give each slot a reachable stand point of its own (snap each wall
    to a distinct walkable point), rather than letting every approach snap to
    one tile.
  - For H2: `builder_build()` requires `target_cell.slot_users.has(bee)` and
    otherwise sends the bee back to `TO_BUILD_SITE`.
- **Hot path.** `builder_build()` runs for every building bee every frame.
  Count the calls and the builder population before adding any check
  (`.claude/rules/performance.md`). A scan of six slots is acceptable; an
  allocation is not.
- **Save/load.** Read `.claude/rules/saving.md` first. A restored run must not
  leave a `BUILDING` bee without a slot.
- **Sequencing.** Do not start until G2 has merged: it is sole owner of
  `bee.gd` and reshapes the `bee_*.gd` signatures this fix would edit.
- **Completion.** Move C-46 from `checks/blocked.md` back to ready. Archive
  this plan with `Next: None — plan complete`.
