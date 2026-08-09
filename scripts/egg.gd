extends Node2D
## A freshly laid egg sitting on the hive floor, waiting for a nursery
## worker to carry it to an empty cell. Once placed, the egg node is
## freed and the cell takes over as "brood".

const Shapes = preload("res://scripts/shapes.gd")

var claimed_by: Node2D = null   # the nursery worker on its way to collect this

func _ready() -> void:
	add_to_group("loose_eggs")

	var shell := Polygon2D.new()
	shell.polygon = Shapes.circle_points(6.0)
	shell.color = Color(0.98, 0.97, 0.9)
	add_child(shell)

	var outline := Polygon2D.new()
	outline.polygon = Shapes.circle_points(4.0)
	outline.color = Color(0.9, 0.88, 0.75)
	add_child(outline)
