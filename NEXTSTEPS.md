# Next steps

Read this first in a new session, before anything else in CLAUDE.md.
Only the next 1-3 actions belong here -- full detail lives in the named
plan file, full history in `git log`.

## Next up

1. **UI bugfix plan -- Slice 4 and the popup-repositioning part of
   Slice 5 are done (four sub-slices, each committed separately: icon-
   only top bar with a settings toggle; the three-column Job/Focus/
   Orders command tray; flower/obstacle/death/soil popups folded into
   the bottom-left selection panel as a content swap; the cell popup
   folded into the command tray, mutually exclusive with the three
   columns). `source_checks.py`/`balance_tests.py` pass and the project
   boots clean under `mcp__godot__run_project` after each sub-slice.
   **Not yet Dave-verified in-game.** Next session should open a save
   and check: the top-bar buttons go icon-only and the "Show button
   labels" setting brings the words back; selecting a bee shows Job/
   Focus/Orders as three columns with More… holding the rest; clicking
   a flower/obstacle/dead bee/soil block shows its summary in the
   bottom-left panel (and that a still-selected bee's command tray
   stays up underneath); selecting a cell shows its five sections in
   the command tray instead of the columns, and reselecting a bee swaps
   back cleanly. Full detail in `UI_BUGFIX_PLAN.md` -- Slices 6
   (resize overlap), 7 (Meadow/Hive hit-area) and 8 (follow-bee-stops)
   are the remaining, unrelated slices.
2. **Challenge 1 revamp** -- start Bundle A (stage-array skeleton +
   trigger tag), then Bundle B (auto-mine sequence). Full plan:
   `CHALLENGE1_REVAMP_PLAN.md`; read "What already exists" first.
