extends SceneTree
## SI-3 test: save, checkpoint and index writes are all-or-nothing.
##
## Statics only, no world. Works under user://si3_test/.
##
## Run by tests/test_si3_atomic_write.py:
##   godot --headless --path <repo> --script res://tests/si3_atomic_write_test.gd
## Prints "SI3 PASS" and exits 0, or prints each failure and exits 1.

# Loaded at run time: save_game.gd names the Session autoload, which a
# --script run lacks at compile time.
var SaveGame: GDScript = null
var SaveSlots: GDScript = null
const DIR := "user://si3_test/"

var _failures: PackedStringArray = PackedStringArray()


func _initialize() -> void:
	SaveGame = load("res://scripts/save_game.gd")
	SaveSlots = load("res://scripts/save_slots.gd")
	_run()
	_remove_dir()
	if _failures.is_empty():
		print("SI3 PASS")
		quit(0)
	else:
		for line in _failures:
			print("SI3 FAIL: " + line)
		quit(1)


func _check(ok: bool, what: String) -> void:
	if not ok:
		_failures.append(what)


func _put(path: String, text: String) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(text)
	f.close()


func _run() -> void:
	_remove_dir()
	DirAccess.make_dir_recursive_absolute(DIR)

	# write_atomic replaces an existing file and leaves no .tmp.
	var target := DIR + "a.json"
	_put(target, "old")
	_check(SaveSlots.write_atomic(target, "new"), "write_atomic returned false")
	_check(FileAccess.get_file_as_string(target) == "new", "target not replaced")
	_check(not FileAccess.file_exists(target + ".tmp"), ".tmp left behind")

	# SaveGame.read: target wins over a garbage .tmp.
	var save := DIR + "save.json"
	_put(save, JSON.stringify({"version": SaveGame.FORMAT_VERSION, "marker": "target"}))
	_put(save + ".tmp", "{garbage")
	_check(SaveGame.read(save).get("marker", "") == "target", "read ignored target for .tmp")
	# Only a valid .tmp.
	DirAccess.remove_absolute(save)
	_put(save + ".tmp", JSON.stringify({"version": SaveGame.FORMAT_VERSION, "marker": "tmp"}))
	_check(SaveGame.read(save).get("marker", "") == "tmp", "read did not fall back to .tmp")

	# SaveSlots._load_index_file, same two cases.
	var old_root: String = SaveSlots.root
	SaveSlots.root = DIR + "idx/"
	DirAccess.make_dir_recursive_absolute(SaveSlots.root)
	var index: String = SaveSlots.root + SaveSlots.INDEX_FILE
	_put(index, JSON.stringify({"slots": {"target": {}}}))
	_put(index + ".tmp", "{garbage")
	_check(SaveSlots._load_index_file().get("slots", {}).has("target"), "index ignored target for .tmp")
	DirAccess.remove_absolute(index)
	_put(index + ".tmp", JSON.stringify({"slots": {"tmp": {}}}))
	_check(SaveSlots._load_index_file().get("slots", {}).has("tmp"), "index did not fall back to .tmp")
	SaveSlots.root = old_root


func _remove_dir() -> void:
	_remove_tree(DIR)


func _remove_tree(dir: String) -> void:
	var d := DirAccess.open(dir)
	if d == null:
		return
	for f in d.get_files():
		d.remove(f)
	for sub in d.get_directories():
		_remove_tree(dir + sub + "/")
	DirAccess.remove_absolute(dir)
