# Challenge 1 — Slice 17, delivered 9 September 2026

Extracted from `plans/now/challenge-1.md` on landing. See that file for the
plan's current state and open slices (18-19, then 7).

## Slice 17 — changing a bee's focus wakes her up — DONE 9 Sep 2026

**Reasoning level: medium.** One guarded branch in the shared bee state
machine, so it must not disturb bees that are mid-errand.

**What Dave reported.** At the pollen stage the queen does nothing at all.
Only right-clicking the nest entrance, a player command, gets her moving.

**Cause.** Stage `1.11`'s `on_exit` runs `freeze_bee:queen`, which parks her
in `State.IDLING`. `scripts/bee.gd`'s state machine handles that state with
`pass   # waits for orders and nothing else`, so nothing dispatches her
again. Assigning a *role* would wake her, because `_apply_role()` ends by
setting `state = _default_state_for_role()`. Changing her *focus* did not:
`Bee.set_focus()` deliberately left the state alone when the bee was inside
the hive, on the reasoning that `_go_to_exit()` would call
`_default_state_for_role()` once she walked out. A bee parked on `IDLING`
never walks out, so the focus change landed on a bee that would never act on
it.

**Delivered, in `scripts/bee.gd`, in `set_focus()`.** Added a branch between
the existing "not inside the hive" case and the fall-through: when the bee
is inside the hive and parked on `State.IDLING`, set
`state = State.IN_HIVE_TO_EXIT` so she walks out through the ordinary
entrance path and `_go_to_exit()` picks the new resource type up on arrival.
Every other inside-the-hive state is left alone, as before, so a bee
carrying a load to a cell still finishes that walk.

**Acceptance.** At the pollen stage, selecting the queen and pressing Pollen
sends her out of the hive and to a flower with no further input. At 1.11,
giving her Forager with nectar focus does the same. A forager already
walking a load to a cell when her focus is switched still delivers that load
first.

**Check:** covered by C-7's rewritten second condition, in `checks/ready.md`.
C-7 as a whole stays open -- its `Owner:` line names Slice 18, since the
pollen-deposit half of the acceptance still needs Slice 18.

**Landed:** commit `2f5e016` on `claude/C1-17`, merging to `master`.
