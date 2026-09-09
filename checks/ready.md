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

## Last pass: 9 September 2026

C-19 and C-26 passed and are archived. C-18 passed on everything except its
column layout and is narrowed below. C-7 failed in five ways, which became
Slices 16 to 19 in `plans/now/challenge-1.md`; it is split below into C-7 and
C-29. C-5 failed on its press count and stands unchanged.

## Ready to run

### C-18 -- the command tray's three columns share its width

Select a bee at 1920x1080, then at 800x600. Look at the Job, Focus and Orders
columns across the tray's width, then select a comb cell and look again.

PASS: at 1920x1080 the three columns divide the tray's width into three equal
parts, with equal gaps between them and equal space at each end, for a bee
and for a cell; at 800x600 they either do the same or wrap onto more rows
with nothing clipped.

Owner: `plans/now/hud-controls.md` HC-1.

### C-7 -- the queen forages unattended once she is given the job

Play Challenge 1 to stage 1.11, "automate nectar gathering", where the player
gives the queen the Forager role with nectar focus. Give her that, then leave
her alone. Do the same at the pollen stage that follows the second cell
(`docs/challenge-stages.md` lists every stage id and what it asks).

PASS: at each stage she works a flower, flies home, deposits, and goes out to
a *different* flower, repeating unaided until that stage's cell is full --
with no right-click from you at any point, and nothing left in her hands at
the hive entrance.

Owner: `plans/now/challenge-1.md` Slice 18.

### C-29 -- the stage's camera and speed switch off when the stage ends

At stage 1.11 and again at the pollen stage, watch the speed readout and the
camera as the queen sets off and again as the stage ends.

PASS: camera-follow and 4x speed start the moment she sets off, not when the
role is assigned, and both return to normal when the stage ends.

Owner: `plans/now/challenge-1.md` Slice 19.

### C-30 -- the new stage makes you designate a cell for pollen before it starts

Play Challenge 1 to stage 1.13, right after the second cell finishes building
(`docs/challenge-stages.md` lists every stage id and what it asks). Try
waiting, or right-clicking things unrelated to the cell.

PASS: the stage will not clear until you select the second cell and choose
Pollen; once you do, it clears immediately into the pollen-automation stage
that follows.

Owner: `plans/now/challenge-1.md` Slice 18.

### C-31 -- nectar caught in the pollen cell is called out, and the queen can clear it herself

Play Challenge 1 slowly through stages 1.12-1.13: once the second cell
finishes, let the queen deliver at least one more nectar trip into it before
you designate it for pollen (`docs/challenge-stages.md` lists what each
stage asks). Once the pollen-automation stage begins with nectar still
sitting in that cell, watch for Dr Gallerin, then select the queen, select
the cell, and press "Empty this cell".

PASS: Dr Gallerin says the pollen cell has nectar in it and to empty it or
build another cell; pressing "Empty this cell" sends the queen to carry the
nectar out herself, with no role change and no second bee needed.

Owner: `plans/now/challenge-1.md` Slice 18.

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
