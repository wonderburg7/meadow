# Next steps

Read this first in a new session, before anything else in CLAUDE.md. This
file holds only the next 1-3 concrete actions -- it is rewritten (not
appended to) at the end of every build session, so it should never grow
into a history. Full history lives in `git log` and the Notion Build Log.

## Next up

1. **Challenge 1 needs Dave's hands-on check in Godot** -- two things now
   need confirming in the same playthrough:
   - The second round of tutorial bug fixes (19 Aug): see
     `TUTORIAL_PLAN.md`'s "Built and playable, 19 Aug 2026" note for the
     full list (camera framing, queen forager default, right-click
     commands, the 1.3 build-cell flow, the 1.7 completion message, the
     right-click ripple and goal readout).
   - `AUDIT_PLAN.md` Bundle A (Challenge state safety), just landed: the
     tutorial's fast build time no longer writes into the `GameConfig`
     autoload (it's scoped to the one cell via
     `HiveCell.build_time_override`); the settings window's Save/Load
     buttons grey out for the length of an active Challenge; and
     `tutorial_checkpoint.gd`'s rolling checkpoint is now cleared on
     every scene reload. Worth specifically: start Challenge 1, reach
     1.3, abandon to the main menu partway through the fast build, and
     confirm building a cell in a fresh run afterwards takes the normal
     90s (not 15s) and that Save/Load were greyed out the whole time.
     `python3 tests/source_checks.py`/`balance_tests.py` and a Godot
     boot via `mcp__godot__run_project` both came back clean, but
     nothing here substitutes for Dave actually playing it.
2. **`AUDIT_PLAN.md` Bundle B is next in the audit plan** (P1,
   deterministic restore + machine-checked guardrails, ~5-7h): makes
   `saving.gd`'s flower/bee restore build and pass its own node array
   instead of re-querying a SceneTree group mid-restore, rejects a save
   newer than `FORMAT_VERSION`, and adds a couple of guardrails to
   `tests/source_checks.py` (checks `Perf` is a registered autoload,
   recursive script glob, a regex guard against unauthorised
   `GameConfig.` writes -- the last of which would have caught Bundle
   A's bug automatically). Start a session on this once (1) is
   confirmed, same one-bundle-per-session order the plan lays out.
3. **Challenge 2 (Brood, Roles and Expansion) has no stage data yet.**
   The menu entry and `LEVELS[2]` starting-state preset exist
   (`levels.gd`); none of its ten sub-stages, failure conditions or
   Dr Gallerin prompts are written. `challenge_runner.gd`'s `STAGES`
   array is Challenge 1 only so far -- see its own header comment for
   why stage data lives there rather than in `levels.gd`. This is
   naturally the next slice once (1) is confirmed, since it's the
   first thing that will actually exercise `tutorial_checkpoint.gd`'s
   restore path (Challenge 1 has no failure condition to trigger it;
   Challenge 2's does, from sub-stage 2.3 onward per the plan).
4. **The balance overrides `TUTORIAL_PLAN.md` describes for Challenge 1's
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
  focused on the tutorial. Fog of war specifically now also has a
  measurement step queued up in `AUDIT_PLAN.md` Bundle C -- the same
  playtest can cover both "does it look right" and "is it fast".
- **Re-measure `bee_movement.gd` with `perf.gd`** -- still on the list.
  See "Measuring performance, not guessing at it" in CLAUDE.md before
  touching it -- wrap the widest scope first.
- Depth in what exists: nurse-mediated caste switching, comb temperature,
  multi-storey comb.
- A second hive site to move to.

## Last verified

- `python3 tests/source_checks.py` and `python3 tests/balance_tests.py`
  both passing, and a full Godot boot via `mcp__godot__run_project`
  clean (only pre-existing, unrelated shadowing/unused-parameter
  warnings), after landing `AUDIT_PLAN.md` Bundle A.
- Every script in `scripts/` also checked with `gdlint`/`gdparse`
  (`gdtoolkit`, pip-installed locally, not a project dependency) as of
  19 Aug -- catches real parser/type errors that `source_checks.py`
  alone can't (it only checks names/brackets, not scope or type
  inference). Two real bugs were caught and fixed this way before
  reaching Dave: a leftover cross-scope reference in `hud.gd`, and a
  `:=` type-inference failure on a loosely-typed `main.X` reference in
  `input_selection.gd` -- see `bee_survival.gd`'s `_announce_death`
  pattern (`main.DeathMarker.new()`, plain `=`) for why that class of
  assignment has to skip `:=`.
