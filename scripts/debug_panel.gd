extends CanvasLayer
## Tuning controls, collapsed behind a button in the top-right corner.
## Editing a value doesn't change bees/flowers already in the world --
## press "Restart Run" to respawn everything with the new numbers
## (they live in the GameConfig autoload, so they survive the reload).
##
## The settings are grouped into collapsible sections, because the flat
## list had grown long enough that finding anything meant scrolling past
## everything. Sections start closed apart from the first, so opening the
## panel shows a short menu rather than a wall of numbers.
##
## Every row carries an "i" badge explaining what the number actually
## does, so you can tune without holding the whole model in your head.
## Those badges can be switched off once you know your way around -- see
## the Interface section.

const UI = preload("res://scripts/ui.gd")

## Section order here is the order they appear in the panel.
const CATEGORIES := [
	"World & start",
	"Flowers",
	"Foraging",
	"Hive & comb",
	"Brood & the queen",
	"Honey",
	"Mining",
	"Bee life",
	"Interface",
]

const TUNABLES := [
	# --- World & start ---
	{
		"key": "hive_cell_count", "label": "Starting cells", "step": 1.0, "min": 1.0,
		"category": "World & start",
		"tip": "How many finished comb cells the hive begins with. Builders add more on top of these.",
	},
	{
		"key": "starting_bees", "label": "Starting foragers", "step": 1.0, "min": 1.0,
		"category": "World & start",
		"tip": "How many foragers exist at the start of a run.",
	},
	{
		"key": "starting_nurses", "label": "Starting nurses", "step": 1.0, "min": 0.0,
		"category": "World & start",
		"tip": "Nurses feed developing larvae. Brood does not develop at all without one, so a colony with no nurse never grows.",
	},
	{
		"key": "starting_builders", "label": "Starting builders", "step": 1.0, "min": 0.0,
		"category": "World & start",
		"tip": "Builders draw new comb and shift stores between cells. With none, the hive can only expand once you assign a bee to build.",
	},
	{
		"key": "starting_honey_makers", "label": "Starting honey makers", "step": 1.0, "min": 0.0,
		"category": "World & start",
		"tip": "Honey makers turn stored nectar into honey. None to begin with by default -- a young colony needs the nectar as it is.",
	},
	{
		"key": "seconds_per_day", "label": "Seconds per day", "step": 30.0, "min": 10.0,
		"category": "World & start",
		"tip": "Real seconds in one in-game day. This drives the day counter and how quickly bees age towards their lifespan.",
	},

	# --- Flowers ---
	{
		"key": "flower_count", "label": "Flowers", "step": 1.0, "min": 1.0,
		"category": "Flowers",
		"tip": "How many flowers are scattered across the meadow. More flowers means less competition and shorter trips.",
	},
	{
		"key": "nectar_recharge_rate", "label": "Nectar rchg/s", "step": 0.1, "min": 0.0,
		"category": "Flowers",
		"tip": "How fast a drained flower refills its nectar, per second. Lower values make bees range further from the hive.",
	},
	{
		"key": "pollen_recharge_rate", "label": "Pollen rchg/s", "step": 0.05, "min": 0.0,
		"category": "Flowers",
		"tip": "How fast a drained flower refills its pollen, per second. Deliberately slower than nectar, so pollen is the scarcer resource.",
	},
	{
		"key": "tarsal_markers_on", "label": "Tarsal markers", "toggle": true,
		"category": "Flowers",
		"tip": "Bees leave a scent mark from their feet on every flower they land on. With this on, other bees avoid a flower marked in the last few seconds, so the colony spreads out instead of crowding the same patch. Real bumblebees and honeybees both do this.",
	},
	{
		"key": "tarsal_marker_seconds", "label": "Marker lasts s", "step": 5.0, "min": 1.0,
		"category": "Flowers",
		"tip": "How long a scent mark keeps other bees away. Only matters when Tarsal markers is on.",
	},
	{
		"key": "floral_constancy_on", "label": "Floral constancy", "toggle": true,
		"category": "Flowers",
		"tip": "Lets you pin a forager to one flower species via 'Set preference' in its selection panel -- it will only ever visit that species from then on. Off by default; existing preferences are kept even if you turn this off, they just stop being offered as a new option.",
	},

	# --- Foraging ---
	{
		"key": "bee_speed", "label": "Bee speed", "step": 10.0, "min": 10.0,
		"category": "Foraging",
		"tip": "Flight and walking speed in pixels per second. The queen moves at a fraction of this (see Queen speed).",
	},
	{
		"key": "flower_handling_time", "label": "Handling s", "step": 0.5, "min": 0.0,
		"category": "Foraging",
		"tip": "Seconds a bee spends on a flower before it starts gathering, representing finding its way to the nectary.",
	},
	{
		"key": "nectar_collection_rate", "label": "Nectar rate/s", "step": 0.5, "min": 0.1,
		"category": "Foraging",
		"tip": "Nectar gathered per second once handling is finished. The flower's readout drains at this rate while you watch.",
	},
	{
		"key": "pollen_collection_rate", "label": "Pollen rate/s", "step": 0.5, "min": 0.1,
		"category": "Foraging",
		"tip": "Pollen gathered per second once handling is finished.",
	},
	{
		"key": "deposit_time", "label": "Deposit s", "step": 0.5, "min": 0.0,
		"category": "Foraging",
		"tip": "Seconds a forager spends emptying itself into a comb cell, once it has walked to that cell.",
	},
	{
		"key": "nectar_stomach_capacity", "label": "Nectar stomach", "step": 5.0, "min": 1.0,
		"category": "Foraging",
		"tip": "How much nectar a forager can carry before it must return to the hive.",
	},
	{
		"key": "pollen_stomach_capacity", "label": "Pollen stomach", "step": 5.0, "min": 1.0,
		"category": "Foraging",
		"tip": "How much pollen a forager can carry. Smaller than the nectar stomach, so pollen trips deliver less.",
	},

	# --- Hive & comb ---
	{
		"key": "cell_capacity", "label": "Cell capacity", "step": 10.0, "min": 1.0,
		"category": "Hive & comb",
		"tip": "How much of one resource a single comb cell holds. A cell stores nectar, or pollen, or honey, or one developing bee -- never a mix.",
	},
	{
		"key": "cell_build_time", "label": "Cell build s", "step": 10.0, "min": 5.0,
		"category": "Hive & comb",
		"tip": "Builder-seconds needed to finish one cell. Two builders on the same cell halve the wall-clock time, three third it, and so on.",
	},
	{
		"key": "build_energy_burn", "label": "Build energy/s", "step": 0.1, "min": 0.0,
		"category": "Hive & comb",
		"tip": "Extra energy a builder burns while building. Bees make wax from the sugar they have eaten, so comb is paid for in nectar rather than a separate wax store.",
	},
	{
		"key": "hive_interior_rings", "label": "Interior rings", "step": 1.0, "min": 2.0,
		"category": "Hive & comb",
		"tip": "How many rings of open floor the hive has before the soil wall starts. This is the space comb can grow into. Takes effect on Restart Run.",
	},
	{
		"key": "hive_soil_depth", "label": "Soil depth", "step": 1.0, "min": 1.0,
		"category": "Hive & comb",
		"tip": "How far the diggable soil extends beyond the hollow. Deeper means more room to mine into later. Takes effect on Restart Run.",
	},
	{
		"key": "hive_rock_rings", "label": "Bedrock rings", "step": 1.0, "min": 1.0,
		"category": "Hive & comb",
		"tip": "Rings of solid rock wrapped round the outside of the soil. Rock cannot be marked, mined or walked through, so this is the hard outer limit of how far the colony can ever spread. Takes effect on Restart Run.",
	},
	{
		"key": "cell_slow_factor", "label": "Comb speed x", "step": 0.05, "min": 0.1,
		"category": "Hive & comb",
		"tip": "How much slower a bee moves while crossing comb rather than open floor. 1 means no penalty.",
	},
	{
		"key": "hive_cell_spacing", "label": "Cell spacing", "step": 1.0, "min": 4.0,
		"category": "Hive & comb",
		"tip": "Distance between neighbouring cell centres. Takes effect on the next Restart Run.",
	},
	{
		"key": "hive_cell_size", "label": "Cell size", "step": 1.0, "min": 3.0,
		"category": "Hive & comb",
		"tip": "How large each hexagon is drawn. Keep this a little below Cell spacing or cells will overlap.",
	},

	# --- Brood & the queen ---
	{
		"key": "egg_pollen_cost", "label": "Pollen per egg", "step": 5.0, "min": 1.0,
		"category": "Brood & the queen",
		"tip": "Pollen the queen must eat before she can lay one egg. This is the link between foraging and colony growth.",
	},
	{
		"key": "queen_eat_rate", "label": "Queen eat/s", "step": 1.0, "min": 0.1,
		"category": "Brood & the queen",
		"tip": "Pollen the queen consumes per second while feeding from a cell.",
	},
	{
		"key": "queen_speed_factor", "label": "Queen speed x", "step": 0.05, "min": 0.05,
		"category": "Brood & the queen",
		"tip": "The queen's speed as a multiple of a worker's. She is larger, so she is slower.",
	},
	{
		"key": "brood_develop_time", "label": "Brood time s", "step": 10.0, "min": 5.0,
		"category": "Brood & the queen",
		"tip": "Seconds of development a larva needs before it emerges. This clock only runs while the larva has food in it, so brood in an unnursed colony simply stops.",
	},
	{
		"key": "brood_feed_seconds", "label": "Feed lasts s", "step": 5.0, "min": 1.0,
		"category": "Brood & the queen",
		"tip": "How many seconds of development one feed of pollen and nectar buys a larva. When it runs out the larva stops developing until a nurse comes back.",
	},
	{
		"key": "brood_feed_seconds_honey", "label": "Honey feed s", "step": 5.0, "min": 1.0,
		"category": "Brood & the queen",
		"tip": "As above, but for a feed of pollen and honey. Honey is denser, so it carries the larva further -- which is much of the point of making it.",
	},
	{
		"key": "brood_feed_pollen", "label": "Pollen per feed", "step": 1.0, "min": 0.0,
		"category": "Brood & the queen",
		"tip": "Pollen a nurse drops into a cell per feed. Pollen is the protein and is needed for every feed, whatever the carbohydrate.",
	},
	{
		"key": "brood_feed_nectar", "label": "Nectar per feed", "step": 1.0, "min": 0.0,
		"category": "Brood & the queen",
		"tip": "Nectar used per feed when the colony has no honey to hand.",
	},
	{
		"key": "brood_feed_honey", "label": "Honey per feed", "step": 0.5, "min": 0.0,
		"category": "Brood & the queen",
		"tip": "Honey used per feed. Less than the nectar equivalent, and it lasts the larva longer.",
	},
	{
		"key": "brood_feed_threshold", "label": "Top up below s", "step": 1.0, "min": 0.0,
		"category": "Brood & the queen",
		"tip": "A nurse tops a larva back up once its remaining food drops below this, rather than waiting for it to stall completely.",
	},
	{
		"key": "tending_speed_bonus", "label": "Tending bonus", "step": 0.5, "min": 1.0,
		"category": "Brood & the queen",
		"tip": "Development speed multiplier while a nursery bee is standing over the cell. It only multiplies time the larva has food for -- tending an unfed larva does nothing.",
	},

	# --- Honey ---
	{
		"key": "honey_cell_capacity", "label": "Honey per cell", "step": 10.0, "min": 1.0,
		"category": "Honey",
		"tip": "How much honey one cell holds. Honey is stored separately from raw nectar so the two can be tuned apart.",
	},
	{
		"key": "honey_energy_factor", "label": "Honey energy x", "step": 0.5, "min": 1.0,
		"category": "Honey",
		"tip": "How many times more energy a unit of honey gives a bee than a unit of nectar. This is why a colony bothers converting: the same cell feeds several times as many bees.",
	},
	{
		"key": "nectar_per_honey", "label": "Nectar per honey", "step": 0.5, "min": 1.0,
		"category": "Honey",
		"tip": "Units of nectar consumed to make one unit of honey mix. Above 1 this is a concentration step -- thin nectar in, dense store out.",
	},
	{
		"key": "honey_chew_time", "label": "Chewing s", "step": 1.0, "min": 0.0,
		"category": "Honey",
		"tip": "Seconds a honey maker spends working enzymes into a load of nectar before it can spit the mix into a cell.",
	},
	{
		"key": "honey_ripen_time", "label": "Fanning s", "step": 5.0, "min": 1.0,
		"category": "Honey",
		"tip": "Bee-seconds of wing-fanning needed to evaporate the water out of one cell of mix. Several bees fanning the same cell share the work. Until it is done the cell holds wet mix, not honey, and nobody can eat it.",
	},
	{
		"key": "honey_rewet_factor", "label": "Re-wet x", "step": 0.1, "min": 0.0,
		"category": "Honey",
		"tip": "Adding fresh wet mix to a part-dried cell sets its drying back to this fraction of the progress it had. Low values make topping cells up expensive.",
	},

	# --- Mining ---
	{
		"key": "block_mine_time", "label": "Block dig s", "step": 10.0, "min": 5.0,
		"category": "Mining",
		"tip": "Miner-seconds needed to break down one soil block. Several miners on one block share the work, exactly like builders on a cell.",
	},
	{
		"key": "miner_dirt_capacity", "label": "Dirt capacity", "step": 5.0, "min": 1.0,
		"category": "Mining",
		"tip": "How much spoil a miner can hold before it has to carry it outside. Real excavation does not vanish.",
	},
	{
		"key": "dirt_fill_rate", "label": "Dirt/s", "step": 0.1, "min": 0.0,
		"category": "Mining",
		"tip": "Spoil a miner accumulates per second while digging.",
	},
	{
		"key": "dirt_dump_time", "label": "Dumping s", "step": 0.5, "min": 0.0,
		"category": "Mining",
		"tip": "Seconds a miner spends outside the hive emptying a load of spoil.",
	},

	# --- Bee life ---
	{
		"key": "bee_lifespan_days", "label": "Lifespan days", "step": 5.0, "min": 1.0,
		"category": "Bee life",
		"tip": "In-game days a bee lives before dying of old age. The queen is exempt -- losing her would silently end the colony.",
	},
	{
		"key": "energy_capacity", "label": "Energy cap", "step": 10.0, "min": 10.0,
		"category": "Bee life",
		"tip": "Maximum energy a bee holds. Bees dim as this runs down and die at zero.",
	},
	{
		"key": "energy_burn_rate", "label": "Energy burn/s", "step": 0.1, "min": 0.0,
		"category": "Bee life",
		"tip": "Energy every bee burns per second just by being alive. Bees refuel from the comb, eating honey first where there is any.",
	},

	# --- Interface ---
	{
		"key": "show_info_badges", "label": "Show info icons", "toggle": true,
		"category": "Interface",
		"tip": "Show the small round 'i' buttons next to controls. Turn them off once you know what everything does and the panels get a lot quieter. Takes effect immediately.",
	},
]

var value_labels: Dictionary = {}
var panel: PanelContainer
var toggle_button: Button
## category name -> the VBox holding its rows, so the header button can
## show and hide it
var sections: Dictionary = {}

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
	panel.custom_minimum_size = Vector2(300, 0)
	panel.visible = false
	add_child(panel)

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(300, min(560.0, vp.y - 80.0))
	panel.add_child(scroll)

	var column := VBoxContainer.new()
	scroll.add_child(column)

	_build_actions(column)

	# First section open, the rest closed, so opening the panel shows a
	# short menu of headings rather than every number at once.
	var first := true
	for category in CATEGORIES:
		var rows := _rows_in(category)
		if rows.is_empty():
			continue
		column.add_child(_make_section(category, rows, first))
		first = false

func _rows_in(category: String) -> Array:
	var found: Array = []
	for entry in TUNABLES:
		if entry.get("category", "") != category:
			continue
		# guard against a renamed setting leaving a dead row behind --
		# that used to crash the panel on startup with a confusing error
		if GameConfig.get(entry.key) == null:
			push_warning("Tuning panel refers to a missing setting: %s" % entry.key)
			continue
		found.append(entry)
	return found

## A clickable heading with its rows underneath, hidden until the heading
## is clicked.
func _make_section(category: String, entries: Array, start_open: bool) -> Control:
	var wrapper := VBoxContainer.new()
	wrapper.add_theme_constant_override("separation", 0)

	var body := VBoxContainer.new()
	body.visible = start_open

	var header := Button.new()
	header.text = "%s  %s" % ["▾" if start_open else "▸", category]
	header.alignment = HORIZONTAL_ALIGNMENT_LEFT
	header.custom_minimum_size = Vector2(0, 24)
	header.add_theme_font_size_override("font_size", 12)
	header.pressed.connect(func():
		body.visible = not body.visible
		header.text = "%s  %s" % ["▾" if body.visible else "▸", category]
	)
	wrapper.add_child(header)
	wrapper.add_child(body)

	for entry in entries:
		if entry.get("toggle", false):
			body.add_child(_make_toggle_row(entry))
		else:
			body.add_child(_make_row(entry))

	sections[category] = body
	return wrapper

## Restart, stage select and the main menu, kept at the top of the panel
## so they don't drift below a growing list of settings.
func _build_actions(column: VBoxContainer) -> void:
	var restart_row := HBoxContainer.new()
	column.add_child(restart_row)

	var restart_btn := Button.new()
	restart_btn.text = "Restart Run"
	restart_btn.pressed.connect(_on_restart_pressed)
	restart_row.add_child(UI.with_info(restart_btn, "Rebuild the meadow and hive from scratch using the current values above, at whichever starting stage you last chose. Everything in progress is lost; the tuning numbers themselves are kept."))

	var menu_btn := Button.new()
	menu_btn.text = "Return to Main Menu"
	menu_btn.pressed.connect(_on_main_menu_pressed)
	restart_row.add_child(UI.with_info(menu_btn, "Pause and go back to the main menu, where you can start a fresh run at Level 1 (the queen alone), Level 2 (queen, one nectar forager, one cell) or Level 3 (queen, two foragers, three cells). You can also close the menu again and carry on with the run you have."))

	column.add_child(HSeparator.new())

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
	box.toggled.connect(func(pressed: bool):
		GameConfig.set(key, pressed)
		if key == "show_info_badges":
			# applies to every badge already on screen, not just new ones
			UI.refresh_badge_visibility(self)
	)
	row.add_child(box)
	row.add_child(UI.info_badge(entry.tip))
	return row

func _adjust(entry: Dictionary, delta: float) -> void:
	var new_value: float = GameConfig.get(entry.key) + delta
	new_value = max(new_value, entry.min)
	GameConfig.set(entry.key, new_value)
	value_labels[entry.key].text = "%s: %s" % [entry.label, _format_value(new_value)]

func _format_value(v) -> String:
	if v is bool:
		return "on" if v else "off"
	if v == int(v):
		return str(int(v))
	return "%.2f" % v

func _on_restart_pressed() -> void:
	_restart()

## main.gd adds the menu to the "main_menu" group, so the panel can reach
## it without the two needing to know about each other directly.
func _on_main_menu_pressed() -> void:
	var menus := get_tree().get_nodes_in_group("main_menu")
	if menus.is_empty():
		push_warning("No main menu in the scene to return to")
		return
	panel.visible = false
	toggle_button.text = "Tuning ▾"
	menus[0].open()

func _restart() -> void:
	get_tree().paused = false
	Engine.time_scale = 1.0
	GameConfig.sim_time = 0.0
	get_tree().reload_current_scene()
