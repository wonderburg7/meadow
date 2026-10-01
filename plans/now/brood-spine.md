# Brood spine — Nurses and Honey worker are bought, and each run has one availability sheet

<!-- CONTEXT: plan | LAYER: immediate-task -->
Status: active | Owner: Dave / Claude Code | Next: BS-8 -- a role's starting count is one roles.gd field (startable, Codex lane, from the 30 Sep architecture review); BS-6 -- developer edits, specified 1 Oct 2026, gated on BS-8 (BS-7 landed 1 Oct 2026) | Dependency: none -- AP-8 landed 24 Sep 2026, so progression step 7 is no longer waiting | Verified: 2026-10-01

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
   introduces Honey yet, and whichever first does must do the same. Decision 5
   narrows this for Nurses.
2. **Seeding implies owning.** A run that starts with bees in a gated role --
   a level's or scenario's `nurses`/`honey_makers`, or Challenge 1's queen,
   whose `queen_laying_backup` is Nurse -- starts owning that role's skill.
   One rule, applied at run start from the run definition; no level or
   scenario lists these grants by hand. Levels 4-6, Challenge 1 and every
   existing fixture therefore play exactly as today. (Superseded in part by
   decision 5: levels 3-7's queens now back up as Nurses.)
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

## Decisions (Dave, 30 Sep 2026, product review)

Asked in the session that wrote `docs/product-review-2026-09-30.md`.

5. **Every ordinary run's queen backs up as a Nurse.** Each Scenario level
   (3-7) names Nurse as its queen's `queen_laying_backup`, as Challenge 1
   does, so under decision 2 every Scenario owns Nurses from the start and a
   lone queen can nurse her own first larva, as the five-minute first worker
   of `plans/design/product-scope.md` §3 needs (BS-7 measures level 3's).
   Nurses is still bought wherever a
   run gives the queen no backup: Challenge 2 removes the grant
   (product-scope §2) and gives Nurses free at 2.5. Honey worker is
   unchanged. Why: since BS-3, Scenario 3 as `levels.gd` defines it ran 11
   days at seed 4242 with no brood fed and one larva dead, and a lone queen
   cannot bank 120 nectar and 80 pollen inside five minutes. BS-7 builds it.
6. **Developer edits persist as a `user://` override** (BS-5's option (a)):
   private to one machine, a small store applied at run start, a "reset to
   the game's data" control, and no fixture ever changed. The review
   recommended deferring BS-6 past the internal alpha; Dave chose to build
   it. BS-4's closeout specifies it.

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
| BS-7 | every Scenario's queen backs up as a Nurse, so a lone queen raises a worker | `scripts/levels.gd`, `test_scenarios/bs7_queen_backup_nurse_test.json` | startable | medium |
| BS-8 | a role's starting-count key is one field on its roles.gd row, before step 8 gates more roles | `scripts/roles.gd`, `scripts/run_availability.gd`, `scripts/world_building.gd`, `scripts/main.gd`, `tests/source_checks.py` | startable (Codex lane) | medium |
| BS-6 | developer edits to the table change what a run starts with | `scripts/developer_overrides.gd`, `scripts/run_availability_panel.gd`, `scripts/main.gd`, `tests/source_checks.py` | gated: BS-8 lands first (shared file; BS-7 landed 1 Oct 2026) | high |

BS-4, BS-7 and BS-8 share no file and are independent. Every later slice names
what it waits for above; each is specified in full when it becomes startable.

BS-1, BS-2, BS-3 and BS-5 shipped between 28 and 30 Sep 2026; each
specification is in `plans/archive/` under its id and date
(`plans/archive/BS-1_2026-09-28.md` and so on).

BS-4 shipped 2026-10-01; its specification is `plans/archive/BS-4_2026-10-01.md`.

## BS-7 — every Scenario's queen backs up as a Nurse

Level: medium (one data change and one scenario; a failure is escalated,
never tuned here). Decision 5 above.

**Now.** `scripts/levels.gd` gives only Challenge 1's queen a
`queen_laying_backup` (`"nurse"`). Scenario levels 3-7 give none, so a
Scenario owns Nurses only if it seeds nurses (levels 4-6). Levels 3 and 7
raise nothing until the player buys Nurses: at seed 4242, level 3's start ran
11 days with no brood fed and one larva dead (product review, 30 Sep 2026).

**Change.** In `scripts/levels.gd`, add `const ORDINARY_QUEEN_BACKUP :=
"nurse"` above `LEVELS`, with a comment naming decision 5 of
`plans/now/brood-spine.md`, and add `"queen_laying_backup":
ORDINARY_QUEEN_BACKUP,` to levels 3, 4, 5, 6 and 7. Nothing else: `bee.gd`
(the queen's default backup, where it reads `queen_laying_backup`) and
`run_availability.gd::_seeded_skills` already read the field, so the queen
takes the backup and the run owns Nurses through the existing rule.

**Must not change.** Level 1 keeps its own literal `"nurse"`; level 2
(Challenge 2) stays without a backup and keeps Nurses free at 2.5;
`bee.gd`, `run_availability.gd` and every existing scenario JSON (a fixture
is its own run definition).

**Scenario.** `test_scenarios/bs7_queen_backup_nurse_test.json`: level 3's
starting colony copied from `levels.gd` (3 cells, one nectar and one pollen
forager, no nurses, builders or miners) plus `"queen_laying_backup":
"nurse"`, `"random_seed": 4242` and `"winter": false`. Actions: `settle` one
tick; `assert` `{"skill_owned": "skill.brood.nurses"}`; then the same
`assert` with `"when": {"population_at_least": {"count": 4}}`. With no role
named, that key counts every adult bee including the queen, so it holds only
once a worker has hatched. `"stop": {"when_actions_resolved": true,
"max_days": 8}`.

**Escalate** if the second assert is still unresolved at day 8: a queen
nursing as her backup does not raise a worker from level 3's start, and what
to change is Dave's call.

**Downstream.** PE-2, the played pacing arc (`plans/now/pacing-evidence.md`,
"Later"), starts from a Scenario whose queen has this backup, so it waits
for BS-7 as well as for WO-1 and the Colony Run definition.

```queue
**[Claude] BS-7 -- every Scenario's queen backs up as a Nurse**
- Plan: `plans/now/brood-spine.md` -- "BS-7 — every Scenario's queen backs up as a Nurse"
- Files: `scripts/levels.gd`, `test_scenarios/bs7_queen_backup_nurse_test.json`
- Check: `python tools/run_scenario.py test_scenarios/bs7_queen_backup_nurse_test.json` passes, a worker hatching from level 3's start within 8 days, and `tools/verify.ps1` is green
- Proof: `absent: scripts/levels.gd :: ORDINARY_QUEEN_BACKUP`
- Next after: BS-6 -- developer edits to the table change what a run starts with
```

## BS-8 — a role's starting count is one field on its roles.gd row

Level: medium, behaviour-preserving (architecture review 30 Sep, F3). **Now:**
the count key is spelled in `run_availability.gd::SEED_COUNT_KEYS` (a gated
role missing there is not seeded; its `push_error` fails no headless run),
`world_building.gd::_spawn_hive_occupants`, `main.gd::_apply_scenario_boot_arg`
and `tests/source_checks.py::check_stage_role_skills`. Step 8 gates Comb worker
and Miner, which levels 4-6 seed. **Change.** (1) `roles.gd`: on the
line after each row's `"skill"`, add `"start_count_key"`/`"start_config"`:
Nurse `"nurses"`/`"starting_nurses"`, Comb worker `"builders"`/
`"starting_builders"`, Miner `"miners"`/`"starting_miners"`, Honey
`"honey_makers"`/`"starting_honey_makers"`, `""` elsewhere; document them by
`skill`'s comment; cut the header list's two BS-8 clauses. (2)
`run_availability.gd`: delete `SEED_COUNT_KEYS`; `_seeded_skills` skips a row
with an empty `skill` or `start_count_key`. (3) `_spawn_hive_occupants`: one
loop over `main.Roles.ROLES` for rows with a `start_count_key`, count
`int(level.get(key, 0))`, or `int(GameConfig.get(row.start_config))` for an
empty level, `_spawn_indoor_bee(row.id)`, the Miner's `automine` line kept.
(4) `_apply_scenario_boot_arg` defaults only `cells` and the forager keys. (5)
`check_stage_role_skills` reads `start_count_key`; a new check fails a row
missing either field, or `SEED_COUNT_KEYS` returning. **Must not change:**
spawn order (table order is today's; spawning draws from the RNG), `levels.gd`,
scenario JSON, `game_config.gd`, `settings_catalogue.gd` and the level-0
fallback (product-scope §6.2). **Escalate** if the equivalence run differs.

```queue
**[Codex] BS-8 -- a role's starting count is one field on its roles.gd row**
- Plan: `plans/now/brood-spine.md` -- "BS-8 — a role's starting count is one field on its roles.gd row"
- Files: `scripts/roles.gd`, `scripts/run_availability.gd`, `scripts/world_building.gd`, `scripts/main.gd`, `tests/source_checks.py`
- Check: `python tools/equivalence.py test_scenarios/colony_30_bees_test.json master` exits 0, `python tools/run_scenario.py` passes `test_scenarios/bs1_seeded_skills_test.json`, `test_scenarios/bs1_seeded_none_test.json` and `test_scenarios/bs3_nurse_gate_test.json`, and `tools/verify.ps1` is green
- Proof: `present: scripts/run_availability.gd :: const SEED_COUNT_KEYS`
- Next after: BS-6 -- developer edits to the table change what a run starts with
```

## Later slices, in outline

Each is specified in full, with its own `queue` block, when what it waits for
has shipped. These notes fix only what the earlier slices must not preclude.

Nothing is outlined here now: BS-6 is specified in full below.

## BS-6 — developer edits to the table change what a run starts with

Level: high (a persisted store and a run-start hook). Specified 1 Oct 2026 in
BS-4's closeout, from decision 6 (option (a): a `user://` override, private to
one machine, never a fixture). **Gated** on BS-8 landing, because both edit
`run_availability.gd` (BS-7, which also read level definitions, landed 1 Oct 2026);
the lanes may not share a file.

- **Scope.** The Run availability table (`run_availability_panel.gd`, opened
  from the debug panel) is read-only today. Each skill row gains a control
  cycling start / tree / unavailable for the level being viewed. An edit
  changes that level's run definition only through `skill_grants` and
  `skill_bans`, the two keys `sheet_for` already honours; it never edits a
  starting count, since "seeding implies owning" derives from counts.
- **Store.** New `scripts/developer_overrides.gd`: one small JSON file,
  `user://developer_start_overrides.json`, mapping level id to
  `{"grants": [...], "bans": [...]}`. `apply(level_id, definition)` returns a
  copy of the definition with the lists merged (a ban still wins over a
  grant, as in `run_availability.gd`). Missing or unparseable file reads as
  no overrides.
- **Hook.** `main.gd` line ~417, where `RunAvailability.sheet_for(level)` runs,
  passes the level through `apply` first. Scenario runs (level 999 /
  `SCENARIO_LEVEL_ID`) and headless runs are never overridden, so every
  fixture and `tools/verify.ps1` behave exactly as before.
- **Reset.** A "Reset to the game's data" button on the panel deletes the
  file and rebuilds the table. Edited rows are marked so a developer can see
  they differ from `levels.gd`.
- **Must not change:** `levels.gd`, any scenario JSON, save files, or
  `progression.gd`'s ownership answers.
- **Escalate** if a run started with an override and one without differ in
  anything beyond starting ownership.

```queue-gated
**[Claude] BS-6 -- developer edits to the table change what a run starts with**
- Plan: `plans/now/brood-spine.md` -- "BS-6 — developer edits to the table change what a run starts with"
- Files: `scripts/developer_overrides.gd`, `scripts/run_availability_panel.gd`, `scripts/main.gd`, `tests/source_checks.py`
- Check: `tools/verify.ps1` is green, a `source_checks.py` check proves `main.gd` applies `DeveloperOverrides` only outside scenario runs, and Dave confirms in the Run availability table that an edited row changes the next run's start and "Reset" restores it
- Proof: `absent: scripts/run_availability_panel.gd :: DeveloperOverrides`
- Next after: none -- the Brood spine plan completes here
```

## Read on demand

- `plans/design/progression.md` sections 4.2, 5.2, 6 and 11 step 7 -- only if
  a slice here needs the tier ladder or reachability reasoning.
- `docs/challenge-stages.md` -- what each Challenge 2 stage asks the player.
