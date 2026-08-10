extends CanvasLayer
## Tuning controls, collapsed behind a button in the top-right corner.
## Editing a value doesn't change bees/flowers already in the world --
## press "Restart Run" to respawn everything with the new numbers
## (they live in the GameConfig autoload, so they survive the reload).
##
## Every row carries an "i" badge explaining what the number actually
## does, so you can tune without holding the whole model in your head.

const UI = preload("res://scripts/ui.gd")

const TUNABLES := [
	{
		"key": "flower_count", "label": "Flowers", "step": 1.0, "min": 1.0,
		"tip": "How many flowers are scattered across the meadow. More flowers means less competition and shorter trips.",
	},
	{
		"key": "hive_cell_count", "label": "Starting cells", "step": 1.0, "min": 1.0,
		"tip": "How many finished comb cells the hive begins with. Builders add more on top of these.",
	},
	{
		"key": "starting_bees", "label": "Starting foragers", "step": 1.0, "min": 1.0,
		"tip": "How many foragers exist at the start of a run.",
	},
	{
		"key": "starting_nurses", "label": "Starting nurses", "step": 1.0, "min": 0.0,
		"tip": "Nurses carry laid eggs into cells. With none, eggs sit on the hive floor and the colony never grows.",
	},
	{
		"key": "starting_builders", "label": "Starting builders", "step": 1.0, "min": 0.0,
		"tip": "Builders draw new comb and shift stores between cells. With none, the hive can never expand past its starting cells.",
	},
	{
		"key": "seconds_per_day", "label": "Seconds per day", "step": 30.0, "min": 10.0,
		"tip": "Real seconds in one in-game day. This drives the day counter and how quickly bees age towards their lifespan.",
	},
	{
		"key": "nectar_recharge_rate", "label": "Nectar rchg/s", "step": 0.1, "min": 0.0,
		"tip": "How fast a drained flower refills its nectar, per second. Lower values make bees range further from the hive.",
	},
	{
		"key": "pollen_recharge_rate", "label": "Pollen rchg/s", "step": 0.05, "min": 0.0,
		"tip": "How fast a drained flower refills its pollen, per second. Deliberately slower than nectar, so pollen is the scarcer resource.",
	},
	{
		"key": "tarsal_markers_on", "label": "Tarsal markers", "toggle": true,
		"tip": "Bees leave a scent mark from their feet on every flower they land on. With this on, other bees avoid a flower marked in the last few seconds, so the colony spreads out instead of crowding the same patch. Real bumblebees and honeybees both do this.",
	},
	{
		"key": "tarsal_marker_seconds", "label": "Marker lasts s", "step": 5.0, "min": 1.0,
		"tip": "How long a scent mark keeps other bees away. Only matters when Tarsal markers is on.",
	},
	{
		"key": "bee_speed", "label": "Bee speed", "step": 10.0, "min": 10.0,
		"tip": "Flight and walking speed in pixels per second. The queen moves at a fraction of this (see Queen speed).",
	},
	{
		"key": "queen_speed_factor", "label": "Queen speed x", "step": 0.05, "min": 0.05,
		"tip": "The queen's speed as a multiple of a worker's. She is larger, so she is slower.",
	},
	{
		"key": "flower_handling_time", "label": "Handling s", "step": 0.5, "min": 0.0,
		"tip": "Seconds a bee spends on a flower before it starts gathering, representing finding its way to the nectary.",
	},
	{
		"key": "nectar_collection_rate", "label": "Nectar rate/s", "step": 0.5, "min": 0.1,
		"tip": "Nectar gathered per second once handling is finished. The flower's readout drains at this rate while you watch.",
	},
	{
		"key": "pollen_collection_rate", "label": "Pollen rate/s", "step": 0.5, "min": 0.1,
		"tip": "Pollen gathered per second once handling is finished.",
	},
	{
		"key": "deposit_time", "label": "Deposit s", "step": 0.5, "min": 0.0,
		"tip": "Seconds a forager spends emptying itself into a comb cell, once it has walked to that cell.",
	},
	{
		"key": "nectar_stomach_capacity", "label": "Nectar stomach", "step": 5.0, "min": 1.0,
		"tip": "How much nectar a forager can carry before it must return to the hive.",
	},
	{
		"key": "pollen_stomach_capacity", "label": "Pollen stomach", "step": 5.0, "min": 1.0,
		"tip": "How much pollen a forager can carry. Smaller than the nectar stomach, so pollen trips deliver less.",
	},
	{
		"key": "cell_capacity", "label": "Cell capacity", "step": 10.0, "min": 1.0,
		"tip": "How much of one resource a single comb cell holds. A cell stores nectar, or pollen, or one developing bee -- never a mix.",
	},
	{
		"key": "cell_build_time", "label": "Cell build s", "step": 10.0, "min": 5.0,
		"tip": "Builder-seconds needed to finish one cell. Two builders on the same cell halve the wall-clock time, three third it, and so on.",
	},
	{
		"key": "build_energy_burn", "label": "Build energy/s", "step": 0.1, "min": 0.0,
		"tip": "Extra energy a builder burns while building. Bees make wax from the sugar they have eaten, so comb is paid for in nectar rather than a separate wax store.",
	},
	{
		"key": "hive_interior_rings", "label": "Interior rings", "step": 1.0, "min": 2.0,
		"tip": "How many rings of open floor the hive has before the soil wall starts. This is the space comb can grow into. Takes effect on Restart Run.",
	},
	{
		"key": "hive_soil_depth", "label": "Soil depth", "step": 1.0, "min": 1.0,
		"tip": "How far the solid soil extends beyond the hollow. This is the ground the bees will be able to mine into, so deeper means more room to expand later. Takes effect on Restart Run.",
	},
	{
		"key": "cell_slow_factor", "label": "Comb speed x", "step": 0.05, "min": 0.1,
		"tip": "How much slower a bee moves while crossing comb rather than open floor. 1 means no penalty.",
	},
	{
		"key": "hive_cell_spacing", "label": "Cell spacing", "step": 1.0, "min": 4.0,
		"tip": "Distance between neighbouring cell centres. Takes effect on the next Restart Run.",
	},
	{
		"key": "hive_cell_size", "label": "Cell size", "step": 1.0, "min": 3.0,
		"tip": "How large each hexagon is drawn. Keep this a little below Cell spacing or cells will overlap.",
	},
	{
		"key": "egg_pollen_cost", "label": "Pollen per egg", "step": 5.0, "min": 1.0,
		"tip": "Pollen the queen must eat before she can lay one egg. This is the link between foraging and colony growth.",
	},
	{
		"key": "queen_eat_rate", "label": "Queen eat/s", "step": 1.0, "min": 0.1,
		"tip": "Pollen the queen consumes per second while feeding from a cell.",
	},
	{
		"key": "brood_develop_time", "label": "Brood time s", "step": 10.0, "min": 5.0,
		"tip": "Seconds a developing bee needs before it emerges as a new forager. Nurses tending the cell speed this up.",
	},
	{
		"key": "tending_speed_bonus", "label": "Tending bonus", "step": 0.5, "min": 1.0,
		"tip": "Development speed multiplier while a nursery bee is tending the cell.",
	},
	{
		"key": "bee_lifespan_days", "label": "Lifespan days", "step": 5.0, "min": 1.0,
		"tip": "In-game days a bee lives before dying of old age. The number beside each bee is its days remaining.",
	},
	{
		"key": "energy_capacity", "label": "Energy cap", "step": 10.0, "min": 10.0,
		"tip": "Maximum energy a bee holds. Bees dim as this runs down and die at zero.",
	},
	{
		"key": "energy_burn_rate", "label": "Energy burn/s", "step": 0.1, "min": 0.0,
		"tip": "Energy every bee burns per second just by being alive. Foragers refuel at the comb when they deposit.",
	},
]

var value_labels: Dictionary = {}
var panel: PanelContainer
var toggle_button: Button

func _ready() -> void:
	process_mode = PROCESS_MODE_ALWAYS
	layer = 10   # draw on top of the world

	var vp := get_viewport().get_visible_rect().size

	# Anchored to the top-right corner so it tracks window resizing.
	# hud.gd keeps this width clear for us, so the two bars can't overlap.
	toggle_button = Button.new()
	toggle_button.text = "Tuning ▾"
	toggle_button.custom_minimum_size = Vector2(92, 26)
	toggle_button.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	toggle_button.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	toggle_button.offset_right = -8
	toggle_button.offset_top = 8
	toggle_button.tooltip_text = "Open the tuning panel. Changing a value here affects bees and flowers created from then on -- press Restart Run to rebuild the whole world with the new numbers."
	toggle_button.pressed.connect(_toggle_panel)
	add_child(toggle_button)

	panel = PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	panel.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	panel.offset_right = -8
	panel.offset_top = 40
	panel.custom_minimum_size = Vector2(290, 0)
	panel.visible = false
	add_child(panel)

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(290, min(500.0, vp.y - 80.0))
	panel.add_child(scroll)

	var column := VBoxContainer.new()
	scroll.add_child(column)

	for entry in TUNABLES:
		# guard against a renamed setting leaving a dead row behind --
		# that used to crash the panel on startup with a confusing error
		if GameConfig.get(entry.key) == null:
			push_warning("Tuning panel refers to a missing setting: %s" % entry.key)
			continue
		if entry.get("toggle", false):
			column.add_child(_make_toggle_row(entry))
		else:
			column.add_child(_make_row(entry))

	var restart_row := HBoxContainer.new()
	column.add_child(restart_row)

	var restart_btn := Button.new()
	restart_btn.text = "Restart Run"
	restart_btn.pressed.connect(_on_restart_pressed)
	restart_row.add_child(UI.with_info(restart_btn, "Rebuild the meadow and hive from scratch using the current values above. Everything in progress is lost; the tuning numbers themselves are kept."))

	var level1_btn := Button.new()
	level1_btn.text = "Level 1"
	level1_btn.pressed.connect(_on_level1_pressed)
	restart_row.add_child(UI.with_info(level1_btn, "Restart with the same conditions, but start with just the queen -- no foragers, no nurses, no builders, and no comb cells. Everything has to be raised or built from scratch."))

func _toggle_panel() -> void:
	panel.visible = not panel.visible
	toggle_button.text = "Tuning ▴" if panel.visible else "Tuning ▾"

func _make_row(entry: Dictionary) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 3)

	var lbl := Label.new()
	lbl.add_theme_font_size_override("font_size", 11)
	lbl.custom_minimum_size = Vector2(140, 0)
	lbl.text = "%s: %s" % [entry.label, _format_value(GameConfig.get(entry.key))]
	value_labels[entry.key] = lbl
	row.add_child(lbl)

	row.add_child(UI.info_badge(entry.tip))

	var minus := Button.new()
	minus.text = "-"
	minus.custom_minimum_size = Vector2(26, 24)
	minus.pressed.connect(func(): _adjust(entry, -entry.step))
	row.add_child(minus)

	var plus := Button.new()
	plus.text = "+"
	plus.custom_minimum_size = Vector2(26, 24)
	plus.pressed.connect(func(): _adjust(entry, entry.step))
	row.add_child(plus)

	return row

## An on/off setting rather than a number, shown as a checkbox. Takes
## effect immediately -- no Restart Run needed.
func _make_toggle_row(entry: Dictionary) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 3)

	var box := CheckBox.new()
	box.text = entry.label
	box.add_theme_font_size_override("font_size", 11)
	box.button_pressed = GameConfig.get(entry.key)
	var key: String = entry.key
	box.toggled.connect(func(pressed: bool): GameConfig.set(key, pressed))
	row.add_child(box)
	row.add_child(UI.info_badge(entry.tip))
	return row

func _adjust(entry: Dictionary, delta: float) -> void:
	var new_value: float = GameConfig.get(entry.key) + delta
	new_value = max(new_value, entry.min)
	GameConfig.set(entry.key, new_value)
	value_labels[entry.key].text = "%s: %s" % [entry.label, _format_value(new_value)]

func _format_value(v) -> String:
	if v == int(v):
		return str(int(v))
	return "%.2f" % v

func _on_restart_pressed() -> void:
	GameConfig.level1_mode = false
	_restart()

func _on_level1_pressed() -> void:
	GameConfig.level1_mode = true
	_restart()

func _restart() -> void:
	get_tree().paused = false
	Engine.time_scale = 1.0
	GameConfig.sim_time = 0.0
	get_tree().reload_current_scene()
