extends GamePanel
## The skill tree, read-only (plans/now/alpha-progression-spine.md AP-3;
## grid rules in plans/design/progression.md section 8). The six sectors'
## title tiles sit on ring 1, every skill at its authored `axial` coordinate
## from skills.gd, and the connect tiles between them come from
## Shapes.hex_line. Each skill is drawn owned, affordable or blocked, from
## Session.progression; a blocked skill names the reason
## Progression.purchase_blocker gives. An affordable skill's Buy button
## (AP-4) spends the colony's real stores -- see _buy for who owns them.
##
## Every tile's state is resolved once when the window opens, into `tiles`,
## and the grid draws from that. Nothing here runs per frame, and a closed
## window does nothing (progression.md 8.4 on why that matters).
##
## SK-1: a full-screen view that pauses the game while it is open. Clicking a
## skill tile shows it in the detail strip along the bottom, whose Buy button
## is the one way to buy it. Drawn on layer 14: above the HUD (9), the
## settings window (10) and the left windows (11), below Gallerin (15) so its
## prompts stay readable, and below the main menu (20).
##
## Created by hud.gd, which owns the Skills button that opens it.

const Skills = preload("res://scripts/skills.gd")
const Progression = preload("res://scripts/progression.gd")
const Shapes = preload("res://scripts/shapes.gd")
const Resources = preload("res://scripts/resources.gd")
const Availability = preload("res://scripts/availability.gd")

## skills.gd prices in these keys; the comb holds them under these content
## types. Bee bread and pollinator points are not held anywhere yet, so a
## skill costing either cannot be afforded.
const STORE_CONTENT := {
	Skills.NECTAR: Resources.NECTAR,
	Skills.POLLEN: Resources.POLLEN,
	Skills.HONEY: Resources.HONEY,
	Skills.ROYAL_JELLY: Resources.JELLY,
}

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

const LAYER := 14

var grid: SkillGrid
## The detail strip: the selected skill's name, tier, state and cost, and Buy.
var detail_label: Label
var buy_button: Button
## The skill tile the strip shows; null until one is clicked.
var _selected_hex = null
## Whether the game was already paused when the view opened, so closing it
## leaves a player's own pause in place.
var _was_paused: bool = false

func _ready() -> void:
	setup_layer("skills", "skill_tree_panel", LAYER)
	_build_panel(0)
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	# The grid fills whatever height is left; the scroll body only scrolls
	# when a large text scale makes the column taller than the window.
	build_scroll_body()

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 6)
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.size_flags_vertical = Control.SIZE_EXPAND_FILL
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

	var intro := _label("What the colony can learn. Each sector grows outwards from the centre, one tier per ring; the lines show which skill leads to which. Hover a tile for details, or click a skill to see it below. The colony is paused while this is open.", "Small")
	column.add_child(intro)

	grid = SkillGrid.new()
	grid.tile_size = TILE_SIZE
	# Fallback text; _get_tooltip answers per tile.
	grid.tooltip_text = "The skill tree"
	var extent := Shapes.hex_to_pixel(GRID_RINGS, 0, TILE_SIZE).x + TILE_SIZE
	grid.custom_minimum_size = Vector2(extent * 2.0, sqrt(3.0) * TILE_SIZE * (GRID_RINGS * 2 + 1))
	grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	grid.on_select = _on_tile_selected
	column.add_child(grid)

	column.add_child(HSeparator.new())
	var strip := HBoxContainer.new()
	strip.add_theme_constant_override("separation", 8)
	column.add_child(strip)
	detail_label = _label("", "Body")
	detail_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	strip.add_child(detail_label)
	buy_button = Button.new()
	buy_button.text = "Buy"
	buy_button.focus_mode = Control.FOCUS_NONE
	for button_state in ["normal", "hover", "pressed", "focus", "disabled"]:
		buy_button.add_theme_stylebox_override(button_state, UiTheme.button_stylebox(button_state))
	buy_button.pressed.connect(_on_buy_pressed)
	strip.add_child(buy_button)
	_refresh_detail()

func open() -> void:
	if is_open():
		return
	_was_paused = get_tree().paused
	get_tree().paused = true
	_rebuild()
	# A hidden control keeps the size it had when the window last changed;
	# re-anchoring measures the viewport as it is now.
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	super.open()
	main.camera_view._refresh_speed_display()

func close() -> void:
	if not is_open():
		return
	super.close()
	get_tree().paused = _was_paused
	main.camera_view._refresh_speed_display()

## While the view is open it owns the keyboard: Escape closes it, and every
## other key stops here so Space or Tab cannot act on the paused game behind.
func _input(event: InputEvent) -> void:
	if not is_open() or not (event is InputEventKey):
		return
	if event.pressed and (event as InputEventKey).keycode == KEY_ESCAPE:
		close()
	get_viewport().set_input_as_handled()

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
	_refresh_detail()

# --- the detail strip ------------------------------------------------

func _on_tile_selected(hex: Vector2i) -> void:
	_selected_hex = hex
	grid.selected = hex
	grid.queue_redraw()
	_refresh_detail()

## Re-reads the selected tile from `tiles`, so after a purchase the strip
## shows the state _rebuild just resolved.
func _refresh_detail() -> void:
	var tile: Dictionary = grid.tiles.get(_selected_hex, {}) if _selected_hex != null else {}
	if tile.get("kind", "") != "skill":
		detail_label.text = "Click a skill to see what it costs and whether the colony can buy it."
		detail_label.remove_theme_color_override("font_color")
		buy_button.disabled = true
		return
	var skill: Dictionary = Skills.entry(tile.id)
	detail_label.text = "%s (tier %d) — %s. Cost: %s." % [tile.name, int(tile.tier),
		_state_text(tile.state, tile.reason), _cost_text(skill)]
	detail_label.add_theme_color_override("font_color", _state_colour(tile.state))
	buy_button.disabled = tile.state != STATE_AFFORDABLE

func _on_buy_pressed() -> void:
	var tile: Dictionary = grid.tiles.get(_selected_hex, {}) if _selected_hex != null else {}
	if tile.get("state", "") == STATE_AFFORDABLE:
		buy_skill(tile.id)

## What the colony could spend right now, keyed the way skills.gd prices
## things: every cell's contents that hive.take() would actually hand over
## -- not sealed or filling towards a seal, and honey only once ripe. A
## snapshot, taken on open and per purchase; the comb stays the owner.
func _stores() -> Dictionary:
	var stores: Dictionary = {}
	if main == null or main.hive == null:
		return stores
	for cell in main.hive.cells:
		if not is_instance_valid(cell) or not cell.can_withdraw():
			continue
		for key in STORE_CONTENT:
			if cell.content_type != STORE_CONTENT[key]:
				continue
			if key == Skills.HONEY and not cell.is_ripe_honey():
				continue
			stores[key] = float(stores.get(key, 0.0)) + cell.amount
	return stores

## AP-4: buys one skill. Who owns the stores (the plan's escalation): the
## comb does, as it always has -- hive.gd's cells hold them and hive.take()
## is how anything removes them. No second owner is invented here.
## Progression.purchase checks and deducts against a snapshot of what is
## withdrawable, and exactly what it deducted is then taken from the comb.
## Because the snapshot counts only what take() can reach, the take cannot
## fall short; if it ever did, the shortfall is reported rather than hidden.
func buy_skill(skill_id: String) -> bool:
	var progression = Session.progression
	if progression == null:
		return false
	var before := _stores()
	var stores := before.duplicate()
	if not progression.purchase(skill_id, stores):
		main.hud.show_warning("The colony cannot buy that right now.")
		_rebuild()
		return false
	for key in before:
		var spent: float = float(before[key]) - float(stores.get(key, 0.0))
		if spent <= 0.0:
			continue
		var taken: float = main.hive.take(STORE_CONTENT[key], spent)
		if taken + 0.001 < spent:
			push_warning("Skill %s: took %.1f of %.1f %s from the comb." % [skill_id, taken, spent, key])
	# A skill can gate work (G3): bees ask again rather than keep a stale answer.
	Availability.invalidate()
	main.hud.show_warning("%s bought." % Skills.label_for(skill_id))
	_rebuild()
	return true

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
	return "%s\n%s\nCost: %s\n%s" % [skill.name, skill.get("description", ""),
		_cost_text(skill), _sentence(_state_text(state, reason))]

func _cost_text(skill: Dictionary) -> String:
	if Session.progression != null and Session.progression.is_free(str(skill.get("id", ""))):
		return "Free"
	var cost: Dictionary = skill.get("cost", {})
	var parts: Array = []
	for resource in cost:
		parts.append("%d %s" % [int(cost[resource]), str(resource).replace("_", " ")])
	return ", ".join(parts) if not parts.is_empty() else "nothing"

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
## the tooltip and a click both find the tile under the pointer with
## Shapes.pixel_to_hex. It redraws only when told to: on open, on a click
## and after a purchase.
class SkillGrid:
	extends Control

	const Shapes = preload("res://scripts/shapes.gd")
	const UiTheme = preload("res://scripts/ui_theme.gd")

	## Called with the hex of a clicked skill tile.
	var on_select: Callable = Callable()

	var tiles: Dictionary = {}
	var tile_size: float = 11.0
	## The clicked skill tile, outlined; null when none is.
	var selected = null

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
		if selected != null and tiles.has(selected):
			var centre: Vector2 = _centre() + Shapes.hex_to_pixel(selected.x, selected.y, tile_size)
			var ring := Shapes.hexagon_points(tile_size * 1.05)
			for i in range(ring.size()):
				draw_line(centre + ring[i], centre + ring[(i + 1) % ring.size()], UiTheme.color("text_primary"), 2.0)

	func _gui_input(event: InputEvent) -> void:
		var click := event as InputEventMouseButton
		if click == null or not click.pressed or click.button_index != MOUSE_BUTTON_LEFT:
			return
		var hex := Shapes.pixel_to_hex(click.position - _centre(), tile_size)
		if tiles.get(hex, {}).get("kind", "") == "skill" and on_select.is_valid():
			on_select.call(hex)
			get_viewport().set_input_as_handled()

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
