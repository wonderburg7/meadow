extends Node
## Autoload. Everything that is *not* a balance number: the clock, flags
## that survive a scene reload, and the player's interface preferences.
##
## These all used to live in GameConfig alongside `egg_pollen_cost` and
## `brood_develop_time`, which caused two real problems. The settings window
## had to keep a hand-written list of which keys were actually tunable,
## because showing "sim_time" as a settable number would be nonsense. And
## saving a run wrote the player's starred readouts into the save file
## along with the colony, so loading someone else's save would rearrange
## your screen.
##
## The rule for deciding where something goes: if a designer would tune
## it to change how the game plays, it belongs in GameConfig. If it
## describes the state of *this* run or *this* player, it belongs here.

# --- the clock ----------------------------------------------------
## In-game seconds elapsed. Advanced by main.gd, saved with the run.
var sim_time: float = 0.0

# --- flags that outlive a scene reload ----------------------------
## Set just before a reload to tell the freshly built world what to do
## with itself. All of them are consumed and cleared by main.gd's _ready.

## True the first time the game runs, so main.gd opens the menu rather
## than dropping straight into a colony.
var menu_pending: bool = true
## Replay a saved run over the newly built world. See save_game.gd.
var load_pending: bool = false
## Which starting stage the next run builds. 0 means "use the tuning
## numbers as they are"; 1-5 are the fixed stages the main menu offers.
## Left as-is after a run starts, so a plain Restart Run repeats whatever
## stage you last chose.
var starting_level: int = 0

# --- winter -------------------------------------------------------
## Whether a winter has been scheduled and when it lands. State of the
## run rather than a setting -- how long a winter lasts is the setting,
## and that stays in GameConfig.
var winter_coming: bool = false
var winter_starts_day: float = 0.0
## True once it has actually arrived. Foraging stops and the colony lives
## on what it stored.
var winter_here: bool = false
var winter_ends_day: float = 0.0
## Gynes that have left to found colonies of their own. This is the
## score: the whole point of a season is how many you get away.
var gynes_released: int = 0

# --- interface preferences ----------------------------------------
## Which readouts are starred into the top-left corner. Keys match the
## STAT_ROWS of the colony and nursery windows.
var pinned_stats: Array = ["day", "stores", "signals"]

## Gates perf.gd's instrumentation. Kept in sync with whether "fps" is
## starred (see hud.gd's pinned_stats_changed) rather than being its
## own setting, so there's exactly one thing to toggle. A plain field
## rather than pinned_stats.has("fps") computed on the fly, because
## Perf reads this on every begin/end and a field read is cheaper than
## an Array scan repeated a dozen times a frame.
var perf_enabled: bool = false

## Turn the small "i" tooltip badges off once you know what everything
## does.
var show_info_badges: bool = true

## Adds a short text label wherever colour would otherwise be the only
## thing distinguishing two states -- cell contents, the nursery ring,
## the comb overlays, the zone glow.
##
## Around one man in twelve has some colour vision deficiency, and
## several of the palettes here (particularly the green/orange/red of the
## problem strip and the ring) are exactly the ones that fail. Labels are
## also simply clearer for everyone at small sizes, which is why this is
## worth having as an option rather than a fix for a minority.
var colour_blind_mode: bool = false

## "Don't show this again" for the discard warning.
var warn_on_discard: bool = true

## Whether Dr Gallerin (the Challenge tutorial's mentor popup, see
## TUTORIAL_PLAN.md) appears at all. Gameplay is identical either way --
## this only silences his prompts, same spirit as the other interface
## preferences above.
var gallerin_enabled: bool = true

## Whether a flower shows its live nectar/pollen numbers underneath itself.
## Off by default -- 500 flowers' worth of numbers is a lot of clutter for
## something you can still get, per flower, by clicking it.
var show_flower_amounts: bool = false

## Whether a comb cell shows the small text describing its contents (N40,
## an egg's development percent, and so on) on top of its colour coding.
var show_cell_contents_text: bool = true

## Whether the small ID-and-letter label above a forager is shown. Doesn't
## affect other roles' labels.
var show_forager_labels: bool = true

## Saved selections, 1-9. Each is a list of bee ids rather than node
## references, so the group survives bees dying and the scene reloading.
var control_groups: Dictionary = {}

## Which comb overlay the hive view is showing, if any. See
## main.gd's _apply_comb_overlay.
var comb_overlay: String = ""

# --- live weather state -------------------------------------------
## Advanced by main.gd. Not a setting: how likely rain is, is.
var rain_intensity: float = 0.0

## Called by main.gd when a run restarts, so nothing from the last one
## leaks into the next. Preferences are deliberately *not* reset -- they
## belong to the player, not the run.
func reset_run_state() -> void:
	sim_time = 0.0
	winter_coming = false
	winter_here = false
	winter_starts_day = 0.0
	winter_ends_day = 0.0
	gynes_released = 0
	rain_intensity = 0.0
	control_groups.clear()
