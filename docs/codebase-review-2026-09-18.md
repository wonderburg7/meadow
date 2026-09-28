# Codebase and plan review — 18 September 2026

<!-- CONTEXT: review | LAYER: on-demand | LOAD: only when routing a finding below into a plan -->
Status: review record | Owner: Dave | Next: route the items in "Prioritised action list" into their owning plans, or into `NEXTSTEPS.md` where one is startable | Verified: 2026-09-18

**Merged 19 Sep 2026, after the fact.** WD-1 to WD-4, L-10 and L-11 shipped
on `master` while this review was on its branch, and the diagnostics plan
moved to `plans/archive/WORKFLOW_DIAGNOSTICS_2026-09-18.md`; paths to it
below point there. Item 3.3 did not reach WD-3 in time: `tools/session_cost.py`
still carries its own `LEVEL_MODELS` copy of the rule in `tools/slice.ps1`.
The rest of items 3.1 to 3.5 are applied.

**What was reviewed.** `NEXTSTEPS.md`, `CLAUDE.md`, `ROADMAP.md`,
`DESIGN_BACKLOG.md`, every live plan under `plans/`, every `.claude/rules/`
file, `docs/known-pitfalls.md`, `docs/performance.md`,
`docs/PERFORMANCE_BASELINE.md`, `GAME_MODEL.md`, `README.md`, `CHATGPT.md`,
`AGENTS.md`, the four `check_docs`/`source_checks`/function-map/stage-reference
checks (all green on `master` at `9f22c68`), and the per-frame, dispatch,
finder, gate and Challenge-runner paths in `scripts/`. Every finding cites the
file and symbol; where a claim is an inference rather than a quotation it says
so. Line numbers are hints, per `plans/README.md` guardrail 15.

**What this review is not.** It does not re-propose anything
`plans/archive/architecture-review_2026-09-24.md` already schedules (E1, F1s, F2s, G3) or
lists under "Patterns deliberately not applied". Those were re-checked against
the live code and still hold. This document adds what that review did not
cover, and corrects two of its slices where the acceptance cannot be run.

---

## 1. Executive summary

Eight findings, by impact. Each is expanded in section 2 and has an entry in
section 3's ordered list; the ones rated moderate or above have a plan in
section 4.

1. **Idle comb workers, nurses and honey makers look for work sixty times a
   second, not eight.** `bee.gd`'s per-frame state `match` calls
   `_idle_dispatch()` unconditionally for `NURSE_IDLE`, `BUILD_IDLE` and
   `HONEY_IDLE`; only `MINE_IDLE` is gated on the 8 Hz dispatch tick. The
   walk reaches three full-comb scans in `hive.gd`. The comment on
   `_try_role_work` says it "runs on every idle bee's think tick", which is
   what everyone believes and is not what happens. Quick code fix, medium
   reasoning; a stated latency change (up to 125 ms, the contract miners
   already have). **Section 2C-1, plan 4.1.**
2. **Two Claude-lane slots are idle on a stale reason.** `NEXTSTEPS.md` holds
   three Claude items and says L-10/L-11 wait because "the Claude lane is
   full at five" and WD-1..4 "wait for a free slot". `check_docs.py` cannot
   see this. Quick fix, plus a one-function check so it cannot recur.
   **2A-1, item 3.2.**
3. **E1's acceptance cannot be run with E1's files.** It asks for "a scenario
   fixture that activates Build cell, then Mine target, then clicks", and
   `scenario_actions.gd` has no verb that arms a placement tool or clicks
   (verbs listed in 2A-3). `scenario_actions.gd` is not on E1's `Files:`
   line. This is the F18 class of defect the architecture review itself
   named. Quick spec fix. **2A-3, item 3.4.**
4. **Adding a third Challenge touches at least six files and nineteen
   `starting_level == n` comparisons.** Fifteen are in
   `challenge_runner.gd`, which also carries 41 stage-id string literals in
   branches that decide per-stage behaviour (`_enter_stage` alone has five).
   Two behaviour-preserving data slices make a Challenge a level-record field
   and a stage-record key set. **2E-1, plans 4.3 and 4.4.**
5. **The rule files a coding model is told to follow disagree with the checks
   that enforce them.** `.claude/rules/saving.md` lists `debug_panel.gd` in
   the `GameConfig` write allowlist; `tests/source_checks.py` lists
   `settings_catalogue.gd`. A model following the rule fails the build. Six
   further stale pointers in the always-loaded and path-loaded files. Quick
   fix. **2B-1, item 3.1.**
6. **The only executed tests are whole headless runs; catalogue logic is
   tested by substring.** `tests/test_conditions.py` asserts that the string
   `"role_count":` appears in `conditions.gd`. Nothing executes
   `Conditions.met`, `Availability.mode_query`, `SaveMigrations.upgrade` or
   `FlowerSpecies.season_weight` outside a full run. One boot argument and a
   test-script convention give every catalogue slice an executed test for
   the cost of the Godot boot `verify.ps1` already pays. **2D-3, plan 4.2.**
7. **Merge and lane rules live in four files, the routing table in
   `plans/README.md` is stale in four rows, and `plans/archive/ui_2026-09-20.md` holds no
   open slice.** Doc-only consolidation. **2B-2, 2A-2, plan 4.5.**
8. **WD-3, as specified, adds a second copy of the level-to-model rule** and
   says so ("mirrors `Get-SliceAdvice`"). The project's own precedent
   (`tests/balance_tests.py` reads tuning values out of the GDScript) fixes
   it in six lines. Quick spec fix before WD-3 is queued. **2B-3, item 3.3.**

Things that are in good shape and should not be touched: the epoch-cached
index and totals in `hive.gd`; the 8 Hz think tick; the presentation gating
in `hive_cell.gd` and `flower.gd`; the catalogue dispatcher G2 landed; the
`conditions.gd` vocabulary; the headless harness and its Challenge fixtures;
the queue tooling's `Proof:` discipline. The architecture review's "Patterns
deliberately not applied" list was checked item by item and is right.

---

## 2. Findings by area

Effort scale: **quick** (one file, under an hour), **moderate** (bounded,
one slice with an acceptance check), **larger** (several slices). Every
finding says whether it can land incrementally.

### A. Plan and process quality

#### A-1. The queue's "not in the queue" reasons are stale, and nothing checks them

*Where.* `NEXTSTEPS.md`, "Not in the queue, and why": "L-10, L-11 -- ready
now; the Claude lane is full at five" and "WD-1, WD-2, WD-3, WD-4 -- all four
are startable ... they wait for a free slot in the Claude lane". The Claude
lane above them holds three items (E1, C1F-1, CB-1).

*Why it matters.* The lane's whole point is that a session never has to
decide what is next. Two ready, file-disjoint, low-level slices (WD-1, WD-2
are both `Level: low`) are sitting behind a sentence that was true when it
was written. `tools/check_docs.py::check_next_steps` enforces "at most five
per lane" and "at least three overall" but not "a reason of the form *lane is
full* is only valid when the lane has five".

*Effort.* Quick (queue edit) plus quick (one check function). Incremental:
yes. Files: `NEXTSTEPS.md`, `tools/check_docs.py`, `tests/test_source_checks.py`.

#### A-2. Restrictions that expired when their slice shipped (rule 10 cases)

Found by applying `plans/README.md` rule 10 to every live plan:

- `plans/README.md` guardrail 14 still opens its `challenge_runner.gd` order
  with "**UI-X-2** ... shipped". A shipped slice heads an ordering list.
- `plans/archive/c1-followups_2026-09-28.md`, open-slices table: C1F-1 "Startable: after
  UI-X-2 and E1". UI-X-2 shipped 18 Sep.
- `plans/README.md`, "Current routing": rows "UI-R, UI-Q, UI-P, UI-D" (all
  closed), "L-1..L-9" (open slices are L-10 to L-13), and "A1-A4, B1-B3,
  C1-C4, D1, E1, F1s, F2s, G1-G3" (only E1, F1s, F2s, G3 are open). No row
  for WD-1..4, PERF-1 or SM-1, which are the three newest plans.
- `plans/README.md`, "Writing or editing a plan": rules are numbered 1 to 8,
  then 10, then 9. A model that is told "rule 9" opens the wrong one.
- `plans/archive/ui_2026-09-20.md` has "Open slices at a glance: None" yet sits in
  `plans/now/`, whose contract is "an executable current/successor slice".
  Its 60 lines of durable layout rules belong in `plans/reference/`, where
  `check-loop.md` already restates two of them (see B-2).
- `plans/now/agent-lifecycle.md`, "Current state": nine bullets of shipped
  history (L-1, L-3, L-9, the 12 Sep fixes) that the same file repeats under
  "Shipped, one pointer each". The README says history moves to the archive
  at a slice transition; here it is stated twice in one live file.
- `checks/blocked.md` still carries a two-line stub for C-18 ("unblocked 18
  Sep 2026 ... see checks/ready/C-18.md", since archived) between real blocked entries.

*Effort.* All quick; doc only. Incremental: yes.

#### A-3. Three acceptance sections name an instrument that does not exist

*E1* (`plans/archive/architecture-review_2026-09-24.md`, "E1 -- one placement tool"):
"A scenario fixture that activates Build cell, then Mine target, then clicks,
and asserts a mine target was set and no cell was placed." The scenario verbs
today are `settle`, `assign_role`, `designate_cell`, `queue_build`,
`queue_mine`, `set_config`, `hatch_role`, `set_restock_order`,
`select_bees`, `select_soil`, `select_cell`, `open_window`, `close_window`,
`viewport_size`, `show_gallerin_prompt`, `advance_challenge_stage`, `assert`
(`grep "static func _do_" scripts/scenario_actions.gd`). None arms a tool or
delivers a click, and `queue_mine`/`queue_build` go straight to the bee, not
through `input_selection.gd::_finish_drag`, which is the code E1 changes.
E1's `Files:` line omits `scenario_actions.gd`. It is in the same lane
(C1F-1 and CB-1 own it), so adding it costs no cross-lane conflict, but the
slice as written would either ship with an unrun acceptance or stop to
escalate.

*C1F-1* is fine: it adds its own `retreat_challenge_stage` verb and says so.

*CB-1* is fine: it names the summary writer as the instrument and tells the
implementer to find it.

*Effort.* Quick spec edit to E1 (section 3.4 gives the text). Incremental: yes.

#### A-4. Scoping and ordering of the current queue

Checked each item for "can one session implement and verify it":

- **E1** (medium): right size once A-3 is fixed. It is correctly first in
  the `challenge_runner.gd` order because C1F-1 requirement 5 depends on it.
- **C1F-1** (medium, 250-line plan section): the largest open slice. Its
  table of twenty stage setups is the part that makes it mechanical, and it
  is right to keep it. One risk: requirement 4 ("that stage's own goal is
  false and every earlier stage's goal would be true") is proved only by the
  fixture, and the fixture asserts only "stage stays put for two seconds".
  That proves the first half. Suggest the fixture also asserts, after each
  retreat, one world fact from the table (for example `built_cells` via the
  existing `built_cells_at_least` condition) so a wrong row fails on the row,
  not on a later symptom. Quick addition to the plan.
- **CB-1, SM-1, PERF-1** (all measure-first): correctly scoped. PERF-1 will
  read `find_food_cell`'s share while finding C-1 below is still live, so
  the numbers it records for `bee_state_builder`/`bee_state_honey` in the
  same run will be inflated by the 60 Hz dispatch. Land 4.1 first, or have
  PERF-1's delivery note say the builder/honey rows predate it. Sequencing
  note, not a rewrite.
- **SF-1** (medium): well specified. Its "measure first" step reads the
  summary through `tools/headless/profiles.py`; fine.
- **L-10 / L-11 / L-12 / L-13**: correctly ordered. L-12's gate (stops
  ledger shows refill among the top two) cannot be evaluated yet: the stops
  ledger does not exist on this checkout and `--events` shows two events.
  That is by design and not a defect.
- **WD-1..4**: independent, correctly low/medium. WD-3 needs the B-3 edit.

Re-sequencing that would make later slices cheaper (front-loading):

1. **4.2 (GDScript test boot) before G3, F2s and CH-1/CH-2.** All four add
   catalogue rows and pure functions whose only executed test would
   otherwise be a full headless run.
2. **4.1 (idle dispatch cadence) before PERF-1's numbers are interpreted.**
3. **CH-1 (Challenge id in the level record) before any Challenge 3 design
   work**, and before G3, because G3 adds "stages may name action ids in
   `unlocked_keys`" and would otherwise be built against the
   `starting_level == 1` shape it is about to inherit.

#### A-5. Plans a coding agent could misread

- `plans/archive/comb-builders_2026-09-20.md` CB-1 requirement 2: "accumulate the elapsed
  time there rather than adding a timer" -- correct, but the file header it
  cites says `run_pending` is "called once per `_process` tick", which is
  `main.gd::_process` only while unpaused and only when `scenario_active`.
  Say "inside `run_pending`" so the sampler is not put at file scope.
- `plans/reference/technical-audit.md` PERF-1: "Both calls already return
  immediately when `Session.perf_enabled` is false" -- true, but the section
  name must also be added to nothing else; the plan says so. Fine.
- `plans/now/season-feel.md` SF-1 requirement 2 changes the random draw
  order per founder and says so. Fine, and a model of how to state a
  behavioural side effect.
- `plans/now/agent-lifecycle.md` L-10: "`plans/archive/**` is denied to the
  file tools, so the reproduction goes through a Bash heredoc" -- a model
  that reads this may conclude it should use a heredoc today. Add "until
  L-10 ships, and never for a section over forty lines".

### B. Token and context efficiency of the workflow

#### B-1. Rules that contradict the checks, or point at sections that no longer exist

Each of these costs a session a failed check or a search, which is exactly
the retry loop `docs/known-pitfalls.md`'s last section measures.

| File | Says | Truth |
| --- | --- | --- |
| `.claude/rules/saving.md`, "`GameConfig` writes are allowlisted" | `game_config.gd`, `debug_panel.gd`, `save_game.gd`, `levels.gd` | `tests/source_checks.py::GAMECONFIG_WRITE_ALLOWLIST` is `game_config.gd`, `settings_catalogue.gd`, `save_game.gd`, `levels.gd`; `.claude/rules/simulation.md` already has the right list |
| `.claude/rules/saving.md`, same section | "see `DESIGN_BACKLOG.md` §11" | `DESIGN_BACKLOG.md` has no numbered sections since 11 Sep; the decision is under "Deferred product decisions", "Save/load during an active Challenge" |
| `.claude/rules/gdscript.md` | "see 'Verifying without Godot' in `CLAUDE.md`" | No such heading in `CLAUDE.md` (grep returns nothing) |
| `CLAUDE.md`, "Where to route a change" | "The seven largest scripts are indexed in `FUNCTION_MAP.md`" | The map is threshold-based since H1 and lists thirteen files |
| `.claude/rules/gdscript.md` | "check `FUNCTION_MAP.md` for the six biggest scripts" | Same |
| `GAME_MODEL.md` (nine places) | "`DESIGN_BACKLOG.md` section 13 / §13" | Section no longer exists |
| `README.md`, "Layout" | `_backups/ snapshots taken before large changes`; "tests/ the two suites above" | `_backups/` is excluded from every tool and superseded by Git per `.claudeignore`; `tests/` holds two suites plus eighteen unittest modules |

*Effort.* Quick, one pass. Incremental: yes.

#### B-2. Rules stated in more than one place

| Rule | Homes today | Recommended single home |
| --- | --- | --- |
| One branch per lane, merge when green, never hold for a hands-on check | `plans/workstreams.md` "When to merge"; `plans/reference/closeout.md` "When to merge"; `CHATGPT.md` (two paragraphs); `plans/README.md` read order; `CLAUDE.md` session route; `.claude/rules/documentation.md` | `plans/reference/closeout.md`. `workstreams.md` keeps its ledger table and the five "Lanes" bullets only; `CHATGPT.md` keeps one sentence and the `heading.py` command |
| Every persistent panel takes its rectangle from `ui_layout.gd` | `plans/README.md` guardrail 11; `plans/reference/check-loop.md` rule 6; `plans/archive/ui_2026-09-20.md` (twice); `plans/archive/architecture-review_2026-09-24.md` F9 | A plans/reference/ui-rules.md made from `ui.md`'s "Durable rules"; the other three become one-line pointers |
| Presentation may be skipped, simulation may not | `CLAUDE.md` rule 2; `.claude/rules/simulation.md`; `plans/archive/ui_2026-09-20.md`; `GAME_MODEL.md`; comments in `main.gd`, `hive_cell.gd` | `.claude/rules/simulation.md` (it loads itself on the files where it matters); `CLAUDE.md` rule 2 stays as the four-word version |
| Read a function, not a file | `CLAUDE.md` rule 1; `.claude/rules/gdscript.md`; `.claude/rules/lifecycle-tooling.md`; `plans/README.md` guardrail 15 | `CLAUDE.md` rule 1 (always loaded); the rest cite it |
| The `GameConfig` write allowlist | `.claude/rules/saving.md`; `.claude/rules/simulation.md`; `tests/source_checks.py` | `tests/source_checks.py` is the authority; both rule files say "the allowlist is `GAMECONFIG_WRITE_ALLOWLIST` in `tests/source_checks.py`" and name no files |

*Effort.* Moderate as one doc-only pass (plan 4.5). Incremental: yes, one
row at a time.

#### B-3. WD-3 creates a second copy of the level-to-model rule

*Where.* `plans/archive/WORKFLOW_DIAGNOSTICS_2026-09-18.md`, WD-3 step 2: a `LEVEL_MODELS`
dictionary in `tools/session_cost.py` with the comment "mirrors
`Get-SliceAdvice` in `tools/slice.ps1`, which is where the rule actually
lives". `Get-SliceAdvice` (`tools/slice.ps1`, "briefing" section) holds the
rule as a PowerShell `switch`.

*Why it matters.* `plans/README.md` rule 6 ("record a decision once") is the
project's own rule, and the slice violates it knowingly. The next time the
model names change, one copy drifts.

*Fix.* Have `session_cost.py` read the `switch` out of `slice.ps1` with a
regex, the way `tests/balance_tests.py::cfg` reads a tuning value out of
`game_config.gd`. Six lines; exact text in 3.3. WD-3 stays inside its own
file. No JSON file, no new owner.

*Effort.* Quick spec edit. Incremental: yes.

#### B-4. Long documents and what actually loads

Measured: `CLAUDE.md` is 6.7 KB (about 1.7K tokens) and re-sent every
request; the five path-scoped rule files total 15 KB and load only when a
matching file is opened. The three design plans are 52 KB, 33 KB and 25 KB,
but every queue item's `read` command prints one heading through
`tools/heading.py`, so a coding session never loads them whole. That
structure is sound and should be kept.

Two places still cost more than they need to:

- `plans/archive/WORKFLOW_DIAGNOSTICS_2026-09-18.md` is 286 lines (the checker warns at
  260). Its "State" paragraph is fifteen lines of what WD-0 built, which the
  archive record holds. Trim to three lines.
- `plans/now/agent-lifecycle.md`: 60 lines of "Current state" history (A-2).

Neither is loaded whole by a slice, so both are low priority; they matter
only to the planning model, which is the reader that opens whole files.

#### B-5. The review prompt and the repo's own settings disagree

`.claude/settings.json` denies `Read` on `ROADMAP.md`, `DESIGN_BACKLOG.md`,
`plans/archive/**` and `docs/archive/**`. A review that is told to read the
first two has to go through `git show`. That is fine for a one-off review,
but a future planning session given the same instruction will spend a turn
on the denial. Either the review prompt should say "via `git show HEAD:`", or
the deny list should carry a comment saying why and what the workaround is.
Quick; Dave's call which.

### C. Runtime and performance

#### C-1. Idle dispatch runs every frame for three of the four idle states

*Evidence.* `scripts/bee.gd::_process`, the state `match` under
`Perf.begin("bee_state")`, whose own comment says "Runs every frame, not
just on a think tick":

```
State.NURSE_IDLE:
    _idle_dispatch()
...
State.BUILD_IDLE:
    _idle_dispatch()
...
State.MINE_IDLE:
    if _miner_dispatch_due:
        _idle_dispatch()
...
State.HONEY_IDLE:
    _idle_dispatch()
```

`_idle_dispatch` has no `thinking` guard; its doc comment says "Called every
frame a bee is sitting in one of the three 'waiting for work' states".
`_try_role_work`'s comment says "this runs on every idle bee's think tick".
The second comment is what the 8 Hz design intends and the first is what
the code does. The catalogue walk it reaches calls, per idle bee per frame:

| Role, mode | Finder | Cost |
| --- | --- | --- |
| Comb worker, Anything | `hive.find_cell_needing_cleaning` | bucket read (cheap) |
| | `hive.find_cell_needing_eviction` | **full pass over `cells`** |
| | `BeeBuilding.find_restock_job` | order walk |
| | `hive.find_unfinished_cell` then `create_next_cell_site` | **full pass**, then a site search |
| Honey maker | `hive.find_honey_target` (`find_cell_for`) | **full pass** |
| | `hive.find_cell_needing_fanning` | **full pass** |
| | `hive.find_cell_with("nectar")` | bucket read |
| Nurse, Feeding | `hive.find_brood_cell` | bucket read |

A colony of ten idle comb workers on Anything and 200 cells does roughly
10 × 60 × 400 = 240,000 cell visits a second doing nothing. The miners had
exactly this problem and it was fixed with `_miner_dispatch_due` plus a
no-work epoch (`docs/PERFORMANCE_BASELINE.md`, "Invalidation contracts").

*Inference, stated as such.* This is likely the largest remaining
`bee_state_builder`/`bee_state_honey` cost in the baseline fixture, and it
scales with idle population, which is the population a player creates by
over-assigning a role. It has not been measured; plan 4.1 measures it first
using the sections that already exist.

*Behaviour.* Gating the three arms on `thinking` changes when an idle bee
notices new work: from the next frame to the next think tick, at most 125
ms, jittered. That is the contract miners already have and no player check
has ever distinguished it. It is flagged as a behavioural change here; the
equivalence run (`tools/equivalence.py`) will show whether any run summary
counter moves.

*Effort.* Quick code, medium reasoning (hot path and simulation rule).
Incremental: yes. Plan 4.1.

#### C-2. Small per-frame waste that is not worth a slice each

Each is a one-to-three-line, behaviour-preserving change. Bundle them into
one low-level slice (item 3.10) or let each ride with the next slice that
opens its file.

- `scripts/debug_panel.gd::_process` calls
  `_refresh_challenge_stage_navigation()` every frame whether or not the
  settings window is open. It does a `get_nodes_in_group("world")` lookup
  and builds a four-field format string every frame to compare against a
  cached key. Guard with `if not panel.visible: return` at the top of
  `_process`; the row is only visible inside the panel.
- `scripts/main.gd::_prune_selection` runs three `Array.filter` calls a
  frame, each allocating, even with nothing selected. Return early when all
  three selections are empty.
- `scripts/challenge_runner.gd::_drive_c1_pollen_cell_nectar_prompt` walks
  `main.hive.cells` once a second on stage 1.14 looking for a nectar cell
  designated pollen; `hive.cells_holding("nectar")` is the bucket that
  already exists. Not hot (1 Hz, one stage), just the pattern B2 built.
- `scripts/challenge_runner.gd::_process` calls `_publish_marker_to_hud()`
  every frame; `hud.gd::_update_stage_marker_arrow` then recomputes the
  canvas transform every frame. Both only run during a Challenge and the
  marker moves only on stage change or camera move. Left alone: the cost is
  a few vector operations and the camera can move every frame anyway.

#### C-3. What will get expensive later

- **`find_empty_cell` and `find_cell_for` remain full passes by design**
  (`plans/reference/technical-audit.md` section A explains the ordering
  subtlety). The queen asks `find_empty_cell` on her think tick; honey
  makers ask `find_cell_for("honey")` (via `find_honey_target`) on theirs.
  At 200 cells that is fine. At a "larger meadow, larger hive" milestone it
  is the next thing PERF-1's pattern should measure. No action now.
- **`get_nodes_in_group("bees")` at 1 Hz** in `year_winter.gd`,
  `season.gd`, `diagnostic_log.gd` and `save_game.gd`: five walks a second
  over the colony. Fine to several hundred bees. The `_role_counts()` epoch
  cache is the pattern to extend if a sixth 1 Hz consumer appears.
- **Fog of war** is the measured hot path (`fog_of_war_update` mean 2.9 ms,
  p95 10 ms in the 17 Sep run) and is already pinned. Nothing here changes
  that.
- **The scenario `assert` walk** (`ScenarioActions.run_pending` each frame
  while a scenario is active) filters `scenario_actions` for unresolved
  entries every frame; headless only, so it costs nothing in play.

### D. Code structure and architecture

#### D-1. Where the codebase mixes patterns, and which should be standard

Three patterns coexist, and each is right for its category. The
recommendation is to make the mapping explicit so a new system lands in the
right shape without a judgement call:

| Category | Pattern in use | Files | Standard? |
| --- | --- | --- | --- |
| Per-instance simulation entities | One `Node2D` per entity with a `_process`, behaviour in `static func` service modules | `bee.gd` + `bee_*.gd`, `flower.gd` + `crab_spider.gd`, `hive_cell.gd` | Yes. Keep. Not ECS (technical-audit's "Not a case for ECS" holds). |
| Colony-wide state and rules | A Controller node under `main` with a `main` back-reference | `world_building.gd`, `input_selection.gd`, `camera_view.gd`, `orders_zones.gd`, `saving.gd`, `year_winter.gd`, `challenge_runner.gd`, `stage_gate.gd`, `fog_of_war.gd` | Yes. Keep. |
| Authoritative data (catalogues) | `RefCounted` leaf with a `const` table and static lookups | `roles.gd`, `resources.gd`, `actions.gd`, `features.gd`, `skills.gd`, `flower_species.gd`, `settings_catalogue.gd`, `prerequisites.gd`, `challenge_stages.gd`, `levels.gd`, `scenario_presets.gd` | Yes. Keep. **Every new rule that a Challenge, scenario or skill needs to vary goes here, not into a branch.** |
| Derived facts | Stateless `RefCounted` static computation | `colony_diagnostics.gd`, `conditions.gd`, `availability.gd` | Yes. Keep. |
| UI panels | Five near-identical `CanvasLayer` scripts | `colony_panel.gd` and four siblings | No; F1s already fixes it with a base class. |
| Placement tools, stage-gated widgets | Boolean flags and bespoke setters | `main.gd`, `hud.gd` | No; E1 and F2s already fix them. |

The one category with no standard is **"per-Challenge behaviour that is not
a goal"**: `challenge_runner.gd`'s `_c2_*` fields, `_check_c2_failure`,
`_drive_c1_forage_effects`, `_drive_opening_mine`. Each is a hand-written
driver keyed on `starting_level`. E-1 below gives the smallest step that
does not require designing the event director.

#### D-2. Duplicated computation and second sources of truth still live

The architecture review closed most of these (role keys, totals, resource
kinds, conditions). Remaining, checked 18 Sep:

- `GOAL_CADENCE` in `challenge_runner.gd` is a second table keyed by goal
  id beside the stage records that already carry `goal` and `condition`.
  `check_goal_cadence_registry` exists only to prove the two agree. Fold
  `cadence` into the stage record (item 3.9; small, data-only, behaviour
  preserving; the check shrinks to "every stage has a cadence").
- `hud.gd` "role controls" carries `HATCH_ROLES` as "plain ints mirroring
  `Bee.Role`" with a comment saying so; `roles.gd` already exposes the ids
  as constants. Documented and deliberate; leave it, but it is the shape
  to avoid in new code.
- The level-to-model rule (B-3).
- `checks/blocked.md`'s format paragraph restates `checks/ready.md`'s
  format; fine, one sentence.

#### D-3. Testability

What exists: Python regex checks over the GDScript source (`source_checks.py`,
30 check functions), Python re-simulation of balance arithmetic
(`balance_tests.py`), the headless scenario runner with `assert` conditions
and layout assertions, `tools/equivalence.py` for before/after runs, and the
one-boot compile check `verify.ps1` runs when Godot is present.

What is missing: any way to execute a single GDScript function with
constructed inputs. The consequence shows in `tests/test_conditions.py`,
whose three tests assert that certain strings appear in `conditions.gd`.
`progression.md` section 11 says the same about steps 1 to 5: "Neither
executes the shipped GDScript". Every catalogue and resolver slice (G3, F2s,
C1F-1's setup vocabulary, SF-1's `season_weight`, every `save_migrations.gd`
step) is therefore proved by a whole headless run or not at all.

The cheap fix is a boot argument, in the same shape as `--scenario=`:
`--gdtest` makes `main.gd` skip world construction, load every
`tests/gd/test_*.gd`, call each `test_*` static function, print one line per
result and quit with a non-zero code on any failure. `tools/godot_compile_check.py`
already boots headlessly and pattern-matches the output; a sibling
tools/godot_test_check.py reuses its `find_godot` and timeout. Plan 4.2.

#### D-4. Coupling that makes a new mechanic touch unrelated files

- **A new placement tool**: nine files' worth of flags and signals; E1
  fixes it. No action here.
- **A new stage-gated control**: setter + field + call + rebuild hook; F2s
  fixes it. No action here.
- **A new Challenge**: E-1 below.
- **A new role's starting count in a level**: `levels.gd` row key +
  `world_building.gd` loop + `settings_catalogue.gd` "Starting N" row +
  `GameConfig` field + `main.gd::_update_population_readout` named int +
  `hud.update_population` signature. Six places, all keyed by role. Not
  worth fixing until a role is actually added; when one is, the pattern is
  a `starting_count_key` on the `roles.gd` row and one loop over
  `Roles.ROLES` in `world_building.gd`. Recorded here so the next role slice
  does not rediscover it.

### E. Extensibility for future content

#### E-1. Adding a Challenge is expensive; adding a Scenario is cheap

**A Scenario** is a `levels.gd` row plus a `main_menu.gd` entry plus,
optionally, a `scenario_presets.gd` difficulty. Data-driven and safe. No
action.

**A Challenge** is not. Verified on 18 Sep:

- `Session.starting_level == 1` / `== 2` is compared in nineteen places:
  fifteen in `challenge_runner.gd`, one each in `main.gd` (`in [1, 2]`,
  which decides whether a runner starts at all), `world_building.gd` (Poppy
  exclusion), `debug_panel.gd`, `challenge_complete.gd`.
- `challenge_runner.gd::_stages` is `return Stages.STAGES_2 if
  Session.starting_level == 2 else Stages.STAGES_1`, so a `STAGES_3` cannot
  be reached without editing the runner.
- `_enter_stage` branches on stage-id literals five times: `"1.1"`
  (command lock), `["1.6" .. "1.10"]` (role-change lock), `"1.8"`,
  `"1.11"` (rate override), `"1.4"`/`"1.7"` (ordered visits), `"1.19"`
  (farewell bubble), plus the fog reveal mode. The runner holds 41 stage-id
  literals in total (`grep -o '"[12]\.[0-9]\+"'`), against a data file whose
  header says "Adding a stage means adding a row here, a predicate in
  challenge_runner.gd's goal registry and (if it needs one) a view binding".
- The runner has a "Challenge 2" section with its own failure/rescue
  driver, and Challenge 1 has three per-frame drivers.
- `docs/challenge-stages.md` is generated (good), `tutorial_checkpoint.gd`
  saves `unlocked_keys` (good), and H4 lets a fixture start "either ordinary
  Challenge by supplying `challenge` of 1 or 2" (the doc's own words: the
  harness is bound to two).

What makes it expensive is not the amount of code but that the identity of a
Challenge is an integer compared in many places instead of a field looked
up once. Two slices, both behaviour-preserving:

- **CH-1** (plan 4.3): the level record gains `"challenge": "c1"` (and
  `"c2"`); `challenge_stages.gd` gains `for_challenge(id)`; the runner
  reads `_challenge_id` once at `start()` and every `starting_level == n`
  becomes `_challenge_id == "c1"`; `main.gd` starts the runner when the
  level record has a `challenge` key. Nineteen edits, one meaning.
- **CH-2** (plan 4.4): the five id-literal branches in `_enter_stage`
  become stage-record keys (`command_locked`, `role_change_locked`,
  `reset_counters`, `forage_rate_multiplier`, `ordered_visit`,
  `farewell_bubble`, `hive_reveal_mode`), each read generically.

After both, a third Challenge is a `levels.gd` row, a `STAGES_3` table and a
`main_menu.gd` entry, with goals in `conditions.gd` vocabulary or `custom`
predicates. The per-Challenge rescue driver (`_check_c2_failure`) stays
bespoke until the event director is designed; that is product-scope's
own open design item and is not proposed here.

#### E-2. What already makes new stages safe

Worth saying so it is not undone: the `condition` key on a stage record, the
`on_enter`/`on_exit` effect vocabulary with a `push_error` on an unknown
effect, `check_goal_cadence_registry`, `check_stage_effects_order`, the
generated stage reference, and the headless `challenge` fixture field. CH-2
extends the effect-vocabulary idea to the five remaining branches; it does
not replace it.

---

## 3. Prioritised action list

Ordered so that process and token fixes that make everything after them
cheaper come first, then by dependency. Each states what it unblocks.

| # | Item | Effort | Level | Files owned | Unblocks |
| --- | --- | --- | --- | --- | --- |
| 3.1 | **DOC-1: fix the seven stale rule pointers** in B-1 (allowlist, §11, "Verifying without Godot", seven/six largest, §13, README layout) | quick | low | `.claude/rules/saving.md`, `.claude/rules/gdscript.md`, `CLAUDE.md`, `GAME_MODEL.md`, `README.md` | every coding session that opens a `.gd` file reads a true rule |
| 3.2 | **Q-1: refill the Claude lane and make "lane is full" checkable.** Add WD-1 and WD-2 (both low, file-disjoint from both lanes) to the Claude lane at positions 4 and 5; reword the L-10/L-11 line to "wait for a free slot"; add `check_not_in_queue_reasons` to `tools/check_docs.py` (a bullet whose text contains "lane is full" fails unless that lane holds five items) | quick | low | `NEXTSTEPS.md`, `tools/check_docs.py`, `tests/test_source_checks.py` | two idle slots; the defect cannot recur |
| 3.3 | **WD-3 amendment**: replace step 2's `LEVEL_MODELS` with a reader over `tools/slice.ps1` (text below) | quick | low | `plans/archive/WORKFLOW_DIAGNOSTICS_2026-09-18.md` | WD-3 ships without a second copy of the rule |
| 3.4 | **E1 amendment**: add two scenario verbs and `scenario_actions.gd` to E1's files (text below) | quick | low | `plans/archive/architecture-review_2026-09-24.md`, `NEXTSTEPS.md` item 1 | E1's acceptance can be run |
| 3.5 | **A-2 trims**: guardrail 14, C1F-1 table, README routing rows and rule numbering, C-18 stub, agent-lifecycle history, workflow-diagnostics State | quick | low | `plans/README.md`, `plans/archive/c1-followups_2026-09-28.md`, `plans/now/agent-lifecycle.md`, `plans/archive/WORKFLOW_DIAGNOSTICS_2026-09-18.md`, `checks/blocked.md` | the planning model stops re-deriving four expired restrictions |
| 3.6 | **IDLE-1: idle dispatch on the think tick** (plan 4.1) | quick code, measured | medium | `scripts/bee.gd`, `docs/PERFORMANCE_BASELINE.md` | PERF-1's numbers are read against a fixed idle cost; the biggest unmeasured per-frame scan is gone |
| 3.7 | **GDT-1: a GDScript test boot** (plan 4.2) | moderate | medium | `scripts/main.gd`, new tools/godot_test_check.py, new `tests/gd/` folder, `tools/verify.ps1`, `docs/headless-run-contract.md` | executed tests for G3, F2s, CH-1, CH-2, C1F-1, SF-1, every migration |
| 3.8 | **CH-1: a Challenge is a level-record field** (plan 4.3) | moderate | medium | `scripts/levels.gd`, `scripts/challenge_stages.gd`, `scripts/challenge_runner.gd`, `scripts/main.gd`, `scripts/world_building.gd`, `scripts/debug_panel.gd`, `scripts/challenge_complete.gd`, `scripts/scenario_actions.gd`, `tests/source_checks.py` | a third Challenge; G3's stage-named actions built on the right shape. Queue after C1F-1 per guardrail 14 |
| 3.9 | **CH-3: `cadence` moves into the stage record** | quick | low | `scripts/challenge_stages.gd`, `scripts/challenge_runner.gd`, `tests/source_checks.py` | one table per stage instead of two; rides with CH-2 if convenient |
| 3.10 | **CH-2: the five id-literal branches become stage keys** (plan 4.4) | moderate | medium | `scripts/challenge_stages.gd`, `scripts/challenge_runner.gd`, `tests/source_checks.py` | a third Challenge needs no runner edit for entry behaviour |
| 3.11 | **DOC-2: one home for the merge rules; `ui.md` to reference** (plan 4.5) | moderate, doc only | low | `plans/reference/closeout.md`, `plans/workstreams.md`, `CHATGPT.md`, `plans/archive/ui_2026-09-20.md` → plans/reference/ui-rules.md, `plans/README.md`, `plans/reference/check-loop.md`, `DESIGN_BACKLOG.md` | the planning model reads one statement per rule |
| 3.12 | **PF-1: per-frame housekeeping** (C-2's first three bullets) | quick | low | `scripts/debug_panel.gd`, `scripts/main.gd`, `scripts/challenge_runner.gd` | nothing; three allocations a frame gone. Lowest priority |
| 3.13 | **C1F-1 fixture addition** (A-4): assert one world fact per retreat | quick | low | `plans/archive/c1-followups_2026-09-28.md` | a wrong setup row fails on its own row |

Text for 3.3, to replace WD-3 step 2 verbatim:

> 2. Add a module-level reader beside `PHASE_LABELS` that takes the rule
>    from its one home rather than copying it:
>    ```python
>    # The model each stated level asks for lives in Get-SliceAdvice in
>    # tools/slice.ps1. Read it out of the switch there, the way
>    # tests/balance_tests.py reads tuning values out of game_config.gd, so
>    # there is one copy. A model outside its level's entry is drift.
>    def level_models() -> dict[str, tuple[str, ...]]:
>        text = (Path(__file__).resolve().parent / "slice.ps1").read_text(encoding="utf-8")
>        block = text.split("function Get-SliceAdvice", 1)[1].split("$uiFile", 1)[0]
>        found: dict[str, tuple[str, ...]] = {}
>        for level, model in re.findall(r'"(low|medium|high)"\s*\{\s*"([a-z0-9-]+)', block):
>            found[level] = (model,) if level != "low" else (model, "claude-haiku-4-5")
>        return found
>    ```
>    Match a transcript's model against an entry by `startswith`.

Text for 3.4, to add to E1 under **Files to change** and **Automated
acceptance**:

> - **Files to change** also: `scripts/scenario_actions.gd` (two verbs, in
>   the same dispatch `match` as `queue_build`: `request_placement_tool`
>   with `tool` naming a catalogue id, calling `main.request_placement_tool`;
>   and `click_world` with `x`, `y` and `view: "hive"|"meadow"`, calling
>   `input_selection._finish_drag` with a zero-size drag at that global
>   point), and `docs/headless-run-contract.md`'s verb list. This file is in
>   the Claude lane (C1F-1, CB-1) so it costs no cross-lane conflict; E1 is
>   ahead of both.
> - **Automated acceptance** stays as written, and now names its instrument:
>   test_scenarios/e1_placement_exclusion_test.json using the two verbs
>   above, asserting through the existing `assert` vocabulary that
>   `main.selected_bees[0].mine_queue` is non-empty and `built_cells_at_least`
>   is unchanged.

---

## 4. Implementation plans

Written in the shape of the project's own slice sections so they can be
pasted into the owning plan (named per plan) without translation. Each ends
with the queue lines it would be admitted with.

### 4.1 IDLE-1 — idle nurses, comb workers and honey makers look for work on the think tick

*Owning plan: a new plans/now/idle-dispatch.md, or `plans/reference/technical-audit.md` beside PERF-1 (same measure-then-change shape). Lane: Claude (owns `bee.gd`; no open item in either lane names it now that G2 has shipped).*

**Purpose.** Finding C-1: three of the four idle states dispatch every
frame; only miners were fixed. Make the other three match the miners, and
measure it, so the "8 Hz think tick" the file describes is what the file
does.

**Root cause, confirmed.** `scripts/bee.gd::_process`: the arms
`State.NURSE_IDLE`, `State.BUILD_IDLE` and `State.HONEY_IDLE` call
`_idle_dispatch()` with no cadence guard; `State.MINE_IDLE` guards on
`_miner_dispatch_due`. `_idle_dispatch` → `_try_role_work` → the catalogue
walk → `find_cell_needing_eviction`, `find_unfinished_cell`,
`find_cell_needing_fanning` and `find_cell_for`, each a full pass over
`hive.cells`.

**Required reading.** This section. `bee.gd`: the "how often a bee thinks"
section (the `THINKS_PER_SECOND` comment block and `_process` down to the
`match`), `_idle_dispatch`, `_try_role_work`, `_maybe_break_off_secondary`.
`.claude/rules/performance.md`. `docs/PERFORMANCE_BASELINE.md`, "Invalidation
contracts" (the miner cadence rule this copies). Read with
`python tools/func.py scripts/bee.gd _idle_dispatch _try_role_work _maybe_break_off_secondary`.

**Files likely to change.** `scripts/bee.gd`, `docs/PERFORMANCE_BASELINE.md`.

**Must not change.** `_try_role_work`'s catalogue order; `_idle_dispatch`'s
queen-first rule; the miner path (`_miner_dispatch_due` and
`_mining_no_work_epoch`); any `hive.gd` finder; any `GameConfig` value;
`actions.gd`.

**Requirements.**
1. *Measure first.* Run `test_scenarios/recommendation_slice0_baseline.json`
   at `--fixed-fps 60` twice on `master` from a worktree with a primed
   `.godot` cache. Read back only `bee_state_builder`, `bee_state_honey`,
   `bee_state_nurse` and `frame_time_ms` (mean and p95) from
   `summary.performance`. Also run `test_scenarios/colony_30_bees_test.json`
   (it has idle comb workers) the same way. Record both in the delivery
   note.
2. In `_process`, change the three arms so they read exactly as the miner
   arm does, using the existing `thinking` flag (not a new timer):
   ```gdscript
   State.NURSE_IDLE:
       if thinking:
           _idle_dispatch()
   ...
   State.BUILD_IDLE:
       if thinking:
           _idle_dispatch()
   ...
   State.HONEY_IDLE:
       if thinking:
           _idle_dispatch()
   ```
   `thinking` is already computed at the top of `_process` and jittered per
   bee, so the colony's dispatches stay spread across frames.
3. Correct the doc comment on `_idle_dispatch` from "Called every frame a
   bee is sitting in" to "Called on a think tick while a bee is sitting
   in". `_try_role_work`'s comment is already right.
4. Re-run requirement 1's two fixtures on the branch. Record the same rows.
5. Run `python tools/equivalence.py` (see `docs/headless-run-contract.md`,
   "Behaviour-equivalence runs") on `test_scenarios/colony_30_bees_test.json`
   against `master`. Any summary counter that differs is reported in the
   delivery note with its before/after value.

**Runtime policy.** Per think tick (8 Hz, jittered), the same as every other
judgement in the file and the same as miners already dispatch. Per-frame
work removed, none added.

**Behavioural change, stated.** An idle nurse, comb worker or honey maker
notices newly available work up to 125 ms later than today (mean about 62
ms). Miners already behave this way and `docs/PERFORMANCE_BASELINE.md`
records it as a contract. No resource amount, order, target choice or
priority changes. If requirement 5 shows a counter moving by more than
random jitter between seeds, stop and report it: that would mean some path
relied on same-frame re-dispatch.

**Edge cases.** A bee that enters an idle state on a non-think frame waits
at most one tick (already true for `MOVE_TO_POINT` → `_default_state_for_role`
→ idle). `_apply_pending_role` is already on the think tick, so a queued
role change lands no later than before. `_maybe_break_off_secondary` is
already think-gated.

**Automated acceptance.** `tools/verify.ps1` green. The equivalence run in
requirement 5 reports no gameplay counter difference, or every difference is
listed and explained. The `bee_state_builder` and `bee_state_honey` rows are
lower than requirement 1's; the delivery note gives the four numbers. A
`tests/source_checks.py::check_idle_dispatch_cadence` check: every
`_idle_dispatch()` call inside `_process`'s `match` is preceded on the
previous line by `if thinking:` or `if _miner_dispatch_due:`; fails on
`master` today, passes on the branch.

**Completion.** Add the before/after rows to `docs/PERFORMANCE_BASELINE.md`
under a dated heading, in the same table shape as "G2 re-measure". No
hands-on check: no player-visible behaviour is intended to change, and the
equivalence run is the instrument. Archive this section.

**Level:** medium (hot path and a simulation rule; the change itself is
three two-line edits). **Escalate if** requirement 1's numbers show the
three sections are already trivial (then drop the change and record why,
as PERF-1 would), or if requirement 5 shows a counter moving.

```
- Plan: plans/now/idle-dispatch.md -- "IDLE-1 — idle nurses, comb workers and honey makers look for work on the think tick"
- Files: scripts/bee.gd, docs/PERFORMANCE_BASELINE.md, tests/source_checks.py
- Check: two baseline runs before and after report lower bee_state_builder and bee_state_honey means, and the equivalence run on colony_30_bees_test.json shows no gameplay counter change
- Proof: absent: scripts/bee.gd :: check_idle_dispatch_cadence
- Next after: none -- idle-dispatch is complete.
```

(The `Proof:` line as written proves the *check* is absent; if the queue
tool requires a source-file symbol, use
`present: scripts/bee.gd :: State.BUILD_IDLE:\n\t\t\t_idle_dispatch()` is
not expressible on one line, so prefer the check-function form and add the
function name to `tests/source_checks.py` in the same slice.)

### 4.2 GDT-1 — one Godot boot runs the GDScript unit tests

*Owning plan: `plans/reference/check-loop.md` gains a durable rule; the slice itself in a new plans/now/gd-tests.md. Lane: either; owns `scripts/main.gd` (Claude lane's E1 owns it today, so queue after E1) plus tools and tests.*

**Purpose.** Finding D-3. Give every catalogue, resolver and migration slice
an executed test that costs one Godot boot, which `tools/verify.ps1` already
pays for the compile check.

**Owner.** `main.gd` owns boot arguments (`_apply_scenario_boot_arg` is the
precedent). `tools/godot_compile_check.py` owns "boot Godot headlessly and
read its output". This slice extends both; it adds no new subsystem.

**Required reading.** This section. `scripts/main.gd::_apply_scenario_boot_arg`
and the `_ready` lines around `TutorialCheckpoint.clear()` (the boot-argument
ordering). `tools/godot_compile_check.py` whole (165 lines).
`tools/verify.ps1`, the "godot boot" stage only. `tests/test_conditions.py`
(the test this replaces).

**Files likely to change.** `scripts/main.gd`; new scripts/headless/gd_test_runner.gd;
new folder `tests/gd/` with `test_conditions.gd` as the first file; new
tools/godot_test_check.py; `tools/verify.ps1`; `docs/headless-run-contract.md`
(one new section); `tests/test_conditions.py` (deleted, its cases moved).

**Must not change.** `--scenario=` behaviour; `tools/godot_compile_check.py`'s
failure patterns; anything under `scripts/` other than `main.gd` and the new
runner. No test may touch the scene tree beyond what its function under
test needs.

**Requirements.**
1. **Boot argument.** In `main.gd::_ready`, before `_apply_scenario_boot_arg()`
   and after `TutorialCheckpoint.clear()`, add:
   ```gdscript
   if "--gdtest" in OS.get_cmdline_user_args():
       GdTestRunner.run_all_and_quit(get_tree())
       return
   ```
   where `GdTestRunner` is a `const` preload of
   res://scripts/headless/gd_test_runner.gd, beside the existing headless
   preloads. Returning before world construction is the point: no bees, no
   meadow, no HUD.
2. **Runner.** scripts/headless/gd_test_runner.gd, `extends RefCounted`,
   one static function `run_all_and_quit(tree: SceneTree) -> void`:
   - List `res://tests/gd/` with `DirAccess`, take every file matching
     `test_*.gd`, `load()` each.
   - For each script, for each method in `get_script_method_list()` whose
     name begins `test_`, call it with no arguments inside a fresh
     `RefCounted` instance of the script. A method that returns `true` or
     `null` passes; `false` or a `String` fails, the string being the
     message.
   - Print exactly one line per test: `GDTEST PASS <file>::<method>` or
     `GDTEST FAIL <file>::<method>: <message>`, then one summary line
     `GDTEST DONE <passed>/<total>`.
   - `tree.quit(0 if failed == 0 else 1)`.
   Tests assert with a tiny helper on the same file:
   `static func expect(cond: bool, msg: String) -> String` returning `""`
   or `msg`, so a test reads `return expect(Conditions.met(main, spec), "...")`.
3. **Fake main.** Tests that need `main` build a `RefCounted` stand-in with
   only the members the function reads (`day`, `hive`, `queen`, `season`,
   `_role_counts()`), following `progression.md` section 11's "a test can
   pass a stand-in". `test_conditions.gd` needs a stand-in hive exposing
   `total()`, `cells_holding()` and a `cells` array of stand-in cells with
   `designated_type`, `designation_is_explicit`, `is_built`. Twelve tests,
   one per `conditions.gd` key, replacing `tests/test_conditions.py`'s
   substring checks.
4. **Python wrapper.** tools/godot_test_check.py: import `find_godot`,
   `TIMEOUT_SECONDS` and the skip logic from `tools/godot_compile_check.py`
   (refactor them into importable names there if they are module-level
   code; do not copy them). Run
   `<godot> --headless --path <repo> -- --gdtest`, fail on any `GDTEST FAIL`
   line or on a missing `GDTEST DONE` line, and print the `DONE` line. Skip
   with exit 0 where the compile check would skip.
5. **Verify stage.** In `tools/verify.ps1`, directly after the "godot boot"
   stage and with the same `if ($lastStageExit -ne 0) { exit ... }` guard,
   add `Invoke-PythonStage -Name "godot tests" -ScriptPath (Join-Path $repoRoot "tools/godot_test_check.py") -FailureNote "a GDScript unit test failed"`.
6. **Contract doc.** One section "GDScript unit tests" in
   `docs/headless-run-contract.md`: the argument, the folder, the naming
   rule, the pass/fail convention, and the sentence "a slice that adds a
   catalogue row, a resolver branch or a migration step adds a `tests/gd/`
   case in the same slice".

**Runtime policy.** Development only. Nothing runs unless `--gdtest` is
passed. Normal boot gains one `in` test over the user-args array.

**Edge cases.** No `tests/gd/` folder (print `GDTEST DONE 0/0`, exit 0). A
test script that fails to load (report as one FAIL naming the file). A test
that throws (Godot prints a `SCRIPT ERROR`; the wrapper must treat that as a
failure too, reusing the compile check's patterns). Windows path separators
in `DirAccess` (use `res://`).

**Automated acceptance.** `python tools/godot_test_check.py` prints
`GDTEST DONE 12/12` on a machine with Godot and skips cleanly on one
without. Deliberately breaking one `conditions.gd` arm (for example
returning `true` for `queen_alive`) makes exactly one test fail and the
stage go red. `tools/verify.ps1` stays green. `tests/test_conditions.py` is
gone and nothing references it.

**Completion.** Add the durable rule to `plans/reference/check-loop.md` as
rule 11: "A pure function ships with an executed test in `tests/gd/`, not a
substring check". Archive this section.

**Level:** medium. **Escalate if** the runner cannot call a static method on
a loaded script without instancing a Node (then use a `Node` instance freed
after each test and say so), or if the boot cannot return before world
construction without a change to `_ready`'s ordering that touches
`Session.menu_pending`.

```
- Plan: plans/now/gd-tests.md -- "GDT-1 — one Godot boot runs the GDScript unit tests"
- Files: scripts/main.gd, scripts/headless/gd_test_runner.gd, tests/gd/test_conditions.gd, tools/godot_test_check.py, tools/godot_compile_check.py, tools/verify.ps1, docs/headless-run-contract.md, tests/test_conditions.py
- Check: python tools/godot_test_check.py prints GDTEST DONE 12/12 and a deliberately broken conditions.gd arm turns exactly one line to FAIL
- Proof: absent: scripts/main.gd :: --gdtest
- Next after: none -- gd-tests is complete.
```

### 4.3 CH-1 — a Challenge is a field on the level record, looked up once

*Owning plan: a new plans/now/challenge-data.md (CH-1, CH-2, CH-3). Lane: Claude, after C1F-1 (guardrail 14: `challenge_runner.gd` order is E1, C1F-1, then this, then F2s and G3).*

**Purpose.** Finding E-1. Nineteen `Session.starting_level == n`
comparisons and one hardcoded `_stages()` ternary are what make a third
Challenge a runner edit. Replace the integer identity with a string field
read once.

**Owner.** `levels.gd` owns what a level is; `challenge_stages.gd` owns
stage data; `challenge_runner.gd` owns when a stage is entered. This slice
moves one fact (which Challenge this run is) from `Session.starting_level`
into the level record, which already carries per-Challenge flags
(`queen_laying_backup`, `designation_keeps_stores`).

**Required reading.** This section. `scripts/levels.gd` (whole, 168 lines).
`scripts/challenge_stages.gd`: the header and the `STAGES_1`/`STAGES_2`
declarations only. The nineteen sites:
`grep -n "starting_level == [0-9]\|starting_level != [0-9]\|starting_level in \[" scripts/*.gd`.
`scripts/challenge_runner.gd::start`, `_stages`. `scripts/main.gd::_ready`
around `challenge_runner.start()`.

**Files likely to change.** `scripts/levels.gd`, `scripts/challenge_stages.gd`,
`scripts/challenge_runner.gd`, `scripts/main.gd`, `scripts/world_building.gd`,
`scripts/debug_panel.gd`, `scripts/challenge_complete.gd`,
`scripts/scenario_actions.gd` (only if it maps `challenge: 1` to a level
id; check `_apply_scenario_boot_arg` in `main.gd` first), `tests/source_checks.py`.

**Must not change.** Any stage record's content; any goal predicate; the
save format (`Session.starting_level` stays as it is and keeps being
saved); `main_menu.gd`; `docs/challenge-stages.md` except through
`python tools/stage_reference.py`.

**Requirements.**
1. `levels.gd`: level 1 gains `"challenge": "c1"`, level 2 gains
   `"challenge": "c2"`. No other level has the key. Add
   `static func challenge_id(level_id: int) -> String` returning
   `get_level(level_id).get("challenge", "")`.
2. `challenge_stages.gd`: add
   ```gdscript
   const STAGES_BY_CHALLENGE := {"c1": STAGES_1, "c2": STAGES_2}
   static func for_challenge(challenge_id: String) -> Array:
       return STAGES_BY_CHALLENGE.get(challenge_id, [])
   ```
3. `challenge_runner.gd`: a `var _challenge_id: String = ""` set once in
   `start()` from `Levels.challenge_id(Session.starting_level)`. `_stages()`
   becomes `return Stages.for_challenge(_challenge_id)`. Every
   `Session.starting_level == 1` in the file becomes `_challenge_id == "c1"`,
   every `== 2` becomes `_challenge_id == "c2"`, `!= 1` becomes `!= "c1"`.
   Fifteen sites; change every one, none by judgement.
4. `main.gd`: `elif Session.starting_level in [1, 2]:` becomes
   `elif not Levels.challenge_id(Session.starting_level).is_empty():`.
5. `world_building.gd` (Poppy exclusion), `debug_panel.gd`,
   `challenge_complete.gd`: the same substitution through
   `Levels.challenge_id(Session.starting_level)`. `challenge_complete.gd`
   may keep a local `is_challenge_one` bool computed once.
6. `tests/source_checks.py`: a `check_challenge_identity` that fails on any
   `starting_level ==`, `starting_level !=` or `starting_level in [` in
   `scripts/*.gd` outside `levels.gd`. Fails on `master`, passes on the
   branch.

**Runtime policy.** Unchanged. `_challenge_id` is read from a field instead
of compared to a literal; no per-frame cost added or removed.

**Edge cases.** A save from before this slice: `Session.starting_level` is
what is saved and is unchanged, so `Levels.challenge_id` resolves it the same
way. A `--scenario` run with `"challenge": 1` (H4): find where the harness
sets `starting_level` for that field and leave it; the lookup then works
through `levels.gd` unchanged. `Levels.SCENARIO_LEVEL_ID` returns `""`
(no Challenge), which is today's behaviour.

**Automated acceptance.** `tools/verify.ps1` green including the new source
check. `test_scenarios/h4_challenge1_stage_advance_test.json` and one
Challenge 2 fixture (`grep -l '"challenge": 2' test_scenarios/*.json`) reach
the same final stage as on `master`. `python tools/stage_reference.py --check`
green. `tools/equivalence.py` on the Challenge 1 fixture reports no
difference.

**Completion.** No hands-on check (no visible behaviour changes). Set
`Next:` to CH-3, then CH-2. Archive this section.

**Level:** medium (nineteen mechanical edits, one ownership move; the level
is medium only because `challenge_runner.gd` is the contended file and the
save path must be reasoned about once).

**Escalate if** any site compares `starting_level` for a reason other than
Challenge identity (none found on 18 Sep, but say so if one appears), or if
the harness's `challenge` field cannot be routed through `levels.gd`.

```
- Plan: plans/now/challenge-data.md -- "CH-1 — a Challenge is a field on the level record, looked up once"
- Files: scripts/levels.gd, scripts/challenge_stages.gd, scripts/challenge_runner.gd, scripts/main.gd, scripts/world_building.gd, scripts/debug_panel.gd, scripts/challenge_complete.gd, tests/source_checks.py
- Check: check_challenge_identity fails on master and passes on the branch; h4_challenge1_stage_advance_test.json and a Challenge 2 fixture reach the same final stage as master
- Proof: absent: scripts/levels.gd :: "challenge": "c1"
- Next after: CH-3 -- cadence moves into the stage record.
```

### 4.4 CH-2 — the five stage-id branches in `_enter_stage` become stage keys

*Owning plan: plans/now/challenge-data.md. Depends on CH-1 (same file; sequential in the Claude lane).*

**Purpose.** After CH-1, entering a stage still branches on `"1.1"`,
`["1.6" .. "1.10"]`, `"1.8"`, `"1.11"`, `"1.4"`/`"1.7"`, `"1.19"` and the fog
mode. Each is a fact about that stage written in the runner instead of the
record. Move them, so a new Challenge's stages declare their own entry
behaviour and the runner reads keys.

**Root cause, confirmed.** `challenge_runner.gd::_enter_stage` (read with
`python tools/func.py scripts/challenge_runner.gd _enter_stage`). Seven
literal-id decisions: command lock, role-change lock, collection counter
reset, forage-rate override, hive reveal mode, ordered visit start, farewell
bubble.

**Required reading.** This section. `_enter_stage`, `_leave_stage`,
`_begin_ordered_visit`, `_clear_ordered_visit`, `_hive_inspection_points`,
`_meadow_inspection_points`. `challenge_stages.gd`: the records for 1.1,
1.4, 1.6 to 1.11, 1.19, and the `player_driven` key comment (the precedent:
"a stage that does not declare the key drives nothing, so the flag clears
itself"). `tests/source_checks.py::check_stage_effects_order`.
`docs/challenge-stages.md` for what each of those stages asks.

**Files likely to change.** `scripts/challenge_stages.gd`,
`scripts/challenge_runner.gd`, `tests/source_checks.py`,
`tools/stage_reference.py` only if it must ignore the new keys (check its
column list first).

**Must not change.** Goal predicates, `GOAL_CADENCE` (CH-3), `on_enter`
effect vocabulary, `_update_marker` (its id branches are a fourth shape and
are left for a later slice; see Escalate), any timing constant, C1F-1's
`setup` key.

**Requirements.** Each new key defaults to "do nothing", exactly as
`player_driven` does, so a record that omits it behaves as every non-Challenge-1
stage does today.

| Key | Type, default | Replaces | Set on |
| --- | --- | --- | --- |
| `command_locked` | bool, false | `queen_command_locked = starting_level == 1 and stage.id == "1.1"` | 1.1 |
| `role_change_locked` | bool, false | `stage.id in ["1.6", ..., "1.10"]` | 1.6, 1.7, 1.8, 1.9, 1.10 |
| `reset_counters` | Array of String, `[]` | `if stage.id == "1.8": _c1_queen_collections = 0` | 1.8 with `["c1_queen_collections"]`; the runner resets each named `_`-prefixed field through `set("_" + name, 0)` |
| `forage_rate_multiplier` | float, 0.0 (meaning none) | the `"1.11"` block | 1.11 with `Stages.CHALLENGE1_FORAGE_SPEED_MULTIPLIER`; the idempotent base-rate capture stays in the runner and runs whenever the key is non-zero |
| `hive_reveal_mode` | String, "" | `set_hive_reveal_mode("queen" if "1.1" else "open_space")` | 1.1 with `"queen"`; every other Challenge 1 record with `"open_space"`. An empty value leaves fog alone (today's non-Challenge-1 behaviour) |
| `ordered_visit` | String, "" | the 1.4/1.7 branches | 1.4 with `"hive"`, 1.7 with `"meadow"`; the runner maps `"hive"` → `_hive_inspection_points()`/`hive_root`, `"meadow"` → the meadow pair, `""` → `_clear_ordered_visit()` |
| `farewell_bubble` | bool, false | the 1.19 block | 1.19 |

The `role_restricted_to` derivation (`_queen_allowed_role_ids(stage.unlocked_keys)`)
is already data-driven and stays. The two `Session.starting_level == 1`
guards around these blocks (CH-1 turns them into `_challenge_id == "c1"`)
are removed once the keys carry the meaning, since a Challenge 2 record
simply omits the keys.

**Runtime policy.** Stage entry only. Unchanged.

**Edge cases.** C1F-1's `setup` key sits beside these and is applied by the
debug arrows before `_enter_stage`; it does not read them. A record with
`ordered_visit` but no visit points for its Challenge (a Challenge 3 that
sets `"hive"`) uses the same `_hive_inspection_points()`, which is
geometry, not Challenge 1 data.

**Automated acceptance.** `tests/source_checks.py`: a check that
`_enter_stage` contains no string literal matching `"[12]\.[0-9]+"`; fails
on `master`, passes on the branch. `check_stage_effects_order` still passes.
`h4_challenge1_stage_advance_test.json` reaches the same final stage;
`tools/equivalence.py` on it reports no difference. `python tools/stage_reference.py --check`
green (regenerate if it lists keys).

**Completion.** C-49's PASS line is unaffected. No hands-on check. Archive
the section; if CH-3 has shipped, set `Next: None — plan complete`.

**Level:** medium. **Escalate if** `_update_marker`'s branches need to move
too for a stage to be fully data-described (they do, but that is a fourth
key and its own slice, CH-4, because `_update_marker` reparents a shared
node and `docs/known-pitfalls.md` records a bug in exactly that), or if any
key's default cannot mean "do nothing" without changing a Challenge 2 stage.

```
- Plan: plans/now/challenge-data.md -- "CH-2 — the five stage-id branches in _enter_stage become stage keys"
- Files: scripts/challenge_stages.gd, scripts/challenge_runner.gd, tests/source_checks.py
- Check: a source check that _enter_stage holds no stage-id literal fails on master and passes on the branch, and h4_challenge1_stage_advance_test.json reaches the same final stage
- Proof: absent: scripts/challenge_stages.gd :: "ordered_visit"
- Next after: none -- challenge-data is complete (CH-4, the marker anchors, is filed under "Not in the queue" until someone wants it).
```

### 4.5 DOC-2 — one home for the merge rules, and the UI rules move to reference

*Owning plan: `plans/now/agent-lifecycle.md` "Standing rules" is the nearest owner; or run it as a documentation-only branch with `verify.ps1 -Docs`. Level: low.*

**Purpose.** Findings B-2 and A-2: the merge/lane rule has four homes, the
panel-rectangle rule has four, and `plans/archive/ui_2026-09-20.md` holds durable rules and
no slice.

**Required reading.** This section. `plans/reference/closeout.md` "When to
merge" and "Branches follow the lanes". `plans/workstreams.md` "Lanes" and
"When to merge". `CHATGPT.md` "Purpose and operating modes" paragraphs 3 to
5. `plans/archive/ui_2026-09-20.md` "Durable rules". `plans/README.md` "Directory contract"
and guardrail 11. `plans/reference/check-loop.md` rule 6.
`.claude/rules/documentation.md` (for what `check_docs.py` enforces).

**Files likely to change.** `plans/reference/closeout.md`,
`plans/workstreams.md`, `CHATGPT.md`, new plans/reference/ui-rules.md
(moved from `plans/archive/ui_2026-09-20.md`, which is deleted), `plans/README.md`,
`plans/reference/check-loop.md`, `DESIGN_BACKLOG.md`, `CLAUDE.md`'s routing
table row for UI.

**Must not change.** `NEXTSTEPS.md`'s item schema; `plans/workstreams.md`'s
table (parsed by `tools/slice.ps1`); any `Status:` line's field set.

**Steps.**
1. In `plans/workstreams.md`, delete the "When to merge" section. Replace it
   with one line: "When to merge, and who closes out which branch:
   `plans/reference/closeout.md`." Keep "Lanes" and the table.
2. In `CHATGPT.md`, replace the three paragraphs that restate start/finish/
   merge timing with one paragraph: the two commands, "the same command and
   timing as Claude", and `python tools/heading.py plans/reference/closeout.md "When to merge"`.
   Keep "Risk-proportional closeout" whole; it is the one thing only
   `CHATGPT.md` says.
3. `git mv plans/archive/ui_2026-09-20.md plans/reference/ui-rules.md`. Change its header
   to `<!-- CONTEXT: plan | LAYER: reference -->` and `Status: reference`.
   Delete "Open slices at a glance", "UI-P", "Closed groups" (leave one line
   pointing at `plans/archive/UI-X_2026-09-18.md` for the last shipped
   group). Keep "Durable rules" and "Deferred decisions".
4. In `plans/README.md` guardrail 11 and `plans/reference/check-loop.md`
   rule 6, keep the first sentence and replace the rest with "Full rule and
   its history: plans/reference/ui-rules.md."
5. Update every backticked `plans/archive/ui_2026-09-20.md` (`grep -rl "plans/archive/ui_2026-09-20.md" --include=*.md .`)
   to the new path: `plans/README.md` routing table, `DESIGN_BACKLOG.md`,
   `CLAUDE.md`'s "UI, theme, layout or accessibility" row.
6. In `plans/README.md` "Current routing", delete the UI-R/Q/P/D row and
   the L-1..L-9 row; change the A1..G3 row to "E1, F1s, F2s, G3"; add rows
   for "WD-1..WD-4" → `plans/archive/WORKFLOW_DIAGNOSTICS_2026-09-18.md`, "PERF-1" →
   `plans/reference/technical-audit.md`, "SM-1" → `plans/archive/SMOKE_SCENARIO_2026-09-19.md`.
   Renumber the "Writing or editing a plan" rules 1 to 10 in order.
7. Run `python tools/check_docs.py`.

**Acceptance.** `check_docs.py` passes. `grep -rn "one slice, one branch" --include=*.md .`
returns exactly one file. `grep -rln "plans/archive/ui_2026-09-20.md"` returns nothing.
`tools/slice.ps1 doctor -Lane Claude` still parses the ledger (its table is
untouched).

**Rollback.** Doc-only; `git revert` of the one commit.

```
- Plan: plans/now/agent-lifecycle.md -- "DOC-2 — one home for the merge rules, and the UI rules move to reference"
- Files: plans/reference/closeout.md, plans/workstreams.md, CHATGPT.md, plans/reference/ui-rules.md, plans/archive/ui_2026-09-20.md, plans/README.md, plans/reference/check-loop.md, DESIGN_BACKLOG.md, CLAUDE.md
- Check: check_docs.py passes and "one slice, one branch" appears in exactly one Markdown file
- Proof: absent: plans/reference/ui-rules.md :: Durable rules
- Next after: none.
```

---

## 5. Changes to how future plans should be written

The existing schema (`plans/README.md`) and its ten rules are good and are
mostly followed. These additions target what this review found missing, in
order of leverage. None restates an existing rule.

1. **Every slice section ends with its queue block.** The five lines
   (`Plan:`, `Files:`, `Check:`, `Proof:`, `Next after:`) in a fenced block,
   written when the plan is written. L-12 proposes tooling around this; the
   habit does not need the tooling. Its effect is that `Proof:` is written
   by the person who knows what the code looks like, not improvised at
   closeout, and that a `Files:` line is checked against the acceptance
   (A-3 would not have happened).
2. **Separate `Owns:` from `Reads:`.** A slice owns the files it edits and
   reads others. E1 reads `scenario_actions.gd` to write a fixture and must
   own it to add a verb. The table column "Files owned" hides the second
   kind. Two lines, not one.
3. **Name the acceptance instrument and prove it exists.** Under
   "Automated acceptance", one line: `Instrument: <verb or check function>
   (present: <file> :: <symbol>)`. If the instrument does not exist, the
   slice either builds it (and it goes on `Owns:`) or the acceptance is not
   written yet. This is F18 and A-3 turned into a line the planning model
   has to fill.
4. **A `Blocked by:` line with an id, not a sentence.** "Startable: after
   UI-X-2 and E1" expires silently. `Blocked by: E1` can be checked against
   `plans/archive/` by `check_docs.py` (it already warns on the archived-id
   case for queue items; extend to plan tables). Rule 10 then becomes
   enforceable instead of a re-verification ritual.
5. **State the cadence of anything that repeats, in one of seven words.**
   Rule 5 already asks for this; make the vocabulary fixed: `frame`,
   `think-tick`, `1 Hz`, `event`, `dirty-flag`, `stage`, `once`. C-1 is a
   case where the file's own prose said "think tick" and the code said
   "frame"; a plan that names the word makes the source check writable.
6. **A behavioural side effect gets its own bold paragraph** headed
   "Behavioural change, stated", even when it is latency only (4.1) or a
   random-stream reorder (SF-1 already does this well). A reviewer on a
   phone should find it without reading the requirements.
7. **Decisions for Dave are lettered options with a cost each, in a
   `Decision needed:` block**, so the answer can be one letter. Rule 8 says
   "escalate with the options and their costs"; this fixes the shape.
   Example from this review (B-5): "A. Add `via git show HEAD:` to review
   prompts (no repo change). B. Comment the deny list in
   `.claude/settings.json` with the workaround (one file). C. Remove the two
   root-file denies (every session may read them; ~1.4K tokens each time
   one does)."
8. **Keep a slice section under about sixty lines; put the rest under a
   sibling reference heading.** `tools/heading.py` prints one heading. C1F-1
   is 150 lines because its twenty-row table is inside the slice; the table
   could be "C1F-1 — the setup each stage declares" as its own heading,
   named under `Required reading`, so a session that only needs the
   requirements pays for the requirements. The plan is right to have the
   table; it is the heading level that costs.
9. **History goes to the archive at the transition, not to a "Current
   state" section.** `agent-lifecycle.md` and `workflow-diagnostics.md` both
   grew one. A live plan's "State" is three sentences: what shipped last,
   what is next, what is blocked.
10. **The planning model verifies one thing per plan by running it.**
    Rule 1 says "run the grep". The cheapest concrete version: every plan
    edit runs `python tools/check_docs.py` and, for any slice that names a
    scenario verb, `grep "static func _do_<verb>" scripts/scenario_actions.gd`.
    Both are allow-listed commands.

---

## Self-check

- Every finding cites a file and symbol, or a plan and heading; the two
  inferences (C-1's share of the baseline cost, C-3's scaling remarks) are
  labelled as inferences.
- The one recommendation that changes behaviour (4.1, up to 125 ms of
  dispatch latency) is flagged in the summary, the finding and the plan, and
  is bounded by an equivalence run.
- No plan asks the implementer to decide an ownership boundary: 4.1 names
  the flag to use, 4.2 names the boot argument and its position, 4.3 lists
  every site, 4.4 tabulates every key with its default and its stage.
- ECS, inheritance and data-driven catalogues are each recommended only
  where an existing file already uses the pattern and a cited site does
  not (E-1, D-2), and the technical audit's "Not a case for ECS" is upheld.
