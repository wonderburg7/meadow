# Meadow — architecture review: catalogues, shared interfaces and update policy

<!-- CONTEXT: plan | LAYER: design | LOAD: only when an architecture slice below is selected -->
Status: active -- decisions A, B and C taken by Dave 11 Sep 2026; H3, H1 and H2 shipped 11 Sep 2026; H4 is the Codex lane's second item, behind Hive comb Slice 5 -- its cross-lane file conflict with H2 is resolved now H2 has shipped, so it becomes claimable in ordinary lane order once Slice 5 lands | Owner: Dave / Claude Code | Next: H4 -- a headless run can start a Challenge and reach a stage | Dependency: H4 owns `challenge_runner.gd` and lands after C1-21 and C1-22 (both shipped); every A-G slice is held until Challenge 1's Slices 21-26 have vacated that file | Verified: 2026-09-11

**Objective.** Cut the number of files a future session must open to add a
resource, a role, a job, a Challenge stage, a window or a setting, by moving
each rule to one authoritative home, and remove the full-set scans and
per-frame checks that no longer earn their cost.

**Method.** A read of the `scripts/` directory against the areas Dave listed, checking each
against one test: would a data-driven catalogue, a shared interface or a base
class *remove* work, or only move it. Findings where the current code is
already the simpler answer are recorded under "Patterns deliberately not
applied" so a later session does not re-propose them.

**What this plan does not do.** It proposes no gameplay change. Every slice
below is behaviour-preserving unless its Requirements say otherwise and name
the escalation that must clear first.

## Decisions taken 11 Sep 2026

Dave answered the three the 11 Sep audit put to him. They are recorded here
because each one changes what a later session may start, and in one case what
this plan is *for*.

**A. Architecture work enters the queue now, but does not displace Challenge 1.**
H3 and H1 are admitted to `NEXTSTEPS.md` behind the open Challenge 1 items, and
H2 follows them. Every A, B, C, D, E, F and G slice is held until Challenge 1's
Slices 21 to 26 have vacated `challenge_runner.gd`. The hold is a blunt rule
rather than a per-file one: A2 and D1 do not touch that file and could in
principle start earlier, so if the Challenge 1 arc runs long, those two are the
ones to ask Dave about lifting first. Do not lift the hold unasked.

**B. This plan is the design pass for four of `product-scope.md` section 6.2's
shared foundations.** The stable catalogues and resolver, the goal model, the
job catalogue and dispatcher, and the catalogue half of the event director are
B1, C2, C4, F2s, G1 and G2 below. There will not be a second design pass on
them, so those slices carry that weight: build each one as the authority its
foundation needs, not as the narrowest thing that preserves today's behaviour.
Behaviour preservation stays the *acceptance* -- it is how each step is proved
safe -- but it is no longer the ceiling on the shape. Run policy and the event
director's selection logic remain product-scope's own design work and are not
this plan's to take.

**C. Settings persistence is three buckets, not sixty-one decisions.** Run
balance saves with the run; interface preference stays with the player and out
of the save; developer-only keys save nowhere. F11 and D1 below now carry the
rule, and D1's second half is no longer blocked.

**D. H4 lands between C1-22 and C1-24.** The 11 Sep plan review found that
nine slices across three plans assert a headless Challenge that cannot be
started (F18 below). Dave took the review's recommendation: build H4 after
C1-21 and C1-22, which are queued and whose acceptance is Dave's own hands-on
passes, and before C1-24 and C1-26, whose acceptance is nothing but headless
assertions. H4 therefore enters the Codex lane as C1-23's `Next after:`.

**E. A queue entry may name a file its slice creates.** `check_docs.py`'s
`validate_queue_files` and `check_backticked_paths` contradicted each other
about exactly that, and H3 had been working around it by reserving a sibling
file. The existence check gives way: it now skips any path declared on a
queue item's `Files:` line. Shipped the same day.

## Findings at a glance

| # | Finding | Benefit | Effort | Depends on |
| --- | --- | --- | --- | --- |
| F6 | `_hatch_ready_brood` walks every cell every frame | high | very low | — |
| F7 | Role counting written four times, key formula duplicated | high | low | — |
| F5 | The `hive.total()` family are full scans on hot readout paths | high | low | — |
| F4 | `GOAL_CADENCE` is declared and never read | high | low | F5 helps |
| F2 | The resource catalogue covers 2 of 7 cell-content kinds | high | medium | — |
| F3 | Three condition vocabularies ask the same questions | high | medium | F5, F7 |
| F12 | Problem signals are an if-chain with magic thresholds | medium | low | F3 |
| F11 | Settings persistence has three lists and measurable drift | high | medium | Dave's call |
| F8 | Nine `awaiting_*` placement flags, no mutual exclusion | medium | medium | — |
| F9 | Five windows duplicate construction and lifecycle | high | medium | — |
| F10 | Stage-gated UI is nine bespoke setters | high | medium | F9 |
| F1 | Bee work is a hardcoded role switch; no action catalogue | very high | high | F2, F3 |
| F16 | Twenty behaviour-preserving slices, and no instrument to prove it | very high | low | — |
| F14 | `hud.gd`'s first section header is at line 1294 | high | very low | — |
| F13 | Six scripts past the map's own threshold are not in the map | high | very low | — |
| F15 | A fifth hand-built role key, in `hive.gd` | — | — | corrects A2 |
| F17 | E1 removes nine flags and leaves nine signals | — | — | corrects E1 |
| F18 | Nine slices assert a headless Challenge that cannot be started | very high | medium | — |

## F1 — Bee work is dispatched by a hardcoded role switch

**Problem.** An action exists only as a branch inside its role's arm of one
function. Roles and actions are fused, so nothing can say "this bee may build
but not mine", "this action unlocks at stage 2.7", or "this action is only
available in season" without editing the dispatcher, the HUD and the Challenge
runner together. This is exactly the flexibility Dave asked for.

**Evidence.** `scripts/bee.gd::_try_role_work` is a ~160-line `match r:` whose
arms carry each role's work priority order, preconditions and target selection
inline. `bee.gd`'s `role_restricted_to` is a bolt-on allow-list that filters
only the *secondary* role, never an individual action.
`scripts/availability.gd::mode_query` gates sub-*modes* from `roles.gd`, not
actions. `scripts/orders_zones.gd::_apply_mode` carries a second role-to-field
`match`, so a new mode needs a code edit there as well as a data row in
`roles.gd`. `scripts/bee.gd` contains 46 `Role.`/`Roles.` references and
`scripts/hud.gd` 29.

**Pattern.** A data-driven action catalogue (a new `actions.gd`) modelled on
`roles.gd`, plus a generic dispatcher. Each action carries: id, label, the
roles that offer it, a priority band, the name of the function that finds and
starts the work, and its gates — feature id, skill id, stage-gate key, config
flag, season window.

**Benefits.** Adding a job becomes one data row plus one work function.
Challenge-specific capability unlocking becomes data, which is what makes the
Challenge 1 queen robust. The dispatcher becomes testable headlessly against a
constructed catalogue. The HUD stops needing to know role internals.

**Risks.** High. This is the simulation's core loop and any change to priority
ordering is a gameplay change. It must land as a strict, ordering-identical
refactor proved by a headless equivalence run, in slices G1 to G3.

**Files.** `scripts/bee.gd`, a new `actions.gd` in `scripts/`, `scripts/availability.gd`,
`scripts/roles.gd`, `scripts/orders_zones.gd`, `scripts/hud.gd`,
`scripts/challenge_runner.gd`.

## F2 — The resource catalogue covers two of seven cell-content kinds

**Problem.** `resources.gd` is the stated authority for a harvested resource
but holds only nectar and pollen, and says so in its own header. Honey, jelly,
brood, corpse and the empty kind live as bare strings in every file that
touches a cell.

**Evidence.** `scripts/hive_cell.gd`'s `capacity_for`, `accepts`, `space_for`,
`needs_eviction`, `add_resource` and `fill_fraction` each branch on hardcoded
`"honey"`, `"jelly"`, `"brood"` and `"corpse"`. `scripts/hive.gd::_content_index`
hardcodes all nine bucket names in a literal. Twenty-six script files contain
a `"nectar"` literal, 19 occurrences in `challenge_runner.gd` alone.
`scripts/flower.gd`'s `get_available`, `get_capacity` and `get_recharge_rate`
are two-branch ifs. `scripts/skills.gd` already names `bee_bread`,
`royal_jelly` and `pollinator_points` as cost currencies no resource catalogue
knows about.

**Pattern.** Extend `resources.gd` into a full cell-content catalogue: one row
per kind carrying its capacity config key, whether it is storable, whether it
is energy and at what factor, its index bucket name, its colour, whether it
may be designated, and whether it is evictable.

**Benefits.** Bee bread becomes a data row rather than a sweep of six files.
The index buckets derive from the catalogue. `take_energy`'s honey-first rule
becomes an ordered priority field rather than hand-written order.

**Risks.** Medium. `content_type` is already a plain string in the save, so
there is no schema change, but `capacity_for` must return identical values for
every existing kind.

**Files.** `scripts/resources.gd`, `scripts/hive_cell.gd`, `scripts/hive.gd`,
`scripts/flower.gd`, `tests/source_checks.py`.

## F3 — Three condition vocabularies ask the same questions

**Problem.** Challenge goals, scenario `when` clauses and the problem strip
each have their own way of asking how much nectar there is, how many of a role
exist, and whether the queen is alive. Adding a Challenge stage therefore needs
a code edit in `challenge_runner.gd`, and a scenario cannot use a Challenge's
vocabulary.

**Evidence.** `scripts/challenge_runner.gd` holds 30 `_goal_check_*`
predicates, several of which are literally a role count
(`_goal_check_nurse_raised`, `_goal_check_pollen_foragers_raised`,
`_goal_check_nectar_forager_hatched`) or a hive total
(`_goal_check_interim_reserve`, `_goal_check_c2_complete`). Each goal name is
written three times: in `challenge_stages.gd`'s `goal` field, in
`GOAL_CADENCE`, and in `_build_goal_registry`.
`scripts/scenario_actions.gd::_when_met` is a separate if-chain over
`day_at_least`, `population_at_least`, `food_stores_at_least`,
`event_count_at_least`, `queen_alive` and `disease_at_least`.
`scripts/levels.gd` already ships an empty `win_conditions` array on every
level, waiting for exactly this.

**Pattern.** One `conditions.gd` evaluator over the facts
`colony_diagnostics.gd` already computes, plus hive totals and role counts,
reading a declarative spec such as
`{"role_count": {"role": "nurse", "at_least": 1}}`. Challenge stages, scenario
`when` clauses and level win conditions all use it. A `custom` key bound to a
named method stays as the escape hatch for goals that genuinely are not
countable — the ordered inspection visits, the hatchling greeting beat.

**Benefits.** A new Challenge stage becomes a data row. Scenario fixtures and
Challenge goals gain each other's vocabulary at no cost. `win_conditions`
becomes usable without a second mechanism.

**Risks.** Medium. Roughly a third of the current goals are not expressible as
counts and must keep a `custom` binding. Forcing them into data would be the
mistake this plan is trying to avoid.

**Files.** New `conditions.gd`, `scripts/challenge_runner.gd`,
`scripts/challenge_stages.gd`, `scripts/scenario_actions.gd`,
`scripts/colony_diagnostics.gd`.

## F4 — `GOAL_CADENCE` is declared and never read

**Problem.** Every Challenge goal predicate runs on every frame of a Challenge
run, including the ones that scan the whole comb.

**Evidence.** `scripts/challenge_runner.gd:907` declares `GOAL_CADENCE`,
tagging each goal `frame`, `event` or `poll`. A search for `GOAL_CADENCE`
returns four hits, all of them the declaration and its comments; `_process`
calls `_goal_met` unconditionally. The `poll`-class checks scan
`main.hive.cells` (`_goal_check_nectar_target`, `_goal_check_cell_designated`,
`_goal_check_persistent_designation_used`) or call `main.hive.total()`, which
is itself a full comb scan. Challenge 2 additionally runs
`min(_c2_nectar_low_seen, main.hive.total("nectar"))` every frame.

**Pattern.** Wire the cadence that is already authored: `poll` on a 4 Hz timer,
`event` against the epochs that already exist (`hive.index_epoch`,
`main._population_epoch`), `frame` unchanged.

**Benefits.** Removes several full-comb scans per frame during a Challenge for
no gameplay change, at a worst-case goal-completion latency of 250 ms.

**Risks.** Low. No stage may depend on sub-frame detection; the ordered-visit
and greeting goals stay on `frame`.

**Files.** `scripts/challenge_runner.gd`.

## F5 — The `hive.total()` family are full scans on hot readout paths

**Problem.** `total`, `total_sealed` and `total_honey` each walk every cell,
and are called several times a frame from the Challenge runner, the problem
strip, the winter forecast and the corner readouts.

**Evidence.** `scripts/hive.gd:247`, `:257` and `:265` each open with
`for cell in cells`. There are 28 call sites across the codebase;
`challenge_runner.gd` alone calls `total()` seven times inside one frame's goal
evaluation. The comb index (`_content_index`) already exists with epoch
invalidation, and the totals ignore it.

**Pattern.** Epoch-cached totals, computed in the same pass that builds the
content buckets.

**Important detail.** `index_epoch` is **not** sufficient on its own.
`hive_cell.gd`'s `add_resource` and `take_resource` call `_invalidate_hive_index`
only when `content_type` or ripeness changes, so an amount-only change does not
bump it. The totals need their own `stock_epoch`, bumped on every amount
change. A cache keyed on `index_epoch` would read stale.

**Risks.** Low, given the epoch above is added rather than reused.

**Files.** `scripts/hive.gd`, `scripts/hive_cell.gd`.

## F6 — `_hatch_ready_brood` walks every cell every frame

**Evidence.** `scripts/main.gd:775` opens
`for cell in hive.cells: if not cell.brood_ready(): continue`, called from
`_process` unconditionally. `hive.cells_holding("brood")` already exists and is
used by `colony_diagnostics.gd` and `hive.brood_stage_counts()`.

**Pattern.** Iterate the brood bucket instead, over a duplicated array since
`clear_cell()` invalidates the index mid-loop.

**Risks.** Very low. This is the cheapest finding in the review.

**Files.** `scripts/main.gd`.

## F7 — Role counting is written four times

**Problem.** `roles.gd::count_key` is documented as the one place a tally key
is formed, precisely so a new role cannot be silently missed by a readout. Four
other places form it, or its equivalent, by hand.

**Evidence.** `scripts/main.gd::_role_counts` rebuilds `"%d|%s"` inline.
`scripts/main.gd::_update_population_readout` counts four named roles into
named ints. `scripts/main.gd::_record_emergence` builds the key by hand a third
time. `scripts/colony_diagnostics.gd::compute` counts three roles with its own
`match`. `scripts/scenario_actions.gd::_population` walks the bee group again.
The bug `roles.gd` was created to prevent is live in four places.

**Pattern.** `_role_counts()` becomes the one counter, built with
`Roles.count_key`; the population readout and the diagnostics facts read from
it rather than walking the group again.

**Risks.** Low. `_update_population_readout` deliberately accepts an explicit
list on the restore path, because a mid-frame group query there still catches
retired bees. That parameter must survive.

**Files.** `scripts/main.gd`, `scripts/colony_diagnostics.gd`,
`scripts/roles.gd`, `scripts/scenario_actions.gd`.

## F8 — Nine parallel placement flags with no mutual exclusion

**Problem.** Every placement tool is its own boolean on `main.gd`, its own
request function, its own placement function and its own arm of one if-chain.
Nothing clears the others when a tool is picked.

**Evidence.** `scripts/main.gd:311-325` declares `awaiting_build_cell`,
`awaiting_queen_build_cell`, `awaiting_home_cell`, `awaiting_home_cell_all`,
`awaiting_mine_home`, `awaiting_mine_target`, `awaiting_keep_clear`,
`awaiting_forage_start` and `awaiting_floral_preference` alongside four
`pending_*_bees` arrays. `scripts/input_selection.gd::_finish_drag` resolves
them by if-chain order. No request function clears any other flag, so picking
Build cell and then Mine target leaves both set and the build handler wins.
That is a live latent defect, not only a tidiness point.

**Pattern.** One `active_placement_tool: String` on `main.gd` plus a small tool
catalogue: id, which bees it captures, whether it forces the hive view, whether
ctrl-click queues rather than replaces, and the handler name.

**Risks.** Low to medium. Nine call sites across `hud.gd` and
`input_selection.gd` move together.

**Files.** `scripts/main.gd`, `scripts/input_selection.gd`, `scripts/hud.gd`.

## F9 — Five windows duplicate construction and lifecycle

**Problem.** Each window rebuilds the same scaffolding and lifecycle, and three
other files then name them again.

**Evidence.** `colony_panel.gd`, `nursery_panel.gd`, `foraging_panel.gd`,
`winter_panel.gd` and `gallerin_panel.gd` each set `process_mode`, set `layer`,
call `add_to_group`, build a `PanelContainer`, assign `UiTheme.build_theme()`
and override the panel stylebox. Four of them define an identical
`open`/`close`/`toggle`/`is_open` over `panel.visible`.
`scripts/year_winter.gd::_refresh_panels` hand-dispatches each refresh, and
`_close_other_left_windows` iterates a literal array of three.
`scripts/scenario_actions.gd::_resolve_named_panel` matches names to nodes, and
`_do_open_window` has a second such match.

**Pattern.** A `GamePanel` base class extending `CanvasLayer` that owns
construction, visibility, the rectangle taken from `ui_layout.gd` and group
registration, plus a registry keyed by the name the scenario verbs already use.

**Benefits.** Adding a window stops touching `year_winter.gd`,
`scenario_actions.gd` and `hud.gd`. The `plans/README.md` guardrail that every
persistent panel takes its rectangle from `ui_layout.gd` becomes structural
rather than a rule; HC-14 was that rule being broken by one panel that set its
own left edge.

**Risks.** Medium, and it is UI, so it needs the layout assertions
`scenario_actions.gd` already provides plus one hands-on check.

**Files.** New `game_panel.gd`, the five panel scripts,
`scripts/year_winter.gd`, `scripts/scenario_actions.gd`.

## F10 — Stage-gated UI is nine bespoke setters

**Evidence.** `scripts/hud.gd` exposes `set_colony_button_visible`,
`set_nursery_button_visible`, `set_view_button_visible`,
`set_foraging_button_visible`, `set_winter_button_visible`,
`set_hatch_lock_visible`, `set_soil_marking_visible` and
`set_queen_build_button_visible`, plus three allow-list setters.
`scripts/challenge_runner.gd::_apply_stage_gate_to_ui` calls each by name and
carries an inline `designation_gates` dictionary. A newly gated control needs a
setter, a field, a call and a rebuild hook.

**Pattern.** A declarative gate table mapping a stage-gate key to the controls
it governs. The HUD registers each gateable control as it builds it, and one
`apply_gates()` walks the table. The Challenge runner stops knowing HUD widget
names.

**Risks.** Medium. Controls are built after `_ready` ordering, so registration
must be lazy and a missing control must be a no-op, not an error.

**Files.** `scripts/hud.gd`, `scripts/challenge_runner.gd`,
`scripts/availability.gd`.

## F11 — Settings persistence has three lists and measurable drift

**Problem.** What a setting *is* lives in `settings_catalogue.gd`, what
`GameConfig` holds lives in `game_config.gd`, and what a save carries lives in
a fourth hand-written list. Nothing reconciles them.

**Evidence**, measured during this review: `TUNABLES` holds 172 keys,
`SAVED_SETTINGS` 136, and `GameConfig` 199 fields. Twenty-five keys are saved
with no catalogue row, among them `cell_full_threshold`, `forage_search_radius`,
`starting_miners` and `known_patches_max`. Sixty-one catalogued keys are not
saved, and they are not all interface preferences — `disease_on`, `seasons_on`,
`rival_hive_on`, `fog_of_war_on`, `season_length_days` and the three
`lay_weight_*` fields are balance. Twenty-two `GameConfig` fields appear in
neither list. `scripts/levels.gd::apply_config_overrides` already bypasses
`SAVED_SETTINGS` deliberately, with its reasoning recorded, because the list was
blocking legitimate balance testing.

**Pattern.** One `persist` field per `TUNABLES` row — `run`, `player` or
`none` — with `SAVED_SETTINGS` derived from it, and a source check that every
`GameConfig` field has a row.

**Risks.** Medium. Changing which keys persist changes what a saved run
restores, which is why the classification was Dave's to make; he made it on
11 Sep 2026 and it is three buckets, not sixty-one judgements. Run balance
saves with the run. Interface preference stays with the player, in `Session`,
and out of the save. Developer-only keys save nowhere. The eight fields this
finding names as looking like balance — `disease_on`, `seasons_on`,
`rival_hive_on`, `fog_of_war_on`, `season_length_days` and the three
`lay_weight_*` — are run balance under that rule and move into the save.

**Files.** `scripts/settings_catalogue.gd`, `scripts/save_game.gd`,
`tests/source_checks.py`.

## F12 — Problem signals are an if-chain with magic thresholds

**Evidence.** `scripts/year_winter.gd::_refresh_signals` decides every line of
the problem strip in one if-chain carrying literals: nectar below `40.0`, honey
below `10.0`, pollen below `egg_pollen_cost * 0.5`, severities as bare `0`,
`1` and `2`, and the drawer category as an optional fourth array element.
`scripts/problem_messages.gd` holds three of the message builders; the rest are
inline format strings.

**Pattern.** A signal catalogue: id, condition expressed in F3's vocabulary,
severity, category, click action, message builder. The thresholds move to
`GameConfig` so they are tunable and, once F11 lands, saved.

**Risks.** Low, and the acceptance is visible: the same lines appear in the
same order in the same conditions.

**Files.** `scripts/year_winter.gd`, `scripts/problem_messages.gd`,
`scripts/game_config.gd`, `scripts/settings_catalogue.gd`.

## Second pass — 11 Sep 2026

The 10 Sep review above read `scripts/` for catalogues, shared interfaces and
update policy. This pass re-read the same tree for the areas it did not cover:
navigation cost for a coding agent, the instrument each of its own slices
assumes, dead code, scene-tree access, per-entity update gating, save design and
signal amplification. Every finding above was re-checked against the live file
and all twelve still hold. F15 and F17 correct two slices above rather than
adding work; F13, F14 and F16 are new and each has a slice at the end of this
file.

## F13 — Six scripts past the map's own threshold are not in the map

**Problem.** `FUNCTION_MAP.md` is the routing instrument CLAUDE.md rule 1 leans
on, and its coverage list is frozen at the seven files that were largest when it
was written.

**Evidence.** `tools/update_function_map.py`'s `FILES` is a hardcoded list of
seven. The file's own header says it indexes "every function and section header
in the seven scripts still over ~700 lines". Thirteen scripts are now over 700
lines. The six that are not indexed are `bee_foraging.gd` (1,329),
`diagnostic_log.gd` (1,132), `challenge_runner.gd` (1,124), `game_config.gd`
(865), `scenario_actions.gd` (824) and `input_selection.gd` (701). Two of them,
`bee_foraging.gd` and `challenge_runner.gd`, are named in the `Files:` lines of
the queue's current items, so the gap is being paid today. `--check` compares
only the seven it already lists, so `tools/verify.ps1` cannot see the omission.

**Pattern.** Derive `FILES` from a line-count threshold over `scripts/*.gd`
rather than naming them, and have `--check` fail when a file crosses it without
being indexed.

**Why it matters.** Coding-agent efficiency, directly. An unindexed 1,300-line
file is read by grep-and-hope or read whole; the second is the ~500K-token
outcome rule 1 exists to prevent.

**Risks.** Very low. The generator writes a Markdown file; nothing reads it at
runtime.

**Files.** `tools/update_function_map.py`, `FUNCTION_MAP.md`.

## F14 — `hud.gd`'s first section header is at line 1294

**Problem.** CLAUDE.md routes any script outside the map to its
`# --- section ---` headers. The project's largest file has three, and the first
one is 41% of the way down it.

**Evidence.** `grep -n "^# --- " scripts/hud.gd` returns line 1294 (cell popup),
2061 (discard warning) and 2109 (readouts). Lines 1 to 1293 — the whole of the
command tray, the role controls, the bottom row, the goal readout and the
problem strip — carry no header. `main.gd`'s first header is at line 583. By
contrast `bee.gd`, at 2,466 lines, has seventeen.

**Pattern.** Add the missing headers. Nothing else: no split, no move. `bee.gd`
is the worked example of what a file this size should look like, and it was
reached by commenting rather than by reorganising.

**Why it matters.** Coding-agent efficiency and nothing else. It is the cheapest
item in either pass of this review and it improves every later HUD slice,
including F1s, F2s and E1 below.

**Risks.** None. Comments only, no statement changes.

**Files.** `scripts/hud.gd`, `scripts/main.gd`.

## F15 — A fifth hand-built role key, in `hive.gd`, with `FORAGER` as a literal

**Corrects A2 above, does not add a slice.** F7 names four places that build a
tally key by hand. There is a fifth.

**Evidence.** `scripts/hive.gd:467-473` builds `key` as `"gyne"`, then
`"0|%s" % cell.hatch_focus` when `cell.hatch_role == 0`, then `"%d|" %
cell.hatch_role`. Its own comment says it is "keyed the same way the live
population counts are ... the focus only forms part of the key for foragers",
which is `Roles.count_key`'s contract restated, with `Roles.FORAGER` written as
a bare `0`. `bee_enums.gd` declares `enum Role { FORAGER, ... }`, so the literal
is correct today and silently wrong the moment a role is ever inserted before
it — the one thing `roles.gd::count_key` was created to make impossible.

**Consequence for A2 as written.** A2's automated acceptance is a source check
that no file outside `roles.gd` holds the literal `"%d|%s"` or `"%d|"`. That
check fails on `hive.gd` today, and A2's **Files to change** does not list
`hive.gd`. A2 as specified cannot pass its own acceptance. Both are corrected in
A2 below.

**Files.** Folded into A2: `scripts/hive.gd` joins its change list.

## F16 — Twenty behaviour-preserving slices, and no instrument to prove it

**Problem.** Nearly every slice in this plan is behaviour-preserving, and each
one states its own hand-rolled proof: run a named scenario before the change,
run it after, compare some named field by eye. That ritual is written out
twenty times and implemented zero times.

**Evidence.** A1's acceptance is "Run `test_scenarios/colony_30_bees_test.json`
before and after; the emergence counts in the run summary must be identical."
A2's is the same scenario "and compare the population lines." A3, B3, C2, E1 and
G2 each name their own field of their own scenario. The headless tooling is
otherwise strong — 64 scenarios, seeded runs, `DiagnosticLog` summaries, bounded
`Perf` capture, layout assertions — but `--experiment` compares
*configuration cases inside one build*, by design: a case "cannot override
cells, population, actions, stop conditions, diagnostics, or any other
starting-state field." Nothing compares one unchanged scenario across two code
revisions, which is what every slice here actually needs.

**Pattern.** One command that takes a scenario and a git ref, runs the scenario
on both the ref and the working tree, and prints the fields that differ. The
runner already writes a `result.json` per run and already resolves a seed, so
this is a wrapper over two existing runs and a dictionary diff, not new
measurement machinery.

**Why it matters.** Testability, and it is a precondition for the rest of this
plan rather than an improvement to it. CLAUDE.md's working-style rule — "the
second time a check fails for the same reason, build the instrument" — applies
before the first failure here, because the plan already schedules the same
manual check twenty times.

**Risks.** Low. A new tool, no production code. The real risk is the opposite
one: without it, a behaviour-preserving slice is merged on a comparison nobody
can re-run.

**Files.** A new `equivalence.py` in `tools/` (or a `--baseline` flag on
`tools/run_scenario.py`), `docs/headless-run-contract.md`.

## F17 — E1 removes nine flags and leaves nine signals

**Corrects E1 above, does not add a slice.** F8's nine `awaiting_*` fields have
nine matching signals on the other side of the boundary, and E1 does not say
what happens to them.

**Evidence.** `scripts/hud.gd` declares 36 signals. Nine are one per placement
tool: `build_cell_requested`, `queen_build_cell_requested`,
`home_cell_requested`, `home_cell_all_requested`, `mine_home_requested`,
`mine_target_requested`, `keep_clear_requested`, `forage_start_point_requested`
and `floral_preference_requested`. Each is connected in `main.gd` to its own
`_on_*_requested`, which sets its own `awaiting_*` flag. E1 says its change to
`hud.gd` is "call sites only", which leaves the nine signals and their nine
handlers standing beside the new catalogue.

**Consequence for E1 as written.** The worst available outcome for a
consolidation slice is both mechanisms at once: a `PLACEMENT_TOOLS` catalogue
that a new tool must be added to *and* a bespoke signal and handler it must
still be given. E1 below now states the signal collapse as a requirement.

**Files.** Folded into E1: one `placement_tool_requested(tool_id: String)`
replaces the nine.

## F18 — Nine slices assert a headless Challenge that cannot be started

**Found by the 11 Sep 2026 plan review, which read the plans' acceptance
sections rather than the code.** Every finding above asked whether the code
could be improved. This one asks whether a slice's stated acceptance can be
run at all, and for nine slices across three plans the answer is no.

**Evidence.** `main.gd:576` starts the Challenge runner only when
`Session.starting_level` is 1 or 2. A `--scenario` launch points
`starting_level` at `Levels.SCENARIO_LEVEL_ID` (`levels.gd:117`), so no
headless run has ever started a Challenge. `scenario_actions.gd` has no
Challenge or stage verb among its verbs, `test_scenarios/` holds no Challenge
fixture, and the "existing stage-sequence test" named as a regression check by
three separate slices does not exist -- `tests/` reaches Challenge code only
through static regex in `source_checks.py`.

**Affected.** `plans/now/challenge-1.md` Slices 21, 22, 24 and 26;
`plans/now/ui.md` UI-U-1; and A4, C2, F2s and G3 below. Slices 24 and 26 are
the acute pair: their acceptance is *only* headless assertions, so today they
have no acceptance at all.

**Pattern.** H4 below. It is the same answer as F16's -- build the instrument
the plans already assume -- and it comes with the same warning: written into
nine acceptance sections and implemented zero times is how a slice gets merged
on a check nobody ran.

**Risks.** Medium, and they are scheduling rather than technical: H4 owns
`scripts/challenge_runner.gd`, the contended file, so it cannot run beside an
open Challenge 1 slice.

**Files.** Folded into H4: `scripts/main.gd`, `scripts/scenario_actions.gd`,
`scripts/challenge_runner.gd`, `docs/headless-run-contract.md`.

## Patterns deliberately not applied

Recorded so a later session does not re-propose them.

- **A spatial index for obstacles.** `scripts/bee_movement.gd::obstacles_towards`
  documents a measured rejection: 14 obstacles asked at 60 Hz per bee, where the
  grid query cost 25 to 121 bucket lookups plus a fresh array allocation per bee
  per frame, and the allocation churn showed as uneven frame times. The linear
  scan is correct here even though the same grid is correct for flowers.
- **Godot signals for cell mutation.** `scripts/hive.gd::invalidate_index`
  explains why epoch polling beats a real signal on a path that fires several
  times a frame with one consumer. Do not convert it.
- **A node-per-component ECS for bees.** The `bee_*.gd` modules are static
  functions over a bee reference, chosen to avoid a circular preload — see
  `scripts/bee_enums.gd`'s header. A node per component would add per-bee node
  overhead to a design whose entire performance story is one node per bee
  thinking at 8 Hz. Keep the module split; give it a catalogue (F1), not nodes.
- **Rewriting the existing catalogues.** `roles.gd`, `features.gd`, `skills.gd`,
  `flower_species.gd`, `adaptations.gd` and `settings_catalogue.gd` are already
  the right shape. Every slice below extends them.
- **Flower recharge and drawing.** `scripts/flower.gd` already has lazy recharge
  and a throttled presentation pass. Leave it.

Added by the 11 Sep second pass, checked and rejected:

- **Gating `Perf` at the call site.** `Perf.begin`/`end` bracket every cell's
  and every flower's `_process`, so the call count scales with entity count.
  Both entry points return on `if not Session.perf_enabled` before touching the
  clock, which is one boolean read. Hoisting the check into the callers would
  spread the instrumentation contract across two files to save nothing
  measurable.
- **Throttling the per-entity `_process` loops.** `hive_cell.gd` and `flower.gd`
  each already do the right thing and say why in comments: simulation
  (`_develop_brood`, ageing) runs unconditionally so an off-screen colony
  behaves identically, presentation is gated on `is_visible_in_tree()` and then
  staggered with a jittered timer so a hive's worth of cells never redraws on
  one frame, and flower recharge is lazy. `hud.gd::_process` is gated on
  `warning_panel.visible`, `cell_group.visible` and `selection_panel.visible`
  plus a cadence. There is nothing left here to switch off.
- **Retaining node references or adding a scene-tree index.** There is not one
  `get_node(` or `find_child(` anywhere in `scripts/`. Relationships are held as
  typed references already. The 26 `get_nodes_in_group` sites were checked in
  the 1 Sep review and remain 1 Hz or event-driven except fog's, which is the
  pinned baseline target.
- **A dead-code sweep.** There is essentially none to sweep: no unreferenced
  script, no `TODO`/`FIXME`/`DEPRECATED` marker in `scripts/`, and nine
  commented-out statements in 31,000 lines. `diagnostic_log.gd`'s
  `legacy_standard` reads as abandoned and is not — it is the default capture
  profile, live on six branches.
- **A spatial index or a cache for the flower search.**
  `bee_foraging.gd::find_flower` already goes to `main.flower_grid` first and
  only falls back to a group scan when the grid misses, behind an
  `allow_full_scan` flag the callers set deliberately. This is the shape the
  rest of the plan is trying to reach, not a problem.
- **Changing what the save carries.** `save_game.gd` records dynamic state and
  replays it onto a freshly built world, so the format is independent of node
  structure; the migration ladder is present and documented; and
  `plans/reference/technical-audit.md` already records field by field which
  forager state is deliberately not saved and why. F11/D1 is the only
  persistence work this plan should touch.

## Slices

Dependency-ordered. Each names its minimum reasoning level per CLAUDE.md rule
4. Every slice is behaviour-preserving unless its Requirements say otherwise.

Lanes: A, B, D and E touch disjoint files and can run in either lane. C depends
on A. F depends on nothing but shares `hud.gd` with any open HUD slice. G is
last and must be sole owner of `bee.gd`. A4, C2, F2s and G3 all want
`scripts/challenge_runner.gd`; `plans/README.md`'s sequencing guardrail 14
holds the one ordered list of everything queued against that file, across all
four plans that want it.

H1 and H3 touched no `scripts/` file at all, so they conflicted with nothing in
either lane and could run beside any queued gameplay slice. H2 is comment-only but
is sole owner of `hud.gd` for the few minutes it takes. **H3 shipped 11 Sep
2026** (`plans/archive/H3_2026-09-11.md`): it built the before/after
comparison that A1 onwards each name as their acceptance and none of them
could previously run. **H1 shipped 11 Sep 2026**
(`plans/archive/H1_2026-09-11.md`): the function map's file list is now
derived from a 700-line threshold instead of a hardcoded seven. H4 is the
same shape as H1 and H3 for Challenge assertions and is the one H slice
that does touch `scripts/`, so it is the only one that has to queue against
the Challenge 1 lane.

### H1 — the function map covers what it says it covers

Shipped 11 Sep 2026. `tools/update_function_map.py` now derives its file
list from a 700-line threshold instead of a hardcoded seven. Full record:
`plans/archive/H1_2026-09-11.md`.

### H2 — `hud.gd` gets the section headers the routing rule assumes

Shipped 11 Sep 2026. Ten headers in `hud.gd`, six in `main.gd`, comment-only.
Two of the plan's eight named boundaries ("role controls", "speed controls")
turned out to be interleaved with other content rather than contiguous --
recorded rather than acted on, per the slice's own Escalation clause. Full
record: `plans/archive/H2_2026-09-11.md`.

### H3 — the behaviour-equivalence run

Shipped 11 Sep 2026. `tools/equivalence.py`. Full record: `plans/archive/H3_2026-09-11.md`.

### H4 — a headless run can start a Challenge and reach a stage

Level: medium. Depends on: C1-21 and C1-22 having landed. **Status: ready
behind those two.** Dave took the ordering decision on 11 Sep 2026 (decision
D below): H4 lands after C1-21 and C1-22 and before C1-24 and C1-26. It owns
`scripts/challenge_runner.gd`, so it runs in the Codex lane, and `C1-23`'s
`Next after:` is what promotes it.

**Why it exists (found by the 11 Sep 2026 plan review, not by either pass
above).** Nine open slices across three plans state a headless Challenge
assertion as their acceptance, and **no headless run can start a Challenge at
all.** `main.gd:576` calls `challenge_runner.start()` only when
`Session.starting_level` is 1 or 2; a `--scenario` run always points
`starting_level` at `Levels.SCENARIO_LEVEL_ID` (`levels.gd:117`), so the
runner never starts. `scenario_actions.gd`'s verb vocabulary has no Challenge
or stage verb of any kind, there is no Challenge fixture under
`test_scenarios/`, and the "existing stage-sequence test" that three slices
name as their regression check does not exist -- the only Challenge coverage
in `tests/` is static regex in `source_checks.py`.

The nine: `plans/now/challenge-1.md` Slices 21, 22, 24 and 26;
`plans/now/ui.md` UI-U-1; and A4, C2, F2s and G3 below. This is F16 one layer
down -- the same ritual written into nine acceptance sections and implemented
zero times -- and `plans/README.md`'s rule that a shared prerequisite is an
earlier slice rather than a later tidy-up applies to it exactly.

- **Required reading.** This heading. `scripts/main.gd`'s `--scenario`
  handling and its `challenge_runner.start()` call.
  `scripts/challenge_runner.gd`'s `_advance`, `_enter_stage` and
  `debug_advance_stage`. `scripts/scenario_actions.gd`'s verb dispatch.
  `docs/headless-run-contract.md`.
- **Files to change.** `scripts/main.gd`, `scripts/scenario_actions.gd`,
  `scripts/challenge_runner.gd`, `docs/headless-run-contract.md`, one new
  fixture under `test_scenarios/`.
- **Files not to change.** `scripts/challenge_stages.gd`. Stage data does not
  move to make a stage reachable, which is the same rule UI-U-1 works under.
- **Requirements.** A scenario may name the Challenge it runs, so
  `challenge_runner.start()` fires for a `--scenario` launch. A scenario verb
  advances to a named stage id by stepping the ordinary `_advance()` path
  until that id is current, so gates, prompts, markers, checkpoints and stage
  effects are all exercised rather than bypassed -- never by assigning
  `_stage_index`. A `when` clause and an assertion can read the current stage
  id. One fixture proves it by reaching 1.14 and asserting the id.
- **Invariants.** The advance path is the existing one;
  `debug_advance_stage()` stays the single forward seam and this slice uses
  it rather than adding a second. Nothing about a Challenge behaves
  differently because a scenario started it -- if it has to, that is a finding
  to report, not to work around. Ordinary `--scenario` runs with no Challenge
  named are unchanged, and every existing fixture keeps its verdict.
- **Implementation guidance.** The seam UI-U-1 needs for its `◀` button is
  the same seam; if that slice lands first, this one extends it rather than
  building a parallel one. A stage whose goal cannot be satisfied by stepping
  alone -- the ordered-visit beats -- may need the verb to satisfy the goal
  as well as advance past it; say which stages those are rather than
  special-casing them silently.
- **Runtime policy.** Developer and test surface only. Nothing new runs in a
  player's session.
- **Automated acceptance.** A fixture that starts Challenge 1, advances to
  1.14, and asserts the current stage id; it fails today because no fixture
  can start a Challenge. Every existing fixture under `test_scenarios/`
  produces the same verdict it does now.
- **Position, decided.** After C1-21 and C1-22, before C1-24 and C1-26
  (Dave, 11 Sep 2026). Those first two are already queued and their fixes are
  behaviour, proved by Dave's C-7 and C-29; the last two have no acceptance at
  all until this lands. `plans/README.md`'s guardrail 14 carries the same
  ordering for `challenge_runner.gd` as a whole. When this slice is promoted
  into `NEXTSTEPS.md` its `Next after:` is **C1-26**, the marker's pulse and
  off-screen arrow, which is the last Challenge 1 slice this unblocks.
- **Escalation.** If starting a Challenge from a scenario turns out to need
  the Challenge itself to behave differently -- a stage that cannot be reached
  without a player action a scenario verb cannot express -- stop and name the
  stage. That is a fact about the stage design, not a thing to special-case in
  the runner.

### A1 — brood hatching reads the brood bucket

Level: low. Depends on: nothing.

- **Required reading.** This heading. `scripts/main.gd::_hatch_ready_brood`.
  `scripts/hive.gd`'s "cell index" section.
- **Files to change.** `scripts/main.gd`.
- **Files not to change.** `scripts/hive.gd`, `scripts/hive_cell.gd`.
- **Requirements.** `_hatch_ready_brood` iterates `hive.cells_holding("brood")`
  instead of `hive.cells`. Every bee that hatched before still hatches, in the
  same order.
- **Invariants.** `cell.clear_cell()` invalidates the content index mid-loop, so
  iterate a duplicate of the returned array, never the live one. The per-hatch
  calls — `_record_emergence`, `world_building._spawn_hatched_bee`,
  `challenge_runner.on_worker_hatched`, `hive.record_birth`,
  `_update_population_readout` — keep their current order.
- **Implementation guidance.** One statement changes: `for cell in hive.cells:`
  becomes `for cell in hive.cells_holding("brood").duplicate():`. The
  `if not cell.brood_ready(): continue` guard stays, because a brood cell is not
  necessarily ready.
- **Runtime policy.** Still called once per frame from `main._process`; the set
  walked drops from every cell to the brood cells only.
- **Automated acceptance.** Run `test_scenarios/colony_30_bees_test.json` before
  and after; the emergence counts in the run summary must be identical. Add a
  `tests/source_checks.py` assertion that `_hatch_ready_brood` contains no
  `for cell in hive.cells`.
- **Escalation.** If the brood bucket turns out not to be invalidated by
  `start_brood`, stop and say so rather than adding a second invalidation
  source.

### A2 — one role tally

Level: medium. Depends on: nothing.

- **Required reading.** This heading. `scripts/roles.gd`'s "counting keys"
  section. `scripts/main.gd`'s `_role_counts`, `_update_population_readout` and
  `_record_emergence`. `scripts/colony_diagnostics.gd`.
- **Files to change.** `scripts/main.gd`, `scripts/colony_diagnostics.gd`,
  `scripts/hive.gd`.
- **Files not to change.** `scripts/roles.gd`, which is already correct, and
  `scripts/hud.gd`.
- **Requirements.** `_role_counts()` builds its keys with `Roles.count_key`.
  `_record_emergence` uses it too. `_update_population_readout` derives its four
  numbers from `_role_counts()` rather than a second group walk.
  `ColonyDiagnostics.compute` takes the counts as a parameter instead of
  counting roles itself.
- **Invariants.** `_update_population_readout(bees)` keeps its explicit-list
  parameter and its behaviour on the restore path, where a mid-frame group query
  still catches retired bees. The energy loop in `compute` stays; only the role
  `match` goes.
- **Implementation guidance.** `compute(main, bees)` becomes
  `compute(main, bees, counts)` and reads
  `counts.get(Roles.count_key(Roles.FORAGER, "nectar"), 0)` plus the pollen key
  for foragers. The one caller is `year_winter.gd::_refresh_signals`, which
  already has `main._role_counts()` a few lines later. `hive.gd:467-473` is the
  fifth site (F15): its `"gyne"` branch stays, and the two below it become
  `Roles.count_key(cell.hatch_role, cell.hatch_focus)` — which is what the
  literal `0` in `elif cell.hatch_role == 0` already means, since `Role.FORAGER`
  is the first enum member.
- **Runtime policy.** Unchanged cadence, 1 Hz for signals; one group walk per
  population epoch instead of three per second.
- **Automated acceptance.** A `tests/source_checks.py` check that no file
  outside `roles.gd` contains the literal `"%d|%s"`, `"%d|"` or `"0|%s"`. That
  check fails on `hive.gd` today, which is why `hive.gd` is on the change list.
  Then run H3's equivalence command over
  `test_scenarios/colony_30_bees_test.json` and compare the population lines.
- **Escalation.** If a readout disagrees after the change, that is a real
  pre-existing divergence between two counters. Report which, do not pick one.

### A3 — epoch-cached hive stock totals

Level: medium. Depends on: nothing.

- **Required reading.** This heading. F5 above. `scripts/hive.gd`'s "cell index"
  section and its `total`, `total_sealed` and `total_honey`.
  `scripts/hive_cell.gd`'s `add_resource`, `take_resource`, `set_closed` and
  `set_fill_then_close`.
- **Files to change.** `scripts/hive.gd`, `scripts/hive_cell.gd`.
- **Files not to change.** every caller of `total()`; the signature does not
  change.
- **Requirements.** `total`, `total_sealed` and `total_honey` return a cached
  value recomputed only when a new `stock_epoch` has moved. Every returned
  number is identical to today's.
- **Invariants.** `stock_epoch` is a **new** counter, not `index_epoch`.
  `add_resource` and `take_resource` bump `index_epoch` only on a content-type
  or ripeness change, so reusing it would serve stale totals after an ordinary
  deposit. Every mutation of `amount`, `is_closed`, `fill_then_close` or
  `ripen_progress` bumps `stock_epoch`. The restore path in `saving.gd` bumps it
  too, as it already does for `index_epoch`.
- **Implementation guidance.** Compute all three sums in one pass over `cells`
  inside a private `_stock()` that caches against `stock_epoch`, and have the
  three public functions read fields off it. Follow `_content_index()`'s shape
  exactly, including its `Perf.begin`/`Perf.end` pair under a new section name.
- **Runtime policy.** One comb pass per stock mutation instead of one per call.
  No timer and no polling: the epoch is the event, per `hive.gd`'s own note.
- **Automated acceptance.** A new `tests/` case that deposits, withdraws, seals
  and unseals a cell and asserts the totals track after each. Run the pinned
  performance baseline `test_scenarios/recommendation_slice0_baseline.json` and
  record the frame time against `docs/PERFORMANCE_BASELINE.md`.
- **Escalation.** If any mutation path cannot be given a `stock_epoch` bump
  without reaching into another script's internals, stop: that is an ownership
  boundary and Dave decides where the counter lives.

### A4 — wire the goal cadence

Level: medium. Depends on: A3 for the full benefit, but lands without it.

- **Required reading.** This heading. F4 above. `scripts/challenge_runner.gd`'s
  `_process`, `GOAL_CADENCE`, `_goal_met` and `_build_goal_registry`.
- **Files to change.** `scripts/challenge_runner.gd`.
- **Files not to change.** `scripts/challenge_stages.gd`, `scripts/hive.gd`.
- **Requirements.** `_process` consults `GOAL_CADENCE` for the current stage's
  goal. `frame` runs every frame as now. `poll` runs at 4 Hz. `event` runs when
  `hive.index_epoch` or `main._population_epoch` has moved since the last check,
  with 4 Hz as a backstop. Challenge 2's `_c2_nectar_low_seen` sampling moves
  onto the same 4 Hz tick.
- **Invariants.** Every goal id in `challenge_stages.gd` has a `GOAL_CADENCE`
  entry; a missing one is an error, not a silent `frame` default. The
  ordered-visit goals and the greeting and hearts beats stay on `frame`.
  `_advance()` still runs in the same frame the goal is first seen met.
- **Implementation guidance.** One `_goal_poll_timer` on the runner, reset to
  0.25 s. Keep `_goal_met` as it is and gate the call site. Do not change any
  predicate body in this slice.
- **Runtime policy.** As stated above: 4 Hz for `poll` and `event`, per frame
  for `frame`. Worst-case goal latency 250 ms, which no stage's text implies is
  too slow.
- **Automated acceptance.** Add a `tests/source_checks.py` check that the goal
  id sets in `challenge_stages.gd`, `GOAL_CADENCE` and `_build_goal_registry`
  are identical — this is the three-lists problem, and the check is cheaper than
  the collapse in C2. Run an existing Challenge scenario fixture and confirm the
  same stage sequence completes.
- **Escalation.** If any stage completes in a different order, stop and report
  which. A stage that needed per-frame detection is a design fact worth
  recording, not a cadence to widen.

### B1 — the cell-content catalogue, data only

Level: low. Depends on: nothing. Nothing reads the new rows in this slice.

- **Required reading.** This heading. F2 above. `scripts/resources.gd` in full.
  `scripts/hive_cell.gd`'s `capacity_for` and `accepts`.
  `scripts/hive.gd::_content_index`.
- **Files to change.** `scripts/resources.gd`, `tests/source_checks.py`.
- **Files not to change.** every consumer; this slice adds data and changes no
  behaviour.
- **Requirements.** `RESOURCES` gains rows for `honey`, `jelly`, `brood`,
  `corpse` and the empty kind. Each row carries `key`, `label`, `colour`,
  `is_energy`, `energy_factor`, `capacity_config` (the `GameConfig` field name,
  empty meaning `cell_capacity`), `index_bucket`, `storable`, `designatable`,
  `evictable`, `config_flag` and `save_policy`. The existing nectar and pollen
  rows gain the new fields with values matching today's behaviour.
- **Invariants.** `Resources.keys()` must keep returning **only the
  forager-selectable resources**. `roles.gd::count_keys` iterates it to build
  forager tally keys, and adding honey there would invent tally keys no bee can
  have. Add a separate `Resources.content_keys()` for the full list and leave
  `keys()` alone. This is the single most likely way to break this slice.
- **Implementation guidance.** Copy the existing rows' comment style. Take
  `capacity_config` values from `hive_cell.gd::capacity_for`'s current `match`:
  honey to `honey_cell_capacity`, jelly to `jelly_cell_capacity`, everything
  else empty. Take `energy_factor` from `hive.gd::take_energy` — honey
  `honey_energy_factor`, nectar 1.0, everything else 0.
- **Runtime policy.** Static const data; no runtime cost.
- **Automated acceptance.** A `tests/source_checks.py` check that the
  `index_bucket` values in `resources.gd` are exactly the bucket names
  `hive.gd::_content_index` builds, and that `Resources.keys()` still returns
  two entries.
- **Escalation.** None expected. If a kind resists a field, leave the field
  empty and say so in a comment rather than inventing a value.

### B2 — the comb index derives from the catalogue

Level: medium. Depends on: B1.

- **Required reading.** This heading. B1's result. `scripts/hive.gd`'s "cell
  index" section.
- **Files to change.** `scripts/hive.gd`.
- **Files not to change.** `scripts/resources.gd`, `scripts/hive_cell.gd`.
- **Requirements.** `_content_index` builds its bucket dictionary from
  `Resources.content_keys()` plus the two derived buckets, `unbuilt` and
  `ripe_honey`, rather than from a literal.
- **Invariants.** The bucket names, their contents and the `ripe_honey`
  double-membership rule are unchanged. `cells_holding()` still returns an empty
  array for an unknown key rather than erroring.
- **Implementation guidance.** Build the dictionary in a loop, then add
  `"unbuilt"` and `"ripe_honey"` explicitly with a comment saying they are
  derived, not content kinds.
- **Runtime policy.** Unchanged: the index still rebuilds only on `index_epoch`.
- **Automated acceptance.** The B1 source check now proves the two lists match
  from the other direction. Run `test_scenarios/colony_30_bees_test.json` and
  compare the summary.
- **Escalation.** None.

### B3 — cell capacity and acceptance read the catalogue

Level: medium. Depends on: B1, B2.

- **Required reading.** This heading. `scripts/hive_cell.gd`'s "contents"
  section in full. `scripts/hive.gd::take_energy`.
- **Files to change.** `scripts/hive_cell.gd`, `scripts/hive.gd`,
  `scripts/resources.gd`.
- **Files not to change.** `scripts/save_game.gd` and `scripts/saving.gd`; no
  save field changes.
- **Requirements.** `capacity_for` reads `capacity_config` from the catalogue.
  `space_for` and `needs_eviction` test `storable` and `evictable` rather than
  naming `brood` and `corpse`. `take_energy` draws in the catalogue's energy
  priority order instead of its hand-written honey-then-nectar sequence.
- **Invariants.** Every existing call returns the same value for every existing
  kind. The ordering of refusals in `accepts` — corpse, closed, keep_empty,
  designation mismatch — is unchanged; it is load-bearing and the comments say
  why. Honey's rewetting rule in `add_resource` stays as special-cased code; it
  is one kind's physics, not catalogue data.
- **Implementation guidance.** Change one function at a time and run the balance
  suite between each. Do not attempt `fill_fraction`'s brood branch in this
  slice.
- **Runtime policy.** `Resources.entry()` is a linear scan over a seven-row
  array called from `capacity_for`, which is hot. Add a static `_by_key`
  dictionary built once in `resources.gd` and have `entry()` read it.
- **Automated acceptance.** `tests/balance_tests.py` must pass unchanged. Add a
  case asserting `capacity_for` for all seven kinds against the current
  `GameConfig` defaults.
- **Escalation.** If `take_energy`'s order turns out to be observable in balance
  output, stop: changing what bees eat first is a gameplay change and Dave
  decides.

### C1 — the conditions evaluator, no callers

Level: medium. Depends on: A2, A3.

- **Required reading.** This heading. F3 above. `scripts/colony_diagnostics.gd`.
  `scripts/scenario_actions.gd::_when_met`. `scripts/challenge_runner.gd`'s
  `_goal_check_*` block.
- **Files to change.** a new `conditions.gd` in `scripts/`, `tests/source_checks.py`, a
  new `tests/` case file.
- **Files not to change.** every existing caller. Nothing reads this file yet,
  the same way `features.gd` and `progression.gd` shipped.
- **Requirements.** A static `met(main, spec) -> bool` and a
  `progress(main, spec) -> Dictionary` returning `{current, target}` or empty.
  Supported keys, chosen because they cover both existing vocabularies:
  `day_at_least`, `role_count` with `role`/`focus`/`at_least`, `hive_total` with
  `resource`/`at_least`, `cell_count` with
  `content`/`designated`/`explicit`/`at_least`, `built_cells_at_least`,
  `brood_cells_at_least`, `queen_alive`, `event_count` with
  `type`/`subtype`/`at_least`/`at_most`, `disease` with `at_least`/`at_most`,
  `all_of`, `any_of`, and `custom` naming a method on the caller.
- **Invariants.** The evaluator reads; it never writes game state. It never
  walks the bee group directly — role counts come from `main._role_counts()` and
  stock from `hive.total()`, both epoch-cached after A2 and A3. An unknown key
  is a `push_error` and `false`, never a silent pass.
- **Implementation guidance.** Model the file on `availability.gd`: a leaf
  RefCounted, static functions, no tree access beyond the `main` passed in.
  Write the tests against constructed dictionaries, as `progression.gd`'s tests
  do, not against a running game.
- **Runtime policy.** A pure function of already-cached facts. No timers and no
  scans of its own.
- **Automated acceptance.** A `tests/` case per supported key. A
  `tests/source_checks.py` check that `conditions.gd` contains no assignment to
  anything reached through `main`.
- **Escalation.** If a key cannot be expressed without walking a set that has no
  cache, do not add the walk. Report it and let A3's pattern be extended first.

### C2 — Challenge goals become data

Level: high. Depends on: C1, A4.

- **Required reading.** This heading. C1's result.
  `scripts/challenge_stages.gd`'s `STAGES_1` and `STAGES_2`.
  `scripts/challenge_runner.gd`'s goal registry, `_goal_met` and
  `_goal_progress`.
- **Files to change.** `scripts/challenge_stages.gd`,
  `scripts/challenge_runner.gd`.
- **Files not to change.** `conditions.gd`.
- **Requirements.** Each stage row gains a `condition` dictionary. The goals
  that are counts or totals lose their `_goal_check_*` method. The goals that
  are not — the ordered visits, the greeting, the stability window, the entrance
  tunnel, selection state — keep theirs behind
  `{"custom": "_goal_check_x"}`. `_build_goal_registry`'s hand-written
  dictionary is deleted, and `custom` resolves by name.
- **Invariants.** Every stage completes on exactly the same condition it does
  today. `GOAL_CADENCE` keeps one entry per goal and A4's three-list source
  check keeps passing. `_goal_progress`'s three numeric bars come from
  `Conditions.progress` and show the same numbers.
- **Implementation guidance.** Convert one stage at a time, running the
  Challenge scenario fixture between each. Expect roughly a third to stay
  `custom`; that is the intended outcome, not a failure.
- **Runtime policy.** As A4 set it. `poll` goals now cost one dictionary walk
  over cached facts rather than a comb scan.
- **Automated acceptance.** A headless run of each Challenge fixture reaching
  the same final stage id. A source check that no `_goal_check_*` method exists
  without a `custom` reference naming it.
- **Escalation.** A stage whose condition changes meaning during conversion is a
  gameplay change. Stop, name the stage and both readings, and let Dave choose,
  per CLAUDE.md rule 5.

### C3 — scenario `when` uses the evaluator

Level: low. Depends on: C1.

- **Required reading.** This heading. `scripts/scenario_actions.gd`'s `_when_met`
  and `_population`. `docs/headless-run-contract.md`.
- **Files to change.** `scripts/scenario_actions.gd`.
- **Files not to change.** any file under `test_scenarios/`; every existing
  fixture must keep working untouched.
- **Requirements.** `_when_met` delegates to `Conditions.met`. The six existing
  key names keep working and map onto the evaluator's keys. `_population` is
  deleted in favour of `main._role_counts()`.
- **Invariants.** Fixture compatibility is absolute. `food_stores_at_least`
  keeps meaning ripe honey only, as it does today, however odd that reads.
- **Implementation guidance.** Keep a small translation table from the legacy key
  names to the evaluator's spec so no fixture has to change.
- **Runtime policy.** Called once per scenario tick, as now.
- **Automated acceptance.** Every fixture under `test_scenarios/` produces the
  same verdict, and `tests/test_headless_verdicts.py` passes unchanged.
- **Escalation.** None expected.

### C4 — the signal catalogue

Level: medium. Depends on: C1.

- **Required reading.** This heading. F12 above.
  `scripts/year_winter.gd::_refresh_signals`. `scripts/problem_messages.gd`.
- **Files to change.** `scripts/year_winter.gd`, `scripts/problem_messages.gd`,
  `scripts/game_config.gd`, `scripts/settings_catalogue.gd`.
- **Files not to change.** `scripts/hud.gd::update_signals`; the array shape it
  receives does not change.
- **Requirements.** A `SIGNALS` catalogue with id, condition in C1's vocabulary,
  severity, category, click action and message function name. The inline
  thresholds `40.0` and `10.0` and the `0.5` multiplier become named
  `GameConfig` fields with catalogue rows.
- **Invariants.** The same lines appear, in the same order, at the same
  severities, in the same conditions. The Challenge early-return that clears the
  strip stays exactly where it is. The optional fourth category element keeps
  its current meaning.
- **Implementation guidance.** Order is load-bearing — the strip shows
  severity-2 lines first because they are listed first. Keep the catalogue in the
  current order and iterate it.
- **Runtime policy.** Still the existing 1 Hz signal tick.
- **Automated acceptance.** A `tests/` case driving a constructed colony state
  through the catalogue and asserting the exact line list, for the six states the
  current chain distinguishes.
- **Escalation.** If a threshold's new default would change when a warning first
  fires, keep today's value and say so.

### D1 — one settings persistence authority

Level: medium. Depends on: nothing, beyond Decision A's hold. Both halves are
startable once that lifts: Dave took the classification decision on 11 Sep 2026
(see "Decisions taken 11 Sep 2026" above).

- **Required reading.** This heading. F11 above.
  `scripts/settings_catalogue.gd`'s header and `TUNABLES` shape.
  `scripts/save_game.gd::SAVED_SETTINGS` and its comment.
  `.claude/rules/saving.md`.
- **Files to change.** `scripts/settings_catalogue.gd`, `scripts/save_game.gd`,
  `tests/source_checks.py`.
- **Files not to change.** `scripts/session.gd`; player preferences stay there,
  and this slice must not move any of them into the save.
- **Requirements.** Every `TUNABLES` row gains `persist`: `run` for a key that
  goes in the save, `player` for a Session preference that never does, `none`
  otherwise. `SAVED_SETTINGS` becomes a function deriving the `run` keys. A
  source check fails when a `GameConfig` field has no `TUNABLES` row, and when a
  row's `persist` disagrees with what the save actually carries.
- **Invariants.** The save format version does **not** change in the first half:
  a derived list identical to today's needs no migration. If the decision below
  adds keys, that is a `FORMAT_VERSION` bump and `save_migrations.gd` gains a
  step defaulting the new keys to their `GameConfig` values.
- **Implementation guidance.** Land it in two halves still, because the first
  half proves the derivation before anything about the save changes. First,
  annotate every row so the derived list is byte-identical to today's
  `SAVED_SETTINGS`, add the check, and change nothing about what is saved.
  Second, apply Dave's rule: run balance saves with the run, interface
  preference stays in `Session` and out of the save, developer-only saves
  nowhere. The 25 saved-but-uncatalogued keys need rows adding either way.
  Classify each of the 61 by asking one question -- would two players loading
  this save get different colony outcomes if the key were missing? Yes is `run`.
- **Runtime policy.** Derived once at save time, not per frame.
- **Automated acceptance.** The derived list equals the current literal, proved
  in `tests/source_checks.py`. `tests/test_save_migrations.py` passes.
- **Escalation.** The classification rule is settled, so do not re-ask it. Stop
  only for a key the rule genuinely does not sort -- one that changes colony
  outcomes *and* is plainly an interface preference. Name those keys and say why
  each resists the rule; do not pick a bucket for them. The eight balance fields
  F11 names move into the save, so the second half is a `FORMAT_VERSION` bump
  with a `save_migrations.gd` step, exactly as the Invariants above describe.

### E1 — one placement tool

Level: medium. Depends on: nothing.

- **Required reading.** This heading. F8 above.
  `scripts/input_selection.gd::_finish_drag` and every `_place_*` and
  `_on_*_requested` pair. `scripts/main.gd:311-325`.
- **Files to change.** `scripts/main.gd`, `scripts/input_selection.gd`,
  `scripts/hud.gd` — call sites, plus the nine signal declarations that F17
  replaces with one.
- **Files not to change.** `scripts/orders_zones.gd`, `scripts/bee.gd`.
- **Requirements.** One `active_placement_tool: String` on `main.gd`, `""`
  meaning none, plus a `PLACEMENT_TOOLS` catalogue in `input_selection.gd`
  carrying id, handler method name, whether ctrl-click queues, whether it forces
  the hive view, and which bees it captures. Requesting a tool clears any other.
  The nine per-tool signals on `hud.gd` collapse to one
  `placement_tool_requested(tool_id: String)` and the nine `_on_*_requested`
  handlers in `main.gd` to one, so a new tool is a catalogue row and nothing
  else (F17). Leaving both mechanisms standing is the one outcome this slice
  must not produce.
- **Invariants.** Each tool does exactly what it does today, including which bees
  it captures. `_on_home_cell_requested` takes only the first selected comb
  worker and `_on_home_cell_all_requested` takes every comb worker in the colony;
  that difference is deliberate and commented, and must survive. The nine
  `awaiting_*` fields are removed, not left as aliases.
- **Implementation guidance.** The if-chain in `_finish_drag` becomes one lookup.
  Keep the current chain order as the catalogue's order so any accidental
  reliance on it is preserved. Search for `awaiting_` and change every hit; the
  HUD's cursor hints read some of them.
- **Runtime policy.** Unchanged; these are input-driven, not per-frame.
- **Automated acceptance.** A scenario fixture that activates Build cell, then
  Mine target, then clicks, and asserts a mine target was set and no cell was
  placed. That case fails today, which is the point.
- **Escalation.** If any tool turns out to be legitimately concurrent with
  another, stop; mutual exclusion is then a gameplay decision.

### F1s — a shared window base class

Level: medium. Depends on: nothing. Sole owner of the five panel files.

- **Required reading.** This heading. F9 above. `scripts/colony_panel.gd` and
  `scripts/winter_panel.gd`'s `_ready` and lifecycle functions.
  `scripts/ui_layout.gd`, `scripts/ui_panel_layout.gd`. `plans/README.md`'s
  sequencing guardrail 11.
- **Files to change.** a new `game_panel.gd` in `scripts/`, the five panel scripts,
  `scripts/year_winter.gd`, `scripts/scenario_actions.gd`.
- **Files not to change.** `scripts/ui_theme.gd`, `scripts/ui_layout.gd`; the
  base class calls them, it does not change them.
- **Requirements.** `GamePanel extends CanvasLayer` owns `process_mode`, `layer`,
  group registration, the `PanelContainer` with its theme and stylebox, the
  rectangle from `ui_layout.gd`, and `open`, `close`, `toggle` and `is_open`.
  Each panel keeps only its own content and its own `refresh`. A registry maps
  the names `scenario_actions.gd` already uses to instances, replacing
  `_resolve_named_panel` and `_do_open_window`'s match.
- **Invariants.** Every panel's on-screen rectangle is pixel-identical after the
  change. The Gallerin bubble is not a left-side window and must not be forced
  into the left-window close-others group. `winter_panel.gd` anchors top-right,
  so the base must support both anchorings rather than assuming one.
- **Implementation guidance.** Convert one panel at a time, running the layout
  assertions between each. `foraging_panel.gd` is the simplest and is the right
  one to convert first.
- **Runtime policy.** Unchanged. `year_winter._refresh_panels` still refreshes
  only open panels; that gate moves into the registry walk.
- **Automated acceptance.** `tests/test_layout_regression.py` must pass
  unchanged, and its `panel_rect` assertions are the instrument here. One
  hands-on check in `checks/ready.md` covering opening and closing each window at
  two text scales.
- **Escalation.** If two panels genuinely need different `layer` values, put the
  value in the subclass rather than widening the base.

### F2s — a declarative UI gate table

Level: medium. Depends on: F1s.

- **Required reading.** This heading. F10 above.
  `scripts/challenge_runner.gd::_apply_stage_gate_to_ui`. `scripts/hud.gd`'s
  `set_*_visible` block and `allowed_*_keys` fields. `scripts/stage_gate.gd`.
- **Files to change.** `scripts/hud.gd`, `scripts/challenge_runner.gd`,
  `scripts/availability.gd`.
- **Files not to change.** `scripts/stage_gate.gd`; it stays string-keyed and
  unchanged, including its accessibility refusal.
- **Requirements.** A gate table mapping a stage-gate key to the controls it
  governs. The HUD registers each gateable control as it builds it and exposes
  one `apply_gates(stage_gate)`. The eight bespoke `set_*_visible` functions go.
  The three allow-list setters stay, because they filter a rebuilt list rather
  than toggling one control, which is a different job.
- **Invariants.** No entry of `stage_gate.ACCESSIBILITY_KEYS` may appear in the
  table, and the source check should fail if one does. A control not yet built
  registers later and is a no-op until then, never an error. The
  `designation_gates` map moves into the table, keeping honey and jelly behind
  keys no Challenge 2 stage unlocks.
- **Implementation guidance.** Register with a `Callable` that returns the
  control rather than a stored reference, since `_rebuild_role_controls` replaces
  nodes.
- **Runtime policy.** Called on stage entry and on `unlocked_changed`, not per
  frame.
- **Automated acceptance.** A source check that no accessibility key appears in
  the gate table, and that every gate key used in `challenge_stages.gd`'s
  `unlocked_keys` has either a table row or a documented reason for having none.
  A Challenge fixture reaching a late stage with the same controls visible.
- **Escalation.** If a control's visibility depends on both a gate and something
  else — the queen build button depends on the gate *and* on a single queen being
  selected — keep the second condition in the HUD and gate only the first. Do not
  put selection state in the table.

### G1 — the action catalogue, data only

Level: medium. Depends on: B3, C1. Nothing reads the catalogue in this slice.

- **Required reading.** This heading. F1 above. `scripts/bee.gd::_try_role_work`
  in full. `scripts/roles.gd`. `scripts/availability.gd`.
- **Files to change.** a new `actions.gd` in `scripts/`, `tests/source_checks.py`.
- **Files not to change.** `scripts/bee.gd`, not one line in this slice.
- **Requirements.** One row per unit of work `_try_role_work` can start, in the
  exact order it tries them today. Each row carries `id`, `label`, `roles` (the
  role ids that offer it), `band` (an integer priority within a role, matching
  today's order), `modes` (which sub-modes of the role enable it, empty meaning
  all), `find` (the name of the function that finds and starts the work),
  `feature`, `skill`, `gate_key`, `config_flag` and `season`.
- **Invariants.** The catalogue is a transcription, not a redesign. Its order,
  read per role, must reproduce today's arms exactly — including the nurse's
  jelly-only branch, the comb worker's clean-then-evict-then-restock-then-build
  order, the miner's queued-then-marked-then-automine order, and the honey
  maker's load-then-fan-then-fetch order. Every `gate_key`, `skill` and `feature`
  field ships empty; filling them is G3, and a value here would change behaviour
  the moment G2 lands.
- **Implementation guidance.** Write the catalogue beside the existing function
  and add a source check comparing the two, rather than trusting a read.
- **Runtime policy.** Static const data.
- **Automated acceptance.** A `tests/source_checks.py` check that every `find`
  name resolves to a real function, that every `roles` id is a real role, and
  that the per-role band sequence has no gaps or duplicates.
- **Escalation.** If a branch cannot be described as one row — the queen's
  brood-before-laying exception in `_idle_dispatch` is the known case — record it
  as a named exception in the catalogue's header rather than bending the schema.
  That exception belongs to the dispatcher, not to an action.

### G2 — the dispatcher reads the catalogue

Level: high. Depends on: G1. Must be sole owner of `scripts/bee.gd`.

- **Required reading.** This heading. G1's result. `scripts/bee.gd`'s
  `_try_role_work`, `_idle_dispatch` and `_maybe_break_off_secondary`.
  `.claude/rules/simulation.md`. `.claude/rules/performance.md`.
- **Files to change.** `scripts/bee.gd`, and the `bee_*.gd` module whose function
  a row names, only to give it a uniform signature.
- **Files not to change.** `scripts/hud.gd`, `scripts/challenge_runner.gd`,
  `scripts/orders_zones.gd`; the player-facing surface does not move in this
  slice.
- **Requirements.** `_try_role_work(r)` walks the catalogue rows for role `r` in
  band order, skipping rows whose `modes` exclude this bee's current sub-mode,
  and calls each row's `find` until one returns true. The `match` goes. Behaviour
  is identical.
- **Invariants.** The queen's brood-before-laying exception stays in
  `_idle_dispatch`, where it is today. `role_restricted_to` keeps its current
  meaning until G3. `working_secondary` and the break-off rule are untouched. The
  miner's `_mining_no_work_epoch` memo must survive; it is a documented
  performance contract in `docs/PERFORMANCE_BASELINE.md`, and dropping it makes
  every idle miner walk the soil set every think tick.
- **Implementation guidance.** Land it behind a plain boolean const at the top of
  `bee.gd` so both paths can run in one build, run the equivalence fixture
  against each, then delete the old path in the same commit. Do not leave the
  const behind.
- **Runtime policy.** `_try_role_work` runs on the 8 Hz think tick, unchanged.
  Resolve the catalogue rows for a role once into a static per-role array at
  load, not per call; a linear filter of the whole catalogue on every think tick
  for every bee would be a regression.
- **Automated acceptance.** A headless equivalence run: the pinned baseline
  `test_scenarios/recommendation_slice0_baseline.json` plus
  `colony_30_bees_test.json`, both to a fixed day count, producing identical
  population, stock and emergence summaries before and after. Frame time recorded
  against `docs/PERFORMANCE_BASELINE.md`.
- **Escalation.** Any summary difference at all, however small, stops the slice.
  This is the core loop, and a "close enough" result is a gameplay change nobody
  chose.

### G3 — actions become gateable

Level: medium. Depends on: G2, F2s.

- **Required reading.** This heading. G2's result. `scripts/availability.gd`.
  `scripts/stage_gate.gd`. `scripts/progression.gd::is_permitted`.
  `plans/design/progression.md` sections 3 and 4.5.
- **Files to change.** `scripts/availability.gd`, `actions.gd`,
  `scripts/bee.gd`, `scripts/challenge_stages.gd`.
- **Files not to change.** `scripts/progression.gd`; it answers skill questions
  and this slice asks it, it does not change it.
- **Requirements.** `Availability.action_query(action_id, bee, stage_gate,
  progression)` composes the same four facts `mode_query` already does —
  existence, config flag, stage unlock, suppression — plus feature and skill
  ownership. The dispatcher skips a row whose query is unavailable. Challenge
  stages may name action ids in `unlocked_keys`.
- **Invariants.** Outside a Challenge, with no skills owned, every action must
  remain available exactly as today. That is what keeps ordinary play unchanged,
  and it is the acceptance. `role_restricted_to` is removed only once the stages
  that rely on it name actions instead; do both in this slice or neither.
- **Implementation guidance.** Ship every catalogue gate field empty except the
  ones a Challenge 1 or 2 stage actually needs, and prove each against that
  stage. An empty gate field means "always available", never "check and pass".
- **Runtime policy.** The query result is stable between stage transitions and
  skill purchases. Cache it per bee against a gate epoch; do not call it per
  action per think tick.
- **Automated acceptance.** Both Challenge fixtures reach the same final stage. A
  scenario fixture with no Challenge active confirms every action is offered. A
  source check that every action id named in `challenge_stages.gd` exists in
  `actions.gd`.
- **Escalation.** If gating an action makes a bee with no available work behave
  differently from an idle bee today, that is a gameplay outcome. Stop and
  describe both behaviours.
- **Cross-plan dependency.** `plans/design/progression.md`'s Phase B step 6
  (the foraging tier-1 vertical slice) is the first work in the project to gate
  a capability by skill ownership, which is what this slice builds the
  mechanism for. Whichever lands first sets the pattern the other must fit.
  Neither is scheduled; settle which one owns skill gating before either
  starts, rather than discovering it during implementation.

## Read on demand

<!-- LAYER: on-demand -->

- `FUNCTION_MAP.md` — line numbers for `hud.gd`, `bee.gd`, `hive.gd`,
  `hive_cell.gd`, `main.gd`, `debug_panel.gd` and `settings_catalogue.gd`.
- `docs/PERFORMANCE_BASELINE.md` — the pinned baseline and the invalidation
  contracts A3, A4 and G2 must not break.
- `docs/known-pitfalls.md` — before any HUD slice.
- `.claude/rules/simulation.md` and `.claude/rules/performance.md` — before G2.
- `.claude/rules/saving.md` — before D1.
- `plans/design/progression.md` sections 3 and 4.5 — before G3.
