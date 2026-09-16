extends RefCounted
## The authoritative catalogue of work a bee may start.
##
## Usage: const Actions = preload("res://scripts/actions.gd")
##
## G1 is deliberately data only: `_try_role_work` still owns dispatch until
## G2. The rows below transcribe its current priority order and must not add a
## gate yet. Empty `modes` means every sub-mode of the role offers the action;
## an empty feature, skill, gate_key, config_flag or season means it is always
## available. G3 owns filling those gate fields.
##
## Dispatcher exception: the queen's brood-before-laying choice remains in
## bee.gd::_idle_dispatch. It is a dispatch rule, not an action row.

const Roles = preload("res://scripts/roles.gd")

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
		"feature": "", "skill": "", "gate_key": "", "config_flag": "", "season": "",
	},
	{
		"id": "nurse_make_jelly", "label": "Make royal jelly", "roles": [Roles.NURSE],
		"band": 2, "modes": ["jelly", "both"], "find": "can_make_jelly",
		"feature": "", "skill": "", "gate_key": "", "config_flag": "", "season": "",
	},

	# Maintenance outranks stocking and building. Mode filters reproduce the
	# current early return for maintain/restock-only comb workers.
	{
		"id": "comb_clean_cell", "label": "Clean cell", "roles": [Roles.COMB_WORKER],
		"band": 0, "modes": ["maintain", "both"], "find": "find_cell_needing_cleaning",
		"feature": "", "skill": "", "gate_key": "", "config_flag": "", "season": "",
	},
	{
		"id": "comb_evict_cell", "label": "Evict cell stores", "roles": [Roles.COMB_WORKER],
		"band": 1, "modes": ["maintain", "both"], "find": "find_cell_needing_eviction",
		"feature": "", "skill": "", "gate_key": "", "config_flag": "", "season": "",
	},
	{
		"id": "comb_restock", "label": "Restock cell", "roles": [Roles.COMB_WORKER],
		"band": 2, "modes": ["restock", "both"], "find": "find_restock_job",
		"feature": "", "skill": "", "gate_key": "", "config_flag": "", "season": "",
	},
	{
		"id": "comb_build", "label": "Build comb", "roles": [Roles.COMB_WORKER],
		"band": 3, "modes": ["build", "both"], "find": "create_cell_site_at",
		"feature": "", "skill": "", "gate_key": "", "config_flag": "", "season": "",
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
		"feature": "", "skill": "", "gate_key": "", "config_flag": "", "season": "",
	},

	# A honey maker deposits a held load, fans wet honey, then fetches nectar.
	{
		"id": "honey_deposit_load", "label": "Deposit honey", "roles": [Roles.HONEY],
		"band": 0, "modes": [], "find": "find_honey_target",
		"feature": "", "skill": "", "gate_key": "", "config_flag": "", "season": "",
	},
	{
		"id": "honey_fan_cell", "label": "Fan honey", "roles": [Roles.HONEY],
		"band": 1, "modes": [], "find": "find_cell_needing_fanning",
		"feature": "", "skill": "", "gate_key": "", "config_flag": "", "season": "",
	},
	{
		"id": "honey_fetch_nectar", "label": "Fetch nectar", "roles": [Roles.HONEY],
		"band": 2, "modes": [], "find": "find_cell_with",
		"feature": "", "skill": "", "gate_key": "", "config_flag": "", "season": "",
	},

	{
		"id": "queen_lay_egg", "label": "Lay egg", "roles": [Roles.QUEEN],
		"band": 0, "modes": [], "find": "has_room_for_egg",
		"feature": "", "skill": "", "gate_key": "", "config_flag": "", "season": "",
	},
	{
		"id": "forager_seek_flower", "label": "Seek flower", "roles": [Roles.FORAGER],
		"band": 0, "modes": [], "find": "seek_flower",
		"feature": "", "skill": "", "gate_key": "", "config_flag": "", "season": "",
	},
]
