# Saves access — Dave's 28 Sep 2026 pass

<!-- CONTEXT: plan | LAYER: immediate-task -->
Status: active | Owner: Dave / Claude Code | Next: SA-1 -- the Saves window is reached from the cog only, everywhere, startable after BS-2 (see Dependencies) | Dependency: BS-2 in `plans/now/brood-spine.md` edits the same fixture | Verified: 2026-09-28

**Objective.** One way into the Saves window -- the settings cog -- that works
the same in a run and on the main menu, and a Delete that always asks.

**State, verified 28 Sep 2026.** SV-2 put a Saves button on the top bar's
second row (`hud.gd::_build_top_right_bar`, `saves_button`). The cog's
"Load run" (`debug_panel.gd::_on_load_pressed`) opens the Saves window in a
sandbox run but, when the main menu is showing or a Challenge is running,
loads the most recent named save straight away -- deliberately, per its SV-3
comment, because the window would open behind the menu. Dave hit that on
28 Sep (C-62's first step). `saves_panel.gd::_on_delete_pressed` confirms
only when `Session.warn_on_discard` is on; Dave's profile has it off, so
Delete went straight through.

**Decisions (Dave, 28 Sep 2026).** The Saves window is reached only from the
settings window; the top-bar button goes. The cog's "Load run" is renamed
"Saves..." and opens the window in a run and from the main menu; "Save run"
stays as the quick save. Deleting a saved run always asks, whatever the
discard-warning setting says.

## Open slices at a glance

| Slice | Outcome from the player's seat | Files owned | Startable | Level |
| --- | --- | --- | --- | --- |
| SA-1 | The cog's Saves... opens the Saves window everywhere; no top-bar button; Delete always asks | `scripts/hud.gd`, `scripts/debug_panel.gd`, `scripts/saves_panel.gd`, `scripts/availability.gd`, `test_scenarios/f2s_challenge2_gate_table_test.json` | after BS-2 | medium |

**Dependencies.** BS-2 (`plans/now/brood-spine.md`) also edits
`test_scenarios/f2s_challenge2_gate_table_test.json`; it is ahead of SA-1 in
the Claude lane, so SA-1 starts from BS-2's version. **Required reading:**
SA-1 below and the functions it names. **Do not change** the Challenge
behaviour of the cog's button (below) or `saves_panel.gd::_load`.

## SA-1 — the Saves window is reached from the cog only, everywhere

Level: medium.

**Change.**

- `hud.gd::_build_top_right_bar`: delete the `saves_button` block (the
  `_icon_button("save", ...)`, its `pressed` connection, `add_child` and
  `_register_gated_control("saves_button", ...)`) and the `saves_button`
  field. `saves_panel` itself stays: hud.gd still creates it.
- `availability.gd`: delete the `"saves_window"` row from `UI_GATES` (its
  only control was `saves_button`; nothing else reads the key).
- `f2s_challenge2_gate_table_test.json`: delete the two
  `hud/**/saves_button` asserts.
- `debug_panel.gd`: `load_btn.text = "Saves…"`; its info text becomes "Open
  the Saves window: save this run by name, load a save or one of its
  checkpoints, or delete one." In `_on_load_pressed`, open the Saves window
  when a world exists and either the main menu is showing or no Challenge
  is running (`not (Session.starting_level in [1, 2])`). Only an in-run
  Challenge keeps today's fallback (load the latest named save).
- `saves_panel.gd`: keep the "Save this run" button as a field
  (`save_run_btn`). In `open()`, when a `main_menu` group node is visible,
  set `layer = 21` (the settings window's own over-the-menu layer,
  `debug_panel.gd::_apply_layer_for_context`) and hide `save_run_btn`;
  otherwise `layer = 11` and show it.
- Delete always asks: `_on_delete_pressed` loses its `warn_on_discard`
  early return. `hud.gd::confirm_discard` gains
  `offer_stop_warning: bool = true`; keep the "Discard, and stop warning me"
  button `add_button` returns as `discard_always_button` and set its
  `visible` to that argument. The Delete call passes `false`; the cell
  discard path sets it visible before its own `popup_centered()`.
- Regenerate `FUNCTION_MAP.md` (`python tools/update_function_map.py`).

**Acceptance (checks filed at closeout, one condition each).** The top bar
has no Saves button. On the main menu, cog → "Saves…" shows the Saves window
over the menu, and Load there starts that run. Delete asks "are you sure"
even with the discard warning switched off.

**Escalate** if the Saves window cannot draw over the main menu at layer 21,
or if anything other than `saves_button` reads the `"saves_window"` key.

```queue
**[Claude] SA-1 -- the Saves window is reached from the cog only, everywhere**
- Plan: `plans/now/saves-access.md` -- "SA-1 — the Saves window is reached from the cog only, everywhere"
- Files: `scripts/hud.gd`, `scripts/debug_panel.gd`, `scripts/saves_panel.gd`, `scripts/availability.gd`, `test_scenarios/f2s_challenge2_gate_table_test.json`
- Check: `python tools/run_scenario.py test_scenarios/sv2_saves_window_test.json` and `test_scenarios/f2s_challenge2_gate_table_test.json` pass, and `tools/verify.ps1` is green
- Proof: `present: scripts/hud.gd :: saves_button = _icon_button(`
- Next after: none -- plans/now/saves-access.md is complete
```
