# Next steps

<!-- CONTEXT: current-queue | LOAD: every session -->

Five ready slices in two lanes. The lanes never touch the same file, so Claude
and Codex can each take the top of their own lane at the same time without
disrupting each other.

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

1. **[Claude] C2 -- Warning banner: one throttle at the channel, one owner for
   the copy.**
   - Plan: `plans/now/ui.md` -- UI-Q-1 and UI-Q-2, landed together as the plan
     itself specifies.
   - Does: `show_warning(text, key, min_gap)` holds one `key -> last shown`
     dictionary in `hud.gd`, replacing three copies of the same throttle in
     three producers; and the two simulation files that write player-facing
     copy get a named entry in a definitions file instead.
   - Files: `scripts/hud.gd`, `scripts/main.gd`, `scripts/bee_survival.gd`,
     `scripts/crab_spider.gd`, `scripts/problem_messages.gd`.
   - Check: `tools/verify.ps1`. One hands-on check to file: two throttled
     events eight seconds apart no longer wipe each other, and a "Run saved."
     confirmation survives an unrelated ambient event.
   - Why now: C1 landed, so `main.gd`'s scenario hook has settled -- this
     slice edits `main.gd`'s three `last_*` warning fields against a file
     nothing else is about to move.
   - Next after: UI-P-6.

2. **[Claude] UI-P-6 -- Settings window: put the gap next to the scrollbar,
   not left over from the panel width.**
   - Plan: `plans/now/ui.md` -- UI-P-6.
   - Does: adds a row-level right margin (~6px) so every settings row's
     content sits a deliberate, consistent distance from the scroll's own
     edge with "Show info icons" both on and off, instead of inheriting
     whatever slack `PANEL_WIDTH := 320.0` leaves when badges are hidden.
     Does not re-tune `PANEL_WIDTH` -- the badge-visible case needs it.
   - Files: `scripts/debug_panel.gd`.
   - Check: `tools/verify.ps1`. One hands-on check to file: with info icons
     on and off, every row's content sits a small consistent gap from the
     scrollbar rather than a larger unexplained gap from the panel edge.
   - Why now: C1 unblocked it. `debug_panel.gd` is 777 lines of widget code
     rather than 1781 lines of widget code wrapped around a data table, so
     this slice edits the rows and nothing else.
   - Next after: nothing in `plans/now/ui.md` is ready -- UI-P-5 and UI-D both
     need Dave's live look first (see "Not in the queue"). Pull from another
     owning plan, or ask Dave which of those his next hands-on pass unblocked.

3. **[Codex] X1 -- Forager return reserve: give it a counter so it can be
   checked at all.**
   - Plan: `plans/active/foraging-evidence.md` -- Slice 3.
   - Does: add `_forager_returns_triggered` to `diagnostic_log.gd`,
     incremented inside `log_forager_return` and reset where
     `_orientation_flights`/`_recruitment_matches` are reset, then surface it
     in `foraging_panel.gd` beside those two. Mirrors an existing pattern
     exactly; no behaviour change.
   - Files: `scripts/diagnostic_log.gd`, `scripts/foraging_panel.gd`.
   - Check: `tools/verify.ps1`. One hands-on check to file: the counter reads
     zero in an ordinary meadow and rises in a sparse/long-range or rainy run.
   - Why now: the emergency-recall path currently cannot be confirmed by
     anything short of grepping a raw log, which is why its check has sat
     unresolvable in `checks/ready.md`. The counter is the unblocker, and X2
     wants the same diagnostic surface.
   - Next after: X2.

4. **[Codex] X2 -- Proximity recruitment: one long evidence run before any
   threshold is touched.**
   - Plan: `plans/active/foraging-evidence.md` -- Slice 2.
   - Does: a headless run with Proximity recruitment on, reading
     `_recruitment_matches` and the `dance_eligible_mentors`/`_seekers` list
     sizes periodically from the diagnostic snapshot. Empty lists mean a
     threshold question; populated lists that never overlap mean a
     spatial/timing one. Record the answer in the plan; change no threshold
     in this slice.
   - Files: `test_scenarios/` (new fixture), `scripts/diagnostic_log.gd` (only
     if the snapshot needs the list sizes added),
     `plans/active/foraging-evidence.md`.
   - Check: the run's own trace is the evidence. No hands-on check.
   - Why after X1: same file, same lane, and X1 establishes the counter
     surface this run reads from.
   - Next after: X3.

5. **[Codex] X3 -- Buttons that read as buttons at rest, game-wide.**
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
   - Why last in this lane: purely cosmetic, and the only Codex item needing a
     hands-on confirm afterwards, so it should not hold up the evidence work.
   - Next after: this lane is empty -- pull the top of `plans/now/ui.md` or ask
     Dave which of the "Not in the queue" items his next live look unblocked.

## Not in the queue, and why

Each of these needs something from Dave before code can be written. They are
listed so they are not lost, not so they are picked up.

- **Challenge 1 Slice 7** (`plans/now/challenge-1.md`) -- an acceptance
  playthrough. Every code slice in that plan has shipped; what remains is
  Dave's hands-on pass over `checks/ready.md`'s Bundle D/E and Slice 9 entries.
- **Hive comb Slices 4 and 5** (`plans/now/hive-comb.md`) -- Slice 4's headless
  trace has found the mechanism (every idle Comb Worker piles onto one
  unfinished site), but capping builders per site changes build throughput, so
  it needs Dave's live look and a call on intended behaviour. Slice 5 needs its
  own live repro.
- **UI-P-5 and UI-D** (`plans/now/ui.md`) -- both name two plausible causes and
  say to reproduce live before changing code.
- **Save/load during an active Challenge** (`DESIGN_BACKLOG.md`) -- `SaveGame`
  has no Challenge stage/gate/prompt schema. A separate high-risk design task.
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
