# ChatGPT insights — implementation plan

Status: planned, not started. 22 Aug 2026.

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

### C2. Undesignated jelly spill -- done, 22 Aug
- **File:** `bee_nursery.gd`, wherever reserve (non-gyne-brood) jelly
  work calls `hive.find_cell_for("jelly")`.
- **Fix:** with no gyne brood pending, only produce/store jelly while an
  explicitly designated jelly cell has room -- don't let the cell
  lookup fall back to ordinary empty comb. Let an urgent gyne need
  override this, but keep that override an explicit, deterministic
  condition, not incidental fallback order.
- **Verify:** headless run with no jelly cell marked -- jelly should
  stop appearing in generic empty cells.

### C3. Honey fanning doesn't stack
- **Files:** `bee_honey.gd` (`honey_fan`, the `being_fanned = true`
  line) and the cell's fan-progress code (likely `hive_cell.gd`).
- **Bug:** every fanning bee sets the same boolean; the cell advances
  by one `delta` per frame regardless of how many bees are fanning it.
- **Fix:** give the cell an `add_fanning(delta)` call like build/mine
  progress already use, called once per fanning bee -- or track an
  integer fanner count instead of a boolean.
- **Verify:** headless 1-fanner vs 4-fanner comparison should show
  close to linear speed-up, not near-identical timing.

### C4. Stocking hatch fallback
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

### C5. Role outcome telemetry
- **File:** `diagnostic_log.gd` (new counters), fed from
  `bee_nursery.gd`, `bee_honey.gd`, `bee_building.gd`, `bee_mining.gd`.
- **Add:** brood feeds, jelly batches, larval deaths; completed/
  cleaned/evicted/restocked cells; completed blocks plus remaining
  exposed/marked soil; honey batches deposited and cells ripened.
  Additive only -- extends the existing `snapshot`/`summary` entry
  shapes, no new log file or format.
- **Verify:** `source_checks.py`; a headless run's summary line shows
  the new counters populated with plausible values.

### C6. Re-run the balance comparisons (verification only, no code)
- After C1-C3 ship, re-run the Feed/Anything nurse comparison and the
  1/2/4-fanner comparison via `run_scenario.py`. Only *then* consider
  touching `jelly_pollen_cost`, `jelly_honey_cost`, `jelly_per_batch`,
  `honey_ripen_time`, `nectar_per_honey` or `honey_energy_factor` --
  the audit's numbers were distorted by these bugs, not proven-bad
  constants.

---

## Group B -- action driver correctness (do before trusting the next audit)

### B1. Shared settings-cascade command
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

### B2. Split role assignment from role mode
- **Files:** `scenario_actions.gd` (`_do_assign_role`), `orders_zones.gd`
  (`_on_role_requested`).
- **Bug:** a combined key like `forager_nectar` logs `accepted` but
  only changes mode, not role -- a scenario expecting a new forager
  sees no population change.
- **Fix:** add explicit `assign_role` / `set_role_mode` verbs (or apply
  both parts, in the right order, to the same resolved bee IDs), and
  check the bees' actual resulting role/mode before logging `accepted`.
- **Verify:** the driver's own postcondition check (B3) now fails
  loudly on a bad combined key instead of silently accepting it.

### B3. Postcondition evidence for the remaining verbs
- **File:** `scenario_actions.gd` (`_do_designate_cell`,
  `_do_queue_build`, `_do_queue_mine`).
- **Fix:** each verb checks its own smallest useful postcondition
  (resulting `designated_type`, stored build/mine target) before
  logging `accepted`, same as B2 does for role assignment.
- **Verify:** `test_scenarios/slice7_action_driver_test.json` still
  passes; a deliberately-wrong action logs a rejection, not a false
  accept.

### B4. Live settings in analysis
- **File:** `tools/analyze_session.py` (`_mechanic_firing`).
- **Bug:** mechanic-firing checks read the boot `config` entry only, so
  a mid-run `set_config` action doesn't update what the summary
  reports -- a run can show 91 tarsal marks while still saying
  `toggle_on: false`.
- **Fix:** build a settings timeline from `action`-type log entries and
  use the last live value before each check, not just the boot
  snapshot.
- **Verify:** a run that enables a mechanic mid-run via `set_config`
  reports `toggle_on: true` once events start firing.

### B5. (Backlog, not a slice yet) Observe-pause-act loop
Park this -- the insight doc's own framing says "only then consider"
it, after B1-B4 land. Revisit only if a specific question genuinely
needs live mid-run decisions rather than a scripted policy.

---

## Group A -- harness speed and token efficiency

### A1. Unique run IDs (a real correctness bug, not just efficiency)
- **File:** `run_scenario.py` (`newest_session_file`).
- **Bug:** two sessions can share a filesystem mtime, so a scenario run
  can pick up another process's (e.g. Dave's live play) unfinished log
  instead of its own.
- **Fix:** generate a run ID per headless launch, pass it into the
  scenario boot argument, have `DiagnosticLog` include it in the
  filename or first `config` entry, and select by ID rather than
  newest-mtime.
- **Verify:** run a scenario while a normal game session is also open;
  the analyser picks up the correct file.

### A2. Explicit `random_seed` scenario field
- **Files:** `main.gd` (`_ready`'s `seed(12345)`), the scenario JSON
  schema, `run_scenario.py`.
- **Fix:** make the seed an explicit, logged scenario field instead of
  a hardcoded constant, so repeats can be genuinely independent (a new
  seed per repeat) or genuinely paired (same seed both sides of an
  A/B comparison).
- **Verify:** two runs of one scenario with different declared seeds
  produce different outcomes; same seed on both sides of a before/after
  comparison cancels randomness.

### A3. `--fixed-fps` benchmark
- **File:** `run_scenario.py`.
- **Fix:** add a `--fixed-fps` launch option; benchmark wall time and
  outcome parity (action postconditions, path completion, throughput,
  population/deaths/resources) at 1/60, 1/30 and 1/15-second steps
  against the current `Engine.time_scale` approach. Pick the largest
  step that stays within tolerance as the new dev-path default.
- **Verify:** one fixed baseline scenario run at each step size,
  diffed on those metrics.

### A4. Cap failure output
- **File:** `run_scenario.py`.
- **Fix:** on a crash or unreadable log, save full stdout/stderr to a
  file and print only a one-line classified error plus the last 10-20
  lines and the artifact path -- not the full native/Python traceback.
- **Verify:** deliberately point the runner at a bad Godot path; the
  printed output stays short.

### A5. Early-success stop conditions + brief reports
- **Files:** `scenario_actions.gd` (stop condition),
  `tools/analyze_session.py` (report profiles).
- **Fix:** add `stop_when_actions_resolved` plus threshold stops (event
  count, population, stores, completed work). Add `brief` / `balance`
  / `behaviour` / `full` report profiles, with `brief` as the default
  AI-facing one.
- **Verify:** a scenario whose actions all resolve by day 10 stops
  there instead of continuing to `max_days`.

### A6. Headless presentation gate
- **File:** `main.gd::_process`.
- **Fix:** one `scenario_active` (or the existing headless flag) gate
  around camera following, selection redraws, scenery visibility and
  fog -- every state decision and resource transfer stays untouched
  either side of the gate, per the project's existing "presentation may
  be skipped, simulation may not" rule.
- **Verify:** headless run outcome (population/deaths/resources) is
  identical with the gate on vs off, at lower wall time.

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
