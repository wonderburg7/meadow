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
| C — Fog-of-war baseline, then optimise if justified | P1 | 3-6h | Closed: measured, partially fixed. `fog_of_war_update` resolved; `fog_of_war_draw` at min zoom over unexplored ground remains the one item with fresh justification, carried to Bundle F |
| D — Claude/agent context restructure | P1 | 4-6h | Done |
| E — Small hot-path and housekeeping cleanups | P2 | 1-2h | Done (code + boot check; Dave's hands-on check still pending) |
| F — Conditional/deferred (fog RLE save, BitMap, mask texture) | P2/P3 | varies | Mask-texture/canvas-shader item: perf fix confirmed by Dave at Day 11/50-bee scale; the edge bug it surfaced took two attempts (a CPU-side clamp fixed stretching but caused a worse revealed-by-default bug; the real fix moved the bounds check into the shader) -- awaiting one more check. Everything else in the bundle still needs new measurement before starting |

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
  every other plan file here (`docs/archive/BEE_SPLIT_PLAN.md`,
  `docs/archive/PERF_PLAN.md`).

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
   baseline (`docs/archive/PERF_PLAN.md`). Don't proceed to step 3 without a new
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

**Step 1 baseline (Dave's playtest, 19 Aug):** starred fps, played Day
1-5 at a handful of colony sizes, fog on and off, zoom 1.0 and 0.4.
Confirmed a real cost, not a false alarm:
- `fog_of_war_draw` dominated at low zoom — ~4ms zoomed in vs measured
  as high as ~130ms zoomed out (the 6.25x drawn-area scaling both
  audits predicted).
- `fog_of_war_update` grew with colony size — from ~1ms at 2 bees to
  ~27ms at 32 meadow bees (Day 3 sample), consistent with the
  per-bee-stored-disc shape both audits flagged.
- Worst frame recorded: 15fps/65ms (Day 3, 32 bees, fog on). A "fog off"
  comparison also showed non-zero `fog_of_war_draw`/`fog_of_war_update`
  readings — **later found to be a `perf.gd` display bug, not a real
  cost** (see the correction below the step 2 re-measurement).
- Separately, Dave also checked Bundle E's pending disease/brood item
  and saw no visible slowdown or comb-panel text after a few minutes of
  leaving larvae uncleaned. Checked against `balance_tests.py`'s own
  pathogen model (`2 bodies, 40 bees in 50 cells: sickens in 3.3 days`)
  — the mechanism is correctly wired (`hud.gd`'s comb readout does show
  `Season.disease_text()`, confirmed by reading the code), it just needs
  more corpses and/or more real time than a few minutes to cross the
  0.35 disease threshold by design ("no cost until real neglect"). Not
  reopening Bundle E for this; flagging here since it was checked in the
  same session.

**Step 2 (landed, gated on the baseline above showing a real cost):**
1. **Shared precomputed disc + centre-only per-bee cache.** `_bee_light`
   no longer stores each bee's full translated tile array; it stores a
   centre tile only. `_disc_offsets` holds one shared `Array[Vector2i]`
   of relative offsets, rebuilt via `_ensure_disc_offsets()` only when
   `GameConfig.fog_reveal_radius` changes (it's a live debug-panel
   slider). `_light_center(center, delta)` applies the shared offsets to
   light (`delta 1`) or unlight (`delta -1`) whichever centre needs it —
   used by both `_relight` and the bee-departed cleanup loop, replacing
   the old `_unlight(tiles)`.
2. **Dirty-driven redraw.** `_update()` now only calls
   `_layer.queue_redraw()` when something that affects the drawn output
   actually changed: a bee relit/unlit this frame, the fog layer just
   became visible again, the hive/meadow view switched, or the camera
   moved/zoomed/`fog_permanent_reveal` toggled since the last frame that
   was actually redrawn (`_camera_view_changed()`). A static camera over
   an unchanging fog state now draws nothing.

Verified: `tests/source_checks.py` and `tests/balance_tests.py` both
pass; `tools/update_function_map.py --check` unaffected (fog_of_war.gd
isn't one of the six mapped scripts). A Godot boot via
`mcp__godot__run_project` shows no new parser/type errors, only the
same pre-existing shadowing/unused-parameter warnings already on
record.

**Step 2 re-measured (Dave's playtest, 19 Aug, same day as the
baseline):** same scenario — a handful of colony sizes, fog on
(unexplored ground opaque black) vs `fog_of_war_on` toggled off
entirely ("see the whole meadow at once" — the fully green
screenshots), zoom 1.0 vs 0.4. Confirmed the shape of what step 2 fixed
and what it didn't:
- **`fog_of_war_update` is effectively resolved.** 0-3ms across every
  sample, including the busiest (27 bees, min zoom: 2ms) — down from
  the baseline's ~27ms at 32 bees. Matches the theory: the old cost was
  mostly the ~9,000 `Vector2.length()` calls and array-append churn of
  rebuilding each bee's disc from scratch every relight, not the
  dictionary writes themselves — sharing one precomputed offsets array
  removed exactly that part.
- **`fog_of_war_draw` dropped at min zoom but is still the dominant
  cost there.** ~71ms at zoom 0.4 with fog on (27-bee sample; worst
  frame 92ms/36fps) vs the baseline's ~132ms at similar zoom — real,
  but not enough on its own. At zoom 1.0 it's largely unchanged (12-27ms
  across samples, comparable to baseline) — expected, since dirty-driven
  redraw only pays off when the view is genuinely static, and an active
  colony with bees flying near the visible edge keeps triggering a
  relight most frames regardless.
- **Correction — the "cost while fog is off" reading in both playtests
  was a `perf.gd` display bug, not a real one.** With `fog_of_war_on`
  false, `_update()` returns before `Perf.begin("fog_of_war_update")`
  runs, and setting `_layer.visible = false` means Godot never calls
  `_draw_fog` at all (invisible `CanvasItem`s aren't redrawn) — the
  section genuinely executes zero times per frame. What Dave was
  actually seeing: `perf.gd`'s corner breakdown is an exponentially-
  smoothed rolling average per section (`perf.gd::_process`), but it
  only *updated* a section's average on frames where that section ran.
  Once a section stopped running altogether, its last known value just
  froze in the display forever instead of decaying — so both playtests'
  "fog off" numbers were stale leftovers from the "fog on" frames just
  before, not a real ongoing cost. **Fixed the same session**: inactive
  sections now decay toward zero each frame and drop out of the
  averages dict once negligible, so `top_sections()` stops surfacing a
  dead section. This means the "zoom-out spike is specific to drawing
  unexplored ground vs bookkeeping in general" claim this section used
  to make here **doesn't hold up** — that comparison was "fog genuinely
  on" vs "layer not drawing at all," which trivially differs and proves
  nothing about `fog_permanent_reveal` specifically. Whether draw cost
  actually concentrates in unexplored-margin tiles vs already-revealed
  ones (`fog_permanent_reveal` on, same zoom, same explored state) is
  still an open question — nobody has actually taken that comparison
  yet, and now that `perf.gd`'s readings can be trusted, it's a cheap
  one to take before committing to the mask-shader rewrite below.

**`perf.gd` fix, landed same session:** `_process()`'s averaging loop
now walks `averages.keys()` first and decays (same 0.1 lerp toward
zero) any section absent from `_totals` this frame, erasing it once its
value drops below 0.01ms. A section that stops running — any toggled-
off system, not just fog — now fades out of the corner breakdown
instead of freezing at its last reading forever. `tests/source_checks.py`/
`balance_tests.py` pass, a Godot boot shows no new parser/type errors.

**Clean re-measurement (Dave, same session, right after the `perf.gd`
fix):** same colony size and camera (22 foraging + 2 nursing + 3 comb
workers, zoomed out), this time comparing "dynamic reveal" (ordinary
fog — unexplored opaque, explored-but-unlit dimmed) against
`fog_permanent_reveal` on, with the `perf.gd` fix in place so the
readings are trustworthy:
- Dynamic reveal: `fog_of_war_draw` **29ms** (35fps, worst 83ms).
- Permanent reveal: `fog_of_war_draw` **7ms** (56fps, worst 88ms).

**This confirms the original theory after all** — drawing genuinely
unexplored/dimmed tiles costs roughly 4x what drawing an
already-revealed, mostly-transparent view does, at the same zoom and
colony size. The open question raised by the correction above is
answered: it's not just raw visible-tile count at low zoom, it's
specifically the opaque-unexplored and dimmed-explored branches of
`_draw_fog_body` that are expensive. (Both readings still show a worst
frame well above the 60fps target — 83-88ms — so there's a separate,
smaller cost at this zoom/colony-size that isn't fog-specific. Out of
scope for this bundle, but see the `perf.gd` granularity addition
directly below — added the same session to actually investigate it.)

**`perf.gd` granularity addition, same session:** the corner
breakdown's smoothed rolling average couldn't explain that 83-88ms
figure at all — its sections summed to roughly 10ms, because a single
spike barely nudges a 0.1-lerp average taken across many frames. The
"worst" number and the section breakdown were never even answering the
same question. Added `Perf.last_worst_ms`/`last_worst_breakdown`: an
unsmoothed snapshot of every section's time taken at the exact frame
that set the current window's worst-ms figure (`perf.gd::_process`,
captured into `_window_worst_totals` the moment `frame_ms` raises
`_window_worst_ms`, published as `last_worst_breakdown` when the window
closes). `perf_breakdown.gd` now shows a second line, "worst frame
(Xms): ...", alongside the existing rolling-average line. Also closed
the one real coverage gap this surfaced: `main.gd::_process()` called
`camera_view._handle_pan`, `world_building._apply_scenery_setting`,
`_reseed_meadow`, `_advance_weather`, `_check_for_loss` and
`_check_colony_energy` with no `Perf` wrap at all, so nothing could
attribute cost to them even in principle. Now wrapped as `camera_pan`
and a combined `housekeeping` section — not because either is assumed
to be the culprit, just so the new worst-frame breakdown can actually
account for the whole frame instead of leaving an unexplained gap.
`tests/source_checks.py`/`balance_tests.py` pass, `tools/
update_function_map.py --check` clean (regenerated after main.gd's new
lines shifted it), a Godot boot shows no new parser/type errors.

**Checked by Dave, same session — a genuine split result:**
- **Fog on: fully explained, and worse than the average suggested.**
  Worst frame 96ms; the new breakdown attributes 89ms of it (93%) to
  `fog_of_war_draw` alone (83ms) plus `fog_of_war_update` (4ms) — its
  own rolling average had only been showing 15ms, because fog draw cost
  is bursty enough that a 0.1-lerp average buries the real peaks. This
  strengthens Bundle F's mask-shader case further: the worst case is
  materially worse than the steady-state number already used to justify
  it.
- **Fog off: still unexplained, and now confirmed unrelated to
  anything in this codebase's `_process`/`_draw` calls.** Worst frame
  58ms; every listed section — including the newly-wrapped
  `camera_pan`/`housekeeping` — summed to roughly 2ms. Wrapped the
  remaining main.gd calls that were still uncovered (`scenery`,
  `history` — folding in `_sample_rates` — and `prune_selection`) in
  case one of those was it; none showed up either. At this point every
  per-frame call main.gd itself makes has a `Perf` section, and the gap
  persists — this is very likely genuine engine/render-thread time
  (vsync/present stall, GPU flush, texture/font work) that no CPU-side
  GDScript timer can ever see, not a missing instrumentation site.
  **`perf.gd` has hit its ceiling on this one specific spike** — further
  diagnosis needs Godot's own built-in profiler (Debugger > Profiler/
  Monitors in the editor), a different tool, not more `perf.gd` surgery.
  Not blocking anything; noted as a known, lower-priority open item.

`source_checks.py`/`balance_tests.py` re-run clean after the second
round of wraps; `FUNCTION_MAP.md` regenerated again; Godot boot clean.

**Bundle C is closed as "measured, partially fixed."** `fog_of_war_update`
needs nothing further. `fog_of_war_draw` at normal zoom is fine; at min
zoom it's a real cost, and now cleanly confirmed to concentrate in
drawing unexplored/dimmed tiles specifically rather than fog bookkeeping
or tile-walk cost in general. Bundle F's mask-texture/canvas-shader item
has real, specific justification — see its updated entry. The other
three Bundle F items (`BitMap`/packed storage, incremental disc-edge
updates, save-size RLE) still have no fresh measurement behind them —
`fog_of_war_update` being cheap now removes the case for incremental
edge updates specifically, and save size/load time hasn't been measured
at all yet.

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

**Done:** all six actions landed, plus two things not explicitly asked
for but cheap given the same read:

1. `CLAUDE.md` trimmed from 555 lines to 210 -- kept: what Meadow is and
   its Godot version, the `NEXTSTEPS.md` pointer, the full file-routing
   table (condensed prose around it, not rows -- that table is the
   single highest-value part of the file), the four numbered rules, the
   two test commands and what each catches, and "Working style Dave
   asked for". 210 is a little over the ~160-200 target; the table
   itself is 37 rows and didn't seem worth cutting to hit a round
   number.
2. Moved out to `docs/`: `docs/known-pitfalls.md` (the bug catalogue),
   `docs/performance.md` (the measuring-performance methodology, plus
   the "explicitly do not change" list this file already carried),
   `docs/history.md` (the state-of-play chronology). All three, and
   `docs/archive/`, are linked from the trimmed `CLAUDE.md`.
3. Archived to `docs/archive/` via `git mv` (history preserved):
   `BEE_SPLIT_PLAN.md`, `MAIN_SPLIT_PLAN.md`, `PERF_PLAN.md`,
   `NEW_FEATURES_BLUEPRINT.md`, `SCOUTING_TOGGLE_PLAN.md`,
   `BEE_INDIVIDUALITY_PLAN.md` -- each got a one-line "Archived, shipped"
   note at the top. `TUTORIAL_PLAN.md` stays at root per this bundle's
   own condition (Challenge 2 hasn't shipped yet). Every cross-reference
   to the six moved files elsewhere in the repo (`CLAUDE.md`,
   `CLAUDE_CODE_SETUP.md`, `DESIGN_BACKLOG.md`, `ROADMAP.md`,
   `TUTORIAL_PLAN.md`, this file) was repointed to the new path -- the
   six files reference each other by bare filename and didn't need
   editing, since they moved together.
4. `.claude/settings.json` added with `permissions.deny` on
   `Read(./.godot/**)` and `Read(./_backups/**)` -- `*.uid` files stay
   un-denied as this bundle specified. `CLAUDE.md` and
   `CLAUDE_CODE_SETUP.md`'s `.claudeignore` claims rewritten to point
   at this instead; `.claudeignore` itself is left in place (harmless,
   just no longer described as doing anything for Claude Code).
5. `.claude/rules/` added: `gdscript.md` (`scripts/**/*.gd`), `saving.md`
   (`saving.gd`, `save_game.gd`, `tutorial_checkpoint.gd`,
   `challenge_runner.gd`), `simulation.md` (`bee*.gd`, `hive*.gd`,
   `flower.gd`, `season.gd`, `spatial_grid.gd`), `performance.md`
   (`fog_of_war.gd`, `perf.gd`, `bee_movement.gd`, `spatial_grid.gd`).
   Confirmed against `claude-code-guide` that `.claude/rules/*.md` with
   a `paths:` glob list is the actual stable mechanism (not a
   convention) before writing these, rather than guessing the format.
6. `tools/update_function_map.py` regenerates `FUNCTION_MAP.md` from the
   six scripts' own `# --- section ---`/`func`/`static func` lines
   (`--check` exits non-zero if the committed file has drifted).
   Running it immediately proved the point of writing it: the
   hand-maintained map was already stale in four places
   (`hud.gd` 1,720→1,725, `debug_panel.gd` 1,187→1,209, `hive_cell.gd`
   845→855, `main.gd` 762→779, plus `saving.gd`, `save_game.gd`,
   `fog_of_war.gd` and `challenge_runner.gd` outside the six-file map)
   since it was last hand-updated 19 Aug. The routing table's line
   counts in `CLAUDE.md` were corrected to match in the same pass. The
   regenerated file drops the old freeform "Last regenerated: ... because
   ..." note in favour of "run `git log -- FUNCTION_MAP.md`" -- that
   narrative duplicated what commit messages already record, and a
   generated file can't keep writing prose about its own history.

Verified: `tests/source_checks.py` and `tests/balance_tests.py` both
pass (no `scripts/**/*.gd` file was touched by this bundle, so a Godot
boot check doesn't add information here -- this is the one bundle where
that's true). **Not yet verified by Dave:** the `/context` comparison
this bundle's own "Validate" step asks for, and a skim of the new
`docs/`/`.claude/rules/` split to confirm nothing load-bearing reads
wrong out of context.

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

**Done:** all three actions landed, wired slightly more explicitly than
the literal wording above so it holds up across the hive's three cell-
creation sites (the initial comb build, a save restore, and a
player-placed build site) rather than just the common one:

1. `Hive` gained `main: Node2D`, set once by `world_building.gd` right
   after `main.hive = main.Hive.new()`. `HiveCell` gained the same
   `main` field, set at all three sites that call `HiveCell.new()`
   (`hive.gd::_start_site_at`, `world_building.gd::_build_starting_comb`,
   `saving.gd`'s restore loop). `HiveCell._health_factor()` now reads
   `main.season.brood_rate()` directly instead of
   `get_tree().get_nodes_in_group("season")` every frame a cell has
   brood in it. Capturing `main` rather than `season` itself sidesteps a
   construction-order problem: `world_building._build_hive_interior()`
   (which builds the starting comb) runs before `main.gd::_ready()`
   creates `season`, so a cell created at boot would have captured a
   null `season` reference forever; reading `main.season` fresh each
   call means it resolves correctly once `season` exists, regardless of
   which of the three sites created the cell or when.
2. `rg 'egg\.gd|queen\.gd|preload\(.*egg|preload\(.*queen'` outside
   comments/docs turned up nothing (both files only ever appeared in
   their own retirement-notice headers), so both were `git rm`'d
   outright rather than edited first — action 3's "clean up the stale
   `_backups/` reference" is moot once the file holding it is gone.
   Stale references to the two files in `CLAUDE.md`, `AGENTS.md` and
   `ROADMAP.md` were updated in the same pass.

Verified: `tests/source_checks.py` and `tests/balance_tests.py` both
pass; `tools/update_function_map.py --check` (the `main` field shifted
line numbers in `hive_cell.gd`, one of the six mapped scripts) was
re-run and is clean. A full Godot boot via `mcp__godot__run_project`
shows no new parser/type errors, only the same pre-existing
shadowing/unused-parameter warnings already on record. **Not yet
verified by Dave's own hands-on play** — specifically, that disease
still slows brood development the same way it did before (e.g. leaving
a few corpses uncleaned in a run and checking brood still visibly slows
down), since that's the one behavioural path this bundle's change
actually sits on.

---

## Bundle F — Conditional / deferred (do not start without new measurement)

Keep these visible so nobody re-discovers them from scratch. Bundle C is
now closed with real measurements behind it (see its "Step 2
re-measured" note) — one item below has fresh, specific justification
from that; the rest still don't:

- **Mask-texture + canvas-shader fog rendering — landed 19 Aug, code +
  boot check, gated on Bundle C's specific justification.** Bundle C's
  re-measurement confirmed `_draw_fog` remains the dominant frame cost
  at minimum zoom (~29ms dynamic reveal, worst frame 83-96ms) and traced
  it to the opaque-unexplored/dimmed-explored branches of
  `_draw_fog_body`, not fog bookkeeping or tile-walk cost in general —
  see Bundle C's "Clean re-measurement" note.

  **Read only:** `fog_of_war.gd` (`_draw_fog_body`/`_update_mask_texture`
  and the mask-texture fields near the top), `shaders/fog_mask.gdshader`.

  **What changed:** `_draw_fog_body` still walks the same visible tile
  span it always did (same trigger conditions from `_update`'s
  dirty-tracking, unchanged), but instead of merging each row into
  colour runs and issuing one `draw_rect` per run, it writes one byte
  per tile (`MASK_UNEXPLORED`/`MASK_EXPLORED`/`MASK_LIT`) into a flat
  `PackedByteArray`, pushes that into a reused `Image`/`ImageTexture`
  (`_update_mask_texture` — only reallocated when the visible span's
  pixel size changes, e.g. on zoom; same size just overwrites the pixel
  data in place), and issues exactly one `draw_texture_rect` call.
  `shaders/fog_mask.gdshader` (a `ShaderMaterial` on `_layer`, assigned
  once in `_build_layer`) reads the mask texture back into the same
  three-state, two-colour picture the old draw_rect version produced —
  unexplored opaque, explored-dim (or clear if `fog_permanent_reveal`),
  lit fully clear — via three alpha bands on a single-channel float
  read, entirely on the GPU. `UNEXPLORED_COLOR`/`EXPLORED_DIM_COLOR`
  (both `Color8(18, 11, 15, ...)`, only differing by alpha) moved into
  the shader as `fog_rgb` plus the two literal alphas, since nothing in
  GDScript needs them any more.

  Deliberately kept the tile-iteration cost and dirty-redraw triggers
  identical to the previous version — the only variable changed is the
  draw method itself (many `draw_rect` calls vs one `draw_texture_rect`
  call), so a before/after comparison at the same scenario measures
  exactly what this bundle claims to fix rather than conflating it with
  a bigger architecture change. A persistent whole-world mask texture
  (updating only changed pixels, no camera-driven rebuild at all) would
  be a further step but changes more than one thing at once — not done
  here.

  Verified: `tests/source_checks.py`/`tests/balance_tests.py` pass; a
  Godot boot via `mcp__godot__run_project` shows no new parser/type
  errors (same pre-existing shadowing/unused-parameter warnings already
  on record) and ran cleanly with fog on.

  **Bug found by Dave's first hands-on check, same session: fog was
  invisible entirely, toggled on or not.** Root cause: `_draw_fog_body`
  passes `_mask_texture` to `draw_texture_rect`, which binds it to the
  canvas-item shader's built-in `TEXTURE` sampler — but
  `shaders/fog_mask.gdshader` never reads `TEXTURE`, it reads a
  separate custom uniform `mask_tex`, which nothing was ever binding
  via `set_shader_parameter`. An unbound custom `sampler2D` falls back
  to Godot's default white texture, which reads as `1.0` — the shader's
  "currently lit" band (`a = 0.0`) — so every tile drew fully
  transparent regardless of its actual explored/lit state. Fixed same
  session: `_update_mask_texture` now calls
  `_mask_material.set_shader_parameter("mask_tex", _mask_texture)`
  whenever it (re)creates the texture (on the first draw, and on any
  resize). Re-verified: `source_checks.py`/`balance_tests.py` pass, a
  fresh Godot boot is clean.

  **Re-checked by Dave, same session: fog renders correctly** (two
  screenshots, dynamic reveal then `fog_permanent_reveal`) — visual bug
  confirmed fixed. Perf readouts from those same screenshots, not a
  controlled comparison (different days/colony sizes/zoom, not a fixed
  camera the way Bundle C's "Clean re-measurement" was) but still
  informative: Day 1, `fog_of_war_draw` 8ms average / 19ms in the 61ms
  worst frame; Day 3, 12ms average / 15ms in the 41ms worst frame. Both
  well under the old baseline (29ms average, 83-96ms worst frame with
  fog responsible for ~89ms of it) — a strong preliminary result, but
  since day/zoom/colony all differ between the two readings and against
  the original baseline, this isn't proof to the same standard Bundle C
  used.

  **That preliminary read didn't hold up — a Day 11 reading came back
  much worse.** Same session, a further screenshot from Day 11 (a
  bigger colony by then, `fog_permanent_reveal` on): `fog_of_war_draw`
  73ms average / 79ms in a 190ms worst frame; `fog_of_war_update` 74ms
  average / 84ms in that same worst frame. Both are close to or above
  the *old* draw_rect renderer's own worst-case numbers — update in
  particular is far above the 0-3ms Bundle C's shared-offset-disc fix
  was supposed to guarantee regardless of colony size, and this is
  meant to be the *cheap* case (`fog_permanent_reveal` on, which the
  old renderer measured at just 7ms). Two live suspects, neither
  confirmed:
  1. The mask-texture draw walks and uploads every visible tile every
     dirty frame with no early-out for "this whole view is one colour"
     — unlike the old draw_rect version, which skipped drawing entirely
     over transparent (fully-explored/permanent-reveal) stretches. This
     may have traded away the old renderer's one genuinely cheap case
     (mostly-explored view, few draw calls needed) for a flat
     view-tile-count cost that doesn't care what's actually in view.
  2. A bigger colony means more bees crossing `RELIGHT_DISTANCE`
     simultaneously, and disc-application cost is `O(active relights x
     disc_size)` regardless of the shared-offset optimisation — nobody
     has measured that scaling above the ~27-32 bees Bundle C tested.

  **Added diagnostic `Perf` sections rather than guessing between the
  two** (same instrumentation-before-diagnosis approach as the main.gd
  worst-frame investigation): `fog_of_war_draw_build` (the byte-array
  tile loop) and `fog_of_war_draw_upload` (texture creation/update plus
  the `draw_texture_rect` call) split what was one `fog_of_war_draw`
  section; `fog_of_war_relight` (just the `_relight` calls) is now
  nested inside `fog_of_war_update`, isolating disc-application cost
  from the group-query/cleanup-loop bookkeeping around it.
  `tests/source_checks.py`/`tests/balance_tests.py` pass, a fresh Godot
  boot is clean — instrumentation only, no behaviour change.

  **Dave chose to fix both suspects at once** (persistent texture +
  incremental relight) rather than wait for a reading to pick between
  them — see the two follow-up entries below.

  **Draw-side fix: persistent whole-meadow mask texture, replacing the
  per-view rebuild.** The per-view texture covered only the current
  camera view and had no early-out for "this whole run is one colour",
  so its cost tracked view size regardless of how much was actually fog
  — worst in exactly the case (`fog_permanent_reveal` on) that used to
  be cheap under the old draw_rect renderer. Replaced with one
  persistent `_world_mask_image`/`_world_mask_texture` sized to the
  whole meadow (`WORLD_MARGIN` past `main.FLOWER_FIELD_HALF_SIZE`, ~700x556
  tiles at today's field size — a few hundred KB). A new `_paint_tile`
  writes a single pixel into it whenever `_light_center`/`reveal_around`
  change a tile's state, instead of every visible tile being
  redetermined from scratch on every dirty frame. `_draw_fog_body` now
  just uploads the image to the GPU when `_mask_dirty` (only if
  something actually changed since the last upload) and draws whichever
  sub-rect the camera currently frames via `draw_texture_rect_region` —
  panning or zooming costs nothing extra, since it only changes which
  part of an already-current texture gets sampled. `restore()` repaints
  the whole image via a new `_repaint_all`, since a loaded save replaces
  `explored` wholesale and the image's existing pixels reflect the
  previous world. Verified: `source_checks.py`/`balance_tests.py` pass,
  a Godot boot ran ~18s with fog on and no new parser/type or runtime
  errors.

  **Update-side fix: incremental relight, replacing full-disc
  unlight/relight.** `_light_center` used to unlight the whole old disc
  and light the whole new one on every relight, regardless of how far
  the bee actually moved — the Day 11 measurement (44-45ms at 50
  foraging bees) is explained by this: a bee only relights after moving
  `RELIGHT_DISTANCE` (8 tiles), far less than `fog_reveal_radius` (48
  tiles), so consecutive discs overlap almost entirely, and the old code
  paid for the whole disc anyway. A new `_relight_delta` applies only
  the symmetric difference between the old and new disc position: for
  an old-disc tile at offset `off`, it's still covered by the new disc
  iff `off - delta` is itself a valid disc offset (unlight it if not);
  mirrored for a new-disc tile at offset `off` against `delta + off`.
  Still walks the full `_disc_offsets` list twice (so the O(disc_size)
  iteration itself isn't reduced), but skips the `_lit_count`/
  `_paint_tile` writes — the expensive part — for the large majority of
  tiles that don't actually change state. Deliberately not a true
  O(edge) geometric algorithm (per-row circle-boundary maths): that
  would cut the iteration cost too, but is much harder to verify
  correct without eyeballing the reveal shape, and a membership-test
  approach can't produce a different disc shape than `_light_center`
  already did, only reach it with less redundant work. `_light_center`
  (now backed by a shared `_apply_light` helper) still handles a bee's
  first light and a departed bee's full unlight. Verified:
  `source_checks.py`/`balance_tests.py` pass, a Godot boot ran ~12s
  with bees relighting and no new parser/type or runtime errors.

  **Re-checked by Dave at Day 11/50-bee scale, same session: the perf
  fix is confirmed.** `fog_of_war_relight` down to 27ms average / 45ms
  in a 55ms worst frame (was 44-45ms flat, at the same colony size) —
  the incremental-relight fix works as intended. `fog_of_war_draw` no
  longer even appears in the breakdown (negligible) — the persistent
  texture fully decoupled draw cost from view size, as intended.

  **That same check surfaced a real bug: fog "lifting into infinity"
  toward the right/bottom screen edge once a bee neared the meadow's
  own right/bottom edge.** Root cause: `camera_view.gd` clamps zoom
  (`main.MIN_ZOOM`/`MAX_ZOOM`) but never clamps camera *position* —
  nothing stops the camera from panning arbitrarily far, and at low
  zoom near a field edge its view span reaches well past `WORLD_MARGIN`
  into territory the persistent texture was never sized to cover.
  `draw_texture_rect_region`'s `clip_uv` (the draw call's default)
  doesn't simply stop sampling at the texture's edge in that case — it
  stretches the boundary texel across whatever screen space is left,
  which is exactly what "lifts into infinity" describes: a lit/clear
  edge pixel smeared across the rest of the view as the camera's
  requested region grew past real data.

  Fixed same session: `_draw_fog_body` now clamps `min_tile`/`max_tile`
  to the persistent image's actual tile range before building the
  draw/src rects, so the drawn region can never exceed real texture
  data — past the edge, the fix simply draws no fog there, which is
  fine since nothing playable exists past the field anyway. This is a
  general fix, not tied to any particular `WORLD_MARGIN` value — it
  would have been needed regardless of how large the margin was, since
  the camera itself has no hard bound. Verified:
  `tests/source_checks.py`/`tests/balance_tests.py` pass, a fresh Godot
  boot is clean.

  **That clamp fix stopped the stretching but introduced a worse bug —
  Dave's next check found the right/bottom edge revealed by default,
  no bees needed to go there.** Cause: clamping shrank the drawn
  region itself, so whatever part of the camera's view fell outside
  the clamp (common at low zoom, since a view span routinely exceeds
  `WORLD_MARGIN`) just never got a `draw_texture_rect_region` call at
  all — no draw call means nothing hides that ground, reading as
  pre-revealed rather than correctly hidden. The two fixes were opposite
  failure modes of the same underlying gap: relying on the draw call's
  own boundary handling (`clip_uv`'s stretch, or a CPU-side clamp's
  "just don't draw there") for something that needs an actual semantic
  answer — ground outside the mask's real coverage is always
  unexplored, never revealed and never a stretched sample of something
  else.

  **Real fix, same session: moved the bounds check out of GDScript and
  into `shaders/fog_mask.gdshader` itself.** `_draw_fog_body` now
  always draws the camera's whole current view in one
  `draw_texture_rect` call (no more CPU-side clamping, no more
  `draw_texture_rect_region`). The shader receives
  `view_world_pos`/`view_world_size` (this draw's view rect in world
  space, set every draw) and `tex_world_pos`/`tex_world_size`
  (`mask_tex`'s actual world coverage, constant, set once in
  `_build_layer`); each fragment reconstructs its own world position
  from the built-in `UV`, converts that to a `mask_tex` UV, and
  explicitly treats anything outside `[0, 1]` as unexplored before
  ever sampling the texture — the correct semantic answer, computed
  once per pixel, rather than delegated to whichever clipping behaviour
  the draw call happened to have. Verified:
  `tests/source_checks.py`/`tests/balance_tests.py` pass, a fresh Godot
  boot is clean with no shader compile errors.

  **Not yet verified by Dave:** confirm both bugs are actually gone —
  pan/zoom near the meadow's right/bottom edge and check for both the
  stretching and the pre-reveal — and that the reveal shape still
  looks like a clean circle around each bee generally. Once all three
  check out, this item is done.
- **Incremental disc edge updates** (update only the symmetric difference
  between old and new translated discs on a relight). **Not justified** —
  Bundle C step 2's shared-offset cache already dropped
  `fog_of_war_update` to 0-3ms even at the busiest sample measured (27
  bees, min zoom); there's no remaining relight cost left to chase here.
- **`BitMap`/packed fog storage.** Still not justified — no memory
  measurement has been taken, and step 2 didn't touch memory shape
  (still one dictionary entry per lit/explored tile). Only prototype if
  a future memory measurement at high exploration actually shows a
  problem.
- **Fog save-size (RLE/row-run representation).** Still not justified —
  a save-file-size/load-time measurement at high exploration percentage
  hasn't been taken. The flower field alone is ~214,000 possible 5-unit
  fog cells, so a naive one-pair-per-tile JSON *could* get large, but
  that's a different axis (save size) from anything Bundle C measured
  (frame time).
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

## Explicitly do not change (both audits agree, carried forward from `docs/archive/PERF_PLAN.md`'s own findings, also listed in `docs/performance.md`)

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
