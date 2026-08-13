extends RefCounted
## A coarse grid over the meadow, so "what is near this point" doesn't
## have to look at everything.
##
## Both the questions this answers were linear scans before:
## `_pick_flower` walked all 250 flowers, and `_first_blocker` walked
## every obstacle. Each is cheap on its own; both are asked by every bee,
## several times a second, which is what makes them the thing that
## decides how many bees the game can run.
##
## Deliberately the simplest structure that works. A quadtree would be
## better if things moved, but flowers and obstacles don't -- they are
## planted, they sit there, and they are removed one at a time. For a
## static set, a flat dictionary of buckets beats anything cleverer
## because the lookup is two integer divisions and a hash.

## Bucket size in world units. Wants to be comfortably larger than the
## radius most queries use, so a query touches four buckets at worst,
## and small enough that a bucket holds a handful of things rather than
## dozens. 200 puts roughly two or three flowers in each.
var cell_size: float = 200.0
var buckets: Dictionary = {}      # Vector2i -> Array of nodes

func _init(bucket_size: float = 200.0) -> void:
	cell_size = max(1.0, bucket_size)

func _key(point: Vector2) -> Vector2i:
	return Vector2i(int(floor(point.x / cell_size)), int(floor(point.y / cell_size)))

func clear() -> void:
	buckets.clear()

func add(node: Node2D) -> void:
	if not is_instance_valid(node):
		return
	var key := _key(node.position)
	if not buckets.has(key):
		buckets[key] = []
	buckets[key].append(node)

func remove(node: Node2D) -> void:
	var key := _key(node.position)
	if buckets.has(key):
		buckets[key].erase(node)

## Rebuilds from scratch. Cheaper than it sounds and far less error-prone
## than incremental maintenance -- called when the meadow is reseeded,
## not per frame.
func rebuild(nodes: Array) -> void:
	clear()
	for node in nodes:
		add(node)

## Everything within `radius` of `point`, plus a few extras from the
## corners of the buckets touched. Callers filter by exact distance
## anyway, so returning a slightly generous set costs nothing.
func near(point: Vector2, radius: float) -> Array:
	var out: Array = []
	var span := int(ceil(radius / cell_size))
	var centre := _key(point)
	for dx in range(-span, span + 1):
		for dy in range(-span, span + 1):
			var bucket: Array = buckets.get(Vector2i(centre.x + dx, centre.y + dy), [])
			for node in bucket:
				if is_instance_valid(node):
					out.append(node)
	return out

## The nearest node to `point` for which `accept` returns true, searching
## outward one ring of buckets at a time and stopping as soon as a ring
## produces nothing better.
##
## Searching outward matters: the whole point is to avoid looking at
## distant things, and a query that widened to the whole map on a miss
## would be slower than the scan it replaced. `max_radius` bounds it.
func nearest(point: Vector2, max_radius: float, accept: Callable) -> Node2D:
	var best: Node2D = null
	var best_distance := INF
	var centre := _key(point)
	var max_rings := int(ceil(max_radius / cell_size))

	for ring in range(max_rings + 1):
		# Once something has been found, one more ring is enough: nothing
		# beyond it can be closer than a bucket's width further away.
		if best != null and float(ring - 1) * cell_size > best_distance:
			break
		for dx in range(-ring, ring + 1):
			for dy in range(-ring, ring + 1):
				# only the outer edge of this ring; the inside was done
				if ring > 0 and abs(dx) != ring and abs(dy) != ring:
					continue
				for node in buckets.get(Vector2i(centre.x + dx, centre.y + dy), []):
					if not is_instance_valid(node) or not accept.call(node):
						continue
					var d: float = point.distance_to(node.position)
					if d < best_distance and d <= max_radius:
						best_distance = d
						best = node
	return best

## How many things are indexed, for the debug readout.
func size() -> int:
	var total := 0
	for bucket in buckets.values():
		total += bucket.size()
	return total
