# Challenge 1 — the acceptance pass

<!-- CONTEXT: plan | LAYER: immediate-task -->
Status: active | Owner: Dave / Claude Code | Next: Slice 7 -- acceptance pass and documentation | Dependency: none -- Slice 7 is startable now | Verified: 2026-09-09

**Objective.** Challenge 1 teaches the game's core loop without ever
advancing on behaviour the player did not command. Every code slice is
shipped; what remains is one acceptance playthrough and its copy pass.

**State.** Slices 1-6 and 8-15 are code-complete and merged (last: 3 Sep
2026). Dave ran C-7 on 9 Sep 2026, the first run possible since LAY-2
restored the command tray, and the automatic-foraging arc failed in five
distinct ways. Those became **Slices 16 to 19** below, per this plan's own
rule that a finding from its acceptance run becomes its next slice while it
is open. Slice 7, the acceptance playthrough, now runs after them. Slices 16,
17 and 18 are shipped: the queen now works more than one flower, wakes up
from a focus change alone, and pollen has somewhere to go once the player
designates a cell for it.

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

**Open slices.** Slice 7, the last one. Nothing else may be added -- a
finding from Slice 7's own run becomes this plan's next slice while it is
open, and a finding after it closes starts a new `plans/now/` file.

**Authoritative files.** Stage data: `scripts/challenge_stages.gd`.
Sequencing and gating: `scripts/challenge_runner.gd`. The
"player drives this bee" flag and the state machine: `scripts/bee.gd`.
Foraging transitions: `scripts/bee_foraging.gd`. Cell storage rules:
`scripts/hive_cell.gd`, `scripts/hive.gd`.

**Required reading.** This file only. The delivered slices are archived at
`plans/archive/CHALLENGE1_SLICE_16_2026-09-09.md`,
`plans/archive/CHALLENGE1_SLICES_11-15_2026-09-03.md` and
`plans/archive/CHALLENGE1_SLICES_1-10.md`; open them for provenance, never to
work out what to do.

**Reasoning level.** Slice 7 is Dave's own playthrough plus a copy/doc pass,
not a reasoning-bounded code slice.

**Slice numbering starts at 16 on purpose.** C-7's `Owner:` line named "Slice
14", a slice archived on 3 Sep, so the check pointed at a specification
nobody could open. New slices never reuse a retired number.

**Slice 16 — the queen works more than one flower at 1.11 — shipped 9 Sep
2026:** `plans/archive/CHALLENGE1_SLICE_16_2026-09-09.md`.

**Slice 17 — changing a bee's focus wakes her up — shipped 9 Sep 2026:**
`plans/archive/CHALLENGE1_SLICE_17_2026-09-09.md`.

**Slice 18 — pollen has somewhere to go, and the player learns why — shipped
9 Sep 2026:** `plans/archive/CHALLENGE1_SLICE_18_2026-09-09.md`. Renumbered
every Challenge 1 stage from the former `1.13` onward by one (ending at
`1.20`) to insert a new `1.13` designation stage -- `docs/challenge-stages.md`
has the current sequence.

**Slice 19 — the stage's automation switches off when the stage ends —
shipped 9 Sep 2026:** `plans/archive/CHALLENGE1_SLICE_19_2026-09-09.md`.
`_complete()` and the checkpoint-restore path now run
`_run_stage_effects(["camera_follow_off", "speed_multiplier:1.0"])`
explicitly, independent of a stage's own `on_exit`.

## Slice 7 — Acceptance pass and documentation (absorbs old Bundle H)

**Run now.** The 29 Aug, 30 Aug, 2 Sep and 9 Sep attempts at this pass are
what found Slices 8, 9/10, 11/13 and 16-19 respectively. This is the plan's
last open slice.

Now that Slices 16-19 are in:

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
