extends SceneTree
## BS-13 test: the Run availability table's stage columns. Nurses is
## introduced at 2.5 and free at 2.5; Honey worker is named by no stage.
##
## Run by tests/test_bs13_stage_columns.py:
##   godot --headless --path <repo> --script res://tests/bs13_stage_columns_test.gd
## Prints "BS13 PASS" and exits 0, or prints each failure and exits 1.

var _failures: PackedStringArray = PackedStringArray()


func _process(_delta: float) -> bool:
	_run()
	_report()
	return true


func _run() -> void:
	var availability: GDScript = load("res://scripts/run_availability.gd")
	var nurses := "skill.brood.nurses"
	var honey_worker := "skill.brood.honey_worker"
	_expect(availability.introduced_stage(nurses), "2.5", "Nurses introduced at")
	_expect(",".join(PackedStringArray(availability.free_stages(nurses))), "2.5", "Nurses free at")
	_expect(availability.introduced_stage(honey_worker), "", "Honey worker introduced at")
	_expect(str(availability.free_stages(honey_worker).size()), "0", "Honey worker free stage count")


func _expect(actual: String, expected: String, what: String) -> void:
	if actual != expected:
		_failures.append("%s: expected \"%s\", got \"%s\"" % [what, expected, actual])


func _report() -> void:
	if _failures.is_empty():
		print("BS13 PASS")
		quit(0)
	else:
		for line in _failures:
			print("BS13 FAIL: " + line)
		quit(1)
