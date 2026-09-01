# Next steps

<!-- CONTEXT: current-queue | LOAD: every session -->

Read this first in a new session. Keep exactly the current slice, one successor
and one blocker here. Open only the named `plans/` file and heading; history is
on demand in `plans/archive/`.

## Next up

1. **Current — Challenge 1 Slice 10: Bundle D/E's manual-to-automatic
   foraging arc (`plans/now/challenge-1.md`).** 10a, 10c, 10d, 10f and 10g
   are now code-complete (`tools/verify.ps1` green): `command_collect_from()`
   no longer permanently promotes the queen to Forager during 1.6-1.10
   (`Bee.role_change_locked`), and checks the flower-occupied guard before
   mutating anything, not after (10a/10g); stage 1.13 now runs the same
   `"freeze_bee:queen"` on_exit effect 1.11 already ships, so pollen
   foraging stops at the taught 75-unit mark instead of overshooting toward
   the cell's real 200-unit capacity (10c); 1.8/1.9's goals now read a real
   per-stage collection counter instead of the size of the queen's private
   `flower_cooldowns` memory, which also grew on a rejected flower (10f);
   the "Doing" (nectar/pollen) row and `Bee.set_focus()` now key off
   whichever role the queen is actively working (primary or backup), not
   just her primary role, so pollen was genuinely unreachable while she
   foraged via her backup role — traced statically (no live Godot boot
   available/needed) via `Bee.current_working_role()` and `hud.gd`'s new
   `_common_working_role()` (10d). 10b needed no code -- Slice 9a's own fix
   already covers it. Re-run Bundle D/E's live checks to confirm all of the
   above (`checks/ready.md`). 10e is resolved (1 Sep): Dave confirmed the
   "Laying" he saw was the expected new "Change to..." choice after the
   third cell, not the already-known 9d marker bug -- no code change,
   closed. Slice 9 (9a-9j) is code-complete, merged 1 Sep -- re-run Slice
   7's full acceptance playthrough only once Bundle D/E's checks above are
   confirmed.
2. **Successor — `plans/now/hive-comb.md` Slice 4: automatic comb-building
   spiral order looks wrong (general play, not the queen-specific bug
   Challenge 1 Slice 8d already fixed).** The isolated Scenario repro
   (`test_scenarios/hive_comb_spiral_repro.json`) is written and its headless
   trace now confirms candidate cause 1: every idle Comb Worker calls
   `hive.find_unfinished_cell()` before `create_next_cell_site()`
   (`scripts/bee.gd:1359-1367`, `scripts/hive.gd:553-557`) with no cap on how
   many workers can queue onto the same uncompleted site, so all four
   workers in the repro build one cell together, then move to the next one
   together, rather than spreading across the ring in parallel — see the
   plan's own section for the trace detail. Still needs Dave's live-boot
   look (the `godot` MCP server hasn't connected this session or the one
   before it) and a call on the intended behaviour, since capping builders
   per site is a build-throughput/balance change, not only a visual one,
   before any code is written. Slices 1-3 (empty-cell sprite
   alignment), 6 (above-centre-row cell rendering) and 7 (comb navigation A*
   cost invalidation) are all now code-complete, merged to master 1 Sep
   (`codex/hive-comb`, `codex/hive-comb-slice-7`, and Slice 6's local
   `dd1b7ab`), hands-on confirmation pending in `checks/ready.md`. Slice 5
   (cell-content feedback lag) also still needs its own live repro.
   Also code-complete and awaiting Dave's hands-on confirmation
   (`checks/ready.md`), not blocking either slice above: Challenge 2 Slices
   B (Meadow/Foraging button unlocks) and D (death marker selection glow),
   both from `codex/hands-on-bd`/`plans/now/hands-on-fixes-2026-08-31.md`;
   and UI-P-1/3/4/7/8 (info-badge tooltip wrap, pre-run menu hex borders and
   left margin, Dr Gallerin bubble, summary/command tray responsive fixes)
   from `codex/ui-p`/`codex/ui-p-2`/`plans/now/ui.md` (UI-P-2/5/6 remain
   unimplemented). `plans/active/foraging-evidence.md` Slice 1 (orientation
   flight/scouting wired as mutually exclusive, not parent/child) is also
   code-complete and merged 1 Sep, awaiting the same live confirm; Slice 2
   (proximity recruitment) and Slice 3 (safe forager return reserve) are
   ready to pick up on their own schedule, not prioritised ahead of the
   above.
3. **Blocked — save/load during an active Challenge.** Deferred in
   `DESIGN_BACKLOG.md`: `SaveGame` has no Challenge stage/gate/prompt
   schema, so `debug_panel.gd::set_save_load_enabled(false)` keeps
   ordinary save/load off for the whole duration (`challenge_runner.gd`).
   A Challenge-aware schema is a separate high-risk design task, not an
   incidental UI change (`.claude/rules/saving.md`).

All other unprioritised work remains in its owning plan. Do not copy it into
this queue merely to keep it visible.
