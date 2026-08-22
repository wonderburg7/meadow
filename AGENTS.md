# Meadow — orientation for a new session

Read this first. It's the shortest path to being useful on this project
without re-deriving everything.

Meadow is a bee-colony simulation game, built solo by Dave in **Godot 4 /
GDScript**. He has some Python experience and no game-dev background, so
code here is read by a person who will want to change it himself. The
point of the project is enjoying building it with AI tools; a polished
Steam release is a stretch goal, not the bar.

**The repo is the design and build source of truth**: `CLAUDE.md`,
`ROADMAP.md`, `DESIGN_BACKLOG.md` and `NEXTSTEPS.md` at the root. Notion
(Meadow teamspace) is no longer kept in sync automatically -- only read
or write it if Dave asks directly.

---

## Start here each session

Read `NEXTSTEPS.md` before anything else in this file. It holds the next
1-3 concrete actions and nothing else -- reading it instead of reasoning
your way back to "what's next" from this whole file is most of the saving
of keeping it. At the end of a session, rewrite it (don't append) so it
stays short and current. If a plan needs to survive past the current
session, it goes in its own file (see `PERF_PLAN.md` for the pattern), not
just in `NEXTSTEPS.md` or the conversation.

## Where things are

```
scenes/Main.tscn      one scene, one node, points at main.gd
scripts/              all game code, ~16,700 lines
tests/                two Python suites, no Godot needed
DESIGN_BACKLOG.md     agreed but unbuilt: progression, winter debate
LANGUAGE_REVIEW.md    naming and structure review (mostly actioned)
ROADMAP.md            candidate features, sized and prioritised
NEXTSTEPS.md          read this first -- see "Start here" above
FUNCTION_MAP.md       line-numbered func index for the six biggest scripts
```

### Which file to open for which kind of change

Read this table, then open one file. Do not explore the whole `scripts/`
folder to find where something lives — that is the single most expensive
thing a session can do here.

| Change | File | Lines |
|---|---|---|
| A bee's dispatch loop, player commands, display text, vars | `bee.gd` | 1,685 |
| Steering and obstacle avoidance (the hot path -- see PERF_PLAN.md) | `bee_movement.gd` | 325 |
| Life support, eating, the stall watchdog | `bee_survival.gd` | 344 |
| Foraging, entering/leaving the hive, scouting, entrance recruitment | `bee_foraging.gd` | 636 |
| Nursery work, royal jelly | `bee_nursery.gd` | 315 |
| Building, restocking | `bee_building.gd` | 316 |
| Mining | `bee_mining.gd` | 80 |
| Honey making | `bee_honey.gd` | 116 |
| Queen egg laying | `bee_egg_laying.gd` | 103 |
| Role/State enums (`bee.gd` and every `bee_*.gd` file alias these) | `bee_enums.gd` | 52 |
| "Is it grounded" / "does this role work indoors" | `bee_status.gd` | 41 |
| A bee's generated name, rolled trait and fact (see BEE_INDIVIDUALITY_PLAN.md) | `bee_identity.gd` | 247 |
| World setup, spawning, moving bees between meadow and hive (hex geometry, the entrance) | `world_building.gd` | 485 |
| Click/drag selection, placement modes, hive-view overlays, right-click commands | `input_selection.gd` | 570 |
| Save/load | `saving.gd` | 260 |
| Restock zones, build/mine queues (the orders a player gives) | `orders_zones.gd` | 261 |
| Year progression, winter | `year_winter.gd` | 323 |
| Camera | `camera_view.gd` | 142 |
| Per-frame entry point, everything not yet split out of main | `main.gd` | 762 |
| Corner readouts, panels, popups, warnings, the problem strip, the Challenge goal readout | `hud.gd` | 1,720 |
| Settings window (the cog icon), starred readouts, save/load buttons, restart | `debug_panel.gd` | 1,187 |
| The comb as a whole: cells, navigation, finding a cell | `hive.gd` | 873 |
| One cell: contents, brood, honey ripening, how it draws | `hive_cell.gd` | 845 |
| Balance numbers | `game_config.gd` | 515 |
| Run state and interface preferences | `session.gd` | 123 |
| Role ids, labels, colours, sub-modes | `roles.gd` | 203 |
| Seasons, disease, winter, gynes leaving | `season.gd` | 173 |
| Flower behaviour, species, in-season logic | `flower.gd` | 341 |
| Save file format | `save_game.gd` | 310 |
| Meadow fog of war: explored/dim/unseen tiles | `fog_of_war.gd` | 220 |
| Level/Challenge starting-state presets (`main.Levels.LEVELS`) | `levels.gd` | 49 |
| Which UI is unlocked during a Challenge run | `stage_gate.gd` | 83 |
| A Challenge's rolling checkpoint/rollback (separate from the player's own save) | `tutorial_checkpoint.gd` | 54 |
| Dr Gallerin: the tutorial mentor popup and its prompt scheduler | `gallerin_panel.gd` | 210 |
| A Challenge's sub-stages: goals, UI unlocks, checkpoints, Dr Gallerin prompts | `challenge_runner.gd` | 291 |

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
`death_marker.gd`, `click_marker.gd`, `spatial_grid.gd`, `shapes.gd`,
`ui.gd`.

Every long script is divided by `# --- section name ---` headers. Grep
for those to find a region rather than reading the file top to bottom.

For the six biggest scripts (`hud.gd`, `bee.gd`, `debug_panel.gd`,
`hive_cell.gd`, `hive.gd`, `main.gd`), `FUNCTION_MAP.md` lists every
function and section header with its line number, so a session can grep
the map for a name instead of reading 800-1,500 lines to find it. See
"Working here without burning tokens" below for how to use and maintain it.

---

## Working here without burning tokens

This project is now ~16,700 lines, and the cost of a session is mostly
the cost of what gets read. In rough order of how much each saves:

**Read one file, not the folder.** Use the table above. A whole-folder
search costs more than every edit in a typical session combined.

**For the six biggest scripts, check `FUNCTION_MAP.md` before opening the
file.** Grep it for the function name, note the line number, then either
`Read` the source file with an offset near that line or grep the source
directly to get the exact current line before editing -- the map's line
numbers drift as the file changes and are a pointer, not a guarantee.
When you add, remove, rename or move a function in one of those six
files, update its entry in `FUNCTION_MAP.md` in the same pass. An
out-of-date map is worse than no map, so don't skip this because the
change felt small.

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
both dropped to under 1,400 straight after the split, with the rest
spread across the files the table above lists. Confirmed working in
Godot 14 Aug. `main.gd` has stayed small (762 lines as of 19 Aug);
`bee.gd` has crept back up to 1,685 (new fields and small player
commands, not a structural regrowth) and is worth watching -- if it
keeps climbing, the same move (a routing table entry, a `static func`
or child-Node file, see `BEE_SPLIT_PLAN.md`/`MAIN_SPLIT_PLAN.md`)
applies again.

**Leave `_backups/` out of any search.** It holds eight full copies of
older scripts (54 `.gd` files). It is gitignored, but it is still on
disk, so a filesystem-wide search matches nine copies of everything.
Git history has replaced it since 10 Aug and it can be deleted.
`.claudeignore` now keeps `_backups/`, the `.godot/` cache and the
per-resource `.uid` files out of Codex's context automatically --
if binary art or audio assets get added later, add their extensions
there too, since a session can't act on raw image/audio bytes anyway.

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

Two suites stand in for a Godot install, and both must pass before
committing:

```
python3 tests/source_checks.py    # does it parse and resolve
python3 tests/balance_tests.py    # are the numbers survivable
```

`source_checks.py` checks names rather than structure: every declaration
must be one legal identifier, every bare call must resolve, both
autoloads must be registered. `balance_tests.py` reads the tuning values
out of the GDScript and re-simulates the rules, so what's tested is what
ships.

**Neither is a real GDScript parser.** Both are worth running on every
change, but `source_checks.py` doesn't catch a genuinely broken script
-- found the hard way 19 Aug, when a leftover cross-scope reference
left over from an earlier edit (`hud.gd` calling a variable that only
existed in a different function) passed both suites clean and then
failed to load in Godot with a real Parser Error. If you want a closer
check than the two suites without Godot itself, `pip install
gdtoolkit` gets you `gdlint`/`gdparse` -- a real GDScript grammar
parser, not a project dependency, just a local tool. It would have
caught that specific bug. It still isn't the full story: `gdtoolkit`
doesn't do Godot's own type inference either, so it missed a `var x :=
some_loosely_typed_ref.SomeClass.new()` failing to infer a type (fixed
by dropping to plain `=`, matching the existing pattern in e.g.
`bee_survival.gd`'s `_announce_death` / `world_building.gd::mark_death`)
-- only an actual Godot run caught that one.

**If `mcp__godot__*` tools are available this session** (check the
deferred-tools list; not guaranteed to be wired up every session), use
`run_project` + `get_debug_output` to boot the project and check for
parser/type errors before telling Dave something is ready to test --
it takes seconds and catches exactly the class of bug the paragraph
above describes, before he ever sees it. Stop the run afterwards
(`stop_project`) rather than leaving it going. This still isn't a
substitute for his own check, just a faster net for the class of bug
that would otherwise cost him a whole session to report back.

**Nothing here replaces Dave's hands-on check.** Anything click-driven
-- popups, dropdowns, placement modes, dialogs -- and anything visual
or behavioural (does the camera frame the right thing, does a bee
actually walk where it should) can only be confirmed by him running
it, even with Godot tooling available. Say so rather than implying
it's verified.

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
  without Godot" above). Passed both check suites; failed to load in
  Godot. Worth rereading the *whole* function after more than one edit
  touches it, not just the specific lines each edit changed.

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

## State of play (19 Aug 2026)

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

**Shipped 14 Aug, later the same day (a blueprint-then-implement
pass, `NEW_FEATURES_BLUEPRINT.md`):**

- **Flat-top hive geometry** — the comb, soil and rock hexagons now sit
  flat-side up/down instead of pointy-top. Confined almost entirely to
  `shapes.gd` (`hexagon_points`, `hex_to_pixel`, `pixel_to_hex`); axial
  neighbour math is orientation-independent so nothing else needed to
  change. Save format bumped to `FORMAT_VERSION = 2` with defensive
  tile-clearing in `saving.gd::_restore_cells` for old saves.
- **Single-file-wide entrance tunnel at the top corner** — replaces the
  old "1, 2, 1, 2" pattern. `world_building.gd::_entrance_tiles` now
  walks the straight `q = 0` column; axial `(0, -R)` is always the
  unique topmost ring corner under flat-top projection.
- **"Work from here" now targets one bee, not the whole selection** —
  plus a new "set for all comb workers" button (`hud.gd`,
  `input_selection.gd`) for the old broadcast behaviour when it's
  actually wanted.
- **A visual marker for a selected bee's home cell** — drawn for both
  builders (`has_home_hex`) and miners (`has_mine_home`), same style as
  the existing start-point marker.
- **Nectar/pollen recolour** — pollen took over the old nectar amber
  (lightened slightly); nectar is now pale blue with a touch of yellow,
  read as a clear liquid in a yellow wax cell (`hive_cell.gd`).
- **Tuner renamed to the settings window, text button replaced with a
  cog icon** (`debug_panel.gd`). Call it "the settings window" in
  conversation and comments from here on, not "the tuning panel".
- **Build-here hover border** — any clear, buildable hex under the
  mouse gets an outline while a build placement is active
  (`input_selection.gd::_draw_build_hover`).
- **Winter energy/lifespan now actually applied in simulation, not
  just shown in the forecast** — `bee_survival.gd::age_and_burn` was
  computing burn without `winter_burn_factor` even though the forecast
  display promised it would; now fixed. Added
  `GameConfig.winter_lifespan_factor` (bees live longer in winter,
  hibernation-like) applied in `season.gd::lifespan_factor()`. The
  4.0x starting value isn't yet backed by a full throwaway simulation
  per this project's own rule 4 — see `DESIGN_BACKLOG.md`.
- **Top-right button row now positions itself relative to the settings
  cog's actual measured width**, not a hardcoded pixel constant
  (`hud.gd::set_settings_button_width`, called from `debug_panel.gd`
  via the cog button's `resized` signal). Done so a future font-size
  setting won't silently break the layout again.

**Shipped 18-19 Aug, three separate pieces of work:**

- **Foraging automation split into a dependency tree** — the old single
  `auto_foraging_on` toggle is now four: **Orientation flight** (a
  forager's one semi-random settling flight before her first trip),
  **Auto scouting** (tries a few start points and keeps the best,
  requires Orientation flight), **Floral constancy** (existing, now
  also samples a species per scouting bout), and **Auto-recruitment**
  (renamed from `auto_foraging_on`; foragers compare notes at the
  entrance, requires Auto scouting). Each cascades its prerequisites on
  and its dependents off (`debug_panel.gd`'s `TOGGLE_PREREQUISITE`).
  Recruitment thresholds are now nectar/pollen pairs, matched
  resource-specific in both directions. See `SCOUTING_TOGGLE_PLAN.md`.
- **Bee individuality** — every bee gets a generated name, one rolled
  stat trait (small, leaning positive), and a fact about herself,
  shown in the single-bee selection panel and survived across
  save/load. A star toggle pins a favourite into the colony window's
  Favourites list. A death shows a one-line epitaph, throttled so a bad
  night doesn't spam toasts. See `bee_identity.gd` and
  `BEE_INDIVIDUALITY_PLAN.md`. Lineage inheritance for gynes is still
  deferred (`DESIGN_BACKLOG.md` §10).
- **Fog of war reworked** — finer 5-unit tiles (was 20), a genuinely
  opaque colour, and a "Fog stays revealed" setting choosing between a
  scouted patch dimming to memory or staying lit for good. Needed a
  real perf pass alongside the constant change (bees recompute lit
  tiles only every ~40 units moved; the draw pass merges each row into
  colour runs). See `fog_of_war.gd`.

All three were last known to need Dave's hands-on check; none has had
a specific correction since, but none has an explicit "confirmed
working" either — see `NEXTSTEPS.md`.

**Shipped 19 Aug — the opening tutorial, `TUTORIAL_PLAN.md`:**

Challenge 1 ("First Stores") is playable end to end: found a colony
from a lone queen, build the first cell, gather nectar then pollen,
guided by Dr Gallerin (a moth mentor popup) through seven scripted
sub-stages with UI that unlocks as you go. New infrastructure this
needed, all reusable for Challenge 2 once that gets written:
`levels.gd` (level/Challenge presets, extracted out of `main.gd`),
`stage_gate.gd` (the UI unlock/lock mechanism), `tutorial_checkpoint.gd`
(a rolling autosave, separate from the player's own save, for a
Challenge's soft-failure rollback — built but not yet exercised, since
Challenge 1 has no failure condition), `gallerin_panel.gd` (the mentor
popup and its prompt scheduler), and `challenge_runner.gd` (the
sub-stage logic itself). The opening menu now groups **Challenges**
(scripted, Dr Gallerin, a win condition) separately from **Starter
modes** (the plain presets Levels 3-5 used to be, relabelled).

Two rounds of hands-on testing turned up real fixes along the way,
including a general navigation bug (bees could path into the empty
space outside the hive's rock wall — see "Bugs this project keeps
having") and a load-destroying deposit bug, both fixed for every level,
not just the tutorial. Full list in `TUTORIAL_PLAN.md`'s "Built and
playable" note and in `NEXTSTEPS.md`.

Challenge 2 (Brood, Roles and Expansion) has no stage data yet — same
menu entry, still just its plain `levels.gd` starting-state preset
underneath.

**What's deferred on purpose and what's next** now lives in
`NEXTSTEPS.md`, not here, because it changes every session and this file
shouldn't. Update `NEXTSTEPS.md` (overwrite, don't append) at the end of
a build session the same way you already update the Notion Build Log --
see "Start here each session" at the top of this file.

See `DESIGN_BACKLOG.md` for the progression/levels design and the
unresolved argument about whether winter should be a played scene or a
resolved event, and `ROADMAP.md` for sized candidate features.
