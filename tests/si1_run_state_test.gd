extends SceneTree
## SI-1: disease, the crab-spider choice and the rival colony survive a load.

const SAVE_PATH := "user://si1_test_save.json"
const BOOT_FRAMES := 10

var _main: Node
var _phase := "boot"
var _frame := 0
var _old_rival_setting := false
var _failures: PackedStringArray = PackedStringArray()

func _process(_delta: float) -> bool:
	_frame += 1
	match _phase:
		"boot":
			_old_rival_setting = root.get_node("GameConfig").rival_hive_on
			root.get_node("GameConfig").rival_hive_on = true
			var session: Node = root.get_node("Session")
			session.starting_level = 3
			session.menu_pending = false
			_create_world()
			_phase = "active"
		"active":
			if _frame >= BOOT_FRAMES:
				_test_active_and_legacy_defaults()
				_queue_reload("loaded")
		"reload":
			_create_world()
			_phase = _next_phase
		"loaded":
			if _frame >= BOOT_FRAMES:
				_test_loaded()
				_queue_reload("collapsed")
		"collapsed":
			if _frame >= BOOT_FRAMES:
				_test_collapsed()
				_queue_reload("legacy")
		"legacy":
			if _frame >= BOOT_FRAMES:
				_test_legacy()
				_cleanup()
				_report()
				return true
	return false

var _next_phase := ""

func _create_world() -> void:
	_main = load("res://scenes/Main.tscn").instantiate()
	root.add_child(_main)
	current_scene = _main
	paused = true
	_frame = 0

func _queue_reload(next_phase: String) -> void:
	var session: Node = root.get_node("Session")
	session.load_pending = true
	session.load_path = SAVE_PATH
	_main.queue_free()
	current_scene = null
	_next_phase = next_phase
	_phase = "reload"

func _test_active_and_legacy_defaults() -> void:
	var session: Node = root.get_node("Session")
	var save_game: GDScript = _main.SaveGame
	_check(_main.rival != null, "level 3 did not build the rival")
	if _main.rival == null:
		return
	var defaults: Dictionary = _main.rival.save_data()
	_check(save_game.save(_main, SAVE_PATH), "initial save failed")
	var old_data: Dictionary = save_game.read(SAVE_PATH)
	old_data["session"].erase("disease")
	old_data["session"].erase("crab_spider_species")
	old_data.erase("rival")
	_main.season.disease = 0.4
	session.crab_spider_preferred_species = "dandelion"
	_main.saving._restore(old_data)
	_check(is_zero_approx(_main.season.disease), "old save did not default disease to zero")
	_check(session.crab_spider_preferred_species == "", "old save did not clear the spider species")
	_check(_main.rival.save_data() == defaults, "old save changed the fresh rival")

	_main.season.disease = 0.4
	session.crab_spider_preferred_species = "dandelion"
	_main.rival.population = 7.0
	_main.rival.nectar = 33.0
	_main.rival.pollen = 17.0
	_main.rival.brood = 2.0
	_main.rival.forager_share = 0.3
	_check(save_game.save(_main, SAVE_PATH), "active save failed")
	var data: Dictionary = save_game.read(SAVE_PATH)
	_check(data.has("rival"), "active save omitted the rival")
	_check(data.get("session", {}).has("disease"), "active save omitted disease")
	_check(data.get("session", {}).has("crab_spider_species"), "active save omitted spider species")
	_main.season.disease = 0.0
	session.crab_spider_preferred_species = ""
	_main.rival.population = 19.0
	_main.rival.nectar = 80.0
	_main.rival.pollen = 80.0
	_main.rival.brood = 0.0
	_main.rival.forager_share = 0.7
	_main.saving._restore(data)
	_check_saved_active_state("in-place restore")
	session.control_groups[1] = [1]

func _test_loaded() -> void:
	_check_saved_active_state("fresh load")
	_check(root.get_node("Session").control_groups.is_empty(), "fresh load retained old bee control groups")
	_main.rival._collapse()
	_check(_main.SaveGame.save(_main, SAVE_PATH), "collapsed save failed")

func _test_collapsed() -> void:
	_check(not _main.rival.alive, "collapsed rival came back alive")
	_check(is_zero_approx(_main.rival.population), "collapsed rival regained population")
	_check(_main.rival.foragers.is_empty(), "collapsed rival kept visible foragers")
	var old_data: Dictionary = _main.SaveGame.read(SAVE_PATH)
	_main.rival.restore({
		"population": 7.0, "nectar": 33.0, "pollen": 17.0,
		"brood": 2.0, "forager_share": 0.3, "alive": true,
	})
	_check(_main.rival.alive and not _main.rival.foragers.is_empty(),
		"in-place restore did not revive a rival after collapse")
	old_data["session"].erase("disease")
	old_data["session"].erase("crab_spider_species")
	old_data.erase("rival")
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	_check(file != null, "could not write old-format fixture")
	if file != null:
		file.store_string(JSON.stringify(old_data))
		file.close()

func _test_legacy() -> void:
	_check(is_zero_approx(_main.season.disease), "legacy load retained disease")
	_check(root.get_node("Session").crab_spider_preferred_species == "", "legacy load retained spider species")
	_check(_main.rival.alive, "legacy load collapsed a fresh rival")
	_check(is_equal_approx(_main.rival.population, max(4.0, root.get_node("GameConfig").rival_starting_bees)), "legacy load changed starting rival population")
	_check(is_equal_approx(_main.rival.nectar, 120.0), "legacy load changed starting rival nectar")

func _check_saved_active_state(where: String) -> void:
	var session: Node = root.get_node("Session")
	var rival: Node = _main.rival
	_check(is_equal_approx(_main.season.disease, 0.4), where + " lost disease")
	_check(session.crab_spider_preferred_species == "dandelion", where + " lost spider species")
	_check(rival.alive, where + " collapsed the rival")
	_check(is_equal_approx(rival.population, 7.0), where + " lost rival population")
	_check(is_equal_approx(rival.nectar, 33.0), where + " lost rival nectar")
	_check(is_equal_approx(rival.pollen, 17.0), where + " lost rival pollen")
	_check(is_equal_approx(rival.brood, 2.0), where + " lost rival brood")
	_check(is_equal_approx(rival.forager_share, 0.3), where + " lost rival forager share")

func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)

func _cleanup() -> void:
	root.get_node("GameConfig").rival_hive_on = _old_rival_setting
	paused = false
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))

func _report() -> void:
	if _failures.is_empty():
		print("SI1 PASS")
		quit(0)
	else:
		for failure in _failures:
			print("SI1 FAIL: " + failure)
		quit(1)
