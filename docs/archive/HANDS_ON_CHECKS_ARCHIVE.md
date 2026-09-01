# Hands-on check archive

Completed entries from `HANDS_ON_CHECKS.md`, moved here once Dave has
confirmed them (or a headless/diagnostic-log check has stood in for a
hands-on one) so the live checklist doesn't accumulate write-ups anyone
has to re-read. Newest first. See `git log` for the commit that shipped
each item if more detail is needed.

## 31 Aug 2026 -- second hands-on pass

- **Same-flower ping-pong / thin-patch escape (foraging).** Confirmed
  working -- a forager worked into an isolated flower correctly switches to
  "flying a search loop" once nothing worthwhile is left to try, rather than
  sitting on the same flower indefinitely. See
  `plans/active/foraging-evidence.md`.
- The Foraging window's own numbers were reconfirmed the same pass (its
  Orientation flight sub-finding was not, and stays open in
  `checks/ready.md` alongside the confirmed line, not archived here, since
  the heading as a whole isn't done).
- Five further items from the same pass were found broken, not confirmed --
  see `plans/now/challenge-1.md` Slice 10 (Challenge 1 Bundle D/E),
  `plans/now/hive-comb.md` Slice 6 (cell rendering), and
  `plans/active/foraging-evidence.md` Slices 1-3 (orientation flight,
  proximity recruitment, safe forager return reserve), and the updated
  entries left open in `checks/ready.md`.

## 31 Aug 2026 -- hands-on pass

- **Cell/colony dirty-index refactor (efficiency Slice 1).** Confirmed
  working -- `hive.gd`'s cell-content buckets and the comb/nursery panel's
  free/brood/gyne/hungry counts update the moment they should.
- **HUD popups bound to revisions, not frames (efficiency Slice 2).**
  Confirmed working -- cell popup, flower summary and selection panel
  refresh immediately on a real change, including the activity line
  updating instantly on a tray order.
- **Crab spiders, full re-check.** Confirmed working -- the tunable attack-
  success setting, the escaped-bee flower cooldown, the attack-flash ring
  and the magenta dev marker all behave as `plans/archive/CRAB_SPIDER_PLAN.md`
  Bundle 5 intended.
- **Challenge 1 Bundle F (laying, backup nursing, the first daughter).**
  Confirmed working in full -- automatic nursing backup, the new worker's
  hatch behaviour (circling the queen, no dart for the exit), the queen not
  re-laying mid-beat, her role panel, the farewell speech bubble placement,
  and all three completion-window options.
- Two items from the same pass were found broken, not confirmed --
  see `plans/archive/HANDS_ON_FIXES_2026-08-31.md` (Slices A/B/C/D) and the
  updated entries left open in `checks/ready.md` for efficiency Slices 4/5
  and Challenge 1 Bundle G.

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
