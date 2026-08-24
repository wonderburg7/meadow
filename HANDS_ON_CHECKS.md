# Hands-on check backlog

Flat checklist of shipped work that's only been checked as far as source
reading and automated tests can confirm. Nothing here needs more building
-- it needs Dave to actually play it. Tick items off (or delete them) as
they're checked; this file is meant to shrink, not accumulate write-ups.
See `git log` for the commit that shipped each item if more detail is
needed. Everything confirmed working, or superseded by a headless/
diagnostic-log check instead, moves to `docs/archive/HANDS_ON_CHECKS_ARCHIVE.md`
rather than sitting here -- that file doesn't need re-reading, this one does.

## UI Plan slices 1-7 -- 24 Aug re-check against `UI_BUGFIX_PLAN.md`
Dave re-checked the 22 Aug "found broken" list item by item. Text scale,
dark/light toggle, colour-blind labels (cells), settings-window sections,
cell popup position and follow-bee-on-view-change all now confirmed working
-- see the archive for detail. Two items are still open:
- [ ] Font choice still doesn't change -- **not a code bug**: the three
      non-default typefaces have no font files under `assets/fonts/` yet
      (`ui_theme.gd::_typeface_path`, `UI_PLAN.md` section 8 already flagged
      this as "a concrete, small task"). Bundled into the UI polish batch --
      see `UI_SETTINGS_PLAN.md` Slice 4.
- [ ] Meadow/Hive (and other top-right) button hit areas are smaller inside
      a Challenge than in a Scenario -- corrected finding, opposite of the
      original guess. See `UI_BUGFIX_PLAN.md` Slice 7 (revised 24 Aug).

## Panel sizing and overlap
- [ ] Summary panel (bee or cell) and command tray/job panel no longer
      overlap, and both hold a fixed width that doesn't change with how
      much text the current bee/cell has -- only a window resize should
      change it. See `UI_BUGFIX_PLAN.md` Slice 6 (revised 24 Aug, folds in
      the cell-popup/summary overlap too). Not built yet.

## Nursery zone removal and cell action-tray redesign
- [ ] Cell bottom-centre popup is two columns (Reserve for / Nursery) with
      More… revealing Sealing and Emptying, one per column; the nursery
      zone reservation mechanic itself is gone; Priority low/medium/high
      now lives under Nursery. See `UI_BUGFIX_PLAN.md` Slice 9 (rewritten
      24 Aug). Not built yet -- also touches queen egg-laying (`hive.gd`),
      so check laying still behaves sensibly with no zone cells at all,
      not just the panel layout.

## Foraging window
- [ ] Foraging window (**G**) showed real numbers when Dave checked it 22
      Aug (see archive) but on 24 Aug showed no data at all -- check
      whether Auto scouting/Auto-recruitment were both off (the panel is
      correctly all-zero then) before treating this as a regression. See
      `FORAGING_ECOLOGY_PLAN.md` Slice 1.

## AI playtest harness (slices 1-7, the headless action driver)
- [ ] Review all seven slices end to end -- see `git log` for the
      slice-by-slice detail.

## Recruitment and crab-spider fixes
- [ ] Recruitment competition fix (commit `103d716`) -- **not** re-checked;
      Dave is deferring this until the planned recruitment update lands
      (see `FORAGING_ECOLOGY_PLAN.md`), so don't chase it before then.
