extends SceneTree
## Rain skills and per-level weather policy, exercised through live functions.

class Owned:
	var keys: Array[String] = []
	func is_behaviour_enabled(key: String) -> bool:
		return key in keys

class WeatherWorld extends Node2D:
	var rain_target: float = 0.0
	var season: Node = null

class TestBee extends Node2D:
	var world: Node2D = null
	var state: int = 0
	var current_flower: Node2D = null
	var player_driven: bool = false
	var indoors: bool = false
	func _is_inside_hive() -> bool:
		return indoors

class TestFlower extends Node2D:
	var released: bool = false
	func release(_bee: Node2D) -> void:
		released = true

func _process(_delta: float) -> bool:
	_run()
	return true

func _run() -> void:
	var BeeStatus: GDScript = load("res://scripts/bee_status.gd")
	var BeeForaging: GDScript = load("res://scripts/bee_foraging.gd")
	var BeeEnums: GDScript = load("res://scripts/bee_enums.gd")
	var Levels: GDScript = load("res://scripts/levels.gd")
	var failures: PackedStringArray = PackedStringArray()
	var session: Node = root.get_node("Session")
	var config: Node = root.get_node("GameConfig")
	var old_progression: Object = session.progression
	var old_rain: float = session.rain_intensity
	var old_weather: bool = config.weather_on
	var old_override: Dictionary = Levels.scenario_override
	var owned := Owned.new()
	var bee := TestBee.new()
	var world := WeatherWorld.new()
	root.add_child(world)
	world.add_child(bee)
	bee.world = world
	var limit: float = config.rain_forage_limit

	session.progression = owned
	session.rain_intensity = 0.0
	world.rain_target = limit + 0.1
	_expect(failures, not BeeStatus.grounded_for_departure(bee), "unowned bee departs before rain arrives")
	owned.keys = ["weather_sensing_on"]
	_expect(failures, BeeStatus.grounded_for_departure(bee), "Weather sensing keeps bee in for approaching rain")
	world.rain_target = 0.0
	_expect(failures, not BeeStatus.grounded_for_departure(bee), "Weather sensing allows departure after rain target clears")
	session.rain_intensity = limit + 0.1
	_expect(failures, BeeStatus.grounded_for_departure(bee), "current rain grounds an owned bee")
	owned.keys = []
	_expect(failures, BeeStatus.grounded_for_departure(bee), "current rain still grounds an unowned bee")

	bee.state = BeeEnums.State.COLLECTING
	var flower := TestFlower.new()
	world.add_child(flower)
	bee.current_flower = flower
	BeeForaging.recall_for_rain(bee)
	_expect(failures, bee.state == BeeEnums.State.COLLECTING, "unowned outside bee keeps collecting")
	_expect(failures, not flower.released, "unowned bee keeps its flower")
	owned.keys = ["rain_recall_on"]
	BeeForaging.recall_for_rain(bee)
	_expect(failures, bee.state == BeeEnums.State.TO_HIVE, "owned outside bee abandons collecting for hive")
	_expect(failures, flower.released and bee.current_flower == null, "recall frees the flower")
	bee.indoors = true
	bee.state = BeeEnums.State.COLLECTING
	BeeForaging.recall_for_rain(bee)
	_expect(failures, bee.state == BeeEnums.State.COLLECTING, "inside bee is not recalled")
	bee.indoors = false
	session.rain_intensity = limit
	BeeForaging.recall_for_rain(bee)
	_expect(failures, bee.state == BeeEnums.State.COLLECTING, "recall waits until rain exceeds limit")
	session.rain_intensity = limit + 0.1
	for kept in [BeeEnums.State.DUMPING_WASTE, BeeEnums.State.DUMPING_DIRT, BeeEnums.State.MOVE_TO_POINT]:
		bee.state = kept
		BeeForaging.recall_for_rain(bee)
		_expect(failures, bee.state == kept, "recall leaves non-foraging outdoor state %d alone" % kept)

	config.weather_on = false
	_expect(failures, Levels.weather_enabled(8), "Colony Run enables rain with global setting off")
	_expect(failures, not Levels.weather_enabled(1) and not Levels.weather_enabled(2), "Challenges keep rain off")
	_expect(failures, not Levels.weather_enabled(3), "Scenario follows setting when off")
	config.weather_on = true
	_expect(failures, Levels.weather_enabled(3), "Scenario follows setting when on")
	_expect(failures, not Levels.weather_enabled(1) and not Levels.weather_enabled(2), "Challenges keep rain off when setting on")
	Levels.scenario_override = {"weather": false}
	_expect(failures, not Levels.weather_enabled(Levels.SCENARIO_LEVEL_ID), "explicit scenario override disables rain")
	Levels.scenario_override = {}

	session.progression = old_progression
	session.rain_intensity = old_rain
	config.weather_on = old_weather
	Levels.scenario_override = old_override
	world.queue_free()
	if failures.is_empty():
		print("T2_5 PASS")
		quit(0)
	else:
		for failure in failures:
			print("T2_5 FAIL ", failure)
		quit(1)

func _expect(failures: PackedStringArray, ok: bool, what: String) -> void:
	if not ok:
		failures.append(what)
