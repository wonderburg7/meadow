extends Node2D
## PP-2 (plans/now/pollination.md): a small "+1" that rises and fades over a
## flower each time pollination.gd pays a Pollinator Point. Presentation
## only: it listens to pollination.gd's points_earned and never reads or
## writes simulation state, so a run plays out the same with or without it.
##
## A fixed pool of POOL slots, each just a position and an age -- no node per
## pop, and nothing allocated while it runs. When every slot is busy the
## oldest is reused. It processes only while a pop is showing, so an idle
## meadow costs nothing per frame.
##
## Created by hud.gd, which parents it under main (the world) so it draws in
## meadow coordinates, above the flowers and bees.

const UiTheme = preload("res://scripts/ui_theme.gd")

const POOL := 8
## How long a "+1" shows, in seconds of game time (so it holds still while
## the game is paused), and how far it rises over that time.
const LIFETIME := 0.9
const RISE := 22.0
## Where it starts, relative to the flower's centre.
const START := Vector2(-6.0, -12.0)
const FONT_SIZE := 14

var _positions: PackedVector2Array = PackedVector2Array()
## Seconds since the slot's pop began; LIFETIME or more is a free slot.
var _ages: PackedFloat32Array = PackedFloat32Array()
var _font: Font
var _colour: Color

func _ready() -> void:
	z_index = 90
	_positions.resize(POOL)
	_ages.resize(POOL)
	_ages.fill(LIFETIME)
	var theme := UiTheme.build_theme()
	_font = theme.default_font if theme.default_font != null else ThemeDB.fallback_font
	_colour = UiTheme.color("warning")
	set_process(false)

## pollination.gd's points_earned. The flower may die later; only its
## position is kept.
func show_at(flower: Node2D) -> void:
	if not is_instance_valid(flower):
		return
	var slot := 0
	for i in POOL:
		if _ages[i] >= LIFETIME:
			slot = i
			break
		if _ages[i] > _ages[slot]:
			slot = i
	_positions[slot] = flower.global_position + START
	_ages[slot] = 0.0
	set_process(true)
	queue_redraw()

func active_count() -> int:
	var count := 0
	for age in _ages:
		if age < LIFETIME:
			count += 1
	return count

func _process(delta: float) -> void:
	var any := false
	for i in POOL:
		if _ages[i] < LIFETIME:
			_ages[i] += delta
			any = any or _ages[i] < LIFETIME
	if not any:
		set_process(false)
	queue_redraw()

func _draw() -> void:
	if _font == null:
		return
	for i in POOL:
		var age: float = _ages[i]
		if age >= LIFETIME:
			continue
		var t := age / LIFETIME
		var colour := _colour
		colour.a = 1.0 - t * t
		draw_string(_font, to_local(_positions[i]) + Vector2(0.0, -RISE * t), "+1",
			HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, colour)
