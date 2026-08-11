extends Polygon2D
## A block of soil forming the hive wall.
##
## Soil sits on the same hexagonal grid as the comb, at the same size,
## so a block can later be mined out and a cell drawn in its place --
## that's how the hive will grow beyond its starting footprint.
##
## Drawn as flat colour with no outline, so neighbouring blocks fuse
## into one solid mass of earth rather than reading as a tiled pattern.
## The individual blocks only become visible once mining starts eating
## holes in them.

const Shapes = preload("res://scripts/shapes.gd")

const SOIL_COLOR := Color(0.30, 0.22, 0.12)

var axial: Vector2i = Vector2i.ZERO
var block_size: float = 17.0

## Miner-seconds put in so far. Several miners on one block share the
## work, the same way builders share a cell.
var mine_progress: float = 0.0
var marked_for_mining: bool = false
var miners: Array = []

## True only for blocks touching open space -- you can't mark a block
## buried behind other soil, because nothing could reach it.
var is_edge: bool = false

var marker: Polygon2D
var progress_label: Label

func _ready() -> void:
	add_to_group("soil_blocks")
	block_size = GameConfig.hive_cell_size
	# oversized so adjacent blocks overlap generously and no seam or
	# background colour shows between them at any zoom -- soil should read
	# as one continuous mass of earth, not a tiled grid
	polygon = Shapes.hexagon_points(block_size * 1.15)
	color = SOIL_COLOR

	# hatched marker shown once you've flagged this block for digging
	marker = Polygon2D.new()
	marker.polygon = Shapes.hexagon_points(block_size * 0.55)
	marker.color = Color(0.95, 0.75, 0.25, 0.9)
	marker.visible = false
	add_child(marker)

	progress_label = Label.new()
	progress_label.position = Vector2(-block_size, -8)
	progress_label.add_theme_font_size_override("font_size", 9)
	add_child(progress_label)

func setup(hex: Vector2i) -> void:
	axial = hex

## Marking and unmarking is just a change of intent, so the digging
## already done is kept. It used to be thrown away on unmark, which meant
## a stray click on a half-dug block -- or toggling one off and on to
## reprioritise -- silently reset it to 0% and wasted every miner-second
## spent on it.
func set_marked(value: bool) -> void:
	marked_for_mining = value
	marker.visible = value
	_refresh()

func claim_miner(bee: Node2D) -> void:
	if not miners.has(bee):
		miners.append(bee)

func release_miner(bee: Node2D) -> void:
	miners.erase(bee)

## Called once per frame by each miner working here, so contributions add
## up. Returns true when the block is finished and should be removed.
func add_mine_progress(delta: float) -> bool:
	if not marked_for_mining:
		return false
	mine_progress += delta
	_refresh()
	return mine_progress >= GameConfig.block_mine_time

func mine_fraction() -> float:
	return clamp(mine_progress / max(0.001, GameConfig.block_mine_time), 0.0, 1.0)

func _refresh() -> void:
	if not marked_for_mining:
		# an unmarked block that has been partly dug still shows how far
		# it got, so the work isn't invisible
		progress_label.text = "%d%%" % int(mine_fraction() * 100.0) if mine_progress > 0.0 else ""
		color = SOIL_COLOR.lerp(Color(0.55, 0.45, 0.28), mine_fraction())
		return
	progress_label.text = "%d%%" % int(mine_fraction() * 100.0)
	# lightens as it's dug away
	color = SOIL_COLOR.lerp(Color(0.55, 0.45, 0.28), mine_fraction())
