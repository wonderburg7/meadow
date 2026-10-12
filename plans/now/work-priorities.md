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
2. **Owning it gives one colony-wide, player-ordered list of jobs**
   (Forage, Nurse, Comb work, Mine, Honey and the rest the run has). A bee
   works its own role first; when that has nothing, it takes the highest job
   on the list that has work, instead of a single backup. The per-bee role
   and backup stay as the individual override. Dispatch happens only when a
   bee goes idle, as today, never per frame. Bees leaving a role that still
   has work because another need is urgent (§8's full version) is out of
   the alpha.

## Open questions

Being asked in the same session.
