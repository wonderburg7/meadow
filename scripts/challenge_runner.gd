extends Node
## Drives a Challenge run through its sub-stages: checks each stage's
## goal, unlocks the UI the next stage needs, checkpoints the boundary,
## and queues Dr Gallerin's prompts. See TUTORIAL_PLAN.md's "Challenge 1:
## First Stores" section for the design this follows stage by stage.
##
## Only Challenge 1 (level id 1) has stage data so far -- STAGES below is
## exactly its seven sub-stages, 1.1 through 1.7. Challenge 2 stays a
## plain level preset (per levels.gd) until its own stage data is
## written; main.gd only calls start() when Session.starting_level == 1.
##
## Deliberately thin glue: the actual mechanisms (stage_gate.gd,
## tutorial_checkpoint.gd, gallerin_panel.gd) already exist and do their
## one job each. This file only decides *when* to call them, by checking
## a small goal per stage against the live game state.
##
## Challenge 1 has no defined failure condition anywhere in
## TUTORIAL_PLAN.md -- "no lethal pressure... nothing irreversible" -- so
## unlike Challenge 2 (still unbuilt), this runner never calls
## TutorialCheckpoint.restore(). It still writes a checkpoint at every
## stage boundary, both because the plan asks for one regardless and so
## the mechanism is exercised for real ahead of Challenge 2 needing the
## rollback half of it.

const Roles = preload("res://scripts/roles.gd")
const Shapes = preload("res://scripts/shapes.gd")

## How close to the cavity's centre counts as "moved there" for 1.2, and
## how much nectar/pollen counts as a "small" store for 1.5/1.6. All four
## are first guesses -- TUTORIAL_PLAN.md doesn't pin down numbers, and
## these are small enough to reach in a trip or two at default balance
## (a forager's stomach holds 50 nectar or 15 pollen -- see GameConfig).
const CENTRE_RADIUS := 40.0
const NECTAR_TARGET := 30.0
const POLLEN_TARGET := 10.0

## Seconds of no progress before a hint, then a stronger hint -- the
## "Timing pattern" in TUTORIAL_PLAN.md's Dr Gallerin section. Also first
## guesses; easy to retune once this is actually played.
const HINT_DELAY := 20.0
const STRONGER_HINT_DELAY := 45.0

## The normal cell_build_time (90s by default) makes sense once a colony
## has many comb workers splitting the wait -- for a lone queen building
## her very first cell it's just standing around. Overridden for the
## length of the Challenge and restored in _complete().
const FAST_BUILD_TIME := 15.0

## A soft gold ring, distinct from the build-hover/home-cell colours
## already used elsewhere on the comb, shown at the centre while 1.2
## asks the player to move the queen there, and at the entrance while
## 1.4-1.6 want her heading out through it.
const MARKER_COLOUR := Color(1.0, 0.85, 0.3, 0.55)

## Each stage: `goal` is a key _goal_met() switches on. `unlocked_keys` is
## the *cumulative* set of stage_gate keys visible from this stage on
## (role keys and mode keys double as stage_gate keys directly, plus
## "meadow_view" -- see _apply_stage_gate_to_ui). `goal_text` feeds the
## corner readout (hud.gd's set_challenge_goal). `prompts` feeds
## gallerin_panel.queue_prompts() straight through.
const STAGES := [
	{
		"id": "1.1", "goal": "queen_selected", "unlocked_keys": [],
		"goal_text": "Goal: select the queen.",
		"prompts": [
			{"id": "1.1_welcome", "trigger": "welcome", "delay": 0.0, "text": "Ah, there she is. One queen, one possible colony. Start by selecting her -- gently, of course."},
			{"id": "1.1_hint", "trigger": "hint", "delay": HINT_DELAY, "text": "The queen is the large bee in the hive. Select her and we'll see what she can begin."},
		],
	},
	{
		"id": "1.2", "goal": "queen_near_centre", "unlocked_keys": [],
		"goal_text": "Goal: move the queen to the marked centre.",
		"prompts": [
			{"id": "1.2_welcome", "trigger": "welcome", "delay": 0.0, "text": "A good colony begins with a sensible centre. Move her into the open space."},
			{"id": "1.2_hint", "trigger": "hint", "delay": HINT_DELAY, "text": "Try guiding the queen toward the middle of the cavity. It gives the first cell room to matter."},
		],
	},
	{
		"id": "1.3", "goal": "first_cell_built", "unlocked_keys": ["comb_worker"],
		"goal_text": "Goal: build one comb cell.",
		"prompts": [
			{"id": "1.3_welcome", "trigger": "welcome", "delay": 0.0, "text": "Now for architecture. One cell is enough to turn empty space into a beginning."},
			{"id": "1.3_hint", "trigger": "hint", "delay": HINT_DELAY, "text": "Press \"Build cell\" in the queen's panel to place one in the open centre. The colony needs somewhere to put what it gathers."},
		],
	},
	{
		"id": "1.4", "goal": "meadow_view_opened", "unlocked_keys": ["comb_worker", "meadow_view"],
		"goal_text": "Goal: switch to the meadow view.",
		"prompts": [
			{"id": "1.4_welcome", "trigger": "welcome", "delay": 0.0, "text": "A cell is useful only if there is something to store. Time to look outside."},
			{"id": "1.4_hint", "trigger": "hint", "delay": HINT_DELAY, "text": "Use the meadow view. The flowers are doing the generous part of the work."},
		],
	},
	{
		"id": "1.5", "goal": "nectar_target",
		"unlocked_keys": ["comb_worker", "meadow_view", "forager", "nectar"],
		"goal_text": "Goal: collect a little nectar.",
		"prompts": [
			{"id": "1.5_welcome", "trigger": "welcome", "delay": 0.0, "text": "Nectar first. It is quick energy: sweet, portable, and very persuasive."},
			{"id": "1.5_hint", "trigger": "hint", "delay": HINT_DELAY, "text": "The marked doorway leads to the meadow. Select the queen and assign her the Forager job, or right-click the doorway to send her straight out."},
			{"id": "1.5_stronger", "trigger": "stronger_hint", "delay": STRONGER_HINT_DELAY, "text": "Select the queen and assign her the Forager job -- she'll fly out, find a flower, and bring nectar back on her own."},
		],
	},
	{
		"id": "1.6", "goal": "pollen_target",
		"unlocked_keys": ["comb_worker", "meadow_view", "forager", "nectar", "pollen"],
		"goal_text": "Goal: collect a little pollen.",
		"prompts": [
			{"id": "1.6_welcome", "trigger": "welcome", "delay": 0.0, "text": "Nectar keeps the lights on. Pollen is different: it is protein, and larvae are demanding little parcels of need."},
			{"id": "1.6_hint", "trigger": "hint", "delay": HINT_DELAY, "text": "Try changing the foraging focus. This time, the colony needs pollen."},
		],
	},
	{
		"id": "1.7", "goal": "complete",
		"unlocked_keys": ["comb_worker", "meadow_view", "forager", "nectar", "pollen"],
		"goal_text": "",
		"prompts": [],
	},
]

var main: Node2D
var active: bool = false
var _stage_index: int = 0
var _meadow_view_seen: bool = false
var _marker: Polygon2D
var _original_cell_build_time: float = 0.0

func start() -> void:
	active = true
	_stage_index = 0
	_meadow_view_seen = false
	main.stage_gate.start()

	# Challenge 1 starts in hive view, per TUTORIAL_PLAN.md's start
	# state -- and since the view switch stays hidden until 1.4, there
	# would otherwise be no way back to the hive at all if the run
	# happened to boot into the meadow.
	if not main.in_hive_view:
		main.camera_view._toggle_view()

	# The queen starts at the inner entrance and is walked to the centre
	# marker by the player (1.1-1.2), rather than starting already there.
	main.queen.position = main.hive_entrance_inside()
	# hive_camera's parent is main itself (see world_building.gd's
	# _build_cameras), not hive_root, so it sits in the same coordinate
	# space global_position already resolves to -- no manual offset math
	# needed here the way hive_entrance_inside() has to do for hive_root.
	main.hive_camera.position = main.queen.global_position

	# "No lethal pressure... nothing irreversible" (TUTORIAL_PLAN.md) --
	# the queen can wander, forage slowly or get stuck without the run
	# turning into a death she has to be rescued from. Restored in
	# _complete().
	main.queen.energy_immune = true
	main.hud.set_warnings_muted(true)

	_original_cell_build_time = GameConfig.cell_build_time
	GameConfig.cell_build_time = FAST_BUILD_TIME

	_marker = Polygon2D.new()
	_marker.polygon = Shapes.circle_points(GameConfig.hive_cell_size * 1.6, 24)
	_marker.color = MARKER_COLOUR
	_marker.z_index = 5
	_marker.visible = false
	main.hive_root.add_child(_marker)

	_enter_stage()

func _process(_delta: float) -> void:
	if not active:
		return
	if not main.in_hive_view:
		_meadow_view_seen = true
	if _goal_met(STAGES[_stage_index].goal):
		_advance()

func _enter_stage() -> void:
	var stage: Dictionary = STAGES[_stage_index]
	main.stage_gate.set_unlocked_keys(stage.unlocked_keys)
	_apply_stage_gate_to_ui()
	main.hud.set_challenge_goal(stage.goal_text)
	main.hud.set_queen_build_button_visible(stage.id == "1.3")
	_update_marker(stage.id)
	main.gallerin_panel.queue_prompts(stage.prompts)
	main.TutorialCheckpoint.save(main)

## The marker sits in hive_root, so it's only ever actually seen while
## looking at the hive -- exactly when it's relevant (the meadow-side
## flowers need no such pointer).
func _update_marker(stage_id: String) -> void:
	if stage_id == "1.2":
		_marker.position = main.world_building._hive_centre_local()
		_marker.visible = true
	elif stage_id in ["1.4", "1.5", "1.6"]:
		_marker.position = main.hive_entrance_inside()
		_marker.visible = true
	else:
		_marker.visible = false

func _advance() -> void:
	main.gallerin_panel.clear_queue()
	_stage_index += 1
	if _stage_index >= STAGES.size():
		_complete()
		return
	_enter_stage()

func _complete() -> void:
	active = false
	main.stage_gate.stop()
	_apply_stage_gate_to_ui()
	main.hud.set_challenge_goal("")
	main.hud.set_queen_build_button_visible(false)
	if _marker != null and is_instance_valid(_marker):
		_marker.visible = false
	if is_instance_valid(main.queen):
		main.queen.energy_immune = false
	main.hud.set_warnings_muted(false)
	GameConfig.cell_build_time = _original_cell_build_time
	main.gallerin_panel.clear_queue()
	main.gallerin_panel.show_now({
		"id": "challenge_1_complete", "trigger": "complete", "repeatable": false,
		"text": "Challenge complete: your first stores are in place.\n\nA promising start. One queen, one cell, and enough stored sweetness to suggest this was not a terrible idea.",
	})

## Challenge 1 only -- the queen's panel shows a direct "Build cell"
## button during 1.3 instead of the usual assign-role-then-click-a-spot
## flow (see hud.gd's set_queen_build_button_visible).
##
## Assigns the site directly (hive.create_cell_site_at + target_cell +
## State.TO_BUILD_SITE) rather than going through the usual manual-
## build-queue-then-idle-dispatch route bee.gd's Comb worker uses for a
## player's own placement click. That route needs at least one
## BUILD_IDLE tick to notice the queued target, and once she goes
## BUILD_IDLE again after finishing (bee.gd::_idle_dispatch, Role.BUILDER)
## it also happily starts a brand new cell outward from the centre if
## nothing else is queued -- which is exactly what kept producing a
## second, unfinished cell next to the first no matter how quickly this
## file's own stage-advance logic tried to react afterwards. Setting
## architect_mode to "maintain" *before* she ever starts, rather than
## resetting it after she finishes, closes that off completely: none of
## _idle_dispatch's Role.BUILDER branch ever runs for her while it's set,
## so there's no path back into auto-building regardless of frame timing.
func _on_queen_build_cell_requested() -> void:
	if not is_instance_valid(main.queen):
		return
	main.queen.architect_mode = "maintain"
	main.queen.set_role(main.Bee.Role.BUILDER)
	var site: Node2D = main.hive.create_cell_site_at(Vector2i.ZERO)
	if site:
		main.queen.target_cell = site
		main.queen.state = main.Bee.State.TO_BUILD_SITE

## Pushes the current stage_gate state into hud.gd via its setters,
## rather than hud.gd reading stage_gate directly -- hud.gd stays
## decoupled from main.gd's internals, same as every other signal/setter
## it already uses. Safe to call any time, active or not: is_unlocked()
## already returns true for everything once stage_gate.stop() has been
## called, so the "Challenge finished" case falls out for free.
func _apply_stage_gate_to_ui() -> void:
	main.hud.set_colony_button_visible(main.stage_gate.is_unlocked("colony_window"))
	main.hud.set_nursery_button_visible(main.stage_gate.is_unlocked("nursery_window"))
	main.hud.set_view_button_visible(main.stage_gate.is_unlocked("meadow_view"))
	var role_keys: Array = Roles.ROLES.map(func(r): return r.key)
	main.hud.set_allowed_role_keys(role_keys.filter(func(k): return main.stage_gate.is_unlocked(k)))
	main.hud.set_allowed_mode_keys(["nectar", "pollen"].filter(func(k): return main.stage_gate.is_unlocked(k)))
	main.hud.update_selection(main.selected_bees)

func _goal_met(goal: String) -> bool:
	match goal:
		"queen_selected":
			return main.selected_bees.size() == 1 and main.selected_bees[0] == main.queen
		"queen_near_centre":
			if not is_instance_valid(main.queen):
				return false
			var centre: Vector2 = main.world_building._hive_centre_local()
			return main.queen.position.distance_to(centre) <= CENTRE_RADIUS
		"first_cell_built":
			for cell in main.hive.cells:
				if is_instance_valid(cell) and cell.is_built:
					return true
			return false
		"meadow_view_opened":
			return _meadow_view_seen
		"nectar_target":
			return main.hive.total("nectar") >= NECTAR_TARGET
		"pollen_target":
			return main.hive.total("pollen") >= POLLEN_TARGET
		"complete":
			return true
	return false
