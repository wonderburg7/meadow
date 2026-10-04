extends SceneTree
## HO-16 test: Challenge 2's Nurse gating (C-81), stage dwell (C-94) and the
## skill tree's Escape (C-100), checked headlessly on the real Main.tscn.
##
## Run by tests/test_challenge2_checks.py:
##   godot --headless --fixed-fps 60 --path <repo> --script res://tests/challenge2_checks_test.gd -- <mode>
## Modes: nurse_gating | dwell | escape. Prints "C2CHECKS PASS" and exits 0,
## or prints each failure and exits 1.

const CHALLENGE_TWO_LEVEL := 2  # main_menu.gd: Challenge 2
const BOOT_FRAMES := 10         # let Main._ready build the world first
const DWELL_FRAME_LIMIT := 3000

var _main: Node = null
var _runner: Node = null
var _hud: Node = null
var _frame := 0
var _phase := "boot"
var _mode := "nurse_gating"
var _roles: Script = null
var _stages: Script = null
var _totals: Dictionary = {}
var _dwell_start := 0
var _logged_unpause := false
var _failures: PackedStringArray = PackedStringArray()
var _log: PackedStringArray = PackedStringArray()


func _process(delta: float) -> bool:
	_frame += 1
	match _phase:
		"boot":
			_boot()
		"settle":
			if _frame >= BOOT_FRAMES:
				_start_mode()
		"nurse_after_buy":
			_check_nurse_after_buy()
		"dwell":
			_watch_dwell(delta)
		"escape_after":
			_check_escape_after()
	if _phase == "done":
		_report()
		return true
	return false


# Autoloads are reached through the tree, and scripts through load(), because
# a --script run compiles this file before the autoloads exist.
func _boot() -> void:
	if not root.has_node("Session"):
		_fail("Session autoload is not loaded")
		return
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		_mode = args[0]
	var session: Node = root.get_node("Session")
	session.starting_level = CHALLENGE_TWO_LEVEL
	session.menu_pending = false
	var scene: PackedScene = load("res://scenes/Main.tscn")
	_main = scene.instantiate()
	root.add_child(_main)
	current_scene = _main
	_roles = load("res://scripts/roles.gd")
	_stages = load("res://scripts/challenge_stages.gd")
	_phase = "settle"


func _start_mode() -> void:
	_runner = _main.get("challenge_runner")
	_hud = _main.get("hud")
	if _runner == null or not bool(_runner.get("active")):
		_fail("Challenge 2 did not start its challenge runner")
		return
	match _mode:
		"nurse_gating":
			_start_nurse_gating()
		"dwell":
			_start_dwell()
		"escape":
			_start_escape()
		_:
			_fail("unknown mode '%s'" % _mode)


func _advance_to(stage_id: String) -> bool:
	for i in range(10):
		if _runner.current_stage_id() == stage_id:
			return true
		_runner.debug_advance_stage()
	return _runner.current_stage_id() == stage_id


func _start_nurse_gating() -> void:
	var nurse: int = _roles.NURSE
	if _hud._role_offered(nurse):
		_fail("Challenge 2 offers Nurse before 2.5")
		return
	if not _advance_to("2.5"):
		_fail("could not reach stage 2.5 (at stage %s)" % _runner.current_stage_id())
		return
	if _hud._role_offered(nurse):
		_fail("Nurse is offered at 2.5 before Nurses is bought")
		return
	if not bool(_hud.skill_tree_panel.buy_skill(_stages.NURSES_SKILL)):
		_fail("buy_skill(Nurses) returned false at 2.5")
		return
	_phase = "nurse_after_buy"


func _check_nurse_after_buy() -> void:
	if not _hud._role_offered(_roles.NURSE):
		_fail("Nurse is not offered the frame after Nurses was bought")
		return
	_phase = "done"


func _start_dwell() -> void:
	if not _advance_to("2.2"):
		_fail("could not reach stage 2.2 (at stage %s)" % _runner.current_stage_id())
		return
	var hive: Node = _main.get("hive")
	var built: Object = null
	for cell in hive.cells:
		if bool(cell.is_built):
			built = cell
			break
	if built == null:
		_fail("no built comb cell to designate for pollen")
		return
	built.set_designation("pollen", true)
	hive.deposit("nectar", 400.0)
	hive.deposit("pollen", 200.0)
	var nectar := float(hive.total("nectar"))
	var pollen := float(hive.total("pollen"))
	if nectar < 175.0 or pollen < 90.0:
		_fail("comb did not hold the reserve: nectar %.1f (need 175), pollen %.1f (need 90)" % [nectar, pollen])
		return
	_runner.debug_advance_stage()
	_dwell_start = _frame
	_phase = "dwell"


func _watch_dwell(delta: float) -> void:
	if paused:
		paused = false
		if not _logged_unpause:
			_logged_unpause = true
			_log.append("run was paused during the dwell; unpaused")
	var id: String = _runner.current_stage_id()
	_totals[id] = float(_totals.get(id, 0.0)) + delta
	if id == "2.5":
		var need: float = float(_stages.MIN_STAGE_DWELL) - 0.1
		for key in ["2.3", "2.4"]:
			_log.append("stage %s dwell %.2fs" % [key, float(_totals.get(key, 0.0))])
			if float(_totals.get(key, 0.0)) < need:
				_fail("stage %s was up for %.2fs, under %.2fs" % [key, float(_totals.get(key, 0.0)), need])
		if _failures.is_empty():
			_phase = "done"
		return
	if _frame - _dwell_start > DWELL_FRAME_LIMIT:
		_fail("stage 2.5 not reached in %d frames; totals %s" % [DWELL_FRAME_LIMIT, _totals])


func _start_escape() -> void:
	var tree_panel: Node = _hud.skill_tree_panel
	tree_panel.open()
	if not paused:
		_fail("opening the skill tree did not pause the run")
		return
	_push_key(KEY_SPACE, true)
	_push_key(KEY_SPACE, false)
	if not paused or not tree_panel.is_open():
		_fail("Space closed or unpaused the skill tree (paused %s, open %s)" % [paused, tree_panel.is_open()])
		return
	_push_key(KEY_ESCAPE, true)
	_phase = "escape_after"


func _check_escape_after() -> void:
	var tree_panel: Node = _hud.skill_tree_panel
	if tree_panel.is_open():
		_fail("Escape did not close the skill tree")
	elif paused:
		_fail("the run is still paused after Escape closed the skill tree")
	else:
		_phase = "done"


func _push_key(keycode: Key, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.keycode = keycode
	event.pressed = pressed
	root.push_input(event)


func _fail(message: String) -> void:
	_failures.append(message)
	_phase = "done"


func _report() -> void:
	for line in _log:
		print("C2CHECKS note: " + line)
	if _failures.is_empty():
		print("C2CHECKS PASS")
		quit(0)
	else:
		for line in _failures:
			print("C2CHECKS FAIL: " + line)
		quit(1)
