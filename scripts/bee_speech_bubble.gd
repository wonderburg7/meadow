extends Node2D
## A short speech bubble anchored to one specific bee instead of the
## screen corner -- reuses gallerin_panel.gd's bubble shape (PanelContainer
## + Label, autowrap, timed dismissal), just following a world position
## every frame rather than sitting fixed in the corner. Self-contained and
## self-freeing, same spirit as click_marker.gd: nothing in the simulation
## reads it. Built for Challenge 1's 1.18 farewell line, but nothing here
## names that stage, so anything wanting a bee-anchored line later can
## reuse it as-is.

const BUBBLE_WIDTH := 220.0
const LIFETIME := 6.0
## Above the bee, not the corner -- centred horizontally on her.
const OFFSET := Vector2(-BUBBLE_WIDTH / 2.0, -70.0)

var bee: Node2D
var _panel: PanelContainer
var _label: Label
var _timer: float = LIFETIME

func _ready() -> void:
	z_index = 96
	_panel = PanelContainer.new()
	_panel.custom_minimum_size = Vector2(BUBBLE_WIDTH, 0)
	add_child(_panel)

	_label = Label.new()
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label.custom_minimum_size = Vector2(BUBBLE_WIDTH - 20.0, 0)
	_panel.add_child(_label)

func show_text(for_bee: Node2D, text: String) -> void:
	bee = for_bee
	_label.text = text
	_timer = LIFETIME
	_follow()

func _process(delta: float) -> void:
	if not is_instance_valid(bee):
		queue_free()
		return
	_follow()
	_timer -= delta
	if _timer <= 0.0:
		queue_free()

## Bees reparent between hive_root and meadow_root as they cross the
## entrance (world_building.move_bee_into_hive/out_of_hive) -- following
## whichever root she's currently in, rather than assuming one, keeps the
## bubble correctly placed if she's still mid-departure when it fires.
func _follow() -> void:
	var bee_parent := bee.get_parent()
	if bee_parent != null and get_parent() != bee_parent:
		reparent(bee_parent, false)
	position = bee.position + OFFSET
