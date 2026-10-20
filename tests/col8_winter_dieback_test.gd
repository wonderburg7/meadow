extends SceneTree
## COL-8 test: winter kills the meadow back and spring regrows it.
##
## Boots Main.tscn into level 3, fills every flower, then resolves a winter
## through season.gd::_resolve_winter and checks that:
## - every flower holds no nectar or pollen just after the skip, and the
##   flower count is unchanged;
## - on spring's first day a flower's season_strength() is below the same
##   date's value with no winter behind it (regrowth factor 1);
## - by day 1 + spring_regrowth_days it equals that value again;
## - before any winter the regrowth factor is 1 (the first spring is unchanged).
##
## Run by tests/test_col8_winter_dieback.py:
##   godot --headless --path <repo> --script res://tests/col8_winter_dieback_test.gd
## Prints "COL8 PASS" and exits 0, or prints each failure and exits 1.

const LEVEL := 3
const BOOT_FRAMES := 10

var _main: Node = null
var _frame := 0
var _done := false
var _failures: PackedStringArray = PackedStringArray()


func _process(_delta: float) -> bool:
	_frame += 1
	if _done:
		return false
	if _frame == 1:
		var session: Node = root.get_node("Session")
		session.starting_level = LEVEL
		session.menu_pending = false
		var scene: PackedScene = load("res://scenes/Main.tscn")
		_main = scene.instantiate()
		root.add_child(_main)
		current_scene = _main
	elif _frame >= BOOT_FRAMES:
		_run()
		_done = true
		_report()
	return false


func _run() -> void:
	var session: Node = root.get_node("Session")
	var config: Node = root.get_node("GameConfig")
	var Flower: GDScript = load("res://scripts/flower.gd")
	config.seasons_on = true
	config.out_of_season_strength = 0.2
	var spd: float = float(config.seconds_per_day)
	var flowers: Array = _main.get_tree().get_nodes_in_group("flowers")
	_check(flowers.size() > 0, "level %d has no flowers" % LEVEL)
	if flowers.is_empty():
		return
	var flower: Variant = flowers[0]
	var season_season: Node2D = _main.season

	season_season._update_regrowth()
	_check(Flower.regrowth_factor == 1.0, "regrowth factor is %f before any winter" % Flower.regrowth_factor)

	var winter_start: float = config.season_length_days + 1.0
	session.sim_time = (winter_start - 1.0) * spd
	for f: Variant in flowers:
		f._nectar_amount = f.nectar_capacity
		f._pollen_amount = f.pollen_capacity
		f._last_recharge_update = session.sim_time
	var count_before: int = flowers.size()
	session.winter_ends_day = winter_start + config.winter_length_days
	session.winter_here = true
	season_season._resolve_winter(config.winter_length_days)

	_check(_main.get_tree().get_nodes_in_group("flowers").size() == count_before, "the flower count changed")
	for f: Variant in flowers:
		if f._nectar_amount != 0.0 or f._pollen_amount != 0.0 or f._last_recharge_update != session.sim_time:
			_check(false, "a flower did not die back cleanly (nectar %f, pollen %f)" % [f._nectar_amount, f._pollen_amount])
			break
	_check(flower.nectar_amount == 0.0, "the first read after the skip credited %f nectar" % flower.nectar_amount)

	var with_winter: float = flower.season_strength()
	Flower.regrowth_factor = 1.0
	var without: float = flower.season_strength()
	_check(with_winter < without, "spring's first day strength %f is not below %f" % [with_winter, without])
	_check(Flower.regrowth_factor == 1.0, "setup")

	session.sim_time += config.spring_regrowth_days * spd
	season_season._update_regrowth()
	_check(Flower.regrowth_factor == 1.0, "regrowth factor %f at day 1 + regrowth days" % Flower.regrowth_factor)
	session.sim_time -= config.spring_regrowth_days * spd * 0.5
	season_season._update_regrowth()
	_check(Flower.regrowth_factor > 0.0 and Flower.regrowth_factor < 1.0, "halfway factor %f" % Flower.regrowth_factor)


func _check(condition: bool, failure: String) -> void:
	if not condition:
		_failures.append(failure)


func _report() -> void:
	if _failures.is_empty():
		print("COL8 PASS")
		quit(0)
		return
	for line: String in _failures:
		print("COL8 FAIL: ", line)
	quit(1)
