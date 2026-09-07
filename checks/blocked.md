# Blocked hands-on checks

<!-- CONTEXT: player-checks | LAYER: blocked | LOAD: only after its unblocker ships -->

These are known checks that cannot yet provide new evidence. Do not load or
re-run them during normal implementation. When the named unblocker ships,
move the entry to `checks/ready.md` keeping its id; move confirmed checks to
`docs/archive/HANDS_ON_CHECKS_ARCHIVE.md`.

Entries use `checks/ready.md`'s format -- one id, one action, one `PASS:`
line, one `Owner:` line -- plus a `Blocked by:` line naming what has to ship
first. The id follows the entry when it moves, and `tools/check_docs.py`
fails if it is reused in either file.

The one difference from `checks/ready.md`: a blocked check may write
`Owner: none` when the plan that owned it has closed, since its `Blocked by:`
line already says what would give it a new one. Every ready entry must name a
plan file that exists.

### C-2 -- a missing font has no visible effect

Selecting one of the three non-default typefaces does nothing, because those
font files are absent from `assets/fonts/`.

PASS: each of the five typefaces visibly changes the UI's lettering.

Blocked by: an asset/licensing commit, not more UI code. If a theme-reload
change is made meanwhile, confirm that selecting a missing font does no
wasted visible work.

Owner: `plans/archive/UI_SETTINGS_PLAN_2026-08-24.md`.

### C-6 -- the deferred recruitment competition fix

The recruitment competition fix (`103d716`) has never been run.

PASS: n/a until it is selected -- this is a deferred code change, not a
shipped behaviour.

Blocked by: a selected recruitment update. The evidence campaign that would
have owned it closed on 3 Sep 2026 with no threshold change
(`plans/archive/FORAGING_EVIDENCE_2026-09-03.md`), so a new plan file has to
pick this up before it can be checked at all.

Owner: none currently.

### C-5 -- Challenge 2's rescue and recovery lines

In a Challenge 2 run past stage 2.1, open the settings window and press
"Force Challenge 2 collapse" in the Triggers group once, then again.

PASS: the first press drops the stores below the rescue threshold and Dr
Gallerin's "Ahem. Field ecologists..." line appears with 150 nectar
restored; the second press drops them below the failure floor and the
checkpoint restore appears with "A brief ecological wobble..." and a live
queen.

Blocked by: `plans/now/ui-bottom-row.md` UI-T-1. Dave, 8 Sep 2026: "can't progress far
enough to test this because of the command panel placement." The command tray
runs off the bottom edge, so the run cannot be driven into Challenge 2 far
enough to reach the trigger. Move this entry straight back to
`checks/ready.md`, unchanged, when UI-T-1 ships.

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

Blocked by: `plans/now/ui-bottom-row.md` UI-T-1. Dave, 8 Sep 2026: "can't test because
necessary buttons in the command panel are off screen." The role controls
this check needs are below the bottom edge of the screen. Move this entry
straight back to `checks/ready.md`, unchanged, when UI-T-1 ships.

Owner: `plans/now/challenge-1.md` Slice 14.
