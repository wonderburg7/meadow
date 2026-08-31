# Settings catalogue — GameConfig as the authority, the panel as a view

<!-- CONTEXT: plan | LAYER: design | LOAD: only when settings/config ownership is selected -->
Status: designed, not scheduled | Owner: Dave / Claude Code | Next: select Slice 1 (reset coverage) only when settings ownership becomes active work; Slice 2 (extraction) depends on it | Dependency: no active implementation slice | Verified: 2026-09-01

Parked here on Dave's call (1 Sep 2026) from the architecture/performance
review. Documentation only; no code has changed.

One idea underlies both slices below: **`game_config.gd` is the authority for
what a setting is, and `debug_panel.gd`'s table is a view of it.** Today that
is inverted — the settings-window table is treated as the list of settings,
and anything absent from it is invisible to code that should know better.
This is the same mistake, one level up, that `prerequisites.gd` was extracted
to fix (`DESIGN_BACKLOG.md` section 13, slice 3): a rule that only existed
inside a checkbox widget.

<!-- LAYER: immediate-task -->

## Slice 1 — `reset_config_to_defaults()` misses 44 GameConfig fields

**Confirmed.** `debug_panel.gd::reset_config_to_defaults()` iterates
`TUNABLES` and resets each key from a fresh `GameConfig` instance. But
`Levels.apply_config_overrides()` validates against `GameConfig`'s *own*
property list and can therefore write any field. There are 171 `TUNABLES`
keys against 196 `GameConfig` script variables.

The 44 with no settings row are, unhelpfully, the ones headless work tunes
most: `forage_search_radius`, `forage_perception_radius`, `known_patches_max`,
`known_patch_min_spacing`, `adaptive_constancy_gain`/`_decay`/`_weight`,
`handling_experience_floor`/`_visits_to_floor`,
`probabilistic_choice_heading_weight`, `cell_full_threshold`,
`flower_lifespan_days`/`_variation`, `flower_regrow_seconds`,
`forager_return_route_factor`/`_safety_margin`, `min_worthwhile_amount`,
`thin_flower_fraction`, `poor_patch_search_streak`, `starting_miners`,
`hive_entrance_width`, the `trait_*`/`fact_*` identity odds, and the whole
`rival_*` economy block.

`TUNABLES` also contains `"fps"`, which is a star row (a
`Session.pinned_stats` entry), not a config field at all.
`reset_config_to_defaults()` currently calls `GameConfig.set("fps", null)` on
it — a silent no-op, because Godot's `Object.set()` ignores unknown
properties. Harmless today; a silent failure path either way.

**Consequence.** Latent, not currently player-reachable: all four
`scenario_presets.gd` override keys (`energy_burn_rate`,
`nectar_recharge_rate`, `pollen_recharge_rate`, `winter_burn_factor`) happen
to be in `TUNABLES`, so the pre-run menu's Scenario picker is safe today. But
the C3 fix this function exists for — `GameConfig` is an autoload and survives
`reload_current_scene()`, so a tweak must not leak into the next run — is only
complete for the 171 keys that happen to have a settings-window row. Any
future preset, or a `--scenario=` `config_overrides` block, touching one of
the 44 leaks into whatever the player picks next in the same process.

**Fix.** Derive the key set from `GameConfig` rather than from a UI table:

```gdscript
static func reset_config_to_defaults() -> void:
	var defaults = GameConfig.get_script().new()
	for prop in GameConfig.get_property_list():
		if prop.usage & PROPERTY_USAGE_SCRIPT_VARIABLE:
			GameConfig.set(prop.name, defaults.get(prop.name))
	defaults.free()
```

This is the same `PROPERTY_USAGE_SCRIPT_VARIABLE` filter
`Levels.apply_config_overrides()` already uses to decide what a valid key is,
so the two agree by construction. It also drops the `SESSION_KEYS` special
case — no Session preference is a `GameConfig` property, so none can be
reached by this loop — and the `"fps"` oddity with it.

**Non-goals.** Do not add `TUNABLES` rows for the 44; most are deliberately
not player-facing. Do not change `apply_config_overrides`. Do not move the
function yet — that is Slice 2.

**Tests.** Add to `tests/source_checks.py`: every `TUNABLES` key must resolve
to either a `game_config.gd` `var` or a `SESSION_KEYS` entry, allowing an
explicit star-row exemption. That check would have caught `"fps"`, and is the
durable guard once the catalogue moves in Slice 2. A behavioural check belongs
in the scenario harness: apply an override to one of the 44, call
`reset_config_to_defaults()`, assert the field equals its declared default.

**Save / determinism.** None; config defaults are not serialised.
**Rollback.** Revert the function body.

## Slice 2 — Move the settings catalogue out of the settings window

**Evidence.** `debug_panel.gd` is 1781 lines, of which roughly 900
(`COLLECTIONS`, `TUNABLES`) are pure data: 171 rows of
`{key, label, category, step, min, max, tip, toggle, options, star}`. Beside
them sit `SESSION_KEYS`, `setting_get`/`setting_set`, `apply_setting` and the
three `_cascade_*_static` helpers — all `static`, and all already called from
non-visual code:

- `scenario_actions.gd::_do_set_config` calls `DebugPanel.apply_setting`.
- `main.gd::_on_scenario_chosen` calls `DebugPanel.reset_config_to_defaults`.

So headless and scenario code already depends on a `CanvasLayer` script that
preloads `Hud`, `UiTheme`, `SaveGame` and `UI` in order to reach a table of
numbers.

**Target shape.** `scripts/settings_catalogue.gd`, a `RefCounted` leaf with no
dependencies beyond `prerequisites.gd`, holding `COLLECTIONS`, `TUNABLES`,
`SESSION_KEYS`, `setting_get`/`setting_set`, `apply_setting`,
`reset_config_to_defaults` and the three cascade helpers. `debug_panel.gd`
keeps every widget-building function (`_make_row`, `_make_toggle_row`,
`_make_options_row`, `_make_star_row`, `_make_section`, `_make_collection`,
and the checkbox-syncing cascade wrappers) and reads the catalogue. Same
authority/presentation split `prerequisites.gd` and `availability.gd` already
established.

**Ordered steps.**

1. Create `settings_catalogue.gd`; move the constants and static functions
   verbatim, changing nothing about any key, label, tip, step or default.
2. Point `debug_panel.gd` at it via `const Settings = preload(...)` and delete
   the moved definitions.
3. Repoint `scenario_actions.gd` and `main.gd` at `Settings` rather than
   `DebugPanel`.
4. Move the Slice 1 source check onto the new file.

**Non-goals.** No key, label, tip, default, category or ordering changes. No
typed Godot `Resource` per setting — a dictionary catalogue matches every
other catalogue in this codebase (`roles.gd`, `resources.gd`,
`challenge_stages.gd`) and nothing here needs editor tooling or per-row
validation beyond the source check. No new settings. No widget changes.

**Benefit.** `debug_panel.gd` drops to roughly 850 lines; headless and
scenario code can query settings without touching the UI tree; and there is
one place a test can assert every key resolves.

**Verification.** `tools/verify.ps1`, plus one scenario run exercising the
`set_config` verb to prove the cascade path still works end to end. No
hands-on check — nothing player-visible changes. **Save / determinism.** None.
**Rollback.** The move is mechanical; `git revert`.

<!-- LAYER: on-demand -->

## Read on demand

- `scripts/debug_panel.gd` — `COLLECTIONS`/`TUNABLES` (lines ~33–951),
  `SESSION_KEYS` and the static block (~952–1048).
- `scripts/game_config.gd` — the 196 field declarations.
- `scripts/levels.gd::apply_config_overrides` — the existing property-list
  validation this design reuses.
- `scripts/prerequisites.gd` — the precedent for pulling a rule out of the
  settings window.
- `tests/source_checks.py::check_catalogue_alignment` — the shape the new
  key-resolution check should follow.
