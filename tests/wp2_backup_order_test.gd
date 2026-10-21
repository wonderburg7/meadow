extends SceneTree
## WP-2 test: once the colony owns Work priorities, an idle bee walks its
## ordered list of backup jobs; without it, it keeps its one backup.
##
## Boots the real Main.tscn into level 3, a Scenario level with comb, where
## Work priorities is not owned at the start. Every bee is stopped, the comb
## is emptied (so a nurse has no brood to tend), and each case spawns one
## test Miner with automine off and nothing marked, so her own role has no
## work. Each case puts her in her idle state and lets the world run:
##
## - Unowned, backup Nurse: she stays idle -- even with a list forced onto
##   her that has Forager next, as no unowned run can give her.
## - Unowned, backup Forager: she takes up foraging, as today.
## - Owned (granted as the scenario action grant_skill does), list Nurse
##   then Forager set through orders_zones.gd's handler: Nurse has nothing,
##   so she takes up foraging, and secondary_role mirrors it.
## - A bee that existed before the purchase gets her backup first, then the
##   colony default; a bee born after it takes the colony default.
## - The lists and the default survive SaveGame.save, SaveGame.read and
##   saving.gd::_restore; a save without them loads the default order and
##   each bee with her backup first.
##
## Run by tests/test_wp2_backup_order.py:
##   godot --headless --fixed-fps 60 --path <repo> --script res://tests/wp2_backup_order_test.gd -- --wp2-save=<file>
## Prints "WP2 PASS" and exits 0, or prints each failure and exits 1.

const LEVEL := 3              # a Scenario level with comb: no Challenge branches
const BOOT_FRAMES := 10       # let Main._ready build the world first
const SPEED := 4.0
const WATCH_FRAMES := 240
const WORK_PRIORITIES := "skill.hive_mind.work_priorities"

## Each case: whether the colony owns Work priorities, the bee's single
## backup, the list forced onto her (unowned) or sent through the handler
## (owned), and whether she should end up foraging.
const CASES := [
	{"name": "unowned, backup Nurse", "owned": false, "backup": "nurse", "forced": ["nurse", "forager"], "forages": false},
	{"name": "unowned, backup Forager", "owned": false, "backup": "forager", "forced": [], "forages": true},
	{"name": "owned, list Nurse then Forager", "owned": true, "backup": "nurse", "list": ["nurse", "forager"], "forages": true},
	{"name": "owned, list Nurse only", "owned": true, "backup": "nurse", "list": ["nurse"], "forages": false},
]

var Roles: GDScript
var _main: Node = null
var _session: Node = null
var _frame := 0
var _phase := "boot"
var _phase_frame := 0
var _case := -1
var _bee: Node2D = null
var _before_purchase: Node2D = null
var _save_path := ""
var _failures: PackedStringArray = PackedStringArray()


func _process(_delta: float) -> bool:
	_frame += 1
	match _phase:
		"boot":
			_boot()
		"settle":
			if _frame >= BOOT_FRAMES:
				_set_up()
		"watch":
			if _frame - _phase_frame >= WATCH_FRAMES:
				_judge()
	if _phase == "done":
		_report()
		return true
	return false


# Autoloads are reached through the tree: a --script run compiles this file
# before they exist.
func _boot() -> void:
	if not root.has_node("Session"):
		_fail("the Session autoload is not loaded")
		return
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--wp2-save="):
			_save_path = arg.trim_prefix("--wp2-save=")
	if _save_path == "":
		_fail("no --wp2-save=<file> given")
		return
	_session = root.get_node("Session")
	Roles = load("res://scripts/roles.gd")
	_session.starting_level = LEVEL
	_session.menu_pending = false
	var scene: PackedScene = load("res://scenes/Main.tscn")
	_main = scene.instantiate()
	root.add_child(_main)
	current_scene = _main
	_phase = "settle"


func _set_up() -> void:
	if _session.progression == null:
		_fail("level %d has no progression" % LEVEL)
		return
	if _session.progression.is_owned(WORK_PRIORITIES):
		_fail("Work priorities is owned at the start of level %d" % LEVEL)
		return
	# The jobs the cases use must be ones this run may give.
	for role_id: int in [Roles.MINER, Roles.NURSE, Roles.FORAGER]:
		var skill: String = Roles.skill_for(role_id)
		if skill != "" and not _session.progression.is_owned(skill):
			_session.progression.grant_temporary(skill)
	_main.Availability.invalidate()
	for bee: Node in _main.get_tree().get_nodes_in_group("bees"):
		bee.process_mode = Node.PROCESS_MODE_DISABLED
	# An empty comb: no brood for a nurse, nothing for anyone to fetch.
	for cell: Variant in _main.hive.cells:
		if is_instance_valid(cell) and cell.content_type != "":
			cell.clear_cell()
	# Born before the purchase, with a Nurse backup: checked once it is made.
	_before_purchase = _spawn("nurse")
	_before_purchase.process_mode = Node.PROCESS_MODE_DISABLED
	_check(_before_purchase.backup_order.is_empty(), "a bee born before the purchase has a list")
	Engine.time_scale = SPEED
	_next_case()


func _spawn(backup_key: String) -> Node2D:
	var bee: Node2D = _main.world_building._spawn_indoor_bee(_main.Bee.Role.MINER)
	bee.energy_immune = true
	bee.automine = false
	bee.set_secondary_role(Roles.id_for_key(backup_key))
	return bee


func _keys_to_ids(keys: Array) -> Array:
	return keys.map(func(k: Variant) -> int: return Roles.id_for_key(str(k)))


func _next_case() -> void:
	if _bee != null and is_instance_valid(_bee):
		_bee.process_mode = Node.PROCESS_MODE_DISABLED
	_case += 1
	if _case >= CASES.size():
		Engine.time_scale = 1.0
		_check_save_and_restore()
		_phase = "done"
		return
	var spec: Dictionary = CASES[_case]
	if spec.owned and not _session.progression.is_owned(WORK_PRIORITIES):
		_session.progression.grant_temporary(WORK_PRIORITIES)
		_main.Availability.invalidate()
		_check_purchase()
	_check(_main.Bee.work_priorities_owned() == spec.owned,
		"%s: work_priorities_owned() is %s" % [spec.name, _main.Bee.work_priorities_owned()])
	_bee = _spawn(spec.backup)
	_check(_bee.secondary_role == Roles.id_for_key(spec.backup), "%s: the backup did not take" % spec.name)
	if spec.owned:
		_main.selected_bees.clear()
		_main.selected_bees.append(_bee)
		_main.orders_zones._on_backup_order_requested(spec.list)
		_main.selected_bees.clear()
		_check(_bee.backup_order == _keys_to_ids(spec.list),
			"%s: the handler set %s, not %s" % [spec.name, _bee.backup_order, _keys_to_ids(spec.list)])
	else:
		_main.selected_bees.clear()
		_main.selected_bees.append(_bee)
		_main.orders_zones._on_backup_order_requested(spec.forced)
		_main.selected_bees.clear()
		_check(_bee.backup_order.is_empty(), "%s: the handler set a list without the skill" % spec.name)
		_bee.backup_order = _keys_to_ids(spec.forced)   # as nothing in an unowned run could
	_bee.state = _main.Bee.State.MINE_IDLE
	_phase = "watch"
	_phase_frame = _frame


func _judge() -> void:
	var spec: Dictionary = CASES[_case]
	var foraging: bool = _bee.working_secondary and _bee.current_working_role() == Roles.FORAGER
	if spec.forages:
		_check(foraging, "%s: she did not take up foraging (state %d, working_secondary %s, secondary %d)" % [
			spec.name, _bee.state, _bee.working_secondary, _bee.secondary_role])
		_check(not _bee.is_waiting_for_work(), "%s: she is still waiting for work" % spec.name)
		if spec.owned:
			_check(_bee.secondary_role == Roles.FORAGER, "%s: secondary_role does not mirror the job taken" % spec.name)
	else:
		_check(not _bee.working_secondary, "%s: she took up a backup job (secondary %d)" % [spec.name, _bee.secondary_role])
		_check(_bee.has_no_available_work(), "%s: she is not idle with no work (state %d)" % [spec.name, _bee.state])
		_check(_bee.secondary_role == Roles.NURSE, "%s: her backup changed to %d" % [spec.name, _bee.secondary_role])
	_check(_bee.role == Roles.MINER, "%s: her own role changed" % spec.name)
	print("WP2 %s: she %s" % [spec.name, "took up foraging" if foraging else "stayed idle"])
	_next_case()


## On purchase: a bee already living has her backup first, then the colony
## default; one born afterwards takes the default, whatever it is now.
func _check_purchase() -> void:
	var default_order: Array = _session.DEFAULT_BACKUP_ORDER
	_check(_session.backup_order_default == default_order, "the colony default is not decision 3's order")
	var expected: Array = [Roles.NURSE]
	for role_id: Variant in default_order:
		if role_id != Roles.NURSE:
			expected.append(role_id)
	var seeded: Array = _before_purchase.backup_list()
	_check(seeded == expected, "a bee born before the purchase got %s, not %s" % [seeded, expected])
	var newborn: Node2D = _main.world_building._spawn_indoor_bee(_main.Bee.Role.FORAGER)
	newborn.process_mode = Node.PROCESS_MODE_DISABLED
	_check(newborn.backup_order == default_order, "a bee born after the purchase got %s" % [newborn.backup_order])
	var custom: Array = [Roles.FORAGER, Roles.MINER, Roles.NURSE]
	_session.set_backup_order_default(custom)
	var second: Node2D = _main.world_building._spawn_indoor_bee(_main.Bee.Role.FORAGER)
	second.process_mode = Node.PROCESS_MODE_DISABLED
	_check(second.backup_order == custom, "a bee born after the default changed got %s" % [second.backup_order])
	_session.set_backup_order_default(default_order)
	print("WP2 purchase: the living bee has her backup first; a newborn takes the colony default")


func _check_save_and_restore() -> void:
	var custom_default: Array = [Roles.NURSE, Roles.FORAGER, Roles.COMB_WORKER]
	var custom_list: Array = [Roles.FORAGER, Roles.COMB_WORKER, Roles.NURSE]
	_session.set_backup_order_default(custom_default)
	_bee.set_backup_order(custom_list)
	var bee_id: int = _bee.bee_id
	var other_id: int = _before_purchase.bee_id
	var other_list: Array = _before_purchase.backup_order.duplicate()
	if not _main.SaveGame.save(_main, _save_path):
		_fail("SaveGame.save failed")
		return
	var data: Dictionary = _main.SaveGame.read(_save_path)
	if data.is_empty():
		_fail("SaveGame.read could not read the save back")
		return
	_session.set_backup_order_default(_session.DEFAULT_BACKUP_ORDER)

	_main.saving._restore(data.duplicate(true))
	_check(_session.backup_order_default == custom_default,
		"the colony default restored as %s, not %s" % [_session.backup_order_default, custom_default])
	var restored: Node2D = _bee_with_id(bee_id)
	_check(restored != null and restored.backup_order == custom_list,
		"the bee's list restored as %s, not %s" % [restored.backup_order if restored != null else "nothing", custom_list])
	var other: Node2D = _bee_with_id(other_id)
	_check(other != null and other.backup_order == other_list, "a second bee's list did not survive restore")
	_check(_session.progression.is_owned(WORK_PRIORITIES), "Work priorities did not survive restore")
	print("WP2 the lists and the colony default survive save and restore")

	# A save from before WP-2 has neither key: the default is decision 3's,
	# and each bee's list, once read, has her backup first.
	var old: Dictionary = data.duplicate(true)
	old.get("session", {}).erase("backup_order_default")
	for entry: Variant in old.get("bees", []):
		entry.erase("backup_order")
	_main.saving._restore(old)
	_check(_session.backup_order_default == _session.DEFAULT_BACKUP_ORDER,
		"an old save loaded the colony default %s" % [_session.backup_order_default])
	var checked := 0
	for bee: Node in _main.get_tree().get_nodes_in_group("bees"):
		if bee.is_queued_for_deletion() or bee.is_queen or bee.is_drone:
			continue
		var backup: int = bee.secondary_role
		var order: Array = bee.backup_list()
		var expected: Array = [backup] if backup != -1 else []
		for role_id: Variant in _session.DEFAULT_BACKUP_ORDER:
			if role_id != backup:
				expected.append(role_id)
		_check(order == expected, "an old save loaded bee %d with %s, not %s" % [bee.bee_id, order, expected])
		checked += 1
	_check(checked > 0, "an old save restored no workers to check")
	var with_nurse: Node2D = _bee_with_id(other_id)
	_check(with_nurse != null and with_nurse.backup_list().front() == Roles.NURSE,
		"an old save did not put the Nurse backup first")
	print("WP2 an old save loads the default order and each bee with her backup first")


func _bee_with_id(id: int) -> Node2D:
	for bee: Node in _main.get_tree().get_nodes_in_group("bees"):
		if is_instance_valid(bee) and not bee.is_queued_for_deletion() and bee.bee_id == id:
			return bee
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
		print("WP2 PASS")
		quit(0)
	else:
		for line: String in _failures:
			print("WP2 FAIL: " + line)
		quit(1)
