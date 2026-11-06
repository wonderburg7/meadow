extends RefCounted
## Selection-panel text. Read only when the HUD refreshes; owns no bee state.

const BeeEnums = preload("res://scripts/bee_enums.gd")
const Role = BeeEnums.Role
const State = BeeEnums.State
const BeeStatus = preload("res://scripts/bee_status.gd")
const BeeSurvival = preload("res://scripts/bee_survival.gd")
const BeeForaging = preload("res://scripts/bee_foraging.gd")
const BeeNursery = preload("res://scripts/bee_nursery.gd")
const BeeBuilding = preload("res://scripts/bee_building.gd")
const Roles = preload("res://scripts/roles.gd")

## Why isn't this bee doing anything?
##
## "Nothing is happening and I can't tell why" is the worst state to
## leave a player in, and it is easy to reach: a nurse with no brood, a
## miner with nothing marked and automine off, a comb worker with
## nowhere left to build all look identical from outside -- a bee
## standing still.
##
## Each role knows what it was looking for, so each can say what it
## didn't find. Returns "" when the bee is genuinely busy.
static func idle_reason(bee: Node2D) -> String:
	if bee.hive == null:
		return ""
	if bee.challenge_vocabulary_limited() and not (bee.state in bee.CHALLENGE_TAUGHT_STATES):
		return ""
	match bee.state:
		State.NURSE_IDLE:
			if bee.role == Role.EGG_LAYER:
				if bee.hive.find_cell_with("pollen") == null:
					return "No pollen in the comb — she can't eat, so she can't lay."
				if not bee.hive.has_room_for_egg():
					return "Nowhere to lay. Every nursery cell is occupied and there is no spare comb — reserve more cells for eggs, or build some."
				return ""
			if bee.hive.cells_holding("brood").is_empty():
				return "No brood to look after. Nothing has been laid, or it has all emerged."
			return ""
		State.BUILD_IDLE:
			if bee.architect_mode == "restock":
				if not BeeBuilding.has_restock_orders(bee):
					return "No restocking orders. Select some comb and choose a resource to keep it full of."
				return "Nowhere to draw from. Every cell holding %s is either sealed, blocked, or one of the cells being filled." % bee.restock_resource
			if bee.architect_mode == "maintain":
				return "Nothing to clear. No dead larvae and no cells waiting to be emptied."
			# T2-14: ask whether there is room, without starting a site. Starting
			# one here made every selected idle comb worker grow the comb.
			if not bee.hive.has_room_to_build(bee.home_hex if bee.has_home_hex else Vector2i.ZERO):
				return "Nowhere left to build. The open floor is full — put miners on the soil to make more room, or clear a keep-clear tile."
			if not bee._action_available("comb_build_outward"):
				return "Nothing marked to build. Mark cells to build, or get the Automation skill so comb workers build outward on their own."
			return ""
		State.MINE_IDLE:
			if not bee.mine_queue.is_empty():
				return "The blocks you marked are still buried. They will be dug once the soil in front of them is gone."
			if bee.automine:
				if not bee._action_available("mine_automine_block"):
					return "Dig on its own needs the Automation skill. Until then, mark blocks with Mine."
				return "No soil left within reach. Everything diggable has been dug, or what's left is behind bedrock."
			return "Nothing marked to dig, and this miner isn't digging on its own. Use Mine to give it a block, or turn on \"Dig on its own\"."
		State.HONEY_IDLE:
			if bee.hive.find_cell_with("nectar") == null:
				return "No nectar to work with. Honey is made from stored nectar, so the foragers have to bring some in first."
			if bee.hive.find_honey_target() == null:
				return "Nowhere to put the mix. Every cell is full or reserved for something else — free one up, or build more comb."
			return ""
		State.SEEK_FLOWER:
			if BeeStatus.grounded(bee):
				if Session.winter_here:
					return "Winter. Nothing is out, so the foragers are staying in."
				return "Raining too hard to fly. They'll go out when it eases."
			if BeeForaging.nearest_flower(bee, false, GameConfig.forage_search_radius) == null:
				return "Nothing worth visiting. Every flower nearby is empty, out of season, or already taken."
			return ""
		State.IDLING:
			return "Set to idle. It will stay put until you give it a job."
	return ""  # gdlint: ignore=max-returns

## The selection panel's "Now:" line: what this bee is doing, with a
## note while it is tipsy (NF-3, wording in bee_status.gd).
static func task_description(bee: Node2D) -> String:
	var line: String = _task_line(bee)
	if bee.tipsy_time_left > 0.0 and bee.state != State.TIPSY_WANDER:
		return BeeStatus.tipsy_note(bee, line)
	return line

## A plain-language description of what this bee is doing right now,
## shown in the selection panel. Deliberately concrete ("returning
## pollen to the hive") rather than naming internal states.
static func _task_line(bee: Node2D) -> String:
	if bee.challenge_vocabulary_limited() and not (bee.state in bee.CHALLENGE_TAUGHT_STATES):
		return "busy in the hive"
	match bee.state:
		State.SEEK_FLOWER:
			return "looking for a %s flower" % bee.resource_type
		State.SEARCHING:
			return "flying a search loop, looking for a %s flower" % bee.resource_type
		State.TO_FLOWER:
			return "flying to a flower for %s" % bee.resource_type
		State.INSPECTING:
			return "inspecting a flower before deciding whether to feed"
		State.COLLECTING:
			if bee.timer > 0.0:
				return "landing on a flower"
			return "collecting %s (%d carried)" % [bee.resource_type, int(bee.current_load)]
		State.TO_HIVE:
			if bee.energy <= 0.0:
				return "crawling home with no energy left (health %d%%)" % int(100.0 * bee.health / max(0.001, GameConfig.health_capacity))
			return "returning %s to the hive (%d carried)" % [bee.current_load_type, int(bee.current_load)]
		State.IN_HIVE_TO_CELL:
			if bee.target_cell == null or not is_instance_valid(bee.target_cell):
				if bee.hive.cells.is_empty():
					return "waiting with %s until the first cell is built" % bee.current_load_type
				return "waiting with %s: no cell has room for it" % bee.current_load_type
			return "carrying %s to a cell" % bee.current_load_type
		State.DEPOSITING:
			return "unloading %s into a cell" % bee.current_load_type
		State.IN_HIVE_TO_EXIT:
			if BeeSurvival.must_rest(bee):
				return "resting to recover before going back out (health %d%%)" % int(100.0 * bee.health / max(0.001, GameConfig.health_capacity))
			return "heading back out of the hive"
		State.MOVE_TO_POINT:
			return "moving where you sent it"
		State.IDLING:
			return "idle -- waiting for orders"
		State.MINE_IDLE:
			var base_mine := "looking for a block to dig" if bee.automine else "waiting for a block to be marked"
			return base_mine + _idle_backup_note(bee)
		State.TO_MINE_SITE:
			return "walking to a marked soil block"
		State.MINING:
			var dug := 0
			if bee.target_block and is_instance_valid(bee.target_block):
				dug = int(bee.target_block.mine_fraction() * 100.0)
			return "digging out soil (%d%%, carrying %d/%d dirt)" % [dug, int(bee.dirt_load), int(GameConfig.miner_dirt_capacity)]
		State.TO_MINE_EXIT:
			return "carrying spoil out to dump it"
		State.DUMPING_DIRT:
			return "emptying out a load of dirt"
		State.NURSE_IDLE:
			return "looking for brood work" + _idle_backup_note(bee)
		State.TO_BROOD:
			return "going to tend the brood"
		State.TENDING:
			if bee.target_cell and is_instance_valid(bee.target_cell) and bee.target_cell.content_type == "brood":
				if bee.target_cell.brood_fed_seconds > 0.0:
					return "feeding a larva (%ds of development left in it)" % int(bee.target_cell.brood_fed_seconds)
				return "tending a larva -- no pollen in the comb to feed it"
			return "tending a developing bee"
		State.DRINKING:
			return "drinking nectar from the flower to refuel (energy %d%%)" % int(100.0 * bee.energy / max(0.001, GameConfig.energy_capacity))
		State.SHELTERING:
			return "sheltering at the hive -- too wet to forage"
		State.AT_ENTRANCE_SEEKING:
			if bee.is_scouting:
				return "scouting: bout %d of 3, waiting at the entrance for a tip (%ds)" % [bee.scout_bout + 1, int(max(0.0, bee.timer))]
			return "waiting at the entrance, hoping to be told a better patch (%ds)" % int(max(0.0, bee.timer))
		State.AT_ENTRANCE_MENTORING:
			return "waiting at the entrance, willing to recruit a struggling forager (%ds)" % int(max(0.0, bee.timer))
		State.DANCING:
			if bee.dance_role == "mentor":
				return "dancing to show a struggling forager a better patch (%ds)" % int(max(0.0, bee.timer))
			return "being shown a better patch by a forager nearby (%ds)" % int(max(0.0, bee.timer))
		State.MAKING_JELLY:
			return "working pollen and honey into royal jelly (%ds)" % int(max(0.0, bee.timer))
		State.TO_JELLY_CELL:
			return "carrying royal jelly to a cell"
		State.DEPOSITING_JELLY:
			return "storing royal jelly"
		State.TO_FOOD_CELL:
			return "going to collect %s for the brood" % bee.nurse_fetching.replace("_", " ")
		State.LOADING_FOOD:
			return "loading up with %s to feed the brood" % bee.nurse_fetching.replace("_", " ")
		State.TO_FEED_CELL:
			return "hungry -- heading to a cell to eat"
		State.FEEDING:
			var eating := "nectar"
			if bee.target_cell and is_instance_valid(bee.target_cell):
				eating = bee.target_cell.content_type
			return "eating %s (energy %d%%)" % [
				eating, int(100.0 * bee.energy / max(0.001, GameConfig.energy_capacity)),
			]
		State.HONEY_IDLE:
			return "looking for nectar to turn into honey" + _idle_backup_note(bee)
		State.TO_NECTAR_CELL:
			return "going to a nectar cell to fill up"
		State.CHEWING:
			return "chewing enzymes into nectar (%ds left)" % int(max(0.0, bee.timer))
		State.TO_HONEY_CELL:
			return "carrying the honey mix to a cell"
		State.DEPOSITING_HONEY:
			return "spitting the mix into a honey cell"
		State.FANNING:
			var dried := 0
			if bee.fan_target and is_instance_valid(bee.fan_target):
				dried = int(bee.fan_target.ripen_fraction() * 100.0)
			return "fanning a honey cell dry (%d%%)" % dried
		State.TO_BEE_BREAD_CELL:
			return "carrying bee bread to a cell"
		State.DEPOSITING_BEE_BREAD:
			return "packing bee bread into a cell"
		State.BUILD_IDLE:
			return "looking for building work" + _idle_backup_note(bee)
		State.TO_BUILD_SITE:
			return "walking to a cell under construction"
		State.BUILDING:
			var pct := 0
			if bee.target_cell and is_instance_valid(bee.target_cell):
				pct = int(bee.target_cell.build_fraction() * 100.0)
			return "building a new cell (%d%%)" % pct
		State.TO_RESTOCK_SOURCE:
			return "fetching %s to top up a cell it keeps full" % bee.restock_resource
		State.TO_RESTOCK_TARGET:
			return "carrying %s to a cell it keeps full" % bee.current_load_type
		State.TO_HAUL_SOURCE:
			return "going to clear a reassigned cell"
		State.TO_HAUL_TARGET:
			return "moving %s to another cell" % bee.current_load_type
		State.TO_CLEAN_CELL:
			if bee.target_body != null:
				return "going to carry a dead bee out of the hive"
			return "going to clear a dead larva out of a cell"
		State.CLEANING:
			if bee.target_body != null and is_instance_valid(bee.target_body):
				var lifted := int(clampf(bee.target_body.clear_progress / maxf(0.001, GameConfig.cell_clean_time), 0.0, 1.0) * 100.0)
				return "lifting a dead bee to carry out (%d%%)" % lifted
			var cleaned := 0
			if bee.target_cell and is_instance_valid(bee.target_cell):
				cleaned = int(bee.target_cell.clean_fraction() * 100.0)
			return "clearing a dead larva out of a cell (%d%%)" % cleaned
		State.TO_SEAL_CELL:
			if bee.target_cell and is_instance_valid(bee.target_cell) and bee.target_cell.is_closed:
				return "going to take the wax cap off a cell"
			return "going to cap a cell with wax"
		State.SEALING:
			var capped := 0
			if bee.target_cell and is_instance_valid(bee.target_cell):
				capped = int(bee.target_cell.seal_work_fraction() * 100.0)
				if bee.target_cell.is_closed:
					return "taking the wax cap off a cell (%d%%)" % capped
			return "capping a cell with wax (%d%%)" % capped
		State.TO_WASTE_EXIT:
			if bee.carrying_corpse:
				return "carrying a dead %s out of the hive" % ("bee" if bee.corpse_is_bee else "larva")
			return "carrying %s out of the hive to dump it" % bee.current_load_type
		State.DUMPING_WASTE:
			if bee.carrying_corpse:
				return "disposing of a dead %s" % ("bee" if bee.corpse_is_bee else "larva")
			return "throwing out unwanted stores"
		State.SEEK_POLLEN:
			if not bee.hive.has_room_for_egg():
				return "waiting -- no free cell to lay in"
			return "looking for pollen to eat"
		State.TO_POLLEN_CELL:
			return "walking to a pollen cell"
		State.EATING:
			return "feeding on pollen (%d of %d for an egg)" % [int(bee.pollen_eaten), int(GameConfig.egg_pollen_cost)]
		State.TO_CELL_TO_LAY:
			return "carrying an egg to a free cell"
		State.LAYING:
			return "laying an egg into a cell"
		State.TIPSY_WANDER:
			return BeeStatus.tipsy_wander_text(bee)
	return "idle"  # gdlint: ignore=max-returns

## Only ever reached from task_description() while sitting in an idle
## state, which means _idle_dispatch already tried the secondary role
## this frame too and it also came up empty.
static func _idle_backup_note(bee: Node2D) -> String:
	# role_restricted_to is exactly the signal that a Challenge is limiting
	# which roles this bee may hold, so a backup role has not been
	# introduced yet and naming one would teach it out of order.
	if not bee.role_restricted_to.is_empty():
		return ""
	if not bee.is_queen and bee.work_priorities_owned():
		# Only a job actually tried can be said to have nothing; skipped
		# ones (not unlocked, or her own role) are not mentioned.
		return " (its backup jobs also have nothing right now)" if bee._backup_jobs_tried > 0 else ""
	if bee.secondary_role != -1 and bee.secondary_role != bee.role:
		return " (backup role %s also has nothing right now)" % Roles.label_for(bee.secondary_role)
	return ""

static func role_name_text(bee: Node2D) -> String:
	var base: String = Roles.label_for(bee.role)
	match bee.role:
		Role.NURSERY:
			base += " (%s)" % Roles.mode_label(Roles.NURSE, bee.nurse_mode).to_lower()
		Role.BUILDER:
			base += " (%s)" % architect_mode_name(bee)
		Role.MINER:
			if bee.automine:
				base += " (digging on its own)"
		Role.HONEY_MAKER:
			if bee.fermenting:
				base += " (%s)" % Roles.mode_label(Roles.HONEY, "ferment").to_lower()
		Role.FORAGER:
			base += " (%s)" % bee.resource_type
			if bee.is_scouting:
				base += " -- scouting (%d/3)" % (bee.scout_bout + 1)
			elif bee.preferred_species != "":
				base += " -- %s only" % bee.preferred_species
			if bee.state == State.AT_ENTRANCE_SEEKING:
				base += " -- waiting to be told a better patch"
			elif bee.state == State.AT_ENTRANCE_MENTORING:
				base += " -- waiting to recruit a struggling forager"
			elif bee.state == State.DANCING:
				base += " -- dancing to recruit a struggling forager" if bee.dance_role == "mentor" else " -- being danced at"
	# COL-10: a queen who took over from a dead one has not mated.
	# COL-11: and says whether she is laying drones or flying to mate.
	if bee.is_queen and not bee.is_mated:
		if bee.nuptial_phase != bee.NUPTIAL_NONE:
			base += " -- Unmated: on a nuptial flight"
		elif bee.nuptial_flights:
			base += " -- Unmated: flies out each day to mate"
		else:
			base += " -- Unmated: lays drones"
	if bee.secondary_role != -1 and bee.secondary_role != bee.role:
		base += " -- when idle: %s" % Roles.label_for(bee.secondary_role)
	return base

static func architect_mode_name(bee: Node2D) -> String:
	var mode_text: String = Roles.mode_label(Roles.COMB_WORKER, bee.architect_mode).to_lower()
	if bee.architect_mode == "restock":
		mode_text += " %s" % (bee.restock_resource if bee.restock_resource != "" else "-- nothing set")
	return mode_text

static func carrying_text(bee: Node2D) -> String:
	if bee.carrying_corpse:
		return "Carrying: a dead %s, for disposal outside" % ("bee" if bee.corpse_is_bee else "larva")
	if bee.role == Role.MINER:
		return "Carrying: %d dirt (of %d)" % [int(bee.dirt_load), int(GameConfig.miner_dirt_capacity)]
	if bee.bee_bread_load > 0.0:
		return "Carrying: %d bee bread" % int(ceil(bee.bee_bread_load))
	if bee.honey_load > 0.0:
		return "Carrying: %d units of honey mix" % int(ceil(bee.honey_load))
	if bee.nurse_pollen > 0.0 or bee.nurse_carb > 0.0 or bee.nurse_jelly > 0.0 or bee.nurse_bee_bread > 0.0:
		var carb_name: String = bee.nurse_carb_type if bee.nurse_carb_type != "" else "nectar"
		var protein: String = "%d pollen" % int(bee.nurse_pollen)
		if bee.nurse_bee_bread > 0.0:
			protein = "%d bee bread, %s" % [int(ceil(bee.nurse_bee_bread)), protein]
		var carried := "Carrying: %s and %d %s for the brood (%d feeds)" % [
			protein, int(bee.nurse_carb), carb_name, int(BeeNursery.feeds_carried(bee)),
		]
		if bee.nurse_jelly > 0.0:
			carried += ", plus %d royal jelly" % int(bee.nurse_jelly)
		return carried
	if bee.current_load <= 0.0 or bee.current_load_type == "":
		return "Carrying: nothing"
	return "Carrying: %d %s (of %d)" % [int(bee.current_load), bee.current_load_type, int(BeeForaging.max_capacity(bee))]

