extends CanvasLayer
## The settings window: every tuning control, collapsed behind a cog
## icon in the top-right corner. Was a text button reading "Tuning" --
## renamed and re-iconed 14 Aug 2026, but the file itself keeps its old
## name (debug_panel.gd) since nothing outside this file references the
## class, only the scene tree node it adds itself as.
## Editing a value doesn't change bees/flowers already in the world --
## press "Restart Run" to respawn everything with the new numbers
## (they live in the GameConfig autoload, so they survive the reload).
##
## The settings are grouped into collapsible sections, because the flat
## list had grown long enough that finding anything meant scrolling past
## everything. Every section starts closed, so opening the panel shows a
## short menu rather than a wall of numbers.
##
## Every row carries an "i" badge explaining what the number actually
## does, so you can tune without holding the whole model in your head.
## Those badges can be switched off once you know your way around -- see
## the Interface section.

const UI = preload("res://scripts/ui.gd")
const SaveGame = preload("res://scripts/save_game.gd")

## Section order here is the order they appear in the panel.
const CATEGORIES := [
	"World & start",
	"Flowers",
	"Foraging",
	"Hive & comb",
	"Brood & the queen",
	"Honey",
	"Gynes & royal jelly",
	"Weather",
	"Seasons & health",
	"Winter",
	"The rival colony",
	"Predators",
	"Mining",
	"Bee life",
	"Interface",
]

const TUNABLES := [
	# --- World & start ---
	{
		"key": "hive_cell_count", "label": "Starting cells", "step": 1.0, "min": 1.0,
		"category": "World & start",
		"tip": "How many finished comb cells the hive begins with. Builders add more on top of these.",
	},
	{
		"key": "starting_bees", "label": "Starting foragers", "step": 1.0, "min": 1.0,
		"category": "World & start",
		"tip": "How many foragers exist at the start of a run.",
	},
	{
		"key": "starting_nurses", "label": "Starting nurses", "step": 1.0, "min": 0.0,
		"category": "World & start",
		"tip": "Nurses feed developing larvae. Brood does not develop at all without one, so a colony with no nurse never grows.",
	},
	{
		"key": "starting_builders", "label": "Starting builders", "step": 1.0, "min": 0.0,
		"category": "World & start",
		"tip": "Builders draw new comb and shift stores between cells. With none, the hive can only expand once you assign a bee to build.",
	},
	{
		"key": "starting_honey_makers", "label": "Starting honey makers", "step": 1.0, "min": 0.0,
		"category": "World & start",
		"tip": "Honey makers turn stored nectar into honey. None to begin with by default -- a young colony needs the nectar as it is.",
	},
	{
		"key": "seconds_per_day", "label": "Seconds per day", "step": 30.0, "min": 10.0,
		"category": "World & start",
		"tip": "Real seconds in one in-game day. This drives the day counter and how quickly bees age towards their lifespan.",
	},
	{
		"key": "pollen_warning_first_day", "label": "Pollen warning from day", "step": 1.0, "min": 1.0,
		"category": "World & start",
		"tip": "The \"almost no pollen\" line is kept off the problem strip until this day. A colony this young genuinely has no pollen and there is nothing useful to do about it, so warning from the first minute only teaches you to ignore the strip.",
	},

	# --- Flowers ---
	{
		"key": "flower_count", "label": "Flowers", "step": 1.0, "min": 1.0,
		"category": "Flowers",
		"tip": "How many flowers are scattered across the meadow. More flowers means less competition and shorter trips.",
	},
	{
		"key": "nectar_recharge_rate", "label": "Nectar rchg/s", "step": 0.1, "min": 0.0,
		"category": "Flowers",
		"tip": "How fast a drained flower refills its nectar, per second. Lower values make bees range further from the hive.",
	},
	{
		"key": "pollen_recharge_rate", "label": "Pollen rchg/s", "step": 0.05, "min": 0.0,
		"category": "Flowers",
		"tip": "How fast a drained flower refills its pollen, per second. Deliberately slower than nectar, so pollen is the scarcer resource.",
	},
	{
		"key": "tarsal_markers_on", "label": "Tarsal markers", "toggle": true,
		"category": "Flowers",
		"tip": "Bees leave a scent mark from their feet on every flower they land on. With this on, other bees avoid a flower marked in the last few seconds, so the colony spreads out instead of crowding the same patch. Real bumblebees and honeybees both do this.",
	},
	{
		"key": "tarsal_marker_seconds", "label": "Marker lasts s", "step": 5.0, "min": 1.0,
		"category": "Flowers",
		"tip": "How long a scent mark keeps other bees away. Only matters when Tarsal markers is on.",
	},
	{
		"key": "orientation_flight_on", "label": "Orientation flight", "toggle": true,
		"category": "Flowers",
		"tip": "A new forager makes a short flight to a random spot near the hive before her first trip, and keeps working that spot from then on, rather than beelining for whatever's nearest the door -- real bees do this too, learning the area before they start foraging properly. Off by default. Turning on Auto scouting turns this on too.",
	},
	{
		"key": "scouting_on", "label": "Auto scouting", "toggle": true,
		"category": "Flowers",
		"tip": "A new forager tries a few start points near the hive (see Orientation flight) and settles on whichever collected best, instead of just keeping the first one. Off by default. Turning on Floral constancy or Auto-recruitment turns this on too, since both rely on a forager having actually scouted. Turning this off also turns off Floral constancy and Auto-recruitment.",
	},
	{
		"key": "floral_constancy_on", "label": "Floral constancy", "toggle": true,
		"category": "Flowers",
		"tip": "Lets you pin a forager to one flower species via 'Set preference' in its selection panel -- it will only ever visit that species from then on. Also makes Auto scouting sample a different species each bout, so a scouted forager settles on the best start point AND species together, not just the best spot. Off by default; existing preferences are kept even if you turn this off, they just stop being offered as a new option. Turning this on also turns Auto scouting on.",
	},
	{
		"key": "auto_recruitment_on", "label": "Auto-recruitment", "toggle": true,
		"category": "Flowers",
		"tip": "Foragers compare notes at the hive entrance -- a good performer can pass its start point (and species, if Floral constancy is also on) to a struggling one of the same resource type. Off by default; off means no bee ever waits at the door. Turning this on also turns Auto scouting on.",
	},
	{
		"key": "forage_start_radius", "label": "Start point radius", "step": 20.0, "min": 20.0,
		"category": "Flowers",
		"tip": "How far from the hive a new forager's start point (Orientation flight or Auto scouting) is scattered -- how spread apart different foragers' patches are. Not how far a forager will fly to find a flower once she's working an area (that's forage_search_radius, tuned separately and much larger). Only matters when Orientation flight or Auto scouting is on.",
	},
	{
		"key": "recruit_lower_threshold_nectar", "label": "Recruit: seek below (nectar)", "step": 0.1, "min": 0.0,
		"category": "Flowers",
		"tip": "A nectar forager collecting less than this (units/second) waits at the entrance hoping a better-performing forager tells it where to go. Only matters when Auto-recruitment is on.",
	},
	{
		"key": "recruit_upper_threshold_nectar", "label": "Recruit: offer above (nectar)", "step": 0.1, "min": 0.0,
		"category": "Flowers",
		"tip": "A nectar forager collecting more than this (units/second) waits at the entrance, willing to pass on its start point. Only matters when Auto-recruitment is on.",
	},
	{
		"key": "recruit_lower_threshold_pollen", "label": "Recruit: seek below (pollen)", "step": 0.1, "min": 0.0,
		"category": "Flowers",
		"tip": "Same as the nectar version, for pollen foragers. Pollen's base collection rate is lower than nectar's, so this needs its own number rather than sharing the nectar threshold. Only matters when Auto-recruitment is on.",
	},
	{
		"key": "recruit_upper_threshold_pollen", "label": "Recruit: offer above (pollen)", "step": 0.1, "min": 0.0,
		"category": "Flowers",
		"tip": "Same as the nectar version, for pollen foragers. Only matters when Auto-recruitment is on.",
	},
	{
		"key": "recruit_wait_seconds", "label": "Recruit wait s", "step": 1.0, "min": 1.0,
		"category": "Flowers",
		"tip": "How long a forager waits at the entrance for a match before giving up and heading out on its own. Only matters when Auto-recruitment is on.",
	},
	{
		"key": "recruit_start_point_jitter", "label": "Recruit start point spread", "step": 10.0, "min": 0.0,
		"category": "Flowers",
		"tip": "A recruited forager's inherited start point is nudged this far from her mentor's exact one, in a random direction -- still the same general proven area, but not the same handful of flowers. At 0, she starts from exactly the mentor's point, which measurably cost the mentor her own rate in testing (both bees converging on one patch). Only matters when Auto-recruitment is on.",
	},
	{
		"key": "recruit_grace_trips", "label": "Recruit grace trips", "step": 1.0, "min": 0.0,
		"category": "Flowers",
		"tip": "How many trips a forager must complete before it's judged against the thresholds above. Only matters when Auto-recruitment is on.",
	},
	{
		"key": "show_flower_amounts", "label": "Show flower amounts", "toggle": true,
		"category": "Flowers",
		"tip": "Show the nectar and pollen numbers under every flower. Off by default -- 500 flowers' worth of numbers gets noisy fast, and clicking a flower shows the same numbers on demand. Applies within about a second, as flowers redraw themselves.",
	},

	# --- Foraging ---
	{
		"key": "bee_speed", "label": "Bee speed", "step": 10.0, "min": 10.0,
		"category": "Foraging",
		"tip": "Flight and walking speed in pixels per second. The queen moves at a fraction of this (see Queen speed).",
	},
	{
		"key": "flower_handling_time", "label": "Handling s", "step": 0.5, "min": 0.0,
		"category": "Foraging",
		"tip": "Seconds a bee spends on a flower before it starts gathering, representing finding its way to the nectary.",
	},
	{
		"key": "nectar_collection_rate", "label": "Nectar rate/s", "step": 0.5, "min": 0.1,
		"category": "Foraging",
		"tip": "Nectar gathered per second once handling is finished. The flower's readout drains at this rate while you watch.",
	},
	{
		"key": "pollen_collection_rate", "label": "Pollen rate/s", "step": 0.5, "min": 0.1,
		"category": "Foraging",
		"tip": "Pollen gathered per second once handling is finished.",
	},
	{
		"key": "deposit_time", "label": "Deposit s", "step": 0.5, "min": 0.0,
		"category": "Foraging",
		"tip": "Seconds a forager spends emptying itself into a comb cell, once it has walked to that cell.",
	},
	{
		"key": "nectar_stomach_capacity", "label": "Nectar stomach", "step": 5.0, "min": 1.0,
		"category": "Foraging",
		"tip": "How much nectar a forager can carry before it must return to the hive.",
	},
	{
		"key": "pollen_stomach_capacity", "label": "Pollen stomach", "step": 5.0, "min": 1.0,
		"category": "Foraging",
		"tip": "How much pollen a forager can carry. Smaller than the nectar stomach, so pollen trips deliver less.",
	},
	{
		"key": "show_forager_labels", "label": "Show forager labels", "toggle": true,
		"category": "Foraging",
		"tip": "Show the small ID-and-letter label that floats above each forager. Off gives a cleaner view of a big crowd of them out in the meadow -- the small dot on each one (yellow for pollen, blue for nectar) still says what it's collecting. Takes effect on the bees currently on screen straight away.",
	},

	# --- Hive & comb ---
	{
		"key": "cell_capacity", "label": "Cell capacity", "step": 10.0, "min": 1.0,
		"category": "Hive & comb",
		"tip": "How much of one resource a single comb cell holds. A cell stores nectar, or pollen, or honey, or one developing bee -- never a mix.",
	},
	{
		"key": "cell_build_time", "label": "Cell build s", "step": 10.0, "min": 5.0,
		"category": "Hive & comb",
		"tip": "Builder-seconds needed to finish one cell. Two builders on the same cell halve the wall-clock time, three third it, and so on.",
	},
	{
		"key": "build_energy_burn", "label": "Build energy/s", "step": 0.1, "min": 0.0,
		"category": "Hive & comb",
		"tip": "Extra energy a builder burns while building. Bees make wax from the sugar they have eaten, so comb is paid for in nectar rather than a separate wax store.",
	},
	{
		"key": "hive_interior_rings", "label": "Interior rings", "step": 1.0, "min": 2.0,
		"category": "Hive & comb",
		"tip": "How many rings of open floor the hive has before the soil wall starts. This is the space comb can grow into. Takes effect on Restart Run.",
	},
	{
		"key": "hive_soil_depth", "label": "Soil depth", "step": 1.0, "min": 1.0,
		"category": "Hive & comb",
		"tip": "How far the diggable soil extends beyond the hollow. Deeper means more room to mine into later. Takes effect on Restart Run.",
	},
	{
		"key": "hive_rock_rings", "label": "Bedrock rings", "step": 1.0, "min": 1.0,
		"category": "Hive & comb",
		"tip": "Rings of solid rock wrapped round the outside of the soil. Rock cannot be marked, mined or walked through, so this is the hard outer limit of how far the colony can ever spread. Takes effect on Restart Run.",
	},
	{
		"key": "cell_slow_factor", "label": "Comb speed x", "step": 0.05, "min": 0.1,
		"category": "Hive & comb",
		"tip": "How much slower a bee moves while crossing comb rather than open floor. 1 means no penalty.",
	},
	{
		"key": "hive_cell_spacing", "label": "Cell spacing", "step": 1.0, "min": 4.0,
		"category": "Hive & comb",
		"tip": "Distance between neighbouring cell centres. Takes effect on the next Restart Run.",
	},
	{
		"key": "hive_cell_size", "label": "Cell size", "step": 1.0, "min": 3.0,
		"category": "Hive & comb",
		"tip": "How large each hexagon is drawn. Keep this a little below Cell spacing or cells will overlap.",
	},
	{
		"key": "show_cell_contents_text", "label": "Show cell contents text", "toggle": true,
		"category": "Hive & comb",
		"tip": "Show the small text on each comb cell -- N40, an egg's development percent, and so on. Off keeps the colour coding but drops the numbers, for a quieter comb at a glance. Applies within about a second, as cells redraw themselves.",
	},

	# --- Brood & the queen ---
	{
		"key": "egg_pollen_cost", "label": "Pollen per egg", "step": 5.0, "min": 1.0,
		"category": "Brood & the queen",
		"tip": "Pollen the queen must eat before she can lay one egg. This is the link between foraging and colony growth.",
	},
	{
		"key": "queen_eat_rate", "label": "Queen eat/s", "step": 1.0, "min": 0.1,
		"category": "Brood & the queen",
		"tip": "Pollen the queen consumes per second while feeding from a cell.",
	},
	{
		"key": "queen_speed_factor", "label": "Queen speed x", "step": 0.05, "min": 0.05,
		"category": "Brood & the queen",
		"tip": "The queen's speed as a multiple of a worker's. She is larger, so she is slower.",
	},
	{
		"key": "lay_weight_low", "label": "Lay weight — low", "step": 1.0, "min": 0.0,
		"category": "Brood & the queen",
		"tip": "How much of the queen's laying a low-priority nursery cell gets, relative to the other two tiers. The three weights are a ratio, not percentages: 1 : 2 : 3 means a high cell receives three eggs for every one a low cell receives. Set a weight to zero to stop that tier being laid in at all.",
	},
	{
		"key": "lay_weight_medium", "label": "Lay weight — medium", "step": 1.0, "min": 0.0,
		"category": "Brood & the queen",
		"tip": "The middle tier's share of the queen's laying. This is the default a cell gets when you first put it in the nursery zone.",
	},
	{
		"key": "lay_weight_high", "label": "Lay weight — high", "step": 1.0, "min": 0.0,
		"category": "Brood & the queen",
		"tip": "The top tier's share. Widening the gap between this and the low weight makes the zone a blunter instrument -- fewer cells needed to skew the mix, but less room for fine adjustment.",
	},
	{
		"key": "queen_lays_in_any_cell", "label": "Lay in plain comb", "toggle": true,
		"category": "Brood & the queen",
		"tip": "On: once every nursery cell is full the queen falls back to any spare undesignated cell, so laying never stalls. Off: she lays only where you have asked her to, and waits otherwise. The same switch appears on the queen's own panel when she is laying.",
	},
	{
		"key": "emergence_window_seconds", "label": "Emergence window s", "step": 30.0, "min": 30.0,
		"category": "Brood & the queen",
		"tip": "How long a stretch the nursery window's \"emerging per minute\" figures cover. Longer is steadier but slower to show the effect of a change you just made.",
	},
	{
		"key": "brood_develop_time", "label": "Brood time s", "step": 10.0, "min": 5.0,
		"category": "Brood & the queen",
		"tip": "Seconds of development a larva needs before it emerges. This clock only runs while the larva has food in it, so brood in an unnursed colony simply stops.",
	},
	{
		"key": "brood_feed_seconds", "label": "Feed lasts s", "step": 5.0, "min": 1.0,
		"category": "Brood & the queen",
		"tip": "How many seconds of development one feed of pollen and nectar buys a larva. When it runs out the larva stops developing until a nurse comes back.",
	},
	{
		"key": "brood_feed_seconds_honey", "label": "Honey feed s", "step": 5.0, "min": 1.0,
		"category": "Brood & the queen",
		"tip": "As above, but for a feed of pollen and honey. Honey is denser, so it carries the larva further -- which is much of the point of making it.",
	},
	{
		"key": "brood_feed_pollen", "label": "Pollen per feed", "step": 1.0, "min": 0.0,
		"category": "Brood & the queen",
		"tip": "Pollen a nurse drops into a cell per feed. Pollen is the protein and is needed for every feed, whatever the carbohydrate.",
	},
	{
		"key": "brood_feed_nectar", "label": "Nectar per feed", "step": 1.0, "min": 0.0,
		"category": "Brood & the queen",
		"tip": "Nectar used per feed when the colony has no honey to hand.",
	},
	{
		"key": "brood_feed_honey", "label": "Honey per feed", "step": 0.5, "min": 0.0,
		"category": "Brood & the queen",
		"tip": "Honey used per feed. Less than the nectar equivalent, and it lasts the larva longer.",
	},
	{
		"key": "brood_feed_threshold", "label": "Top up below s", "step": 1.0, "min": 0.0,
		"category": "Brood & the queen",
		"tip": "A nurse tops a larva back up once its remaining food drops below this, rather than waiting for it to stall completely.",
	},
	{
		"key": "larva_death_seconds", "label": "Starves after s", "step": 10.0, "min": 10.0,
		"category": "Brood & the queen",
		"tip": "How long a larva survives with nothing to eat before it dies. The body then blocks the cell until a comb worker on cell maintenance clears it out and carries it away, so neglect costs you the cell as well as the bee.",
	},
	{
		"key": "cell_clean_time", "label": "Clearing s", "step": 5.0, "min": 1.0,
		"category": "Brood & the queen",
		"tip": "Comb-worker seconds needed to clear a dead larva out of a cell. Several working the same cell share it.",
	},
	{
		"key": "nurse_carry_feeds", "label": "Feeds carried", "step": 1.0, "min": 1.0,
		"category": "Brood & the queen",
		"tip": "How many complete meals a nurse loads up with in one visit to the stores. She walks to a pollen cell and then a nectar or honey cell to fill up, and feeds larvae from what she is carrying -- higher values mean fewer trips back to the comb.",
	},
	{
		"key": "nurse_load_time", "label": "Loading s", "step": 0.5, "min": 0.0,
		"category": "Brood & the queen",
		"tip": "Seconds a nurse spends at a cell filling up with food for the brood.",
	},
	{
		"key": "tending_speed_bonus", "label": "Tending bonus", "step": 0.5, "min": 1.0,
		"category": "Brood & the queen",
		"tip": "Development speed multiplier while a nursery bee is standing over the cell. It only multiplies time the larva has food for -- tending an unfed larva does nothing.",
	},

	# --- Honey ---
	{
		"key": "honey_cell_capacity", "label": "Honey per cell", "step": 10.0, "min": 1.0,
		"category": "Honey",
		"tip": "How much honey one cell holds. Honey is stored separately from raw nectar so the two can be tuned apart.",
	},
	{
		"key": "honey_energy_factor", "label": "Honey energy x", "step": 0.5, "min": 1.0,
		"category": "Honey",
		"tip": "How many times more energy a unit of honey gives a bee than a unit of nectar. This is why a colony bothers converting: the same cell feeds several times as many bees.",
	},
	{
		"key": "nectar_per_honey", "label": "Nectar per honey", "step": 0.5, "min": 1.0,
		"category": "Honey",
		"tip": "Units of nectar consumed to make one unit of honey mix. Above 1 this is a concentration step -- thin nectar in, dense store out.",
	},
	{
		"key": "honey_chew_time", "label": "Chewing s", "step": 1.0, "min": 0.0,
		"category": "Honey",
		"tip": "Seconds a honey maker spends working enzymes into a load of nectar before it can spit the mix into a cell.",
	},
	{
		"key": "honey_ripen_time", "label": "Fanning s", "step": 5.0, "min": 1.0,
		"category": "Honey",
		"tip": "Bee-seconds of wing-fanning needed to evaporate the water out of one cell of mix. Several bees fanning the same cell share the work. Until it is done the cell holds wet mix, not honey, and nobody can eat it.",
	},
	{
		"key": "honey_rewet_factor", "label": "Re-wet x", "step": 0.1, "min": 0.0,
		"category": "Honey",
		"tip": "Adding fresh wet mix to a part-dried cell sets its drying back to this fraction of the progress it had. Low values make topping cells up expensive.",
	},

	# --- Gynes & royal jelly ---
	{
		"key": "gyne_egg_pollen_cost", "label": "Pollen per gyne", "step": 10.0, "min": 1.0,
		"category": "Gynes & royal jelly",
		"tip": "Pollen the queen must eat before she can lay a gyne, as opposed to a worker. This is the up-front cost of deciding to raise a future queen.",
	},
	{
		"key": "gyne_develop_multiplier", "label": "Gyne time x", "step": 0.5, "min": 1.0,
		"category": "Gynes & royal jelly",
		"tip": "How much longer a gyne takes to develop than a worker. She has to be fed the whole way, so this is also how much more nursing she costs.",
	},
	{
		"key": "gyne_speed_factor", "label": "Gyne speed x", "step": 0.05, "min": 0.1,
		"category": "Gynes & royal jelly",
		"tip": "A gyne's movement speed as a multiple of a worker's. She is a bigger animal, so she is slower.",
	},
	{
		"key": "gyne_energy_factor", "label": "Gyne energy x", "step": 0.05, "min": 1.0,
		"category": "Gynes & royal jelly",
		"tip": "How much more energy a gyne burns than a worker, both at rest and in flight.",
	},
	{
		"key": "gyne_size_factor", "label": "Gyne size x", "step": 0.05, "min": 1.0,
		"category": "Gynes & royal jelly",
		"tip": "How large a gyne is drawn relative to a worker, so you can pick one out of a crowd. The queen is about 1.55.",
	},
	{
		"key": "brood_feed_jelly", "label": "Jelly per feed", "step": 0.5, "min": 0.0,
		"category": "Gynes & royal jelly",
		"tip": "Royal jelly a nurse puts into a gyne larva per feed. Gyne larvae take jelly with pollen and honey and will not accept nectar.",
	},
	{
		"key": "brood_feed_seconds_gyne", "label": "Gyne feed s", "step": 5.0, "min": 1.0,
		"category": "Gynes & royal jelly",
		"tip": "How many seconds of development one royal jelly feed buys a gyne larva.",
	},
	{
		"key": "jelly_pollen_cost", "label": "Jelly: pollen", "step": 1.0, "min": 0.0,
		"category": "Gynes & royal jelly",
		"tip": "Pollen a nurse eats to make one batch of royal jelly.",
	},
	{
		"key": "jelly_honey_cost", "label": "Jelly: honey", "step": 1.0, "min": 0.0,
		"category": "Gynes & royal jelly",
		"tip": "Honey a nurse eats to make one batch of royal jelly. Jelly needs honey specifically, so a colony has to be making honey before it can raise gynes.",
	},
	{
		"key": "jelly_make_time", "label": "Jelly make s", "step": 1.0, "min": 1.0,
		"category": "Gynes & royal jelly",
		"tip": "Seconds a nurse spends working pollen and honey into a batch of royal jelly.",
	},
	{
		"key": "jelly_per_batch", "label": "Jelly per batch", "step": 1.0, "min": 1.0,
		"category": "Gynes & royal jelly",
		"tip": "How much royal jelly one batch produces.",
	},
	{
		"key": "jelly_cell_capacity", "label": "Jelly per cell", "step": 10.0, "min": 1.0,
		"category": "Gynes & royal jelly",
		"tip": "How much royal jelly a single cell holds.",
	},

	# --- Weather ---
	{
		"key": "weather_on", "label": "Weather on", "toggle": true,
		"category": "Weather",
		"tip": "Turn rain on or off. With it off the meadow stays dry indefinitely, which is easier but removes the main reason to keep stores in the comb.",
	},
	{
		"key": "rain_chance_per_day", "label": "Rain chance/day", "step": 0.05, "min": 0.0,
		"category": "Weather",
		"tip": "Roughly how often a day brings rain.",
	},
	{
		"key": "rain_min_seconds", "label": "Rain min s", "step": 10.0, "min": 5.0,
		"category": "Weather",
		"tip": "Shortest a shower lasts.",
	},
	{
		"key": "rain_max_seconds", "label": "Rain max s", "step": 10.0, "min": 5.0,
		"category": "Weather",
		"tip": "Longest a shower lasts. A long one on a colony with no stores is how a run ends.",
	},
	{
		"key": "rain_nectar_dilution", "label": "Nectar diluted", "step": 0.05, "min": 0.0,
		"category": "Weather",
		"tip": "How much of nectar's value is washed out of an open flower at full rain. A wet day's foraging brings home less from the same volume.",
	},
	{
		"key": "rain_flight_burn_factor", "label": "Wet flight x", "step": 0.1, "min": 1.0,
		"category": "Weather",
		"tip": "How much more flying costs at full rain. A wet bee carries the water as dead weight.",
	},
	{
		"key": "rain_forage_limit", "label": "Ground above", "step": 0.05, "min": 0.05,
		"category": "Weather",
		"tip": "Rain intensity past which a trip costs more than it brings back, so foragers stay at the hive until it eases.",
	},

	# --- Seasons & health ---
	{
		"key": "seasons_on", "label": "Flowering seasons", "toggle": true,
		"category": "Seasons & health",
		"tip": "Species come into flower at different times of the year, so the best ground moves through a run. Poppy is early and is the only pollen worth having before the borage arrives; foxglove has a short rich window in midsummer; clover carries most of the year. With this off everything flowers all the time. Takes effect immediately.",
	},
	{
		"key": "season_length_days", "label": "Season days", "step": 5.0, "min": 5.0,
		"category": "Seasons & health",
		"tip": "How long a full year is. Shorter means the flowering windows come round faster and the colony has less time in each.",
	},
	{
		"key": "disease_on", "label": "Pathogens", "toggle": true,
		"category": "Seasons & health",
		"tip": "Pressure builds in a hive with dead larvae left in it and in one that is crowded, and it slows brood development and shortens bee lifespans. This is what turns clearing from tidying into work worth doing before you need it -- the cost of ignoring it arrives later and all at once.",
	},
	{
		"key": "disease_threshold", "label": "Harmless below", "step": 0.05, "min": 0.0,
		"category": "Seasons & health",
		"tip": "Pressure below this does nothing at all. A basically clean colony should not be paying a constant tax; the cost has to arrive as a consequence of neglect.",
	},
	{
		"key": "disease_per_corpse", "label": "Per body/s", "step": 0.0005, "min": 0.0,
		"category": "Seasons & health",
		"tip": "How fast pressure builds per dead larva left in the comb. This is the number that decides how urgent clearing is.",
	},
	{
		"key": "disease_recovery", "label": "Recovery/s", "step": 0.0002, "min": 0.0,
		"category": "Seasons & health",
		"tip": "How fast pressure falls once the cause is dealt with. If clearing a backlog feels like it never helps, raise this.",
	},
	{
		"key": "disease_brood_penalty", "label": "Brood penalty", "step": 0.05, "min": 0.0,
		"category": "Seasons & health",
		"tip": "How much slower brood develops at full pressure.",
	},
	{
		"key": "disease_lifespan_penalty", "label": "Lifespan penalty", "step": 0.05, "min": 0.0,
		"category": "Seasons & health",
		"tip": "How much of its lifespan a bee loses at full pressure.",
	},
	{
		"key": "gyne_release_day", "label": "Gynes leave after", "step": 0.05, "min": 0.0,
		"category": "Seasons & health",
		"tip": "How far through the year gynes will start leaving, as a fraction of a season. They wait until late because one released in spring would have nowhere to overwinter -- and because letting them go the moment they matured would remove the decision about when to start raising them.",
	},
	{
		"key": "gyne_release_energy", "label": "Gyne needs", "step": 0.05, "min": 0.0,
		"category": "Seasons & health",
		"tip": "How full a gyne's crop has to be before she will leave, as a share of capacity. She is founding a colony on what she carries.",
	},

	# --- Winter ---
	{
		"key": "winter_countdown_days", "label": "Winter in days", "step": 1.0, "min": 1.0,
		"category": "Winter",
		"tip": "How many in-game days ahead \"Bring on winter\" schedules it. Fifteen is enough to change what you are doing without being so far off that it stops mattering.",
	},
	{
		"key": "winter_length_days", "label": "Winter lasts days", "step": 1.0, "min": 1.0,
		"category": "Winter",
		"tip": "How long the winter will be. This is what the required-stores figure is calculated from, so it is the main dial for how hard surviving one is.",
	},
	{
		"key": "winter_burn_factor", "label": "Winter burn x", "step": 0.05, "min": 0.05,
		"category": "Winter",
		"tip": "What a bee burns per second through the winter, as a multiple of its ordinary rate. Below one because a clustered colony is doing very little. Tune this first if the winter target feels trivial or impossible.",
	},
	{
		"key": "winter_lifespan_factor", "label": "Winter lifespan x", "step": 0.25, "min": 1.0,
		"category": "Winter",
		"tip": "How much longer a bee's natural lifespan runs through the winter, as a multiple of its ordinary one. Above one because a dormant, clustered bee wears out slower -- without this, bees can die of old age mid-winter even when perfectly fed.",
	},

	# --- The rival colony ---
	{
		"key": "rival_hive_on", "label": "Rival colony", "toggle": true,
		"category": "The rival colony",
		"tip": "Put a second colony in the meadow, run by the game. It isn't a copy of your simulation -- that would double the cost of the game for something you can't watch -- but an abstract colony with a few visible foragers that take nectar from the same real flowers you do. There is no combat: the pressure is entirely economic. Takes effect on Restart Run.",
	},
	{
		"key": "rival_starting_bees", "label": "Rival start bees", "step": 1.0, "min": 1.0,
		"category": "The rival colony",
		"tip": "How big the rival colony is when a run begins. Takes effect on Restart Run.",
	},
	{
		"key": "rival_max_bees", "label": "Rival max bees", "step": 5.0, "min": 1.0,
		"category": "The rival colony",
		"tip": "The most bees the rival can ever reach. This is the main dial for how much competition it eventually represents.",
	},
	{
		"key": "rival_min_distance", "label": "Rival distance", "step": 50.0, "min": 100.0,
		"category": "The rival colony",
		"tip": "How far from your hive the rival is placed. Far enough that you aren't fighting over the same flowers on day one; the two colonies meet in the middle later as both grow. Takes effect on Restart Run.",
	},
	{
		"key": "rival_forage_range", "label": "Rival range", "step": 20.0, "min": 50.0,
		"category": "The rival colony",
		"tip": "How far the rival's foragers will travel. Raising it makes the two colonies overlap sooner.",
	},
	{
		"key": "rival_crowding_scale", "label": "Rival crowding", "step": 5.0, "min": 1.0,
		"category": "The rival colony",
		"tip": "How much the rival's bees get in each other's way. More bees working the same patch of meadow get less each, which is what gives the colony a size that depends on the forage rather than always growing to its cap. Lower means the meadow supports fewer of them. Simulated over 200 days, this is the dial that decides whether squeezing the rival visibly shrinks it or does nothing at all.",
	},
	{
		"key": "rival_brood_gate_days", "label": "Rival grows above", "step": 5.0, "min": 1.0,
		"category": "The rival colony",
		"tip": "How many days of food in hand the rival wants before it will raise brood. Growing on an empty larder made it boom and then starve; waiting until it has a margin is what makes it settle at a steady size instead.",
	},
	{
		"key": "rival_flower_take", "label": "Rival take/visit", "step": 0.5, "min": 0.0,
		"category": "The rival colony",
		"tip": "Nectar one rival forager removes from a flower per visit. This is the only way the rival touches your world, so it is what turns it from scenery into competition. Set it to zero to have a neighbour that doesn't compete at all.",
	},

	# --- Predators ---
	{
		"key": "predators_on", "label": "Crab spiders", "toggle": true,
		"category": "Predators",
		"tip": "Ambush predators that sit motionless on flowers of one species (rolled per run) and occasionally kill a forager that starts feeding. Off by default -- the whole feature stays off until you turn it on to test. Everything else in this section only matters once this is on.",
	},
	{
		"key": "crab_spider_flower_fraction", "label": "Spider chance/flower", "step": 0.005, "min": 0.0,
		"category": "Predators",
		"tip": "Chance a newly created or regrown flower of the dangerous species gets a spider. At the default flower count and clover's share of the species mix, the starting guess of 0.02 puts roughly 4 spiders in the meadow at once. Only matters when Crab spiders is on.",
	},
	{
		"key": "crab_spider_attack_success_chance", "label": "Spider attack success", "step": 0.01, "min": 0.0,
		"category": "Predators",
		"tip": "Chance a spider actually catches a bee that starts feeding at its flower, rather than her narrowly escaping. Starting guess is 0.05 (5%) -- most attacks in real life miss too. Only matters when Crab spiders is on.",
	},
	{
		"key": "crab_spider_residency_seconds", "label": "Spider residency s", "step": 30.0, "min": 10.0,
		"category": "Predators",
		"tip": "How long a spider stays on one flower before relocating to another of the same species. It also relocates immediately, without waiting this long, if its flower dies first. Only matters when Crab spiders is on.",
	},
	{
		"key": "crab_spider_reveal_seconds", "label": "Spider reveal s", "step": 0.5, "min": 0.1,
		"category": "Predators",
		"tip": "How long a spider stays visible after an attack or a relocation before fading from view again. It's otherwise invisible. Only matters when Crab spiders is on.",
	},
	{
		"key": "show_crab_spiders", "label": "Always show spiders (dev)", "toggle": true,
		"category": "Predators",
		"tip": "Dev-only: marks every crab spider's flower with a large bright ring, rather than only flashing the tiny in-play marker on an attack or a relocation. For finding spiders to test spawning and movement before anything dangerous is worth watching for.",
	},
	{
		"key": "crab_spider_recruit_suppression_on", "label": "Suppress recruitment after escape", "toggle": true,
		"category": "Predators",
		"tip": "A forager who escapes an attack stops recruiting entrance mentors towards wherever she was foraging at the time -- until she moves on herself (a re-scout, a new preferred species, being mentored). She can still forage and still ask for help throughout; this only ever holds back her own recruiting. Only matters when Crab spiders is on.",
	},
	{
		"key": "alarm_pheromone_on", "label": "Alarm pheromone (placeholder)", "toggle": true,
		"category": "Predators",
		"tip": "Placeholder -- will move to a skill unlock once the skill tree exists. While on, a bee that lands at a flower another bee was recently attacked at (hit or miss) notices and leaves before ever risking a feed there -- a brief orange ring flashes on her when this fires, same as an attack flashes on a flower. Only matters when Crab spiders is on.",
	},
	{
		"key": "crab_spider_alarm_marker_seconds", "label": "Alarm marker s", "step": 5.0, "min": 5.0,
		"category": "Predators",
		"tip": "How long a flower stays marked as alarmed after an attack there. Only matters when Crab spiders and Alarm pheromone are both on.",
	},

	# --- Mining ---
	{
		"key": "block_mine_time", "label": "Block dig s", "step": 10.0, "min": 5.0,
		"category": "Mining",
		"tip": "Miner-seconds needed to break down one soil block. Several miners on one block share the work, exactly like builders on a cell.",
	},
	{
		"key": "miner_dirt_capacity", "label": "Dirt capacity", "step": 5.0, "min": 1.0,
		"category": "Mining",
		"tip": "How much spoil a miner can hold before it has to carry it outside. Real excavation does not vanish.",
	},
	{
		"key": "dirt_fill_rate", "label": "Dirt/s", "step": 0.1, "min": 0.0,
		"category": "Mining",
		"tip": "Spoil a miner accumulates per second while digging.",
	},
	{
		"key": "dirt_dump_time", "label": "Dumping s", "step": 0.5, "min": 0.0,
		"category": "Mining",
		"tip": "Seconds a miner spends outside the hive emptying a load of spoil.",
	},

	# --- Bee life ---
	{
		"key": "bee_lifespan_days", "label": "Lifespan days", "step": 5.0, "min": 1.0,
		"category": "Bee life",
		"tip": "In-game days a bee lives before dying of old age. The queen is exempt -- losing her would silently end the colony.",
	},
	{
		"key": "energy_capacity", "label": "Energy cap", "step": 10.0, "min": 10.0,
		"category": "Bee life",
		"tip": "Maximum energy a bee holds. Bees dim as this runs down and die at zero.",
	},
	{
		"key": "energy_burn_rate", "label": "Energy burn/s", "step": 0.1, "min": 0.0,
		"category": "Bee life",
		"tip": "Energy every bee burns per second just by being alive. Bees refuel from the comb, eating honey first where there is any.",
	},
	{
		"key": "flight_energy_burn", "label": "Flight burn/s", "step": 0.05, "min": 0.0,
		"category": "Bee life",
		"tip": "Extra energy a bee burns per second while actually flying, on top of simply being alive. This is what makes a distant patch cost something to work.",
	},
	{
		"key": "forager_drink_threshold", "label": "Drink below", "step": 0.05, "min": 0.05,
		"category": "Bee life",
		"tip": "How low a forager's energy gets before it drinks nectar straight from the flower it has landed on, rather than flying home. Every forager does this, including pollen foragers.",
	},
	{
		"key": "nectar_drink_rate", "label": "Drink rate/s", "step": 1.0, "min": 0.5,
		"category": "Bee life",
		"tip": "How quickly a bee takes nectar on board while drinking, at a flower or from its own crop.",
	},
	{
		"key": "crop_drink_threshold", "label": "Crop below", "step": 0.05, "min": 0.0,
		"category": "Bee life",
		"tip": "How low a nectar forager gets before it starts metabolising the load in its own crop rather than landing. That comes off the delivery, so a bee doing it often is ranging further than the patch is worth.",
	},
	{
		"key": "hunger_threshold", "label": "Eat below", "step": 0.05, "min": 0.05,
		"category": "Bee life",
		"tip": "How low a bee's energy has to fall, as a fraction of its capacity, before it breaks off what it is doing and walks to a cell to eat. Eating is a real trip now, so a low value means bees run leaner but lose less time.",
	},
	{
		"key": "bee_eat_rate", "label": "Eating rate/s", "step": 1.0, "min": 0.5,
		"category": "Bee life",
		"tip": "Energy a bee takes on per second while feeding at a cell. Honey supplies this from far fewer units than nectar does.",
	},
	{
		"key": "bumble_flight_on", "label": "Bumble flight", "toggle": true,
		"category": "Bee life",
		"tip": "Outdoor flying bees drift on a small side-to-side wander instead of beelining, so movement reads as bee-like. Purely visual -- never changes where a bee is or how fast it gets there.",
	},
	{
		"key": "bumble_flight_amplitude", "label": "Wander amplitude", "step": 1.0, "min": 0.0,
		"category": "Bee life",
		"tip": "How far side to side the wander drifts, in pixels. Only matters when Bumble flight is on.",
	},
	{
		"key": "bumble_flight_frequency", "label": "Wander speed", "step": 0.1, "min": 0.1,
		"category": "Bee life",
		"tip": "How fast the wander oscillates, in radians per second. Higher is twitchier. Only matters when Bumble flight is on.",
	},
	{
		"key": "bumble_flight_settle_seconds", "label": "Wander settle s", "step": 0.05, "min": 0.05,
		"category": "Bee life",
		"tip": "How long the visual offset takes to ease in when a bee starts flying outdoors, and back out when it lands -- this is what stops a landing bee snapping onto the flower. Only matters when Bumble flight is on.",
	},

	# --- Interface ---
	{
		"key": "history_sample_seconds", "label": "History sample s", "step": 1.0, "min": 1.0,
		"category": "Interface",
		"tip": "How often the colony window's over-time plot takes a reading. Together with the number of points below, this sets how far back the plot reaches.",
	},
	{
		"key": "history_points", "label": "History points", "step": 10.0, "min": 10.0,
		"category": "Interface",
		"tip": "How many readings the plot keeps. Sample seconds multiplied by this is the span it covers, in in-game seconds.",
	},
	{
		"key": "low_energy_warning_fraction", "label": "Warn at share", "step": 0.05, "min": 0.05,
		"category": "Interface",
		"tip": "What fraction of the colony has to be running low on energy before the game warns you. The warning does not pause anything.",
	},
	{
		"key": "low_energy_warning_level", "label": "Low energy is", "step": 0.05, "min": 0.05,
		"category": "Interface",
		"tip": "What counts as a bee running low, as a fraction of its energy capacity.",
	},
	{
		"key": "low_energy_gap", "label": "Warn every s", "step": 30.0, "min": 10.0,
		"category": "Interface",
		"tip": "Shortest gap between low-energy warnings, so a colony that stays hungry is told once and then left alone to be dealt with.",
	},
	{
		"key": "scenery_on", "label": "Trees & raised ground", "toggle": true,
		"category": "World & start",
		"tip": "Turn the trees and raised areas in the meadow on or off. With them off they vanish and stop blocking anything, so bees fly in straight lines -- useful for seeing the foraging economics on their own. Takes effect immediately.",
	},
	{
		"key": "fog_of_war_on", "label": "Fog of war", "toggle": true,
		"category": "World & start",
		"tip": "Hide meadow ground no bee has explored yet, and dim ground that's been seen before but has no bee near it right now. Turn off to see the whole meadow at once, same as before this existed. Takes effect immediately.",
	},
	{
		"key": "fog_reveal_radius", "label": "Sight radius", "step": 20.0, "min": 40.0,
		"category": "World & start",
		"tip": "How far around a bee out in the meadow counts as seen. Larger clears the fog faster and makes finding flowers less of a discovery.",
	},
	{
		"key": "fog_permanent_reveal", "label": "Fog stays revealed", "toggle": true,
		"category": "World & start",
		"tip": "Once a patch of meadow has been scouted, keep it fully visible for good. Off (the default), a scouted patch dims to a foggy memory once no bee is nearby, and brightens again when one returns. Either way it stays explored -- this only changes how an unlit patch draws. Takes effect immediately.",
	},
	{
		"key": "death_marker_days", "label": "Death marks days", "step": 1.0, "min": 0.0,
		"category": "World & start",
		"tip": "How many in-game days a mark stays where a bee died, fading as it goes. A cluster of them out at the edge of the meadow tells you bees are running out of energy trying to work a patch that is too far away.",
	},
	{
		"key": "fps", "label": "Frame rate", "star": true,
		"category": "Interface",
		"tip": "Show the frame rate in the top-right corner, alongside whatever else you have starred. Three numbers: the average, how long the last frame took in milliseconds, and the longest frame in the last second. The last one is the one that matters for smoothness -- a run that averages 60 but spikes to 50ms every so often will feel choppy, and only the worst-frame figure shows it.",
	},
	{
		"key": "show_info_badges", "label": "Show info icons", "toggle": true,
		"category": "Interface",
		"tip": "Show the small round 'i' buttons next to controls. Turn them off once you know what everything does and the panels get a lot quieter. Takes effect immediately.",
	},
	{
		"key": "colour_blind_mode", "label": "Colour-blind labels", "toggle": true,
		"category": "Interface",
		"tip": "Add a short text label wherever colour would otherwise be the only thing telling two states apart: what a cell holds, the nursery ring, the comb overlays and the zone glow. Around one man in twelve has some colour vision deficiency, and several of the palettes here are exactly the ones that fail -- but the labels are clearer for everyone at small sizes, so it is worth trying either way. Takes effect immediately.",
	},
	{
		"key": "gallerin_enabled", "label": "Dr Gallerin", "toggle": true,
		"category": "Interface",
		"tip": "The moth mentor who offers hints and encouragement during a Challenge. Turning him off changes nothing about how a Challenge plays -- he can be switched back on here at any time. Takes effect immediately.",
	},
]

## Foraging-automation prerequisite tree (see SCOUTING_TOGGLE_PLAN.md):
## each key's value is the toggle it depends on. Empty string means no
## prerequisite. Mirrors the intended research order for a future skills
## tree, not built yet.
const TOGGLE_PREREQUISITE := {
	"scouting_on": "orientation_flight_on",
	"floral_constancy_on": "scouting_on",
	"auto_recruitment_on": "scouting_on",
	"crab_spider_recruit_suppression_on": "predators_on",
	"alarm_pheromone_on": "predators_on",
}

## Settings that live in Session rather than GameConfig -- the player's
## own preferences, as opposed to numbers that change how the game plays.
## The panel edits both, so it needs to know which object to ask.
const SESSION_KEYS := [
	"show_info_badges", "colour_blind_mode",
	"show_flower_amounts", "show_cell_contents_text", "show_forager_labels",
	"gallerin_enabled", "show_crab_spiders",
]

static func setting_get(key: String):
	return Session.get(key) if key in SESSION_KEYS else GameConfig.get(key)

static func setting_set(key: String, value) -> void:
	if key in SESSION_KEYS:
		Session.set(key, value)
	else:
		GameConfig.set(key, value)

var value_labels: Dictionary = {}
## setting key -> its CheckBox, so the cascade helpers below can refresh
## a row's display when they flip a toggle other than the one clicked.
var toggle_boxes: Dictionary = {}
var panel: PanelContainer
var toggle_button: Button
## Greyed out for the length of an active Challenge -- see
## set_save_load_enabled, called by challenge_runner.gd.
var save_btn: Button
var load_btn: Button
## category name -> the VBox holding its rows, so the header button can
## show and hide it
var sections: Dictionary = {}

func _ready() -> void:
	process_mode = PROCESS_MODE_ALWAYS
	layer = 10   # draw on top of the world

	var vp := get_viewport().get_visible_rect().size

	# Anchored to the top-right corner so it tracks window resizing.
	# hud.gd keeps this width clear for us, so the two bars can't overlap.
	toggle_button = Button.new()
	# A plain cog glyph rather than a loaded texture, consistent with the
	# rest of the game's placeholder-art approach of drawing everything
	# rather than importing assets. Sized up with its own font override
	# since the button itself is now icon-sized rather than text-width.
	toggle_button.text = "⚙"
	toggle_button.add_theme_font_size_override("font_size", 18)
	toggle_button.custom_minimum_size = Vector2(36, 26)
	toggle_button.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	toggle_button.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	toggle_button.offset_right = -8
	toggle_button.offset_top = 8
	toggle_button.tooltip_text = "Open the settings window. Changing a value here affects bees and flowers created from then on -- press Restart Run to rebuild the whole world with the new numbers."
	toggle_button.pressed.connect(_toggle_panel)
	add_child(toggle_button)

	# hud.gd's top-right button row keeps clear of however wide this cog
	# actually is, rather than a fixed reserve -- see hud.gd's
	# set_settings_button_width. `resized` covers every future change
	# (e.g. a font-size setting making the glyph bigger); the deferred
	# call covers the first layout pass, since `resized` only fires on a
	# genuine change and the button's very first size might already be
	# whatever custom_minimum_size says.
	toggle_button.resized.connect(_report_settings_button_width)
	call_deferred("_report_settings_button_width")

	# Built once, here, rather than inside _report_settings_button_width --
	# that function's job is only to tell hud.gd how wide the cog is, and
	# it fires again on every resize. Building the panel there too used to
	# rebuild (and re-add, orphaning the old one) the whole settings window
	# every time the window was resized, on top of using `vp` from outside
	# its own scope, which failed to compile at all.
	panel = PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	panel.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	panel.offset_right = -8
	panel.offset_top = 40
	panel.custom_minimum_size = Vector2(300, 0)
	panel.visible = false
	add_child(panel)

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(300, min(560.0, vp.y - 80.0))
	panel.add_child(scroll)

	var column := VBoxContainer.new()
	scroll.add_child(column)

	_build_actions(column)

	# Every section starts closed, so opening the panel shows a short menu
	# of headings rather than every number at once.
	for category in CATEGORIES:
		var rows := _rows_in(category)
		if rows.is_empty():
			continue
		column.add_child(_make_section(category, rows, false))

func _report_settings_button_width() -> void:
	for hud in get_tree().get_nodes_in_group("huds"):
		if is_instance_valid(hud) and hud.has_method("set_settings_button_width"):
			hud.set_settings_button_width(toggle_button.size.x)

func _rows_in(category: String) -> Array:
	var found: Array = []
	for entry in TUNABLES:
		if entry.get("category", "") != category:
			continue
		# star rows aren't settings at all -- they toggle whether
		# something appears in the corner, which lives in
		# Session.pinned_stats rather than in GameConfig or Session
		# directly, so the guard below doesn't apply to them
		if entry.get("star", false):
			found.append(entry)
			continue
		# guard against a renamed setting leaving a dead row behind --
		# that used to crash the panel on startup with a confusing error
		if setting_get(entry.key) == null:
			push_warning("Settings window refers to a missing setting: %s" % entry.key)
			continue
		found.append(entry)
	return found

## A clickable heading with its rows underneath, hidden until the heading
## is clicked.
func _make_section(category: String, entries: Array, start_open: bool) -> Control:
	var wrapper := VBoxContainer.new()
	wrapper.add_theme_constant_override("separation", 0)

	var body := VBoxContainer.new()
	body.visible = start_open

	var header := Button.new()
	header.text = "%s  %s" % ["▾" if start_open else "▸", category]
	header.alignment = HORIZONTAL_ALIGNMENT_LEFT
	header.custom_minimum_size = Vector2(0, 24)
	header.add_theme_font_size_override("font_size", 12)
	header.pressed.connect(func():
		body.visible = not body.visible
		header.text = "%s  %s" % ["▾" if body.visible else "▸", category]
	)
	wrapper.add_child(header)
	wrapper.add_child(body)

	for entry in entries:
		if entry.get("star", false):
			body.add_child(_make_star_row(entry))
		elif entry.get("toggle", false):
			body.add_child(_make_toggle_row(entry))
		else:
			body.add_child(_make_row(entry))

	# The controls used to be printed permanently in the top-left corner
	# of the screen. They live here instead, so they're available when
	# you want them and out of the way when you don't.
	if category == "Interface":
		body.add_child(HSeparator.new())
		body.add_child(_make_controls_help())

	sections[category] = body
	return wrapper

func _make_controls_help() -> Control:
	var help := Label.new()
	help.add_theme_font_size_override("font_size", 11)
	help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	help.custom_minimum_size = Vector2(270, 0)
	help.text = """Controls

Arrow keys — pan the view
Mouse wheel — zoom in and out
Middle mouse drag — pan the view
Tab — switch between meadow and hive
Space — pause
C — colony window
N — nursery window
O — cycle the comb overlay
F — frame everything in view
Ctrl+1..9 — save the selection as a group
1..9 — select that group again
Ctrl+Z — undo the last cell reservation

Left click or drag — select bees
Ctrl+click — add comb or soil to a selection
Left click a flower, tree or raised area — see what it is
Left click a comb cell — inspect and set it
Left click exposed soil — mark it for digging
Right click a flower — send the selection to collect there
Right click the ground — move the selection there

Click a warning in the corner to select what it is about."""
	return help

## Restart, stage select and the main menu, kept at the top of the panel
## so they don't drift below a growing list of settings.
func _build_actions(column: VBoxContainer) -> void:
	var restart_row := HBoxContainer.new()
	column.add_child(restart_row)

	var restart_btn := Button.new()
	restart_btn.text = "Restart Run"
	restart_btn.pressed.connect(_on_restart_pressed)
	restart_row.add_child(UI.with_info(restart_btn, "Rebuild the meadow and hive from scratch using the current values above, at whichever starting stage you last chose. Everything in progress is lost; the tuning numbers themselves are kept."))

	var menu_btn := Button.new()
	menu_btn.text = "Return to Main Menu"
	menu_btn.pressed.connect(_on_main_menu_pressed)
	restart_row.add_child(UI.with_info(menu_btn, "Pause and go back to the main menu, where you can start a fresh run at Level 1 (the queen alone), Level 2 (queen, one nectar forager, one cell) or Level 3 (queen, two foragers, three cells). You can also close the menu again and carry on with the run you have."))

	var save_row := HBoxContainer.new()
	column.add_child(save_row)

	save_btn = Button.new()
	save_btn.text = "Save run"
	save_btn.pressed.connect(_on_save_pressed)
	save_row.add_child(UI.with_info(save_btn, "Write the current run to disk: the comb and everything in it, every bee and what it is doing, the meadow, the weather and the clock. There is one save slot, so saving again overwrites it."))

	load_btn = Button.new()
	load_btn.text = "Load run"
	load_btn.pressed.connect(_on_load_pressed)
	save_row.add_child(UI.with_info(load_btn, "Rebuild the world from the saved run. Whatever is happening now is lost."))

	var winter_row := HBoxContainer.new()
	column.add_child(winter_row)

	var winter_btn := Button.new()
	winter_btn.text = "Bring on winter"
	winter_btn.pressed.connect(_on_winter_pressed)
	winter_row.add_child(UI.with_info(winter_btn, "Schedule a winter for a set number of days from now (see \"Winter in days\" below). A forecast opens in the top right showing what the colony will need to last it out and how far short it currently is. The figure moves as the colony grows, which is the point: every bee you add is another mouth to feed through it."))

	column.add_child(HSeparator.new())

## Starts the countdown on the running world. Winter is scheduled
## relative to the current day rather than a fixed date, so pressing this
## on day 40 gives the same run-up as pressing it on day 4.
func _on_winter_pressed() -> void:
	var worlds := get_tree().get_nodes_in_group("world")
	if worlds.is_empty():
		return
	worlds[0].begin_winter_countdown()

## Ordinary player save/load doesn't record Challenge stage/gate/prompt
## state (see challenge_runner.gd), so it's disabled for the length of an
## active Challenge -- tutorial_checkpoint.gd covers Challenge-internal
## rollback instead. Godot doesn't fire `pressed` on a disabled button, so
## the handlers below don't need their own guard on top of this.
func set_save_load_enabled(enabled: bool) -> void:
	save_btn.disabled = not enabled
	load_btn.disabled = not enabled

## Lets another panel (hud.gd's queen panel) change a settings-window
## toggle without writing GameConfig/Session itself -- keeps the write
## inside this allowlisted file and keeps the settings window's own
## checkbox in sync if it's currently open.
func set_toggle(key: String, value: bool) -> void:
	setting_set(key, value)
	if toggle_boxes.has(key):
		toggle_boxes[key].set_pressed_no_signal(value)

func _on_save_pressed() -> void:
	var worlds := get_tree().get_nodes_in_group("world")
	if worlds.is_empty():
		push_warning("No world to save")
		return
	worlds[0].save_run()

## Loading goes through a scene reload rather than trying to mutate the
## running world in place: the saved tuning values decide the shape of
## the hive, so the world has to be built with them from the start. The
## flag tells the fresh scene to replay the save over itself.
func _on_load_pressed() -> void:
	var data := SaveGame.read()
	if data.is_empty():
		push_warning("There is no save to load")
		return
	SaveGame.apply_settings(data)
	Session.load_pending = true
	Session.menu_pending = false
	get_tree().paused = false
	Engine.time_scale = 1.0
	get_tree().reload_current_scene()

func _toggle_panel() -> void:
	panel.visible = not panel.visible
	# The cog itself doesn't change state -- the panel opening or closing
	# is feedback enough, the way it wasn't when this button was just a
	# label reading "Tuning".

func _make_row(entry: Dictionary) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 3)

	var lbl := Label.new()
	lbl.add_theme_font_size_override("font_size", 11)
	lbl.custom_minimum_size = Vector2(140, 0)
	lbl.text = "%s: %s" % [entry.label, _format_value(setting_get(entry.key))]
	value_labels[entry.key] = lbl
	row.add_child(lbl)

	row.add_child(UI.info_badge(entry.tip))

	var minus := Button.new()
	minus.text = "-"
	minus.custom_minimum_size = Vector2(26, 24)
	minus.pressed.connect(func(): _adjust(entry, -entry.step))
	row.add_child(minus)

	var plus := Button.new()
	plus.text = "+"
	plus.custom_minimum_size = Vector2(26, 24)
	plus.pressed.connect(func(): _adjust(entry, entry.step))
	row.add_child(plus)

	return row

## An on/off setting rather than a number, shown as a checkbox. Takes
## effect immediately -- no Restart Run needed.
func _make_toggle_row(entry: Dictionary) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 3)

	var box := CheckBox.new()
	box.text = entry.label
	box.add_theme_font_size_override("font_size", 11)
	box.button_pressed = setting_get(entry.key)
	var key: String = entry.key
	toggle_boxes[key] = box
	box.toggled.connect(func(pressed: bool):
		setting_set(key, pressed)
		if key == "show_info_badges":
			# applies to every badge already on screen, not just new ones
			UI.refresh_badge_visibility(self)
		elif key == "colour_blind_mode":
			# every cell relabels itself on its next frame; the panels are
			# told so they can redraw their keys straight away
			for panel in get_tree().get_nodes_in_group("colour_blind_listeners"):
				if is_instance_valid(panel) and panel.has_method("colour_blind_changed"):
					panel.colour_blind_changed()
		elif key == "gallerin_enabled":
			# gallerin_panel.gd only reads this once, in its own _ready() --
			# toggling it here has to reach the live node directly, same
			# idea as the colour-blind broadcast above.
			for panel in get_tree().get_nodes_in_group("gallerin"):
				if is_instance_valid(panel):
					panel.visible = pressed
		elif TOGGLE_PREREQUISITE.has(key) or TOGGLE_PREREQUISITE.values().has(key):
			if pressed:
				_cascade_prerequisites_on(key)
			else:
				_cascade_dependents_off(key)
	)
	row.add_child(box)
	row.add_child(UI.info_badge(entry.tip))
	return row

## Walks up TOGGLE_PREREQUISITE from `key`, turning on everything it
## depends on -- e.g. switching on Floral constancy also switches on
## Auto scouting, which also switches on Orientation flight.
func _cascade_prerequisites_on(key: String) -> void:
	var parent: String = TOGGLE_PREREQUISITE.get(key, "")
	while parent != "":
		if not setting_get(parent):
			setting_set(parent, true)
			if toggle_boxes.has(parent):
				toggle_boxes[parent].button_pressed = true
		parent = TOGGLE_PREREQUISITE.get(parent, "")

## Walks TOGGLE_PREREQUISITE's values to find anything whose prerequisite
## is `key` (directly or transitively) and turns it off too -- e.g.
## switching off Auto scouting also switches off Floral constancy and
## Auto-recruitment.
func _cascade_dependents_off(key: String) -> void:
	for child in TOGGLE_PREREQUISITE:
		if TOGGLE_PREREQUISITE[child] == key and setting_get(child):
			setting_set(child, false)
			if toggle_boxes.has(child):
				toggle_boxes[child].button_pressed = false
			_cascade_dependents_off(child)

## A row whose control is the same ★ / ☆ toggle the colony window uses,
## pinning something into the corner readout rather than changing a
## number. Kept identical to that one on purpose: a star means the same
## thing wherever the player meets it.
func _make_star_row(entry: Dictionary) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 3)

	var key: String = entry.key
	var star := Button.new()
	star.toggle_mode = true
	star.flat = true
	star.focus_mode = Control.FOCUS_NONE
	star.button_pressed = Session.pinned_stats.has(key)
	star.text = "★" if star.button_pressed else "☆"
	star.add_theme_font_size_override("font_size", 13)
	star.tooltip_text = "Show this in the top-right corner."
	star.toggled.connect(func(pressed: bool):
		if pressed and not Session.pinned_stats.has(key):
			Session.pinned_stats.append(key)
		elif not pressed:
			Session.pinned_stats.erase(key)
		star.text = "★" if pressed else "☆"
		# The corner has to be told: no number changed, so nothing else
		# would prompt it to redraw.
		for hud in get_tree().get_nodes_in_group("huds"):
			if is_instance_valid(hud) and hud.has_method("pinned_stats_changed"):
				hud.pinned_stats_changed()
	)
	row.add_child(star)

	var label := Label.new()
	label.text = entry.label
	label.add_theme_font_size_override("font_size", 11)
	row.add_child(label)
	row.add_child(UI.info_badge(entry.tip))
	return row

func _adjust(entry: Dictionary, delta: float) -> void:
	var new_value: float = setting_get(entry.key) + delta
	new_value = max(new_value, entry.min)
	setting_set(entry.key, new_value)
	value_labels[entry.key].text = "%s: %s" % [entry.label, _format_value(new_value)]

func _format_value(v) -> String:
	if v is bool:
		return "on" if v else "off"
	if v == int(v):
		return str(int(v))
	return "%.2f" % v

func _on_restart_pressed() -> void:
	_restart()

## main.gd adds the menu to the "main_menu" group, so the panel can reach
## it without the two needing to know about each other directly.
func _on_main_menu_pressed() -> void:
	var menus := get_tree().get_nodes_in_group("main_menu")
	if menus.is_empty():
		push_warning("No main menu in the scene to return to")
		return
	panel.visible = false
	menus[0].open()

func _restart() -> void:
	get_tree().paused = false
	Engine.time_scale = 1.0
	Session.reset_run_state()
	get_tree().reload_current_scene()
