extends GamePanel
## The Saves window (plans/now/named-saves.md SV-2): every saved run with its
## three rolling checkpoints, each showing its day and how long ago it was
## written, with Load per row and Delete per run. It is also where a run is
## saved by name: the first save of a run asks for the name, later saves
## reuse it.
##
## The list is built when the window opens and after a save or delete.
## Nothing polls the filesystem: save_slots.gd answers from its index file.
## Created by hud.gd; opened only from the settings window's "Saves…"
## (debug_panel.gd::_on_load_pressed), in a run or on the main menu (SA-1).

const UI = preload("res://scripts/ui.gd")
const SaveSlots = preload("res://scripts/save_slots.gd")
const SaveGame = preload("res://scripts/save_game.gd")

## Whether this run has been saved by name yet. Static so it survives the
## scene reload a load performs (a loaded run already has its name); a new
## run clears it through Session.run_reset.
static var _run_named: bool = false

var list_box: VBoxContainer
var name_row: HBoxContainer
var name_edit: LineEdit
## Hidden on the main menu, where there is no run of the player's to save.
var save_run_btn: Button

func _ready() -> void:
	setup_layer("saves", "saves_panel")
	build_left_window(360)
	build_scroll_body()

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 6)
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll_container.add_child(column)

	var header := HBoxContainer.new()
	column.add_child(header)
	var title := Label.new()
	title.text = "Saves"
	title.theme_type_variation = "Heading"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	header.add_child(UI.info_badge(
		"Every run you have saved, newest first. Under each are its automatic checkpoints: the game quietly saves one every few days and keeps the last three, so a bad turn never costs you more than a few days. Loading a checkpoint never touches your own save."
	))
	var close_btn := _button("×")
	close_btn.custom_minimum_size = Vector2(26, 22)
	close_btn.pressed.connect(func(): close())
	header.add_child(close_btn)

	save_run_btn = _button("Save this run")
	save_run_btn.pressed.connect(_on_save_pressed)
	column.add_child(save_run_btn)

	name_row = HBoxContainer.new()
	name_row.visible = false
	column.add_child(name_row)
	var prompt := Label.new()
	prompt.text = "Name this run:"
	prompt.theme_type_variation = "Body"
	name_row.add_child(prompt)
	name_edit = LineEdit.new()
	name_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_edit.max_length = 40
	name_edit.text_submitted.connect(func(_text): _on_name_confirmed())
	name_row.add_child(name_edit)
	var confirm_btn := _button("Save")
	confirm_btn.pressed.connect(_on_name_confirmed)
	name_row.add_child(confirm_btn)

	column.add_child(HSeparator.new())
	list_box = VBoxContainer.new()
	list_box.add_theme_constant_override("separation", 4)
	column.add_child(list_box)

	Session.run_reset.connect(_on_run_reset)
	connect_left_window_reflow()

## Over the main menu the window takes the settings window's own
## over-the-menu layer (debug_panel.gd::_apply_layer_for_context), since the
## menu's CanvasLayer (20) would otherwise hide it; in a run it sits at the
## ordinary GamePanel layer.
func open() -> void:
	var menus := get_tree().get_nodes_in_group("main_menu")
	var menu_visible: bool = not menus.is_empty() and menus[0].visible
	layer = 21 if menu_visible else 11
	save_run_btn.visible = not menu_visible
	name_row.visible = false
	_rebuild()
	super.open()

func _on_run_reset() -> void:
	_run_named = false

# --- saving ---------------------------------------------------------

func _on_save_pressed() -> void:
	if _run_named:
		_save(Session.run_name)
		return
	name_edit.text = Session.run_name
	name_row.visible = true
	name_edit.grab_focus()
	name_edit.select_all()

func _on_name_confirmed() -> void:
	var run_name := name_edit.text.strip_edges()
	if run_name == "":
		run_name = Session.run_name
	name_row.visible = false
	var slug := SaveSlots.slugify(run_name)
	var taken := false
	for entry in SaveSlots.list_slots():
		if entry["slug"] == slug and int(entry.get("saved_at", 0)) > 0:
			taken = true
	if taken and Session.warn_on_discard:
		main.hud.confirm_discard(
			"Replace the saved run",
			"There is already a saved run called \"%s\". Saving under that name replaces it." % run_name,
			"Replace it", "Keep the old one", func(): _save(run_name))
		return
	_save(run_name)

func _save(run_name: String) -> void:
	main.saving.save_run(run_name)
	_run_named = true
	_rebuild()

# --- the list -------------------------------------------------------

func _rebuild() -> void:
	for child in list_box.get_children():
		child.queue_free()
	var slots: Array = SaveSlots.list_slots()
	if slots.is_empty():
		list_box.add_child(_label("No saved runs yet.", "Small"))
		return
	var now := int(Time.get_unix_time_from_system())
	for entry in slots:
		var slug: String = entry["slug"]
		var display_name: String = str(entry.get("name", slug))
		var row := HBoxContainer.new()
		list_box.add_child(row)
		var saved_at := int(entry.get("saved_at", 0))
		var named := saved_at > 0 and FileAccess.file_exists(SaveSlots.slot_path(slug))
		var text := display_name
		if named:
			text += " — %s, %s" % [_day_text(int(entry.get("day", -1))), _age_text(now - saved_at)]
		else:
			text += " — not saved by hand yet"
		var label := _label(text, "Body")
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(label)
		if named:
			var load_btn := _button("Load")
			load_btn.pressed.connect(func(): _load(SaveSlots.slot_path(slug), display_name))
			row.add_child(load_btn)
		var delete_btn := _button("Delete")
		delete_btn.pressed.connect(func(): _on_delete_pressed(slug, display_name))
		row.add_child(delete_btn)

		var checkpoints: Dictionary = entry.get("checkpoints", {})
		var numbers: Array = checkpoints.keys()
		# Newest checkpoint first, the same order as the runs above.
		numbers.sort_custom(func(a, b): return int(checkpoints[a].get("saved_at", 0)) > int(checkpoints[b].get("saved_at", 0)))
		for number in numbers:
			var path := SaveSlots.checkpoint_path(slug, int(number))
			if not FileAccess.file_exists(path):
				continue
			var point: Dictionary = checkpoints[number]
			var point_row := HBoxContainer.new()
			list_box.add_child(point_row)
			var point_label := _label("    Checkpoint — %s, %s" % [
				_day_text(int(point.get("day", -1))), _age_text(now - int(point.get("saved_at", 0)))], "Small")
			point_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			point_row.add_child(point_label)
			var point_load := _button("Load")
			point_load.pressed.connect(func(): _load(path, display_name))
			point_row.add_child(point_load)

## The same reload the cog's Load run performs: the saved tuning values
## decide the hive's shape, so the world is rebuilt with them first.
func _load(path: String, display_name: String) -> void:
	var data := SaveGame.read(path)
	if data.is_empty():
		main.hud.show_warning("That save could not be read — check the log for why.")
		return
	SaveGame.apply_settings(data)
	Session.run_name = display_name
	Session.load_path = path
	Session.load_pending = true
	Session.menu_pending = false
	_run_named = true
	get_tree().paused = false
	Engine.time_scale = 1.0
	get_tree().reload_current_scene()

## Always asks, whatever warn_on_discard says (SA-1): a deleted run cannot
## be recovered, so the confirmation offers no "stop warning me".
func _on_delete_pressed(slug: String, display_name: String) -> void:
	main.hud.confirm_discard(
		"Delete this run",
		"Delete \"%s\" and its checkpoints? This cannot be undone." % display_name,
		"Delete it", "Keep it", func(): _delete(slug), false)

func _delete(slug: String) -> void:
	SaveSlots.delete(slug)
	_rebuild()

# --- helpers --------------------------------------------------------

func _day_text(day: int) -> String:
	return "day %d" % day if day >= 0 else "day unknown"

@warning_ignore("integer_division")
func _age_text(seconds: int) -> String:
	if seconds < 60:
		return "just now"
	if seconds < 3600:
		return "%d min ago" % (seconds / 60)
	if seconds < 86400:
		return "%d h ago" % (seconds / 3600)
	return "%d days ago" % (seconds / 86400)

func _label(text: String, variation: String) -> Label:
	var label := Label.new()
	label.text = text
	label.theme_type_variation = variation
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size = Vector2(180, 0)
	return label

func _button(text: String) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.focus_mode = Control.FOCUS_NONE
	for state in ["normal", "hover", "pressed", "focus", "disabled"]:
		btn.add_theme_stylebox_override(state, UiTheme.button_stylebox(state))
	return btn
