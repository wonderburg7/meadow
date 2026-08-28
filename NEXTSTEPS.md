# Next steps

<!-- CONTEXT: current-queue | LOAD: every session -->

Read this first in a new session. Keep exactly the current slice, one successor
and one blocker here. Open only the named `plans/` file and heading; history is
on demand in `plans/archive/`.

## Next up

1. **Current — Challenge 1 manual-teaching revamp.** Slices 1–7 in
   `plans/now/challenge-1.md` are code-complete and merged. What remains is
   Dave's hands-on acceptance playthrough against `checks/ready.md`'s
   Challenge 1 Bundles D–G, then the plan's own status/archive rewrite.
2. **Successor — UI-D Challenge top-bar hit-area fix, needs Dave's hands-on
   confirmation.** Cause found and fixed in `plans/now/ui.md`: the goal
   shelf now passes pointer input through to the top-bar buttons beneath
   it. Check against `checks/ready.md`.
3. **Blocked — save/load during an active Challenge.** Deferred in
   `DESIGN_BACKLOG.md`: `SaveGame` has no Challenge stage/gate/prompt
   schema, so `debug_panel.gd::set_save_load_enabled(false)` keeps
   ordinary save/load off for the whole duration (`challenge_runner.gd`).
   A Challenge-aware schema is a separate high-risk design task, not an
   incidental UI change (`.claude/rules/saving.md`).

All other unprioritised work remains in its owning plan. Do not copy it into
this queue merely to keep it visible.
