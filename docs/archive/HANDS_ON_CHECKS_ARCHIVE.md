# Hands-on check archive

Completed entries from `HANDS_ON_CHECKS.md`, moved here once Dave has
confirmed them (or a headless/diagnostic-log check has stood in for a
hands-on one) so the live checklist doesn't accumulate write-ups anyone
has to re-read. Newest first. See `git log` for the commit that shipped
each item if more detail is needed.

## 24 Aug 2026 -- second hands-on pass

- **Text now scales.** Confirmed working (`UI_BUGFIX_PLAN.md` Slices 1-2,
  the `theme_type_variation`/live-theme-apply migration).
- **Dark/light theme toggles.** Confirmed working (`UI_SETTINGS_PLAN.md`
  Slice 1, live theme apply).
- **Colour-blind labels appear for cells.** Confirmed working. The wider
  audit of every colour-only indicator beyond cells (`UI_BUGFIX_PLAN.md`
  Slice 3's "generalise beyond the nursery ring") is separate and still
  open -- not re-added here since it was never confirmed broken, just
  unconfirmed.
- **Settings-window sections are good.** Confirmed working
  (`UI_SETTINGS_PLAN.md` Slice 3, the Game Settings/Hive/Meadow
  reorganisation -- `git log` commit `a1ed2d0`).
- **Cell popup position is good.** Confirmed working, positioning only --
  the separate overlap-with-the-summary-panel issue is tracked as new work
  in `UI_BUGFIX_PLAN.md` Slice 6, not archived here.
- **Follow-bee works as expected.** `UI_BUGFIX_PLAN.md` Slice 8 (the
  hive/meadow view-change follow-bee-stops bug) is confirmed already
  working as of this check -- closed with no code change needed. Whatever
  fixed it happened as a side effect of other work; not worth chasing
  further.
- **Empty-crop critical recall.** Confirmed working -- a bee with an empty
  crop and low energy returned straight to the hive instead of continuing
  to search, matching `NEXTSTEPS.md`'s 24 Aug starvation-fix writeup
  (`bee_survival.gd::check_critical_recall`).
- **Forager-history save gap -- decision resolved.** Dave's answer: yes,
  worth its own slice. Turned into a scoped technical-work item in
  `DESIGN_BACKLOG.md` section 5 rather than left as an open question here.
- **Adaptive constancy ("unpinned forager gravitates toward whichever
  species is paying off").** Dave couldn't reproduce this by eye. Rather
  than a further hands-on attempt, this is already answered by the
  headless evidence `FORAGING_ECOLOGY_PLAN.md` Slice 7 recorded on 23 Aug:
  with `floral_constancy_on` off and `probabilistic_choice_on` +
  `adaptive_constancy_on` both on, flower_visits rose +18% (seed 12345,
  232 -> 274) versus the same run with confidence off, confirmed as the
  intended per-species-confidence effect rather than a regression. Closed
  on that evidence; no further hands-on check needed for this one.

## Earlier (22 Aug 2026)

- **Challenge-completion screen's actual play test.** Confirmed -- Challenge
  1 completes as intended.
- **Game model Slice 3's prerequisite cascade.** Confirmed -- both chains
  (Orientation flight/Scouting/Floral constancy/Auto-recruitment and
  Predators/Crab-spider suppression/Alarm pheromone) walk correctly both
  ways.
- **Bumble flight.** Confirmed -- the two-sine wander reads as bee-like.
- **Crab-spider second-round fixes.** Confirmed -- predator behaviour works
  as intended.
- **Foraging window (`FORAGING_ECOLOGY_PLAN.md` Slice 1).** Confirmed on a
  day-5 run with recruitment/scouting on -- panel numbers internally
  consistent against `DiagnosticLog`. (Superseded by a fresh "no data"
  report on 24 Aug -- see the live checklist, not re-opened here since
  the 22 Aug check itself was genuine at the time.)
- **Foraging ecology Slices 5 and 6 (local search, probabilistic
  choice).** Confirmed on a live playthrough -- heading-weighted choice and
  the SEARCHING spiral both read as intended. `forage_perception_radius`
  taken down 400 -> 320 off a `perf.gd` steer.
