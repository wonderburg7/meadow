# Next steps

Read this first in a new session, before anything else in CLAUDE.md. This
file holds only the next 1-3 concrete actions -- it is rewritten (not
appended to) at the end of every build session, so it should never grow
into a history. Full history lives in `git log` and the Notion Build Log.

## Next up

1. **Recruitment competition -- root cause found and fixed this session,
   waiting on Dave's hands-on re-check.** The real bug (not the jitter
   theory from earlier today): an empty-handed return -- patch had
   nothing left -- skipped `_score_trip` entirely
   (`BeeForaging.go_to_deposit_cell`), so `avg_collection_rate` froze at
   whatever a forager's last real delivery read. A mentor whose patch had
   gone dry kept advertising it as good, undiminished, to every new
   seeker, rather than her own next few empty trips pulling her rate back
   down. Confirmed directly in the session logs from earlier today: every
   mentor matched more than once had a bit-identical `avg_collection_rate`
   across every match, sometimes 100+ seconds apart -- proof no trip had
   actually been scored in between. Fixed alongside the other half of
   today's question (is the data too noisy/short-term): the grace-window
   average was an EMA from trip one, putting ~49% of the weight on that
   first trip alone by the time a forager was first judged; it's now a
   plain mean across the grace window, switching to EMA only once
   settled. Both fixes pull real, previously-invisible low readings into
   the distribution, so `recruit_lower/upper_threshold_nectar/pollen`
   were re-derived from a fresh 5-run/150-sample calibration pass (0.42/
   0.56 -> 0.27/0.45 nectar, 0.25/0.31 -> 0.23/0.31 pollen -- see
   `game_config.gd`'s comment for the full writeup). Re-ran the
   recruitment followup comparison post-fix: mentors' rate still drops to
   ~65-80% of pre-match and *stays* down across all 5 tracked trips
   (n=19 down to n=4) -- a sustained depression, not a one-trip
   regression-to-the-mean blip, so the competition effect looks real even
   with the measurement bug gone. **Still open**: the control-group
   comparison (bees who crossed the mentor threshold but were never
   matched, vs matched mentors) that was the original plan for isolating
   the effect cleanly -- worth doing now that the underlying data is
   trustworthy, but not done this session. Both check suites and 5 fresh
   headless runs pass; nothing hands-on played yet.
2. **A large uncommitted diff is sitting here, waiting on Dave's review**
   -- everything below plus the AI playtest harness (item 3) plus this
   session's recruitment fix. Nothing has been committed.
3. **AI playtest harness is built through slice 6**, all self-verified,
   still waiting on review -- see `git log` for the slice-by-slice detail
   (nothing left to build, per `AI_PLAYTEST_PLAN.md`).
4. **Crab spiders: a second round of playtest fixes**, still waiting on
   Dave's hands-on re-check -- see `CRAB_SPIDER_PLAN.md`'s 20 Aug
   "Confirmed" entry.
5. **A backlog of earlier hands-on checks is building up** -- none
   blocked on anything, just not yet played (Challenge 1/2 fixes, Bundle
   A/B from the technical audit). See `git log` around 20 Aug for detail
   if needed.
6. **A full UI redesign is planned, not started** -- `UI_PLAN.md` (20 Aug
   2026), nine build slices, lower priority than the above.

## What this session actually did (21 Aug 2026)

Built diagnostic logging for tarsal marking, orientation flight,
recruitment, floral constancy and scouting, ran real simulations against
it, and used what the logs showed to fix bugs and retune balance numbers
-- not just add instrumentation. Self-verified (`source_checks.py`,
`balance_tests.py`, `FUNCTION_MAP.md --check`, a clean Godot boot all
pass); nothing committed yet.

**Two real bugs found and fixed, both found only because the logs made
scouting/recruitment's near-total failure visible:**
- `bee.gd`'s `TO_FLOWER` handler didn't guard `is_instance_valid` on a
  dying flower, unlike every other flower-handling function -- a bee
  flying towards a flower that died mid-flight got stuck erroring every
  frame, forever.
- The big one: `bee_foraging.gd::wait_at_entrance`'s "nobody came"
  timeout sent a still-scouting seeker to a fresh scout point without
  first reparenting her out of the hive, leaving her pathfinding inside
  `hive_root` towards an unreachable meadow point -- invisible to the
  stall watchdog too, since its first check is "is she inside the hive".
  This was the dominant failure: fixing it took flower visits from ~32
  to 130+ per 60-day run and got scouting actually settling bees (0 to
  6-9 per run).

**Balance numbers retuned from real simulation data, not guesses (see
each field's comment in `game_config.gd` for the derivation):**
recruit_lower/upper_threshold_nectar (0.5/2.0 -> 0.42/0.56),
recruit_lower/upper_threshold_pollen (0.2/0.8 -> 0.25/0.31),
forage_start_radius (200 -> 450, A/B tested), recruit_wait_seconds (10 ->
15, untested guess at Dave's request).

**New standing capability, not just this session's throwaway tests:**
- A "Recruiting" readout in the Colony window's Readouts section (star
  it like any other) shows live how many foragers currently read above
  the offer/below the seek threshold -- `year_winter.gd::
  _refresh_recruit_gap`.
- Scenario `config_overrides` can now set *any* real `GameConfig` field,
  not just the player-save allowlist (`levels.gd::apply_config_overrides`
  now checks via reflection) -- and a scenario's starting shape now
  supports `honey_makers` alongside the other roles it already could set.
- A scenario can set `"snapshot_seconds"` (top-level, like `"time_scale"`)
  to decouple diagnostic snapshot cadence from a compressed test day --
  cut session file sizes ~27x (2MB to ~70KB) on a 60-day/20s-per-day run
  with no loss of resolution anything reads. `analyze_session.py`'s
  population/honey curves are also deduped to one point per day now.
- `DiagnosticLog` gained permanent low-volume events worth knowing about
  for future balance work: `forager_settled` (fires once per bee, the
  moment her rate first becomes trustworthy -- an instant source for the
  rate-distribution data the thresholds above were derived from, no
  temporary debug print needed next time) and `recruitment_followup`
  (both bees in a match, their next 5 trips each, against their pre-match
  rate -- see item 1 above).

Four new/updated files in `test_scenarios/` support all of this:
`foraging_features_on_test.json`, `foraging_features_off_test.json`,
`recruit_threshold_calibration_test.json` (a sustained 45-forager colony,
lifespans stretched via override, for gathering rate-distribution data),
`forage_radius_wide_test.json`.
