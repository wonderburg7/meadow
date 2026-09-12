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

### C-18 -- the command tray's three columns share its width

Select a bee at 1920x1080, then at 800x600, and look at the Job, Focus and
Orders columns across the tray; then select a comb cell and look again.

PASS: at 1920x1080 the tray's columns divide its width into equal parts with equal gaps and equal space at each end -- Job, Focus and Orders for a bee; Reserve for, Priority and Raises for a cell -- and at 800x600 they either do the same or wrap onto more rows with nothing clipped.

Blocked by: UI-W-3, which gives a cell's tray its third column. Dave's
12 Sep 2026 run passed the bee half; a cell still shows two columns ("using
three would mean it uses less vertical space"). Re-run the cell half only.

Owner: `plans/now/ui-w.md` UI-W-3.

### C-31 -- nectar caught in the pollen cell is called out, and the queen can clear it herself

Play Challenge 1 slowly through 1.12 (build a second comb cell) and 1.13 (set
the new cell aside for pollen) -- `docs/challenge-stages.md` lists every
stage. Once the second cell is built and the first is completely full, let
the queen bring home one more nectar trip, so it lands in the second cell,
before you set that cell to Pollen. When 1.14 (switch her focus to pollen)
begins with nectar still in that cell, watch for Dr Gallerin, then select the
queen, select the cell and press "Empty this cell".

PASS: Dr Gallerin says the pollen cell has nectar in it and to empty it or build another cell; pressing "Empty this cell" sends the queen to carry the nectar out herself, with no role change and no second bee needed.

Blocked by: Challenge 1 Slice 27. In Dave's 12 Sep 2026 run the situation
could not arise: the first cell's real capacity is 200, not 150, so the extra
trip went into it (to 155) instead of into the second cell.

Owner: `plans/now/challenge-1.md` Slice 27.

### C-34 -- Challenge 2 keeps enough pollen to raise its first pollen Forager

Start Challenge 2 and stay in stage 2.1 (watch the nectar stores fall, then
recover them) long enough for Dr Gallerin's stronger hint. Let pollen run
below one bee's cost, then move into 2.2 (raise a pollen Forager) without
raising one at once. Let it run briefly, then select an empty cell, set
Raises to Forager -- Pollen, and play until 2.2 clears.

PASS: during 2.1 Dr Gallerin warns that every new bee costs pollen and some should be kept back; at low pollen, exactly once per run, the colony receives three bee-costs of pollen with a line explaining that no pollen means no new bees, and the same low-pollen state does not top the store up again; once the pollen Forager is raised no further rescue occurs.

Blocked by: UI-W-2. In Dave's 12 Sep 2026 run there was no Forager control
beside "Raises:" at 2.2 at all (confirmed in session, 13 Sep 2026), so the
pollen Forager could not be chosen. UI-W-2 also re-checks the 2.1 half of
this wording before the check moves back: 2.1 has not taught the Forager
role, so nothing can be raised as one there.

Owner: `plans/now/ui-w.md` UI-W-2.

### C-42 -- the queen keeps her nectar when the comb has no room

What this checks: the queen never loses nectar she gathered just because
there is nowhere to put it. In Challenge 1 at stage 1.12 (build a second comb
cell), before building it, make sure the first cell is completely full. Send
the queen to a flower, bring her home, and watch her at the hive. Then build
the second cell. Later, at 1.14 (switch her focus to pollen), fill every
nectar cell and let her bring nectar home again.

PASS: at 1.12 she waits at the hive still carrying her nectar and the cell's total does not change, and once the second cell exists she puts that same load into it; at 1.14 Dr Gallerin warns there is no room for nectar before that trip is thrown away.

Blocked by: Challenge 1 Slice 27. Today a Challenge 1 cell is only
completely full at 200: at 150 the lesson ends and she stops, but a later
trip tops the cell up past 150 (Dave, 12 Sep 2026), so "full" never happens
where this check expects it.

Owner: `plans/now/challenge-1.md` Slice 27.

### C-46 -- comb builders spread across six walls before opening another site

Give at least seven idle bees the Comb worker job with the Building focus,
with open floor in the hive and no cells marked, and watch them start
building on their own. Watch the first unfinished cell and the next one that
begins while it is still unfinished.

PASS: no more than six workers stand at the first cell, each at a different wall, and the seventh starts a second site rather than joining the first.

Blocked by: CB-2, after CB-1 measures the fault. Dave's 12 Sep 2026 run: the
builders did not stand around the six walls, and more than six built one
cell.

Owner: `plans/now/comb-builders.md` CB-1.

### C-52 -- the settings window is about a quarter of the screen's width

Open the settings cog in a run, at the default text scale on a maximised
1920x1080 window.

PASS: the window is about a quarter of the screen wide, the action buttons and the Triggers buttons each read in full, and no row forces a horizontal scrollbar.

Blocked by: UI-W-1. Dave's 12 Sep 2026 run: the window was about a fifth of
the screen (it is a fixed 320px) and "could be bigger, up to 25%".

Owner: `plans/now/ui-w.md` UI-W-1.

### C-53 -- the Controls list reads as one list, with no gaps

Open the settings cog, expand Interface (or whichever collection holds it)
and open the Controls section.

PASS: the control lines sit close together like one list, with no visible gap between one line and the next, there is no second "Controls" heading, and every line is readable at the window's width.

Blocked by: UI-W-1. Dave's 12 Sep 2026 run: "still too big a gap between each
item in the list", after the blank lines were removed.

Owner: `plans/now/ui-w.md` UI-W-1.
