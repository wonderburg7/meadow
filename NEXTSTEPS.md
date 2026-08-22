# Next steps

Read this first in a new session, before anything else in CLAUDE.md.
Only the next 1-3 actions belong here -- full detail lives in the named
plan file, full history in `git log`.

## Next up

1. **Challenge 1 revamp** -- start Bundle A (stage-array skeleton +
   trigger tag), then Bundle B (auto-mine sequence). Full plan:
   `CHALLENGE1_REVAMP_PLAN.md`; read “What already exists” first.
2. **UI bugfix plan -- from Dave's 22 Aug hands-on pass, Slices 1-2 done.**
   Full eight-slice plan, each root-caused against the actual code and
   tagged with a suggested model, in `UI_BUGFIX_PLAN.md`. Slice 1
   (hud.gd font-size conversion) and Slice 2 (debug_panel.gd font-size
   conversion; the Appearance/Accessibility category split it also
   called for turned out already done under UI Plan slice 5) are both
   committed and checks pass. **Next concrete action:** Slice 3 (wire
   `hud.gd`'s trays and `debug_panel.gd` to
   `UiTheme.panel_stylebox()`/`button_stylebox()`, and generalise
   `colour_blind_mode` beyond the nursery ring) -- needs 1+2's work in
   place to judge visually, which it now has. Slice 0's three open
   decisions (icon-only buttons, bottom-row column layout, which popups
   move) are still unconfirmed and gate Slice 4.
