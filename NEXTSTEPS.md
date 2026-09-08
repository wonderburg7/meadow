# Next steps

<!-- CONTEXT: current-queue | LOAD: every session -->

**"Implement the next slice" means:** run `tools/slice.ps1 start -Lane Claude`
(or `-Lane Codex`) to claim your lane's leading item and open its worktree,
open only the `Plan:` file and heading that item names, implement, run
`tools/verify.ps1`, and close with the end-of-slice report (`CLAUDE.md`).
Do not read the other lane's plan, the archive, `ROADMAP.md` or Git history
to work out what to do -- the script already decided.

**UI-W-3 shipped 2026-09-08** (`plans/archive/UI-W-3_2026-09-08.md`): Colony
and Foraging's sections now start collapsed, and Colony's remembered
`section_open` state resets on `Session.run_reset`. UI-W-4 takes its place
in the queue.

Every item below is specified down to the function and the line, because each
one was diagnosed against the source during the 8 Sep pass.

## Next up

1. **[Codex] SB-1 -- peak-season production is a rise, not a spike.**
   - Plan: `plans/now/season-balance.md` -- "SB-1 — peak-season production is a rise, not a spike"
   - Files: see the named plan heading
   - Check: file C-24
   - Proof: see the named plan heading
   - Next after: SB-2 (out-of-season species have a standing presence)

2. **[Codex] Challenge 2 Slice 2 -- the collapse button does what its tooltip says.**
   The button picks its target from the nectar currently in the hive, which
   the rescue has just topped up by 150, so the second press does nothing and
   the third is the one that reaches the failure floor. Count presses instead.
   The rescue line also needs `clear_queue()` before `show_now()`, or the
   stage's next hint overwrites it.
   - Plan: `plans/now/challenge-2.md` -- "Slice 2 — the collapse button does what its tooltip says, and the rescue line survives"
   - Files: `scripts/debug_panel.gd`, `scripts/challenge_runner.gd`, `scripts/gallerin_panel.gd`
   - Check: re-file C-5
   - Proof: `absent: scripts/debug_panel.gd :: _c2_collapse_presses`
   - Next after: none -- `plans/now/challenge-2.md` is complete once this lands

3. **[Claude] UI-W-4 -- the pre-run Settings button opens nothing pre-expanded.**
   `main_menu.gd::_on_settings_pressed` opens the settings window with
   Accessibility and Appearance pre-expanded; Dave asked for the pre-run
   Settings button to open with every collection and topic section
   collapsed, matching the in-run window C-22 already confirmed.
   - Plan: `plans/now/ui-windows.md` -- "UI-W-4 — the pre-run Settings button opens nothing pre-expanded"
   - Files: `scripts/main_menu.gd`
   - Check: file C-27
   - Proof: `present: scripts/main_menu.gd :: panels[0].open_to_categories(["Accessibility", "Appearance"])`
   - Next after: none -- `plans/now/ui-windows.md` is complete once this lands

## Ready, not yet in the queue

These are fully specified and could be started today; they are out of the
queue only because it is capped at five. Promote them as the lanes drain, in
this order.

- **SB-2** (`plans/now/season-balance.md`) -- out-of-season species seed at
  0.15 of their usual weight, which reads as a standing presence rather than
  a rarity. One value. Codex lane, after SB-1 (same file).
- **LAY-1** (`plans/now/ui-layout-ownership.md`) -- one owner for every
  persistent HUD rectangle, plus the source check that stops
  `custom_minimum_size` being used as a ceiling again. Deliberately last: it
  consolidates the arithmetic UI-T-6 got right and UI-W-1 will get right, and
  running it first would consolidate two known-wrong sums.

## Not in the queue, and why

Each of these wants something from Dave, or something else to ship first.

- **Challenge 1 Slice 7** (`plans/now/challenge-1.md`) -- the acceptance
  playthrough, and Dave's run rather than a code slice. It needs C-7, ready
  to run in `checks/ready.md` now that UI-T-6 shipped and unblocked it.
- **Hive comb Slices 4 and 5** (`plans/now/hive-comb.md`) -- Slice 4's
  headless trace found the mechanism (every idle Comb Worker piles onto one
  unfinished site), but capping builders per site changes build throughput,
  so it wants Dave's live look and a call on intended behaviour. Slice 5
  wants its own reproduction.
- **UI-P-5** (`plans/now/ui.md`) -- names two plausible causes and says to
  reproduce the symptom live before choosing between them. Neither of Dave's
  8 Sep passes reported on it.
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
- **Save/load during an active Challenge** -- a settled design decision, not
  a defect. `DESIGN_BACKLOG.md` holds it; it is not restated here.

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
