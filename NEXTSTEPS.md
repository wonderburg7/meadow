# Next steps

<!-- CONTEXT: current-queue | LOAD: every session -->

**"Implement the next slice" means:** run `tools/slice.ps1 start -Lane Claude`
(or `-Lane Codex`) to claim your lane's leading item and open its worktree,
open only the `Plan:` file and heading that item names, implement, run
`tools/verify.ps1`, and close with the end-of-slice report (`CLAUDE.md`).
Do not read the other lane's plan, the archive, `ROADMAP.md` or Git history
to work out what to do -- the script already decided.

**Dave ran a full hands-on pass on 8 Sep 2026 and both lanes are stocked
again.** Fourteen checks went out; eleven came back confirmed and are
archived, three failed, and two could not be run because of the command tray
running off the bottom of the screen. Every item below is specified down to
the function and the line, because each one was diagnosed against the source
during that pass -- the plan sections say what to change and what not to
touch, so no slice below needs a fresh investigation.

## Next up

1. **[Claude] UI-T-1 -- keep the command tray wholly on screen.** The tray's
   height is measured at the old width and then narrowed, so its top edge
   lands too low and its content spills past the bottom edge; the height cap
   that was meant to stop this is a no-op, because `Control.set_size` clamps
   *up* to the combined minimum. Fix the order, and express the cap as a
   `ScrollContainer` instead of an assignment to `size`. This is the highest
   item in the whole queue: two other checks cannot be run at all while it
   stands.
   - Plan: `plans/now/ui-bottom-row.md` -- "UI-T-1 — the command tray must stay wholly on screen"
   - Files: `scripts/hud.gd`, `scripts/ui_layout.gd`
   - Check: file C-18, replacing C-11 and C-12; move C-5 and C-7 back from
     `checks/blocked.md` to `checks/ready.md` unchanged in the same pass
   - Proof: `present: scripts/hud.gd :: command_tray.size.y = minf(command_tray.size.y, maximum_height)`
   - Next after: UI-T-2 (left-side windows shorten for the summary panel)

2. **[Codex] UI-T-4 -- stop clipping the first hexagon's left point.** Each
   pre-run menu tile paints its border polygon `HEX_BORDER_OVERLAP` (3px)
   wider than the tile's own bbox, so tile 0's leftmost vertex sits at x=-3
   and the wrapping `ScrollContainer` cuts it off. Inset the whole strip by
   that constant and widen the strip's minimum size to match.
   - Plan: `plans/now/ui-small-fixes.md` -- "UI-T-4 — the pre-run menu clips the first hexagon's left point"
   - Files: `scripts/main_menu.gd`
   - Check: file C-21
   - Proof: `present: scripts/main_menu.gd :: tile.position = Vector2(float(i) * HEX_STEP_X, row_offset if i % 2 == 1 else 0.0)`
   - Next after: UI-T-3 (cell highlight rings two pixels lower)

3. **[Claude] UI-T-2 -- left-side windows shorten for the summary panel.**
   `left_window_max_height` reserves against the viewport's bottom edge and
   knows nothing about the bottom row, so Colony, Foraging and Nursery draw
   over the bee summary panel. Give it the summary panel's top as a third
   argument, add the `hud.gd` accessor that supplies it, and reflow the three
   windows when the selection changes.
   - Plan: `plans/now/ui-bottom-row.md` -- "UI-T-2 — left-side windows shorten instead of covering the summary panel"
   - Files: `scripts/ui_layout.gd`, `scripts/hud.gd`, `scripts/colony_panel.gd`, `scripts/foraging_panel.gd`, `scripts/nursery_panel.gd`
   - Check: file C-19
   - Proof: `present: scripts/ui_layout.gd :: return maxf(120.0, viewport_height - top - SELECTION_TRAY_GAP)`
   - Next after: UI-S-4b (a double right-click stops closing the bee panels)

4. **[Codex] UI-T-3 -- cell highlight rings two pixels lower.** Every ring
   built from `EMPTY_SILHOUETTE` sits 2px high on the drawn cup. Add a
   ring-only `RING_Y_NUDGE` inside `_silhouette_point_to_local` so the sprite
   itself is untouched and the two still cannot drift apart.
   - Plan: `plans/now/ui-small-fixes.md` -- "UI-T-3 — cell highlight rings sit two pixels high"
   - Files: `scripts/hive_cell.gd`
   - Check: file C-20
   - Proof: `absent: scripts/hive_cell.gd :: RING_Y_NUDGE`
   - Next after: UI-T-5 (settings sections collapsed on startup)

5. **[Codex] UI-T-5 -- settings sections collapsed on startup.** The panel is
   built with everything closed, but `open_to_categories()` (the pre-run
   menu's Settings button) expands Accessibility and Appearance and nothing
   ever closes them again, so the expansion follows the player into every
   later run. Add `collapse_all()` and drive it from `Session.run_reset`.
   - Plan: `plans/now/ui-small-fixes.md` -- "UI-T-5 — the settings window opens with every section collapsed"
   - Files: `scripts/debug_panel.gd`
   - Check: file C-22
   - Proof: `absent: scripts/debug_panel.gd :: func collapse_all()`
   - Next after: SB-1 (peak-season production is a rise, not a spike)

## Ready, not yet in the queue

These are fully specified and could be started today; they are out of the
queue only because it is capped at five. Promote them as the lanes drain, in
this order.

- **UI-S-4b** (`plans/now/ui-bottom-row.md`) -- a double right-click closes the bee
  panels. C-14's log has been recovered and analysed: the selection is
  provably intact on every right-click, which retires UI-S-4's theory and
  makes this a presentation fix plus one input-boundary guard. Claude lane,
  after UI-T-2 (same file).
- **UI-Q-3** (`plans/now/ui-bottom-row.md`) -- the warning dwell rule. C-4 passed and
  gave the timings that settle the priority design UI-Q-1 deferred: ~6s,
  ~1-2s, ~12s. Claude lane, after UI-S-4b (same file).
- **SB-1** (`plans/now/season-balance.md`) -- peak season production is a
  spike, twenty times the out-of-season floor, and discontinuous at the
  window edge. One curve and one new `GameConfig` value, with the headless
  comparison stated in the slice. Codex lane.
- **SB-2** (`plans/now/season-balance.md`) -- out-of-season species seed at
  0.15 of their usual weight, which reads as a standing presence rather than
  a rarity. One value. Codex lane, after SB-1 (same file).

## Not in the queue, and why

Each of these wants something from Dave, or something else to ship first.

- **Challenge 1 Slice 7** (`plans/now/challenge-1.md`) -- the acceptance
  playthrough, and Dave's run rather than a code slice. It is stalled behind
  UI-T-1 for exactly the reason C-7 is: the role controls it needs are below
  the bottom edge of the screen.
- **Challenge 2 Slice 2** (`plans/now/challenge-2.md`) -- fixing whichever of
  the rescue and recovery lines does not appear. C-5 is in
  `checks/blocked.md` behind UI-T-1; nothing can be written here until it is
  run, and guessing has already failed twice.
- **Hive comb Slices 4 and 5** (`plans/now/hive-comb.md`) -- Slice 4's
  headless trace found the mechanism (every idle Comb Worker piles onto one
  unfinished site), but capping builders per site changes build throughput,
  so it wants Dave's live look and a call on intended behaviour. Slice 5
  wants its own reproduction.
- **UI-P-5** (`plans/now/ui.md`) -- names two plausible causes and says to
  reproduce the symptom live before choosing between them. Dave's 8 Sep pass
  did not report on it. UI-D is now closed: C-3 passed on 8 Sep 2026.
- **Progression Phase B step 6 onwards** (`plans/design/progression.md`) --
  the foraging tier-1 vertical slice is where the tree panel, the HUD button
  and run saving first appear. Phase A (steps 1-4) is complete precisely
  because it stops short of it. Its acceptance is something Dave sees, so it
  wants a clear run of the UI work above rather than to compete with it.
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
