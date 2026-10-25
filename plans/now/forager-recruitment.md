# Forager recruitment -- Orientation flight, then Auto scouting, then Auto-recruitment

<!-- CONTEXT: plan | LAYER: immediate-task -->
Status: active (FR-2 landed) | Owner: Dave / Claude Code | Next: PP-6 (`plans/now/pollination.md`), then FR-3 -- FR-2 landed: Auto scouting is a Foraging tier-2 purchase at (5, -1) that replaces Orientation flight (`scripts/bee.gd` joined its files, 25 Oct 2026, for the new-forager scouting gate) | Dependency: FR-1 → FR-1b → FR-1c → FR-1d → FR-2 → PP-6 (`plans/now/pollination.md`) → FR-3 | Verified: 2026-10-24

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
| FR-3 | owning Auto-recruitment switches it on, passing species with Adaptive constancy | `scripts/skills.gd`, `scripts/bee_foraging.gd`, `scripts/hive.gd`, `scripts/game_config.gd`, `scripts/levels.gd`, tests | no -- after PP-6 | high |
| FR-4 | a headless assertion replaces the C-143 hands-on check | `scripts/scenario_actions.gd`, tests | no -- `scripts/scenario_actions.gd` was released 25 Oct 2026, but `tools/admission.py` reads C-143 as an unlanded slice | medium |

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

FR-2 shipped 2026-10-25; its specification is `plans/archive/FR-2_2026-10-25.md`.

## FR-3 -- owning Auto-recruitment switches it on, passing species with Adaptive constancy

<!-- LAYER: design -->

Decisions 4, 5, 6 and 7. Auto-recruitment's `enable_behaviour`
`auto_recruitment_on`, read through a helper as FR-2's are; species passing
under Adaptive constancy; a sweep of the `recruit_*` values in
`game_config.gd` to decision 4's gain, which also prices the node.
Specified fully once PP-6 lands.

## FR-4 -- a headless assertion replaces the C-143 hands-on check

Level: medium -- claude-sonnet-5-5 at medium effort.

**True now.** Dave, on C-143: "I don't have the patience to test this". The
check asks him to watch that an unmatched scout does not wait at the entrance
while an established forager does. Nothing asserts a bee's state in a
scenario: `scenario_actions.gd` has `set_bee_load` but no way to set a bee's
trip history and no condition that reads bee states.

**When done:**

1. A new assert condition `bee_states` in `scenario_actions.gd`'s assertion
   checks: for a bee selector, the bee's state name is (or is not) in a listed
   set, evaluated at the assertion's time.
2. A `set_bee_stats` action verb, beside `set_bee_load`, that sets
   `trips_scored` and `avg_collection_rate` on the matched bees.
3. `test_scenarios/fr4_scout_entrance.json` turns Auto scouting and
   Auto-recruitment on with `set_config`, then asserts that an unmatched scout
   (`is_scouting`, no `entrance_mentors`) is not left in
   `AT_ENTRANCE_SEEKING` and walks back out (`bee_foraging.gd::go_to_exit`,
   `_leave_hive_and_resume`), while an established forager (`trips_scored` at
   least `GameConfig.recruit_grace_trips`, `avg_collection_rate` below
   `recruit_lower_threshold`) waits in `AT_ENTRANCE_SEEKING`.
   `tests/test_fr4_scout_entrance.py` runs it.
4. On a pass, the implementer archives C-143 with `python tools/new_check.py
   --confirm C-143` and edits `checks/ready/C-143.md` if the tool asks.

**Invariants.** No simulation code changes. If the assertion shows a scout
waiting at the entrance, that is a gameplay bug in `bee_foraging.gd`: stop and
escalate with the figures, do not fix it in this slice. No hands-on check is
filed: the assertion replaces it.

**Open decisions:** none.

```queue-gated
**[Claude] FR-4 -- a headless assertion replaces the C-143 hands-on check**
- Plan: `plans/now/forager-recruitment.md` -- "FR-4 -- a headless assertion replaces the C-143 hands-on check"
- Files: `scripts/scenario_actions.gd`, `test_scenarios/fr4_scout_entrance.json`, `tests/test_fr4_scout_entrance.py`, `checks/ready/C-143.md`
- Check: `python -m unittest tests.test_fr4_scout_entrance` passes (an unmatched scout is not in `AT_ENTRANCE_SEEKING` after its walk and leaves the hive; an established forager below the lower threshold waits there); C-143 is archived; `.\tools\verify.ps1` is green
- Proof: `absent: scripts/scenario_actions.gd :: "bee_states"`
- Next after: none -- FR-3 in `plans/now/forager-recruitment.md` does not depend on it
```
