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

# --- constants and colours ----------------------------------------

const Shapes = preload("res://scripts/shapes.gd")
const Roles = preload("res://scripts/roles.gd")
const Resources = preload("res://scripts/resources.gd")
const UiTheme = preload("res://scripts/ui_theme.gd")
const SpriteCatalogue = preload("res://scripts/sprite_catalogue.gd")

const EMPTY_COLOR := Color(0.85, 0.78, 0.55)

## The empty-cell cup: frame 0 of the nectar cell sheet (the cup is the base
## layer of `wax_cell_nectar.aseprite`), a 32x32 canvas holding a 32-wide,
## 16-tall hex "cup" already alpha-masked to its own outline, so a plain
## Sprite2D shows it correctly with no risk of a square corner spilling
## onto a neighbouring cell. Sheet, frame size and anchor come from the
## generated catalogue (`tools/sprites.py`, `assets/sprites/SPRITES.md`).
## Toggled by `Session.use_cell_sprites` -- see `_refresh`.
const EMPTY_TEXTURE := SpriteCatalogue.WAX_CELL_NECTAR_SHEET
const EMPTY_FRAME_SIZE := SpriteCatalogue.WAX_CELL_NECTAR_FRAME_SIZE

## SP-7. Every cell sheet `_show_fill_art` can show, as [texture, hframes,
## level bounds]. All share the cup's 32x32 frame and anchor, so swapping
## one for another moves nothing.
const CELL_ART := {
	"nectar": [SpriteCatalogue.WAX_CELL_NECTAR_SHEET, SpriteCatalogue.WAX_CELL_NECTAR_HFRAMES, SpriteCatalogue.WAX_CELL_NECTAR_LEVELS],
	"fermented": [SpriteCatalogue.WAX_CELL_NECTAR_FERMENTED_SHEET, SpriteCatalogue.WAX_CELL_NECTAR_FERMENTED_HFRAMES, SpriteCatalogue.WAX_CELL_NECTAR_FERMENTED_LEVELS],
	"pollen": [SpriteCatalogue.WAX_CELL_POLLEN_SHEET, SpriteCatalogue.WAX_CELL_POLLEN_HFRAMES, SpriteCatalogue.WAX_CELL_POLLEN_LEVELS],
	"honey": [SpriteCatalogue.WAX_CELL_HONEY_SHEET, SpriteCatalogue.WAX_CELL_HONEY_HFRAMES, SpriteCatalogue.WAX_CELL_HONEY_LEVELS],
	"jelly": [SpriteCatalogue.WAX_CELL_ROYAL_JELLY_SHEET, SpriteCatalogue.WAX_CELL_ROYAL_JELLY_HFRAMES, SpriteCatalogue.WAX_CELL_ROYAL_JELLY_LEVELS],
	"bee_bread": [SpriteCatalogue.WAX_CELL_BEE_BREAD_SHEET, SpriteCatalogue.WAX_CELL_BEE_BREAD_HFRAMES, SpriteCatalogue.WAX_CELL_BEE_BREAD_LEVELS],
	"bee_bread_ripe": [SpriteCatalogue.WAX_CELL_BEE_BREAD_RIPE_SHEET, SpriteCatalogue.WAX_CELL_BEE_BREAD_RIPE_HFRAMES, SpriteCatalogue.WAX_CELL_BEE_BREAD_RIPE_LEVELS],
	"larva": [SpriteCatalogue.WAX_CELL_LARVA_SHEET, SpriteCatalogue.WAX_CELL_LARVA_HFRAMES, SpriteCatalogue.WAX_CELL_LARVA_LEVELS],
}

## SP-7. A starving larva's art reddens towards this as it runs out of
## time, as the flat brood colour does without sprites.
const STARVING_ART_TINT := Color(1.0, 0.45, 0.4)

## CT-1. How strongly a cell's contents tint it, from 0 (empty) to
## CONTENT_TONE_MAX (full), in eight steps with how full the cell is.
static func content_tone_strength(fraction: float) -> float:
	if fraction <= 0.0:
		return 0.0
	var step: float = ceil(clampf(fraction, 0.0, 1.0) * 8.0) / 8.0
	return lerpf(CONTENT_TONE_MIN, CONTENT_TONE_MAX, step)

## CT-1. The tint for a cell's art and cap: white at zero strength. At full
## strength it keeps the content colour's hue, with saturation held between
## 0.35 and 0.8 and full value, so multiplying the art by it never dims it.
static func content_tone(base: Color, strength: float) -> Color:
	return Color.WHITE.lerp(Color.from_hsv(base.h, clampf(base.s, 0.35, 0.8), 1.0), strength)

## SP-4. Which sheet and frame a nectar or pollen cell shows at `fraction`
## full, from the catalogue's level bounds (percent, rising): the first level
## whose bound is at least the fill, frame 0 (the empty cup) at nothing.
## Returns the frame index, or -1 for a fill with no art.
static func fill_frame(levels: Array, fraction: float) -> int:
	if fraction <= 0.0:
		return 0
	var percent: float = fraction * 100.0
	for i: int in levels.size():
		if percent <= float(levels[i]) + 0.0001:
			return i + 1
	return levels.size()

## Where the actual hex "floor" -- the silhouette that has to land on the
## grid's own hex, three-sided front wall included -- is centred within
## the 32x32 frame: the table's anchor row (y 22, the middle of the 16-tall
## slice that starts 14px down). The 14px left above the floor is the
## cup's back wall, drawn there so it overlaps whichever cell is behind
## this one -- see `Shapes.hex_draw_depth`.
const EMPTY_FLOOR_MID_Y: float = SpriteCatalogue.WAX_CELL_NECTAR_ANCHOR.y

## Fine visual nudge on top of the derived offset below, in screen pixels
## (negative = up). This stays separate from the export measurements so a
## future resprite export cannot silently undo an alignment tuned by eye.
const EMPTY_SPRITE_Y_NUDGE := -1.0

## Makes the cup fractionally larger than exact tessellation if a filtering
## seam needs closing. 1.0 keeps the exported sprite at its exact size.
const EMPTY_SPRITE_SCALE_NUDGE := 1.0

## The cup's rim -- the bright outline round the top face of the empty
## frame -- in the frame's own pixel space (outer pixel edges). Measured
## 14 Oct 2026 off frame 0 of wax_cell_nectar_sheet.png by printing its
## pixels as a grid: top y 5 (x 9..26), bottom y 21 (x 8..26), left x 1 and
## right x 32 at y 13. A flat-topped hexagon, which every ring on the cell
## traces. Re-measure this if the cup layer of wax_cell_nectar.aseprite is
## redrawn.
const EMPTY_RIM: Array = [
	Vector2(9.0, 5.0), Vector2(26.0, 5.0), Vector2(32.0, 13.0),
	Vector2(26.0, 21.0), Vector2(8.0, 21.0), Vector2(1.0, 13.0),
]

## SP-3. Nectar is the sprite lime (187, 248, 36), exactly.
const NECTAR_COLOR := Color(0.73333, 0.97255, 0.14118)

## NF-2. Nectar left past GameConfig.nectar_ferment_hours turns a murky
## olive, so a fermented cell stands apart from fresh nectar, pollen and
## honey at a glance. Colour-blind mode adds a "sour" tag (see _refresh).
const FERMENTED_NECTAR_COLOR := Color(0.55, 0.68, 0.39)

## RR-11. Nectar nearing its fermenting time shows the midpoint of fresh and
## fermented as a warning. It is still ordinary nectar until it ferments.
const PRE_FERMENTED_NECTAR_COLOR := Color(0.64, 0.83, 0.27)
const PRE_FERMENTED_ART_TINT := Color(0.9, 0.92, 0.78)

## SP-3. Pollen is the sprite orange (255, 123, 0), exactly. Honey is a
## darker amber so every cell content stays 0.10 apart in OKLab
## (tests/test_sp3_content_colours.py).
const POLLEN_COLOR := Color(1.0, 0.48235, 0.0)

const HONEY_WET_COLOR := Color(0.74, 0.45, 0.03)
const HONEY_COLOR := Color(0.57, 0.19, 0.05)
const BROOD_COLOR := Color(0.9, 0.9, 0.85)
const CORPSE_COLOR := Color(0.24, 0.21, 0.14)
const JELLY_COLOR := Color(1.0, 1.0, 0.68)
const GYNE_BROOD_COLOR := Color(1.0, 0.86, 0.31)
const SITE_COLOR := Color(0.42, 0.34, 0.16)

## BB-1. Bee bread in three states: a pale mauve while it is being packed,
## a deep violet once the full cell seals, and a plum when it has ripened.
## Each sits at least 0.10 (OKLab) from every other cell-content colour
## above and from the other two (tests/test_bb1_bee_bread.py checks it), so
## sealed and ripe read apart. Colour-blind mode spells the state out in
## the cell's label. resources.gd's bee_bread row carries BEE_BREAD_COLOR.
const BEE_BREAD_COLOR := Color(0.80, 0.58, 0.84)
const BEE_BREAD_SEALED_COLOR := Color(0.46, 0.34, 0.64)
const BEE_BREAD_RIPE_COLOR := Color(0.74, 0.24, 0.56)

## CT-1. How strongly a cell's contents tint its art and cap: a nearly empty
## cell takes the faintest tone, a full one the strongest, in eight steps (as
## many as the cap sheet has stages). Presentation only, so no GameConfig field.
const CONTENT_TONE_MIN := 0.06
const CONTENT_TONE_MAX := 0.28

# --- cell state ---------------------------------------------------

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

## COL-9. Is the larva in here a drone -- from an unmated queen's egg? A
## drone develops and is fed exactly like a worker; only what hatches
## differs. Never true together with brood_is_gyne.
var brood_is_drone: bool = false

## Honey drying. A honey maker fans its wings over the cell to drive the
## water off; `ripen_progress` counts bee-seconds of fanning, and the
## contents only count as real honey once it reaches honey_ripen_time.
var ripen_progress: float = 0.0

## Session.sim_time at which this cell first took nectar (the age of its
## oldest nectar; topping up keeps it). -1.0 means "not stamped yet".
## Saved per cell (NF-2); a save from before NF-2 restores the stamp at the
## restore time (saving.gd). See nectar_age() and is_fermented().
var nectar_since: float = -1.0

## BB-1. Session.sim_time at which this bee bread cell filled and sealed;
## -1.0 while it is still filling, or holds no bee bread. Saved per cell.
## See is_ripe_bee_bread().
var bee_bread_sealed_at: float = -1.0

## BB-2. What the larva in here has been raised on: Resources.POLLEN from the
## moment the egg goes in, Resources.BEE_BREAD once any feed of bee bread has
## gone in (feed_brood), "" when no larva is being raised. clear_cell() leaves
## it alone, because main.gd's hatch clears the cell before
## world_building.gd::_spawn_hatched_bee reads it to fix the new worker's
## outcome; that spawn resets it. Saved per cell.
var brood_food: String = ""

# --- building state -----------------------------------------------

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

## Zero means "use the normal nectar capacity". Challenge 1 sets this on
## its wax-cell sites so its 150-nectar lesson does not change other modes,
## resources, or the shared GameConfig autoload.
var nectar_capacity_override: float = 0.0

## Set by whichever of hive.gd/world_building.gd/saving.gd created this
## cell, so _health_factor can reach main.season directly instead of a
## per-frame get_nodes_in_group lookup on the brood-development path.
var main: Node2D = null

func effective_build_time() -> float:
	return build_time_override if build_time_override > 0.0 else GameConfig.cell_build_time

# --- designation and orders ---------------------------------------

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
## CT-1. The tone strength `_refresh` last applied, 0 for no tint. The scenario
## assert `cell_tone_strength` (scenario_actions.gd) reads it.
var tone_strength: float = 0.0
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

# --- hatch settings -----------------------------------------------

## Which role a bee raised in this cell takes when it emerges.
## -1 means "whatever the colony default is". Set from the cell popup,
## along with the sub-mode that role needs (a forager's focus, whether a
## miner starts with automine on).
var hatch_role: int = -1
var hatch_focus: String = "nectar"
var hatch_automine: bool = false
## Set from the cell popup: the queen lays a gyne into this cell rather
## than a worker. Costs her far more pollen and takes several times as
## long to raise, so it's a deliberate choice per cell. A cell carries at
## most one mark, so setting it clears hatch_drone.
var hatch_gyne: bool = false:
	set(value):
		hatch_gyne = value
		if value:
			hatch_drone = false
## DR-1. The queen lays a drone into this cell, mated or not, at a worker
## egg's cost. A setting of the cell like hatch_gyne, so it outlasts the
## larva in it; setting it clears hatch_gyne. Saved; false in an older save.
var hatch_drone: bool = false:
	set(value):
		hatch_drone = value
		if value:
			hatch_gyne = false
## PP-5. Set from the cell popup's "Feed first" box once Priority cells is
## owned: nurses choosing a hungry larva take one in a marked cell before any
## other (bee_nursery.gd::choose_brood_cell). A setting of the cell, like
## hatch_gyne, so it outlasts the larva in it. Saved; false in an older save.
var priority_cell: bool = false
## When false the role applies to the next bee only and then clears, so a
## one-off choice doesn't quietly govern the cell forever. The popup's
## "Keep for every bee" button pins it.
var hatch_role_locked: bool = false

# --- layout and display nodes -------------------------------------

var axial: Vector2i = Vector2i.ZERO

var cell_size: float = 17.0
## Cached when the empty-cell sprite is built so its raised cup outline uses
## the same screen-space scale as the sprite itself.
var empty_scale: float = 1.0
## SP-4. "<sheet>:<frame>" of what `empty_sprite` last showed, so `_refresh`
## touches the texture only when the art actually changes.
var _art_key: String = ""
## Cached from `Session.use_sprite_hex_grid` in `_ready` -- read once, not
## live, since the hive's whole grid is laid out on Restart Run (see the
## note on that Session field).
var squashed: bool = false
var info_label: Label
## The last size applied to `info_label`. `_refresh` runs frequently, so a
## live text-scale change only updates the label when its capped size differs.
var _label_font_size: int = 9
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
## The cell art (see `EMPTY_TEXTURE` and `CELL_ART`): the cup, with
## whatever the cell holds drawn in it, while `Session.use_cell_sprites`
## is on.
var empty_sprite: Sprite2D
## SP-7. The wax cap drawn over `empty_sprite`: going on stage by stage
## while bee bread ripens, whole over a cell the player has closed.
var cap_sprite: Sprite2D

# --- slots --------------------------------------------------------

## One working position per wall. A bee claims a slot before it walks
## over, and gives it up when it leaves, so bees never stand on top of
## each other while loading, unloading, or building. An unfinished cell
## cannot hold resources, so builders using these shared slots cannot
## block a forager from depositing.
## How far outside its wall a slot's stand point sits, as a multiple of the
## wall midpoint's offset from the cell centre (see `slot_position`).
const SLOT_REACH := 1.35
const SQUASHED_SLOT_Y_REACH := 1.65

var slot_users: Array = [null, null, null, null, null, null]

# --- setup --------------------------------------------------------

func _ready() -> void:
	add_to_group("hive_cells")
	capacity = capacity_for("nectar")
	cell_size = GameConfig.hive_cell_size
	squashed = Session.use_sprite_hex_grid

	# Cells are built one at a time as the comb grows, in whatever order
	# the player or the queen happens to add them, but the cup's wall (see
	# EMPTY_FLOOR_MID_Y) has to paint over the cell behind it. The shared
	# depth (see Shapes.hex_draw_depth) keeps that order whatever the build order.
	z_index = Shapes.hex_draw_depth(axial)

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
	# Frame 0 of the sheet; the gutter around it is symmetric, so the cup
	# stays centred exactly where the bare 32x32 canvas put it.
	empty_sprite.hframes = SpriteCatalogue.WAX_CELL_NECTAR_HFRAMES
	empty_sprite.vframes = SpriteCatalogue.WAX_CELL_NECTAR_VFRAMES
	empty_sprite.frame = 0
	empty_scale = PixelSprite.hive_scale()
	PixelSprite.apply(empty_sprite, empty_scale * EMPTY_SPRITE_SCALE_NUDGE)
	# The floor slice sits low in its 32-tall canvas (see
	# EMPTY_FLOOR_MID_Y), so shift up until the floor's own centre --
	# not the canvas's -- lands on this cell's actual centre; otherwise
	# the cup reads as floating above (or sunk below) where the hex grid,
	# and every filled-cell fill, actually put this tile.
	var canvas_mid: float = EMPTY_FRAME_SIZE.y * 0.5
	empty_sprite.offset = Vector2(
		0.0,
		canvas_mid - EMPTY_FLOOR_MID_Y + EMPTY_SPRITE_Y_NUDGE / empty_scale
	)
	empty_sprite.visible = false
	add_child(empty_sprite)

	# SP-7. The cap sheet shares the cup's frame and anchor, so it takes
	# the cup's scale and offset and lands exactly over it.
	cap_sprite = Sprite2D.new()
	cap_sprite.texture = SpriteCatalogue.WAX_CELL_SEALED_SHEET
	cap_sprite.hframes = SpriteCatalogue.WAX_CELL_SEALED_HFRAMES
	cap_sprite.vframes = SpriteCatalogue.WAX_CELL_SEALED_VFRAMES
	PixelSprite.apply(cap_sprite, empty_scale * EMPTY_SPRITE_SCALE_NUDGE)
	cap_sprite.offset = empty_sprite.offset
	cap_sprite.visible = false
	add_child(cap_sprite)

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

# --- overlay, selection and rings ---------------------------------

## Which overlay this cell is drawing under, if any. Applied on top of
## its ordinary colour in _refresh, so switching overlays off restores
## the normal view without anything having to be remembered.
var overlay: String = ""

func set_overlay(mode: String) -> void:
	overlay = mode

## The colour this cell should take under the current overlay, and the
## short tag that goes with it. Returns an empty tag when the overlay is
## off or doesn't apply to this cell.
# CQ-R5 shortens this function; until then the early returns stay.
func _overlay_colour() -> Array:
	match overlay:
		"contents":
			match content_type:
				"nectar": return [NECTAR_COLOR, "n"]
				"pollen": return [POLLEN_COLOR, "p"]
				"honey": return [HONEY_COLOR, "h"]
				"jelly": return [JELLY_COLOR, "j"]
				"bee_bread": return [BEE_BREAD_COLOR, "b"]
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
			# DR-1: tagged, in the unset grey. Its own colour is DR-2's to
			# choose: bee.gd's DRONE_COLOUR sits too close to bee bread's.
			if hatch_drone:
				return [Color(0.62, 0.62, 0.66), "D"]
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
				"bee_bread": return [BEE_BREAD_COLOR, "b"]
				"brood": return [Color(0.6, 1.0, 0.7), "e"]
			return [Color(0.26, 0.26, 0.28), ""]
	return []  # gdlint: ignore=max-returns

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
	for p: Variant in pts:
		line.add_point(p)
	line.add_point(pts[0])   # close the loop

## Converts one point of EMPTY_RIM (in the empty frame's own pixel
## space) into this cell's local space, using exactly the arithmetic
## `_ready()` uses to place `empty_sprite` -- so a ring built from this can
## never drift away from the sprite it is meant to trace.
func _silhouette_point_to_local(p: Vector2) -> Vector2:
	var s: float = empty_scale * EMPTY_SPRITE_SCALE_NUDGE
	return Vector2(
		(p.x - EMPTY_FRAME_SIZE.x * 0.5) * s,
		(p.y - EMPTY_FLOOR_MID_Y) * s + EMPTY_SPRITE_Y_NUDGE
	)

## With cell art on every ring traces the cup's rim (EMPTY_RIM), scaled
## about the rim's own centre so the larger zone rings stay centred on it.
## Reached only via `_apply_outline_points`.
func _set_outline_points_cup(line: Line2D, size: float) -> void:
	line.clear_points()
	var ring_scale := size / cell_size
	var local: Array = []
	var centre := Vector2.ZERO
	for p: Vector2 in EMPTY_RIM:
		var q := _silhouette_point_to_local(p)
		local.append(q)
		centre += q
	centre /= float(local.size())
	var pts: Array = []
	for q: Variant in local:
		pts.append(centre + (q - centre) * ring_scale)
	for p: Variant in pts:
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

# --- per-frame update ---------------------------------------------

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

# --- brood development --------------------------------------------

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
	brood_is_drone = false
	brood_food = ""
	DiagnosticLog.count_larval_death()
	_invalidate_hive_index()
	_invalidate_stock()

# --- index and display epochs -------------------------------------

## The single call-through every content_type/is_built mutator below uses
## to tell the hive's cell-content buckets (hive.gd's `_content_index`)
## they're stale. `main` is set by hive.gd/world_building.gd the moment a
## cell is created -- see hive.gd's `_start_site_at`.
func _invalidate_hive_index() -> void:
	if main != null and is_instance_valid(main) and main.hive != null:
		main.hive.invalidate_index()
	bump_display_epoch()

## The stock-total counterpart to `_invalidate_hive_index()` above -- a
## separate epoch (hive.gd's `stock_epoch`) because `amount`, `is_closed`,
## `fill_then_close` and `ripen_progress` all change the totals without
## necessarily changing content_type/is_built/ripeness, so they wouldn't
## otherwise bump `index_epoch` at all.
func _invalidate_stock() -> void:
	if main != null and is_instance_valid(main) and main.hive != null:
		main.hive.invalidate_stock()

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
	for i: int in range(6):
		if slot_users[i] == bee:
			return i
	for i: int in range(6):
		var holder: Variant = slot_users[i]
		if holder == null or not is_instance_valid(holder):
			slot_users[i] = bee
			return i
	return -1

func release_slot(bee: Node2D) -> void:
	for i: int in range(6):
		if slot_users[i] == bee:
			slot_users[i] = null

## Whether another bee can reserve one of this cell's walls. Invalid
## holders are treated as free here, just as `claim_slot` treats them.
func has_free_slot() -> bool:
	for holder: Variant in slot_users:
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
	# On the squashed grid the two walls on each side sit only half a cell
	# apart vertically, so a plain 1.35 nudge leaves their stand points
	# 11.5px apart and builders bunch. Stretching y alone keeps every pair
	# of stand points at least 0.8 of a cell apart.
	var y_reach: float = SQUASHED_SLOT_Y_REACH if squashed else SLOT_REACH
	return position + Vector2(edge_offset.x * SLOT_REACH, edge_offset.y * y_reach)

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
	if resource_type == "nectar" and nectar_capacity_override > 0.0:
		return nectar_capacity_override
	var config_field: String = Resources.entry(resource_type).get("capacity_config", "")
	if config_field == "":
		return GameConfig.cell_capacity
	return GameConfig.get(config_field)

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
	if content_type != "" and not Resources.entry(content_type).get("storable", false):
		return 0.0
	# BB-1: a sealed bee bread cell takes no more.
	if content_type == Resources.BEE_BREAD and bee_bread_sealed_at >= 0.0:
		return 0.0
	if not accepts(resource_type):
		return 0.0
	if content_type == "":
		return capacity_for(resource_type)
	if content_type == resource_type:
		# BB-1: a bee bread cell keeps the size it started with (add_resource).
		if resource_type == Resources.BEE_BREAD:
			return max(0.0, capacity - amount)
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
	if content_type == "" or not Resources.entry(content_type).get("evictable", false):
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
	if resource_type == "nectar" and was_content_type != "nectar":
		nectar_since = Session.sim_time
	content_type = resource_type
	# BB-1: a bee bread cell's size is fixed by its first deposit, so a
	# later change to bee_bread_cell_capacity cannot leave a part-filled
	# cell unable to reach full and seal. Every other kind reads it live.
	if resource_type != Resources.BEE_BREAD or was_content_type != Resources.BEE_BREAD:
		capacity = capacity_for(resource_type)
	amount += added
	# "Fill then close" seals itself the moment it tops out, so you don't
	# have to be watching the cell at the right second to catch it.
	if fill_then_close and amount >= capacity - 0.001:
		fill_then_close = false
		is_closed = true
	# BB-1: bee bread seals itself once the cell is full, and ripens from
	# that moment (is_ripe_bee_bread).
	if resource_type == Resources.BEE_BREAD and bee_bread_sealed_at < 0.0 and amount >= capacity - 0.001:
		bee_bread_sealed_at = Session.sim_time
		bump_display_epoch()
	_invalidate_stock()
	# A fresh deposit changes which content-type/ripe-honey bucket this
	# cell belongs in either by switching content_type outright, or (for
	# honey) by rewetting it out of the ripe_honey bucket.
	if was_content_type != content_type or was_ripe != is_ripe_honey():
		_invalidate_hive_index()
	return added

## Sim-seconds the oldest nectar here has sat in the cell; 0 when it holds
## none. add_resource stamps a cell's first nectar (scenario fills included)
## and saving.gd restores the saved stamp, so an unstamped nectar cell is a
## fallback only: it is stamped now, and its age counts from this call.
func nectar_age() -> float:
	if content_type != "nectar" or amount <= 0.0:
		return 0.0
	if nectar_since < 0.0:
		nectar_since = Session.sim_time
	return Session.sim_time - nectar_since

## NF-2. Has the nectar here sat past GameConfig.nectar_ferment_hours?
## Derived from the stamp on every call and changes nothing, so it costs no
## per-frame work. Fresh nectar topped up into a fermented cell keeps the
## old stamp, so the cell stays fermented until it is emptied (decision 8).
## An unstamped cell has no age yet, so it is never fermented.
func is_fermented() -> bool:
	if content_type != "nectar" or amount <= 0.0 or nectar_since < 0.0:
		return false
	var hour: float = maxf(0.001, GameConfig.seconds_per_day / 24.0)
	return Session.sim_time - nectar_since > GameConfig.nectar_ferment_hours * hour

## RR-11. Past GameConfig.nectar_pre_ferment_fraction of the fermenting time
## but not yet fermented: the warning stage. Derived on every call, like
## is_fermented(), and read by nothing but the cell's colour.
func is_pre_fermented() -> bool:
	if content_type != "nectar" or amount <= 0.0 or nectar_since < 0.0:
		return false
	if is_fermented():
		return false
	var hour: float = maxf(0.001, GameConfig.seconds_per_day / 24.0)
	var warn_after: float = GameConfig.nectar_pre_ferment_fraction * GameConfig.nectar_ferment_hours * hour
	return Session.sim_time - nectar_since > warn_after

## BB-1. For the restore path, which writes a cell's fields directly: sizes
## a bee bread cell from today's setting, and seals one already that full.
func restore_bee_bread_seal() -> void:
	if content_type != Resources.BEE_BREAD:
		return
	capacity = capacity_for(Resources.BEE_BREAD)
	if bee_bread_sealed_at < 0.0 and amount >= capacity - 0.001:
		bee_bread_sealed_at = Session.sim_time

## BB-2. Takes back ripe bee bread a nurse was carrying without losing its
## ripeness. It tops up a ripe cell to the size it started at, keeping the
## seal stamp, or starts an empty cell that takes bee bread as already sealed
## and ripe (stamped bee_bread_ripen_hours ago, never before 0). It never
## touches a cell still filling or fermenting, which hive.deposit would pick.
## Returns what it took.
func return_ripe_bee_bread(requested: float) -> float:
	if requested <= 0.0 or not accepts(Resources.BEE_BREAD):
		return 0.0
	var added: float = 0.0
	if content_type == Resources.BEE_BREAD:
		if not is_ripe_bee_bread() or not can_withdraw():
			return 0.0
		added = minf(requested, maxf(0.0, capacity - amount))
		if added <= 0.0:
			return 0.0
		amount += added
		_invalidate_stock()
		return added
	if content_type != "":
		return 0.0
	var size: float = capacity_for(Resources.BEE_BREAD)
	added = minf(requested, size)
	if designated_type == "":
		designated_type = Resources.BEE_BREAD
	content_type = Resources.BEE_BREAD
	capacity = size
	amount = added
	var hour: float = maxf(0.001, GameConfig.seconds_per_day / 24.0)
	bee_bread_sealed_at = maxf(0.0, Session.sim_time - GameConfig.bee_bread_ripen_hours * hour - 0.001)
	_invalidate_stock()
	_invalidate_hive_index()
	return added

## BB-1. Has this bee bread cell filled and sealed?
func is_bee_bread_sealed() -> bool:
	return content_type == Resources.BEE_BREAD and bee_bread_sealed_at >= 0.0

## BB-1. Has the sealed bee bread here sat GameConfig.bee_bread_ripen_hours?
## Derived from the stamp on every call, as is_fermented() is, so ripening
## costs no per-frame work. Until it is ripe it is neither food nor currency.
func is_ripe_bee_bread() -> bool:
	return is_bee_bread_sealed() and bee_bread_ripen_fraction() >= 1.0

## How far a sealed bee bread cell is towards ripe, 0 to 1; 0 while filling.
func bee_bread_ripen_fraction() -> float:
	if not is_bee_bread_sealed():
		return 0.0
	var hour: float = maxf(0.001, GameConfig.seconds_per_day / 24.0)
	var needed: float = maxf(0.001, GameConfig.bee_bread_ripen_hours * hour)
	return clampf((Session.sim_time - bee_bread_sealed_at) / needed, 0.0, 1.0)

## Removes up to `requested`, returns how much came out.
func take_resource(resource_type: String, requested: float) -> float:
	if content_type != resource_type:
		return 0.0
	# Sealed, or being filled towards a seal. Emptying the cell on the
	# player's own instruction still gets through -- otherwise a closed
	# cell could never be opened up and cleared again.
	if (is_closed or fill_then_close) and not evict_requested:
		return 0.0
	# BB-1: unripe bee bread stays put; nothing draws on it until it ripens.
	# The player's own emptying order is let through here too, though
	# orders_zones.gd and bee.gd::command_empty_cell refuse to give one for
	# bee bread in BB-1.
	if resource_type == Resources.BEE_BREAD and not is_ripe_bee_bread() and not evict_requested:
		return 0.0
	var taken: float = min(requested, amount)
	amount -= taken
	_invalidate_stock()
	if amount <= 0.001:
		content_type = ""
		amount = 0.0
		ripen_progress = 0.0
		nectar_since = -1.0
		bee_bread_sealed_at = -1.0
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
	_invalidate_stock()
	bump_display_epoch()

func set_fill_then_close(value: bool) -> void:
	fill_then_close = value
	if value:
		is_closed = false   # it has to be able to take deposits to fill
	_invalidate_stock()
	bump_display_epoch()

## How full the cell is, 0 to 1, for the fill shading. Brood reports its
## development instead, which is the equivalent "how far along is this".
func fill_fraction() -> float:
	if content_type == "brood":
		return clamp(brood_progress / max(0.001, develop_time()), 0.0, 1.0)
	if content_type == "" or content_type == "corpse":
		return 0.0
	var full: float = capacity if content_type == Resources.BEE_BREAD else capacity_for(content_type)
	return clamp(amount / max(0.001, full), 0.0, 1.0)

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
	_invalidate_stock()
	if is_ripe_honey() and not was_ripe:
		DiagnosticLog.count_cell_ripened()
		_invalidate_hive_index()

func ripen_fraction() -> float:
	return clamp(ripen_progress / max(0.001, GameConfig.honey_ripen_time), 0.0, 1.0)

# --- brood ---------------------------------------------------------

func start_brood(as_gyne: bool = false, as_drone: bool = false) -> void:
	content_type = "brood"
	amount = 0.0
	brood_progress = 0.0
	brood_fed_seconds = 0.0
	unfed_seconds = 0.0
	fed_on_honey = false
	brood_food = Resources.POLLEN
	brood_is_drone = as_drone
	brood_is_gyne = as_gyne and not as_drone
	_invalidate_hive_index()
	_invalidate_stock()

## What the brood label calls this larva: "gyne", "drone" or a plain "egg".
func brood_kind_label() -> String:
	if brood_is_gyne:
		return "gyne"
	if brood_is_drone:
		return "drone"
	return "egg"

## How long this larva needs in total. A gyne takes several times as long
## as a worker, which is what makes raising one a commitment rather than
## a decision.
func develop_time() -> float:
	if brood_is_gyne:
		return GameConfig.brood_develop_time * GameConfig.gyne_develop_multiplier
	return GameConfig.brood_develop_time

## Called by a nurse that has just dropped food in. `seconds` is what the
## feed buys; feeds don't stack up indefinitely, they just top the larva
## back to a full feed's worth. `on_bee_bread` (BB-2) marks the larva as
## raised on bee bread for the rest of its development.
func feed_brood(seconds: float, on_honey: bool, on_bee_bread: bool = false) -> void:
	brood_fed_seconds = max(brood_fed_seconds, seconds)
	fed_on_honey = on_honey
	if on_bee_bread:
		brood_food = Resources.BEE_BREAD

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
	brood_is_drone = false
	ripen_progress = 0.0
	bee_bread_sealed_at = -1.0
	evict_requested = false
	evict_mode = "move"
	_invalidate_hive_index()
	_invalidate_stock()

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
		"bee_bread":
			return Color(0.62, 0.36, 0.78)
		"brood":
			return Color(0.6, 1.0, 0.7)
	# A later content kind without its own outline colour remains visible
	# instead of losing its rim altogether.
	return Color(0.35, 0.28, 0.12)

func _refresh() -> void:
	var scaled_label_font_size: int = int(round(9.0 * minf(Session.text_scale, 1.5) * UiTheme.typeface_size_factor(Session.ui_typeface)))
	if scaled_label_font_size != _label_font_size:
		_label_font_size = scaled_label_font_size
		info_label.add_theme_font_size_override("font_size", _label_font_size)
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
		cap_sprite.visible = false
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
	var art_sheet: String = ""
	# -1: the frame for how full the cell is, from the sheet's own levels
	# once the match below has picked the sheet.
	var art_frame: int = -1
	# SP-7. 0 for no cap, otherwise the cap stage, 1 to the sheet's last.
	var cap_stage: int = 0
	var art_tint: Color = Color.WHITE
	match content_type:
		"nectar":
			color = NECTAR_COLOR
			info_label.text = "N%d" % int(round(amount))
			art_sheet = "nectar"
			if is_fermented():
				color = FERMENTED_NECTAR_COLOR
				art_sheet = "fermented"
				if Session.colour_blind_mode:
					info_label.text = "sour " + info_label.text
			elif is_pre_fermented():
				color = PRE_FERMENTED_NECTAR_COLOR
				art_tint = PRE_FERMENTED_ART_TINT
				if Session.colour_blind_mode:
					info_label.text = "turning " + info_label.text
		"pollen":
			color = POLLEN_COLOR
			art_sheet = "pollen"
			info_label.text = "P%d" % int(round(amount))
		"jelly":
			color = JELLY_COLOR
			art_sheet = "jelly"
			info_label.text = "RJ%d" % int(round(amount))
		"bee_bread":
			# Filling, sealed and ripe each have a colour and a label of their
			# own, so a glance tells the three apart. The art does the same:
			# unfermented bee bread while it fills, a cap going on stage by
			# stage as it ripens under the seal, fully capped once ripe, and
			# the fermented art showing once the bees open it to eat.
			art_sheet = "bee_bread"
			if is_ripe_bee_bread():
				art_sheet = "bee_bread_ripe"
			if is_bee_bread_sealed() and amount >= capacity - 0.001:
				var stages: int = SpriteCatalogue.WAX_CELL_SEALED_HFRAMES
				cap_stage = clampi(int(ceil(bee_bread_ripen_fraction() * stages)), 1, stages)
			if is_ripe_bee_bread():
				color = BEE_BREAD_RIPE_COLOR
				info_label.text = "BB%d ripe" % int(round(amount))
			elif is_bee_bread_sealed():
				color = BEE_BREAD_SEALED_COLOR
				info_label.text = "BB sealed %d%%" % int(bee_bread_ripen_fraction() * 100.0)
			else:
				color = BEE_BREAD_COLOR
				info_label.text = "bb%d" % int(round(amount))
		"honey":
			color = HONEY_WET_COLOR.lerp(HONEY_COLOR, ripen_fraction())
			art_sheet = "honey"
			if is_ripe_honey():
				info_label.text = "H%d" % int(round(amount))
			else:
				info_label.text = "h%d %d%%" % [int(round(amount)), int(ripen_fraction() * 100.0)]
		"brood":
			color = GYNE_BROOD_COLOR if brood_is_gyne else BROOD_COLOR
			info_label.text = "%s %d%%" % [brood_kind_label(), int(development_percent())]
			# Nine growth stages, each an equal share of the development
			# time; a fresh egg already shows the first.
			art_sheet = "larva"
			art_frame = maxi(1, fill_frame(SpriteCatalogue.WAX_CELL_LARVA_LEVELS, fill_fraction()))
			if brood_fed_seconds <= 0.0:
				# a starving larva reddens as it runs out of time, so a
				# neglected nursery is obvious without opening any panels
				var urgency: float = 1.0 - (seconds_until_death() / max(0.001, GameConfig.larva_death_seconds))
				color = BROOD_COLOR.lerp(Color(0.85, 0.25, 0.2), urgency)
				art_tint = Color.WHITE.lerp(STARVING_ART_TINT, urgency)
				info_label.text += " (%ds)" % int(seconds_until_death())
		"corpse":
			color = CORPSE_COLOR
			info_label.text = "dead %d%%" % int(clean_fraction() * 100.0)
		_:
			# The resprite stands in for the flat fill colour when the
			# setting's on; either way EMPTY_COLOR stays set underneath so
			# switching it off mid-run needs nothing else touched.
			color = EMPTY_COLOR
			if Session.use_cell_sprites:
				_show_fill_art("nectar", 0)
			# an empty cell reserved for something still says so, otherwise
			# you can't tell a reserved cell from an unused one
			if keep_empty:
				info_label.text = "keep"
			elif is_nursery_cell():
				info_label.text = _priority_mark()
			else:
				info_label.text = ""

	if art_sheet != "" and art_frame < 0:
		art_frame = fill_frame(CELL_ART[art_sheet][2], fill_fraction())
	# A cell the player has closed wears the whole cap, whatever is in it.
	if is_closed:
		cap_stage = SpriteCatalogue.WAX_CELL_SEALED_HFRAMES
	# CT-1. A cell holding food or bee bread tints its art and cap by how full
	# it is; brood, corpses and empty cells stay white.
	tone_strength = content_tone_strength(fill_fraction()) if content_type in ["nectar", "honey", "pollen", "jelly", "bee_bread"] else 0.0
	var tone: Color = content_tone(color, tone_strength)

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
		empty_sprite.visible = false
		cap_sprite.visible = false
		outline.visible = true
		outline.default_color = Color(0.12, 0.12, 0.14, 0.8)
		info_label.text = str(over[1])
		closed_mark.visible = is_closed or fill_then_close
		return

	if art_sheet != "" and Session.use_cell_sprites:
		_show_fill_art(art_sheet, art_frame)
		fill_shape.visible = false
		# The sprite is the whole cell: no flat body behind it.
		color = Color(color.r, color.g, color.b, 0.0)
	else:
		_apply_fill_shading()
	empty_sprite.modulate = art_tint * tone
	cap_sprite.modulate = tone
	_show_cap(cap_stage if empty_sprite.visible else 0)
	# The cap says "closed" by itself; the bar stays for the flat look and
	# for a cell still filling towards its close.
	closed_mark.visible = (is_closed or fill_then_close) and not cap_sprite.visible
	closed_mark.default_color = (
		Color(0.1, 0.1, 0.12, 0.9) if is_closed else Color(0.95, 0.95, 0.4, 0.85)
	)

## SP-4, SP-7. Points `empty_sprite` at one frame of a `CELL_ART` sheet and
## shows it. Every sheet shares one frame size and anchor, so only the
## texture and its column count change, and only when the frame does.
func _show_fill_art(sheet: String, frame: int) -> void:
	empty_sprite.visible = true
	var key := "%s:%d" % [sheet, frame]
	if key == _art_key:
		return
	_art_key = key
	var art: Array = CELL_ART[sheet]
	empty_sprite.texture = art[0]
	empty_sprite.hframes = art[1]
	empty_sprite.frame = frame

## SP-7. Shows cap stage `stage` (1 to the sheet's last) over the cell art,
## or hides the cap at 0.
func _show_cap(stage: int) -> void:
	cap_sprite.visible = stage > 0
	if stage > 0 and cap_sprite.frame != stage - 1:
		cap_sprite.frame = stage - 1

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
		"bee_bread":
			return "[b]"
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
