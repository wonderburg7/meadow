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

Last pass: **2 Sep 2026**. Fifteen entries confirmed and archived; the
findings that came out of that pass are slices in their owning plans, not
checks here.

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

### Challenge 1 Bundle D -- meadow arrival, manual foraging (stages 1.6-1.10)
**Slices 11 and 12 landed 2-3 Sep 2026; this entry is ready to re-run.**
Dave's 2 Sep run found the queen still foraging on her own through these
stages -- she flew to the next flower by herself after working one dry, and
walked back out to forage after the 1.10 deposit. Slice 11 guarded those
three transitions; Slice 12 then replaced `manual_deposit_pending` with one
`player_driven` flag and routed all thirteen of the file's autonomous
transitions through `bee_foraging.gd::autonomous_state()`
(`plans/now/challenge-1.md` Slices 11 and 12).

- [ ] **Slice 12 acceptance (a refactor, so this is the regression check):**
      re-run the Slice 11 acceptance box below and confirm 1.6-1.10 behave
      exactly as Slice 11 left them -- no change is the passing result. Two
      places Slice 12 newly guards, worth a look while you are there: if it
      rains during 1.6-1.10 the queen must stay put rather than flying home
      or sheltering, and if a flower she is working disappears she must stay
      where she is rather than seeking another. Outside a Challenge nothing
      should differ at all: check a Scenario forager still forages, returns,
      deposits and leaves the hive on her own.

- [ ] Play Challenge 1 through to the meadow: exit the hive (right-click
      the marked doorway), tour the three marked meadow points, gather
      from two flowers via right-click (`Bee.command_collect_from`), then
      right-click the hive's meadow-side marker to send the queen home.
      Once she arrives, right-click the wax cell to deposit the load.
      Confirm each stage's goal actually advances, automatic movement,
      collection and deposit never clear a manual stage, and the queen
      never gets auto-assigned a role she was not manually given.
- [ ] **Slice 11 acceptance, the part 10a/10g did not cover:** at 1.8,
      right-click a flower and let the queen work it *dry* before her crop
      is full -- she must stay put at that flower, not set off for another
      one. At 1.10, after the manual deposit she must stay inside the hive
      doing nothing, not walk back out. Throughout 1.6-1.10 the Job column
      must keep reading "Laying" -- no "Forager" anywhere.
- [ ] **Slice 11 hand-over, the blocker itself:** on reaching 1.11 the Job
      column must offer "Change to..." with Forager in it. If it is empty,
      the queen is still working as a Forager and one of the three guards
      did not hold -- report which stage she started foraging at.
- [ ] **Fix applied 1 Sep (10f), not yet confirmed live:** 1.8/1.9 now
      read a dedicated `ChallengeRunner._c1_queen_collections` counter
      rather than `Bee.flower_cooldowns.size()`, which also grew on a
      rejection. Confirm at 1.8: right-click a visibly near-empty flower
      twice and the stage should **not** clear; then collect from one real
      flower and it should. See `plans/archive/CHALLENGE1_SLICES_1-10.md`
      Slice 10, section 10f.

### Challenge 1 Bundle E -- automate nectar, then pollen (stages 1.11-1.14)
**Reachable again as of Slice 11 (2 Sep 2026).** Dave's 2 Sep run stopped
at the 1.10 -> 1.11 hand-over: the queen was already auto-foraging, so the
Job column offered no Forager to switch her to and the run could not
continue. Slice 11 removed that cause, so run this whole entry after the
Bundle D hand-over check above passes.

- [ ] Play Challenge 1 from the meadow-harvest deposit onward: assign the
      queen Forager/nectar and let her fill the nectar cell (1.11 -- runs
      at 2x her normal rate and stops on her own once it reads full), use
      her "Build cell" button for a second cell (1.12), switch her to
      Forager/pollen until its cell holds 75 (1.13, also 2x rate), then
      build a third cell (1.14). Confirm each stage's goal advances, the
      second and third cells land beside the first rather than failing,
      and 1.13's Gallerin copy withholds "pollen makes new workers" while
      1.14's reveals it. See `plans/archive/CHALLENGE1_SLICES_1-10.md`
      Slices 4-5.
- [ ] **Fix applied 1 Sep (10c), not yet confirmed live:** stage 1.13 now
      runs the same `"freeze_bee:queen"` on_exit effect 1.11 already ships,
      so automatic pollen foraging stops at the 75-unit target rather than
      running on toward the cell's real 200-unit capacity. Confirm at 1.13:
      the stage advances right at 75, and she is idle immediately after.
      See `plans/archive/CHALLENGE1_SLICES_1-10.md` Slice 10, section 10c.
- [ ] **Fix applied 1 Sep (10d), not yet confirmed live:** the "Doing"
      (nectar/pollen) row now keys off whichever role the queen is
      actively working, not just her primary role, and `set_focus()`
      accepts the change while she works Forager as a backup role. Confirm
      at 1.13: select the queen while she is auto-foraging nectar via her
      backup role, open the Doing row, and pick Pollen -- it should render,
      take, and she should switch to pollen collection. See
      `plans/archive/CHALLENGE1_SLICES_1-10.md` Slice 10, section 10d.

### Challenge 1 Slice 9 fixes (9a-9j)
- [ ] Re-run Slice 7's full acceptance playthrough (`plans/now/challenge-1.md`
      Slice 7) end to end, **after Slice 11 lands** -- the 2 Sep attempt
      could not get past 1.10. In particular: the queen's backup role no
      longer lets her auto-build/auto-forage before a stage unlocks it
      (9a); "Build cell" stays visible whenever a fourth cell might be
      needed (9b); hatch options never offer "Default" (9c); the Job
      column's current-role marker respects `allowed_role_keys` (9d);
      "Raise a gyne" is hidden until its stage gate (9e); Dr Gallerin's
      hint text says "any flower" not "marked flower" (9f); a manually-
      placed second cell renders (9g); commanding a bee to a point in the
      other zone routes her through the entrance/exit (9h); automatic
      nectar foraging locks her to one flower with camera-follow/4x speed
      visibly firing (9i); a designated cell returns to neutral once fully
      emptied (9j). See `plans/archive/CHALLENGE1_SLICES_1-10.md` Slice 9.

### Safe forager return reserve (recommendation Slice 4)
- [ ] Foragers turn for home on a calculated return-energy estimate
      (distance x route factor x flight/upkeep rate, plus a safety margin)
      instead of a fixed 20% threshold -- watch a run with foragers ranging
      far from the hive and confirm they still turn back with a sensible
      margin rather than cutting it fine or turning back too early on
      short trips.
- [ ] **Counter added 1 Sep (X1), still open after the 2 Sep pass.** Dave
      reported "Empty returns increases when it rains" -- that is the
      *Empty returns* row in the overview block, which counts trips that
      came home with nothing, and rising in rain is expected (rain waters
      nectar down and grounds foragers). The row this check is about is
      **Forager returns triggered**, in the recruitment block lower down
      the same panel. Confirm that row specifically: it should read zero in
      an ordinary meadow and rise during a sparse/long-range or rainy run.
      See `plans/active/foraging-evidence.md` Slice 3.

### Nectar/pollen recharge reads as stuck (hands-on-fixes Slice C)
- [ ] **Fix applied 31 Aug, not yet confirmed live (C1/C2 only -- C3 is
      confirmed and archived).** Click a flower's detail panel and confirm
      the shown "+_/s" rate now reflects season/senescence (reads ~0.00/s
      when out of season or senescent, instead of the old nominal rate
      that never matched what was actually happening). Watch a flower
      under forager pressure near the "1" floor and confirm it no longer
      looks pinned -- `nearest_flower()` now skips anything below
      `GameConfig.min_worthwhile_amount`, not just `<= 0.0`. See
      `plans/archive/HANDS_ON_FIXES_2026-08-31.md` Slice C1-C2.

### Hive comb visual alignment (Slices 1-3)
- [x] Confirmed 2 Sep: cell art, above-centre rows and wide-comb routing
      are all consistent after a save and load, and the settings placement
      (Cell art, Show cell contents text, Sprite-aligned hex grid and
      Direction-even hex speed under Appearance) is right. Archived.
- [ ] **Found broken 2 Sep:** cell highlight borders do not follow the
      shape of the cell sprites. Only `selection_ring` traces the cup
      silhouette; the base outline, the designation ring and the nursery
      zone glow/halo still use the flat hex and cut through the sprite's
      raised back wall. Fix is `plans/now/hive-comb.md` Slice 8; re-check
      after it lands, with cell art on and off, against all four rings.

### Proximity recruitment (Slice 9)
- [x] Confirmed 2 Sep, plus X2's headless evidence run: matches do happen.
      Archived. The open question is that a player cannot see one happen --
      that is `plans/active/foraging-evidence.md` Slice 4, a feature slice,
      not a check.
- [ ] Once Slice 4's highlight toggle ships: turn on Proximity recruitment
      and the new highlight, and confirm you can find a dancing pair on
      screen inside one in-game day, that the mentor and the seeker are
      distinguishable from each other, and that the selection panel reads
      "dancing to..."/"being shown a better patch" for them.

### Foraging window
- [x] Confirmed 31 Aug (second time): the panel shows real numbers again.
- [x] Confirmed 2 Sep: Slice 1's orientation-flight/auto-scouting mutual
      exclusion works both ways and the orientation-flight counter moves.
      Archived.

### AI playtest harness (slices 1-7, the headless action driver)
- [ ] Review all seven slices end to end -- see `git log` for the
      slice-by-slice detail.

### Command tray placement (UI-R-1)
- [ ] Select a bee so the command tray shows, then look at the bottom row at
      1920, 1280 and 800 wide. The whole tray should be on screen, its left
      edge one 16px gap right of the summary panel, its bottom level with the
      panel's, and its right edge clear of Dr Gallerin -- check with a speech
      bubble showing and with none. Resize the window while the tray is
      visible: it should move and re-cap, not just re-cap. Narrowing should
      still wrap the Job/Focus/Orders groups onto further rows rather than
      growing the tray into either neighbour (UI-P-8's own acceptance).
- [ ] At 800 wide specifically, the summary panel is now noticeably narrower
      than before (139px against 268px). That is the deliberate trade: below
      about 1150px the tray hits its 200px floor, and the slice chose "never
      cross into Gallerin's reserve" over "keep the panel wide". Say if the
      panel is too cramped to read there -- the alternative is letting the
      tray overlap Gallerin at the very narrow end instead.

### Warning banner: one throttle at the channel (C2, UI-Q-1/UI-Q-2)
Moved to `checks/blocked.md` on 2 Sep -- there is no way to trigger two
throttled events on demand, so this check cannot currently produce
evidence. Its unblocker is `plans/now/ui.md` UI-R-3.
