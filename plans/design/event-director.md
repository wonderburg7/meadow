# Event director -- the alpha's small scheduler of colony pressures

<!-- CONTEXT: plan | LAYER: design -->
Status: agreed design, not yet a plan | Owner: Dave | Next: EV-0 in `plans/now/event-director.md`; the event slices (EV-1 onward) are written there when CQ-R2 and ED-3 near | Dependency: CQ-R2 (`plans/now/code-health.md`) creates `event_director.gd` (new, in `scripts/`); it and every EV slice wait for the alpha chain's save slices (ED-3, `plans/now/difficulty.md`) | Verified: 2026-11-01

What schedules pressure on the colony in a Colony Run, and what it may
choose. `plans/design/product-scope.md` §6.2 names the event director as a
shared foundation; this file is that design pass for the closed alpha.

## Current state

- One readiness-aware event exists: the first crisis (FC-2), an announced
  heavy rain inside a measured window that comes early when the colony is
  prepared and falls at the window's end with a full warning lead when it
  is not (`scripts/main.gd`, "the first crisis" section;
  `plans/archive/crisis-readiness_2026-10-17.md`). It holds ordinary rain
  off while it runs.
- Ordinary rain rolls by chance (`GameConfig.rain_chance_per_day`,
  `main.gd::_advance_weather`). Crab spiders spawn per flower by chance
  (`crab_spider.gd::maybe_spawn`). Nothing schedules either against the
  colony's state.
- `ColonyDiagnostics.crisis_readiness()` is the readiness reading FC-2 uses;
  the director reuses it rather than adding a second one.

<!-- LAYER: durable-rules -->

## Decisions (Dave, 1 Nov 2026)

1. **A small director, few events.** For the closed alpha the director
   schedules the first crisis and one or two further pressures in the
   20-60 minute stretch, choosing by elapsed time, colony readiness,
   recent events and difficulty. It schedules pressure; simulation rules
   decide the outcome (§6.2). A full catalogue, pacing curves and
   post-alpha threats are out of this version.
2. **It lives in `event_director.gd` (new, in `scripts/`), created by CQ-R2.** CQ-R2
   (`plans/now/code-health.md`) moves the first crisis out of `main.gd`
   into that file as the director's first event, behaviour unchanged, in
   place of the `first_crisis.gd` it planned. Director slices extend it;
   there is no second extraction.
3. **The alpha's pressures are three, beside the first crisis:**
   - **a second heavy rain** -- reuses FC-2's rain, warning and readiness
     reading; it tests whether the player kept their rain preparation;
   - **a crab-spider surge** -- spiders gather on one busy flower patch for
     a while, using the existing spider foundations;
   - **a forage dearth** -- one patch's nectar fails for some days.
   Disease outbreaks are not a director event in the alpha.
4. **Two pressures before winter, one after (Dave, 1 Nov 2026).** Beside
   the first crisis, a Colony Run gets two director pressures before the
   first winter and one after it, before the gynes. Dave: "winter comes too
   fast" -- he wants more time and more than one crisis before winter. The
   count and the slots are *settings, not code*: Dave expects to keep
   changing timings, day lengths and season lengths, so the schedule must
   be overseen and edited from one central place (the open questions
   say where).
5. **Signs first, then Dr Gallerin (Dave, 1 Nov 2026).** A spider surge or
   a forage dearth has no banner when it starts: the player sees the signs
   (spiders on a patch, a patch's nectar falling) and the colony readout
   explains them. Dr Gallerin warns some time after it starts. Heavy rain
   keeps FC-2's announced lead.
6. **Easy waits for readiness (Dave, 1 Nov 2026).** On Easy each pressure
   waits until the colony reads as ready (`crisis_readiness()`), up to a
   later fallback day; Standard takes its calendar slot whatever the
   readiness. This answers `plans/now/difficulty.md`'s open question.

7. **One "Calendar and events" settings group (Dave, 1 Nov 2026).** Every
   timing value -- day length, season lengths, winter onset and length,
   the first crisis window and the director's slots -- is a `GameConfig`
   field in one settings-window group, all in days (FC-2's window is in
   seconds today), with a read-only timeline row showing the run they make
   from day 1 to the gynes. `GameConfig` owns them and `settings_catalogue.gd`
   lists them, as for any balance value; there is no separate calendar
   table. Converting FC-2's seconds to days changes no gameplay.
8. **Slots are absolute days (Dave, 1 Nov 2026).** Each director slot is a
   day number (a window of days), not an offset from winter. Moving winter
   means re-checking the slots by hand; the timeline row is where that is
   seen.
9. **Dr Gallerin warns after a fixed delay (Dave, 1 Nov 2026).** For a
   spider surge or a forage dearth he speaks a set time after it starts --
   a value in the calendar group, not a diagnostic threshold.
10. **Winter comes about a week later (Dave, 1 Nov 2026).** Today winter
    runs days 31 to 41 (`season_length_days` 30; the countdown opens on day
    16). The intent is winter from around day 38: Dave, "winter shouldn't
    start that early as the game starts at the beginning of spring". That
    leaves the first crisis (days 12-15 after PN-11) and two pressures well
    spaced before it. This
    supersedes the onset day in `plans/archive/winter-onset_2026-10-01.md`
    (the mechanism -- a fixed-day countdown -- is unchanged). It changes a
    gameplay outcome, so its own slice sets the number by simulation: the
    pacing gates (`tools/pacing_gates.py`) over three seeds before and after,
    the 60- and 90-minute gates re-judged on the new calendar.

11. **EV-0 moves winter before PP-10 (Dave, 1 Nov 2026).** The calendar
    group and the later winter are one slice, EV-0
    (`plans/now/event-director.md`), run after PP-11 and before PP-10, so
    PP-10 prices the route to Gyne rearing once, on the new calendar.
12. **A save made before the director gets no director events (Dave,
    1 Nov 2026).** Loading it plays on with the first crisis as it was and
    no scheduled pressures; a save without the schedule field reads as
    "none". No migration step.
13. **A forage dearth hits nectar and pollen (Dave, 1 Nov 2026).** For its
    days one patch's flowers refill neither nectar nor pollen (so Bee Bread
    feels it too); seed set and offspring quality (§10) are untouched, and
    the patch recovers fully afterwards.
14. **The scenario harness may force a director event** (a test-only
    action, like `set_config`), so each event has a headless check without
    waiting for its slot. Not a gameplay outcome; recorded here so EV
    slices do not each invent one.

## Open questions

None left that blocks writing the EV slices. The numbers (slot days,
dearth and surge lengths, Dr Gallerin's delay, Easy's fallback day) are
balance values set by simulation when each slice is written.
