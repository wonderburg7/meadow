# Meadow

A bee-colony simulation game in Godot 4 / GDScript. You are the hive
mind: dig out a hive, build comb, put your bees to work, get through the
flowering year, and send gynes away to found colonies of their own.

Built solo, with AI, one small slice at a time.

---

## Running it

1. Open **Godot 4.3 or later**.
2. Import this folder (the one with `project.godot`).
3. Press **F5**.

The main menu offers five starting levels, from a lone queen with
nothing (level 1) up to an established colony (level 5).

---

## The loop

The colony has two views — the **meadow** and the **hive interior** —
and a role you assign per bee:

| Role | Does |
| --- | --- |
| Forager | Flies out for nectar or pollen |
| Nurse | Feeds brood, or makes royal jelly |
| Comb worker | Builds comb, clears dead cells, restocks stores |
| Miner | Digs soil to open the hive out |
| Honey | Turns nectar into honey for winter |
| Laying | The queen's own job |
| Idle | Standing by |

Most roles have sub-modes — a comb worker can be set to Building,
Clearing, Stocking or Anything — and any bee can be given a backup role
it falls back to when its own job has nothing on offer.

A **gyne** isn't a role but a bee raised as one, in a cell you've marked
for it. Raising one needs royal jelly, which needs a nurse making it.

Bees burn energy, eat from the comb, and die of old age or starvation.
Brood needs nursing or it starves. Flowers have real flowering windows,
so what's available changes through the year. Corpses left in the comb
raise disease pressure, which slows brood and shortens lives. Winter
stops foraging entirely and the colony lives on what it stored.

**Score is gynes released.** A huge hive that released none has failed
at the only thing a season is for.

---

## Controls

| Key | Does |
| --- | --- |
| Space | Pause |
| Tab | Switch view |
| C | Colony window |
| N | Nursery window |
| O | Cycle comb overlays |
| F | Frame the view on what matters |
| Ctrl + 1–9 | Save a selection |
| 1–9 | Recall it |
| Ctrl + Z | Undo a cell designation |
| Ctrl + click | Add comb or soil to the selection |
| Arrows | Pan |

Drag to select bees. Right-click to send them somewhere. Click any
warning in the corner and it selects whatever it's about.

There's a settings window behind the cog icon in the top-right corner:
every balance number in the game, editable while it runs, plus
save/load and restart.

---

## Verifying a change

There are two Python suites. Neither needs Godot, and both should pass
before you commit:

```
python3 tests/source_checks.py    # does it parse and resolve
python3 tests/balance_tests.py    # are the numbers survivable
```

`source_checks.py` checks that every declaration is a single legal
identifier, every bare call resolves, and both autoloads are registered.
It exists because a bulk rename once produced `var comb workers := 0` —
a parse error that took the whole game down to a blank screen, and that
every structural check of the day sailed straight past.

`balance_tests.py` reads the tuning values out of the GDScript and
re-simulates the rules, so what it tests is what actually ships. It has
caught a winter needing more honey cells than the hive has, a rival
colony that ignored how rich the meadow was, disease that punished a
spotless colony, and a stretch of the year with nothing in flower.

Neither can check anything click-driven or visual. That still needs
playing.

---

## Layout

```
scenes/Main.tscn      the only scene
scripts/              all game code
  roles.gd            single source of truth for every role
  game_config.gd      balance numbers (autoload)
  session.gd          run state and interface preferences (autoload)
  bee.gd              behaviour, state machine, movement
  main.gd             world, selection, save/restore, input
  hive.gd             comb, soil, indoor navigation
  hive_cell.gd        one cell: contents, brood, designation
  season.gd           the year: seasons, disease, winter, gynes
  spatial_grid.gd     bucketed lookups for flowers and obstacles
  hud.gd              readouts, panels, popups
tests/                the two suites above
_backups/             snapshots taken before large changes
```

Design notes live in `DESIGN_BACKLOG.md` (progression, the winter
question), `ROADMAP.md` (sized candidate features) and
`LANGUAGE_REVIEW.md` (naming and structure). `CLAUDE.md` is the
orientation file for an AI session.
