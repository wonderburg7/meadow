# Brood spine — Nurses and Honey worker are bought, and each run has one availability sheet

<!-- CONTEXT: plan | LAYER: immediate-task -->
Status: active | Owner: Dave / Claude Code | Next: BS-6 -- developer edits to the table change what a run starts with (BS-9, BS-10 and BS-11 landed 2 Oct 2026; queued 4 Oct 2026 with its scope check moved to `tests/test_run_scenario_launch.py`, so it no longer waits for SR-5) | Dependency: none -- AP-8 landed 24 Sep 2026, so progression step 7 is no longer waiting | Verified: 2026-10-04

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

## Decisions (Dave, 1 Oct 2026, feedback-build readiness review)

Asked in the session that wrote `plans/now/feedback-build.md`.

7. **The queen nurses without the Nurses skill; workers still need it.** An
   exception to BS-3's rule that a row of a role the colony has not bought is
   never worked, for the queen's own nursing only. Challenge 2 keeps no queen
   backup in its level data and keeps the free Nurses purchase of its stage
   2.5 (buy Nurses, then raise a nurse; C-67); its queen nurses through the
   backup every queen takes at setup. Why: Challenge 2's stage 2.2 asks the
   player to raise a pollen Forager, but nothing could feed a larva before
   stage 2.5 (`docs/product-review-2026-09-30.md` F10, C-83; the readiness
   probe of 1 Oct 2026 recorded no feed and a dead larva). Declined: rewording
   stage 2.2 to ask for a reassignment, and naming a queen backup for
   Challenge 2, which would make the run own Nurses and take stage 2.5's
   purchase away. BS-9 builds it.

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
| BS-6 | developer edits to the table change what a run starts with | `scripts/developer_overrides.gd`, `scripts/run_availability_panel.gd`, `scripts/main.gd`, `tests/test_run_scenario_launch.py` | yes -- BS-11 landed 2 Oct 2026; its check left `tests/source_checks.py` (SR-5's) on 4 Oct 2026 | high |

BS-11 went before BS-6 (reordered 2 Oct 2026): the two share
`run_availability_panel.gd`. Every later slice names
what it waits for above; each is specified in full when it becomes startable.

BS-1, BS-2, BS-3 and BS-5 shipped between 28 and 30 Sep 2026; each
specification is in `plans/archive/` under its id and date
(`plans/archive/BS-1_2026-09-28.md` and so on).

BS-4 shipped 2026-10-01; its specification is `plans/archive/BS-4_2026-10-01.md`.

BS-7 shipped 2026-10-01; its specification is `plans/archive/BS-7_2026-10-01.md`.

BS-8 shipped 2026-10-01; its specification is `plans/archive/BS-8_2026-10-01.md`.

## Later slices, in outline

Each is specified in full, with its own `queue` block, when what it waits for
has shipped. These notes fix only what the earlier slices must not preclude.

Nothing is outlined here now: BS-9 and BS-6 are specified in full below.

BS-9 shipped 2026-10-02; its specification is `plans/archive/BS-9_2026-10-02.md`.

## BS-6 — developer edits to the table change what a run starts with

Level: high (a persisted store and a run-start hook). Specified 1 Oct 2026 in
BS-4's closeout, from decision 6 (option (a): a `user://` override, private to
one machine, never a fixture). It was gated on BS-8, which shared
`run_availability.gd` across the lanes; BS-8 landed 1 Oct 2026. It now
waited for SR-5 (Codex lane), which also edits `tests/source_checks.py`; on
4 Oct 2026 (Dave) its scope check moved to `tests/test_run_scenario_launch.py`,
a module `tools/verify.ps1` already runs and no other lane owns, so it is
queued.

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

```queue
**[Claude] BS-6 -- developer edits to the table change what a run starts with**
- Plan: `plans/now/brood-spine.md` -- "BS-6 — developer edits to the table change what a run starts with"
- Files: `scripts/developer_overrides.gd`, `scripts/run_availability_panel.gd`, `scripts/main.gd`, `tests/test_run_scenario_launch.py`
- Check: `tools/verify.ps1` is green, a source-reading test in `tests/test_run_scenario_launch.py` proves `main.gd` applies `DeveloperOverrides` only outside scenario runs, and Dave confirms in the Run availability table that an edited row changes the next run's start and "Reset" restores it
- Proof: `absent: scripts/run_availability_panel.gd :: DeveloperOverrides`
- Next after: none -- the last slice in this plan
```

BS-10 shipped 2026-10-02; its specification is `plans/archive/BS-10_2026-10-02.md`.

BS-11 shipped 2026-10-02; its specification is `plans/archive/BS-11_2026-10-02.md`.

## Read on demand

- `plans/design/progression.md` sections 4.2, 5.2, 6 and 11 step 7 -- only if
  a slice here needs the tier ladder or reachability reasoning.
- `docs/challenge-stages.md` -- what each Challenge 2 stage asks the player.
