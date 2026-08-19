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
##     only a centre tile; `_disc_offsets` holds one shared array of
##     relative offsets, rebuilt only if `fog_reveal_radius` changes, and
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
## note above `_draw_fog_body` for what replaced it.

var main: Node2D

var explored: Dictionary = {}      # Vector2i tile -> true, saved
var _lit_count: Dictionary = {}    # Vector2i tile -> int, bees currently covering it

## bee instance id -> {"pos": Vector2, "center": Vector2i} -- the position
## and lit-disc centre as of that bee's last recompute. The disc itself
## isn't stored per bee any more -- see `_disc_offsets` below.
var _bee_light: Dictionary = {}

## Every bee shares one disc of tile offsets (relative to its own centre
## tile), rebuilt only when `GameConfig.fog_reveal_radius` changes rather
## than translated and stored fresh per bee per relight -- see the 19 Aug
## perf note below.
var _disc_offsets: Array[Vector2i] = []
var _disc_offsets_radius: float = -1.0

var _layer: Node2D
## Tracked so `_update` only queues a redraw when something actually
## changed, instead of every frame -- see the 19 Aug perf note below.
var _last_layer_visible: bool = false
var _last_seen_in_hive_view: bool = false
var _last_draw_cam_pos: Vector2 = Vector2.ZERO
var _last_draw_cam_zoom: float = -1.0
var _last_draw_permanent: bool = false

## Mask-texture rendering (AUDIT_PLAN.md Bundle F, 19 Aug 2026) -- see the
## perf note further down, above `_draw_fog_body`. `_mask_image`/
## `_mask_texture` are reused frame to frame and only rebuilt (rather than
## updated in place) when the visible tile span changes size.
var _mask_material: ShaderMaterial
var _mask_image: Image
var _mask_texture: ImageTexture

const FOG_TILE_SIZE := 5.0
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
	reveal_around(main.hive.position, START_CLEAR_RADIUS)

## Part of main's public surface for this system: called once from
## main._process each frame.
func _update() -> void:
	if not GameConfig.fog_of_war_on:
		if _layer.visible:
			_layer.visible = false
		_last_layer_visible = false
		return
	var just_shown: bool = not _last_layer_visible
	_layer.visible = true
	_last_layer_visible = true

	Perf.begin("fog_of_war_update")
	var dirty: bool = just_shown
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
		_last_draw_permanent = GameConfig.fog_permanent_reveal

## True once the camera's moved, zoomed, or `fog_permanent_reveal` has
## flipped since the last frame we actually redrew.
func _camera_view_changed() -> bool:
	var cam: Camera2D = main.camera_view._active_camera()
	return (
		cam.position != _last_draw_cam_pos
		or cam.zoom.x != _last_draw_cam_zoom
		or GameConfig.fog_permanent_reveal != _last_draw_permanent
	)

## Rebuilds the shared offset disc only when the reveal radius has
## actually changed (it's a live-tunable debug-panel slider).
func _ensure_disc_offsets() -> void:
	var radius: float = GameConfig.fog_reveal_radius
	if radius == _disc_offsets_radius and not _disc_offsets.is_empty():
		return
	_disc_offsets.clear()
	var span: int = int(ceil(radius / FOG_TILE_SIZE))
	for dx in range(-span, span + 1):
		for dy in range(-span, span + 1):
			if Vector2(dx, dy).length() * FOG_TILE_SIZE > radius:
				continue
			_disc_offsets.append(Vector2i(dx, dy))
	_disc_offsets_radius = radius

## Recomputes and swaps in the disc centre bee `id` currently lights.
func _relight(id: int, pos: Vector2) -> void:
	_ensure_disc_offsets()
	var old: Dictionary = _bee_light.get(id, {})
	if not old.is_empty():
		_light_center(old.center, -1)
	var center: Vector2i = _tile_of(pos)
	_light_center(center, 1)
	_bee_light[id] = {"pos": pos, "center": center}

## Applies the shared disc offsets around `center`, lighting (delta 1) or
## unlighting (delta -1) every tile it covers.
func _light_center(center: Vector2i, delta: int) -> void:
	for off in _disc_offsets:
		var tile: Vector2i = Vector2i(center.x + off.x, center.y + off.y)
		var count: int = _lit_count.get(tile, 0) + delta
		if count <= 0:
			_lit_count.erase(tile)
		else:
			_lit_count[tile] = count
		if delta > 0:
			explored[tile] = true

## Marks a circle of tiles explored without lighting them -- used for the
## starting clearing and for restoring a save.
func reveal_around(pos: Vector2, radius: float) -> void:
	for tile in _disc(pos, radius):
		explored[tile] = true

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
## Performance note (19 Aug 2026, AUDIT_PLAN.md Bundle F): used to walk each
## row merging same-colour tiles into runs and issuing one draw_rect per
## run -- correct, but Bundle C's re-measurement found this the dominant
## frame cost at low zoom regardless (~29ms dynamic reveal, worst frame
## 83ms), because a fog boundary is jagged enough that the view can still
## produce a lot of runs, and each is its own draw call. Replaced with a
## mask texture: one byte per visible tile written into `_mask_texture`
## (0/128/255 for unexplored/explored/lit, read back by
## shaders/fog_mask.gdshader as three alpha bands) and a single
## draw_texture_rect call. Same tiles get walked -- the tile-iteration cost
## this shares with the old version is unchanged -- but the per-run
## draw-call and Rect2/Color churn is gone, replaced by one flat byte-array
## write and one draw call regardless of how jagged the boundary is.
##
## Performance note (19 Aug 2026, later same day): a Day 11 playtest with a
## bigger colony and (likely) a more zoomed-out camera than the earlier
## quick check showed fog_of_war_draw back up to 73-79ms and
## fog_of_war_update up to 74ms -- both far above what the "small scenario"
## check suggested and above Bundle C's own worst-case numbers. Two
## unproven suspects: (1) the byte-array build below still walks every
## visible tile every dirty frame with no early-out for "this whole run is
## the same colour", unlike the old draw_rect version, which skipped
## drawing entirely over transparent (fully explored/permanent-reveal)
## stretches -- so this version may have simply traded "many draw calls"
## for "no cheap case at all" when most of the view is already explored;
## (2) the GPU texture upload in `_update_mask_texture` itself may be the
## expensive part at a large view size, not the CPU-side loop. Split into
## `fog_of_war_draw_build`/`fog_of_war_draw_upload` below rather than
## guessing which -- same instrumentation-before-diagnosis approach as the
## main.gd worst-frame investigation (see AUDIT_PLAN.md Bundle C).
func _draw_fog_body() -> void:
	var cam: Camera2D = main.camera_view._active_camera()
	var span: Vector2 = main.get_viewport_rect().size / cam.zoom.x
	var view: Rect2 = Rect2(cam.position - span * 0.5, span).grow(FOG_TILE_SIZE)

	var min_tile: Vector2i = _tile_of(view.position)
	var max_tile: Vector2i = _tile_of(view.position + view.size)
	var w: int = max_tile.x - min_tile.x + 1
	var h: int = max_tile.y - min_tile.y + 1
	if w <= 0 or h <= 0:
		return

	Perf.begin("fog_of_war_draw_build")
	var data: PackedByteArray = PackedByteArray()
	data.resize(w * h)
	var i: int = 0
	for cy in range(min_tile.y, max_tile.y + 1):
		for cx in range(min_tile.x, max_tile.x + 1):
			var tile: Vector2i = Vector2i(cx, cy)
			if _lit_count.has(tile):
				data[i] = MASK_LIT
			elif explored.has(tile):
				data[i] = MASK_EXPLORED
			else:
				data[i] = MASK_UNEXPLORED
			i += 1
	Perf.end("fog_of_war_draw_build")

	Perf.begin("fog_of_war_draw_upload")
	_update_mask_texture(w, h, data)
	_mask_material.set_shader_parameter("permanent_reveal", GameConfig.fog_permanent_reveal)
	var dest: Rect2 = Rect2(Vector2(min_tile) * FOG_TILE_SIZE, Vector2(w, h) * FOG_TILE_SIZE)
	_layer.draw_texture_rect(_mask_texture, dest, false)
	Perf.end("fog_of_war_draw_upload")

## Rebuilds `_mask_image`/`_mask_texture` only when the visible tile span's
## size changes (camera zoom); an unchanged size just overwrites the pixel
## data in place instead of reallocating an Image/Texture2D every dirty
## frame. Also (re)binds `mask_tex` on the shader -- `draw_texture_rect`
## in `_draw_fog_body` feeds the built-in TEXTURE sampler, not a custom
## uniform, so the shader would otherwise read an unset `mask_tex` (an
## opaque-white fallback -- reads as "fully lit," hiding fog everywhere)
## instead of this texture.
func _update_mask_texture(w: int, h: int, data: PackedByteArray) -> void:
	if _mask_image == null or _mask_image.get_width() != w or _mask_image.get_height() != h:
		_mask_image = Image.create_from_data(w, h, false, Image.FORMAT_R8, data)
		_mask_texture = ImageTexture.create_from_image(_mask_image)
		_mask_material.set_shader_parameter("mask_tex", _mask_texture)
	else:
		_mask_image.set_data(w, h, false, Image.FORMAT_R8, data)
		_mask_texture.update(_mask_image)

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
