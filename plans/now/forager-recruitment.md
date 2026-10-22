# Forager recruitment -- Orientation flight, then Auto scouting, then Auto-recruitment

<!-- CONTEXT: plan | LAYER: immediate-task -->
Status: active | Owner: Dave / Claude Code | Next: FR-1b -- tune the measured foraging-stage order | Dependency: FR-1 → FR-1b → FR-2 → PP-6 (`plans/now/pollination.md`) → FR-3 | Verified: 2026-10-17

## Objective

`plans/design/progression.md` §11 step 15 names Auto-recruitment as tier-4
content. Today it is a priced Foraging tier-4 node that switches nothing
on. Dave (14 Oct 2026) chose to make it work, as the last of three stages:
Orientation flight is the primitive way a new forager finds food, Auto
scouting replaces it, and Auto-recruitment builds on Auto scouting. Each
stage must forage measurably better than the one before.

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
| FR-2 | Auto scouting becomes a Foraging tier-2 purchase that replaces Orientation flight | `scripts/skills.gd`, `scripts/bee_foraging.gd`, `scripts/skill_tree_panel.gd`, `scripts/levels.gd`, `tests/source_checks.py`, tests | no -- after FR-1b tunes the stage order FR-1 measured (FR-1 landed 17 Oct 2026) | high |
| FR-3 | owning Auto-recruitment switches it on, passing species with Adaptive constancy | `scripts/skills.gd`, `scripts/bee_foraging.gd`, `scripts/hive.gd`, `scripts/game_config.gd`, `scripts/levels.gd`, tests | no -- after PP-6 | high |

**Dependencies.** FR-1 changes no game file. FR-2 waits for FR-1's table;
if a stage is not better than the one before, a tuning slice (FR-1b) is
specified from FR-1's numbers before FR-2, and if tuning cannot fix the
order the work stops for Dave (decision 3). Auto scouting sits on the gyne
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
3. **Each stage must forage better than the one before**, measured as
   food (nectar plus pollen) delivered per forager per day on the same
   seeds. FR-1 measures first. A stage that is not better gets a tuning
   sweep of its existing `GameConfig` values; if tuning cannot fix the
   order, stop and bring Dave the options.
4. **Auto-recruitment is strong**: at least 30% more food per forager than
   Auto scouting alone on the post-winter mixed meadow, with a visible
   queue of seekers and mentors at the entrance within a day or two of
   buying it.
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

## FR-1b -- tune the measured foraging-stage order

<!-- LAYER: immediate-task -->
Level: medium

Use the FR-1 scenario and its five seeds to sweep the existing `GameConfig`
foraging values, without adding a new behaviour or save field. Find a
configuration in which each row is better than its predecessor and
Auto-recruitment is at least 30% above Auto scouting; record the resulting
table and selected values here. If no existing-value combination can meet
both conditions, stop for Dave with the failed sweep evidence and choices.

```queue
**[Codex] FR-1b -- tune the measured foraging-stage order**
- Plan: `plans/now/forager-recruitment.md` -- "FR-1b -- tune the measured foraging-stage order"
- Files: `tools/forager_tuning.py`, `tests/test_forager_tuning.py`, `test_scenarios/fr1_forager_stages_test.json`, `plans/now/forager-recruitment.md`
- Check: `python -m unittest tests.test_forager_tuning` passes; `python tools/forager_tuning.py` records the five-seed stage table and chosen existing values in this section; `tools/verify.ps1` is green
- Proof: `present: plans/now/forager-recruitment.md :: Next: FR-1b -- tune the measured foraging-stage order`
- Next after: FR-2 -- Auto scouting becomes a Foraging tier-2 purchase that replaces Orientation flight
```

**Execution, 22 Oct 2026:** `codex/FR-1b`, baseline `9f6c4c9b905d34c41645243ae118bb16c2da52b2`.
Tool/tests/evidence are implemented; the slice awaits Dave. The FR-1 fixture is unchanged.

**Result:** 35 complete configurations plus three first-gate screens, on the same five seeds.
Scouting loses at all eight radii (best 0.972x); recruitment's best is 1.249x at radius 1500,
which still loses at the other transitions. The recruitment-only wait/threshold grid was
skipped because it cannot repair the first gate. Spread/grace were refined at the two
strongest initial configurations. This finite sweep does not prove global impossibility.

**Validation:** nine focused tests, `tools/prefinish.py` and `tools/verify.ps1` pass
(47 unit-test modules, zero failures). `python tools/forager_tuning.py` reproduces the table
and returns 2 (decision required).

**Decision needed (Dave):** recommendation: keep the stage-order and 30% requirements and
authorise a behaviour diagnosis/fix slice, with simulation evidence and high-risk review.
Alternatively, broaden existing-value tuning: another campaign, with no guaranteed success.
Record Dave's choice here before specifying/admitting a follow-up. FR-2 remains blocked;
neither option is chosen or queued.

<!-- FR-1b tuning evidence -->
### Tuning sweep evidence

Simulation fingerprint: `3ddc0ab91e72468d79fb4a1ecc5155a6b72acb72f061e49e562e620b5f2aa08d`. Seeds: 7, 555, 2026, 12345, 90210.
Window: days 1–20; food is nectar plus pollen delivered / (20 days × 11 starting foragers).
Each candidate uses the same settings for all four stages; only FR-1's stage toggles differ.

Search: five full start-radius trials and three intermediate radii screened on the first two stages;
wait × threshold-band sweep at every radius where scouting improves;
then spread × grace refinement of the two strongest distinct candidates.
The finite sweep does not prove that no other real-valued combination could work.
Closest means the strongest minimum of scouting/orientation, recruitment/scouting ÷ 1.3,
and species-passing/recruitment; ties favour recruitment's median food delivery.

Measured 35 distinct configurations. **DECISION REQUIRED**: no measured configuration meets both requirements; FR-2 remains blocked.

Closest measured values (not selected for gameplay):

```json
{
  "forage_start_radius": 100.0,
  "recruit_wait_seconds": 15.0,
  "recruit_lower_threshold_nectar": 0.27,
  "recruit_upper_threshold_nectar": 0.45,
  "recruit_lower_threshold_pollen": 0.23,
  "recruit_upper_threshold_pollen": 0.31,
  "recruit_start_point_jitter": 0.0,
  "recruit_grace_trips": 6.0
}
```

| Stage | Median food per forager per day | Per seed (7, 555, 2026, 12345, 90210) | vs previous |
| --- | --- | --- | --- |
| Orientation flight | 6.1244 | 3.7818, 6.1244, 9.3467, 4.8748, 6.3908 | -- |
| Auto scouting | 5.0407 | 4.4881, 6.2172, 9.2036, 4.5676, 5.0407 | 0.82x |
| Auto scouting + Auto-recruitment | 4.6053 | 4.1810, 6.2677, 7.3469, 4.1698, 4.6053 | 0.91x |
| Auto scouting + Auto-recruitment + species passing | 3.6055 | 2.7908, 3.6504, 4.0347, 3.6055, 2.6889 | 0.78x |

All candidates below use those same five seeds. Ratios are rounded for display only.

| Candidate | Radius | Wait | Nectar band | Pollen band | Spread | Grace | Stage medians | Ratios | Pass |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | 100.0 | 15.0 | 0.27/0.45 | 0.23/0.31 | 150.0 | 3.0 | 6.1244, 5.0407, 4.3363, 3.0767 | 0.823x, 0.860x, 0.710x | False |
| 2 | 200.0 | 15.0 | 0.27/0.45 | 0.23/0.31 | 150.0 | 3.0 | 6.2090, 5.2680, 4.2417, 3.7423 | 0.848x, 0.805x, 0.882x | False |
| 3 | 450.0 | 15.0 | 0.27/0.45 | 0.23/0.31 | 150.0 | 3.0 | 6.0133, 5.8454, 4.7757, 3.3102 | 0.972x, 0.817x, 0.693x | False |
| 4 | 900.0 | 15.0 | 0.27/0.45 | 0.23/0.31 | 150.0 | 3.0 | 6.6756, 5.6522, 4.8397, 3.3977 | 0.847x, 0.856x, 0.702x | False |
| 5 | 1500.0 | 15.0 | 0.27/0.45 | 0.23/0.31 | 150.0 | 3.0 | 5.7432, 4.2451, 5.3021, 3.3684 | 0.739x, 1.249x, 0.635x | False |
| 6 | 100.0 | 15.0 | 0.27/0.45 | 0.23/0.31 | 0.0 | 0.0 | 6.1244, 5.0407, 4.3098, 3.0113 | 0.823x, 0.855x, 0.699x | False |
| 7 | 100.0 | 15.0 | 0.27/0.45 | 0.23/0.31 | 0.0 | 1.0 | 6.1244, 5.0407, 4.7557, 3.0767 | 0.823x, 0.943x, 0.647x | False |
| 8 | 100.0 | 15.0 | 0.27/0.45 | 0.23/0.31 | 0.0 | 3.0 | 6.1244, 5.0407, 4.5459, 3.0767 | 0.823x, 0.902x, 0.677x | False |
| 9 | 100.0 | 15.0 | 0.27/0.45 | 0.23/0.31 | 0.0 | 6.0 | 6.1244, 5.0407, 4.6053, 3.6055 | 0.823x, 0.914x, 0.783x | False |
| 10 | 100.0 | 15.0 | 0.27/0.45 | 0.23/0.31 | 75.0 | 0.0 | 6.1244, 5.0407, 4.3098, 3.0113 | 0.823x, 0.855x, 0.699x | False |
| 11 | 100.0 | 15.0 | 0.27/0.45 | 0.23/0.31 | 75.0 | 1.0 | 6.1244, 5.0407, 4.7557, 3.0767 | 0.823x, 0.943x, 0.647x | False |
| 12 | 100.0 | 15.0 | 0.27/0.45 | 0.23/0.31 | 75.0 | 3.0 | 6.1244, 5.0407, 4.3363, 3.0767 | 0.823x, 0.860x, 0.710x | False |
| 13 | 100.0 | 15.0 | 0.27/0.45 | 0.23/0.31 | 75.0 | 6.0 | 6.1244, 5.0407, 4.6053, 3.6055 | 0.823x, 0.914x, 0.783x | False |
| 14 | 100.0 | 15.0 | 0.27/0.45 | 0.23/0.31 | 150.0 | 0.0 | 6.1244, 5.0407, 4.3098, 3.0113 | 0.823x, 0.855x, 0.699x | False |
| 15 | 100.0 | 15.0 | 0.27/0.45 | 0.23/0.31 | 150.0 | 1.0 | 6.1244, 5.0407, 4.7557, 3.0767 | 0.823x, 0.943x, 0.647x | False |
| 16 | 100.0 | 15.0 | 0.27/0.45 | 0.23/0.31 | 150.0 | 6.0 | 6.1244, 5.0407, 4.6053, 3.6055 | 0.823x, 0.914x, 0.783x | False |
| 17 | 100.0 | 15.0 | 0.27/0.45 | 0.23/0.31 | 300.0 | 0.0 | 6.1244, 5.0407, 4.3098, 3.0113 | 0.823x, 0.855x, 0.699x | False |
| 18 | 100.0 | 15.0 | 0.27/0.45 | 0.23/0.31 | 300.0 | 1.0 | 6.1244, 5.0407, 4.7557, 3.0767 | 0.823x, 0.943x, 0.647x | False |
| 19 | 100.0 | 15.0 | 0.27/0.45 | 0.23/0.31 | 300.0 | 3.0 | 6.1244, 5.0407, 4.3363, 3.0767 | 0.823x, 0.860x, 0.710x | False |
| 20 | 100.0 | 15.0 | 0.27/0.45 | 0.23/0.31 | 300.0 | 6.0 | 6.1244, 5.0407, 4.6053, 3.6055 | 0.823x, 0.914x, 0.783x | False |
| 21 | 900.0 | 15.0 | 0.27/0.45 | 0.23/0.31 | 0.0 | 0.0 | 6.6756, 5.6522, 5.0499, 3.6726 | 0.847x, 0.893x, 0.727x | False |
| 22 | 900.0 | 15.0 | 0.27/0.45 | 0.23/0.31 | 0.0 | 1.0 | 6.6756, 5.6522, 4.4389, 3.4405 | 0.847x, 0.785x, 0.775x | False |
| 23 | 900.0 | 15.0 | 0.27/0.45 | 0.23/0.31 | 0.0 | 3.0 | 6.6756, 5.6522, 4.3077, 3.3977 | 0.847x, 0.762x, 0.789x | False |
| 24 | 900.0 | 15.0 | 0.27/0.45 | 0.23/0.31 | 0.0 | 6.0 | 6.6756, 5.6522, 4.8908, 3.4658 | 0.847x, 0.865x, 0.709x | False |
| 25 | 900.0 | 15.0 | 0.27/0.45 | 0.23/0.31 | 75.0 | 0.0 | 6.6756, 5.6522, 4.8226, 3.6726 | 0.847x, 0.853x, 0.762x | False |
| 26 | 900.0 | 15.0 | 0.27/0.45 | 0.23/0.31 | 75.0 | 1.0 | 6.6756, 5.6522, 4.4389, 3.4405 | 0.847x, 0.785x, 0.775x | False |
| 27 | 900.0 | 15.0 | 0.27/0.45 | 0.23/0.31 | 75.0 | 3.0 | 6.6756, 5.6522, 4.3077, 3.3977 | 0.847x, 0.762x, 0.789x | False |
| 28 | 900.0 | 15.0 | 0.27/0.45 | 0.23/0.31 | 75.0 | 6.0 | 6.6756, 5.6522, 4.8908, 3.4658 | 0.847x, 0.865x, 0.709x | False |
| 29 | 900.0 | 15.0 | 0.27/0.45 | 0.23/0.31 | 150.0 | 0.0 | 6.6756, 5.6522, 4.8226, 3.6726 | 0.847x, 0.853x, 0.762x | False |
| 30 | 900.0 | 15.0 | 0.27/0.45 | 0.23/0.31 | 150.0 | 1.0 | 6.6756, 5.6522, 4.8397, 3.4405 | 0.847x, 0.856x, 0.711x | False |
| 31 | 900.0 | 15.0 | 0.27/0.45 | 0.23/0.31 | 150.0 | 6.0 | 6.6756, 5.6522, 4.8908, 3.4658 | 0.847x, 0.865x, 0.709x | False |
| 32 | 900.0 | 15.0 | 0.27/0.45 | 0.23/0.31 | 300.0 | 0.0 | 6.6756, 5.6522, 5.5783, 3.6726 | 0.847x, 0.987x, 0.658x | False |
| 33 | 900.0 | 15.0 | 0.27/0.45 | 0.23/0.31 | 300.0 | 1.0 | 6.6756, 5.6522, 4.4389, 3.4803 | 0.847x, 0.785x, 0.784x | False |
| 34 | 900.0 | 15.0 | 0.27/0.45 | 0.23/0.31 | 300.0 | 3.0 | 6.6756, 5.6522, 4.3113, 3.4405 | 0.847x, 0.763x, 0.798x | False |
| 35 | 900.0 | 15.0 | 0.27/0.45 | 0.23/0.31 | 300.0 | 6.0 | 6.6756, 5.6522, 4.8908, 3.4658 | 0.847x, 0.865x, 0.709x | False |

Intermediate-radius first-gate screen (same colony, window and five seeds):

| Radius | Orientation flight, per seed | Auto scouting, per seed | Median ratio |
| --- | --- | --- | --- |
| 300.0 | 3.7116, 6.4056, 10.3514, 4.4215, 5.8965 | 3.4424, 7.3864, 9.6604, 3.6840, 4.4988 | 0.763x |
| 600.0 | 4.1619, 6.5401, 9.3422, 4.0412, 5.7033 | 4.5312, 7.2857, 9.1263, 4.7965, 5.4155 | 0.950x |
| 1200.0 | 4.6242, 7.4350, 8.8194, 5.2880, 6.4079 | 5.7209, 6.6850, 7.9340, 5.3640, 5.4817 | 0.893x |
<!-- /FR-1b tuning evidence -->


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
