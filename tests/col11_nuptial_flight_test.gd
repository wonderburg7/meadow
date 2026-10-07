extends SceneTree
## COL-11 test: an unmated queen's nuptial flights.
##
## Boots the real Main.tscn into level 3, unmates its queen and, through
## the succession window's "Nuptial flights" button, sends her flying. With
## the peak chance raised to certainty, checks that:
## - season.gd's mating curve is 0 in early spring and 1 at mid summer;
## - with her selected, the panel's Mating row switches her mode both ways;
## - in early spring she leaves the hive, lays nothing while she is out,
##   comes home, and has not mated (the curve is 0 there);
## - she does not fly a second time the same day;
## - the next day, a move order on her way home ends that flight without a
##   roll, and she still gets back inside;
## - on a mid-summer day she flies again and comes home mated, her flights
##   mode gone, her readout no longer "Unmated" and the Mating row gone;
## - she then lays worker brood, not drones.
##
## Runs at eight times speed on a fixed frame rate (the Python wrapper
## passes --fixed-fps), so a flight of a few in-game minutes takes a few
## thousand frames.
##
## Run by tests/test_col11_nuptial_flight.py:
##   godot --headless --fixed-fps 60 --path <repo> --script res://tests/col11_nuptial_flight_test.gd
## Prints "COL11 PASS" and exits 0, or prints each failure and exits 1.

const LEVEL := 3            # a Scenario level with comb: no Challenge branches
const BOOT_FRAMES := 10     # let Main._ready build the world first
const SPEED := 8.0          # the game's own fastest speed
const FLIGHT_FRAMES := 9000 # frames allowed for one whole flight
const SAME_DAY_FRAMES := 300  # 40 in-game seconds, well inside the day
const LAY_FRAMES := 9000    # frames allowed for her first worker egg
const SPRING_DAY := 2       # season fraction 0.03: before the window opens
const INTERRUPT_DAY := 3    # season fraction 0.07: still before the window
const SUMMER_DAY := 16      # season fraction 0.5: mid summer

var _main: Node = null
var _session: Node = null
var _config: Node = null
var _queen: Node2D = null
var _frame := 0
var _phase := "boot"
var _phase_frame := 0
var _left_hive := false
var _brood_at_departure := -1
var _interrupted := false
var _worker_brood_at_mating: Array = []
var _failures: PackedStringArray = PackedStringArray()


func _process(_delta: float) -> bool:
	_frame += 1
	# A flight never loses her: a queen who died on one fails here rather
	# than on the next call into a freed node.
	if _phase not in ["boot", "settle", "done"] and not is_instance_valid(_queen):
		_fail("the queen died during the %s" % _phase)
	match _phase:
		"boot":
			_boot()
		"settle":
			if _frame >= BOOT_FRAMES:
				_start_flights()
		"spring_flight":
			_watch_flight(_after_spring_flight)
		"same_day":
			_watch_same_day()
		"interrupted_flight":
			_watch_interrupted_flight()
		"summer_flight":
			_watch_flight(_after_summer_flight)
		"worker_brood":
			_watch_worker_brood()
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
	_session = root.get_node("Session")
	_config = root.get_node("GameConfig")
	_session.starting_level = LEVEL
	_session.menu_pending = false
	var scene: PackedScene = load("res://scenes/Main.tscn")
	_main = scene.instantiate()
	root.add_child(_main)
	current_scene = _main
	_phase = "settle"


func _start_flights() -> void:
	_queen = _main.queen
	if _queen == null or not is_instance_valid(_queen):
		_fail("level %d has no queen after boot" % LEVEL)
		return
	_config.seasons_on = true
	# Above 1 so the clamped chance is certain wherever the curve is above
	# 0 -- the test is about where she can mate, not about luck.
	_config.nuptial_flight_peak_chance = 2.0

	_jump_to_day(SUMMER_DAY)
	_check(is_equal_approx(_main.season.mating_curve(), 1.0),
		"the mating curve on day %d is %.3f, not 1" % [SUMMER_DAY, _main.season.mating_curve()])
	_jump_to_day(SPRING_DAY)
	_check(_main.season.mating_curve() == 0.0,
		"the mating curve on day %d is %.3f, not 0" % [SPRING_DAY, _main.season.mating_curve()])
	_check(_main.season.nuptial_mating_chance() == 0.0, "the mating chance in early spring is not 0")

	_queen.is_mated = false
	_check(not _queen.nuptial_flights, "an unmated queen starts on nuptial flights")
	_main.succession_panel.open_for(_queen)
	_main.succession_panel.choose_flights(true)
	_check(_queen.nuptial_flights, "the window's Nuptial flights button did not set her mode")
	_check(not _main.succession_panel.is_open(), "the succession window stayed open after a choice")
	_check_mating_row()
	Engine.time_scale = SPEED
	_begin_flight_watch("spring_flight")


## Puts the clock at the start of `day` (plus a second), as the run's own
## day counter reads it.
func _jump_to_day(day: int) -> void:
	_session.sim_time = float(day - 1) * float(_config.seconds_per_day) + 1.0


func _begin_flight_watch(phase: String) -> void:
	_left_hive = false
	_brood_at_departure = -1
	_phase = phase
	_phase_frame = _frame


func _watch_flight(on_return: Callable) -> void:
	var flown_before: int = 0 if _phase == "spring_flight" else 1
	if not _queen._is_inside_hive():
		if not _left_hive:
			_left_hive = true
			_brood_at_departure = _brood_count(false)
		# Nothing laid while she is out.
		if _brood_count(false) > _brood_at_departure:
			_fail("brood was laid while the queen was out on a flight")
			return
	if _queen.nuptial_flights_flown > flown_before:
		print("COL11 %s home after %d frames on day %d, mated %s" % [
			_phase, _frame - _phase_frame, _main.day, _queen.is_mated,
		])
		_check(_left_hive, "the queen came home from a flight without leaving the hive")
		on_return.call()
		return
	if _frame - _phase_frame > FLIGHT_FRAMES:
		_fail("%d frames into the %s the queen had not come home (phase %d, state %d, day %d)" % [
			FLIGHT_FRAMES, _phase, _queen.nuptial_phase, _queen.state, _main.day,
		])


func _after_spring_flight() -> void:
	_check(not _queen.is_mated, "the queen mated in early spring, where the curve is 0")
	_check(_queen.nuptial_flights, "an unmated queen lost her flights mode")
	_check(_queen.role_name_text().contains("Unmated"),
		"the unmated queen's readout is \"%s\"" % _queen.role_name_text())
	# Back to the start of the same day, so the watch below cannot run into
	# the next one, when she would rightly fly again.
	_jump_to_day(SPRING_DAY)
	_phase = "same_day"
	_phase_frame = _frame


func _watch_same_day() -> void:
	if _queen.nuptial_phase != _queen.NUPTIAL_NONE:
		_fail("the queen set out a second time on day %d" % _main.day)
		return
	if _frame - _phase_frame < SAME_DAY_FRAMES:
		return
	_check(int(_main.day) == SPRING_DAY, "the same-day watch ran into day %d" % _main.day)
	if not _failures.is_empty():
		_phase = "done"
		return
	_jump_to_day(INTERRUPT_DAY)
	_begin_flight_watch("interrupted_flight")


## On her way home she is ordered further out into the meadow. The flight
## ends there without a roll, and once the order has run its course she
## comes home by herself.
func _watch_interrupted_flight() -> void:
	if not _interrupted:
		if _queen.nuptial_phase == _queen.NUPTIAL_BACK and not _queen._is_inside_hive():
			var away: Vector2 = (_queen.position - _main.hive.position).normalized()
			_queen.command_move_to(_queen.global_position + away * 100.0)
			_interrupted = true
	elif _queen._is_inside_hive() and _queen.nuptial_phase == _queen.NUPTIAL_NONE:
		print("COL11 interrupted flight home %d frames after it began" % (_frame - _phase_frame))
		_check(_queen.nuptial_flights_flown == 1,
			"the interrupted flight rolled (%d flights flown)" % _queen.nuptial_flights_flown)
		_check(not _queen.is_mated, "the queen mated on an interrupted flight")
		_jump_to_day(SUMMER_DAY)
		_begin_flight_watch("summer_flight")
		return
	if _frame - _phase_frame > FLIGHT_FRAMES:
		_fail("%d frames into the interrupted flight the queen was not home (interrupted %s, phase %d, state %d, inside %s)" % [
			FLIGHT_FRAMES, _interrupted, _queen.nuptial_phase, _queen.state, _queen._is_inside_hive(),
		])


func _after_summer_flight() -> void:
	_check(_queen.is_mated, "the queen came home from a mid-summer flight unmated")
	_check(not _queen.nuptial_flights, "a mated queen still has a flights mode")
	_check(not _queen.role_name_text().contains("Unmated"),
		"the mated queen's readout is \"%s\"" % _queen.role_name_text())
	_main.hud.update_selection([_queen])
	_check(_mating_row() == null, "a mated queen's panel still has a Mating row")
	if not _failures.is_empty():
		_phase = "done"
		return
	_worker_brood_at_mating = _worker_brood_cells()
	_phase = "worker_brood"
	_phase_frame = _frame


## She lays as any queen does: a cell of worker brood that was not there
## when she came home.
func _watch_worker_brood() -> void:
	for cell in _worker_brood_cells():
		if not _worker_brood_at_mating.has(cell):
			print("COL11 first worker egg %d frames after mating" % (_frame - _phase_frame))
			_phase = "done"
			return
	if _frame - _phase_frame > LAY_FRAMES:
		_fail("%d frames after mating the queen had laid no worker brood (drone brood %d)" % [
			LAY_FRAMES, _brood_count(true),
		])


## With her selected, the panel's Mating row switches her mode either way,
## lighting the choice in force. Leaves her on flights.
func _check_mating_row() -> void:
	_main.hud.update_selection([_queen])
	for choice in [["Lay drones in the hive", false], ["Nuptial flights", true]]:
		var button: Button = _find_button(_mating_row(), choice[0])
		if button == null:
			_fail("the unmated queen's panel has no \"%s\" button in a Mating row" % choice[0])
			return
		button.pressed.emit()
		_check(_queen.nuptial_flights == choice[1],
			"the Mating row's \"%s\" left her flights mode %s" % [choice[0], _queen.nuptial_flights])
	_main.hud.update_selection([])


func _mating_row() -> Node:
	return _main.hud.focus_column.get_node_or_null("mating_row")


func _find_button(node: Node, text: String) -> Button:
	if node == null:
		return null
	if node is Button and node.text == text:
		return node
	for child in node.get_children():
		var found: Button = _find_button(child, text)
		if found != null:
			return found
	return null


func _brood_count(drones_only: bool) -> int:
	var count := 0
	for cell in _main.get_tree().get_nodes_in_group("hive_cells"):
		if is_instance_valid(cell) and cell.content_type == "brood":
			if not drones_only or cell.brood_is_drone:
				count += 1
	return count


func _worker_brood_cells() -> Array:
	var out: Array = []
	for cell in _main.get_tree().get_nodes_in_group("hive_cells"):
		if is_instance_valid(cell) and cell.content_type == "brood" and not cell.brood_is_drone:
			out.append(cell)
	return out


func _check(condition: bool, failure: String) -> void:
	if not condition:
		_failures.append(failure)


func _fail(line: String) -> void:
	_failures.append(line)
	_phase = "done"


func _report() -> void:
	Engine.time_scale = 1.0
	if _failures.is_empty():
		print("COL11 PASS")
		quit(0)
	else:
		for line in _failures:
			print("COL11 FAIL: " + line)
		quit(1)
