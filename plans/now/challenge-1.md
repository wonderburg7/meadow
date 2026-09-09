# Challenge 1 — the acceptance pass

<!-- CONTEXT: plan | LAYER: immediate-task -->
Status: active | Owner: Dave / Claude Code | Next: Slice 16 -- the queen works more than one flower at 1.11 | Dependency: none -- Slices 16 to 19 are startable today | Verified: 2026-09-09

**Objective.** Challenge 1 teaches the game's core loop without ever
advancing on behaviour the player did not command. Every code slice is
shipped; what remains is one acceptance playthrough and its copy pass.

**State.** Slices 1-6 and 8-15 are code-complete and merged (last: 3 Sep
2026). Dave ran C-7 on 9 Sep 2026, the first run possible since LAY-2
restored the command tray, and the automatic-foraging arc failed in five
distinct ways. Those became **Slices 16 to 19** below, per this plan's own
rule that a finding from its acceptance run becomes its next slice while it
is open. Slice 7, the acceptance playthrough, now runs after them.

**What C-7 found, 9 Sep 2026.** Dave's five reports, in the order the player
meets them:

1. At 1.11 the queen "is just visiting a single flower before returning to
   deposit nectar. she should visit multiple flowers. same for pollen."
2. At 1.13 "the queen does not automatically start foraging for pollen, only
   when I right click the nest entrance does she visit a flower and come back
   to the hive".
3. "she doesn't auto deposit pollen, she just waits at the inner entrance to
   the hive".
4. "she doesn't manually deposit pollen either, she goes to the cell but then
   goes to a particular place in the hive after without having deposited".
5. "after building the second cell, and the queen collecting pollen there's a
   risk of her depositing left over nectar in the second cell, which breaks
   the flow of the challenge and can be confusing for the player, as there's
   then nowhere to deposit pollen unless the player realised they need to
   make a new cell." Dave also reported "4x speed doesn't reset at the stage
   ends".

Reports 3, 4 and 5 are one defect seen from three angles: nothing in the hive
will accept pollen, because both built cells hold nectar. Slice 18 is that
one.

**Open slices.** Slices 16 to 19, then Slice 7. Nothing else may be added --
a finding from Slice 7's own run becomes this plan's next slice while it is
open, and a finding after it closes starts a new `plans/now/` file.

**Authoritative files.** Stage data: `scripts/challenge_stages.gd`.
Sequencing and gating: `scripts/challenge_runner.gd`. The
"player drives this bee" flag and the state machine: `scripts/bee.gd`.
Foraging transitions: `scripts/bee_foraging.gd`. Cell storage rules:
`scripts/hive_cell.gd`, `scripts/hive.gd`.

**Required reading.** This file only. The delivered slices are archived at
`plans/archive/CHALLENGE1_SLICES_11-15_2026-09-03.md` and
`plans/archive/CHALLENGE1_SLICES_1-10.md`; open them for provenance, never to
work out what to do.

**Reasoning level.** Low for Slice 16. Medium for Slices 17 and 19. High for
Slice 18, which adds a stage, changes what a cell accepts and gives the queen
a job she could not do before.

**Slice numbering starts at 16 on purpose.** C-7's `Owner:` line named "Slice
14", a slice archived on 3 Sep, so the check pointed at a specification
nobody could open. New slices never reuse a retired number.

## Slice 16 — the queen works more than one flower at 1.11

**Reasoning level: low.** Delete one stage effect and its counterpart.

**What Dave reported.** At 1.11, "automate nectar gathering", the queen works
one flower, flies home, deposits, and goes straight back to the *same*
flower, for the whole stage.

**Cause.** `scripts/challenge_stages.gd`, stage `1.11`, carries
`"on_enter": ["lock_flower_target:queen"]`. That effect sets
`Bee.flower_switch_locked`, and every autonomous transition in
`scripts/bee_foraging.gd` that would otherwise pick a new flower reads it:
lines 454, 485, 636 and 717 all send her to `State.TO_HIVE` instead of
`State.SEEK_FLOWER` while it is set. The lock is right for the manual arc
(1.8 to 1.10), where the player picks each flower; it is exactly wrong for
the stage whose whole point is that she now chooses for herself.

**Deliver, in `scripts/challenge_stages.gd`.**

- Remove `"on_enter": ["lock_flower_target:queen"]` from stage `1.11`.
- Remove `"unlock_flower_target:queen"` from stage `1.11`'s `on_exit`,
  leaving the other three effects in place and in their current order.
- Leave the `lock_flower_target:queen` and `unlock_flower_target:queen` cases
  in `challenge_runner.gd::_run_stage_effects()`. They are still the
  documented mechanism, and `_run_stage_effects` pushes an error for an
  unknown effect, so a later stage can use them without re-adding code.

**Do not touch `flower_switch_locked` itself.** No other stage sets it, and
the field is what a future "work this one flower" order would use.

**Acceptance.** At 1.11 the queen fills up at one flower, flies home,
deposits, and then flies to a *different* flower, repeating until the nectar
cell is full. The same for pollen once Slice 17 lands.

**Check to file:** covered by C-7's rewritten first condition.

## Slice 17 — changing a bee's focus wakes her up

**Reasoning level: medium.** One guarded branch in the shared bee state
machine, so it must not disturb bees that are mid-errand.

**What Dave reported.** At the pollen stage the queen does nothing at all.
Only right-clicking the nest entrance, a player command, gets her moving.

**Cause.** Stage `1.11`'s `on_exit` runs `freeze_bee:queen`, which parks her
in `State.IDLING`. `scripts/bee.gd`'s state machine handles that state with
`pass   # waits for orders and nothing else`, so nothing dispatches her
again. Assigning a *role* would wake her, because `_apply_role()` ends by
setting `state = _default_state_for_role()`. Changing her *focus* does not:
`Bee.set_focus()` (`scripts/bee.gd:1790`) deliberately leaves the state alone
when the bee is inside the hive, on the reasoning that `_go_to_exit()` will
call `_default_state_for_role()` once she walks out. A bee parked on `IDLING`
never walks out, so the focus change lands on a bee that will never act on
it. The build-a-cell stage sits between the freeze and the focus change,
which is why this only shows up at the pollen stage.

**Deliver, in `scripts/bee.gd`, in `set_focus()`.** Replace the final

```gdscript
if not _is_inside_hive():
    state = State.SEEK_FLOWER
```

with a three-way branch, keeping the existing comment about meadow
coordinates and adding one for the new case:

- Not inside the hive: `state = State.SEEK_FLOWER`, exactly as now.
- Inside the hive and `state == State.IDLING`: `state = State.IN_HIVE_TO_EXIT`,
  so she walks out through the entrance the ordinary way and `_go_to_exit()`
  picks the new resource type up on arrival. Comment this branch with the
  phrase **a bee parked on IDLING** -- `NEXTSTEPS.md`'s `Proof:` line for this
  slice asserts that phrase is absent until the slice lands.
- Inside the hive and any other state: leave the state alone, as now. A bee
  carrying a load to a cell must finish that walk.

**Why `IN_HIVE_TO_EXIT` and not `SEEK_FLOWER`.** The comment already in
`set_focus()` says why: a bee parented under `hive_root` reads a meadow
position as a hive-local offset and drifts to a meaningless spot. Sending her
to the exit keeps her inside the existing entrance-crossing path.

**This is safe for every caller.** `set_focus` already refuses any bee that
is not a Forager, primary or secondary (`scripts/bee.gd:1797`), so the only
bees this can wake are ones whose job is to be out foraging.

**Acceptance.** At the pollen stage, selecting the queen and pressing Pollen
sends her out of the hive and to a flower with no further input. At 1.11,
giving her Forager with nectar focus does the same. A forager already walking
a load to a cell when her focus is switched still delivers that load first.

**Check to file:** covered by C-7's rewritten second condition.

## Slice 18 — pollen has somewhere to go, and the player learns why

**Reasoning level: high.** Adds a Challenge stage, changes what a cell
accepts, and gives the queen a job she could not previously do. Read the
whole slice before starting.

**What Dave reported.** Three symptoms, one cause. She waits at the inner
entrance holding pollen; a manual deposit walks her to the cell and then
elsewhere without depositing; and leftover nectar can fill the second cell,
after which "there's nowhere to deposit pollen unless the player realised
they need to make a new cell".

**Cause.** `HiveCell.space_for()` (`scripts/hive_cell.gd:682`) returns `0.0`
for any resource that is not the cell's current `content_type`. By the pollen
stage both built cells hold nectar, so `Hive.find_cell_for("pollen")` returns
`null`. `BeeForaging.go_to_deposit_cell()` (`scripts/bee_foraging.gd:801`)
then sets `deposit_blocked_epoch` and **returns holding the load**, by
design — that guard is what stopped a full comb silently erasing foraging
trips. The manual deposit fails at the same check for the same reason.
Nothing is broken; the hive genuinely has nowhere to put pollen, and nothing
tells the player so.

**Dave's decision, 9 Sep 2026,** asked for four things together, and all four
are this slice:

> "when the first cell reaches max capacity, make any additional nectar the
> queen is carrying disappear, teach designating a cell. make it so selecting
> 'emptying the cell' can be carried out by the queen (without any additional
> roles happening). if nectar is in the second cell, have the Dr tell the
> player so they know to either empty the cell or make a new one."

**Deliver in five parts, in this order.**

**(a) Overflow nectar disappears, in `scripts/bee_foraging.gd`.** In
`go_to_deposit_cell()`, in the branch that currently sets
`bee.deposit_blocked_epoch` and returns, add a Challenge-1-only case *before*
that line: if the bee is the queen, the load type is `"nectar"`, and
Challenge 1 is active, discard the load (`bee.current_load = 0.0`,
`bee.current_load_type = ""`) and fall through to `State.IN_HIVE_TO_EXIT`
instead of holding it. Route the "is Challenge 1 active" question through one
new method on `challenge_runner.gd`, for example
`func discards_overflow(bee) -> bool`, rather than reading `Session` from
inside the foraging file. The simulation must not grow a second opinion about
which Challenge is running.

Leave the general path exactly as it is. Outside Challenge 1 a full comb must
still keep the load; that guard is load-bearing and its own comment says so.

**(b) A new stage teaching cell designation, in `scripts/challenge_stages.gd`.**
Insert a stage between the existing `1.12` (build a second cell) and `1.13`
(automate pollen gathering). The stage ids are the player-visible sequence
and `docs/challenge-stages.md` is generated from this file, so renumber
rather than inventing a `1.12a`: the new stage becomes `1.13` and every later
stage moves up one, ending at `1.20`.

The new `1.13`:

- `"goal": "cell_designated"` — that goal function already exists, used by
  Challenge 2's stage `2.3`. Reuse it; do not write a second one.
- `"unlocked_keys"`: stage `1.12`'s list plus `"cell_designation"`.
- `"goal_text": "Goal: set the new cell aside for pollen."`
- `"instruction": "designate the second cell for pollen"`.
- Prompts in Dr Gallerin's voice: a `welcome` at delay 0.0 explaining that a
  cell can be reserved for one thing, and a `hint` at `HINT_DELAY` saying to
  select the empty cell and choose Pollen.

Then find every place a Challenge 1 stage id appears as a literal and update
it. `challenge_runner.gd` alone has `1.1`, `1.4`, `1.7`, `1.8`, `1.11`,
`1.16` and `1.18` in `_enter_stage()`, plus the `1.11`/`1.13` pair in
`_drive_c1_forage_effects()`. Work through `grep -rn "1\.1" scripts/` rather
than from memory: getting one wrong moves a stage effect onto the wrong
stage, and that failure is invisible until someone plays it.

Finally run `python tools/stage_reference.py` to regenerate
`docs/challenge-stages.md`. `tools/verify.ps1` re-runs it with `--check` and
fails if it was not regenerated.

**(c) Challenge 2's stage `2.3` now teaches this second.** Stage `2.3`'s goal
is also `cell_designated`, and its prompts introduce designation as new.
Reword `2.3_welcome` and `2.3_hint` as a reminder instead, and say in the
commit message that this is why. Do not remove the stage: Challenge 2 can be
started without Challenge 1.

**(d) The queen can empty a cell, in `scripts/bee_building.gd`,
`scripts/bee.gd` and `scripts/hud.gd`.** Emptying a cell today is Comb Worker
work: `builder_evict()` and `builder_go_to_haul_target()` run only from the
builder states, and Challenge 1 forbids the queen ever taking `Role.BUILDER`,
as primary or as backup. That durable rule is at the foot of this file and
must not be weakened.

Add a **player-commanded** eviction instead, the same shape as the existing
`command_*` calls:

- `Bee.command_empty_cell(cell)` sets `target_cell` and assigns the eviction
  states directly, each line marked `# player-command` so
  `tests/source_checks.py`'s autonomous-transition rule passes. The bee's
  `role` is never touched.
- Reuse `bee_building.gd`'s existing eviction and haul steps. Where those
  functions branch on the builder role, lift that into a parameter or a plain
  check on the current state so one code path serves both callers. Do not
  copy the functions.
- Issue the command from the cell's own controls: add an "Empty this cell"
  button to the comb-cell group in `hud.gd::_build_cell_group()`, shown when
  the cell holds anything at all, and gated by `allowed_role_keys` the way
  the other cell actions are.

**(e) Dr Gallerin says when nectar is in the pollen cell.** In
`challenge_runner.gd`, while the renumbered pollen stage is current, check
once per second whether any cell whose `designated_type` is `"pollen"` has
`content_type == "nectar"`. If one does, call
`main.gallerin_panel.clear_queue()` and then `show_now()` with a
non-repeatable prompt saying the pollen cell has nectar in it, and that the
player can either empty it or build another cell. `clear_queue()` before
`show_now()` is required, and is the same ordering `plans/now/challenge-2.md`
Slice 2 fixes for the rescue line — without it the stage's own hint
overwrites this within seconds.

**Acceptance.** Play 1.11 through to the end of the pollen stage without
touching the debug panel. The queen fills the first cell with nectar and any
surplus she is carrying disappears rather than stranding her. The new
designation stage asks the player to set the second cell aside for pollen and
will not advance until they do. She then forages pollen and deposits it in
that cell unaided. If nectar is somehow in the pollen cell, Dr Gallerin says
so, and the "Empty this cell" button lets the queen clear it with no role
change and no second bee.

**Checks to file:** three, one condition each — the automatic pollen deposit,
the designation stage, and the queen-run cell emptying.

## Slice 19 — the stage's automation switches off when the stage ends

**Reasoning level: medium.** A small change, but it is about event ordering.

**What Dave reported.** "4x speed doesn't reset at the stage ends."

**The likely cause, to confirm first.** Both `1.11` and the pollen stage
declare `"on_exit": ["camera_follow_off", "speed_multiplier:1.0", ...]`, and
`challenge_runner.gd::_advance()` runs `on_exit` before `_enter_stage()`, so
the reset does exist in the code. The pollen stage, however, could not
complete at all in Dave's run — Slices 17 and 18 are why. A stage that never
ends never runs its `on_exit`, which accounts for the speed staying at 4x.

**So start by re-running it.** With Slices 16 to 18 merged, play 1.11 and the
pollen stage to completion and watch the speed readout. If it returns to 1x
both times, this slice delivers only its guard below, and says so in the
commit message.

**Deliver either way, in `scripts/challenge_runner.gd`.** Make the reset
independent of a stage completing normally. `_complete()` already clears
`_c1_forage_effects_done`; give it, and the checkpoint-restore path, an
explicit `_run_stage_effects(["camera_follow_off", "speed_multiplier:1.0"])`,
so an abandoned, restored or completed Challenge never leaves the player at
4x with the camera locked to a bee.

**If the speed still persists after a normal stage end,** the second place to
look is `scripts/debug_panel.gd:536` and `:872`, which set
`Engine.time_scale = 1.0` without updating `main.current_speed`. The two can
disagree, and `_refresh_speed_display()` reads `main.current_speed`. Fix by
routing both through `camera_view._on_speed_requested()`.

**Acceptance.** Finishing 1.11 returns the game to 1x speed and releases the
camera. The same at the pollen stage. Abandoning Challenge 1 from the
settings window does too.

**Check to file:** covered by C-7's rewritten third condition.

## Slice 7 — Acceptance pass and documentation (absorbs old Bundle H)

**Run after Slices 16-19 land.** The 29 Aug, 30 Aug, 2 Sep and 9 Sep attempts
at this pass are what found Slices 8, 9/10, 11/13 and 16-19 respectively.
Starting it before the automatic-foraging arc works only rediscovers C-7.

Once Slices 16-19 are in:

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
  across the new/changed lines (1.10, 1.12, 1.13 especially), update any
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
