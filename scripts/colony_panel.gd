extends CanvasLayer
## The colony overview: what the whole hive is made of, what it holds,
## how it is doing, and how that has changed -- in one place, with each
## role tally doubling as a selector.
##
## Managing bees one click at a time stops scaling somewhere around a
## dozen of them. This is the answer to "where has everyone gone" and to
## "put ten more bees on nectar" without hunting for them in the meadow.
##
## The running readouts that used to sit permanently in the top-left
## corner live here now. Each has a star beside it: starred readouts are
## also shown in the corner, so you choose what is worth screen space
## rather than being given a fixed block of it. Which ones are starred
## lives in GameConfig, so it survives a restart.
##
## Opened with the button in the top-right bar, or the C key.

const UI = preload("res://scripts/ui.gd")
const Roles = preload("res://scripts/roles.gd")

## Emitted when a role tally is clicked. `focus` narrows foragers to one
## resource; "" means the whole role.
signal role_selection_requested(role: int, focus: String)
## The set of starred readouts has changed; main.gd passes it to the HUD.
signal pinned_changed()

## The job tallies. Built from the role table, so a new role appears
## here without anyone remembering to add it -- which is exactly the bug
## this used to invite.

## The readouts that can be starred into the top-left corner. `key` is
## what Session.pinned_stats holds and what the HUD matches on.
const STAT_ROWS := [
	{"key": "day", "tip": "The day counter. One in-game day is however many real seconds the settings window says."},
	{"key": "stores", "tip": "What is actually in the comb: nectar, pollen, ripe honey and royal jelly. Honey only counts once it has been fanned dry."},
	{"key": "population", "tip": "How the colony is divided between jobs right now."},
	{"key": "comb", "tip": "How much comb there is, how much of it is free, and how the brood is doing."},
	{"key": "energy", "tip": "The average energy of every living bee, as a share of a full crop. This is the single best early warning: it falls for a while before bees actually start dying, so a steady slide here is the moment to put more bees on nectar."},
	{"key": "rates", "tip": "Nectar and pollen coming in, and bees emerging, averaged over the last minute. Rates rather than totals, because what matters is whether the colony is keeping up."},
	{"key": "signals", "tip": "The list of things currently going wrong, worst first."},
]

## Which series the history plot is showing.
const PLOT_SERIES := [
	{"key": "bees", "label": "Bees", "colour": Color(0.55, 0.85, 0.45)},
	{"key": "nectar", "label": "Nectar", "colour": Color(0.95, 0.72, 0.20)},
	{"key": "pollen", "label": "Pollen", "colour": Color(0.55, 0.48, 0.90)},
	{"key": "honey", "label": "Honey", "colour": Color(0.95, 0.45, 0.25)},
]

var panel: PanelContainer
var count_labels: Dictionary = {}   # count key -> Button
var stat_labels: Dictionary = {}    # stat key -> Label
var star_buttons: Dictionary = {}   # stat key -> Button

var plot: Control
var plot_button_row: HBoxContainer
var plot_series: String = "bees"
var plot_label: Label
var history: Array = []             # handed over by main.gd each refresh
## Which sections are expanded, remembered for the session.
var section_open: Dictionary = {}

func _ready() -> void:
	process_mode = PROCESS_MODE_ALWAYS
	layer = 11
	add_to_group("colony_panel")

	panel = PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	panel.offset_left = 16
	panel.offset_top = 60
	panel.custom_minimum_size = Vector2(330, 0)
	panel.visible = false
	add_child(panel)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 3)
	panel.add_child(column)

	var title := Label.new()
	title.text = "Colony"
	title.add_theme_font_size_override("font_size", 16)
	column.add_child(title)

	var hint := Label.new()
	hint.text = "Click a row to select every bee in it. Star a readout to keep it in the corner of the screen."
	hint.add_theme_font_size_override("font_size", 10)
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.custom_minimum_size = Vector2(300, 0)
	hint.add_theme_color_override("font_color", Color(0.7, 0.75, 0.8))
	column.add_child(hint)

	# Three collapsible sections rather than one long list. Who is doing
	# what is the thing you open this for most, so it starts open; the
	# readouts and the plot are there when you want them and out of the
	# way when you don't.
	var jobs := _section(column, "Who is doing what", true)
	for key in Roles.count_keys():
		jobs.add_child(_make_role_row(key))

	var readouts := _section(column, "Readouts", true)
	for entry in STAT_ROWS:
		readouts.add_child(_make_stat_row(entry))

	_build_plot(_section(column, "Over time", false))

## A collapsible section. Same pattern as the settings window and the cell
## popup, so all three behave the same way.
func _section(column: VBoxContainer, title: String, open_by_default: bool) -> VBoxContainer:
	if not section_open.has(title):
		section_open[title] = open_by_default

	var header := Button.new()
	header.alignment = HORIZONTAL_ALIGNMENT_LEFT
	header.add_theme_font_size_override("font_size", 12)
	header.focus_mode = Control.FOCUS_NONE
	column.add_child(header)

	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 2)
	body.visible = section_open[title]
	column.add_child(body)

	header.text = "%s  %s" % ["▾" if body.visible else "▸", title]
	header.pressed.connect(func():
		section_open[title] = not section_open[title]
		body.visible = section_open[title]
		header.text = "%s  %s" % ["▾" if body.visible else "▸", title]
	)
	return body

## Each row is a button so the whole strip is clickable, not just a
## small target -- selecting every forager should be one easy click.
func _make_role_row(key: String) -> Control:
	var button := Button.new()
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.custom_minimum_size = Vector2(0, 22)
	button.add_theme_font_size_override("font_size", 12)
	button.text = "%s: 0" % Roles.label_for_key(key)
	# A colour chip in the label so the tallies, the ring plot and the
	# comb overlays all read as one palette.
	button.add_theme_color_override("font_color", Roles.colour_for_key(key).lerp(Color.WHITE, 0.35))

	var parts: PackedStringArray = key.split("|")
	var role_value: int = int(parts[0])
	var focus_value: String = parts[1]
	button.pressed.connect(func(): role_selection_requested.emit(role_value, focus_value))

	count_labels[key] = button
	return button

## A readout plus the star that pins it to the corner. The star is a
## toggle button showing a filled or hollow star, which needs no
## explanation and takes almost no width.
func _make_stat_row(entry: Dictionary) -> Control:
	var row := HBoxContainer.new()
	var key: String = entry.key

	var star := Button.new()
	star.toggle_mode = true
	star.custom_minimum_size = Vector2(26, 20)
	star.add_theme_font_size_override("font_size", 12)
	star.button_pressed = Session.pinned_stats.has(key)
	star.text = "★" if star.button_pressed else "☆"
	star.tooltip_text = "Show this in the top-left corner of the screen as well as here."
	star.toggled.connect(func(pressed: bool): _set_pinned(key, pressed))
	row.add_child(star)
	star_buttons[key] = star

	var label := Label.new()
	label.add_theme_font_size_override("font_size", 12)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size = Vector2(270, 0)
	row.add_child(label)
	stat_labels[key] = label

	row.add_child(UI.info_badge(entry.tip))
	return row

func _set_pinned(key: String, pressed: bool) -> void:
	if pressed and not Session.pinned_stats.has(key):
		Session.pinned_stats.append(key)
	elif not pressed:
		Session.pinned_stats.erase(key)
	if star_buttons.has(key):
		star_buttons[key].text = "★" if pressed else "☆"
	pinned_changed.emit()

# --- the history plot ---------------------------------------------
## One series at a time rather than all four at once: they are on wildly
## different scales (tens of bees against hundreds of units of nectar),
## so overlaying them either needs four axes or makes three of them a
## flat line along the bottom.

func _build_plot(column: VBoxContainer) -> void:
	var header := HBoxContainer.new()
	column.add_child(header)

	var title := Label.new()
	title.text = "Over time"
	title.add_theme_font_size_override("font_size", 13)
	header.add_child(title)
	header.add_child(UI.info_badge(
		"How one number has moved over the last quarter of an hour or so of game time. Shape matters more than the values: a store that climbs and then flattens is a colony that has run out of somewhere to put things, and a population that flattens while nectar keeps climbing is one short of nursery cells."
	))

	plot_button_row = HBoxContainer.new()
	column.add_child(plot_button_row)
	for entry in PLOT_SERIES:
		var btn := Button.new()
		btn.text = entry.label
		btn.toggle_mode = true
		btn.add_theme_font_size_override("font_size", 11)
		btn.button_pressed = entry.key == plot_series
		var key: String = entry.key
		btn.pressed.connect(func(): _choose_series(key))
		plot_button_row.add_child(btn)

	plot = Control.new()
	plot.custom_minimum_size = Vector2(300, 110)
	plot.draw.connect(_draw_plot)
	column.add_child(plot)

	plot_label = Label.new()
	plot_label.add_theme_font_size_override("font_size", 11)
	plot_label.add_theme_color_override("font_color", Color(0.72, 0.78, 0.85))
	column.add_child(plot_label)

func _choose_series(key: String) -> void:
	plot_series = key
	for i in range(PLOT_SERIES.size()):
		plot_button_row.get_child(i).button_pressed = PLOT_SERIES[i].key == key
	plot.queue_redraw()

func _series_colour() -> Color:
	for entry in PLOT_SERIES:
		if entry.key == plot_series:
			return entry.colour
	return Color.WHITE

func _series_label() -> String:
	for entry in PLOT_SERIES:
		if entry.key == plot_series:
			return entry.label
	return plot_series

## Drawn by hand -- a line chart is a polyline, an axis and two numbers,
## and pulling in a charting library for that would be silly.
func _draw_plot() -> void:
	var size := plot.size
	var frame := Rect2(Vector2(34, 6), Vector2(max(40.0, size.x - 42.0), max(30.0, size.y - 30.0)))
	plot.draw_rect(frame, Color(0.12, 0.13, 0.16, 0.7), true)

	var font := ThemeDB.fallback_font
	if history.size() < 2:
		plot.draw_string(
			font, frame.position + Vector2(8, 22), "Not enough history yet.",
			HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.7, 0.72, 0.76)
		)
		return

	var highest := 0.0
	for point in history:
		highest = max(highest, float(point.get(plot_series, 0.0)))
	if highest <= 0.0:
		highest = 1.0
	# a little headroom, so the line never runs along the very top edge
	highest *= 1.12

	var points := PackedVector2Array()
	var count := history.size()
	for i in range(count):
		var value: float = float(history[i].get(plot_series, 0.0))
		points.append(Vector2(
			frame.position.x + frame.size.x * (float(i) / float(count - 1)),
			frame.position.y + frame.size.y * (1.0 - value / highest)
		))
	plot.draw_polyline(points, _series_colour(), 2.0)

	# baseline and the top of the scale, which is all the axis anyone
	# needs for a shape-reading plot
	plot.draw_line(
		frame.position + Vector2(0, frame.size.y),
		frame.position + frame.size,
		Color(0.5, 0.52, 0.58), 1.0
	)
	plot.draw_string(
		font, Vector2(2, frame.position.y + 10), "%d" % int(highest),
		HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.7, 0.72, 0.76)
	)
	plot.draw_string(
		font, Vector2(2, frame.position.y + frame.size.y), "0",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.7, 0.72, 0.76)
	)

	var latest: float = float(history[count - 1].get(plot_series, 0.0))
	var earliest: float = float(history[0].get(plot_series, 0.0))
	var change: float = latest - earliest
	plot_label.text = "%s: %d now, %+d over the last %d minutes" % [
		_series_label(), int(latest), int(change),
		int(round((float(history[count - 1].t) - float(history[0].t)) / 60.0)),
	]

func toggle() -> void:
	panel.visible = not panel.visible

func is_open() -> bool:
	return panel.visible

## Called each second by main.gd with the live figures. `counts` is keyed
## by "role|focus" to match ROLE_ROWS. `texts` carries the ready-made
## readout lines, so the corner and this panel can never disagree about
## what a number says -- both are handed the same strings.
func refresh(counts: Dictionary, texts: Dictionary, samples: Array) -> void:
	if not panel.visible:
		return

	for key in Roles.count_keys():
		count_labels[key].text = "%s: %d" % [Roles.label_for_key(key), counts.get(key, 0)]

	for stat_key in stat_labels.keys():
		stat_labels[stat_key].text = str(texts.get(stat_key, ""))

	history = samples
	plot.queue_redraw()
