extends RefCounted
## Small drawing/geometry helpers shared by the placeholder-art scripts.
## Usage: const Shapes = preload("res://scripts/shapes.gd")
##        polygon = Shapes.circle_points(radius)

static func circle_points(radius: float, segments: int = 16) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in range(segments):
		var angle := TAU * i / segments
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	return points

static func square_points(size: Vector2) -> PackedVector2Array:
	var half := size / 2.0
	return PackedVector2Array([
		Vector2(-half.x, -half.y),
		Vector2(half.x, -half.y),
		Vector2(half.x, half.y),
		Vector2(-half.x, half.y),
	])

## A regular flat-top hexagon's height (corner to corner) is
## `size * sqrt(3)`. Multiplying that height by this factor instead gives
## exactly `size` -- a flattened hex whose width:height ratio is 2:1,
## matching the `wax.cell.empty.png` resprite's 32x16 footprint at any
## `size`. See `Session.use_sprite_hex_grid`.
const SQUASH := 1.0 / 1.7320508075688772

## Flat-top hexagon centred on origin. `size` is the distance from the
## centre to any corner. Every cell gets a flat edge on top and bottom
## this way, rather than a point -- corners start at 0 degrees instead
## of the old pointy-top's -30, and nothing else here needs to know
## which orientation this is: hex_to_pixel/pixel_to_hex below carry the
## rest of it. `squashed` flattens the hex vertically to match the
## sprite-aligned grid (see `SQUASH`); leave it false for anything not
## sharing the hive's own grid (menu decoration, icon backgrounds).
static func hexagon_points(size: float, squashed: bool = false) -> PackedVector2Array:
	var y_scale := SQUASH if squashed else 1.0
	var points := PackedVector2Array()
	for i in range(6):
		var angle := deg_to_rad(60.0 * i)
		points.append(Vector2(cos(angle) * size, sin(angle) * size * y_scale))
	return points

## The midpoint of each of a hexagon's six edges, in the same order as
## `hexagon_points`. Bees loading or unloading a comb cell stand on one
## of these rather than piling into the middle of it, which is what caps
## a cell at six workers at once -- one per wall.
static func hexagon_edge_midpoints(size: float, squashed: bool = false) -> Array:
	var corners := hexagon_points(size, squashed)
	var midpoints: Array = []
	for i in range(6):
		midpoints.append((corners[i] + corners[(i + 1) % 6]) * 0.5)
	return midpoints

## Converts a pixel position back to the nearest flat-top axial hex. Used
## to work out which tile a bee is standing on, so terrain can slow it
## down. `squashed` must match whatever `hex_to_pixel` placed the grid
## with, or a click/position will resolve to the wrong tile.
static func pixel_to_hex(point: Vector2, size: float, squashed: bool = false) -> Vector2i:
	# hex_to_pixel scales y by SQUASH going out, so un-scale it coming
	# back in before the ordinary flat-top inversion below.
	var y: float = point.y / SQUASH if squashed else point.y
	var qf := (2.0 / 3.0 * point.x) / size
	var rf := (-1.0 / 3.0 * point.x + sqrt(3.0) / 3.0 * y) / size
	return _axial_round(qf, rf)

## Hex coordinates don't round like square ones -- you have to round in
## cube space and repair whichever axis drifted furthest.
static func _axial_round(qf: float, rf: float) -> Vector2i:
	var sf := -qf - rf
	var q := roundi(qf)
	var r := roundi(rf)
	var s := roundi(sf)
	var q_diff: float = abs(float(q) - qf)
	var r_diff: float = abs(float(r) - rf)
	var s_diff: float = abs(float(s) - sf)
	if q_diff > r_diff and q_diff > s_diff:
		q = -r - s
	elif r_diff > s_diff:
		r = -q - s
	return Vector2i(q, r)

## How many steps apart two axial hexes are.
static func hex_distance(a: Vector2i, b: Vector2i) -> int:
	var dq := a.x - b.x
	var dr := a.y - b.y
	return int((abs(dq) + abs(dq + dr) + abs(dr)) / 2)

## How many steps a hex is from the centre.
static func hex_ring_index(hex: Vector2i) -> int:
	return hex_distance(hex, Vector2i(0, 0))

## Every axial coordinate sitting exactly `radius` steps from the centre.
static func hex_ring(radius: int) -> Array:
	if radius <= 0:
		return [Vector2i(0, 0)]
	var results: Array = []
	var directions := [
		Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 1),
		Vector2i(-1, 0), Vector2i(0, -1), Vector2i(1, -1),
	]
	# The starting corner has to match the rotation order of `directions`
	# below. Getting these two out of step meant only the first side of
	# each ring landed on the ring at all and the rest spiralled away,
	# which is what turned the hive into a wedge.
	var hex := Vector2i(0, -radius)
	for dir_index in range(6):
		for step in range(radius):
			results.append(hex)
			hex += directions[dir_index]
	return results

## Converts flat-top hex axial coordinates (q, r) to pixel position.
## `q = 0` is a perfectly straight vertical column (x stays 0 whatever r
## is) -- world_building.gd's entrance tunnel relies on that to carve a
## single-tile-wide shaft rather than the old alternating-width one.
## `squashed` compresses only the y axis (see `SQUASH`), so that column
## stays exactly vertical either way -- every caller placing something on
## this grid needs to pass the same `squashed` value `pixel_to_hex` and
## `hexagon_points` were given, or positions and hit-tests drift apart.
static func hex_to_pixel(q: int, r: int, size: float, squashed: bool = false) -> Vector2:
	var y_scale := SQUASH if squashed else 1.0
	var x := size * 1.5 * q
	var y := size * sqrt(3.0) * (r + q / 2.0) * y_scale
	return Vector2(x, y)

## Points along a circular arc, centred on origin, from `from_degrees`
## round to `to_degrees` (anticlockwise). Used to draw the hive wall as
## a near-complete ring with a gap left for the entrance.
static func arc_points(radius: float, from_degrees: float, to_degrees: float, segments: int = 64) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in range(segments + 1):
		var t := float(i) / float(segments)
		var angle := deg_to_rad(lerp(from_degrees, to_degrees, t))
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	return points

## The axial coordinate of a single position in the outward spiral,
## without building the whole list first. Used when a builder adds one
## more cell to an existing comb.
static func hex_spiral_at(index: int) -> Vector2i:
	var all := hex_spiral(index + 1)
	return all[index]

## Returns `count` axial hex coordinates in an outward spiral from the
## centre, so a hive of any size fills in as a tidy honeycomb blob.
static func hex_spiral(count: int) -> Array:
	var results := [Vector2i(0, 0)]
	# the six directions you step in to walk around a hex ring
	var directions := [
		Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 1),
		Vector2i(-1, 0), Vector2i(0, -1), Vector2i(1, -1),
	]
	var radius := 1
	while results.size() < count:
		# same corner/rotation pairing as hex_ring -- see the note there
		var hex := Vector2i(0, -radius)
		for dir_index in range(6):
			for step in range(radius):
				if results.size() >= count:
					break
				results.append(hex)
				hex += directions[dir_index]
		radius += 1
	return results.slice(0, count)
