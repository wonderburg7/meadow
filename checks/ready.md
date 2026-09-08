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

## Last pass: 8 Sep 2026, second batch

The UI-T group's own checks came back the same day it shipped. **Four passed
and are archived** in `docs/archive/HANDS_ON_CHECKS_ARCHIVE.md`: C-20, C-21,
C-22 and C-23. Two failed and both are re-filed below against new slices, and
C-5 finally ran and produced the evidence Challenge 2 had been waiting three
attempts for.

- **C-18 failed.** UI-T-1 stopped the command tray running off the bottom
  edge and then collapsed it to a bar a few pixels high with no buttons in
  it, and the summary panel still overlaps it. `plans/now/ui-bottom-row.md`
  UI-T-6 owns both halves.
- **C-19 passed its main clause and returned three defects** -- no real 16px
  gap, the nursery donut's key ignoring the chosen font, and the left-side
  sections opening expanded. These are UI-W-1, UI-W-2 and UI-W-3 in the new
  `plans/now/ui-windows.md`. The dynamic-resize clause Dave asked about is
  already built and already passing: UI-T-2's `bottom_row_changed` signal is
  what makes the windows reflow while open.
- **C-22 passed** and Dave asked for the same behaviour at the pre-run menu:
  UI-W-4.
- **C-5 ran and failed usefully.** Four separate observations, all explained
  by the collapse button choosing its target from the current stores rather
  than from how many times it has been pressed, plus the rescue line not
  clearing the stage's prompt queue before showing itself.
  `plans/now/challenge-2.md` Slice 2 now specifies the fix down to the line.
- **C-7 still could not be run** -- it needs the command tray, so it goes
  back to `checks/blocked.md` naming UI-T-6.

**The pattern behind C-11, C-12, C-13, C-18 and C-19** was diagnosed in the
same pass and written up in `plans/now/ui-layout-ownership.md`: four Godot
behaviours nothing in the code stated, and no single owner of a panel's
rectangle. That file also holds the panel hierarchy Dave asked for -- command
tray, then the bottom row's side bands, then the left-side windows, 16px
apart -- and LAY-1, which enforces it.

## Ready to run

### C-18 -- the command tray shows its buttons and keeps its gaps

At 1920x1080, 1280x720 and 800x600, select a bee and then a comb cell. Then
select a bee with a long name and check the left-hand gap.

PASS: at every size the whole command tray is on screen with its Job, Focus
and Orders buttons visible and clickable, `More…` is clickable, and opening
`More…` either grows the tray upwards or gives it a scrollbar rather than
pushing anything below the bottom of the window. A 16px gap is visible
between the tray and the summary panel on its left and Dr Gallerin's bubble
on its right, at every one of those sizes, while dragging between them, and
with the longest bee name selected.

Owner: `plans/now/ui-bottom-row.md` UI-T-6.

### C-19 -- left-side windows leave a real gap above the summary panel

Open Colony, then Foraging, then Nursery at a short viewport height with
nothing selected -- each should still fill down close to the bottom edge.
With one open, select a bee and then a comb cell.

PASS: the open window shortens so a clear gap sits between its bottom edge
and the top of the summary panel, and that gap looks the same size as the gap
between the summary panel and the left edge of the screen. Contents scroll
inside the smaller area, and the window grows back on deselecting.

Owner: `plans/now/ui-windows.md` UI-W-1.

### C-5 -- Challenge 2's rescue and recovery lines

In a Challenge 2 run, get past stage 2.1 -- the opening stage, where the
nectar stores fall and you bring them back -- and into 2.2, where you raise a
pollen Forager (`docs/challenge-stages.md` lists every stage). Open the
settings window and press "Force Challenge 2 collapse" in the Triggers group
once, then again.

PASS: the first press drops the stores below the rescue threshold, and Dr
Gallerin's "Ahem. Field ecologists..." line appears with 150 nectar restored
and stays up rather than being replaced by a stage hint a few seconds later.
The second press drops them below the failure floor and the checkpoint
restore appears with "A brief ecological wobble..." and a live queen. Neither
takes a third press.

Owner: `plans/now/challenge-2.md` Slice 2.

### C-26 -- the nursery donut's key follows the chosen typeface and text scale

Open the Nursery window and look at the key beside the donut ("The colony
now"). Change the text scale to its largest and the typeface to each option
in turn, in Settings > Accessibility and Appearance.

PASS: the key's text changes typeface and size with the settings, matching
the headings around it, and stays inside the window without clipping or
overlapping the ring at the largest scale.

Owner: `plans/now/ui-windows.md` UI-W-2.

### C-27 -- sections start collapsed everywhere

From the pre-run menu, press Settings. Start a run, and open Colony, Foraging
and Nursery in turn. Expand several sections in each, return to the menu,
start another run, and open all four again.

PASS: every collection and topic section in the settings window, and every
section in Colony and Foraging, is collapsed on both run starts and at the
pre-run menu. Expanding one still works and still holds while that run lasts.

Owner: `plans/now/ui-windows.md` UI-W-3.

## Decisions waiting on Dave

Not checks -- these need a call rather than a playthrough, and they are here
because this is the file Dave answers by id. Reply "D-2: <choice>". They use
`#### D-<n>` headings deliberately, so `tools/check_docs.py`'s C-id format
rules do not apply to them.

#### D-1 -- answered, 8 Sep 2026

The paused checks were the binding constraint on the whole queue. Dave ran a
full pass on 8 Sep 2026, which unblocked every lane. Kept here only so the
next empty-queue session can see what fixed it. No action.

#### D-2 -- answered, 8 Sep 2026: the floor is 3, and slices name successors

Dave: "have queue floor be 3. ensure slices have successors so that the queue
replenishes automatically."

Both are applied. `tools/check_docs.py`'s `QUEUE_SIZE_MIN` is 3, and a new
`check_queue_successors` fails any queue item whose `Next after:` line does
not name a following slice -- the only accepted alternative being
`none -- <plan> is complete`. Together those stop the drift that took the
floor from 5 to 2 over two days: a slice can no longer ship with nothing
behind it, so refilling a lane is a lookup rather than an investigation. No
further action.

#### D-3 -- answered, 8 Sep 2026: leave it as a lane marker

Dave: "leave it as a lane marker." `tools/slice.ps1`'s `Get-LaneTrailer`
keeps writing `Co-Authored-By: Claude Sonnet 5` on every Claude-lane slice,
and the trailer means "the Claude lane", not "the model that ran". No action;
recorded so the next session does not re-raise it.

#### D-4 -- answered, 8 Sep 2026, and waiting on one edit only Dave can make

Dave: "lift the deny for an audit session only, or other uses where access is
useful."

The change is to move `docs/archive/**`, `plans/archive/**`, `ROADMAP.md` and
`DESIGN_BACKLOG.md` out of `permissions.deny` and into `permissions.ask` in
`.claude/settings.json`, leaving `.godot/**` and `_backups/**` denied. `ask`
does exactly what Dave described: a routine session is still steered off
those paths by the prompt, and an audit session simply says yes.

**Claude Code will not let a session edit its own permission settings**, so
this one has to be pasted in by hand. The whole file becomes:

```json
{
  "permissions": {
    "deny": [
      "Read(./.godot/**)",
      "Read(./_backups/**)"
    ],
    "ask": [
      "Read(./docs/archive/**)",
      "Read(./plans/archive/**)",
      "Read(./ROADMAP.md)",
      "Read(./DESIGN_BACKLOG.md)"
    ]
  },
  "enabledPlugins": {
    "gitkraken-hooks@gitkraken": false
  }
}
```

Until that lands, archiving a check still takes a Python or shell write
rather than an edit, and `ROADMAP.md`/`DESIGN_BACKLOG.md` stay unreadable.
