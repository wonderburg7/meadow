extends Button
## Shared, bounded tooltip for every small "i" badge.
##
## Godot's default Button tooltip follows its text's natural single-line
## width. Keeping the override on the badge itself means every panel gets the
## same readable, viewport-safe tooltip without each caller reimplementing it.

const UiTheme = preload("res://scripts/ui_theme.gd")

const TOOLTIP_TEXT_WIDTH := 260.0

func _make_custom_tooltip(for_text: String) -> Control:
	return make_bounded_tooltip(for_text)

## The one bounded, wrapped, themed tooltip; the skill grid calls it too.
static func make_bounded_tooltip(for_text: String) -> Control:
	var panel := PanelContainer.new()
	panel.theme = UiTheme.build_theme()
	panel.add_theme_stylebox_override("panel", UiTheme.panel_stylebox())
	panel.custom_minimum_size.x = TOOLTIP_TEXT_WIDTH + 20.0

	var label := Label.new()
	label.text = for_text
	label.theme_type_variation = "Body"
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size.x = TOOLTIP_TEXT_WIDTH
	panel.add_child(label)
	return panel
