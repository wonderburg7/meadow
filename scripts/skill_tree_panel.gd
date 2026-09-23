extends GamePanel
## The skill tree, read-only (plans/now/alpha-progression-spine.md AP-3;
## grid rules in plans/design/progression.md section 8). The six sectors'
## title tiles sit on ring 1, every skill at its authored `axial` coordinate
## from skills.gd, and the connect tiles between them come from
## Shapes.hex_line. Each skill is drawn owned, affordable or blocked, from
## Session.progression; a blocked skill names the reason
## Progression.purchase_blocker gives. Buying comes in AP-4.
##
## Every tile's state is resolved once when the window opens, into `tiles`,
## and the grid draws from that. Nothing here runs per frame, and a closed
## window does nothing (progression.md 8.4 on why that matters).
##
## Created by hud.gd, which owns the Skills button that opens it.

const Skills = preload("res://scripts/skills.gd")
const Progression = preload("res://scripts/progression.gd")
const Shapes = preload("res://scripts/shapes.gd")
const Resources = preload("res://scripts/resources.gd")

## shapes.gd's axial direction order, which is also skills.gd's SECTORS
## order (progression.md 8.2).
const DIRECTIONS := [
	Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 1),
	Vector2i(-1, 0), Vector2i(0, -1), Vector2i(1, -1),
]
const TILE_SIZE := 11.0
const GRID_RINGS := 9

const STATE_OWNED := "owned"
const STATE_AFFORDABLE := "affordable"
const STATE_BLOCKED := "blocked"

## purchase_blocker's reasons in the player's words.
const BLOCK_TEXT := {
	Progression.BLOCK_NO_SUCH_SKILL: "not in the catalogue",
	Progression.BLOCK_BASELINE: "always on",
	Progression.BLOCK_UNKNOWN: "not discovered yet",
	Progression.BLOCK_NOT_PERMITTED: "not available in this run",
	Progression.BLOCK_FEATURE: "needs a part of the game this run does not have",
	Progression.BLOCK_PREREQUISITES: "needs an earlier skill first",
	Progression.BLOCK_PREVIOUS_TIER: "needs a skill from the tier before it",
	Progression.BLOCK_ALREADY_OWNED: "already owned",
	Progression.BLOCK_COST: "the colony cannot pay for it yet",
}

var grid: SkillGrid
var list_box: VBoxContainer

func _ready() -> void:
	setup_layer("skills", "skill_tree_panel")
	build_left_window(400)
	build_scroll_body()

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 6)
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll_container.add_child(column)

	var header := HBoxContainer.new()
	column.add_child(header)
	var title := Label.new()
	title.text = "Skills"
	title.theme_type_variation = "Heading"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	var close_btn := Button.new()
	close_btn.text = "×"
	close_btn.custom_minimum_size = Vector2(26, 22)
	close_btn.focus_mode = Control.FOCUS_NONE
	for state in ["normal", "hover", "pressed", "focus", "disabled"]:
		close_btn.add_theme_stylebox_override(state, UiTheme.button_stylebox(state))
	close_btn.pressed.connect(func(): close())
	header.add_child(close_btn)

	var intro := _label("What the colony can learn. Each sector grows outwards from the centre, one tier per ring; the lines show which skill leads to which. Hover a tile for details.", "Small")
	column.add_child(intro)

	grid = SkillGrid.new()
	grid.tile_size = TILE_SIZE
	# Fallback text; _get_tooltip answers per tile.
	grid.tooltip_text = "The skill tree"
	var extent := Shapes.hex_to_pixel(GRID_RINGS, 0, TILE_SIZE).x + TILE_SIZE
	grid.custom_minimum_size = Vector2(extent * 2.0, sqrt(3.0) * TILE_SIZE * (GRID_RINGS * 2 + 1))
	column.add_child(grid)

	column.add_child(HSeparator.new())
	list_box = VBoxContainer.new()
	list_box.add_theme_constant_override("separation", 2)
	column.add_child(list_box)

	connect_left_window_reflow()

func open() -> void:
	_rebuild()
	super.open()

# --- resolving every tile once --------------------------------------

func _rebuild() -> void:
	var progression = Session.progression
	var stores := _stores()
	var tiles: Dictionary = {}   # Vector2i -> tile dictionary
	tiles[Vector2i(0, 0)] = {"kind": "centre", "tip": "The colony's stores:\n" + _stores_text(stores)}
	for i in range(Skills.SECTORS.size()):
		tiles[DIRECTIONS[i]] = {"kind": "title", "tip": Skills.SECTORS[i].label}

	var edges: Array = []   # [from axial, to axial]
	for skill in Skills.SKILLS:
		if skill.get("baseline", false):
			continue
		var at: Vector2i = skill.axial
		var state := STATE_BLOCKED
		var reason := ""
		if progression == null:
			reason = "no run in progress"
		elif progression.is_owned(skill.id):
			state = STATE_OWNED
		else:
			var blocker: String = progression.purchase_blocker(skill.id, stores)
			if blocker == "":
				state = STATE_AFFORDABLE
			else:
				reason = BLOCK_TEXT.get(blocker, blocker)
		tiles[at] = {"kind": "skill", "id": skill.id, "name": skill.name, "state": state,
			"reason": reason, "sector": skill.sector, "tier": int(skill.tier),
			"tip": _skill_tip(skill, state, reason)}
		if int(skill.tier) == 1:
			edges.append([DIRECTIONS[Skills.sector_index(skill.sector)], at])
		for prerequisite in skill.get("all_of", []) + skill.get("any_of", []):
			var from: Dictionary = Skills.entry(prerequisite)
			if not from.is_empty() and not from.get("baseline", false):
				edges.append([from.axial, at])

	# Connect tiles never overwrite a skill or title (progression.md 8.3).
	for edge in edges:
		for hex in Shapes.hex_line(edge[0], edge[1]):
			if not tiles.has(hex):
				tiles[hex] = {"kind": "connect", "tip": ""}

	grid.tiles = tiles
	grid.queue_redraw()
	_rebuild_list(tiles)

func _rebuild_list(tiles: Dictionary) -> void:
	for child in list_box.get_children():
		child.queue_free()
	for sector in Skills.SECTORS:
		list_box.add_child(_label(sector.label, "Body"))
		for skill in Skills.for_sector(sector.key):
			var tile: Dictionary = tiles.get(skill.axial, {})
			var line := "    %s (tier %d) — %s" % [skill.name, int(skill.tier), _state_text(tile.get("state", STATE_BLOCKED), tile.get("reason", ""))]
			var label := _label(line, "Small")
			label.add_theme_color_override("font_color", _state_colour(tile.get("state", STATE_BLOCKED)))
			list_box.add_child(label)

## The colony's spendable stores, keyed the way skills.gd prices things.
## A snapshot for this window only: who owns a spendable-stores collection
## is AP-4's question (see its Escalation), and this answers nothing for it.
func _stores() -> Dictionary:
	if main == null or main.hive == null:
		return {}
	return {
		Skills.NECTAR: main.hive.total(Resources.NECTAR),
		Skills.POLLEN: main.hive.total(Resources.POLLEN),
		Skills.HONEY: main.hive.total_honey(),
		Skills.ROYAL_JELLY: main.hive.total(Resources.JELLY),
	}

# --- text -----------------------------------------------------------

func _state_text(state: String, reason: String) -> String:
	match state:
		STATE_OWNED:
			return "owned"
		STATE_AFFORDABLE:
			return "can be bought"
	return "blocked: " + reason

func _state_colour(state: String) -> Color:
	match state:
		STATE_OWNED:
			return UiTheme.color("success")
		STATE_AFFORDABLE:
			return UiTheme.color("warning")
	return UiTheme.color("locked")

func _skill_tip(skill: Dictionary, state: String, reason: String) -> String:
	var cost: Dictionary = skill.get("cost", {})
	var parts: Array = []
	for resource in cost:
		parts.append("%d %s" % [int(cost[resource]), str(resource).replace("_", " ")])
	return "%s\n%s\nCost: %s\n%s" % [skill.name, skill.get("description", ""),
		", ".join(parts) if not parts.is_empty() else "nothing", _sentence(_state_text(state, reason))]

func _sentence(text: String) -> String:
	return text.substr(0, 1).to_upper() + text.substr(1) + "."

func _stores_text(stores: Dictionary) -> String:
	if stores.is_empty():
		return "none yet"
	var lines: Array = []
	for resource in stores:
		lines.append("%s: %d" % [str(resource).replace("_", " ").capitalize(), int(stores[resource])])
	return "\n".join(lines)

func _label(text: String, variation: String) -> Label:
	var label := Label.new()
	label.text = text
	label.theme_type_variation = variation
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size = Vector2(300, 0)
	return label


## The hex grid itself. Draws from `tiles`, which the panel fills on open;
## the tooltip finds the tile under the pointer with Shapes.pixel_to_hex.
class SkillGrid:
	extends Control

	const Shapes = preload("res://scripts/shapes.gd")
	const UiTheme = preload("res://scripts/ui_theme.gd")

	var tiles: Dictionary = {}
	var tile_size: float = 11.0

	func _centre() -> Vector2:
		return size / 2.0

	func _draw() -> void:
		var outline := Shapes.hexagon_points(tile_size * 0.92)
		for hex in tiles:
			var tile: Dictionary = tiles[hex]
			var at: Vector2 = _centre() + Shapes.hex_to_pixel(hex.x, hex.y, tile_size)
			var points := PackedVector2Array()
			for point in outline:
				points.append(at + point)
			draw_colored_polygon(points, _fill(tile))

	func _fill(tile: Dictionary) -> Color:
		match tile.get("kind", ""):
			"centre":
				return UiTheme.color("accent_honey")
			"title":
				return UiTheme.color("accent_wax")
			"connect":
				var line := UiTheme.color("text_secondary")
				line.a = 0.35
				return line
		match tile.get("state", ""):
			"owned":
				return UiTheme.color("success")
			"affordable":
				return UiTheme.color("warning")
		return UiTheme.color("locked")

	func _get_tooltip(at_position: Vector2) -> String:
		var hex := Shapes.pixel_to_hex(at_position - _centre(), tile_size)
		return str(tiles.get(hex, {}).get("tip", ""))
