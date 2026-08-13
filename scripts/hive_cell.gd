extends Polygon2D
## A single hexagonal comb cell inside the hive.
##
## A cell holds exactly one thing at a time:
##   ""       -- empty
##   "nectar" -- stored nectar, up to `capacity`
##   "pollen" -- stored pollen, up to `capacity`
##   "honey"  -- nectar/enzyme mix a honey maker has spat in, drying out
##               (see `ripen_progress`) and only usable once it's honey
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
##
## Bees load and unload from one of the six walls rather than from the
## middle, so no more than six can work a cell at once -- see
## `claim_slot`.

const Shapes = preload("res://scripts/shapes.gd")

const EMPTY_COLOR := Color(0.85, 0.78, 0.55)
const NECTAR_COLOR := Color(0.95, 0.7, 0.15)
const POLLEN_COLOR := Color(0.4, 0.35, 0.8)
const HONEY_WET_COLOR := Color(0.78, 0.55, 0.18)
const HONEY_COLOR := Color(0.85, 0.42, 0.05)
const BROOD_COLOR := Color(0.9, 0.9, 0.85)
const CORPSE_COLOR := Color(0.34, 0.30, 0.30)
const JELLY_COLOR := Color(0.97, 0.94, 0.82)
const GYNE_BROOD_COLOR := Color(0.98, 0.80, 0.35)
const SITE_COLOR := Color(0.42, 0.34, 0.16)

var content_type: String = ""
var amount: float = 0.0
var capacity: float = 200.0
var brood_progress: float = 0.0
var being_tended: bool = false

## Seconds of development this larva still has food for. Brood does not
## develop at all while this is zero -- a nurse (or the queen) has to
## come and drop pollen plus nectar or honey in to top it back up. This
## is what makes nursing a real, ongoing job rather than a speed bonus.
var brood_fed_seconds: float = 0.0
## How long this larva has gone with nothing at all in it. Past
## `larva_death_seconds` it dies and the cell holds a body instead.
var unfed_seconds: float = 0.0
## Set to true by whichever feed was last given, so the readout can say
## whether the larva is on honey or on nectar.
var fed_on_honey: bool = false

## Architect-seconds spent clearing a dead larva out of this cell.
var clean_progress: float = 0.0

## Is the larva in here being raised as a gyne -- a future queen? Gynes
## take several times as long to develop and can only be fed on royal
## jelly, pollen and honey, so this changes what the cell needs from the
## moment the egg goes in.
var brood_is_gyne: bool = false

## Honey drying. A honey maker fans its wings over the cell to drive the
## water off; `ripen_progress` counts bee-seconds of fanning, and the
## contents only count as real honey once it reaches honey_ripen_time.
var ripen_progress: float = 0.0
var being_fanned: bool = false

## Building state. Cells the hive starts with are already finished.
var is_built: bool = true
var build_progress: float = 0.0
var builders: Array = []

## "" means the cell takes whatever is going. Otherwise it only accepts
## the named thing: "nectar", "pollen", "honey", or "brood" for a nursery
## cell that stores eggs rather than stores.
var designated_type: String = ""

## Priority tier within the nursery zone: 0 low, 1 medium, 2 high. Only
## meaningful while this is a brood cell. The queen shares her eggs
## between the tiers in proportion to the weights in GameConfig, so this
## is how you set the mix of roles the colony produces without having to
## micromanage each cell in turn.
enum Priority { LOW, MEDIUM, HIGH }
var nursery_priority: int = Priority.MEDIUM

## A closed cell is sealed: nothing can be put in and nothing taken out.
## This is how you set honey aside for winter rather than watching the
## colony drink it the moment it ripens.
var is_closed: bool = false
## Set from the honey popup's "Fill then close". The cell refuses
## withdrawals from the moment it is set, so it can actually reach the
## top instead of being sipped from as fast as it fills, and closes
## itself once full.
var fill_then_close: bool = false

## Set from the cell popup's "Empty cell" controls. While true the cell
## refuses every new deposit, so foragers stop cramming nectar into every
## spare pot and leave room for pollen and brood. Designating the cell to
## a resource clears it again.
var keep_empty: bool = false
## The player has asked for the contents to be cleared out. Builders pick
## this up the same way they clear a re-designated cell. `evict_mode`
## says where it goes: "move" into another cell, or "discard", which
## means a builder physically carries it out of the hive and dumps it
## rather than it evaporating the moment you click.
var evict_requested: bool = false
var evict_mode: String = "move"

## Which role a bee raised in this cell takes when it emerges.
## -1 means "whatever the colony default is". Set from the cell popup,
## along with the sub-mode that role needs (a forager's focus, whether a
## miner starts with automine on).
var hatch_role: int = -1
var hatch_focus: String = "nectar"
var hatch_automine: bool = false
## Set from the cell popup: the queen lays a gyne into this cell rather
## than a worker. Costs her far more pollen and takes several times as
## long to raise, so it's a deliberate choice per cell.
var hatch_gyne: bool = false
## When false the role applies to the next bee only and then clears, so a
## one-off choice doesn't quietly govern the cell forever. The popup's
## "Keep for every bee" button pins it.
var hatch_role_locked: bool = false

var axial: Vector2i = Vector2i.ZERO

var cell_size: float = 17.0
var info_label: Label
var outline: Line2D
var designation_ring: Line2D
var selection_ring: Line2D
var selected: bool = false
## Drawn on top of the cell body, sized to how full the cell is, so you
## can read the state of the whole comb at a glance instead of squinting
## at the numbers on each one. See `_refresh`.
var fill_shape: Polygon2D
## Shown only while the nursery window is open: a coloured halo marking
## this as a zone cell, in the colour of the role it raises.
var zone_glow: Line2D
## A small seal drawn over a closed cell.
var closed_mark: Line2D

## One working position per wall. A bee claims a slot before it walks
## over, and gives it up when it leaves, so bees never stand on top of
## each other while loading or unloading.
var slot_users: Array = [null, null, null, null, null, null]

func _ready() -> void:
	add_to_group("hive_cells")
	capacity = GameConfig.cell_capacity
	cell_size = GameConfig.hive_cell_size

	polygon = Shapes.hexagon_points(cell_size)
	color = EMPTY_COLOR

	# The body is drawn washed out and this sits on top at full strength,
	# scaled to the contents -- so a cell with 20 nectar in it reads as
	# obviously different from one with 200 without opening anything.
	fill_shape = Polygon2D.new()
	fill_shape.polygon = Shapes.hexagon_points(cell_size)
	fill_shape.visible = false
	add_child(fill_shape)

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

	# Shown while the cell is part of a multi-cell selection, so it's
	# obvious what the popup's buttons are about to act on.
	selection_ring = Line2D.new()
	_set_outline_points(selection_ring, cell_size + 2.0)
	selection_ring.width = 2.5
	selection_ring.default_color = Color(0.2, 1.0, 0.4, 0.95)
	selection_ring.visible = false
	add_child(selection_ring)

	# Marks this cell as part of the nursery zone while that window is
	# open. Sits outside the selection ring so the two never overlap.
	zone_glow = Line2D.new()
	_set_outline_points(zone_glow, cell_size + 5.0)
	zone_glow.width = 4.0
	zone_glow.default_color = Color(1.0, 1.0, 1.0, 0.9)
	zone_glow.visible = false
	add_child(zone_glow)

	# A bar across a sealed cell, so "closed" is visible on the comb and
	# not only in the popup.
	closed_mark = Line2D.new()
	closed_mark.add_point(Vector2(-cell_size * 0.6, 0))
	closed_mark.add_point(Vector2(cell_size * 0.6, 0))
	closed_mark.width = 3.0
	closed_mark.default_color = Color(0.1, 0.1, 0.12, 0.9)
	closed_mark.visible = false
	add_child(closed_mark)

	info_label = Label.new()
	info_label.position = Vector2(-cell_size, -8)
	info_label.add_theme_font_size_override("font_size", 9)
	add_child(info_label)

func set_selected(value: bool) -> void:
	selected = value
	if selection_ring != null:
		selection_ring.visible = value

## Turns the nursery-zone halo on or off. `glow_colour` is the colour of
## the role this cell raises, so the comb and the ring plot in the
## nursery window use one palette between them.
func set_zone_glow(value: bool, glow_colour: Color = Color.WHITE) -> void:
	if zone_glow == null:
		return
	zone_glow.visible = value
	zone_glow.default_color = glow_colour

func _set_outline_points(line: Line2D, size: float) -> void:
	line.clear_points()
	var pts := Shapes.hexagon_points(size)
	for p in pts:
		line.add_point(p)
	line.add_point(pts[0])   # close the loop

func _process(delta: float) -> void:
	if content_type == "brood":
		_develop_brood(delta)
	elif content_type == "honey":
		if being_fanned:
			ripen_progress = min(ripen_progress + delta, GameConfig.honey_ripen_time)
		being_fanned = false   # honey makers re-assert this each frame
	_refresh()

## A larva burns through whatever its last feed bought it and then simply
## stops. A nurse standing over it still speeds up the time it does have
## (tending_speed_bonus), but no amount of tending moves an unfed larva.
func _develop_brood(delta: float) -> void:
	if brood_fed_seconds > 0.0:
		var rate: float = GameConfig.tending_speed_bonus if being_tended else 1.0
		brood_progress += delta * rate
		brood_fed_seconds = max(0.0, brood_fed_seconds - delta)
		unfed_seconds = 0.0
	else:
		# Nothing left in it. A larva can go hungry for a while, but not
		# indefinitely -- neglect eventually kills it, and the body then
		# blocks the cell until an architect clears it out.
		unfed_seconds += delta
		if unfed_seconds >= GameConfig.larva_death_seconds:
			_larva_dies()
	being_tended = false   # nursery workers re-assert this each frame while tending

func _larva_dies() -> void:
	content_type = "corpse"
	amount = 0.0
	brood_progress = 0.0
	brood_fed_seconds = 0.0
	unfed_seconds = 0.0
	clean_progress = 0.0
	brood_is_gyne = false

# --- working positions --------------------------------------------

## Takes one of the six wall positions for `bee`, or returns -1 when all
## six are already in use. Asking twice just returns the slot the bee
## already holds.
func claim_slot(bee: Node2D) -> int:
	for i in range(6):
		if slot_users[i] == bee:
			return i
	for i in range(6):
		var holder = slot_users[i]
		if holder == null or not is_instance_valid(holder):
			slot_users[i] = bee
			return i
	return -1

func release_slot(bee: Node2D) -> void:
	for i in range(6):
		if slot_users[i] == bee:
			slot_users[i] = null

## Where a bee holding slot `index` should stand: the midpoint of that
## wall, nudged a little outside the hexagon so the bee sits against the
## cell rather than on top of its contents.
func slot_position(index: int) -> Vector2:
	if index < 0:
		return position
	var midpoints := Shapes.hexagon_edge_midpoints(cell_size)
	var offset: Vector2 = midpoints[index % 6]
	return position + offset * 1.35

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

## Honey cells hold their own amount, which can be tuned separately from
## the raw-store cells.
func capacity_for(resource_type: String) -> float:
	match resource_type:
		"honey":
			return GameConfig.honey_cell_capacity
		"jelly":
			return GameConfig.jelly_cell_capacity
		_:
			return GameConfig.cell_capacity

func accepts(resource_type: String) -> bool:
	if not is_built:
		return false
	if content_type == "corpse":
		return false   # blocked until an architect clears it
	# A sealed cell is out of circulation entirely. Cells filling towards
	# a close still accept -- that's the point of them.
	if is_closed:
		return false
	# A cell the player has asked to be kept clear takes nothing at all
	# until they designate it to something.
	if keep_empty:
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
	if content_type == "brood" or content_type == "corpse":
		return 0.0
	if not accepts(resource_type):
		return 0.0
	if content_type == "":
		return capacity_for(resource_type)
	if content_type == resource_type:
		return max(0.0, capacity_for(resource_type) - amount)
	return 0.0

## True when the contents need carrying out: either the player has pinned
## the cell to one resource but it still holds something else, or they've
## asked outright for it to be emptied into another cell.
func needs_eviction() -> bool:
	if not is_built:
		return false
	# A body isn't cargo -- clearing it is its own job (needs_cleaning),
	# because it ends up thrown away rather than moved to another cell.
	if content_type == "" or content_type == "brood" or content_type == "corpse":
		return false
	if evict_requested:
		return true
	if designated_type == "":
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
	if resource_type == "honey":
		# fresh mix is wet: topping a drying cell up sets it back
		if content_type == "honey":
			ripen_progress *= GameConfig.honey_rewet_factor
		else:
			ripen_progress = 0.0
	content_type = resource_type
	capacity = capacity_for(resource_type)
	amount += added
	# "Fill then close" seals itself the moment it tops out, so you don't
	# have to be watching the cell at the right second to catch it.
	if fill_then_close and amount >= capacity - 0.001:
		fill_then_close = false
		is_closed = true
	return added

## Removes up to `requested`, returns how much came out.
func take_resource(resource_type: String, requested: float) -> float:
	if content_type != resource_type:
		return 0.0
	# Sealed, or being filled towards a seal. Emptying the cell on the
	# player's own instruction still gets through -- otherwise a closed
	# cell could never be opened up and cleared again.
	if (is_closed or fill_then_close) and not evict_requested:
		return 0.0
	var taken: float = min(requested, amount)
	amount -= taken
	if amount <= 0.001:
		content_type = ""
		amount = 0.0
		ripen_progress = 0.0
		evict_requested = false
		evict_mode = "move"
	return taken

## Can anything actually be drawn out of here right now? The hive's
## find_* functions check this before sending a bee, otherwise a hungry
## bee walks all the way to a sealed honey cell, gets nothing, and walks
## back to ask again -- forever.
func can_withdraw() -> bool:
	return not is_closed and not fill_then_close

## Opens a sealed cell back up. Also cancels a pending fill-then-close,
## so one button undoes either state.
func set_closed(value: bool) -> void:
	is_closed = value
	if not value:
		fill_then_close = false

func set_fill_then_close(value: bool) -> void:
	fill_then_close = value
	if value:
		is_closed = false   # it has to be able to take deposits to fill

## How full the cell is, 0 to 1, for the fill shading. Brood reports its
## development instead, which is the equivalent "how far along is this".
func fill_fraction() -> float:
	if content_type == "brood":
		return clamp(brood_progress / max(0.001, develop_time()), 0.0, 1.0)
	if content_type == "" or content_type == "corpse":
		return 0.0
	return clamp(amount / max(0.001, capacity_for(content_type)), 0.0, 1.0)

func set_designation(resource_type: String) -> void:
	designated_type = resource_type
	if resource_type != "":
		# choosing what a cell is for overrides "leave it empty"
		keep_empty = false

# --- honey ---------------------------------------------------------

func is_ripe_honey() -> bool:
	return content_type == "honey" and ripen_progress >= GameConfig.honey_ripen_time

## Honey makers fan cells that still hold wet mix.
func needs_fanning() -> bool:
	return content_type == "honey" and amount > 0.0 and not is_ripe_honey()

func ripen_fraction() -> float:
	return clamp(ripen_progress / max(0.001, GameConfig.honey_ripen_time), 0.0, 1.0)

# --- brood ---------------------------------------------------------

func start_brood(as_gyne: bool = false) -> void:
	content_type = "brood"
	amount = 0.0
	brood_progress = 0.0
	brood_fed_seconds = 0.0
	unfed_seconds = 0.0
	fed_on_honey = false
	brood_is_gyne = as_gyne

## How long this larva needs in total. A gyne takes several times as long
## as a worker, which is what makes raising one a commitment rather than
## a decision.
func develop_time() -> float:
	if brood_is_gyne:
		return GameConfig.brood_develop_time * GameConfig.gyne_develop_multiplier
	return GameConfig.brood_develop_time

## Called by a nurse that has just dropped food in. `seconds` is what the
## feed buys; feeds don't stack up indefinitely, they just top the larva
## back to a full feed's worth.
func feed_brood(seconds: float, on_honey: bool) -> void:
	brood_fed_seconds = max(brood_fed_seconds, seconds)
	fed_on_honey = on_honey

## True when the larva is running out of food and a nurse should visit.
func needs_feeding() -> bool:
	return content_type == "brood" and brood_fed_seconds < GameConfig.brood_feed_threshold

## Seconds this larva has left before it starves, for the readout.
func seconds_until_death() -> float:
	if content_type != "brood":
		return 0.0
	return max(0.0, GameConfig.larva_death_seconds - unfed_seconds)

# --- clearing a dead larva ------------------------------------------

func needs_cleaning() -> bool:
	return content_type == "corpse"

## Called each frame by every architect working here, so several clearing
## the same cell share the load. Returns true once the body is free to be
## carried away.
func add_clean_progress(delta: float) -> bool:
	if content_type != "corpse":
		return false
	clean_progress += delta
	return clean_progress >= GameConfig.cell_clean_time

func clean_fraction() -> float:
	return clamp(clean_progress / max(0.001, GameConfig.cell_clean_time), 0.0, 1.0)

func brood_ready() -> bool:
	return content_type == "brood" and brood_progress >= develop_time()

func clear_cell() -> void:
	content_type = ""
	amount = 0.0
	brood_progress = 0.0
	brood_fed_seconds = 0.0
	unfed_seconds = 0.0
	clean_progress = 0.0
	brood_is_gyne = false
	ripen_progress = 0.0
	evict_requested = false
	evict_mode = "move"

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
		outline.visible = true
		color = Color(SITE_COLOR.r, SITE_COLOR.g, SITE_COLOR.b, lerp(0.25, 0.75, f))
		designation_ring.visible = false
		fill_shape.visible = false
		closed_mark.visible = false
		info_label.text = "%d%%" % int(f * 100.0)
		return

	polygon = Shapes.hexagon_points(cell_size)
	_set_outline_points(outline, cell_size)
	outline.default_color = Color(0.35, 0.28, 0.12)
	# An empty cell is drawn as flat colour with no rim, so open comb and
	# open floor read as one continuous surface instead of a grid of
	# outlined tiles. Cells with something in them keep their outline.
	outline.visible = content_type != ""
	designation_ring.visible = designated_type != "" or keep_empty
	if keep_empty:
		designation_ring.default_color = Color(0.85, 0.85, 0.9, 0.9)
	elif designated_type == "nectar":
		designation_ring.default_color = Color(1.0, 0.85, 0.3, 0.95)
	elif designated_type == "pollen":
		designation_ring.default_color = Color(0.7, 0.65, 1.0, 0.95)
	elif designated_type == "honey":
		designation_ring.default_color = Color(1.0, 0.55, 0.1, 0.95)
	elif designated_type == "brood":
		designation_ring.default_color = Color(0.6, 1.0, 0.7, 0.95)

	match content_type:
		"nectar":
			color = NECTAR_COLOR
			info_label.text = "N%d" % int(round(amount))
		"pollen":
			color = POLLEN_COLOR
			info_label.text = "P%d" % int(round(amount))
		"jelly":
			color = JELLY_COLOR
			info_label.text = "RJ%d" % int(round(amount))
		"honey":
			color = HONEY_WET_COLOR.lerp(HONEY_COLOR, ripen_fraction())
			if is_ripe_honey():
				info_label.text = "H%d" % int(round(amount))
			else:
				info_label.text = "h%d %d%%" % [int(round(amount)), int(ripen_fraction() * 100.0)]
		"brood":
			color = GYNE_BROOD_COLOR if brood_is_gyne else BROOD_COLOR
			info_label.text = "%s %d%%" % ["gyne" if brood_is_gyne else "egg", int(development_percent())]
			if brood_fed_seconds <= 0.0:
				# a starving larva reddens as it runs out of time, so a
				# neglected nursery is obvious without opening any panels
				var urgency: float = 1.0 - (seconds_until_death() / max(0.001, GameConfig.larva_death_seconds))
				color = BROOD_COLOR.lerp(Color(0.85, 0.25, 0.2), urgency)
				info_label.text += " (%ds)" % int(seconds_until_death())
		"corpse":
			color = CORPSE_COLOR
			info_label.text = "dead %d%%" % int(clean_fraction() * 100.0)
		_:
			color = EMPTY_COLOR
			# an empty cell reserved for something still says so, otherwise
			# you can't tell a reserved cell from an unused one
			if keep_empty:
				info_label.text = "keep"
			elif is_nursery_cell():
				info_label.text = _priority_mark()
			else:
				info_label.text = ""

	_apply_fill_shading()
	closed_mark.visible = is_closed or fill_then_close
	closed_mark.default_color = (
		Color(0.1, 0.1, 0.12, 0.9) if is_closed else Color(0.95, 0.95, 0.4, 0.85)
	)

## An empty nursery cell shows its tier rather than a bare "egg", so the
## shape of the zone is readable straight off the comb.
func _priority_mark() -> String:
	match nursery_priority:
		Priority.HIGH:
			return "egg •••"
		Priority.LOW:
			return "egg •"
		_:
			return "egg ••"

## Draws the cell body washed out and lays a full-strength shape over it
## sized to the contents. Area, not width, tracks the fraction -- a
## half-full cell should look half full, and scaling the width linearly
## would make it look like a quarter.
func _apply_fill_shading() -> void:
	var fraction := fill_fraction()
	if content_type == "" or content_type == "corpse" or fraction <= 0.001:
		fill_shape.visible = false
		return
	fill_shape.visible = true
	fill_shape.color = color
	fill_shape.polygon = Shapes.hexagon_points(cell_size * sqrt(fraction))
	# the body behind it: same hue, drained towards bare wax
	color = EMPTY_COLOR.lerp(color, 0.35)

func development_percent() -> float:
	if content_type != "brood":
		return 0.0
	return min(100.0, 100.0 * brood_progress / max(0.001, develop_time()))
