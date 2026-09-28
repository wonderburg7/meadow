# Brood spine — Nurses and Honey worker are bought, and each run has one availability sheet

<!-- CONTEXT: plan | LAYER: immediate-task -->
Status: active | Owner: Dave / Claude Code | Next: BS-2 -- Challenge 2 offers Nurses free at 2.5 (startable, BS-1 landed 28 Sep 2026), and BS-D -- a developer mode setting, both in the Claude lane | Dependency: none -- AP-8 landed 24 Sep 2026, so progression step 7 is no longer waiting | Verified: 2026-09-28

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
| BS-D | a developer mode setting, switched on from the main menu's settings | `scripts/settings_catalogue.gd`, `scripts/game_config.gd`, `scripts/main_menu.gd` | yes | medium |
| BS-2 | Challenge 2 offers Nurses free at 2.5 | `scripts/challenge_stages.gd`, `scripts/challenge_runner.gd`, `scripts/progression.gd`, `scripts/skill_tree_panel.gd`, `test_scenarios/f2s_challenge2_gate_table_test.json`, `docs/challenge-stages.md` | yes | medium |
| BS-3 | the gate goes live: an unowned role cannot be assigned or worked | `scripts/availability.gd`, `scripts/hud.gd`, `scripts/challenge_runner.gd` | after BS-1, BS-2 | high |
| BS-4 | a run buys Honey worker, makes honey and affords a tier-2 skill | a new scenario, `plans/design/progression.md` | after BS-3 | medium |
| BS-5 | the developer table shows a run's sheet, read-only | a new panel script, `scripts/run_availability.gd` | after BS-1, BS-D | medium |
| BS-6 | developer edits to the table change what a run starts with | decided in BS-5's closeout | after BS-5 and a persistence decision | high |

BS-1 and BS-D share no file and are independent. Every later slice names
what it waits for above; each is specified in full when it becomes startable.

BS-1 shipped 2026-09-28; its specification is `plans/archive/BS-1_2026-09-28.md`.

## BS-2 — Challenge 2 offers Nurses free at 2.5

Level: medium (bounded: one stage row, one waiver, one panel label, one
fixture; the ownership boundary was settled in BS-1).

- **Required reading.** Decision 1 above. `scripts/challenge_stages.gd`'s 2.5
  and 2.6 rows; `scripts/progression.gd`'s `begin_run`, `is_known`,
  `purchase_blocker` and `purchase`; `scripts/run_availability.gd`'s header;
  `scripts/skill_tree_panel.gd`'s cost label and `buy_skill`; the
  `test_scenarios/f2s_challenge2_gate_table_test.json` actions around 2.5.
- **Files to change.** `scripts/challenge_stages.gd`,
  `scripts/challenge_runner.gd`, `scripts/progression.gd`,
  `scripts/skill_tree_panel.gd`,
  `test_scenarios/f2s_challenge2_gate_table_test.json`,
  `docs/challenge-stages.md` (regenerated by `python tools/stage_reference.py`,
  never hand-edited).
- **Requirements.**
  - A stage row may carry `free_skills` (skill ids). Stage 2.5 lists
    `skills.gd`'s Nurses id, adds `skills_window` and that id to its
    `unlocked_keys` (a skill's stage-gate key is its own id), and every later
    Challenge 2 row keeps both keys, since each row lists its keys in full.
    If the availability.gd `UI_GATES`/`UNTABLED_GATE_KEYS` source check
    refuses a skill id as a gate key, stop and report: that file is BS-3's.
  - `progression.gd` holds the waiver: the runner, on entering a stage,
    hands its `free_skills` to one entry (e.g. `waive_cost(ids)`), and
    `purchase_blocker`/`purchase` treat a waived skill's cost as empty. It is
    run state: `end_run()` clears it, and it is not saved (a restored run
    re-enters its stage, which hands it back). Check `is_known()` lets a
    Challenge buy Nurses; if discovery hides it, that is the escalation.
  - `skill_tree_panel.gd` shows "Free" in place of the cost for a waived
    skill, from the resolver, never from its own rule.
  - 2.5's goal becomes Nurses owned and a nurse raised
    (`{"all_of": [{"skill_owned": ...}, {"role_count": ...}]}`, BS-1's
    condition), and its goal text, welcome and hint say to buy Nurses in the
    skill tree first.
  - The sheet's "introduced at stage" and "free at stage" columns: add them
    to `run_availability.gd` only if BS-5 needs them before it starts;
    otherwise leave its comment naming them.
- **Fixture.** `f2s_challenge2_gate_table_test.json` buys Nurses at 2.5
  (`{"do": "buy_skill", ...}`), asserts no stores were spent, and still
  completes Challenge 2.
- **Escalation.** A stage that unlocks a skill-gated role key before its
  skill is owned or free is exactly BS-3's hazard; if the Honey role key is
  already unlocked by a Challenge 2 stage, stop and report.

```queue
**[Claude] BS-2 -- Challenge 2 offers Nurses free at 2.5**
- Plan: `plans/now/brood-spine.md` -- "BS-2 — Challenge 2 offers Nurses free at 2.5"
- Files: `scripts/challenge_stages.gd`, `scripts/challenge_runner.gd`, `scripts/progression.gd`, `scripts/skill_tree_panel.gd`, `test_scenarios/f2s_challenge2_gate_table_test.json`, `docs/challenge-stages.md`
- Check: `test_scenarios/f2s_challenge2_gate_table_test.json` passes: Challenge 2 buys Nurses at 2.5 for nothing and still completes, `docs/challenge-stages.md` shows 2.5's new goal, and `tools/verify.ps1` is green
- Proof: `absent: scripts/challenge_stages.gd :: "free_skills"`
- Next after: BS-3 -- the gate goes live: an unowned role cannot be assigned or worked
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

- **BS-3 — the gate goes live.** `Availability.role_query` composes the stage
  key and the role's skill; the HUD's Job row and brood role designation read
  it, and `action_query` refuses a row whose role's skill is unowned. Proof: a
  level 7 run cannot assign or raise a nurse before buying Nurses, and can
  after; Challenge 2's fixture still completes. Also carried from BS-2's
  outline: a source check that fails a stage unlocking a skill-gated role key
  before that role's skill is owned or free -- what makes a future Honey
  stage safe. **Save compatibility (found in BS-1):** starting skills are
  saved as temporary ownership and `save_game.gd::restore_skills` replaces
  ownership wholesale, so a save written before BS-1 (level 4-6, Challenge 1)
  restores without Nurses/Honey worker. Harmless until this gate; before it
  goes live, decide whether restore re-applies the run's `starting` skills
  (one line in `saving.gd`) or the save version bumps.
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
