# Seed-set evidence

<!-- CONTEXT: reference | LAYER: reference | LOAD: seed-set measurements or ecology design -->
Status: active | Owner: Dave / Codex | Next: EE-2 -- measure carryover through winter and spring | Dependency: existing PP-4 seed-set behaviour | Verified: 2026-10-31

## Summer measurements

EE-1 measured five paired seeds on baseline
`6610f7698c03cda7a655d14597ec224325a55cec`, using Godot
`4.7.2.stable.official.ed1daf0bf` at fixed 30 fps. All ten runs passed,
resolved every scenario action and produced an end save on day 10.

Reproduce with `python tools/seed_set_evidence.py summer`. The tool runs
serially and prints the generated report path. An optional `--output`
selects an empty artefact directory. The measured campaign is retained at
`C:/Users/dl13860/Documents/Meadow/evidence/EE-1-summer/`: `report.json`
contains exact values, paired summaries and source paths; `report.md` is
the readable table; `provenance.json` records all fixture controls. Each
`<seed>-<arm>/` retains its scenario variant, runner result, process log,
full session log and complete private user directory including end saves.
These generated files are outside the checkout and are not committed.

The fixture is `test_scenarios/ee1_seed_set_summer.json`, SHA-256
`e5f34b222894d329edfe1116b874cdae88fb70a8db9ac02d6021530fd5e7adea`.
It starts from PP-4's 12 cells, 24 nectar foragers and six pollen foragers,
all specialising in Clover; nurses, builders, miners and honey makers are
zero. Three initial actions each put 200 honey in a built cell. Winter,
weather, disease, rival hive and predators are off. Days last 20 seconds,
the season lasts ten days and flower regrowth takes 0.1 seconds. The
explicit disease and predator configuration overrides are false; snapshots
are every 60 seconds and pollination logging is on. The fourth action saves
`EE1 end` at day 10; the scenario stops once actions resolve, with a day-11
safety cap. Variants change only `random_seed` and `seed_set`; within each
pair only `seed_set` changes. This is an accelerated, supported diagnostic
colony, not ordinary Colony Run pacing. The PP-4 fixture is unchanged.

In the table, eligible deaths are logged `sets_seed=true` deaths in either
arm, independent of whether seed-set replacement is enabled. All deaths
means every logged flower death of age (`pollination_withered`), not bee
deaths. Seed and seasonal replacements count actual `pollination_replant`
events, one per flower, including individual flowers in bushes. They are
not inferred from eligibility. Final live counts come from the end save's
`flowers` array, in species order Clover / Borage / Foxglove / Poppy /
Bramble / Dandelion. Clover share divides live Clover by all live flowers;
an empty meadow gives an undefined (`null`) share and is excluded from
share summaries with the defined-pair denominator reported explicitly.
Species absent from a save are zero. Seconds are elapsed session simulated
time; counts and shares describe the end save rather than a time average.

| Seed | Arm | Seconds | Eligible / all deaths | Seed / seasonal replacements | Live C/B/F/P/Br/D | Total | Clover share |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 12345 | off | 180.750 | 43 / 2016 | 0 / 1800 | 139/216/9/8/195/17 | 584 | 23.8014% |
| 12345 | on | 180.750 | 54 / 2068 | 35 / 1765 | 118/194/6/11/187/16 | 532 | 22.1805% |
| 7 | off | 180.750 | 68 / 2018 | 0 / 1789 | 112/215/8/6/213/17 | 571 | 19.6147% |
| 7 | on | 180.750 | 62 / 2034 | 47 / 1742 | 144/211/5/10/176/9 | 555 | 25.9459% |
| 2026 | off | 180.750 | 67 / 2022 | 0 / 1785 | 124/193/6/8/211/21 | 563 | 22.0249% |
| 2026 | on | 180.750 | 70 / 2020 | 57 / 1728 | 132/186/10/11/210/16 | 565 | 23.3628% |
| 90210 | off | 180.750 | 68 / 2029 | 0 / 1791 | 102/211/10/10/208/21 | 562 | 18.1495% |
| 90210 | on | 180.750 | 65 / 2002 | 55 / 1736 | 136/210/10/7/210/16 | 589 | 23.0900% |
| 555 | off | 180.750 | 77 / 2038 | 0 / 1800 | 117/180/7/8/232/18 | 562 | 20.8185% |
| 555 | on | 180.750 | 71 / 2042 | 58 / 1742 | 151/191/7/7/195/7 | 558 | 27.0609% |

| Seed | On minus off seed replacements | On minus off Clover share (percentage points) |
| --- | --- | --- |
| 12345 | +35 | -1.6209 |
| 7 | +47 | +6.3312 |
| 2026 | +57 | +1.3380 |
| 90210 | +55 | +4.9405 |
| 555 | +58 | +6.2424 |
| Median (five defined pairs) | +55 | +4.9405 |
| Range | +35 to +58 | -1.6209 to +6.3312 |

Every arm covers both eligible and ineligible deaths and actual seasonal
replacements. Every enabled arm also covers actual seed replacements;
every disabled arm has zero seed replacements. No fixture adjustment was
needed to obtain coverage. Seed replacement operates in this setup, while
the final species-share effect is mixed: Clover's share is higher in four
pairs and lower in seed 12345. The median increase is 4.94 percentage points,
but this does not establish a guaranteed increase or an effect size for
ordinary play. Seasonal replacements still dominate the observed totals.

The arms' random streams diverge after replacement choices differ. These
are paired whole-run comparisons with matching initial conditions, not
causal matches between individual flowers or bees. Five chosen seeds are
descriptive evidence, not a population confidence interval. Different final
meadow totals also affect the share denominator. Summer alone cannot show
winter carryover; the next evidence step is EE-2's paired spring campaign.
No gameplay or balance change follows from this table.

The offline tests cover aggregation, failure and missing-arm rejection,
malformed events, incomplete actions/logs, empty denominators, absent species
and known paired differences. Runtime instrumentation, saves and production
processing remain unchanged.
