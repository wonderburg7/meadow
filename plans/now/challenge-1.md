# Challenge 1 — the acceptance pass

<!-- CONTEXT: plan | LAYER: immediate-task -->
Status: active | Owner: Dave / Claude Code | Next: Slice 7 -- acceptance pass and documentation | Dependency: none | Verified: 2026-09-12

**Objective.** Challenge 1 teaches the game's core loop without ever
advancing on behaviour the player did not command, and without ever taking
something away from the player that they watched themselves earn. The nectar
half of that loop now works. The pollen half does not, and Slices 20 to 26
are what make it work before the acceptance playthrough is worth running.

**State.** Slices 1-6 and 8-15 are code-complete and merged (3 Sep 2026).
Slices 16-20 shipped by 10 Sep 2026 in answer to Dave's first C-7 run --
the queen works more than one flower, a focus change wakes her, pollen has
somewhere to go once a cell is designated for it, and a stage's camera and
speed switch off when it ends. Their specifications and the five reports
that produced them are archived at
`plans/archive/CHALLENGE1_SLICE_16_2026-09-09.md` and its siblings for 17,
18 and 19; open them for provenance, never to work out what to do.

**What Dave's 10 Sep pass confirmed.** C-30 and C-31 failed again, exactly as
Slice 20 predicts: he reports "there's no instruction to do this, the
instructions from the doctor go straight to assigning the Queen the
forager/pollen role", and for C-31 that "the dr's speech stays at 'keep the
forager role…'". That line is stage 1.14's own hint -- the pollen-automation
stage, where the queen switches her focus to pollen -- so the game is sitting
at 1.14 with 1.13, the stage that reserves the second cell for pollen, never
having been seen. Slice 20 is the fix and nothing about it changes. C-29
failed on the pollen stage's camera only, which is Slice 22. C-7's nectar
half passed and its pollen half failed, which is Slice 21.

**What the same pass added.** One new defect and one new pair of asks:

- Slice 25. The queen's nectar is destroyed whenever Challenge 1's comb is
  full, at every stage, not only at the pollen stage the rule was written
  for. This is the most severe finding in the pass -- it loses resources the
  player gathered by hand and can dead-end the run.
- Slice 26. The yellow "move here" marker should pulse, and should show an
  edge arrow when it is off screen.

**Design review, still standing.** Dave, 9 Sep 2026: "The design here should
be reviewed so there isn't this degree of disruption to the stages and the
gameplay." Slice 20 was that review's first answer -- the disruption is one
over-broad goal, not the stage design. Slice 25 is its second, and has the
same shape: a rule whose comment named a stage and whose code did not.

**Slice 21 shipped 11 Sep 2026.** The queen's stall was the same shape again:
Slice 25's stage-1.14 discard rule only ever ran from a bee actively
retrying a deposit, never from one parked on `IDLING` by Stage 1.11's
freeze -- so a nectar load frozen mid-trip rode straight through to 1.14
untouched. Full record, including why the prescribed headless trace could
not be run: `plans/archive/C1-21_2026-09-11.md`.

## Open slices at a glance

Slices 20 through 26 have all shipped; their specifications are
archived (see the pointers above and `plans/archive/`). What remains:

| Slice | What it fixes | Files | Level |
| --- | --- | --- | --- |
| 7 | The acceptance playthrough and copy pass | docs | -- |

Slice 7 runs last.

**Slices 24 and 26 name a headless assertion that cannot be run yet (found 11
Sep 2026, narrowed 11 Sep 2026 when Slice 21 shipped on a static trace
instead).** Both state a headless Challenge assertion as their acceptance,
and no headless run can start a Challenge at all: `challenge_runner.start()`
fires only for `Session.starting_level` 1 or 2, and a `--scenario` launch
always sets that to `Levels.SCENARIO_LEVEL_ID`. There is no Challenge
fixture and no stage-sequence test, whatever Slice 24's regression line
says. `plans/design/architecture-review.md`'s **H4** is the slice that fixes
it. Both of H4's dependencies (C1-21 and C1-22) have now shipped, so H4 is
queued in `NEXTSTEPS.md`'s Codex lane -- not as the lane's leading item,
since it shares `scripts/main.gd` with the Claude lane's own leading item
(H2), but as its second item, claimable once one of those two ships. Slices
24 and 26 stay blocked until H4 actually lands.

Nothing else may be added -- a finding from Slice 7's own run becomes this
plan's next slice while it is open, and a finding after it closes starts a
new `plans/now/` file.

**Authoritative files.** Stage data: `scripts/challenge_stages.gd`.
Sequencing and gating: `scripts/challenge_runner.gd`. The
"player drives this bee" flag and the state machine: `scripts/bee.gd`.
Foraging transitions: `scripts/bee_foraging.gd`. Cell storage rules:
`scripts/hive_cell.gd`, `scripts/hive.gd`.

**Required reading.** The one slice heading you are implementing, plus
`docs/challenge-stages.md`. Never the whole file.

**Reasoning level.** Stated per slice in the table above. Slice 7 is Dave's
own playthrough plus a copy/doc pass, not a reasoning-bounded code slice.

**Numbering never restarts.** C-7 once named "Slice 14", archived on 3 Sep,
so the check pointed at a specification nobody could open. A retired number
is never reused.

## Slice 20 — the designation stage asks for the designation it names

Shipped 10 Sep 2026. Full specification and delivery record:
[`plans/archive/C1-20_2026-09-10.md`](../archive/C1-20_2026-09-10.md).

## Slice 25 — the queen's harvest is never thrown away without her being told

Shipped 11 Sep 2026. Full specification and delivery record:
[`plans/archive/C1-25_2026-09-11.md`](../archive/C1-25_2026-09-11.md).

## Slice 21 — the queen forages pollen without being pushed

Shipped 11 Sep 2026. Full specification and delivery record:
[`plans/archive/C1-21_2026-09-11.md`](../archive/C1-21_2026-09-11.md).

## Slice 22 — the stage's camera reaches the pollen stage

Shipped 11 Sep 2026. Full specification and delivery record:
[`plans/archive/C1-22_2026-09-11.md`](../archive/C1-22_2026-09-11.md).

## Slice 23 — a Challenge 1 wax cell is full at 150 nectar

Shipped 11 Sep 2026. Full specification and delivery record:
[`plans/archive/C1-23_2026-09-11.md`](../archive/C1-23_2026-09-11.md).

## Slice 26 — the stage marker asks to be noticed, and says where it is

Shipped 12 Sep 2026. Full specification and delivery record:
[`plans/archive/C1-24_2026-09-12.md`](../archive/C1-24_2026-09-12.md).

Shipped 12 Sep 2026. Full specification and delivery record:
[`plans/archive/C1-26_2026-09-12.md`](../archive/C1-26_2026-09-12.md).

### Challenge 1 acceptance pass — shipped 12 Sep 2026

Archived delivery record: `plans/archive/C1-7_2026-09-12.md`. The retained
reference below documents the stage contract; delivery detail lives only in
the archive.

**Runs after Slices 20-24.** The 29 Aug, 30 Aug, 2 Sep and the two 9 Sep
attempts at this pass are what found Slices 8, 9/10, 11/13, 16-19 and 20-24
respectively. It is not worth a sixth attempt until the pollen arc works
unattended.

Once Slices 20-24 are in:

- Run `.\tools\verify.ps1` (source + balance suites, function map,
  planning-metadata checks).
- Boot the project (`mcp__godot__*` if available this session) and play
  Challenge 1 start to finish, checking every item in the brief's
  "Acceptance checks" section directly (repeated here for a literal
  checklist pass):
  - No locked panel or role button is visible early.
  - The Meadow button appears only after the queen enters the meadow.
  - Manual stages never advance through automatic movement, collection,
    building or deposit.
  - The Forager role and its Nectar/Pollen options unlock only at their
    specified stages.
  - The queen stops when the nectar cell is full.
  - Pollen foraging continues until the pollen cell reaches ≥75.
  - Cell building never changes the queen's role to Comb worker.
  - All visible buttons respond across their complete bounds.
- Do the copy/current-doc pass that was Bundle H: consistent Gallerin voice
  across the new/changed lines (1.10, 1.12, 1.13, 1.14 especially), update any
  user-facing Challenge 1 / UI-unlock documentation to match, regenerate
  `FUNCTION_MAP.md` only if one of its six indexed scripts' functions moved.
- Add exactly the hands-on checks that still need Dave's eyes to
  `checks/ready.md` (short action, expected result, pointer) — the
  automated boot pass above covers structural correctness, not feel.
- Rewrite this file's Status line and `NEXTSTEPS.md`'s current-slice entry
  once this is genuinely done; archive execution detail here to
  `plans/archive/` per the documentation lifecycle rule.

<!-- LAYER: durable-rules -->

- Only Forager and Egg Layer (`roles.gd`'s `FORAGER`/`QUEEN`, key `forager`/
  `laying`) may ever be selectable during Challenge 1 — never add
  `"comb_worker"`, `"nurse"`, `"miner"`, `"honey"` or `"idle"` to any
  `STAGES_1` entry's `unlocked_keys`, and remember `hatch_options()` needs
  the same `allowed_role_keys` filter the Job column already has (Slice 2f).
- Challenge 1 cell building must never assign `Role.BUILDER` to the queen —
  neither as her primary role nor, per Slice 8d, her secondary/backup role
  (`Bee.role_restricted_to`) — the state machine (`State.TO_BUILD_SITE`/
  `BUILDING`) doesn't need it, and `_idle_dispatch`'s auto-rebuild behaviour
  is exactly what assigning it would reintroduce, via either role field.
- Any UI menu that offers a role choice (Job column, hatch options, the "If
  idle" backup-role menu) must filter by `allowed_role_keys` — three such
  menus exist; keep all three in sync, don't just fix the one a bug report
  named (Slice 8d-i closed the third).
- Challenge-local numeric overrides live on the object they affect
  (`HiveCell.build_time_override`, a per-bee collection-rate multiplier),
  never on `GameConfig` — see `.claude/rules/saving.md`'s write allowlist.
- `Bee.manual_deposit_pending` must default `false` and only ever be set
  `true` by `challenge_runner.gd` during Challenge 1's manual-forage stages;
  it must never leak into Challenge 2, Scenarios or open play.

<!-- LAYER: on-demand -->

- Full stage data: `scripts/challenge_stages.gd` (`STAGES_1`, `FAST_BUILD_TIME`,
  `NECTAR_TARGET`/`POLLEN_TARGET`, and Slice 8e's new `on_enter`/`on_exit`
  action arrays once added).
- Shared full-storage/epoch-guard fix (Slice 8a): `scripts/bee_foraging.gd`
  (`go_to_deposit_cell`), `scripts/hive.gd` (`index_epoch`,
  `invalidate_index`), and the existing miner precedent for the same shape
  (`bee.gd`'s `_mining_no_work_epoch`/`hive.mining_work_epoch`).
- Stage sequencing/goals: `scripts/challenge_runner.gd` (`_enter_stage`,
  `_goal_registry`, `_on_queen_build_cell_requested`,
  `_apply_stage_gate_to_ui`).
- Role panel: `scripts/hud.gd` (`_rebuild_role_controls`, `_build_job_row`,
  `_build_queen_build_row`, `_build_nursery_controls`, `hatch_options`).
- Movement/commands: `scripts/bee.gd` (`command_move_to`,
  `command_collect_from`, `command_return_and_deposit`, `_idle_dispatch`,
  `_try_role_work`), `scripts/bee_foraging.gd` (`enter_hive`,
  `go_to_deposit_cell`), `scripts/bee_building.gd` (`builder_go_to_site`,
  `builder_build`).
- Input routing: `scripts/input_selection.gd` (`_issue_command`,
  `_finish_drag`, `_place_build_cell`, `_draw_build_hover`, `_cell_at`).
- Flowers: `scripts/flower_species.gd` (`pick_species_index`),
  `scripts/world_building.gd` (`_seed_flower`).
- Win screen: `scripts/challenge_complete.gd`, `scripts/main.gd`
  (`_on_level_chosen`, the `challenge_complete.*_requested` connections
  ~line 539–544).
- Historical Challenge 1/2 design: `plans/archive/TUTORIAL_PLAN_2026-08-24.md`.
- Related open UI investigation: `plans/now/ui.md`'s UI-D — check for overlap
  before/after Slice 1a.
- Current player checks: `checks/ready.md` (search `Challenge 1`).
