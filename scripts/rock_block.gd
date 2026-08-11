extends Polygon2D
## Bedrock. A ring of these wraps the outside of the soil, so the ground
## the colony can dig into has a hard edge.
##
## Unlike soil, rock can't be marked, can't be mined and can't be walked
## through -- it isn't in the "soil_blocks" group, so the click-to-mark
## handler and the miner's job search both skip it, and hive.gd's
## `_is_solid` treats it as permanently blocking when it builds routes.

const Shapes = preload("res://scripts/shapes.gd")

const ROCK_COLOR := Color(0.28, 0.28, 0.32)

var axial: Vector2i = Vector2i.ZERO
var block_size: float = 17.0

func _ready() -> void:
	add_to_group("rock_blocks")
	block_size = GameConfig.hive_cell_size
	# oversized like soil so neighbouring blocks fuse into one solid mass
	# with no seams between them
	polygon = Shapes.hexagon_points(block_size * 1.15)
	color = ROCK_COLOR

func setup(hex: Vector2i) -> void:
	axial = hex
