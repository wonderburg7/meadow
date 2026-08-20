# Meadow — design backlog

Ideas agreed but deliberately **not** built yet. Kept here so the code stays
focused on what's actually in the game, and so nothing gets lost between
sessions. Nothing in this file is implemented.

Last updated: 20 Aug 2026 -- section 7.3 (predators) now has a full design
rather than just a confirmation, extended the same day with spider
movement and a narrower recruitment-suppression rule. See
`CRAB_SPIDER_PLAN.md` for the complete plan, worked out from a planning
conversation plus research into real crab spider (Thomisidae) ecology.
Nothing built yet.

Previously updated 19 Aug 2026 — added section 11, one product decision that
fell out of the two-report technical audit (`AUDIT_PLAN.md`): whether
ordinary player save/load should work during an active Challenge.

Previously updated 19 Aug 2026 — Challenge 1 (`TUTORIAL_PLAN.md`) is now
built and playable end to end: both technical prerequisites in section
1 and section 5 (the `levels.gd` restructure and the tutorial
checkpoint system) are done, plus the new UI-unlock and Dr Gallerin
machinery the plan called for (`stage_gate.gd`, `gallerin_panel.gd`,
`challenge_runner.gd`). See `NEXTSTEPS.md` for what's still open —
Challenge 2 has no stage data yet, and Challenge 1 wants Dave's
hands-on confirmation after two rounds of hands-on-testing fixes.

Previously updated 18 Aug 2026 — the scouting/floral-constancy/recruitment
split (`docs/archive/SCOUTING_TOGGLE_PLAN.md`) is now built: the old single
`auto_foraging_on` toggle is four toggles forming a dependency tree
(`orientation_flight_on`, `scouting_on`, `floral_constancy_on`,
`auto_recruitment_on`, the last renamed from `auto_foraging_on`), a
scouting bee now actually keeps the start point it found (previously
only the species survived), and the recruitment thresholds are split
into nectar/pollen pairs with mentor/seeker matching now
resource-specific in both directions. See `bee_foraging.gd`
(`take_orientation_flight`, `start_scouting`, `_score_trip`,
`wait_at_entrance`), `debug_panel.gd`'s `TOGGLE_PREREQUISITE` for the
cascade wiring, and section 5 below for the still-unsimulated
threshold numbers. Needs Dave's hands-on check in Godot — see
`NEXTSTEPS.md`.

Previously updated 18 Aug 2026 — resolved part of section 1 (the tutorial's
menu terminology and the levels-1/2 supersede rule) and extended
section 5 (the tutorial checkpoint system), both from the Challenge
1/2 tutorial plan agreed the same day. See `TUTORIAL_PLAN.md` for the
full design.

Previously updated 17 Aug 2026, added section 10 (bee individuality, the
lineage/inheritance piece deferred out of the plan agreed the same day,
see `docs/archive/BEE_INDIVIDUALITY_PLAN.md` for what's in scope for the
first slice).

Previously updated 17 Aug 2026 — removed 7.1 (foraging memory and recruitment)
and 8 (floral constancy — automatic component), now built as one combined
mechanism (they shared the entrance-wait exchange). See `bee_foraging.gd`
(`start_scouting`, `wait_at_entrance`, `_score_trip`), `hive.gd`
(`entrance_mentors`) and `GameConfig.auto_foraging_on`. The Foraging
window (collection-rate breakdown, heatmap) and per-hive-cell preference
setting that both sections mentioned as accompanying UI are **not** built
— see section 5.

Previously updated 16 Aug 2026 — removed 7.4 (fog of war), now built. See
`fog_of_war.gd`.

Previously updated 14 Aug 2026 — added sections 6–8 (sprite readiness,
meadow engagement, floral constancy automation), recorded from a
planning conversation.

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

**Done, 19 Aug 2026:** `LEVELS` extracted out of `main.gd` into its own
`levels.gd` data file (`main.Levels.LEVELS`), each entry now carrying
empty `unlocks` and `win_conditions` arrays alongside the starting-state
fields that were already there. Challenge 1's actual sub-stage data
(goals, unlocked UI keys, Dr Gallerin prompts) lives separately in
`challenge_runner.gd`'s `STAGES` rather than inside `levels.gd` itself
— see that file's own header comment for why the split landed there.

**Menu terminology and the levels 1/2 supersede rule (agreed 18 Aug,
full detail in `TUTORIAL_PLAN.md`) — done, 19 Aug 2026:** the opening
menu (`main_menu.gd`) splits `LEVELS` into two labelled groups rather
than one flat list. **Challenges** are the new staged, scripted entries
(Challenge 1: First Stores — built; Challenge 2: Brood, Roles and
Expansion — menu entry only, no stage data yet) — "levels" only
internally, "Challenges" in every player-facing surface. **Starter
modes** are the existing plain starting-point presets (`LEVELS` 3, 4
and 5), relabelled 1-3 for display but otherwise unchanged. Challenge
1's starting state, sub-stages and UI unlocks now supersede what
`LEVELS` 1 used to be, exactly as agreed; Challenge 2 (`LEVELS` 2)
hasn't been superseded yet since it has no stage data.

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
- **Tutorial checkpoint/rollback system (agreed 18 Aug, full detail in
  `TUTORIAL_PLAN.md`) — built 19 Aug 2026, `tutorial_checkpoint.gd`.**
  Reuses `save_game.gd`'s serialise/deserialise routines (both given an
  optional `path` parameter for this) against a separate
  `user://tutorial_checkpoint.save`, one rolling checkpoint, never
  touching the player's own save slot. `challenge_runner.gd` writes one
  at every Challenge 1 sub-stage boundary as designed. Still genuinely
  untested in the sense that matters: Challenge 1 has no defined
  failure condition, so nothing has ever called `.restore()` yet — that
  only happens once Challenge 2's stage data defines a real soft-failure
  case. Could eventually share plumbing with proper save slots once
  those exist, but doesn't depend on them.
- **Flower regrowth on load.** Cluster centres aren't saved, so the meadow's
  patchiness gradually re-randomises after loading. Harmless, but it means a
  loaded run drifts from the one that was saved.
- **Spatial partitioning for obstacles.** The list is cached now, which was
  the big win, but it is still scanned linearly per bee. A grid would matter
  if obstacle counts rise a lot.
- **Bee update budgeting.** Every bee runs its full state machine every
  frame. At several hundred bees, staggering the expensive checks (work
  searches, not movement) across frames would be the next thing to do.
- **A Foraging window.** Deferred from the auto-scouting/recruitment work
  (17 Aug) — collection-rate data broken down by flower/species and area,
  plus a heatmap, so the player can judge whether the mechanism (and their
  `recruit_lower/upper_threshold` settings) are actually working rather
  than trusting it blindly.
- **Per-hive-cell flower preference.** Also deferred from the same work —
  a cell already sets a hatching bee's role and focus (`hatch_role`,
  `hatch_focus` in `hive_cell.gd`/`hud.gd`); a preferred species should
  follow the same pattern, so a cell can raise foragers already committed
  to a species rather than only settable after the bee exists (and, for
  now, only reachable by disabling Auto scouting or waiting for it to run).
- **Auto-recruitment thresholds are unsimulated.** `GameConfig.recruit_lower/
  upper_threshold_nectar` (0.5 / 2.0 resource units/sec), the `_pollen` pair
  (0.2 / 0.8, scaled off nectar's by the two collection rates' ratio, an even
  rougher guess) and `forage_start_radius` (200px) are starting guesses, not
  backed by a throwaway model per rule 4 — tune live in the settings window
  and watch whether scouting/recruitment actually change collection rates
  before trusting the defaults.

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
  the 4fps investigation (`perf.gd`, `docs/performance.md`): instrument first,
  then compare sprite mode against polygon mode at the colony sizes
  already used for that investigation.

---

## 7. Making the meadow more engaging (agreed direction, not built)

Most decisions currently happen in the hive; the meadow is largely bees
walking to the nearest acceptable flower on their own. Several ideas
below, in the order Dave wants to take them.

### 7.2 Patch depletion made visible

Agreed to build. `flower.gd` already fades and shrinks a flower as it
drains; extend this so a fully stripped patch leaves visibly bare,
slowly-recovering ground, so the meadow visibly changes over a season
rather than reading as static once you've learned where the flowers
are.

### 7.3 Predators / ambush threats

Agreed to build (was an open question on `ROADMAP.md` — now confirmed
as a future item, not shelved). The existing "floral ambush predators
(crab spiders and the like)" note in section 3's win-condition pool is
the same idea.

**Full design done, 20 Aug 2026, extended same day -- see
`CRAB_SPIDER_PLAN.md`.** Starting with crab spiders specifically: an
ambush predator that waits, invisible to the player except for a brief
flash when it strikes or relocates, on one flower of whichever species
this run has randomly decided is dangerous (rolled per run, not fixed,
so a player can't permanently write off one species). It moves to a new
flower after a set residency time, and immediately if its current flower
dies, rather than staying on one flower for that flower's whole life. A
forager is only at risk once it actually starts feeding, not while
inspecting -- grounded in real crab spider ecology (Thomisidae attack
from a fixed ambush position, usually miss, favour pale/yellow flowers,
and do relocate once a flower stops paying off) researched for this
plan. Kills reuse the existing `BeeSurvival.die()`/epitaph path
unchanged. An escaped bee gets a long flower-specific cooldown and,
behind a toggle, stops recruiting other bees at the entrance exchange --
only for as long as her own start point and preferred species stay the
same as they were at the attack; moving on herself lifts it. A marker
left on the flower by any attack is the basis of an "alarm pheromone"
sense that would let a bee notice and leave before ever feeding there --
no skill tree exists yet to hang that on, so the plan builds it as a
working global toggle explicitly labelled as a placeholder for a future
per-bee/per-colony unlock. Floral constancy (already built) becomes the
main defence for free, with no new code -- a forager pinned to a safe
species never visits the dangerous one. Whole feature ships off by
default (`GameConfig.predators_on = false`). Every quantity (spider
rarity, attack success chance, residency time, cooldowns) is a starting
guess pending a throwaway model per rule 4 -- see the plan's own "before
implementing" section. Dave has also flagged bees fighting back and
killing a spider (eventually generalising to colony/wasp "fights") as a
wanted future mechanism -- not part of this build, noted in the plan's
deferred section. The logic lives in a new `crab_spider.gd` module
(same shape as `bee_survival.gd`/`bee_foraging.gd`) rather than being
folded into `flower.gd`/`bee_foraging.gd` directly, and the plan is now
split into six sequential bundles -- foundations/spawning/movement,
attack resolution, recruitment suppression, alarm pheromone, balance
modelling, closeout -- each meant for its own Claude Code session, with
its own check before the next one starts. See `CRAB_SPIDER_PLAN.md`'s
"Implementation bundles" section.

### 7.4 Weather beyond rain

Agreed to build. Wind, cold snap, heatwave — see the existing
candidate list in section 4. Confirmed wanted, detail not yet worked
out.

---

## 9. Follow-ups from the 14 Aug blueprint pass (hex redesign, winter fix, cog rename)

Two loose ends from the `docs/archive/NEW_FEATURES_BLUEPRINT.md`
implementation, recorded so they don't get lost:

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

---

## 10. Bee individuality: lineage inheritance (deferred slice)

The first slice of bee individuality (a rolled stat trait, a generated
name and fact, cosmetic jitter, milestone bees, death epitaphs,
favourite-bee pinning) is planned and ready to build, see
`docs/archive/BEE_INDIVIDUALITY_PLAN.md`. One reading of `ROADMAP.md`'s existing
"gynes carry it forward" line is deliberately left out of that slice
and recorded here instead.

**The question:** does a trait "carrying forward" mean only that a
gyne keeps her own rolled trait when she leaves the colony (trivial,
already covered by saving the trait on the bee), or that a colony she
goes on to found should bias its own new bees' rolls toward her trait,
a genetics/lineage mechanic?

**Why it's parked:** there's no simulation of a founded colony to
attach lineage to yet, a gyne currently just leaves and becomes a
scoreboard number (`bee.gd::leave_to_found_colony()`). Building
inheritance before that exists would be designing a system with
nowhere to plug in.

**Worth doing once a founded colony is simulated:** track which bee
(if any) a new bee's trait was biased from, and nudge the direction
weight or magnitude bands in that bee's favour rather than copying the
trait outright, keeps every bee still an individual roll rather than a
clone of her mother.

---

## 11. Ordinary save/load during an active Challenge (decision needed)

Fell out of the technical audit (`AUDIT_PLAN.md` Bundle A), recorded here
because it's a player-facing behaviour choice, not just an engineering
fix.

**The problem:** `SaveGame` doesn't record Challenge state (stage index,
which UI is unlocked, which Dr Gallerin prompts have fired, tutorial
checkpoint status). If a player saves mid-Challenge and reloads, none of
that comes back — the world state would restore but the Challenge would
be out of sync with it.

**Default assumed in `AUDIT_PLAN.md`:** hide/disable the ordinary
save/load buttons while a Challenge is active, and rely on
`tutorial_checkpoint.gd`'s own rolling checkpoint for in-Challenge
rollback instead. This is the cheap, safe option — Challenges are short
(5-10 minutes) so losing the ability to save mid-Challenge costs little,
and it avoids designing a Challenge-aware save schema before there's a
second Challenge to prove the shape of that data.

**The alternative**, not being built now: extend `SaveGame` to serialise
Challenge state properly, so ordinary save/load works everywhere. Worth
revisiting once Challenge 2 exists and there's a real second data point
for what "Challenge state" needs to hold — designing that schema off one
Challenge risks getting it wrong.

**Status:** proceeding with the default above in `AUDIT_PLAN.md` Bundle A
unless Dave says otherwise.
