# Hands-on check archive

Completed entries from `HANDS_ON_CHECKS.md`, moved here once Dave has
confirmed them (or a headless/diagnostic-log check has stood in for a
hands-on one) so the live checklist doesn't accumulate write-ups anyone
has to re-read. Newest first. See `git log` for the commit that shipped
each item if more detail is needed.

## 3 Oct 2026 -- Dave's hands-on pass

### C-79 -- Skills fills the screen and pauses the game

What this checks: start a sandbox run, set the speed to 2, and press Skills on the top bar's second row. Then close the view with its × (and once more with Escape).

PASS: the skill tree covers the whole window and the colony stops (the pause readout shows); after closing, the colony runs again at speed 2.

If it fails, `skill_tree_panel.gd::open`/`close` are not pausing or restoring the tree, or the view is not anchored full-screen.

Owner: `plans/archive/skill-screen_2026-10-01.md`

### C-80 -- clicking a skill and pressing Buy buys it

What this checks: in a sandbox run with some nectar and pollen stored (a few in-game days in is enough), press Skills and click a skill tile drawn in the "can be bought" colour. Read the strip along the bottom, then press its Buy button.

PASS: the strip names the skill, its tier and its cost; after Buy, the colony's stores drop by that cost and the strip and the tile both show it as owned.

If it fails, the click is not reaching `SkillGrid._gui_input` or the strip's Buy (`_on_buy_pressed`) is not calling `buy_skill`.

Owner: `plans/archive/skill-screen_2026-10-01.md`

### C-93 -- Skills tooltip wraps on screen and Buy sits clear of Dr Gallerin

What this checks: Run the game, open the Skills window, and hover the Nurses tile near the right edge of the window. Then click an affordable skill and press the Buy button, which now sits at the left of the strip along the bottom, beside the skill's text.

PASS: The tooltip wraps into a narrow themed box fully inside the window, and one click on Buy (anywhere on the button) buys the skill.

If it fails, UT-2 reopens: a tooltip still running off-screen means SkillGrid's tooltip override is not being used; a missed Buy click means Dr Gallerin's layer still covers the button.

Owner: `plans/now/ui-texture-polish.md`

### C-71 -- High contrast panels stay plain

What this checks: switch Appearance to High contrast, then set Panel texture to Honeycomb and then Grain, and look at the Colony window.

PASS: in High contrast, Honeycomb and Grain both leave the Colony window plain, with no pattern behind the text.

If it fails, `scripts/ui_theme.gd::PanelBox._draw` is drawing a texture in High contrast.

Owner: `plans/now/ui-texture-polish.md`

### C-72 -- Text scale applies after a pause

What this checks: open the settings window during a Challenge, open World & start and Appearance, and set Text scale to 2.0 (2 is the most it goes to). Click − five times quickly to reach 1.50, wait two seconds, then click + four times quickly, keeping the pointer still.

PASS: + stays under the pointer for every click, Text scale reads 1.90, Typeface has not changed, and the whole interface resizes about a second after the last click.

If it fails, `scripts/debug_panel.gd::_adjust` re-lays the window on each click (or never applies the scale), or the Challenge stage navigator in World & start (`_make_challenge_stage_navigation`) changes height when the stage moves on, which shifts every row below it. SC-1 fixed that second cause: in C-72 run 1 (1 Oct 2026) the stage moved on mid-click and three + clicks changed Typeface. A stage change while you click is chance, so a pass doesn't prove that fix. The headless check in SC-1's plan section does.

Owner: `plans/archive/settings-and-corner_2026-10-03.md`

### C-96 -- A queen who starves in Scenario 1 opens "The queen is dead"

What this checks: from the main menu, start "Scenario 1 Queen alone" on
any preset, set the speed to 8 and give no orders at all. Watch until her
energy reaches 0% (around Day 4) and she dies of starvation.

PASS: the moment she dies, the dark-red "The queen is dead" panel covers the screen, the day counter stops, and "Try again" and "Main menu" both work.

If it fails, HO-10 (`plans/now/hands-on-findings.md`) reopens: the run
carrying on past her death means `main.gd::_check_for_loss` still misses a
freed queen; a panel that opens but sits behind something means
`scripts/game_over.gd`'s layer is wrong.

Owner: `plans/now/hands-on-findings.md`

### C-97 -- Developer mode shows the Triggers, and End the run opens The queen is dead

What this checks: open the debug menu in a Challenge run with Developer mode unticked, then tick it in the settings and press "End the run" under Triggers.

PASS: with Developer mode off there is no Triggers header or button, and with it on "End the run" opens "The queen is dead".

If it fails, HO-3 reopens in `scripts/debug_panel.gd` (or the Triggers show for a tester who should not see them).

Owner: `plans/now/hands-on-findings.md`

### C-98 -- Saves window name field shows 24+ characters and opens on top of the menu

What this checks: In a run, click the cog -> "Saves…", press "Save this run" on a fresh run and type a long name such as "My very long colony name 1"; then, leaving the window open, choose Return to Main Menu and press cog -> "Saves…".

PASS: The name field shows at least 24 characters on its own row, and the Saves window appears on top of the main menu without a "Save this run" button.

If it fails, the HO-4 slice reopens: `scripts/saves_panel.gd` (field width, or the layer refresh in `_apply_menu_context`).

Owner: `plans/now/hands-on-findings.md`

### C-95 -- Back to the run is absent on a fresh boot and works after Return to Main Menu

What this checks: <what Dave does, and where: the screen, the setting,
the control. Plain language -- say how to reach it, not what the code
does. One or two sentences.>

PASS: <the single condition, on this one line>

If it fails, <what a failure would change -- the value, the file, or the
slice it reopens. A check whose failure changes nothing does not belong
here.>

Owner: `plans/now/hands-on-findings.md`

## 2 Oct 2026 -- Dave's hands-on pass

### C-74 -- Winter forecast replaces Colony on the left

What this checks: in a running game with a winter scheduled (settings cog -> Winter section, or wait for the countdown), open the Colony window, then press the Winter button in the top-right bar.

PASS: the Winter forecast opens where Colony was, Colony closes, and nothing covers the top-right bar.

If it fails, `scripts/year_winter.gd::_toggle_panel` or `scripts/winter_panel.gd` is not using the left-window rules and HF-4 reopens.

Owner: `plans/archive/hud-followups_2026-09-30.md`

Confirmed 2 Oct 2026: First pass by Claude computer use, 2 Oct 2026; confirmed by Dave.

### C-75 -- Nursery keeps the meadow view

What this checks: in a running game showing the meadow, press the Nursery button in the top-right bar.

PASS: the Nursery window opens and the meadow stays on screen (the view does not switch to the hive).

If it fails, `scripts/year_winter.gd::_on_nursery_window_requested` still switches views and HF-5 reopens.

Owner: `plans/archive/hud-followups_2026-09-30.md`

Confirmed 2 Oct 2026: First pass by Claude computer use, 2 Oct 2026; confirmed by Dave.

### C-76 -- the top bar has no Saves button

What this checks: start a sandbox run and look along the top bar's second row (the row with the Winter and Skills buttons).

PASS: there is no Saves button there; the Saves window opens only from the cog's settings window, under "Saves…".

If it fails, SA-1's removal of `saves_button` from `hud.gd::_build_top_right_bar` did not land.

Owner: `plans/archive/saves-access_2026-09-30.md`

Confirmed 2 Oct 2026: First pass by Claude computer use, 2 Oct 2026; confirmed by Dave.

### C-77 -- Saves opens over the main menu and loads a run

What this checks: in a sandbox run, save it by name (cog -> "Saves…" -> "Save this run"). Go back to the main menu, open the cog there and press "Saves…". Press Load on the run you just saved.

PASS: the Saves window appears on top of the main menu (with no "Save this run" button), and Load starts that saved run.

If it fails, the window is drawing behind the menu (its layer in `saves_panel.gd::open`) or the cog still loads the latest save directly (`debug_panel.gd::_on_load_pressed`).

Owner: `plans/archive/saves-access_2026-09-30.md`

Confirmed 2 Oct 2026: First pass by Claude computer use, 2 Oct 2026; confirmed by Dave.

### C-78 -- deleting a saved run always asks

What this checks: your profile already has the discard warning switched off (28 Sep). If it has been switched back on, turn it off by saving a run under a name that already exists (cog -> "Saves…" -> "Save this run") and pressing "Discard, and stop warning me". Then, in cog -> "Saves…", press Delete on a saved run you don't need.

PASS: a "Delete this run" confirmation appears, offering only "Delete it" and "Keep it", and the run is gone only after "Delete it".

If it fails, Delete still honours the discard warning switch (`saves_panel.gd::_on_delete_pressed`) and a run can be lost with one click.

Owner: `plans/archive/saves-access_2026-09-30.md`

Confirmed 2 Oct 2026: First pass by Claude computer use, 2 Oct 2026; confirmed by Dave.

### C-82 -- Developer mode shows the Run availability table

What this checks: start level 5, open the cog, and switch on Interface -> Developer mode. Press the "Run availability" button that appears near the top of the settings window. Then switch Developer mode off again.

PASS: the table lists every skill with where it comes from and why in plain words (Nurses "at the start", because level 5 starts with nurses; Honey worker "in the tree"), plus Role and Feature rows; with Developer mode off the button is gone and the table closes.

If it fails, the button's guard (`debug_panel.gd::_make_run_availability_button`) or the table (`run_availability_panel.gd`) is not doing its job.

Owner: `plans/now/brood-spine.md`

Confirmed 2 Oct 2026: First pass by Claude computer use, 2 Oct 2026; confirmed by Dave.

### C-83 -- at Challenge 2's 2.2 a raised pollen Forager hatches

What this checks: start Challenge 2 and play to 2.2, raise a pollen Forager (`docs/challenge-stages.md`). Click an empty comb cell, choose "Forager -- Pollen" from its Raises row's "Forager..." menu, then wait for the egg to grow (fast-forward is fine; about a game-day). Do not move the nectar Forager to pollen. Only valid after BS-9 has merged (`plans/now/brood-spine.md`).

PASS: a pollen Forager hatches from that cell and 2.2 completes.

If it fails, BS-9 reopens: the queen is not feeding the larva (`availability.gd::action_query`), so stages 2.1 to 2.4 still ask the player to raise bees that nobody can feed until 2.5 opens Nurses. Say whether the larva died or nothing was laid. Before BS-9 the readiness probe of 1 Oct 2026 reproduced exactly this failure; Dave's answer to it is decision 7 of `plans/now/brood-spine.md`.

Owner: `plans/now/brood-spine.md`

Confirmed 2 Oct 2026: First pass by Claude computer use, 2 Oct 2026; confirmed by Dave.

### C-85 -- Challenge 2's 2.3 waits for you to designate a cell

What this checks: start Challenge 2 from the main menu and play (or step with Game Settings -> World & start's arrows) to 2.3, "designate a cell" (`docs/challenge-stages.md`). Wait there a moment without touching the comb, then click an empty comb cell and choose a resource on its Reserve for row.

PASS: 2.3 and Dr Gallerin's reminder stay on screen until you reserve a cell, and the stage clears once you do.

If it fails, say which way: clearing before you reserve anything means 2.3's condition in `scripts/challenge_stages.gd` has lost `"explicit": true` (`tests/source_checks.py::check_designation_goals_explicit` guards it); not clearing after you reserve means the Reserve for row is not reaching `scripts/orders_zones.gd::_designate_one`. Either becomes this plan's next slice. Found by `docs/gameplay-review-2026-09-30.md` F1.

Owner: `plans/now/gameplay-consistency.md`

Confirmed 2 Oct 2026: First pass by Claude computer use, 2 Oct 2026; confirmed by Dave.

### C-87 -- Serious warning is not lost behind a minor one

What this checks: In a run, save a selection group with Ctrl+1 and, within about six seconds, let a bee die or drop colony energy so the starvation warning fires (the debug panel's Triggers group has a button that fires a death warning then a save-style notice). Only valid after UI-F-2 has merged.

PASS: The death or starvation message is on the banner (or appears the moment the dwell ends), and "Group 1 saved" never replaces it.

If it fails, UI-F-2 reopens, and the severity values or the pending-slot rule in `scripts/hud.gd::show_warning` are what change.

Owner: `plans/archive/ui-feedback_2026-10-01.md`

Confirmed 2 Oct 2026: First pass by Claude computer use, 2 Oct 2026; confirmed by Dave.

### C-89 -- An Idle bee stays in the hive

What this checks: start Scenario 4 from the main menu, click a nurse
inside the hive and choose Job, Idle. Watch her for three game days.

PASS: she stays in the hive and is still there and alive three game days later.

If it fails, Idle still walks a bee out into the meadow where she cannot
eat and starves; GC-1 (`scripts/bee.gd::_apply_role`,
`scripts/bee_survival.gd::after_feeding`) reopens.

Owner: `plans/now/gameplay-consistency.md`

Confirmed 2 Oct 2026: First pass by Claude computer use, 2 Oct 2026; confirmed by Dave.

### C-90 -- A forager moved indoors unloads first

What this checks: start Scenario 4 from the main menu, click a forager
while she is flying home from a flower (her panel shows a "Carrying" line
with nectar or pollen), and in her panel change her job to Miner.

PASS: once back in the hive she walks to a cell, her "Carrying" line drops to nothing, and she then starts mining.

If it fails, the colony still loses a load whenever a forager is moved to
an indoor job, and GC-2 (`plans/now/gameplay-consistency.md`) reopens.

Owner: `plans/now/gameplay-consistency.md`

Confirmed 2 Oct 2026: First pass by Claude computer use, 2 Oct 2026; confirmed by Dave.

### C-91 -- Winter's countdown opens by itself

What this checks: start Scenario 4 from the main menu with default settings
and play, fast-forwarding is fine, until the day counter reaches day 6. Do
not press any winter button.

PASS: on day 6, with no button pressed, the Winter window opens on the left and a message says winter will arrive on day 21.

If it fails, a player never sees winter coming and no ordinary run meets a
winter at all; WO-1 (`season.gd::_advance_winter`) reopens.

Owner: `plans/archive/winter-onset_2026-10-01.md`

Confirmed 2 Oct 2026: First pass by Claude computer use, 2 Oct 2026; confirmed by Dave.

### C-92 -- Skills tree hides the cut skills

What this checks: from the main menu start Scenario 2 "A working colony" and press Skills at the top of the screen, then click Cell capacity.

PASS: none of the nine cut skills (Guard bee, Combat, Auto-defence, Nectar robbing, Drones, Medicine, Adjustment panel, Extended backup roles, Chemical cascade) has a tile, and Cell capacity shows "Not built yet: buying it changes nothing yet." beside its cost.

If it fails, FBB-1 in `plans/now/feedback-build.md` reopens: a cut node is still drawn in `scripts/skill_tree_panel.gd::_rebuild`, or the note is missing from `_refresh_detail`.

Owner: `plans/now/feedback-build.md`

Confirmed 2 Oct 2026: First pass by Claude computer use, 2 Oct 2026; confirmed by Dave.

## 1 Oct 2026 -- Dave's hands-on pass

### C-57 -- at Challenge 2's 2.2 the Raises menu offers a pollen Forager

What this checks: start Challenge 2 and play (or step with Game Settings -> World & start's arrows) to 2.2, raise a pollen Forager (`docs/challenge-stages.md`). Click a comb cell and open its Raises row's "Forager..." menu.

PASS: the menu lists "Forager -- Pollen" as well as "Forager -- Nectar".

If it fails, say exactly how you reached 2.2 (played through, stage arrows forward or back, a loaded save, the cell already open when the stage changed, or something else). HF-6's fixture (`test_scenarios/hf6_challenge2_raises_test.json`) finds Pollen on every one of those routes it can drive headless, so a failure means your route is one it does not take yet, and that route becomes the next fixture.

Owner: `plans/archive/hud-followups_2026-09-30.md`

### C-66 -- Developer mode toggle in the main menu settings

What this checks: From the main menu, click the cog (top-right) to open the
settings window and open the Interface section. Tick "Developer mode", close
the game completely, start it again and reopen the same settings window.

PASS: "Developer mode" is listed under Interface, starts unticked on a first run, and is still ticked after a full restart.

If it fails, the setting is not being saved between sessions or is missing from the window, and BS-D reopens before BS-5 (the developer table) builds on it.

Owner: `plans/now/brood-spine.md`

### C-67 -- Challenge 2 gives Nurses free at stage 2.5

What this checks: Start Challenge 2 from the main menu and play to stage 2.5 ("buy Nurses in the skill tree, then raise a nurse"). Open the skills window from the Skills button at the top of the screen and hover the Nurses node in the Brood sector.

PASS: The Skills button appears at 2.5, Nurses shows "Cost: Free", buying it takes no nectar or pollen from the comb, and raising one nurse then completes the stage.

If it fails, the "Free" label or the button's stage gate reopens BS-2 (`scripts/skill_tree_panel.gd`, `scripts/challenge_stages.gd`).

Owner: `plans/now/brood-spine.md`

### C-68 -- Clicking the hive or its exit switches view

What this checks: in a normal run with the View button available, left-click the hive in the meadow, then left-click the exit tile inside the hive.

PASS: Clicking the hive shows the hive view, and clicking the exit inside shows the meadow again.

If it fails, HR-2 reopens: the click radius or the bee-first rule in `scripts/input_selection.gd::_click_switches_view` needs adjusting.

Owner: `plans/archive/hive-readouts_2026-09-29.md`

### C-69 -- A bee waiting for room says so

What this checks: in a running game, let the comb fill up so foragers stand still in the hive holding a load, then click one of those bees and read the "Now" line in the selection panel.

PASS: A bee standing still with a load because the comb is full reads "waiting with <resource>: no cell has room for it".

If it fails, HR-3 reopens: the wording in `scripts/bee.gd::task_description` (the `IN_HIVE_TO_CELL` case) is not reached for that bee.

Owner: `plans/archive/hive-readouts_2026-09-29.md`

Confirmed 1 Oct 2026: First pass by Claude via computer use, confirmed by Dave (1 Oct 2026)

### C-70 -- Changing panel texture moves nothing

What this checks: with the Colony window open, go to cog -> Appearance -> Panel texture and switch between Flat, Honeycomb and Grain, watching the window's edges and its lines of text.

PASS: no panel edge and no line of text moves when the texture changes.

If it fails, `scripts/ui_theme.gd::PanelBox` margins or border differ from the old flat panel, and HF-1 reopens.

Owner: `plans/archive/hud-followups_2026-09-30.md`

Confirmed 1 Oct 2026: First pass by Claude via computer use, confirmed by Dave (1 Oct 2026)

### C-73 -- Top bar second row spans the first

What this checks: start a normal run at the default 1280x720 window with button labels off and look at the top-right bar: the row of Colony, Nursery, Foraging and View buttons under the pause and speed row.

PASS: the second row's buttons fill the same width as the row above, equally sized and evenly spaced.

If it fails, the expand-fill flags in `scripts/hud.gd::_build_top_right_bar` are not taking effect and HF-3 reopens.

Owner: `plans/archive/hud-followups_2026-09-30.md`

Confirmed 1 Oct 2026: First pass by Claude via computer use, confirmed by Dave (1 Oct 2026)

## 28 Sep 2026 -- Dave's hands-on pass

### C-7 -- the queen forages unattended once she is given the job

Play Challenge 1 to stage 1.11, "automate nectar gathering", where the player
gives the queen the Forager role with nectar focus. Give her that, then leave
her alone. Do the same at the pollen stage that follows the second cell
(`docs/challenge-stages.md` lists every stage id and what it asks).

PASS: at each stage she works a flower, flies home, deposits, and goes out to
a *different* flower, repeating unaided until that stage's cell is full --
with no right-click from you at any point, and nothing left in her hands at
the hive entrance.

Owner: `plans/archive/c1-followups_2026-09-28.md` (17 Sep fixes); built in `plans/archive/CHALLENGE1_2026-09-15.md` Slice 18.

Re-run note (Dave, 10 Sep 2026). The nectar half passes. The pollen half
fails, and Dave located it more precisely than the first run did: "the queen
doesn't automatically start moving when assigned the forager/pollen role (she
does for the forager/nectar role); she only starts automatically moving once
she's in the meadow. But this should start when initially assigned the role
in the hive." Challenge 1 Slice 21 owns it, and Slice 20 has to land first --
until stage 1.13 runs, no cell in the hive accepts pollen, which is a
sufficient cause on its own.

Re-run note (Claude Code, 11 Sep 2026). Slice 20 and Slice 25 have both since
landed, and Slice 21 is now in too: the queen entered the pollen stage still
holding leftover nectar from the freeze at stage 1.11's exit, which Slice 25's
1.14 discard rule couldn't clear because it only ever ran from a bee actively
mid-deposit, never from one parked by the freeze. A new stage effect now
clears that stale load on 1.13's exit, and `bee.gd::set_focus()` was widened
to also wake a bee genuinely stuck without a deposit target, not just a
frozen one. No headless Challenge run exists yet to prove this in an
automated way (`plans/archive/architecture-review_2026-09-24.md`'s H4 is still open), so
this re-run is the confirmation: PASS as written above at the pollen stage
specifically -- she should set off the moment her focus is switched to
Pollen at stage 1.14, with no right-click needed.

Re-run note (Dave, 12 Sep 2026). The nectar half passes again. The pollen
half was not reached, and is not a fault: the Nectar/Pollen focus buttons only
appear at 1.14, after 1.13 asks you to set the second cell aside for pollen,
and they appeared as soon as Dave did that (13 Sep 2026, in session). Re-run
the pollen half, doing 1.13's designation first.

Re-run note (Dave, 17 Sep 2026). The nectar half passes again (camera, speed
and stopping too). The pollen half fails: switched to pollen she "jolts" but
stays in the hive, reading "Now: returning nectar to the hive (5 carried)".
Cause, from the code: waiting at a full comb she kept a deposit target that
could no longer take nectar, so the focus change read her as mid-delivery and
did not wake her. Fixed on `claude/pass-0917` (the stale target is dropped,
and the nectar aboard is discarded with Dr Gallerin's warning). Re-run the
pollen half; C1F-2 in `plans/archive/c1-followups_2026-09-28.md` adds the headless proof.

Re-run note (Dave, 19 Sep 2026). The pollen half fails again: at the pollen
stage "she thinks she's foraging, but she's not" -- the status line says she
is fetching pollen while she drifts about inside the hive "as if visiting
invisible flowers", sometimes even gaining resources. Cause, confirmed from
the code: an idle Forager inside the hive (for example after building the
second cell at 1.12, or after an "Empty this cell" trip) was dispatched to
flower-seeking where she stood. Inside the hive her position is measured
from the hive, a flower's from the meadow, so she found, flew to and drank
from points that were not flowers. The focus switch then left her alone,
because she already looked like a forager at work. Fixed: flower-seeking now
walks an indoor bee out through the entrance first
(`bee_foraging.gd::_walk_out_if_indoors`), with a static test. Re-run the
pollen half: at 1.14 switch her focus to Pollen and do not click her again.

Confirmed 28 Sep 2026: Passed in Dave's 28 Sep 2026 batch; his follow-up requests from the same run are filed as slices in plans/now/ (hud-followups, saves-access, skill-screen, season-feel SF-2).

### C-25 -- founders reflect their birth seasons

With Season days 5, start a new run and inspect flowers straight away, then
again after a full five-day cycle at the same seasonal point.

PASS: the founding meadow reflects flowers' wrapped birth seasons, so its mix
at the start resembles the mix at the same point one year later rather than a
cohort selected entirely for the restart instant.

Owner: `plans/archive/season-feel_2026-09-30.md` SF-1.

Confirmed 28 Sep 2026: Passed in Dave's 28 Sep 2026 batch; his follow-up requests from the same run are filed as slices in plans/now/ (hud-followups, saves-access, skill-screen, season-feel SF-2).

### C-29 -- the stage's camera and speed switch off when the stage ends

At stage 1.11 and again at the pollen stage, watch the speed readout and the
camera as the queen sets off and again as the stage ends.

PASS: camera-follow and 4x speed start the moment she sets off, not when the
role is assigned, and both return to normal when the stage ends.

Owner: `plans/archive/c1-followups_2026-09-28.md` (17 Sep fixes); built in `plans/archive/CHALLENGE1_2026-09-15.md` Slice 19.

Re-run note (Dave, 10 Sep 2026). The nectar half passes: camera and speed
both start when the queen sets off and both return to normal when the stage
ends. The pollen half fails on the camera alone -- "speed stops and starts
for the pollen foraging, but the camera following doesn't start". That is
Challenge 1 Slice 22, which was written for this exact symptom after the
9 Sep pass and is unchanged by the second sighting.

Re-run note (Dave, 12 Sep 2026). The nectar half passes again. The pollen
half was not reached for the same reason as C-7's: the Pollen focus only
appears once 1.13's cell has been set aside for pollen. Re-run the pollen
half after doing that.

Re-run note (Dave, 17 Sep 2026). Speed passes at both stages; the nectar
camera passes. The pollen camera could not be judged: the queen did not set
off on her own when switched to pollen (C-7), so Dave sent her out by hand,
and a player command turns camera-follow off. That departure is fixed on
`claude/pass-0917`. Re-run the pollen half only: at 1.14 (automate pollen
gathering), switch her focus to Pollen and do not click her again.

Re-run note (Dave, 19 Sep 2026). The nectar stage passes. At the pollen
stage the camera did not follow. Two causes, both confirmed from the code:
she never left the hive (C-7's indoor fault, now fixed), and the 1.14
effects fired as soon as the stage began, because she was already in a
"foraging" state, so selecting her to press Pollen turned the camera off
again (every selection change does). The 1.14 effects now wait for her
Pollen focus. Re-run the pollen half only: at 1.14 select her, press Pollen,
and do not click her again.

Confirmed 28 Sep 2026: Passed in Dave's 28 Sep 2026 batch; his follow-up requests from the same run are filed as slices in plans/now/ (hud-followups, saves-access, skill-screen, season-feel SF-2).

### C-31 -- nectar caught in the pollen cell is called out, and the queen can clear it herself

Play Challenge 1 slowly through 1.12 (build a second comb cell) and 1.13 (set
the new cell aside for pollen) -- `docs/challenge-stages.md` lists every
stage. Once the second cell is built and the first is completely full, let
the queen bring home one more nectar trip, so it lands in the second cell,
before you set that cell to Pollen. When 1.14 (switch her focus to pollen)
begins with nectar still in that cell, watch for Dr Gallerin, then select the
queen, select the cell and press "Empty this cell".

PASS: Dr Gallerin says the pollen cell has nectar in it and to empty it or build another cell; pressing "Empty this cell" sends the queen to carry the nectar out herself, with no role change and no second bee needed.

Owner: `plans/archive/c1-followups_2026-09-28.md` (17 Sep fixes); built in `plans/archive/CHALLENGE1_2026-09-15.md` Slice 27.

Re-run note (Dave, 17 Sep 2026). Failed: the Pollen focus only appears after
the cell is set to Pollen, and setting it to Pollen made its nectar vanish,
so Dr Gallerin had nothing to warn about. "Empty this cell" does work. Cause:
reserving a cell with no room elsewhere for its contents discarded them
(`orders_zones.gd::_designate_one`). Dave chose, in session, that Challenge 1
keeps the nectar; now a level rule (`designation_keeps_stores` in
`scripts/levels.gd`) on `claude/pass-0917`. Re-run as written above.

Re-run note (Dave, 19 Sep 2026). Failed: "Empty this cell" made one trip
out, then she stuck at the inside of the entrance reading "flying to flower
for pollen". Causes, confirmed from the code: the emptying trip always ended
as if she were a builder looking for work, so she dropped the order after one
stomachful, and her own Forager job then sent her flower-seeking while still
indoors (C-7). Fixed: the order now continues until the cell is empty
(`bee_building.gd::builder_dump_waste`), and she then walks out to forage as
usual. Re-run as written above, and watch that she makes as many trips as
the cell needs.

Confirmed 28 Sep 2026: Passed in Dave's 28 Sep 2026 batch; his follow-up requests from the same run are filed as slices in plans/now/ (hud-followups, saves-access, skill-screen, season-feel SF-2).

### C-42 -- the queen keeps her nectar when the comb has no room

What this checks: the queen never loses nectar she gathered just because
there is nowhere to put it. In Challenge 1 at stage 1.12 (build a second comb
cell), before building it, make sure the first cell is completely full. Send
the queen to a flower, bring her home, and watch her at the hive. Then build
the second cell. Later, at 1.14 (switch her focus to pollen), fill every
nectar cell and let her bring nectar home again.

PASS: at 1.12 she waits at the hive still carrying her nectar and the cell's total does not change, and once the second cell exists she puts that same load into it; at 1.14 Dr Gallerin warns there is no room for nectar before that trip is thrown away, and the queen then waits in the hive rather than going straight back out for more nectar.

Owner: `plans/archive/c1-followups_2026-09-28.md` (17 Sep fixes); built in `plans/archive/CHALLENGE1_2026-09-15.md` Slice 27.

Re-run note (Dave, 17 Sep 2026). Partial pass: she keeps her nectar at 1.12
and Dr Gallerin warns at 1.14. Two faults: switched to pollen and leaving the
hive, her 5 nectar vanished without a word; and on nectar at 1.14 she looped
forever, each trip thrown away at the door. Both fixed on `claude/pass-0917`:
the switch now gives the same warning, and after a discard she waits in the
hive until her focus or role changes. The PASS above now says so; re-run it.

Re-run note (Dave, 19 Sep 2026). Partial pass. She keeps her nectar at 1.12
and puts it in the second cell once built; at 1.14 she waits in the hive
after the warning. What read wrong: Dr Gallerin said there was no room for
nectar while an empty cell stood there. That cell is set aside for pollen,
which only takes pollen; Dave confirmed in session that it stays pollen-only.
The warning now says so, and says to switch her focus to Pollen or build
another nectar cell; switching focus while carrying nectar has its own line.
Re-run the 1.14 half and read the warning.

Confirmed 28 Sep 2026: Passed in Dave's 28 Sep 2026 batch; his follow-up requests from the same run are filed as slices in plans/now/ (hud-followups, saves-access, skill-screen, season-feel SF-2).

### C-46 -- comb builders spread across six walls before opening another site

What this checks: idle comb workers building on their own ring one cell's six walls, then start a second site. Give at least seven idle bees the Comb worker job with the Building focus, with open floor in the hive and no cells marked, and watch them start building on their own. Watch the first unfinished cell and the next one that begins while it is still unfinished.

PASS: no more than six workers stand at the first cell, each at a different wall, and the seventh starts a second site rather than joining the first.

Owner: `plans/archive/comb-builders_2026-09-20.md` CB-2 (fix: wall stand points spaced apart, builders now stand on them; headless spacing 14.0px against 13.6 needed). Dave's 12 Sep 2026 run showed builders bunching and more than six on one cell.

Confirmed 28 Sep 2026: Passed in Dave's 28 Sep 2026 batch; his follow-up requests from the same run are filed as slices in plans/now/ (hud-followups, saves-access, skill-screen, season-feel SF-2).

### C-49 -- Challenge stages can be replayed from settings

In Challenge 1, open Game Settings > World & start and step forward and back
across every stage with the stage arrows.

PASS: after each arrow the queen, the tunnel, the comb cells and their stores match the stage shown, and the stage shown stays put until you act.

If it fails: the stage advances again by itself or the world does not match, and the C1F-1 setup for that stage (`scripts/challenge_stages.gd`) is wrong.

Owner: `plans/archive/c1-followups_2026-09-28.md` C1F-1.

Confirmed 28 Sep 2026: Passed in Dave's 28 Sep 2026 batch; his follow-up requests from the same run are filed as slices in plans/now/ (hud-followups, saves-access, skill-screen, season-feel SF-2).

### C-53 -- the Controls list reads as one list, with no gaps

Open the settings cog, expand Interface (or whichever collection holds it)
and open the Controls section.

PASS: the control lines sit close together like one list, with no visible gap between one line and the next, there is no second "Controls" heading, and every line is readable at the window's width.

Owner: `plans/archive/UI-X-1_2026-09-18.md`.

Unblocked 18 Sep 2026. UI-X-1 measured the Controls label's line pitch
(24px against a 20px font at this profile's saved text scale) and pulled it
tight with a `line_spacing` override on that label only, so consecutive
lines now sit at most 2px apart rather than at the font's own ~1.2x leading.

Re-run note (Dave, 19 Sep 2026). Failed: still a gap between each line.
Cause, measured headlessly: the tighter spacing was worked out once, when
the label first appeared, and never updated when the text size changed; at
text scale 1.5 the lines sat 23px apart for 20px text, not the intended 22.
It is now recomputed on every theme change, and
`test_scenarios/c53_controls_list_leading_test.json` asserts at most 2px of
leading at text scale 1.5, 2.0 and 1.0 (it fails on the old code). Re-run
at your usual text size. If a gap still shows, send the screenshot and your
text scale: the instrument then needs a tighter limit, not another guess.

Confirmed 28 Sep 2026: Passed in Dave's 28 Sep 2026 batch; his follow-up requests from the same run are filed as slices in plans/now/ (hud-followups, saves-access, skill-screen, season-feel SF-2).

### C-58 -- the top-left readouts follow the text size

What this checks: star a couple of readouts so they show in the top-left
corner, then open the settings cog, Accessibility, and change Text scale up
and down a few steps.

PASS: the top-left readouts grow and shrink with each Text scale step, within a second, without reopening anything.

If it fails, the corner still has another path that ignores text scale, and
`hud.gd::_refresh_corner` needs a rebuild triggered by the setting itself
rather than by the next readout update.

Owner: `plans/archive/ui_2026-09-20.md`

Dave's note (19 Sep 2026): "when changing the text size, the top left
corner text doesn't change size." Cause: the corner's labels carry
font-size overrides set when they are built, which the theme refresh cannot
reach, and the corner only rebuilt when a readout's text changed. Text
scale is now part of that check, so the next readout update rebuilds them.

Confirmed 28 Sep 2026: Passed in Dave's 28 Sep 2026 batch; his follow-up requests from the same run are filed as slices in plans/now/ (hud-followups, saves-access, skill-screen, season-feel SF-2).

### C-59 -- One placement tool at a time

What this checks: in the game, select a comb worker, click "Build here" in its panel, then click "Keep clear" (or "Work from here"), then click a tile in the hive view.

PASS: only the last button pressed acts -- the tile is marked keep-clear, and no cell is queued to be built there.

If it fails, E1's single active_placement_tool is not replacing the old per-button flags, and the placement buttons in `scripts/hud.gd` need reopening under `plans/archive/architecture-review_2026-09-24.md`.

Owner: `plans/archive/architecture-review_2026-09-24.md`

Confirmed 28 Sep 2026: Passed in Dave's 28 Sep 2026 batch; his follow-up requests from the same run are filed as slices in plans/now/ (hud-followups, saves-access, skill-screen, season-feel SF-2).

### C-61 -- every HUD window still opens, closes and sits where it did

Run the game and open, then close, each window from its button: Colony,
Foraging, Nursery (hive view), the winter forecast (top right) and, if
Dr Gallerin is on, a Gallerin bubble. Do this once at the default text size and
once at the largest (Settings, text size). Open two left-hand windows in turn.

PASS: each window appears in the same place and size as before, at both text
sizes; opening a second left-hand window closes the first; the winter forecast
and the Gallerin bubble open and close without closing the left-hand windows.

Owner: `plans/archive/architecture-review_2026-09-24.md` (F1s). A failure means a window
moved, or the base class `scripts/game_panel.gd` changed which windows close
each other.

Confirmed 28 Sep 2026: Passed in Dave's 28 Sep 2026 batch; his follow-up requests from the same run are filed as slices in plans/now/ (hud-followups, saves-access, skill-screen, season-feel SF-2).

### C-62 -- named saves keep your colony

Start Meadow from the primary checkout after SV-1 has merged. Before doing
anything else, open the cog (the settings/tuning panel) and press **Load run**:
the colony you last saved before this change should load. Then play on, press
**Save run**, keep playing to at least day 10, press **Load run** again, and
look in `%APPDATA%\Godot\app_userdata\Meadow - Claude\saves` in File
Explorer.

PASS: the first Load brings back your old colony, the second brings back the
day you saved on, and the `saves` folder holds `my-colony.json` plus at least
`my-colony.checkpoint1.json` and `my-colony.checkpoint2.json`.

If it fails, SV-1's adoption of the old `meadow_save.json` or its load path is
wrong, and SV-2's Saves window would be listing the wrong files -- SV-1 reopens
before SV-2 starts. Your original `meadow_save.json` is copied, never moved,
so nothing is lost either way.

Owner: `plans/archive/named-saves_2026-09-24.md`

Confirmed 28 Sep 2026: Passed in Dave's 28 Sep 2026 batch; his follow-up requests from the same run are filed as slices in plans/now/ (hud-followups, saves-access, skill-screen, season-feel SF-2).

### C-63 -- a loaded checkpoint puts the colony back where it was

Start a new sandbox run (not a Challenge). Click **Saves** at the right of the
top bar, press **Save this run**, type a name such as `Test colony` and press
Enter. Play on past day 10 so two checkpoints appear under it (one every five
days), note roughly what the colony looks like at the first one, then quit
the game. Reopen it, click **Saves**, and press **Load** on the *older* of the
two checkpoints. Then open the settings cog and press **Load run**. Finally
press **Delete** on the run in the Saves window and confirm.

PASS: the checkpoint loads on the day it lists with the colony as it was
then, the cog's Load run opens the Saves window rather than loading anything,
every other window still opens, closes and sits where it did, and after
Delete the run is gone from the list.

If it fails, `scripts/saves_panel.gd` (the list, Load or Delete) or SV-1's
checkpoint writing reopens -- this is the closed alpha's main reliability
claim (`plans/design/product-scope.md` section 6.1), and no automated check can
cover a quit and restart.

Owner: `plans/archive/named-saves_2026-09-24.md`

Confirmed 28 Sep 2026: Passed in Dave's 28 Sep 2026 batch; his follow-up requests from the same run are filed as slices in plans/now/ (hud-followups, saves-access, skill-screen, season-feel SF-2).

### C-64 -- the skill tree reads in every theme and at the largest text

In a sandbox run (not a Challenge), click **Skills** at the right of the top
bar, just left of the Hive/Meadow view button. Look over the hex grid and the
list under it, and hover a few tiles. Look at the **Skills** and **Saves**
buttons' icons too (an up arrow and a disk). Then open the settings cog, switch the
theme through all three choices (Appearance) and set the text size to its
largest (Accessibility), reopening Skills each time.

PASS: in every theme and at the largest text, the six coloured sector tiles,
the skill tiles and the faint connecting lines are all distinguishable, both
button icons are visible, every
list line is readable without clipping, and each tile's tooltip names the
skill, its cost and why it is blocked.

If it fails, `scripts/skill_tree_panel.gd`'s colours (`_fill`, `_state_colour`)
or tile size change before AP-4 puts a Buy button on the same panel.

Owner: `plans/archive/alpha-progression-spine_2026-09-25.md`

Confirmed 28 Sep 2026: Passed in Dave's 28 Sep 2026 batch; his follow-up requests from the same run are filed as slices in plans/now/ (hud-followups, saves-access, skill-screen, season-feel SF-2).

### C-65 -- buying Tarsal secretions spends stores and survives a reload

In a sandbox run with Tarsal markers left off in the settings cog, play until
the comb holds at least 120 nectar and 40 pollen. Open **Skills** from the top
bar, note the stores on the centre tile's tooltip, and press **Buy** beside
Tarsal secretions. Then click a flower a bee has just visited. Finally open
**Saves**, save the run, load it again, and reopen **Skills**.

PASS: the purchase takes 120 nectar and 40 pollen out of the comb, the
flower's scent-mark line now reads "(bees avoiding)", and after the reload
Tarsal secretions still shows as owned.

If it fails, AP-4's purchase path (`skill_tree_panel.gd::buy_skill`) or the
save's new `skills` block (`save_game.gd`, `saving.gd::_restore`) reopens
before any further skill is made buyable.

Owner: `plans/archive/alpha-progression-spine_2026-09-25.md`

Confirmed 28 Sep 2026: Passed in Dave's 28 Sep 2026 batch; his follow-up requests from the same run are filed as slices in plans/now/ (hud-followups, saves-access, skill-screen, season-feel SF-2).

## 19 Sep 2026 -- Dave's hands-on pass

Thirteen checks run. Seven passed and are recorded here: C-18, C-24, C-34,
C-52, C-54, C-55 and C-56. C-7, C-29, C-31, C-42 and C-53 failed or
partly passed; each was diagnosed and fixed in session and carries a
re-run note. Dave's extra findings became C-57 (Challenge 2's Raises
menu, with 2.1 now unlocking the nectar Forager, Dave's decision) and
C-58 (the top-left readouts and text size). C-42's pollen-only cell
stays pollen-only (Dave, in session).

### C-18 -- the command tray's three columns share its width

Select a bee at 1920x1080, then at 800x600, and look at the Job, Focus and
Orders columns across the tray; then select a comb cell and look again.

PASS: at 1920x1080 the tray's columns divide its width into equal parts with equal gaps and equal space at each end -- Job, Focus and Orders for a bee; Reserve for, Priority and Raises for a cell -- and at 800x600 they either do the same or wrap onto more rows with nothing clipped.

Owner: `plans/archive/UI-X-3_2026-09-18.md`.

Unblocked 18 Sep 2026. UI-X-3 split the cell tray's Nursery column into
Priority and Raises, so a comb cell's tray now shows three columns --
Reserve for, Priority, Raises -- matching the bee tray's three-column shape.
The bee half already passed on Dave's 12 Sep 2026 run; re-run the cell half.

Passed (Dave, 19 Sep 2026).

### C-24 -- peak season reads as a good summer, not a different game

What this checks: how much more a flower gives in the middle of its own
flowering season than outside it. In Game Settings > Seasons & health, set
"Season days" to 5 (the shortest year), restart the run and play at 8x. Click
one flower and keep its summary panel (bottom left) open. Watch the
"Nectar: ... (+x/s)" figure for a minute or two as its season comes and goes.

PASS: the +/s figure climbs smoothly to a peak and falls smoothly away again, and out of season it never drops below about three fifths of its peak (0.75x against 1.25x of the flower's normal rate).

If it fails, `GameConfig.out_of_season_strength` (0.75) and
`peak_season_strength` (1.25) are wrong or not what the summary panel reads.

Owner: `plans/archive/season-feel_2026-09-30.md` (values set on `claude/pass-0917`).

Re-run note (Dave, 17 Sep 2026). Failed against the old 0.05/0.75 values:
"flowers' nectar rates quickly falling to one tenth of their peak season
rate". Dave set the new range in session: off season 75% of the normal rate,
peak 125%. Re-run as written above.

Passed (Dave, 19 Sep 2026).

### C-34 -- Challenge 2 keeps enough pollen to raise its first pollen Forager

Start Challenge 2 and stay in stage 2.1 (watch the nectar stores fall, then
recover them) long enough for Dr Gallerin's stronger hint. Let pollen run
below one bee's cost, then move into 2.2 (raise a pollen Forager) without
raising one at once. Let it run briefly, then select an empty cell, set
Raises to Forager -- Pollen, and play until 2.2 clears.

PASS: during 2.1 Dr Gallerin warns that every new bee costs pollen and some should be kept back; at low pollen, exactly once per run, the colony receives three bee-costs of pollen with a line explaining that no pollen means no new bees, and the same low-pollen state does not top the store up again; once the pollen Forager is raised no further rescue occurs.

Owner: `plans/archive/UI-X-2_2026-09-18.md`.

Unblocked 18 Sep 2026. UI-X-2 fixed the missing Forager control: a stage
transition while a cell's tray was open closed the whole tray (not a role-
unlock gap), so selecting the cell freshly after 2.2 begins -- as this check
already asks -- reaches a working "Raises: Forager..." menu. 2.1's own text
above was re-checked and does not ask to raise anything as a Forager during
2.1 (the role has no unlock there by design); nothing in this check's
wording needed changing.

Passed (Dave, 19 Sep 2026).

### C-52 -- the settings window is about a quarter of the screen's width

Open the settings cog in a run, at the default text scale on a maximised
1920x1080 window.

PASS: the window is about a quarter of the screen wide, the action buttons and the Triggers buttons each read in full, and no row forces a horizontal scrollbar.

Owner: `plans/archive/UI-X-1_2026-09-18.md`.

Unblocked 18 Sep 2026. UI-X-1 replaced the settings window's fixed 320px
width with `UiLayout.settings_window_width()` -- a quarter of the viewport,
floored at 320px -- so a 1920x1080 window now opens the panel 480px wide.

Passed (Dave, 19 Sep 2026).

### C-54 -- a run's starting bees do not all die of old age together

Start a new run from Restart Run with the default settings. Select each
starting bee in turn and read "Age" and "Left" in the summary panel (bottom
left).

PASS: the starting bees show different ages, from newly hatched up to about half a lifespan, rather than all reading the same.

If it fails, the founders still share one death day, and `starter_age_spread`
in `scripts/game_config.gd` (Game Settings > Bee life > Starting age spread)
is not reaching the spawn in `scripts/world_building.gd`.

Owner: `plans/archive/c1-followups_2026-09-28.md` (17 Sep fixes, `claude/pass-0917`).

Passed (Dave, 19 Sep 2026).

### C-55 -- Challenge 1's queen takes Nursing as her backup by herself

Play Challenge 1 to 1.16, where Dr Gallerin asks you to let the queen lay the
colony's first egg (`docs/challenge-stages.md`). Select the queen and give her
the Laying role only; do not open her backup choice. Read Dr Gallerin's lines
at 1.16 and 1.17, then look at the queen's backup in her command tray.

PASS: her backup already reads Nursing, and neither of Dr Gallerin's lines asks you to choose a backup.

If it fails, the first hatch can starve with nobody feeding it, and
`queen_laying_backup` in `scripts/levels.gd` is not being applied.

Owner: `plans/archive/c1-followups_2026-09-28.md` (17 Sep fixes, `claude/pass-0917`).

Passed (Dave, 19 Sep 2026).

### C-56 -- Dr Gallerin's long lines show in full, up to a third of the screen

Trigger a long Dr Gallerin prompt (the developer/debug trigger, or any real
prompt of a few hundred characters or more) at the default window size.

PASS: the bubble grows past its old few-line size, up to about a third of the window's height, and a line too long for that shows the rest via the bubble's scrollbar rather than being cut off silently.

Owner: `plans/archive/UI-X-4_2026-09-18.md`.

Filed 18 Sep 2026. `UiLayout.GALLERIN_MAX_HEIGHT_FRACTION` caps the bubble at
a third of the viewport height (was effectively uncapped), and
`_bubble_label.visible_characters_behavior = VC_CHARS_AFTER_SHAPING` fixed
the bug that had it sizing to an empty first line instead.

Passed (Dave, 19 Sep 2026).

## 17 Sep 2026 -- Dave's hands-on pass

Eight checks run. C-48 passed and is recorded here. C-24 failed and was
refiled against Dave's new season range; C-7, C-29, C-31 and C-42 were fixed
in session on `claude/pass-0917` and refiled for re-run; C-25 and C-49 moved
to `checks/blocked.md` behind SF-1 (`plans/archive/season-feel_2026-09-30.md`) and C1F-1
(`plans/archive/c1-followups_2026-09-28.md`). Dave's extra asks: staggered starter ages
(shipped, C-54), automatic Nursing backup in Challenge 1 (shipped, C-55), the
settings stage row (shipped with a headless check), and Dr Gallerin's bubble
height with room for the settings window (UI-W-4, `plans/now/ui-w.md`).

### C-48 -- Challenge 1's marker remains noticeable and findable

What this checks: the yellow circle Challenge 1 draws to show where to go or
build next. It appears at 1.2 (the cavity to send the queen into), 1.5 (the
centre to build the first cell on), 1.6 (the doorway to send her outside),
1.10, 1.12, 1.15 and 1.19 -- `docs/challenge-stages.md` says what each stage
asks. Use Game Settings > World & start's stage arrows to jump to 1.5. Watch
the circle at normal speed and at 4x, then pan the view with the arrow keys
until the circle is off screen, then back.

PASS: the circle gently grows and shrinks at both speeds; while it is off screen a yellow arrow sits at the screen edge pointing towards it, clear of the bottom panels, Dr Gallerin's bubble and the corner readout; the arrow disappears as soon as the circle is back on screen, and no arrow shows after Tab switches to the meadow view.

Owner: `plans/archive/CHALLENGE1_2026-09-15.md` Slice 26.

Reworded 13 Sep 2026: Dave's 12 Sep pass could not tell which marker the old
wording meant.

Passed (Dave, 17 Sep 2026).

### C-49 -- Challenge stages can be replayed from settings

Start either Challenge, open Game Settings > World & start, and use the
stage arrows to move forward, then back, across a stage that follows the
queen or speeds the game up. Repeat until the first and last stages.

PASS: each arrow rebuilds the shown stage's gates, prompts and marker; the
back arrow is disabled at the first stage and the forward arrow at the last;
after every move the camera follows no bee and the speed is normal.

Owner: `plans/now/ui.md` UI-U-1.

Re-run note (Dave, 12 Sep 2026). The stage row itself draws badly: its
arrow buttons are far too tall and the stage name runs one letter per line
(screenshot). The cause is confirmed and owned by `plans/now/ui-w.md` UI-W-1.
The arrows still work, so the PASS above can still be judged now; the row's
layout gets its own re-run note when UI-W-1 lands.

Superseded (17 Sep 2026) by the blocked C-49 in `checks/blocked.md`, whose
PASS now includes the world matching the stage shown.

## 10 Sep 2026 -- Dave's fourth hands-on pass

Eleven checks run. Four confirmed and recorded here; two of the four carried a
follow-up ask that was filed as a slice rather than left in the check. C-18,
C-29, C-32 and C-7 each passed the part their own slice had fixed and failed
on a cause underneath it, so all four stay in `checks/ready.md`. C-30 and
C-31 failed outright on the cause Challenge 1 Slice 20 is already open
against. C-34 could not be run at all and moved to `checks/blocked.md`.

### C-36 -- a summary panel's cog fits the entity it names

PASS confirmed, with no qualification. The single bee's cog offers all four
fields and each one hides and shows its line; the cell and the soil block
show no cog; two or more bees show "Identity & job" alone.
Owner was `plans/archive/HC-11_2026-09-10.md`.

### C-35 -- the Favourite star sits beside the summary panel's cog

PASS confirmed, with one adjustment: "make the star button the same height as
its neighbouring settings button". Neither button sets a minimum height, so
each takes the height its own glyph asks for and the star lands shorter than
the cog. That is one shared constant and is queued as HC-13 in
`plans/now/hud-controls.md`.
Owner was `plans/archive/HC-10_2026-09-09.md`.

### C-33 -- the default text size is 2px larger everywhere, and nothing clips

PASS confirmed for every panel the check named. One place outside them spills:
"there's some text spilling over in the main menu hexagons". A hex tile's
label is given a fixed pixel box derived from `HEX_SIZE` while its text
follows the text-size setting, so the longer titles now overrun the hexagon.
Queued as UI-M-2 in `plans/now/ui.md`, together with Dave's request to drop
the punctuation after the Challenge and Scenario numbers.
Owner was `plans/archive/HC-4_2026-09-09.md`.

### C-5 -- Challenge 2's rescue and recovery lines

PASS confirmed at the third attempt. One press of "Force Challenge 2 collapse"
drops the stores below the rescue threshold and Dr Gallerin's "Ahem. Field
ecologists..." line appears with 150 nectar restored and stays up; the second
press reaches the failure floor and restores the checkpoint with a live queen.
Neither needs a third press. Challenge 2 Slice 2 holds.
Owner was `plans/now/challenge-2.md` Slice 2.

## 9 Sep 2026 (second pass) -- the LAY group's own checks

Two confirmed. C-18 passed on everything the panel-layout plan owned and was
narrowed to its remaining column-layout fault; C-7 failed in five ways and
C-5 failed on its press count, all three staying in `checks/ready.md`.

### C-19 -- left-side windows leave a true 16px gap, and grow with their content

PASS confirmed. The gap below an open Colony, Foraging or Nursery window
matches the gap between the summary panel and the left screen edge. Expanding
a section grows the window until its bottom would reach that gap, after which
it scrolls; collapsing it shrinks the window again. LAY-3 holds.
Owner was `plans/archive/LAY-3_2026-09-09.md`.

### C-26 -- the nursery donut's key follows the typeface and clears the scrollbar

PASS confirmed. The key's text changes typeface and size with the appearance
settings, matching the headings around it, and no line of it runs under the
window's scrollbar at any scale. LAY-4 holds, and with it every slice in
`plans/archive/PANEL_LAYOUT_2026-09-09.md`.
Owner was `plans/archive/LAY-4_2026-09-09.md`.

## 9 Sep 2026 -- hands-on pass over the UI-W and LAY-1 group

Three entries confirmed. Three failed and are re-filed against
`plans/now/panel-layout.md` (C-18, C-19, C-26); two -- C-7 and C-5 -- could
not be run at all, because both need the command tray's buttons, and moved to
`checks/blocked.md` naming LAY-2.

### C-4 -- warning banner messages get a guaranteed minimum dwell

PASS confirmed. The epitaph holds for several seconds, the crab-spider escape
message is not cut short, and "Run saved." waits its turn. UI-Q-3's guaranteed
minimum dwell holds.
Owner was `plans/archive/UI-Q-3_2026-09-08.md`.

### C-27 -- sections start collapsed everywhere

PASS confirmed, at both ends: the in-run Colony, Foraging and settings
sections and the pre-run Settings button all open collapsed, on a first run
and after a return to the menu. UI-W-3 and UI-W-4 together close
`plans/archive/UI-WINDOWS_2026-09-08.md`.
Owner was `plans/archive/UI-WINDOWS_2026-09-08.md` UI-W-3 and UI-W-4.

### C-28 -- the panel refactor changed no panel's position or size

PASS confirmed for what LAY-1 itself owned. Dave: "every persistent panel is
wholly on screen except the command tray", and "the gaps look correct other
than the left-side panel and summary window gap looks too big". Both
exceptions were already open defects with their own entries -- the tray is
C-18 and the left-side gap is C-19 -- and both are now specified in
`plans/now/panel-layout.md` as LAY-2 and LAY-3. LAY-1's own claim, that one
owner sizes every persistent rectangle and nothing else moved, holds. The
deliberate change LAY-1 announced -- a left-side window hugging its content
rather than filling the band -- was not reported as a problem.
Owner was `plans/archive/LAY-1_2026-09-08.md`.

## 3 Sep 2026 -- hands-on pass over the 31 Aug / 1-3 Sep fixes

Eleven entries confirmed, one dropped, one superseded. The five that failed
are slices in their owning plans, not entries here: `plans/archive/CHALLENGE1_2026-09-15.md`
Slices 14-15, `plans/now/hive-comb.md` Slice 9, `plans/now/ui.md` UI-S-1 to
UI-S-4, and `plans/now/challenge-2.md`. Two new asks became
`plans/now/flowers.md`, and the process findings from the pass became
`plans/now/check-loop.md`.

- **Save migrations and domain-event boundaries (efficiency Slice 5).**
  Confirmed: "save works as intended without loss of bees", and the repeated
  "Exponent too high" warnings are gone from that load. The `saving.gd:275`
  typed-array fix and the paired `save_game.gd` one both hold. The only
  console warning left on that boot was an unused-parameter warning in
  `scenario_actions.gd::_do_set_config`, fixed in the same 3 Sep pass.
  Provenance: `plans/archive/HANDS_ON_FIXES_2026-08-31.md` Slice A0/A1.
- **Challenge 1 Bundle D -- Slice 12's acceptance (the refactor regression
  check).** Confirmed: through 1.6-1.10 the queen never gets auto-assigned a
  role she was not manually given, across exiting the hive, touring the
  meadow points, gathering from two flowers, being sent home and depositing
  by hand. One issue came out of it -- once she *is* given the Forager role
  at 1.11 she still pauses at flowers instead of foraging -- which is
  `plans/archive/CHALLENGE1_2026-09-15.md` Slice 14.
- **Challenge 1 Bundle D -- Slice 11's acceptance.** Confirmed on all three
  clauses: worked dry at 1.8 she stays at the flower; after the 1.10 manual
  deposit she stays inside the hive; the Job column reads "Laying"
  throughout 1.6-1.10. The two transitions Slice 12 newly guarded are
  confirmed too -- rain during 1.6-1.10 does not send her home or to
  shelter, and a flower vanishing under her does not send her looking for
  another.
- **Challenge 1 Bundle D -- the 1.10 to 1.11 hand-over.** Confirmed: on
  reaching 1.11 the Job column offers "Change to..." with Forager in it.
  This was the blocker that stopped the 2 Sep run.
- **Challenge 1 Bundle D -- the 10f collection counter.** Confirmed at 1.8:
  right-clicking a near-empty flower twice does not clear the stage, and one
  real collection does.
- **Challenge 1 Bundle E -- automate nectar, then pollen (1.11-1.14).**
  Confirmed, including the 10c freeze at the 75-unit pollen target and 10d's
  Doing row keying off the role she is actually working.
- **Challenge 1 Slice 9 fixes (9a-9j).** Confirmed except 9i's camera-follow
  and 4x speed, which never fire: the effects are set at stage entry and
  cancelled inside the same `_enter_stage()` call. That half is
  `plans/archive/CHALLENGE1_2026-09-15.md` Slice 14; every other item in 9a-9j passed.
- **Challenge 1 selection-panel vocabulary (Slice 13), outside a Challenge.**
  Confirmed: nothing changes in a Scenario. The in-Challenge half did not
  pass -- the line is taught vocabulary but still not useful -- which is
  `plans/archive/CHALLENGE1_2026-09-15.md` Slice 15.
- **Nectar/pollen recharge reads as stuck -- the C1 half.** Confirmed: a
  dandelion showed `+0.00/s` on day 23, so the panel's rate really does
  reflect season and senescence rather than the nominal figure. The C2 half
  (a flower near its floor no longer pinned) stays open as C-1 in
  `checks/ready.md`. Provenance:
  `plans/archive/HANDS_ON_FIXES_2026-08-31.md` Slice C1.
- **Hive comb visual alignment -- the live Cell art toggle.** Confirmed:
  turning Cell art off returns every ring to the flat hex within a fraction
  of a second, so Slice 8's single routing helper is called in the right
  places. The silhouette it draws is wrong, which is
  `plans/now/hive-comb.md` Slice 9.
- **Proximity recruitment (Slice 9 / FE-4).** Confirmed on all three
  clauses: the dance highlight makes a pair findable and distinguishable,
  the toggle survives a restart, and recruitment still happens with the
  toggle off. Provenance:
  `plans/archive/FORAGING_EVIDENCE_2026-09-03.md` Slice 4.
- **Safe forager return reserve -- dropped, not confirmed.** Dave's call:
  "no increase [in] Forager returns triggered, as it's so unlikely to happen
  -- let's drop this and assume it works." The emergency recall, its counter
  and its panel row stay as built; the sparse/long-range rerun will not be
  run, and the queued FE-5 slice that existed to make that rerun readable
  headlessly was dropped with it.
- **Command tray placement (UI-R-1) -- superseded.** The check asked whether
  the summary panel is too cramped at 800 wide. Dave's answer re-specified
  the whole bottom row instead: the tray takes half the viewport, centred,
  and the summary panel and Dr Gallerin's bubble fill what is left with a
  16px gap each. That is `plans/now/ui.md` UI-S-1, whose check replaces this
  one.
- **AI playtest harness (slices 1-7) -- withdrawn, not a player check.**
  "Review all seven slices end to end -- see `git log`" is developer work,
  not something Dave can do at the keyboard; his reply was that he did not
  know what it referred to. Removed under the check-admission rule in
  `plans/now/check-loop.md`.

## 2 Sep 2026 -- hands-on pass over the 31 Aug/1 Sep fixes

Fifteen entries confirmed. The findings that came out of the same pass are
slices in their owning plans, not entries here.

- **Foraging window, Slice 1 (Option B) -- orientation flight vs auto
  scouting.** Switching either of Auto scouting / Orientation flight on
  turns the other off, both directions, and the orientation-flight counter
  now moves while Orientation flight is the live option. Provenance:
  `plans/archive/FORAGING_EVIDENCE_SLICE_1.md`.
- **Hive comb Slice 6 -- above-centre-row rendering.** Cells built above
  the comb's centre line paint correctly, cell art on and off. The
  `HIVE_FLOOR_Z_INDEX` pin holds.
- **Hive comb Slice 7 -- navigation cost.** A bee crossing a wide comb
  prefers the open-floor detour, and the route is identical before and
  after a save/reload.
- **Hive comb Slices 1-3 -- cell art after save/load,** and the settings
  placement (Cell art, Show cell contents text, Sprite-aligned hex grid,
  Direction-even hex speed under Appearance). *Partial:* the ring-shape
  clause failed -- see `plans/now/hive-comb.md` Slice 8.
- **UI-P-6 -- settings window row/scrollbar gap.** Rows sit a small,
  consistent gap from the scrollbar with info icons on and off.
- **UI-P-1 -- long info-badge tooltip.** Wraps into a multi-line box
  instead of spilling off-screen.
- **UI-P-3 -- pre-run menu tile borders and hit testing.** Neighbouring
  tiles read as one shared line, and a click near a touching corner still
  selects the tile under the pointer.
- **UI-P-7 -- Dr Gallerin's bubble.** Typeface, size, width, placement
  left of his icon and the pointer between the two are all as intended.
  *Partial:* the "command tray never renders underneath it" clause failed
  -- see `plans/now/ui.md` UI-R-1.
- **UI-P-8 -- summary panel cog.** With an identity label wrapping to two
  or three lines the cog stays aligned with the first line. *Partial:* the
  command-tray width/wrap clauses failed -- same UI-R-1.
- **UI-P-4 -- pre-run left margin.** Shipped and working, but too small;
  raising it is `plans/now/ui.md` UI-R-2, not a re-check.
- **Challenge 2 Slice B -- opening unlocks.** The Meadow button is visible
  from Challenge 2's opening stage and the Foraging window button stays
  visible across every stage transition through 2.9.
- **Challenge 2 Slice D -- death markers.** A death marker shows the same
  green selection ring as any other selectable object, in both zones, by
  single click and by drag-box.
- **Save/load unavailable during Challenge 2.** Working as built, not a
  bug: `challenge_runner.gd::start()` calls
  `main.debug_panel.set_save_load_enabled(false)` for the length of a
  Challenge because `SaveGame` has no Challenge stage/gate/prompt schema.
  Recorded as a confirmed decision in `DESIGN_BACKLOG.md`.
- **Proximity recruitment fires.** Superseded by X2's headless run (25
  dance matches over 40 days) plus Dave's live confirmation. The remaining
  question -- that a match cannot be *seen* -- is
  `plans/active/foraging-evidence.md` Slice 4.
- **Scenario pick resets debug-panel toggles (C3).** Confirmed doing
  exactly what it was built to do. Dave has since reversed the intended
  behaviour -- see `plans/now/settings-persistence.md`.

## 31 Aug 2026 -- second hands-on pass

- **Same-flower ping-pong / thin-patch escape (foraging).** Confirmed
  working -- a forager worked into an isolated flower correctly switches to
  "flying a search loop" once nothing worthwhile is left to try, rather than
  sitting on the same flower indefinitely. See
  `plans/active/foraging-evidence.md`.
- The Foraging window's own numbers were reconfirmed the same pass (its
  Orientation flight sub-finding was not, and stays open in
  `checks/ready.md` alongside the confirmed line, not archived here, since
  the heading as a whole isn't done).
- Five further items from the same pass were found broken, not confirmed --
  see `plans/archive/CHALLENGE1_2026-09-15.md` Slice 10 (Challenge 1 Bundle D/E),
  `plans/now/hive-comb.md` Slice 6 (cell rendering), and
  `plans/active/foraging-evidence.md` Slices 1-3 (orientation flight,
  proximity recruitment, safe forager return reserve), and the updated
  entries left open in `checks/ready.md`.

## 31 Aug 2026 -- hands-on pass

- **Cell/colony dirty-index refactor (efficiency Slice 1).** Confirmed
  working -- `hive.gd`'s cell-content buckets and the comb/nursery panel's
  free/brood/gyne/hungry counts update the moment they should.
- **HUD popups bound to revisions, not frames (efficiency Slice 2).**
  Confirmed working -- cell popup, flower summary and selection panel
  refresh immediately on a real change, including the activity line
  updating instantly on a tray order.
- **Crab spiders, full re-check.** Confirmed working -- the tunable attack-
  success setting, the escaped-bee flower cooldown, the attack-flash ring
  and the magenta dev marker all behave as `plans/archive/CRAB_SPIDER_PLAN.md`
  Bundle 5 intended.
- **Challenge 1 Bundle F (laying, backup nursing, the first daughter).**
  Confirmed working in full -- automatic nursing backup, the new worker's
  hatch behaviour (circling the queen, no dart for the exit), the queen not
  re-laying mid-beat, her role panel, the farewell speech bubble placement,
  and all three completion-window options.
- Two items from the same pass were found broken, not confirmed --
  see `plans/archive/HANDS_ON_FIXES_2026-08-31.md` (Slices A/B/C/D) and the
  updated entries left open in `checks/ready.md` for efficiency Slices 4/5
  and Challenge 1 Bundle G.

## 24 Aug 2026 -- second hands-on pass

- **Text now scales.** Confirmed working (`UI_BUGFIX_PLAN.md` Slices 1-2,
  the `theme_type_variation`/live-theme-apply migration).
- **Dark/light theme toggles.** Confirmed working (`UI_SETTINGS_PLAN.md`
  Slice 1, live theme apply).
- **Colour-blind labels appear for cells.** Confirmed working. The wider
  audit of every colour-only indicator beyond cells (`UI_BUGFIX_PLAN.md`
  Slice 3's "generalise beyond the nursery ring") is separate and still
  open -- not re-added here since it was never confirmed broken, just
  unconfirmed.
- **Settings-window sections are good.** Confirmed working
  (`UI_SETTINGS_PLAN.md` Slice 3, the Game Settings/Hive/Meadow
  reorganisation -- `git log` commit `a1ed2d0`).
- **Cell popup position is good.** Confirmed working, positioning only --
  the separate overlap-with-the-summary-panel issue is tracked as new work
  in `UI_BUGFIX_PLAN.md` Slice 6, not archived here.
- **Follow-bee works as expected.** `UI_BUGFIX_PLAN.md` Slice 8 (the
  hive/meadow view-change follow-bee-stops bug) is confirmed already
  working as of this check -- closed with no code change needed. Whatever
  fixed it happened as a side effect of other work; not worth chasing
  further.
- **Empty-crop critical recall.** Confirmed working -- a bee with an empty
  crop and low energy returned straight to the hive instead of continuing
  to search, matching `NEXTSTEPS.md`'s 24 Aug starvation-fix writeup
  (`bee_survival.gd::check_critical_recall`).
- **Forager-history save gap -- decision resolved.** Dave's answer: yes,
  worth its own slice. Turned into a scoped technical-work item in
  `DESIGN_BACKLOG.md` section 5 rather than left as an open question here.
- **Adaptive constancy ("unpinned forager gravitates toward whichever
  species is paying off").** Dave couldn't reproduce this by eye. Rather
  than a further hands-on attempt, this is already answered by the
  headless evidence `FORAGING_ECOLOGY_PLAN.md` Slice 7 recorded on 23 Aug:
  with `floral_constancy_on` off and `probabilistic_choice_on` +
  `adaptive_constancy_on` both on, flower_visits rose +18% (seed 12345,
  232 -> 274) versus the same run with confidence off, confirmed as the
  intended per-species-confidence effect rather than a regression. Closed
  on that evidence; no further hands-on check needed for this one.

## Earlier (22 Aug 2026)

- **Challenge-completion screen's actual play test.** Confirmed -- Challenge
  1 completes as intended.
- **Game model Slice 3's prerequisite cascade.** Confirmed -- both chains
  (Orientation flight/Scouting/Floral constancy/Auto-recruitment and
  Predators/Crab-spider suppression/Alarm pheromone) walk correctly both
  ways.
- **Bumble flight.** Confirmed -- the two-sine wander reads as bee-like.
- **Crab-spider second-round fixes.** Confirmed -- predator behaviour works
  as intended.
- **Foraging window (`FORAGING_ECOLOGY_PLAN.md` Slice 1).** Confirmed on a
  day-5 run with recruitment/scouting on -- panel numbers internally
  consistent against `DiagnosticLog`. (Superseded by a fresh "no data"
  report on 24 Aug -- see the live checklist, not re-opened here since
  the 22 Aug check itself was genuine at the time.)
- **Foraging ecology Slices 5 and 6 (local search, probabilistic
  choice).** Confirmed on a live playthrough -- heading-weighted choice and
  the SEARCHING spiral both read as intended. `forage_perception_radius`
  taken down 400 -> 320 off a `perf.gd` steer.

## Confirmed in Dave's pass of 8 Sep 2026

Eleven entries came back confirmed. Where a pass carried a correction or a
balance note alongside it, the slice that owns the follow-up is named -- the
check itself still passed and is closed here.

### C-1 -- a flower under forager pressure no longer reads as pinned

PASS confirmed. Dave: "Depleted flower recharges when abandoned."
`nearest_flower()`'s `GameConfig.min_worthwhile_amount` skip is the fix, and
it works: a flower drawn down near its floor is left alone and visibly
recharges instead of sitting pinned just above zero.
Owner was `plans/archive/HANDS_ON_FIXES_2026-08-31.md` Slice C2.

### C-3 -- Challenge-only top-bar hit areas

PASS confirmed. Dave: "second-row top-bar buttons work across its full
height." The goal shelf's `Control.MOUSE_FILTER_IGNORE` fix (1 Sep 2026) was
both the cause and the cure. The `stage_gate.gd` theory is retired, and the
geometry fallback that was held in reserve is not needed (archived at `plans/archive/UI_D_CLOSED_2026-09-08.md`). UI-D is
closed.

### C-4 -- two throttled warnings eight seconds apart

PASS confirmed. All three messages appeared -- a bee-death epitaph, a
crab-spider escape, then "Run saved." -- and none wiped another out, which is
the condition. Dave timed the dwells: ~6s, ~1-2s, ~12s. The second message
being cut to a fraction of the others is the priority/dwell rule UI-Q-1
deliberately deferred, and is now `plans/now/ui-bottom-row.md` UI-Q-3, which will file
its own replacement check.
Owner was `plans/now/ui.md` UI-Q-1/UI-Q-2.

### C-8 -- the queen's "Now:" line says what to do, not what she cannot do

PASS confirmed. Every waiting stage from 1.1 to 1.14 reads "Now: waiting for
instruction", with the stage's action appended from 1.2 on, and every working
stage still narrates the activity. `plans/archive/CHALLENGE1_2026-09-15.md` Slice 15 is
closed.

### C-9 -- cell highlight rings follow the cup sprite's own silhouette

PASS confirmed, with one correction. All five rings trace the cup's own
silhouette, none cuts through the sprite, turning Cell art off returns every
ring to the flat hex, and the sprite-aligned hex grid works on restarting the
level. Dave's correction: "move the cell highlight rings 2 pixels lower.
otherwise as intended." That is `plans/now/ui-small-fixes.md` UI-T-3, which files C-20.
Owner was `plans/now/hive-comb.md` Slice 9.

### C-10 -- a hand-set toggle survives picking a Scenario

PASS confirmed on all three clauses. A weather toggle set by hand in the main
menu carried over into a Scenario; restarting the game removed the override;
preset A's values did not carry into preset B's run; and a custom override
did not leak into the next Scenario.
Owner was `plans/archive/SETTINGS_PERSISTENCE_2026-09-03.md` Slice 1.

### C-11 -- the centred command tray preserves both bottom-row gaps

PARTIAL, closed as superseded. Shifting between sizes works as UI-S-1
intended, and the gap between Dr Gallerin's text and the command bar is
correct. But there is no gap on the summary-panel side and the two overlap,
and the tray itself runs off the bottom edge with its top too low to see.
Superseded by `plans/now/ui-bottom-row.md` UI-T-1 and its check C-18. Dave's durable ask
from this entry -- "ensure that panels like the command panel can't go off
screen" -- is now a durable rule in that plan.
Owner was `plans/now/ui.md` UI-S-1.

### C-12 -- command tray reflows and stays on screen

FAIL, closed as superseded. Dave: "as much of the command panel is off screen
(off the bottom edge), i can't select 'more…'." Same defect as C-11's second
half; both are UI-T-1 in `plans/now/ui-bottom-row.md`, whose check C-18 replaces the pair.
Owner was `plans/now/ui.md` UI-S-3.

### C-13 -- left-side windows clear the corner and scroll

PASS confirmed on everything the entry asked, with one addition. Mutual
closing works, the Nursery still enters the hive view and shows its zone
glow, scrolling works, and starring works. Dave added: "left-side windows
still sit ontop and overlap with a summary window if that's open at the same
time, but these should not overlap. left-side windows should shorten in
response to the summary window size." That is `plans/now/ui-bottom-row.md` UI-T-2, which
files C-19.
Owner was `plans/now/ui.md` UI-S-2.

### C-14 -- double right-click command diagnosis

FAIL, closed as superseded -- but the diagnostic it existed to produce did
its job, and the answer overturns the theory UI-S-4 was built on.

Dave: still happening, for any bee rather than only the queen, and "it clocks
off their summary window/command panel so it's as if you're selecting off the
bee". The run's log was recovered from
`%APPDATA%\Godot\app_userdata\Meadow - Claude\logs\session_1788822502.jsonl`
(7 Sep 2026, ~23:35). Seventeen `command_issue` entries, and **every one
records `selected_count: 1`, `commandable_count: 1` and a correct state
transition**. Two pairs sit 0.62s and 0.72s apart in `game_time` -- the
double-clicks -- and in both the second command was accepted
(`MOVE_TO_POINT -> MOVE_TO_POINT`).

So the selection is not lost, no command is refused and no bee is pruned:
the panels are being hidden while the selection behind them is intact. That
is a presentation fault, not a selection one. `plans/now/ui-bottom-row.md` UI-S-4b owns
the fix and files C-23.
Owner was `plans/now/ui.md` UI-S-4.

### C-15 -- flower age and season read from the flower summary panel

PASS confirmed. Dave: "Works as intended." One balance note alongside it:
"Increases to flower resource production in peak season are a bit too high."
That is the new `plans/now/season-balance.md` SB-1, which files C-24.
Owner was `plans/archive/FLOWERS_SLICE_1_2026-09-03.md`.

### C-16 -- pre-run menu left inset

PASS confirmed. The left pane has a comfortable edge buffer and tile spacing,
borders and clicking are unchanged. A separate defect on the same screen:
"the first hexagons have part of the far-left hexagon point removed, despite
there being space to include the point." That is the border polygon being
drawn wider than the tile bbox and clipped by the wrapping ScrollContainer --
`plans/now/ui-small-fixes.md` UI-T-4, which files C-21. It is not a regression in UI-R-2.
Owner was `plans/now/ui.md` UI-R-2.

### C-17 -- the meadow's species mix follows the seasons without collapsing

PASS confirmed on every clause: "every season retains visible flowers,
out-of-season flowers remain rare rather than absent, and panel text/rates
agree." One balance note: "Out-of-season plants should be more rare." That is
`plans/now/season-balance.md` SB-2, which files C-25.
Owner was `plans/archive/FLOWERS_SLICE_2_2026-09-06.md`.

## Second 8 Sep 2026 pass -- the UI-T group's own checks

UI-T-1 to UI-T-5 and UI-S-4b shipped on 8 Sep 2026 and Dave ran their checks
the same day. Four passed outright and are recorded here. C-18 and C-19 did
not, and were re-filed against new slices rather than archived -- see
`checks/ready.md`.

### C-20 -- cell-art highlight rings align with their cups

PASS confirmed, with one adjustment: "Move the cell-art highlight rings 1 px
higher." UI-T-3 moved them 2px down from the previous high position; Dave's
eye puts the true centre 1px above where that landed. The correction is a
single constant and rides with the next slice that opens the cell-art
drawing, rather than a slice of its own.
Owner was `plans/archive/ui-small-fixes_2026-09-08.md` UI-T-3.

### C-21 -- pre-run menu's first hexagon is not clipped

PASS confirmed. Both the Challenges and Scenarios strips show unbroken
leftmost hexagons, every tile selects its own stage, and the left-pane text
inset is unchanged.
Owner was `plans/archive/ui-small-fixes_2026-09-08.md` UI-T-4.

### C-22 -- settings sections reset closed

PASS confirmed for the in-run settings window. Dave added one ask covering
the other end of the same behaviour: "make it so the pre-run settings opens
with every collection and topic section collapsed" -- the pre-run Settings
button still expands Accessibility and Appearance on purpose, and Dave would
rather it did not. That is a one-line change in the same file UI-T-5 touched
and is queued as UI-W-4 in `plans/now/ui-windows.md`.
Owner was `plans/archive/ui-small-fixes_2026-09-08.md` UI-T-5.

### C-23 -- a double right-click no longer closes the bee panels

PASS confirmed, in the strongest form: "no bee panel closure after single or
double right click." UI-S-4b's fix -- ignoring the duplicate `double_click`
event at the input boundary -- was the right one, and UI-S-4's lost-selection
theory stays retired. The diagnostic logging UI-S-4 added is what proved it
and is kept.
Owner was `plans/now/ui-bottom-row.md` UI-S-4b.

## Confirmed in Dave's pass of 12 Sep 2026

Each entry below passed as written. C-50 was never a player check; Claude Code ran it on 13 Sep 2026 and its entry says so.

### C-30 -- the new stage makes you designate a cell for pollen before it starts

Play Challenge 1 to stage 1.13, right after the second cell finishes building
(`docs/challenge-stages.md` lists every stage id and what it asks). Try
waiting, or right-clicking things unrelated to the cell.

PASS: the stage will not clear until you select the second cell and choose
Pollen; once you do, it clears immediately into the pollen-automation stage
that follows.

Owner: `plans/archive/CHALLENGE1_2026-09-15.md` Slice 18.

Passed (Dave, 12 Sep 2026).

### C-32 -- the soil panel's two buttons are full width and labelled

Select a soil block at the default text scale, then at the largest text scale.

PASS: at both scales, "Mark for digging" and "Clear marks" each span the
panel's width, show their label, and pressing each does what it says; at the
largest scale a label wraps onto a second line and the button grows taller
rather than the panel growing wider.

Owner: `plans/archive/HUD_CONTROLS_2026-09-11.md` HC-2.

Re-run note (Dave, 10 Sep 2026). The buttons' text now scales, which is what
HC-9 set out to do. Labels wrapping onto a second line at a smaller viewport
is within this check's stated pass condition and Dave confirmed on 10 Sep
2026 that it is not a fault. What remains is the blank band above the two
buttons: the soil summary leaves its energy, activity and trait labels
visible while empty, and an empty Godot Label still asks for a full line of
height. That is HC-13's third requirement.

HC-13 landed on 10 Sep 2026: an empty summary label is no longer shown,
and the panel retakes its height so the space is reclaimed rather than
left blank. Ready to re-run.

Passed (Dave, 12 Sep 2026).

### C-37 -- every control in the tray and the summary panel matches its neighbours

Start Challenge 1 and select the queen. Read the command tray, open `More…`,
and look at the summary panel's header. Then click a soil block, a tree and a
death mark in turn, and finally click a cell and read its "Raises:" row. Play
on to stage 1.16, where the queen is taught her laying job, and select her
again.

PASS: the current-job marker and the "Change to…" menu are the same lettering
size as every other control in the tray; the Favourite star and the cog beside
it are the same height; a soil, obstacle or death summary shows only the lines
it has text for, with no blank band above the buttons; before stage 1.16 the
`More…` panel offers neither "Lay in plain comb too" nor "Finish the job
first", and no empty "If idle:" row is left where they were; after 1.16 the
plain-comb checkbox is there; and the cell popup's "Raises:" choices that open
a menu end in an ellipsis, as the tray's "Change to…" does.

Owner: `plans/archive/HUD_CONTROLS_2026-09-11.md` HC-13.

A failure changes something: the tray sizes and the star's height would mean
the theme's `Small` variation is not what those controls fall through to, the
blank band would mean the summary panel's height is not being retaken when its
content shrinks, and a checkbox showing early would mean `allowed_role_keys`
does not carry the laying key at the stage `challenge_stages.gd` says it does.

Passed (Dave, 12 Sep 2026).

### C-38 -- Dr Gallerin's bubble types its line out

Trigger a Challenge prompt so Dr Gallerin's bubble appears (any welcome/hint
line, or click his icon after one has shown once). Watch the text appear a
character at a time rather than all at once, and note the bubble's size --
it should already be its final size on the very first character, not grow
as more text reveals. Then set game speed to 4x (Game Settings > World, or
the speed control) and trigger another prompt: the typing speed should look
the same as at 1x. Finally, mid-type, left-click anywhere on the bubble.

PASS: the line reveals one character at a time at a readable pace; the
bubble does not resize while typing; 4x game speed does not speed up the
typing; and clicking the bubble completes the line immediately.

Owner: `plans/archive/HUD_CONTROLS_2026-09-11.md` HC-5.

A failure changes something: text appearing all at once would mean
`visible_characters` isn't being driven from `_process()`; the bubble
growing as it types would mean the label isn't holding the full text from
the start; typing speeding up at 4x would mean `Engine.time_scale` isn't
being divided back out of `delta`; and a click doing nothing would mean
`gui_input` isn't wired to finish the line.

Passed (Dave, 12 Sep 2026).

### C-39 -- Dr Gallerin's bubble can be paged back through

Trigger several Challenge prompts (or click his icon repeatedly after
different lines have shown) so at least three lines have appeared in his
bubble. Click `◀` in the bubble's button row: the previous line should
appear in full, instantly -- not typed out. Keep clicking `◀` until you
reach the very first line shown; it should be disabled there rather than
doing nothing silently. Click `▶` back to the newest line the same way,
noting it disables at that end too. Then trigger a new prompt (or wait for
a queued one) while paged back to an older line: it should not replace what
you're reading. Click `▶` back to the newest line afterwards -- the new
prompt should be waiting there.

PASS: `◀`/`▶` step through previous lines one at a time, each shown in full
rather than typed; both arrows disable at their respective end instead of
doing nothing; and a prompt that becomes due while an older line is shown
waits until you return to the newest line rather than snatching the bubble.

Owner: `plans/archive/HUD_CONTROLS_2026-09-11.md` HC-6.

A failure changes something: the arrows doing nothing would mean
`_history`/`_history_index` aren't wired to the button row; a paged-back
line typing out would mean `_show_history_entry()` isn't bypassing the
typing effect; a live end failing to disable would mean
`_update_history_buttons()` isn't being called after every history change;
and a new prompt replacing an older line being read would mean the
`_fire_due_prompts()` guard in `_process()` isn't checking
`_history_index` against the newest entry.

Passed (Dave, 12 Sep 2026).

### C-40 -- a hexagon's title fits inside it, at every text size

In Game Settings > Accessibility, set Text scale to 2.0 (the maximum), then
return to the pre-run menu. Look at "Challenge 2 Brood, Roles and Expansion"
(the longest title) and "Scenario 3 Established nest" (the longest Scenario
title): both should read in full inside their own hexagon, not spilling
onto the backdrop or getting cut off mid-word. Check a completed stage's `✓`
tick sits cleanly in its corner, not crossed by the wrapped title. Then set
Text scale back to 1.0 and confirm every title still reads "Challenge 1
First Stores", "Challenge 2 Brood, Roles and Expansion", "Scenario 1 Queen
alone" and so on -- no colon after the Challenge number, no dash after the
Scenario number.

PASS: every title is fully readable inside its hexagon at text scale 1.0 and
2.0, the completion tick is never crossed by title text, and none of the
seven titles has a colon or dash after its number.

Owner: `plans/now/ui.md` UI-M-2.

A failure changes something: text still spilling outside the hexagon at 2.0
would mean the label's `theme_type_variation` is back on a size too large for
its box, or `clip_text` isn't set; the tick being crossed would mean the
label's box still reaches under it; a surviving colon or dash would mean the
`STAGES` table wasn't fully updated.

Passed (Dave, 12 Sep 2026).

### C-41 -- the command tray fits its content the first time you select a bee

Start a fresh run. Select any single bee (a forager is easiest). Look at the
command tray: its bottom edge should sit right after the last row of
content (Job/Focus/Orders, or the `More…` button if that's the last visible
row) -- no unneeded band of empty space below it, and no scrollbar unless
the tray's content genuinely does not fit the screen. Then select a
different bee of a very different kind (the queen, if she's selectable) and
check the same thing again on that first selection.

PASS: the tray's bottom edge tracks its content on the *first* time each
bee is selected -- no unnecessary empty space, no unneeded scrollbar.

Owner: `plans/archive/HUD_CONTROLS_2026-09-11.md` HC-8.

This only covers the first time a given selection state is built. Reselecting
back and forth between bees is now covered separately by C-43 (HC-16) --
this check is specifically about whether the *first* build is right, which
is what C-18's "unnecessary empty space at the bottom" on startup was about.

A failure changes something: empty space or a spurious scrollbar reappearing
here would mean `hud.gd::_resettle_command_tray`'s stability loop is no
longer converging before the tray is shown, which the automated check
(`tests/test_hc8_tray_first_open.py`) did not catch for some content shape
or text scale it doesn't cover.

Passed (Dave, 12 Sep 2026).

### C-43 -- the command tray fits its content on a reselection, not just the first time

Start a fresh run. Select a forager, open `More…`, then select a very
different bee (the queen, if she's selectable) while `More…` is still open.
Look at the command tray: its bottom edge should sit right after the last
row of content, no unneeded band of empty space below it and no scrollbar
unless the content genuinely does not fit. Switch back to the forager and
check the same thing again. Then repeat the whole forager <-> queen
reselection with `More…` closed. Try it at the default text size and at the
largest one (Settings > Accessibility).

PASS: the tray's height tracks its content on every reselection, not just
the first build of a given selection state -- with `More…` open and with it
closed, in both directions, at both text sizes.

Owner: `plans/archive/HUD_CONTROLS_2026-09-11.md` HC-16 (`plans/archive/HC-16_2026-09-11.md` for the full delivery record).

C-18's original report was exactly this: reselecting a bee after opening
`More…` left the tray "taking up a lot of the screen, with a lot of blank
space in the tray." HC-8 fixed the *first* build after a selection; this
covers every later one. The confirmed cause was `_rebuild_role_controls`
freeing the previous selection's rows with a plain `queue_free()`, which
left them parented -- and still counted by the tray's nested
`HFlowContainer`s -- for one to several frames after the new rows were
already added, so the tray briefly measured a mix of old and new content
and could settle on a plausible but wrong height. `hud.gd::_detach_and_free_children`
now detaches each old row from its column immediately, before any new row
is added.

Proven headlessly against a real Godot boot (not just self-consistency): with
the fix reverted, `tests/fixtures/hc16_tray_reselect_1x.json` fails; with it
in place, all four new fixtures pass --
`hc16_tray_reselect_1x.json`/`_2x.json` (no `More…`) and
`hc16_tray_reselect_more_1x.json`/`_2x.json` (`More…` open), run by
`tests/test_hc16_tray_reselect.py`. This hands-on check is the one thing
the headless proof cannot see for itself: whether the fix reads as right on
Dave's own screen, not only against a pixel tolerance.

A failure changes something: a wrong tray height reappearing here on a
reselection, after the automated fixtures above pass, would mean the fixed
seed and viewport sizes those fixtures use do not cover a content shape or
timing case the real game hits -- worth widening the fixtures before
treating it as fixed again.

Passed (Dave, 12 Sep 2026).

### C-44 -- Challenge 1's nectar lesson completes at 150

Play Challenge 1 to stage 1.11, "automate nectar gathering", and give the
queen the Forager role with nectar focus. Watch the numeric goal bar as she
deposits nectar into the first wax cell.

PASS: the goal bar becomes full and the stage advances on the deposit that
brings the cell to at least 150 nectar, without waiting for 200; the stage's
exit freezes the queen at that point.

Owner: `plans/archive/CHALLENGE1_2026-09-15.md` Slice 23.

Passed (Dave, 12 Sep 2026).

### C-45 -- Cell contents colour their outline

With Cell art on, have a forager deposit nectar into an empty built cell, then
empty that cell again. Compare its outline before the deposit, with nectar in
it, and after it is empty.

PASS: the first nectar deposit gives the cell a pale-yellow nectar outline,
and the built cell has no outline both before the deposit and after it is
empty.

Owner: `plans/archive/HIVE_COMB_2026-09-12.md` HCB-5.

Passed (Dave, 12 Sep 2026).

### C-47 -- Challenge 1's build marker stays in the hive

Play Challenge 1 through stages 1.12 and 1.15. At each build-cell stage,
look in both the hive and meadow views before placing the cell.

PASS: no yellow marker appears in the meadow. The yellow build marker appears
inside the hive, at the cell-building anchor.

Owner: `plans/archive/CHALLENGE1_2026-09-15.md` Slice 24.

Passed (Dave, 12 Sep 2026).

### C-51 -- the HUD is back: every panel and label draws again

Start a run and play for a minute. Look at the corner readouts, select a
bee, select a comb cell, and open the colony and nursery windows.

PASS: the corner readouts, the summary panel, the command tray, the goal
shelf and the warning corner all draw, and selecting a bee or a cell fills
them; nothing that used to be on screen is missing.

Owner: `plans/archive/UI-B-1_2026-09-12.md`.

Why it matters: `scripts/hud.gd` called `Rect2.get_closest_point()`, which
does not exist in Godot 4. A parse error fails the compile of every script
that depends on it, so `scripts/main.gd` never loaded and the whole HUD went
with it (Dave's 12 Sep 2026 report, with screenshots). `tools/verify.ps1`
now boots Godot and fails on any script error, so this class of break cannot
reach `master` again -- this check is the human confirmation that the HUD
Dave lost is the HUD he has back.

Passed (Dave, 12 Sep 2026).

### C-50 -- record A3's pinned performance baseline

Run the pinned baseline scenario and record its frame time against
`docs/PERFORMANCE_BASELINE.md`, alongside the existing exploratory-profile
note:

```powershell
python tools/run_scenario.py test_scenarios/recommendation_slice0_baseline.json --fixed-fps 60 --report brief
```

PASS: the run produces a `summary.performance` block (mean/p95 wall-clock ms
for total frame time and the three target sections), and that number is
written into `docs/PERFORMANCE_BASELINE.md`.

Owner: `plans/archive/architecture-review_2026-09-24.md` A3.

Filed instead of run in-session: four attempts in this session (default
300s timeout, 900s, 1500s, and after priming Godot's `.import` cache with an
`--editor --quit` boot) each produced only the scenario's initial config
line in the session log and no snapshot or summary line at all -- not slow,
stalled, the same way regardless of timeout length. That is worth a look on
its own if it recurs (this scenario is 85 foragers + 24 miners with the fog
CPU path on; `colony_30_bees_test.json`, far smaller, completed in 5.4s in
the same environment), but it did not block A3's own correctness: `tools/
verify.ps1` is green, including a new static check
(`check_hive_stock_epoch_cache` in `tests/source_checks.py`) that proves
`stock_epoch` exists, is distinct from `index_epoch`, and is bumped by
every deposit/withdraw/seal/unseal path in `hive_cell.gd`.

Run by Claude Code on 13 Sep 2026 from the primary checkout rather than a worktree: it completed (`outcome: performance_capture_complete`) and its numbers are recorded in `docs/PERFORMANCE_BASELINE.md`. The four stalls above all ran inside the A3 worktree, which fits the known fresh-worktree failure (no Godot import cache, so scripts silently fail to compile) -- likely, not proven.
