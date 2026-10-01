extends Node2D
## Bee -- v1 prototype, slice 8.
##
## A bee has a ROLE, and (if foraging) a FOCUS resource:
##   Forager    -- flies out to flowers, brings nectar or pollen home
##   Nursery    -- stays in the hive, carries eggs to cells, tends brood
##   Builder    -- draws new comb cells, and hauls resources between cells
##   Egg layer  -- queen only: eats pollen, lays eggs on the hive floor
##
## Foraging loop: pick an unoccupied flower with spare focus resource
## that isn't on this bee's "recently drained" list, fly there, collect,
## repeat until the stomach is full, then fly home, walk in through the
## hive entrance, deposit into a cell, and walk back out.
##
## Every bee burns energy constantly and dies if it hits zero, and dies
## of old age at `bee_lifespan_days`. Foragers refuel from the comb when
## they deposit; in-hive bees sip from the comb as they go.
##
## The queen is an ordinary bee with `is_queen` set: she moves slower,
## and she alone can take the Egg layer role. She can be reassigned to
## forage or build like anyone else.

# --- preloads and shared enums ------------------------------------
## Role and State (and ROLE_PERF_SECTIONS) live in bee_enums.gd, a leaf
## file with no dependencies, so every other bee_*.gd file can use them
## without a circular preload of bee.gd itself. Aliased straight back
## here so every existing `Bee.Role.X` / `Bee.State.X` reference in
## hud.gd, main.gd, world_building.gd, input_selection.gd,
## orders_zones.gd and year_winter.gd keeps working unchanged.
const BeeEnums = preload("res://scripts/bee_enums.gd")
const Role = BeeEnums.Role
const State = BeeEnums.State
const ROLE_PERF_SECTIONS = BeeEnums.ROLE_PERF_SECTIONS

const Shapes = preload("res://scripts/shapes.gd")
const Roles = preload("res://scripts/roles.gd")
const Levels = preload("res://scripts/levels.gd")
const BeeIdentity = preload("res://scripts/bee_identity.gd")
## Only for HiveCell.EMPTY_COLOR -- the comb worker's role ring is drawn in
## the same colour as an empty wax cell, so the two read as the same
## material rather than picking an unrelated brown/tan and hoping it reads
## the same. hive_cell.gd doesn't preload bee.gd, so this isn't circular.
const HiveCell = preload("res://scripts/hive_cell.gd")
const BeeMovement = preload("res://scripts/bee_movement.gd")
const BeeStatus = preload("res://scripts/bee_status.gd")
const BeeSurvival = preload("res://scripts/bee_survival.gd")
const BeeForaging = preload("res://scripts/bee_foraging.gd")
const BeeNursery = preload("res://scripts/bee_nursery.gd")
const BeeBuilding = preload("res://scripts/bee_building.gd")
const BeeMining = preload("res://scripts/bee_mining.gd")
const BeeHoney = preload("res://scripts/bee_honey.gd")
const BeeEggLaying = preload("res://scripts/bee_egg_laying.gd")
const Actions = preload("res://scripts/actions.gd")
const Availability = preload("res://scripts/availability.gd")

# --- the role action catalogue ------------------------------------
## The catalogue is grouped once when this script loads. `_try_role_work` runs
## on every idle bee's think tick, so filtering the full catalogue there would
## turn a data refactor into a hot-path regression.
static var _actions_by_role: Dictionary = _build_actions_by_role()
## G3: this bee's Availability.action_query answers for gated rows, valid
## while _action_gate_epoch matches Availability.gate_epoch. Ungated rows --
## every row today -- never reach it.
var _action_gate_cache: Dictionary = {}
var _action_gate_epoch: int = -1
const ROLE_ACTION_FINDERS := {
	Roles.NURSE: BeeNursery,
	Roles.COMB_WORKER: BeeBuilding,
	Roles.MINER: BeeMining,
	Roles.HONEY: BeeHoney,
	Roles.QUEEN: BeeEggLaying,
	Roles.FORAGER: BeeForaging,
}

# --- stats copied from GameConfig ---------------------------------
var speed: float = 110.0
var flower_handling_time: float = 2.0
var nectar_collection_rate: float = 5.0
var pollen_collection_rate: float = 2.0
var deposit_time: float = 2.5
var nectar_stomach_capacity: float = 50.0
var pollen_stomach_capacity: float = 25.0
var arrive_distance: float = 4.0
var click_radius: float = 14.0

# --- role, state and identity -------------------------------------
var role: int = Role.FORAGER
var state: int = State.SEEK_FLOWER
var timer: float = 0.0
var is_queen: bool = false

## A gyne: a future queen, raised on royal jelly and several times more
## expensive than a worker. She can do any worker job while she is here,
## but she is bigger, slower and hungrier than one.
var is_gyne: bool = false

## Nursery sub-mode: "feed" tends and feeds brood, "jelly" makes royal
## jelly for gyne larvae, "both" does either as it comes up.
var nurse_mode: String = "feed"
## Royal jelly this nurse is carrying, both to feed gyne larvae with and
## to deposit into a jelly cell after making a batch.
var nurse_jelly: float = 0.0

var hive: Node2D          # the meadow-side marker / storage accountant
var world: Node2D         # main.gd -- owns the geometry and the two roots
var resource_type: String = "nectar"    # this bee's focus, when foraging
var current_load: float = 0.0
var current_load_type: String = ""
var current_flower: Node2D = null
var bee_id: int = 0

## A generated name, one small rolled stat trait, and a generated fact
## about herself -- see bee_identity.gd and BEE_INDIVIDUALITY_PLAN.md.
## All three rolled once at spawn and saved, so a bee's identity survives
## a reload rather than being re-rolled. trait_stat is one of
## BeeIdentity.TRAIT_STATS, "" only very briefly before _ready() rolls
## it. trait_percent is signed, e.g. 0.07 or -0.03.
var bee_name: String = ""
var bee_fact: String = ""
var trait_stat: String = ""
var trait_percent: float = 0.0
## Set from the single-bee selection panel, or from the colony window's
## Favourites list, which is how the player finds this bee again in a
## colony of hundreds.
var is_favourite: bool = false
## Cosmetic-only jitter, rolled once at spawn -- see _ready(). Never
## saved: rerolling on load is harmless since nothing simulated reads
## either of these (rule 3).
var tint_factor: float = 1.0
var size_jitter: float = 1.0

var energy: float = 100.0
## Held topped up and exempt from starvation -- only ever set by
## challenge_runner.gd, for the queen, during Challenge 1's "no lethal
## pressure" start state (see TUTORIAL_PLAN.md). Never touched anywhere
## else, so ordinary play is completely unaffected.
var energy_immune: bool = false
## True only for the few seconds after Challenge 1's first hatch (1.16) --
## challenge_runner.gd sets this on the queen so she doesn't immediately
## lay into the cell that just emptied while the hatchling greeting/hearts
## beat is still playing. Only ever set by challenge_runner.gd; ordinary
## play never touches it.
var laying_paused: bool = false
var age_seconds: float = 0.0
var selected: bool = false
## queue_free only takes effect at the end of the frame, so without this
## a dying bee can be processed again and die twice.
var is_dying: bool = false
## Set by BeeSurvival.die() the instant it's called, so anything reading
## it afterwards (the epitaph toast, the diagnostic log) sees the actual
## branch that fired rather than re-deriving a guess from stale state.
var death_cause: String = ""

var move_target: Vector2 = Vector2.ZERO   # for player-commanded movement
var target_cell: Node2D = null
## `hive.index_epoch` last seen when a full comb blocked this bee's deposit
## -- -1 means "not blocked", since epoch 0 is a real value a fresh hive
## starts at. No leading underscore, like `target_cell` above and every
## other field `bee_foraging.gd` reaches through a bee reference: Godot's
## "unused private variable" warning fires on an underscore-prefixed field
## with no access from its own script, and doesn't count a companion
## script's access as a use. A prior pass had this named `_deposit_blocked_
## epoch` and deleted it outright to silence that false positive, which
## produced a real crash (invalid property access) the moment a forager's
## first deposit target went stale -- don't repeat either mistake.
var deposit_blocked_epoch: int = -1
## While true, this bee makes no autonomous state transition of its own --
## every state change comes from a `command_*` call or a Challenge stage
## effect. Written in exactly one place, challenge_runner.gd::_enter_stage,
## from the stage's own `player_driven` key; no command ever writes it.
## False everywhere else, so outside a Challenge nothing here applies.
## bee_foraging.gd::autonomous_state() is the single choke point that reads
## it, and tests/source_checks.py fails the build if an autonomous
## transition is added that skips that choke point.
var player_driven: bool = false
## A stage can let a forager pick her first flower automatically but require
## an explicit player command before she switches to another one.
var flower_switch_locked: bool = false
## Challenge 1's manual-forage arc lets the queen fly a collection trip
## without command_collect_from's usual set_role(Role.FORAGER) becoming
## permanent. False everywhere else.
var role_change_locked: bool = false
## A point, flower, or receiving cell clicked in the other zone. The command
## resumes only after the bee has physically crossed the entrance.
var pending_move_target := Vector2(INF, INF)
var pending_collect_flower: Node2D = null
var pending_deposit_cell: Node2D = null
var haul_target: Node2D = null
var target_block: Node2D = null
var automine: bool = false

## What a comb worker (the Builder role) actually does: "build" draws new
## comb, "maintain" clears dead larvae and shifts stores out of cells the
## player has re-designated, "both" does either as it comes up.
var architect_mode: String = "both"
## True while carrying a dead larva out of the hive to throw away.
var carrying_corpse: bool = false

## Whether a change of job waits for the current one to finish. Off means
## the bee drops what it's doing the instant you reassign it; on means it
## sees the job through first -- a forager, for instance, delivers its
## load before it takes up the new role. `pending_role` holds the change
## until then.
var finish_task_first: bool = false
var pending_role: int = -1
var dirt_load: float = 0.0
var pollen_eaten: float = 0.0

## Honey making. `honey_load` is chewed nectar-and-enzyme mix on its way
## to a cell; `fan_target` is the cell currently being dried out.
var honey_load: float = 0.0
var fan_target: Node2D = null

## The wall of `target_cell` this bee has claimed while loading or
## unloading. -1 means it doesn't hold one. Only six bees can work a cell
## at a time, one per wall, so they never stand on top of each other.
var cell_slot: int = -1
var slot_cell: Node2D = null

## What a nurse is physically carrying. Brood is fed from this, not from
## the comb directly, so a nurse has to go and load up first -- see
## _nurse_restock_errand. `nurse_carb` is either nectar or honey; which
## one is in `nurse_carb_type`, because honey feeds a larva for longer.
var nurse_pollen: float = 0.0
var nurse_carb: float = 0.0
var nurse_carb_type: String = ""
var nurse_fetching: String = ""      # what this trip to a cell is for

## Stall watchdog. A bee that hasn't moved for a few seconds while it is
## supposed to be travelling has got itself pinned on something; rather
## than hovering there until the player notices, it gives up on the
## current errand. See _watch_for_stalls.
var stall_best_distance: float = INF
var stall_timer: float = 0.0
const STALL_SECONDS := 4.0
## How close to an obstacle a bee has to be for the escape hatch to treat
## it as the thing it is caught on.
const ESCAPE_RANGE := 60.0

## A role to fall back to whenever this bee's primary role has genuinely
## nothing for it to do right now -- a non-automine miner with no block
## marked, a nurse with no brood to tend, a builder with nowhere left to
## build. -1 means none set. The bee's own `role` never changes because
## of this; it just borrows another role's behaviour between primary
## tasks and drops it the instant primary work turns up again.
var secondary_role: int = -1

## Optional allow-list for the backup role's actual work dispatch. Empty is
## unrestricted, matching the HUD's allowed_role_keys convention. Challenges
## use it as a second line of defence when their taught-role list matters.
var role_restricted_to: Array = []

## True while the bee is currently doing secondary_role's work rather than
## its own. Building and mining are the two secondary jobs long enough
## (up to a full cell or block) that "drops it the instant primary work
## turns up" needs an actual check mid-task, not just at the next idle
## state -- see _maybe_break_off_secondary.
var working_secondary: bool = false

## The role this bee is actually doing right now -- its secondary role
## while working_secondary is true (see above), otherwise its primary
## role. UI that offers a sub-mode choice (hud.gd's Doing row) must key
## off this, not `role` alone, or a bee working entirely through its
## backup role -- e.g. Challenge 1's queen, who never becomes a primary
## Forager -- has no way to reach a mode it hasn't got a live role for.
func current_working_role() -> int:
	return secondary_role if working_secondary else role

# --- floral constancy and the search pattern ----------------------
## Floral constancy (see GameConfig.floral_constancy_on): "" means no
## preference. Once set, this bee only ever selects flowers of this
## species, regardless of the toggle -- turning constancy off in tuning
## just stops new preferences being offered, it doesn't clear ones a
## bee already has.
var preferred_species: String = ""

## Player-set point (meadow/global space) a forager heads to first on
## every trip out, before hunting for a flower. Lets the player split
## foragers across different parts of the meadow instead of them all
## drifting to whatever's nearest the entrance. INF means "not set".
var forage_start_point: Vector2 = Vector2(INF, INF)
## Set only while a forager has abandoned an outdoor errand to preserve the
## energy needed to get home.  It is intentionally transient: it explains
## this trip, not a new saved simulation state.
var emergency_return_reason: String = ""

## Slice 5 (local search): where SEARCHING's spiral is centred. Reset to
## forage_start_point at every point that (re)sets forage_start_point
## itself -- see FORAGING_ECOLOGY_PLAN.md's Slice 5 -- so manual/scouting/
## recruitment control over where a forager starts stays authoritative.
## Between resets it drifts toward flowers she actually commits to (see
## start_collecting in bee_foraging.gd), so a run of good luck in one
## corner of her patch shifts where she searches from next, without ever
## overriding the pin itself.
var local_search_anchor: Vector2 = Vector2(INF, INF)

## Slice 5 (local search): SEARCHING's own progress through its expanding
## spiral. search_angle only ever grows while in SEARCHING (it drives both
## radius growth and direction -- see _spiral_point), reset to 0 whenever
## seek_flower puts a bee into that state fresh. search_start_direction is
## a fresh random offset per bout, so a bee whose anchor sits near an
## obstacle in one fixed direction doesn't spiral into the same wall on
## every single bout from that anchor. Neither is saved -- not saved, same
## as timer/move_target for every other in-progress state, so a reload
## just restarts the spiral from her current anchor rather than losing
## anything that matters.
var search_angle: float = 0.0
var search_start_direction: float = 0.0
var search_waypoint: Vector2 = Vector2(INF, INF)
## Slice 6: the point the current SEARCHING bout's spiral is actually
## centred on -- normally local_search_anchor, but a bout that outgrows
## forage_search_radius tries one known_patches entry before giving up
## for real (see search_for_flower), which recentres this without
## disturbing local_search_anchor itself. Not saved, same as the other
## SEARCHING-only fields above.
var search_origin: Vector2 = Vector2(INF, INF)
## Slice 6: whether this SEARCHING bout has already spent its one
## known_patches retry -- see search_for_flower. Reset fresh each bout.
var search_tried_patch: bool = false

## How many flowers in a row she's inspected and found already picked
## over (thin) or turned down outright -- see start_collecting and
## reject_flower in bee_foraging.gd. This is never known before she
## actually lands and inspects (nearest_flower's own pre-flight check
## only ever rules out a literally empty flower); it's purely a record
## of what her last few visits actually taught her. Once it reaches
## GameConfig.poor_patch_search_streak, seek_flower stops trying
## whatever's merely nearby and sends her straight into SEARCHING's
## widening spiral instead, on the theory that a patch that's kept
## disappointing her several visits running is worth leaving rather
## than picking over one more flower from.
var thin_visit_streak: int = 0

## Slice 6 (probabilistic choice and memory): the direction she's
## actually moving in, updated every frame she moves (see
## BeeMovement.move_towards). Only ever a unit vector (or the default,
## for a bee that hasn't moved yet) -- used to weight flower choice
## toward "ahead of me" over "behind me" at similar distances.
var heading: Vector2 = Vector2.RIGHT

# --- patch memory and species experience --------------------------
## Slice 6 (probabilistic choice and memory): a small ring buffer of
## distinct locations she's actually fed from, most-recent last.
## Consulted only when a SEARCHING bout gives up and needs a fresh
## anchor (see search_for_flower in bee_foraging.gd), before falling
## back to a full meadow scan. Reset to empty at every point that resets
## local_search_anchor to forage_start_point -- a fresh assignment
## shouldn't carry memory of a completely different part of the meadow.
var known_patches: Array[Vector2] = []

## Slice 7 (handling experience): visit count per species this bee has
## actually finished handling, only tracked when
## GameConfig.handling_experience_on is on -- see finish_collecting in
## bee_foraging.gd. Keyed by the same species-name strings
## flower.species_name/flower_species.gd already use. Persisted, same
## pattern as known_patches above.
var species_experience: Dictionary = {}

## Slice 7 (adaptive constancy): a 0..1 confidence score per species,
## rising on a completed handling bout (finish_collecting) and falling on
## a rejection (reject_flower), only tracked when
## GameConfig.adaptive_constancy_on is on. Feeds
## bee_foraging.gd::_weighted_flower_choice as an extra multiplier when
## probabilistic_choice_on is also on. Persisted, same pattern as
## known_patches above.
var species_confidence: Dictionary = {}

# --- scouting -----------------------------------------------------
## Scouting (see GameConfig.scouting_on) -- a brand-new forager's phase
## of trying a few different start points, timed, so it can settle on
## whichever paid off best rather than the player having to click "Pick
## a flower" for every bee. Under Floral constancy this also samples a
## different species each bout, see scout_species below.
## Not save-persisted; a bee saved mid-scout just resumes as a plain
## forager on load rather than continuing where it left off.
var is_scouting: bool = false
var scout_bout: int = 0
## Species committed to for the bout in progress, only ever set when
## GameConfig.floral_constancy_on is on. "" means this bout hasn't
## landed on a flower yet (or constancy is off, in which case it never
## gets set at all and the bout forages whatever's nearest).
var scout_species: String = ""
var scout_tried_species: Array = []
var scout_best_species: String = ""
var scout_best_rate: float = -1.0
## Winner-tracking for the current scouting run, alongside the fields
## above -- see SCOUTING_TOGGLE_PLAN.md section 2. Not save-persisted,
## same as the rest of the scouting block.
var scout_current_start_point: Vector2 = Vector2(INF, INF)
var scout_best_start_point: Vector2 = Vector2(INF, INF)

# --- trip rates and scoring ---------------------------------------
## Recruitment: a rolling average of this forager's own resource
## collection rate, weighted towards recent trips rather than a lifetime
## average, so it reacts to a patch going bad rather than staying
## anchored by its first few good trips. Compared against
## GameConfig.recruit_lower/upper_threshold_nectar/pollen at the hive
## entrance -- see BeeForaging.wait_at_entrance. Tracked for any forager
## whenever scouting or auto-recruitment is on, not just while scouting
## -- scouting just reads the same per-trip rate to score its bouts.
## Only becomes the EMA described above once past the grace window --
## see grace_rate_sum immediately below. Persisted (forager-history save
## design, 28 Aug 2026): same additive .get()-default pattern as
## known_patches/species_experience above, no FORMAT_VERSION bump. An
## older save simply has no key, and 0.0 is exactly a fresh bee's
## starting value, so old saves load unchanged.
var avg_collection_rate: float = 0.0
const RATE_EMA_WEIGHT := 0.3
## Running sum of trip rates while still inside the grace window (see
## trips_scored below) -- avg_collection_rate is a plain mean of these
## until she's settled, only switching to the EMA above once there are
## enough real trips behind it to smooth one lucky/unlucky trip out
## rather than being decided by it. See BeeForaging._score_trip.
## Persisted, same pattern as avg_collection_rate above.
var grace_rate_sum: float = 0.0
## How many trips this forager has actually been scored on since it last
## started being tracked (scouting or auto-recruitment turned on, or the
## bee created while either already was). Below GameConfig.recruit_grace_trips,
## avg_collection_rate is too young a number to judge -- a brand-new
## colony's first trips are always going to look weak, and a bee that's
## foraged happily for an hour reads exactly the same as a new one the
## instant the toggle is switched on, since neither has a scored trip
## yet. Judging either against the thresholds immediately is what let
## a whole starting colony pile up at the entrance and starve -- see
## BeeForaging.go_to_exit. Persisted, same pattern as avg_collection_rate
## above -- without this a reload silently reset every settled forager's
## recruitment history back to "brand new colony" grace period.
var trips_scored: int = 0
## Set while waiting at the entrance (see BeeForaging.wait_at_entrance) so
## the bee actually walks a couple of hex rows clear of the doorway
## instead of standing in it. INF means "not currently waiting".
var entrance_wait_target: Vector2 = Vector2(INF, INF)
## Sim time this trip out started, and the load captured at the start
## of its delivery (so a trip that empties into more than one cell
## still scores against the whole trip's take, not just the last
## cell's share). Both -1/0 sentinels outside a trip.
var trip_start_time: float = 0.0
var trip_load_amount: float = -1.0
## Foraging ecology plan Slice 1 (FORAGING_ECOLOGY_PLAN.md): trip timing
## broken into components, reset at the same points trip_start_time is
## and read out by _score_trip. trip_first_flower_time is the sim_time
## of this trip's first flower contact -- -1.0 means none yet, so
## search+flight time (trip_first_flower_time - trip_start_time) is only
## ever computed once it's real. trip_handling_seconds sums the time
## spent between a start_collecting/finish_collecting pair, across every
## flower visited this trip, not just the last one. trip_flowers_visited
## is a plain per-trip count, distinct from DiagnosticLog's lifetime
## total. flower_visit_started_at is per-visit scratch, not per-trip --
## it only ever needs to survive from one start_collecting call to its
## matching finish_collecting.
var trip_first_flower_time: float = -1.0
var trip_handling_seconds: float = 0.0
var trip_flowers_visited: int = 0
var flower_visit_started_at: float = -1.0

# --- recruitment and dancing --------------------------------------
## Set on both bees the instant a recruitment match happens at the
## entrance (see BeeForaging.wait_at_entrance) so their next several
## scored trips can each be logged against the rate each had *before* the
## match -- see BeeForaging._score_trip/RECRUIT_FOLLOWUP_TRIPS. Tracks
## both sides, not just the seeker: the mentor keeps working the same
## patch she just handed out the start point for, so if a followed-onto
## patch is worse for the one who was already there too, this is what
## shows it. Not save-persisted, same as the rest of the
## scouting/recruitment block: a bee saved mid-check just drops the
## comparison rather than resuming it on load.
var recruit_partner: Node2D = null
var recruit_role: String = ""
var recruit_rate_before: float = -1.0
var recruit_followup_remaining: int = 0
## Slice 9 (proximity recruitment): the other bee in an in-progress
## State.DANCING exchange, and which side of it this bee is ("mentor" or
## "seeker") -- see BeeForaging.dance/_complete_dance. pre_dance_state/
## pre_dance_timer stash whatever this bee was doing (and how far into
## it) the moment the dance interrupted her, so she resumes exactly
## there rather than being sent anywhere new -- -1 means "not dancing".
## Not save-persisted, same as the rest of the recruitment block.
var dance_partner: Node2D = null
var dance_role: String = ""
var pre_dance_state: int = -1
var pre_dance_timer: float = 0.0
## One recruit per mentor per hive visit -- see hive.gd's
## add_dance_eligible_mentor and world_building.gd's move_bee_into_hive
## (where this resets). Not save-persisted; a bee saved mid-visit just
## gets a fresh chance to dance again on load, which is harmless.
var has_danced_this_visit: bool = false
## Set the first time trips_scored reaches recruit_grace_trips, so
## DiagnosticLog.log_forager_settled fires exactly once per bee -- see
## BeeForaging._score_trip. Gives a standing, always-on source for the
## per-forager rate distribution (recruit_lower/upper_threshold_nectar/
## pollen were derived from exactly this reading, gathered by hand before
## this event existed -- see game_config.gd) without needing a one-off
## debug print re-added every time the thresholds need rechecking.
var settled_rate_logged: bool = false

# --- build and mine queues ----------------------------------------
## A player-placed manual cell site a builder should try first, before
## falling back to its usual pick-a-site logic. Consumed (cleared) the
## moment it's acted on, successfully or not, so a bad click can't loop.
var manual_build_hex: Vector2i = Vector2i.ZERO
var has_manual_build_target: bool = false
## Tiles this comb worker has been told to build on, in the order they were
## clicked. Only this bee works its own queue; other comb workers pick
## their own sites as before.
var build_queue: Array = []
## The same for a miner: blocks it has been told to dig, in order.
var mine_queue: Array = []

## A comb worker's own centre of operations. Left to pick its own sites it
## fills the space around this tile outwards in a honeycomb spiral,
## rather than always adding to the middle of the comb -- so two
## comb workers with different home cells grow the hive in two places.
var home_hex: Vector2i = Vector2i.ZERO
var has_home_hex: bool = false
## The same idea for miners: the tile a miner works outward from when
## choosing which soil to dig next.
var mine_home_hex: Vector2i = Vector2i.ZERO
var has_mine_home: bool = false

# --- flower cooldowns and predator memory -------------------------
## Flowers this bee has drained, mapped to the sim-time at which they
## should be back to full. Time-based rather than checking the flower's
## live amount, so a bee commits to staying away for the whole recharge
## rather than darting back the moment a trickle appears.
##
## This is deliberately soft memory: BeeForaging.nearest_flower() relaxes
## it when nothing else qualifies (see that function's own comment)
## rather than have a bee stand starving over a spent flower. That's the
## right call for "this was recently stripped" but the wrong one for
## "a spider is sitting on this" -- see predator_flower_cooldowns below.
var flower_cooldowns: Dictionary = {}

## Same shape as flower_cooldowns, but for exactly the flower a crab
## spider ambush happened at (see CrabSpider.resolve_attack) -- kept
## separate so it's never in the pool nearest_flower() relaxes under
## scarcity. Real bees that survive an attack abandon that flower
## outright (CRAB_SPIDER_PLAN.md's biology section), not "unless nothing
## else is nearby" -- a bee low on options should go hungry a little
## longer or try a different species, not walk back into the same spider.
var predator_flower_cooldowns: Dictionary = {}

## Crab spiders (see CRAB_SPIDER_PLAN.md section 4) -- set at the moment
## this bee escapes an ambush. Not a permanent mark: recruitment
## suppression (Bundle 3) compares her *current* forage_start_point/
## preferred_species against this snapshot, so it lifts on its own once
## she's genuinely moved on rather than needing a timer or a clear-flag
## hook.
var was_attacked_by_predator: bool = false
var attacked_at_start_point: Vector2 = Vector2(INF, INF)
var attacked_at_preferred_species: String = ""
## Sim-time until which alarm_ring (below) shows -- set by
## CrabSpider.flee_alarm when alarm_pheromone_on lets this bee notice an
## alarmed flower and turn away before ever risking State.COLLECTING.
## Same brief-flash duration as a flower's own reveal (section 7); the
## point is a visible signal on the bee reacting, not just her quietly
## not feeding.
var alarm_flash_until: float = -999.0
## Sim-time until which attack_ring (below) shows -- set by
## CrabSpider.resolve_attack the instant a bee is actually attacked and
## narrowly escapes. A separate signal from alarm_ring above: that one
## fires when alarm_pheromone_on lets a bee avoid the risk entirely,
## this one fires when she took the risk and survived it, which needs
## its own visible tell or those two very different outcomes look
## identical from the outside.
var attack_flash_until: float = -999.0

# --- pathfinding inside the hive ----------------------------------
## Cached route while walking inside the hive -- see _move_towards.
var path_points: PackedVector2Array = PackedVector2Array()
var path_index: int = 0
var path_goal: Vector2 = Vector2(INF, INF)

# --- the visual nodes ---------------------------------------------
## Every visual child (rings, body, label) hangs off this instead of the
## bee node itself, so bumble flight (see _update_wander_flight) can drift
## the whole visual stack a few pixels off the real position without
## touching bee.position -- everything that reads bee.position (arrival
## checks, obstacle steering, the stall watchdog) stays exact.
var visual_root: Node2D

## Rolled once at spawn, like tint/size jitter, so a knot of bees flying
## together don't all wobble in lockstep. See _update_wander_flight.
var wander_phase: float = 0.0

## Set true by bee_movement.gd's move_towards whenever this bee actually
## moves outdoors this frame, cleared before the state machine runs each
## _process -- so it reflects only this frame's movement. Read by
## _update_wander_flight below.
var flying_outdoors: bool = false

var label: Label
var selection_ring: Polygon2D
var alarm_ring: Polygon2D
var attack_ring: Polygon2D
var body: Polygon2D
## A thin ring nested just inside the black outline (miner: brown, nurse:
## white, comb worker: wax colour) and a small dot at the centre (forager:
## light yellow on pollen, light blue on nectar). Role tells that read from
## further away than the label text, and that don't depend on
## Session.show_forager_labels being on. See _update_role_marker.
var outline_ring: Polygon2D
var centre_dot: Polygon2D

## A bright wedge pointing along bee.heading, foragers only, outdoors
## only. Slice 5's probabilistic flower choice already weighs on heading
## (bee_foraging.gd) but nothing showed it on screen -- there was no way
## to watch a forager favour the flower ahead of her over a nearer one
## behind. See _update_heading_marker.
var heading_marker: Polygon2D

## A pulsing ring, shown only in State.SEARCHING (Slice 5's expanding
## spiral). task_description() already named this state in the selection
## panel, but nothing distinguished a searching bee from one still
## seeking or already committed at a glance, in a crowd, without
## clicking her. See _update_search_ring.
var search_ring: Polygon2D

## A pulsing ring on each half of an in-progress recruitment dance,
## shown only while Session.show_recruitment_highlight is on. A dance is
## two bees standing together indoors among however many others are
## milling about the comb, for the length of one timer, and the only
## outward sign was the selection panel text -- which needs the right bee
## picked first. See _update_dance_ring.
var dance_ring: Polygon2D

# --- _ready and construction --------------------------------------
func _ready() -> void:
	add_to_group("bees")
	# Newly built cells and freshly-mined floor tiles get added to
	# hive_root's child list after bees that already exist, which made
	# them draw on top -- Godot draws same-z siblings in child order, and
	# reparenting/adding doesn't reshuffle existing children. Giving bees
	# a fixed z_index above the static furniture (floor, soil, cells, all
	# left at the default 0) means draw order no longer depends on when
	# each node happened to be added.
	z_index = 5

	flower_handling_time = GameConfig.flower_handling_time
	deposit_time = GameConfig.deposit_time
	energy = GameConfig.energy_capacity

	# One rolled stat trait, small and leaning positive -- see
	# bee_identity.gd and BEE_INDIVIDUALITY_PLAN.md. _apply_stats() does
	# the actual multiplying, and is called again by saving.gd after a
	# save restores trait_stat/trait_percent, so a reload lands on
	# exactly the same numbers rather than keeping this random roll.
	var trait_roll: Dictionary = BeeIdentity.roll_trait_stat()
	trait_stat = trait_roll.stat
	trait_percent = trait_roll.percent
	_apply_stats()

	bee_name = BeeIdentity.roll_name()

	# Visual jitter: a small brightness and size nudge, purely cosmetic
	# (rule 3), so it's fine that this simply rerolls on a save/load
	# rebuild rather than being saved. Size scales the whole node, not
	# just the body, so the outline, rings and label all stay aligned --
	# see the field comments below.
	tint_factor = randf_range(1.0 - GameConfig.visual_tint_jitter_range, 1.0 + GameConfig.visual_tint_jitter_range)
	size_jitter = randf_range(1.0 - GameConfig.visual_size_jitter_range, 1.0 + GameConfig.visual_size_jitter_range)
	scale = Vector2.ONE * size_jitter

	# A gyne sits visibly between a worker and the queen, so you can pick
	# one out of a crowd without selecting it.
	var size_factor: float = 1.0
	if is_queen:
		size_factor = 1.55
	elif is_gyne:
		size_factor = GameConfig.gyne_size_factor
	var body_radius: float = 6.5 * size_factor
	var outline_radius: float = 9.0 * size_factor
	click_radius = (outline_radius + 5.0) * size_jitter

	wander_phase = randf() * TAU

	visual_root = Node2D.new()
	add_child(visual_root)

	selection_ring = Polygon2D.new()
	selection_ring.polygon = Shapes.circle_points(outline_radius + 4.0)
	selection_ring.color = Color(0.2, 1.0, 0.4, 0.85)
	selection_ring.visible = false
	visual_root.add_child(selection_ring)

	# Alarm-pheromone flee flash (see CRAB_SPIDER_PLAN.md sections 5/7) --
	# a distinct ring, outside selection_ring, so the two never get read
	# as the same thing. Only ever shown by CrabSpider.flee_alarm.
	alarm_ring = Polygon2D.new()
	alarm_ring.polygon = Shapes.circle_points(outline_radius + 8.0)
	alarm_ring.color = Color(1.0, 0.55, 0.0, 0.85)
	alarm_ring.visible = false
	visual_root.add_child(alarm_ring)

	# Attack flash (see CRAB_SPIDER_PLAN.md section 4) -- a bee who was
	# actually attacked and escaped, not just one who noticed the alarm
	# mark and turned away. Red rather than alarm_ring's orange, and a
	# touch further out, so the two read as clearly different events.
	# Only ever shown by CrabSpider.resolve_attack's escape branch.
	attack_ring = Polygon2D.new()
	attack_ring.polygon = Shapes.circle_points(outline_radius + 11.0)
	attack_ring.color = Color(0.95, 0.1, 0.1, 0.85)
	attack_ring.visible = false
	visual_root.add_child(attack_ring)

	# Further out than selection/alarm/attack (none of which overlap it in
	# practice -- SEARCHING is a foraging-only state) and a colour none of
	# them use, so it never reads as one of those instead.
	search_ring = Polygon2D.new()
	search_ring.polygon = Shapes.circle_points(outline_radius + 14.0)
	search_ring.color = Color(0.65, 0.25, 0.95, 0.85)
	search_ring.visible = false
	visual_root.add_child(search_ring)

	# Outside search_ring so the two never sit on top of each other -- a
	# bee can be SEARCHING one moment and DANCING the next, and the pair
	# needs to read as a pair. No colour here, unlike the four above:
	# which of the two this bee wears depends on which side of the dance
	# she is on, which is not known until she dances, so _update_dance_ring
	# sets it in the same frame it makes the ring visible.
	dance_ring = Polygon2D.new()
	dance_ring.polygon = Shapes.circle_points(outline_radius + 17.0)
	dance_ring.visible = false
	visual_root.add_child(dance_ring)

	var outline := Polygon2D.new()
	outline.polygon = Shapes.circle_points(outline_radius)
	outline.color = Color(0.05, 0.05, 0.05)   # black outline
	visual_root.add_child(outline)

	# Sits between the outline and the body -- see the field comment above
	# -- so it draws as a thin ring just inside the black edge rather than
	# a dot or a full-radius circle. Radius is fixed at creation; only its
	# colour and visibility change afterwards, in _update_role_marker.
	outline_ring = Polygon2D.new()
	outline_ring.polygon = Shapes.circle_points(outline_radius - 1.5 * size_factor)
	outline_ring.visible = false
	visual_root.add_child(outline_ring)

	body = Polygon2D.new()
	body.polygon = Shapes.circle_points(body_radius)
	body.color = _tinted(_base_colour())
	visual_root.add_child(body)

	# Drawn after the body, so it sits on top as a small dot rather than
	# being covered by it.
	centre_dot = Polygon2D.new()
	centre_dot.polygon = Shapes.circle_points(body_radius * 0.35)
	centre_dot.visible = false
	visual_root.add_child(centre_dot)

	# A wedge pointing along heading, deliberately brighter/larger than
	# the role markers so it reads from a distance rather than needing a
	# close look. Rest shape points along local +X; _update_heading_marker
	# rotates the whole node to the live heading each frame.
	heading_marker = Polygon2D.new()
	var tip: float = outline_radius + 7.0
	var wedge_base: float = outline_radius - 1.0
	var half_width: float = 4.5
	heading_marker.polygon = PackedVector2Array([
		Vector2(tip, 0.0),
		Vector2(wedge_base, -half_width),
		Vector2(wedge_base, half_width),
	])
	heading_marker.color = Color(1.0, 1.0, 1.0, 0.95)
	heading_marker.visible = false
	visual_root.add_child(heading_marker)

	label = Label.new()
	label.position = Vector2(-16, -32 if not is_queen else -40)
	label.add_theme_font_size_override("font_size", 12)
	visual_root.add_child(label)

	_update_role_marker()

# --- setup, stats and appearance ----------------------------------
func setup(hive_node: Node2D, type: String, id: int, bee_role: int = Role.FORAGER, world_node: Node2D = null) -> void:
	hive = hive_node
	world = world_node
	resource_type = type
	bee_id = id
	# Mining dispatch has its own stable phase.  Keep the older general think
	# jitter untouched: it also schedules stall and survival checks.
	_miner_dispatch_timer = float(bee_id % int(THINKS_PER_SECOND)) / THINKS_PER_SECOND
	role = bee_role
	if world != null and is_instance_valid(world):
		world.invalidate_population()
	if is_queen:
		# The queen's day used to be eat, lay, wait, eat, lay. Nursing is
		# her natural second job -- she is in the brood nest anyway -- so
		# she picks it up automatically whenever laying is blocked. The
		# player can change it like any other bee's backup role.
		if secondary_role == -1:
			secondary_role = Role.NURSERY
	# Only reachable here, not _ready(): a milestone fact needs bee_id
	# and world, neither of which is set until setup() runs. See
	# BEE_INDIVIDUALITY_PLAN.md section 5.
	_roll_fact()
	# A brand-new forager scouts a few start points before settling,
	# rather than hunting the nearest flower of nothing in particular --
	# see BeeForaging.start_scouting. Orientation flight is scouting's
	# simpler fallback: one point, kept, no comparison. Only at creation:
	# a bee switched into Forager later (set_role) keeps whatever
	# preference it already had.
	if GameConfig.scouting_on and bee_role == Role.FORAGER:
		BeeForaging.start_scouting(self)
	elif BeeForaging.orientation_flight_on() and bee_role == Role.FORAGER:
		BeeForaging.take_orientation_flight(self)
	else:
		state = _default_state_for_role()
	_update_label()
	_update_role_marker()

## Milestone bees get a deterministic fact instead of a rolled one --
## see BEE_INDIVIDUALITY_PLAN.md section 5. Checked in a fixed order so
## a bee can only ever claim one milestone: the very first bee (id 0,
## which is also the founding queen), then the first gyne ever raised,
## then every Nth bee after that.
func _roll_fact() -> void:
	if bee_id == 0:
		bee_fact = BeeIdentity.milestone_fact_first_bee()
		return
	if is_gyne and world != null and is_instance_valid(world) and not world.first_gyne_seen:
		world.first_gyne_seen = true
		bee_fact = BeeIdentity.milestone_fact_first_gyne()
		return
	var interval: int = int(GameConfig.milestone_interval)
	if interval > 0 and bee_id % interval == 0:
		bee_fact = BeeIdentity.milestone_fact_nth(bee_id)
		return
	bee_fact = BeeIdentity.roll_fact(trait_stat)

func _default_state_for_role() -> int:
	match role:
		Role.NURSERY:
			return State.NURSE_IDLE
		Role.BUILDER:
			return State.BUILD_IDLE
		Role.EGG_LAYER:
			# Deliberately an idle state rather than SEEK_POLLEN: it sends
			# the queen through _idle_dispatch, which checks the brood
			# before it checks laying. Going straight to SEEK_POLLEN would
			# have her start on the next egg without ever looking at the
			# larvae she already has.
			return State.NURSE_IDLE
		Role.IDLE:
			return State.IDLING
		Role.MINER:
			return State.MINE_IDLE
		Role.HONEY_MAKER:
			return State.HONEY_IDLE
		_:
			return State.SEEK_FLOWER

func _base_colour() -> Color:
	if is_queen:
		return Color(0.95, 0.45, 0.75)
	if is_gyne:
		return Color(1.0, 0.62, 0.35)   # between a worker's yellow and the queen's pink
	return Color(1.0, 0.85, 0.1)

## The role colour with this bee's individual brightness jitter applied
## -- a nudge, not a hue shift, so role stays identifiable at a glance
## (Roles.colour_for and the colour-blind tag system depend on colour
## meaning role). Alpha is left alone.
func _tinted(c: Color) -> Color:
	return Color(
		clampf(c.r * tint_factor, 0.0, 1.0),
		clampf(c.g * tint_factor, 0.0, 1.0),
		clampf(c.b * tint_factor, 0.0, 1.0),
		c.a
	)

## Recomputes every stat GameConfig can influence: the shared base
## value, this bee's rolled trait (if any), and the queen/gyne speed
## adjustment. Called from _ready() at spawn, and again by
## saving.gd::_restore_bees after a save restores trait_stat/
## trait_percent -- always resetting from the GameConfig base rather
## than multiplying whatever's already there, so it's safe to call more
## than once and always lands on the same numbers for the same trait.
func _apply_stats() -> void:
	speed = GameConfig.bee_speed
	nectar_collection_rate = GameConfig.nectar_collection_rate
	pollen_collection_rate = GameConfig.pollen_collection_rate
	nectar_stomach_capacity = GameConfig.nectar_stomach_capacity
	pollen_stomach_capacity = GameConfig.pollen_stomach_capacity
	if trait_stat != "":
		var factor: float = 1.0 + trait_percent
		match trait_stat:
			"speed":
				speed *= factor
			"nectar_collection_rate":
				nectar_collection_rate *= factor
			"pollen_collection_rate":
				pollen_collection_rate *= factor
			"nectar_stomach_capacity":
				nectar_stomach_capacity *= factor
			"pollen_stomach_capacity":
				pollen_stomach_capacity *= factor
	if is_gyne:
		speed *= GameConfig.gyne_speed_factor
	if is_queen:
		speed *= GameConfig.queen_speed_factor

## A short readout of this bee's trait, e.g. "Speed +7%", or "" if
## somehow unrolled.
func trait_text() -> String:
	if trait_stat == "":
		return ""
	return "%s %s" % [BeeIdentity.stat_label(trait_stat), BeeIdentity.trait_percent_text(trait_percent)]

## Sets which of the two role markers (see the field comments) is showing
## and what colour it is. Called on creation, whenever the role changes,
## and whenever a forager's resource_type changes -- anywhere the thing it
## is telling you about could be out of date otherwise.
func _update_role_marker() -> void:
	if outline_ring == null or centre_dot == null:
		return
	outline_ring.visible = false
	centre_dot.visible = false
	match role:
		Role.FORAGER:
			centre_dot.visible = true
			centre_dot.color = Color(1.0, 1.0, 0.6) if resource_type == "pollen" else Color(0.6, 0.85, 1.0)
		Role.MINER:
			outline_ring.visible = true
			outline_ring.color = Color(0.55, 0.35, 0.18)   # brown
		Role.NURSERY:
			outline_ring.visible = true
			outline_ring.color = Color(1.0, 1.0, 1.0)      # white
		Role.BUILDER:
			outline_ring.visible = true
			outline_ring.color = HiveCell.EMPTY_COLOR      # same as an empty wax cell

# --- how often a bee thinks ---------------------------------------
## Movement has to happen every frame or bees stutter. *Deciding* things
## does not: a bee choosing a flower, checking whether it is hungry, or
## looking for work is making a judgement on a scale of seconds, and
## asking sixty times a second is sixty times more often than the answer
## can change.
##
## So the state machine runs every frame (it is mostly movement) but the
## expensive judgements behind it -- searching the comb for work, picking
## a flower, scanning for a stall -- run on a slower tick. At 8 a second
## no behaviour is visibly different and the per-bee cost of the parts
## that scale badly drops by roughly seven eighths.
##
## Each bee's tick is offset by its own id, so they don't all think on
## the same frame and produce a spike. This is the single biggest thing
## standing between the current colony size and a much larger one.
const THINKS_PER_SECOND := 8.0
var think_timer: float = 0.0
## Real time since this bee last thought, so anything measured in
## seconds (the stall watchdog) counts wall time rather than ticks.
var since_last_think: float = 0.0
## True on the frames where the slow work is allowed to happen.
var thinking: bool = false

## A failed mining search stays valid only until the Hive work owner says
## otherwise.  This prevents every idle miner from walking the global soil
## collection again on every think tick when there is no work.
var _mining_no_work_epoch: int = -1
var _mining_no_work_automine: bool = false
var _miner_dispatch_timer: float = 0.0
var _miner_dispatch_due: bool = false

func _process(delta: float) -> void:
	Perf.begin("bees")
	if hive == null or is_dying:
		Perf.end("bees")
		return

	# Staggered by a random jitter so the colony's thinking is spread
	# across frames rather than landing on one.
	think_timer -= delta
	since_last_think += delta
	thinking = think_timer <= 0.0
	var think_delta: float = since_last_think
	if thinking:
		think_timer = (1.0 / THINKS_PER_SECOND) * randf_range(0.85, 1.15)
		since_last_think = 0.0

	# Miner job selection is deliberately independent from the general think
	# jitter: stable IDs spread dispatches deterministically across the same
	# bounded 8 Hz cadence without perturbing any other random decisions.
	_miner_dispatch_due = false
	_miner_dispatch_timer -= delta
	while _miner_dispatch_timer <= 0.0:
		_miner_dispatch_timer += 1.0 / THINKS_PER_SECOND
		_miner_dispatch_due = true

	Perf.begin("bee_burn")
	BeeSurvival.age_and_burn(self, delta)
	Perf.end("bee_burn")
	if not is_inside_tree():
		Perf.end("bees")
		return   # died during ageing

	if thinking:
		Perf.begin("bee_think")
		BeeSurvival.watch_for_stalls(self, think_delta)

		# A queued role change lands the moment the bee is free. Checked
		# here rather than only in the idle states because not every job
		# ends in one -- a forager that finishes a walk-to-point drops
		# straight into looking for a flower, and would otherwise never
		# pick the change up.
		if pending_role != -1 and not _is_busy():
			_apply_pending_role()

		# Backup building/mining is the one case secondary_role's "drops it
		# the instant primary work turns up" promise doesn't already hold --
		# both can run for a whole cell or block, far longer than the gap
		# between idle-dispatch checks. With "Finish the job first" off the
		# player has said the same thing for a manual reassignment; this is
		# that promise applied automatically. See _maybe_break_off_secondary.
		if working_secondary and not finish_task_first:
			_maybe_break_off_secondary()

		# Eating is an errand now, not a number that quietly appears. A
		# bee that has run low breaks off whatever it was doing, walks to
		# a cell with food in it and feeds there. Checked before the
		# state machine so it can interrupt anything.
		if BeeSurvival.should_go_and_eat(self):
			BeeSurvival.begin_feeding_self(self)
		Perf.end("bee_think")

	# Cleared before the state machine runs so it reflects only this
	# frame's movement -- bee_movement.gd's move_towards sets it back to
	# true from inside the outdoor branch, if that's what actually runs
	# below. See _update_wander_flight.
	flying_outdoors = false

	# Runs every frame, not just on a think tick -- unlike the block
	# above, so this is where a per-state handler that does real search
	# or scan work (rather than just walking) would show up as costing
	# far more than THINKS_PER_SECOND would suggest.
	Perf.begin("bee_state")
	# Nested under a second, role-specific section so the breakdown can
	# answer "is it every bee, or one role" without needing a second
	# playtest -- both cover exactly the same code, so bee_state stays
	# the total and the per-role ones are how it's split.
	var role_section: String = ROLE_PERF_SECTIONS[role] if role >= 0 and role < ROLE_PERF_SECTIONS.size() else "bee_state"
	Perf.begin(role_section)
	match state:
		# --- forager, outdoors ---
		# Individually timed rather than lumped into bee_state_forager:
		# Dave's colony is 25/33 foragers cycling through here, and this
		# is where the plan's suspect list runs out -- bee_move and
		# bee_path both read 0ms, so whatever it is has to be one of
		# these specific branches rather than the moving between them.
		State.SEEK_FLOWER:
			Perf.begin("bee_seek_flower")
			BeeForaging.seek_flower(self)
			Perf.end("bee_seek_flower")
		State.SEARCHING:
			Perf.begin("bee_search")
			BeeForaging.search_for_flower(self, delta)
			Perf.end("bee_search")
		State.TO_FLOWER:
			Perf.begin("bee_to_flower")
			# is_instance_valid too, not just null -- a flower that died
			# mid-flight (flower_lifespan_days) leaves current_flower
			# pointing at a freed instance, not a null one. Every other
			# flower-handling function here (inspect, drink_at_flower,
			# collect) already guards both; this one didn't, so a bee
			# flying towards a flower that happened to die under it errored
			# on current_flower.position every frame from then on and never
			# left this state -- found via foraging_features_on_test.json,
			# where scouting's extra churn through fresh flowers made the
			# odds of catching a dying one high enough to strand most of
			# the colony within the first week.
			if current_flower == null or not is_instance_valid(current_flower):
				current_flower = null
				state = State.TO_HIVE if flower_switch_locked else State.SEEK_FLOWER
			else:
				BeeMovement.move_towards(self, current_flower.position, delta)
				if position.distance_to(current_flower.position) < arrive_distance:
					BeeForaging.start_inspecting(self)
			Perf.end("bee_to_flower")
		State.INSPECTING:
			Perf.begin("bee_inspecting")
			BeeForaging.inspect(self, delta)
			Perf.end("bee_inspecting")
		State.COLLECTING:
			Perf.begin("bee_collecting")
			BeeForaging.collect(self, delta)
			Perf.end("bee_collecting")
		State.DRINKING:
			BeeForaging.drink_at_flower(self, delta)
		State.TO_HIVE:
			Perf.begin("bee_to_hive")
			BeeMovement.move_towards(self, hive.position, delta)
			if position.distance_to(hive.position) < arrive_distance:
				BeeForaging.enter_hive(self)
			Perf.end("bee_to_hive")
		State.SHELTERING:
			BeeForaging.shelter(self, delta)
		State.AT_ENTRANCE_SEEKING, State.AT_ENTRANCE_MENTORING:
			BeeForaging.wait_at_entrance(self, delta)
		State.DANCING:
			BeeForaging.dance(self, delta)

		# --- nursery, making royal jelly ---
		State.MAKING_JELLY:
			BeeNursery.nurse_make_jelly(self, delta)
		State.TO_JELLY_CELL:
			BeeNursery.nurse_go_to_jelly_cell(self, delta)
		State.DEPOSITING_JELLY:
			BeeNursery.nurse_deposit_jelly(self, delta)

		# --- forager, indoors ---
		State.IN_HIVE_TO_CELL:
			Perf.begin("bee_to_cell")
			BeeForaging.go_to_deposit_cell(self, delta)
			Perf.end("bee_to_cell")
		State.DEPOSITING:
			timer -= delta
			if timer <= 0.0:
				BeeForaging.finish_depositing(self)
		State.IN_HIVE_TO_EXIT:
			Perf.begin("bee_to_exit")
			BeeForaging.go_to_exit(self, delta)
			Perf.end("bee_to_exit")

		State.MOVE_TO_POINT:
			BeeMovement.move_towards(self, move_target, delta)
			if position.distance_to(move_target) < arrive_distance:
				state = _default_state_for_role()
		State.IDLING:
			pass   # waits for orders and nothing else

		# --- nursery ---
		State.NURSE_IDLE:
			_idle_dispatch()
		State.TO_BROOD:
			BeeNursery.nurse_go_to_brood(self, delta)
		State.TENDING:
			BeeNursery.nurse_tend(self, delta)
		State.TO_FOOD_CELL:
			BeeNursery.nurse_go_to_food(self, delta)
		State.LOADING_FOOD:
			BeeNursery.nurse_load_food(self, delta)

		# --- eating (any role) ---
		State.TO_FEED_CELL:
			BeeSurvival.go_to_feed_cell(self, delta)
		State.FEEDING:
			BeeSurvival.feed_self(self, delta)

		# --- builder ---
		State.BUILD_IDLE:
			_idle_dispatch()
		State.TO_BUILD_SITE:
			BeeBuilding.builder_go_to_site(self, delta)
		State.BUILDING:
			BeeBuilding.builder_build(self, delta)
		State.TO_RESTOCK_SOURCE:
			BeeBuilding.restock_go_to_source(self, delta)
		State.TO_RESTOCK_TARGET:
			BeeBuilding.restock_go_to_target(self, delta)
		State.TO_HAUL_SOURCE:
			BeeBuilding.builder_go_to_haul_source(self, delta)
		State.TO_HAUL_TARGET:
			BeeBuilding.builder_go_to_haul_target(self, delta)
		State.TO_WASTE_EXIT:
			BeeBuilding.builder_go_to_waste_exit(self, delta)
		State.DUMPING_WASTE:
			BeeBuilding.builder_dump_waste(self, delta)
		State.TO_CLEAN_CELL:
			BeeBuilding.architect_go_to_clean(self, delta)
		State.CLEANING:
			BeeBuilding.architect_clean(self, delta)

		# --- miner ---
		State.MINE_IDLE:
			if _miner_dispatch_due:
				_idle_dispatch()
		State.TO_MINE_SITE:
			BeeMining.miner_go_to_site(self, delta)
		State.MINING:
			BeeMining.miner_dig(self, delta)
		State.TO_MINE_EXIT:
			BeeMining.miner_go_to_exit(self, delta)
		State.DUMPING_DIRT:
			BeeMining.miner_dump(self, delta)

		# --- honey maker ---
		State.HONEY_IDLE:
			_idle_dispatch()
		State.TO_NECTAR_CELL:
			BeeHoney.honey_go_to_nectar(self, delta)
		State.CHEWING:
			BeeHoney.honey_chew(self, delta)
		State.TO_HONEY_CELL:
			BeeHoney.honey_go_to_pot(self, delta)
		State.DEPOSITING_HONEY:
			BeeHoney.honey_deposit(self, delta)
		State.FANNING:
			BeeHoney.honey_fan(self, delta)

		# --- egg layer ---
		State.SEEK_POLLEN:
			BeeEggLaying.queen_seek_pollen(self)
		State.TO_POLLEN_CELL:
			BeeEggLaying.queen_go_to_pollen(self, delta)
		State.EATING:
			BeeEggLaying.queen_eat(self, delta)
		State.TO_CELL_TO_LAY:
			BeeEggLaying.queen_go_to_lay(self, delta)
		State.LAYING:
			BeeEggLaying.queen_lay(self, delta)
	Perf.end(role_section)
	Perf.end("bee_state")

	# Slice 9 (proximity recruitment): checked continuously, not on a
	# single decision point, since a mentor/seeker pair can cross paths at
	# any moment during ordinary indoor movement -- see
	# BeeForaging.check_dance_proximity. New per-frame cost, so its own
	# span per .claude/rules/performance.md.
	if GameConfig.proximity_recruitment_on and role == Role.FORAGER and state != State.DANCING:
		Perf.begin("recruitment_dance")
		BeeForaging.check_dance_proximity(self, delta)
		Perf.end("recruitment_dance")

	Perf.begin("bee_label")
	_update_label()
	_update_alarm_ring()
	_update_heading_marker()
	_update_search_ring()
	_update_dance_ring()
	Perf.end("bee_label")

	Perf.begin("bee_wander")
	_update_wander_flight(delta)
	_update_dance_circle(delta)
	Perf.end("bee_wander")
	Perf.end("bees")

# --- life support -------------------------------------------------
## Moved to bee_survival.gd -- see BEE_SPLIT_PLAN.md.
# --- eating -------------------------------------------------------
## Moved to bee_survival.gd -- see BEE_SPLIT_PLAN.md.
# --- stall watchdog -----------------------------------------------
## Moved to bee_survival.gd -- see BEE_SPLIT_PLAN.md. reset_stall_watch
## stays here: bee_movement.gd's clear_navigation_state() (already
## split out) calls it directly, and moving it would make
## bee_movement.gd and bee_survival.gd preload each other.

func _reset_stall_watch() -> void:
	stall_best_distance = INF
	stall_timer = 0.0
# --- foraging -----------------------------------------------------
## Moved to bee_foraging.gd -- see BEE_SPLIT_PLAN.md.
# --- entering and leaving the hive --------------------------------
## Moved to bee_foraging.gd -- see BEE_SPLIT_PLAN.md.
# --- nursery work -------------------------------------------------
## Moved to bee_nursery.gd -- see BEE_SPLIT_PLAN.md.
# --- royal jelly ---------------------------------------------------
## Moved to bee_nursery.gd -- see BEE_SPLIT_PLAN.md.
# --- idle work dispatch --------------------------------------------

## Called every frame a bee is sitting in one of the three "waiting for
## work" states (NURSE_IDLE, BUILD_IDLE, MINE_IDLE -- interchangeable
## now, since this is the only thing any of them do). Tries the bee's
## real role first; only if that genuinely has nothing on offer does it
## try the secondary role instead. Because the fallback states above all
## route failures back to one of these same three idle states, a bee
## doing secondary work re-checks its primary role again the moment that
## task ends -- it never gets stuck permanently "being" its secondary.
## Idle states are exactly the moments a bee has finished something and
## has nothing in hand, so a queued role change is applied here. Foragers
## also apply theirs the moment they finish unloading, since standing in
## the hive holding nothing is not a state they pass through.
func _apply_pending_role() -> bool:
	if pending_role == -1:
		return false
	var wanted: int = pending_role
	pending_role = -1
	if wanted != role:
		_apply_role(wanted)
		return true
	return false

## GC-2. A bee reaching an idle state still holding a load puts it in a cell
## before starting anything else: a forager made a Miner mid-trip, or a Comb
## worker left with a remnant when a restock target filled. Only the
## forager's own routine used to deliver, so any other job kept the load
## aboard for good, and the next lift overwrote it. One choke point here
## rather than a guard per job (docs/known-pitfalls.md). When no cell had
## room and none has changed since, she gets on with her job instead.
func _deliver_held_load() -> bool:
	if is_queen:
		return false
	if current_load <= 0.0 or current_load_type == "":
		return false
	if not _is_inside_hive():
		return false
	if deposit_blocked_epoch == hive.index_epoch:
		return false
	state = State.IN_HIVE_TO_CELL
	return true

## Is this bee partway through something worth finishing? Everything
## except the "waiting for work" states and standing idle.
func _is_busy() -> bool:
	match state:
		State.IDLING, State.NURSE_IDLE, State.BUILD_IDLE, State.MINE_IDLE, State.HONEY_IDLE, State.SEEK_FLOWER, State.SEARCHING:
			return false
	return true

func _idle_dispatch() -> void:
	if _apply_pending_role():
		return
	if _deliver_held_load():
		return

	# The queen is the exception to "own role first". A hungry larva stops
	# developing altogether and can be lost, whereas a delayed egg costs
	# only time -- so she feeds the brood she already has before making
	# more. Any other bee, and a queen whose backup the player has
	# changed, still works its own role first.
	if is_queen and role == Role.EGG_LAYER and secondary_role != -1 and (role_restricted_to.is_empty() or secondary_role in role_restricted_to):
		if _try_role_work(secondary_role):
			return

	working_secondary = false
	if _try_role_work(role):
		return
	if secondary_role != -1 and secondary_role != role and (role_restricted_to.is_empty() or secondary_role in role_restricted_to):
		working_secondary = _try_role_work(secondary_role)

## Called on a think tick while working_secondary and "Finish the job
## first" is off. Only building and mining are long enough to need this --
## everything else a secondary role can be doing routes back through an
## idle state (BUILD_IDLE/MINE_IDLE/NURSE_IDLE) often enough on its own.
## Both keep their progress on the cell/block itself when abandoned (see
## builder_build/miner_dig), the same as a bee that wanders off mid-job
## today, so breaking off here costs nothing but the walk back.
func _maybe_break_off_secondary() -> void:
	var was_building: bool = state == State.TO_BUILD_SITE or state == State.BUILDING
	var was_mining: bool = state == State.TO_MINE_SITE or state == State.MINING
	if not (was_building or was_mining):
		return
	# Captured before the call: _try_role_work(role), if it succeeds,
	# overwrites target_cell/target_block with the new primary job's own
	# targets, so these are the only references left that still need
	# releasing.
	var old_cell: Node2D = target_cell if was_building else null
	var old_block: Node2D = target_block if was_mining else null
	working_secondary = false
	if not _try_role_work(role):
		# Nothing to switch to after all -- put it back and carry on.
		working_secondary = true
		return
	if old_cell != null and is_instance_valid(old_cell):
		old_cell.release_builder(self)
	if old_block != null and is_instance_valid(old_block):
		old_block.release_miner(self)

## Attempts to find and start one unit of work for role `r`. Returns
## true if it found something (and has already changed state), false if
## there was genuinely nothing to do.
func _try_role_work(r: int) -> bool:
	# The Hive owns mining-work invalidation. Keep this guard outside the
	# catalogue walk: otherwise an idle miner would still call all three
	# mining finders after it had already established this epoch has no work.
	if r == Role.MINER and _mining_no_work_epoch == hive.mining_work_epoch and _mining_no_work_automine == automine:
		return false
	var finder = ROLE_ACTION_FINDERS.get(r)
	if finder == null:
		return false
	# Resolved once, not per row: this runs on every idle bee's think tick.
	var mode: String = _action_mode_for_role(r)
	for action in _actions_by_role.get(r, []):
		var modes: Array = action.modes
		if not modes.is_empty() and not mode in modes:
			continue
		if action.gated and not _action_available(action.id):
			continue
		if finder.call(action.find, self):
			return true
	if r == Role.MINER:
		_mining_no_work_epoch = hive.mining_work_epoch
		_mining_no_work_automine = automine
	return false


static func _build_actions_by_role() -> Dictionary:
	var grouped: Dictionary = {}
	for action in Actions.ACTIONS:
		# The catalogue rows are const; the copy carries whether the row is
		# gated, worked out once here rather than per think tick.
		var row: Dictionary = action.duplicate()
		row["gated"] = Actions.is_gated(action)
		for action_role in action.roles:
			if not grouped.has(action_role):
				grouped[action_role] = []
			grouped[action_role].append(row)
	return grouped

## G3: Availability.action_query for one gated row, asked once per gate
## epoch rather than on every think tick.
func _action_available(action_id: String) -> bool:
	if _action_gate_epoch != Availability.gate_epoch:
		_action_gate_cache.clear()
		_action_gate_epoch = Availability.gate_epoch
	if not _action_gate_cache.has(action_id):
		var stage_gate = world.stage_gate if world != null else null
		_action_gate_cache[action_id] = Availability.action_query(action_id, self, stage_gate, Session.progression).available
	return _action_gate_cache[action_id]


func _action_mode_for_role(r: int) -> String:
	if r == Role.NURSERY:
		return nurse_mode
	if r == Role.BUILDER:
		return architect_mode
	if r == Role.MINER:
		return "automine" if automine else ""
	return ""

# --- building -----------------------------------------------------
## Moved to bee_building.gd -- see BEE_SPLIT_PLAN.md.
# --- keeping cells topped up ---------------------------------------
## Moved to bee_building.gd -- see BEE_SPLIT_PLAN.md. The four
## methods below stay as one-line wrappers because orders_zones.gd
## and hud.gd call them directly on a bee.
## A comb worker on the restock sub-mode has a list of cells it keeps full
## of one resource, drawing on the rest of the comb to do it.
##
## The point of it is placement. The colony's stores end up wherever the
## foragers happened to put them, which is fine until something needs to
## be *somewhere* -- honey next to the brood before winter, pollen within
## reach of the nursery, a reserve by the entrance. Rather than adding a
## new kind of bee, this is a job a comb worker can be given: it is already
## the caste that moves things between cells.
##
## The source list is what stops it undoing your own arrangements. With
## nothing chosen it takes from anywhere; name some cells and it takes
## only from those; block some and it leaves them alone. That is what
## lets you say "fill these from the outer comb, but never touch the
## winter store".

## Cells this comb worker keeps full, and of what.
var restock_targets: Array = []
var restock_resource: String = ""
## Cells it may draw on. Empty means anywhere that isn't blocked.
var restock_sources: Array = []
var restock_blocked: Array = []

## One-line wrappers -- orders_zones.gd and hud.gd call these directly on
## a bee, so the public API didn't move even though the logic did.
func set_restock_targets(cells: Array, resource: String) -> void:
	BeeBuilding.set_restock_targets(self, cells, resource)

func set_restock_sources(cells: Array, allowed: bool) -> void:
	BeeBuilding.set_restock_sources(self, cells, allowed)

func clear_restock() -> void:
	BeeBuilding.clear_restock(self)

func has_restock_orders() -> bool:
	return BeeBuilding.has_restock_orders(self)
# --- mining -------------------------------------------------------
## Moved to bee_mining.gd -- see BEE_SPLIT_PLAN.md.
# --- honey making -------------------------------------------------
## Moved to bee_honey.gd -- see BEE_SPLIT_PLAN.md.
# --- egg laying (queen only) --------------------------------------
## Moved to bee_egg_laying.gd -- see BEE_SPLIT_PLAN.md.
# --- player commands ----------------------------------------------

## `world_point` is a true global (screen-space-derived) position. Bee
## movement always works in local-to-parent coordinates -- `position` is
## a Node2D's local offset, not a global one -- so this converts once,
## here, rather than leaving every caller to remember to. Getting this
## wrong is exactly what sent bees drifting off to one side inside the
## hive: a global point was being compared directly against a local
## position, which only matches by coincidence in the meadow (where
## meadow_root sits at the origin).
func command_move_to(world_point: Vector2) -> void:
	_clear_pending_zone_command()
	var parent := get_parent()
	var target: Vector2 = parent.to_local(world_point) if parent else world_point
	# Inside the hive, a click can land on solid soil -- snap it to the
	# nearest open tile rather than sending the bee at a point it can
	# only reach by cutting straight through the wall.
	if _is_inside_hive() and hive and hive.has_method("nearest_walkable_point"):
		target = hive.nearest_walkable_point(target)
	else:
		# Out in the meadow the equivalent hazard is a click on a tree or
		# a raised area. The bee can't stand there, so it would creep up
		# to the boundary and never register as having arrived. Nudging
		# the destination out to the edge means it completes the order.
		target = BeeMovement.block_obstacles(self, target)
	move_target = target
	_release_everything()
	state = State.MOVE_TO_POINT

## Queue a move in the other zone, then take the ordinary entrance route.
func command_move_through_entrance(world_point: Vector2, target_in_hive: bool) -> void:
	_clear_pending_zone_command()
	pending_move_target = world_point
	_release_everything()
	state = State.TO_HIVE if target_in_hive else State.IN_HIVE_TO_EXIT

## Right-clicking the entrance tile (see input_selection.gd's
## _issue_command) sends a selected, indoor bee out through the door
## rather than to a plain point -- the same route BeeForaging.go_to_exit
## already walks automatically once a bee's job sends it home, just
## triggered directly rather than waiting on the state machine to get
## there on its own. Does nothing for a bee already outside.
func command_exit_hive() -> void:
	if not _is_inside_hive():
		return
	_clear_pending_zone_command()
	_release_everything()
	state = State.IN_HIVE_TO_EXIT

## `meadow_point` is global/meadow-space (meadow_root sits at the origin,
## so global and local-to-meadow coincide -- see the note on
## command_move_to for why that distinction matters elsewhere).
func set_forage_start_point(meadow_point: Vector2, source: String = "manual") -> Vector2:
	var resolved := BeeMovement.resolve_flight_start(self, meadow_point)
	forage_start_point = resolved.point
	local_search_anchor = resolved.point
	known_patches.clear()
	DiagnosticLog.log_flight_start_resolved(self, source, meadow_point, resolved)
	return resolved.point

func has_forage_start_point() -> bool:
	return forage_start_point.x != INF

func set_preferred_species(species: String) -> void:
	preferred_species = species
	flower_cooldowns.clear()   # a change of preference is worth a fresh look
	# A manual choice always wins over the automatic one still in
	# progress -- without this, scouting would silently overwrite it
	# the moment the bee's three bouts finished.
	is_scouting = false

## `hex` is an axial coordinate relative to the comb centre, matching
## what hive.gd already uses for cells and soil blocks.
##
## Replaces whatever was queued. Ctrl-clicking uses queue_build_target
## instead, which adds to the end.
func set_manual_build_target(hex: Vector2i) -> void:
	build_queue = [hex]
	manual_build_hex = hex
	has_manual_build_target = true

## Adds a tile to the end of this comb worker's build order. The queue is
## worked front to back, so the order you click is the order the comb
## gets drawn -- which matters when you're extending towards something.
func queue_build_target(hex: Vector2i) -> void:
	if build_queue.has(hex):
		return
	build_queue.append(hex)
	manual_build_hex = build_queue[0]
	has_manual_build_target = true

func clear_build_queue() -> void:
	build_queue.clear()
	has_manual_build_target = false

## Takes the next tile off the front of the queue, or returns false when
## there is nothing queued.
func _take_next_build_target() -> bool:
	while not build_queue.is_empty():
		var hex: Vector2i = build_queue.pop_front()
		if hive != null and hive.can_build_on(hex):
			manual_build_hex = hex
			has_manual_build_target = true
			return true
		# tile has been filled or dug away since it was queued -- skip it
		# rather than stalling the whole order on one stale entry
	has_manual_build_target = false
	return false

## Same idea for miners: an ordered list of blocks this bee will dig.
func set_mine_target(block: Node2D) -> void:
	mine_queue = [block] if is_instance_valid(block) else []
	if is_instance_valid(block):
		block.set_marked(true)
	if hive != null:
		hive.invalidate_mining_work()

func queue_mine_target(block: Node2D) -> void:
	if not is_instance_valid(block) or mine_queue.has(block):
		return
	mine_queue.append(block)
	block.set_marked(true)
	if hive != null:
		hive.invalidate_mining_work()

func clear_mine_queue() -> void:
	mine_queue.clear()
	if hive != null:
		hive.invalidate_mining_work()

## The next block this miner should dig from its own order, skipping any
## that have been dug out or unmarked since.
func _next_queued_block() -> Node2D:
	while not mine_queue.is_empty():
		var block = mine_queue[0]
		if is_instance_valid(block) and block.marked_for_mining:
			return block
		mine_queue.pop_front()
	return null

func set_home_hex(hex: Vector2i) -> void:
	home_hex = hex
	has_home_hex = true

## A miner's own centre of operations. It picks the soil nearest to this
## rather than nearest to itself, so a seam gets worked through from one
## end instead of the miner drifting to whatever happens to be closest
## after each block. Two miners with different home cells open the hive
## up in two places at once.
func set_mine_home_hex(hex: Vector2i) -> void:
	mine_home_hex = hex
	has_mine_home = true

## Where the miner should judge distance from: its home cell if it has
## one, otherwise wherever it is standing.
func _mine_reference_point() -> Vector2:
	if has_mine_home and hive != null:
		return hive.comb_centre + Shapes.hex_to_pixel(mine_home_hex.x, mine_home_hex.y, GameConfig.hive_cell_spacing, Session.use_sprite_hex_grid)
	return position

## Sent to a specific flower by right-click: ignore the cooldown list
## for this one trip and go straight there.
## Right-clicking a flower with a bee selected always sends it to collect
## from that flower -- switching it to Forager first if it wasn't
## already one (unless role_change_locked -- Challenge 1's manual-forage
## arc, where the trip must not permanently promote the queen), the same
## direct-command spirit as command_exit_hive.
## Doesn't change resource_type: she gathers whichever resource she's
## already set to (nectar by default -- see Bee.setup), not whatever the
## flower happens to be offering.
func command_collect_from(flower: Node2D) -> void:
	_clear_pending_zone_command()
	if flower.occupied_by != null and flower.occupied_by != self:
		return
	if role != Role.FORAGER and not role_change_locked:
		set_role(Role.FORAGER)
	if current_flower and current_flower != flower:
		current_flower.release(self)
	flower_cooldowns.erase(flower)
	predator_flower_cooldowns.erase(flower)
	flower.occupied_by = self
	current_flower = flower
	state = State.TO_FLOWER

## A flower belongs to meadow coordinates, so do not call
## command_collect_from until an indoor bee has left the hive.
func command_collect_from_after_exit(flower: Node2D) -> void:
	_clear_pending_zone_command()
	pending_collect_flower = flower
	_release_everything()
	state = State.IN_HIVE_TO_EXIT

## Sends a bee straight home to deposit whatever she's carrying, without
## waiting for a role's own trip-end logic to notice. Outside, this is
## the same State.TO_HIVE a full stomach already triggers on its own in
## BeeForaging.collect(); inside, it jumps straight to the same
## go_to_deposit_cell dispatch a returning forager already runs every
## time. General, not Challenge-1-only, the same direct-command spirit
## as command_exit_hive and command_collect_from above.
func command_return_and_deposit() -> void:
	_clear_pending_zone_command()
	_release_everything()
	if _is_inside_hive():
		state = State.IN_HIVE_TO_CELL if current_load > 0.0 else State.IN_HIVE_TO_EXIT
	else:
		state = State.TO_HIVE

## Returns an outdoor bee to the hive without selecting a receiving cell.
## Challenge 1 uses this during its manual deposit lesson only.
func command_return_only() -> void:
	_clear_pending_zone_command()
	_release_everything()
	state = State.TO_HIVE

## Deposits the carried load into the cell the player selected.
func command_deposit_at(cell: Node2D) -> void:
	_clear_pending_zone_command()
	target_cell = cell
	state = State.IN_HIVE_TO_CELL

## Sends this bee to carry `cell`'s contents out, using the same haul-out
## machinery a comb worker's autonomous maintenance already runs
## (BeeBuilding.builder_go_to_haul_source/_target, dispatched purely by
## state -- neither checks role) -- but commanded directly, so it works for
## any bee, including the queen, whom Challenge 1 forbids ever taking
## Role.BUILDER (durable rule, plans/archive/CHALLENGE1_2026-09-15.md). Her own role is
## left untouched; she returns to her own role's idle dispatch the moment
## the cell is empty. Slice 18.
func command_empty_cell(cell: Node2D) -> void:
	if not is_instance_valid(cell) or cell.content_type == "" or cell.content_type == "brood" or cell.content_type == "corpse":
		return
	_clear_pending_zone_command()
	cell.evict_requested = true
	cell.bump_display_epoch()
	_release_everything()
	target_cell = cell
	state = State.TO_HAUL_SOURCE   # player-command

## A hive cell belongs to hive coordinates, so delay assigning it until an
## outdoor bee has walked in through the entrance.
func command_deposit_at_after_enter(cell: Node2D) -> void:
	_clear_pending_zone_command()
	pending_deposit_cell = cell
	_release_everything()
	state = State.TO_HIVE

## Called immediately after the entrance reparenting at either side. Returns
## true when there was a player command to resume instead of normal idle work.
func resume_pending_zone_command() -> bool:
	if pending_deposit_cell != null and is_instance_valid(pending_deposit_cell):
		var cell := pending_deposit_cell
		_clear_pending_zone_command()
		command_deposit_at(cell)
		return true
	if pending_collect_flower != null and is_instance_valid(pending_collect_flower):
		var flower := pending_collect_flower
		_clear_pending_zone_command()
		command_collect_from(flower)
		return true
	if pending_move_target.x != INF:
		var target := pending_move_target
		_clear_pending_zone_command()
		command_move_to(target)
		return true
	_clear_pending_zone_command()
	return false

func _clear_pending_zone_command() -> void:
	pending_move_target = Vector2(INF, INF)
	pending_collect_flower = null
	pending_deposit_cell = null

func set_focus(type: String) -> void:
	if type == resource_type:
		return
	# A bee working Forager as its secondary/backup role (working_secondary,
	# role itself unchanged -- see current_working_role) must still be able
	# to switch nectar/pollen: it is genuinely doing Forager's job, just
	# without a primary-role change to show for it.
	if role != Role.FORAGER and not (working_secondary and secondary_role == Role.FORAGER):
		return
	resource_type = type
	flower_cooldowns.clear()
	# Challenge 1's pollen stage has no cell for nectar, so a load of it
	# still aboard when her focus moves to pollen is thrown away here, with
	# the same warning as at a full comb, rather than silently overwritten
	# by her first pollen visit (C-42, 17 Sep 2026).
	if current_load > 0.0 and current_load_type != type and is_instance_valid(world) 			and world.challenge_runner != null and world.challenge_runner.discards_overflow(self):
		world.challenge_runner.announce_overflow_discard(true)
		current_load = 0.0
		current_load_type = ""
	if current_flower:
		current_flower.release(self)
		current_flower = null

	# A bee mid-errand inside the hive (carrying to a cell, depositing,
	# walking out) is still physically parented under hive_root. Forcing
	# it into SEEK_FLOWER here would send it hunting for a flower whose
	# position is in meadow coordinates while the bee itself is reading
	# that as a local-to-hive offset -- it ends up drifting to a fixed,
	# meaningless spot in the hive. Instead, let it finish walking out
	# normally; _go_to_exit already calls _default_state_for_role() once
	# it's back in the meadow, which will pick up the new resource type.
	if not _is_inside_hive():
		# Already out foraging -- no need to fly home first.
		state = State.SEEK_FLOWER
	elif state == State.IDLING or (state == State.IN_HIVE_TO_CELL and not _has_deliverable_target()):
		# A bee parked on IDLING (Stage 1.11's freeze_bee) never dispatches
		# itself again on its own, so a focus change here would otherwise
		# be silently ignored. The same is true of a bee genuinely stuck in
		# IN_HIVE_TO_CELL with no target_cell -- go_to_deposit_cell's own
		# retry loop (bee_foraging.gd) only re-searches when the comb
		# actually changes, so she would otherwise wait out a focus change
		# too, still holding the old resource. A bee with a real target_cell
		# is mid-delivery and is left alone to finish it. Walk her out
		# through the ordinary exit path; _go_to_exit() calls
		# _default_state_for_role() on arrival, which picks up the new
		# resource type.
		state = State.IN_HIVE_TO_EXIT
	_update_label()
	_update_role_marker()

## `new_role` of -1 clears it. A bee can't take itself as its own
## backup, and only Miner, Nursery and Builder ever actually check
## theirs (see _idle_dispatch) -- the hud only offers the control for
## bees currently doing one of those.
## Whether this bee's deposit target can still take what she carries. A
## target that filled up or was re-designated counts as none: she is
## waiting, not mid-delivery (C-7, 17 Sep 2026).
func _has_deliverable_target() -> bool:
	return (
		target_cell != null and is_instance_valid(target_cell)
		and target_cell.space_for(current_load_type) > 0.0
	)

func set_secondary_role(new_role: int) -> void:
	secondary_role = -1 if new_role == role else new_role

func can_take_role(new_role: int) -> bool:
	return is_queen if new_role == Role.EGG_LAYER else true

## Changing a bee's job used to reparent it between the meadow and the
## hive on the spot. That teleported it: assign the queen to forage and
## she vanished from the hive floor and reappeared at the meadow marker,
## or the reverse. She now travels there like any other bee -- if she's
## outside she flies home and walks in through the entrance; if she's
## inside she walks out through it. The role changes immediately; only
## the journey takes time.
func set_role(new_role: int) -> void:
	if new_role == role or not can_take_role(new_role):
		return

	# With "finish current task" ticked, the change is queued rather than
	# applied: the bee sees the job through -- a forager delivers the
	# load it is carrying, a comb worker finishes the cell it is on -- and
	# picks the new role up the moment it is next free. Unticked, it
	# drops everything immediately, which is the old behaviour.
	if finish_task_first and _is_busy():
		pending_role = new_role
		return

	pending_role = -1
	_apply_role(new_role)

## Applied straight away, with no regard for what the bee was doing.
func _apply_role(new_role: int) -> void:
	_release_everything()
	working_secondary = false

	role = new_role
	# The one place `role` actually changes, so it's the one place to tell
	# main.gd's cached _role_counts() it's stale -- callers like
	# orders_zones.gd already refresh the HUD readout separately, but a
	# "finish current task first" bee applies its queued role change here
	# (see _apply_pending_role) without going through any of them.
	if world != null and is_instance_valid(world):
		world.invalidate_population()
	visible = true
	# brood food a nurse was carrying isn't any use in another job
	nurse_pollen = 0.0
	nurse_carb = 0.0
	nurse_carb_type = ""
	nurse_fetching = ""
	nurse_jelly = 0.0
	var now_indoors := BeeStatus.works_indoors(self)

	if is_queen and new_role == Role.EGG_LAYER and secondary_role == -1:
		# A run may name the backup a Laying queen takes by default; see
		# levels.gd's "queen_laying_backup". The player can still change it.
		var backup_key: String = str(Levels.get_level(Session.starting_level).get("queen_laying_backup", ""))
		if backup_key != "":
			set_secondary_role(Roles.id_for_key(backup_key))

	if _is_inside_hive():
		# already in the hive: either start the new indoor job here, or
		# walk out through the entrance the normal way. An Idle bee stays
		# where she is, as its tip promises -- walked out, she could never
		# eat again (BeeSurvival feeds only bees inside the hive)
		state = _default_state_for_role() if (now_indoors or new_role == Role.IDLE) else State.IN_HIVE_TO_EXIT
	else:
		# out in the meadow: fly to the hive and walk in, or just get on
		# with the new outdoor job from where it stands
		state = State.TO_HIVE if now_indoors else _default_state_for_role()

	_update_label()
	_update_role_marker()

func _release_everything() -> void:
	if current_flower:
		current_flower.release(self)
		current_flower = null
	if target_cell and is_instance_valid(target_cell):
		target_cell.release_builder(self)
	if target_block and is_instance_valid(target_block):
		target_block.release_miner(self)
	BeeForaging.release_cell_slot(self)
	target_cell = null
	target_block = null
	haul_target = null
	fan_target = null
	if hive:
		hive.remove_entrance_mentor(self)

## Called by a flower that's about to wither with this bee on it.
func release_flower_reference(flower: Node2D) -> void:
	if current_flower == flower:
		current_flower = null
		if state == State.TO_FLOWER or state == State.INSPECTING or state == State.COLLECTING:
			state = State.TO_HIVE if flower_switch_locked else State.SEEK_FLOWER

func set_selected(value: bool) -> void:
	selected = value
	selection_ring.visible = value

# --- display ------------------------------------------------------

func role_letter() -> String:
	# Foragers are the one role whose letter depends on what it's doing,
	# since which resource a bee is on is the thing you most want to read
	# off a crowd of them at a glance.
	if role == Role.FORAGER:
		return "N" if resource_type == "nectar" else "P"
	return Roles.letter_for(role)

## The states a Challenge has actually taught by the time a bee can be
## standing in them. Challenge 1 covers foraging, the queen's own laying
## chain, eating, tending brood and building a cell, and deliberately
## never reaches scouting bouts, entrance mentoring, dancing, royal
## jelly, mining spoil or honey fanning -- so the selection panel must
## not name those while a Challenge is running (Slice 13).
const CHALLENGE_TAUGHT_STATES := [
	State.SEEK_FLOWER, State.TO_FLOWER, State.COLLECTING, State.TO_HIVE,
	State.IN_HIVE_TO_CELL, State.DEPOSITING, State.IN_HIVE_TO_EXIT,
	State.MOVE_TO_POINT, State.IDLING,
	State.NURSE_IDLE, State.TO_BROOD, State.TENDING,
	State.TO_FEED_CELL, State.FEEDING,
	State.TO_BUILD_SITE, State.BUILDING,
	State.SEEK_POLLEN, State.TO_POLLEN_CELL, State.EATING,
	State.TO_CELL_TO_LAY, State.LAYING,
]

## True while a Challenge is running, which is when the selection panel's
## vocabulary has to stay inside what the player has been shown. Same
## is_instance_valid(world) guard bee_foraging.gd's _c1_queen_collections
## line uses -- world is null on a bee built before main.gd hands it over.
func challenge_vocabulary_limited() -> bool:
	return is_instance_valid(world) and world.challenge_runner != null and world.challenge_runner.active

## Why isn't this bee doing anything?
##
## "Nothing is happening and I can't tell why" is the worst state to
## leave a player in, and it is easy to reach: a nurse with no brood, a
## miner with nothing marked and automine off, a comb worker with
## nowhere left to build all look identical from outside -- a bee
## standing still.
##
## Each role knows what it was looking for, so each can say what it
## didn't find. Returns "" when the bee is genuinely busy.
func idle_reason() -> String:
	if hive == null:
		return ""
	if challenge_vocabulary_limited() and not (state in CHALLENGE_TAUGHT_STATES):
		return ""
	match state:
		State.NURSE_IDLE:
			if role == Role.EGG_LAYER:
				if hive.find_cell_with("pollen") == null:
					return "No pollen in the comb — she can't eat, so she can't lay."
				if not hive.has_room_for_egg():
					return "Nowhere to lay. Every nursery cell is occupied and there is no spare comb — reserve more cells for eggs, or build some."
				return ""
			if hive.cells_holding("brood").is_empty():
				return "No brood to look after. Nothing has been laid, or it has all emerged."
			return ""
		State.BUILD_IDLE:
			if architect_mode == "restock":
				if not BeeBuilding.has_restock_orders(self):
					return "No restocking orders. Select some comb and choose a resource to keep it full of."
				return "Nowhere to draw from. Every cell holding %s is either sealed, blocked, or one of the cells being filled." % restock_resource
			if architect_mode == "maintain":
				return "Nothing to clear. No dead larvae and no cells waiting to be emptied."
			if hive.create_next_cell_site(home_hex if has_home_hex else Vector2i.ZERO) == null:
				return "Nowhere left to build. The open floor is full — put miners on the soil to make more room, or clear a keep-clear tile."
			return ""
		State.MINE_IDLE:
			if not mine_queue.is_empty():
				return "The blocks you marked are still buried. They will be dug once the soil in front of them is gone."
			if automine:
				return "No soil left within reach. Everything diggable has been dug, or what's left is behind bedrock."
			return "Nothing marked to dig, and this miner isn't digging on its own. Use Mine to give it a block, or turn on \"Dig on its own\"."
		State.HONEY_IDLE:
			if hive.find_cell_with("nectar") == null:
				return "No nectar to work with. Honey is made from stored nectar, so the foragers have to bring some in first."
			if hive.find_honey_target() == null:
				return "Nowhere to put the mix. Every cell is full or reserved for something else — free one up, or build more comb."
			return ""
		State.SEEK_FLOWER:
			if BeeStatus.grounded(self):
				if Session.winter_here:
					return "Winter. Nothing is out, so the foragers are staying in."
				return "Raining too hard to fly. They'll go out when it eases."
			if BeeForaging.nearest_flower(self, false, GameConfig.forage_search_radius) == null:
				return "Nothing worth visiting. Every flower nearby is empty, out of season, or already taken."
			return ""
		State.IDLING:
			return "Set to idle. It will stay put until you give it a job."
	return ""

## A plain-language description of what this bee is doing right now,
## shown in the selection panel. Deliberately concrete ("returning
## pollen to the hive") rather than naming internal states.
func task_description() -> String:
	if challenge_vocabulary_limited() and not (state in CHALLENGE_TAUGHT_STATES):
		return "busy in the hive"
	match state:
		State.SEEK_FLOWER:
			return "looking for a %s flower" % resource_type
		State.SEARCHING:
			return "flying a search loop, looking for a %s flower" % resource_type
		State.TO_FLOWER:
			return "flying to a flower for %s" % resource_type
		State.INSPECTING:
			return "inspecting a flower before deciding whether to feed"
		State.COLLECTING:
			if timer > 0.0:
				return "landing on a flower"
			return "collecting %s (%d carried)" % [resource_type, int(current_load)]
		State.TO_HIVE:
			return "returning %s to the hive (%d carried)" % [current_load_type, int(current_load)]
		State.IN_HIVE_TO_CELL:
			if target_cell == null or not is_instance_valid(target_cell):
				if hive.cells.is_empty():
					return "waiting with %s until the first cell is built" % current_load_type
				return "waiting with %s: no cell has room for it" % current_load_type
			return "carrying %s to a cell" % current_load_type
		State.DEPOSITING:
			return "unloading %s into a cell" % current_load_type
		State.IN_HIVE_TO_EXIT:
			return "heading back out of the hive"
		State.MOVE_TO_POINT:
			return "moving where you sent it"
		State.IDLING:
			return "idle -- waiting for orders"
		State.MINE_IDLE:
			var base_mine := "looking for a block to dig" if automine else "waiting for a block to be marked"
			return base_mine + _idle_backup_note()
		State.TO_MINE_SITE:
			return "walking to a marked soil block"
		State.MINING:
			var dug := 0
			if target_block and is_instance_valid(target_block):
				dug = int(target_block.mine_fraction() * 100.0)
			return "digging out soil (%d%%, carrying %d/%d dirt)" % [dug, int(dirt_load), int(GameConfig.miner_dirt_capacity)]
		State.TO_MINE_EXIT:
			return "carrying spoil out to dump it"
		State.DUMPING_DIRT:
			return "emptying out a load of dirt"
		State.NURSE_IDLE:
			return "looking for brood work" + _idle_backup_note()
		State.TO_BROOD:
			return "going to tend the brood"
		State.TENDING:
			if target_cell and is_instance_valid(target_cell) and target_cell.content_type == "brood":
				if target_cell.brood_fed_seconds > 0.0:
					return "feeding a larva (%ds of development left in it)" % int(target_cell.brood_fed_seconds)
				return "tending a larva -- no pollen in the comb to feed it"
			return "tending a developing bee"
		State.DRINKING:
			return "drinking nectar from the flower to refuel (energy %d%%)" % int(100.0 * energy / max(0.001, GameConfig.energy_capacity))
		State.SHELTERING:
			return "sheltering at the hive -- too wet to forage"
		State.AT_ENTRANCE_SEEKING:
			if is_scouting:
				return "scouting: bout %d of 3, waiting at the entrance for a tip (%ds)" % [scout_bout + 1, int(max(0.0, timer))]
			return "waiting at the entrance, hoping to be told a better patch (%ds)" % int(max(0.0, timer))
		State.AT_ENTRANCE_MENTORING:
			return "waiting at the entrance, willing to recruit a struggling forager (%ds)" % int(max(0.0, timer))
		State.DANCING:
			if dance_role == "mentor":
				return "dancing to show a struggling forager a better patch (%ds)" % int(max(0.0, timer))
			return "being shown a better patch by a forager nearby (%ds)" % int(max(0.0, timer))
		State.MAKING_JELLY:
			return "working pollen and honey into royal jelly (%ds)" % int(max(0.0, timer))
		State.TO_JELLY_CELL:
			return "carrying royal jelly to a cell"
		State.DEPOSITING_JELLY:
			return "storing royal jelly"
		State.TO_FOOD_CELL:
			return "going to collect %s for the brood" % nurse_fetching
		State.LOADING_FOOD:
			return "loading up with %s to feed the brood" % nurse_fetching
		State.TO_FEED_CELL:
			return "hungry -- heading to a cell to eat"
		State.FEEDING:
			var eating := "nectar"
			if target_cell and is_instance_valid(target_cell):
				eating = target_cell.content_type
			return "eating %s (energy %d%%)" % [
				eating, int(100.0 * energy / max(0.001, GameConfig.energy_capacity)),
			]
		State.HONEY_IDLE:
			return "looking for nectar to turn into honey" + _idle_backup_note()
		State.TO_NECTAR_CELL:
			return "going to a nectar cell to fill up"
		State.CHEWING:
			return "chewing enzymes into nectar (%ds left)" % int(max(0.0, timer))
		State.TO_HONEY_CELL:
			return "carrying the honey mix to a cell"
		State.DEPOSITING_HONEY:
			return "spitting the mix into a honey cell"
		State.FANNING:
			var dried := 0
			if fan_target and is_instance_valid(fan_target):
				dried = int(fan_target.ripen_fraction() * 100.0)
			return "fanning a honey cell dry (%d%%)" % dried
		State.BUILD_IDLE:
			return "looking for building work" + _idle_backup_note()
		State.TO_BUILD_SITE:
			return "walking to a cell under construction"
		State.BUILDING:
			var pct := 0
			if target_cell and is_instance_valid(target_cell):
				pct = int(target_cell.build_fraction() * 100.0)
			return "building a new cell (%d%%)" % pct
		State.TO_RESTOCK_SOURCE:
			return "fetching %s to top up a cell it keeps full" % restock_resource
		State.TO_RESTOCK_TARGET:
			return "carrying %s to a cell it keeps full" % current_load_type
		State.TO_HAUL_SOURCE:
			return "going to clear a reassigned cell"
		State.TO_HAUL_TARGET:
			return "moving %s to another cell" % current_load_type
		State.TO_CLEAN_CELL:
			return "going to clear a dead larva out of a cell"
		State.CLEANING:
			var cleaned := 0
			if target_cell and is_instance_valid(target_cell):
				cleaned = int(target_cell.clean_fraction() * 100.0)
			return "clearing a dead larva out of a cell (%d%%)" % cleaned
		State.TO_WASTE_EXIT:
			if carrying_corpse:
				return "carrying a dead larva out of the hive"
			return "carrying %s out of the hive to dump it" % current_load_type
		State.DUMPING_WASTE:
			return "disposing of a dead larva" if carrying_corpse else "throwing out unwanted stores"
		State.SEEK_POLLEN:
			if not hive.has_room_for_egg():
				return "waiting -- no free cell to lay in"
			return "looking for pollen to eat"
		State.TO_POLLEN_CELL:
			return "walking to a pollen cell"
		State.EATING:
			return "feeding on pollen (%d of %d for an egg)" % [int(pollen_eaten), int(GameConfig.egg_pollen_cost)]
		State.TO_CELL_TO_LAY:
			return "carrying an egg to a free cell"
		State.LAYING:
			return "laying an egg into a cell"
	return "idle"

## Only ever reached from task_description() while sitting in an idle
## state, which means _idle_dispatch already tried the secondary role
## this frame too and it also came up empty.
func _idle_backup_note() -> String:
	# role_restricted_to is exactly the signal that a Challenge is limiting
	# which roles this bee may hold, so a backup role has not been
	# introduced yet and naming one would teach it out of order.
	if not role_restricted_to.is_empty():
		return ""
	if secondary_role != -1 and secondary_role != role:
		return " (backup role %s also has nothing right now)" % Roles.label_for(secondary_role)
	return ""

func role_name_text() -> String:
	var base: String = Roles.label_for(role)
	match role:
		Role.NURSERY:
			base += " (%s)" % Roles.mode_label(Roles.NURSE, nurse_mode).to_lower()
		Role.BUILDER:
			base += " (%s)" % architect_mode_name()
		Role.MINER:
			if automine:
				base += " (digging on its own)"
		Role.FORAGER:
			base += " (%s)" % resource_type
			if is_scouting:
				base += " -- scouting (%d/3)" % (scout_bout + 1)
			elif preferred_species != "":
				base += " -- %s only" % preferred_species
			if state == State.AT_ENTRANCE_SEEKING:
				base += " -- waiting to be told a better patch"
			elif state == State.AT_ENTRANCE_MENTORING:
				base += " -- waiting to recruit a struggling forager"
			elif state == State.DANCING:
				base += " -- dancing to recruit a struggling forager" if dance_role == "mentor" else " -- being danced at"
	if secondary_role != -1 and secondary_role != role:
		base += " -- when idle: %s" % Roles.label_for(secondary_role)
	return base

func architect_mode_name() -> String:
	var mode_text: String = Roles.mode_label(Roles.COMB_WORKER, architect_mode).to_lower()
	if architect_mode == "restock":
		mode_text += " %s" % (restock_resource if restock_resource != "" else "-- nothing set")
	return mode_text

func carrying_text() -> String:
	if carrying_corpse:
		return "Carrying: a dead larva, for disposal outside"
	if role == Role.MINER:
		return "Carrying: %d dirt (of %d)" % [int(dirt_load), int(GameConfig.miner_dirt_capacity)]
	if honey_load > 0.0:
		return "Carrying: %d units of honey mix" % int(ceil(honey_load))
	if nurse_pollen > 0.0 or nurse_carb > 0.0 or nurse_jelly > 0.0:
		var carb_name: String = nurse_carb_type if nurse_carb_type != "" else "nectar"
		var carried := "Carrying: %d pollen and %d %s for the brood (%d feeds)" % [
			int(nurse_pollen), int(nurse_carb), carb_name, int(BeeNursery.feeds_carried(self)),
		]
		if nurse_jelly > 0.0:
			carried += ", plus %d royal jelly" % int(nurse_jelly)
		return carried
	if current_load <= 0.0 or current_load_type == "":
		return "Carrying: nothing"
	return "Carrying: %d %s (of %d)" % [int(current_load), current_load_type, int(BeeForaging.max_capacity(self))]

## Age and remaining life now live in the selection panel rather than
## floating over every bee, which was a lot of numbers to read at once.
func age_days() -> float:
	return age_seconds / max(0.001, GameConfig.seconds_per_day)

## A gyne mature enough and fed enough to go. She simply leaves: the
## colony has already spent everything it will spend on her, and what it
## gets back is a number on the scoreboard rather than a bee.
##
## Not a death -- no marker, no corpse. She flew off and it worked.
func leave_to_found_colony() -> void:
	if is_dying:
		return
	is_dying = true
	if current_flower:
		current_flower.release(self)
	if target_cell and is_instance_valid(target_cell):
		target_cell.release_builder(self)
	if target_block and is_instance_valid(target_block):
		target_block.release_miner(self)
	BeeForaging.release_cell_slot(self)
	queue_free()

func days_remaining() -> float:
	return max(0.0, BeeSurvival.lifespan_seconds(self) / max(1.0, GameConfig.seconds_per_day) - age_days())

## Skipped entirely for bees the camera can't see. Setting a label's text
## and a polygon's colour are each cheap; doing both for every bee every
## frame when most of them are off screen is not, and nobody can tell.
## Below this share of full energy a bee's body starts to visibly darken.
## Above it, energy fluctuating in the normal range (feeding, flying,
## draining slowly between meals) doesn't change how a bee looks at all --
## darkening is a warning sign, not a readout of every point of energy.
const ENERGY_DARKEN_THRESHOLD := 0.4

func _update_label() -> void:
	if world != null and is_instance_valid(world) and not world.is_on_screen(self):
		return
	var prefix := "Q" if is_queen else str(bee_id)
	label.text = "%s%s" % [prefix, role_letter()]
	# Only foragers currently offer a toggle for this (see
	# Session.show_forager_labels) -- every other role's label stays as
	# it was.
	label.visible = Session.show_forager_labels if role == Role.FORAGER else true
	# body dims as energy runs low, so a starving bee is visible at a glance.
	# Nothing happens above ENERGY_DARKEN_THRESHOLD; below it, darkening
	# ramps up to full at zero energy, same as it always did once it starts.
	var energy_fraction: float = clamp(energy / max(0.001, GameConfig.energy_capacity), 0.0, 1.0)
	var darken_amount: float = 0.0
	if energy_fraction < ENERGY_DARKEN_THRESHOLD:
		darken_amount = (ENERGY_DARKEN_THRESHOLD - energy_fraction) / ENERGY_DARKEN_THRESHOLD
	body.color = _base_colour().lerp(Color(0.45, 0.35, 0.3), darken_amount)

## Same off-screen skip as _update_label -- purely presentational (rule
## 3), and cheap enough not to need its own throttle.
func _update_alarm_ring() -> void:
	if world != null and is_instance_valid(world) and not world.is_on_screen(self):
		return
	alarm_ring.visible = Session.sim_time < alarm_flash_until
	attack_ring.visible = Session.sim_time < attack_flash_until

## Foragers only, outdoors only -- heading only ever influences a
## forager's own flower choice, and showing it indoors/for other roles
## would just be visual noise pointing at whatever direction she last
## happened to move. Same off-screen skip as _update_label/_update_alarm_ring
## (rule 3).
func _update_heading_marker() -> void:
	if heading_marker == null:
		return
	if world != null and is_instance_valid(world) and not world.is_on_screen(self):
		return
	var should_show: bool = role == Role.FORAGER and not _is_inside_hive()
	heading_marker.visible = should_show
	if should_show and heading != Vector2.ZERO:
		heading_marker.rotation = heading.angle()

## Pulses (scale, not just a static ring) so a searching bee catches the
## eye in a crowd rather than being one more small circle to spot. Same
## off-screen skip as the other presentation-only updates (rule 3).
const SEARCH_RING_PULSE_HZ := 1.6
func _update_search_ring() -> void:
	if search_ring == null:
		return
	if world != null and is_instance_valid(world) and not world.is_on_screen(self):
		return
	var searching: bool = state == State.SEARCHING
	search_ring.visible = searching
	if searching:
		var pulse: float = 0.5 + 0.5 * sin(Session.sim_time * TAU * SEARCH_RING_PULSE_HZ)
		search_ring.scale = Vector2.ONE * (1.0 + 0.2 * pulse)

## The mentor/seeker pair in a recruitment dance, ringed so they can be
## found in a crowd (foraging-evidence.md Slice 4). Opt-in, because it is
## a hunting aid rather than something every run wants on screen: off, the
## whole function is one boolean read and, at most, one hide. Two colours
## so the pair reads as a pair with a direction -- warm yellow for the
## mentor doing the recruiting, cool blue for the struggling forager she
## is dancing at. Same pulse idea and off-screen skip as
## _update_search_ring; presentation only (rule 3), so it never gates the
## dance itself.
const DANCE_RING_PULSE_HZ := 2.4
const DANCE_RING_MENTOR_COLOUR := Color(1.0, 0.85, 0.15, 0.85)
const DANCE_RING_SEEKER_COLOUR := Color(0.2, 0.7, 1.0, 0.85)
func _update_dance_ring() -> void:
	if dance_ring == null:
		return
	if not Session.show_recruitment_highlight:
		if dance_ring.visible:
			dance_ring.visible = false
		return
	if world != null and is_instance_valid(world) and not world.is_on_screen(self):
		return
	var dancing: bool = state == State.DANCING
	dance_ring.visible = dancing
	if dancing:
		dance_ring.color = DANCE_RING_MENTOR_COLOUR if dance_role == "mentor" else DANCE_RING_SEEKER_COLOUR
		var pulse: float = 0.5 + 0.5 * sin(Session.sim_time * TAU * DANCE_RING_PULSE_HZ)
		dance_ring.scale = Vector2.ONE * (1.0 + 0.2 * pulse)

## Bumble flight (see ROADMAP.md): a small Lissajous drift on visual_root
## while the bee is actually flying outdoors, so movement reads as
## bee-like instead of beelining. bee.position itself never moves for
## this, so arrival checks, obstacle steering and the stall watchdog are
## all unaffected -- only where the bee is *drawn* wobbles.
##
## Two sines at different rates (rather than one) so the path traces a
## drifting loop instead of a straight line back and forth, which reads
## as idling in place rather than flight.
##
## The offset is eased towards its target -- the wander itself while
## flying, zero once it stops -- rather than set outright. Without this,
## a bee arriving at a flower had its visuals jump back onto the exact
## landing spot the instant flying_outdoors went false that frame, which
## read as a teleport/snap rather than a landing. Easing over
## GameConfig.bumble_flight_settle_seconds turns that into a smooth
## touchdown, and does the same (less noticeably) when a bee sets off.
func _update_wander_flight(delta: float) -> void:
	var target_offset := Vector2.ZERO
	if GameConfig.bumble_flight_on and flying_outdoors:
		# Off screen: skip the trig and the ease both, same pattern as
		# _update_label/_update_alarm_ring (rule 3) -- nothing to see.
		if world != null and is_instance_valid(world) and not world.is_on_screen(self):
			return
		var t: float = Session.sim_time * GameConfig.bumble_flight_frequency + wander_phase
		target_offset = Vector2(
			sin(t) * GameConfig.bumble_flight_amplitude,
			sin(t * 1.7 + PI * 0.5) * GameConfig.bumble_flight_amplitude
		)

	if visual_root.position.distance_squared_to(target_offset) < 0.01:
		if visual_root.position != target_offset:
			visual_root.position = target_offset
		return
	var blend: float = 1.0 - exp(-delta / max(0.001, GameConfig.bumble_flight_settle_seconds))
	visual_root.position = visual_root.position.lerp(target_offset, blend)

## Slice 9 (proximity recruitment): the mentor's drawn body orbits the
## seeker's real position while State.DANCING -- pure presentation (rule
## 3), same visual_root-offset technique as bumble flight above.
## bee.position itself never moves for this: the proximity check, the
## dance timer and the eventual info transfer (BeeForaging._complete_dance)
## all happen exactly the same whether or not either bee is ever drawn.
## Only the mentor's sprite moves; the seeker's own visual_root just eases
## back to zero (nothing here touches hers), so this reads as one bee
## visiting the other rather than both drifting.
const DANCE_ORBIT_RADIUS := 14.0
const DANCE_ORBIT_HZ := 0.8
func _update_dance_circle(delta: float) -> void:
	if state != State.DANCING or dance_role != "mentor" or dance_partner == null or not is_instance_valid(dance_partner):
		return
	if world != null and is_instance_valid(world) and not world.is_on_screen(self):
		return
	var t: float = Session.sim_time * TAU * DANCE_ORBIT_HZ
	var orbit := Vector2(cos(t), sin(t)) * DANCE_ORBIT_RADIUS
	var target_offset: Vector2 = (dance_partner.position - position) + orbit
	var blend: float = 1.0 - exp(-delta / max(0.001, GameConfig.bumble_flight_settle_seconds))
	visual_root.position = visual_root.position.lerp(target_offset, blend)

## Bees inside the hive pick their way over the comb rather than flying
## straight, so standing on a cell slows them down. Out in the meadow
## there's no terrain, so this is a no-op.
func _terrain_speed_factor() -> float:
	if not _is_inside_hive():
		return 1.0
	if hive == null or not hive.has_method("cell_at_tile"):
		return 1.0
	var local: Vector2 = position - hive.comb_centre
	var hex: Vector2i = Shapes.pixel_to_hex(local, GameConfig.hive_cell_spacing, Session.use_sprite_hex_grid)
	return GameConfig.cell_slow_factor if hive.cell_at_tile(hex) != null else 1.0

func _is_inside_hive() -> bool:
	return world != null and get_parent() == world.hive_root

# --- getting round things in the meadow ---------------------------
## Obstacle avoidance and steering moved to bee_movement.gd -- see
## BEE_SPLIT_PLAN.md. These three vars stay here (all vars stay on
## bee.gd) because bee_movement.gd's static functions read and write
## them directly as bee.skirt_obstacle etc.

## Which obstacle the bee is currently going round, and which way. Held
## until the bee is genuinely past it -- picking a side afresh each frame
## flips at the halfway angle and shuffles the bee on the spot.
var skirt_obstacle: Node2D = null
var skirt_turn: float = 1.0

## How many consecutive clear frames before the bee forgets what it was
## going round. See bee_movement.gd's SKIRT_FORGET_FRAMES for why one
## clear frame isn't enough.
var skirt_clear_frames: int = 0

## Kept as a one-line wrapper so world_building.gd's call to
## `b.clear_navigation_state()` didn't have to change -- same pattern as
## main.gd's wrappers after the main.gd split.
func clear_navigation_state() -> void:
	BeeMovement.clear_navigation_state(self)
