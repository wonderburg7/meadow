extends RefCounted
## Nursery work and royal jelly, split out of bee.gd -- see
## BEE_SPLIT_PLAN.md.
##
## Usage: const BeeNursery = preload("res://scripts/bee_nursery.gd")
##        BeeNursery.nurse_tend(bee, delta)

const BeeEnums = preload("res://scripts/bee_enums.gd")
const Role = BeeEnums.Role
const State = BeeEnums.State
const BeeForaging = preload("res://scripts/bee_foraging.gd")

static func nurse_go_to_brood(bee: Node2D, delta: float) -> void:
	if bee.target_cell == null or not is_instance_valid(bee.target_cell) or bee.target_cell.content_type != "brood":
		BeeForaging.release_cell_slot(bee)
		bee.state = State.NURSE_IDLE
		return
	var approach := BeeForaging.approach_cell(bee, bee.target_cell, delta)
	if approach < 0:
		bee.target_cell = null
		bee.state = State.NURSE_IDLE
		return
	if approach == 1:
		bee.state = State.TENDING


static func nurse_tend(bee: Node2D, _delta: float) -> void:
	if bee.target_cell == null or not is_instance_valid(bee.target_cell) or bee.target_cell.content_type != "brood":
		BeeForaging.release_cell_slot(bee)
		bee.state = State.NURSE_IDLE
		return
	bee.target_cell.being_tended = true   # cell reads this each frame to speed development

	if bee.target_cell.needs_feeding():
		if can_feed(bee, bee.target_cell):
			feed_brood(bee, bee.target_cell)
			return
		# Out of one or both halves of the meal. Go and restock, but only
		# if there is actually something in the comb to fetch -- otherwise
		# stay put, since standing over the larva at least speeds up
		# whatever food it has left.
		if restock_possible(bee):
			BeeForaging.release_cell_slot(bee)
			bee.target_cell = null
			bee.state = State.NURSE_IDLE
		return

	# This larva has food in it for now.
	#
	# A bee nursing as a backup job (the queen, unless you change it)
	# hands back and re-checks its real role. A dedicated nurse moves on
	# to whichever larva is hungriest if there is one -- otherwise a
	# single nurse would camp the first cell it found while every other
	# larva in the nest starved -- and only stays put when there is
	# nothing more urgent, since standing over brood speeds it up.
	if bee.role != Role.NURSERY:
		BeeForaging.release_cell_slot(bee)
		bee.target_cell = null
		bee.state = State.NURSE_IDLE
		return

	var other = bee.hive.find_brood_cell()
	if other != null and other != bee.target_cell and other.needs_feeding():
		BeeForaging.release_cell_slot(bee)
		bee.target_cell = other
		bee.state = State.TO_BROOD


## Drops a meal into the cell. Larvae don't develop at all on their own
## any more (see HiveCell._develop_brood): each feed buys a fixed stretch
## of development and then it stalls until someone comes back.
##
## Pollen is the protein and is required either way. The carbohydrate is
## honey if the colony has any, because it's denser and lasts the larva
## longer -- which is the main reason a colony bothers making honey at
## all -- and nectar otherwise.
## How much carbohydrate one feed takes out of what the nurse is
## carrying. Honey goes further, which is the whole point of it.
static func carb_per_feed(bee: Node2D) -> float:
	return GameConfig.brood_feed_honey if bee.nurse_carb_type == "honey" else GameConfig.brood_feed_nectar


## Can this nurse feed that particular larva right now, from what she is
## carrying? A gyne is fussier: royal jelly and honey specifically, where
## a worker larva will take nectar.
static func can_feed(bee: Node2D, cell: Node2D) -> bool:
	if bee.nurse_pollen < GameConfig.brood_feed_pollen:
		return false
	if cell != null and is_instance_valid(cell) and cell.brood_is_gyne:
		if bee.nurse_jelly < GameConfig.brood_feed_jelly:
			return false
		return bee.nurse_carb_type == "honey" and bee.nurse_carb >= GameConfig.brood_feed_honey
	return bee.nurse_carb >= carb_per_feed(bee)


static func can_feed_brood(bee: Node2D) -> bool:
	return bee.nurse_pollen >= GameConfig.brood_feed_pollen and bee.nurse_carb >= carb_per_feed(bee)


## How many complete meals this nurse is carrying, for the info panel --
## whichever half runs out first is the limit.
static func feeds_carried(bee: Node2D) -> float:
	var from_pollen: float = bee.nurse_pollen / max(0.001, GameConfig.brood_feed_pollen)
	var from_carb: float = bee.nurse_carb / max(0.001, carb_per_feed(bee))
	return floor(min(from_pollen, from_carb))


## Could a trip to the stores actually improve what this nurse is
## carrying? Deliberately mirrors _nurse_restock_errand's conditions: if
## the two disagreed, a nurse short of pollen with none in the comb would
## bounce between the brood nest and her idle state every frame, being
## told to restock and finding nothing to restock with.
static func restock_possible(bee: Node2D) -> bool:
	if bee.nurse_pollen < GameConfig.brood_feed_pollen and bee.hive.find_cell_with("pollen") != null:
		return true
	if bee.nurse_carb < carb_per_feed(bee):
		if bee.hive.find_cell_with("honey") != null or bee.hive.find_cell_with("nectar") != null:
			return true
	if bee.nurse_jelly < GameConfig.brood_feed_jelly and bee.hive.find_cell_with("jelly") != null:
		return true
	return false


## Feeds from what this nurse is physically carrying. She had to walk to
## a pollen cell and a nectar or honey cell to get it (see
## _nurse_restock_errand) -- food no longer appears in the larva out of
## the colony's totals with no bee going anywhere.
static func feed_brood(bee: Node2D, cell: Node2D) -> void:
	if not can_feed(bee, cell):
		return

	if cell.brood_is_gyne:
		# A gyne is raised on royal jelly. Nothing else will do, and it
		# has to come with honey rather than nectar.
		bee.nurse_pollen -= GameConfig.brood_feed_pollen
		bee.nurse_jelly -= GameConfig.brood_feed_jelly
		bee.nurse_carb -= GameConfig.brood_feed_honey
		if bee.nurse_carb <= 0.001:
			bee.nurse_carb = 0.0
			bee.nurse_carb_type = ""
		cell.feed_brood(GameConfig.brood_feed_seconds_gyne, true)
		return

	var on_honey: bool = bee.nurse_carb_type == "honey"
	bee.nurse_pollen -= GameConfig.brood_feed_pollen
	bee.nurse_carb -= carb_per_feed(bee)
	if bee.nurse_carb <= 0.001:
		bee.nurse_carb = 0.0
		bee.nurse_carb_type = ""
	cell.feed_brood(
		GameConfig.brood_feed_seconds_honey if on_honey else GameConfig.brood_feed_seconds,
		on_honey
	)


## Only gyne larvae eat royal jelly, and only nurses set to make it
## produce any. A nurse eats pollen and honey and works them into jelly
## in her head glands, then either carries it straight to a gyne larva or
## stores it in a cell set aside for it.

static func can_make_jelly(bee: Node2D) -> bool:
	# no point making it if nothing needs it and there's nowhere to put it
	if not bee.hive.has_gyne_brood() and bee.hive.find_cell_for("jelly") == null:
		return false
	if bee.hive.total("pollen") < GameConfig.jelly_pollen_cost:
		return false
	return bee.hive.total_honey() >= GameConfig.jelly_honey_cost


## Standing still while her glands do the work. The pollen and honey are
## taken at the start, so a batch that is interrupted still costs.
static func nurse_make_jelly(bee: Node2D, delta: float) -> void:
	if bee.timer == GameConfig.jelly_make_time:
		if not can_make_jelly(bee):
			bee.state = State.NURSE_IDLE
			return
		bee.hive.take("pollen", GameConfig.jelly_pollen_cost)
		bee.hive.take("honey", GameConfig.jelly_honey_cost)
		bee.hive.announce()

	bee.timer -= delta
	if bee.timer > 0.0:
		return
	bee.nurse_jelly += GameConfig.jelly_per_batch
	bee.state = State.NURSE_IDLE


static func nurse_go_to_jelly_cell(bee: Node2D, delta: float) -> void:
	if bee.target_cell == null or not is_instance_valid(bee.target_cell) or bee.target_cell.space_for("jelly") <= 0.0:
		BeeForaging.release_cell_slot(bee)
		bee.target_cell = bee.hive.find_cell_for("jelly")
		if bee.target_cell == null:
			bee.state = State.NURSE_IDLE
		return

	var approach := BeeForaging.approach_cell(bee, bee.target_cell, delta)
	if approach < 0:
		bee.target_cell = bee.hive.find_cell_for("jelly", bee.target_cell)
		return
	if approach == 1:
		bee.timer = GameConfig.nurse_load_time
		bee.state = State.DEPOSITING_JELLY


static func nurse_deposit_jelly(bee: Node2D, delta: float) -> void:
	bee.timer -= delta
	if bee.timer > 0.0:
		return
	if bee.target_cell != null and is_instance_valid(bee.target_cell):
		# She keeps one feed's worth on her, so she isn't storing jelly
		# and then immediately fetching it back out again.
		var keep: float = GameConfig.brood_feed_jelly if bee.hive.has_gyne_brood() else 0.0
		var spare: float = max(0.0, bee.nurse_jelly - keep)
		bee.nurse_jelly -= bee.target_cell.add_resource("jelly", spare)
		bee.hive.announce()
	BeeForaging.release_cell_slot(bee)
	bee.target_cell = null
	bee.state = State.NURSE_IDLE


## Sends this nurse off to load up if she is short of either half of a
## meal. Returns true when an errand was started. Honey is preferred over
## nectar because a honey feed carries a larva further.
static func nurse_restock_errand(bee: Node2D, for_gyne: bool = false) -> bool:
	if bee.nurse_pollen < GameConfig.brood_feed_pollen:
		var pollen_cell = bee.hive.find_cell_with("pollen")
		if pollen_cell != null:
			start_food_errand(bee, pollen_cell, "pollen")
			return true

	# A gyne larva takes honey and nothing else, so there's no falling
	# back on nectar for one.
	var carb_needed: float = GameConfig.brood_feed_honey if for_gyne else carb_per_feed(bee)
	var carb_short: bool = bee.nurse_carb < carb_needed or (for_gyne and bee.nurse_carb_type != "honey")
	if carb_short:
		var carb_type := "honey"
		var carb_cell = bee.hive.find_cell_with("honey")
		if carb_cell == null and not for_gyne:
			carb_type = "nectar"
			carb_cell = bee.hive.find_cell_with("nectar")
		if carb_cell != null:
			start_food_errand(bee, carb_cell, carb_type)
			return true

	if for_gyne and bee.nurse_jelly < GameConfig.brood_feed_jelly:
		var jelly_cell = bee.hive.find_cell_with("jelly")
		if jelly_cell != null:
			start_food_errand(bee, jelly_cell, "jelly")
			return true
		# nobody has made any -- make it here if this nurse is set to
		if bee.nurse_mode != "feed" and can_make_jelly(bee):
			bee.timer = GameConfig.jelly_make_time
			bee.state = State.MAKING_JELLY
			return true

	return false


static func start_food_errand(bee: Node2D, cell: Node2D, what: String) -> void:
	BeeForaging.release_cell_slot(bee)
	bee.target_cell = cell
	bee.nurse_fetching = what
	bee.state = State.TO_FOOD_CELL


static func nurse_go_to_food(bee: Node2D, delta: float) -> void:
	if bee.target_cell == null or not is_instance_valid(bee.target_cell) or bee.target_cell.content_type != bee.nurse_fetching or bee.target_cell.amount <= 0.0:
		abandon_food_errand(bee)
		return
	if bee.nurse_fetching == "honey" and not bee.target_cell.is_ripe_honey():
		abandon_food_errand(bee)
		return

	var approach := BeeForaging.approach_cell(bee, bee.target_cell, delta)
	if approach < 0:
		abandon_food_errand(bee)
		return
	if approach == 1:
		bee.timer = GameConfig.nurse_load_time
		bee.state = State.LOADING_FOOD


## Filling up. She takes several feeds' worth in one visit, so she isn't
## walking back to the stores for every single larva.
static func nurse_load_food(bee: Node2D, delta: float) -> void:
	bee.timer -= delta
	if bee.timer > 0.0:
		return

	if bee.target_cell != null and is_instance_valid(bee.target_cell):
		var feeds: float = max(1.0, GameConfig.nurse_carry_feeds)
		if bee.nurse_fetching == "pollen":
			bee.nurse_pollen += bee.target_cell.take_resource("pollen", GameConfig.brood_feed_pollen * feeds)
		elif bee.nurse_fetching == "jelly":
			bee.nurse_jelly += bee.target_cell.take_resource("jelly", GameConfig.brood_feed_jelly * feeds)
		else:
			var per_feed: float = GameConfig.brood_feed_honey if bee.nurse_fetching == "honey" else GameConfig.brood_feed_nectar
			var got: float = bee.target_cell.take_resource(bee.nurse_fetching, per_feed * feeds)
			if got > 0.0:
				# a nurse carries one kind of carbohydrate at a time
				if bee.nurse_carb_type != bee.nurse_fetching:
					bee.nurse_carb = 0.0
				bee.nurse_carb += got
				bee.nurse_carb_type = bee.nurse_fetching
		bee.hive.announce()

	abandon_food_errand(bee)


static func abandon_food_errand(bee: Node2D) -> void:
	BeeForaging.release_cell_slot(bee)
	bee.target_cell = null
	bee.nurse_fetching = ""
	bee.state = State.NURSE_IDLE

