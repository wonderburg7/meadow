# Ready hands-on checks

<!-- CONTEXT: player-checks | LAYER: on-demand -->

Shipped behaviours that static checks cannot prove. Search for the id or the
feature and run only that check. Reply by id: "C-1 pass", or "C-1 fails:
<what I saw>".

Move a confirmed or superseded entry to
`docs/archive/HANDS_ON_CHECKS_ARCHIVE.md`. Move anything that cannot be run
on demand to `checks/blocked.md`, naming its unblocker.

**Entry format.** `### C-<n> -- <short name>`, then what to do in a sentence
or two, then one `PASS:` line stating a single condition, then one `Owner:`
line naming the plan that owns it. A check naming a Challenge stage says what
the stage asks the player to do, or links `docs/challenge-stages.md`.
`tools/check_docs.py` enforces the heading, the `PASS:` line, the `Owner:`
plan existing, and ids being unique across this file and `checks/blocked.md`.
The rules behind the format, and why entries are admitted or refused, are in
`plans/reference/check-loop.md`.

**Diagnostic logs.** One `.jsonl` per run at
`%APPDATA%\Godot\app_userdata\Meadow - Claude\logs\session_<unix time>.jsonl`
(`Meadow - Codex` for that lane). Nothing needs saving by hand; "send the log"
means the newest file in that folder.

## Last pass: 9 September 2026 (second hands-on pass)

Dave's second 9 Sep pass reported on seven checks. Nothing passed outright.
C-18 failed again, unchanged: the tray's columns are still stacked one per
row. C-7, C-29, C-31 and C-32 each passed one half and failed the other, and
are narrowed below to the half that still fails. C-30 failed outright, and
its cause turned out to be the cause of C-31 and of most of C-7's pollen half
as well. C-5 failed again on its press count and stands unchanged, still
owned by the Codex lane's C2-2.

The narrowing rule used here: a check keeps only the sentences that are still
unproved. What passed is written into the owning slice's record, so a re-run
tests the defect rather than re-testing settled behaviour.

## Ready to run

### C-18 -- the command tray's three columns share its width

Failed twice: on 9 Sep 2026 before HC-1, and again after it. HC-1 gave the
three columns the right widths, but the container holding them never grew
past its own minimum, so they still stack one per row against the tray's
left edge with the rest of the tray blank.

Select a bee at 1920x1080, then at 800x600. Look at the Job, Focus and Orders
columns across the tray's width, then select a comb cell and look again.

PASS: at 1920x1080 the three columns divide the tray's width into three equal
parts, side by side on one row, with equal gaps between them and equal space
at each end, for a bee and for a cell; at 800x600 they either do the same or
wrap onto more rows with nothing clipped.

Owner: `plans/now/hud-controls.md` HC-7.

### C-7 -- the queen forages unattended once she is given the job

Narrowed on 9 Sep 2026. The nectar half passed: at stage 1.11, "automate
nectar gathering", she works flower after flower and deposits unaided. Only
the pollen half is still open, so only it is described here.

Play Challenge 1 to stage 1.14, "automate pollen gathering", which follows
the stage where you set the second cell aside for pollen
(`docs/challenge-stages.md` lists every stage id and what it asks). Switch
her focus to Pollen, then leave her completely alone.

PASS: she sets off for a flower on the focus change alone, works a flower,
flies home, deposits *pollen* into the pollen cell, and goes out to a
different flower, repeating until the stage's target is reached -- with no
right-click from you at any point, and with no nectar still in her hands when
she reaches the hive.

Owner: `plans/now/challenge-1.md` Slice 21.

### C-29 -- the stage's camera and speed switch off when the stage ends

Narrowed on 9 Sep 2026. The nectar stage passed in full. At the pollen stage
the speed half passed -- it went to 4x and back to 1x -- and only the camera
half failed: the view never followed the queen at all. Dave also saw the
nectar stage's automation skipped when he foraged and deposited before
walking the three meadow waypoints, which is a second, separate failure the
same slice covers.

At stage 1.14, "automate pollen gathering", watch the camera as the queen
sets off and again as the stage ends. Then start a fresh run and, at the
meadow-waypoint stage, gather from a flower and deposit before visiting all
three waypoints, and watch the nectar stage's camera and speed.

PASS: at the pollen stage the camera follows the queen from the moment she
sets off and stops following when the stage ends; and taking an early forage
trip during the waypoint stage does not stop the nectar stage's camera-follow
and 4x speed from starting.

Owner: `plans/now/challenge-1.md` Slice 22.

### C-30 -- the new stage makes you designate a cell for pollen before it starts

Play Challenge 1 to stage 1.13, right after the second cell finishes building
(`docs/challenge-stages.md` lists every stage id and what it asks). Try
waiting, or right-clicking things unrelated to the cell.

Failed on 9 Sep 2026: the stage cleared instantly and was never seen.

PASS: the stage will not clear until you select the second cell and choose
Pollen; once you do, it clears immediately into the pollen-automation stage
that follows.

Owner: `plans/now/challenge-1.md` Slice 20.

### C-31 -- nectar caught in the pollen cell is called out, and the queen can clear it herself

Play Challenge 1 slowly through stages 1.12-1.13: once the second cell
finishes, let the queen deliver at least one more nectar trip into it before
you designate it for pollen (`docs/challenge-stages.md` lists what each
stage asks). Once the pollen-automation stage begins with nectar still
sitting in that cell, watch for Dr Gallerin, then select the queen, select
the cell, and press "Empty this cell".

Narrowed on 9 Sep 2026. The second half passed: "Empty this cell" does send
the queen to clear it herself. Dr Gallerin's line never appeared, because the
stage that would have made the cell a pollen cell never ran (C-30).

PASS: Dr Gallerin says the pollen cell has nectar in it and to empty it or
build another cell.

Owner: `plans/now/challenge-1.md` Slice 20.

### C-5 -- Challenge 2's rescue and recovery lines

In a Challenge 2 run, get past stage 2.1 -- the opening stage, where the
nectar stores fall and you bring them back -- and into 2.2, where you raise a
pollen Forager. Open the settings window and press "Force Challenge 2
collapse" in the Triggers group once, then again.

PASS: the first press drops the stores below the rescue threshold and Dr
Gallerin's "Ahem. Field ecologists..." line appears with 150 nectar restored,
and stays up rather than being replaced by a stage hint. The second press
drops them below the failure floor and the checkpoint restore appears with "A
brief ecological wobble..." and a live queen. Neither takes a third press.

Owner: `plans/now/challenge-2.md` Slice 2.

### C-32 -- the soil panel's two buttons follow the text-size setting

Narrowed on 9 Sep 2026. HC-2's own conditions passed: at both text scales the
two buttons span the panel's width, show their labels, and do what they say.
What failed is that their text never changed size, so the wrapping half of
the check could not be run at all. The panel's own "1 soil block selected"
line did change size, which is what makes this a button-specific defect.

Select a soil block at the default text scale, then at the largest text
scale, and compare the button labels with the "1 soil block selected" line
above them.

PASS: at the largest scale "Mark for digging" and "Clear marks" read larger
than at the default scale, by the same step the line above them takes, and a
label that no longer fits wraps onto a second line and grows the button
taller rather than the panel wider.

Owner: `plans/now/hud-controls.md` HC-9.

### C-33 -- the default text size is 2px larger everywhere, and nothing clips

Boot the game at 800x600 at the default text-scale setting, then again at the
largest text-scale setting. Look at every label in the summary panel, the
command tray (including the Job/Focus/Orders columns) and Dr Gallerin's
bubble.

PASS: at the default scale every label reads visibly larger than before this
slice; at both scales and both viewport sizes nothing in the summary panel,
the command tray or Dr Gallerin's bubble is clipped or wraps mid-word.

Owner: `plans/now/hud-controls.md` HC-4.
