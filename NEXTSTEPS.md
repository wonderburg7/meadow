# Next steps

<!-- CONTEXT: current-queue | LOAD: every session -->

Four ready slices in two lanes. C2-1 shipped 3 Sep 2026; its own successor
(Challenge 2 Slice 2) needs Dave's hands-on pass first, so the fourth slot is
now filled by Colony Diagnostics' first vertical slice
(`plans/design/colony-diagnostics.md` § 4) instead, which that plan's own
Status line names as ready the moment a Claude-lane slot is free. Every other
open plan (`ui.md`, `challenge-1.md`, `check-loop.md`, `hive-comb.md`,
`flowers.md`, `progression.md`) was checked and has nothing else genuinely
startable today -- everything else needs a hands-on check, a live repro or a
product decision, which is exactly what does not belong in this list.
`tools/check_docs.py`'s queue-size check accepts four or five items (Dave, 3
Sep 2026); the fifth slot refills the moment a plan below has real ready work
again.

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

1. **[Codex] UI-R-2 -- Pre-run menu: the left edge still needs more room.**
   - Plan: `plans/now/ui.md` -- UI-R-2.
   - Does: raises `main_menu.gd`'s `LEFT_PANE_MARGIN` from 16 to 32. One
     constant; nothing about tile size, spacing, centres or hit-testing
     changes, so UI-M and UI-P-3 cannot regress.
   - Files: `scripts/main_menu.gd`.
   - Check: `tools/verify.ps1`. One hands-on check to file: the left pane
     sits comfortably clear of the screen edge and tile clicking is
     unchanged.
   - Proof: `present: scripts/main_menu.gd :: LEFT_PANE_MARGIN := 16`
   - Next after: FL-2, already fourth in this lane.

2. **[Claude] CD-1 -- One computation, not three, for the diagnostics
   the HUD already shows.**
   - Plan: `plans/design/colony-diagnostics.md` -- § 4, First vertical slice.
   - Does: adds `colony_diagnostics.gd::compute(main, bees) -> Dictionary`,
     moving the per-bee loop and the two `cells_holding(...)` walks
     currently inline in `year_winter.gd::_refresh_signals` into one
     function. `_refresh_signals` calls it once and reads the same key
     names from the returned dict instead of its local variables;
     `_refresh_panels` and `_winter_forecast()` take the dict (or its
     `bees_count`) as a parameter instead of recomputing or re-fetching it.
     `_sample_history()`'s separate cadence is untouched. No behaviour
     change -- same values, computed once per signal-tick instead of two or
     three times.
   - Files: `scripts/colony_diagnostics.gd` (new), `scripts/year_winter.gd`.
   - Check: `tools/verify.ps1`. No hands-on check: the acceptance is that
     the problem-strip lines, Colony/Nursery panel readouts and winter
     forecast show identical values before and after, for the same
     save/seed -- nothing about what the player sees is meant to change.
   - Proof: `absent: scripts/year_winter.gd :: ColonyDiagnostics`
   - Why here: C2-1, which led this lane, shipped 3 Sep 2026; its successor
     is not yet startable (see "Not in the queue" below), so this plan's own
     Status line (ready "once a Claude-lane slot is free") fills the gap
     instead.
   - Next after: none yet named -- read `plans/design/colony-diagnostics.md`
     § 5-7 to pick the next fact once this lands.

3. **[Claude] check-loop P-2 -- one owner for panel rectangles, enforced.**
   - Plan: `plans/now/check-loop.md` -- P-2.
   - Does: adds a check to `tests/source_checks.py`, in the style of the
     existing `GameConfig` write allowlist, that fails on any numeric
     literal assigned to `offset_top`/`offset_left`/`offset_right`/
     `offset_bottom` in `hud.gd`, `colony_panel.gd`, `foraging_panel.gd`,
     `nursery_panel.gd`, `gallerin_panel.gd` or `debug_panel.gd`. A trailing
     `# fixed-inset` comment or a value read from `UiLayout` is allowed; the
     message names the file, line and `ui_layout.gd` as where the number
     belongs.
   - Files: `tests/source_checks.py`.
   - Check: `tools/verify.ps1`, including a deliberate break (a literal
     `offset_top = 60` in `colony_panel.gd`) and repair.
   - Proof: `absent: tests/source_checks.py :: fixed-inset`
   - Why here: UI-S-1 and UI-S-2, the panel-rect moves this check locks in,
     both shipped 3 Sep 2026, so the plan's last open slice is now startable.
     `tests/source_checks.py` collides with no other queued file.
   - Next after: none -- this plan then has no open slice.

4. **[Codex] FL-2 -- Out of season means "barely", not "not at all".**
   - Plan: `plans/now/flowers.md` -- Slice 2.
   - Does: gives out-of-season flowers a small recharge floor, faster ageing
     and rarer seeding, using three explicit `GameConfig` balance values.
   - Files: `scripts/game_config.gd`, `scripts/flower.gd`,
     `scripts/flower_species.gd`.
   - Check: `tools/verify.ps1`, plus baseline and branch runs of
     `test_scenarios/slice8_senescence_on_seed12345_test.json` as specified
     in the plan. One hands-on check to file: the year-round species mix
     visibly follows the seasons without collapsing.
   - Proof: `absent: scripts/game_config.gd :: out_of_season_strength`
   - Why here: it shares no file with the current Claude work; the plan
     makes its required headless comparison explicit before merge.
   - Next after: none -- this plan then has no open slice.

## Ready, not yet in the queue

Nothing. Every slice that could be started today is in the queue above,
which is why the queue sits at four rather than five (see the note at the
top of this file). The next lane to empty, or the fifth slot whenever a
plan below gets real ready work, pulls from an owning plan's next open
slice.

## Not in the queue, and why

Each of these needs something from Dave, or something else to ship first.
They are listed so they are not lost, not so they are picked up.

- **Challenge 1 Slice 7** (`plans/now/challenge-1.md`) -- the acceptance
  playthrough. C1-15 landed 3 Sep 2026; this is now Dave's run and the last
  thing that plan needs.
- **Challenge 2 Slice 2** (`plans/now/challenge-2.md`) -- fixing whichever
  of the rescue and recovery lines does not appear. C2-1 shipped 3 Sep 2026
  (its "Force Challenge 2 collapse" trigger is `checks/ready.md` C-5); this
  now needs Dave to press it and report which line is missing. There is no
  static defect to fix blind, and guessing has already failed twice.
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
