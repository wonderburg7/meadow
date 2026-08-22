# Next steps

Read this first in a new session, before anything else in CLAUDE.md.
Only the next 1-3 actions belong here -- full detail lives in the named
plan file, full history in `git log`.

## Next up

1. **Challenge 1 revamp** -- start Bundle A (stage-array skeleton +
   trigger tag), then Bundle B (auto-mine sequence). Full plan:
   `CHALLENGE1_REVAMP_PLAN.md` -- read its "What already exists" table
   first, most of this is resequencing, not new systems.
2. **UI text-scale migration gap** -- `hud.gd` and `debug_panel.gd` still
   use `add_theme_font_size_override` instead of `theme_type_variation`,
   so `Session.text_scale` does nothing for most on-screen UI. Detail:
   `UI_PLAN.md` slice 9 writeup.
3. **Hands-on check backlog** -- nothing new to build, but several shipped
   slices need Dave's own playtest before being called done. Full list:
   `HANDS_ON_CHECKS.md`.
