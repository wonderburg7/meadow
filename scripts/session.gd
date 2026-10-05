extends Node
## Autoload. Everything that is *not* a balance number: the clock, flags
## that survive a scene reload, and the player's interface preferences.
##
## The interface-preferences block below (and the appearance/accessibility
## fields further down) are a runtime mirror of player_profile.gd's
## persisted "preferences" block (UI_PLAN.md section 12): _ready() loads
## whatever was last saved, and save_preferences() writes the current
## values back. Every existing field name and call site stays exactly as
## it was -- nothing outside this file and player_profile.gd needs to
## know the durable copy exists.
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

## Fires at the end of reset_run_state() -- i.e. at every point a new run
## actually begins (Restart Run, New Run, Load; see every call site of
## reset_run_state()). diagnostic_log.gd is the one listener today,
## closing out the previous session file and opening the next. A signal
## rather than a direct call, so Session stays ignorant of
## DiagnosticLog's existence -- new call sites of reset_run_state() get
## covered automatically without Session needing to know why.
signal run_reset()

const PlayerProfile = preload("res://scripts/player_profile.gd")
const Progression = preload("res://scripts/progression.gd")

func _ready() -> void:
	PlayerProfile.apply_to_session(PlayerProfile.read())

## Writes every interface-preference field to the player profile file, so
## it survives a full game restart, not just a Restart Run. Called
## wherever one of those fields is actually set -- see the doc comment at
## the top of this file for the full list of call sites.
func save_preferences() -> void:
	PlayerProfile.save_preferences()

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
## Which save file that replay reads (SV-1: saves are named slots now, so
## "the save" is no longer one fixed path).
var load_path: String = ""
## The run's display name; its slug names the save slot and checkpoints
## (save_slots.gd). Kept across a restart, like a player's own save was.
var run_name: String = "My colony"
## Which starting stage the next run builds. 0 means "use the tuning
## numbers as they are"; the positive ids are fixed run definitions offered
## by the main menu (Challenges and Scenarios, currently 1-7 with stable ids).
## Left as-is after a run starts, so a plain Restart Run repeats whatever
## stage you last chose.
var starting_level: int = 0

# --- the run's skill policy (BS-14) -------------------------------
## The skill_grants and skill_bans this run's availability sheet was built
## from (what Progression.begin_run was given), recorded by main.gd's
## run_definition at the run's start and written into every save of the run
## by save_game.gd.
var run_skill_grants: Array = []
var run_skill_bans: Array = []
## True when developer edits (developer_overrides.gd) changed this run's
## level policy at its start. A load carries it over, so every later save
## of the run says so too.
var run_developer_changes: bool = false
## A loaded save's policy, put back by SaveGame.apply_skill_policy before the
## reload: {"level", "grants", "bans", "developer_changes"}, or empty.
## main.gd's run_definition uses it instead of the overrides file and clears
## it, so the next new run reads that file again.
var pending_skill_policy: Dictionary = {}

## Called once per run start by main.gd's run_definition.
func record_run_skill_policy(grants: Array, bans: Array, developer_changes: bool) -> void:
	run_skill_grants = grants.duplicate()
	run_skill_bans = bans.duplicate()
	run_developer_changes = developer_changes

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

# --- crab spiders (see CRAB_SPIDER_PLAN.md) ------------------------
## Which flower species this run's crab spiders are hunting on. Rolled
## once, the first time GameConfig.predators_on is true and this is
## still unset -- see FlowerSpecies.roll_preferred_species(). Run state,
## not a balance number: it's "which species this particular run
## picked", same reasoning as winter_coming above.
var crab_spider_preferred_species: String = ""

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

## Turn the small "i" tooltip badges on if you want a reminder of what
## everything does. Off by default per UI_PLAN.md section 9 -- badges
## used to default on, which is a real behaviour change for anyone
## opening a fresh save.
var show_info_badges: bool = false

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

## Whether an empty comb cell shows the `wax.cell.empty.png` resprite
## instead of the original flat colour fill. Off reverts to the flat
## fill Meadow used before the resprite -- see `HiveCell._refresh`.
## Purely cosmetic: doesn't touch the hive's grid geometry, unlike
## `use_sprite_hex_grid` below.
var use_cell_sprites: bool = true

## Whether the hive's whole hex grid -- comb, floor, soil, bedrock, the
## entrance tunnel, all of it -- is drawn squashed 2:1 to match the
## resprite's 32x16 footprint, rather than as a regular hexagon. This is
## grid geometry, not just a colour swap, so world_building.gd only reads
## it while laying out a fresh hive: flipping it mid-run would leave
## every already-placed cell and soil block sitting at the old grid's
## positions. Takes effect on Restart Run, same as `hive_cell_size`/
## `hive_cell_spacing` in GameConfig. See `Shapes.SQUASH`.
var use_sprite_hex_grid: bool = true

## Whether a bee walking inside the (squashed) hive covers one hex-edge's
## worth of true distance in the same time regardless of which of the six
## directions it's walking. Off reproduces the older behaviour: speed is
## constant in squashed *screen* pixels, so a bee moving in the compressed
## vertical direction crosses the same hex-distance faster than one moving
## sideways. On by default so travel time is direction-independent; the
## toggle exists to compare the two side by side. No effect when
## `use_sprite_hex_grid` is off, since nothing is squashed to correct for.
var use_radial_hex_speed: bool = true

## Whether the small ID-and-letter label above a forager is shown. Doesn't
## affect other roles' labels.
var show_forager_labels: bool = true

## Whether the two bees in an in-progress recruitment dance are ringed so
## they can be picked out of a crowd on the comb (mentor warm yellow,
## seeker cool blue). Presentation only -- it must never gate the
## recruitment mechanism itself, which is why this lives here and not in
## GameConfig. Off by default, and off costs one boolean read per forager
## per frame. See bee.gd's _update_dance_ring.
var show_recruitment_highlight: bool = false

## Dev-only: keeps a flower's crab spider marker visible all the time
## instead of only flashing on an attack/relocation. Off means the
## normal, mostly-invisible presentation; see CRAB_SPIDER_PLAN.md
## section 7. Same pattern as show_flower_amounts.
var show_crab_spiders: bool = false

## Dev-only: shows the 8x speed button in the top-right bar. Off by
## default -- UI_PLAN.md section 2 lists 8x as a parenthetical, optional
## entry, not one every player needs on screen. Same pattern as
## show_crab_spiders.
var show_speed_8x: bool = false

## Developer mode: unlocks the developer-only tables and readouts. Off by
## default and a player preference, not run state, so it survives a
## restart (PlayerProfile.PREFERENCE_KEYS). Switched on from the settings
## window; BS-5 (plans/now/brood-spine.md) is its first consumer.
var developer_mode: bool = false

## Saved selections, 1-9. Each is a list of bee ids rather than node
## references, so the group survives bees dying and the scene reloading.
var control_groups: Dictionary = {}

## Which comb overlay the hive view is showing, if any. See
## main.gd's _apply_comb_overlay.
var comb_overlay: String = ""

## Selection tray field visibility (UI_PLAN.md section 5's four-group
## ranking), toggled from the tray's own cog rather than the settings
## window -- same spirit as pinned_stats' stars.
var show_selection_identity: bool = true
var show_selection_energy: bool = true
var show_selection_activity: bool = true
var show_selection_trait: bool = true

# --- appearance and accessibility (UI_PLAN.md sections 6/7) --------
## Read by ui_theme.gd's palette(). "dark" (default), "light" or
## "high_contrast".
var ui_theme: String = "dark"

## Read by ui_theme.gd's PanelBox. "flat" (default), "comb" (pixel hexagon
## tiling in panel_line) or "grain" (per-pixel jitter over panel_bg).
var panel_texture: String = "flat"

## Read by ui_theme.gd's build_theme(). "sans" (default, no asset
## needed), "atkinson", "opensans", "opendyslexic", "munro" or
## "silkscreen" -- each of the non-default faces loads its font file
## from assets/fonts/ and falls back to the default font if the file
## is ever missing rather than erroring.
var ui_typeface: String = "sans"

## Multiplier applied to every UiTheme type-variation font size. 1.0 to
## 2.0, per UI_PLAN.md section 14's "every text scale up to 200%" check.
var text_scale: float = 1.0

## Whether the top-right bar's Colony/Nursery/Meadow-Hive buttons show
## their text label alongside the icon. Off by default (icon-only) per
## Dave's 22 Aug call -- the label is a settings opt-in, not the default,
## now that the icons carry the meaning on their own.
var show_interface_labels: bool = false

## Suppresses the neon attention flashes and any future drawer/marker
## animation (UI_PLAN.md section 7). Doesn't affect anything simulated.
var reduced_motion: bool = false

## "off", "reduced" or "full". Reserved: no screen shake exists in the
## codebase yet -- this is the settings slot so one is never shipped
## without an off switch already in place.
var screen_shake: String = "full"

## Seconds a hovered control waits before showing its tooltip. 0.5
## matches Godot's own default (gui/timers/tooltip_delay_sec).
var tooltip_delay: float = 0.5

# --- progression --------------------------------------------------
## This run's skill resolver (progression.gd). Run state, so it lives here
## rather than on main.gd: skill ownership is "what this run has", and
## Session survives the scene reloads between runs. Built by main.gd's
## _ready through ensure_progression() once the stage gate exists, and
## dropped by reset_run_state() so the next run starts with a fresh one.
var progression: Object = null

## Returns this run's resolver, building it on first call. `gate` is the
## run's stage_gate.gd node, which the resolver reads for is_permitted().
## A resolver holding a different gate belongs to an earlier scene -- the
## save-file Load path reloads the scene without reset_run_state() -- so
## it is replaced rather than left pointing at a freed node.
func ensure_progression(gate: Node) -> Object:
	if progression != null and progression.stage_gate == gate:
		return progression
	if progression != null:
		progression.end_run()
	progression = Progression.new(GameConfig, gate)
	return progression

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
	crab_spider_preferred_species = ""
	rain_intensity = 0.0
	control_groups.clear()
	# A new run never inherits a load's policy (BS-14); a load itself does
	# not come through here.
	pending_skill_policy = {}
	if progression != null:
		progression.end_run()
		progression = null
	run_reset.emit()
