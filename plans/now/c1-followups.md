# C1F — Dave's 17 Sep 2026 pass: Challenge 1 follow-ups

<!-- CONTEXT: plan | LAYER: immediate-task -->
Status: active | Owner: Dave / Claude Code | Next: C1F-1 -- each Challenge 1 stage sets up the world it starts from | Dependency: none | Verified: 2026-09-17

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

## Open slices at a glance

| Slice | Outcome from the player's seat | Files owned | Startable | Level |
| --- | --- | --- | --- | --- |
| C1F-1 | Each settings stage arrow puts the queen, tunnel, cells and stores where that stage begins, so going back always stays back | new `scripts/challenge_stage_setup.gd`, `scripts/challenge_stages.gd`, `scripts/challenge_runner.gd`, `scripts/scenario_actions.gd` (one new action), new test_scenarios/c1f1_stage_setup_test.json | after UI-W-2 | high |
| C1F-2 | A headless run proves the queen sets off on pollen at 1.14 and does not loop on a full comb | `scripts/scenario_actions.gd`, new test_scenarios/c1f2_queen_pollen_departure_test.json | after C1F-1 | medium |

**Dependencies.** C1F-1 adds one action to `scripts/scenario_actions.gd`, as
UI-W-2 does, so it follows UI-W-2 in the Claude lane. C1F-2 starts its fixture at 1.14 through C1F-1's setup;
without it a headless run cannot reach 1.14 with two built cells. C1F-2 also
edits `scripts/scenario_actions.gd`, which UI-W-2 (`plans/now/ui-w.md`) owns
while it is open, so C1F-2 waits for UI-W-2 as well.

**Required reading for any slice.** Its own section below. Nothing in
`plans/archive/` is needed.

## C1F-1 — each Challenge 1 stage sets up the world it starts from

**Purpose.** C-49, Dave 17 Sep 2026: going back "doesn't work" at some
stages (for example back from 1.11, automate nectar gathering), the queen
"doesn't change position" and "wax cells [don't] appear" when skipping, and
"skipping the first stage does not make the hive soil blocks that are being
mined disappear". Dave chose (17 Sep 2026, in session) that each stage
declares the world it starts from and both arrows apply it.

**Root cause, confirmed.** `challenge_runner.gd::debug_retreat_stage` and
`debug_advance_stage` only re-run `_leave_stage`/`_enter_stage`, which rebuild
gates, prompts and marker; the docstring says world state is deliberately not
rolled back. Every Challenge 1 goal is a check against live world state
(`_goal_check_harvest_deposited`: queen inside, no load;
`_goal_check_nectar_target`: a nectar cell at `NECTAR_TARGET`;
`built_cells_at_least`). Retreating into a stage whose goal the world already
meets advances again at the next goal poll (`GOAL_POLL_INTERVAL`), which is
the "back doesn't work" symptom. Nothing moves the queen, builds or removes
cells, or clears the opening tunnel, which is the rest.

**Owner.** `scripts/challenge_stages.gd` owns stage data;
`scripts/challenge_runner.gd` owns when a stage is entered. The new
`scripts/challenge_stage_setup.gd` owns how a declared setup is applied, so
the runner (1,198 lines) does not grow a world-building section.

**Required reading.** `challenge_runner.gd`: `_enter_stage`, `_leave_stage`,
`_advance`, `debug_advance_stage`, `debug_retreat_stage`,
`_setup_opening_tunnel`, `_opening_tunnel_cleared`, and the `var _` block at
the top. `challenge_stages.gd`: the file header comment and the 1.1-1.20
records. `hive.gd::create_cell_site_at`, `hive_cell.gd` `add_build_progress`,
`add_resource`, `clear_cell`, `set_designation`. `world_building.gd`:
`move_bee_into_hive`, `move_bee_out_of_hive`, `_hive_centre_local`,
`_spawn_hatched_bee`. `scenario_actions.gd::_do_advance_challenge_stage`.

**Files likely to change.** New `scripts/challenge_stage_setup.gd`;
`scripts/challenge_stages.gd`; `scripts/challenge_runner.gd`;
`scripts/scenario_actions.gd`; `tests/source_checks.py`; new
test_scenarios/c1f1_stage_setup_test.json;
`docs/challenge-stages.md` only through `python tools/stage_reference.py`.

**Must not change.** `scripts/bee.gd`, `scripts/bee_foraging.gd`,
`scripts/save_game.gd`, `scripts/saving.gd`, `scripts/tutorial_checkpoint.gd`,
Challenge 2's stage records, and natural stage advance (a goal met in play).

**Requirements.**
1. Each Challenge 1 stage record gains `"setup": {...}`, a declaration of the
   world at that stage's start, using only these keys (all optional; an
   absent key means "leave as it is"):
   - `tunnel_open: bool` -- false re-creates the opening soil blocks through
     `_setup_opening_tunnel()`; true removes any that remain.
   - `queen_at: "tunnel" | "cavity" | "hive_floor" | "meadow_door"` --
     positions and parents the queen, with no navigation in progress.
   - `built_cells: int` -- exactly this many built comb cells, built at the
     same anchors the stage markers use (`_update_marker`'s build anchor);
     extra cells, newest first, are removed.
   - `cell_stores: [{"type": "nectar"|"pollen", "amount": float}]` -- contents
     of built cells in build order; unlisted cells are emptied.
   - `pollen_cell: int` -- index of the cell explicitly designated for pollen,
     or -1 for none (clears designations).
   - `queen_role: "egg_layer" | "forager"`, `queen_focus: "nectar" | "pollen"`,
     `queen_load: {"type": String, "amount": float}` (amount 0 = empty).
   - `brood_cells: int` -- cells holding an egg (1.17 onwards).
   - `new_worker: bool` -- a hatched nectar Forager exists and is the runner's
     `_new_worker` (1.18 onwards); false removes it.
   - `runner: {...}` -- runner counters the stage's goal reads, today only
     `c1_queen_collections`.
2. `ChallengeStageSetup.apply(runner, main, setup: Dictionary)` applies them
   in the order above, then calls `main.hive.build_navigation()`,
   `main.hive.refresh_edge_flags()` and `main.hive.announce()` once.
3. `debug_advance_stage` and `debug_retreat_stage` apply the *destination*
   stage's setup after `_leave_stage()` and before `_enter_stage()`. Natural
   `_advance()` never applies setup.
4. Each record's setup is written so that, once applied, that stage's own
   goal is false and every earlier stage's goal would be true. This is the
   rule that makes going back stay back, and it is tested (below).
5. Release the queen first (`_release_everything()`,
   `clear_navigation_state()`, `current_flower = null`, `target_cell = null`,
   state `IDLING`), as `freeze_bee:queen` does, so no errand survives a jump.

**Constraints and invariants.** Setup runs only for `Session.starting_level
== 1`; a Challenge 2 jump stays gates-only (see Escalate). No save format
change: setup edits live nodes only, and `_enter_stage` still writes its
checkpoint afterwards. `_leave_stage`'s camera-follow-off and 1x speed still
run on every jump. No per-frame work is added.

**State and cleanup.** Removing a cell must release every bee's slot on it
and clear any `target_cell` pointing at it before `queue_free`. Re-creating
the tunnel resets `_opening_blocks`/`_opening_started` through
`_setup_opening_tunnel()`. The 1.11 collection-rate override stays
idempotent (`_c1_base_nectar_rate`).

**Edge cases.** Jumping while the queen is mid-flight in the meadow; while a
cell is half-built; forward past 1.17 with no egg laid; back from 1.20 after
`_complete()` has run (`active` is false -- the arrows are disabled then,
keep it so). Fog of war must reveal the cavity when `tunnel_open` is true.

**Automated acceptance.**
- test_scenarios/c1f1_stage_setup_test.json (`"challenge": 1`): step
  forward through every stage to 1.19 and back to 1.1 using a new
  `retreat_challenge_stage` scenario action (mirror of
  `_do_advance_challenge_stage`, in the same file's dispatch). After each
  step, settle 2 seconds of game time and assert `challenge_stage_id` is still
  the stage stepped to. Fails on master at the first retreat into a met goal.
- A `tests/source_checks.py` check: every Challenge 1 record has a `setup`,
  and every key in it is one of requirement 1's names.

**Regression checks.** `tools/verify.ps1`;
`test_scenarios/h4_challenge1_stage_advance_test.json`;
`python tools/stage_reference.py --check`.

**Completion.** Replace C-49 in `checks/blocked.md` with a ready check (same
id): "In Challenge 1, open Game Settings > World & start and step forward and
back across every stage. PASS: after each arrow the queen, the tunnel, the
comb cells and their stores match the stage shown, and the stage shown stays
put until you act." Archive this section; set `Next:` to C1F-2.

**Level:** high (ownership boundary and event ordering).

**Escalate if** a stage's goal cannot be made false by setup alone, if cell
removal needs a change in `hive.gd`'s index beyond `announce()`, or if Dave
wants Challenge 2's arrows to set up its world too (its goals are
population-based and would need a different setup vocabulary).

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
condition beside `challenge_stage_id` in the shared when/assert checker, and a `set_queen_load` action), new
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

**Acceptance.** Both fixtures pass on the branch; reverting
`bee_foraging.gd::go_to_deposit_cell`'s `bee.target_cell = null` line makes A
fail. **Level:** medium. **Escalate if** reaching 1.14 headlessly needs more
than C1F-1's setup.
