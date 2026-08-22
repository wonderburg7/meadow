# Next steps

Read this first in a new session, before anything else in CLAUDE.md.
Only the next 1-3 actions belong here -- full detail lives in the named
plan file, full history in `git log`.

## Next up

1. **Challenge 1 revamp** -- start Bundle A (stage-array skeleton +
   trigger tag), then Bundle B (auto-mine sequence). Full plan:
   `CHALLENGE1_REVAMP_PLAN.md`; read “What already exists” first.
2. **UI bugfix plan -- from Dave's 22 Aug hands-on pass, Slices 1-3 done.**
   Full eight-slice plan, each root-caused against the actual code and
   tagged with a suggested model, in `UI_BUGFIX_PLAN.md`. Slice 1
   (hud.gd font-size conversion) had never actually been committed
   despite NEXTSTEPS previously saying so -- hud.gd still had all 50
   raw `add_theme_font_size_override` calls and no `UiTheme.build_theme()`
   applied anywhere, so this session did it for real before starting
   Slice 3. Slice 2 (debug_panel.gd) was genuinely done already. Slice 3
   (panel/button stylebox wiring in `hud.gd`/`debug_panel.gd`, plus
   generalising `colour_blind_mode` to the nursery zone glow -- the one
   colour-only spot debug_panel.gd's own tooltip named that wasn't
   wired) is now done too; `source_checks.py`/`balance_tests.py` pass
   and the project boots clean under `mcp__godot__run_project` with no
   new parser or runtime errors. **Not yet Dave-verified in-game** --
   next session should open a save, check text scale/theme/typeface
   actually change the top bar, goal shelf, selection tray, command
   tray and every popup, and check colour-blind mode on the nursery
   zone glow. **Next concrete action after that:** Slice 0's three open
   decisions (icon-only buttons, bottom-row column layout, which popups
   move) are still unconfirmed and gate Slice 4; Slice 5 + Slice 7 are
   independent and can go first if Slice 0 isn't answered yet.
