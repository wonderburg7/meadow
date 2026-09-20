# C1F — Dave's 17 Sep 2026 pass: Challenge 1 follow-ups

<!-- CONTEXT: plan | LAYER: immediate-task -->
Status: active | Owner: Dave / Claude Code | Next: None -- plan complete; one known gap filed below (C1F-G1) | Dependency: none | Verified: 2026-09-20

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
| C1F-2 | A headless run proves the queen sets off on pollen at 1.14 and does not loop on a full comb | `scripts/scenario_actions.gd`, new test_scenarios/c1f2_queen_pollen_departure_test.json | after C1F-1 | medium |

**Dependencies.** C1F-1 follows E1
(`plans/design/architecture-review.md`), because requirement 5 clears the
placement tool E1 replaces: taken in the other order, C1F-1 writes seven
`awaiting_*` clears that E1 then deletes. C1F-2 starts its fixture at 1.14 through C1F-1's setup;
without it a headless run cannot reach 1.14 with two built cells. C1F-2 also
edits `scripts/scenario_actions.gd`.

**Required reading for any slice.** Its own section below. Nothing in
`plans/archive/` is needed.

C1F-1 shipped 2026-09-19; its specification is `plans/archive/C1F-1_2026-09-19.md`.

## C1F-2 — a headless run proves the queen's pollen departure and no discard loop

**Purpose.** C-7's pollen half has failed or not been reached on 10, 12 and
17 Sep 2026, and C-42's loop was found on 17 Sep. CLAUDE.md: the second time
a check fails for the same reason, build the instrument.

**Root cause (fixed on `claude/pass-0917`).** A queen waiting at a full comb
kept a `target_cell` that could no longer take her load, so
`bee.gd::set_focus` read her as mid-delivery and did not wake her; the 1.14
discard sat behind the deposit epoch gate; after a discard she walked
straight out for another trip. This slice proves the fix stays fixed.

**Files likely to change.** `scripts/scenario_actions.gd` (a `queen_inside_hive`
condition beside `challenge_stage_id` in the shared when/assert checker, and the `set_queen_load`, `set_cell_contents` and `empty_cell` actions), new
test_scenarios/c1f2_queen_pollen_departure_test.json.

**Requirements.**
1. Fixture A: `"challenge": 1`, advance to 1.14 (C1F-1 sets two built cells,
   the second designated pollen, the first full of nectar). `set_queen_load`
   nectar 5 and state `IN_HIVE_TO_CELL` with the pollen cell as
   `target_cell`. `assign_role` `forager_pollen` on the queen. Assert within
   30 game seconds that `queen_inside_hive` is false and her load is empty.
2. Fixture B: same start, focus stays nectar, queen sent to a flower. Assert
   exactly one `challenge_1_nectar_overflow` Gallerin prompt within 120 game
   seconds and `queen_inside_hive` true 30 seconds after it.
3. Fixture A also asserts, from `assign_role` to departure, that the queen is
   never in `SEEK_FLOWER`, `SEARCHING`, `TO_FLOWER` or `COLLECTING` while
   `queen_inside_hive` is true (a `queen_state_in` list beside
   `queen_inside_hive` in the same checker), and that the Challenge's
   camera-follow is on 10 game seconds after the Pollen focus is set.
4. Fixture C: same start, with nectar stocked in the pollen cell and the
   queen told to empty it. Neither verb exists yet: add `set_cell_contents`
   (`{"hex": [q, r], "resource": "nectar", "amount": n}`, through the cell's
   own `add_resource`) and `empty_cell` (`{"hex": [q, r]}`, calling
   `bee.gd::command_empty_cell` on the queen -- the button's own function) to
   `scripts/scenario_actions.gd`, beside `designate_cell`. Assert the cell is
   empty within 120 game seconds and that the queen then leaves the hive (`queen_inside_hive` false) without a player command.

**Acceptance.** All three fixtures pass on the branch; reverting
`bee_foraging.gd::go_to_deposit_cell`'s `bee.target_cell = null` line makes A
fail, removing the `_walk_out_if_indoors` call from `seek_flower` makes A's
requirement 3 fail, and removing `builder_dump_waste`'s continuation makes C
fail. **Level:** medium. **Escalate if** reaching 1.14 headlessly needs more
than C1F-1's setup.

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
