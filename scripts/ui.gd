extends RefCounted
## Small shared UI helpers.
## Usage: const UI = preload("res://scripts/ui.gd")
##        row.add_child(UI.info_badge("what this control does"))

## A small dark "i" in a white circle. Hovering it shows `text`.
## Godot renders `tooltip_text` natively, so there's nothing to wire up.
static func info_badge(text: String) -> Button:
	var badge := Button.new()
	badge.text = "i"
	badge.tooltip_text = text
	badge.custom_minimum_size = Vector2(16, 16)
	badge.focus_mode = Control.FOCUS_NONE
	badge.add_theme_font_size_override("font_size", 10)
	badge.add_theme_color_override("font_color", Color(0.1, 0.1, 0.12))
	badge.add_theme_color_override("font_hover_color", Color(0.0, 0.0, 0.0))
	badge.add_theme_color_override("font_pressed_color", Color(0.0, 0.0, 0.0))

	for style_name in ["normal", "hover", "pressed"]:
		var box := StyleBoxFlat.new()
		box.bg_color = Color(1, 1, 1) if style_name == "normal" else Color(0.88, 0.9, 0.95)
		box.set_corner_radius_all(8)
		box.content_margin_left = 4
		box.content_margin_right = 4
		box.content_margin_top = 0
		box.content_margin_bottom = 0
		badge.add_theme_stylebox_override(style_name, box)
	return badge

## Wraps a control and its info badge side by side.
static func with_info(control: Control, tip: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 3)
	row.add_child(control)
	row.add_child(info_badge(tip))
	return row
