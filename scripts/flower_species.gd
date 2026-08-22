extends RefCounted
## Flower species registry -- Foraging ecology plan, Slice 2.
## The data table and species-picking logic that used to live in
## flower.gd, split out so it can be read by flower.gd, world_building.gd
## and crab_spider.gd without any of them needing to preload flower.gd
## itself (flower.gd preloads crab_spider.gd, so crab_spider.gd reading
## flower.gd back would have closed a compile-time cycle -- see this
## file's history in crab_spider.gd before this slice).
##
## Six species now, so "which flower" is a real decision:
##   Clover -- nectar-rich, pollen-poor, pinky-purple
##   Borage -- pollen-rich, nectar-poor, blue-violet
##   Foxglove -- rich but slow, short mid-summer window
##   Poppy -- pollen only, earliest species out
##   Bramble -- rich in both, long fiddly flower, no crab spiders
##   Dandelion -- common, quick, a classic ambush site
##
## "microhabitat" is a plain descriptive string, not read anywhere yet --
## it names the kind of ground each species belongs on, ready for a later
## slice (patchy/microhabitat-aware meadow generation) to place species
## accordingly instead of scattering all six uniformly.

## Flowering seasons.
##
## Each species is in flower over a window of the year, given as a
## fraction of a season from 0 (first day) to 1 (the last before
## winter). Outside its window a species produces nothing and new ones
## don't seed.
##
## This is the cheapest way to make three systems that already exist
## matter more than they did. Floral constancy becomes a real commitment
## rather than a curiosity, because the species you pinned a forager to
## will run out. Forage start points matter, because the best ground
## moves. And the pollen supply has a genuine gap in it, which is what
## makes storing ahead worth doing.
const SPECIES := [
	{
		# Clover spreads by runners and seeds into dense mats -- real
		# patches are tightly packed, so a small cluster radius.
		"name": "Clover",
		# Spans almost the whole year, which is why it is the backbone of
		# a colony's. Between clover and borage something is always in
		# flower -- simulating the windows found a stretch at the turn of
		# the year with nothing at all out, which would have starved the
		# colony for no reason worth playing.
		"season_start": 0.00, "season_end": 0.85,
		"nectar_capacity": 20.0,
		"pollen_capacity": 10.0,
		"weight": 40.0,
		"cluster_radius": 45.0,
		"cluster_chance": 0.85,
		# Pinky-purple like a real red clover head -- was too close to
		# Dandelion's yellow to tell apart at a glance (Dave, 22 Aug).
		"color": Color(0.82, 0.42, 0.62),
		"centre": Color(0.35, 0.12, 0.24),
		"microhabitat": "grassland",
		# a well-visited, exposed flower whatever its colour -- a
		# different thing from "weight" above, which governs how common
		# the species is
		"crab_spider_weight": 40.0,
	},
	{
		# Borage self-seeds readily and is often grown in blocks -- loose
		# but still clearly patchy.
		"name": "Borage",
		# Comes in late and keeps going, so it carries the pollen supply
		# through the part of the year when clover is finishing.
		"season_start": 0.30, "season_end": 1.00,
		"nectar_capacity": 8.0,
		"pollen_capacity": 22.0,
		"weight": 30.0,
		"cluster_radius": 70.0,
		"cluster_chance": 0.7,
		"color": Color(0.45, 0.4, 0.85),
		"centre": Color(0.15, 0.1, 0.4),
		"microhabitat": "cultivated bed",
		# blue-violet, least typical ambush colour, but not zero -- real
		# crab spiders do occasionally turn up somewhere surprising
		"crab_spider_weight": 5.0,
	},
	{
		# rich but slow: rewards spreading out rather than camping a patch
		# Biennial, colonises disturbed ground at wood edges -- loose,
		# scattered stands rather than a tidy patch.
		"name": "Foxglove",
		# A short mid-summer window. Rich while it lasts, and worth
		# reorganising around, which is the point of having it.
		"season_start": 0.40, "season_end": 0.65,
		"nectar_capacity": 34.0,
		"pollen_capacity": 6.0,
		"recharge_scale": 0.4,
		"weight": 8.0,
		"cluster_radius": 110.0,
		"cluster_chance": 0.55,
		"color": Color(0.78, 0.35, 0.6),
		"centre": Color(0.42, 0.12, 0.3),
		"microhabitat": "wood edge",
		# pink/magenta, a less typical ambush colour
		"crab_spider_weight": 10.0,
	},
	{
		# no nectar at all, so pollen foraging becomes a spatial decision
		# Annual of disturbed/arable ground, wind-scattered seed -- the
		# least clustered species, closer to individual plants than a
		# patch.
		"name": "Poppy",
		# Early, and the only pollen worth having before the borage
		# arrives -- so the start of a run has a real constraint.
		"season_start": 0.00, "season_end": 0.45,
		"nectar_capacity": 0.0,
		"pollen_capacity": 30.0,
		"recharge_scale": 1.0,
		"weight": 22.0,
		"cluster_radius": 140.0,
		"cluster_chance": 0.3,
		"color": Color(0.85, 0.22, 0.18),
		"centre": Color(0.15, 0.12, 0.1),
		"microhabitat": "arable margin",
		# red, but wide open and much-visited, so not a negligible risk
		"crab_spider_weight": 25.0,
	},
	{
		# Grows in dense tangled hedgerow thickets -- a tight cluster,
		# not scattered plants.
		"name": "Bramble",
		# Comes in as foxglove is finishing and carries on into early
		# autumn, overlapping the back half of borage.
		"season_start": 0.45, "season_end": 0.90,
		"nectar_capacity": 18.0,
		"pollen_capacity": 16.0,
		# A bramble flower has a fiddly ring of stamens to work over,
		# not a simple open cup -- slower to handle than most.
		"handling_time_scale": 1.4,
		# Rich, but slow to build that richness back up -- same shape as
		# Foxglove's slow recharge below, just less extreme.
		"recharge_scale": 0.7,
		"weight": 18.0,
		"cluster_radius": 55.0,
		"cluster_chance": 0.75,
		"color": Color(0.95, 0.93, 0.9),
		"centre": Color(0.85, 0.8, 0.4),
		"microhabitat": "hedgerow thicket",
		# Drawn as several individual blooms over one shared bush backdrop
		# -- see flower.gd's setup(). Each bloom is still its own Flower
		# node with its own feeding slot; only the background is shared.
		"bushy": true,
		# world_building.gd::_seed_flower plants this many flower units
		# together, tightly jittered around one anchor point, whenever a
		# Bramble bush seeds -- a real bramble thicket is several blooms
		# at once, not a lone flower that might get a same-species
		# neighbour later if the random re-seeding happens to land close.
		"bush_min_units": 2, "bush_max_units": 4,
		# Thorny, tangled growth gives a crab spider nowhere flat and
		# exposed to sit and wait -- doesn't happen here.
		"crab_spider_weight": 0.0,
	},
	{
		# Individual plants popping up across open ground rather than a
		# tight patch -- loosely scattered.
		"name": "Dandelion",
		# The earliest flush of the year, overlapping poppy's window
		# but a different niche (open ground, not arable margins).
		"season_start": 0.00, "season_end": 0.35,
		"nectar_capacity": 6.0,
		"pollen_capacity": 8.0,
		# A flat, open flower -- quick to land on and quick to leave.
		"handling_time_scale": 0.6,
		# Low-value and quick to top back up, matching the quick handling
		# above -- a Dandelion never keeps a forager waiting long.
		"recharge_scale": 1.4,
		"weight": 35.0,
		"cluster_radius": 90.0,
		"cluster_chance": 0.35,
		"color": Color(1.0, 0.82, 0.05),
		"centre": Color(0.6, 0.45, 0.05),
		"microhabitat": "open ground",
		# Flat, bright yellow and wide open -- about as classic an
		# ambush site as exists in the meadow.
		"crab_spider_weight": 35.0,
	},
]

## Picks a species by rarity weight. Clover is common, foxglove scarce.
static func pick_species_index() -> int:
	var total := 0.0
	for s in SPECIES:
		total += s.get("weight", 1.0)
	var roll := randf() * total
	for i in range(SPECIES.size()):
		roll -= SPECIES[i].get("weight", 1.0)
		if roll <= 0.0:
			return i
	return 0

## Picks this run's crab-spider target species, weighted by
## crab_spider_weight -- same shape as pick_species_index above, which
## weights by rarity instead.
static func roll_preferred_species() -> String:
	var total := 0.0
	for s in SPECIES:
		total += s.get("crab_spider_weight", 1.0)
	var roll := randf() * total
	for s in SPECIES:
		roll -= s.get("crab_spider_weight", 1.0)
		if roll <= 0.0:
			return s.name
	return SPECIES[0].name
