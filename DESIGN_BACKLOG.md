# Meadow — design backlog

Ideas agreed but deliberately **not** built yet. Kept here so the code stays
focused on what's actually in the game, and so nothing gets lost between
sessions. Nothing in this file is implemented.

Last updated: 11 Aug 2026

---

## 1. Progression structure (agreed direction)

The shape Dave proposed, recorded as the intended spine of the game:

- Each level introduces one or two new mechanics and a win condition that
  can only be met by using them.
- Complexity accumulates: later levels keep everything unlocked earlier.
- Some levels have **multiple win conditions**, all of which must be met in
  a single run.
- After the campaign, an **open world mode**: no win conditions, and a
  toggle list of every mechanic unlocked across the levels, so the player
  can build the sandbox they want.

**Implication for the code as it stands:** the level presets in `main.gd`
(`LEVELS`) are currently only *starting states*. They will need to grow into
a level definition holding: starting state, which mechanics are enabled,
win conditions, and adverse conditions. Worth doing as one restructure
rather than bolting conditions on piecemeal.

**Suggested first step when we pick this up:** extract levels out of
`main.gd` into their own `levels.gd` data file, with the same
starting-state fields plus empty `unlocks` and `win_conditions` arrays.
That is a small, safe change that makes everything after it easier.

---

## 2. Winter — the open question

Dave's concern, recorded verbatim in substance: a winter mode risks being
boring, because there is little to do and the goal reduces to limiting
energy expenditure.

That concern is well founded. A winter where the player watches a number go
down is a loading screen with extra steps.

### Option A — winter as a resolved event (Dave's fallback)

At the end of the season the game calculates what the colony needs to
survive: stores against colony size, adjusted for how well insulated the
comb is. Above the threshold, the colony emerges in spring with some losses;
below it, the colony dies.

- **Pros:** no dead playtime, keeps all the pressure in the part of the game
  that is actually fun, trivially cheap to build.
- **Cons:** it's a report card rather than a scene. The player never *feels*
  the winter, only reads about it.

### Option B — winter as a short, different game

Compress it heavily (a few minutes, not a season) and change what the player
is doing rather than removing things to do:

- **Thermoregulation.** Bees cluster and shiver to keep the brood warm.
  Shivering burns honey. The player positions the cluster and decides how
  tightly to hold it — tight is warm but slow to reach stores, loose is
  cheap but risks chilling brood. This is a genuine spatial decision, not a
  number.
- **Rationing.** Which bees eat, and which are allowed to die. Grim, but a
  real decision with a real trade-off against spring labour.
- **Cluster movement.** The cluster must move through the comb to reach
  stores. Isolation starvation — a colony dying with honey two cells away
  because it couldn't cross the cold gap — is real, well documented, and
  makes comb layout retroactively matter.
- **Intrusions.** Mice, damp, a mild spell that wakes the colony early and
  wastes stores.

### Recommendation

**Build Option A first**, as the resolution step at the end of a season, and
treat Option B's *thermoregulation and cluster movement* as the winter
gameplay to layer on later if the game wants a longer arc.

Reasoning: Option A is cheap, unblocks having a win condition at all, and
makes stores matter immediately. Option B is the interesting version but
it's a whole mechanic in itself, and building it before there's a campaign
to put it in risks it being work that gets designed around later. Doing A
first also gives a baseline to compare B against — if the resolved event
turns out to be satisfying enough, that's worth knowing before building the
bigger thing.

---

## 3. Win conditions (candidate pool)

For levels to draw on. Roughly ordered by how much new machinery each needs.

**Buildable on what exists now**
- Grow to a given colony size.
- Survive a given number of days.
- Produce a given number of gynes.
- Reach winter with a viable queen, workers, and stores above the threshold.
- Ecological balance: thrive without exhausting the meadow — score against
  flower depletion as well as colony output.

**Needs one new system**
- Scenario victory: each run has a different headline pressure.
- Survive specified adverse conditions (needs the adverse condition system).
- Protect against disease: task partitioning, limiting how much foragers
  bring in from outside.
- A system to survive floral ambush predators (crab spiders and the like).
- Temporal polyethism: bees change job with age rather than by assignment.
  Would be a significant change to how the player interacts with roles —
  worth prototyping separately before committing.

**Needs rival colonies**
- Repel robber bees (e.g. stop five robbers taking nectar).
- Rob from another colony.
- Destroy a rival colony.
- Grow to a size, or survive a duration, without provoking an attack.

---

## 4. Adverse conditions (candidate pool)

**Weather** — rain *(built)*, wind, drought, heatwave, cold snap.

**Flower ecology** — depletion, bloom timing through a season, patch quality
differences, competition from other pollinators.

**Hive biology** — disease, varroa mites, viruses, ageing.

**Social** — workers laying their own eggs, and the need for other bees to
police that. A genuinely interesting one: it turns the colony into something
the player manages *against* as well as with.

**Management pressure** — storage limits, labour bottlenecks, overcrowding.

**External** — pesticides, mowing, badgers, dogs, human disturbance.

---

## 5. Technical work not yet done

- **Save slots.** There is currently one slot, overwritten each save.
- **Flower regrowth on load.** Cluster centres aren't saved, so the meadow's
  patchiness gradually re-randomises after loading. Harmless, but it means a
  loaded run drifts from the one that was saved.
- **Spatial partitioning for obstacles.** The list is cached now, which was
  the big win, but it is still scanned linearly per bee. A grid would matter
  if obstacle counts rise a lot.
- **Bee update budgeting.** Every bee runs its full state machine every
  frame. At several hundred bees, staggering the expensive checks (work
  searches, not movement) across frames would be the next thing to do.
