extends SceneTree
## Associative learning: gated by the skill, builds over visits, fades elsewhere.

class Owned:
	var keys: Array[String] = []
	func is_behaviour_enabled(key: String) -> bool:
		return key in keys

class TestBee extends Node2D:
	var species_experience: Dictionary = {}

func _process(_delta: float) -> bool:
	_run()
	return true

func _run() -> void:
	var BeeForaging: GDScript = load("res://scripts/bee_foraging.gd")
	var failures: PackedStringArray = PackedStringArray()
	var session: Node = root.get_node("Session")
	var config: Node = root.get_node("GameConfig")
	var old_progression: Object = session.progression
	var old_on: bool = config.handling_experience_on
	var owned := Owned.new()
	session.progression = owned
	config.handling_experience_on = false
	var bee := TestBee.new()

	_expect(failures, not BeeForaging.handling_experience_on(), "off before purchase")
	owned.keys = ["handling_experience_on"]
	_expect(failures, BeeForaging.handling_experience_on(), "on once Associative learning is owned")
	_expect(failures, is_equal_approx(BeeForaging._handling_experience_scale(bee, "clover"), 1.0), "first-timer handles at full time")

	for i in 10:
		BeeForaging.record_species_visit(bee, "clover")
	_expect(failures, is_equal_approx(BeeForaging._handling_experience_scale(bee, "clover"), config.handling_experience_floor), "ten visits reach 0.75")

	for i in 14:
		BeeForaging.record_species_visit(bee, "lavender")
	_expect(failures, bee.species_experience.has("clover") and float(bee.species_experience["clover"]) > 0.0, "experience survives 14 visits elsewhere")
	BeeForaging.record_species_visit(bee, "lavender")
	_expect(failures, not bee.species_experience.has("clover"), "fifteen visits elsewhere erase it")
	_expect(failures, is_equal_approx(BeeForaging._handling_experience_scale(bee, "clover"), 1.0), "erased species is a first-timer again")

	# Save and restore: JSON round trip, as the save file stores it.
	var parsed: Variant = JSON.parse_string(JSON.stringify(bee.species_experience))
	var restored := TestBee.new()
	restored.species_experience = parsed
	_expect(failures, is_equal_approx(BeeForaging._handling_experience_scale(restored, "lavender"), BeeForaging._handling_experience_scale(bee, "lavender")), "experience survives save and restore")
	var old_save := TestBee.new()
	old_save.species_experience = JSON.parse_string("{\"clover\": 10}")
	_expect(failures, is_equal_approx(BeeForaging._handling_experience_scale(old_save, "clover"), config.handling_experience_floor), "integer counts from old saves load")

	session.progression = old_progression
	config.handling_experience_on = old_on
	if failures.is_empty():
		print("T2_6 PASS")
		quit(0)
	else:
		for failure in failures:
			print("T2_6 FAIL ", failure)
		quit(1)

func _expect(failures: PackedStringArray, ok: bool, what: String) -> void:
	if not ok:
		failures.append(what)
