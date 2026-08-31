# Next steps

<!-- CONTEXT: current-queue | LOAD: every session -->

Read this first in a new session. Keep exactly the current slice, one successor
and one blocker here. Open only the named `plans/` file and heading; history is
on demand in `plans/archive/`.

## Next up

1. **Current — Challenge 1 Slice 10: Bundle D/E's manual-to-automatic
   foraging arc is still broken (`plans/now/challenge-1.md`).** Found in a
   second 31 Aug pass replaying stages 1.6-1.14. 10a/10c are the priority --
   both break the Bundle D/E teaching sequence outright: `command_collect_from()`
   (the manual right-click-a-flower command Bundle D itself uses) permanently
   promotes the queen to a real Forager via `set_role()`, a separate and more
   direct leak than Slice 9a's `role_restricted_to` finding and not fixed by
   9a alone (10a, needs one live-confirmation step before shipping -- see its
   own section); and no mechanism ever stops her automatic foraging once a
   stage's target amount is reached, so she overshoots toward the cell's real
   200-unit capacity instead of stopping at the taught 75/full mark (10c).
   10b ships alongside 9a's own fix. 10d (pollen sub-mode may be unreachable
   via the queen's backup-role path) and 10e ("building the third cell
   reveals Laying" is most likely the correct transition, not a new bug, but
   may instead be the already-known 9d) both need one live-reproduction step
   or a word from Dave before they're scoped as code changes.
   Slice 9 (9a-9j) is now code-complete, merged from `codex/challenge-1-slice-9`
   1 Sep -- `tools/verify.ps1` green; re-run Slice 7's full acceptance
   playthrough to confirm it (`checks/ready.md`), ideally alongside 10a/10c
   once those land, since 10a's fix changes the same `command_collect_from`
   path 9's own checks exercise.
2. **Successor — `plans/now/hive-comb.md` Slice 6: cells above the comb's
   centre row don't render.** Traced to `hive_cell.gd`'s z_index formula
   silently assuming a value that goes negative above the centre, very
   likely surfaced by the recent hex-grid radial-symmetry fix letting the
   comb grow upward for the first time. Confirmed-plausible, pending one
   live scene-inspector look (see the plan's own section) before picking
   between its two fix options. Slices 1-3 (empty-cell sprite alignment)
   shipped from `codex/hive-comb` 1 Sep, hands-on confirmation pending in
   `checks/ready.md`.
   Also code-complete and awaiting Dave's hands-on confirmation
   (`checks/ready.md`), not blocking either slice above: Challenge 2 Slices
   B (Meadow/Foraging button unlocks) and D (death marker selection glow),
   both from `codex/hands-on-bd`/`plans/now/hands-on-fixes-2026-08-31.md`;
   and UI-P-1/3/4/7 (info-badge tooltip wrap, pre-run menu hex borders and
   left margin, Dr Gallerin bubble) from `codex/ui-p`/`plans/now/ui.md`
   (UI-P-2/5/6/8 remain unimplemented). `plans/active/foraging-evidence.md`
   (orientation flight, proximity recruitment, safe forager return reserve)
   is ready to pick up on its own schedule, not prioritised ahead of the
   above.
3. **Blocked — save/load during an active Challenge.** Deferred in
   `DESIGN_BACKLOG.md`: `SaveGame` has no Challenge stage/gate/prompt
   schema, so `debug_panel.gd::set_save_load_enabled(false)` keeps
   ordinary save/load off for the whole duration (`challenge_runner.gd`).
   A Challenge-aware schema is a separate high-risk design task, not an
   incidental UI change (`.claude/rules/saving.md`).

All other unprioritised work remains in its owning plan. Do not copy it into
this queue merely to keep it visible.
