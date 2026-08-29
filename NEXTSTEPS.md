# Next steps

<!-- CONTEXT: current-queue | LOAD: every session -->

Read this first in a new session. Keep exactly the current slice, one successor
and one blocker here. Open only the named `plans/` file and heading; history is
on demand in `plans/archive/`.

## Next up

1. **Current — Challenge 1 Slice 8: fix acceptance-playthrough findings.**
   `plans/now/challenge-1.md`'s Slice 7 hands-on pass (29 Aug 2026) found
   six bugs, now scoped as Slice 8: a shared full-storage bug that silently
   discards a forager's carried resource (8a, affects ordinary play too,
   not just Challenge 1), the queen auto-flying home during manual nectar
   collection instead of waiting at the flower (8b), an unguarded "If idle"
   backup-role menu letting the queen's secondary role become Comb Worker
   and auto-build the whole hex spiral (8d), and the still-unbuilt
   camera-follow/4x-speed presentation for automatic nectar foraging (8e).
   Land 8a first (everything else depends on foraging not silently losing
   resource), then 8b/8d (independent of each other), then 8e. Re-run
   Slice 7's checklist only once Slice 8 is done.
2. **Successor — UI-D through UI-N: top-bar/tray/menu work.** UI-D through
   UI-K (top-bar hit-area, doubled buttons, goal-shelf placement,
   tray-width, Gallerin-bubble, Foraging-button hiding) are implemented and
   still need Dave's hands-on confirmation against `checks/ready.md`. Three
   new slices are scoped and ready once that check is done: UI-L stops the
   simulation running behind the pre-run menu before Start is pressed,
   UI-M redesigns that menu full-screen (2:1 left/right split, 1.5x
   hexagons, a new Settings button), and UI-N unifies the in-run top-right
   bar's row-2 button spacing/sizing onto one shared constant.
3. **Blocked — save/load during an active Challenge.** Deferred in
   `DESIGN_BACKLOG.md`: `SaveGame` has no Challenge stage/gate/prompt
   schema, so `debug_panel.gd::set_save_load_enabled(false)` keeps
   ordinary save/load off for the whole duration (`challenge_runner.gd`).
   A Challenge-aware schema is a separate high-risk design task, not an
   incidental UI change (`.claude/rules/saving.md`).

All other unprioritised work remains in its owning plan. Do not copy it into
this queue merely to keep it visible.
