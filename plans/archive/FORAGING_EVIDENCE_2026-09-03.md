# Foraging evidence and validation -- active campaign

<!-- CONTEXT: plan | LAYER: active -->
Status: active | Owner: Dave / Claude Code | Next: Slice 5 (the forager-return counter is not in either headless read-out), Claude lane | Dependency: none | Verified: 2026-09-03

Three findings from Dave's 31 Aug hands-on pass against `checks/ready.md`'s
Foraging window, Proximity recruitment and Safe forager return reserve
entries. `ROADMAP.md`/`DESIGN_BACKLOG.md` already route foraging-mechanics
evidence work here; this is the first live file at this path -- the
previous campaign's record is archived at
`plans/archive/FORAGING_EVIDENCE_CAMPAIGN_2026-08-29.md`, closed and not
reopened per `plans/README.md`'s own rule (this is new work, not a
continuation of that one).

Slices 1, 2 and 3 are all shipped. Slice 1 is archived at
`plans/archive/FORAGING_EVIDENCE_SLICE_1.md` and its hands-on check was
confirmed on 2 Sep 2026. Slice 3 shipped as `codex/x1` (merged 2 Sep 2026);
its hands-on check is still open in `checks/ready.md`'s "Safe forager return
reserve" entry. Slice 2 shipped as `codex/x2` (merged 2 Sep 2026) and its
result is recorded in place below -- it needed no hands-on check.

Slice 4 came out of Dave's 2 Sep hands-on pass and shipped as `claude/fe-4`
on 3 Sep 2026; its hands-on check is open in `checks/ready.md`'s "Proximity
recruitment" entry. Slice 5 was found while filing it, and is implementable
now. Slices 2 and 3 are kept here rather than archived because Slice 4's
acceptance reads against Slice 2's finding, and because Slice 3's own check
is still open.

## Slice 2 -- Proximity recruitment: wiring confirmed clean in static code; needs a validated live/headless run before touching thresholds

**Traced end to end, no defect found.** `_score_trip`
(`bee_foraging.gd:847-898`) unconditionally calls
`_update_dance_eligibility(bee)` on every completed trip; that function
correctly gates on `GameConfig.proximity_recruitment_on` and computes
seeker/mentor eligibility from `avg_collection_rate` against
`recruit_lower/upper_threshold_nectar/pollen` once `trips_scored >=
recruit_grace_trips`. `bee.gd`'s per-frame dispatch (~line 1134-1139) calls
`BeeForaging.check_dance_proximity(self, delta)` every frame for every
non-dancing forager while the toggle is on, matching a mentor to any
eligible seeker of the same `resource_type` within `recruit_dance_radius`
(100.0). A successful match calls `_complete_dance()`, which calls
`DiagnosticLog.log_recruitment_match(seeker, mentor, "dance")` -- the *same*
`_recruitment_matches` counter the Foraging window already displays and
that Dave has already confirmed reads real numbers for auto-recruitment's
own matches. So this is independently checkable without a lucky visual
catch: **if `_recruitment_matches` never moves over a long
proximity-recruitment-only run, that's numeric confirmation this genuinely
never fires, not just that Dave didn't happen to see it.**

**Two untested, plausible reasons it might genuinely be rare rather than
broken, worth ruling out before touching any threshold:**
1. `recruit_lower_threshold_nectar/pollen` (0.27/0.23) and
   `recruit_upper_threshold_nectar/pollen` (0.45/0.31) require a forager's
   `avg_collection_rate` to sit outside a fairly narrow band before she's
   eligible as either a seeker or a mentor at all -- in a colony with
   broadly similar-quality flowers nearby, most foragers may simply never
   cross either line.
2. `has_danced_this_visit` limits a mentor to one recruit per hive visit,
   and eligibility is only (re-)computed once per completed trip
   (`_score_trip`) -- a mentor who deposits and leaves quickly may rarely
   overlap, within `recruit_dance_radius` and indoors, with an
   already-eligible seeker on the same frame.

**Action:** before any threshold change, run one long session with
Proximity recruitment on (Auto-recruitment correctly forced off by the
existing mutual-exclusion) and read `_recruitment_matches`/
`dance_eligible_mentors`/`dance_eligible_seekers` list sizes from the
diagnostic snapshot (`diagnostic_log.gd`'s existing summary output, ~line
935) periodically through the run. If mentor/seeker lists populate but
never overlap in time, it's a spatial/timing tuning question (radius, or
how long a mentor stays eligible before her next trip clears it). If the
lists themselves stay empty, it's a threshold-tuning question (the band is
too narrow for typical colony conditions). Either answer is real evidence;
guessing a threshold change without this read first would match
`plans/archive/CHALLENGE1_2026-09-15.md`'s "not a blind fix" precedent for exactly this
kind of unconfirmed finding.

**Result (2 Sep 2026, X2): confirmed operational; no threshold change.**
`test_scenarios/proximity_recruitment_evidence_x2.json` ran for 40 days
with `proximity_recruitment_on: true` and `auto_recruitment_on: false`
(seed 12345, 16x time scale). Its 30-sim-second snapshots reached four
observations where both eligibility lists were non-empty (mentor maximum 4,
seeker maximum 6), and the final diagnostic summary records 25
`recruitment_matches` (all `via: "dance"`), 47 partner overlaps, and 82
recruitment follow-ups. This rules out both an empty-threshold band and a
complete spatial/timing failure in this representative long run. Keep the
current thresholds and radius; a later tuning decision needs a player-facing
reason, not a wiring fix.

## Slice 3 -- Safe forager return reserve: rare by design, needs its own counter to be checkable at all

**Confirmed why this is hard to observe, not a defect in the estimate
itself.** `check_critical_recall` (`bee_survival.gd:135-152`) only
evaluates while a forager is outdoors, actively searching/flying
(`SEEK_FLOWER`, `SEARCHING`, `TO_FLOWER`, `MOVE_TO_POINT`), and explicitly
skips her entirely the moment she's carrying any nectar
(`current_load_type == "nectar" and current_load > 0.0` -> early return,
since `sip_from_crop` is already keeping her fed). Separately,
`needs_a_drink`/`drink_at_flower` (`bee_foraging.gd:441-456`) tops any
forager -- nectar or pollen -- back up to `energy_capacity` from whichever
flower she's standing on, whenever her energy drops below 70%
(`forager_drink_threshold`). In an ordinary meadow with flowers reasonably
close together, a forager refuels locally long before
`estimated_return_energy()`'s calculated reserve is ever approached while
she's actually in one of the four checked states -- so the emergency recall
is, by design, only ever expected to fire when flowers are genuinely sparse
or distant relative to her energy burn (rain, a long range, a thin patch),
which is a harder scenario to land in by accident than an ordinary
playthrough. This matches Dave's report precisely: he isn't failing to
notice it, ordinary play essentially never asks the mechanism to do
anything.

**Confirmed gap: there is no way to check this happened at all short of
catching it live.** `check_critical_recall` does call
`DiagnosticLog.log_forager_return(bee, "started", required)`
(`bee_survival.gd:145`, `diagnostic_log.gd:479`) the instant it fires -- but
unlike `_orientation_flights`/`_recruitment_matches`, there is no running
counter for this event anywhere, and nothing in `foraging_panel.gd` reads
it. The only way to know it ever happened today is to grep the raw
diagnostic log file after the fact.

**Fix (reusable, matches the existing pattern exactly):** add a
`_forager_returns_triggered: int` counter to `diagnostic_log.gd`,
incremented alongside the existing `_write()` call inside
`log_forager_return` (mirroring `_orientation_flights += 1`/
`_recruitment_matches += 1`'s exact shape), reset in the same place those
two are reset, and surfaced in `foraging_panel.gd` next to the existing
orientation-flight/recruitment-match rows. This makes the mechanism
checkable by number over a long run (does it ever fire at all, and does the
count grow when Dave deliberately engineers a sparse/long-range scenario)
without needing a lucky visual catch -- the same reason those two counters
were added in the first place.

**Action, once the counter exists:** re-run this check specifically with
foragers working flowers well out toward the edge of the meadow, or with
rain active (`rain_flight_burn_factor` raises the burn rate the estimate
itself already accounts for) -- conditions likely to actually separate her
energy from the drink-at-flower safety net long enough for the reserve
estimate to matter.

## Slice 4 -- A recruitment dance is happening and cannot be found on screen

**Confirmed, both ways (2 Sep 2026).** Slice 2's headless run recorded 25
dance matches over 40 days, and Dave's live pass confirms matches are
happening. His remaining report is the whole of this slice: *"recruitment
matches are happening but I can't see them happening -- make a toggle
setting so these bees are visually highlighted to make them easier to
find."* Nothing about the mechanism needs changing.

**Why it is hard to catch.** A dance is two bees, indoors, among however
many others are milling about the comb, for the length of one timer, with
no visual difference from any other pair standing near each other. The only
outward sign today is the selection panel's `task_description()` text, which
requires having already picked the right bee.

**Fix -- follow `search_ring` exactly; it is the same problem solved once
already.** `bee.gd` already carries four rings (`selection_ring`,
`alarm_ring`, `attack_ring`, `search_ring`) at increasing radii, and
`_update_search_ring()` shows a pulsing ring for the whole time a bee is in
`State.SEARCHING`, skipped when off screen, driven from the per-frame
presentation block.

- a) Add a `Session` preference `show_recruitment_highlight` (default
  `false`) -- a `Session` key, not a `GameConfig` one, because it is
  presentation and must not change simulation. Add it to
  `settings_catalogue.gd`'s `SESSION_KEYS` list and give it a row in the
  **Appearance** category next to `show_forager_labels`, with a tip saying
  it rings the two bees in a recruitment dance so they can be found in a
  crowd, and that it costs nothing when off.
- b) Add `dance_ring: Polygon2D` to `bee.gd`, built in the same block as the
  other four at `Shapes.circle_points(outline_radius + 17.0)` -- outside
  `search_ring`'s `+14.0` so the two never sit on top of each other. Give
  the mentor and the seeker different colours so the pair reads as a pair
  with a direction: mentor a warm yellow, seeker a cool blue, both at the
  same 0.85 alpha the others use. `Bee.dance_role` already holds
  `"mentor"`/`"seeker"`.
- c) Add `_update_dance_ring()` modelled line for line on
  `_update_search_ring()`: same off-screen early return, visible only while
  `state == State.DANCING` **and** `Session.show_recruitment_highlight`,
  same `SEARCH_RING_PULSE_HZ`-style pulse with its own named constant. Call
  it from the same `Perf.begin("bee_label")` block as
  `_update_search_ring()`.

**Acceptance.** With Proximity recruitment on and the new toggle on, a
dancing pair is findable on screen without hunting; the two bees are
distinguishable from each other; the ring disappears the moment the dance
ends. With the toggle off, nothing renders and no per-bee work is done
beyond the one boolean read. Auto-recruitment's own entrance exchange
(`AT_ENTRANCE_SEEKING`/`AT_ENTRANCE_MENTORING`) is deliberately **not**
covered by this slice -- those bees wait at a fixed, already-obvious place.

**Check:** `tools/verify.ps1`. One hands-on check to file: the acceptance
above, replacing the archived Proximity recruitment entry's "watch for a
forager briefly circling another one indoors" clause.

**Result (3 Sep 2026, `claude/fe-4`): shipped as planned, with two
departures worth recording.** The row went into the **Appearance**
category as specified rather than beside `show_forager_labels`, which
turned out to live under **Foraging**, not Appearance -- the category was
the load-bearing half of that instruction and the adjacency was not.
`show_recruitment_highlight` was also added to `player_profile.gd`'s
`PREFERENCE_KEYS`, which the plan did not list: without it the toggle
would reset every launch, unlike every other Appearance toggle. The ring
sits at `outline_radius + 17.0` outside `search_ring`'s `+14.0`, pulses at
its own `DANCE_RING_PULSE_HZ` of 2.4 (faster than `search_ring`'s 1.6, so
the two read as different events even at the same moment), and takes its
colour per frame from `dance_role` since which of the two a bee wears is
not known until she dances. With the toggle off `_update_dance_ring` is
one boolean read and, at most, one hide -- the off-screen check and every
trig call sit behind it.

**Files:** `scripts/bee.gd`, `scripts/settings_catalogue.gd`,
`scripts/session.gd`.

**Next after:** Slice 5.

## Slice 5 -- The forager-return counter cannot be read from a headless run

**Found 3 Sep 2026, while filing Slice 4.** Slice 3's whole point was to
make the emergency recall (`bee_survival.gd::check_critical_recall`)
checkable *by number* over a long run instead of by a lucky visual catch.
The counter itself shipped: `diagnostic_log.gd` declares
`_forager_returns_triggered`, increments it in `log_forager_return`, resets
it beside `_orientation_flights`/`_recruitment_matches`, answers
`event_count("forager_return")`, and `foraging_panel.gd` prints it as
"Forager returns triggered". So a player watching the panel can read it.

**The gap is that a headless run cannot.** `_orientation_flights` and
`_recruitment_matches` each appear in *both* of the two read-outs a
scenario run produces -- `end_session`'s run-total dictionary
(`"orientation_flights"`, `"recruitment_matches"`) and `_snapshot`'s
periodic `foraging` block (`"orientation_flights_total"`).
`_forager_returns_triggered` is in neither. That is exactly the read Slice
3's own "Action, once the counter exists" asks for: rerun with foragers
working the edge of the meadow, or with rain on, and see whether the count
moves. Slice 2 answered its question that way and Slice 3 cannot, for want
of two dictionary entries.

**Fix.** Add `"forager_returns_triggered": _forager_returns_triggered` to
`end_session`'s totals dictionary beside `"orientation_flights"`, and
`"forager_returns_total": _forager_returns_triggered` to `_snapshot`'s
`foraging` block beside `"orientation_flights_total"`. Nothing else: the
counter, its reset and its panel row are all already correct, and no other
file reads either dictionary by a fixed key set.

**Acceptance.** A scenario run's snapshots and its end-of-run summary both
carry a forager-return figure, so Slice 3's sparse/long-range rerun can be
done headlessly and read like Slice 2's was, without a live watch.

**Check:** `tools/verify.ps1`. No hands-on check -- it is two read-only
dictionary entries, and the acceptance is a headless run's own output.

**Files:** `scripts/diagnostic_log.gd`.

**Next after:** none. Both remaining items in this plan are then Dave's
runs: Slice 3's sparse/long-range confirmation and Slice 4's acceptance.
Archive this file once those two checks are confirmed.

## Closed 3 Sep 2026

Dave's 3 Sep hands-on pass confirmed Slice 4 outright: the recruitment-dance
highlight makes a dancing pair findable, the mentor and the forager she is
dancing at read as different bees, the toggle survives a restart, and with
the toggle off the dance still happens (the recruitment-match count still
moves). That was this campaign's last open question.

Slice 3's own check went the other way, by decision rather than by evidence:
"no increase [in] Forager returns triggered, as it's so unlikely to happen
-- let's drop this and assume it works." The emergency recall stays as
built, its counter and panel row stay, and the sparse/long-range rerun is
not going to be run. **Slice 5 was dropped with it**: it existed only to
make that rerun readable headlessly, and was removed from `NEXTSTEPS.md`
unstarted on 3 Sep. Nothing else read the two dictionary entries it would
have added.

This file is closed. A later recruitment or foraging-evidence question
starts a new plan under `plans/now/`; per `plans/README.md` this one is not
reopened. The one loose thread is the deferred recruitment competition fix
(`103d716`), parked in `checks/blocked.md` as C-6 with no owner.
