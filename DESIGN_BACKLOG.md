# Meadow — design backlog

Ideas agreed but deliberately **not** built yet. Kept here so the code stays
focused on what's actually in the game, and so nothing gets lost between
sessions. Nothing in this file is implemented.

Last updated: 14 Aug 2026 — added sections 6–8 (sprite readiness, meadow
engagement, floral constancy automation), recorded from a planning
conversation. Nothing in these new sections is built; no code changed
alongside this update.

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

---

## 6. Sprite readiness (agreed direction, not built)

Dave will want to add sprites in place of the current placeholder art at
some point, and wants to be able to toggle back to the current simple
graphics if sprites turn out too slow. Nothing here is built and no
restructure has been done for it yet — recorded so the shape of the
change is agreed before it's picked up.

**Current state.** Every visual in the game is a `Polygon2D`/`Line2D`
built procedurally through `shapes.gd` — bees, flowers, obstacles, soil
and rock blocks, the comb. There is no `Sprite2D`, `Texture` or
`AnimatedSprite2D` anywhere in the codebase yet.

**Suggested shape of the change, when it's picked up:**

- A single toggle, `Session.sprite_mode: bool` — a display preference,
  not a balance number, so it belongs in `Session` alongside
  `colour_blind_mode`, not `GameConfig`. This also matches the existing
  `GameConfig.scenery_on` precedent for toggling how something is drawn.
- Each visual-owning script (`bee.gd`, `flower.gd`, `obstacle.gd`,
  `soil_block.gd`, `rock_block.gd`, `hive_cell.gd`) gets a small
  `_build_visual()` that branches on the flag. The polygon path stays
  permanently as the fallback/toggle-back option, not something removed
  once sprites exist.
- Bees are the easiest retrofit: `bee.gd` already isolates the drawn
  body as its own child node (`body: Polygon2D`), separate from the
  outline, selection ring and label, so only that one node needs to
  become swappable.
- Sprites will likely need a facing direction, which the current circles
  don't. Worth checking what heading/velocity value `bee_movement.gd`
  already computes for steering before assuming one needs to be added.
- If the toggle should work live (not just at next boot), each drawable
  node needs a `refresh_visual()` callable across its group (`bees`,
  `flowers`, `obstacles`, `soil_blocks`, `rock_blocks`) rather than
  requiring a restart to compare.
- Worth fixing an `assets/sprites/...` folder convention before any art
  exists, so it has a stable home from the start.
- Performance must be measured, not assumed — use the same method as
  the 4fps investigation (`perf.gd`, `PERF_PLAN.md`): instrument first,
  then compare sprite mode against polygon mode at the colony sizes
  already used for that investigation.

---

## 7. Making the meadow more engaging (agreed direction, not built)

Most decisions currently happen in the hive; the meadow is largely bees
walking to the nearest acceptable flower on their own. Several ideas
below, in the order Dave wants to take them.

### 7.1 Foraging memory and recruitment

The most-requested-feeling gap on `ROADMAP.md`, but Dave's explicit
condition: **it has to be shown to actually increase resource
collection before it's trusted**, not just built and assumed to help —
foragers are already collecting fine on their own. This is the same
rule `CLAUDE.md` already has for balance numbers ("never trust a
balance number that hasn't been simulated") — this needs a throwaway
model or a measured before/after comparison, not a build-and-hope.

**Open question, to work out alongside the mechanism:** what makes one
patch "good" compared to another. The mechanism below assumes a
per-bee resource collection rate (amount collected, factored by time
taken) as the measure, but the exact definition still needs settling.

**Mechanism, as Dave drafted it 14 Aug:**

- Each forager tracks its own average resource collection rate.
- Two player-tunable thresholds, a lower and an upper. Where a bee sits
  relative to them decides what happens after it deposits its last
  batch:
  - **Below the lower threshold** — the bee waits at the hive entrance
    (inside) for ten seconds after depositing, receptive to being
    influenced by a bee above the upper threshold if one is there.
  - **Above the upper threshold** — the bee also waits at the entrance
    for ten seconds after depositing, willing to pass on its flower
    preference and starting location to an under-threshold bee it
    meets there.
  - **Between the two thresholds** — the bee does neither; it goes
    straight back out.
- If an under-threshold bee meets an over-threshold bee at the
  entrance within its ten seconds, it adopts the over-threshold bee's
  flower preference and starting location.
- If an under-threshold bee's ten seconds pass with no over-threshold
  bee arriving, it picks a new flower preference and starting location
  of its own rather than repeating the same low-performing pattern.
- The two thresholds need to be tunable by the player (fits the
  existing settings window pattern in `debug_panel.gd`/`GameConfig`),
  since what counts as "good enough" will vary by hive setup.
- Scouting-phase bees (see section 8) use the same entrance-waiting
  behaviour as under-threshold bees, and can be influenced the same
  way by an over-threshold bee they encounter there.

**New UI to support this — a Foraging window:**

- Collection-rate data broken down by flower/species and by area, so
  the player has the information to judge whether the mechanism (and
  their threshold settings) are actually working, not just trust it
  blindly.
- A heatmap option showing how much of a given resource is being
  collected in a given area, to help spot where the good patches
  actually are.

### 7.2 Patch depletion made visible

Agreed to build. `flower.gd` already fades and shrinks a flower as it
drains; extend this so a fully stripped patch leaves visibly bare,
slowly-recovering ground, so the meadow visibly changes over a season
rather than reading as static once you've learned where the flowers
are.

### 7.3 Predators / ambush threats

Agreed to build (was an open question on `ROADMAP.md` — now confirmed
as a future item, not shelved). Detail still to be worked out; the
existing "floral ambush predators (crab spiders and the like)" note in
section 3's win-condition pool is the same idea.

### 7.4 Fog of war

Agreed to build. Not previously scoped — the goal is to make finding a
good patch feel like a discovery rather than something the player can
see laid out from the start. Listed as an unbuilt environment feature
in the original Game Outline; this confirms it's wanted, not just
raw material.

### 7.5 Weather beyond rain

Agreed to build. Wind, cold snap, heatwave — see the existing
candidate list in section 4. Confirmed wanted, detail not yet worked
out.

---

## 8. Floral constancy — automatic component (agreed direction, not built)

Currently 100% manual: select foragers, click "Pick a flower", click a
flower in the meadow (`input_selection._place_floral_preference`) →
`bee.set_preferred_species()`. Dave wants an automatic path that
doesn't rely on the player clicking every bee.

**Mechanism, as Dave drafted it 14 Aug — a scouting phase, not
richness-weighted pre-selection:**

- When a forager first emerges, it enters a scouting phase: it heads to
  a location a short, slightly randomised distance from the hive.
- It runs a full forage bout there (collect, return, deposit) on
  whichever species it first encounters.
- It repeats this for a second and then a third species — three bouts,
  three different species.
- It calculates each bout's resource collection rate (amount collected
  factored by time taken) and sets its permanent flower preference to
  whichever species scored highest.
- This is deliberately experiential rather than the richness-weighted
  "look before visiting" option considered earlier — the bee has to
  actually forage each species to judge it, not be handed the answer.
- While scouting, these bees use the same hive-entrance waiting
  behaviour as the under-threshold bees in section 7.1's recruitment
  mechanism, and can be influenced by an over-threshold bee they meet
  there — which would let a scouting bee adopt a known-good preference
  early and skip the rest of its own scouting bouts.

**Player control, alongside the automatic path:**

- A colony-level policy toggle for whether new foragers auto-scout.
- The existing per-bee click-to-set control stays.
- The same preference should also be settable per hive cell — a cell
  already sets a hatching bee's focus (`hatch_options` in `hud.gd`);
  flower preference should follow the same pattern rather than only
  being settable after a bee already exists.

---

## 9. Follow-ups from the 14 Aug blueprint pass (hex redesign, winter fix, cog rename)

Two loose ends from the `NEW_FEATURES_BLUEPRINT.md` implementation,
recorded so they don't get lost:

- **`GameConfig.hive_entrance_width` is now unused.** The new
  single-column entrance tunnel (`world_building.gd::_entrance_tiles`)
  doesn't need a width parameter — it always walks the `q = 0` column.
  Kept in `game_config.gd` only for old save-file compatibility.
  Decision needed whenever the entrance is revisited: repurpose it for
  a wider doorway (multiple columns) or drop it once `FORMAT_VERSION 1`
  saves are no longer worth supporting.
- **`GameConfig.winter_lifespan_factor = 4.0` (bees living longer
  through winter) is a starting guess, not yet backed by a full
  throwaway simulation.** `tests/balance_tests.py::test_winter()` only
  checks it gives ≥1.5x headroom against `winter_length_days` (came out
  at 5.0x) — it doesn't model population dynamics across a winter the
  way this project's rule 4 asks for. Worth a proper model before
  trusting the number, the same way the disease and forage balance
  numbers were modelled.
