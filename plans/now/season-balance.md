# Season balance — the flowering year's peaks and troughs

<!-- CONTEXT: plan | LAYER: immediate-task -->
Status: active | Owner: Dave / Claude Code | Next: SB-0 -- the two season readouts SB-1 and SB-2 are measured against | Dependency: SB-1 and SB-2 both wait on SB-0; neither can be simulated until it lands | Verified: 2026-09-11

**Objective.** A meadow year that reads as a year: every season has something
in flower, the summer peak is a good season rather than a different game, and
an out-of-season species is a rarity rather than a background constant.

**Why this is a new plan.** Both slices come from checks whose owning plans
are already archived — C-15 (`plans/archive/FLOWERS_SLICE_1_2026-09-03.md`)
and C-17 (`plans/archive/FLOWERS_SLICE_2_2026-09-06.md`). Both checks
**passed** on 8 Sep 2026; these are Dave's balance notes alongside the pass,
not defects in what shipped. `CLAUDE.md` is explicit that a finding arriving
after a plan is archived starts a new plan file rather than reopening the old
one.

**Required reading for any slice here.** This file's own section, plus
`.claude/rules/simulation.md` and the one function named in the slice.
`plans/archive/FLOWERS_SLICE_*.md` are provenance only — do not open them.

**Durable rule this plan works under.** `GameConfig` owns balance values, and
a balance change is simulated before it ships (`CLAUDE.md` rule 2). Neither
slice below may be merged on a code reading alone: each states the headless
comparison that has to be run.

## Open slices at a glance

| Slice | Outcome | Owns | Startable | Reasoning |
| --- | --- | --- | --- | --- |
| SB-0 | A year-long run reports stored stock and live flowers per species | `diagnostic_probes.gd`, `diagnostic_log.gd` | yes | low |
| SB-1 | Peak-season production is a rise, not a spike | `game_config.gd`, `flower.gd` | no — after SB-0 | medium |
| SB-2 | Out-of-season species become genuinely rare | `game_config.gd`, `flower_species.gd` | no — after SB-0, then SB-1 | low |

SB-0 comes first because it is the only thing that can tell whether SB-1 and
SB-2 did what they intend. SB-2 follows SB-1 only because both add a value to
`scripts/game_config.gd`; neither depends on the other's behaviour.

**Why SB-1 and SB-2 were not startable before (corrected 11 Sep 2026).**
`NEXTSTEPS.md` held both out on the grounds that the 9 Sep smoke baseline
exited `0xC0000005` before writing a summary. That failure no longer
reproduces: on 11 Sep 2026 `python tools/run_scenario.py
test_scenarios/slice1_smoke_test.json --report verdict` completed in 7.7 s
with exit code 0 and a classified result. The real obstacle is different and
was never written down -- **both slices name a measurement that does not
exist**. `tests/balance_tests.py` is a static analyser over GDScript source
and runs no simulation at all, so "the balance suite's existing full-year
scenario" names nothing; and `DiagnosticLog`'s snapshot carries
`resources.food_stores` (ripe honey only), the two rate averages and cell
counts by content, but no stored nectar or pollen amount and no live-flower
count by species. SB-0 closes that gap. This is `plans/README.md`'s
sequencing guardrail 2 -- evidence before threshold changes -- applied to a
plan that had assumed the evidence already existed.

## SB-0 — a year-long run reports what a season change actually did

**Reasoning level: low.** Two rows in an existing allowlist catalogue, plus
one merge bug that adding a second row in an existing group exposes.

**Purpose.** SB-1 and SB-2 are balance changes, and `CLAUDE.md` rule 2 says a
balance change is simulated before it ships. Neither can be, because the
fields their comparisons read do not exist. This slice adds them, and nothing
else.

**Current state.** `scripts/headless/diagnostic_probes.gd`'s `SNAPSHOT_FIELDS`
is the allowlist of probes a scenario's diagnostics profile may select; it has
six entries. `DiagnosticLog::_snapshot` reports `resources.food_stores` (ripe
honey only), the two rate averages, and cell *counts* per content kind.
Nothing reports stored nectar or pollen as an amount, and nothing counts live
flowers by species.

**Required reading.** This heading. `scripts/headless/diagnostic_probes.gd` in
full (28 lines). `DiagnosticLog::_snapshot` and `_selected_snapshot`.

**Files likely to change.** `scripts/headless/diagnostic_probes.gd`,
`scripts/diagnostic_log.gd`, `docs/headless-run-contract.md`.

**Files that must not change.** `scripts/hive.gd`, `scripts/flower.gd`,
`scripts/game_config.gd`. This slice measures; it changes nothing measured.

**Requirements.**

1. `SNAPSHOT_FIELDS` gains `resources.stored_nectar`,
   `resources.stored_pollen` and `environment.flowers_by_species`. The first
   two are `hive.total("nectar")` and `hive.total("pollen")`; the third is a
   species-name-to-count dictionary over live flowers, built the way
   `_snapshot` already walks the `soil_blocks` group.
2. **Required discovery, fix it here.** `selected_snapshot`'s `match` assigns a
   whole sub-dictionary per arm, so two selected fields in one group clobber
   each other -- selecting `performance.fps` and `performance.top_sections_ms`
   together loses `fps` today. Adding a second `resources.*` row makes that
   live. Merge into the group instead of assigning it.
3. `_snapshot`'s `resources` block gains the same two totals beside
   `food_stores`, so a run with no selected profile reports them too.

**Constraints and invariants.** Cadence is unchanged -- hourly in game time,
or a scenario's `snapshot_seconds`. Every existing field keeps its exact key
and meaning; `food_stores` stays ripe honey only, because
`scenario_actions.gd`'s `food_stores_at_least` depends on that reading.
`hive.total()` is a full comb scan, so it runs once per snapshot and never per
frame.

**Acceptance checks.** A fixture selecting all three new fields produces them
in `session.jsonl`. A fixture selecting both `performance` fields produces
both, which fails today. `tools/verify.ps1` green.

**Check to file:** none -- nothing a player sees changes.

## SB-1 — peak-season production is a rise, not a spike

**Reasoning level: medium.** One curve, but it moves every forage rate in
the game, so the headless comparison is the substance of the slice.

**Evidence (Dave, 8 Sep 2026, alongside C-15 passing).** "Increases to flower
resource production in peak season are a bit too high." The panel readouts
themselves are correct — C-15 confirmed the age, season and `+/s` lines all
agree. The complaint is the size of the swing.

**Cause.** `scripts/flower.gd::season_strength()` (~line 297) returns a plain
sine arch that reaches exactly 1.0 at the middle of a species' window, while
outside the window it drops to `GameConfig.out_of_season_strength` (0.05):

```gdscript
func season_strength() -> float:
    if not GameConfig.seasons_on:
        return 1.0
    var f: float = season_fraction()
    if f < season_start or f > season_end:
        return GameConfig.out_of_season_strength
    var span: float = max(0.001, season_end - season_start)
    var through: float = (f - season_start) / span
    # a smooth arch: 0 at both ends, 1 in the middle
    return sin(through * PI)
```

So the in-season peak is twenty times the out-of-season floor, and the curve
is also discontinuous at the window edges: it eases to 0.0 at `season_start`
and `season_end`, then jumps to 0.05 one frame later. Both are worth fixing
in one edit.

**Deliver.**

1. In `scripts/game_config.gd`, in the `# --- seasons ---` block beside
   `out_of_season_strength` (~line 796), add:

   ```gdscript
   ## What a species reaches at the very middle of its own flowering window,
   ## as a multiple of its nominal recharge rate. Was implicitly 1.0, which
   ## made peak season twenty times the out-of-season floor and read as a
   ## different game rather than a good summer (Dave, 8 Sep 2026).
   var peak_season_strength: float = 0.75
   ```

2. Rewrite `season_strength()`'s in-window return so the arch runs from the
   out-of-season floor up to that peak, which removes the edge discontinuity
   at the same time:

   ```gdscript
       # A smooth arch from the out-of-season floor up to peak_season_strength
       # and back. Interpolating from the floor rather than from zero also
       # removes the old discontinuity: the curve used to ease to 0.0 at the
       # window edge and then jump to out_of_season_strength.
       return lerpf(
           GameConfig.out_of_season_strength,
           GameConfig.peak_season_strength,
           sin(through * PI)
       )
   ```

3. Expose it in `scripts/settings_catalogue.gd` beside the existing
   `seasons_on` and `season_length_days` rows (~line 576), so Dave can tune it
   without a rebuild: `key` `peak_season_strength`, label "Peak season
   strength", `step` 0.05, `min` 0.1, `max` 1.5.

Do not touch `_senescence_scale()`, `out_of_season_ageing_factor`, or
`effective_nectar_rate`/`effective_pollen_rate` — those already multiply
`season_strength()` and will follow it automatically, which is what keeps the
panel readouts C-15 confirmed in step with the change.

**Simulate before shipping.** A Meadow year is `season_length_days`, 60 by
default, so a 60-day headless run is one year and the existing 60-day foraging
fixtures are the right shape to copy. Add a fixture that runs 60 days with
`seasons_on` at its default, selecting SB-0's `resources.stored_nectar`,
`resources.stored_pollen` and `environment.flowers_by_species`, and run it at
`peak_season_strength` 1.0 (today's behaviour) and 0.75. Report, for each: the
final stored nectar and pollen, the peak stored nectar across the year's
snapshots, and the lowest stored nectar in any one-sixth of the year. The change is
acceptable if the yearly total falls by roughly a fifth to a quarter and the
worst month does not fall far enough to starve a colony that survives today.
If the worst month collapses, raise `out_of_season_strength` rather than
putting `peak_season_strength` back — the point of the slice is to narrow the
gap, and it can be narrowed from either end.

**Acceptance (what Dave does and sees).** With seasons on, watch one species
through its own window with the flower summary panel open. The `+/s` figures
still rise into the middle of the window and fall away at its edges, but the
peak is visibly closer to the shoulder than it was, and the rate no longer
jumps as the window edge passes. Out-of-season flowers are unchanged.

**Check to file:** C-24.

## SB-2 — out-of-season species become genuinely rare

**Reasoning level: low.** One value, one existing formula.

**Evidence (Dave, 8 Sep 2026, alongside C-17 passing).** C-17 passed in full:
"every season retains visible flowers, out-of-season flowers remain rare
rather than absent, and panel text/rates agree." The one note: "Out-of-season
plants should be more rare."

**Cause.** `scripts/flower_species.gd::season_weight()` (~line 185) floors an
out-of-season species' seeding weight at `GameConfig.out_of_season_seed_weight`,
currently 0.15 — a species out of its window still seeds at fifteen per cent
of its usual rarity weight, which over a whole meadow is a steady presence
rather than an occasional one.

**Deliver.** Lower the floor, and only the floor. In
`scripts/game_config.gd` (~line 802):

```gdscript
## An out-of-season species retains this fraction of its usual seed weight,
## so a species never disappears from the meadow entirely. Lowered 0.15 ->
## 0.06 on 8 Sep 2026: at 0.15 an out-of-season plant read as a background
## constant rather than as a rarity (Dave, alongside C-17 passing).
## It must stay above zero -- C-17's pass condition is "rare rather than
## absent", and zero would fail it.
var out_of_season_seed_weight: float = 0.06
```

Do not change `season_weight()`'s shape, `out_of_season_strength`, or any
species' own `weight`. This value is deliberately a single dial.

**Simulate before shipping.** Run SB-1's 60-day fixture at 0.15 and 0.06 and
report, for four snapshots spread across the year,
`environment.flowers_by_species` -- the count of live flowers of each species,
which is the field SB-0 adds for exactly this. Acceptable if at every sampled day at
least one species is well represented and no species reaches zero anywhere in
the year. If any species does reach zero, raise the value in 0.02 steps until
none does, and ship the lowest value that keeps them all present.

**Acceptance.** Play or headless-watch a full year with seasons on. Something
is visibly in flower all year, as C-17 required, but an out-of-season species
now reads as an occasional find rather than as part of the standing mix.

**Check to file:** C-25, which re-runs C-17's condition against the new value.
