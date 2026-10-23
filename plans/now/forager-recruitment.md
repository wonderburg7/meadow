# Forager recruitment -- Orientation flight, then Auto scouting, then Auto-recruitment

<!-- CONTEXT: plan | LAYER: immediate-task -->
Status: active | Owner: Dave / Claude Code | Next: FR-2 -- specified with its queue block (plan review, 23 Oct 2026); it follows CQ-L2 and CQ-M8 in the Claude lane, which hold `tests/source_checks.py` and `scripts/bee_foraging.gd` | Dependency: FR-1 → FR-1b → FR-1c → FR-1d → FR-2 → PP-6 (`plans/now/pollination.md`) → FR-3 | Verified: 2026-10-23

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
| FR-2 | Auto scouting becomes a Foraging tier-2 purchase that replaces Orientation flight | `scripts/skills.gd`, `scripts/bee_foraging.gd`, `scripts/skill_tree_panel.gd`, `scripts/levels.gd`, `tests/source_checks.py`, tests | yes -- block written; same lane as CQ-L2 and CQ-M8, which hold two of its files | medium |
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

FR-1d shipped 2026-10-23; its specification is `plans/archive/FR-1d_2026-10-23.md`.

## Not in the queue, and why

- **FR-3:** waits for PP-6 (`plans/now/pollination.md`), which shares
  `scripts/skills.gd`; specified fully once PP-6 lands.

## FR-2 -- Auto scouting becomes a Foraging tier-2 purchase that replaces Orientation flight

<!-- LAYER: immediate-task -->

Decisions 1, 2, 6 and 7 above. Specified by the plan review, 23 Oct 2026,
against `1a1f81c`. Minimum reasoning: **medium**. Read this section, the
durable rules above and `.claude/rules/performance.md`.

**True now.**

- `skills.gd`: `AUTO_SCOUTING` sits in the "Baseline capabilities" block
  (`tier: 0`, `axial: Vector2i(0, 0)`, `cost: {}`, `effects: []`,
  `status: "baseline"`, `baseline: true`). `progression.gd::is_owned`
  answers true for every baseline id without saving it, so every run
  "owns" Auto scouting today and it switches nothing on.
- Foraging tier 2 is Associative learning `(5, 0)` and Adaptive constancy
  `(4, 1)`; Orientation flight is tier 1 at `(3, -1)`; Auto-recruitment is
  tier 4 at `(8, 1)` with `all_of: []`.
- `bee_foraging.gd` reads `GameConfig.scouting_on or
  GameConfig.auto_recruitment_on` directly in seven places
  (`start_collecting`, `finish_collecting`, `go_to_deposit_cell`,
  `finish_depositing` twice, `_score_trip`, `_leave_hive_and_resume`), and
  `orientation_flight_on()` is the toggle or the owned skill.
- `skill_tree_panel.gd::_skill_tip` builds a node's tooltip from name,
  description, cost, state and `_not_built_note`.
- `tests/source_checks.py` `BASELINE_SKILL` is `skill.foraging.auto_scouting`.
- `levels.gd` rows 1 and 2 (Challenges 1 and 2) carry `"skill_bans": []`.
- `test_scenarios/pp2_points_spendable.json` grants Weighted flower choice
  and Pollinator points, then buys Auto-recruitment.

**True afterwards.**

1. **The node.** Move the `AUTO_SCOUTING` entry out of the baseline block
   into the Foraging block, after Adaptive constancy: `"tier": 2`,
   `"axial": Vector2i(5, -1)`, `"cost": {HONEY: 20, NECTAR: 180, POLLEN:
   80}` (a placeholder PP-6 re-prices; it matches Adaptive constancy),
   `"requires_previous_tier": true`, `"all_of": [ORIENTATION_FLIGHT]`,
   `"effects": [{"type": "enable_behaviour", "key": "scouting_on"}]`,
   `"status": "existing"`, `"baseline": false`. Keep its name and
   description. Add a one-line comment naming decision 1 of this plan.
2. **The chain is one line.** Auto-recruitment moves to `Vector2i(9, -1)`
   and gains `"all_of": [AUTO_SCOUTING]`. Orientation flight `(3, -1)` →
   Auto scouting `(5, -1)` → Auto-recruitment `(9, -1)` is one straight
   row; the review ran `check_progression_grid`'s rules over every free
   tier-2 hex: `(5, -1)` and `(5, -2)` pass only with Auto-recruitment
   moved, and `(9, -1)` keeps the line straight. Auto-recruitment's
   behaviour stays unwired (FR-3).
3. **The helper.** Add `static func scouting_on() -> bool` to the
   "skill-or-setting behaviour switches" section of `bee_foraging.gd`, in
   the same shape as `adaptive_constancy_on()`. Replace each of the seven
   `GameConfig.scouting_on or GameConfig.auto_recruitment_on` reads with
   `scouting_on() or GameConfig.auto_recruitment_on`. None of the seven is
   per frame: each sits behind an arrival, a finished visit or a trip end,
   and `progression.gd::is_behaviour_enabled` is a cached dictionary read,
   so no profile is needed (performance rule: counted, not guessed).
4. **Replacement.** `orientation_flight_on()` returns false whenever
   `scouting_on()` is true, and is otherwise unchanged. With the developer
   toggles alone nothing changes, because `prerequisites.gd` already makes
   `orientation_flight_on` and `scouting_on` mutually exclusive.
5. **The tooltip.** Add `_replaced_note(skill)` beside `_not_built_note`
   and append it in `_skill_tip`: for Orientation flight, once
   `Session.progression.is_owned(Skills.AUTO_SCOUTING)`, it returns
   `"\nReplaced by Auto scouting: new foragers now scout for themselves."`;
   otherwise `""`.
6. **Challenges.** `levels.gd` rows 1 and 2 get `"skill_bans":
   ["skill.foraging.auto_scouting", "skill.foraging.auto_recruitment"]`
   (string ids, as the field's header comment describes).
7. **Tests.** `BASELINE_SKILL` becomes `skill.colony.cell_priority`.
   `pp2_points_spendable.json` grants Auto scouting (a `grant_skill` step
   beside the other two) before its Auto-recruitment purchase. New
   `test_scenarios/fr2_auto_scouting_test.json`, built on
   `ap8_bought_orientation_test.json` (same colony, seed, overrides and
   stocked cells): `grant_skill` Tarsal secretions and Orientation flight,
   `buy_skill` Auto scouting, assert it owned; then, once
   `event_count_at_least` `brood_hatch` 1, assert `event_count_at_least`
   `scouting_settled` 1; and once `event_count_at_least`
   `scouting_settled` 3, assert `event_count_at_most` `orientation_flight`
   0 (both are `"when"`-gated asserts, as `ap8` writes its own). New `tests/test_fr2_auto_scouting.py` runs it
   through `tools/run_scenario.py::run_once` as `tests/test_pp2_*` do.
8. **Hands-on check.** File one per `plans/reference/check-loop.md`: in a
   Colony Run with Orientation flight owned, Auto scouting is offered at
   Foraging tier 2 on the same row; buying it, hover Orientation flight in
   the skill tree and read the Replaced line.

**Must not change.** Durable rule 7 (toggles work alone; ownership never
writes `GameConfig`; no save field). The save format: baseline ids were
never saved, so no migration. Challenges 1 and 2 play as today. No other
skill's position, cost or prerequisites. No display string except the new
Replaced line.

**Expected side effect.** Tier 3 of Foraging now needs Auto scouting owned
in Colony Runs and Scenarios (decision 1), so the alpha arc's foraging
tier-3 purchases may come later. Run `python tools/pacing_gates.py` before
and after and put both outputs in the closeout; do not tune anything --
PP-6 prices the route.

**Stop and escalate** if any test other than those named above fails
because tier 3 now waits for Auto scouting, if the grid check rejects
`(5, -1)` or `(9, -1)`, or if a Challenge stage check changes.

**Open decisions:** none.

```queue
**[Claude] FR-2 -- Auto scouting becomes a Foraging tier-2 purchase that replaces Orientation flight**
- Plan: `plans/now/forager-recruitment.md` -- "FR-2 -- Auto scouting becomes a Foraging tier-2 purchase that replaces Orientation flight"
- Files: `scripts/skills.gd`, `scripts/bee_foraging.gd`, `scripts/skill_tree_panel.gd`, `scripts/levels.gd`, `tests/source_checks.py`, `test_scenarios/pp2_points_spendable.json`, `test_scenarios/fr2_auto_scouting_test.json`, `tests/test_fr2_auto_scouting.py`
- Check: `python -m unittest tests.test_fr2_auto_scouting` passes (Auto scouting bought after Orientation flight: scouts settle and no orientation flight runs); `python tools/run_scenario.py test_scenarios/pp2_points_spendable.json` and `test_scenarios/ap8_bought_orientation_test.json` pass; `python tests/source_checks.py` passes its grid check with Auto scouting at (5, -1) and Auto-recruitment at (9, -1); `python tools/prefinish.py` and `.\tools\verify.ps1` are green
- Proof: `absent: scripts/bee_foraging.gd :: static func scouting_on`
- Next after: PP-6 -- the sweep prices points and tier-3/4 so Gyne rearing is affordable after the first winter
```

## FR-3 -- owning Auto-recruitment switches it on, passing species with Adaptive constancy

<!-- LAYER: design -->

Decisions 4, 5, 6 and 7. Auto-recruitment's `enable_behaviour`
`auto_recruitment_on`, read through a helper as FR-2's are; species passing
under Adaptive constancy; a sweep of the `recruit_*` values in
`game_config.gd` to decision 4's gain, which also prices the node.
Specified fully once PP-6 lands.
