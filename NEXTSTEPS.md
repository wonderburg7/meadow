# Next steps

Read this first in a new session, before anything else in CLAUDE.md.
Only the next 1-3 actions belong here -- full detail lives in the named
plan file, full history in `git log`.

## Next up

1. **Challenge 1 revamp** -- start Bundle A (stage-array skeleton +
   trigger tag), then Bundle B (auto-mine sequence). Full plan:
   `CHALLENGE1_REVAMP_PLAN.md`; read “What already exists” first.
2. **UI bugfix plan -- Slice 1 done, Slice 2 next.** Full eight-slice
   plan in `UI_BUGFIX_PLAN.md`. Slice 1 converted all 50 of `hud.gd`'s
   `add_theme_font_size_override` calls to `theme_type_variation`
   (Heading/Body/Small, by nearest pixel match to the old size -- see
   the diff for the CORNER_SIZES/goal-shelf judgement calls) and fixed
   the other half of "text scale does nothing": `hud.gd` extends
   CanvasLayer with a dozen independent top-level Controls (no single
   Control root to hang a theme off, unlike colony_panel.gd's one
   PanelContainer), so none of them were ever picking up
   `UiTheme.build_theme()` at all. Added a `hud_theme` var built once in
   `_ready()` and assigned to each of the 13 top-level roots (corner
   column, top-right bar, goal shelf, selection panel, command tray, the
   five popups, the discard dialog, pause label). `source_checks.py`/
   `balance_tests.py` clean, `FUNCTION_MAP.md` regenerated; a live Godot
   boot wasn't possible in this remote session (no display) --
   **Dave still needs to play at 100/150/200% text scale and confirm
   the top-right bar, goal shelf, selection tray and command tray all
   actually resize** before this slice is called done.
   **Next concrete action:** Slice 2 -- same font-size migration in
   `debug_panel.gd` (8 calls), plus splitting its "Interface" category
   into "Appearance"/"Accessibility" and wiring the theme selector if
   it isn't already exposed. Slice 0 (three open decisions -- icon-only
   buttons, bottom-row column layout, which popups move) is still
   unanswered and gates Slice 4 only, not Slice 2. `HANDS_ON_CHECKS.md`
   has been updated to point at this plan rather than re-list the same
   items.
