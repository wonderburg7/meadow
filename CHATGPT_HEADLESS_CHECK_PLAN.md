# ChatGPT-only headless mechanism check plan

> **CHATGPT-ONLY WORKING FILE. Claude Code must ignore this file.**
> Do not read it for orientation, implement it, maintain it, or fold it into
> Claude's plans. Dave will explicitly start this work with ChatGPT in a new
> session. `CHATGPT_NEXTSTEPS.md` is ChatGPT's separate short hand-off;
> `NEXTSTEPS.md` remains exclusively Claude's source of work.

Status: in progress 22 Aug 2026. H0 inventory, H1 smoke gate and H2 brood
lifecycle completed; H3 is next. This is
the execution hand-off for ChatGPT sessions. It turns Meadow's existing
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

1. Read `CHATGPT_NEXTSTEPS.md`, then this file. Do not use or edit Claude's
   `NEXTSTEPS.md` as part of this work.
2. Read only the relevant part of `AI_PLAYTEST_PLAN.md` and the header of
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
work and responding monotonically to 1, 2 and 4 workers; and restocking through
the normal role loop. The C2/C6 scenarios cover much of this already. Consolidate
the invocation and pass criteria rather than duplicating their JSON.

### H4. Player-command routing

Exercise semantic action verbs through the same functions as player commands:
role/focus assignment, designation, one build order and one mine order. Require
accepted actions plus observable postconditions and stop when resolved.

Do not test Challenge stages. Do not add auto-mining coverage until the
Challenge revamp has landed. If work completion is not observable cheaply, test
correct queuing now and leave completion to H7.

### H5. Survival and adverse systems

Use paired on/off comparisons with matched seeds for a controlled energy/hunger
case, disease, and crab spiders. Check activation and direction of effect through
event counts, deaths and survival, not animation or exact tuning. Use three
seeds per pair. Omit the hunger Godot run if the existing Python test fully
answers it and the headless run adds no integration evidence.

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
once it is resolved; Git history is the archive. Never put ChatGPT actions in
`NEXTSTEPS.md`. Do not push; pushing depends on the GitKraken plugin being
available.
