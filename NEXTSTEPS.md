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
2. **Successor — UI-D through UI-N top-bar, tray-width, Gallerin-bubble,
   Challenge-1 button, pre-run-menu and top-bar-gap work, needs Dave's
   hands-on confirmation.** All eleven implemented in `plans/now/ui.md`:
   the goal shelf passes pointer input through to the top-bar buttons
   beneath it (UI-D), every top-right control is doubled in size (UI-E),
   the goal shelf's vertical offset is now derived instead of hardcoded
   (UI-F), the command tray's three columns now share its full width
   instead of clustering left (UI-G), width shifted from the command tray
   to the summary panel (UI-H, may need Dave's tuning pass on the
   multipliers), Dr Gallerin's bubble is bigger, text-scale-aware and no
   longer auto-hides (UI-I), it now shrinks at a narrow window size like
   the summary panel does (UI-J, confirmed with a headless Godot boot as
   well as static checks), the Foraging button is hidden for the whole of
   Challenge 1 (UI-K), a fresh boot no longer simulates a hidden colony
   behind the pre-run menu (UI-L, confirmed with two headless Godot
   boots), the pre-run "choose where to start" menu is now a full-screen
   2:1 left/right split with 1.5x hexagons and a Settings button that
   opens the existing settings window straight to Accessibility/Appearance
   (UI-M), and the top-right bar's row1/row2/settings-cog gaps and row-2
   button footprints now share named constants (UI-N). Check against
   `checks/ready.md`.
3. **Blocked — save/load during an active Challenge.** Deferred in
   `DESIGN_BACKLOG.md`: `SaveGame` has no Challenge stage/gate/prompt
   schema, so `debug_panel.gd::set_save_load_enabled(false)` keeps
   ordinary save/load off for the whole duration (`challenge_runner.gd`).
   A Challenge-aware schema is a separate high-risk design task, not an
   incidental UI change (`.claude/rules/saving.md`).

All other unprioritised work remains in its owning plan. Do not copy it into
this queue merely to keep it visible.
