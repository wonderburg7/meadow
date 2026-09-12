# Next steps

<!-- CONTEXT: current-queue | LOAD: every session -->

**"Implement the next slice" means:** run `tools/slice.ps1 start -Lane Claude`
(or `-Lane Codex`) to claim your lane's leading item and open its worktree,
open only the `Plan:` file and heading that item names, implement, run
`tools/verify.ps1`, and close with the end-of-slice report (`CLAUDE.md`).
Do not read the other lane's plan, the archive, `ROADMAP.md` or Git history
to work out what to do -- the script already decided.

**Current state, after Dave's fourth hands-on pass (9-10 Sep 2026).** Eleven
checks ran, and everything that pass unblocked has now shipped. C1-25, the most
severe finding, landed on 11 Sep 2026: Challenge 1's nectar-discard rule now
names stage 1.14 in its code rather than only in a comment, so the queen keeps
a load the comb cannot take at every earlier stage and is told by Dr Gallerin
on the one stage that does discard it. Its check is C-42.

HC-16 landed on 11 Sep 2026: the command tray's height now matches its
content on a reselection, not just the first build, with or without `More…`
open. The confirmed cause was `_rebuild_role_controls` freeing the previous
selection's rows with a plain `queue_free()`, which left them parented (and
still counted by the tray's nested layout) for one to several frames after
the new rows were already added; `hud.gd::_detach_and_free_children` now
detaches each old row immediately instead. That plan had no further open
slices, so it is archived in full at
`plans/archive/HUD_CONTROLS_2026-09-11.md`; its check is C-43. With no
ready slice left in that plan, C1-21 (bee.gd/bee_foraging.gd, file-disjoint
from the Codex lane's C1-23) moves into the Claude lane below, and C1-22
(startable on its own merits per `plans/now/challenge-1.md`) fills the
third slot.

The pass's other three fixes (HC-13, HC-14 and HC-15) landed on 10 Sep 2026 and
their records are in `plans/archive/`. Fourteen hands-on checks are waiting in
`checks/ready.md`; by rule no queue item is held open for one.

**Dave took three decisions on 11 Sep 2026**, from that day's architecture and
planning audit. They are recorded in full under "Decisions taken 11 Sep 2026" in
`plans/design/architecture-review.md`; what they change here is the queue.
Architecture work is admitted, but behind the open Challenge 1 items rather than
in front of them, so H3 and H1 now fill slots 4 and 5 of the Claude lane and H2
follows them. Every A-to-G slice in that plan stays out of the queue until
Challenge 1's Slices 21 to 26 have vacated `challenge_runner.gd`. That plan is
also now the design pass for four of `plans/design/product-scope.md` section
6.2's shared foundations, and its settings-persistence slice is unblocked by a
three-bucket classification rule.

**A plan review ran on 11 Sep 2026** over every active plan. It changed no
queue item's scope and took nothing out of the queue. What it changed here:
the SB entry below now names the real blocker instead of a Godot crash that
no longer reproduces, and C1-22 names its own successor instead of sharing
C1-23's, which would have let the Codex lane fall below the floor of three.
**Dave answered all four of its questions the same day.** H4, a new slice,
lands after C1-22 and before C1-24, and enters the Codex lane as C1-23's
successor. `check_docs.py`'s two contradictory rules are reconciled and
shipped: a queue item's `Files:` line may now name a file its slice creates,
which is why H3 at 4 below names the tool it builds. Comb workers are capped
at six per site, one to each wall, and a cell holding any amount of a
resource outlines itself in that resource's colour -- both were specified in
the now-complete `plans/archive/HIVE_COMB_2026-09-12.md`.

**C1-23 shipped 11 Sep 2026, but the queue was never refreshed to say so.**
`NECTAR_TARGET := 150.0` landed on master that day in three commits
(`7702760`, `3eae1db`, `29a8c2a`) and its check is C-44
(`checks/ready/C-44.md`), but this file and `plans/now/challenge-1.md` kept
listing C1-23 as the Codex lane's leading item -- which is what correctly
stopped a later `tools/slice.ps1 start -Lane Codex` from claiming it: its
own stale-proof check refused the claim rather than silently redoing
finished work. Fixed here, retroactively: the slice's specification moved
to `plans/archive/C1-23_2026-09-11.md`, C1-22 now leads the Codex lane, and
HCB-5 -- already startable per Dave's 11 Sep 2026 answers and
file-disjoint from both lanes -- fills the slot C1-23 leaves. Its true
successor, H4, still cannot enter until C1-22 also lands (it depends on
both C1-21, already shipped, and C1-22), so it stays in "Not in the queue"
below rather than being pulled in early.

**C1-21 shipped 11 Sep 2026.** The prescribed headless Challenge trace could
not be run -- H4 was still open, so `--scenario` cannot start a Challenge at
all -- and a full static trace of the live code stood in for it instead. The
real fault: C1-25's stage-1.14 discard rule only ever ran from a bee actively
retrying a deposit, never from one parked on `IDLING` by Stage 1.11's freeze,
so a nectar load frozen mid-trip rode untouched all the way to 1.14. Fixed
with a new stage effect that clears it on 1.13's exit, plus a general
`bee.gd::set_focus()` fix so any bee genuinely stuck (not just an `IDLING`
one) wakes up on a focus change. Full record:
`plans/archive/C1-21_2026-09-11.md`.

**H3 shipped 11 Sep 2026.** `tools/equivalence.py` runs a scenario at a
chosen git ref (from a throwaway detached worktree, never checked out over
the working tree) and again in the working tree at the same seed, and
prints only the `result.json` fields that differ -- the missing instrument
F16 named, now available to every behaviour-preserving slice in
`plans/design/architecture-review.md`. `docs/headless-run-contract.md`
documents it under "Behaviour-equivalence runs". Its `Next after` (H1) was
already queued below, so the Claude lane simply drops to one item, which
brings the combined queue to three -- `tools/check_docs.py`'s floor -- so no
new slice needed pulling in to replace it.

**H1 shipped 11 Sep 2026.** `tools/update_function_map.py`'s `FILES` list is
now derived from a named `LINE_THRESHOLD = 700` constant by walking
`scripts/*.gd`, instead of being a hardcoded seven; the six scripts F13
found missing (`bee_foraging.gd`, `challenge_runner.gd`, `diagnostic_log.gd`,
`scenario_actions.gd`, `game_config.gd`, `input_selection.gd`) now join the
original seven in `FUNCTION_MAP.md`, each with a one-line description, and
`--check` fails by name when a file crosses the threshold without one. Full
record: `plans/archive/H1_2026-09-11.md`. Its `Next after` (H2) fills the
Claude lane's slot below.

**C1-22 shipped 11 Sep 2026.** `camera_follow_off` now routes through
`camera_view._on_follow_bee_toggled(null, false)` instead of writing
`main.following_bee = null` directly, `_handle_follow` re-points a
stage-owned queen follow at the current queen instead of nulling it when a
checkpoint rebuild replaces the node, and entering stage 1.11 or 1.14 arms
that stage's forage effects regardless of what the queen was doing
beforehand -- fixing the waypoint-stage arming gap. Its full record is at
`plans/archive/C1-22_2026-09-11.md`. Both of H4's dependencies (C1-21 and
C1-22) have now shipped, so H4 is admitted below -- but not as the Codex
lane's leading item: it shares `scripts/main.gd` with H2, this session's own
Claude-lane refill, and the two lanes' leading items must stay file-disjoint.
HCB-5, already queued and independent of both, takes the
leading Codex slot instead; H4 sits behind it as the lane's second item and
becomes claimable once either H2 or HCB-5 ships.

**H2 shipped 11 Sep 2026.** Ten `# --- section ---` headers went into
`hud.gd` and six into `main.gd`, comment-only, covering the 1,293 and 331
lines F14 found unheaded. Two of the plan's eight named boundaries ("role
controls", "speed controls") turned out to be interleaved with other
content in the source rather than contiguous; per the slice's own
Escalation clause that is recorded in the archive rather than acted on.
Full record: `plans/archive/H2_2026-09-11.md`. H2's departure also resolves
H4's cross-lane file conflict -- H4 now only waits on ordinary lane order
behind HCB-5, not on a leading-item collision -- but H4 still
isn't promoted here since HCB-5 hasn't shipped yet. This session also
fixed two `tools/slice.ps1` bugs surfaced while claiming H2: it was
checking a claim candidate against every item in the other lane instead of
just its leading one (contradicting `check_docs.py`'s documented rule), and
its queue-item parser silently dropped any item whose id is a multi-word
phrase rather than a single token -- which is exactly what "Hive comb
Slice 5" was. Both are fixed on master (`d4b6c27`, `f1755d9`); the
multi-word id itself is fixed here, retroactively -- the item is now
`plans/archive/HIVE_COMB_2026-09-12.md`'s HCB-5, a short bare token consistent with every
other queue item, so it can be claimed with `tools/slice.ps1 start -Lane
Codex` without producing an invalid git branch name.

**HCB-5 shipped 12 Sep 2026.** A built cell's outline now draws in the
colour of whatever resource it holds, sharing one lookup with the
designation ring; an empty cell stays outline-free and an unmapped content
kind falls back to the previous shared brown. Full record:
`plans/archive/HCB-5_2026-09-12.md`; its check is C-45. Its `Next after`
(HCB-4) fills the Codex lane's leading slot below.

**HCB-4 shipped 12 Sep 2026.** Comb Workers now reserve the six shared wall
slots while approaching an unfinished site and release them on every existing
abandon and completion path; a full site is skipped so the next worker opens
another. The prescribed headless simulations could not run here because Godot
crashed before writing its session (exit `0xC0000005`), but `verify.ps1` is
green. The hive-comb plan is complete and archived at
`plans/archive/HIVE_COMB_2026-09-12.md`; C-46 is the pending hands-on check.
H4 now leads the Codex lane.

**SB-0 shipped 12 Sep 2026.** `diagnostic_probes.gd`'s `SNAPSHOT_FIELDS`
gains `resources.stored_nectar`, `resources.stored_pollen` and
`environment.flowers_by_species`, and the `match`-per-field merge bug a
second `resources.*` entry exposed is fixed alongside it: `selected_snapshot`
now merges each selected field into its group dictionary instead of
overwriting it, so two fields from the same group (e.g. both `performance.*`
fields) survive together. `DiagnosticLog::_snapshot`'s unconditional
`resources` block and `tools/headless/profiles.py`'s allowlist (not in the
plan's Files list, but required for a fixture selecting the new fields to
pass validation before Godot launches) both got the same two totals. No
check filed -- nothing a player sees changes. Full record:
`plans/archive/SB-0_2026-09-12.md`.

**SB-1 shipped 12 Sep 2026.** `game_config.gd` gained `peak_season_strength`
(0.75), and `flower.gd::season_strength()`'s in-window return now arches
between `out_of_season_strength` and `peak_season_strength` instead of
between 0 and 1 -- which also removes the old edge discontinuity, since both
formulas now agree exactly at the window edge. `settings_catalogue.gd`
exposes the new dial. A 60-day headless A/B (today's 1.0 vs the new 0.75, on
`test_scenarios/foraging_evidence_base.json`) showed identical colony
survival in both runs and a materially narrower peak nectar-gathering rate
(12.26 -> 6.85); no 60-day fixture in `test_scenarios/` currently keeps a
colony's stored nectar/pollen above zero long enough to compare peaks there
(pre-existing, confirmed on an already-shipped fixture too, not caused by
this slice), so the rate curve stood in for the plan's stored-total
comparison. Full record: `plans/archive/SB-1_2026-09-12.md`; its check is
C-24. Its `Next after` (SB-2) filled the Claude lane's slot below.

**D1's first half shipped 12 Sep 2026.** Every `TUNABLES` row in
`scripts/settings_catalogue.gd` now carries a `persist` tag (`run`,
`player` or `none`), including 47 new rows for `GameConfig` fields the
catalogue never named at all -- F11's 25 saved-but-uncatalogued keys and
22 fields in neither list -- each with no `category` so none of them gain
a visible settings-window control this half didn't intend to add.
`scripts/save_game.gd::saved_settings()` derives the saved-keys list from
the `run` rows in place of the old hand-written `SAVED_SETTINGS` literal;
a new check, `tests/source_checks.py::check_settings_persist`, proves
that derivation byte-identical to the literal it replaced and fails on a
`GameConfig` field with no row or a `persist` tag pointing at the wrong
object. Nothing about what is saved changed, so no `FORMAT_VERSION` bump
and no hands-on check -- nothing a player sees is different yet. Full
record: `plans/design/architecture-review.md`'s D1 heading. Its second
half -- reclassifying per Dave's rule and bumping `FORMAT_VERSION` -- fills
the Claude lane's slot below.

**SB-2 shipped 12 Sep 2026.** `game_config.gd`'s `out_of_season_seed_weight`
lowered from 0.15 to 0.06, changing only that one value as specified. A
matched-seed 60-day A/B on `test_scenarios/foraging_evidence_base.json`
at both 0.15 and 0.06, sampling `environment.flowers_by_species` every 3
sim-days across the full year, showed all six species present at some point
in the year at both values -- 0.06 introduces no new extinction. Full record:
`plans/archive/SB-2_2026-09-12.md`; its check is C-25.
season-balance.md had no further slices, so the whole plan is now
archived in full at `plans/archive/SEASON_BALANCE_2026-09-12.md`. **This left the Claude lane empty**, since SB-2 was its
only item, and nothing else in `plans/now/` is currently startable for
Claude. Asked in this session, Dave chose to lift the architecture-review
hold early rather than wait for Challenge 1's Slices 21-26 to vacate
`challenge_runner.gd`, and to admit D1 specifically -- A2 shares
`scripts/main.gd` with the Codex lane's leading item (H4) and would break
the lanes' file-disjoint rule, while D1 (`scripts/settings_catalogue.gd`,
`scripts/save_game.gd`, `tests/source_checks.py`) does not.

**D1's second half shipped 12 Sep 2026.** `seasons_on`, `season_length_days`,
`disease_on`, `rival_hive_on`, `fog_of_war_on` and the three `lay_weight_*`
fields moved from `persist: "none"` to `persist: "run"` in
`scripts/settings_catalogue.gd`, per Dave's three-bucket rule. `FORMAT_VERSION`
bumped 4 -> 5, and `save_migrations.gd` gained a `_migrate_4_to_5` step
defaulting each of the eight to its `GameConfig` value for an older save.
`tests/source_checks.py` and `tests/test_save_migrations.py` were updated to
match; no hands-on check filed, since nothing a player sees changes and the
migration path is already proved by the automated fixture tests. Full record:
`plans/archive/D1_2026-09-12.md`. The plan's own `Next after` (B1) is one of
the architecture-review plan's A-G slices held under Decision A until
Challenge 1's Slices 21-26 vacate `scripts/challenge_runner.gd` -- not yet
true, since C1-24 still leads the Codex lane -- and nothing else in
`plans/now/ui.md`, `plans/now/challenge-1.md` or
`plans/design/progression.md` is currently startable, which would otherwise
have left the Claude lane empty. Asked in this session, Dave chose to lift
the hold for B1 specifically (not the whole A-G backlog): B1 touches only
`scripts/resources.gd` and `tests/source_checks.py`, file-disjoint from every
open Challenge 1 slice, and carries a `low` reasoning level with no
dependencies of its own.

**This session also fixed a stale `plans/workstreams.md` row.** D1's
worktree/branch were integrated and closed inside this same session, but the
ledger row naming `.worktrees/D1` was left behind, which is what
`tools/verify.ps1` was reporting to the Codex lane as a doc-check failure
blocking its own `tools/slice.ps1 finish` on C1-24. Removed from the primary
checkout, per `plans/workstreams.md`'s own rule that it is edited only from
there.

**B1 shipped 12 Sep 2026.** `resources.gd`'s `RESOURCES` table gained rows
for `honey`, `jelly`, `brood`, `corpse` and the empty kind, each carrying
`key`/`label`/`colour`/`is_energy`/`energy_factor`/`capacity_config`/
`index_bucket`/`storable`/`designatable`/`evictable`/`config_flag`/
`save_policy` taken from the live `match` statements in `hive_cell.gd` and
`hive.gd::take_energy`. `Resources.keys()` now returns a fixed two-entry
literal (nectar, pollen) instead of mapping over the table, so it cannot
grow by accident; `Resources.content_keys()` is the new full-list accessor.
`tests/source_checks.py::check_catalogue_alignment` was narrowed to check
only those two forager-selectable keys against `roles.gd`'s `ROLES` table,
and a new `check_resource_content_catalogue` proves the table's
`index_bucket` values exactly match `hive.gd::_content_index()`'s per-
content-type buckets. Nothing outside the two changed files was touched,
and nothing reads the new rows yet -- that is B2 onwards. No hands-on check
filed, since nothing a player sees changes. Full record:
`plans/archive/B1_2026-09-12.md`. Its `Next after` (B2) fills the Claude
lane's slot below.

**B2 shipped 12 Sep 2026.** `hive.gd::_content_index` now builds its bucket
dictionary from `Resources.content_keys()` plus the two derived buckets,
`unbuilt` and `ripe_honey`, instead of a nine-name literal, so a future
content kind only has to be added in `resources.gd`.
`tests/source_checks.py::check_resource_content_catalogue` is rewritten to
match: it confirms `_content_index` derives from `Resources.content_keys()`
and that every `RESOURCES` row's `index_bucket` still covers its own `key`,
rather than scanning a literal dict that no longer exists. An equivalence run
against master on `test_scenarios/colony_30_bees_test.json` showed no
differences. No hands-on check filed, since nothing a player sees changes.
Its `Next after` (B3) fills the Claude lane's slot below.

**B3's own successor needed a decision.** B is the last lettered slice in
`architecture-review.md`'s B series, and every other A/C/D/E/F/G slice was
held under Decision A until Challenge 1's Slices 21-26 vacated
`scripts/challenge_runner.gd`. `plans/now/challenge-1.md` shows Slices 20-26
have all shipped -- only Slice 7 (the docs-only acceptance pass, already
queued as the Codex lane's leading item) remains, and it does not touch
`challenge_runner.gd` -- so that hold is lifted. Asked in this session, Dave
chose A1 -- brood hatching reads the brood bucket -- as B3's successor: level
low, depends on nothing, touches only `scripts/main.gd`, file-disjoint from
every open item.

## Next up

1. **[Claude] B3 -- cell capacity and acceptance read the catalogue.**
   `hive_cell.gd::capacity_for` still names `honey` and `jelly` in a `match`
   instead of reading `capacity_config` off the catalogue, and `space_for`/
   `needs_eviction` name `brood`/`corpse` instead of testing `storable`/
   `evictable`. Read `capacity_config`/`storable`/`evictable` from
   `resources.gd`'s `RESOURCES` table instead.
   - Plan: `plans/design/architecture-review.md` -- "B3 — cell capacity and acceptance read the catalogue"
   - Files: `scripts/hive_cell.gd`, `scripts/hive.gd`, `scripts/resources.gd`
   - Check: `tests/balance_tests.py` passes unchanged, including a new case asserting `capacity_for` for all seven kinds against current `GameConfig` defaults
   - Proof: `present: scripts/hive_cell.gd :: func capacity_for(resource_type: String) -> float:`
   - Next after: A1 -- brood hatching reads the brood bucket.

2. **[Codex] UI-U-1 -- step back and forth through Challenge stages.**
   Add developer controls in Game Settings > World and Start for navigating a
   Challenge's stages through the runner's existing transition path.
   - Plan: `plans/now/ui.md` -- "UI-U-1 — step back and forth through a Challenge's stages"
   - Files: `scripts/debug_panel.gd`, `scripts/challenge_runner.gd`, `plans/reference/check-loop.md`
   - Check: stage navigation rebuilds the same gates, prompts and markers; no skip leaves camera-follow or 4x speed active
   - Proof: `present: scripts/challenge_runner.gd :: func debug_advance_stage() -> void:`
   - Next after: UI-P-5 -- reproduce the missing pre-run placeholder live.

3. **[Codex] A2 -- one role tally.**
   Role counts are currently built in several incompatible places. Derive the
   population readout and colony diagnostics from the canonical `Roles.count_key`
   representation, including the hive's hatch-focus counts.
   - Plan: `plans/design/architecture-review.md` -- "A2 — one role tally"
   - Files: `scripts/main.gd`, `scripts/colony_diagnostics.gd`, `scripts/hive.gd`
   - Check: no file outside `roles.gd` contains the legacy `"%d|%s"`, `"%d|"` or `"0|%s"` count keys; an H3 equivalence run preserves the colony population lines
   - Proof: `present: scripts/main.gd :: func _role_counts() -> Dictionary`
   - Next after: A3 -- epoch-cached hive stock totals.

## Not in the queue, and why

Each of these wants something from Dave, something else to ship first, or
simply a free slot -- the queue holds three (the floor), and none of the
entries below is startable today.

- **The architecture review's remaining A-to-G slices**
  (`plans/design/architecture-review.md`), other than A1 and A2 above --
  Decision A's hold (every A/C/D/E/F/G slice waits for Challenge 1's Slices
  21-26 to vacate `scripts/challenge_runner.gd`) is lifted as of 12 Sep 2026,
  since those slices have all shipped, but the queue holds only three items
  and A1 and A2 already fill both of this session's open slots.
- **UI-U-1** (`plans/now/ui.md`) -- arrows in Game Settings > World and Start
  for stepping back and forth through a Challenge's stages, which is the
  instrument for reaching stages 1.12 to 1.14 without a full playthrough. It
  edits both `scripts/debug_panel.gd` and `scripts/challenge_runner.gd`, so it
  waits for both lanes to vacate them.
- **UI-P-5** (`plans/now/ui.md`) -- named two plausible causes; a 10 Sep 2026
  headless check ruled both out (the placeholder is present, visible and
  correctly positioned in a fresh boot), so the real cause needs Dave's own
  screen, not more static reading. None of Dave's six passes since 8 Sep has
  reported on it.
- **Progression Phase B step 6 onwards** (`plans/design/progression.md`) --
  the foraging tier-1 vertical slice is where the tree panel, the HUD button
  and run saving first appear. Phase A (steps 1-4) is complete precisely
  because it stops short of it. Its acceptance is something Dave sees, so it
  wants a clear run of the UI work above rather than to compete with it.
- **The cell-art rings' last pixel** -- C-20 passed with "move the cell-art
  highlight rings 1 px higher". One constant, too small for a slice of its
  own; it rides with the next slice that opens the cell-art drawing, and is
  recorded in `docs/archive/HANDS_ON_CHECKS_ARCHIVE.md` under C-20 so it is
  not lost.
- **The documented smoke scenario fails on master** -- `python
  tools/run_scenario.py test_scenarios/slice1_smoke_test.json` is the first
  command `docs/headless-run-contract.md` gives a new session, and on 11 Sep
  2026 it returned `status=failed`, `classification=product_failure`: its one
  assertion waits on `cells_completed_at_least: 1` and never fires inside the
  fixture's three days, with ten cells, one builder and one miner. The harness
  itself is healthy -- exit code 0, a classified result in 7.7 s. This is
  either a fixture whose assumption stopped holding or a real build-throughput
  finding, and telling which needs a trace, not a reading. Not a slice until
  someone has looked: it is one investigation, and nothing waits on it.
- **Save/load during an active Challenge** -- a settled design decision, not
  a defect. `DESIGN_BACKLOG.md` holds it; it is not restated here.
- **The Codex lifecycle's own success measure** -- CR-1 to CR-7 all shipped by
  9 Sep 2026 and the plan is archived at
  `plans/archive/CODEX_RELIABILITY_2026-09-09.md`, but its stated measure was
  ten throwaway lifecycle exercises including parallel lanes and injected
  failures, and those were never run. It is not a defect and nothing waits on
  it, so it is not a slice; it becomes one only if a lifecycle failure recurs.

## Copy-paste prompts

Start a new session with one of these and nothing else.

Claude, implementing:

```
Implement the next slice.
```

Codex, implementing:

```
Read CHATGPT.md, then NEXTSTEPS.md. Implement the first unclaimed [Codex] item
in the Next up queue. Follow its Plan heading only. Claim it with
tools/slice.ps1 start -Lane Codex, implement, run tools/verify.ps1, then close
out per CHATGPT.md's "Risk-proportional closeout".
```

Claude, integrating a high-risk Codex branch (the only kind handed over):

```
Integrate the finished Codex branch and close it out.
```

Claude, when Dave has done a hands-on pass:

```
I've done a hands-on pass. Here's what I found: <notes>. Update the checks,
plans and queue.
```
