# Next steps

<!-- CONTEXT: current-queue | LOAD: every session -->

Five ready slices in two lanes, refilled 3 Sep 2026 after UI-R-3 landed and
`plans/now/check-loop.md` P-2 came unblocked (UI-S-1 and UI-S-2, the last
things it needed, both shipped 3 Sep 2026). C2-1 is now the only queued
`debug_panel.gd` slice.

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
   - Next after: FL-2, already fifth in this lane.

2. **[Claude] FL-1 -- The flower panel says nothing about age or season.**
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
   - Why first in this lane: UI-R-3, which led before it, shipped 3 Sep
     2026. Nothing else in the queue names `scripts/hud.gd`, and the Codex
     lane leads with `main_menu.gd`, so the two heads cannot collide.
   - Next after: C2-1, next in this lane.

3. **[Claude] C2-1 -- A Challenge 2 nectar collapse cannot be made to happen.**
   - Plan: `plans/now/challenge-2.md` -- Slice 1.
   - Does: adds a "Force Challenge 2 collapse" button to the Triggers group
     P-3 built, styled with the same `_style_button` + `UI.with_info` pattern
     as its neighbours. One press withdraws nectar until the hive sits just
     below `Stages.C2_RESCUE_THRESHOLD`; a second press takes it below
     `Stages.C2_FAILURE_FLOOR`, so both branches of
     `challenge_runner.gd::_check_c2_failure()` can be reached in order from
     one run. Thresholds are read from `challenge_stages.gd`, never repeated.
     It does nothing unless `Session.starting_level == 2` and the runner is
     active, which the info badge says.
   - Files: `scripts/debug_panel.gd`.
   - Check: `tools/verify.ps1`. One hands-on check to file: the plan's
     acceptance, replacing `checks/ready.md`'s "Challenge data/goal-registry
     extraction" entry.
   - Proof: `absent: scripts/debug_panel.gd :: Force Challenge 2 collapse`
   - Why here, not leading: FL-1 above it has no conflicting file, and this
     queue position is unchanged from before UI-R-3 shipped.
   - Next after: `plans/now/challenge-2.md` Slice 2, once Dave has pressed
     the button and reported which line is missing (not yet ready --
     check-loop P-2 fills this lane's third slot instead).

4. **[Claude] check-loop P-2 -- one owner for panel rectangles, enforced.**
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

5. **[Codex] FL-2 -- Out of season means "barely", not "not at all".**
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
   - Why here: it has no dependency on FL-1 and shares no file with the
     current Claude work; the plan makes its required headless comparison
     explicit before merge.
   - Next after: none -- this plan then has no open slice.

## Ready, not yet in the queue

Nothing. Every slice that could be started today is in the queue above; the
next lane to empty pulls its refill from an owning plan's next open slice.

## Not in the queue, and why

Each of these needs something from Dave, or something else to ship first.
They are listed so they are not lost, not so they are picked up.

- **Challenge 1 Slice 7** (`plans/now/challenge-1.md`) -- the acceptance
  playthrough. C1-15 landed 3 Sep 2026; this is now Dave's run and the last
  thing that plan needs.
- **Challenge 2 Slice 2** (`plans/now/challenge-2.md`) -- fixing whichever
  of the rescue and recovery lines does not appear. Needs C2-1 (third in the
  queue, second in the Claude lane) to ship and Dave to press the button;
  there is no static defect to fix blind, and guessing has already failed
  twice.
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
