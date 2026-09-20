# Technical audit — current contracts

<!-- CONTEXT: plan | LAYER: reference | LOAD: only for measured hot-path or restore work -->
Status: reference | Owner: Dave / Claude Code | Next: PERF-2 (if admitted) -- measure `find_food_cell` with a pinned hungry indoor population | Dependency: none -- A2, A3 and B2 have shipped | Verified: 2026-09-20

The Aug 2026 audit bundles are complete or deliberately measurement-gated. The
full implementation record is archived at
`plans/archive/AUDIT_PLAN_AUG_2026.md`; it is not a session starting point.

## Contracts retained from the audit

- Profile before changing a hot path. Keep the baseline, population and
  measurement window comparable; a lower FPS number alone is not causal
  evidence. See `docs/performance.md` and `docs/PERFORMANCE_BASELINE.md`.
- Restore is all-or-nothing. Do not query deferred-freed groups while a restore
  is rebuilding; follow `.claude/rules/saving.md`.
- `GameConfig` writes remain allowlisted and Challenge-local overrides stay
  on the affected instance.
- Fog changes require identical-tile checks plus a visible moving-bee check.
  The current row-span relight contract is in `docs/PERFORMANCE_BASELINE.md`.

## Deferred work

Fog storage compression, BitMap experiments and new masking approaches are not
planned work. Reopen one only after a fresh comparable profile identifies a
specific bottleneck and the smallest path is written as a new, focused slice.

## Feature availability is split across five owners (26 Aug 2026 review)

Whether a feature is available today is decided in five places: `GameConfig`,
`prerequisites.gd`, level flags, `stage_gate.gd`, and Challenge/UI filtering.
Roles additionally mirror their persisted integer IDs across `roles.gd` and
`bee_enums.gd` -- that one is deliberate and stays.

**Consequence:** every new resource, order or gated mechanic has to restate
the same rule in several of those places, and a rule added to only four of
the five is invisible until a player finds it.

**Consolidating it is no longer this file's work.** Until 11 Sep 2026 this
section prescribed two slices of its own -- an availability query, then a
resource catalogue -- and said neither was startable without Dave's call.
`plans/design/architecture-review.md` has since specified exactly that work,
with the ownership decisions taken: B1 is the cell-content catalogue, C1 the
conditions evaluator that replaces the three condition vocabularies, and F2s
the declarative gate table that replaces the bespoke stage-gated UI setters.
Read those slices. Do not open a second version of them from here.


## Forager-history save design (28 Aug 2026)

`DESIGN_BACKLOG.md`'s deferred "forager-history persistence" item, resolved
narrowly: only the recruitment collection-rate history
(`avg_collection_rate`, `grace_rate_sum`, `trips_scored` on `bee.gd`) is now
save-persisted — see `save_game.gd::_bees_data` and `saving.gd`'s bee restore
block. This is the only part of a forager's "history" that (a) is genuinely
learned state rather than in-progress scratch and (b) silently affected
gameplay on every reload, resetting every settled forager back to a brand-new
colony's recruitment grace period.

Deliberately additive, no `FORMAT_VERSION` bump: the three fields follow the
existing `known_patches`/`species_experience`/`species_confidence` pattern
(`.get()` with a default in `saving.gd`, no entry in `save_migrations.gd`).
An older save missing the keys defaults to `0.0`/`0.0`/`0`, which is exactly
a freshly spawned bee's own starting value — a genuinely harmless default,
not a lossy one, so `save_migrations.gd`'s existing "safe additive fields"
carve-out applies and no migration step or fixture was added.

Scouting-bout state (`is_scouting`, `scout_bout`, `scout_species`,
`scout_tried_species`, `scout_best_species`, `scout_best_rate`,
`scout_current_start_point`, `scout_best_start_point`) and the dance/
recruit-partner links stay intentionally unsaved, unchanged from before this
slice: they are mid-action scratch, same category as `search_angle`/
`move_target`, and a bee saved mid-scout or mid-dance already resumes
harmlessly as a plain forager on load. `settled_rate_logged` also stays
unsaved — it only gates a one-time diagnostic log line, so a reload past the
grace window re-logs it once more, which is a harmless duplicate, not a
gameplay effect.

No further forager-history work is planned; this closes the backlog item.

## Measurement-gated hot-path candidates (1 Sep 2026 review)

Not to be confused with `plans/design/architecture-review.md`, which is the
10 Sep 2026 review and holds scheduled slices. These two are recorded here,
not scheduled, and deliberately subject to the "profile before
changing a hot path" contract above. Each names the instrumentation step that
would turn it from a plausible improvement into a measured one. Neither is a
reason to open a slice on its own.

### A. `hive.gd`'s `find_*` functions bypass the content index that already exists

**Not covered by the architecture review, deliberately.** That review's A3
caches the `total()` family and B2 builds the bucket dictionary from the
catalogue; neither touches the `find_*` functions below.

**Precondition met, 17 Sep 2026.** A3 and B2 have both shipped, so the
instrumentation step below is now the next thing to do here rather than
something waiting on another slice. It is still a measurement, not a fix: it
is admissible as a queue item only in the shape "add the Perf section, run
the baseline, report the numbers, and specify the change only if the section
is non-trivial".

`_content_index()` maintains epoch-invalidated buckets keyed
`"" / nectar / pollen / honey / jelly / brood / corpse / unbuilt / ripe_honey`,
and `find_cell_with`, `find_brood_cell`, `find_cell_needing_cleaning` and
`has_gyne_brood` read them. These do not:

| Function | Current | Bucket that already exists |
| --- | --- | --- |
| `find_food_cell` | **two** full passes over `cells` | `ripe_honey`, then `nectar` |
| `find_unfinished_cell` | full pass | `unbuilt` |
| `find_cell_needing_fanning` | full pass, no `is_instance_valid` guard | `honey` + `needs_fanning()` |
| `find_cell_for` | full pass | `""` + `resource_type` |
| `find_cell_needing_eviction` | full pass | the four stored-resource buckets |
| `find_empty_cell` | full pass filtered to nursery cells | none — would need a new bucket |

`find_food_cell` is the one worth checking first: `BeeSurvival.should_go_and_eat`
calls it on every think tick (8 Hz) for every hungry bee inside the hive, so
its cost scales as *hungry bees x 2 x cells* — exactly the situation the game
is about.

Equivalence was checked for the top three: `space_for()` returns 0 for an
unbuilt cell, so no unbuilt cell can hold nectar or honey, and buckets are
built in `cells` order, so iteration order and therefore the chosen cell are
unchanged. `find_cell_for` and `find_empty_cell` are **not** in that set — the
`best_empty`/`almost_full`/designation preference is a single-pass ordering
that a two-bucket walk would subtly change; leave them alone.

**Instrumentation needed first.** The hive's index *rebuild* is instrumented
(`hive_index_rebuild`); its *queries* are not, so today their cost is only
visible folded into `bee_state_nurse`/`bee_state_forager`. That measurement is
now a queued slice:

PERF-1 shipped 2026-09-20; its specification is `plans/archive/PERF-1_2026-09-20.md`.

### B. The 1 Hz colony refresh walks the same sets more than once

**Mostly owned elsewhere now.** `plans/design/architecture-review.md`'s A2
makes `ColonyDiagnostics.compute` take role counts as a parameter instead of
walking the bee group itself, which removes the largest duplicate in this call
tree. A2 shipped, so what follows is the residue it left behind: roughly a
dozen lines, covered by the existing `signals` Perf section, and best carried
by the next slice that opens `year_winter.gd` rather than queued on its
own.

In one tick of `year_winter.gd::_refresh_signals`,
`get_nodes_in_group("bees")` is called there and again in `_winter_forecast`
(reached via `_refresh_panels` -> `_refresh_winter`); `season.gd`'s own 1 Hz
tick queries it once or twice more. `cells_holding("")` is walked in
`_refresh_signals` (`free_cells`) and again in `_refresh_panels`
(`free_cells`), and `cells_holding("brood")` likewise, recomputing
`hungry_brood` both times.

The smallest version is not a new structure: pass the already-fetched `bees`
array (or just its size) into `_winter_forecast`, and compute
`free_cells`/`hungry_brood` once in `_refresh_signals` and hand them to
`_refresh_panels`. Roughly a dozen lines. The `signals` Perf section already
covers all of it, so the before/after comparison needs no new instrumentation.

Explicitly **not** proposed: a colony-snapshot object, a push-based signal, or
an epoch cache over the bee group. `main._role_counts()` already demonstrates
the epoch-cache pattern if a larger version is ever wanted, and `hive.gd`'s
`invalidate_index()` comment records why polling an epoch was chosen over a
Godot signal in the first place.


### Not a case for ECS

Checked deliberately, since 153 fields on `bee.gd` look component-shaped.
There are 26 `get_nodes_in_group("bees")` sites, but almost all are 1 Hz or
event-driven; the only per-frame one is `fog_of_war._update`, which is already
this document's instrumented baseline target. There is no repeated
filtered-query bottleneck to justify a migration, and the `bee_*.gd`
static-function modules operating on a bee Node are already systems over a
component bag. A and B above capture the same value incrementally.
