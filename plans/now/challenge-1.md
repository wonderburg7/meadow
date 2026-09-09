# Challenge 1 — the acceptance pass

<!-- CONTEXT: plan | LAYER: immediate-task -->
Status: active | Owner: Dave / Claude Code | Next: Slice 20 -- the designation stage asks for the designation it names | Dependency: Slice 21 waits on Slice 20; Slice 7 waits on all of 20-24 | Verified: 2026-09-09

**Objective.** Challenge 1 teaches the game's core loop without ever
advancing on behaviour the player did not command. The nectar half of that
loop now works. The pollen half does not, and Slices 20 to 24 are what make
it work before the acceptance playthrough is worth running.

**State.** Slices 1-6 and 8-15 are code-complete and merged (3 Sep 2026).
Slices 16-19 shipped on 9 Sep 2026 in answer to Dave's first C-7 run --
the queen works more than one flower, a focus change wakes her, pollen has
somewhere to go once a cell is designated for it, and a stage's camera and
speed switch off when it ends. Their specifications and the five reports
that produced them are archived at
`plans/archive/CHALLENGE1_SLICE_16_2026-09-09.md` and its siblings for 17,
18 and 19; open them for provenance, never to work out what to do.

**What Dave's second 9 Sep pass found.** C-7's nectar half and C-29's
nectar stage now pass. Everything downstream of the second cell does not.
C-30 failed outright, C-31 failed on Dr Gallerin's line, C-7 failed on the
whole pollen arc, and C-29 failed on the pollen stage's camera. One confirmed
cause sits under three of the four: stage 1.13's goal is satisfied by the
*first* cell's automatic nectar designation, so the stage that would set the
second cell aside for pollen clears before the player sees it (Slice 20).
Dave also asked for a lower nectar target, and reported a stray marker in the
meadow. He added: "The design here should be reviewed so there isn't this
degree of disruption to the stages and the gameplay." Slice 20 is that
review's first answer -- the disruption is one over-broad goal, not the
stage design -- and Slice 21 tests whether anything remains once it is gone.

## Open slices at a glance

| Slice | What it fixes | Files | Level |
| --- | --- | --- | --- |
| 20 | Stage 1.13 clears before the player sees it (C-30, C-31) | `challenge_runner.gd`, `challenge_stages.gd` | medium |
| 21 | The queen will not start pollen foraging unaided (C-7) | `bee.gd`, `bee_foraging.gd` | high |
| 22 | The pollen stage's camera never follows (C-29) | `challenge_runner.gd`, `camera_view.gd` | medium |
| 23 | A Challenge 1 nectar cell is full at 150, not 200 | `challenge_stages.gd`, `challenge_runner.gd` | low |
| 24 | A stage marker appears in the meadow at 1.12 (yellow dot) | `challenge_runner.gd` | low |
| 7 | The acceptance playthrough and copy pass | docs | -- |

Slice 21 depends on Slice 20: until 1.13 runs, no cell accepts pollen and
every pollen symptom has that as a sufficient cause. Slice 7 runs last.
Slices 22, 23 and 24 are independent of each other and of 20.

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

**Reasoning level: medium.** One goal function, but it is shared with
Challenge 2 and it gates three failed checks.

**Confirmed root cause.** `challenge_runner.gd::_goal_check_cell_designated()`
(`:996`) returns true for *any* cell whose `designated_type` is one of
nectar/pollen/brood. `hive_cell.gd::add_resource()` (`:721`) auto-assigns
`designated_type = resource_type` the first time anything is deposited into
an empty, undesignated cell. So the queen's first nectar delivery at stage
1.10 designates the first cell "nectar", and stage 1.13 — "set the new cell
aside for pollen" — is already satisfied the instant it opens. It clears in
the same frame and the player never sees it (C-30).

Two further failures follow from that one cause, so all three are this
slice's:

- The second cell is never designated for pollen, so the queen's next nectar
  trip auto-designates it "nectar" too. `_drive_c1_pollen_cell_nectar_prompt`
  (`:790`) only fires on a cell with `designated_type == "pollen"`, so Dr
  Gallerin's call-out never runs (C-31).
- With no cell that will accept pollen, the pollen-automation stage begins
  with nowhere to put a pollen load. Slice 21 covers what the queen then
  does; this slice removes the reason.

**Current authoritative owner.** `scripts/challenge_runner.gd` for goals and
sequencing; `scripts/challenge_stages.gd` for stage data.

**Required reading.** This heading, `docs/challenge-stages.md`, and
`challenge_runner.gd`'s `_goal_registry` (`:884`) and `GOAL_KINDS` (`:856`).

**Files likely to change.** `scripts/challenge_runner.gd`,
`scripts/challenge_stages.gd`, `docs/challenge-stages.md` (regenerated).

**Files that must not be changed.** `scripts/hive_cell.gd` — the auto-designate
on first deposit is correct open-play behaviour and several other systems
rely on it. `scripts/hive.gd`. Challenge 2's stage `2.3`, which keeps the
existing `cell_designated` goal unchanged.

**Requirements.**

1. Add a new goal key `pollen_cell_designated`, registered in `GOAL_KINDS` as
   `"poll"` and in `_goal_registry` as `_goal_check_pollen_cell_designated`.
2. It returns true only when a cell has `designated_type == "pollen"` **and**
   `designation_is_explicit == true`. That second field already exists on
   `HiveCell` (`:762` reads it) and is what separates a player's choice from
   the auto-assignment `add_resource` makes.
3. Point stage `1.13` at the new goal. Leave stage `2.3` on
   `cell_designated` and leave `_goal_check_cell_designated` itself alone.
4. Confirm the cell-designation UI sets `designation_is_explicit`. If the
   Pollen button in the cell popup does not set it, set it there — that is
   the one place a designation is genuinely the player's choice. Do not set
   it anywhere in `add_resource`'s path.

**Constraints and invariants.**

- Challenge 2's stage 2.3 must keep passing on the same behaviour it passes
  on today. Do not repurpose the shared goal.
- No `GameConfig` write (this plan's durable rules).
- Save compatibility: `designation_is_explicit` is already saved or already
  not saved; do not change which. If it is not persisted, do not start
  persisting it in this slice — say so in the commit message and file it as
  a follow-up instead.

**State-transition and cleanup behaviour.** Stage 1.13's `on_exit` stays as
it is. Nothing new is stored on the runner, so nothing new needs resetting in
`_reset_c1_state` (`:183`).

**Edge cases.**

- The player designates the *first* cell for pollen instead of the second.
  The goal passes — that is a legitimate, if odd, way to satisfy it, and the
  stage text says "the new one" rather than enforcing which.
- The player unreserves and re-reserves. The goal is a poll, so it simply
  goes false and true again; the stage does not advance while it is false.
- A checkpoint restore during 1.13 rebuilds `hive.cells`; the poll reads the
  new list each frame, so nothing stale survives.

**Automated acceptance checks.** Add a test that builds a hive with one cell
auto-designated nectar by a deposit and asserts `pollen_cell_designated` is
false; then explicitly designates a second cell pollen and asserts it is
true. Add a regression assertion that `cell_designated` still returns true
for the auto-designated cell, so Challenge 2 is proved untouched.

**Regression checks.** Run the source and balance suites. Re-run any existing
Challenge 2 stage-sequence test.

**Completion and documentation.** Regenerate `docs/challenge-stages.md` with
`python tools/stage_reference.py` (verification re-runs it with `--check`).
Re-file C-30 and C-31 unchanged — they are already written for this
behaviour.

**Escalate rather than guess if:** `designation_is_explicit` turns out not to
exist as a persisted, reliable flag, or the cell popup's Pollen button shares
its code path with the automatic designation. Either would mean the
player-choice signal has to be introduced rather than read, which is an
ownership decision.

## Slice 21 — the queen forages pollen without being pushed

**Reasoning level: high.** Bee state machine, and the cause is only partly
established.

**Depends on Slice 20.** Until stage 1.13 actually runs, no cell in the hive
will accept pollen, and every symptom below has that as a sufficient cause.
Do not start this slice before Slice 20 has landed and C-30 has been re-run.

**Observable problem (C-7, pollen half).** At stage 1.14 the queen does not
set off when the player switches her focus to Pollen. Right-clicking the hive
exit starts her; she then forages pollen, returns, and deposits the leftover
*nectar* she was still carrying.

**Established so far.** `bee.gd::_try_role_work()`'s `Role.FORAGER` branch
(`:1478`) has no storage precondition — it always enters `SEEK_FLOWER` — so
the stall is not a refusal to take forager work. Stage 1.11's `on_exit` runs
`freeze_bee:queen`, which calls `_release_everything()`,
`clear_navigation_state()` and sets `state = IDLING`; none of those drops
`current_load`. So the queen enters 1.12 to 1.14 still holding nectar. The
leading hypothesis is that a carried load routes her to a deposit before any
role work, and with the nectar cell full and (before Slice 20) the second
cell also nectar, the deposit search finds nothing and she waits — which is
exactly the "waits at the inner entrance" symptom from the first C-7 pass.

**This is a hypothesis, not a confirmed cause. Confirm it first.** Use the
headless scenario runner (`docs/headless-run-contract.md`) to drive Challenge
1 to 1.14 and record, per think tick: the queen's `state`, `current_load`,
`carrying` type, and the result of the deposit-cell search. Extract only
those fields; do not read raw run output back. If the trace does not show her
blocked on a deposit, stop and report what it does show rather than
implementing the fix below.

**Files likely to change.** `scripts/bee.gd`, `scripts/bee_foraging.gd`, and
`scripts/challenge_stages.gd` only if a stage effect is the right home for
the load-clearing.

**Files that must not be changed.** `scripts/game_config.gd`.
`scripts/hive.gd`'s deposit-search ordering, unless the trace shows the fault
is there — in which case escalate, because that path serves every bee.

**Requirements, if the trace confirms the hypothesis.**

1. The queen must not carry a nectar load into the pollen stage. Prefer a
   stage effect over a change to general bee behaviour: extend
   `_run_stage_effects` with an effect that deposits or discards the carried
   load, and give stage 1.13 or 1.14 that effect on entry. Naming it for what
   it does to the bee, not for the stage, keeps it reusable.
2. A bee holding a load it cannot deposit anywhere must not stand still
   indefinitely. Whatever the trace shows as the stall, the fix is that she
   either finds another home for it or gives it up and takes role work —
   never that she waits.
3. A focus change alone starts her (Slice 17 established this for nectar);
   prove it still holds for pollen once the load is gone.

**Constraints and invariants.** `manual_deposit_pending` must stay false
outside Challenge 1's manual stages. No change may make a non-Challenge bee
drop a load — check any new behaviour is behind the stage effect, not in
`_idle_dispatch`.

**Edge cases.** She is mid-flight when the focus changes. She is inside the
hive with a partial load. The pollen cell fills while she is still out.

**Automated acceptance checks.** A headless scenario that reaches 1.14 and
asserts the queen leaves the hive within N think ticks of the focus change,
with no command issued, and that her load is pollen when she next deposits.

**Regression checks.** Re-run the nectar half of the arc (stage 1.11) and
assert it still passes — it passes today and must keep passing.

**Escalate rather than guess if:** the trace points at `hive.gd`'s deposit
search, or the fix would need a bee to discard resources in open play. Both
change behaviour outside Challenge 1.

## Slice 22 — the stage's camera reaches the pollen stage

**Reasoning level: medium.** Two small failures in one function, one of them
needing a live or headless observation first.

**Observable problems (C-29).** At stage 1.14 the speed goes to 4x and back
to 1x correctly, but the camera never follows the queen. Separately, at the
meadow-waypoint stage, foraging and depositing before visiting all three
waypoints stops the nectar stage's automation from starting at all.

**Established so far.** `_drive_c1_forage_effects()` (`:758`) applies
`camera_follow_queen` and `speed_multiplier:4.0` together, gated on
`_c1_forage_effects_done` and on the queen being in one of
`CHALLENGE1_FORAGE_TRIGGER_STATES`. `_c1_forage_effects_done` is reset on
stage entry (`:342`), so the flag is not what suppresses the camera. Because
both effects are applied in the same call, "speed changed but the camera did
not" cannot be explained by that function alone: something after it clears
`main.following_bee`. `_run_stage_effects`'s `camera_follow_off` writes
`main.following_bee = null` directly (`:542`) rather than going through
`camera_view._on_follow_bee_toggled`, which is an asymmetry worth removing
whatever the cause turns out to be.

**Confirm the cause before fixing.** Log every write to `main.following_bee`
for the duration of stage 1.14 — the setter in `camera_view.gd:114`, the
direct write in `challenge_runner.gd:542`, and the `is_instance_valid` clear
in `_handle_follow` (`:124`) — and record which one runs last. The
`_handle_follow` clear is a live candidate: a checkpoint restore or a bee
rebuild replaces the queen node, and a stale reference would be nulled
silently on the next frame.

**Files likely to change.** `scripts/challenge_runner.gd`,
`scripts/camera_view.gd`.

**Files that must not be changed.** `scripts/main.gd`'s ownership of
`following_bee` as the single source of truth. Do not add a second
follow-target field.

**Requirements.**

1. `camera_follow_off` routes through `camera_view._on_follow_bee_toggled(null, false)`
   so both directions of the toggle have one owner, and add a matching
   assertion or comment saying that is the only way it is written from here.
2. Fix whatever the trace names as the last writer. If it is a replaced queen
   node, re-point the follow target at `main.queen` rather than nulling it.
3. The waypoint-stage failure: `_drive_c1_forage_effects` fires on the first
   frame the queen is in a foraging state *at stage 1.11 or 1.14 only*, and
   `_c1_forage_effects_done` is set true when it does. Establish whether an
   early forage trip during the waypoint stage leaves the flag or the queen's
   state such that 1.11 never triggers. The fix is that entering 1.11 arms the
   effects regardless of what the queen was doing beforehand.

**Constraints and invariants.** The effects must still start when she *sets
off*, not when the role is assigned — that distinction is what C-29 checks
and Slice 19 established. Camera-follow and 4x speed must both be off at
stage exit and after a checkpoint restore.

**Edge cases.** The player turns follow off by hand mid-stage; the stage must
not turn it back on. The player is in hive view when she sets off.

**Automated acceptance checks.** A headless assertion that at 1.14
`main.following_bee` is the queen within N ticks of her leaving, and is null
one tick after the stage completes.

**Regression checks.** Stage 1.11's camera and speed, which pass today.

**Escalate rather than guess if:** the last writer is outside these three
call sites, which would mean follow-target ownership is genuinely shared.

## Slice 23 — a Challenge 1 wax cell is full at 150 nectar

**Reasoning level: low.** One constant and two call sites.

**What Dave asked (9 Sep 2026).** "Make challenge 1's wax cells only require
150 nectar to be full, so the queen fills it to 150 and stops (rather than
200 which is taking too long so it's boring for the player)."

**Confirmed current behaviour.** `_goal_check_nectar_target()` (`:938`)
passes when a nectar cell's `fill_fraction()` reaches 1.0, which is
`GameConfig.cell_capacity`, 200. The queen stops because stage 1.11's
`on_exit` freezes her, so lowering the goal threshold is what makes her stop
sooner.

**Files likely to change.** `scripts/challenge_stages.gd`,
`scripts/challenge_runner.gd`.

**Files that must not be changed.** `scripts/game_config.gd` — this plan's
durable rule puts Challenge-local numbers on the object or the stage data,
never on `GameConfig`, and cell capacity is a balance value the whole game
reads.

**Requirements.**

1. Add `const NECTAR_TARGET := 150.0` to `challenge_stages.gd`, beside the
   existing `POLLEN_TARGET := 75.0` (`:18`), and mirror its comment.
2. `_goal_check_nectar_target` compares `cell.amount >= Stages.NECTAR_TARGET`
   for a cell with `content_type == "nectar"`, exactly as
   `_goal_check_pollen_target` already does for pollen.
3. `_goal_progress`'s `"nectar_target"` branch returns
   `{"current": cell.amount, "target": Stages.NECTAR_TARGET}` so the goal
   shelf's bar fills at the same point the stage clears. Today it returns
   `cell.capacity_for("nectar")`, which would leave the bar at 75% when the
   stage ends.
4. Check `challenge_stages.gd:272`'s comment about `cell_capacity` being 200
   and update it if this changes what it describes.

**Constraints and invariants.** The cell's real capacity stays 200 — this
changes when the *stage* is satisfied, not how much a cell holds. Challenge 2
is untouched.

**Edge cases.** The queen is carrying more than the remainder when she
crosses 150; the goal is a poll on the cell's amount, so it simply passes on
the deposit that crosses it.

**Automated acceptance checks.** A test asserting `nectar_target` is false at
149 and true at 150, and that the progress dictionary's target is 150.

**Regression checks.** Balance suite, which reads `cell_capacity`.

**Completion and documentation.** Update `docs/challenge-stages.md` only if
the goal text changes; it does not.

## Slice 24 — the stage marker is never left in the wrong world

**Reasoning level: low.** One missing guard, already written twice in the
same function.

**Confirmed root cause.** `challenge_runner.gd::_update_marker()` (`:479`)
reparents `_marker` before showing it in two of its branches — `1.6`/`1.19`
pull it back to `hive_root`, `1.10` pushes it to `meadow_root` — but the
`["1.2", "1.5", "1.12", "1.15"]` branch sets a hive-local position and makes
the marker visible without reparenting it. Stages 1.7 and 1.10 leave the
marker parented to `meadow_root`, so at 1.12 it appears in the meadow at a
coordinate that means nothing there. That is Dave's yellow dot: "A yellow dot
appears in the meadow when getting to the 'use build cell and place a second
cell beside the first' stage."

**Files likely to change.** `scripts/challenge_runner.gd`.

**Files that must not be changed.** Anything else.

**Requirements.**

1. Give the `["1.2", "1.5", "1.12", "1.15"]` branch the same reparent guard
   the `1.6`/`1.19` branch has, before it sets the position.
2. Better: hoist the guard so every branch states the parent it wants and one
   line does the reparenting. Four branches each remembering to reparent is
   how the fourth was missed; one place that always does it cannot be.

**Constraints and invariants.** `reparent(parent, false)` keeps the local
transform, which is what these branches want — they all assign a local
position immediately afterwards. Do not switch to global positioning.

**Edge cases.** 1.15 has the same defect and the same fix; it was not
reported only because 1.10's meadow trip is further behind it. Fix both.

**Automated acceptance checks.** A headless assertion that on entering each
of 1.2, 1.5, 1.12 and 1.15 the marker's parent is `hive_root`, and on
entering 1.10 it is `meadow_root`.

**Regression checks.** The existing stage-sequence test.

**Check to file:** one check that no marker appears in the meadow at 1.12 or
1.15, and that the hive-side marker does appear.

## Slice 7 — Acceptance pass and documentation (absorbs old Bundle H)

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
