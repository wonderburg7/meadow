extends SceneTree
## PN-2 test: SaveSlots.rename changes the index name only.
##
## Statics only, no world. Works under user://pn2_test/.
##
## Run by tests/test_pn2_save_rename.py:
##   godot --headless --path <repo> --script res://tests/pn2_save_rename_test.gd
## Prints "PN2 PASS" and exits 0, or prints each failure and exits 1.

var SaveSlots: GDScript = null
const DIR := "user://pn2_test/"

var _failures: PackedStringArray = PackedStringArray()


func _initialize() -> void:
	SaveSlots = load("res://scripts/save_slots.gd")
	_run()
	_remove_dir()
	if _failures.is_empty():
		print("PN2 PASS")
		quit(0)
	else:
		for line in _failures:
			print("PN2 FAIL: " + line)
		quit(1)


func _check(ok: bool, what: String) -> void:
	if not ok:
		_failures.append(what)


func _name_of(slug: String) -> String:
	for slot: Dictionary in SaveSlots.list_slots():
		if slot["slug"] == slug:
			return str(slot["name"])
	return "<missing>"


func _run() -> void:
	_remove_dir()
	DirAccess.make_dir_recursive_absolute(DIR)
	SaveSlots.root = DIR
	SaveSlots._prepared_root = ""

	var f := FileAccess.open(SaveSlots.slot_path("alpha"), FileAccess.WRITE)
	f.store_string("{\"marker\": 1}")
	f.close()
	SaveSlots.record_save("alpha", "Alpha", 7)
	SaveSlots.record_save("beta", "Beta", 3)

	_check(SaveSlots.rename("alpha", "Meadow One") == "", "valid rename refused")
	_check(_name_of("alpha") == "Meadow One", "name not updated")
	_check(FileAccess.get_file_as_string(SaveSlots.slot_path("alpha")) == "{\"marker\": 1}", "save file touched")
	var kept: Dictionary = {}
	for slot: Dictionary in SaveSlots.list_slots():
		if slot["slug"] == "alpha":
			kept = slot
	_check(int(kept.get("day", -1)) == 7, "day changed")
	_check(not FileAccess.file_exists(SaveSlots.root + "index.json.tmp"), ".tmp left behind")

	# Survives a reload of the index from disk.
	SaveSlots._prepared_root = ""
	_check(_name_of("alpha") == "Meadow One", "name lost on reload")

	_check(SaveSlots.rename("alpha", "   ") != "", "empty name accepted")
	_check(SaveSlots.rename("alpha", "beta") != "", "duplicate name accepted")
	_check(SaveSlots.rename("alpha", "BETA!") != "", "duplicate slug accepted")
	_check(_name_of("alpha") == "Meadow One", "refused rename changed the name")
	_check(SaveSlots.rename("alpha", "MEADOW ONE") == "", "case change of own name refused")
	_check(SaveSlots.rename("gone", "Anything") != "", "missing slot accepted")


func _remove_dir() -> void:
	if DirAccess.dir_exists_absolute(DIR):
		for file_name: String in DirAccess.get_files_at(DIR):
			DirAccess.remove_absolute(DIR + file_name)
		DirAccess.remove_absolute(DIR)
