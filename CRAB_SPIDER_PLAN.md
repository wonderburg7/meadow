# Crab spiders -- plan

Full design for `DESIGN_BACKLOG.md` §7.3 / `ROADMAP.md`'s "Predators" row
(confirmed wanted 14 Aug, detail worked out 20 Aug). **Nothing in this
file is built.** Written so Claude Code can implement it directly against
the code as it stands today, without a separate planning pass.

Status: plan only. When built, the whole feature stays off by default
(`GameConfig.predators_on = false`) until Dave turns it on to test.

---

## The idea in one paragraph

A crab spider waits, motionless, on one flower of whichever species this
run has decided is dangerous, moving on to a new flower every so often
and whenever its current one dies rather than staying for that flower's
whole life. It's invisible to the player except for a brief flash when
it strikes or relocates -- easy to miss, since the spider itself is tiny.
A forager that lands and inspects the flower is safe -- only a bee that
actually starts feeding is at risk, and even then the spider usually
misses. A bee that escapes remembers and avoids that flower for a long
time, and stops recruiting other bees towards wherever she was foraging
at the time -- but only for as long as she keeps foraging from the same
spot after that; once she moves on herself, so does the suppression. An
unlockable "alarm pheromone" sense (not built yet, this session put a
placeholder in its place) would let a bee notice a flower another bee
was attacked at and leave before ever being at risk.

---

## Biology this is grounded in

Real crab spiders (Thomisidae, chiefly *Misumena vatia* and relatives)
hunt this way almost exactly:

- **True ambush predators.** No web, no chase -- they sit on a flower and
  grab whatever lands within reach.
- **Colour-matched to specific flowers.** They favour pale/yellow flowers
  and some species slowly shift their own body colour to match the one
  they're sitting on over several days. This is why "which species is
  dangerous" is a real, learnable thing for a forager, not a random
  hazard.
- **They stay put.** Once settled, a spider holds a flower for hours; it
  only relocates once that flower stops paying off, and even then it
  almost never switches species (1 of 175 spiders tracked in one study
  changed species at all).
- **Attacks usually fail.** One milkweed study logged many attacks
  against six actual kills. Spiders attacked bumblebees more often but
  caught honeybees more often -- capture rate depends on the prey as much
  as the spider. Dave's ~5% instinct sits comfortably in the range the
  literature suggests.
- **Escaped bees leave.** Roughly 80% of bees that survive an attack
  abandon that flower outright rather than trying again.
- **Bees detect danger two ways in real life:** visually at very short
  range (avoidance starts within ~90-110mm of a spider), and by scent --
  88% of foragers rejected a feeder carrying spider odour alone in one
  choice test. Separately, honeybees are well documented to leave alarm
  pheromone at a site where an attack happened, which other foragers then
  detect and avoid. That second mechanism -- a mark left behind after an
  attack, read by later visitors -- is what "alarm pheromone" means here,
  and it maps directly onto the tarsal-marker mechanic `flower.gd`
  already has.

Sources: [Death by Crab Spider](https://awkwardbotany.com/2018/09/12/death-by-crab-spider-part-one/),
[Reproductive success and foraging of *Misumena vatia*](https://link.springer.com/article/10.1007/BF00379217),
[Foraging at a safe distance: crab spider effects on pollinators](https://labs.biology.ucsd.edu/nieh/papers/HueyNieh2017.pdf),
[Honey bee alarm pheromone in plant-pollinator-predator interactions](https://www.mdpi.com/2075-4450/10/10/366),
[Movement between flowers (Morse)](https://www.americanarachnology.org/journal-joa/joa-all-articles/article/download/arac_12_3_0307.pdf/?no_cache=1).

No bee anywhere in the codebase has "health" -- death is binary, always
through `BeeSurvival.die(bee, cause)`. This stays exactly that simple: a
successful ambush is an instant kill, not an injury state.

---

## Decisions taken this session (20 Aug, Dave)

| Question | Decision |
|---|---|
| Which species do spiders prefer? | **Rolled per run, not fixed.** So a player can't permanently write off one species. |
| Can an unskilled bee notice a spider at all? | **No.** No baseline detection -- the alarm-pheromone mark is the only tell, and only for a bee that has it. |
| How does "alarm pheromone" slot in without a skill tree? | **A working global toggle, explicitly labelled as a placeholder** for where a real per-bee/per-colony skill-tree unlock will eventually go. |
| How visible is a spider to the player? | **Invisible until it strikes, then briefly visible** (win or lose), then hidden again. |
| How long does a spider stay on one flower? | **Not for the flower's whole life.** It relocates after a set residency time, and immediately if its flower dies -- see "Movement", below. Relocating is visible the same way an attack is: a brief flash, easy to miss. |
| How long does recruitment suppression last? | **Until she moves on herself.** Not permanent -- it lifts as soon as the escaped bee's own start point and/or preferred species change from what they were at the moment of the attack, since that's what "no longer recruiting towards the dangerous area" actually means. |

**Noted for later, not part of this build:** Dave wants bees that can
fight back -- killing a crab spider rather than only fleeing it -- as a
future mechanism, one that could later be shared with colony-vs-colony
or wasp "fights". Nothing here builds that; see "Explicitly deferred"
at the end of this plan.

---

## Mechanic

### 1. Which species, and how many

At run start, roll one species as this run's crab spider target, weighted
by how plausible an ambush flower it is (paler/yellower species more
likely, but nothing at zero -- real crab spiders do occasionally turn up
somewhere surprising). Add a `crab_spider_weight` entry per species in
`flower.gd`'s `SPECIES` table, alongside the existing `weight` (which
governs how common the species is, a different thing):

```
Clover:   crab_spider_weight = 40   # yellow -- the classic ambush colour
Poppy:    crab_spider_weight = 25   # red, but wide open and much-visited
Foxglove: crab_spider_weight = 10   # pink/magenta, less typical
Borage:   crab_spider_weight = 5    # blue-violet, least typical, not zero
```

Store the roll on `Session` (run state, not a balance number -- see
`CLAUDE.md` rule 2, this is "which species this particular run picked",
exactly the kind of thing that belongs on `Session` alongside
`winter_here`, not `GameConfig`):

```
# session.gd
var crab_spider_preferred_species: String = ""
```

Roll it once, the first time `GameConfig.predators_on` is true and the
value is still unset (run start, or the moment the toggle is switched
on mid-run for testing). If the rolled species later goes out of season,
the predator naturally goes quiet along with it -- no special-casing
needed, there's simply nowhere for a spider to sit until it blooms again.

Rarity: when a flower of the preferred species is created (both at
world-seed and at every regrowth), roll `crab_spider_flower_fraction`
(starting guess 0.02) for whether it gets a spider. At the default
`flower_count` (500) and Clover's ~40% share of the species mix, that
puts roughly **4 spiders in the meadow at once** -- genuinely rare, not
something you trip over. **Not yet modelled -- CLAUDE.md rule 4 applies,
simulate before trusting.**

### 2. The flower gains state

New `flower.gd` fields:

```
var has_crab_spider: bool = false
var crab_spider_settled_at: float = -999.0      # sim-time the spider arrived here
var crab_spider_reveal_until: float = -999.0    # sim-time; drives the brief-visibility presentation
var crab_spider_alarm_at: float = -999.0        # sim-time of the last attack here
```

A spider isn't tied to one flower's lifetime any more -- see "Movement",
next.

### 3. Movement: residency and flower death

Real crab spiders hold a flower for hours, then move on once it stops
paying off -- and even then almost never travel far or switch species
(see the biology section above). Modelled here as one spider identity
that hands itself from flower to flower rather than a fresh spider
spawning and despawning each time, so relocating reads as the same
spider moving, not a new one appearing:

```
## Called when this flower's spider's residency is up, or when this
## flower is about to die with a spider still on it. Hands the spider to
## a new flower of the same species rather than letting it vanish --
## real spiders relocate rather than starve on a spent patch.
## `show_departure` is false when called from the dying-flower path,
## since this flower is being freed the same frame anyway and a flash
## here would be invisible.
func _relocate_crab_spider(show_departure: bool) -> void:
    if show_departure:
        crab_spider_reveal_until = Session.sim_time + GameConfig.crab_spider_reveal_seconds
    has_crab_spider = false
    var candidates: Array = []
    for f in get_tree().get_nodes_in_group("flowers"):
        if f == self or not is_instance_valid(f) or f.has_crab_spider:
            continue
        if f.species_name != species_name or not f.in_season():
            continue
        candidates.append(f)
    if candidates.is_empty():
        # Nowhere to go -- this spider is lost, much as a real one that
        # can't find fresh hunting ground eventually isn't found again.
        # The periodic spawn roll (see section 1) keeps numbers up over
        # time without this needing to guarantee a home.
        return
    var new_home: Node2D = candidates[randi() % candidates.size()]
    new_home.has_crab_spider = true
    new_home.crab_spider_settled_at = Session.sim_time
    new_home.crab_spider_reveal_until = Session.sim_time + GameConfig.crab_spider_reveal_seconds
```

Two call sites in `flower.gd::_process()`:

- **Residency timeout:** `if has_crab_spider and Session.sim_time -
  crab_spider_settled_at >= GameConfig.crab_spider_residency_seconds:
  _relocate_crab_spider(true)`. New `GameConfig.crab_spider_residency_seconds`
  -- starting guess **300.0** (one and a half in-game days at the default
  `seconds_per_day` of 200), long enough that a spider reads as settled
  rather than jumpy. **Not yet modelled.**
- **Flower death:** in the existing age-out block (`if age_seconds >=
  lifespan_seconds:`), before `queue_free()`, add `if has_crab_spider:
  _relocate_crab_spider(false)`.

Deliberately not distance-aware -- a relocation can land anywhere the
right species is currently blooming, not just nearby. Real spiders find
a short hop (2-5cm to an adjacent flower) far easier than a longer one,
but with only a handful of spiders in the whole meadow (see section 1)
and relocation itself a rare event, an honest scan of every flower on
each hop costs nothing worth optimising -- see `ROADMAP.md`'s own
"optimising a set too small to need it" note. Worth revisiting only if
spider counts grow a lot later.

### 4. Attack resolution

Bees are safe through `State.INSPECTING` -- a landed bee can still walk
away having learned nothing bad happened. Risk begins the instant a bee
actually starts feeding.

Hook into `bee_foraging.gd::start_collecting()` (currently just sets the
handling timer and state): if `GameConfig.predators_on` and
`bee.current_flower.has_crab_spider`, roll once against
`crab_spider_attack_success_chance` (starting guess **0.05**, per Dave's
own estimate and in the range the literature supports):

- **Hit (5%):** the spider caught her. `BeeSurvival.die(bee, "crab
  spider ambush")` -- reuses the existing death path exactly, so the
  epitaph toast ("X has died of crab spider ambush. <her fact>") needs
  no new code at all.
- **Miss (95%):** she escapes. Interrupt the visit -- don't enter
  `State.COLLECTING` for real. Set a much longer cooldown on this
  specific flower than an ordinary rejection gets
  (`crab_spider_escape_cooldown_seconds`, starting guess **120s**,
  against the ordinary `REJECTED_AVOID_SECONDS` of 15s in the same
  file) via the existing `bee.flower_cooldowns` mechanism, release the
  flower, and send her to `State.SEEK_FLOWER`. Also record the attack on
  the bee herself -- `was_attacked_by_predator = true`, plus a snapshot
  of `forage_start_point` and `preferred_species` at that moment (see
  §6, recruitment suppression, for why and how those get used).

Either outcome marks the flower (see next section) and triggers the
brief visual reveal.

### 5. The alarm-pheromone mark (placeholder skill)

Every attack -- hit or miss -- leaves a mark: `flower.crab_spider_alarm_at
= Session.sim_time`. This is deliberately a separate mark from the
existing tarsal marker (`marked_at`/`marked_by`) -- tarsal marks mean
"recently drained", this means "something was attacked here", and a
flower can carry both independently.

```
func is_predator_alarmed() -> bool:
    return Session.sim_time - crab_spider_alarm_at < GameConfig.crab_spider_alarm_marker_seconds
```

**Placeholder for the skill tree** (no skill tree exists yet -- see
`CLAUDE.md`'s project instructions): `GameConfig.alarm_pheromone_on`,
off alongside `predators_on`. While it's on, a bee reaching
`State.INSPECTING` at an alarmed flower notices and leaves before ever
risking `State.COLLECTING` there -- hook into `bee_foraging.gd::inspect()`
right where the existing tarsal-marker check already lives in
`worth_feeding()`, as a second, independent check. Label it clearly in
code and in the settings window (`debug_panel.gd`) as standing in for a
future per-bee/per-colony unlock rather than a permanent global toggle,
e.g. a tooltip: *"Alarm pheromone (placeholder -- will move to a skill
unlock once the skill tree exists)"*. The mechanic itself is real and
testable now; only the delivery method (global toggle vs. an actual
unlock) is temporary.

### 6. Recruitment suppression (toggle) -- scoped to "still pointing at danger"

Not a permanent mark against a bee -- it lifts as soon as she's no
longer actually recruiting other bees towards wherever the attack
happened. What she offers a recruit at the entrance exchange is her
`forage_start_point` and (under `floral_constancy_on`) her
`preferred_species` -- so "she's moved on" means either of those has
changed since the attack, not that any fixed amount of time has passed.

New bee fields, set at the moment of an escape (see §4):

```
var was_attacked_by_predator: bool = false
var attacked_at_start_point: Vector2 = Vector2(INF, INF)
var attacked_at_preferred_species: String = ""
```

```
# in the escape branch of start_collecting's attack roll:
bee.was_attacked_by_predator = true
bee.attacked_at_start_point = bee.forage_start_point
bee.attacked_at_preferred_species = bee.preferred_species
```

Gate in `bee_foraging.gd::go_to_exit()`, the existing entrance-mentoring
branch, by comparing her *current* start point/species against the
snapshot taken at the attack, rather than a one-off flag check:

```
var still_pointing_at_danger: bool = bee.was_attacked_by_predator \
        and bee.forage_start_point == bee.attacked_at_start_point \
        and bee.preferred_species == bee.attacked_at_preferred_species
elif past_grace and bee.avg_collection_rate > upper \
        and not (GameConfig.crab_spider_recruit_suppression_on and still_pointing_at_danger):
    bee.hive.add_entrance_mentor(bee)
    ...
```

This is deliberately comparison-based rather than clearing the flag the
moment something changes -- `forage_start_point` and `preferred_species`
already get rewritten from several places (re-scouting, being matched
with a mentor herself, the entrance-wait timeout resetting a stale
preference), and comparing at the point of use catches all of them for
free rather than needing a clear-the-flag hook added at every one of
those sites, including any added later. She can still forage and still
ask for help as a seeker throughout -- this only ever stops her
recruiting others, never her own foraging. Depends on `predators_on`,
same cascade shape as `scouting_on`/`floral_constancy_on`/
`auto_recruitment_on`.

### 7. Presentation -- hidden except for a brief flash

No icon, no fog-of-war reveal, no warning while a spider is simply
sitting there. Two moments make it flash briefly into view --
`crab_spider_reveal_until = Session.sim_time +
GameConfig.crab_spider_reveal_seconds` (starting guess **1.5s**):

- **An attack**, hit or miss (see §4).
- **A relocation**, at the new flower always, and at the old one too
  unless it's relocating because it's dying (see §3 -- `show_departure`).

Either way it then fades from view again. This is purely presentational:
a small dark shape at the flower's centre, in the same procedural-
`Polygon2D` style as everything else in the game right now (see
`DESIGN_BACKLOG.md` §6, sprite readiness -- this follows the
placeholder-art convention already in use, not ahead of it). A
relocation doesn't get a toast -- only the flash -- since it isn't a
meaningful event to announce and would get repetitive over a run; a kill
and an escape both do (next paragraph).

A kill's epitaph toast and a miss's warning both come free from existing
channels: `_announce_death` for a kill, and a lighter, throttled
`hud.show_warning` call for a miss (reuse the `epitaph_min_gap`-style
throttle pattern so a bad patch of attacks can't spam the corner --
`crab_spider_escape_min_gap` or similar).

A dev-only reveal toggle (`Session.show_crab_spiders` or similar, same
pattern as `Session.show_flower_amounts`) is worth adding for Dave's own
testing, surfaced in `debug_panel.gd` -- without it, testing this blind
is painful.

### 8. Floral constancy interaction -- no new code needed

This falls out for free. A forager with a fixed `preferred_species` (or
one currently `is_scouting` toward a species under `floral_constancy_on`)
naturally never visits the dangerous species if the player steers it
elsewhere, and naturally eats all the risk if it's pinned to the one
species that happens to be dangerous this run. Worth a line in
`hud.gd`/tooltips once built, but nothing mechanical to add -- this is
exactly the "floral constancy becomes a real commitment" effect Dave
asked for, and it's already latent in `bee_foraging.gd::nearest_flower`.

---

## Data model additions (summary)

**`flower.gd`**
- `SPECIES` table: new `crab_spider_weight` per entry.
- New fields: `has_crab_spider`, `crab_spider_settled_at`,
  `crab_spider_reveal_until`, `crab_spider_alarm_at`.
- New methods: `is_predator_alarmed()`, `_relocate_crab_spider(show_departure)`.

**`game_config.gd`** (all off/starting-guess, none simulated yet -- rule 4)
```
var predators_on: bool = false
var crab_spider_flower_fraction: float = 0.02
var crab_spider_attack_success_chance: float = 0.05
var crab_spider_escape_cooldown_seconds: float = 120.0
var crab_spider_residency_seconds: float = 300.0
var crab_spider_reveal_seconds: float = 1.5
var crab_spider_alarm_marker_seconds: float = 40.0
var alarm_pheromone_on: bool = false
var crab_spider_recruit_suppression_on: bool = false
```

**`session.gd`**
```
var crab_spider_preferred_species: String = ""
```

**`bee.gd`**
```
var was_attacked_by_predator: bool = false
var attacked_at_start_point: Vector2 = Vector2(INF, INF)
var attacked_at_preferred_species: String = ""
```

**Touch points:** `bee_foraging.gd` (`start_collecting`, `inspect`/
`worth_feeding`, `go_to_exit`), `flower.gd` (spawn roll, draw, the new
residency/death relocation logic), wherever flowers are seeded/regrown
(`world_building.gd` or `main.gd`, wherever `Flower.setup` is currently
called), `debug_panel.gd` (three new toggles plus the dev reveal toggle,
wired into the `TOGGLE_PREREQUISITE` cascade alongside the existing
scouting/constancy/recruitment tree), `session.gd`
(the roll + dev reveal flag).

No new `Bee.State` values are needed -- the attack resolves as a single
roll at the moment `State.COLLECTING` begins, not as its own state.

---

## Before implementing: check, don't assume

- **Save/load.** `DESIGN_BACKLOG.md` §5 notes flower cluster centres
  aren't currently saved and the meadow re-randomises a bit on load.
  Check `save_game.gd`'s actual flower/bee serialisation before deciding
  whether `has_crab_spider`/`crab_spider_settled_at`/
  `was_attacked_by_predator` and its two snapshot fields need saving, or
  whether (like cluster centres) it's fine for them to reset -- a spider
  simply re-rolling its position on load is probably an acceptable loss,
  same reasoning as the flower it's sitting on.
- **`FUNCTION_MAP.md`.** If this touches `bee.gd` or `hud.gd`
  meaningfully, regenerate with `tools/update_function_map.py` per
  `CLAUDE.md`.
- **Balance numbers.** Every number above is a starting guess, not a
  simulated one. Per `CLAUDE.md` rule 4, model spider count vs. forager
  losses in a throwaway Python script (`tests/balance_tests.py` is the
  natural home) before trusting `crab_spider_flower_fraction` and
  `crab_spider_attack_success_chance` against actual colony sizes --
  the failure mode to check for is a colony's forage income taking a
  real, felt hit rather than staying "rare enough not to notice
  mechanically, present enough to notice narratively."

---

## Explicitly deferred, not part of this build

- **A real skill tree.** `alarm_pheromone_on` is a stand-in; the actual
  unlock UI/progression system is a separate, larger piece of work (see
  the "raw material, not scoped" note in `CLAUDE.md`'s project
  instructions).
- **Bees fighting back.** Dave wants bees able to kill a crab spider
  rather than only ever fleeing or dying, as a future addition -- and
  wants whatever resolves that combat built so it can later be reused
  for colony-vs-colony or wasp "fights", rather than being crab-spider-
  specific. Nothing here builds that. Worth keeping in mind once it's
  picked up: the attack-resolution shape in section 4 (a single
  success-chance roll between two parties, one of whom may die) is
  already close to generic -- a future combat mechanism could plausibly
  generalise that roll rather than replace it, but that's a decision for
  whenever it's actually scoped, not now.
- **Distance-aware relocation.** See section 3 -- a spider currently
  jumps to any eligible flower of its species, not preferentially a
  nearby one.
- **More than one preferred species per run**, or a species mix that
  changes mid-run.
- **Other ambush predator types** (crab spiders are explicitly the
  first of a category -- "and the like" per `DESIGN_BACKLOG.md` §3/§7.3
  -- but nothing here generalises the system yet; that's worth doing once
  a second predator type is actually wanted, not speculatively now).
- **Win/loss conditions built around predators** -- `DESIGN_BACKLOG.md`
  §3 lists "a system to survive floral ambush predators" as a candidate
  win condition; this plan only builds the predator itself.
