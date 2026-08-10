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

## Pointy-top hexagon centred on origin. `size` is the distance from
## the centre to any corner.
static func hexagon_points(size: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in range(6):
		var angle := deg_to_rad(60.0 * i - 30.0)
		points.append(Vector2(cos(angle), sin(angle)) * size)
	return points

## Converts a pixel position back to the nearest pointy-top axial hex.
## Used to work out which tile a bee is standing on, so terrain can slow
## it down.
static func pixel_to_hex(point: Vector2, size: float) -> Vector2i:
	var qf := (sqrt(3.0) / 3.0 * point.x - point.y / 3.0) / size
	var rf := (2.0 / 3.0 * point.y) / size
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

## Converts pointy-top hex axial coordinates (q, r) to pixel position.
static func hex_to_pixel(q: int, r: int, size: float) -> Vector2:
	var x := size * sqrt(3.0) * (q + r / 2.0)
	var y := size * 1.5 * r
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
