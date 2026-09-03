# Colony Diagnostics — CD-1, first vertical slice (shipped)

<!-- CONTEXT: archive | LAYER: history -->
Shipped: 2026-09-04 | Branch: claude/CD-1 | Owning plan: `plans/design/colony-diagnostics.md`

Execution record for the slice specified in `plans/design/colony-diagnostics.md`
section 4 (as it read before this slice shipped) and queued as CD-1 in
`NEXTSTEPS.md`'s Claude lane on 2026-09-03/04.

## What shipped

Consolidated `year_winter.gd`'s triplicated colony-state computation into
one call, `colony_diagnostics.gd::compute(main, bees: Array) -> Dictionary`
(new file, `extends RefCounted`, a single `static func`):

1. Moved the per-bee loop (`starving`, `hungry`, `foragers`, `nurses`,
   `comb_workers`) and the two `cells_holding(...)` walks with a loop body
   (`hungry_brood`, `free_cells`) — both previously inline in
   `_refresh_signals` — into `compute()`, returning them under the same key
   names, plus `bees_count` (`bees.size()`), needed by `_winter_forecast`.
   `dead_cells` (a plain `cells_holding("corpse").size()`, not duplicated
   elsewhere) stayed a direct read inside `_refresh_signals` — it was never
   part of the "computed three times" problem, only named `dead_cells` in
   passing in the original slice text.
2. `_refresh_signals` now calls `compute()` once, keeps its existing line-
   building logic reading from the returned dict, and passes both `bees` and
   the dict (`facts`) into `_refresh_panels`.
3. `_refresh_panels` stopped recomputing `hungry_brood`/`free_cells`; it
   reads them from `facts`. `brood_count`/`gyne_count` stayed a direct walk
   of `cells_holding("brood")` in `_refresh_panels`, since they need
   `brood_is_gyne` per cell, which `facts` does not carry.
4. `_winter_forecast()` (now `_winter_forecast(bees_count: int)`) and
   `_refresh_winter()` (now `_refresh_winter(bees_count: int)`) take the bee
   count as a parameter instead of calling
   `get_tree().get_nodes_in_group("bees")` a third time; `_refresh_panels`
   passes `facts.bees_count` at its one call site.
5. `_sample_history()` was left untouched, as specified — its own
   `main.history_timer` cadence stays a separate fetch.

No behaviour change: same values, computed once per signal-tick instead of
two or three times. `tools/verify.ps1` passed (source checks, balance
suite, function map, doc checks). No hands-on check — the acceptance was
"same values before and after for the same save/seed", not a new visible
behaviour.

## Files touched

- `scripts/colony_diagnostics.gd` (new)
- `scripts/year_winter.gd`

## What did not ship

Sections 5–7 of `plans/design/colony-diagnostics.md` (the naming rule,
non-goals, and read-on-demand list) are durable reference, not a further
slice — section 6 explicitly defers migrating any other ad hoc colony-state
read to this module until that site is next touched for another reason, or
a genuine second consumer needs the same fact. Nothing in the design file
names a second ready slice; the plan is complete pending such a consumer.
