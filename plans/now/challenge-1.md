# Challenge 1 — current slice

<!-- CONTEXT: plan | LAYER: immediate-task -->
Status: active | Owner: Dave / Claude Code | Next: resume Slice 7's
acceptance-playthrough checklist — Slices 1-6 and Slice 8 (8a/8b/8d/8e) are
merged to master; 8c proposed no code change and is re-verified live as part
of Slice 7 | Dependency: none | Verified: 2026-08-29

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
