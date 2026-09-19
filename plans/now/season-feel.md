# Season feel — Dave's 17 Sep 2026 pass

<!-- CONTEXT: plan | LAYER: immediate-task -->
Status: active | Owner: Dave / Claude Code | Next: SF-1 -- a new run's meadow starts with the season mix it will settle into | Dependency: none | Verified: 2026-09-17

**Objective.** A meadow's seasonal mix looks natural from the first minute of
a run, not only once the founding flowers have died off.

**State.** `plans/archive/SEASON_BALANCE_2026-09-12.md` is archived and never
reopened, so C-24 and C-25's 17 Sep findings start here. C-24's half is
already done on `claude/pass-0917`: out-of-season recharge is 0.75x the
nominal rate and the mid-season peak 1.25x (Dave's figures, 17 Sep 2026), in
`GameConfig.out_of_season_strength`/`peak_season_strength`. C-24 is filed to
re-run against those numbers.

## Open slices at a glance

| Slice | Outcome from the player's seat | Files owned | Startable | Level |
| --- | --- | --- | --- | --- |
| SF-1 | At the start of a run only an occasional flower is out of season, as later in the year | `scripts/world_building.gd`, `scripts/flower.gd`, `scripts/flower_species.gd`, `scripts/diagnostic_log.gd`, new test_scenarios/sf1_founding_flower_mix_test.json | yes | medium |

**Required reading.** SF-1's section below only.

## SF-1 — a new run's meadow starts with the season mix it will settle into

**Purpose.** C-25, Dave 17 Sep 2026, semi pass: "when the game starts, there
are seemingly big proportions of all species, sometimes many species are
around during their off season. this should be more 'natural'. Over time
this corrects as the initial population dies, and off season flowers become
rare."

**Root cause.**
- *Confirmed contributing cause.* The founding cohort is seeded once, for the
  season on day 1, with `age_seconds = randf() * lifespan_seconds`
  (`flower.gd`, flower setup). `flower_lifespan_days` is 6 (±40%), and the
  check was run with Season days 5, so founders live up to 8.4 days: longer
  than the whole year. Every founder seeded in season on day 1 is still there
  through its own off-season. Replacements seed through
  `FlowerSpecies.season_weight`, which is why the mix corrects as founders die.
- *Unconfirmed.* That the founders' share is also wrong at day 1 itself. By
  `season_weight`, at day 1 of a 5-day year three of the six species are out
  of season at weight 0.06, so under 10% of founders should be out of season;
  "big proportions of all species" would mean seeding does not see the
  season it should (for example `Session.sim_time` or `season_length_days`
  not yet reset when `_seed_flower` runs on a restart). Step 1 settles this.

**Files likely to change.** `scripts/world_building.gd` (founding seed loop and
`_seed_flower`), `scripts/flower.gd` (setup takes an optional starting age),
`scripts/flower_species.gd` (`season_weight`/`pick_species_index` take an
optional year fraction), `scripts/diagnostic_log.gd` (the two counters step 1
needs), and a new fixture. **Not `scenario_actions.gd`**: nothing there or in
`tools/run_scenario.py` reads a flower's season today (checked 17 Sep 2026),
and that file belongs to the Claude lane, so the measurement goes through the
diagnostics summary instead -- see requirement 1.

**Must not change.** `GameConfig.out_of_season_seed_weight` (0.06),
`flower_lifespan_days`, replacement seeding's timing, and Challenge 1's Poppy
exclusion.

**Requirements.**
1. *Measure first.* Add two counters to `DiagnosticLog` beside its existing
   flower counters -- flowers in season and flowers out of season
   (`flower.gd::in_season()` is the test) -- so they appear in the hourly
   snapshot and the run summary, which `tools/run_scenario.py` already
   validates through `tools/headless/profiles.py`'s `validate_diagnostics`. Read them
   at t=0, day 1, day 3 and day 5, for Season days 5 and 60, seed 4242.
   Record the four numbers per year length in the delivery note, and read
   back only those fields, never the raw output.
   If the day-0 out-of-season share is above 15%, the unconfirmed cause is
   real: fix that first (seed after the clock and settings are reset) and
   re-measure before step 2.
2. *Founders are born in the past.* For the founding cohort only, draw the
   founder's age first, then pick its species with the season weight for the
   year fraction at its birth (`now - age`, wrapped into the year), and pass
   that age into flower setup instead of drawing it there. A founder then
   matches a flower seeded naturally that long ago, so the day-0 mix equals
   the mix the meadow settles into. Replacement seeding is unchanged.
3. Both new parameters default to today's behaviour, so every other caller is
   untouched.

**Runtime policy.** Founding only; no per-frame work. The global random
stream is consumed in the same order as before per founder (age, then
species) -- accept the one-off layout change and say so in the delivery note.

**Edge cases.** `seasons_on` false (weights ignore the fraction). A year
shorter than a founder's age (wrap with `fposmod`). Challenge 1's excluded
species. A restart after changing Season days.

**Automated acceptance.** `sf1_founding_flower_mix_test.json` at Season days
5, with the assertion in a Python test beside `tests/test_layout_regression.py`
(the fixture produces the summary; the test reads the two counters out of it,
because the scenario `assert` vocabulary has no season condition and must not
grow one in this lane): the day-0 out-of-season share of flowers is within 5
percentage points of the same phase one year later. The original below-15%
criterion conflicts with founders genuinely sampled from their past birth
seasons when flowers can outlive a five-day year; Dave chose the stated
birth-time/stable-mix behaviour on 19 Sep 2026.

**Regression.** `tools/verify.ps1` (the seasons balance test must still find
something in flower, and a pollen source, all year).

**Delivery note (19 Sep 2026).** The two live counters were read at t=0, day
1, day 3 and day 5 with seed 4242. At Season days 5 they were, respectively,
in/out: 516/429, 448/316, 340/105 and 66/46. At Season days 60 they were
386/573, 386/573, 303/293 and 173/61. The 5-day same-phase regression is the
automated contract; its initial and final out-of-season shares differ by less
than five percentage points.

**Completion.** Move C-25 from `checks/blocked.md` to ready with the
birth-time/stable-mix check. Archive this section; set `Next:` to `None — plan
complete` if nothing else was filed.

**Level:** medium. **Escalate if** the two counters cannot be read out of the
run summary without a scenario condition (the Claude lane owns
`scenario_actions.gd`), or if founders born in the past visibly thin the
meadow at the start.
