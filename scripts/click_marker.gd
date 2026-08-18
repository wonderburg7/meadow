extends Node2D
## A brief expanding, fading ring where the player right-clicked to send
## a selected bee somewhere -- pure visual feedback, nothing in the
## simulation reads it. Same self-fading, self-freeing pattern as
## death_marker.gd, just much shorter-lived.

const Shapes = preload("res://scripts/shapes.gd")

const LIFETIME := 0.4
const START_RADIUS := 4.0
const END_RADIUS := 16.0
const RING_COLOUR := Color(1.0, 1.0, 1.0, 0.7)

var age_seconds: float = 0.0
var ring: Polygon2D

func _ready() -> void:
	z_index = 90   # above bees and comb, below the drag-selection box
	ring = Polygon2D.new()
	ring.polygon = Shapes.circle_points(START_RADIUS, 20)
	ring.color = RING_COLOUR
	add_child(ring)

func _process(delta: float) -> void:
	age_seconds += delta
	if age_seconds >= LIFETIME:
		queue_free()
		return
	var t: float = age_seconds / LIFETIME
	ring.polygon = Shapes.circle_points(lerpf(START_RADIUS, END_RADIUS, t), 20)
	ring.color.a = RING_COLOUR.a * (1.0 - t)
