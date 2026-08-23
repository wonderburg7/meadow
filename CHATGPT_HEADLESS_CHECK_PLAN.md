# ChatGPT-only headless mechanism check plan

> **CHATGPT-ONLY WORKING FILE. Claude Code must ignore this file.**
> Do not read it for orientation, implement it, maintain it, or fold it into
> Claude's plans. Dave will explicitly start this work with ChatGPT in a new
> session. `CHATGPT_NEXTSTEPS.md` is ChatGPT's separate short hand-off;
> `NEXTSTEPS.md` is the canonical integrated-project queue and is not a source
> of work for this plan.

Status: **abandoned by Dave on 22 Aug 2026 because the plan was not especially
useful. Do not resume H6, H7 or extend the suite.** H0 inventory, H1 smoke gate,
H2 brood lifecycle, H3 hive production, H4 player-command routing and H5
survival and adverse systems were completed before the plan was stopped. Their
evidence remains below as a historical record; future ChatGPT sessions should
run simulations only to answer a specific current question, not from this plan.
This is the execution hand-off for ChatGPT sessions. It turns Meadow's existing
headless harness into a small, stable mechanism-check suite without spending
runs on systems that are about to change.

## Goal

Create the smallest useful set of real-Godot headless runs that answers:

> Do Meadow's important, stable simulation mechanisms still perform their
> intended work through the real game code?

This is not a second balance-test suite and not a substitute for Dave playing
the game. Prefer a short causal check with an early stop over a long simulated
playthrough. Reuse existing scenarios wherever they already answer the
question.

## Start of the new ChatGPT session

1. Read `CHATGPT_NEXTSTEPS.md`, then this file. Do not use or independently
   curate `NEXTSTEPS.md` as part of this work; the exception for an explicitly
   assigned queue edit is defined in `CHATGPT.md`.
2. Read only the relevant part of `docs/archive/AI_PLAYTEST_PLAN.md` and the header of
   `scripts/scenario_actions.gd` for the slice being built.
3. Check `git log --oneline -10` and `git status --short` so this plan is not
   applied blindly across newer work.
4. Run `python tools/run_scenario.py --help` rather than re-reading the runner.
5. Begin with H0 only. Do not create scenarios or edit game code until the
   existing scenario inventory has been classified.

Do not begin with a folder-wide source read. The harness already has unique run
IDs, explicit seeds, fixed-FPS determinism, brief reports, early-success stops,
capped failures and presentation gating.

## Scope boundary

### Include now

1. Clean simulation boot and a short colony-health smoke check.
2. Brood feeding, development and hatching into a requested role.
3. Royal-jelly production, restocking and honey fanning.
4. Role/focus assignment, cell designation and small work orders, where real
   postconditions can be observed cheaply.
5. Hunger/energy survival, disease pressure and crab-spider outcomes.
6. The season-to-winter boundary and store consumption as an occasional
   integration check.
7. Indoor path/work completion and staying inside the built hive, only if this
   can be observed without broad new telemetry.

### Exclude for now

- Foraging search, scouting, floral constancy, recruitment, flower choice,
  patch depletion, tarsal markers and rival-foraging comparisons. The planned
  foraging ecology overhaul changes their assumptions. Retain existing runs as
  historical baselines where useful, but do not bless their present outcomes
  as stable regression expectations.
- Challenge 1 stage order, unlock timing, Dr Gallerin prompts and tutorial
  pacing. `CHALLENGE1_REVAMP_PLAN.md` will replace the sequence.
- UI layout, text scaling, settings-window clicking, fog appearance and the
  Challenge-completion presentation. Headless evidence has poor validity here
  and the UI migration is unfinished.
- Bumble-flight quality, which needs human visual judgement.
- Forager-history save fidelity, whose known schema gap has not been scoped.
- A large winter-balance oracle. Winter remains an open design question; keep
  the arithmetic tests and add only a narrow integration check.

Before each slice, use the recent Git history and the named project plan for
that mechanism to confirm it is not about to change. Park the check if it is,
rather than reading or modifying Claude's separate next-step hand-off.

## Evidence and cost rules

- Run `python tests/source_checks.py` and `python tests/balance_tests.py` first.
  Diagnose a failure there before paying for Godot runs.
- Use the runner's default fixed FPS and `brief` report. Do not print raw JSONL
  or `--full` output by default.
- Use `stop.when`, `stop.when_actions_resolved` or a short `max_days`. Stop at
  the first decisive postcondition.
- One pinned seed is enough for deterministic command plumbing. Use three
  matched seeds for stochastic mechanisms; increase to five only if the three
  disagree or sit close to a threshold.
- Paired comparisons must use identical starting state and seeds, changing one
  setting only.
- One run demonstrates execution, not balance. Do not tune a constant from it.
- Prefer existing summary counters and action postconditions. Add telemetry
  only when a missing observation blocks an important check, and keep it useful
  for manual-session diagnosis too.
- Use `behaviour` only for mechanic-firing questions and `balance` only for the
  winter integration run or a diagnosed trend.
- Record wall time while developing checks. Drop or shorten a scenario whose
  result duplicates a cheaper Python test without adding real-game integration
  evidence.

## Execution slices

Build and commit one slice at a time. After each slice, run both Python suites
and the scenario, then record its measured wall time and the named failure it
protects against here.

### H0. Inventory and prune, no game-code changes

Review `test_scenarios/*.json` by filename and short JSON content. Map every
candidate below to an existing scenario before creating anything. Likely
reusable starting points:

- `slice1_smoke_test.json`
- `c2_no_jelly_cell_test.json`
- `c4_stocking_hatch_test.json`
- `c6_nurse_feed_test.json` and `c6_nurse_both_test.json`
- `c6_fanners_1_test.json`, `c6_fanners_2_test.json` and
  `c6_fanners_4_test.json`
- `slice6_crab_spider_test.json`
- `b2_combined_role_test.json` and `b3_postcondition_test.json`

Classify each existing scenario as `keep`, `adapt`, `historical baseline` or
`one-off harness test`. Do not rename old scenarios merely for tidiness. Add a
compact inventory table to this file before starting H1.

Completed 22 Aug 2026. All 25 existing scenarios were read in full after
checking the recent harness history. No scenario or game-code file changed.

| Classification | Scenarios | Mechanism-suite use |
|---|---|---|
| Keep | `b2_combined_role_test.json`, `b3_postcondition_test.json` | H4: real role/mode routing plus accepted designation/build/mine queue postconditions. B3 proves queuing, not job completion. |
| Keep | `c2_no_jelly_cell_test.json` | H3: no royal-jelly spill into undesignated comb; summary already distinguishes feeding from jelly work. |
| Keep | `c4_stocking_hatch_test.json` | H2/H3: requested Stocking hatch resolves to `architect_mode=restock` through the real hatch-role command. |
| Keep | `c6_nurse_feed_test.json`, `c6_nurse_both_test.json` | H2/H3 matched comparison: brood feeding and Anything-mode priority. |
| Keep | `c6_fanners_1_test.json`, `c6_fanners_2_test.json`, `c6_fanners_4_test.json` | H3 matched comparison: honey work fires and throughput rises with more fanners. |
| Adapt | `slice1_smoke_test.json` | H1 starting point. Pin its seed and add explicit cheap health/action pass criteria and an early decisive stop if the present summary cannot enforce them. |
| Adapt | `slice6_crab_spider_test.json` | H5 starting point. Replace the single long predator-on run as regression evidence with matched on/off, three-seed direction-of-effect checks. |
| Historical baseline | `foraging_features_off_test.json`, `foraging_features_on_test.json`, `forage_radius_wide_test.json`, `recruit_threshold_calibration_test.json` | Keep the files and their past findings, but do not treat their current outcomes as stable while the foraging ecology overhaul is pending. |
| One-off harness test | `a2_seed_111_test.json`, `a2_seed_222_test.json`, `a3_fixedfps_benchmark_test.json`, `a5_actions_resolved_test.json`, `a5_stop_when_test.json` | Development fixtures for seed plumbing, fixed-FPS determinism and stop behaviour. Reuse only when changing the harness itself. |
| One-off harness test | `slice2_config_overrides_test.json`, `slice3_timescale_8x_test.json`, `slice3_timescale_16x_test.json`, `slice3_timescale_30x_test.json`, `slice7_action_driver_test.json` | Historical harness build checks for config allowlisting, time-scale choice and the original action-driver demonstration. Superseded for mechanism coverage by the focused B/C scenarios above. |

Coverage gaps deliberately left for their own slices: H2 still needs a concise
development-progress postcondition; H5 has no disease or controlled survival
pair; H6 has no winter-boundary scenario; H7 has queuing evidence but no cheap
completion/stall/invalid-position signal yet. These gaps do not justify new
files during H0.

H0 verification: `source_checks.py` and `balance_tests.py` passed. A read-only
baseline run of `slice1_smoke_test.json` with the default fixed FPS and `brief`
report also passed (`day: 2`, no deaths, brood feeding and cell completion
non-zero, no action problems), confirming the inventoried harness still works
through real Godot. Wall time was 28.6s, so the existing file is not yet the
few-second routine gate H1 requires. H0 protects against accidentally treating
foraging experiments and harness-development fixtures as stable gameplay
regressions; it adds no runtime test of its own.

### H1. Fast smoke gate

A small established colony runs for 2-3 game days and exits cleanly. Require a
living queen, non-zero population and no failed or unresolved actions. Use one
pinned seed and `brief`. This is the only Godot scenario intended for routine
use after every gameplay slice. Target wall time: a few seconds. Reuse
`slice1_smoke_test.json` if it already supplies the evidence.

Completed 22 Aug 2026. `slice1_smoke_test.json` now starts a deliberately small
colony with every worker role represented, pins seed `4242`, and waits for the
first cell completed through the normal builder loop. At that decisive event it
asserts that the queen is still alive and population is non-zero, then
`when_actions_resolved` ends the run; `max_days: 3` is the safety ceiling that
turns a missing completion into an unresolved action. The runner now exits
non-zero for any rejected, failed or unresolved action instead of printing a
warning and returning success.

Routine invocation: `python tools/run_scenario.py
test_scenarios/slice1_smoke_test.json --report brief` (default fixed FPS 30,
one pinned seed). The final development run took 5.6s wall time and stopped on
day 1 at game time 92.75s with one completed cell, outcome
`actions_resolved`, one accepted assertion and no action problems. This is
moderate-validity integration evidence: the artificial colony is small, but
cell completion and queen/population state come from normal game code.

Named failure protected: a scenario boot/setup regression, broken builder
dispatch or cell completion, loss of the queen, an empty colony, or action
plumbing that rejects or never reaches its assertion now makes the routine
gate fail. It deliberately does not promise brood, foraging quality, balance
or presentation coverage.

### H2. Brood lifecycle

Use the smallest scenario or pair needed to prove that brood is fed,
development advances, at least one bee hatches into the requested role, and a
stocking hatch can restock rather than silently falling back. Start from the C6
nurse and C4 stocking scenarios. Add a generic assertion or stop counter only
if the summary cannot distinguish progress from a stall.

Completed 22 Aug 2026. The retained C6 nurse pair now shares seed `4242` and
identical starting state, differing only in the nurse mode assignment. Each
waits for the first real brood hatch, then asserts that at least one real brood
feed occurred and exits via `when_actions_resolved`; `max_days: 10` is the
safety ceiling that converts a feeding/development stall into a failed
`never_fired` action. Both stopped on day 1 at game time 160.75s with six feeds,
one nectar-forager hatch, no deaths and no action problems. Wall times were
11.4s for Feed brood and 10.2s for Anything. Their exactly matched summaries
also retain the useful H3 evidence that Anything mode services needy brood
before doing lower-priority jelly work.

`c4_stocking_hatch_test.json` uses the same seed and starting state, applies the
real hatch-role command to the brood cell, and waits specifically for a
`BUILDER/restock` emergence. It then makes the same feeding assertion and exits
early. The final run stopped on day 1 at game time 160.75s with seven feeds,
one `BUILDER/restock` hatch, no deaths and no action problems in 12.7s wall
time. The old hatch diagnostic was logged as a pseudo-action with result
`spawned`, which H1's deliberate fail-on-non-accepted rule correctly treated
as a problem. H2 replaces that pseudo-action with one generic
`brood_hatches_by_role_mode` summary/event counter, useful in ordinary
diagnostic logs as well as scenarios.

Invocations use the default fixed FPS 30 and `brief` report:
`python tools/run_scenario.py test_scenarios/c6_nurse_feed_test.json --report
brief`, the matching `c6_nurse_both_test.json` command, and the matching
`c4_stocking_hatch_test.json` command. Named failures protected: nurses no
longer delivering food, fed brood stalling before emergence, the Anything mode
failing to give needy brood its feeding priority, a requested hatch role not
being applied, or Stocking silently emerging as another Comb worker mode.
These are moderate-validity integration checks: the starting colony is
artificial, but feeding, development, emergence and role/mode application all
run through normal game code. They do not judge nursery pacing or balance.

### H3. Hive production

Retain isolated checks for no undesignated jelly spill; an Anything-mode nurse
feeding before making jelly when brood needs food; honey fanning doing real
work across matched 1, 2 and 4-worker cases; and restocking through the normal
role loop. Record fanner throughput for diagnosis but do not require strict
monotonic totals, for the reasons established below. The C2/C6 scenarios cover
much of this already. Consolidate the invocation and pass criteria rather than
duplicating their JSON.

Baseline checkpoint 22 Aug 2026. Both Python gates passed before the Godot
runs (`source_checks.py`: 63 scripts; `balance_tests.py`: all 16 checks). The
unchanged scenarios use fixed FPS 30 and `brief`, but none yet has a protected
gameplay postcondition:

| Scenario | Seed | Result | Wall time | What it proves today |
|---|---:|---|---:|---|
| `c2_no_jelly_cell_test.json` | runner-selected `1869930731` | day 10; 99 brood feeds; 0 jelly batches; 2 starvation deaths | 35.1s | The present run made no jelly without a designated cell, but only the nurse assignment is enforced. |
| `c6_fanners_1_test.json` | runner-selected `1833933892` | day 6; 17 deposits; 16 cells ripened; 0 deaths | 22.3s | Honey work fired, but this seed cannot be compared with the other two. |
| `c6_fanners_2_test.json` | runner-selected `60366718` | day 6; 22 deposits; 12 cells ripened; 2 deaths | 13.5s | Same limitation. |
| `c6_fanners_4_test.json` | runner-selected `610896351` | day 6; 56 deposits; 44 cells ripened; 0 deaths | 11.6s | Same limitation. |

A read-only rerun of the unchanged fanner trio with seed `4242` removed that
confound. The 1/2/4 cases produced 26/19/33 honey deposits and 26/15/20
ripened cells; the 2- and 4-fanner wall times were 19.7s and 16.4s (the first
direct launch was not externally timed). All reached day 6. This is useful
moderate-validity evidence that every case performs real honey work, but it
rejects strict monotonic final throughput as a stable regression oracle.
Assigning extra fanners also removes active foragers and changes contention
for shared nectar, cells and paths, so the comparison changes more than raw
fanning capacity even though the JSON differs by one requested worker count.

The smallest implementation hand-off is therefore:

1. Expose the already-maintained `jelly_batches`,
   `honey_batches_deposited`, `cells_ripened` and `cells_restocked` counters
   through the generic `event_count` condition; do not add new telemetry.
2. Pin seed `4242` in C2 and all three fanner files. Give each fanner case a
   cheap real-work assertion/early stop (at least one deposit and one ripened
   cell) plus a short safety ceiling. Treat 1/2/4 as matched execution checks,
   not a monotonic balance threshold.
3. Make C2 fail non-zero if any jelly batch occurs before a designated jelly
   cell exists. The current positive-only condition language cannot express
   that forbidden-event invariant, so add one generic maximum/equality
   counter condition or a stop/failure condition rather than a C2-specific
   verb. Keep the safety horizon only as long as needed to allow several brood
   feeds, proving the Anything nurse had opportunities to work.
4. Do not count `c4_stocking_hatch_test.json` as restocking coverage. It proves
   a requested bee emerges in `BUILDER/restock` mode, but supplies no restock
   target/source order and the baseline summary has zero deliveries. Either
   add the smallest semantic restock-order action that calls the real
   `orders_zones` path and stop on one `cells_restocked` event, or explicitly
   leave delivery coverage as an H3 gap.

Implementation-ready contract, checked against commit `fb5871f` and the live
working tree on 22 Aug 2026:

- Extend `DiagnosticLog.event_count()` with the existing flat counters under
  the summary names `jelly_batches`, `honey_batches_deposited`,
  `cells_ripened` and `cells_restocked`. Extend
  `ScenarioActions._when_met()` with generic
  `event_count_at_most: {type, subtype?, count}` alongside the existing
  `event_count_at_least`. This is deliberately an assertion condition, not a
  special jelly verb.
- In C2, pin `random_seed: 4242`. Keep the immediate Anything-mode nurse
  assignment, then gate an assertion on five real `brood_feed` events and
  assert `jelly_batches <= 0`. Use `when_actions_resolved` and a short
  `max_days` ceiling. A spill becomes `assert_failed`; missing brood work
  becomes `never_fired`; both make the runner exit non-zero.
- In each C6 fanner file, pin `random_seed: 4242`. Keep the matched starting
  state and the day-1 assignment count of 1, 2 or 4. Add one assertion gated
  on both `honey_batches_deposited >= 1` and `cells_ripened >= 1`, assert the
  same two conditions, then use `when_actions_resolved` with a short ceiling.
  Do not compare the final totals as a pass threshold.
- Add a semantic `set_restock_order` action rather than mutating bee fields.
  Resolve the chosen Comb worker and target/source comb cells, temporarily
  populate the same `main.selected_bees` and `main.selected_cells` collections
  the UI uses, and call
  `orders_zones._on_restock_targets_requested(resource)` followed by
  `_on_restock_sources_requested(true)`. Restore the previous selections and
  reject the action unless the worker finishes with the requested target,
  source and resource. This calls the real order path and keeps the action
  useful beyond H3.
- Prefer a new isolated `h3_restock_delivery_test.json` over extending C4.
  A compact deterministic setup can use 15 cells, one Comb worker, seed 4242
  and `stock: {"honey": 2}`. For a 15-cell starting spiral the last two stocked
  cells are `[0, 2]` and `[1, 1]`; `[0, 0]` is a suitable empty target at boot.
  Apply the restock order immediately, then gate/assert on
  `cells_restocked >= 1` and stop when actions resolve. The scenario must
  reject cleanly if any named cell is absent or the order did not stick.

Before adopting those example coordinates, Claude should make one real run to
confirm the queen has not occupied `[0, 0]` before the first action tick. If
that race exists, choose another known-empty starting cell or let the semantic
action select an empty target explicitly; do not add direct resource mutation
to make the scenario pass.

No scenario, game-code or harness file was changed in this checkpoint because
that session was in advisory mode, where `CHATGPT.md` restricts ChatGPT to
ChatGPT-specific Markdown. H3 is not complete and should not be committed as a
completed slice until the adapted scenarios pass, their final wall times are
recorded, and both Python gates are rerun.

Continuation checkpoint 22 Aug 2026. Rechecked commit `fb5871f` and the live
working tree after newer Dave/Claude edits appeared elsewhere. The H3 contract
has not landed: `DiagnosticLog.event_count()` still lacks the four production
counter mappings; `ScenarioActions._when_met()` still has no
`event_count_at_most`; there is no `set_restock_order` action or
`h3_restock_delivery_test.json`; and C2 plus the three C6 fanner scenarios
remain unpinned and without causal assertions or early stops. The relevant
implementation and scenario files have no working-tree diff, so verification
was deliberately not run against the unchanged baselines. H3 remains blocked
at the existing implementation hand-off; the concurrent gameplay edits were
not touched.

Completed 22 Aug 2026 against commit `9c9466b` plus the live working tree.
Dave authorised the narrow headless-check implementation exception now
recorded in `CHATGPT.md`. H3 adds no balance values or production telemetry:
it exposes four counters already maintained by `DiagnosticLog`, adds generic
`event_count_at_most`, and adds one semantic `set_restock_order` action that
uses the real two-step `orders_zones` command path and restores the prior
selection afterwards.

All retained scenarios use fixed FPS 30, seed `4242`, `brief`, causal
postconditions and `when_actions_resolved`, with `max_days` only as a failure
ceiling:

| Scenario | Decisive result | Stop | Wall time |
|---|---|---:|---:|
| `c2_no_jelly_cell_test.json` | 5 real brood feeds; 0 jelly batches | day 1, game time 140.75s | 5.3s |
| `c6_fanners_1_test.json` | 1 honey deposit; 1 cell ripened | day 1, game time 97.75s | 7.2s |
| `c6_fanners_2_test.json` | 2 honey deposits; 1 cell ripened | day 1, game time 78.75s | 6.3s |
| `c6_fanners_4_test.json` | 4 honey deposits; 1 cell ripened | day 1, game time 81.75s | 4.1s |
| `h3_restock_delivery_test.json` | 1 real nectar restock delivery | day 1, game time 3.875s | 3.4s |

The restock scenario deliberately uses starting nectar rather than the
contract's provisional honey example. A real trial showed that starting honey
has not been ripened, while the real restock loop correctly allows honey to be
drawn only from `ripe_honey`; using nectar isolates delivery without weakening
the command-path evidence. The named cells existed, `[0, 0]` remained a valid
target at the first action tick, both semantic commands stuck, and the worker
completed the delivery through its normal role loop.

Disposable negative controls were run and deleted. One deliberately produced
jelly batch made `event_count_at_most` fail with outcome `assert_failed` and
runner exit 1. Removing honey-worker assignment left the deposit assertion
`never_fired` and exit 1. Removing the restock order left the delivery
assertion `never_fired` and exit 1. Thus a jelly spill, missing honey work and
missing restock delivery cannot pass merely by reaching a time ceiling.

Final verification passed: `source_checks.py` checked 65 scripts and
`balance_tests.py` passed all 16 checks. The positive runs had no failed,
rejected or unresolved actions. Named failures protected are an undesignated
jelly spill after real brood-work opportunities, any fanner case ceasing to
deposit or ripen honey, the semantic restock command failing to set its worker,
target, source or resource, and the normal restock loop failing to deliver.
This is moderate-validity integration evidence: starting colonies are
artificial, but every protected mechanism and command path is real. It does
not claim monotonic fanner throughput, balance quality or good presentation.

No commit was made during closure because the ChatGPT-specific Markdown files
already contained earlier uncommitted edits and Claude changed separate plan
files concurrently; committing whole files would mix ownership. The H3 source
and scenario changes remain distinct in the working tree.

### H4. Player-command routing

Exercise semantic action verbs through the same functions as player commands:
role/focus assignment, designation, one build order and one mine order. Require
accepted actions plus observable postconditions and stop when resolved.

Do not test Challenge stages. Do not add auto-mining coverage until the
Challenge revamp has landed. If work completion is not observable cheaply, test
correct queuing now and leave completion to H7.

Completed 22 Aug 2026 against commit `9c9466b` plus the live working tree.
The retained B2/B3 fixtures now pin seed `4242`, issue their commands on the
first valid action tick, and stop with `when_actions_resolved`; `max_days: 1`
is only a failure ceiling. No completion telemetry was added. The semantic
verbs already call the real player-command functions and verify their immediate
postconditions before logging acceptance: selected bees hold the requested
role and mode, the cell holds its designation, and the real worker queues hold
the requested build tile or soil block.

| Scenario | Decisive result | Stop | Wall time |
|---|---|---:|---:|
| `b2_combined_role_test.json` | 2 nurses became pollen foragers; explicit population assertion passed | day 1, game time 0.75s | 4.1s |
| `b3_postcondition_test.json` | build target, mine target and honey designation all accepted after their live postconditions were checked | day 1, game time 0.75s | 4.3s |

The B2 negative control exposed a real false-positive: an invented combined
focus such as `forager_not_a_focus` was applied and then reported accepted,
because the postcondition compared the bee's freely assigned string without
first checking that it was a mode the role actually offers. The generic
`assign_role` action now validates combined mode keys against
`Roles.modes_for(role_id)` before calling the player path. A repeat rejected
the invented focus with runner exit 1. Separate disposable negatives for a
missing build worker, absent mine block and absent designation cell were all
rejected and also produced runner exit 1; all temporary fixtures were deleted.

Final verification passed: `source_checks.py` checked 66 scripts and
`balance_tests.py` passed all 16 checks. Both positive runs had only accepted
actions and no action problems. Named failures protected are a role change or
focus change silently not sticking, an unknown focus being falsely accepted,
designation silently not sticking, or build/mine commands failing to enter the
real worker queues. This is high-validity command-routing evidence, because
the actions use the same functions as player commands and inspect the resulting
game objects. B3 deliberately proves queuing rather than completion; work
completion, stalls and invalid hive positions remain H7 concerns.

No commit was made during closure because `scenario_actions.gd` already
contains the uncommitted H3 restock action and the ChatGPT plan files contain
the earlier H3 record; committing whole files would mix completed slices while
Claude also has unrelated live changes in the tree. The H4 changes remain
small and identifiable in the working tree.

### H5. Survival and adverse systems

Use paired on/off comparisons with matched seeds for a controlled energy/hunger
case, disease, and crab spiders. Check activation and direction of effect through
event counts, deaths and survival, not animation or exact tuning. Use three
seeds per pair. Omit the hunger Godot run if the existing Python test fully
answers it and the headless run adds no integration evidence.

Completed 22 Aug 2026 against commit `9c9466b` plus the live working tree.
The arithmetic suite covers energy budgets and default pathogen/predator risk,
but does not execute a bee's real death path, so H5 retained a controlled
energy pair rather than omitting it. The harness now exposes its existing
death and flower-visit counters through generic `event_count` conditions,
supports live `disease_at_least`/`disease_at_most` observations, and accepts a
comma-separated `--seeds` list so both sides of a stochastic pair can replay
the same launches without duplicating fixtures. An empty crab-spider subtype
now means all outcomes, which makes the predator-off invariant cover kills,
escapes and alarm flees rather than accidentally querying a nonexistent empty
key.

All pairs used fixed FPS 30, `brief`, matched seeds `101,202,303`, causal
postconditions and `when_actions_resolved`; their short `max_days` values are
failure ceilings only. Each pair differs in one causal setting:

| Pair | On/adverse result across seeds | Off/control result across seeds | Final seed-101 stop / wall time |
|---|---|---|---|
| Energy (`flight_energy_burn` 10 vs 0) | One real forager starvation in every run; queen alive | Ten real flower visits, zero starvation deaths; queen alive | 24.75s / 3.2s vs 14.75s / 3.2s, day 1 |
| Disease (`disease` true vs false) | Pressure exceeded 0.1 and all eight workers died early of old age in every run | Pressure stayed at 0 and no worker died by day 7 | 121.75s / 4.0s vs 120.75s / 4.7s, day 7 |
| Crab spiders (`predators_on` true vs false) | At least one real ambush kill in every run (1-3 deaths) | Ten real flower visits and no predator outcome of any kind | 4.775s / 2.2s vs 5.75s / 2.3s, day 1 |

Routine paired invocation shape is `python tools/run_scenario.py <scenario>
--seeds 101,202,303 --report brief`. The six retained fixtures are
`h5_energy_high_flight_burn_test.json`,
`h5_energy_zero_flight_burn_test.json`, `h5_disease_on_test.json`,
`h5_disease_off_test.json`, the adapted `slice6_crab_spider_test.json`, and
`h5_crab_spider_off_test.json`.

Disposable inverted controls were run and deleted. Removing high flight burn
from the adverse energy case left its starvation assertion `never_fired` and
runner exit 1. Turning disease off in the adverse pathogen case left its old-
age assertion `never_fired` and exit 1. Turning predators on with a zero kill
chance produced three escapes before the control horizon, making the generic
no-predator-event assertion fail with `assert_failed` and exit 1. Thus none of
the three pairs passes merely by reaching its safety ceiling.

Final verification passed: `source_checks.py` checked 66 scripts and
`balance_tests.py` passed all 15 checks in the current tree. All 18 positive
Godot runs ended `actions_resolved` with no rejected, failed or unresolved
actions. Named failures protected are flight energy no longer being charged or
causing starvation, zero flight cost incorrectly causing starvation, pathogen
pressure failing to activate or shorten lifespan, disease-disabled runs still
accumulating pressure, crab-spider encounters failing to kill under a forced
100% test setup, and any predator event occurring while predators are off.
This is moderate-validity integration evidence: artificial settings amplify
each mechanism for a fast causal check, while energy burn, disease progression,
lifespan and ambush deaths all execute through normal game code. It deliberately
does not bless the amplified values as balance or make a claim about visuals.

No commit was made during closure because the shared diagnostic/action files
still contain the earlier uncommitted H3/H4 changes and Claude has unrelated
live ecology changes in the same working tree; committing whole files would
mix ownership. H5 did not edit the changing foraging or crab-spider gameplay
files.

### H6. Seasonal integration, milestone-only

Start an established colony with enough stores to cross the seasonal boundary.
Check winter arrival, changed consumption, falling honey and survival to a
short horizon. Use `balance` and one pinned seed initially. Run only before a
milestone or after changes to seasons, winter, survival, honey storage or time
progression. Keep the pass boundary broad enough not to freeze the unresolved
winter design.

### H7. Navigation/work watchdog, only if cheaply observable

Attempt one indoor route and one small queued job. The check must be able to
fail on a stalled bee or one leaving the built hive, not merely time out. Look
for existing diagnostic evidence first. If absent, estimate the cost of one
generic work-completion or invalid-hive-position signal before editing.

Park this slice if it requires special-case instrumentation or overlaps the
Challenge revamp's auto-mine work.

## Resulting run tiers

| Tier | Contents | When to use |
|---|---|---|
| Smoke | Python suites + H1 | Every gameplay slice |
| Mechanism | Only relevant checks from H2-H5 | When that system changes |
| Milestone | All retained stable checks + H6, optionally H7 | Before a milestone or broad refactor |

Do not build a general suite runner unless manual invocation becomes a real
repeated cost. A short command list is cheaper to maintain at this scale.

## Ecological validity and player experience

- **High validity:** a semantic action calls the real player-command function,
  bees use normal role loops, and a resource or state postcondition is observed.
- **Moderate validity:** an artificial starting colony isolates a mechanism but
  the mechanism itself runs normally. Good regression evidence, weak whole-game
  balance evidence.
- **Low validity:** the result depends on visuals, comprehension, pacing,
  targeting skill or subjective motion. Leave it to Dave's directed hands-on
  check.

State the applicable level in the final report. Never translate “counter was
non-zero” into “the feature feels good”.

## Completion criteria

1. Every retained scenario protects a named important failure and records its
   invocation, report profile, seed policy, stop condition and wall time.
2. Soon-to-be-invalid and one-off harness scenarios are labelled rather than
   silently treated as regression checks.
3. H1 is cheap enough for routine use; H2-H5 are selective; H6 is milestone-only.
4. Retained scenarios pass real Godot runs, both Python suites pass, and no
   balance value was changed merely to make a test green.
5. The hand-off states what still needs Dave's eyes.

At the end, update this file's status/results, add only unresolved durable
conclusions to `insights_from_ChatGPT.md`, rewrite `CHATGPT_NEXTSTEPS.md`, and
commit the completed slice with a plain-language message. Delete an insight
once it is resolved; Git history is the archive. Do not independently put
ChatGPT actions in `NEXTSTEPS.md`; follow `CHATGPT.md` if Dave explicitly
assigns a queue update. Do not push; pushing depends on the GitKraken plugin
being available.

In every headless-run final response, explicitly tell Dave whether any
recommendations were added to, updated in or removed from
`insights_from_ChatGPT.md`. If there were none, say so directly.
