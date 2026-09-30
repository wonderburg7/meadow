# Brood spine — Nurses and Honey worker are bought, and each run has one availability sheet

<!-- CONTEXT: plan | LAYER: immediate-task -->
Status: active | Owner: Dave / Claude Code | Next: BS-5 -- the developer table shows a run's sheet (startable, in the Claude lane); BS-4 -- the honey gate needs its specification first (see Later slices) | Dependency: none -- AP-8 landed 24 Sep 2026, so progression step 7 is no longer waiting | Verified: 2026-09-30

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
| BS-3 | the gate goes live: an unowned role cannot be assigned or worked | `scripts/availability.gd`, `scripts/hud.gd`, `scripts/challenge_runner.gd` | yes | high |
| BS-4 | a run buys Honey worker, makes honey and affords a tier-2 skill | a new scenario, `plans/design/progression.md` | after BS-3 | medium |
| BS-5 | the developer table shows a run's sheet, read-only | `scripts/run_availability_panel.gd` (new), `scripts/run_availability.gd`, `scripts/debug_panel.gd` | yes | medium |
| BS-6 | developer edits to the table change what a run starts with | decided in BS-5's closeout | after BS-5 and a persistence decision | high |

BS-1 and BS-D share no file and are independent. Every later slice names
what it waits for above; each is specified in full when it becomes startable.

BS-1 shipped 2026-09-28; its specification is `plans/archive/BS-1_2026-09-28.md`.

BS-2 shipped 2026-09-29; its specification is `plans/archive/BS-2_2026-09-29.md`.

## BS-3 — the gate goes live

Level: high (ownership boundary and a save-compatibility decision).

`Availability.role_query` composes the stage
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

**Result (30 Sep 2026).** `Availability.role_query(role_id, stage_gate,
progression)` is the one rule: the role's stage key while a Challenge is
active, and its roles.gd `skill` owned. The HUD's Job row, "when idle" menu
and Raises row ask it (`hud.gd::_role_offered`, over the gate `apply_gates`
last received), and the skill tree's Buy re-applies it
(`hud.gd::refresh_role_gating`). `orders_zones.gd`'s role, backup-role and
Raises commands refuse a role whose skill is unowned -- the skill part only,
since what a Challenge shows is the HUD's lesson plan. `Actions.is_gated`
counts a role's skill, so `action_query` now refuses every Nurse and Honey
worker row until it is owned. **Save compatibility, option A (Dave, 30 Sep
2026):** `saving.gd::_restore` grants the run's starting skills again after
`restore_skills`, so a pre-BS-1 save keeps its seeded roles; no version bump.
`tests/source_checks.py::check_stage_role_skills` fails a stage that unlocks
a skill-gated role before that skill is free at or before it, or owned from
the Challenge's level definition. Proof: `test_scenarios/bs3_nurse_gate_test.json`
(no seeded nurses: assigning and raising a nurse are refused, then allowed
after buying Nurses). The three `c6_fanners` fixtures assign Honey workers
without seeding any, so they now start with `skill_grants` for Honey worker.
`challenge_runner.gd` needed no change.

```queue
**[Claude] BS-3 -- the gate goes live: an unowned role cannot be assigned or worked**
- Plan: `plans/now/brood-spine.md` -- "BS-3 — the gate goes live"
- Files: `scripts/availability.gd`, `scripts/actions.gd`, `scripts/hud.gd`, `scripts/orders_zones.gd`, `scripts/saving.gd`, `scripts/skill_tree_panel.gd`, `scripts/scenario_actions.gd`, `tests/source_checks.py`, `test_scenarios/bs3_nurse_gate_test.json`, `test_scenarios/c6_fanners_1_test.json`, `test_scenarios/c6_fanners_2_test.json`, `test_scenarios/c6_fanners_4_test.json`
- Check: a level 7 run cannot assign or raise a nurse before buying Nurses and can after, Challenge 2's fixture `test_scenarios/f2s_challenge2_gate_table_test.json` still passes, and `tools/verify.ps1` is green
- Proof: `absent: scripts/availability.gd :: "role_query"`
- Next after: BS-4 -- a run buys Honey worker, makes honey and affords a tier-2 skill
```

BS-D shipped 2026-09-28; its specification is `plans/archive/BS-D_2026-09-28.md`.

## BS-5 — the developer table shows a run's sheet, read-only

Level: medium (one new panel, one button, one source check; the sheet it reads
already exists).

- **Required reading.** Decision 3 above. `scripts/run_availability.gd` (its
  header and `sheet_for`); how `scripts/debug_panel.gd` builds its footer or
  category buttons, to place one more; `Session.developer_mode`
  (`scripts/session.gd`, landed in BS-D).
- **Files to change.** `scripts/run_availability_panel.gd` (new),
  `scripts/run_availability.gd`, `scripts/debug_panel.gd`.
- **Requirements.**
  - With `Session.developer_mode` on, the settings window shows a "Run
    availability" button; with it off the button is absent, not disabled. The
    button opens a read-only window listing the current run's sheet: one row
    per skill, with its source (start / tree / unavailable) and the reason
    turned from `run_availability.gd`'s `reason.*` key into a sentence.
  - The reason-to-text table lives in the panel; the sheet stays keys only.
    The window recomputes the sheet when opened, never per frame, and reads
    it through `RunAvailability.sheet_for(Levels.get_level(...))` exactly as
    `main.gd` does; it does not read `progression.gd`'s ownership as a second
    answer.
  - Feature rows and gated-role rows: add them to `run_availability.gd` only
    as far as its header already promises (features through
    `progression.gd::feature_valid()`); the "introduced at stage" and "free
    at stage" columns wait for BS-2 and are named in the window as "not yet
    available" rather than left blank.
  - Nothing here edits the sheet. Editing is BS-6.
- **Source check.** A test that fails if the button can be built while
  `developer_mode` is off, and one that fails if every `reason.*` key in
  `run_availability.gd` lacks a sentence in the panel.
- **Escalation.** If the settings window cannot host the button without
  reaching into `main.gd`, report which and let Dave choose the entry point.

```queue
**[Claude] BS-5 -- the developer table shows a run's sheet, read-only**
- Plan: `plans/now/brood-spine.md` -- "BS-5 — the developer table shows a run's sheet, read-only"
- Files: `scripts/run_availability_panel.gd`, `scripts/run_availability.gd`, `scripts/debug_panel.gd`
- Check: with Developer mode on, the settings window lists a Run availability button that opens a read-only table of the run's skills with source and reason; with it off the button is absent, and `tools/verify.ps1` is green
- Proof: `absent: scripts/debug_panel.gd :: run_availability_panel`
- Next after: BS-6 -- developer edits to the table change what a run starts with
```

## Later slices, in outline

Each is specified in full, with its own `queue` block, when what it waits for
has shipped. These notes fix only what the earlier slices must not preclude.

- **BS-4 — the honey gate.** A run with no seeded honey makers buys Honey
  worker, makes honey and affords a tier-2 skill before it runs short of
  comb: section 6's constraint 2, proved with a scenario rather than asserted.
  Records the result in `plans/design/progression.md` step 7.
- **BS-6 — developer edits.** Needs a decision before it can be specified:
  whether an edit is a local override stored under `user://` and applied at
  run start, or is written back to the run definition (`levels.gd` or the
  scenario JSON) so it becomes the game's data. BS-5's closeout brings the
  options and costs to Dave.

## Read on demand

- `plans/design/progression.md` sections 4.2, 5.2, 6 and 11 step 7 -- only if
  a slice here needs the tier ladder or reachability reasoning.
- `docs/challenge-stages.md` -- what each Challenge 2 stage asks the player.
