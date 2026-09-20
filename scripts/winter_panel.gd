extends GamePanel
## The winter forecast: how long until it arrives, what the colony will
## need to get through it, and whether it is on track.
##
## Winter isn't simulated yet -- this is the run-up to it. That is
## deliberate and it is the useful half: the interesting decisions
## (stop growing and start storing? seal a cell? raise gynes now or
## later?) all happen *before* the weather turns. A countdown with an
## honest shortfall figure creates all of those decisions on its own,
## without any winter mechanics existing yet.
##
## The requirement is worked out from the colony's own numbers rather
## than a fixed target, so it responds to the colony the player has
## actually built: more bees means more food needed, and honey counts for
## several times its volume because that is what it is worth.

const UI = preload("res://scripts/ui.gd")

var headline: Label
var detail: Label
var verdict: Label
## The live text, so it can be starred into the corner like everything
## else.
var corner_text: String = ""

func _ready() -> void:
	setup_layer("winter", "winter_panel")
	# top-right, under the button bar, since that's where it's opened from
	build_top_right_window(330, 44, -12)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 4)
	panel.add_child(column)

	var header := HBoxContainer.new()
	column.add_child(header)

	var title := Label.new()
	title.text = "Winter"
	title.theme_type_variation = "Heading"
	header.add_child(title)
	header.add_child(UI.info_badge(
		"What the colony will need to survive the winter, and whether it has it. The figures come from the colony's own size, so they move as it grows -- a bigger colony needs more, which is the tension: growing now costs you the stores that would have carried you through."
	))

	var close_btn := Button.new()
	close_btn.text = "×"
	close_btn.custom_minimum_size = Vector2(26, 22)
	# Only the states a plain Godot Button actually looks up ("selected"
	# and "locked" from UiTheme's seven apply to custom-drawn controls
	# like the future skill tree, not a native Button).
	for state in ["normal", "hover", "pressed", "focus", "disabled"]:
		close_btn.add_theme_stylebox_override(state, UiTheme.button_stylebox(state))
	close_btn.pressed.connect(func(): close())
	header.add_child(close_btn)

	column.add_child(HSeparator.new())

	headline = _make_label(column, "Body")
	detail = _make_label(column, "Small")
	verdict = _make_label(column, "Body")

func _make_label(column: VBoxContainer, variation: String) -> Label:
	var label := Label.new()
	label.theme_type_variation = variation
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size = Vector2(300, 0)
	column.add_child(label)
	return label

## `needs` comes from main.gd's _winter_forecast.
func refresh(needs: Dictionary) -> void:
	var days_left: float = needs.get("days_left", 0.0)
	var required: float = needs.get("required_energy", 0.0)
	var held: float = needs.get("held_energy", 0.0)
	var bees: int = int(needs.get("bees", 0))

	if days_left > 0.0:
		headline.text = "Winter in %d days" % int(ceil(days_left))
	else:
		headline.text = "Winter is here"

	detail.text = (
		"%d bees, needing about %d units of stored energy to last %d days of winter.\n\n"
		+ "In the comb now: %d units, counting honey at %d× nectar.\n"
		+ "Honey is what matters -- it keeps, and the same cell holds several times the energy."
	) % [
		bees, int(required), int(GameConfig.winter_length_days),
		int(held), int(GameConfig.honey_energy_factor),
	]

	var shortfall: float = required - held
	if shortfall <= 0.0:
		verdict.text = "On track — about %d units spare." % int(-shortfall)
		verdict.add_theme_color_override("font_color", UiTheme.color("success"))
		corner_text = "Winter in %d days — on track" % int(ceil(days_left))
	else:
		var per_day: float = shortfall / max(1.0, days_left)
		verdict.text = "Short by about %d units. That is %d a day from now until winter." % [
			int(shortfall), int(ceil(per_day)),
		]
		verdict.add_theme_color_override("font_color", UiTheme.color("danger"))
		corner_text = "Winter in %d days — short by %d" % [int(ceil(days_left)), int(shortfall)]
