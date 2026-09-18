extends Node
## Drives a Challenge run through its sub-stages: checks each stage's
## goal, unlocks the UI the next stage needs, checkpoints the boundary,
## and queues Dr Gallerin's prompts. See TUTORIAL_PLAN.md's "Challenge 1:
## First Stores" and "Challenge 2: Brood, Roles and Expansion" sections
## for the design this follows stage by stage.
##
## Both Challenges share this one file: challenge_stages.gd's Stages.STAGES_1
## is Challenge 1's twenty sub-stages (1.1-1.20), Stages.STAGES_2 is
## Challenge 2's nine (2.1-2.9, per Bundle G's trim -- see STAGES_2's own
## comment there) -- `_stages()` picks between them by `Session.starting_level`.
## Where the two Challenges' shapes actually differ (Challenge 1 walks the queen
## from the entrance to a marker before she can build; Challenge 2 starts
## with comb and cells already in place per levels.gd; Challenge 2 alone
## has a real failure/rescue path) the functions below branch on level id
## rather than trying to force one code path to fit both.
##
## Deliberately thin glue: the actual mechanisms (stage_gate.gd,
## tutorial_checkpoint.gd, gallerin_panel.gd) already exist and do their
## one job each. This file only decides *when* to call them, by checking
## a small goal per stage against the live game state.
##
## Challenge 1 has no defined failure condition anywhere in
## TUTORIAL_PLAN.md -- "no lethal pressure... nothing irreversible" -- so
## it never calls TutorialCheckpoint.restore(); it still writes a
## checkpoint at every stage boundary, both because the plan asks for one
## regardless and so the mechanism was exercised for real ahead of
## Challenge 2 actually needing the rollback half of it. Challenge 2's
## own restore path (2.1 onward, see _check_c2_failure) is the first thing
## that ever calls TutorialCheckpoint.restore() for real -- see its
## comment for what a restore does and doesn't reset.

## Slice 5 (persistence/event boundaries) -- fired once a stage's goal is
## met, naming the stage id just cleared. No listener is connected yet
## (checkpointing happens in _enter_stage(), which also runs for the very
## first stage -- not just on a clear -- so it stays a direct call there
## rather than being folded into this signal); this documents the event
## boundary per the slice's exit criterion.
signal challenge_stage_cleared(stage_id: String)

const Roles = preload("res://scripts/roles.gd")
const Availability = preload("res://scripts/availability.gd")
const Shapes = preload("res://scripts/shapes.gd")
const PlayerProfile = preload("res://scripts/player_profile.gd")
const QueenHeartsVfx = preload("res://scripts/queen_hearts_vfx.gd")
const BeeSpeechBubble = preload("res://scripts/bee_speech_bubble.gd")
const Bee = preload("res://scripts/bee.gd")
## Slice 14: 1.11/1.14's camera-follow and 4x speed belong to the moment the
## queen actually sets off foraging, not to stage entry -- she has to be
## selected to be given the Forager role, and selection clears camera-follow
## (see _apply_stage_gate_to_ui). These are the states that mean "she's on
## her way", so _process() below fires the effects the first time she's seen
## in one of them.
const CHALLENGE1_FORAGE_TRIGGER_STATES = [Bee.State.SEEK_FLOWER, Bee.State.TO_FLOWER, Bee.State.INSPECTING, Bee.State.COLLECTING]
## Stage records, prompt records and static targets/timings for both
## Challenges -- pure data, see challenge_stages.gd's own header.
const Stages = preload("res://scripts/challenge_stages.gd")
const Conditions = preload("res://scripts/conditions.gd")
## Named feedback definitions (stage-clear, warning/toast prompts) -- see
## challenge_feedback.gd's own header.
const Feedback = preload("res://scripts/challenge_feedback.gd")

var main: Node2D
var active: bool = false
var _stage_index: int = 0
var _marker: Polygon2D
## Presentation belongs to the marker's owner too: the tween is created when
## the marker becomes visible and is always killed with it, so a completed
## stage cannot leave an invisible tween running.
var _marker_pulse: Tween
## Ordered-point visit state shared by the hive inspection in 1.4 and the
## meadow tour in 1.7. Points stay local to their marker parent so the same
## helper works in either world without hard-coding the two worlds' offset.
var _visit_points: Array = []
var _visit_point_index: int = 0
var _visit_marker_parent: Node2D
## True only during 1.1. input_selection.gd rejects right-click commands
## for this queen, while hud.gd keeps her summary visible but hides the
## separate command tray.
var queen_command_locked: bool = false
## Temporary tunnel blocks, ordered from the queen's starting point toward
## the cavity. Invalid entries have been mined and freed.
var _opening_blocks: Array = []
var _opening_started: bool = false
## The previous stage's goal_text, fed to hud.gd's goal shelf as the
## "just completed" line (UI_PLAN.md section 5) -- blank at the very
## first stage, since nothing has been completed yet.
var _last_completed_goal_text: String = ""

## Challenge 2 only -- counters/snapshots reset in _enter_stage() so a
## goal can ask "has this happened since this stage began" rather than
## "is this true right now" (a cell built before 2.9 started shouldn't
## count towards 2.9's own goal). See the "Challenge 2" _goal_check_* methods.
var _c2_nectar_at_stage_entry: float = 0.0
var _c2_nectar_low_seen: float = 0.0
var _c2_cells_built_at_stage_entry: int = 0
var _c2_soil_blocks_at_stage_entry: int = 0
var _c2_nurses_at_stage_entry: int = 0
## Set once the rescue has fired, so a second collapse falls through to
## the ordinary checkpoint restore instead -- gallerin_panel's own
## _shown_ids dedup already stops the *message* repeating, but the
## nectar grant itself needs its own guard.
var _c2_rescue_used: bool = false
## Like the nectar rescue, but needed before 2.2 can be cleared: a colony
## with no pollen cannot raise the pollen Forager that unlocks its recovery.
var _c2_pollen_rescue_used: bool = false
## Stage 2.1 deliberately withholds the rescue. Record the first withheld
## rescue per run without writing the same diagnostic every frame.
var _c2_rescue_suppressed_logged: bool = false

## Challenge 1's first daughter (1.16-1.18) -- the one bee on-screen every
## goal/animation/bubble from here on refers to. Set once, by
## on_worker_hatched(), and never reassigned within a run.
var _new_worker: Node2D = null
var _greeting_active: bool = false
var _greeting_elapsed: float = 0.0
var _greeting_start_angle: float = 0.0
## Counts down from Stages.HEARTS_DURATION once the hatch fires; clears the
## queen's laying_paused the moment it reaches zero. Independent of the
## greeting timer above -- the two beats overlap but don't have to finish
## together.
var _hearts_timer: float = 0.0

## GOAL_CADENCE's "poll"/"event" backstop, seconds remaining to the next 4 Hz
## tick (Slice A4). "frame" goals ignore this and check every _process call
## as before; "poll" goals only check when it fires; "event" goals check
## early too, the moment _goal_checked_index_epoch/_goal_checked_population_epoch
## go stale, with this as the worst-case fallback for the rare event a
## predicate can't reach purely through those two epochs.
const GOAL_POLL_INTERVAL: float = 0.25
var _goal_poll_timer: float = 0.0
## hive.index_epoch/main._population_epoch as last observed at a poll tick,
## so an "event" goal can tell a real change from "nothing moved since we
## last looked" without re-running its own predicate every frame.
var _goal_checked_index_epoch: int = -1
var _goal_checked_population_epoch: int = -1

## Challenge 1 only: the queen gathers at twice her normal rate once the
## automatic-foraging lesson begins. Keep the actual pre-override values so
## traits and debug-tuned rates are restored exactly when the Challenge ends.
var _c1_base_nectar_rate: float = -1.0
var _c1_base_pollen_rate: float = -1.0
## Real count of the queen's completed flower collections during Challenge 1
## -- 1.8/1.9's own goal counter, since flower_cooldowns.size() (bee.gd) also
## grows on a rejected flower and isn't a stage-scoped measurement (Slice 10f).
var _c1_queen_collections: int = 0
## Slice 14: guards the once-per-stage firing of 1.11/1.13's camera-follow
## and speed-up, so _process() doesn't re-trigger them every frame she's
## seen foraging. Cleared on every stage entry, so 1.13 fires its own copy.
var _c1_forage_effects_done: bool = false
## Slice 18: seconds since the pollen-automation stage (1.14) last checked
## its designated cell for stray nectar. Polled rather than event-driven --
## nothing marks the moment a cell becomes wrong, only its steady state --
## and once a second is often enough for a prompt, not a state change.
var _c1_pollen_cell_nectar_elapsed: float = 0.0
## One suffix per actual discarded trip. Gallerin deduplicates non-repeatable
## prompt ids, so this makes the warning visible once for every occurrence.
## Reset at a stage boundary with the other Challenge 1 prompt state.
var _c1_overflow_discard_count: int = 0

func _ready() -> void:
	Session.run_reset.connect(_reset_c2_pollen_rescue)

func _reset_c2_pollen_rescue() -> void:
	_c2_pollen_rescue_used = false

func _stages() -> Array:
	return Stages.STAGES_2 if Session.starting_level == 2 else Stages.STAGES_1

## Read by hud.gd's "waiting for instruction" line -- what the player should
## do at the current stage, or "" outside a Challenge or if unset.
func current_stage_instruction() -> String:
	if not active or _stage_index >= _stages().size():
		return ""
	return str(_stages()[_stage_index].get("instruction", ""))

## Dev/test read surface for scenario assertions. The stage record remains
## private; callers can observe its stable id without reaching into the index.
func current_stage_id() -> String:
	if not active or _stage_index >= _stages().size():
		return ""
	return str(_stages()[_stage_index].id)

## Companion read surface for the settings window's Challenge navigator.
## Keeping the record private means the panel can describe the stage without
## ever becoming another owner of its index or transition state.
func current_stage_goal_text() -> String:
	if not active or _stage_index >= _stages().size():
		return ""
	return str(_stages()[_stage_index].goal_text)

func can_debug_retreat_stage() -> bool:
	return active and _stage_index > 0

func can_debug_advance_stage() -> bool:
	return active and _stage_index < _stages().size() - 1

## Section 11 Phase A step 3: this Challenge's explicit skill-policy
## overrides, straight out of levels.gd's run definition for
## Session.starting_level. Nothing calls this yet -- Phase B step 6 is
## what constructs a Progression resolver for a running game and hands
## it these via set_skill_policy(); every level ships them empty until
## then, so today's call sites (none) would see no override either way.
func run_skill_grants() -> Array:
	return main.Levels.get_level(Session.starting_level).get("skill_grants", [])

func run_skill_bans() -> Array:
	return main.Levels.get_level(Session.starting_level).get("skill_bans", [])

func run_skill_delays() -> Dictionary:
	return main.Levels.get_level(Session.starting_level).get("skill_delays", {})

func start() -> void:
	active = true
	_stage_index = 0
	_c2_rescue_used = false
	_c2_pollen_rescue_used = false
	_c2_rescue_suppressed_logged = false
	_last_completed_goal_text = ""
	main.stage_gate.start()
	# Ordinary save/load doesn't record Challenge stage/gate/prompt state,
	# so a load mid-Challenge would silently drop it -- disabled for the
	# length of the run; tutorial_checkpoint.gd covers Challenge-internal
	# rollback instead. Re-enabled in _complete().
	main.debug_panel.set_save_load_enabled(false)
	main.fog_of_war.permanent_reveal_override = Session.starting_level == 1
	queen_command_locked = false
	_opening_blocks.clear()
	_opening_started = false
	_clear_ordered_visit()
	_new_worker = null
	_greeting_active = false
	_hearts_timer = 0.0
	_goal_poll_timer = 0.0
	_goal_checked_index_epoch = -1
	_goal_checked_population_epoch = -1
	main.awaiting_queen_build_cell = false
	main.queen.player_driven = false
	main.queen.flower_switch_locked = false
	main.queen.role_change_locked = false
	main.queen.role_restricted_to = []
	_c1_base_nectar_rate = -1.0
	_c1_base_pollen_rate = -1.0
	_c1_queen_collections = 0
	_c1_forage_effects_done = false

	if not main.in_hive_view:
		main.camera_view._toggle_view()

	if Session.starting_level == 2:
		# Challenge 2's start state (levels.gd) already has the queen,
		# comb and cells built by world_building.gd -- unlike Challenge 1
		# there's no entrance-to-centre walk to stage, and she may have
		# been left as a Forager by a previous Challenge 1 run, so her
		# role is reset explicitly here (TUTORIAL_PLAN.md's start state).
		main.queen.set_role(main.Bee.Role.EGG_LAYER)
	else:
		# Seal the inner third of the already-built straight entrance and
		# put the queen at its newly exposed face. She mines inward during
		# 1.1; the player takes over only after the cavity opens.
		_setup_opening_tunnel()

	# hive_camera's parent is main itself (see world_building.gd's
	# _build_cameras), not hive_root, so it sits in the same coordinate
	# space global_position already resolves to -- no manual offset math
	# needed here the way hive_entrance_inside() has to do for hive_root.
	main.hive_camera.position = main.queen.global_position

	# "No lethal pressure... nothing irreversible" (Challenge 1) / "forgiving
	# early queen energy" (Challenge 2, TUTORIAL_PLAN.md) -- neither
	# Challenge wants the queen herself dying of neglect. Restored in
	# _complete().
	main.queen.energy_immune = true
	main.hud.set_warnings_muted(true)

	# Clears any checkpoint left behind by a previous Challenge run that
	# was abandoned before reaching _complete() -- belt and braces, since
	# every exit path that doesn't complete the Challenge also reloads the
	# scene (see main.gd's _ready(), which clears this unconditionally),
	# but a fresh start() shouldn't depend on that indirection to be safe.
	main.TutorialCheckpoint.clear()

	_marker = Polygon2D.new()
	_marker.polygon = Shapes.circle_points(GameConfig.hive_cell_size * 1.6, 24)
	_marker.color = Stages.MARKER_COLOUR
	_marker.z_index = 5
	_marker.visible = false
	main.hive_root.add_child(_marker)

	_enter_stage()

func _process(delta: float) -> void:
	if not active:
		return
	_publish_marker_to_hud()
	if Session.starting_level == 1 and _stage_index == 0:
		_drive_opening_mine()
	if Session.starting_level == 1:
		_drive_c1_forage_effects()
		_drive_c1_pollen_cell_nectar_prompt(delta)
	if _greeting_active:
		_drive_greeting(delta)
	if _hearts_timer > 0.0:
		_hearts_timer -= delta
		if _hearts_timer <= 0.0 and is_instance_valid(main.queen):
			main.queen.laying_paused = false
	_goal_poll_timer -= delta
	var goal_tick_due: bool = _goal_poll_timer <= 0.0
	if Session.starting_level == 2:
		if goal_tick_due:
			_c2_nectar_low_seen = min(_c2_nectar_low_seen, main.hive.total("nectar"))
		_check_c2_failure()
		if not active:   # a restore can end the run mid-frame -- see below
			return
	var goal_id: String = _stages()[_stage_index].goal
	var check_goal_now: bool = _should_check_goal(goal_id, goal_tick_due)
	if goal_tick_due:
		_goal_poll_timer = GOAL_POLL_INTERVAL
		_goal_checked_index_epoch = main.hive.index_epoch
		_goal_checked_population_epoch = main._population_epoch
	if check_goal_now and _goal_met(goal_id):
		_advance()

## GOAL_CADENCE's runtime half (Slice A4 -- see the const's own comment for
## the "frame"/"poll"/"event" meanings). `goal_tick_due` is true once every
## GOAL_POLL_INTERVAL seconds, shared with the epoch snapshot above so
## "event" goals fall back to the same cadence as "poll" ones when nothing
## epoch-tracked moved. A goal id absent from GOAL_CADENCE is a data bug --
## tests/source_checks.py catches it before this ever runs -- so this falls
## back to checking every frame rather than silently never firing.
func _should_check_goal(goal_id: String, goal_tick_due: bool) -> bool:
	var cadence: String = GOAL_CADENCE.get(goal_id, "")
	match cadence:
		"frame":
			return true
		"poll":
			return goal_tick_due
		"event":
			return (
				goal_tick_due
				or main.hive.index_epoch != _goal_checked_index_epoch
				or main._population_epoch != _goal_checked_population_epoch
			)
		_:
			push_error("challenge_runner: goal '%s' has no GOAL_CADENCE entry" % goal_id)
			return true

## Challenge 2's soft-failure/rescue, from 2.1 onward (TUTORIAL_PLAN.md's
## "Failure and rescue"). Runs every frame once active, but only actually
## checks anything from stage 2.1 onward -- indices below that never had
## a nectar collapse be possible in the first place. (Since Bundle G, 2.1
## is the very first stage, so this now applies from the start of the run.)
func _check_c2_failure() -> void:
	if _stage_index < _c2_index("2.1"):
		return
	var nectar: float = main.hive.total("nectar")
	var pollen: float = main.hive.total("pollen")

	# Pollen is the price of every new bee. Keep this rescue available through
	# 2.2, but no later: once its pollen Forager exists the player has the
	# recovery route this top-up is meant to preserve.
	if not _c2_pollen_rescue_used and _stage_index <= _c2_index("2.2") and pollen < Stages.c2_pollen_rescue_threshold():
		_c2_pollen_rescue_used = true
		main.hive.deposit("pollen", Stages.c2_pollen_rescue_amount())
		main.gallerin_panel.clear_queue()
		main.gallerin_panel.show_now({
			"id": "challenge_2_pollen_rescue",
			"trigger": "recovery",
			"repeatable": false,
			"text": "A colony without pollen cannot raise any bee at all. I have set a little aside, so you can raise the pollen Forager and restore the supply.",
		})
		return

	# The one-time rescue only ever applies once 2.1 itself is behind us
	# (its own goal *is* "recover from a dip", so a rescue mid-2.1 would
	# short-circuit the very thing it's meant to teach).
	if not _c2_rescue_used and nectar < Stages.C2_RESCUE_THRESHOLD:
		if _stage_index > _c2_index("2.1"):
			_c2_rescue_used = true
			main.hive.deposit("nectar", Stages.C2_RESCUE_AMOUNT)
			main.gallerin_panel.clear_queue()
			main.gallerin_panel.show_now(Feedback.gallerin_prompt("challenge_2_rescue"))
			return
		if _stage_index == _c2_index("2.1") and not _c2_rescue_suppressed_logged:
			_c2_rescue_suppressed_logged = true
			DiagnosticLog.log_action("c2_rescue", _stages()[_stage_index].id, "suppressed", "rescue is withheld during 2.1 by design; nectar %.0f" % nectar)

	if nectar < Stages.C2_FAILURE_FLOOR:
		if not main.TutorialCheckpoint.restore(main):
			push_error("Challenge 2 checkpoint restore failed")
			return
		# A restore replaces main.queen with a new Bee node and rebuilds
		# main.hive.cells from scratch (see saving.gd::_restore) -- nothing
		# here may go on using the pre-restore queen/cell references.
		# _stage_index itself doesn't move: the checkpoint is "the start of
		# this sub-stage", so this re-enters the same stage rather than
		# advancing or regressing it.
		if not is_instance_valid(main.queen):
			push_error("Challenge 2 checkpoint restore left no queen")
			return
		# A restore re-enters the same stage without running its on_exit, so
		# 4x speed or camera-follow active going into the dip would otherwise
		# survive the rescue.
		_run_stage_effects(["camera_follow_off", "speed_multiplier:1.0"])
		main.queen.energy_immune = true
		_c2_nectar_at_stage_entry = main.hive.total("nectar")
		_c2_nectar_low_seen = _c2_nectar_at_stage_entry
		_apply_stage_gate_to_ui()
		_show_goal(_stages()[_stage_index])
		main.gallerin_panel.clear_queue()
		main.gallerin_panel.show_now(Feedback.gallerin_prompt("challenge_2_recovery", "_%d" % _stage_index))

func _c2_index(stage_id: String) -> int:
	for i in range(Stages.STAGES_2.size()):
		if Stages.STAGES_2[i].id == stage_id:
			return i
	return 0

## Keeps trigger metadata local to Challenge stage data. stage_gate.gd remains
## a general string-key store; the trigger explains *why* a Challenge unlocks
## something, but does not change the gate's behaviour yet. "skill" and
## "event" therefore remain documentation hooks for their eventual consumers.
func _stage_unlock_keys(entries: Array) -> Array:
	var keys: Array = []
	for entry in entries:
		if entry is String:
			keys.append(entry)
		elif entry is Dictionary:
			var key: String = entry.get("key", "")
			var trigger: String = entry.get("trigger", "stage")
			if key.is_empty():
				push_error("challenge_runner: unlock descriptor is missing a key: %s" % entry)
				continue
			if trigger not in Stages.UNLOCK_TRIGGER_TYPES:
				push_error("challenge_runner: unknown unlock trigger '%s' for '%s'" % [trigger, key])
				continue
			keys.append(key)
		else:
			push_error("challenge_runner: unlock entry must be a String or Dictionary: %s" % entry)
	return keys

## Challenge 1 lets the queen fall back to nursing from its opening, while
## every other permitted backup role must exactly match the stage's Job gate.
func _queen_allowed_role_ids(entries: Array) -> Array:
	var role_ids: Array = [Roles.QUEEN, Roles.NURSE]
	for key_value in _stage_unlock_keys(entries):
		var role_id: int = Roles.id_for_key(str(key_value))
		if role_id >= 0 and role_id not in role_ids:
			role_ids.append(role_id)
	return role_ids

func _enter_stage() -> void:
	var stage: Dictionary = _stages()[_stage_index]
	queen_command_locked = Session.starting_level == 1 and stage.id == "1.1"
	# Fresh per stage, including after a foraging trip during the waypoint
	# lesson. Entering either automatic-forage stage therefore always arms its
	# own first departure, whatever state the queen used to be in.
	_c1_forage_effects_done = false
	_c1_overflow_discard_count = 0
	_c1_pollen_cell_nectar_elapsed = 0.0
	# The one place player_driven is ever written. A stage that does not
	# declare the key drives nothing, so the flag clears itself on the way
	# out of the manual-forage arc without a matching list to maintain.
	if is_instance_valid(main.queen):
		main.queen.player_driven = stage.get("player_driven", false)
	if Session.starting_level == 1:
		# Challenge 1's manual building drives the queen's state directly;
		# derive her permitted backup work from the same stage keys as the
		# role controls, rather than maintaining a more-permissive copy here.
		# Her own laying role and day-one nursing fallback remain intentional
		# exceptions: neither is taught as a general role at the opening.
		main.queen.role_restricted_to = _queen_allowed_role_ids(stage.unlocked_keys)
		main.queen.role_change_locked = stage.id in ["1.6", "1.7", "1.8", "1.9", "1.10"]
		if stage.id == "1.8":
			_c1_queen_collections = 0
		if stage.id == "1.11":
			# Debug navigation can re-enter this stage. Keep its teaching-rate
			# override idempotent instead of multiplying it again on every pass.
			if _c1_base_nectar_rate < 0.0:
				_c1_base_nectar_rate = main.queen.nectar_collection_rate
				_c1_base_pollen_rate = main.queen.pollen_collection_rate
			main.queen.nectar_collection_rate = _c1_base_nectar_rate * Stages.CHALLENGE1_FORAGE_SPEED_MULTIPLIER
			main.queen.pollen_collection_rate = _c1_base_pollen_rate * Stages.CHALLENGE1_FORAGE_SPEED_MULTIPLIER
	if Session.starting_level == 1:
		main.fog_of_war.set_hive_reveal_mode("queen" if stage.id == "1.1" else "open_space")
	main.stage_gate.set_unlocked_keys(_stage_unlock_keys(stage.unlocked_keys))
	_apply_stage_gate_to_ui()
	_show_goal(stage)
	main.hud.set_queen_build_button_visible(Session.starting_level == 1)
	if stage.id == "1.4":
		_begin_ordered_visit(_hive_inspection_points(), main.hive_root)
	elif stage.id == "1.7":
		_begin_ordered_visit(_meadow_inspection_points(), main.meadow_root)
	else:
		_clear_ordered_visit()
	_update_marker(stage.id)
	if stage.id == "1.19" and is_instance_valid(_new_worker):
		var bubble := BeeSpeechBubble.new()
		_new_worker.get_parent().add_child(bubble)
		bubble.show_text(_new_worker, Stages.FAREWELL_LINE)
	main.gallerin_panel.queue_prompts(stage.prompts)
	# Run on_enter last, not first: _apply_stage_gate_to_ui() above ends in
	# update_selection(), whose first line clears camera-follow, so an effect
	# set any earlier in this function is undone before the stage is done
	# entering. tests/source_checks.py enforces this ordering.
	_run_stage_effects(stage.get("on_enter", []))
	main.TutorialCheckpoint.save(main)

	if Session.starting_level == 2:
		_c2_nectar_at_stage_entry = main.hive.total("nectar")
		_c2_nectar_low_seen = _c2_nectar_at_stage_entry
		_c2_cells_built_at_stage_entry = _built_cell_count()
		_c2_soil_blocks_at_stage_entry = main.get_tree().get_nodes_in_group("soil_blocks").size()
		_c2_nurses_at_stage_entry = main._role_counts().get(Roles.count_key(Roles.NURSE), 0)

func _built_cell_count() -> int:
	var count := 0
	for cell in main.hive.cells:
		if is_instance_valid(cell) and cell.is_built:
			count += 1
	return count

## Shared by both Challenges' laying goals and _goal_progress's numeric
## readout, so the checks never drift apart on what counts as an egg.
func _brood_cell_count() -> int:
	var count := 0
	for cell in main.hive.cells:
		if is_instance_valid(cell) and cell.content_type == "brood":
			count += 1
	return count

## Three deliberately separated floor tiles, all safely inside the guaranteed
## open part of the chamber. Keeping them in axial space makes the tour follow
## the hive geometry if its pixel spacing changes later.
func _hive_inspection_points() -> Array:
	var centre: Vector2 = main.world_building._hive_centre_local()
	var spacing: float = GameConfig.hive_cell_spacing
	var squashed: bool = Session.use_sprite_hex_grid
	return [
		{"position": centre + Shapes.hex_to_pixel(0, -3, spacing, squashed), "radius": Stages.VISIT_POINT_RADIUS},
		{"position": centre + Shapes.hex_to_pixel(-3, 1, spacing, squashed), "radius": Stages.VISIT_POINT_RADIUS},
		{"position": centre + Shapes.hex_to_pixel(3, 0, spacing, squashed), "radius": Stages.VISIT_POINT_RADIUS},
	]

## Three scenic waypoints out from the hive's meadow-side marker (where a
## bee appears the moment she exits) -- Bundle D's reuse of the same
## ordered-visit helper Bundle C built for the hive tour, just parented to
## meadow_root instead of hive_root.
func _meadow_inspection_points() -> Array:
	var origin: Vector2 = main.hive.position
	return [
		{"position": origin + Vector2(220.0, -160.0), "radius": Stages.VISIT_POINT_RADIUS},
		{"position": origin + Vector2(-280.0, 140.0), "radius": Stages.VISIT_POINT_RADIUS},
		{"position": origin + Vector2(140.0, 380.0), "radius": Stages.VISIT_POINT_RADIUS},
	]

## Starts an ordered tour. Each entry owns its arrival radius so a later use
## (Bundle D's meadow tour) can mix broad scenic stops with precise targets.
## Visiting a future point early has no effect: only the current index is ever
## tested by _ordered_visit_complete().
func _begin_ordered_visit(points: Array, marker_parent: Node2D) -> void:
	_visit_points = points.duplicate(true)
	_visit_point_index = 0
	_visit_marker_parent = marker_parent
	_show_current_visit_point()

func _clear_ordered_visit() -> void:
	_visit_points.clear()
	_visit_point_index = 0
	_visit_marker_parent = null

func _ordered_visit_complete(traveller: Node2D) -> bool:
	if _visit_points.is_empty() or not is_instance_valid(traveller):
		return false
	if _visit_point_index >= _visit_points.size():
		return true
	var point: Dictionary = _visit_points[_visit_point_index]
	var target_global: Vector2 = _visit_marker_parent.to_global(point.position)
	if traveller.global_position.distance_to(target_global) > float(point.radius):
		return false
	_visit_point_index += 1
	_show_current_visit_point()
	return _visit_point_index >= _visit_points.size()

func _show_current_visit_point() -> void:
	if _marker == null or not is_instance_valid(_marker):
		return
	if _visit_point_index >= _visit_points.size():
		_set_marker_visible(false)
		return
	if _marker.get_parent() != _visit_marker_parent:
		_marker.reparent(_visit_marker_parent, false)
	_marker.position = _visit_points[_visit_point_index].position
	_set_marker_visible(true)

## Places the shared marker for the current beat. The ordered-visit helper can
## reparent it to either world; Bundle C uses the hive root, and Bundle D can
## reuse the same path in the meadow without adding a second marker. Challenge
## 2 has no single "go here" point, so it never shows one.
func _update_marker(stage_id: String) -> void:
	# The marker's coordinates below are local to one of these two worlds.
	# Select that world before setting them so a prior meadow beat cannot leave
	# a later hive marker stranded at a meaningless meadow-local position.
	var marker_parent: Node2D = null
	if stage_id in ["1.2", "1.5", "1.6", "1.12", "1.15", "1.19"]:
		marker_parent = main.hive_root
	elif stage_id == "1.10":
		marker_parent = main.meadow_root
	if marker_parent != null and _marker.get_parent() != marker_parent:
		_marker.reparent(marker_parent, false)

	if stage_id in ["1.4", "1.7"]:
		_show_current_visit_point()
	elif stage_id in ["1.2", "1.5", "1.12", "1.15"]:
		# The actual site 1.12/1.15 land on spirals out from here rather
		# than sitting exactly on it (see _on_queen_build_cell_requested),
		# but the centre is still the honest "build near here" anchor --
		# same marker 1.5 already uses for the first cell.
		_marker.position = main.world_building._hive_centre_local()
		_set_marker_visible(true)
	elif stage_id in ["1.6", "1.19"]:
		# Both beats are walked from inside the hive view -- the marker
		# points at the interior doorway.
		_marker.position = main.hive_entrance_inside()
		_set_marker_visible(true)
	elif stage_id == "1.10":
		# Unlike 1.6/1.19, this beat is walked from the meadow: point at
		# the hive's meadow-side marker instead of the (meaningless out
		# here) interior doorway coordinate.
		_marker.position = main.hive.position
		_set_marker_visible(true)
	else:
		_set_marker_visible(false)

## Starts/stops the marker's unscaled heartbeat and sends its authoritative
## world state to hud.gd. The HUD deliberately receives no marker node: it
## cannot move or otherwise alter the runner-owned world presentation.
func _set_marker_visible(value: bool) -> void:
	if _marker == null or not is_instance_valid(_marker):
		return
	if _marker.visible == value:
		_publish_marker_to_hud()
		return
	_marker.visible = value
	if value:
		_marker.scale = Vector2.ONE
		_marker_pulse = create_tween()
		_marker_pulse.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		_marker_pulse.set_ignore_time_scale(true)
		_marker_pulse.set_loops()
		_marker_pulse.tween_property(_marker, "scale", Vector2(1.16, 1.16), 0.65) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		_marker_pulse.tween_property(_marker, "scale", Vector2.ONE, 0.65) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	else:
		if _marker_pulse != null and _marker_pulse.is_valid():
			_marker_pulse.kill()
		_marker_pulse = null
		_marker.scale = Vector2.ONE
	_publish_marker_to_hud()

func _publish_marker_to_hud() -> void:
	if _marker == null or not is_instance_valid(_marker) or main == null or main.hud == null:
		return
	main.hud.set_stage_marker(
		_marker.global_position, _marker.visible,
		_marker.get_parent() == main.hive_root)

## Feeds the goal shelf (hud.gd's set_challenge_goal / UI_PLAN.md section
## 5): the stage's own goal text, the goal that was just completed
## (blank at the very first stage), and numeric progress for a goal with
## a countable target.
func _show_goal(stage: Dictionary) -> void:
	var progress: Dictionary = _goal_progress(stage.goal)
	main.hud.set_challenge_goal(
		stage.goal_text, _last_completed_goal_text,
		progress.get("current", -1.0), progress.get("target", -1.0)
	)

func _advance() -> void:
	main.gallerin_panel.clear_queue()
	var completed_stage: Dictionary = _leave_stage()
	_last_completed_goal_text = completed_stage.goal_text
	challenge_stage_cleared.emit(completed_stage.id)
	_stage_index += 1
	if _stage_index >= _stages().size():
		_complete()
		return
	_enter_stage()

## Leaves a stage through the same cleanup boundary in either direction.
## Stage data owns its own exit effects; the final two effects are mandatory
## because an interrupted automatic forage must never carry camera follow or
## 4x speed into the stage being replayed.
func _leave_stage() -> Dictionary:
	var stage: Dictionary = _stages()[_stage_index]
	_run_stage_effects(stage.get("on_exit", []))
	_run_stage_effects(["camera_follow_off", "speed_multiplier:1.0"])
	return stage

## Runs small, named stage-boundary effects declared in challenge_stages.gd.
## They belong here rather than the data file because each touches live scene
## state; unknown actions remain visible in Godot's debugger instead of being
## silently ignored when a stage record is mistyped.
func _run_stage_effects(effects: Array) -> void:
	for effect_value in effects:
		var effect: String = str(effect_value)
		match effect:
			"camera_follow_queen":
				main.camera_view._on_follow_bee_toggled(main.queen, true, true)
			"camera_follow_off":
				# Keep both directions with camera_view, the sole owner of the
				# follow target, so a stage exit cannot leave private camera state.
				main.camera_view._on_follow_bee_toggled(null, false)
			"speed_multiplier:1.0", "speed_multiplier:4.0":
				main.camera_view._on_speed_requested(effect.trim_prefix("speed_multiplier:").to_float())
			"lock_flower_target:queen":
				main.queen.flower_switch_locked = true
			"unlock_flower_target:queen":
				main.queen.flower_switch_locked = false
			"freeze_bee:queen":
				main.queen._release_everything()
				main.queen.clear_navigation_state()
				main.queen.state = main.Bee.State.IDLING
			"clear_stale_load:queen":
				# freeze_bee:queen (1.11's on_exit) parks her on IDLING without
				# touching current_load, so a nectar trip caught mid-errand
				# rides IDLING straight through 1.12 and 1.13. discards_overflow()
				# below never gets a chance to catch it: that check only runs
				# from bee_foraging.gd's go_to_deposit_cell, which a bee parked
				# on IDLING never enters. Same discard, same message, run
				# directly here instead, on entry to 1.14 where it is due.
				if main.queen.current_load > 0.0 and main.queen.current_load_type == "nectar":
					main.queen.current_load = 0.0
					main.queen.current_load_type = ""
					announce_overflow_discard()
			_:
				push_error("challenge_runner: unknown stage effect '%s'" % effect)

## Debug-panel seam for exercising a newly scaffolded Challenge sequence before
## every causal goal exists. It deliberately uses the ordinary transition path
## so gates, prompts, checkpoints, markers and completion are all exercised.
func debug_advance_stage() -> void:
	if can_debug_advance_stage():
		_advance()

## Settings-panel counterpart to debug_advance_stage(). World state is
## deliberately not rolled back: this only rebuilds the stage's gates,
## prompts and marker through the ordinary entry path.
func debug_retreat_stage() -> void:
	if not can_debug_retreat_stage():
		return
	main.gallerin_panel.clear_queue()
	_leave_stage()
	_stage_index -= 1
	_enter_stage()

func _complete() -> void:
	active = false
	queen_command_locked = false
	_c1_forage_effects_done = false
	# A stage's own on_exit only runs on the way to the next stage, so a
	# Challenge whose last stage completes never runs one -- release the
	# camera and speed here explicitly rather than depending on that.
	_run_stage_effects(["camera_follow_off", "speed_multiplier:1.0"])
	main.fog_of_war.set_hive_reveal_mode("")
	main.fog_of_war.permanent_reveal_override = false
	PlayerProfile.mark_challenge_complete(Session.starting_level)
	main.stage_gate.stop()
	_apply_stage_gate_to_ui()
	main.hud.set_challenge_goal("")
	main.hud.set_queen_build_button_visible(false)
	if _marker != null and is_instance_valid(_marker):
		_set_marker_visible(false)
	if is_instance_valid(main.queen):
		main.queen.energy_immune = false
		main.queen.role_restricted_to = []
		main.queen.player_driven = false
		main.queen.flower_switch_locked = false
		main.queen.role_change_locked = false
		if _c1_base_nectar_rate >= 0.0:
			main.queen.nectar_collection_rate = _c1_base_nectar_rate
			main.queen.pollen_collection_rate = _c1_base_pollen_rate
	main.hud.set_warnings_muted(false)
	main.debug_panel.set_save_load_enabled(true)
	main.TutorialCheckpoint.clear()
	main.gallerin_panel.clear_queue()
	# The completion screen now carries this moment (UI_PLAN.md section 15
	# slice 7) -- Dr Gallerin's own "complete" bubble was dropped rather
	# than kept alongside it, since the two would otherwise say the same
	# thing twice in a row.
	var bees: int = main.get_tree().get_nodes_in_group("bees").size()
	if Session.starting_level == 2:
		main.challenge_complete.open(
			"Challenge complete: your colony has a balanced young workforce and enough stores to keep growing.",
			"Wonderful. Nectar, pollen, nurses, builders, miners -- a small colony with actual departments. I shall try not to look too proud.",
			main.day, bees, main.hive.total("nectar"), main.hive.total("pollen"),
		)
	else:
		main.challenge_complete.open(
			"Challenge complete: your first stores are in place.",
			"A promising start. One queen, one cell, and enough stored sweetness to suggest this was not a terrible idea.",
			main.day, bees, main.hive.total("nectar"), main.hive.total("pollen"),
		)

## Challenge 1 only -- the queen's panel shows a direct "Build cell"
## button during its manual-build stages instead of the usual
## assign-role-then-click-a-spot
## flow (see hud.gd's set_queen_build_button_visible).
##
## Arms a Challenge-only player placement mode. The queen keeps her real
## role: TO_BUILD_SITE and BUILDING work from target_cell, while assigning
## BUILDER would make idle dispatch auto-start another build after this one.
func _on_queen_build_cell_requested() -> void:
	if not is_instance_valid(main.queen):
		return
	main.awaiting_queen_build_cell = true
	main.input_selection._ensure_hive_view()

func on_queen_build_site_chosen(hex: Vector2i) -> void:
	if not is_instance_valid(main.queen) or not main.hive.can_build_on(hex):
		return
	var site: Node2D = main.hive.create_cell_site_at(hex)
	if site == null:
		return
	site.build_time_override = Stages.FAST_BUILD_TIME
	if Session.starting_level == 1:
		site.nectar_capacity_override = Stages.C1_NECTAR_CELL_CAPACITY
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
	main.hud.set_foraging_button_visible(main.stage_gate.is_unlocked("foraging_window"))
	var role_keys: Array = Roles.ROLES.map(func(r): return r.key)
	main.hud.set_allowed_role_keys(role_keys.filter(func(k): return main.stage_gate.is_unlocked(k)))

	# Every role's mode keys, not just Forager's. Availability.mode_query
	# owns the bare-vs-namespaced gate key formula (Nurse and Comb worker
	# both have a mode keyed "both", so a bare key would let one role's
	# unlock leak into the other's) -- hud.gd's own gate check in
	# _build_doing_row reads the same formula via Availability.mode_gate_key,
	# so the two can no longer drift apart by hand.
	var mode_keys: Array = []
	for role in Roles.ROLES:
		for mode in role.modes:
			if Availability.mode_query(role.id, mode.key, main.stage_gate).available:
				mode_keys.append(Availability.mode_gate_key(role.id, mode.key))
	main.hud.set_allowed_mode_keys(mode_keys)

	# Designation types: nectar/pollen/brood and Unreserve all become
	# available together once "cell_designation" is taught (2.5) --
	# honey/jelly stay hidden throughout Challenge 2 (those systems are
	# deferred entirely, not just deferred until designation is taught),
	# so they're gated behind keys no Challenge 2 stage ever unlocks.
	var designation_gates: Dictionary = {
		"nectar": "cell_designation", "pollen": "cell_designation",
		"brood": "cell_designation", "any": "cell_designation",
		"honey": "honey_designation", "jelly": "jelly_designation",
	}
	main.hud.set_allowed_designation_keys(designation_gates.keys().filter(
		func(k): return main.stage_gate.is_unlocked(designation_gates[k])
	))
	main.hud.set_hatch_lock_visible(main.stage_gate.is_unlocked("hatch_lock"))
	main.hud.set_soil_marking_visible(main.stage_gate.is_unlocked("miner"))
	main.hud.set_command_locked_bees([main.queen] if queen_command_locked and is_instance_valid(main.queen) else [])
	# UI-X-2, H1: update_selection([]) reads an empty bee list as "nothing
	# is selected" and hides the command tray and cell popup to match
	# (hud.gd::update_selection -- "a bee selection always wins over a
	# cell selection's content"). A stage transition is not a selection
	# change, so calling it here with no bees selected silently closed an
	# open cell's tray out from under the player -- the Raises row (and
	# any hatch role it had just unlocked, e.g. Forager at 2.2) along with
	# it. set_allowed_role_keys above already re-gates an open cell popup
	# in place; only a genuine bee selection needs the reset below.
	if not main.selected_bees.is_empty() or main.selected_cells.is_empty():
		main.hud.update_selection(main.selected_bees)

## Whether player-issued commands should be rejected for this bee. Kept as
## a Challenge-runner query so input_selection.gd does not need to know what
## a stage id means or carry a second copy of the lock state.
func is_bee_command_locked(bee: Node2D) -> bool:
	return active and queen_command_locked and is_instance_valid(main.queen) and bee == main.queen

## world_building opens the whole entrance for ordinary runs. Challenge 1
## temporarily puts soil back into its inner third, computed from that same
## geometry, and positions the queen two-thirds of the way in from outside.
## The floor polygons underneath are harmless and become visible again as
## each temporary soil block is removed through the ordinary mining path.
func _setup_opening_tunnel() -> void:
	var interior_rings: int = int(GameConfig.hive_interior_rings)
	var tunnel_depth: int = int(GameConfig.hive_soil_depth + GameConfig.hive_rock_rings)
	var entrance_tiles: Dictionary = main.world_building._entrance_tiles(interior_rings, tunnel_depth)
	# The innermost entrance tile already touches the cavity: clearing the
	# block immediately outside it opens a route in, so sealing that final
	# tile only adds an unnecessary fifth dig.
	var blocked_count: int = maxi(1, ceili(float(entrance_tiles.size()) / 3.0) - 1)
	var seconds_per_block: float = Stages.OPENING_MINE_SECONDS / float(blocked_count)
	var inner_ring: int = interior_rings - 1
	var first_block_ring: int = inner_ring + 1

	# Add inner-to-outer so all blocks exist before edge flags/navigation
	# are rebuilt, then retain the opposite order for the queen to follow.
	var inner_to_outer: Array = []
	for offset in range(blocked_count):
		var hex := Vector2i(0, -(first_block_ring + offset))
		main.world_building._add_soil_block(
			hex, main.world_building._hive_centre_local(), GameConfig.hive_cell_spacing
		)
		var block = main.hive.occupied_tiles.get(hex)
		if block != null and is_instance_valid(block):
			block.mine_time_override = seconds_per_block
			block.set_marked(true)
			inner_to_outer.append(block)

	_opening_blocks = inner_to_outer.duplicate()
	_opening_blocks.reverse()
	_opening_started = not _opening_blocks.is_empty()
	main.hive.build_navigation()
	main.hive.refresh_edge_flags()
	var queen_ring: int = first_block_ring + blocked_count
	main.queen.position = main.world_building._hive_centre_local() + Shapes.hex_to_pixel(
		0, -queen_ring, GameConfig.hive_cell_spacing, Session.use_sprite_hex_grid
	)
	_drive_opening_mine()

## Drives the same TO_MINE_SITE -> MINING states ordinary miners use, but
## supplies the next ordered tunnel block itself instead of exposing mining
## controls or changing the queen's role.
func _drive_opening_mine() -> void:
	if not _opening_started or not is_instance_valid(main.queen):
		return
	while not _opening_blocks.is_empty() and not is_instance_valid(_opening_blocks[0]):
		_opening_blocks.pop_front()
	if _opening_blocks.is_empty():
		return
	var next_block: Node2D = _opening_blocks[0]
	if main.queen.target_block != next_block:
		main.queen.target_block = next_block
		main.queen.state = main.Bee.State.TO_MINE_SITE

func _opening_tunnel_cleared() -> bool:
	if not _opening_started:
		return false
	for block in _opening_blocks:
		if is_instance_valid(block):
			return false
	return true

## Slice 14: 1.11/1.14's camera-follow and 4x speed fire the moment the queen
## is actually seen setting off to forage, not at stage entry -- stage entry
## is while the player is still being asked to select her and assign the
## Forager role, and selecting her clears camera-follow (see
## _apply_stage_gate_to_ui). Runs every frame Challenge 1 is active; the
## stage-id and _c1_forage_effects_done checks make it a no-op outside the
## one moment it's for.
func _drive_c1_forage_effects() -> void:
	if _c1_forage_effects_done:
		return
	var stage_id: String = _stages()[_stage_index].id
	if stage_id != "1.11" and stage_id != "1.14":
		return
	if not is_instance_valid(main.queen):
		return
	# Walking out through the hive entrance is the start of an automatic trip,
	# not merely its setup. It is also the state a queen reaches when she
	# switches focus after the meadow-waypoint lesson, so include it rather
	# than waiting for a later outdoor state that can race a UI follow-off.
	if main.queen.state != Bee.State.IN_HIVE_TO_EXIT and main.queen.state not in CHALLENGE1_FORAGE_TRIGGER_STATES:
		return
	_c1_forage_effects_done = true
	_run_stage_effects(["camera_follow_queen", "speed_multiplier:4.0"])

## Whether `bee`'s overflow load must be discarded instead of waiting at a
## full comb. Only the pollen-automation stage has legitimately made every
## cell unavailable to nectar; bee_foraging.gd routes this question here so
## the simulation keeps one opinion about that Challenge-specific boundary.
func discards_overflow(bee: Node2D) -> bool:
	return (
		active and Session.starting_level == 1
		and is_instance_valid(main.queen) and bee == main.queen
		and bee.current_load_type == "nectar"
		and _stages()[_stage_index].id in Stages.C1_DISCARD_STAGES
	)

## Called only after discards_overflow() accepts a real deposit attempt. Clear
## the stage queue first so its hint cannot immediately overwrite the reason
## this gathered nectar was discarded. The unique id preserves one warning per
## occurrence even though Gallerin normally deduplicates prompt ids.
func announce_overflow_discard() -> void:
	_c1_overflow_discard_count += 1
	main.gallerin_panel.clear_queue()
	main.gallerin_panel.show_now({
		"id": "challenge_1_nectar_overflow_%s_%d" % [_stages()[_stage_index].id, _c1_overflow_discard_count],
		"trigger": "warning",
		"repeatable": false,
		"text": "The comb has no room for nectar: this trip cannot be stored while this cell is reserved for pollen. Empty a cell or build another nectar cell before sending her out again.",
	})

## Slice 18: from the pollen-automation stage (1.14) onward, nectar left in
## the cell the player designated for pollen has nowhere to be collected
## from -- most often a forager trip that landed there just before the
## designation was set. Told once per occurrence rather than every frame:
## clear_queue() first, or the stage's own hint overwrites this within
## seconds (same ordering plans/now/challenge-2.md Slice 2 fixes for the
## rescue line).
func _drive_c1_pollen_cell_nectar_prompt(delta: float) -> void:
	if _stages()[_stage_index].id != "1.14":
		_c1_pollen_cell_nectar_elapsed = 0.0
		return
	_c1_pollen_cell_nectar_elapsed += delta
	if _c1_pollen_cell_nectar_elapsed < 1.0:
		return
	_c1_pollen_cell_nectar_elapsed = 0.0
	for cell in main.hive.cells:
		if is_instance_valid(cell) and cell.designated_type == "pollen" and cell.content_type == "nectar":
			main.gallerin_panel.clear_queue()
			main.gallerin_panel.show_now(Feedback.gallerin_prompt("challenge_1_pollen_cell_nectar"))
			return

## Called by main.gd right after every brood hatch, for every hatch in the
## game -- a no-op unless Challenge 1 is actually waiting on this one
## (stage 1.17, the colony's first daughter). Keeps her from immediately
## walking to the exit the way an ordinary hatch does, and starts the
## greeting animation and the queen's hearts VFX.
func on_worker_hatched(bee: Node2D) -> void:
	if not active or Session.starting_level != 1 or not is_instance_valid(bee):
		return
	if _stages()[_stage_index].id != "1.17":
		return
	_new_worker = bee
	bee.state = main.Bee.State.IDLING
	_greeting_active = true
	_greeting_elapsed = 0.0
	_greeting_start_angle = randf() * TAU
	if is_instance_valid(main.queen):
		main.queen.laying_paused = true
		_hearts_timer = Stages.HEARTS_DURATION
		var hearts := QueenHeartsVfx.new()
		hearts.position = main.queen.position
		main.hive_root.add_child(hearts)

## Walks _new_worker on a scripted circle around the queen rather than
## through her own state machine (she's parked on IDLING, which never
## calls _idle_dispatch -- see bee.gd's State.IDLING case -- so nothing
## fights this for control of her position). Settles her just below the
## queen once the circle completes, reading as having arrived to greet her.
func _drive_greeting(delta: float) -> void:
	if not is_instance_valid(_new_worker) or not is_instance_valid(main.queen):
		_greeting_active = false
		return
	_greeting_elapsed += delta
	var t: float = clampf(_greeting_elapsed / Stages.GREETING_DURATION, 0.0, 1.0)
	var centre: Vector2 = main.queen.position
	if t >= 1.0:
		_greeting_active = false
		_new_worker.position = centre + Stages.GREETING_REST_OFFSET
		return
	var angle: float = _greeting_start_angle + t * TAU
	_new_worker.position = centre + Vector2(cos(angle), sin(angle)) * Stages.GREETING_RADIUS

## Declared cadence per goal id (Slice 4, CHATGPT_EFFICIENCY_IMPLEMENTATION_PLAN.md;
## wired to _process by Slice A4, architecture-review.md):
## "frame" tracks a moving position/state every tick, "event" only ever
## flips true once from a discrete happening (a build, a hatch, a
## selection), "poll" compares accumulated totals against a target.
## _should_check_goal() below is what actually reads this per _process
## call; see its own comment and GOAL_POLL_INTERVAL for the runtime half.
const GOAL_CADENCE := {
	"entrance_tunnel_cleared": "frame", "queen_reached_cavity": "frame",
	"queen_selected": "event", "hive_points_visited": "frame",
	"first_cell_built": "event", "second_cell_built": "event", "third_cell_built": "event",
	"nectar_target": "poll", "pollen_target": "poll", "first_egg_laid": "event",
	"queen_reached_meadow": "frame", "meadow_points_visited": "frame",
	"first_flower_collected": "event", "second_flower_collected": "event",
	"harvest_deposited": "frame", "new_bee_selected": "event", "new_bee_left_hive": "frame",
	"complete": "event", "nectar_forager_hatched": "event",
	"nectar_stabilized": "poll", "pollen_foragers_raised": "event", "cell_designated": "poll",
	"pollen_cell_designated": "poll",
	"interim_reserve": "poll", "nurse_raised": "event", "persistent_designation_used": "poll",
	"comb_worker_building": "poll", "miner_expansion": "poll", "c2_complete": "poll",
}

func _goal_met(goal: String) -> bool:
	var stage: Dictionary = _stages()[_stage_index]
	if str(stage.get("goal", "")) != goal or not stage.has("condition"):
		push_error("challenge_runner: goal '%s' has no condition" % goal)
		return false
	var condition: Dictionary = stage.condition
	if condition.has("custom"):
		var method := str(condition.custom)
		# The source contract pairs every custom reference with one method.
		return bool(Callable(self, method).call())
	return Conditions.met(main, condition)

func _goal_check_entrance_tunnel_cleared() -> bool:
	return _opening_tunnel_cleared()

func _goal_check_queen_reached_cavity() -> bool:
	return is_instance_valid(main.queen) and main.queen.position.distance_to(
		main.world_building._hive_centre_local()
	) <= Stages.CENTRE_RADIUS

func _goal_check_queen_selected() -> bool:
	return main.selected_bees.size() == 1 and main.selected_bees[0] == main.queen

func _goal_check_hive_points_visited() -> bool:
	return _ordered_visit_complete(main.queen)

func _goal_check_nectar_target() -> bool:
	for cell in main.hive.cells:
		if is_instance_valid(cell) and cell.content_type == "nectar" and cell.amount >= Stages.NECTAR_TARGET:
			return true
	return false

func _goal_check_pollen_target() -> bool:
	for cell in main.hive.cells:
		if is_instance_valid(cell) and cell.content_type == "pollen" and cell.amount >= Stages.POLLEN_TARGET:
			return true
	return false

func _goal_check_queen_reached_meadow() -> bool:
	return is_instance_valid(main.queen) and not main.queen._is_inside_hive()

func _goal_check_meadow_points_visited() -> bool:
	return _ordered_visit_complete(main.queen)

func _goal_check_first_flower_collected() -> bool:
	return _c1_queen_collections >= 1

func _goal_check_second_flower_collected() -> bool:
	return _c1_queen_collections >= 2

func _goal_check_harvest_deposited() -> bool:
	return is_instance_valid(main.queen) and main.queen._is_inside_hive() and main.queen.current_load <= 0.0

func _goal_check_new_bee_selected() -> bool:
	return (
		is_instance_valid(_new_worker) and main.selected_bees.size() == 1
		and main.selected_bees[0] == _new_worker
	)

func _goal_check_new_bee_left_hive() -> bool:
	return is_instance_valid(_new_worker) and not _new_worker._is_inside_hive()

func _goal_check_complete() -> bool:
	return true

# --- Challenge 2 ---------------------------------------------
func _goal_check_nectar_stabilized() -> bool:
	# It has to have actually dropped and come back, not just sat above the
	# recovery line the whole time -- see Stages.C2_STABILITY_*.
	var dropped: bool = _c2_nectar_low_seen <= _c2_nectar_at_stage_entry - Stages.C2_STABILITY_DROP
	var recovered: bool = main.hive.total("nectar") >= _c2_nectar_low_seen + Stages.C2_STABILITY_RECOVERY
	return dropped and recovered

func _goal_check_persistent_designation_used() -> bool:
	var locked := 0
	for cell in main.hive.cells:
		if is_instance_valid(cell) and cell.hatch_role_locked:
			locked += 1
	var nurses: int = main._role_counts().get(Roles.count_key(Roles.NURSE), 0)
	return locked >= 2 and nurses > _c2_nurses_at_stage_entry

func _goal_check_comb_worker_building() -> bool:
	var has_builder: bool = main._role_counts().get(Roles.count_key(Roles.COMB_WORKER), 0) >= 1
	return has_builder and _built_cell_count() >= _c2_cells_built_at_stage_entry + 2

func _goal_check_miner_expansion() -> bool:
	var has_miner: bool = main._role_counts().get(Roles.count_key(Roles.MINER), 0) >= 1
	var soil_now: int = main.get_tree().get_nodes_in_group("soil_blocks").size()
	var dug: bool = soil_now < _c2_soil_blocks_at_stage_entry
	var built: bool = _built_cell_count() > _c2_cells_built_at_stage_entry
	return has_miner and dug and built

## Numeric progress for a goal with a single countable target -- feeds
## the goal shelf's tertiary progress bar (UI_PLAN.md section 5). Most
## goals here have nothing to count ("select the queen" is a yes/no), so
## this only covers the handful that do; an empty Dictionary tells
## _show_goal there's no bar to show.
func _goal_progress(goal: String) -> Dictionary:
	var stage: Dictionary = _stages()[_stage_index]
	if str(stage.get("goal", "")) != goal:
		return {}
	var condition: Dictionary = stage.get("condition", {})
	if condition.has("custom"):
		return _custom_goal_progress(str(condition.custom))
	return Conditions.progress(main, condition)

func _custom_goal_progress(method: String) -> Dictionary:
	match method:
		"_goal_check_nectar_target":
			for cell in main.hive.cells:
				if is_instance_valid(cell) and cell.content_type == "nectar":
					return {"current": cell.amount, "target": Stages.NECTAR_TARGET}
		"_goal_check_pollen_target":
			for cell in main.hive.cells:
				if is_instance_valid(cell) and cell.content_type == "pollen":
					return {"current": cell.amount, "target": Stages.POLLEN_TARGET}
	return {}
