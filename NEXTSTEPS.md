# Next steps

<!-- CONTEXT: current-queue | LOAD: every session -->

Five ready slices in two lanes, rewritten 3 Sep 2026 after C1-13 landed.
C1-13 was the last Challenge 1 code slice, so that plan now has only Slice
7's acceptance playthrough left, which is Dave's run rather than a queue
item. The Claude lane moves on to FE-4, and UI-R-3 has been promoted from
the ready list to fill the gap.

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

1. **[Claude] FE-4 -- A recruitment dance is happening and cannot be found
   on screen.**
   - Plan: `plans/active/foraging-evidence.md` -- Slice 4.
   - Does: adds a `Session` preference `show_recruitment_highlight` (a
     presentation key, not a `GameConfig` one) with an Appearance row in
     `settings_catalogue.gd`, plus a fifth `dance_ring` on `bee.gd` at
     `outline_radius + 17.0` and an `_update_dance_ring()` modelled line for
     line on the existing `_update_search_ring()`. Mentor and seeker get
     different colours so the pair reads as a pair.
   - Files: `scripts/bee.gd`, `scripts/settings_catalogue.gd`.
   - Check: `tools/verify.ps1`. The hands-on check is already filed under
     `checks/ready.md` § Proximity recruitment (Slice 9).
   - Why first: C1-13 landed ahead of it in this lane and touched the same
     file, so this is the next one to take. It shares no file with X3.
   - Next after: SP-1.

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

3. **[Claude] SP-1 -- Picking a Scenario wipes settings the player set by
   hand.**
   - Plan: `plans/now/settings-persistence.md` -- Slice 1.
   - Does: `main.gd::_on_scenario_chosen` calls
     `SettingsCatalogue.reset_config_to_defaults()`, which writes the default
     back over every `GameConfig` field -- including toggles the player set
     themselves. Records the key set each `ScenarioPresets.apply()` wrote,
     adds `reset_config_keys()` beside the full reset, and resets only the
     union of the outgoing preset's keys and the incoming one's.
   - Files: `scripts/main.gd`, `scripts/scenario_presets.gd`,
     `scripts/settings_catalogue.gd`.
   - Check: `tools/verify.ps1`. One hands-on check to file: a hand-set
     flower/season toggle survives picking a Scenario, and preset A's values
     do not leak into preset B's run.
   - Why here: it shares `settings_catalogue.gd` with FE-4, which is fine --
     both are in this lane and are worked one after the other, never at once.
   - Next after: none -- that plan is one slice unless its acceptance run
     finds more. This lane then pulls the next ready slice from an owning
     plan.

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
   - Check: `tools/verify.ps1`. It also unblocks `checks/blocked.md`'s
     banner-arbitration entry, which names this slice as its unblocker;
     move that entry to `checks/ready.md` when this lands.
   - Why here: promoted from the ready list when C1-13 landed. It shares no
     file with anything else in the queue.
   - Next after: none in this plan's UI-R group -- the lane then pulls from
     `plans/now/ui.md`'s remaining items or another owning plan.

## Ready, not yet in the queue

Empty as of 3 Sep 2026: UI-R-3 was the last item here and has been promoted
into the queue. Everything else in the owning plans is listed below instead.

## Not in the queue, and why

Each of these needs something from Dave before code can be written. They are
listed so they are not lost, not so they are picked up.

- **Challenge 1 Slice 7** (`plans/now/challenge-1.md`) -- an acceptance
  playthrough, and with C1-13 landed on 3 Sep it is all that plan has left.
  C1-11 removed what stopped the 2 Sep attempt at stage 1.10, C1-12 made
  that class of bug fail the build instead, and C1-13 stopped the queen's
  "Now:" line naming mechanics the Challenge has not taught. It now needs
  only Dave's run: `checks/ready.md` Bundles D and E, plus the new
  selection-panel vocabulary entry, are the three to work through.
- **Hive comb Slices 4 and 5** (`plans/now/hive-comb.md`) -- with HC-8
  landed these are all that plan has left, and neither is startable. Slice
  4's headless trace has found the mechanism (every idle Comb Worker piles
  onto one unfinished site), but capping builders per site changes build
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
