extends RefCounted
## Everything about a bee's rolled identity: name, fact, and which stat
## trait it has. One place these are described, so bee.gd, hud.gd and
## save_game.gd all read the same lists -- the same shape as roles.gd.
##
## Usage: const BeeIdentity = preload("res://scripts/bee_identity.gd")
##        BeeIdentity.roll_trait_stat()
##
## Every roll here happens once, at spawn, and the result is saved --
## see BEE_INDIVIDUALITY_PLAN.md. Nothing in this file costs anything
## per frame.

# --- the trait pool -------------------------------------------------
## Matches the five per-bee stats synced from GameConfig in bee.gd's
## _apply_stats(). Tier 2 (lifespan, energy burn) is deliberately not
## here yet -- see the plan's "parked" section.
const TRAIT_STATS := [
	"speed", "nectar_collection_rate", "pollen_collection_rate",
	"nectar_stomach_capacity", "pollen_stomach_capacity",
]

const TRAIT_LABELS := {
	"speed": "Speed",
	"nectar_collection_rate": "Nectar rate",
	"pollen_collection_rate": "Pollen rate",
	"nectar_stomach_capacity": "Nectar capacity",
	"pollen_stomach_capacity": "Pollen capacity",
}

## Picks one stat, a direction (leaning positive per
## GameConfig.trait_positive_chance) and a magnitude from
## GameConfig.trait_magnitude_bands. Returns {"stat": String, "percent": float},
## percent signed, e.g. 0.07 or -0.03.
static func roll_trait_stat() -> Dictionary:
	var stat: String = TRAIT_STATS[randi() % TRAIT_STATS.size()]
	var positive: bool = randf() < GameConfig.trait_positive_chance
	var magnitude: float = _roll_magnitude()
	return {"stat": stat, "percent": magnitude if positive else -magnitude}

static func _roll_magnitude() -> float:
	var bands: Array = GameConfig.trait_magnitude_bands
	var roll: float = randf()
	var cumulative: float = 0.0
	for band in bands:
		cumulative += band.weight
		if roll <= cumulative:
			return randf_range(band.min, band.max)
	# Rounding could leave a sliver unclaimed; fall back to the last band
	# rather than returning nothing.
	var last: Dictionary = bands[bands.size() - 1]
	return randf_range(last.min, last.max)

static func stat_label(stat: String) -> String:
	return TRAIT_LABELS.get(stat, stat)

## "+7%" / "-3%", signed and rounded to a whole percent.
static func trait_percent_text(percent: float) -> String:
	return "%s%d%%" % ["+" if percent >= 0.0 else "", int(round(percent * 100.0))]

# --- names -----------------------------------------------------------
## Any adjective paired with any noun reads fine -- that's what makes
## combining two flat lists safe here, no bad-pairing check needed.
## Append-only, same convention as bee_enums.gd's Role/State: add new
## words at the end, don't reorder or delete, so a saved bee's name
## (rolled once and saved, not re-derived) never has to be revisited.
const NAME_ADJECTIVES := [
	"Speedy", "Sleepy", "Plucky", "Wobbly", "Fuzzy", "Bold", "Nimble",
	"Drowsy", "Cheerful", "Grumpy", "Tiny", "Mighty", "Gentle", "Scrappy",
	"Dizzy", "Sunny", "Breezy", "Quiet", "Restless", "Dapper", "Curious",
	"Stripy", "Golden", "Humble", "Zippy",
]

const NAME_NOUNS := [
	"Clover", "Pip", "Dot", "Marigold", "Thistle", "Buzz", "Daisy",
	"Bramble", "Sorrel", "Hazel", "Poppy", "Fern", "Nettle", "Willow",
	"Clementine", "Rosie", "Petal", "Acorn", "Juniper", "Blossom",
	"Meadow", "Sprig", "Honey", "Basil", "Marjoram",
]

static func roll_name() -> String:
	var adjective: String = NAME_ADJECTIVES[randi() % NAME_ADJECTIVES.size()]
	var noun: String = NAME_NOUNS[randi() % NAME_NOUNS.size()]
	return "%s %s" % [adjective, noun]

# --- facts -------------------------------------------------------------
## Three pools, weighted by GameConfig.fact_trait_matched_chance /
## fact_general_chance / fact_templated_chance. Each entry works
## regardless of whether the bee's roll on that stat was positive or
## negative -- the wording doesn't need to know the sign.
const TRAIT_FACTS := {
	"speed": [
		"Reckons she's the fastest forager in the colony.",
		"Takes the scenic route, every time.",
		"Never seems to be in a hurry, or always is -- hard to tell which.",
		"Beats everyone back to the hive and won't let anyone forget it.",
	],
	"nectar_collection_rate": [
		"Can empty a flower before it knows what's happening.",
		"Takes her time over every flower, like it's the only one that matters.",
		"Swears the good nectar is always one flower further on.",
		"Has strong opinions about which flowers are worth the visit.",
	],
	"pollen_collection_rate": [
		"Comes home dusted head to foot, every single trip.",
		"Is fussier about pollen than anyone has a right to be.",
		"Packs it in tight, like she's being graded on it.",
		"Never quite gets all the pollen off before going back out.",
	],
	"nectar_stomach_capacity": [
		"Carries more nectar than seems physically reasonable.",
		"Makes more trips than anyone, carrying less each time.",
		"Tops up little and often, and won't be talked out of it.",
		"Comes home so full she can barely walk straight.",
	],
	"pollen_stomach_capacity": [
		"Packs her pollen baskets to bursting.",
		"Prefers a light load and a quick turnaround.",
		"Somehow always has room for a little bit more.",
		"Times her trips so she's never carrying quite enough.",
	],
}

const GENERAL_FACTS := [
	"Once got lost for eleven minutes.",
	"Has personally inspected every soil block in the hive.",
	"Named the flower patch to the east 'the good one'.",
	"Grooms her antennae four times before takeoff, never three, never five.",
	"Has never once landed on the same flower twice in a row.",
	"Is convinced she was hatched in a better cell than everyone else.",
	"Keeps circling back to check the entrance is still there.",
	"Refuses to fly in a straight line if a wiggly one is available.",
	"Was the last one out of the cell on hatching day.",
	"Has strong feelings about which wall of the comb faces the sun.",
	"Insists on landing feet-first, every time, no exceptions.",
	"Once followed another bee home by mistake and stayed all week.",
	"Hums slightly off-key from everyone else.",
	"Has a favourite patch of shade and defends it fiercely.",
	"Cleans her wings before anything else, even a full stomach.",
	"Counts the cells on the way past, or seems to.",
	"Was mistaken for the queen once, briefly, by a very confused wasp.",
	"Takes the long way round the comb out of pure habit.",
	"Has opinions about the weather that nobody asked for.",
	"Sleeps facing the entrance, just in case.",
	"Was the slowest to hatch and the first to get to work.",
	"Never quite finishes a landing without a small stumble.",
	"Keeps a mental list of every flower that's disappointed her.",
	"Is the first to notice when the rain is coming.",
	"Flies a little crooked, and gets there just the same.",
	"Was found napping on the queen's own cell, once.",
	"Has never been seen resting -- possibly doesn't.",
	"Prefers company to working alone, whatever the job.",
	"Is inexplicably popular with the nursery workers.",
	"Once carried a passenger halfway home by accident.",
	"Marks her own trail, whether the colony uses tarsal markers or not.",
	"Talks to the flowers, or so the others say.",
	"Has an unshakeable sense of direction, mostly.",
	"Was the first to try a flower nobody else would touch.",
	"Keeps returning to the same cell wall for no obvious reason.",
	"Is smaller than average and makes up for it in attitude.",
	"Never seems to notice when she's carrying too much.",
	"Has outlasted three different queens' worth of gossip.",
]

const FACT_TEMPLATES := [
	"Absolutely loves %s.",
	"Can't stand %s.",
	"Is weirdly fascinated by %s.",
	"Gets nervous around %s.",
	"Has strong opinions about %s.",
	"Never shuts up about %s.",
]

const FACT_SUBJECTS := [
	"the smell of clover", "rainy days", "tight spaces in the comb",
	"long flights", "the colour blue", "loud buzzing", "spiders",
	"crowded cells", "sunbathing on a warm leaf", "thunder",
	"getting lost", "the taste of thistle nectar", "shiny things",
	"mornings", "other bees' gossip", "the smell of fresh wax",
	"windy days", "the far side of the meadow", "queueing at the entrance",
	"the sound of rain on the comb", "freshly dug soil",
	"flowers that close early", "being watched while she works",
	"the first flight of the day", "crowded flower patches",
	"the quiet of the night shift", "a full stomach",
	"unfamiliar flowers",
]

const _WEIGHT_KEYS := ["trait", "general", "templated"]

## Rolls one fact for a bee with the given trait_stat (always set --
## every bee has exactly one trait, per this design). Weighted by
## GameConfig.fact_trait_matched_chance / fact_general_chance /
## fact_templated_chance.
static func roll_fact(trait_stat: String) -> String:
	var weights := {
		"trait": GameConfig.fact_trait_matched_chance,
		"general": GameConfig.fact_general_chance,
		"templated": GameConfig.fact_templated_chance,
	}
	var total: float = 0.0
	for key in _WEIGHT_KEYS:
		total += weights[key]
	var roll: float = randf() * max(0.001, total)
	var cumulative: float = 0.0
	var pool: String = _WEIGHT_KEYS[_WEIGHT_KEYS.size() - 1]
	for key in _WEIGHT_KEYS:
		cumulative += weights[key]
		if roll <= cumulative:
			pool = key
			break

	match pool:
		"trait":
			var options: Array = TRAIT_FACTS.get(trait_stat, GENERAL_FACTS)
			return options[randi() % options.size()]
		"templated":
			var template: String = FACT_TEMPLATES[randi() % FACT_TEMPLATES.size()]
			var subject: String = FACT_SUBJECTS[randi() % FACT_SUBJECTS.size()]
			return template % subject
		_:
			return GENERAL_FACTS[randi() % GENERAL_FACTS.size()]

# --- birth-order "firsts" -------------------------------------------
## Deterministic, no RNG -- overrides the rolled fact above for a
## milestone bee. See bee.gd's setup() for the bee_id / first-gyne
## checks that decide when these apply.

static func milestone_fact_first_bee() -> String:
	return "Was the very first bee this colony ever raised."

static func milestone_fact_first_gyne() -> String:
	return "Was the first gyne this colony ever raised."

static func milestone_fact_nth(n: int) -> String:
	return "Was the %d%s bee this colony ever raised." % [n, _ordinal_suffix(n)]

static func _ordinal_suffix(n: int) -> String:
	if n % 100 in [11, 12, 13]:
		return "th"
	match n % 10:
		1:
			return "st"
		2:
			return "nd"
		3:
			return "rd"
		_:
			return "th"
