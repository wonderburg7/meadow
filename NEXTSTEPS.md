# Next steps

<!-- CONTEXT: current-queue | LOAD: every session -->

Five ready slices in two lanes, rewritten 2 Sep 2026 from Dave's hands-on
batch. That pass confirmed fifteen checks and produced eight implementable
findings, so both lanes are full again and three more ready slices are
waiting in their owning plans (`Next after:` says which).

**Everything in this file can be started right now.** Nothing here is waiting
on a hands-on check, a live repro, or a decision from Dave. Work that *is*
waiting is listed under "Not in the queue" at the bottom, with a pointer, and
is deliberately not mixed in above.

**"Implement the next slice" means:** take the first unclaimed item in your
lane, open only the `Plan:` file and heading it names, add your row to
`plans/workstreams.md`, branch, implement, run `tools/verify.ps1`, and close
with the end-of-slice report (`CLAUDE.md`, "End-of-slice report"). Do not read
the other lane's plan, the archive, `ROADMAP.md` or Git history to work out
what to do -- this file already decided.

## Next up

1. **[Claude] C1-11 -- Challenge 1's manual-forage stages: three unguarded
   autonomous transitions.**
   - Plan: `plans/now/challenge-1.md` -- Slice 11.
   - Does: stops the queen foraging on her own through stages 1.6-1.10.
     `finish_collecting`'s part-load branch sends her to the next flower,
     the deposit-completion branch sends her back out of the hive, and
     `command_deposit_at` clears the flag that should have stopped both.
     One guard each, all three traced to a line in the plan. Also unblocks
     the 1.10 -> 1.11 hand-over, which currently ends the Challenge: the
     missing Forager option is a consequence of the queen already foraging,
     not a separate bug.
   - Files: `scripts/bee_foraging.gd`, `scripts/bee.gd`,
     `plans/now/challenge-1.md`.
   - Check: `tools/verify.ps1`, then the Slice 11 acceptance already written
     into the Bundle D entry of the player-check list.
   - Why first: it is the only item in the batch that blocks a whole
     Challenge from being finished.
   - Next after: C1-12.

2. **[Codex] X3 -- Buttons that read as buttons at rest, game-wide.**
   - Plan: `plans/now/ui.md` -- UI-P-2.
   - Does: raise `ui_theme.gd::_refresh_button_stylebox()`'s `"normal"` state
     from `base.lightened(0.10)` toward 0.16-0.18 and/or give it a low-alpha
     border, so "Change to..." and "When idle:" (and every other command-panel
     button) show a background at rest. One shared value, not a per-menu
     override.
   - Files: `scripts/ui_theme.gd`.
   - Check: `tools/verify.ps1`. One hands-on check to file: ordinary buttons
     read as buttons at rest, and `mark_as_current` buttons still read as
     clearly more prominent.
   - Why first in this lane: it was already at the head of the queue and
     shares no file with anything in the Claude lane.
   - Next after: UI-R-2.

3. **[Claude] UI-R-1 -- The command tray sits off-centre, overhangs the
   screen and covers Dr Gallerin's bubble.**
   - Plan: `plans/now/ui.md` -- UI-R-1.
   - Does: the tray is anchored `PRESET_CENTER_BOTTOM`, i.e. centred on the
     viewport, while its two reserves are unequal (390 left, 544 right). The
     plan works the arithmetic: it lands 77px right of the band's true
     centre, and the `0.924` fudge factor only claws back half of that.
     Replaces the factor with an explicit left edge and a named side gap in
     `ui_layout.gd`, and anchors the tray to it.
   - Files: `scripts/ui_layout.gd`, `scripts/hud.gd`.
   - Check: `tools/verify.ps1`. One hands-on check to file: fully on screen
     at 1920/1280/800, one gap from the summary panel, never inside
     Gallerin's reserve, and UI-P-8's wrap behaviour intact.
   - Next after: HC-8.

4. **[Codex] UI-R-2 -- Pre-run menu: the left edge still needs more room.**
   - Plan: `plans/now/ui.md` -- UI-R-2.
   - Does: raises `main_menu.gd`'s `LEFT_PANE_MARGIN` from 16 to 32. One
     constant; nothing about tile size, spacing, centres or hit-testing
     changes, so UI-M and UI-P-3 cannot regress.
   - Files: `scripts/main_menu.gd`.
   - Check: `tools/verify.ps1`. One hands-on check to file: the left pane
     sits comfortably clear of the screen edge and tile clicking is
     unchanged.
   - Next after: UI-R-3.

5. **[Claude] HC-8 -- Cell highlight borders do not follow the cell
   sprite's silhouette.**
   - Plan: `plans/now/hive-comb.md` -- Slice 8.
   - Does: `hive_cell.gd` builds five outlines and only `selection_ring`
     knows about the cup sprite's raised back wall; the base outline, the
     designation ring and the nursery zone glow/halo still trace the flat
     hex and cut through it. Routes all five through one helper that makes
     the silhouette decision once.
   - Files: `scripts/hive_cell.gd`.
   - Check: `tools/verify.ps1`. One hands-on check to file: all four rings
     follow the cup with Cell art on, and revert instantly when it is off.
   - Next after: this lane then pulls from `plans/now/challenge-1.md`
     (C1-12/C1-13), `plans/active/foraging-evidence.md` (Slice 4) or
     `plans/now/settings-persistence.md` (Slice 1) -- all three are ready.

## Ready, not yet in the queue

These pass the admission test and are only out because the queue holds five.
Promote from here when a lane empties; no extra decision is needed.

- **C1-12** (`plans/now/challenge-1.md` Slice 12) -- one `player_driven`
  flag owned by stage data, one choke point in `bee_foraging.gd`, and a
  `source_checks.py` rule so the next unguarded transition fails the build
  instead of being found by playing. Do it after C1-11.
- **C1-13** (`plans/now/challenge-1.md` Slice 13) -- the queen's "Now:" line
  names mechanics Challenge 1 has not taught yet.
- **FE-4** (`plans/active/foraging-evidence.md` Slice 4) -- a settings
  toggle that rings the two bees in a recruitment dance, so a match can
  actually be seen happening. Follows `search_ring`'s existing pattern.
- **SP-1** (`plans/now/settings-persistence.md` Slice 1) -- picking a
  Scenario resets only the keys a preset owns, instead of wiping every
  `GameConfig` field including the ones the player set by hand.
- **UI-R-3** (`plans/now/ui.md` UI-R-3) -- a debug-panel button that fires
  named warning-banner cases, so the banner arbitration check can be run at
  all.

## Not in the queue, and why

Each of these needs something from Dave before code can be written. They are
listed so they are not lost, not so they are picked up.

- **Challenge 1 Slice 7** (`plans/now/challenge-1.md`) -- an acceptance
  playthrough, and it cannot start until C1-11 lands; the 2 Sep attempt
  stopped at stage 1.10.
- **Hive comb Slices 4 and 5** (`plans/now/hive-comb.md`) -- Slice 4's
  headless trace has found the mechanism (every idle Comb Worker piles onto
  one unfinished site), but capping builders per site changes build
  throughput, so it needs Dave's live look and a call on intended behaviour.
  Slice 5 needs its own live repro.
- **UI-P-5 and UI-D** (`plans/now/ui.md`) -- both name two plausible causes
  and say to reproduce live before changing code.
- **Save/load during an active Challenge** (`DESIGN_BACKLOG.md`) -- `SaveGame`
  has no Challenge stage/gate/prompt schema, which is why save and load are
  greyed out for the length of Challenge 2. Confirmed working as built on
  2 Sep; changing it is a separate high-risk design task.
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
in the Next up queue. Follow its Plan heading only. Branch as codex/<slice-id>,
run tools/verify.ps1, commit, and finish with the hand-off block in CHATGPT.md.
```

Claude, integrating a finished Codex branch:

```
Integrate the finished Codex branch and close it out.
```

Claude, when Dave has done a hands-on pass:

```
I've done a hands-on pass. Here's what I found: <notes>. Update the checks,
plans and queue.
```
