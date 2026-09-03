# Blocked hands-on checks

<!-- CONTEXT: player-checks | LAYER: blocked | LOAD: only after its unblocker ships -->

These are known checks that cannot yet provide new evidence. Do not load or
re-run them during normal implementation. When the named unblocker ships,
move the entry to `checks/ready.md` keeping its id; move confirmed checks to
`docs/archive/HANDS_ON_CHECKS_ARCHIVE.md`.

Entries use `checks/ready.md`'s format -- one id, one action, one `PASS:`
line, one `Owner:` line -- plus a `Blocked by:` line naming what has to ship
first. The id follows the entry when it moves.

### C-2 -- a missing font has no visible effect

Selecting one of the three non-default typefaces does nothing, because those
font files are absent from `assets/fonts/`.

PASS: each of the five typefaces visibly changes the UI's lettering.

Blocked by: an asset/licensing commit, not more UI code. If a theme-reload
change is made meanwhile, confirm that selecting a missing font does no
wasted visible work.

Owner: `plans/archive/UI_SETTINGS_PLAN_2026-08-24.md`.

### C-3 -- Challenge-only top-bar hit areas

In a Challenge, only a thin strip along the top of the second-row top-bar
buttons responds to a click; the same controls are fully clickable in a
Scenario. The goal shelf's `mouse_filter` fix is in.

PASS: every second-row top-bar button responds across its full height in a
Challenge, exactly as in a Scenario.

Blocked by: nothing shipped -- it is grouped into UI-F's combined check and
should be run with it. Do not treat the old `stage_gate.gd` theory as the
established cause.

Owner: `plans/now/ui.md` UI-D.

### C-4 -- two throttled warnings eight seconds apart

Fire a bee-death epitaph, then a crab-spider escape eight seconds later,
then an unkeyed "Run saved." confirmation.

PASS: the first two do not wipe each other, and the confirmation survives
the ambient event that follows it.

Blocked by: `plans/now/ui.md` UI-R-3 -- a debug-panel row that fires named
warning-banner cases directly. Waiting for a death, a spider escape and a
low-energy warning to land within eight seconds of each other is not a check
anyone can run.

Owner: `plans/now/ui.md` UI-Q-1/UI-Q-2.

### C-5 -- Challenge 2's rescue and recovery lines

Trigger a Challenge 2 nectar collapse past stage 2.1, twice: once below the
rescue threshold, once below the failure floor.

PASS: the rescue line ("Ahem. Field ecologists...") appears with 150 nectar
restored, and the checkpoint restore appears with "A brief ecological
wobble..." and a live queen.

Blocked by: `plans/now/challenge-2.md` Slice 1 -- a debug-panel button that
forces the collapse. This check has now failed twice (31 Aug, 3 Sep) with
each attempt separated by days of waiting for the simulation to oblige; the
31 Aug attribution to the `known_patches` restore crash was wrong, since
that crash is confirmed fixed in the same 3 Sep pass.

Owner: `plans/now/challenge-2.md`.

### C-6 -- the deferred recruitment competition fix

The recruitment competition fix (`103d716`) has never been run.

PASS: n/a until it is selected -- this is a deferred code change, not a
shipped behaviour.

Blocked by: a selected recruitment update. The evidence campaign that would
have owned it closed on 3 Sep 2026 with no threshold change
(`plans/archive/FORAGING_EVIDENCE_2026-09-03.md`), so a new plan file has to
pick this up before it can be checked at all.

Owner: none currently.
