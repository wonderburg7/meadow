# Hive readouts — Dave's 28 Sep 2026 pass

<!-- CONTEXT: plan | LAYER: immediate-task -->
Status: active | Owner: Dave / Claude Code | Next: HR-3 -- a bee waiting for room says it is waiting, startable, its block below | Dependency: none | Verified: 2026-09-28

**Objective.** Make the hive view say what it shows and answer the clicks a
player naturally tries, from Dave's 28 Sep 2026 hands-on batch. Decisions
were taken with Dave in that session.

**State.** Nothing built yet. The sibling HUD fixes from the same batch are
in `plans/now/hud-followups.md`.

## Open slices at a glance

| Slice | Outcome from the player's seat | Files owned | Startable | Level |
| --- | --- | --- | --- | --- |
| HR-3 | A bee waiting for room says it is waiting | `scripts/bee.gd` | yes | low |

**Dependencies.** None; HR-1 and HR-2 share `input_selection.gd`, so they
run one at a time. **Required reading:** the slice's own section, then only
the functions it names. **Do not change** any simulation behaviour: HR-3 is
words only.

HR-1 shipped 2026-09-29; its specification is `plans/archive/HR-1_2026-09-29.md`.

HR-2 shipped 2026-09-29; its specification is `plans/archive/HR-2_2026-09-29.md`.

## HR-3 — a bee waiting for room says it is waiting

Level: low. Dave saw bees standing still in the hive whose Now line read
"Carrying [resource] to a cell". **Cause, confirmed in code:**
`bee_foraging.gd::go_to_deposit_cell` deliberately keeps a bee in
`IN_HIVE_TO_CELL`, holding her load, when `hive.find_cell_for` finds no cell
with room (or no cell is built), and `bee.gd::task_description` prints
"carrying %s to a cell" for that state whatever the target. Behaviour is
right; the words are not. In `task_description`'s `IN_HIVE_TO_CELL` case,
when `target_cell` is null or invalid, return "waiting with %s: no cell has
room for it" (or "waiting with %s until the first cell is built" when
`hive.cells` is empty). No simulation change.

**Acceptance (check filed at closeout).** A bee standing still with a load
because the comb is full reads "waiting ... no cell has room for it".

```queue
**[Claude] HR-3 -- a bee waiting for room says it is waiting**
- Plan: `plans/now/hive-readouts.md` -- "HR-3 — a bee waiting for room says it is waiting"
- Files: `scripts/bee.gd`
- Check: `tools/verify.ps1` is green, and `task_description` returns the waiting text when `state == IN_HIVE_TO_CELL` and `target_cell == null`
- Proof: `absent: scripts/bee.gd :: no cell has room for it`
- Next after: none -- plans/now/hive-readouts.md is complete
```
