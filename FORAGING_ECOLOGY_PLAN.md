# Foraging ecology plan

Source: Dave's design brief, 22 Aug 2026 (pasted into the Meadow Cowork
session, not Notion — Notion is not consulted, per the repo's own
source-of-truth rule, now corrected in `CLAUDE.md`/`AGENTS.md` alongside
this plan). Full biological/ecological reasoning lives in that brief;
this file is the implementation-ready breakdown Claude Projects is
asked to produce before Claude Code touches any code, refining Slice 0
and Slice 1 only for now, as the brief itself instructs. Slices 2-9 are
kept below as a scope index, deliberately not detailed further yet.

**Nothing in this file is built.** Hand one slice at a time to Claude
Code, review the test results and a hands-on playtest description, then
come back here for the next one.

## What's changed since the brief was written (checked against the live repo, 22 Aug)

The brief flags two things as open risks that are already partly
resolved:

- **"Current uncommitted mentor-consumption and 250-unit
  recruitment-jitter changes" don't exist.** `git status` on the repo
  shows no uncommitted changes to `bee_foraging.gd` or `game_config.gd`.
  The mentor-consumption fix (a matched mentor is removed from
  `hive.entrance_mentors` immediately, so one waiting cycle can't
  oversubscribe her) already shipped and is committed — see
  `NEXTSTEPS.md`'s 22 Aug entry. It's been A/B tested against
  `foraging_features_on_test.json` vs `foraging_features_off_test.json`
  (5 runs each): mean flower visits recovered from 134 (below the 230
  no-automation baseline) to 203. `recruit_start_point_jitter` is
  **150**, not 250 — 250 fixed per-match rates but cost colony
  throughput; 150 is Dave's deliberate middle ground, and NEXTSTEPS
  says explicitly not to re-tune it further until the matching-logic
  rework (this plan's Slice 9) lands. Nothing here needs preserving —
  it's already the baseline to build on.
- **The A/B comparison above is not yet a genuine multi-seed
  comparison.** `main.gd` calls `seed(12345)` once, hardcoded, with no
  scenario-level override — every one of those 5 repeat runs used the
  identical meadow layout. Bee-level randomness (trait rolls, choice
  jitter) still varies run to run since it draws from the same
  consumed RNG stream, so the 5 runs aren't literally identical, but
  they are not independent seeds either. This is a real gap against
  the brief's own "multi-seed comparisons" acceptance criterion, and
  Slice 0 below closes it.

Everything else in the brief's "existing recruitment work" section
still holds: treat the current mentor-consumption behaviour as the
interim baseline, and only replace it with proximity recruitment
(Slice 9) after an A/B comparison shows an actual improvement.

## Fixed design decisions (carried over, not open questions)

- One flower icon = one flower, one feeding position. No multi-slot flowers.
- Meadow has genuinely good and bad areas, not near-uniform scatter.
- Recruitment advertises an uncertain area, never an exact point.
- Scatter within an advertised area is genuinely random (not stratified).
- Bee flower choice uses local perception, never omniscient nearest-flower.
- Every new realism feature is individually toggleable.
- Manual player controls (species lock, starting point) stay authoritative
  over anything learned or recruited.
- All balance numbers live in `GameConfig`; only run/UI state lives in
  `Session` — the existing project rule, unchanged.

## Full slice list (scope index — 2 onward not yet refined)

0. **Establish the control** — seeded, repeatable baseline runs and
   defined metrics. Refined below.
1. **Stats and foraging-window foundation** — event-based trip
   accounting and the first numerical foraging window, no behaviour
   change. Refined below.
2. Species registry — migrate existing species into `flower_species.gd`, then differentiate.
3. Add new species (two at a time, from the UK roster in the brief).
4. Patchy, scalable meadow — lazy flower resource updates, clustered generation, staged count increases.
5. Local search — perception radius, search anchors, expanding-loop search.
6. Probabilistic choice and memory — heading-weighted selection, recent-flower avoidance, patch memory.
7. Handling experience and adaptive constancy — species familiarity, preference confidence.
8. Finite pollen and ecological time — flower lifespan/opening rules, schedules in simulated time.
9. Proximity recruitment — the dance-floor model, superseding today's entrance-wait mechanism only after a proven A/B win.

---

## Slice 0: Establish the control — implementation-ready

**Goal:** a seeded, multi-run baseline that Slice 1 onward can be
measured against, using tooling that already exists
(`tools/run_scenario.py`, `DiagnosticLog`, `test_scenarios/*.json`)
rather than building anything new.

**Tasks**

1. **Make the meadow seed scenario-configurable.**
   `main.gd:278` currently does `seed(12345)` unconditionally. Add a
   `"seed"` field to the scenario JSON's `config_overrides`-adjacent
   top level (alongside `stop`/`snapshot_seconds`, not inside
   `config_overrides` since it isn't a `GameConfig` value), defaulting
   to `12345` when absent so every existing scenario file keeps its
   current behaviour unchanged. Wire it into that same `seed()` call.
2. **Add a small set of fixed alternate seeds** for repeat testing —
   Dave's specific seeds if he has any preference, otherwise 4-5 picked
   once and reused (e.g. 12345, 7, 2026, 90210, 555). Record them in
   this file once chosen, so "multi-seed" means the same seeds every
   time, not a fresh random set per test.
3. **Define the exact trip and recruitment metrics**, split into what
   already exists and what's genuinely new:
   - **Already logged today** (`diagnostic_log.gd`): recruitment
     matches, recruitment followups (per-trip rate after a match),
     scouting-settled count, orientation flights, forager-settled
     count, flower visits (total and unique), tarsal marks/rejections,
     stall recoveries, deaths by cause/role.
   - **Not yet logged, needed for this plan** (build in Slice 1, not
     here): flowers visited per successful trip, resource collected
     per flower, trip duration split into search/flight/handling time,
     empty-return rate, per-species breakdown of all of the above.
     Slice 0 should only *name* these as the target metric set — don't
     add fields yet, that's Slice 1's job.
4. **Re-run the control comparison Dave already has, properly seeded.**
   `foraging_features_on_test.json` vs `foraging_features_off_test.json`
   already exist and already gave the 134→203 flower-visits result
   cited in NEXTSTEPS. Re-run both, 5 repeats each, once per seed from
   step 2, using `tools/run_scenario.py --repeat 5 --full`. This
   produces the real "unmatched-high-performer control" comparison the
   brief asks for — multiple independent layouts, not one layout
   repeated.
5. **Record a performance baseline** at the current flower/bee counts
   using `perf.gd`'s existing top-8 breakdown, at the colony size
   already used for prior performance work (~29 bees), so Slice 4's
   later flower-count increases have something concrete to compare
   against. No code change — just a recorded number.

**Deliverable:** a short results note (can live in this file, appended
under a "Slice 0 results" heading, or as its own dated section) giving
the seed list, the re-run comparison numbers, and the performance
baseline. No gameplay code changes in this slice — only the one-line
scenario-seed plumbing in `main.gd`.

**Checks:** `source_checks.py`, `balance_tests.py`, a Godot boot via
`mcp__godot__run_project` if available, and the multi-seed scenario
runs themselves stand in for a hands-on check here — there's no new
visible behaviour to click through.

### Slice 0 results (22 Aug 2026)

**Task 1 turned out already done.** `main.gd:278`'s assumed unconditional
`seed(12345)` is stale — `CHATGPT_INSIGHTS_PLAN.md`'s A2 work already
added a scenario JSON `random_seed` field plus a `--random-seed=` CLI
override (`main.gd:976-995`, `run_scenario.py:61-135`), wired before this
plan was written. No code change was needed; only new scenario files.

**Seeds used:** 12345, 7, 2026, 90210, 555 — following the repo's
existing `a2_seed_111_test.json` convention, one new scenario file per
seed per side: `test_scenarios/foraging_features_{on,off}_seed{N}_test.json`.

**Re-run comparison** (one run per seed per side — reduced from the
5-repeats-per-seed the task originally specified, after Dave flagged that
as an oversized/wasteful batch; see `docs/known-pitfalls.md`-style note
in memory `feedback_headless_run_batches`):

| side | seed | flower_visits | total_deaths | recruitment_matches | foragers_settled |
|---|---|---|---|---|---|
| on | 12345 | 225 | 21 | 7 | 14 |
| on | 7 | 221 | 20 | 5 | 14 |
| on | 2026 | 215 | 20 | 8 | 14 |
| on | 90210 | 210 | 21 | 6 | 13 |
| on | 555 | 204 | 20 | 5 | 12 |
| off | 12345 | 392 | 22 | 0 | 0 |
| off | 7 | 388 | 22 | 0 | 0 |
| off | 2026 | 378 | 22 | 0 | 0 |
| off | 90210 | 353 | 21 | 0 | 0 |
| off | 555 | 366 | 22 | 0 | 0 |

On (features on): mean flower_visits ≈215 across 5 independent seeds.
Off (features off): mean flower_visits ≈375. This gap is wider than the
single-seed 203-vs-230 figure NEXTSTEPS previously cited — expected,
since `off` disables recruitment/scouting/orientation entirely (hence
`recruitment_matches`/`foragers_settled` both 0), removing all the
overhead auto-recruitment adds to a trip, not because `on` regressed.
Read this as the real multi-seed shape of the existing on/off gap, not
as a new regression to chase.

**Not done this slice:** the 5-repeats-per-seed jitter averaging (only 1
run per seed was taken, to keep the batch small per Dave's steer) and
the `perf.gd` performance baseline (needs an interactive boot with the
"fps" star — no `mcp__godot__*` tools were connected this session, so
this stayed a hands-on item for Dave rather than something automated).

---

## Slice 1: Stats and foraging-window foundation — implementation-ready

**Goal:** make existing foraging observable in detail, with **no
behavioural change whatsoever** — this slice is purely additive
instrumentation and a read-only panel.

**Tasks**

1. **Add `foraging_stats.gd`**, a new plain Node child of `main`
   (matching the `world_building.gd`/`orders_zones.gd` pattern already
   used for `main`'s siblings — not a `RefCounted` static-helper file,
   since this one holds live aggregated state across the whole run,
   the same shape as `DiagnosticLog`). It receives events, not raw bee
   list scans, and maintains counters only — the brief's own
   requirement that the panel never scans every bee/flower on redraw.
2. **Split trip timing into its components**, in `bee_foraging.gd`.
   Today a trip's duration isn't decomposed at all. Add three
   lightweight timers/stamps to the trip lifecycle already tracked via
   `trip_load_amount`/`_score_trip`: time from leaving the hive to
   first flower contact (search + flight combined, since there's no
   local-search behaviour yet to separate them further — that split
   only becomes meaningful once Slice 5 exists), time spent handling
   flowers, and total trip time. Feed these into `foraging_stats.gd`
   on each `_score_trip` call rather than storing per-bee history.
3. **Add empty-return tracking.** `_score_trip` already knows
   `trip_load_amount`; a trip that returns with ~0 load is an empty
   return. Count it in `foraging_stats.gd`.
4. **Add per-species breakdown**, keyed by `bee.resource_type` and
   `bee.scout_species`/preferred species where set — since there's no
   `flower_species.gd` registry yet (that's Slice 2), key by the
   existing species string identifiers already used in `flower.gd`,
   not a new enum. This will get a cleaner home once the registry
   exists; don't block Slice 1 on Slice 2.
5. **Build `foraging_panel.gd`** as a new, separate panel (not a new
   `hud.gd` section, per the brief and per the existing `UI_PLAN.md`
   pattern of pulling panels out rather than growing `hud.gd` further).
   First version shows exactly the brief's three sections — Overview,
   Species, Recruitment — reading only from `foraging_stats.gd`'s
   counters and `DiagnosticLog`'s existing recruitment/scouting counts.
   No heatmap, no patch-memory display — those are explicitly "later
   version" in the brief.
6. **No changes to `bee_foraging.gd`'s decision logic.** The only
   `bee_foraging.gd` edits in this slice are adding timestamp captures
   and stat-event calls at points that already exist
   (`start_collecting`, `_score_trip`, `wait_at_entrance`) — never
   changing what a bee decides to do.

**Deliverable:** a playable slice where the new panel shows real,
correct numbers for the existing foraging/scouting/recruitment
behaviour, verified by comparing its Overview totals against
`DiagnosticLog`'s existing session-summary counts (they should agree
where both track the same thing, e.g. flower visits).

**Checks:** `source_checks.py`, `balance_tests.py` (should be
unaffected — no balance numbers touched), a Godot boot, a
`tools/run_scenario.py --full` run to confirm the new stats aren't
silently zero, and a hands-on check from Dave opening the new panel
mid-run and sanity-checking the numbers against what he can see
happening on screen. Update `FUNCTION_MAP.md` only if `hud.gd` or
another mapped file is touched — a new standalone panel file doesn't
need an entry.

### Slice 1 results (22 Aug 2026)

**Built as specced**, all six tasks:

- `foraging_stats.gd` — a plain `Node` child of `main` (`world_building.gd`/
  `orders_zones.gd`'s pattern), holding running counters plus a
  `"resource_type|species"` breakdown. Nothing scans the bee list; it's
  fed one call per scored trip. No `reset()` — every reset path already
  goes through `get_tree().reload_current_scene()`, which recreates
  `main` and every sibling under it from scratch.
- `bee.gd` gained four fields next to the existing
  `trip_start_time`/`trip_load_amount`: `trip_first_flower_time`,
  `trip_handling_seconds`, `trip_flowers_visited`, and a private
  per-visit scratch stamp `_flower_visit_started_at`.
- `bee_foraging.gd`: `start_collecting` stamps first-contact time and
  bumps the flower count; `finish_collecting` accumulates handling
  seconds; `_leave_hive_and_resume` and `start_scouting` reset the new
  fields at the same point they already reset `trip_start_time`;
  `_score_trip` reads them out and calls
  `bee.world.foraging_stats.record_trip(...)` before `scout_species` is
  cleared, so a still-scouting bee's in-progress species is captured.
  **No decision logic touched anywhere** — every edit is either a stamp,
  an accumulate, or a reset at a point that already existed.
- `foraging_panel.gd` — new `CanvasLayer`, `colony_panel.gd`'s pattern
  (code-built `PanelContainer`, collapsible sections, `toggle()`/
  `is_open()`/`refresh()`). Overview (trips scored, flowers visited,
  avg trip/search+flight/handling time, empty-return rate), Species
  (same breakdown per `resource_type`/species), Recruitment (reads
  `DiagnosticLog.event_count` for matches/settled/scouting/orientation —
  no new DiagnosticLog fields needed). No heatmap, no patch memory, as
  specced.
- Wired into `main.gd` (new `foraging_stats`/`foraging_panel` fields,
  instantiated alongside `orders_zones`/`colony_panel`), `hud.gd` (a
  plain-text "Foraging" button next to Nursery, no icon yet — matches
  `winter_button`'s own fallback), `input_selection.gd` (**G** key,
  `C`/`N`/`F`/`O` were already taken), and `year_winter.gd` (refreshed
  once a second alongside the colony panel, only while open).

**Same gate as the existing trip-scoring mechanism, deliberately not
loosened.** `trip_start_time`/`trip_load_amount`/`_score_trip` already
only run when `GameConfig.scouting_on` or `auto_recruitment_on` is on —
with both off, no trip has ever been scored, on any build before this
slice. The new fields and the `foraging_stats.gd` call follow that same
gate rather than running unconditionally, since "no behavioural change"
also means "no new always-on per-frame bookkeeping that wasn't there
before" — a bee with both toggles off pays nothing extra. This does mean
the panel reads all zeroes with both toggles off; the panel's own hint
label says so rather than looking broken.

**Not verified headlessly, unlike Slice 0.** `foraging_stats.gd` is
pure runtime state for the panel — nothing in this slice writes it to
`DiagnosticLog`'s `.jsonl`, so `tools/run_scenario.py` (which only ever
reads that file) has no way to see it. Adding a logging path for it
wasn't in Slice 1's task list and would be scope creep onto Slice 1
proper. Checked instead: `source_checks.py` and `balance_tests.py` both
pass (16/16); a `mcp__godot__run_project` boot completed with no parser
or runtime errors (only pre-existing warnings, plus one new "declared
but never used" warning on `_flower_visit_started_at` that's the same
false positive `_grace_rate_sum` already has — both are written from
`bee.gd` and only ever read via `bee.<field>` from `bee_foraging.gd`,
which Godot's static analysis doesn't trace across scripts). **Still
needs Dave's hands-on check**: open a run with Auto scouting or
Auto-recruitment on, press **G**, and confirm the numbers move and look
sane against what's visibly happening — this was not and cannot be
verified by anything above.

---

### Dave's hands-on check (22 Aug 2026)

Confirmed on a day-5 run with recruitment/scouting on. Panel numbers are
internally consistent — the Overview's 106s average trip time is exactly
the flowers-weighted average of the Species rows (82/62/13/8/3 trips at
42/184/76/195/154s). Two things that looked odd on first read but check
out against the code:

- **search+flight (29s) + handling (18s) = 47s, well under the 106s trip
  average.** Expected, not a bug — `foraging_stats.gd` only tracks
  first-flower search/flight and cumulative handling time, per the Slice
  1 spec; neither covers flight *between* flowers on a multi-flower trip
  (avg 4.5/trip here) or the flight home. That ~59s residual is the
  bucket Slice 5 (local search) would decompose further, not something
  to fix now.
- **0% empty returns across all 168 trips.** Plausible, not miswired —
  `record_trip` only flags empty when delivered load is under
  `GameConfig.min_worthwhile_amount` (1.0), the same threshold `collect()`
  already uses. Worth re-checking on a deliberately harsh scenario (few
  flowers, long distances) rather than a good day-5 run, if it stays at
  0% there too.

## Slice 2: Species registry — implementation-ready and built

**Scope, on inspection.** The brief's "migrate existing species into
`flower_species.gd`, then differentiate" turned out to be two separable
pieces of work. Grepping every `species`/`resource_type` reference
across the repo found ~18 files, but almost all of those touch
`resource_type` ("nectar"/"pollen") or `preferred_species` (a bee's
runtime pin) — genuinely unrelated to the species *data table* itself.
Only three call sites ever touched `Flower.SPECIES`/`pick_species_index`
directly: `flower.gd` (owns the table), `world_building.gd` (seeding a
new flower), and `crab_spider.gd` (rolling this run's target species).
"Differentiate" — giving species further behavioural distinctions beyond
today's data columns — isn't specified anywhere in the brief with actual
numbers or mechanics, so it stays out of this slice; it needs Dave's
design input before it's implementation-ready, same as slices 3+.

**Built:**
- New `flower_species.gd` (`extends RefCounted`, plain data + two
  `static func`s, no state) holds the `SPECIES` array and
  `pick_species_index()`, moved verbatim out of `flower.gd`.
- `crab_spider.gd`'s `roll_preferred_species()` moved alongside them in
  the same file, since it's the same kind of species-table query
  (weighted by `crab_spider_weight` instead of `weight`). This also
  removed a workaround: `crab_spider.gd` previously took the species
  table as a parameter rather than preloading `flower.gd`, specifically
  to avoid a compile-time cycle (`flower.gd` preloads `crab_spider.gd`).
  `flower_species.gd` has no dependency on `flower.gd`, so `crab_spider.gd`
  now preloads it directly and the parameter is gone.
- `flower.gd`, `main.gd` and `world_building.gd` updated to read the
  table via a new `FlowerSpecies` preload const, same pattern as the
  existing `Flower`/`CrabSpider` consts on `main.gd`.
- Save format untouched — `flower.setup(index)`'s signature and
  `species_index` (the int actually persisted) didn't change.
- `tests/balance_tests.py`'s two regex-based readers of the species
  table (`test_crab_spiders`, `test_seasons`) updated from
  `source("flower.gd")` to `source("flower_species.gd")` — these read
  GDScript source as text rather than importing it, so they needed
  updating by hand; nothing else in either test file changed.

**Checks:** `source_checks.py` and `balance_tests.py` both pass (16/16,
including the crab-spider and season checks that read the moved table).
A `mcp__godot__run_project` boot showed only pre-existing warnings (the
same ones present before this slice, e.g. `_flower_visit_started_at`).
A `tools/run_scenario.py` run against `c2_no_jelly_cell_test.json`
confirmed flowers still spawn and get visited at runtime
(`flower_visits: 59`, `unique_flowers_visited: 34`) — this exercises
`world_building.gd`'s `pick_species_index()`/`SPECIES` call and
`crab_spider.gd`'s `maybe_spawn` end to end.

**Not done, deliberately:** no behaviour changed, no new species added,
no "differentiation" beyond the existing data columns. This was a pure
file-move refactor to give Slice 3 (new species) a clean home to add to,
without also touching gameplay in the same slice.

## Slice 3: Add new species — implementation-ready and built

**Species chosen (Dave, 22 Aug):** Bramble and Dandelion, alongside the
existing Clover/Borage/Foxglove/Poppy.

**Differentiation, per Dave's steer:** beyond the existing
season/cluster/colour/crab-spider-weight columns, this slice introduces
one genuinely new column — `handling_time_scale`, a per-species
multiplier on `flower_handling_time` — and uses `crab_spider_weight: 0.0`
for the first time (Bramble), where the brief's existing "some species
may have zero likelihood" allowance hadn't yet been used.

**Built:**
- `flower_species.gd`: two new `SPECIES` entries.
  - **Bramble** — rich in both nectar (18) and pollen (16), a long
    mid-to-late-summer window (0.45-0.90) bridging Foxglove into
    Borage's back half, tightly clustered (hedgerow thicket:
    `cluster_radius` 55, `cluster_chance` 0.75), slow to handle
    (`handling_time_scale` 1.4 — a fiddly ring of stamens), and no crab
    spiders at all (`crab_spider_weight` 0.0 — thorny growth gives a
    spider nowhere flat to sit).
  - **Dandelion** — low value (nectar 6, pollen 8), the earliest flush
    of the year (0.00-0.35, alongside but ecologically distinct from
    Poppy), very common (`weight` 35, the highest in the table),
    loosely scattered rather than patchy (`cluster_radius` 90,
    `cluster_chance` 0.35), quick to handle (`handling_time_scale` 0.6
    — a flat open disc), and a classic ambush site
    (`crab_spider_weight` 35, also the table's highest).
- `flower.gd`: new `handling_time_scale` field, copied from the species
  dict in `setup()` the same way `recharge_scale` already is, defaulting
  to 1.0 for every species that doesn't specify it.
- `bee_foraging.gd`'s `start_collecting` (the only place
  `flower_handling_time` was ever read): now
  `bee.timer = bee.flower_handling_time * bee.current_flower.handling_time_scale`.
  This is the one behavioural change in the slice — every existing
  species keeps its old handling time unchanged (scale 1.0), only
  Bramble and Dandelion differ.
- Both scripts' header comments updated from "two species" to point at
  the roster rather than re-describing it in two places.

**Checks:** `source_checks.py` and `balance_tests.py` both pass (15/15).
Adding two species roughly halved every existing species' *share* of
the meadow (Clover 40%→26% of total weight) — this correctly re-derives
`crab_spider` risk numbers per species (all still within the existing
5-200 days-between-kills / <20% lifetime-risk bounds) but broke one
test assertion that had hardcoded CRAB_SPIDER_PLAN.md's original
two-species worked example ("~4 spiders on Clover at ~40% share").
That assertion was pinned to a species count, not a real invariant —
updated to print Clover's current numbers instead of asserting a frozen
figure, since the general per-species bounds already cover Clover at
whatever share it currently holds. A `tools/run_scenario.py` run against
`c2_no_jelly_cell_test.json` completed cleanly (74 flower visits, 37
unique flowers, no errors), exercising `pick_species_index()` over the
full six-species table and the new handling-time scaling end to end. No
`mcp__godot__*` tools were connected this session, so a Godot boot
wasn't done — **still needs Dave's hands-on check**: a normal playtest
where Bramble (white/pale, slow to work) and Dandelion (bright yellow,
quick, common, occasionally hosting a spider) both show up and behave
distinctly from the existing four.

## Slice 3 fixes from Dave's playtest (22 Aug 2026)

Dave played a normal run with Bramble and Dandelion visible and flagged
two things:

- **Bramble and Dandelion showed the same recharge rate.** Neither set
  `recharge_scale` in Slice 3, so both defaulted to the game-wide
  0.50/s nectar, 0.10/s pollen rates — identical to each other and to
  every other unscaled species, despite being pitched as differentiated.
  Fixed with `recharge_scale` values following the existing
  Foxglove/Poppy pattern: Bramble `0.7` (rich but slow to build back up,
  matching its slow `handling_time_scale`), Dandelion `1.4` (low-value
  and quick, never keeps a forager waiting).
- **Bramble should look like a bush of individual flowers, not one
  icon.** Confirmed with Dave this stays mechanically inside the
  existing fixed rule (one Flower node = one feeding slot) — Bramble's
  own tight clustering (`cluster_radius: 55`, `cluster_chance: 0.75`,
  already in Slice 3) already places several individual Bramble flowers
  close together, each already its own slot. What was missing was
  purely visual. `flower.gd::setup()` now gives any species flagged
  `"bushy": true` (Bramble only, so far) an irregular green backdrop
  polygon per flower, drawn behind the bloom (`show_behind_parent`)
  with jittered shape/position so nearby cluster-mates' backdrops
  overlap into one ragged bush outline instead of a stack of identical
  circles.

**Checks:** `source_checks.py` (66/66) and `balance_tests.py` (15/15)
both still pass. A `tools/run_scenario.py` run against
`c2_no_jelly_cell_test.json` completed cleanly (66 flower visits, 28
unique). No `mcp__godot__*` tools connected this session, so this
still hasn't had a Godot boot — **needs Dave's hands-on check**: open a
run, find a Bramble patch, confirm it now reads as a bush and that its
summary panel's nectar/pollen `+X/s` no longer matches Dandelion's.

## Second playtest round (22 Aug 2026)

Dave played again and flagged three more things, all fixed:

- **A Bramble "bush" was still only ever one flower unit.** The
  previous round's fix was purely the drawn backdrop; whether a bush
  got same-species neighbours nearby still depended on the normal
  cluster-reseed odds over time. Fixed properly this round:
  `flower_species.gd` gives Bramble `bush_min_units`/`bush_max_units`
  (2-4), and `world_building.gd::_seed_flower` now plants that many
  flower units together in one seeding event, tightly jittered
  (`BUSH_UNIT_SPREAD`, 8-24px) around a shared anchor point, whenever a
  Bramble bush is placed. Each unit is still its own `Flower` node with
  its own feeding slot — the one-node-one-slot rule is unchanged; a
  bush is now guaranteed to arrive as several of them at once instead
  of maybe one. **Worth flagging for balance**: this makes Bramble's
  effective share of meadow flowers noticeably higher than its
  `weight: 18.0` alone implies (each weighted pick now yields 2-4
  flowers, not 1) — not simulated against the economy numbers this
  round; watch whether Bramble reads as over-abundant once Dave's
  played more.
- **Clover and Dandelion were both yellow, hard to tell apart.**
  Clover changed to a pinky-purple (real red-clover colour) —
  `Color(0.82, 0.42, 0.62)`, centre `Color(0.35, 0.12, 0.24)` — leaving
  Dandelion as the only yellow species. The old "yellow, classic
  ambush colour" comment justifying Clover's `crab_spider_weight` was
  reworded rather than left describing a colour that no longer applies;
  the weight itself (40.0) is untouched.
- **New `microhabitat` column**, a plain descriptive string on all six
  species (grassland, cultivated bed, wood edge, arable margin,
  hedgerow thicket, open ground) — not read anywhere yet, added so a
  later slice (patchy/microhabitat-aware meadow generation, part of
  Slice 4's scope) has real per-species ground-type data to place from
  instead of every species scattering uniformly.

**Checks:** `source_checks.py` (66/66), `balance_tests.py` (15/15,
unaffected — microhabitat and bush unit count are outside anything the
suite reads), and a `run_scenario.py` run against
`c2_no_jelly_cell_test.json` all pass (82 flower visits, 33 unique —
higher than the previous round's 66/28, consistent with Bramble now
seeding several flowers per bush).

**Dave's hands-on check (22 Aug 2026): confirmed good.** Bramble bushes
show multiple blooms over a shared backdrop, and Clover reads as
pink/purple, distinct from Dandelion's yellow. Slices 2 and 3 (both
playtest rounds) are now fully Dave-verified — no outstanding items on
either.

## Slice 4: Patchy, scalable meadow — implementation-ready

**Goal:** give the meadow genuinely good and bad areas (the brief's own
fixed decision, not yet true today — species cluster with themselves
but land their first cluster anywhere with equal odds), and establish
whether the existing per-flower `_process` cost can take a higher
`flower_count` before it needs to change, rather than guessing.

**What's already there, checked against the live repo (22 Aug):**
`_seed_flower` (`world_building.gd:146`) already clusters a species
around its own past cluster centres (`cluster_radius`/`cluster_chance`,
up to `MAX_CLUSTERS_PER_SPECIES` = 22 remembered anchors per species)
and already reads `flower_lifespan_days`/`flower_regrow_seconds` to
keep the meadow topped up as flowers age out (`main.gd:694-699`). The
gap is that a *new* cluster anchor, when one is needed, comes from
`_random_field_point()` — uniform over the whole
`FLOWER_FIELD_HALF_SIZE` rectangle regardless of species — so every
species is equally likely to start clustering anywhere. `microhabitat`
(added in Slice 3, `flower_species.gd`) is a plain string on each
species, not read anywhere yet. Flower recharge/ageing already runs
every frame regardless of on-screen visibility, correctly, per
`.claude/rules/simulation.md` — that part must not change; the only
open question is whether it's *cheap enough* at a higher flower count,
which is a profiling question, not an assumption (rule 3).

**Tasks**

1. **Record the still-owed Slice 0 perf baseline, properly this time —
   at today's `flower_count` (500) and at two staged increases (750,
   1000).** Use `perf.gd`'s "flowers" section (already instrumented via
   `Perf.begin("flowers")`/`Perf.end("flowers")` in `flower.gd:161-202`)
   at each of the three counts, same colony size (~29 bees) as prior
   performance work, via the "fps" star's top-8 breakdown. This is a
   number-recording task, no code change other than temporarily editing
   `GameConfig.flower_count` for the two higher runs and reverting it
   after. **Do this before task 3** — per `.claude/rules/performance.md`
   and rule 3 in `CLAUDE.md`, lazy recharge updates are only worth
   building if this shows "flowers" becoming a real chunk of frame time
   as the count rises, not because it seems like it should.
2. **Add microhabitat zones and bias new cluster anchors toward the
   matching one.** In `world_building.gd`, generate a small fixed set
   of zones once per run (seeded, so reproducible per the Slice 0 work)
   — soft circles scattered across `FLOWER_FIELD_HALF_SIZE`, one or two
   per microhabitat string already on the species table (grassland,
   cultivated bed, wood edge, arable margin, hedgerow thicket, open
   ground), radius large enough to feel like a region rather than a
   pinpoint (e.g. 300-450px against a 2700x1980 field). Store as
   `Dictionary[String, Array[Vector2]]` (microhabitat name -> zone
   centres + radius), built once in `_build_meadow()` before the seeding
   loop. Change `_seed_flower()`'s "no cluster yet" branch only: instead
   of always calling `_random_field_point()` for a fresh anchor, roll a
   weighted choice — most of the time (e.g. 75%) pick a point inside a
   zone matching that species' `microhabitat` (with the existing
   `_random_field_point` retry logic for hive-distance/obstacle
   clearance still applied inside the zone's circle), the rest of the
   time fall back to `_random_field_point()` unchanged. This keeps
   "scatter is genuinely random" (the fixed decision) true within a
   zone while making zones the real explanation for where a species'
   clusters tend to start. Existing clusters (`main.cluster_centers`)
   are untouched by this — only the *first* anchor per species-cluster
   lineage changes.
3. **Only if task 1 shows a real cost at the higher counts: make flower
   recharge lazy.** Today's `_process` recomputes `nectar_amount`/
   `pollen_amount` every frame for every flower whether or not any bee
   is about to check it. If profiling shows this matters, replace the
   per-frame accumulation with an on-demand computation: store
   `_last_update_time` and compute `nectar_amount`/`pollen_amount` from
   elapsed simulated time capped at the resource's capacity, evaluated
   whenever something actually reads the flower's current amount
   (`collect()`, the presentation throttle's fade/label update, or a
   bee's flower-choice check) rather than every frame regardless of
   whether anyone looked. This must produce numerically identical
   results to today's accumulation (same rate, same cap, same season
   gating) — it's a caching change, not a balance change, so
   `balance_tests.py` should need no edits. Skip this task entirely if
   task 1's numbers don't justify it; leave a note here either way.
4. **Re-run the Slice 0 multi-seed on/off comparison at the new
   `flower_count` staging** (whatever value task 1/3 settle on as the
   new default, if any change was warranted) to confirm flower-visit
   and death numbers still land in a sane range, not a fresh full
   balance pass — flag anything that looks like a regression rather
   than fixing it inline.

**Deliverable:** a results note appended below this section (matching
Slices 0-3's pattern) with the three perf numbers, whichever of tasks 2
and 3 were built, and the re-run comparison. If task 3 is skipped, say
so and why, so a future session doesn't re-ask the same profiling
question from scratch.

**Checks:** `source_checks.py`, `balance_tests.py`, a `mcp__godot__run_project`
boot if available, a `tools/run_scenario.py --full` run to catch anything
obviously broken in seeding, and Dave's hands-on check — this slice is
visible (zones should read as a species being more common in some parts
of the meadow than others) so it needs an actual playtest, not just
numbers.

### Slice 4 results so far (22 Aug 2026)

**Task 1: done, Dave's own `perf.gd` "fps" star reading (22 Aug 2026).**

| flower_count | actual flower nodes | flower work mean / p95 | whole-frame mean / p95 | headless throughput |
|---|---|---|---|---|
| 500 | 592 | 8.33 / 11.42 ms | 27.32 / 36.70 ms | 36.6 fps |
| 750 | 904 | 11.77 / 15.52 ms | 32.57 / 42.15 ms | 30.7 fps |
| 1000 | 1,210 | 14.08 / 17.54 ms | 34.89 / 42.39 ms | 28.7 fps |

Compared with 500: 750 is flower cost +41%, whole-frame mean +19%; 1000
is flower cost +69%, whole-frame mean +28%. At 1000, flower processing
alone exceeds the 16.7 ms 60-fps budget at p95. Method: Godot 4.7.1,
headless fixed 60 Hz, seed 4242, 18 bees, Perf instrumentation, 240-frame
warmup, 600 measured frames. Actual node counts exceed the setting
because bushy species (Bramble) create multiple flower units per
placement. Excludes visible-build rendering, fog and camera costs.

This clears the plan's own gate — task 1 shows a real, rising cost, so
task 3 is justified rather than speculative. But the `Perf.begin("flowers")`/
`Perf.end("flowers")` span in `flower.gd:161-202` wraps the *entire*
`_process` body, not just the recharge accumulation: `CrabSpider.update()`
(if `predators_on`), the age/lifespan check, and the presentation
throttle (labels/fade/crab marker, gated by `is_visible_in_tree()` and
`PRESENTATION_PER_SECOND`) are all inside the same measured span. Lazy
recharge only changes the recharge lines
(`flower.gd:166-169`) — it isn't yet established how much of the 8-14ms
is recharge specifically versus the rest of that span, so task 3 below
is scoped narrowly (recharge only) and flags this as an open question
rather than assuming recharge is the whole cost.

**A genuine blocker on task 3 as specced, surfaced during implementation
planning:** `season_strength()` is time-varying, not constant — a smooth
`sin(through * PI)` arch across a species' season window
(`flower.gd:225-234`), re-evaluated fresh every frame from `Session.sim_time`.
Today's per-frame accumulation is an Euler integration of that curve:
`nectar_amount += rate * strength(t) * delta`, sampled once per frame.
A lazy version computed only when something reads `nectar_amount` would
need to integrate `rate * strength(t)` analytically over the elapsed gap
since the last read to be "numerically identical" as the task requires
— straightforward in the mid-season plateau (strength ~constant) but a
real analytical integral at the ramp edges, and wrong by a growing error
if approximated with a single instantaneous sample multiplied by elapsed
time (a bee that hasn't checked a flower in 40 seconds would get a wildly
wrong catch-up amount right as a season boundary crosses). This wasn't
visible until reading `season_strength()` alongside the recharge lines —
worth Dave's steer before building rather than choosing an approximation
unilaterally. See `NEXTSTEPS.md` for the options put to him.

**Task 2: built.** `main.gd` gained `microhabitat_zones: Dictionary`
(microhabitat name -> `Array[{"centre": Vector2, "radius": float}]`),
next to `cluster_centers`. `world_building.gd::_build_microhabitat_zones()`
runs once per run from `_build_meadow()`, before the seeding loop and
right after `_scatter_obstacles()` (so it's seeded off the run's own
`seed()` call, same reproducibility Slice 0 established) — one or two
zones per distinct `microhabitat` string already on the species table,
centre from the existing `_random_field_point()`, radius 300-450px
against the 2700x1980 field. `_seed_flower()`'s "no cluster yet" branch
now rolls a weighted choice (75%, `MICROHABITAT_ZONE_CHANCE`): if that
species' microhabitat has a zone, pick a point inside it
(`_random_point_in_zone`, uniform-in-circle, same hive-distance retry as
`_random_field_point`); otherwise (25%, or no zone exists for that
habitat) fall back to `_random_field_point()` unchanged. Only the first
anchor per species-cluster lineage is affected — `main.cluster_centers`
and the existing per-species cluster radius/chance logic are untouched,
so scatter within a zone is still genuinely random, per the fixed
decision.

**Task 3: built, scoped to recharge only (22 Aug 2026).** Task 1's
numbers cleared the gate. Before building, reading `season_strength()`
surfaced a real snag not visible from the task description alone: it's
a time-varying `sin` arch across a species' season window, so a lazily-computed
version can't be byte-identical to the old per-frame Euler accumulation
without an analytical integral. Put to Dave as a choice between an
approximate lazy version, an exact-integral lazy version, a
cheaper-but-still-per-frame version (cache `season_strength()` once per
species per frame instead of per flower), or holding off; his steer was
"whichever of the approximate-lazy or cached-per-frame options is
cheaper to process" — approximate lazy wins on that test, since it skips
recharge work entirely for the (large) majority of flowers nobody is
reading from on a given frame, where the cached version still pays a
multiply-add-min for every flower every frame regardless of who's
looking.

**Built:** `flower.gd`'s `nectar_amount`/`pollen_amount` became computed
properties (`_nectar_amount`/`_pollen_amount` backing fields,
`_last_recharge_update` sim-time stamp). Both getter and setter call a
new `_sync_recharge()` first, which advances the backing fields by
`rate * season_strength() * elapsed_since_last_read` (capped at
capacity) using the *instantaneous* strength at read-time rather than
integrating across the gap — the one deliberate deviation from "numerically
identical", approved by Dave's steer above. Drift is bounded and
self-correcting (capacity is still a hard cap either way) and only
shows up while a season window is ramping in/out; it's silent everywhere
a species is mid-season, which is most of the year for most species.
`_process()` no longer accumulates recharge at all — the per-frame work
left is ageing/lifespan (unaffected, still runs for every flower every
frame, out of this task's scope) and the existing visibility-gated
presentation throttle, which now computes `season_strength()` itself
only when it actually redraws a visible flower's fade. Every existing
external read (`hud.gd`, `rival_hive.gd`, `save_game.gd`, `saving.gd`)
goes through the same properties unchanged, since they were already
plain field access on `flower.nectar_amount`/`pollen_amount`. Save/load
order was checked: `saving.gd::_restore()` sets `Session.sim_time`
before `_restore_flowers()` runs, so a restored flower's first sync
uses the correct sim time rather than a stale zero.

**Checker gap found and fixed, not the game.** GDScript 4's inline
property syntax (`var x: T:\n  get:\n  set(value):`) put `set(value):`
in the exact position `tests/source_checks.py`'s regex-based
`check_calls` treats as a function call — a false positive, the same
kind of gap `.claude/rules/gdscript.md` already documents for `:=`.
Fixed by adding `get`/`set` to the checker's `NOT_CALLS` keyword list
(with a comment explaining why), not by avoiding the syntax.

**Checks:** `source_checks.py` (66/66) and `balance_tests.py` (15/15,
unaffected — nothing in that suite depends on recharge accumulation
timing) both pass. A `mcp__godot__run_project` boot showed only the same
pre-existing warnings as every prior slice, nothing new. A
`tools/run_scenario.py --full` run against `c2_no_jelly_cell_test.json`
gave 62 flower visits / 34 unique flowers — identical to the same
scenario's result recorded after task 2, confirming lazy recharge hasn't
changed forage outcomes at the flower-visit level.

**Not verified: whether this actually moves the perf numbers.**
`run_scenario.py` has no headless path to `perf.gd`'s "flowers" timing —
task 1's numbers were Dave's own hands-on "fps" star reading, and a fair
before/after needs the same method. **Still needs Dave's hands-on
check**: repeat the 500/750/1000 `flower_count` readings from task 1
with the same method, to see how much (if any) of the flower-work mean/p95
improved.

**Task 4: re-run, seed 12345 only** (the full 5-seed re-run is Slice 0's
job to repeat, not owed again here — this was a sanity check, not a
fresh balance pass):

| side | flower_visits | unique_flowers | total_deaths | recruitment_matches | foragers_settled |
|---|---|---|---|---|---|
| on (before, Slice 0) | 225 | -- | 21 | 7 | 14 |
| on (after zones) | 194 | 163 | 20 | 10 | 14 |
| off (before, Slice 0) | 392 | -- | 22 | 0 | 0 |
| off (after zones) | 424 | 194 | 21 | 0 | 0 |

Both sides stay in the same ballpark as Slice 0's numbers -- no death
spike, no recruitment collapse, `off` actually up slightly. `on`'s
flower_visits dropped by about 14%, plausibly because a species now
frequently travelling to its own zone means less spread-out incidental
proximity to other species' flowers along the way; worth Dave watching
in a hands-on playtest rather than treating as a regression to chase
now, per the task's own instruction to flag rather than fix inline.

**Checks:** `source_checks.py` (66/66) and `balance_tests.py` (15/15)
both pass. A `mcp__godot__run_project` boot completed with only the same
pre-existing warnings as every prior slice (`_flower_visit_started_at`
etc, none new). A `tools/run_scenario.py --full` run against
`c2_no_jelly_cell_test.json` completed cleanly (62 visits, 34 unique).
**Still needs Dave's hands-on check**: open a run and confirm a species
now reads as more common in one part of the meadow than another, per
its `microhabitat` (e.g. Bramble's "hedgerow thicket" clustering
visibly apart from Dandelion's "open ground").

**Task 4 full 5-seed re-run (23 Aug 2026), now owed and done.** One run
per seed per side (not 5 repeats — Dave's small-batch steer from Slice 0,
[[feedback_headless_run_batches]]), same seeds and scenario files as
Slice 0, run *after* both task 2 (zones) and task 3 (lazy recharge),
via a ~25-line driver script (`run_once`/`analyze` imported directly,
one summary line per run printed) rather than the CLI's full JSON dump:

| side | seed | flower_visits | unique_flowers | total_deaths | recruitment_matches | foragers_settled |
|---|---|---|---|---|---|---|
| on | 12345 | 255 | 180 | 20 | 5 | 14 |
| on | 7 | 226 | 171 | 21 | 2 | 11 |
| on | 2026 | 256 | 200 | 20 | 4 | 12 |
| on | 90210 | 229 | 189 | 20 | 2 | 12 |
| on | 555 | 253 | 168 | 20 | 2 | 12 |
| off | 12345 | 349 | 204 | 22 | 0 | 0 |
| off | 7 | 392 | 193 | 22 | 0 | 0 |
| off | 2026 | 362 | 214 | 21 | 0 | 0 |
| off | 90210 | 388 | 214 | 21 | 0 | 0 |
| off | 555 | 359 | 196 | 21 | 0 | 0 |

Mean flower_visits: `on` ≈244 (was ≈215 in Slice 0's pre-zones baseline),
`off` ≈370 (was ≈375 in Slice 0) — the on/off gap is intact and, if
anything, `on` reads slightly *higher* than before, not lower. This
corrects the single-seed sanity check above: seed 12345 alone (194,
zones-only, no lazy recharge yet) looked like a 14% drop, but across all
5 seeds with both task 2 and task 3 in, there's no drop to explain.
Deaths stay flat (20-22 both sides, matching Slice 0). One real shift
worth flagging, not fixing: mean `recruitment_matches` on `on` fell from
≈6.2 (Slice 0) to ≈3.0 here — plausibly the same zone-clustering effect
(bees now often already at the right patch, less need for a recruitment
dance to redirect a nestmate) rather than a bug, but it's a bigger
change than the flower-visits numbers and worth Dave's eye in a
hands-on playtest. `foragers_settled` on `on` is essentially unchanged
(≈13.4 to ≈12.2).

**Checks:** all 10 runs exited 0, each produced a summary line (no
`FAILED` rows). `source_checks.py`/`balance_tests.py` unaffected (no
code changed this task, re-run only).

**Both remaining hands-on items Dave-confirmed (23 Aug 2026):** the
task 2 microhabitat-clustering visual check, and the task 1/3
500/750/1000 `perf.gd` flower-work re-read to see how much lazy recharge
helped -- no specific numbers recorded against the latter, just Dave's
confirmation it holds up. Slice 4 is now fully closed.

## Slice 5: Local search — implementation-ready

**What's already there, checked against the live repo (23 Aug):**
`seek_flower` (`bee_foraging.gd:69`) and `nearest_flower` (`bee_foraging.gd:108`)
make an instant, single-frame, omniscient-within-radius decision — one
spatial-grid query centred on the bee's *current position*, radius
`GameConfig.forage_search_radius` (900px), and if that finds nothing the
fallback is a full unbounded scan of every flower in the meadow. There is
no search *behaviour* today: a bee either already knows where to go this
frame, or she's checked literally everything that exists. Slice 1's
results flagged the gap this leaves — a scored trip's search+flight time
and handling time only account for ~47s of a 106s average trip, and the
unexplained ~59s residual (flight between flowers on a multi-flower trip,
plus whatever "not finding one immediately" actually costs) has no
behaviour behind it to decompose further. This slice gives it one.

**Design decisions (Dave, 23 Aug):**
- **Real spiral flight**, not an invisible widened-query change. A bee
  who can't see a flower flies a visible expanding loop until she spots
  one or gives up, rather than the decision staying a single frame with
  a bigger number plugged in.
- **A new, genuinely separate search anchor** (`bee.local_search_anchor`),
  not a reuse of `forage_start_point`. The anchor drifts to follow where
  she's actually finding flowers; `forage_start_point` stays the fixed,
  manually/scouting/recruitment-authoritative pin the existing fixed
  decision already protects — resetting the anchor back to it at every
  point that already resets `forage_start_point` is what keeps "manual
  stays authoritative" true even though the anchor itself can drift
  in between.
- **`forage_perception_radius` gets simulated, not guessed** — a new,
  smaller number than today's 900px, which is repurposed rather than
  replaced (see task 3).

**Tasks**

1. **Generalise `nearest_flower` to take a radius parameter**, defaulting
   call sites to today's `GameConfig.forage_search_radius` so this task
   alone changes nothing observable. Pure refactor, cheap to verify in
   isolation before anything else in this slice touches behaviour.
2. **Add `local_search_anchor: Vector2` to `bee.gd`**, saved next to
   `forage_start_point` (`save_game.gd:243`, same pattern). Reset it to
   `forage_start_point` at every existing point that sets/clears
   `forage_start_point` itself: orientation flight (`take_orientation_flight`),
   scouting settling (`_score_trip`'s settle branch), a recruitment match
   or the entrance-timeout reset (`wait_at_entrance`), and a manual
   "Set start point" control if `input_selection.gd` has one — grep for
   `forage_start_point =` to find every site rather than trusting this
   list is exhaustive. In `start_collecting`, nudge the anchor toward the
   flower just committed to — `local_search_anchor = local_search_anchor.lerp(current_flower.position, GameConfig.local_search_drift_rate)`
   (new `GameConfig` constant, provisional value, simulated alongside the
   perception radius in task 4). Still no visible behaviour change this
   task — the anchor is tracked and drifting but nothing reads it yet.
3. **Add the `SEARCHING` state and the spiral itself.** `SEARCHING`
   appended to the end of `BeeEnums.State` (never inserted mid-list — the
   enum is saved as a plain int, per its own header comment). Rewrite
   `seek_flower`'s empty-handed branch: today's fallback to a full
   meadow scan only fires once the spiral gives up, not immediately.
   - `nearest_flower(bee, true/false, GameConfig.forage_perception_radius)`
     centred on current position, exactly as today just with the smaller
     radius (task 1's new parameter).
   - Nothing found → `State.SEARCHING`, seeded from `local_search_anchor`:
     an Archimedean spiral (`radius = forage_perception_radius * (1 + turns * step)`,
     angle advancing each waypoint reached) walked via
     `BeeMovement.move_towards` exactly like any other move — obstacle
     avoidance and indoor/outdoor handling come for free. Each frame in
     `SEARCHING`, re-run the same bounded `nearest_flower` query from
     current position; a hit transitions straight to `TO_FLOWER`, same
     as `seek_flower` does today.
   - Cap: once the spiral radius exceeds `GameConfig.forage_search_radius`
     (900px, repurposed from "how far the instant query looked" to "how
     far the expanding loop is allowed to travel before giving up"),
     fall back to today's relaxed full-scan (`nearest_flower(bee, false)`,
     unbounded) once; if that's also empty, go home (`State.TO_HIVE`),
     matching today's genuinely-empty behaviour exactly.
   - New `Perf.begin("bee_search")`/`Perf.end("bee_search")` span
     covering the whole `SEARCHING` per-frame cost, per
     `.claude/rules/performance.md` — this is a new hot-path state that
     can now run for many consecutive frames per bee where the old
     decision was one frame, and needs its own measurement rather than
     an assumption either way.
4. **Simulate `forage_perception_radius` and `local_search_drift_rate`
   before locking them** (`CLAUDE.md` rule 4) — a throwaway Python model
   or a `tools/run_scenario.py` multi-seed sweep (Slice 0's five seeds)
   comparing candidate perception radii against flower-visits/trip-time
   outcomes, plus a `perf.gd` "bee_search" reading at the existing ~29-bee
   baseline to check the new per-frame state doesn't reintroduce the
   Slice 4-style cost jump. Record the numbers and the chosen values
   here before task 5.
5. **Re-run Slice 0's multi-seed on/off comparison** at the locked values,
   same five seeds, same "flag don't fix inline" instruction as every
   prior slice's task 4/5.

**Deliverable:** a results note appended below this section, matching
Slices 0/1/4's pattern — the perception-radius/drift-rate numbers chosen
and why, the perf reading, and the re-run comparison. Visibly: a
foraging bee who can't see a flower should now fly a widening loop
rather than beelining the instant she leaves the hive.

**Checks:** `source_checks.py`, `balance_tests.py`, a
`mcp__godot__run_project` boot if available, a `tools/run_scenario.py --full`
run, and Dave's hands-on check — this is a visible behaviour change
(watch a bee search) so it needs an actual playtest, not just numbers.
Update `FUNCTION_MAP.md` only if `bee.gd` is touched (it will be, for
the new field and state).

### Slice 5 results (23 Aug 2026)

**Task 1: built.** `nearest_flower` gained a `radius: float` parameter
(no default), and both `seek_flower` call sites and the status-hint call
in `bee.gd` (found by grepping every `nearest_flower(` call site, not
just the two in `seek_flower` — a third existed at `bee.gd`'s
`idle_reason()`) now pass `GameConfig.forage_search_radius` explicitly.
Pure refactor: `source_checks.py`/`balance_tests.py` both passed
unchanged before task 3 touched any behaviour.

**Task 2: built.** `bee.local_search_anchor` added next to
`forage_start_point`, reset alongside it at every site that sets or
clears `forage_start_point` (`take_orientation_flight`, scouting's settle
branch, a recruitment match, the entrance-timeout reset, and
`set_forage_start_point` for the manual control) — found by grepping
`forage_start_point =` per the task's own instruction. Drifts toward a
committed flower in `start_collecting` via
`GameConfig.local_search_drift_rate`; a bee with no start point yet
(anchor still `INF`) has its first commit plant the anchor there instead
of lerping from `INF`. Saved next to `forage_start_point` in
`save_game.gd`/`saving.gd`, with an old-save fallback to the just-restored
`forage_start_point` rather than `INF`, so a pre-Slice-5 save doesn't
lose it on first load. No behaviour change — nothing read the anchor yet.

**Task 3: built, with two real bugs found and fixed during the same
scenario run that verified it.** `State.SEARCHING` appended to
`bee_enums.gd`. `nearest_flower` gained an `allow_full_scan: bool = true`
parameter — needed because the existing "fall back to a full unbounded
scan whenever the grid finds nothing" behaviour was unconditional inside
`nearest_flower` itself, at every call, regardless of the `radius`
passed in; `seek_flower`/`search_for_flower` now call it via a shared
`_perceive_flower` helper with `allow_full_scan: false`, so a bounded,
in-sight-only check actually stays bounded. `seek_flower` now commits
immediately to anything within `forage_perception_radius`, and otherwise
seeds `State.SEARCHING` from `local_search_anchor` (falling back to the
bee's own position if she's never had a start point). `search_for_flower`
re-runs the same bounded check every frame, walks an Archimedean spiral
(`_spiral_point`) via ordinary `BeeMovement.move_towards`, and once the
spiral's radius exceeds `forage_search_radius` falls back to the old
relaxed full scan once before giving up and heading home — matching
`seek_flower`'s pre-Slice-5 genuinely-empty behaviour exactly. `SEARCHING`
added to `_is_busy()`'s not-busy list (same as `SEEK_FLOWER` — nothing's
committed yet), `bee_survival.gd::is_flying()` (she's flying under her own
power), and `current_goal()` (`search_waypoint`, so the stall watchdog
tracks her properly) — found by grepping every other place `SEEK_FLOWER`/
`TO_FLOWER` were already handled outside `bee.gd`/`bee_foraging.gd`,
rather than assuming the new state only needed touching in the state
dispatch. New `Perf.begin("bee_search")`/`Perf.end("bee_search")` span in
`bee.gd`'s dispatch, per the task's own instruction.

A first scenario run (`foraging_features_on_seed12345_test.json`, 60
days) surfaced two genuine bugs, not tuning:
- **The stall watchdog never reset its baseline when SEARCHING advanced
  to a new (further) waypoint.** `watch_for_stalls` only resets
  `stall_best_distance`/`stall_timer` when distance-to-goal *improves*;
  advancing to a fresh spiral waypoint makes the goal jump further away
  by design, which the watchdog read as "stopped progressing" and fired
  almost immediately on every leg. `stall_recoveries` went from a
  baseline of 3 (pre-Slice-5, same scenario/seed) to 500. Fixed by
  calling `bee._reset_stall_watch()` whenever `search_for_flower`
  advances the waypoint (now factored into a shared
  `advance_search_waypoint`, used by both the normal-arrival path and the
  stall-recovery path below).
- **An unclamped spiral point can land beyond the meadow's hard world
  boundary**, which is permanently unreachable to within `arrive_distance`
  and reads as a stall that never resolves. `_spiral_point` now clamps
  its result to `main.FLOWER_FIELD_HALF_SIZE`, the same rectangle
  `_random_field_point()` already scatters within.
- Even after both fixes, `stall_recoveries` was still 73 (vs baseline 3),
  with the watchdog's own escape shove (`escape_nearest_obstacle`) doing
  nothing for `SEARCHING` specifically — `TO_FLOWER` rejects the flower
  and `MOVE_TO_POINT` resets to a default state after an escape shove, so
  the deadlock actually breaks, but `SEARCHING` had no equivalent and just
  re-aimed at the same unreachable waypoint forever. Session-log evidence
  (`diagnostic_log.gd`'s `stall_recovery` events, which record
  state/position/goal) showed one bee frozen at a bit-identical position
  and goal across a dozen consecutive stall checks. Fixed by calling the
  new `advance_search_waypoint` from `watch_for_stalls`'s `SEARCHING`
  branch too, so an escaped-but-still-unreachable waypoint is abandoned
  like any other, not retried forever. This brought `stall_recoveries` to
  56.
- One more contributing factor, not a bug but a design gap: `search_angle`
  always started at exactly `0.0` (due east of the anchor), so a bee whose
  anchor sat near an obstacle in that fixed direction hit the same wall on
  every single bout from that anchor — session logs showed several bees
  repeatedly stalling at bit-identical points across different bouts,
  seconds or minutes apart. Fixed by adding `bee.search_start_direction`,
  a fresh `randf() * TAU` offset per bout, kept separate from
  `search_angle` itself (which still starts at 0 and only measures
  progress through the spiral, so radius growth stays independent of
  which way the spiral happens to open). Brought `stall_recoveries` to 56
  with a much flatter per-bee distribution (max 7 on one bee, vs 12+
  before).

**Task 4: built.** Both new constants were provisional guesses pending
simulation; per CLAUDE.md rule 4, swept before locking rather than left
as guesses:
- `forage_perception_radius` — swept 150/250/400 on
  `foraging_features_on_seed12345_test.json`, cross-checked 250/400 on
  seed 7 (one run each, not 5 repeats, per the plan's established
  small-batch steer — see `[[feedback_headless_run_batches]]`). 400 beat
  both smaller candidates on `flower_visits` and
  `unique_flowers_visited` on both seeds, at a similar or lower
  `stall_recoveries` count than 250 — a tighter radius meant `SEARCHING`
  fired often enough to cost real throughput without covering
  meaningfully more ground. Locked at 400, up from the provisional 250.
- `local_search_drift_rate` — swept 0.15/0.3/0.5 at
  `forage_perception_radius` 400 on seed 12345 (one run each). 0.3 (the
  original provisional value) gave the best `flower_visits`/
  `unique_flowers_visited` of the three, so kept rather than changed on a
  single noisy run either way.
- The spiral's own shape constants (`forage_search_spiral_step`,
  `forage_search_angle_step`) aren't named in the task list for formal
  simulation, but needed real values during task 3's debugging regardless
  — locked at 1.0 and `TAU/6` (a ~13-waypoint, ~2-loop spiral before
  falling back), chosen and verified against the same scenario runs that
  found the stall-watchdog bugs above, documented on the fields
  themselves in `game_config.gd`.
- **Not done: the `perf.gd` "bee_search" hands-on reading** the task also
  asked for, at the existing ~29-bee baseline, to confirm the new
  per-frame `SEARCHING` state doesn't reintroduce a Slice-4-style cost
  jump. `run_scenario.py` has no headless path to `perf.gd` timing (same
  gap Slice 4's task 1 hit) — this is Dave's own hands-on reading to take,
  the same way Slice 4's baseline was.

**Task 5: built.** Full 5-seed on/off re-run at the locked values (one
run per seed per side, same seeds as every prior slice's re-run):

| side | seed | flower_visits | unique_flowers | total_deaths | recruitment_matches | foragers_settled | stall_recoveries |
|---|---|---|---|---|---|---|---|
| on | 12345 | 232 | 152 | 20 | 3 | 9 | 39 |
| on | 7 | 199 | 118 | 19 | 3 | 5 | 11 |
| on | 2026 | 228 | 151 | 20 | 2 | 10 | 7 |
| on | 90210 | 226 | 148 | 19 | 5 | 9 | 14 |
| on | 555 | 288 | 145 | 20 | 4 | 10 | 19 |
| off | 12345 | 322 | 140 | 21 | 0 | 0 | 23 |
| off | 7 | 440 | 213 | 22 | 0 | 0 | 2 |
| off | 2026 | 417 | 194 | 21 | 0 | 0 | 1 |
| off | 90210 | 582 | 197 | 22 | 0 | 0 | 0 |
| off | 555 | 401 | 193 | 21 | 0 | 0 | 2 |

Mean flower_visits: `on` ≈235 (was ≈244 in Slice 4's post-zones baseline
— a real but modest ~4% drop, the expected cost of `SEARCHING` actually
taking simulated time now instead of an instant lookup). `off` ≈432 (was
≈370 in Slice 4) — up, not down, despite `off` having no automation to
offset any new search cost. `SEARCHING` is unconditional (not gated
behind `scouting_on`/`auto_recruitment_on`, matching how Slice 4's zones
and lazy recharge also shipped without a toggle despite the brief's
general "every new realism feature is toggleable" steer), so `off`-side
bees run it too; the rise most plausibly comes from the old unconditional
full-scan fallback sometimes handing a bee the single globally-nearest
flower in the whole meadow (however far that actually was), where the
spiral now more often finds *a* usable flower nearby before it ever
widens that far. Deaths flat both sides (19-22, matching every prior
slice's range). `stall_recoveries` sit in a modest, unevenly-distributed
range (0-39) consistent with the watchdog firing on genuine occasional
obstacle encounters rather than a systemic problem — nothing here reads
as a regression to flag.

**Checks:** `source_checks.py` (66/66) and `balance_tests.py` (15/15)
passed after every task. No `mcp__godot__*` tools were connected this
session, so no Godot boot — **still needs Dave's hands-on check**: watch
a foraging bee fly a widening loop when nothing's immediately visible
(most noticeable with a low-density or heavily-preferred-species
scenario), confirm it reads as searching rather than erratic, and take
the owed `perf.gd` "bee_search" reading at ~29 bees. `FUNCTION_MAP.md`
regenerated (`bee.gd` was touched, for the new fields/state) and verified
with `--check`.

## Next physical step

Slice 5 is built and simulated; only Dave's hands-on check and the
`perf.gd` "bee_search" reading remain (see Slice 5 results above).
Slices 6 onward (probabilistic choice, handling experience, finite
pollen, proximity recruitment) stay scope-indexed only, not yet refined.
Dave still separately owes the hand-recorded `perf.gd` baseline Slice
4's task 1 asked for — already folded into that slice rather than
treated as a separate leftover from Slice 0.
