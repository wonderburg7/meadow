# Named saves and rolling checkpoints

<!-- CONTEXT: plan | LAYER: immediate-task -->
Status: active | Owner: Dave / Claude Code | Next: SV-2 -- the Saves window, queued in the Claude lane (SV-1 landed 23 Sep) | Dependency: none -- F2s has merged | Verified: 2026-09-23

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

**What is intended when this plan is done.** A run is saved under a name the
player chose, the game keeps the last three automatic recovery points behind
it, and both are reachable from the HUD without instruction.

## Open slices at a glance

| Slice | Outcome from the player's seat | Files owned | Startable | Level |
| --- | --- | --- | --- | --- |
| SV-2 | A Saves window lists every run and recovery point with its day and time, and loads or deletes one. | `scripts/saves_panel.gd`, `scripts/hud.gd` | yes | medium |

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

## SV-2 — the Saves window

Level: medium.

- **Required reading.** This heading. SV-1's result. `scripts/game_panel.gd`
  whole. One existing subclass, `scripts/winter_panel.gd`, for the pattern.
- **Files to change.** New `scripts/saves_panel.gd`, `scripts/hud.gd`.
- **Requirements.** A `GamePanel` subclass keyed `saves`, listing what
  `list_slots()` returns: display name, day, and how long ago it was saved, with
  each run's three checkpoints under it. Load and Delete per row, with Delete
  behind the existing `Session.warn_on_discard` confirmation rather than a new
  one. Saving asks for a name the first time a run is saved and reuses it after.
- **Invariants.** Every other window still opens, closes and sits where it did
  (`C-61`). The panel takes its rectangle from `ui_layout.gd` through the base
  class (HC-14).
- **Runtime policy.** The list is built on open and after a save or delete.
  Nothing polls the filesystem.
- **Hands-on check.** File one: name a run, play past two checkpoints, quit,
  reopen, load the middle checkpoint and confirm the colony is where it was.
  This is the alpha's single most important reliability claim and a static check
  cannot make it.

```queue
**[Claude] SV-2 -- the Saves window**
- Plan: `plans/now/named-saves.md` -- "SV-2 — the Saves window"
- Files: `scripts/saves_panel.gd`, `scripts/hud.gd`
- Check: a `GamePanel` subclass keyed `saves` lists every run and its three checkpoints with day and age, loads and deletes a row with deletion behind `Session.warn_on_discard`, and asks for a run name on first save; every other window still opens, closes and sits where it did
- Proof: `absent: scripts/hud.gd :: saves_panel`
- Next after: none -- named-saves is complete once SV-2 ships.
```

## Read on demand

<!-- LAYER: on-demand -->

- `.claude/rules/saving.md` — the standing rules for touching a save.
- `plans/design/product-scope.md` §6.1 and §15 — why this is an alpha blocker.
- `scripts/player_profile.gd` — the existing example of a second `user://` file
  with defensive reads.
