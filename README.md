# Meadow -- v1 prototype 1: forager movement + pickup

## What this tests
One bee, one flower, one hive. The bee flies out, "collects" for a
second, flies back, "deposits" for half a second, then repeats forever.
No player input yet -- this is purely to check the loop *feels* right
before we build anything else on top of it (multiple bees, nectar/pollen
choice, flower depletion, day counter).

## How to run it
1. Open Godot 4.3 or later.
2. Import this folder (the one with `project.godot` in it) as a project.
3. Press Play (F5), or F6 to just run the Main scene.
4. You should see: a brown square (hive) and a yellow square (flower),
   with a black square (bee) shuttling between them, and a "Collected: N"
   counter in the top-left that ticks up by 1 each round trip.

## What to report back
- Does it run without errors?
- Does the loop feel too fast / too slow / about right? (tweak `speed`,
  `collect_time`, `deposit_time` at the top of `scripts/bee.gd` and
  re-run to compare)
- Anything that looks or feels wrong.

## Files
- `project.godot` -- project settings
- `scenes/Main.tscn` -- the one scene, just points at `main.gd`
- `scripts/main.gd` -- creates the hive, flower, and bee and wires them up
- `scripts/bee.gd` -- the bee's state machine (fly / collect / fly / deposit)
- `scripts/hive.gd` -- storage counter
- `scripts/flower.gd` -- placeholder, no logic yet
