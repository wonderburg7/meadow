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
resource outlines itself in that resource's colour -- both are specified in
`plans/now/hive-comb.md` and both are startable, waiting only for a queue
slot.

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
`plans/now/hive-comb.md`'s HCB-5, a short bare token consistent with every
other queue item, so it can be claimed with `tools/slice.ps1 start -Lane
Codex` without producing an invalid git branch name.

**HCB-5 shipped 12 Sep 2026.** A built cell's outline now draws in the
colour of whatever resource it holds, sharing one lookup with the
designation ring; an empty cell stays outline-free and an unmapped content
kind falls back to the previous shared brown. Full record:
`plans/archive/HCB-5_2026-09-12.md`; its check is C-45. Its `Next after`
(HCB-4) fills the Codex lane's leading slot below.

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
`plans/archive/SB-0_2026-09-12.md`. Its `Next after` (SB-1) fills the
Claude lane's slot below. SB-1 does not touch `docs/headless-run-contract.md`,
so the cross-lane note on H4 below (which used to point at SB-0 owning that
file) is simplified to plain lane order behind HCB-4.

## Next up

1. **[Codex] HCB-4 -- at most six comb builders per site, one to a wall.**
   Idle Comb Workers currently pile onto the first unfinished cell, even
   though a hex already has six wall positions. Give each builder a stable
   wall slot, skip a site only once all six slots are claimed, and keep an
   abandoned site resumable when it still has a free wall.
   - Plan: `plans/now/hive-comb.md` -- "HCB-4 — Cell auto-building: every idle builder piles onto one site"
   - Files: `scripts/hive.gd`, `scripts/bee_building.gd`, `scripts/hive_cell.gd`
   - Check: a seven-worker comb build never assigns more than six workers to one cell and starts a second site while the first is unfinished
   - Proof: `present: scripts/hive_cell.gd :: func claim_slot(bee: Node2D) -> int`
   - Next after: HCB plan complete.

2. **[Codex] H4 -- a headless run can start a Challenge and reach a stage.**
   Challenge-only acceptance checks cannot run today: scenario launches use
   `Levels.SCENARIO_LEVEL_ID`, so `challenge_runner.start()` never fires.
   Let a scenario name a Challenge, add a verb that steps through the ordinary
   `debug_advance_stage()` seam to a named stage, expose the current stage id
   to scenario assertions, and prove it with a fixture that reaches 1.14.
   Queued behind HCB-4 above in ordinary lane order; it becomes claimable
   once HCB-4 ships.
   - Plan: `plans/design/architecture-review.md` -- "H4 — a headless run can start a Challenge and reach a stage"
   - Files: `scripts/main.gd`, `scripts/scenario_actions.gd`, `scripts/challenge_runner.gd`, `docs/headless-run-contract.md`, `test_scenarios/h4_challenge1_stage_advance_test.json`
   - Check: a fixture starts Challenge 1, reaches 1.14 by the ordinary stage-advance path, and asserts that stage id; every existing scenario fixture keeps its verdict
   - Proof: `present: scripts/challenge_runner.gd :: func debug_advance_stage() -> void`
   - Next after: Challenge 1 Slice 24 -- the stage marker is never left in the wrong world. H4 is the shared prerequisite that gives Slice 24's stated headless acceptance a runnable path.

3. **[Claude] SB-1 -- peak-season production is a rise, not a spike.**
   `flower.gd::season_strength()` returns a plain sine arch reaching exactly
   1.0 at the middle of a species' window, twenty times the out-of-season
   floor, and it is discontinuous at the window edges (eases to 0.0, then
   jumps to the 0.05 floor one frame later). Add a `peak_season_strength`
   dial to `game_config.gd`, rewrite the in-window return to arch between the
   floor and that peak (removing the discontinuity for free), and expose the
   new value in `settings_catalogue.gd`. Simulate a 60-day headless year at
   1.0 (today) and 0.75 using SB-0's new snapshot fields before shipping.
   - Plan: `plans/now/season-balance.md` -- "SB-1 — peak-season production is a rise, not a spike"
   - Files: `scripts/game_config.gd`, `scripts/flower.gd`, `scripts/settings_catalogue.gd`
   - Check: one hands-on check watching a season's `+/s` figures peak closer to the shoulder without a jump at the window edge, while out-of-season flowers are unchanged
   - Proof: `absent: scripts/game_config.gd :: peak_season_strength`
   - Next after: SB-2 -- out-of-season species become genuinely rare (`plans/now/season-balance.md`); startable the moment SB-1 lands (both add a value to `scripts/game_config.gd`).

## Not in the queue, and why

Each of these wants something from Dave, something else to ship first, or
simply a free slot -- the queue holds three (the floor), and none of the
entries below is startable today.

- **Challenge 1 Slices 24 and 26** (`plans/now/challenge-1.md`) -- both are
  specified, and **neither has an acceptance that can run until H4 lands**:
  each states only a headless Challenge assertion, and no headless run can
  start a Challenge. Slice 26 also waits on Slice 24, the other open change
  to the same marker node. The Codex lane reaches them in order without
  anything being decided here: C1-22 promotes H4, H4 promotes Slice 24, and
  Slice 24 promotes Slice 26.
- **The architecture review's A-to-G slices**
  (`plans/design/architecture-review.md`) -- seventeen slices, all specified.
  Dave admitted the three that touch no gameplay file (H3 shipped 11 Sep
  2026; H1 above, H2 behind it) and held the rest until Challenge 1's
  Slices 21 to 26 have
  vacated `challenge_runner.gd`, which C1-23 and C1-22 above are both still in.
  A2 and D1 are the two that do not touch that file, so they are the ones to
  ask Dave about lifting early if the Challenge 1 arc runs long. Do not lift
  the hold unasked.
- **Challenge 1 Slice 7** (`plans/now/challenge-1.md`) -- the acceptance
  playthrough. Not worth a sixth attempt until Slices 20 to 26 have made the
  pollen arc work unattended.
- **UI-U-1** (`plans/now/ui.md`) -- arrows in Game Settings > World and Start
  for stepping back and forth through a Challenge's stages, which is the
  instrument for reaching stages 1.12 to 1.14 without a full playthrough. It
  edits both `scripts/debug_panel.gd` and `scripts/challenge_runner.gd`, so it
  waits for both lanes to vacate them.
- **SB-2** (`plans/now/season-balance.md`) -- out-of-season species become
  genuinely rare. Waits on **SB-1**, now in the Claude lane above, since both
  add a value to `scripts/game_config.gd`; SB-1's own `Next after`.
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
