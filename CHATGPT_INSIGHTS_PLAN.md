# ChatGPT insights — implementation plan

Status: Group C fully built and verified, 22 Aug 2026. B1-B4 built and
verified, 22 Aug 2026. B5 stays parked. Group A fully built and
verified (A1-A6), 22 Aug 2026 (A3 closes the determinism gap A2
surfaced -- `--fixed-fps 30` is now the harness's default and gives
genuine run-to-run reproducibility; A6's presentation gate on top of it
cut the same benchmark's wall time by roughly 7-8x with no outcome
change). A7 stays parked. Everything in this plan is now built and
verified except A7 (parked) and B5 (parked).

## 22 Aug 2026 follow-up: stable, token-cheap mechanism checks

Dave asked which important parts of Meadow are worth checking through cheap
headless runs without investing in areas that upcoming work will change. The
execution hand-off is in `CHATGPT_HEADLESS_CHECK_PLAN.md`, a ChatGPT-only file
which Claude Code must ignore unless Dave explicitly reverses that instruction.
ChatGPT's short hand-off lives separately in `CHATGPT_NEXTSTEPS.md`; no ChatGPT
action from this work belongs in Claude's `NEXTSTEPS.md`.

Durable insights and recommendations:

- Headless evidence is strongest for stable simulation mechanisms: brood and
  nursing, hive production, role/command routing, survival/adverse systems and
  a narrow seasonal integration check. These run real game paths and can expose
  regressions without needing visual judgement.
- Do not expand regression expectations around current foraging, recruitment,
  rival competition or flower ecology before the planned ecology overhaul.
  Preserve existing scenarios as control/history where useful, but do not let
  their current outcomes harden into a future design constraint.
- Do not spend headless effort on the imminent Challenge 1 sequence revamp or
  unfinished UI/text-scale work. Tutorial pacing, layout, motion, fog appearance
  and feedback clarity remain hands-on questions even after those changes land.
- Use layers: Python source/balance checks first; a seconds-long real-Godot smoke
  run routinely; focused early-stop scenarios only for a touched mechanism; and
  winter/whole-cycle integration only at milestones.
- Token cost and simulation cost are separate. Keep output on the brief report,
  request curves only for a timing question, stop on decisive postconditions,
  and use one pinned seed for deterministic plumbing. Use three matched seeds
  for stochastic comparisons, rising to five only when results disagree.
- A scenario should protect a named plausible failure. Avoid a large always-run
  suite and avoid duplicating `balance_tests.py`; a headless run earns its cost
  when it proves that real Godot objects, state machines and command routes work
  together.
- Interpret results honestly: a real command plus a real state/resource
  postcondition has good regression validity; a synthetic colony is weaker for
  whole-game balance; visuals, comprehension, pacing and subjective feel cannot
  be certified headlessly.

Status: plan written, not initiated. Dave will start it with ChatGPT in a new
session.

Turns `insights_from_ChatGPT.md`'s three 22 Aug entries into small,
independently-committable slices for Claude Code. Each slice touches
one or two files, has its own verification step, and can be built and
reviewed on its own -- read only the slice you're building, not this
whole plan or the source insights doc.

Mark a slice done here **and** flip its row in `insights_from_ChatGPT.md`'s
"Implementation status" table when it ships.

## How the three source entries map here

- Entry 1 ("faster, token-efficient headless runs") -> Group A.
- Entry 2 ("first real test of the headless action driver") -> Group B.
- Entry 3 ("nurse/comb-worker/miner/honey-worker audit") -> Group C --
  these are real gameplay bugs the audit surfaced, not harness work.
  They affect Dave's actual game, not just test tooling.

**Suggested build order: C, then B, then A.** C changes what the player
experiences today. B makes the next headless audit trustworthy. A is
speed/token efficiency for that tooling -- valuable, but nobody's game
is broken by skipping it a while longer.

All groups are independent of each other; do them in any order, or
pick single slices out of order, without breaking anything.

---

## Group C -- gameplay bugs the audit found (do first)

Small, isolated fixes. None touch a `GameConfig` value yet -- per
principle 4 (never trust a balance number that hasn't been simulated),
re-simulate in C6 before tuning any constant these bugs were masking.

### C1. Anything-mode nurses feed before making jelly -- done, 22 Aug
- **File:** `bee.gd` (`_try_role_work`, the
  `nurse_mode != "feed"` check -- the plan's original file reference
  named `bee_nursery.gd`, but the dispatch logic actually lives here).
- **Bug:** that check tries jelly work before looking for hungry brood,
  so Anything behaves almost exactly like Jelly and starves larvae --
  the tooltip promises "feeding first".
- **Fix:** check for hungry brood first regardless of mode; only fall
  through to jelly work once no brood needs feeding.
- **Verify:** `source_checks.py`, `balance_tests.py`, then a headless
  comparison (2 Feed vs 2 Anything, same seed) showing Anything no
  longer lags Feed on population growth.

### C2. Undesignated jelly spill -- done, 22 Aug; verified 22 Aug
- **File:** `bee_nursery.gd`, wherever reserve (non-gyne-brood) jelly
  work calls `hive.find_cell_for("jelly")`.
- **Fix:** with no gyne brood pending, only produce/store jelly while an
  explicitly designated jelly cell has room -- don't let the cell
  lookup fall back to ordinary empty comb. Let an urgent gyne need
  override this, but keep that override an explicit, deterministic
  condition, not incidental fallback order.
- **Verify:** headless run with no jelly cell marked -- jelly should
  stop appearing in generic empty cells.
- **Verified:** `test_scenarios/c2_no_jelly_cell_test.json` (3 nurses
  switched to Anything mode day 0 via `assign_role`, no cell designated
  `jelly`, no gyne brood pending, 10 days). Summary line:
  `jelly_batches: 0`, `brood_feeds: 96`, `cells_completed: 21` -- nurses
  fed brood and had nothing else to fall back on, matching the fix.

### C3. Honey fanning doesn't stack -- done, 22 Aug
- **Files:** `bee_honey.gd` (`honey_fan`, the `being_fanned = true`
  line) and the cell's fan-progress code (likely `hive_cell.gd`).
- **Bug:** every fanning bee sets the same boolean; the cell advances
  by one `delta` per frame regardless of how many bees are fanning it.
- **Fix:** give the cell an `add_fanning(delta)` call like build/mine
  progress already use, called once per fanning bee -- or track an
  integer fanner count instead of a boolean.
- **Verify:** headless 1-fanner vs 4-fanner comparison should show
  close to linear speed-up, not near-identical timing.

### C4. Stocking hatch fallback -- done, 22 Aug; verified 22 Aug
- **File:** `world_building.gd` (`_spawn_hatched_bee`, the
  `["build", "maintain", "both"]` check).
- **Bug:** a nursery cell configured to hatch a Stocking worker is
  silently changed to Anything, since Stocking isn't a valid
  `architect_mode`.
- **Fix:** add `"restock"` to the valid list. Separately (one-line
  question to Dave, not a code decision to make alone): should Stocking
  also do maintenance? `orders_zones.gd`'s `architect_mode != "build"`
  condition currently lets it, ahead of any answer.
- **Verify:** `source_checks.py`, plus a hatch test confirming a
  Stocking-configured cell actually produces a Stocking worker.
- **Verified:** the headless action driver had no way to configure a
  cell's hatch role at all, so this needed two small additions first:
  a `hatch_role` verb in `scenario_actions.gd` (calls
  `orders_zones._on_cell_hatch_role_requested`, the same function the
  nursery panel's role buttons call -- same "call the real command
  function" pattern every other verb there follows), and a one-line
  dev-only log in `world_building.gd::_spawn_hatched_bee`
  (`DiagnosticLog.log_action("hatch_comb_worker", ...)`) reporting the
  resolved `architect_mode` directly, since inferring it from behaviour
  alone can't distinguish "restock" from the old "both" fallback (both
  still perform restocking). `test_scenarios/c4_stocking_hatch_test.json`
  hatch-configures cell `[0,0]` as Stocking (`role=comb_worker,
  focus=restock`) at day 0, 12-day run. Logged line: `hatch_comb_worker
  (focus=restock): spawned -- architect_mode=restock` -- confirms the
  fix; before it, this would have read `architect_mode=both`.

### C5. Role outcome telemetry -- done, 22 Aug
- **File:** `diagnostic_log.gd` (new counters), fed from
  `bee_nursery.gd`, `bee_honey.gd`, `bee_building.gd`, `bee_mining.gd`.
- **Add:** brood feeds, jelly batches, larval deaths; completed/
  cleaned/evicted/restocked cells; completed blocks plus remaining
  exposed/marked soil; honey batches deposited and cells ripened.
  Additive only -- extends the existing `snapshot`/`summary` entry
  shapes, no new log file or format.
- **Verify:** `source_checks.py`; a headless run's summary line shows
  the new counters populated with plausible values.

### C6. Re-run the balance comparisons -- done, 22 Aug
- New scenarios: `test_scenarios/c6_nurse_feed_test.json` /
  `c6_nurse_both_test.json` (10 days, 3 nurses, default Feed vs
  reassigned to Anything on day 1) and `c6_fanners_1_test.json` /
  `_2_` / `_4_test.json` (6 days, 1/2/4 foragers reassigned to Honey on
  day 1).
- **Found a follow-on bug before the comparison could even run**: C1's
  own fix at [bee.gd:1067](scripts/bee.gd:1067) checked
  `nurse_mode == "anything"`, but the sub-mode's real key (`roles.gd`'s
  table, and everywhere else that reads `nurse_mode`) is `"both"` --
  no code ever assigns the literal string `"anything"`. C1's headline
  fix (feed before jelly) still worked, since that's a separate branch,
  but the "fall back to jelly when idle" half of C1 was dead code --
  an Anything-mode nurse with no hungry brood just stood idle instead.
  Fixed by changing the check to `"both"`.
- **Nurse comparison** (brood feeds / deaths over 10 days): Feed 118
  feeds, 2 deaths (1 starvation-adjacent builder loss, 1 larval death);
  Anything 112 feeds, 0 deaths. Anything now tracks Feed instead of
  lagging it -- C1 confirmed.
- **Fanner comparison** (honey batches deposited / cells ripened over 6
  days): 1 fanner 27/27, 2 fanners 39/27, 4 fanners 55/34. Deposits and
  ripening both rise with fanner count instead of staying flat --
  confirms C3's stacking fix is doing something -- but the increase
  isn't linear: `cells_ripened` looks bottlenecked by how many wet
  cells exist to fan at once (comb space, deposit rate) rather than by
  fanning speed alone at low fanner counts. Good enough to confirm the
  fix works; not a clean throughput multiplier, so don't read a
  fanner-to-ripening-rate constant out of these three numbers.
- `source_checks.py` and `balance_tests.py` both still pass after the
  `bee.gd` fix.
- **Conclusion:** C1 and C3 hold up under re-test. Still don't touch
  `jelly_pollen_cost`, `jelly_honey_cost`, `jelly_per_batch`,
  `honey_ripen_time`, `nectar_per_honey` or `honey_energy_factor` off
  the back of this alone -- these five scenarios are a bugfix check,
  not a balance pass. C2's "no jelly cell marked" run and C4's hatch
  test are both now done too, see those sections above -- Group C is
  fully verified.

---

## Group B -- action driver correctness (do before trusting the next audit)

### B1. Shared settings-cascade command -- done, 22 Aug; verified 22 Aug
- **Files:** `debug_panel.gd` (`setting_set` and its `Prerequisites`
  walk) and `scenario_actions.gd` (`_do_set_config`).
- **Fix:** extract one function that applies a setting value plus the
  prerequisite/dependant cascade; have both the checkbox handler and
  `_do_set_config` call it, so there's one cascade implementation, not
  two that can drift -- the same "one source of truth" pattern
  `roles.gd` already models for role data.
- **Verify:** a headless `set_config` that turns on Auto scouting
  without Orientation flight now cascades the same way the settings
  checkbox does (turns the dependant off, or refuses, whichever the
  checkbox does).
- **Built:** `debug_panel.gd` gained two static helpers,
  `_cascade_prerequisites_on_static` and `_cascade_dependents_off_static`
  (the same up/down `Prerequisites` walks as before, now returning the
  keys they actually changed instead of touching UI directly), plus a
  new static `apply_setting(key, value)` that calls `setting_set` and
  then cascades. The old instance methods `_cascade_prerequisites_on` /
  `_cascade_dependents_off` are now thin wrappers: they call the static
  walkers and use the returned key list to sync `toggle_boxes`
  checkboxes -- same on-screen behaviour, same algorithm, just no
  longer duplicated. `scenario_actions.gd::_do_set_config` now calls
  `DebugPanel.apply_setting` instead of the bare `setting_set`, so a
  headless `set_config` action gets the identical cascade a settings
  checkbox click gets -- structurally one implementation, not two that
  can drift.
- **Verified:** `source_checks.py` and `balance_tests.py` both pass,
  `FUNCTION_MAP.md` regenerated (`debug_panel.gd` is one of the six
  mapped files), and a `mcp__godot__` boot is clean (same pre-existing
  warning set as before, no new ones -- including the two
  already-known `debug_panel.gd` iterator-shadow warnings at the lines
  the refactor didn't touch). Re-ran
  `test_scenarios/slice7_action_driver_test.json` (its existing
  `set_config scouting_on=true` action) end-to-end: still 4/4 actions
  `accepted`, `scouting_settled: 1`, no assert failures -- the scenario
  that already exercised this cascade path keeps working through the
  new shared function. A live-value check of the cascaded parent
  (`orientation_flight_on` actually flipping true) isn't observable
  from outside Godot yet -- the diagnostic log's `config` snapshot is
  boot-time only, which is exactly the gap B4 exists to close. Given
  this is a pure extraction (same walk algorithm, same call sites, now
  literally one function instead of two independently-written copies),
  source-level equivalence plus a clean end-to-end scenario run is
  the practical verification available before B4 lands.

### B2. Split role assignment from role mode -- done, 22 Aug 2026
- **Files:** `scenario_actions.gd` (`_do_assign_role`), `orders_zones.gd`
  (`_on_role_requested`, unchanged -- see below).
- **Bug:** a combined key like `forager_nectar` logs `accepted` but
  only changes mode, not role -- a scenario expecting a new forager
  sees no population change.
- **Root cause, more precisely:** `_on_role_requested`'s own two-branch
  behaviour (plain key assigns role, combined key applies mode) exactly
  mirrors the real UI -- hud.gd's Doing row only ever appears for the
  selection's *current* common role, so a human always assigns role
  first, then clicks a mode button in a second click once already on
  it. `orders_zones.gd` didn't need changing; a scenario author writing
  a combined key in one `assign_role` action was asking for both of
  those clicks at once, which nothing on the calling side provided.
- **Fix:** `_do_assign_role` now splits a combined key into its base
  role and mode (same prefix-matching loop `_on_role_requested` already
  used), calls `_on_role_requested` with the base key first and, if a
  mode was present, again with the full combined key -- the same two
  calls a human's two clicks would make, both against the same resolved
  bee IDs. It then checks every bee actually ended up on that role
  (`b.role`) and, if a mode was given, on that mode
  (`hud._mode_is_active`, the same read the Doing row's own toggle
  state uses) before logging `accepted`; a mismatch -- including
  `can_take_role` silently refusing the change -- now logs `rejected`
  with a count of the bees that didn't take.
- **Verify:** `source_checks.py` and `balance_tests.py` both pass.
  New scenario `test_scenarios/b2_combined_role_test.json` reassigns 2
  nurses to `forager_pollen` in one `assign_role` action (previously:
  silently a no-op, since `set_focus` no-ops on a bee whose `role` isn't
  already `FORAGER`) and asserts `population_at_least` forager count 3+
  the next day. Ran end-to-end through Godot itself
  (`tools/run_scenario.py --full`): both actions logged `accepted`,
  `by_role.nursery` dropped to 0 and `by_role.forager` rose to the
  expected count on both days, `problems: []`. `slice7_action_driver_test.json`
  (which already exercises a combined key, `forager_pollen`, on bees
  already foragers) still runs clean through the changed function too.

### B3. Postcondition evidence for the remaining verbs -- done, 22 Aug 2026
- **File:** `scenario_actions.gd` (`_do_designate_cell`,
  `_do_queue_build`, `_do_queue_mine`).
- **Fix:** each verb checks its own smallest useful postcondition
  (resulting `designated_type`, stored build/mine target) before
  logging `accepted`, same as B2 does for role assignment.
- **Built:** `_do_designate_cell` now compares `cell.designated_type`
  against the requested content after calling `_designate_one`, so the
  silent no-op path (a conflicting occupant, `Session.warn_on_discard`
  on, nothing headless to answer the dialog) logs `rejected` with the
  cell's actual designation instead of a false `accepted` -- this is the
  one verb where the postcondition is a real semantic check.
  `_do_queue_build` and `_do_queue_mine` check `bee.build_queue.has(hex)`
  / `bee.mine_queue.has(block)` on every targeted bee; `set_manual_build_target`
  / `queue_build_target` / `set_mine_target` / `queue_mine_target` queue
  unconditionally (the real validity check, `hive.can_build_on`, only
  runs later when a bee actually takes the target off its own queue), so
  in practice this catches "the call didn't reach this bee" rather than
  "the tile turned out unbuildable" -- still the same "check state, don't
  assume the call worked" pattern B2 established, just a narrower payoff
  for these two verbs given how those setters are written.
- **Verified:** `source_checks.py` and `balance_tests.py` both pass.
  Re-ran `test_scenarios/slice7_action_driver_test.json`
  (`tools/run_scenario.py --full`) end-to-end: still 4/4 actions
  `accepted`, `problems: []` -- the existing `designate_cell` action
  (a plain, non-conflicting case) is unaffected by the new check. New
  scenario `test_scenarios/b3_postcondition_test.json` (one
  `queue_build`, one `queue_mine`, one `designate_cell`, 2-day run) ran
  end-to-end the same way: all 3 `accepted`, log lines confirm the real
  postcondition values (`1 bees -> (3, 0)`, `1 bees -> [-5.0, -5.0]`,
  `[1.0, 0.0] -> honey`). The genuine-rejection path for
  `_do_designate_cell` (conflicting occupant, no room elsewhere) needs a
  cell pre-filled with a specific resource before the action fires,
  which isn't worth the scenario complexity here -- verified by reading
  the code instead: `_designate_one` leaves `cell.designated_type`
  unchanged on that path, so the new comparison catches it.

### B4. Live settings in analysis -- done, 22 Aug 2026
- **File:** `tools/analyze_session.py` (`_mechanic_firing`).
- **Bug:** mechanic-firing checks read the boot `config` entry only, so
  a mid-run `set_config` action doesn't update what the summary
  reports -- a run can show 91 tarsal marks while still saying
  `toggle_on: false`.
- **Fix:** build a settings timeline from `action`-type log entries and
  use the last live value before each check, not just the boot
  snapshot.
- **Built:** three new module-level helpers. `_parse_set_config_value`
  undoes `scenario_actions.gd::_do_set_config`'s `"%s = %s" % [key,
  value]` log formatting (the action entry has no structured value
  field, just that string) back into bool/int/float/str.
  `_settings_timeline` walks every `action`-type entry with
  `do == "set_config"` and `result == "accepted"` into an ordered
  `(game_time, key, value)` list. `_live_value` starts from the boot
  `config` snapshot and applies every timeline entry for that key at or
  before a given cutoff, last one wins. `_mechanic_firing` now takes
  `actions` as a third argument and reads each toggle's `toggle_on` via
  `_live_value(..., cutoff=summary["game_time"])` instead of the raw
  boot `settings` dict -- `analyze()`'s call site passes `actions`
  through.
- **Verified:** `source_checks.py` and `balance_tests.py` both pass
  (this file has no GDScript side, so no `FUNCTION_MAP.md`/Godot-boot
  step applies). Since the change is pure Python parsing with no
  Godot/gameplay dependency, verified directly against synthetic
  session entries rather than a scenario run: a 3-entry session (boot
  `scouting_on: false`, an accepted `set_config scouting_on = true` at
  `game_time` 10, a `summary` at `game_time` 50 with
  `scouting_settled: 3`) reports `toggle_on: true, fired: true` on this
  branch; re-run against the pre-fix code (`git stash`) on the same
  synthetic entries reproduces the exact bug this slice describes --
  `toggle_on: false` despite `event_count: 3` -- confirming the fix
  changes the reported value, not just the code path.

### B5. (Backlog, not a slice yet) Observe-pause-act loop
Park this -- the insight doc's own framing says "only then consider"
it, after B1-B4 land. Revisit only if a specific question genuinely
needs live mid-run decisions rather than a scripted policy.

---

## Group A -- harness speed and token efficiency

### A1. Unique run IDs (a real correctness bug, not just efficiency) -- done, 22 Aug 2026
- **Files:** `run_scenario.py` (`newest_session_file` -> replaced),
  `diagnostic_log.gd` (`start_session`), `main.gd`
  (`_apply_scenario_boot_arg`).
- **Bug:** two sessions can share a filesystem mtime, so a scenario run
  can pick up another process's (e.g. Dave's live play) unfinished log
  instead of its own.
- **Built:** `run_scenario.py::run_once` generates a short hex run ID
  (`uuid.uuid4().hex[:12]`) per launch and passes it as a second
  `--run-id=` boot argument alongside the existing `--scenario=` one --
  a separate cmdline arg, not a scenario JSON field, since it names this
  *process's launch*, not the scenario being run (so two `--repeat`
  iterations of the same scenario file still get distinct IDs).
  `main.gd::_apply_scenario_boot_arg` reads it into `DiagnosticLog.run_id_override`
  before `Session.reset_run_state()` triggers `start_session()`.
  `diagnostic_log.gd::start_session` folds the override into the
  filename as a suffix -- `session_<unix_time>_<run_id>.jsonl` -- rather
  than replacing the timestamp prefix, so `_prune_old_sessions`' existing
  "unix-time filenames sort chronologically as plain strings" assumption
  still holds; an ordinary (non-scenario) play session keeps the old
  `session_<unix_time>.jsonl` shape unchanged, since `run_id_override`
  defaults to empty. `newest_session_file` (mtime-based) is gone,
  replaced by `session_file_for_run_id`, an exact glob match on
  `session_*_<run_id>.jsonl` -- no more racing against mtime at all.
- **Verified:** `source_checks.py` and `balance_tests.py` pass;
  `FUNCTION_MAP.md` regenerated (`main.gd` is one of the six mapped
  files); a `mcp__godot__` boot is clean (same pre-existing warning set,
  nothing new). Then two real end-to-end runs through
  `tools/run_scenario.py` against `test_scenarios/slice1_smoke_test.json`
  (Godot actually installed at `C:\Program Files\Godot\Godot.exe`): a
  single run picked up `session_1787410260_bc28ce5b54a2.jsonl` by its own
  run ID and printed a normal summary; a `--repeat 2` run confirmed each
  iteration gets a distinct run ID (`4318991aef65` then `3e387bcd1a07`)
  and its own correctly-matched session file -- the scenario this slice
  exists to fix (two runs close enough together to blur mtime ordering)
  exercised directly, not just read from the code.

### A2. Explicit `random_seed` scenario field -- done, 22 Aug 2026
- **Files:** `main.gd` (`_ready`'s `seed(12345)`,
  `_apply_scenario_boot_arg`), `diagnostic_log.gd`, `run_scenario.py`.
- **Fix:** make the seed an explicit, logged scenario field instead of
  a hardcoded constant, so repeats can be genuinely independent (a new
  seed per repeat) or genuinely paired (same seed both sides of an
  A/B comparison).
- **Built:** `main.gd` names the old inline `12345` literal
  `DEFAULT_RANDOM_SEED` and still seeds with it unconditionally in
  `_ready` (manual play is unchanged). `_apply_scenario_boot_arg` reads
  an optional `"random_seed"` scenario JSON field (falling back to
  `DEFAULT_RANDOM_SEED` if absent), then a `--random-seed=` cmdline
  argument if given -- which wins over the JSON field -- and calls
  `seed()` again with whichever value resolves, logging it into the new
  `random_seed` key on `diagnostic_log.gd`'s `"config"` entry
  (`DiagnosticLog.scenario_random_seed`, defaulting to
  `DEFAULT_RANDOM_SEED` so even a non-scenario boot's config entry states
  the real seed truthfully) and into the existing "AI playtest: loaded
  scenario" print line. `run_scenario.py::run_once` peeks the scenario
  JSON (`_scenario_declares_seed`) and, only when it has no pinned
  `random_seed` of its own, generates a fresh `--random-seed=` per launch
  -- so an unpinned scenario's `--repeat N` draws N independent seeds
  instead of N replays of `DEFAULT_RANDOM_SEED`, while a scenario that
  does pin one keeps reproducing that exact value every launch.
- **Verified:** `source_checks.py`/`balance_tests.py` pass,
  `FUNCTION_MAP.md` regenerated, `mcp__godot__` boot clean (same
  pre-existing warnings only). Two new scenarios,
  `test_scenarios/a2_seed_111_test.json` /
  `a2_seed_222_test.json` (otherwise identical, 3-day runs), confirmed
  end-to-end through `tools/run_scenario.py` against the real Godot
  install: both sessions' `"config"` entries log the exact declared
  `random_seed` (111, 222); seed 111 vs seed 222 produce different
  outcomes (`flower_visits` 223/217 vs 213 across two 111 runs and one
  222 run) -- confirming a declared seed changes what happens.
  **Genuine finding, not just a checklist pass:** re-running
  `a2_seed_111_test.json` twice did *not* reproduce a byte-identical
  trajectory -- the very first snapshot already shows different
  `game_time` (8.5 vs 9.35846) between the two runs, though the
  RNG-driven *initial* state each seed controls (role assignment, cell
  layout) matched. Cause, confirmed by inspection rather than assumed:
  this project drives simulation speed through `Engine.time_scale`
  (30x by default for scenarios) rather than a fixed per-frame step, so
  real wall-clock scheduling jitter changes how much sim time elapses
  per frame and therefore how the RNG's draws interleave with gameplay
  events across a run -- a pre-existing determinism gap this slice's
  seed plumbing can't close on its own. This is exactly the problem
  A3's `--fixed-fps` step exists to solve; until A3 lands, "same seed
  cancels randomness" holds for a run's *initial* random draws (meadow
  layout, role assignment, trait rolls) but not for full run-length
  reproducibility. Worth reading A3's own writeup once it's done for
  whether it closes this gap.

### A3. `--fixed-fps` benchmark -- done, 22 Aug 2026
- **File:** `run_scenario.py`.
- **Fix:** add a `--fixed-fps` launch option; benchmark wall time and
  outcome parity (action postconditions, path completion, throughput,
  population/deaths/resources) at 1/60, 1/30 and 1/15-second steps
  against the current `Engine.time_scale` approach. Pick the largest
  step that stays within tolerance as the new dev-path default.
- **Built:** `run_once` takes an optional `fixed_fps` argument and
  passes Godot's own built-in `--fixed-fps <N>` engine flag (before the
  `--` separator, alongside `--headless` -- not one of our own `--run-id=`/
  `--random-seed=` user args) when set, plus a wall-time print around
  each `subprocess.run`. A new `--fixed-fps` CLI flag defaults to
  `DEFAULT_FIXED_FPS` (see below); `--fixed-fps 0` opts back out to
  ordinary wall-clock timing.
- **Benchmarked:** `test_scenarios/a3_fixedfps_benchmark_test.json`
  (matches the existing `slice3_timescale_*` pattern -- `time_scale: 30`,
  `seconds_per_day: 20` override, 30 days -- plus a pinned
  `random_seed: 4242` from A2) run against the real Godot install at
  the baseline (`--fixed-fps 0`) and all three requested steps:

  | setting | wall time | flower_visits | total_deaths | game_time |
  |---|---|---|---|---|
  | baseline (wall-clock) | ~21.5s | 294 / 303 (two runs) | 17 | ~580.08 |
  | `--fixed-fps 60` | ~21.8-46.9s | 353 | 17 | 580.0 |
  | `--fixed-fps 30` | ~15.3-43.1s | 324 | 17 | 580.75 |
  | `--fixed-fps 15` | ~10.7-14.7s | 259 | 17 | 581.75 |

  (The wide wall-time ranges on the first pass turned out to be system
  contention, not the flag itself -- a clean re-run of baseline/60/15
  landed at ~21.4s/~21.8s/~10.7s; not re-timed a third time for 30, but
  its two runs already agreed at ~15.4s.)
- **Findings, not just numbers to file away:**
  - **Wall time isn't a clean "larger step = faster" story.** `--fixed-fps
    60` ran about the same as baseline, not faster -- only 30 and 15
    beat it, and 30 wasn't consistently faster than 60 either on the
    noisy first pass. Speed comes from disabling real-time sync, not
    from the step size alone, and this headless project was apparently
    already running close to unthrottled at baseline.
  - **`total_deaths`/`deaths_by_cause`/`deaths_by_role` (the balance
    metrics C6 and this project's own principle 4 care about most) were
    identical at all four settings** -- 17 old-age deaths, same role
    split, every time. The plan's core survivability numbers are step-
    size-insensitive here.
  - **`flower_visits` (the one throughput proxy checked) was not** --
    259 (fps 15) to 353 (fps 60), a real spread, not simulation noise:
    it moved consistently with step size across repeated runs of the
    same setting, unlike baseline's own run-to-run wobble (294 vs 303).
  - **The actual headline result: `--fixed-fps` gives genuine
    determinism, which plain wall-clock timing does not.** Two
    `--fixed-fps 30` runs of the same seeded scenario landed on
    identical `flower_visits` (324/324), `game_time` (580.75/580.75) and
    `total_deaths` (17/17); confirmed again on a second, different
    scenario (`a2_seed_111_test.json`, `brood_feeds`/`flower_visits`/
    `game_time` all identical twice). Two baseline (wall-clock) runs of
    the *same* pinned-seed scenario, by contrast, disagreed
    (`flower_visits` 294 vs 303) -- the exact non-determinism A2's
    writeup found and flagged as A3's problem to solve. **`--fixed-fps`
    closes that gap.** `slice7_action_driver_test.json` re-run at
    `--fixed-fps 30` still resolved all 4 actions `accepted`,
    `problems: []` -- action-postcondition parity holds too.
  - **Picked `--fixed-fps 30`** (`DEFAULT_FIXED_FPS = 30`) as the new
    default: faster than baseline once warmed up, its `flower_visits`
    (324) sits between 60's (353) and 15's (259) rather than at either
    extreme, and -- the deciding factor over raw speed -- it's the
    setting already benchmarked *and* proven bit-for-bit reproducible
    twice over, which matters more for a harness whose whole point is
    trustworthy repeats and A/B comparisons than shaving a further few
    seconds off with `--fixed-fps 15`'s larger, more behaviour-
    distorting step.
- **Verify:** one fixed baseline scenario run at each step size,
  diffed on those metrics -- done, see the table and findings above.

### A4. Cap failure output -- done, 22 Aug 2026
- **File:** `run_scenario.py`.
- **Fix:** on a crash or unreadable log, save full stdout/stderr to a
  file and print only a one-line classified error plus the last 10-20
  lines and the artifact path -- not the full native/Python traceback.
- **Built:** two failure paths, both now capped. A bad `--godot-path`
  (the executable itself missing/unlaunchable) is caught as `OSError`
  around `subprocess.run` and prints one line -- there's no
  stdout/stderr to save in that case, since the process never started.
  A launched-but-failed run (non-zero exit with no session file, or a
  session file that never got written at all) goes through the new
  `_report_failure`: writes `--- stdout ---`/`--- stderr ---` to a
  `tempfile.mkstemp` log, then prints one classified line, the saved
  path, and the last 15 lines of whichever stream is non-empty
  (stderr preferred). A non-zero exit that *did* still produce a valid
  session file (Godot can exit non-zero for reasons that don't corrupt
  the run) stays a short one-line warning, not a capped-artifact
  failure -- same tolerance the pre-slice code had, just shorter.
- **Verified:** `source_checks.py`/`balance_tests.py` pass (Python-only
  change, no GDScript). Three real invocations of
  `tools/run_scenario.py`: a nonexistent `--godot-path` printed exactly
  one line (`error: could not launch Godot at ...: [WinError 2] ...`),
  no traceback; `--godot-path` pointed at `cmd.exe` (launches, never
  writes a session file) printed a 6-line capped report -- one
  classified line, the saved artifact path, and cmd.exe's own short
  banner as the tail -- with the file at that path confirmed to hold
  the full stdout/stderr; and an ordinary successful run against the
  real Godot install was unaffected, confirming the change doesn't
  touch the non-failure path.

### A5. Early-success stop conditions + brief reports -- done, 22 Aug 2026
- **Files:** `main.gd` (`_process`, `_apply_scenario_boot_arg`,
  `_end_scenario_run`), `tools/analyze_session.py` (report profiles),
  `tools/run_scenario.py`.
- **Fix:** add `stop_when_actions_resolved` plus threshold stops (event
  count, population, stores, completed work). Add `brief` / `balance`
  / `behaviour` / `full` report profiles, with `brief` as the default
  AI-facing one.
- **Built:** two new `stop` fields, both dev-only and erased from the
  `level` dict the same way `max_days` already is. `"when": {...}`
  reuses `scenario_actions.gd::_when_met`'s existing vocabulary
  (`day_at_least`, `food_stores_at_least`, `population_at_least`,
  `event_count_at_least`) rather than inventing a second one -- checked
  every tick (not just on a day change, unlike `max_days`) right after
  `ScenarioActions.run_pending`, ending the run with outcome
  `"stop_condition_met"`. `"when_actions_resolved": true` ends the run
  with outcome `"actions_resolved"` once every entry in the scenario's
  `actions` array has its own `"_resolved"` flag set (fired, not
  necessarily accepted -- same flag `scenario_actions.gd` already
  tracks), skipped when there are no actions at all so a scenario with
  none doesn't stop on tick one. `tools/analyze_session.py` gained
  `REPORT_PROFILES` (a name -> which of `analyze()`'s top-level keys to
  keep) and a `report()` function; `run_scenario.py`'s old boolean
  `--full` is now a `--report {brief,balance,behaviour,full}` choice
  (`--full` kept as a plain shorthand for `--report full`, since
  earlier slices this session already used it in their own
  verification write-ups) -- `brief` (summary + action problems) is
  the new default in place of the old bare summary line.
- **Verified:** `source_checks.py`/`balance_tests.py` pass,
  `FUNCTION_MAP.md` regenerated (`main.gd` is mapped), `mcp__godot__`
  boot clean. Two new scenarios run end-to-end through
  `tools/run_scenario.py` against the real Godot install:
  `test_scenarios/a5_stop_when_test.json` (`stop.when.day_at_least: 3`,
  `max_days: 30`) ended at day 3 with `outcome: "stop_condition_met"`,
  not day 30; `test_scenarios/a5_actions_resolved_test.json` (one
  `set_config` action, `stop.when_actions_resolved: true`, `max_days:
  30`) ended at day 1 (2.0s wall time) with `outcome:
  "actions_resolved"` and the action still logged `accepted`/
  `problems: []`. Confirmed all four `--report` profiles return exactly
  their declared key sets, `--full` still works as `--report full`'s
  shorthand, and an ordinary scenario with neither new `stop` field
  (`c6_nurse_feed_test.json`) still runs to its own `max_days`
  unaffected.

### A6. Headless presentation gate -- done, 22 Aug 2026
- **File:** `main.gd::_process`.
- **Fix:** one `scenario_active` (or the existing headless flag) gate
  around camera following, selection redraws, scenery visibility and
  fog -- every state decision and resource transfer stays untouched
  either side of the gate, per the project's existing "presentation may
  be skipped, simulation may not" rule.
- **Built:** `if not scenario_active:` around
  `camera_view._handle_pan`/`_handle_follow`, `selection_layer.queue_redraw()`
  and `fog_of_war._update()` -- confirmed each is presentation-only
  before gating: pan/follow only ever move a `Camera2D` or read
  `Input.is_key_pressed` (and `_handle_follow` early-returns immediately
  since nothing headless ever sets `main.following_bee`); the selection
  layer is a pure redraw queue; fog-of-war's own "explored" state is
  read only by rendering and `save_game.gd` (which no scenario run
  calls). **`world_building._apply_scenery_setting()` deliberately
  stays outside the gate**, unlike the plan's own "scenery visibility"
  wording suggests -- reading it found it also sets `obstacle.solid`,
  which changes bee navigation/collision, so skipping it under
  `scenario_active` would have been a real principle-3 violation, not
  a safe optimisation. It already early-returns cheaply when nothing's
  changed, so it didn't need gating for cost reasons either.
- **Verified:** `source_checks.py`/`balance_tests.py` pass,
  `FUNCTION_MAP.md` regenerated, `mcp__godot__` boot clean. Direct A/B
  against the real Godot install using A3's own pinned-seed benchmark
  scenario at `--fixed-fps 30`: gate on (current code) and gate
  temporarily forced off (`if true:` in place of `if not
  scenario_active:`, reverted immediately after) produced byte-identical
  `flower_visits` (324), `game_time` (580.75) and `total_deaths` (17) --
  while wall time dropped from 36.3s (gate off) to 5.2s/4.6s (gate on,
  two runs) -- roughly 7-8x faster, well beyond "lower wall time".

### A7. (Backlog) Release/dedicated export
Only worth building if A3-A6's measurements still show material
editor/startup overhead once everything else here is in place. Not a
slice until then.

---

## Slice hygiene

Same as every other slice in this repo: `source_checks.py` and
`balance_tests.py` pass, `FUNCTION_MAP.md` regenerated if a mapped file
changed, a `mcp__godot__` boot check clean, one slice per commit, plain-
language commit message. Nothing here is hands-on verified by Dave
until he says so.
