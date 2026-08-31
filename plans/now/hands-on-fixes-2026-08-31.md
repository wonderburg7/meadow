# Hands-on fixes — 31 Aug 2026 pass

<!-- CONTEXT: plan | LAYER: immediate-task -->
Status: proposed, not yet implemented | Owner: Dave / Claude Code | Next: Dave
to sequence against `plans/now/challenge-1.md` Slice 9 and `plans/now/ui.md`
UI-P | Dependency: none | Verified: 2026-08-31

Five findings from Dave's 31 Aug hands-on pass across `checks/ready.md`'s
efficiency Slice 4/5, Challenge 1/2 and crab-spider checks. Each was traced
against live source before being written up here, not guessed from symptoms
— see each slice for confirmed-vs-hypothesis evidence, matching the
discipline `plans/now/challenge-1.md` Slices 8–9 already use.

Everything confirmed clean in this pass (efficiency Slices 1–2, crab spiders,
Challenge 1 Bundle F) is recorded in `checks/ready.md`'s update, not here —
this file is fixes only.

---

## Slice A — Critical: restore can silently drop bees, including the queen

**Two symptoms, one shared root cause plus one local bug.**

1. Dave: "loading a game after saving... seems to have made many bees,
   including the queen, disappear" (ordinary save/load).
2. Dave: Challenge 2 checkpoint-restore fires, but "queen isn't present in
   the restore," and neither the rescue ("Ahem. Field ecologists...") nor
   recovery ("A brief ecological wobble...") Gallerin lines ever appeared.

### A1 — `saving.gd::_restore_bees()` has no per-entry error boundary

**Confirmed-plausible, pending a live-boot confirmation with console
output.** `_restore_bees()` (`scripts/saving.gd:219-316`) loops every saved
bee entry with no guard around the loop body. GDScript aborts the whole
function on an unhandled runtime error, so one malformed entry partway
through silently truncates every entry after it — bees before the failure
survive as real nodes, everything after (queen included, since the save-time
array order comes from a live group scan, not a queen-first order) never
gets created. This is the only mechanism found that fits "**many** bees,
including the queen" rather than all-or-none.

The one restore step with a confirmed missing guard, contrasted with its
neighbours: `known_patches` (`scripts/saving.gd:276-277`) loops arbitrary-
length pairs with **no `.size() == 2` check**, unlike `home_hex`/
`mine_home_hex` a few lines above, which do check. Not proven as *the*
throwing field yet, but the clearest concrete gap in an otherwise
defensively-written loop.

Also relevant: `checks/ready.md`'s own Slice 5 entry has this exact check
still open (`- [ ]`, never confirmed), and Slice 5's own writeup says "No
Godot boot was available this session to confirm parser-level correctness."
This restore path has no test coverage — `tests/test_save_migrations.py`
only checks version bookkeeping, never runs a real multi-bee restore.

**Fix:**
- Add a `pair.size() == 2` guard around the `known_patches` loop
  (`saving.gd:276-277`), matching the existing `home_hex`/`mine_home_hex`
  pattern.
- Once a live boot names the actual throwing field (see below), add the
  same defensive `.get()`/type/size check there, following the pattern
  already used throughout this function.
- Consider wrapping each entry's construction so one bad entry logs and is
  skipped rather than aborting the rest of the colony — decide the exact
  shape once the real failure is known; don't guess a broad try/catch-style
  fix before that.

**Live confirmation needed:**
1. Debug-panel Save then Load on a non-trivial colony; capture the Godot
   console at the moment of load (a script error names the exact file:line
   and field).
2. Compare bee count before save vs after load — partial loss confirms this
   hypothesis; total loss points earlier in `_restore()` (e.g.
   `_restore_cells`/`_restore_soil` throwing before `_restore_bees()` is
   even reached) and needs its own look.
3. Capture the reproducing save JSON as a new `tests/fixtures/` file — there
   is currently no bee/queen-bearing fixture, which is the coverage gap that
   let this ship unnoticed.

### A2 — `challenge_runner.gd::_check_c2_failure()`'s restore branch has no queen guard

**Confirmed.** Line 224 calls `main.TutorialCheckpoint.restore(main)` and
never checks its return value; line 230 (`main.queen.energy_immune = true`)
dereferences `main.queen` unguarded immediately after — the one place in
this file that skips the `is_instance_valid(main.queen)` check used at 14
other call sites in the same file (194, 485, 522, 528, 579, 586, 634, 668,
681, 768, 803, 809, 812, 815), including a comment directly above line 230
that already warns "nothing here may go on using the pre-restore
queen/cell references."

If A1 leaves `main.queen` null after a checkpoint restore (checkpoint
restore reuses the exact same `saving.gd::_restore()` ordinary load does,
via `tutorial_checkpoint.gd:40-47`), line 230 throws and aborts the rest of
the function — which is also where `_apply_stage_gate_to_ui()`,
`_show_goal()`, and the `challenge_2_recovery` Gallerin prompt
(line 237) live. **One crash explains both "no queen" and "no recovery
message" as one symptom, not two** — fix A1 and re-test before assuming a
second bug remains here.

The missing **rescue** message (not recovery) has a separate, more likely
explanation: `Feedback.gallerin_prompt("challenge_2_rescue")` is
deliberately gated to `_stage_index > _c2_index("2.1")`
(`challenge_runner.gd:217`, with a comment explaining a mid-2.1 rescue would
"short-circuit the very thing it's meant to teach") — and 2.1 is Challenge
2's first stage. If Dave's nectar collapse happened during 2.1 itself, the
rescue branch is architecturally unreachable by design; he'd only ever hit
the floor/restore branch, whose recovery message then got eaten by the
line-230 crash. That single scenario explains all three absences without a
second defect. Not confirmed without knowing which stage he was on.

**Fix (independent of A1, apply regardless):**
```gdscript
if not main.TutorialCheckpoint.restore(main):
    push_error("Challenge 2 checkpoint restore failed")
    return
if not is_instance_valid(main.queen):
    push_error("Challenge 2 checkpoint restore left no queen")
    return
main.queen.energy_immune = true
```
matching this file's own established convention rather than inventing a new
one.

**Design question, not a bug — flag for Dave, don't fix blind:** should the
rescue net also cover stage 2.1 itself? Current behaviour is deliberate
(see the comment at 217); only change the `> _c2_index("2.1")` condition if
Dave wants that.

---

## Slice B — Challenge 2: meadow (and foraging) buttons never unlock

**Confirmed, fully static — no live repro needed.**

`_apply_stage_gate_to_ui()` gates the Hive/Meadow toggle button (this is
what Dave means by "the meadow panel" — its label reads "Meadow" while in
the hive) on `main.stage_gate.is_unlocked("meadow_view")`
(`challenge_runner.gd:546`). `STAGES_2` (`challenge_stages.gd:275-347`)
never lists `"meadow_view"` in any of its 9 stages' `unlocked_keys` — it's a
Challenge-1-only key (first unlocked at 1.7). `stage_gate.set_unlocked_keys()`
(`stage_gate.gd:87-90`) **replaces** the unlocked set wholesale on every
`_enter_stage()`, so a key missing from a stage isn't just "not yet
unlocked" — it's actively hidden the moment that stage is entered.

**Same-shape sibling bug, one stage later, not yet hit by Dave:**
`"foraging_window"` is set in 2.1 but not repeated in 2.2–2.9 — the
foraging button will vanish again the moment the player advances past 2.1,
for the identical reason.

**Fix:** add `"meadow_view"` to all 9 `STAGES_2` entries; add
`"foraging_window"` to 2.2 through 2.9 (already present in 2.1). Plain data
change in `challenge_stages.gd`, no logic touched — matches this project's
"a per-stage restriction/unlock list must be derived correctly, not
hand-maintained inconsistently" durable rule already stated in
`plans/now/challenge-1.md`.

**Acceptance:** starting Challenge 2 fresh, the Meadow button is visible
from the opening stage; the Foraging window button stays visible across
every stage transition through 2.9.

---

## Slice C — Nectar/pollen recharge reads as stuck

Dave: "since scenario 5... even at speed 8 the nectar stays at 1/8 and
pollen at 1/22... recharges in scenario 4, [but] pollen very slowly... no
recharge difference between scenarios should exist."

**Scenario choice is very likely a confound, not the cause.** "Scenario 4"/
"Scenario 5" are level ids 5/6 (`main_menu.gd:67-84`); diffing their
`LEVELS` entries (`levels.gd:61-87`) shows only starting colony composition
differs — nothing recharge/season-related. `ScenarioPresets.apply()`
(`scenario_presets.gd:13-23`) restates all four of its own fields on every
scenario pick specifically to stop leakage between runs, and
`Session.reset_run_state()` zeroes `sim_time` on every switch. No static
evidence supports a genuine per-scenario recharge difference.

**Two real, non-scenario-specific issues found instead, both worth fixing
regardless of which explains Dave's specific report:**

### C1 — HUD shows the nominal rate, not the effective one

`hud.gd:1399-1410`'s flower detail panel prints the flower's static
`nectar_recharge_rate`/`pollen_recharge_rate` fields, not the actual
effective rate (`rate * season_strength() * senescence_scale`,
`flower.gd:207-228,296-305`). A flower reads e.g. "+0.50/s" while genuinely
adding zero because it's out of season or senescent — which reproduces
exactly this class of report ("the rate shown says it should be
recharging, but it isn't moving"). **Fix:** show the effective rate.

### C2 — a flower pinned near `min_worthwhile_amount` looks frozen

`GameConfig.min_worthwhile_amount = 1.0` is an absolute floor, not a
percentage — explains why both nectar (cap 8) and pollen (cap 22)
independently read "1". A flower under enough forager pressure gets drained
to just under 1.0, ticks back above it, and gets immediately re-claimed —
visually pinned near "1" even though the mechanism works.
`nearest_flower()`'s accept filter (`bee_foraging.gd:281`) only excludes a
flower at `<= 0.0`, not below `min_worthwhile_amount`, so a marginal flower
keeps getting probed by a rotating cast of different bees. **Fix:** loosen
the filter to `< GameConfig.min_worthwhile_amount` — cheap, removes the
"looks frozen" artefact at its source rather than just explaining it away.

### C3 — reusable fix: close the `GameConfig` reset gap

Not confirmed as Dave's specific cause, but a real, silent leak worth
closing on its own: `seasons_on`, `flower_senescence_on`,
`flower_senescence_floor` are debug-panel-writable
(`debug_panel.gd:110,115,579`) but **not** among `scenario_presets.gd`'s
four restated fields. `GameConfig` is an autoload that survives
`reload_current_scene()`, so a debug-panel tweak from an earlier session
can silently outlive it and leak into a later scenario pick. **Fix, data-
driven per Dave's steer rather than patching one field at a time as it
bites:** add a single "reset every debug-panel-writable `GameConfig` field
to its declared default" call at the same point `Session.reset_run_state()`
already runs on scenario choice, instead of extending
`scenario_presets.gd`'s hand-maintained allowlist forever.

**Live confirmation needed before implementing (30-second check, no
guessing):** click the stuck flower's detail panel, read the *current*
displayed rate — if ~0.00/s, check the debug panel for a non-default
`seasons_on`/`flower_senescence_*` value (C3); if the panel shows a healthy
default rate but the amount still doesn't climb with no bee present, that's
a genuine `_sync_recharge` defect distinct from all three explanations
above and needs its own look; if it climbs cleanly with no bee present,
C2 is confirmed and it was never actually stuck.

---

## Slice D — Death marker: no selection glow

Dave: "make it so the green selection glow surrounds the death mark when
selected so the player knows what's selected."

**Confirmed — no selection visual exists for death markers at all**, not a
wrong-shaped one. `death_marker.gd` (60 lines) builds only a body circle and
a cross, no ring, no `set_selected()` — the only selectable type missing
this (bees, soil blocks, flowers, cells and obstacles each already have
their own). `input_selection.gd`'s three death-marker click branches
(121-125, 137-141, 168-174) call `_clear_world_object_selection()` then show
the summary directly, instead of `_select_world_object("death", marker)`
(the helper every other selectable type uses, 251-257, which sets
`selected_world_object` and calls `set_selected(true)`) — so even the
click registers, but nothing is ever told to glow.

**Fix — mirror `flower.gd`'s pattern** (closest precedent: small standalone
world object, simple circular footprint):
- `death_marker.gd`: add a `selection_ring: Line2D` in `_ready()` (circle,
  radius ~8px to clear the body+cross, same green as `flower.gd:119`,
  `visible = false`) and `func set_selected(value): selection_ring.visible = value`.
- `input_selection.gd`: replace the three branches' direct
  `show_object_summary` calls with `_select_world_object("death", marker)`;
  adjust `hud.gd`'s `"death"` case (~1392) to read `marker.death_info` off
  the passed node.

**Not scoping a shared selection-ring component** — no such component
exists anywhere (five object types each hand-roll their own already); a
sixth ~10-line copy matches this project's "small playable slices" steer
better than a refactor nobody asked for.

**Risk:** low — presentation-only, no simulation/save path touched
(`death_marker.gd`'s own header already documents it as simulation-inert).
Needs a hands-on visual check (ring reads right on screen), not an
automated one.

---

## Files referenced (on-demand)

- Slice A: `scripts/saving.gd` (`_restore_bees`, 219-316),
  `scripts/challenge_runner.gd` (`_check_c2_failure`, 209-237),
  `scripts/tutorial_checkpoint.gd` (full file, 54 lines),
  `scripts/save_game.gd` (`_bees_data`, ~234-260).
- Slice B: `scripts/challenge_stages.gd` (`STAGES_2`, 275-347),
  `scripts/challenge_runner.gd` (`_apply_stage_gate_to_ui`, ~546-547),
  `scripts/stage_gate.gd` (`set_unlocked_keys`, 87-90).
- Slice C: `scripts/flower.gd` (`_sync_recharge`, 207-228),
  `scripts/hud.gd` (flower detail panel, 1399-1410),
  `scripts/bee_foraging.gd` (`nearest_flower` accept filter, ~281),
  `scripts/scenario_presets.gd`, `scripts/game_config.gd`,
  `scripts/debug_panel.gd`, `scripts/session.gd`.
- Slice D: `scripts/death_marker.gd` (full file, 60 lines),
  `scripts/input_selection.gd` (121-141, 168-174, 251-257, `_select_world_object`),
  `scripts/flower.gd` (line 119, selection ring precedent).
