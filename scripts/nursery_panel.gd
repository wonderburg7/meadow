extends CanvasLayer
## The nursery zone window: what the colony is currently set up to
## produce, what it is actually made of, and what has been coming out of
## the comb lately.
##
## The point of it is to answer one question -- "am I going to get the mix
## of bees I want?" -- by putting the three things that bear on it next to
## each other:
##   * how many cells are assigned to each role, and at what priority
##   * the make-up of the colony right now, as a ring
##   * how many of each role have actually emerged in the last few minutes
##
## While it is open the comb behind it dims and every zone cell glows in
## the colour of the role it raises, so the plan on screen and the plan in
## the hive are visibly the same thing.

const UI = preload("res://scripts/ui.gd")
const Roles = preload("res://scripts/roles.gd")
const UiLayout = preload("res://scripts/ui_layout.gd")
const UiTheme = preload("res://scripts/ui_theme.gd")

signal closed()
## A readout here has been starred or unstarred into the top-left corner.
signal pinned_changed()
## A line in "Brood needing attention" was clicked -- see colony_panel.gd's
## identical signal for why this is separate from hud.gd's own.
signal signal_clicked(action: String)

## The readouts in this window that can be starred into the corner, the
## same way the colony window's are. Keys are shared with
## Session.pinned_stats and HUD.corner_texts, so one mechanism drives
## the corner rather than each panel having its own.
const STAT_ROWS := [
	{"key": "nursery_zone", "tip": "How many cells are set aside for each role, and how many are in each priority tier."},
	{"key": "nursery_brood_stages", "tip": "How many of the colony's brood are eggs, larvae or capped and close to emerging. A count derived from each cell's own development progress, not a separately tracked stage."},
	{"key": "nursery_mix", "tip": "What the colony is made of right now, as counts and shares."},
	{"key": "nursery_output", "tip": "How many bees of each kind have emerged from the comb in the last few minutes. This is the nursery's output -- the thing the zone actually controls."},
]

## Nursery-relevant signal kinds, matched against the 4th ("category")
## element year_winter.gd::_refresh_signals tags a line with -- see that
## function's comment. Everything else in main.hud.shown_signals is
## still shown in the Colony drawer, just not repeated here.
const BROOD_SIGNAL_CATEGORY := "brood"

## The live text of each, handed to the HUD so the corner and this window
## always say the same thing.
var corner_texts: Dictionary = {
	"nursery_zone": "", "nursery_brood_stages": "", "nursery_mix": "", "nursery_output": "",
}
var star_buttons: Dictionary = {}

## Role colours, labels and order all come from the role table now, so
## the ring plot, the comb glow and the colony window's tallies are
## guaranteed to agree. Gynes are the one thing here that isn't a job --
## they get their own slice because they're a different kind of bee.
const GYNE_COLOUR := Color(0.98, 0.80, 0.35)
const UNSET_COLOUR := Color(0.75, 0.75, 0.78)

static func _key_label(key: String) -> String:
	if key == "gyne":
		return "Gynes"
	if key == "unset":
		return "No role set"
	return Roles.label_for_key(key)

static func _key_tag(key: String) -> String:
	if key == "gyne":
		return "G"
	if key == "unset":
		return "?"
	return Roles.tag_for_key(key)

static func _key_colour(key: String) -> Color:
	if key == "gyne":
		return GYNE_COLOUR
	if key == "unset":
		return UNSET_COLOUR
	return Roles.colour_for_key(key)

## Row order, so readouts don't reshuffle as counts change.
static func row_order() -> Array:
	var keys: Array = Roles.count_keys()
	keys.append("gyne")
	keys.append("unset")
	return keys

const TIER_NAMES := ["Low", "Medium", "High"]

var panel: PanelContainer
var main: Node2D
var scroll_container: ScrollContainer
var zone_label: Label
var brood_stages_label: Label
var tier_label: Label
var intended_roles_label: Label
var emergence_label: Label
var ring: Control
var ring_slices: Array = []   # [{colour, share}] read by the ring's _draw

var needing_attention_column: VBoxContainer
var needing_attention_ok_label: Label

func _ready() -> void:
	process_mode = PROCESS_MODE_ALWAYS
	layer = 11
	add_to_group("nursery_panel")
	main = get_parent() as Node2D

	panel = PanelContainer.new()
	panel.theme = UiTheme.build_theme()
	panel.add_theme_stylebox_override("panel", UiTheme.panel_stylebox())
	panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	panel.offset_left = UiLayout.SELECTION_TRAY_LEFT_MARGIN
	panel.custom_minimum_size = Vector2(330, 0)
	panel.visible = false
	add_child(panel)

	scroll_container = ScrollContainer.new()
	scroll_container.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll_container.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	panel.add_child(scroll_container)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 4)
	scroll_container.add_child(column)

	var header := HBoxContainer.new()
	column.add_child(header)

	var title := Label.new()
	title.text = "Nursery zone"
	title.theme_type_variation = "Heading"
	header.add_child(title)
	header.add_child(UI.info_badge(
		"Cells reserved for brood make up the nursery zone. Each one can name the role it raises and a priority tier, and the queen shares her eggs between the tiers in proportion to their weights -- so with the default 1:2:3, a high-priority cell gets three eggs for every one a low cell gets. That is how you steer what the colony grows into without giving every bee an order."
	))

	var close_btn := Button.new()
	close_btn.text = "×"
	close_btn.custom_minimum_size = Vector2(26, 22)
	_style_button(close_btn)
	close_btn.pressed.connect(func(): close())
	header.add_child(close_btn)

	column.add_child(HSeparator.new())

	# Priority order per UI_PLAN.md section 5: is any brood in trouble
	# right now, then the zone's capacity, then the stage make-up of what
	# it currently holds, then the tier weights steering future eggs,
	# then the colony as a whole, then output, then the by-role detail
	# behind the zone's capacity figure.
	needing_attention_column = _section_body(column, "Brood needing attention")
	needing_attention_ok_label = Label.new()
	needing_attention_ok_label.text = "Brood is fine -- nothing needs attention right now."
	needing_attention_ok_label.theme_type_variation = "Small"
	needing_attention_ok_label.add_theme_color_override("font_color", UiTheme.color("success"))
	needing_attention_ok_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	needing_attention_ok_label.custom_minimum_size = Vector2(300, 0)
	needing_attention_column.add_child(needing_attention_ok_label)

	column.add_child(HSeparator.new())

	zone_label = _make_readout(_starred_row(column, "nursery_zone", "The zone"), "Small")

	column.add_child(HSeparator.new())

	brood_stages_label = _make_readout(_starred_row(column, "nursery_brood_stages", "Brood stages"), "Small")

	column.add_child(HSeparator.new())

	tier_label = _make_readout(_section_body(column, "Priority tiers"), "Small")

	column.add_child(HSeparator.new())

	column.add_child(_starred_row(column, "nursery_mix", "The colony now", true))

	# Drawn by hand: there is no charting library here, and a donut is a
	# handful of arcs.
	ring = Control.new()
	ring.custom_minimum_size = Vector2(300, 150)
	ring.draw.connect(_draw_ring)
	column.add_child(ring)

	column.add_child(HSeparator.new())

	column.add_child(_starred_row(column, "nursery_output", "Emerging (last 3 minutes)", true))
	emergence_label = _make_readout(column, "Small")

	column.add_child(HSeparator.new())

	intended_roles_label = _make_readout(_section_body(column, "Intended roles"), "Small")
	get_viewport().size_changed.connect(_apply_left_window_rect)
	main.hud.bottom_row_changed.connect(_on_bottom_row_changed)

## The five states a plain Godot Button actually looks up -- see
## colony_panel.gd's identical helper.
func _style_button(button: Button) -> Button:
	for state in ["normal", "hover", "pressed", "focus", "disabled"]:
		button.add_theme_stylebox_override(state, UiTheme.button_stylebox(state))
	return button

## A plain (non-collapsible) sub-heading, for a block that doesn't need
## hiding -- unlike colony_panel.gd's sections, everything here is short
## enough that collapsing it would save no real space.
func _section_body(column: VBoxContainer, title: String) -> VBoxContainer:
	var heading := Label.new()
	heading.text = title
	heading.theme_type_variation = "Body"
	column.add_child(heading)
	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 2)
	column.add_child(body)
	return body

## A section heading with a star beside it. Starring pins that readout to
## the top-left corner, the same as in the colony window -- one habit
## rather than two.
##
## `standalone` returns the row for the caller to add itself; otherwise
## the row is added here and returned as a container for the readout.
func _starred_row(column: VBoxContainer, key: String, title: String, standalone: bool = false) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 3)

	var star := Button.new()
	star.toggle_mode = true
	star.custom_minimum_size = Vector2(24, 18)
	star.theme_type_variation = "Small"
	_style_button(star)
	star.focus_mode = Control.FOCUS_NONE
	star.button_pressed = Session.pinned_stats.has(key)
	star.text = "★" if star.button_pressed else "☆"
	star.tooltip_text = "Show this in the top-left corner of the screen as well as here."
	star.toggled.connect(func(pressed: bool): _set_pinned(key, pressed))
	row.add_child(star)
	star_buttons[key] = star

	var label := Label.new()
	label.text = title
	label.theme_type_variation = "Body"
	row.add_child(label)

	for entry in STAT_ROWS:
		if entry.key == key:
			row.add_child(UI.info_badge(entry.tip))
			break

	if standalone:
		return row
	var holder := VBoxContainer.new()
	holder.add_child(row)
	column.add_child(holder)
	return holder

func _set_pinned(key: String, pressed: bool) -> void:
	if pressed and not Session.pinned_stats.has(key):
		Session.pinned_stats.append(key)
	elif not pressed:
		Session.pinned_stats.erase(key)
	Session.save_preferences()
	if star_buttons.has(key):
		star_buttons[key].text = "★" if pressed else "☆"
	pinned_changed.emit()

func _make_readout(column: Node, variation: String) -> Label:
	var label := Label.new()
	label.theme_type_variation = variation
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size = Vector2(300, 0)
	column.add_child(label)
	return label

func toggle() -> void:
	if panel.visible:
		close()
	else:
		open()

func _apply_left_window_rect() -> void:
	var top := UiLayout.left_window_top(main.hud.corner_bottom())
	panel.offset_top = top
	scroll_container.custom_minimum_size.y = UiLayout.left_window_max_height(
		get_viewport().get_visible_rect().size.y, top, main.hud.selection_panel_top()
	)

## The bottom row (summary panel) changed height while this window may
## already be open -- reflow it rather than waiting for the next open().
func _on_bottom_row_changed() -> void:
	if panel.visible:
		_apply_left_window_rect()

func open() -> void:
	_apply_left_window_rect()
	panel.visible = true

func close() -> void:
	panel.visible = false
	closed.emit()

func is_open() -> bool:
	return panel.visible

## The colour a zone cell should glow, given the role it is set to raise.
static func colour_for(role: int, focus: String, is_gyne: bool) -> Color:
	if is_gyne:
		return GYNE_COLOUR
	if role < 0:
		return UNSET_COLOUR
	return Roles.colour_for(role, focus)

## The short tag standing in for colour_for's colour, given to the comb's
## zone glow so it stays legible with Session.colour_blind_mode on.
static func tag_for(role: int, focus: String, is_gyne: bool) -> String:
	if is_gyne:
		return "G"
	if role < 0:
		return "?"
	return Roles.tag_for_key(Roles.count_key(role, focus))

## Called once a second by main.gd while the window is open.
##   `zone`          -- Hive.zone_summary()
##   `live`          -- "role|focus" -> how many bees exist now
##   `emerged`       -- "role|focus" -> how many emerged in the window
##   `window`        -- length of that window in in-game seconds
##   `brood_stages`  -- Hive.brood_stage_counts()
##   `signals`       -- main.hud.shown_signals
## Runs whether or not the window is showing: a readout starred into the
## corner has to keep updating with the window closed, or it freezes at
## whatever it last said. Writing to hidden labels costs nothing.
func refresh(
	zone: Dictionary, live: Dictionary, emerged: Dictionary, window: float,
	brood_stages: Dictionary = {}, signals: Array = []
) -> void:
	_refresh_zone(zone)
	_refresh_brood_stages(brood_stages)
	_refresh_ring(live)
	_refresh_emergence(emerged, window)
	_rebuild_needing_attention(signals)

## Rebuilt from scratch each refresh, same reason as colony_panel.gd's
## identical favourites/needing-attention lists -- which problems exist,
## and how many, changes at any time.
func _rebuild_needing_attention(signals: Array) -> void:
	for child in needing_attention_column.get_children():
		if child != needing_attention_ok_label:
			child.queue_free()

	var relevant: Array = []
	for entry in signals:
		var category: String = entry[3] if entry.size() > 3 else ""
		if category == BROOD_SIGNAL_CATEGORY:
			relevant.append(entry)

	needing_attention_ok_label.visible = relevant.is_empty()
	for entry in relevant:
		needing_attention_column.add_child(
			UI.signal_line_button(entry, func(action): signal_clicked.emit(action))
		)

## Capacity (how big the zone is, how much of it is free) and the tier
## weights, both read straight off Hive.zone_summary() -- the by-role
## breakdown moved to _refresh_intended_roles below, since it's a
## separate priority item per UI_PLAN.md section 5, not because the
## underlying data changed.
func _refresh_zone(zone: Dictionary) -> void:
	var counts: Array = zone.get("counts", [0, 0, 0])
	var free: Array = zone.get("free", [0, 0, 0])
	var total_cells := int(counts[0]) + int(counts[1]) + int(counts[2])
	var total_free := int(free[0]) + int(free[1]) + int(free[2])

	if total_cells <= 0:
		zone_label.text = "No cells in the zone yet. Select comb and reserve it for eggs (\"Reserve for\" -> Eggs)."
	else:
		zone_label.text = "%d cells in the zone, %d free" % [total_cells, total_free]

	var tier_lines: Array = []
	var weights := [
		GameConfig.lay_weight_low, GameConfig.lay_weight_medium, GameConfig.lay_weight_high,
	]
	for tier in range(3):
		tier_lines.append("%s ×%d: %d cells (%d free)" % [
			TIER_NAMES[tier], int(weights[tier]), int(counts[tier]), int(free[tier]),
		])
	tier_label.text = "\n".join(tier_lines)

	_refresh_intended_roles(zone, total_cells)

func _refresh_intended_roles(zone: Dictionary, total_cells: int) -> void:
	var by_role: Dictionary = zone.get("by_role", {})
	var lines: Array = []
	for key in row_order():
		var count: int = int(by_role.get(key, 0))
		if count <= 0:
			continue
		lines.append("%s: %d cell%s" % [_key_label(key), count, "" if count == 1 else "s"])
	if lines.is_empty():
		intended_roles_label.text = "No cells in the zone yet."
		corner_texts["nursery_zone"] = "Nursery zone — no cells set aside"
	else:
		intended_roles_label.text = "\n".join(lines)
		corner_texts["nursery_zone"] = "Nursery zone — %d cells: %s" % [total_cells, ", ".join(lines)]

## Buckets each brood cell's own development_percent() into thirds --
## presentation only, see Hive.brood_stage_counts().
func _refresh_brood_stages(stages: Dictionary) -> void:
	var egg := int(stages.get("egg", 0))
	var larva := int(stages.get("larva", 0))
	var capped := int(stages.get("capped", 0))
	var total := egg + larva + capped
	if total <= 0:
		brood_stages_label.text = "No brood in the comb right now."
		corner_texts["nursery_brood_stages"] = "Brood stages — none right now"
		return
	brood_stages_label.text = "Egg: %d · Larva: %d · Capped: %d  (%d total)" % [egg, larva, capped, total]
	corner_texts["nursery_brood_stages"] = (
		"Brood stages — egg %d, larva %d, capped %d" % [egg, larva, capped]
	)

func _refresh_ring(live: Dictionary) -> void:
	var total := 0
	for key in live.keys():
		total += int(live[key])
	ring_slices = []
	if total <= 0:
		ring.queue_redraw()
		return
	for key in row_order():
		var count: int = int(live.get(key, 0))
		if count <= 0:
			continue
		ring_slices.append({
			"colour": _key_colour(key),
			"share": float(count) / float(total),
			"label": _key_label(key),
			"count": count,
			"tag": _key_tag(key),
		})
	ring.queue_redraw()
	# The ring answers "what shape is the colony", which is a question
	# about proportions -- so the key gives the share as well as the
	# count. Reading proportions off arc lengths by eye is exactly the
	# thing pie charts are bad at.
	var lines: Array = []
	for slice in ring_slices:
		lines.append("%s: %d (%.0f%%)" % [slice.label, slice.count, slice.share * 100.0])
	corner_texts["nursery_mix"] = "Colony mix — %s" % ", ".join(lines) if not lines.is_empty() else ""

## Bees that have emerged from the comb in the window, as a rate. This
## counts *births*, not what those bees then go on to do -- it is the
## output of the nursery, which is the thing the zone controls.
func _refresh_emergence(emerged: Dictionary, window: float) -> void:
	var minutes: float = max(0.001, window / 60.0)
	var lines: Array = []
	var total := 0
	for key in row_order():
		var count: int = int(emerged.get(key, 0))
		if count <= 0:
			continue
		total += count
		lines.append("%s: %.1f/min  (%d)" % [_key_label(key), count / minutes, count])
	if lines.is_empty():
		emergence_label.text = "Nothing has emerged in the last 3 minutes."
		corner_texts["nursery_output"] = "Emerging — nothing recently"
		return
	lines.append("All bees: %.1f/min" % (total / minutes))
	emergence_label.text = "\n".join(lines)
	corner_texts["nursery_output"] = "Emerging — %s" % ", ".join(lines)

## A donut, drawn as a run of thick arcs. Slices under a couple of degrees
## are still drawn -- a role with one bee in a colony of eighty should
## show as a sliver rather than disappear.
func _draw_ring() -> void:
	var centre := Vector2(75, 75)
	var radius := 52.0
	var thickness := 22.0

	if ring_slices.is_empty():
		ring.draw_arc(centre, radius, 0.0, TAU, 48, Color(0.4, 0.4, 0.45, 0.6), thickness)
		return

	var angle := -PI / 2.0   # start at twelve o'clock
	for slice in ring_slices:
		var sweep: float = slice.share * TAU
		ring.draw_arc(centre, radius, angle, angle + sweep, 32, slice.colour, thickness)
		# A tag on any slice wide enough to hold one, so a reader who
		# can't separate the colours can still match ring to key.
		if Session.colour_blind_mode and sweep > 0.35:
			var mid: float = angle + sweep * 0.5
			ring.draw_string(
				ThemeDB.fallback_font,
				centre + Vector2(cos(mid), sin(mid)) * radius + Vector2(-7, 4),
				slice.tag, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.08, 0.08, 0.1)
			)
		angle += sweep

	# legend down the right-hand side
	var y := 6.0
	var font := ThemeDB.fallback_font
	for slice in ring_slices:
		ring.draw_rect(Rect2(Vector2(150, y), Vector2(10, 10)), slice.colour, true)
		var text: String = "%s  %d  (%.0f%%)" % [slice.label, slice.count, slice.share * 100.0]
		if Session.colour_blind_mode:
			# The chip alone tells you nothing if you can't separate the
			# colours, and the slices on the ring have no labels of their
			# own. The tag appears on both, which is what links them.
			text = "[%s] %s" % [slice.tag, text]
		ring.draw_string(
			font, Vector2(166, y + 10), text,
			HORIZONTAL_ALIGNMENT_LEFT, -1, 11, UiTheme.color("text_primary")
		)
		y += 15.0
