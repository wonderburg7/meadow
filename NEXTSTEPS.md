# Next steps

<!-- CONTEXT: current-queue | LOAD: every session -->

Five ready slices in two lanes, rewritten 3 Sep 2026 after UI-R-1 landed.
UI-R-1 replaced the command tray's centred anchor and `0.924` fudge factor
with an explicit left edge, so the Claude lane now leads with HC-8 and FE-4
has been promoted from the ready list to fill the gap.

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

1. **[Claude] HC-8 -- Cell highlight borders do not follow the cell
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
   - Why first: UI-R-1 landed ahead of it in this lane, and it shares no
     file with X3.
   - Next after: C1-13.

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

3. **[Claude] C1-13 -- The queen's "Now:" line says things Challenge 1 has
   not taught.**
   - Plan: `plans/now/challenge-1.md` -- Slice 13.
   - Does: `bee.gd::task_description()` and `idle_reason()` are one large
     `match state:` covering every state in the game -- scouting bouts,
     entrance mentoring, royal jelly, honey fanning -- so a Challenge-1
     player is shown vocabulary for mechanics the Challenge has deliberately
     not reached. Adds `challenge_vocabulary_limited()` and falls back to one
     neutral line outside the permitted set; also suppresses
     `_idle_backup_note()` while `role_restricted_to` is non-empty.
   - Files: `scripts/bee.gd`.
   - Check: `tools/verify.ps1`. One hands-on check to file: read the "Now:"
     line at every stage to 1.14 with the queen selected, and confirm a
     Scenario scout still reads "scouting: bout 1 of 3...".
   - Why here: it is the last Challenge 1 code slice before Slice 7's
     acceptance pass, which is Dave's to run.
   - Next after: FE-4.

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

5. **[Claude] FE-4 -- A recruitment dance is happening and cannot be found
   on screen.**
   - Plan: `plans/active/foraging-evidence.md` -- Slice 4.
   - Does: adds a `Session` preference `show_recruitment_highlight` (a
     presentation key, not a `GameConfig` one) with an Appearance row in
     `settings_catalogue.gd`, plus a fifth `dance_ring` on `bee.gd` at
     `outline_radius + 17.0` and an `_update_dance_ring()` modelled line for
     line on the existing `_update_search_ring()`. Mentor and seeker get
     different colours so the pair reads as a pair.
   - Files: `scripts/bee.gd`, `scripts/settings_catalogue.gd`.
   - Check: `tools/verify.ps1`. The hands-on check is already filed and
     waiting under `checks/ready.md` § Proximity recruitment (Slice 9).
   - Why here: promoted from the ready list when UI-R-1 landed. It shares
     `bee.gd` with C1-13, which is fine -- both are in this lane, so they
     are worked one after the other, never at once.
   - Next after: this lane then pulls SP-1
     (`plans/now/settings-persistence.md` Slice 1), which is ready.

## Ready, not yet in the queue

These pass the admission test and are only out because the queue holds five.
Promote from here when a lane empties; no extra decision is needed.

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
  playthrough. C1-11 removed what stopped the 2 Sep attempt at stage 1.10
  and C1-12 made that class of bug fail the build instead, so this now needs
  only Dave's run: `checks/ready.md` Bundles D and E are the two entries to
  work through. C1-13 is the one code slice still ahead of it.
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
