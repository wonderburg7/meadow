# C1F — Dave's 17 Sep 2026 pass: Challenge 1 follow-ups

<!-- CONTEXT: plan | LAYER: immediate-task -->
Status: active | Owner: Dave / Claude Code | Next: C1F-4 -- a contract test guards the target_cell reset (closes C1F-G1), queued in the Claude lane; C1F-3 shipped 27 Sep | Dependency: none | Verified: 2026-09-27

**Objective.** The Challenge 1 findings from Dave's 17 Sep 2026 hands-on pass
that could not be fixed in the session, each owned here because
`plans/archive/CHALLENGE1_2026-09-15.md` is archived and never reopened.
`docs/challenge-stages.md` says what every stage id asks the player to do.

**State.** Fixed in the session itself, on `claude/pass-0917` (no slice spec
needed): the queen now sets off when switched to pollen at 1.14, the 1.14
nectar discard no longer loops, reserving a stocked cell for pollen keeps its
nectar, the queen's Nursing backup is automatic, and the settings stage row
reads on one line. Their re-run notes are on C-7, C-29, C-31, C-42 and C-49.
What remains needs a new mechanism (C1F-1) and the instrument that uses it
(C1F-2).

**19 Sep 2026 pass, fixed in session** (re-run notes on C-7, C-29, C-31,
C-42). An idle Forager inside the hive was dispatched to flower-seeking
where she stood and, reading meadow positions as hive-local ones, "foraged"
invisible flowers indoors -- the pollen stage's real fault on 17 and 19 Sep.
`bee_foraging.gd::_walk_out_if_indoors` now walks her out first, at the two
flower-finding steps. The 1.14 camera and speed wait for her Pollen focus,
since selecting her to press it cleared a follow that had already fired.
"Empty this cell" continues until the cell is empty
(`bee_building.gd::builder_dump_waste`). The 1.14 overflow warning names the
pollen-only cell (Dave: it stays pollen-only). `tests/test_source_checks.py`'s
`IndoorForagingContractTest` pins the first two statically; C1F-2 below
proves them at runtime.

## Open slices at a glance

| Slice | Outcome from the player's seat | Files owned | Startable | Level |
| --- | --- | --- | --- | --- |
| C1F-4 | none -- a regression guard: reverting the queen's `target_cell` reset now fails `tests/test_source_checks.py` | `tests/test_source_checks.py` | yes | low |

**Dependencies.** C1F-1 follows E1
(`plans/archive/architecture-review_2026-09-24.md`), because requirement 5 clears the
placement tool E1 replaces: taken in the other order, C1F-1 writes seven
`awaiting_*` clears that E1 then deletes. C1F-2 starts its fixture at 1.14 through C1F-1's setup;
without it a headless run cannot reach 1.14 with two built cells. C1F-2 also
edits `scripts/scenario_actions.gd`.

**Required reading for any slice.** Its own section below. Nothing in
`plans/archive/` is needed.

C1F-1 shipped 2026-09-19; its specification is `plans/archive/C1F-1_2026-09-19.md`.

C1F-2 shipped 2026-09-20; its specification is `plans/archive/C1F-2_2026-09-20.md`.

C1F-3 shipped 2026-09-27; its specification is `plans/archive/C1F-3_2026-09-27.md`.

## C1F-4 — a contract test guards the target_cell reset

Closes C1F-G1 (below). Dave chose the unit-level route on 24 Sep 2026, at
AP-8's closeout, over a stage-setup key that skips `_release_queen` or a
scenario action that sets the queen's state after the jump. Meadow has no
GDScript unit harness, so "unit-level" means a static contract test beside
`IndoorForagingContractTest`, the way C-7's sibling fixes are already pinned.

- **Level.** low -- one test file, no game code.
- **Requirements.** Add a `unittest.TestCase` class,
  `DepositTargetResetContractTest`, to `tests/test_source_checks.py`. Using
  the same `_body` split as `IndoorForagingContractTest`, take
  `bee_foraging.gd::go_to_deposit_cell` and assert that, inside the branch that
  opens `if bee.target_cell == null or not is_instance_valid(bee.target_cell)`,
  the line `bee.target_cell = null` appears before the epoch-gate
  `if bee.deposit_blocked_epoch == bee.hive.index_epoch` return. The docstring
  names C-7 and says why a runtime fixture was not used (C1F-G1: stage jumps
  release the queen, so no fixture reaches the pre-1.14 early return).
- **Automated acceptance.** `python -m unittest tests.test_source_checks` passes;
  deleting the `bee.target_cell = null` line from `go_to_deposit_cell` makes the
  new test fail (try it, then restore the line; record that in the closeout
  note). Then mark C1F-G1 below as closed by C1F-4.

```queue
**[Claude] C1F-4 -- a contract test guards the target_cell reset**
- Plan: `plans/now/c1-followups.md` -- "C1F-4 — a contract test guards the target_cell reset"
- Files: `tests/test_source_checks.py`
- Check: `python -m unittest tests.test_source_checks` passes, and deleting `bee.target_cell = null` from `go_to_deposit_cell` makes `DepositTargetResetContractTest` fail
- Proof: `absent: tests/test_source_checks.py :: DepositTargetResetContractTest`
- Next after: none -- c1-followups is complete once C1F-3 and C1F-4 ship.
```

## Known gap C1F-G1 -- the `target_cell = null` revert does not fail fixture A

Filed 20 Sep 2026 at C1F-2's closeout, for a higher-reasoning session to plan.
C1F-2's fixtures A, B and C pass, and removing `builder_dump_waste`'s
continuation makes C fail and removing `seek_flower`'s `_walk_out_if_indoors`
call crashes the run. Reverting `bee_foraging.gd::go_to_deposit_cell`'s
`bee.target_cell = null` does **not** fail A, so that line's regression is not
guarded. Why: at 1.14 `challenge_discards` is true, so the function overwrites
`target_cell` from `find_cell_for` whatever the line did; the line only matters
on the epoch-gate early return, before 1.14. A fixture that reaches it needs the
queen waiting at a full comb *before* 1.14 and then carried into the stage, but
`challenge_stage_setup.gd::apply` calls `_release_queen` on every jump and so
wipes that state. Options for the plan: a stage-setup key that skips the release,
a scenario action that sets the state after the jump but before the first think
tick, or a unit-level check of `go_to_deposit_cell`. Fixture A's departure window
is also 10 s + 50 s, not the 30 s the plan asked for: the queen needs longer than
30 game seconds to walk out.
