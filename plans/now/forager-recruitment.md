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
| FR-2 | Auto scouting becomes a Foraging tier-2 purchase that replaces Orientation flight | `scripts/skills.gd`, `scripts/bee_foraging.gd`, `scripts/skill_tree_panel.gd`, `scripts/levels.gd`, `tests/source_checks.py`, tests | no -- after FR-1 shows Auto scouting beats Orientation flight | high |
| FR-3 | owning Auto-recruitment switches it on, passing species with Adaptive constancy | `scripts/skills.gd`, `scripts/bee_foraging.gd`, `scripts/hive.gd`, `scripts/game_config.gd`, `scripts/levels.gd`, tests | no -- after PP-6 | high |

**Dependencies.** FR-1 changes no game file. FR-2 waits for FR-1's table;
if a stage is not better than the one before, a tuning slice (FR-1b) is
specified from FR-1's numbers before FR-2, and if tuning cannot fix the
order the work stops for Dave (decision 3). Auto scouting sits on the gyne
route (decision 1), so PP-6 (`plans/now/pollination.md`) prices the route
only after FR-2 lands, and AR-4 (`plans/now/alpha-route-evidence.md`)
still waits for PP-6. FR-3 shares `skills.gd` with PP-6, so it follows it.

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
- Proof: `contains: plans/now/forager-recruitment.md :: Auto-recruitment is at least 30% above Auto scouting`
- Next after: FR-2 -- Auto scouting becomes a Foraging tier-2 purchase that replaces Orientation flight
```

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
