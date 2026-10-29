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

const CanvasLayers = preload("res://scripts/canvas_layers.gd")
const Skills = preload("res://scripts/skills.gd")
const UiInfoBadge = preload("res://scripts/ui_info_badge.gd")
const Progression = preload("res://scripts/progression.gd")
const Shapes = preload("res://scripts/shapes.gd")
const Resources = preload("res://scripts/resources.gd")
const Availability = preload("res://scripts/availability.gd")

## skills.gd prices in these keys; the comb holds them under these content
## types. Bee bread (BB-3) is held by sealed, ripe cells. Pollinator points
## (PP-2) are not in the comb: pollination.gd's ledger holds them, so they
## are added to the snapshot and spent separately.
const STORE_CONTENT := {
	Skills.NECTAR: Resources.NECTAR,
	Skills.POLLEN: Resources.POLLEN,
	Skills.HONEY: Resources.HONEY,
	Skills.ROYAL_JELLY: Resources.JELLY,
	Skills.BEE_BREAD: Resources.BEE_BREAD,
}

## shapes.gd's axial direction order, which is also skills.gd's SECTORS
## order (progression.md 8.2).
const DIRECTIONS := [
	Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 1),
	Vector2i(-1, 0), Vector2i(0, -1), Vector2i(1, -1),
]
const TILE_SIZE := 56.0
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
## The detail strip: the selected skill's name, tier, state and cost, and Buy.
var detail_label: Label
var buy_button: Button
## The skill tile the strip shows; null until one is clicked.
var _selected_hex = null
## Whether the game was already paused when the view opened, so closing it
## leaves a player's own pause in place.
var _was_paused: bool = false

func _ready() -> void:
	setup_layer("skills", "skill_tree_panel", CanvasLayers.SKILL_TREE)
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
	grid.rings = GRID_RINGS
	# The grid clips and pans, so it no longer needs room for every ring.
	grid.custom_minimum_size = Vector2(300, 160)
	grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	grid.on_select = _on_tile_selected
	column.add_child(grid)

	column.add_child(HSeparator.new())
	var strip := HBoxContainer.new()
	strip.add_theme_constant_override("separation", 8)
	column.add_child(strip)
	detail_label = _label("", "Body")
	detail_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	buy_button = Button.new()
	buy_button.text = "Buy"
	buy_button.focus_mode = Control.FOCUS_NONE
	for button_state in ["normal", "hover", "pressed", "focus", "disabled"]:
		buy_button.add_theme_stylebox_override(button_state, UiTheme.button_stylebox(button_state))
	buy_button.pressed.connect(_on_buy_pressed)
	# First in the strip, so Buy is never in the bottom-right corner that
	# Dr Gallerin's layer-15 bubble covers.
	strip.add_child(buy_button)
	strip.add_child(detail_label)
	_refresh_detail()

func open() -> void:
	if is_open():
		return
	_was_paused = get_tree().paused
	get_tree().paused = true
	_rebuild()
	grid.reset_view()
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
		tiles[DIRECTIONS[i]] = {"kind": "title", "tip": Skills.SECTORS[i].label, "label": Skills.SECTORS[i].label}

	var edges: Array = []   # [from axial, to axial]
	for skill in Skills.SKILLS:
		if skill.get("baseline", false) or Skills.is_cut(skill.id):
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
	if not Skills.is_built(tile.id):
		detail_label.text += " Not built yet: buying it changes nothing yet."
	detail_label.add_theme_color_override("font_color", _state_colour(tile.state))
	buy_button.disabled = tile.state != STATE_AFFORDABLE

func _on_buy_pressed() -> void:
	var tile: Dictionary = grid.tiles.get(_selected_hex, {}) if _selected_hex != null else {}
	if tile.get("state", "") == STATE_AFFORDABLE:
		buy_skill(tile.id)

## What the colony could spend right now, keyed the way skills.gd prices
## things: every cell's contents that hive.take() would actually hand over
## -- not sealed or filling towards a seal; honey and bee bread only once ripe; and
## nectar only while it has not fermented. A
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
			if key == Skills.BEE_BREAD and not cell.is_ripe_bee_bread():
				continue
			if key == Skills.NECTAR and cell.is_fermented():
				continue
			stores[key] = float(stores.get(key, 0.0)) + cell.amount
	# PP-2: the ledger, read like a cell; absent at zero, like any store.
	if main.pollination != null and main.pollination.points > 0:
		stores[Skills.POLLINATOR_POINTS] = float(main.pollination.points)
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
		# PP-2: points come out of the ledger, which is their only owner.
		if key == Skills.POLLINATOR_POINTS:
			var points_taken: int = main.pollination.spend(int(round(spent)))
			if points_taken < int(round(spent)):
				push_warning("Skill %s: took %d of %d pollinator points." % [skill_id, points_taken, int(round(spent))])
			continue
		var taken: float = main.hive.take(STORE_CONTENT[key], spent)
		if taken + 0.001 < spent:
			push_warning("Skill %s: took %.1f of %.1f %s from the comb." % [skill_id, taken, spent, key])
	# A skill can gate work (G3): bees ask again rather than keep a stale answer.
	Availability.invalidate()
	# ...and a role (BS-3): the HUD re-offers one this purchase unlocked.
	main.hud.refresh_role_gating()
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
	return "%s\n%s\nCost: %s\n%s%s" % [skill.name, skill.get("description", ""),
		_cost_text(skill), _sentence(_state_text(state, reason)), _not_built_note(skill) + _replaced_note(skill)]

## FBB-1: a node whose effect is not built says so rather than sell nothing.
func _not_built_note(skill: Dictionary) -> String:
	return "" if Skills.is_built(str(skill.get("id", ""))) else "\nNot built yet: buying it changes nothing yet."

## FR-2: Orientation flight says so once Auto scouting has replaced it.
func _replaced_note(skill: Dictionary) -> String:
	if str(skill.get("id", "")) != Skills.ORIENTATION_FLIGHT:
		return ""
	if Session.progression == null or not Session.progression.is_owned(Skills.AUTO_SCOUTING):
		return ""
	return "\nReplaced by Auto scouting: new foragers now scout for themselves."

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


## The hex grid itself. Draws from `tiles`, which the panel fills on open.
## It clips to its own rectangle and shows the tree through a pan and a zoom:
## dragging moves it, the wheel zooms about the pointer, and the tooltip and
## a click both invert the same transform before Shapes.pixel_to_hex finds
## the tile. It redraws only when told to: on open, on a click, on a pan or
## zoom and after a purchase.
class SkillGrid:
	extends Control

	const UiTheme = preload("res://scripts/ui_theme.gd")

	const MAX_ZOOM := 1.5
	const ZOOM_STEP := 1.1
	## A press that moves less than this is a click, not a drag.
	const DRAG_THRESHOLD := 6.0
	const NAME_LINES := 3
	## A name may shrink to this share of the Small font before a word that
	## still does not fit is broken with a hyphen.
	const MIN_NAME_SCALE := 0.6
	## Text colours over a coloured tile, picked by the tile's brightness.
	const DARK_TEXT := Color(0.11, 0.09, 0.06)
	const LIGHT_TEXT := Color(1, 1, 1)

	## Called with the hex of a clicked skill tile.
	var on_select: Callable = Callable()

	var tiles: Dictionary = {}
	var tile_size: float = 56.0
	## How many rings the whole tree spans; sets the zoomed-out limit.
	var rings: int = 9
	## The clicked skill tile, outlined; null when none is.
	var selected = null
	## Where the colony tile sits, as an offset from the middle of the control.
	var pan: Vector2 = Vector2.ZERO
	var zoom: float = 1.0

	var _pressed: bool = false
	var _dragging: bool = false
	var _press_at: Vector2 = Vector2.ZERO
	## text -> {"size": int, "lines": Array}; cleared when the font or width changes.
	var _fit_cache: Dictionary = {}
	var _fit_key: String = ""

	func _init() -> void:
		clip_contents = true

	## Back to 1.0 zoom, centred on the colony tile.
	func reset_view() -> void:
		pan = Vector2.ZERO
		zoom = clampf(1.0, _min_zoom(), MAX_ZOOM)
		queue_redraw()

	## The zoom at which the whole tree fits inside the control, never above 1.0.
	func _min_zoom() -> float:
		var half := Vector2(
				Shapes.hex_to_pixel(rings, 0, tile_size).x + tile_size,
				sqrt(3.0) * tile_size * (rings * 2 + 1) / 2.0)
		var view := _visible_size()
		if view.x <= 0.0 or view.y <= 0.0:
			return 1.0
		return minf(minf(view.x / (half.x * 2.0), view.y / (half.y * 2.0)), 1.0)

	## The part of this control the player can actually see: at large text
	## scales the window can be taller than the screen, so `size` alone
	## over-reports the room the tree has.
	func _visible_size() -> Vector2:
		if not is_inside_tree():
			return size
		var seen := Rect2(global_position, size).intersection(get_viewport_rect())
		if seen.size.x <= 0.0 or seen.size.y <= 0.0:
			return size
		return seen.size

	## Keeps some of the tree on screen however far it is dragged.
	func _clamp_pan() -> void:
		var half := Vector2(
				Shapes.hex_to_pixel(rings, 0, tile_size).x + tile_size,
				sqrt(3.0) * tile_size * (rings * 2 + 1) / 2.0)
		var limit := half * zoom
		pan = pan.clamp(-limit, limit)

	func _notification(what: int) -> void:
		if what == NOTIFICATION_RESIZED:
			zoom = clampf(zoom, _min_zoom(), MAX_ZOOM)
			_clamp_pan()
			queue_redraw()

	## A point on the control, in the tree's own coordinates (colony tile at 0,0).
	func _to_tree(point: Vector2) -> Vector2:
		return (point - size / 2.0 - pan) / zoom

	func _draw() -> void:
		draw_set_transform(size / 2.0 + pan, 0.0, Vector2(zoom, zoom))
		var outline := Shapes.hexagon_points(tile_size * 0.92)
		var font: Font = get_theme_font("font", "Small")
		var font_size: int = get_theme_font_size("font_size", "Small")
		var text_width := tile_size * 1.4
		var key := "%d|%d|%d" % [font.get_instance_id(), font_size, int(text_width)]
		if key != _fit_key:
			_fit_key = key
			_fit_cache.clear()
		for hex in tiles:
			var tile: Dictionary = tiles[hex]
			var at: Vector2 = Shapes.hex_to_pixel(hex.x, hex.y, tile_size)
			var points := PackedVector2Array()
			for point in outline:
				points.append(at + point)
			var fill := _fill(tile)
			draw_colored_polygon(points, fill)
			var text := str(tile.get("name", tile.get("label", "")))
			if text != "":
				if not _fit_cache.has(text):
					_fit_cache[text] = _fit_name(text, font, font_size, text_width)
				var fit: Dictionary = _fit_cache[text]
				var lines: Array = fit["lines"]
				var line_size: int = fit["size"]
				var line_height := font.get_height(line_size)
				var top := at.y - line_height * lines.size() / 2.0 + font.get_ascent(line_size)
				var colour := _text_colour(tile, fill)
				for i in range(lines.size()):
					draw_string(font, Vector2(at.x - text_width / 2.0, top + line_height * i),
							lines[i], HORIZONTAL_ALIGNMENT_CENTER, text_width, line_size, colour)
		if selected != null and tiles.has(selected):
			var centre: Vector2 = Shapes.hex_to_pixel(selected.x, selected.y, tile_size)
			var ring := Shapes.hexagon_points(tile_size * 1.05)
			for i in range(ring.size()):
				draw_line(centre + ring[i], centre + ring[(i + 1) % ring.size()], UiTheme.color("text_primary"), 2.0)

	## Lays a name out so every letter shows: whole words at the largest size
	## (down to MIN_NAME_SCALE of `base_size`) that fits NAME_LINES lines,
	## else hyphen-broken words at that smallest size.
	func _fit_name(text: String, font: Font, base_size: int, width: float) -> Dictionary:
		var min_size := maxi(int(base_size * MIN_NAME_SCALE), 6)
		for line_size in range(base_size, min_size - 1, -1):
			var lines := _wrap(text, font, line_size, width, false)
			if not lines.is_empty() and lines.size() <= NAME_LINES:
				return {"size": line_size, "lines": lines}
		return {"size": min_size, "lines": _wrap(text, font, min_size, width, true)}

	## Greedy word wrap. Returns [] when a word is too wide and `hyphenate` is off.
	func _wrap(text: String, font: Font, line_size: int, width: float, hyphenate: bool) -> Array:
		var pieces: Array = []
		for word in text.split(" ", false):
			var rest: String = word
			while _text_width(rest, font, line_size) > width and rest.length() > 1:
				if not hyphenate:
					return []
				var cut := 1
				for n in range(rest.length() - 1, 0, -1):
					if _text_width(rest.substr(0, n) + "-", font, line_size) <= width:
						cut = n
						break
				pieces.append(rest.substr(0, cut) + "-")
				rest = rest.substr(cut)
			pieces.append(rest)
		var lines: Array = []
		var current := ""
		for piece in pieces:
			if current == "":
				current = piece
			elif not current.ends_with("-") and _text_width(current + " " + piece, font, line_size) <= width:
				current += " " + piece
			else:
				lines.append(current)
				current = piece
		if current != "":
			lines.append(current)
		return lines

	func _text_width(text: String, font: Font, line_size: int) -> float:
		return font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, line_size).x

	func _gui_input(event: InputEvent) -> void:
		var button := event as InputEventMouseButton
		if button != null:
			if button.button_index == MOUSE_BUTTON_LEFT:
				if button.pressed:
					_pressed = true
					_dragging = false
					_press_at = button.position
				else:
					if _pressed and not _dragging:
						_click(button.position)
					_pressed = false
					_dragging = false
				accept_event()
			elif button.pressed and (button.button_index == MOUSE_BUTTON_WHEEL_UP or button.button_index == MOUSE_BUTTON_WHEEL_DOWN):
				_zoom_about(button.position, ZOOM_STEP if button.button_index == MOUSE_BUTTON_WHEEL_UP else 1.0 / ZOOM_STEP)
				accept_event()
			return
		var motion := event as InputEventMouseMotion
		if motion != null and _pressed:
			if not _dragging and motion.position.distance_to(_press_at) > DRAG_THRESHOLD:
				_dragging = true
			if _dragging:
				pan += motion.relative
				_clamp_pan()
				queue_redraw()
				accept_event()

	func _click(at_position: Vector2) -> void:
		var hex := Shapes.pixel_to_hex(_to_tree(at_position), tile_size)
		if tiles.get(hex, {}).get("kind", "") == "skill" and on_select.is_valid():
			on_select.call(hex)

	## Zooms by `factor`, keeping the tree point under `at_position` where it is.
	func _zoom_about(at_position: Vector2, factor: float) -> void:
		var anchor := _to_tree(at_position)
		zoom = clampf(zoom * factor, _min_zoom(), MAX_ZOOM)
		pan = at_position - size / 2.0 - anchor * zoom
		_clamp_pan()
		queue_redraw()

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

	## The panel's own text colour on a locked tile, dark or light on a coloured one.
	func _text_colour(tile: Dictionary, fill: Color) -> Color:
		if tile.get("kind", "") == "skill" and tile.get("state", "") == "blocked":
			return UiTheme.color("text_primary")
		return DARK_TEXT if fill.get_luminance() > 0.45 else LIGHT_TEXT

	func _make_custom_tooltip(for_text: String) -> Object:
		if for_text.is_empty():
			return null
		return UiInfoBadge.make_bounded_tooltip(for_text)

	func _get_tooltip(at_position: Vector2) -> String:
		var hex := Shapes.pixel_to_hex(_to_tree(at_position), tile_size)
		return str(tiles.get(hex, {}).get("tip", ""))
