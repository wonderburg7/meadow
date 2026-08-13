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

signal closed()
## A readout here has been starred or unstarred into the top-left corner.
signal pinned_changed()

## The readouts in this window that can be starred into the corner, the
## same way the colony window's are. Keys are shared with
## GameConfig.pinned_stats and HUD.corner_texts, so one mechanism drives
## the corner rather than each panel having its own.
const STAT_ROWS := [
	{"key": "nursery_zone", "tip": "How many cells are set aside for each role, and how many are in each priority tier."},
	{"key": "nursery_mix", "tip": "What the colony is made of right now, as counts and shares."},
	{"key": "nursery_output", "tip": "How many bees of each kind have emerged from the comb in the last few minutes. This is the nursery's output -- the thing the zone actually controls."},
]

## The live text of each, handed to the HUD so the corner and this window
## always say the same thing.
var corner_texts: Dictionary = {"nursery_zone": "", "nursery_mix": "", "nursery_output": ""}
var star_buttons: Dictionary = {}

## One colour per role, shared between the ring plot, the emergence list
## and the glow on the comb itself. Keys match the "role|focus" form used
## everywhere else; "gyne" is its own category because a gyne is not a
## job, it's a different kind of bee.
const ROLE_COLOURS := {
	"0|nectar": Color(0.95, 0.72, 0.20),
	"0|pollen": Color(0.55, 0.48, 0.90),
	"1|": Color(0.40, 0.80, 0.95),
	"2|": Color(0.55, 0.85, 0.45),
	"5|": Color(0.80, 0.55, 0.35),
	"6|": Color(0.95, 0.45, 0.25),
	"4|": Color(0.60, 0.60, 0.62),
	"3|": Color(1.0, 0.85, 0.55),
	"gyne": Color(0.98, 0.80, 0.35),
	"unset": Color(0.75, 0.75, 0.78),
}

const ROLE_LABELS := {
	"0|nectar": "Nectar foragers",
	"0|pollen": "Pollen foragers",
	"1|": "Nurses",
	"2|": "Architects",
	"5|": "Miners",
	"6|": "Honey makers",
	"4|": "Idle",
	"3|": "Queen",
	"gyne": "Gynes",
	"unset": "No role set",
}

## Row order, so the readouts don't reshuffle themselves as counts change.
const ROLE_ORDER := [
	"0|nectar", "0|pollen", "1|", "2|", "5|", "6|", "gyne", "4|", "3|", "unset",
]

const TIER_NAMES := ["Low", "Medium", "High"]

var panel: PanelContainer
var zone_label: Label
var tier_label: Label
var emergence_label: Label
var ring: Control
var ring_slices: Array = []   # [{colour, share}] read by the ring's _draw

func _ready() -> void:
	process_mode = PROCESS_MODE_ALWAYS
	layer = 11
	add_to_group("nursery_panel")

	panel = PanelContainer.new()
	# left-hand side, clear of the top-left readouts
	panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	panel.offset_left = 16
	panel.offset_top = 150
	panel.custom_minimum_size = Vector2(330, 0)
	panel.visible = false
	add_child(panel)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 4)
	panel.add_child(column)

	var header := HBoxContainer.new()
	column.add_child(header)

	var title := Label.new()
	title.text = "Nursery zone"
	title.add_theme_font_size_override("font_size", 16)
	header.add_child(title)
	header.add_child(UI.info_badge(
		"Cells reserved for brood make up the nursery zone. Each one can name the role it raises and a priority tier, and the queen shares her eggs between the tiers in proportion to their weights -- so with the default 1:2:3, a high-priority cell gets three eggs for every one a low cell gets. That is how you steer what the colony grows into without giving every bee an order."
	))

	var close_btn := Button.new()
	close_btn.text = "×"
	close_btn.custom_minimum_size = Vector2(26, 22)
	close_btn.pressed.connect(func(): close())
	header.add_child(close_btn)

	column.add_child(HSeparator.new())

	zone_label = _make_readout(_starred_row(column, "nursery_zone", "The zone"), 12)
	tier_label = _make_readout(column, 12)

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
	emergence_label = _make_readout(column, 12)

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
	star.add_theme_font_size_override("font_size", 11)
	star.focus_mode = Control.FOCUS_NONE
	star.button_pressed = GameConfig.pinned_stats.has(key)
	star.text = "★" if star.button_pressed else "☆"
	star.tooltip_text = "Show this in the top-left corner of the screen as well as here."
	star.toggled.connect(func(pressed: bool): _set_pinned(key, pressed))
	row.add_child(star)
	star_buttons[key] = star

	var label := Label.new()
	label.text = title
	label.add_theme_font_size_override("font_size", 13)
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
	if pressed and not GameConfig.pinned_stats.has(key):
		GameConfig.pinned_stats.append(key)
	elif not pressed:
		GameConfig.pinned_stats.erase(key)
	if star_buttons.has(key):
		star_buttons[key].text = "★" if pressed else "☆"
	pinned_changed.emit()

func _make_readout(column: Node, size: int) -> Label:
	var label := Label.new()
	label.add_theme_font_size_override("font_size", size)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size = Vector2(300, 0)
	column.add_child(label)
	return label

func toggle() -> void:
	if panel.visible:
		close()
	else:
		open()

func open() -> void:
	panel.visible = true

func close() -> void:
	panel.visible = false
	closed.emit()

func is_open() -> bool:
	return panel.visible

## The colour a zone cell should glow, given the role it is set to raise.
static func colour_for(role: int, focus: String, is_gyne: bool) -> Color:
	if is_gyne:
		return ROLE_COLOURS["gyne"]
	if role < 0:
		return ROLE_COLOURS["unset"]
	var key: String = "%d|%s" % [role, focus] if role == 0 else "%d|" % role
	return ROLE_COLOURS.get(key, ROLE_COLOURS["unset"])

## Called once a second by main.gd while the window is open.
##   `zone`      -- Hive.zone_summary()
##   `live`      -- "role|focus" -> how many bees exist now
##   `emerged`   -- "role|focus" -> how many emerged in the window
##   `window`    -- length of that window in in-game seconds
## Runs whether or not the window is showing: a readout starred into the
## corner has to keep updating with the window closed, or it freezes at
## whatever it last said. Writing to hidden labels costs nothing.
func refresh(zone: Dictionary, live: Dictionary, emerged: Dictionary, window: float) -> void:
	_refresh_zone(zone)
	_refresh_ring(live)
	_refresh_emergence(emerged, window)

func _refresh_zone(zone: Dictionary) -> void:
	var by_role: Dictionary = zone.get("by_role", {})
	var lines: Array = []
	var total := 0
	for key in ROLE_ORDER:
		var count: int = int(by_role.get(key, 0))
		if count <= 0:
			continue
		total += count
		lines.append("%s: %d cell%s" % [ROLE_LABELS[key], count, "" if count == 1 else "s"])
	if lines.is_empty():
		zone_label.text = "No cells in the zone yet. Select comb and use \"Add to nursery zone\"."
		corner_texts["nursery_zone"] = "Nursery zone — no cells set aside"
	else:
		zone_label.text = "%d cells in the zone\n%s" % [total, "\n".join(lines)]
		corner_texts["nursery_zone"] = "Nursery zone — %d cells: %s" % [total, ", ".join(lines)]

	var counts: Array = zone.get("counts", [0, 0, 0])
	var free: Array = zone.get("free", [0, 0, 0])
	var tier_lines: Array = []
	var weights := [
		GameConfig.lay_weight_low, GameConfig.lay_weight_medium, GameConfig.lay_weight_high,
	]
	for tier in range(3):
		tier_lines.append("%s ×%d: %d cells (%d free)" % [
			TIER_NAMES[tier], int(weights[tier]), int(counts[tier]), int(free[tier]),
		])
	tier_label.text = "\n".join(tier_lines)

func _refresh_ring(live: Dictionary) -> void:
	var total := 0
	for key in live.keys():
		total += int(live[key])
	ring_slices = []
	if total <= 0:
		ring.queue_redraw()
		return
	for key in ROLE_ORDER:
		var count: int = int(live.get(key, 0))
		if count <= 0:
			continue
		ring_slices.append({
			"colour": ROLE_COLOURS.get(key, ROLE_COLOURS["unset"]),
			"share": float(count) / float(total),
			"label": ROLE_LABELS.get(key, key),
			"count": count,
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
	for key in ROLE_ORDER:
		var count: int = int(emerged.get(key, 0))
		if count <= 0:
			continue
		total += count
		lines.append("%s: %.1f/min  (%d)" % [ROLE_LABELS.get(key, key), count / minutes, count])
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
		angle += sweep

	# legend down the right-hand side
	var y := 6.0
	var font := ThemeDB.fallback_font
	for slice in ring_slices:
		ring.draw_rect(Rect2(Vector2(150, y), Vector2(10, 10)), slice.colour, true)
		ring.draw_string(
			font, Vector2(166, y + 10),
			"%s  %d  (%.0f%%)" % [slice.label, slice.count, slice.share * 100.0],
			HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.9, 0.92, 0.95)
		)
		y += 15.0
