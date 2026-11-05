# Event director -- the run's calendar in one place, then the alpha's pressures

<!-- CONTEXT: plan | LAYER: immediate-task -->
Status: active | Owner: Dave / Claude Code | Next: EV-0b -- one calendar, startable now; then EV-0 -- the Calendar and events settings group and a 35-day season, after PN-11 and EV-0b | Dependency: EV-0 runs before PP-10 (`plans/now/pollination.md`, Dave 1 Nov 2026); the director's events (EV-1 onward, not yet written) wait for CQ-R2 (`plans/now/code-health.md`), which follows ED-3 (`plans/now/difficulty.md`) alone (Dave, 5 Nov 2026) | Verified: 2026-11-05

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
| EV-0b | one calendar: day numbers and the season's fraction from one place | `scripts/run_calendar.gd` (new), `scripts/flower.gd`, `scripts/flower_species.gd`, `scripts/world_building.gd`, tests | yes | medium |
| EV-0 | one Calendar and events settings group in days, a read-only timeline row read from `RunCalendar`, and winter on day 36 (a 35-day season) | `scripts/game_config.gd`, `scripts/settings_catalogue.gd`, `scripts/main.gd`, `scripts/season.gd`, `scripts/run_calendar.gd`, tests | no -- after PN-11 (re-pins the first crisis to days 12-15) and EV-0b | medium |

**Dependencies.** EV-0 follows PN-11 and EV-0b, and precedes PP-10, so
PP-10 checks the route once, on the new calendar (Dave, 1 Nov 2026). The
director's event slices follow CQ-R2, which creates `event_director.gd`
(new, in `scripts/`) (design decision 2) and follows ED-3 alone (Dave,
5 Nov 2026, plan review: not RR-12 or SP-8a); they read their days from
`RunCalendar`.
Each EV slice adds a kind to the shared cycle (design decision 15), not a
cycle of its own. The spider surge and the forage dearth both need "one
busy patch", and no patch exists on the world side today (a patch is only
a bee's remembered position, `bee.gd::known_patches`): whichever of the two
is written first creates one patch query in `event_director.gd` over
`main.gd::flower_grid` (centre, radius, the flowers inside), and the other
reuses it (`docs/architecture-review-2026-11-04.md` F2).

**Read:** EV-0 reads its own section and `plans/design/event-director.md`
decisions 7, 8 and 10; EV-0b reads its own section only.

## EV-0 -- one Calendar and events settings group, and winter a week later

Level: medium -- claude-sonnet-5-5 at medium effort.

**True now.** Dave (1 Nov 2026) expects to keep changing timings, day
lengths and season lengths, and finds winter comes too fast. The values sit
in several settings groups, and the first crisis window is in seconds, so a
change to `seconds_per_day` silently moves it to a different day.

**Timings stay adaptable (Dave, 5 Nov 2026, plan review).** Day lengths,
season lengths and the events on them will change again when timings are
reviewed. Every day this slice shows or sets is derived from the values it
depends on through `RunCalendar` (EV-0b), never copied, so changing one value
moves everything that follows from it.

**When done:**

1. One settings-window group, "Calendar and events", holds every timing
   value: `seconds_per_day`, `season_length_days`, `winter_countdown_days`, `winter_length_days`, `rain_free_days` and the first crisis
   window and lead. The first crisis window becomes days
   (`first_crisis_window_open_day`, `first_crisis_window_close_day`) read
   through `seconds_per_day`; at the default day length it produces exactly
   the seconds PN-11 pinned, so FC-2's scenarios pass unchanged.
2. A read-only timeline row in that group shows the run the values make:
   first-crisis window, winter start and end, and the post-winter mating
   window, as day numbers. `RunCalendar` gains `countdown_open_day`,
   `winter_start_day` and `winter_end_day` for a year and the mating window's
   days (from `season.gd`'s `MATING_WINDOW_START` and `MATING_WINDOW_END`);
   the row, `season.gd::_winter_countdown_day` and `main.gd`'s day counter all
   call them instead of their own arithmetic.
3. Winter starts later (Dave, 1 Nov 2026: winter comes too fast):
   `season_length_days` goes from 30 to 35, so winter arrives on day 36
   instead of 31, and `winter_countdown_days` stays 15, so the countdown opens
   on day 21 (Dave, 5 Nov 2026). The countdown opens at `season_length_days -
   winter_countdown_days` and winter arrives that many days later, so raising
   the countdown alone would only open it earlier. Both are drafts (product
   review D5): no before/after tuning. One `python tools/pacing_gates.py` run
   after the change confirms the order only -- every colony still enters and
   survives winter -- and its per-seed block is recorded here. Bloom windows
   are fractions of the season, so they stretch with it.

**Invariants.** No director, no new event, no save field: a run's dates
(`Session.winter_starts_day` and friends) are already state of the run, and
`season_length_days` is saved with the run, so an old save keeps its 30-day
season and its saved winter. Prices are PP-10's job, not this
slice's. FC-2's behaviour at the default day length is unchanged.

**Open decisions:** none.

```queue-gated
**[Claude] EV-0 -- one Calendar and events settings group, and winter a week later**
- Plan: `plans/now/event-director.md` -- "EV-0 -- one Calendar and events settings group, and winter a week later"
- Files: `scripts/game_config.gd`, `scripts/settings_catalogue.gd`, `scripts/main.gd`, `scripts/season.gd`, `scripts/run_calendar.gd`, `tests/test_ev0_calendar.py`
- Check: `python -m unittest tests.test_ev0_calendar tests.test_fc2_first_crisis` passes (every timing value, `rain_free_days` included, sits in the "Calendar and events" group; the first crisis window is in days and gives PN-11's seconds at the default day length; at the defaults winter arrives on day 36 and the timeline row names the crisis window, winter and the mating window; with `season_length_days` or `seconds_per_day` changed, the row's days and the game's own countdown day move together); one `python tools/pacing_gates.py` run over 3 seeds shows every colony entering and surviving winter, its per-seed block recorded in the EV-0 section; `.\tools\verify.ps1` is green
- Proof: `absent: scripts/game_config.gd :: first_crisis_window_open_day`
- Next after: PP-10 -- the sweep prices the route so Gyne rearing is first affordable after the first winter
```

## EV-0b -- one calendar: day numbers and the season's fraction from one place

Level: medium. One new static script and three callers moved onto it; no
behaviour change.

**True now.** The day number and the fraction of the playable season are
worked out three times: `flower.gd::season_fraction`,
`flower_species.gd::year_fraction_now` (whose comment says it duplicates the
first) and `world_building.gd`'s flower birth fraction (near line 246), each
from `Session.sim_time`, `GameConfig.seconds_per_day`,
`GameConfig.season_length_days` and `Session.year_days()`. A change to how
the calendar works has to be made in every copy.

**Why (Dave, 5 Nov 2026, plan review).** Every timing is a draft and will
change when timings are reviewed, day and season lengths included, so the
relationships between timings are derived in one place, never copied. Bloom
curves must stay quick and cheap to change as species are added and moved to
their real peak. They already are data: each species' `season_start` and
`season_end` in `flower_species.gd`'s catalogue is a fraction of the playable
season, so a new season length moves every window with it, and adding a
species or moving its peak is one catalogue edit. This slice gives the
fraction they are read against one home.

**True afterwards.**

1. New `scripts/run_calendar.gd`, `class_name RunCalendar`, static functions
   only, reading `GameConfig` and `Session`: `day_at(sim_time: float) ->
   float` (1-based, fractional) and `season_fraction_at(sim_time: float) ->
   float` (0 to 1, held at 1 through winter, as today). The year's length
   stays `Session.year_days()`, which it calls.
2. `flower.gd::season_fraction`, `flower_species.gd::year_fraction_now` and
   `world_building.gd`'s birth fraction call `RunCalendar.season_fraction_at`
   (the last with `Session.sim_time - starting_age`). Each keeps its own
   seasons-off handling (`flower.gd` still returns 0.5); none keeps its own
   `seconds_per_day` arithmetic, and the "duplicates" comment goes.
3. `tests/ev0b_run_calendar_test.gd`, run by `tests/test_ev0b_run_calendar.py`,
   checks `season_fraction_at` against the old formula at day 1, mid-season,
   the last season day, mid-winter and the next spring's first day, for 30-
   and 35-day seasons, with winter on and off. The Python test also fails if
   `flower.gd`, `flower_species.gd` or `world_building.gd` still divides
   `sim_time` by `seconds_per_day`.

**Must not change.** Any flower's bloom, seed draw or birth fraction on any
day; `Session.year_days()`; the save format. Each caller does the same
arithmetic behind one static call, so no per-frame cost is added and no cache
is wanted (`.claude/rules/performance.md`).

**Open decisions:** none.

```queue
**[Claude] EV-0b -- one calendar: day numbers and the season's fraction from one place**
- Plan: `plans/now/event-director.md` -- "EV-0b -- one calendar: day numbers and the season's fraction from one place"
- Files: `scripts/run_calendar.gd`, `scripts/flower.gd`, `scripts/flower_species.gd`, `scripts/world_building.gd`, `tests/ev0b_run_calendar_test.gd`, `tests/test_ev0b_run_calendar.py`
- Check: `python -m unittest tests.test_ev0b_run_calendar` passes (`RunCalendar.season_fraction_at` matches the old formula at day 1, mid-season, the last season day, mid-winter and the next spring for 30- and 35-day seasons, winter on and off; no `sim_time` / `seconds_per_day` arithmetic is left in `flower.gd`, `flower_species.gd` or `world_building.gd`); `python -m unittest tests.test_pp4_seed_set tests.test_sf1_founding_flower_mix` still passes; `.\tools\verify.ps1` is green
- Proof: `present: scripts/flower_species.gd :: This duplicates Flower.season_fraction()`
- Next after: EV-0 -- one Calendar and events settings group, and winter a week later
```
