# Season balance — the flowering year's peaks and troughs

<!-- CONTEXT: plan | LAYER: immediate-task -->
Status: active | Owner: Dave / Claude Code | Next: SB-2 -- out-of-season species become genuinely rare | Dependency: none -- SB-1 shipped | Verified: 2026-09-12

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
| SB-2 | Out-of-season species become genuinely rare | `game_config.gd`, `flower_species.gd` | yes | low |

SB-0 shipped 12 Sep 2026 (`plans/archive/SB-0_2026-09-12.md`): it added the
`resources.stored_nectar`, `resources.stored_pollen` and
`environment.flowers_by_species` snapshot fields SB-1 and SB-2 both simulate
against.

SB-1 shipped 12 Sep 2026 (`plans/archive/SB-1_2026-09-12.md`):
`game_config.gd` gained `peak_season_strength` (0.75) and
`flower.gd::season_strength()`'s in-window return now arches between
`out_of_season_strength` and `peak_season_strength` instead of between 0 and
1, which also removes the old edge discontinuity. `settings_catalogue.gd`
exposes the new dial. Its check is C-24. SB-2 was waiting on SB-1 only
because both slices add a value to `scripts/game_config.gd`; with SB-1
landed, SB-2 is now startable on its own merits.

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
