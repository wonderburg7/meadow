extends RefCounted
## The one place a harvested/stored resource kind is described.
##
## Usage: const Resources = preload("res://scripts/resources.gd")
##        Resources.label_for(Resources.NECTAR)
##
## Scope (Slice 3 of CHATGPT_EFFICIENCY_IMPLEMENTATION_PLAN.md; extended by
## B1 of architecture-review.md's F2): `keys()` still returns only nectar
## and pollen, the two resources a forager chooses between --
## `roles.gd::count_keys` iterates it to build forager tally keys, and a
## third entry there would invent a tally key no bee can have. `RESOURCES`
## itself, and `content_keys()`, now cover every cell-content kind (honey,
## jelly, brood, corpse and the empty kind too), matching the buckets
## `hive.gd::_content_index` builds. Nothing outside this file reads those
## added rows yet -- see B1's own slice heading -- and the existing per-
## kind logic in `hive_cell.gd`/`hive.gd`/`flower.gd` still owns its own
## typed fields and, in a couple of places, its own colour; consolidating
## those onto this catalogue is a later slice (B2 onwards), not this one.

const NECTAR := "nectar"
const POLLEN := "pollen"
const HONEY := "honey"
const JELLY := "jelly"
const BROOD := "brood"
const CORPSE := "corpse"
const EMPTY := ""

const RESOURCES := [
	{
		"key": NECTAR, "label": "Nectar", "colour": Color(0.95, 0.72, 0.20),
		# Colony energy: bees eat it directly and building comb burns it.
		"is_energy": true,
		# Nectar's energy factor isn't config-driven -- take_energy() takes
		# it 1-for-1 with no multiplier, unlike honey below.
		"energy_factor": 1.0,
		# take_energy() draws honey (priority 0) before nectar (priority 1).
		"energy_priority": 1,
		# Empty means hive_cell.gd::capacity_for()'s default, GameConfig.cell_capacity.
		"capacity_config": "",
		"index_bucket": NECTAR,
		"storable": true,
		"designatable": true,
		"evictable": true,
		"config_flag": "",
		# Persisted today via hive.gd/flower.gd/bee.gd's own typed fields
		# (see save_game.gd), not through this catalogue -- recorded here
		# so a future save-migration slice has one place to read the
		# resource list from rather than re-deriving it.
		"save_policy": "persisted_via_owner_fields",
	},
	{
		"key": POLLEN, "label": "Pollen", "colour": Color(0.55, 0.48, 0.90),
		# What the queen eats to lay eggs; not itself colony energy.
		"is_energy": false,
		"energy_factor": 0.0,
		"capacity_config": "",
		"index_bucket": POLLEN,
		"storable": true,
		"designatable": true,
		"evictable": true,
		"config_flag": "",
		"save_policy": "persisted_via_owner_fields",
	},
	{
		"key": HONEY, "label": "Honey", "colour": Color(0.85, 0.42, 0.05),
		# Colony energy, and take_energy() draws it before nectar.
		"is_energy": true,
		# A GameConfig field name, not a literal, because it's a live
		# tunable (settings_catalogue.gd) -- unlike nectar's fixed 1.0.
		"energy_factor": "honey_energy_factor",
		"energy_priority": 0,
		"capacity_config": "honey_cell_capacity",
		"index_bucket": HONEY,
		"storable": true,
		"designatable": true,
		"evictable": true,
		"config_flag": "",
		"save_policy": "persisted_via_owner_fields",
	},
	{
		"key": JELLY, "label": "Jelly", "colour": Color(0.97, 0.94, 0.82),
		# What nurses feed gyne larvae, not colony energy.
		"is_energy": false,
		"energy_factor": 0.0,
		"capacity_config": "jelly_cell_capacity",
		"index_bucket": JELLY,
		"storable": true,
		"designatable": true,
		"evictable": true,
		"config_flag": "",
		"save_policy": "persisted_via_owner_fields",
	},
	{
		"key": BROOD, "label": "Brood", "colour": Color(0.9, 0.9, 0.85),
		# A developing bee, not a stored resource -- add_resource()/
		# take_resource() never move it and it never needs eviction.
		"is_energy": false,
		"energy_factor": 0.0,
		"capacity_config": "",
		"index_bucket": BROOD,
		"storable": false,
		"designatable": true,
		"evictable": false,
		"config_flag": "",
		"save_policy": "persisted_via_owner_fields",
	},
	{
		"key": CORPSE, "label": "Corpse", "colour": Color(0.34, 0.30, 0.30),
		# A body to be cleared, not stored or reserved for.
		"is_energy": false,
		"energy_factor": 0.0,
		"capacity_config": "",
		"index_bucket": CORPSE,
		"storable": false,
		"designatable": false,
		"evictable": false,
		"config_flag": "",
		"save_policy": "persisted_via_owner_fields",
	},
	{
		"key": EMPTY, "label": "Empty", "colour": Color(0.85, 0.78, 0.55),
		# The absence of content, not a resource a bee ever carries.
		"is_energy": false,
		"energy_factor": 0.0,
		"capacity_config": "",
		"index_bucket": EMPTY,
		"storable": false,
		"designatable": false,
		"evictable": false,
		"config_flag": "",
		"save_policy": "persisted_via_owner_fields",
	},
]

# --- lookups ------------------------------------------------------

# Built once on first lookup and reused for the process lifetime --
# entry() is called from hive_cell.gd::capacity_for(), which is hot.
static var _by_key: Dictionary = {}

static func entry(key: String) -> Dictionary:
	if _by_key.is_empty():
		for resource in RESOURCES:
			_by_key[resource.key] = resource
	return _by_key.get(key, {})

static func is_valid(key: String) -> bool:
	return not entry(key).is_empty()

static func label_for(key: String) -> String:
	return entry(key).get("label", key)

static func colour_for(key: String) -> Color:
	return entry(key).get("colour", Color.WHITE)

static func is_energy(key: String) -> bool:
	return entry(key).get("is_energy", false)

## The energy kinds (honey, nectar) in the order take_energy() should
## draw them, cheapest colony cost first -- honey before nectar.
static func energy_keys_by_priority() -> Array:
	var energy_resources: Array = RESOURCES.filter(func(r): return r.is_energy)
	energy_resources.sort_custom(func(a, b): return a.energy_priority < b.energy_priority)
	return energy_resources.map(func(r): return r.key)

## Resolves an entry's `energy_factor`, which is either a literal float
## (nectar's fixed 1.0) or a GameConfig field name (honey's live tunable).
static func energy_factor_for(key: String) -> float:
	var factor = entry(key).get("energy_factor", 0.0)
	if factor is String:
		return GameConfig.get(factor) if factor != "" else 0.0
	return factor

## The two forager-selectable resources only, in the fixed order they
## should be offered/shown. `roles.gd::count_keys` iterates this to build
## forager tally keys, so it must never grow to include the other cell-
## content kinds below -- use `content_keys()` for the full list.
static func keys() -> Array:
	return [NECTAR, POLLEN]

## Every cell-content kind: the two forager-selectable resources plus
## honey, jelly, brood, corpse and the empty kind.
static func content_keys() -> Array:
	return RESOURCES.map(func(r): return r.key)
