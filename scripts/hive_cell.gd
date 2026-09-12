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
const Roles = preload("res://scripts/roles.gd")

const EMPTY_COLOR := Color(0.85, 0.78, 0.55)

## The empty-cell resprite: a 32x32 canvas holding a 32-wide, 16-tall
## hex "cup" already alpha-masked to its own outline (exported from the
## Resprite project alongside this file, `wax.cell.empty.resprite`), so a
## plain Sprite2D shows it correctly with no risk of a square corner
## spilling onto a neighbouring cell. Toggled by `Session.use_cell_sprites`
## -- see `_refresh`.
const EMPTY_TEXTURE := preload("res://assets/sprites/environment/wax.cell.empty.png")

## Where the actual hex "floor" -- the silhouette that has to land on the
## grid's own hex, three-sided front wall included -- sits within
## EMPTY_TEXTURE's 32x32 canvas: a 32-wide, 16-tall slice starting 14px
## down. Read straight off the Tileset-properties slice used to export
## `wax.cell.empty.resprite` (Base W 32, Base H 16, Base Y 14). The 14px
## left above the floor is the cup's back wall, drawn there so it
## overlaps whichever cell is behind this one -- see `_ready`'s z_index.
const EMPTY_TEXTURE_BASE_Y := 14.0
const EMPTY_TEXTURE_BASE_H := 16.0

## Fine visual nudge on top of the derived offset below, in screen pixels
## (negative = up). This stays separate from the export measurements so a
## future resprite export cannot silently undo an alignment tuned by eye.
const EMPTY_SPRITE_Y_NUDGE := -1.0
## Rings only, not the sprite: EMPTY_SILHOUETTE was measured two pixels
## above where the drawn cup reads, so every ring built from it sat high
## on the art (Dave, 8 Sep 2026, C-9). Applied in
## _silhouette_point_to_local after the sprite's own arithmetic, so the
## two still cannot drift apart.
const RING_Y_NUDGE := 2.0
## Makes the cup fractionally larger than exact tessellation if a filtering
## seam needs closing. 1.0 keeps the exported sprite at its exact size.
const EMPTY_SPRITE_SCALE_NUDGE := 1.0

## The empty-cell sprite's own outline, in pixels on its 32x32 canvas.
## Measured off EMPTY_TEXTURE's alpha: opaque rows 4..30, a 16px flat top
## edge at y=4 (x=8..23), a 16px flat bottom edge at y=30, and the full
## 32px width held between y=12 and y=22. Eight corners, not six -- the
## cup has vertical sides, which is why a hexagon can never trace it.
## Re-measure this if wax.cell.empty.png is redrawn.
const EMPTY_SILHOUETTE: Array = [
	Vector2(8.0, 4.0), Vector2(24.0, 4.0), Vector2(32.0, 12.0),
	Vector2(32.0, 23.0), Vector2(24.0, 31.0), Vector2(8.0, 31.0),
	Vector2(0.0, 23.0), Vector2(0.0, 12.0),
]

## Nectar is a clear liquid sitting in a yellow wax cell, so it's drawn as
## a pale blue warmed slightly by the wax showing through, rather than a
## flat pale blue on its own. Worked out as a pale-blue base lerped 15%
## towards a wax yellow -- Color(0.72, 0.84, 0.95).lerp(Color(0.9, 0.8, 0.3), 0.15)
## -- and written out as a literal so this stays an ordinary constant like
## every other colour here. Nudge the two source colours or the 0.15 and
## redo the lerp by hand if this needs retuning by eye.
const NECTAR_COLOR := Color(0.747, 0.834, 0.8525)

## Pollen keeps the amber/gold that nectar used to be, nudged a little
## lighter and further towards yellow so the two read as clearly
## different resources sitting side by side.
const POLLEN_COLOR := Color(0.97, 0.78, 0.22)

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

## Comb-worker seconds spent clearing a dead larva out of this cell.
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

## Building state. Cells the hive starts with are already finished.
var is_built: bool = true
var build_progress: float = 0.0
var builders: Array = []

## -1 means "use GameConfig.cell_build_time as normal". Set above zero to
## give this one cell its own build speed without touching the GameConfig
## autoload -- see challenge_runner.gd's queen-built cell in Challenge 1,
## which needs a fast build without leaking that speed into every other
## cell in the hive (or into a save, if building outlasts the Challenge).
var build_time_override: float = -1.0

## Set by whichever of hive.gd/world_building.gd/saving.gd created this
## cell, so _health_factor can reach main.season directly instead of a
## per-frame get_nodes_in_group lookup on the brood-development path.
var main: Node2D = null

func effective_build_time() -> float:
	return build_time_override if build_time_override > 0.0 else GameConfig.cell_build_time

## "" means the cell takes whatever is going. Otherwise it only accepts
## the named thing: "nectar", "pollen", "honey", or "brood" for a nursery
## cell that stores eggs rather than stores.
var designated_type: String = ""
## True only for a player-made reservation. The first automatic deposit also
## assigns designated_type so stores stay tidy, but that temporary assignment
## returns to neutral when the cell is fully emptied.
var designation_is_explicit: bool = false

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
## Cached when the empty-cell sprite is built so its raised cup outline uses
## the same screen-space scale as the sprite itself.
var empty_scale: float = 1.0
## Cached from `Session.use_sprite_hex_grid` in `_ready` -- read once, not
## live, since the hive's whole grid is laid out on Restart Run (see the
## note on that Session field).
var squashed: bool = false
var info_label: Label
var outline: Line2D
var designation_ring: Line2D
var selection_ring: Line2D
var selected: bool = false
## Drawn on top of the cell body, sized to how full the cell is, so you
## can read the state of the whole comb at a glance instead of squinting
## at the numbers on each one. See `_refresh`.
var fill_shape: Polygon2D
## Shown only while the nursery window is open: a coloured glow marking
## this as a zone cell, in the colour of the role it raises.
var zone_glow: Line2D
var zone_halo: Line2D
## The role tag that stands in for the zone glow's colour when
## Session.colour_blind_mode is on -- see set_zone_glow.
var zone_glow_tag: String = ""
## Which silhouette the constant-size rings were last built with. A live
## `Session.use_cell_sprites` toggle re-points them once, in `_refresh`,
## rather than four rings being rebuilt six times a second forever.
var _rings_follow_cup: bool = false
## A small seal drawn over a closed cell.
var closed_mark: Line2D
## The empty-cell resprite (see `EMPTY_TEXTURE`), shown only while the
## cell holds nothing and `Session.use_cell_sprites` is on.
var empty_sprite: Sprite2D

## One working position per wall. A bee claims a slot before it walks
## over, and gives it up when it leaves, so bees never stand on top of
## each other while loading, unloading, or building. An unfinished cell
## cannot hold resources, so builders using these shared slots cannot
## block a forager from depositing.
var slot_users: Array = [null, null, null, null, null, null]

func _ready() -> void:
	add_to_group("hive_cells")
	capacity = GameConfig.cell_capacity
	cell_size = GameConfig.hive_cell_size
	squashed = Session.use_sprite_hex_grid

	# Cells are built one at a time as the comb grows, in whatever order
	# the player or the queen happens to add them, but the resprite's cup
	# wall (see EMPTY_TEXTURE_BASE_Y below) has to paint over the cell
	# behind it -- so draw order needs to run screen-top to screen-bottom
	# regardless of build order. `Shapes.hex_to_pixel`'s y is always a
	# positive multiple of (2r + q), squashed or not, so that alone gives
	# every cell's relative order without caring where comb_centre sits.
	z_index = 2 * axial.y + axial.x

	polygon = Shapes.hexagon_points(cell_size, squashed)
	color = EMPTY_COLOR

	# The empty-cell resprite, shown in place of the flat fill above when
	# `Session.use_cell_sprites` is on -- see `_refresh`. Sized off
	# `hive_cell_spacing` -- the distance the grid actually places cell
	# centres apart -- rather than `hive_cell_size`, which draws the flat
	# hex a touch smaller than that so the plain-colour look gets a
	# grout-line gap. The resprite's whole point is to tessellate edge to
	# edge like real comb, so it needs the full spacing, not the shrunk
	# radius.
	empty_sprite = Sprite2D.new()
	empty_sprite.texture = EMPTY_TEXTURE
	var sprite_size: float = GameConfig.hive_cell_spacing
	empty_scale = (sprite_size * 2.0) / EMPTY_TEXTURE.get_width()
	empty_sprite.scale = Vector2.ONE * empty_scale * EMPTY_SPRITE_SCALE_NUDGE
	# The floor slice sits low in its 32-tall canvas (see
	# EMPTY_TEXTURE_BASE_Y), so shift up until the floor's own centre --
	# not the canvas's -- lands on this cell's actual centre; otherwise
	# the cup reads as floating above (or sunk below) where the hex grid,
	# and every filled-cell fill, actually put this tile.
	var canvas_mid: float = EMPTY_TEXTURE.get_height() * 0.5
	var base_mid: float = EMPTY_TEXTURE_BASE_Y + EMPTY_TEXTURE_BASE_H * 0.5
	empty_sprite.offset = Vector2(
		0.0,
		canvas_mid - base_mid + EMPTY_SPRITE_Y_NUDGE / empty_scale
	)
	empty_sprite.visible = false
	add_child(empty_sprite)

	# The body is drawn washed out and this sits on top at full strength,
	# scaled to the contents -- so a cell with 20 nectar in it reads as
	# obviously different from one with 200 without opening anything.
	fill_shape = Polygon2D.new()
	fill_shape.polygon = Shapes.hexagon_points(cell_size, squashed)
	fill_shape.visible = false
	add_child(fill_shape)

	outline = Line2D.new()
	_apply_outline_points(outline, cell_size)
	outline.width = 1.5
	outline.default_color = Color(0.35, 0.28, 0.12)
	add_child(outline)

	# a second, brighter ring drawn only when the player has pinned this
	# cell to one resource
	designation_ring = Line2D.new()
	_apply_outline_points(designation_ring, cell_size - 3.0)
	designation_ring.width = 2.0
	designation_ring.default_color = Color(1.0, 1.0, 1.0, 0.9)
	designation_ring.visible = false
	add_child(designation_ring)

	# Shown while the cell is part of a multi-cell selection, so it's
	# obvious what the popup's buttons are about to act on.
	selection_ring = Line2D.new()
	_set_selection_ring_points()
	selection_ring.width = 2.5
	selection_ring.default_color = Color(0.2, 1.0, 0.4, 0.95)
	selection_ring.visible = false
	add_child(selection_ring)

	# Marks this cell as part of the nursery zone while that window is
	# open. Two rings rather than one: a wide soft halo outside and a
	# bright thin rim on top of it, which reads as a glow rather than as
	# a drawn outline, and stays legible over any cell contents. Sits
	# outside the selection ring so the two never overlap.
	zone_halo = Line2D.new()
	_apply_outline_points(zone_halo, cell_size + 6.0)
	zone_halo.width = 7.0
	zone_halo.default_color = Color(1.0, 1.0, 1.0, 0.22)
	zone_halo.visible = false
	add_child(zone_halo)

	zone_glow = Line2D.new()
	_apply_outline_points(zone_glow, cell_size + 4.0)
	zone_glow.width = 2.5
	zone_glow.default_color = Color(1.0, 1.0, 1.0, 0.95)
	zone_glow.visible = false
	add_child(zone_glow)
	# The five rings above were all just pointed at the same silhouette;
	# `_refresh` re-points them if the setting changes under them.
	_rings_follow_cup = Session.use_cell_sprites

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

## Which overlay this cell is drawing under, if any. Applied on top of
## its ordinary colour in _refresh, so switching overlays off restores
## the normal view without anything having to be remembered.
var overlay: String = ""

func set_overlay(mode: String) -> void:
	overlay = mode

## The colour this cell should take under the current overlay, and the
## short tag that goes with it. Returns an empty tag when the overlay is
## off or doesn't apply to this cell.
func _overlay_colour() -> Array:
	match overlay:
		"contents":
			match content_type:
				"nectar": return [NECTAR_COLOR, "n"]
				"pollen": return [POLLEN_COLOR, "p"]
				"honey": return [HONEY_COLOR, "h"]
				"jelly": return [JELLY_COLOR, "j"]
				"brood": return [GYNE_BROOD_COLOR if brood_is_gyne else BROOD_COLOR, "e"]
				"corpse": return [CORPSE_COLOR, "x"]
			return [Color(0.30, 0.30, 0.32), ""]
		"fill":
			# One scale from empty to full, so a glance says where the
			# spare room is -- the question comb overlays are best at.
			var f := fill_fraction()
			if content_type == "":
				return [Color(0.22, 0.26, 0.30), ""]
			return [Color(0.25, 0.30, 0.35).lerp(Color(0.35, 1.0, 0.55), f), "%d" % int(f * 9.0)]
		"role":
			if not is_nursery_cell():
				return [Color(0.24, 0.24, 0.26), ""]
			if hatch_gyne:
				return [GYNE_BROOD_COLOR, "G"]
			if hatch_role < 0:
				return [Color(0.62, 0.62, 0.66), "?"]
			return [Roles.colour_for(hatch_role, hatch_focus), Roles.tag_for_key(Roles.count_key(hatch_role, hatch_focus))]
		"reserved":
			if keep_empty:
				return [Color(0.75, 0.75, 0.80), "-"]
			match designated_type:
				"nectar": return [NECTAR_COLOR, "n"]
				"pollen": return [POLLEN_COLOR, "p"]
				"honey": return [HONEY_COLOR, "h"]
				"jelly": return [JELLY_COLOR, "j"]
				"brood": return [Color(0.6, 1.0, 0.7), "e"]
			return [Color(0.26, 0.26, 0.28), ""]
	return []

func set_selected(value: bool) -> void:
	selected = value
	if selection_ring != null:
		selection_ring.visible = value

## Turns the nursery-zone halo on or off. `glow_colour` is the colour of
## the role this cell raises, so the comb and the ring plot in the
## nursery window use one palette between them. `tag` is the same role
## as a short piece of text (see roles.gd::tag_for_key) -- the glow was
## the one colour-only spot debug_panel.gd's colour-blind tooltip
## promised and hive_cell.gd didn't yet deliver; the ring, the reserved-
## cell ring and the comb overlays above all already spell theirs out.
func set_zone_glow(value: bool, glow_colour: Color = Color.WHITE, tag: String = "") -> void:
	if zone_glow == null or zone_halo == null:
		return
	zone_glow.visible = value
	zone_halo.visible = value
	zone_glow.default_color = Color(glow_colour.r, glow_colour.g, glow_colour.b, 0.95)
	zone_halo.default_color = Color(glow_colour.r, glow_colour.g, glow_colour.b, 0.28)
	zone_glow_tag = tag if value else ""
	if Session.colour_blind_mode:
		_refresh()

func _set_outline_points(line: Line2D, size: float) -> void:
	line.clear_points()
	var pts := Shapes.hexagon_points(size, squashed)
	for p in pts:
		line.add_point(p)
	line.add_point(pts[0])   # close the loop

## Converts one point of EMPTY_SILHOUETTE (in EMPTY_TEXTURE's own pixel
## space) into this cell's local space, using exactly the arithmetic
## `_ready()` uses to place `empty_sprite` -- so a ring built from this can
## never drift away from the sprite it is meant to trace.
func _silhouette_point_to_local(p: Vector2) -> Vector2:
	var s: float = empty_scale * EMPTY_SPRITE_SCALE_NUDGE
	var base_mid: float = EMPTY_TEXTURE_BASE_Y + EMPTY_TEXTURE_BASE_H * 0.5
	return Vector2(
		(p.x - EMPTY_TEXTURE.get_width() * 0.5) * s,
		(p.y - base_mid) * s + EMPTY_SPRITE_Y_NUDGE + RING_Y_NUDGE
	)

## Cell art's cup sprite has vertical sides and a flat top and bottom, not
## a hexagon -- so this walks EMPTY_SILHOUETTE, the shape measured off the
## sprite's own alpha, rather than nudging hexagon corners. Reached only
## via `_apply_outline_points`.
func _set_outline_points_cup(line: Line2D, size: float) -> void:
	line.clear_points()
	var ring_scale := size / cell_size
	var pts: Array = []
	for p in EMPTY_SILHOUETTE:
		pts.append(_silhouette_point_to_local(p) * ring_scale)
	for p in pts:
		line.add_point(p)
	line.add_point(pts[0])   # close the loop

## The single place any ring decides which silhouette it traces. Every
## ring on the cell goes through here, so the four highlight rings and
## the base outline can never disagree with each other about whether the
## cup sprite is being drawn -- which is exactly how the base outline,
## the designation ring and the two zone rings came to cut through the
## back wall while the selection ring alone traced it.
func _apply_outline_points(line: Line2D, size: float) -> void:
	if line == null:
		return
	if Session.use_cell_sprites:
		_set_outline_points_cup(line, size)
	else:
		_set_outline_points(line, size)

func _set_selection_ring_points() -> void:
	_apply_outline_points(selection_ring, cell_size + 2.0)

## How often a cell redraws itself. Six times a second, not sixty.
##
## _refresh rebuilds this cell's hexagon polygon, its outline points and
## its label text. That was running for every cell every frame, so a
## grown hive was doing several hundred polygon rebuilds a frame to draw
## a picture that changes about as fast as a person can read it. It is
## also the reason the choppiness got worse as a colony grew.
##
## Presentation only, and skipped entirely when the comb is not on
## screen. Everything above this line -- brood developing, honey
## ripening, the tended flag workers re-assert -- runs every frame
## regardless of whether anyone is looking, which is the rule this
## project keeps: culling may skip presentation, never simulation.
const REFRESHES_PER_SECOND := 6.0
var refresh_timer: float = 0.0

func _process(delta: float) -> void:
	Perf.begin("cells")
	if content_type == "brood":
		_develop_brood(delta)

	# `is_visible_in_tree` covers the view switch for free: main.gd hides
	# whichever root is not being looked at, so this is false for every
	# cell in the hive while the player is out in the meadow.
	if not is_visible_in_tree():
		Perf.end("cells")
		return
	refresh_timer -= delta
	if refresh_timer > 0.0:
		Perf.end("cells")
		return
	# Staggered, so a hive's worth of cells doesn't all redraw on the
	# same frame and produce the hitch this was meant to remove.
	refresh_timer = (1.0 / REFRESHES_PER_SECOND) * randf_range(0.85, 1.15)
	_refresh()
	Perf.end("cells")

## A larva burns through whatever its last feed bought it and then simply
## stops. A nurse standing over it still speeds up the time it does have
## (tending_speed_bonus), but no amount of tending moves an unfed larva.
func _develop_brood(delta: float) -> void:
	if brood_fed_seconds > 0.0:
		var rate: float = GameConfig.tending_speed_bonus if being_tended else 1.0
		# Pathogens slow development. This is where neglecting to clear
		# dead larvae actually costs you: not immediately, and not
		# visibly, but the whole nursery runs slower until it's dealt
		# with.
		rate *= _health_factor()
		brood_progress += delta * rate
		brood_fed_seconds = max(0.0, brood_fed_seconds - delta)
		unfed_seconds = 0.0
	else:
		# Nothing left in it. A larva can go hungry for a while, but not
		# indefinitely -- neglect eventually kills it, and the body then
		# blocks the cell until a comb worker clears it out.
		unfed_seconds += delta
		if unfed_seconds >= GameConfig.larva_death_seconds:
			_larva_dies()
	being_tended = false   # nursery workers re-assert this each frame while tending

## The colony's brood-rate multiplier, from the season/disease system.
func _health_factor() -> float:
	if main == null or not is_instance_valid(main):
		return 1.0
	var season: Node2D = main.season
	if season == null or not is_instance_valid(season):
		return 1.0
	return season.brood_rate()

func _larva_dies() -> void:
	content_type = "corpse"
	amount = 0.0
	brood_progress = 0.0
	brood_fed_seconds = 0.0
	unfed_seconds = 0.0
	clean_progress = 0.0
	brood_is_gyne = false
	DiagnosticLog.count_larval_death()
	_invalidate_hive_index()

## The single call-through every content_type/is_built mutator below uses
## to tell the hive's cell-content buckets (hive.gd's `_content_index`)
## they're stale. `main` is set by hive.gd/world_building.gd the moment a
## cell is created -- see hive.gd's `_start_site_at`.
func _invalidate_hive_index() -> void:
	if main != null and is_instance_valid(main) and main.hive != null:
		main.hive.invalidate_index()
	bump_display_epoch()

## Bumped on every discrete change to a field the cell popup shows
## (hud.gd::_refresh_cell_popup) -- content/build/ripe changes through
## _invalidate_hive_index above, plus close/fill-close here and the
## keep-empty/priority/hatch-role fields orders_zones.gd writes directly.
## hud.gd polls this instead of rebuilding the popup every frame; the
## ticking fields (build/ripen/development percent, countdowns) stay on
## an explicit cadence rather than this epoch, since they change whether
## or not a discrete field does.
var display_epoch: int = 0

func bump_display_epoch() -> void:
	display_epoch += 1

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

## Whether another bee can reserve one of this cell's walls. Invalid
## holders are treated as free here, just as `claim_slot` treats them.
func has_free_slot() -> bool:
	for holder in slot_users:
		if holder == null or not is_instance_valid(holder):
			return true
	return false

## Where a bee holding slot `index` should stand: the midpoint of that
## wall, nudged a little outside the hexagon so the bee sits against the
## cell rather than on top of its contents.
func slot_position(index: int) -> Vector2:
	if index < 0:
		return position
	var midpoints := Shapes.hexagon_edge_midpoints(cell_size, squashed)
	var edge_offset: Vector2 = midpoints[index % 6]
	return position + edge_offset * 1.35

# --- building -----------------------------------------------------

func start_as_site() -> void:
	is_built = false
	build_progress = 0.0
	_invalidate_hive_index()

func claim_builder(bee: Node2D) -> void:
	if not builders.has(bee):
		builders.append(bee)

func release_builder(bee: Node2D) -> void:
	builders.erase(bee)
	release_slot(bee)

## Called once per frame by every builder working here, so contributions
## from several bees simply add up.
func add_build_progress(delta: float) -> void:
	if is_built:
		return
	build_progress += delta
	if build_progress >= effective_build_time():
		build_progress = effective_build_time()
		is_built = true
		builders.clear()
		DiagnosticLog.count_cell_completed()
		_invalidate_hive_index()

func build_fraction() -> float:
	return clamp(build_progress / max(0.001, effective_build_time()), 0.0, 1.0)

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
		return false   # blocked until a comb worker clears it
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
	var was_content_type: String = content_type
	var was_ripe: bool = is_ripe_honey()
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
	# A fresh deposit changes which content-type/ripe-honey bucket this
	# cell belongs in either by switching content_type outright, or (for
	# honey) by rewetting it out of the ripe_honey bucket.
	if was_content_type != content_type or was_ripe != is_ripe_honey():
		_invalidate_hive_index()
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
		if not designation_is_explicit:
			designated_type = ""
		if evict_requested:
			DiagnosticLog.count_cell_evicted()
		evict_requested = false
		evict_mode = "move"
		_invalidate_hive_index()
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
	bump_display_epoch()

func set_fill_then_close(value: bool) -> void:
	fill_then_close = value
	if value:
		is_closed = false   # it has to be able to take deposits to fill
	bump_display_epoch()

## How full the cell is, 0 to 1, for the fill shading. Brood reports its
## development instead, which is the equivalent "how far along is this".
func fill_fraction() -> float:
	if content_type == "brood":
		return clamp(brood_progress / max(0.001, develop_time()), 0.0, 1.0)
	if content_type == "" or content_type == "corpse":
		return 0.0
	return clamp(amount / max(0.001, capacity_for(content_type)), 0.0, 1.0)

func set_designation(resource_type: String, explicit: bool = true) -> void:
	designated_type = resource_type
	designation_is_explicit = explicit and resource_type != ""
	if resource_type != "":
		# choosing what a cell is for overrides "leave it empty"
		keep_empty = false
	bump_display_epoch()

# --- honey ---------------------------------------------------------

func is_ripe_honey() -> bool:
	return content_type == "honey" and ripen_progress >= GameConfig.honey_ripen_time

## Honey makers fan cells that still hold wet mix.
func needs_fanning() -> bool:
	return content_type == "honey" and amount > 0.0 and not is_ripe_honey()

## Called once per frame by every bee fanning this cell, so contributions
## from several bees simply add up -- same pattern as add_build_progress.
func add_fanning_progress(delta: float) -> void:
	if content_type != "honey":
		return
	var was_ripe: bool = is_ripe_honey()
	ripen_progress = min(ripen_progress + delta, GameConfig.honey_ripen_time)
	if is_ripe_honey() and not was_ripe:
		DiagnosticLog.count_cell_ripened()
		_invalidate_hive_index()

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
	_invalidate_hive_index()

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

## Called each frame by every comb worker working here, so several clearing
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
	_invalidate_hive_index()

# --- display ------------------------------------------------------

## Returns the shared outline hue for a stored resource or designation.
## B1's resource catalogue will become the home for this mapping; keep it
## together here until then so the ring and the contents outline cannot drift.
func _resource_outline_colour(resource_type: String) -> Color:
	match resource_type:
		"nectar":
			return Color(1.0, 0.85, 0.3)
		"pollen":
			return Color(0.7, 0.65, 1.0)
		"honey":
			return Color(1.0, 0.55, 0.1)
		"brood":
			return Color(0.6, 1.0, 0.7)
	# A later content kind without its own outline colour remains visible
	# instead of losing its rim altogether.
	return Color(0.35, 0.28, 0.12)

func _refresh() -> void:
	# Independent of everything below -- see Session.show_cell_contents_text.
	# The text is always computed regardless (cheap, and other logic below
	# doesn't need to know or care whether it's actually shown), only its
	# visibility is gated.
	info_label.visible = Session.show_cell_contents_text
	# `use_cell_sprites` can switch live, so keep every ring in the matching
	# shape alongside the empty-sprite visibility below. Only the toggle
	# itself changes a constant-size ring's points, so they are rebuilt when
	# it flips rather than on all six refreshes a second. The base outline
	# is not in here: it is re-pointed unconditionally below anyway, because
	# an unfinished cell resizes it as it builds.
	if Session.use_cell_sprites != _rings_follow_cup:
		_rings_follow_cup = Session.use_cell_sprites
		_set_selection_ring_points()
		_apply_outline_points(designation_ring, cell_size - 3.0)
		_apply_outline_points(zone_halo, cell_size + 6.0)
		_apply_outline_points(zone_glow, cell_size + 4.0)
	if not is_built:
		# an unfinished cell grows outwards from a stub as it's drawn, so
		# you can see at a glance how far along it is
		var f := build_fraction()
		var drawn_size: float = lerp(cell_size * 0.35, cell_size, f)
		polygon = Shapes.hexagon_points(drawn_size, squashed)
		# The one ring that stays flat whatever the setting says: a site
		# draws no cup sprite at any size (`empty_sprite.visible = false`
		# below), and the cup's raised back wall is an absolute offset, so
		# on a 35%-size stub it would tower over the shape it outlines.
		_set_outline_points(outline, drawn_size)
		outline.default_color = Color(0.6, 0.5, 0.25, 0.9)
		outline.visible = true
		color = Color(SITE_COLOR.r, SITE_COLOR.g, SITE_COLOR.b, lerp(0.25, 0.75, f))
		empty_sprite.visible = false
		designation_ring.visible = false
		fill_shape.visible = false
		closed_mark.visible = false
		info_label.text = "%d%%" % int(f * 100.0)
		return

	polygon = Shapes.hexagon_points(cell_size, squashed)
	_apply_outline_points(outline, cell_size)
	outline.default_color = _resource_outline_colour(content_type)
	# An empty cell is drawn as flat colour with no rim, so open comb and
	# open floor read as one continuous surface instead of a grid of
	# outlined tiles. Cells with something in them keep their outline.
	outline.visible = content_type != ""
	designation_ring.visible = designated_type != "" or keep_empty
	if keep_empty:
		designation_ring.default_color = Color(0.85, 0.85, 0.9, 0.9)
	else:
		var designation_colour := _resource_outline_colour(designated_type)
		designation_ring.default_color = Color(
			designation_colour.r, designation_colour.g, designation_colour.b, 0.95
		)

	empty_sprite.visible = false
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
			# The resprite stands in for the flat fill colour when the
			# setting's on; either way EMPTY_COLOR stays set underneath so
			# switching it off mid-run needs nothing else touched.
			color = EMPTY_COLOR
			empty_sprite.visible = Session.use_cell_sprites
			# an empty cell reserved for something still says so, otherwise
			# you can't tell a reserved cell from an unused one
			if keep_empty:
				info_label.text = "keep"
			elif is_nursery_cell():
				info_label.text = _priority_mark()
			else:
				info_label.text = ""

	# The designation ring is colour-only: a cell reserved for pollen and
	# one reserved for honey are the same shape, same size, same
	# everything but hue. With colour-blind labels on, the reservation is
	# spelled out on the cell instead.
	if Session.colour_blind_mode and info_label != null:
		var tag := _designation_tag()
		if tag != "":
			info_label.text = ("%s %s" % [tag, info_label.text]).strip_edges()
		# The zone glow (see set_zone_glow) is a ring drawn outside the cell
		# itself, colour-only in exactly the same way the designation ring
		# above is -- so it gets the same treatment, in brackets so it
		# doesn't read as part of the cell's own contents.
		if zone_glow != null and zone_glow.visible and zone_glow_tag != "":
			info_label.text = ("[%s] %s" % [zone_glow_tag, info_label.text]).strip_edges()

	# An overlay replaces the cell's ordinary colour entirely, so the
	# whole comb reads as one map of one property rather than as its
	# usual mixture. The tag goes on with or without colour-blind mode,
	# because a colour scale alone can't say "which role" precisely.
	var over: Array = _overlay_colour()
	if not over.is_empty():
		color = over[0]
		fill_shape.visible = false
		outline.visible = true
		outline.default_color = Color(0.12, 0.12, 0.14, 0.8)
		info_label.text = str(over[1])
		closed_mark.visible = is_closed or fill_then_close
		return

	_apply_fill_shading()
	closed_mark.visible = is_closed or fill_then_close
	closed_mark.default_color = (
		Color(0.1, 0.1, 0.12, 0.9) if is_closed else Color(0.95, 0.95, 0.4, 0.85)
	)

## A one-character tag for what the cell is reserved for, shown when
## colour-blind labels are on. "·" for an unreserved cell would be noise,
## so that returns nothing.
func _designation_tag() -> String:
	if is_closed:
		return "[X]"
	if fill_then_close:
		return "[>]"
	if keep_empty:
		return "[-]"
	match designated_type:
		"nectar":
			return "[n]"
		"pollen":
			return "[p]"
		"honey":
			return "[h]"
		"jelly":
			return "[j]"
		"brood":
			return "[e]"
	return ""

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
	fill_shape.polygon = Shapes.hexagon_points(cell_size * sqrt(fraction), squashed)
	# the body behind it: same hue, drained towards bare wax
	color = EMPTY_COLOR.lerp(color, 0.35)

func development_percent() -> float:
	if content_type != "brood":
		return 0.0
	return min(100.0, 100.0 * brood_progress / max(0.001, develop_time()))
