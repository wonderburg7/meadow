# Challenge 1 — the acceptance pass

<!-- CONTEXT: plan | LAYER: immediate-task -->
Status: active | Owner: Dave / Claude Code | Next: Slice 25 -- the queen's harvest is never thrown away without her being told | Dependency: Slice 26 waits on Slice 24; Slice 7 waits on all of 21-26 | Verified: 2026-09-10

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

## Open slices at a glance

| Slice | What it fixes | Files | Level |
| --- | --- | --- | --- |
| 25 | The queen's harvest is discarded whenever the comb is full | `challenge_runner.gd`, `challenge_stages.gd`, `bee_foraging.gd` | high |
| 21 | The queen will not start pollen foraging unaided (C-7) | `bee.gd`, `bee_foraging.gd` | high |
| 22 | The pollen stage's camera never follows (C-29) | `challenge_runner.gd`, `camera_view.gd` | medium |
| 23 | A Challenge 1 nectar cell is full at 150, not 200 | `challenge_stages.gd`, `challenge_runner.gd` | low |
| 24 | A stage marker appears in the meadow at 1.12 (yellow dot) | `challenge_runner.gd` | low |
| 26 | The marker does not pulse, and vanishes when off screen | `challenge_runner.gd`, `hud.gd` | medium |
| 7 | The acceptance playthrough and copy pass | docs | -- |

Slice 26 depends on Slice 24, which is the other open change to the same
marker node. Slices 21, 22, 23 and 24 are otherwise independent of each
other. Slice 7 runs last.

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

**Reasoning level: high.** A resource-loss rule with no stage gate, sitting
in the deposit path every bee in the game uses. The fix is small; getting its
boundary right is not.

**Purpose and intended outcome.** A load the player watched the queen gather
is never silently destroyed. Challenge 1 stops dead-ending when the comb
fills, and the one case where discarding really is the least-bad answer is
narrowed to the stage that needs it and is announced when it happens.

**Status and dependencies.** Ready. Independent of Slices 20 to 24; it can
land before or after any of them. It touches
`scripts/challenge_runner.gd`, which Slice 20 also touches, so the two must
not run at the same time in the same lane.

**Observable problem (Dave, 10 Sep 2026).** "In Challenge 1, after you filled
up the nectar cell, if you take the queen out and right-click on a flower so
she continues to forage nectar, then when you right-click the hive for her to
return home, she moves to the hive icon, all the resources that she's
carrying disappear and she continues to forage. So she doesn't actually
return to the hive or attempt to deposit anything. The resources just
disappear. And then there's no way for her to return and the challenge gets
stuck."

**Confirmed root cause.** `bee_foraging.gd::go_to_deposit_cell` reaches a
branch that sets `bee.current_load = 0.0`, clears `current_load_type` and
sends the bee back out, whenever `hive.find_cell_for()` returns null, the
comb is not empty, and `challenge_runner.discards_overflow(bee)` is true. The
comment above that branch states the intent exactly: "Challenge 1 only: by
the pollen stage both built cells hold nectar, so a nectar trip genuinely has
nowhere to go until the player designates a cell for pollen."

`challenge_runner.gd::discards_overflow` does not implement that intent. It
is:

```
active and Session.starting_level == 1
and is_instance_valid(main.queen) and bee == main.queen
and bee.current_load_type == "nectar"
```

There is no stage in it. It is therefore true for the queen carrying nectar
at *every* Challenge 1 stage, including 1.11 the moment the nectar cell
fills, and 1.12 while the player is being asked to build the second cell.
That is precisely Dave's reproduction: the first cell is full, no second cell
has space yet, the queen comes home, and the branch fires. Nothing tells the
player, so the only visible events are the load vanishing and the queen
leaving again.

**Contributing causes worth naming in the fix.**

- A comment carried the stage restriction and the code did not. The
  restriction has to live in the predicate.
- `discards_overflow` reads `Session.starting_level` to mean "this is
  Challenge 1". `challenge_runner` already knows which stage it is in; the
  stage is the thing the rule depends on and the level is not.
- The discard has no feedback path at all, while the neighbouring case —
  nectar sitting in the cell designated for pollen — has one
  (`_drive_c1_pollen_cell_nectar_prompt`). Two responses to one situation,
  only one of which the player can see.

**Current authoritative owner.** `scripts/challenge_runner.gd` owns the
predicate. `scripts/bee_foraging.gd` owns the deposit path and calls it.
`scripts/hive.gd`'s deposit search is not in scope.

**Required reading.** This heading; `bee_foraging.gd::go_to_deposit_cell`;
`challenge_runner.gd::discards_overflow` and
`_drive_c1_pollen_cell_nectar_prompt`; `docs/challenge-stages.md` for what
1.11 to 1.14 ask the player to do.

**Files likely to change.** `scripts/challenge_runner.gd`,
`scripts/challenge_stages.gd`, `scripts/bee_foraging.gd`.

**Files that must not be changed.** `scripts/hive.gd` — the deposit search
serves every bee in the game and is not at fault. `scripts/bee.gd`'s command
functions — `command_return_and_deposit` does the right thing and the load
survives it. `scripts/game_config.gd`.

**Requirements.**

1. Add `const C1_DISCARD_STAGES := ["1.14"]` to `scripts/challenge_stages.gd`
   beside the Challenge 1 stage table, with a comment saying why that stage
   and no other: it is the stage where the second cell is reserved for pollen
   and a nectar trip therefore has nowhere legitimate to go. If the
   implementer's trace shows 1.13 needs it too, add 1.13 and say so; do not
   widen it beyond that without escalating.
2. `discards_overflow` returns true only when the current stage id is in
   `C1_DISCARD_STAGES`, in addition to the four conditions it already tests.
   Read the current stage from the runner's own stage index, not from
   `Session.starting_level`, which stays only as the "this is Challenge 1"
   guard it already is.
3. When the discard does fire, the player is told once per occurrence, using
   the same `clear_queue()` then `show_now()` pattern
   `_drive_c1_pollen_cell_nectar_prompt` uses, with a line saying that the
   comb has no room for nectar and what to do about it. Do not add a second
   prompting mechanism.
4. At every stage *not* in `C1_DISCARD_STAGES`, a queen who comes home with a
   load the comb cannot take keeps it. That is what the general branch below
   already does — the fix is that she now reaches it — so requirement 4 is a
   test, not new code.
5. The player must be able to get out of the state requirement 4 creates.
   Confirm against the current build that a queen holding an undepositable
   load can still be commanded: "Empty this cell" on a full cell
   (`bee.gd::command_empty_cell`) and designating the new cell both free
   space. If neither is reachable at stage 1.12 because the controls are
   gated, say so and stop — that is a stage-gating slice, not this one.

**Constraints and invariants.** No bee outside Challenge 1 may ever lose a
load. `bee_foraging.gd`'s general "keep the load until a cell changes" branch
and its `deposit_blocked_epoch` guard are correct and stay. The
`autonomous_state()` wrapper rule holds: any transition this slice adds in
`bee_foraging.gd` goes through it, or is marked `# player-command`, and
`tests/source_checks.py` enforces that.

**State-transition and cleanup behaviour.** A stage leaving
`C1_DISCARD_STAGES` must not leave a bee mid-discard. The discard is a single
frame's decision inside `go_to_deposit_cell`, so there is no state to unwind;
assert that rather than assuming it. The once-per-occurrence prompt timer
resets on stage entry, as the existing pollen-cell prompt's does.

**Runtime policy.** `discards_overflow` is called from the deposit path, which
runs per think tick per returning bee. Its added stage lookup must be an
index read, not a search through the stage table.

**Edge cases.** The queen carrying pollen rather than nectar at 1.14. A
checkpoint restore mid-trip. The player designating the second cell for
pollen while she is already inside the hive holding nectar. Two cells both
full at 1.14, which is the case the discard exists for. A save taken with the
queen holding an undepositable load.

**Automated acceptance checks.** A headless scenario that drives Challenge 1
to stage 1.12 with the first cell full, sends the queen to a flower and home
again, and asserts her `current_load` is unchanged on arrival and that the
colony's nectar total did not fall. A second scenario at 1.14 asserting the
discard still fires there and that a prompt was shown in the same tick.

**Regression checks.** The nectar arc at stage 1.11, which passes today
(C-7's nectar half, C-29's nectar stage). A non-Challenge run with a
deliberately full comb, asserting a forager keeps her load — the general
branch must be untouched.

**Save/load.** `current_load` and `current_load_type` are saved per bee.
Requirement 4 means a save can now contain a queen holding an undepositable
load, which was previously impossible in Challenge 1. Confirm the save
round-trips it and that she resumes rather than stalling on load.

**Completion and documentation updates.** Update this plan's glance table and
Status line, archive this heading, regenerate `docs/challenge-stages.md` with
`python tools/stage_reference.py` if the stage table changed, and file one
hands-on check covering Dave's exact reproduction.

**Escalate rather than guess if:** the trace shows the discard is also
reachable for a bee that is not the queen, or outside Challenge 1. Either
would mean resource loss in open play, which is a different and larger
problem than this slice.

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

**Second report (Dave, 10 Sep 2026, C-7).** The same symptom, located more
precisely: "In Challenge 1 the queen doesn't automatically start moving when
assigned the forager/pollen role -- she does for the forager/nectar role. She
only starts automatically moving once she's in the meadow. But this should
start when initially assigned the role in the hive." So she is stalled
*inside* the hive, and leaving the hive by any means clears the stall. That
matches the leading hypothesis below rather than contradicting it: a carried
load is only in the way while she is indoors, where the deposit dispatch
runs. Confirm it against the trace all the same.

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
to 1x correctly, but the camera never follows the queen. Dave re-ran this on
10 Sep 2026 and reported it unchanged: the nectar stage passes outright, and
at the pollen stage "speed stops and starts for the pollen foraging, but the
camera following doesn't start". Two passes, one symptom, no drift -- the
trace below is still the right first move. Separately, at the
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
