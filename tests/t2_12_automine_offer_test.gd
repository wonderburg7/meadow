extends SceneTree
## T2-12 test: "Dig on its own" is offered only once Automation is owned.
## Without Automation a selected miner's Job panel has no "Dig on its own"
## toggle, and a cell's Raises menu has no "Miner — Dig on its own" entry.
## With Automation owned both are offered. Run by
## tests/test_t2_12_automine_offer.py:
##   godot --headless --path <repo> --script res://tests/t2_12_automine_offer_test.gd
## Prints "T2_12 PASS" and exits 0, or each "T2_12 FAIL" line and exits 1.

const AUTOMATION := "skill.hive_mind.automation"
const DIG_TOGGLE := "Dig on its own"
const DIG_RAISE := "Miner — Dig on its own"


class Owned:
	var ids: Array = []
	func is_owned(skill_id: String) -> bool:
		return skill_id in ids


class FakeMiner:
	var automine := false
	var is_queen := false
	var is_mated := false


func _initialize() -> void:
	var hud_script: GDScript = load("res://scripts/hud.gd")
	var roles: GDScript = load("res://scripts/roles.gd")
	var session: Node = root.get_node("Session")
	var failures: PackedStringArray = PackedStringArray()

	for case in [["without", []], ["with", [AUTOMATION]]]:
		var label: String = case[0]
		var owned := Owned.new()
		owned.ids = case[1]
		session.progression = owned

		var hud = hud_script.new()
		hud.focus_column = VBoxContainer.new()
		hud._command_rows._build_doing_row(roles.MINER, FakeMiner.new())
		var job_labels: Array = _button_texts(hud.focus_column, [])
		_expect(failures, (DIG_TOGGLE in job_labels) == (label == "with"),
			"%s Automation: Job panel toggle shown is %s (buttons: %s)" % [label, DIG_TOGGLE in job_labels, str(job_labels)])

		var miner_entry: Dictionary = {}
		for entry in hud_script.hatch_options():
			if entry.role == roles.MINER:
				miner_entry = entry
		var popup := PopupMenu.new()
		hud._fill_hatch_menu(popup, roles.MINER, miner_entry.options)
		var raise_labels: Array = []
		for i in range(popup.item_count):
			raise_labels.append(popup.get_item_text(i))
		_expect(failures, (DIG_RAISE in raise_labels) == (label == "with"),
			"%s Automation: Raises menu offers %s (items: %s)" % [label, DIG_RAISE, str(raise_labels)])
		_expect(failures, "Miner — only where told" in raise_labels,
			"%s Automation: the Miner's plain option is still offered" % label)
		hud.free()

	session.progression = null
	if failures.is_empty():
		print("T2_12 PASS")
		quit(0)
	else:
		for f in failures:
			print("T2_12 FAIL ", f)
		quit(1)


func _button_texts(node: Node, out: Array) -> Array:
	if node is Button:
		out.append((node as Button).text)
	for child in node.get_children():
		_button_texts(child, out)
	return out


func _expect(failures: PackedStringArray, ok: bool, what: String) -> void:
	if not ok:
		failures.append(what)
