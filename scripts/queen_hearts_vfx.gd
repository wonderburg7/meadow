extends Node2D
## Floating pixel-hearts over the queen -- pure celebration for Challenge
## 1's first hatch (1.16), cosmetic only, nothing in the simulation reads
## it. Same self-fading, self-freeing pattern as click_marker.gd, just a
## handful of little squares instead of one ring, each rising and fading
## on its own staggered delay.

const Shapes = preload("res://scripts/shapes.gd")

const HEART_COUNT := 4
const HEART_SIZE := 7.0
const HEART_COLOUR := Color(0.95, 0.35, 0.55, 0.9)
const RISE_DISTANCE := 46.0
const RISE_SECONDS := 1.8
const STAGGER_SECONDS := 0.35

var _age: float = 0.0
var _hearts: Array = []

func _ready() -> void:
	z_index = 94
	for i in range(HEART_COUNT):
		var heart := Polygon2D.new()
		heart.polygon = Shapes.square_points(Vector2.ONE * HEART_SIZE)
		heart.color = HEART_COLOUR
		heart.rotation = deg_to_rad(45.0)
		heart.position = Vector2(randf_range(-14.0, 14.0), randf_range(-6.0, 6.0))
		heart.visible = false
		add_child(heart)
		_hearts.append({"node": heart, "start": heart.position, "delay": i * STAGGER_SECONDS})

func _process(delta: float) -> void:
	_age += delta
	var still_going := false
	for entry in _hearts:
		var t: float = clampf((_age - entry.delay) / RISE_SECONDS, 0.0, 1.0)
		var node: Polygon2D = entry.node
		if _age < entry.delay:
			still_going = true
			continue
		if t >= 1.0:
			node.visible = false
			continue
		still_going = true
		node.visible = true
		node.position = entry.start + Vector2(0, -RISE_DISTANCE * t)
		node.color.a = HEART_COLOUR.a * (1.0 - t)
	if not still_going:
		queue_free()
