# Technical audit plan (Aug 2026)

Two external audits (a broad pass, then a deeper extension covering state
safety, fog architecture, deterministic restores and agent context) were run
against the repo as of the tutorial/bee-individuality/fog-of-war work
landing 19 Aug. Both concluded the same thing: **no broad refactor** — the
project is a sensibly structured prototype. The value left on the table is
concentrated in a handful of bundles below. This file is the executable
version of both reports; read this instead of re-requesting the audits.

**How to use this file.** Work one session per bundle, in order, unless a
bundle says otherwise. Each bundle lists exactly which files to read —
don't explore beyond that list, that's the whole point of bundling by file
overlap. Update the status table below at the end of each session (the same
"rewrite NEXTSTEPS.md" discipline applies here: keep this file's *status*
current, keep the *content* of a finished bundle as a record of what was
done, don't delete it).

## Status

| Bundle | Priority | Effort | Status |
|---|---|---|---|
| A — Challenge state safety | P0 | 2-3h | Done (code + boot check; Dave's hands-on check still pending) |
| B — Deterministic restore + machine-checked guardrails | P1 | 5-7h | Done (code + boot check; Dave's hands-on check still pending) |
| C — Fog-of-war baseline, then optimise if justified | P1 | 3-6h | Not started |
| D — Claude/agent context restructure | P1 | 4-6h | Not started |
| E — Small hot-path and housekeeping cleanups | P2 | 1-2h | Not started |
| F — Conditional/deferred (fog RLE save, BitMap, mask texture) | P2/P3 | varies | Do not start without new measurement |

---

## Ground rules (both audits agreed on these — keep them)

- **Profile before changing.** Every optimisation in bundle C is gated on a
  measurement step. `perf.gd` already exists and is nearly free when
  disabled — use it rather than guessing. This project has twice disproved
  a confident guess (A* pathfinding was cleared as a suspect; the real
  4fps cause was a recursive `_grounded()` call) and found the real bug by
  measuring instead.
- **Minimal global mutation.** `GameConfig` is an autoload and survives
  scene reloads. Nothing outside `game_config.gd`, the save/load path, and
  level/preset code should assign into it. Bundle A fixes the one place
  this rule is currently broken; bundle B adds a cheap static check so it
  stays fixed.
- **Restore is all-or-nothing.** A save either fails validation and changes
  nothing, or succeeds and leaves every collection, index, cross-reference
  and UI readout mutually consistent. Never let code rebuild a cache by
  re-querying a SceneTree group for objects you just created yourself —
  `queue_free()`'d nodes are still visible to a group query until the end
  of the frame.
- **Presentation may be skipped; simulation may not.** Unchanged from
  `CLAUDE.md` rule 3 — repeating it because bundle C's fog work sits right
  on this boundary (fog is presentation *and* has a cached "explored"
  simulation state; don't let a drawing optimisation change what's
  actually been explored).
- **One behavioural axis per change, small commits.** Same discipline as
  every other plan file here (`BEE_SPLIT_PLAN.md`, `PERF_PLAN.md`).

---

## Bundle A — Challenge state safety (P0, do first)

**Why first:** this is the one confirmed bug, not a plausible-optimisation
finding. `challenge_runner.gd::start()` writes `GameConfig.cell_build_time
= FAST_BUILD_TIME` (15s) and only restores it in `_complete()`. Leaving or
restarting Challenge 1 before it completes leaves the game running — and
saving — with the tutorial build speed. This is exactly the kind of thing
that could make Dave's pending Challenge 1 hands-on check (see
`NEXTSTEPS.md` item 1) misleading, so it's worth landing before or
alongside that check.

**Read only:** `challenge_runner.gd`, `tutorial_checkpoint.gd`,
`game_config.gd` (just the `cell_build_time` field and its callers),
`hive_cell.gd` (wherever build progress reads `cell_build_time`),
`debug_panel.gd` (save/load button wiring only).

**Actions:**

1. Stop writing `GameConfig.cell_build_time` globally. Give the fast build
   time an owner that's actually scoped to the tutorial — e.g. a
   `HiveCell.effective_build_time()` that checks for a Challenge-local
   override (or a value `challenge_runner.gd` passes directly to the cell
   being built in 1.3) and falls back to `GameConfig.cell_build_time`
   otherwise. `GameConfig` itself never changes.
2. Call `TutorialCheckpoint.clear()` on every Challenge exit path:
   successful completion, abandonment/return to menu, and starting a fresh
   Challenge. It exists for exactly this and isn't currently wired up
   anywhere in the codebase (checked by search, not just the completion
   flow) — harmless today because Challenge 1 has no failure condition to
   roll back to, but Challenge 2 will use it for real.
3. Decide and enforce: **ordinary player save/load is unavailable while a
   Challenge is active.** Normal `SaveGame` doesn't record Challenge
   stage/gate/prompt state, so a load during a Challenge would silently
   drop it. Simplest fix: grey out or hide the save/load buttons in
   `debug_panel.gd` while `challenge_runner.active`, and rely on
   `tutorial_checkpoint.gd` for Challenge-internal rollback. (This is the
   default both audits recommend — flag it to Dave if he'd rather keep
   ordinary save available and accept losing Challenge progress on load.)

**Validate:** start Challenge 1, reach the fast-build stage (1.3), then in
turn: abandon to menu, restart the run, start a different starter mode —
after each, `GameConfig.cell_build_time` should read the normal value and
building a cell outside the Challenge should take the normal time. Confirm
the save/load buttons are unavailable during an active Challenge and that
no stale checkpoint file survives a completed or abandoned run.

**Done:** all three actions landed. Notes on how, since the mechanism
ended up slightly different from the literal wording above:

1. `HiveCell` gained `build_time_override` (-1 = "use
   `GameConfig.cell_build_time`") and `effective_build_time()`;
   `add_build_progress`/`build_fraction` now call the latter.
   `challenge_runner.gd::_on_queen_build_cell_requested` sets the
   override on the one site it creates. `GameConfig.cell_build_time`
   is no longer written anywhere in `challenge_runner.gd`.
2. Rather than sprinkling `TutorialCheckpoint.clear()` across every
   button handler that can end a Challenge (main menu, restart, load,
   post-game-over restart -- four separate places, all of which already
   `reload_current_scene()`), it's called once, unconditionally, near
   the top of `main.gd::_ready()`: every one of those paths reloads the
   scene, so a single clear-on-boot covers all of them, including any
   future exit path that also reloads. `start()` also clears
   defensively before writing its own first checkpoint, and `_complete()`
   clears explicitly too, since finishing a Challenge doesn't itself
   reload the scene (the player keeps playing).
3. `debug_panel.gd` gained `set_save_load_enabled(bool)`, disabling
   (not hiding) `save_btn`/`load_btn`; `main.gd` now stores its
   `DebugPanel` instance as `debug_panel` (it previously only added it
   as an anonymous child) so `challenge_runner.gd` can call
   `main.debug_panel.set_save_load_enabled(false)` in `start()` and
   `(true)` in `_complete()` -- the same push-a-setter pattern
   `_apply_stage_gate_to_ui()` already uses for the rest of the
   Challenge UI lock.

Verified: `tests/source_checks.py` and `tests/balance_tests.py` both
pass; a full Godot boot via `mcp__godot__run_project` shows no new
parser/type errors (only pre-existing, unrelated shadowing warnings).
**Not yet verified by Dave's own hands-on play** -- specifically,
starting Challenge 1, reaching 1.3, abandoning/restarting at that point,
and confirming `cell_build_time` didn't leak and the save/load buttons
were greyed out throughout.

---

## Bundle B — Deterministic restore + machine-checked guardrails (P1)

**Why bundled together:** both halves touch `saving.gd`/`save_game.gd` and
`tests/source_checks.py`, so one session can hold both without re-reading
either file twice.

**Read only:** `saving.gd`, `save_game.gd`, `world_building.gd` (just the
flower/bee restore calls), `spatial_grid.gd` (just `rebuild()`/`near()`),
`tests/source_checks.py`.

**Actions — restore determinism:**

1. `_restore_flowers()` (and the equivalent bee restore) should build and
   return an explicit array of the nodes it just created. `_restore()`
   should pass that array straight to `flower_grid.rebuild()` instead of
   calling `get_nodes_in_group("flowers")` afterwards. Right now the old
   flowers are `queue_free()`'d but Godot doesn't actually remove them
   from the tree/groups until end of frame, so a group query taken
   mid-restore can catch old and new flowers together. `SpatialGrid`
   already guards with `is_instance_valid()` so this isn't a crash — it's
   wasted work and a stale grid entry until the next rebuild — but it's
   cheap to make deterministic instead of relying on frame timing.
2. Apply the same pattern to restored bees wherever a population count or
   readout is taken immediately after restore.
3. Optionally add a small `_retire_node(node, group_name)` helper
   (`remove_from_group` + `remove_child` before `queue_free()`) for any
   restore path that still wants to iterate old nodes before disposal —
   makes the lifecycle intent explicit rather than depending on deferred
   deletion.
4. Add a preflight check in `SaveGame.read()`: reject (return empty,
   `push_error`, no world mutation) a save whose `version` is *newer* than
   `FORMAT_VERSION`, rather than only warning. Known older versions can
   keep the current defensive-restore behaviour — don't build a full
   migration framework for two format versions, that's over-engineering
   for what's here today.

**Actions — guardrails in `tests/source_checks.py`:**

5. Add `Perf` to the autoload check (currently only `GameConfig` and
   `Session` are checked, despite `Perf` being a registered autoload used
   throughout hot code).
6. Switch the script glob from `scripts/*.gd` to a recursive glob. No
   behaviour change today (scripts/ is still flat) but it means a future
   reorganisation can't silently drop test coverage.
7. Add a cheap regex guard against unauthorised `GameConfig.` writes
   (assignment, not read) outside an allowlist (`game_config.gd`,
   `debug_panel.gd`, `save_game.gd`, `levels.gd`). This is what would have
   caught bundle A's bug automatically if it had existed sooner.

**Validate:** load a save with ~500 flowers and a decent colony;
`flower_grid.size()` should equal the live flower count exactly, not
roughly double it. Load the same save several times in a row and confirm
object/index counts don't grow. Feed the loader a save with
`version: 999` and confirm the live world is untouched and an error is
logged. Run `python3 tests/source_checks.py` — should still pass clean,
and should now fail if you temporarily insert a stray `GameConfig.x = 1`
somewhere it shouldn't be (delete the test insert after confirming).

**Done:** all seven actions landed, plus one thing the guardrail found
before it even shipped:

1-3. `saving.gd` gained `_retire_node(node, group_name)` (removes from
   group and parent, then `queue_free()`), used by both
   `_restore_flowers()` and `_restore_bees()` instead of a bare
   `queue_free()`. Both now return the array of nodes they just created.
   `_restore()` hands the flower array straight to
   `main.flower_grid.rebuild()` (no more `world_building._rebuild_flower_grid()`
   re-querying the group) and the bee array to `main._update_population_readout(bees)`,
   which now accepts an optional explicit list and only falls back to a
   live group query when called with none — its three other call sites
   are unaffected.
4. `SaveGame.read()` now rejects (returns `{}`, `push_error`) a save
   whose `version` is newer than `FORMAT_VERSION`, before anything is
   touched. Older versions keep the existing warn-and-continue path.
5-7. `tests/source_checks.py`: `Perf` added to the autoload check; the
   script glob is now recursive (`scripts/**/*.gd`); and a new
   `check_gameconfig_writes` flags any `GameConfig.<field> =`/`+=`/etc.
   assignment outside `game_config.gd`, `debug_panel.gd`, `save_game.gd`,
   `levels.gd`.
   Turning this check on immediately caught a real, pre-existing
   violation it wasn't written to find: `hud.gd`'s queen panel had its
   own "Lay in plain comb too" checkbox writing
   `GameConfig.queen_lays_in_any_cell` directly, a second, undocumented
   path to the same setting the settings window already exposes safely.
   Fixed the same way `finish_first_requested` and every other hud.gd
   control already work — `hud.gd` now emits
   `queen_lay_any_cell_toggled(value)`, `main.gd` connects it to a new
   `debug_panel.gd::set_toggle(key, value)` (writes `GameConfig`/`Session`
   via the existing `setting_set` and syncs the settings window's own
   checkbox if it's open), so the write stays inside the one allowlisted
   file.

Verified: `tests/source_checks.py` and `tests/balance_tests.py` both
pass; confirmed the new guardrail actually fires by temporarily adding
a stray `GameConfig.flower_count = 1` to `hive.gd` (caught it, then
reverted). A full Godot boot via `mcp__godot__run_project` shows no new
parser/type errors, only the same pre-existing shadowing/unused-parameter
warnings already on record. **Not yet verified by Dave's own hands-on
play** — specifically, saving and loading a run with a sizeable colony
and confirming population/flower counts don't drift across repeated
loads, and that the queen panel's "Lay in plain comb too" checkbox still
works and stays in sync with the settings window's copy.

---

## Bundle C — Fog-of-war: measure first, then optimise (P1, gated)

**Why gated:** the 5-unit fog rework (shipped 18-19 Aug) is explicitly
unmeasured in the source itself. Both audits agree the *shape* of the risk
is real (a reveal radius of 240 at 5-unit resolution means ~7,200-9,400
tile operations per bee per relight, each bee caching its own full tile
array, full-array queries and an unconditional `queue_redraw()` every
frame) but neither treats that as proof it's currently costing frames.
**Do the measurement step before writing any optimisation code.**

**Read only:** `fog_of_war.gd`, `perf.gd` (for the `Perf.begin`/`end`
pattern), `camera_view.gd` (only for where zoom/position change, needed for
the dirty-redraw step).

**Step 1 — baseline (measurement only, no code change):**

Using the existing starred-fps/`perf.gd` breakdown (see "Measuring
performance, not guessing at it" in `CLAUDE.md`), get frame time and the
`fog_of_war` section specifically at a few colony sizes with fog on vs
off, at zoom 1.0 and the minimum zoom (0.4, where the drawn area is 6.25x
larger). This needs Dave's hands-on playtest (or the `mcp__godot__*` tools
if wired up this session, to at least confirm it boots and the perf
overlay works) — a static read of the code can't tell you whether this is
actually the bottleneck.

**Step 2 — if the baseline shows `fog_of_war` as a real cost, in order:**

1. **Shared precomputed disc + center-only per-bee cache.** Replace each
   bee's full translated tile array with one shared `Array[Vector2i]` of
   relative offsets (computed once, rebuilt only if `fog_reveal_radius`
   changes) plus a per-bee `{last_world_pos, center}` record. Relighting
   applies the shared offsets to the old center (to unlight) and the new
   center (to light), instead of recomputing and storing the whole disc
   per bee per relight. This alone removes most of the repeated geometry
   and the ~7,200-entry-per-bee arrays without changing what's revealed.
2. **Dirty-driven redraw.** Only call `_layer.queue_redraw()` when fog
   state actually changed (a source relit/expired, `explored` changed,
   `fog_permanent_reveal` toggled) or the camera moved/zoomed/switched
   view — not unconditionally every `_update()`.
3. Re-measure with the same scenario as the baseline. Stop here if frame
   time and worst-frame numbers are back near the pre-fog-rework 60fps
   baseline (`PERF_PLAN.md`). Don't proceed to step 3 without a new
   measurement showing it's still needed.

**Do not do in this bundle** (explicitly deferred to bundle F, and only
with fresh justification): incremental old-disc/new-disc edge updates,
a `BitMap`/packed representation, a lower-frequency polling cadence for
relight checks, or a mask-texture + shader rewrite. All four are real
options if step 2 turns out insufficient, but none should be the first
thing tried.

**Validate:** identical explored/lit visual output before and after
(screenshot compare at a fixed camera position is enough). Lower
`fog_of_war` time and lower memory in the same scenario used for the
baseline. If the baseline in step 1 comes back clean, close this bundle
with "measured, not a bottleneck" and move on — that's a valid outcome,
not a stall.

---

## Bundle D — Claude/agent context restructure (P1, docs and config only, zero gameplay risk)

**Why this matters as much as the code bundles:** root `CLAUDE.md` is
currently ~550 lines. Current Claude Code guidance is that always-loaded
project instructions over roughly 200 lines cost more context and can
reduce instruction adherence, and that `@path` imports don't help (they
still load at session start) — the actual mechanism for scoping is
path-specific rules that load only when matching files are touched. This
is the single highest-leverage item in either report; it costs nothing in
gameplay risk because nothing here touches `scripts/`.

**Read only:** `CLAUDE.md`, `.claudeignore`, `CLAUDE_CODE_SETUP.md`,
`FUNCTION_MAP.md`. Do not open simulation scripts for this bundle.

**Actions:**

1. **Trim root `CLAUDE.md` to ~160-200 lines.** Keep: what Meadow is and
   its Godot version, the "start here" pointer to `NEXTSTEPS.md`, the
   condensed file-routing table, the four numbered rules, the two test
   commands and what each catches, and a short "working style Dave asked
   for" section. Move out (don't delete): the full bug-catalogue
   ("Bugs this project keeps having"), the detailed perf-investigation
   writeup, and the chronological "state of play" shipped-feature history.
2. **Move what's cut to `docs/`:** `docs/known-pitfalls.md` (the bug
   catalogue — coordinate spaces, shadowed built-ins, the recursion bug,
   etc.), `docs/performance.md` (the measuring-performance methodology,
   which stays referenced from the trimmed `CLAUDE.md`), `docs/history.md`
   (the state-of-play chronology). Link to all three from the trimmed
   `CLAUDE.md` rather than inlining them.
3. **Archive completed plan docs** (`BEE_SPLIT_PLAN.md`,
   `MAIN_SPLIT_PLAN.md`, `PERF_PLAN.md`, `NEW_FEATURES_BLUEPRINT.md`,
   `SCOUTING_TOGGLE_PLAN.md`, `BEE_INDIVIDUALITY_PLAN.md`, and
   `TUTORIAL_PLAN.md` once Challenge 1 is confirmed and Challenge 2 ships)
   into `docs/archive/`. They stay valuable as history, not as
   always-discoverable root-level files competing with live plans like
   this one.
4. **Fix the `.claudeignore` claim.** `CLAUDE.md` currently says
   `.claudeignore` keeps `.godot/`, `_backups/` and `*.uid` out of Claude
   Code's context automatically — that's not how Claude Code actually
   applies exclusions. Replace with `.claude/settings.json`:
   ```json
   {
     "permissions": {
       "deny": ["Read(./.godot/**)", "Read(./_backups/**)"]
     }
   }
   ```
   Leave `*.uid` files alone — they're tiny and matter during file
   moves/renames; the audit's original suggestion to blanket-deny them
   isn't worth it next to the other three items here.
5. **Add path-scoped rules** under `.claude/rules/`: `gdscript.md` (paths:
   `scripts/**/*.gd` — parsing/typing conventions, the `:=` landmine),
   `saving.md` (paths: `saving.gd`, `save_game.gd`,
   `tutorial_checkpoint.gd`, `challenge_runner.gd` — the restore-safety
   rules from bundle B), `simulation.md` (paths: `bee*.gd`, `hive*.gd`,
   `flower.gd`, `season.gd`, `spatial_grid.gd` — presentation/simulation
   split, `GameConfig` read-only rule), `performance.md` (paths:
   `fog_of_war.gd`, `perf.gd`, `bee_movement.gd`, `spatial_grid.gd` — the
   measure-first method). Content comes from what's moved out of
   `CLAUDE.md` in steps 1-2, not new writing.
6. **Generate `FUNCTION_MAP.md`** with a small `tools/update_function_map.py`
   instead of maintaining it by hand, plus a `--check` mode that fails if
   the committed file is stale. Keeps the "grep the map before opening a
   1,000+ line file" workflow (`CLAUDE.md`'s current advice) reliable
   without relying on every session remembering to update it manually.

**Validate:** open a fresh session and ask it to summarise what it knows
after reading just the trimmed `CLAUDE.md` + `NEXTSTEPS.md` — check nothing
load-bearing was lost. Compare `/context` usage (or `/memory`, if
available) before and after on two or three representative small tasks
(a UI label change; a bee-behaviour condition change; a save-compatibility
change) — the goal is lower context *and* no new corrective edits, not
context reduction at any cost.

---

## Bundle E — Small hot-path and housekeeping cleanups (P2, bundle together, low risk)

**Why bundled:** none of these depend on each other, but they're all small
enough that splitting them across sessions would waste more tokens on
session setup than the fixes themselves take.

**Read only:** `hive_cell.gd`, `season.gd`, `egg.gd`, `queen.gd`.

**Actions:**

1. `HiveCell._health_factor()` calls `get_tree().get_nodes_in_group("season")`
   from a per-frame brood-development path to find the one `Season`
   system that already exists as a direct child of `main`. Give `Hive`
   (or `HiveCell`) a stable reference instead — small win today, matters
   more as cell counts grow.
2. Run `rg 'egg\.gd|queen\.gd|preload\(.*egg|preload\(.*queen' .` to
   confirm there's no remaining reference, then delete `egg.gd` and
   `queen.gd` — both already mark themselves retired in their own file
   header (loose eggs replaced by direct laying into a cell; queen
   behaviour is now the ordinary `Bee` with `is_queen = true`).
3. Clean up the stale `_backups/` reference inside `queen.gd`'s own header
   comment (it claims an old implementation lives there) as part of the
   same pass, since you're deleting the file anyway.

**Validate:** `python3 tests/source_checks.py` and
`python3 tests/balance_tests.py` both still pass; a `rg` for `egg.gd`/
`queen.gd` outside `_backups/` and git history returns nothing.

---

## Bundle F — Conditional / deferred (do not start without new measurement)

Keep these visible so nobody re-discovers them from scratch, but none is
authorised work yet:

- **Fog save-size (RLE/row-run representation).** Only worth it if a
  save-file-size/load-time measurement at high exploration percentage
  actually shows a problem. The flower field alone is ~214,000 possible
  5-unit fog cells, so a naive one-pair-per-tile JSON *could* get large,
  but that's not yet measured.
- **`BitMap`/packed fog storage.** Requires committing to a fixed
  fog-space rectangle as an architectural assumption (today's dictionary
  is unbounded). Only prototype if bundle C's memory measurements justify
  it.
- **Incremental disc edge updates** (update only the symmetric difference
  between old and new translated discs on a relight). Only worth the
  added correctness risk if bundle C step 2 still shows relight as hot
  after the shared-offset change.
- **Mask-texture + canvas-shader fog rendering.** Only if `_draw_fog`
  itself remains a measured bottleneck after the dirty-redraw change —
  this is a rendering-architecture change, not a tuning change, and
  should be compared against the simpler renderer on frame time, worst
  frame, memory and visual parity before being adopted.
- **Event-driven whole-hive hatch detection** (a `brood_ready` signal or a
  coarser hatch-check tick instead of a per-frame linear scan). Only
  worth it if a 250/500-cell stress test actually shows this scaling
  badly — include it in whatever scenario bundle C's baseline session
  ends up testing, since the setup (a large synthetic hive) is shared.
- **Centralising `season_strength()`/flower per-frame work.** Only if
  `flowers` shows up near the top of a `Perf` breakdown after the fog work
  above is done — the previous perf pass already reduced flowers to
  presentation-only updates at 6/sec; simulation still runs every frame
  and that may simply be fine at current counts.

---

## Explicitly do not change (both audits agree, carried forward from `PERF_PLAN.md`'s own findings)

- Don't re-add spatial indexing for obstacles (14 objects; already
  measured as slower than a linear scan — see `ROADMAP.md`).
- Don't touch A* pathfinding or move it to a coarser graph — cleared as a
  suspect, measures at ~0ms.
- Don't remove or weaken `perf.gd` — it has already paid for itself many
  times over.
- Don't turn the bee behaviour helper modules (`bee_movement.gd` etc.)
  into per-bee child Nodes — the static-`RefCounted` pattern is correct
  for something instantiated hundreds of times.
- Don't split `Main.tscn` into multiple scenes or reorganise `scripts/`
  into subfolders — the flat layout is what makes the routing table and
  `source_checks.py` work today; a reorg is real work for no measured
  benefit and would need the recursive-glob fix in bundle B first anyway.
- Don't introduce object pooling, MultiMesh rendering, or reduce
  off-screen simulation fidelity without a specific measured bottleneck
  pointing at exactly that.

---

*Source: two audit passes against `master` as of the 19 Aug tutorial/fog/
bee-individuality work (Godot 4.7.1, parses and boots clean). Full report
text isn't reproduced here — this file is the actionable distillation;
treat it as authoritative over re-deriving priorities from scratch.*
