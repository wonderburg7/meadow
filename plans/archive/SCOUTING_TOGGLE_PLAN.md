# Scouting / floral constancy / recruitment split

**Archived 19 Aug 2026 — shipped.** Kept as a record of the design. See
`docs/history.md` for what actually landed.

Written 18 Aug 2026, agreed with Dave across two planning conversations
(not yet built). Follows the same shape as `BEE_INDIVIDUALITY_PLAN.md`
and `PERF_PLAN.md`: read this before starting, build one slice at a
time, confirm each runs before moving on.

Read this after `NEXTSTEPS.md` points here.

---

## Why this exists

`floral_constancy_on` and `auto_foraging_on` (recruitment) were built
17 Aug as one combined mechanism because they shared the entrance-wait
exchange (`DESIGN_BACKLOG.md`'s history note, removed old sections 7.1
and 8). In practice that merge went further than intended: **scouting
itself** — a new forager trying a few options before settling — only
ran when `auto_foraging_on` was on, a scouting bee was always pulled
into the entrance-wait queue between bouts whether or not recruitment
was wanted, and the winning *start point* a scout found was never
actually kept (only the species was). This plan fixes all of that and
adds a fourth, more basic tier underneath scouting: a semi-random
starting flight for every new forager, on or off independent of
everything above it.

The four mechanisms now form a small dependency tree, matching the
research order Dave wants for a future skills tree (not built now —
see "Looking ahead" below):

```
Orientation flight (new, tier 0)
  └─ Scouting (tier 1)
       ├─ Floral constancy (tier 2)
       └─ Auto-recruitment (tier 2)
```

Turning a toggle on turns its prerequisite on too, all the way down.
Turning a toggle off turns everything that depends on it off too, all
the way up. Floral constancy and auto-recruitment sit side by side —
each depends on scouting, **not on each other** — see the flagged
decision below for why.

---

## Flagged decision: does auto-recruitment require floral constancy?

Dave described the intended order as "Random starting location →
Scouting → Floral constancy → Auto-recruiting," which read literally
would make auto-recruitment depend on floral constancy the same way
scouting depends on orientation flight. That would contradict something
agreed earlier in the same conversation: auto-recruitment must work with
floral constancy off, with the mentor passing on only its start point
(not its species) in that case.

**This plan treats the arrow as the intended research order for the
future skills tree, not a strict on/off dependency for today's
toggles.** Floral constancy and auto-recruitment both depend on
scouting; neither depends on the other. That preserves "recruit
without constancy, start point only" as a real, working combination.
If you actually want recruitment to require constancy — i.e. turning
recruitment on also forces constancy on, and turning constancy off
also forces recruitment off — that's a one-line change to the
prerequisite table in section 4 below (`auto_recruitment_on`'s parent
becomes `floral_constancy_on` instead of `scouting_on`), but it removes
that combination. Flagging this before it's built rather than guessing.

---

## The four toggles, what each one does alone

| Toggle | Alone, does this |
|---|---|
| **Orientation flight** (new, `orientation_flight_on`) | A new forager makes one semi-random flight to a point within `forage_start_radius` of the hive before her first trip, and keeps that as her `forage_start_point` from then on — real bees do this too, learning the area before they start foraging properly. No comparison, no scoring, just one pick, kept. |
| **Scouting** (`scouting_on`) | A new forager tries `SCOUT_BOUTS` (3) semi-random start points, forages normally from each (no species restriction), and keeps whichever start point scored the best resource rate as `forage_start_point`. This is orientation flight done three times with the results compared, so it needs orientation flight underneath it. |
| **Floral constancy** (`floral_constancy_on`, existing) | Player can hand-pin a forager to one species via "Pick a flower" (unchanged). Also folds a species sample into each of scouting's bouts, so a scouted forager settles on the best *(start point, species)* pair instead of start point alone. |
| **Auto-recruitment** (`auto_recruitment_on`, renamed from `auto_foraging_on`) | Foragers below a resource-specific lower threshold wait at the entrance hoping a better performer passes on its start point (and species, if constancy's also on); foragers above the upper threshold wait to offer. Matching is resource-specific in both directions — see section 3. |

**Cascade rules, both directions:**

- Turning a toggle **on** also turns its prerequisite on, recursively.
  Turning Scouting on turns Orientation flight on. Turning Floral
  constancy or Auto-recruitment on turns Scouting on, which turns
  Orientation flight on.
- Turning a toggle **off** also turns everything that depends on it
  off, recursively. Turning Orientation flight off turns off Scouting,
  which turns off Floral constancy and Auto-recruitment. Turning
  Scouting off turns off Floral constancy and Auto-recruitment (this
  part explicitly asked for). Turning Floral constancy or
  Auto-recruitment off on its own doesn't cascade anywhere — nothing
  depends on either of them.

---

## What's deliberately kept from today's build

A still-scouting bee remains eligible to be pulled aside by a mentor
mid-scout (`wait_at_entrance`'s seeker branch) **when
`auto_recruitment_on` is also on** — being handed an already-proven
patch is still strictly better than finishing the remaining bouts, same
reasoning as today's comment on that line. A scouting bee only visits
the entrance queue at all when `auto_recruitment_on` is on; with
recruitment off, all three bouts run uninterrupted every time.

---

## Order of work (one slice at a time, confirm it runs, then move on)

1. **Mechanical rename**, zero behaviour change: `auto_foraging_on` →
   `auto_recruitment_on`, `floral_scouting_radius` → `forage_start_radius`
   (it's about to be used by orientation flight too, not just scouting)
   everywhere either appears. Add `scouting_on` and
   `orientation_flight_on` (both `false` by default) to `GameConfig`
   with no consumers yet. Run `source_checks.py` to confirm the rename
   didn't miss a reference before touching any logic.
2. **Orientation flight**, the new base tier, built alone first since
   everything else now sits on top of it. New `bee.gd` creation branch,
   new `BeeForaging.take_orientation_flight` (section 3 below). Playable
   and checkable on its own: toggle it on, watch new foragers scatter to
   a random spot near the hive on their first trip instead of beelining
   for the nearest flower, and stay working that spot afterwards.
3. **Decouple the entrance detour from scouting**, and reroute
   scouting's own trigger through `scouting_on`. In `go_to_exit`, gate
   the whole AT_ENTRANCE_SEEKING/MENTORING block on
   `auto_recruitment_on` instead of the old combined toggle, and stop
   treating `bee.is_scouting` as an automatic reason to visit the
   entrance unless that gate is open. At this point scouting can run
   start-to-finish with `auto_recruitment_on` off and nothing waits at
   the door.
4. **Keep the winning start point.** Add `scout_current_start_point`
   and `scout_best_start_point` to `bee.gd`, record the former each
   bout, compare/keep the latter in `_score_trip`, and write it to
   `forage_start_point` when scouting finishes — the gap found while
   first scoping this (today's build only ever kept the species).
5. **Fold species sampling into scouting under floral constancy.**
   Move the `scout_species` commit/avoid logic from gating on the old
   combined toggle to gating on `floral_constancy_on`. Only write
   `preferred_species` at the end of scouting when constancy's on;
   always write `forage_start_point` from the winning bout regardless.
6. **Split recruitment thresholds by resource, and match mentors and
   seekers by resource in both directions.** Replace
   `recruit_lower_threshold` / `recruit_upper_threshold` with `_nectar`
   / `_pollen` pairs. Fix `wait_at_entrance`'s seeker scan to skip
   mentors whose `resource_type` doesn't match instead of only ever
   looking at the front of the list — confirmed explicitly this needs
   to work both ways: a nectar forager should never pick up a pollen
   mentor's patch, and a pollen mentor should just keep waiting (or
   time out) if only nectar seekers are around, not get claimed by the
   wrong type.
7. **Conditional hand-off content.** In `wait_at_entrance`'s match,
   always copy `forage_start_point`; only also copy `preferred_species`
   when `floral_constancy_on` is on.
8. **Settings window and the cascade wiring.** Add the
   `orientation_flight_on` and `scouting_on` rows, rename the
   recruitment row and its tips, split the two threshold rows into
   four, and wire the prerequisite table (section 4) into the toggle
   handler so switching any of the four correctly cascades the other
   three.
9. **Comment sweep.** `bee.gd`'s field comments, `hive.gd` line 37,
   `game_config.gd`'s var comments — all currently describe the old
   two-toggle shape.

Each slice is independently playable/checkable against
`source_checks.py`/`balance_tests.py`; no need to build all nine before
the first playtest.

---

## 1. `GameConfig` field changes

```
# new -- tier 0, see above
var orientation_flight_on: bool = false

# unchanged in meaning, new name
var scouting_on: bool = false

# unchanged
var floral_constancy_on: bool = false

# renamed from auto_foraging_on -- entrance exchange only now
var auto_recruitment_on: bool = false

# renamed from floral_scouting_radius -- now shared by orientation
# flight and scouting, not scouting-specific any more
var forage_start_radius: float = 200.0

var recruit_wait_seconds: float = 10.0
var recruit_grace_trips: float = 3.0

# replaces recruit_lower_threshold / recruit_upper_threshold
var recruit_lower_threshold_nectar: float = 0.5
var recruit_upper_threshold_nectar: float = 2.0
# starting guess, scaled off nectar's pair by the ratio of the two base
# collection rates (pollen_collection_rate 2.0 vs nectar_collection_rate
# 5.0) -- not simulated, same rule-4 flag as the nectar pair always was
var recruit_lower_threshold_pollen: float = 0.2
var recruit_upper_threshold_pollen: float = 0.8
```

**Rule 4 flag, carried over and extended:** the nectar thresholds were
already unsimulated starting guesses (`DESIGN_BACKLOG.md` §5). The new
pollen pair is an even rougher guess and the four-toggle interaction as
a whole is new territory — worth a deliberate look (a throwaway rate
simulation, or at minimum a longer playtest with both resource types
tracked) before trusting any of these numbers.

---

## 2. `bee.gd` field changes

```
## Winner-tracking for the current scouting run, alongside the existing
## scout_bout / scout_species / scout_tried_species / scout_best_species
## / scout_best_rate. Not save-persisted, same as the rest of the
## scouting block -- a bee saved mid-scout resumes as a plain forager.
var scout_current_start_point: Vector2 = Vector2(INF, INF)
var scout_best_start_point: Vector2 = Vector2(INF, INF)
```

Reset both in `BeeForaging.start_scouting` alongside the existing
resets. No other new fields — `preferred_species` and
`forage_start_point` already exist and are already saved
(`save_game.gd` lines 223-225), and orientation flight only ever writes
to `forage_start_point`, nothing new to persist.

---

## 3. Exact logic changes, by function (`bee_foraging.gd` unless noted)

**`bee.gd`'s creation branch (currently line 387)** -- scouting first,
orientation flight as the fallback, same "only at creation" restriction
as today (a bee switched into Forager later via `set_role` keeps
whatever it already had):
```
if GameConfig.scouting_on and bee_role == Role.FORAGER:
    BeeForaging.start_scouting(self)
elif GameConfig.orientation_flight_on and bee_role == Role.FORAGER:
    BeeForaging.take_orientation_flight(self)
else:
    state = _default_state_for_role()
```

**New shared helper**, factored out of the old `_send_to_scout_point`
so orientation flight and scouting pick points the same way:
```
static func _random_point_near_hive(bee: Node2D) -> Vector2:
    var base: Vector2 = bee.world.hive.position if bee.world else bee.position
    var angle: float = randf() * TAU
    var dist: float = randf() * GameConfig.forage_start_radius
    return base + Vector2(cos(angle), sin(angle)) * dist
```

**New: `take_orientation_flight`** -- one pick, kept, no scoring:
```
## Tier 0: a new forager's one semi-random flight before her first
## trip, kept as her start point from then on. See
## SCOUTING_TOGGLE_PLAN.md. Outdoor-spawned bees fly there immediately;
## indoor-spawned (hatched) ones pick it up on their first exit via the
## normal forage_start_point handling in _leave_hive_and_resume.
static func take_orientation_flight(bee: Node2D) -> void:
    var point: Vector2 = _random_point_near_hive(bee)
    bee.forage_start_point = point
    if not bee._is_inside_hive():
        bee.move_target = point
        bee.state = State.MOVE_TO_POINT
    else:
        bee.state = bee._default_state_for_role()
```

**`_send_to_scout_point` (currently lines 495-500)** -- reuse the
shared helper, record the point for scoring:
```
static func _send_to_scout_point(bee: Node2D) -> void:
    var point: Vector2 = _random_point_near_hive(bee)
    bee.move_target = point
    bee.scout_current_start_point = point
    bee.state = State.MOVE_TO_POINT
```

**`seek_flower` (currently line 49-50)** -- species commit only under
constancy:
```
if GameConfig.floral_constancy_on and bee.is_scouting and bee.scout_species == "":
    bee.scout_species = best.species_name
```

**`nearest_flower`'s `accept` closure (currently lines 73-83)** -- same
change of gate, same shape otherwise:
```
if bee.is_scouting and GameConfig.floral_constancy_on:
    if bee.scout_species != "":
        if f.species_name != bee.scout_species:
            return false
    elif bee.scout_tried_species.has(f.species_name):
        return false
elif bee.preferred_species != "" and f.species_name != bee.preferred_species:
    return false
```
Without `floral_constancy_on`, `bee.scout_species` never gets set (see
above) so this branch is simply never entered during a pure scout --
the bee forages whatever's nearest and available, exactly as a
non-scouting bee would, which is what lets the bout's rate reflect the
start point alone.

**`finish_depositing` (currently lines 362, 382)** -- both old
`auto_foraging_on` checks become `scouting_on or auto_recruitment_on`
(trip timing/scoring is needed by either mechanism):
```
if (GameConfig.scouting_on or GameConfig.auto_recruitment_on) and bee.trip_load_amount < 0.0:
    bee.trip_load_amount = bee.current_load
...
if GameConfig.scouting_on or GameConfig.auto_recruitment_on:
    _score_trip(bee)
```

**`_score_trip` (currently lines 395-421)** -- keep the winning start
point, only touch species bookkeeping under constancy, only write
`preferred_species` under constancy, always write `forage_start_point`:
```
static func _score_trip(bee: Node2D) -> void:
    var amount: float = max(bee.trip_load_amount, 0.0)
    var elapsed: float = max(Session.sim_time - bee.trip_start_time, 0.1)
    var rate: float = amount / elapsed
    if bee.avg_collection_rate <= 0.0:
        bee.avg_collection_rate = rate
    else:
        bee.avg_collection_rate = lerpf(bee.avg_collection_rate, rate, bee.RATE_EMA_WEIGHT)
    bee.trips_scored += 1
    bee.trip_load_amount = -1.0

    if not bee.is_scouting:
        return
    if rate > bee.scout_best_rate:
        bee.scout_best_rate = rate
        bee.scout_best_species = bee.scout_species
        bee.scout_best_start_point = bee.scout_current_start_point
    if GameConfig.floral_constancy_on:
        bee.scout_tried_species.append(bee.scout_species)
    bee.scout_bout += 1
    bee.scout_species = ""
    if bee.scout_bout >= SCOUT_BOUTS:
        bee.is_scouting = false
        if bee.scout_best_rate > 0.0:
            if bee.scout_best_start_point.x != INF:
                bee.forage_start_point = bee.scout_best_start_point
            if GameConfig.floral_constancy_on:
                bee.preferred_species = bee.scout_best_species
```

**`go_to_exit` (currently lines 424-454)** -- gate the whole detour on
`auto_recruitment_on`, split the threshold lookup by resource type:
```
if GameConfig.auto_recruitment_on and bee.role == Role.FORAGER:
    var past_grace: bool = bee.trips_scored >= GameConfig.recruit_grace_trips
    var lower: float = GameConfig.recruit_lower_threshold_nectar if bee.resource_type == "nectar" else GameConfig.recruit_lower_threshold_pollen
    var upper: float = GameConfig.recruit_upper_threshold_nectar if bee.resource_type == "nectar" else GameConfig.recruit_upper_threshold_pollen
    if bee.is_scouting or (past_grace and bee.avg_collection_rate < lower):
        bee.timer = GameConfig.recruit_wait_seconds
        bee.entrance_wait_target = _entrance_wait_spot(bee, -1)
        bee.state = State.AT_ENTRANCE_SEEKING
        return
    elif past_grace and bee.avg_collection_rate > upper:
        bee.hive.add_entrance_mentor(bee)
        bee.timer = GameConfig.recruit_wait_seconds
        bee.entrance_wait_target = _entrance_wait_spot(bee, 1)
        bee.state = State.AT_ENTRANCE_MENTORING
        return
_leave_hive_and_resume(bee)
```
Note this is the one place `bee.is_scouting` still causes an entrance
visit -- and it's now only reachable at all when `auto_recruitment_on`
is on, which is exactly the "deliberately kept" behaviour above.

**`_leave_hive_and_resume` (currently lines 473-490)** -- trip timing
needed by either mechanism, not just recruitment:
```
if (GameConfig.scouting_on or GameConfig.auto_recruitment_on) and bee.role == Role.FORAGER:
    bee.trip_start_time = Session.sim_time
    if bee.is_scouting:
        _send_to_scout_point(bee)
        return
```

**`wait_at_entrance` (currently lines 525-569)** -- match mentors and
seekers by resource type, in both directions: a seeker only picks up a
same-resource mentor, and a mismatched mentor is left in the queue
rather than consumed or blocking:
```
# Seeker. Scan for the first valid mentor of the same resource type,
# pruning dead ones as we go but leaving a mismatched-resource mentor
# in place for a seeker of its own type -- a nectar forager has no use
# for a pollen patch's start point, and shouldn't block a pollen
# mentor from ever being found by a pollen seeker either.
var i := 0
while i < bee.hive.entrance_mentors.size():
    var mentor: Node2D = bee.hive.entrance_mentors[i]
    if not is_instance_valid(mentor):
        bee.hive.entrance_mentors.remove_at(i)
        continue
    if mentor.resource_type != bee.resource_type:
        i += 1
        continue
    bee.forage_start_point = mentor.forage_start_point
    if GameConfig.floral_constancy_on:
        bee.preferred_species = mentor.preferred_species
    bee.is_scouting = false
    _leave_hive_and_resume(bee)
    return
```
The mentor side needs no change beyond this -- `add_entrance_mentor`
already just appends whatever bee offers, and a mentor of one resource
type sitting in the queue is now correctly invisible to a seeker of the
other type, per the scan above. The "nobody came" fallback (currently
lines 558-569) is unchanged in shape, just now only ever reached when
`auto_recruitment_on` is on, per the `go_to_exit` gate above.

---

## 4. Settings window (`debug_panel.gd`, currently lines 106-140)

New/changed entries, same `CONFIG_FIELDS`-style dictionaries. Order
matters here for readability -- listed in tier order, orientation
flight first:

```
{
    "key": "orientation_flight_on", "label": "Orientation flight", "toggle": true,
    "category": "Flowers",
    "tip": "A new forager makes a short flight to a random spot near the hive before her first trip, and keeps working that spot from then on, rather than beelining for whatever's nearest the door -- real bees do this too, learning the area before they start foraging properly. Off by default. Turning on Auto scouting turns this on too.",
},
{
    "key": "scouting_on", "label": "Auto scouting", "toggle": true,
    "category": "Flowers",
    "tip": "A new forager tries a few start points near the hive (see Orientation flight) and settles on whichever collected best, instead of just keeping the first one. Off by default. Turning on Floral constancy or Auto-recruitment turns this on too, since both rely on a forager having actually scouted. Turning this off also turns off Floral constancy and Auto-recruitment.",
},
{
    "key": "floral_constancy_on", "label": "Floral constancy", "toggle": true,
    "category": "Flowers",
    "tip": "Lets you pin a forager to one flower species via 'Set preference' in its selection panel -- it will only ever visit that species from then on. Also makes Auto scouting sample a different species each bout, so a scouted forager settles on the best start point AND species together, not just the best spot. Off by default; existing preferences are kept even if you turn this off, they just stop being offered as a new option. Turning this on also turns Auto scouting on.",
},
{
    "key": "auto_recruitment_on", "label": "Auto-recruitment", "toggle": true,
    "category": "Flowers",
    "tip": "Foragers compare notes at the hive entrance -- a good performer can pass its start point (and species, if Floral constancy is also on) to a struggling one of the same resource type. Off by default; off means no bee ever waits at the door. Turning this on also turns Auto scouting on.",
},
{
    "key": "forage_start_radius", "label": "Start point radius", "step": 20.0, "min": 20.0,
    "category": "Flowers",
    "tip": "How far from the hive a new forager's start point (Orientation flight or Auto scouting) is scattered. Only matters when one of those is on.",
},
{
    "key": "recruit_lower_threshold_nectar", "label": "Recruit: seek below (nectar)", "step": 0.1, "min": 0.0,
    "category": "Flowers",
    "tip": "A nectar forager collecting less than this (units/second) waits at the entrance hoping a better-performing forager tells it where to go. Only matters when Auto-recruitment is on.",
},
{
    "key": "recruit_upper_threshold_nectar", "label": "Recruit: offer above (nectar)", "step": 0.1, "min": 0.0,
    "category": "Flowers",
    "tip": "A nectar forager collecting more than this (units/second) waits at the entrance, willing to pass on its start point. Only matters when Auto-recruitment is on.",
},
{
    "key": "recruit_lower_threshold_pollen", "label": "Recruit: seek below (pollen)", "step": 0.1, "min": 0.0,
    "category": "Flowers",
    "tip": "Same as the nectar version, for pollen foragers. Pollen's base collection rate is lower than nectar's, so this needs its own number rather than sharing the nectar threshold. Only matters when Auto-recruitment is on.",
},
{
    "key": "recruit_upper_threshold_pollen", "label": "Recruit: offer above (pollen)", "step": 0.1, "min": 0.0,
    "category": "Flowers",
    "tip": "Same as the nectar version, for pollen foragers. Only matters when Auto-recruitment is on.",
},
{
    "key": "recruit_wait_seconds", "label": "Recruit wait s", "step": 1.0, "min": 1.0,
    "category": "Flowers",
    "tip": "How long a forager waits at the entrance for a match before giving up and heading out on its own. Only matters when Auto-recruitment is on.",
},
{
    "key": "recruit_grace_trips", "label": "Recruit grace trips", "step": 1.0, "min": 0.0,
    "category": "Flowers",
    "tip": "How many trips a forager must complete before it's judged against the thresholds above. Only matters when Auto-recruitment is on.",
},
```

**Cascade wiring.** Rather than special-casing key names one at a time
(the pattern the existing handler at lines 1027-1038 uses for
`show_info_badges`/`colour_blind_mode`), this is small enough to be
data-driven, and the shape maps directly onto the dependency tree at
the top of this plan -- worth keeping that way since the future skills
tree will want the same table:

```
## Foraging-automation prerequisite tree (see SCOUTING_TOGGLE_PLAN.md):
## each key's value is the toggle it depends on. Empty string means no
## prerequisite. Mirrors the intended research order for a future
## skills tree, not built yet.
const TOGGLE_PREREQUISITE := {
    "scouting_on": "orientation_flight_on",
    "floral_constancy_on": "scouting_on",
    "auto_recruitment_on": "scouting_on",
}
```

In `_make_toggle_row`'s `toggled.connect` closure, after the existing
`setting_set(key, pressed)`:
```
if pressed:
    _cascade_prerequisites_on(key)
else:
    _cascade_dependents_off(key)
```
with two small recursive helpers (walk up via `TOGGLE_PREREQUISITE` to
turn prerequisites on; walk the dictionary's values to find and turn
off anything whose prerequisite is `key`, recursively). Each toggle a
helper flips needs its own row's `CheckBox.button_pressed` refreshed to
match -- exact mechanism (a `key -> CheckBox` lookup populated as
`_make_toggle_row` builds each row, or a full section rebuild) is an
implementation call for whoever picks this slice up, not specified
further here.

---

## 5. Comment sweep (no behaviour change, do in the same pass as the rename)

- `bee.gd` lines 176-181 (`preferred_species`), 189-210 (the
  `is_scouting` block and `avg_collection_rate`) -- currently describe
  the old single combined toggle by name.
- `hive.gd` line 37 -- references `GameConfig.auto_foraging_on`.
- `game_config.gd` -- the block currently at lines 44-78 needs
  rewriting to describe four toggles instead of two (this plan's
  section 1 above is close to final wording for these).

---

## Worked examples, for reference while building/testing

| Toggles on | New forager behaviour | Entrance |
|---|---|---|
| none | Plain foraging, nearest available flower. Today's baseline. | never |
| Orientation flight only | One random flight, then works that spot every trip. No comparison. | never |
| Scouting (pulls in Orientation flight) | 3 bouts, fresh random start point each, no species restriction -- keeps best-rate start point. | never |
| Scouting + Floral constancy | 3 bouts, each a fresh (start point, species) pair -- keeps the best-performing pair. Manual "Pick a flower" override still available. | never |
| Scouting + Auto-recruitment, constancy off | Base scouting as above, plus the entrance exchange judged against resource-specific thresholds. Matched mentor passes start point only, and only to a seeker of the same resource type. | active |
| All four on | Scouting samples pairs, entrance exchange active, matched mentor passes start point and species, resource-matched both ways. | active |

Any state with Floral constancy or Auto-recruitment on always has
Scouting (and therefore Orientation flight) on too, so the first three
rows are only reachable by deliberately switching the higher tiers back
off afterwards.

---

## Looking ahead: the skills tree

Not built now, recorded so the shape agreed here doesn't need
rediscovering later. Dave's intended progression is Orientation flight
→ Scouting → Floral constancy → Auto-recruitment, researched in that
order. The `TOGGLE_PREREQUISITE` table in section 4 is deliberately
shaped so a future skills tree can reuse it directly (a skill unlocking
one of these toggles rather than the settings window offering it for
free) rather than needing a second, parallel dependency structure. The
one open question (see "Flagged decision" above) is whether
Auto-recruitment's prerequisite should eventually become Floral
constancy rather than Scouting, once the skill tree actually exists --
worth revisiting there rather than deciding now.

---

## Not in scope for this slice

- **The skills tree itself** -- see above.
- **The pre-existing quirk where a seeker's manual species pin gets
  wiped if no mentor turns up in time** (`wait_at_entrance`'s "nobody
  came" branch always clears `preferred_species`, even a manually-set
  one). Predates this plan, not introduced by it, left alone --
  recorded here so it isn't mistaken for something this rework caused.
- **A Foraging window and per-hive-cell flower preference** -- already
  deferred in `DESIGN_BACKLOG.md` §5, unaffected by this plan.
- Simulating the four threshold numbers properly (rule 4) -- flagged
  above, worth doing once the split is playtested and the numbers are
  worth trusting.
