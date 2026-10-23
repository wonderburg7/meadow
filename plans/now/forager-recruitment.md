# Forager recruitment -- Orientation flight, then Auto scouting, then Auto-recruitment

<!-- CONTEXT: plan | LAYER: immediate-task -->
Status: active | Owner: Dave / Claude Code | Next: FR-1d -- repair the diagnosed foraging behaviour | Dependency: FR-1 → FR-1b → FR-1c → FR-1d → FR-2 → PP-6 (`plans/now/pollination.md`) → FR-3 | Verified: 2026-10-23

## Objective

`plans/design/progression.md` §11 step 15 names Auto-recruitment as tier-4
content. Today it is a priced Foraging tier-4 node that switches nothing
on. Dave (14 Oct 2026) chose to make it work, as the last of three stages:
Orientation flight is the primitive way a new forager finds food, Auto
scouting replaces it, and Auto-recruitment builds on Auto scouting. Each
stage should forage measurably better than the one before, as a provisional
direction rather than a hard acceptance gate (Dave, 22 Oct 2026).

## Current state

Verified 14 Oct 2026 against master:

- Foraging tier 1 is Tarsal secretions and Orientation flight; tier 2 is
  Associative learning and Adaptive constancy; tier 3 is Weighted flower
  choice and Pollinator points; tier 4 is Nectar robbing (cut) and
  Auto-recruitment (`skills.gd`, axial `(8, 1)`, `"effects": []`). Auto
  scouting is a reserved baseline entry (`tier: 0`, `baseline: true`) that
  switches nothing on.
  `progression.gd::branch_tier_open` opens a tier only once every offered
  node of the tier below is owned.
- The behaviours are developer toggles in `game_config.gd`:
  `orientation_flight_on`, `scouting_on` (Auto scouting),
  `auto_recruitment_on`, `proximity_recruitment_on`, `floral_constancy_on`.
  `prerequisites.gd` makes `auto_recruitment_on` and `floral_constancy_on`
  need `scouting_on`, and makes Orientation flight and Auto scouting
  mutually exclusive.
- Owned skills are read through helpers in `bee_foraging.gd` (for example
  `orientation_flight_on()` at about line 636: the toggle or
  `Session.progression.is_behaviour_enabled(...)`), not pushed into
  `GameConfig`, so no save or restore order is involved. The recruitment
  code itself reads `GameConfig.scouting_on or
  GameConfig.auto_recruitment_on` directly in about eight places in
  `bee_foraging.gd` -- a per-trip path (`.claude/rules/performance.md`).
- Recruitment already passes the mentor's species to a seeker, but only
  under `floral_constancy_on` (`hive.gd`, the entrance mentor queue).
- Challenges 1 and 2 are the two `levels.gd` rows without `"seed_set"`;
  every row already carries an empty `skill_bans` list.

## Open slices

| Slice | What it does | Files it owns | Startable | Level |
| --- | --- | --- | --- | --- |
| FR-1d | Repair the concrete defects FR-1c establishes | `scripts/bee_foraging.gd`, focused tests/scenarios, this plan | claimed -- implementation awaits high-risk review/integration | high |
| FR-2 | Auto scouting becomes a Foraging tier-2 purchase that replaces Orientation flight | `scripts/skills.gd`, `scripts/bee_foraging.gd`, `scripts/skill_tree_panel.gd`, `scripts/levels.gd`, `tests/source_checks.py`, tests | no -- after FR-1d; numeric targets are provisional | high |
| FR-3 | owning Auto-recruitment switches it on, passing species with Adaptive constancy | `scripts/skills.gd`, `scripts/bee_foraging.gd`, `scripts/hive.gd`, `scripts/game_config.gd`, `scripts/levels.gd`, tests | no -- after PP-6 | high |

**Dependencies.** FR-1 changes no game file. FR-2 waits for FR-1's table;
if a stage is not better than the one before, a tuning slice (FR-1b) is
specified from FR-1's numbers before FR-2, and if tuning cannot fix the
order the work stops for Dave (decision 3). Dave authorised behaviour
diagnosis/fix on 22 Oct 2026, retaining stage order and 30% as loose targets
because upcoming rebalancing may change the figures substantially. FR-1c
diagnoses through the harness while CQ-L1 owns `bee_foraging.gd`; FR-1d
applies the evidenced repair once that ownership clears. Both precede FR-2.
Auto scouting sits on the gyne
route (decision 1), so PP-6 (`plans/now/pollination.md`) prices the route
only after FR-2 lands, and AR-4 (`plans/now/alpha-route-evidence.md`)
still waits for PP-6. FR-3 shares `skills.gd` with PP-6, so it follows it.
HP-1 (`plans/archive/hot-path-cadence_2026-10-18.md`) moves SEARCHING's flower check onto
the think tick; if it lands after FR-1, it re-runs FR-1's table and stops
if the stage order changes.

**Reads.** A slice reads its own section and the durable rules below; FR-2
and FR-3 also read `.claude/rules/performance.md`.

## Durable rules

<!-- LAYER: durable-rules -->

Decisions (Dave, 14 Oct 2026):

1. **Auto scouting is a Foraging tier-2 node**, beside Associative
   learning and Adaptive constancy, with `all_of: [ORIENTATION_FLIGHT]`;
   Auto-recruitment gains `all_of: [AUTO_SCOUTING]`. Because tier 3 opens
   only once every tier-2 node is owned, every Colony Run reaching
   Pollinator points owns Auto scouting: it is on the gyne route and PP-6
   prices it.
2. **The three stages read as one progression.** Node placement draws the
   chain (Orientation flight `(3, -1)` → Auto scouting on a free tier-2
   hex on that side → Auto-recruitment, moved if needed so the generated
   connect tiles form one line; `progression.md` §8.3's validation catches
   collisions). Node text says what each stage improves on. Once Auto
   scouting is owned, Orientation flight's panel says it has been replaced,
   for example "Replaced by Auto scouting: new foragers now scout for
   themselves." Auto-recruitment adds to Auto scouting; it replaces
   nothing.
3. **Aim for each stage to forage better than the one before**, measured as
   food (nectar plus pollen) delivered per forager per day on the same
   seeds. FR-1 measures first. A stage that is not better gets a tuning
   sweep of its existing `GameConfig` values; if tuning cannot fix the
   order, stop and bring Dave the options. **22 Oct 2026 update:** Dave
   authorised a behaviour diagnosis/fix slice; stage order is a loose target,
   not a hard acceptance gate while rebalancing remains ahead.
4. **Aim for strong Auto-recruitment**: around 30% more food per forager than
   Auto scouting alone on the post-winter mixed meadow, with a visible
   queue of seekers and mentors at the entrance within a day or two of
   buying it. **22 Oct 2026 update:** retain this direction provisionally;
   report results honestly without tuning solely to force the numeric target.
5. **With Adaptive constancy also owned, a mentor passes her species** as
   well as her patch: the existing species-passing path reads Adaptive
   constancy's ownership as well as `floral_constancy_on`.
6. **Colony Run and Scenarios only.** Challenges 1 and 2 ban Auto scouting
   and Auto-recruitment through their `skill_bans`, so their authored
   stages and hands-on checks stand (seed set's precedent,
   `product-scope.md` §10).
7. **Must not change:** the developer toggles keep working on their own
   for runs that set them; turning a stage on by ownership never writes
   `GameConfig`; no new save field (ownership is already saved).

FR-1 shipped 2026-10-17; its specification is `plans/archive/FR-1_2026-10-17.md`.

FR-1b shipped 2026-10-22; its specification is `plans/archive/FR-1b_2026-10-22.md`.

FR-1c shipped 2026-10-22; its specification is `plans/archive/FR-1c_2026-10-22.md`.

## FR-1d -- repair the diagnosed foraging behaviour

<!-- LAYER: design -->
Level: high

**Implementation status, 23 Oct 2026:** implemented on `codex/FR-1d`;
awaiting high-risk review and integration. Do not claim or implement it again.

Dave authorised this behaviour repair on 22 Oct. Scouts now leave through
`_leave_hive_and_resume` when the entrance queue has no valid same-resource
mentor, and resume their remaining bouts. A scout already waiting also
leaves if her matching mentor disappears or is taken by another seeker.
Matching uses the existing validity/resource contract. Established low-rate
seekers retain the full wait and timeout reset; mentors retain their wait.
Grace, settlement, species preferences, both recruitment modes and developer
toggles retain their existing semantics. No balance or save fields changed.

**Causal checks and profiling.** The real-bee Godot fixture first failed
exactly six assertions against the unchanged runtime: empty, wrong-resource
and freed-mentor queues, each for nectar and pollen. All 33 assertions then
passed after the guard. Expanded coverage passes 40 assertions, including
mentor death during a wait, mentor timeout, grace/third-bout settlement,
explicit species with species passing off/on, tipsiness, and a completed
proximity dance. The wrapper fails on script errors as well as assertions.
A synthetic profile of 1,000 exit calls on one real bee with an empty queue
took 33,931 microseconds before the repair and 17,053 after. This measures
that fixture, not colony-wide performance. No index, cache or new per-frame
system was added; the new scan runs only for a scout at the door.

**Fresh paired campaign.** Baseline commit: `8946f8d4c01e6f12fb54bd60008f5c16c2e2c823`.
Measured source fingerprints: before `56f0e8824ac2e7a491d7ca58feb1ebd7035a0f0e067b3cf0577f7fdaf137f6ae`;
after `55abbd962d5f433a1c258e2bf65173f20ce3c5b71325a4aaa43b17b9d675f9db`.
Both runs use the same source baseline plus this guard, Godot 4.7.2, fixed
30 fps, unchanged FR-1b defaults, the settled 15-cell colony with 8 nectar
and 3 pollen foragers, the same skills, and complete days 1--20. Every one
of the 40 runs passed and reached day 20. Food is nectar plus pollen
delivered / (20 days x 11 starting foragers). Seed order: 7, 555, 2026,
12345, 90210. Runtime fingerprints are retained in the local measurement
manifests; only explanatory comments changed after the after-run began.

| Stage | Before median | After median | After / preceding stage |
| --- | ---: | ---: | ---: |
| Orientation flight | 6.0133 | 6.0133 | -- |
| Auto scouting | 5.8454 | 5.8454 | 0.972x |
| Auto scouting + Auto-recruitment | 4.7757 | 5.1949 | 0.889x |
| Auto scouting + Auto-recruitment + species passing | 3.3102 | 3.2064 | 0.617x |

| Stage | Before, by seed | After, by seed |
| --- | --- | --- |
| Orientation flight | 4.8253, 6.0133, 8.3810, 4.8707, 6.3986 | 4.8253, 6.0133, 8.3810, 4.8707, 6.3986 |
| Auto scouting | 4.4272, 7.4413, 9.2718, 5.1354, 5.8454 | 4.4272, 7.4413, 9.2718, 5.1354, 5.8454 |
| Auto scouting + Auto-recruitment | 3.2282, 6.4012, 7.8084, 3.0379, 4.7757 | 3.9537, 5.1949, 8.9151, 5.5395, 5.1372 |
| Auto scouting + Auto-recruitment + species passing | 3.0415, 2.5565, 5.0416, 3.3543, 3.3102 | 2.9787, 3.4482, 3.2064, 3.5612, 2.8479 |

Orientation flight and Auto scouting are identical on every seed. The
Auto-recruitment median rises 8.8%, but effects vary by seed; species
passing falls 3.1%. Median sampled seeker occupancy falls from 0.8333 to
0 for recruitment, and from 0.6667 to 0 for species passing; these samples
are not exact dwell times. Recruitment remains 11.1% below Auto scouting,
rather than 30% above it; stage order also remains unmet. Those targets
remain loose guidance. This repair proves the avoidable wait, not a general
foraging improvement or a species-selection defect; do not broaden it into
speculative selection changes or tune to force the target.

**Validation:** focused Godot regressions and `tools/prefinish.py` pass
(boot, 106-script source checks, 11 tests in four affected modules).
`tools/verify.ps1 -Scope branch` passes: 145 test groups, zero failures,
15 balance checks, 148-file lint, source checks, boot and generated checks.
The game-test phase took 735 seconds on three workers.

**Integration ownership blocker:** verification regenerated seven line-number
entries in FUNCTION_MAP.md for the moved foraging helpers. The owner check
assigns that generated file to Claude's queued CQ-S0b. Codex restored only
its automatic map edit and excludes it from this branch's commit. Claude
must resolve that shared-file ownership, regenerate the map against the
final sources and include it during review/integration. The green verify
includes that automatic regeneration; the committed map is intentionally
still at the baseline. Investigate the missing generated-file dependency
in FR-1d's Files declaration so future claims detect this overlap before
implementation. No other lane's source or queue was edited.
Local raw evidence lives in the ignored build directories fr1d-before and
fr1d-after, each with a measurement.json manifest and per-run artefacts.
The tables above preserve the reviewable measurements in Git. Reproduce a
campaign with `tools.forager_tuning.measure(DEFAULTS, output, fingerprint(),
None, 2)` from Python, using that module's defaults and fingerprint; it runs
all four stages on all five seeds at fixed 30 fps.

**Hands-on check for integration:** start a Colony Run with Auto scouting
and Auto-recruitment enabled. With no matching mentor at the door, watch a
scout resume her next bout; an established low-rate seeker should retain
her entrance wait. This is a visual check, not an integration gate.

**Successor:** FR-2 remains blocked until this runtime repair is reviewed
and integrated; it still needs its full specification and queue block.

```queue
**[Codex] FR-1d -- repair the diagnosed foraging behaviour**
- Plan: `plans/now/forager-recruitment.md` -- "FR-1d -- repair the diagnosed foraging behaviour"
- Files: `scripts/bee_foraging.gd`, `tests/test_forager_behaviour.py`, `tests/fr1d_forager_behaviour_test.gd`, `test_scenarios/fr1d_forager_behaviour_test.json`, `plans/now/forager-recruitment.md`
- Check: causal regression checks and the five-seed comparison pass; `tools/prefinish.py` and `tools/verify.ps1` are green; provisional target misses are documented
- Proof: `present: plans/now/forager-recruitment.md :: Next: FR-1d -- repair the diagnosed foraging behaviour`
- Next after: FR-2 -- Auto scouting becomes a Foraging tier-2 purchase that replaces Orientation flight
```

## Not in the queue, and why

- **FR-2:** waits for FR-1d's behaviour fix; its numeric targets are provisional.

## FR-2 -- Auto scouting becomes a Foraging tier-2 purchase that replaces Orientation flight

<!-- LAYER: design -->

Decisions 1, 2, 6 and 7. FR-2 promotes the reserved `AUTO_SCOUTING` entry
(`skills.gd`, today `tier: 0`, `baseline: true`, per `progression.md` §5.7's
superseded 1 Sep decision) to a tier-2 node with `enable_behaviour`
`scouting_on`; the `bee_foraging.gd` helpers make owned
Auto scouting switch Orientation flight's behaviour off, and the direct
`GameConfig.scouting_on` reads go through a helper (measure the per-trip
cost first). Its recipe is a placeholder until PP-6 prices it.
`tests/source_checks.py` uses Auto scouting as its example baseline skill
(`BASELINE_SKILL`); FR-2 moves that check to another baseline entry. Specified
fully, with its queue block, once FR-1's table is in.

## FR-3 -- owning Auto-recruitment switches it on, passing species with Adaptive constancy

<!-- LAYER: design -->

Decisions 4, 5, 6 and 7. Auto-recruitment's `enable_behaviour`
`auto_recruitment_on`, read through a helper as FR-2's are; species passing
under Adaptive constancy; a sweep of the `recruit_*` values in
`game_config.gd` to decision 4's gain, which also prices the node.
Specified fully once PP-6 lands.
