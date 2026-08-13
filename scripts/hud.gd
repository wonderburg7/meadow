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
signal colony_panel_requested()
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
## Applied the moment the checkbox is ticked, independently of whether
## the cell is being emptied right now.
signal cell_keep_empty_requested(cell: Node2D, keep_empty: bool)
## Whether the queen lays a gyne into this cell rather than a worker.
signal cell_gyne_requested(cell: Node2D, as_gyne: bool)
## "Click a spot" modes -- main.gd puts itself into a placement mode when
## these fire, and consumes the next click in the relevant view instead
## of treating it as a normal select/drag.
signal build_cell_requested()
## Sets the tile an architect builds outward from -- its own centre of
## operations, rather than the middle of the comb.
signal home_cell_requested()
## The same for a miner: the tile it works outward from when choosing
## which soil to dig next.
signal mine_home_requested()
## "Mine": the next click (ctrl to add more) sets this miner's own list
## of blocks to dig, in order.
signal mine_target_requested()
## "Keep clear": the next click flags a tile no architect will build on.
signal keep_clear_requested()
## Restocking. The currently selected comb becomes the cells this
## architect keeps full of `resource`.
signal restock_targets_requested(resource: String)
## The selected comb becomes the architect's allowed sources (`allowed`
## true) or the cells it must never touch (false).
signal restock_sources_requested(allowed: bool)
signal restock_clear_requested()
## Adds the selected cells to the nursery zone, or takes them out of it.
signal cell_zone_requested(cell: Node2D, in_zone: bool)
## Sets the priority tier on the selected zone cells: 0 low, 1 medium,
## 2 high.
signal cell_priority_requested(cell: Node2D, tier: int)
## Seals the selected cells, or opens them back up.
signal cell_close_requested(cell: Node2D, closed: bool)
## Fill the cell to the top and then seal it, refusing withdrawals in the
## meantime so it can actually get there.
signal cell_fill_close_requested(cell: Node2D)
## Opens the nursery zone window.
signal nursery_window_requested()
## Marks or clears the digging flag on every selected soil block.
signal soil_mark_requested(mark: bool)
signal forage_start_point_requested()
## "none" clears it. Only offered for bees whose primary role actually
## checks a secondary -- see the note on _rebuild_role_controls.
signal secondary_role_requested(role_key: String)
## Whether reassigning the selected bees waits for their current job.
signal finish_first_requested(value: bool)
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
	## An architect's sub-mode rides in the `focus` field rather than
	## getting a field of its own -- the cell only needs to carry one
	## extra string, and a bee is never both a forager and an architect.
	{"label": "Architect", "role": 2, "options": [
		{"label": "Architect — cell builder", "focus": "build", "automine": false},
		{"label": "Architect — cell maintenance", "focus": "maintain", "automine": false},
		{"label": "Architect — both", "focus": "both", "automine": false},
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

## What an architect can be set to do. The keys are what main.gd matches
## on in _on_role_requested.
const ARCHITECT_MODES := [
	{"key": "architect_build", "mode": "build", "label": "Build"},
	{"key": "architect_maintain", "mode": "maintain", "label": "Maintain"},
	{"key": "architect_restock", "mode": "restock", "label": "Restock"},
	{"key": "architect_both", "mode": "both", "label": "Build & maintain"},
]

## What a nursery bee can be set to do. Royal jelly is only worth
## producing when the colony is raising gynes.
const NURSE_MODES := [
	{"key": "nurse_feed", "mode": "feed", "label": "Feed brood"},
	{"key": "nurse_jelly", "mode": "jelly", "label": "Produce royal jelly"},
	{"key": "nurse_both", "mode": "both", "label": "Both"},
]

const ROLE_BUTTONS := [
	{
		"label": "Forager", "role": "forager",
		"tip": "Send the selected bees out to the meadow to gather nectar or pollen and carry it back into the comb.",
	},
	{
		"label": "Nursery", "role": "nursery",
		"tip": "Keep the selected bees indoors on brood work. Larvae do not develop at all on their own: a nurse collects pollen and either nectar or honey from the comb, carries it to the cell, and each feed only buys the larva a short stretch of growth before it stalls again. Honey feeds last longer. With no nurse, the colony cannot grow. On the royal jelly sub-mode a nurse instead eats pollen and honey and works them into jelly, which is the one thing a gyne larva cannot be raised without.",
	},
	{
		"label": "Architect", "role": "builder",
		"tip": "Architects look after the comb itself. As a cell builder one draws new cells; on cell maintenance it clears dead larvae out of blocked cells and shifts stores out of any cell you have re-designated or asked to be emptied; on both it takes whichever job comes up, with maintenance first. Building burns extra energy, because bees make wax from the sugar they have eaten.",
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

## The top-left corner. Every readout lives in the colony window now;
## this shows only the ones the player has starred there, in a fixed
## order, so the corner is theirs to spend rather than a fixed block of
## text. `corner_texts` is also what the colony window is handed, so the
## two can never disagree about what a number says.
var corner_column: VBoxContainer
var corner_texts: Dictionary = {
	"day": "", "stores": "", "population": "", "comb": "",
	"energy": "", "rates": "",
}
## Order the starred readouts appear in, matching ColonyPanel.STAT_ROWS.
const CORNER_ORDER := ["day", "stores", "population", "comb", "energy", "rates"]
## Font size per readout -- the day is the headline, the rest is detail.
const CORNER_SIZES := {
	"day": 22, "stores": 16, "population": 13, "comb": 12,
	"energy": 13, "rates": 12,
}
## What is currently drawn, so the column is only rebuilt when it would
## actually look different rather than every frame.
var corner_signature: String = ""

var pause_label: Label
var view_button: Button
var selection_panel: PanelContainer
var selection_label: Label
var task_label: Label
var speed_buttons: Array = []
var role_row: VBoxContainer
var shown_bees: Array = []

var cell_popup: PopupPanel
var cell_popup_label: Label
var active_cell: Node2D = null
var keep_empty_box: CheckBox
var hatch_lock_box: CheckBox
var gyne_box: CheckBox

var flower_popup: PopupPanel
var flower_popup_label: Label
var active_flower: Node2D = null

var obstacle_popup: PopupPanel
var obstacle_popup_label: Label

var soil_popup: PopupPanel
var soil_popup_label: Label
## How many cells the popup's buttons will act on. 1 unless the player
## has a multi-cell selection.
var selected_cell_count: int = 1

var warning_panel: PanelContainer
var warning_label: Label
var warning_timer: float = 0.0

## The at-a-glance problem strip, as [text, severity] pairs, kept so the
## corner can be rebuilt without main.gd having to resend it.
var shown_signals: Array = []

## Severity colours for the at-a-glance strip: 0 is background
## information, 1 is worth looking at, 2 is losing you something now.
const SIGNAL_COLOURS := [
	Color(0.75, 0.82, 0.9),
	Color(1.0, 0.85, 0.4),
	Color(1.0, 0.45, 0.4),
]

var discard_dialog: ConfirmationDialog
var pending_cell: Node2D = null
var pending_type: String = ""

func _ready() -> void:
	process_mode = PROCESS_MODE_ALWAYS
	layer = 9

	# The controls used to be printed here permanently. They now live in
	# the Tuning panel's Interface section, which keeps the corner of the
	# screen clear once you know them.
	#
	# One column for everything in the corner: the starred readouts, then
	# the at-a-glance problem strip underneath, so it reads as one block --
	# what you have, then what's wrong with it. Laid out rather than
	# positioned at fixed pixels, because which readouts are showing
	# changes as the player stars and unstars them.
	corner_column = VBoxContainer.new()
	corner_column.position = Vector2(16, 12)
	corner_column.add_theme_constant_override("separation", 2)
	add_child(corner_column)

	pause_label = _make_label(Vector2(16, 300), 18)
	pause_label.text = "PAUSED"
	pause_label.visible = false

	_build_top_right_bar()
	_build_selection_panel()
	_build_cell_popup()
	_build_flower_popup()
	_build_obstacle_popup()
	_build_soil_popup()
	_build_warning_banner()
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

	var colony_button := Button.new()
	colony_button.text = "Colony (C)"
	colony_button.custom_minimum_size = Vector2(90, 26)
	colony_button.pressed.connect(func(): colony_panel_requested.emit())
	bar.add_child(colony_button)
	bar.add_child(_info("Open the colony overview: how many bees are on each job, what is in the comb, and how the brood is doing. Click any role in it to select every bee doing that job at once."))

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
	# sense depends on what's currently selected. See
	# _rebuild_role_controls.
	#
	# A column of short rows rather than one long row of everything: the
	# panel had grown to a dozen controls side by side, which ran off the
	# screen and gave no clue which control belonged to which idea. The
	# rows are now grouped by question -- what is it, how is it doing it,
	# what should it do next -- which is roughly the order you think in.
	role_row = VBoxContainer.new()
	role_row.add_theme_constant_override("separation", 3)
	column.add_child(role_row)

# --- cell popup ---------------------------------------------------

## The popup had grown to five rows of buttons plus two checkboxes, all
## on screen at once, which is more than anyone can scan while a click is
## in progress. It's now grouped into collapsible sections, the same
## pattern the tuning panel uses.
##
## Only "Reserve for" starts open, because that is the one thing you do
## to nearly every cell. The rest are things you do occasionally and
## deliberately, so they're one click away rather than always in the way.
## Which sections are open is remembered for the session, so a player who
## works in the zone a lot doesn't reopen it every time.
var cell_sections: Dictionary = {}     # title -> the VBox holding its rows
var cell_section_open: Dictionary = {}

func _build_cell_popup() -> void:
	cell_popup = PopupPanel.new()
	add_child(cell_popup)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 2)
	cell_popup.add_child(column)

	cell_popup_label = Label.new()
	cell_popup_label.add_theme_font_size_override("font_size", 12)
	column.add_child(cell_popup_label)

	var row := HBoxContainer.new()
	_cell_section(column, "Reserve for", true).add_child(row)

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

	var jelly_btn := Button.new()
	jelly_btn.text = "Store Jelly"
	jelly_btn.pressed.connect(func(): _request_designation("jelly"))
	row.add_child(_with_info(jelly_btn, "Reserve this cell for royal jelly. Nurses on the royal jelly sub-mode store what they make here, and draw on it when feeding gyne larvae."))

	var egg_btn := Button.new()
	egg_btn.text = "Raise Eggs"
	egg_btn.pressed.connect(func(): _request_designation("brood"))
	row.add_child(_with_info(egg_btn, "Reserve this cell as a nursery. The queen lays here first, and foragers won't fill it with stores. Reserving enough of these is what stops laying stalling for want of a free cell."))

	var auto_btn := Button.new()
	auto_btn.text = "Any"
	auto_btn.pressed.connect(func(): _request_designation(""))
	row.add_child(_with_info(auto_btn, "Remove the reservation. The cell takes whichever resource arrives first, and reserves itself for that from then on."))

	_build_zone_controls(_cell_section(column, "Nursery zone", false))
	_build_closing_controls(_cell_section(column, "Sealing", false))
	_build_empty_controls(_cell_section(column, "Emptying", false))

	var raises := _cell_section(column, "Raises", false)

	# Which role a bee raised here comes out as.
	var hatch_row := HBoxContainer.new()
	raises.add_child(hatch_row)
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
	raises.add_child(lock_row)
	hatch_lock_box = CheckBox.new()
	hatch_lock_box.text = "Keep this role for every bee raised here"
	hatch_lock_box.add_theme_font_size_override("font_size", 11)
	hatch_lock_box.toggled.connect(func(pressed: bool):
		if active_cell and is_instance_valid(active_cell):
			cell_hatch_lock_requested.emit(active_cell, pressed)
			_refresh_cell_popup()
	)
	lock_row.add_child(hatch_lock_box)

	# Whether the queen lays a gyne here rather than a worker.
	var gyne_row := HBoxContainer.new()
	raises.add_child(gyne_row)
	gyne_box = CheckBox.new()
	gyne_box.text = "Raise a gyne (future queen) in this cell"
	gyne_box.add_theme_font_size_override("font_size", 11)
	gyne_box.toggled.connect(func(pressed: bool):
		if active_cell and is_instance_valid(active_cell):
			cell_gyne_requested.emit(active_cell, pressed)
			_refresh_cell_popup()
	)
	gyne_row.add_child(gyne_box)
	gyne_row.add_child(_info("A gyne is a future queen. She costs the queen several times as much pollen to lay, takes four times as long to develop, and can only be fed on royal jelly with pollen and honey -- so you need nurses producing jelly before one will grow at all. She can do any worker job in the meantime, though she is bigger, slower and hungrier than a worker."))
	lock_row.add_child(_info("On: every bee this cell ever raises comes out in the chosen role, so you can earmark a cell as a builder nursery once and forget about it. Off: the role applies to the next bee only and then clears, so a one-off choice doesn't quietly govern the cell forever."))

## Adds a collapsible section to the popup and returns the container its
## rows should go into. The header button toggles it; the arrow says
## which way it will go, which is the convention everywhere else.
func _cell_section(column: VBoxContainer, title: String, open_by_default: bool) -> VBoxContainer:
	if not cell_section_open.has(title):
		cell_section_open[title] = open_by_default

	var header := Button.new()
	header.alignment = HORIZONTAL_ALIGNMENT_LEFT
	header.add_theme_font_size_override("font_size", 12)
	header.focus_mode = Control.FOCUS_NONE
	column.add_child(header)

	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 2)
	body.visible = cell_section_open[title]
	column.add_child(body)

	header.text = "%s  %s" % ["▾" if body.visible else "▸", title]
	header.pressed.connect(func():
		cell_section_open[title] = not cell_section_open[title]
		body.visible = cell_section_open[title]
		header.text = "%s  %s" % ["▾" if body.visible else "▸", title]
		# the popup was sized to the old contents, so let it shrink or
		# grow to fit what's showing now
		cell_popup.reset_size()
	)

	cell_sections[title] = body
	return body

## The nursery zone: which cells the queen lays in, and how hard she
## favours each one.
##
## The reason this is a zone rather than a per-cell setting is that
## setting twenty cells one at a time is admin, not strategy. Select a
## block of comb, put it in the zone, give it a role and a tier, and the
## proportions look after themselves from then on.
func _build_zone_controls(column: VBoxContainer) -> void:
	var row := HBoxContainer.new()
	column.add_child(row)

	var title := Label.new()
	title.text = "Nursery zone:"
	title.add_theme_font_size_override("font_size", 11)
	row.add_child(title)

	var add_btn := Button.new()
	add_btn.text = "Add"
	add_btn.add_theme_font_size_override("font_size", 11)
	add_btn.pressed.connect(func(): _request_zone(true))
	row.add_child(_with_info(add_btn, "Put the selected cells into the nursery zone. They are reserved for brood, the queen lays in them ahead of ordinary comb, and foragers leave them alone. Set what each one raises with the \"Raises\" buttons below."))

	var remove_btn := Button.new()
	remove_btn.text = "Remove"
	remove_btn.add_theme_font_size_override("font_size", 11)
	remove_btn.pressed.connect(func(): _request_zone(false))
	row.add_child(_with_info(remove_btn, "Take the selected cells back out of the zone. They go back to holding whatever arrives first."))

	var open_btn := Button.new()
	open_btn.text = "Open zone window"
	open_btn.add_theme_font_size_override("font_size", 11)
	open_btn.pressed.connect(func(): nursery_window_requested.emit())
	row.add_child(_with_info(open_btn, "Open the nursery window: how many cells are assigned to each role and tier, what the colony is made of right now, and how many bees of each kind have emerged in the last three minutes. While it is open every zone cell glows in the colour of the role it raises."))

	var tier_row := HBoxContainer.new()
	column.add_child(tier_row)

	var tier_title := Label.new()
	tier_title.text = "Priority:"
	tier_title.add_theme_font_size_override("font_size", 11)
	tier_row.add_child(tier_title)

	for tier in range(3):
		var btn := Button.new()
		btn.text = ["Low", "Medium", "High"][tier]
		btn.add_theme_font_size_override("font_size", 11)
		var tier_value: int = tier
		btn.pressed.connect(func(): _request_priority(tier_value))
		tier_row.add_child(btn)

	tier_row.add_child(_info("How much of the queen's laying this cell gets. She shares eggs between the three tiers in proportion to their weights -- by default 1 : 2 : 3 -- so a high cell receives three eggs for every one a low cell receives, and they come out interleaved rather than in streaks. Twelve high forager cells beside three low nurse cells is how you say \"mostly foragers, a few nurses\" once and then leave it alone. The weights themselves are in the tuning panel."))

## Sealing a cell. A colony with honey in it drinks the honey; this is
## how you set some aside for a hard stretch instead.
func _build_closing_controls(column: VBoxContainer) -> void:
	var row := HBoxContainer.new()
	column.add_child(row)

	var title := Label.new()
	title.text = "Sealing:"
	title.add_theme_font_size_override("font_size", 11)
	row.add_child(title)

	var close_btn := Button.new()
	close_btn.text = "Close"
	close_btn.add_theme_font_size_override("font_size", 11)
	close_btn.pressed.connect(func(): _request_close(true))
	row.add_child(_with_info(close_btn, "Seal the selected cells. Nothing can be added and nothing taken out until you open them again -- the contents are held in reserve. A sealed cell is drawn with a dark bar across it."))

	var open_btn := Button.new()
	open_btn.text = "Open"
	open_btn.add_theme_font_size_override("font_size", 11)
	open_btn.pressed.connect(func(): _request_close(false))
	row.add_child(_with_info(open_btn, "Unseal the selected cells so the colony can use what is in them again."))

	var fill_btn := Button.new()
	fill_btn.text = "Fill then close"
	fill_btn.add_theme_font_size_override("font_size", 11)
	fill_btn.pressed.connect(func(): _request_fill_close())
	row.add_child(_with_info(fill_btn, "Keep taking deposits but refuse every withdrawal, and seal the cell the moment it is full. Without this a honey cell is sipped from as fast as it is filled and never quite gets to the top, so there is never a full pot to put by. A cell in this state is drawn with a yellow bar."))

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

	# This has to write straight through to the cell. It used to be read
	# back from the cell every frame by _refresh_cell_popup while only
	# being applied when one of the buttons above was pressed -- so
	# ticking it was undone a frame later and it looked like the option
	# could not be selected at all.
	var keep_row := HBoxContainer.new()
	column.add_child(keep_row)
	keep_empty_box = CheckBox.new()
	keep_empty_box.text = "Keep this cell empty afterwards"
	keep_empty_box.add_theme_font_size_override("font_size", 11)
	keep_empty_box.toggled.connect(func(pressed: bool):
		if active_cell and is_instance_valid(active_cell):
			cell_keep_empty_requested.emit(active_cell, pressed)
			_refresh_cell_popup()
	)
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

## --- obstacle popup -----------------------------------------------
## Clicking a tree or a bank of raised ground says what it is, so the
## things bees have to walk round aren't unexplained scenery.

## --- warning banner -----------------------------------------------
## A nudge, not an interruption: it sits at the top of the screen, the
## game carries on running behind it, and it clears itself after a while
## if the player doesn't dismiss it.

const WARNING_SECONDS := 18.0

func _build_warning_banner() -> void:
	warning_panel = PanelContainer.new()
	warning_panel.set_anchors_preset(Control.PRESET_CENTER_TOP)
	warning_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	warning_panel.offset_top = 48
	warning_panel.custom_minimum_size = Vector2(520, 0)
	warning_panel.visible = false
	add_child(warning_panel)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	warning_panel.add_child(row)

	warning_label = Label.new()
	warning_label.add_theme_font_size_override("font_size", 13)
	warning_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.5))
	warning_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	warning_label.custom_minimum_size = Vector2(450, 0)
	row.add_child(warning_label)

	var close_btn := Button.new()
	close_btn.text = "×"
	close_btn.custom_minimum_size = Vector2(28, 28)
	close_btn.pressed.connect(func(): warning_panel.visible = false)
	row.add_child(close_btn)

func show_warning(text: String) -> void:
	warning_label.text = text
	warning_panel.visible = true
	warning_timer = WARNING_SECONDS

func _build_obstacle_popup() -> void:
	obstacle_popup = PopupPanel.new()
	add_child(obstacle_popup)

	obstacle_popup_label = Label.new()
	obstacle_popup_label.add_theme_font_size_override("font_size", 12)
	obstacle_popup_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	obstacle_popup_label.custom_minimum_size = Vector2(260, 0)
	obstacle_popup.add_child(obstacle_popup_label)

func show_obstacle_popup(obstacle: Node2D, screen_position: Vector2) -> void:
	obstacle_popup_label.text = "%s\n\n%s" % [obstacle.display_name(), obstacle.description()]
	obstacle_popup.position = Vector2i(screen_position + Vector2(12, -10))
	obstacle_popup.popup()

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

## --- soil popup ---------------------------------------------------

func _build_soil_popup() -> void:
	soil_popup = PopupPanel.new()
	add_child(soil_popup)

	var column := VBoxContainer.new()
	soil_popup.add_child(column)

	soil_popup_label = Label.new()
	soil_popup_label.add_theme_font_size_override("font_size", 12)
	soil_popup_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	soil_popup_label.custom_minimum_size = Vector2(280, 0)
	column.add_child(soil_popup_label)

	var row := HBoxContainer.new()
	column.add_child(row)

	var mark_btn := Button.new()
	mark_btn.text = "Mark for digging"
	mark_btn.pressed.connect(func(): soil_mark_requested.emit(true); soil_popup.hide())
	row.add_child(_with_info(mark_btn, "Flag every selected block for miners to dig out. Blocks buried behind other soil can be marked too -- miners simply cannot reach them until the ones in front are gone, so a marked seam digs itself inward layer by layer."))

	var clear_btn := Button.new()
	clear_btn.text = "Clear marks"
	clear_btn.pressed.connect(func(): soil_mark_requested.emit(false); soil_popup.hide())
	row.add_child(_with_info(clear_btn, "Take the digging flag off the selected blocks. Any digging already done is kept, so you can put the mark back later without losing the work."))

func show_soil_popup(count: int, reachable: int, screen_position: Vector2) -> void:
	var text := "%d soil block%s selected" % [count, "" if count == 1 else "s"]
	if reachable < count:
		text += "\n%d can be reached right now; the rest are buried and will be dug once the soil in front of them is gone." % reachable
	soil_popup_label.text = text
	soil_popup.position = Vector2i(screen_position + Vector2(12, -10))
	soil_popup.popup()

func show_cell_popup(cell: Node2D, screen_position: Vector2, count: int = 1) -> void:
	active_cell = cell
	selected_cell_count = count
	_refresh_cell_popup()
	cell_popup.position = Vector2i(screen_position + Vector2(12, -10))
	cell_popup.popup()

func _refresh_cell_popup() -> void:
	if active_cell == null or not is_instance_valid(active_cell):
		return
	var lines := []
	if selected_cell_count > 1:
		lines.append("%d cells selected — everything below applies to all of them" % selected_cell_count)
		lines.append("Showing: the first one")
	if not active_cell.is_built:
		lines.append("Unfinished cell -- %d%% built" % int(active_cell.build_fraction() * 100.0))
	else:
		match active_cell.content_type:
			"nectar":
				lines.append("Nectar: %d / %d" % [int(round(active_cell.amount)), int(active_cell.capacity)])
			"pollen":
				lines.append("Pollen: %d / %d" % [int(round(active_cell.amount)), int(active_cell.capacity)])
			"jelly":
				lines.append("Royal jelly: %d / %d" % [int(round(active_cell.amount)), int(active_cell.capacity)])
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
				lines.append("%s -- %d%%" % [
					"Developing gyne" if active_cell.brood_is_gyne else "Developing bee",
					int(active_cell.development_percent()),
				])
				if active_cell.brood_is_gyne:
					lines.append("Needs royal jelly, pollen and honey. Nothing else will do.")
				if active_cell.brood_fed_seconds > 0.0:
					lines.append("Fed on %s -- %ds of development left in it" % [
						"honey" if active_cell.fed_on_honey else "nectar",
						int(active_cell.brood_fed_seconds),
					])
				else:
					lines.append("Hungry -- development has stopped. It dies in %ds if nobody feeds it" % int(active_cell.seconds_until_death()))
			"corpse":
				lines.append("A larva starved here. The body blocks the cell.")
				lines.append("Being cleared: %d%% -- an architect on cell maintenance has to carry it out" % int(active_cell.clean_fraction() * 100.0))
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
	if active_cell.is_nursery_cell():
		lines.append("Nursery zone — %s priority" % ["low", "medium", "high"][clampi(active_cell.nursery_priority, 0, 2)])
	if active_cell.is_closed:
		lines.append("Sealed — nothing goes in or comes out")
	elif active_cell.fill_then_close:
		lines.append("Filling to the top, then sealing. Withdrawals refused meanwhile")
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
	gyne_box.set_pressed_no_signal(active_cell.hatch_gyne)

func _process(_delta: float) -> void:
	if warning_panel.visible:
		warning_timer -= _delta
		if warning_timer <= 0.0:
			warning_panel.visible = false
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

func _request_zone(in_zone: bool) -> void:
	if active_cell and is_instance_valid(active_cell):
		cell_zone_requested.emit(active_cell, in_zone)
		_refresh_cell_popup()

func _request_priority(tier: int) -> void:
	if active_cell and is_instance_valid(active_cell):
		cell_priority_requested.emit(active_cell, tier)
		_refresh_cell_popup()

func _request_close(closed: bool) -> void:
	if active_cell and is_instance_valid(active_cell):
		cell_close_requested.emit(active_cell, closed)
		_refresh_cell_popup()

func _request_fill_close() -> void:
	if active_cell and is_instance_valid(active_cell):
		cell_fill_close_requested.emit(active_cell)
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
	corner_texts["day"] = "Day %d" % day
	_refresh_corner()

## Honey is counted only once it's fully fanned dry -- wet mix still
## drying in a cell isn't a store the colony can use yet. Anything sealed
## into closed cells is called out separately: it's still the colony's,
## but nothing can eat it until the cells are opened again.
func update_storage(nectar: float, pollen: float, honey: float, jelly: float, sealed: float = 0.0) -> void:
	var text := "Nectar: %d   Pollen: %d   Honey: %d   Jelly: %d" % [
		int(round(nectar)), int(round(pollen)), int(round(honey)), int(round(jelly)),
	]
	if sealed > 0.5:
		text += "\n(%d sealed away in closed cells)" % int(round(sealed))
	corner_texts["stores"] = text
	_refresh_corner()

func update_population(foragers: int, nurses: int, builders: int, honey_makers: int) -> void:
	corner_texts["population"] = "Bees: %d foraging, %d nursing, %d architects, %d on honey" % [
		foragers, nurses, builders, honey_makers,
	]
	_refresh_corner()

func update_comb(text: String) -> void:
	corner_texts["comb"] = text
	_refresh_corner()

func update_energy(mean_fraction: float) -> void:
	corner_texts["energy"] = "Average energy: %d%%" % int(round(mean_fraction * 100.0))
	_refresh_corner()

## `births_per_sec` is shown per minute instead -- birth events are rare
## enough (one every 90s+ per brood cell) that a per-second figure would
## always read as an unreadable 0.0x.
func update_rates(nectar_per_sec: float, pollen_per_sec: float, births_per_sec: float) -> void:
	corner_texts["rates"] = "Rates (60s avg): Nectar +%.1f/s   Pollen +%.1f/s   Births %.2f/min" % [
		nectar_per_sec, pollen_per_sec, births_per_sec * 60.0,
	]
	_refresh_corner()

## `lines` is an array of [text, severity] pairs from main.gd.
func update_signals(lines: Array) -> void:
	shown_signals = lines
	corner_texts["signals"] = "\n".join(lines.map(func(e): return "• %s" % e[0]))
	_refresh_corner()

## Rebuilds the corner from the starred readouts. Only actually does the
## work when the result would look different, so this can be called from
## every setter without thrashing labels every frame.
func _refresh_corner() -> void:
	var signature := ""
	for key in CORNER_ORDER:
		if GameConfig.pinned_stats.has(key):
			signature += "%s=%s\n" % [key, corner_texts.get(key, "")]
	var show_signals: bool = GameConfig.pinned_stats.has("signals")
	if show_signals:
		for entry in shown_signals:
			signature += "s%d|%s\n" % [entry[1], entry[0]]
	if signature == corner_signature:
		return
	corner_signature = signature

	for child in corner_column.get_children():
		child.queue_free()

	for key in CORNER_ORDER:
		if not GameConfig.pinned_stats.has(key):
			continue
		var text: String = str(corner_texts.get(key, ""))
		if text == "":
			continue
		var label := Label.new()
		label.text = text
		label.add_theme_font_size_override("font_size", int(CORNER_SIZES.get(key, 12)))
		corner_column.add_child(label)

	if not show_signals:
		return
	for entry in shown_signals:
		var line := Label.new()
		line.text = "• %s" % entry[0]
		line.add_theme_font_size_override("font_size", 12)
		line.add_theme_color_override("font_color", SIGNAL_COLOURS[clampi(entry[1], 0, 2)])
		corner_column.add_child(line)

## Called when the player stars or unstars something in the colony
## window: the corner has to be redrawn even though no number changed.
func pinned_stats_changed() -> void:
	corner_signature = ""
	_refresh_corner()

func update_selection(bees: Array) -> void:
	shown_bees = bees
	selection_panel.visible = not bees.is_empty()
	if bees.is_empty():
		return

	_rebuild_role_controls(bees)
	_refresh_selection_text()

## The selection panel's controls, rebuilt from scratch whenever the
## selection changes.
##
## Laid out as a short column of labelled rows rather than one long strip
## of buttons. The rows answer, in order, the three things you want to
## know about a selected bee:
##
##   Job      what it is, and what else it could be
##   Doing    the sub-mode of that job, where it has one
##   Orders   the "click a spot" actions that apply to it
##
## with the backup role and the finish-first switch underneath. Roles it
## isn't doing now live inside one dropdown instead of a button each,
## which is what was making the panel wider than the screen.
func _rebuild_role_controls(bees: Array) -> void:
	for child in role_row.get_children():
		child.queue_free()

	var common_role: int = _common_role(bees)
	var first = bees[0] if is_instance_valid(bees[0]) else null
	var any_queen := false
	for b in bees:
		if is_instance_valid(b) and b.is_queen:
			any_queen = true
			break

	_build_job_row(common_role, any_queen)
	_build_doing_row(common_role, first)
	_build_orders_row(common_role, first)
	_build_fallback_row(common_role, first)

## Job: what the selection is, lit up, plus one dropdown holding every
## role it could be switched to.
func _build_job_row(common_role: int, any_queen: bool) -> void:
	var row := _labelled_row("Job")
	if common_role == -1:
		var mixed := Label.new()
		mixed.text = "mixed selection"
		mixed.add_theme_font_size_override("font_size", 11)
		mixed.add_theme_color_override("font_color", Color(0.8, 0.8, 0.6))
		row.add_child(mixed)
	else:
		row.add_child(_current_role_marker(_role_label(common_role)))

	var items: Array = []
	for entry in ROLE_BUTTONS:
		var key: String = entry.role
		if key == "automine":
			continue   # a switch on miners, not a role
		if key == "egg_layer" and not any_queen:
			continue   # queen only
		if _role_key_to_value(key) == common_role:
			continue   # already doing it
		items.append({
			"text": entry.label,
			"action": func(): role_requested.emit(key),
		})
	if not items.is_empty():
		row.add_child(_make_role_menu("Change to…", "Switch the selected bees to another job. Sub-modes for that job appear on the Doing row once they are on it.", items))

## Doing: the sub-mode of the current job, where that job has one.
func _build_doing_row(common_role: int, first) -> void:
	match common_role:
		Bee.Role.FORAGER:
			var row := _labelled_row("Doing")
			var focus: String = first.resource_type if first != null else "nectar"
			row.add_child(_toggle_button("Nectar", focus == "nectar",
				func(): focus_requested.emit("nectar"),
				"Look for nectar. Nectar is the colony's energy: bees eat it, and building comb burns it."))
			row.add_child(_toggle_button("Pollen", focus == "pollen",
				func(): focus_requested.emit("pollen"),
				"Look for pollen. Pollen is what the queen eats to lay eggs, so no pollen means no new bees."))
		Bee.Role.NURSERY:
			var row := _labelled_row("Doing")
			var mode: String = first.nurse_mode if first != null else "feed"
			for entry in NURSE_MODES:
				var value: String = entry.mode
				var key: String = entry.key
				row.add_child(_toggle_button(entry.label, mode == value,
					func(): role_requested.emit(key), _tip_for("nursery")))
		Bee.Role.BUILDER:
			var row := _labelled_row("Doing")
			var mode: String = first.architect_mode if first != null else "both"
			for entry in ARCHITECT_MODES:
				var value: String = entry.mode
				var key: String = entry.key
				row.add_child(_toggle_button(entry.label, mode == value,
					func(): role_requested.emit(key), _tip_for("builder")))
		Bee.Role.MINER:
			var row := _labelled_row("Doing")
			var on: bool = first.automine if first != null else false
			row.add_child(_toggle_button("Automine", on,
				func(): role_requested.emit("automine"), _tip_for("automine")))

## Orders: the "click this, then click a spot" actions. Grouped together
## because they all behave the same way and all need the hive or meadow
## view, which is worth learning once rather than per button.
func _build_orders_row(common_role: int, first) -> void:
	if common_role != Bee.Role.FORAGER and common_role != Bee.Role.BUILDER and common_role != Bee.Role.MINER:
		return
	var row := _labelled_row("Orders")

	match common_role:
		Bee.Role.FORAGER:
			var has_start: bool = first != null and first.has_forage_start_point()
			row.add_child(_action_button("Reset start point" if has_start else "Set start point",
				func(): forage_start_point_requested.emit(),
				"Click this, then click a spot in the meadow. The selected foragers head there first on every trip out, so you can split them across different parts of the meadow instead of them all drifting to whichever flower is nearest the entrance."))
			if GameConfig.floral_constancy_on:
				var pref: String = first.preferred_species if first != null else ""
				row.add_child(_action_button(("Flower: %s" % pref) if pref != "" else "Pick a flower",
					func(): floral_preference_requested.emit(),
					"Click this, then click a flower. The selected foragers will only ever visit that species from then on, even walking past a nearer flower of something else -- real bees do this too."))
		Bee.Role.BUILDER:
			row.add_child(_action_button("Build here",
				func(): build_cell_requested.emit(),
				"Click this, then click any open tile -- including ground that has been mined out. Hold Ctrl and keep clicking to queue up several: they are built in the order you click them, and a faint line shows that order while this bee is selected."))
			row.add_child(_action_button("Keep clear",
				func(): keep_clear_requested.emit(),
				"Click this, then click a tile to reserve it as open floor. No architect will ever build there, so you can keep a corridor through the comb or a landing area by the entrance. Clicking a reserved tile again releases it. This applies to every architect, not just this one, and the reserved tiles show whenever any architect is selected."))
			row.add_child(_action_button("Home tile",
				func(): home_cell_requested.emit(),
				"Click this, then click a tile. That tile becomes this architect's centre of operations: left to itself it fills the space around it outwards in a spiral, rather than always adding to the middle. Give two architects different home tiles and the hive grows in two places at once."))

			# Restocking needs three things chosen, so it gets its own row
			# rather than crowding the general orders.
			if first != null and first.architect_mode == "restock":
				_build_restock_row(first)
		Bee.Role.MINER:
			row.add_child(_action_button("Mine",
				func(): mine_target_requested.emit(),
				"Click this, then click a soil block for the selected miners to dig. Hold Ctrl and keep clicking to queue several: they are dug in the order you click them, and a faint line shows that order while the miner is selected."))
			row.add_child(_action_button("Dig centre",
				func(): mine_home_requested.emit(),
				"Click this, then click a tile. The selected miners will always dig whichever soil is nearest that tile, rather than whichever is nearest wherever they finished the last block. Keeps a team working through one face."))

## The restock sub-mode's own row: which cells to keep full, of what, and
## where the contents may come from.
##
## All three act on the current comb selection, which is why there is no
## "click a spot" mode here -- you select cells the ordinary way first,
## then press the button that says what they are for.
func _build_restock_row(first) -> void:
	var row := _labelled_row("Keep full")

	for resource in ["nectar", "pollen", "honey", "jelly"]:
		var value: String = resource
		var current: bool = first != null and first.restock_resource == value
		row.add_child(_toggle_button(
			resource.capitalize(), current,
			func(): restock_targets_requested.emit(value),
			"Select comb first, then press this. Those cells become the ones this architect keeps full of %s, fetching it from elsewhere in the hive whenever they run down. This is how you get a resource to sit *somewhere* -- honey beside the brood before winter, pollen within reach of the nursery -- rather than wherever the foragers happened to drop it." % resource
		))

	var source_row := _labelled_row("Take from")
	source_row.add_child(_action_button("Only these",
		func(): restock_sources_requested.emit(true),
		"Select comb first, then press this. The architect will draw only on those cells when refilling. Use it to point restocking at the outer comb and leave the rest alone."))
	source_row.add_child(_action_button("Never these",
		func(): restock_sources_requested.emit(false),
		"Select comb first, then press this. The architect will never take from those cells. This is what protects a winter store from being redistributed by your own bee."))
	source_row.add_child(_action_button("Clear orders",
		func(): restock_clear_requested.emit(),
		"Forget this architect's restocking orders entirely -- the cells it keeps full, and the sources it may use."))

	if first != null and first.has_restock_orders():
		var summary := Label.new()
		summary.text = "%d cells of %s" % [first.restock_targets.size(), first.restock_resource]
		summary.add_theme_font_size_override("font_size", 11)
		summary.add_theme_color_override("font_color", Color(0.6, 0.9, 0.7))
		source_row.add_child(summary)

## The backup role and whether a reassignment waits for the current job.
func _build_fallback_row(common_role: int, first) -> void:
	var row := _labelled_row("If idle")
	if common_role != -1:
		var current: int = first.secondary_role if first != null else -1
		row.add_child(_make_role_menu(
			"Backup: %s" % _secondary_label(current),
			"What this bee does instead of standing around whenever it genuinely has no work of its own -- a non-automine miner with no block marked, say, or a nurse with no brood to tend. It drops the backup role and returns to its own the instant real work turns up.",
			[
				{"text": "None", "action": func(): secondary_role_requested.emit("none")},
				{"text": "Forager", "action": func(): secondary_role_requested.emit("forager")},
				{"text": "Nursery", "action": func(): secondary_role_requested.emit("nursery")},
				{"text": "Architect", "action": func(): secondary_role_requested.emit("builder")},
				{"text": "Miner", "action": func(): secondary_role_requested.emit("miner")},
				{"text": "Honey maker", "action": func(): secondary_role_requested.emit("honey_maker")},
			]
		))

	var finish_box := CheckBox.new()
	finish_box.text = "Finish current task first"
	finish_box.add_theme_font_size_override("font_size", 11)
	finish_box.button_pressed = first.finish_task_first if first != null else false
	finish_box.toggled.connect(func(pressed: bool): finish_first_requested.emit(pressed))
	row.add_child(_with_info(finish_box, "On: reassigning this bee waits until it has finished what it is doing -- a forager delivers the load it is carrying, an architect finishes the cell it is on -- and the new role takes effect the moment it is free. Off: it drops everything and starts immediately."))

	# The queen's own laying rule sits here rather than in its own row --
	# it is a "what does she do when she can't lay" question, which is
	# the same question this row is about.
	if first != null and first.is_queen and common_role == Bee.Role.EGG_LAYER:
		var any_cell_box := CheckBox.new()
		any_cell_box.text = "Lay in plain comb too"
		any_cell_box.add_theme_font_size_override("font_size", 11)
		any_cell_box.button_pressed = GameConfig.queen_lays_in_any_cell
		any_cell_box.toggled.connect(func(pressed: bool): GameConfig.queen_lays_in_any_cell = pressed)
		row.add_child(_with_info(any_cell_box, "On (the default): once every nursery cell is occupied she lays into any spare undesignated cell, so laying never stalls for want of somewhere to put an egg. Off: she lays only in nursery zone cells and waits when they are full. Turn it off for exact control, and be ready to add zone cells or she stops laying."))

## One row of the panel, with its heading. Returns the box the controls
## go into.
func _labelled_row(title: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	role_row.add_child(row)

	var label := Label.new()
	label.text = "%s:" % title
	label.add_theme_font_size_override("font_size", 11)
	label.add_theme_color_override("font_color", Color(0.68, 0.74, 0.8))
	label.custom_minimum_size = Vector2(48, 0)
	row.add_child(label)
	return row

## A button that shows whether its option is the one currently in force.
## Sub-modes used to be buried in a "Doing: x" dropdown, so the only way
## to see which mode a bee was on was to read the button's own label --
## and the only way to see the alternatives was to open it.
func _toggle_button(label: String, is_current: bool, action: Callable, tip: String) -> Control:
	var button := Button.new()
	button.text = label
	button.add_theme_font_size_override("font_size", 11)
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(action)
	if is_current:
		UI.mark_as_current(button)
	return _with_info(button, tip)

func _action_button(label: String, action: Callable, tip: String) -> Control:
	var button := Button.new()
	button.text = label
	button.add_theme_font_size_override("font_size", 11)
	button.pressed.connect(action)
	return _with_info(button, tip)

func _role_label(role_value: int) -> String:
	match role_value:
		Bee.Role.FORAGER: return "Forager"
		Bee.Role.NURSERY: return "Nursery"
		Bee.Role.BUILDER: return "Architect"
		Bee.Role.MINER: return "Miner"
		Bee.Role.HONEY_MAKER: return "Honey maker"
		Bee.Role.EGG_LAYER: return "Egg layer"
		Bee.Role.IDLE: return "Idle"
	return "Unknown"

## Maps the string keys main.gd matches on back to Bee.Role values, so
## the "Change to…" menu can leave out the role a bee already has.
func _role_key_to_value(key: String) -> int:
	match key:
		"forager": return Bee.Role.FORAGER
		"nursery": return Bee.Role.NURSERY
		"builder": return Bee.Role.BUILDER
		"miner": return Bee.Role.MINER
		"honey_maker": return Bee.Role.HONEY_MAKER
		"egg_layer": return Bee.Role.EGG_LAYER
		"idle": return Bee.Role.IDLE
	return -1

## The lit-up button naming the role the selection is already on. It is
## an ordinary button rather than a label so it sits at the same height
## as everything else in the row; pressing it just reasserts the role the
## bee already has, which is harmless.
func _current_role_marker(label: String) -> Control:
	var button := Button.new()
	button.text = "● %s" % label
	button.focus_mode = Control.FOCUS_NONE
	button.tooltip_text = "This is what the selected bees are doing now."
	return UI.mark_as_current(button)

## -1 means the selection is mixed -- no role is marked as current in
## that case, since there's no single answer to what they're all doing.
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

## Menu entries for the architect dropdown. `assign_role` is true when
## the bees aren't architects yet, in which case each entry also takes
## the role, not just the mode.
##
## Written as a plain loop rather than a mapped lambda: each entry needs
## its own captured copy of the mode key, and a lambda built inside
## another lambda is a good way to end up with every entry sharing the
## last one.
func _architect_items(assign_role: bool) -> Array:
	var items: Array = []
	for entry in ARCHITECT_MODES:
		var key: String = entry.key
		var label: String = entry.label
		if assign_role:
			items.append({
				"text": "Become architect — %s" % label,
				"action": func(): role_requested.emit("builder"); role_requested.emit(key),
			})
		else:
			items.append({
				"text": label,
				"action": func(): role_requested.emit(key),
			})
	return items

func _nurse_items(assign_role: bool) -> Array:
	var items: Array = []
	for entry in NURSE_MODES:
		var key: String = entry.key
		var label: String = entry.label
		if assign_role:
			items.append({
				"text": "Become nursery — %s" % label,
				"action": func(): role_requested.emit("nursery"); role_requested.emit(key),
			})
		else:
			items.append({
				"text": label,
				"action": func(): role_requested.emit(key),
			})
	return items

func _nurse_mode_label(mode: String) -> String:
	for entry in NURSE_MODES:
		if entry.mode == mode:
			return entry.label
	return "Feed brood"

func _architect_mode_label(mode: String) -> String:
	for entry in ARCHITECT_MODES:
		if entry.mode == mode:
			return entry.label
	return "Both"

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
