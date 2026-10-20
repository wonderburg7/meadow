extends Node2D
## A second colony out in the meadow, run by the game.
##
## Deliberately *not* a second copy of the player's simulation. Running
## another few hundred bees, each with its own state machine and
## pathfinding, would roughly double the cost of the game to produce
## something the player mostly can't see -- they only ever watch one hive
## interior at a time. So this is an abstract colony: a handful of
## numbers advanced once a second, with a small number of visible
## foragers drawn flying to real flowers so the competition is something
## you can watch rather than only read about.
##
## What makes it a rival rather than scenery is that its foragers drain
## the same flowers the player's do. There is no combat and no direct
## interference -- the pressure is entirely economic, which is both truer
## to bumblebees and a more interesting problem than a fight.
##
## The feedback rules below are the whole "AI". They are deliberately
## legible: a player who watches it for a while should be able to work
## out what it is doing and out-plan it, rather than losing to something
## opaque.

const Shapes = preload("res://scripts/shapes.gd")
const SpriteCatalogue = preload("res://scripts/sprite_catalogue.gd")

## The ruin's tint: the darker skep goes grey when the colony dies out.
const RUIN_TINT := Color(0.55, 0.55, 0.55)

## Visible foragers. Enough to read as a colony at a glance without
## costing anything that matters.
const SHOWN_FORAGERS := 8
const FORAGER_SPEED := 95.0

## How the colony divides itself. It rebalances towards these whenever
## something is short -- see `_rebalance`.
const MIN_FORAGER_SHARE := 0.45
const MAX_FORAGER_SHARE := 0.85

var hive_position: Vector2 = Vector2.ZERO
var world: Node2D = null

# --- the abstract colony ------------------------------------------
var population: float = 0.0
var nectar: float = 0.0
var pollen: float = 0.0
var brood: float = 0.0
var forager_share: float = 0.7
var alive: bool = true

## Sim seconds since the last tick. The whole colony updates once a
## second rather than every frame -- nothing here changes fast enough
## for that to be visible, and it keeps the cost flat.
## Random phase, so this doesn't land on the same frame as season.gd's
## tick. See the note there.
var tick_timer: float = randf()

## The drawn foragers: each just a position, a target flower and a
## direction of travel. No state machine, no energy, no pathfinding.
var foragers: Array = []
var body: Polygon2D
var skep: Sprite2D
var label: Label

func _ready() -> void:
	add_to_group("rival_hive")
	z_index = 1

	body = Polygon2D.new()
	body.polygon = Shapes.square_points(Vector2(52, 52))
	body.color = Color(0.42, 0.24, 0.30, 0.0)   # hit shape only; the skep below is drawn
	add_child(body)

	# The darker recolour of the player's skep (SP-5), footprint centred.
	skep = Sprite2D.new()
	skep.texture = SpriteCatalogue.HIVE_SKEP_RIVAL_SHEET
	skep.centered = false
	PixelSprite.apply(skep, PixelSprite.MEADOW_SCALE)
	skep.position = -(SpriteCatalogue.HIVE_SKEP_ANCHOR + Vector2(SpriteCatalogue.HIVE_SKEP_CELL_GUTTER, SpriteCatalogue.HIVE_SKEP_CELL_GUTTER)) * PixelSprite.MEADOW_SCALE
	add_child(skep)

	label = Label.new()
	label.position = Vector2(-34, -46)
	label.add_theme_font_size_override("font_size", 11)
	label.add_theme_color_override("font_color", Color(1.0, 0.75, 0.75))
	add_child(label)

	population = max(4.0, GameConfig.rival_starting_bees)
	nectar = 120.0
	pollen = 40.0

	for i: int in range(SHOWN_FORAGERS):
		foragers.append(_make_forager())

func save_data() -> Dictionary:
	return {
		"population": population,
		"nectar": nectar,
		"pollen": pollen,
		"brood": brood,
		"forager_share": forager_share,
		"alive": alive,
	}

func restore(data: Dictionary) -> void:
	population = float(data.get("population", max(4.0, GameConfig.rival_starting_bees)))
	nectar = float(data.get("nectar", 120.0))
	pollen = float(data.get("pollen", 40.0))
	brood = float(data.get("brood", 0.0))
	forager_share = float(data.get("forager_share", 0.7))
	if not bool(data.get("alive", true)):
		if alive:
			_collapse()
	elif not alive:
		alive = true
		skep.modulate = Color.WHITE
		for i: int in range(SHOWN_FORAGERS):
			foragers.append(_make_forager())
		_update_label()
	else:
		_update_label()

func _make_forager() -> Dictionary:
	var dot := Polygon2D.new()
	dot.polygon = Shapes.circle_points(3.5, 8)
	dot.color = Color(0.95, 0.55, 0.55)
	dot.position = position
	get_parent().add_child(dot)
	return {"node": dot, "target": null, "heading_home": false, "load": 0.0}

func _process(delta: float) -> void:
	Perf.begin("rival")
	if not alive:
		Perf.end("rival")
		return
	_move_foragers(delta)

	tick_timer += delta
	if tick_timer < 1.0:
		Perf.end("rival")
		return
	var elapsed := tick_timer
	tick_timer = 0.0
	_advance_colony(elapsed)
	_update_label()
	Perf.end("rival")

# --- the colony's own rules ---------------------------------------
## Once a second: eat, grow, and adjust what it is doing about whatever
## it is short of. Five rules, in the order they matter.
func _advance_colony(elapsed: float) -> void:
	# 1. Everyone eats. This is the pressure that makes the rest matter:
	#    a colony that stops foraging starves rather than coasting.
	var eaten: float = population * GameConfig.rival_eat_per_bee * elapsed
	nectar -= eaten
	if nectar < 0.0:
		# Short of food, bees die. Losing a share rather than a fixed
		# number, so a big colony collapses faster than a small one --
		# which is what stops it growing without limit.
		var starved: float = min(population, -nectar * GameConfig.rival_starve_rate)
		population -= starved
		nectar = 0.0

	# 2. Foraging brings in nectar and pollen, in proportion to how many
	#    bees are on it and how much forage is left nearby. Two things
	#    hold it down, and both matter:
	#
	#    Richness is the competition -- if the player has stripped the
	#    flowers, the rival's income falls just as theirs would.
	#
	#    Crowding is the carrying capacity: more bees working the same
	#    patch get less each. Without it the colony either ran up to its
	#    hard cap or died out, with nothing in between, whatever the
	#    forage was doing. With it, the size it settles at *is* a
	#    reading of how much meadow the player has left it.
	var foraging: float = population * forager_share
	var richness: float = _local_forage_richness()
	var crowding: float = 1.0 / (1.0 + population / max(1.0, GameConfig.rival_crowding_scale))
	var yield_factor: float = richness * crowding * elapsed
	nectar += foraging * GameConfig.rival_nectar_per_bee * yield_factor
	nectar = min(nectar, population * GameConfig.rival_store_per_bee)
	pollen += foraging * GameConfig.rival_pollen_per_bee * yield_factor

	# 3. Pollen becomes brood, brood becomes bees -- but only while there
	#    is food in hand to spare. A colony that grows on an empty larder
	#    booms and then starves; this is what makes it settle instead.
	var days_of_food: float = nectar / max(0.01, population * GameConfig.rival_eat_per_bee)
	if days_of_food >= GameConfig.rival_brood_gate_days:
		var nurses: float = population * (1.0 - forager_share)
		var can_raise: float = min(pollen / max(0.1, GameConfig.rival_pollen_per_bee_raised), nurses * elapsed * GameConfig.rival_brood_per_nurse)
		if can_raise > 0.0:
			pollen -= can_raise * GameConfig.rival_pollen_per_bee_raised
			brood += can_raise
	var hatched: float = brood * GameConfig.rival_hatch_rate * elapsed
	brood -= hatched
	population += hatched

	# 4. A colony can't grow past what the meadow around it supports.
	population = min(population, GameConfig.rival_max_bees)
	if population < 1.0:
		_collapse()
		return

	_rebalance()

## Puts more bees on whatever is scarcest. Deliberately simple and
## deliberately visible in its effects: short of food, nearly everyone
## forages; comfortable, more bees go on brood and the colony grows.
func _rebalance() -> void:
	var days_of_food: float = nectar / max(0.01, population * GameConfig.rival_eat_per_bee)
	if days_of_food < GameConfig.rival_brood_gate_days * 0.75:
		forager_share = min(MAX_FORAGER_SHARE, forager_share + 0.05)
	elif days_of_food > 90.0:
		forager_share = max(MIN_FORAGER_SHARE, forager_share - 0.05)

## How much forage is left within range. Sampled from the real flowers,
## so the player stripping a patch genuinely costs the rival income --
## and the rival working a patch costs the player.
func _local_forage_richness() -> float:
	if world == null or not is_instance_valid(world):
		return 1.0
	var total := 0.0
	var counted := 0
	for flower: Node in world.get_tree().get_nodes_in_group("flowers"):
		if not is_instance_valid(flower):
			continue
		if flower.position.distance_to(position) > GameConfig.rival_forage_range:
			continue
		total += flower.nectar_amount / max(1.0, flower.nectar_capacity)
		counted += 1
	if counted == 0:
		return 0.15    # nothing in range: scraping by on very little
	return clampf(total / float(counted), 0.1, 1.0)

## Died out. The hive stays on the map as a ruin, because a colony that
## simply vanished would leave the player wondering whether it had ever
## been there.
func _collapse() -> void:
	alive = false
	population = 0.0
	skep.modulate = RUIN_TINT
	label.text = "Rival hive — collapsed"
	for forager: Variant in foragers:
		if is_instance_valid(forager.node):
			forager.node.queue_free()
	foragers.clear()

# --- the visible foragers -----------------------------------------
## Purely presentational, with one real consequence: when a forager
## reaches a flower it actually takes nectar out of it. That is what
## makes the rival something the player competes with rather than a
## number in the corner.
func _move_foragers(delta: float) -> void:
	var showing: int = clampi(int(population * forager_share / 3.0), 1, SHOWN_FORAGERS)
	for i: int in range(foragers.size()):
		var forager: Dictionary = foragers[i]
		if not is_instance_valid(forager.node):
			continue
		forager.node.visible = i < showing and alive
		if not forager.node.visible:
			continue

		if forager.heading_home:
			forager.node.position = forager.node.position.move_toward(position, FORAGER_SPEED * delta)
			if forager.node.position.distance_to(position) < 8.0:
				forager.heading_home = false
				forager.target = null
			continue

		if forager.target == null or not is_instance_valid(forager.target):
			forager.target = _pick_flower()
			if forager.target == null:
				forager.heading_home = true
				continue

		forager.node.position = forager.node.position.move_toward(forager.target.position, FORAGER_SPEED * delta)
		if forager.node.position.distance_to(forager.target.position) < 6.0:
			# A real withdrawal from a real flower. Small per visit, but
			# it is the whole point: the two colonies are drawing on one
			# meadow.
			forager.target.collect("nectar", GameConfig.rival_flower_take)
			forager.heading_home = true

func _pick_flower() -> Node2D:
	if world == null or not is_instance_valid(world):
		return null
	var best: Node2D = null
	var best_score := 0.0
	var flowers: Array = world.get_tree().get_nodes_in_group("flowers")
	if flowers.is_empty():
		return null
	# Sampled rather than exhaustively searched -- with 250 flowers and
	# eight foragers re-picking constantly, a full scan each time is real
	# cost for no visible benefit.
	for attempt: int in range(12):
		var flower: Variant = flowers[randi() % flowers.size()]
		if not is_instance_valid(flower):
			continue
		var distance: float = flower.position.distance_to(position)
		if distance > GameConfig.rival_forage_range:
			continue
		var score: float = flower.nectar_amount / max(40.0, distance)
		if score > best_score:
			best_score = score
			best = flower
	return best

func _update_label() -> void:
	if not alive:
		return
	label.text = "Rival hive — %d bees" % int(population)

## What the player's HUD shows about it, when they have discovered it.
func summary() -> String:
	if not alive:
		return "Rival hive — collapsed"
	return "Rival hive — about %d bees, %s" % [
		int(population),
		"growing" if brood > 1.0 else "holding steady",
	]
