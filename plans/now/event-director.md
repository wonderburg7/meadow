# Event director -- the run's calendar in one place, then the alpha's pressures

<!-- CONTEXT: plan | LAYER: immediate-task -->
Status: active | Owner: Dave / Claude Code | Next: EV-0 -- the Calendar and events settings group, and winter a week later, gated on PN-11 (SG-3, HS-2 and PP-11 landed 1 Nov 2026) | Dependency: EV-0 runs before T2-7b (`plans/now/tier-two.md`) and PP-10 (`plans/now/pollination.md`; Dave 1 Nov 2026 and 5 Nov 2026, product review D4); the director's events (EV-1 onward, not yet written) wait for CQ-R2 (`plans/now/code-health.md`) and the alpha chain's save slices ending with ED-3 (`plans/now/difficulty.md`) | Verified: 2026-11-01

## Objective

Give Dave one place to see and edit every timing in a run (day length,
seasons, winter, crises, director slots), move winter about a week later,
then build the small event director agreed in
`plans/design/event-director.md`. That file holds the design and its
decisions; this plan holds only slices.

## Current state

Timing values are scattered `GameConfig` fields: `seconds_per_day` (200),
`winter_countdown_days` (15, slider max 15) and `winter_length_days` (10)
in days; the first crisis window (`first_crisis_window_open` 1080,
`first_crisis_window_close` 1500, `first_crisis_warning_lead` 120) in
seconds. Winter runs days 31 to 41: `season_length_days` (30) less
`winter_countdown_days` opens the countdown on day 16
(`season.gd::_winter_countdown_day`). No director exists;
FC-2's first crisis lives in `scripts/main.gd`, "the first crisis".

## Open slices

| Slice | What it does | Files it owns | Startable | Level |
| --- | --- | --- | --- | --- |
| EV-0 | one Calendar and events settings group in days, a read-only timeline row, and winter about a week later set by simulation | `scripts/game_config.gd`, `scripts/settings_catalogue.gd`, `scripts/main.gd`, `scripts/season.gd`, tests | no -- after PN-11 (re-pins the first crisis to days 12-15, on `claude/dave-hands-on-checks-784f2a`); SG-3, HS-2 and PP-11 landed 1 Nov 2026 | medium |

**Dependencies.** EV-0 follows PN-11 (SG-3, HS-2 and PP-11 landed 1 Nov
2026), and precedes
T2-7b and then PP-10, so both price the route once, on the new calendar
(Dave, 1 Nov 2026; T2-7b's place, 5 Nov 2026). The director's event slices follow CQ-R2, which creates
`event_director.gd` (new, in `scripts/`) (design decision 2), and ED-3.
Each EV slice adds a kind to the shared cycle (design decision 15), not a
cycle of its own. The spider surge and the forage dearth both need "one
busy patch", and no patch exists on the world side today (a patch is only
a bee's remembered position, `bee.gd::known_patches`): whichever of the two
is written first creates one patch query in `event_director.gd` over
`main.gd::flower_grid` (centre, radius, the flowers inside), and the other
reuses it (`docs/architecture-review-2026-11-04.md` F2).

**Read:** this plan's EV-0 section and `plans/design/event-director.md`
decisions 7, 8 and 10.

## EV-0 -- one Calendar and events settings group, and winter a week later

Level: medium -- claude-sonnet-5-5 at medium effort.

**True now.** Dave (1 Nov 2026) expects to keep changing timings, day
lengths and season lengths, and finds winter comes too fast. The values sit
in several settings groups, and the first crisis window is in seconds, so a
change to `seconds_per_day` silently moves it to a different day.

**When done:**

1. One settings-window group, "Calendar and events", holds every timing
   value: `seconds_per_day`, `season_length_days`, `winter_countdown_days`, `winter_length_days` and the first crisis
   window and lead. The first crisis window becomes days
   (`first_crisis_window_open_day`, `first_crisis_window_close_day`) read
   through `seconds_per_day`; at the default day length it produces exactly
   the seconds PN-11 pinned, so FC-2's scenarios pass unchanged.
2. A read-only timeline row in that group shows the run the values make:
   first-crisis window, winter start and end, and the post-winter mating
   window, as day numbers.
3. Winter starts about a week later than today (intent: around day 38
   instead of 31, Dave 1 Nov 2026). The exact value is set by running
   `python tools/pacing_gates.py` over three seeds before and after; the
   before/after table is recorded in this section. `winter_countdown_days`'
   slider maximum widens if the chosen value needs it.

**Invariants.** No director, no new event, no save field: a run's dates
(`Session.winter_starts_day` and friends) are already state of the run, so
an old save keeps its saved winter. Prices are PP-10's job, not this
slice's. FC-2's behaviour at the default day length is unchanged.

**Open decisions:** none.

```queue-gated
**[Claude] EV-0 -- one Calendar and events settings group, and winter a week later**
- Plan: `plans/now/event-director.md` -- "EV-0 -- one Calendar and events settings group, and winter a week later"
- Files: `scripts/game_config.gd`, `scripts/settings_catalogue.gd`, `scripts/main.gd`, `scripts/season.gd`, `tests/test_ev0_calendar.py`
- Check: `python -m unittest tests.test_ev0_calendar tests.test_fc2_first_crisis` passes (every timing value sits in the "Calendar and events" group; the first crisis window is in days and gives PN-11's seconds at the default day length; the timeline row names the crisis window, winter and the mating window); over 3 seeds `python tools/pacing_gates.py` reports winter entered about a week later than before, with the before/after table recorded in the EV-0 section; `.\tools\verify.ps1` is green
- Proof: `absent: scripts/game_config.gd :: first_crisis_window_open_day`
- Next after: T2-7b -- the tier-2 price sweep, before PP-10 prices the gyne route
```
