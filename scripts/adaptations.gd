extends RefCounted
## The one place a Colony Adaptation card is described.
##
## Usage: const Adaptations = preload("res://scripts/adaptations.gd")
##        Adaptations.entry(Adaptations.STRONGER_WINGS).name
##
## Scope (progression.md section 3, Phase A step 1): catalogue data only.
## Adaptations are deliberately the *last* thing built -- section 7 moves
## them behind the entire skill tree, and no skill-tree slice may depend
## on them existing. The reason to author the data now anyway is that the
## design is settled and would otherwise rot in a plan file; the reason
## every `effects` is `[]` is that the effect schema belongs to the
## resolver, which does not exist yet.
##
## The division of labour with skills.gd, which is the whole point of
## keeping them apart: **skills unlock capabilities, adaptations move
## numbers.** A card here is a percentage; a node there is a thing the
## colony can now do. `skill.colony.cell_capacity` is the one deliberate
## exception, flagged in section 5.10 item 4 so it does not become the
## precedent for a tree full of percentage filler.
##
## Bands are balance ranges, not values
## ------------------------------------
## `band` is `[low, high]` as a percentage, straight from section 7.3,
## and several cards have none at all (`[]`) because the design says what
## the card does without saying by how much. Nothing should read a band
## as a shipped number: they need simulation with the scenario harness.

const Skills = preload("res://scripts/skills.gd")
const Features = preload("res://scripts/features.gd")

# --- adaptation ids -----------------------------------------------

const STRONGER_WINGS := "adaptation.general.stronger_wings"
const DEEPER_STORES := "adaptation.general.deeper_stores"
const FULLER_CROPS := "adaptation.general.fuller_crops"
const FRUGAL_COLONY := "adaptation.general.frugal_colony"
const LONG_LIVED_WORKERS := "adaptation.general.long_lived_workers"

const NIMBLE_HANDLING := "adaptation.foraging.nimble_handling"
const EFFICIENT_FLIGHT := "adaptation.foraging.efficient_flight"
const LONG_RANGE := "adaptation.foraging.long_range"
const QUICK_LEARNERS := "adaptation.foraging.quick_learners"
const PERSISTENT_MEMORY := "adaptation.foraging.persistent_memory"

const ATTENTIVE_NURSES := "adaptation.brood.attentive_nurses"
const SUSTAINING_MEALS := "adaptation.brood.sustaining_meals"
const HEALTHY_BROOD := "adaptation.brood.healthy_brood"
const RICH_JELLY := "adaptation.brood.rich_jelly"
const EFFICIENT_FANNING := "adaptation.brood.efficient_fanning"

const WAX_EFFICIENCY := "adaptation.colony.wax_efficiency"
const TIRELESS_BUILDERS := "adaptation.colony.tireless_builders"
const SURE_FOOTED_MINERS := "adaptation.colony.sure_footed_miners"
const LARGER_SPOIL_LOADS := "adaptation.colony.larger_spoil_loads"

const WEATHERED_WINGS := "adaptation.ecology.weathered_wings"
const EARLY_WARNING := "adaptation.ecology.early_warning"

const ALERT_GUARDS := "adaptation.defence.alert_guards"
const FORCEFUL_DEFENCE := "adaptation.defence.forceful_defence"
const HYGIENIC_COLONY := "adaptation.defence.hygienic_colony"

# --- the catalogue ------------------------------------------------
## Fields:
##   id               stable key; never a display string
##   name             display text; never a save key or a dependency
##   description      the effect in the player's words
##   group            general, or the sector the card belongs beside
##   max_rank         1 for every card in this pass (section 4.4)
##   requires_skill   a skills.gd id that must be owned, or ""
##   requires_feature a features.gd id the run must have, or ""
##   band             [low, high] percentage from section 7.3, or []
##   effects          typed effects; empty until the resolver exists
##   offerable        false where the design says not to offer it yet
##   icon             card art; empty until the panel exists

const ADAPTATIONS := [
	# --- General --------------------------------------------------
	{
		"id": STRONGER_WINGS, "name": "Stronger wings",
		"description": "Bees fly faster outdoors. Walking about inside the hive is unchanged.",
		"group": "general", "max_rank": 1,
		"requires_skill": "", "requires_feature": "", "band": [6, 10],
		"effects": [], "offerable": true, "icon": "",
	},
	{
		"id": DEEPER_STORES, "name": "Deeper stores",
		"description": "Every cell holds a little more nectar, pollen, honey or jelly.",
		"group": "general", "max_rank": 1,
		"requires_skill": "", "requires_feature": "", "band": [8, 12],
		"effects": [], "offerable": true, "icon": "",
	},
	{
		"id": FULLER_CROPS, "name": "Fuller crops",
		"description": "A forager carries more home per trip.",
		"group": "general", "max_rank": 1,
		"requires_skill": "", "requires_feature": "", "band": [8, 12],
		"effects": [], "offerable": true, "icon": "",
	},
	{
		# Touches every role's energy use, so it wants careful simulation
		# rather than a number picked off the band (section 7.3).
		"id": FRUGAL_COLONY, "name": "Frugal colony",
		"description": "Bees burn less energy going about ordinary work.",
		"group": "general", "max_rank": 1,
		"requires_skill": "", "requires_feature": "", "band": [5, 8],
		"effects": [], "offerable": true, "icon": "",
	},
	{
		"id": LONG_LIVED_WORKERS, "name": "Long-lived workers",
		"description": "Workers live longer. The queen and any gynes are unaffected.",
		"group": "general", "max_rank": 1,
		"requires_skill": "", "requires_feature": "", "band": [5, 8],
		"effects": [], "offerable": true, "icon": "",
	},

	# --- Foraging -------------------------------------------------
	{
		"id": NIMBLE_HANDLING, "name": "Nimble handling",
		"description": "Bees spend less time working each flower.",
		"group": "foraging", "max_rank": 1,
		"requires_skill": "", "requires_feature": "", "band": [8, 12],
		"effects": [], "offerable": true, "icon": "",
	},
	{
		"id": EFFICIENT_FLIGHT, "name": "Efficient flight",
		"description": "Flying costs less energy.",
		"group": "foraging", "max_rank": 1,
		"requires_skill": "", "requires_feature": "", "band": [10, 15],
		"effects": [], "offerable": true, "icon": "",
	},
	{
		"id": LONG_RANGE, "name": "Long range",
		"description": "Foragers look further from the hive for something worth working.",
		"group": "foraging", "max_rank": 1,
		"requires_skill": "", "requires_feature": "", "band": [10, 15],
		"effects": [], "offerable": true, "icon": "",
	},
	{
		"id": QUICK_LEARNERS, "name": "Quick learners",
		"description": "Bees get familiar with a species of flower faster.",
		"group": "foraging", "max_rank": 1,
		"requires_skill": Skills.ASSOCIATIVE_LEARNING, "requires_feature": "", "band": [],
		"effects": [], "offerable": true, "icon": "",
	},
	{
		"id": PERSISTENT_MEMORY, "name": "Persistent memory",
		"description": "Familiarity with a species fades more slowly when a bee stops working it.",
		"group": "foraging", "max_rank": 1,
		"requires_skill": Skills.ASSOCIATIVE_LEARNING, "requires_feature": "", "band": [],
		"effects": [], "offerable": true, "icon": "",
	},

	# --- Brood ----------------------------------------------------
	{
		"id": ATTENTIVE_NURSES, "name": "Attentive nurses",
		"description": "A nurse carries one more feed before it has to go back for more.",
		"group": "brood", "max_rank": 1,
		"requires_skill": Skills.NURSES, "requires_feature": "", "band": [],
		"effects": [], "offerable": true, "icon": "",
	},
	{
		"id": SUSTAINING_MEALS, "name": "Sustaining meals",
		"description": "Each feed buys a larva a longer stretch of growth.",
		"group": "brood", "max_rank": 1,
		"requires_skill": Skills.NURSES, "requires_feature": "", "band": [10, 15],
		"effects": [], "offerable": true, "icon": "",
	},
	{
		"id": HEALTHY_BROOD, "name": "Healthy brood",
		"description": "Disease slows brood development less than it would.",
		"group": "brood", "max_rank": 1,
		"requires_skill": "", "requires_feature": Features.DISEASE, "band": [],
		"effects": [], "offerable": true, "icon": "",
	},
	{
		"id": RICH_JELLY, "name": "Rich jelly",
		"description": "A nurse gets more royal jelly out of each batch.",
		"group": "brood", "max_rank": 1,
		"requires_skill": Skills.ROYAL_JELLY_SKILL, "requires_feature": "", "band": [],
		"effects": [], "offerable": true, "icon": "",
	},
	{
		"id": EFFICIENT_FANNING, "name": "Efficient fanning",
		"description": "Honey ripens sooner, so a cell is finished with faster.",
		"group": "brood", "max_rank": 1,
		"requires_skill": Skills.HONEY_WORKER, "requires_feature": "", "band": [10, 15],
		"effects": [], "offerable": true, "icon": "",
	},

	# --- Colony ---------------------------------------------------
	{
		"id": WAX_EFFICIENCY, "name": "Wax efficiency",
		"description": "Drawing a cell burns less energy.",
		"group": "colony", "max_rank": 1,
		"requires_skill": Skills.COMB_WORKER, "requires_feature": "", "band": [10, 15],
		"effects": [], "offerable": true, "icon": "",
	},
	{
		"id": TIRELESS_BUILDERS, "name": "Tireless builders",
		"description": "A cell takes less time to draw.",
		"group": "colony", "max_rank": 1,
		"requires_skill": Skills.COMB_WORKER, "requires_feature": "", "band": [10, 15],
		"effects": [], "offerable": true, "icon": "",
	},
	{
		"id": SURE_FOOTED_MINERS, "name": "Sure-footed miners",
		"description": "Miners dig faster.",
		"group": "colony", "max_rank": 1,
		"requires_skill": Skills.MINER, "requires_feature": "", "band": [10, 15],
		"effects": [], "offerable": true, "icon": "",
	},
	{
		"id": LARGER_SPOIL_LOADS, "name": "Larger spoil loads",
		"description": "A miner carries more soil before it has to go outside and dump it.",
		"group": "colony", "max_rank": 1,
		"requires_skill": Skills.MINER, "requires_feature": "", "band": [],
		"effects": [], "offerable": true, "icon": "",
	},

	# --- Ecology --------------------------------------------------
	{
		"id": WEATHERED_WINGS, "name": "Weathered wings",
		"description": "Rain adds less to the cost of flying. The band is a share of the penalty, not of the base cost.",
		"group": "ecology", "max_rank": 1,
		"requires_skill": "", "requires_feature": Features.WEATHER, "band": [10, 20],
		"effects": [], "offerable": true, "icon": "",
	},
	{
		"id": EARLY_WARNING, "name": "Early warning",
		"description": "The colony notices unsafe weather sooner.",
		"group": "ecology", "max_rank": 1,
		"requires_skill": Skills.WEATHER_SENSING, "requires_feature": "", "band": [],
		"effects": [], "offerable": true, "icon": "",
	},

	# --- Defence --------------------------------------------------
	{
		"id": ALERT_GUARDS, "name": "Alert guards",
		"description": "Guards react to a threat sooner.",
		"group": "defence", "max_rank": 1,
		"requires_skill": Skills.GUARD_BEE, "requires_feature": "", "band": [],
		"effects": [], "offerable": true, "icon": "",
	},
	{
		# Section 7.3 says plainly: do not add this until attack balance
		# is established. Carried as data so the design is not lost, and
		# marked unofferable so it cannot reach a card until it is.
		"id": FORCEFUL_DEFENCE, "name": "Forceful defence",
		"description": "Guards hit harder.",
		"group": "defence", "max_rank": 1,
		"requires_skill": Skills.COMBAT, "requires_feature": "", "band": [],
		"effects": [], "offerable": false, "icon": "",
	},
	{
		"id": HYGIENIC_COLONY, "name": "Hygienic colony",
		"description": "Corpses and crowding push the disease load up less than they would.",
		"group": "defence", "max_rank": 1,
		"requires_skill": "", "requires_feature": Features.DISEASE, "band": [],
		"effects": [], "offerable": true, "icon": "",
	},
]

# --- milestones ---------------------------------------------------
## What triggers an offer (section 7.2). Thresholds are deliberately not
## here: the design says they need the scenario harness rather than a
## guess, and a milestone measures progress made *during* the run so an
## advanced Scenario starting above a raw population figure does not fire
## every one of them on its first frame.

const FIRST_GENERATION := "milestone.colony.first_generation"
const ESTABLISHED := "milestone.colony.established"
const THRIVING := "milestone.colony.thriving"

const MILESTONES := [
	{
		"id": FIRST_GENERATION, "name": "First generation",
		"description": "The colony has raised a meaningful number of new adult workers this run.",
	},
	{
		"id": ESTABLISHED, "name": "Established colony",
		"description": "Meaningful population growth, plus a functioning amount of comb.",
	},
	{
		"id": THRIVING, "name": "Thriving colony",
		"description": "A larger workforce, plus evidence that the colony's economy is stable.",
	},
]

# --- lookups ------------------------------------------------------

static func entry(adaptation_id: String) -> Dictionary:
	for adaptation: Dictionary in ADAPTATIONS:
		if adaptation.id == adaptation_id:
			return adaptation
	return {}

static func has(adaptation_id: String) -> bool:
	return not entry(adaptation_id).is_empty()

static func ids() -> Array:
	return ADAPTATIONS.map(func(a: Dictionary) -> Variant: return a.id)

static func label_for(adaptation_id: String) -> String:
	return entry(adaptation_id).get("name", adaptation_id)

## The cards that may reach an offer at all, before any run-specific
## eligibility test. Section 7.1's three-distinct-cards rule is the
## resolver's job, not this catalogue's.
static func offerable_ids() -> Array:
	return ADAPTATIONS.filter(func(a: Dictionary) -> Variant: return a.offerable).map(func(a: Dictionary) -> Variant: return a.id)

static func for_group(group_key: String) -> Array:
	return ADAPTATIONS.filter(func(a: Dictionary) -> bool: return a.group == group_key)

static func milestone(milestone_id: String) -> Dictionary:
	for entry_data: Dictionary in MILESTONES:
		if entry_data.id == milestone_id:
			return entry_data
	return {}

static func milestone_ids() -> Array:
	return MILESTONES.map(func(m: Dictionary) -> Variant: return m.id)
