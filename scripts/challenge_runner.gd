extends Node
## Drives a Challenge run through its sub-stages: checks each stage's
## goal, unlocks the UI the next stage needs, checkpoints the boundary,
## and queues Dr Gallerin's prompts. See TUTORIAL_PLAN.md's "Challenge 1:
## First Stores" and "Challenge 2: Brood, Roles and Expansion" sections
## for the design this follows stage by stage.
##
## Both Challenges share this one file: STAGES_1 is Challenge 1's seven
## sub-stages (1.1-1.7), STAGES_2 is Challenge 2's ten (2.1-2.10) --
## `_stages()` picks between them by `Session.starting_level`. Where the
## two Challenges' shapes actually differ (Challenge 1 walks the queen
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
## own restore path (2.3 onward, see _check_failure) is the first thing
## that ever calls TutorialCheckpoint.restore() for real -- see its
## comment for what a restore does and doesn't reset.

const Roles = preload("res://scripts/roles.gd")
const Shapes = preload("res://scripts/shapes.gd")
const PlayerProfile = preload("res://scripts/player_profile.gd")

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
## her very first cell it's just standing around. Set only on the one
## cell site the queen builds in 1.3 (via HiveCell.build_time_override),
## never on the GameConfig autoload -- a global write there used to leak
## the tutorial's fast build speed into normal play (and into a save) if
## the Challenge was left or restarted before 1.3 completed.
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
const STAGES_1 := [
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

## Interim/completion targets and the rescue threshold -- first guesses
## read off TUTORIAL_PLAN.md's own ranges and sanity-checked by hand
## against GameConfig (cell_capacity is 200, so the 2 nectar-full starting
## cells already hold 400 -- comfortably above the 300 completion target,
## which is deliberate: the colony spends that nest egg growing the
## workforce through 2.1-2.6 and earns it back easily once 10 nectar
## Foragers exist). Like Challenge 1's own constants, easy to retune once
## this is actually played.
const C2_INTERIM_NECTAR := 175.0        # 2.6: doc range 150-200
const C2_INTERIM_POLLEN := 90.0         # 2.6: doc range 75-100
const C2_COMPLETE_NECTAR := 300.0
const C2_COMPLETE_POLLEN := 150.0
const C2_COMPLETE_NECTAR_FORAGERS := 10
const C2_COMPLETE_POLLEN_FORAGERS := 4
const C2_COMPLETE_NURSES := 2
const C2_COMPLETE_BUILDERS := 2
const C2_COMPLETE_MINERS := 2
## How far nectar has to have dropped below its level at 2.3's start, and
## then recovered back above, for "stability demonstrated" to count.
const C2_STABILITY_DROP := 30.0
const C2_STABILITY_RECOVERY := 30.0
## Soft-failure floor (checkpoint restore) once 2.3 is active.
const C2_FAILURE_FLOOR := 15.0
## One-time rescue: triggers once nectar first falls below this floor
## after 2.3 has completed. Doc range 25-50.
const C2_RESCUE_THRESHOLD := 40.0
const C2_RESCUE_AMOUNT := 150.0

const STAGES_2 := [
	{
		"id": "2.1", "goal": "eggs_laid", "unlocked_keys": ["laying"],
		"goal_text": "Goal: let the queen lay in both empty cells.",
		"prompts": [
			{"id": "2.1_welcome", "trigger": "welcome", "delay": 0.0, "text": "You have stores, space, and a queen. That is enough to begin making a workforce -- provided someone lays the eggs."},
			{"id": "2.1_hint", "trigger": "hint", "delay": HINT_DELAY, "text": "She's already on Laying duty. Make sure she has pollen to eat and a free cell to lay in, and she'll take care of the rest."},
		],
	},
	{
		"id": "2.2", "goal": "nectar_forager_hatched", "unlocked_keys": ["laying"],
		"goal_text": "Goal: wait for the first egg to hatch into a nectar Forager.",
		"prompts": [
			{"id": "2.2_welcome", "trigger": "welcome", "delay": 0.0, "text": "Left to their own devices, these first eggs will become nectar foragers. Sensible. A hungry colony needs energy before ambition."},
			{"id": "2.2_hint", "trigger": "hint", "delay": HINT_DELAY, "text": "Developing bees still need care. A little attention now becomes wings later."},
		],
	},
	{
		"id": "2.3", "goal": "nectar_stabilized", "unlocked_keys": ["laying", "colony_window"],
		"goal_text": "Goal: watch the nectar stores fall, then recover them.",
		"prompts": [
			{"id": "2.3_welcome", "trigger": "welcome", "delay": 0.0, "text": "Notice the nectar stores. Bees do not run on enthusiasm alone; movement, work, and survival all cost energy."},
			{"id": "2.3_hint", "trigger": "hint", "delay": HINT_DELAY, "text": "Your stores are falling. That is not automatically bad -- but it does mean the colony needs nectar coming in."},
		],
	},
	{
		"id": "2.4", "goal": "pollen_foragers_raised",
		"unlocked_keys": ["laying", "colony_window", "forager", "nectar", "pollen"],
		"goal_text": "Goal: raise a pollen Forager.",
		"prompts": [
			{"id": "2.4_welcome", "trigger": "welcome", "delay": 0.0, "text": "Nectar keeps bees moving. Pollen helps make more bees. A colony that wants a future needs both."},
			{"id": "2.4_hint", "trigger": "hint", "delay": HINT_DELAY, "text": "Try raising a pollen forager. The next generation will need protein, not just sweetness."},
		],
	},
	{
		"id": "2.5", "goal": "cell_designated",
		"unlocked_keys": ["laying", "colony_window", "forager", "nectar", "pollen", "cell_designation"],
		"goal_text": "Goal: designate a cell.",
		"prompts": [
			{"id": "2.5_welcome", "trigger": "welcome", "delay": 0.0, "text": "A cell can be more than empty space. Give it a purpose, and the colony becomes easier to steer."},
			{"id": "2.5_hint", "trigger": "hint", "delay": HINT_DELAY, "text": "Try designating a cell. Bees are marvellous, but they do appreciate a labelled cupboard."},
		],
	},
	{
		"id": "2.6", "goal": "interim_reserve",
		"unlocked_keys": ["laying", "colony_window", "forager", "nectar", "pollen", "cell_designation"],
		"goal_text": "Goal: build a reserve of ~175 nectar and ~90 pollen.",
		"prompts": [
			{"id": "2.6_welcome", "trigger": "welcome", "delay": 0.0, "text": "Before growing further, build a small reserve. Colonies with no buffer are simply dramatic accidents waiting to happen."},
			{"id": "2.6_hint", "trigger": "hint", "delay": HINT_DELAY, "text": "Prioritise nectar for now. Every bee you raise will add to the colony's energy demand."},
		],
	},
	{
		"id": "2.7", "goal": "nurse_raised",
		"unlocked_keys": ["laying", "colony_window", "forager", "nectar", "pollen", "cell_designation", "nurse", "nurse_feed", "nurse_both"],
		"goal_text": "Goal: raise a nurse.",
		"prompts": [
			{"id": "2.7_welcome", "trigger": "welcome", "delay": 0.0, "text": "The queen can begin a colony, but she should not have to do every nursery shift. Raise a nurse."},
			{"id": "2.7_hint", "trigger": "hint", "delay": HINT_DELAY, "text": "Designate an egg or brood cell for a nurse. Once grown, they can tend developing bees automatically."},
		],
	},
	{
		"id": "2.8", "goal": "persistent_designation_used",
		"unlocked_keys": ["laying", "colony_window", "forager", "nectar", "pollen", "cell_designation", "nurse", "nurse_feed", "nurse_both", "hatch_lock"],
		"goal_text": "Goal: keep two cells raising foragers, and raise one more nurse as a one-off.",
		"prompts": [
			{"id": "2.8_welcome", "trigger": "welcome", "delay": 0.0, "text": "Some cells can remember what they are for. Useful, if one prefers planning to mild panic."},
			{"id": "2.8_hint", "trigger": "hint", "delay": HINT_DELAY, "text": "Set a cell to keep producing foragers, then make a nurse as a one-off. Repeating some jobs and choosing others is the trick."},
		],
	},
	{
		"id": "2.9", "goal": "comb_worker_building",
		"unlocked_keys": ["laying", "colony_window", "forager", "nectar", "pollen", "cell_designation", "nurse", "nurse_feed", "nurse_both", "hatch_lock", "comb_worker", "comb_worker_build", "comb_worker_maintain"],
		"goal_text": "Goal: raise a Comb worker and build more comb.",
		"prompts": [
			{"id": "2.9_welcome", "trigger": "welcome", "delay": 0.0, "text": "The colony is starting to outgrow its first furniture. Raise a comb worker and give the hive more comb."},
			{"id": "2.9_hint", "trigger": "hint", "delay": HINT_DELAY, "text": "Choose where the next cell should go, then let a comb worker take on some building automatically once the pattern is obvious."},
		],
	},
	{
		"id": "2.10", "goal": "miner_expansion",
		"unlocked_keys": ["laying", "colony_window", "forager", "nectar", "pollen", "cell_designation", "nurse", "nurse_feed", "nurse_both", "hatch_lock", "comb_worker", "comb_worker_build", "comb_worker_maintain", "miner", "miner_automine"],
		"goal_text": "Goal: raise a miner, dig new space, and build a cell in it.",
		"prompts": [
			{"id": "2.10_welcome", "trigger": "welcome", "delay": 0.0, "text": "Comb needs somewhere to exist. For that, the colony requires miners: the underground department."},
			{"id": "2.10_hint", "trigger": "hint", "delay": HINT_DELAY, "text": "Raise a miner, then mark a little soil for digging. Space first, cells second."},
		],
	},
	{
		"id": "2.11", "goal": "c2_complete",
		"unlocked_keys": ["laying", "colony_window", "forager", "nectar", "pollen", "cell_designation", "nurse", "nurse_feed", "nurse_both", "hatch_lock", "comb_worker", "comb_worker_build", "comb_worker_maintain", "miner", "miner_automine"],
		"goal_text": "Goal: 300 nectar, 150 pollen, 10 nectar Foragers, 4 pollen Foragers, 2 nurses, 2 Comb workers, 2 miners.",
		"prompts": [],
	},
]

var main: Node2D
var active: bool = false
var _stage_index: int = 0
var _meadow_view_seen: bool = false
var _marker: Polygon2D
## The previous stage's goal_text, fed to hud.gd's goal shelf as the
## "just completed" line (UI_PLAN.md section 5) -- blank at the very
## first stage, since nothing has been completed yet.
var _last_completed_goal_text: String = ""

## Challenge 2 only -- counters/snapshots reset in _enter_stage() so a
## goal can ask "has this happened since this stage began" rather than
## "is this true right now" (a cell built before 2.9 started shouldn't
## count towards 2.9's own goal). See _goal_met()'s C2 branch.
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

func _stages() -> Array:
	return STAGES_2 if Session.starting_level == 2 else STAGES_1

func start() -> void:
	active = true
	_stage_index = 0
	_meadow_view_seen = false
	_c2_rescue_used = false
	_last_completed_goal_text = ""
	main.stage_gate.start()
	# Ordinary save/load doesn't record Challenge stage/gate/prompt state,
	# so a load mid-Challenge would silently drop it -- disabled for the
	# length of the run; tutorial_checkpoint.gd covers Challenge-internal
	# rollback instead. Re-enabled in _complete().
	main.debug_panel.set_save_load_enabled(false)

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
		# The queen starts at the inner entrance and is walked to the
		# centre marker by the player (1.1-1.2), rather than starting
		# already there.
		main.queen.position = main.hive_entrance_inside()

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
	if Session.starting_level == 2:
		_c2_nectar_low_seen = min(_c2_nectar_low_seen, main.hive.total("nectar"))
		_check_c2_failure()
		if not active:   # a restore can end the run mid-frame -- see below
			return
	if _goal_met(_stages()[_stage_index].goal):
		_advance()

## Challenge 2's soft-failure/rescue, from 2.3 onward (TUTORIAL_PLAN.md's
## "Failure and rescue"). Runs every frame once active, but only actually
## checks anything from stage 2.3 onward -- indices below that never had
## a nectar collapse be possible in the first place.
func _check_c2_failure() -> void:
	if _stage_index < _c2_index("2.3"):
		return
	var nectar: float = main.hive.total("nectar")

	# The one-time rescue only ever applies once 2.3 itself is behind us
	# (its own goal *is* "recover from a dip", so a rescue mid-2.3 would
	# short-circuit the very thing it's meant to teach).
	if not _c2_rescue_used and _stage_index > _c2_index("2.3") and nectar < C2_RESCUE_THRESHOLD:
		_c2_rescue_used = true
		main.hive.deposit("nectar", C2_RESCUE_AMOUNT)
		main.gallerin_panel.show_now({
			"id": "challenge_2_rescue", "trigger": "recovery", "repeatable": false,
			"text": "Ahem. Field ecologists do not usually carry emergency nectar, but I shall make one exception. Try to keep a forager pipeline going from here.",
		})
		return

	if nectar < C2_FAILURE_FLOOR:
		main.TutorialCheckpoint.restore(main)
		# A restore replaces main.queen with a new Bee node and rebuilds
		# main.hive.cells from scratch (see saving.gd::_restore) -- nothing
		# here may go on using the pre-restore queen/cell references.
		# _stage_index itself doesn't move: the checkpoint is "the start of
		# this sub-stage", so this re-enters the same stage rather than
		# advancing or regressing it.
		main.queen.energy_immune = true
		_c2_nectar_at_stage_entry = main.hive.total("nectar")
		_c2_nectar_low_seen = _c2_nectar_at_stage_entry
		_apply_stage_gate_to_ui()
		_show_goal(_stages()[_stage_index])
		main.gallerin_panel.clear_queue()
		main.gallerin_panel.show_now({
			"id": "challenge_2_recovery_%d" % _stage_index, "trigger": "recovery", "repeatable": false,
			"text": "A brief ecological wobble. Let's return to the last stable moment.\n\nThe colony has run out of usable energy. Let's return to the last stable point and rebuild the foraging pipeline.",
		})

func _c2_index(stage_id: String) -> int:
	for i in range(STAGES_2.size()):
		if STAGES_2[i].id == stage_id:
			return i
	return 0

func _enter_stage() -> void:
	var stage: Dictionary = _stages()[_stage_index]
	main.stage_gate.set_unlocked_keys(stage.unlocked_keys)
	_apply_stage_gate_to_ui()
	_show_goal(stage)
	main.hud.set_queen_build_button_visible(stage.id == "1.3")
	_update_marker(stage.id)
	main.gallerin_panel.queue_prompts(stage.prompts)
	main.TutorialCheckpoint.save(main)

	if Session.starting_level == 2:
		_c2_nectar_at_stage_entry = main.hive.total("nectar")
		_c2_nectar_low_seen = _c2_nectar_at_stage_entry
		_c2_cells_built_at_stage_entry = _c2_built_cell_count()
		_c2_soil_blocks_at_stage_entry = main.get_tree().get_nodes_in_group("soil_blocks").size()
		_c2_nurses_at_stage_entry = main._role_counts().get(Roles.count_key(Roles.NURSE), 0)

func _c2_built_cell_count() -> int:
	var count := 0
	for cell in main.hive.cells:
		if is_instance_valid(cell) and cell.is_built:
			count += 1
	return count

## Shared by _goal_met's "eggs_laid" and _goal_progress's numeric
## readout, so the two never drift apart on what counts as an egg.
func _c2_brood_cell_count() -> int:
	var count := 0
	for cell in main.hive.cells:
		if is_instance_valid(cell) and cell.content_type == "brood":
			count += 1
	return count

## The marker sits in hive_root, so it's only ever actually seen while
## looking at the hive -- exactly when it's relevant (the meadow-side
## flowers need no such pointer). Challenge 2 has no single "go here"
## point the way Challenge 1's queen-centric early stages do, so it never
## shows one.
func _update_marker(stage_id: String) -> void:
	if stage_id == "1.2":
		_marker.position = main.world_building._hive_centre_local()
		_marker.visible = true
	elif stage_id in ["1.4", "1.5", "1.6"]:
		_marker.position = main.hive_entrance_inside()
		_marker.visible = true
	else:
		_marker.visible = false

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
	_last_completed_goal_text = _stages()[_stage_index].goal_text
	_stage_index += 1
	if _stage_index >= _stages().size():
		_complete()
		return
	_enter_stage()

func _complete() -> void:
	active = false
	PlayerProfile.mark_challenge_complete(Session.starting_level)
	main.stage_gate.stop()
	_apply_stage_gate_to_ui()
	main.hud.set_challenge_goal("")
	main.hud.set_queen_build_button_visible(false)
	if _marker != null and is_instance_valid(_marker):
		_marker.visible = false
	if is_instance_valid(main.queen):
		main.queen.energy_immune = false
	main.hud.set_warnings_muted(false)
	main.debug_panel.set_save_load_enabled(true)
	main.TutorialCheckpoint.clear()
	main.gallerin_panel.clear_queue()
	if Session.starting_level == 2:
		main.gallerin_panel.show_now({
			"id": "challenge_2_complete", "trigger": "complete", "repeatable": false,
			"text": "Challenge complete: your colony has a balanced young workforce and enough stores to keep growing.\n\nWonderful. Nectar, pollen, nurses, builders, miners -- a small colony with actual departments. I shall try not to look too proud.",
		})
	else:
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
		site.build_time_override = FAST_BUILD_TIME
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

	# Every role's mode keys, not just Forager's -- bare for Forager
	# ("nectar", "pollen"), "<role_key>_<mode_key>" for the rest (Nurse
	# and Comb worker both have a mode keyed "both", so a bare key would
	# let one role's unlock leak into the other's). Must match hud.gd's
	# own gate_key computation in _build_doing_row exactly.
	var mode_keys: Array = []
	for role in Roles.ROLES:
		for mode in role.modes:
			mode_keys.append(mode.key if role.id == Roles.FORAGER else "%s_%s" % [role.key, mode.key])
	main.hud.set_allowed_mode_keys(mode_keys.filter(func(k): return main.stage_gate.is_unlocked(k)))

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
		# --- Challenge 2 ---------------------------------------------
		"eggs_laid":
			return _c2_brood_cell_count() >= 2
		"nectar_forager_hatched":
			return main._role_counts().get(Roles.count_key(Roles.FORAGER, "nectar"), 0) >= 1
		"nectar_stabilized":
			# It has to have actually dropped and come back, not just sat
			# above the recovery line the whole time -- see C2_STABILITY_*.
			var dropped: bool = _c2_nectar_low_seen <= _c2_nectar_at_stage_entry - C2_STABILITY_DROP
			var recovered: bool = main.hive.total("nectar") >= _c2_nectar_low_seen + C2_STABILITY_RECOVERY
			return dropped and recovered
		"pollen_foragers_raised":
			return main._role_counts().get(Roles.count_key(Roles.FORAGER, "pollen"), 0) >= 1
		"cell_designated":
			for cell in main.hive.cells:
				if is_instance_valid(cell) and cell.designated_type in ["nectar", "pollen", "brood"]:
					return true
			return false
		"interim_reserve":
			return main.hive.total("nectar") >= C2_INTERIM_NECTAR and main.hive.total("pollen") >= C2_INTERIM_POLLEN
		"nurse_raised":
			return main._role_counts().get(Roles.count_key(Roles.NURSE), 0) >= 1
		"persistent_designation_used":
			var locked := 0
			for cell in main.hive.cells:
				if is_instance_valid(cell) and cell.hatch_role_locked:
					locked += 1
			var nurses: int = main._role_counts().get(Roles.count_key(Roles.NURSE), 0)
			return locked >= 2 and nurses > _c2_nurses_at_stage_entry
		"comb_worker_building":
			var has_builder: bool = main._role_counts().get(Roles.count_key(Roles.COMB_WORKER), 0) >= 1
			return has_builder and _c2_built_cell_count() >= _c2_cells_built_at_stage_entry + 2
		"miner_expansion":
			var has_miner: bool = main._role_counts().get(Roles.count_key(Roles.MINER), 0) >= 1
			var soil_now: int = main.get_tree().get_nodes_in_group("soil_blocks").size()
			var dug: bool = soil_now < _c2_soil_blocks_at_stage_entry
			var built: bool = _c2_built_cell_count() > _c2_cells_built_at_stage_entry
			return has_miner and dug and built
		"c2_complete":
			var counts: Dictionary = main._role_counts()
			return (
				main.hive.total("nectar") >= C2_COMPLETE_NECTAR
				and main.hive.total("pollen") >= C2_COMPLETE_POLLEN
				and counts.get(Roles.count_key(Roles.FORAGER, "nectar"), 0) >= C2_COMPLETE_NECTAR_FORAGERS
				and counts.get(Roles.count_key(Roles.FORAGER, "pollen"), 0) >= C2_COMPLETE_POLLEN_FORAGERS
				and counts.get(Roles.count_key(Roles.NURSE), 0) >= C2_COMPLETE_NURSES
				and counts.get(Roles.count_key(Roles.COMB_WORKER), 0) >= C2_COMPLETE_BUILDERS
				and counts.get(Roles.count_key(Roles.MINER), 0) >= C2_COMPLETE_MINERS
			)
	return false

## Numeric progress for a goal with a single countable target -- feeds
## the goal shelf's tertiary progress bar (UI_PLAN.md section 5). Most
## goals here have nothing to count ("select the queen" is a yes/no), so
## this only covers the handful that do; an empty Dictionary tells
## _show_goal there's no bar to show.
func _goal_progress(goal: String) -> Dictionary:
	match goal:
		"nectar_target":
			return {"current": main.hive.total("nectar"), "target": NECTAR_TARGET}
		"pollen_target":
			return {"current": main.hive.total("pollen"), "target": POLLEN_TARGET}
		"eggs_laid":
			return {"current": _c2_brood_cell_count(), "target": 2.0}
		_:
			return {}
