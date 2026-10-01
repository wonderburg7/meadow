extends RefCounted
## The one place a skill node is described.
##
## Usage: const Skills = preload("res://scripts/skills.gd")
##        Skills.cost_for(Skills.ORIENTATION_FLIGHT)
##
## Scope (progression.md section 3, Phase A step 1): catalogue data only,
## modelled on roles.gd's shape -- static const data plus lookup funcs.
## Nothing reads this file yet. The thin resolver (Phase A step 2) is the
## only thing that will ever answer ownership, afford and validity
## questions from it, and nothing anywhere writes GameConfig from a skill
## effect (section 3).
##
## What is deliberately empty here
## -------------------------------
## Every entry's `effects` is `[]`, except Tarsal secretions and
## Orientation flight (Phase A step 4): they transcribe the always-on
## GameConfig toggles they already are today
## (`tarsal_markers_on`/`orientation_flight_on`) as `enable_behaviour`
## effects, section 9.1's type for a plain owned/not-owned switch rather
## than a magnitude. Every other node's `effects` stays `[]` until its
## own content step reaches it -- a number nothing can balance is a
## guess, matching the rule this file already applies to cost amounts.
## `introduced_by` is likewise "" until the campaign meta tree exists,
## and `icon` is "" until the tree panel does.
##
## Cost amounts are unsimulated starting values
## --------------------------------------------
## What is fixed here is which *resources* a recipe names: section 4.2's
## ladder says a tier-N recipe must name at least one resource from tier
## N's row, which is what makes the Brood spine gate every other branch.
## The amounts are first guesses and will be replaced by a balance pass
## with the scenario harness behind it -- they are not tuned numbers.
##
## Baseline entries (section 5.7)
## ------------------------------
## Four capabilities are on from the start and are not purchasable. Their
## IDs are reserved here with `baseline: true` and `tier: 0` rather than
## left out, so promoting one to a real node later is a data change
## rather than a rewrite. They hold no grid position -- `axial` is
## Vector2i(0, 0) for all four, and grid validation skips them.

const Features = preload("res://scripts/features.gd")

# --- cost currencies ----------------------------------------------
## Cost keys, not resources.gd entries: nectar and pollen are harvested
## resources today, honey is produced, and bee bread and Pollinator
## Points do not exist yet. Naming them here is what lets the ladder be
## authored and validated before those resources are built.

const NECTAR := "nectar"
const POLLEN := "pollen"
const HONEY := "honey"
const BEE_BREAD := "bee_bread"
const ROYAL_JELLY := "royal_jelly"
const POLLINATOR_POINTS := "pollinator_points"

## Section 4.2. A recipe must name at least one of its own tier's
## REQUIRED row, and may name nothing outside its ALLOWED row.
const TIER_REQUIRED := {
	1: [NECTAR, POLLEN],
	2: [HONEY],
	3: [BEE_BREAD],
	4: [POLLINATOR_POINTS],
}

const TIER_ALLOWED := {
	1: [NECTAR, POLLEN],
	2: [HONEY, NECTAR, POLLEN],
	3: [BEE_BREAD, HONEY, NECTAR, POLLEN],
	# Royal jelly is no longer the universal tier-4 gate, but a specific
	# tier-4 recipe may still name it thematically -- Gyne rearing does.
	4: [POLLINATOR_POINTS, ROYAL_JELLY, BEE_BREAD, HONEY, NECTAR, POLLEN],
}

# --- sectors ------------------------------------------------------
## Order is not cosmetic: it is shapes.gd's axial direction order, so a
## sector's index *is* the direction its wedge points along (section
## 8.2). Every cross-sector prerequisite below sits between adjacent
## wedges, which is what keeps its connecting line short. Reordering this
## lengthens those lines.

const SECTORS := [
	{"key": "foraging", "label": "Foraging"},
	{"key": "defence", "label": "Defence"},
	{"key": "ecology", "label": "Ecology"},
	{"key": "hive_mind", "label": "Hive Mind"},
	{"key": "colony", "label": "Colony"},
	{"key": "brood", "label": "Brood"},
]

# --- skill ids ----------------------------------------------------
## Named constants so other files can reference a skill without repeating
## its string, the way roles.gd names its role ids.

const TARSAL_SECRETIONS := "skill.foraging.tarsal_secretions"
const ORIENTATION_FLIGHT := "skill.foraging.orientation_flight"
const ASSOCIATIVE_LEARNING := "skill.foraging.associative_learning"
const ADAPTIVE_CONSTANCY := "skill.foraging.adaptive_constancy"
const WEIGHTED_FLOWER_CHOICE := "skill.foraging.weighted_flower_choice"
const POLLINATOR_POINTS_SKILL := "skill.foraging.pollinator_points"
const NECTAR_ROBBING := "skill.foraging.nectar_robbing"
const AUTO_RECRUITMENT := "skill.foraging.auto_recruitment"
const AUTO_SCOUTING := "skill.foraging.auto_scouting"

const HONEY_WORKER := "skill.brood.honey_worker"
const NURSES := "skill.brood.nurses"
const BEE_BREAD_SKILL := "skill.brood.bee_bread"
const ROYAL_JELLY_SKILL := "skill.brood.royal_jelly"
const PRIORITY_CELLS := "skill.brood.priority_cells"
const GYNE_REARING := "skill.brood.gyne_rearing"
const DRONES := "skill.brood.drones"

const CELL_CAPACITY := "skill.colony.cell_capacity"
const COMB_WORKER := "skill.colony.comb_worker"
const MINER := "skill.colony.miner"
const RESTOCKING := "skill.colony.restocking"
const WORK_PRIORITIES := "skill.colony.work_priorities"

const THREAT_DETECTION := "skill.defence.threat_detection"
const ALARM_PHEROMONE := "skill.defence.alarm_pheromone"
const GUARD_BEE := "skill.defence.guard_bee"
const COMBAT := "skill.defence.combat"
const SUPPRESS_RECRUITMENT := "skill.defence.suppress_recruitment"
const MEDICINE := "skill.defence.medicine"
const AUTO_DEFENCE := "skill.defence.auto_defence"

const WEATHER_SENSING := "skill.ecology.weather_sensing"
const RAIN_RECALL := "skill.ecology.rain_recall"
const LANDSCAPE_MEMORY := "skill.ecology.landscape_memory"

const BACKUP_ROLES := "skill.hive_mind.backup_roles"
const AUTOMATION := "skill.hive_mind.automation"
const CLEANING := "skill.hive_mind.cleaning"
const ADJUSTMENT_PANEL := "skill.hive_mind.adjustment_panel"
const EXTENDED_BACKUP_ROLES := "skill.hive_mind.extended_backup_roles"
const CHEMICAL_CASCADE := "skill.hive_mind.chemical_cascade"
const STANDING_INSTRUCTIONS := "skill.hive_mind.standing_instructions"

# --- the catalogue ------------------------------------------------
## Fields, per section 3:
##   id           stable key; never a display string (section 0)
##   name         display text; never a save key and never a dependency
##   description  what the player is buying, in their words
##   sector       a SECTORS key
##   tier         1-4, or 0 for a baseline capability
##   axial        grid coordinate; ring == 2 * tier + 1 (section 8.1)
##   max_rank     1 everywhere in this pass (section 4.4)
##   cost         resource key -> amount, spent on purchase
##   requires_previous_tier
##                section 4.3's branch-tier rule; a run definition is the
##                only thing that may ever waive it
##   all_of       skill ids, every one of which must be owned
##   any_of       groups; at least one member of each group owned
##   feature      a features.gd id this skill cannot work without, or ""
##   introduced_by  the run that discovers it in the campaign tree
##   effects      typed effects; empty until the resolver exists
##   icon         tree-panel art; empty until the panel exists
##   status       design status, from section 5's key
##   baseline     true for section 5.7's always-on capabilities
##   open         true while section 5.9 has not defined what it does

const SKILLS := [
	# --- Foraging -------------------------------------------------
	{
		"id": TARSAL_SECRETIONS, "name": "Tarsal secretions",
		"description": "Bees notice each other's recent scent marks, so they spread out rather than crowding a flower somebody has just worked.",
		"sector": "foraging", "tier": 1, "axial": Vector2i(3, 0),
		"max_rank": 1, "cost": {NECTAR: 120, POLLEN: 40},
		"requires_previous_tier": true, "all_of": [], "any_of": [],
		"feature": "", "introduced_by": "",
		# Transcribes GameConfig.tarsal_markers_on -- section 11 Phase A
		# step 4. "enable_behaviour" and the key are section 9.1's fixed
		# vocabulary; progression.gd is where they get resolved.
		"effects": [{"type": "enable_behaviour", "key": "tarsal_markers_on"}],
		"icon": "",
		"status": "existing", "baseline": false, "open": false,
	},
	{
		"id": ORIENTATION_FLIGHT, "name": "Orientation flight",
		"description": "A new forager learns a working area of its own before it starts collecting, instead of heading straight for the nearest flower.",
		# (2, 1) sat on the connect line from Tarsal secretions to Alarm
		# pheromone (progression.md 8.3's grid check caught it); the other
		# free tier-1 slot in this wedge is clear of every line.
		"sector": "foraging", "tier": 1, "axial": Vector2i(3, -1),
		"max_rank": 1, "cost": {NECTAR: 140, POLLEN: 40},
		"requires_previous_tier": true, "all_of": [], "any_of": [],
		"feature": "", "introduced_by": "",
		# Transcribes GameConfig.orientation_flight_on -- section 11 Phase A
		# step 4. Same vocabulary as Tarsal secretions above.
		"effects": [{"type": "enable_behaviour", "key": "orientation_flight_on"}],
		"icon": "",
		"status": "existing", "baseline": false, "open": false,
	},
	{
		# Familiarity is per bee per *species*, not per flower, and has
		# to be saved (section 5.1). Rates need simulation before build.
		"id": ASSOCIATIVE_LEARNING, "name": "Associative learning",
		"description": "A bee gets quicker at a flower the more of that species it has worked, so a settled forager handles each one faster.",
		"sector": "foraging", "tier": 2, "axial": Vector2i(5, 0),
		"max_rank": 1, "cost": {HONEY: 20, NECTAR: 200, POLLEN: 80},
		"requires_previous_tier": true, "all_of": [], "any_of": [],
		"feature": "", "introduced_by": "", "effects": [], "icon": "",
		"status": "new", "baseline": false, "open": false,
	},
	{
		# The old floral_constancy_on, with the difference that a forager
		# re-evaluates rather than locking to one species for good.
		"id": ADAPTIVE_CONSTANCY, "name": "Adaptive constancy",
		"description": "A forager settles on one kind of flower, but drops it and looks again once that species stops paying.",
		"sector": "foraging", "tier": 2, "axial": Vector2i(4, 1),
		"max_rank": 1, "cost": {HONEY: 20, NECTAR: 180, POLLEN: 80},
		"requires_previous_tier": true, "all_of": [], "any_of": [],
		"feature": "", "introduced_by": "", "effects": [], "icon": "",
		"status": "existing_foundation", "baseline": false, "open": false,
	},
	{
		"id": WEIGHTED_FLOWER_CHOICE, "name": "Weighted flower choice",
		"description": "Foragers weigh what a flower is likely to yield against how long it takes and how far it is, instead of always taking the nearest.",
		"sector": "foraging", "tier": 3, "axial": Vector2i(7, 0),
		"max_rank": 1, "cost": {BEE_BREAD: 12, HONEY: 40, POLLEN: 120},
		"requires_previous_tier": true, "all_of": [ASSOCIATIVE_LEARNING], "any_of": [],
		"feature": "", "introduced_by": "", "effects": [], "icon": "",
		"status": "new", "baseline": false, "open": false,
	},
	{
		# Two ledgers, not one: spendable Points gate every tier-4
		# purchase, and Pollination Contribution is never spent.
		"id": POLLINATOR_POINTS_SKILL, "name": "Pollinator points",
		"description": "The colony starts being paid for the pollination it does -- in points that buy the hardest skills, and in a contribution the meadow itself remembers.",
		"sector": "foraging", "tier": 3, "axial": Vector2i(6, 1),
		"max_rank": 1, "cost": {BEE_BREAD: 14, HONEY: 40, NECTAR: 150},
		"requires_previous_tier": true, "all_of": [], "any_of": [],
		"feature": "", "introduced_by": "", "effects": [], "icon": "",
		"status": "new", "baseline": false, "open": false,
	},
	{
		# A pure speed-up with no downside would dominate: needs its own
		# balance pass, not a number picked here (section 5.1).
		"id": NECTAR_ROBBING, "name": "Nectar robbing",
		"description": "Bees pierce a flower at the base and take the nectar straight out, skipping the work of the flower entirely -- and pollinating nothing.",
		"sector": "foraging", "tier": 4, "axial": Vector2i(9, 0),
		"max_rank": 1, "cost": {POLLINATOR_POINTS: 25, BEE_BREAD: 30, HONEY: 80},
		"requires_previous_tier": true, "all_of": [WEIGHTED_FLOWER_CHOICE], "any_of": [],
		"feature": "", "introduced_by": "", "effects": [], "icon": "",
		"status": "new", "baseline": false, "open": false,
	},
	{
		"id": AUTO_RECRUITMENT, "name": "Auto-recruitment",
		"description": "A forager that has found something good tells the others at the entrance, so a productive area fills up on its own.",
		"sector": "foraging", "tier": 4, "axial": Vector2i(8, 1),
		"max_rank": 1, "cost": {POLLINATOR_POINTS: 25, BEE_BREAD: 30, NECTAR: 250},
		"requires_previous_tier": true, "all_of": [], "any_of": [],
		"feature": "", "introduced_by": "", "effects": [], "icon": "",
		"status": "existing", "baseline": false, "open": false,
	},

	# --- Brood ----------------------------------------------------
	# The tier spine (section 4.2). Honey worker gates every tier-2
	# purchase in every branch; Bee bread gates every tier-3 one.
	{
		"id": HONEY_WORKER, "name": "Honey worker",
		"description": "Unlocks the Honey role, and with it turning nectar into honey and storing it.",
		"sector": "brood", "tier": 1, "axial": Vector2i(3, -3),
		"max_rank": 1, "cost": {NECTAR: 150, POLLEN: 60},
		"requires_previous_tier": true, "all_of": [], "any_of": [],
		"feature": "", "introduced_by": "", "effects": [], "icon": "",
		"status": "existing", "baseline": false, "open": false,
	},
	{
		# One purchase, not several: the role, the feeding behaviour,
		# Feeding mode and its controls all arrive together (section 5.2).
		"id": NURSES, "name": "Nurses",
		"description": "Unlocks the Nurse role: bees that carry food to the larvae, without which nothing in the comb develops at all.",
		"sector": "brood", "tier": 1, "axial": Vector2i(2, -3),
		"max_rank": 1, "cost": {NECTAR: 120, POLLEN: 80},
		"requires_previous_tier": true, "all_of": [], "any_of": [],
		"feature": "", "introduced_by": "", "effects": [], "icon": "",
		"status": "existing", "baseline": false, "open": false,
	},
	{
		# The chain's shape is settled; the recipe, cell capacity and
		# larval ration are still open (section 5.9 item 3).
		"id": BEE_BREAD_SKILL, "name": "Bee bread",
		"description": "A honey worker seals pollen and honey into a cell and lets it ferment, making the richest thing a nurse can carry.",
		"sector": "brood", "tier": 2, "axial": Vector2i(5, -5),
		"max_rank": 1, "cost": {HONEY: 30, POLLEN: 150},
		"requires_previous_tier": true, "all_of": [], "any_of": [],
		"feature": "", "introduced_by": "", "effects": [], "icon": "",
		"status": "new", "baseline": false, "open": false,
	},
	{
		"id": ROYAL_JELLY_SKILL, "name": "Royal jelly",
		"description": "Unlocks Jelly mode: nurses work pollen and honey into the one food a gyne larva cannot be raised without.",
		"sector": "brood", "tier": 3, "axial": Vector2i(7, -7),
		"max_rank": 1, "cost": {BEE_BREAD: 16, HONEY: 50, POLLEN: 150},
		"requires_previous_tier": true, "all_of": [BEE_BREAD_SKILL], "any_of": [],
		"feature": "", "introduced_by": "", "effects": [], "icon": "",
		"status": "existing", "baseline": false, "open": false,
	},
	{
		"id": PRIORITY_CELLS, "name": "Priority cells",
		"description": "Mark brood cells that nurses feed before any others, so scarce food goes where you want it.",
		"sector": "brood", "tier": 3, "axial": Vector2i(6, -7),
		"max_rank": 1, "cost": {BEE_BREAD: 12, HONEY: 40, NECTAR: 120},
		"requires_previous_tier": true, "all_of": [NURSES], "any_of": [],
		"feature": "", "introduced_by": "", "effects": [], "icon": "",
		"status": "new", "baseline": false, "open": false,
	},
	{
		# The one tier-4 recipe that still names royal jelly directly.
		"id": GYNE_REARING, "name": "Gyne rearing",
		"description": "Designate a larva to be raised as a gyne, feed her as one, and give the colony something to send out at the end of the season.",
		"sector": "brood", "tier": 4, "axial": Vector2i(9, -9),
		"max_rank": 1, "cost": {POLLINATOR_POINTS: 30, ROYAL_JELLY: 10, BEE_BREAD: 30, HONEY: 80},
		"requires_previous_tier": true, "all_of": [ROYAL_JELLY_SKILL], "any_of": [],
		"feature": "", "introduced_by": "", "effects": [], "icon": "",
		"status": "existing", "baseline": false, "open": false,
	},
	{
		# Nothing drone-related exists in the codebase: a full feature
		# slice, not a wiring job (section 5.2).
		"id": DRONES, "name": "Drones",
		"description": "Raise drones, so the colony has something to send to another colony's gyne rather than only its own.",
		"sector": "brood", "tier": 4, "axial": Vector2i(8, -9),
		"max_rank": 1, "cost": {POLLINATOR_POINTS: 25, BEE_BREAD: 25, HONEY: 70},
		"requires_previous_tier": true, "all_of": [ROYAL_JELLY_SKILL], "any_of": [],
		"feature": "", "introduced_by": "", "effects": [], "icon": "",
		"status": "new", "baseline": false, "open": false,
	},

	# --- Colony ---------------------------------------------------
	{
		# The one numeric node in the catalogue, and a deliberate
		# exception to section 7's "numbers live in adaptations" line
		# (section 5.10 item 4). Not a precedent for percentage filler.
		"id": CELL_CAPACITY, "name": "Cell capacity",
		"description": "Bees learn to draw a deeper cell, so each one holds more of whatever is put in it.",
		"sector": "colony", "tier": 1, "axial": Vector2i(0, -3),
		"max_rank": 1, "cost": {NECTAR: 130, POLLEN: 50},
		"requires_previous_tier": true, "all_of": [], "any_of": [],
		"feature": "", "introduced_by": "", "effects": [], "icon": "",
		"status": "new", "baseline": false, "open": false,
	},
	{
		"id": COMB_WORKER, "name": "Comb worker",
		"description": "Unlocks the Comb worker role: drawing new cells, clearing blocked ones, and the controls that direct both.",
		"sector": "colony", "tier": 2, "axial": Vector2i(0, -5),
		"max_rank": 1, "cost": {HONEY: 20, NECTAR: 200},
		"requires_previous_tier": true, "all_of": [], "any_of": [],
		"feature": "", "introduced_by": "", "effects": [], "icon": "",
		"status": "existing", "baseline": false, "open": false,
	},
	{
		# Automation needs this and Comb worker together (section 8.2).
		# The Hive Mind-facing slots (-1, -4) and (-2, -3) both sat
		# exactly on Comb worker's connect line to Automation (the grid
		# check caught it), so this uses the wedge's other free slot.
		"id": MINER, "name": "Miner",
		"description": "Unlocks the Miner role and dig orders, so the hive can open up room for more comb.",
		"sector": "colony", "tier": 2, "axial": Vector2i(1, -5),
		"max_rank": 1, "cost": {HONEY: 20, NECTAR: 180, POLLEN: 60},
		"requires_previous_tier": true, "all_of": [], "any_of": [],
		"feature": "", "introduced_by": "", "effects": [], "icon": "",
		"status": "existing", "baseline": false, "open": false,
	},
	{
		"id": RESTOCKING, "name": "Restocking",
		"description": "Keep chosen cells stocked with one resource, so honey can sit beside the brood before winter rather than wherever it landed.",
		"sector": "colony", "tier": 3, "axial": Vector2i(0, -7),
		"max_rank": 1, "cost": {BEE_BREAD: 12, HONEY: 40, NECTAR: 150},
		"requires_previous_tier": true, "all_of": [COMB_WORKER], "any_of": [],
		"feature": "", "introduced_by": "", "effects": [], "icon": "",
		"status": "existing", "baseline": false, "open": false,
	},

	# --- Defence --------------------------------------------------
	{
		"id": THREAT_DETECTION, "name": "Threat detection",
		"description": "A bee that has seen a predator remembers where it was, instead of walking back into it.",
		"sector": "defence", "tier": 1, "axial": Vector2i(0, 3),
		"max_rank": 1, "cost": {NECTAR: 120, POLLEN: 50},
		"requires_previous_tier": true, "all_of": [], "any_of": [],
		"feature": Features.PREDATORS, "introduced_by": "", "effects": [], "icon": "",
		"status": "existing_foundation", "baseline": false, "open": false,
	},
	{
		# Cross-sector prerequisite, which is why this sits on the
		# Foraging edge of the Defence wedge (section 8.2). It replaces
		# the current global alarm_pheromone_on placeholder as the
		# delivery mechanism -- expected migration, not new scope.
		"id": ALARM_PHEROMONE, "name": "Alarm pheromone",
		"description": "Bees read the alarm left by an attacked bee and keep away from that flower until it has faded.",
		"sector": "defence", "tier": 1, "axial": Vector2i(1, 2),
		"max_rank": 1, "cost": {NECTAR: 140, POLLEN: 50},
		"requires_previous_tier": true, "all_of": [TARSAL_SECRETIONS], "any_of": [],
		"feature": Features.PREDATORS, "introduced_by": "", "effects": [], "icon": "",
		"status": "existing_placeholder", "baseline": false, "open": false,
	},
	{
		# Role.GUARD must be *appended* to bee_enums.gd's Role enum when
		# this is built, never inserted or renumbered (section 5.4).
		"id": GUARD_BEE, "name": "Guard bee",
		"description": "Unlocks the Guard role: bees that stay near the entrance and watch, rather than working.",
		"sector": "defence", "tier": 2, "axial": Vector2i(0, 5),
		"max_rank": 1, "cost": {HONEY: 20, NECTAR: 180, POLLEN: 70},
		"requires_previous_tier": true, "all_of": [THREAT_DETECTION], "any_of": [],
		"feature": "", "introduced_by": "", "effects": [], "icon": "",
		"status": "new", "baseline": false, "open": false,
	},
	{
		# Resolution has to be reusable for robbers and wasps later, not
		# crab-spider-specific, and no strength tuning before playtest.
		"id": COMBAT, "name": "Combat",
		"description": "Guards can attack what they find rather than only watching it.",
		"sector": "defence", "tier": 2, "axial": Vector2i(1, 4),
		"max_rank": 1, "cost": {HONEY: 25, NECTAR: 200, POLLEN: 60},
		"requires_previous_tier": true, "all_of": [GUARD_BEE], "any_of": [],
		"feature": "", "introduced_by": "", "effects": [], "icon": "",
		"status": "new", "baseline": false, "open": false,
	},
	{
		# Split out of the old danger_memory (section 5.10 item 3).
		"id": SUPPRESS_RECRUITMENT, "name": "Suppress recruitment",
		"description": "A bee that has just escaped something does not send anyone else towards it until the danger has genuinely moved on.",
		"sector": "defence", "tier": 2, "axial": Vector2i(-1, 5),
		"max_rank": 1, "cost": {HONEY: 20, NECTAR: 160},
		"requires_previous_tier": true, "all_of": [THREAT_DETECTION], "any_of": [],
		"feature": "", "introduced_by": "", "effects": [], "icon": "",
		"status": "new", "baseline": false, "open": false,
	},
	{
		# Open: what it does is Dave's to define (section 5.9 item 1).
		# Carried as data with no effects so the tier is not left with a
		# hole nobody remembers.
		"id": MEDICINE, "name": "Medicine",
		"description": "Not yet defined. A disease system already exists, so a hygienic or propolis reading would have a foundation -- unconfirmed.",
		"sector": "defence", "tier": 3, "axial": Vector2i(0, 7),
		"max_rank": 1, "cost": {BEE_BREAD: 12, HONEY: 40, POLLEN: 120},
		"requires_previous_tier": true, "all_of": [], "any_of": [],
		"feature": "", "introduced_by": "", "effects": [], "icon": "",
		"status": "open", "baseline": false, "open": true,
	},
	{
		# One node covering auto-defence and auto attack. Must not become
		# a constant threat scan every frame (section 5.4).
		"id": AUTO_DEFENCE, "name": "Auto-defence",
		"description": "Guards act on what the colony has seen and engage without being told one at a time.",
		"sector": "defence", "tier": 3, "axial": Vector2i(1, 6),
		"max_rank": 1, "cost": {BEE_BREAD: 14, HONEY: 45, NECTAR: 150},
		"requires_previous_tier": true, "all_of": [COMBAT], "any_of": [],
		"feature": "", "introduced_by": "", "effects": [], "icon": "",
		"status": "new", "baseline": false, "open": false,
	},

	# --- Ecology --------------------------------------------------
	{
		# Section 5.10 item 5 is unresolved: this node either ships in
		# two halves or waits for a drought feature. It is authored here
		# as the rain half's home, depending on the weather feature it
		# can actually read. The drought half is deliberately not
		# authored as a second node -- that call is Dave's, not this
		# slice's, and features.gd holds feature.drought either way.
		"id": WEATHER_SENSING, "name": "Weather sensing",
		"description": "The colony reads bad weather coming and stops sending bees out into it, rather than only reacting once it has arrived.",
		"sector": "ecology", "tier": 1, "axial": Vector2i(-3, 3),
		"max_rank": 1, "cost": {NECTAR: 120, POLLEN: 50},
		"requires_previous_tier": true, "all_of": [], "any_of": [],
		"feature": Features.WEATHER, "introduced_by": "", "effects": [], "icon": "",
		"status": "existing_foundation", "baseline": false, "open": false,
	},
	{
		"id": RAIN_RECALL, "name": "Rain recall",
		"description": "Bees already out abandon what they are doing and come home when the rain gets bad enough -- not just the ones about to set off.",
		"sector": "ecology", "tier": 2, "axial": Vector2i(-5, 5),
		"max_rank": 1, "cost": {HONEY: 20, NECTAR: 170},
		"requires_previous_tier": true, "all_of": [WEATHER_SENSING], "any_of": [],
		"feature": Features.WEATHER, "introduced_by": "", "effects": [], "icon": "",
		"status": "new", "baseline": false, "open": false,
	},

	# --- Hive Mind ------------------------------------------------
	{
		"id": BACKUP_ROLES, "name": "Backup roles",
		"description": "Give a bee a second job to fall back on when its first has nothing to do.",
		"sector": "hive_mind", "tier": 1, "axial": Vector2i(-3, 0),
		"max_rank": 1, "cost": {NECTAR: 110, POLLEN: 50},
		"requires_previous_tier": true, "all_of": [], "any_of": [],
		"feature": "", "introduced_by": "", "effects": [], "icon": "",
		"status": "existing", "baseline": false, "open": false,
	},
	{
		# Cross-sector prerequisite into Colony, so it sits on that edge
		# of the wedge. One node, not two: auto-mining and auto-building
		# together (section 5.10 item 1).
		"id": AUTOMATION, "name": "Automation",
		"description": "Comb workers and miners keep working outward on their own, beyond the tiles you have marked yourself.",
		"sector": "hive_mind", "tier": 2, "axial": Vector2i(-3, -2),
		"max_rank": 1, "cost": {HONEY: 25, NECTAR: 200},
		"requires_previous_tier": true, "all_of": [COMB_WORKER, MINER], "any_of": [],
		"feature": "", "introduced_by": "", "effects": [], "icon": "",
		"status": "existing", "baseline": false, "open": false,
	},
	{
		"id": CLEANING, "name": "Cleaning",
		"description": "Debris and corpses become work the colony takes on deliberately, rather than something that simply sits there.",
		# (-5, 0) sat on the sector's own r=0 spine, exactly on Backup
		# roles' connect line to both Adjustment panel and Extended
		# backup roles (the grid check caught it); this slot is off that
		# axis entirely.
		"sector": "hive_mind", "tier": 2, "axial": Vector2i(-4, -1),
		"max_rank": 1, "cost": {HONEY: 20, NECTAR: 160, POLLEN: 60},
		"requires_previous_tier": true, "all_of": [], "any_of": [],
		"feature": "", "introduced_by": "", "effects": [], "icon": "",
		"status": "existing_foundation", "baseline": false, "open": false,
	},
	{
		# Depends on the behaviours it sets existing: combat (Defence T2),
		# rain recall (Ecology T2), and drought, which is not a feature
		# yet -- so the panel ships with the rows it can actually drive.
		"id": ADJUSTMENT_PANEL, "name": "Adjustment panel",
		"description": "One place to set what the colony does by default -- how it answers a threat, and what it does when the weather turns.",
		"sector": "hive_mind", "tier": 3, "axial": Vector2i(-7, 0),
		"max_rank": 1, "cost": {BEE_BREAD: 12, HONEY: 40, NECTAR: 140},
		"requires_previous_tier": true, "all_of": [BACKUP_ROLES], "any_of": [],
		"feature": "", "introduced_by": "", "effects": [], "icon": "",
		"status": "new", "baseline": false, "open": false,
	},
	{
		"id": EXTENDED_BACKUP_ROLES, "name": "Extended backup roles",
		"description": "Order a bee's fallback jobs by priority instead of naming a single one.",
		"sector": "hive_mind", "tier": 3, "axial": Vector2i(-6, -1),
		"max_rank": 1, "cost": {BEE_BREAD: 10, HONEY: 35, NECTAR: 120},
		"requires_previous_tier": true, "all_of": [BACKUP_ROLES], "any_of": [],
		"feature": "", "introduced_by": "", "effects": [], "icon": "",
		"status": "new", "baseline": false, "open": false,
	},
	{
		# Open: what it does is Dave's to define (section 5.9 item 2).
		"id": CHEMICAL_CASCADE, "name": "Chemical cascade",
		"description": "Not yet defined.",
		"sector": "hive_mind", "tier": 4, "axial": Vector2i(-9, 0),
		"max_rank": 1, "cost": {POLLINATOR_POINTS: 25, BEE_BREAD: 25, HONEY: 70},
		"requires_previous_tier": true, "all_of": [], "any_of": [],
		"feature": "", "introduced_by": "", "effects": [], "icon": "",
		"status": "open", "baseline": false, "open": true,
	},

	# --- Baseline capabilities (section 5.7) ----------------------
	# On from the start, not purchasable, no grid position. Reserved as
	# data so promoting one to a node later is an edit, not a rewrite.
	{
		"id": AUTO_SCOUTING, "name": "Auto scouting",
		"description": "A new forager samples a few areas and keeps the best one.",
		"sector": "foraging", "tier": 0, "axial": Vector2i(0, 0),
		"max_rank": 1, "cost": {},
		"requires_previous_tier": false, "all_of": [], "any_of": [],
		"feature": "", "introduced_by": "", "effects": [], "icon": "",
		"status": "baseline", "baseline": true, "open": false,
	},
	{
		"id": WORK_PRIORITIES, "name": "Work priorities",
		"description": "Cells, zones and orders can be given priority over one another.",
		"sector": "colony", "tier": 0, "axial": Vector2i(0, 0),
		"max_rank": 1, "cost": {},
		"requires_previous_tier": false, "all_of": [], "any_of": [],
		"feature": "", "introduced_by": "", "effects": [], "icon": "",
		"status": "baseline", "baseline": true, "open": false,
	},
	{
		"id": STANDING_INSTRUCTIONS, "name": "Standing instructions",
		"description": "Instructions that persist, such as keeping a role or working from here.",
		"sector": "hive_mind", "tier": 0, "axial": Vector2i(0, 0),
		"max_rank": 1, "cost": {},
		"requires_previous_tier": false, "all_of": [], "any_of": [],
		"feature": "", "introduced_by": "", "effects": [], "icon": "",
		"status": "baseline", "baseline": true, "open": false,
	},
	{
		"id": LANDSCAPE_MEMORY, "name": "Landscape memory",
		"description": "Meadow the colony has explored stays remembered rather than dimming back towards uncertain.",
		"sector": "ecology", "tier": 0, "axial": Vector2i(0, 0),
		"max_rank": 1, "cost": {},
		"requires_previous_tier": false, "all_of": [], "any_of": [],
		"feature": Features.FOG_OF_WAR, "introduced_by": "", "effects": [], "icon": "",
		"status": "baseline", "baseline": true, "open": false,
	},
]

# --- lookups ------------------------------------------------------

static func entry(skill_id: String) -> Dictionary:
	for skill in SKILLS:
		if skill.id == skill_id:
			return skill
	return {}

static func has(skill_id: String) -> bool:
	return not entry(skill_id).is_empty()

static func ids() -> Array:
	return SKILLS.map(func(s): return s.id)

static func label_for(skill_id: String) -> String:
	return entry(skill_id).get("name", skill_id)

static func cost_for(skill_id: String) -> Dictionary:
	return entry(skill_id).get("cost", {})

static func is_baseline(skill_id: String) -> bool:
	return entry(skill_id).get("baseline", false)

## Product-scope 6.4's nine cuts: kept in the catalogue, never offered,
## never ownable in the alpha.
const CUT_FROM_ALPHA := [
	"skill.defence.guard_bee", "skill.defence.combat", "skill.defence.auto_defence",
	"skill.foraging.nectar_robbing", "skill.brood.drones", "skill.defence.medicine",
	"skill.hive_mind.adjustment_panel", "skill.hive_mind.extended_backup_roles",
	"skill.hive_mind.chemical_cascade",
]

static func is_cut(skill_id: String) -> bool:
	return CUT_FROM_ALPHA.has(skill_id)

## False while the node's design status says its effect is not built yet.
static func is_built(skill_id: String) -> bool:
	return not ["new", "open", "existing_placeholder"].has(str(entry(skill_id).get("status", "")))

## Every purchasable node in one sector, in catalogue (tier) order.
static func for_sector(sector_key: String) -> Array:
	return SKILLS.filter(func(s): return s.sector == sector_key and not s.baseline)

static func for_sector_tier(sector_key: String, tier: int) -> Array:
	return SKILLS.filter(func(s): return s.sector == sector_key and s.tier == tier)

## Section 5.7's always-on capabilities, which the resolver will treat as
## owned from the first frame of every run.
static func baseline_ids() -> Array:
	return SKILLS.filter(func(s): return s.baseline).map(func(s): return s.id)

static func sector_keys() -> Array:
	return SECTORS.map(func(s): return s.key)

## A sector's position in shapes.gd's axial direction order, which is
## also the direction its wedge points along (section 8.2). -1 if the key
## names no sector.
static func sector_index(sector_key: String) -> int:
	for i in range(SECTORS.size()):
		if SECTORS[i].key == sector_key:
			return i
	return -1

static func sector_label(sector_key: String) -> String:
	var index := sector_index(sector_key)
	return SECTORS[index].label if index >= 0 else sector_key

## The ring a tier's tiles sit on (section 8.1). Baseline entries are not
## on the grid at all, so this is meaningless for tier 0.
static func ring_for_tier(tier: int) -> int:
	return 2 * tier + 1
