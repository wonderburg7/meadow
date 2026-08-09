extends Node
## Autoload (registered in project.godot under [autoload]) -- the one
## place all the tunable prototype numbers live. Bees, flowers and the
## hive read these when they're created; the tuning dropdown edits them
## directly. Because this is an autoload it survives a scene reload, so
## "Restart Run" respawns everything using whatever values are set here.

# --- world ---
var flower_count: float = 20.0
var hive_cell_count: float = 5.0        # cells the hive starts with; builders add more
var starting_bees: float = 3.0
var starting_nurses: float = 1.0        # without at least one nurse, laid eggs never reach a cell
var starting_builders: float = 1.0
var seconds_per_day: float = 300.0      # 5 real minutes per in-game day

# --- flowers (per-species values are in flower.gd; these scale them) ---
var nectar_recharge_rate: float = 0.5   # per second
var pollen_recharge_rate: float = 0.1   # per second

# --- foraging ---
var bee_speed: float = 110.0
var flower_handling_time: float = 2.0
var nectar_collection_rate: float = 5.0
var pollen_collection_rate: float = 2.0
var deposit_time: float = 2.5
var nectar_stomach_capacity: float = 50.0
var pollen_stomach_capacity: float = 25.0

# --- hive ---
var cell_capacity: float = 200.0        # one resource per cell, or one developing bee
var egg_pollen_cost: float = 20.0       # pollen the queen must eat to lay one egg
var queen_eat_rate: float = 4.0         # pollen per second the queen consumes
var queen_speed_factor: float = 0.45    # she's larger, so slower than a worker
var brood_develop_time: float = 90.0    # seconds of development before a bee emerges
var tending_speed_bonus: float = 2.0    # multiplier while a nursery worker is tending

# --- comb building ---
## Builder-seconds needed to finish one cell. Two builders working the
## same cell halve the wall-clock time, three thirds it, and so on.
var cell_build_time: float = 90.0
## Extra energy a builder burns while actually building. Bees make wax
## from the sugar they've eaten, so building is paid for in energy
## rather than from a separate wax stockpile.
var build_energy_burn: float = 0.6

# --- hive geometry ---
var hive_wall_radius: float = 250.0     # inner radius of the hive wall
var hive_cell_size: float = 17.0        # centre-to-corner of one comb cell
var hive_cell_spacing: float = 19.0     # spacing passed to hex_to_pixel

# --- bee life ---
var bee_lifespan_days: float = 30.0
var energy_capacity: float = 100.0
var energy_burn_rate: float = 0.3       # nectar-equivalent burned per second

# --- runtime clock (not tunable; advanced by main.gd) ---
var sim_time: float = 0.0

# --- session preferences (not tunable; set from dialogs) ---
var warn_on_discard: bool = true        # "don't show this again" clears this
