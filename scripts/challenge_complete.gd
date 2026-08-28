extends CanvasLayer
## Shown once a Challenge's final sub-stage goal is met.
##
## Unlike game_over.gd, the colony hasn't ended -- stage_gate has already
## unlocked everything the Challenge was gating, and the player's own
## colony carries on exactly as it was the moment the goal was met. This
## is a pause-and-celebrate beat, not an end state: "Continue playing" is
## the expected choice, "Main menu" (to start something else instead) is
## the secondary one -- the same two-button shape as game_over.gd, minus
## its "the run is over" framing.

const UI = preload("res://scripts/ui.gd")
const UiTheme = preload("res://scripts/ui_theme.gd")

signal continue_requested()
signal continue_to_next_requested()
signal menu_requested()
signal restart_requested()

var headline_label: Label
var flavour_label: Label
var summary_label: Label
var reward_label: Label
var continue_btn: Button
var continue_to_next_btn: Button
var restart_btn: Button
var continue_row: HBoxContainer
var continue_to_next_row: HBoxContainer
var restart_row: HBoxContainer

func _ready() -> void:
	process_mode = PROCESS_MODE_ALWAYS   # still works while the run is paused
	layer = 24                           # below game_over's 25, above everything else
	visible = false
	add_to_group("challenge_complete")

	var backdrop := ColorRect.new()
	backdrop.color = Color(UiTheme.color("panel_bg"), 0.85)
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(backdrop)

	var panel := PanelContainer.new()
	panel.theme = UiTheme.build_theme()
	panel.add_theme_stylebox_override("panel", UiTheme.panel_stylebox())
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	panel.custom_minimum_size = Vector2(460, 0)
	add_child(panel)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	panel.add_child(column)

	headline_label = Label.new()
	headline_label.theme_type_variation = "Heading"
	headline_label.add_theme_color_override("font_color", UiTheme.color("success"))
	headline_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	headline_label.custom_minimum_size = Vector2(430, 0)
	column.add_child(headline_label)

	flavour_label = Label.new()
	flavour_label.theme_type_variation = "Body"
	flavour_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	flavour_label.custom_minimum_size = Vector2(430, 0)
	column.add_child(flavour_label)

	summary_label = Label.new()
	summary_label.theme_type_variation = "Small"
	summary_label.add_theme_color_override("font_color", UiTheme.color("text_secondary"))
	column.add_child(summary_label)

	reward_label = Label.new()
	reward_label.theme_type_variation = "Small"
	reward_label.add_theme_color_override("font_color", UiTheme.color("success"))
	reward_label.text = "+ [meta-currency placeholder] earned"
	reward_label.visible = false
	column.add_child(reward_label)

	column.add_child(HSeparator.new())

	continue_btn = Button.new()
	continue_btn.text = "Continue playing"
	continue_btn.custom_minimum_size = Vector2(0, 32)
	for state in ["normal", "hover", "pressed", "focus", "disabled"]:
		continue_btn.add_theme_stylebox_override(state, UiTheme.button_stylebox(state))
	continue_btn.pressed.connect(func(): continue_requested.emit())
	continue_row = UI.with_info(continue_btn, "Keep playing this colony -- everything the Challenge was gating is now unlocked.")
	column.add_child(continue_row)

	continue_to_next_btn = Button.new()
	continue_to_next_btn.text = "Continue to Challenge 2"
	continue_to_next_btn.custom_minimum_size = Vector2(0, 32)
	for state in ["normal", "hover", "pressed", "focus", "disabled"]:
		continue_to_next_btn.add_theme_stylebox_override(state, UiTheme.button_stylebox(state))
	continue_to_next_btn.pressed.connect(func(): continue_to_next_requested.emit())
	continue_to_next_row = UI.with_info(continue_to_next_btn, "Begin Challenge 2 with a fresh colony.")
	continue_to_next_row.visible = false
	column.add_child(continue_to_next_row)

	restart_btn = Button.new()
	restart_btn.text = "Restart Challenge 1"
	restart_btn.custom_minimum_size = Vector2(0, 32)
	for state in ["normal", "hover", "pressed", "focus", "disabled"]:
		restart_btn.add_theme_stylebox_override(state, UiTheme.button_stylebox(state))
	restart_btn.pressed.connect(func(): restart_requested.emit())
	restart_row = UI.with_info(restart_btn, "Start Challenge 1 again from the beginning.")
	restart_row.visible = false
	column.add_child(restart_row)

	var menu_btn := Button.new()
	menu_btn.text = "Main menu"
	menu_btn.custom_minimum_size = Vector2(0, 32)
	for state in ["normal", "hover", "pressed", "focus", "disabled"]:
		menu_btn.add_theme_stylebox_override(state, UiTheme.button_stylebox(state))
	menu_btn.pressed.connect(func(): menu_requested.emit())
	column.add_child(UI.with_info(menu_btn, "Go back to the menu and pick a different Challenge or Scenario."))

## `headline`/`flavour` are the Challenge's own completion text (the same
## strings challenge_runner.gd used to hand straight to Dr Gallerin) --
## shown here instead of as a bubble, so the one moment of "you did it"
## has one home rather than two competing messages. `day`/`bees`/
## `nectar`/`pollen` are a short summary in the same spirit as
## game_over.gd's epitaph, just framed as what got achieved rather than
## what was lost.
func open(headline: String, flavour: String, day: int, bees: int, nectar: float, pollen: float) -> void:
	var is_challenge_one := Session.starting_level == 1
	headline_label.text = headline
	flavour_label.text = flavour
	summary_label.text = "Day %d · %d bees · %d nectar and %d pollen in the comb" % [
		day, bees, int(round(nectar)), int(round(pollen)),
	]
	reward_label.visible = is_challenge_one
	continue_row.visible = not is_challenge_one
	continue_to_next_row.visible = is_challenge_one
	restart_row.visible = is_challenge_one
	visible = true
	get_tree().paused = true
