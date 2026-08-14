# Meadow — orientation for a new session

Read this first. It's the shortest path to being useful on this project
without re-deriving everything.

Meadow is a bee-colony simulation game, built solo by Dave in **Godot 4 /
GDScript**. He has some Python experience and no game-dev background, so
code here is read by a person who will want to change it himself. The
point of the project is enjoying building it with AI tools; a polished
Steam release is a stretch goal, not the bar.

**Notion is the design source of truth** (Meadow teamspace only): Game
Outline, V1 Design Doc, Decisions Log, Backlog / Parking Lot, Build Log.
Check them before planning; log back to them after a session.

---

## Where things are

```
scenes/Main.tscn      one scene, one node, points at main.gd
scripts/              all game code, ~14,000 lines
tests/                two Python suites, no Godot needed
DESIGN_BACKLOG.md     agreed but unbuilt: progression, winter debate
LANGUAGE_REVIEW.md    naming and structure review (mostly actioned)
ROADMAP.md            candidate features, sized and prioritised
```

### Which file to open for which kind of change

Read this table, then open one file. Do not explore the whole `scripts/`
folder to find where something lives — that is the single most expensive
thing a session can do here.

| Change | File | Lines |
|---|---|---|
| A bee's dispatch loop, player commands, display text, vars | `bee.gd` | 1,399 |
| Steering and obstacle avoidance (the hot path -- see PERF_PLAN.md) | `bee_movement.gd` | 325 |
| Life support, eating, the stall watchdog | `bee_survival.gd` | 309 |
| Foraging, entering/leaving the hive | `bee_foraging.gd` | 397 |
| Nursery work, royal jelly | `bee_nursery.gd` | 315 |
| Building, restocking | `bee_building.gd` | 303 |
| Mining | `bee_mining.gd` | 80 |
| Honey making | `bee_honey.gd` | 116 |
| Queen egg laying | `bee_egg_laying.gd` | 103 |
| Role/State enums (`bee.gd` and every `bee_*.gd` file alias these) | `bee_enums.gd` | 46 |
| "Is it grounded" / "does this role work indoors" | `bee_status.gd` | 41 |
| World setup, spawning, moving bees between meadow and hive | `world_building.gd` | 457 |
| Click/drag selection, placement modes | `input_selection.gd` | 486 |
| Save/load | `saving.gd` | 234 |
| Restock zones, build/mine queues (the orders a player gives) | `orders_zones.gd` | 253 |
| Year progression, winter | `year_winter.gd` | 323 |
| Camera | `camera_view.gd` | 114 |
| Per-frame entry point, everything not yet split out of main | `main.gd` | 725 |
| Corner readouts, panels, popups, warnings, the problem strip | `hud.gd` | 1,540 |
| Tuning rows, starred readouts, save/load buttons, restart | `debug_panel.gd` | 1,014 |
| The comb as a whole: cells, navigation, finding a cell | `hive.gd` | 831 |
| One cell: contents, brood, honey ripening, how it draws | `hive_cell.gd` | 827 |
| Balance numbers | `game_config.gd` | 402 |
| Run state and interface preferences | `session.gd` | 104 |
| Role ids, labels, colours, sub-modes | `roles.gd` | 203 |
| Seasons, disease, winter, gynes leaving | `season.gd` | 165 |
| Flower behaviour, species, in-season logic | `flower.gd` | 334 |
| Save file format | `save_game.gd` | 276 |

`bee.gd` and `main.gd` are each split across several files now (see
`BEE_SPLIT_PLAN.md` and `MAIN_SPLIT_PLAN.md` for why each file has the
boundary it has). `bee_movement.gd`, `bee_survival.gd` and the rest are
plain `extends RefCounted` files of `static func`s, called as
`BeeForaging.seek_flower(bee)` -- not child nodes, since a bee is
instantiated hundreds of times. `world_building.gd`, `input_selection.gd`
and `main.gd`'s other siblings are the opposite: each a single Node
child of `main`, reached as `main.world_building.foo()`, because `main`
exists once.

Smaller and self-explanatory: `colony_panel.gd`, `nursery_panel.gd`,
`winter_panel.gd`, `game_over.gd`, `main_menu.gd`, `rival_hive.gd`,
`obstacle.gd`, `soil_block.gd`, `rock_block.gd`, `rain_effect.gd`,
`death_marker.gd`, `spatial_grid.gd`, `shapes.gd`, `ui.gd`.

`egg.gd` and `queen.gd` are retired stubs. Ignore them.

Every long script is divided by `# --- section name ---` headers. Grep
for those to find a region rather than reading the file top to bottom.

---

## Working here without burning tokens

This project is now ~13,500 lines, and the cost of a session is mostly
the cost of what gets read. In rough order of how much each saves:

**Read one file, not the folder.** Use the table above. A whole-folder
search costs more than every edit in a typical session combined.

**Use git rather than re-reading.** `git log --oneline -10`,
`git show --stat HEAD` and `git show <sha> -- <file>` answer "what
changed recently" for a fraction of what re-reading the files costs.
The commit messages here are deliberately long and explain *why*; they
are cheaper than the code they describe.

**Run the tests instead of re-reading code to check it.**
`python3 tests/source_checks.py` and `python3 tests/balance_tests.py`
produce about twenty lines between them and catch the classes of bug
this project actually has. Verifying by reading is both dearer and
worse.

**Grep for a symbol before opening anything.** `grep -n "func _foo"`
and the section headers will locate a change in a few hundred tokens.

**One topic per session.** A session that has already loaded the hive
in order to answer a hive question is carrying that context through
every later question about something else. A fresh session with a
narrow goal reads less.

**Say what changed, not "have a look".** "The foragers went jittery
after the last update" points at a diff. "Something feels off" points
at the whole codebase.

**Splitting the big files was a token change as much as a tidiness
one, and it's done.** `main.gd` was 2,801 lines and `bee.gd` was 3,138;
both are now under 1,400, with the rest spread across the files the
table above lists. Confirmed working in Godot 14 Aug. If either grows
back towards that size, the same move (a routing table entry, a
`static func` or child-Node file, see `BEE_SPLIT_PLAN.md`/
`MAIN_SPLIT_PLAN.md`) applies again.

**Leave `_backups/` out of any search.** It holds eight full copies of
older scripts (54 `.gd` files). It is gitignored, but it is still on
disk, so a filesystem-wide search matches nine copies of everything.
Git history has replaced it since 10 Aug and it can be deleted.

**A stale `.git/index.lock` or `HEAD.lock` costs a retry, not a
rebuild.** Sessions reaching this folder through a device bridge
(rather than a local shell) sometimes can't delete files directly, and
a previous git process here can leave a lock file behind. `git commit`
then fails with "Unable to create ... .git/index.lock". The fix is to
move the stale lock aside rather than delete it — `mv` works where `rm`
doesn't — then re-run the commit:

```
mv .git/index.lock .git/stale_locks/index.lock.$(date +%s)
mv .git/HEAD.lock .git/stale_locks/HEAD.lock.$(date +%s)   # if present
```

Nothing is actually wrong with the repo when this happens. Don't spend
a turn investigating it — move the lock and retry.

---

## The four rules that matter

**1. Role data lives in `roles.gd`, nowhere else.**
Every role's id, label, colour, letter, tooltip and sub-modes are in one
table. `bee.gd`, `hud.gd`, `colony_panel.gd`, `nursery_panel.gd` and
`hive_cell.gd` all read from it. Adding a role should be one entry, and
every menu should pick it up for free. If you find yourself typing a
role name as a string literal in a panel, stop — that's the duplication
this file exists to prevent.

Note the enum in `bee.gd` still uses the old internal names
(`Role.BUILDER` is the Comb worker, `Role.NURSERY` is the Nurse). The
player-facing labels come from `roles.gd`. Don't rename the enum without
a good reason; the save format depends on it.

**2. `GameConfig` is balance numbers. `Session` is run and UI state.**
Both are autoloads. The test: would a designer tune it to change how the
game plays? Then `GameConfig`. Does it describe *this* run or *this*
player? Then `Session`. Getting this wrong is how the save file ended up
overwriting the player's screen layout with someone else's preferences.

**3. Presentation may be skipped; simulation may not.**
`main.gd.is_on_screen(node)` gates label and colour updates only. Never
gate a decision, a state change or a resource move behind it — bees off
screen must behave identically to bees on screen, or the game changes
depending on where the camera points.

**4. Never trust a balance number that hasn't been simulated.**
Every economic system here has shipped broken at least once and been
caught by writing a throwaway Python model first: winter needing more
honey cells than the hive has; a rival colony that always maxed out or
always died; disease that punished a spotless colony; a gap in the
flowering calendar with nothing in bloom at all. Model it, then set the
constant.

---

## Verifying without Godot

There's no Godot in the sandbox, so nothing here can actually be run.
Two suites stand in for it, and both must pass before committing:

```
python3 tests/source_checks.py    # does it parse and resolve
python3 tests/balance_tests.py    # are the numbers survivable
```

`source_checks.py` checks names rather than structure: every declaration
must be one legal identifier, every bare call must resolve, both
autoloads must be registered. `balance_tests.py` reads the tuning values
out of the GDScript and re-simulates the rules, so what's tested is what
ships.

**Neither replaces Dave's hands-on check.** Anything click-driven —
popups, dropdowns, placement modes, dialogs — and anything visual can
only be confirmed by him running it. Say so rather than implying it's
verified.

---

## Measuring performance, not guessing at it

`perf.gd` is an autoload that times named sections of code and shows
the worst frame times as a plot plus a top-8 breakdown in the corner,
behind the "fps" star (`Session.perf_enabled`, kept in sync by
`hud.gd::pinned_stats_changed`). It exists because this project has
had two performance regressions caused by confident guesses that were
wrong — see `PERF_PLAN.md` for the full writeup of the second one, a
4fps drop that turned out to be `_grounded()` calling itself instead
of checking rain -- that function is `bee_status.gd::grounded()` now,
moved there in the bee.gd split, but the bug and the method that found
it predate the move.

**The method that found it, worth repeating for the next one:**

1. Wrap the suspect at its widest scope first (a whole `_process`),
   not the function you already suspect — the plan's own leading
   suspect (A\* pathfinding) turned out to be measured at ~0ms
   throughout, and guessing would have wasted the session chasing it.
2. Ask Dave to star "fps", play until it's bad, and screenshot the
   corner. The breakdown names the worst sections directly; the plot
   shows whether it's sustained or a spike.
3. Split whichever section is worst along whatever dimension could
   explain it — role, then state, then the specific function — one
   round per playtest. Each split is a small, safe edit: wrap a
   narrower scope in its own `Perf.begin`/`Perf.end` pair, nested
   inside the wider one that's already there (different names nest
   fine; the same name nested twice does not — see the warning
   below). Two or three rounds is normal; this investigation took
   three (role → the eight forager states → ruling out a side theory)
   before the exact function fell out.
4. Only once a specific function is named, go and read it. Don't read
   speculatively before that — it's exactly the guessing this exists
   to avoid.

**Adding a new hot per-frame system?** Give it a `Perf.begin("name")`
/ `Perf.end("name")` pair at the point that covers its whole per-frame
cost, the same way the existing dozen-plus sections do. It costs
nothing when perf is off (both functions check
`Session.perf_enabled` and return immediately). This keeps the
breakdown complete rather than silently blind to whatever's newest —
grep `scripts/*.gd` for `Perf.begin(` to see the current full list
rather than trusting a copy of it here, since that list will drift.

**The one way this goes wrong**: a `begin` with no matching `end` on
every exit path of the function it's in. `Perf.end` silently no-ops
if there's no matching `begin` open, so a missed exit path just
under-counts that call rather than crashing or corrupting later
frames — safe, but worth actually checking (count `return` statements
in the function, make sure each has an `end` before it) rather than
assuming. Never reuse a section name for two spans that can be
active at once in the same function; a second `begin` under the same
name overwrites the first one's start time.

---

## Bugs this project keeps having

Worth knowing, because each has bitten more than once:

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
  This was the entire cause of a 4fps drop (see `PERF_PLAN.md`):
  GDScript's call stack recursed until it errored out, every single
  call. Nothing crashed and nothing looked obviously wrong from
  outside the function, which is what made it worth `perf.gd` finding
  rather than a read-through. Worth a beat of suspicion any time a doc
  comment describes two things a function does but only one appears
  to happen in the body.
  Any hysteresis needs to survive one bad frame.

---

## Working style Dave asked for

- **Multiple-choice questions, not open ones.** He often works from his
  phone. Offer 2–4 concrete options plus room for something else, and
  say which you'd pick.
- **Small playable slices**, not whole systems. After each: confirm the
  checks pass, say in plain language what changed, propose the next step.
- **Readability over cleverness.** Comments explain *why*, not *what*.
- **Show a plan before anything large or irreversible**, and back up
  before substantial edits.
- **British English. No em dashes.**
- Commit at the end of each slice with a plain-language message.
  Pushing goes through the GitKraken plugin, which disconnects often; if
  its tools aren't there, say so rather than retrying silently. The
  sandbox has no GitHub credentials, so a bare `git push` will fail.

---

## State of play (14 Aug 2026)

Playable well beyond the original v1 target. The loop runs: found a
colony, dig out a hive, build comb, assign bees across seven roles,
forage through a flowering year, survive winter, release gynes for
score. There's a rival colony competing for the same meadow, disease
pressure from neglect, weather, save/load, five starting levels and a
full settings window (the cog icon, top right).

`main.gd` and `bee.gd` have both been split (see the routing table
above, and `MAIN_SPLIT_PLAN.md` / `BEE_SPLIT_PLAN.md` for why each
boundary is where it is) and confirmed working in Godot 14 Aug --
that was the last item on the "deferred on purpose" list from the
previous state-of-play note.

**Deferred on purpose, most recent first:**

- **Tutorial / first-run guidance** — Dave named this as the next thing
  to build once the splits were done.
- **Re-measure `bee_movement.gd` with `perf.gd`** — it's the hottest
  path in the file (steering, obstacle avoidance) and hasn't been
  specifically re-profiled since the static-call pattern went in.
  Worth doing before trusting it's free, per this project's own rule
  about not trusting an unsimulated/unmeasured number.
- **Depth in what exists** — nurse-mediated caste switching, comb
  temperature, bee individuality, foraging memory, multi-storey comb.
- **A second hive site to move to.**

See `DESIGN_BACKLOG.md` for the progression/levels design and the
unresolved argument about whether winter should be a played scene or a
resolved event, and `ROADMAP.md` for sized candidate features.
