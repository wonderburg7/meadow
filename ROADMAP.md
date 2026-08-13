# Candidate features and improvements

Grouped by what they'd buy you. Each has a rough size and my honest view
of whether it's worth doing, because a list of everything possible isn't
much use on its own.

Sizes: **S** an evening, **M** a few sessions, **L** a substantial piece
of work.

---

## Performance and scale

The game currently runs a full state machine, energy budget and
pathfinding per bee per frame. That's fine at fifty bees. The things
below are in the order they'll start to matter.

| | Size | Worth it? |
|---|---|---|
| **Update budgeting** — give each bee a "think" tick a few times a second rather than every frame, keeping only movement per-frame. Bees make decisions on a scale of seconds; asking sixty times a second is waste | M | **Yes, and first.** This is the single biggest win available and costs nothing visible. A colony of 300 would cost about what 50 does now |
| **Spatial grid for flowers and obstacles** — bucket the meadow into a coarse grid so "nearest flower" and "what's in the way" check a handful of candidates instead of all 250 | M | **Yes, second.** `_pick_flower` and `_first_blocker` are both linear scans today |
| **Stop drawing what isn't on screen** — bees and flowers outside the camera don't need `_update_label` or colour lerps | S | Yes, cheap |
| **Pool the death markers and rain streaks** rather than creating and freeing nodes | S | Only if profiling says so; rain is already pooled |
| **Move the hive's A\* to a coarser graph** — route between regions rather than tiles, then walk locally | L | Not yet. The path cache already handles it |

**The one measurement worth taking first:** run 300 bees and see what
actually costs. Everything above is a prediction, and predictions about
performance are usually wrong.

## Making the middle game interesting

The colony currently has no reason to stop growing. These give it one.

| | Size | Worth it? |
|---|---|---|
| **Winter proper** — the countdown exists; make the season actually happen. Foraging stops, the colony burns stores, bees die if it runs out, and the survivors emerge in spring | M | **Yes.** The countdown is already creating the interesting decisions; delivering on it closes the loop |
| **Gynes leaving and scoring** — the original premise. Gynes fly off at the end of the season and are the score | M | **Yes.** It's the stated win condition and nothing currently ends a run except losing |
| **Disease and parasites** — a hive that grows without cleaning gets sick; nurses and clearing work become preventative rather than reactive | M | Strong. It gives "maintenance" a reason to exist beyond tidiness |
| **Forage seasonality** — species come into flower at different times, so the best patch moves through the year | M | **Yes, and cheap given `Flower.SPECIES` already exists.** Turns floral constancy and start points from curiosities into real decisions |
| **Predators** — something that eats foragers in the meadow | M | Maybe. Adds pressure, but the colony already has plenty; risks becoming noise |
| **A second hive site to move to** | L | Not yet |

## Depth in what exists

| | Size | Worth it? |
|---|---|---|
| **Nurse-mediated caste switching** — the deferred option from the nursery zone design. What a larva becomes is set by feeding, not by the cell | M | **Yes, as a later-level unlock.** It changes how an existing system works rather than adding a new one, which is the best kind of progression |
| **Comb temperature** — brood develops faster in a warm cluster; bees fan or huddle. Gives comb *layout* a reason to matter beyond space | M | Strong. Right now the shape of the comb barely matters |
| **Bee individuality** — small inherited variation in speed, capacity, lifespan; gynes carry it forward | S | Cheap and adds a lot of texture for the size |
| **Foraging memory** — a bee that found a good patch returns to it and recruits others (a waggle dance, or bumblebee scent-following) | M | **Yes.** It's the most famous thing bees do and the game doesn't have it |
| **Cell depth / multi-storey comb** | L | No. Doubles the UI problem for little gain |

## Interface

| | Size | Worth it? |
|---|---|---|
| **A "why is this bee idle?" answer** — click an idle bee and be told what it's waiting for | S | **Yes, high value for the size.** "Nothing is happening and I don't know why" is the worst state for a player |
| **Alerts you can click through to** — the problem strip lines select the bees or cells they're about | S | Yes, obvious follow-on from the strip |
| **Saved selections / control groups** (press 1 to select your nectar foragers) | S | Yes |
| **Comb overlay modes** — colour the whole comb by contents, by fill level, by age, by who's assigned to it | M | **Yes.** The nursery zone glow proved this pattern works; generalise it |
| **A tutorial or first-run guidance** | M | Eventually. Not while the systems are still moving |
| **Undo for cell designation** | S | Worth it once players are managing 50+ cells |
| **Rebindable keys and a settings screen** | S | Later |
| **Zoom-to-fit and camera bookmarks** | S | Nice, cheap |

## Structural work (see LANGUAGE_REVIEW.md for detail)

| | Size | Worth it? |
|---|---|---|
| **One `roles.gd` instead of role constants in four files** | S | **Yes, first.** Removes a whole class of bug |
| **Split `GameConfig` into balance vs session state** | S | Yes |
| **Save the things that currently aren't** (keep-clear tiles, build/mine queues, restocking orders, priority credit) | S | Yes — silent data loss is the worst kind |
| **Break up `main.gd`** (selection, world building, save/restore) | M | Yes, when it next becomes painful rather than pre-emptively |
| **Automated tests for the balance rules** — the rival colony and winter maths are already tested this way, and both had real bugs the tests caught | M | **Yes.** The pattern works; extend it to brood, energy and foraging economics |

---

## If I had to pick five

1. **Update budgeting** — everything else gets easier when the colony can be large
2. **One `roles.gd`** — an evening, and it stops a recurring class of bug
3. **Winter proper** — the countdown has already created the decisions; deliver on them
4. **Forage seasonality** — cheap, and makes three existing systems matter more
5. **"Why is this bee idle?"** — the cheapest large improvement to how the game feels to play
