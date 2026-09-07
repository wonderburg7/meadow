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

`tools/check_docs.py` enforces that format from 3 Sep 2026: it fails on an
entry whose heading does not start `C-<n> -- `, on one with no `PASS:` line,
on one whose `Owner:` names no plan file or names one that does not exist,
and on an id used twice across this file and `checks/blocked.md`.

**Where the diagnostic logs are.** Dave asked during the 8 Sep pass. One
`.jsonl` file per run, written line by line and flushed on every entry, at
`%APPDATA%\Godot\app_userdata\Meadow - Claude\logs\session_<unix time>.jsonl`
(`Meadow - Codex` for that lane's build). Nothing has to be saved by hand,
and closing the window still writes the summary line. The newest file is the
run that just finished, so "send the log" means sending the newest file in
that folder.

## Last pass: 8 Sep 2026

Fourteen checks went out. **Eleven came back confirmed** and are archived in
`docs/archive/HANDS_ON_CHECKS_ARCHIVE.md`: C-1, C-3, C-4, C-8, C-9, C-10,
C-13, C-15, C-16 and C-17, plus C-11 in part. Three of those carried a
correction or a balance note alongside the pass, and each became a slice:

- C-9 passed but the rings sit 2px high -> `plans/now/ui-small-fixes.md` UI-T-3.
- C-13 passed but left-side windows still overlap the summary panel ->
  UI-T-2.
- C-16 passed, and a separate clipped hexagon point in the same screen ->
  UI-T-4.
- C-15 and C-17 both passed with a balance note -> the new
  `plans/now/season-balance.md`, SB-1 and SB-2.
- C-4 passed, and the dwell times Dave timed became UI-Q-3.

**Three came back failing**, and all three are now specified:

- C-11 and C-12 -- the command tray runs off the bottom of the screen and
  `More…` is unreachable -> UI-T-1, whose own check C-18 replaces both.
- C-14 -- a double right-click still closes the bee panels -> UI-S-4b. Its
  log was recovered and it proves the selection is *not* lost, which retires
  UI-S-4's theory.

**Two could not be run at all** -- C-5 and C-7 both need buttons that are
currently below the bottom edge of the screen. Both moved to
`checks/blocked.md` naming UI-T-1 as their unblocker.

Two new asks arrived outside the checks: the pre-run menu clips the first
hexagon's left point (UI-T-4) and the settings window should open with every
section collapsed (UI-T-5).

## Ready to run

### C-21 -- pre-run menu's first hexagon is not clipped

Open the pre-run menu at the usual viewport. In both Challenges and Scenarios,
confirm the leftmost hexagon's full left point and border are visible, then
click every tile and confirm it selects its corresponding stage; also confirm
the left-pane text inset still looks unchanged.

PASS: Both strips show unbroken leftmost hexagons, every tile selects the
right stage, and the left-pane text inset is unchanged.

Owner: `plans/now/ui-small-fixes.md`

### C-18 -- the command tray stays wholly on screen

At 1920x1080, 1280x720 and 800x600, select a bee and then a comb cell.

PASS: in every case the whole command tray is on screen -- its top edge is
visible, `More…` is clickable, and opening `More…` either grows the tray
upwards or gives it a scrollbar, never pushing anything below the bottom of
the window. The 16px gap between the tray and the summary panel on its left,
and between the tray and Dr Gallerin's bubble on its right, is visible at
every one of those sizes and while dragging between them.

Owner: `plans/archive/UI-T-1_2026-09-08.md`.

### C-5 -- Challenge 2's rescue and recovery lines

In a Challenge 2 run past stage 2.1, open the settings window and press
"Force Challenge 2 collapse" in the Triggers group once, then again.

PASS: the first press drops the stores below the rescue threshold and Dr
Gallerin's "Ahem. Field ecologists..." line appears with 150 nectar
restored; the second press drops them below the failure floor and the
checkpoint restore appears with "A brief ecological wobble..." and a live
queen.

Owner: `plans/now/challenge-2.md` Slice 1.

### C-7 -- 1.11/1.13's automatic foraging: camera-follow and 4x speed fire as she sets off

At 1.11, give the queen the Forager role with nectar focus: she should not
pause on the first flower she finishes -- she works one flower, flies home,
deposits, and goes back out, repeating until the nectar cell is full. The
camera starts following her and the game speed jumps to 4x the moment she
sets off (not at the moment the role is assigned), and both switch off again
when the stage ends. The same at 1.13 for pollen.

PASS: at 1.11, giving her Forager/nectar starts an unattended loop with
camera-follow and 4x speed visibly firing as she sets off, not before;
the same at 1.13 for pollen; both stop at stage end.

Owner: `plans/now/challenge-1.md` Slice 14.

Remaining slices from Dave's pass (`plans/now/ui-bottom-row.md` UI-T-2,
UI-S-4b and UI-Q-3; `plans/now/ui-small-fixes.md` UI-T-3 and UI-T-5;
`plans/now/season-balance.md` SB-1 and SB-2) each file their own check when
they ship -- C-19, C-20 and C-22 to C-25, reserved in those plans so the ids
cannot collide.

## Decisions waiting on Dave

Not checks -- these need a call rather than a playthrough, and they are here
because this is the file Dave answers by id. Reply "D-2: <choice>". They use
`#### D-<n>` headings deliberately, so `tools/check_docs.py`'s C-id format
rules do not apply to them.

#### D-1 -- answered, 8 Sep 2026

The paused checks were the binding constraint on the whole queue. Dave ran a
full pass on 8 Sep 2026, which unblocked every lane: both lanes now hold
ready work and `NEXTSTEPS.md` is back to five items. Kept here only so the
next empty-queue session can see what fixed it. No action.

#### D-2 -- whether the queue floor stays at 2

`tools/check_docs.py`'s comment asks for this to be flagged to you: the
minimum queue size was lowered 5 -> 4 -> 3 -> 2 over 3-4 Sep 2026, each time
because a slice shipped with no ready successor. The 8 Sep pass has put the
queue back to a full five, so the floor is no longer doing any work.

Options: leave it at 2 and let it absorb the next dry spell; or raise it back
to 3 now that both lanes have depth again.

#### D-3 -- git attribution names Sonnet, whichever model ran

`tools/slice.ps1`'s `Get-LaneTrailer` hard-codes
`Co-Authored-By: Claude Sonnet 5` for every Claude-lane slice. Its stated
purpose is telling the Claude and Codex lanes apart in `git log`, which it
does; but sessions run on different models, so the trailer is not accurate as
attribution. Left unchanged, because attribution is yours to decide.

Options: leave it as a lane marker; or have it name the model the session
actually ran on.

#### D-4 -- `ROADMAP.md` and `DESIGN_BACKLOG.md` are unreadable to a session

`.claude/settings.json` denies reads of both, which correctly keeps them out
of the routing path -- but it also means no session can check their contents
against the plans. Two dead pointers in `DESIGN_BACKLOG.md` were repaired
blind, by known-target substitution, and `tools/check_docs.py` now catches
that whole class automatically, so the gap is smaller than it was. The same
deny covers `plans/archive/` and `docs/archive/`, which is why archiving a
check takes a shell append rather than an edit.

Options: leave both denied and rely on the backticked-path check; or lift the
deny for an explicit audit session only.
