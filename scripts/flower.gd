extends Polygon2D
## Flower -- v1 prototype, slice 7.
## Holds a limited amount of nectar and pollen that drains as bees
## collect and recharges over time. Only one bee may visit a given
## flower at a time (see `occupied_by`).
##
## Two species now, so "which flower" is a real decision:
##   Clover -- nectar-rich, pollen-poor, yellow
##   Borage -- pollen-rich, nectar-poor, blue-violet

const Shapes = preload("res://scripts/shapes.gd")

## Flowering seasons.
##
## Each species is in flower over a window of the year, given as a
## fraction of a season from 0 (first day) to 1 (the last before
## winter). Outside its window a species produces nothing and new ones
## don't seed.
##
## This is the cheapest way to make three systems that already exist
## matter more than they did. Floral constancy becomes a real commitment
## rather than a curiosity, because the species you pinned a forager to
## will run out. Forage start points matter, because the best ground
## moves. And the pollen supply has a genuine gap in it, which is what
## makes storing ahead worth doing.
const SPECIES := [
	{
		# Clover spreads by runners and seeds into dense mats -- real
		# patches are tightly packed, so a small cluster radius.
		"name": "Clover",
		# Spans almost the whole year, which is why it is the backbone of
		# a colony's. Between clover and borage something is always in
		# flower -- simulating the windows found a stretch at the turn of
		# the year with nothing at all out, which would have starved the
		# colony for no reason worth playing.
		"season_start": 0.00, "season_end": 0.85,
		"nectar_capacity": 20.0,
		"pollen_capacity": 10.0,
		"weight": 40.0,
		"cluster_radius": 45.0,
		"cluster_chance": 0.85,
		"color": Color(0.95, 0.85, 0.1),
		"centre": Color(0.5, 0.35, 0.05),
	},
	{
		# Borage self-seeds readily and is often grown in blocks -- loose
		# but still clearly patchy.
		"name": "Borage",
		# Comes in late and keeps going, so it carries the pollen supply
		# through the part of the year when clover is finishing.
		"season_start": 0.30, "season_end": 1.00,
		"nectar_capacity": 8.0,
		"pollen_capacity": 22.0,
		"weight": 30.0,
		"cluster_radius": 70.0,
		"cluster_chance": 0.7,
		"color": Color(0.45, 0.4, 0.85),
		"centre": Color(0.15, 0.1, 0.4),
	},
	{
		# rich but slow: rewards spreading out rather than camping a patch
		# Biennial, colonises disturbed ground at wood edges -- loose,
		# scattered stands rather than a tidy patch.
		"name": "Foxglove",
		# A short mid-summer window. Rich while it lasts, and worth
		# reorganising around, which is the point of having it.
		"season_start": 0.40, "season_end": 0.65,
		"nectar_capacity": 34.0,
		"pollen_capacity": 6.0,
		"recharge_scale": 0.4,
		"weight": 8.0,
		"cluster_radius": 110.0,
		"cluster_chance": 0.55,
		"color": Color(0.78, 0.35, 0.6),
		"centre": Color(0.42, 0.12, 0.3),
	},
	{
		# no nectar at all, so pollen foraging becomes a spatial decision
		# Annual of disturbed/arable ground, wind-scattered seed -- the
		# least clustered species, closer to individual plants than a
		# patch.
		"name": "Poppy",
		# Early, and the only pollen worth having before the borage
		# arrives -- so the start of a run has a real constraint.
		"season_start": 0.00, "season_end": 0.45,
		"nectar_capacity": 0.0,
		"pollen_capacity": 30.0,
		"recharge_scale": 1.0,
		"weight": 22.0,
		"cluster_radius": 140.0,
		"cluster_chance": 0.3,
		"color": Color(0.85, 0.22, 0.18),
		"centre": Color(0.15, 0.12, 0.1),
	},
]

## The window of the year this species is in flower, as fractions of a
## season. Copied off the species table in setup.
var season_start: float = 0.0
var season_end: float = 1.0

## Which entry of SPECIES this flower is. Kept so a saved game can put
## the same flower back rather than having to match it up by name.
var species_index: int = 0
var species_name: String = "Clover"
var nectar_capacity: float = 20.0
var pollen_capacity: float = 10.0
var nectar_recharge_rate: float = 0.5
var pollen_recharge_rate: float = 0.1

var nectar_amount: float
var pollen_amount: float
var occupied_by: Node2D = null   # the bee currently visiting this flower, if any
var marked_at: float = -999.0    # sim-time of the last tarsal scent mark
var marked_by: Node2D = null     # which bee left it

var age_seconds: float = 0.0
var lifespan_seconds: float = 1800.0

var nectar_label: Label
var pollen_label: Label

func _ready() -> void:
	add_to_group("flowers")

func setup(index: int) -> void:
	species_index = index % SPECIES.size()
	var s: Dictionary = SPECIES[species_index]
	species_name = s.name
	nectar_capacity = s.nectar_capacity
	pollen_capacity = s.pollen_capacity
	season_start = s.get("season_start", 0.0)
	season_end = s.get("season_end", 1.0)
	# some species refill more slowly than others
	var recharge_scale: float = s.get("recharge_scale", 1.0)
	nectar_recharge_rate = GameConfig.nectar_recharge_rate * recharge_scale
	pollen_recharge_rate = GameConfig.pollen_recharge_rate * recharge_scale
	nectar_amount = nectar_capacity
	pollen_amount = pollen_capacity

	var spread: float = GameConfig.flower_lifespan_variation
	lifespan_seconds = GameConfig.flower_lifespan_days * GameConfig.seconds_per_day \
		* randf_range(1.0 - spread, 1.0 + spread)
	# start partway through life, so the first generation doesn't all
	# wither at the same moment
	age_seconds = randf() * lifespan_seconds

	polygon = Shapes.square_points(Vector2(28, 28))
	color = s.color

	var centre_dot := Polygon2D.new()
	centre_dot.polygon = Shapes.circle_points(5.0)
	centre_dot.color = s.centre
	add_child(centre_dot)

	# nectar amount reads bottom-left, pollen amount reads bottom-right
	nectar_label = Label.new()
	nectar_label.position = Vector2(-16, 11)
	nectar_label.add_theme_font_size_override("font_size", 10)
	add_child(nectar_label)

	pollen_label = Label.new()
	pollen_label.position = Vector2(4, 11)
	pollen_label.add_theme_font_size_override("font_size", 10)
	add_child(pollen_label)

	_update_labels()

## Picks a species by rarity weight. Clover is common, foxglove scarce.
static func pick_species_index() -> int:
	var total := 0.0
	for s in SPECIES:
		total += s.get("weight", 1.0)
	var roll := randf() * total
	for i in range(SPECIES.size()):
		roll -= SPECIES[i].get("weight", 1.0)
		if roll <= 0.0:
			return i
	return 0

## As hive_cell.gd, and for the same reason: there are 250 of these and
## the two amount labels were being reformatted sixty times a second
## each, which is thirty thousand throwaway strings a second to show
## numbers that tick over once or twice.
const PRESENTATION_PER_SECOND := 6.0
var presentation_timer: float = 0.0

func _process(delta: float) -> void:
	Perf.begin("flowers")
	# Out of season a plant produces nothing; at the edges of its window
	# it produces a little. The plant stays where it is either way --
	# flowers popping in and out of existence would read as a glitch
	# rather than as a season.
	var strength: float = season_strength()
	if strength > 0.0:
		nectar_amount = min(nectar_capacity, nectar_amount + nectar_recharge_rate * strength * delta)
		pollen_amount = min(pollen_capacity, pollen_amount + pollen_recharge_rate * strength * delta)

	# Flowers don't last forever. main.gd seeds a replacement elsewhere,
	# so the meadow drifts around while staying about as full.
	age_seconds += delta
	if age_seconds >= lifespan_seconds:
		if occupied_by != null and is_instance_valid(occupied_by):
			occupied_by.release_flower_reference(self)
		queue_free()
		Perf.end("flowers")
		return

	# Everything above runs every frame: a flower recharges and ages at
	# the same rate whether it is on screen or not. Only the drawing
	# below is throttled.
	if not is_visible_in_tree():
		Perf.end("flowers")
		return
	presentation_timer -= delta
	if presentation_timer > 0.0:
		Perf.end("flowers")
		return
	presentation_timer = (1.0 / PRESENTATION_PER_SECOND) * randf_range(0.85, 1.15)
	# `strength` is passed in rather than asked for again -- it was being
	# computed twice per flower per frame.
	_update_fade(strength)
	_update_labels()
	Perf.end("flowers")

## Where we are in the year, 0 to 1. Winter is not part of the season:
## a season runs from day 1 to the day winter starts.
static func season_fraction() -> float:
	if not GameConfig.seasons_on:
		return 0.5     # permanently mid-season
	var day: float = 1.0 + Session.sim_time / max(1.0, GameConfig.seconds_per_day)
	var length: float = max(1.0, GameConfig.season_length_days)
	return clampf(fmod(day, length) / length, 0.0, 1.0)

## Is this species in flower now? Out of season a plant is still there --
## it just isn't producing, which reads better than flowers vanishing and
## reappearing.
func in_season() -> bool:
	if not GameConfig.seasons_on:
		return true
	var f: float = season_fraction()
	return f >= season_start and f <= season_end

## How strongly it is flowering: nothing at the edges of its window,
## full in the middle. Eased rather than switched, so a species fading
## out gives the colony warning rather than stopping dead.
func season_strength() -> float:
	if not GameConfig.seasons_on:
		return 1.0
	var f: float = season_fraction()
	if f < season_start or f > season_end:
		return 0.0
	var span: float = max(0.001, season_end - season_start)
	var through: float = (f - season_start) / span
	# a smooth arch: 0 at both ends, 1 in the middle
	return sin(through * PI)

func get_available(resource_type: String) -> float:
	return nectar_amount if resource_type == "nectar" else pollen_amount

func get_capacity(resource_type: String) -> float:
	return nectar_capacity if resource_type == "nectar" else pollen_capacity

func get_recharge_rate(resource_type: String) -> float:
	return nectar_recharge_rate if resource_type == "nectar" else pollen_recharge_rate

## How long, in seconds, until this flower is back to full for the
## given resource. Bees use this to decide how long to stay away.
func seconds_until_full(resource_type: String) -> float:
	var missing: float = get_capacity(resource_type) - get_available(resource_type)
	var rate: float = get_recharge_rate(resource_type)
	if rate <= 0.0:
		return 0.0
	return max(0.0, missing / rate)

## Removes up to `amount` of `resource_type` and returns how much was
## actually taken (may be less than requested if the flower runs low).
func collect(resource_type: String, amount: float) -> float:
	if resource_type == "nectar":
		var taken_n: float = min(amount, nectar_amount)
		nectar_amount -= taken_n
		return taken_n
	else:
		var taken_p: float = min(amount, pollen_amount)
		pollen_amount -= taken_p
		return taken_p

func release(bee: Node2D) -> void:
	if occupied_by == bee:
		occupied_by = null

# --- tarsal secretion markers -------------------------------------
## Real bees leave a scent from their feet on flowers they land on, and
## other foragers read it as "someone just emptied this". Modelled here
## as a timestamp; see GameConfig.tarsal_markers_on.

func leave_marker(bee: Node2D) -> void:
	marked_at = Session.sim_time
	marked_by = bee

## True if another bee marked this flower recently. A bee ignores its
## own mark, since it already has its own memory of what it drained.
func is_marked(asking_bee: Node2D) -> bool:
	if marked_by == null or marked_by == asking_bee:
		return false
	return Session.sim_time - marked_at < GameConfig.tarsal_marker_seconds

func marker_age() -> float:
	if marked_by == null:
		return -1.0
	return Session.sim_time - marked_at

## Fades the flower out as it empties so depletion is visible, and
## back in as it recharges. Purely a visual aid for playtesting.
##
## The fade is applied to the petal colour rather than `modulate`,
## because `modulate` cascades to child nodes and was dragging the
## amount labels down to 35% alpha exactly when you most want to read
## them (a nearly empty flower).
func _update_fade(strength: float) -> void:
	var fullness: float = (nectar_amount + pollen_amount) / max(0.001, nectar_capacity + pollen_capacity)
	color.a = lerp(0.35, 1.0, fullness)
	# Out of season a plant is drawn greyed and small, so a patch that has
	# gone over is obvious from the air rather than something you only
	# discover by sending foragers to it.
	if strength <= 0.0:
		color = color.lerp(Color(0.45, 0.44, 0.38, color.a), 0.75)
		scale = Vector2(0.7, 0.7)
	else:
		scale = Vector2.ONE

func _update_labels() -> void:
	nectar_label.text = str(int(round(nectar_amount)))
	pollen_label.text = str(int(round(pollen_amount)))
