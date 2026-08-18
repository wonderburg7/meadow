# Next steps

Read this first in a new session, before anything else in CLAUDE.md. This
file holds only the next 1-3 concrete actions -- it is rewritten (not
appended to) at the end of every build session, so it should never grow
into a history. Full history lives in `git log` and the Notion Build Log.

## Next up

1. **Challenge 1 needs Dave's hands-on check in Godot, after a second
   round of bug fixes landed 19 Aug.** The first playtest surfaced seven
   real problems; all seven are fixed, but none re-confirmed by an actual
   playthrough yet. See `TUTORIAL_PLAN.md`'s "Built and playable, 19 Aug
   2026" note under "Challenge 1: First Stores" for the full list with
   the reasoning behind each fix. Specifically worth eyeballing:
   - The camera opens centred on the queen at the hive entrance, not
     wherever the default hive-view framing used to put it.
   - Assigning the queen Forager defaults her to nectar, not pollen.
   - Right-clicking a flower with any bee selected sends it collecting
     from that flower (switching it to Forager first if needed); right-
     clicking the doorway sends a selected indoor bee straight out to
     the meadow. Both are new general mechanics, not Challenge-1-only.
   - Building the one cell in 1.3 (via the queen's new "Build cell"
     button) should produce exactly one cell, not a scatter of
     unfinished ones around it, and comb workers now stand beside a
     cell while building it rather than on top of it.
   - A full nectar-then-pollen run should reach 1.7 and actually show
     the "Challenge complete" message -- this was reported as not
     happening, and the most likely cause (a deposit bug that silently
     destroyed a forager's load before it ever counted toward the
     stage's target) is fixed, but wants confirming end to end.
   - Small polish: a short ripple appears wherever a right-click command
     lands, and a goal readout under the settings cog names the current
     sub-stage's goal in plain language.
2. **Challenge 2 (Brood, Roles and Expansion) has no stage data yet.**
   The menu entry and `LEVELS[2]` starting-state preset exist
   (`levels.gd`); none of its ten sub-stages, failure conditions or
   Dr Gallerin prompts are written. `challenge_runner.gd`'s `STAGES`
   array is Challenge 1 only so far -- see its own header comment for
   why stage data lives there rather than in `levels.gd`. This is
   naturally the next slice once (1) is confirmed, since it's the
   first thing that will actually exercise `tutorial_checkpoint.gd`'s
   restore path (Challenge 1 has no failure condition to trigger it;
   Challenge 2's does, from sub-stage 2.3 onward per the plan).
3. **The balance overrides `TUTORIAL_PLAN.md` describes for Challenge 1's
   start state are still not applied** -- no rain, no rival colony, no
   winter, no disease are all just "not yet true" rather than switched
   off. Hasn't caused a visible problem in testing (a 5-10 minute
   Challenge doesn't run long enough to hit most of them), but it's a
   known gap against the written design, worth closing before trusting
   Challenge 1 is really "no lethal pressure" rather than "usually fine."

## Waiting, lower priority

- **Scouting/recruitment split, bee individuality, and fog of war** --
  all three shipped in earlier sessions (18-19 Aug) and were last known
  to need Dave's hands-on check; none has had a specific correction
  request since, but none has had an explicit "confirmed working" either
  -- they've only been exercised incidentally while playtesting the
  tutorial. Worth a deliberate look whenever there's a session not
  focused on the tutorial.
- **Re-measure `bee_movement.gd` with `perf.gd`** -- still on the list.
  See "Measuring performance, not guessing at it" in CLAUDE.md before
  touching it -- wrap the widest scope first.
- Depth in what exists: nurse-mediated caste switching, comb temperature,
  multi-storey comb.
- A second hive site to move to.

## Last verified

- `python3 tests/source_checks.py` and `python3 tests/balance_tests.py`
  both passing as of 19 Aug.
- Every script in `scripts/` also checked with `gdlint`/`gdparse`
  (`gdtoolkit`, pip-installed locally, not a project dependency) and
  with an actual Godot 4.7.1 boot via the `mcp__godot__*` tools now
  available in-session -- both catch real parser/type errors that
  `source_checks.py` alone can't (it only checks names/brackets, not
  scope or type inference). Two real bugs were caught and fixed this
  way before reaching Dave: a leftover cross-scope reference in
  `hud.gd`, and a `:=` type-inference failure on a loosely-typed `main.X`
  reference in `input_selection.gd` -- see `bee_survival.gd`'s
  `_announce_death` pattern (`main.DeathMarker.new()`, plain `=`) for
  why that class of assignment has to skip `:=`.
