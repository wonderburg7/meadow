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

## Fully opaque so unexplored ground is genuinely hidden, not just
## darkened -- nothing of the meadow underneath should show through.
const UNEXPLORED_COLOR := Color8(18, 11, 15, 255)
## Explored but no bee nearby right now, when fog_permanent_reveal is
## off: a dim memory of the ground rather than the full black of never
## having seen it, and not fully clear either.
const EXPLORED_DIM_COLOR := Color8(18, 11, 15, 140)

## Called once, after meadow_root and main.hive both exist -- world_building
## builds the meadow before this can run, so main._ready calls this right
## after world_building._build_meadow().
func _build_layer() -> void:
	_layer = Node2D.new()
	_layer.z_index = 90   # above bees (5) and the rain wash (50), below the selection layer (100)
	_layer.draw.connect(_draw_fog)
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
			_relight(id, b.position)
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
func _draw_fog_body() -> void:
	var cam: Camera2D = main.camera_view._active_camera()
	var span: Vector2 = main.get_viewport_rect().size / cam.zoom.x
	var view: Rect2 = Rect2(cam.position - span * 0.5, span).grow(FOG_TILE_SIZE)

	var min_tile: Vector2i = _tile_of(view.position)
	var max_tile: Vector2i = _tile_of(view.position + view.size)
	var permanent: bool = GameConfig.fog_permanent_reveal

	# Merged into horizontal runs of one colour rather than one draw call
	# per tile -- at this tile size the view can span tens of thousands
	# of them, and a fog boundary is a smooth curve, so most of a row is
	# a single colour either side of it. See the perf note at the top of
	# this file.
	for cy in range(min_tile.y, max_tile.y + 1):
		var run_start: int = min_tile.x
		var run_color: Color = Color(0.0, 0.0, 0.0, 0.0)
		var run_open: bool = false
		for cx in range(min_tile.x, max_tile.x + 2):   # one past the end, to flush the last run
			var color: Color = Color(0.0, 0.0, 0.0, 0.0)
			if cx <= max_tile.x:
				var tile: Vector2i = Vector2i(cx, cy)
				if not _lit_count.has(tile):
					if explored.has(tile):
						color = Color(0.0, 0.0, 0.0, 0.0) if permanent else EXPLORED_DIM_COLOR
					else:
						color = UNEXPLORED_COLOR
			if run_open and color == run_color:
				continue
			if run_open and run_color.a > 0.0:
				var width: float = float(cx - run_start) * FOG_TILE_SIZE
				_layer.draw_rect(Rect2(Vector2(run_start, cy) * FOG_TILE_SIZE, Vector2(width, FOG_TILE_SIZE)), run_color)
			run_start = cx
			run_color = color
			run_open = true

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
