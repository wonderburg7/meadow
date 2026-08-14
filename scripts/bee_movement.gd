extends RefCounted
## Steering and obstacle avoidance, split out of bee.gd -- see
## BEE_SPLIT_PLAN.md. This is the hottest path in the file: it runs every
## frame for every moving bee, which is what the 4fps investigation in
## PERF_PLAN.md was originally chasing before the real cause turned out
## to be _grounded()'s recursion.
##
## Holds no state of its own. `skirt_obstacle`, `skirt_turn` and
## `skirt_clear_frames` stay as vars on bee.gd itself (per the split
## plan's "all vars stay on bee.gd" rule, since more of them are read
## externally than moved) and are read and written here as
## `bee.skirt_obstacle` etc.
##
## Usage: const BeeMovement = preload("res://scripts/bee_movement.gd")
##        BeeMovement.move_towards(self, target, delta)

##
## This was rewritten after three failed patches, because the approach
## itself was wrong rather than the details.
##
## The old scheme aimed at a point on a circle of radius
## `max(clearance, current distance from the centre)`. That number is the
## bee's *own* distance from the obstacle, so the aim point sat on the
## circle the bee was already standing on. Moving towards it produced
## tangential motion and no radial motion at all -- the bee orbited the
## obstacle at a fixed distance forever, unable to get closer or further
## away. That is exactly the behaviour on screen. Every patch since then
## adjusted which way round the orbit went, which was never the problem.
##
## The rewrite steers at the *tangent point*: the place on the inflated
## circle where a straight line from the bee just grazes the obstacle.
## Three things follow from that, and they are what make it work:
##
##   1. The tangent point is never on the bee's current circle, so the
##      motion always has a radial component. No orbit is possible.
##   2. Walking a tangent line is the shortest way past a circle, so the
##      bee visibly makes for the edge and rounds it.
##   3. Once the bee passes the tangent point the obstacle is behind it
##      and the straight line to the target is clear, so the detour ends
##      by itself rather than needing to be detected.
##
## Underneath it all is a hard guarantee that does not depend on any of
## the geometry being right: bee.gd's `_watch_for_stalls` measures whether
## the bee is actually getting closer to where it is going, and if it
## isn't, moves it clear. A steering bug should cost a bee a few seconds,
## never the run.

## Room left round an obstacle when steering, and the hard boundary
## block_obstacles enforces. These two numbers have to satisfy two
## constraints, and getting them the wrong way round is what caused the
## orbiting in the first place:
##
##   BLOCK_MARGIN >= OBSTACLE_MARGIN
##     A bee pressed against the hard boundary must not be considered to
##     be inside the steering margin. When it was (block 8, steering 16),
##     a bee at the boundary counted as blocked by the very obstacle it
##     was touching -- in every direction, including directly away from
##     it. It could never report "the way is clear", so it circled at the
##     boundary forever. That is the orbit at fixed distance.
##
##   BLOCK_MARGIN < the clearance flowers are planted at
##     Otherwise a flower near a plateau sits inside the boundary and no
##     bee can ever physically reach it.
##
## 18 and 18 satisfy both, against a flower clearance of 30 (see
## main.gd's FLOWER_CLEARANCE).
const OBSTACLE_MARGIN := 18.0
const BLOCK_MARGIN := 18.0

## How far round the rim to aim when the bee is already at the boundary.
const SWEEP_STEP := 0.6

## How many consecutive clear frames before the bee forgets what it was
## going round.
##
## One clear frame used to be enough, and that was too eager. The
## blocker test can momentarily report the way clear part-way past an
## obstacle -- it is a line-of-sight check against a set that changes as
## the bee moves -- and dropping the commitment on that one frame lets
## the side be chosen afresh from an angle that has already swung past
## halfway. Which is precisely the shuffle the commitment exists to
## stop. Holding it for a few frames costs nothing: the turn is only
## ever read on a frame where there *is* a blocker.
const SKIRT_FORGET_FRAMES := 3

## Returns where the bee should actually head this frame: the target
## itself when the way is clear, or a tangent point past whatever is in
## the way.
static func avoid_obstacles(bee: Node2D, target: Vector2) -> Vector2:
	var blocker := first_blocker(bee, target)
	if blocker == null:
		# Clear for now, but not necessarily past it. See
		# SKIRT_FORGET_FRAMES.
		bee.skirt_clear_frames += 1
		if bee.skirt_clear_frames >= SKIRT_FORGET_FRAMES:
			bee.skirt_obstacle = null
			bee.skirt_clear_frames = 0
		return target
	bee.skirt_clear_frames = 0
	return tangent_past(bee, blocker, target)

## The nearest solid obstacle the straight line to `target` runs into,
## or null if the way is clear.
##
## `solid` is checked here as well as in block_obstacles. Without it,
## switching the scenery off left bees still steering round trees they
## could now walk straight through -- which is why turning the scenery
## off didn't free the stuck ones.
static func first_blocker(bee: Node2D, target: Vector2) -> Node2D:
	var to_target: Vector2 = target - bee.position
	var span: float = to_target.length()
	if span < 1.0:
		return null
	var direction: Vector2 = to_target / span

	var nearest: Node2D = null
	var nearest_along := INF
	for obstacle in obstacles_towards(bee, target):
		if not is_instance_valid(obstacle) or not obstacle.solid:
			continue
		var reach: float = obstacle.radius + OBSTACLE_MARGIN

		# Something the bee is standing next to but heading away from is
		# not in the way. Without this test a bee at the boundary of a
		# plateau reports itself blocked by that plateau whichever way it
		# faces, and can never decide it is past it.
		var to_obstacle: Vector2 = obstacle.position - bee.position
		var along: float = clamp(to_obstacle.dot(direction), 0.0, span)
		if along <= 0.5:
			continue

		# An obstacle whose margin contains the destination can't be
		# steered around and still arrived at -- a flower planted close to
		# a plateau, say. Ignore it and let the hard boundary slide the
		# bee round the edge instead, which does get there.
		if target.distance_to(obstacle.position) < reach:
			continue

		var closest_point: Vector2 = bee.position + direction * along
		if closest_point.distance_to(obstacle.position) >= reach:
			continue
		if along < nearest_along:
			nearest_along = along
			nearest = obstacle
	return nearest

## Where to aim in order to get past `obstacle`.
##
## The aim point always sits on the circle of radius R = obstacle radius
## plus the margin. That fixed R is the whole fix. The old code used
## `max(R, the bee's own distance from the centre)`, which put the aim
## point on whatever circle the bee happened to be standing on -- so the
## bee moved along that circle and never off it. Pure orbit.
##
## How far round the circle to aim depends on where the bee is:
##
##   Far out: aim at the silhouette edge, acos(R/d) round from the bee's
##   own bearing. That is the point where a straight line from the bee
##   just grazes the obstacle, so this is the shortest way past it.
##
##   At the boundary: acos(R/d) collapses to nothing, so step a fixed
##   SWEEP_STEP round instead. The bee walks round the edge until the
##   way ahead opens up.
##
## Both cases put the aim point somewhere the bee is not, and both pull
## it towards R rather than holding it wherever it started, so there is
## always motion both around and across.
static func tangent_past(bee: Node2D, obstacle: Node2D, target: Vector2) -> Vector2:
	var rim: float = obstacle.radius + OBSTACLE_MARGIN
	var from_centre: Vector2 = bee.position - obstacle.position
	var distance: float = from_centre.length()
	if distance < 0.01:
		from_centre = Vector2.RIGHT
		distance = 0.01

	var turn: float = committed_turn(bee, obstacle, target)
	var silhouette: float = acos(clamp(rim / distance, -1.0, 1.0)) if distance > rim else 0.0
	var offset: float = max(silhouette, SWEEP_STEP)
	var heading: float = from_centre.angle() + turn * offset
	return obstacle.position + Vector2(cos(heading), sin(heading)) * rim

	# Deliberately no recursion for the case where the way past one
	# obstacle points into its neighbour. first_blocker always returns
	# the *nearest* thing in the way, so as the bee advances the
	# neighbour becomes the nearest blocker and is routed round in its
	# turn, one obstacle at a time. Trying to solve the whole chain in
	# one frame is how the old code produced aim points that satisfied
	# neither obstacle.

## Which way round. Chosen once per obstacle and then held, because a
## choice remade every frame from an angle that changes as you act on it
## will flip back and forth at the halfway point -- that is the
## side-to-side shuffle. Committing to the longer way round is always
## better than oscillating.
static func committed_turn(bee: Node2D, obstacle: Node2D, target: Vector2) -> float:
	if bee.skirt_obstacle == obstacle and is_instance_valid(bee.skirt_obstacle):
		return bee.skirt_turn
	var here: float = (bee.position - obstacle.position).angle()
	var there: float = (target - obstacle.position).angle()
	var shorter_way: float = wrapf(there - here, -PI, PI)
	bee.skirt_obstacle = obstacle
	bee.skirt_turn = 1.0 if shorter_way >= 0.0 else -1.0
	return bee.skirt_turn

## Called when the world changes underneath a bee -- the scenery being
## toggled, or a bee being given a new order -- so no stale commitment to
## an obstacle that may no longer be solid survives into the next frame.
## bee.gd keeps a one-line wrapper (`clear_navigation_state`) so
## world_building.gd's call to `b.clear_navigation_state()` didn't have
## to change.
static func clear_navigation_state(bee: Node2D) -> void:
	bee.skirt_obstacle = null
	bee.skirt_clear_frames = 0
	bee._reset_stall_watch()

## The obstacle list, from main.gd's cache rather than a group query.
## Every bee asks about obstacles several times a frame; scanning the
## scene tree for them each time was one of the few things in here that
## scales badly with colony size. The meadow's obstacles never change
## during a run, so main.gd builds the list once.
static func obstacles(bee: Node2D) -> Array:
	if bee.world != null and is_instance_valid(bee.world):
		return bee.world.obstacles
	return bee.get_tree().get_nodes_in_group("obstacles")

## Which obstacles could matter for a move from here to `target`.
##
## The honest answer is "all fourteen of them", and that is what this
## returns. It briefly went through the spatial grid, which was a
## mistake worth writing down: the grid is a clear win for flowers, and
## a loss here, because the two questions are not the same shape.
##
## The flower search asks about 250 objects, eight times a second. The
## obstacle search asks about 14, sixty times a second, for every bee.
## Against 14 items in an array main.gd already holds, the grid query
## was slower than the scan it replaced -- 25 to 121 bucket lookups
## depending on how far the bee was flying, plus a fresh Array allocated
## every frame per bee. At sixty bees that is thousands of allocations a
## second, and allocation churn shows up as *uneven* frame times rather
## than a lower average. Since movement is speed * delta, uneven frames
## are visible directly as bees moving in little lurches.
##
## It also fed a set that changed as the bee moved into committed_turn,
## which is meant to be sticky. See SKIRT_FORGET_FRAMES.
##
## Kept as its own function rather than inlined: if the meadow ever
## holds hundreds of obstacles this is the one place that has to change,
## and the right fix then is to cache per journey, not per frame.
static func obstacles_towards(bee: Node2D, _target: Vector2) -> Array:
	return obstacles(bee)

## The hard half of obstacle handling. avoid_obstacles steers, which is
## enough most of the time but not a guarantee: a bee right-clicked onto
## a mound, or squeezed between two obstacles, could still end up on top
## of one. This refuses the move outright -- if the position a bee is
## about to take is inside a solid obstacle it gets pushed back out to
## the edge and slid along it, so it walks round the boundary instead of
## over it. Raised ground stays impassable until a movement upgrade
## clears `solid` on it.
static func block_obstacles(bee: Node2D, wanted: Vector2) -> Vector2:
	var result := wanted
	# Settle over a few rounds. Pushing clear of one obstacle can land a
	# bee inside the next one where two sit close together, and a single
	# pass would leave it there.
	for round_number in range(3):
		var moved := false
		for obstacle in obstacles(bee):
			if not is_instance_valid(obstacle) or not obstacle.solid:
				continue
			var edge: float = obstacle.radius + BLOCK_MARGIN
			var offset: Vector2 = result - obstacle.position
			var distance: float = offset.length()
			if distance >= edge:
				continue
			if distance < 0.01:
				# exactly on the centre (shouldn't happen) -- shove it out
				# in an arbitrary but consistent direction rather than
				# dividing by zero
				offset = Vector2.RIGHT
				distance = 1.0
			result = obstacle.position + offset / distance * edge
			moved = true
		if not moved:
			break
	return result

## Outdoors a bee flies straight. Inside the hive it walks a route over
## open tiles, because soil is solid. The route is recalculated only
## when the destination changes, not every frame.
static func move_towards(bee: Node2D, target: Vector2, delta: float) -> void:
	Perf.begin("bee_move")
	var step: float = bee.speed * bee._terrain_speed_factor() * delta

	if not bee._is_inside_hive():
		var wanted: Vector2 = bee.position.move_toward(avoid_obstacles(bee, target), step)
		bee.position = block_obstacles(bee, wanted)
		Perf.end("bee_move")
		return

	if target.distance_to(bee.path_goal) > 6.0 or bee.path_points.is_empty():
		bee.path_goal = target
		# Timed inside path_between itself (hive.gd), which is the
		# suspect the perf plan names first: an A* search over the whole
		# hive grid, potentially every frame per bee.
		bee.path_points = bee.hive.path_between(bee.position, target)
		bee.path_index = 0

	if bee.path_points.is_empty():
		Perf.end("bee_move")
		return   # no safe route -- stay put rather than cutting through soil

	# walk the waypoints, spending any leftover movement on the next one
	while step > 0.0 and bee.path_index < bee.path_points.size():
		var waypoint: Vector2 = bee.path_points[bee.path_index]
		var gap: float = bee.position.distance_to(waypoint)
		if gap <= step:
			bee.position = waypoint
			step -= gap
			bee.path_index += 1
		else:
			bee.position = bee.position.move_toward(waypoint, step)
			step = 0.0
	if bee.path_index >= bee.path_points.size():
		bee.position = bee.position.move_toward(target, step)
	Perf.end("bee_move")
