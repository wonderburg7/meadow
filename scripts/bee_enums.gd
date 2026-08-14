extends RefCounted
## Bee's Role and State enums, split out of bee.gd so every other new
## bee_*.gd file can reference them without preloading the whole
## state machine (that would be a circular preload -- see
## BEE_SPLIT_PLAN.md). A leaf file: no dependencies of its own.
##
## bee.gd aliases these straight back (`const Role = BeeEnums.Role`,
## `const State = BeeEnums.State`), so every existing external
## reference (`Bee.Role.FORAGER`, `Bee.State.X` from hud.gd, main.gd,
## world_building.gd, input_selection.gd, orders_zones.gd,
## year_winter.gd) keeps working completely unchanged.

## HONEY_MAKER is appended rather than slotted in alphabetically because
## hive_cell.hatch_role and hud.gd's HATCH_ROLES store these as plain
## ints -- renumbering the existing ones would silently change what
## every already-earmarked cell raises.
enum Role { FORAGER, NURSERY, BUILDER, EGG_LAYER, IDLE, MINER, HONEY_MAKER }

## Perf section per role, indexed by the Role enum above -- an Array
## lookup rather than building a string every frame, so asking "which
## role is it" in the breakdown costs almost nothing extra.
const ROLE_PERF_SECTIONS := [
	"bee_state_forager", "bee_state_nurse", "bee_state_builder",
	"bee_state_queen", "bee_state_idle", "bee_state_miner", "bee_state_honey",
]
enum State {
	SEEK_FLOWER, TO_FLOWER, INSPECTING, COLLECTING, TO_HIVE,   # forager, outdoors
	DRINKING, SHELTERING,                                  # forager, refuelling / rained off
	MAKING_JELLY, TO_JELLY_CELL, DEPOSITING_JELLY,         # nursery, royal jelly
	IN_HIVE_TO_CELL, DEPOSITING, IN_HIVE_TO_EXIT,          # forager, indoors
	MOVE_TO_POINT, IDLING,                                 # player-commanded
	NURSE_IDLE, TO_BROOD, TENDING,                         # nursery
	TO_FOOD_CELL, LOADING_FOOD,                            # nursery, fetching a meal
	TO_FEED_CELL, FEEDING,                                 # any bee, eating
	BUILD_IDLE, TO_BUILD_SITE, BUILDING,                   # builder
	TO_HAUL_SOURCE, TO_HAUL_TARGET,                        # builder, moving stores
	TO_RESTOCK_SOURCE, TO_RESTOCK_TARGET,                  # builder, keeping cells topped up
	TO_WASTE_EXIT, DUMPING_WASTE,                          # builder, throwing it out
	TO_CLEAN_CELL, CLEANING,                               # comb worker, clearing a dead larva
	MINE_IDLE, TO_MINE_SITE, MINING,                       # miner
	TO_MINE_EXIT, DUMPING_DIRT,                            # miner, full of spoil
	SEEK_POLLEN, TO_POLLEN_CELL, EATING,                   # egg layer
	TO_CELL_TO_LAY, LAYING,
	HONEY_IDLE, TO_NECTAR_CELL, CHEWING,                   # honey maker
	TO_HONEY_CELL, DEPOSITING_HONEY, FANNING,
}
