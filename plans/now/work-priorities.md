# Work Priorities -- Hive Mind tier 3: one colony-wide order of fallback jobs

<!-- CONTEXT: plan | LAYER: active -->
Status: active | Owner: Dave / Claude Code | Next: WP-2 -- owned, each bee follows an ordered backup list (WP-1 catalogue landed 14 Oct 2026), then WP-3 | Dependency: none for WP-2 (FC-2, `plans/archive/crisis-readiness_2026-10-17.md`, released the save files 17 Oct 2026; WP-1 landed 14 Oct 2026); WP-3 after WP-2 | Verified: 2026-10-14

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
4. **Many bees: edit a selection, plus a colony default.** The selection
   panel's Backup row becomes an ordered list (up/down buttons,
   keyboard-reachable) that applies to every selected bee at once, as role
   changes already do. The Colony window holds a colony default list, which
   starts in decision 3's order and which every new bee takes. On purchase,
   each bee's current backup goes first, then the default order. The default
   list is saved with the run; a save without one uses decision 3's order.

## Open slices

| Slice | What it does | Files it owns | Startable | Level |
| --- | --- | --- | --- | --- |
| WP-2 | Owned, each bee follows an ordered backup list; a saved colony default | `scripts/bee.gd`, `scripts/session.gd`, `scripts/skills.gd`, `scripts/orders_zones.gd`, `scripts/save_game.gd`, `scripts/saving.gd`, `tests/wp2_backup_order_test.gd`, `tests/test_wp2_backup_order.py` | yes (FC-2 released the save files 17 Oct 2026; WP-1 landed 14 Oct 2026) | high |
| WP-3 | The ordered list in the selection panel and the colony default in the Colony window | `scripts/hud.gd`, `scripts/colony_panel.gd`, `scripts/orders_zones.gd`, `scripts/main.gd`, `test_scenarios/wp3_backup_order_ui.json`, `tests/test_wp3_backup_order_ui.py` | no -- after WP-2 | medium |

WP-1, then WP-2, then WP-3: each needs the one before. Dave's order (13 Oct
2026) is tier 3 first (`plans/archive/tier-three_2026-10-14.md` and this plan), then
`plans/now/short-term-goals.md`, then `plans/now/difficulty.md`. Do not
change Backup roles' behaviour for a run that does not own Work Priorities,
or the queen's nurse-before-laying rule.

**Price.** WP-1 keeps Extended backup roles' recipe as a guess. PP-6
(`plans/now/pollination.md`) sweeps tier-3 recipes; if WP-1 has landed by
then, its sweep prices Work Priorities too.

**Reads.** A slice reads its own section only; WP-2 also reads
`.claude/rules/saving.md` and `.claude/rules/simulation.md`, WP-3
`plans/reference/ui-rules.md`.

WP-1 shipped 2026-10-14; its specification is `plans/archive/WP-1_2026-10-14.md`.

## WP-2 -- owned, each bee follows an ordered backup list

<!-- LAYER: immediate-task -->

**Change.** `bee.gd` gains `backup_order`, an array of role ids. Without
Work Priorities nothing changes: `secondary_role` is the one backup, as
today. Owned, `_idle_dispatch` tries the bee's own role, then each role in
`backup_order` in turn (honouring `role_restricted_to`), taking the first
with work; `secondary_role` mirrors the entry being worked so
`working_secondary`, `current_working_role` and the HUD keep working. The
queen is unchanged. `Session` holds the colony default order, starting at
decision 3's; a bee created after purchase takes it, and on purchase each
existing bee gets its current backup first, then the default order. Roles
the run has not unlocked or bought are skipped. `orders_zones.gd` sets a
whole selection's order at once. `skills.gd`: status `existing`. Saves carry
each bee's `backup_order` and the default; a save without them gives each
bee `[secondary_role]` and the default order.

```queue
**[Claude] WP-2 -- owned, each bee follows an ordered backup list**
- Plan: `plans/now/work-priorities.md` -- "WP-2 -- owned, each bee follows an ordered backup list"
- Files: `scripts/bee.gd`, `scripts/session.gd`, `scripts/skills.gd`, `scripts/orders_zones.gd`, `scripts/save_game.gd`, `scripts/saving.gd`, `tests/wp2_backup_order_test.gd`, `tests/test_wp2_backup_order.py`
- Check: `python -m unittest tests.test_wp2_backup_order` passes (unowned, a bee falls back on its one backup as today; owned, an idle bee whose role and first backup have no work takes the next job on its list that does; a bee born after purchase takes the colony default; the lists and the default survive save and restore; an old save loads each bee with its backup first); `.\tools\verify.ps1` is green
- Proof: `absent: scripts/bee.gd :: backup_order`
- Next after: WP-3 -- the ordered list in the selection panel and the colony default
```

## WP-3 -- the ordered list in the selection panel and the colony default

<!-- LAYER: immediate-task -->

**Change.** Owned, the selection panel's Backup row becomes an ordered list
with up and down buttons, keyboard-reachable, applied to every selected bee
at once; a mixed selection shows its first bee's order and says so. The
Colony window gains a "New bees fall back on" list editing the colony
default. Unowned, the row is today's single Backup choice.

```queue-gated
**[Claude] WP-3 -- the ordered list in the selection panel and the colony default**
- Plan: `plans/now/work-priorities.md` -- "WP-3 -- the ordered list in the selection panel and the colony default"
- Files: `scripts/hud.gd`, `scripts/colony_panel.gd`, `scripts/orders_zones.gd`, `scripts/main.gd`, `test_scenarios/wp3_backup_order_ui.json`, `tests/test_wp3_backup_order_ui.py`
- Check: `python -m unittest tests.test_wp3_backup_order_ui` passes (owned, moving a job up in the selection panel reorders every selected bee's list; the Colony window list changes what a newly emerged bee takes; unowned, the single Backup choice is unchanged); `.\tools\verify.ps1` is green
- Proof: `absent: scripts/hud.gd :: backup_order`
- Next after: none -- the Work Priorities plan is complete; SG-2 in `plans/now/short-term-goals.md` follows in Dave's order
```

## Open questions

- Work Priorities' price: see "Price" above.
