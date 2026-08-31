# Challenge 1 — current slice

<!-- CONTEXT: plan | LAYER: immediate-task -->
Status: active | Owner: Dave / Claude Code | Next: implement Slice 9 (below),
then resume Slice 7's acceptance-playthrough checklist again | Dependency:
none | Verified: 2026-08-30

Slice 7's resumed acceptance pass (30 Aug 2026) found nine further items in
"code-complete" Slices 1-6/8. Slices 1-2's own acceptance checks (Poppy
removal, hit areas, manual build, no auto-second-cell, no Comb Worker
role/letter change) are now confirmed clean; the rest of Slice 7's checklist
(full start-to-finish playthrough, copy pass, `checks/ready.md` entries) is
still blocked on Slice 9 below the same way it was blocked on Slice 8 before.

Supersedes the old Bundle H (copy/doc pass). That pass is folded into Slice 7
below, run *after* the mechanics change, not before — updating docs to match
mechanics that are about to be rewritten would be wasted work. Bundle A–G's
delivery evidence is still at `plans/archive/CHALLENGE1_REVAMP_PLAN.md` for
provenance only.

Slice 7's own hands-on pass (29 Aug 2026) found six bugs in the "code-
complete" Slices 1-6. All six were traced against live source (not just the
plan's description of what Slices 1-6 were supposed to do) before Slice 8
below was written — see each entry for confirmed-vs-hypothesis evidence.

## Why

Challenge 1 currently teaches manual foraging then jumps to automatic
foraging, but cell building has always been one instant, auto-placed action
(`challenge_runner.gd::_on_queen_build_cell_requested`), the queen becomes a
Comb worker to do it, and several controls surface before they're taught. This
slice makes cell building manual and player-placed, restricts the queen to
Forager/Egg Layer for the whole Challenge, tightens control visibility, fixes
a hit-area bug in the role panel, drops Poppy from Challenge 1's meadow, and
changes the completion screen. Everything below was scoped by reading the
live code, not guessed — each task names the exact function to change and why
the change is safe.

## Stage-id map (read this before Slices 3–5)

The user-facing "Stage 1/2/3" in this brief are **not** new stages — they map
onto existing `challenge_stages.gd::STAGES_1` sub-stage ids, whose goals and
prompts already do most of the right thing:

| Brief's stage | Existing sub-stage id(s) | What changes |
| --- | --- | --- |
| 1. Manual nectar collection | 1.8, 1.9, 1.10 | 1.8/1.9 (drink from flower 1/2) are already correct and need no code change. 1.10 (return + deposit) must split into two manual commands — see Slice 3. |
| 2. Unlock automatic nectar foraging | 1.11 | Goal changes from "30 nectar in the hive" to "the nectar cell is full"; add the 2x forage-speed override — see Slice 4. |
| 3. Introduce pollen | 1.12, 1.13 | 1.12 (`second_cell_built`) is the manual second cell — reuses Slice 2's build flow unchanged. 1.13 goal changes from "10 pollen in the hive" to "a pollen cell holds ≥75" — see Slice 5. |

Stages 1.1–1.7 (opening, hive tour, meadow tour) and 1.14–1.19 (third cell,
laying, hatch, farewell) are **not** in scope for sequence changes, but 1.14
reuses Slice 2's manual build flow, so it inherits that fix automatically —
no separate edit needed there beyond deleting `"comb_worker"` from its
`unlocked_keys` (see Slice 2).

## Current boundary

Challenge 1 owns the opening through the first worker leaving. Challenge 2
starts after the first worker exists, avoiding duplicated teaching. Shared
infrastructure is `challenge_runner.gd`, `stage_gate.gd`,
`tutorial_checkpoint.gd`, and `gallerin_panel.gd`; do not create
Challenge-specific parallel state. Ordinary save/load stays unavailable during
an active Challenge until a Challenge-aware schema exists.

---

## Slice 1 — Fix-first: role-panel hit areas + remove Poppy

Two small, independent, low-risk fixes the brief calls out to land before the
larger rework, so later manual-flow testing isn't confused by them. Bundled
together only because both are quick and isolated — they don't share files.

### 1a. Role-panel button hit areas

**Symptom:** the full visible area of a role-panel button isn't clickable,
worst in "the second row" of a wrapping button group.

**Diagnose before changing layout** (same discipline as `plans/now/ui.md`'s
UI-D, which this may turn out to be the same root cause as — check that plan
after fixing this one, and cross-reference there if so). Reproduce inside an
actual Challenge 1 run first, since `stage_gate` show/hide is a lead, not a
confirmed cause.

Two concrete leads, in priority order:

1. `hud.gd::_build_nursery_controls`'s `hatch_row` (~line 1115) is an
   `HFlowContainer` holding the "Raises:" buttons/dropdowns (Default,
   Forager, Nurse, Comb worker, Miner, Honey) — the only button group in the
   role/cell UI that actually wraps onto a second line. Check whether the
   container's computed height lags one frame behind its children after
   `_build_nursery_controls` populates it (a stale `custom_minimum_size` or a
   missing `reset_size()`/`queue_sort()` after dynamic population is the
   classic cause), which would leave row 2's buttons drawn in the right place
   but hit-tested against the wrong `Rect2`.
2. `hud.gd::_build_top_right_bar` (~line 498) explicitly builds two stacked
   `HBoxContainer` rows of icon buttons. Less likely given the symptom is
   scoped to "role-panel" buttons, but check it too if (1) doesn't reproduce.

Fix only once you've confirmed which container and why; don't touch both
speculatively.

### 1b. Remove Poppy from Challenge 1

Poppy stays in the game generally — only Challenge 1's meadow should never
seed one. `flower_species.gd::pick_species_index()` has no filter parameter
today; `world_building.gd::_seed_flower()` (line 195) is the single call site
used both for the initial meadow (`_build_meadow`, line 50) and for
re-seeding, so a change there covers both automatically — verify
`main.gd`'s reseed path calls the same `_seed_flower()` and not a duplicate.

Implement as:

```gdscript
# flower_species.gd
static func pick_species_index(exclude: Array = []) -> int:
    var total := 0.0
    for s in SPECIES:
        if s.name in exclude:
            continue
        total += s.get("weight", 1.0)
    var roll := randf() * total
    for i in range(SPECIES.size()):
        if SPECIES[i].name in exclude:
            continue
        roll -= SPECIES[i].get("weight", 1.0)
        if roll <= 0.0:
            return i
    return 0
```

`world_building.gd::_seed_flower()`: `var species_index = main.FlowerSpecies.pick_species_index(["Poppy"] if Session.starting_level == 1 else [])`.

**Acceptance:** no Poppy flower ever appears in a Challenge 1 run; Poppy is
unaffected in Challenge 2, Scenarios and open play. Every role-panel button's
clickable area matches its visible bounds, confirmed on a button that sits in
a wrapped second row.

---

## Slice 2 — Manual cell building + role/control availability

Foundation for Slices 3–5 (they all build cells or gate controls through the
mechanism this slice sets up) — land this first among the mechanics work.

### 2a. Stop assigning Comb Worker to the queen when she builds

`challenge_runner.gd::_on_queen_build_cell_requested()` currently calls
`main.queen.set_role(main.Bee.Role.BUILDER)` and
`main.queen.architect_mode = "maintain"`. **Delete both lines.** This is safe,
not just permitted, because of how the state machine actually works:

- `bee.gd`'s `State.TO_BUILD_SITE` / `State.BUILDING` handlers
  (`bee_building.gd::builder_go_to_site` / `builder_build`) never check
  `role` — they act purely on `target_cell`. `builder_go_to_site`'s own
  comment already anticipates this ("a builder (the queen included, in
  Challenge 1)").
- Only `_idle_dispatch()`'s `Role.BUILDER` branch (inside `_try_role_work`)
  auto-selects a *new* build site — and that branch is only ever reached
  when `role == Role.BUILDER`. Since the queen's role is never changed, it's
  never reached, so "don't auto-start another build" falls out for free
  without `architect_mode = "maintain"` doing anything.
- When `builder_build` finishes, it unconditionally sets
  `state = State.BUILD_IDLE`, which calls `_idle_dispatch()` on the queen's
  *real* role (Egg Layer, Forager, whatever it already was) — she correctly
  resumes her own job instead of looking for more building.

### 2b. Player-placed position instead of auto-placement

Replace the instant `main.hive.create_next_cell_site()` call with the same
"arm, then click a highlighted tile" flow ordinary Comb workers use for
"Build here" — but as a **separate** path, not by routing the queen through
the shared one, because that path's `input_selection.gd::_on_build_cell_requested`
filters `main.selected_bees` to `role == Role.BUILDER`, which the queen no
longer has (Slice 2a) and must not gain.

Implement as:

- `main.gd`: add `awaiting_queen_build_cell: bool = false` (sibling to the
  existing `awaiting_build_cell`).
- `hud.gd::_build_queen_build_row()`: keep emitting `queen_build_cell_requested`
  (no signal rename needed).
- `challenge_runner.gd::_on_queen_build_cell_requested()` becomes: set
  `main.awaiting_queen_build_cell = true`, ensure hive view (same one-liner
  `_ensure_hive_view()`-style check `input_selection.gd` already uses
  elsewhere).
- `input_selection.gd::_finish_drag()`: add a branch for
  `main.awaiting_queen_build_cell` (alongside the existing
  `main.awaiting_build_cell` branch) that reads the clicked hex
  (`_hex_at`), clears the flag, and calls a new
  `main.challenge_runner.on_queen_build_site_chosen(hex)`.
- `input_selection.gd::_draw_build_hover()`: generalise its guard from
  `main.awaiting_build_cell` to `main.awaiting_build_cell or main.awaiting_queen_build_cell`
  so the same hover-highlight-on-a-valid-tile feedback (`main.hive.can_build_on(hex)`)
  covers the queen's placement too — this is what satisfies "valid positions
  are highlighted."
- New `challenge_runner.gd::on_queen_build_site_chosen(hex: Vector2i) -> void`:
  if `not main.hive.can_build_on(hex)`, do nothing (invalid click is simply
  ignored, same as the ordinary Build-here flow). Otherwise:
  `var site = main.hive.create_cell_site_at(hex)` (the player-chosen-hex
  primitive `hive.gd` already exposes, distinct from the auto-picking
  `create_next_cell_site()`), then exactly what the old code did minus the
  role change: `site.build_time_override = Stages.FAST_BUILD_TIME`,
  `main.queen.target_cell = site`, `main.queen.state = main.Bee.State.TO_BUILD_SITE`.

### 2c. Build cell button placement

`hud.gd::_build_queen_build_row()` is currently appended to `more_panel`
(behind "More…"). Move its call in `_rebuild_role_controls()` so the button
renders in a primary column instead — next to or above the Job column is
fine; it must be visible without opening "More…". Keep the existing
`show_queen_build_row` guard (`show_queen_build_button and bees.size() == 1
and first.is_queen`).

### 2d. Build time: 5 seconds, not 15

`challenge_stages.gd::FAST_BUILD_TIME` is `15.0`; the brief specifies 5
seconds. Change the constant to `5.0` and update its comment (it's shared by
1.5, 1.12 and 1.14 — one change covers all three).

### 2e. Availability: only Forager and Egg Layer ever unlock

`STAGES_1` currently lists `"comb_worker"` in every stage's `unlocked_keys`
from 1.5 through 1.19 (11 entries). **Delete every one.** No other stage ever
lists `"nurse"`, `"miner"`, `"honey"` or `"idle"`, so this one deletion is
sufficient to make `hud.gd`'s `allowed_role_keys` filter (fed by
`challenge_runner.gd::_apply_stage_gate_to_ui`) contain only `forager` and
`laying` for the rest of the run — the Job column's "Change to…" menu can
then never offer Comb worker, Nurse, Miner or Honey to any bee, queen or new
worker alike.

Everything else the brief's "Availability rules" section asks for is
**already correct** in the existing stage data — verify, don't re-implement:

- Meadow view button: `"meadow_view"` unlocks at 1.7's *entry*, which only
  happens after 1.6's goal (`queen_reached_meadow`) is already met — i.e.
  after she's first inside the meadow. No change needed.
- Forager not shown at start: `"forager"`/`"nectar"` first unlock at 1.11.
  No change needed.
- `colony_window` / `nursery_window` keys are never unlocked anywhere in
  `STAGES_1` — those buttons stay hidden the whole Challenge already.

### 2f. Hatch-role panel gap (found during this review, in scope)

`hud.gd::_build_nursery_controls`'s "Raises:" row (hatch options for a cell —
Forager, Nurse, Comb worker, Miner, Honey) is built from
`HUD.hatch_options()` with **no** `allowed_role_keys` filtering at all today,
unlike the Job column. That means a player could currently hatch-designate a
Challenge 1 cell to raise a Nurse/Miner/Honey bee despite those roles being
otherwise completely hidden. Filter `hatch_options()`'s entries the same way
`_build_job_row` already filters role-change items — skip an entry whose
`role` isn't `-1` (the "Default" entry, always shown) and isn't in
`allowed_role_keys` when `allowed_role_keys` is non-empty.

**Acceptance (Slice 2):** Build cell is a full-width/primary-column button,
never behind More…; pressing it highlights valid tiles and does nothing
until the player clicks one; the queen's role and letter never change to
Comb worker while or after building; a completed build takes 5 seconds and
she resumes her prior job afterward with no second build starting on its
own; the Job column and the cell popup's "Raises:" row both offer only
Forager and Egg Layer (or their existing sub-options) for the whole
Challenge.

---

## Slice 3 — Manual nectar collection (1.10's deposit split)

1.8/1.9 (drink from flower 1, then 2) already work as specified — do not
touch `command_collect_from` or the goal checks for those two ids.

1.10 currently reaches its goal (`harvest_deposited`: "is inside the hive and
current_load is 0") via one command, `command_return_and_deposit()`, called
from `input_selection.gd::_issue_command()`'s hive-marker branch. That
command auto-picks a cell and auto-deposits the moment she's home — the
brief wants two separate manual steps. The goal predicate itself doesn't need
to change (it's still "home and empty"); only how she gets there does.

Implement as:

- `bee.gd`: add `var manual_deposit_pending: bool = false`.
- `bee.gd`: add `func command_return_only() -> void:` — identical to
  `command_return_and_deposit()`'s outdoor branch
  (`_release_everything(); state = State.TO_HIVE`), used only when
  `manual_deposit_pending` is true.
- `bee.gd`: add `func command_deposit_at(cell: Node2D) -> void:` — sets
  `target_cell = cell`, `manual_deposit_pending = false`, `state = State.IN_HIVE_TO_CELL`.
  `go_to_deposit_cell`/`finish_depositing` already act on whatever
  `target_cell` is set to (mirroring how `builder_go_to_site` already
  trusts a pre-set `target_cell`), so no change is needed in
  `bee_foraging.gd` for this part.
- `bee_foraging.gd::enter_hive()`: immediately after `bee.target_cell = null`
  (line ~702), add: `if bee.manual_deposit_pending: bee.state = State.IDLING; return`
  — before the existing `works_indoors` line. This is a no-op for every bee
  outside Challenge 1's manual stage (the flag defaults false), so it cannot
  regress ordinary automatic foraging.
- `input_selection.gd::_issue_command()`: in the existing hive-marker branch
  (`world_point.distance_to(main.hive.global_position) <= HIVE_CLICK_RADIUS`),
  change `b.command_return_and_deposit()` to
  `b.command_return_only() if b.manual_deposit_pending else b.command_return_and_deposit()`.
- `input_selection.gd::_issue_command()`: add a new branch, checked when
  `main.in_hive_view` is true (alongside the existing entrance/flower
  checks), for a bee with `manual_deposit_pending and current_load > 0.0`
  right-clicking a cell — reuse the already-existing `_cell_at(world_point)`
  helper (defined lower in the same file for left-click selection) to find
  it, and call `b.command_deposit_at(cell)` instead of `command_move_to`.
  Leave ordinary (non-manual) right-clicks on a cell exactly as they are
  today (`command_move_to`) — this new branch must only fire for a bee in
  manual-deposit mode, so it can't change behaviour for anyone else.
- `challenge_runner.gd::_enter_stage()`: set
  `main.queen.manual_deposit_pending = stage.id in ["1.6", "1.7", "1.8", "1.9", "1.10"]`
  (true for the whole manual-forage arc, false from 1.11 on). Also set it
  `false` in `start()` as a safety default so a resumed/restored run can
  never get stuck in manual mode outside this window.
- `challenge_stages.gd`: update 1.10's `prompts` copy to describe the two
  separate actions (right-click the hive to come home, then right-click the
  wax cell to deposit) instead of "Use Return and deposit" — final wording
  is a copy-pass concern (Slice 7), but the mechanic it describes must
  change now.

**Acceptance:** during 1.6–1.10, right-clicking the hive marker brings the
queen home and stops her there carrying her load; she does not auto-select
or auto-walk to a cell; right-clicking the built wax cell while she's
carrying a load is what triggers the deposit; from 1.11 onward the ordinary
one-click `command_return_and_deposit()` behaviour is restored for her (and
was never touched for any other bee).

---

## Slice 4 — Unlock automatic nectar foraging (1.11)

Two independent changes to the same stage; bundle them since both touch
`challenge_runner.gd`'s goal registry and stage-entry code in one pass.

### 4a. Goal: "the nectar cell is full", not "30 nectar in the hive"

`_goal_check_nectar_target()` currently checks
`main.hive.total("nectar") >= Stages.NECTAR_TARGET` (30.0) — a hive-wide
total, unrelated to whether the one cell built so far is actually full.
Replace with a cell-specific check:

```gdscript
func _goal_check_nectar_target() -> bool:
    for cell in main.hive.cells:
        if is_instance_valid(cell) and cell.content_type == "nectar" and cell.fill_fraction() >= 1.0:
            return true
    return false
```

Update `_goal_progress()`'s `"nectar_target"` case to report that same
cell's `amount` / `capacity_for("nectar")` instead of
`hive.total("nectar")` / `NECTAR_TARGET`, so the goal shelf's progress bar
stays honest. Remove the now-unused `NECTAR_TARGET` constant from
`challenge_stages.gd` once nothing references it.

### 4b. Automatic collection runs at 2x speed for this Challenge

Per-bee override, following the same pattern `HiveCell.build_time_override`
already established (never write `GameConfig` — see
`.claude/rules/saving.md`'s allowlist). `bee.gd` already has
`nectar_collection_rate`/`pollen_collection_rate` fields set from
`GameConfig` in `_apply_stats()`, and `_apply_stats()` already multiplies
them by a trait `factor` — same shape, different trigger.

Implement as:

- `challenge_stages.gd`: add `const CHALLENGE1_FORAGE_SPEED_MULTIPLIER := 2.0`.
- `challenge_runner.gd::_enter_stage()`: on entering `"1.11"`, multiply
  `main.queen.nectar_collection_rate` and `main.queen.pollen_collection_rate`
  by `Stages.CHALLENGE1_FORAGE_SPEED_MULTIPLIER`. Store the pre-multiply
  values first (e.g. `_c1_base_nectar_rate`/`_c1_base_pollen_rate`, reset in
  `start()`) so they can be restored exactly.
- `challenge_runner.gd::_complete()`: restore both rates from the stored
  base values, the same restore-on-exit discipline already used for
  `energy_immune` and `hud.set_warnings_muted(false)`.

**Acceptance:** the player must explicitly choose Forager → Nectar (already
true — nothing auto-selects it); once chosen, her nectar gathering runs at
double the normal rate; she stops the moment the nectar cell reads full and
does not pick a new task on her own; leaving the Challenge (complete or
otherwise) always restores her normal rate.

---

## Slice 5 — Introduce pollen (1.12–1.13)

### 5a. Second cell (1.12)

No new code: `second_cell_built` already reuses the Build cell button, which
Slice 2 already made manual/player-placed and Comb-Worker-free. Only the
**copy** changes — 1.12/1.13's prompts should carry the "colony needs
pollen, and here's why — but not yet what it's for" framing described in
the brief (Dr Gallerin explains protein/growth in general terms, no mention
of raising workers, which stays reserved for 1.14's existing "pollen's
deeper purpose" line). This is a copy-pass concern; land it in Slice 7 or
inline here if it's quick — either way, do not invent a new warning-banner
UI mechanism for "no available nursery cells": the existing `goal_text`
(`hud.gd::set_challenge_goal`) and Gallerin prompt queue
(`gallerin_panel.gd::queue_prompts`) are the established way this game
surfaces stage messaging, and they already reach "the queen's summary
panel" area the brief describes. Do not add a `show_warning()` toast for
this — that mechanism is for one-shot event toasts (a death, a saved game),
not a standing instruction, and it would disappear before the player acts on
it.

### 5b. Goal: "a pollen cell holds ≥75", not "10 pollen in the hive"

Same shape as Slice 4a. `_goal_check_pollen_target()` currently checks
`main.hive.total("pollen") >= Stages.POLLEN_TARGET` (10.0). Replace with:

```gdscript
func _goal_check_pollen_target() -> bool:
    for cell in main.hive.cells:
        if is_instance_valid(cell) and cell.content_type == "pollen" and cell.amount >= 75.0:
            return true
    return false
```

Set `Stages.POLLEN_TARGET := 75.0` and update `_goal_progress()`'s
`"pollen_target"` case to read that cell's `amount` against `75.0` (or
against `POLLEN_TARGET`, kept as the named threshold) rather than
`hive.total("pollen")`.

### 5c. Pollen unlock stays manual

`"pollen"` already only unlocks at 1.13 in `unlocked_keys`, and role/mode
selection already requires an explicit player choice (`role_requested`
signal, never auto-emitted) — no change needed. The 2x speed multiplier from
Slice 4b already covers pollen (`pollen_collection_rate` is multiplied in
the same call).

**Acceptance:** the second cell is built through the same manual
click-to-place flow as the first; Pollen only appears as a Forager option
once that cell is built; automatic pollen gathering runs at the same 2x rate;
the queen stops once a pollen cell holds ≥75 units and picks no further task
on her own.

---

## Slice 6 — Win window (Challenge 1 completion only)

`challenge_complete.gd` currently shows "Continue playing"/"Main menu" for
both Challenges. Only Challenge 1's completion screen changes.

Implement as:

- `challenge_complete.gd::open()`: read `Session.starting_level` directly
  (no new parameter needed — it's already a global the file's neighbours
  read the same way) and branch the button row: for level 1, hide
  "Continue playing" and show two buttons instead — "Continue to Challenge 2"
  and "Restart Challenge 1" — alongside the existing "Main menu"; for any
  other level, keep today's two-button layout untouched.
- Add two new signals, `continue_to_next_requested()` and
  `restart_requested()`, emitted by the two new buttons.
- Add a `Label` placeholder beneath `summary_label`, visible only for level
  1, reading something like "+ [meta-currency placeholder] earned" — exact
  copy is Dave's call; there is no real currency system yet
  (`player_profile.gd` has no such field), so this is cosmetic text only,
  not a new persisted value. Do not add a `PlayerProfile` field for it.
- `main.gd`: wire the two new signals next to the existing
  `challenge_complete.continue_requested`/`menu_requested` connections
  (~line 543): `continue_to_next_requested` → the same level-start path
  `_on_level_chosen` already uses, called with `2`; `restart_requested` →
  the same call with `1`. Read `_on_level_chosen`'s body first — reuse it
  exactly rather than duplicating scene-reload/boot-arg logic.

**Acceptance:** finishing Challenge 1 shows "Continue to Challenge 2",
"Restart Challenge 1", "Main menu" and the meta-currency placeholder;
finishing Challenge 2 is unchanged ("Continue playing"/"Main menu", no
placeholder).

---

## Slice 8 — Acceptance-playthrough findings

Six bugs found during Slice 7's hands-on pass. 8a-8d are bug fixes to shared
or Challenge-1 mechanics; 8e is a new feature (the brief always described the
1.11 camera/speed presentation, but no code implements it yet). None of these
are Challenge-1-specific except where noted — fix the shared mechanism, not a
Challenge-only branch, per `CLAUDE.md`'s "reusable, data-driven" steer.

### 8a — Shared full-storage bug: carried resource silently discarded

**Confirmed, shared-system (affects every forager, not just Challenge 1).**
`bee_foraging.gd::go_to_deposit_cell()`, when `hive.find_cell_for()` returns
null and `hive.cells` is non-empty (comb genuinely full, as opposed to the
already-handled "nothing built yet" case just above it):

```gdscript
bee.current_load = 0.0
bee.current_load_type = ""
bee.state = State.IN_HIVE_TO_EXIT
```

The load is thrown away with no deposit having happened, and
`_default_state_for_role()` sends her straight back to `SEEK_FLOWER`
(`bee.gd`), so she repeats the collect-and-lose cycle indefinitely. This is
Challenge 1's "queen appears to return with nectar, then it disappears and
foraging restarts" bug, and it is *also* an ordinary-play bug: any forager
whose compatible cells fill up loses her next several loads.

**Fix — reuse the miner role's existing epoch-guard shape**, not a new
polling timer or a new `State`. Miners already do exactly this for "I looked
for a job and there wasn't one" (`_mining_no_work_epoch` compared against
`hive.mining_work_epoch`, `bee.gd` ~line 1348). `hive.gd` already has an
equivalent for cell content (`index_epoch`, bumped by `invalidate_index()`
from every cell mutator — `hive.gd:108,146`). Add a per-bee
`_deposit_blocked_epoch: int = -1` and change the full-comb branch to:

```gdscript
if bee.target_cell == null or not is_instance_valid(bee.target_cell) or bee.target_cell.space_for(bee.current_load_type) <= 0.0:
    if bee._deposit_blocked_epoch == bee.hive.index_epoch:
        return   # nothing about the comb has changed since we last looked
    bee.target_cell = bee.hive.find_cell_for(bee.current_load_type)
    if bee.target_cell == null:
        if bee.hive.cells.is_empty():
            return   # unchanged: nothing built yet at all
        bee._deposit_blocked_epoch = bee.hive.index_epoch
        return   # still carrying it -- retry once the comb changes
```

She stays in `State.IN_HIVE_TO_CELL`, keeps her `current_load`, and the
epoch guard means she isn't re-scanning every frame while blocked (a
performance win, not just a correctness one). No new bee state, no
Challenge-specific branch — Challenge 1's "stop cleanly when the nectar cell
fills" falls out of this for free (she just stops losing nectar and stops
finding a next task, which is 8e's job to notice and freeze cleanly).

### 8b — Manual nectar collection: queen auto-flies home

**Confirmed.** `bee_foraging.gd::finish_collecting()` unconditionally sets
`state = State.TO_HIVE if current_load >= max_capacity else SEEK_FLOWER`
once her stomach is full — no reference to `manual_deposit_pending`
anywhere in the collection-finish path. The existing guard Slice 3 added
(`bee_foraging.gd::enter_hive()`, "if `manual_deposit_pending`: `IDLING`;
return") only fires *after* she's already flown home; it correctly blocks
the auto-*deposit* but nothing blocks the auto-*travel*, so she visibly
flies home on her own the moment she's full — the reported bug.

**Fix:** in `finish_collecting()` (and the resource-type-mismatch branch a
few lines above it, `bee_foraging.gd` ~line 627-630, which has the same
unconditional `state = State.TO_HIVE`), route through
`State.IDLING` instead of `State.TO_HIVE` when `bee.manual_deposit_pending`
is true. She then waits at the flower, fully loaded, until the player
right-clicks the hive marker (`command_return_only()`, already wired).

### 8c — Re-verify Nectar/Pollen unlock gating live

**Not reproducible in static code — likely a symptom of 8b, not an
independent bug.** Traced both goal predicates against real code:
`harvest_deposited` (`challenge_runner.gd::_goal_check_harvest_deposited`)
only reads true once `current_load` actually reaches zero, which only
happens via a real `finish_depositing()` call; `second_cell_built` only
reads true once `HiveCell.is_built` flips, which only happens once
`build_progress` reaches the time target. No code path unlocks on
arrival/full-load/build-start, and no code path auto-assigns the sub-role
to the queen (the only `set_role`/`set_focus`/`architect_mode` writes in
Challenge 1 are player-signal handlers or the Challenge-2 EGG_LAYER reset).

**Action:** no code change proposed here. Once 8b lands, replay Bundle D/E
(`checks/ready.md`) live — watching the queen auto-fly home and idle
without depositing plausibly *read* as "the game already finished this
stage," even though the actual `harvest_deposited`/`second_cell_built`
checks were never satisfied. If it still reproduces after 8b, that's new
information and needs its own investigation, not a guess now.

### 8d — Manual cell-building: 0% progress on every empty space, one after another

**Confirmed-plausible mechanism, precise enough to fix, pending a live-boot
confirmation.** Dave's own observation was the key: the sites appear in the
same hex-spiral order `hive.gd::create_next_cell_site()` uses for ordinary
Comb Worker auto-building — meaning that function, not the player-placement
one (`create_cell_site_at()`), is firing repeatedly. Traced the only way the
queen can reach it:

`hud.gd::_secondary_items()` (feeds `_build_fallback_row()`'s "If idle"
backup-role menu) builds its options straight from `Roles.ROLES` with **no
`allowed_role_keys` filtering** — unlike `_build_job_row()`'s "Change to…"
menu, which does filter (`hud.gd:2026`,
`if not allowed_role_keys.is_empty() and not allowed_role_keys.has(key): continue`).
So during Challenge 1, the queen's "If idle" menu still offers Comb Worker
as a backup role even though Slice 2e removed `"comb_worker"` from every
`STAGES_1` entry's `unlocked_keys`.

If a player picks it (`secondary_role = Role.BUILDER`, via
`orders_zones.gd::_on_secondary_role_requested`), `_idle_dispatch()`'s
queen-priority branch (`bee.gd` ~line 1200) calls `_try_role_work(Role.
BUILDER)` the next time she goes idle — including landing in
`State.BUILD_IDLE` right after completing her *own* player-placed cell.
With `architect_mode` defaulting to `"both"` (`bee.gd:141`, never set
otherwise for the queen), that branch falls through the
maintenance/restock checks to the auto-site-selection chain
(`bee.gd:1327-1345`): no manual queue, no unfinished cell of her own, so it
calls `hive.create_next_cell_site()` — the hex-spiral auto-placement
function. Each site she builds this way completes back into the same
shared `State.BUILD_IDLE` (`bee_building.gd:63`) → `_idle_dispatch()` →
same branch → next spiral hex. This matches the reported symptom exactly,
including the spiral ordering.

**Two-part fix, matching Dave's "make this more standalone" steer:**

- **8d-i (closes the hole):** filter `_secondary_items()` by
  `allowed_role_keys`, the identical pattern `_build_job_row()` already
  uses. This is a general fix — any future stage-gated role restriction
  benefits, not just Challenge 1 — closing a gap in an existing convention
  rather than inventing a new one. (This is the third place role choices
  are offered; `_build_job_row` and `hatch_options()`/Slice 2f were already
  fixed — this menu was the one gap left.)
- **8d-ii (defense in depth, reusable beyond this one bug):** add
  `var role_restricted_to: Array = []` to `Bee` — an allow-list of `Role`
  ints, empty by default (unrestricted, exactly like `allowed_role_keys`'s
  own empty-means-unrestricted convention). `challenge_runner.gd::
  _enter_stage()` sets `main.queen.role_restricted_to = [Role.EGG_LAYER,
  Role.FORAGER, Role.NURSERY]` for the whole of Challenge 1 (mirroring how
  `manual_deposit_pending`/`energy_immune`/the forage-rate multiplier are
  already set-on-entry, restored-on-exit), cleared to `[]` in `start()`'s
  reset block and `_complete()`. `_idle_dispatch()` checks it before each
  secondary-role dispatch attempt:
  ```gdscript
  if is_queen and role == Role.EGG_LAYER and secondary_role != -1 and (role_restricted_to.is_empty() or secondary_role in role_restricted_to):
      if _try_role_work(secondary_role):
          return
  ...
  if secondary_role != -1 and secondary_role != role and (role_restricted_to.is_empty() or secondary_role in role_restricted_to):
      working_secondary = _try_role_work(secondary_role)
  ```
  This closes off *any* wrong-role-via-secondary-role path for the
  Challenge-1 queen in one place — not just Comb Worker — so the same class
  of bug can't reappear if a future stage similarly restricts, say, Miner or
  Honey Maker. It never touches her manual build flow at all (that path
  sets `target_cell`/`state` directly from `challenge_runner.gd`, bypassing
  `_try_role_work` entirely), and it's a no-op for every bee/mode outside
  Challenge 1 (empty array, same as `allowed_role_keys`).
- Also route `bee_building.gd::builder_build()`'s completion through
  `bee._default_state_for_role()` instead of the hardcoded
  `State.BUILD_IDLE` — small, low-risk, and means a bee without the real
  Comb Worker role never lands in a Comb-Worker-shaped idle state at all,
  regardless of what future code does with secondary roles.

**Acceptance:** live Godot boot, reproduce today's build first (confirm the
"If idle" menu genuinely offers Comb Worker to the queen mid-Challenge and
that picking it reproduces the spiral), then confirm 8d-i alone closes the
UI hole and 8d-ii holds even if some future code sets `secondary_role`
directly without going through the UI.

### 8e — Automatic nectar foraging: camera/speed presentation (1.11)

**Feature genuinely missing, not buggy** — the brief describes behaviour no
code implements yet. Camera-follow (`camera_view.gd::_on_follow_bee_toggled`
/ `_handle_follow`, already driven every frame from `main._process`) and
game speed (`camera_view.gd::_on_speed_requested`, sets real
`Engine.time_scale`) both already exist as callable primitives independent
of their HUD buttons — `challenge_runner.gd` can call them directly. Confirm
the distinction already documented in Slice 4b: `CHALLENGE1_FORAGE_SPEED_
MULTIPLIER` is a **per-bee collection-rate** multiplier, not game speed —
this is a separate, new mechanism.

**Depends on 8a** (otherwise the queen loses nectar and keeps looping
instead of cleanly stopping when the cell fills).

**Implement as a small, reusable stage-effects table** rather than more
`if stage.id == "1.11":` branches in `_enter_stage()`/`_advance()` — this is
the general pattern worth establishing now (see "Proposed architecture"
below): add optional `on_enter`/`on_exit` string-key arrays to a
`challenge_stages.gd` stage record, and one small dispatcher in
`challenge_runner.gd` that recognises a handful of named actions
(`"camera_follow_queen"`, `"speed_multiplier:4.0"`, `"freeze_bee:queen"`).
1.11 gets `"on_enter": ["camera_follow_queen", "speed_multiplier:4.0"]`;
the 1.11→1.12 transition (i.e. `_advance()` when `nectar_target`'s goal
fires) undoes both — `main.following_bee = null`,
`camera_view._on_speed_requested(1.0)` — and freezes the queen exactly
once: `_release_everything()`, `clear_navigation_state()`,
`state = State.IDLING` (confirmed the correct "do nothing further" target —
the one state `_process`'s big `match` does nothing with, so
`_idle_dispatch` cannot restart automatic foraging on the next frame; her
`role` stays `FORAGER`, only `state` changes). Camera-follow and speed
always switch off on this edge — no case where either should persist into
1.12 (confirmed with Dave).

**Acceptance:** selecting Forager→Nectar at 1.11 starts camera-follow and
4x speed exactly once; filling the nectar cell stops foraging, resets both
exactly once (not reapplied per frame), and leaves the queen standing
beside the full cell waiting for the next command.

<!-- LAYER: durable-rules -->

- **Manual command ownership must be checked where automatic work starts,
  not only where it ends.** Both 8b and 8d were the same shape: a
  `manual_*_pending`/role-restriction guard existed at the point automatic
  work would *finish* (arrival, build-completion) but not at the point it
  would *begin* (`finish_collecting`'s state assignment, secondary-role
  idle dispatch). Any future manual-teaching stage needs the guard at both
  ends.
- **A Challenge that restricts a bee's primary role must restrict its
  secondary/backup role the same way** — `role_restricted_to` (8d-ii) is
  the reusable mechanism; don't reintroduce a primary-role-only check.

---

## Slice 9 — findings from the resumed Slice 7 acceptance pass (30 Aug 2026)

Nine items found while re-running Slice 7's playthrough now that Slice 8 has
landed. Grouped by mechanism, not by the order Dave found them in, since
several share one root cause.

<!-- LAYER: durable-rules -->

- **A per-stage restriction list must be derived from the same source as
  the UI gate it's meant to back up, never hand-maintained twice.**
  `allowed_role_keys` (what the Job column may show) is already correctly
  derived stage by stage from `unlocked_keys`. 9a below is exactly what
  happens when a second list doing the equivalent job for *behaviour*
  (`role_restricted_to`) is instead one hand-written array covering the
  whole Challenge — it silently drifts more permissive than the UI it's
  supposed to match. Any future per-bee behavioural restriction should
  read from `allowed_role_keys`/`unlocked_keys`, not maintain its own copy.
- **Every place a role can appear in the UI must respect `allowed_role_keys`
  — this is now the fourth instance of the same missed-filter bug,** not a
  new class of mistake. `challenge-1.md`'s existing durable rule ("Any UI
  menu that offers a role choice... must filter by `allowed_role_keys`")
  already named the Job column, hatch options and the "If idle" backup menu
  as the three places to keep in sync; 9d below adds a fourth,
  `_current_role_marker`'s always-on display of the bee's *current* role.
  Update that rule to say "four such places", not just three.

### 9a — Queen auto-forages before the player has ever chosen Forager as her job

**Confirmed.** `challenge_runner.gd::_enter_stage()` sets
`main.queen.role_restricted_to = [Roles.QUEEN, Roles.FORAGER, Roles.NURSE]`
unconditionally for **every** Challenge 1 stage, from 1.1 onward — not
derived from the current stage's `unlocked_keys` the way `allowed_role_keys`
is. `bee.gd::_idle_dispatch()`'s queen-priority branch
(`if is_queen and role == Role.EGG_LAYER and secondary_role != -1 and
(role_restricted_to.is_empty() or secondary_role in role_restricted_to):
_try_role_work(secondary_role)`) therefore already permits `Role.FORAGER`
as her secondary/backup role from the very start of the Challenge, well
before "forager" is unlocked in `allowed_role_keys` (1.11). The player never
has to touch "Change to: Forager" to trigger automatic foraging — picking
Forager once from the "When idle" backup-role menu (which itself correctly
only lists Forager once `allowed_role_keys` includes it, per Slice 8d-i) is
enough, because a queen's *secondary* role takes priority over her primary
Egg Layer job. This matches every symptom Dave reported: she forages
without her primary Job ever reading "Forager", and she resumes foraging
automatically the instant she's next idle (e.g. straight after a deposit),
because that's exactly what the backup-role priority branch is for.

**Fix — stop hand-maintaining `role_restricted_to` as one static array; derive
it from the stage the same way `allowed_role_keys` already is.**
`_stage_unlock_keys(stage.unlocked_keys)` already produces the list of
allowed role *keys* for the current stage. Add a small conversion (e.g.
`Roles.role_ids_for_keys(keys: Array) -> Array`, or inline a `for key in
keys: result.append(Roles.role_for_key(key))` if no such helper exists yet)
and set `main.queen.role_restricted_to = Roles.role_ids_for_keys(_stage_unlock_keys(stage.unlocked_keys))`
in `_enter_stage()` instead of the current hardcoded array — same call site,
same timing, but now it can never be more permissive than what the Job
column itself shows. Confirm `Roles.NURSERY`/`Roles.QUEEN` (her own
always-available fallback and primary role) are still included via
whatever mechanism already makes "nursing herself" possible before "nurse"
ever appears as a general `unlocked_keys` entry — if `unlocked_keys` doesn't
carry an implicit "queen may always fall back to nursing" concept, keep that
one exception explicit (e.g. always union in `[Roles.QUEEN, Roles.NURSERY]`
before converting the stage's own keys) rather than losing her intended
day-one nursing fallback.

### 9b — Queen's "Build cell" button disappears after the third cell

**Confirmed.** `challenge_runner.gd::_enter_stage()`:
`main.hud.set_queen_build_button_visible(stage.id in ["1.5", "1.12",
"1.14"])` — the button is visible only during those three exact stages,
hidden everywhere else (and explicitly hidden on completion, line ~482).
Once past 1.14 there is no stage that turns it back on, so if the third
cell later fills (e.g. an auto-foraged resource lands in it before she's
laid), she has no way to ask for a fourth — exactly Dave's reported
scenario.

**Fix:** Slice 2's manual-build flow is already safe when nothing is under
construction and does nothing until the player clicks a valid tile, so
there's no risk in leaving the button available for the whole Challenge
rather than gating it to three specific stage ids. Change the call to
`main.hud.set_queen_build_button_visible(true)` inside the existing
`if Session.starting_level == 1:` block in `_enter_stage()`, and leave the
explicit `set_queen_build_button_visible(false)` in `_complete()` as the
only place it's ever turned off.

### 9c — "Raises:" still offers Default

**Confirmed, and traced to Slice 2f's own filter, not a missed case.**
`hud.gd::hatch_options()`'s filter (`_apply_cell_popup_gating`, line ~1174 /
Slice 2f) is `if entry.role != -1 and not allowed_role_keys.is_empty() and
not allowed_role_keys.has(...)`: it explicitly *never* filters the
`role == -1` "Default" entry, by design ("the Default entry, always
shown" — correct for ordinary play, where "Default" is a meaningful
fallback among several real hatch choices). In Challenge 1, `allowed_role_keys`
only ever contains `forager`/`laying` (and "laying" isn't hatchable — a cell
can't raise a queen or egg-layer), so "Forager" is the *only* real option —
"Default" next to a single real choice reads as redundant rather than
useful.

**Fix:** extend the filter so `role == -1` is also skipped whenever
`allowed_role_keys` is non-empty (i.e. a Challenge is actively restricting
roles): `if not allowed_role_keys.is_empty() and (entry.role == -1 or not
allowed_role_keys.has(Roles.key_for(entry.role))): continue`. This is a
one-line change to an existing, already-reusable filter — it also correctly
drops "Default" the same way for any future Challenge that restricts roles,
not just this one.

### 9d — "Laying" shows as the queen's current role before it's taught

**Confirmed, and it's the fourth instance of the class of bug the existing
durable rule already tracks (see above).** `hud.gd::_build_job_row()`
(~line 2038-2047) always adds `_current_role_marker(Roles.label_for(common_role))`
for a single selection, with no `allowed_role_keys` check — unlike the
"Change to…" switch-target list right below it in the same function, which
does filter. The queen's role is `EGG_LAYER` ("Laying") from the moment
Challenge 1 starts, long before `"laying"` enters `unlocked_keys` (1.15), so
her Job column shows a "● Laying" current-role button the whole game,
undermining the stage's own pacing.

**Fix:** gate the marker the same way the switch-target list already is:
`if common_role != -1 and (allowed_role_keys.is_empty() or
allowed_role_keys.has(Roles.key_for(common_role))): row.add_child(_current_role_marker(...))`.
Outside a Challenge (`allowed_role_keys` empty) this is a no-op, identical
to today. Update the existing "Any UI menu that offers a role choice...
must filter by `allowed_role_keys`" durable rule to name this as the fourth
place, alongside the Job column's switch list, `hatch_options()`, and the
"If idle" menu.

### 9e — "Raise a gyne" is reachable in Challenge 1

**Confirmed.** `hud.gd`'s `gyne_box` checkbox row (~line 1207-1220) is
added to the cell tray unconditionally, with no `allowed_role_keys`/
`allowed_designation_keys` gate at all — unlike the "Jelly" designation
button next to it, which is likewise ungated today (so this isn't a
regression specific to gynes, it's a control nobody has gated yet).

**Fix, minimum:** gate `gyne_row`'s visibility on `allowed_role_keys.is_empty()`
in `_apply_cell_popup_gating()` (or wherever the row's `.visible` is set) —
correct for Challenge 1 today, since gyne-raising is never meant to be
reachable there. **Fix, reusable (recommended so this doesn't need
revisiting once Challenge 2 or a Scenario wants gynes gated too):** add a
proper unlock key (e.g. `"gyne"`) alongside `allowed_role_keys` the same
`_stage_unlock_keys` mechanism already produces, and gate on
`allowed_role_keys.is_empty() or allowed_role_keys.has("gyne")` instead of
the blunter empty-check — this lets a future Challenge stage unlock gyne
-raising explicitly (`unlocked_keys: [..., "gyne"]`) rather than only ever
being all-or-nothing. Not yet needed by any stage today, so the minimum fix
is enough to ship; note the reusable version as the natural next step if a
Challenge 2 stage ever wants to teach it.

### 9f — Dr Gallerin's "right-click the marked flower" hint doesn't match "any flower is fine"

**Ask (Dave, 30 Aug):** the hint text presupposes a specific marked flower
that isn't (or shouldn't need to be) there; the player should be able to
select any available flower.

`challenge_stages.gd`'s 1.8/1.9 hints ("right-click the marked flower" /
"the next marked flower") already work against goal predicates
(`first_flower_collected`/`second_flower_collected`) that are not tied to
any specific flower instance — mechanically, any flower already satisfies
them. This reads as a copy mismatch, not a logic bug: the hint text should
say "right-click a flower" (1.8) and "right-click another flower" (1.9)
rather than implying one specific marked flower. **Before making it a pure
copy fix, confirm live** whether `_meadow_inspection_points()`/`_update_marker()`
(the same ordered-visit/marker machinery 1.7's hive-points tour uses) is
also trying to mark one specific flower object for 1.8/1.9 and simply
failing to find/keep track of it — if a marker mechanism genuinely exists
here and is broken, fix or remove it consistent with "any flower is fine"
rather than leaving a dangling visual pointer at nothing; if no such marker
exists for these two stages (most likely, since flower selection isn't in
the ordered-visit list `_hive_inspection_points`/`_meadow_inspection_points`
feed), it's a copy-only fix.

### 9g — Second manually-built cell: no build animation, and the finished cell is invisible

**Confirmed as a rendering problem, not a logic one — the cell functionally
exists.** Selecting the tile opens a real cell popup and accepts a pollen
deposit, so the `HiveCell` node exists, is tracked in `hive.cells`, and
responds to input at the right position. But nothing about it ever paints:
no growing "under construction" stub during the build (which
`hive_cell.gd::_refresh()` already draws for every other cell via
`build_fraction()`), and no flat/cup fill once complete, regardless of the
Cell art setting. Since even the *unbuilt* stub never shows, this points at
the node's own visibility/paint state rather than anything content- or
Cell-art-specific.

**Two named, unconfirmed candidates — reproduce live with the remote scene
inspector before changing code, same discipline as Slice 8d's own
"confirmed-plausible, pending live-boot confirmation" finding:**

1. **Fog-of-war visibility.** `fog_of_war.gd` is already named in
   `plans/now/ui.md`'s UI-D-adjacent file list as something that reads
   `Session.use_sprite_hex_grid`/hive geometry and gates tile visibility.
   Check whether it also gates a freshly-created `HiveCell` node's own
   `visible` by whether its tile has been "revealed" yet, and whether a
   cell placed via the *new* player-chosen-tile flow (`create_cell_site_at`
   /`on_queen_build_site_chosen`, Slice 2b) reaches that reveal check the
   same way an auto-placed one (`create_next_cell_site`) always has —
   this is the one meaningfully new code path this cell went through that
   an ordinary auto-built cell never does.
2. **Paint-order collision.** Confirm the clicked hex's computed
   `z_index` (`2 * axial.y + axial.x`) and pixel position
   (`comb_centre + Shapes.hex_to_pixel(hex.x, hex.y, GameConfig.hive_cell_spacing,
   Session.use_sprite_hex_grid)`) don't coincide with another node already
   occupying that exact position/layer (soil, floor decoration, the first
   cell) in a way that fully occludes it.

**Action:** live-inspect the second cell's `HiveCell` node (`visible`,
`modulate`, `z_index`, parent chain) at the moment it's created, before
picking between the two candidates above.

### 9h — Selecting a bee and right-clicking a location in the *other* zone sends her off-screen

**Confirmed.** `input_selection.gd::_issue_command(world_point)` handles two
specific cross-zone cases explicitly — clicking the hive entrance while in
hive view (`command_exit_hive`) and clicking the meadow-side hive marker
while in meadow view (`command_return_and_deposit`/`command_return_only`) —
but its general fallback (`b.command_move_to(world_point)` /
`b.command_collect_from(flower)`, ~line 490-495) never checks whether the
*commanded bee* is even in the zone currently being viewed. `world_point` is
computed in the currently-displayed zone's coordinate space
(`hive_root`/`meadow_root`), so issuing it to a bee physically standing in
the *other* zone hands her a position that means nothing in her own zone's
coordinates — reproducing exactly "tries to move somewhere off screen"
rather than routing her through the entrance/exit first.

**Fix:** in `_issue_command`, before the generic `command_move_to`/
`command_collect_from` fallback, check whether each commandable bee is
actually in the zone matching `main.in_hive_view` (however that's tracked
per-bee today — likely the same state `works_indoors`/`_is_inside_hive()`
already reads). For a bee in the *other* zone, don't call `command_move_to`
directly: route her through the transition first (`command_exit_hive()` if
she's inside and the view is the meadow; the equivalent hive-ward entry
command if she's outside and the view is the hive), then queue the
originally-clicked point as a destination to continue toward once she
arrives — a new `pending_move_target: Vector2` (or similar) field on `Bee`,
consumed by whatever already runs once she completes the zone transition
(the same place `enter_hive()`/its meadow-side equivalent hands off to a
default state), continuing to `command_move_to(pending_move_target)` instead
of falling through to her default idle/role behaviour when one is queued.
This generalises the existing two hardcoded cross-zone cases into one
mechanism reusable for any future click, rather than adding a third
special case.

### 9i — Automatic nectar foraging (1.11): queen keeps switching flowers on her own; camera-follow/speed don't fire

**Two related but separate findings at the same stage.**

**Flower-switching (new design ask, not a regression of Slice 4's spec):**
Dave: "the queen still moves to a new flower after depleting one, which she
should not do — manual reselection only." Slice 4 never asked for this
restriction (its acceptance was only "stops when the nectar cell is full");
automatically picking a new flower once the current one depletes is
ordinary automatic-forager behaviour (the same `SEEK_FLOWER`-driven
selection every other forager already uses in `bee_foraging.gd`), which the
Challenge is now asking to suppress specifically for the queen during 1.11.
**Implement via the same reusable mechanism Slice 8e just introduced** —
`challenge_stages.gd`'s per-stage `on_enter`/`on_exit` action arrays and
`challenge_runner.gd::_run_stage_effects()` — rather than a new Challenge-
only branch in `bee_foraging.gd`: add a new named effect (e.g.
`"lock_flower_target:queen"`/`"unlock_flower_target:queen"`) backed by a new
`Bee.flower_switch_locked: bool` field (default `false`, exactly the same
empty-means-unrestricted shape `role_restricted_to`/`manual_deposit_pending`
already use). Add `"lock_flower_target:queen"` to 1.11's existing `on_enter`
list (alongside `"camera_follow_queen"`/`"speed_multiplier:4.0"`) and
`"unlock_flower_target:queen"` to its `on_exit` list (alongside the existing
unwind actions). Wherever a forager currently picks a *new* flower once the
current one depletes or a collection bout ends without being full (the
automatic-selection point in `bee_foraging.gd`'s `SEEK_FLOWER`-adjacent
code — confirm the exact call site live, it wasn't pinned down in this
pass), add a guard: if `flower_switch_locked` is true and she already has a
`current_flower`/just released one, drop to `State.IDLING` instead of
auto-selecting a replacement, the same "wait for an explicit player command"
shape 8b already established for manual deposit.

**Camera-follow/speed not firing:** `_run_stage_effects()` and 1.11's
`on_enter` list (`["camera_follow_queen", "speed_multiplier:4.0"]`) are both
present and call real primitives (`camera_view._on_follow_bee_toggled`,
`_on_speed_requested`) directly — nothing in the static trace explains why
Dave saw no camera movement or speed change. **Needs live reproduction, not
a blind fix:** confirm `_enter_stage()` actually runs `_run_stage_effects(stage.get("on_enter", []))`
for stage id `"1.11"` specifically (a stage-id typo or an early-return
somewhere before that line would silently skip it); if it does run, check
whether calling `_on_follow_bee_toggled`/`_on_speed_requested` directly
(bypassing whatever button-press signal normally drives them) leaves some
other piece of state inconsistent — e.g. a speed-button's own pressed
visual not reflecting the change even though `Engine.time_scale` genuinely
did, which would look like nothing happened even though the effect fired.
Add a debug log line inside `_run_stage_effects`'s match (or a breakpoint)
for one live playthrough before changing either function's logic.

### 9j — Compatible-cell availability: a designated cell never returns to neutral, and a "vanishing" deposit needs live confirmation

**Two findings, one confirmed design behaviour and one not yet reproduced
in static code.**

**Confirmed: a cell's `designated_type` is permanent once first used, even
after it empties completely — this is probably not what "drink some nectar,
now there's space" expects.** `hive_cell.gd::add_resource()` sets
`designated_type = resource_type` the *first* time a spare
(`content_type == "" and designated_type == ""`) cell receives anything —
correct, and how the comb is meant to "organise itself as it fills"
(the function's own comment). But `take_resource()` (drinking/consuming from
a cell) only ever resets `content_type` back to `""` once the cell empties
completely — it never touches `designated_type`. So a nectar cell that gets
fully drunk down stays permanently reserved for nectar; a pollen-carrying
bee blocked on "nowhere to deposit" gets no new option from that cell
emptying, because `accepts()`/`space_for()` still refuse it
(`designated_type != "" and designated_type != resource_type`). This is
consistent with Dave's report that the blocked "carrying pollen to a cell"
status doesn't change after the bee drinks nectar — nothing about cell
availability for pollen actually changed, because the emptied cell is still
pinned to nectar.

**This is a real design gap worth naming, distinct from a bug:** there is no
way today to tell an *auto*-designated cell (first-use fallback, the cell in
`add_resource`'s comment) apart from a *player*-designated one (an explicit
"Reserve for" click) — both just set the same `designated_type` field. A
player's own explicit designation should stay sticky forever, exactly as
today; an auto-designation that's since gone fully empty arguably should
release back to neutral so the next resource that needs room can use it,
the same way the cell would have if nothing had ever been deposited there
at all.

**Proposed fix (reusable, not a Challenge-1-only branch):** add a
`bool designation_is_explicit` field to `HiveCell`, `false` by default. Set
it `true` only where the player actually requests a designation
(`set_designation()`, the "Reserve for" buttons) — never in `add_resource()`'s
auto-fallback branch. In `take_resource()`'s full-empty branch (where
`content_type` already resets to `""`), also reset
`designated_type = ""` when `not designation_is_explicit`. A player-pinned
cell is completely unaffected (it never sets the flag, so it never
auto-releases); an auto-designated cell that empties out now genuinely
returns to the neutral pool, which is what would let the "drink nectar,
free a cell" scenario actually work as Dave expects, and fixes the same
underlying staleness for every resource type and every bee, not just the
queen's pollen/nectar case.

**Also confirmed, and worth pairing with the fix above:** the
`deposit_blocked_epoch`/`hive.index_epoch` guard (Slice 8a) only bumps on a
*full* empty-out or a content-type change (`_invalidate_hive_index()`,
called from `add_resource` and `take_resource`'s `amount <= 0.001` branch) —
never on a partial withdrawal. That's already consistent (a partial drink
never changes what any cell accepts today), but once the fix above makes a
full empty-out able to change eligibility for a *different* resource type,
double check `_invalidate_hive_index()` still fires on that exact same
`take_resource()` branch — it already does (same `if amount <= 0.001` block),
so no separate epoch-guard change should be needed; confirm live rather
than assuming once 9j's designation fix lands.

**Not confirmed: "the resource vanishes/is lost" when only an
incompatible-type cell is available.** Traced `go_to_deposit_cell`,
`find_cell_for`, `space_for`/`accepts`, and `finish_depositing` end to end —
every path that assigns `bee.target_cell` already goes through
`find_cell_for(resource_type)`, which itself excludes any cell whose
`designated_type` doesn't match, and `add_resource`/`space_for` re-check the
same thing again before anything is written. No static path was found where
a bee deposits into a genuinely incompatible cell. **Action, matching 8c's
own precedent:** no code change proposed here yet — replay live once 9a-9j
above are in (several of them change exactly the mechanics this scenario
depends on) and note precisely which two cell states were in play at the
moment it happened; if it still reproduces, that's new information needing
its own investigation, not a guess now.

**Also raised in the same pass, not Challenge-1-specific:** "Change to…"
and "When idle:" should present as buttons (background colour) rather than
floating text, in every instance, not just Challenge 1. Tracked as
`plans/now/ui.md`'s UI-P-2 (a `UiTheme` change, not a Challenge file) — no
duplicate entry needed here.

**Acceptance (Slice 9):** each of 9a-9j above closes independently against
its own description; re-run the specific `checks/ready.md` entries once
implemented (see Slice 7 below for the full playthrough this all feeds
back into). 9g and 9i's camera/speed half, and 9j's "vanishing resource"
claim, need a live repro pass before or alongside implementation, per their
own sections above — don't skip that step because the rest of the slice is
otherwise ready to build.

## Slice 7 — Acceptance pass and documentation (absorbs old Bundle H)

**Blocked on Slice 8** — the first attempt at this pass (29 Aug 2026) is
what found the six bugs Slice 8 now fixes; re-run the checklist below only
after Slice 8 lands, not before.

Once Slices 1–6 (and now 8) are in:

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
