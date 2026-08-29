extends Button
## A flat, invisible button clipped to its own hexagon rather than its
## full bounding rectangle. main_menu.gd's honeycomb (UI-M) now tessellates
## with touching, vertically-offset tiles (Dave's 29 Aug request) -- their
## rectangular bounding boxes overlap even though the hexagons themselves
## don't, so a plain Button's rectangular hit test would let one tile
## steal clicks meant for its neighbour in the overlapping corners. This
## tests against the actual hexagon polygon instead.
##
## Usage: var btn := HexHitArea.new()
##        btn.hex_size = HEX_SIZE
##        btn.hex_center = bbox / 2.0   # where the hex is drawn within the tile

const Shapes = preload("res://scripts/shapes.gd")

var hex_size: float = 0.0
var hex_center: Vector2 = Vector2.ZERO

func _has_point(point: Vector2) -> bool:
	return Geometry2D.is_point_in_polygon(point - hex_center, Shapes.hexagon_points(hex_size))
