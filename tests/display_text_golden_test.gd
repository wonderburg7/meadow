extends SceneTree
## CQ-R0: display-text golden harness.
##
## Boots level 3 and collects every player-facing string a bee, a cell and the
## hud build from game state: bee.gd's `task_description` / `_task_line` (every
## State, under several roles), `idle_reason`, `role_name_text`, `carrying_text`;
## the hud's selection and cell-popup labels and its corner signal rows; and a
## cell's `info_label` for each content type, overlay and colour-blind setting.
## Everything is written to one JSON file with sorted keys.
##
## Nothing is created only to make a string appear: bees and cells are driven
## through their existing fields and setters, and every call is read-only.
## All of it happens in one frame so no simulation tick can move a value.
##
## Run by tests/test_display_text_golden.py:
##   godot --headless --path <repo> --script res://tests/display_text_golden_test.gd -- --golden-out=<file>
## Prints "CQ-R0 PASS" after writing the file, or each "CQ-R0 FAIL" line.

const LEVEL := 3
const BOOT_FRAMES := 10

var _main: Node = null
var _frame := 0
var _phase := "boot"
var _failures: PackedStringArray = PackedStringArray()
var _session: Node = null
var _out_path := ""
var _out: Dictionary = {}
var BeeEnums: GDScript = null


func _process(_delta: float) -> bool:
	_frame += 1
	if _phase == "boot":
		_boot()
	elif _phase == "settle" and _frame >= BOOT_FRAMES:
		_collect()
		_phase = "done"
	if _phase == "done":
		_report()
		return true
	return false


# Autoloads are reached through the tree: a --script run compiles this file
# before they exist.
func _boot() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--golden-out="):
			_out_path = arg.trim_prefix("--golden-out=")
	if _out_path == "":
		_fail("no --golden-out=<file> given")
		_phase = "done"
		return
	if not root.has_node("Session"):
		_fail("Session autoload is not loaded")
		_phase = "done"
		return
	_session = root.get_node("Session")
	_session.starting_level = LEVEL
	_session.menu_pending = false
	BeeEnums = load("res://scripts/bee_enums.gd")
	var scene: PackedScene = load("res://scenes/Main.tscn")
	_main = scene.instantiate()
	root.add_child(_main)
	current_scene = _main
	_phase = "settle"


func _collect() -> void:
	for bee: Node in _main.get_tree().get_nodes_in_group("bees"):
		bee.process_mode = Node.PROCESS_MODE_DISABLED
	_bee_task_and_idle()
	_bee_role_and_carrying()
	_hud_selection()
	_cells()
	_corner_signals()
	var file := FileAccess.open(_out_path, FileAccess.WRITE)
	if file == null:
		_fail("cannot write %s" % _out_path)
		return
	file.store_string(JSON.stringify(_out, "\t", true) + "\n")
	file.close()


# --- bees ------------------------------------------------------------------

func _new_bee(role_name: String, props: Dictionary) -> Node2D:
	var role_id: int = BeeEnums.Role[role_name]
	var bee: Node2D = _main.world_building._spawn_indoor_bee(role_id)
	bee.process_mode = Node.PROCESS_MODE_DISABLED
	# Rolled per bee at birth; fixed so the capacity a label prints is not.
	bee.nectar_stomach_capacity = 50.0
	bee.pollen_stomach_capacity = 20.0
	bee.energy = _main.get_node("/root/GameConfig").energy_capacity
	for key: String in props:
		bee.set(key, props[key])
	return bee


func _drop(bee: Node2D) -> void:
	bee.get_parent().remove_child(bee)
	bee.free()


func _task_configs() -> Array:
	var role: Dictionary = BeeEnums.Role
	return [
		{"name": "forager_nectar", "role": "FORAGER", "props": {"resource_type": "nectar", "current_load": 6.0, "current_load_type": "nectar", "energy": 40.0}},
		{"name": "forager_pollen_scout", "role": "FORAGER", "props": {"resource_type": "pollen", "current_load": 2.0, "current_load_type": "pollen", "is_scouting": true, "scout_bout": 1, "dance_role": "mentor", "timer": 12.0}},
		{"name": "forager_dancer_follower", "role": "FORAGER", "props": {"resource_type": "nectar", "dance_role": "follower", "timer": 7.0, "preferred_species": "clover"}},
		{"name": "forager_tipsy", "role": "FORAGER", "props": {"resource_type": "nectar", "tipsy_time_left": 20.0}},
		{"name": "nurse_feed", "role": "NURSERY", "props": {"nurse_mode": "feed", "nurse_fetching": "honey_mix", "secondary_role": role.FORAGER}},
		{"name": "nurse_jelly", "role": "NURSERY", "props": {"nurse_mode": "jelly", "timer": 9.0}},
		{"name": "builder_both", "role": "BUILDER", "props": {"architect_mode": "both", "restock_resource": "honey"}},
		{"name": "builder_restock", "role": "BUILDER", "props": {"architect_mode": "restock", "restock_resource": "pollen", "current_load_type": "pollen"}},
		{"name": "builder_maintain_corpse", "role": "BUILDER", "props": {"architect_mode": "maintain", "carrying_corpse": true, "corpse_is_bee": true}},
		{"name": "egg_layer", "role": "EGG_LAYER", "props": {"pollen_eaten": 3.0}},
		{"name": "miner_manual", "role": "MINER", "props": {"automine": false, "dirt_load": 2.0}},
		{"name": "miner_automine", "role": "MINER", "props": {"automine": true, "dirt_load": 5.0}},
		{"name": "honey_maker", "role": "HONEY_MAKER", "props": {"fermenting": false, "timer": 30.0}},
		{"name": "honey_maker_fermenting", "role": "HONEY_MAKER", "props": {"fermenting": true}},
		{"name": "idle", "role": "IDLE", "props": {}},
	]


## Every State, under each role setup: the task line and the idle reason.
func _bee_task_and_idle() -> void:
	var state_names: Array = BeeEnums.State.keys()
	for config: Dictionary in _task_configs():
		var bee: Node2D = _new_bee(config.role, config.props)
		for state_name: String in state_names:
			bee.state = BeeEnums.State[state_name]
			var prefix := "bee.%s.%s" % [config.name, state_name]
			_out[prefix + ".task_description"] = bee.task_description()
			_out[prefix + ".task_line"] = bee._task_line()
			_out[prefix + ".idle_reason"] = bee.idle_reason()
		_drop(bee)


func _role_configs() -> Array:
	var role: Dictionary = BeeEnums.Role
	var configs: Array = []
	for role_name: String in BeeEnums.Role.keys():
		configs.append({"name": role_name.to_lower(), "role": role_name, "props": {}})
	configs.append_array([
		{"name": "nurse_jelly", "role": "NURSERY", "props": {"nurse_mode": "jelly"}},
		{"name": "nurse_both", "role": "NURSERY", "props": {"nurse_mode": "both"}},
		{"name": "builder_build", "role": "BUILDER", "props": {"architect_mode": "build"}},
		{"name": "builder_maintain", "role": "BUILDER", "props": {"architect_mode": "maintain"}},
		{"name": "builder_restock_pollen", "role": "BUILDER", "props": {"architect_mode": "restock", "restock_resource": "pollen"}},
		{"name": "builder_restock_none", "role": "BUILDER", "props": {"architect_mode": "restock", "restock_resource": ""}},
		{"name": "miner_automine", "role": "MINER", "props": {"automine": true}},
		{"name": "honey_fermenting", "role": "HONEY_MAKER", "props": {"fermenting": true}},
		{"name": "forager_pollen", "role": "FORAGER", "props": {"resource_type": "pollen"}},
		{"name": "forager_scout", "role": "FORAGER", "props": {"is_scouting": true, "scout_bout": 2}},
		{"name": "forager_species", "role": "FORAGER", "props": {"preferred_species": "clover"}},
		{"name": "forager_seeking", "role": "FORAGER", "props": {"state": BeeEnums.State.AT_ENTRANCE_SEEKING}},
		{"name": "forager_mentoring", "role": "FORAGER", "props": {"state": BeeEnums.State.AT_ENTRANCE_MENTORING}},
		{"name": "forager_dancing_mentor", "role": "FORAGER", "props": {"state": BeeEnums.State.DANCING, "dance_role": "mentor"}},
		{"name": "forager_dancing_follower", "role": "FORAGER", "props": {"state": BeeEnums.State.DANCING, "dance_role": "follower"}},
		{"name": "nurse_backup_forager", "role": "NURSERY", "props": {"secondary_role": role.FORAGER}},
		{"name": "queen_mated", "role": "EGG_LAYER", "props": {"is_queen": true, "is_mated": true}},
		{"name": "queen_unmated_drones", "role": "EGG_LAYER", "props": {"is_queen": true, "is_mated": false, "nuptial_flights": false}},
		{"name": "queen_unmated_flies", "role": "EGG_LAYER", "props": {"is_queen": true, "is_mated": false, "nuptial_flights": true}},
		{"name": "queen_unmated_on_flight", "role": "EGG_LAYER", "props": {"is_queen": true, "is_mated": false, "nuptial_phase": 1}},
	])
	return configs


func _carrying_configs() -> Array:
	return [
		{"name": "nothing", "props": {}},
		{"name": "nectar", "props": {"current_load": 4.0, "current_load_type": "nectar"}},
		{"name": "pollen_unknown_type", "props": {"current_load": 4.0, "current_load_type": ""}},
		{"name": "corpse_bee", "props": {"carrying_corpse": true, "corpse_is_bee": true}},
		{"name": "corpse_larva", "props": {"carrying_corpse": true, "corpse_is_bee": false}},
		{"name": "dirt", "props": {"dirt_load": 3.0}},
		{"name": "bee_bread", "props": {"bee_bread_load": 1.5}},
		{"name": "honey_mix", "props": {"honey_load": 2.2}},
		{"name": "nurse_default", "props": {"nurse_pollen": 2.0, "nurse_carb": 3.0}},
		{"name": "nurse_honey_jelly", "props": {"nurse_pollen": 2.0, "nurse_carb": 3.0, "nurse_carb_type": "honey", "nurse_jelly": 1.0}},
		{"name": "nurse_bee_bread", "props": {"nurse_pollen": 1.0, "nurse_bee_bread": 2.5, "nurse_carb": 1.0}},
	]


func _bee_role_and_carrying() -> void:
	for config: Dictionary in _role_configs():
		var bee: Node2D = _new_bee(config.role, config.props)
		_out["bee.role_name.%s" % config.name] = bee.role_name_text()
		_drop(bee)
	for role_name: String in ["FORAGER", "NURSERY", "MINER"]:
		for config: Dictionary in _carrying_configs():
			var bee: Node2D = _new_bee(role_name, config.props)
			_out["bee.carrying.%s.%s" % [role_name.to_lower(), config.name]] = bee.carrying_text()
			_drop(bee)


# --- hud -------------------------------------------------------------------

## The selection panel's activity and energy labels for single bees, and the
## count line for a multiple selection. Identity, age and trait lines hold a
## bee id, a name, an age and a roll, so they are left out.
func _hud_selection() -> void:
	var hud: Node = _main.hud
	var configs: Array = [
		{"name": "forager", "role": "FORAGER", "props": {"resource_type": "nectar", "current_load": 3.0, "current_load_type": "nectar", "state": BeeEnums.State.COLLECTING}},
		{"name": "nurse_idle", "role": "NURSERY", "props": {"state": BeeEnums.State.NURSE_IDLE}},
		{"name": "builder_idle", "role": "BUILDER", "props": {"state": BeeEnums.State.BUILD_IDLE}},
		{"name": "miner_idle", "role": "MINER", "props": {"state": BeeEnums.State.MINE_IDLE}},
		{"name": "queen", "role": "EGG_LAYER", "props": {"is_queen": true, "state": BeeEnums.State.SEEK_POLLEN, "pollen_eaten": 2.0}},
	]
	var bees: Array = []
	for config: Dictionary in configs:
		var bee: Node2D = _new_bee(config.role, config.props)
		bees.append(bee)
		hud.update_selection([bee])
		_out["hud.selection.%s.activity" % config.name] = hud.activity_label.text
		_out["hud.selection.%s.energy" % config.name] = hud.energy_label.text
	hud.update_selection(bees.slice(0, 2))
	_out["hud.selection.multiple.identity"] = hud.identity_label.text
	hud.update_selection([])
	for bee: Node2D in bees:
		_drop(bee)


# --- cells -----------------------------------------------------------------

func _built_cells() -> Array:
	var built: Array = _main.hive.cells.filter(func(c: Variant) -> bool: return is_instance_valid(c) and c.is_built and not c.is_closed)
	built.sort_custom(func(a: Variant, b: Variant) -> bool:
		if a.axial.x != b.axial.x:
			return a.axial.x < b.axial.x
		return a.axial.y < b.axial.y
	)
	return built


func _hour() -> float:
	return maxf(0.001, _main.get_node("/root/GameConfig").seconds_per_day / 24.0)


## Each case fills one cell through its own setters and names what the cell
## then shows. `setup` takes the cell; `amount` is a share of its capacity.
func _cell_cases() -> Array:
	var config: Node = _main.get_node("/root/GameConfig")
	var now: float = _session.sim_time
	var hour: float = _hour()
	return [
		{"name": "empty", "fn": func(_c: Variant) -> void: pass},
		{"name": "empty_keep", "fn": func(c: Variant) -> void: c.keep_empty = true},
		{"name": "empty_reserved_pollen", "fn": func(c: Variant) -> void: c.designated_type = "pollen"},
		{"name": "empty_reserved_brood", "fn": func(c: Variant) -> void: c.designated_type = "brood"},
		{"name": "nectar", "fn": func(c: Variant) -> void: c.add_resource("nectar", 3.0)},
		{"name": "nectar_fermented", "fn": func(c: Variant) -> void:
			c.add_resource("nectar", 3.0)
			c.nectar_since = now - (config.nectar_ferment_hours + 1.0) * hour},
		{"name": "pollen", "fn": func(c: Variant) -> void: c.add_resource("pollen", 4.0)},
		{"name": "jelly", "fn": func(c: Variant) -> void: c.add_resource("jelly", 1.0)},
		{"name": "bee_bread_filling", "fn": func(c: Variant) -> void: c.add_resource("bee_bread", 1.0)},
		{"name": "bee_bread_sealed", "fn": func(c: Variant) -> void:
			c.add_resource("bee_bread", 1000.0)
			c.bee_bread_sealed_at = now - config.bee_bread_ripen_hours * hour * 0.55},
		{"name": "bee_bread_ripe", "fn": func(c: Variant) -> void:
			c.add_resource("bee_bread", 1000.0)
			c.bee_bread_sealed_at = now - config.bee_bread_ripen_hours * hour - 1.0},
		{"name": "honey_wet", "fn": func(c: Variant) -> void:
			c.add_resource("honey", 3.0)
			c.ripen_progress = config.honey_ripen_time * 0.4},
		{"name": "honey_ripe", "fn": func(c: Variant) -> void:
			c.add_resource("honey", 3.0)
			c.ripen_progress = config.honey_ripen_time},
		{"name": "brood_fed", "fn": func(c: Variant) -> void:
			c.start_brood()
			c.brood_progress = c.develop_time() * 0.3
			c.brood_fed_seconds = 20.0},
		{"name": "brood_hungry", "fn": func(c: Variant) -> void:
			c.start_brood()
			c.brood_progress = c.develop_time() * 0.3
			c.brood_fed_seconds = 0.0
			c.unfed_seconds = config.larva_death_seconds * 0.5},
		{"name": "brood_gyne_fed_on_honey", "fn": func(c: Variant) -> void:
			c.start_brood(true)
			c.brood_progress = c.develop_time() * 0.6
			c.brood_fed_seconds = 15.0
			c.fed_on_honey = true},
		{"name": "brood_drone", "fn": func(c: Variant) -> void:
			c.start_brood(false, true)
			c.brood_progress = c.develop_time() * 0.1
			c.brood_fed_seconds = 15.0},
		{"name": "corpse", "fn": func(c: Variant) -> void:
			c.content_type = "corpse"
			c.clean_progress = config.cell_clean_time * 0.4},
		{"name": "sealed_honey", "fn": func(c: Variant) -> void:
			c.add_resource("honey", 1000.0)
			c.ripen_progress = config.honey_ripen_time
			c.set_closed(true)},
		{"name": "fill_then_close", "fn": func(c: Variant) -> void:
			c.add_resource("pollen", 2.0)
			c.set_fill_then_close(true)},
		{"name": "evict_priority", "fn": func(c: Variant) -> void:
			c.add_resource("pollen", 2.0)
			c.evict_requested = true
			c.priority_cell = true
			c.nursery_priority = 2},
	]


func _record_cell(cell: Variant, key: String) -> void:
	cell._refresh()
	_out["cell.info_label.%s" % key] = cell.info_label.text


func _cells() -> void:
	var built: Array = _built_cells()
	if built.is_empty():
		_fail("level %d has no built cells" % LEVEL)
		return
	var cell: Variant = built[0]
	var hud: Node = _main.hud
	var overlays: Array = ["", "contents", "fill", "role", "reserved"]
	var colour_blind_before: bool = _session.colour_blind_mode
	for entry: Dictionary in _cell_cases():
		cell.clear_cell()
		cell.keep_empty = false
		cell.designated_type = ""
		cell.is_closed = false
		cell.fill_then_close = false
		cell.evict_requested = false
		cell.priority_cell = false
		cell.hatch_gyne = false
		cell.fed_on_honey = false
		cell.nectar_since = -1.0
		entry.fn.call(cell)
		for overlay: String in overlays:
			cell.set_overlay(overlay)
			for colour_blind: bool in [false, true]:
				_session.colour_blind_mode = colour_blind
				_record_cell(cell, "%s.overlay_%s.colour_blind_%s" % [entry.name, overlay if overlay != "" else "none", str(colour_blind)])
		cell.set_overlay("")
		_session.colour_blind_mode = false
		cell._refresh()
		hud.show_cell_popup(cell, 1)
		var popup_key := "hud.cell_popup.%s" % entry.name
		_out[popup_key + ".identity"] = hud.identity_label.text
		_out[popup_key + ".contents"] = hud.energy_label.text
		_out[popup_key + ".state"] = hud.activity_label.text
		_out[popup_key + ".raises"] = hud.trait_label.text
	hud.show_cell_popup(cell, 3)
	_out["hud.cell_popup.bulk.identity"] = hud.identity_label.text
	_out["hud.cell_popup.bulk.contents"] = hud.energy_label.text
	# An unfinished cell: the build site shows its progress as a percentage.
	var site: Variant = null
	for candidate: Variant in _main.hive.cells:
		if is_instance_valid(candidate) and not candidate.is_built:
			site = candidate
			break
	if site == null:
		site = _main.hive.create_next_cell_site(Vector2i.ZERO)
	if site != null:
		site.build_progress = site.effective_build_time() * 0.5
		_record_cell(site, "unfinished")
		hud.show_cell_popup(site, 1)
		_out["hud.cell_popup.unfinished.contents"] = hud.energy_label.text
	else:
		_fail("no unfinished cell to read")
	_session.colour_blind_mode = colour_blind_before
	hud.update_selection([])
	cell.clear_cell()


# --- corner signal rows ----------------------------------------------------

func _corner_signals() -> void:
	var hud: Node = _main.hud
	var starred_before: Array = _session.pinned_stats.duplicate()
	var lines: Array = []
	for index in range(7):
		lines.append(["Signal line %d" % index, 2 if index % 2 == 0 else 1, "act%d" % index, "", "sig%d" % index])
	lines.append(["A quiet line", 0, "", "", "quiet"])
	# Starred, then unstarred: the red-only filtering differs.
	for starred: bool in [true, false]:
		_session.pinned_stats = ["signals"] if starred else []
		hud.removed_signal_ids = []
		hud.corner_signature = ""
		hud.update_signals([])
		hud.corner_signature = ""
		hud.update_signals(lines)
		var texts: Array = []
		for child: Node in hud.corner_column.get_children():
			if child.is_queued_for_deletion():
				continue
			if child is Label:
				texts.append("label: %s" % child.text)
			elif child is HBoxContainer:
				for part: Node in child.get_children():
					if part is Button:
						texts.append("button: %s" % part.text)
		_out["hud.corner.signals_starred_%s" % str(starred)] = "\n".join(texts)
		_out["hud.corner.signals_text_starred_%s" % str(starred)] = str(hud.corner_texts.get("signals", ""))
	_session.pinned_stats = starred_before
	hud.update_signals([])


func _fail(message: String) -> void:
	_failures.append("CQ-R0 FAIL: %s" % message)


func _report() -> void:
	if _failures.is_empty():
		print("CQ-R0 PASS (%d strings)" % _out.size())
		quit(0)
		return
	for line in _failures:
		print(line)
	quit(1)
