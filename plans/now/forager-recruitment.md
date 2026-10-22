# Forager recruitment -- Orientation flight, then Auto scouting, then Auto-recruitment

<!-- CONTEXT: plan | LAYER: immediate-task -->
Status: active | Owner: Dave / Claude Code | Next: FR-1d -- repair the diagnosed foraging behaviour | Dependency: FR-1 → FR-1b → FR-1c → FR-1d → FR-2 → PP-6 (`plans/now/pollination.md`) → FR-3 | Verified: 2026-10-22

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
| FR-1c | Diagnose foraging-stage behaviour in the existing headless harness | `tools/forager_diagnosis.py`, `tests/test_forager_diagnosis.py`, this plan | yes -- no runtime-source ownership | high |
| FR-1d | Repair the concrete defects FR-1c establishes | `scripts/bee_foraging.gd`, focused tests/scenarios, this plan | no -- after FR-1c and CQ-L1 releases `scripts/bee_foraging.gd` | high |
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

## FR-1c -- diagnose foraging-stage behaviour

<!-- LAYER: immediate-task -->
Level: high

Dave authorised this slice on 22 Oct 2026. Keep stage order and recruitment's
30% uplift as provisional direction: rebalancing may change them substantially.
Diagnose concrete behaviour defects through the existing harness and logs;
do not chase an exact ratio. Runtime repair is FR-1d because CQ-L1 currently
owns `bee_foraging.gd`. This split advances the independent causal work while
preserving both lanes' ownership. No runtime, save, skill-tree or balance edits.

**Starting evidence (FR-1b's default radius 450, five seeds):** queue recruitment
made 0, 4, 2, 0, 0 matches, while the species-passing row made 1, 0, 1, 1, 0.
Scouting settled 4, 10, 11, 5, 7 foragers; recruitment settled 3, 9, 10, 3, 7;
species passing settled 1, 3, 6, 2, 3. These counts establish sparse matching
and slower settlement, not their cause. Existing `report.json` summaries and
session logs and a manifest of all 20 baseline cases are preserved under
`build/forager-evidence/fr1b-baseline` in the primary checkout, outside the
disposable worktree. The full sweep figures are preserved there as well.

**Diagnosis and scope:** use the five pinned seeds and unchanged FR-1 colony.
Isolate the cost of searching several patches, entrance waits when no mentor
is available, the patch actually scored versus the point later inherited,
and species restrictions during scouting. The fourth FR-1 row enables
`floral_constancy_on`, changing species sampling as well as mentor passing;
its whole delivery loss cannot be attributed to passing alone. Confirm causes
with controlled existing-value overlays and focused deterministic tests.
Record call/event rate and population relevant to the repair. Distinguish
proven causes, correlations and hypotheses that need a runtime probe in FR-1d.

**Acceptance:** a reproducible diagnosis report records the default five-seed
stage table plus controlled wait-cost and species-restriction comparisons,
per-seed delivery/matching/settlement counts and limitations. Test overlay
fairness, extraction and paired comparisons. State the smallest evidenced
repair to carry into FR-1d and any remaining causal probe; missing provisional
order/30% targets alone is not failure. Run focused tests, `tools/prefinish.py`
and verification. Keep original evidence archived and game source unchanged.

**Result, 22 Oct 2026:** implemented on `codex/FR-1c`, baseline
`349cb34fb18d92805fba3d7f8d1d0d805f09b6ed`. The source fingerprint matched
FR-1b, so its 20 preserved baseline cases were reused; 20 new controlled runs
were measured. Raw scenarios, verdicts, reports and logs survive under
`build/forager-evidence/fr1c-diagnosis` in the primary checkout. Reproduce with
`python tools/forager_diagnosis.py`; it regenerates cases when a matching
baseline manifest is unavailable, rather than reusing incompatible inputs.

**Conclusions:** with mentors disabled in both controls, reducing wait from
15s to 1s increases food on all five seeds (paired +3.0% to +30.5%, median
+13.8%): waiting can impose a cost with no information benefit. In normal
recruitment the global reduction instead loses 16.7% on seed 555 and reduces
its matches from four to zero. Keep the global default; investigate avoiding
unproductive early-scout waits while preserving useful mentor opportunities.

Species restrictions reduce food on all seeds with recruitment disabled
(paired median -45.1%). Under those same restrictions, enabling recruitment
has paired median +3.1%, with mixed per-seed results. The old fourth row is
a combined constancy/recruitment measurement, not a clean species-passing
comparison. Do not remove deliberate player preferences or constancy to force
a target. FR-3 must measure its actual ownership-gated passing independently.

The baseline has 11 initial foragers and 11–13 at sampled peaks, with roughly
3–10 nonempty delivery events per simulated minute across controls. These
are population/event measurements, not an exact profile of `_score_trip` or
entrance calls; FR-1d still profiles its affected path before editing it.
Patch-selection correctness remains unproven because standard logs do not
record each bout's sampled flowers against its eventual inherited point.

Seven focused diagnosis tests pass, including control fairness, seed identity,
complete-window checks and cache replay. Final prefinish/verification results
and any ownership blocker are recorded at closeout.

```queue
**[Codex] FR-1c -- diagnose foraging-stage behaviour**
- Plan: `plans/now/forager-recruitment.md` -- "FR-1c -- diagnose foraging-stage behaviour"
- Files: `tools/forager_diagnosis.py`, `tests/test_forager_diagnosis.py`, `plans/now/forager-recruitment.md`
- Check: focused diagnosis tests pass; five-seed default and controlled reports are recorded in the slice; `tools/prefinish.py` and `tools/verify.ps1` are green
- Proof: `present: plans/now/forager-recruitment.md :: Next: FR-1c -- diagnose foraging-stage behaviour`
- Next after: FR-1d -- repair the diagnosed foraging behaviour
```

<!-- FR-1c diagnosis evidence -->
### FR-1c controlled diagnosis

Simulation fingerprint: `3ddc0ab91e72468d79fb4a1ecc5155a6b72acb72f061e49e562e620b5f2aa08d`. Seeds: 7, 555, 2026, 12345, 90210.
Same FR-1 colony, default radius 450, days 1–20, fixed FPS 30; food / (20 × 11 starting foragers).
Only the stated toggles/wait/mentor-eligibility overrides differ. No gameplay setting is selected.

| Case | Median food | Food per seed | Matches per seed | Settled per seed |
| --- | --- | --- | --- | --- |
| Orientation flight | 6.0133 | 4.8253, 6.0133, 8.3810, 4.8707, 6.3986 | 0, 0, 0, 0, 0 | 0, 0, 0, 0, 0 |
| Auto scouting | 5.8454 | 4.4272, 7.4413, 9.2718, 5.1354, 5.8454 | 0, 0, 0, 0, 0 | 4, 10, 11, 5, 7 |
| Auto scouting + Auto-recruitment | 4.7757 | 3.2282, 6.4012, 7.8084, 3.0379, 4.7757 | 0, 4, 2, 0, 0 | 3, 9, 10, 3, 7 |
| Auto scouting + Auto-recruitment + species passing | 3.3102 | 3.0415, 2.5565, 5.0416, 3.3543, 3.3102 | 1, 0, 1, 1, 0 | 1, 3, 6, 2, 3 |
| Recruitment, 1-second wait | 5.3307 | 3.4196, 5.3307, 8.1507, 5.2945, 5.5633 | 0, 0, 1, 1, 0 | 3, 6, 10, 6, 7 |
| No mentors, 15-second wait | 4.8362 | 3.0560, 6.4852, 8.1242, 4.4231, 4.8362 | 0, 0, 0, 0, 0 | 3, 9, 11, 5, 7 |
| No mentors, 1-second wait | 6.3133 | 3.6356, 7.2724, 8.3696, 5.0330, 6.3133 | 0, 0, 0, 0, 0 | 3, 8, 9, 6, 7 |
| Scouting with species restrictions, no recruitment | 3.2074 | 2.9822, 3.0277, 3.6699, 3.2543, 3.2074 | 0, 0, 0, 0, 0 | 5, 3, 4, 2, 3 |

Paired food changes (each seed compared with itself):

| Controlled comparison | Per-seed change | Median paired change |
| --- | --- | --- |
| Wait 1s vs 15s, recruitment enabled | +5.9%, -16.7%, +4.4%, +74.3%, +16.5% | +5.9% |
| Wait 1s vs 15s, mentors disabled in both | +19.0%, +12.1%, +3.0%, +13.8%, +30.5% | +13.8% |
| Species restrictions on vs off, recruitment disabled in both | -32.6%, -59.3%, -60.4%, -36.6%, -45.1% | -45.1% |
| Recruitment on vs off, species restrictions enabled in both | +2.0%, -15.6%, +37.4%, +3.1%, +3.2% | +3.1% |

Queue/population samples (means are sampled occupancy, not exact dwell time):

| Case | Peak foragers per seed | Mean seekers per seed | Mean mentors per seed | Delivery events/min per seed |
| --- | --- | --- | --- | --- |
| Orientation flight | 13, 12, 13, 12, 12 | 0.00, 0.00, 0.00, 0.00, 0.00 | 0.00, 0.00, 0.00, 0.00, 0.00 | 6.15, 6.93, 8.98, 5.52, 7.25 |
| Auto scouting | 12, 12, 13, 12, 13 | 0.00, 0.00, 0.00, 0.00, 0.00 | 0.00, 0.00, 0.00, 0.00, 0.00 | 5.67, 8.35, 9.93, 6.15, 6.93 |
| Auto scouting + Auto-recruitment | 12, 12, 12, 12, 12 | 0.56, 1.06, 0.89, 0.56, 0.83 | 0.39, 0.50, 0.67, 0.11, 0.39 | 4.10, 6.62, 8.19, 3.78, 5.52 |
| Auto scouting + Auto-recruitment + species passing | 12, 12, 12, 11, 12 | 0.61, 0.67, 0.89, 0.72, 0.56 | 0.06, 0.11, 0.50, 0.11, 0.06 | 3.47, 2.99, 5.20, 3.62, 3.47 |
| Recruitment, 1-second wait | 13, 13, 13, 12, 12 | 0.06, 0.00, 0.11, 0.00, 0.00 | 0.06, 0.00, 0.00, 0.06, 0.11 | 4.89, 6.46, 8.82, 6.30, 6.46 |
| No mentors, 15-second wait | 12, 12, 12, 12, 12 | 0.50, 1.11, 1.00, 0.78, 0.72 | 0.00, 0.00, 0.00, 0.00, 0.00 | 4.41, 7.25, 8.35, 5.04, 5.67 |
| No mentors, 1-second wait | 13, 12, 13, 12, 12 | 0.06, 0.00, 0.11, 0.00, 0.00 | 0.00, 0.00, 0.00, 0.00, 0.00 | 5.04, 7.88, 8.98, 6.15, 7.09 |
| Scouting with species restrictions, no recruitment | 12, 12, 12, 12, 12 | 0.00, 0.00, 0.00, 0.00, 0.00 | 0.00, 0.00, 0.00, 0.00, 0.00 | 3.78, 4.10, 3.94, 3.62, 3.47 |

Limits: snapshot occupancy is coarse; delivered trips are a lower bound on scoring calls.
Existing logs do not capture every scored bout's sampled flowers/start point, so patch-selection
correctness still needs a focused runtime probe. The fourth original row combines species
restriction with recruitment; it does not isolate the effect of mentor species passing.
Shortening waits also changes later trips and random draws. These are paired finite-window
mechanism tests, not a recommendation to set the global wait to one second.
<!-- /FR-1c diagnosis evidence -->

## FR-1d -- repair the diagnosed foraging behaviour

<!-- LAYER: design -->
Level: high

Dave authorised behaviour diagnosis/fix on 22 Oct 2026; FR-1c separates the
independent measurement from runtime ownership. Its controlled evidence is
above (or in its archive after closeout). Start with unproductive early-scout
entrance waits: prove and repair the case where a scout waits despite no
eligible mentor being able to match, while preserving established-seeker and
useful mentor waits. Prototype a narrowly scoped guard, not a global wait
reduction. Include mixed resources, stale mentors, existing matching mentors,
grace/settlement boundaries and both recruitment modes in the regression checks.
Keep species/preference semantics unchanged: FR-1c proved the old table's
confounding, not a defect in explicit constancy. Do not repair speculative
patch-selection issues without a causal probe. Retain targets as loose guidance.
No weakening Orientation flight, save fields, skill wiring, new balance fields
or unrelated performance work. Profile the affected per-bee path first;
preserve explicit player preferences, both recruitment modes and developer
toggles. Require causal before/after regression checks, the same five-seed
stage table and focused/full verification. Runtime changes require high-risk
review/integration. Refine this section from FR-1c's results before claiming.

```queue-gated
**[Codex] FR-1d -- repair the diagnosed foraging behaviour**
- Plan: `plans/now/forager-recruitment.md` -- "FR-1d -- repair the diagnosed foraging behaviour"
- Files: `scripts/bee_foraging.gd`, `tests/test_forager_behaviour.py`, `tests/fr1d_forager_behaviour_test.gd`, `test_scenarios/fr1d_forager_behaviour_test.json`, `plans/now/forager-recruitment.md`
- Check: causal regression checks and the five-seed comparison pass; `tools/prefinish.py` and `tools/verify.ps1` are green; provisional target misses are documented
- Proof: `present: plans/now/forager-recruitment.md :: Next: FR-1d -- repair the diagnosed foraging behaviour`
- Next after: FR-2 -- Auto scouting becomes a Foraging tier-2 purchase that replaces Orientation flight
```

## Not in the queue, and why

- **FR-1d:** FR-1c's causal evidence is ready on its branch; CQ-L1 in the Claude lane owns `scripts/bee_foraging.gd`. After
  CQ-L1 lands or releases that ownership with evidence, recheck both lanes,
  change its `queue-gated` fence to `queue`, and let normal refill admit it.
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
