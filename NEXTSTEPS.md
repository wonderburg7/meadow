# Next steps

Read this first in a new session, before anything else in CLAUDE.md. This
file holds only the next 1-3 concrete actions -- it is rewritten (not
appended to) at the end of every build session, so it should never grow
into a history. Full history lives in `git log` and the Notion Build Log.

## Next up

1. **Bundle F's mask-texture/canvas-shader fog item is landed and
   confirmed working.** `fog_of_war.gd::_draw_fog_body` no longer merges
   rows into colour runs and issues one `draw_rect` per run; it writes
   one byte per visible tile into a reused `Image`/`ImageTexture` and
   issues a single `draw_texture_rect`, with `shaders/fog_mask.gdshader`
   (a `ShaderMaterial` on the fog layer) turning that single-channel
   mask back into the same unexplored/dim/lit picture on the GPU. One
   real bug turned up and got fixed along the way -- `draw_texture_rect`
   binds the built-in `TEXTURE` sampler, not the shader's custom
   `mask_tex` uniform, so fog drew fully transparent everywhere until
   `_update_mask_texture` was made to bind it explicitly. Dave's
   playtest (two screenshots, dynamic reveal then `fog_permanent_reveal`)
   confirms fog renders correctly. Perf readouts from those same shots
   look like a strong win over the old baseline -- 8-12ms
   `fog_of_war_draw` average and 15-19ms in-worst-frame here vs the old
   29ms average / 83-96ms worst frame -- but the two shots weren't a
   controlled comparison (different day/colony/zoom, no fixed camera),
   so it's not to the same rigour as Bundle C's own measurement.
   **Optional next step, not blocking:** a same-camera, same-colony,
   min-zoom dynamic-vs-permanent comparison mirroring Bundle C's "Clean
   re-measurement" exactly, if a precise before/after number matters.
   Otherwise this item is done -- see `AUDIT_PLAN.md` Bundle F's entry
   for the full trail.
2. **The separate non-fog worst-frame cost is real, and `perf.gd` has
   hit its ceiling investigating it -- next step is Godot's own
   profiler, not more work here.** Added `Perf.last_worst_ms`/
   `last_worst_breakdown` -- an unsmoothed snapshot of every section's
   time from the exact frame that set the window's worst-ms figure,
   shown as a second "worst frame (Xms): ..." line in
   `perf_breakdown.gd` -- because the existing rolling average couldn't
   explain an 83-88ms spike at all (summed to ~10ms). Also wrapped every
   remaining uninstrumented call in `main.gd::_process()` (`camera_pan`,
   `scenery`, `housekeeping`, `history`, `prune_selection`). Dave's
   re-check gave a clean split: with fog on, the tool fully explained the
   spike (above). **With fog off, a 58ms worst frame still summed to
   only ~2ms across every listed section**, including all the
   newly-wrapped main.gd ones -- meaning that cost isn't happening in
   any GDScript `_process`/`_draw` call at all. Most likely genuine
   engine/render-thread time (vsync/present stall, GPU flush) that no
   CPU-side timer can see. Not blocking anything; if it's worth chasing
   further, that means opening Godot's built-in Debugger > Profiler, a
   different tool entirely.
3. **Two other audit bundles still need Dave's hands-on check in Godot**
   -- can be combined with a future playtest session. `AUDIT_PLAN.md`
   Bundle A and Bundle B have both landed (code + boot check) but
   neither has been played:
   - **Bundle A** (Challenge state safety): start Challenge 1, reach
     stage 1.3, abandon to the main menu partway through the fast build,
     and confirm building a cell in a fresh run afterwards takes the
     normal 90s (not 15s) and that Save/Load were greyed out throughout.
   - **Bundle B** (deterministic restore + guardrails): save and load a
     run with a decent-sized colony and meadow, a few times in a row --
     population counts and flower counts should stay exact, not drift
     upward. Also check the queen panel's "Lay in plain comb too"
     checkbox (only shown while she's laying) still works and stays in
     sync with the same setting in the settings window -- it was rewired
     this session to stop writing `GameConfig` directly (see Bundle B's
     "Done" note in `AUDIT_PLAN.md` for why).
   - Also still open from the tutorial's second bug-fix round (19 Aug):
     see `TUTORIAL_PLAN.md`'s "Built and playable, 19 Aug 2026" note
     (camera framing, queen forager default, right-click commands, the
     1.3 build-cell flow, the 1.7 completion message, the right-click
     ripple and goal readout).
   `python3 tests/source_checks.py`/`balance_tests.py` and a Godot boot
   via `mcp__godot__run_project` all came back clean for all three
   bundles, but nothing here substitutes for Dave actually playing it.
4. **Challenge 2 (Brood, Roles and Expansion) has no stage data yet.**
   The menu entry and `LEVELS[2]` starting-state preset exist
   (`levels.gd`); none of its ten sub-stages, failure conditions or
   Dr Gallerin prompts are written. `challenge_runner.gd`'s `STAGES`
   array is Challenge 1 only so far -- see its own header comment for
   why stage data lives there rather than in `levels.gd`. This is
   naturally the next slice once (1) is confirmed, since it's the
   first thing that will actually exercise `tutorial_checkpoint.gd`'s
   restore path (Challenge 1 has no failure condition to trigger it;
   Challenge 2's does, from sub-stage 2.3 onward per the plan).

## Waiting, lower priority

- **The balance overrides `TUTORIAL_PLAN.md` describes for Challenge 1's
  start state are still not applied** -- no rain, no rival colony, no
  winter, no disease are all just "not yet true" rather than switched
  off. Hasn't caused a visible problem in testing (a 5-10 minute
  Challenge doesn't run long enough to hit most of them), but it's a
  known gap against the written design.
- **Scouting/recruitment split and bee individuality** -- both shipped
  18-19 Aug and were last known to need Dave's hands-on check; neither
  has had a specific correction request since, but neither has had an
  explicit "confirmed working" either -- they've only been exercised
  incidentally while playtesting the tutorial.
- **Re-measure `bee_movement.gd` with `perf.gd`** -- still on the list.
  See "Measuring performance, not guessing at it" in CLAUDE.md before
  touching it -- wrap the widest scope first.
- Depth in what exists: nurse-mediated caste switching, comb temperature,
  multi-storey comb.
- A second hive site to move to.

## Last verified

- `AUDIT_PLAN.md` Bundle F's mask-texture/canvas-shader fog item landed
  19 Aug. `fog_of_war.gd::_draw_fog_body` now writes one byte per visible
  tile into a reused `Image`/`ImageTexture` and issues one
  `draw_texture_rect`, instead of merging rows into colour runs and
  issuing one `draw_rect` per run; a new `shaders/fog_mask.gdshader`
  (assigned as a `ShaderMaterial` on the fog layer in `_build_layer`)
  reads the mask back into the same three-state fog picture on the GPU.
  Tile-walk cost and the dirty-redraw triggers from Bundle C's step 2
  are unchanged -- only the draw method itself changed, so a before/after
  comparison isolates exactly the thing this item claims to fix.
  `source_checks.py`/`balance_tests.py` pass, a Godot boot via
  `mcp__godot__run_project` shows no new parser/type errors and ran
  cleanly with fog on. **Dave's first hands-on check (same day) found
  fog invisible entirely, toggled on or not** -- `_draw_fog_body`'s
  `draw_texture_rect(_mask_texture, ...)` binds the mask to the
  built-in `TEXTURE` sampler, but the shader reads a separate custom
  `mask_tex` uniform that was never bound via `set_shader_parameter`.
  An unbound custom sampler2D falls back to Godot's default white
  texture -- reads as 1.0, the shader's "fully lit" band, so every tile
  drew fully transparent. Fixed same session: `_update_mask_texture`
  now calls `_mask_material.set_shader_parameter("mask_tex",
  _mask_texture)` whenever it (re)creates the texture. Re-run clean
  (`source_checks.py`/`balance_tests.py`, a fresh Godot boot). **Dave
  re-checked, same day: fog renders correctly** (two screenshots,
  dynamic reveal then `fog_permanent_reveal`). Perf readouts from those
  screenshots look like a strong win over the old baseline (8-12ms
  `fog_of_war_draw` average, 15-19ms in the worst frame, vs the old
  29ms average / 83-96ms worst frame) but weren't a controlled
  comparison -- different day/colony/zoom, no fixed camera -- so treat
  as a strong preliminary result, not a rigorous before/after. A
  same-camera, same-colony, min-zoom re-measurement mirroring Bundle
  C's method is optional if a precise number is ever wanted; not
  blocking.
- `perf.gd` gained an unsmoothed worst-frame section breakdown
  (`last_worst_ms`/`last_worst_breakdown`, captured the instant a frame
  raises the current window's worst-ms figure), shown as a second line
  in `perf_breakdown.gd`. Added 19 Aug because the existing
  rolling-average breakdown couldn't explain an 83-88ms worst-frame
  spike at all -- its sections summed to ~10ms, since a single spike
  barely moves a 0.1-lerp average taken across many frames. Also wrapped
  every remaining uninstrumented call in `main.gd::_process()`
  (`camera_pan`, `scenery`, `housekeeping`, `history`,
  `prune_selection`), so the new breakdown can actually account for the
  whole frame instead of leaving an unexplained gap.
  `source_checks.py`/`balance_tests.py` pass, `FUNCTION_MAP.md`
  regenerated (main.gd shifted, twice), a Godot boot shows no new
  parser/type errors. **Checked by Dave, same session -- a clean split
  result.** Fog on: the tool worked exactly as intended, attributing
  89ms of a 96ms worst frame to `fog_of_war_draw`/`fog_of_war_update` --
  see the Bundle C entry above, this also raised the mask-shader item's
  urgency (83ms peak vs the 15ms average previously used to justify it).
  Fog off: a 58ms worst frame still summed to only ~2ms across every
  section, main.gd's newly-wrapped ones included -- so that cost isn't
  in any GDScript `_process`/`_draw` call at all, most likely genuine
  engine/render-thread time. `perf.gd` has reached its ceiling on that
  specific spike; further diagnosis needs Godot's own built-in profiler,
  not more work here. Not blocking anything, logged as a known
  lower-priority open item.
- `AUDIT_PLAN.md` Bundle C step 2 (shared-offset fog cache + dirty-driven
  redraw) landed 19 Aug, gated on Dave's own baseline playtest that
  confirmed `fog_of_war` was a real cost (up to ~130ms `fog_of_war_draw`
  at min zoom, ~27ms `fog_of_war_update` at 32 bees, worst frame
  15fps/65ms). `fog_of_war.gd`'s `_bee_light` now stores a centre tile
  per bee instead of a full translated disc; a shared `_disc_offsets`
  array (rebuilt only if `fog_reveal_radius` changes) is applied via
  `_light_center()`. `_update()` only calls `queue_redraw()` when
  something that affects the drawn output actually changed (a relight,
  the layer becoming visible again, a view switch, or the camera/
  `fog_permanent_reveal` changing) rather than every frame.
  `source_checks.py`/`balance_tests.py` pass, a Godot boot shows no new
  parser/type errors. **Re-measured by Dave the same day** -- confirmed:
  `fog_of_war_update` down to 0-3ms everywhere tested (was ~27ms at 32
  bees); `fog_of_war_draw` down at min zoom (~71ms, was ~130ms) but
  still the dominant cost there with fog genuinely on. A same-session
  comparison then wrongly narrowed that to "specifically unexplored
  tiles" based on a reading that turned out to be a `perf.gd` staleness
  bug (below) -- but a clean redo right after the fix (same colony size
  and camera, dynamic reveal vs `fog_permanent_reveal`) confirmed the
  narrowing was actually correct: 29ms vs 7ms. Bundle C is closed;
  Bundle F's mask-shader item now has clean, specific justification --
  see `AUDIT_PLAN.md`'s "Clean re-measurement" note and Bundle F's
  updated entry.
- `perf.gd`'s corner breakdown used to freeze a section at its last
  reading forever once that section stopped running (e.g. fog toggled
  off), because `_process()`'s averaging loop only updated a section's
  rolling average on frames where it actually ran. Found while
  puzzling over why "fog off" screenshots still showed real-looking
  `fog_of_war_draw`/`fog_of_war_update` numbers during the Bundle C
  re-measurement above -- it was this bug, not a real cost. Fixed same
  session: an inactive section now decays toward zero each frame and
  is erased once negligible, so the breakdown only ever shows what's
  actually running. `source_checks.py`/`balance_tests.py` pass, a Godot
  boot shows no new parser/type errors. Worth remembering for *any*
  future perf reading, not just fog: a toggled-off system's old number
  used to linger and look like an ongoing cost.
- `AUDIT_PLAN.md` Bundle E (small hot-path/housekeeping cleanups) is
  done -- `HiveCell._health_factor()` no longer does a per-frame
  `get_tree().get_nodes_in_group("season")` lookup on the brood-
  development path; `Hive` and `HiveCell` both gained a `main:
  Node2D` field, set at all three sites a `HiveCell` gets created
  (initial comb build, save restore, player-placed build site), so a
  cell reaches `main.season.brood_rate()` directly. Retired
  `egg.gd`/`queen.gd` stubs deleted (`git rm`, confirmed no remaining
  references first); stale mentions of them in `CLAUDE.md`, `AGENTS.md`
  and `ROADMAP.md` cleaned up too. `source_checks.py`/`balance_tests.py`
  pass, `tools/update_function_map.py --check` is clean (regenerated
  after `hive_cell.gd`'s new field shifted its line numbers), and a
  Godot boot via `mcp__godot__run_project` shows no new parser/type
  errors. Dave checked the disease/brood-slowing behaviour on 19 Aug
  during the Bundle C baseline playtest and saw no visible effect after
  a few minutes of leaving larvae uncleaned -- traced to the mechanism
  itself (not this bundle's wiring): `balance_tests.py`'s own pathogen
  model needs `2 bodies, 40 bees in 50 cells` before it sickens, and even
  then takes `3.3 days` at 1x -- by design ("no cost until real
  neglect"), so a short test window plausibly never crossed the 0.35
  disease threshold. `hud.gd`'s comb readout does show
  `Season.disease_text()` when it does cross. Considered closed unless a
  longer/heavier neglect test says otherwise.
- `AUDIT_PLAN.md` Bundle D (Claude/agent context restructure) is done --
  root `CLAUDE.md` trimmed 555 -> 210 lines, history/pitfalls/perf detail
  moved to `docs/`, six completed plan docs archived to `docs/archive/`,
  `.claude/settings.json` + `.claude/rules/*.md` added, and
  `FUNCTION_MAP.md` is now generated by `tools/update_function_map.py`
  (which immediately found the hand-maintained map was stale in four
  files). Docs/config only, nothing under `scripts/` touched, so no
  Godot boot was needed -- `source_checks.py`/`balance_tests.py` both
  pass. Still needs Dave to skim the new `docs/`/`.claude/rules/` split
  and confirm nothing load-bearing reads wrong out of context (this
  bundle's own "Validate" step).
- `python3 tests/source_checks.py` and `python3 tests/balance_tests.py`
  both passing, and a full Godot boot via `mcp__godot__run_project`
  clean (only pre-existing, unrelated shadowing/unused-parameter
  warnings), after splitting `fog_of_war.gd`'s `Perf` instrumentation
  into `fog_of_war_update`/`fog_of_war_draw` for `AUDIT_PLAN.md` Bundle
  C's still-pending baseline measurement -- no behaviour change, prep
  only.
- Same two checks and boot, after landing `AUDIT_PLAN.md` Bundle B. The new
  `check_gameconfig_writes` guardrail was confirmed to actually fire
  (tested with a temporary stray write, then reverted) before this was
  called done.
- Every script in `scripts/` also checked with `gdlint`/`gdparse`
  (`gdtoolkit`, pip-installed locally, not a project dependency) as of
  19 Aug -- catches real parser/type errors that `source_checks.py`
  alone can't (it only checks names/brackets, not scope or type
  inference). Two real bugs were caught and fixed this way before
  reaching Dave: a leftover cross-scope reference in `hud.gd`, and a
  `:=` type-inference failure on a loosely-typed `main.X` reference in
  `input_selection.gd` -- see `bee_survival.gd`'s `_announce_death`
  pattern (`main.DeathMarker.new()`, plain `=`) for why that class of
  assignment has to skip `:=`.
