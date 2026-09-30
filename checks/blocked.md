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

### C-57 -- at Challenge 2's 2.2 the Raises menu offers a pollen Forager

Start Challenge 2 and play (or step with Game Settings -> World & start's
arrows) to 2.2, raise a pollen Forager (`docs/challenge-stages.md`). Click
a comb cell and open its Raises row's "Forager..." menu.

PASS: the menu lists "Forager -- Pollen" as well as "Forager -- Nectar".

If it fails, HF-6's fixture missed the path you took; say how you reached 2.2.
Passed on 28 Sep 2026 and not re-checked: at 2.1 the menu offers only
"Forager -- Nectar", and no stage shows "Raises:" with nothing to choose.

Owner: `plans/now/hud-followups.md` HF-6

Blocked by: HF-6 -- why Raises lacks Pollen at 2.2. It moves back to
`checks/ready/` once HF-6 has found and fixed the step that drops Pollen.
