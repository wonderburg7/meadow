# Next steps

Read this first in a new session, before anything else in CLAUDE.md.
Only the next 1-3 actions belong here -- full detail lives in the named
plan file, full history in `git log`.

## Next up

1. **UI polish batch -- top-right bar and small display fixes.** Several
   small, independent items Dave found in his 24 Aug hands-on pass, all
   mechanical once traced, all touching the same `hud.gd`/`ui_theme.gd`
   region -- worth one session rather than one slice each:
   - Tooltip text on hover for Colony/Nursery/Meadow-Hive
     (`hud.gd::_icon_button` never sets `tooltip_text`), and on the
     Foraging/Winter buttons (same gap).
   - Foraging button becomes an icon, not the word "Foraging" (matches
     the icon-only pattern the other top-bar buttons already use).
   - Speed buttons become right-pointing play-icon stacks (▶/▶▶/▶▶▶/▶▶▶▶
     for 1x/2x/4x/8x) instead of the numeral text.
   - Every top-right button (pause, speed, foraging, winter, cog, and the
     Colony/Nursery/Meadow-Hive icon buttons) becomes one consistent
     height and a bit bigger -- traced to two different `custom_minimum_size`
     constants in play today (26px in `hud.gd`'s plain buttons and the
     settings cog, 28px in `_icon_button`); pick one and apply it everywhere
     rather than guessing which is "right."
   - Font choice still doing nothing: not a code bug, just missing asset
     files -- add the three typeface files under `assets/fonts/`
     (`UI_PLAN.md` section 8 already named them: Atkinson Hyperlegible,
     OpenDyslexic, Pixel Operator, all OFL-licensed).
   - Hover text unreadable in any theme, in any panel: `ui_theme.gd`'s
     `_refresh_theme_resource` sets `font_color` but never
     `font_hover_color`/`font_pressed_color`/`font_focus_color`, so a
     hovered control falls back to Godot's engine-default colour instead
     of the active palette's. One `ui_theme.gd` fix covers every panel at
     once, plus finish the `hud.gd` hardcoded-light-text audit
     `UI_SETTINGS_PLAN.md` Slice 2 already flagged as remaining.
   - Scent-mark text on a flower's summary should disappear once the mark
     is no longer detectable (`hud.gd::_refresh_flower_summary` currently
     shows "Scent mark: Xs old" forever once a bee has ever marked it --
     should only show while `age < GameConfig.tarsal_marker_seconds`,
     matching `flower.gd::is_marked()`'s own definition of fresh).
   Full detail: `UI_SETTINGS_PLAN.md` Slice 4 (top-right bar: tooltips,
   icons, heights, font assets) and Slice 2 (hover colour), plus
   `UI_BUGFIX_PLAN.md`'s new Slice 14 (scent-mark visibility).
2. **Panel width consistency (supersedes the old Slice 6).** Root cause
   found: `hud.gd::_build_selection_panel`'s `PanelContainer` has no
   `custom_minimum_size.x` at all, so it (and the cell version of the same
   panel) sizes itself off whatever text the current bee/cell has -- which
   is both "the job panel is a different size for some bees" and the
   summary/command-tray overlap, from one cause. Dave's steer: give every
   summary panel and job/command panel a fixed width, driven by
   `ui_layout.gd` off the viewport, that only changes on a window resize.
   Also closes the cell-popup/summary overlap the same way. Full detail:
   `UI_BUGFIX_PLAN.md` Slice 6 (rewritten 24 Aug).
3. **Nursery zone removal + cell action-tray redesign (supersedes Slice
   9).** Dave's steer: drop the nursery-zone reservation mechanic for now
   (keep the Priority low/medium/high control, move it under a renamed
   "Nursery" section alongside what a cell raises); the bottom-centre cell
   popup becomes two columns -- Reserve for, Nursery -- with More…
   revealing Sealing and Emptying, one per column. This is a real feature
   removal, not just a layout change -- `is_nursery_cell()`/
   `nursery_priority` are read by the queen's own laying logic in
   `hive.gd`, not just the panel, so it touches more than `hud.gd`. Medium
   risk per `CLAUDE.md`'s routing table. Full detail: `UI_BUGFIX_PLAN.md`
   Slice 9 (rewritten 24 Aug).
4. **Meadow/Hive button hit-area bug -- Slice 7, corrected direction.**
   Dave's 24 Aug check found the opposite of the original 22 Aug guess:
   the smaller hit area happens *inside* a Challenge, not in a Scenario,
   and affects other top-right buttons too, not just Meadow/Hive. The
   original trace (a label-swap recalculation race) needs re-checking
   against this, not re-guessed -- `stage_gate.gd`'s Challenge-only
   visibility toggling is the new prime suspect. Give this its own
   investigation session, same as the old follow-bee slice got. Full
   detail: `UI_BUGFIX_PLAN.md` Slice 7 (revised 24 Aug).
5. **Foraging window: no data.** Confirmed working with real numbers on
   22 Aug, reported empty on 24 Aug. First check whether Auto
   scouting/Auto-recruitment were both off (the panel is correctly all-
   zero then, by design -- see `FORAGING_ECOLOGY_PLAN.md` Slice 1's
   results) before treating this as a regression from the Slice 6-9 work
   that touched `bee_foraging.gd` since. `HANDS_ON_CHECKS.md`.
6. **Forager-history save-gap slice -- approved, not designed yet.**
   Dave's answer: yes, worth its own slice. `avg_collection_rate`,
   `trips_scored`, `scout_*` fields and `hive.entrance_mentors` aren't in
   `save_game.gd`'s per-bee block today, so a save/load loses a forager's
   accumulated history. Needs an implementation-ready writeup (which
   fields, save-format version bump if any, old-save fallback) before
   building -- not started. See `DESIGN_BACKLOG.md` section 5.
7. **Challenge 1 revamp** -- start Bundle A (stage-array skeleton +
   trigger tag), then Bundle B (auto-mine sequence). Full plan:
   `CHALLENGE1_REVAMP_PLAN.md`; read "What already exists" first.
8. **Foraging ecology plan -- Slice 9 (proximity recruitment) is built,
   not yet swept.** `proximity_recruitment_on` (off by default, mutually
   exclusive with `auto_recruitment_on`), the indoor dance itself
   (`State.DANCING`, `hive.dance_eligible_mentors/seekers`,
   `BeeForaging.check_dance_proximity`/`_complete_dance`), and the
   circling visual are all in -- `source_checks.py`/`balance_tests.py`
   pass, `FUNCTION_MAP.md` regenerated. See `FORAGING_ECOLOGY_PLAN.md`'s
   24 Aug build note under the Slice 9 section for the full detail.
   **Not done:** this build session had no Godot available (no
   `mcp__godot__*` tools, no `godot`/`godot4` binary), so the spec's own
   task 7 (sweep `recruit_dance_radius`/`recruit_dance_seconds`/the two
   fuzz constants) and task 8 (the three-way A/B against
   `auto_recruitment_on`) haven't run -- there's no real results table
   yet, and the four new constants are reasoned defaults, not measured
   ones. `auto_recruitment_on` stays the shipped default until that
   comparison actually shows the new mechanism doing at least as well,
   per the spec's own rule. Needs a session with Godot (or Dave running
   `tools/run_scenario.py` himself) plus his hands-on check
   (`HANDS_ON_CHECKS.md`) before this can supersede the old mechanism.
   `tools/run_scenario.py`'s hardcoded `log_dir()` still assumes
   `config/name="Meadow"`; this sandbox's `project.godot` says "Meadow -
   Claude," so headless runs here still need the small `log_dir()`-
   monkeypatch driver script (not part of the repo).
9. **Handling experience and flower senescence: verify headlessly, not
   by eye.** Dave can't perceive either effect directly in play (flower
   handling is too fast; flowers carry no visible age tell) -- both
   should be confirmed through the diagnostic log and headless runs
   instead of a hands-on check, same treatment adaptive constancy already
   got (see `HANDS_ON_CHECKS_ARCHIVE.md`). Senescence has one single-seed
   headless run already (`FORAGING_ECOLOGY_PLAN.md` Slice 8, 24 Aug);
   handling experience's existing evidence is indirect (inferred from
   `stall_recoveries` rising, not a direct handling-time-per-visit
   measurement). A small follow-up -- log or print average handling
   seconds bucketed by `species_experience` visit count, plus a second
   senescence seed or two -- would make both a clean direct check rather
   than an inference. Reuses the same monkeypatch driver as task 8.

## Settled from this session, no action needed

- Follow-bee (old Slice 8) confirmed already working 24 Aug -- closed, no
  code change required.
- Settings-window sections, cell popup position, text scale, dark/light
  toggle, colour-blind cell labels and the empty-crop critical recall all
  confirmed working 24 Aug -- see `HANDS_ON_CHECKS_ARCHIVE.md`.
- Weighted flower choice and adaptive constancy should move from the
  Flowers settings category to Foraging, alongside `handling_experience_on`
  and `flower_senescence_on` -- these four toggles landed under Flowers
  after `UI_SETTINGS_PLAN.md` Slice 3's own content audit ran, so they were
  missed rather than deliberately left. Small follow-up inside whichever
  session next touches `debug_panel.gd`'s categories, not a slice of its
  own.
