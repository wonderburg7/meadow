# Next steps

<!-- CONTEXT: current-queue | LOAD: every session -->

Five ready slices in two lanes, refilled 3 Sep 2026 after UI-S-1 and W-6
landed.

**Everything in this file can be started right now.** Nothing here is waiting
on a hands-on check, a live repro, or a decision from Dave. Work that *is*
waiting is listed under "Not in the queue" at the bottom, with a pointer, and
is deliberately not mixed in above.

**"Implement the next slice" means:** run `tools/slice.ps1 start -Lane
Claude` (or `-Lane Codex`) to claim the lane's leading item and open its
worktree, open only the `Plan:` file and heading it names, implement, run
`tools/verify.ps1`, and close with the end-of-slice report (`CLAUDE.md`,
"End-of-slice report"). Do not read the other lane's plan, the archive,
`ROADMAP.md` or Git history to work out what to do -- the script already
decided.

## Next up

1. **[Claude] W-7 -- `verify.ps1` is quiet on success.**
   - Plan: `plans/now/agent-workflow.md` -- W-7.
   - Does: adds `-Quiet` and `-Docs` switches to `tools/verify.ps1`. `-Quiet`
     captures each stage and prints one line per stage (`source checks: OK`,
     `balance tests: OK`, `function map: OK`, `doc checks: OK`), printing a
     stage's captured output in full only when it fails; `-Docs` runs
     `tools/check_docs.py` alone and skips the source, balance and
     function-map stages. The doc stage's failures print under a heading that
     names them as documentation, not code, with the code suites' passes
     still visible. No stage changes what it checks, and the no-switch output
     is untouched.
   - Files: `tools/verify.ps1`.
   - Check: `tools/verify.ps1`. No hands-on check: `-Quiet` printing four
     lines, `-Docs` skipping the code suites, and a deliberately broken
     `plans/workstreams.md` row producing a doc-only failure are all
     scriptable.
   - Proof: `absent: tools/verify.ps1 :: $Quiet`
   - Why first: W-6 landed and W-7 is its `Next after:` item and
     `plans/now/agent-workflow.md`'s last open slice. It owns `tools/verify.ps1`
     alone, so it collides with neither UI-S-3 (the leading Codex item) nor
     anything else queued. `tools/slice.ps1 finish` already passes `-Quiet`
     when it exists, so this switch is the last thing that closeout wants.
   - Next after: FL-1 (`plans/now/flowers.md` Slice 1) -- by then UI-S-3 will
     have landed or dropped, clearing the `scripts/hud.gd` overlap that keeps
     FL-1 out of the lead today.

2. **[Codex] UI-S-3 -- The command tray shrinks again and stays on screen.**
   - Plan: `plans/now/ui.md` -- UI-S-3.
   - Does: makes the bee and cell `More...` controls recompute the command
     tray's rect after they collapse, and caps its height so its bottom-left
     layout never extends past the viewport.
   - Files: `scripts/hud.gd`.
   - Check: `tools/verify.ps1`. One hands-on check to file: opening and
     closing both `More...` panels restores the old height, and a full cell
     tray stays on screen at 800x600.
   - Proof: `absent: scripts/hud.gd :: _resize_command_tray`
   - Why first in this lane: UI-S-1 landed, and UI-S-3 is its stated next
     slice in `plans/now/ui.md`; it does not overlap W-7, the leading Claude
     item.
   - Next after: UI-S-2 (`plans/now/ui.md` -- left-side windows follow the
     corner readout and scroll within the viewport).

3. **[Claude] FL-1 -- The flower panel says nothing about age or season.**
   - Plan: `plans/now/flowers.md` -- Slice 1.
   - Does: `hud.gd::_refresh_flower_summary()` already rebuilds the flower
     summary panel every frame it's open and already prints both effective
     rates, but says nothing about age or season. Builds one extra line --
     age in days against lifespan, and "in season (NN%)" / "out of season" /
     "seasons off" -- and puts it in `trait_label` above the scent-mark text
     (joined with a newline, not replacing it) using `age_seconds`,
     `lifespan_seconds` and `season_strength()`, all already public on
     `flower.gd`. Nothing new is computed in `flower.gd`.
   - Files: `scripts/hud.gd`.
   - Check: `tools/verify.ps1`. One hands-on check to file: click a flower
     and the panel shows its age against its lifespan and whether it's in
     or out of season; watching one across a season boundary flips the line
     at the same moment the `+/s` figures fall away.
   - Proof: `absent: scripts/hud.gd :: season_strength`
   - Why here, not leading: it shares `scripts/hud.gd` with UI-S-3, the
     leading Codex item, so it stays second in the Claude lane rather than
     promoting to lead -- promoting it now would make both lanes' leading
     items collide. Re-check this pairing whichever of FL-1 or UI-S-3 lands
     first: landing either one clears the conflict for the other to lead.
   - Next after: FL-2 (`plans/now/flowers.md` Slice 2) -- a balance change,
     needs its named headless run before it merges.

4. **[Codex] UI-R-2 -- Pre-run menu: the left edge still needs more room.**
   - Plan: `plans/now/ui.md` -- UI-R-2.
   - Does: raises `main_menu.gd`'s `LEFT_PANE_MARGIN` from 16 to 32. One
     constant; nothing about tile size, spacing, centres or hit-testing
     changes, so UI-M and UI-P-3 cannot regress.
   - Files: `scripts/main_menu.gd`.
   - Check: `tools/verify.ps1`. One hands-on check to file: the left pane
     sits comfortably clear of the screen edge and tile clicking is
     unchanged.
   - Proof: `present: scripts/main_menu.gd :: LEFT_PANE_MARGIN := 16`
   - Next after: UI-R-3.

5. **[Codex] UI-R-3 -- No way to fire a warning-banner case on demand.**
   - Plan: `plans/now/ui.md` -- UI-R-3.
   - Does: adds a second button, "Fire test warnings", to
     `debug_panel.gd`'s existing `challenge_row` beside "Advance Challenge
     stage", styled with the same `_style_button` + `UI.with_info` pattern.
     It calls `hud.show_warning` three times off one `SceneTreeTimer`
     chain -- an epitaph-keyed message at t=0, a crab-spider-escape-keyed
     one at t=+8s and an unkeyed confirmation at t=+10s -- using the real
     `problem_messages.gd` entries and `GameConfig` gaps, not literals.
     Developer section only, so ordinary play cannot reach it.
   - Files: `scripts/debug_panel.gd`.
   - Check: `tools/verify.ps1`. It also unblocks `checks/blocked.md`'s C-4;
     move that entry to `checks/ready.md`, keeping its id, when this lands.
   - Proof: `absent: scripts/debug_panel.gd :: Fire test warnings`
   - Next after: UI-S-2.

## Ready, not yet in the queue

All of these can be started today; they are out of the queue only because it
holds five. Take one when a lane empties, in roughly this order.

- **UI-S-2** (`plans/now/ui.md`) -- the colony, foraging and nursery windows
  sit below the corner readout with a 16px buffer, scroll when they do not
  fit, and close each other.
- **UI-S-4** (`plans/now/ui.md`) -- a second right-click sometimes does
  nothing and appears to deselect the bee: instrument the command choke
  point and make a refused command say so.
- **FL-2** (`plans/now/flowers.md` Slice 2) -- out of season means a small
  non-zero rate, faster ageing and rarer seeding. A balance change: it needs
  its named headless run before it merges.
- **C2-1** (`plans/now/challenge-2.md` Slice 1) -- a debug button that forces
  a Challenge 2 nectar collapse, so C-5 can be run at all.
- **P-1** (`plans/now/check-loop.md`) -- make `checks/ready.md`'s new entry
  format (id, one action, one PASS line, an owner) enforceable in
  `tools/check_docs.py`.

## Not in the queue, and why

Each of these needs something from Dave, or something else to ship first.
They are listed so they are not lost, not so they are picked up.

- **Challenge 1 Slice 7** (`plans/now/challenge-1.md`) -- the acceptance
  playthrough. C1-15 landed 3 Sep 2026; this is now Dave's run and the last
  thing that plan needs.
- **Challenge 2 Slice 2** (`plans/now/challenge-2.md`) -- fixing whichever
  of the rescue and recovery lines does not appear. Needs C2-1 to ship and
  Dave to press the button; there is no static defect to fix blind, and
  guessing has already failed twice.
- **check-loop P-2 and P-3** (`plans/now/check-loop.md`) -- the panel-rect
  source check runs after UI-S-1 and UI-S-2 move the numbers; the shared
  developer-trigger section runs after UI-R-3 and C2-1 exist to collect.
- **Hive comb Slices 4 and 5** (`plans/now/hive-comb.md`) -- Slice 4's
  headless trace found the mechanism (every idle Comb Worker piles onto one
  unfinished site), but capping builders per site changes build throughput,
  so it needs Dave's live look and a call on intended behaviour. Slice 5
  needs its own live repro.
- **UI-P-5 and UI-D** (`plans/now/ui.md`) -- both name two plausible causes
  and say to reproduce live before changing code.
- **Save/load during an active Challenge** -- a settled design decision, not
  a defect. `DESIGN_BACKLOG.md` § "Deferred product decisions" holds it; it is
  not restated here.
- **Progression Phase A** (`plans/design/progression.md`) -- designed, not
  scheduled; parked behind the settings-catalogue work by Dave's 1 Sep call.

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
