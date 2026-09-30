extends PanelContainer
## The developer table (plans/now/brood-spine.md BS-5, decision 3): the
## current run's availability sheet, read-only. One row per skill with its
## source (start / tree / unavailable) and the reason in words, then one row
## per skill-gated role and per game feature a skill depends on.
##
## The sheet is recomputed when the table opens, never per frame, through
## RunAvailability.sheet_for(Levels.get_level(Session.starting_level)) as
## main.gd computes it; the run's progression is passed only so a feature
## that is off shows as such (feature_valid), never as a second answer to
## "is this owned". The sheet holds keys; the sentences live here. Nothing
## here edits the sheet -- that is BS-6.
##
## Built by debug_panel.gd, only while Session.developer_mode is on, and
## drawn over the settings window inside its own CanvasLayer.

const RunAvailability = preload("res://scripts/run_availability.gd")
const Levels = preload("res://scripts/levels.gd")
const Roles = preload("res://scripts/roles.gd")
const UiTheme = preload("res://scripts/ui_theme.gd")

## Every reason key run_availability.gd can put in a row, in words.
## tests/source_checks.py fails a key with no sentence here.
const REASON_TEXT := {
	RunAvailability.REASON_BASELINE: "Always on: every colony has it.",
	RunAvailability.REASON_RUN_GRANT: "Granted from the start by this run's skill_grants.",
	RunAvailability.REASON_SEEDED_ROLE: "The run starts with bees in the role this skill unlocks.",
	RunAvailability.REASON_RUN_BAN: "Banned in this run by its skill_bans.",
	RunAvailability.REASON_TREE: "Left to be bought in the skill tree.",
	RunAvailability.REASON_FEATURE_OFF: "Needs a part of the game that is off, or not built yet, in this run.",
	RunAvailability.REASON_FEATURE_ON: "On in this run.",
}

const SOURCE_TEXT := {
	RunAvailability.SOURCE_START: "at the start",
	RunAvailability.SOURCE_TREE: "in the tree",
	RunAvailability.SOURCE_UNAVAILABLE: "not available",
}

const COLUMNS := ["Name", "Source", "Why", "Introduced at stage", "Free at stage"]
## The two stage columns are not in the sheet yet; the table says so rather
## than leaving them blank.
const NOT_YET := "not yet available"

var title_label: Label
var grid: GridContainer

func _init() -> void:
	theme = UiTheme.build_theme()
	add_theme_stylebox_override("panel", UiTheme.panel_stylebox())
	visible = false
	set_anchors_preset(Control.PRESET_FULL_RECT)
	offset_left = 40
	offset_top = 40
	offset_right = -40
	offset_bottom = -40

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 6)
	add_child(column)

	var header := HBoxContainer.new()
	column.add_child(header)
	title_label = Label.new()
	title_label.theme_type_variation = "Heading"
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title_label)
	var close_btn := Button.new()
	close_btn.text = "×"
	close_btn.custom_minimum_size = Vector2(26, 22)
	close_btn.focus_mode = Control.FOCUS_NONE
	close_btn.pressed.connect(hide)
	header.add_child(close_btn)

	var intro := Label.new()
	intro.text = "Developer mode, read-only: what this run starts owning, leaves to the skill tree or does not offer, and why. Editing comes later."
	intro.theme_type_variation = "Small"
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(intro)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	column.add_child(scroll)
	grid = GridContainer.new()
	grid.columns = COLUMNS.size()
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 2)
	scroll.add_child(grid)

## Recomputes the sheet and shows it.
func open() -> void:
	_fill()
	show()

func _fill() -> void:
	for child in grid.get_children():
		grid.remove_child(child)
		child.queue_free()
	title_label.text = "Run availability -- level %d" % Session.starting_level
	var sheet: Dictionary = RunAvailability.sheet_for(Levels.get_level(Session.starting_level), Session.progression)

	for heading in COLUMNS:
		_cell(heading, "Body")
	var skills: Dictionary = sheet.get("skills", {})
	for skill_id in skills:
		_row(RunAvailability.skill_label(skill_id), skills[skill_id])
	var roles: Dictionary = sheet.get("roles", {})
	for role_key in roles:
		_row("Role: %s" % Roles.label_for(Roles.id_for_key(role_key)), roles[role_key])
	var features: Dictionary = sheet.get("features", {})
	for feature_id in features:
		_row("Feature: %s" % feature_id, features[feature_id])

func _row(row_name: String, row: Dictionary) -> void:
	_cell(row_name, "Small")
	_cell(SOURCE_TEXT.get(row.get("source", ""), str(row.get("source", ""))), "Small")
	_cell(REASON_TEXT.get(row.get("reason", ""), str(row.get("reason", ""))), "Small")
	_cell(NOT_YET, "Small")
	_cell(NOT_YET, "Small")

func _cell(text: String, variation: String) -> void:
	var label := Label.new()
	label.text = text
	label.theme_type_variation = variation
	grid.add_child(label)
