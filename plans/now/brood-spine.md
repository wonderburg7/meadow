# Brood spine — Nurses and Honey worker are bought, and each run has one availability sheet

<!-- CONTEXT: plan | LAYER: immediate-task -->
Status: complete | Owner: Dave / Claude Code | Next: nothing further -- BS-12 landed 4 Oct 2026 (BS-6 landed 4 Oct 2026: the developer table's edits to skill_grants/skill_bans live in `user://developer_start_overrides.json` and change the next run's start outside scenario and headless runs; hands-on check C-112, `checks/ready/C-112.md`). The table's "Introduced at stage" and "Free at stage" columns still read "not yet available": `skills.gd`'s `introduced_by` stays empty until the campaign meta tree exists (`plans/design/progression.md` Phase C), so no slice can fill them yet | Dependency: none | Verified: 2026-10-04

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

Asked in the session that wrote `plans/archive/feedback-build_2026-10-05.md`.

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
| BS-12 | the Run availability button no longer calls the table read-only | `scripts/debug_panel.gd` | yes | low |

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

BS-6 shipped 2026-10-04; its specification is `plans/archive/BS-6_2026-10-04.md`.

## BS-12 -- the Run availability button no longer calls the table read-only

<!-- LAYER: immediate-task -->

Level: low (one file, two strings). Specified 4 Oct 2026 from BS-6's
closeout, which named it as an unfiled follow-up.

**True now** (verified 4 Oct 2026 on branch claude/BS-6). BS-6 made the
Run availability table editable: a skill row's source is a button, and
"Reset to the game's data" deletes the edits. `debug_panel.gd` still
describes it as read-only in two places: the comment above `developer_row`
("the read-only Run availability table they open") and the action row's
hover text in `_refresh_developer_row` ("Developer mode: a read-only table
of this run's skills, ...").

**True afterwards.** Both describe the table as BS-6 left it: it shows what
a run of this level starts owning, leaves to the skill tree or does not
offer, and why, and a click on a skill's source changes what the next run
of this level starts with, on this machine only. The wording follows the
table's own intro line in `run_availability_panel.gd`; nothing else
changes.

**Must not change.** The table, `developer_overrides.gd`, or when the
button is built.

```queue
**[Claude] BS-12 -- the Run availability button no longer calls the table read-only**
- Plan: `plans/now/brood-spine.md` -- "BS-12 -- the Run availability button no longer calls the table read-only"
- Files: `scripts/debug_panel.gd`
- Check: `grep -n "read-only" scripts/debug_panel.gd` finds nothing; a Godot boot is clean; `tools/verify.ps1` is green
- Proof: `present: scripts/debug_panel.gd :: a read-only table of this run's skills`
- Next after: none -- plans/now/brood-spine.md is complete
```

## Read on demand

- `plans/design/progression.md` sections 4.2, 5.2, 6 and 11 step 7 -- only if
  a slice here needs the tier ladder or reachability reasoning.
- `docs/challenge-stages.md` -- what each Challenge 2 stage asks the player.
