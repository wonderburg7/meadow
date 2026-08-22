# Insights from ChatGPT

Purpose: a short advisory hand-off from ChatGPT/Codex to Dave and Claude.
ChatGPT may add findings and recommendations here while analysing or running
Meadow, but does not edit the game's code. Entries should be dated, concise,
and treated as suggestions for Claude to assess rather than build instructions
that have already been approved.

## Implementation status

Slices and file references are in `CHATGPT_INSIGHTS_PLAN.md`. Update the
status column here as each slice ships -- don't edit the dated entries
below, which are ChatGPT's own record.

| Slice | What | Status |
|---|---|---|
| C1 | Anything nurses feed before jelly | Built, 22 Aug -- headless comparison still open |
| C2 | Stop undesignated jelly spill | Built, 22 Aug -- headless comparison still open |
| C3 | Honey fanning stacks | Not started |
| C4 | Stocking hatch fallback | Not started |
| C5 | Role outcome telemetry | Not started |
| C6 | Re-run balance comparisons | Not started |
| B1 | Shared settings-cascade command | Not started |
| B2 | Split role assignment from role mode | Not started |
| B3 | Postcondition evidence for remaining verbs | Not started |
| B4 | Live settings in analysis | Not started |
| A1 | Unique run IDs | Not started |
| A2 | Explicit `random_seed` field | Not started |
| A3 | `--fixed-fps` benchmark | Not started |
| A4 | Cap failure output | Not started |
| A5 | Early-success stop + brief reports | Not started |
| A6 | Headless presentation gate | Not started |

(B5 -- observe-pause-act loop -- and A7 -- release export -- are
backlog, not slices; see the plan.)

## 22 August 2026: faster, token-efficient headless runs

### Bottom line

The harness currently makes **game time** advance faster with
`Engine.time_scale`, but it still launches Godot on its ordinary real-time
loop. The best next experiment is Godot's `--fixed-fps` command-line option,
which explicitly disables real-time synchronisation. Used with `--headless`,
this should let Meadow execute a chosen number of simulation steps as fast as
the CPU can manage instead of waiting for wall time.

Keep simulation speed and simulation fidelity as two separate controls:

- `--fixed-fps` controls the fixed idle-frame delta and removes the wait for
  real time.
- `Engine.time_scale` multiplies that delta.
- The important fidelity number for Meadow is therefore approximately
  `time_scale / fixed_fps` simulated seconds per `_process` call, not the
  headline multiplier on its own.

Godot documents that `--fixed-fps` disables real-time synchronisation and
gives every process frame the same delta. Its general advice is to increase
physics ticks when using a large `time_scale`, but Meadow has no
`_physics_process` functions: its simulation lives in `_process`. Raising
physics ticks is therefore not the first lever to pull here. The relevant
Godot references are the
[command-line options](https://docs.godotengine.org/en/latest/tutorials/editor/command_line_tutorial.html)
and [Engine timing properties](https://docs.godotengine.org/en/4.6/classes/class_engine.html).

### Why 30x is not yet a sufficient fidelity test

At a nominal 60 frames per second, `time_scale = 30` gives each process call
about 0.5 simulated seconds. A bee is meant to think eight times per simulated
second, but `bee.gd` can only notice an expired think timer on a process call.
With a 0.5-second step, it can therefore think only about twice per simulated
second. Movement, arrival checks, short timers and several same-day events can
also be crossed in one large step.

The existing 8x/16x/30x comparison checked final death totals. That was a good
smoke test, but identical deaths do not prove identical behaviour. Before
making a faster route authoritative, compare at least:

- action acceptance and postconditions;
- travel/path completion and stall recoveries;
- flower visits, collection rate and recruitment;
- feeds, builds, mines, honey batches and other role throughput;
- population, deaths and resource totals.

Start with non-real-time 1/60-second steps as the fidelity baseline. Then try
1/30, 1/15 and, only if needed, larger steps. Choose the largest step whose
relevant outcomes stay within a defined tolerance. This can be much faster
than real time even at a small step because `--fixed-fps` removes the wall-
clock wait. Do not assume `--disable-render-loop` helps; benchmark it after
`--fixed-fps`, since headless mode already removes the display and Meadow may
still spend CPU scheduling redraw work.

### Remove work that a headless result cannot use

Headless mode removes the window, but Meadow still executes presentation code.
`main.gd::_process` currently handles camera following, selection redraws,
scenery visibility and fog every frame before it reaches simulation work.
Other scripts still update labels, HUD state and visual effects.

Use one explicit `scenario_active`/headless presentation gate around those
paths, while leaving every state decision and resource transfer untouched.
This follows the project's existing rule that presentation may be skipped but
simulation may not. Measure before and after with a fixed scenario and fixed
step. A dedicated-server-style release export is a later optimisation: Godot
says export-template binaries are smaller and more optimised than the editor
binary, but an export workflow is only worthwhile if repeated runs show that
startup or editor overhead is material.

### Stop as soon as the question is answered

The original plan proposed event-count stop conditions, but the built path
currently stops only at `max_days`, queen collapse or a failed assertion. A
successful action script can finish its useful checks early and then simulate
many irrelevant days.

Add one or both of:

- explicit success/stop actions;
- `stop_when_actions_resolved`, ending once every action and assertion has
  either passed or failed.

Also support threshold stops for event count, population, stores and completed
work. Early success should be as loud and structured as early failure. This is
often a larger saving than another engine-level speed increase.

### Make repeats informative rather than habitual

`main.gd::_ready` calls `seed(12345)` before the meadow is built. Most of the
random simulation after that point is consequently repeatable, even though the
runner currently describes every repeat as an independent random trial. Five
near-identical runs consume time and tokens without providing five independent
samples.

Make `random_seed` an explicit scenario field, apply it before world creation
and log it. Then use:

- one fixed seed for wiring, regression and action-driver checks;
- a small named seed set for balance distributions;
- the same seeds on both sides of an A/B comparison, so randomness cancels
  rather than requiring many extra runs.

Run one short smoke seed first. Expand to three or five seeds only if it passes
and the question genuinely concerns variation. Stop a batch on an invariant or
action failure rather than finishing doomed repeats.

### Treat the analyser as the boundary of the AI conversation

Raw JSONL is a useful forensic artifact, not a useful default model input.
The normal AI workflow should be one command that runs the whole requested
matrix locally, analyses it locally, then returns a compact verdict. Claude or
ChatGPT should not launch each repeat in a separate tool call or read every log
line between runs.

A useful default report would contain only:

- scenario name, code revision, step size, seeds and wall time;
- pass/fail and stop reason;
- action problems and failed invariants;
- the question-specific metrics as min/median/max or A/B deltas;
- at most a few anomalies, each with a run ID and artifact path.

Keep full curves, individual deaths and snapshots in a saved report opened
only when the compact result identifies an anomaly. Add report profiles such
as `brief`, `balance`, `behaviour` and `full`; do not make `--full` the normal
AI path. Prefer event counters and milestone snapshots over hourly snapshots
for long runs, and let the scenario declare which metrics its report needs.

One concrete failure today showed why this matters. A Codex-side trial hit an
environment-specific AppData permission problem after the installed Godot
4.7.1 process crashed. The runner printed the entire native crash backtrace
and then an uncaught Python traceback. This is not evidence of a Meadow game
bug, but it turned one small infrastructure failure into thousands of tokens.
Save complete stdout/stderr to an artifact, then print only a classified error,
the final 10-20 relevant lines and the artifact path. Catch an inaccessible
log directory and report it in one line instead of continuing into a traceback.

This matches current official OpenAI guidance: keep prompts and tool surfaces
lean, reduce bounded intermediate results programmatically, and judge savings
by final-answer quality as well as token count. See
[OpenAI model guidance](https://developers.openai.com/api/docs/guides/latest-model).

### Suggested implementation order

1. Add a runner option for `--fixed-fps`, record wall time and benchmark a
   1/60-step baseline against progressively larger fixed steps.
2. Cap failure output and save full stdout/stderr outside the conversation.
3. Add explicit run IDs, seeds and paired-seed A/B batches.
4. Add early-success stop conditions and question-specific brief reports.
5. Gate presentation-only work in scenario runs and measure the gain.
6. Consider a release/dedicated export only if the measurements still show
   worthwhile editor/startup overhead.

## 22 August 2026: first real test of the headless action driver

### What was tested

The implemented action driver was exercised through real Godot runs, not only
read in source:

- The supplied slice 7 fixture ran to day 3 with all four actions accepted.
- A separate 15-day strategy changed a comb worker into a forager on day 3,
  added a nurse once honey appeared, checked the resulting role count and
  checked that food stores existed by day 12.
- Build and mine orders were issued against valid axial targets.
- A failed assertion ended its run immediately, while an event-triggered
  action whose condition never occurred was reported as `never_fired`.

The useful core is working. State and resource triggers can drive real player
commands, base-role changes affect the simulation, valid build/mine orders are
accepted, assertions are loud, and unresolved actions do not disappear. The
strategy run grew from 18 to 19 bees, made honey and suffered no deaths. The
normal source, balance and function-map checks also passed.

### Finding 1: settings actions do not follow the checkbox rules

`scenario_actions.gd::_do_set_config` calls
`DebugPanel.setting_set` directly. The real settings checkbox calls that setter
and then walks `Prerequisites`, turning prerequisites on or dependants off.
The headless action skips the second part.

This was visible in the supplied fixture: it switched Auto scouting on while
Orientation flight remained off, a state the settings window does not permit.
That breaks the driver's main promise that a semantic action follows the same
rules as a human action.

**Recommendation:** extract one shared semantic settings command which applies
the value, prerequisite cascade, dependant cascade and any live side effects.
Both the checkbox and the headless driver should call it. Avoid reproducing the
cascade separately in `scenario_actions.gd`.

### Finding 2: a combined role key can report a false success

The action driver says a key such as `forager_nectar` behaves like role
assignment. In `orders_zones.gd`, however, a base key such as `forager` changes
the role, while `forager_nectar` changes only the mode/focus of the selected
bees.

The test selected one comb worker and requested `forager_nectar`. The driver
logged `accepted` and described the result as `1 bees -> forager_nectar`, but
the next population snapshot still contained the same number of foragers. A
base-role request of `forager` in the corrected run worked immediately.

**Recommendation:** make role and mode explicit fields or separate verbs, for
example `assign_role: forager` plus `set_role_mode: nectar`. If a convenience
action supports both, apply them in the right order to the same resolved bee
IDs. Record those IDs and verify their actual role and mode before logging the
action as accepted.

### Finding 3: analysis reports the starting settings after mid-run changes

`tools/analyze_session.py` builds `mechanic_firing` from the initial `config`
log entry. It does not fold later `set_config` actions into that state. One run
recorded 91 tarsal marks after the action enabled Tarsal markers, while the
analysis still reported `toggle_on: false`.

That can make the summary internally contradictory and can hide a mechanic
that failed after being enabled during play.

**Recommendation:** log settings changes as structured before/after values,
including any cascaded changes, and build a settings timeline in the analyser.
At minimum, mechanic checks should use the last live setting value before the
summary rather than the boot snapshot.

### Recommendation: make `accepted` mean the requested result happened

At present, several verbs log `accepted` once they have called a command
function. That proves dispatch, not outcome. The combined-role test is the
concrete example.

Each verb should verify its smallest useful postcondition and log structured
evidence:

- role/mode: affected bee IDs and their resulting role/mode;
- designation: hex and resulting `designated_type`;
- build/mine: bee IDs plus the stored target or marked block;
- setting: requested value, final value and any prerequisite changes.

Keep scenario `assert` for strategy-level claims. Action-level postconditions
belong inside the driver because every scenario otherwise has to rediscover
whether its command vocabulary is truthful.

### Recommendation: distinguish scripted decisions from live autonomous play

The current driver executes decisions written into the scenario before the
run starts. State-triggered actions make that much more capable than a starting
preset, but ChatGPT still cannot inspect an unexpected day-7 snapshot and
invent a new response inside the same live colony. It can currently test a
policy it wrote in advance, or inspect one finished run and change the next
run's policy.

After the correctness issues above, the smallest genuine observe-then-decide
extension would be one dev-only decision point: pause at a requested trigger,
write the normal structured snapshot, accept another allowlisted action batch
with a timeout, then resume. This need not become screen control or mouse
injection. Until such a loop exists, describe the harness as a semantic
strategy-script runner rather than a fully autonomous player.

### Suggested order

1. Share settings semantics with the real checkbox path.
2. Separate role assignment from role mode and verify postconditions.
3. Make analysis reflect live settings changes.
4. Add structured action evidence for the remaining verbs.
5. Only then consider an observe-pause-act loop and a fixed random seed for
   reproducible behavioural failures.

## 22 August 2026: nurse, comb-worker, miner and honey-worker audit

### Method and an important test-environment note

The four indoor roles were tested in controlled headless colonies with
weather, disease, winter and the rival disabled. The shipped 200-second day
and shipped work durations were kept intact; only engine time was accelerated
to 30x. This matters because changing `seconds_per_day` would change a
90-second build or 120-second mine into a different number of game days and
would invalidate a balance comparison.

At the start of the audit, a current-`HEAD` launch reported that `hud.gd` could
not be parsed/preloaded, so `main.gd` never loaded. The role, hive, balance,
diagnostic and action-driver files were unchanged since `f9b9cfd`; only
`main.gd` had changed among the files in scope. To avoid mixing that unrelated
UI state into the role results, the scenarios ran from a temporary clean
snapshot of `f9b9cfd` using the exact current role code. A final current-`HEAD`
Godot boot later succeeded with only the project's existing warnings, so the
earlier preload failure was transient and is not an outstanding finding.

### Nurses: feeding works, but Anything currently behaves like Jelly first

The feed-only loop is coherent:

1. Pick the hungriest brood cell.
2. Fetch pollen first if short.
3. Fetch honey for carbohydrate when available, otherwise nectar.
4. Feed the larva, then stand over fed brood for the tending speed bonus.
5. Move to another larva when one becomes hungrier.

The queen also runs this loop as her default secondary job, and uniquely tries
nursing before laying whenever brood needs her.

Results after 600 simulation seconds in a stocked 20-cell hive:

| Dedicated nurses | Start population | Final population | Maximum corpses |
|---:|---:|---:|---:|
| 0 | 1 | 8 | 0 |
| 1 Feed | 2 | 10 | 2 |
| 2 Feed | 3 | 12 | 1 |

The zero-nurse colony grew because the queen is a capable backup nurse. This
contradicts the Nurse tooltip's statement that a colony cannot grow with no
nurse. Either clarify that dedicated nurses scale beyond the queen's small-
colony backup, or remove/restrict her nursing fallback if the role is meant to
be strictly required. The observed marginal gain from the first two dedicated
nurses was modest because pollen, not nurse time, became the limiting input.
At current values one worker costs 60 pollen for the egg plus about 18 pollen
across six nectar feeds, so the egg itself is roughly 77% of the pollen cost.

The `Anything` mode has a more serious order bug. Its tooltip promises
"feeding first", but `_try_role_work` attempts royal-jelly work before it even
looks for brood whenever `nurse_mode != "feed"`.

Two repeated rich-hive comparisons, each starting at population 3:

| Mode | Final population | Corpses at end | Jelly cells |
|---|---:|---:|---:|
| 2 Feed, run 1 | 11 | 2 | 0 |
| 2 Feed, run 2 | 13 | 0 | 0 |
| 2 Anything, run 1 | 5 | 4 | 3 |
| 2 Anything, run 2 | 5 | 3 | 3 |
| 2 Jelly | 5 | 4 | 3 |

Anything nurses spent roughly the first 220-243 simulation seconds making
and storing jelly before sustained brood work. In effect, Anything behaved
almost like Jelly. This killed worker larvae and sharply reduced growth.

One designated jelly cell also failed to cap production. Once that cell was
full, generic `hive.find_cell_for("jelly")` selected ordinary empty cells, so
the nurses spread jelly into three cells. A full 120-unit jelly cell requires
15 batches at current values, costing 180 pollen and 90 honey. Uncontrolled
spill therefore consumes the same pollen as three eggs per filled cell, before
counting the brood feeds it displaced.

**Recommendations:**

1. Make Anything honour its tooltip: feed hungry brood first, then make/store
   jelly when feeding is under control.
2. With no gyne brood, allow jelly production only while an explicitly
   designated jelly cell has room. Do not spill reserve jelly into generic
   empty comb.
3. Let an urgent gyne need override ordinary reserve stocking, but still make
   the priority visible and deterministic.
4. Re-run the Feed/Anything comparison after the logic change before tuning
   `jelly_pollen_cost`, `jelly_honey_cost`, `jelly_per_batch` or capacity. The
   current economic damage is dominated by wrong priority and unlimited
   spill, not proven bad constants.
5. Add nurse telemetry for feeds, jelly batches, larval deaths and target cell
   IDs. Multiple nurses can currently choose the same hungriest larva while
   `being_tended` is only a boolean, so their tending bonuses may also fail to
   stack or distribute. The present snapshots cannot prove which target each
   nurse had.

### Comb workers: core order and scaling are sound

The implemented order is:

- Building: manual targets, unfinished cells, then automatic outward growth.
- Clearing: dead larvae first, then resources that must be evicted.
- Stocking: maintenance first, then restock orders, then stop.
- Anything: dead larvae, eviction, restocking, then building.

The controlled eviction test worked. A Clearing worker entered
`TO_HAUL_SOURCE` and `TO_HAUL_TARGET` in the first 10 simulation seconds,
moved nectar out of the re-designated cell and preserved the resource. A
Building worker ignored the same eviction job and continued expanding.

With enough nectar to keep every worker alive, 1, 2 and 4 Building workers
completed 4, 8 and 15 cells respectively over 400 simulation seconds. They
consumed roughly 1, 2 and 4 full 200-unit nectar cells. Throughput and energy
cost therefore scale almost linearly, and the cost is proportionate to the
storage capacity created.

There is no evidence here to change `cell_build_time = 90` or
`build_energy_burn = 0.6`. An empty-hive control did demonstrate that a worker
building continuously without food can die in under a day, but that is the
expected consequence of the role's stated sugar cost, not a normal supplied
colony result.

Two sub-role issues remain:

- Stocking could not be run end to end because the action driver has no verb
  for setting restock targets/sources. Add that semantic action before calling
  the sub-role covered by autonomous tests.
- Code currently lets Stocking workers do clearing/eviction first because the
  maintenance condition is `architect_mode != "build"`. Since Clearing and
  Anything already exist as separate modes, decide whether a Stocking
  specialist should really be diverted by maintenance; its tooltip does not
  say so.
- `world_building.gd::_spawn_hatched_bee` accepts only `build`, `maintain` and
  `both` for a newborn comb worker. A nursery cell configured to hatch a
  Stocking worker is silently changed to Anything. Add `restock` to the valid
  list and cover it with a hatch test.

### Miners: manual priority, teamwork and Automine all work

The tested order matches the intended design: the miner's own queue first,
then any player-marked block, then the nearest exposed automatic choice when
Automine is enabled. Buried queued blocks are skipped until reachable.

For the same manually marked block, the last observed mining time was:

| Miners | Last `MINING` snapshot |
|---:|---:|
| 1 | 143.6 seconds |
| 2 | 65.8 seconds |
| 4 | 35.8 seconds |

The solo miner filled her 40-unit dirt load after 80 seconds, walked outside,
dumped it and returned to finish the 120-second block. Two and four miners
completed before any individual filled her own load. Automine remained active
through the entire 400-second run and repeatedly cycled through mining, exit,
dump and return states. Team progress therefore adds correctly.

`block_mine_time = 120`, `dirt_fill_rate = 0.5` and
`miner_dirt_capacity = 40` create a deliberate discontinuity: one miner must
interrupt every first block at 80 seconds, while two miners finish it without
a dump. This is coherent and does not require a balance change. If the solo
interruption feels fussy in hands-on play, capacity 60 would let one miner
finish a block before dumping while retaining the hauling loop between blocks.
Do not change it on simulation evidence alone.

Add a `mining_complete` event and snapshot counts for total, exposed and marked
soil. Current logs show what state miners occupy but not how much area they
actually opened, making long-run mining balance needlessly indirect.

### Honey workers: the production chain works, but fanning does not stack

The dispatch order is sensible: put down any carried mix first, fan existing
wet honey until usable, then fetch more nectar. With 800 starting nectar:

| Honey workers | Ripe honey at end | Result |
|---:|---:|---|
| 0 | 0 | No conversion, as expected |
| 1 | 200 | Part of the input converted |
| 2 | 400 | All input converted |
| 4 | 400 | All input converted earlier, then workers idled |

Four workers exhausted the input and were mostly idle by about 194 seconds;
two did so around 338 seconds. Fetching, chewing and depositing therefore
parallelise and the overall role has a real impact.

Fanning is wired differently from building and mining, however. Every honey
worker sets the same cell boolean `being_fanned = true`, and the cell adds
`delta` once regardless of how many workers asserted it. An isolated wet-cell
test confirmed the effect:

| Fanners visibly working | First ripe store snapshot |
|---:|---:|
| 1 | 37.2 seconds |
| 4 | 35.9 seconds |

Four workers provided essentially the same 30 bee-seconds of drying as one,
despite the source comment promising proportional contribution.

**Recommendation:** give honey cells an `add_fanning(delta)` operation like
build and mine progress, called once by every fanning bee, or accumulate an
integer fanner count rather than a boolean. Then re-run 1/2/4-worker throughput
before changing `honey_ripen_time = 30`; the current value has effectively
been balanced around non-stacking work.

The conversion constants also deserve an explicit design decision rather than
an incidental one. `nectar_per_honey = 2` and `honey_energy_factor = 4` mean
two nectar energy units become four energy units of honey before worker costs,
so honey making doubles stored calories as well as concentrating them. Keep
that if the role is meant to create a large economic gain. If honey is meant
only to preserve and compact existing energy, a ratio nearer 4 would be more
consistent. Model the whole colony and winter economy before changing either
number.

### Harness and telemetry findings from this audit

The normal Meadow instance was running while the headless audit ran. Two log
files received the same filesystem modification time, and
`run_scenario.py::newest_session_file` selected the live player's unfinished
session instead of the completed scenario. The analyser then had no summary.

Give every headless launch a unique run ID and include it in both the requested
scenario and diagnostic filename/config record. Select the result by that ID,
not by global newest modification time. A timestamp cannot safely identify one
producer when normal play and tests share `user://logs`.

The role audit also showed that snapshots need a few outcome counters, not
only state occupancy:

- brood feeds, jelly batches and larval deaths;
- completed/cleaned/evicted/restocked cells;
- completed blocks and remaining exposed/marked soil;
- honey batches deposited and cells ripened;
- the target bee/cell/block IDs behind each action.

These are small diagnostic additions, but they turn "the bee was seen in the
right state" into "the role produced the intended result" and make future
balance comparisons much more trustworthy.

### Recommended priority

1. Fix Anything nurses feeding after jelly and stop undesignated jelly spill.
2. Make multiple honey fanners contribute independently.
3. Fix the Stocking hatch fallback and decide whether Stocking should also do
   maintenance.
4. Give headless runs unique IDs and add the role outcome counters above.
5. Re-run the same comparisons before changing nurse/honey constants.
6. Leave comb-building values unchanged; treat miner capacity 60 as an
   optional feel improvement, not a required balance correction.
