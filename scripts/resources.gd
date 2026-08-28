extends RefCounted
## The one place a harvested/stored resource kind is described.
##
## Usage: const Resources = preload("res://scripts/resources.gd")
##        Resources.label_for(Resources.NECTAR)
##
## Scope (Slice 3 of CHATGPT_EFFICIENCY_IMPLEMENTATION_PLAN.md): the
## vertical path this catalogue backs is forager mode -- nectar and
## pollen are the two resources a forager chooses between, and this file
## is the shared identity/colour/energy-semantics authority for that
## choice. Nectar/pollen also appear as flower yields, hive stock and
## cell content elsewhere (flower.gd, hive.gd, hive_cell.gd, bee.gd) with
## their own typed fields and, in a couple of places, their own colour --
## consolidating those is out of scope here; see the audit's P0 resources
## finding for the fuller inventory.

const NECTAR := "nectar"
const POLLEN := "pollen"

const RESOURCES := [
	{
		"key": NECTAR, "label": "Nectar", "colour": Color(0.95, 0.72, 0.20),
		# Colony energy: bees eat it directly and building comb burns it.
		"is_energy": true,
		# Persisted today via hive.gd/flower.gd/bee.gd's own typed fields
		# (see save_game.gd), not through this catalogue -- recorded here
		# so a future save-migration slice has one place to read the
		# resource list from rather than re-deriving it.
		"save_policy": "persisted_via_owner_fields",
		"config_flag": "",
	},
	{
		"key": POLLEN, "label": "Pollen", "colour": Color(0.55, 0.48, 0.90),
		# What the queen eats to lay eggs; not itself colony energy.
		"is_energy": false,
		"save_policy": "persisted_via_owner_fields",
		"config_flag": "",
	},
]

# --- lookups ------------------------------------------------------

static func entry(key: String) -> Dictionary:
	for resource in RESOURCES:
		if resource.key == key:
			return resource
	return {}

static func is_valid(key: String) -> bool:
	return not entry(key).is_empty()

static func label_for(key: String) -> String:
	return entry(key).get("label", key)

static func colour_for(key: String) -> Color:
	return entry(key).get("colour", Color.WHITE)

static func is_energy(key: String) -> bool:
	return entry(key).get("is_energy", false)

## Every resource key, in the fixed order they should be offered/shown.
static func keys() -> Array:
	return RESOURCES.map(func(r): return r.key)
