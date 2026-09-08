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

### C-7 -- 1.11/1.13's automatic foraging: camera-follow and 4x speed fire as she sets off

At stage 1.11 -- "automate nectar gathering", where the player gives the
queen the Forager role with nectar focus (`docs/challenge-stages.md`) -- do
exactly that: she should not pause on the first flower she finishes. She works
one flower, flies home, deposits, and goes back out, repeating until the
nectar cell is full. The camera starts following her and the game speed jumps
to 4x the moment she sets off (not when the role is assigned), and both switch
off again when the stage ends. The same at 1.13, "automate pollen gathering",
for pollen.

PASS: at 1.11, giving her Forager/nectar starts an unattended loop with
camera-follow and 4x speed visibly firing as she sets off, not before; the
same at 1.13 for pollen; both stop at stage end.

Blocked by: LAY-2 (`plans/now/panel-layout.md`). Assigning a role needs the
command tray's Job button, and the tray is currently off the bottom of the
screen. Dave, 9 Sep 2026: "I can't test this because the command tray is off
screen." This is the second pass C-7 has been blocked by the tray.

Owner: `plans/now/challenge-1.md` Slice 14.

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

Blocked by: LAY-2 (`plans/now/panel-layout.md`). Reaching stage 2.2 means
raising a pollen Forager, which needs the command tray's Job button. Dave, 9
Sep 2026: "I can't raise a pollen forager because the command tray is off
screen." Challenge 2 Slice 2 can still be implemented meanwhile -- it is in
the Codex lane and its fix is specified against the source -- but its check
cannot run until the tray is back.

Owner: `plans/now/challenge-2.md` Slice 2.

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
