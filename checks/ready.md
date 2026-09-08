# Ready hands-on checks

<!-- CONTEXT: player-checks | LAYER: on-demand -->

These are shipped behaviours that static checks cannot prove. An entry here
exists specifically so the branch/worktree that produced it could close
without waiting on a human to play-test it (see `CLAUDE.md`, "Coordinating
and closing out workstreams") -- landing a check here, not leaving the
worktree open, is what "done" means. Search for the id or the feature and
run only that check. Move a confirmed or superseded entry to
`docs/archive/HANDS_ON_CHECKS_ARCHIVE.md`; anything that cannot be run on
demand belongs in `checks/blocked.md`, with its unblocker named.

**Entry format, from 3 Sep 2026.** Every entry is
`### C-<n> -- <short name>`, then what to do in a sentence or two, then one
`PASS:` line stating the single condition, then one `Owner:` line naming the
plan that owns it. Reply by id -- "C-1 pass", or "C-1 fails: <what I saw>"
-- so nothing has to be inferred from prose. An entry only belongs here if
failing it would change what gets built; if the answer is "nothing, we would
assume it works", do not file it (`plans/reference/check-loop.md`).

**Name the stage, from 8 Sep 2026.** A check that names a Challenge stage id
must say in the same sentence what happens at that stage, or link to
`docs/challenge-stages.md`, which lists every id with its goal and what the
player does. Dave: "when talking about stages in particular challenges, say
what the stage is, or point me to where the stage details are." A bare "past
2.1" tells the person running the check nothing.

**This file holds checks only, from 9 Sep 2026.** Decisions Dave has to make
are raised in the session that needs them, and answered there. Dave: "you can
ask me decisions in the LLM sessions now rather than write them in the checks
-- it was just a temporary request in one session." The former "Decisions
waiting on Dave" section is gone; its four entries were all answered, and
what each one settled now lives where the rule it changed lives
(`plans/reference/check-loop.md`, "Durable rules this pass adds").

**Anything asked of Dave names the file and the steps, from 9 Sep 2026.** If
a check, plan or session report asks Dave to change something himself, it
gives the exact path, the exact place in the file, and what to type. Dave, 9
Sep: "you haven't told me where to put the permission setting code. in future
make sure if i'm being asked to do something, the steps and locations are
explicitly communicated." A description of the change without its location is
not an ask, it is a puzzle.

`tools/check_docs.py` enforces the entry format from 3 Sep 2026: it fails on
an entry whose heading does not start `C-<n> -- `, on one with no `PASS:`
line, on one whose `Owner:` names no plan file or names one that does not
exist, and on an id used twice across this file and `checks/blocked.md`.

**Where the diagnostic logs are.** Dave asked during the 8 Sep pass. One
`.jsonl` file per run, written line by line and flushed on every entry, at
`%APPDATA%\Godot\app_userdata\Meadow - Claude\logs\session_<unix time>.jsonl`
(`Meadow - Codex` for that lane's build). Nothing has to be saved by hand,
and closing the window still writes the summary line. The newest file is the
run that just finished, so "send the log" means sending the newest file in
that folder.

## Last pass: 9 Sep 2026

Three passed and are archived in
`docs/archive/HANDS_ON_CHECKS_ARCHIVE.md`: C-4, C-27 and C-28. Three failed
and stay below against new owners. Two -- C-7 and C-5 -- could not be run at
all and moved to `checks/blocked.md`.

- **C-18 failed for the fourth time**, and Dave sent a screenshot: the
  command tray's "Job" header sits level with the bottom of the summary panel
  and the rest of the tray is below the window's bottom edge, so no button
  can be pressed. Dave: "diagnose why this is happening repeatedly, as this
  is wasting many tokens." The cause is written up in
  `plans/now/panel-layout.md`, "Why this kept coming back", and it is one
  Godot behaviour nothing in the code stated: `Control.set_size()` rewrites
  all four anchor offsets from the cached position, so giving a
  bottom-anchored panel a height silently converts its bottom pin into a top
  pin, and the tray then regrows downwards off the screen. LAY-2 removes the
  behaviour rather than re-tuning a height, and LAY-5
  (`plans/now/layout-regression.md`) makes a headless check catch it next
  time. The horizontal gap between the tray and the summary window is
  correct, and no slice here touches it.
- **C-19 failed on its measurement.** The gap exists but is about 36px, not
  16: `left_window_max_height()` subtracts the panel chrome, and
  `ui_panel_layout.gd::apply()` subtracts it again. Dave also asked for the
  windows to grow when a section is expanded, which they do not -- expanding
  a section changes the content but nothing re-applies the rectangle. Both
  are LAY-3.
- **C-26 half passed.** The key follows the chosen typeface, which is what
  UI-W-2 shipped. The new defect is that the Nursery window's scrollbar
  covers the key's right-hand end, because the donut's legend draws at fixed
  pixel positions inside a fixed 300px box. LAY-4 gives it a measured width
  and a scrollbar gutter.
- **C-7 and C-5 could not be run.** Both need the command tray's buttons.
  They are in `checks/blocked.md`, unblocked by LAY-2, and come straight back
  here when it lands.

## Ready to run

### C-18 -- the command tray shows its buttons and keeps its gaps

At 1920x1080, 1280x720 and 800x600, select a bee, then a comb cell, then open
`More…`, then select a bee again. Then select a bee with a long name and
check the left-hand gap.

PASS: at every size the whole command tray is on screen with its Job, Focus
and Orders buttons visible and clickable, `More…` is clickable, and opening
`More…` either grows the tray upwards or gives it a scrollbar rather than
pushing anything below the bottom of the window. The tray's bottom edge stays
16px above the window's bottom edge through all of that, including after the
tray has once been tall. A 16px gap is visible between the tray and the
summary panel on its left and Dr Gallerin's bubble on its right, at every one
of those sizes, while dragging between them, and with the longest bee name
selected.

Owner: `plans/now/panel-layout.md` LAY-2.

### C-19 -- left-side windows leave a true 16px gap, and grow with their content

With a bee selected, open Colony, then Foraging, then Nursery in turn at
1280x720, then at 800x600. In Colony and Foraging, expand a section and then
collapse it again.

PASS: the visible gap between the bottom of the open window and the top of
the summary panel is the same as the gap between the summary panel and the
left screen edge. Expanding a section makes the window grow taller, up to the
point where its bottom would reach that gap, after which it scrolls instead;
collapsing the section makes it shrink again.

Owner: `plans/now/panel-layout.md` LAY-3.

### C-26 -- the nursery donut's key follows the typeface and clears the scrollbar

Open the Nursery window and look at the key beside the donut ("The colony
now"). Change the text scale to its largest and the typeface to each option
in turn, in Settings > Accessibility and Appearance.

PASS: the key's text changes typeface and size with the settings, matching
the headings around it, and no line of it is covered by or runs under the
window's scrollbar at any scale.

Owner: `plans/now/panel-layout.md` LAY-4.
