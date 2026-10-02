# Hands-on findings -- what the 2 Oct 2026 pass turned up beside its checks

<!-- CONTEXT: plan | LAYER: immediate-task -->
Status: active | Owner: Dave / Claude Code | Next: HO-1 -- Escape closes the skill tree (after UT-2, same file) | Dependency: HO-1/HO-2 follow UT-2 (`plans/now/ui-texture-polish.md`); HO-3/HO-4 are startable (SC-3 landed 2 Oct 2026) and HO-5/HO-6 follow SC-4 (`plans/now/settings-and-corner.md`); HO-7 is built on branch claude/HO-7 (option (b), Dave 2 Oct 2026; hands-on check filed); HO-8 is specified (Dave, 2 Oct 2026) and waits for the `scripts/hud.gd` and `scripts/main.gd` slices ahead of it; HO-9 is built on branch claude/HO-9 (hands-on check filed), HO-10 is built on branch claude/HO-10 (hands-on check C-96 filed), HO-11 waits for SR-4 (Codex lane) and the `scripts/hud.gd` slices ahead of it, HO-12 follows HO-9 (same file) | Verified: 2026-10-02

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
| HO-3 | the Triggers live under Developer mode, and one ends the run | `scripts/debug_panel.gd` | yes -- queued (SC-3 landed 2 Oct 2026) | medium |
| HO-4 | the Saves window's name field is usable and always opens on top | `scripts/saves_panel.gd` | yes -- queued (SC-3 landed 2 Oct 2026) | medium |
| HO-5 | long text stays inside its window | `scripts/hud.gd`, `scripts/gallerin_panel.gd`, `scripts/winter_panel.gd` | no -- after SC-4, UT-3 and UT-4 | medium |
| HO-6 | a bee under the top-left readout can be clicked | `scripts/hud.gd` | no -- after SC-4 (same file) | low |
| HO-8 | the HUD splits nectar and pollen Foragers and counts miners, so 2.9's shortfall can be read | `scripts/hud.gd`, `scripts/main.gd`, `scripts/challenge_runner.gd`, `checks/ready/C-84.md` | no -- after HO-7, HO-6 (`hud.gd`) and BS-6 (`main.gd`) | medium |
| HO-10 | a queen who starves ends the run with "The queen is dead" | `scripts/main.gd`, `scripts/game_over.gd`, a new headless test, `tools/verify.ps1` | yes -- queued; land before HO-8 (`main.gd`) | high |
| HO-11 | the role menus use the theme's font and the text scale | `scripts/hud.gd` | no -- after SR-4 and the `hud.gd` slices ahead of it | low |
| HO-12 | a Challenge or Scenario hex breaks its name between words | `scripts/main_menu.gd` | no -- after HO-9 (same file) | low |

**Dependencies.** HO-1 then HO-2 (one file). HO-3 and HO-4 each wait for the
SC slice that owns their file. HO-5 and HO-6 both edit `scripts/hud.gd`, so
they run one after the other, after SC-4, UT-4 and SR-4 have landed. HO-7
goes before HO-8; both edit `scripts/challenge_runner.gd`. HO-8 also edits
`scripts/hud.gd` (after HO-6) and `scripts/main.gd` (after BS-6). HO-9
then HO-12 edit `scripts/main_menu.gd`. HO-10 edits `scripts/main.gd` and
should land before HO-8, which edits it too. HO-11 edits `scripts/hud.gd`
after SR-4 and HO-8.

**What a slice reads.** Its own section below, and the function it names.
Every "Seen" line is from the 2 Oct 2026 pass, driven by computer use in a
maximised window; the 1-2 s capture lag noted in `ui-texture-polish.md`
("Source") applied, and each sighting below survived a re-capture.

## Second pass, 2 Oct 2026 -- check outcomes on build 932d320

<!-- LAYER: on-demand -->

A second computer-use pass (07:46-08:14) ran the ten then-ready checks on
build `932d320`, maximised, Developer mode on. UT-1 (08:02), UT-2 (08:12),
BS-10 (09:15), SC-1 (09:47) and UT-3 (13:32) merged after that build, so
every row marked "re-run" was tested against code that has since changed.
Nothing was confirmed. Texture readings are greyscale mean / sd / range of
the Colony window's empty lower margin.

| Check | Seen on `932d320` | Now |
| --- | --- | --- |
| C-60 | Dark: Honeycomb none (23.0 / 0.00 / 23-23), Grain faint (24.3 / 1.17 / 20-29) against Flat (23.0 / 0.38 / 21-24). Light: Honeycomb clear (218.0 / 9.25 / 191-237), Grain faint (223.6 / 1.15). High contrast: Honeycomb faint (11.9 / 3.07), Grain near none (10.0 / 0.55) | re-run after UT-1 |
| C-71 | tested to its old wording: High contrast text (up to ~205) stayed legible over a texture no brighter than 22 | re-run to the new wording (panels plain) after UT-1 |
| C-72 | four quick + (1.40 to 1.80) and four quick - (1.80 to 1.40) all landed with the pointer still; the panels resized about 1 s after the last click. 2.0 is the cap, so from Dave's baseline of 2 a + does nothing: step down first. The top-left stats readout did not change size | re-run after SC-1 |
| C-79 | the tree covers the window and the colony held (nectar 50 and Day 1 unchanged over ~40 s open at speed 2); x restores speed 2. Escape did not close it (three tries) while Space reached the game: HO-1. The HUD's pause readout is hidden under the tree; only the tree's own line says the colony is paused | Escape waits for HO-1 |
| C-80 | strip read "Honey worker (tier 1) -- can be bought. Cost: 150 nectar, 60 pollen."; a click on Buy's top-right did nothing (Dr Gallerin covers it), one at its lower-left bought it; tile and strip turned to owned; nectar 800 to 650 exactly, pollen 398 to 318 while nurses were eating | superseded by C-93 (UT-2) |
| C-81 | blocked: Scenario 1 starts with Nurses owned, and the queen's "Change to..." already offers Nurse | re-run after BS-10 |
| C-84 | not reached | unchanged |
| C-86 | blocked: no trigger ends the run (HO-3), and a queen who starved in Scenario 1 did not end it either: HO-10 | waits for HO-3 or HO-10 |
| C-88 | names cut ("CLEA" for Cleaning): HO-2. Drag works. The wheel stops zooming out with the tree about 675 px tall in a view about 610 px tall (screenshot pixels, text scale 2), so REST and AUTO RECR never show together: see HO-2 | names wait for HO-2 |

Seen in passing and already owned: the alert lines and the Skills tooltip
running off the right edge (HO-5, UT-2), PAUSED drawn over the readout's
"Recruiting" line (SC-4), the HUD stats dark red over the meadow in Light
(UT-3, UT-4), Light's Honeycomb muddying the Colony window's pale hint (UT-1,
UT-3).

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

**Seen again (second pass, build 932d320).** The cut names match. Zoom
did not fully pass there: maximised at text scale 2, the wheel stopped
zooming out with the tree about 675 px tall in a view about 610 px tall
(screenshot pixels), so REST and AUTO RECR never showed together.

**Decision (Dave, 2 Oct 2026).** HO-2 fixes the zoom limit too.

**True afterwards.** At the opening zoom, at text scale 1 and 2, in
Silkscreen and Atkinson Hyperlegible, every name shows every letter: a word
that cannot fit breaks with a hyphen or the name drops to a smaller size, and
the detail strip still gives the full name. The wheel zooms out until the
whole tree fits the view at text scale 1 and 2, maximised and at the default
window size (`_min_zoom`). File a hands-on check that replaces C-88.

**Must not change.** Drag (passed on both 2 Oct passes), and the hover
tooltip.

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

```queue
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

```queue
**[Claude] HO-4 -- the Saves window's name field is usable and always opens on top**
- Plan: `plans/now/hands-on-findings.md` -- "HO-4 -- the Saves window's name field is usable and always opens on top"
- Files: `scripts/saves_panel.gd`
- Check: the name field shows at least 24 characters; with the Saves window left open in a run, Return to Main Menu then cog -> "Saves…" opens it on top of the menu; a Godot boot is clean, a hands-on check is filed, and `tools/verify.ps1` is green
- Proof: `present: scripts/saves_panel.gd :: prompt.text = "Name this run:"`
- Next after: HO-5 -- long text stays inside its window
```

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

HO-7 shipped 2026-10-02; its specification is `plans/archive/HO-7_2026-10-02.md`.

## HO-8 -- the HUD splits nectar and pollen Foragers and counts miners, so 2.9's shortfall can be read

<!-- LAYER: immediate-task -->

**True now.** At 2.9 (reached with the stage arrows) the goal text lists all
seven targets -- 300 nectar, 150 pollen, 10 nectar Foragers, 4 pollen
Foragers, 2 nurses, 2 Comb workers, 2 miners -- but the screen cannot answer
them. `hud.gd::update_population` prints "Bees: %d foraging, %d nursing, %d
comb workers, %d on honey". `main.gd::_update_population_readout` adds the
nectar and pollen Forager counts together before passing them, and passes no
miner count, though `_role_counts` holds all of them. The goal shelf
(`set_challenge_goal`) showed one bar and count, "400 / 300", while the
HUD's Nectar read 376. Dr Gallerin still showed 2.8's line, since 2.9's
`prompts` list is empty.

**Decision (Dave, 2 Oct 2026, on C-84).** The HUD's population line splits
nectar from pollen Foragers and counts miners, so every 2.9 target can be
read off the screen. No per-target goal readout is added.

**True afterwards.**
- The population line reads, for example, "Bees: 6 nectar foragers, 2
  pollen foragers, 1 nursing, 2 comb workers, 1 mining, 0 on honey", in every
  run, not only Challenge 2. A count of zero still shows, so a shortfall is
  visible. `update_population` takes the split counts and the miner count;
  `_update_population_readout` passes them from `_role_counts`. Runtime
  policy unchanged: the readout already refreshes on population change.
- The "400 / 300" mismatch is explained and fixed: find which amount
  `Conditions.progress` reports for `c2_complete`'s condition (via
  `challenge_runner.gd::_goal_progress`) and make it the same nectar total
  the HUD shows, or drop the bar for a multi-target goal if it can only
  ever show one target.
- `checks/ready/C-84.md` keeps its question and points its Owner line at
  this plan; Dave re-runs it.

**Must not change.** The stores line; the goal shelf for single-target
goals; C-74's left-window layout (a longer line wraps inside the corner
column SC-4 builds).

```queue-gated
**[Claude] HO-8 -- the HUD splits nectar and pollen Foragers and counts miners, so 2.9's shortfall can be read**
- Plan: `plans/now/hands-on-findings.md` -- "HO-8 -- the HUD splits nectar and pollen Foragers and counts miners, so 2.9's shortfall can be read"
- Files: `scripts/hud.gd`, `scripts/main.gd`, `scripts/challenge_runner.gd`, `checks/ready/C-84.md`
- Check: the population line names nectar foragers, pollen foragers and miners in a Challenge 2 run, 2.9's goal bar agrees with the HUD's nectar or is absent, a Godot boot is clean, and `tools/verify.ps1` is green
- Proof: `present: scripts/hud.gd :: "Bees: %d foraging, %d nursing, %d comb workers, %d on honey"`
- Next after: HO-9 -- "Back to the run" on a fresh boot leaves the menu up
```

HO-9 shipped 2026-10-02; its specification is `plans/archive/HO-9_2026-10-02.md`.

## HO-10 -- a queen who starves ends the run with "The queen is dead"

<!-- LAYER: immediate-task -->

**True now.** Seen 2 Oct 2026 (second pass, build 932d320): Scenario 1 (the
queen alone, no comb) at speed 8 with no input. Her energy reached 0% by
Day 4; a click where she lay showed "Dapper Willow ... died of starvation,
lived 2.9 days", but the run went on into Day 5 at speed 8 and "The queen is
dead" never showed. Nothing was logged. `bee_survival.gd::die` frees the bee
and `main.gd::_check_for_loss` runs every unpaused frame, so the cause is not
visible from reading. Candidates: `game_over.gd::open` ran but draws under
the hive view; `main.queen` is not the bee that died; or the inspector showed
a memorial for another bee.

**True afterwards.** A headless test,
`tests/test_ho10_queen_starvation_ends_run.py` running
`tests/ho10_queen_starvation_ends_run_test.gd` in the style of
`tests/test_gc4_nurse_role_change_keeps_food.py` (`scripts/scenario_actions.gd`
is Codex-owned), starts the queen alone with no stores, lets her starve and
asserts `colony_lost` is set and "The queen is dead" is visible. It is listed
in `tools/verify.ps1`'s `$unitModules` and ships with the fix
(`plans/reference/check-loop.md`, rule 7). In a Challenge or level run a
queen who dies of any cause opens "The queen is dead". If the cause lies
outside the files the block names, stop and ask before widening it.

**Must not change.** How and when a bee starves, its epitaph, and scenario
runs ending "collapsed".

```queue
**[Claude] HO-10 -- a queen who starves ends the run with "The queen is dead"**
- Plan: `plans/now/hands-on-findings.md` -- "HO-10 -- a queen who starves ends the run with "The queen is dead""
- Files: `scripts/main.gd`, `scripts/game_over.gd`, `tests/test_ho10_queen_starvation_ends_run.py`, `tests/ho10_queen_starvation_ends_run_test.gd`, `tools/verify.ps1`
- Check: the new headless test fails on master before the fix and passes after it, a queen starved in Scenario 1 opens "The queen is dead", a Godot boot is clean, a hands-on check is filed, and `tools/verify.ps1` is green
- Proof: `absent: tools/verify.ps1 :: tests.test_ho10_queen_starvation_ends_run`
- Next after: HO-8 -- the HUD splits nectar and pollen Foragers and counts miners, so 2.9's shortfall can be read
```

## HO-11 -- the role menus use the theme's font and the text scale

<!-- LAYER: immediate-task -->

**True now.** Seen 2 Oct 2026 (second pass, build 932d320) at text scale 2 in
High contrast: the queen's Job row "Change to..." list (Forager, Nurse, Comb
worker, Idle, Miner) opened in Godot's small default font, unthemed, while
the inspector around it used the theme's font at scale 2. The menus are
`MenuButton`s built in `hud.gd`; their popups take no theme font or size.

**True afterwards.** Every `MenuButton` popup in the HUD (Job, Raises, the
selection cog) uses the theme's font, colours and the current text scale,
and follows a change to either.

**Must not change.** Which roles each menu offers (`hud.gd::_role_offered`,
C-81).

## HO-12 -- a Challenge or Scenario hex breaks its name between words

<!-- LAYER: immediate-task -->

**True now.** Seen 2 Oct 2026 (second pass) on the main menu at text scale 2
in Silkscreen: hex labels split words -- "CHALLENG / E 1 FIRST STORES",
"ESTABLIS / HED NEST". `main_menu.gd::_make_hex_tile` sets
`AUTOWRAP_WORD_SMART`, which breaks a word wider than the label.

**True afterwards.** At text scale 1 and 2, in every typeface, each hex shows
whole words: its label shrinks or the hex grows rather than splitting one.

**Must not change.** Challenges above Scenarios, the ticks, and the
selection outline.

```queue
**[Claude] HO-12 -- a Challenge or Scenario hex breaks its name between words**
- Plan: `plans/now/hands-on-findings.md` -- "HO-12 -- a Challenge or Scenario hex breaks its name between words"
- Files: `scripts/main_menu.gd`
- Check: at text scale 1 and 2 in every typeface each hex shows whole words, a Godot boot is clean, a hands-on check is filed, and `tools/verify.ps1` is green
- Proof: `present: scripts/main_menu.gd :: label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART`
- Next after: none -- the last slice in this plan
```
