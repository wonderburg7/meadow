extends Polygon2D
## A single hexagonal comb cell inside the hive.
##
## A cell holds exactly one thing at a time:
##   ""       -- empty
##   "nectar" -- stored nectar, up to `capacity`
##   "pollen" -- stored pollen, up to `capacity`
##   "brood"  -- a single developing bee (see `brood_progress`)
##
## Cells may also be *unfinished*: builders draw them over time, and a
## half-built cell can't hold anything yet. Progress is stored on the
## cell rather than the builder, so building can be abandoned partway
## and resumed later by anyone.
##
## The player can designate a cell to a specific resource. A designated
## cell refuses anything else, and any wrong contents already inside get
## hauled away by a builder.

const Shapes = preload("res://scripts/shapes.gd")

const EMPTY_COLOR := Color(0.85, 0.78, 0.55)
const NECTAR_COLOR := Color(0.95, 0.7, 0.15)
const POLLEN_COLOR := Color(0.4, 0.35, 0.8)
const BROOD_COLOR := Color(0.9, 0.9, 0.85)
const SITE_COLOR := Color(0.42, 0.34, 0.16)

var content_type: String = ""
var amount: float = 0.0
var capacity: float = 200.0
var brood_progress: float = 0.0
var being_tended: bool = false

## Building state. Cells the hive starts with are already finished.
var is_built: bool = true
var build_progress: float = 0.0
var builders: Array = []

## "" means the cell takes whatever is going. Otherwise it only accepts
## the named thing: "nectar", "pollen", or "brood" for a nursery cell
## that stores eggs rather than stores.
var designated_type: String = ""

## Which role a bee raised in this cell takes when it emerges.
## -1 means "whatever the colony default is". Set from the cell popup,
## so you can earmark a cell as, say, a builder nursery and every bee
## it ever raises comes out as a builder.
var hatch_role: int = -1

var axial: Vector2i = Vector2i.ZERO

var cell_size: float = 17.0
var info_label: Label
var outline: Line2D
var designation_ring: Line2D

func _ready() -> void:
	add_to_group("hive_cells")
	capacity = GameConfig.cell_capacity
	cell_size = GameConfig.hive_cell_size

	polygon = Shapes.hexagon_points(cell_size)
	color = EMPTY_COLOR

	outline = Line2D.new()
	_set_outline_points(outline, cell_size)
	outline.width = 1.5
	outline.default_color = Color(0.35, 0.28, 0.12)
	add_child(outline)

	# a second, brighter ring drawn only when the player has pinned this
	# cell to one resource
	designation_ring = Line2D.new()
	_set_outline_points(designation_ring, cell_size - 3.0)
	designation_ring.width = 2.0
	designation_ring.default_color = Color(1.0, 1.0, 1.0, 0.9)
	designation_ring.visible = false
	add_child(designation_ring)

	info_label = Label.new()
	info_label.position = Vector2(-cell_size, -8)
	info_label.add_theme_font_size_override("font_size", 9)
	add_child(info_label)

func _set_outline_points(line: Line2D, size: float) -> void:
	line.clear_points()
	var pts := Shapes.hexagon_points(size)
	for p in pts:
		line.add_point(p)
	line.add_point(pts[0])   # close the loop

func _process(delta: float) -> void:
	if content_type == "brood":
		var rate: float = GameConfig.tending_speed_bonus if being_tended else 1.0
		brood_progress += delta * rate
		being_tended = false   # nursery workers re-assert this each frame while tending
	_refresh()

# --- building -----------------------------------------------------

func start_as_site() -> void:
	is_built = false
	build_progress = 0.0

func claim_builder(bee: Node2D) -> void:
	if not builders.has(bee):
		builders.append(bee)

func release_builder(bee: Node2D) -> void:
	builders.erase(bee)

## Called once per frame by every builder working here, so contributions
## from several bees simply add up.
func add_build_progress(delta: float) -> void:
	if is_built:
		return
	build_progress += delta
	if build_progress >= GameConfig.cell_build_time:
		build_progress = GameConfig.cell_build_time
		is_built = true
		builders.clear()

func build_fraction() -> float:
	return clamp(build_progress / max(0.001, GameConfig.cell_build_time), 0.0, 1.0)

# --- contents -----------------------------------------------------

func is_empty() -> bool:
	return is_built and content_type == ""

func accepts(resource_type: String) -> bool:
	if not is_built:
		return false
	if designated_type != "" and designated_type != resource_type:
		return false
	return true

## True when this cell has been set aside for raising brood, so foragers
## leave it alone and nurses use it first.
func is_nursery_cell() -> bool:
	return designated_type == "brood"

func space_for(resource_type: String) -> float:
	if not is_built:
		return 0.0
	if content_type == "brood":
		return 0.0
	if not accepts(resource_type):
		return 0.0
	if content_type == "":
		return capacity
	if content_type == resource_type:
		return max(0.0, capacity - amount)
	return 0.0

## True when the player has pinned this cell to one resource but it
## still holds something else -- a builder will come and shift it.
func needs_eviction() -> bool:
	if not is_built or designated_type == "":
		return false
	if content_type == "" or content_type == "brood":
		return false
	return content_type != designated_type

## Adds up to `requested` of `resource_type`, returns how much fitted.
##
## The first delivery into a spare cell also reserves it for that
## resource, so the comb organises itself as it fills and you only need
## to intervene where you disagree.
func add_resource(resource_type: String, requested: float) -> float:
	var space := space_for(resource_type)
	if space <= 0.0:
		return 0.0
	var added: float = min(space, requested)
	if content_type == "" and designated_type == "":
		designated_type = resource_type
	content_type = resource_type
	amount += added
	return added

## Removes up to `requested`, returns how much came out.
func take_resource(resource_type: String, requested: float) -> float:
	if content_type != resource_type:
		return 0.0
	var taken: float = min(requested, amount)
	amount -= taken
	if amount <= 0.001:
		content_type = ""
		amount = 0.0
	return taken

func set_designation(resource_type: String) -> void:
	designated_type = resource_type

func start_brood() -> void:
	content_type = "brood"
	amount = 0.0
	brood_progress = 0.0

func brood_ready() -> bool:
	return content_type == "brood" and brood_progress >= GameConfig.brood_develop_time

func clear_cell() -> void:
	content_type = ""
	amount = 0.0
	brood_progress = 0.0

# --- display ------------------------------------------------------

func _refresh() -> void:
	if not is_built:
		# an unfinished cell grows outwards from a stub as it's drawn, so
		# you can see at a glance how far along it is
		var f := build_fraction()
		var drawn_size: float = lerp(cell_size * 0.35, cell_size, f)
		polygon = Shapes.hexagon_points(drawn_size)
		_set_outline_points(outline, drawn_size)
		outline.default_color = Color(0.6, 0.5, 0.25, 0.9)
		color = Color(SITE_COLOR.r, SITE_COLOR.g, SITE_COLOR.b, lerp(0.25, 0.75, f))
		designation_ring.visible = false
		info_label.text = "%d%%" % int(f * 100.0)
		return

	polygon = Shapes.hexagon_points(cell_size)
	_set_outline_points(outline, cell_size)
	outline.default_color = Color(0.35, 0.28, 0.12)
	designation_ring.visible = designated_type != ""
	if designated_type == "nectar":
		designation_ring.default_color = Color(1.0, 0.85, 0.3, 0.95)
	elif designated_type == "pollen":
		designation_ring.default_color = Color(0.7, 0.65, 1.0, 0.95)
	elif designated_type == "brood":
		designation_ring.default_color = Color(0.6, 1.0, 0.7, 0.95)

	match content_type:
		"nectar":
			color = NECTAR_COLOR
			info_label.text = "N%d" % int(round(amount))
		"pollen":
			color = POLLEN_COLOR
			info_label.text = "P%d" % int(round(amount))
		"brood":
			color = BROOD_COLOR
			info_label.text = "egg %d%%" % int(development_percent())
		_:
			color = EMPTY_COLOR
			# an empty cell reserved for brood still says so, otherwise
			# you can't tell a nursery cell from an unused one
			info_label.text = "egg" if is_nursery_cell() else ""

func development_percent() -> float:
	if content_type != "brood":
		return 0.0
	return min(100.0, 100.0 * brood_progress / max(0.001, GameConfig.brood_develop_time))
