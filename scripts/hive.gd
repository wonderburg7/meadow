extends Polygon2D
## The hive's meadow-side marker (the brown square foragers fly home to)
## and the accountant for everything stored in the comb.
##
## Storage physically lives in the hexagonal cells over in the hive
## view; this script routes deposits and withdrawals to them and hands
## out jobs to builders, so the meadow never needs to know how the comb
## is laid out.

signal storage_changed(nectar: float, pollen: float)

const Shapes = preload("res://scripts/shapes.gd")
const HiveCell = preload("res://scripts/hive_cell.gd")

var cells: Array = []            # populated by main.gd once the comb is built
var comb_parent: Node2D = null   # the hive-view root new cells get added to
var comb_centre: Vector2 = Vector2.ZERO

func _ready() -> void:
	polygon = Shapes.square_points(Vector2(60, 60))
	color = Color(0.55, 0.35, 0.15)  # placeholder art: brown square

## Spreads `amount` across any cells that will take it. Returns how
## much actually fitted -- anything left over is lost, which is the
## signal that the hive needs more comb.
##
## Foragers no longer use this (they walk to a specific cell instead);
## it's kept for the no-world fallback path in bee.gd.
func deposit(resource_type: String, amount: float) -> float:
	if resource_type == "" or amount <= 0.0:
		return 0.0
	var remaining := amount
	# top up part-filled cells of this type first, then start new ones
	for cell in cells:
		if remaining <= 0.0:
			break
		if cell.content_type == resource_type:
			remaining -= cell.add_resource(resource_type, remaining)
	for cell in cells:
		if remaining <= 0.0:
			break
		if cell.is_empty():
			remaining -= cell.add_resource(resource_type, remaining)
	announce()
	return amount - remaining

## Pulls up to `amount` of a resource back out of the comb.
func take(resource_type: String, amount: float) -> float:
	var still_needed := amount
	for cell in cells:
		if still_needed <= 0.0:
			break
		still_needed -= cell.take_resource(resource_type, still_needed)
	announce()
	return amount - still_needed

func total(resource_type: String) -> float:
	var sum := 0.0
	for cell in cells:
		if cell.content_type == resource_type:
			sum += cell.amount
	return sum

# --- finding cells ------------------------------------------------

## The cell a bee carrying `resource_type` should walk to: a part-filled
## cell of the same resource if there is one (so stores stay tidy and
## cells fill up rather than spreading thin), otherwise a free cell.
## Cells designated to this resource are preferred over undesignated
## ones. `except` lets a hauling builder avoid its own source cell.
func find_cell_for(resource_type: String, except: Node2D = null) -> Node2D:
	var best_empty: Node2D = null
	for cell in cells:
		if cell == except or not is_instance_valid(cell):
			continue
		if cell.space_for(resource_type) <= 0.0:
			continue
		if cell.content_type == resource_type:
			return cell   # already holds this -- top it up first
		if best_empty == null:
			best_empty = cell
		elif cell.designated_type == resource_type and best_empty.designated_type == "":
			best_empty = cell   # prefer a cell the player pinned to this
	return best_empty

func find_empty_cell() -> Node2D:
	for cell in cells:
		if cell.is_empty() and cell.designated_type == "":
			return cell
	# fall back to any empty cell, even a designated one, rather than
	# leaving an egg stranded on the floor
	for cell in cells:
		if cell.is_empty():
			return cell
	return null

func find_cell_with(resource_type: String) -> Node2D:
	for cell in cells:
		if cell.content_type == resource_type and cell.amount > 0.0:
			return cell
	return null

func find_brood_cell() -> Node2D:
	for cell in cells:
		if cell.content_type == "brood":
			return cell
	return null

func find_unfinished_cell() -> Node2D:
	for cell in cells:
		if not cell.is_built:
			return cell
	return null

func find_cell_needing_eviction() -> Node2D:
	for cell in cells:
		if cell.needs_eviction():
			return cell
	return null

## Is there anywhere else `resource_type` could go? Used to decide
## whether re-designating a cell would destroy its contents.
func has_room_elsewhere(resource_type: String, except: Node2D) -> bool:
	return find_cell_for(resource_type, except) != null

# --- growing the comb ---------------------------------------------

## Adds the next cell in the outward hex spiral as an unfinished site
## for builders to work on. Returns null when the comb has grown as far
## as the hive wall allows -- later, wall-mining bees will lift that.
func create_next_cell_site() -> Node2D:
	if comb_parent == null:
		return null
	var index := cells.size()
	var axial: Vector2i = Shapes.hex_spiral_at(index)
	var cell_offset: Vector2 = Shapes.hex_to_pixel(axial.x, axial.y, GameConfig.hive_cell_spacing)
	if cell_offset.length() + GameConfig.hive_cell_size > GameConfig.hive_wall_radius:
		return null   # would poke through the wall

	var cell := HiveCell.new()
	cell.position = comb_centre + cell_offset
	comb_parent.add_child(cell)
	cell.start_as_site()
	cells.append(cell)
	return cell

func announce() -> void:
	storage_changed.emit(total("nectar"), total("pollen"))
