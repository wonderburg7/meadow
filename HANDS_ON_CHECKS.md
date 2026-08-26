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
      correctly all-zero then) before treating this as a regression. See
      `FORAGING_ECOLOGY_PLAN.md` Slice 1.

### Proximity recruitment (Slice 9)
- [ ] Turn on Proximity recruitment (settings cog, Foraging section) --
      confirms Auto-recruitment turns itself off (they're mutually
      exclusive). Watch for a forager briefly circling another one
      indoors (near the comb, not at the door) rather than either bee
      ever waiting anywhere; check the selection panel reads "dancing
      to..."/"being shown a better patch" during it. See
      `FORAGING_ECOLOGY_PLAN.md`'s Slice 9 build note -- this hasn't been
      through a real headless sweep yet (no Godot available in the build
      session), so this is also the first real look at whether it feels
      right, not just a confirmation of numbers already checked.

## Blocked -- waiting on a fix or an unbuilt slice

### UI Plan slices 1-7 -- two items still open from the 24 Aug re-check
- [ ] Font choice still doesn't change -- **not a code bug**: the three
      non-default typefaces have no font files under `assets/fonts/` yet
      (`ui_theme.gd::_typeface_path`, `UI_PLAN.md` section 8 already flagged
      this as "a concrete, small task"). Blocked on `UI_SETTINGS_PLAN.md`
      Slice 4 (part of the UI polish batch, `NEXTSTEPS.md` item 1). Dave's
      25 Aug check: choosing a non-default font causes a visible pause,
      as if something's loading, but no on-screen text updates -- worth
      checking during the Slice 4 fix whether the theme-reload path is
      doing (and stalling on) wasted work even when the font file is
      missing, not just silently no-op'ing.
- [ ] Meadow/Hive (and other top-right) button hit areas are smaller
      inside a Challenge than in a Scenario -- corrected finding, opposite
      of the original guess. Needs its own investigation session before
      there's a fix to check. See `UI_BUGFIX_PLAN.md` Slice 7 (revised 24
      Aug) and `NEXTSTEPS.md` item 4.

### Panel sizing and overlap
- [ ] Summary panel (bee or cell) and command tray/job panel no longer
      overlap, and both hold a fixed width that doesn't change with how
      much text the current bee/cell has -- only a window resize should
      change it. Not built yet. See `UI_BUGFIX_PLAN.md` Slice 6 (revised
      24 Aug) and `NEXTSTEPS.md` item 2.

### Nursery zone removal and cell action-tray redesign
- [ ] Cell bottom-centre popup is two columns (Reserve for / Nursery) with
      More… revealing Sealing and Emptying, one per column; the nursery
      zone reservation mechanic itself is gone; Priority low/medium/high
      now lives under Nursery. Not built yet -- also touches queen
      egg-laying (`hive.gd`), so check laying still behaves sensibly with
      no zone cells at all, not just the panel layout. See
      `UI_BUGFIX_PLAN.md` Slice 9 (rewritten 24 Aug) and `NEXTSTEPS.md`
      item 3.

### Recruitment and crab-spider fixes
- [ ] Recruitment competition fix (commit `103d716`) -- **not** re-checked;
      Dave is deferring this until the planned recruitment update lands
      (see `FORAGING_ECOLOGY_PLAN.md`), so don't chase it before then.
