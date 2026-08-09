extends CanvasLayer
## Top-left readouts (day, stores, bee count), the view switcher, the
## game-speed controls, the panel that appears when bees are selected,
## and the popup for inspecting a single comb cell.
##
## Every control carries a small "i" badge whose tooltip explains what
## it does -- see `_info()`. Kept separate from main.gd so the
## simulation wiring stays readable.

const UI = preload("res://scripts/ui.gd")

signal focus_requested(type: String)
signal role_requested(role_name: String)
signal view_toggle_requested()
signal speed_requested(speed_scale: float)
signal cell_designation_requested(cell: Node2D, type: String)

const SPEEDS := [
	{"label": "II", "scale": 0.0, "tip": "Pause. The whole colony freezes; you can still look around and give orders."},
	{"label": "0.5x", "scale": 0.5, "tip": "Half speed. Useful for watching a single bee's decisions closely."},
	{"label": "1x", "scale": 1.0, "tip": "Normal speed."},
	{"label": "2x", "scale": 2.0, "tip": "Double speed. Good for waiting out brood development or comb building."},
	{"label": "4x", "scale": 4.0, "tip": "Quadruple speed. Fastest way to reach the next day."},
]

const ROLE_BUTTONS := [
	{
		"label": "Forager", "role": "forager",
		"tip": "Send the selected bees out to the meadow to gather nectar or pollen and carry it back into the comb.",
	},
	{
		"label": "Nursery", "role": "nursery",
		"tip": "Keep the selected bees indoors to carry newly laid eggs into empty cells and tend developing brood, which speeds up how fast they grow.",
	},
	{
		"label": "Builder", "role": "builder",
		"tip": "Set the selected bees to draw new comb cells and to shift stores out of any cell you have re-designated. Building burns extra energy, because bees make wax from the sugar they have eaten.",
	},
	{
		"label": "Egg layer", "role": "egg_layer",
		"tip": "Queen only. She eats pollen from the comb and lays eggs on the hive floor for nursery bees to collect. Other bees ignore this button.",
	},
]

var day_label: Label
var storage_label: Label
var population_label: Label
var pause_label: Label
var view_button: Button
var selection_panel: PanelContainer
var selection_label: Label
var speed_buttons: Array = []

var cell_popup: PopupPanel
var cell_popup_label: Label
var active_cell: Node2D = null

var discard_dialog: ConfirmationDialog
var pending_cell: Node2D = null
var pending_type: String = ""

func _ready() -> void:
	process_mode = PROCESS_MODE_ALWAYS
	layer = 9

	day_label = _make_label(Vector2(16, 12), 22)
	storage_label = _make_label(Vector2(16, 42), 18)
	population_label = _make_label(Vector2(16, 66), 14)

	var hint := _make_label(Vector2(16, 88), 12)
	hint.text = "Arrows = pan · wheel = zoom · Tab = switch view · Space = pause\nClick or drag to select bees · right-click a flower to send them · right-click ground to move\nIn the hive view, click a cell to inspect it"

	pause_label = _make_label(Vector2(16, 140), 18)
	pause_label.text = "PAUSED"
	pause_label.visible = false

	_build_top_right_bar()
	_build_selection_panel()
	_build_cell_popup()
	_build_discard_dialog()

func _make_label(pos: Vector2, font_size: int) -> Label:
	var l := Label.new()
	l.position = pos
	l.add_theme_font_size_override("font_size", font_size)
	add_child(l)
	return l

func _info(text: String) -> Button:
	return UI.info_badge(text)

func _with_info(control: Control, tip: String) -> HBoxContainer:
	return UI.with_info(control, tip)

func _build_top_right_bar() -> void:
	var vp := get_viewport().get_visible_rect().size

	var bar := HBoxContainer.new()
	bar.add_theme_constant_override("separation", 6)
	bar.position = Vector2(vp.x - 430, 8)
	add_child(bar)

	for entry in SPEEDS:
		var btn := Button.new()
		btn.text = entry.label
		btn.tooltip_text = entry.tip
		btn.custom_minimum_size = Vector2(34, 26)
		btn.toggle_mode = true
		var scale_value: float = entry.scale
		btn.pressed.connect(func(): speed_requested.emit(scale_value))
		bar.add_child(btn)
		speed_buttons.append({"button": btn, "scale": scale_value})

	bar.add_child(_info("Game speed. These change how fast the simulation runs; they do not change how much resource a bee gathers per in-game second."))

	view_button = Button.new()
	view_button.text = "To Hive (Tab)"
	view_button.custom_minimum_size = Vector2(120, 26)
	view_button.pressed.connect(func(): view_toggle_requested.emit())
	bar.add_child(view_button)
	bar.add_child(_info("Switch between the meadow (flowers and foragers) and the hive interior (comb, queen, brood). Both keep simulating whichever one you are looking at."))

func set_speed_display(speed_scale: float) -> void:
	for entry in speed_buttons:
		entry.button.button_pressed = is_equal_approx(entry.scale, speed_scale)

func _build_selection_panel() -> void:
	var vp := get_viewport().get_visible_rect().size
	selection_panel = PanelContainer.new()
	selection_panel.position = Vector2(16, vp.y - 130)
	selection_panel.visible = false
	add_child(selection_panel)

	var column := VBoxContainer.new()
	selection_panel.add_child(column)

	selection_label = Label.new()
	selection_label.add_theme_font_size_override("font_size", 12)
	column.add_child(selection_label)

	var focus_row := HBoxContainer.new()
	column.add_child(focus_row)

	var nectar_btn := Button.new()
	nectar_btn.text = "Focus Nectar"
	nectar_btn.pressed.connect(func(): focus_requested.emit("nectar"))
	focus_row.add_child(_with_info(nectar_btn, "The selected foragers will look for nectar. Nectar is the colony's energy: bees eat it, and building comb burns it."))

	var pollen_btn := Button.new()
	pollen_btn.text = "Focus Pollen"
	pollen_btn.pressed.connect(func(): focus_requested.emit("pollen"))
	focus_row.add_child(_with_info(pollen_btn, "The selected foragers will look for pollen. Pollen is what the queen eats to lay eggs, so no pollen means no new bees."))

	var role_row := HBoxContainer.new()
	column.add_child(role_row)
	for entry in ROLE_BUTTONS:
		var btn := Button.new()
		btn.text = entry.label
		var role_key: String = entry.role
		btn.pressed.connect(func(): role_requested.emit(role_key))
		role_row.add_child(_with_info(btn, entry.tip))

# --- cell popup ---------------------------------------------------

func _build_cell_popup() -> void:
	cell_popup = PopupPanel.new()
	add_child(cell_popup)

	var column := VBoxContainer.new()
	cell_popup.add_child(column)

	cell_popup_label = Label.new()
	cell_popup_label.add_theme_font_size_override("font_size", 12)
	column.add_child(cell_popup_label)

	var row := HBoxContainer.new()
	column.add_child(row)

	var nectar_btn := Button.new()
	nectar_btn.text = "Store Nectar"
	nectar_btn.pressed.connect(func(): _request_designation("nectar"))
	row.add_child(_with_info(nectar_btn, "Reserve this cell for nectar. Foragers carrying pollen will walk past it."))

	var pollen_btn := Button.new()
	pollen_btn.text = "Store Pollen"
	pollen_btn.pressed.connect(func(): _request_designation("pollen"))
	row.add_child(_with_info(pollen_btn, "Reserve this cell for pollen. Foragers carrying nectar will walk past it."))

	var auto_btn := Button.new()
	auto_btn.text = "Any"
	auto_btn.pressed.connect(func(): _request_designation(""))
	row.add_child(_with_info(auto_btn, "Remove the reservation. The cell will accept whichever resource arrives first, and can also be used for brood."))

func show_cell_popup(cell: Node2D, screen_position: Vector2) -> void:
	active_cell = cell
	_refresh_cell_popup()
	cell_popup.position = Vector2i(screen_position + Vector2(12, -10))
	cell_popup.popup()

func _refresh_cell_popup() -> void:
	if active_cell == null or not is_instance_valid(active_cell):
		return
	var lines := []
	if not active_cell.is_built:
		lines.append("Unfinished cell -- %d%% built" % int(active_cell.build_fraction() * 100.0))
	else:
		match active_cell.content_type:
			"nectar":
				lines.append("Nectar: %d / %d" % [int(round(active_cell.amount)), int(active_cell.capacity)])
			"pollen":
				lines.append("Pollen: %d / %d" % [int(round(active_cell.amount)), int(active_cell.capacity)])
			"brood":
				var pct: float = 100.0 * active_cell.brood_progress / max(0.001, GameConfig.brood_develop_time)
				lines.append("Developing bee -- %d%%" % int(min(100.0, pct)))
			_:
				lines.append("Empty")
	var reserved: String = active_cell.designated_type if active_cell.designated_type != "" else "any resource"
	lines.append("Reserved for: %s" % reserved)
	cell_popup_label.text = "\n".join(lines)

func _process(_delta: float) -> void:
	if cell_popup.visible:
		_refresh_cell_popup()

func _request_designation(type: String) -> void:
	if active_cell and is_instance_valid(active_cell):
		cell_designation_requested.emit(active_cell, type)
		_refresh_cell_popup()

# --- discard warning ----------------------------------------------

## "Don't warn me again" is a third button rather than a checkbox.
## AcceptDialog lays out its own message label and doesn't reliably
## position arbitrary child controls beneath it, so an extra button is
## the sturdier choice here.
func _build_discard_dialog() -> void:
	discard_dialog = ConfirmationDialog.new()
	discard_dialog.title = "Nothing else can hold this"
	discard_dialog.ok_button_text = "Discard it"
	discard_dialog.cancel_button_text = "Leave the cell as it is"
	add_child(discard_dialog)

	discard_dialog.add_button("Discard, and stop warning me", true, "discard_always")
	discard_dialog.confirmed.connect(_on_discard_confirmed)
	discard_dialog.custom_action.connect(_on_discard_custom_action)

## Called by main.gd when re-designating a cell would destroy whatever
## is already in it, because no other cell has room.
func show_discard_warning(cell: Node2D, new_type: String, existing_type: String, existing_amount: float) -> void:
	pending_cell = cell
	pending_type = new_type
	discard_dialog.dialog_text = (
		"This cell holds %d %s, and there is no other cell with room for it.\n\n"
		+ "Reserving it for %s will throw that away."
	) % [int(round(existing_amount)), existing_type, new_type]
	discard_dialog.popup_centered()

func _on_discard_confirmed() -> void:
	_apply_discard()

func _on_discard_custom_action(action: StringName) -> void:
	if action == "discard_always":
		GameConfig.warn_on_discard = false
		discard_dialog.hide()
		_apply_discard()

func _apply_discard() -> void:
	if pending_cell and is_instance_valid(pending_cell):
		pending_cell.clear_cell()
		pending_cell.set_designation(pending_type)
	pending_cell = null
	pending_type = ""
	_refresh_cell_popup()

# --- readouts -----------------------------------------------------

func update_day(day: int) -> void:
	day_label.text = "Day %d" % day

func update_storage(nectar: float, pollen: float) -> void:
	storage_label.text = "Nectar: %d   Pollen: %d" % [int(round(nectar)), int(round(pollen))]

func update_population(foragers: int, nurses: int, builders: int) -> void:
	population_label.text = "Bees: %d foraging, %d nursing, %d building" % [foragers, nurses, builders]

func update_selection(bees: Array) -> void:
	selection_panel.visible = not bees.is_empty()
	if bees.is_empty():
		return
	if bees.size() == 1 and is_instance_valid(bees[0]):
		var b = bees[0]
		selection_label.text = "%s%s — %s — energy %d%%" % [
			"Queen " if b.is_queen else "Bee ",
			"" if b.is_queen else str(b.bee_id),
			b.role_name_text(),
			int(100.0 * b.energy / max(0.001, GameConfig.energy_capacity)),
		]
	else:
		selection_label.text = "%d bees selected" % bees.size()

func set_view_label(in_hive: bool) -> void:
	view_button.text = "To Meadow (Tab)" if in_hive else "To Hive (Tab)"
