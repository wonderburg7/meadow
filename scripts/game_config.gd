extends Node
## Autoload (registered in project.godot under [autoload]) -- the one
## place all the tunable prototype numbers live. Bees, flowers and the
## hive read these when they're created; the tuning dropdown edits them
## directly. Because this is an autoload it survives a scene reload, so
## "Restart Run" respawns everything using whatever values are set here.

# --- world ---
var flower_count: float = 250.0         # the meadow is topped back up to this
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
var tending_speed_bonus: float = 2.0    # multiplier while a nursery worker is tending

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
var bee_eat_rate: float = 15.0          # energy per second while feeding

# --- flight ---
## Flying costs energy on top of simply being alive, so a forager's range
## is paid for rather than free. Wet wings cost more again (see rain).
var flight_energy_burn: float = 0.25

## A forager out in the meadow drinks nectar straight from a flower when
## it drops below this share of its capacity -- it doesn't have to fly
## home to eat. Pollen foragers do this too: they aren't collecting
## nectar, but they will still drink it.
var forager_drink_threshold: float = 0.5
var nectar_drink_rate: float = 10.0     # energy per second while drinking

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
var hive_entrance_width: float = 1.0    # tiles left out of the soil for the doorway
var hive_cell_size: float = 17.0        # centre-to-corner of one comb tile
var hive_cell_spacing: float = 19.0     # spacing passed to hex_to_pixel

## Bees walking over comb are slower than over open floor -- they have
## to pick their way across the cells rather than fly straight.
var cell_slow_factor: float = 0.55

# --- bee life ---
var bee_lifespan_days: float = 25.0
var energy_capacity: float = 100.0
var energy_burn_rate: float = 0.35       # nectar-equivalent burned per second

## Trees and raised ground can be switched off entirely, which clears the
## meadow of anything bees have to route around. Useful for seeing the
## foraging economics without the terrain, and for testing.
var scenery_on: bool = true

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

