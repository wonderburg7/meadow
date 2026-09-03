# Challenge 1 — Slices 11-15, delivered 2-3 September 2026

<!-- CONTEXT: archive | LAYER: history -->
Status: archived | Owner: Dave / Claude Code | Next: None — archived record | Dependency: none | Verified: 2026-09-03

Provenance only. These five slices are shipped and merged; their hands-on
confirmations are C-7 and C-8 in `checks/ready.md`. The live plan is
`plans/now/challenge-1.md`, which holds only Slice 7 (Dave's acceptance
pass) and this area's durable rules. Do not reopen anything here — a new
finding against Challenge 1 while that plan is open becomes its next
slice; a finding after it closes starts a new `plans/now/` file
(`plans/README.md`).

| Slice | What it did | Shipped |
| --- | --- | --- |
| 11 | Manual-forage stages: three unguarded autonomous transitions | 2 Sep 2026 |
| 12 | One authoritative `player_driven` flag, and a check that keeps it true | 3 Sep 2026 |
| 13 | The queen's "Now:" line says things Challenge 1 has not taught | 3 Sep 2026 |
| 14 | 1.11 hand-over: the queen parks at the flower; stage camera/speed effects cancelled as set | 3 Sep 2026 |
| 15 | "Now:" tells the player what to do, not what she cannot do | 3 Sep 2026 |

---

## Slice 11 — Manual-forage stages: three unguarded autonomous transitions — DONE 2 Sep 2026

**Symptom (Dave, 2 Sep 2026).** Through 1.6-1.10 the queen still forages on
her own. After the player right-clicks the first flower she flies on to
another flower by herself and drinks from it. She *does* correctly stop at
the flower once her crop is full. After the manual deposit at 1.10 she walks
straight back out of the hive and resumes foraging. Then at 1.11 there is no
Forager option to give her, so the run cannot continue at all.

**Root cause — three specific transitions, each traced to a line.**

1. `bee_foraging.gd::finish_collecting()`, last statement:
   `bee.state = State.TO_HIVE if bee.current_load >= max_capacity(bee) else State.SEEK_FLOWER`.
   The `manual_deposit_pending` guard immediately above it covers only the
   *full crop* case. When the flower runs dry first (the
   `get_available(...) < GameConfig.min_worthwhile_amount` early exit
   further up the same function) she leaves with a part-load and falls into
   the `else` -- `State.SEEK_FLOWER`, which is the automatic flight to the
   next flower Dave sees. This is exactly his report: the full-crop case is
   guarded, the part-load case is not.
2. The deposit-completion path in the same file (after `add_resource` and
   `release_cell_slot`, the branch that ends `bee.state =
   State.IN_HIVE_TO_EXIT`). That is the forager's ordinary
   deposit-and-leave step and it has no manual-stage guard at all, so it is
   what sends her back out after 1.10's deposit.
3. `bee.gd::command_deposit_at()` sets `manual_deposit_pending = false` when
   the player *issues* the deposit command, not when the stage ends. By the
   time (2) runs, the flag that should have stopped it has already been
   cleared by the very command the stage asked the player to give.

**Why 1.11 then offers no Forager (the blocker, no separate bug).** With the
queen already working as a forager, `hud.gd::_build_job_row` reads her
current *working* role as Forager (Slice 10d's `_common_working_role()`),
skips Forager as "already doing it", and 1.11's `unlocked_keys` allow no
other role key -- so `items` is empty and the "Change to…" menu is never
added. The menu is behaving correctly; it is offering nothing because the
game already did the thing the stage was about to ask for. Fixing 1-3
removes the cause. **Do not change `_build_job_row`.**

**Fix, in order.**

- a) In `finish_collecting`, collapse the two trailing branches into one
  guard: if `bee.manual_deposit_pending`, set `bee.state = State.IDLING`
  *regardless of load*; otherwise keep today's `TO_HIVE` / `SEEK_FLOWER`
  choice. Delete the now-redundant
  `if bee.manual_deposit_pending and bee.current_load >= max_capacity(bee)`
  branch above it -- one guard, not two.
- b) In the deposit-completion path, make the final assignment
  `bee.state = State.IDLING if bee.manual_deposit_pending else State.IN_HIVE_TO_EXIT`.
- c) Remove the `manual_deposit_pending = false` line from
  `Bee.command_deposit_at()`. The flag is owned by
  `challenge_runner.gd::_enter_stage`, which already sets it per stage id
  (`stage.id in ["1.6", ... "1.10"]`) and clears it on entering 1.11; a
  command must never write it. Before editing, read
  `bee_foraging.gd::enter_hive` and confirm the in-flight manual deposit
  still routes correctly: `resume_pending_zone_command()` runs first and
  consumes `pending_deposit_cell`, so the `if bee.manual_deposit_pending:
  bee.state = State.IDLING` line below it is not reached on that path.

**Acceptance.** At 1.8, right-click a flower and let the queen work it dry
with a part-load: she stays at that flower and never sets off for another
one. At 1.10, after the manual deposit she stays inside the hive doing
nothing. At 1.11 the Job column shows "Change to… → Forager". Nothing
outside a Challenge changes: `manual_deposit_pending` is false for every
other bee in every other mode, so all three guards are inert there.

**Check:** `tools/verify.ps1`, then the Bundle D entry in `checks/ready.md`
(already rewritten to name this acceptance) plus the 1.10 -> 1.11 hand-over.

**Files:** `scripts/bee_foraging.gd`, `scripts/bee.gd`.

**Landed 2 Sep 2026** on `claude/c1-11`, all three fixes as written:
(a) `finish_collecting` now ends `if bee.manual_deposit_pending: IDLING`
with no load test, and the older full-crop-only guard is gone -- one guard,
not two; (b) `finish_depositing`'s last statement is
`IDLING if bee.manual_deposit_pending else IN_HIVE_TO_EXIT`; (c)
`Bee.command_deposit_at()` no longer writes `manual_deposit_pending`, so
`challenge_runner.gd::_enter_stage` is its only writer. `enter_hive` was
read first as the plan asked: `resume_pending_zone_command()` still returns
early on the `command_deposit_at_after_enter` path, so keeping the flag true
there does not divert the in-flight manual deposit. `_build_job_row` was not
touched. `input_selection.gd`'s cell branch is gated on
`current_load > 0.0`, so a post-deposit right-click falls through to an
ordinary move rather than re-entering the deposit command. Hands-on
acceptance is filed in `checks/ready.md` § Challenge 1 Bundle D.

**Next after:** Slice 12.

## Slice 12 — One authoritative "player drives this bee" flag, and a check that keeps it true — DONE 3 Sep 2026

**Why this slice exists.** Slice 11 is the sixth round of the same bug.
9a, 10a, 10b, 10f, 10g and now 11 were all "an autonomous state transition
somewhere in the bee state machine that nobody remembered to guard". The
rule "during these stages the player drives the queen" is currently spread
over five fields -- `manual_deposit_pending`, `role_change_locked`,
`flower_switch_locked`, `role_restricted_to`, `queen_command_locked` --
written in three places and read in nine, each named after the one symptom
that prompted it. Nothing anywhere lists the transitions that need
guarding, so every new one is found by playing the Challenge until it goes
wrong. That is the thing to change, not another guard.

**Fix, in three parts. Do all three; part 3 is the point of the slice.**

1. **Name the concept once.** Add `var player_driven: bool = false` to
   `bee.gd` with a doc comment saying: *while true, this bee makes no
   autonomous state transition of its own -- every state change comes from a
   `command_*` call or a Challenge stage effect.* Set it in exactly one
   place, `challenge_runner.gd::_enter_stage`, from a new
   `"player_driven": true` key on the stage dictionary in
   `challenge_stages.gd`. Add that key to stages 1.6, 1.7, 1.8, 1.9 and
   1.10 -- exactly today's `stage.id in [...]` list -- and read it with
   `stage.get("player_driven", false)` so no other stage needs the key.
   Clear it in `challenge_runner.gd::start()` and `_complete()` alongside
   the other per-run resets. No command ever writes it.
2. **One choke point.** Add to `bee_foraging.gd`:
   `static func autonomous_state(bee: Node2D, next: int) -> int:` returning
   `State.IDLING if bee.player_driven else next`. Route every autonomous
   transition in that file through it -- Slice 11's three, plus
   `finish_collecting`'s focus-change branch, `enter_hive`'s role-based
   branch, and the `IN_HIVE_TO_EXIT if bee._is_inside_hive() else
   SEEK_FLOWER` assignment near the drink/refuel path. Commands keep
   assigning `bee.state` directly; that distinction is the whole point.
   Then replace `manual_deposit_pending` with `player_driven` at its three
   read sites in `bee_foraging.gd` and its two in `input_selection.gd`, and
   delete the field. **Leave `role_change_locked`, `flower_switch_locked`,
   `role_restricted_to` and `queen_command_locked` alone** -- each enforces
   a different rule (role promotion, flower target, permitted backup work,
   command lock) and is correctly named for it. Only
   `manual_deposit_pending` is named after one stage's lesson rather than
   the rule it enforces.
3. **Make it enforceable.** Add a check to `tools/source_checks.py` that
   scans `scripts/bee_foraging.gd` and fails if `bee.state = State.` is
   assigned to `SEEK_FLOWER`, `TO_HIVE` or `IN_HIVE_TO_EXIT` anywhere
   except inside `autonomous_state()` itself or on a line whose trailing
   comment is `# player-command`. Follow the existing check style in that
   file (one function, appended to the same error list). This is what stops
   the seventh round: a new transition has to declare which kind it is
   instead of silently defaulting to autonomous.

**Acceptance.** `tools/verify.ps1` passes, including the new source check.
Deliberately breaking it (add a bare `bee.state = State.SEEK_FLOWER` to
`bee_foraging.gd`) makes `source_checks.py` fail with a readable message;
remove it again. Challenge 1's 1.6-1.10 behave exactly as Slice 11 left
them. Outside a Challenge, `player_driven` is false for every bee, so no
behaviour changes.

**Check:** `tools/verify.ps1`. One hands-on check to file: re-run Bundle
D's Slice 11 acceptance and confirm it still passes after the refactor.

**Files:** `scripts/bee.gd`, `scripts/bee_foraging.gd`,
`scripts/challenge_stages.gd`, `scripts/challenge_runner.gd`,
`scripts/input_selection.gd`, `tools/source_checks.py`.

### What landed, 3 Sep 2026

All three parts, as planned. Four notes on where the shipped slice differs
from the sketch above:

- **The checker lives at `tests/source_checks.py`,** not
  `tools/source_checks.py` as this plan and `NEXTSTEPS.md` both said. There
  is no `tools/source_checks.py`; `tools/verify.ps1` has always run the
  `tests/` one.
- **Thirteen transitions went through `autonomous_state()`, not six.** The
  plan named six; the source check in part 3 fails on *any* unwrapped
  assignment to `SEEK_FLOWER`, `TO_HIVE` or `IN_HIVE_TO_EXIT`, which is what
  makes it enforceable, so the rest of the file had to be honest too. The
  seven the plan did not name are the rained-off returns in `seek_flower`
  and `search_for_flower` (twice), the empty-meadow return, the
  flower-vanished branches in `inspect`, `drink_at_flower` and `collect`,
  `reject_flower`, the empty-handed arrival in `go_to_deposit_cell`, and the
  `deposit_everything_remotely` fallback. Each is a decision the bee makes
  for herself, so each is a route the seventh round of this bug could have
  taken.
- **`_enter_stage`'s write is guarded by `is_instance_valid(main.queen)`.**
  The write sits outside the `Session.starting_level == 1` block, because
  the stage dictionary now carries the rule and any Challenge can use it --
  but `_enter_stage` runs for Challenge 2 as well, where the queen can be
  dead, and the file guards `main.queen` everywhere else for that reason.
- **`tools/check_docs.py` needed a fix to make `verify.ps1` runnable from a
  worktree at all.** It resolved a ledger row's `.worktrees/x` path against
  the *running* checkout, so inside a worktree it looked for a nested copy
  that has never existed and reported every row stale. It now resolves
  against the primary checkout (`git rev-parse --git-common-dir`). This is
  pre-existing and unrelated to Challenge 1, but the slice could not be
  verified on its own branch without it.

**Acceptance evidence.** `tools/verify.ps1` green. The new check was broken
deliberately (a bare `bee.state = State.SEEK_FLOWER` added to
`bee_foraging.gd`) and reported
`bee_foraging.gd:475  unguarded autonomous transition -- wrap it in
autonomous_state(bee, ...) so a player-driven bee stays put, or mark the
line \`# player-command\``, then passed again once repaired. Both escape
hatches were tested too: the same line with a trailing `# player-command`
passes, and a bare assignment inside `autonomous_state()` itself passes.

**Next after:** Slice 13.

**Still to confirm by playing:** `checks/ready.md` § Challenge 1 Bundle D.

## Slice 13 — The queen's "Now:" line says things Challenge 1 has not taught — DONE 3 Sep 2026

**Ask (Dave, 2 Sep 2026):** the summary panel's "Now:" text options for the
queen should be reviewed so nothing appears that is not relevant to the
Challenge.

**Where it comes from.** `hud.gd` builds the line as
`"Now: %s" % b.task_description()`, and `bee.gd::task_description()` is one
large `match state:` covering every state in the game -- scouting bouts,
entrance mentoring, dancing, royal jelly, mining spoil, honey fanning. The
sibling `bee.gd::idle_reason()` has the same shape and the same problem, and
`_idle_backup_note()` appends "(backup role Nurse also has nothing right
now)" before backup roles have been introduced. None of this is gated on
`stage_gate`, so a Challenge-1 player can be shown vocabulary for mechanics
the Challenge deliberately has not reached yet.

**Fix.** Do not rewrite the vocabulary and do not add a second copy of it.

- a) Add `func challenge_vocabulary_limited() -> bool` to `bee.gd`,
  returning true when `world.challenge_runner != null and
  world.challenge_runner.active`. Use the same `is_instance_valid(world)`
  guard `finish_collecting`'s `_c1_queen_collections` line already uses.
- b) In `task_description()` and `idle_reason()`, when that returns true,
  fall back to a short neutral line for any state outside the set a
  Challenge actually reaches. The permitted set for Challenge 1 is:
  `SEEK_FLOWER`, `TO_FLOWER`, `COLLECTING`, `TO_HIVE`, `IN_HIVE_TO_CELL`,
  `DEPOSITING`, `IN_HIVE_TO_EXIT`, `MOVE_TO_POINT`, `IDLING`,
  `NURSE_IDLE`, `TO_BROOD`, `TENDING`, `TO_FEED_CELL`, `FEEDING`,
  `TO_BUILD_SITE`, `BUILDING`, and the queen's own laying chain
  `SEEK_POLLEN`, `TO_POLLEN_CELL`, `EATING`, `TO_CELL_TO_LAY`, `LAYING`
  (she lays from 1.1, so those are taught by the time she reaches them).
  Everything else returns
  `"busy in the hive"` from `task_description()` and `""` from
  `idle_reason()`.
- c) Suppress `_idle_backup_note()` entirely while
  `role_restricted_to` is non-empty -- that is already the exact signal
  that a Challenge is limiting which roles exist for this bee.

**Built (3 Sep 2026, `claude/c1-13`).** All three parts as specified, in
`scripts/bee.gd` only:

- `challenge_vocabulary_limited()` sits beside the two description
  functions and uses the same `is_instance_valid(world)` guard as
  `bee_foraging.gd`'s `_c1_queen_collections` line.
- `CHALLENGE_TAUGHT_STATES` is one const list of the permitted states, read
  by both `task_description()` and `idle_reason()` -- one decision, two
  call sites, and no second copy of the vocabulary. Outside the set,
  `task_description()` returns `"busy in the hive"` and `idle_reason()`
  returns `""`.
- `_idle_backup_note()` returns `""` whenever `role_restricted_to` is
  non-empty, so the backup-role note cannot appear before backup roles
  exist for that bee.

Nothing outside a Challenge changes: both gates are inert while
`challenge_runner` is null or inactive. `tools/verify.ps1` green,
`FUNCTION_MAP.md` regenerated for the new function, and a headless Godot
4.7.1 boot ran clean -- which is what proves the const list folds at parse
time.

**Acceptance (Dave's, now filed as a check).** Play Challenge 1 to 1.14
with the queen selected the whole way and read the "Now:" line at every
stage: every line names something the player has already been shown.
Outside a Challenge the line is unchanged -- check a scouting forager
still reads "scouting: bout 1 of 3…" in a Scenario.

**Next after:** Slice 7's acceptance pass, which is Dave's, not a queue
slice. With this landed, every code slice in this plan is done.

**Still to confirm by playing:** `checks/ready.md` § Challenge 1
selection-panel vocabulary (Slice 13).

## Slice 14 -- 1.11 hand-over: the queen parks at the flower, and the stage's own camera/speed effects are cancelled as they are set -- DONE 3 Sep 2026

**Symptom (Dave, 3 Sep 2026, running Bundle D and the 9i check).** Two
reports, one stage. (1) Once the player finally gives the queen the Forager
role at 1.11 she does not start her automatic round -- "she pauses on
flowers even when she has the forager role. She should only do this prior
to getting the forager role." (2) The 9i acceptance clause "automatic
nectar foraging locks her to one flower with camera-follow/4x speed
visibly firing" fails on its camera/speed half; every other 9a-9j item
passed.

**Root cause A -- `flower_switch_locked` was implemented as "stop", not as
"do not go to a different flower".** 1.11's `on_enter` runs
`lock_flower_target:queen`, which sets `Bee.flower_switch_locked`
(`challenge_runner.gd::_run_stage_effects`). `bee_foraging.gd::finish_collecting()`
then early-returns `bee.state = State.IDLING` whenever that flag is set.
That block sits *before* the crop-full test below it, so the first
completed bout -- full crop or flower run dry -- parks her at that flower
for the rest of the stage. Five sibling sites repeat the same substitution
when the flower vanishes underneath her: `inspect`, `drink_at_flower` and
`collect` in `bee_foraging.gd`, and two lines in `bee.gd` (one of them
`release_flower_reference`), each reading
`State.IDLING if flower_switch_locked else State.SEEK_FLOWER`.

This is the `manual_deposit_pending` lesson again (Slice 12): a lock named
for what it forbids, implemented as `IDLING` used as a catch-all. `IDLING`
is the right answer for `player_driven`, where the player supplies the next
state; it is the wrong answer for a lock that only rules out *one* of the
two autonomous options.

**Root cause B -- an `on_enter` effect is undone inside the same
`_enter_stage()` call.** `_enter_stage()` runs
`_run_stage_effects(stage.get("on_enter", []))` as its **first** statement.
About twelve lines later it calls `_apply_stage_gate_to_ui()`, whose last
line is `main.hud.update_selection(main.selected_bees)`, whose *first* line
is `follow_bee_toggled.emit(null, false)` -- which
`camera_view._on_follow_bee_toggled` turns into `main.following_bee = null`.
So `camera_follow_queen` is cancelled by the same function that set it, for
every stage, always. (`speed_multiplier:4.0` does survive, but it starts at
stage entry -- while the player is still being asked to assign the role --
rather than when the automatic round begins, so it does not read as part of
the foraging either.)

Stage entry is in any case the wrong moment for both: the player must
*select* the queen to give her the Forager role, and that selection emits
the same `follow_bee_toggled(null, false)`. The effects belong to the
moment automatic foraging actually starts.

**Fix, in five parts.**

- a) `bee_foraging.gd::finish_collecting()` -- delete the
  `if bee.flower_switch_locked:` early-return block entirely, and replace
  the function's last statement with a single `autonomous_state` call whose
  next state is `State.TO_HIVE` when either the crop is full **or**
  `bee.flower_switch_locked` is true, and `State.SEEK_FLOWER` otherwise.
  Comment it: a locked forager may still take her load home; what the lock
  forbids is going to find a *different* flower.

- b) The five "the flower has gone" sites -- `inspect`, `drink_at_flower`
  and `collect` in `bee_foraging.gd`, and the two matching lines in
  `bee.gd` -- change `State.IDLING if ...flower_switch_locked else
  State.SEEK_FLOWER` to `State.TO_HIVE if ...flower_switch_locked else
  State.SEEK_FLOWER`. A locked forager whose flower has vanished flies home
  rather than freezing; `go_to_deposit_cell` already handles an
  empty-handed arrival. Find them all with
  `grep -n flower_switch_locked scripts/*.gd` and change every read site,
  so none is left meaning "stop".

- c) `challenge_runner.gd::_enter_stage()` -- move
  `_run_stage_effects(stage.get("on_enter", []))` from the first line of
  the function to its last statement before
  `main.TutorialCheckpoint.save(main)`, with a comment saying why: an
  effect must not be undone by the gate/selection refresh that follows it.

- d) Fire 1.11's camera/speed effects when she actually starts foraging,
  not at stage entry. In `challenge_stages.gd`, remove
  `"camera_follow_queen"` and `"speed_multiplier:4.0"` from 1.11's
  `on_enter`, leaving `["lock_flower_target:queen"]`; leave 1.11's
  `on_exit` exactly as it is (it must still turn both off), and add
  `"camera_follow_off"` and `"speed_multiplier:1.0"` to 1.13's `on_exit`
  so the pollen stage cleans up the way the nectar one does. In
  `challenge_runner.gd`, add `var _c1_forage_effects_done: bool = false`,
  cleared in `_enter_stage()`, `start()` and `_complete()` beside the other
  per-stage/per-run resets, and in `_process()` -- inside the existing
  `Session.starting_level == 1` work, after the opening-mine branch -- run
  the two effects once, via the existing `_run_stage_effects([...])`, when
  all of these hold: the flag is still false, the current stage id is
  `"1.11"` or `"1.13"`, `is_instance_valid(main.queen)`, and
  `main.queen.state` is one of `SEEK_FLOWER`, `TO_FLOWER`, `INSPECTING`,
  `COLLECTING` (declare that list as one `const` beside the file's other
  constants; use whatever `Bee` reference the file already has in scope,
  `main.Bee.State` if there is none). Set the flag in the same branch.
  Comment it: the camera-follow and speed-up belong to the moment she sets
  off, because the player has to select her to assign the role and any
  selection change clears camera-follow.

- e) Make B unrepeatable. Add a check to `tests/source_checks.py`, in the
  style of the `autonomous_state` check Slice 12 added: read
  `scripts/challenge_runner.gd`, take the body of `func _enter_stage()`,
  and fail if the line calling `_run_stage_effects(` comes **before** the
  line calling `_apply_stage_gate_to_ui(`. Message: `challenge_runner.gd:
  _enter_stage runs on_enter effects before _apply_stage_gate_to_ui --
  update_selection() clears camera-follow, so the effect is cancelled as it
  is set. Run the effects last.`

**Acceptance.** At 1.11, give the queen Forager with nectar focus: the
camera starts following her and the speed goes to 4x as she sets off, not
before; she works one flower, flies home, deposits, and goes back out,
repeating until the nectar cell is full; at the stage end camera-follow
stops, speed returns to 1x and she stands still. The same at 1.13 for
pollen. Stages 1.6-1.10 are unchanged -- `player_driven`, not
`flower_switch_locked`, is what holds her there, and Slice 12's source
check still passes. Outside a Challenge nothing changes:
`flower_switch_locked` is false for every bee in every other mode.

**Check:** `tools/verify.ps1`, including the new source check (break it
deliberately by moving the `_run_stage_effects` call back to the top of
`_enter_stage`, confirm the message, put it back). One hands-on check to
file: the acceptance above, replacing the 9i clause in `checks/ready.md`.

**Files:** `scripts/bee_foraging.gd`, `scripts/bee.gd`,
`scripts/challenge_runner.gd`, `scripts/challenge_stages.gd`,
`tests/source_checks.py`.

**Landed 3 Sep 2026** on `claude/c1-14`, all five parts as written. (a)
`finish_collecting`'s trailing block is now one `autonomous_state` call:
`TO_HIVE` when the crop is full **or** the flower is locked, `SEEK_FLOWER`
otherwise -- the old `if bee.flower_switch_locked: IDLING; return` early
exit is gone. (b) All five "the flower has gone" sites now read `TO_HIVE if
...flower_switch_locked else SEEK_FLOWER`: the three in `bee_foraging.gd`
(`inspect`, `drink_at_flower`, `collect`) plus `bee.gd`'s `_process()`
`TO_FLOWER` branch and `release_flower_reference`. (c) `_enter_stage()` now
calls `_run_stage_effects(stage.get("on_enter", []))` as its last statement,
after `main.gallerin_panel.queue_prompts(...)` and immediately before
`main.TutorialCheckpoint.save(main)` -- `_apply_stage_gate_to_ui()` now runs
well before it. (d) 1.11's `on_enter` is just
`["lock_flower_target:queen"]`; `camera_follow_queen` and
`speed_multiplier:4.0` fire from a new `_drive_c1_forage_effects()`, called
from `_process()` every frame Challenge 1 is active, guarded by a new
`_c1_forage_effects_done` flag (cleared in `start()`, `_enter_stage()` and
`_complete()`) and firing once the queen is seen in `SEEK_FLOWER`,
`TO_FLOWER`, `INSPECTING` or `COLLECTING` while the stage id is `"1.11"` or
`"1.13"`. 1.11's `on_exit` is untouched; 1.13's now also carries
`camera_follow_off` and `speed_multiplier:1.0`. (e) `tests/source_checks.py`
gained `check_stage_effects_order`, scanning `challenge_runner.gd`'s
`_enter_stage()` body for a `_run_stage_effects(` call before
`_apply_stage_gate_to_ui(`; verified to fire (and to clear once reverted) by
temporarily reinserting the old top-of-function call during this slice.

`tools/verify.ps1` green, including the new check both broken and repaired.
Hands-on acceptance is filed in `checks/ready.md` as C-7, replacing the 9i
clause.

**Next after:** Slice 15.

## Slice 15 -- "Now:" should tell the player what to do, not narrate what she cannot do -- DONE 3 Sep 2026

**Ask (Dave, 3 Sep 2026, against Slice 13's own check).** Slice 13 stopped
the queen's "Now:" line naming untaught mechanics, but the line Dave still
sees at the stages that are waiting for him reads: *"Now: looking for brood
work. No pollen in the comb - she can't eat so she can't lay..."*. His
instruction: *"Instead of this say 'Now: waiting for instruction' or 'Now:
waiting for instruction [insert what the player should instruct her to do
for that stage]'."*

**Why Slice 13 did not catch it.** `NURSE_IDLE` is inside
`CHALLENGE_TAUGHT_STATES` -- correctly, since the Challenge does reach it
-- so the whole nursing-idle vocabulary is still permitted. The problem is
not that the sentence is untaught; it is that a stage waiting for a player
action should say what the action is. That is stage knowledge, and `bee.gd`
must not acquire any: the line is assembled in `hud.gd`
(`var activity := "Now: %s" % b.task_description()`, ~line 2396), which
already knows the world.

**Fix.**

- a) `challenge_stages.gd`: add a short `"instruction"` string to each
  `STAGES_1` entry -- imperative, no full stop, naming only what the player
  should do next. Use exactly these:
  - 1.1 `""` (nothing to do -- she is opening the tunnel)
  - 1.2 `"right-click the marked cavity to send her in"`
  - 1.3 `"left-click the queen to select her"`
  - 1.4 `"right-click each marked place in the cavity"`
  - 1.5 `"use Build cell, then click the marked centre"`
  - 1.6 `"right-click the marked doorway to send her outside"`
  - 1.7 `"right-click each marked place in the meadow"`
  - 1.8 `"right-click a flower to gather from it"`
  - 1.9 `"right-click another flower to gather from it"`
  - 1.10 `"right-click the hive, then right-click the wax cell"`
  - 1.11 `"give her the Forager role with nectar focus"`
  - 1.12 `"use Build cell to place a second cell"`
  - 1.13 `"switch her focus to pollen"`
  - 1.14 `"use Build cell to place a third cell"`

  Read it with `stage.get("instruction", "")` so no other Challenge needs
  the key. Stages beyond 1.14 keep no key and fall back to the bare line.
- b) `challenge_runner.gd`: add `func current_stage_instruction() -> String`
  returning `str(_stages()[_stage_index].get("instruction", ""))` while
  `active`, and `""` otherwise. Guard `_stage_index` against the stage
  list's size the way the file's other readers do.
- c) `hud.gd`, at the `"Now: %s"` line: when a Challenge is running
  (`main.challenge_runner != null and main.challenge_runner.active`), the
  bee is the queen, and she has no task of her own -- `b.state` is
  `Bee.State.IDLING` or `Bee.State.NURSE_IDLE`, or `b.player_driven` is
  true -- render `"Now: waiting for instruction"`, with `" -- %s"` and the
  instruction appended when `current_stage_instruction()` is non-empty. Do
  not call `task_description()` at all on that path, and leave the
  idle-reason line it feeds blank for the same case. Every other bee, and
  every other state, is untouched.

**Acceptance.** Play Challenge 1 to 1.14 with the queen selected: at every
stage that is waiting for the player the line reads "Now: waiting for
instruction -- <the action for this stage>", and at every stage where she
is genuinely working (walking, gathering, flying home, building, laying)
it still describes what she is doing. Outside a Challenge nothing changes.

**Check:** `tools/verify.ps1`. One hands-on check to file: the acceptance
above, replacing the Slice 13 entry in `checks/ready.md`.

**Files:** `scripts/challenge_stages.gd`, `scripts/challenge_runner.gd`,
`scripts/hud.gd`.

**Next after:** Slice 7's acceptance pass, which is Dave's run.

