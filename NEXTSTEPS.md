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
2. **Successor — UI-D through UI-J top-bar, tray-width and Gallerin-bubble
   work, needs Dave's hands-on confirmation.** All seven implemented in
   `plans/now/ui.md`: the goal shelf passes pointer input through to the
   top-bar buttons beneath it (UI-D), every top-right control is doubled
   in size (UI-E), the goal shelf's vertical offset is now derived instead
   of hardcoded (UI-F), the command tray's three columns now share its
   full width instead of clustering left (UI-G), width shifted from the
   command tray to the summary panel (UI-H, may need Dave's tuning pass on
   the multipliers), Dr Gallerin's bubble is bigger, text-scale-aware and
   no longer auto-hides (UI-I), and it now shrinks at a narrow window size
   like the summary panel does (UI-J, confirmed with a headless Godot boot
   as well as static checks). Check against `checks/ready.md`.
3. **Blocked — save/load during an active Challenge.** Deferred in
   `DESIGN_BACKLOG.md`: `SaveGame` has no Challenge stage/gate/prompt
   schema, so `debug_panel.gd::set_save_load_enabled(false)` keeps
   ordinary save/load off for the whole duration (`challenge_runner.gd`).
   A Challenge-aware schema is a separate high-risk design task, not an
   incidental UI change (`.claude/rules/saving.md`).

All other unprioritised work remains in its owning plan. Do not copy it into
this queue merely to keep it visible.
