# Crab spiders -- plan

Full design for `DESIGN_BACKLOG.md` §7.3 / `ROADMAP.md`'s "Predators" row
(confirmed wanted 14 Aug, detail worked out 20 Aug, extended same day
with movement, a narrower recruitment rule, and this bundle breakdown).
**Nothing in this file is built.** Written so Claude Code can implement
it directly against the code as it stands today, one bundle at a time,
without a separate planning pass.

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

## Architecture: one small new module, not more logic bolted into flower.gd/bee_foraging.gd

New file `scripts/crab_spider.gd` -- `extends RefCounted`, static
functions that take a `flower`/`bee` node and act on it, exactly the
shape `bee_survival.gd`/`bee_foraging.gd`/`roles.gd` already use (see
`BEE_SPLIT_PLAN.md`'s own reasoning: a leaf file with no dependencies of
its own beyond what it's handed, so nothing has to preload the world to
use it). `flower.gd` and `bee_foraging.gd` each gain only a handful of
call-out lines into this module at their existing hook points --
`_process()`, `start_collecting()`, `inspect()`, `go_to_exit()` -- not
new logic written inline into either file.

**Why a new file rather than growing the two existing ones directly:**
predator behaviour is a distinct concern from "what a flower is" or "how
a bee forages", crab spiders are already flagged as the first of a
category (`DESIGN_BACKLOG.md` §3/§7.3 says "and the like"), and Dave has
separately flagged wanting the attack-resolution shape reused for a
future combat mechanism (bees fighting back, then colony/wasp fights).
One small, growing file gives a second predator type, or that combat
generalisation, one obvious place to start from later, instead of logic
that has to be pulled back out of `flower.gd` and `bee_foraging.gd`
after the fact.

**Why not go further and build a generic `predator.gd`/combat framework
now:** there's only one predator type and no second concrete case yet to
design a shared base against -- the same reasoning `DESIGN_BACKLOG.md`
section 10 already uses to defer lineage inheritance until there's an
actual founded colony to attach it to. Building the general shape before
a second case exists risks guessing wrong about what it needs to share.
`crab_spider.gd` stays crab-spider-specific; a future predator or combat
piece can lift the parts that turn out to generalise once it exists to
prove what those are.

`crab_spider.gd` grows one function per bundle below -- see "Implementation
bundles" for the split. `flower.gd`, `bee.gd` and `session.gd` hold only
plain data fields, no predator logic of their own, matching how `bee.gd`
already holds every field while the `bee_*.gd` files hold the logic that
acts on them.

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
| How should the build be structured for Claude Code? | **Bundles, one per sequential session/thread**, each independently buildable and checkable -- see "Implementation bundles" below. Chosen to keep each thread's own context small (token efficiency) and to keep runtime cost reviewed at the point each piece is added (process efficiency), not as one large after-the-fact pass. |

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

`CrabSpider.roll_preferred_species()` (new, in `crab_spider.gd`) does the
weighted pick, the same shape as `Flower.pick_species_index()` already
uses. Store the result on `Session` (run state, not a balance number --
see `CLAUDE.md` rule 2, this is "which species this particular run
picked", exactly the kind of thing that belongs on `Session` alongside
`winter_here`, not `GameConfig`):

```
# session.gd
var crab_spider_preferred_species: String = ""
```

Roll it once, the first time `GameConfig.predators_on` is true and the
value is still unset (run start, or the moment the toggle is switched on
mid-run for testing). If the rolled species later goes out of season,
the predator naturally goes quiet along with it -- no special-casing
needed, there's simply nowhere for a spider to sit until it blooms again.

Rarity: `CrabSpider.maybe_spawn(flower)` is called wherever a flower of
the preferred species is created (both at world-seed and at every
regrowth), and rolls `crab_spider_flower_fraction` (starting guess 0.02)
for whether it gets a spider. At the default `flower_count` (500) and
Clover's ~40% share of the species mix, that puts roughly **4 spiders in
the meadow at once** -- genuinely rare, not something you trip over.
**Not yet modelled -- CLAUDE.md rule 4 applies, simulate before
trusting** (see Bundle 5, below).

### 2. The flower gains state

New `flower.gd` fields (plain data only -- see "Architecture" above):

```
var has_crab_spider: bool = false
var crab_spider_settled_at: float = -999.0      # sim-time the spider arrived here
var crab_spider_reveal_until: float = -999.0    # sim-time; drives the brief-visibility presentation
var crab_spider_alarm_at: float = -999.0        # sim-time of the last attack here
```

### 3. Movement: residency and flower death

Real crab spiders hold a flower for hours, then move on once it stops
paying off -- and even then almost never travel far or switch species
(see the biology section above). Modelled here as one spider identity
that hands itself from flower to flower rather than a fresh spider
spawning and despawning each time, so relocating reads as the same
spider moving, not a new one appearing:

```
## crab_spider.gd
## Called when a flower's spider's residency is up, or when that flower
## is about to die with a spider still on it. Hands the spider to a new
## flower of the same species rather than letting it vanish -- real
## spiders relocate rather than starve on a spent patch.
## `show_departure` is false when called from the dying-flower path,
## since that flower is being freed the same frame anyway and a flash
## there would be invisible.
static func relocate(flower: Node2D, show_departure: bool) -> void:
    if show_departure:
        flower.crab_spider_reveal_until = Session.sim_time + GameConfig.crab_spider_reveal_seconds
    flower.has_crab_spider = false
    var candidates: Array = []
    for f in flower.get_tree().get_nodes_in_group("flowers"):
        if f == flower or not is_instance_valid(f) or f.has_crab_spider:
            continue
        if f.species_name != flower.species_name or not f.in_season():
            continue
        candidates.append(f)
    if candidates.is_empty():
        # Nowhere to go -- this spider is lost, much as a real one that
        # can't find fresh hunting ground eventually isn't found again.
        # The periodic spawn roll (section 1) keeps numbers up over time
        # without this needing to guarantee a home.
        return
    var new_home: Node2D = candidates[randi() % candidates.size()]
    new_home.has_crab_spider = true
    new_home.crab_spider_settled_at = Session.sim_time
    new_home.crab_spider_reveal_until = Session.sim_time + GameConfig.crab_spider_reveal_seconds
```

Also add `CrabSpider.update(flower, delta)`, called from
`flower.gd::_process()`, holding the residency check:

```
static func update(flower: Node2D, _delta: float) -> void:
    if not flower.has_crab_spider:
        return
    if Session.sim_time - flower.crab_spider_settled_at >= GameConfig.crab_spider_residency_seconds:
        relocate(flower, true)
```

The `if not flower.has_crab_spider: return` guard means this costs
essentially nothing for the ~496 of 500 flowers that never carry a
spider -- one boolean check, not a real per-frame cost, so it doesn't
need its own `Perf.begin`/`Perf.end` section (see `CLAUDE.md` on
measuring rather than guessing -- worth confirming with `perf.gd` once
built if that assumption ever looks wrong, but no reason to expect it
will at ~4 spiders in 500 flowers).

New `GameConfig.crab_spider_residency_seconds` -- starting guess **300.0**
(one and a half in-game days at the default `seconds_per_day` of 200),
long enough that a spider reads as settled rather than jumpy. **Not yet
modelled.**

Flower death: in `flower.gd::_process()`'s existing age-out block (`if
age_seconds >= lifespan_seconds:`), before `queue_free()`, add `if
has_crab_spider: CrabSpider.relocate(self, false)`.

Deliberately not distance-aware -- a relocation can land anywhere the
right species is currently blooming, not just nearby. Real spiders find
a short hop (2-5cm to an adjacent flower) far easier than a longer one,
but with only a handful of spiders in the whole meadow and relocation
itself a rare event (roughly once per residency window per spider, plus
occasional flower deaths), an honest scan of every flower on each hop
costs nothing worth optimising -- see `ROADMAP.md`'s own "optimising a
set too small to need it" note, and it only runs on that rare event, never
per frame. Worth revisiting only if spider counts grow a lot later.

### 4. Attack resolution

Bees are safe through `State.INSPECTING` -- a landed bee can still walk
away having learned nothing bad happened. Risk begins the instant a bee
actually starts feeding.

`CrabSpider.resolve_attack(bee)`, called from
`bee_foraging.gd::start_collecting()` (currently just sets the handling
timer and state) right after the existing `leave_marker` call, only if
`GameConfig.predators_on and bee.current_flower.has_crab_spider`:

```
## crab_spider.gd
## Rolls one attack. Returns true if the bee is still alive and should
## carry on into State.COLLECTING as normal; false if she died (caller
## does nothing further -- BeeSurvival.die already handled everything)
## or escaped (caller must not enter State.COLLECTING).
static func resolve_attack(bee: Node2D) -> bool:
    var flower: Node2D = bee.current_flower
    flower.crab_spider_alarm_at = Session.sim_time
    flower.crab_spider_reveal_until = Session.sim_time + GameConfig.crab_spider_reveal_seconds
    if randf() < GameConfig.crab_spider_attack_success_chance:
        BeeSurvival.die(bee, "crab spider ambush")
        return false
    # escaped
    bee.flower_cooldowns[flower] = Session.sim_time + GameConfig.crab_spider_escape_cooldown_seconds
    bee.was_attacked_by_predator = true
    bee.attacked_at_start_point = bee.forage_start_point
    bee.attacked_at_preferred_species = bee.preferred_species
    flower.release(bee)
    bee.current_flower = null
    bee.state = BeeEnums.State.SEEK_FLOWER
    bee.world.hud.show_warning(...)   # throttled -- see section 7
    return false
```

- **Hit (starting guess 5%):** the spider caught her. `BeeSurvival.die`
  reuses the existing death path exactly, so the epitaph toast ("X has
  died of crab spider ambush. <her fact>") needs no new code at all.
- **Miss (95%):** she escapes, with a much longer cooldown on this
  specific flower than an ordinary rejection gets
  (`crab_spider_escape_cooldown_seconds`, starting guess **120s**,
  against the ordinary `REJECTED_AVOID_SECONDS` of 15s in
  `bee_foraging.gd`), and a snapshot of where/what she was foraging at
  the time (see §6, recruitment suppression).

`bee_foraging.gd::start_collecting()` becomes:

```
static func start_collecting(bee: Node2D) -> void:
    bee.current_flower.leave_marker(bee)
    if GameConfig.predators_on and bee.current_flower.has_crab_spider:
        if not CrabSpider.resolve_attack(bee):
            return   # dead or escaped -- state already set by resolve_attack
    bee.timer = bee.flower_handling_time
    bee.state = State.COLLECTING
```

### 5. The alarm-pheromone mark (placeholder skill)

Every attack -- hit or miss -- already marks the flower via
`resolve_attack` above (`crab_spider_alarm_at = Session.sim_time`). This
is deliberately a separate mark from the existing tarsal marker
(`marked_at`/`marked_by`) -- tarsal marks mean "recently drained", this
means "something was attacked here", and a flower can carry both
independently.

```
## crab_spider.gd
static func is_alarmed(flower: Node2D) -> bool:
    return Session.sim_time - flower.crab_spider_alarm_at < GameConfig.crab_spider_alarm_marker_seconds
```

**Placeholder for the skill tree** (no skill tree exists yet -- see
`CLAUDE.md`'s project instructions): `GameConfig.alarm_pheromone_on`, off
alongside `predators_on`. While it's on, a bee reaching
`State.INSPECTING` at an alarmed flower notices and leaves before ever
risking `State.COLLECTING` there -- hook into `bee_foraging.gd::inspect()`
right where the existing tarsal-marker check already lives in
`worth_feeding()`, as a second, independent check calling
`CrabSpider.is_alarmed(f)`. Label it clearly in code and in the settings
window (`debug_panel.gd`) as standing in for a future per-bee/per-colony
unlock rather than a permanent global toggle, e.g. a tooltip: *"Alarm
pheromone (placeholder -- will move to a skill unlock once the skill tree
exists)"*. The mechanic itself is real and testable now; only the
delivery method (global toggle vs. an actual unlock) is temporary.

### 6. Recruitment suppression (toggle) -- scoped to "still pointing at danger"

Not a permanent mark against a bee -- it lifts as soon as she's no
longer actually recruiting other bees towards wherever the attack
happened. What she offers a recruit at the entrance exchange is her
`forage_start_point` and (under `floral_constancy_on`) her
`preferred_species` -- so "she's moved on" means either of those has
changed since the attack, not that any fixed amount of time has passed.

New bee fields, set at the moment of an escape (§4, `resolve_attack`):

```
var was_attacked_by_predator: bool = false
var attacked_at_start_point: Vector2 = Vector2(INF, INF)
var attacked_at_preferred_species: String = ""
```

`CrabSpider.recruitment_suppressed(bee)`, comparing her *current* start
point/species against the snapshot taken at the attack, rather than a
one-off flag check:

```
## crab_spider.gd
static func recruitment_suppressed(bee: Node2D) -> bool:
    if not (GameConfig.crab_spider_recruit_suppression_on and bee.was_attacked_by_predator):
        return false
    return bee.forage_start_point == bee.attacked_at_start_point \
        and bee.preferred_species == bee.attacked_at_preferred_species
```

Gate in `bee_foraging.gd::go_to_exit()`, the existing entrance-mentoring
branch:

```
elif past_grace and bee.avg_collection_rate > upper and not CrabSpider.recruitment_suppressed(bee):
    bee.hive.add_entrance_mentor(bee)
    ...
```

This is deliberately comparison-based rather than clearing a flag the
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
GameConfig.crab_spider_reveal_seconds` (starting guess **1.5s**), already
set by `resolve_attack` and `relocate` above:

- **An attack**, hit or miss.
- **A relocation**, at the new flower always, and at the old one too
  unless it's relocating because it's dying (`show_departure`).

Either way it then fades from view again. This is purely presentational:
a small dark shape at the flower's centre, drawn only when
`Session.sim_time < crab_spider_reveal_until` (or the dev toggle, below)
is true, in the same procedural-`Polygon2D` style as everything else in
the game right now (see `DESIGN_BACKLOG.md` §6, sprite readiness -- this
follows the placeholder-art convention already in use, not ahead of it).
A relocation doesn't get a toast -- only the flash -- since it isn't a
meaningful event to announce and would get repetitive over a run; a kill
and an escape both do (next paragraph).

**Runtime cost:** fold the visibility check into `flower.gd`'s existing
throttled presentation pass (`_update_fade`/`_update_labels`, already
gated to `PRESENTATION_PER_SECOND` and skipped for off-screen flowers)
rather than adding a second, separate per-frame check -- there's no
reason this needs to update any faster than the flower's other visuals
already do, and it means 500 flowers' worth of spider-visibility checks
piggyback on a cost that's already accounted for instead of adding a new
one.

A kill's epitaph toast and a miss's warning both come free from existing
channels: `_announce_death` for a kill, and a lighter, throttled
`hud.show_warning` call for a miss (reuse the `epitaph_min_gap`-style
throttle pattern so a bad patch of attacks can't spam the corner --
`crab_spider_escape_min_gap` or similar).

A dev-only reveal toggle (`Session.show_crab_spiders` or similar, same
pattern as `Session.show_flower_amounts`) is worth adding for Dave's own
testing, surfaced in `debug_panel.gd` -- without it, testing this blind
is painful, and it's the main way Bundle 1 (below) gets checked before
anything dangerous exists to test.

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

**`scripts/crab_spider.gd`** (new)
- `extends RefCounted`. Grows one function per bundle:
  `roll_preferred_species()`, `maybe_spawn(flower)`, `update(flower,
  delta)`, `relocate(flower, show_departure)` (Bundle 1);
  `resolve_attack(bee)` (Bundle 2); `recruitment_suppressed(bee)`
  (Bundle 3); `is_alarmed(flower)` (Bundle 4).

**`flower.gd`**
- `SPECIES` table: new `crab_spider_weight` per entry.
- New fields: `has_crab_spider`, `crab_spider_settled_at`,
  `crab_spider_reveal_until`, `crab_spider_alarm_at`.
- `_process()`: one call to `CrabSpider.update(self, delta)`, one
  `has_crab_spider` check + `CrabSpider.relocate(self, false)` in the
  existing age-out block, and the reveal check folded into the existing
  throttled presentation pass.

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
var show_crab_spiders: bool = false   # dev-only reveal, alongside show_flower_amounts
```

**`bee.gd`**
```
var was_attacked_by_predator: bool = false
var attacked_at_start_point: Vector2 = Vector2(INF, INF)
var attacked_at_preferred_species: String = ""
```

No new `Bee.State` values are needed -- the attack resolves as a single
roll at the moment `State.COLLECTING` begins, not as its own state.

---

## Implementation bundles

Each bundle below is meant to be handed to Claude Code as its own
session/thread, run sequentially. Point a thread at this plan and name
the bundle -- it only needs the "Architecture" section above, the
bundle's own entry, and whichever numbered `Mechanic` subsection(s) it
references, not the whole file every time. That's deliberate: keeping
each thread's own context small is the point, alongside each bundle
being independently checkable before the next one starts, matching how
`AUDIT_PLAN.md`'s own "Bundle A/B/C" split already works in this repo.

Dependency shape: 1 before everything; 2 needs 1; 3 and 4 both only need
2, not each other, so they're safe to run in either order (or as two
threads in parallel if Dave wants to); 5 needs 2 to exist but not 3/4;
6 comes last.

### Bundle 1 -- Foundations: the module, data fields, spawning, movement

**Depends on:** nothing. **Unlocks:** everything else.

Creates `scripts/crab_spider.gd` and the fields in section 2/3 above.
Implements species-weight roll, per-run preferred-species roll and
storage on `Session`, the rarity spawn roll on flower creation/regrowth,
residency-timeout relocation, and death-triggered relocation. Adds
`predators_on` to `game_config.gd` and `debug_panel.gd` as the new
toggle tree's root, plus the dev-only `show_crab_spiders` reveal on
`Session` and its own settings-window checkbox.

Deliberately does **not** touch `bee_foraging.gd` or `bee.gd` at all --
nothing can attack a bee yet, so this bundle is inert to gameplay and
safe to land on its own. `flower.gd`'s existing behaviour is unchanged
for every flower that never rolls a spider.

**Files touched:** `scripts/crab_spider.gd` (new), `flower.gd`,
`game_config.gd`, `session.gd`, `debug_panel.gd`, wherever flowers are
seeded/regrown (`world_building.gd` or `main.gd`, wherever
`Flower.setup` is currently called).

**Check before moving on:** `source_checks.py`/`balance_tests.py` pass,
a Godot boot shows no new parser/type errors, and with `predators_on`
and the dev reveal both on, Dave can watch the meadow for a while and
confirm spiders appear (rarely, on the right species only), sit for a
while, and occasionally hop to a new flower of the same species --
including one visibly relocating when its old flower ages out. Nothing
should happen to any bee.

### Bundle 2 -- The danger: attack resolution

**Depends on:** Bundle 1. **Unlocks:** 3, 4, 5.

Implements `CrabSpider.resolve_attack(bee)` (section 4) and its hook
into `bee_foraging.gd::start_collecting()`. Adds the three new `bee.gd`
fields (`was_attacked_by_predator` and the two snapshots -- written now
even though nothing reads them until Bundle 3, since they belong with
the escape branch that sets them). Adds the kill/escape toast handling
(`_announce_death` needs no changes; the throttled escape warning does).
This is the bundle that makes the feature actually dangerous.

**Files touched:** `scripts/crab_spider.gd`, `bee_foraging.gd`
(`start_collecting`), `bee.gd` (three new fields).

**Check before moving on:** with `predators_on` and the dev reveal on,
run a colony for a while and confirm foragers occasionally die specifically
at spider-flagged flowers (cause "crab spider ambush" in the epitaph and
in a `session_*.jsonl` diagnostic log, if one's captured), roughly at the
5% starting rate over enough attempts to judge by eye; confirm an
escaped bee visibly avoids that exact flower afterwards
(`flower_cooldowns` working) while still visiting others normally.

### Bundle 3 -- Recruitment suppression (toggle)

**Depends on:** Bundle 2. **Independent of:** Bundle 4 (can run before,
after, or in parallel with it).

Implements `CrabSpider.recruitment_suppressed(bee)` (section 6) and its
hook into `bee_foraging.gd::go_to_exit()`. Adds
`crab_spider_recruit_suppression_on` to `game_config.gd`, wired into
`debug_panel.gd`'s `TOGGLE_PREREQUISITE` cascade as a child of
`predators_on`.

**Files touched:** `scripts/crab_spider.gd`, `bee_foraging.gd`
(`go_to_exit`), `game_config.gd`, `debug_panel.gd`.

**Check before moving on:** with the toggle on, confirm a forager who
escaped an attack doesn't appear as an entrance mentor while her start
point and species still match the attack (check via the mentor list or
by observing recruitment behaviour), and does resume being eligible once
she re-scouts or is matched with a mentor herself.

### Bundle 4 -- Alarm pheromone (placeholder skill toggle)

**Depends on:** Bundle 2. **Independent of:** Bundle 3.

Implements `CrabSpider.is_alarmed(flower)` (section 5) and its hook into
`bee_foraging.gd::inspect()`/`worth_feeding()`. Adds `alarm_pheromone_on`
to `game_config.gd`, wired into the same toggle cascade as a child of
`predators_on`, with the settings-window tooltip explicitly labelling it
as a placeholder for a future skill-tree unlock (see "Architecture" and
section 5).

**Files touched:** `scripts/crab_spider.gd`, `bee_foraging.gd`
(`inspect`/`worth_feeding`), `game_config.gd`, `debug_panel.gd`.

**Check before moving on:** with the toggle on, confirm a bee that lands
on a recently-alarmed flower (one another bee was just attacked at)
leaves during `State.INSPECTING` without ever entering
`State.COLLECTING`, and that this stops happening once
`crab_spider_alarm_marker_seconds` has elapsed since the last attack
there.

### Bundle 5 -- Balance modelling

**Depends on:** Bundle 2 (needs `crab_spider_flower_fraction` and
`crab_spider_attack_success_chance` to exist as real numbers to model).
**Independent of:** Bundles 3/4 -- can run in parallel with either.

Per `CLAUDE.md` rule 4, a throwaway Python model (natural home:
`tests/balance_tests.py`, following the same pattern already used for
disease/winter numbers) checking spider count vs. forager losses at a
few representative colony sizes. The failure mode to check for: a
colony's forage income taking a real, felt hit rather than staying "rare
enough not to notice mechanically, present enough to notice
narratively." Feeds back into `crab_spider_flower_fraction`,
`crab_spider_attack_success_chance` and `crab_spider_residency_seconds`
in `game_config.gd` if the model says the starting guesses are off.

**Files touched:** `tests/balance_tests.py`, possibly `game_config.gd`
(if numbers move).

**Check before moving on:** the model's own stated conclusion, plus
`balance_tests.py` still passing with whatever defaults it settles on.

**Built 20 Aug.** `test_crab_spiders()` in `tests/balance_tests.py` reads
`flower.gd`'s `weight`/`crab_spider_weight` table and re-derives, for
every species (not just whichever gets rolled this run, since the roll
only decides *which* species is dangerous, not how dangerous it is once
chosen): expected spiders resident in the meadow, days between
colony-wide spider kills for a representative 40-forager colony, and
what fraction of a forager's natural lifespan that risk represents. The
model's conclusion: the starting guesses hold up as-is, no
`game_config.gd` change needed. Worst case (Clover, ~40% of the meadow)
costs a 40-forager colony about one death every 19 days and a ~3.3%
chance of any individual forager losing a race against old age to a
spider -- inside the "felt but not punishing" band this bundle checks
for (5-200 days between colony kills, <20% lifetime risk). Best case
(Foxglove, 8% of the meadow) is closer to one death every 94 days.
Clover's own worked example in section 1 (~4 spiders) checks out exactly
against the current numbers. `source_checks.py`/`balance_tests.py` both
pass.

**Follow-up fixes, 20 Aug (from Dave's hands-on check):** three gaps the
plan's own text didn't anticipate, found the moment predators actually
ran in front of a player rather than a test:

- **The dev reveal toggle wasn't actually conspicuous.** `show_crab_spiders`
  only forced the same 4px near-black dot the real in-play flash uses
  visible permanently -- technically working, but useless for finding a
  spider by eye across a 500-flower meadow, which is the entire point of
  the toggle. `flower.gd` now has a second marker,
  `crab_spider_dev_marker` -- a large, bright magenta ring, shown only
  under `Session.show_crab_spiders`, never from a real attack/relocation
  flash -- so the toggle and the actual gameplay flash stay visually
  distinct and the toggle is now unmissable.
- **Alarm pheromone had no visible signal at all.** The mechanic
  (section 5) was working -- `worth_feeding()` did turn a bee away from
  an alarmed flower -- but nothing showed it happening; a bee that fled
  looked identical to one that just found a flower not worth feeding
  from, which is why Dave couldn't tell if it was doing anything.
  `bee.gd` now has `alarm_ring` (a bright orange ring, distinct from the
  green `selection_ring`) plus `alarm_flash_until`, and
  `CrabSpider.flee_alarm(bee, flower)` (new) flashes it for
  `crab_spider_reveal_seconds` -- the same brief-flash duration and
  presentation-only pattern (rule 3) the flower's own marker already
  uses. Hooked into both places `worth_feeding()` can turn a bee away
  (`inspect()` and `drink_at_flower()` in `bee_foraging.gd`).
- **No log evidence any of this was working.** See
  `docs/archive/DIAGNOSTIC_LOGGING_PLAN.md`'s own changelog for the logging side of
  this fix -- a new `crab_spider_event` log line (kill/escape/alarm_flee)
  plus snapshot-level `crab_spiders`/`foraging_behaviour` sections now
  give direct evidence from `session_*.jsonl` that predators, alarm
  pheromone, floral constancy, recruitment and scouting are each firing,
  without needing to watch a run live.

`source_checks.py`/`balance_tests.py` pass and a Godot boot shows no new
parser/type errors. Still needs Dave's own re-check that the dev marker
and the alarm-ring flash are now actually visible in play.

**Confirmed 20 Aug** (dev marker and alarm ring both visible), which
surfaced three more issues in the same playtest, plus a settings gap:

- **`crab_spider_attack_success_chance` wasn't in the settings window at
  all** -- every other crab-spider number was tunable from
  `debug_panel.gd` except the one that decides how dangerous an attack
  actually is. Added under Predators, next to the spawn-chance entry it
  sits closest to conceptually.
- **Bees were revisiting a flower they'd just been attacked at.** Real
  bug, not a rare edge case: `resolve_attack`'s escape cooldown was
  written into `bee.flower_cooldowns` -- the same dictionary
  `BeeForaging.nearest_flower()`'s relaxed fallback pass deliberately
  *ignores* once the strict pass finds nothing (see that function's own
  comment: "relax the memory and take the best of what's left", written
  for ordinary tarsal marks/rejections, which are fine to override
  rather than starve a bee over). A predator escape isn't that kind of
  soft memory -- the biology section this plan is grounded in is
  explicit that ~80% of bees that survive an attack abandon the flower
  outright, not "unless nothing else is nearby". Fixed by giving it its
  own dictionary, `bee.predator_flower_cooldowns`, checked unconditionally
  in `nearest_flower()` (outside the `if strict:` block, so both passes
  respect it) rather than folded into the pool that gets relaxed.
- **Some bees interacting with a spider weren't glowing orange.** Not a
  bug in the mechanic -- `alarm_ring` only ever fires from
  `CrabSpider.flee_alarm()`, which is the *alarm_pheromone_on*
  precognition path (a bee notices the mark and never risks feeding).
  A bee who actually walks into `State.COLLECTING` and gets attacked
  (the much rarer case once alarm pheromone is on, which is presumably
  why "most" bees glowed and a few didn't) went through
  `CrabSpider.resolve_attack`'s escape branch instead, which had no
  per-bee visual at all -- only the flower flashed. Added a second ring,
  `attack_ring` (red, distinct from alarm_ring's orange), fired from
  `resolve_attack` itself, so an actual attack-and-escape is now just as
  visible as an alarm-triggered avoidance, and the two read as the
  different events they are.
- **Bees looked like they were beelining for "the spider" rather than
  the flower it's on.** A presentation side-effect of the dev marker
  fix above, not a pathing bug -- bees only ever target
  `flower.position`, confirmed nothing outside `flower.gd` references
  either marker. But the dev marker was a filled disc 22px in radius
  against a flower that's a 28x28 square (half-width 14), so it visually
  dwarfed the flower it sat on and read as a separate object next to it.
  Changed `crab_spider_dev_marker` from a filled `Polygon2D` to an
  unfilled `Line2D` ring -- still just as conspicuous, but now frames
  the flower instead of competing with it for "which of these is the
  thing bees are flying to".

`source_checks.py`/`balance_tests.py` pass, `FUNCTION_MAP.md`
regenerated (bee.gd touched again), a Godot boot is clean. Needs Dave's
re-check on all four: the setting shows up and does something, an
escaped bee's exact flower stays off-limits even when forage is tight
nearby, every attack (not just alarm-avoidance) now flashes red on the
bee, and the dev marker reads as a ring around the flower rather than a
separate blob.

### Bundle 6 -- Closeout

**Depends on:** all of the above being built (though not necessarily
Dave's hands-on confirmation yet -- that can follow this bundle).

Administrative, not mechanical: resolve the save/load question flagged
under "Before implementing" (decide whether the new fields need
serialising in `save_game.gd`, or can reset like flower cluster centres
already do); regenerate `FUNCTION_MAP.md` via
`tools/update_function_map.py` if `bee.gd`/`hud.gd` shifted meaningfully;
update `DESIGN_BACKLOG.md` §7.3, `ROADMAP.md`'s Predators row and
`NEXTSTEPS.md` to reflect "built, wants Dave's hands-on playtest" rather
than "planned" -- matching how every other shipped feature in this repo
gets closed out.

**Files touched:** `save_game.gd` (maybe), `FUNCTION_MAP.md` (maybe),
`DESIGN_BACKLOG.md`, `ROADMAP.md`, `NEXTSTEPS.md`.

**Check before moving on:** `source_checks.py`/`balance_tests.py` pass,
a Godot boot is clean, and the docs accurately describe what's actually
built -- then it's ready for Dave's own playtest.

---

## Before implementing: check, don't assume

- **Save/load.** `DESIGN_BACKLOG.md` §5 notes flower cluster centres
  aren't currently saved and the meadow re-randomises a bit on load.
  Check `save_game.gd`'s actual flower/bee serialisation before deciding
  whether `has_crab_spider`/`crab_spider_settled_at`/
  `was_attacked_by_predator` and its two snapshot fields need saving, or
  whether (like cluster centres) it's fine for them to reset -- a spider
  simply re-rolling its position on load is probably an acceptable loss,
  same reasoning as the flower it's sitting on. Formally resolved in
  Bundle 6, but worth keeping in mind from Bundle 1 onward.
- **`FUNCTION_MAP.md`.** If this touches `bee.gd` or `hud.gd`
  meaningfully, regenerate with `tools/update_function_map.py` per
  `CLAUDE.md` (Bundle 6, or sooner if a bundle's own diff is large).
- **Balance numbers.** Every number above is a starting guess, not a
  simulated one -- see Bundle 5.

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
  picked up: `CrabSpider.resolve_attack` (section 4) -- a single
  success-chance roll between two parties, one of whom may die -- is
  already close to generic, and now lives in its own file rather than
  inline in `bee_foraging.gd`, precisely so a future combat mechanism has
  something to generalise from rather than replace outright. Still a
  decision for whenever it's actually scoped, not now.
- **A generic predator/combat framework.** See "Architecture" above --
  deliberately not built ahead of a second concrete case.
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
