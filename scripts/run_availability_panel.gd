extends PanelContainer
## The developer table (plans/now/brood-spine.md BS-5, decision 3): the
## availability sheet of the level being viewed. One row per skill with its
## source (start / tree / unavailable) and the reason in words, then one row
## per skill-gated role and per game feature a skill depends on.
##
## The sheet is recomputed when the table opens or a row is edited, never per
## frame, through RunAvailability.sheet_for(DeveloperOverrides.apply(...)) as
## main.gd computes it at a run start; the run's progression is passed only
## so a feature that is off shows as such (feature_valid), never as a second
## answer to "is this owned". The sheet holds keys; the sentences live here.
##
## BS-6: a skill row's source is a button cycling the states the level's
## skill_grants and skill_bans can reach -- start, tree (only if the level
## leaves it to the tree), unavailable -- written to DeveloperOverrides'
## user:// file, so the next run of that level starts with it. Baseline,
## seeded-role, cut and already-unavailable rows have no button: no grant or
## ban edit can change them safely. An edited row is marked; "Reset to the game's data"
## deletes the file. Scenario runs (SCENARIO_LEVEL_ID) are never editable.
##
## Built by debug_panel.gd, only while Session.developer_mode is on, and
## drawn over the settings window inside its own CanvasLayer.

const RunAvailability = preload("res://scripts/run_availability.gd")
const DeveloperOverrides = preload("res://scripts/developer_overrides.gd")
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
	RunAvailability.REASON_CUT: "Cut from this build: kept in the catalogue but never offered.",
	RunAvailability.REASON_FEATURE_OFF: "Needs a part of the game that is off, or not built yet, in this run.",
	RunAvailability.REASON_FEATURE_ON: "On in this run.",
}

const FEATURE_LABELS := {
	"feature.predators": "Predators",
	"feature.weather": "Weather",
	"feature.seasons": "Seasons",
	"feature.fog_of_war": "Fog of war",
	"feature.disease": "Disease",
	"feature.drought": "Drought",
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
const EDITED_MARK := " (edited)"

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
	var reset_btn := Button.new()
	reset_btn.text = "Reset to the game's data"
	reset_btn.focus_mode = Control.FOCUS_NONE
	reset_btn.pressed.connect(_reset)
	header.add_child(reset_btn)
	var close_btn := Button.new()
	close_btn.text = "×"
	close_btn.custom_minimum_size = Vector2(26, 22)
	close_btn.focus_mode = Control.FOCUS_NONE
	close_btn.pressed.connect(hide)
	header.add_child(close_btn)

	var intro := Label.new()
	intro.text = "Developer mode: what a run of this level starts owning, leaves to the skill tree or does not offer, and why. Click a skill's source to change what the next run of this level starts with; edits stay on this machine and scenario runs never use them."
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
	var level_id: int = Session.starting_level
	title_label.text = "Run availability -- level %d" % level_id
	var level: Dictionary = Levels.get_level(level_id)
	var editable: bool = level_id != Levels.SCENARIO_LEVEL_ID
	var own_skills: Dictionary = RunAvailability.sheet_for(level, Session.progression).get("skills", {})
	var edited_level: Dictionary = DeveloperOverrides.apply(level_id, level) if editable else level
	var sheet: Dictionary = RunAvailability.sheet_for(edited_level, Session.progression)

	for heading in COLUMNS:
		_cell(heading, "Body")
	var skills: Dictionary = sheet.get("skills", {})
	for skill_id in skills:
		var row: Dictionary = skills[skill_id]
		var edits: Array = _edit_cycle(own_skills.get(skill_id, row)) if editable else []
		if edits.is_empty():
			_row(RunAvailability.skill_label(skill_id), row)
			continue
		var edit: String = DeveloperOverrides.edit_for(level_id, skill_id)
		var row_name: String = RunAvailability.skill_label(skill_id)
		if edit != DeveloperOverrides.EDIT_NONE:
			row_name += EDITED_MARK
		_cell(row_name, "Small")
		var source_btn := Button.new()
		source_btn.text = SOURCE_TEXT.get(row.get("source", ""), str(row.get("source", "")))
		source_btn.focus_mode = Control.FOCUS_NONE
		var next_edit: String = edits[(edits.find(edit) + 1) % edits.size()]
		source_btn.pressed.connect(_set_edit.bind(level_id, skill_id, next_edit))
		grid.add_child(source_btn)
		_cell(REASON_TEXT.get(row.get("reason", ""), str(row.get("reason", ""))), "Small")
		_cell(NOT_YET, "Small")
		_cell(NOT_YET, "Small")
	var roles: Dictionary = sheet.get("roles", {})
	for role_key in roles:
		_row("Role: %s" % Roles.label_for(Roles.id_for_key(role_key)), roles[role_key])
	var features: Dictionary = sheet.get("features", {})
	for feature_id in features:
		_row("Feature: %s" % FEATURE_LABELS.get(feature_id, feature_id.trim_prefix("feature.").capitalize()), features[feature_id])

## The edits a skill row cycles through, from its source in the level's own
## data: a tree skill goes tree -> start -> unavailable, a skill the level
## grants goes start -> unavailable. Empty (no button) for every other row:
## a grant cannot lift a level's ban or an off feature, banning a baseline
## skill is not an edit this table offers, and a seeded-role skill stays
## owned -- the level's starting count still puts bees in that role, and
## "seeding implies owning" derives from counts, which this table never
## edits (DeveloperOverrides.apply drops such a ban too).
static func _edit_cycle(own_row: Dictionary) -> Array:
	var reason: String = own_row.get("reason", "")
	if reason == RunAvailability.REASON_TREE:
		return [DeveloperOverrides.EDIT_NONE, DeveloperOverrides.EDIT_GRANT, DeveloperOverrides.EDIT_BAN]
	if reason == RunAvailability.REASON_RUN_GRANT:
		return [DeveloperOverrides.EDIT_NONE, DeveloperOverrides.EDIT_BAN]
	return []

func _set_edit(level_id: int, skill_id: String, edit: String) -> void:
	DeveloperOverrides.set_edit(level_id, skill_id, edit)
	_fill()

func _reset() -> void:
	DeveloperOverrides.reset()
	_fill()

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
