extends GamePanel
## COL-10: shown once, when a gyne takes over from a queen who has died.
##
## main.gd::_check_for_loss promotes the oldest adult gyne in the frame the
## queen's reference goes invalid, then opens this window with her. It
## says what happened and what it means: she has not mated, so every egg
## she lays is a drone until she does. It does not pause the colony -- the
## run carries on underneath, as it does for every other HUD window.
##
## Its one action now is "Lay drones in the hive", which simply closes it:
## she is already laying. COL-11 adds nuptial flights as a second choice.

var headline: Label
var detail: Label
var lay_btn: Button
## How many takeovers this window has explained, for the COL-10 test.
var takeovers_shown: int = 0

func _ready() -> void:
	setup_layer("succession", "succession_panel")
	build_left_window(330)
	build_scroll_body()

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 4)
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll_container.add_child(column)

	var title := Label.new()
	title.text = "A new queen"
	title.theme_type_variation = "Heading"
	column.add_child(title)

	column.add_child(HSeparator.new())

	headline = _make_label(column, "Body")
	detail = _make_label(column, "Small")

	lay_btn = Button.new()
	lay_btn.text = "Lay drones in the hive"
	for state in ["normal", "hover", "pressed", "focus", "disabled"]:
		lay_btn.add_theme_stylebox_override(state, UiTheme.button_stylebox(state))
	lay_btn.pressed.connect(func(): close())
	column.add_child(lay_btn)
	connect_left_window_reflow()

func _make_label(column: VBoxContainer, variation: String) -> Label:
	var label := Label.new()
	label.theme_type_variation = variation
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size = Vector2(300, 0)
	column.add_child(label)
	return label

## Called by main.gd with the gyne who has just become queen.
func open_for(new_queen: Node2D) -> void:
	var who: String = new_queen.bee_name if new_queen.bee_name != "" else "Gyne %d" % new_queen.bee_id
	headline.text = "The queen has died. %s, the oldest gyne in the hive, has taken her place." % who
	detail.text = (
		"She has not mated, so every egg she lays will hatch as a drone: a male who eats "
		+ "from the stores but does no work. Until she mates, no new workers will be raised."
	)
	takeovers_shown += 1
	open()
