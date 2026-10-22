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
| FR-1d | Repair the concrete defects FR-1c establishes | `scripts/bee_foraging.gd`, focused tests/scenarios, this plan | yes -- CQ-L1 released `scripts/bee_foraging.gd`; FR-1c closes out before refill admits it | high |
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
Take a fresh same-source baseline before/after the repair: FR-1c's frozen
measurements used `349cb34fb18d92805fba3d7f8d1d0d805f09b6ed`, before later
integrated work. Do not interpret intervening changes as the repair's effect.
No weakening Orientation flight, save fields, skill wiring, new balance fields
or unrelated performance work. Profile the affected per-bee path first;
preserve explicit player preferences, both recruitment modes and developer
toggles. Require causal before/after regression checks, the same five-seed
stage table and focused/full verification. Runtime changes require high-risk
review/integration. Refine this section from FR-1c's results before claiming.

**Closeout dependency, 22 Oct 2026:** FR-1c's seven focused tests, prefinish
and `finish`'s branch verification passed. CQ-L1 has now landed and released
`bee_foraging.gd`; FR-1c can close out and refill the Codex lane with FR-1d.
The runtime repair remains unmerged until FR-1d completes its high-risk review.

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
