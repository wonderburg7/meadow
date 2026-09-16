# Challenge 1 Slice 18 — pollen has somewhere to go, and the player learns why

<!-- CONTEXT: archive | LAYER: provenance -->
Status: shipped 9 Sep 2026 | Owner: Dave / Claude Code | Verified: 2026-09-09

Delivered from `plans/archive/CHALLENGE1_2026-09-15.md`'s C-7 finding (Dave's 9 Sep 2026
hands-on pass). Kept here for provenance only -- see
`plans/archive/CHALLENGE1_2026-09-15.md` for current work.

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

**Delivered in five parts, in this order.**

**(a) Overflow nectar disappears, in `scripts/bee_foraging.gd`.** In
`go_to_deposit_cell()`, in the branch that currently sets
`bee.deposit_blocked_epoch` and returns, added a Challenge-1-only case
*before* that line: if the bee is the queen, the load type is `"nectar"`,
and Challenge 1 is active, discard the load (`bee.current_load = 0.0`,
`bee.current_load_type = ""`) and fall through to `State.IN_HIVE_TO_EXIT`
instead of holding it. Routed the "is Challenge 1 active" question through
one new method on `challenge_runner.gd`, `func discards_overflow(bee) ->
bool`, rather than reading `Session` from inside the foraging file.

The general path is unchanged: outside Challenge 1 a full comb still keeps
the load.

**(b) A new stage teaching cell designation, in `scripts/challenge_stages.gd`.**
Inserted a stage between the former `1.12` (build a second cell) and `1.13`
(automate pollen gathering). The new stage is `1.13`, and every later stage
moved up one, ending at `1.20`. `1.13` reuses the existing `cell_designated`
goal (already used by Challenge 2's `2.3`).

Every literal Challenge 1 stage id in `challenge_runner.gd` was updated to
match: the old `1.13` (pollen automation) is now `1.14`, `1.14` (third cell)
is `1.15`, `1.15` (first egg) is `1.16`, `1.16` (nectar forager hatched) is
`1.17`, `1.17` (new bee selected) is `1.18`, `1.18` (new bee left hive) is
`1.19`, and `1.19` (complete) is `1.20`.

`docs/challenge-stages.md` was regenerated with `python tools/stage_reference.py`.

**(c) Challenge 2's stage `2.3` now teaches this second.** Reworded
`2.3_welcome` and `2.3_hint` as a reminder rather than a first introduction,
since Challenge 1's new `1.13` now teaches designation first (Challenge 2
remains startable on its own).

**(d) The queen can empty a cell, in `scripts/bee.gd`, `scripts/hud.gd`,
`scripts/input_selection.gd` and `scripts/main.gd`.** Added
`Bee.command_empty_cell(cell)`: sets `cell.evict_requested = true`, then
`target_cell = cell` and `state = State.TO_HAUL_SOURCE` (marked
`# player-command`). `bee_building.gd`'s existing
`builder_go_to_haul_source`/`builder_go_to_haul_target` and the state
dispatch in `bee.gd` never check `role`, so no role-branch needed lifting --
they already serve any bee reaching those states. The queen's `role` is
never touched, and she returns to her own role's idle dispatch once the
cell is empty.

Added an "Empty this cell" button to the "Emptying" column in
`hud.gd::_build_cell_group()`'s `_build_empty_controls()`, visible whenever
the selected cell holds anything haulable (not empty, brood or a corpse).
It is not gated by `allowed_role_keys`/`allowed_designation_keys` -- doing
so would hide it throughout Challenge 1, since the queen never unlocks a
builder-role key, which is exactly the colony state the button exists for.
Wired via a new `cell_empty_by_bee_requested(cell)` signal through
`main.gd` to a new `input_selection.gd::_on_cell_empty_by_bee_requested`,
which commands the first selected bee -- same "one click, one bee" shape as
`_on_home_cell_requested`.

**(e) Dr Gallerin says when nectar is in the pollen cell.** In
`challenge_runner.gd::_drive_c1_pollen_cell_nectar_prompt()`, while the
renumbered pollen stage (`1.14`) is current, checks once a second whether
any cell whose `designated_type` is `"pollen"` has `content_type ==
"nectar"`. If one does, calls `main.gallerin_panel.clear_queue()` then
`show_now()` with a new non-repeatable `challenge_1_pollen_cell_nectar`
definition in `challenge_feedback.gd`.

**Acceptance.** Play 1.11 through to the end of the pollen stage without
touching the debug panel. The queen fills the first cell with nectar and any
surplus she is carrying disappears rather than stranding her. The new
designation stage asks the player to set the second cell aside for pollen
and will not advance until they do. She then forages pollen and deposits it
in that cell unaided. If nectar is somehow in the pollen cell, Dr Gallerin
says so, and the "Empty this cell" button lets the queen clear it with no
role change and no second bee.

**Checks filed:** C-7 (already covered the automatic pollen deposit, Owner
line updated to this slice), plus two new: C-30 (the designation stage) and
C-31 (nectar caught in the pollen cell, and the queen emptying it herself).
