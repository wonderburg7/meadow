# Next steps

<!-- CONTEXT: current-queue | LOAD: every session -->

Read this first in a new session. Keep exactly the current slice, one successor
and one blocker here. Open only the named `plans/` file and heading; history is
on demand in `plans/archive/`.

## Next up

1. **Current — Challenge 1 Slice 10: Bundle D/E's manual-to-automatic
   foraging arc (`plans/now/challenge-1.md`).** 10a, 10c, 10f and 10g are
   now code-complete, merged from `codex/challenge-1-slice-10`
   (`tools/verify.ps1` green): `command_collect_from()` no longer
   permanently promotes the queen to Forager during 1.6-1.10
   (`Bee.role_change_locked`), and checks the flower-occupied guard before
   mutating anything, not after (10a/10g); stage 1.13 now runs the same
   `"freeze_bee:queen"` on_exit effect 1.11 already ships, so pollen
   foraging stops at the taught 75-unit mark instead of overshooting toward
   the cell's real 200-unit capacity (10c); 1.8/1.9's goals now read a real
   per-stage collection counter instead of the size of the queen's private
   `flower_cooldowns` memory, which also grew on a rejected flower (10f).
   10b needed no code -- Slice 9a's own fix already covers it. Re-run
   Bundle D/E's live checks to confirm all of the above (`checks/ready.md`).
   10d (pollen sub-mode may be unreachable via the queen's backup-role path)
   and 10e ("building the third cell reveals Laying" is most likely the
   correct transition, not a new bug, but may instead be the already-known
   9d) both still need one live-reproduction step or a word from Dave before
   they're scoped as code changes. Slice 9 (9a-9j) is code-complete, merged
   1 Sep -- re-run Slice 7's full acceptance playthrough only once 10d/10e
   are resolved and Bundle D/E's checks above are confirmed.
2. **Successor — `plans/now/hive-comb.md` Slice 6: cells above the comb's
   centre row don't render.** Traced to `hive_cell.gd`'s z_index formula
   silently assuming a value that goes negative above the centre, very
   likely surfaced by the recent hex-grid radial-symmetry fix letting the
   comb grow upward for the first time. Confirmed-plausible, pending one
   live scene-inspector look (see the plan's own section) before picking
   between its two fix options. Slices 1-3 (empty-cell sprite alignment)
   and Slice 7 (comb navigation A* cost invalidation) shipped from
   `codex/hive-comb`/`codex/hive-comb-slice-7`, merged to master 1 Sep,
   hands-on confirmation pending in `checks/ready.md`.
   Also code-complete and awaiting Dave's hands-on confirmation
   (`checks/ready.md`), not blocking either slice above: Challenge 2 Slices
   B (Meadow/Foraging button unlocks) and D (death marker selection glow),
   both from `codex/hands-on-bd`/`plans/now/hands-on-fixes-2026-08-31.md`;
   and UI-P-1/3/4/7/8 (info-badge tooltip wrap, pre-run menu hex borders and
   left margin, Dr Gallerin bubble, summary/command tray responsive fixes)
   from `codex/ui-p`/`codex/ui-p-2`/`plans/now/ui.md` (UI-P-2/5/6 remain
   unimplemented). `plans/active/foraging-evidence.md` (orientation flight,
   proximity recruitment, safe forager return reserve) is ready to pick up
   on its own schedule, not prioritised ahead of the above.
3. **Blocked — save/load during an active Challenge.** Deferred in
   `DESIGN_BACKLOG.md`: `SaveGame` has no Challenge stage/gate/prompt
   schema, so `debug_panel.gd::set_save_load_enabled(false)` keeps
   ordinary save/load off for the whole duration (`challenge_runner.gd`).
   A Challenge-aware schema is a separate high-risk design task, not an
   incidental UI change (`.claude/rules/saving.md`).

All other unprioritised work remains in its owning plan. Do not copy it into
this queue merely to keep it visible.
