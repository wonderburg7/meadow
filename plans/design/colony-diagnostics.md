# Meadow — Colony Diagnostics

<!-- CONTEXT: plan | LAYER: design -->
Status: active | Owner: Dave / Claude Code | Next: § 4's first vertical slice, queued as CD-1 in `NEXTSTEPS.md`'s Claude lane | Dependency: none | Verified: 2026-09-03

Scoped 3 Sep 2026 as the first of `plans/design/product-scope.md` §6.2's five
undesigned "shared foundations" to get its own design pass (Dave's pick —
the other four are goal model, event director, job catalogue/dispatcher and
run policy; none of them is designed yet, and this file does not define
them).

## 1. Purpose

One reusable computation of "what is true about the colony right now," in
named, stable-keyed facts — read by the problem-strip/warning banner, the
Colony/Nursery/Foraging panels, and later Dr Gallerin's "Why is this
happening?" route, the goal model's urgent-problem detection and the event
director, once those exist. Today every one of those either recomputes its
own version of the same fact, or doesn't exist yet to read one. This file
defines the computation and its shape only — not the goal model, the event
director or Dr Gallerin's dialogue, which each need their own design pass
before they can consume it for anything beyond what's in section 4.

## 2. What already exists — reuse map

<!-- LAYER: durable-rules -->

| Need | Existing precedent | Decision |
|---|---|---|
| A per-colony aggregate cheap enough to read every tick | `main.gd::_role_counts()` — a `Dictionary` cache plus an epoch counter (`_role_counts_cache`, `_role_counts_built_epoch` against `_population_epoch`), rebuilt only when population actually changed | Precedent for "cache the aggregate, don't recompute it per reader" — but see section 3: this file's cadence is a *timer*, not an epoch, so the mechanism differs even though the shape (a stored `Dictionary`, one owner) is the same. |
| Bucketed cell lookups | `hive.gd::_content_index()` — cells bucketed by `content_type` (`nectar`/`pollen`/`honey`/`jelly`/`brood`/`corpse`/`unbuilt`/`ripe_honey`), invalidated by the cell mutator, read by `cells_holding()` | Colony Diagnostics reads these buckets (`cells_holding("brood")`, `cells_holding("")`); it does not add a second cell index. |
| The one place these facts are already computed today | `year_winter.gd::_refresh_signals` (per-bee loop for `starving`/`hungry`/`foragers`/`nurses`/`comb_workers`, plus `hungry_brood`/`free_cells` from the cell buckets) and `_refresh_panels` (recomputes `hungry_brood`/`free_cells` a second time), both reached from the same 1&nbsp;Hz `main.signal_timer` gate; `_winter_forecast` (reached via `_refresh_panels` → `_refresh_winter`) re-fetches `get_tree().get_nodes_in_group("bees")` a third time in the same call tree | This is the file to change first (section 4) — `plans/reference/technical-audit.md` item B already names this exact duplication as a measured-not-yet candidate. |
| Warning/toast copy and throttling | `problem_messages.gd` — the existing catalogue of message text/keys, read by `hud.show_warning` | Unchanged. Colony Diagnostics feeds facts to callers that decide whether to show a message; it is not a second warning system. |
| Dev/telemetry facts | `diagnostic_log.gd` and `docs/headless-run-contract.md`'s diagnostic snapshot allowlist (`population.total`, `resources.food_stores`, `environment.winter_here`, `role_outcomes.cells_completed_total`, `performance.fps`, `performance.top_sections_ms`) | A separate system for a separate audience (headless scenario verdicts), kept separate — see section 5's naming rule for why it still matters here. |

Net effect: this is a consolidation of facts already being computed, not a
new computation.

## 3. Shape

- **No new tick.** The facts are computed inside `year_winter.gd`'s existing
  `main.signal_timer`-gated call (currently the top of `_refresh_signals`),
  which already runs at 1&nbsp;Hz. Do not add a second timer.
- **No new cache/epoch mechanism for the first slice.** The computed
  `Dictionary` is threaded as a plain function argument through the same
  call chain that already threads `bees: Array` today
  (`_refresh_signals` → `_refresh_panels(bees)` → `_refresh_winter()` →
  `_winter_forecast()`), the same way `bees` itself is already threaded.
  Nothing needs to be *stored* for this slice to close the duplication.
- **A later slice may add a retained copy** (e.g. `main.colony_facts`,
  written once at the end of the signal-tick, same pattern as
  `main.hud.corner_texts`) once a consumer genuinely needs to read a fact
  outside the signal-tick call chain — Dr Gallerin's "Why?" route or the
  event director are the likely first ones. Do not build that storage
  speculatively ahead of a consumer that needs it.
- **New file, not a new section of `year_winter.gd`.** `year_winter.gd`'s
  own header says it holds no state and covers "the winter forecast, the
  season/day readout, the problem-strip signals and the panels they feed" —
  a fact computation meant to be read by systems that are not about winter
  or panels (the future goal model, event director) does not belong owned
  by that file. New file `colony_diagnostics.gd`: a stateless
  `extends RefCounted` of `static func`s taking `main`/`bees` as arguments
  and returning a `Dictionary` — the Service shape `GAME_MODEL.md`'s "Core
  architecture terms" section already names for colony-wide,
  non-Node-per-instance logic.

## 4. First vertical slice

Consolidate `year_winter.gd`'s existing triplicated computation into one
call. No behaviour change — same values, computed once per signal-tick
instead of two or three times.

1. `colony_diagnostics.gd::compute(main, bees: Array) -> Dictionary` moves
   the per-bee loop currently inline in `_refresh_signals`
   (`starving`, `hungry`, `foragers`, `nurses`, `comb_workers`) and the two
   `cells_holding(...)` walks currently inline in the same function
   (`hungry_brood`, `free_cells`) into one function, returning them under
   those same key names.
2. `_refresh_signals` calls it once, keeps its existing line-building logic
   (the `if starving > 0: lines.append(...)` block and the rest) reading
   from the returned dict instead of local variables, then passes the dict
   into `_refresh_panels(bees, facts)`.
3. `_refresh_panels` stops recomputing `hungry_brood`/`free_cells` itself
   and reads them from `facts` instead.
4. `_winter_forecast()` takes `facts` (or just `facts.bees_count`) as a
   parameter instead of calling `get_tree().get_nodes_in_group("bees")`
   again — it is reached from inside the same call chain, so the value it
   needs was already computed one call up.
5. `_sample_history()` is a deliberately separate cadence
   (`main.history_timer`, gated by `GameConfig.history_sample_seconds`, not
   1&nbsp;Hz) and stays out of this slice — folding it in would change when
   its own bee-count fetch happens, which is exactly the kind of tick-policy
   drift this file is meant to prevent, not introduce.

**Acceptance.** `tools/verify.ps1` passes. The problem-strip lines, the
Colony/Nursery panel readouts and the winter forecast panel show identical
values before and after, for the same save/seed. No hands-on check beyond
that — nothing about what the player sees is meant to change.

**Reasoning level:** low. One file added, one existing file's internal calls
rewired behind an unchanged external result; the values and their meaning
are already fully specified by the code being consolidated.

## 5. Naming rule for facts added later

A fact this file's `Dictionary` computes that already has a name in
`docs/headless-run-contract.md`'s diagnostic snapshot allowlist (population
totals, food stores, winter-here, cells-completed, and so on) must mean the
same thing that name already means there, not a subtly different count
under the same word. The two systems stay separate — one feeds player-facing
UI and future goal/event logic, the other feeds headless scenario verdicts —
but a future contributor should never have to wonder whether "population
total" here matches "population total" there. Section 4's own facts
(`starving`, `hungry`, `foragers`, `nurses`, `comb_workers`, `hungry_brood`,
`free_cells`) have no existing counterpart in that allowlist, so nothing
needs renaming for the first slice.

## 6. Non-goals for this pass

Design the goal model, the event director, Dr Gallerin's dialogue system or
the job catalogue/dispatcher — each is a separate, still-undesigned §6.2
foundation. Add a retained/cached copy of the facts dict ahead of a
consumer that needs one. Migrate every existing ad hoc colony-state read in
the codebase to this module in one pass — only `year_winter.gd`'s named
triplication (section 4) is in scope; other sites move to it only when they
are next touched for another reason, or when a genuine second consumer
needs the same fact and would otherwise compute it a third way.

## 7. Read on demand

<!-- LAYER: on-demand -->

- `scripts/year_winter.gd` lines 17–32 and 166–307 — before writing
  `colony_diagnostics.gd` or rewiring the calls in section 4.
- `scripts/main.gd`'s `_role_counts()` (search `_role_counts_cache`) — the
  cache/epoch precedent referenced in section 2, if a later slice adds
  retained storage.
- `plans/reference/technical-audit.md` item B — the existing hot-path
  finding this slice resolves; re-read before claiming a second, larger
  version of this consolidation is warranted without a fresh profile.
- `docs/headless-run-contract.md`'s diagnostic snapshot field list — before
  naming any fact not already covered by section 4.
