# Next steps

Read this first in a new session, before anything else in CLAUDE.md.
Only the next 1-3 actions belong here -- full detail lives in the named
plan file, full history in `git log`.

## Next up

1. **Challenge 1 revamp** -- start Bundle A (stage-array skeleton +
   trigger tag), then Bundle B (auto-mine sequence). Full plan:
   `CHALLENGE1_REVAMP_PLAN.md`; read “What already exists” first.
2. **UI bugfix plan -- from Dave's 22 Aug hands-on pass, not started.**
   Full eight-slice plan, each root-caused against the actual code and
   tagged with a suggested model, in `UI_BUGFIX_PLAN.md`. One root cause
   explains most of it: the slice-1b Theme migration (text scale, font
   choice, dark/light theme, panel styling) never reached `hud.gd` or
   `debug_panel.gd` -- the two files carrying almost everything on
   screen. Five further, unrelated bugs also root-caused: cell popup
   position, the meadow/hive button's hit area, follow-bee-on-
   hive-to-meadow, panel overlap on resize, and settings-window
   sections. **Next concrete action:** Slice 0 (confirm three open
   decisions with Dave -- icon-only buttons, the bottom-row column
   layout, which popups move) then Slices 1+2 (the mechanical font
   conversion, good for a cheaper model). `HANDS_ON_CHECKS.md` has been
   updated to point at this plan rather than re-list the same items.
