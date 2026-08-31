extends Polygon2D
## Flower -- v1 prototype, slice 7.
## Holds a limited amount of nectar and pollen that drains as bees
## collect and recharges over time. Only one bee may visit a given
## flower at a time (see `occupied_by`).
##
## Six species now, so "which flower" is a real decision -- see
## flower_species.gd for the full roster.

const Shapes = preload("res://scripts/shapes.gd")
const CrabSpider = preload("res://scripts/crab_spider.gd")
const FlowerSpecies = preload("res://scripts/flower_species.gd")

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
## Multiplies flower_handling_time -- a fiddly flower (e.g. Bramble's ring
## of stamens) takes longer per visit than a simple open one (e.g.
## Dandelion's flat disc). 1.0 for species that don't specify it.
var handling_time_scale: float = 1.0

## Backing fields for the lazy-recharge properties below. Recharge is
## computed on demand (whenever code reads nectar_amount/pollen_amount)
## rather than accumulated every frame -- see _sync_recharge(). This is
## an approximation, not an exact replay of the old per-frame Euler
## accumulation: it multiplies the *instantaneous* season_strength() at
## read-time by the elapsed time since the last read/write, rather than
## integrating the strength curve across that gap. That only differs
## from the old behaviour while a flower's season window is ramping in
## or out (season_strength is flat everywhere else), and the result is
## still capped at capacity either way, so the drift can't compound.
var _nectar_amount: float = 0.0
var _pollen_amount: float = 0.0
var _last_recharge_update: float = 0.0

var nectar_amount: float:
	get:
		_sync_recharge()
		return _nectar_amount
	set(value):
		_sync_recharge()
		_nectar_amount = value

var pollen_amount: float:
	get:
		_sync_recharge()
		return _pollen_amount
	set(value):
		_sync_recharge()
		_pollen_amount = value

var occupied_by: Node2D = null   # the bee currently visiting this flower, if any
var marked_at: float = -999.0    # sim-time of the last tarsal scent mark
var marked_by: Node2D = null     # which bee left it

var age_seconds: float = 0.0
var lifespan_seconds: float = 1800.0

var nectar_label: Label
var pollen_label: Label
## Presentation-only selection outline. InputSelection owns which meadow
## object is selected and calls set_selected; the flower simulation never
## reads this node.
var selection_ring: Line2D

# --- crab spiders (see CRAB_SPIDER_PLAN.md) -------------------------
## Whether this flower currently carries a spider. False for essentially
## every flower, even with predators_on -- see CrabSpider.maybe_spawn.
var has_crab_spider: bool = false
var crab_spider_settled_at: float = -999.0      # sim-time the spider arrived here
var crab_spider_reveal_until: float = -999.0    # sim-time; drives the brief-visibility presentation
var crab_spider_alarm_at: float = -999.0        # sim-time of the last attack here
var crab_spider_marker: Polygon2D
var crab_spider_dev_marker: Line2D

func _ready() -> void:
	add_to_group("flowers")

func setup(index: int) -> void:
	species_index = index % FlowerSpecies.SPECIES.size()
	var s: Dictionary = FlowerSpecies.SPECIES[species_index]
	species_name = s.name
	nectar_capacity = s.nectar_capacity
	pollen_capacity = s.pollen_capacity
	season_start = s.get("season_start", 0.0)
	season_end = s.get("season_end", 1.0)
	handling_time_scale = s.get("handling_time_scale", 1.0)
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

	selection_ring = Line2D.new()
	selection_ring.points = Shapes.circle_points(24.0, 28)
	selection_ring.closed = true
	selection_ring.width = 3.5
	selection_ring.default_color = Color(0.2, 1.0, 0.4, 0.95)
	selection_ring.visible = false
	selection_ring.z_index = 10
	add_child(selection_ring)

	# A "bushy" species (Bramble) is still one Flower node with one
	# feeding slot, same as every other species -- but clustered flowers
	# of the same bushy species get an irregular green backdrop each, so
	# a cluster reads as one shared bush rather than loose blooms in a
	# field. show_behind_parent keeps it under the petal shape above;
	# per-flower jitter on the shape and position means overlapping
	# backdrops from nearby cluster-mates blend into one ragged outline
	# instead of a visible stack of identical circles.
	if s.get("bushy", false):
		var bush := Polygon2D.new()
		var bush_points := PackedVector2Array()
		var bush_segments := 10
		for i in range(bush_segments):
			var angle: float = TAU * i / bush_segments
			var jitter: float = randf_range(0.75, 1.2)
			bush_points.append(Vector2(cos(angle), sin(angle)) * 34.0 * jitter)
		bush.polygon = bush_points
		bush.color = Color(0.22, 0.32, 0.12, 0.6)
		bush.show_behind_parent = true
		bush.position = Vector2(randf_range(-10.0, 10.0), randf_range(-10.0, 10.0))
		add_child(bush)

	var centre_dot := Polygon2D.new()
	centre_dot.polygon = Shapes.circle_points(5.0)
	centre_dot.color = s.centre
	add_child(centre_dot)

	# A small dark shape, hidden except for the brief flash a spider gets
	# on an attack or a relocation (or the dev reveal toggle) -- see
	# CRAB_SPIDER_PLAN.md section 7. Placeholder-art style, same as
	# everything else here.
	crab_spider_marker = Polygon2D.new()
	crab_spider_marker.polygon = Shapes.circle_points(4.0)
	crab_spider_marker.color = Color(0.1, 0.1, 0.1)
	crab_spider_marker.position = Vector2(8, -8)
	crab_spider_marker.visible = false
	add_child(crab_spider_marker)

	# The dark dot above is deliberately tiny and easy to miss -- that's
	# the point in normal play. But that also made Session.show_crab_spiders
	# useless for testing: a 4px dark circle is nearly invisible against
	# 500 flowers even when you know to look. This one only ever appears
	# under that dev toggle (never from a real in-play flash), and uses a
	# colour nothing else in the game does, so a spider is unmissable
	# while testing. Drawn as an unfilled ring, not a filled disc -- an
	# earlier filled version was big enough to read as a separate object
	# sitting next to the flower, which made bees flying to the flower
	# look like they were beelining for "the spider" itself. A ring
	# frames the flower it's on instead of competing with it.
	crab_spider_dev_marker = Line2D.new()
	crab_spider_dev_marker.points = Shapes.circle_points(22.0)
	crab_spider_dev_marker.closed = true
	crab_spider_dev_marker.width = 3.5
	crab_spider_dev_marker.default_color = Color(1.0, 0.0, 0.85, 0.85)
	crab_spider_dev_marker.visible = false
	add_child(crab_spider_dev_marker)

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

## As hive_cell.gd, and for the same reason: there are 250 of these and
## the two amount labels were being reformatted sixty times a second
## each, which is thirty thousand throwaway strings a second to show
## numbers that tick over once or twice.
const PRESENTATION_PER_SECOND := 6.0
var presentation_timer: float = 0.0

## Catches nectar_amount/pollen_amount up to the current sim time,
## before either is read or written. Out of season this adds nothing
## (season_strength is 0), matching the old per-frame gate. The plant
## stays where it is whether it's recharging or not -- flowers popping
## in and out of existence would read as a glitch rather than as a
## season.
func _sync_recharge() -> void:
	var elapsed: float = Session.sim_time - _last_recharge_update
	if elapsed <= 0.0:
		return
	var seasonal_strength: float = season_strength()
	var senescence_scale: float = _senescence_scale()
	var strength: float = seasonal_strength * senescence_scale
	if strength > 0.0:
		var base_nectar: float = nectar_recharge_rate * seasonal_strength * elapsed
		var base_pollen: float = pollen_recharge_rate * seasonal_strength * elapsed
		var actual_nectar: float = min(nectar_capacity, _nectar_amount + base_nectar * senescence_scale)
		var actual_pollen: float = min(pollen_capacity, _pollen_amount + base_pollen * senescence_scale)
		if senescence_scale < 1.0:
			# Count only resource that could actually have been stored. This is
			# zero while the feature is off and excludes recharge lost to a full
			# flower, so the campaign measures the active gameplay effect.
			var unsenesced_nectar: float = min(nectar_capacity, _nectar_amount + base_nectar)
			var unsenesced_pollen: float = min(pollen_capacity, _pollen_amount + base_pollen)
			DiagnosticLog.count_flower_senescence_loss(unsenesced_nectar - actual_nectar, unsenesced_pollen - actual_pollen)
		_nectar_amount = actual_nectar
		_pollen_amount = actual_pollen
	_last_recharge_update = Session.sim_time

## Slice 8: how much slower this flower recharges as it nears the end of
## its life. 1.0 (full speed) at age 0, easing linearly down to
## GameConfig.flower_senescence_floor at lifespan_seconds. Off by default
## via GameConfig.flower_senescence_on -- see the toggle's own comment.
func _senescence_scale() -> float:
	if not GameConfig.flower_senescence_on:
		return 1.0
	var age_fraction: float = clampf(age_seconds / max(1.0, lifespan_seconds), 0.0, 1.0)
	return lerp(1.0, GameConfig.flower_senescence_floor, age_fraction)

func _process(delta: float) -> void:
	Perf.begin("flowers")
	if GameConfig.predators_on:
		CrabSpider.update(self, delta)

	# Flowers don't last forever. main.gd seeds a replacement elsewhere,
	# so the meadow drifts around while staying about as full.
	age_seconds += delta
	if age_seconds >= lifespan_seconds:
		DiagnosticLog.count_flower_senescence()
		if occupied_by != null and is_instance_valid(occupied_by):
			occupied_by.release_flower_reference(self)
		if has_crab_spider:
			CrabSpider.relocate(self, false)
		queue_free()
		Perf.end("flowers")
		return

	# Ageing above runs every frame regardless of visibility; recharge is
	# lazy (see _sync_recharge) so it isn't computed here at all unless
	# something below reads nectar_amount/pollen_amount. Only the drawing
	# below is throttled.
	if not is_visible_in_tree():
		Perf.end("flowers")
		return
	presentation_timer -= delta
	if presentation_timer > 0.0:
		Perf.end("flowers")
		return
	presentation_timer = (1.0 / PRESENTATION_PER_SECOND) * randf_range(0.85, 1.15)
	_update_fade(season_strength())
	_update_labels()
	_update_crab_spider_marker()
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

## What's actually being added per second right now -- nominal rate scaled
## by both season and senescence, matching _sync_recharge()'s own maths.
## The HUD shows these, not the nominal fields, so a flower that's out of
## season or senescent doesn't read as "should be recharging" when it isn't.
func effective_nectar_rate() -> float:
	return nectar_recharge_rate * season_strength() * _senescence_scale()

func effective_pollen_rate() -> float:
	return pollen_recharge_rate * season_strength() * _senescence_scale()

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

func set_selected(value: bool) -> void:
	if selection_ring != null:
		selection_ring.visible = value

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
	# Off by default -- see Session.show_flower_amounts. The numbers are
	# still available by clicking the flower; this only governs whether
	# they're written under every one of them all the time.
	nectar_label.visible = Session.show_flower_amounts
	pollen_label.visible = Session.show_flower_amounts
	if not Session.show_flower_amounts:
		return
	nectar_label.text = str(int(round(nectar_amount)))
	pollen_label.text = str(int(round(pollen_amount)))

## Hidden except for a brief flash on an attack or a relocation -- see
## CRAB_SPIDER_PLAN.md section 7. Folded into this file's existing
## throttled presentation pass rather than a second per-frame check. The
## dev-only reveal (Session.show_crab_spiders) drives a separate, much
## more conspicuous marker below rather than this one, so testing
## doesn't depend on spotting a near-invisible dot.
func _update_crab_spider_marker() -> void:
	crab_spider_marker.visible = has_crab_spider and Session.sim_time < crab_spider_reveal_until
	crab_spider_dev_marker.visible = has_crab_spider and Session.show_crab_spiders
