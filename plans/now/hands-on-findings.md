# Hands-on findings -- what the 2 Oct 2026 pass turned up beside its checks

<!-- CONTEXT: plan | LAYER: immediate-task -->
Status: active | Owner: Dave / Claude Code | Next: HO-1 -- Escape closes the skill tree (after UT-2, same file) | Dependency: HO-1/HO-2 follow UT-2 (`plans/now/ui-texture-polish.md`); HO-3/HO-4 follow SC-3 and HO-5/HO-6 follow SC-4 (`plans/now/settings-and-corner.md`); HO-7 is startable (Dave chose option (b), 2 Oct 2026); HO-8 waits on Dave's C-84 verdict | Verified: 2026-10-02

**Objective.** The defects a computer-use pass over C-60 to C-92 found on
2 Oct 2026 that no open plan already owns are fixed. Presentation and
developer tooling only, except HO-7 (Challenge stage pacing), a
decision Dave took on 2 Oct 2026. The skill-screen and HUD plans that owned these areas are archived,
so they start here (`plans/README.md`, "Plan schema").

**Already owned elsewhere, so not repeated here.** C-60's faint textures
(UT-1) and Buy under Dr Gallerin, which failed C-80 (UT-2):
`plans/now/ui-texture-polish.md`. Light theme leaving the Colony hint and the
HUD stats unreadable (UT-3, UT-4). C-72's quick + clicks landing on Typeface
(SC-1) and the boot's GDScript warnings (SC-3):
`plans/now/settings-and-corner.md`. C-81 tests a run that owns Nurses from
the start (BS-10), and the developer table lists cut skills as buyable
(BS-11): `plans/now/brood-spine.md`. A nurse switched to another job loses
her brood food (GC-4): `plans/now/gameplay-consistency.md`.

| Slice | Outcome | Files | Startable | Level |
| --- | --- | --- | --- | --- |
| HO-1 | Escape closes the skill tree | `scripts/skill_tree_panel.gd` | no -- after UT-2 (same file) | high |
| HO-2 | every skill's name reads whole in its hex | `scripts/skill_tree_panel.gd` | no -- after HO-1 (same file) | medium |
| HO-3 | the Triggers live under Developer mode, and one ends the run | `scripts/debug_panel.gd` | no -- after SC-1 and SC-3 (same file) | medium |
| HO-4 | the Saves window's name field is usable and always opens on top | `scripts/saves_panel.gd` | no -- after SC-3 (same file) | medium |
| HO-5 | long text stays inside its window | `scripts/hud.gd`, `scripts/gallerin_panel.gd`, `scripts/winter_panel.gd` | no -- after SC-4, UT-3 and UT-4 | medium |
| HO-6 | a bee under the top-left readout can be clicked | `scripts/hud.gd` | no -- after SC-4 (same file) | low |
| HO-7 | each Challenge stage stays on screen a moment before the next can clear | `scripts/challenge_runner.gd`, `scripts/challenge_stages.gd` | yes -- queued | high |
| HO-8 | Challenge 2's 2.9 shows which targets are still short | `scripts/challenge_runner.gd`, `scripts/hud.gd` | gated -- Dave's verdict on C-84 | medium |

**Dependencies.** HO-1 then HO-2 (one file). HO-3 and HO-4 each wait for the
SC slice that owns their file. HO-5 and HO-6 both edit `scripts/hud.gd`, so
they run one after the other, after SC-4, UT-4 and SR-4 have landed. HO-7
goes before HO-8; both edit `scripts/challenge_runner.gd`.

**What a slice reads.** Its own section below, and the function it names.
Every "Seen" line is from the 2 Oct 2026 pass, driven by computer use in a
maximised window; the 1-2 s capture lag noted in `ui-texture-polish.md`
("Source") applied, and each sighting below survived a re-capture.

## HO-1 -- Escape closes the skill tree

<!-- LAYER: immediate-task -->

**True now.** `skill_tree_panel.gd::_input` closes the view on
`KEY_ESCAPE` and swallows every other key. Seen: with the tree open over
Scenario 2, Escape did nothing three times (pointer still, then over the
tree, then after a click on empty tree). Ctrl+1 a moment later reached the
game ("Group 1 cleared."), so keys were arriving. × closed it and restored
speed 2 every time. So the handler exists and does not run, or runs after
another node has already consumed Escape -- an inference, not a diagnosis.

**True afterwards.** Escape closes the tree and restores the speed it had,
exactly as × does. Reproduce first; if Escape works, stop and report.
Likely places: a node earlier in `_input` order handling Escape (the
settings window or HUD), or the layer's process mode while the tree is
paused.

**Must not change.** The swallowing of every other key while the view is
open (Space and Tab must not reach the paused game), C-79's full-screen
pause, and × closing it.

## HO-2 -- every skill's name reads whole in its hex

<!-- LAYER: immediate-task -->

**True now.** `SkillGrid._draw` wraps each name to `tile_size * 1.4` across
`NAME_LINES` (3) lines in the "Small" font. Seen at the opening zoom, text
scale 2, Silkscreen: words are cut, not wrapped -- "CLEA", "ORIE FLIGH",
"TARS SECR", "WEIG FLOW CHOI" -- so C-88's PASS ("every skill's name is
readable inside its hexagon") fails.

**True afterwards.** At the opening zoom, at text scale 1 and 2, in
Silkscreen and Atkinson Hyperlegible, every name shows every letter: a word
that cannot fit breaks with a hyphen or the name drops to a smaller size, and
the detail strip still gives the full name. File a hands-on check that
replaces C-88.

**Must not change.** Drag, wheel zoom and `_min_zoom` (C-88's other two
parts passed), and the hover tooltip.

## HO-3 -- the Triggers live under Developer mode, and one ends the run

<!-- LAYER: immediate-task -->

**True now.** `debug_panel.gd::_build_actions` builds the Triggers group
(Advance Challenge stage, Fire test warnings, Force Challenge 2 collapse)
for every player. Only Run availability is behind `Session.developer_mode`
(`_refresh_developer_row`). No trigger reaches "The queen is dead": Force
Challenge 2 collapse gives the rescue, then a checkpoint rewind. So C-86
could not be run on 2 Oct (blocked). The Return to Main Menu tip still
offers "Level 1 (the queen alone), Level 2 ... Level 3", which the menu no
longer has.

**Decision (Dave, 2 Oct 2026).** The Triggers are hidden with Developer mode
off: the feedback build's tester must not see "Force Challenge 2 collapse".

**True afterwards.** With Developer mode off the Triggers group -- header
and every button -- is absent, not disabled, and it appears or goes as the
box is ticked, through the refresh `_refresh_developer_row` already runs.
A new "End the run" trigger kills the queen through
`bee_survival.gd::die`, so `main.gd::_check_for_loss` opens `game_over.gd`'s
"The queen is dead" exactly as a real death does; it does nothing in a
scenario run, which `_check_for_loss` ends differently. The Return to Main Menu tip describes the current menu. C-86 then
runs as written.

**Must not change.** Each existing trigger's behaviour, and Run
availability's guard (`tests/source_checks.py` checks it).

```queue-gated
**[Claude] HO-3 -- the Triggers live under Developer mode, and one ends the run**
- Plan: `plans/now/hands-on-findings.md` -- "HO-3 -- the Triggers live under Developer mode, and one ends the run"
- Files: `scripts/debug_panel.gd`
- Check: with Developer mode off no Triggers header or button is built, "End the run" in a Challenge or level run opens "The queen is dead", a Godot boot is clean, a hands-on check is filed, and `tools/verify.ps1` is green
- Proof: `absent: scripts/debug_panel.gd :: End the run`
- Next after: HO-4 -- the Saves window's name field is usable and always opens on top
```

## HO-4 -- the Saves window's name field is usable and always opens on top

<!-- LAYER: immediate-task -->

**True now.** `saves_panel.gd` puts "Name this run:", the `LineEdit` and
Save on one row. Seen: the field was about seven characters wide ("My
colo"). Also seen: with the Saves window left open in a run, Return to Main
Menu then cog -> "Saves…" showed nothing on top. The run's window stayed
dimmed behind the menu, still with "Save this run". After closing it in the
run, the same steps opened it correctly over the menu. `open()` sets
`layer` from the menu's visibility; whether it runs for a window already
open is not yet known.

**True afterwards.** The name field shows at least 24 characters (its own
row if need be), and "Saves…" from the main menu opens the window on top of
the menu whether or not it was left open in the run. Reproduce the second
part first.

**Must not change.** C-77 and C-78 (passed 2 Oct 2026): no "Save this run"
over the menu, Load starts the run, Delete always asks.

## HO-5 -- long text stays inside its window

<!-- LAYER: immediate-task -->

**True now.** Seen: problem lines under the stats ("Mighty Fern is annoyed
that there is nowhere to put the nectar she gathered -- how can she work
un...") run off the right edge and under the settings window. The one-line
description shown on hovering the cog runs off the right. Dr Gallerin's
bubble cuts words at its right edge ("DESIGNATE A CELL FOI"). The Winter
window runs off the bottom of the screen and opens over the selected bee's
panel instead of replacing it. Around day 7 at speed 8 it closed and
reopened within about 3 s.

**True afterwards.** Every one of these wraps or scrolls inside its own
window, and the Winter window follows the left-window rules (C-74, passed).
Diagnose first: SC-4 ("left windows follow its height") may already fix the
Winter window and the problem lines. Re-run the sightings after SC-4 lands
and drop whatever it fixed. Split per file if more than one remains.

**Must not change.** The corner column SC-4 builds, and the Winter window
opening by itself on day 6 (C-91, passed).

## HO-6 -- a bee under the top-left readout can be clicked

<!-- LAYER: immediate-task -->

**True now.** Seen in Scenario 4's meadow: a click on forager 4N, drawn
under the stats lines ("Hive health..."), selected nothing. The same click
on a bee clear of the text selected it. Which control takes the click is
not yet known: `energy_label` is built in `hud.gd` with no `mouse_filter`.

**True afterwards.** Text in the top-left readout passes clicks through to
the world, unless the text is itself interactive. Find the control first.

**Must not change.** Anything in the corner that is meant to be clicked.

## HO-7 -- each Challenge stage stays on screen a moment before the next can clear

<!-- LAYER: immediate-task -->

Level: high (event ordering in every Challenge's stage flow).

**True now.** `challenge_runner.gd::_process` calls `_advance()` the first
frame a stage's goal is met, and `_enter_stage` runs the next stage's check
from its own first poll. So any later stage whose goal is already true
clears straight after it. 2.3's condition (`challenge_stages.gd`) accepts
an explicit nectar, pollen or brood designation, and choosing a Raises role
reserves the cell for Eggs, which counts. Seen on 2 Oct 2026: at 2.2 I set a
developing larva's cell to raise a pollen Forager. When it hatched, 2.2, 2.3
and 2.4 (whose reserve was already met) all cleared within one poll, and
the next thing on screen was 2.5. The player never saw 2.3's lesson or
2.4's goal.

**Decision (Dave, 2 Oct 2026): option (b).** Every stage holds for a minimum
time before it can clear. A Raises choice still counts for 2.3 (option (c)
declined). Applies to Challenge 1 and Challenge 2 alike.

**True afterwards.** A stage cannot clear until it has been on screen for
`MIN_STAGE_DWELL` game seconds (5.0 to start; a named constant beside the
other stage constants in `challenge_stages.gd`), counted from
`_enter_stage` while the game is unpaused, in game time so speed 8 shortens
it with everything else. A goal met earlier clears the moment the dwell
ends. Each stage's goal text and its delay-0 Dr Gallerin line are therefore
on screen first. Runtime policy: one float added per frame in `_process`,
which already runs every frame; no new scan. The debug stage arrows and
`debug_advance_stage` bypass the dwell. A checkpoint restore that re-enters
the same stage restarts it.

**Must not change.** Stage order, goals and conditions; Challenge 2's rescue
and failure (`_check_c2_failure`); the goal-poll cadence (`GOAL_CADENCE`).
Every Challenge fixture in `test_scenarios/` (`h4_challenge1_stage_advance`,
`f2s_challenge2_gate_table`, `bs9_c2_queen_nurses`,
`uiw2_challenge2_raises_forager`, `hf6_challenge2_raises` and the rest)
still passes. Escalate if one needs its timings changed rather than
lengthened.

```queue
**[Claude] HO-7 -- each Challenge stage stays on screen a moment before the next can clear**
- Plan: `plans/now/hands-on-findings.md` -- "HO-7 -- each Challenge stage stays on screen a moment before the next can clear"
- Files: `scripts/challenge_runner.gd`, `scripts/challenge_stages.gd`
- Check: a Godot boot is clean, every Challenge fixture in `test_scenarios/` passes, a hands-on check is filed for 2.2 -> 2.3 -> 2.4 each showing on screen when one hatch satisfies all three, and `tools/verify.ps1` is green
- Proof: `absent: scripts/challenge_stages.gd :: MIN_STAGE_DWELL`
- Next after: HO-8 -- Challenge 2's 2.9 shows which targets are still short
```

## HO-8 -- Challenge 2's 2.9 shows which targets are still short

<!-- LAYER: immediate-task -->

**True now.** At 2.9 (reached with the stage arrows) the goal text lists all
seven targets, but `hud.gd::set_challenge_goal` shows one bar and one count:
"400 / 300", while the HUD's own Nectar read 376. The HUD does not split
nectar from pollen Foragers or count miners. Dr Gallerin still showed 2.8's
line, since 2.9's `prompts` list is empty. C-84 asks whether a player can
finish 2.9 without guessing; the 2 Oct pass left that verdict to Dave
(FEEL, leaning fail).

**Gate.** Dave's verdict on C-84. If it fails, this becomes the "Challenge 2
goal-presentation slice" `checks/ready/C-84.md` names. Either way, find
where `c2_complete`'s progress pair comes from and why it read 400 against
376.

**True afterwards.** Specified when the gate clears.
