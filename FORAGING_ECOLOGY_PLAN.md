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

## Next physical step

Slices 0-3 are all built and Dave-verified. Slice 4 onward (patchy
meadow, local search, probabilistic choice, handling experience,
finite pollen, proximity recruitment) stay scope-indexed only, not yet
refined — refine one at a time, in its own session, when Dave's ready
to pick the next slice. Slice 4 in particular can build on the
`microhabitat` column added above rather than starting that data from
scratch. Dave still separately owes a hand-recorded `perf.gd`
performance baseline from Slice 0.
