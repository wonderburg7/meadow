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
| SV-1 | Saving still looks the same, but the run now also keeps three automatic recovery points, and a save carries the name of the run it belongs to. | `scripts/save_slots.gd`, `scripts/saving.gd`, `scripts/main.gd` | yes | medium |
| SV-2 | A Saves window lists every run and recovery point with its day and time, and loads or deletes one. | `scripts/saves_panel.gd`, `scripts/hud.gd` | yes | medium |

**Dependencies, stated rather than implied by order.**

- SV-2 needs SV-1's catalogue to list anything, and waits on **F2s**
  (`plans/design/architecture-review.md`) because both own `scripts/hud.gd`.
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

## SV-1 — a save is a named slot, and the run keeps three

Level: medium.

- **Required reading.** This heading.
  `python tools/func.py scripts/save_game.gd save read has_save`.
  `scripts/saving.gd` lines 1 to 20 only (`save_run` and the header) — the
  `_restore_*` helpers below it are not touched and are most of the file.
  `scripts/tutorial_checkpoint.gd` whole (54 lines), as the pattern for a
  second save path that already works.
- **Files to change.** New `scripts/save_slots.gd`, `scripts/saving.gd`,
  `scripts/main.gd`.
- **Files not to change.** `scripts/save_game.gd` — it already takes a path,
  which is the only thing this slice needs from it. `scripts/save_migrations.gd`
  and `FORMAT_VERSION` — nothing about the file's *contents* changes, so a bump
  here would be a migration that migrates nothing.
  `scripts/tutorial_checkpoint.gd`, for the reason above.
- **The owner is a new `save_slots.gd`, and here is why it is not an existing
  file.** `save_game.gd` serialises one run to one path and should keep doing
  exactly that. `saving.gd` performs the act of saving and restoring against
  `main`. Neither owns "which files exist, what they are called and which may be
  deleted", and putting a directory catalogue in either would give one file two
  jobs. `save_slots.gd` is pure path-and-index work with no `main` reference,
  which also makes it testable without a world.
- **Requirements.**
  1. `save_slots.gd` owns `user://saves/`, creating it on first use. A slot is
     `user://saves/<slug>.json`, where `<slug>` is the player's run name reduced
     to lowercase letters, digits and hyphens. A checkpoint is
     `user://saves/<slug>.checkpoint<N>.json` for N in 1..3.
  2. `func checkpoint(slug: String) -> String` returns the path the next
     checkpoint should be written to, rotating 1 → 2 → 3 → 1 so the oldest is
     the one overwritten. The rotation index lives in the index file, not in a
     scan of the directory.
  3. An index file `user://saves/index.json` records, per slug, the display
     name, the last-saved day, the last-saved wall-clock time and the next
     checkpoint number. `func list_slots() -> Array` returns it sorted by
     last-saved, newest first. A missing, empty or corrupt index must be treated
     as "no saves", never as an error that stops the game — the same defensive
     shape `save_game.gd::read` and `player_profile.gd` already use.
  4. `saving.gd::save_run()` gains an optional name, defaulting to the current
     run's slug, and writes through `save_slots.gd`. `saving.gd` gains
     `func checkpoint() -> void`, connected to `main.gd`'s `day_changed`, which
     writes a rotating checkpoint every `GameConfig.checkpoint_every_days` days.
  5. `GameConfig` gains `checkpoint_every_days: int = 5`, matching
     product-scope §6.1's "every five days", with a `settings_catalogue.gd`
     entry tagged `persist: "run"`. **If adding the catalogue row would put
     `settings_catalogue.gd` in this slice's file list and collide with the
     other lane, hardcode 5 in `saving.gd` with a comment naming this
     requirement and say so at closeout** — the constant's home is a smaller
     question than the slice.
  6. **Migrating the existing save.** On first run after this slice, an existing
     `user://meadow_save.json` is adopted into the catalogue as a slot named
     "My colony" rather than ignored or deleted. Dave has saves; losing them to
     a directory change is the exact failure this plan exists to prevent.
- **Invariants.** Saving and loading from the HUD behaves as it does today — the
  same button, the same confirmation, the same warning text. A checkpoint is
  never written over the player's own named save. `tutorial_checkpoint.gd`'s
  path is untouched and never appears in `list_slots()`.
- **Runtime policy.** A checkpoint is written **on the `day_changed` signal**,
  every fifth day, never on a timer and never per frame. Writing a save walks
  the whole world, so it must not be attached to anything that fires more often.
  `list_slots()` reads the index file, not the directory, and is called only
  when something is about to display it.
- **Automated acceptance.** A new `tests/` module is **not** how this is proved
  — `tests/` belongs to the Codex lane while `plans/now/feedback-build.md` is
  open. Prove it with `tools/godot_compile_check.py` plus a scenario that saves,
  advances ten days and confirms three checkpoint files and one named slot
  exist, then loads the named slot and reaches the same day.
- **Escalation.** If `user://` turns out to already contain something at
  `user://saves`, or if adopting the existing save cannot be done without
  reading its contents, stop and say so before writing anything — this slice's
  whole justification is that it does not touch save contents.

```queue
**[Claude] SV-1 -- a save is a named slot, and the run keeps three**
- Plan: `plans/now/named-saves.md` -- "SV-1 — a save is a named slot, and the run keeps three"
- Files: `scripts/save_slots.gd`, `scripts/saving.gd`, `scripts/main.gd`
- Check: saves live in `user://saves/` under a slug, a rotating three-deep checkpoint is written on `day_changed` every fifth day and never over the player's own save, an index file survives being missing or corrupt by reporting no saves, an existing `user://meadow_save.json` is adopted as a named slot rather than lost, and `save_game.gd`'s `FORMAT_VERSION` is unchanged
- Proof: `absent: scripts/saving.gd :: checkpoint`
- Next after: SV-2 -- the Saves window.
```

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
