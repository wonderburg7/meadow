extends RefCounted
## Pure data for both Challenges (CHATGPT_EFFICIENCY_IMPLEMENTATION_PLAN.md
## Slice 4): stage records, prompt records and the static targets/timings
## challenge_runner.gd's goals and beats read. Nothing here reads `main` or
## touches the tree -- the runner owns all of that. Adding a stage means
## adding a row here, a predicate in challenge_runner.gd's goal registry and
## (if it needs one) a view binding, not edits scattered across the runner,
## HUD and debug panel.
##
## See challenge_runner.gd's own header comment for how STAGES_1/STAGES_2
## are chosen between and why Challenge 1 and 2 share one shape despite
## their differences.
class_name ChallengeStages

## Challenge 1's wax cells hold this much nectar. The 1.11 lesson completes
## when one reaches that capacity, so the goal and storage rule cannot drift.
const C1_NECTAR_CELL_CAPACITY := 150.0
const NECTAR_TARGET := C1_NECTAR_CELL_CAPACITY
## Challenge 1's 1.13 pollen lesson completes when its pollen cell reaches
## this amount. Like the preceding nectar lesson, it teaches a meaningful
## reserve rather than filling the cell completely.
const POLLEN_TARGET := 75.0
## A nectar trip can be discarded only once the second comb cell is reserved
## for pollen. Before 1.14 the player can create more nectar space, so taking
## a gathered load away would silently dead-end the lesson instead.
const C1_DISCARD_STAGES := ["1.14"]
## Challenge 1's automatic nectar/pollen lesson runs at double each queen's
## current rate. challenge_runner.gd restores the saved per-bee values on exit.
const CHALLENGE1_FORAGE_SPEED_MULTIPLIER := 2.0
const CENTRE_RADIUS := 40.0
const VISIT_POINT_RADIUS := 30.0

## The opening seals the inner third of world_building's entrance tunnel.
## Each temporary block gets an equal share of this duration through its
## own mine_time_override; normal mining keeps GameConfig.block_mine_time.
const OPENING_MINE_SECONDS := 30.0

## Seconds of no progress before a hint, then a stronger hint -- the
## "Timing pattern" in TUTORIAL_PLAN.md's Dr Gallerin section. Also first
## guesses; easy to retune once this is actually played.
const HINT_DELAY := 20.0
const STRONGER_HINT_DELAY := 45.0

## The normal cell_build_time (90s by default) makes sense once a colony
## has many comb workers splitting the wait -- for a lone queen building
## her very first cell it's just standing around. Set only on the one
## cell site the queen builds in Challenge 1 (via HiveCell.build_time_override),
## never on the GameConfig autoload -- a global write there used to leak
## the tutorial's fast build speed into normal play (and into a save) if
## the Challenge was left or restarted before 1.3 completed.
const FAST_BUILD_TIME := 5.0

## 1.16's hatchling greeting: the new worker circles the queen once and
## settles just in front of her, while a normal FORAGER hatch would
## otherwise already be walking for the exit (world_building's
## _spawn_hatched_bee sets IN_HIVE_TO_EXIT immediately) -- on_worker_hatched
## overrides that to IDLING for the length of this beat and until the
## player sends her out herself (1.17/1.18).
const GREETING_RADIUS := 30.0
const GREETING_DURATION := 2.4
const GREETING_REST_OFFSET := Vector2(0.0, 18.0)

## How long the queen's laying AI stays paused after the hatch, so she
## doesn't immediately walk off to lay into the cell that just emptied
## while the hearts VFX is still playing (bee.gd's laying_paused).
const HEARTS_DURATION := 3.0

const FAREWELL_LINE := "Thanks for giving me life, Mum... I mean... my Queen..."

## A soft gold ring, distinct from the build-hover/home-cell colours
## already used elsewhere on the comb, shown at the centre for the early
## inspection/build beats and at the entrance for departure/return beats.
const MARKER_COLOUR := Color(1.0, 0.85, 0.3, 0.55)

## Each stage: `goal` is a key the goal registry switches on. `unlocked_keys`
## is the *cumulative* set of stage_gate keys visible from this stage on.
## Entries are normally bare strings (implicit trigger reason "stage"), but
## may be {"key": String, "trigger": String} when the reason is worth making
## explicit. _stage_unlock_keys() normalises both shapes before stage_gate sees
## them; stage_gate itself deliberately remains string-keyed and unchanged.
## `goal_text` feeds the corner readout (hud.gd's set_challenge_goal).
## `prompts` feeds gallerin_panel.queue_prompts() straight through.
## `on_enter`/`on_exit` optionally name runner-owned presentation or one-shot
## stage effects. They keep stage-boundary behaviour in the data alongside the
## goal it belongs to instead of growing id-specific branches in the runner.
const UNLOCK_TRIGGER_TYPES := ["design", "skill", "stage", "event", "interaction"]

const STAGES_1 := [
	{
		"id": "1.1", "goal": "entrance_tunnel_cleared", "condition": {"custom": "_goal_check_entrance_tunnel_cleared"}, "unlocked_keys": [],
		"instruction": "",
		"goal_text": "Goal: watch the queen open the way into the hive.",
		"prompts": [
			{"id": "1.1_welcome", "trigger": "welcome", "delay": 0.0, "text": "Dr Gallerin, at your service. And there she is: one queen, arriving with a whole colony still only a possibility."},
			{"id": "1.1_hint", "trigger": "hint", "delay": HINT_DELAY, "text": "For the moment, let her finish opening the tunnel. You are not one bee here; you are the colony's whole intention."},
		],
	},
	{
		"id": "1.2", "goal": "queen_reached_cavity", "condition": {"custom": "_goal_check_queen_reached_cavity"},
		"unlocked_keys": [{"key": "queen_commands", "trigger": "event"}],
		"instruction": "right-click the marked cavity to send her in",
		"goal_text": "Goal: guide the queen into the newly opened cavity.",
		"prompts": [
			{"id": "1.2_welcome", "trigger": "welcome", "delay": 0.0, "text": "The cavity is open. Pan with the arrow keys or by dragging with the middle mouse button, then guide her inside."},
			{"id": "1.2_hint", "trigger": "hint", "delay": HINT_DELAY, "text": "The marked space is her destination. A right-click gives a selected bee somewhere to go."},
		],
	},
	{
		"id": "1.3", "goal": "queen_selected", "condition": {"custom": "_goal_check_queen_selected"}, "unlocked_keys": [{"key": "queen_commands", "trigger": "event"}],
		"instruction": "left-click the queen to select her",
		"goal_text": "Goal: select the queen.",
		"prompts": [
			{"id": "1.3_welcome", "trigger": "welcome", "delay": 0.0, "text": "Select her for a closer look. Queens are not merely larger bees; this colony's entire future begins with this one."},
			{"id": "1.3_hint", "trigger": "hint", "delay": HINT_DELAY, "text": "Select the large bee in the hive to open her summary."},
		],
	},
	{
		"id": "1.4", "goal": "hive_points_visited", "condition": {"custom": "_goal_check_hive_points_visited"}, "unlocked_keys": [{"key": "queen_commands", "trigger": "event"}],
		"instruction": "right-click each marked place in the cavity",
		"goal_text": "Goal: inspect the three marked places in the cavity.",
		"prompts": [
			{"id": "1.4_welcome", "trigger": "welcome", "delay": 0.0, "text": "Before furnishing the place, let us inspect it. A hive is architecture, climate, nursery and pantry all at once."},
			{"id": "1.4_hint", "trigger": "hint", "delay": HINT_DELAY, "text": "Visit the marked points in order; each shows a different part of the colony's new home."},
		],
	},
	{
		"id": "1.5", "goal": "first_cell_built", "condition": {"built_cells_at_least": 1}, "unlocked_keys": [{"key": "queen_commands", "trigger": "event"}],
		"instruction": "use Build cell, then click the marked centre",
		"goal_text": "Goal: build the colony's first comb cell.",
		"prompts": [
			{"id": "1.5_welcome", "trigger": "welcome", "delay": 0.0, "text": "Now for architecture. One wax cell is enough to turn empty space into the beginning of a working hive."},
			{"id": "1.5_hint", "trigger": "hint", "delay": HINT_DELAY, "text": "Use Build cell in the queen's panel and place the first cell at the marked centre."},
		],
	},
	{
		"id": "1.6", "goal": "queen_reached_meadow", "condition": {"custom": "_goal_check_queen_reached_meadow"},
		"unlocked_keys": [{"key": "queen_commands", "trigger": "event"}],
		# The manual-forage arc: the player issues every move, collection and
		# deposit, so the queen makes no state transition of her own. Read by
		# challenge_runner.gd::_enter_stage into bee.gd::player_driven, which
		# bee_foraging.gd::autonomous_state() is the one place that acts on.
		"player_driven": true,
		"instruction": "right-click the marked doorway to send her outside",
		"goal_text": "Goal: send the queen out to the meadow.",
		"prompts": [
			{"id": "1.6_welcome", "trigger": "welcome", "delay": 0.0, "text": "A beautiful cell, and presently an empty one. The meadow can remedy that. Send the queen through the entrance."},
			{"id": "1.6_hint", "trigger": "hint", "delay": HINT_DELAY, "text": "Select the queen and right-click the marked doorway to send her outside."},
		],
	},
	{
		"id": "1.7", "goal": "meadow_points_visited", "condition": {"custom": "_goal_check_meadow_points_visited"}, "unlocked_keys": [{"key": "queen_commands", "trigger": "event"}, {"key": "meadow_view", "trigger": "interaction"}],
		"player_driven": true,
		"instruction": "right-click each marked place in the meadow",
		"goal_text": "Goal: explore the three marked places in the meadow.",
		"prompts": [
			{"id": "1.7_welcome", "trigger": "welcome", "delay": 0.0, "text": "Flowers, distance, weather, other wings -- the meadow is the colony's wider world. Let us take a short tour."},
			{"id": "1.7_hint", "trigger": "hint", "delay": HINT_DELAY, "text": "Guide the queen through the marked points in order. Flying costs more energy than crawling, so routes matter."},
		],
	},
	{
		"id": "1.8", "goal": "first_flower_collected", "condition": {"custom": "_goal_check_first_flower_collected"}, "unlocked_keys": [{"key": "queen_commands", "trigger": "event"}, {"key": "meadow_view", "trigger": "interaction"}],
		"player_driven": true,
		"instruction": "right-click a flower to gather from it",
		"goal_text": "Goal: gather from a flower.",
		"prompts": [
			{"id": "1.8_welcome", "trigger": "welcome", "delay": 0.0, "text": "There: a flower with nectar to spare. Right-click it and the queen will gather what she can carry."},
			{"id": "1.8_hint", "trigger": "hint", "delay": HINT_DELAY, "text": "With the queen selected, right-click a flower."},
		],
	},
	{
		"id": "1.9", "goal": "second_flower_collected", "condition": {"custom": "_goal_check_second_flower_collected"}, "unlocked_keys": [{"key": "queen_commands", "trigger": "event"}, {"key": "meadow_view", "trigger": "interaction"}],
		"player_driven": true,
		"instruction": "right-click another flower to gather from it",
		"goal_text": "Goal: gather from another flower.",
		"prompts": [
			{"id": "1.9_welcome", "trigger": "welcome", "delay": 0.0, "text": "One flower is a meal; a landscape of them is a supply network. Try another."},
			{"id": "1.9_hint", "trigger": "hint", "delay": HINT_DELAY, "text": "Send the queen to another flower before returning home."},
		],
	},
	{
		"id": "1.10", "goal": "harvest_deposited", "condition": {"custom": "_goal_check_harvest_deposited"}, "unlocked_keys": [{"key": "queen_commands", "trigger": "event"}, {"key": "meadow_view", "trigger": "interaction"}],
		"player_driven": true,
		"instruction": "right-click the hive, then right-click the wax cell",
		"goal_text": "Goal: return to the hive and deposit the harvest.",
		"prompts": [
			{"id": "1.10_welcome", "trigger": "welcome", "delay": 0.0, "text": "A full stomach is useful; a filled store is a colony. Bring her home, then choose the wax cell that receives the harvest."},
			{"id": "1.10_hint", "trigger": "hint", "delay": HINT_DELAY, "text": "Right-click the hive to bring the queen home, then right-click the wax cell to deposit her load."},
		],
	},
	{
		"id": "1.11", "goal": "nectar_target", "condition": {"custom": "_goal_check_nectar_target"}, "unlocked_keys": [{"key": "queen_commands", "trigger": "event"}, {"key": "meadow_view", "trigger": "interaction"}, "forager", "nectar"],
		"instruction": "give her the Forager role with nectar focus",
		"goal_text": "Goal: automate nectar gathering.",
		"on_exit": ["camera_follow_off", "speed_multiplier:1.0", "freeze_bee:queen"],
		"prompts": [
			{"id": "1.11_welcome", "trigger": "welcome", "delay": 0.0, "text": "You have proved the route. Now give the queen the Forager role and let colony instinct repeat it."},
			{"id": "1.11_hint", "trigger": "hint", "delay": HINT_DELAY, "text": "Assign the Forager role with nectar selected and let her build a small store."},
			{"id": "1.11_stronger", "trigger": "stronger_hint", "delay": STRONGER_HINT_DELAY, "text": "Select the queen, choose Forager, and leave her focus on nectar."},
		],
	},
	{
		"id": "1.12", "goal": "second_cell_built", "condition": {"built_cells_at_least": 2}, "unlocked_keys": [{"key": "queen_commands", "trigger": "event"}, {"key": "meadow_view", "trigger": "interaction"}, "forager", "nectar"],
		"instruction": "use Build cell to place a second cell",
		"goal_text": "Goal: build a second comb cell.",
		"prompts": [
			{"id": "1.12_welcome", "trigger": "welcome", "delay": 0.0, "text": "Stores need space. Add another cell by hand; bees are tiny logistics departments with wings, but even they need shelving."},
			{"id": "1.12_hint", "trigger": "hint", "delay": HINT_DELAY, "text": "Use Build cell and place a second cell beside the first."},
		],
	},
	{
		"id": "1.13", "goal": "pollen_cell_designated", "condition": {"cell_count": {"designated": "pollen", "explicit": true, "at_least": 1}}, "unlocked_keys": [{"key": "queen_commands", "trigger": "event"}, {"key": "meadow_view", "trigger": "interaction"}, "forager", "nectar", "cell_designation"],
		"instruction": "designate the second cell for pollen",
		"goal_text": "Goal: set the new cell aside for pollen.",
		"on_exit": ["clear_stale_load:queen"],
		"prompts": [
			{"id": "1.13_welcome", "trigger": "welcome", "delay": 0.0, "text": "A cell can be reserved for one thing. Set the new one aside for pollen before she brings any home."},
			{"id": "1.13_hint", "trigger": "hint", "delay": HINT_DELAY, "text": "Select the empty cell and choose Pollen."},
		],
	},
	{
		"id": "1.14", "goal": "pollen_target", "condition": {"custom": "_goal_check_pollen_target"}, "unlocked_keys": [{"key": "queen_commands", "trigger": "event"}, {"key": "meadow_view", "trigger": "interaction"}, "forager", "nectar", "pollen"],
		"instruction": "switch her focus to pollen",
		"goal_text": "Goal: automate pollen gathering.",
		"on_exit": ["camera_follow_off", "speed_multiplier:1.0", "freeze_bee:queen"],
		"prompts": [
			{"id": "1.14_welcome", "trigger": "welcome", "delay": 0.0, "text": "Nectar is fuel. Pollen is protein: less immediately glamorous, biologically indispensable."},
			{"id": "1.14_hint", "trigger": "hint", "delay": HINT_DELAY, "text": "Keep the Forager role, switch the focus to pollen, and gather a small store."},
		],
	},
	{
		"id": "1.15", "goal": "third_cell_built", "condition": {"built_cells_at_least": 3}, "unlocked_keys": [{"key": "queen_commands", "trigger": "event"}, {"key": "meadow_view", "trigger": "interaction"}, "forager", "nectar", "pollen"],
		"instruction": "use Build cell to place a third cell",
		"goal_text": "Goal: build a third cell for the colony's next generation.",
		"prompts": [
			{"id": "1.15_welcome", "trigger": "welcome", "delay": 0.0, "text": "Here is pollen's deeper purpose: making more bees. Build a third cell, and we can turn provisions into a future."},
			{"id": "1.15_hint", "trigger": "hint", "delay": HINT_DELAY, "text": "Place one more comb cell with the queen's Build cell command."},
		],
	},
	{
		"id": "1.16", "goal": "first_egg_laid", "condition": {"brood_cells_at_least": 1}, "unlocked_keys": [{"key": "queen_commands", "trigger": "event"}, {"key": "meadow_view", "trigger": "interaction"}, "forager", "nectar", "pollen", "laying"],
		"goal_text": "Goal: let the queen lay the colony's first egg.",
		"prompts": [
			{"id": "1.16_welcome", "trigger": "welcome", "delay": 0.0, "text": "Set her to Laying, with Nursing as her backup. A queen who only seeks empty cells would overlook the hungry brood already depending on her."},
			{"id": "1.16_hint", "trigger": "hint", "delay": HINT_DELAY, "text": "Choose Laying as the queen's role and Nursing as her backup, then keep one cell free."},
		],
	},
	{
		"id": "1.17", "goal": "nectar_forager_hatched", "condition": {"role_count": {"role": "forager", "focus": "nectar", "at_least": 1}}, "unlocked_keys": [{"key": "queen_commands", "trigger": "event"}, {"key": "meadow_view", "trigger": "interaction"}, "forager", "nectar", "pollen", "laying"],
		"goal_text": "Goal: care for the egg until the first worker hatches.",
		"prompts": [
			{"id": "1.17_welcome", "trigger": "welcome", "delay": 0.0, "text": "An egg is a promise with a feeding schedule. Keep the young bee supplied and watch what pollen becomes."},
			{"id": "1.17_hint", "trigger": "hint", "delay": HINT_DELAY, "text": "The queen's Nursing backup lets her feed developing brood whenever laying is blocked."},
		],
	},
	{
		"id": "1.18", "goal": "new_bee_selected", "condition": {"custom": "_goal_check_new_bee_selected"}, "unlocked_keys": [{"key": "queen_commands", "trigger": "event"}, {"key": "meadow_view", "trigger": "interaction"}, "forager", "nectar", "pollen", "laying"],
		"goal_text": "Goal: select the new worker.",
		"prompts": [
			{"id": "1.18_welcome", "trigger": "welcome", "delay": 0.0, "text": "A daughter, and the colony's first worker. Select her and inspect the summary and role panels."},
			{"id": "1.18_hint", "trigger": "hint", "delay": HINT_DELAY, "text": "Select the smaller new bee. She begins as a nectar Forager, ready to turn one route into a routine."},
		],
	},
	{
		"id": "1.19", "goal": "new_bee_left_hive", "condition": {"custom": "_goal_check_new_bee_left_hive"}, "unlocked_keys": [{"key": "queen_commands", "trigger": "event"}, {"key": "meadow_view", "trigger": "interaction"}, "forager", "nectar", "pollen", "laying"],
		"goal_text": "Goal: send the new worker out into the meadow.",
		"prompts": [
			{"id": "1.19_welcome", "trigger": "welcome", "delay": 0.0, "text": "Her first journey awaits. Send the new worker through the hive entrance."},
			{"id": "1.19_hint", "trigger": "hint", "delay": HINT_DELAY, "text": "With the new worker selected, command her to leave the hive."},
		],
	},
	{
		"id": "1.20", "goal": "complete", "condition": {"custom": "_goal_check_complete"},
		"unlocked_keys": [{"key": "queen_commands", "trigger": "event"}, {"key": "meadow_view", "trigger": "interaction"}, "forager", "nectar", "pollen", "laying"],
		"goal_text": "",
		"prompts": [],
	},
]

## Interim/completion targets and the rescue threshold -- first guesses
## read off TUTORIAL_PLAN.md's own ranges and sanity-checked by hand
## against GameConfig (cell_capacity is 200, so the 2 nectar-full starting
## cells already hold 400 -- comfortably above the 300 completion target,
## which is deliberate: the colony spends that nest egg growing the
## workforce through 2.1-2.4 and earns it back easily once 10 nectar
## Foragers exist). Like Challenge 1's own constants, easy to retune once
## this is actually played.
const C2_INTERIM_NECTAR := 175.0        # 2.4: doc range 150-200
const C2_INTERIM_POLLEN := 90.0         # 2.4: doc range 75-100
const C2_COMPLETE_NECTAR := 300.0
const C2_COMPLETE_POLLEN := 150.0
const C2_COMPLETE_NECTAR_FORAGERS := 10
const C2_COMPLETE_POLLEN_FORAGERS := 4
const C2_COMPLETE_NURSES := 2
const C2_COMPLETE_BUILDERS := 2
const C2_COMPLETE_MINERS := 2
## How far nectar has to have dropped below its level at 2.1's start, and
## then recovered back above, for "stability demonstrated" to count.
const C2_STABILITY_DROP := 30.0
const C2_STABILITY_RECOVERY := 30.0
## Soft-failure floor (checkpoint restore) once 2.1 is active.
const C2_FAILURE_FLOOR := 15.0
## One-time rescue: triggers once nectar first falls below this floor
## after 2.1 has completed. Doc range 25-50.
const C2_RESCUE_THRESHOLD := 40.0
const C2_RESCUE_AMOUNT := 150.0
## One-time pollen rescue before 2.2 clears. Read the actual per-bee cost
## from GameConfig so this safety net follows balance changes automatically.
## These must be functions rather than GDScript constants because the cost is
## an editable GameConfig instance property, not a compile-time value.
static func c2_pollen_rescue_threshold() -> float:
	return GameConfig.egg_pollen_cost

static func c2_pollen_rescue_amount() -> float:
	return c2_pollen_rescue_threshold() * 3.0

## Bundle G (CHALLENGE1_REVAMP_PLAN.md): the old 2.1 (eggs_laid) and 2.2
## (nectar_forager_hatched) are gone -- Challenge 1's own 1.15-1.16 now
## teach exactly that (laying, backup nursing, the first hatch), and
## levels.gd's level 2 starts with that first nectar Forager already
## hatched (see world_building.gd::_spawn_starting_foragers). What was
## 2.3 is renumbered to 2.1 so the sequence still starts at "2.1" rather
## than opening on a stage id that looks like two are missing.
const STAGES_2 := [
	{
		"id": "2.1", "goal": "nectar_stabilized", "condition": {"custom": "_goal_check_nectar_stabilized"}, "unlocked_keys": ["meadow_view", "laying", "colony_window", "foraging_window"],
		"goal_text": "Goal: watch the nectar stores fall, then recover them.",
		"prompts": [
			{"id": "2.1_welcome", "trigger": "welcome", "delay": 0.0, "text": "Notice the nectar stores. Bees do not run on enthusiasm alone; movement, work, and survival all cost energy."},
			{"id": "2.1_hint", "trigger": "hint", "delay": HINT_DELAY, "text": "Your stores are falling. That is not automatically bad -- but it does mean the colony needs nectar coming in."},
			{"id": "2.1_pollen_reserve", "trigger": "hint", "delay": STRONGER_HINT_DELAY, "text": "One caution before you raise too many nectar Foragers: every new bee is raised on pollen. Keep some back, or the colony may spend its way out of a future."},
		],
	},
	{
		"id": "2.2", "goal": "pollen_foragers_raised", "condition": {"role_count": {"role": "forager", "focus": "pollen", "at_least": 1}},
		"unlocked_keys": ["meadow_view", "laying", "colony_window", "foraging_window", "forager", "nectar", "pollen"],
		"goal_text": "Goal: raise a pollen Forager.",
		"prompts": [
			{"id": "2.2_welcome", "trigger": "welcome", "delay": 0.0, "text": "Now put that pollen reserve to work: raise a pollen Forager. Nectar keeps bees moving, but pollen helps make more bees."},
			{"id": "2.2_hint", "trigger": "hint", "delay": HINT_DELAY, "text": "Try raising a pollen forager. The next generation will need protein, not just sweetness."},
		],
	},
	{
		"id": "2.3", "goal": "cell_designated", "condition": {"any_of": [{"cell_count": {"designated": "nectar", "at_least": 1}}, {"cell_count": {"designated": "pollen", "at_least": 1}}, {"cell_count": {"designated": "brood", "at_least": 1}}]},
		"unlocked_keys": ["meadow_view", "laying", "colony_window", "foraging_window", "forager", "nectar", "pollen", "cell_designation"],
		"goal_text": "Goal: designate a cell.",
		# Reworded from Slice 18's Challenge 1 1.13, which now teaches
		# designation first -- Challenge 2 can still be started on its own,
		# so this is a reminder rather than the first introduction.
		"prompts": [
			{"id": "2.3_welcome", "trigger": "welcome", "delay": 0.0, "text": "Remember that a cell can be reserved for one thing. Time to put that to use here as well."},
			{"id": "2.3_hint", "trigger": "hint", "delay": HINT_DELAY, "text": "Designate a cell for the resource this colony needs most. Bees do appreciate a labelled cupboard."},
		],
	},
	{
		"id": "2.4", "goal": "interim_reserve", "condition": {"all_of": [{"hive_total": {"resource": "nectar", "at_least": C2_INTERIM_NECTAR}}, {"hive_total": {"resource": "pollen", "at_least": C2_INTERIM_POLLEN}}]},
		"unlocked_keys": ["meadow_view", "laying", "colony_window", "foraging_window", "forager", "nectar", "pollen", "cell_designation"],
		"goal_text": "Goal: build a reserve of ~175 nectar and ~90 pollen.",
		"prompts": [
			{"id": "2.4_welcome", "trigger": "welcome", "delay": 0.0, "text": "Before growing further, build a small reserve. Colonies with no buffer are simply dramatic accidents waiting to happen."},
			{"id": "2.4_hint", "trigger": "hint", "delay": HINT_DELAY, "text": "Prioritise nectar for now. Every bee you raise will add to the colony's energy demand."},
		],
	},
	{
		"id": "2.5", "goal": "nurse_raised", "condition": {"role_count": {"role": "nurse", "at_least": 1}},
		"unlocked_keys": ["meadow_view", "laying", "colony_window", "foraging_window", "forager", "nectar", "pollen", "cell_designation", "nurse", "nurse_feed", "nurse_both"],
		"goal_text": "Goal: raise a nurse.",
		"prompts": [
			{"id": "2.5_welcome", "trigger": "welcome", "delay": 0.0, "text": "The queen can begin a colony, but she should not have to do every nursery shift. Raise a nurse."},
			{"id": "2.5_hint", "trigger": "hint", "delay": HINT_DELAY, "text": "Designate an egg or brood cell for a nurse. Once grown, they can tend developing bees automatically."},
		],
	},
	{
		"id": "2.6", "goal": "persistent_designation_used", "condition": {"custom": "_goal_check_persistent_designation_used"},
		"unlocked_keys": ["meadow_view", "laying", "colony_window", "foraging_window", "forager", "nectar", "pollen", "cell_designation", "nurse", "nurse_feed", "nurse_both", "hatch_lock"],
		"goal_text": "Goal: keep two cells raising foragers, and raise one more nurse as a one-off.",
		"prompts": [
			{"id": "2.6_welcome", "trigger": "welcome", "delay": 0.0, "text": "Some cells can remember what they are for. Useful, if one prefers planning to mild panic."},
			{"id": "2.6_hint", "trigger": "hint", "delay": HINT_DELAY, "text": "Set a cell to keep producing foragers, then make a nurse as a one-off. Repeating some jobs and choosing others is the trick."},
		],
	},
	{
		"id": "2.7", "goal": "comb_worker_building", "condition": {"custom": "_goal_check_comb_worker_building"},
		"unlocked_keys": ["meadow_view", "laying", "colony_window", "foraging_window", "forager", "nectar", "pollen", "cell_designation", "nurse", "nurse_feed", "nurse_both", "hatch_lock", "comb_worker", "comb_worker_build", "comb_worker_maintain"],
		"goal_text": "Goal: raise a Comb worker and build more comb.",
		"prompts": [
			{"id": "2.7_welcome", "trigger": "welcome", "delay": 0.0, "text": "The colony is starting to outgrow its first furniture. Raise a comb worker and give the hive more comb."},
			{"id": "2.7_hint", "trigger": "hint", "delay": HINT_DELAY, "text": "Choose where the next cell should go, then let a comb worker take on some building automatically once the pattern is obvious."},
		],
	},
	{
		"id": "2.8", "goal": "miner_expansion", "condition": {"custom": "_goal_check_miner_expansion"},
		"unlocked_keys": ["meadow_view", "laying", "colony_window", "foraging_window", "forager", "nectar", "pollen", "cell_designation", "nurse", "nurse_feed", "nurse_both", "hatch_lock", "comb_worker", "comb_worker_build", "comb_worker_maintain", "miner", "miner_automine"],
		"goal_text": "Goal: raise a miner, dig new space, and build a cell in it.",
		"prompts": [
			{"id": "2.8_welcome", "trigger": "welcome", "delay": 0.0, "text": "Comb needs somewhere to exist. For that, the colony requires miners: the underground department."},
			{"id": "2.8_hint", "trigger": "hint", "delay": HINT_DELAY, "text": "Raise a miner, then mark a little soil for digging. Space first, cells second."},
		],
	},
	{
		"id": "2.9", "goal": "c2_complete", "condition": {"all_of": [{"hive_total": {"resource": "nectar", "at_least": C2_COMPLETE_NECTAR}}, {"hive_total": {"resource": "pollen", "at_least": C2_COMPLETE_POLLEN}}, {"role_count": {"role": "forager", "focus": "nectar", "at_least": C2_COMPLETE_NECTAR_FORAGERS}}, {"role_count": {"role": "forager", "focus": "pollen", "at_least": C2_COMPLETE_POLLEN_FORAGERS}}, {"role_count": {"role": "nurse", "at_least": C2_COMPLETE_NURSES}}, {"role_count": {"role": "comb_worker", "at_least": C2_COMPLETE_BUILDERS}}, {"role_count": {"role": "miner", "at_least": C2_COMPLETE_MINERS}}]},
		"unlocked_keys": ["meadow_view", "laying", "colony_window", "foraging_window", "forager", "nectar", "pollen", "cell_designation", "nurse", "nurse_feed", "nurse_both", "hatch_lock", "comb_worker", "comb_worker_build", "comb_worker_maintain", "miner", "miner_automine"],
		"goal_text": "Goal: 300 nectar, 150 pollen, 10 nectar Foragers, 4 pollen Foragers, 2 nurses, 2 Comb workers, 2 miners.",
		"prompts": [],
	},
]
