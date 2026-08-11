extends CanvasLayer
## Top-left readouts (day, stores, bee count), the view switcher, the
## game-speed controls, the panel that appears when bees are selected,
## and the popup for inspecting a single comb cell.
##
## Every control carries a small "i" badge whose tooltip explains what
## it does -- see `_info()`. Kept separate from main.gd so the
## simulation wiring stays readable.

const UI = preload("res://scripts/ui.gd")
const Bee = preload("res://scripts/bee.gd")

signal focus_requested(type: String)
signal role_requested(role_name: String)
signal view_toggle_requested()
signal speed_requested(speed_scale: float)
signal cell_designation_requested(cell: Node2D, type: String)
## `focus` and `use_automine` carry the sub-mode the chosen role needs --
## which resource a forager starts on, whether a miner starts automining.
signal cell_hatch_role_requested(cell: Node2D, role: int, focus: String, use_automine: bool)
## Pins the hatch role so every future bee raised in the cell inherits
## it, rather than it applying to the next one only.
signal cell_hatch_lock_requested(cell: Node2D, locked: bool)
## `method` is "move" (a builder carries the contents to another cell) or
## "discard" (thrown out of the hive). `keep_empty` leaves the cell
## closed to deposits afterwards.
signal cell_empty_requested(cell: Node2D, method: String, keep_empty: bool)
## "Click a spot" modes -- main.gd puts itself into a placement mode when
## these fire, and consumes the next click in the relevant view instead
## of treating it as a normal select/drag.
signal build_cell_requested()
signal forage_start_point_requested()
## "none" clears it. Only offered for bees whose primary role actually
## checks a secondary -- see the note on _rebuild_role_controls.
signal secondary_role_requested(role_key: String)
## Enters "click a flower" mode -- only offered when floral constancy is
## on in tuning. See GameConfig.floral_constancy_on.
signal floral_preference_requested()

## Mirrors Bee.Role. Kept as plain ints so the HUD doesn't need to
## preload bee.gd just to name them. -1 means "colony default".
##
## Roles with a sub-mode are offered as a dropdown rather than a single
## button, so you can earmark a cell as, say, "raises pollen foragers" in
## one go instead of setting the role here and the focus on the bee once
## it emerges. `options` is a list of {label, focus, automine}.
const HATCH_ROLES := [
	{"label": "Default", "role": -1, "options": [
		{"label": "Colony default", "focus": "nectar", "automine": false},
	]},
	{"label": "Forager", "role": 0, "options": [
		{"label": "Forager — nectar", "focus": "nectar", "automine": false},
		{"label": "Forager — pollen", "focus": "pollen", "automine": false},
	]},
	{"label": "Nursery", "role": 1, "options": [
		{"label": "Nursery", "focus": "nectar", "automine": false},
	]},
	{"label": "Builder", "role": 2, "options": [
		{"label": "Builder", "focus": "nectar", "automine": false},
	]},
	{"label": "Miner", "role": 5, "options": [
		{"label": "Miner — marked blocks only", "focus": "nectar", "automine": false},
		{"label": "Miner — automine on", "focus": "nectar", "automine": true},
	]},
	{"label": "Honey", "role": 6, "options": [
		{"label": "Honey maker", "focus": "nectar", "automine": false},
	]},
]

## Transport-style controls: pause, play, and two levels of fast
## forward, using the usual arrow symbols rather than numbers.
const SPEEDS := [
	{"label": "❚❚", "scale": 0.0, "tip": "Pause. The whole colony freezes; you can still look around and give orders."},
	{"label": "▶", "scale": 1.0, "tip": "Play at normal speed."},
	{"label": "▶▶", "scale": 2.0, "tip": "Fast forward at double speed. Good for waiting out brood development or comb building."},
	{"label": "▶▶▶", "scale": 4.0, "tip": "Fast forward at quadruple speed. The quickest way to reach the next day."},
]

const ROLE_BUTTONS := [
	{
		"label": "Forager", "role": "forager",
		"tip": "Send the selected bees out to the meadow to gather nectar or pollen and carry it back into the comb.",
	},
	{
		"label": "Nursery", "role": "nursery",
		"tip": "Keep the selected bees indoors feeding the brood. Larvae do not develop at all on their own: a nurse has to drop pollen and either nectar or honey into each cell, and each feed only buys the larva a short stretch of growth before it stalls again. Honey feeds last longer. Standing over a fed larva speeds it up as well. With no nurse, the colony cannot grow.",
	},
	{
		"label": "Builder", "role": "builder",
		"tip": "Set the selected bees to draw new comb cells and to shift stores out of any cell you have re-designated. Building burns extra energy, because bees make wax from the sugar they have eaten.",
	},
	{
		"label": "Miner", "role": "miner",
		"tip": "Set the selected bees to dig out soil blocks you have marked. Click any soil block touching open space in the hive view to mark it. One miner takes about two minutes per block; several digging the same block share the work.",
	},
	{
		"label": "Automine", "role": "automine",
		"tip": "Toggle automatic digging for the selected miners. With it on they pick the exposed soil block nearest the centre of the comb without waiting to be told, so the hive opens up around itself.",
	},
	{
		"label": "Honey maker", "role": "honey_maker",
		"tip": "Set the selected bees to make honey. They take stored nectar back out of the comb, chew enzymes into it, spit the mix into a cell of its own and then fan their wings over that cell until the water has evaporated off. Only then is it honey -- which is several times as energy-dense as the nectar it came from, keeps far better, and lets nurses raise larvae faster.",
	},
	{
		"label": "Idle", "role": "idle",
		"tip": "Stop the selected bees doing anything on their own. They stay where they are and keep burning energy, but you can still move them with right-click. Useful for holding bees back or parking one somewhere.",
	},
	{
		"label": "Egg layer", "role": "egg_layer",
		"tip": "Queen only. She eats pollen from the comb until she has enough for an egg, then walks to a free cell and lays into it. Whenever laying is blocked -- no pollen, or no free cell -- she falls back to her backup role, which is nursing unless you change it, so she is feeding larvae rather than standing idle. Other bees ignore this button.",
	},
]

## Width kept clear in the top-right corner for the Tuning button that
## debug_panel.gd owns. Both use the same number so they can't collide.
const TUNING_BUTTON_RESERVE := 108.0

var day_label: Label
var storage_label: Label
var population_label: Label
var rate_label: Label
var pause_label: Label
var view_button: Button
var selection_panel: PanelContainer
var selection_label: Label
var task_label: Label
var speed_buttons: Array = []
var role_row: HBoxContainer
var shown_bees: Array = []

var cell_popup: PopupPanel
var cell_popup_label: Label
var active_cell: Node2D = null
var keep_empty_box: CheckBox
var hatch_lock_box: CheckBox

var flower_popup: PopupPanel
var flower_popup_label: Label
var active_flower: Node2D = null

var discard_dialog: ConfirmationDialog
var pending_cell: Node2D = null
var pending_type: String = ""

func _ready() -> void:
	process_mode = PROCESS_MODE_ALWAYS
	layer = 9

	day_label = _make_label(Vector2(16, 12), 22)
	storage_label = _make_label(Vector2(16, 42), 18)
	population_label = _make_label(Vector2(16, 66), 14)
	rate_label = _make_label(Vector2(16, 86), 12)

	var hint := _make_label(Vector2(16, 106), 12)
	hint.text = "Arrows = pan · wheel = zoom · Tab = switch view · Space = pause\nClick or drag to select bees · right-click a flower to send them · right-click ground to move\nIn the hive view, click a cell to inspect it"

	pause_label = _make_label(Vector2(16, 192), 18)
	pause_label.text = "PAUSED"
	pause_label.visible = false

	_build_top_right_bar()
	_build_selection_panel()
	_build_cell_popup()
	_build_flower_popup()
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

## Anchored to the top-right rather than positioned at fixed pixels, so
## the bar follows the corner when the window is resized. The tuning
## button in debug_panel.gd is anchored the same way and reserves its
## own width, so the two no longer overlap.
func _build_top_right_bar() -> void:
	var bar := HBoxContainer.new()
	bar.add_theme_constant_override("separation", 6)
	bar.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	bar.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	# leave room for the Tuning button, which sits in the very corner
	bar.offset_right = -TUNING_BUTTON_RESERVE
	bar.offset_top = 8
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
	selection_panel = PanelContainer.new()
	# anchored to the bottom-left so it stays put when the window resizes
	selection_panel.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	selection_panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	selection_panel.offset_left = 16
	selection_panel.offset_bottom = -16
	selection_panel.visible = false
	add_child(selection_panel)

	var column := VBoxContainer.new()
	selection_panel.add_child(column)

	selection_label = Label.new()
	selection_label.add_theme_font_size_override("font_size", 12)
	column.add_child(selection_label)

	# what the bee is doing right this second
	task_label = Label.new()
	task_label.add_theme_font_size_override("font_size", 12)
	task_label.add_theme_color_override("font_color", Color(0.75, 0.9, 1.0))
	column.add_child(task_label)

	# Rebuilt from scratch on every selection change -- which controls make
	# sense (a plain "Forager" button vs. a focus row, "Miner" vs. an
	# Automine toggle, and so on) depends on what's currently selected. See
	# _rebuild_role_controls.
	role_row = HBoxContainer.new()
	column.add_child(role_row)

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

	var honey_btn := Button.new()
	honey_btn.text = "Store Honey"
	honey_btn.pressed.connect(func(): _request_designation("honey"))
	row.add_child(_with_info(honey_btn, "Reserve this cell for honey. Honey makers spit their chewed nectar mix into cells like this one and then fan it dry."))

	var egg_btn := Button.new()
	egg_btn.text = "Raise Eggs"
	egg_btn.pressed.connect(func(): _request_designation("brood"))
	row.add_child(_with_info(egg_btn, "Reserve this cell as a nursery. The queen lays here first, and foragers won't fill it with stores. Reserving enough of these is what stops laying stalling for want of a free cell."))

	var auto_btn := Button.new()
	auto_btn.text = "Any"
	auto_btn.pressed.connect(func(): _request_designation(""))
	row.add_child(_with_info(auto_btn, "Remove the reservation. The cell takes whichever resource arrives first, and reserves itself for that from then on."))

	_build_empty_controls(column)

	# Which role a bee raised here comes out as.
	var hatch_row := HBoxContainer.new()
	column.add_child(hatch_row)
	var hatch_title := Label.new()
	hatch_title.text = "Raises:"
	hatch_title.add_theme_font_size_override("font_size", 11)
	hatch_row.add_child(hatch_title)
	hatch_row.add_child(_info("Set what a bee raised in this cell becomes when it emerges. Roles that have a sub-mode -- a forager's resource, whether a miner starts automining -- offer it here, so the new bee arrives already set up."))

	for entry in HATCH_ROLES:
		var options: Array = entry.options
		if options.size() == 1:
			var btn := Button.new()
			btn.text = entry.label
			btn.add_theme_font_size_override("font_size", 11)
			var role_value: int = entry.role
			var only: Dictionary = options[0]
			btn.pressed.connect(func(): _request_hatch_role(role_value, only.focus, only.automine))
			hatch_row.add_child(btn)
		else:
			hatch_row.add_child(_make_hatch_menu(entry))

	# Whether that role sticks for every future bee, or applies once.
	var lock_row := HBoxContainer.new()
	column.add_child(lock_row)
	hatch_lock_box = CheckBox.new()
	hatch_lock_box.text = "Keep this role for every bee raised here"
	hatch_lock_box.add_theme_font_size_override("font_size", 11)
	hatch_lock_box.toggled.connect(func(pressed: bool):
		if active_cell and is_instance_valid(active_cell):
			cell_hatch_lock_requested.emit(active_cell, pressed)
			_refresh_cell_popup()
	)
	lock_row.add_child(hatch_lock_box)
	lock_row.add_child(_info("On: every bee this cell ever raises comes out in the chosen role, so you can earmark a cell as a builder nursery once and forget about it. Off: the role applies to the next bee only and then clears, so a one-off choice doesn't quietly govern the cell forever."))

## Clearing a cell out. This exists because a colony with plenty of
## foragers fills every spare cell with nectar, leaving nothing free for
## pollen or for the queen to lay in -- so emptying a cell is only half
## the job, and "keep it empty afterwards" is the other half.
func _build_empty_controls(column: VBoxContainer) -> void:
	var empty_row := HBoxContainer.new()
	column.add_child(empty_row)

	var title := Label.new()
	title.text = "Empty cell:"
	title.add_theme_font_size_override("font_size", 11)
	empty_row.add_child(title)

	var move_btn := Button.new()
	move_btn.text = "To another cell"
	move_btn.add_theme_font_size_override("font_size", 11)
	move_btn.pressed.connect(func(): _request_empty("move"))
	empty_row.add_child(_with_info(move_btn, "A builder comes and carries the contents to another cell with room for them. If nothing anywhere has room, the load is lost -- so keep an eye on how full the comb is."))

	var discard_btn := Button.new()
	discard_btn.text = "Discard outside"
	discard_btn.add_theme_font_size_override("font_size", 11)
	discard_btn.pressed.connect(func(): _request_empty("discard"))
	empty_row.add_child(_with_info(discard_btn, "Throw the contents out of the hive. Quicker than moving them, but everything in the cell is gone."))

	var keep_row := HBoxContainer.new()
	column.add_child(keep_row)
	keep_empty_box = CheckBox.new()
	keep_empty_box.text = "Keep this cell empty afterwards"
	keep_empty_box.add_theme_font_size_override("font_size", 11)
	keep_row.add_child(keep_empty_box)
	keep_row.add_child(_info("On: the cell refuses every deposit once it's been cleared, so it stays free. This is what stops a crowd of foragers cramming nectar into the last spare pot and leaving nowhere for pollen or eggs. Reserving the cell for a resource later clears this again. Off: the cell goes back to taking whatever arrives first."))

## A dropdown for a role that has more than one way to start.
func _make_hatch_menu(entry: Dictionary) -> Control:
	var menu := MenuButton.new()
	menu.text = entry.label
	menu.add_theme_font_size_override("font_size", 11)
	var options: Array = entry.options
	var role_value: int = entry.role
	var popup := menu.get_popup()
	for i in range(options.size()):
		popup.add_item(options[i].label, i)
	popup.id_pressed.connect(func(id: int):
		_request_hatch_role(role_value, options[id].focus, options[id].automine)
	)
	return menu

## --- flower popup -------------------------------------------------

func _build_flower_popup() -> void:
	flower_popup = PopupPanel.new()
	add_child(flower_popup)

	flower_popup_label = Label.new()
	flower_popup_label.add_theme_font_size_override("font_size", 12)
	flower_popup.add_child(flower_popup_label)

func show_flower_popup(flower: Node2D, screen_position: Vector2) -> void:
	active_flower = flower
	_refresh_flower_popup()
	flower_popup.position = Vector2i(screen_position + Vector2(12, -10))
	flower_popup.popup()

func _refresh_flower_popup() -> void:
	if active_flower == null or not is_instance_valid(active_flower):
		return
	var lines := []
	lines.append(active_flower.species_name)
	lines.append("Nectar: %d / %d   (+%.2f/s)" % [
		int(round(active_flower.nectar_amount)),
		int(active_flower.nectar_capacity),
		active_flower.nectar_recharge_rate,
	])
	lines.append("Pollen: %d / %d   (+%.2f/s)" % [
		int(round(active_flower.pollen_amount)),
		int(active_flower.pollen_capacity),
		active_flower.pollen_recharge_rate,
	])
	if active_flower.occupied_by != null and is_instance_valid(active_flower.occupied_by):
		lines.append("Being worked by bee %d" % active_flower.occupied_by.bee_id)
	else:
		lines.append("No bee here")
	var age: float = active_flower.marker_age()
	if age >= 0.0:
		var fresh := age < GameConfig.tarsal_marker_seconds
		lines.append("Scent mark: %ds old%s" % [int(age), " (bees avoiding)" if (fresh and GameConfig.tarsal_markers_on) else ""])
	flower_popup_label.text = "\n".join(lines)

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
			"honey":
				if active_cell.is_ripe_honey():
					lines.append("Honey: %d / %d" % [int(round(active_cell.amount)), int(active_cell.capacity)])
				else:
					lines.append("Honey mix: %d / %d -- %d%% fanned dry" % [
						int(round(active_cell.amount)),
						int(active_cell.capacity),
						int(active_cell.ripen_fraction() * 100.0),
					])
					lines.append("Not edible until it is fully dried out.")
			"brood":
				lines.append("Developing bee -- %d%%" % int(active_cell.development_percent()))
				if active_cell.brood_fed_seconds > 0.0:
					lines.append("Fed on %s -- %ds of development left in it" % [
						"honey" if active_cell.fed_on_honey else "nectar",
						int(active_cell.brood_fed_seconds),
					])
				else:
					lines.append("Hungry -- development has stopped until a nurse feeds it")
			_:
				lines.append("Empty")
	var reserved := "any resource"
	if active_cell.keep_empty:
		reserved = "nothing -- being kept empty"
	elif active_cell.designated_type == "brood":
		reserved = "raising eggs"
	elif active_cell.designated_type != "":
		reserved = active_cell.designated_type
	lines.append("Reserved for: %s" % reserved)
	if active_cell.evict_requested:
		lines.append("Waiting for a builder to carry the contents out")

	var hatch_name := "colony default"
	for entry in HATCH_ROLES:
		if entry.role == active_cell.hatch_role:
			hatch_name = entry.label
			if entry.role == 0:
				hatch_name += " (%s)" % active_cell.hatch_focus
			elif entry.role == 5 and active_cell.hatch_automine:
				hatch_name += " (automine)"
			break
	lines.append("Raises: %s%s" % [
		hatch_name,
		" -- every bee" if active_cell.hatch_role_locked else "",
	])
	cell_popup_label.text = "\n".join(lines)

	# reflect the cell's own state without re-firing the signals
	keep_empty_box.set_pressed_no_signal(active_cell.keep_empty)
	hatch_lock_box.set_pressed_no_signal(active_cell.hatch_role_locked)

func _process(_delta: float) -> void:
	if cell_popup.visible:
		_refresh_cell_popup()
	if flower_popup.visible:
		_refresh_flower_popup()
	if selection_panel.visible:
		_refresh_selection_text()

func _request_designation(type: String) -> void:
	if active_cell and is_instance_valid(active_cell):
		cell_designation_requested.emit(active_cell, type)
		_refresh_cell_popup()

func _request_hatch_role(role: int, focus: String, use_automine: bool) -> void:
	if active_cell and is_instance_valid(active_cell):
		cell_hatch_role_requested.emit(active_cell, role, focus, use_automine)
		_refresh_cell_popup()

func _request_empty(method: String) -> void:
	if active_cell and is_instance_valid(active_cell):
		cell_empty_requested.emit(active_cell, method, keep_empty_box.button_pressed)
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

## Honey is counted only once it's fully fanned dry -- wet mix still
## drying in a cell isn't a store the colony can use yet.
func update_storage(nectar: float, pollen: float, honey: float) -> void:
	storage_label.text = "Nectar: %d   Pollen: %d   Honey: %d" % [
		int(round(nectar)), int(round(pollen)), int(round(honey)),
	]

func update_population(foragers: int, nurses: int, builders: int, honey_makers: int) -> void:
	population_label.text = "Bees: %d foraging, %d nursing, %d building, %d on honey" % [
		foragers, nurses, builders, honey_makers,
	]

## `births_per_sec` is shown per minute instead -- birth events are rare
## enough (one every 90s+ per brood cell) that a per-second figure would
## always read as an unreadable 0.0x.
func update_rates(nectar_per_sec: float, pollen_per_sec: float, births_per_sec: float) -> void:
	rate_label.text = "Rates (60s avg): Nectar +%.1f/s   Pollen +%.1f/s   Births %.2f/min" % [
		nectar_per_sec, pollen_per_sec, births_per_sec * 60.0,
	]

func update_selection(bees: Array) -> void:
	shown_bees = bees
	selection_panel.visible = not bees.is_empty()
	if bees.is_empty():
		return

	_rebuild_role_controls(bees)
	_refresh_selection_text()

## Which controls to show depends on what's selected: a bee already doing
## a role doesn't need a button to become that role again, and some roles
## have extra actions (focus, automine, manual build placement) that only
## make sense once a bee is already doing them. Rebuilding the row from
## scratch is simpler than trying to toggle a fixed set of widgets.
func _rebuild_role_controls(bees: Array) -> void:
	for child in role_row.get_children():
		child.queue_free()

	var common_role: int = _common_role(bees)
	var any_queen := false
	for b in bees:
		if is_instance_valid(b) and b.is_queen:
			any_queen = true
			break

	# --- forager: focus + start point directly if already foraging,
	# otherwise a dropdown that becomes a forager with a focus in one go
	if common_role == Bee.Role.FORAGER:
		var nectar_btn := Button.new()
		nectar_btn.text = "Focus Nectar"
		nectar_btn.pressed.connect(func(): focus_requested.emit("nectar"))
		role_row.add_child(_with_info(nectar_btn, "The selected foragers will look for nectar. Nectar is the colony's energy: bees eat it, and building comb burns it."))

		var pollen_btn := Button.new()
		pollen_btn.text = "Focus Pollen"
		pollen_btn.pressed.connect(func(): focus_requested.emit("pollen"))
		role_row.add_child(_with_info(pollen_btn, "The selected foragers will look for pollen. Pollen is what the queen eats to lay eggs, so no pollen means no new bees."))

		var has_start: bool = is_instance_valid(bees[0]) and bees[0].has_forage_start_point()
		var start_btn := Button.new()
		start_btn.text = "Reset start point" if has_start else "Set start point"
		start_btn.pressed.connect(func(): forage_start_point_requested.emit())
		role_row.add_child(_with_info(start_btn, "Click this, then click a spot in the meadow. The selected foragers will head there first on every trip out of the hive, so you can split them across different parts of the meadow instead of them all drifting to whichever flower happens to be nearest the entrance. A green marker shows where it's set while a bee with one is selected."))

		if GameConfig.floral_constancy_on:
			var current_pref: String = bees[0].preferred_species if is_instance_valid(bees[0]) else ""
			var pref_btn := Button.new()
			pref_btn.text = ("Preference: %s" % current_pref) if current_pref != "" else "Set preference"
			pref_btn.pressed.connect(func(): floral_preference_requested.emit())
			role_row.add_child(_with_info(pref_btn, "Click this, then click a flower in the meadow. The selected foragers will only ever visit that species from then on, even walking past a nearer flower of something else -- real bees do this too, sticking with one species while it's paying off."))
	else:
		var forager_menu := _make_role_menu("Forager", _tip_for("forager"), [
			{"text": "Become forager", "action": func(): role_requested.emit("forager")},
			{"text": "...and focus Nectar", "action": func(): role_requested.emit("forager"); focus_requested.emit("nectar")},
			{"text": "...and focus Pollen", "action": func(): role_requested.emit("forager"); focus_requested.emit("pollen")},
		])
		role_row.add_child(forager_menu)

	# --- nursery ---
	if common_role != Bee.Role.NURSERY:
		var nursery_btn := Button.new()
		nursery_btn.text = "Nursery"
		nursery_btn.pressed.connect(func(): role_requested.emit("nursery"))
		role_row.add_child(_with_info(nursery_btn, _tip_for("nursery")))

	# --- builder: manual placement directly if already building,
	# otherwise a plain button to become one
	if common_role == Bee.Role.BUILDER:
		var build_btn := Button.new()
		build_btn.text = "Build Cell"
		build_btn.pressed.connect(func(): build_cell_requested.emit())
		role_row.add_child(_with_info(build_btn, "Click this, then click an empty tile in the hive view. The selected builders will place and build a cell there next, before falling back to their usual pick-a-site behaviour."))
	else:
		var builder_btn := Button.new()
		builder_btn.text = "Builder"
		builder_btn.pressed.connect(func(): role_requested.emit("builder"))
		role_row.add_child(_with_info(builder_btn, _tip_for("builder")))

	# --- miner: automine toggle directly if already mining, otherwise a
	# dropdown that becomes a miner with automine already on
	if common_role == Bee.Role.MINER:
		var first_automine: bool = bees[0].automine if is_instance_valid(bees[0]) else false
		var automine_btn := Button.new()
		automine_btn.toggle_mode = true
		automine_btn.button_pressed = first_automine
		automine_btn.text = "Automine: On" if first_automine else "Automine: Off"
		automine_btn.pressed.connect(func(): role_requested.emit("automine"))
		role_row.add_child(_with_info(automine_btn, _tip_for("automine")))
	else:
		var miner_menu := _make_role_menu("Miner", _tip_for("miner"), [
			{"text": "Become miner", "action": func(): role_requested.emit("miner")},
			{"text": "...with automine on", "action": func(): role_requested.emit("miner"); role_requested.emit("automine")},
		])
		role_row.add_child(miner_menu)

	# --- honey maker ---
	if common_role != Bee.Role.HONEY_MAKER:
		var honey_btn := Button.new()
		honey_btn.text = "Honey maker"
		honey_btn.pressed.connect(func(): role_requested.emit("honey_maker"))
		role_row.add_child(_with_info(honey_btn, _tip_for("honey_maker")))

	# --- idle ---
	if common_role != Bee.Role.IDLE:
		var idle_btn := Button.new()
		idle_btn.text = "Idle"
		idle_btn.pressed.connect(func(): role_requested.emit("idle"))
		role_row.add_child(_with_info(idle_btn, _tip_for("idle")))

	# --- egg layer: queen only, and only if she isn't already one ---
	if any_queen and common_role != Bee.Role.EGG_LAYER:
		var egg_btn := Button.new()
		egg_btn.text = "Egg layer"
		egg_btn.pressed.connect(func(): role_requested.emit("egg_layer"))
		role_row.add_child(_with_info(egg_btn, _tip_for("egg_layer")))

	# --- secondary role: only Miner, Nursery and Builder ever check
	# theirs (see Bee._idle_dispatch), so it's only offered while one of
	# those is the common role -- offering it otherwise would be a
	# control that silently does nothing.
	if (
		common_role == Bee.Role.MINER
		or common_role == Bee.Role.NURSERY
		or common_role == Bee.Role.BUILDER
		or common_role == Bee.Role.HONEY_MAKER
		or common_role == Bee.Role.EGG_LAYER
	):
		var current_secondary: int = bees[0].secondary_role if is_instance_valid(bees[0]) else -1
		var secondary_menu := _make_role_menu(
			"Backup: %s" % _secondary_label(current_secondary),
			"What this bee does instead of standing around whenever it genuinely has no work of its own -- for example a non-automine miner with no block marked, or a nurse with no brood to tend. It drops the backup role and returns to its own the instant real work turns up again.",
			[
				{"text": "None", "action": func(): secondary_role_requested.emit("none")},
				{"text": "Forager", "action": func(): secondary_role_requested.emit("forager")},
				{"text": "Nursery", "action": func(): secondary_role_requested.emit("nursery")},
				{"text": "Builder", "action": func(): secondary_role_requested.emit("builder")},
				{"text": "Miner", "action": func(): secondary_role_requested.emit("miner")},
				{"text": "Honey maker", "action": func(): secondary_role_requested.emit("honey_maker")},
			]
		)
		role_row.add_child(secondary_menu)

## -1 means the selection is mixed -- no role button gets hidden in that
## case, since there's no single "already this role" to exclude.
func _common_role(bees: Array) -> int:
	var found := false
	var role_value := -1
	for b in bees:
		if not is_instance_valid(b):
			continue
		if not found:
			role_value = b.role
			found = true
		elif b.role != role_value:
			return -1
	return role_value if found else -1

func _secondary_label(secondary_role: int) -> String:
	match secondary_role:
		Bee.Role.FORAGER:
			return "Forager"
		Bee.Role.NURSERY:
			return "Nursery"
		Bee.Role.BUILDER:
			return "Builder"
		Bee.Role.MINER:
			return "Miner"
		Bee.Role.HONEY_MAKER:
			return "Honey maker"
		Bee.Role.EGG_LAYER:
			return "Egg layer"
		_:
			return "None"

func _tip_for(role_key: String) -> String:
	for entry in ROLE_BUTTONS:
		if entry.role == role_key:
			return entry.tip
	return ""

## A small dropdown button: clicking it opens a popup menu rather than
## firing an action directly. Used where becoming a role and configuring
## it (a focus, automine) are offered together as one click.
func _make_role_menu(label: String, tip: String, items: Array) -> Control:
	var menu := MenuButton.new()
	menu.text = label
	menu.tooltip_text = tip
	var popup := menu.get_popup()
	for i in range(items.size()):
		popup.add_item(items[i].text, i)
	popup.id_pressed.connect(func(id: int): items[id].action.call())
	return menu

## Re-read every frame so the task line tracks what the bee is doing.
func _refresh_selection_text() -> void:
	shown_bees = shown_bees.filter(func(b): return is_instance_valid(b))
	if shown_bees.is_empty():
		selection_panel.visible = false
		return
	if shown_bees.size() == 1:
		var b = shown_bees[0]
		var line := "%s%s — %s — energy %d%%" % [
			"Queen " if b.is_queen else "Bee ",
			"" if b.is_queen else str(b.bee_id),
			b.role_name_text(),
			int(100.0 * b.energy / max(0.001, GameConfig.energy_capacity)),
		]
		if b.is_queen:
			line += "\nAge: %.1f days   (does not die of old age)" % b.age_days()
		else:
			line += "\nAge: %.1f days   Left: %.1f days" % [b.age_days(), b.days_remaining()]
		line += "\n%s" % b.carrying_text()
		# the queen's pollen store is the thing that gates egg-laying,
		# so it's worth showing as a running total
		if b.is_queen:
			line += "\nPollen eaten: %d / %d needed for an egg" % [
				int(b.pollen_eaten), int(GameConfig.egg_pollen_cost),
			]
		selection_label.text = line
		task_label.text = "Now: %s" % b.task_description()
	else:
		selection_label.text = "%d bees selected" % shown_bees.size()
		task_label.text = ""

func set_view_label(in_hive: bool) -> void:
	view_button.text = "To Meadow (Tab)" if in_hive else "To Hive (Tab)"
