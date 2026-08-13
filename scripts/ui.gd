extends RefCounted
## Small shared UI helpers.
## Usage: const UI = preload("res://scripts/ui.gd")
##        row.add_child(UI.info_badge("what this control does"))

const BADGE_SIZE := 16.0

## A small dark "i" in a white circle. Hovering it shows `text`.
## Godot renders `tooltip_text` natively, so there's nothing to wire up.
##
## The badge is pinned to an exact square. Left to size itself around the
## letter plus its stylebox margins it came out wider than it was tall,
## so the rounded corners read as a stretched oval rather than a circle.
## Fixed size + zero horizontal content margin + a corner radius of
## exactly half the size gives a true circle at any font setting.
static func info_badge(text: String) -> Button:
	var badge := Button.new()
	badge.text = "i"
	badge.tooltip_text = text
	badge.custom_minimum_size = Vector2(BADGE_SIZE, BADGE_SIZE)
	badge.size = Vector2(BADGE_SIZE, BADGE_SIZE)
	# without this the button grows to fill whatever room the row has
	badge.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	badge.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	badge.clip_text = true
	badge.focus_mode = Control.FOCUS_NONE
	badge.add_theme_font_size_override("font_size", 10)
	badge.add_theme_color_override("font_color", Color(0.1, 0.1, 0.12))
	badge.add_theme_color_override("font_hover_color", Color(0.0, 0.0, 0.0))
	badge.add_theme_color_override("font_pressed_color", Color(0.0, 0.0, 0.0))

	for style_name in ["normal", "hover", "pressed"]:
		var box := StyleBoxFlat.new()
		box.bg_color = Color(1, 1, 1) if style_name == "normal" else Color(0.88, 0.9, 0.95)
		box.set_corner_radius_all(int(BADGE_SIZE / 2.0))
		# a circle needs the same margin on every side; the old asymmetric
		# left/right padding is what made it an oval
		box.content_margin_left = 0
		box.content_margin_right = 0
		box.content_margin_top = 0
		box.content_margin_bottom = 0
		box.set_border_width_all(0)
		badge.add_theme_stylebox_override(style_name, box)

	# Every badge joins one group so the tuning panel's "Show info icons"
	# switch can hide them all at once, wherever they happen to live.
	badge.add_to_group("info_badges")
	badge.visible = GameConfig.show_info_badges
	return badge

## Wraps a control and its info badge side by side.
static func with_info(control: Control, tip: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 3)
	row.add_child(control)
	row.add_child(info_badge(tip))
	return row

## The colour of the "this is what the selection is already doing" border.
const CURRENT_ROLE_COLOUR := Color(0.35, 1.0, 0.55)

## Draws a glowing border round a button to mark it as the role the
## selected bees are already on.
##
## The selection panel used to hide the button for the current role
## instead, which meant the row of buttons changed shape every time you
## clicked a different bee -- and the one piece of information you most
## want ("what is this bee doing?") was conveyed by an absence, which is
## the hardest thing to read. Every button is now always present in the
## same place, and the current one is lit up.
static func mark_as_current(button: Button) -> Button:
	button.add_theme_color_override("font_color", CURRENT_ROLE_COLOUR)
	for style_name in ["normal", "hover", "pressed", "focus"]:
		var box := StyleBoxFlat.new()
		box.bg_color = Color(0.16, 0.30, 0.20) if style_name == "normal" else Color(0.22, 0.38, 0.26)
		box.set_corner_radius_all(4)
		box.set_border_width_all(2)
		box.border_color = CURRENT_ROLE_COLOUR
		box.content_margin_left = 8
		box.content_margin_right = 8
		box.content_margin_top = 3
		box.content_margin_bottom = 3
		button.add_theme_stylebox_override(style_name, box)
	return button

## Applies the current GameConfig.show_info_badges setting to every badge
## already on screen. `node` is any node in the tree -- it's only used to
## reach the scene tree.
static func refresh_badge_visibility(node: Node) -> void:
	if node == null or not node.is_inside_tree():
		return
	for badge in node.get_tree().get_nodes_in_group("info_badges"):
		if is_instance_valid(badge):
			badge.visible = GameConfig.show_info_badges
