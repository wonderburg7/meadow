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
const Resources = preload("res://scripts/resources.gd")
## PP-5. skills.gd::PRIORITY_CELLS; progression.gd answers whether it is owned.
const PRIORITY_CELLS_SKILL := "skill.brood.priority_cells"

## BB-2. A nurse that cannot get at the ripe bee bread -- every wall of the
## cell taken, or the walk there not done in BEE_BREAD_ERRAND_SECONDS --
## feeds from the pollen she carries for BEE_BREAD_RETRY_SECONDS before she
## tries for it again, so a larva never starves while she queues for it.
const BEE_BREAD_RETRY_SECONDS := 10.0
const BEE_BREAD_ERRAND_SECONDS := 20.0

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
		# BB-2: looked up once for this decision, and only for a worker larva.
		var bread: Node2D = null if bee.target_cell.brood_is_gyne else bee_bread_source(bee)
		if can_feed(bee, bee.target_cell, bread):
			feed_brood(bee, bee.target_cell, bread)
			return
		# Out of one or both halves of the meal. Go and restock, but only
		# if there is actually something in the comb to fetch -- otherwise
		# stay put, since standing over the larva at least speeds up
		# whatever food it has left.
		if restock_possible(bee, bee.target_cell.brood_is_gyne, bread):
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

	var other = choose_brood_cell(bee.hive)
	if other != null and other != bee.target_cell and other.needs_feeding():
		BeeForaging.release_cell_slot(bee)
		bee.target_cell = other
		bee.state = State.TO_BROOD


## PP-5. Is Priority cells owned this run? Without it no cell can be marked
## (orders_zones.gd::_on_cell_feed_first_requested) and no mark is honoured.
static func priority_cells_owned() -> bool:
	return Session.progression != null and Session.progression.is_owned(PRIORITY_CELLS_SKILL)


## The larva a nurse goes to: the hungriest one that needs feeding, else any
## brood at all (hive.gd::find_brood_cell's rule). PP-5: with Priority cells
## owned, a hungry larva in a cell marked "Feed first" comes before every
## unmarked one, whatever food it takes; inside each group the order is the
## same as without the skill. One pass over the brood, the ownership looked
## up once, because a tending nurse asks every frame.
static func choose_brood_cell(hive: Node2D) -> Node2D:
	var honour_marks: bool = priority_cells_owned()
	var hungriest: Node2D = null
	var hungriest_marked: Node2D = null
	var any_brood: Node2D = null
	for cell in hive.cells_holding("brood"):
		if any_brood == null:
			any_brood = cell
		if not cell.needs_feeding():
			continue
		if honour_marks and cell.priority_cell:
			if hungriest_marked == null or cell.brood_fed_seconds < hungriest_marked.brood_fed_seconds:
				hungriest_marked = cell
		elif hungriest == null or cell.brood_fed_seconds < hungriest.brood_fed_seconds:
			hungriest = cell
	if hungriest_marked != null:
		return hungriest_marked
	return hungriest if hungriest != null else any_brood


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


## BB-2. A ripe bee bread cell a nurse can load from, or null. Only ripe
## bee bread is food (hive_cell.gd::is_ripe_bee_bread); a cell still filling
## or fermenting is passed over.
static func ripe_bee_bread_cell(bee: Node2D) -> Node2D:
	for cell in bee.hive.cells_holding(Resources.BEE_BREAD):
		if cell.amount > 0.0 and cell.can_withdraw() and cell.is_ripe_bee_bread():
			return cell
	return null


## BB-2. The ripe bee bread cell this nurse would load from now, or null:
## none is ripe, or she could not get at it lately and is on pollen until
## nurse_bee_bread_retry_at. Every decision looks it up once and passes it on.
static func bee_bread_source(bee: Node2D) -> Node2D:
	if Session.sim_time < bee.nurse_bee_bread_retry_at:
		return null
	return ripe_bee_bread_cell(bee)


## BB-2. Is this nurse carrying any bee bread? A feed takes up to
## brood_feed_bee_bread, so a remainder short of a full ration is fed too
## rather than carried out of the comb for good.
static func carries_bee_bread_feed(bee: Node2D) -> bool:
	return bee.nurse_bee_bread > 0.001


## BB-2. The protein half of a worker larva's meal. Bee bread when she
## carries some; pollen only when there is no bee bread for her to load
## (`bread`, from bee_bread_source), since with some to hand she loads that
## first.
static func _worker_protein_ready(bee: Node2D, bread: Node2D) -> bool:
	if carries_bee_bread_feed(bee):
		return true
	return bee.nurse_pollen >= GameConfig.brood_feed_pollen and bread == null


## Can this nurse feed that particular larva right now, from what she is
## carrying? A gyne is fussier: royal jelly, pollen and honey specifically,
## where a worker larva will take nectar, and bee bread in place of pollen.
## `bread` is bee_bread_source(bee), looked up once by the caller.
static func can_feed(bee: Node2D, cell: Node2D, bread: Node2D) -> bool:
	if cell != null and is_instance_valid(cell) and cell.brood_is_gyne:
		if bee.nurse_pollen < GameConfig.brood_feed_pollen:
			return false
		if bee.nurse_jelly < GameConfig.brood_feed_jelly:
			return false
		return bee.nurse_carb_type == "honey" and bee.nurse_carb >= GameConfig.brood_feed_honey
	return can_feed_brood(bee, bread)


static func can_feed_brood(bee: Node2D, bread: Node2D) -> bool:
	return _worker_protein_ready(bee, bread) and bee.nurse_carb >= carb_per_feed(bee)


## How many complete meals this nurse is carrying, for the info panel --
## whichever half runs out first is the limit. Bee bread is the protein
## half, a part ration counting as a feed; carried pollen counts only while
## she would feed it (no bee bread for her to load), as can_feed decides.
static func feeds_carried(bee: Node2D) -> float:
	var from_protein: float = ceil(bee.nurse_bee_bread / max(0.001, GameConfig.brood_feed_bee_bread) - 0.001)
	if bee_bread_source(bee) == null:
		from_protein += floor(bee.nurse_pollen / max(0.001, GameConfig.brood_feed_pollen))
	var from_carb: float = bee.nurse_carb / max(0.001, carb_per_feed(bee))
	return floor(min(from_protein, from_carb))


## Could a trip to the stores actually improve what this nurse is
## carrying? Deliberately mirrors _nurse_restock_errand's conditions: if
## the two disagreed, a nurse short of pollen with none in the comb would
## bounce between the brood nest and her idle state every frame, being
## told to restock and finding nothing to restock with.
static func restock_possible(bee: Node2D, for_gyne: bool, bread: Node2D) -> bool:
	# BB-2: a worker larva's protein is bee bread while she can load some.
	if not for_gyne and not carries_bee_bread_feed(bee) and bread != null:
		return true
	var pollen_needed: bool = for_gyne or not carries_bee_bread_feed(bee)
	if pollen_needed and bee.nurse_pollen < GameConfig.brood_feed_pollen and bee.hive.find_cell_with("pollen") != null:
		return true
	if bee.nurse_carb < carb_per_feed(bee):
		if bee.hive.find_cell_with("honey") != null or bee.hive.find_brood_nectar() != null:
			return true
	if bee.nurse_jelly < GameConfig.brood_feed_jelly and bee.hive.find_cell_with("jelly") != null:
		return true
	return false


## Feeds from what this nurse is physically carrying. She had to walk to
## a pollen cell and a nectar or honey cell to get it (see
## _nurse_restock_errand) -- food no longer appears in the larva out of
## the colony's totals with no bee going anywhere.
static func feed_brood(bee: Node2D, cell: Node2D, bread: Node2D) -> void:
	if not can_feed(bee, cell, bread):
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
		DiagnosticLog.count_brood_feed()
		return

	var on_honey: bool = bee.nurse_carb_type == "honey"
	# BB-2: bee bread in place of pollen whenever she carries a feed of it.
	# can_feed only let her get here on pollen if none was ripe.
	var on_bee_bread: bool = carries_bee_bread_feed(bee)
	if on_bee_bread:
		bee.nurse_bee_bread -= minf(bee.nurse_bee_bread, GameConfig.brood_feed_bee_bread)
		if bee.nurse_bee_bread <= 0.001:
			bee.nurse_bee_bread = 0.0
	else:
		bee.nurse_pollen -= GameConfig.brood_feed_pollen
	bee.nurse_carb -= carb_per_feed(bee)
	if bee.nurse_carb <= 0.001:
		bee.nurse_carb = 0.0
		bee.nurse_carb_type = ""
	cell.feed_brood(
		GameConfig.brood_feed_seconds_honey if on_honey else GameConfig.brood_feed_seconds,
		on_honey,
		on_bee_bread
	)
	DiagnosticLog.count_brood_feed()


## Only gyne larvae eat royal jelly, and only nurses set to make it
## produce any. A nurse eats pollen and honey and works them into jelly
## in her head glands, then either carries it straight to a gyne larva or
## stores it in a cell set aside for it.

## Where a jelly batch may go. A pending gyne need is urgent enough to
## use any cell, same as other resources -- but with none pending, jelly
## may only go in a cell the player has explicitly pinned to it, or it
## spills into whatever ordinary comb happens to be empty.
static func _jelly_storage_target(bee: Node2D, except: Node2D = null) -> Node2D:
	if bee.hive.has_gyne_brood():
		return bee.hive.find_cell_for("jelly", except)
	return bee.hive.find_designated_cell_for("jelly", except)


static func _can_make_jelly(bee: Node2D) -> bool:
	# no point making it if nothing needs it and there's nowhere to put it
	if not bee.hive.has_gyne_brood() and _jelly_storage_target(bee) == null:
		return false
	if bee.hive.total("pollen") < GameConfig.jelly_pollen_cost:
		return false
	return bee.hive.total_honey() >= GameConfig.jelly_honey_cost


## Catalogue finders all take one bee and return whether they started work.
static func find_brood_cell(bee: Node2D) -> bool:
	var brood = choose_brood_cell(bee.hive)
	if brood == null or (bee.role != Role.NURSERY and not brood.needs_feeding()):
		return false
	if brood.needs_feeding():
		var bread: Node2D = null if brood.brood_is_gyne else bee_bread_source(bee)
		if not can_feed(bee, brood, bread) and nurse_restock_errand(bee, brood.brood_is_gyne, bread):
			return true
	bee.target_cell = brood
	bee.state = State.TO_BROOD
	return true


static func jelly_storage_cell(bee: Node2D) -> bool:
	if bee.nurse_jelly <= 0.0 or bee.hive.find_cell_for("jelly") == null:
		return false
	bee.state = State.TO_JELLY_CELL
	return true


static func can_make_jelly(bee: Node2D) -> bool:
	if not _can_make_jelly(bee):
		return false
	bee.timer = GameConfig.jelly_make_time
	bee.state = State.MAKING_JELLY
	return true


## Standing still while her glands do the work. The pollen and honey are
## taken at the start, so a batch that is interrupted still costs.
static func nurse_make_jelly(bee: Node2D, delta: float) -> void:
	if bee.timer == GameConfig.jelly_make_time:
		if not _can_make_jelly(bee):
			bee.state = State.NURSE_IDLE
			return
		bee.hive.take("pollen", GameConfig.jelly_pollen_cost)
		bee.hive.take("honey", GameConfig.jelly_honey_cost)
		bee.hive.announce()

	bee.timer -= delta
	if bee.timer > 0.0:
		return
	bee.nurse_jelly += GameConfig.jelly_per_batch
	DiagnosticLog.count_jelly_batch()
	bee.state = State.NURSE_IDLE


static func nurse_go_to_jelly_cell(bee: Node2D, delta: float) -> void:
	if bee.target_cell == null or not is_instance_valid(bee.target_cell) or bee.target_cell.space_for("jelly") <= 0.0:
		BeeForaging.release_cell_slot(bee)
		bee.target_cell = _jelly_storage_target(bee)
		if bee.target_cell == null:
			bee.state = State.NURSE_IDLE
		return

	var approach := BeeForaging.approach_cell(bee, bee.target_cell, delta)
	if approach < 0:
		bee.target_cell = _jelly_storage_target(bee, bee.target_cell)
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
static func nurse_restock_errand(bee: Node2D, for_gyne: bool, bread: Node2D) -> bool:
	# BB-2: while she can load ripe bee bread (`bread`, bee_bread_source), a
	# worker larva's protein comes from it rather than from pollen. A gyne
	# still takes pollen.
	if not for_gyne and not carries_bee_bread_feed(bee) and bread != null:
		start_food_errand(bee, bread, Resources.BEE_BREAD)
		return true
	if bee.nurse_pollen < GameConfig.brood_feed_pollen and (for_gyne or not carries_bee_bread_feed(bee)):
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
			carb_cell = bee.hive.find_brood_nectar()   # NF-4: fresh only with the sense
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
	bee.nurse_errand_started_at = Session.sim_time
	bee.state = State.TO_FOOD_CELL


## BB-2. She could not get at the ripe bee bread: on pollen for a while.
static func _bee_bread_out_of_reach(bee: Node2D) -> void:
	bee.nurse_bee_bread_retry_at = Session.sim_time + BEE_BREAD_RETRY_SECONDS
	abandon_food_errand(bee)


static func nurse_go_to_food(bee: Node2D, delta: float) -> void:
	if bee.target_cell == null or not is_instance_valid(bee.target_cell) or bee.target_cell.content_type != bee.nurse_fetching or bee.target_cell.amount <= 0.0:
		abandon_food_errand(bee)
		return
	if bee.nurse_fetching == "honey" and not bee.target_cell.is_ripe_honey():
		abandon_food_errand(bee)
		return
	# NF-4: nectar that fermented on her way over is left, with the sense.
	if bee.nurse_fetching == "nectar" and bee.hive.avoids_as_sour(bee.target_cell):
		abandon_food_errand(bee)
		return
	var for_bread: bool = bee.nurse_fetching == Resources.BEE_BREAD
	if for_bread and not bee.target_cell.is_ripe_bee_bread():
		abandon_food_errand(bee)
		return
	if for_bread and Session.sim_time - bee.nurse_errand_started_at > BEE_BREAD_ERRAND_SECONDS:
		_bee_bread_out_of_reach(bee)
		return

	var approach := BeeForaging.approach_cell(bee, bee.target_cell, delta)
	if approach < 0:
		if for_bread:
			_bee_bread_out_of_reach(bee)
		else:
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
		elif bee.nurse_fetching == Resources.BEE_BREAD:
			bee.nurse_bee_bread += bee.target_cell.take_resource(Resources.BEE_BREAD, GameConfig.brood_feed_bee_bread * feeds)
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

