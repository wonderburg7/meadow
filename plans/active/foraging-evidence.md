# Foraging evidence and validation -- active campaign

<!-- CONTEXT: plan | LAYER: active -->
Status: active | Owner: Dave / Claude Code | Next: implement Slice 1's decided
Option B fix (move `scouting_on`/`orientation_flight_on` into
`prerequisites.gd::MUTUALLY_EXCLUSIVE`), then Slice 2's validated
live/headless proximity-recruitment run | Dependency: none | Verified:
2026-09-01

Three findings from Dave's 31 Aug hands-on pass against `checks/ready.md`'s
Foraging window, Proximity recruitment and Safe forager return reserve
entries. `ROADMAP.md`/`DESIGN_BACKLOG.md` already route foraging-mechanics
evidence work here; this is the first live file at this path -- the
previous campaign's record is archived at
`plans/archive/FORAGING_EVIDENCE_CAMPAIGN_2026-08-29.md`, closed and not
reopened per `plans/README.md`'s own rule (this is new work, not a
continuation of that one).

## Slice 1 -- Orientation-flight counter reads zero whenever Auto scouting is on, by construction, not by bug

**Confirmed.** A new forager's spawn logic (`bee.gd:718-723`):
```gdscript
if GameConfig.scouting_on and bee_role == Role.FORAGER:
	BeeForaging.start_scouting(self)
elif GameConfig.orientation_flight_on and bee_role == Role.FORAGER:
	BeeForaging.take_orientation_flight(self)
```
is an `if/elif` -- mutually exclusive. `DiagnosticLog.log_orientation_flight`
(and its `_orientation_flights` counter the Foraging window reads,
`foraging_panel.gd:135`) is only ever reached from the `elif` branch. But
`prerequisites.gd::TOGGLE_PREREQUISITE` declares `"scouting_on":
"orientation_flight_on"` -- `scouting_on` *requires* `orientation_flight_on`
as its parent -- and `debug_panel.gd`'s cascade
(`_cascade_prerequisites_on_static`) ticks every ancestor on when a child is
switched on. So turning on Auto scouting also shows Orientation flight as on
(correctly, per the prerequisite graph) -- but the runtime code treats them
as alternatives, not layers: with scouting on, every forager takes the `if`
branch and the orientation-flight counter can never move, no matter how "on"
the toggle reads. This is exactly Dave's report: he sees the toggle
"triggered" (lit by the cascade) but the count sits at zero, because
scouting has silently superseded it for every forager since the moment
scouting was switched on.

**This is a design question, not a one-line bug -- needs Dave's steer
before implementing:**
- **Option A -- make the runtime match the settings graph (both apply
  together).** Have every new scouting forager also register an orientation
  flight first (call `take_orientation_flight` unconditionally when
  `orientation_flight_on`, then layer `start_scouting`'s extra comparison on
  top), so the counter reflects reality for any forager, scouting or not.
- **Option B -- make the settings graph match the runtime (alternatives, not
  layers).** Move `scouting_on`/`orientation_flight_on` into
  `prerequisites.gd::MUTUALLY_EXCLUSIVE` (the map
  `auto_recruitment_on`/`proximity_recruitment_on` already use) instead of
  `TOGGLE_PREREQUISITE`, so switching one off the other and the cascade
  stops implying they run together. The orientation-flight count then
  honestly reads "how many foragers used the simple mechanism instead of
  scouting," and stays at zero exactly when scouting has taken over -- no
  runtime foraging code changes.
- **Option C -- cosmetic only.** Leave both mechanisms as they are (scouting
  is a strict superset, by design) but relabel or footnote the Foraging
  window's orientation-flight stat so a reader doesn't mistake "0" for
  "broken" whenever scouting is active.

**Decided (Dave, 1 Sep 2026): Option B.** Move `scouting_on` and
`orientation_flight_on` from `prerequisites.gd::TOGGLE_PREREQUISITE` into
its existing `MUTUALLY_EXCLUSIVE` map (the same map
`auto_recruitment_on`/`proximity_recruitment_on` already use) -- a one-line
move between two existing maps, no runtime foraging code touched. The
orientation-flight counter then honestly reads "how many foragers used the
simple mechanism instead of scouting," and stays at zero exactly when
scouting has taken over. Not yet implemented; this is the next actionable
step in this plan.

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
`plans/now/challenge-1.md`'s "not a blind fix" precedent for exactly this
kind of unconfirmed finding.

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
