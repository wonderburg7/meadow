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
Hive comb Slice 5 -- already startable per Dave's 11 Sep 2026 answers and
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

## Next up

1. **[Codex] C1-22 -- the pollen stage's camera never follows.**
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
   - Next after: H4 (a headless run can start a Challenge and reach a stage). H4 depends on this slice landing (alongside C1-21, already shipped), and Dave's 11 Sep 2026 ordering decision places it directly after this slice and before C1-24 and C1-26.

2. **[Codex] Hive comb Slice 5 -- a cell's outline takes the colour of what is in it.**
   With Cell art on, a built cell's outline stays one shared brown no matter
   what it holds, so a first deposit is easy to miss; there is no lag, just
   one colour used for everything. Hoist the nectar/pollen/honey/brood colour
   lookup the designation ring already uses into one function that both the
   ring and the outline call, so a cell holding any amount of a resource
   draws its outline in that resource's colour. An empty cell keeps no
   outline at all, and a content kind with no colour of its own falls back to
   today's brown rather than to nothing.
   - Plan: `plans/now/hive-comb.md` -- "Slice 5 — a cell's outline takes the colour of what is in it"
   - Files: `scripts/hive_cell.gd`
   - Check: one check confirming a deposit gives its cell an outline in that resource's colour, and an empty cell stays outline-free
   - Proof: `present: scripts/hive_cell.gd :: outline.default_color = Color(0.35, 0.28, 0.12)`
   - Next after: Slice 4 (at most six comb builders per site, one to a wall). Dave's 11 Sep 2026 answer runs Slice 5 first because it is smaller and the one he will see; the two slices are independent and share only `hive_cell.gd`.

3. **[Claude] H1 -- the function map covers what it says it covers.**
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

Each of these wants something from Dave, something else to ship first, or
simply a free slot -- the queue holds three (the floor), and three of
the entries below are startable today.

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
  (`plans/design/architecture-review.md`). Nine open slices across three plans
  state a headless Challenge assertion as their acceptance, and no headless
  run can start a Challenge: the runner starts only for
  `Session.starting_level` 1 or 2, and a `--scenario` launch always sets that
  to the scenario level. **Decided, not blocked** -- Dave placed it after
  C1-21 and C1-22 and before C1-24 and C1-26 on 11 Sep 2026, and C1-22 above
  names it as its successor, so it enters the Codex lane by the ordinary
  promotion rather than needing anything from here. C1-21 has already
  shipped; it is only waiting on C1-22.
- **Hive comb Slice 4** (`plans/now/hive-comb.md`) -- **startable, waiting
  only for a slot.** Dave answered its open question on 11 Sep 2026: at most
  six comb workers per site, one to each wall of the hexagon, using the
  six-slot mechanism `hive_cell.gd` already has. It shares `hive_cell.gd`
  with Slice 5 above (different parts of the file, so it rebases cleanly
  either way) and with nothing else in the queue; Slice 5 above names it as
  its successor.
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
