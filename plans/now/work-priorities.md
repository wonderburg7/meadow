# Work Priorities -- Hive Mind tier 3: one colony-wide order of fallback jobs

<!-- CONTEXT: plan | LAYER: active -->
Status: active | Owner: Dave / Claude Code | Next: decisions being recorded in the 12-13 Oct 2026 plan-ahead session; slices follow | Dependency: the catalogue slice shares `scripts/skills.gd` with PP-5 (Claude lane) and waits for it | Verified: 2026-10-13

## Objective

`plans/design/product-scope.md` §6.1 lists "Tier-3 Work Priorities
progression" as essential for the closed alpha, and §8 makes Work Priorities
Hive Mind tier 3, the control surface that replaces the cut Extended Backup
Roles. Nothing builds it, and the skill catalogue contradicts the design.

## Current state

Verified 13 Oct 2026 against master `06bd26c`:

- `scripts/skills.gd` has `skill.colony.work_priorities` as a tier-0
  baseline ("Cells, zones and orders can be given priority over one
  another"), which is what `orders_zones.gd`'s cell `nursery_priority`
  already does. Hive Mind tier 3 holds only Adjustment panel and Extended
  backup roles, both in `CUT_FROM_ALPHA`.
- A bee has one `role` and one `secondary_role` (`bee.gd`).
  `bee.gd::_idle_dispatch` runs only while a bee waits for work: own role
  first, then the backup; the queen nurses before laying. Backup roles is
  Hive Mind tier 1.

## Decisions (Dave, 13 Oct 2026, plan-ahead session)

1. **Work Priorities takes Extended backup roles' tier-3 slot**, which it
   supersedes (product-scope §8); Extended backup roles is retired from the
   catalogue. The tier-0 baseline that orders cells, zones and orders is
   renamed "Cell priority", so the two never share a name.
2. **Work Priorities turns each bee's single backup into an ordered list
   of backups** (Dave: "work priorities are per bee backups, they can just
   be ordered. so these replace the backup"). Once owned, an idle bee tries
   its own role, then each job on its own list in order, taking the first
   that has work. The list replaces the one `secondary_role`; it is not a
   colony-wide list. Dispatch happens only when a bee goes idle, as today,
   never per frame. The queen keeps today's rule (she nurses before laying).
   Bees leaving a role that still has work because another need is urgent
   (§8's full version) is out of the alpha.
3. **Default order: Comb work, Nurse, Mine, Honey, Forage.** Forage is last
   because there is always something to forage, so a bee that falls through
   to it never reaches anything below. Jobs the run has not unlocked or
   bought are left out until they are.

## Open questions

Being asked in the same session.
