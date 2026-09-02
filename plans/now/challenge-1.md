# Challenge 1 — current slice

<!-- CONTEXT: plan | LAYER: immediate-task -->
Status: active | Owner: Dave / Claude Code | Next: Slice 13 (the queen's "Now:" line names mechanics Challenge 1 has not taught), Claude lane | Dependency: none | Verified: 2026-09-03

Slices 1-6, 8, 9 and 10 are code-complete and merged to master (last: 1 Sep
2026). Their findings and traces are archived at
`plans/archive/CHALLENGE1_SLICES_1-10.md`; their outstanding hands-on
confirmations are in `checks/ready.md`. Bundle A-G's delivery evidence is at
`plans/archive/CHALLENGE1_REVAMP_PLAN.md` for provenance only; the old
Bundle H copy/doc pass is folded into Slice 7 below.

Dave's 2 Sep 2026 hands-on pass could not finish the Challenge: it stopped
at the 1.10 -> 1.11 hand-over. Slices 11-13 below are what came out of it.
Slice 11 is the fix, Slice 12 is the reason it kept happening, Slice 13 is
a copy finding from the same run.

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

## Slice 13 — The queen's "Now:" line says things Challenge 1 has not taught

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

**Acceptance.** Play Challenge 1 to 1.14 with the queen selected the whole
way and read the "Now:" line at every stage: every line names something the
player has already been shown. Outside a Challenge the line is unchanged --
check a scouting forager still reads "scouting: bout 1 of 3…" in a Scenario.

**Check:** `tools/verify.ps1`. One hands-on check to file: the read-through
above.

**Files:** `scripts/bee.gd`.

**Next after:** Slice 7's acceptance pass, which is Dave's, not a queue
slice.

## Slice 7 — Acceptance pass and documentation (absorbs old Bundle H)

**Run after Slices 11-13 land** — the 29 Aug, 30 Aug and 2 Sep attempts at
this pass are what found Slices 8, 9/10 and 11/13 respectively.

Once Slices 11–13 are in:

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
