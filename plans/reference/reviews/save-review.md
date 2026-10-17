# Save, restore and migration review

<!-- CONTEXT: review-prompt | LOAD: only when running this review -->
Record key: save-review
Reasoning: high
Watches: scripts/save_game.gd scripts/saving.gd scripts/save_migrations.gd scripts/save_slots.gd scripts/tutorial_checkpoint.gd tests/test_save_migrations.py .claude/rules/saving.md

**Owns:** `scripts/save_game.gd`, `scripts/saving.gd`,
`scripts/save_migrations.gd`, `scripts/save_slots.gd`, checkpoints
(`scripts/tutorial_checkpoint.gd` and Challenge checkpoints), the durable
state of every system, and round-trip and migration coverage
(`tests/test_save_migrations.py` and related scenarios).

**Hand-offs:** how saves are presented to the player: UI review. Correctness
of live, unsaved gameplay state: gameplay consistency review.

**Rules that apply:** `.claude/rules/saving.md` (for example, restore is
all-or-nothing).

## Steps

1. **State inventory, from the code.** The last record holds an inventory:
   review only state added or changed since SINCE. Start from what the
   writers and readers gained (`git diff <SINCE>..HEAD -- scripts/save_game.gd
   scripts/saving.gd scripts/save_migrations.gd`), then the systems that
   gained state without a matching writer change (`git log --stat
   --format=%s <SINCE>..HEAD -- scripts/`, new `var` lines in the files it
   ranks highest). Sort each new piece into authoritative
   durable, derived, cached, temporary, UI-only or runtime state, and say
   whether it is saved, rebuilt on restore, or lost. Open system code only
   to confirm a field's category.
2. **Check for:** state that must survive a restore but is not saved
   (Challenge and stage, season, year, lifecycle, queen and gyne state,
   unlocks, objectives, random seed, queues, timers); saved state that
   should be derived; authority duplicated between scenes, singletons and
   save data; unstable identifiers and dangling references; subscriptions,
   timers, caches and dirty flags that come back wrong after a restore;
   `FORMAT_VERSION` and migration coverage for every version still in use;
   partial-write, corruption and rollback behaviour.
3. **For each issue** give: evidence; affected versions or flows; severity
   (loss, duplication, drift or crash); root cause; the recommended owner;
   migration implications; and the round-trip or migration test that fails
   today, stating what must and must not be true after loading.

Any change to the save schema or the compatibility policy is Dave's decision:
ask in this session, with the options and their costs.
