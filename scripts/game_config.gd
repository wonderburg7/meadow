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
var seconds_per_day: float = 300.0      # 5 real minutes per in-game day

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
var queen_eat_rate: float = 4.0         # pollen per second the queen consumes
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

## A larva that has gone this long with nothing to eat dies. The cell is
## then blocked by the body until an architect on maintenance clears it
## out and carries it away -- neglect costs you the cell as well as the
## bee.
var larva_death_seconds: float = 90.0
var cell_clean_time: float = 20.0   # architect-seconds to clear a dead larva

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
var bee_lifespan_days: float = 30.0
var energy_capacity: float = 100.0
var energy_burn_rate: float = 0.35       # nectar-equivalent burned per second

# --- interface ---
## Turn the small "i" tooltip badges off once you know what everything
## does. Takes effect immediately -- no restart needed.
var show_info_badges: bool = true

# --- runtime clock (not tunable; advanced by main.gd) ---
var sim_time: float = 0.0

# --- session preferences (not tunable; set from dialogs) ---
var warn_on_discard: bool = true        # "don't show this again" clears this

## Which starting stage the next run builds. 0 means "use the tuning
## numbers as they are"; 1-3 are the fixed stages offered by the main
## menu (see main_menu.gd and main.gd's _spawn_* functions):
##   1  the queen alone, no comb
##   2  queen + one nectar forager + one cell
##   3  queen + one of each forager + three cells
## Read on scene build and left as-is, so a plain Restart Run repeats
## whatever stage you last chose.
var starting_level: int = 0

## True the first time the game runs, so main.gd knows to open the menu
## rather than dropping straight into a colony. Cleared once the player
## picks a stage.
var menu_pending: bool = true
