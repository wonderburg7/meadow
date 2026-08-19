# Next steps

Read this first in a new session, before anything else in CLAUDE.md. This
file holds only the next 1-3 concrete actions -- it is rewritten (not
appended to) at the end of every build session, so it should never grow
into a history. Full history lives in `git log` and the Notion Build Log.

## Next up

1. **`AUDIT_PLAN.md` Bundle C is now closed** ("measured, partially
   fixed" -- see its own file for the full re-measurement). Short
   version: the shared-offset-disc cache landed and effectively solved
   `fog_of_war_update` (0-3ms everywhere now, was ~27ms at 32 bees).
   `fog_of_war_draw` at normal zoom is fine; at minimum zoom over
   still-mostly-unexplored ground it's still the dominant per-frame cost
   (~71ms, worst frame 36fps/92ms) -- Dave's re-measurement narrowed this
   to specifically drawing opaque unexplored tiles (a same-zoom,
   mostly-revealed view showed no spike). This gives **Bundle F's
   mask-texture/canvas-shader fog rendering item fresh, specific
   justification** -- the other three Bundle F items (BitMap storage,
   incremental disc-edge updates, save-size RLE) still don't have
   measurement behind them; incremental edge updates in particular is
   now explicitly *not* justified since update is already cheap.
   **Next: pick up Bundle F's mask-shader item in a new session/thread**
   -- read `AUDIT_PLAN.md` Bundle F's updated note plus Bundle C's
   "Step 2 re-measured" section first, since that's where the specific
   condition to target (zoomed out, large unexplored margin) and the
   comparison bar (measure against the current run-merged rect renderer)
   are recorded.
2. **Two other audit bundles still need Dave's hands-on check in Godot**
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
3. **Challenge 2 (Brood, Roles and Expansion) has no stage data yet.**
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
  still the dominant cost specifically when the zoomed-out view is
  mostly unexplored ground -- a same-zoom, mostly-revealed view showed
  no spike. Bundle C is now closed; see `AUDIT_PLAN.md`'s own "Step 2
  re-measured" note and Bundle F's updated entry for what that justifies
  next (mask-shader rendering, specifically).
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
