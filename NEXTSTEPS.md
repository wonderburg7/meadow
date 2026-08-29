# Next steps

<!-- CONTEXT: current-queue | LOAD: every session -->

Read this first in a new session. Keep exactly the current slice, one successor
and one blocker here. Open only the named `plans/` file and heading; history is
on demand in `plans/archive/`.

## Next up

1. **Current — Challenge 1 Slice 7: resume the acceptance-playthrough
   checklist.** Slice 8 (all four code changes: 8a's shared full-storage
   fix, 8b's manual-collection wait-at-flower fix, 8d's backup-role guard,
   8e's camera-follow/4x-speed presentation) is merged to master. 8c
   proposed no code change and is re-verified live as part of this pass.
   Re-run `plans/now/challenge-1.md`'s Slice 7 checklist (boot the project,
   play Challenge 1 start to finish against the "Acceptance checks" list,
   then the copy/doc pass) now that Slice 8's fixes are in.
2. **Successor — UI-O, fixes from Dave's 29 Aug hands-on pass, needs
   Dave's re-check.** His hands-on pass through UI-A to UI-N confirmed
   UI-A, UI-B, UI-C, UI-D/E/F, UI-G, UI-K and UI-L outright (closed, no
   further action). UI-N, UI-M, UI-I and UI-H each turned up real bugs,
   plus two new spots (the in-run Settings window and the main menu) that
   weren't covered yet -- all fixed in one pass as UI-O
   (`plans/now/ui.md`): the top-right bar's row1/settings-cog gap was
   actually zero, not the intended visible gap (UI-N), row-2 button
   tooltips are now one short line instead of a paragraph (UI-N), the
   settings window opened invisibly behind the pre-run menu when launched
   from its Settings button (UI-M, fixed via a contextual CanvasLayer
   z-order swap), the honeycomb now genuinely tessellates with touching,
   hex-accurate-hit-tested tiles instead of a separated row (UI-M), Dr
   Gallerin's bubble no longer loses its narrow-width reserve entirely
   (making the tray-overlap worse, not better) and its text now scales
   live rather than only at boot (UI-I), the summary panel's cog sits
   inline with the bee-name line instead of an empty row above it, and its
   width is now derived from the command tray's (10% wider) reserved zone
   rather than a fixed constant (UI-H), the settings window now opens
   below the full HUD bar instead of overlapping it and "Show info icons"
   no longer forces an unwanted horizontal scroll, and the pre-run menu's
   Settings button now uses the same cog glyph as the in-run one with its
   placeholder text no longer wrapping one letter per line. Confirmed with
   two headless Godot boots (fresh and `--scenario=`); check against
   `checks/ready.md`.
3. **Blocked — save/load during an active Challenge.** Deferred in
   `DESIGN_BACKLOG.md`: `SaveGame` has no Challenge stage/gate/prompt
   schema, so `debug_panel.gd::set_save_load_enabled(false)` keeps
   ordinary save/load off for the whole duration (`challenge_runner.gd`).
   A Challenge-aware schema is a separate high-risk design task, not an
   incidental UI change (`.claude/rules/saving.md`).

All other unprioritised work remains in its owning plan. Do not copy it into
this queue merely to keep it visible.
