extends GamePanel
## The Saves window (plans/now/named-saves.md SV-2): every saved run with its
## three rolling checkpoints, each showing its day and how long ago it was
## written, with Load per row and Delete per run. It is also where a run is
## saved by name: the first save of a run asks for the name, later saves
## reuse it.
##
## The list is built when the window opens and after a save or delete.
## Nothing polls the filesystem: save_slots.gd answers from its index file.
## Created by main.gd (RR-2, before the menu returns early); opened only from the settings window's "Saves…"
## (debug_panel.gd::_on_load_pressed), in a run or on the main menu (SA-1).

const UI = preload("res://scripts/ui.gd")
const SaveSlots = preload("res://scripts/save_slots.gd")
const SaveGame = preload("res://scripts/save_game.gd")

## Whether this run has been saved by name yet. Static so it survives the
## scene reload a load performs (a loaded run already has its name); a new
## run clears it through Session.run_reset.
static var _run_named: bool = false

var list_box: VBoxContainer
var name_row: VBoxContainer
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

	name_row = VBoxContainer.new()
	name_row.visible = false
	column.add_child(name_row)
	var prompt := Label.new()
	prompt.text = "Name this run:"
	prompt.theme_type_variation = "Body"
	name_row.add_child(prompt)
	var edit_row := HBoxContainer.new()
	name_row.add_child(edit_row)
	name_edit = LineEdit.new()
	name_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_edit.custom_minimum_size = Vector2(240, 0)
	name_edit.max_length = 40
	name_edit.text_submitted.connect(func(_text): _on_name_confirmed())
	edit_row.add_child(name_edit)
	var confirm_btn := _button("Save")
	confirm_btn.pressed.connect(_on_name_confirmed)
	edit_row.add_child(confirm_btn)

	column.add_child(HSeparator.new())
	list_box = VBoxContainer.new()
	list_box.add_theme_constant_override("separation", 4)
	column.add_child(list_box)

	Session.run_reset.connect(_on_run_reset)
	get_viewport().size_changed.connect(_apply_left_window_rect)
	connect_hud_reflow()

## main.gd builds this window before the hud exists (RR-2), so the hud
## signals are joined here when it is there and by hud.gd::_ready otherwise.
func connect_hud_reflow() -> void:
	if main.hud == null or main.hud.bottom_row_changed.is_connected(_on_bottom_row_changed):
		return
	# Not the corner readout's height, as game_panel.gd explains.
	main.hud.bottom_row_changed.connect(_on_bottom_row_changed)

## With no hud (the menu at boot) there is no corner readout or bottom row
## to avoid, so the window takes the full height below the top margin.
func _apply_left_window_rect() -> void:
	if main.hud != null:
		super._apply_left_window_rect()
		return
	var rect := UiLayout.left_window_rect(
		get_viewport().get_visible_rect().size, panel.custom_minimum_size.x, 0.0, 0.0
	)
	panel.offset_top = rect.position.y
	UiPanelLayout.apply(panel, scroll_container, rect)

## A warning through the hud, or the log when there is no hud yet (RR-2).
func _warn(text: String) -> void:
	if main.hud == null:
		push_warning(text)
		return
	main.hud.show_warning(text)

## The hud's confirmation dialog. With no hud (the menu at boot) the window
## asks through a plain ConfirmationDialog of its own, so Delete still works (RR-2).
func _confirm(title: String, text: String, ok_text: String, cancel_text: String, action: Callable, offer_stop_warning: bool = true) -> void:
	if main.hud != null:
		main.hud.confirm_discard(title, text, ok_text, cancel_text, action, offer_stop_warning)
		return
	var dialog := ConfirmationDialog.new()
	dialog.title = title
	dialog.dialog_text = text
	dialog.ok_button_text = ok_text
	dialog.cancel_button_text = cancel_text
	dialog.confirmed.connect(action)
	dialog.canceled.connect(dialog.queue_free)
	dialog.confirmed.connect(dialog.queue_free)
	add_child(dialog)
	dialog.popup_centered()

## Over the main menu the window takes the settings window's own
## over-the-menu layer (debug_panel.gd::_apply_layer_for_context), since the
## menu's CanvasLayer (20) would otherwise hide it; in a run it sits at the
## ordinary GamePanel layer.
func open() -> void:
	name_row.visible = false
	_apply_menu_context()
	_rebuild()
	super.open()

## The window can be left open in a run while the player returns to the main
## menu, so open() does not run again; the menu's visibility drives this too.
func _apply_menu_context() -> void:
	var menus := get_tree().get_nodes_in_group("main_menu")
	var menu_visible: bool = not menus.is_empty() and menus[0].visible
	layer = 21 if menu_visible else 11
	save_run_btn.visible = not menu_visible
	if menu_visible:
		name_row.visible = false
	if not menus.is_empty() and not menus[0].visibility_changed.is_connected(_apply_menu_context):
		menus[0].visibility_changed.connect(_apply_menu_context)

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
		_confirm(
			"Replace the saved run",
			"There is already a saved run called \"%s\". Saving under that name replaces it." % run_name,
			"Replace it", "Keep the old one", func(): _save(run_name))
		return
	_save(run_name)

func _save(run_name: String) -> void:
	if main.saving == null:
		push_warning("There is no run to save")
		return
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
	if not reload_from(get_tree(), path, display_name):
		_warn("That save could not be read — check the log for why.")

## The reload itself, static so the game-over screen's "Load the latest
## checkpoint" runs the very same path. False if the file could not be read.
static func reload_from(tree: SceneTree, path: String, display_name: String) -> bool:
	var data := SaveGame.read(path)
	if data.is_empty():
		return false
	SaveGame.apply_settings(data)
	SaveGame.apply_starting_level(data)
	SaveGame.apply_skill_policy(data)
	Session.run_name = display_name
	Session.load_path = path
	Session.load_pending = true
	Session.menu_pending = false
	_run_named = true
	tree.paused = false
	Engine.time_scale = 1.0
	tree.reload_current_scene()
	return true

## Always asks, whatever warn_on_discard says (SA-1): a deleted run cannot
## be recovered, so the confirmation offers no "stop warning me".
func _on_delete_pressed(slug: String, display_name: String) -> void:
	_confirm(
		"Delete this run",
		"Delete \"%s\" and its checkpoints? This cannot be undone." % display_name,
		"Delete it", "Keep it", func(): _delete(slug), false)

func _delete(slug: String) -> void:
	SaveSlots.delete(slug)
	_rebuild()

# --- helpers --------------------------------------------------------

func _day_text(day: int) -> String:
	return "day %d" % day if day >= 0 else "day unknown"

func _age_text(seconds: int) -> String:
	if seconds < 60:
		return "just now"
	if seconds < 3600:
		return "%d min ago" % int(seconds / 60.0)
	if seconds < 86400:
		return "%d h ago" % int(seconds / 3600.0)
	return "%d days ago" % int(seconds / 86400.0)

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
