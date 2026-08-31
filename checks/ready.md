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

### Save migrations and domain-event boundaries (efficiency Slice 5)
- [x] Confirmed 31 Aug: the epitaph toast and death marker on death, the
      day/season boundary update, and rain start/stop plus a Challenge
      stage clear/checkpoint all still fire correctly -- the signal
      refactor itself is clean.
- [ ] **Root cause confirmed 31 Aug, fix not yet applied:** saving then
      loading a save made many bees, including the queen, disappear --
      confirmed via live boot to be a `saving.gd:275` typed-array
      assignment throw that restores zero bees on every load, not a
      regression of this signal work. See
      `plans/now/hands-on-fixes-2026-08-31.md` Slice A1 -- fix queued
      ahead of Challenge 1 Slice 9.

### Challenge data/goal-registry extraction (efficiency Slice 4)
- [x] Confirmed 31 Aug: goal shelf text/progress still advances stage by
      stage exactly as before.
- [ ] **Not confirmed, found broken 31 Aug:** neither the rescue message
      ("Ahem. Field ecologists...") nor the recovery/checkpoint-restore
      message ("A brief ecological wobble...") appeared during a Challenge
      2 nectar collapse. Traced to `challenge_runner.gd`'s checkpoint-
      restore branch, not this extraction. See
      `plans/now/hands-on-fixes-2026-08-31.md` Slice A2.

### Challenge 1 Bundle G -- trim Challenge 2's opening (stages renumbered 2.1-2.9)
- [x] Confirmed 31 Aug: Challenge 2 opens with the queen (role Laying)
      plus one nectar Forager already out in the meadow, 5 cells (2
      nectar-full, 1 pollen-full, 2 empty), and the goal shelf showing
      stage 2.1's "watch the nectar stores fall, then recover them" text.
      Dave noted he intends to revisit the goal wording later -- a design
      preference, not a bug, not tracked as an issue here.
- [ ] **Not confirmed, found broken 31 Aug:** the Meadow view button never
      appears in Challenge 2 (missing `"meadow_view"` unlock key in every
      `STAGES_2` entry). See `plans/now/hands-on-fixes-2026-08-31.md`
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
      workers" while 1.14's reveals it. See `plans/now/challenge-1.md`
      Slices 4-5.
- [ ] **Not confirmed, found broken 31 Aug (second pass):** nothing ever
      stops the queen's automatic foraging once a stage's target amount is
      reached -- she keeps going toward the cell's real 200-unit capacity,
      well past the 75-unit pollen target. Assigning Forager/pollen also
      did not visibly start automatic pollen foraging in this run; two
      competing explanations traced in code, not yet told apart live.
      "Building the third cell reveals Laying" is most likely the correct
      1.14->1.15 transition, not a new bug -- but may be the already-known,
      unfixed 9d (current-role marker) instead; needs Dave to confirm which
      UI element he saw. See `plans/now/challenge-1.md` Slice 10, sections
      10c-10e.

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
- [ ] **Not confirmed, found broken 31 Aug (second pass):** right-clicking
      a flower during these stages permanently makes the queen a real
      Forager (she reads "Forager -- nectar" with no role ever manually
      assigned) and she keeps auto-foraging after every deposit from then
      on. Diagnosed as `Bee.command_collect_from()` calling
      `set_role(Role.FORAGER)` unconditionally, with no Challenge-aware
      lock -- a separate, more direct cause than Slice 9a's own
      `role_restricted_to` finding, and not fixed by 9a alone. See
      `plans/now/challenge-1.md` Slice 10, sections 10a-10b.

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
- [ ] **Confirmed 31 Aug why this can't be watched directly:** foragers
      self-refuel to full at any flower with nectar (`drink_at_flower`)
      well before the calculated reserve is ever approached in an ordinary
      meadow, and the check is skipped outright while she's carrying any
      nectar. This is very likely working as designed (an emergency-only
      path for sparse/long-range conditions), but there is currently no
      counter for it either, so it cannot be confirmed by number over a
      long run. See `plans/active/foraging-evidence.md` Slice 3 for the
      proposed counter and a scenario likely to actually trigger it.

### AI playtest harness (slices 1-7, the headless action driver)
- [ ] Review all seven slices end to end -- see `git log` for the
      slice-by-slice detail.

### Foraging window
- [x] Confirmed 31 Aug (second time): the panel shows real numbers again.
- [ ] **Not confirmed, found broken 31 Aug:** Orientation flight reads 0
      even with the toggle showing as triggered. Traced to a genuine
      mismatch, not a display bug: `orientation_flight_on` is
      `scouting_on`'s settings-prerequisite (so the cascade lights it up
      too), but the two are runtime alternatives (`if scouting_on ... elif
      orientation_flight_on`), so the orientation-flight counter can never
      move while scouting is on. Needs Dave's steer on which of three
      options to take -- see `plans/active/foraging-evidence.md` Slice 1.

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
