extends RefCounted
## The authoritative catalogue of work a bee may start.
##
## Usage: const Actions = preload("res://scripts/actions.gd")
##
## bee.gd::_try_role_work walks these rows in band order (G2). Empty `modes`
## means every sub-mode of the role offers the action. The gate fields (G3):
## `config_flag` is a GameConfig bool, `skill` a progression skill the colony
## must own, and `gate_key` the stage-gate key a Challenge stage names in its
## `unlocked_keys` to offer the action -- by convention the action's own id.
## `feature` and `season` are not queried yet and stay empty. An empty gate field means "always available", never "check and
## pass": Availability.action_query only looks at the fields a row fills, and
## bee.gd never queries a row with none filled. Every field ships empty until
## a Challenge 1 or 2 stage needs one (tests/source_checks.py).
##
## Dispatcher exception: the queen's brood-before-laying choice remains in
## bee.gd::_idle_dispatch. It is a dispatch rule, not an action row.

const Roles = preload("res://scripts/roles.gd")

const GATE_FIELDS := ["feature", "skill", "gate_key", "config_flag", "season"]

static var _by_id: Dictionary = {}

## The catalogue row for `action_id`, or {} if there is none.
static func by_id(action_id: String) -> Dictionary:
	if _by_id.is_empty():
		for action in ACTIONS:
			_by_id[action.id] = action
	return _by_id.get(action_id, {})

## Whether `action` fills any gate field, or serves a role a skill unlocks
## (BS-3: Availability.action_query refuses that row until the skill is
## owned) -- a row that is neither is always available and is never queried.
static func is_gated(action: Dictionary) -> bool:
	for field in GATE_FIELDS:
		if str(action.get(field, "")) != "":
			return true
	for role_id in action.get("roles", []):
		if Roles.skill_for(role_id) != "":
			return true
	return false

const ACTIONS := [
	# A jelly-only nurse skips feeding; an Anything nurse feeds before either
	# jelly action. Bands still express the shared priority sequence.
	{
		"id": "nurse_feed_brood", "label": "Feed brood", "roles": [Roles.NURSE],
		"band": 0, "modes": ["feed", "both"], "find": "find_brood_cell",
		"feature": "", "skill": "", "gate_key": "", "config_flag": "", "season": "",
	},
	{
		"id": "nurse_store_jelly", "label": "Store royal jelly", "roles": [Roles.NURSE],
		"band": 1, "modes": ["jelly", "both"], "find": "jelly_storage_cell",
		"feature": "", "skill": "skill.brood.royal_jelly", "gate_key": "", "config_flag": "", "season": "",
	},
	{
		"id": "nurse_make_jelly", "label": "Make royal jelly", "roles": [Roles.NURSE],
		"band": 2, "modes": ["jelly", "both"], "find": "can_make_jelly",
		"feature": "", "skill": "skill.brood.royal_jelly", "gate_key": "", "config_flag": "", "season": "",
	},

	# Maintenance outranks stocking and building. A Stocking comb worker clears
	# and evicts too: bee.gd's pre-catalogue branch ran both for every mode but
	# "build", and only the *restock* and *build* steps were mode-specific.
	# Corrected 17 Sep 2026 during G2's integration review.
	{
		"id": "comb_clean_cell", "label": "Clean cell", "roles": [Roles.COMB_WORKER],
		"band": 0, "modes": ["maintain", "restock", "both"], "find": "find_cell_needing_cleaning",
		"feature": "", "skill": "skill.hive_mind.cleaning", "gate_key": "", "config_flag": "", "season": "",
	},
	{
		"id": "comb_evict_cell", "label": "Evict cell stores", "roles": [Roles.COMB_WORKER],
		"band": 1, "modes": ["maintain", "restock", "both"], "find": "find_cell_needing_eviction",
		"feature": "", "skill": "", "gate_key": "", "config_flag": "", "season": "",
	},
	# RR-19: capping a cell the player asked to be sealed, or uncapping one
	# they asked to be opened. Right after eviction: both carry out a cell
	# order. Bands are one per row (tests/source_checks.py), so the rows
	# below it moved down one.
	{
		"id": "comb_seal_cell", "label": "Seal or open cell", "roles": [Roles.COMB_WORKER],
		"band": 2, "modes": ["maintain", "restock", "both"], "find": "find_cell_needing_sealing",
		"feature": "", "skill": "", "gate_key": "", "config_flag": "", "season": "",
	},
	{
		"id": "comb_restock", "label": "Restock cell", "roles": [Roles.COMB_WORKER],
		"band": 3, "modes": ["restock", "both"], "find": "find_restock_job",
		"feature": "", "skill": "", "gate_key": "", "config_flag": "", "season": "",
	},
	{
		"id": "comb_build", "label": "Build comb", "roles": [Roles.COMB_WORKER],
		"band": 4, "modes": ["build", "both"], "find": "create_cell_site_at",
		"feature": "", "skill": "", "gate_key": "", "config_flag": "", "season": "",
	},
	# T2-2: extending the outward spiral past the marked sites is Automation's.
	{
		"id": "comb_build_outward", "label": "Build comb outward", "roles": [Roles.COMB_WORKER],
		"band": 5, "modes": ["build", "both"], "find": "create_next_cell_site_outward",
		"feature": "", "skill": "skill.hive_mind.automation", "gate_key": "", "config_flag": "", "season": "",
	},

	# A direct player order always wins over a marked block, which wins over
	# autonomous mining.
	{
		"id": "mine_queued_block", "label": "Mine queued block", "roles": [Roles.MINER],
		"band": 0, "modes": [], "find": "_next_queued_block",
		"feature": "", "skill": "", "gate_key": "", "config_flag": "", "season": "",
	},
	{
		"id": "mine_marked_block", "label": "Mine marked block", "roles": [Roles.MINER],
		"band": 1, "modes": [], "find": "find_marked_block",
		"feature": "", "skill": "", "gate_key": "", "config_flag": "", "season": "",
	},
	{
		"id": "mine_automine_block", "label": "Mine nearest edge block", "roles": [Roles.MINER],
		"band": 2, "modes": ["automine"], "find": "find_nearest_edge_block",
		"feature": "", "skill": "skill.hive_mind.automation", "gate_key": "", "config_flag": "", "season": "",
	},

	# BB-1: bee bread comes ahead of honey. Any honey maker holding bee bread
	# puts it in a cell first, so turning Fermenting off never strands a
	# load; only a Fermenting one makes more. When neither applies, the
	# honey rows below run as before.
	{
		"id": "honey_deposit_bee_bread", "label": "Store bee bread", "roles": [Roles.HONEY],
		"band": 0, "modes": [], "find": "find_bee_bread_target",
		"feature": "", "skill": "skill.brood.bee_bread", "gate_key": "", "config_flag": "", "season": "",
	},
	{
		"id": "honey_make_bee_bread", "label": "Make bee bread", "roles": [Roles.HONEY],
		"band": 1, "modes": ["ferment"], "find": "find_bee_bread_ingredients",
		"feature": "", "skill": "skill.brood.bee_bread", "gate_key": "", "config_flag": "", "season": "",
	},

	# A honey maker deposits a held load, fans wet honey, then fetches nectar.
	{
		"id": "honey_deposit_load", "label": "Deposit honey", "roles": [Roles.HONEY],
		"band": 2, "modes": [], "find": "find_honey_target",
		"feature": "", "skill": "", "gate_key": "", "config_flag": "", "season": "",
	},
	{
		"id": "honey_fan_cell", "label": "Fan honey", "roles": [Roles.HONEY],
		"band": 3, "modes": [], "find": "find_cell_needing_fanning",
		"feature": "", "skill": "", "gate_key": "", "config_flag": "", "season": "",
	},
	{
		"id": "honey_fetch_nectar", "label": "Fetch nectar", "roles": [Roles.HONEY],
		"band": 4, "modes": [], "find": "find_cell_with",
		"feature": "", "skill": "", "gate_key": "", "config_flag": "", "season": "",
	},

	{
		"id": "queen_lay_egg", "label": "Lay egg", "roles": [Roles.QUEEN],
		"band": 0, "modes": [], "find": "has_room_for_egg",
		"feature": "", "skill": "", "gate_key": "", "config_flag": "", "season": "",
	},
	{
		"id": "forager_seek_flower", "label": "Seek flower", "roles": [Roles.FORAGER],
		"band": 0, "modes": [], "find": "start_seek_flower",
		"feature": "", "skill": "", "gate_key": "", "config_flag": "", "season": "",
	},
]
