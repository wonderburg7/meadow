# Brood spine — Nurses and Honey worker are bought, and each run has one availability sheet

<!-- CONTEXT: plan | LAYER: immediate-task -->
Status: active | Owner: Dave / Claude Code | Next: BS-1 -- a run's availability sheet decides its starting skills, and BS-D -- a developer mode setting, both queued in the Claude lane | Dependency: none -- AP-8 landed 24 Sep 2026, so progression step 7 is no longer waiting | Verified: 2026-09-25

**Objective.** Execute Phase B step 7 of `plans/design/progression.md`: Honey
worker and Nurses become skills a run buys, so a tier-2 purchase becomes
possible and section 6's constraint 2 (enough starting comb to make the first
honey) is proved in a real run. Alongside it, give every level and scenario one
derived **availability sheet** -- which skills, gated roles and features are on
at the start, introduced at a Challenge stage, bought in the tree, or not
available -- that the run start reads and a developer table shows and edits.

## Decisions (Dave, 25 Sep 2026)

1. **Every run buys them.** Nurses and Honey worker are purchased in every run,
   Challenges included. A Challenge stage that introduces one of the two roles
   makes its skill a **free purchase** at that stage, so the player learns the
   tree by buying it. Challenge 2 does this at 2.5 (raise a nurse); no stage
   introduces Honey yet, and whichever first does must do the same.
2. **Seeding implies owning.** A run that starts with bees in a gated role --
   a level's or scenario's `nurses`/`honey_makers`, or Challenge 1's queen,
   whose `queen_laying_backup` is Nurse -- starts owning that role's skill.
   One rule, applied at run start from the run definition; no level or
   scenario lists these grants by hand. Levels 4-6, Challenge 1 and every
   existing fixture therefore play exactly as today.
3. **A developer availability table.** A developer mode, switched on from the
   main menu's settings, opens a table per level or scenario: every feature,
   skill and gated role, with columns for *on at the start*, *introduced at
   stage* (naming the stage), *bought in the tree*, *not available*, and
   *free at stage*. In developer mode the table can be edited to change what a
   run starts with.
4. **Architecture principles** that every slice here is reviewed against:
   fewer duplicated rules and fewer files a future session must open; one
   authoritative home for each rule or value; modular, consistent,
   extensible and testable; no new per-frame work, full-set scans or frequent
   updates; and new features, Challenges and scenarios cheaper and safer to
   add.

## Ownership taken by this plan

- **`scripts/roles.gd` owns which skill unlocks a role** (a `skill` field on
  the role row, empty for ungated roles). This is role data, which
  `CLAUDE.md` puts in `roles.gd`. `actions.gd`'s `skill` field keeps the 17 Sep
  2026 meaning for work a skill unlocks *inside* a role (a later Jelly mode,
  for example); `Availability.action_query` also refuses a row whose role's
  skill is unowned, so the role gate is written once, not copied onto every
  nurse and honey row.
- **`scripts/run_availability.gd` (new) owns the availability sheet.** It is
  derived, not authored: from the run definition (`levels.gd` entry or
  scenario JSON), `challenge_stages.gd`, `skills.gd`, `roles.gd` and
  `features.gd`. It is computed once per run start, never per frame. The run
  start (`main.gd`, where `set_skill_policy` is called today) hands its result
  to `progression.gd`; nothing else computes starting ownership.
- **`progression.gd` stays the only answer to "is this owned"**, and becomes
  the only answer to "what does this cost in this run" (a stage's free
  purchase is a waiver it holds, not a second cost table).
- **Not to change:** stage ids. Save checkpoints record them, so 2.5 keeps its
  id and gains the purchase as part of its goal rather than a new stage being
  inserted.

## Open slices at a glance

| Slice | Outcome | Files owned | Startable | Level |
| --- | --- | --- | --- | --- |
| BS-1 | the run start derives starting skills from one sheet | `scripts/run_availability.gd`, `scripts/roles.gd`, `scripts/progression.gd`, `scripts/main.gd`, `scripts/conditions.gd`, `test_scenarios/bs1_seeded_skills_test.json` | yes | high |
| BS-D | a developer mode setting, switched on from the main menu's settings | `scripts/settings_catalogue.gd`, `scripts/game_config.gd`, `scripts/main_menu.gd` | yes | medium |
| BS-2 | Challenge 2 offers Nurses free at 2.5 | `scripts/challenge_stages.gd`, `scripts/challenge_runner.gd`, `scripts/progression.gd`, `scripts/skill_tree_panel.gd`, `test_scenarios/f2s_challenge2_gate_table_test.json` | after BS-1 | medium |
| BS-3 | the gate goes live: an unowned role cannot be assigned or worked | `scripts/availability.gd`, `scripts/hud.gd`, `scripts/challenge_runner.gd` | after BS-1, BS-2 | high |
| BS-4 | a run buys Honey worker, makes honey and affords a tier-2 skill | a new scenario, `plans/design/progression.md` | after BS-3 | medium |
| BS-5 | the developer table shows a run's sheet, read-only | a new panel script, `scripts/run_availability.gd` | after BS-1, BS-D | medium |
| BS-6 | developer edits to the table change what a run starts with | decided in BS-5's closeout | after BS-5 and a persistence decision | high |

BS-1 and BS-D share no file and are independent. Every later slice names
what it waits for above; each is specified in full when it becomes startable.

## BS-1 — a run's availability sheet decides its starting skills

Level: high (an ownership boundary and the run-start order).

- **Required reading.** This plan's "Decisions" and "Ownership taken"
  sections. `scripts/main.gd` around the `set_skill_policy` call (search for
  `ensure_progression`), `scripts/progression.gd`'s `set_skill_policy`,
  `is_permitted` and `grant_temporary`, `scripts/levels.gd`'s header comment
  and one level entry, and `scripts/conditions.gd`'s `_met_key` and
  `_progress_key`.
- **Files to change.** `scripts/run_availability.gd` (new),
  `scripts/roles.gd`, `scripts/progression.gd`, `scripts/main.gd`,
  `scripts/conditions.gd`, `test_scenarios/bs1_seeded_skills_test.json` (new).
- **Requirements.**
  - `roles.gd`: a `skill` field on every role row -- `Skills.NURSES` on
    Nurse, `Skills.HONEY_WORKER` on Honey, empty elsewhere -- and a
    `skill_for(role_id)` lookup. Guard against a preload cycle with
    `skills.gd`; if one appears, use the skill id strings and a source check
    that they match `skills.gd`'s constants.
  - `run_availability.gd`: a static `sheet_for(run_definition)` returning, per
    skill id, `{"source": "start"|"tree"|"unavailable", "reason": ...}`, and
    `starting_skills(run_definition)`: the run's `skill_grants` plus the skill
    of every role the definition seeds (a non-zero `nurses`/`honey_makers`
    count, or the role `queen_laying_backup` names). Stage and feature columns
    are BS-2's and BS-5's; leave a comment naming them, not empty code.
  - `progression.gd`: one `begin_run(sheet)` (or equivalently named) entry
    that applies the policy and grants the starting skills as temporary
    ownership; `main.gd` calls it in place of today's direct
    `set_skill_policy` call. Call `Availability.invalidate()` after
    ownership changes, as that file's comment requires.
  - `conditions.gd`: a `skill_owned` condition (met and progress), for BS-2's
    stage goal and this slice's fixture.
  - **No behaviour changes in this slice**: no action or role is gated yet, so
    the only observable difference is which skills are owned at the start.
- **Fixture.** `bs1_seeded_skills_test.json` asserts, from a scenario that
  seeds nurses and honey makers, that both skills are owned on day 0, and a
  second case with neither seeded that neither is owned.
- **Escalation.** If the scenario level path (`Levels.SCENARIO_LEVEL_ID`)
  does not carry `queen_laying_backup` or the seeded counts through to the
  run definition, stop and report rather than adding a second reader.

```queue
**[Claude] BS-1 -- a run's availability sheet decides its starting skills**
- Plan: `plans/now/brood-spine.md` -- "BS-1 — a run's availability sheet decides its starting skills"
- Files: `scripts/run_availability.gd`, `scripts/roles.gd`, `scripts/progression.gd`, `scripts/main.gd`, `scripts/conditions.gd`, `test_scenarios/bs1_seeded_skills_test.json`
- Check: `test_scenarios/bs1_seeded_skills_test.json` passes: a run seeding nurses and honey makers owns Nurses and Honey worker on day 0 and a run seeding neither owns neither, `main.gd` no longer calls `set_skill_policy` directly, and `tools/verify.ps1` is green
- Proof: `absent: scripts/roles.gd :: "skill":`
- Next after: BS-2 -- Challenge 2 offers Nurses free at 2.5
```

## BS-D — a developer mode setting, switched on from the main menu's settings

Level: medium.

- **Required reading.** This heading. `scripts/settings_catalogue.gd`'s header
  and the `show_crab_spiders` entry (the nearest existing dev-only setting),
  and how `scripts/main_menu.gd` opens the settings window.
- **Files to change.** `scripts/settings_catalogue.gd`,
  `scripts/game_config.gd`, `scripts/main_menu.gd`.
- **Requirements.** A `developer_mode` setting, off by default, owned by
  `GameConfig` and catalogued in `settings_catalogue.gd` like any other
  toggle, reachable from the settings window the main menu opens. It is a
  preference, not run state, so it survives a restart. Nothing reads it yet
  except a source check that it exists; BS-5 is its first consumer. Do not
  build a separate settings screen for it.
- **Escalation.** If the main menu's settings window cannot show a toggle
  without the in-run settings window showing it too, report which it is and
  let Dave choose; either is acceptable for a developer setting.

```queue
**[Claude] BS-D -- a developer mode setting, switched on from the main menu's settings**
- Plan: `plans/now/brood-spine.md` -- "BS-D — a developer mode setting, switched on from the main menu's settings"
- Files: `scripts/settings_catalogue.gd`, `scripts/game_config.gd`, `scripts/main_menu.gd`
- Check: the settings window opened from the main menu lists a Developer mode toggle, off by default, that survives a restart, and `tools/verify.ps1` is green
- Proof: `absent: scripts/settings_catalogue.gd :: developer_mode`
- Next after: BS-5 -- the developer table shows a run's sheet, read-only
```

## Later slices, in outline

Each is specified in full, with its own `queue` block, when what it waits for
has shipped. These notes fix only what the earlier slices must not preclude.

- **BS-2 — Challenge 2 offers Nurses free at 2.5.** A stage row gains
  `free_skills`; `progression.gd` holds the waiver and answers the run's cost
  (`skill_tree_panel.gd` shows "free" from it); stage 2.5 unlocks
  `skills_window` and the Nurses node, and its goal becomes Nurses owned and
  a nurse raised, with its welcome and hint text saying so. The sheet reports
  the skill as introduced at 2.5 and free there. A source check fails a stage
  that unlocks a skill-gated role key without the role's skill being owned or
  free by that stage -- which is what makes the future Honey stage safe.
- **BS-3 — the gate goes live.** `Availability.role_query` composes the stage
  key and the role's skill; the HUD's Job row and brood role designation read
  it, and `action_query` refuses a row whose role's skill is unowned. Proof: a
  level 7 run cannot assign or raise a nurse before buying Nurses, and can
  after; Challenge 2's fixture still completes.
- **BS-4 — the honey gate.** A run with no seeded honey makers buys Honey
  worker, makes honey and affords a tier-2 skill before it runs short of
  comb: section 6's constraint 2, proved with a scenario rather than asserted.
  Records the result in `plans/design/progression.md` step 7.
- **BS-5 — the developer table, read-only.** With developer mode on, a window
  lists the current run's sheet: every feature, skill and gated role, and the
  columns from decision 3. It reads `run_availability.gd` only.
- **BS-6 — developer edits.** Needs a decision before it can be specified:
  whether an edit is a local override stored under `user://` and applied at
  run start, or is written back to the run definition (`levels.gd` or the
  scenario JSON) so it becomes the game's data. BS-5's closeout brings the
  options and costs to Dave.

## Read on demand

- `plans/design/progression.md` sections 4.2, 5.2, 6 and 11 step 7 -- only if
  a slice here needs the tier ladder or reachability reasoning.
- `docs/challenge-stages.md` -- what each Challenge 2 stage asks the player.
