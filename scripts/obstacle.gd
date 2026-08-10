extends Node2D
## A static obstacle in the meadow -- a tree or a raised area -- that
## foraging bees steer around rather than fly straight through.
##
## The meadow has no real pathfinding (unlike the hive, which routes
## over a hex grid with A*). This is a lighter touch: Bee._avoid_obstacles
## checks whether the straight line to a target passes too close to an
## obstacle and, if so, aims at a point that clears it instead. That's
## enough to stop bees clipping through a trunk without building a full
## navmesh for open ground that's otherwise empty.

const Shapes = preload("res://scripts/shapes.gd")

enum Kind { TREE, RAISED }

var kind: int = Kind.TREE
var radius: float = 30.0

func _ready() -> void:
	add_to_group("obstacles")

func setup(obstacle_kind: int, obstacle_radius: float) -> void:
	kind = obstacle_kind
	radius = obstacle_radius

	if kind == Kind.TREE:
		_build_tree()
	else:
		_build_raised_area()

func _build_tree() -> void:
	# trunk
	var trunk := Polygon2D.new()
	trunk.polygon = Shapes.square_points(Vector2(radius * 0.25, radius * 0.6))
	trunk.position = Vector2(0, radius * 0.35)
	trunk.color = Color(0.35, 0.24, 0.14)
	add_child(trunk)

	# canopy -- a cluster of overlapping circles reads better than one
	# perfect disc
	var canopy_spots := [Vector2.ZERO, Vector2(-radius * 0.4, radius * 0.15), Vector2(radius * 0.4, radius * 0.15)]
	for spot in canopy_spots:
		var leaf := Polygon2D.new()
		leaf.polygon = Shapes.circle_points(radius * 0.65, 14)
		leaf.position = spot
		leaf.color = Color(0.16, 0.32, 0.14)
		add_child(leaf)

func _build_raised_area() -> void:
	var mound := Polygon2D.new()
	mound.polygon = Shapes.circle_points(radius, 16)
	mound.color = Color(0.5, 0.47, 0.4)
	add_child(mound)

	var highlight := Polygon2D.new()
	highlight.polygon = Shapes.circle_points(radius * 0.7, 16)
	highlight.position = Vector2(-radius * 0.15, -radius * 0.15)
	highlight.color = Color(0.58, 0.55, 0.47)
	add_child(highlight)
