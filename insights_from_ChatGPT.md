# Current insights from ChatGPT

> **CHATGPT ADVISORY FILE. Claude Code must ignore this file unless Dave
> explicitly points to it.**

Purpose: a small, current-only queue of evidence-backed findings for Dave to
hand to Claude when useful. Completed or rejected items are deleted, not kept
as prose history; Git already preserves that history. Keep each entry to
evidence, consequence and next action. Do not add implementation diaries or
status tables.

Last refreshed: 22 Aug 2026, from the day 1-116 long run
`session_1787414045.jsonl` and its day-112 performance overlay.

## Highest-value work

### P0. Idle miner searches dominate bee processing

**Evidence:** at 6 fps the frame took 144.8 ms. Bee processing cost 64 ms;
`bee_state_miner` alone cost 43-45 ms for 24 miners, while 85 foragers cost
about 3 ms. Mining had finished by day 58, but each `MINE_IDLE` miner still ran
the same failed queued/marked/nearest-edge searches. Those searches currently
run through idle dispatch every frame.

**Recommendation:** first gate idle job dispatch to staggered think ticks.
Then give the hive cheap marked/exposed-work counts or queues and cache the
global "no mining work" result until an order or topology change invalidates
it. Prefer one shared work allocator over every idle miner scanning the hive.

### P0. Fog relighting is the other main frame cost

**Evidence:** `fog_of_war_update` cost 55-56 ms and
`fog_of_war_relight` 54-55 ms. `_relight_delta` avoids most tile writes but
still walks the full reveal disc twice for every moving bee. With 85 outdoor
bees, this remains proportional to bee count times disc area. Bee processing
plus fog consumed roughly 83% of the 145 ms frame; nested profiler rows must
not be added to their parents again.

**Recommendation:** budget/stagger relights across frames, then replace the
full-disc membership scans with a true edge/row-span update. If that remains
too expensive, share light sources for bees in the same coarse area or move
the dynamic light mask to the GPU while keeping permanent exploration state on
the CPU. Do not optimise forager, nurse, honey or corner-refresh paths first;
their measured costs were small.

### P1. A build target appears permanently unreachable

**Evidence:** the last cell completed on day 57. One unbuilt cell then remained
through day 116. From day 100 onwards there averaged 23.9 comb workers, 23.6 in
`TO_BUILD_SITE`, none `BUILDING` and none `BUILD_IDLE`. The log cannot prove
the cell identity stayed the same, but total and completion counters never
advanced.

**Recommendation:** log target cell ID/hex, claimed slot and approach/path
failure. Fix invalid-target or reservation handling and consider an indoor
work-stall watchdog. This is primarily a simulation bug; removing the wasted
movement is a secondary performance gain.

### P1. Outdoor foragers need an energy-aware abort decision

**Evidence:** 53 bees starved: 51 foragers and two miners. Fifty deaths were
outdoors; 42 occurred while the hive held more than 1,000 honey. Forty deaths
clustered around the days 51-63 nectar trough. Outdoor deaths averaged 669
units from the hive and reached 1,376 units. Foragers drink only after reaching
a flower with worthwhile nectar; depleted flowers send them back into search,
with no low-energy instruction to return home.

**Recommendation:** add an emergency return-home threshold which reserves
enough energy for estimated distance home. Log resource focus, load, distance
home, target-flower nectar and time since the last drink on starvation before
tuning the threshold.

## Smaller but useful work

### Validate every foraging start point against obstacles

Automatic orientation/scout points, recruitment jitter and manual start
points are accepted without checking trees or raised areas. This is a genuine
latent defect, but it was not the main cause of this run's starvation: no death
or stall occurred in `MOVE_TO_POINT`, no orientation flight occurred, death
positions were dispersed, and they did not overlap the recorded stall
hotspots. Route every source through one obstacle-clearing helper.

### Investigate repeated flower-route stalls

There were 59 watchdog recoveries, 58 in `TO_FLOWER`; 56 occurred early and
several destination coordinates recurred across 31 bees. Flowers are spawned
clear of obstacles, so this looks more like difficult approach geometry than
flowers placed on raised ground. Add flower ID and nearby-obstacle identity to
stall events, then reproduce the seed before changing steering.

### Make critical indoor hunger legible and race-safe

The two miners died together on day 10 at identical age and position. Just
beforehand there was no ripe honey and only one newly deposited nectar cell;
several hungry bees were travelling to it and only one was observed feeding.
Pollen is not edible. The likely cause is real scarcity and contention, not a
miner failing beside abundant food.

Consider a visible "waiting for food" state instead of immediately resuming
work when a food target is drained, and reserve a small amount when a hungry
bee commits to a cell. Diagnostics should report edible nectar and ripe-honey
amounts, not merely occupied cell counts, plus whether the dying bee lost a
food target or received zero food.

### Re-test foraging automation for long enough to produce evidence

The full orientation/scouting/constancy/recruitment set was active for only
about 190 simulated seconds before quit. Only two foragers reached three
scored trips; there were no new-forager orientation flights or recruitment
matches, while three scouts were still active. Run a pinned-seed comparison
with features enabled before a new forager cohort hatches. Also watch the
24,092 tarsal rejection checks from 981 marks; it may be intended behaviour,
but could indicate avoidable search churn.

## Diagnostic housekeeping

- Replace the `cells.by_contents[""]` JSON key with `"empty"`; the empty key
  is valid JSON but breaks ordinary object-mode parsing in some tools.
- Keep the snapshot invariants: all 2,707 snapshots matched population roles,
  states and cell totals, with regular timing and monotonic counters.
- This run did not meaningfully exercise winter, weather, predators, rivals,
  disease or the newly enabled automation, so it is not evidence for them.

## Older unresolved design questions

- The Nurse tooltip says a colony cannot grow without a nurse, while the queen
  is deliberately a capable backup nurse. Align the wording or the mechanic.
- Decide whether a Stocking specialist should also be diverted into
  clearing/eviction; the current tooltip describes stocking only.
- `nectar_per_honey = 2` with `honey_energy_factor = 4` doubles stored energy
  before worker costs. Keep it if honey making is meant to create energy;
  otherwise model the whole colony/winter economy before changing it.

## Suggested order

1. Stop idle miners doing global searches every frame and re-profile.
2. Reduce fog relight complexity and re-profile at the same population/zoom.
3. Diagnose the persistent unbuilt cell.
4. Add the forager emergency return and safe start-point validation.
5. Improve the narrow diagnostic fields above, then run the longer automation
   comparison.
