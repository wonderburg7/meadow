# Challenge 1 — the acceptance pass

<!-- CONTEXT: plan | LAYER: immediate-task -->
Status: active | Owner: Dave / Claude Code | Next: Slice 24 -- the stage marker is never left in the wrong world (blocked until H4 lands) | Dependency: Slice 24 needs H4 (`plans/design/architecture-review.md`, queued but not yet landed) to land first; Slice 26 waits on Slice 24; Slice 7 waits on both | Verified: 2026-09-11

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

Slices 20, 21, 22, 23 and 25 have all shipped; their specifications are
archived (see the pointers above and `plans/archive/`). What remains:

| Slice | What it fixes | Files | Level |
| --- | --- | --- | --- |
| 24 | A stage marker appears in the meadow at 1.12 (yellow dot) | `challenge_runner.gd` | low |
| 26 | The marker does not pulse, and vanishes when off screen | `challenge_runner.gd`, `hud.gd` | medium |
| 7 | The acceptance playthrough and copy pass | docs | -- |

Slice 26 depends on Slice 24, which is the other open change to the same
marker node. Slice 7 runs last.

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

## Slice 24 — the stage marker is never left in the wrong world

**Reasoning level: low.** One missing guard, already written twice in the
same function.

**Confirmed root cause.** `challenge_runner.gd::_update_marker()` (`:519`)
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

## Slice 26 — the stage marker asks to be noticed, and says where it is

**Reasoning level: medium.** One existing node gains an animation, and one
new HUD element has to avoid the panels already on screen.

**Purpose and intended outcome.** A player who has been told to right-click a
marked place can find it, whether it is on screen or not. Two of Dave's 10
Sep 2026 asks are answered together because both are about the same node.

**Status and dependencies.** Follows Slice 24, which is the other open change
to the same marker in the same file. Take Slice 24 first; this slice assumes
the marker is in the world the player is looking at.

**What Dave asked (10 Sep 2026).**

- "Make the yellow 'move here' symbols pulse so they get the player's
  attention."
- "If a yellow 'move here' symbol is off screen, show an arrow at the closest
  point on the screen guiding the player to the symbol. Consider how panels
  could obscure this so it's still visible."

**Established.** There is exactly one marker: `challenge_runner.gd`'s
`_marker`, a `Polygon2D` created in the runner's setup, coloured
`Stages.MARKER_COLOUR`, re-parented between `hive_root` and `meadow_root` and
positioned by `_update_marker(stage_id)` and `_show_current_visit_point()`.
It has no animation of any kind and no screen-space counterpart. Challenge 2
never shows one.

**Current authoritative owner.** `scripts/challenge_runner.gd` owns the
marker's existence, world and position. `scripts/hud.gd` owns everything
drawn in screen space, including the panel rectangles the off-screen arrow
has to avoid. That split is the design: the runner must not draw to the
screen, and the HUD must not decide where the marker is.

**Required reading.** This heading, `challenge_runner.gd::_update_marker` and
`_show_current_visit_point`, `scripts/ui_layout.gd`'s persistent-rectangle
owners, and `scripts/camera_view.gd` for how world coordinates reach the
screen.

**Files likely to change.** `scripts/challenge_runner.gd`, `scripts/hud.gd`.

**Files that must not be changed.** `scripts/ui_layout.gd` — the arrow reads
the panel rectangles it already publishes and adds none.
`scripts/challenge_stages.gd` — no stage data changes.

**Requirements.**

1. While `_marker.visible`, it pulses: a smooth, continuous change of scale
   or alpha, on a period slow enough to read as a heartbeat rather than a
   flash. Drive it from a `Tween` set to loop, created when the marker is
   shown and killed when it is hidden, not from a `_process` accumulator.
2. The pulse uses unscaled time, so it does not speed up at 4x game speed.
   Stage 1.11 and 1.14 both set 4x while a marker can be showing, so this is
   a real case, not a hypothetical.
3. When the marker is visible but its screen position falls outside the
   viewport, the HUD shows one arrow at the viewport edge, pointing along the
   line from the screen centre to the marker. It disappears the moment the
   marker is on screen.
4. The arrow is clamped inside the rectangle left over once the persistent
   panels are excluded — the summary panel, the command tray and Dr
   Gallerin's bubble along the bottom, and the corner readout at the top.
   Read those rectangles from `ui_layout.gd`'s existing owner functions; do
   not restate their geometry. If the true edge point falls behind a panel,
   slide the arrow along that edge to the nearest point that is not, keeping
   its rotation pointing at the marker.
5. The runner publishes the marker's global position and visibility to the
   HUD through a signal or a single query, in the direction the codebase
   already uses (`challenge_runner` pushes to `hud` via setters, as
   `_apply_stage_gate_to_ui` does). The HUD must not reach into
   `challenge_runner` for it.

**Constraints and invariants.** Presentation never gates simulation: neither
the pulse nor the arrow may change when a stage completes or where the marker
is. The arrow is drawn only while a Challenge is active and a marker is
visible; Challenge 2 and open play show nothing. No new persistent panel — the
arrow is a lightweight overlay and must not enter the bottom-row layout.

**Existing patterns to reuse.** `Stages.MARKER_COLOUR` for the arrow, so the
two read as the same thing. `Shapes` for the arrow polygon, matching the
codebase's flat-polygon placeholder art. `ui_layout.gd`'s rectangle owners
for the exclusion zone.

**State-transition and cleanup behaviour.** Hiding the marker kills the tween
and hides the arrow in the same call, so a stage ending cannot leave either
running. Switching between hive and meadow view hides the arrow if the marker
is in the other world — a marker in the hive is not "off the right-hand edge"
of the meadow, and an arrow pointing at it would be a lie. Slice 24 is what
makes the marker's world reliable, which is why this slice follows it.

**Runtime policy.** The arrow's position is recomputed per frame while it is
visible, from one world-to-screen transform and a rectangle clamp. That is
cheap and bounded. The tween costs nothing per frame. Neither may allocate
per frame.

**Edge cases.** The marker exactly on the viewport edge, where the arrow must
not flicker on and off — hysteresis, or a small inset, and say which. The
camera following the queen while the marker is behind her. A viewport resize
with the arrow showing. The player in hive view at stage 1.10, whose marker
is in the meadow.

**Automated acceptance checks.** A headless assertion that with the camera
moved far from the marker the arrow node is visible, its rotation points
within a few degrees of the true bearing, and its rectangle does not
intersect any of the three bottom-row panel rectangles; and that with the
camera on the marker the arrow is hidden. LAY-5's `panel_rect` and LAY-6's
`control_rect` are the helpers for the intersection test.

**Regression checks.** Slice 24's assertion that the marker is never shown in
the world the player is not looking at. Stage 1.4's and 1.7's ordered visits,
where the marker moves between three points in turn.

**Save/load.** None. The marker and the arrow are both rebuilt from the
current stage.

**Completion and documentation updates.** Update the glance table and Status
line, archive this heading, and file one check: at a stage with a marker,
that it pulses, and that walking the camera away puts an arrow at the edge
which is never hidden behind a panel.

**Escalate rather than guess if:** requirement 4 cannot be satisfied at
800x600, where the three bottom-row panels plus the corner readout may leave
too little clear edge for an arrow to be visible at all. That would be a
question about the bottom row's footprint, not about this arrow.

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
