extends SceneTree
## T2-2 test: Automation gates the Miner's automine mode and the comb
## workers' outward building, and nothing marked. Run by
## tests/test_t2_2_automation_gate.py:
##   godot --headless --path <repo> --script res://tests/t2_2_automation_gate_test.gd
## Prints "T2_2 PASS" and exits 0, or each "T2_2 FAIL" line and exits 1.

const AUTOMATION := "skill.hive_mind.automation"
const COMB := "skill.colony.comb_worker"
const MINER := "skill.colony.miner"


class Owned:
	var ids: Array = []
	func is_owned(skill_id: String) -> bool:
		return skill_id in ids


func _initialize() -> void:
	var availability: GDScript = load("res://scripts/availability.gd")
	var roles: GDScript = load("res://scripts/roles.gd")
	var failures: PackedStringArray = PackedStringArray()
	var without := Owned.new()
	without.ids = [COMB, MINER]
	var with := Owned.new()
	with.ids = [COMB, MINER, AUTOMATION]

	_expect(failures, not availability.mode_query(roles.MINER, "automine", null, without).available, "automine refused without Automation")
	_expect(failures, availability.mode_query(roles.MINER, "automine", null, with).available, "automine allowed with Automation")
	_expect(failures, not availability.action_query("mine_automine_block", null, null, without).available, "automine row refused without Automation")
	_expect(failures, availability.action_query("mine_automine_block", null, null, with).available, "automine row allowed with Automation")
	_expect(failures, not availability.action_query("comb_build_outward", null, null, without).available, "outward building refused without Automation")
	_expect(failures, availability.action_query("comb_build_outward", null, null, with).available, "outward building allowed with Automation")
	for marked in ["comb_build", "mine_marked_block", "mine_queued_block"]:
		_expect(failures, availability.action_query(marked, null, null, without).available, "%s needs no Automation" % marked)

	if failures.is_empty():
		print("T2_2 PASS")
		quit(0)
	else:
		for f in failures:
			print("T2_2 FAIL ", f)
		quit(1)


func _expect(failures: PackedStringArray, ok: bool, what: String) -> void:
	if not ok:
		failures.append(what)
