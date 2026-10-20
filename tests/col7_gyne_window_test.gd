extends SceneTree
## COL-7 test: the player sends a gyne, and the mating window decides what
## she is worth.
##
## Boots the real Main.tscn into level 3 and raises gynes there. Checks that:
## - a ready gyne stays put across many season ticks late in the year, where
##   the old automatic release would have sent her;
## - a gyne short of energy can't be sent: her panel's send button is greyed
##   out, her readout says why, and send_gyne refuses her;
## - sent through her panel in early spring, where the mating curve is 0,
##   she is gone, gyne_lost fires, and the release count, the genetic
##   points and the victory don't change, though the win's other conditions
##   (a winter over, the queen alive) hold;
## - sent in mid summer she counts: gyne_released fires, the release count
##   rises by one, she adds genetic_points_per_gyne (10) points, and the
##   Colony Run is won;
## - the points survive save_data/restore through JSON, and a record without
##   them restores 0.
##
## The genetic points and the win are a Colony Run's only (applies() reads
## the level row each time), so once the ticks have run the test points
## Session.starting_level at the Colony Run's row, 8, whose lone queen has
## no comb to raise a gyne in.
##
## Run by tests/test_col7_gyne_window.py:
##   godot --headless --fixed-fps 60 --path <repo> --script res://tests/col7_gyne_window_test.gd
## Prints "COL7 PASS" and exits 0, or prints each failure and exits 1.

const LEVEL := 3            # a Scenario level with comb: no Challenge branches
const COLONY_RUN_LEVEL := 8 # the Colony Run's level row
const BOOT_FRAMES := 10     # let Main._ready build the world first
const SPEED := 8.0          # the game's own fastest speed
const TICK_FRAMES := 600    # 80 in-game seconds at SPEED: about 80 season ticks
const MIN_TICK_SECONDS := 60.0
const LATE_DAY := 25        # season fraction 0.8: past the old release day (0.75)
const SPRING_DAY := 2       # season fraction 0.03: before the window opens
const SUMMER_DAY := 16      # season fraction 0.5: mid summer
const SEND_BUTTON := "Send her to found a colony"

var _main: Node = null
var _session: Node = null
var _config: Node = null
var _frame := 0
var _phase := "boot"
var _phase_frame := 0
var _ticked: Node2D = null
var _released_before := 0
var _sim_time_before := 0.0
var _released_signals := 0
var _lost_signals := 0
var _failures: PackedStringArray = PackedStringArray()


func _process(_delta: float) -> bool:
	_frame += 1
	match _phase:
		"boot":
			_boot()
		"settle":
			if _frame >= BOOT_FRAMES:
				_start_ticks()
		"ticks":
			_watch_ticks()
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


func _start_ticks() -> void:
	_config.seasons_on = true
	_check(is_equal_approx(float(_config.genetic_points_per_gyne), 10.0),
		"genetic_points_per_gyne is %s, not 10" % _config.genetic_points_per_gyne)
	_check(_main.season.gyne_lost.is_connected(_main.year_winter._on_gyne_lost),
		"season.gd's gyne_lost does not reach year_winter.gd's notice")
	_main.season.gyne_released.connect(func(_total: int) -> void: _released_signals += 1)
	_main.season.gyne_lost.connect(func() -> void: _lost_signals += 1)
	_jump_to_day(LATE_DAY)
	_ticked = _spawn_gyne()
	if _ticked == null:
		return
	_released_before = int(_session.gynes_released)
	_sim_time_before = float(_session.sim_time)
	Engine.time_scale = SPEED
	_phase = "ticks"
	_phase_frame = _frame


## Kept topped up the whole time, so she stays ready: only the season tick
## could send her, and it must not.
func _watch_ticks() -> void:
	if not is_instance_valid(_ticked) or _ticked.is_dying:
		_fail("a ready gyne left by herself %d frames into the season ticks" % (_frame - _phase_frame))
		return
	_ticked.energy = float(_config.energy_capacity)
	if _frame - _phase_frame < TICK_FRAMES:
		return
	Engine.time_scale = 1.0
	var ticked_seconds: float = float(_session.sim_time) - _sim_time_before
	print("COL7 a ready gyne stayed put through %.0f in-game seconds of season ticks" % ticked_seconds)
	_check(ticked_seconds >= MIN_TICK_SECONDS,
		"only %.0f in-game seconds passed, too few season ticks to show anything" % ticked_seconds)
	_check(int(_session.gynes_released) == _released_before, "the release count moved with no gyne sent")
	_check(_released_signals == 0 and _lost_signals == 0, "a gyne signal fired with no gyne sent")
	_check(_main.season.gyne_not_ready_reason(_ticked) == "",
		"the topped-up gyne is not ready: %s" % _main.season.gyne_not_ready_reason(_ticked))
	if _failures.is_empty():
		_send_gynes()
	_phase = "done"


func _send_gynes() -> void:
	var milestones: RefCounted = _main.colony_milestones
	_session.starting_level = COLONY_RUN_LEVEL
	_check(milestones.applies(), "the Colony Run's rules do not apply on level %d" % COLONY_RUN_LEVEL)
	# The win's other conditions hold from here on: a winter has come and
	# gone, and the queen is alive. Only the gyne decides it.
	_session.winter_ends_day = 1.0
	_session.winter_here = false
	_check(milestones.day_met(milestones.VICTORY) == -1, "the run was won before any gyne was sent")
	var points_before: int = milestones.genetic_points
	var released_before: int = int(_session.gynes_released)

	_check_not_ready()

	# Early spring: the curve is 0, so she is lost.
	_jump_to_day(SPRING_DAY)
	_check(_main.season.mating_curve() == 0.0,
		"the mating curve on day %d is %.3f, not 0" % [SPRING_DAY, _main.season.mating_curve()])
	_press_send(_ticked)
	_check(not is_instance_valid(_ticked) or _ticked.is_dying, "the gyne sent in early spring did not leave")
	_check(_lost_signals == 1, "gyne_lost fired %d times for one gyne sent in early spring" % _lost_signals)
	_check(_released_signals == 0, "gyne_released fired for a gyne sent in early spring")
	_check(int(_session.gynes_released) == released_before, "a gyne sent in early spring was counted as released")
	_check(milestones.genetic_points == points_before,
		"a gyne sent in early spring earned %d genetic points" % (milestones.genetic_points - points_before))
	_check(milestones.day_met(milestones.VICTORY) == -1, "a gyne sent in early spring won the run")

	# Mid summer: the curve is 1, so she counts and earns the full 10.
	_jump_to_day(SUMMER_DAY)
	_check(is_equal_approx(_main.season.mating_curve(), 1.0),
		"the mating curve on day %d is %.3f, not 1" % [SUMMER_DAY, _main.season.mating_curve()])
	var summer: Node2D = _spawn_gyne()
	if summer == null:
		return
	_press_send(summer)
	_check(not is_instance_valid(summer) or summer.is_dying, "the gyne sent in mid summer did not leave")
	_check(_released_signals == 1, "gyne_released fired %d times for one gyne sent in mid summer" % _released_signals)
	_check(_lost_signals == 1, "gyne_lost fired for a gyne sent in mid summer")
	_check(int(_session.gynes_released) == released_before + 1,
		"the release count is %d after one gyne sent in mid summer, not %d" % [_session.gynes_released, released_before + 1])
	_check(milestones.genetic_points == points_before + 10,
		"a gyne sent in mid summer earned %d genetic points, not 10" % (milestones.genetic_points - points_before))
	_check(milestones.day_met(milestones.VICTORY) >= 0, "a gyne sent in mid summer after a winter did not win the run")
	print("COL7 sent in early spring: lost; in mid summer: released, %d genetic points" % milestones.genetic_points)

	_check_points_saved(milestones)


## A gyne short of energy: the button is there but greyed out, her readout
## says why, and send_gyne refuses her.
func _check_not_ready() -> void:
	var hungry: Node2D = _spawn_gyne()
	if hungry == null:
		return
	hungry.energy = 0.1 * float(_config.energy_capacity)
	var why: String = _main.season.gyne_not_ready_reason(hungry)
	_check(why != "", "a gyne at a tenth of her crop is ready to be sent")
	_main.hud.update_selection([hungry])
	var button: Button = _find_button(_send_row(), SEND_BUTTON)
	if button == null:
		_fail("a gyne's panel has no \"%s\" button" % SEND_BUTTON)
		return
	_check(button.disabled, "the send button is live for a gyne who is not ready")
	_check(why != "" and _main.hud.activity_label.text.contains(why),
		"her readout does not say why she can't go: \"%s\"" % _main.hud.activity_label.text)
	_check(not _main.season.send_gyne(hungry), "send_gyne sent a gyne who was not ready")
	_check(is_instance_valid(hungry) and not hungry.is_dying, "a gyne who was not ready left")
	_main.hud.update_selection([])
	hungry.is_gyne = false       # out of the way of the sends below


## Selects `gyne` and presses her panel's send button, as the player does.
func _press_send(gyne: Node2D) -> void:
	gyne.energy = float(_config.energy_capacity)
	_main.hud.update_selection([gyne])
	var button: Button = _find_button(_send_row(), SEND_BUTTON)
	if button == null:
		_fail("a ready gyne's panel has no \"%s\" button" % SEND_BUTTON)
		return
	_check(not button.disabled, "the send button is greyed out for a ready gyne")
	button.pressed.emit()
	_main.hud.update_selection([])


## The points go into the save record beside the days, survive a JSON
## round trip, and a record from before them restores 0.
func _check_points_saved(milestones: RefCounted) -> void:
	var saved: Dictionary = JSON.parse_string(JSON.stringify(milestones.save_data()))
	_check(int(saved.get("genetic_points", -1)) == 10,
		"the saved record holds genetic_points %s, not 10" % saved.get("genetic_points"))
	milestones.restore({})
	_check(milestones.genetic_points == 0, "an empty record restored %d genetic points" % milestones.genetic_points)
	milestones.restore(saved)
	_check(milestones.genetic_points == 10, "the saved points restored as %d, not 10" % milestones.genetic_points)
	_check(milestones.day_met(milestones.VICTORY) >= 0, "the victory day did not survive the restore")
	var before_points: Dictionary = saved.duplicate()
	before_points.erase("genetic_points")
	milestones.restore(before_points)
	_check(milestones.genetic_points == 0,
		"a record without genetic_points restored %d of them" % milestones.genetic_points)


## Puts the clock at the start of `day` (plus a second), as the run's own
## day counter reads it.
func _jump_to_day(day: int) -> void:
	_session.sim_time = float(day - 1) * float(_config.seconds_per_day) + 1.0


func _spawn_gyne() -> Node2D:
	var cell: Node2D = _main.hive.find_empty_cell()
	if cell == null:
		_fail("no empty cell to hatch a gyne at")
		return null
	var gyne: Node2D = _main.world_building._spawn_hatched_bee(_main.Bee.Role.NURSERY, cell, true, "feed")
	gyne.energy = float(_config.energy_capacity)
	return gyne


func _send_row() -> Node:
	return _main.hud.focus_column.get_node_or_null("gyne_send_row")


func _find_button(node: Node, text: String) -> Button:
	if node == null:
		return null
	if node is Button and node.text == text:
		return node
	for child: Node in node.get_children():
		var found: Button = _find_button(child, text)
		if found != null:
			return found
	return null


func _check(condition: bool, failure: String) -> void:
	if not condition:
		_failures.append(failure)


func _fail(line: String) -> void:
	_failures.append(line)
	_phase = "done"


func _report() -> void:
	Engine.time_scale = 1.0
	if _failures.is_empty():
		print("COL7 PASS")
		quit(0)
	else:
		for line: String in _failures:
			print("COL7 FAIL: " + line)
		quit(1)
