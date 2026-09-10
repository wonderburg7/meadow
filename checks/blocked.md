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

### C-34 -- Challenge 2 keeps enough pollen to raise its first pollen Forager

Start Challenge 2 and leave it in stage 2.1 long enough for Dr Gallerin's
stronger hint. Spend pollen freely on nectar Foragers until the pollen store
falls below one bee's cost, then continue into 2.2 without raising its pollen
Forager. Let the game run briefly, and then continue until stage 2.2 clears.

PASS: during 2.1, Dr Gallerin warns that every new bee costs pollen and some
should be kept back. At low pollen, exactly once per run, the colony receives
three bee-costs of pollen and the line explains that no pollen means no new
bees. The rescue line remains visible, and the same low-pollen state does not
top the store up again. Once the pollen Forager is raised, no further pollen
rescue occurs.

Blocked by: HC-13 in `plans/now/hud-controls.md`. Dave, 10 Sep 2026: "there's
no option to raise a pollen forager in the cell command window." The cell
popup's "Raises:" row builds the Forager choice as a `MenuButton` labelled
just "Forager", with Nectar and Pollen inside its popup and no ellipsis,
chevron or any other mark saying a menu is there -- the same complaint HC-3
fixed for the tray's "Change to…" and never applied here. Until the control
says it opens a menu, the check's own second half cannot be reached, so a
failure here would not be evidence about the pollen rescue.

Owner: `plans/now/challenge-2.md` Slice 3.
