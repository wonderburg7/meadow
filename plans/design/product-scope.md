# Meadow — product scope and development sequence

<!-- CONTEXT: plan | LAYER: design -->
Status: selected design, not scheduled | Owner: Dave | Next: reconcile `plans/design/progression.md` with the decisions recorded here, then admit one alpha-foundation slice through `NEXTSTEPS.md` | Dependency: current stabilisation and hands-on checks continue independently | Verified: 2026-09-03

This is Meadow's high-level product map. It defines what the game is trying to
prove, what is essential for the first feedback build, which foundations later
systems should share, and when to review or defer work. It is deliberately
above implementation slices: `NEXTSTEPS.md` remains the only execution queue,
and the detailed plans it names continue to own individual changes.

## 1. Product promise

Meadow's flagship experience is a multi-session colony-management game. The
player starts with a queen, builds a colony from the ground up, unlocks
capabilities, automates recurring work, notices where the colony is failing
and changes its organisation so the solution persists. The three primary
player fantasies, in order, are:

1. optimising jobs, stores and foraging;
2. surviving environmental pressures; and
3. solving a colony-management puzzle.

The desired rhythm is **observe → diagnose → reorganise → automate → face new
pressure**. Individual-bee control supports tutorials and emergencies; the
normal game increasingly operates through priorities, standing policy and
automation.

The first external audience is friends and family with mixed game experience
who tolerate rough edges. Their feedback is valuable only after the game is
clear enough that confusion with the interface can be distinguished from a
weak underlying decision.

## 2. Run types

- **Challenges** are focused, authored lessons and unusual problems. Completing
  them discovers skills for the main game. Challenges 1 and 2 deliberately
  remove the queen's normal Backup Roles grant.
- **Colony Run** is the working name for the flagship systemic game. It starts
  with a queen, includes contextual help from Dr Gallerin, builds through the
  skill tree and combines scheduled pressure with simulation-driven events.
  In the eventual main game, only skills discovered through Challenges are
  available for purchase.
- **Scenarios** are variants of the Colony Run with different starting states,
  environments, restrictions or objectives.
- **Sandbox** has no required win condition. It becomes available after the
  first set of Challenges and contains only features discovered through
  completed Challenges.
- **Early feedback run** is a temporary Colony Run policy, not a separate
  implementation. Every skill included in the alpha may become discoverable
  through progress in that run, so testers can exercise the game before the
  full Challenge campaign exists.

## 3. First feedback target

The first closed alpha is a saveable 90-minute arc that may be continued after
victory. Target timings are experience budgets, not promises that override a
player's pause or chosen speed:

| Time | Player outcome |
| --- | --- |
| About 5 minutes | The queen has established the colony and raised the first worker. |
| About 10 minutes | The player has achieved the first useful automation. |
| About 20 minutes | A serious, readable forage-and-weather crisis tests preparation and response. |
| About 60 minutes | The colony enters and survives its first winter. |
| About 90 minutes | After emerging from winter, the colony raises and releases gynes, reaches formal victory and may continue. |

The build does not need every planned feature. It needs one complete route
through the economy and skill tree to Gyne Rearing, representative pressures,
and enough continued play to prove that later branches have somewhere to go.

## 4. Scope status vocabulary

Use these labels in the product map so "planned" is never mistaken for
"built" and "built" is never mistaken for "player-ready":

- **Built foundation** — implemented and suitable to build on, though ordinary
  defect fixing and balancing may remain.
- **Built, review required** — implemented but still has a named hands-on,
  usability, balance or evidence question.
- **Designed, not scheduled** — product direction exists but has not entered
  `NEXTSTEPS.md`.
- **Needs design** — an idea worth retaining whose rules, ownership or player
  outcome are not yet settled.
- **Parked for later** — intentionally cannot delay the current milestone;
  reopening requires evidence or the named earlier milestone.
- **Cut from alpha** — retained in the wider product vision but absent and
  hidden in the first feedback build.

## 5. Current product inventory

### 5.1 Built foundation

- a playable queen-to-colony loop across meadow and hive views;
- bee roles and sub-modes for foraging, nursing, comb work, mining, honey,
  laying and idle behaviour;
- brood, royal jelly, comb construction, excavation, stores, energy, ageing,
  starvation, disease pressure, seasons, winter and gyne scoring;
- flowers with flowering windows and resource replenishment;
- rain/weather foundations, a rival hive and crab-spider predator foundations;
- Challenges, Scenarios, stage gating, Dr Gallerin guidance and tutorial
  checkpoints;
- save/load foundations, settings, accessibility options, fog of war,
  diagnostics and deterministic verification;
- a procedural visual fallback that lets development continue before bespoke
  art is complete.

### 5.2 Built, review required

The current queue and hands-on lists own the exact checks. At product level the
remaining work clusters are:

- Challenge 1 acceptance and Challenge 2 rescue/recovery evidence;
- UI hierarchy, control clarity, panel layout and command feedback;
- flower season/senescence readability and balance;
- comb construction/readability questions;
- settings surviving run changes;
- save/restore, predator and foraging behaviours that still have named live
  checks.

These are part of alpha stabilisation. They should continue through
`NEXTSTEPS.md`; this plan does not duplicate or reorder their slices.

### 5.3 Designed, not scheduled

- skill catalogue, resolver, campaign discovery and in-run purchasing;
- Colony Adaptations, deliberately after the skill tree;
- the long-form feedback run described here;
- the alpha workforce, Bee Bread, pollination and ecological rules below.

## 6. Essential versus later

### 6.1 Essential for the closed alpha

- the 90-minute queen → winter → gynes arc;
- contextual onboarding, clear controls and high-impact defect correction;
- long-, milestone-, short-term- and urgent-goal presentation;
- first-encounter explanations from Dr Gallerin and a persistent
  "Why is this happening?" route;
- resource production-versus-consumption, missing-workforce, waiting/travel and
  blocked-work diagnostics;
- progress-triggered skill discovery for the feedback-run policy;
- the retained alpha skill set and one selected route to Gyne Rearing;
- Backup Roles, early automation and Tier-3 Work Priorities progression;
- Bee Bread production, larval use and adult consequences;
- rain sensing/recall, predator avoidance and a readiness-aware crisis;
- named run saves, three rolling recovery checkpoints and reliable restore;
- Easy difficulty rules, a standard difficulty baseline and understandable
  failure/victory/continue states;
- balance and pacing evidence at the 5/10/20/60/90-minute gates;
- a simple feedback process for friends and family.

### 6.2 Shared foundations that precede content expansion

- **Run policy:** skill discovery, availability, difficulty, event pacing,
  victory, failure and continuation per run type.
- **Stable catalogues and resolver:** feature, skill, role, resource, goal and
  event IDs; typed effects; one availability/affordability authority.
- **Goal model:** separate long-term goals, milestones, optional short-term
  outcomes and urgent problems.
- **Event director:** hybrid selection using elapsed time, colony progress,
  readiness, recent events and difficulty. It schedules pressure; simulation
  rules determine the outcome.
- **Colony diagnostics:** reusable derived facts for UI, Dr explanations,
  automated checks and future balancing.
- **Job catalogue and dispatcher:** jobs and sub-jobs are stable data used by
  roles, Work Priorities, individual overrides and later policies.
- **Persistence:** separate player profile and named run saves, migration,
  three rolling checkpoints, and restoration of progression/ecology state.
- **Authoring data:** Challenges, Scenarios and environments share validated
  data formats before a public editor is considered.
- **Observability:** deterministic balance scenarios and bounded diagnostics
  for every new economy or per-bee hot path.

### 6.3 Core expansion after feedback validates the base

- deeper standing policies, workforce targets and sub-role control;
- Colony Adaptations;
- broader weather and colony responses;
- ecosystem consequences and stewardship choices;
- additional diseases, pests, predators and environmental animals;
- Codex/Dr notes combining game guidance with bee biology;
- themed Challenge sets, additional Scenarios and environments;
- audio, broader sprite production and accessibility refinement.

### 6.4 Cut from alpha / protected experiments

- guards, combat, invading or robbing other colonies;
- nectar robbing and robber defence;
- drones, medicine, auto-defence/auto-attack;
- drought, Adjustment Panel, Chemical Cascade and Extended Backup Roles;
- public Scenario/environment editor, sharing, moderation and distribution;
- a 3D terrain conversion;
- detailed temperature and waste management;
- temporal polyethism as a simulation-wide rule;
- many individually modelled diseases/pests at once;
- multiple fully developed biomes, complete sprite replacement, full
  localisation and launch-scale audio;
- Steam commercial decisions that do not affect the alpha build.

"Cut from alpha" is not rejection. Reopening requires either the successful
closed-alpha gate or feedback showing the missing feature prevents the core
promise from working.

## 7. Goal and guidance model

1. **Long-term:** survive winter and release gynes.
2. **Milestones:** first worker, first automation, stable resource income,
   winter readiness, post-winter recovery and first gyne.
3. **Short-term:** optional, context-sensitive outcomes such as establish a
   pollen surplus or reduce blocked work. They state an outcome, not an exact
   click sequence, and carry no failure penalty.
4. **Urgent problems:** falling stores, starving brood, blocked work, dangerous
   weather or other immediate risks.

Dr Gallerin explains a problem on its first appearance, with occasional humour
and personality. Afterwards the player can request the same causal explanation
through "Why is this happening?". Advice should connect evidence to possible
responses without declaring one correct colony organisation.

## 8. Workforce progression

- **Start:** ordinary bees have one exclusive role.
- **Backup Roles — Hive Mind Tier 1:** one primary and one fallback role. The
  queen is granted this capability in ordinary runs; Challenges 1 and 2 remove
  the grant.
- **Automation — Hive Mind Tier 2:** automatic building and mining. Cleaning is
  also retained at Tier 2.
- **Work Priorities — Hive Mind Tier 3:** roles become priority presets which
  bees may depart from when colony needs demand it. Unlocks colony-wide
  job/sub-job ordering and individual-bee overrides.
- **Extended Backup Roles:** cut from alpha; Work Priorities provides the
  intended scalable control surface.

## 9. Bee Bread

Bee Bread is pollen plus honey deposited into a designated cell by a Honey
Worker in the **Fermenter** sub-role. The worker seals the cell; it ferments for
seven game-days, then becomes larval food and a Tier-3 progression currency.

Nurses feed available Bee Bread automatically. The later Priority Cells skill
allows deliberate allocation when supply is scarce.

Adult outcome is fixed at emergence and saved with the bee:

- raised without Bee Bread: 15-day lifespan, 95% speed and 95% carrying
  capacity;
- raised with Bee Bread: 25-day lifespan, 105% speed and 105% carrying
  capacity.

The exact pollen/honey recipe, cell capacity, larval ration and UI forecast are
balance decisions requiring the scenario harness; they are not guessed here.

## 10. Pollination and ecology

A bee earns one Pollinator Point when it moves from one flower individual to a
different individual of the same species, subject to one award per destination
plant's pollination window.

Track two ledgers:

- **Spendable Pollinator Points** are required by every Tier-4 skill. A recipe
  may add thematic resources; Gyne Rearing may also require royal jelly.
- **Pollination Contribution** is never spent. It drives ecological goals,
  seed outcomes and later environment improvements.

Compatible pollination increases seed set and offspring quality. A visit
arriving directly from another species contributes incompatible pollen,
reducing both. An unpollinated flower does not set seed. A separate minimum
background emergence/seed-bank probability prevents a species disappearing
from the simulation entirely.

Offspring quality gives a slight bonus or penalty to nectar and pollen amounts,
is bounded to ±15% of species baseline, and regresses toward that baseline
between generations so success cannot compound without limit.

The first sprite/readability set is **Dandelion, Poppy and Borage**, each with
rewarding, depleted, out-of-season and ageing/senescent treatment. Procedural
indicators handle overlapping states to avoid a combinatorial asset set.

## 11. Difficulty, failure and recovery

### Easy

- event timing follows player readiness more strongly than calendar day;
- ordinary workers may die from old age, but non-age damage and energy loss
  cannot kill them;
- a worker at one health or without energy moves at 25% speed until it returns
  to the hive, rests and clears minimum health and energy thresholds;
- predator attacks can injure and force retreat but cannot kill;
- the queen cannot die from any cause.

The queen cannot die of old age on any difficulty. Other difficulty rules need
a separate balance pass; they must remain visible preset rules rather than
hidden assistance.

The game creates a rolling checkpoint before each major crisis, before each
season transition and every five game-days, retaining the latest three. The
load menu lets the player voluntarily choose any retained checkpoint or named
manual save. A colony is doomed only when its queen has died and it has no
gynes; that state offers restore rather than silently ending the run.

## 12. Development and review sequence

```mermaid
flowchart TD
    A[Existing playable loop] --> B[Stabilise and review current systems]
    B --> C[Alpha foundations: run policy, catalogues, saves, goals, diagnostics]
    C --> D[0-10 min: queen, first worker, Backup Roles and early automation]
    D --> E[10-20 min: decision information and readable weather crisis]
    E --> F[20-60 min: Bee Bread, selected Tier 2-3 skills and winter preparation]
    F --> G[About 60 min: winter and recovery checkpoint]
    G --> H[60-90 min: emerge, buy Gyne Rearing, raise and release gynes]
    H --> I[Closed alpha with friends and family]
    I --> J{Does the core promise work?}
    J -->|No: clarity, pacing or decisions fail| B
    J -->|Yes| K[Select one expansion pillar]

    L[First-time Dr explanations and Why? diagnostics] -. throughout .-> D
    L -. throughout .-> H
    M[Flower and environment sprite queue] -. parallel .-> D
    M -. parallel .-> I
    N[5, 10, 20, 60 and 90 minute reviews] -. evidence .-> J
```

### Sequence rules

1. Finish or consciously supersede the current stabilisation evidence before
   building a large system on top of it.
2. Reconcile `plans/design/progression.md` before implementing progression:
   Work Priorities moves from baseline to Hive Mind Tier 3; Weather Sensing
   becomes rain-only in alpha; Bee Bread and Pollinator Points use the rules
   above; Pollinator Points replace royal jelly as the universal Tier-4 gate.
3. Build catalogue/resolver/run-policy plumbing before skill content, following
   the existing progression plan's safe extension pattern.
4. Prove each new system through the shortest playable vertical path. Do not
   implement every branch before testing the first ten or twenty minutes.
5. Gyne Rearing remains Tier 4. The alpha deliberately reaches that selected
   route after winter; it does not complete every Tier-3 branch first.
6. Treat Bee Bread, Work Priorities, pollination ecology and save/checkpoint
   changes as separate high-risk systems with their own validation, not one
   bundled feature.
7. Admit implementation through `NEXTSTEPS.md` one slice at a time. This plan
   defines order and gates but is never a second queue.

## 13. Review gates

| Gate | Question that must be answered | Evidence |
| --- | --- | --- |
| Current-loop review | Are existing controls and feedback reliable enough to judge the game? | Current queue, deterministic checks and named hands-on checks. |
| 5 minutes | Can a mixed-experience player raise the first worker without step-by-step scripting? | Observation plus a short comprehension question. |
| 10 minutes | Has automation removed repetition without removing the player's decisions? | Player explanation of what they automated and why. |
| 20 minutes | Can the player diagnose and respond to the first crisis? | Actions taken, Why? usage and post-crisis explanation. |
| 60 minutes | Can the player understand production/consumption, save/resume and prepare for winter? | Economy trace, restore test and player account. |
| 90 minutes | Can the player explain victory or failure and do they want to continue? | Gyne result, short interview and observed friction. |
| Closed alpha | Do multiple players reach the same understanding through different viable organisations? | Cross-player feedback grouped by clarity, decisions, pacing, defects and desire to replay. |

Failure at a gate sends work back to the smallest system responsible. It does
not justify adding unrelated content.

## 14. Parallel non-coding and production streams

### Relaxing creative stream

Keep three to six television-friendly sprite tasks available at all times.
Start with Dandelion, Poppy and Borage state sets, then common environmental
components, bee activities, hive components, weather and finally animals or
threats. Allow occasional motivational art outside strict production order;
the procedural fallback means it must not block playability.

### Evidence and feedback stream

- internal milestone play at 5/10/20/60/90 minutes;
- friends/family observation before broad distribution;
- feedback separated into defect, confusion, pacing, decision quality and
  desired expansion;
- balance changes backed by repeatable scenario evidence where possible.

### Release stream

Before Early Access: named saves and migrations, stable distributable builds,
crash/feedback collection, accessibility review, performance budgets, asset
licence register, store page/capsules/trailer, pricing, community expectations
and a public roadmap whose promises match proven capacity.

Before 1.0: content-complete core, onboarding and difficulty coverage, broader
audio/art, localisation decision, platform/input decision, legal/ratings/tax
checks, Steam achievements/cloud/workshop decisions, and a final save-support
policy. Charity proceeds and whether to present as a studio are commercial and
legal decisions for the release stream, not alpha blockers.

## 15. Release stages

- **Current prototype:** playable core, narrow stabilisation and evidence work.
- **Internal alpha:** the full 90-minute route works with placeholder art and
  developer-supported setup.
- **Closed alpha:** friends/family can install, save, resume and provide useful
  feedback without live instruction.
- **Beta:** core systems are feature-complete; work shifts toward content,
  balance, usability, accessibility, performance and presentation rather than
  new foundations.
- **Early Access:** replayable product with transparent scope, durable saves,
  a feedback/community process and enough content to justify payment.
- **1.0:** the promised modes and content are complete, polished and supported.

## 16. Open design questions that do not block this scope

- exact Work Priorities dispatch rules and its scalable many-bee UI;
- Bee Bread recipe quantities, rationing and fermentation feedback;
- exact skill discovery milestones and costs in the 90-minute route;
- Pollinator Point window duration and seed/quality formula;
- Standard and harder difficulty rules;
- short-term-goal selection, concurrency and dismissal behaviour;
- named-save count, naming, overwrite and deletion UX;
- detailed post-alpha threat, ecosystem and environment order;
- Early Access content volume, price, demo, studio identity and charity model.

Resolve these in focused design/evidence passes when the development sequence
reaches them. They are not reasons to reopen the whole scope.

