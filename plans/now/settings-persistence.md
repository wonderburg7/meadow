# Settings persistence across a run change

<!-- CONTEXT: plan | LAYER: immediate-task -->
Status: active | Owner: Dave / Claude Code | Next: Slice 1 (reset only what a preset owns, keep what the player set) | Dependency: none | Verified: 2026-09-02

New file, 2 Sep 2026. The settings-catalogue work that owned this area is
finished and archived at `plans/archive/SETTINGS_CATALOGUE_2026-09-01.md`;
per `plans/README.md` an archived plan is never reopened, so this finding
starts here.

## Slice 1 — Picking a Scenario wipes the player's settings, and should not

**Ask (Dave, 2 Sep 2026):** "When choosing the Scenario, and changing a
flower/season debug toggle, then choosing the Scenario, it resets to
default. It should keep the settings rather than reset, unless it's
settings that are integral to a given scenario or challenge."

**This reverses an intended behaviour, and that is deliberate.** The
current code is fix C3 from the 31 Aug hands-on batch, and its own check
was confirmed on 2 Sep as doing exactly what it was built to do:
`main.gd::_on_scenario_chosen` calls
`SettingsCatalogue.reset_config_to_defaults()` before
`ScenarioPresets.apply()`, which walks every `PROPERTY_USAGE_SCRIPT_VARIABLE`
property on the `GameConfig` autoload and writes the default back. C3 was
solving a real problem — a *preset's* overrides leaking from one run into
the next — but it solved it by wiping everything, including the toggles the
player set by hand. Dave has now made the call: preset values are the
run's, hand-set values are the player's, and only the first kind resets.

**Fix — reset what a preset owns, keep what the player set.**

- a) In `scenario_presets.gd`, record the key set the last `apply()` wrote:
  a `static var _last_applied_keys: Array[String]`, filled from the keys of
  the `overrides` dictionary `apply()` has already assembled, just before
  it calls `Levels.apply_config_overrides(overrides)`. Presets are applied
  from exactly one place, so one static is enough; say so in a comment.
- b) Add `static func reset_config_keys(keys: Array) -> void` to
  `settings_catalogue.gd` beside `reset_config_to_defaults()`, doing the
  same fresh-`GameConfig`-instance default read but only for the named keys.
  Keep `reset_config_to_defaults()` — it is still the right call for a full
  reset and other callers may want it.
- c) In `main.gd::_on_scenario_chosen`, replace the
  `reset_config_to_defaults()` call with
  `SettingsCatalogue.reset_config_keys(ScenarioPresets.keys_to_reset(preset_key, custom_overrides))`,
  where a new `ScenarioPresets.keys_to_reset()` returns the union of
  `_last_applied_keys`, `get_preset(preset_key).overrides`' keys and (for
  the `"custom"` preset) `custom_overrides`' keys. That clears the
  previous preset's fingerprints and everything the new one is about to set,
  and leaves every other `GameConfig` field exactly as the player left it.
- d) Leave `main.gd::_on_level_chosen` (the Challenge path) alone. It was
  checked on 2 Sep 2026 and resets no `GameConfig` field today; do not add
  a reset to it.

**Explicitly out of scope.** Do not touch `Session` preferences: they are
already persistent by design and go through `Session.save_preferences()`.
Do not add a "reset settings" button, a per-setting sticky flag, or any new
settings row — the ask is a change of default behaviour, not a new control.

**Acceptance.** Change a flower or season toggle in the settings window,
pick a Scenario, and the toggle is still where the player left it once the
run boots. Pick a Scenario with preset A, then restart and pick preset B:
none of A's values survive into B's run. Pick a Scenario with a custom
override, then one without: the override does not leak.

**Check:** `tools/verify.ps1`. One hands-on check to file: the acceptance
above, replacing the archived C3 entry.

**Files:** `scripts/main.gd`, `scripts/scenario_presets.gd`,
`scripts/settings_catalogue.gd`.

**Next after:** none — this plan is one slice unless the acceptance run
finds more.

<!-- LAYER: durable-rules -->

- A run change resets only the `GameConfig` keys a preset or Challenge
  actually writes. Anything the player set by hand survives until they
  change it back. `Session` preferences are never reset by a run change.
- `GameConfig` is an autoload, so it survives `reload_current_scene()`.
  Anything that must not carry over between runs has to be reset
  explicitly — and by name, not by wiping the object.

<!-- LAYER: on-demand -->

- Why the full reset existed: `plans/archive/HANDS_ON_FIXES_2026-08-31.md`
  Slice C3.
- Settings ownership and the `SESSION_KEYS` / `GameConfig` split:
  `scripts/settings_catalogue.gd`, then
  `plans/archive/SETTINGS_CATALOGUE_2026-09-01.md`.
