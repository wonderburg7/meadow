# Ready hands-on checks

<!-- CONTEXT: player-checks | LAYER: on-demand -->

These are shipped behaviours that static checks cannot prove. Search for the
feature and run only its check. Move a confirmed or superseded entry to
`docs/archive/HANDS_ON_CHECKS_ARCHIVE.md`; blocked items belong in
`checks/blocked.md`.

### UI-L -- pre-run menu no longer runs the simulation behind it
- [ ] Launch the game fresh (or Restart Run from the OS, not "Return to
      Main Menu" mid-session): confirm no bee, flower, day advance or
      weather change happens before Start is pressed -- only the menu is
      visible. Choose a Challenge and confirm it still loads only that
      Challenge's configuration; choose a Scenario and confirm the same.
      Confirm the existing in-run "Return to Main Menu" still just pauses
      the live session (world stays alive underneath) rather than this
      fresh-boot path. See UI-L in `plans/now/ui.md`.

### UI-K -- Foraging button hidden for Challenge 1
- [ ] Start Challenge 1 and confirm the top-right "Foraging" button is
      absent for every stage. Finish Challenge 1 ("Continue playing") and
      confirm it reappears immediately, exactly like the colony/nursery/
      view buttons. Separately confirm it stays visible throughout
      Challenge 2 (present from stage 2.1 onward) and in ordinary
      Scenarios. See UI-K in `plans/now/ui.md`.

### UI-J -- Dr Gallerin bubble matches the summary panel's layout behaviour
- [ ] Narrow the window below roughly 1000px width (`NARROW_BREAKPOINT`):
      confirm Dr Gallerin's bubble visibly shrinks and the role/command
      tray's reserved gap shrinks to match, exactly like the bottom-left
      summary panel's own narrow-width step; the role/command tray never
      renders underneath the bubble at any tested viewport width. See
      UI-J in `plans/now/ui.md`.

### UI-I -- Dr Gallerin bubble bigger, persistent, updates immediately
- [ ] Trigger a Dr Gallerin prompt (any Challenge stage transition, or
      click his icon after one has shown): confirm the bubble and its
      text are visibly larger than before and scale with the text-size
      accessibility setting; it stays on screen indefinitely until
      "Dismiss" or "Turn off Dr Gallerin" is clicked (no auto-hide);
      triggering a second prompt while the first is still showing (two
      stage transitions in quick succession) swaps the visible text
      immediately with no stale text lingering. See UI-I in
      `plans/now/ui.md`.

### UI-H -- role panel narrower, summary panel wider
- [ ] Select a bee or cell (so the bottom-left summary panel shows
      content) and select several bees at once (so the command tray
      shows Job/Focus/Orders): confirm the summary panel is visibly
      wider and the command tray's maximum width is visibly narrower by
      roughly 30% than before, with no overlap between the two or the
      Gallerin reserve at any viewport width down to
      `MIN_SUPPORTED_WIDTH`. The two multipliers (`SELECTION_TRAY_WIDTH`
      x1.3, `command_tray_max_width` x0.7) are a first-pass split, not an
      exact pixel conservation -- flag if the balance looks wrong so they
      can be retuned. See UI-H in `plans/now/ui.md`.

### UI-G -- centre role panels use the full tray width
- [ ] Select several bees at once (so Job/Focus/Orders all show content)
      and confirm the three command-tray columns and their buttons
      visibly spread across the tray's full width, headers centred, no
      cluster on the left with empty space to the right. See UI-G in
      `plans/now/ui.md`.

### UI-D/E/F -- Challenge top-bar hit area, doubled buttons, goal shelf placement
- [ ] Start a Challenge and try clicking the second-row top-bar buttons
      (Colony, Nursery, Foraging, etc.) while the goal shelf is visible in
      the top-right -- every part of each button should respond to a click,
      not just its exposed top edge (UI-D). Compare against a Scenario,
      where the goal shelf is hidden and this never showed up.
- [ ] Confirm every top-right control (pause, each speed multiplier,
      Colony, Nursery, Foraging, Winter, Meadow/Hive, settings cog) is
      visibly twice its old size and all sit at one consistent height
      (UI-E), and that the goal shelf starts clearly below both top-bar
      rows with a visible gap at every window size and text scale, never
      overlapping a button (UI-F). See UI-D/E/F in `plans/now/ui.md`.

### Challenge 1 Slices 1-2 -- role-panel hit areas, Poppy removal, manual cell building
- [ ] Play Challenge 1 from the start through building the first two cells
      (1.5 and 1.12). Confirm: the role-panel "Change to..." control responds
      to a click anywhere across its full row, not just over the text; no
      Poppy ever appears in this Challenge's meadow; pressing "Build cell"
      highlights valid tiles and does nothing until you click one; the build
      takes about 5 seconds; the queen's role/letter never becomes Comb
      Worker during or after building, and she resumes her prior job
      afterwards with no second cell starting on its own; the Job column and
      the cell popup's "Raises:" row offer only Forager and Egg Layer for the
      whole Challenge. See `plans/now/challenge-1.md` Slices 1-2.

### Save migrations and domain-event boundaries (efficiency Slice 5)
- [ ] Pure refactor: bee death, day rollover and a Challenge stage clear
      now reach their listeners via a Godot signal (`main.bee_died`,
      `main.day_changed`, `challenge_runner.challenge_stage_cleared`)
      instead of direct cross-script calls; rain start/stop gets a signal
      too (`main.rain_changed`) though nothing listens to it yet. No
      behaviour was meant to change. Play a session and confirm: a bee's
      epitaph toast and the death marker both still appear the moment she
      dies; the day counter/season text in the HUD still updates exactly
      on the day boundary; rain still starts/stops with its usual warning
      and overlay; a Challenge stage still clears, checkpoints and shows
      the next goal normally. Also save, then load that save, and confirm
      nothing looks different immediately after a load (the restore path
      was deliberately left setting state directly, not replaying any of
      these signals). See `plans/archive/CHATGPT_EFFICIENCY_IMPLEMENTATION_PLAN_2026-08-28.md`
      Slice 5.

### Challenge data/goal-registry extraction (efficiency Slice 4)
- [ ] Pure refactor: stage/prompt/target data moved to `challenge_stages.gd`,
      goal predicates moved from one `match` into a registry of bound
      methods in `challenge_runner.gd`, and the two Challenge 2 rescue/
      recovery prompts now come from named defs in `challenge_feedback.gd`.
      No stage text, target number or goal rule was meant to change. Play
      Challenge 1 through a few stages and Challenge 2 into a deliberate
      nectar collapse (spend down stores fast) and confirm: goal shelf text/
      progress still advances stage by stage exactly as before, Dr
      Gallerin's prompts still queue and show, and the rescue message
      ("Ahem. Field ecologists...") then the recovery/checkpoint-restore
      message ("A brief ecological wobble...") still fire at the same
      thresholds as before. See `plans/archive/CHATGPT_EFFICIENCY_IMPLEMENTATION_PLAN_2026-08-28.md`
      Slice 4.

### HUD popups bound to revisions, not frames (efficiency Slice 2)
- [ ] Cell popup, flower summary and the bee selection panel now refresh
      at a 10Hz cadence (or instantly on a real change) instead of every
      render frame. Select a cell and, while its popup is open, have
      another mechanism change it without touching that popup's own
      buttons -- e.g. open the Nursery panel and bulk-designate a zone
      that includes it, or let a forager finish a deposit into it, or let
      a builder finish building it -- and confirm the popup's numbers
      (fill amount, build %, "Raises:", Sealed/Filling state) update
      within a heartbeat, not a full second later or only on reselect.
      Do the same with a flower summary open (watch nectar/pollen tick)
      and a bee selected (watch age/energy tick, then give it an order
      from the tray and confirm the activity line changes immediately,
      not on a delay). See `plans/archive/CHATGPT_EFFICIENCY_IMPLEMENTATION_PLAN_2026-08-28.md`
      Slice 2.

### Cell/colony dirty-index refactor (efficiency Slice 1)
- [ ] `hive.gd`'s cell-content buckets and the comb/nursery panel's
      free/brood/gyne/hungry counts now rebuild only when a mutation says
      they might be stale, not once a frame/second regardless -- headless
      scenarios (`b3_postcondition_test.json`, `c4_stocking_hatch_test.json`,
      `b2_combined_role_test.json`) still pass unchanged, but watch for
      staleness on a real playthrough: build a cell, let brood hatch, kill
      a bee (debug panel), designate/clear a cell, and save+load -- the
      Comb line, nursery ring counts and colony window's role counts
      should all update the moment each of those happens, not lag a
      second behind. See `plans/archive/CHATGPT_EFFICIENCY_IMPLEMENTATION_PLAN_2026-08-28.md`
      Slice 1.

### Crab spiders (all bundles) -- final re-check
- [ ] Turn on `predators_on` and `show_crab_spiders` (settings cog,
      Predators section). Confirm: `crab_spider_attack_success_chance`
      appears as its own tunable setting; an escaped bee's exact flower
      stays off-limits even when forage is tight nearby
      (`predator_flower_cooldowns`, not the ordinary relaxed-fallback
      pool); every attack -- not just an alarm-pheromone avoidance --
      flashes red on the bee (`attack_ring`), distinct from the orange
      `alarm_ring`; and the dev marker reads as a bright magenta ring
      around the flower, not a filled blob competing with it visually.
      See `plans/archive/CRAB_SPIDER_PLAN.md` Bundle 5's 20 Aug follow-up notes for
      what was fixed and why.

### Challenge 1 Bundle G -- trim Challenge 2's opening (stages renumbered 2.1-2.9)
- [ ] Start Challenge 2 fresh from the main menu. Confirm it opens with
      the queen (role Laying) plus one nectar Forager already out in the
      meadow, 5 cells (2 nectar-full, 1 pollen-full, 2 empty), and the
      goal shelf showing stage 2.1's "watch the nectar stores fall, then
      recover them" (the old eggs_laid/nectar_forager_hatched opening is
      gone). Play through a couple more stages and confirm the ids/goals
      line up with `plans/archive/CHALLENGE1_REVAMP_PLAN.md`'s Bundle G section and
      nothing about the soft-failure/rescue (2.1's own goal) misfires on
      the very first stage. See `plans/now/challenge-1.md`.

### Challenge 1 Bundle F -- laying, backup nursing, the first daughter (stages 1.15-1.18)
- [ ] Play Challenge 1 through to the first egg: set the queen to Laying
      (Nursing backup is automatic, no picker interaction needed) and let
      her lay one egg (1.15), then keep her fed until it hatches (1.16).
      Confirm: the new worker doesn't dart straight for the exit on
      hatching; she instead circles the queen once and settles near her
      while pink hearts rise and fade above the queen; the queen doesn't
      immediately walk off to re-lay into the empty cell during that
      beat. Select the new worker (1.17) and check her summary/role panel
      read as expected (nectar Forager). Right-click the entrance to send
      her out (1.18) and confirm her farewell line ("Thanks for giving me
      life, Mum... I mean... my Queen...") appears as a speech bubble
      anchored above her (not the corner) and doesn't visually collide
      with Dr Gallerin's own bottom-right bubble, then that the Challenge
      completion window offers Continue to Challenge 2, Restart Challenge 1,
      and Main menu (not Continue playing). Choose each option in separate
      runs and confirm it starts Challenge 2, restarts Challenge 1, and opens
      the menu respectively. See `plans/now/challenge-1.md` Slices 6-7.

### Challenge 1 Bundle E -- automate nectar, then pollen (stages 1.11-1.14)
- [ ] Play Challenge 1 from the meadow-harvest deposit onward: assign the
      queen Forager/nectar and let her fill the nectar cell (1.11 -- runs
      at 2x her normal rate and stops on her own once it reads full), use
      her "Build cell" button for a second cell (1.12 -- this is the fix:
      it used to try to rebuild at the hive centre, which was already
      occupied by the first cell, so the button silently did nothing),
      switch her to Forager/pollen until its cell holds 75 (1.13, also 2x
      rate), then build a third cell (1.14). Confirm each stage's goal
      advances, the second and third cells land beside the first rather
      than failing, and 1.13's Gallerin copy withholds "pollen makes new
      workers" while 1.14's reveals it. See `plans/now/challenge-1.md`
      Slices 4-5.

### Challenge 1 Bundle D -- meadow arrival, manual foraging (stages 1.6-1.10)
- [ ] Play Challenge 1 through to the meadow: exit the hive (right-click
      the marked doorway), tour the three marked meadow points, gather
      from two flowers via right-click (`Bee.command_collect_from`), then
      right-click the hive's meadow-side marker to send the queen home.
      Once she arrives, right-click the wax cell to deposit the load.
      Confirm each stage's goal actually advances (queen reaching the
      meadow, the 3-point tour, each flower, the deposit), automatic
      movement/collection/deposit never clears a manual stage, and the
      queen never gets auto-assigned a role she wasn't manually given. See
      `plans/now/challenge-1.md` Slice 3.

### Same-flower ping-pong / thin-patch escape (foraging)
- [ ] Watch a forager worked into an isolated flower (nothing else within
      `forage_perception_radius`), and separately one in a busy patch
      (e.g. `foraging_evidence_base.json`'s 3-pollen-forager setup).
      Before: selection panel could sit alternating "inspecting a flower
      before deciding whether to feed" / "landing on a flower" for a long
      stretch with the carried amount barely moving -- worst case, forever,
      on the exact same flower. After: once nothing worthwhile is left to
      try (the same flower still on her own cooldown, or a run of thin
      finds), she should switch to "flying a search loop, looking for a
      ... flower" instead. See `plans/active/foraging-evidence.md`'s "Recent
      fixes".

### HUD integrity batch (UI-A)
- [ ] Hover/press every top-right button (pause, speed, Colony, Nursery,
      Foraging, Winter, Meadow/Hive, settings cog) in Dark, Light and High
      Contrast -- text should stay readable, not fall back to the engine
      default. Confirm Colony/Nursery/Foraging/Winter/Meadow-Hive all show a
      useful tooltip on hover and sit at one consistent height. Click a
      flower with an old scent mark and confirm the "Scent mark: Xs old"
      line disappears once the mark expires rather than staying forever.
      See `git log` (merge commit for `codex/ui-a-hud-integrity`).

### Safe forager return reserve (recommendation Slice 4)
- [ ] Foragers now turn for home based on a calculated return-energy
      estimate (distance x route factor x flight/upkeep rate, plus a
      safety margin) instead of a fixed 20% energy threshold -- watch a
      run with foragers ranging far from the hive and confirm they still
      turn back with a sensible margin rather than cutting it fine or
      turning back too early on short trips. `source_checks.py`/
      `balance_tests.py` pass; no headless A/B against the old fixed
      threshold has run yet. See `git log` (merge commit for
      `codex/recommendation-slice-4`).

### AI playtest harness (slices 1-7, the headless action driver)
- [ ] Review all seven slices end to end -- see `git log` for the
      slice-by-slice detail.

### Foraging window
- [ ] Foraging window (**G**) showed real numbers when Dave checked it 22
      Aug (see archive) but on 24 Aug showed no data at all -- check
      whether Auto scouting/Auto-recruitment were both off (the panel is
      correctly all-zero then) before treating this as a regression. See the
      current campaign in `plans/active/foraging-evidence.md`.

### Proximity recruitment (Slice 9)
- [ ] Turn on Proximity recruitment (settings cog, Foraging section) --
      confirms Auto-recruitment turns itself off (they're mutually
      exclusive). Watch for a forager briefly circling another one
      indoors (near the comb, not at the door) rather than either bee
      ever waiting anywhere; check the selection panel reads "dancing
      to..."/"being shown a better patch" during it. See
      current `plans/active/foraging-evidence.md` campaign -- this has not been
      through a real headless sweep yet, so it is also the first real look at
      whether it feels right, not just a confirmation of numbers already
      checked.

### Panel sizing and overlap (UI-B)
- [ ] Select a bee, then a cell, and watch the bottom-left summary panel
      and the bottom-centre command tray while resizing the window and
      raising the text scale: neither panel's width should change with
      what the current bee/cell shows (long idle-reason lines, a bee fact
      quote, a long obstacle description), only with the window size, and
      the two should never overlap. See UI-B in `plans/now/ui.md`.

### Nursery zone removal and cell action-tray redesign (UI-C)
- [ ] Select a hive cell: the tray is now two primary columns, "Reserve
      for" and "Nursery" (priority Low/Medium/High, "Open nursery window",
      and the Raises controls -- hatch role, "Keep for every bee", "Raise a
      gyne" -- all together), with More… revealing Emptying and Sealing.
      There is no separate "Add"/"Remove" zone button anywhere -- reserving
      a cell for eggs is done from Reserve for's Eggs/Unreserve buttons.
      Confirm pressing a Priority button still reserves the cell for brood
      if it wasn't already, and that the queen still lays eggs sensibly
      (respects the priority-tier proportions, `queen_lays_in_any_cell`
      still behaves as documented). See UI-C in `plans/now/ui.md`.
