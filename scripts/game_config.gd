extends Node
## Autoload (registered in project.godot under [autoload]) -- the one
## place all the tunable prototype numbers live. Bees, flowers and the
## hive read these when they're created; the tuning dropdown edits them
## directly. Because this is an autoload it survives a scene reload, so
## "Restart Run" respawns everything using whatever values are set here.

# --- world ---
var flower_count: float = 500.0         # the meadow is topped back up to this
## Flowers age and die, and a replacement seeds elsewhere, so the meadow
## shifts around underneath the colony while staying roughly this full.
var flower_lifespan_days: float = 6.0
var flower_lifespan_variation: float = 0.4   # +/- this fraction, so they don't all die together
var flower_regrow_seconds: float = 2.0       # gap between replacements seeding
var hive_cell_count: float = 5.0        # cells the hive starts with; builders add more
var starting_bees: float = 3.0
var starting_nurses: float = 1.0        # without at least one nurse, laid eggs never reach a cell
var starting_builders: float = 0.0
var seconds_per_day: float = 200.0      # real seconds in one in-game day

# --- flowers (per-species values are in flower.gd; these scale them) ---
var nectar_recharge_rate: float = 0.5   # per second
var pollen_recharge_rate: float = 0.1   # per second

## Tarsal secretion markers. Bees leave a scent from their feet on every
## flower they land on; with this on, other bees avoid a flower marked
## recently rather than wasting a trip on one just stripped. Real
## bumblebees and honeybees both do this.
var tarsal_markers_on: bool = false
var tarsal_marker_seconds: float = 25.0

## Crab spiders (see CRAB_SPIDER_PLAN.md) -- ambush predators that sit
## motionless on flowers of one species, rolled per run, and occasionally
## kill a forager that starts feeding. Off by default; the whole feature
## stays off until Dave turns it on to test. This is the toggle tree's
## root -- everything else the plan adds (attack resolution, recruitment
## suppression, the alarm-pheromone placeholder) depends on this.
var predators_on: bool = false
## Chance a newly created/regrown flower of the preferred species gets a
## spider. Starting guess, not yet modelled -- see CLAUDE.md rule 4 and
## CRAB_SPIDER_PLAN.md Bundle 5.
var crab_spider_flower_fraction: float = 0.02
## How long a spider stays on one flower before relocating (it also
## relocates immediately if that flower dies). Starting guess, one and a
## half in-game days at the default seconds_per_day of 200.
var crab_spider_residency_seconds: float = 300.0
## How long a spider flashes into view after an attack or a relocation,
## before fading from view again.
var crab_spider_reveal_seconds: float = 1.5
## Chance a bee that starts feeding at a spider's flower is caught.
## Starting guess, not yet modelled -- see CLAUDE.md rule 4 and
## CRAB_SPIDER_PLAN.md Bundle 5.
var crab_spider_attack_success_chance: float = 0.05
## How long an escaped bee avoids the exact flower she was attacked at --
## much longer than the ordinary REJECTED_AVOID_SECONDS (15s) a bee gets
## for simply finding a flower not worthwhile.
var crab_spider_escape_cooldown_seconds: float = 120.0
## Throttle on the escape warning toast, same shape as epitaph_min_gap,
## so a bad patch of near-misses can't spam the corner.
var crab_spider_escape_min_gap: float = 8.0
## Whether an escaped bee is held back from becoming an entrance mentor
## for as long as she's still pointing recruits towards wherever she was
## attacked (her forage_start_point/preferred_species unchanged since).
## Bundle 3 -- see CRAB_SPIDER_PLAN.md section 6.
var crab_spider_recruit_suppression_on: bool = false
## Placeholder for a future skill-tree unlock (no skill tree exists yet --
## see CRAB_SPIDER_PLAN.md section 5 and CLAUDE.md). While on, a bee that
## reaches State.INSPECTING at a flower another bee was recently attacked
## at (hit or miss) notices and leaves before ever risking
## State.COLLECTING there. Off by default, cascaded under predators_on.
var alarm_pheromone_on: bool = false
## How long a flower stays "alarmed" after an attack there, for the
## alarm_pheromone_on check above. Starting guess, not yet modelled.
var crab_spider_alarm_marker_seconds: float = 40.0

## A bee gives up on a flower once less than this is left. Without it,
## the slow recharge trickle is enough to keep a bee parked on an
## exhausted flower indefinitely.
var min_worthwhile_amount: float = 1.0

## How far a forager looks for a flower before giving up and falling back
## to a full search of the meadow. Bounds the spatial-grid query: without
## a limit, a bee whose species is nowhere nearby would widen its search
## to the whole map every time and cost more than the plain scan it
## replaced.
var forage_search_radius: float = 900.0

## When on, a forager can be given a fixed species preference (see the
## "Set preference" control in a forager's selection panel) and will
## only ever visit that species from then on, even if it means walking
## past a nearer flower of something else. Real bees show this kind of
## floral constancy -- sticking with one species while it's rewarding.
var floral_constancy_on: bool = false

## Foraging-automation dependency tree (see SCOUTING_TOGGLE_PLAN.md):
## Orientation flight (tier 0, a new forager's one semi-random start-point
## flight, kept from then on, no comparison) sits under Scouting (tries a
## few of those points and keeps whichever scored best), which sits under
## both Floral constancy (also folds a species sample into each scouting
## bout, so a scouted forager settles on the best (start point, species)
## pair) and Auto-recruitment (the entrance exchange -- foragers below a
## resource-specific lower threshold wait hoping a better performer passes
## on its start point; foragers above the upper threshold wait to offer).
## Turning a toggle on turns its prerequisite on too, recursively; turning
## one off turns everything that depends on it off too, recursively.
## Floral constancy and Auto-recruitment sit side by side -- each depends
## on Scouting, not on each other, so "recruit without constancy, start
## point only" is a real working combination. All four off by default;
## off means foraging works exactly as it does with none of this present.
var orientation_flight_on: bool = false
var scouting_on: bool = false
var auto_recruitment_on: bool = false
## How far from the hive a new forager's start point (Orientation flight
## or Scouting) is scattered -- not to be confused with
## forage_search_radius below, which is how far *from wherever she
## currently is* a forager will look for a flower on any given decision.
## This one only controls how spread out different foragers' patches are
## from each other and from the hive.
##
## 450, up from 200 -- simulation-backed: A/B on
## test_scenarios/forage_radius_wide_test.json vs the 200 default showed
## the wider spread bringing home ~13% more flower visits and ~24% more
## distinct flowers visited (foragers landing on the same handful of
## flowers less often), with no rise in deaths -- the generous
## forage_search_radius already means a bee starting further out has no
## trouble finding a flower. Only tested at 450 itself, not the space
## between 200 and 450 -- there may be a better point in between, but 450
## is the one with real data behind it rather than a guess.
var forage_start_radius: float = 450.0
## Resource units/second. A forager below this after a delivery waits at
## the entrance hoping to be told a better patch; a forager above it
## waits to offer one. Split by resource type since pollen's base
## collection rate is much lower than nectar's.
##
## Simulation-derived (see CLAUDE.md rule 4), not a starting guess any
## more: checked against real settled-forager avg_collection_rate from
## test_scenarios/recruit_threshold_calibration_test.json (a 45-forager
## colony, everything on, life spans stretched so the founder cohort
## survives long enough to build real trip history). These are the
## 10th/90th percentiles of that run's settled-forager rates, so roughly
## the bottom-performing tenth reads as a seeker and the top-performing
## tenth as a mentor, matching what real bees in this colony size/shape
## were actually collecting.
##
## Re-derived 21 Aug 2026 (nectar 0.42/0.56 -> 0.27/0.45, pollen
## 0.25/0.31 -> 0.23/0.31, from 150 settled-forager samples over 5 runs)
## after fixing two measurement bugs in avg_collection_rate itself, found
## while investigating why recruitment kept funnelling many seekers onto
## one already-drained patch (see NEXTSTEPS.md's recruitment-competition
## writeup):
## - An empty-handed return (patch had nothing left) used to skip
##   BeeForaging._score_trip entirely, so avg_collection_rate stayed
##   frozen at whatever a forager's last real delivery read -- a mentor
##   whose patch had gone dry kept advertising it as good, undiminished,
##   to every new seeker, rather than her own next few empty trips
##   pulling her rate back down. Confirmed directly in old session logs:
##   every mentor matched more than once had a bit-identical
##   avg_collection_rate across every match, sometimes 100+ seconds
##   apart.
## - The grace-window average (trips_scored below recruit_grace_trips)
##   used to be the same EMA as afterwards, which put ~49% of the weight
##   on trip one alone by the time a forager was first judged -- one
##   lucky or unlucky trip was deciding "has she found a good patch"
##   almost by itself. It's now a plain mean across the grace window,
##   switching to the EMA only once settled.
## Both fixes pull real (previously invisible) low readings into the
## distribution, which is why every threshold moved down rather than
## just nectar's median shifting -- this is the corrected picture, not a
## regression. Re-check with debug_panel.gd's "Recruiting" readout (see
## year_winter.gd::_refresh_recruit_gap) if the foraging economy changes
## enough to shift the distribution -- collection rates, flower density,
## or anything else upstream of avg_collection_rate.
var recruit_lower_threshold_nectar: float = 0.27
var recruit_upper_threshold_nectar: float = 0.45
var recruit_lower_threshold_pollen: float = 0.23
var recruit_upper_threshold_pollen: float = 0.31
## How long a bee waits at the entrance for a match before giving up.
## 15s, up from 10 -- untested guess either way, but a mentor and a
## matching seeker both have to be waiting at the same time for a match
## to happen at all, so a few more seconds of overlap window should mean
## more matches without the wait itself costing much against a whole
## multi-trip foraging cycle. Worth rechecking recruitment_matches once
## there's a longer/bigger run to compare against.
var recruit_wait_seconds: float = 15.0
## How far a recruited seeker's inherited start point is nudged away from
## her mentor's exact one. Simulation-backed, not a guess: tracking both
## bees' rates over their next 5 trips (see bee.gd's recruit_partner
## block/DiagnosticLog.log_recruitment_followup) found the mentor's own
## rate dropping hard right after a match and staying down across the
## whole tracked window, while a direct flower-overlap check (did the
## seeker land on a flower the mentor had *just* marked) hit noticeably
## more often than chance alone would explain with dozens of candidate
## flowers in range. Sending the seeker to literally the same point was
## putting two bees onto one bee's worth of nearby flowers. This keeps
## her in the same general proven area (the whole point of being told
## about it) while giving her a different starting corner of it, rather
## than funnelling both bees onto the same handful of flowers.
## 150, up from 80 (see the mentor-cap fix alongside this one, and the
## recruitment-competition investigation, NEXTSTEPS.md) -- 80px inside a
## 900px forage_search_radius wasn't really "a different corner of the
## same patch", it was the same catchment of flowers the mentor was
## already drawing from. A/B'd against 250 on foraging_features_on_test.json
## (5 runs each, mentor cap in place both times): 250 gave the best
## per-match outcomes (a seeker's 3rd tracked trip averaged *above* her
## own pre-match rate) but cost colony-wide flower visits (202.6 -> 179.4,
## moving away from the 230 no-automation baseline) -- likely random-
## direction jitter that size sometimes lands a seeker in a sparser
## corner of the meadow rather than nearer more flowers. 150 as a
## deliberate middle ground, not yet A/B'd on its own -- recruitment's
## matching logic is expected to change again shortly, so revisit this
## once that lands rather than spending another calibration pass now.
var recruit_start_point_jitter: float = 150.0
## Trips a forager must actually be scored on -- since auto-recruitment
## turned on, or since it was created -- before its avg_collection_rate
## is trusted against the thresholds above. Below this, it leaves
## straight back out no matter how low or high its (still unformed)
## average reads. Without this, a brand-new colony's foragers judge
## themselves against the thresholds on their very first trip home, when
## the number means nothing yet, and pile up waiting at the door with no
## mentors ever able to form either -- see bee.gd's trips_scored.
var recruit_grace_trips: float = 3.0

# --- foraging ---
var bee_speed: float = 110.0
var flower_handling_time: float = 2.0
var nectar_collection_rate: float = 5.0
var pollen_collection_rate: float = 2.0
var deposit_time: float = 2.5
var nectar_stomach_capacity: float = 50.0
var pollen_stomach_capacity: float = 15.0

# --- hive ---
var cell_capacity: float = 200.0        # one resource per cell, or one developing bee
## Fraction of capacity above which a cell is treated as "practically
## full" for routing purposes, so a second cell starts receiving
## deposits instead of everything piling into one that's constantly
## being sipped from and so never quite reaches the literal cap.
var cell_full_threshold: float = 0.9
var egg_pollen_cost: float = 60.0       # pollen the queen must eat to lay one egg
var queen_eat_rate: float = 3.0         # pollen per second the queen consumes
var queen_speed_factor: float = 0.6     # she's larger, so slower than a worker
var brood_develop_time: float = 120.0   # seconds of development before a bee emerges
var tending_speed_bonus: float = 1.5    # multiplier while a nursery worker is tending

## Brood no longer develops on its own. A nurse (or the queen, who takes
## nursing as her second job) has to visit the cell and drop food in;
## each feed buys the larva a fixed stretch of development time and then
## it stalls again until someone comes back. Honey is the better feed:
## it's denser, so it lasts longer per visit.
var brood_feed_seconds: float = 20.0        # a pollen + nectar feed
var brood_feed_seconds_honey: float = 25.0  # a pollen + honey feed
var brood_feed_pollen: float = 3.0      # pollen used per feed
var brood_feed_nectar: float = 6.0      # nectar used per feed, when there's no honey
var brood_feed_honey: float = 1.5       # honey used per feed -- less goes further
## A nurse tops a larva back up once its remaining fed-time drops below
## this, rather than waiting for it to stall completely.
var brood_feed_threshold: float = 6.0

# --- the nursery zone ---
## Cells reserved for brood form the nursery zone, and each carries a
## priority tier. The queen shares her eggs between the tiers in
## proportion to these weights, so with the defaults a high-priority cell
## gets three eggs for every one a low-priority cell gets.
##
## The sharing is done by a running credit per tier rather than a fixed
## rota (see Hive.find_empty_cell), which keeps the ratio exactly true
## over any length of time *and* interleaves the tiers -- three highs in
## a row would average out correctly but feel streaky and unpredictable.
var lay_weight_low: float = 1.0
var lay_weight_medium: float = 2.0
var lay_weight_high: float = 3.0

## A zone cell with no role set is a fallback: the queen only lays in one
## once every zone cell that *does* name a role is full, and the bee that
## emerges is an ordinary nectar forager. That way an unset cell is never
## dead weight, but it never quietly outbids a cell you configured.
##
## With this off the queen also refuses to lay in plain undesignated
## comb, so eggs only ever go where you have asked for them. On (the
## default) she falls back to any spare cell once the zone is full.
var queen_lays_in_any_cell: bool = true

## How long a window the nursery window's emergence figures cover, in
## in-game seconds. Three minutes is long enough to smooth out the
## lumpiness of individual hatches without lagging behind a change you
## just made.
var emergence_window_seconds: float = 180.0

## The colony window's history plot samples the stores and the population
## this often, keeping this many points.
var history_sample_seconds: float = 5.0
var history_points: float = 180.0

## The "almost no pollen" signal is suppressed until this day. A young
## colony genuinely has no pollen for a while and there is nothing useful
## to do about it, so saying so from the first minute is just noise.
var pollen_warning_first_day: float = 7.0

## A larva that has gone this long with nothing to eat dies. The cell is
## then blocked by the body until a comb worker on maintenance clears it
## out and carries it away -- neglect costs you the cell as well as the
## bee.
var larva_death_seconds: float = 90.0
var cell_clean_time: float = 20.0   # comb-worker seconds to clear a dead larva

## Nurses carry the food to the brood themselves. A nurse walks to a
## pollen cell and loads up, then to a honey or nectar cell, and only
## then can she feed anything -- she feeds from what she is carrying, not
## out of thin air. Carrying several feeds' worth at a time stops her
## shuttling back and forth for every single larva.
var nurse_carry_feeds: float = 4.0
var nurse_load_time: float = 1.5    # seconds spent filling up at a cell

# --- eating ---
## Bees eat as a visible errand rather than topping themselves up
## invisibly wherever they happen to be. Once a bee drops below
## `hunger_threshold` of its capacity it breaks off, walks to a cell with
## food in it, and feeds until it is full.
var hunger_threshold: float = 0.30      # fraction of capacity
var bee_eat_rate: float = 25.0          # energy per second while feeding

# --- flight ---
## Flying costs energy on top of simply being alive, so a forager's range
## is paid for rather than free. Wet wings cost more again (see rain).
var flight_energy_burn: float = 0.17

## A forager out in the meadow drinks nectar straight from a flower when
## it drops below this share of its capacity -- it doesn't have to fly
## home to eat. Pollen foragers do this too: they aren't collecting
## nectar, but they will still drink it.
var forager_drink_threshold: float = 0.7
var nectar_drink_rate: float = 20.0     # energy per second while drinking

## A nectar forager can also metabolise what is already in its crop
## rather than land at all. That comes straight off the delivery, so a
## bee that has to do this a lot is one that is ranging too far.
var crop_drink_threshold: float = 0.25

# --- gynes ---
## A gyne is a future queen: bigger than a worker, slower, hungrier, and
## far more expensive to raise. She can do any worker job in the
## meantime, so raising one early costs you real labour as well as
## resources.
var gyne_size_factor: float = 1.35      # relative to a worker; the queen is ~1.55
var gyne_speed_factor: float = 0.85
var gyne_energy_factor: float = 1.3
var gyne_egg_pollen_cost: float = 180.0 # what the queen must eat to lay one
var gyne_develop_multiplier: float = 4.0
## Feeding a gyne larva takes royal jelly as well as pollen, and honey
## rather than nectar -- nothing else will do.
var brood_feed_jelly: float = 2.0
var brood_feed_seconds_gyne: float = 30.0

# --- royal jelly ---
## Nurses on the royal jelly sub-mode eat pollen and honey and work it
## into jelly, which is stored in cells of its own. Only gyne larvae need
## it, so it's dead weight for a colony that isn't raising any.
var jelly_pollen_cost: float = 12.0
var jelly_honey_cost: float = 6.0
var jelly_make_time: float = 12.0
var jelly_per_batch: float = 8.0
var jelly_cell_capacity: float = 120.0

# --- weather ---
## Rain grounds a colony. It waters down the nectar in open flowers, and
## a wet bee is a heavy bee, so flying costs more. Past
## `rain_forage_limit` a trip costs more than it brings back and foragers
## stay in.
## Off to begin with. Rain is a complication on top of an economy that
## is already the thing worth learning, and having it arrive unannounced
## in someone's first run reads as the game being broken rather than as
## weather. Switch it on once the foraging loop makes sense.
var weather_on: bool = false
var rain_chance_per_day: float = 0.45
var rain_min_seconds: float = 40.0
var rain_max_seconds: float = 130.0
var rain_nectar_dilution: float = 0.6   # share of nectar value lost at full intensity
var rain_flight_burn_factor: float = 2.2
var rain_forage_limit: float = 0.5      # intensity above which foragers stay home


# --- warnings ---
## When this fraction of the colony is below `low_energy_warning_level`
## of its energy, the game says so. It doesn't pause -- it's a nudge, not
## an interruption -- and it won't say it again for `low_energy_gap`
## seconds even if things stay bad.
var low_energy_warning_fraction: float = 0.5
var low_energy_warning_level: float = 0.3
var low_energy_gap: float = 180.0

# --- honey ---
## Honey makers take nectar out of the comb, chew enzymes into it, spit
## the mix into a fresh cell and then fan their wings over it to drive
## the water off. Only once a cell is fully fanned is what's in it
## actually honey, and honey is a far denser store of energy than the
## nectar it came from.
var honey_cell_capacity: float = 200.0
var honey_energy_factor: float = 4.0    # one unit of honey is worth this much nectar
var nectar_per_honey: float = 2.0       # nectar consumed to make one unit of mix
var honey_chew_time: float = 10.0        # seconds spent adding enzymes before depositing
var honey_ripen_time: float = 30.0      # bee-seconds of fanning to dry one cell out
## Adding a fresh batch of wet mix to a part-dried cell sets the drying
## back by this fraction, so topping a cell up has a real cost.
var honey_rewet_factor: float = 0.5
var starting_honey_makers: float = 0.0

# --- comb building ---
## Miner-seconds to break down one soil block. Like building, several
## miners on the same block share the work.
var block_mine_time: float = 120.0
var starting_miners: float = 0.0

## A miner fills up with spoil as it digs and has to carry it outside
## before it can dig more -- real excavation doesn't vanish.
var miner_dirt_capacity: float = 40.0
var dirt_fill_rate: float = 0.5     # dirt per second while digging
var dirt_dump_time: float = 2.0     # seconds spent outside emptying out

## Builder-seconds needed to finish one cell. Two builders working the
## same cell halve the wall-clock time, three thirds it, and so on.
var cell_build_time: float = 90.0
## Extra energy a builder burns while actually building. Bees make wax
## from the sugar they've eaten, so building is paid for in energy
## rather than from a separate wax stockpile.
var build_energy_burn: float = 0.6

# --- hive geometry ---
## The hive interior is a hexagonal grid. Tiles closer to the centre
## than `hive_interior_rings` are open floor or comb; the next
## `hive_wall_thickness` rings are soil blocks forming the wall. Soil
## uses the same tile size as comb so a mined block can be replaced by
## a cell later.
var hive_interior_rings: float = 6.0
## How far the solid soil extends beyond the open area. Everything from
## the edge of the hollow out to here is diggable ground, so the hive
## sits in earth rather than being ringed by a thin wall.
var hive_soil_depth: float = 12.0
## Rings of bedrock wrapped round the outside of the soil. Rock can't be
## marked, mined or walked through -- it's the hard edge of the map.
var hive_rock_rings: float = 2.0
## No longer read by world_building.gd::_entrance_tiles, which now always
## carves a single-tile-wide corner tunnel (14 Aug 2026 -- flat-top hexes
## made a genuinely straight one-tile tunnel possible, which was the
## point of this setting in the first place). Left in place, unused,
## rather than removed outright, so old saves that recorded a value for
## it still load without an unknown-setting warning. Revisit if a wider
## doorway is ever wanted -- see NEW_FEATURES_BLUEPRINT.md.
var hive_entrance_width: float = 1.0
var hive_cell_size: float = 17.0        # centre-to-corner of one comb tile
var hive_cell_spacing: float = 19.0     # spacing passed to hex_to_pixel

## Bees walking over comb are slower than over open floor -- they have
## to pick their way across the cells rather than fly straight.
var cell_slow_factor: float = 0.55

# --- bee life ---
var bee_lifespan_days: float = 25.0
var energy_capacity: float = 100.0
var energy_burn_rate: float = 0.17       # nectar-equivalent burned per second

# --- bee individuality ---
## Every bee rolls one small stat trait at spawn (see bee_identity.gd
## and BEE_INDIVIDUALITY_PLAN.md). Leans positive so a colony reads as
## quietly gifted rather than half-crippled; starting guesses, not yet
## backed by a simulation -- see CLAUDE.md rule 4.
var trait_positive_chance: float = 0.7
## Small changes are far more likely than big ones. Weights must sum to
## 1.0 -- checked in tests/balance_tests.py.
var trait_magnitude_bands: Array = [
	{"min": 0.02, "max": 0.04, "weight": 0.50},
	{"min": 0.04, "max": 0.07, "weight": 0.35},
	{"min": 0.07, "max": 0.10, "weight": 0.15},
]

## How a bee's fact is rolled: commentary on its own trait, pure
## flavour, or a love/hate/fascination template. Shapes how "meaningful"
## vs "purely silly" a colony feels.
var fact_trait_matched_chance: float = 0.4
var fact_general_chance: float = 0.3
var fact_templated_chance: float = 0.3

## Cosmetic-only jitter on a bee's body tint and size, rolled once at
## spawn. Never gated by is_on_screen -- see bee.gd's _ready().
var visual_size_jitter_range: float = 0.05    # GameConfig, +/- this fraction
var visual_tint_jitter_range: float = 0.05

## Bumble flight: a small side-to-side drift while flying outdoors, so
## movement reads as bee-like instead of beelining. Purely visual -- the
## offset lands on bee.visual_root, never on bee.position, so arrival
## checks, obstacle steering and the stall watchdog are all unaffected.
## Gated on is_on_screen and outdoor flight, so it costs nothing off
## screen or indoors -- see bee.gd::_update_wander_flight and
## bee_movement.gd::move_towards.
##
## The offset eases towards its target (the wander, or zero once the bee
## stops flying outdoors) over bumble_flight_settle_seconds rather than
## snapping straight there -- a bee landing on a flower used to have its
## visuals jump back onto the exact landing spot the instant it arrived,
## which read as a teleport. Easing turns that into a smooth touchdown.
var bumble_flight_on: bool = true
var bumble_flight_amplitude: float = 14.0   # pixels either side of the flight line
var bumble_flight_frequency: float = 1.6    # radians/second
var bumble_flight_settle_seconds: float = 0.20   # time to ease to/from the wander

## Milestone bees ("the hundredth bee this colony ever raised") get a
## deterministic fact instead of a rolled one -- see
## bee_identity.gd::milestone_fact_nth.
var milestone_interval: float = 100.0

## A death epitaph (see BeeSurvival.die) won't repeat more often than
## this, in sim seconds -- a bad night shouldn't fire a dozen of them
## back to back. Same pattern as low_energy_gap.
var epitaph_min_gap: float = 8.0

## Trees and raised ground can be switched off entirely, which clears the
## meadow of anything bees have to route around. Useful for seeing the
## foraging economics without the terrain, and for testing.
var scenery_on: bool = true

## Unexplored meadow stays dark until a bee has flown near it. Purely a
## player-facing view of the meadow -- bees themselves still find
## flowers by the same search either way. See fog_of_war.gd and
## DESIGN_BACKLOG.md 7.4.
var fog_of_war_on: bool = true
## How far around a bee out in the meadow counts as "seen", in world
## units. Larger clears the map faster and makes discovery feel cheaper.
var fog_reveal_radius: float = 240.0
## What happens to a patch once no bee is near it any more: dims to a
## foggy memory (off, the classic fog-of-war reading) or stays exactly
## as visible as the moment it was found (on -- "you've mapped the
## meadow", nothing is ever re-hidden). Either way it's saved once
## explored; this only changes how an explored-but-unlit patch draws.
var fog_permanent_reveal: bool = false

## A bee that dies leaves a mark where it fell, which fades over this
## many in-game days. Nothing reads it -- it is there so losses are
## visible where they happened rather than only in the numbers.
var death_marker_days: float = 5.0

# --- the rival colony ---
## A second colony out in the meadow, run by the game. It isn't a copy of
## the player's simulation -- that would roughly double the cost of the
## game to produce something you can't watch, since you only ever see one
## hive interior at a time. It's an abstract colony advanced once a
## second, with a few visible foragers that draw on the same real
## flowers. The pressure is purely economic: no combat, no interference,
## just two colonies working one meadow.
var rival_hive_on: bool = false
var rival_starting_bees: float = 12.0
var rival_max_bees: float = 90.0
## How far from the player's hive the rival is placed. Far enough that
## the two aren't fighting over the same flowers on day one, close enough
## that they eventually meet in the middle.
var rival_min_distance: float = 900.0
var rival_forage_range: float = 620.0
## Per bee per second, for the once-a-second colony tick.
var rival_eat_per_bee: float = 0.06
var rival_nectar_per_bee: float = 0.28
var rival_pollen_per_bee: float = 0.05
var rival_pollen_per_bee_raised: float = 8.0
var rival_hatch_rate: float = 0.004
## Brood one nurse can start per second. Together with the hatch rate
## this sets how fast the rival grows -- not where it settles, which is
## decided by the crowding and eating rates. Slow enough that it isn't
## fully grown by the end of the first week, which would read as having
## been placed there rather than having got there.
var rival_brood_per_nurse: float = 0.012
## How fast a colony loses bees once its stores run out.
var rival_starve_rate: float = 0.4
## Crowding. More bees working the same patch of meadow get less each,
## so income per bee falls as the colony grows. This is what gives the
## rival a carrying capacity that depends on the forage available rather
## than always running up to its hard cap: simulated without it, it
## either reached the cap or died, with nothing in between. Lower means
## the meadow supports fewer of them.
var rival_crowding_scale: float = 30.0
## The colony only raises brood while it has this many days of food in
## hand. Growing on an empty larder is what made it boom and then
## collapse rather than settle.
var rival_brood_gate_days: float = 40.0
## Cap on stores, per bee, so a rich colony banks a sensible reserve
## instead of an ever-growing number nothing ever spends.
var rival_store_per_bee: float = 400.0
## Nectar one visible rival forager takes from a flower per visit. This
## is the only way the rival touches the player's world, and it's what
## makes it competition rather than scenery.
var rival_flower_take: float = 4.0

# --- seasons ---
## Species come into flower at different times of the year, so the best
## ground moves through a run. This is the cheapest way to make three
## systems that already exist matter more: floral constancy becomes a
## commitment rather than a curiosity, forage start points matter because
## the good patch moves, and the pollen supply has a real gap in it,
## which is what makes storing ahead worth doing.
var seasons_on: bool = true
## How long a full year is. Winter is scheduled separately and does not
## come out of this.
var season_length_days: float = 60.0

# --- disease ---
## Pathogen pressure builds in a hive that isn't kept clean and knocks
## down brood development and bee lifespan. It is what turns clearing
## from tidying into preventative work: the cost of ignoring it arrives
## later and all at once, rather than immediately.
var disease_on: bool = true
## How fast pressure builds, per corpse per second, and per bee per
## second from crowding (bees per cell, not bees).
##
## Tuned against the recovery rate so that a colony with one dead larva
## in it never crosses the threshold at all, two becomes a problem in
## about three days, and four is urgent within one. At the first numbers
## I wrote, a single body crossed in under two days and a merely crowded
## but perfectly clean colony crossed in under five -- which made this a
## constant tax rather than a consequence of neglect, the exact thing it
## is not supposed to be.
var disease_per_corpse: float = 0.0008
var disease_per_bee: float = 0.000004
## How fast it clears on its own once the cause is dealt with.
var disease_recovery: float = 0.0012
## Pressure above which brood slows and bees start dying early. Below it
## the colony is simply healthy.
var disease_threshold: float = 0.35
## At full pressure, brood development runs this much slower and bees
## live this much less long.
var disease_brood_penalty: float = 0.55
var disease_lifespan_penalty: float = 0.4

# --- gynes leaving ---
## A gyne that reaches maturity and has enough stored energy flies off to
## found a colony of her own. That is the score: a season is measured in
## how many you get away, not in how big the hive got.
var gyne_release_day: float = 0.75   # fraction of the season, earliest
var gyne_release_energy: float = 0.8 # share of a full crop she needs first

# --- winter ---
## How long a winter is and what it costs. Whether one is *scheduled*,
## and when, is state of the run rather than a setting, so it lives in
## Session.
var winter_countdown_days: float = 15.0
var winter_length_days: float = 20.0
## What a bee burns through winter, as a multiple of its ordinary rate.
## Well below 1 because a clustered colony is nearly dormant, and because
## anything higher makes the target impossible: at 0.55 a fifty-bee
## colony needed forty-eight full honey cells, which is more comb than
## the hive has. At 0.15 it needs about thirteen -- a real target that a
## colony can actually reach in the run-up. This is the first number to
## reach for if winter feels trivial or impossible.
var winter_burn_factor: float = 0.15
## How much longer a bee's natural lifespan runs through winter, as a
## multiple of its ordinary one -- real colonies overwinter on the same
## bees rather than replacing them, and a clustered, near-dormant bee
## simply wears out slower. Without this, `bee_lifespan_days` (25) sits
## close enough to `winter_length_days` (20) that a chunk of the colony
## would die of old age over one winter even if perfectly fed, which
## defeats the point of the reduced burn rate above. Picked as a
## starting point, not simulated yet -- per this project's rule on
## balance numbers, model it (alongside winter_burn_factor and
## winter_length_days) before trusting it, the same way winter_burn_factor
## itself was worked out.
var winter_lifespan_factor: float = 4.0

