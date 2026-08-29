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
