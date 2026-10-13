extends SceneTree
## Weighted flower choice: off and unowned means nearest-first; owned (or the
## Developer mode force-on) means the weighted scoring.

class Owned:
	var keys: Array[String] = []
	func is_behaviour_enabled(key: String) -> bool:
		return key in keys

class TestBee extends Node2D:
	var heading: Vector2 = Vector2.RIGHT

func _process(_delta: float) -> bool:
	_run()
	return true

func _run() -> void:
	var BeeForaging: GDScript = load("res://scripts/bee_foraging.gd")
	var failures: PackedStringArray = PackedStringArray()
	var session: Node = root.get_node("Session")
	var config: Node = root.get_node("GameConfig")
	var old_progression: Object = session.progression
	var old_on: bool = config.probabilistic_choice_on
	var owned := Owned.new()
	session.progression = owned
	config.probabilistic_choice_on = false

	_expect(failures, not BeeForaging.probabilistic_choice_on(), "off while unowned and the setting is off")
	owned.keys = ["probabilistic_choice_on"]
	_expect(failures, BeeForaging.probabilistic_choice_on(), "on once Weighted flower choice is owned")
	owned.keys = []
	config.probabilistic_choice_on = true
	_expect(failures, BeeForaging.probabilistic_choice_on(), "the Developer force-on still works")
	config.probabilistic_choice_on = false

	# Behaviour: a bee facing right with a near flower behind her and a
	# slightly farther one ahead. Weighted scoring picks the one ahead
	# sometimes; nearest-first never does.
	var bee := TestBee.new()
	bee.position = Vector2.ZERO
	var behind := Node2D.new()
	behind.position = Vector2(-100, 0)
	var ahead := Node2D.new()
	ahead.position = Vector2(110, 0)
	var nodes: Array = [behind, ahead]
	var accept := func(_f): return true
	var ahead_picks := 0
	for i in 400:
		if BeeForaging._weighted_flower_choice(bee, nodes, accept, 500.0) == ahead:
			ahead_picks += 1
	_expect(failures, ahead_picks > 0, "weighted choice sometimes takes the farther flower ahead")
	_expect(failures, ahead_picks < 400, "weighted choice still favours distance")

	session.progression = old_progression
	config.probabilistic_choice_on = old_on
	if failures.is_empty():
		print("T3_1 PASS")
		quit(0)
	else:
		for failure in failures:
			print("T3_1 FAIL ", failure)
		quit(1)

func _expect(failures: PackedStringArray, ok: bool, what: String) -> void:
	if not ok:
		failures.append(what)
