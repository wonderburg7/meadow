extends RefCounted
## The settings catalogue: what a setting *is*, separate from the window
## that shows it. Every row's key, label, category, range, tip and
## grouping lives here, together with the four functions that read and
## write a setting -- including the Prerequisites cascade, so turning a
## toggle on or off keeps its dependencies consistent no matter who asked.
##
## Split out of debug_panel.gd (1781 lines, roughly 900 of them this
## table) because non-visual code already depended on it:
## scenario_actions.gd's `set_config` verb and main.gd's scenario picker
## both had to reach through a CanvasLayer that preloads Hud, UiTheme,
## SaveGame and UI to get at a list of numbers. Same authority /
## presentation split prerequisites.gd and availability.gd already made:
## game_config.gd is the authority for what a setting is, this file
## catalogues how it is presented, and debug_panel.gd is a view of both.
##
## A leaf: nothing here touches the scene tree, and the only script it
## preloads is prerequisites.gd. debug_panel.gd builds every widget and
## keeps its own checkbox-syncing wrappers around the three cascade
## helpers below.

# --- preloads and collection order --------------------------------
const Prerequisites = preload("res://scripts/prerequisites.gd")

## Collection and section order here is the order they appear in the panel.
const COLLECTIONS := [
	{
		"name": "Game Settings",
		"categories": [
			"World & start", "Interface", "Appearance", "Accessibility", "Controls",
		],
	},
	{
		"name": "Hive",
		"categories": [
			"Hive & comb", "Brood & the queen", "Honey", "Gynes & royal jelly", "Bee life",
		],
	},
	{
		"name": "Meadow",
		"categories": [
			"Flowers", "Foraging", "Weather", "Seasons & health", "Winter",
			"The rival colony", "Predators", "Mining",
		],
	},
]

# --- the tunables table -------------------------------------------
const TUNABLES := [
	# --- World & start ---
	# The five starting-colony rows are dev_only (Dave, 15 Oct 2026,
	# architecture review F5): every startable run takes its cells and bees
	# from its levels.gd row, so these shape only the level-0 fallback world
	# built before a load replays a save.
	{
		"persist": "run",
		"key": "hive_cell_count", "label": "Starting cells", "step": 1.0, "min": 1.0,
		"category": "World & start", "dev_only": true,
		"tip": "How many finished comb cells the hive begins with. Builders add more on top of these.",
	},
	{
		"persist": "run",
		"key": "starting_bees", "label": "Starting foragers", "step": 1.0, "min": 1.0,
		"category": "World & start", "dev_only": true,
		"tip": "How many foragers exist at the start of a run.",
	},
	{
		"persist": "run",
		"key": "starting_nurses", "label": "Starting nurses", "step": 1.0, "min": 0.0,
		"category": "World & start", "dev_only": true,
		"tip": "Nurses feed developing larvae. Brood does not develop at all without one, so a colony with no nurse never grows.",
	},
	{
		"persist": "run",
		"key": "starting_builders", "label": "Starting builders", "step": 1.0, "min": 0.0,
		"category": "World & start", "dev_only": true,
		"tip": "Builders draw new comb and shift stores between cells. With none, the hive can only expand once you assign a bee to build.",
	},
	{
		"persist": "run",
		"key": "starting_honey_makers", "label": "Starting honey makers", "step": 1.0, "min": 0.0,
		"category": "World & start", "dev_only": true,
		"tip": "Honey makers turn stored nectar into honey. None to begin with by default -- a young colony needs the nectar as it is.",
	},
	{
		"persist": "run",
		"key": "seconds_per_day", "label": "Seconds per day", "step": 30.0, "min": 10.0,
		"category": "World & start",
		"tip": "Real seconds in one in-game day. This drives the day counter and how quickly bees age towards their lifespan.",
	},
	{
		"persist": "none",
		"key": "checkpoint_every_days", "label": "Checkpoint every (days)", "step": 1.0, "min": 1.0,
		"category": "World & start",
		"tip": "How often the run quietly writes one of its three rotating checkpoints. Your own save is never overwritten by one.",
	},
	{
		"persist": "none",
		"key": "pollen_warning_first_day", "label": "Pollen warning from day", "step": 1.0, "min": 1.0,
		"category": "World & start",
		"tip": "The \"almost no pollen\" line is kept off the problem strip until this day. A colony this young genuinely has no pollen and there is nothing useful to do about it, so warning from the first minute only teaches you to ignore the strip.",
	},
	{
		"persist": "run",
		"key": "pollen_warning_stock_multiplier", "label": "Pollen warning x egg cost", "step": 0.05, "min": 0.0,
		"category": "World & start",
		"tip": "Show the low-pollen warning when stores fall below this multiple of the pollen needed for one egg. At 0.5, the warning begins below half an egg's worth, matching the original signal.",
	},
	{
		"persist": "run",
		"key": "nectar_warning_total", "label": "Nectar warning below", "step": 5.0, "min": 0.0,
		"category": "World & start",
		"tip": "One half of the food warning: it appears only when both raw nectar and honey are below their own limits.",
	},
	{
		"persist": "run",
		"key": "honey_warning_total", "label": "Honey warning below", "step": 1.0, "min": 0.0,
		"category": "World & start",
		"tip": "The stored-honey half of the food warning. Raising it makes the warning arrive earlier only when nectar is also low.",
	},

	# --- Flowers ---
	{
		"persist": "run",
		"key": "flower_count", "label": "Flowers", "step": 1.0, "min": 1.0,
		"category": "Flowers",
		"tip": "How many flowers are scattered across the meadow. More flowers means less competition and shorter trips.",
	},
	{
		"persist": "run",
		"key": "nectar_recharge_rate", "label": "Nectar rchg/s", "step": 0.1, "min": 0.0,
		"category": "Flowers",
		"tip": "How fast a drained flower refills its nectar, per second. Lower values make bees range further from the hive.",
	},
	{
		"persist": "run",
		"key": "pollen_recharge_rate", "label": "Pollen rchg/s", "step": 0.05, "min": 0.0,
		"category": "Flowers",
		"tip": "How fast a drained flower refills its pollen, per second. Deliberately slower than nectar, so pollen is the scarcer resource.",
	},
	{
		"persist": "run",
		"key": "flower_senescence_on", "label": "Flower senescence", "toggle": true,
		"category": "Flowers",
		"tip": "A flower recharges more slowly as it nears the end of its life instead of refilling at full strength right up until it dies -- real flowers get less productive as they age.",
	},
	{
		"persist": "run",
		"key": "flower_senescence_floor", "label": "Senescence floor", "step": 0.05, "min": 0.0, "max": 1.0,
		"category": "Flowers",
		"tip": "How slow a flower's recharge has become by the end of its life, as a fraction of full speed (1.0 = no decline, 0.3 = down to 30%). Only matters with Flower senescence on.",
	},
	{
		"persist": "run",
		"key": "tarsal_markers_on", "label": "Tarsal markers", "toggle": true,
		"category": "Foraging",
		"tip": "Bees leave a scent mark from their feet on every flower they land on. With this on, other bees avoid a flower marked in the last few seconds, so the colony spreads out instead of crowding the same patch. Real bumblebees and honeybees both do this.",
	},
	{
		"persist": "run",
		"key": "tarsal_marker_seconds", "label": "Marker lasts s", "step": 5.0, "min": 1.0,
		"category": "Foraging",
		"tip": "How long a scent mark keeps other bees away. Only matters when Tarsal markers is on.",
	},
	{
		"persist": "run",
		"key": "orientation_flight_on", "label": "Orientation flight", "toggle": true,
		"category": "Foraging",
		"tip": "A new forager makes a short flight to a random spot near the hive before her first trip, and keeps working that spot from then on, rather than beelining for whatever's nearest the door -- real bees do this too, learning the area before they start foraging properly. Off by default. This and Auto scouting are alternatives: turning either on turns the other off.",
	},
	{
		"persist": "run",
		"key": "scouting_on", "label": "Auto scouting", "toggle": true,
		"category": "Foraging",
		"tip": "A new forager tries a few start points near the hive and settles on whichever collected best, instead of just keeping the first one. Off by default. This and Orientation flight are alternatives: turning either on turns the other off. Turning on Floral constancy or Auto-recruitment turns this on too, since both rely on a forager having actually scouted. Turning this off also turns off Floral constancy and Auto-recruitment.",
	},
	{
		"persist": "run",
		"key": "floral_constancy_on", "label": "Floral constancy", "toggle": true,
		"category": "Foraging",
		"tip": "Lets you pin a forager to one flower species via 'Set preference' in its selection panel -- it will only ever visit that species from then on. Also makes Auto scouting sample a different species each bout, so a scouted forager settles on the best start point AND species together, not just the best spot. Off by default; existing preferences are kept even if you turn this off, they just stop being offered as a new option. Turning this on also turns Auto scouting on.",
	},
	{
		"persist": "run",
		"key": "auto_recruitment_on", "label": "Auto-recruitment", "toggle": true,
		"category": "Foraging",
		"tip": "Foragers compare notes at the hive entrance -- a good performer can pass its start point (and species, if Floral constancy is also on) to a struggling one of the same resource type. Off by default; off means no bee ever waits at the door. Turning this on also turns Auto scouting on and turns Proximity recruitment off.",
	},
	{
		"persist": "run",
		"key": "proximity_recruitment_on", "label": "Proximity recruitment", "toggle": true,
		"category": "Foraging",
		"tip": "An alternate to Auto-recruitment, not stacked on top of it: instead of waiting at the door, a good performer physically dances with a struggling one of the same resource type the moment they cross paths during ordinary indoor movement, passing on a rough direction and distance rather than an exact point. Off by default; mutually exclusive with Auto-recruitment -- turning one on turns the other off, since both compete for the same eligible bees. Turning this on also turns Auto scouting on.",
	},
	{
		"persist": "run",
		"key": "probabilistic_choice_on", "label": "Weighted flower choice (dev)", "toggle": true,
		"category": "Flowers", "dev_only": true,
		"tip": "Developer mode: forces weighted flower choice on for testing. A forager choosing between several flowers she can see weighs distance and heading (ahead of her over behind her) instead of always taking the literal nearest one. In play this comes from owning the Weighted flower choice skill; with neither, foragers take the nearest flower.",
	},
	{
		"persist": "run",
		"key": "handling_experience_on", "label": "Handling experience", "toggle": true,
		"category": "Flowers",
		"tip": "A forager gets faster at working a flower species the more she's actually fed from it, up to a practised-expert floor. Off by default; off means handling time is exactly what the species alone sets, with no per-bee learning curve.",
	},
	{
		"persist": "run",
		"key": "adaptive_constancy_on", "label": "Adaptive constancy", "toggle": true,
		"category": "Flowers",
		"tip": "A forager grows more confident in a species that keeps paying off, and loses confidence in one that doesn't -- unlike Floral constancy's fixed pin, she can still drift away if a trusted species dries up. Off by default. Only visible when the flower-choice-weighting toggle (probabilistic_choice) is also on -- confidence only ever biases a weighted choice, it never overrides Floral constancy's outright pin.",
	},
	{
		"persist": "run",
		"key": "forage_start_radius", "label": "Start point radius", "step": 20.0, "min": 20.0,
		"category": "Foraging",
		"tip": "How far from the hive a new forager's start point (Orientation flight or Auto scouting) is scattered -- how spread apart different foragers' patches are. Not how far a forager will fly to find a flower once she's working an area (that's forage_search_radius, tuned separately and much larger). Only matters when Orientation flight or Auto scouting is on.",
	},
	{
		"persist": "run",
		"key": "recruit_lower_threshold_nectar", "label": "Recruit: seek below (nectar)", "step": 0.1, "min": 0.0,
		"category": "Foraging",
		"tip": "A nectar forager collecting less than this (units/second) waits at the entrance hoping a better-performing forager tells it where to go. Only matters when Auto-recruitment is on.",
	},
	{
		"persist": "run",
		"key": "recruit_upper_threshold_nectar", "label": "Recruit: offer above (nectar)", "step": 0.1, "min": 0.0,
		"category": "Foraging",
		"tip": "A nectar forager collecting more than this (units/second) waits at the entrance, willing to pass on its start point. Only matters when Auto-recruitment is on.",
	},
	{
		"persist": "run",
		"key": "recruit_lower_threshold_pollen", "label": "Recruit: seek below (pollen)", "step": 0.1, "min": 0.0,
		"category": "Foraging",
		"tip": "Same as the nectar version, for pollen foragers. Pollen's base collection rate is lower than nectar's, so this needs its own number rather than sharing the nectar threshold. Only matters when Auto-recruitment is on.",
	},
	{
		"persist": "run",
		"key": "recruit_upper_threshold_pollen", "label": "Recruit: offer above (pollen)", "step": 0.1, "min": 0.0,
		"category": "Foraging",
		"tip": "Same as the nectar version, for pollen foragers. Only matters when Auto-recruitment is on.",
	},
	{
		"persist": "run",
		"key": "recruit_wait_seconds", "label": "Recruit wait s", "step": 1.0, "min": 1.0,
		"category": "Foraging",
		"tip": "How long a forager waits at the entrance for a match before giving up and heading out on its own. Only matters when Auto-recruitment is on.",
	},
	{
		"persist": "run",
		"key": "recruit_start_point_jitter", "label": "Recruit start point spread", "step": 10.0, "min": 0.0,
		"category": "Foraging",
		"tip": "A recruited forager's inherited start point is nudged this far from her mentor's exact one, in a random direction -- still the same general proven area, but not the same handful of flowers. At 0, she starts from exactly the mentor's point, which measurably cost the mentor her own rate in testing (both bees converging on one patch). Only matters when Auto-recruitment is on.",
	},
	{
		"persist": "run",
		"key": "recruit_grace_trips", "label": "Recruit grace trips", "step": 1.0, "min": 0.0,
		"category": "Foraging",
		"tip": "How many trips a forager must complete before it's judged against the thresholds above. Shared with Proximity recruitment, which judges eligibility the same way.",
	},
	{
		"persist": "run",
		"key": "recruit_dance_radius", "label": "Dance trigger radius", "step": 10.0, "min": 10.0,
		"category": "Foraging",
		"tip": "How close a mentor-eligible and a seeker-eligible forager (same resource type) must be, indoors, before they dance. Only matters when Proximity recruitment is on.",
	},
	{
		"persist": "run",
		"key": "recruit_dance_seconds", "label": "Dance duration s", "step": 0.5, "min": 0.5,
		"category": "Foraging",
		"tip": "How long the dance itself lasts once triggered. Only matters when Proximity recruitment is on.",
	},
	{
		"persist": "run",
		"key": "recruit_dance_angle_fuzz_degrees", "label": "Dance angle fuzz", "step": 5.0, "min": 0.0, "max": 180.0,
		"category": "Foraging",
		"tip": "How far off, in degrees, the direction a dance encodes can drift from the mentor's own start-point direction. Only matters when Proximity recruitment is on.",
	},
	{
		"persist": "run",
		"key": "recruit_dance_distance_fuzz_fraction", "label": "Dance distance fuzz", "step": 0.05, "min": 0.0, "max": 1.0,
		"category": "Foraging",
		"tip": "How far off, as a fraction of the mentor's own distance from the hive, the distance a dance encodes can drift. 0.25 means anywhere from 75% to 125% of the mentor's distance. Only matters when Proximity recruitment is on.",
	},
	{
		"persist": "player",
		"key": "show_flower_amounts", "label": "Show flower amounts", "toggle": true,
		"category": "Flowers",
		"tip": "Show the nectar and pollen numbers under every flower. Off by default -- 500 flowers' worth of numbers gets noisy fast, and clicking a flower shows the same numbers on demand. Applies within about a second, as flowers redraw themselves.",
	},

	# --- Foraging ---
	{
		"persist": "run",
		"key": "bee_speed", "label": "Bee speed", "step": 10.0, "min": 10.0,
		"category": "Foraging",
		"tip": "Flight and walking speed in pixels per second. The queen moves at a fraction of this (see Queen speed).",
	},
	{
		"persist": "run",
		"key": "flower_handling_time", "label": "Handling s", "step": 0.5, "min": 0.0,
		"category": "Foraging",
		"tip": "Seconds a bee spends on a flower before it starts gathering, representing finding its way to the nectary.",
	},
	{
		"persist": "run",
		"key": "nectar_collection_rate", "label": "Nectar rate/s", "step": 0.5, "min": 0.1,
		"category": "Foraging",
		"tip": "Nectar gathered per second once handling is finished. The flower's readout drains at this rate while you watch.",
	},
	{
		"persist": "run",
		"key": "pollen_collection_rate", "label": "Pollen rate/s", "step": 0.5, "min": 0.1,
		"category": "Foraging",
		"tip": "Pollen gathered per second once handling is finished.",
	},
	{
		"persist": "run",
		"key": "deposit_time", "label": "Deposit s", "step": 0.5, "min": 0.0,
		"category": "Foraging",
		"tip": "Seconds a forager spends emptying itself into a comb cell, once it has walked to that cell.",
	},
	{
		"persist": "run",
		"key": "nectar_stomach_capacity", "label": "Nectar stomach", "step": 5.0, "min": 1.0,
		"category": "Foraging",
		"tip": "How much nectar a forager can carry before it must return to the hive.",
	},
	{
		"persist": "run",
		"key": "pollen_stomach_capacity", "label": "Pollen stomach", "step": 5.0, "min": 1.0,
		"category": "Foraging",
		"tip": "How much pollen a forager can carry. Smaller than the nectar stomach, so pollen trips deliver less.",
	},
	{
		"persist": "player",
		"key": "show_forager_labels", "label": "Show forager labels", "toggle": true,
		"category": "Foraging",
		"tip": "Show the small ID-and-letter label that floats above each forager. Off gives a cleaner view of a big crowd of them out in the meadow -- the small dot on each one (yellow for pollen, blue for nectar) still says what it's collecting. Takes effect on the bees currently on screen straight away.",
	},

	# --- Hive & comb ---
	{
		"persist": "run",
		"key": "cell_capacity", "label": "Cell capacity", "step": 10.0, "min": 1.0,
		"category": "Hive & comb",
		"tip": "How much of one resource a single comb cell holds. A cell stores nectar, or pollen, or honey, or one developing bee -- never a mix.",
	},
	{
		"persist": "run",
		"key": "cell_build_time", "label": "Cell build s", "step": 10.0, "min": 5.0,
		"category": "Hive & comb",
		"tip": "Builder-seconds needed to finish one cell. Two builders on the same cell halve the wall-clock time, three third it, and so on.",
	},
	{
		"persist": "run",
		"key": "build_energy_burn", "label": "Build energy/s", "step": 0.1, "min": 0.0,
		"category": "Hive & comb",
		"tip": "Extra energy a builder burns while building. Bees make wax from the sugar they have eaten, so comb is paid for in nectar rather than a separate wax store.",
	},
	{
		"persist": "run",
		"key": "hive_interior_rings", "label": "Interior rings", "step": 1.0, "min": 2.0,
		"category": "Hive & comb",
		"tip": "How many rings of open floor the hive has before the soil wall starts. This is the space comb can grow into. Takes effect on Restart Run.",
	},
	{
		"persist": "run",
		"key": "hive_soil_depth", "label": "Soil depth", "step": 1.0, "min": 1.0,
		"category": "Hive & comb",
		"tip": "How far the diggable soil extends beyond the hollow. Deeper means more room to mine into later. Takes effect on Restart Run.",
	},
	{
		"persist": "run",
		"key": "hive_rock_rings", "label": "Bedrock rings", "step": 1.0, "min": 1.0,
		"category": "Hive & comb",
		"tip": "Rings of solid rock wrapped round the outside of the soil. Rock cannot be marked, mined or walked through, so this is the hard outer limit of how far the colony can ever spread. Takes effect on Restart Run.",
	},
	{
		"persist": "run",
		"key": "cell_slow_factor", "label": "Comb speed x", "step": 0.05, "min": 0.1,
		"category": "Hive & comb",
		"tip": "How much slower a bee moves while crossing comb rather than open floor. 1 means no penalty.",
	},
	{
		"persist": "run",
		"key": "hive_cell_spacing", "label": "Cell spacing", "step": 1.0, "min": 4.0,
		"category": "Hive & comb",
		"tip": "Distance between neighbouring cell centres. Takes effect on the next Restart Run.",
	},
	{
		"persist": "run",
		"key": "hive_cell_size", "label": "Cell size", "step": 1.0, "min": 3.0,
		"category": "Hive & comb",
		"tip": "How large each hexagon is drawn. Keep this a little below Cell spacing or cells will overlap.",
	},
	{
		"persist": "player",
		"key": "show_cell_contents_text", "label": "Show cell contents text", "toggle": true,
		"category": "Appearance",
		"tip": "Show the small text on each comb cell -- N40, an egg's development percent, and so on. Off keeps the colour coding but drops the numbers, for a quieter comb at a glance. Applies within about a second, as cells redraw themselves.",
	},
	{
		"persist": "player",
		"key": "use_cell_sprites", "label": "Cell art", "toggle": true,
		"category": "Appearance",
		"tip": "Draw the comb as wax-cell art -- how full each store is, the brood growing and the wax caps going on -- instead of the original flat colour fill. Off reverts to the flat fill. Applies within about a second, as cells redraw themselves.",
	},
	{
		"persist": "player",
		"key": "use_sprite_hex_grid", "label": "Sprite-aligned hex grid", "toggle": true,
		"category": "Appearance",
		"tip": "Draw the whole hive -- comb, floor, soil, bedrock, the entrance tunnel -- squashed 2:1 to match the cell resprite's shape, instead of as a regular hexagon. Off restores the original hex grid. Takes effect on Restart Run.",
	},
	{
		"persist": "player",
		"key": "use_radial_hex_speed", "label": "Direction-even hex speed", "toggle": true,
		"category": "Appearance",
		"tip": "On the squashed hex grid, make a bee take the same time to cross one hex-edge in any of the six directions. Off reproduces the older behaviour, where speed is constant in squashed screen pixels and vertical travel is faster than sideways travel. Applies immediately; only matters while Sprite-aligned hex grid is on.",
	},
	{
		"persist": "player",
		"key": "show_recruitment_highlight", "label": "Highlight recruitment dances", "toggle": true,
		"category": "Appearance",
		"tip": "Ring the two bees in a recruitment dance so the pair can be found in a crowd on the comb -- the mentor in warm yellow, the struggling forager she is dancing at in cool blue. The rings appear when the dance starts and vanish the moment it ends. Off costs nothing and is the default; it changes nothing about recruitment itself, only whether you can see it happen.",
	},

	# --- Brood & the queen ---
	{
		"persist": "run",
		"key": "egg_pollen_cost", "label": "Pollen per egg", "step": 5.0, "min": 1.0,
		"category": "Brood & the queen",
		"tip": "Pollen the queen must eat before she can lay one egg. This is the link between foraging and colony growth.",
	},
	{
		"persist": "run",
		"key": "queen_eat_rate", "label": "Queen eat/s", "step": 1.0, "min": 0.1,
		"category": "Brood & the queen",
		"tip": "Pollen the queen consumes per second while feeding from a cell.",
	},
	{
		"persist": "run",
		"key": "queen_speed_factor", "label": "Queen speed x", "step": 0.05, "min": 0.05,
		"category": "Brood & the queen",
		"tip": "The queen's speed as a multiple of a worker's. She is larger, so she is slower.",
	},
	{
		"persist": "run",
		"key": "lay_weight_low", "label": "Lay weight — low", "step": 1.0, "min": 0.0,
		"category": "Brood & the queen",
		"tip": "How much of the queen's laying a low-priority nursery cell gets, relative to the other two tiers. The three weights are a ratio, not percentages: 1 : 2 : 3 means a high cell receives three eggs for every one a low cell receives. Set a weight to zero to stop that tier being laid in at all.",
	},
	{
		"persist": "run",
		"key": "lay_weight_medium", "label": "Lay weight — medium", "step": 1.0, "min": 0.0,
		"category": "Brood & the queen",
		"tip": "The middle tier's share of the queen's laying. This is the default a cell gets when you first put it in the nursery zone.",
	},
	{
		"persist": "run",
		"key": "lay_weight_high", "label": "Lay weight — high", "step": 1.0, "min": 0.0,
		"category": "Brood & the queen",
		"tip": "The top tier's share. Widening the gap between this and the low weight makes the zone a blunter instrument -- fewer cells needed to skew the mix, but less room for fine adjustment.",
	},
	{
		"persist": "none",
		"key": "queen_lays_in_any_cell", "label": "Lay in plain comb", "toggle": true,
		"category": "Brood & the queen",
		"tip": "On: once every nursery cell is full the queen falls back to any spare undesignated cell, so laying never stalls. Off: she lays only where you have asked her to, and waits otherwise. The same switch appears on the queen's own panel when she is laying.",
	},
	{
		"persist": "none",
		"key": "emergence_window_seconds", "label": "Emergence window s", "step": 30.0, "min": 30.0,
		"category": "Brood & the queen",
		"tip": "How long a stretch the nursery window's \"emerging per minute\" figures cover. Longer is steadier but slower to show the effect of a change you just made.",
	},
	{
		"persist": "run",
		"key": "brood_develop_time", "label": "Brood time s", "step": 10.0, "min": 5.0,
		"category": "Brood & the queen",
		"tip": "Seconds of development a larva needs before it emerges. This clock only runs while the larva has food in it, so brood in an unnursed colony simply stops.",
	},
	{
		"persist": "run",
		"key": "brood_feed_seconds", "label": "Feed lasts s", "step": 5.0, "min": 1.0,
		"category": "Brood & the queen",
		"tip": "How many seconds of development one feed of pollen and nectar buys a larva. When it runs out the larva stops developing until a nurse comes back.",
	},
	{
		"persist": "run",
		"key": "brood_feed_seconds_honey", "label": "Honey feed s", "step": 5.0, "min": 1.0,
		"category": "Brood & the queen",
		"tip": "As above, but for a feed of pollen and honey. Honey is denser, so it carries the larva further -- which is much of the point of making it.",
	},
	{
		"persist": "run",
		"key": "brood_feed_pollen", "label": "Pollen per feed", "step": 1.0, "min": 0.0,
		"category": "Brood & the queen",
		"tip": "Pollen a nurse drops into a cell per feed. Pollen is the protein and is needed for every feed, whatever the carbohydrate.",
	},
	{
		"persist": "run",
		"key": "brood_feed_nectar", "label": "Nectar per feed", "step": 1.0, "min": 0.0,
		"category": "Brood & the queen",
		"tip": "Nectar used per feed when the colony has no honey to hand.",
	},
	{
		"persist": "none",
		"key": "brood_feed_bee_bread", "label": "Bee bread per feed", "step": 0.5, "min": 0.5,
		"category": "Brood & the queen",
		"tip": "Ripe bee bread a nurse feeds a worker larva in place of pollen, per feed. Nurses use it whenever the colony has some ripe; a larva given any emerges raised on bee bread.",
	},
	{
		"persist": "run",
		"key": "brood_feed_honey", "label": "Honey per feed", "step": 0.5, "min": 0.0,
		"category": "Brood & the queen",
		"tip": "Honey used per feed. Less than the nectar equivalent, and it lasts the larva longer.",
	},
	{
		"persist": "run",
		"key": "brood_feed_threshold", "label": "Top up below s", "step": 1.0, "min": 0.0,
		"category": "Brood & the queen",
		"tip": "A nurse tops a larva back up once its remaining food drops below this, rather than waiting for it to stall completely.",
	},
	{
		"persist": "run",
		"key": "larva_death_seconds", "label": "Starves after s", "step": 10.0, "min": 10.0,
		"category": "Brood & the queen",
		"tip": "How long a larva survives with nothing to eat before it dies. The body then blocks the cell until a comb worker on cell maintenance clears it out and carries it away, so neglect costs you the cell as well as the bee.",
	},
	{
		"persist": "run",
		"key": "cell_clean_time", "label": "Clearing s", "step": 5.0, "min": 1.0,
		"category": "Brood & the queen",
		"tip": "Comb-worker seconds needed to clear a dead larva out of a cell. Several working the same cell share it.",
	},
	{
		"persist": "run",
		"key": "nurse_carry_feeds", "label": "Feeds carried", "step": 1.0, "min": 1.0,
		"category": "Brood & the queen",
		"tip": "How many complete meals a nurse loads up with in one visit to the stores. She walks to a pollen cell and then a nectar or honey cell to fill up, and feeds larvae from what she is carrying -- higher values mean fewer trips back to the comb.",
	},
	{
		"persist": "run",
		"key": "nurse_load_time", "label": "Loading s", "step": 0.5, "min": 0.0,
		"category": "Brood & the queen",
		"tip": "Seconds a nurse spends at a cell filling up with food for the brood.",
	},
	{
		"persist": "run",
		"key": "tending_speed_bonus", "label": "Tending bonus", "step": 0.5, "min": 1.0,
		"category": "Brood & the queen",
		"tip": "Development speed multiplier while a nursery bee is standing over the cell. It only multiplies time the larva has food for -- tending an unfed larva does nothing.",
	},

	# --- Honey ---
	{
		"persist": "run",
		"key": "honey_cell_capacity", "label": "Honey per cell", "step": 10.0, "min": 1.0,
		"category": "Honey",
		"tip": "How much honey one cell holds. Honey is stored separately from raw nectar so the two can be tuned apart.",
	},
	{
		"persist": "run",
		"key": "honey_energy_factor", "label": "Honey energy x", "step": 0.5, "min": 1.0,
		"category": "Honey",
		"tip": "How many times more energy a unit of honey gives a bee than a unit of nectar. This is why a colony bothers converting: the same cell feeds several times as many bees.",
	},
	{
		"persist": "run",
		"key": "nectar_per_honey", "label": "Nectar per honey", "step": 0.5, "min": 1.0,
		"category": "Honey",
		"tip": "Units of nectar consumed to make one unit of honey mix. At the honey energy multiplier, conversion makes honey denser without gaining or losing energy.",
	},
	{
		"persist": "run",
		"key": "honey_chew_time", "label": "Chewing s", "step": 1.0, "min": 0.0,
		"category": "Honey",
		"tip": "Seconds a honey maker spends working enzymes into a load of nectar before it can spit the mix into a cell.",
	},
	{
		"persist": "run",
		"key": "honey_ripen_time", "label": "Fanning s", "step": 5.0, "min": 1.0,
		"category": "Honey",
		"tip": "Bee-seconds of wing-fanning needed to evaporate the water out of one cell of mix. Several bees fanning the same cell share the work. Until it is done the cell holds wet mix, not honey, and nobody can eat it.",
	},
	{
		"persist": "run",
		"key": "honey_rewet_factor", "label": "Re-wet x", "step": 0.1, "min": 0.0,
		"category": "Honey",
		"tip": "Adding fresh wet mix to a part-dried cell sets its drying back to this fraction of the progress it had. Low values make topping cells up expensive.",
	},
	{
		"persist": "none",
		"key": "nectar_ferment_hours", "label": "Nectar ferments h", "step": 6.0, "min": 1.0,
		"category": "Honey",
		"tip": "In-game hours raw nectar can sit in a cell before it ferments and turns murky. Honey makers cannot use fermented nectar. Topping a cell up keeps the age of its oldest nectar, so only emptying the cell resets it.",
	},
	{
		"persist": "none",
		"key": "tipsy_seconds", "label": "Tipsy for s", "step": 5.0, "min": 1.0,
		"category": "Honey",
		"tip": "Seconds a bee stays tipsy after eating fermented nectar. Eating more while tipsy starts the count again rather than adding to it.",
	},
	{
		"persist": "none",
		"key": "tipsy_speed_factor", "label": "Tipsy speed x", "step": 0.05, "min": 0.05,
		"category": "Honey",
		"tip": "A tipsy bee moves at this fraction of its normal speed, indoors and out.",
	},
	{
		"persist": "none",
		"key": "tipsy_vision_factor", "label": "Tipsy sight x", "step": 0.05, "min": 0.05,
		"category": "Honey",
		"tip": "A tipsy forager spots flowers from only this fraction of the usual distance, so it searches longer for each one.",
	},
	{
		"persist": "none",
		"key": "tipsy_wobble_degrees", "label": "Tipsy wobble deg", "step": 5.0, "min": 0.0,
		"category": "Honey",
		"tip": "How far either side of its course a tipsy bee's flight swings. Wider wobbles waste more of every trip.",
	},
	{
		"persist": "none",
		"key": "tipsy_wander_chance", "label": "Tipsy wander /s", "step": 0.01, "min": 0.0,
		"category": "Honey",
		"tip": "Chance per second that a tipsy bee working in the hive stops partway through its task and wanders off confused.",
	},
	{
		"persist": "none",
		"key": "tipsy_wander_seconds", "label": "Tipsy wander s", "step": 1.0, "min": 0.5,
		"category": "Honey",
		"tip": "How long one confused wander lasts before the bee walks back and carries on with its task.",
	},

	# --- Gynes & royal jelly ---
	{
		"persist": "run",
		"key": "gyne_egg_pollen_cost", "label": "Pollen per gyne", "step": 10.0, "min": 1.0,
		"category": "Gynes & royal jelly",
		"tip": "Pollen the queen must eat before she can lay a gyne, as opposed to a worker. This is the up-front cost of deciding to raise a future queen.",
	},
	{
		"persist": "run",
		"key": "gyne_develop_multiplier", "label": "Gyne time x", "step": 0.5, "min": 1.0,
		"category": "Gynes & royal jelly",
		"tip": "How much longer a gyne takes to develop than a worker. She has to be fed the whole way, so this is also how much more nursing she costs.",
	},
	{
		"persist": "run",
		"key": "gyne_speed_factor", "label": "Gyne speed x", "step": 0.05, "min": 0.1,
		"category": "Gynes & royal jelly",
		"tip": "A gyne's movement speed as a multiple of a worker's. She is a bigger animal, so she is slower.",
	},
	{
		"persist": "run",
		"key": "gyne_energy_factor", "label": "Gyne energy x", "step": 0.05, "min": 1.0,
		"category": "Gynes & royal jelly",
		"tip": "How much more energy a gyne burns than a worker, both at rest and in flight.",
	},
	{
		"persist": "run",
		"key": "gyne_size_factor", "label": "Gyne size x", "step": 0.05, "min": 1.0,
		"category": "Gynes & royal jelly",
		"tip": "How large a gyne is drawn relative to a worker, so you can pick one out of a crowd. The queen is about 1.55.",
	},
	{
		"persist": "run",
		"key": "brood_feed_jelly", "label": "Jelly per feed", "step": 0.5, "min": 0.0,
		"category": "Gynes & royal jelly",
		"tip": "Royal jelly a nurse puts into a gyne larva per feed. Gyne larvae take jelly with pollen and honey and will not accept nectar.",
	},
	{
		"persist": "run",
		"key": "brood_feed_seconds_gyne", "label": "Gyne feed s", "step": 5.0, "min": 1.0,
		"category": "Gynes & royal jelly",
		"tip": "How many seconds of development one royal jelly feed buys a gyne larva.",
	},
	{
		"persist": "run",
		"key": "jelly_pollen_cost", "label": "Jelly: pollen", "step": 1.0, "min": 0.0,
		"category": "Gynes & royal jelly",
		"tip": "Pollen a nurse eats to make one batch of royal jelly.",
	},
	{
		"persist": "run",
		"key": "jelly_honey_cost", "label": "Jelly: honey", "step": 1.0, "min": 0.0,
		"category": "Gynes & royal jelly",
		"tip": "Honey a nurse eats to make one batch of royal jelly. Jelly needs honey specifically, so a colony has to be making honey before it can raise gynes.",
	},
	{
		"persist": "run",
		"key": "jelly_make_time", "label": "Jelly make s", "step": 1.0, "min": 1.0,
		"category": "Gynes & royal jelly",
		"tip": "Seconds a nurse spends working pollen and honey into a batch of royal jelly.",
	},
	{
		"persist": "run",
		"key": "jelly_per_batch", "label": "Jelly per batch", "step": 1.0, "min": 1.0,
		"category": "Gynes & royal jelly",
		"tip": "How much royal jelly one batch produces.",
	},
	{
		"persist": "run",
		"key": "jelly_cell_capacity", "label": "Jelly per cell", "step": 10.0, "min": 1.0,
		"category": "Gynes & royal jelly",
		"tip": "How much royal jelly a single cell holds.",
	},

	# --- Bee bread (BB-1), listed under Honey: honey workers make it ---
	{
		"persist": "none",
		"key": "bee_bread_pollen_per_load", "label": "Bee bread: pollen", "step": 1.0, "min": 0.0,
		"category": "Honey",
		"tip": "Pollen a Fermenting honey worker takes from the comb for one load of bee bread.",
	},
	{
		"persist": "none",
		"key": "bee_bread_honey_per_load", "label": "Bee bread: honey", "step": 1.0, "min": 0.0,
		"category": "Honey",
		"tip": "Ripe honey a Fermenting honey worker takes from the comb for one load of bee bread. Wet honey still being fanned will not do.",
	},
	{
		"persist": "none",
		"key": "bee_bread_per_load", "label": "Bee bread per load", "step": 1.0, "min": 1.0,
		"category": "Honey",
		"tip": "How much bee bread one load packs into its cell.",
	},
	{
		"persist": "none",
		"key": "bee_bread_cell_capacity", "label": "Bee bread per cell", "step": 10.0, "min": 1.0,
		"category": "Honey",
		"tip": "How much bee bread a single cell holds. A cell seals once it is full and takes no more.",
	},
	{
		"persist": "none",
		"key": "bee_bread_ripen_hours", "label": "Bee bread ripens h", "step": 6.0, "min": 1.0,
		"category": "Honey",
		"tip": "In-game hours a sealed cell of bee bread takes to ripen. Until then it is neither food nor something you can spend.",
	},

	# --- Weather ---
	{
		"persist": "run",
		"key": "weather_on", "label": "Weather on", "toggle": true,
		"category": "Weather",
		"tip": "Turn rain on or off. With it off the meadow stays dry indefinitely, which is easier but removes the main reason to keep stores in the comb.",
	},
	{
		"persist": "run",
		"key": "rain_chance_per_day", "label": "Rain chance/day", "step": 0.05, "min": 0.0,
		"category": "Weather",
		"tip": "Roughly how often a day brings rain.",
	},
	{
		"persist": "run",
		"key": "rain_min_seconds", "label": "Rain min s", "step": 10.0, "min": 5.0,
		"category": "Weather",
		"tip": "Shortest a shower lasts.",
	},
	{
		"persist": "run",
		"key": "rain_max_seconds", "label": "Rain max s", "step": 10.0, "min": 5.0,
		"category": "Weather",
		"tip": "Longest a shower lasts. A long one on a colony with no stores is how a run ends.",
	},
	{
		"persist": "run",
		"key": "rain_nectar_dilution", "label": "Nectar diluted", "step": 0.05, "min": 0.0,
		"category": "Weather",
		"tip": "How much of nectar's value is washed out of an open flower at full rain. A wet day's foraging brings home less from the same volume.",
	},
	{
		"persist": "run",
		"key": "rain_flight_burn_factor", "label": "Wet flight x", "step": 0.1, "min": 1.0,
		"category": "Weather",
		"tip": "How much more flying costs at full rain. A wet bee carries the water as dead weight.",
	},
	{
		"persist": "run",
		"key": "rain_forage_limit", "label": "Ground above", "step": 0.05, "min": 0.05,
		"category": "Weather",
		"tip": "Rain intensity past which a trip costs more than it brings back, so foragers stay at the hive until it eases.",
	},
	# FC-2: the Colony Run's first crisis. Saved with the run (Dave, 17 Oct
	# 2026), with save_migrations.gd's 6->7 step for an older save.
	{
		"persist": "run",
		"key": "first_crisis_window_open", "label": "Crisis window opens s", "step": 30.0, "min": 0.0,
		"category": "Weather",
		"tip": "Seconds of play before the Colony Run's first heavy-rain crisis can be announced. A colony ready by then is warned straight away.",
	},
	{
		"persist": "run",
		"key": "first_crisis_window_close", "label": "Crisis window closes s", "step": 30.0, "min": 60.0,
		"category": "Weather",
		"tip": "Seconds of play by which the first crisis's rain has started, ready or not. A colony not ready a warning lead before this is warned then.",
	},
	{
		"persist": "run",
		"key": "first_crisis_warning_lead", "label": "Crisis warning lead s", "step": 10.0, "min": 10.0,
		"category": "Weather",
		"tip": "How long the first crisis's warning comes before its rain: time to put a worker on foraging and get a trip home.",
	},
	{
		"persist": "run",
		"key": "first_crisis_check_seconds", "label": "Crisis readiness check s", "step": 0.5, "min": 0.5,
		"category": "Weather",
		"tip": "How often, inside the window, the game checks whether the colony is ready for the first crisis.",
	},

	# --- Seasons & health ---
	{
		"persist": "run",
		"key": "seasons_on", "label": "Flowering seasons", "toggle": true,
		"category": "Seasons & health",
		"tip": "Species come into flower at different times of the year, so the best ground moves through a run. Poppy is early and is the only pollen worth having before the borage arrives; foxglove has a short rich window in midsummer; clover carries most of the year. With this off everything flowers all the time. Takes effect immediately.",
	},
	{
		"persist": "run",
		"key": "season_length_days", "label": "Playable season days", "step": 5.0, "min": 15.0,
		"category": "Seasons & health",
		"tip": "How long spring through autumn last before winter. Shorter means the flowering windows come round faster and the colony has less time in each.",
	},
	{
		"persist": "none",
		"key": "peak_season_strength", "label": "Peak season strength", "step": 0.05, "min": 0.1, "max": 1.5,
		"category": "Seasons & health",
		"tip": "What a species reaches at the very middle of its own flowering window, as a multiple of its nominal recharge rate. Lower narrows the gap between peak and out-of-season flowering.",
	},
	{
		"persist": "run",
		"key": "disease_on", "label": "Pathogens", "toggle": true,
		"category": "Seasons & health",
		"tip": "Pressure builds in a hive with dead larvae left in it and in one that is crowded, and it slows brood development and shortens bee lifespans. This is what turns clearing from tidying into work worth doing before you need it -- the cost of ignoring it arrives later and all at once.",
	},
	{
		"persist": "none",
		"key": "disease_threshold", "label": "Harmless below", "step": 0.05, "min": 0.0,
		"category": "Seasons & health",
		"tip": "Pressure below this does nothing at all. A basically clean colony should not be paying a constant tax; the cost has to arrive as a consequence of neglect.",
	},
	{
		"persist": "none",
		"key": "disease_per_corpse", "label": "Per body/s", "step": 0.0005, "min": 0.0,
		"category": "Seasons & health",
		"tip": "How fast pressure builds per dead larva left in the comb. This is the number that decides how urgent clearing is.",
	},
	{
		"persist": "none",
		"key": "max_hive_bodies", "label": "Most bodies", "step": 1.0, "min": 0.0,
		"category": "Seasons & health",
		"tip": "The most dead bees that can lie on the hive floor at once; past it the oldest goes. Each counts towards disease like a dead larva until a Comb worker with Cleaning carries it out. A safety cap, set well above what a colony normally holds.",
	},
	{
		"persist": "none",
		"key": "disease_recovery", "label": "Recovery/s", "step": 0.0002, "min": 0.0,
		"category": "Seasons & health",
		"tip": "How fast pressure falls once the cause is dealt with. If clearing a backlog feels like it never helps, raise this.",
	},
	{
		"persist": "none",
		"key": "disease_brood_penalty", "label": "Brood penalty", "step": 0.05, "min": 0.0,
		"category": "Seasons & health",
		"tip": "How much slower brood develops at full pressure.",
	},
	{
		"persist": "none",
		"key": "disease_lifespan_penalty", "label": "Lifespan penalty", "step": 0.05, "min": 0.0,
		"category": "Seasons & health",
		"tip": "How much of its lifespan a bee loses at full pressure.",
	},
	{
		"persist": "none",
		"key": "gyne_release_energy", "label": "Gyne needs", "step": 0.05, "min": 0.0,
		"category": "Seasons & health",
		"tip": "How full a gyne's crop has to be before you can send her to found a colony, as a share of capacity. She is founding a colony on what she carries.",
	},
	{
		"persist": "none",
		"key": "genetic_points_per_gyne", "label": "Gyne points", "step": 1.0, "min": 0.0,
		"category": "Seasons & health",
		"tip": "The genetic points a gyne earns when you send her out in mid summer. She earns less either side of it, and nothing outside late spring to early autumn, when she finds no mate and is lost.",
	},
	{
		"persist": "none",
		"key": "nuptial_flight_peak_chance", "label": "Mating chance", "step": 0.05, "min": 0.0, "max": 1.0,
		"category": "Seasons & health",
		"tip": "The chance an unmated queen finds a mate on one nuptial flight in mid summer. It falls away either side and is nothing outside late spring to early autumn. Each flight takes her out of the hive for part of a day, so a lower chance means more days without new workers.",
	},

	# --- Winter ---
	{
		"persist": "run",
		"key": "winter_countdown_days", "label": "Winter in days", "step": 1.0, "min": 1.0, "max": 15.0,
		"category": "Winter",
		"tip": "How many in-game days before each winter its countdown opens. Fifteen is enough to change what you are doing without being so far off that it stops mattering.",
	},
	{
		"persist": "run",
		"key": "winter_length_days", "label": "Winter lasts days", "step": 1.0, "min": 1.0,
		"category": "Winter",
		"tip": "How long the winter will be. This is what the required-stores figure is calculated from, so it is the main dial for how hard surviving one is.",
	},
	{
		"persist": "none",
		"key": "spring_regrowth_days", "label": "Spring regrowth days", "step": 0.5, "min": 0.0,
		"category": "Winter",
		"tip": "How many days the meadow takes to flower again after a winter. The plants die back over winter; for this long after it, flowers recover from nothing to full strength.",
	},
	{
		"persist": "run",
		"key": "winter_burn_factor", "label": "Winter burn x", "step": 0.05, "min": 0.05,
		"category": "Winter",
		"tip": "What a bee burns per second through the winter, as a multiple of its ordinary rate. Below one because a clustered colony is doing very little. Tune this first if the winter target feels trivial or impossible.",
	},
	{
		"persist": "run",
		"key": "winter_lifespan_factor", "label": "Winter lifespan x", "step": 0.25, "min": 1.0,
		"category": "Winter",
		"tip": "How much longer a bee's natural lifespan runs through the winter, as a multiple of its ordinary one. Above one because a dormant, clustered bee wears out slower -- without this, bees can die of old age mid-winter even when perfectly fed.",
	},
	{
		"persist": "none",
		"key": "winter_unclustered_multiplier", "label": "Unclustered winter x", "step": 0.25, "min": 1.0,
		"category": "Winter",
		"tip": "What the winter bill is multiplied by while the colony has not learned Shiver Cluster. One makes the skill change nothing.",
	},
	{
		"persist": "none",
		"key": "winter_unclustered_warning_days", "label": "Shiver warning days", "step": 1.0, "min": 0.0,
		"category": "Winter",
		"tip": "How many of the winter countdown's last days the problem strip warns that the colony has not learned Shiver Cluster.",
	},

	# --- The rival colony ---
	{
		"persist": "run",
		"key": "rival_hive_on", "label": "Rival colony", "toggle": true,
		"category": "The rival colony",
		"tip": "Put a second colony in the meadow, run by the game. It isn't a copy of your simulation -- that would double the cost of the game for something you can't watch -- but an abstract colony with a few visible foragers that take nectar from the same real flowers you do. There is no combat: the pressure is entirely economic. Takes effect on Restart Run.",
	},
	{
		"persist": "none",
		"key": "rival_starting_bees", "label": "Rival start bees", "step": 1.0, "min": 1.0,
		"category": "The rival colony",
		"tip": "How big the rival colony is when a run begins. Takes effect on Restart Run.",
	},
	{
		"persist": "none",
		"key": "rival_max_bees", "label": "Rival max bees", "step": 5.0, "min": 1.0,
		"category": "The rival colony",
		"tip": "The most bees the rival can ever reach. This is the main dial for how much competition it eventually represents.",
	},
	{
		"persist": "none",
		"key": "rival_min_distance", "label": "Rival distance", "step": 50.0, "min": 100.0,
		"category": "The rival colony",
		"tip": "How far from your hive the rival is placed. Far enough that you aren't fighting over the same flowers on day one; the two colonies meet in the middle later as both grow. Takes effect on Restart Run.",
	},
	{
		"persist": "none",
		"key": "rival_forage_range", "label": "Rival range", "step": 20.0, "min": 50.0,
		"category": "The rival colony",
		"tip": "How far the rival's foragers will travel. Raising it makes the two colonies overlap sooner.",
	},
	{
		"persist": "none",
		"key": "rival_crowding_scale", "label": "Rival crowding", "step": 5.0, "min": 1.0,
		"category": "The rival colony",
		"tip": "How much the rival's bees get in each other's way. More bees working the same patch of meadow get less each, which is what gives the colony a size that depends on the forage rather than always growing to its cap. Lower means the meadow supports fewer of them. Simulated over 200 days, this is the dial that decides whether squeezing the rival visibly shrinks it or does nothing at all.",
	},
	{
		"persist": "none",
		"key": "rival_brood_gate_days", "label": "Rival grows above", "step": 5.0, "min": 1.0,
		"category": "The rival colony",
		"tip": "How many days of food in hand the rival wants before it will raise brood. Growing on an empty larder made it boom and then starve; waiting until it has a margin is what makes it settle at a steady size instead.",
	},
	{
		"persist": "none",
		"key": "rival_flower_take", "label": "Rival take/visit", "step": 0.5, "min": 0.0,
		"category": "The rival colony",
		"tip": "Nectar one rival forager removes from a flower per visit. This is the only way the rival touches your world, so it is what turns it from scenery into competition. Set it to zero to have a neighbour that doesn't compete at all.",
	},

	# --- Predators ---
	{
		"persist": "run",
		"key": "predators_on", "label": "Crab spiders", "toggle": true,
		"category": "Predators",
		"tip": "Ambush predators that sit motionless on flowers of one species (rolled per run) and occasionally kill a forager that starts feeding. Off by default -- the whole feature stays off until you turn it on to test. Everything else in this section only matters once this is on.",
	},
	{
		"persist": "none",
		"key": "crab_spider_flower_fraction", "label": "Spider chance/flower", "step": 0.005, "min": 0.0,
		"category": "Predators",
		"tip": "Chance a newly created or regrown flower of the dangerous species gets a spider. At the default flower count and clover's share of the species mix, the starting guess of 0.02 puts roughly 4 spiders in the meadow at once. Only matters when Crab spiders is on.",
	},
	{
		"persist": "run",
		"key": "crab_spider_attack_success_chance", "label": "Spider attack success", "step": 0.01, "min": 0.0,
		"category": "Predators",
		"tip": "Chance a spider actually catches a bee that starts feeding at its flower, rather than her narrowly escaping. Starting guess is 0.05 (5%) -- most attacks in real life miss too. Only matters when Crab spiders is on.",
	},
	{
		"persist": "none",
		"key": "crab_spider_residency_seconds", "label": "Spider residency s", "step": 30.0, "min": 10.0,
		"category": "Predators",
		"tip": "How long a spider stays on one flower before relocating to another of the same species. It also relocates immediately, without waiting this long, if its flower dies first. Only matters when Crab spiders is on.",
	},
	{
		"persist": "none",
		"key": "crab_spider_reveal_seconds", "label": "Spider reveal s", "step": 0.5, "min": 0.1,
		"category": "Predators",
		"tip": "How long a spider stays visible after an attack or a relocation before fading from view again. It's otherwise invisible. Only matters when Crab spiders is on.",
	},
	{
		"persist": "player",
		"key": "show_crab_spiders", "label": "Always show spiders (dev)", "toggle": true,
		"category": "Predators",
		"tip": "Dev-only: marks every crab spider's flower with a large bright ring, rather than only flashing the tiny in-play marker on an attack or a relocation. For finding spiders to test spawning and movement before anything dangerous is worth watching for.",
	},
	{
		"persist": "none",
		"key": "crab_spider_recruit_suppression_on", "label": "Suppress recruitment after escape", "toggle": true,
		"category": "Predators",
		"tip": "A forager who escapes an attack stops recruiting entrance mentors towards wherever she was foraging at the time -- until she moves on herself (a re-scout, a new preferred species, being mentored). She can still forage and still ask for help throughout; this only ever holds back her own recruiting. Only matters when Crab spiders is on.",
	},
	{
		"persist": "none",
		"key": "alarm_pheromone_on", "label": "Alarm pheromone (placeholder)", "toggle": true,
		"category": "Predators",
		"tip": "Placeholder -- will move to a skill unlock once the skill tree exists. While on, a bee that lands at a flower another bee was recently attacked at (hit or miss) notices and leaves before ever risking a feed there -- a brief orange ring flashes on her when this fires, same as an attack flashes on a flower. Only matters when Crab spiders is on.",
	},
	{
		"persist": "none",
		"key": "crab_spider_alarm_marker_seconds", "label": "Alarm marker s", "step": 5.0, "min": 5.0,
		"category": "Predators",
		"tip": "How long a flower stays marked as alarmed after an attack there. Only matters when Crab spiders and Alarm pheromone are both on.",
	},

	# --- Mining ---
	{
		"persist": "run",
		"key": "block_mine_time", "label": "Block dig s", "step": 10.0, "min": 5.0,
		"category": "Mining",
		"tip": "Miner-seconds needed to break down one soil block. Several miners on one block share the work, exactly like builders on a cell.",
	},
	{
		"persist": "run",
		"key": "miner_dirt_capacity", "label": "Dirt capacity", "step": 5.0, "min": 1.0,
		"category": "Mining",
		"tip": "How much spoil a miner can hold before it has to carry it outside. Real excavation does not vanish.",
	},
	{
		"persist": "run",
		"key": "dirt_fill_rate", "label": "Dirt/s", "step": 0.1, "min": 0.0,
		"category": "Mining",
		"tip": "Spoil a miner accumulates per second while digging.",
	},
	{
		"persist": "run",
		"key": "dirt_dump_time", "label": "Dumping s", "step": 0.5, "min": 0.0,
		"category": "Mining",
		"tip": "Seconds a miner spends outside the hive emptying a load of spoil.",
	},

	# --- Bee life ---
	{
		"persist": "none",
		"key": "starter_age_spread", "label": "Starting age spread", "step": 0.1, "min": 0.0, "max": 0.9,
		"category": "Bee life",
		"tip": "Starting bees begin at a random age up to this fraction of their lifespan, so the founders do not all die of old age together. 0 starts every one newly hatched.",
	},
	{
		"persist": "run",
		"key": "bee_lifespan_days", "label": "Lifespan days", "step": 5.0, "min": 1.0,
		"category": "Bee life",
		"tip": "In-game days a bee lives before dying of old age. The queen is exempt -- losing her would silently end the colony.",
	},
	# --- a worker's outcome (BB-2): fixed when she emerges, saved with her ---
	{
		"persist": "none",
		"key": "bee_bread_raised_lifespan_factor", "label": "Bee bread: lifespan x", "step": 0.05, "min": 0.05,
		"category": "Bee life",
		"tip": "Multiplies Lifespan days for a worker raised on bee bread. 1.0 is the full 25 days. Founding bees, and bees from a save made before bee bread nursing, live Lifespan days.",
	},
	{
		"persist": "none",
		"key": "bee_bread_raised_stat_factor", "label": "Bee bread: speed and load", "step": 0.05, "min": 0.1,
		"category": "Bee life",
		"tip": "Multiplies the speed and carrying capacity of a worker raised on bee bread. 1.05 is 105%.",
	},
	{
		"persist": "none",
		"key": "pollen_raised_lifespan_factor", "label": "Pollen only: lifespan x", "step": 0.05, "min": 0.05,
		"category": "Bee life",
		"tip": "Multiplies Lifespan days for a worker raised only on pollen. 0.6 is 15 of the 25 days.",
	},
	{
		"persist": "none",
		"key": "pollen_raised_stat_factor", "label": "Pollen only: speed and load", "step": 0.05, "min": 0.1,
		"category": "Bee life",
		"tip": "Multiplies the speed and carrying capacity of a worker raised only on pollen. 0.95 is 95%.",
	},
	{
		"persist": "run",
		"key": "energy_capacity", "label": "Energy cap", "step": 10.0, "min": 10.0,
		"category": "Bee life",
		"tip": "Maximum energy a bee holds. Bees dim as this runs down and die at zero.",
	},
	{
		"persist": "run",
		"key": "energy_burn_rate", "label": "Energy burn/s", "step": 0.1, "min": 0.0,
		"category": "Bee life",
		"tip": "Energy every bee burns per second just by being alive. Bees refuel from the comb, eating honey first where there is any.",
	},
	{
		"persist": "run",
		"key": "flight_energy_burn", "label": "Flight burn/s", "step": 0.05, "min": 0.0,
		"category": "Bee life",
		"tip": "Extra energy a bee burns per second while actually flying, on top of simply being alive. This is what makes a distant patch cost something to work.",
	},
	{
		"persist": "run",
		"key": "forager_drink_threshold", "label": "Drink below", "step": 0.05, "min": 0.05,
		"category": "Bee life",
		"tip": "How low a forager's energy gets before it drinks nectar straight from the flower it has landed on, rather than flying home. Every forager does this, including pollen foragers.",
	},
	{
		"persist": "run",
		"key": "nectar_drink_rate", "label": "Drink rate/s", "step": 1.0, "min": 0.5,
		"category": "Bee life",
		"tip": "How quickly a bee takes nectar on board while drinking, at a flower or from its own crop.",
	},
	{
		"persist": "run",
		"key": "crop_drink_threshold", "label": "Crop below", "step": 0.05, "min": 0.0,
		"category": "Bee life",
		"tip": "How low a nectar forager gets before it starts metabolising the load in its own crop rather than landing. That comes off the delivery, so a bee doing it often is ranging further than the patch is worth.",
	},
	{
		"persist": "run",
		"key": "hunger_threshold", "label": "Eat below", "step": 0.05, "min": 0.05,
		"category": "Bee life",
		"tip": "How low a bee's energy has to fall, as a fraction of its capacity, before it breaks off what it is doing and walks to a cell to eat. Eating is a real trip now, so a low value means bees run leaner but lose less time.",
	},
	{
		"persist": "run",
		"key": "bee_eat_rate", "label": "Eating rate/s", "step": 1.0, "min": 0.5,
		"category": "Bee life",
		"tip": "Energy a bee takes on per second while feeding at a cell. Honey supplies this from far fewer units than nectar does.",
	},
	{
		"persist": "none",
		"key": "bumble_flight_on", "label": "Bumble flight", "toggle": true,
		"category": "Bee life",
		"tip": "Outdoor flying bees drift on a small side-to-side wander instead of beelining, so movement reads as bee-like. Purely visual -- never changes where a bee is or how fast it gets there.",
	},
	{
		"persist": "none",
		"key": "bumble_flight_amplitude", "label": "Wander amplitude", "step": 1.0, "min": 0.0,
		"category": "Bee life",
		"tip": "How far side to side the wander drifts, in pixels. Only matters when Bumble flight is on.",
	},
	{
		"persist": "none",
		"key": "bumble_flight_frequency", "label": "Wander speed", "step": 0.1, "min": 0.1,
		"category": "Bee life",
		"tip": "How fast the wander oscillates, in radians per second. Higher is twitchier. Only matters when Bumble flight is on.",
	},
	{
		"persist": "none",
		"key": "bumble_flight_settle_seconds", "label": "Wander settle s", "step": 0.05, "min": 0.05,
		"category": "Bee life",
		"tip": "How long the visual offset takes to ease in when a bee starts flying outdoors, and back out when it lands -- this is what stops a landing bee snapping onto the flower. Only matters when Bumble flight is on.",
	},

	# --- Interface ---
	{
		"persist": "none",
		"key": "history_sample_seconds", "label": "History sample s", "step": 1.0, "min": 1.0,
		"category": "Interface",
		"tip": "How often the colony window's over-time plot takes a reading. Together with the number of points below, this sets how far back the plot reaches.",
	},
	{
		"persist": "none",
		"key": "history_points", "label": "History points", "step": 10.0, "min": 10.0,
		"category": "Interface",
		"tip": "How many readings the plot keeps. Sample seconds multiplied by this is the span it covers, in in-game seconds.",
	},
	{
		"persist": "run",
		"key": "low_energy_warning_fraction", "label": "Warn at share", "step": 0.05, "min": 0.05,
		"category": "Interface",
		"tip": "What fraction of the colony has to be running low on energy before the game warns you. The warning does not pause anything.",
	},
	{
		"persist": "run",
		"key": "low_energy_warning_level", "label": "Low energy is", "step": 0.05, "min": 0.05,
		"category": "Interface",
		"tip": "What counts as a bee running low, as a fraction of its energy capacity.",
	},
	{
		"persist": "run",
		"key": "low_energy_gap", "label": "Warn every s", "step": 30.0, "min": 10.0,
		"category": "Interface",
		"tip": "Shortest gap between low-energy warnings, so a colony that stays hungry is told once and then left alone to be dealt with.",
	},
	{
		"persist": "player",
		"key": "ui_theme", "label": "Theme",
		"options": ["dark", "light", "high_contrast"],
		"option_labels": {"dark": "Dark", "light": "Light", "high_contrast": "High contrast"},
		"category": "Appearance",
		"tip": "Which colour palette every panel draws from. High contrast swaps in a near-black background, near-white text and a small set of highly saturated accent colours, clearing WCAG AAA for body text. Takes effect immediately.",
	},
	{
		"persist": "player",
		"key": "panel_texture", "label": "Panel texture",
		"options": ["flat", "comb", "grain"],
		"option_labels": {"flat": "Flat", "comb": "Honeycomb", "grain": "Grain"},
		"category": "Appearance",
		"tip": "Optional texture inside every panel's background: a faint honeycomb, or fine grain. Flat is the plain colour, and High contrast always shows plain panels. Panel edges and text never move. Takes effect immediately.",
	},
	{
		"persist": "player",
		"key": "show_speed_8x", "label": "Show 8x speed button", "toggle": true,
		"category": "Interface",
		"tip": "Adds an 8x button next to 1x/2x/4x in the top-right bar, for skipping a stretch you've already seen. Off by default -- most runs don't need it, and there is more happening per second at 8x than you can follow by watching the bees. Takes effect immediately.",
	},
	{
		"persist": "player",
		"key": "show_interface_labels", "label": "Show button labels", "toggle": true,
		"category": "Interface",
		"tip": "Shows the word alongside the icon on the Colony/Nursery/Meadow-Hive buttons in the top-right bar. Off by default -- the icons alone carry the meaning once you know them. Takes effect immediately.",
	},
	{
		"persist": "player",
		"key": "developer_mode", "label": "Developer mode", "toggle": true,
		"category": "Interface",
		"tip": "Unlocks the developer-only tables and readouts as they are added. Off by default and kept between sessions. Changes nothing about how a run plays.",
	},
	{
		"persist": "none",
		"key": "scenery_on", "label": "Trees & raised ground", "toggle": true,
		"category": "World & start",
		"tip": "Turn the trees and raised areas in the meadow on or off. With them off they vanish and stop blocking anything, so bees fly in straight lines -- useful for seeing the foraging economics on their own. Takes effect immediately.",
	},
	{
		"persist": "run",
		"key": "fog_of_war_on", "label": "Fog of war", "toggle": true,
		"category": "World & start",
		"tip": "Hide meadow ground no bee has explored yet, and dim ground that's been seen before but has no bee near it right now. Turn off to see the whole meadow at once, same as before this existed. Takes effect immediately.",
	},
	{
		"persist": "none",
		"key": "fog_reveal_radius", "label": "Sight radius", "step": 20.0, "min": 40.0,
		"category": "World & start",
		"tip": "How far around a bee out in the meadow counts as seen. Larger clears the fog faster and makes finding flowers less of a discovery.",
	},
	{
		"persist": "none",
		"key": "fog_permanent_reveal", "label": "Fog stays revealed", "toggle": true,
		"category": "World & start",
		"tip": "Once a patch of meadow has been scouted, keep it fully visible for good. Off (the default), a scouted patch dims to a foggy memory once no bee is nearby, and brightens again when one returns. Either way it stays explored -- this only changes how an unlit patch draws. Takes effect immediately.",
	},
	{
		"persist": "none",
		"key": "death_marker_days", "label": "Death marks days", "step": 1.0, "min": 0.0,
		"category": "World & start",
		"tip": "How many in-game days a mark stays where a bee died, fading as it goes. A cluster of them out at the edge of the meadow tells you bees are running out of energy trying to work a patch that is too far away.",
	},
	{
		"persist": "none",
		"key": "fps", "label": "Frame rate", "star": true,
		"category": "Interface",
		"tip": "Show the frame rate in the top-right corner, alongside whatever else you have starred. Three numbers: the average, how long the last frame took in milliseconds, and the longest frame in the last second. The last one is the one that matters for smoothness -- a run that averages 60 but spikes to 50ms every so often will feel choppy, and only the worst-frame figure shows it.",
	},
	{
		"persist": "player",
		"key": "gallerin_enabled", "label": "Dr Gallerin", "toggle": true,
		"category": "Interface",
		"tip": "The moth mentor who offers hints and encouragement during a Challenge. Turning him off changes nothing about how a Challenge plays -- he can be switched back on here at any time. Takes effect immediately.",
	},
	# --- Accessibility ---
	{
		"persist": "player",
		"key": "show_info_badges", "label": "Show info icons", "toggle": true,
		"category": "Accessibility",
		"tip": "Show the small round 'i' buttons next to controls. Turn them off once you know what everything does and the panels get a lot quieter. Takes effect immediately.",
	},
	{
		"persist": "player",
		"key": "colour_blind_mode", "label": "Colour-blind labels", "toggle": true,
		"category": "Accessibility",
		"tip": "Add a short text label wherever colour would otherwise be the only thing telling two states apart: what a cell holds, the nursery ring, the comb overlays and the zone glow. Around one man in twelve has some colour vision deficiency, and several of the palettes here are exactly the ones that fail -- but the labels are clearer for everyone at small sizes, so it is worth trying either way. Takes effect immediately.",
	},
	{
		"persist": "player",
		"key": "ui_typeface", "label": "Typeface",
		"options": ["sans", "atkinson", "opensans", "opendyslexic", "munro", "silkscreen"],
		"option_labels": {"sans": "Standard", "atkinson": "Atkinson Hyperlegible", "opensans": "Open Sans", "opendyslexic": "OpenDyslexic", "munro": "Munro", "silkscreen": "Silkscreen"},
		"category": "Appearance",
		"tip": "The font every panel draws its text in. Atkinson Hyperlegible and OpenDyslexic are both designed to stay readable at small sizes; Munro and Silkscreen are pixel-style looks, not accessibility choices. Takes effect immediately.",
	},
	{
		"persist": "player",
		"key": "text_scale", "label": "Text scale", "step": 0.1, "min": 1.0, "max": 2.0,
		"category": "Appearance",
		"tip": "Multiplies every panel's font size, from 100% up to 200%. Panels reflow -- wrap, grow taller -- rather than clip at any scale. Takes effect immediately.",
	},
	{
		"persist": "player",
		"key": "reduced_motion", "label": "Reduced motion", "toggle": true,
		"category": "Accessibility",
		"tip": "Suppresses attention flashes and pulsing animation, once a panel actually uses either. Nothing reads this yet -- it is a settings slot reserved ahead of that work, so an animation is never shipped without an off switch already in place.",
	},
	{
		"persist": "player",
		"key": "screen_shake", "label": "Screen shake",
		"options": ["off", "reduced", "full"],
		"option_labels": {"off": "Off", "reduced": "Reduced", "full": "Full"},
		"category": "Accessibility",
		"tip": "No screen shake exists in the game yet -- this is the settings slot reserved ahead of that work, so a shake effect is never shipped without an off switch already in place.",
	},
	{
		"persist": "player",
		"key": "tooltip_delay", "label": "Tooltip delay s", "step": 0.1, "min": 0.0, "max": 3.0,
		"category": "Accessibility",
		"tip": "Seconds a hovered control waits before showing its tooltip. Godot's own default is half a second -- raise it if tooltips keep popping up before you meant to see them, or lower it towards zero to see them straight away. Takes effect immediately.",
	},

	# --- catalogued for save-persistence bookkeeping only; not yet
	# shown in the settings window (no "category") -- F11,
	# plans/design/architecture-review.md ---
	{
		"key": "adaptive_constancy_decay", "persist": "run",
	},
	{
		"key": "adaptive_constancy_gain", "persist": "run",
	},
	{
		"key": "adaptive_constancy_weight", "persist": "run",
	},
	{
		"key": "cell_full_threshold", "persist": "run",
	},
	{
		"key": "epitaph_min_gap", "persist": "run",
	},
	{
		"key": "fact_general_chance", "persist": "run",
	},
	{
		"key": "fact_templated_chance", "persist": "run",
	},
	{
		"key": "fact_trait_matched_chance", "persist": "run",
	},
	{
		"key": "forage_perception_radius", "persist": "run",
	},
	{
		"key": "forage_search_angle_step", "persist": "run",
	},
	{
		"key": "forage_search_radius", "persist": "run",
	},
	{
		"key": "forage_search_spiral_step", "persist": "run",
	},
	{
		"key": "handling_experience_floor", "persist": "run",
	},
	{
		"key": "handling_experience_visits_to_floor", "persist": "run",
	},
	{
		"key": "handling_experience_forget_visits", "persist": "run",
	},
	{
		"key": "hive_entrance_width", "persist": "run",
	},
	{
		"key": "known_patch_min_spacing", "persist": "run",
	},
	{
		"key": "known_patches_max", "persist": "run",
	},
	{
		"key": "local_search_drift_rate", "persist": "run",
	},
	{
		"key": "milestone_interval", "persist": "run",
	},
	{
		"key": "probabilistic_choice_heading_weight", "persist": "run",
	},
	{
		"key": "starting_miners", "persist": "run",
	},
	{
		"key": "trait_magnitude_bands", "persist": "run",
	},
	{
		"key": "trait_positive_chance", "persist": "run",
	},
	{
		"key": "visual_size_jitter_range", "persist": "run",
	},
	{
		"key": "visual_tint_jitter_range", "persist": "run",
	},
	{
		"key": "crab_spider_escape_cooldown_seconds", "persist": "none",
	},
	{
		"key": "crab_spider_escape_min_gap", "persist": "none",
	},
	{
		"key": "disease_per_bee", "persist": "none",
	},
	{
		"key": "flower_lifespan_days", "persist": "none",
	},
	{
		"key": "flower_lifespan_variation", "persist": "none",
	},
	{
		"key": "flower_regrow_seconds", "persist": "none",
	},
	{
		"key": "forager_return_route_factor", "persist": "none",
	},
	{
		"key": "forager_return_safety_margin", "persist": "none",
	},
	{
		"key": "min_worthwhile_amount", "persist": "none",
	},
	{
		"key": "out_of_season_ageing_factor", "persist": "none",
	},
	{
		"key": "out_of_season_seed_weight", "persist": "none",
	},
	{
		"key": "out_of_season_strength", "persist": "none",
	},
	{
		"key": "poor_patch_search_streak", "persist": "none",
	},
	{
		"key": "rival_brood_per_nurse", "persist": "none",
	},
	{
		"key": "rival_eat_per_bee", "persist": "none",
	},
	{
		"key": "rival_hatch_rate", "persist": "none",
	},
	{
		"key": "rival_nectar_per_bee", "persist": "none",
	},
	{
		"key": "rival_pollen_per_bee", "persist": "none",
	},
	{
		"key": "rival_pollen_per_bee_raised", "persist": "none",
	},
	{
		"key": "rival_starve_rate", "persist": "none",
	},
	{
		"key": "rival_store_per_bee", "persist": "none",
	},
	{
		"key": "thin_flower_fraction", "persist": "none",
	},
]

# --- settings owned by Session ------------------------------------
## Settings that live in Session rather than GameConfig -- the player's
## own preferences, as opposed to numbers that change how the game plays.
## The panel edits both, so it needs to know which object to ask.
const SESSION_KEYS := [
	"show_info_badges", "colour_blind_mode",
	"show_flower_amounts", "show_cell_contents_text", "use_cell_sprites",
	"use_sprite_hex_grid", "use_radial_hex_speed", "show_forager_labels",
	"show_recruitment_highlight",
	"gallerin_enabled", "show_crab_spiders",
	"ui_theme", "panel_texture", "ui_typeface", "text_scale", "reduced_motion", "screen_shake",
	"tooltip_delay", "show_speed_8x", "show_interface_labels", "developer_mode",
]

# --- reading and writing a setting --------------------------------
static func setting_get(key: String):
	return Session.get(key) if key in SESSION_KEYS else GameConfig.get(key)

static func setting_set(key: String, value) -> void:
	if key in SESSION_KEYS:
		Session.set(key, value)
		Session.save_preferences()
	else:
		GameConfig.set(key, value)

# --- resetting ----------------------------------------------------
## C3 (hands-on-fixes-2026-08-31.md): GameConfig is an autoload, so a
## debug-panel tweak from an earlier session survives reload_current_scene()
## and would otherwise leak into whatever the player picks next from the
## main menu. Reads each default from a fresh, unmodified GameConfig
## instance rather than a hand-maintained list, so it can't drift from
## game_config.gd over time.
##
## The key set comes from GameConfig's own property list, not from
## TUNABLES: a settings-window row is a view of a field, not the
## definition of one, and 44 GameConfig fields have no row -- the ones
## headless and scenario work tunes most. Iterating TUNABLES left those
## 44 able to leak from one run into the next. This is the same
## PROPERTY_USAGE_SCRIPT_VARIABLE filter levels.gd::apply_config_overrides
## uses to decide what a valid override key is, so the two agree by
## construction. No SESSION_KEYS special case is needed either: a Session
## preference is not a GameConfig property, so this loop cannot reach one.
static func reset_config_to_defaults() -> void:
	var defaults = GameConfig.get_script().new()
	for prop in GameConfig.get_property_list():
		if prop.usage & PROPERTY_USAGE_SCRIPT_VARIABLE:
			GameConfig.set(prop.name, defaults.get(prop.name))
	defaults.free()

## SP-1 (settings-persistence.md): resets only the named GameConfig keys to
## their fresh-instance defaults, leaving every other field as the player
## left it. Same default source as reset_config_to_defaults(), so the two
## can't drift apart -- used where a run change owns a known subset of
## GameConfig rather than the whole thing.
static func reset_config_keys(keys: Array) -> void:
	var defaults = GameConfig.get_script().new()
	for key in keys:
		GameConfig.set(key, defaults.get(key))
	defaults.free()

# --- applying a setting with its cascades -------------------------
## Sets `key` to `value` and, if `key` takes part in the Prerequisites
## tree, cascades to keep dependencies consistent -- turning a toggle on
## also turns on everything it depends on; turning one off also turns
## off everything that depends on it. Shared by the settings-window
## checkbox handler (`_make_toggle_row`, which additionally syncs its own
## checkboxes afterwards) and the headless `set_config` scenario verb
## (`scenario_actions.gd::_do_set_config`), so there is one cascade
## implementation, not two that can drift (CHATGPT_INSIGHTS_PLAN.md B1).
static func apply_setting(key: String, value) -> void:
	setting_set(key, value)
	if value:
		_cascade_mutual_exclusion_static(key)
	if not Prerequisites.is_gated(key):
		return
	if value:
		_cascade_prerequisites_on_static(key)
	else:
		_cascade_dependents_off_static(key)

# --- the cascade helpers ------------------------------------------
## Walks up Prerequisites from `key`, turning on everything it depends
## on -- e.g. switching on Floral constancy also switches on Auto
## scouting. Returns the keys it actually changed, so a UI caller can
## sync their checkboxes.
static func _cascade_prerequisites_on_static(key: String) -> Array[String]:
	var changed: Array[String] = []
	var parent: String = Prerequisites.direct_parent(key)
	while parent != "":
		if not setting_get(parent):
			setting_set(parent, true)
			changed.append(parent)
			# A prerequisite can itself be an alternate mechanism (Auto
			# scouting versus Orientation flight), so activating it must
			# keep that pair consistent too.
			_cascade_mutual_exclusion_static(parent)
		parent = Prerequisites.direct_parent(parent)
	return changed

## Walks Prerequisites to find anything whose prerequisite is `key`
## (directly or transitively) and turns it off too -- e.g. switching off
## Auto scouting also switches off Floral constancy and
## Auto-recruitment. Returns the keys it actually changed.
static func _cascade_dependents_off_static(key: String) -> Array[String]:
	var changed: Array[String] = []
	for child in Prerequisites.direct_dependents(key):
		if setting_get(child):
			setting_set(child, false)
			changed.append(child)
			changed.append_array(_cascade_dependents_off_static(child))
	return changed

## Turns off whatever's mutually exclusive with `key` (Prerequisites.
## MUTUALLY_EXCLUSIVE), if anything is and it's currently on -- e.g.
## switching on Proximity recruitment also switches off Auto-recruitment.
## Returns the keys it actually changed, same shape as the two cascades
## above, so a UI caller can sync their checkboxes.
static func _cascade_mutual_exclusion_static(key: String) -> Array[String]:
	var changed: Array[String] = []
	var sibling: String = Prerequisites.mutually_exclusive_with(key)
	if sibling != "" and setting_get(sibling):
		setting_set(sibling, false)
		changed.append(sibling)
		if Prerequisites.is_gated(sibling):
			changed.append_array(_cascade_dependents_off_static(sibling))
	return changed
