# Hands-on check backlog

Flat checklist of shipped work that's only been checked as far as source
reading and automated tests can confirm. Nothing here needs more building
-- it needs Dave to actually play it. Tick items off (or delete them) as
they're checked; this file is meant to shrink, not accumulate write-ups.
See `git log` for the commit that shipped each item if more detail is
needed. Everything confirmed working, or superseded by a headless/
diagnostic-log check instead, moves to `docs/archive/HANDS_ON_CHECKS_ARCHIVE.md`
rather than sitting here -- that file doesn't need re-reading, this one does.

Split into two parts: **Checkable now** is built and playable -- go check
it. **Blocked** needs a fix or a slice to land first; re-checking these
now will just reconfirm the known bug, so leave them until `NEXTSTEPS.md`
says the fix has shipped.

## Checkable now

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
      ... flower" instead. See `FORAGING_ECOLOGY_PLAN.md`'s "Recent
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
      current campaign in `FORAGING_ECOLOGY_PLAN.md`.

### Proximity recruitment (Slice 9)
- [ ] Turn on Proximity recruitment (settings cog, Foraging section) --
      confirms Auto-recruitment turns itself off (they're mutually
      exclusive). Watch for a forager briefly circling another one
      indoors (near the comb, not at the door) rather than either bee
      ever waiting anywhere; check the selection panel reads "dancing
      to..."/"being shown a better patch" during it. See
      current `FORAGING_ECOLOGY_PLAN.md` campaign -- this has not been
      through a real headless sweep yet, so it is also the first real look at
      whether it feels right, not just a confirmation of numbers already
      checked.

## Blocked -- waiting on a fix or an unbuilt slice

### UI Plan slices 1-7 -- two items still open from the 24 Aug re-check
- [ ] Font choice still doesn't change -- **not a code bug**: the three
      non-default typefaces have no font files under `assets/fonts/` yet
      (`ui_theme.gd::_typeface_path`; the UI archive records the original
      asset decision). UI-A shipped without them by design (separate
      licensing/asset commit); blocked on sourcing the font files, not on
      any more code. Dave's
      25 Aug check: choosing a non-default font causes a visible pause,
      as if something's loading, but no on-screen text updates -- worth
      checking during the Slice 4 fix whether the theme-reload path is
      doing (and stalling on) wasted work even when the font file is
      missing, not just silently no-op'ing.
- [ ] Meadow/Hive (and other top-right) button hit areas are smaller
      inside a Challenge than in a Scenario -- corrected finding, opposite
      of the original guess. Needs its own investigation session before
      there's a fix to check. See UI-D in `UI_PLAN.md`.

### Panel sizing and overlap
- [ ] Summary panel (bee or cell) and command tray/job panel no longer
      overlap, and both hold a fixed width that doesn't change with how
      much text the current bee/cell has -- only a window resize should
      change it. Not built yet. See UI-B in `UI_PLAN.md`.

### Nursery zone removal and cell action-tray redesign
- [ ] Cell bottom-centre popup is two columns (Reserve for / Nursery) with
      More… revealing Sealing and Emptying, one per column; the nursery
      zone reservation mechanic itself is gone; Priority low/medium/high
      now lives under Nursery. Not built yet -- also touches queen
      egg-laying (`hive.gd`), so check laying still behaves sensibly with
      no zone cells at all, not just the panel layout. See UI-C in
      `UI_PLAN.md`.

### Recruitment and crab-spider fixes
- [ ] Recruitment competition fix (commit `103d716`) -- **not** re-checked;
      Dave is deferring this until the planned recruitment update lands
      (see `FORAGING_ECOLOGY_PLAN.md`), so don't chase it before then.
