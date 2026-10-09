extends RefCounted
## Two small environment/role queries -- "is it grounded" (rained or
## seasonally off) and "does this role work indoors" -- split into their
## own leaf file rather than living in bee_survival.gd, because both
## bee_survival.gd and bee_foraging.gd need them and putting them in
## either one would make the two preload each other. See
## BEE_SPLIT_PLAN.md.
##
## Usage: const BeeStatus = preload("res://scripts/bee_status.gd")
##        BeeStatus.grounded(bee)

const BeeEnums = preload("res://scripts/bee_enums.gd")
const Role = BeeEnums.Role

## Should a forager stay in? Rain and winter both stop trips, and having
## one function decide means a bee can never be caught out by one of them
## while checking only the other.
##
## Fixed 14 Aug 2026: this called itself here instead of checking rain,
## almost certainly lost in a refactor -- unconditional recursion until
## GDScript's call stack errors out, which is where the whole 4fps
## drop came from. `_seek_flower` and `_go_to_exit` both call this as
## their first line, which is exactly the two states the perf overlay
## named as the cost.
static func grounded(bee: Node2D) -> bool:
	if Session.rain_intensity > GameConfig.rain_forage_limit:
		return true
	if bee.world != null and is_instance_valid(bee.world) and bee.world.season != null:
		return bee.world.season.foraging_stopped()
	return false


## At the hive door, owned Weather sensing also considers rain on its way.
## The current intensity remains the safety cutoff while rain eases off.
static func grounded_for_departure(bee: Node2D) -> bool:
	if grounded(bee):
		return true
	return (Session.progression != null
		and Session.progression.is_behaviour_enabled("weather_sensing_on")
		and bee.world != null and is_instance_valid(bee.world)
		and bee.world.rain_target > GameConfig.rain_forage_limit)


static func rain_recall_on() -> bool:
	return (Session.rain_intensity > GameConfig.rain_forage_limit
		and Session.progression != null
		and Session.progression.is_behaviour_enabled("rain_recall_on"))


static func works_indoors(bee: Node2D) -> bool:
	return (
		bee.role == Role.NURSERY
		or bee.role == Role.BUILDER
		or bee.role == Role.EGG_LAYER
		or bee.role == Role.MINER
		or bee.role == Role.HONEY_MAKER
	)

