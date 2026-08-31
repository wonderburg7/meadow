# Bugs this project keeps having

Moved out of root `CLAUDE.md` in the Aug 2026 context restructure
(`plans/reference/technical-audit.md`) so the always-loaded file stays short.
`.claude/rules/gdscript.md` and `.claude/rules/simulation.md` point here
automatically when a `.gd` file is touched. Worth knowing, because each
of these has bitten more than once:

- **Bulk renames hitting identifiers.** "Architect" → "Comb worker"
  produced `var comb workers := 0`. Blank screen, because a parse error
  in `main.gd` means the only scene won't load. `source_checks.py` now
  catches it. Prefer word-boundary replacements and check the diff.
- **Variable shadowing built-in properties.** `offset` on Polygon2D,
  `scale` on Node2D. Four separate occurrences so far.
- **Coordinate spaces.** `hive_root` and `meadow_root` sit at different
  world offsets, so local `position` matches a global point only by
  coincidence in the meadow. Convert once, deliberately.
- **Nearest-thing searches picking the thing you're standing on.**
  A flower recharges every frame, so the one a bee just drained keeps
  winning at distance zero. Any "find the nearest X" needs an exclusion.
- **Optimising a set too small to need it.** The spatial grid was
  applied to the 14 obstacles as well as the 250 flowers, and made
  steering slower: the query touched 25 to 121 buckets and allocated an
  Array per bee per frame, against a scan of 14 items that allocated
  nothing. Before adding an index, check the count *and* the call rate.
  Flowers: 250 objects, 8 queries a second. Obstacles: 14 objects, 60 a
  second. Only the first is worth indexing.
- **Allocation churn reads as jitter, not as slowness.** Movement is
  `speed * delta`, so anything that makes frame times uneven shows up as
  bees moving in little lurches rather than as a lower FPS number. If
  something looks twitchy, suspect per-frame allocation before you
  suspect the steering maths.
- **Commitments dropped on a single frame.** `skirt_obstacle` is held so
  a bee doesn't re-pick which way round an obstacle to go and flip at
  the halfway angle. Clearing it the first frame the way looks clear
  defeats that, because the check can momentarily miss part-way past.
- **A refactor leaves a function calling itself.** `_grounded()`'s doc
  comment said "rain and winter both stop trips", but the rain half
  had been replaced with `if _grounded(): return true` — the function
  calling itself, unconditionally, presumably where a real rain check
  used to be before something got renamed or moved out from under it.
  (The function is `bee_status.gd::grounded()` since the bee.gd split;
  this bug predates that move.)
   This was the entire cause of a 4fps drop (see `plans/archive/PERF_PLAN.md`):
  GDScript's call stack recursed until it errored out, every single
  call. Nothing crashed and nothing looked obviously wrong from
  outside the function, which is what made it worth `perf.gd` finding
  rather than a read-through. Worth a beat of suspicion any time a doc
  comment describes two things a function does but only one appears
  to happen in the body.
  Any hysteresis needs to survive one bad frame.
- **A navigable-area loop one ring wider than the area actually built.**
  `hive.gd::build_navigation` scanned hex rings `0..reach` inclusive;
  `world_building.gd`'s own dig loops stop at `reach - 1`. Ring `reach`
  never got a floor, soil or rock tile, so nothing was registered
  there -- and the walkability check (`_is_solid`) reads "no node
  registered" as "open floor" by default, not as "doesn't exist yet".
  The two numbers only had to agree by convention, not by any shared
  constant, and they'd drifted apart. Found 19 Aug because Challenge
  1's queen could path onto that phantom ring and wander the empty
  space outside the rock wall instead of reaching the entrance. Worth
  a beat of suspicion any time two different loops are meant to cover
  "the same" range but each computes its own bound.
- **A leftover line surviving a multi-step edit.** Fixing a comment
  during one `Edit` call, then fixing the code again in a second call
  a few turns later, left a stray line from the first version sitting
  in a function that never used it (`hud.gd`, 19 Aug — see "Verifying
  without Godot" in `CLAUDE.md`). Passed both check suites; failed to
  load in Godot. Worth rereading the *whole* function after more than
  one edit touches it, not just the specific lines each edit changed.
- **A typed `Array[T]` property can't take a bare `[]` from outside its
  class.** `bee.known_patches` is declared `Array[Vector2]`; resetting it
  from another script via `some_dynamically_typed_ref.known_patches = []`
  throws "Invalid assignment of property or key" at runtime, because an
  untyped literal isn't coerced into a typed array outside the declaring
  class's own static context — and it's data-independent, so it throws
  on the very first call, not just on bad input. Build the typed array in
  a local var first (`var x: Array[T] = []`, populate, then assign) or
  return one from a helper, rather than assigning a literal through a
  reference whose static type doesn't carry the property's declared type.
  Bit `saving.gd::_restore_bees()` 31 Aug (see
  `plans/now/hands-on-fixes-2026-08-31.md` Slice A1) — worth a beat of
  suspicion for any other `Array[T]`/`Dictionary[K,V]`-typed field a
  restore/deserialize path resets wholesale from outside its class.

## Environment quirk: a stale git lock

A stale `.git/index.lock` or `HEAD.lock` costs a retry, not a rebuild.
Sessions reaching this folder through a device bridge (rather than a
local shell) sometimes can't delete files directly, and a previous git
process here can leave a lock file behind. `git commit` then fails with
"Unable to create ... .git/index.lock". The fix is to move the stale
lock aside rather than delete it — `mv` works where `rm` doesn't — then
re-run the commit:

```
mv .git/index.lock .git/stale_locks/index.lock.$(date +%s)
mv .git/HEAD.lock .git/stale_locks/HEAD.lock.$(date +%s)   # if present
```

Nothing is actually wrong with the repo when this happens. Don't spend
a turn investigating it — move the lock and retry.
