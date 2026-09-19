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

### C-25 -- out-of-season flowers read as a rare find, not a standing mix

With Season days 5 (Game Settings > Seasons & health), restart the run and
play at 8x. Look around the meadow at three or four points in the year,
starting straight after the restart, clicking a handful of flowers each time
-- the summary panel says whether each one is in season.

PASS: there are always some flowers in the meadow, but at every point, including the first minute of the run, only an occasional flower you click is out of season.

Owner: `plans/now/season-feel.md` SF-1.

Blocked by: SF-1 (a new run's meadow starts with the season mix it will
settle into). Semi pass (Dave, 17 Sep 2026): later in the year off-season
flowers are rare, but at the start "big proportions of all species" are
about, many out of season, until the founding flowers die. A re-run before
SF-1 lands would fail the same way.
