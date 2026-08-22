extends Node2D
## A mark left where a bee died, fading out over `death_marker_days`.
##
## Nothing in the simulation reads these. They exist so that losses are
## visible in the place they happened: a cluster of marks out at the far
## edge of the meadow says something a falling population number doesn't,
## which is that bees are running out of energy trying to work a patch
## that is too far away.
##
## `death_info` carries a plain snapshot of the bee at the moment she
## died -- taken in world_building.gd::mark_death() while she's still a
## valid node, since queue_free() hasn't actually removed her yet but
## nothing after this marker exists can safely read her fields again.
## Lets a click bring up what happened to her without needing the bee
## herself to still exist -- see input_selection.gd's death-marker click
## handling and hud.gd's show_object_summary.

const Shapes = preload("res://scripts/shapes.gd")
const CLICK_RADIUS := 10.0

var age_seconds: float = 0.0
var lifetime_seconds: float = 1000.0
var death_info: Dictionary = {}

var body: Polygon2D
var cross_a: Line2D
var cross_b: Line2D

func _ready() -> void:
	add_to_group("death_markers")
	z_index = 1   # above the ground, below live bees
	lifetime_seconds = max(1.0, GameConfig.death_marker_days * GameConfig.seconds_per_day)

	# a small dark smudge with a cross over it -- legible at a glance
	# without being ghoulish about it
	body = Polygon2D.new()
	body.polygon = Shapes.circle_points(5.0, 12)
	body.color = Color(0.18, 0.16, 0.15, 0.75)
	add_child(body)

	cross_a = _make_stroke(Vector2(-4, -4), Vector2(4, 4))
	cross_b = _make_stroke(Vector2(4, -4), Vector2(-4, 4))

func _make_stroke(from_point: Vector2, to_point: Vector2) -> Line2D:
	var line := Line2D.new()
	line.add_point(from_point)
	line.add_point(to_point)
	line.width = 1.6
	line.default_color = Color(0.85, 0.85, 0.85, 0.8)
	add_child(line)
	return line

func _process(delta: float) -> void:
	age_seconds += delta
	if age_seconds >= lifetime_seconds:
		queue_free()
		return
	# fades steadily rather than vanishing, so an old loss is visibly
	# older than a fresh one
	modulate.a = 1.0 - (age_seconds / lifetime_seconds)
