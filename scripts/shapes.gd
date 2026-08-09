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
		# start each ring one step "up-left" from the centre
		var hex := Vector2i(-radius, radius)
		for dir_index in range(6):
			for step in range(radius):
				if results.size() >= count:
					break
				results.append(hex)
				hex += directions[dir_index]
		radius += 1
	return results.slice(0, count)
