# Brood spine — Nurses and Honey worker are bought, and each run has one availability sheet

<!-- CONTEXT: plan | LAYER: immediate-task -->
Status: active | Owner: Dave / Claude Code | Next: BS-4 -- the honey gate (startable, specified 30 Sep 2026); BS-6 -- developer edits, waiting for Dave's persistence decision | Dependency: none -- AP-8 landed 24 Sep 2026, so progression step 7 is no longer waiting | Verified: 2026-09-30

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
| BS-4 | a run buys Honey worker, makes honey and affords a tier-2 skill | `test_scenarios/bs4_honey_gate_test.json`, `plans/design/progression.md` | startable | medium |
| BS-6 | developer edits to the table change what a run starts with | decided in BS-5's closeout | after BS-5 and a persistence decision | high |

BS-1 and BS-D share no file and are independent. Every later slice names
what it waits for above; each is specified in full when it becomes startable.

BS-1 shipped 2026-09-28; its specification is `plans/archive/BS-1_2026-09-28.md`.

BS-2 shipped 2026-09-29; its specification is `plans/archive/BS-2_2026-09-29.md`.

BS-3 shipped 2026-09-30; its specification is `plans/archive/BS-3_2026-09-30.md`.

BS-5 shipped 2026-09-30; its specification is `plans/archive/BS-5_2026-09-30.md`.

## BS-4 — the honey gate

Level: medium (one scenario and a recorded result; a stall is escalated,
never rebalanced here). Specified 30 Sep 2026 in BS-5's closeout.

`plans/design/progression.md` section 6, constraint 2: a run must start with
enough empty comb for a Honey worker to make the honey its first tier-2
purchase costs, "checked by a scenario run, not an assertion in code". BS-3
made that real: no run owns Honey worker unless it seeds honey makers.

- **Scenario.** `test_scenarios/bs4_honey_gate_test.json`, the starting
  colony of level 5 copied from `levels.gd` (its counts, `stock` and
  `automine`; it seeds nurses but no honey makers, so it starts owning
  Nurses and not Honey worker). Actions, each purchase timed with a `when`
  on `hive_total` so it fires only once affordable: `buy_skill`
  `skill.brood.honey_worker` when nectar is at least 150 and pollen 60;
  then `assign_role` two nectar foragers to `honey`; then `buy_skill`
  `skill.colony.comb_worker` (20 honey, 200 nectar) when honey is at least
  20 and nectar 200; then `assert` `skill_owned` for Comb worker. Stop when
  the actions resolve, `max_days` 30. If a purchase is refused for a reason
  other than cost (the tree's tier rule, say), say which in the result
  rather than working round it.
- **Result.** Add one line to `plans/design/progression.md` section 11,
  step 7: the day Comb worker was bought, or the step the run stalled at,
  naming the fixture.
- **Escalate** if the run stalls on honey or comb: that is the constraint
  failing, and the fix is a balance decision for Dave -- more pre-built
  empty comb in `levels.gd`, or a cheaper first tier-2 skill -- not this
  slice's to make.

```queue
**[Claude] BS-4 -- a run buys Honey worker, makes honey and affords a tier-2 skill**
- Plan: `plans/now/brood-spine.md` -- "BS-4 — the honey gate"
- Files: `test_scenarios/bs4_honey_gate_test.json`, `plans/design/progression.md`
- Check: `python tools/run_scenario.py test_scenarios/bs4_honey_gate_test.json` passes with Comb worker bought within 30 days, or its failure names the stalled step and the options go to Dave; `plans/design/progression.md` section 11 step 7 records the result; and `tools/verify.ps1` is green
- Proof: `absent: plans/design/progression.md :: bs4_honey_gate_test`
- Next after: BS-6 -- developer edits to the table change what a run starts with
```

## Later slices, in outline

Each is specified in full, with its own `queue` block, when what it waits for
has shipped. These notes fix only what the earlier slices must not preclude.

- **BS-6 — developer edits.** Needs a decision before it can be specified:
  whether an edit is a local override stored under `user://` and applied at
  run start, or is written back to the run definition (`levels.gd` or the
  scenario JSON) so it becomes the game's data. BS-5's closeout brings the
  options and costs to Dave. Brought on 30 Sep 2026 (BS-5's closeout): (a) a
  `user://` override is private to one machine, needs a small store and a
  "reset to the game's data" control, and never changes a fixture; (b) a
  write-back edits `levels.gd` or a scenario JSON from inside the game, so an
  edit becomes shared data but needs a GDScript/JSON writer and a guard that
  it only runs in a development checkout.

## Read on demand

- `plans/design/progression.md` sections 4.2, 5.2, 6 and 11 step 7 -- only if
  a slice here needs the tier ladder or reachability reasoning.
- `docs/challenge-stages.md` -- what each Challenge 2 stage asks the player.
