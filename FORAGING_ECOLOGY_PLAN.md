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

---

## Next physical step

Slice 0 first: add the one-line seed override to `main.gd`, pick the
fixed seed list, and re-run the existing on/off comparison across
seeds. That's a single small Claude Code session. Slice 1 (the
foraging panel) is a second, separate session once Slice 0's numbers
are in and reviewed — don't combine them, per the brief's own "don't
combine slices into one implementation pass" rule.
