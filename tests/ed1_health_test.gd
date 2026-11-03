extends SceneTree
## ED-1 test: every bee has health (plans/now/difficulty.md, ED-1).
##
## Boots the real Main.tscn and watches bees in a live run. One mode a run:
##   starve  -- Scenario 1 (the queen alone, no comb, no stores). Her energy
##              is set to zero: she must not die on the spot, must lose
##              health, and must die of starvation about half a game-day
##              later, since there is nothing to eat.
##   recover -- level 3 (comb and foragers). A forager is put out in the
##              meadow with no energy and little health. She must give up
##              her errand and crawl home at GameConfig.spent_speed_factor
##              of her speed, eat, rest inside while health or energy is
##              under the rest thresholds, and leave only once both clear.
##   ambush  -- level 3. A crab-spider ambush on a bee at full health
##              still kills her outright, cause "crab spider ambush".
##
## Run by tests/test_ed1_health.py:
##   godot --headless --fixed-fps 60 --path <repo> --script res://tests/ed1_health_test.gd -- <mode>
## Prints "ED1 PASS" and exits 0, or prints each failure and exits 1.

# Loaded in _boot, not preloaded: they name the autoloads, which a --script
# run compiles this file before.
var BeeSurvival: GDScript = null
var CrabSpider: GDScript = null
const BeeEnums = preload("res://scripts/bee_enums.gd")

const SCENARIO_ONE_LEVEL := 7   # main_menu.gd: "Scenario 1 Queen alone"
const COMB_LEVEL := 3           # a Scenario level with comb and foragers
const BOOT_FRAMES := 10         # let Main._ready build the world first
const SPEED := 8.0              # the game's own fastest speed
const STARVE_FRAME_LIMIT := 3000
const RECOVER_FRAME_LIMIT := 6000
const MEADOW_OFFSET := Vector2(220.0, 0.0)   # where the spent forager starts, from the hive marker
const STARTING_HEALTH_SHARE := 0.6           # her health when put out: enough to cross the hive to food at a crawl

var _main: Node = null
var _session: Node = null
var _config: Node = null
var _bee: Node2D = null
var _mode := "starve"
var _frame := 0
var _phase := "boot"
var _phase_frame := 0
var _start_time := 0.0
var _last_pos := Vector2.ZERO
var _last_time := 0.0
var _crawl_distance := 0.0
var _crawl_seconds := 0.0
var _went_home := false
var _ate := false
var _rested := false
var _lowest_health := INF
var _health_before_home := INF
var _death_cause := ""
var _trace := ""
var _last_state := -1
var _failures: PackedStringArray = PackedStringArray()
var _log: PackedStringArray = PackedStringArray()


func _process(_delta: float) -> bool:
	_frame += 1
	match _phase:
		"boot":
			_boot()
		"settle":
			if _frame >= BOOT_FRAMES:
				match _mode:
					"starve":
						_start_starve()
					"recover":
						_start_recover()
					"ambush":
						_run_ambush()
					_:
						_fail("unknown mode %s" % _mode)
		"starving":
			_watch_starve()
		"crawling", "inside":
			_watch_recover()
	if _phase == "done":
		_report()
		return true
	return false


# Autoloads are reached through the tree: a --script run compiles this file
# before they exist.
func _boot() -> void:
	if not root.has_node("Session") or not root.has_node("GameConfig"):
		_fail("the Session or GameConfig autoload is not loaded")
		return
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		_mode = args[0]
	_session = root.get_node("Session")
	BeeSurvival = load("res://scripts/bee_survival.gd")
	CrabSpider = load("res://scripts/crab_spider.gd")
	_config = root.get_node("GameConfig")
	_session.starting_level = SCENARIO_ONE_LEVEL if _mode == "starve" else COMB_LEVEL
	_session.menu_pending = false
	var scene: PackedScene = load("res://scenes/Main.tscn")
	_main = scene.instantiate()
	root.add_child(_main)
	current_scene = _main
	_phase = "settle"


# --- starve ---------------------------------------------------------------

func _start_starve() -> void:
	_bee = _main.get("queen")
	if _bee == null or not is_instance_valid(_bee):
		_fail("Scenario 1 has no queen after boot")
		return
	if bool(_bee.energy_immune):
		_fail("the Scenario 1 queen is energy-immune, so she cannot starve")
		return
	if not is_equal_approx(float(_bee.health), float(_config.health_capacity)):
		_fail("the queen was not born at full health (%.2f)" % float(_bee.health))
		return
	_bee.energy = 0.0
	# Her node is freed at the end of the frame she dies in, so the cause is
	# taken from main.gd's bee_died signal rather than read off her later.
	_main.bee_died.connect(_on_bee_died)
	_start_time = float(_session.sim_time)
	Engine.time_scale = SPEED
	_phase = "starving"
	_phase_frame = _frame


func _watch_starve() -> void:
	var elapsed: float = float(_session.sim_time) - _start_time
	if not is_instance_valid(_bee) or bool(_bee.is_dying):
		var cause: String = str(_bee.death_cause) if is_instance_valid(_bee) else _death_cause
		var day: float = float(_config.seconds_per_day)
		_log.append("queen lasted %.1f s at zero energy (%.2f of a day), cause %s" % [elapsed, elapsed / day, cause])
		_check(cause == "starvation", "the exhausted queen died of %s, not starvation" % cause)
		_check(elapsed >= 0.4 * day and elapsed <= 0.6 * day,
			"the exhausted queen lasted %.1f s, not about half a day (%.0f s)" % [elapsed, 0.5 * day])
		_finish()
		return
	if _frame - _phase_frame == 30:
		_check(float(_bee.health) < float(_config.health_capacity),
			"an out-of-energy queen has lost no health (%.2f)" % float(_bee.health))
	if _frame - _phase_frame > STARVE_FRAME_LIMIT:
		_fail("the queen did not die within %d frames (health %.2f, energy %.2f)" % [
			STARVE_FRAME_LIMIT, float(_bee.health), float(_bee.energy)])


func _on_bee_died(bee: Node) -> void:
	if bee == _bee:
		_death_cause = str(bee.death_cause)


# --- recover --------------------------------------------------------------

func _start_recover() -> void:
	for bee in _main.get_tree().get_nodes_in_group("bees"):
		if not bee.is_queen and bee.role == BeeEnums.Role.FORAGER and not bool(bee.is_dying):
			_bee = bee
			break
	if _bee == null:
		_fail("level %d has no forager" % COMB_LEVEL)
		return
	if not _stock_food():
		return
	if _bee._is_inside_hive():
		_main.move_bee_out_of_hive(_bee)
	_bee.position = _main.hive.position + MEADOW_OFFSET
	_bee.current_load = 0.0
	_bee.current_load_type = ""
	_bee.tipsy_time_left = 0.0
	_bee.state = BeeEnums.State.SEEK_FLOWER
	_bee.energy = 0.0
	_bee.health = float(_config.health_capacity) * STARTING_HEALTH_SHARE
	_health_before_home = float(_bee.health)
	_main.bee_died.connect(_on_bee_died)
	_last_pos = _bee.position
	_last_time = float(_session.sim_time)
	Engine.time_scale = SPEED
	_phase = "crawling"
	_phase_frame = _frame


## Puts nectar where any bee can eat it.
func _stock_food() -> bool:
	for cell in _main.hive.cells:
		if cell.content_type != "" and cell.content_type != "nectar":
			continue
		var kept: String = cell.designated_type
		var kept_explicit: bool = cell.designation_is_explicit
		if kept != "" and kept != "nectar":
			cell.set_designation("", false)
		cell.add_resource("nectar", 400.0)
		if kept != "" and kept != "nectar":
			cell.set_designation(kept, kept_explicit)
		if cell.content_type == "nectar" and cell.amount >= 50.0:
			return true
	_fail("level %d has no cell that will take nectar" % COMB_LEVEL)
	return false


func _watch_recover() -> void:
	if not is_instance_valid(_bee) or bool(_bee.is_dying):
		_fail("the recovering forager died (%s) in phase %s, %s" % [
			str(_bee.death_cause) if is_instance_valid(_bee) else _death_cause, _phase, _trace])
		return
	if _frame - _phase_frame > RECOVER_FRAME_LIMIT:
		_fail("phase %s ran out of frames (state %d, health %.1f, energy %.1f, went home %s, ate %s, rested %s)" % [
			_phase, int(_bee.state), float(_bee.health), float(_bee.energy), _went_home, _ate, _rested])
		return
	var now: float = float(_session.sim_time)
	var cap: float = float(_config.health_capacity)
	_lowest_health = minf(_lowest_health, float(_bee.health))
	var inside: bool = _bee._is_inside_hive()
	if int(_bee.state) != _last_state:
		_last_state = int(_bee.state)
		_trace += " %d@h%.0f/e%.0f" % [_last_state, float(_bee.health), float(_bee.energy)]
	if _phase == "crawling":
		if inside:
			_check(_went_home, "the spent forager reached the hive without ever heading home")
			_check(float(_bee.health) < _health_before_home, "she lost no health crawling home")
			_check(_crawl_seconds > 0.5, "too little crawl was measured (%.2f s)" % _crawl_seconds)
			if _crawl_seconds > 0.0:
				var ratio: float = _crawl_distance / (_crawl_seconds * float(_bee.speed))
				_log.append("crawled %.0f px in %.1f s: %.3f of her speed" % [_crawl_distance, _crawl_seconds, ratio])
				var want: float = float(_config.spent_speed_factor)
				_check(absf(ratio - want) <= 0.03, "she crawled at %.3f of her speed, not %.2f" % [ratio, want])
			_phase = "inside"
			_phase_frame = _frame
		elif _bee.state == BeeEnums.State.TO_HIVE:
			_went_home = true
			if float(_bee.energy) <= 0.0 and now > _last_time:
				_crawl_distance += _bee.position.distance_to(_last_pos)
				_crawl_seconds += now - _last_time
		_last_pos = _bee.position
		_last_time = now
		return
	# inside
	if _bee.state == BeeEnums.State.FEEDING:
		_ate = true
	if _bee.state == BeeEnums.State.IN_HIVE_TO_EXIT and BeeSurvival.must_rest(_bee):
		_rested = true
	if not inside:
		var health_share: float = float(_bee.health) / cap
		var energy_share: float = float(_bee.energy) / float(_config.energy_capacity)
		_log.append("left again at health %.2f, energy %.2f (lowest health %.2f)" % [health_share, energy_share, _lowest_health / cap])
		_check(_ate, "she left the hive without eating")
		_check(_rested, "she was never held inside to rest")
		_check(health_share >= float(_config.rest_leave_health),
			"she left at health %.2f, under the %.2f threshold" % [health_share, float(_config.rest_leave_health)])
		_check(energy_share >= float(_config.rest_leave_energy),
			"she left at energy %.2f, under the %.2f threshold" % [energy_share, float(_config.rest_leave_energy)])
		_check(float(_bee.health) > _lowest_health, "her health never recovered inside")
		_finish()


# --- ambush ---------------------------------------------------------------

func _run_ambush() -> void:
	var flowers: Array = _main.get_tree().get_nodes_in_group("flowers")
	for bee in _main.get_tree().get_nodes_in_group("bees"):
		if not bee.is_queen and not bool(bee.is_dying):
			_bee = bee
			break
	if _bee == null or flowers.is_empty():
		_fail("level %d has no worker or no flower" % COMB_LEVEL)
		return
	_check(is_equal_approx(float(_bee.health), float(_config.health_capacity)), "the worker is not at full health")
	_config.crab_spider_attack_success_chance = 2.0
	_bee.current_flower = flowers[0]
	CrabSpider.resolve_attack(_bee)
	_check(bool(_bee.is_dying), "a successful ambush did not kill a bee at full health")
	_check(str(_bee.death_cause) == "crab spider ambush", "the ambush death's cause is %s" % str(_bee.death_cause))
	_finish()


# --- reporting ------------------------------------------------------------

func _check(ok: bool, message: String) -> void:
	if not ok:
		_failures.append(message)


func _fail(message: String) -> void:
	_failures.append(message)
	_phase = "done"


func _finish() -> void:
	_phase = "done"


func _report() -> void:
	Engine.time_scale = 1.0
	for line in _log:
		print("ED1 note: " + line)
	if _failures.is_empty():
		print("ED1 PASS")
		quit(0)
	else:
		for line in _failures:
			print("ED1 FAIL: " + line)
		quit(1)
