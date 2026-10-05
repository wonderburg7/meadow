# Running a feedback session at Dave's machine

Status: current | Owner: Dave | Verified: 2026-10-01

How to sit one tester down at Dave's own machine, watch them play and keep
what they say. Written for the first session (Saturday 3 or Sunday 4 October
2026; its route and decisions are in `plans/archive/feedback-build_2026-10-05.md`); the steps
hold for the next one. Every command below is Windows PowerShell 5.1.

## The route

Challenge 1 ("Challenge 1 First Stores", the top-left tile of the main menu),
then Scenario 2 "A working colony" on the Relaxed preset, played towards its
first winter. The Winter window opens by itself on day 6 and winter arrives
on day 21 (WO-1). A game-day lasts 200 seconds at speed 1, so day 21 is about
67 minutes away at speed 1 and about 17 at speed 4.

## Friday: freeze, then rehearse

1. After the last merge of the day, update and tag master, then re-import, so
   a script added since the editor last ran cannot stop the game loading (the
   "Could not resolve script" failure):

   ```powershell
   cd C:\Users\dl13860\Documents\Meadow\meadow
   git pull --ff-only
   git tag feedback-2026-10-03
   & "C:\Program Files\Godot\Godot.exe" --headless --path . --import
   ```

2. Put your own profile aside, so the game starts with no saves, no ticks and
   default settings:

   ```powershell
   cd $env:APPDATA\Godot\app_userdata
   Rename-Item "Meadow - Claude" "Meadow - Claude (Dave)"
   ```

3. Launch exactly as the tester will ("On the day", step 2) and play the route
   yourself. Time Challenge 1; in the Scenario note the day and stores when
   winter arrives and whether the colony lives through it on Relaxed. Reply
   by id for each check you pass on the way: C-68, C-69, C-75, C-89 and C-90
   (Challenge 1 and the Scenario's first days); C-79, C-80 and C-88 (press
   Skills at the top of the screen in the Scenario); C-91 and C-74 (day 6);
   C-76, C-77 and C-78 (saving, through the cog's Save run and Saves...);
   FBB-1's check once FBB-1 has merged.

4. Keep the rehearsal's profile apart, so the tester starts clean:

   ```powershell
   cd $env:APPDATA\Godot\app_userdata
   Rename-Item "Meadow - Claude" "Meadow - Claude (rehearsal)"
   ```

## On the day

1. Close every Claude Code and Codex session on this machine, and start none
   until "Afterwards" is done. Every Godot launch, a headless test included,
   keeps only the five newest session logs (`diagnostic_log.gd`,
   `MAX_SESSION_FILES`), and a merge would change the build between testers.
2. Launch:

   ```powershell
   cd C:\Users\dl13860\Documents\Meadow\meadow
   & "C:\Program Files\Godot\Godot.exe" --path . --maximized
   ```

   This runs the game without the editor, so a script error is written to the
   log and play carries on instead of stopping in the editor's debugger. The
   window title reads "Meadow - Claude (DEBUG)"; that is expected.
3. Before the tester sits down: open the cog on the main menu, set Text scale
   under Appearance to what reads comfortably on this screen, and leave
   everything else, Developer mode included, as it is. Give them a mouse with
   a right button: right-click gives every order.
4. Briefing, read out: "This is an early build of a bee-colony game. The first
   Challenge teaches the controls. After it you will run a colony of your own:
   try to get it through its first winter. The 1, 2 and 4 buttons change the
   speed. Please use the cog only for text size and for saving. Think aloud
   as you play; I will only step in if you are stuck for a couple of minutes."
5. While they play, write down: the clock time at the end of Challenge 1, and
   in the Scenario at day 6, at day 21 and at the end; every stall of more
   than a minute (where, and what they tried); every time you step in and
   what you said; what they say about it. With their agreement, Win+Alt+R
   records the game window and microphone (Xbox Game Bar).
6. Known oddities, to note rather than explain: in winter the meadow stays in
   bloom while the foragers stay in (`docs/gameplay-review-2026-09-30.md` F5);
   the cog shows debug Triggers and tuning values (decision 2 of the plan);
   a skill marked "Not built yet" does nothing when bought.
7. If the queen dies, "The queen is dead" offers Restart or Main Menu. A
   Scenario keeps three checkpoints, one every five game-days: choose Main
   Menu, then the cog, then Saves..., and load the newest checkpoint.

## Afterwards

1. Ask, in this order:
   1. What were you trying to do in the last ten minutes?
   2. When did you not know what to do next, and what did you try?
   3. What did you set bees to do on their own, and why?
   4. When the stores dropped, what did you think was causing it?
   5. Was anything too slow or too fast? When did you reach for the speed
      buttons?
   6. Which choice felt like it mattered, and which felt pointless?
   7. Did anything look broken?
   8. Would you play another half-hour? What would you want to do next?
2. Save the logs, keep the tester's profile, and restore yours:

   ```powershell
   cd $env:APPDATA\Godot\app_userdata
   New-Item -ItemType Directory -Force C:\Users\dl13860\Documents\Meadow\feedback | Out-Null
   Copy-Item -Recurse "Meadow - Claude\logs" C:\Users\dl13860\Documents\Meadow\feedback\2026-10-03-logs
   Rename-Item "Meadow - Claude" "Meadow - Claude (tester)"
   Rename-Item "Meadow - Claude (Dave)" "Meadow - Claude"
   ```

   The logs folder holds one `session_*.jsonl` per run (its settings, every
   death, an hourly snapshot and a summary, from `diagnostic_log.gd`, which is
   always on) and `godot*.log` files carrying any script error.
3. Group the notes by defect, confusion, pacing, decision quality and wanted
   expansion (`plans/design/product-scope.md` §14, "Evidence and feedback
   stream") and give them to a Claude session to file: a defect as a finding
   against its owning plan, the rest as evidence for the Colony Run
   definition pass.
