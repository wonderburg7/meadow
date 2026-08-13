extends RefCounted
## The one place a role is described.
##
## Usage: const Roles = preload("res://scripts/roles.gd")
##        Roles.label_for(Roles.FORAGER)
##
## Before this file, every role's id, name, colour, letter and list of
## sub-modes was written out separately in bee.gd, hud.gd,
## colony_panel.gd and nursery_panel.gd, each with a comment saying it
## mirrored the others. Four places to remember when adding a role, and
## nothing to catch you if you forgot one -- the colony window would
## simply not count the new bees, silently.
##
## Everything about a role now lives here and every other file reads it.
## Adding a role means adding one entry below.

# --- role ids -----------------------------------------------------
## These match Bee.Role exactly and must stay in that order. Kept as
## plain constants so files that only need to name a role (the panels)
## don't have to preload bee.gd, which pulls in the whole state machine.
const FORAGER := 0
const NURSE := 1
const COMB_WORKER := 2
const QUEEN := 3
const IDLE := 4
const MINER := 5
const HONEY := 6

## Colours are shared between the bee bodies, the nursery ring plot, the
## zone glow on the comb and the comb overlays, so a role looks the same
## everywhere it appears.
const ROLES := [
	{
		"id": FORAGER, "key": "forager", "label": "Forager", "letter": "F",
		"colour": Color(0.95, 0.72, 0.20),
		"tip": "Sends bees out to the meadow to gather nectar or pollen and carry it back into the comb.\n\nNectar is the colony's energy -- bees eat it, and building comb burns it. Pollen is what the queen eats to lay eggs, so no pollen means no new bees.",
		"modes": [
			{"key": "nectar", "label": "Nectar", "tip": "Look for nectar. This is the colony's energy: bees eat it, and building comb burns it."},
			{"key": "pollen", "label": "Pollen", "tip": "Look for pollen. This is what the queen eats to lay eggs, so no pollen means no new bees."},
		],
	},
	{
		"id": NURSE, "key": "nurse", "label": "Nurse", "letter": "U",
		"colour": Color(0.40, 0.80, 0.95),
		"tip": "Keeps bees indoors feeding the brood.\n\nLarvae do not develop on their own: a nurse collects pollen and either nectar or honey from the comb, carries it to the cell, and each feed buys the larva a short stretch of growth before it stalls again. Honey feeds last longer. With no nurse, the colony cannot grow.",
		"modes": [
			{"key": "feed", "label": "Feeding", "tip": "Carry pollen and nectar or honey to the larvae. Without this nothing in the comb develops at all."},
			{"key": "jelly", "label": "Making jelly", "tip": "Eat pollen and honey and work them into royal jelly, which is the one thing a gyne larva cannot be raised without. Dead weight for a colony not raising any."},
			{"key": "both", "label": "Anything", "tip": "Take whichever of the two comes up, feeding first."},
		],
	},
	{
		"id": COMB_WORKER, "key": "comb_worker", "label": "Comb worker", "letter": "C",
		"colour": Color(0.55, 0.85, 0.45),
		"tip": "Looks after the comb itself: drawing new cells, clearing blocked ones, and moving stores between them.\n\nBuilding burns extra energy, because bees make wax from the sugar they have eaten.",
		"modes": [
			{"key": "build", "label": "Building", "tip": "Draw new comb. Pick the tiles yourself with \"Build here\", or leave it to work outward on its own."},
			{"key": "maintain", "label": "Clearing", "tip": "Clear dead larvae out of blocked cells and shift stores out of any cell you have re-designated or asked to be emptied. A body blocks a cell completely, so this is urgent work."},
			{"key": "restock", "label": "Stocking", "tip": "Keep chosen cells full of one resource, fetching it from elsewhere in the comb. This is how you get a resource to sit somewhere in particular -- honey beside the brood before winter -- rather than wherever the foragers happened to drop it."},
			{"key": "both", "label": "Anything", "tip": "Take whichever job comes up, clearing first, then stocking, then building."},
		],
	},
	{
		"id": QUEEN, "key": "laying", "label": "Laying", "letter": "Q",
		"colour": Color(1.0, 0.85, 0.55),
		"tip": "Queen only. She eats pollen from the comb until she has enough for an egg, then walks to a free cell and lays into it.\n\nWhenever laying is blocked -- no pollen, or no free cell -- she falls back to her second job, which is nursing unless you change it. Other bees ignore this.",
		"modes": [],
	},
	{
		"id": IDLE, "key": "idle", "label": "Idle", "letter": "-",
		"colour": Color(0.60, 0.60, 0.62),
		"tip": "Stops bees doing anything on their own.\n\nThey stay where they are and keep burning energy, but you can still move them with right-click. Useful for holding bees back or parking one somewhere.",
		"modes": [],
	},
	{
		"id": MINER, "key": "miner", "label": "Miner", "letter": "M",
		"colour": Color(0.80, 0.55, 0.35),
		"tip": "Digs out soil blocks to make room for more comb.\n\nOne miner takes about two minutes per block; several digging the same block share the work. A miner fills up with spoil as it digs and has to carry it outside before it can carry on.",
		"modes": [
			{"key": "automine", "label": "Dig on its own", "tip": "Pick the nearest exposed soil block and start digging without waiting to be told, so the hive opens up around itself. Blocks you have marked yourself still come first."},
		],
	},
	{
		"id": HONEY, "key": "honey", "label": "Honey", "letter": "H",
		"colour": Color(0.95, 0.45, 0.25),
		"tip": "Turns stored nectar into honey.\n\nA honey bee takes nectar back out of the comb, chews enzymes into it, spits the mix into a cell of its own and then fans its wings over that cell until the water has evaporated off. Only then is it honey -- which is four times as energy-dense as the nectar it came from, keeps far better, and lets nurses raise larvae faster.",
		"modes": [],
	},
]

## Foragers are split by what they are collecting wherever bees are
## counted, because "twenty foragers" tells you much less than "sixteen
## on nectar, four on pollen". These are the extra keys that creates.
const FORAGER_FOCUS_COLOURS := {
	"nectar": Color(0.95, 0.72, 0.20),
	"pollen": Color(0.55, 0.48, 0.90),
}

# --- lookups ------------------------------------------------------

static func entry(role_id: int) -> Dictionary:
	for role in ROLES:
		if role.id == role_id:
			return role
	return ROLES[IDLE]

static func label_for(role_id: int) -> String:
	return entry(role_id).label

static func letter_for(role_id: int) -> String:
	return entry(role_id).letter

static func tip_for(role_id: int) -> String:
	return entry(role_id).tip

static func colour_for(role_id: int, focus: String = "") -> Color:
	if role_id == FORAGER and FORAGER_FOCUS_COLOURS.has(focus):
		return FORAGER_FOCUS_COLOURS[focus]
	return entry(role_id).colour

static func modes_for(role_id: int) -> Array:
	return entry(role_id).modes

## The label of one sub-mode, for readouts.
static func mode_label(role_id: int, mode_key: String) -> String:
	for mode in modes_for(role_id):
		if mode.key == mode_key:
			return mode.label
	return mode_key

static func mode_tip(role_id: int, mode_key: String) -> String:
	for mode in modes_for(role_id):
		if mode.key == mode_key:
			return mode.tip
	return ""

## The string key main.gd matches on when a role is requested, and back.
static func key_for(role_id: int) -> String:
	return entry(role_id).key

static func id_for_key(key: String) -> int:
	for role in ROLES:
		if role.key == key:
			return role.id
	return -1

# --- counting keys ------------------------------------------------
## Everywhere bees are tallied uses the same key, so the colony window,
## the nursery ring and the corner readouts can never disagree about
## what counts as what. Foragers carry their focus; nobody else does.

static func count_key(role_id: int, focus: String = "") -> String:
	if role_id == FORAGER:
		return "%d|%s" % [role_id, focus]
	return "%d|" % role_id

## Every key that can appear in a tally, in the order they should be
## shown. Fixed order so readouts don't reshuffle as counts change.
static func count_keys() -> Array:
	var keys: Array = []
	for role in ROLES:
		if role.id == FORAGER:
			for focus in ["nectar", "pollen"]:
				keys.append(count_key(FORAGER, focus))
		else:
			keys.append(count_key(role.id))
	return keys

static func label_for_key(key: String) -> String:
	var parts: PackedStringArray = key.split("|")
	if parts.size() < 2:
		return key
	var role_id: int = int(parts[0])
	if role_id == FORAGER and parts[1] != "":
		return "Foragers — %s" % parts[1]
	return _plural(label_for(role_id))

static func colour_for_key(key: String) -> Color:
	var parts: PackedStringArray = key.split("|")
	if parts.size() < 2:
		return Color.WHITE
	return colour_for(int(parts[0]), parts[1])

## Tally rows are plural; the role's own name is singular. Only a couple
## of them need anything cleverer than an "s".
static func _plural(label: String) -> String:
	match label:
		"Laying", "Honey", "Idle":
			return label
		_:
			return label + "s"
