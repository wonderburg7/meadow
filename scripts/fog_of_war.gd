extends Node
## Fog of war over the meadow. Split out 16 Aug 2026 to give
## DESIGN_BACKLOG.md 7.4 a home -- see MAIN_SPLIT_PLAN.md for why systems
## like this live as a sibling Node of main rather than inside it.
##
## Two grids, both keyed by a coarse tile over the meadow (see `_tile_of`
## -- same int-division idiom as SpatialGrid, just flags/counts rather
## than buckets of nodes). Called "tile" throughout this file rather than
## "cell" on purpose -- hive.gd already draws that exact line for its own
## grid (`occupied_tiles`/`tile_is_free` for hex position, `cells` for
## the wax HiveCell objects that sit on some of them), and fog needed the
## same split: a fog tile is nothing like a wax cell, wrong size, wrong
## grid, wrong file, and `GameConfig.hive_cell_size` already exists for
## the real thing.
##
##   `explored`   -- tiles any bee has ever flown near. Saved with the
##                   run, so a discovered patch stays discovered.
##   `_lit_count` -- tiles within a bee's sight *this instant*, as a
##                   reference count (more than one bee can cover the
##                   same tile) rather than a plain flag, so one bee
##                   leaving doesn't dark a tile another is still
##                   lighting. Not saved.
## Explored-but-not-currently-lit draws dimmed by default, or fully clear
## if `GameConfig.fog_permanent_reveal` is on -- see `_draw_fog`.
##
## Presentation only, per CLAUDE.md rule 3: a bee still finds flowers via
## the same flower_grid search regardless of what the player has seen.
## Fog hides what the player can see, not what the bees know -- so it
## costs nothing to gate a draw call, unlike gating a decision would.
##
## Drawn on `_layer`, a plain Node2D added under `main.meadow_root` so it
## shares the meadow's coordinate space and its show/hide with the
## hive-view toggle automatically (`meadow_root.visible` already flips in
## camera_view._apply_view). Its `draw` signal is connected to
## `_draw_fog` the same way `main.selection_layer` connects to
## `input_selection._draw_selection_box`.
##
## Performance note (18 Aug 2026): `FOG_TILE_SIZE` shrank from 20 to 5 for
## a smoother reveal edge, which on its own would have meant ~16x the
## tiles per bee per frame -- at a few dozen meadow bees, comfortably
## enough to repeat the exact "walks something expensive every frame"
## shape of bug `hive.gd::create_next_cell_site` hit the same week. Two
## changes keep it cheap instead:
##   - a bee only recomputes its lit tiles when it has moved
##     `RELIGHT_DISTANCE` since the last time (`_relight`/`_bee_light`),
##     not every frame -- most frames touch nothing at all;
##   - `_draw_fog` merges each row into runs of one colour rather than
##     issuing one draw call per tile, since a fog boundary is a smooth
##     curve and most of a row is a single colour either side of it.
## Neither is measured against a real playtest (nothing here can run
## Godot) -- both are wrapped in Perf so the corner readout will show
## `fog_of_war` if this guess turns out wrong.
##
## Performance note (19 Aug 2026, AUDIT_PLAN.md Bundle C): the guess above
## turned out wrong -- a baseline playtest showed `fog_of_war_draw` costing
## up to ~130ms at minimum zoom and `fog_of_war_update` scaling visibly
## with bee count (~30ms at ~30 meadow bees). Two changes, gated on that
## measurement rather than guessed:
##   - `_bee_light` used to store each bee's full translated tile array
##     (thousands of Vector2i at today's reveal radius). It now stores
##     only a centre tile; `_disc_row_spans` holds one shared set of
##     relative horizontal spans, rebuilt only if `fog_reveal_radius` changes, and
##     `_light_center` applies it to whichever centre needs lighting or
##     unlighting. Same tiles get lit, far less stored and reallocated.
##   - `_update` used to call `_layer.queue_redraw()` unconditionally
##     every frame. It now only does so when a bee's lit tiles actually
##     changed, the camera moved or zoomed, the hive/meadow view switched,
##     or `fog_permanent_reveal` toggled -- a static camera over an
##     unchanging fog state now draws nothing.
##
## Performance note (19 Aug 2026, AUDIT_PLAN.md Bundle F): even after the
## above, a re-measurement (same session, see Bundle C's "Clean
## re-measurement" note) found `fog_of_war_draw` still the dominant cost at
## min zoom -- ~29ms dynamic reveal, worst frame 83ms of a 96ms total. The
## remaining cost was the draw method itself: `_draw_fog_body` used to merge
## each row into runs of one colour and `draw_rect` each run, which still
## means many draw calls when the explored boundary is jagged. See the perf
## note above `_draw_fog_body` for what replaced it -- and the note below
## for why that replacement itself needed a second pass.
##
## Performance note (19 Aug 2026, later same day): the mask-texture version
## above was a per-view-rebuild -- a byte array covering only what the
## camera could currently see, rebuilt from scratch on every dirty frame.
## A Day 11 playtest with a bigger colony and a more zoomed-out camera than
## the earlier quick check showed it costing as much as the original
## draw_rect version, worst in exactly the case that used to be cheap
## (`fog_permanent_reveal` on): with no early-out for "this whole run is
## one colour", its cost tracked view size, not how much fog was actually
## in view. Replaced the per-view texture with one persistent
## `_world_mask_image`/`_world_mask_texture` sized to the whole meadow
## (`WORLD_MARGIN` past `main.FLOWER_FIELD_HALF_SIZE`, ~700x556 tiles at
## today's field size -- a few hundred KB, trivial). `_paint_tile` writes a
## single pixel directly into it whenever `_light_center`/`reveal_around`
## change a tile's state, instead of every visible tile being redetermined
## every dirty frame. `_draw_fog_body` now just re-uploads the image (only
## if something was actually painted since the last upload -- see
## `_mask_dirty`) and draws whichever sub-rect the camera currently frames
## with `draw_texture_rect_region` -- panning or zooming costs nothing
## extra, since it only changes which part of the already-current texture
## gets sampled.
##
## That fixed the draw side but not relight cost scaling with bee count
## (Day 11, 50 foraging bees: `fog_of_war_relight` 44-45ms) -- tackled the
## same session via `_relight_delta`, applied instead of `_light_center`
## once a bee has an old position to diff against. See its own comment for
## the reasoning; short version: a bee only relights after moving
## `RELIGHT_DISTANCE` (8 tiles), far less than `fog_reveal_radius` (48
## tiles), so consecutive discs overlap almost entirely and only the thin
## edge between them needs touching.

const Shapes = preload("res://scripts/shapes.gd")
const HIVE_QUEEN_REVEAL_RADIUS_MULTIPLIER := 2.0
const HIVE_OPEN_SPACE_REVEAL_BLOCKS := 1.8

var main: Node2D

## A run-local equivalent of GameConfig.fog_permanent_reveal. Challenges
## can keep explored ground visible without mutating the shared autoload and
## leaking that choice into the next run.
var permanent_reveal_override: bool = false

var explored: Dictionary = {}      # Vector2i tile -> true, saved
var _lit_count: Dictionary = {}    # Vector2i tile -> int, bees currently covering it

## bee instance id -> {"pos": Vector2, "center": Vector2i} -- the position
## and lit-disc centre as of that bee's last recompute. The disc itself
## isn't stored per bee any more -- see `_disc_row_spans` below.
var _bee_light: Dictionary = {}

## Every bee shares one disc as compact horizontal row spans, keyed by
## relative y.  Rebuilt only when `GameConfig.fog_reveal_radius` changes.
## A span is Vector2i(min_x, max_x), inclusive.  This preserves the exact
## tile disc while allowing a moved source to touch only its entering and
## leaving edges instead of testing every disc tile for membership.
var _disc_row_spans: Dictionary = {}
var _disc_offsets_radius: float = -1.0
## Set when a radius change removes cached contributions before the normal
## source loop relights them. `_update` consumes it to redraw even if no bee
## remains outdoors to make the loop dirty on its own.
var _contributions_invalidated: bool = false

var _layer: Node2D
## Challenge 1's opening happens in hive_root, while the ordinary fog layer
## belongs to meadow_root and is hidden in hive view. A separate small mask
## gives that tutorial beat real fog without changing ordinary hive runs.
var _hive_layer: Node2D
var _hive_mask_material: ShaderMaterial
var _hive_mask_image: Image
var _hive_mask_texture: ImageTexture
var _hive_origin_tile: Vector2i = Vector2i.ZERO
var _hive_mask_dirty: bool = false
var _hive_explored: Dictionary = {}
## "queen" during the opening dig, then "open_space" after breakthrough.
## Empty outside Challenge 1.
var hive_reveal_mode: String = ""
var _last_hive_reveal_pos: Vector2 = Vector2(INF, INF)
var _last_hive_cam_pos: Vector2 = Vector2(INF, INF)
var _last_hive_cam_zoom: float = -1.0
## Tracked so `_update` only queues a redraw when something actually
## changed, instead of every frame -- see the 19 Aug perf note below.
var _last_layer_visible: bool = false
var _last_seen_in_hive_view: bool = false
var _last_draw_cam_pos: Vector2 = Vector2.ZERO
var _last_draw_cam_zoom: float = -1.0
var _last_draw_permanent: bool = false

## Mask-texture rendering (AUDIT_PLAN.md Bundle F, 19 Aug 2026) -- see the
## perf notes further down. One persistent image covers the whole meadow;
## `_paint_tile` writes single pixels into it as tiles change state, and
## `_draw_fog_body` uploads it to the GPU only when `_mask_dirty` and draws
## whichever sub-rect the camera currently frames.
var _mask_material: ShaderMaterial
var _world_mask_image: Image
var _world_mask_texture: ImageTexture
## Tile coordinate of the persistent image's pixel (0, 0) -- tile
## coordinates are signed (the hive sits near the world's centre) but image
## pixel coordinates aren't, so every read/write subtracts this to convert.
var _world_origin_tile: Vector2i = Vector2i.ZERO
## True once `_paint_tile`/`_repaint_all` has changed a pixel since the
## last GPU upload -- lets `_draw_fog_body` skip re-uploading the whole
## image on a frame that only panned or zoomed the camera.
var _mask_dirty: bool = false

const FOG_TILE_SIZE := 5.0
## How far past `main.FLOWER_FIELD_HALF_SIZE` the persistent mask image
## extends on each side -- covers `fog_reveal_radius` overshoot and any
## steering wander near the field edge, so a bee near the boundary never
## tries to paint a tile outside the image (silently dropped by
## `_paint_tile` if it ever did, rather than erroring, but shouldn't
## happen with this much slack).
const WORLD_MARGIN := 400.0
## How far a bee has to move since its last recompute before its lit
## tiles are redone. Keeps the expensive part (walking every tile in
## sight radius) down to roughly once every third of a second per bee
## rather than every frame -- see the perf note above.
const RELIGHT_DISTANCE := 40.0
## A modest clearing around the hive at the start of a fresh run, so day
## one isn't a black screen with a single lit dot. Not saved separately
## -- it just becomes ordinary explored tiles like any other.
const START_CLEAR_RADIUS := 420.0

## Mask-texture byte values -- one per tile, read by shaders/fog_mask.gdshader
## as a normalised float and bucketed into the same three states this file
## used to draw directly (see the band comments there). Values just need to
## fall clearly either side of 0.25/0.75 once divided by 255, not match any
## particular scale.
const MASK_UNEXPLORED := 0
const MASK_EXPLORED := 128
const MASK_LIT := 255

## Called once, after meadow_root and main.hive both exist -- world_building
## builds the meadow before this can run, so main._ready calls this right
## after world_building._build_meadow().
func _build_layer() -> void:
	_layer = Node2D.new()
	_layer.z_index = 90   # above bees (5) and the rain wash (50), below the selection layer (100)
	_layer.draw.connect(_draw_fog)
	_mask_material = ShaderMaterial.new()
	_mask_material.shader = preload("res://shaders/fog_mask.gdshader")
	_layer.material = _mask_material
	main.meadow_root.add_child(_layer)

	var half_size: Vector2 = main.FLOWER_FIELD_HALF_SIZE + Vector2(WORLD_MARGIN, WORLD_MARGIN)
	var world_w: int = int(ceil(half_size.x * 2.0 / FOG_TILE_SIZE))
	var world_h: int = int(ceil(half_size.y * 2.0 / FOG_TILE_SIZE))
	_world_origin_tile = _tile_of(Vector2(-half_size.x, -half_size.y))
	_world_mask_image = Image.create_empty(world_w, world_h, false, Image.FORMAT_R8)
	_world_mask_image.fill(Color8(MASK_UNEXPLORED, MASK_UNEXPLORED, MASK_UNEXPLORED, 255))
	_world_mask_texture = ImageTexture.create_from_image(_world_mask_image)
	_mask_material.set_shader_parameter("mask_tex", _world_mask_texture)
	# Constant for the texture's lifetime -- the shader uses this plus the
	# per-draw view_world_pos/size (set in _draw_fog_body) to work out
	# whether a given screen pixel's world position actually falls inside
	# mask_tex's real coverage, rather than trusting Godot's own UV
	# clipping. See shaders/fog_mask.gdshader's header comment for why.
	_mask_material.set_shader_parameter("tex_world_pos", Vector2(_world_origin_tile) * FOG_TILE_SIZE)
	_mask_material.set_shader_parameter("tex_world_size", Vector2(world_w, world_h) * FOG_TILE_SIZE)

	reveal_around(main.hive.position, START_CLEAR_RADIUS)
	_build_hive_layer()

func _build_hive_layer() -> void:
	_hive_layer = Node2D.new()
	_hive_layer.z_index = 90
	_hive_layer.draw.connect(_draw_hive_fog)
	_hive_mask_material = ShaderMaterial.new()
	_hive_mask_material.shader = preload("res://shaders/fog_mask.gdshader")
	_hive_layer.material = _hive_mask_material
	_hive_layer.visible = false
	main.hive_root.add_child(_hive_layer)

	var rings: float = GameConfig.hive_interior_rings + GameConfig.hive_soil_depth + GameConfig.hive_rock_rings
	var half_extent: float = (rings + 3.0) * GameConfig.hive_cell_spacing * 1.5
	var centre: Vector2 = main.world_building._hive_centre_local()
	_hive_origin_tile = _tile_of(centre - Vector2(half_extent, half_extent))
	var side: int = int(ceil(half_extent * 2.0 / FOG_TILE_SIZE))
	_hive_mask_image = Image.create_empty(side, side, false, Image.FORMAT_R8)
	_hive_mask_image.fill(Color8(MASK_UNEXPLORED, MASK_UNEXPLORED, MASK_UNEXPLORED, 255))
	_hive_mask_texture = ImageTexture.create_from_image(_hive_mask_image)
	_hive_mask_material.set_shader_parameter("mask_tex", _hive_mask_texture)
	_hive_mask_material.set_shader_parameter("tex_world_pos", Vector2(_hive_origin_tile) * FOG_TILE_SIZE)
	_hive_mask_material.set_shader_parameter("tex_world_size", Vector2(side, side) * FOG_TILE_SIZE)
	_hive_mask_material.set_shader_parameter("permanent_reveal", true)

## Part of main's public surface for this system: called once from
## main._process each frame.
func _update() -> void:
	if not GameConfig.fog_of_war_on:
		if _layer.visible:
			_layer.visible = false
		if _hive_layer != null:
			_hive_layer.visible = false
		_last_layer_visible = false
		return
	_update_hive_fog()
	var just_shown: bool = not _last_layer_visible
	_layer.visible = true
	_last_layer_visible = true

	Perf.begin("fog_of_war_update")
	_ensure_disc_offsets()
	var dirty: bool = just_shown or _contributions_invalidated
	_contributions_invalidated = false
	var seen_ids: Dictionary = {}
	for b in get_tree().get_nodes_in_group("bees"):
		if not is_instance_valid(b) or b.get_parent() != main.meadow_root:
			continue
		var id: int = b.get_instance_id()
		seen_ids[id] = true
		var cached: Dictionary = _bee_light.get(id, {})
		if cached.is_empty() or cached.pos.distance_to(b.position) >= RELIGHT_DISTANCE:
			# Own section, nested inside fog_of_war_update -- lets a
			# breakdown tell "many bees relit this frame" apart from
			# "the group query/cleanup loop itself got expensive". See
			# the 19 Aug Bundle F granularity note above _draw_fog_body.
			Perf.begin("fog_of_war_relight")
			_relight(id, b.position)
			Perf.end("fog_of_war_relight")
			dirty = true

	# A bee that died or came indoors since the last frame stops lighting
	# whatever it was covering.
	for id in _bee_light.keys():
		if not seen_ids.has(id):
			_light_center(_bee_light[id].center, -1)
			_bee_light.erase(id)
			dirty = true
	Perf.end("fog_of_war_update")

	var view_switched: bool = main.in_hive_view != _last_seen_in_hive_view
	_last_seen_in_hive_view = main.in_hive_view
	if main.in_hive_view:
		return   # _draw_fog is a no-op while the hive view is showing

	if dirty or view_switched or _camera_view_changed():
		_layer.queue_redraw()
		var cam: Camera2D = main.camera_view._active_camera()
		_last_draw_cam_pos = cam.position
		_last_draw_cam_zoom = cam.zoom.x
		_last_draw_permanent = permanent_reveal_enabled()

## True once the camera's moved, zoomed, or `fog_permanent_reveal` has
## flipped since the last frame we actually redrew.
func _camera_view_changed() -> bool:
	var cam: Camera2D = main.camera_view._active_camera()
	return (
		cam.position != _last_draw_cam_pos
		or cam.zoom.x != _last_draw_cam_zoom
		or permanent_reveal_enabled() != _last_draw_permanent
	)

func permanent_reveal_enabled() -> bool:
	return GameConfig.fog_permanent_reveal or permanent_reveal_override

## Challenge-local hive reveal. Only the queen paints this mask: the opening
## is about the path she has personally made visible, and no worker exists yet.
func _update_hive_fog() -> void:
	if _hive_layer == null:
		return
	_hive_layer.visible = permanent_reveal_override and hive_reveal_mode != ""
	if not _hive_layer.visible:
		return
	if hive_reveal_mode == "queen" and is_instance_valid(main.queen) and main.queen.get_parent() == main.hive_root:
		var queen_pos: Vector2 = main.queen.position
		if _last_hive_reveal_pos.x == INF or queen_pos.distance_to(_last_hive_reveal_pos) >= GameConfig.hive_cell_size * 0.5:
			_reveal_hive_around(
				queen_pos, GameConfig.hive_cell_size * HIVE_QUEEN_REVEAL_RADIUS_MULTIPLIER
			)
			_last_hive_reveal_pos = queen_pos
	var cam: Camera2D = main.hive_camera
	var camera_changed: bool = cam.position != _last_hive_cam_pos or cam.zoom.x != _last_hive_cam_zoom
	if main.in_hive_view and (_hive_mask_dirty or camera_changed):
		_hive_layer.queue_redraw()
		_last_hive_cam_pos = cam.position
		_last_hive_cam_zoom = cam.zoom.x

func set_hive_reveal_mode(mode: String) -> void:
	if mode == hive_reveal_mode:
		return
	if mode not in ["", "queen", "open_space"]:
		push_error("fog_of_war: unknown hive reveal mode '%s'" % mode)
		return
	hive_reveal_mode = mode
	_last_hive_reveal_pos = Vector2(INF, INF)
	if mode == "open_space":
		_rebuild_hive_open_space_mask()
	else:
		_clear_hive_mask()
		if mode == "queen":
			_reveal_hive_entrance_to_queen()

## The queen begins partway down a tunnel she has already traversed. Seed that
## history immediately, rather than making the route behind her inexplicably
## dark until she walks over it again.
func _reveal_hive_entrance_to_queen() -> void:
	if not is_instance_valid(main.queen):
		return
	var interior_rings: int = int(GameConfig.hive_interior_rings)
	var tunnel_depth: int = int(GameConfig.hive_soil_depth + GameConfig.hive_rock_rings)
	var entrance_tiles: Dictionary = main.world_building._entrance_tiles(interior_rings, tunnel_depth)
	var queen_hex: Vector2i = Shapes.pixel_to_hex(
		main.queen.position - main.hive.comb_centre, GameConfig.hive_cell_spacing, Session.use_sprite_hex_grid
	)
	var queen_ring: int = Shapes.hex_ring_index(queen_hex)
	var reveal_radius: float = GameConfig.hive_cell_size * HIVE_QUEEN_REVEAL_RADIUS_MULTIPLIER
	for hex in entrance_tiles.keys():
		if Shapes.hex_ring_index(hex) < queen_ring:
			continue
		var point: Vector2 = main.hive.comb_centre + Shapes.hex_to_pixel(
			hex.x, hex.y, GameConfig.hive_cell_spacing, Session.use_sprite_hex_grid
		)
		_reveal_hive_around(point, reveal_radius)

## Called after a soil block is actually removed. No per-frame topology scan:
## an open-space mask is rebuilt only on this causal event (or mode entry).
func notify_hive_open_space_changed() -> void:
	if hive_reveal_mode == "open_space":
		_rebuild_hive_open_space_mask()

func _clear_hive_mask() -> void:
	_hive_explored.clear()
	_hive_mask_image.fill(Color8(MASK_UNEXPLORED, MASK_UNEXPLORED, MASK_UNEXPLORED, 255))
	_hive_mask_dirty = true

func _rebuild_hive_open_space_mask() -> void:
	_clear_hive_mask()
	var reach: int = int(GameConfig.hive_interior_rings + GameConfig.hive_soil_depth + GameConfig.hive_rock_rings)
	# About 1.8 block widths: enough to show the whole first soil block
	# bordering floor and a slice of the one behind it.
	var reveal_radius: float = GameConfig.hive_cell_size * 2.0 * HIVE_OPEN_SPACE_REVEAL_BLOCKS
	for ring in range(reach + 1):
		for hex in Shapes.hex_ring(ring):
			if not main.hive.tile_is_walkable(hex):
				continue
			var point: Vector2 = main.hive.comb_centre + Shapes.hex_to_pixel(
				hex.x, hex.y, GameConfig.hive_cell_spacing, Session.use_sprite_hex_grid
			)
			_reveal_hive_around(point, reveal_radius)

func _reveal_hive_around(pos: Vector2, radius: float) -> void:
	for tile in _disc(pos, radius):
		if _hive_explored.has(tile):
			continue
		_hive_explored[tile] = true
		var px: Vector2i = tile - _hive_origin_tile
		if px.x < 0 or px.y < 0 or px.x >= _hive_mask_image.get_width() or px.y >= _hive_mask_image.get_height():
			continue
		_hive_mask_image.set_pixel(px.x, px.y, Color8(MASK_EXPLORED, MASK_EXPLORED, MASK_EXPLORED, 255))
		_hive_mask_dirty = true

func _draw_hive_fog() -> void:
	if not main.in_hive_view or not permanent_reveal_override or hive_reveal_mode == "":
		return
	if _hive_mask_dirty:
		_hive_mask_texture.update(_hive_mask_image)
		_hive_mask_dirty = false
	var cam: Camera2D = main.hive_camera
	var span: Vector2 = main.get_viewport_rect().size / cam.zoom.x
	var local_cam_pos: Vector2 = cam.position - main.hive_root.position
	var view: Rect2 = Rect2(local_cam_pos - span * 0.5, span).grow(FOG_TILE_SIZE)
	var min_tile: Vector2i = _tile_of(view.position)
	var max_tile: Vector2i = _tile_of(view.position + view.size)
	var size_tiles := Vector2i(max_tile.x - min_tile.x + 1, max_tile.y - min_tile.y + 1)
	if size_tiles.x <= 0 or size_tiles.y <= 0:
		return
	var dest := Rect2(Vector2(min_tile) * FOG_TILE_SIZE, Vector2(size_tiles) * FOG_TILE_SIZE)
	_hive_mask_material.set_shader_parameter("view_world_pos", dest.position)
	_hive_mask_material.set_shader_parameter("view_world_size", dest.size)
	_hive_layer.draw_texture_rect(_hive_mask_texture, dest, false)

## Rebuilds the shared offset disc only when the reveal radius has
## actually changed (it's a live-tunable debug-panel slider).
func _ensure_disc_offsets() -> void:
	var radius: float = GameConfig.fog_reveal_radius
	if radius == _disc_offsets_radius and not _disc_row_spans.is_empty():
		return
	# The cached centres were lit with the old radius. Remove those exact old
	# spans before replacing the shared shape; each outdoor source will receive
	# a first-light pass below. This is the radius invalidation contract, rather
	# than diffing two discs that no longer share a definition.
	if not _disc_row_spans.is_empty():
		for light in _bee_light.values():
			_light_center(light.center, -1)
		_bee_light.clear()
		_contributions_invalidated = true
	_disc_row_spans.clear()
	var span: int = int(ceil(radius / FOG_TILE_SIZE))
	for dy in range(-span, span + 1):
		var row_half_width: int = -1
		for dx in range(span + 1):
			if Vector2(dx, dy).length() * FOG_TILE_SIZE > radius:
				break
			row_half_width = dx
		if row_half_width >= 0:
			_disc_row_spans[dy] = Vector2i(-row_half_width, row_half_width)
	_disc_offsets_radius = radius

## Recomputes and swaps in the disc centre bee `id` currently lights.
##
## Performance note (19 Aug 2026, AUDIT_PLAN.md Bundle F): used to
## unconditionally unlight the whole old disc then relight the whole new
## one -- correct, but a Day 11 playtest at 50 foraging bees measured this
## at 44-45ms, since a full disc is thousands of tiles and every relight
## paid for all of them regardless of how far the bee actually moved. A
## bee only relights after moving `RELIGHT_DISTANCE` (40 units, 8 tiles),
## far less than `fog_reveal_radius` (240 units, 48 tiles) -- so the old
## and new discs overlap almost completely, and only a thin edge actually
## changes state. `_relight_delta` below applies just that edge instead of
## the whole disc on every relight after the first.
func _relight(id: int, pos: Vector2) -> void:
	_ensure_disc_offsets()
	var center: Vector2i = _tile_of(pos)
	var old: Dictionary = _bee_light.get(id, {})
	if old.is_empty():
		_light_center(center, 1)   # first light for this bee -- no "old" to diff against
	else:
		_relight_delta(old.center, center, center - old.center)
	_bee_light[id] = {"pos": pos, "center": center}

## Unlights whichever old-disc tiles the new disc no longer covers, and
## lights whichever new-disc tiles the old disc didn't already cover --
## the symmetric difference between the two discs, not their full areas.
##
## Each old/new row pair has two inclusive x spans.  Subtracting their
## overlap gives at most two short edge spans, so normal movement is bounded
## by the circumference times the displacement rather than the disc area.
## The row spans are built from the same distance predicate as the previous
## offset array, so the reveal shape is unchanged.
func _relight_delta(old_center: Vector2i, new_center: Vector2i, delta: Vector2i) -> void:
	for y in _disc_row_spans:
		var old_span: Vector2i = _disc_row_spans[y]
		var new_span: Vector2i = _disc_row_spans.get(y - delta.y, Vector2i(1, 0))
		_apply_span_difference(old_center.x + old_span.x, old_center.x + old_span.y,
			new_center.x + new_span.x, new_center.x + new_span.y, old_center.y + int(y), -1)
	for y in _disc_row_spans:
		var new_span: Vector2i = _disc_row_spans[y]
		var old_span: Vector2i = _disc_row_spans.get(y + delta.y, Vector2i(1, 0))
		_apply_span_difference(new_center.x + new_span.x, new_center.x + new_span.y,
			old_center.x + old_span.x, old_center.x + old_span.y, new_center.y + int(y), 1)

## Applies the inclusive part of [start_x, end_x] not covered by
## [covered_start, covered_end]. An inverted covered range means no overlap.
func _apply_span_difference(start_x: int, end_x: int, covered_start: int,
		covered_end: int, y: int, delta: int) -> void:
	if covered_start > start_x:
		_apply_span(start_x, min(end_x, covered_start - 1), y, delta)
	if covered_end < end_x:
		_apply_span(max(start_x, covered_end + 1), end_x, y, delta)

func _apply_span(start_x: int, end_x: int, y: int, delta: int) -> void:
	for x in range(start_x, end_x + 1):
		_apply_light(Vector2i(x, y), delta)

## Applies the shared disc row spans around `center`, lighting (delta 1) or
## unlighting (delta -1) every tile it covers. Used for a bee's first
## light (no "old" position to diff against yet) and for a departed bee's
## full unlight -- `_relight_delta` above handles the common case of a bee
## that's already lighting somewhere and just moved.
func _light_center(center: Vector2i, delta: int) -> void:
	for y in _disc_row_spans:
		var row: Vector2i = _disc_row_spans[y]
		_apply_span(center.x + row.x, center.x + row.y, center.y + int(y), delta)

## One tile's actual state change: updates the reference count (and
## `explored`, on a light) and repaints the tile in the persistent mask
## image. Shared by `_light_center` and `_relight_delta` so both apply a
## tile exactly the same way.
func _apply_light(tile: Vector2i, delta: int) -> void:
	var count: int = _lit_count.get(tile, 0) + delta
	if count <= 0:
		_lit_count.erase(tile)
	else:
		_lit_count[tile] = count
	if delta > 0:
		explored[tile] = true
	_paint_tile(tile)

## Marks a circle of tiles explored without lighting them -- used for the
## starting clearing and for restoring a save.
func reveal_around(pos: Vector2, radius: float) -> void:
	for tile in _disc(pos, radius):
		explored[tile] = true
		_paint_tile(tile)

## Writes `tile`'s current state (unexplored/explored/lit) into the
## persistent mask image, if it falls within the image's bounds -- see
## `WORLD_MARGIN`. Marks the image dirty so `_draw_fog_body` knows to
## upload it before the next draw.
func _paint_tile(tile: Vector2i) -> void:
	var px: Vector2i = tile - _world_origin_tile
	if px.x < 0 or px.y < 0 or px.x >= _world_mask_image.get_width() or px.y >= _world_mask_image.get_height():
		return
	var value: int = MASK_UNEXPLORED
	if _lit_count.has(tile):
		value = MASK_LIT
	elif explored.has(tile):
		value = MASK_EXPLORED
	_world_mask_image.set_pixel(px.x, px.y, Color8(value, value, value, 255))
	_mask_dirty = true

## Repaints the whole persistent image from `explored` -- used after
## `restore()` replaces `explored` wholesale, since the image's existing
## pixels reflect the previous world's state, not the loaded save's.
## `_lit_count` isn't restored (bees relight fresh once respawned), and a
## lit tile is always already explored, so `explored` alone is enough.
func _repaint_all() -> void:
	_world_mask_image.fill(Color8(MASK_UNEXPLORED, MASK_UNEXPLORED, MASK_UNEXPLORED, 255))
	for tile in explored.keys():
		_paint_tile(tile)
	_mask_dirty = true

## Every tile within `radius` of `pos`, as a flat array.
func _disc(pos: Vector2, radius: float) -> Array:
	var out: Array = []
	var span: int = int(ceil(radius / FOG_TILE_SIZE))
	var centre: Vector2i = _tile_of(pos)
	for dx in range(-span, span + 1):
		for dy in range(-span, span + 1):
			if Vector2(dx, dy).length() * FOG_TILE_SIZE > radius:
				continue
			out.append(Vector2i(centre.x + dx, centre.y + dy))
	return out

func _tile_of(pos: Vector2) -> Vector2i:
	return Vector2i(int(floor(pos.x / FOG_TILE_SIZE)), int(floor(pos.y / FOG_TILE_SIZE)))

## Bound to the tiles the camera can currently see, the same margin
## approach as world_building.is_on_screen -- the meadow is thousands of
## units across but the view is never more than a few hundred tiles wide.
func _draw_fog() -> void:
	if main.in_hive_view:
		return
	Perf.begin("fog_of_war_draw")
	_draw_fog_body()
	Perf.end("fog_of_war_draw")

## Split from _draw_fog so every early return above the Perf wrap doesn't
## also need its own Perf.end -- see the "one begin with no matching end"
## warning in CLAUDE.md's perf section.
##
## Performance note (19 Aug 2026, AUDIT_PLAN.md Bundle F): see the header
## comment's 19 Aug perf notes for the full trail (draw_rect runs ->
## per-view mask texture -> persistent whole-meadow mask texture -> this).
## No per-frame tile walk here any more -- `_paint_tile` (called from
## `_light_center`/`reveal_around`/`_repaint_all`) already keeps
## `_world_mask_image` current as tiles change state. This function only
## uploads it to the GPU if `_mask_dirty`, then draws the camera's whole
## current view in one call -- cost no longer depends on view size or
## zoom at all, only on whether anything actually changed.
##
## Always draws the *whole* view, with no CPU-side clamping to
## `_world_mask_image`'s bounds -- an earlier version clamped here, which
## fixed a stretching artifact (see shaders/fog_mask.gdshader's header
## comment) but introduced a worse one: whatever part of the view fell
## outside the clamped region just never got drawn, which read as that
## ground being revealed by default rather than hidden. The shader itself
## now decides, per pixel, whether that pixel's world position is inside
## `mask_tex`'s real coverage -- see `view_world_pos`/`view_world_size`,
## set below, and `tex_world_pos`/`tex_world_size`, set once in
## `_build_layer`.
func _draw_fog_body() -> void:
	if _mask_dirty:
		Perf.begin("fog_of_war_draw_upload")
		_world_mask_texture.update(_world_mask_image)
		_mask_dirty = false
		Perf.end("fog_of_war_draw_upload")

	_mask_material.set_shader_parameter("permanent_reveal", permanent_reveal_enabled())

	var cam: Camera2D = main.camera_view._active_camera()
	var span: Vector2 = main.get_viewport_rect().size / cam.zoom.x
	var view: Rect2 = Rect2(cam.position - span * 0.5, span).grow(FOG_TILE_SIZE)

	var min_tile: Vector2i = _tile_of(view.position)
	var max_tile: Vector2i = _tile_of(view.position + view.size)
	var w: int = max_tile.x - min_tile.x + 1
	var h: int = max_tile.y - min_tile.y + 1
	if w <= 0 or h <= 0:
		return

	var dest: Rect2 = Rect2(Vector2(min_tile) * FOG_TILE_SIZE, Vector2(w, h) * FOG_TILE_SIZE)
	_mask_material.set_shader_parameter("view_world_pos", dest.position)
	_mask_material.set_shader_parameter("view_world_size", dest.size)
	_layer.draw_texture_rect(_world_mask_texture, dest, false)

## Tiles as flat pairs, matching SaveGame._hex_list -- save_game.gd calls
## this rather than reaching into `explored` directly, same as it goes
## through world.hive for cell data rather than touching hive_cell.gd's
## internals.
func explored_list() -> Array:
	var out: Array = []
	for tile in explored.keys():
		out.append([tile.x, tile.y])
	return out

## Called from saving.gd._restore. Replaces rather than merges -- a
## loaded run should show exactly what that save had explored, not that
## plus whatever the fresh world's starting clearing added.
func restore(tiles: Array) -> void:
	explored.clear()
	for pair in tiles:
		explored[Vector2i(int(pair[0]), int(pair[1]))] = true
	_repaint_all()
