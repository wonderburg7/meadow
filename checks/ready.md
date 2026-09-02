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

### Settings window: row gap next to the scrollbar (UI-P-6)
- [ ] With "Show info icons" on and off, open the settings window and
      confirm every row's content sits a small, consistent (~6px) gap from
      the scrollbar, not a larger unexplained gap from the panel's outer
      edge. The fix (`debug_panel.gd`'s `content_margin` MarginContainer,
      `margin_right = 6`, wrapping the settings column) shipped 31 Aug 2026
      in the same commit as UI-P-1/3/4/7/8 but was never confirmed live or
      recorded as shipped -- this entry is that missing confirmation.

### Warning banner: one throttle at the channel (C2, UI-Q-1/UI-Q-2)
- [ ] Two throttled events eight seconds apart (e.g. a bee death epitaph,
      then a crab spider escape) no longer wipe each other -- both throttles
      now live in `hud.gd::show_warning`'s one `key -> last shown` dictionary
      instead of each producer's own `last_*` timestamp on `main.gd`.
- [ ] A "Run saved." confirmation survives an unrelated ambient event (rain
      starting, a low-energy warning) firing shortly after it.

### Save migrations and domain-event boundaries (efficiency Slice 5)
- [x] Confirmed 31 Aug: the epitaph toast and death marker on death, the
      day/season boundary update, and rain start/stop plus a Challenge
      stage clear/checkpoint all still fire correctly -- the signal
      refactor itself is clean.
- [ ] **Fix applied 31 Aug, not yet confirmed live:** saving then loading a
      save made many bees, including the queen, disappear -- root-caused to
      a `saving.gd:275` typed-array assignment throw that restored zero
      bees on every load. Fixed on `claude/save-restore-slice-a` by
      building `known_patches` as a locally-typed `Array[Vector2]` before
      assignment. Boot the game, load a save with at least one bee (the
      repro save had 110, queen included), and confirm every bee restores
      with no `known_patches`/`Invalid assignment` error in the console.
      Also confirm the console no longer shows repeated "Exponent too
      high" warnings on that same load (the paired `save_game.gd` fix, was
      284 lines on the repro save). See
      `plans/archive/HANDS_ON_FIXES_2026-08-31.md` Slice A1/A0.

### Challenge data/goal-registry extraction (efficiency Slice 4)
- [x] Confirmed 31 Aug: goal shelf text/progress still advances stage by
      stage exactly as before.
- [ ] **Fix applied 31 Aug, not yet confirmed live:** neither the rescue
      message ("Ahem. Field ecologists...") nor the recovery/checkpoint-
      restore message ("A brief ecological wobble...") appeared during a
      Challenge 2 nectar collapse. Most likely explained entirely by the
      known_patches restore crash above (checkpoint-restore reuses the
      same `_restore()` path); `challenge_runner.gd::_check_c2_failure()`
      also now guards `TutorialCheckpoint.restore()`'s return and
      `main.queen` validity before use, matching its other 14 call sites.
      Trigger a Challenge 2 nectar collapse past stage 2.1 and confirm the
      recovery Gallerin line appears and the queen survives the restore.
      See `plans/archive/HANDS_ON_FIXES_2026-08-31.md` Slice A2.

### Challenge 1 Bundle G -- trim Challenge 2's opening (stages renumbered 2.1-2.9)
- [x] Confirmed 31 Aug: Challenge 2 opens with the queen (role Laying)
      plus one nectar Forager already out in the meadow, 5 cells (2
      nectar-full, 1 pollen-full, 2 empty), and the goal shelf showing
      stage 2.1's "watch the nectar stores fall, then recover them" text.
      Dave noted he intends to revisit the goal wording later -- a design
      preference, not a bug, not tracked as an issue here.
- [ ] **Not confirmed, found broken 31 Aug:** the Meadow view button never
      appears in Challenge 2 (missing `"meadow_view"` unlock key in every
      `STAGES_2` entry). See `plans/archive/HANDS_ON_FIXES_2026-08-31.md`
      Slice B.

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
      workers" while 1.14's reveals it. See `plans/archive/CHALLENGE1_SLICES_1-10.md`
      Slices 4-5.
- [ ] **Fix applied 1 Sep (10c), not yet confirmed live:** nothing ever
      stopped the queen's automatic pollen foraging once a stage's target
      amount was reached -- she kept going toward the cell's real 200-unit
      capacity, well past the 75-unit pollen target. Stage 1.13 now runs
      the same `"freeze_bee:queen"` on_exit effect 1.11 already ships.
      Confirm at 1.13: let the queen auto-forage pollen, the stage should
      advance right at 75 (not before), and she should be idle immediately
      after -- not still flying to a flower or continuing to collect. See
      `plans/archive/CHALLENGE1_SLICES_1-10.md` Slice 10, section 10c.
- [ ] **Fix applied 1 Sep (10d), not yet confirmed live:** assigning
      Forager/pollen didn't visibly start automatic pollen foraging in one
      31 Aug run -- traced to the "Doing" (nectar/pollen) row reading only
      the queen's primary role (`EGG_LAYER`), which never renders a mode
      row for her while she forages via her secondary/backup role; and even
      once rendered, `Bee.set_focus()`'s own primary-role-only guard would
      have silently no-opped the click. Both are fixed: `Bee.
      current_working_role()` and `hud.gd`'s new `_common_working_role()`
      key the Doing row off whichever role she's actively working, and
      `set_focus()` now accepts the change while she's working Forager as a
      backup role. Confirm at 1.13: select the queen while she's
      auto-foraging nectar via her backup role, open the Doing row, and
      pick Pollen -- it should render, take, and she should switch to
      pollen collection. See `plans/archive/CHALLENGE1_SLICES_1-10.md` Slice 10,
      section 10d.
- [x] **Confirmed 1 Sep (10e), no bug:** Dave confirms "Laying" appeared as a
      *new choice* in the "Change to..." list right after the third cell --
      the intended 1.14->1.15 pacing, not a leak. Closed with no code change.
      The separate, still-unfixed 9d (current-role marker showing "Laying"
      before 1.15) remains open and is tracked only under Slice 9's own
      entry above. See `plans/archive/CHALLENGE1_SLICES_1-10.md` Slice 10, section 10e.

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
      `plans/archive/CHALLENGE1_SLICES_1-10.md` Slice 3.
- [ ] **Fix applied 1 Sep (10a/10g), not yet confirmed live:**
      right-clicking a flower during these stages used to permanently make
      the queen a real Forager (she read "Forager -- nectar" with no role
      ever manually assigned) and kept auto-foraging after every deposit
      from then on -- `Bee.command_collect_from()` calling
      `set_role(Role.FORAGER)` unconditionally, with no Challenge-aware
      lock. `Bee.role_change_locked` now suppresses the promotion during
      1.6-1.10 and the flower-occupied guard runs before any mutation.
      Confirm: right-click two flowers in turn, collect from each, and the
      Job column should keep reading "Laying" throughout -- no "Forager"
      anywhere, and no automatic foraging resumes after the deposit at
      1.10. See `plans/archive/CHALLENGE1_SLICES_1-10.md` Slice 10, sections 10a/10g.
- [ ] **Fix applied 1 Sep (10f), not yet confirmed live:** 1.8/1.9 used to
      clear on a *rejected* flower as readily as a collected one, since
      both goals counted `Bee.flower_cooldowns.size()`, which also grew on
      a rejection. They now read a dedicated
      `ChallengeRunner._c1_queen_collections` counter, incremented only
      from a real completed collection. Confirm at 1.8: right-click a
      visibly near-empty/depleted flower twice and the stage should **not**
      clear; then collect from one real flower and it should. See
      `plans/archive/CHALLENGE1_SLICES_1-10.md` Slice 10, section 10f.
- [ ] **No code needed (10b):** once the above two fixes land, confirm
      live that the backup-role path Slice 9a fixed also stays closed --
      i.e. the queen never shows "Forager" anywhere during 1.6-1.10 by any
      route, not just via the manual flower-click path above. See
      `plans/archive/CHALLENGE1_SLICES_1-10.md` Slice 10, section 10b.

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
- [ ] **Counter added 1 Sep (X1):** foragers
      self-refuel to full at any flower with nectar (`drink_at_flower`)
      well before the calculated reserve is ever approached in an ordinary
      meadow, and the check is skipped outright while she's carrying any
      nectar. This is very likely working as designed (an emergency-only
      path for sparse/long-range conditions). In the Foraging panel, confirm
      **Forager returns triggered** reads zero in an ordinary meadow and rises
      during a sparse/long-range or rainy run. See
      `plans/active/foraging-evidence.md` Slice 3.

### Nectar/pollen recharge reads as stuck (hands-on-fixes Slice C)
- [ ] **Fix applied 31 Aug, not yet confirmed live:** three fixes, none
      confirmed as Dave's specific cause but each closing a real gap. Click
      a flower's detail panel and confirm the shown "+_/s" rate now reflects
      season/senescence (reads ~0.00/s when out of season or senescent,
      instead of the old nominal rate that never matched what was actually
      happening). Watch a flower under forager pressure near the "1" floor
      and confirm it no longer looks pinned -- `nearest_flower()` now skips
      anything below `GameConfig.min_worthwhile_amount`, not just `<= 0.0`.
      Pick a Scenario preset after tweaking a debug-panel flower/season
      toggle and confirm the toggle is back to its default rather than
      leaking into the new run (`SettingsCatalogue.reset_config_to_defaults()`,
      called from `main.gd::_on_scenario_chosen`). See
      `plans/archive/HANDS_ON_FIXES_2026-08-31.md` Slice C1-C3.

### AI playtest harness (slices 1-7, the headless action driver)
- [ ] Review all seven slices end to end -- see `git log` for the
      slice-by-slice detail.

### Foraging window
- [x] Confirmed 31 Aug (second time): the panel shows real numbers again.
- [ ] **Fix applied 1 Sep (Slice 1, Option B), not yet confirmed live:**
      Orientation flight used to read 0 even with the toggle showing as
      triggered, because `orientation_flight_on`/`scouting_on` were wired as
      settings-prerequisite parent/child (so switching Scouting on also lit
      Orientation flight) while the runtime treats them as alternatives
      (`if scouting_on ... elif orientation_flight_on`) -- the counter could
      never move while scouting was on. The two toggles are now in
      `prerequisites.gd::MUTUALLY_EXCLUSIVE` instead: turning either on
      turns the other off, in both the setting and its checkbox. Confirm:
      switch Auto scouting on, confirm Orientation flight's checkbox turns
      itself off (not just staying lit with a zero counter); switch
      Orientation flight on and confirm the same in reverse, and that its
      counter now moves. See `plans/archive/FORAGING_EVIDENCE_SLICE_1.md`.

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
- [ ] **Not confirmed, found broken 31 Aug:** no dance observed over
      several in-game days. Traced end to end in static code with no
      defect found -- eligibility scoring, the per-frame proximity check
      and the shared `_recruitment_matches` counter are all wired
      correctly. Most likely a threshold/timing tuning question rather
      than a logic bug; needs one long run read against the diagnostic
      counters before any threshold changes. See
      `plans/active/foraging-evidence.md` Slice 2.

### Hive comb visual alignment (Slices 1-3)
- [ ] With Cell art on at the default comb spacing, inspect a column and
      lower-side neighbours: empty cups should sit one pixel higher without a
      visible seam. Multi-select an empty cell: its green ring should trace
      the cup's raised back wall. Turn Cell art off mid-run: the same ring
      should immediately return to the unchanged flat-hex outline. In
      Settings, confirm Cell art, Show cell contents text, Sprite-aligned hex
      grid and Direction-even hex speed are all under Appearance and absent
      from Hive & comb; all other Hive & comb controls remain there.

### Hive comb above-centre-row rendering (Slice 6)
- [ ] **Fix applied 1 Sep, not yet confirmed live:** cells placed in rows
      above the comb's centre line never painted, even though they existed,
      were built and held content correctly -- traced to the hive-floor
      polygon's default `z_index = 0` occluding any cell whose own
      row-ordered `z_index` (`2 * axial.y + axial.x`) goes negative above
      the centre. Fixed by pinning the floor tile's `z_index` to -4096
      (`world_building.gd::_add_floor_tile`, `HIVE_FLOOR_Z_INDEX`) so it can
      never sit above a cell regardless of sign. Build comb rows both above
      and below the hive's centre line and confirm every cell renders
      (empty cup or filled) with no gap, in both Cell-art-on and -off modes.

### Hive comb navigation cost (Slice 7)
- [ ] Build a wide comb across the hive while an open-floor detour remains,
      then send a bee from one side to the other: she should prefer the open
      floor over travelling straight across comb. Save and reload; the route
      should remain the same before and after reload.

### Challenge 1 Slice 9 fixes (9a-9j)
- [ ] Re-run Slice 7's full acceptance playthrough (`plans/now/challenge-1.md`
      Slice 7) end to end. In particular: the queen's backup role no longer
      lets her auto-build/auto-forage before a stage unlocks it (9a); "Build
      cell" stays visible whenever a fourth cell might be needed, not just at
      three fixed stage ids (9b); hatch options never offer "Default" (9c);
      the Job column's current-role marker respects `allowed_role_keys` (9d);
      "Raise a gyne" is hidden until its stage gate (9e); Dr Gallerin's hint
      text says "any flower" not "marked flower" (9f); a manually-placed
      second cell renders (9g); commanding a bee to a point in the other zone
      routes her through the entrance/exit instead of off-screen (9h);
      automatic nectar foraging locks her to one flower with camera-follow/
      4x speed visibly firing (9i); a designated cell returns to neutral once
      fully emptied (9j). See `plans/archive/CHALLENGE1_SLICES_1-10.md` Slice 9 for each
      finding's detail.

### Challenge 2 Slice B + Slice D fixes
- [ ] Start Challenge 2 fresh: the Meadow button is visible from the opening
      stage, and the Foraging window button stays visible across every stage
      transition through 2.9 (Slice B). Select a death marker (drag-box and
      single-click, both zones): a green selection ring surrounds it, same
      as any other selectable object (Slice D). See
      `plans/archive/HANDS_ON_FIXES_2026-08-31.md` Slices B and D.

### UI-P-1, UI-P-3, UI-P-4, UI-P-7 (Dr Gallerin bubble, pre-run menu, info badges)
- [ ] Hover a long info-badge tooltip (settings window or elsewhere): it
      wraps into a multi-line box instead of spilling off-screen as one line
      (P-1). On the pre-run menu, neighbouring honeycomb tiles' borders read
      as one shared line, not a doubled seam, and clicking near a touching
      corner still selects the tile under the pointer (P-3); the left pane's
      text/hexagons sit a small buffer from the screen edge instead of pixel
      0 (P-4). Dr Gallerin's speech bubble text matches the rest of the
      HUD's size and follows the chosen typeface, sits to the left of his
      icon with a pointer connecting the two, and the command tray never
      renders underneath it at any tested width (P-7). See
      `plans/archive/UI_SHIPPED_2026-09-01.md` UI-P-1/3/4/7.

### UI-P-8 (summary panel cog, command tray width, resize overlap)
- [ ] With a bee selected whose identity label wraps to 2-3 lines, confirm
      the summary panel's cog stays aligned with the first line, not a lower
      one. At a normal window size, the command tray reads visibly wider
      (~20%) than before with the summary panel still filling the rest.
      Narrow the window toward `MIN_SUPPORTED_WIDTH` with several bees
      selected (so Job/Focus/Orders all show content): the tray's rows wrap
      onto further lines rather than the tray growing into the summary
      panel or Gallerin's space. Summary panel text (name/energy/activity/
      trait) reads the same size as command-panel button text. See
      `plans/archive/UI_SHIPPED_2026-09-01.md` UI-P-8.
