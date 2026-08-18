extends CanvasLayer
## The main menu: a full-screen overlay that pauses the run behind it and
## offers a choice of starting stage.
##
## It opens by itself the first time the game is launched, and after that
## only when the player picks "Return to Main Menu" in the settings window.
## Choosing a stage sets Session.starting_level and reloads the scene
## (main.gd does the reloading, via the level_chosen signal), so every
## stage is built by the same world-building code rather than a separate
## path that could drift out of step.

const UI = preload("res://scripts/ui.gd")

signal level_chosen(level: int)

## Kept in the same order they're shown. `level` matches the keys of
## levels.gd's LEVELS dictionary, which is what actually decides what gets
## spawned -- these are the words for it.
##
## Split into two groups per TUTORIAL_PLAN.md's "Terminology" section:
## **Challenges** (`group: "challenge"`) are staged, scripted entries with
## a win condition and Dr Gallerin guiding you through it. **Starter
## modes** (`group: "starter"`) are the plain starting-point presets this
## menu always had -- no sub-stages, no win condition, no Dr Gallerin,
## just a different-sized colony to begin from. Internal level ids stay
## exactly as they were (1-5) so existing saves and the LEVELS dictionary
## don't need to change shape; only the menu's grouping and labels do.
const STAGES := [
	{
		"level": 1,
		"group": "challenge",
		"title": "Challenge 1: First Stores",
		"blurb": "Found the beginnings of a colony. Build your first cell, gather nectar, and learn how a tiny hive starts to sustain itself.",
	},
	{
		"level": 2,
		"group": "challenge",
		"title": "Challenge 2: Brood, Roles and Expansion",
		"blurb": "Grow the colony from stored food into a working hive. Lay eggs, raise specialist bees, keep nectar flowing, and expand the hive enough to support a balanced workforce.",
	},
	{
		"level": 3,
		"group": "starter",
		"title": "Starter mode 1 — A working colony",
		"blurb": "The queen, three cells, and two foragers — one on nectar, one on pollen. Both resources are coming in from the first moment.",
	},
	{
		"level": 4,
		"group": "starter",
		"title": "Starter mode 2 — Established nest",
		"blurb": "Fifteen cells and a full crew: eleven foragers (eight on nectar, three on pollen), two nurses, two comb workers on both jobs, and two miners. Enough colony that keeping it fed is the challenge, not starting it.",
	},
	{
		"level": 5,
		"group": "starter",
		"title": "Starter mode 3 — In full swing",
		"blurb": "Twenty-two foragers (sixteen on nectar, six on pollen), four nurses, three comb workers and three miners already digging. Twelve cells, four of them full of nectar and two of pollen, so the queen can lay from the first second. A colony big enough that what to do with it is the question.",
	},
]

## Shown above each group of STAGES rows, in the same order the groups
## should appear.
const GROUPS := [
	{"key": "challenge", "heading": "Challenges", "note": "Staged and scripted, with Dr Gallerin guiding you through each one."},
	{"key": "starter", "heading": "Starter modes", "note": "Plain starting points -- no sub-stages, no win condition, no Dr Gallerin."},
]

var panel: PanelContainer
var backdrop: ColorRect

func _ready() -> void:
	process_mode = PROCESS_MODE_ALWAYS   # the menu still works while paused
	layer = 20                           # above the HUD and the settings window
	visible = false
	# so the settings window's "Return to Main Menu" button can find us
	# without main.gd having to wire the two together
	add_to_group("main_menu")

	backdrop = ColorRect.new()
	backdrop.color = Color(0.05, 0.07, 0.05, 0.88)
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP   # swallow clicks on the world behind
	add_child(backdrop)

	panel = PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	panel.custom_minimum_size = Vector2(520, 0)
	add_child(panel)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	panel.add_child(column)

	var title := Label.new()
	title.text = "Meadow"
	title.add_theme_font_size_override("font_size", 30)
	column.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Choose where to start. Everything else uses your current tuning values."
	subtitle.add_theme_font_size_override("font_size", 13)
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	subtitle.custom_minimum_size = Vector2(500, 0)
	column.add_child(subtitle)

	for group in GROUPS:
		var heading := Label.new()
		heading.text = group.heading
		heading.add_theme_font_size_override("font_size", 16)
		column.add_child(heading)

		var note := Label.new()
		note.text = group.note
		note.add_theme_font_size_override("font_size", 11)
		note.add_theme_color_override("font_color", Color(0.7, 0.74, 0.68))
		note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		note.custom_minimum_size = Vector2(500, 0)
		column.add_child(note)

		for stage in STAGES:
			if stage.group == group.key:
				column.add_child(_make_stage_row(stage))

		column.add_child(HSeparator.new())

	var close_btn := Button.new()
	close_btn.text = "Back to the run"
	close_btn.custom_minimum_size = Vector2(0, 30)
	close_btn.pressed.connect(close)
	column.add_child(UI.with_info(close_btn, "Close the menu and carry on with the colony you already have. Nothing is restarted."))

func _make_stage_row(stage: Dictionary) -> Control:
	var row := VBoxContainer.new()
	row.add_theme_constant_override("separation", 2)

	var button := Button.new()
	button.text = stage.title
	button.custom_minimum_size = Vector2(0, 34)
	var level_value: int = stage.level
	button.pressed.connect(func(): _choose(level_value))
	row.add_child(button)

	var blurb := Label.new()
	blurb.text = stage.blurb
	blurb.add_theme_font_size_override("font_size", 12)
	blurb.add_theme_color_override("font_color", Color(0.78, 0.82, 0.75))
	blurb.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	blurb.custom_minimum_size = Vector2(500, 0)
	row.add_child(blurb)

	return row

func open() -> void:
	visible = true
	get_tree().paused = true

func close() -> void:
	visible = false
	get_tree().paused = false
	Session.menu_pending = false

func _choose(level: int) -> void:
	visible = false
	level_chosen.emit(level)
