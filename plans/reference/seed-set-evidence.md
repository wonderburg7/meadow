# Seed-set evidence

<!-- CONTEXT: reference | LAYER: reference | LOAD: seed-set measurements or ecology design -->
Status: reference | Owner: Dave / Codex | Next: consult spring measurements for a specific ecology design question | Dependency: existing PP-4 seed-set behaviour | Verified: 2026-11-01

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
winter carryover; EE-2's paired spring campaign below supplies that evidence.
No gameplay or balance change follows from this table.

The offline tests cover aggregation, failure and missing-arm rejection,
malformed events, incomplete actions/logs, empty denominators, absent species
and known paired differences. Runtime instrumentation, saves and production
processing remain unchanged.

## Spring measurements

EE-2 ran the same five seed pairs serially on baseline
`01756d4a372b698da46859a47c9af12a057aea0d`, Godot
`4.7.2.stable.official.ed1daf0bf`, fixed 30 fps. All ten arms passed with
every action resolved. Reproduce with `python tools/seed_set_evidence.py
spring`; retained artefacts are at
`C:/Users/dl13860/Documents/Meadow/evidence/EE-2-spring-report/`, with the
same report, provenance, per-arm logs and complete private-save layout as
EE-1. The reporter hash identifies the reporting code alongside the baseline
game commit and fixture hash. The fixture SHA-256 is
`107cd3d9c3959f45e3fe2b7ffac5af29b92d25b95cdc8e93ca8a344b56498c35`.

`test_scenarios/ee2_seed_set_spring.json` retains PP-4's specialist workforce,
600 initial honey, 20-second days and ten-day seasons, with winter enabled,
a one-day countdown, ten-day winter, 0.01 winter burn factor, three-day
spring regrowth and 0.1-second flower replacement. Other controls match
EE-1. There is no restore or backward timeline. Saves occur on day 10
(180.750 simulated seconds, before winter) and day 25 (480.750 seconds,
after regrowth). Regrowth is the half-open interval [400, 460) seconds;
observed spring replacements count actual replant events in that interval,
including each bush flower. Both arms receive identical actions and food.
These summer saves are from this winter-enabled campaign, not EE-1's
winter-disabled runs; they must not be spliced together.

Vectors below use Clover / Borage / Foxglove / Poppy / Bramble / Dandelion.
Shares use all live flowers at each save, with absent species counted as
zero. The generated readable report includes every within-arm change and
paired on-minus-off change in live counts, shares and both seed ledgers,
plus their median, range and defined-pair denominators. `report.json`
retains exact values; percentages here are rounded to four decimal places.

| Seed | Arm | Summer live species | Summer Clover % | Spring live species | Spring Clover % | Observed spring replacements |
| --- | --- | --- | --- | --- | --- | --- |
| 12345 | off | 131/211/11/17/190/18 | 22.6644 | 228/45/1/101/16/117 | 44.8819 | 192/11/8/132/35/212 |
| 12345 | on | 141/216/6/11/197/16 | 24.0204 | 312/28/5/68/4/62 | 65.1357 | 383/10/5/70/14/108 |
| 7 | off | 124/191/5/16/223/10 | 21.7926 | 203/42/3/117/16/107 | 41.5984 | 173/19/4/152/37/205 |
| 7 | on | 124/201/11/9/218/13 | 21.5278 | 290/42/4/91/20/64 | 56.7515 | 391/11/3/78/10/97 |
| 2026 | off | 133/185/11/13/229/22 | 22.4283 | 193/51/3/113/33/115 | 37.9921 | 158/20/7/140/37/228 |
| 2026 | on | 150/182/9/8/195/18 | 26.6904 | 312/36/3/76/9/66 | 62.1514 | 374/17/2/66/13/118 |
| 90210 | off | 122/229/10/8/192/16 | 21.1438 | 214/33/3/119/15/120 | 42.4603 | 171/27/9/132/19/232 |
| 90210 | on | 137/227/8/8/187/21 | 23.2993 | 318/32/2/68/9/69 | 63.8554 | 379/5/2/68/8/128 |
| 555 | off | 128/207/7/6/200/19 | 22.5750 | 223/31/5/125/25/107 | 43.2171 | 188/26/5/135/24/212 |
| 555 | on | 142/199/12/10/196/15 | 24.7387 | 314/30/1/65/16/74 | 62.8000 | 379/3/5/71/4/128 |

All off-arm seed and spring counts are zero at both saves. All summer
spring-count ledgers are zero. Enabled-arm ledgers are:

| Seed | Summer seed counts | Spring seed counts (new year) | Spring counts (previous year) |
| --- | --- | --- | --- |
| 12345 | 42/0/0/0/0/0 | 20/0/0/0/0/0 | 50/0/0/0/0/0 |
| 7 | 63/0/0/0/0/0 | 15/0/0/0/0/0 | 72/0/0/0/0/0 |
| 2026 | 72/0/0/0/0/0 | 6/2/0/0/0/0 | 82/0/0/0/0/0 |
| 90210 | 72/0/0/0/0/0 | 8/0/0/0/0/0 | 75/0/0/0/0/0 |
| 555 | 75/0/0/0/0/0 | 8/0/0/0/0/1 | 81/0/0/0/0/0 |

The previous-year spring ledger includes the remaining days after the
summer save. It rolls once in every on arm; off arms correctly log no
rollover. Each spring save's ledger matches its logged rollover. The
report separates per-species minimum/maximum logged seasonal draw weights
from realised replacement counts: for example Clover's raw weight ranges
from 2.4 to 35.7238 off and 12.2491 to 116.4655 on in every seed. Those are
draw inputs, not probabilities, live counts or replacement counts.

| Seed | Off summer-to-spring Clover change (pp) | On summer-to-spring change (pp) | Summer on minus off (pp) | Spring on minus off (pp) | Change on minus off (pp) |
| --- | --- | --- | --- | --- | --- |
| 12345 | 22.2175 | 41.1153 | 1.3561 | 20.2538 | 18.8977 |
| 7 | 19.8057 | 35.2237 | -0.2648 | 15.1531 | 15.4179 |
| 2026 | 15.5638 | 35.4610 | 4.2621 | 24.1593 | 19.8972 |
| 90210 | 21.3165 | 40.5561 | 2.1555 | 21.3951 | 19.2396 |
| 555 | 20.6421 | 38.0613 | 2.1637 | 19.5829 | 17.4192 |
| Median (five defined pairs) | 20.6421 | 38.0613 | 2.1555 | 20.2538 | 18.8977 |
| Range | 15.5638 to 22.2175 | 35.2237 to 41.1153 | -0.2648 to 4.2621 | 15.1531 to 24.1593 | 15.4179 to 19.8972 |

Spring live Clover increases by 84–119 flowers on minus off (median 91).
Realised spring Clover replacements increase by 191–218 (median 208),
while paired median replacement differences for the other species are
-8 Borage, -3 Foxglove, -64 Poppy, -21 Bramble and -104 Dandelion. The
generated report gives all species' individual paired values and ranges.
Every campaign arm covers eligible and ineligible deaths and seasonal
replacements; enabled arms also record actual seed replacements.

This supported setup shows carryover in realised spring composition, with
higher Clover share in all five enabled arms. Both arms also change with
the season; the off-arm increase is why within-arm increases alone cannot
measure seed-set carryover. Random streams diverge, flower totals differ,
and these five descriptive pairs are not a population confidence interval.
The spring window's replacements are not the final live population:
flowers may subsequently die or be replaced before the day-25 save.
The deliberately supported colony establishes neither ordinary-run
survival nor ordinary-run effect size. No balance or ecology mechanic
changes follow from this campaign.

No further general evidence campaign is warranted by this question. Reopen
measurement only when a specific proposed ecology design requires an
ordinary-paced or different-specialist comparison; make that design
decision before scheduling more evidence. No defect or follow-up slice
was found. Offline checks cover phase edges, missing spring evidence,
backward events, disabled-arm rollover, absent species and known paired
spring arithmetic. Existing PP-4 tests and runtime instrumentation remain
unchanged.
