extends CanvasLayer
## The colony overview: what the whole hive is made of and what it holds,
## in one place, with each role tally doubling as a selector.
##
## Managing bees one click at a time stops scaling somewhere around a
## dozen of them. This is the answer to "where has everyone gone" and to
## "put ten more bees on nectar" without hunting for them in the meadow.
##
## Opened with the button in the top-right bar, or the C key.

const UI = preload("res://scripts/ui.gd")

## Emitted when a role tally is clicked. `focus` narrows foragers to one
## resource; "" means the whole role.
signal role_selection_requested(role: int, focus: String)

## Mirrors Bee.Role, as plain ints -- see the note on hud.gd's
## HATCH_ROLES for why this file doesn't preload bee.gd.
const ROLE_ROWS := [
	{"label": "Foragers — nectar", "role": 0, "focus": "nectar"},
	{"label": "Foragers — pollen", "role": 0, "focus": "pollen"},
	{"label": "Nurses", "role": 1, "focus": ""},
	{"label": "Architects", "role": 2, "focus": ""},
	{"label": "Miners", "role": 5, "focus": ""},
	{"label": "Honey makers", "role": 6, "focus": ""},
	{"label": "Idle", "role": 4, "focus": ""},
	{"label": "Queen", "role": 3, "focus": ""},
]

var panel: PanelContainer
var count_labels: Dictionary = {}   # row index -> Label
var stores_label: Label
var brood_label: Label
var energy_label: Label

func _ready() -> void:
	process_mode = PROCESS_MODE_ALWAYS
	layer = 11
	add_to_group("colony_panel")

	panel = PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	panel.offset_left = 16
	panel.offset_top = 250
	panel.custom_minimum_size = Vector2(300, 0)
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
	hint.text = "Click a row to select every bee in it."
	hint.add_theme_font_size_override("font_size", 10)
	hint.add_theme_color_override("font_color", Color(0.7, 0.75, 0.8))
	column.add_child(hint)

	column.add_child(HSeparator.new())

	for i in range(ROLE_ROWS.size()):
		column.add_child(_make_role_row(i))

	column.add_child(HSeparator.new())

	stores_label = _make_readout(column)
	brood_label = _make_readout(column)
	energy_label = _make_readout(column)

func _make_readout(column: VBoxContainer) -> Label:
	var label := Label.new()
	label.add_theme_font_size_override("font_size", 12)
	column.add_child(label)
	return label

## Each row is a button so the whole strip is clickable, not just a
## small target -- selecting every forager should be one easy click.
func _make_role_row(index: int) -> Control:
	var entry: Dictionary = ROLE_ROWS[index]
	var button := Button.new()
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.custom_minimum_size = Vector2(0, 22)
	button.add_theme_font_size_override("font_size", 12)
	button.text = "%s: 0" % entry.label

	var role_value: int = entry.role
	var focus_value: String = entry.focus
	button.pressed.connect(func(): role_selection_requested.emit(role_value, focus_value))

	count_labels[index] = button
	return button

func toggle() -> void:
	panel.visible = not panel.visible

func is_open() -> bool:
	return panel.visible

## Called each second by main.gd with the live figures. `counts` is keyed
## by "role|focus" to match ROLE_ROWS.
func refresh(counts: Dictionary, stores: Dictionary, brood: Dictionary, mean_energy: float) -> void:
	if not panel.visible:
		return

	for i in range(ROLE_ROWS.size()):
		var entry: Dictionary = ROLE_ROWS[i]
		var key: String = "%d|%s" % [entry.role, entry.focus]
		count_labels[i].text = "%s: %d" % [entry.label, counts.get(key, 0)]

	stores_label.text = "Stores — nectar %d · pollen %d · honey %d · jelly %d" % [
		int(stores.get("nectar", 0.0)),
		int(stores.get("pollen", 0.0)),
		int(stores.get("honey", 0.0)),
		int(stores.get("jelly", 0.0)),
	]
	brood_label.text = "Comb — %d cells, %d free · brood %d (%d gynes), %d hungry" % [
		int(brood.get("cells", 0)),
		int(brood.get("free", 0)),
		int(brood.get("brood", 0)),
		int(brood.get("gynes", 0)),
		int(brood.get("hungry", 0)),
	]
	energy_label.text = "Average energy: %d%%" % int(mean_energy * 100.0)
