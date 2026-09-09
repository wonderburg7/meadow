extends RefCounted
## Foraging, plus entering and leaving the hive, split out of bee.gd --
## see BEE_SPLIT_PLAN.md.
##
## Usage: const BeeForaging = preload("res://scripts/bee_foraging.gd")
##        BeeForaging.seek_flower(bee)

const BeeEnums = preload("res://scripts/bee_enums.gd")
const Role = BeeEnums.Role
const State = BeeEnums.State
const BeeMovement = preload("res://scripts/bee_movement.gd")
const BeeStatus = preload("res://scripts/bee_status.gd")
const CrabSpider = preload("res://scripts/crab_spider.gd")

const SCOUT_BOUTS := 3
## How many of a recruited bee's (and her mentor's) trips get logged
## against their pre-match rate -- see wait_at_entrance's match branch and
## _score_trip. One trip is noisy (a single trip's raw rate against a
## multi-trip EMA average is not a fair comparison); a handful smooths
## that out enough to tell a real effect from trip-to-trip variance.
const RECRUIT_FOLLOWUP_TRIPS := 5

## The single choke point for every autonomous state change in this file.
##
## A bee whose `player_driven` flag is set makes no state transition of her
## own: through Challenge 1's manual-forage stages the player issues every
## move, collection and deposit, and a routine that quietly sent her on to
## the next flower or home to the hive would teach the opposite of the
## lesson. Six rounds of that bug (Slices 9a, 10a, 10b, 10f, 10g and 11)
## were each one more unguarded transition, found by playing rather than by
## testing -- so the rule is named once, here, instead of being remembered
## at each site.
##
## Wrap every transition this file makes on the bee's own initiative. A
## transition a `command_*` call asked for is not one of those: it assigns
## `bee.state` directly and marks the line `# player-command`. That
## distinction is the whole point, and tests/source_checks.py enforces it.
static func autonomous_state(bee: Node2D, next: int) -> int:
	return State.IDLING if bee.player_driven else next


static func max_capacity(bee: Node2D) -> float:
	return bee.nectar_stomach_capacity if bee.resource_type == "nectar" else bee.pollen_stomach_capacity


static func collection_rate(bee: Node2D) -> float:
	return bee.nectar_collection_rate if bee.resource_type == "nectar" else bee.pollen_collection_rate


## A short, randomised point near the hive -- shared by orientation
## flight (kept as-is) and scouting (one per bout, scored). See
## DESIGN_BACKLOG.md section 8, "a location a short, slightly randomised
## distance from the hive."
static func _random_point_near_hive(bee: Node2D) -> Vector2:
	var base: Vector2 = bee.world.hive.position if bee.world else bee.position
	var angle: float = randf() * TAU
	var dist: float = randf() * GameConfig.forage_start_radius
	return base + Vector2(cos(angle), sin(angle)) * dist


## A random point within `radius` of `base` -- same shape as
## _random_point_near_hive above, just not anchored to the hive. Used to
## spread a recruited seeker's inherited start point away from her
## mentor's exact one -- see wait_at_entrance and
## GameConfig.recruit_start_point_jitter.
static func _jittered_point(base: Vector2, radius: float) -> Vector2:
	var angle: float = randf() * TAU
	var dist: float = randf() * radius
	return base + Vector2(cos(angle), sin(angle)) * dist


## Tier 0: a new forager's one semi-random flight before her first trip,
## kept as her start point from then on -- see SCOUTING_TOGGLE_PLAN.md.
## Outdoor-spawned bees fly there immediately; indoor-spawned (hatched)
## ones pick it up on their first exit via the normal forage_start_point
## handling in _leave_hive_and_resume.
static func take_orientation_flight(bee: Node2D) -> void:
	var point: Vector2 = _random_point_near_hive(bee)
	point = bee.set_forage_start_point(point, "orientation")
	DiagnosticLog.log_orientation_flight(bee)
	if not bee._is_inside_hive():
		bee.move_target = point
		bee.state = State.MOVE_TO_POINT
	else:
		bee.state = bee._default_state_for_role()


## Only ever an instant decision now -- a flower already in sight
## (forage_perception_radius) is taken immediately, exactly as before
## Slice 5. Anything further than that no longer falls straight through
## to a full-meadow scan: it hands off to State.SEARCHING's spiral
## instead. See search_for_flower below, which re-runs this same bounded
## check every frame while the spiral widens.
static func seek_flower(bee: Node2D) -> void:
	# Heavy rain: a trip costs more in wet-wing flight than the watered
	# down nectar brings back, so there is no point going out. Wait it out
	# at the hive instead.
	if BeeStatus.grounded(bee):
		bee.state = autonomous_state(bee, State.TO_HIVE)
		return

	# A run of thin or rejected flowers means whatever's merely nearby has
	# already proven disappointing several visits running -- go straight
	# to SEARCHING's widening spiral rather than grabbing the next one
	# from this same picked-over patch. See bee.thin_visit_streak.
	if bee.thin_visit_streak >= GameConfig.poor_patch_search_streak:
		bee.thin_visit_streak = 0
		_start_searching(bee)
		return

	var best := _perceive_flower(bee)
	if best != null:
		_commit_to_flower(bee, best)
		return

	# Nothing in sight from right here either -- same widening loop.
	_start_searching(bee)


## A fresh SEARCHING bout from scratch -- shared by seek_flower's "nothing
## in sight" fallback and its poor_patch_search_streak shortcut above.
static func _start_searching(bee: Node2D) -> void:
	# Seeded from the drifting local_search_anchor, falling back to her
	# current position if she has never had a start point at all.
	# search_start_direction is randomised fresh each bout -- a fixed
	# starting direction sent a bee whose anchor sits near an obstacle in
	# that exact direction into the same wall on every single bout from
	# that anchor, found via a 60-day scenario run where a handful of bees
	# repeatedly stalled at identical points. search_angle itself still
	# starts at 0 -- it drives radius growth (see _spiral_point), which
	# should always start from scratch regardless of which direction the
	# spiral opens in.
	bee.search_angle = 0.0
	bee.search_start_direction = randf() * TAU
	bee.search_tried_patch = false
	bee.search_origin = bee.local_search_anchor if bee.local_search_anchor.x != INF else bee.position
	bee.search_waypoint = _spiral_point(bee, bee.search_origin, bee.search_angle)
	bee.state = State.SEARCHING


## SEARCHING's per-frame step. Walks the expanding spiral via the normal
## steering (obstacle avoidance and indoor/outdoor handling come free),
## re-checking for a flower in perception range from wherever she's
## actually got to each frame -- a bee flying past one shouldn't have to
## reach the next waypoint before noticing it. Once the spiral's radius
## outgrows forage_search_radius, give the search up and fall back to the
## old relaxed full-meadow scan once; if that's also empty, go home,
## matching seek_flower's pre-Slice-5 genuinely-empty behaviour exactly.
static func search_for_flower(bee: Node2D, delta: float) -> void:
	if BeeStatus.grounded(bee):
		bee.state = autonomous_state(bee, State.TO_HIVE)
		return

	var best := _perceive_flower(bee)
	if best != null:
		_commit_to_flower(bee, best)
		return

	var turns: float = bee.search_angle / TAU
	var radius: float = GameConfig.forage_perception_radius * (1.0 + turns * GameConfig.forage_search_spiral_step)
	if radius > GameConfig.forage_search_radius:
		# Slice 6 patch memory: one retry from a remembered good spot
		# before giving this bout up for real -- a bee who's fed
		# somewhere before shouldn't have to stumble back onto it by
		# the same odds as anywhere else in the meadow.
		if not bee.search_tried_patch and not bee.known_patches.is_empty():
			bee.search_tried_patch = true
			bee.search_origin = _pick_known_patch(bee)
			bee.search_angle = 0.0
			bee.search_start_direction = randf() * TAU
			bee.search_waypoint = _spiral_point(bee, bee.search_origin, bee.search_angle)
			return
		best = nearest_flower(bee, false, GameConfig.forage_search_radius, true)
		if best != null:
			_commit_to_flower(bee, best)
		else:
			bee.state = autonomous_state(bee, State.TO_HIVE)
		return

	BeeMovement.move_towards(bee, bee.search_waypoint, delta)
	if bee.position.distance_to(bee.search_waypoint) < bee.arrive_distance:
		advance_search_waypoint(bee)


## Moves SEARCHING on to its next spiral waypoint -- reached normally
## (search_for_flower above) or, via the stall watchdog, given up on: a
## waypoint an obstacle has pinned the bee against for STALL_SECONDS is
## exactly as abandoned as a waypoint she flew to, not retried forever.
## Without this, watch_for_stalls's own escape_nearest_obstacle nudge
## (the same for every state) has nothing else to change for SEARCHING --
## TO_FLOWER rejects the flower, MOVE_TO_POINT resets to a default state,
## but SEARCHING would just re-aim at the same unreachable point and stall
## again next cycle, forever.
static func advance_search_waypoint(bee: Node2D) -> void:
	bee.search_angle += GameConfig.forage_search_angle_step
	var origin: Vector2 = bee.search_origin if bee.search_origin.x != INF else bee.position
	bee.search_waypoint = _spiral_point(bee, origin, bee.search_angle)
	# The stall watchdog tracks progress toward current_goal(), which just
	# jumped further away by moving to the next waypoint -- reset its
	# baseline here, the same way a fresh MOVE_TO_POINT target would, so
	# "the goal changed" doesn't read as "stopped progressing".
	bee._reset_stall_watch()


## The bounded, in-sight-only query shared by seek_flower and
## search_for_flower: strict first (respects this bee's own memory of
## what it has drained, and scent marks if that option is on), relaxed
## if that finds nothing, neither ever falling through to a full scan --
## see nearest_flower's allow_full_scan parameter.
static func _perceive_flower(bee: Node2D) -> Node2D:
	var best := nearest_flower(bee, true, GameConfig.forage_perception_radius, false)
	if best == null:
		best = nearest_flower(bee, false, GameConfig.forage_perception_radius, false)
	return best


static func _commit_to_flower(bee: Node2D, flower: Node2D) -> void:
	flower.occupied_by = bee
	bee.current_flower = flower
	bee.state = State.TO_FLOWER
	if GameConfig.floral_constancy_on and bee.is_scouting and bee.scout_species == "":
		bee.scout_species = flower.species_name


## Slice 6 patch memory: append `position` to bee.known_patches (a small
## ring buffer, most-recent last) unless it's too close to something
## already remembered -- working one rich cluster shouldn't fill the
## buffer with near-duplicates of the same spot. Oldest entry evicted
## once the buffer is full.
static func _remember_patch(bee: Node2D, position: Vector2) -> void:
	for known in bee.known_patches:
		if known.distance_to(position) < GameConfig.known_patch_min_spacing:
			return
	bee.known_patches.append(position)
	while bee.known_patches.size() > int(GameConfig.known_patches_max):
		bee.known_patches.pop_front()


## Recency-weighted random pick from bee.known_patches -- the most
## recently remembered patch is the most likely, but not the only,
## choice. Only called with a non-empty array (search_for_flower checks
## first).
static func _pick_known_patch(bee: Node2D) -> Vector2:
	var total := 0.0
	for i in bee.known_patches.size():
		total += float(i + 1)
	var roll := randf() * total
	var acc := 0.0
	for i in bee.known_patches.size():
		acc += float(i + 1)
		if roll <= acc:
			return bee.known_patches[i]
	return bee.known_patches[-1]


## A point on an Archimedean spiral centred on `anchor`: radius grows
## with each full turn (forage_search_spiral_step) of `angle`, which
## always starts at 0 and only ever measures progress through the spiral
## -- the actual compass direction is angle + bee.search_start_direction,
## a fresh random offset per bout (see seek_flower), so radius growth
## stays independent of which way the spiral happens to open.
## Clamped to the meadow field -- an anchor near the field's edge can put
## an unclamped point beyond the world's hard boundary, which is
## unreachable to within arrive_distance and reads as a permanent stall
## rather than a widening search. Found via a 60-day scenario run: an
## unclamped spiral took stall_recoveries from 3 to 500+.
static func _spiral_point(bee: Node2D, anchor: Vector2, angle: float) -> Vector2:
	var turns: float = angle / TAU
	var radius: float = GameConfig.forage_perception_radius * (1.0 + turns * GameConfig.forage_search_spiral_step)
	var direction: float = angle + bee.search_start_direction
	var point: Vector2 = anchor + Vector2(cos(direction), sin(direction)) * radius
	if bee.world != null and is_instance_valid(bee.world):
		var half: Vector2 = bee.world.FLOWER_FIELD_HALF_SIZE
		point.x = clamp(point.x, -half.x, half.x)
		point.y = clamp(point.y, -half.y, half.y)
	return point


## `strict` applies the soft, social avoidance rule (another bee's tarsal
## mark); without it only the hard constraints (occupied, empty) and this
## bee's own memory -- her personal flower_cooldowns and, if predators are
## on, predator_flower_cooldowns -- are checked. Those two are never
## relaxed: they're what she actually learned by being there, not a
## guess, so scarcity is no reason to forget them. `radius` bounds the grid
## query. `allow_full_scan` controls the honest-scan fallback below: true
## (the default, and every call site outside the SEARCHING pipeline) lets
## a bee whose preferred species has nothing in range still find one
## eventually rather than deciding the meadow is empty; seek_flower and
## search_for_flower pass false so a bounded, in-sight-only check stays
## bounded -- widening the search is SEARCHING's job, not a side effect of
## asking nearest_flower a question.
## Searched through main.gd's spatial grid rather than by walking every
## flower in the meadow. This was a scan of 250 nodes per bee per
## decision; with the grid it looks at the handful in the buckets
## nearest the bee and widens only if it finds nothing.
static func nearest_flower(bee: Node2D, strict: bool, radius: float, allow_full_scan: bool = true) -> Node2D:
	var accept := func(f) -> bool:
		if f.occupied_by != null:
			return false
		if f.get_available(bee.resource_type) < GameConfig.min_worthwhile_amount:
			return false
		# Gated on floral_constancy_on too, not just is_scouting -- a pure
		# scout (constancy off) never commits scout_species (see
		# seek_flower), so this branch is never entered during a plain
		# scout and the bout forages whatever's nearest and available,
		# exactly as a non-scouting bee would -- which is what lets the
		# bout's rate reflect the start point alone.
		if bee.is_scouting and GameConfig.floral_constancy_on:
			# Bout not yet committed to a species: anything not already
			# scored this scouting run is fair game. Once committed (see
			# seek_flower), stay on that species for the rest of the bout.
			if bee.scout_species != "":
				if f.species_name != bee.scout_species:
					return false
			elif bee.scout_tried_species.has(f.species_name):
				return false
		elif bee.preferred_species != "" and f.species_name != bee.preferred_species:
			return false
		# Checked outside the `if strict:` block below, same as the
		# predator check just under it -- her own memory of a flower she
		# personally just drained or turned down isn't something scarcity
		# should override either. Without this, a bee with nothing else in
		# range fell straight back onto the exact flower she'd just left
		# (the only "available" thing the relaxed pass could see), and did
		# it again the moment that visit ended -- landing on the same
		# flower forever instead of ever giving SEARCHING a chance to run.
		# See bee.gd's flower_cooldowns field comment.
		if bee.flower_cooldowns.has(f) and Session.sim_time < bee.flower_cooldowns[f]:
			return false
		# Checked outside the `if strict:` block below -- unlike an
		# ordinary rejection, memory of a spider attack isn't something
		# scarcity should override. See bee.gd's predator_flower_cooldowns
		# field comment.
		if GameConfig.predators_on and bee.predator_flower_cooldowns.has(f) \
				and Session.sim_time < bee.predator_flower_cooldowns[f]:
			return false
		if strict:
			# Tarsal secretion: bees leave a scent mark on flowers they
			# land on, and other bees avoid a recently marked flower
			# rather than wasting a trip on one already stripped. Soft,
			# social evidence (it might not even be this bee's own mark) --
			# unlike the two checks above, worth relaxing once nothing else
			# is in range rather than treating it as a hard no.
			if GameConfig.tarsal_markers_on and f.is_marked(bee):
				DiagnosticLog.count_tarsal_rejection()
				return false
		return true

	var grid = flower_grid(bee)
	if grid != null:
		var found: Node2D
		if GameConfig.probabilistic_choice_on:
			# grid.near() returns everything in range (plus a few extras
			# from the touched buckets' corners) rather than stopping at
			# the first match, so there's a real candidate set to weigh --
			# see _weighted_flower_choice.
			found = _weighted_flower_choice(bee, grid.near(bee.position, radius), accept, radius)
		else:
			found = grid.nearest(bee.position, radius, accept)
		if found != null:
			return found

	if not allow_full_scan:
		return null

	# Nothing close enough, or no grid yet. Fall back to the honest scan.
	var candidates: Array = []
	for f in bee.get_tree().get_nodes_in_group("flowers"):
		if is_instance_valid(f) and accept.call(f):
			candidates.append(f)

	if GameConfig.probabilistic_choice_on:
		return _weighted_flower_choice(bee, candidates, func(_f): return true, INF)

	var best: Node2D = null
	var best_dist := INF
	for f in candidates:
		var d := bee.position.distance_to(f.position)
		if d < best_dist:
			best_dist = d
			best = f
	return best


## Slice 6 (probabilistic choice): weighted-random pick among every
## flower in `nodes` that passes `accept` and sits within `radius` --
## score = (1/(1+distance)) * (1 - heading_weight + heading_weight * alignment),
## alignment = 0.5+0.5*cos(angle to candidate) in [0,1] against bee.heading.
## Distance still dominates a candidate directly behind her (alignment
## floors at 0.5, never zeroes a candidate out), so this reshapes the
## odds toward "ahead of me" rather than replacing "nearest" outright.
## Returns null if nothing qualifies.
static func _weighted_flower_choice(bee: Node2D, nodes: Array, accept: Callable, radius: float) -> Node2D:
	var heading: Vector2 = bee.heading if bee.heading != Vector2.ZERO else Vector2.RIGHT
	var heading_weight: float = GameConfig.probabilistic_choice_heading_weight
	var candidates: Array = []
	var weights: Array = []
	var total := 0.0
	for f in nodes:
		if not is_instance_valid(f) or not accept.call(f):
			continue
		var d: float = bee.position.distance_to(f.position)
		if d > radius:
			continue
		var alignment := 1.0
		if d > 0.001:
			alignment = 0.5 + 0.5 * heading.dot((f.position - bee.position) / d)
		var w: float = (1.0 / (1.0 + d)) * (1.0 - heading_weight + heading_weight * alignment)
		# Slice 7 (adaptive constancy): a species this bee has been doing
		# well with recently gets a further boost on top of the
		# distance/heading score above, rather than replacing it -- a
		# confident bee still prefers a close, well-aligned flower of her
		# trusted species over a far one of the same species.
		if GameConfig.adaptive_constancy_on:
			var confidence: float = float(bee.species_confidence.get(f.species_name, 0.0))
			w *= (1.0 + GameConfig.adaptive_constancy_weight * confidence)
		candidates.append(f)
		weights.append(w)
		total += w
	if candidates.is_empty():
		return null
	var roll := randf() * total
	var acc := 0.0
	for i in candidates.size():
		acc += weights[i]
		if roll <= acc:
			return candidates[i]
	return candidates[-1]


static func flower_grid(bee: Node2D):
	if bee.world != null and is_instance_valid(bee.world):
		return bee.world.flower_grid
	return null

## Landing on a flower doesn't commit a bee to feeding from it. A short
## inspection comes first -- long enough to notice things like a fresh
## tarsal mark from another bee, or that it's nearly empty -- and only
## then does the bee decide whether to actually feed or move on. This
## also catches a flower that got marked by someone else mid-flight,
## after this bee had already committed to it.
const INSPECTION_TIME := 1.5
const REJECTED_AVOID_SECONDS := 15.0


static func start_inspecting(bee: Node2D) -> void:
	bee.timer = INSPECTION_TIME
	bee.state = State.INSPECTING


static func inspect(bee: Node2D, delta: float) -> void:
	if bee.current_flower == null or not is_instance_valid(bee.current_flower):
		bee.current_flower = null
		bee.state = autonomous_state(bee, State.TO_HIVE if bee.flower_switch_locked else State.SEEK_FLOWER)
		return
	bee.timer -= delta
	if bee.timer > 0.0:
		return
	# Refuel before working. Every forager drinks nectar, whatever it came
	# for -- a pollen forager still needs the sugar, it just isn't what
	# it's carrying home.
	if needs_a_drink(bee) and bee.current_flower.get_available("nectar") > GameConfig.min_worthwhile_amount:
		bee.state = State.DRINKING
		return

	if worth_feeding(bee, bee.current_flower):
		start_collecting(bee)
	else:
		if GameConfig.alarm_pheromone_on and CrabSpider.is_alarmed(bee.current_flower):
			CrabSpider.flee_alarm(bee, bee.current_flower)
		reject_flower(bee)


static func needs_a_drink(bee: Node2D) -> bool:
	return bee.energy < GameConfig.energy_capacity * GameConfig.forager_drink_threshold


## Drinking straight from the flower, into the bee rather than into its
## load. This is what gives a forager range: it doesn't have to fly home
## to eat, so how far it can work depends on what's flowering out there
## rather than on the distance back to the comb.
static func drink_at_flower(bee: Node2D, delta: float) -> void:
	if bee.current_flower == null or not is_instance_valid(bee.current_flower):
		bee.current_flower = null
		bee.state = autonomous_state(bee, State.TO_HIVE if bee.flower_switch_locked else State.SEEK_FLOWER)
		return

	var room: float = GameConfig.energy_capacity - bee.energy
	var wanted: float = min(GameConfig.nectar_drink_rate * delta, room)
	var drunk: float = bee.current_flower.collect("nectar", wanted)
	# Rain waters the nectar down, so a wet flower gives back less than
	# the same volume would on a dry day.
	bee.energy += drunk * nectar_strength(bee)

	if room <= 0.5 or drunk <= 0.0 or bee.current_flower.get_available("nectar") < GameConfig.min_worthwhile_amount:
		# topped up (or the flower is dry) -- get on with the job
		if worth_feeding(bee, bee.current_flower):
			start_collecting(bee)
		else:
			if GameConfig.alarm_pheromone_on and CrabSpider.is_alarmed(bee.current_flower):
				CrabSpider.flee_alarm(bee, bee.current_flower)
			reject_flower(bee)


## How much a unit of nectar is actually worth right now. Rain dilutes
## what's standing in an open flower.
static func nectar_strength(_bee: Node2D) -> float:
	return lerpf(1.0, 1.0 - GameConfig.rain_nectar_dilution, Session.rain_intensity)


## Rained off. Waiting it out *inside* the hive rather than at the door:
## a bee sheltering out in the meadow couldn't reach the comb to eat, and
## would have walked itself in and straight back out again every few
## seconds as the exit and the rain check argued with each other.
static func shelter(bee: Node2D, _delta: float) -> void:
	if not BeeStatus.grounded(bee):
		bee.state = autonomous_state(bee, State.IN_HIVE_TO_EXIT if bee._is_inside_hive() else State.SEEK_FLOWER)


static func worth_feeding(bee: Node2D, f: Node2D) -> bool:
	if f.get_available(bee.resource_type) < GameConfig.min_worthwhile_amount:
		return false
	if GameConfig.tarsal_markers_on and f.is_marked(bee):
		return false
	if GameConfig.alarm_pheromone_on and CrabSpider.is_alarmed(f):
		return false
	return true


## Doesn't set a full recharge-length cooldown -- this bee didn't drain
## anything, so there's no reason to wait for a refill. A short "don't
## bother rechecking immediately" pause is enough.
static func reject_flower(bee: Node2D) -> void:
	# A turned-down flower is as telling as a thin one -- see
	# start_collecting's own streak update just below.
	bee.thin_visit_streak += 1
	if bee.current_flower and is_instance_valid(bee.current_flower):
		bee.flower_cooldowns[bee.current_flower] = Session.sim_time + REJECTED_AVOID_SECONDS
		# Slice 7 (adaptive constancy): a rejection erodes trust in this
		# species specifically, faster than a good visit builds it (see
		# GameConfig.adaptive_constancy_decay) -- a species that's turned
		# unrewarding should lose favour quickly.
		if GameConfig.adaptive_constancy_on:
			var species: String = bee.current_flower.species_name
			bee.species_confidence[species] = max(0.0, float(bee.species_confidence.get(species, 0.0)) - GameConfig.adaptive_constancy_decay)
		bee.current_flower.release(bee)
	bee.current_flower = null
	bee.state = autonomous_state(bee, State.SEEK_FLOWER)


static func start_collecting(bee: Node2D) -> void:
	DiagnosticLog.count_flower_visit(bee.current_flower)
	# Only known now, on arrival -- accepted (worth_feeding passed) doesn't
	# mean rich, just above min_worthwhile_amount. A flower this picked
	# over still costs a full handling bout for very little, so it counts
	# against the same streak a rejection does; a properly stocked flower
	# clears it, on the theory that a real find means the patch is fine
	# again. See GameConfig.thin_flower_fraction and bee.thin_visit_streak.
	var available: float = bee.current_flower.get_available(bee.resource_type)
	var capacity: float = bee.current_flower.get_capacity(bee.resource_type)
	if capacity > 0.0 and available < capacity * GameConfig.thin_flower_fraction:
		bee.thin_visit_streak += 1
	else:
		bee.thin_visit_streak = 0
	# Slice 5 (local search): the anchor drifts toward wherever she's
	# actually finding flowers, so SEARCHING starts from real recent
	# experience rather than staying pinned to forage_start_point forever.
	# A bee with no forage_start_point yet (anchor still INF) has nothing
	# to drift from, so the first commit just plants the anchor there.
	if bee.local_search_anchor.x == INF:
		bee.local_search_anchor = bee.current_flower.position
	else:
		bee.local_search_anchor = bee.local_search_anchor.lerp(bee.current_flower.position, GameConfig.local_search_drift_rate)
	_remember_patch(bee, bee.current_flower.position)
	# Slice 1 trip-timing instrumentation -- gated the same as
	# trip_start_time/trip_load_amount just below, since those are what
	# _score_trip needs to actually be running for this to mean anything.
	if GameConfig.scouting_on or GameConfig.auto_recruitment_on:
		if bee.trip_first_flower_time < 0.0:
			bee.trip_first_flower_time = Session.sim_time
		bee.trip_flowers_visited += 1
	bee.flower_visit_started_at = Session.sim_time
	if GameConfig.tarsal_markers_on:
		DiagnosticLog.count_tarsal_mark()
	# Checked before this bee's own mark overwrites whatever was here --
	# tarsal marking's marked_by/marked_at update unconditionally on every
	# visit regardless of tarsal_markers_on (only the *avoidance* is gated
	# by that toggle), so this reads the true "who was just here" even
	# with marking off. Direct evidence for/against the hypothesis that a
	# recruited bee, sharing her mentor's exact start point, tends to land
	# on flowers her mentor only just finished draining.
	if bee.recruit_followup_remaining > 0 and bee.recruit_partner != null \
			and is_instance_valid(bee.recruit_partner) and bee.current_flower.marked_by == bee.recruit_partner:
		DiagnosticLog.count_recruit_partner_overlap()
	bee.current_flower.leave_marker(bee)
	# Crab spiders (see CRAB_SPIDER_PLAN.md section 4) -- risk begins the
	# instant a bee actually starts feeding, not on landing/inspecting.
	# resolve_attack already moved the bee to SEEK_FLOWER (escaped) or
	# freed her entirely (killed) when it returns false, so the caller
	# must not fall through into COLLECTING.
	if GameConfig.predators_on and bee.current_flower.has_crab_spider:
		if not CrabSpider.resolve_attack(bee):
			return
	# `timer` now counts down the handling phase only -- finding the
	# nectary after landing. Gathering itself happens gradually, in
	# _collect(), so the flower's readout ticks down while you watch.
	# Scaled per species -- a fiddly flower takes longer to work over than
	# a simple open one (Foraging ecology plan, Slice 3) -- and, under
	# Slice 7's handling experience, further scaled by how practised this
	# particular bee is with this particular species.
	var experience_scale := 1.0
	if GameConfig.handling_experience_on:
		experience_scale = _handling_experience_scale(bee, bee.current_flower.species_name)
	bee.timer = bee.flower_handling_time * bee.current_flower.handling_time_scale * experience_scale
	bee.state = State.COLLECTING


## Slice 7 (handling experience): how much faster this bee handles
## `species` compared to a first-timer, as a multiplier on handling time
## (1.0 = no speed-up yet, GameConfig.handling_experience_floor = fully
## practised). Diminishing returns -- lerps toward the floor as visits
## approach handling_experience_visits_to_floor rather than a hard
## cutoff, so the first few visits matter more than the tenth.
static func _handling_experience_scale(bee: Node2D, species: String) -> float:
	var visits: float = float(bee.species_experience.get(species, 0))
	var t: float = clampf(visits / GameConfig.handling_experience_visits_to_floor, 0.0, 1.0)
	return lerpf(1.0, GameConfig.handling_experience_floor, t)


## Draws resource out of the flower a little each frame. Previously the
## whole load was removed in one lump when the timer expired, which made
## the flower's numbers look frozen until the bee left.
static func collect(bee: Node2D, delta: float) -> void:
	if bee.current_flower == null or not is_instance_valid(bee.current_flower):
		bee.current_flower = null
		bee.state = autonomous_state(bee, State.TO_HIVE if bee.flower_switch_locked else State.SEEK_FLOWER)
		return

	if bee.timer > 0.0:
		bee.timer -= delta
		return   # still handling the flower, nothing gathered yet

	# A bee carries one resource at a time. If it still has a part-load of
	# something else after a focus change, it delivers that first rather
	# than mixing the two in its stomach.
	if bee.current_load > 0.0 and bee.current_load_type != "" and bee.current_load_type != bee.resource_type:
		finish_collecting(bee)
		# The journey home is a transition of the bee's own, so a focus
		# change cannot fly a player-driven queen home before the player has
		# issued the return command.
		bee.state = autonomous_state(bee, State.TO_HIVE)
		return

	var space_left: float = max_capacity(bee) - bee.current_load
	if space_left <= 0.0:
		finish_collecting(bee)
		return

	# A drained flower still trickles back a little every frame as it
	# recharges. Waiting for the take to hit exactly zero therefore never
	# happened -- the bee sat there sipping the trickle forever. Instead
	# it leaves as soon as there isn't a worthwhile amount left.
	if bee.current_flower.get_available(bee.resource_type) < GameConfig.min_worthwhile_amount:
		finish_collecting(bee)
		return

	var wanted: float = min(collection_rate(bee) * delta, space_left)
	var taken: float = bee.current_flower.collect(bee.resource_type, wanted)
	# Nectar standing in an open flower is watered down by rain, so a wet
	# day's foraging brings home less than the same volume would dry.
	if bee.resource_type == "nectar":
		taken *= nectar_strength(bee)
	bee.current_load += taken
	if taken > 0.0:
		bee.current_load_type = bee.resource_type
		bee.hive.record_collection(bee.resource_type, taken)

	if bee.current_load >= max_capacity(bee):
		finish_collecting(bee)


static func finish_collecting(bee: Node2D) -> void:
	var handling_seconds := -1.0
	if bee.flower_visit_started_at >= 0.0:
		handling_seconds = Session.sim_time - bee.flower_visit_started_at
	if (GameConfig.scouting_on or GameConfig.auto_recruitment_on) and handling_seconds >= 0.0:
		bee.trip_handling_seconds += handling_seconds
	if handling_seconds >= 0.0:
		bee.flower_visit_started_at = -1.0
	if bee.current_flower and is_instance_valid(bee.current_flower):
		# Slice 10f: Challenge 1's 1.8/1.9 goals need a real per-stage count of
		# completed collections, not flower_cooldowns.size() (also grows on a
		# rejection, on the 1.7 tour, and shrinks on a focus change).
		if is_instance_valid(bee.world) and bee.world.challenge_runner != null and bee.world.challenge_runner.active and bee == bee.world.queen:
			bee.world.challenge_runner._c1_queen_collections += 1
		var species: String = bee.current_flower.species_name
		var prior_experience := int(bee.species_experience.get(species, 0))
		if handling_seconds >= 0.0:
			DiagnosticLog.record_handling_visit(species, prior_experience, handling_seconds)
		# Slice 7: a completed handling bout is what "experience"/
		# "confidence" mean here -- she got far enough into working this
		# flower to be timed out or run it dry, as opposed to reject_flower
		# below, which is a species she looked at and turned down.
		if GameConfig.handling_experience_on:
			bee.species_experience[species] = int(bee.species_experience.get(species, 0)) + 1
		if GameConfig.adaptive_constancy_on:
			bee.species_confidence[species] = minf(1.0, float(bee.species_confidence.get(species, 0.0)) + GameConfig.adaptive_constancy_gain)
		# stay away until it's had time to fully recharge
		bee.flower_cooldowns[bee.current_flower] = Session.sim_time + bee.current_flower.seconds_until_full(bee.resource_type)
		bee.current_flower.release(bee)
	bee.current_flower = null
	# Both arms are the bee's own decision, so a player-driven queen stops at
	# the flower whatever the crop holds and waits for command_return_only().
	# A locked forager may still take her load home, full or not -- what the
	# lock forbids is going to find a *different* flower, so a full crop or
	# a locked flower both send her to the hive.
	bee.state = autonomous_state(bee, State.TO_HIVE if (bee.current_load >= max_capacity(bee) or bee.flower_switch_locked) else State.SEEK_FLOWER)



## Foragers now physically walk into the hive view to deposit, rather
## than vanishing at the meadow marker. main.gd owns the reparenting
## because it owns both world roots and the entrance geometry.
static func enter_hive(bee: Node2D) -> void:
	if bee.world == null:
		# no world wired up (shouldn't happen) -- fall back to the old
		# behaviour so a bee never gets stuck at the door
		deposit_everything_remotely(bee)
		return
	bee.world.move_bee_into_hive(bee)
	if bee.emergency_return_reason != "":
		DiagnosticLog.log_forager_return(bee, "arrived", 0.0)
		bee.emergency_return_reason = ""
	bee.target_cell = null
	if bee.resume_pending_zone_command():
		return
	# A bee that came home because its job is now indoors (see set_role)
	# starts that job at the door rather than running the forager's
	# deposit-and-leave sequence. Either branch is the bee choosing for
	# herself, so a player-driven queen waits at the door instead, and the
	# player picks the receiving cell.
	bee.state = autonomous_state(bee, bee._default_state_for_role() if BeeStatus.works_indoors(bee) else State.IN_HIVE_TO_CELL)


## Walks to one of the six wall positions on `cell`, claiming it first,
## so no more than six bees ever work the same cell at once and none of
## them stand on top of each other. Returns:
##    1  arrived and in position
##    0  still on the way
##   -1  every wall is taken -- the caller should look for another cell
static func approach_cell(bee: Node2D, cell: Node2D, delta: float) -> int:
	if cell == null or not is_instance_valid(cell):
		return -1
	if bee.slot_cell != cell:
		release_cell_slot(bee)
		var index: int = cell.claim_slot(bee)
		if index < 0:
			return -1
		bee.cell_slot = index
		bee.slot_cell = cell
	var stand_point: Vector2 = cell.slot_position(bee.cell_slot)
	BeeMovement.move_towards(bee, stand_point, delta)
	return 1 if bee.position.distance_to(stand_point) < 6.0 else 0


static func release_cell_slot(bee: Node2D) -> void:
	if bee.slot_cell != null and is_instance_valid(bee.slot_cell):
		bee.slot_cell.release_slot(bee)
	bee.slot_cell = null
	bee.cell_slot = -1


static func go_to_deposit_cell(bee: Node2D, delta: float) -> void:
	if bee.current_load <= 0.0:
		# Nothing to deliver. Eating is handled separately now -- the
		# hunger check in _process will already have sent this bee to a
		# food cell if it needed one, and it runs whether the trip home
		# was a productive one or not.
		#
		# Still score the trip itself, though. This used to fall straight
		# through to IN_HIVE_TO_EXIT without ever touching _score_trip, so
		# a played-out patch (drained by weather, normal recharge timing,
		# or a pile of recruited seekers all working it at once) was
		# invisible to avg_collection_rate -- an empty-handed forager kept
		# reading exactly as good as her last real delivery, so she kept
		# re-qualifying as a mentor and re-advertising the same dead patch
		# to every new seeker. Confirmed against real session logs: every
		# mentor matched more than once had a bit-identical
		# avg_collection_rate across every match, sometimes 100+ seconds
		# apart -- proof no scored trip had happened in between, not just
		# a stable patch. See the recruitment-competition investigation,
		# NEXTSTEPS.md.
		if GameConfig.scouting_on or GameConfig.auto_recruitment_on:
			bee.trip_load_amount = 0.0
			_score_trip(bee)
			if bee._apply_pending_role():
				return
		bee.state = autonomous_state(bee, State.IN_HIVE_TO_EXIT)
		return

	if bee.target_cell == null or not is_instance_valid(bee.target_cell) or bee.target_cell.space_for(bee.current_load_type) <= 0.0:
		# A full comb cannot receive this trip yet.  As with a miner that
		# remembers no work, avoid repeating the same global search on every
		# think tick until a cell mutation makes a new answer possible.
		if bee.deposit_blocked_epoch == bee.hive.index_epoch:
			return
		bee.target_cell = bee.hive.find_cell_for(bee.current_load_type)
		if bee.target_cell == null:
			if bee.hive.cells.is_empty():
				# Nothing built yet at all -- distinct from an established
				# colony's comb being genuinely full. A brand new colony
				# whose first forager comes home before the first cell is
				# finished shouldn't lose her whole trip for it; just wait
				# here (still carrying it) and recheck next frame, so a
				# cell finishing mid-wait picks her straight back up.
				return
			# Challenge 1 only: by the pollen stage both built cells hold
			# nectar, so a nectar trip genuinely has nowhere to go until the
			# player designates a cell for pollen. Outside Challenge 1 this
			# guard does not fire -- a full comb must still keep the load,
			# which is exactly what the general case below does.
			if is_instance_valid(bee.world) and bee.world.challenge_runner != null and bee.world.challenge_runner.discards_overflow(bee):
				bee.current_load = 0.0
				bee.current_load_type = ""
				bee.state = autonomous_state(bee, State.IN_HIVE_TO_EXIT)
				return
			# Keep the load until a cell changes.  Discarding it here made a
			# full comb silently erase every later foraging trip.
			bee.deposit_blocked_epoch = bee.hive.index_epoch
			return

	var approach := approach_cell(bee, bee.target_cell, delta)
	if approach < 0:
		# all six walls busy -- try somewhere else rather than queueing
		bee.target_cell = bee.hive.find_cell_for(bee.current_load_type, bee.target_cell)
		return
	if approach == 1:
		bee.timer = bee.deposit_time
		bee.state = State.DEPOSITING


static func finish_depositing(bee: Node2D) -> void:
	# Captured once, before the first cell takes its share, so a trip
	# split across several cells still scores against the whole trip.
	# Needed by either scouting or auto-recruitment, not just the latter.
	if (GameConfig.scouting_on or GameConfig.auto_recruitment_on) and bee.trip_load_amount < 0.0:
		bee.trip_load_amount = bee.current_load
	var placed := 0.0
	if bee.target_cell and is_instance_valid(bee.target_cell):
		placed = bee.target_cell.add_resource(bee.current_load_type, bee.current_load)
		bee.current_load -= placed
		bee.hive.announce()
	DiagnosticLog.count_forager_delivery(placed)
	release_cell_slot(bee)
	bee.target_cell = null

	# No refuelling here any more. A forager used to eat its fill the
	# instant it unloaded, taking most of the delivery straight back out
	# of the very cell it had just filled -- which is why a bee carrying
	# 50 nectar appeared to deposit a fraction of it. If it is hungry the
	# check in _process sends it to eat as a separate, visible trip.

	if bee.current_load > 0.0:
		bee.state = State.IN_HIVE_TO_CELL   # still carrying -- find another cell
		return

	bee.current_load_type = ""
	if GameConfig.scouting_on or GameConfig.auto_recruitment_on:
		_score_trip(bee)
	# The load is delivered, so a queued role change takes effect now --
	# this is the "finish depositing first" case.
	if bee._apply_pending_role():
		return
	# Leaving the hive after a delivery is the forager routine's own move, so
	# for a player-driven queen it is the player's next command to give.
	bee.state = autonomous_state(bee, State.IN_HIVE_TO_EXIT)


## The trip just finished (whether or not this bee is scouting): work
## out how much it collected per second and fold that into its running
## average (used by the entrance recruitment check). A scouting bee
## also scores this bout of its three against the best one seen so far.
static func _score_trip(bee: Node2D) -> void:
	var amount: float = max(bee.trip_load_amount, 0.0)
	var elapsed: float = max(Session.sim_time - bee.trip_start_time, 0.1)
	var rate: float = amount / elapsed

	# Slice 1 (FORAGING_ECOLOGY_PLAN.md): feed the same trip this rate was
	# just computed from into foraging_stats.gd, before scout_species is
	# cleared further down so a still-scouting bee's in-progress species
	# is captured too. bee.world is main -- see bee.gd's own field
	# comment -- and can be null very early (a bee scored before main has
	# finished wiring itself up shouldn't happen, but this matches every
	# other bee.world caller's null guard rather than assuming).
	if bee.world != null and (GameConfig.scouting_on or GameConfig.auto_recruitment_on):
		var search_flight: float = (bee.trip_first_flower_time - bee.trip_start_time) if bee.trip_first_flower_time >= 0.0 else 0.0
		var species: String = bee.preferred_species if bee.preferred_species != "" else bee.scout_species
		bee.world.foraging_stats.record_trip(
			bee.resource_type, species, search_flight, bee.trip_handling_seconds,
			elapsed, bee.trip_flowers_visited, amount
		)
	if bee.trips_scored < GameConfig.recruit_grace_trips:
		# Plain mean, not the EMA below, while still inside the grace
		# window -- an EMA started on trip one is ~49% decided by that
		# first trip alone by the time trips_scored reaches 3, so a
		# single lucky or unlucky trip was effectively answering "has
		# this forager found a good patch" on its own. An equal-weighted
		# average of the same handful of trips is a fairer read of
		# whether the patch itself is actually good before recruitment
		# starts trusting the number. See the recruitment-competition
		# investigation, NEXTSTEPS.md.
		bee.grace_rate_sum += rate
		bee.avg_collection_rate = bee.grace_rate_sum / (bee.trips_scored + 1)
	else:
		bee.avg_collection_rate = lerpf(bee.avg_collection_rate, rate, bee.RATE_EMA_WEIGHT)
	bee.trips_scored += 1
	bee.trip_load_amount = -1.0

	if not bee.settled_rate_logged and bee.trips_scored >= GameConfig.recruit_grace_trips:
		bee.settled_rate_logged = true
		DiagnosticLog.log_forager_settled(bee)

	if bee.recruit_followup_remaining > 0:
		var trip_index: int = RECRUIT_FOLLOWUP_TRIPS - bee.recruit_followup_remaining + 1
		DiagnosticLog.log_recruitment_followup(bee, trip_index, rate)
		bee.recruit_followup_remaining -= 1
		if bee.recruit_followup_remaining <= 0:
			bee.recruit_partner = null
			bee.recruit_role = ""

	# Slice 9 (proximity recruitment): eligibility is decided here, the
	# instant a trip is scored, not just once at the door -- see
	# _update_dance_eligibility.
	_update_dance_eligibility(bee)

	if not bee.is_scouting:
		return
	if rate > bee.scout_best_rate:
		bee.scout_best_rate = rate
		bee.scout_best_species = bee.scout_species
		bee.scout_best_start_point = bee.scout_current_start_point
	if GameConfig.floral_constancy_on:
		bee.scout_tried_species.append(bee.scout_species)
	bee.scout_bout += 1
	bee.scout_species = ""
	if bee.scout_bout >= SCOUT_BOUTS:
		# All bouts tried -- settle on whichever start point (and, under
		# Floral constancy, species) paid off best. If every bout came
		# back empty (rate never beat the -1 sentinel), leave both unset
		# rather than pinning something that never actually delivered.
		bee.is_scouting = false
		if bee.scout_best_rate > 0.0:
			if bee.scout_best_start_point.x != INF:
				bee.set_forage_start_point(bee.scout_best_start_point, "scouting_settled")
				bee.known_patches.clear()
			if GameConfig.floral_constancy_on:
				bee.preferred_species = bee.scout_best_species
		DiagnosticLog.log_scouting_settled(bee)


static func go_to_exit(bee: Node2D, delta: float) -> void:
	# No point walking out into weather that costs more to fly in than the
	# trip would bring back. Wait inside, where the food is.
	if bee.role == Role.FORAGER and BeeStatus.grounded(bee):
		bee.state = State.SHELTERING
		return

	var exit_point: Vector2 = bee.world.hive_entrance_inside() if bee.world else bee.position
	BeeMovement.move_towards(bee, exit_point, delta)
	if bee.position.distance_to(exit_point) < 8.0:
		# Auto-recruitment: a still-scouting bee, or one whose own rate has
		# drifted outside the recruitment band, waits here rather than
		# walking straight back out -- see wait_at_entrance. This is the
		# one place bee.is_scouting still causes an entrance visit, and
		# it's only reachable at all when auto_recruitment_on is on -- with
		# it off, all of scouting's bouts run uninterrupted every time. The
		# rate check itself is gated on trips_scored -- see its declaration
		# on bee.gd -- so a bee with no real trips behind it yet (brand
		# new, or auto-recruitment just switched on for an established bee)
		# goes straight back out rather than judging itself on a number
		# that isn't real yet.
		if GameConfig.auto_recruitment_on and bee.role == Role.FORAGER:
			var past_grace: bool = bee.trips_scored >= GameConfig.recruit_grace_trips
			var lower: float = GameConfig.recruit_lower_threshold_nectar if bee.resource_type == "nectar" else GameConfig.recruit_lower_threshold_pollen
			var upper: float = GameConfig.recruit_upper_threshold_nectar if bee.resource_type == "nectar" else GameConfig.recruit_upper_threshold_pollen
			if bee.is_scouting or (past_grace and bee.avg_collection_rate < lower):
				bee.timer = GameConfig.recruit_wait_seconds
				bee.entrance_wait_target = _entrance_wait_spot(bee, -1)
				bee.state = State.AT_ENTRANCE_SEEKING
				return
			elif past_grace and bee.avg_collection_rate > upper and not CrabSpider.recruitment_suppressed(bee):
				bee.hive.add_entrance_mentor(bee)
				bee.timer = GameConfig.recruit_wait_seconds
				bee.entrance_wait_target = _entrance_wait_spot(bee, 1)
				bee.state = State.AT_ENTRANCE_MENTORING
				return
		_leave_hive_and_resume(bee)

## `side` is -1 for a seeker (left of the empty middle tile) or 1 for a
## mentor (right), so the two waiting groups read as distinct queues
## rather than one crowd blocking the doorway. A little jitter on top
## keeps several bees on the same side from standing exactly on top of
## each other.
static func _entrance_wait_spot(bee: Node2D, side: int) -> Vector2:
	if bee.world == null:
		return bee.position
	var jitter := Vector2(randf_range(-6.0, 6.0), randf_range(-5.0, 5.0))
	return bee.world.entrance_wait_point(side) + jitter


## Every exit from the hive door funnels through here once the bee has
## actually decided to go, whether that's a plain exit, a seeker who
## just got matched, or a wait that timed out -- so "what does a
## forager do next" (start point, scout point, or the plain default)
## is decided in exactly one place.
static func _leave_hive_and_resume(bee: Node2D) -> void:
	bee.entrance_wait_target = Vector2(INF, INF)
	if bee.world:
		bee.world.move_bee_out_of_hive(bee)
	if bee.resume_pending_zone_command():
		return
	if (GameConfig.scouting_on or GameConfig.auto_recruitment_on) and bee.role == Role.FORAGER:
		bee.trip_start_time = Session.sim_time
		bee.trip_first_flower_time = -1.0
		bee.trip_handling_seconds = 0.0
		bee.trip_flowers_visited = 0
		if bee.is_scouting:
			_send_to_scout_point(bee)
			return
	# A forager with a start point set heads there first, every trip,
	# rather than just once -- that's what keeps it working the same
	# patch instead of drifting back to whatever's nearest the door.
	if bee.role == Role.FORAGER and bee.forage_start_point.x != INF:
		bee.move_target = bee.forage_start_point
		bee.state = State.MOVE_TO_POINT
	else:
		bee.state = bee._default_state_for_role()


## Sends a scouting bee to a fresh random start point for its next bout,
## and records it so _score_trip can compare this bout's rate against the
## best one seen so far and keep the winning point.
static func _send_to_scout_point(bee: Node2D) -> void:
	var point: Vector2 = _random_point_near_hive(bee)
	var requested := point
	var resolved := BeeMovement.resolve_flight_start(bee, point)
	point = resolved.point
	DiagnosticLog.log_flight_start_resolved(bee, "scouting", requested, resolved)
	bee.move_target = point
	bee.scout_current_start_point = point
	bee.state = State.MOVE_TO_POINT


## Kicks off a brand-new forager's scouting phase (see setup() in
## bee.gd, the only caller). An outdoor-spawned bee is already out in
## the meadow, so it heads to its first bout immediately; an
## indoor-spawned (hatched) one walks out through the door as normal
## and picks up its first bout from _leave_hive_and_resume instead.
static func start_scouting(bee: Node2D) -> void:
	bee.is_scouting = true
	bee.scout_bout = 0
	bee.scout_species = ""
	bee.scout_tried_species = []
	bee.scout_best_species = ""
	bee.scout_best_rate = -1.0
	bee.scout_current_start_point = Vector2(INF, INF)
	bee.scout_best_start_point = Vector2(INF, INF)
	bee.trip_load_amount = -1.0
	bee.trip_first_flower_time = -1.0
	bee.trip_handling_seconds = 0.0
	bee.trip_flowers_visited = 0
	if not bee._is_inside_hive():
		bee.trip_start_time = Session.sim_time
		_send_to_scout_point(bee)


## A forager waiting at the entrance, either hoping to be told a
## better patch (seeker: scouting, or its own rate has fallen below
## the lower threshold) or offering to tell one (mentor: its rate is
## above the upper threshold). See DESIGN_BACKLOG.md section 7.1.
static func wait_at_entrance(bee: Node2D, delta: float) -> void:
	# Walk clear of the doorway itself while waiting -- see
	# world_building.gd::entrance_wait_point. Harmless if the spot turns
	# out to be unreachable: move_towards just leaves the bee where it is,
	# right by the door, same as before this existed.
	if bee.entrance_wait_target.x != INF:
		BeeMovement.move_towards(bee, bee.entrance_wait_target, delta)

	if bee.state == State.AT_ENTRANCE_MENTORING:
		bee.timer -= delta
		if bee.timer <= 0.0:
			bee.hive.remove_entrance_mentor(bee)
			_leave_hive_and_resume(bee)
		return

	# Seeker. Any same-resource mentor currently waiting is fair game --
	# being learned from doesn't use a mentor up, so there's no claiming
	# involved. A mentor that died mid-wait is pruned here rather than
	# left blocking the front of the list forever. A mismatched-resource
	# mentor is left in place for a seeker of its own type instead -- a
	# nectar forager has no use for a pollen patch's start point, and
	# shouldn't block a pollen mentor from ever being found by a pollen
	# seeker either.
	var i := 0
	while i < bee.hive.entrance_mentors.size():
		var mentor: Node2D = bee.hive.entrance_mentors[i]
		if not is_instance_valid(mentor):
			bee.hive.entrance_mentors.remove_at(i)
			continue
		if mentor.resource_type != bee.resource_type:
			i += 1
			continue
		# One match per mentor per waiting cycle -- see the
		# recruitment-competition investigation, NEXTSTEPS.md. Nothing used
		# to remove a mentor from entrance_mentors except her own timeout,
		# so every seeker who checked the list during her wait matched the
		# same mentor: real session logs showed one mentor picking up 3-4
		# seekers within a couple of seconds, all funnelled onto the same
		# ~900px catchment (recruit_start_point_jitter is only 80px). The
		# mentor's own next trip then read ~4% of her pre-match rate on
		# average, not just "diminished" -- her patch was actually
		# oversubscribed. She keeps waiting out her own timer below and
		# leaves normally; she just can't be handed out again.
		bee.hive.remove_entrance_mentor(mentor)
		# Nudged, not identical -- see recruit_start_point_jitter's field
		# comment in game_config.gd. Same general proven area, different
		# corner of it, so the seeker isn't funnelled onto the exact same
		# handful of flowers the mentor is still working.
		bee.set_forage_start_point(_jittered_point(mentor.forage_start_point, GameConfig.recruit_start_point_jitter), "recruitment")
		if GameConfig.floral_constancy_on:
			bee.preferred_species = mentor.preferred_species
		# Captured here, before the new patch has had a single trip on it,
		# so _score_trip can log a clean before/after comparison over each
		# of the next few trips -- for both bees, not just the seeker: the
		# mentor is still working the same patch she just handed the start
		# point out for, so if the seeker following her onto it costs the
		# mentor anything, this is what shows it.
		bee.recruit_partner = mentor
		bee.recruit_role = "seeker"
		bee.recruit_rate_before = bee.avg_collection_rate
		bee.recruit_followup_remaining = RECRUIT_FOLLOWUP_TRIPS
		mentor.recruit_partner = bee
		mentor.recruit_role = "mentor"
		mentor.recruit_rate_before = mentor.avg_collection_rate
		mentor.recruit_followup_remaining = RECRUIT_FOLLOWUP_TRIPS
		DiagnosticLog.log_recruitment_match(bee, mentor)
		# The whole point of scouting is finding a good patch -- being
		# handed one already-proven is strictly better, so there's no
		# reason to keep running the remaining bouts.
		bee.is_scouting = false
		_leave_hive_and_resume(bee)
		return

	bee.timer -= delta
	if bee.timer <= 0.0:
		# Nobody came. Rather than repeat the same low-performing pattern,
		# drop it and pick a fresh spot -- scouting bees just re-enter
		# scouting; an established forager with a stale preference tries
		# a new one the same way a fresh bee would.
		if bee.is_scouting:
			# _leave_hive_and_resume, not _send_to_scout_point directly --
			# this bee is still parented under hive_root (she walked in to
			# wait at the entrance and never left), and only
			# _leave_hive_and_resume reparents her out before handing her a
			# fresh meadow-space scout point. Calling _send_to_scout_point
			# on its own here set State.MOVE_TO_POINT with a target the
			# hive-interior pathfinder can't reach, and left her
			# permanently invisible to the stall watchdog too, since its
			# very first check is bee._is_inside_hive() -- a seeker who
			# timed out with no mentor waiting (the common case early in a
			# run, before anyone's traded enough trips to qualify as one)
			# got stuck for good the moment this fired. Found via
			# foraging_features_on_test.json: scouting plus auto-recruitment
			# together made this the dominant failure mode, freezing most
			# of the colony's foraging within the first week.
			_leave_hive_and_resume(bee)
		else:
			bee.preferred_species = ""
			bee.forage_start_point = Vector2(INF, INF)
			bee.local_search_anchor = Vector2(INF, INF)
			bee.known_patches.clear()
			_leave_hive_and_resume(bee)


## Slice 9 (proximity recruitment, GameConfig.proximity_recruitment_on):
## same eligibility test auto-recruitment's go_to_exit already uses (past
## the grace window, above/below the resource-specific threshold, not
## already-suppressed), just evaluated continuously from the moment a
## trip is scored rather than once at the door -- see _score_trip above.
## A bee never sits in both lists; scouting always reads as seeker-side,
## same as go_to_exit's own ordering (checked before the mentor branch).
static func _update_dance_eligibility(bee: Node2D) -> void:
	if not GameConfig.proximity_recruitment_on or bee.role != Role.FORAGER:
		return
	bee.hive.remove_dance_eligible_mentor(bee)
	bee.hive.remove_dance_eligible_seeker(bee)
	var past_grace: bool = bee.trips_scored >= GameConfig.recruit_grace_trips
	if not past_grace and not bee.is_scouting:
		return
	var lower: float = GameConfig.recruit_lower_threshold_nectar if bee.resource_type == "nectar" else GameConfig.recruit_lower_threshold_pollen
	var upper: float = GameConfig.recruit_upper_threshold_nectar if bee.resource_type == "nectar" else GameConfig.recruit_upper_threshold_pollen
	if bee.is_scouting or (past_grace and bee.avg_collection_rate < lower):
		bee.hive.add_dance_eligible_seeker(bee)
	elif past_grace and bee.avg_collection_rate > upper and not CrabSpider.recruitment_suppressed(bee):
		bee.hive.add_dance_eligible_mentor(bee)

## Called once a frame for every indoor forager while proximity
## recruitment is on (see bee.gd's per-frame dispatch) -- cheap by
## construction, same reasoning as entrance_mentors before it: this is a
## bounded scan against two small lists, not every bee in the hive.
## Scanned mentor-side only (each dance-eligible mentor checks the seeker
## list), not both directions, so a matching pair is only ever found
## once per frame rather than twice. Dead seekers are pruned as they're
## found, same while-loop-with-remove_at shape wait_at_entrance uses for
## entrance_mentors above.
static func check_dance_proximity(bee: Node2D, _delta: float) -> void:
	if not bee.hive.dance_eligible_mentors.has(bee):
		return
	var seekers: Array = bee.hive.dance_eligible_seekers
	var i := 0
	while i < seekers.size():
		var seeker: Node2D = seekers[i]
		if not is_instance_valid(seeker):
			seekers.remove_at(i)
			continue
		if seeker.resource_type == bee.resource_type and seeker.state != State.DANCING \
				and bee.position.distance_to(seeker.position) <= GameConfig.recruit_dance_radius:
			_start_dance(bee, seeker)
			return
		i += 1

## Both bees enter State.DANCING -- neither one waits or hopes; this
## fires the instant proximity is detected. Their pre-dance state and
## its in-progress timer are stashed so `dance` below can resume exactly
## where each was (this matters for DEPOSITING in particular, whose
## timer is mid-countdown and would otherwise be clobbered by the dance's
## own timer). Removed from both dance-eligible lists immediately -- a
## bee mid-dance is neither offering nor looking any more, and this is
## also what enforces "one recruit per mentor per hive visit" (see
## has_danced_this_visit, set in _complete_dance below).
static func _start_dance(mentor: Node2D, seeker: Node2D) -> void:
	mentor.hive.remove_dance_eligible_mentor(mentor)
	seeker.hive.remove_dance_eligible_seeker(seeker)
	mentor.dance_partner = seeker
	mentor.dance_role = "mentor"
	mentor.pre_dance_state = mentor.state
	mentor.pre_dance_timer = mentor.timer
	seeker.dance_partner = mentor
	seeker.dance_role = "seeker"
	seeker.pre_dance_state = seeker.state
	seeker.pre_dance_timer = seeker.timer
	mentor.timer = GameConfig.recruit_dance_seconds
	seeker.timer = GameConfig.recruit_dance_seconds
	mentor.state = State.DANCING
	seeker.state = State.DANCING

## State.DANCING's own per-frame handler (see bee.gd's dispatch). Only
## the mentor side actually performs the info transfer, once, when her
## own timer completes -- both bees' timers were set to the same value in
## _start_dance, but only one of them should ever run _complete_dance.
static func dance(bee: Node2D, delta: float) -> void:
	bee.timer -= delta
	if bee.timer > 0.0:
		return
	if bee.dance_role == "mentor" and bee.dance_partner != null and is_instance_valid(bee.dance_partner):
		_complete_dance(bee, bee.dance_partner)
	_end_dance(bee)

## Resumes whatever this bee was doing before the dance interrupted her
## -- the whole point of "no waiting states": she was already walking to
## a cell, depositing, or walking back out, and picks that straight back
## up rather than being sent anywhere new.
static func _end_dance(bee: Node2D) -> void:
	var resume_state: int = bee.pre_dance_state
	var resume_timer: float = bee.pre_dance_timer
	bee.dance_partner = null
	bee.dance_role = ""
	bee.pre_dance_state = -1
	bee.pre_dance_timer = 0.0
	if resume_state != -1:
		bee.state = resume_state
		bee.timer = resume_timer
	else:
		bee.state = bee._default_state_for_role()

## The info transfer itself -- see the interpretive call in
## FORAGING_ECOLOGY_PLAN.md Slice 9: angle and distance are decomposed
## relative to hive_entrance_inside(), not the seeker's own position, so
## the encoding matches how mentor.forage_start_point is itself set
## (hive-relative, via orientation flight/scouting) regardless of where
## in the hive the dance actually happened. Sets the same handful of
## fields wait_at_entrance's match branch already does, just fed from
## the decoded point instead of the jittered one -- see that function's
## own comments for why each field is set.
static func _complete_dance(mentor: Node2D, seeker: Node2D) -> void:
	var hive_point: Vector2 = mentor.world.hive_entrance_inside() if mentor.world else mentor.position
	var offset: Vector2 = mentor.forage_start_point - hive_point
	var fuzzed_angle: float = offset.angle() + deg_to_rad(randf_range(-GameConfig.recruit_dance_angle_fuzz_degrees, GameConfig.recruit_dance_angle_fuzz_degrees))
	var fuzzed_distance: float = offset.length() * (1.0 + randf_range(-GameConfig.recruit_dance_distance_fuzz_fraction, GameConfig.recruit_dance_distance_fuzz_fraction))
	var decoded: Vector2 = hive_point + Vector2.from_angle(fuzzed_angle) * fuzzed_distance

	seeker.set_forage_start_point(decoded, "dance_recruitment")
	if GameConfig.floral_constancy_on:
		seeker.preferred_species = mentor.preferred_species
	seeker.is_scouting = false

	seeker.recruit_partner = mentor
	seeker.recruit_role = "seeker"
	seeker.recruit_rate_before = seeker.avg_collection_rate
	seeker.recruit_followup_remaining = RECRUIT_FOLLOWUP_TRIPS
	mentor.recruit_partner = seeker
	mentor.recruit_role = "mentor"
	mentor.recruit_rate_before = mentor.avg_collection_rate
	mentor.recruit_followup_remaining = RECRUIT_FOLLOWUP_TRIPS
	# The structural half of "one recruit per mentor per hive visit" --
	# checked by add_dance_eligible_mentor, reset at move_bee_into_hive.
	mentor.has_danced_this_visit = true

	DiagnosticLog.log_recruitment_match(seeker, mentor, "dance")


## Fallback only -- deposits without the walk-in animation.
static func deposit_everything_remotely(bee: Node2D) -> void:
	bee.hive.deposit(bee.current_load_type, bee.current_load)
	bee.current_load = 0.0
	bee.current_load_type = ""
	bee.energy += bee.hive.take_energy(GameConfig.energy_capacity - bee.energy)
	bee.state = autonomous_state(bee, State.SEEK_FLOWER)
