extends SceneTree
## Drones get no Job / Doing / "If idle" rows. Run by
## tests/test_drone_command_rows.py:
##   godot --headless --path <repo> --script res://tests/drone_command_rows_test.gd
## Prints "DRONE_ROWS PASS" and exits 0, or each "DRONE_ROWS FAIL" line and exits 1.

class FakeBee:
	var is_drone := false


func _initialize() -> void:
	var hud = load("res://scripts/hud.gd").new()
	var rows = hud._command_rows
	var drone := FakeBee.new()
	drone.is_drone = true
	var worker := FakeBee.new()
	var failures: PackedStringArray = PackedStringArray()
	if not rows._all_drones([drone, drone]):
		failures.append("two drones should count as all drones")
	if rows._all_drones([drone, worker]):
		failures.append("a mixed selection should keep its rows")
	if rows._all_drones([worker]):
		failures.append("a worker is not a drone")
	if rows._all_drones([]):
		failures.append("an empty selection is not all drones")
	hud.free()
	if failures.is_empty():
		print("DRONE_ROWS PASS")
		quit(0)
	else:
		for f in failures:
			print("DRONE_ROWS FAIL ", f)
		quit(1)
