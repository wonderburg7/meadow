# Next steps

Read this first in a new session, before anything else in CLAUDE.md. This
file holds only the next 1-3 concrete actions -- it is rewritten (not
appended to) at the end of every build session, so it should never grow
into a history. Full history lives in `git log` and the Notion Build Log.

## Next up

1. **This session's two fixes need Dave's hands-on check in Challenge 1
   and 2** -- `source_checks.py`/`balance_tests.py` pass and
   `FUNCTION_MAP.md` is regenerated, but no Godot boot was available this
   session (the `mcp__godot__*` tools were disabled), so there hasn't
   even been a parser-error check yet -- do that first next session,
   before anything else.
   - **Corner problem strip during a Challenge** (`year_winter.gd::
     _refresh_signals`): the "signals" readout ("larvae are going
     hungry", "bees running low on energy", etc.) is starred by default
     for every run and was never covered by `hud.gd`'s `warnings_muted`
     -- that flag only silences the toast banner (`show_warning`), a
     separate mechanism. It now goes blank for the length of an active
     Challenge (`main.challenge_runner.active`), on the reasoning that
     Dr Gallerin already gives stage-appropriate guidance and the generic
     strip was flagging things the tutorial hadn't unlocked a fix for yet
     (no nurses before 2.7, low energy while still learning the
     controls). Check: start Challenge 1 or 2, let a larva go hungry or a
     bee's energy drop, and confirm nothing appears in the corner: only
     Dr Gallerin's own prompts should be visible. If Dave wants specific
     ones back (or reworded to reference the current stage) rather than
     all of them gone, that's a follow-up.
   - **Backup building/mining not dropping when primary work turns up**
     (`bee.gd`): a bee whose secondary role is Comb worker or Miner used
     to only re-check its primary role at the *next* idle state --
     `BUILDING`/`MINING` can run for a whole cell or block, so with
     "Finish the job first" off it still didn't drop the backup job for
     up to that whole stretch, unlike every other manual reassignment.
     New `working_secondary` flag + `_maybe_break_off_secondary()` (see
     its doc comment) now checks on every think tick and, if off, hands
     back to the primary role immediately -- reusing the same
     `_try_role_work`/`release_builder`/`release_miner` paths a manual
     switch already goes through, so build/mine progress on the
     cell/block itself is preserved exactly as if the bee had wandered
     off mid-job (existing behaviour). Check: give a Nurse (or Forager)
     a Comb worker or Miner backup role with "Finish the job first" off,
     let it start building/mining as backup, then create primary work
     (brood to feed / a flower to visit) and confirm it breaks off within
     a second or two rather than finishing the whole cell/block first.
     Also worth confirming this is what was behind the reported deaths --
     if bees still die mid-build/mid-mine after this, the cause is
     something else (e.g. the colony genuinely out of food, not a stuck
     state).
2. **Challenge 2 (Brood, Roles and Expansion) still needs Dave's first
   hands-on playtest** -- all ten sub-stages, the 2.3+ checkpoint/rescue
   path, and the new `hud.gd` gating (cell designation, hatch-role
   picker, Nurse/Comb-worker/Miner sub-modes, soil marking) are built and
   checked, but never played. See `TUTORIAL_PLAN.md`'s Challenge 2
   section for the full checklist (stage sequence, restore-on-collapse
   behaviour, the one-time rescue firing once, nothing unlocking early,
   whether the balance overrides turn out to be needed at all).
3. **Two audit bundles still need Dave's hands-on check, same as last
   session** -- can combine with the Challenge 2 playtest:
   - **Bundle A**: start Challenge 1, reach 1.3, abandon to the main menu
     mid-build, confirm a fresh run's build time is back to normal (90s)
     and Save/Load were greyed out throughout.
   - **Bundle B**: save/load a run a few times, check population/flower
     counts don't drift, and check the queen panel's "Lay in plain comb
     too" checkbox stays in sync with the settings window's copy.

## Waiting, lower priority

- The non-fog worst-frame cost (a genuine engine/render-thread cost, not
  anything in GDScript) -- `perf.gd` has hit its ceiling on it; next step
  is Godot's own Debugger > Profiler, not more work in `perf.gd`.
- Scouting/recruitment split and bee individuality -- shipped, exercised
  incidentally, never explicitly confirmed.
- Re-measure `bee_movement.gd` with `perf.gd`.
- Depth in what exists: nurse-mediated caste switching, comb temperature,
  multi-storey comb.
- A second hive site to move to.
