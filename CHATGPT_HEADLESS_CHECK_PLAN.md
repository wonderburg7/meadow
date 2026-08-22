# ChatGPT-only headless mechanism check plan

> **CHATGPT-ONLY WORKING FILE. Claude Code must ignore this file.**
> Do not read it for orientation, implement it, maintain it, or fold it into
> Claude's plans. Dave will explicitly start this work with ChatGPT in a new
> session. `CHATGPT_NEXTSTEPS.md` is ChatGPT's separate short hand-off;
> `NEXTSTEPS.md` remains exclusively Claude's source of work.

Status: planned 22 Aug 2026, not started. This is the execution hand-off for a
future ChatGPT session. It turns Meadow's existing headless harness into a
small, stable mechanism-check suite without spending runs on systems that are
about to change.

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

### H1. Fast smoke gate

A small established colony runs for 2-3 game days and exits cleanly. Require a
living queen, non-zero population and no failed or unresolved actions. Use one
pinned seed and `brief`. This is the only Godot scenario intended for routine
use after every gameplay slice. Target wall time: a few seconds. Reuse
`slice1_smoke_test.json` if it already supplies the evidence.

### H2. Brood lifecycle

Use the smallest scenario or pair needed to prove that brood is fed,
development advances, at least one bee hatches into the requested role, and a
stocking hatch can restock rather than silently falling back. Start from the C6
nurse and C4 stocking scenarios. Add a generic assertion or stop counter only
if the summary cannot distinguish progress from a stall.

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

At the end, update this file's status/results, add only durable conclusions to
`CHATGPT_INSIGHTS_PLAN.md`, rewrite `CHATGPT_NEXTSTEPS.md`, and commit the
completed slice with a plain-language message. Never put ChatGPT actions in
`NEXTSTEPS.md`. Do not push; pushing depends on the GitKraken plugin being
available.
