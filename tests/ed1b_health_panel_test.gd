extends SceneTree
## ED-1b test: an ambush takes health and the selection panel shows it.
##
## Boots level 3 (comb and foragers). A worker at full health is ambushed: she
## must lose all of it and die with cause "crab spider ambush". A second worker
## at half health is selected: the energy label must show "Health 50%" beside
## her energy.
##
## Run by tests/test_ed1b_health_panel.py:
##   godot --headless --fixed-fps 60 --path <repo> --script res://tests/ed1b_health_panel_test.gd
## Prints "ED1B PASS" and exits 0, or prints each failure and exits 1.

var CrabSpider: GDScript = null

const COMB_LEVEL := 3
const BOOT_FRAMES := 10

var _main: Node = null
var _frame := 0
var _failures: PackedStringArray = PackedStringArray()


func _process(_delta: float) -> bool:
	_frame += 1
	if _frame == 1:
		_boot()
	elif _frame >= BOOT_FRAMES:
		_run()
		_report()
		return true
	return false


func _boot() -> void:
	if not root.has_node("Session") or not root.has_node("GameConfig"):
		_failures.append("the Session or GameConfig autoload is not loaded")
		return
	CrabSpider = load("res://scripts/crab_spider.gd")
	root.get_node("Session").starting_level = COMB_LEVEL
	root.get_node("Session").menu_pending = false
	_main = (load("res://scenes/Main.tscn") as PackedScene).instantiate()
	root.add_child(_main)
	current_scene = _main


func _run() -> void:
	if _main == null:
		return
	var config: Node = root.get_node("GameConfig")
	var flowers: Array = _main.get_tree().get_nodes_in_group("flowers")
	var workers: Array = []
	for bee in _main.get_tree().get_nodes_in_group("bees"):
		if not bee.is_queen and not bool(bee.is_dying):
			workers.append(bee)
	if workers.size() < 2 or flowers.is_empty():
		_failures.append("level %d has too few workers or no flower" % COMB_LEVEL)
		return
	var victim: Node2D = workers[0]
	_check(is_equal_approx(float(victim.health), float(config.health_capacity)), "the worker is not at full health")
	config.crab_spider_attack_success_chance = 2.0
	victim.current_flower = flowers[0]
	CrabSpider.resolve_attack(victim)
	_check(float(victim.health) <= 0.0, "the ambush left her health at %s" % str(victim.health))
	_check(bool(victim.is_dying), "the ambush did not kill her")
	_check(str(victim.death_cause) == "crab spider ambush", "the death cause is %s" % str(victim.death_cause))
	var patient: Node2D = workers[1]
	patient.health = float(config.health_capacity) * 0.5
	_main.hud.update_selection([patient])
	var text: String = _main.hud.energy_label.text
	_check(text.contains("Health 50%"), "the panel text is %s" % text.replace("\n", " / "))
	_check(text.find("Energy") < text.find("Health"), "health is not beside energy: %s" % text)
	_main.hud.update_selection([])


func _check(ok: bool, message: String) -> void:
	if not ok:
		_failures.append(message)


func _report() -> void:
	if _failures.is_empty():
		print("ED1B PASS")
		quit(0)
	else:
		for line in _failures:
			print("ED1B FAIL: " + line)
		quit(1)
