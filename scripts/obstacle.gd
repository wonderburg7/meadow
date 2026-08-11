extends Node2D
## A static obstacle in the meadow -- a tree or a raised area -- that
## foraging bees have to go round.
##
## The meadow has no navmesh (unlike the hive, which routes over a hex
## grid with A*). Two lighter mechanisms stand in for one:
##
##   1. Bee._avoid_obstacles aims at a point that clears the obstacle
##      whenever the straight line to a target would cut through it, so
##      bees curve round rather than heading into it.
##   2. Bee._block_obstacles refuses to let a bee's position end up
##      inside a solid obstacle at all, sliding it along the edge
##      instead. This is the hard guarantee: however a bee is steered,
##      commanded or nudged, it cannot end up on raised ground.
##
## Raised ground is solid until a later movement upgrade lets bees cross
## it; trees are solid too, since a trunk is a trunk.

const Shapes = preload("res://scripts/shapes.gd")

enum Kind { TREE, RAISED }

var kind: int = Kind.TREE
var radius: float = 30.0
## Bees can neither fly over nor walk through this. Left as a variable
## rather than derived from `kind` so a future "can cross raised ground"
## upgrade can simply clear it on every raised area in the meadow.
var solid: bool = true

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

## Raised ground was previously a sandy disc with a thin rim, which
## disappeared into the grass at any distance. It's now drawn the way a
## contour map draws a hill: a dark shadow skirt, then two stepped
## terraces in rising tones, a bright cap, and a heavy outline round the
## whole thing. The stepped edges make the boundary unmistakable, which
## matters because that boundary is now a wall bees have to walk round.
func _build_raised_area() -> void:
	# a shadow offset down-right, so the mound reads as standing proud of
	# the ground rather than being a patch painted on it
	var shadow := Polygon2D.new()
	shadow.polygon = Shapes.circle_points(radius * 1.06, 24)
	shadow.position = Vector2(radius * 0.10, radius * 0.12)
	shadow.color = Color(0.16, 0.20, 0.12, 0.55)
	add_child(shadow)

	# terraces, outermost first
	var terraces := [
		{"scale": 1.0, "color": Color(0.52, 0.44, 0.30)},
		{"scale": 0.78, "color": Color(0.66, 0.57, 0.39)},
		{"scale": 0.54, "color": Color(0.79, 0.70, 0.50)},
		{"scale": 0.30, "color": Color(0.90, 0.83, 0.62)},
	]
	for step in terraces:
		var terrace := Polygon2D.new()
		terrace.polygon = Shapes.circle_points(radius * step.scale, 24)
		terrace.color = step.color
		add_child(terrace)

		var rim := Line2D.new()
		_close_loop(rim, Shapes.circle_points(radius * step.scale, 24))
		rim.width = 2.0
		rim.default_color = Color(0.26, 0.19, 0.10, 0.75)
		add_child(rim)

	# the boundary bees cannot cross, drawn thick so it's obvious where
	# the no-go edge actually is
	var outline := Line2D.new()
	_close_loop(outline, Shapes.circle_points(radius, 24))
	outline.width = 4.0
	outline.default_color = Color(0.20, 0.14, 0.07, 0.98)
	add_child(outline)

func _close_loop(line: Line2D, points: PackedVector2Array) -> void:
	for p in points:
		line.add_point(p)
	line.add_point(points[0])
