extends Node2D
## Builds and runs the prototype: a meadow of flowers and foragers, and
## a walled hive interior with a hexagonal comb, the queen, nursery
## workers and builders.
##
## Both places simulate all the time. Switching view just moves the
## camera -- nothing pauses when you look away. The two worlds sit far
## apart in the same coordinate space (see HIVE_WORLD_OFFSET) so each
## camera can frame one without seeing the other.
##
## Foragers move between the two: they fly to the hive marker in the
## meadow, then get reparented into the hive view and walk in through
## the entrance to reach a cell. main.gd owns that handover because it
## owns both roots and the entrance geometry (see move_bee_into_hive).
##
## Controls
##   Tab            switch between meadow and hive
##   Space          pause
##   Arrow keys     pan the camera
##   Mouse wheel    zoom
##   Left click     select a bee (Shift to add), or a comb cell -- or drag a box
##   Right click    on a flower: go collect there. on ground: move there
##
## Split 14 Aug 2026 (see MAIN_SPLIT_PLAN.md): this file used to be one
## 2,825-line script. It now holds every field and every method that
## something outside this split touches -- bee.gd, hud.gd, season.gd,
## rival_hive.gd and debug_panel.gd all still reach in exactly the way
## they always did -- plus the per-frame dispatch loop and a handful of
## small helpers shared by more than one of the six new files. Everything
## else moved into world_building.gd, saving.gd, input_selection.gd,
## orders_zones.gd, year_winter.gd and camera_view.gd, each a plain Node
## created below and reached through the fields of the same name. None of
## them hold state of their own (bar two or three private helper vars) --
## they read and write this file's fields through their own `main`
## reference, the same way bee.gd already did.

const Bee = preload("res://scripts/bee.gd")
const Roles = preload("res://scripts/roles.gd")
const Hive = preload("res://scripts/hive.gd")
const Flower = preload("res://scripts/flower.gd")
const HiveCell = preload("res://scripts/hive_cell.gd")
const SoilBlock = preload("res://scripts/soil_block.gd")
const Obstacle = preload("res://scripts/obstacle.gd")
const RockBlock = preload("res://scripts/rock_block.gd")
const Hud = preload("res://scripts/hud.gd")
const DebugPanel = preload("res://scripts/debug_panel.gd")
const MainMenu = preload("res://scripts/main_menu.gd")
const GameOver = preload("res://scripts/game_over.gd")
const ColonyPanel = preload("res://scripts/colony_panel.gd")
const NurseryPanel = preload("res://scripts/nursery_panel.gd")
const DeathMarker = preload("res://scripts/death_marker.gd")
const RainEffect = preload("res://scripts/rain_effect.gd")
const RivalHive = preload("res://scripts/rival_hive.gd")
const SpatialGrid = preload("res://scripts/spatial_grid.gd")
const Season = preload("res://scripts/season.gd")
const WinterPanel = preload("res://scripts/winter_panel.gd")
const GallerinPanel = preload("res://scripts/gallerin_panel.gd")
const ClickMarker = preload("res://scripts/click_marker.gd")
const SaveGame = preload("res://scripts/save_game.gd")
const Shapes = preload("res://scripts/shapes.gd")
const Levels = preload("res://scripts/levels.gd")
const TutorialCheckpoint = preload("res://scripts/tutorial_checkpoint.gd")

## The six files this script delegates to. Each is a plain Node with a
## `main` field pointing back here; none of them are added to the scene
## via Main.tscn, since main.gd is still the only node the scene defines
## -- they're created and parented in _ready() instead, same as the HUD
## or the camera.
const WorldBuilding = preload("res://scripts/world_building.gd")
const Saving = preload("res://scripts/saving.gd")
const InputSelection = preload("res://scripts/input_selection.gd")
const OrdersZones = preload("res://scripts/orders_zones.gd")
const YearWinter = preload("res://scripts/year_winter.gd")
const CameraView = preload("res://scripts/camera_view.gd")
const FogOfWar = preload("res://scripts/fog_of_war.gd")
const StageGate = preload("res://scripts/stage_gate.gd")
const ChallengeRunner = preload("res://scripts/challenge_runner.gd")

var world_building: Node
var saving: Node
var input_selection: Node
var orders_zones: Node
var year_winter: Node
var camera_view: Node
var fog_of_war: Node
var stage_gate: Node
var challenge_runner: Node
var debug_panel: Node

const HIVE_WORLD_OFFSET := Vector2(20000, 0)
const HIVE_INTERIOR_CENTRE := Vector2(20400, 280)
## A rectangular field rather than a radial one -- a uniform-angle,
## sqrt-distance scatter (the previous approach) always reads as a disc
## no matter how it's tuned. Rectangular + clustered breaks that up.
##
## Widened alongside the jump from 250 to 500 flowers (see
## GameConfig.flower_count) so the meadow spreads out rather than just
## getting denser -- roughly double the area, same rough density.
const FLOWER_FIELD_HALF_SIZE := Vector2(1350.0, 990.0)
const FLOWER_MIN_DISTANCE := 90.0     # keep the ground by the hive clear
const MAX_CLUSTERS_PER_SPECIES := 22
## A few large plateaus rather than many small mounds: raised ground is
## meant to reshape how the colony moves across the meadow, which a
## scattering of little bumps doesn't do.
const RAISED_AREA_COUNT := 4
const RAISED_AREA_RADIUS := Vector2(130.0, 240.0)
const TREE_COUNT := 10
const TREE_RADIUS := Vector2(22.0, 34.0)
const OBSTACLE_HIVE_CLEARANCE := 220.0
## How far clear of a tree or plateau a flower is planted. This has to
## stay comfortably above BeeMovement.BLOCK_MARGIN, the hard boundary a bee is
## never allowed inside -- a flower any closer than that would sit in
## ground no bee can stand on, and foragers would queue up against the
## edge trying to reach it forever.
const FLOWER_CLEARANCE := 30.0
const HIVE_MARKER_POSITION := Vector2(620, 330)

## Muted, slightly grey-green so it reads as grass without glowing.
const MEADOW_COLOR := Color(0.44, 0.56, 0.35)
const FLOOR_COLOR := Color(0.78, 0.60, 0.47)

const PAN_SPEED := 420.0
const MIN_ZOOM := 0.4
const MAX_ZOOM := 3.0

const COMB_OVERLAYS := ["", "contents", "fill", "role", "reserved"]
const OVERLAY_NAMES := {
	"": "off",
	"contents": "what each cell holds",
	"fill": "how full each cell is",
	"role": "what each nursery cell raises",
	"reserved": "what each cell is reserved for",
}

const BUILD_ORDER_COLOUR := Color(0.45, 0.85, 1.0)
const MINE_ORDER_COLOUR := Color(1.0, 0.72, 0.30)
const KEEP_CLEAR_COLOUR := Color(0.95, 0.45, 0.45)
## The tile under the cursor while "Build here" is armed, before it's
## clicked -- distinct from BUILD_ORDER_COLOUR so a live hover doesn't
## read as an already-queued tile.
const BUILD_HOVER_COLOUR := Color(0.55, 1.0, 0.65)
## A selected bee's "Work from here" cell -- distinct from the order
## colours since it isn't a queued job, it's a standing reference point.
const HOME_CELL_COLOUR := Color(0.85, 0.65, 1.0)

var meadow_root: Node2D
var hive_root: Node2D
var meadow_camera: Camera2D
var hive_camera: Camera2D
var selection_layer: Node2D

var hive: Node2D
var hud: CanvasLayer
var queen: Node2D
var game_over: CanvasLayer
var colony_panel: CanvasLayer
var nursery_panel: CanvasLayer
var winter_panel: CanvasLayer
var gallerin_panel: CanvasLayer
var rival: Node2D = null
## The year: seasons, disease, winter and gynes leaving.
var season: Node2D = null
var colony_lost: bool = false

## Every bee that has emerged, as {t, key} where key is "role|focus".
## Used for the nursery window's "emerging in the last three minutes"
## figures -- that is the output of the nursery, which is what the zone
## actually controls, rather than what those bees go on to collect.
var emergence_log: Array = []

## Samples of the stores and the population for the colony window's
## history plot.
var history_samples: Array = []
var history_timer: float = randf()

## Built once when the meadow is laid out. Bees consult this constantly
## for steering, and a scene-tree group query per bee per frame was the
## worst-scaling thing in the simulation. Obstacles never move or appear
## mid-run, so one list serves everybody.
var obstacles: Array = []
## Coarse spatial index over the flowers, so "nearest flower" checks a
## handful of buckets instead of all 250. Rebuilt when the meadow is
## reseeded rather than maintained incrementally -- flowers appear and
## die a few times a minute, not per frame.
##
## Deliberately not done for obstacles. There are only fourteen of them,
## and steering asks about them every frame rather than eight times a
## second, so the query cost more than the scan it replaced. See
## bee.gd's _obstacles_towards.
var flower_grid = SpatialGrid.new(200.0)
## Mirrors GameConfig.scenery_on, so the toggle is only acted on when it
## actually changes rather than every frame.
var scenery_shown: bool = true

## Weather. Rain waters down open nectar, makes flying heavier, and past
## a point grounds the foragers entirely.
var weather_timer: float = 0.0
var rain_target: float = 0.0
var rain_seconds_left: float = 0.0
var rain_overlay: ColorRect
var rain_effect: Node2D

## Sim time the low-energy warning was last shown, so it can't nag. -INF
## means it hasn't been shown at all yet this run.
var last_energy_warning: float = -INF
## Same idea for death epitaphs (see BeeSurvival.die) -- a bad night
## shouldn't fire a dozen toasts back to back.
var last_epitaph_time: float = -INF
var warning_check_timer: float = 5.0 + randf()
## The periodic sweeps below are each given a random starting phase.
## Every one of them walks the whole colony or the whole comb, and when
## their timers align they all land on one frame, which reads as an
## intermittent stutter rather than as a slower game. Spread out, the
## same work costs the same and no single frame carries it all.
var signal_timer: float = randf()

var in_hive_view: bool = false
var selected_bees: Array = []
## Comb cells and soil blocks the player has selected. Anything the cell
## or soil popup does applies to the whole list, not just the one clicked.
var selected_cells: Array = []
var selected_blocks: Array = []
var next_bee_id: int = 1
## Set the first time any bee's is_gyne becomes true -- see
## bee.gd::_roll_fact and BEE_INDIVIDUALITY_PLAN.md section 5. Saved
## alongside next_bee_id so a reload can't award "first gyne" twice.
var first_gyne_seen: bool = false
var day: int = 1
var current_speed: float = 1.0

var dragging: bool = false
var drag_start: Vector2 = Vector2.ZERO
var drag_current: Vector2 = Vector2.ZERO

var reseed_timer: float = 0.0
## Rolling window for the top-left rate readout: a sample every 10 sim
## seconds, keeping the last 7 (a 60s span once warmed up). Rate is the
## change across the whole window divided by its length, which is
## steadier than reading the last 10s alone.
var rate_samples: Array = []
var rate_sample_timer: float = 10.0 + randf() * 2.0
var cluster_centers: Dictionary = {}   # species name -> Array[Vector2]
var panning: bool = false          # middle mouse button held
var pan_anchor: Vector2 = Vector2.ZERO

## "Click a spot" placement modes, entered from the HUD. While one is
## active the next left click in the relevant view is consumed as the
## placement rather than a normal select/drag.
var awaiting_build_cell: bool = false
var awaiting_home_cell: bool = false
var awaiting_home_cell_all: bool = false
var awaiting_mine_home: bool = false
var awaiting_mine_target: bool = false
var awaiting_keep_clear: bool = false
var pending_builder_bees: Array = []
var pending_home_bees: Array = []
var pending_mine_bees: Array = []
var pending_mine_target_bees: Array = []
var awaiting_forage_start: bool = false
var pending_forage_bees: Array = []
var awaiting_floral_preference: bool = false
var pending_preference_bees: Array = []

func _ready() -> void:
	add_to_group("world")   # so the settings window can find us to save
	process_mode = PROCESS_MODE_ALWAYS   # keep input and camera alive while paused
	Engine.time_scale = 1.0
	seed(12345)   # fixed layout while tuning -- delete for a random meadow each run

	# Every path back to this function -- a fresh boot, Restart Run, the
	# main menu's level picker, a load, a post-game-over restart -- reloads
	# the whole scene, and tutorial_checkpoint.gd's rolling snapshot is only
	# ever meant to be replayed within the Challenge run that wrote it, not
	# across a reload. Clearing it unconditionally here means every
	# Challenge exit path is covered for free, including ones a future
	# "abandon" button might add, without each of them needing to remember
	# to call this themselves.
	TutorialCheckpoint.clear()

	# The split-out files, created first so everything below can call into
	# them. They hold no state of their own beyond a `main` pointer back
	# here (fog_of_war and stage_gate are the exceptions -- their
	# explored-cells map and unlocked-UI set respectively are real state),
	# so creation order relative to the rest of _ready() only matters in
	# that they have to exist before anything calls them.
	world_building = WorldBuilding.new()
	world_building.main = self
	add_child(world_building)
	saving = Saving.new()
	saving.main = self
	add_child(saving)
	input_selection = InputSelection.new()
	input_selection.main = self
	add_child(input_selection)
	orders_zones = OrdersZones.new()
	orders_zones.main = self
	add_child(orders_zones)
	year_winter = YearWinter.new()
	year_winter.main = self
	add_child(year_winter)
	camera_view = CameraView.new()
	camera_view.main = self
	add_child(camera_view)
	fog_of_war = FogOfWar.new()
	fog_of_war.main = self
	add_child(fog_of_war)
	stage_gate = StageGate.new()
	stage_gate.main = self
	add_child(stage_gate)
	challenge_runner = ChallengeRunner.new()
	challenge_runner.main = self
	add_child(challenge_runner)

	meadow_root = Node2D.new()
	# Main is PROCESS_MODE_ALWAYS (so the camera and HUD keep working
	# while paused), and process_mode is inherited by default -- without
	# pinning these back to normal, every bee and flower under them would
	# silently inherit ALWAYS too and just keep simulating through a
	# pause. This is what made Pause not actually stop anything.
	meadow_root.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(meadow_root)

	hive_root = Node2D.new()
	hive_root.position = HIVE_WORLD_OFFSET
	hive_root.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(hive_root)

	# Cameras first: _build_meadow spawns the starting foragers, and
	# spawning a bee calls into is_on_screen (bee.gd's _update_label,
	# via setup()) before the bee has ever been drawn. is_on_screen
	# reads whichever camera is active, so it has to exist by then --
	# building cameras after the meadow left a null-camera crash on
	# every fresh run. Neither _build_meadow nor _build_hive_interior
	# reads meadow_camera/hive_camera themselves, so moving this earlier
	# changes nothing else about what they do.
	world_building._build_cameras()
	world_building._build_meadow()
	world_building._build_hive_interior()
	fog_of_war._build_layer()   # needs main.hive's position, set by _build_meadow

	# A wash of grey-blue over the meadow while it's raining. Drawn on its
	# own layer beneath the HUD so it tints the world, not the panels.
	var weather_layer := CanvasLayer.new()
	weather_layer.layer = 5
	add_child(weather_layer)
	rain_overlay = ColorRect.new()
	rain_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	rain_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rain_overlay.color = Color(0.35, 0.45, 0.62, 0.0)
	rain_overlay.visible = false
	weather_layer.add_child(rain_overlay)

	# The falling streaks themselves, over the colour wash. Screen-space,
	# so they don't slide about when the camera pans.
	rain_effect = RainEffect.new()
	weather_layer.add_child(rain_effect)


	selection_layer = Node2D.new()
	selection_layer.z_index = 100
	selection_layer.draw.connect(input_selection._draw_selection_box)
	add_child(selection_layer)

	hud = Hud.new()
	hud.focus_requested.connect(input_selection._on_focus_requested)
	hud.role_requested.connect(orders_zones._on_role_requested)
	hud.view_toggle_requested.connect(camera_view._toggle_view)
	hud.colony_panel_requested.connect(func(): year_winter._toggle_panel(colony_panel))
	hud.speed_requested.connect(camera_view._on_speed_requested)
	hud.cell_designation_requested.connect(orders_zones._on_cell_designation_requested)
	hud.cell_hatch_role_requested.connect(orders_zones._on_cell_hatch_role_requested)
	hud.cell_hatch_lock_requested.connect(orders_zones._on_cell_hatch_lock_requested)
	hud.cell_empty_requested.connect(orders_zones._on_cell_empty_requested)
	hud.cell_keep_empty_requested.connect(orders_zones._on_cell_keep_empty_requested)
	hud.cell_gyne_requested.connect(orders_zones._on_cell_gyne_requested)
	hud.build_cell_requested.connect(input_selection._on_build_cell_requested)
	hud.queen_build_cell_requested.connect(challenge_runner._on_queen_build_cell_requested)
	hud.home_cell_requested.connect(input_selection._on_home_cell_requested)
	hud.home_cell_all_requested.connect(input_selection._on_home_cell_all_requested)
	hud.mine_home_requested.connect(input_selection._on_mine_home_requested)
	hud.mine_target_requested.connect(input_selection._on_mine_target_requested)
	hud.keep_clear_requested.connect(input_selection._on_keep_clear_requested)
	hud.restock_targets_requested.connect(orders_zones._on_restock_targets_requested)
	hud.restock_sources_requested.connect(orders_zones._on_restock_sources_requested)
	hud.restock_clear_requested.connect(orders_zones._on_restock_clear_requested)
	hud.soil_mark_requested.connect(input_selection._on_soil_mark_requested)
	hud.cell_zone_requested.connect(orders_zones._on_cell_zone_requested)
	hud.cell_priority_requested.connect(orders_zones._on_cell_priority_requested)
	hud.cell_close_requested.connect(orders_zones._on_cell_close_requested)
	hud.cell_fill_close_requested.connect(orders_zones._on_cell_fill_close_requested)
	hud.nursery_window_requested.connect(year_winter._on_nursery_window_requested)
	hud.winter_window_requested.connect(func(): winter_panel.toggle())
	hud.signal_clicked.connect(year_winter._on_signal_clicked)
	hud.forage_start_point_requested.connect(input_selection._on_forage_start_point_requested)
	hud.secondary_role_requested.connect(orders_zones._on_secondary_role_requested)
	hud.finish_first_requested.connect(orders_zones._on_finish_first_requested)
	hud.floral_preference_requested.connect(input_selection._on_floral_preference_requested)
	hud.favourite_requested.connect(orders_zones._on_favourite_requested)
	add_child(hud)
	# Syncs Session.perf_enabled and the corner to whatever "fps" was
	# left starred as, rather than assuming a fresh run starts unstarred.
	hud.pinned_stats_changed()

	debug_panel = DebugPanel.new()
	add_child(debug_panel)
	hud.queen_lay_any_cell_toggled.connect(func(value: bool): debug_panel.set_toggle("queen_lays_in_any_cell", value))

	# The main menu sits above everything and pauses the run behind it.
	# It opens by itself the first time the game is launched, and after
	# that only when the player asks for it from the settings window.
	var menu := MainMenu.new()
	menu.level_chosen.connect(_on_level_chosen)
	add_child(menu)
	if Session.menu_pending:
		menu.open()

	colony_panel = ColonyPanel.new()
	colony_panel.role_selection_requested.connect(input_selection._on_role_selection_requested)
	colony_panel.pinned_changed.connect(func(): hud.pinned_stats_changed())
	colony_panel.favourite_selected.connect(camera_view._focus_on_bee)
	add_child(colony_panel)

	nursery_panel = NurseryPanel.new()
	# closing the window has to take the glow off the comb with it,
	# otherwise the hive stays lit up with no panel to explain why
	nursery_panel.closed.connect(orders_zones._clear_zone_glow)
	nursery_panel.pinned_changed.connect(func(): hud.pinned_stats_changed())
	add_child(nursery_panel)

	winter_panel = WinterPanel.new()
	add_child(winter_panel)

	gallerin_panel = GallerinPanel.new()
	add_child(gallerin_panel)

	season = Season.new()
	season.world = self
	season.winter_started.connect(year_winter._on_winter_started)
	season.winter_survived.connect(year_winter._on_winter_survived)
	season.gyne_released.connect(year_winter._on_gyne_released)
	add_child(season)

	game_over = GameOver.new()
	game_over.restart_requested.connect(_on_restart_after_loss)
	game_over.menu_requested.connect(func(): game_over.visible = false; menu.open())
	add_child(game_over)

	hive.storage_changed.connect(func(n, p, h, j): hud.update_storage(n, p, h, j, hive.total_sealed()))
	hud.update_day(day, year_winter._season_text())
	hud.update_storage(0, 0, 0, 0)
	hud.update_rates(0.0, 0.0, 0.0)
	hud.set_speed_display(1.0)
	_update_population_readout()
	camera_view._apply_view()

	# A pending load is applied last, over the top of a world that has
	# just been built to the saved settings -- see SaveGame's note on why
	# it replays state rather than restoring a scene tree.
	if Session.load_pending:
		Session.load_pending = false
		saving._restore(SaveGame.read())
	elif Session.starting_level == 1:
		# Only Challenge 1's stages are defined so far (see
		# challenge_runner.gd) -- Challenge 2 stays a plain level preset
		# until its own stage data is written.
		challenge_runner.start()

# --- public surface other scripts call directly -------------------
## bee.gd holds a reference to this node (as `world`) and calls these by
## name; debug_panel.gd finds it via the "world" group and calls
## save_run/begin_winter_countdown the same way. Every one of these is a
## one-line forward to whichever of the six split files now holds the
## real body, so nothing outside this split had to change.

func is_on_screen(node: Node2D) -> bool:
	return world_building.is_on_screen(node)

func hive_entrance_inside() -> Vector2:
	return world_building.hive_entrance_inside()

func entrance_wait_point(side: int) -> Vector2:
	return world_building.entrance_wait_point(side)

func move_bee_into_hive(bee: Node2D) -> void:
	world_building.move_bee_into_hive(bee)

func move_bee_out_of_hive(bee: Node2D) -> void:
	world_building.move_bee_out_of_hive(bee)

func mark_death(bee: Node2D) -> void:
	world_building.mark_death(bee)

func finish_mining(block: Node2D) -> void:
	world_building.finish_mining(block)

func save_run() -> void:
	saving.save_run()

func begin_winter_countdown() -> void:
	year_winter.begin_winter_countdown()

# --- per-frame ----------------------------------------------------
## The Perf sections below (camera_pan, scenery, housekeeping, history,
## prune_selection) were added 19 Aug while chasing a worst-frame spike
## that had no matching cost in any instrumented section -- everything
## main.gd calls straight from here used to run uncovered. Not because
## any one of them turned out to be the culprit necessarily, but so
## `Perf.last_worst_breakdown` (perf.gd) can actually account for the
## whole frame instead of leaving an unexplained gap between the
## worst-ms figure and the sections summed.

func _process(delta: float) -> void:
	_sample_fps()
	Perf.begin("camera_pan")
	camera_view._handle_pan(delta)
	Perf.end("camera_pan")
	selection_layer.queue_redraw()
	Perf.begin("scenery")
	world_building._apply_scenery_setting()
	Perf.end("scenery")
	fog_of_war._update()

	if not get_tree().paused:
		Session.sim_time += delta
		var new_day: int = 1 + int(Session.sim_time / max(1.0, GameConfig.seconds_per_day))
		if new_day != day:
			day = new_day
			hud.update_day(day, year_winter._season_text())
		_hatch_ready_brood()
		Perf.begin("housekeeping")
		_reseed_meadow(delta)
		_advance_weather(delta)
		_check_for_loss()
		_check_colony_energy(delta)
		Perf.end("housekeeping")
		year_winter._refresh_signals(delta)
		Perf.begin("history")
		year_winter._sample_history(delta)
		rate_sample_timer -= delta
		if rate_sample_timer <= 0.0:
			rate_sample_timer = 10.0
			year_winter._sample_rates()
		Perf.end("history")

	Perf.begin("prune_selection")
	_prune_selection()
	Perf.end("prune_selection")

# --- the frame rate readout ----------------------------------------
## Measured off the wall clock rather than off `delta`.
##
## `delta` is the wrong source here for two reasons: the speed controls
## work by changing `Engine.time_scale`, which scales it, and pausing
## stops it entirely. Either would make the reading lie at exactly the
## moment you were trying to use it.
##
## Three numbers are reported, because they answer different questions.
## The average says whether the game is fast enough. The last frame time
## says what that average is made of. The worst frame in the window is
## the one you actually felt: a run that averages 60fps but spends one
## frame in twenty at 50ms reads as choppy while the average still looks
## fine, and that is precisely the failure this game has had.
var fps_last_usec: int = 0
var fps_worst_ms: float = 0.0
var fps_window_start_usec: int = 0
const FPS_WINDOW_USEC := 500000   # report twice a second

func _sample_fps() -> void:
	var now: int = Time.get_ticks_usec()
	if fps_last_usec == 0:
		fps_last_usec = now
		fps_window_start_usec = now
		return
	var frame_ms: float = float(now - fps_last_usec) / 1000.0
	fps_last_usec = now
	fps_worst_ms = max(fps_worst_ms, frame_ms)

	if now - fps_window_start_usec < FPS_WINDOW_USEC:
		return
	fps_window_start_usec = now
	# Sampling costs a subtraction whether or not anyone is looking;
	# rebuilding the corner does not, so that part is skipped unless the
	# readout is actually starred.
	if Session.pinned_stats.has("fps"):
		hud.update_fps(Engine.get_frames_per_second(), frame_ms, fps_worst_ms)
	fps_worst_ms = 0.0

## Flowers wither on their own; this quietly seeds replacements so the
## meadow stays about as full as `flower_count` without every gap
## refilling instantly.
func _reseed_meadow(delta: float) -> void:
	reseed_timer -= delta
	if reseed_timer > 0.0:
		return
	reseed_timer = GameConfig.flower_regrow_seconds
	if get_tree().get_nodes_in_group("flowers").size() < int(GameConfig.flower_count):
		world_building._seed_flower()
		world_building._rebuild_flower_grid()
	if dragging:
		selection_layer.queue_redraw()

## A finished brood cell releases a new bee. The cell decides what that
## bee becomes: whatever role you set on it, or a nectar forager by
## default. Because the role lives on the cell, every future egg raised
## there comes out the same way without you touching it again.
func _hatch_ready_brood() -> void:
	Perf.begin("hatch")
	for cell in hive.cells:
		if not cell.brood_ready():
			continue
		# A cell with no role named raises an ordinary nectar forager --
		# the safe default, and the thing a colony short of everything
		# else most often needs.
		var role: int = cell.hatch_role if cell.hatch_role >= 0 else Bee.Role.FORAGER
		var focus: String = cell.hatch_focus if cell.hatch_role >= 0 else "nectar"
		var as_gyne: bool = cell.brood_is_gyne
		_record_emergence(role, focus, as_gyne)
		cell.clear_cell()
		world_building._spawn_hatched_bee(role, cell, as_gyne, focus)
		# Unless the player pinned it, a role set on a cell applies to that
		# one bee and then clears, so a one-off choice doesn't quietly
		# govern everything the cell ever raises. "Keep for every bee" in
		# the cell popup is what locks it in.
		if not cell.hatch_role_locked:
			cell.hatch_role = -1
		hive.record_birth()
		_update_population_readout()
	Perf.end("hatch")

## Weather. Rain arrives, builds, sits, and eases off again, so the
## colony gets a warning rather than being switched off mid-flight. The
## intensity is what every other system reads: it waters down the nectar
## standing in open flowers, adds the weight of water to every wingbeat,
## and past `rain_forage_limit` makes a trip cost more than it returns,
## at which point foragers stay in.
func _advance_weather(delta: float) -> void:
	if not GameConfig.weather_on:
		Session.rain_intensity = 0.0
		_apply_rain_overlay()
		return

	if rain_seconds_left > 0.0:
		rain_seconds_left -= delta
		if rain_seconds_left <= 0.0:
			rain_target = 0.0
	else:
		# one roll per in-game day, spread evenly over it
		weather_timer -= delta
		if weather_timer <= 0.0:
			weather_timer = max(10.0, GameConfig.seconds_per_day / 6.0)
			if randf() < GameConfig.rain_chance_per_day / 6.0:
				rain_target = randf_range(0.35, 1.0)
				rain_seconds_left = randf_range(GameConfig.rain_min_seconds, GameConfig.rain_max_seconds)
				hud.show_warning(
					"Rain is coming in. Nectar in the open flowers is being watered down, wet wings cost more to fly on, and if it gets heavy enough your foragers will stay at the hive."
				)

	# eased rather than switched, so bees aren't grounded from one frame
	# to the next
	Session.rain_intensity = move_toward(Session.rain_intensity, rain_target, delta * 0.25)
	_apply_rain_overlay()

func _apply_rain_overlay() -> void:
	if rain_overlay == null:
		return
	rain_overlay.color = Color(0.35, 0.45, 0.62, Session.rain_intensity * 0.35)
	var showing: bool = Session.rain_intensity > 0.01 and not in_hive_view
	rain_overlay.visible = showing
	# Rain is only visible from outside. Inside the hive you find out
	# about it the way the colony does -- the foragers stop coming back.
	if rain_effect != null:
		rain_effect.visible = showing

## The queen is the only bee that can lay and there is no succession, so
## losing her ends the run. Checked here rather than from the bee itself
## because a dying bee frees itself, and main.gd is what holds the
## reference worth watching.
func _check_for_loss() -> void:
	if colony_lost or queen == null:
		return
	if is_instance_valid(queen):
		return
	colony_lost = true
	game_over.open(
		day,
		get_tree().get_nodes_in_group("bees").size(),
		hive.total("nectar"),
		hive.total_honey(),
	)

## Warns when the colony as a whole is running on empty. Deliberately
## doesn't pause: it's information, and stopping the game every time
## things got tight would be worse than the problem. It also won't repeat
## for `low_energy_gap` seconds, so a colony that stays hungry gets told
## once and then left alone to be dealt with.
func _check_colony_energy(delta: float) -> void:
	warning_check_timer -= delta
	if warning_check_timer > 0.0:
		return
	warning_check_timer = 5.0

	if Session.sim_time - last_energy_warning < GameConfig.low_energy_gap:
		return

	var bees: Array = get_tree().get_nodes_in_group("bees")
	if bees.size() < 3:
		return   # too small a colony for a proportion to mean anything

	var hungry := 0
	for b in bees:
		if b.energy < GameConfig.energy_capacity * GameConfig.low_energy_warning_level:
			hungry += 1
	var share: float = float(hungry) / float(bees.size())
	if share < GameConfig.low_energy_warning_fraction:
		return

	last_energy_warning = Session.sim_time
	hud.show_warning(
		"%d of your %d bees (%d%%) are below %d%% energy. The colony is burning nectar faster than it is bringing it in — put more bees on nectar foraging, or they will start to starve."
		% [hungry, bees.size(), int(share * 100.0), int(GameConfig.low_energy_warning_level * 100.0)]
	)

## The live population, keyed by job. Shared by the colony window, the
## nursery ring and the corner readouts so they can't drift apart.
func _role_counts() -> Dictionary:
	var counts := {}
	for b in get_tree().get_nodes_in_group("bees"):
		if not is_instance_valid(b):
			continue
		var key: String = "%d|" % b.role
		if b.role == Bee.Role.FORAGER:
			key = "%d|%s" % [b.role, b.resource_type]
		counts[key] = int(counts.get(key, 0)) + 1
	return counts

## `bees` lets a caller pass an explicit list instead of a live group query
## -- saving.gd's restore path uses this, since a mid-frame group query
## would still catch the just-retired old bees alongside their replacements.
func _update_population_readout(bees = null) -> void:
	var foragers := 0
	var nurses := 0
	var builders := 0
	var honey_makers := 0
	var list: Array = bees if bees != null else get_tree().get_nodes_in_group("bees")
	for b in list:
		match b.role:
			Bee.Role.NURSERY:
				nurses += 1
			Bee.Role.BUILDER:
				builders += 1   # comb workers
			Bee.Role.FORAGER:
				foragers += 1
			Bee.Role.HONEY_MAKER:
				honey_makers += 1
	hud.update_population(foragers, nurses, builders, honey_makers)

## Records what just came out of the comb, for the nursery window's
## emergence rates. Keyed the same way the population counts are, so the
## two line up row for row.
func _record_emergence(role: int, focus: String, as_gyne: bool) -> void:
	var key: String = "gyne"
	if not as_gyne:
		key = "%d|%s" % [role, focus] if role == Bee.Role.FORAGER else "%d|" % role
	emergence_log.append({"t": Session.sim_time, "key": key})

func _prune_selection() -> void:
	# cells and blocks can be freed under us -- a mined block, a cell
	# rebuilt on load -- so drop the dead references before anything acts
	# on them
	selected_cells = selected_cells.filter(func(c): return is_instance_valid(c))
	selected_blocks = selected_blocks.filter(func(b): return is_instance_valid(b))

	var before := selected_bees.size()
	selected_bees = selected_bees.filter(func(b): return is_instance_valid(b))
	if selected_bees.size() != before:
		hud.update_selection(selected_bees)
		_update_population_readout()

func _on_restart_after_loss() -> void:
	Session.reset_run_state()
	get_tree().paused = false
	Engine.time_scale = 1.0
	get_tree().reload_current_scene()

func _on_level_chosen(level: int) -> void:
	Session.starting_level = level
	Session.menu_pending = false
	Session.reset_run_state()
	get_tree().paused = false
	Engine.time_scale = 1.0
	get_tree().reload_current_scene()

# Note: input_selection.gd defines its own _unhandled_input(event) and is
# added to the tree as a child of this node in _ready() above, so Godot
# calls it directly -- no forwarding needed here. Keeping a second
# _unhandled_input on main.gd as well would process every click, keypress
# and drag twice.
