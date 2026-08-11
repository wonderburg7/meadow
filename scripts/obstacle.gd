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

## Shown when the player clicks this thing in the meadow.
func display_name() -> String:
	return "Tree" if kind == Kind.TREE else "Raised ground"

func description() -> String:
	if kind == Kind.TREE:
		return "A tree. Bees cannot fly through the trunk and canopy, so they steer round it. Nothing grows in its shade."
	return "A plateau of raised ground, standing well above the meadow. Trees and flowers grow on top of it, but your bees cannot climb the bank, so all of it is out of reach and they have to walk the long way round. A later movement upgrade will open it up."

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
## Raised ground is a whole region of the meadow, not a single prop: a
## broad grassy plateau standing above the field, with its own trees and
## flowers growing on top of it. Those are scenery -- they aren't in the
## "flowers" group, so no forager ever targets them. That's the point:
## you can see resources up there and you cannot reach them, until a
## movement upgrade lets bees climb.
##
## Drawn as a low bank with a stepped edge: a dark shadow skirt, a bare
## earth cliff face, then the green top surface with a heavy rim, so the
## boundary bees have to walk around is unmistakable at any zoom.
func _build_raised_area() -> void:
	var edge := Shapes.circle_points(radius, 26)

	var shadow := Polygon2D.new()
	shadow.polygon = Shapes.circle_points(radius * 1.05, 26)
	shadow.position = Vector2(radius * 0.06, radius * 0.08)
	shadow.color = Color(0.16, 0.20, 0.12, 0.5)
	add_child(shadow)

	# the exposed earth of the bank itself
	var cliff := Polygon2D.new()
	cliff.polygon = edge
	cliff.color = Color(0.45, 0.36, 0.24)
	add_child(cliff)

	# the flat top, inset so the earth shows as a rim all the way round
	var top := Polygon2D.new()
	top.polygon = Shapes.circle_points(radius * 0.9, 26)
	top.position = Vector2(0, -radius * 0.06)
	top.color = Color(0.36, 0.5, 0.28)   # greener and lighter than the meadow
	add_child(top)

	var rim := Line2D.new()
	_close_loop(rim, Shapes.circle_points(radius * 0.9, 26))
	rim.position = Vector2(0, -radius * 0.06)
	rim.width = 2.5
	rim.default_color = Color(0.24, 0.34, 0.18, 0.9)
	add_child(rim)

	var outline := Line2D.new()
	_close_loop(outline, edge)
	outline.width = 4.0
	outline.default_color = Color(0.20, 0.14, 0.07, 0.98)
	add_child(outline)

	_scatter_scenery()

## Trees and flowers growing on top of the plateau. Deliberately plain
## Polygon2Ds rather than real Flower/Obstacle nodes -- they are out of
## reach, so they must not join any group the simulation looks at.
func _scatter_scenery() -> void:
	var rng := RandomNumberGenerator.new()
	# seeded from where this area sits, so a given meadow always grows
	# the same scenery rather than reshuffling on every rebuild
	rng.seed = int(abs(position.x) * 7919 + abs(position.y) * 104729)

	var tree_count: int = int(radius / 55.0) + 1
	for i in range(tree_count):
		var spot := _scenery_spot(rng, 0.62)
		var size: float = rng.randf_range(16.0, 26.0)

		var trunk := Polygon2D.new()
		trunk.polygon = Shapes.square_points(Vector2(size * 0.22, size * 0.55))
		trunk.position = spot + Vector2(0, size * 0.3)
		trunk.color = Color(0.32, 0.22, 0.13)
		add_child(trunk)

		for offset in [Vector2.ZERO, Vector2(-size * 0.35, size * 0.12), Vector2(size * 0.35, size * 0.12)]:
			var leaf := Polygon2D.new()
			leaf.polygon = Shapes.circle_points(size * 0.6, 12)
			leaf.position = spot + offset
			leaf.color = Color(0.13, 0.27, 0.12)
			add_child(leaf)

	var flower_count: int = int(radius / 14.0)
	var petal_colours := [
		Color(0.95, 0.85, 0.35), Color(0.9, 0.45, 0.6),
		Color(0.75, 0.6, 0.95), Color(0.95, 0.95, 0.9),
	]
	for i in range(flower_count):
		var bloom := Polygon2D.new()
		bloom.polygon = Shapes.circle_points(rng.randf_range(2.5, 4.5), 8)
		bloom.position = _scenery_spot(rng, 0.8)
		bloom.color = petal_colours[rng.randi() % petal_colours.size()]
		add_child(bloom)

## A point on the top surface, kept in from the edge so nothing appears
## to hang over the cliff.
func _scenery_spot(rng: RandomNumberGenerator, spread: float) -> Vector2:
	var angle := rng.randf() * TAU
	var distance := sqrt(rng.randf()) * radius * spread
	return Vector2(cos(angle), sin(angle)) * distance + Vector2(0, -radius * 0.06)

func _close_loop(line: Line2D, points: PackedVector2Array) -> void:
	for p in points:
		line.add_point(p)
	line.add_point(points[0])
