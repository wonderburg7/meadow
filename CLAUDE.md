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
scripts/              all game code, ~13,500 lines
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
| Anything a bee does: states, movement, steering, jobs, energy | `bee.gd` | 3,098 |
| World setup, per-frame loop, input, selection, saving, orders | `main.gd` | 2,801 |
| Corner readouts, panels, popups, warnings, the problem strip | `hud.gd` | 1,498 |
| Tuning rows, starred readouts, save/load buttons, restart | `debug_panel.gd` | 1,014 |
| The comb as a whole: cells, navigation, finding a cell | `hive.gd` | 825 |
| One cell: contents, brood, honey ripening, how it draws | `hive_cell.gd` | 823 |
| Balance numbers | `game_config.gd` | 402 |
| Run state and interface preferences | `session.gd` | 96 |
| Role ids, labels, colours, sub-modes | `roles.gd` | 203 |
| Seasons, disease, winter, gynes leaving | `season.gd` | 161 |
| Flower behaviour, species, in-season logic | `flower.gd` | 329 |
| Save file format | `save_game.gd` | 276 |

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

**Splitting the big files is a token change as much as a tidiness
one.** `main.gd` at 2,801 lines is roughly 27,000 tokens to read once,
and it is the file most changes touch. `bee.gd` is larger still. Both
are queued for splitting.

**Leave `_backups/` out of any search.** It holds eight full copies of
older scripts (54 `.gd` files). It is gitignored, but it is still on
disk, so a filesystem-wide search matches nine copies of everything.
Git history has replaced it since 10 Aug and it can be deleted.

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

## State of play (13 Aug 2026)

Playable well beyond the original v1 target. The loop runs: found a
colony, dig out a hive, build comb, assign bees across seven roles,
forage through a flowering year, survive winter, release gynes for
score. There's a rival colony competing for the same meadow, disease
pressure from neglect, weather, save/load, five starting levels and a
full tuning panel.

**Deferred on purpose, most recent first:**

- **Break up `main.gd`** — extract selection/placement modes, world
  building, and save/restore. Agreed worth doing "when it next becomes
  painful". At 2,750 lines it's close.
- **Tutorial / first-run guidance** — Dave named this as the next thing
  to build after the 13 Aug batch.
- **Depth in what exists** — nurse-mediated caste switching, comb
  temperature, bee individuality, foraging memory, multi-storey comb.
- **A second hive site to move to.**

See `DESIGN_BACKLOG.md` for the progression/levels design and the
unresolved argument about whether winter should be a played scene or a
resolved event, and `ROADMAP.md` for sized candidate features.
