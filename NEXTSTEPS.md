# Next steps

<!-- CONTEXT: current-queue | LOAD: every session -->

Five ready slices in two lanes, refilled 3 Sep 2026 after UI-S-2 landed and
W-7's closeout exposed two defects in `tools/slice.ps1 finish` (S-1).

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

1. **[Claude] S-1 -- `slice.ps1 finish` dies on the worktree it deletes.**
   - Plan: `plans/now/slice-tooling.md` -- S-1.
   - Does: `Invoke-SliceFinish` runs its merge/cleanup block under
     `Push-Location $root`, so the worktree it is about to delete is what sits
     on the location stack, and the `finally`'s `Pop-Location` throws once
     that directory is gone -- exiting 1 after a wholly successful merge, push
     and branch delete. Replaces that pair with `Set-Location -LiteralPath
     $root`. Instrumenting the block also showed the ledger row filter never
     matches: a backtick is the escape character in a PowerShell wildcard, so
     `"*``$worktreeRelative``*"` asks `-like` for a literal asterisk, nothing
     is removed, and the ledger `git commit` then exits 1 on "nothing to
     commit" -- the exception `Pop-Location` was masking. Swaps that filter
     for an ordinal substring match and lets an already-clean ledger pass.
   - Files: `tools/slice.ps1`.
   - Check: `tools/verify.ps1`, plus an end-to-end rehearsal in a throwaway
     repo (bare remote, primary checkout, one worktree) that must exit 0 with
     the ledger row gone. No hands-on check: `finish` is agent-run closeout
     tooling with no player-visible surface.
   - Proof: `present: tools/slice.ps1 :: $_ -notlike`
   - Why first: it breaks the tail of every closeout in both lanes and leaves
     a stale `plans/workstreams.md` row that fails `check_docs.py` on master,
     so every landing needs a hand repair until it is fixed. It owns
     `tools/slice.ps1`, which no other queued item names.
   - Next after: P-1, already second in this lane.

2. **[Codex] UI-S-4 -- A refused command says so, at one instrumented choke point.**
   - Plan: `plans/now/ui.md` -- UI-S-4.
   - Does: instruments every right-click command issue, shows a throttled
     warning instead of silently refusing a command, and removes invalid
     selections rather than making them appear to vanish.
   - Files: `scripts/input_selection.gd`, `scripts/diagnostic_log.gd`,
     `scripts/hud.gd`.
   - Check: `tools/verify.ps1`. One hands-on check to file: reproduce the
     double right-click, then send the run's diagnostic log so its cause is
     pinned to one branch rather than guessed.
   - Proof: `absent: scripts/input_selection.gd :: DiagnosticLog`
   - Why first in this lane: UI-S-2 landed and explicitly promotes it. It does
     not overlap P-1, the leading Claude item.
   - Next after: UI-R-2, already fourth in this lane.

3. **[Claude] P-1 -- the check format is a convention, not a check.**
   - Plan: `plans/now/check-loop.md` -- P-1.
   - Does: adds a `check_checks()` function to `tools/check_docs.py`, in the
     style of `check_next_steps()`, that reads `checks/ready.md` and
     `checks/blocked.md` and fails when an entry heading does not start with
     an id matching `C-<n> -- `, when an entry has no line beginning `PASS:`,
     when it has no `Owner:` line naming a plan file that exists, or when two
     entries share an id. It skips each file's header block -- everything
     before the first `### ` -- and reuses the existing Markdown-link/path
     resolution. Nothing outside the checker changes.
   - Files: `tools/check_docs.py`, `checks/ready.md`, `checks/blocked.md`.
   - Check: `tools/verify.ps1`, including a deliberate break and repair -- an
     entry added without an id, or without a `PASS:` line, must fail with a
     readable message, and both files as they stand today must pass. No
     hands-on check: the whole slice is a checker and its own fixtures.
   - Proof: `absent: tools/check_docs.py :: check_checks`
   - Why here, not leading: S-1 breaks the tail of every closeout in both
     lanes, so it takes the head of this lane. P-1 owns three files no other
     queued item names and leads this lane the moment S-1 lands.
   - Next after: FL-1, first under "Ready, not yet in the queue" -- it
     re-enters this lane as soon as S-1 or P-1 frees the slot.

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
   - Next after: UI-S-4.

## Ready, not yet in the queue

All of these can be started today; they are out of the queue only because it
holds five. Take one when a lane empties, in roughly this order.

- **UI-S-4** (`plans/now/ui.md`) -- a second right-click sometimes does
  nothing and appears to deselect the bee: instrument the command choke
  point and make a refused command say so.
- **FL-1** (`plans/now/flowers.md` Slice 1) -- the flower panel says nothing
  about age or season: `hud.gd::_refresh_flower_summary()` gains one line
  giving age against lifespan and in/out of season, built from `age_seconds`,
  `lifespan_seconds` and `season_strength()`, all already public on
  `flower.gd`. Out of the queue only because S-1 took the slot.
- **FL-2** (`plans/now/flowers.md` Slice 2) -- out of season means a small
  non-zero rate, faster ageing and rarer seeding. A balance change: it needs
  its named headless run before it merges.
- **C2-1** (`plans/now/challenge-2.md` Slice 1) -- a debug button that forces
  a Challenge 2 nectar collapse, so C-5 can be run at all.

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
