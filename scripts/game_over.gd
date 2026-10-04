extends CanvasLayer
## Shown when the queen dies.
##
## She is the only bee that can lay, and there is no succession yet, so
## losing her ends the colony -- everything still alive will age out
## without replacement. The run is stopped rather than left to wind down
## on its own, because watching a doomed colony starve for ten minutes
## isn't a game state worth sitting in.

const UI = preload("res://scripts/ui.gd")
const UiTheme = preload("res://scripts/ui_theme.gd")
const SaveSlots = preload("res://scripts/save_slots.gd")
const Levels = preload("res://scripts/levels.gd")
const SavesPanel = preload("res://scripts/saves_panel.gd")

signal restart_requested()
signal menu_requested()

var summary_label: Label
var checkpoint_btn: Button
var _checkpoint_path: String = ""
var _checkpoint_name: String = ""

func _ready() -> void:
	process_mode = PROCESS_MODE_ALWAYS   # still works while the run is paused
	layer = 25                           # above the main menu
	visible = false
	add_to_group("game_over")

	var backdrop := ColorRect.new()
	backdrop.color = Color(0.10, 0.03, 0.03, 0.9)
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

	var title := Label.new()
	title.text = "The queen is dead"
	title.theme_type_variation = "Heading"
	UiTheme.bind_color(title, "font_color", "danger")
	column.add_child(title)

	var body := Label.new()
	body.text = (
		"She was the only bee in the colony that could lay, and there is no "
		+ "successor. No more eggs will be laid, and every worker still alive "
		+ "will age out without a replacement.\n\nThe colony is over."
	)
	body.theme_type_variation = "Body"
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.custom_minimum_size = Vector2(430, 0)
	column.add_child(body)

	summary_label = Label.new()
	summary_label.theme_type_variation = "Small"
	column.add_child(summary_label)

	column.add_child(HSeparator.new())

	checkpoint_btn = Button.new()
	checkpoint_btn.custom_minimum_size = Vector2(0, 32)
	checkpoint_btn.visible = false
	checkpoint_btn.pressed.connect(_on_checkpoint_pressed)
	column.add_child(UI.with_info(checkpoint_btn, "Reload the run as it was on that day, the same way the Saves window loads a checkpoint."))

	var restart_btn := Button.new()
	restart_btn.text = "Try again"
	restart_btn.custom_minimum_size = Vector2(0, 32)
	restart_btn.pressed.connect(func(): restart_requested.emit())
	column.add_child(UI.with_info(restart_btn, "Start the run again at the same stage, with the same tuning values."))

	var menu_btn := Button.new()
	menu_btn.text = "Main menu"
	menu_btn.custom_minimum_size = Vector2(0, 32)
	menu_btn.pressed.connect(func(): menu_requested.emit())
	column.add_child(UI.with_info(menu_btn, "Go back to the menu and pick a different starting stage."))

## `day` and `bees` are shown as a short epitaph for the run.
## The gyne count leads, because it is the score. A colony that lasted a
## hundred days and released nothing achieved nothing that a season is
## for; one that lasted forty and got three away did well.
func open(day: int, bees: int, nectar: float, honey: float) -> void:
	var lines: Array = []
	if Session.gynes_released > 0:
		lines.append("%d gyne%s got away" % [
			Session.gynes_released, "" if Session.gynes_released == 1 else "s",
		])
	else:
		lines.append("No gynes got away — nothing carries on from this colony")
	lines.append("Lasted %d days · %d bees still alive · %d nectar and %d honey in the comb" % [
		day, bees, int(round(nectar)), int(round(honey)),
	])
	summary_label.text = "\n".join(lines)
	_offer_checkpoint()
	visible = true
	get_tree().paused = true

func _on_checkpoint_pressed() -> void:
	if not SavesPanel.reload_from(get_tree(), _checkpoint_path, _checkpoint_name):
		summary_label.text += "\nThat checkpoint could not be read."

## Colony Runs only (a Challenge keeps its own rollback): offers the newest
## of the run's rotating checkpoints that still exists on disk.
func _offer_checkpoint() -> void:
	checkpoint_btn.visible = false
	var level: Dictionary = Levels.get_level(Session.starting_level)
	if str(level.get("run_type", "")) != "colony":
		return
	var slug := SaveSlots.slugify(Session.run_name)
	var checkpoints: Dictionary = {}
	for entry in SaveSlots.list_slots():
		if entry["slug"] == slug:
			checkpoints = entry.get("checkpoints", {})
	var best_time := -1
	for number in checkpoints:
		var path := SaveSlots.checkpoint_path(slug, int(number))
		var saved_at := int(checkpoints[number].get("saved_at", 0))
		if FileAccess.file_exists(path) and saved_at > best_time:
			best_time = saved_at
			_checkpoint_path = path
			_checkpoint_name = Session.run_name
			checkpoint_btn.text = "Load the latest checkpoint (day %d)" % int(checkpoints[number].get("day", 0))
			checkpoint_btn.visible = true
