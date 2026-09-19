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

### C-49 -- Challenge stages can be replayed from settings

Start Challenge 1, open Game Settings > World & start, and step forward and
back across every stage with the stage arrows, including across 1.11
(automate nectar gathering) and 1.14 (automate pollen gathering), which
follow the queen and speed the game up.

PASS: after each arrow the queen, the tunnel, the comb cells and their stores match the stage shown, its gates, prompts and marker are rebuilt, the stage shown stays put until you act, the back arrow is disabled at the first stage and the forward arrow at the last, and the camera follows no bee at normal speed.

Owner: `plans/now/c1-followups.md` C1F-1.

Blocked by: C1F-1 (each Challenge 1 stage sets up the world it starts from).
Partial pass (Dave, 17 Sep 2026): gates, prompts and marker rebuild, the
arrows disable at both ends, and follow and speed reset on every arrow. Going
back fails at some stages (for example from 1.11) because the earlier
stage's goal is already met in the world and it advances again; the queen,
tunnel soil and cells never change. Dave chose, in session, that each stage
sets up its world. The stage row's layout (letters one per line, tall arrows)
is fixed on `claude/pass-0917` with a headless check; see C-49's history in
`docs/archive/HANDS_ON_CHECKS_ARCHIVE.md`.
