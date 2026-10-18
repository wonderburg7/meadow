# Blocked hands-on checks

<!-- CONTEXT: player-checks | LAYER: blocked | LOAD: only after its unblocker ships -->

These are known checks that cannot yet provide new evidence. Do not load or
re-run them during normal implementation. When the named unblocker ships,
move the entry to `checks/ready.md` keeping its id; move confirmed checks to
`docs/archive/HANDS_ON_CHECKS_ARCHIVE.md`.

Entries use `checks/ready.md`'s format -- one id, one action, one `PASS:`
line, one `Owner:` line -- plus a `Blocked by:` line naming what has to ship
first. The id follows the entry when it moves, and `tools/check_docs.py`
fails if it is reused in either file.

The one difference from `checks/ready.md`: a blocked check may write
`Owner: none` when the plan that owned it has closed, since its `Blocked by:`
line already says what would give it a new one. Every ready entry must name a
plan file that exists.

### C-2 -- a missing font has no visible effect

Selecting one of the three non-default typefaces does nothing, because those
font files are absent from `assets/fonts/`.

PASS: each of the five typefaces visibly changes the UI's lettering.

Blocked by: an asset/licensing commit, not more UI code. If a theme-reload
change is made meanwhile, confirm that selecting a missing font does no
wasted visible work.

Owner: `plans/archive/UI_SETTINGS_PLAN_2026-08-24.md`.

### C-6 -- the deferred recruitment competition fix

The recruitment competition fix (`103d716`) has never been run.

PASS: n/a until it is selected -- this is a deferred code change, not a
shipped behaviour.

Blocked by: a selected recruitment update. The evidence campaign that would
have owned it closed on 3 Sep 2026 with no threshold change
(`plans/archive/FORAGING_EVIDENCE_2026-09-03.md`), so a new plan file has to
pick this up before it can be checked at all.

Owner: none currently.

### C-109 -- Colony Run's goal shelf shows the next milestone

What this checks: On the main menu, pick the "Colony Run" tile (the first tile in the Scenarios strip) and press Start. Look under the top-right button row for the goal shelf, then let the game run (the speed-up button helps) until the queen's first egg hatches into a worker and emerges.

PASS: the goal shelf reads "Raise your first worker" at the start, and once the first worker emerges it shows the next goal, "Unlock your first automation", with "Raise your first worker" struck through beneath it.

If it fails, COL-1 reopens: `colony_milestones.show_next` in `scripts/colony_milestones.gd` (the goal text and which milestone is shown) or its calls in `scripts/main.gd` (run start, load and milestone change).

Runner: opus -- the player must time collection and the first worker by hand (Dave, 11 Oct 2026): a long played founding, which haiku cannot do

Owner: `plans/archive/colony-run_2026-10-08.md`

Blocked by: RR-1 (`plans/now/run-repairs.md`) -- a lone Colony Run queen cannot build her first cell, so no Colony Run grows past the founding (10-11 Oct 2026 pass).

### C-110 -- Colony Run victory screen

What this checks: run the game in its own window. In Git Bash, run `cd /c/Users/dl13860/Documents/Meadow/meadow`
then `"/c/Program Files/Godot/Godot.exe" --path .`. From the main menu start a Colony Run (the first tile in the Scenarios strip). Play at high speed through the first winter (about days 21 to 41) until a gyne leaves. Then save, load that save, and keep playing past the next gyne.

PASS: when the first gyne leaves after winter, a completion screen opens with Colony Run wording; Continue keeps the run going and Main menu ends it; after saving and loading, the screen does not open again.

If it fails, COL-2 (`plans/archive/colony-run_2026-10-08.md`) reopens: a screen that never opens or opens for a gyne before winter is a fault in `scripts/colony_milestones.gd::check_victory`, and a screen that returns after a load is a fault in its `restore`. When you report a failure, say which day the screen opened on and whether it showed Challenge wording.

Runner: opus -- a long play through the first winter, then save and load

Owner: `plans/archive/colony-run_2026-10-08.md`

Blocked by: RR-1 (`plans/now/run-repairs.md`) -- a lone Colony Run queen cannot build her first cell, so no Colony Run grows past the founding (10-11 Oct 2026 pass).

### C-111 -- A lost Colony Run offers its latest checkpoint

What this checks: Start a Colony Run from the main menu and play past day 5 so a checkpoint is written (one is saved every 5 days), then let the queen die (the debug panel can kill her, if it offers that). On the game-over screen look for a "Load the latest checkpoint (day N)" button and press it. Then start a Scenario from the menu, lose it the same way, and look at its game-over screen.

PASS: The Colony Run's game-over screen shows "Load the latest checkpoint (day N)" with the right day, pressing it brings the run back as it was on that day, and a Scenario's game-over screen has no such button.

If it fails, the slice COL-3 reopens: scripts/game_over.gd (the button's gate or the day it names) or scripts/saves_panel.gd::reload_from (the load itself).

Runner: sonnet -- a checkpoint, a debug kill and two game-over screens

Owner: `plans/archive/colony-run_2026-10-08.md`

Blocked by: RR-1 (`plans/now/run-repairs.md`) -- a lone Colony Run queen cannot build her first cell, so no Colony Run grows past the founding (10-11 Oct 2026 pass).

### C-114 -- An unmated queen's nuptial flights: the succession window's button and the Mating row switch

What this checks: in a Colony Run that has an adult gyne in the hive, kill the queen with the developer "End the run" button in the settings window, so the gyne takes over. When the "A new queen" window opens, press "Nuptial flights". Then click the new queen, and in the panel at the bottom check the "Mating" row shows "Nuptial flights" lit. Press "Lay drones in the hive" and then "Nuptial flights" again, and watch her (8x speed helps) walk out through the entrance once that day, wait in the meadow, and come back. On a mid-summer day (about day 11 to 20) she should mate within a few days. Her readout then loses "Unmated" and the Mating row is gone the next time you click her.

PASS: Both buttons in the window and the Mating row read clearly and switch her mode, she flies out and back once a day, and once mated the Mating row no longer appears.

If it fails, the change is in scripts/succession_panel.gd (the window's buttons), scripts/hud.gd::_build_mating_row (the row) or scripts/bee.gd's nuptial flights section (the flight itself), and COL-11 reopens.

Runner: opus -- sets up a gyne succession and watches her flights over several days

Owner: `plans/archive/colony-run_2026-10-08.md`

Blocked by: RR-1 (`plans/now/run-repairs.md`) -- a lone Colony Run queen cannot build her first cell, so no Colony Run grows past the founding (10-11 Oct 2026 pass).

### C-115 -- Sending a gyne in mid summer wins; in early spring she is lost

What this checks: start the Colony Run from the main menu and, before the
first winter, raise two or three gynes (click an empty cell and tick "Raise
a gyne (a future queen)" in its popup; nurses need royal jelly first). Play
through the first winter. In the first five days after spring arrives,
click one adult gyne: her panel's Focus column has a "Send her to found a
colony" button (greyed out, with a line in her readout saying why, until her
energy is 80% or more). Press it. Later, when the day readout says
"Midsummer" (around 15 days after winter ends), send another ready gyne the
same way.

PASS: the early-spring gyne leaves with a notice that she found no mate and does not count, and no win screen opens; the midsummer gyne's notice names the genetic points she earned (10 at the height of summer) and the run's total, and the Colony Run win screen opens.

If it fails, COL-7 (`plans/archive/colony-run_2026-10-08.md`, or its archive record once
merged) reopens: a missing or always-greyed button is `scripts/hud.gd`'s
`_build_gyne_send_row`, a wrong notice is `scripts/year_winter.gd`, and a
win from the spring gyne, or none from the summer one, is
`scripts/season.gd::send_gyne`. Say which notice you saw and on what day.

Runner: opus -- raises gynes through winter and times two sends by the season

Owner: `plans/archive/colony-run_2026-10-08.md`

Blocked by: RR-1 (`plans/now/run-repairs.md`) -- a lone Colony Run queen cannot build her first cell, so no Colony Run grows past the founding (10-11 Oct 2026 pass).

### C-116 -- Meadow dies back over winter and regrows

What this checks: Start a Colony Run (a level with winter on) and play until winter arrives, then look at the meadow on spring's first day and for the next few days. No setting needs changing.

PASS: On spring's first day every flower is bare (no nectar), and the meadow is back in flower about three days later.

If it fails, the factor in `scripts/season.gd::_update_regrowth` or the `spring_regrowth_days` default (3) in `scripts/game_config.gd` is wrong, and COL-8 reopens.

Runner: sonnet -- plays to spring and looks at the flowers over a few days

Owner: `plans/archive/colony-run_2026-10-08.md`

Blocked by: RR-1 (`plans/now/run-repairs.md`) -- a lone Colony Run queen cannot build her first cell, so no Colony Run grows past the founding (10-11 Oct 2026 pass).

### C-117 -- Rain skills in the Colony Run

In Settings, Weather section, untick "Weather on" and set "Rain chance/day" to 6, then start a
Colony Run from the main menu. With foragers working outside, buy Weather
sensing and Rain recall in Skills and watch the next shower build.

PASS: Rain arrives despite Weather being off, no forager starts a trip toward the approaching heavy rain, and those already outside return once it grows heavy.

If it fails, reopen T2-5's weather policy or bee recall behavior.

Runner: dave -- whether foragers avoid approaching rain is movement over time, not visible in stills

Owner: `plans/now/tier-two.md`

Blocked by: RR-1 (`plans/now/run-repairs.md`) -- a lone Colony Run queen cannot build her first cell, so no Colony Run grows past the founding (10-11 Oct 2026 pass).

### C-118 -- Shiver Cluster in a Colony Run: the Winter note and doubled figure, gone once the node is bought

What this checks: Start a Colony Run from the main menu and play until the Winter countdown begins, then open the Winter window. Read its Shiver Cluster note and the stores figure it asks for, then open the Skills tree (Hive Mind, behind Backup roles), buy Shiver Cluster, and look at the Winter window again.

PASS: Before buying, the Winter window names Shiver Cluster and shows double the stores figure; after buying, the note is gone and the figure halves.

If it fails, the node or its starting rule (T2-8b, scripts/skills.gd and run_availability.gd) reopens.

Runner: sonnet -- plays to the winter countdown, reads a figure, buys a skill, reads it again

Owner: `plans/now/tier-two.md`

Blocked by: RR-1 (`plans/now/run-repairs.md`) -- a lone Colony Run queen cannot build her first cell, so no Colony Run grows past the founding (10-11 Oct 2026 pass).

### C-84 -- Challenge 2's last stage shows what is still short

What this checks: play Challenge 2 through to 2.9, which asks for 300 nectar, 150 pollen, 10 nectar Foragers, 4 pollen Foragers, 2 nurses, 2 Comb workers and 2 miners all at once (`docs/challenge-stages.md`). Play it out without the stage arrows.

PASS: throughout 2.9 you can tell from the screen which of the seven targets are still short, and you finish it without guessing.

If it fails, 2.9 needs a progress readout or a Dr Gallerin line (its `prompts` list in `scripts/challenge_stages.gd` is empty, the only stage with none), and it goes to Dave as a Challenge 2 goal-presentation slice. Found by `docs/product-review-2026-09-30.md`.

Runner: dave -- a long unassisted Challenge 2 playthrough judged on whether the goals felt readable

Owner: `plans/archive/hands-on-findings_2026-10-05.md`

Blocked by: RR-1 (`plans/now/run-repairs.md`) and T2-9 (`plans/now/tier-two.md`) -- Challenge 2 has no way to make new cells: the queen's Build cell is Challenge 1 only and Comb worker is blocked at 2.7 (Dave, 11 Oct 2026).

### C-136 -- Without Automation, a miner's Job panel offers no Dig on its own

What this checks: start a Colony Run without Automation (Skills > Hive Mind), select a Miner and read its Job panel; then open a comb cell's raise menu and read the Miner entries.

PASS: neither the Job panel nor the raise menu offers "Dig on its own" until Automation is owned.

If it fails, T2-12 reopens: the mode filter in `scripts/hud.gd` (the mode column or `_fill_hatch_menu`).

Runner: haiku -- reading two menus for one label

Owner: `plans/now/tier-two.md`

Blocked by: T2-12 (`plans/now/tier-two.md`), which waits for `scripts/hud.gd`.

### C-130 -- Hive soil blocks show Dave's art and crumble as they are dug

What this checks: Start a game with Cell art on (Settings), open the hive view and zoom in on the soil wall. Mark one soil block for digging and watch it while a bee mines it.

PASS: The blocks look like Dave's soil art, sit on their hexes like the comb cups, and the marked block crumbles through four pictures before vanishing.

If it fails, SP-9 reopens: the block offset (side height 14 px in scripts/soil_block.gd) or the quarter-to-picture mapping needs adjusting.

Runner: dave

Owner: `plans/now/sprites.md`

Blocked by: SP-10 (`plans/now/sprites.md`) -- the blocks draw in the wrong order outside the bottom right of the hive (Dave, 14 Oct 2026), so whether they sit on their hexes cannot be judged until it lands.
