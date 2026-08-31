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
- [ ] **Not confirmed, found broken 31 Aug:** saving then loading a save
      made many bees, including the queen, disappear. Diagnosed as a
      likely missing per-entry error boundary in `saving.gd::_restore_bees()`,
      not a regression of this signal work. See
      `plans/now/hands-on-fixes-2026-08-31.md` Slice A -- fix queued ahead
      of Challenge 1 Slice 9.

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
