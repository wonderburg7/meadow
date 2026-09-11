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
Two things came out of it that are Dave's to decide, and both sit under "Not
in the queue" below: where the new slice H4 goes relative to Challenge 1, and
which of `tools/check_docs.py`'s two contradictory rules gives way.

## Next up

1. **[Codex] C1-23 -- Challenge 1's wax cell is full at 150 nectar, not 200.**
   Add a `NECTAR_TARGET` constant beside the existing `POLLEN_TARGET` and
   have the nectar stage's goal check and progress bar use it instead of the
   cell's full 200 capacity, so the queen stops filling it at 150 and the
   nectar stage stays a demonstration rather than a chore.
   - Plan: `plans/now/challenge-1.md` -- "Slice 23 — a Challenge 1 wax cell is full at 150 nectar"
   - Files: `scripts/challenge_stages.gd`, `scripts/challenge_runner.gd`
   - Check: one check confirming the nectar stage's goal bar fills and the queen stops at 150, not 200
   - Proof: `absent: scripts/challenge_stages.gd :: NECTAR_TARGET`
   - Next after: C1-24 (the stage marker is never left in the wrong world, at 1.12 and 1.15)

2. **[Claude] C1-21 -- the queen forages pollen without being pushed.**
   At the pollen stage she stays put when the player switches her focus to
   Pollen, and only sets off once something else has moved her out of the
   hive. Trace it headlessly first: the standing hypothesis is that the
   nectar she is still carrying routes her to a deposit that does not exist,
   and C1-25 has just made her keep that load rather than lose it, so the
   stall is now the only way it can end. Fix what the trace shows.
   - Plan: `plans/now/challenge-1.md` -- "Slice 21 — the queen forages pollen without being pushed"
   - Files: `scripts/bee.gd`, `scripts/bee_foraging.gd`
   - Check: C-7's pollen half, re-run once she leaves on the focus change alone
   - Proof: `absent: scripts/bee_foraging.gd :: C1-21`
   - Next after: H3 (the behaviour-equivalence run, queued at 4 below)

3. **[Codex] C1-22 -- the pollen stage's camera never follows.**
   At stage 1.14 the speed goes to 4x and back correctly, but the camera
   never follows the queen; Dave confirmed this unchanged on a second pass.
   `_run_stage_effects`'s `camera_follow_off` writes `main.following_bee =
   null` directly rather than through `camera_view._on_follow_bee_toggled`,
   an asymmetry worth removing regardless of the trace's answer. Confirm the
   actual last writer first (log every write to `main.following_bee` for
   stage 1.14), then fix it; separately, an early forage trip during the
   meadow-waypoint stage stops the nectar stage's automation from arming at
   all -- entering 1.11 must arm the effects regardless of what the queen
   was doing beforehand.
   - Plan: `plans/now/challenge-1.md` -- "Slice 22 — the stage's camera reaches the pollen stage"
   - Files: `scripts/challenge_runner.gd`, `scripts/camera_view.gd`
   - Check: C-29, re-run once the camera follows at the pollen stage and the waypoint-stage arming gap is fixed
   - Proof: `present: scripts/challenge_runner.gd :: main.following_bee = null`
   - Next after: C1-26 (the marker pulses and shows an off-screen arrow when it is off screen). C1-23 above already names C1-24 as its successor, so the Codex lane reaches C1-24 first and C1-26's one dependency is met by the time this item lands.

4. **[Claude] H3 -- the behaviour-equivalence run.**
   Seventeen architecture slices each name a before-and-after scenario
   comparison as their acceptance, and nothing can run one: the experiment
   harness compares configuration cases inside a single build by design. Build
   one command that runs a scenario at a given git ref and again in the working
   tree at the same seed, prints only the summary fields that differ, and exits
   non-zero when any do. Touches no `scripts/` file, so it cannot collide with
   either Challenge 1 lane. The slice may add a sibling tool beside the runner
   rather than a flag on it; nothing else claims either, and a file that does
   not exist yet cannot be named on a Files: line, so the entry reserves the
   runner. The plan records why under H3.
   - Plan: `plans/design/architecture-review.md` -- "H3 — the behaviour-equivalence run"
   - Files: `tools/run_scenario.py`, `docs/headless-run-contract.md`
   - Check: none needed -- the acceptance is the tool's own exit status, and a unit test covers the diff without launching Godot
   - Proof: `absent: docs/headless-run-contract.md :: equivalence`
   - Next after: H1 (the function map covers what it says it covers)

5. **[Claude] H1 -- the function map covers what it says it covers.**
   `FUNCTION_MAP.md` says it indexes every script over ~700 lines; thirteen
   scripts are now over 700 and six are missing, including `bee_foraging.gd`
   and `challenge_runner.gd`, both named in the queue above. The generator's
   file list is hardcoded, so `--check` cannot see the gap. Derive the list
   from a named threshold and make `--check` fail when a file crosses it
   unindexed.
   - Plan: `plans/design/architecture-review.md` -- "H1 — the function map covers what it says it covers"
   - Files: `tools/update_function_map.py`, `FUNCTION_MAP.md`
   - Check: none needed -- `python tools/update_function_map.py --check` is the acceptance, and nothing a player sees changes
   - Proof: `absent: tools/update_function_map.py :: bee_foraging.gd`
   - Next after: H2 (the HUD and main scripts get the section headers the routing rule assumes)

## Not in the queue, and why

Each of these wants something from Dave, or something else to ship first.

- **Challenge 1 Slices 24 and 26** (`plans/now/challenge-1.md`) -- both are
  specified. Slice 26 (the marker pulses and shows an off-screen arrow, both
  Dave's 10 Sep asks) waits on Slice 24, the other open change to the same
  marker node. Slice 24 is next after C1-23 and is queued as its
  `Next after:`. Slice 22 is now in the queue above (C1-22) -- with HC-16
  landed and its plan archived (`plans/archive/HUD_CONTROLS_2026-09-11.md`),
  C1-21 moved into the Claude lane it vacated, freeing C1-22 to be queued
  directly rather than only as C1-21's `Next after:`.
- **The architecture review's A-to-G slices**
  (`plans/design/architecture-review.md`) -- seventeen slices, all specified.
  Dave admitted the three that touch no gameplay file (H3 and H1 above, H2
  behind them) and held the rest until Challenge 1's Slices 21 to 26 have
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
- **SB-1 and SB-2** (`plans/now/season-balance.md`) -- the reason recorded
  here until 11 Sep 2026, a `0xC0000005` exit from the smoke baseline, no
  longer reproduces: that scenario now completes in 7.7 s with exit code 0 and
  a classified result. The real obstacle, found in the 11 Sep plan review, is
  that both slices name a measurement that does not exist -- there is no
  full-year *scenario* in the balance suite (it is a static analyser), and no
  snapshot field carries stored nectar, stored pollen or live flowers by
  species. **SB-0** now leads that plan: it adds those three probes, it is
  startable today, and it shares no file with either lane. It is this lane's
  refill candidate the next time a Claude slot opens.
- **Hive comb Slices 4 and 5** (`plans/now/hive-comb.md`) -- Slice 4's
  headless trace found the mechanism (every idle Comb Worker piles onto one
  unfinished site), but capping builders per site changes build throughput,
  so it wants Dave's live look and a call on intended behaviour. Slice 5
  wants its own reproduction.
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
- **H4 -- a headless run can start a Challenge and reach a stage**
  (`plans/design/architecture-review.md`). New, from the 11 Sep plan review,
  and **waiting on one decision from Dave**. Nine open slices across three
  plans state a headless Challenge assertion as their acceptance, and no
  headless run can start a Challenge: the runner starts only for
  `Session.starting_level` 1 or 2, and a `--scenario` launch always sets that
  to the scenario level. There is no Challenge fixture and no stage-sequence
  test, though three slices name one as their regression check. Two of the
  nine -- Challenge 1's Slices 24 and 26 -- have no acceptance at all until
  this lands, so neither should be queued ahead of it. H4 owns
  `scripts/challenge_runner.gd`, which is why its position is a decision and
  not a lookup; the plan states the three orderings and recommends landing it
  after C1-21 and C1-22 and before C1-24 and C1-26.
- **`tools/check_docs.py` contradicts itself about a file a slice creates**
  -- `validate_queue_files`'s docstring says a queue `Files:` line may name
  "exact paths for files created by a slice", and `check_backticked_paths`
  then rejects any backticked path not on disk, `NEXTSTEPS.md` included. H3
  above already works around it by reserving `tools/run_scenario.py` instead
  of the new equivalence tool it will create beside it. Three more slices will hit the
  same wall: the architecture review's C1 creates `conditions.gd`, G1 creates
  `actions.gd` and F1s creates `game_panel.gd`. Waiting on Dave's call on
  which rule gives way -- the plan review's recommendation is that
  `check_backticked_paths` skip paths inside a queue item's `Files:` line,
  since `validate_queue_files` has already checked their shape.
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
