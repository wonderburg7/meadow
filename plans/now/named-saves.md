# Named saves and rolling checkpoints

<!-- CONTEXT: plan | LAYER: immediate-task -->
Status: complete -- SV-1 landed 23 Sep, SV-2 and SV-3 24 Sep 2026 | Owner: Dave / Claude Code | Next: None — plan complete. Follow-ups: the Saves button's icon is filed as `plans/now/alpha-progression-spine.md` AP-5; whether game hotkeys fire while typing a run name is covered by C-63 | Dependency: none | Verified: 2026-09-24

**Objective.** `plans/design/product-scope.md` §6.1 makes "named run saves,
three rolling recovery checkpoints and reliable restore" a closed-alpha
essential, and §15 defines the closed alpha as friends and family being able to
"install, save, resume and provide useful feedback without live instruction".
A tester who loses an hour to one bad save stops testing. This plan makes the
save a named slot with automatic recovery points behind it.

## Current state

Verified 22 September 2026 by reading `scripts/save_game.gd`,
`scripts/saving.gd` and `scripts/tutorial_checkpoint.gd`.

- **There is exactly one save.** `save_game.gd` writes
  `const SAVE_PATH := "user://meadow_save.json"`. Saving again overwrites it.
  There is no recovery point, no second slot and no way to tell two runs apart.
- **The serialiser is already slot-ready, and this is the whole reason this
  plan is cheap.** `SaveGame.save(world, path)` and `SaveGame.read(path)` both
  take a path already, and `tutorial_checkpoint.gd` already passes its own
  (`user://tutorial_checkpoint.save`) so a Challenge's checkpoints never touch
  the player's file. Nothing below needs to change the save *format*, bump
  `FORMAT_VERSION` or write a migration.
- **`scripts/saving.gd` owns the act of saving**, not the format:
  `save_run()` calls `SaveGame.save(main)` with the default path and shows a
  HUD warning. It holds no state and knows nothing about slots — `grep -c
  checkpoint scripts/saving.gd` returns 0.
- **`main.gd` already emits `day_changed(day)`**, so a periodic checkpoint has a
  trigger to hang on without inventing a timer.

**SV-1 landed 23 Sep 2026** (`plans/archive/` has its specification). What
SV-2 builds on: `scripts/save_slots.gd` owns `user://saves/` --
`list_slots()` (newest first, each entry the index record plus `slug` and
`last_saved`, with `checkpoints` keyed "1".."3" each holding `day` and
`saved_at`), `slot_path(slug)`, `checkpoint_path(slug, n)`, `latest_named()`
and `delete(slug)`. `saving.gd::save_run(run_name)` renames the run when given
a name; the run's name is `Session.run_name` (default "My colony"), and
`Session.load_path` is the file a pending load replays. The cog's Load run reads
`latest_named()` until SV-2 replaces it. Decisions SV-1 took without Dave
(each the cheapest to reverse):

- **Legacy save is copied, not moved.** `meadow_save.json` is copied byte for
  byte to `my-colony.json` once, with day unknown (-1) because reading it would
  mean opening a save; the original stays where it was.
- **`checkpoint_every_days` is `persist: "none"`, not `"run"`.** `"run"` adds
  the key to every save's `settings` block, which `verify.ps1`'s D1 source
  check forbids and which would change save contents -- the one thing this
  plan promised not to do. It is a float like the other counts in
  `game_config.gd`, read as an int.
- **Challenges write no checkpoints.** `tutorial_checkpoint.gd` already rolls
  them back, and a Challenge's checkpoints would push the player's own run's out
  of the rotation.
- **Headless scenario runs use `user://scenario_saves/`**, emptied at boot, so
  a test run never touches the player's catalogue.
- **Files beyond the queue line**, all clear of the Codex lane:
  `scripts/debug_panel.gd` (Load reads the named slot), `scripts/session.gd`
  (`run_name`, `load_path`), `scripts/game_config.gd` and
  `scripts/settings_catalogue.gd` (the setting), `scripts/scenario_actions.gd`
  (`save_run`/`restore_slot` actions and a `save_slot` assertion) and
  `test_scenarios/sv1_named_saves_test.json`, the acceptance run.
- Hands-on check filed: C-62.

**SV-2 landed 24 Sep 2026.** `scripts/saves_panel.gd` is a left `GamePanel`
keyed `saves`, opened by a text **Saves** button that `hud.gd` adds to the top
bar (hidden during Challenges) and creates the panel for. It lists every run
newest first with its checkpoints, each showing its day and age. Every row
with a file has Load, and each run has Delete. The first save of a run asks
for a name, prefilled with the current one. Deleting, or saving over another
run's name, goes through `hud.gd`'s existing discard dialog via
`confirm_discard` when `Session.warn_on_discard` is on. Proven by
`test_scenarios/sv2_saves_window_test.json` and the unchanged
`tests/test_layout_regression.py`. Hands-on check filed: C-63. Decisions taken
without Dave (each the cheapest to reverse):

- **Delete is per run, not per checkpoint.** A checkpoint row has Load only;
  the checkpoints rotate out on their own.
- **A plain text button, not an icon.** `ui_icon.gd` has no save glyph and is
  outside SV-2's files.
- **No Saves button in Challenges.** A Challenge reveals controls stage by
  stage and has its own rollback.
- **"Asked for a name" lasts until a new run starts.** It is a static flag on
  the panel, set by a save or a load and cleared by `Session.run_reset`.
  Restarting asks again, prefilled with the old name, and saving over an
  existing run's name asks first.

Follow-ups: the cog's **Load run** still loads the newest named save rather
than opening this window -- now SV-3. Whether game hotkeys fire while the name
box has focus is unchecked; C-63's typing step would show it.

**SV-3 landed 24 Sep 2026.** In a sandbox run the cog's **Load run** closes
the settings window and opens the Saves window. In a Challenge, or with the
main menu showing (it would sit on top of the Saves window), it still loads the
newest named save. `test_scenarios/sv2_saves_window_test.json` still passes.
C-63 now includes the Load run step.

**What is intended when this plan is done.** A run is saved under a name the
player chose, the game keeps the last three automatic recovery points behind
it, and both are reachable from the HUD without instruction.

## Open slices at a glance

| Slice | Outcome from the player's seat | Files owned | Startable | Level |
| --- | --- | --- | --- | --- |
| SV-3 | The settings cog's **Load run** opens the Saves window, so there is one way to choose what to load. | `scripts/debug_panel.gd` | yes | low |

**Dependencies, stated rather than implied by order.**

- SV-2 needs SV-1's catalogue to list anything, and waits on **F2s**
  (`plans/archive/architecture-review_2026-09-24.md`) because both own `scripts/hud.gd`.
- **Independent of `plans/now/alpha-progression-spine.md`.** AP-4 bumps
  `FORMAT_VERSION` and writes new fields; SV-1 and SV-2 change only *where* a
  save is written and never open the format. Whichever ships first, the other
  fits beside it. Recorded in both plans.
- `scripts/tutorial_checkpoint.gd` is **not** replaced by this plan. It is a
  Challenge mechanism with its own single fixed path and its own lifetime, and
  folding it into the slot catalogue would mean a Challenge's checkpoint showing
  up in the player's save list. Named here so a later slice does not "tidy" it.

**Required reading for any slice.** Its own section below. `save_game.gd`'s
header comment and its `save`/`read`/`has_save` signatures — nothing else in
that file, and no part of `saving.gd`'s 250 lines of `_restore_*` helpers.

SV-1 shipped 2026-09-23; its specification is `plans/archive/SV-1_2026-09-23.md`.

SV-2 shipped 2026-09-24; its specification is `plans/archive/SV-2_2026-09-24.md`.

## SV-3 — the cog's Load run opens the Saves window

Level: low.

- **Required reading.** This heading. `python tools/func.py scripts/debug_panel.gd _on_load_pressed _on_save_pressed`.
- **Files to change.** `scripts/debug_panel.gd`.
- **Why.** Since SV-1 the cog's **Load run** loads whichever named save was
  written last (`SaveSlots.latest_named()`), a stopgap its own comment names.
  Now that SV-2's Saves window lists every run and checkpoint, two Load
  buttons that choose differently would confuse a tester.
- **Requirements.** `_on_load_pressed` closes the settings panel and opens
  `main.hud.saves_panel` through `main.year_winter._toggle_panel`, the same
  way the top-bar **Saves** button does, instead of reloading. **Save run**
  keeps saving under the run's current name. The `SaveSlots` preload goes if
  nothing else in the file uses it.
- **Invariants.** Outside a Challenge the window opens where the top-bar button
  opens it. In a Challenge, where the Saves button is hidden, **Load run**
  behaves as it does today rather than revealing the window early.
- **Automated acceptance.** `tools/godot_compile_check.py`, and
  `test_scenarios/sv2_saves_window_test.json` still passes.

```queue
**[Claude] SV-3 -- the cog's Load run opens the Saves window**
- Plan: `plans/now/named-saves.md` -- "SV-3 — the cog's Load run opens the Saves window"
- Files: `scripts/debug_panel.gd`
- Check: outside a Challenge the cog's Load run opens the Saves window instead of reloading the newest save, inside a Challenge it behaves as before, and Save run is unchanged
- Proof: `absent: scripts/debug_panel.gd :: saves_panel`
- Next after: none -- named-saves is complete once SV-3 ships.
```

## Read on demand

<!-- LAYER: on-demand -->

- `.claude/rules/saving.md` — the standing rules for touching a save.
- `plans/design/product-scope.md` §6.1 and §15 — why this is an alpha blocker.
- `scripts/player_profile.gd` — the existing example of a second `user://` file
  with defensive reads.
