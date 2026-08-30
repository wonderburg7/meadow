# Ready hands-on checks

<!-- CONTEXT: player-checks | LAYER: on-demand -->

These are shipped behaviours that static checks cannot prove. An entry here
exists specifically so the branch/worktree that produced it could close
without waiting on a human to play-test it (see `CLAUDE.md`, "Coordinating
and closing out workstreams") -- landing a check here, not leaving the
worktree open, is what "done" means. Search for the feature and run only
its check. Move a confirmed or superseded entry to
`docs/archive/HANDS_ON_CHECKS_ARCHIVE.md`; blocked items belong in
`checks/blocked.md`.

### Empty-cell resprite + sprite-aligned hex grid -- new wax-cell art and grid shape (re-check after render-order/alignment fix)
- [ ] Look at any empty comb cell in the hive: confirm the
      `assets/sprites/environment/wax.cell.empty.png` cup art shows
      (Settings > Hive & comb > "Cell art" on, the default), its hex floor
      lands exactly on the grid's own hex (not floating above or sunk
      below it -- compare against a neighbouring filled cell's fill shape),
      and neighbouring cells tessellate edge to edge with no gap. Toggle
      "Cell art" off: cells should revert instantly to the original
      flat-colour fill, no lingering resprite.
- [ ] Look at a run of cells going down a column: confirm each cell's cup
      wall visibly overlaps -- stands in front of -- the top of the cell
      below it on screen, and that this holds regardless of which cell was
      built first (e.g. build a new cell above an older one and confirm
      the older one, now lower on screen relative to it, still paints in
      front). Previously cells painted in build order, so a cell built
      later could wrongly paint over one above it that was built earlier.
      See `scripts/hive_cell.gd`'s `z_index` line in `_ready`.
- [ ] Confirm cells with something in them (nectar, pollen, honey, brood,
      corpse) are unaffected by "Cell art" either way -- still flat
      colour, sprite never shows over live contents.
- [ ] Toggle Settings > Hive & comb > "Sprite-aligned hex grid" off, then
      Restart Run (it only applies to a freshly built hive -- see
      `Session.use_sprite_hex_grid`'s comment in `scripts/session.gd`):
      confirm the whole hive -- comb, floor, soil, the entrance tunnel --
      is visibly taller/more regular-hexagon-shaped than with the setting
      on, bees still path and dig normally, and nothing looks
      misaligned. Turn it back on and Restart Run again to confirm the
      squashed 2:1 grid returns and still matches the resprite's own
      32x16 footprint (`Shapes.SQUASH` in `scripts/shapes.gd`).
- [ ] Play a few minutes with the sprite-aligned grid on: foragers
      depositing into comb, a miner digging soil, the queen laying --
      general confidence the grid-geometry change (touches
      `hive.gd`/`world_building.gd`/`bee.gd`/`saving.gd`/`fog_of_war.gd`/
      `input_selection.gd`, all reading `Session.use_sprite_hex_grid`)
      hasn't broken navigation, digging or click targeting. The main
      menu's own honeycomb and icon backgrounds are deliberately
      unaffected by this setting -- they're decoration, not the hive grid.

### Accessibility fonts -- Typeface setting now has five real faces
- [ ] Open Settings > Appearance > Typeface and step through each option
      (Standard, Atkinson Hyperlegible, Open Sans, OpenDyslexic, Munro,
      Silkscreen): confirm every panel's text visibly changes face (not
      just size) and stays readable at 100% and 200% text scale. Font
      files newly added under `assets/fonts/` and wired in
      `scripts/ui_theme.gd`/`scripts/debug_panel.gd`.

### UI-N -- top-right button group gap and row-2 tooltips (re-check after fix)
- [ ] Row 1 (pause/speed buttons): confirm a real, visible gap now exists
      between the last speed button (1x/2x/4x, or 8x if enabled) and the
      settings cog -- previously zero, a real formula bug (both rows'
      content actually touched the cog; row 2's icon padding just masked
      it). Row 2: confirm the same visible gap, and hover each of Colony/
      Nursery/Foraging/Winter/Meadow-Hive -- the tooltip should now be one
      short line ("Opens the Nursery window.", etc.), not the old
      paragraph (that detail moved to each button's own "i" info badge,
      which should still show the full text on hover). See UI-O in
      `plans/now/ui.md`.

### UI-M -- settings-panel z-order and honeycomb tessellation (re-check after fix)
- [ ] Open the pre-run menu and click its top-right Settings button:
      confirm the settings window now appears *in front of* the menu's
      own background (previously invisible, opening behind it) and text-
      scale/contrast changes apply immediately as before.
- [ ] Look at the Challenges/Scenarios honeycombs: confirm neighbouring
      hex tiles now visibly touch edge-to-edge (no gap), alternating
      top/bottom so the row stays roughly level across two bands, and
      that clicking near a touching corner always selects the tile the
      pointer is actually over, never its neighbour. See UI-O in
      `plans/now/ui.md`.

### UI-I -- Dr Gallerin bubble: narrow-width overlap and live text scale (re-check after fix)
- [ ] Narrow the window below roughly 1000px width: confirm the role/
      command tray no longer renders underneath the bubble at any tested
      width (previously narrowing actually *removed* the tray's reserve
      for the bubble instead of shrinking it, making the overlap worse,
      not better).
- [ ] With a bubble showing, open Settings and change the text-scale
      slider: confirm the bubble's own text visibly resizes immediately,
      without needing to dismiss/re-trigger it. See UI-O in
      `plans/now/ui.md`.

### UI-H -- summary-panel cog placement and command/summary width split (re-check after fix)
- [ ] Select a bee or cell: confirm the panel's own configuration cog now
      sits on the same line as the bee name/first line of text, with no
      empty row above it, and the panel is correspondingly shorter.
- [ ] Select several bees at once (Job/Focus/Orders showing) and compare
      panel widths at a normal window size: the command tray should read
      about 10% wider than before, and the summary panel should now fill
      whatever room is actually left up to a 16px gap before the command
      tray, rather than a fixed narrow width -- flag if either reads too
      wide/narrow so the split can be retuned further.
- [ ] Narrow the window right down towards `MIN_SUPPORTED_WIDTH` (800px):
      confirm the summary panel and command tray never overlap each other
      at any width tested. See UI-O in `plans/now/ui.md`.

### Settings window -- position and "Show info icons" scroll (new, UI-O)
- [ ] Open the in-run settings window (top-right cog): confirm it now
      opens clearly below the full two-row HUD button bar, not
      overlapping/underneath it.
- [ ] Turn on "Show info icons" (Accessibility): confirm every row's
      toggle/+/- controls stay fully visible and reachable without a
      horizontal scrollbar appearing. See UI-O in `plans/now/ui.md`.

### Main menu -- settings icon and placeholder text wrap (new, UI-O)
- [ ] Open the pre-run menu: confirm the Settings button now shows the
      same gear glyph the in-run cog uses, not a "Settings" text button.
- [ ] Before selecting a Challenge or Scenario, confirm the right pane's
      placeholder text ("Choose a Challenge or Scenario on the left.")
      reads as normal wrapped sentences, not one letter per line. See
      UI-O in `plans/now/ui.md`.

### Challenge 1 Slice 8 -- acceptance-playthrough fixes (8a/8b/8d/8e)
- [ ] **8a (full-storage bug, any forager):** fill every compatible cell in
      the comb, then let a forager collect a load she has nowhere to put.
      Confirm she keeps the load and waits (does not silently lose it and
      loop back to the flower) until a cell frees up or a new one is built,
      then deposits normally.
- [ ] **8b (manual nectar collection):** during Challenge 1 stages 1.6-1.10,
      let the queen fill up at a flower. Confirm she stays at the flower
      instead of auto-flying home, and only travels home once you
      right-click the hive marker.
- [ ] **8c (re-verify, no code change):** with 8b fixed, replay the
      Bundle D/E checks below and confirm `harvest_deposited` /
      `second_cell_built` still only fire on a genuine deposit/build-finish,
      not on arrival or full load. Flag if this still misbehaves -- it would
      be new information, not the bug 8c originally suspected.
- [ ] **8d (backup-role guard):** during Challenge 1, open the queen's "If
      idle" backup-role menu and confirm Comb Worker is absent (only
      Forager/Egg Layer/Nurse offered). If reachable at all, confirm picking
      a backup role never starts the auto hex-spiral cell-building loop.
- [ ] **8e (nectar-foraging presentation):** at stage 1.11, assign Forager/
      Nectar and confirm the camera starts following the queen and the game
      speed jumps to 4x, both exactly once; once the nectar cell reads full,
      confirm foraging stops, camera-follow and speed both reset to normal
      exactly once (not every frame), and the queen stands idle beside the
      full cell awaiting the next command. See `plans/now/challenge-1.md`
      Slice 8.

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

