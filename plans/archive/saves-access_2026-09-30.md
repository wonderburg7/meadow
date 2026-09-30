# Saves access — Dave's 28 Sep 2026 pass

<!-- CONTEXT: plan | LAYER: immediate-task -->
Status: complete | Owner: Dave / Claude Code | Next: None — plan complete; follow-ups: hands-on checks C-76, C-77 and C-78 in checks/ready.md | Dependency: BS-2 in `plans/now/brood-spine.md` edits the same fixture | Verified: 2026-09-28

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

**Dependencies.** BS-2 (`plans/now/brood-spine.md`) also edits
`test_scenarios/f2s_challenge2_gate_table_test.json`; it is ahead of SA-1 in
the Claude lane, so SA-1 starts from BS-2's version. **Required reading:**
SA-1 below and the functions it names. **Do not change** the Challenge
behaviour of the cog's button (below) or `saves_panel.gd::_load`.

SA-1 shipped 2026-09-30; its specification is `plans/archive/SA-1_2026-09-30.md`.
