# Bee individuality plan

Written 17 Aug 2026, agreed with Dave in a planning conversation (not yet
built). This is the spec Claude Code should build from next session. It
follows the same shape as `PERF_PLAN.md` and `BEE_SPLIT_PLAN.md`: read
this before starting, so the session doing the work doesn't have to
rediscover any of it.

Read this after `NEXTSTEPS.md` points here.

---

## Goal

Bees stop being interchangeable. Every bee gets one small mechanical
quirk (a stat nudged up or down), a generated name, and a generated fact
about herself, so the player can form an attachment to individuals
inside a colony of hundreds. `ROADMAP.md` already names this "small
inherited variation in speed, capacity, lifespan, cheap, adds texture."
This plan scopes it down to what's genuinely cheap for a first slice,
and parks the rest.

Nothing here should cost anything per frame. Every roll happens once,
at spawn.

---

## Order of work (build one slice at a time, confirm it runs, then move on)

1. Stat trait roll, the mechanical core.
2. Name generation.
3. Fact generation.
4. Visual jitter (body tint and size).
5. Birth-order "firsts" (milestone bees).
6. Death epitaphs.
7. Favourite-bee pinning.

Each is independently playable and checkable. Don't build all seven
before the first playtest, one small step at a time per the project's
usual build phase.

---

## New shared file: `scripts/bee_identity.gd`

Following rule 1 in `CLAUDE.md` (role data lives in one table, nowhere
else), the word lists, fact templates and lookup helpers all live in one
new leaf file, the same shape as `roles.gd`:

```
extends RefCounted
## Everything about a bee's rolled identity: name, fact, and which stat
## trait it has. One place these are described, so bee.gd, hud.gd and
## save_game.gd all read the same lists.
```

It holds the data tables (below) and small static functions:
`roll_trait_stat()`, `roll_name()`, `roll_fact(trait_stat: String)`.
`bee.gd` preloads it the same way it preloads `Roles`.

---

## 1. Stat trait roll

**Trait pool (Tier 1 only for this slice, all already per-bee variables
on `Bee`, synced from `GameConfig` in one place, `bee.gd` `_ready()`
lines 255-261):**

| Stat | What it does |
|---|---|
| `speed` | flight/walk speed |
| `nectar_collection_rate` | nectar gathered per second at a flower |
| `pollen_collection_rate` | pollen gathered per second |
| `nectar_stomach_capacity` | max nectar carried per trip |
| `pollen_stomach_capacity` | max pollen carried per trip |

Not in this slice: `bee_lifespan_days` and `energy_burn_rate`. Those are
read straight from `GameConfig` inside `bee_survival.gd` rather than
from the bee itself, so including them means also editing the 2-3 read
sites there (`lifespan_seconds()` at line 78, the upkeep calc at line
29). Worth doing once this slice is proven fun, not before.

**The roll, once, in `_ready()` right after the existing stat sync:**

1. Pick 1 of the 5 stats at random.
2. Pick a direction: weighted, leans positive. `positive_chance = 0.7`.
3. Pick a magnitude band, small changes far more likely than large ones:

| Band | Weight |
|---|---|
| 2-4% | 50% |
| 4-7% | 35% |
| 7-10% | 15% |

Roll uniformly within whichever band is picked.

4. Multiply the chosen stat by `1 + magnitude` (positive roll) or
   `1 - magnitude` (negative roll).

**These weights are balance numbers, not content, so they belong in
`GameConfig`** per rule 2 in `CLAUDE.md` (would a designer tune it to
change how the game plays? yes), not hardcoded in `bee_identity.gd`:

```
var trait_positive_chance: float = 0.7
var trait_magnitude_bands: Array = [
    {"min": 0.02, "max": 0.04, "weight": 0.50},
    {"min": 0.04, "max": 0.07, "weight": 0.35},
    {"min": 0.07, "max": 0.10, "weight": 0.15},
]
```

Apply the picked stat with an explicit `match` statement in `bee.gd`,
not dynamic property indexing, readability over cleverness per the
project's own convention (Dave will be reading and tweaking this).

**Storage, on the bee:**

```
var trait_stat: String = ""      # e.g. "speed"
var trait_percent: float = 0.0   # signed, e.g. 0.07 or -0.03
```

**Save/load:** add `trait_stat` and `trait_pct` to `save_game.gd`
`_bees_data()` (around line 191 onward, alongside `role`, `state` etc.)
and restore them explicitly on load, the same as every other per-bee
field there. Without this, reloading a save silently re-rolls every
bee's trait, which breaks the whole point ("this is Buzzwick, she's 8%
faster" stops being true).

**Not gated by `is_on_screen`.** The roll happens once at spawn
regardless of camera position, consistent with rule 3 (simulation may
never be skipped for off-screen bees). This only matters for the
*displaying* of the trait, never the applying of it.

**Rule 4 flag:** the 70/30 direction split and the magnitude band
weights are starting guesses, the same category as
`recruit_lower/upper_threshold` in the existing backlog. Worth a
one-off check in `tests/balance_tests.py`, that the bands' weights sum
to 1.0, and roughly what the population-average stat shift looks like
across a full colony (should land noticeably positive given the 70/30
skew, that's the intended texture, just worth confirming rather than
assuming).

---

## 2. Name generation

Two short lists combined, adjective and noun, in `bee_identity.gd`:

```
const NAME_ADJECTIVES := ["Speedy", "Sleepy", "Plucky", "Wobbly",
    "Fuzzy", "Bold", "Nimble", "Drowsy", "Cheerful", "Grumpy", ...]
    # ~25 entries

const NAME_NOUNS := ["Clover", "Pip", "Dot", "Marigold", "Thistle",
    "Buzz", "Daisy", "Bramble", "Sorrel", "Hazel", ...]
    # ~25 entries
```

25 x 25 gives 625 combinations from 50 lines of text. Both lists are
curated so *any* pairing reads fine, "Wobbly Marigold", "Speedy Dot",
that's what makes combining lists safe here rather than a
maintenance risk: no runtime check is needed for a bad-sounding result.

Roll once at spawn, store as `bee_name: String`, add `name` to
`save_game.gd`'s per-bee save dict and restore it on load. Not derived
deterministically from `bee_id`: if a word gets added or reordered in
either list later, every existing bee's name would silently change on
next load. Rolling once and saving the result avoids that.

**Append-only convention for both lists**, same as `bee_enums.gd`'s
Role/State enums: add new words at the end, don't reorder or delete,
so nothing here needs to touch the save format again once shipped.

---

## 3. Fact generation

Three pools in `bee_identity.gd`, one picked at random per bee (weights
below), then one entry (or one combination) from within it:

**a. Trait-matched facts** (`TRAIT_FACTS`, a dictionary keyed by stat
name, ~4-5 lines each, about 20-25 lines total). Only used for the stat
the bee actually rolled, so it reads as commentary on the mechanical
trait rather than being random, e.g. for `speed`:
`"Reckons she's the fastest forager in the colony."` /
`"Takes the scenic route, every time."` (works for either a positive or
negative roll on that stat, wording doesn't need to know the sign).

**b. General facts** (`GENERAL_FACTS`, a flat list, expanded from the
original idea, aim for 35-40 complete lines), standalone and unrelated
to any stat, pure flavour:
`"Once got lost for eleven minutes."` /
`"Has personally inspected every soil block in the hive."` /
`"Named the flower patch to the east 'the good one'."` /
`"Grooms her antennae four times before takeoff, never three, never
five."`

**c. Templated love/hate/fascination facts** (`FACT_TEMPLATES` x
`FACT_SUBJECTS`), the combination format Dave asked for. A small list of
sentence templates combined with a shared list of subjects:

```
const FACT_TEMPLATES := [
    "Absolutely loves %s.",
    "Can't stand %s.",
    "Is weirdly fascinated by %s.",
    "Gets nervous around %s.",
    "Has strong opinions about %s.",
    "Never shuts up about %s.",
]   # ~6 entries

const FACT_SUBJECTS := [
    "the smell of clover", "rainy days", "tight spaces in the comb",
    "long flights", "the colour blue", "loud buzzing", "spiders",
    "crowded cells", "sunbathing on a warm leaf", "thunder",
    "getting lost", "the taste of thistle nectar", "shiny things",
    "mornings", "other bees' gossip", ...
]   # ~25-30 entries
```

6 templates x 28 subjects gives 168 more combinations from about 34
lines. Subjects are written so they work under every template without
reading oddly, the same safety trick as the name lists.

**Weights** (also `GameConfig`, they shape how "meaningful" vs "purely
silly" a colony feels, that's a tuning knob):

```
var fact_trait_matched_chance: float = 0.4
var fact_general_chance: float = 0.3
var fact_templated_chance: float = 0.3
```

Storage: `bee_fact: String`, rolled once at spawn (a bee without a
trait never happens in this design, every bee gets exactly one, so
pool (a) is always available). Add `fact` to the per-bee save dict,
restored on load, same reasoning as the name.

---

## 4. Visual jitter (body tint and size)

Both rolled once at spawn, both purely cosmetic (rule 3: presentation
only, fine to skip for off-screen bees if that's ever worth doing,
though at this cost there's no need to bother).

**Tint:** a small brightness jitter on the existing role colour, not a
hue shift, role colour still has to stay identifiable at a glance
(`Roles.colour_for()`, and the colour-blind tag system in `roles.gd`
depends on colour meaning role). Multiply the role colour by a factor
in `0.95..1.05`, applied once when `body.color` is set.

**Size:** scale the whole `Bee` node (not just `body`), `0.95..1.05`,
so `body`, `outline_ring`, `selection_ring`, `centre_dot` and the label
all stay aligned and scale together.

```
var visual_size_jitter_range: float = 0.05   # GameConfig, +/- this fraction
```

---

## 5. Birth-order "firsts"

Milestone bees keep their normal rolled name (still part of the same
system), but their **fact is overridden** with a deterministic line
instead of a rolled one, no extra RNG needed, just a check at spawn
against `bee_id` (already tracked via `world.next_bee_id`, already
saved):

- `bee_id == 0` (or whatever the very first hatch's id turns out to be):
  `"Was the very first bee this colony ever raised."`
- First gyne ever raised (needs one new tracked flag, e.g.
  `world.first_gyne_seen: bool`, set the first time a bee's `is_gyne`
  becomes true): `"Was the first gyne this colony ever raised."`
- Every Nth bee (`MILESTONE_INTERVAL := 100` in `GameConfig`, a round
  number, tunable): `"Was the hundredth bee this colony ever raised."`

Cheap because it reuses `next_bee_id`, which already exists and is
already saved, no new counters needed except the one gyne flag.

---

## 6. Death epitaphs

**Hook:** `BeeSurvival.die()` in `bee_survival.gd`, lines 306-321, the
one place every bee's death already funnels through (starvation and
old age both call it). It already calls `bee.world.mark_death(bee)`
just before `queue_free()`, that's where an epitaph line should be
built and shown, using the bee's already-stored `bee_name`,
`bee_fact` and `trait_stat`, e.g.:

`"Wobbly Marigold, who never met a flower she didn't try, has died of
old age."`

**Display channel:** reuse `hud.show_warning()`. It already exists and
is already used for exactly this kind of one-line toast (see
`main.gd::_check_colony_energy()` and the control-group messages in
`camera_view.gd`), no new UI needed.

**Important: needs a throttle.** A bad night in winter, or a mass
starvation event, could otherwise fire dozens of epitaphs back to back,
overwhelming exactly the moment the game should be showing restraint.
`main.gd::_check_colony_energy()` already solves this same problem with
a cooldown (`GameConfig.low_energy_gap`, tracked via
`last_energy_warning`). Reuse that pattern: a minimum gap between
epitaphs (`GameConfig.epitaph_min_gap`, a few seconds is plenty), and
if more bees die within the gap, skip their epitaphs rather than
queuing them, the moment matters more than completeness.

---

## 7. Favourite-bee pinning

Lets the player mark bees by name and find them again in a colony of
hundreds.

**Storage:** `is_favourite: bool` on the bee, saved like any other
per-bee flag.

**Closest existing precedent to reuse:** `Session.control_groups`
(`camera_view.gd::_save_control_group()` /
`_recall_control_group()`), which already does "remember a set of bee
ids, reselect them later." Favouriting is the same shape but persistent
by name rather than recalled by a hotkey slot, and surfaced as a list
rather than a keypress.

**UI:** a small "Favourites" list in `colony_panel.gd`, name plus role
plus energy per row. Clicking an entry selects that bee and jumps the
camera to it, reusing `camera_view.gd::_zoom_to_fit()`'s
centre-and-zoom logic (currently built for "fit everything selected,"
here it'd fit on just the one bee).

**Toggling:** a right-click option or a star icon in the single-bee
selection panel (`hud.gd`, the same panel that already shows name and
fact), `input_selection.gd` already owns bee selection and is the
natural place to add the toggle action.

---

## Save format summary

New fields added to each bee's entry in `save_game.gd`'s `_bees_data()`
(and restored on load in `saving.gd`), all `.get()`-defaulted so old
saves don't break:

| Field | Type | From |
|---|---|---|
| `name` | String | section 2 |
| `fact` | String | section 3 (or 5, if a milestone) |
| `trait_stat` | String | section 1 |
| `trait_pct` | float | section 1 |
| `favourite` | bool | section 7 |

No `FORMAT_VERSION` bump needed, this follows the same
defaulted-field pattern already used elsewhere in the save system.

---

## Parked, not this slice

- **Gyne lineage inheritance.** `ROADMAP.md`'s "gynes carry it forward"
  line could mean a colony a gyne founds biases its own bees' rolls
  toward her trait, a real genetics/lineage system. Not needed for v1,
  no founded-colony simulation exists yet for it to attach to. Recorded
  as an open question in `DESIGN_BACKLOG.md`.
- **Tier 2 stats** (lifespan, energy efficiency), once Tier 1's proven
  fun.
- **Favourite-flower nudging actual flower choice** (a tie-break only,
  not a new scan), that's a simulation change, not flavour text, kept
  separate from this cosmetic-and-light-mechanics slice.
