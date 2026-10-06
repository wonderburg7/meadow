# Gameplay consistency — a job change keeps the bee and her load, and honey stores energy without creating it

<!-- CONTEXT: plan | LAYER: immediate-task -->
Status: complete | Owner: Dave / Claude Code | Next: None -- plan complete; GC-3 delivered 6 Oct 2026 (nectar_per_honey 4.0, so honey stores energy without creating it), GC-4 delivered 2 Oct 2026, C-89 and C-90 passed 2 Oct 2026; follow-ups: none -- COL-4 (Codex lane, `plans/now/colony-run.md`) next edits the same two script files | Dependency: none | Verified: 2026-10-06

**Objective.** Three rules that the code breaks today hold again: an Idle bee
does what the Idle tooltip says, a change of job never loses what the bee is
carrying, and making honey follows `.claude/rules/simulation.md` ("must not
create energy"). Found by `docs/gameplay-review-2026-09-30.md` (F2 to F4),
each demonstrated in a headless run.

## Open slices at a glance

| Slice | Outcome from the player's seat | Files owned | Startable | Level |
| --- | --- | --- | --- | --- |

GC-1 and GC-2 are independent in behaviour but share `bee.gd`, so they run in
that order in one lane. GC-3 is independent of both. **Required reading:**
the slice's own section and the functions it names. **Must not change:** the
queen's behaviour anywhere (Challenge 1 owns her loads and her `IDLING`
freeze, `bee_foraging.gd::autonomous_state`); `bee_status.gd::works_indoors`
(winter grounding and the entrance read it); `scripts/roles.gd` (Codex lane,
BS-8); the save format.

GC-1 shipped 2026-10-01; its specification is `plans/archive/GC-1_2026-10-01.md`.

GC-2 shipped 2026-10-01; its specification is `plans/archive/GC-2_2026-10-01.md`.

GC-3 shipped 2026-10-06; its specification is `plans/archive/GC-3_2026-10-06.md`.
