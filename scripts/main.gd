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

# --- signals ------------------------------------------------------
## Slice 5 (persistence/event boundaries, CHATGPT_EFFICIENCY_
## IMPLEMENTATION_PLAN.md). Each is emitted once at its existing single
## mutation chokepoint -- these replace three direct cross-script calls
## that used to reach straight into main.gd (bee_died) or straight out to
## hud.gd (day_changed), and give rain a defined boundary even though
## nothing else listens yet. saving.gd::_restore() must never emit any of
## these: a load sets state directly and rebuilds caches once at the end
## (invalidate_index(), _update_population_readout()) rather than
## replaying events.
signal bee_died(bee: Node2D)
signal day_changed(day: int)
signal rain_changed(raining: bool)

# --- preloads and boot constants ----------------------------------
const Bee = preload("res://scripts/bee.gd")
const Roles = preload("res://scripts/roles.gd")
const Hive = preload("res://scripts/hive.gd")
const Flower = preload("res://scripts/flower.gd")
const FlowerSpecies = preload("res://scripts/flower_species.gd")
const CrabSpider = preload("res://scripts/crab_spider.gd")
const HiveCell = preload("res://scripts/hive_cell.gd")
const SoilBlock = preload("res://scripts/soil_block.gd")
const Obstacle = preload("res://scripts/obstacle.gd")
const RockBlock = preload("res://scripts/rock_block.gd")
const Hud = preload("res://scripts/hud.gd")
const DebugPanel = preload("res://scripts/debug_panel.gd")
const SavesPanel = preload("res://scripts/saves_panel.gd")
const SettingsCatalogue = preload("res://scripts/settings_catalogue.gd")
const MainMenu = preload("res://scripts/main_menu.gd")
const GameOver = preload("res://scripts/game_over.gd")
const ChallengeComplete = preload("res://scripts/challenge_complete.gd")
const ColonyPanel = preload("res://scripts/colony_panel.gd")
const NurseryPanel = preload("res://scripts/nursery_panel.gd")
const ForagingPanel = preload("res://scripts/foraging_panel.gd")
const DeathMarker = preload("res://scripts/death_marker.gd")
const RainEffect = preload("res://scripts/rain_effect.gd")
const RivalHive = preload("res://scripts/rival_hive.gd")
const SpatialGrid = preload("res://scripts/spatial_grid.gd")
const Season = preload("res://scripts/season.gd")
const UiLayout = preload("res://scripts/ui_layout.gd")
const WinterPanel = preload("res://scripts/winter_panel.gd")
const GallerinPanel = preload("res://scripts/gallerin_panel.gd")
const SuccessionPanel = preload("res://scripts/succession_panel.gd")
const ClickMarker = preload("res://scripts/click_marker.gd")
const SaveGame = preload("res://scripts/save_game.gd")
const Shapes = preload("res://scripts/shapes.gd")
const Levels = preload("res://scripts/levels.gd")
const RunAvailability = preload("res://scripts/run_availability.gd")
const DeveloperOverrides = preload("res://scripts/developer_overrides.gd")
const Availability = preload("res://scripts/availability.gd")
const TutorialCheckpoint = preload("res://scripts/tutorial_checkpoint.gd")
const ScenarioActions = preload("res://scripts/scenario_actions.gd")
const ScenarioPresets = preload("res://scripts/scenario_presets.gd")
const PlayerProfile = preload("res://scripts/player_profile.gd")

## Every boot's RNG seed, scenario or manual play alike -- see _ready().
## A scenario's own "random_seed" field (CHATGPT_INSIGHTS_PLAN.md's A2)
## overrides this; DiagnosticLog logs whichever value actually ends up
## seeding a given run.
const DEFAULT_RANDOM_SEED := 12345

# --- delegate systems ---------------------------------------------
## The six files this script delegates to. Each is a plain Node with a
## `main` field pointing back here; none of them are added to the scene
## via Main.tscn, since main.gd is still the only node the scene defines
## -- they're created and parented in _ready() instead, same as the HUD
## or the camera.
const WorldBuilding = preload("res://scripts/world_building.gd")
const Saving = preload("res://scripts/saving.gd")
const SaveSlots = preload("res://scripts/save_slots.gd")
const InputSelection = preload("res://scripts/input_selection.gd")
const OrdersZones = preload("res://scripts/orders_zones.gd")
const ForagingStats = preload("res://scripts/foraging_stats.gd")
const YearWinter = preload("res://scripts/year_winter.gd")
const ColonyMilestones = preload("res://scripts/colony_milestones.gd")
const Pollination = preload("res://scripts/pollination.gd")
const CameraView = preload("res://scripts/camera_view.gd")
const FogOfWar = preload("res://scripts/fog_of_war.gd")
const StageGate = preload("res://scripts/stage_gate.gd")
const ChallengeRunner = preload("res://scripts/challenge_runner.gd")

var world_building: Node
var saving: Node
var input_selection: Node
var orders_zones: Node
var foraging_stats: Node
var year_winter: Node
## CR-2: the Colony Run's milestone evaluator. Idle in any other run.
var colony_milestones: ColonyMilestones
## PP-1: the Pollinator Points and Pollination Contribution ledger.
var pollination: Pollination
var camera_view: Node
var fog_of_war: Node
var stage_gate: Node
var challenge_runner: Node
var debug_panel: Node
## The Saves window (RR-2): built beside debug_panel so the menu's Saves...
## works on a fresh boot, before any run (or hud) exists.
var saves_panel: CanvasLayer

# --- world and meadow constants -----------------------------------
const HIVE_WORLD_OFFSET := Vector2(20000, 0)
const HIVE_INTERIOR_CENTRE := Vector2(20400, 280)
## A rectangular field rather than a radial one -- a uniform-angle,
## sqrt-distance scatter (the previous approach) always reads as a disc
## no matter how it's tuned. Rectangular + clustered breaks that up.
##
## Widened alongside the jump from 250 to 500 flowers (see
## GameConfig.flower_count) so the meadow spreads out rather than just
## getting denser -- roughly double the area, same rough density.
## Widened again 23 Aug 2026 to match the grass background (4000x3000):
## Dave wanted more variation between good and bad patches, so this went
## up further than flower_count did -- area is ~2.24x, flower_count only
## ~1.6x, so density is deliberately lower than before.
const FLOWER_FIELD_HALF_SIZE := Vector2(2000.0, 1500.0)
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

# --- state --------------------------------------------------------
var meadow_root: Node2D
var hive_root: Node2D
var meadow_camera: Camera2D
var hive_camera: Camera2D
var selection_layer: Node2D

var hive: Node2D
var hud: CanvasLayer
var queen: Node2D
var game_over: CanvasLayer
var challenge_complete: CanvasLayer
var colony_panel: CanvasLayer
var nursery_panel: CanvasLayer
var foraging_panel: CanvasLayer
var winter_panel: CanvasLayer
var gallerin_panel: CanvasLayer
## COL-10: explains a gyne's takeover from a dead queen.
var succession_panel: CanvasLayer
var rival: Node2D = null
## The year: seasons, disease, winter and gynes leaving.
var season: Node2D = null
var colony_lost: bool = false
## Set the first frame _check_for_loss sees a live queen, so a run that
## has not built one yet is told apart from one whose queen has died.
var queen_seen_alive: bool = false

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

var warning_check_timer: float = 5.0 + randf()
## The periodic sweeps below are each given a random starting phase.
## Every one of them walks the whole colony or the whole comb, and when
## their timers align they all land on one frame, which reads as an
## intermittent stutter rather than as a slower game. Spread out, the
## same work costs the same and no single frame carries it all.
var signal_timer: float = randf()

var in_hive_view: bool = false
var selected_bees: Array = []
## The bee the "Follow bee" command tray toggle is tracking, if any --
## see camera_view.gd::_handle_follow. Cleared on every selection change
## (hud.gd's follow_bee_toggled(null, false) emit) and self-clears if the
## bee dies mid-follow.
var following_bee: Node2D = null
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

## Dev-only headless playtest path (AI_PLAYTEST_PLAN.md). Set by
## _apply_scenario_boot_arg() when launched with --scenario=<path>;
## scenario_stop_max_days stays -1 (never triggers) unless the scenario
## file's "stop.max_days" says otherwise.
var scenario_active: bool = false
## PP-1: a scenario file's "pollination_log": true asks pollination.gd for
## one session-log line per flower visit and hive entry. Off unless asked,
## so every other scenario's action log is unchanged.
var scenario_pollination_log: bool = false
var scenario_stop_max_days: int = -1
## A "stop.when" dict (CHATGPT_INSIGHTS_PLAN.md's A5) -- the same
## day_at_least/food_stores_at_least/population_at_least/
## event_count_at_least shape an action's own "when"/an "assert"'s
## condition already use (see ScenarioActions._when_met), checked every
## tick so a scenario can end on a real threshold instead of always
## running to max_days. Empty means no such condition is set.
var scenario_stop_when: Dictionary = {}
## True if the scenario's "stop" declares "when_actions_resolved": true --
## ends the run once every entry in scenario_actions has fired (fired, not
## necessarily "accepted" -- see ScenarioActions.run_pending's own
## "_resolved" flag), instead of running on after a strategy script has
## nothing left to do.
var scenario_stop_when_actions_resolved: bool = false
## Dev-only bounded wall-clock profiler window. It observes a pinned scenario
## without changing simulation timing or player settings.
var scenario_performance_capture: Dictionary = {}
## A scenario's "actions" array (the headless action driver;
## docs/headless-run-contract.md) -- see scenario_actions.gd for the
## verbs/triggers and main.gd::_process for where it's ticked.
var scenario_actions: Array = []

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
## CR-2: the stores at each day boundary, for conditions.gd's net_income rate
## key -- {day, nectar, pollen, nectar_collected, pollen_collected}, one per
## new day, keeping the last DAY_STORE_SAMPLES. Neither history_samples (a
## fixed count of 5 s samples for the colony window's plot, whose span moves
## with the day length) nor rate_samples (60 s of lifetime collection) holds a
## whole day, so this is its own series. Not saved: after a load the window
## refills over the next few days.
const DAY_STORE_SAMPLES := 8
var day_store_totals: Array = []
var cluster_centers: Dictionary = {}   # species name -> Array[Vector2]
var microhabitat_zones: Dictionary = {}   # microhabitat name -> Array[{"centre": Vector2, "radius": float}]
var panning: bool = false          # middle mouse button held
var pan_anchor: Vector2 = Vector2.ZERO

## "Click a spot" placement: the id of the one tool armed from the HUD ("" =
## none). While one is active the next left click in the relevant view is
## consumed as the placement rather than a normal select/drag. The catalogue
## is input_selection.gd::PLACEMENT_TOOLS.
var active_placement_tool: String = ""
## Bees each tool captured when armed; cleared with the tool.
var pending_builder_bees: Array = []
var pending_home_bees: Array = []
var pending_mine_bees: Array = []
var pending_mine_target_bees: Array = []
var pending_forage_bees: Array = []
var pending_preference_bees: Array = []

# --- _ready and construction --------------------------------------
## BS-14 (plans/now/brood-spine.md): the level definition this run's
## availability sheet is built from. A loaded save's policy
## (Session.pending_skill_policy, put back by SaveGame.apply_skill_policy)
## replaces the level's own skill_grants and skill_bans when it belongs to
## this level; it is cleared either way, so the next new run reads the
## overrides file again. Otherwise BS-6's developer edits apply when
## `developer_edits_allowed`, and the run is tagged when they changed its
## lists. Session records what was chosen, for every save of the run.
## `overrides_path` is for tests.
static func run_definition(level_id: int, developer_edits_allowed: bool, overrides_path: String = DeveloperOverrides.PATH) -> Dictionary:
	var level: Dictionary = Levels.get_level(level_id)
	var saved: Dictionary = Session.pending_skill_policy
	Session.pending_skill_policy = {}
	if not saved.is_empty() and int(saved.get("level", -1)) == level_id:
		var restored: Dictionary = level.duplicate(true)
		restored["skill_grants"] = saved.get("grants", []).duplicate()
		restored["skill_bans"] = saved.get("bans", []).duplicate()
		Session.record_run_skill_policy(restored["skill_grants"], restored["skill_bans"], saved.get("developer_changes", false) == true)
		return restored
	var edited: Dictionary = level
	if developer_edits_allowed:
		edited = DeveloperOverrides.apply(level_id, level, overrides_path)
	var grants: Array = edited.get("skill_grants", [])
	var bans: Array = edited.get("skill_bans", [])
	var changed: bool = str(grants) != str(level.get("skill_grants", [])) or str(bans) != str(level.get("skill_bans", []))
	Session.record_run_skill_policy(grants, bans, changed)
	return edited

func _ready() -> void:
	add_to_group("world")   # so the settings window can find us to save
	process_mode = PROCESS_MODE_ALWAYS   # keep input and camera alive while paused
	Engine.time_scale = 1.0
	seed(DEFAULT_RANDOM_SEED)   # fixed layout while tuning -- delete for a random meadow each run

	# RR-4: the window cannot be made smaller than the floor the UI is laid
	# out for. Set before the menu_pending return below so the pre-run menu
	# is bounded too.
	get_tree().root.min_size = Vector2i(int(UiLayout.MIN_SUPPORTED_WIDTH), int(UiLayout.MIN_SUPPORTED_HEIGHT))

	# Every path back to this function -- a fresh boot, Restart Run, the
	# main menu's level picker, a load, a post-game-over restart -- reloads
	# the whole scene, and tutorial_checkpoint.gd's rolling snapshot is only
	# ever meant to be replayed within the Challenge run that wrote it, not
	# across a reload. Clearing it unconditionally here means every
	# Challenge exit path is covered for free, including ones a future
	# "abandon" button might add, without each of them needing to remember
	# to call this themselves.
	TutorialCheckpoint.clear()

	# Dev-only: --scenario=<path> (AI_PLAYTEST_PLAN.md). Has to run before
	# world_building._build_meadow() below, since that's what actually reads
	# Session.starting_level -- and before menu.open(), since a scenario run
	# skips the main menu entirely.
	_apply_scenario_boot_arg()

	# The main menu sits above everything and pauses the run behind it. It
	# opens by itself the first time the game is launched, and after that
	# only when the player asks for it from the settings window. Built and
	# checked before any world-building below, and standalone (extends
	# CanvasLayer, reads no `main`/world state), so it needs nothing else
	# to exist yet -- letting a fresh boot show only the menu instead of
	# simulating a whole hidden colony behind it (UI-L).
	var menu := MainMenu.new()
	menu.level_chosen.connect(_on_level_chosen)
	menu.scenario_chosen.connect(_on_scenario_chosen)
	add_child(menu)

	# Built here rather than down with the rest of the HUD (UI-M): the
	# menu's own Settings button reaches this panel via the "debug_panel"
	# group to jump straight to Accessibility/Appearance, and that has to
	# work on a fresh boot too, before the early return below. Standalone
	# like MainMenu -- holds no `main` pointer and reaches the rest of the
	# scene lazily via get_tree().get_nodes_in_group() at call time, not at
	# _ready(), so building it this early is safe.
	debug_panel = DebugPanel.new()
	add_child(debug_panel)

	# RR-2: the Saves window is opened from the settings window, which the
	# menu reaches too, so it is built before the early return. It copes
	# with there being no hud or saving node yet (saves_panel.gd).
	saves_panel = SavesPanel.new()
	add_child(saves_panel)

	if Session.menu_pending:
		menu.open()
		return

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
	foraging_stats = ForagingStats.new()
	add_child(foraging_stats)
	year_winter = YearWinter.new()
	year_winter.main = self
	add_child(year_winter)
	colony_milestones = ColonyMilestones.new()
	colony_milestones.main = self
	pollination = Pollination.new()
	pollination.main = self
	camera_view = CameraView.new()
	camera_view.main = self
	add_child(camera_view)
	fog_of_war = FogOfWar.new()
	fog_of_war.main = self
	add_child(fog_of_war)
	stage_gate = StageGate.new()
	stage_gate.main = self
	add_child(stage_gate)
	# The run's skill resolver, built straight after its stage gate so it
	# never exists without one. BS-1: the run's availability sheet is
	# derived once, here, from the level or scenario definition, and the
	# resolver takes its skill policy and starting skills from it. A loaded
	# save replaces the starting skills with the ones it recorded
	# (saving.gd::_restore, after this).
	# BS-6: the developer table's user:// edits to skill_grants/skill_bans.
	# Never in a scenario run (a Challenge fixture keeps level 1 or 2, so
	# the level id alone is not enough) or a headless one, so every fixture
	# and verify.ps1 start exactly as levels.gd and their JSON say. BS-14: a
	# loaded save's own grants and bans win over the file (run_definition).
	var developer_edits_allowed: bool = not scenario_active and Session.starting_level != Levels.SCENARIO_LEVEL_ID and DisplayServer.get_name() != "headless"
	var level: Dictionary = run_definition(Session.starting_level, developer_edits_allowed)
	Session.ensure_progression(stage_gate).begin_run(RunAvailability.sheet_for(level))
	Availability.invalidate()
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
	hud.main = self
	hud.role_requested.connect(orders_zones._on_role_requested)
	hud.view_toggle_requested.connect(camera_view._toggle_view)
	hud.colony_panel_requested.connect(func(): year_winter._toggle_panel(colony_panel))
	hud.foraging_panel_requested.connect(func(): year_winter._toggle_panel(foraging_panel))
	hud.speed_requested.connect(camera_view._on_speed_requested)
	hud.cell_designation_requested.connect(orders_zones._on_cell_designation_requested)
	hud.cell_hatch_role_requested.connect(orders_zones._on_cell_hatch_role_requested)
	hud.cell_hatch_lock_requested.connect(orders_zones._on_cell_hatch_lock_requested)
	hud.cell_empty_requested.connect(orders_zones._on_cell_empty_requested)
	hud.clear_fermented_requested.connect(orders_zones._on_clear_fermented_requested)
	hud.cell_empty_by_bee_requested.connect(input_selection._on_cell_empty_by_bee_requested)
	hud.cell_keep_empty_requested.connect(orders_zones._on_cell_keep_empty_requested)
	hud.cell_gyne_requested.connect(orders_zones._on_cell_gyne_requested)
	hud.placement_tool_requested.connect(input_selection.request_placement_tool)
	hud.restock_targets_requested.connect(orders_zones._on_restock_targets_requested)
	hud.restock_sources_requested.connect(orders_zones._on_restock_sources_requested)
	hud.restock_clear_requested.connect(orders_zones._on_restock_clear_requested)
	hud.soil_mark_requested.connect(input_selection._on_soil_mark_requested)
	hud.keep_clear_clear_requested.connect(input_selection._on_keep_clear_clear_requested)
	hud.cell_priority_requested.connect(orders_zones._on_cell_priority_requested)
	hud.cell_close_requested.connect(orders_zones._on_cell_close_requested)
	hud.cell_fill_close_requested.connect(orders_zones._on_cell_fill_close_requested)
	hud.nursery_window_requested.connect(year_winter._on_nursery_window_requested)
	hud.winter_window_requested.connect(func(): year_winter._toggle_panel(winter_panel))
	hud.signal_clicked.connect(year_winter._on_signal_clicked)
	hud.secondary_role_requested.connect(orders_zones._on_secondary_role_requested)
	hud.finish_first_requested.connect(orders_zones._on_finish_first_requested)
	hud.favourite_requested.connect(orders_zones._on_favourite_requested)
	hud.follow_bee_toggled.connect(camera_view._on_follow_bee_toggled)
	add_child(hud)
	# Syncs Session.perf_enabled and the corner to whatever "fps" was
	# left starred as, rather than assuming a fresh run starts unstarred.
	hud.pinned_stats_changed()
	if not scenario_performance_capture.is_empty():
		# A headless run has no HUD interaction to pin fps. Keep this explicit
		# so a player's saved preference cannot alter a baseline capture.
		Session.perf_enabled = true
		Perf.start_capture(
			int(scenario_performance_capture.warmup_frames),
			int(scenario_performance_capture.measurement_frames),
			scenario_performance_capture.sections,
		)

	# debug_panel itself is built earlier, alongside the menu (UI-L/UI-M) --
	# only this wiring, which needs hud to already exist, waits until here.
	hud.queen_lay_any_cell_toggled.connect(func(value: bool): debug_panel.set_toggle("queen_lays_in_any_cell", value))

	colony_panel = ColonyPanel.new()
	colony_panel.role_selection_requested.connect(input_selection._on_role_selection_requested)
	colony_panel.pinned_changed.connect(func(): hud.pinned_stats_changed())
	colony_panel.favourite_selected.connect(camera_view._focus_on_bee)
	# Same "needing attention" click-to-select handler as the corner
	# problem strip -- one place decides what a signal's action does.
	colony_panel.signal_clicked.connect(year_winter._on_signal_clicked)
	add_child(colony_panel)

	foraging_panel = ForagingPanel.new()
	add_child(foraging_panel)

	nursery_panel = NurseryPanel.new()
	# closing the window has to take the glow off the comb with it,
	# otherwise the hive stays lit up with no panel to explain why
	nursery_panel.closed.connect(orders_zones._clear_zone_glow)
	nursery_panel.pinned_changed.connect(func(): hud.pinned_stats_changed())
	nursery_panel.signal_clicked.connect(year_winter._on_signal_clicked)
	add_child(nursery_panel)

	winter_panel = WinterPanel.new()
	add_child(winter_panel)

	gallerin_panel = GallerinPanel.new()
	add_child(gallerin_panel)

	succession_panel = SuccessionPanel.new()
	add_child(succession_panel)

	season = Season.new()
	season.world = self
	season.winter_started.connect(year_winter._on_winter_started)
	season.winter_survived.connect(year_winter._on_winter_survived)
	season.gyne_released.connect(year_winter._on_gyne_released)
	season.gyne_released.connect(func(_total): colony_milestones.evaluate())
	season.gyne_released.connect(func(_total): colony_milestones.check_victory())
	add_child(season)

	game_over = GameOver.new()
	game_over.restart_requested.connect(_on_restart_after_loss)
	game_over.menu_requested.connect(func(): game_over.visible = false; menu.open())
	add_child(game_over)

	challenge_complete = ChallengeComplete.new()
	challenge_complete.continue_requested.connect(func(): challenge_complete.visible = false; get_tree().paused = false)
	challenge_complete.continue_to_next_requested.connect(func(): _on_level_chosen(2))
	challenge_complete.menu_requested.connect(func(): challenge_complete.visible = false; menu.open())
	challenge_complete.restart_requested.connect(func(): _on_level_chosen(1))
	add_child(challenge_complete)

	hive.storage_changed.connect(func(n, p, h, j): hud.update_storage(n, p, h, j, hive.total_sealed()))
	bee_died.connect(_on_bee_died)
	bee_died.connect(func(_bee): colony_milestones.evaluate())
	day_changed.connect(func(d): hud.update_day(d, year_winter._season_text()))
	# Before the checkpoint, so a day's checkpoint carries that day's milestones.
	day_changed.connect(func(_d): colony_milestones.evaluate())
	day_changed.connect(func(_d): saving.checkpoint())
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
		var loaded: Dictionary = SaveGame.read(Session.load_path)
		Session.control_groups.clear()
		saving._restore(loaded)
		# After the world: a population hook during the replay may have
		# recorded the load day, and the save's own record replaces that.
		colony_milestones.restore(SaveGame.milestone_days(loaded))
		Session.load_path = ""
	elif Session.starting_level in [1, 2]:
		# Both Challenges now have stage data (challenge_runner.gd's
		# STAGES_1/STAGES_2) -- levels.gd's own presets only cover the
		# starting state for either.
		challenge_runner.start()
	# COL-1: the goal shelf's first line in a Colony Run, fresh or loaded.
	colony_milestones.show_next()

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

## bee_died's one connected listener (Slice 5) -- replaces the two direct
## calls bee_survival.gd::die() used to make into this script. Epitaph
## announcement stays a direct call inside die() itself: it's a bee-domain
## concern (throttled by GameConfig.epitaph_min_gap) rather than a
## cross-system reach-through.
func _on_bee_died(bee: Node2D) -> void:
	mark_death(bee)
	invalidate_population()

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
	# _ready() returns early while the pre-run menu is up (UI-L) -- nothing
	# below has been built yet, so there's nothing to sample or step.
	# Godot still calls _process every frame regardless (process_mode is
	# ALWAYS, precisely so this keeps running once a real session is
	# paused mid-run) -- Session.menu_pending only stays true across
	# this one fresh-boot window, never during an in-run "Return to Main
	# Menu", so this guard cannot affect a live pause.
	if Session.menu_pending:
		return
	_sample_fps()
	# Headless presentation gate (CHATGPT_INSIGHTS_PLAN.md's A6) -- nothing
	# is watching a --scenario= run, so camera following/panning, the
	# selection layer's redraw and the fog-of-war overlay are pure
	# wasted work there. `_apply_scenery_setting` stays outside the gate
	# on purpose: unlike the others it isn't purely cosmetic -- it sets
	# obstacle.solid, which changes bee navigation/collision, so skipping
	# it would violate this project's "presentation may be skipped,
	# simulation may not" rule (CLAUDE.md principle 3) rather than just
	# save a redraw.
	if not scenario_active:
		Perf.begin("camera_pan")
		camera_view._handle_pan(delta)
		camera_view._handle_follow(delta)
		Perf.end("camera_pan")
		selection_layer.queue_redraw()
		fog_of_war._update()
	elif bool(scenario_performance_capture.get("include_fog", false)):
		# Performance captures may opt back into just the fog simulation
		# path. Camera/input presentation stays disabled for headless runs.
		fog_of_war._update()
	Perf.begin("scenery")
	world_building._apply_scenery_setting()
	Perf.end("scenery")

	# HO-14: checked every frame, not only while the run steps. The
	# developer "End the run" trigger kills the queen from the settings
	# window, which pauses the run, and the game-over panel used to wait
	# for an unpause (3 Oct 2026 check pass).
	_check_for_loss()
	if not get_tree().paused:
		Session.sim_time += delta
		var new_day: int = 1 + int(Session.sim_time / max(1.0, GameConfig.seconds_per_day))
		if new_day != day:
			day = new_day
			_sample_day_stores()
			day_changed.emit(day)
			if scenario_active and scenario_stop_max_days >= 0 and day >= scenario_stop_max_days:
				_end_scenario_run("max_days")
				return
		_hatch_ready_brood()
		Perf.begin("housekeeping")
		_reseed_meadow(delta)
		_advance_weather(delta)
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

		DiagnosticLog.tick(delta, self)

		if scenario_active:
			ScenarioActions.run_pending(self, scenario_actions)
			# Early-success stops (CHATGPT_INSIGHTS_PLAN.md's A5) -- a
			# scenario that's already got what it needs shouldn't have to
			# burn the rest of max_days to say so.
			if not scenario_stop_when.is_empty() and ScenarioActions._when_met(self, scenario_stop_when):
				_end_scenario_run("stop_condition_met")
				return
			if scenario_stop_when_actions_resolved and not scenario_actions.is_empty():
				var unresolved: Array = scenario_actions.filter(func(a): return not a.get("_resolved", false))
				if unresolved.is_empty():
					_end_scenario_run("actions_resolved")
					return

	Perf.begin("prune_selection")
	_prune_selection()
	Perf.end("prune_selection")
	if scenario_active and not scenario_performance_capture.is_empty() and Perf.capture_complete():
		_end_scenario_run("performance_capture_complete")

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
		hud.update_fps(Engine.get_frames_per_second(), frame_ms, fps_worst_ms, current_speed)
	fps_worst_ms = 0.0

## Flowers wither on their own; this quietly seeds replacements so the
## meadow stays about as full as `flower_count` without every gap
## refilling instantly.
func _reseed_meadow(delta: float) -> void:
	reseed_timer -= delta
	if reseed_timer > 0.0:
		return
	var interval: float = maxf(GameConfig.flower_regrow_seconds, 0.001)
	var owed: int = floori(-reseed_timer / interval) + 1
	reseed_timer += float(owed) * interval
	var room: int = int(GameConfig.flower_count) - get_tree().get_nodes_in_group("flowers").size()
	var to_seed: int = mini(owed, room)
	while to_seed > 0:
		to_seed -= world_building._seed_flower(false, to_seed)
	if room > 0 and owed > 0:
		world_building._rebuild_flower_grid()
	if dragging:
		selection_layer.queue_redraw()

## A finished brood cell releases a new bee. The cell decides what that
## bee becomes: whatever role you set on it, or a nectar forager by
## default. Because the role lives on the cell, every future egg raised
## there comes out the same way without you touching it again.
func _hatch_ready_brood() -> void:
	Perf.begin("hatch")
	for cell in hive.cells_holding("brood").duplicate():
		if not cell.brood_ready():
			continue
		# A cell with no role named raises an ordinary nectar forager --
		# the safe default, and the thing a colony short of everything
		# else most often needs.
		var role: int = cell.hatch_role if cell.hatch_role >= 0 else Bee.Role.FORAGER
		var focus: String = cell.hatch_focus if cell.hatch_role >= 0 else "nectar"
		var as_gyne: bool = cell.brood_is_gyne
		# COL-9: a drone ignores the cell's role and hatches Idle, and is
		# made a drone here rather than inside world_building.gd's spawn.
		var as_drone: bool = cell.brood_is_drone
		if as_drone:
			role = Bee.Role.IDLE
		_record_emergence(role, focus, as_gyne)
		cell.clear_cell()
		var hatched: Node2D = world_building._spawn_hatched_bee(role, cell, as_gyne, focus)
		if as_drone:
			hatched.become_drone()
		challenge_runner.on_worker_hatched(hatched)
		# Unless the player pinned it, a role set on a cell applies to that
		# one bee and then clears, so a one-off choice doesn't quietly
		# govern everything the cell ever raises. "Keep for every bee" in
		# the cell popup is what locks it in.
		if not cell.hatch_role_locked:
			cell.hatch_role = -1
			cell.bump_display_epoch()
		hive.record_birth()
		_update_population_readout()
		colony_milestones.evaluate()
	Perf.end("hatch")

## CR-2: one sample of the stores per day boundary, taken before day_changed
## is emitted so its listeners (the milestone evaluator) see today's.
func _sample_day_stores() -> void:
	day_store_totals.append({
		"day": day,
		"nectar": hive.total("nectar"),
		"pollen": hive.total("pollen"),
		"nectar_collected": hive.lifetime_nectar_collected,
		"pollen_collected": hive.lifetime_pollen_collected,
	})
	while day_store_totals.size() > DAY_STORE_SAMPLES:
		day_store_totals.pop_front()

## Weather. Rain arrives, builds, sits, and eases off again, so the
## colony gets a warning rather than being switched off mid-flight. The
## intensity is what every other system reads: it waters down the nectar
## standing in open flowers, adds the weight of water to every wingbeat,
## and past `rain_forage_limit` makes a trip cost more than it returns,
## at which point foragers stay in.
func _advance_weather(delta: float) -> void:
	if not Levels.weather_enabled(Session.starting_level):
		Session.rain_intensity = 0.0
		_apply_rain_overlay()
		return

	if rain_seconds_left > 0.0:
		rain_seconds_left -= delta
		if rain_seconds_left <= 0.0:
			rain_target = 0.0
			rain_changed.emit(false)
	else:
		# one roll per in-game day, spread evenly over it
		weather_timer -= delta
		if weather_timer <= 0.0:
			weather_timer = max(10.0, GameConfig.seconds_per_day / 6.0)
			if randf() < GameConfig.rain_chance_per_day / 6.0:
				rain_target = randf_range(0.35, 1.0)
				rain_seconds_left = randf_range(GameConfig.rain_min_seconds, GameConfig.rain_max_seconds)
				rain_changed.emit(true)
				hud.show_warning(
					"Rain is coming in. Nectar in the open flowers is being watered down, wet wings cost more to fly on, and if it gets heavy enough your foragers will stay at the hive.",
					"", 0.0, hud.SEVERITY_NOTICE
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

## The queen is the only bee that can lay. When she dies the oldest adult
## gyne takes her place (COL-10, _promote_gyne_to_queen); only with no
## gyne to succeed her does losing her end the run. Checked here rather
## than from the bee itself because a dying bee frees itself, and main.gd
## is what holds the reference worth watching.
##
## The promotion comes before colony_lost is set, in the same frame the
## old queen's reference goes invalid, so a run with a gyne never shows
## the game-over screen and then carries on.
##
## HO-10: this used to open with `queen == null`, meant to skip a run with
## no queen yet. But a freed Object compares equal to null in Godot 4, so
## the moment she died and freed herself the guard returned early, every
## frame, and the run carried on without her. Whether a queen ever lived
## is now remembered instead (queen_seen_alive), and only
## is_instance_valid() is asked about the reference itself.
func _check_for_loss() -> void:
	if colony_lost:
		return
	if is_instance_valid(queen):
		queen_seen_alive = true
		return
	if not queen_seen_alive:
		return
	if _promote_gyne_to_queen():
		return
	colony_lost = true
	if scenario_active:
		_end_scenario_run("collapsed")
		return
	DiagnosticLog.end_session("collapsed")
	game_over.open(
		day,
		get_tree().get_nodes_in_group("bees").size(),
		hive.total("nectar"),
		hive.total_honey(),
	)

## COL-10. The oldest adult gyne still with the colony becomes its queen:
## hatched (brood is a cell, not a bee) and not leaving or dying, which
## is_dying covers -- a gyne who flew off to found a colony is still a
## valid node until the end of that frame. She takes over unmated, so
## she lays drones (COL-9) until she mates, and the succession window
## says so once. Returns false when there is no gyne to promote.
func _promote_gyne_to_queen() -> bool:
	var heir: Node2D = null
	for bee in get_tree().get_nodes_in_group("bees"):
		if not is_instance_valid(bee) or not bee.is_gyne or bee.is_dying:
			continue
		if heir == null or bee.age_seconds > heir.age_seconds:
			heir = bee
	if heir == null:
		return false
	heir.become_queen()
	queen = heir
	_update_population_readout()
	year_winter._close_other_left_windows(succession_panel)
	succession_panel.open_for(heir)
	return true

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

	hud.show_warning(
		"%d of your %d bees (%d%%) are below %d%% energy. The colony is burning nectar faster than it is bringing it in — put more bees on nectar foraging, or they will start to starve."
		% [hungry, bees.size(), int(share * 100.0), int(GameConfig.low_energy_warning_level * 100.0)],
		"low_energy", GameConfig.low_energy_gap, hud.SEVERITY_DANGER
	)

## Bumped whenever the live population's role assignment changes -- birth
## (bee.gd::setup), death (bee_survival.gd::die) or role change
## (bee.gd::_apply_role) -- so `_role_counts()` below knows its cache is
## stale. Same "epoch, not per-frame" shape as hive.gd's
## index_epoch/mining_work_epoch.
var _population_epoch: int = 0

func invalidate_population() -> void:
	_population_epoch += 1

var _role_counts_cache: Dictionary = {}
var _role_counts_built_epoch: int = -1

## The live population, keyed by job. Shared by the colony window, the
## nursery ring and the corner readouts so they can't drift apart. Cached
## against `_population_epoch`: challenge_runner.gd asks this several
## times over the course of one stage-check, so a repeat ask gets the
## same scan rather than repeating the group walk.
func _role_counts(bees = null) -> Dictionary:
	if _role_counts_built_epoch == _population_epoch:
		return _role_counts_cache
	var counts := {}
	var list: Array = bees if bees != null else get_tree().get_nodes_in_group("bees")
	for b in list:
		if not is_instance_valid(b):
			continue
		var key: String = Roles.count_key(b.role, b.resource_type)
		counts[key] = int(counts.get(key, 0)) + 1
	_role_counts_cache = counts
	_role_counts_built_epoch = _population_epoch
	return _role_counts_cache

## `bees` lets a caller pass an explicit list instead of a live group query
## -- saving.gd's restore path uses this, since a mid-frame group query
## would still catch the just-retired old bees alongside their replacements.
func _update_population_readout(bees = null) -> void:
	invalidate_population()
	var counts: Dictionary = _role_counts(bees)
	var nectar_foragers: int = int(counts.get(Roles.count_key(Roles.FORAGER, "nectar"), 0))
	var pollen_foragers: int = int(counts.get(Roles.count_key(Roles.FORAGER, "pollen"), 0))
	var miners: int = int(counts.get(Roles.count_key(Roles.MINER), 0))
	var nurses: int = int(counts.get(Roles.count_key(Roles.NURSE), 0))
	var builders: int = int(counts.get(Roles.count_key(Roles.COMB_WORKER), 0))
	var honey_makers: int = int(counts.get(Roles.count_key(Roles.HONEY), 0))
	hud.update_population(nectar_foragers, pollen_foragers, nurses, builders, miners, honey_makers)

## Records what just came out of the comb, for the nursery window's
## emergence rates. Keyed the same way the population counts are, so the
## two line up row for row.
func _record_emergence(role: int, focus: String, as_gyne: bool) -> void:
	var key: String = "gyne"
	if not as_gyne:
		key = Roles.count_key(role, focus)
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
	Session.run_name = SaveSlots.fresh_run_name("My colony")
	Session.starting_level = level
	Session.menu_pending = false
	Session.reset_run_state()
	get_tree().paused = false
	Engine.time_scale = 1.0
	get_tree().reload_current_scene()

## Scenario counterpart of _on_level_chosen -- also applies the chosen
## difficulty preset to GameConfig before the reload, and records that
## this level+preset combination has been played (UI_PLAN.md section 12,
## slice 6). The preset write has to land before reload_current_scene()
## rebuilds the world, since world_building.gd reads GameConfig at boot.
func _on_scenario_chosen(level: int, preset_key: String, custom_overrides: Dictionary) -> void:
	SettingsCatalogue.reset_config_keys(ScenarioPresets.keys_to_reset(preset_key, custom_overrides))
	ScenarioPresets.apply(preset_key, custom_overrides)
	PlayerProfile.mark_scenario_played(level, preset_key)
	Session.run_name = SaveSlots.fresh_run_name("My colony")
	Session.starting_level = level
	Session.menu_pending = false
	Session.reset_run_state()
	get_tree().paused = false
	Engine.time_scale = 1.0
	get_tree().reload_current_scene()

## Dev-only headless playtest path -- see AI_PLAYTEST_PLAN.md. Never
## reachable from the main menu; only ever set by a --scenario= argument on
## the actual command line the process was launched with. The JSON is
## applied through levels.gd's existing LEVELS shape (via Levels.get_level),
## plus a "config_overrides" block applied to GameConfig -- see
## Levels.apply_config_overrides for the per-field allowlist check -- and an
## optional "time_scale" field (defaults to 30x, see slice 3 below).
func _apply_scenario_boot_arg() -> void:
	var scenario_path: String = ""
	# --run-id=: the headless harness's own per-launch identifier
	# (CHATGPT_INSIGHTS_PLAN.md's A1), not a scenario JSON field -- it names
	# this process's launch, not the scenario. Optional; a manual
	# --scenario= launch with no --run-id still works, same as before.
	var run_id: String = ""
	# --random-seed=: run_scenario.py's own per-launch override
	# (CHATGPT_INSIGHTS_PLAN.md's A2) -- lets it hand each --repeat
	# iteration a fresh seed without editing the scenario file. Wins over
	# the scenario's own "random_seed" field below when both are given.
	var cmdline_seed: String = ""
	# Created only by tools/run_scenario.py. Keeping the output location off
	# scenario JSON makes concurrent runs unambiguous and cannot grant a
	# scenario fixture arbitrary file-write authority.
	var session_output_path: String = ""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--scenario="):
			scenario_path = arg.substr("--scenario=".length())
		elif arg.begins_with("--run-id="):
			run_id = arg.substr("--run-id=".length())
		elif arg.begins_with("--random-seed="):
			cmdline_seed = arg.substr("--random-seed=".length())
		elif arg.begins_with("--headless-session-path="):
			session_output_path = arg.substr("--headless-session-path=".length())
	if scenario_path.is_empty():
		return

	if not FileAccess.file_exists(scenario_path):
		push_error("--scenario=%s: file not found" % scenario_path)
		return
	var text: String = FileAccess.get_file_as_string(scenario_path)
	var parsed = JSON.parse_string(text)
	if not (parsed is Dictionary):
		push_error("--scenario=%s: not a JSON object" % scenario_path)
		return

	var level: Dictionary = parsed.duplicate(true)
	var performance_capture = level.get("performance_capture", null)
	level.erase("performance_capture")
	scenario_performance_capture = _parse_scenario_performance_capture(performance_capture)
	if performance_capture != null and scenario_performance_capture.is_empty():
		get_tree().quit(2)
		return
	var scenario_diagnostics = level.get("diagnostics", null)
	level.erase("diagnostics")
	var stop: Dictionary = level.get("stop", {})
	level.erase("stop")
	var config_overrides: Dictionary = level.get("config_overrides", {})
	level.erase("config_overrides")
	# A Challenge scenario uses the Challenge's ordinary level setup, but keeps
	# the scenario-only controls below (actions, stop conditions, diagnostics)
	# available to the headless runner. Leaving this absent preserves the
	# existing synthetic scenario level exactly.
	var challenge_id: int = int(level.get("challenge", 0))
	level.erase("challenge")
	# Dev-only headless action driver (docs/headless-run-contract.md)
	# -- see scenario_actions.gd. Not a levels.gd field, same
	# reasoning as stop/config_overrides just above.
	var actions: Array = level.get("actions", [])
	level.erase("actions")
	# Dev-only, not a GameConfig field so it doesn't go through the
	# allowlist in Levels.apply_config_overrides -- see AI_PLAYTEST_PLAN.md
	# slice 3. Default of 30x is the ceiling that slice 3 confirmed holds
	# steady (identical total_deaths/deaths_by_cause/deaths_by_role at
	# 8x/16x/30x on a 30-day level-4-shaped run -- no sign of the large-
	# per-frame-delta overshoot the plan's "open risk" worried about,
	# comfortably past the player-facing 8x speed-control cap). A scenario
	# file can still ask for a different value if a future test finds a
	# scenario class where 30x isn't safe.
	var scenario_time_scale: float = float(level.get("time_scale", 30.0))
	level.erase("time_scale")
	# Same reasoning as time_scale just above: dev-only, describes how much
	# diagnostic data this run records rather than anything about how the
	# game plays, so it bypasses GameConfig/the allowlist entirely rather
	# than going through config_overrides. Optional -- omitted means the
	# ordinary hourly cadence. See DiagnosticLog.snapshot_interval_override.
	var scenario_snapshot_seconds: float = float(level.get("snapshot_seconds", -1.0))
	level.erase("snapshot_seconds")
	# PP-1, dev-only like snapshot_seconds: see scenario_pollination_log.
	scenario_pollination_log = bool(level.get("pollination_log", false))
	level.erase("pollination_log")
	# Dev-only, same reasoning as time_scale/snapshot_seconds above. An
	# explicit field instead of always reusing DEFAULT_RANDOM_SEED (the one
	# every manual-play boot also gets) lets a headless comparison declare
	# the same seed on both sides to cancel randomness out, or -- via
	# --random-seed=, which wins if both are present -- let run_scenario.py
	# hand each --repeat iteration its own fresh seed instead of every
	# repeat replaying identically.
	var scenario_random_seed: int = int(level.get("random_seed", DEFAULT_RANDOM_SEED))
	if cmdline_seed != "":
		scenario_random_seed = int(cmdline_seed)
	level.erase("random_seed")
	# A UI-only scenario (layout/text assertions) has no colony to describe;
	# cells and forager counts remain direct boot fields, while indoor roles
	# read their optional start_count_key from roles.gd.
	for count_key in ["cells", "nectar_foragers", "pollen_foragers"]:
		level[count_key] = level.get(count_key, 0)

	Levels.scenario_override = level
	Levels.apply_config_overrides(config_overrides)
	Session.starting_level = challenge_id if challenge_id in [1, 2] else Levels.SCENARIO_LEVEL_ID
	Session.menu_pending = false
	scenario_active = true
	SaveSlots.use_scratch_root()
	scenario_actions = actions
	scenario_stop_max_days = int(stop.get("max_days", -1))
	scenario_stop_when = stop.get("when", {})
	scenario_stop_when_actions_resolved = bool(stop.get("when_actions_resolved", false))
	Engine.time_scale = scenario_time_scale
	DiagnosticLog.snapshot_interval_override = scenario_snapshot_seconds
	if not DiagnosticLog.configure_scenario_diagnostics(scenario_diagnostics):
		get_tree().quit(2)
		return
	DiagnosticLog.configure_performance_capture(scenario_performance_capture)
	DiagnosticLog.run_id_override = run_id
	DiagnosticLog.session_path_override = session_output_path
	seed(scenario_random_seed)
	DiagnosticLog.scenario_random_seed = scenario_random_seed
	# DiagnosticLog only ever opens a session file off Session.run_reset
	# (see diagnostic_log.gd) -- fired at the end of every reset_run_state(),
	# which a normal boot never calls (only Restart/New Run/Load do). A
	# scenario boot needs the same session file every other run gets, so it
	# has to trigger that itself.
	Session.reset_run_state()
	print("AI playtest: loaded scenario %s (stop.max_days=%s, time_scale=%s, random_seed=%s)" % [scenario_path, scenario_stop_max_days, scenario_time_scale, scenario_random_seed])


func _parse_scenario_performance_capture(raw: Variant) -> Dictionary:
	if raw == null:
		return {}
	if not (raw is Dictionary):
		push_error("scenario performance_capture must be an object")
		return {}
	var allowed := ["warmup_frames", "measurement_frames", "sections", "include_fog"]
	for key in raw:
		if not key in allowed:
			push_error("scenario performance_capture has unknown key: %s" % key)
			return {}
	for required in ["warmup_frames", "measurement_frames", "sections"]:
		if not raw.has(required):
			push_error("scenario performance_capture missing %s" % required)
			return {}
	var warmup = raw.warmup_frames
	var measurement = raw.measurement_frames
	if not _is_whole_number(warmup) or warmup < 0:
		push_error("scenario performance_capture.warmup_frames must be a non-negative integer")
		return {}
	if not _is_whole_number(measurement) or measurement <= 0:
		push_error("scenario performance_capture.measurement_frames must be a positive integer")
		return {}
	if not (raw.sections is Array) or raw.sections.is_empty():
		push_error("scenario performance_capture.sections must be a non-empty array")
		return {}
	var sections: Array = []
	for section in raw.sections:
		if not (section is String) or section.is_empty() or section in sections:
			push_error("scenario performance_capture.sections must contain unique non-empty strings")
			return {}
		sections.append(section)
	var include_fog = raw.get("include_fog", false)
	if not (include_fog is bool):
		push_error("scenario performance_capture.include_fog must be boolean")
		return {}
	return {"warmup_frames": warmup, "measurement_frames": measurement,
		"sections": sections, "include_fog": include_fog}


func _is_whole_number(value: Variant) -> bool:
	return (value is int) or (value is float and is_equal_approx(value, round(value)))

## Ends a headless scenario run the same way a normal loss does --
## DiagnosticLog gets its summary line either way -- but quits the process
## afterwards instead of showing game_over's UI, since nothing is watching
## it. `outcome` matches DiagnosticLog.end_session's existing vocabulary
## ("collapsed" is already used by _check_for_loss; "max_days" and
## "assert_failed" were added for the headless action driver, the latter
## from a failed scenario_actions.gd "assert"; "stop_condition_met" and
## "actions_resolved" are CHATGPT_INSIGHTS_PLAN.md's A5 early-success
## stops). Any action left unresolved (its "when" never met) is logged
## before the summary line, same reasoning as a failed assert: a run
## should say plainly what it couldn't do, not just what it did.
func _end_scenario_run(outcome: String) -> void:
	ScenarioActions.log_unresolved(scenario_actions)
	DiagnosticLog.set_queen_alive(is_instance_valid(queen))
	DiagnosticLog.end_session(outcome)
	if DiagnosticLog.session_path_override != "":
		print("MEADOW_RESULT_PATH=%s" % DiagnosticLog.session_path())
	print("AI playtest: scenario ended (%s) at day %d" % [outcome, day])
	get_tree().quit()

# Note: input_selection.gd defines its own _unhandled_input(event) and is
# added to the tree as a child of this node in _ready() above, so Godot
# calls it directly -- no forwarding needed here. Keeping a second
# _unhandled_input on main.gd as well would process every click, keypress
# and drag twice.
