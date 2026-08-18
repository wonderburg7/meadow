extends CanvasLayer
## Top-left readouts (day, stores, bee count), the view switcher, the
## game-speed controls, the panel that appears when bees are selected,
## and the popup for inspecting a single comb cell.
##
## Every control carries a small "i" badge whose tooltip explains what
## it does -- see `_info()`. Kept separate from main.gd so the
## simulation wiring stays readable.

const UI = preload("res://scripts/ui.gd")
const Bee = preload("res://scripts/bee.gd")
const Roles = preload("res://scripts/roles.gd")
const PerfPlot = preload("res://scripts/perf_plot.gd")
const PerfBreakdown = preload("res://scripts/perf_breakdown.gd")

signal focus_requested(type: String)
signal role_requested(role_name: String)
signal view_toggle_requested()
signal colony_panel_requested()
signal speed_requested(speed_scale: float)
signal cell_designation_requested(cell: Node2D, type: String)
## `focus` and `use_automine` carry the sub-mode the chosen role needs --
## which resource a forager starts on, whether a miner starts automining.
signal cell_hatch_role_requested(cell: Node2D, role: int, focus: String, use_automine: bool)
## Pins the hatch role so every future bee raised in the cell inherits
## it, rather than it applying to the next one only.
signal cell_hatch_lock_requested(cell: Node2D, locked: bool)
## `method` is "move" (a builder carries the contents to another cell) or
## "discard" (thrown out of the hive). `keep_empty` leaves the cell
## closed to deposits afterwards.
signal cell_empty_requested(cell: Node2D, method: String, keep_empty: bool)
## Applied the moment the checkbox is ticked, independently of whether
## the cell is being emptied right now.
signal cell_keep_empty_requested(cell: Node2D, keep_empty: bool)
## Whether the queen lays a gyne into this cell rather than a worker.
signal cell_gyne_requested(cell: Node2D, as_gyne: bool)
## "Click a spot" modes -- main.gd puts itself into a placement mode when
## these fire, and consumes the next click in the relevant view instead
## of treating it as a normal select/drag.
signal build_cell_requested()
## Challenge 1 only -- a "Build cell" button in the queen's own selection
## panel, replacing the generic Job-row-then-placement-click flow for
## that one first cell. See set_queen_build_button_visible.
signal queen_build_cell_requested()
## Sets the tile the *selected* comb worker builds outward from -- its own
## centre of operations, rather than the middle of the comb. Applies to
## one bee only, even if several are selected -- see home_cell_all_requested
## for the colony-wide version.
signal home_cell_requested()
## The same, but for every comb worker in the colony at once, not just
## the current selection.
signal home_cell_all_requested()
## The same for a miner: the tile it works outward from when choosing
## which soil to dig next.
signal mine_home_requested()
## "Mine": the next click (ctrl to add more) sets this miner's own list
## of blocks to dig, in order.
signal mine_target_requested()
## "Keep clear": the next click flags a tile no comb worker will build on.
signal keep_clear_requested()
## Restocking. The currently selected comb becomes the cells this
## comb worker keeps full of `resource`.
signal restock_targets_requested(resource: String)
## The selected comb becomes the comb worker's allowed sources (`allowed`
## true) or the cells it must never touch (false).
signal restock_sources_requested(allowed: bool)
signal restock_clear_requested()
## Adds the selected cells to the nursery zone, or takes them out of it.
signal cell_zone_requested(cell: Node2D, in_zone: bool)
## Sets the priority tier on the selected zone cells: 0 low, 1 medium,
## 2 high.
signal cell_priority_requested(cell: Node2D, tier: int)
## Seals the selected cells, or opens them back up.
signal cell_close_requested(cell: Node2D, closed: bool)
## Fill the cell to the top and then seal it, refusing withdrawals in the
## meantime so it can actually get there.
signal cell_fill_close_requested(cell: Node2D)
## Opens the nursery zone window.
signal nursery_window_requested()
## Opens the winter forecast. Only offered once a winter is scheduled.
signal winter_window_requested()
## A line in the problem strip was clicked. `action` names what it is
## about, so main.gd can select the bees or cells concerned.
signal signal_clicked(action: String)
## Marks or clears the digging flag on every selected soil block.
signal soil_mark_requested(mark: bool)
signal forage_start_point_requested()
## "none" clears it. Only offered for bees whose primary role actually
## checks a secondary -- see the note on _rebuild_role_controls.
signal secondary_role_requested(role_key: String)
## Whether reassigning the selected bees waits for their current job.
signal finish_first_requested(value: bool)
## Enters "click a flower" mode -- only offered when floral constancy is
## on in tuning. See GameConfig.floral_constancy_on.
signal floral_preference_requested()
## The star in the single-bee panel -- only offered for one bee at a
## time, see BEE_INDIVIDUALITY_PLAN.md section 7.
signal favourite_requested(value: bool)

## Mirrors Bee.Role. Kept as plain ints so the HUD doesn't need to
## preload bee.gd just to name them. -1 means "colony default".
##
## What a cell can be set to raise. Built from the role table rather
## than written out again here: a role's sub-modes are exactly the
## options a cell should offer, so there is nothing extra to keep in
## step. "-1" is the colony default.
##
## A comb worker's sub-mode rides in the cell's `focus` field rather than
## getting a field of its own -- the cell only needs to carry one extra
## string, and a bee is never both a forager and a comb worker.
static func hatch_options() -> Array:
	var entries: Array = [{
		"label": "Default", "role": -1,
		"options": [{"label": "Colony default", "focus": "nectar", "automine": false}],
	}]
	for role in Roles.ROLES:
		if role.id == Roles.QUEEN or role.id == Roles.IDLE:
			continue   # a cell can't raise a queen, and "raises idle" is nonsense
		var options: Array = []
		if role.modes.is_empty():
			options.append({"label": role.label, "focus": "nectar", "automine": false})
		else:
			for mode in role.modes:
				options.append({
					"label": "%s — %s" % [role.label, mode.label],
					"focus": mode.key if role.id != Roles.MINER else "nectar",
					"automine": role.id == Roles.MINER and mode.key == "automine",
				})
			if role.id == Roles.MINER:
				options.push_front({"label": "Miner — only where told", "focus": "nectar", "automine": false})
		entries.append({"label": role.label, "role": role.id, "options": options})
	return entries

## Transport-style controls: pause, play, and two levels of fast
## forward, using the usual arrow symbols rather than numbers.
## Numbers rather than stacked arrows: "▶▶▶" and "▶▶▶▶" are hard to tell
## apart at a glance and each one is wider than the last, which is what
## was eating the top bar. A number is one character at any speed.
const SPEEDS := [
	{"label": "❚❚", "scale": 0.0, "tip": "Pause. The whole colony freezes; you can still look around and give orders."},
	{"label": "1", "scale": 1.0, "tip": "Normal speed."},
	{"label": "2", "scale": 2.0, "tip": "Double speed. Good for waiting out brood development or comb building."},
	{"label": "4", "scale": 4.0, "tip": "Quadruple speed. The quickest way to reach the next day."},
	{"label": "8", "scale": 8.0, "tip": "Eight times speed. For skipping a stretch you have already seen -- a winter run-up, or waiting on a big dig. Watch the energy readout rather than the bees at this speed; there is more happening per second than you can follow."},
]

## The role a bee can be switched to, and the sub-modes of each, both
## come from Roles now. The keys main.gd matches on are built from the
## role key and the mode key -- "comb_worker_build", "nurse_jelly" --
## so adding a mode to the table is all it takes.
static func mode_command(role_id: int, mode_key: String) -> String:
	return "%s_%s" % [Roles.key_for(role_id), mode_key]

## Gap left between this bar and the settings cog that debug_panel.gd
## owns, on top of however wide the cog button actually is right now.
const SETTINGS_BUTTON_GAP := 8.0
## Used only until debug_panel.gd reports the cog's real width (see
## set_settings_button_width) -- close to the cog's own custom_minimum_size
## so there's no visible jump on the first frame.
const SETTINGS_BUTTON_DEFAULT_WIDTH := 36.0

## The top-left corner. Every readout lives in the colony window now;
## this shows only the ones the player has starred there, in a fixed
## order, so the corner is theirs to spend rather than a fixed block of
## text. `corner_texts` is also what the colony window is handed, so the
## two can never disagree about what a number says.
var corner_column: VBoxContainer
## The perf plot and its breakdown line, when "fps" is starred. Kept as
## persistent children rather than rebuilt with the rest of the corner
## texts each time the signature changes -- see _refresh_corner -- so
## their own 4Hz redraw timing isn't reset every time e.g. the day
## counter ticks over.
var perf_plot: Control
var perf_breakdown: Label
var corner_texts: Dictionary = {
	"day": "", "stores": "", "population": "", "comb": "",
	"energy": "", "rates": "", "winter": "", "fps": "",
	"nursery_zone": "", "nursery_mix": "", "nursery_output": "",
}
## Order the starred readouts appear in. Covers both the colony window's
## STAT_ROWS and the nursery window's, since both pin into the same
## corner and the order they appear in shouldn't depend on which window
## the player happened to star them from.
const CORNER_ORDER := [
	"fps",
	"day", "winter", "stores", "population", "comb", "energy", "rates",
	"nursery_zone", "nursery_mix", "nursery_output",
]
## Font size per readout -- the day is the headline, the rest is detail.
const CORNER_SIZES := {
	"fps": 12,
	"day": 22, "winter": 15, "stores": 16, "population": 13, "comb": 12,
	"energy": 13, "rates": 12,
	"nursery_zone": 12, "nursery_mix": 12, "nursery_output": 12,
}
## What is currently drawn, so the column is only rebuilt when it would
## actually look different rather than every frame.
var corner_signature: String = ""

var pause_label: Label
var view_button: Button
var winter_button: Button
var colony_button: Button
var nursery_button: Button
## The "i" badges next to colony_button/nursery_button/view_button --
## kept so the visibility setters below can hide the explanation
## alongside the control it explains, rather than leaving an orphaned
## info badge for a button that isn't there.
var colony_info: Button
var nursery_info: Button
var view_info: Button
## The current Challenge's next-goal readout -- see set_challenge_goal.
var goal_label: Label
## Restricts the Job row's "Change to..." dropdown / the Doing row's
## Forager sub-modes to just these keys. Empty means no restriction --
## only a Challenge (see challenge_runner.gd) ever sets these to
## something non-empty. See set_allowed_role_keys/set_allowed_mode_keys.
var allowed_role_keys: Array = []
var allowed_mode_keys: Array = []
## Challenge 1 only -- see set_queen_build_button_visible.
var show_queen_build_button: bool = false
## The row of speed/colony/nursery/winter/view buttons in the top-right
## corner, kept anchored clear of whatever debug_panel.gd's settings cog
## currently measures -- see set_settings_button_width.
var top_right_bar: HBoxContainer
var selection_panel: PanelContainer
var selection_label: Label
var task_label: Label
var speed_buttons: Array = []
var role_row: VBoxContainer
var shown_bees: Array = []

var cell_popup: PopupPanel
var cell_popup_label: Label
var active_cell: Node2D = null
var keep_empty_box: CheckBox
var hatch_lock_box: CheckBox
var gyne_box: CheckBox

var flower_popup: PopupPanel
var flower_popup_label: Label
var active_flower: Node2D = null

var obstacle_popup: PopupPanel
var obstacle_popup_label: Label

var soil_popup: PopupPanel
var soil_popup_label: Label
## How many cells the popup's buttons will act on. 1 unless the player
## has a multi-cell selection.
var selected_cell_count: int = 1

var warning_panel: PanelContainer
var warning_label: Label
var warning_timer: float = 0.0
## Set by challenge_runner.gd for the length of a Challenge -- see
## TUTORIAL_PLAN.md's "Don't include the warning messages" note. Every
## other caller of show_warning is unaffected outside a Challenge.
var warnings_muted: bool = false

## The at-a-glance problem strip, as [text, severity] pairs, kept so the
## corner can be rebuilt without main.gd having to resend it.
var shown_signals: Array = []

## Severity colours for the at-a-glance strip: 0 is background
## information, 1 is worth looking at, 2 is losing you something now.
const SIGNAL_COLOURS := [
	Color(0.75, 0.82, 0.9),
	Color(1.0, 0.85, 0.4),
	Color(1.0, 0.45, 0.4),
]

var discard_dialog: ConfirmationDialog
var pending_cell: Node2D = null
var pending_type: String = ""

func _ready() -> void:
	process_mode = PROCESS_MODE_ALWAYS
	layer = 9
	# So the settings window can find the corner readout to refresh it when
	# a star is toggled, without either script holding a reference to the
	# other.
	add_to_group("huds")

	# The controls used to be printed here permanently. They now live in
	# the settings window's Interface section, which keeps the corner of the
	# screen clear once you know them.
	#
	# One column for everything in the corner: the starred readouts, then
	# the at-a-glance problem strip underneath, so it reads as one block --
	# what you have, then what's wrong with it. Laid out rather than
	# positioned at fixed pixels, because which readouts are showing
	# changes as the player stars and unstars them.
	corner_column = VBoxContainer.new()
	corner_column.position = Vector2(16, 12)
	corner_column.add_theme_constant_override("separation", 2)
	add_child(corner_column)

	perf_plot = PerfPlot.new()
	perf_plot.custom_minimum_size = Vector2(140, 40)
	perf_plot.visible = false
	corner_column.add_child(perf_plot)
	perf_breakdown = PerfBreakdown.new()
	perf_breakdown.visible = false
	corner_column.add_child(perf_breakdown)

	pause_label = _make_label(Vector2(16, 300), 18)
	pause_label.text = "PAUSED"
	pause_label.visible = false

	_build_top_right_bar()
	_build_selection_panel()
	_build_cell_popup()
	_build_flower_popup()
	_build_obstacle_popup()
	_build_soil_popup()
	_build_warning_banner()
	_build_discard_dialog()

func _make_label(pos: Vector2, font_size: int) -> Label:
	var l := Label.new()
	l.position = pos
	l.add_theme_font_size_override("font_size", font_size)
	add_child(l)
	return l

func _info(text: String) -> Button:
	return UI.info_badge(text)

func _with_info(control: Control, tip: String) -> HBoxContainer:
	return UI.with_info(control, tip)

## Anchored to the top-right rather than positioned at fixed pixels, so
## the bar follows the corner when the window is resized. The settings
## cog in debug_panel.gd is anchored the same way and reports its own
## width back here (see set_settings_button_width) so the two never
## overlap and never leave more of a gap than the cog actually needs --
## previously this reserved a fixed 108px sized for the old "Tuning ▾"
## text button, which left a stretch of dead space once that became a
## plain icon. Reading the real width back, rather than another fixed
## number, also means this keeps working if the cog's font size (and so
## its width) ever becomes a player setting.
func _build_top_right_bar() -> void:
	var bar := HBoxContainer.new()
	top_right_bar = bar
	bar.add_theme_constant_override("separation", 6)
	bar.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	bar.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	bar.offset_right = -(SETTINGS_BUTTON_DEFAULT_WIDTH + SETTINGS_BUTTON_GAP)
	bar.offset_top = 8
	add_child(bar)

	# The speed buttons sit in their own tight group with no gaps, which
	# reads as one control rather than five and gives the extra speed
	# somewhere to go without pushing everything else off the bar.
	var speed_group := HBoxContainer.new()
	speed_group.add_theme_constant_override("separation", 1)
	bar.add_child(speed_group)

	for entry in SPEEDS:
		var btn := Button.new()
		btn.text = entry.label
		btn.tooltip_text = entry.tip
		btn.custom_minimum_size = Vector2(24, 26)
		btn.add_theme_font_size_override("font_size", 11)
		btn.focus_mode = Control.FOCUS_NONE
		btn.toggle_mode = true
		var scale_value: float = entry.scale
		btn.pressed.connect(func(): speed_requested.emit(scale_value))
		speed_group.add_child(btn)
		speed_buttons.append({"button": btn, "scale": scale_value})

	bar.add_child(_info("Game speed, as a multiple of normal. These change how fast the simulation runs; they do not change how much a bee gathers per in-game second."))

	colony_button = Button.new()
	colony_button.text = "Colony (C)"
	colony_button.custom_minimum_size = Vector2(80, 26)
	colony_button.pressed.connect(func(): colony_panel_requested.emit())
	bar.add_child(colony_button)
	colony_info = _info("Open the colony overview: how many bees are on each job, what is in the comb, how the brood is doing, and how any of that has changed over time. Click a role in it to select every bee doing that job at once.")
	bar.add_child(colony_info)

	nursery_button = Button.new()
	nursery_button.text = "Nursery (N)"
	nursery_button.custom_minimum_size = Vector2(84, 26)
	nursery_button.pressed.connect(func(): nursery_window_requested.emit())
	bar.add_child(nursery_button)
	nursery_info = _info("Open the nursery zone window: which cells are set to raise which role, what the colony is made of now, and how many of each kind have emerged recently. While it is open the zone cells glow on the comb.")
	bar.add_child(nursery_info)

	# Only appears once a winter has been scheduled -- until then there is
	# nothing for it to say, and a permanently dead button is worse than
	# no button.
	winter_button = Button.new()
	winter_button.text = "Winter"
	winter_button.custom_minimum_size = Vector2(62, 26)
	winter_button.visible = Session.winter_coming
	winter_button.pressed.connect(func(): winter_window_requested.emit())
	bar.add_child(winter_button)

	view_button = Button.new()
	view_button.text = "Hive"
	view_button.custom_minimum_size = Vector2(64, 26)
	view_button.pressed.connect(func(): view_toggle_requested.emit())
	bar.add_child(view_button)
	view_info = _info("Switch between the meadow (flowers and foragers) and the hive interior (comb, queen, brood) -- or press Tab. Both keep simulating whichever one you are looking at.")
	bar.add_child(view_info)

	# Sits directly under the button row, anchored and widened the same
	# way -- see set_settings_button_width. Hidden outside a Challenge;
	# challenge_runner.gd is the only caller of set_challenge_goal.
	goal_label = Label.new()
	goal_label.visible = false
	goal_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	goal_label.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	goal_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	goal_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	goal_label.offset_right = -(SETTINGS_BUTTON_DEFAULT_WIDTH + SETTINGS_BUTTON_GAP)
	goal_label.offset_top = 38
	goal_label.custom_minimum_size = Vector2(320, 0)
	goal_label.add_theme_font_size_override("font_size", 13)
	goal_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.6))
	add_child(goal_label)

## Called by debug_panel.gd whenever its settings cog's actual width
## changes (including the first layout pass), so this bar sits exactly
## as far from the corner as the cog needs and no further -- see the
## comment on _build_top_right_bar.
func set_settings_button_width(width: float) -> void:
	if top_right_bar == null:
		return
	top_right_bar.offset_right = -(width + SETTINGS_BUTTON_GAP)
	goal_label.offset_right = -(width + SETTINGS_BUTTON_GAP)

## Shown under the top-right button row for the length of a Challenge --
## see TUTORIAL_PLAN.md. Empty text hides it again.
func set_challenge_goal(text: String) -> void:
	goal_label.text = text
	goal_label.visible = not text.is_empty()

func set_speed_display(speed_scale: float) -> void:
	for entry in speed_buttons:
		entry.button.button_pressed = is_equal_approx(entry.scale, speed_scale)

func _build_selection_panel() -> void:
	selection_panel = PanelContainer.new()
	# anchored to the bottom-left so it stays put when the window resizes
	selection_panel.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	selection_panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	selection_panel.offset_left = 16
	selection_panel.offset_bottom = -16
	selection_panel.visible = false
	add_child(selection_panel)

	var column := VBoxContainer.new()
	selection_panel.add_child(column)

	selection_label = Label.new()
	selection_label.add_theme_font_size_override("font_size", 12)
	column.add_child(selection_label)

	# what the bee is doing right this second
	task_label = Label.new()
	task_label.add_theme_font_size_override("font_size", 12)
	task_label.add_theme_color_override("font_color", Color(0.75, 0.9, 1.0))
	column.add_child(task_label)

	# Rebuilt from scratch on every selection change -- which controls make
	# sense depends on what's currently selected. See
	# _rebuild_role_controls.
	#
	# A column of short rows rather than one long row of everything: the
	# panel had grown to a dozen controls side by side, which ran off the
	# screen and gave no clue which control belonged to which idea. The
	# rows are now grouped by question -- what is it, how is it doing it,
	# what should it do next -- which is roughly the order you think in.
	role_row = VBoxContainer.new()
	role_row.add_theme_constant_override("separation", 3)
	column.add_child(role_row)

# --- cell popup ---------------------------------------------------

## The popup had grown to five rows of buttons plus two checkboxes, all
## on screen at once, which is more than anyone can scan while a click is
## in progress. It's now grouped into collapsible sections, the same
## pattern the settings window uses.
##
## Only "Reserve for" starts open, because that is the one thing you do
## to nearly every cell. The rest are things you do occasionally and
## deliberately, so they're one click away rather than always in the way.
## Which sections are open is remembered for the session, so a player who
## works in the zone a lot doesn't reopen it every time.
var cell_sections: Dictionary = {}     # title -> the VBox holding its rows
var cell_section_open: Dictionary = {}
## Popup buttons whose appearance tracks the state of the cell being
## shown, keyed by what they represent. Lit up in _refresh_cell_popup, so
## "which priority is this cell on" and "is this one sealed" are readable
## without hunting through the text above.
var live_buttons: Dictionary = {}

func _build_cell_popup() -> void:
	cell_popup = PopupPanel.new()
	add_child(cell_popup)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 2)
	cell_popup.add_child(column)

	cell_popup_label = Label.new()
	cell_popup_label.add_theme_font_size_override("font_size", 12)
	column.add_child(cell_popup_label)

	var row := HBoxContainer.new()
	_cell_section(column, "Reserve for", true).add_child(row)

	var nectar_btn := Button.new()
	nectar_btn.text = "Nectar"
	nectar_btn.focus_mode = Control.FOCUS_NONE
	nectar_btn.pressed.connect(func(): _request_designation("nectar"))
	live_buttons["designation_nectar"] = nectar_btn
	row.add_child(_with_info(nectar_btn, "Reserve this cell for nectar. Foragers carrying pollen will walk past it."))

	var pollen_btn := Button.new()
	pollen_btn.text = "Pollen"
	pollen_btn.focus_mode = Control.FOCUS_NONE
	pollen_btn.pressed.connect(func(): _request_designation("pollen"))
	live_buttons["designation_pollen"] = pollen_btn
	row.add_child(_with_info(pollen_btn, "Reserve this cell for pollen. Foragers carrying nectar will walk past it."))

	var honey_btn := Button.new()
	honey_btn.text = "Honey"
	honey_btn.focus_mode = Control.FOCUS_NONE
	honey_btn.pressed.connect(func(): _request_designation("honey"))
	live_buttons["designation_honey"] = honey_btn
	row.add_child(_with_info(honey_btn, "Reserve this cell for honey. Honey makers spit their chewed nectar mix into cells like this one and then fan it dry."))

	var jelly_btn := Button.new()
	jelly_btn.text = "Jelly"
	jelly_btn.focus_mode = Control.FOCUS_NONE
	jelly_btn.pressed.connect(func(): _request_designation("jelly"))
	live_buttons["designation_jelly"] = jelly_btn
	row.add_child(_with_info(jelly_btn, "Reserve this cell for royal jelly. Nurses on the royal jelly sub-mode store what they make here, and draw on it when feeding gyne larvae."))

	var egg_btn := Button.new()
	egg_btn.text = "Eggs"
	egg_btn.focus_mode = Control.FOCUS_NONE
	egg_btn.pressed.connect(func(): _request_designation("brood"))
	live_buttons["designation_brood"] = egg_btn
	row.add_child(_with_info(egg_btn, "Reserve this cell as a nursery. The queen lays here first, and foragers won't fill it with stores. Reserving enough of these is what stops laying stalling for want of a free cell."))

	var auto_btn := Button.new()
	auto_btn.text = "Unreserve"
	auto_btn.focus_mode = Control.FOCUS_NONE
	auto_btn.pressed.connect(func(): _request_designation(""))
	live_buttons["designation_any"] = auto_btn
	row.add_child(_with_info(auto_btn, "Remove the reservation. The cell takes whichever resource arrives first, and reserves itself for that from then on."))

	_build_zone_controls(_cell_section(column, "Nursery zone", false))
	_build_closing_controls(_cell_section(column, "Sealing", false))
	_build_empty_controls(_cell_section(column, "Emptying", false))

	var raises := _cell_section(column, "Raises", false)

	# Which role a bee raised here comes out as.
	var hatch_row := HBoxContainer.new()
	raises.add_child(hatch_row)
	var hatch_title := Label.new()
	hatch_title.text = "Raises:"
	hatch_title.add_theme_font_size_override("font_size", 11)
	hatch_row.add_child(hatch_title)
	hatch_row.add_child(_info("Set what a bee raised in this cell becomes when it emerges. Roles that have a sub-mode -- a forager's resource, whether a miner starts automining -- offer it here, so the new bee arrives already set up."))

	for entry in hatch_options():
		var options: Array = entry.options
		if options.size() == 1:
			var btn := Button.new()
			btn.text = entry.label
			btn.add_theme_font_size_override("font_size", 11)
			var role_value: int = entry.role
			var only: Dictionary = options[0]
			btn.pressed.connect(func(): _request_hatch_role(role_value, only.focus, only.automine))
			hatch_row.add_child(btn)
		else:
			hatch_row.add_child(_make_hatch_menu(entry))

	# Whether that role sticks for every future bee, or applies once.
	var lock_row := HBoxContainer.new()
	raises.add_child(lock_row)
	hatch_lock_box = CheckBox.new()
	hatch_lock_box.text = "Keep for every bee"
	hatch_lock_box.add_theme_font_size_override("font_size", 11)
	hatch_lock_box.toggled.connect(func(pressed: bool):
		if active_cell and is_instance_valid(active_cell):
			cell_hatch_lock_requested.emit(active_cell, pressed)
			_refresh_cell_popup()
	)
	lock_row.add_child(hatch_lock_box)

	# Whether the queen lays a gyne here rather than a worker.
	var gyne_row := HBoxContainer.new()
	raises.add_child(gyne_row)
	gyne_box = CheckBox.new()
	gyne_box.text = "Raise a gyne (a future queen)"
	gyne_box.add_theme_font_size_override("font_size", 11)
	gyne_box.toggled.connect(func(pressed: bool):
		if active_cell and is_instance_valid(active_cell):
			cell_gyne_requested.emit(active_cell, pressed)
			_refresh_cell_popup()
	)
	gyne_row.add_child(gyne_box)
	gyne_row.add_child(_info("A gyne is a future queen. She costs the queen several times as much pollen to lay, takes four times as long to develop, and can only be fed on royal jelly with pollen and honey -- so you need nurses producing jelly before one will grow at all. She can do any worker job in the meantime, though she is bigger, slower and hungrier than a worker."))
	lock_row.add_child(_info("On: every bee this cell ever raises comes out in the chosen role, so you can earmark a cell as a builder nursery once and forget about it. Off: the role applies to the next bee only and then clears, so a one-off choice doesn't quietly govern the cell forever."))

## Adds a collapsible section to the popup and returns the container its
## rows should go into. The header button toggles it; the arrow says
## which way it will go, which is the convention everywhere else.
func _cell_section(column: VBoxContainer, title: String, open_by_default: bool) -> VBoxContainer:
	if not cell_section_open.has(title):
		cell_section_open[title] = open_by_default

	var header := Button.new()
	header.alignment = HORIZONTAL_ALIGNMENT_LEFT
	header.add_theme_font_size_override("font_size", 12)
	header.focus_mode = Control.FOCUS_NONE
	column.add_child(header)

	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 2)
	body.visible = cell_section_open[title]
	column.add_child(body)

	header.text = "%s  %s" % ["▾" if body.visible else "▸", title]
	header.pressed.connect(func():
		cell_section_open[title] = not cell_section_open[title]
		body.visible = cell_section_open[title]
		header.text = "%s  %s" % ["▾" if body.visible else "▸", title]
		# the popup was sized to the old contents, so let it shrink or
		# grow to fit what's showing now
		cell_popup.reset_size()
	)

	cell_sections[title] = body
	return body

## The nursery zone: which cells the queen lays in, and how hard she
## favours each one.
##
## The reason this is a zone rather than a per-cell setting is that
## setting twenty cells one at a time is admin, not strategy. Select a
## block of comb, put it in the zone, give it a role and a tier, and the
## proportions look after themselves from then on.
func _build_zone_controls(column: VBoxContainer) -> void:
	var row := HBoxContainer.new()
	column.add_child(row)

	var title := Label.new()
	title.text = "Nursery zone:"
	title.add_theme_font_size_override("font_size", 11)
	row.add_child(title)

	var add_btn := Button.new()
	add_btn.text = "Add"
	add_btn.add_theme_font_size_override("font_size", 11)
	add_btn.pressed.connect(func(): _request_zone(true))
	row.add_child(_with_info(add_btn, "Put the selected cells into the nursery zone. They are reserved for brood, the queen lays in them ahead of ordinary comb, and foragers leave them alone. Set what each one raises with the \"Raises\" buttons below."))

	var remove_btn := Button.new()
	remove_btn.text = "Remove"
	remove_btn.add_theme_font_size_override("font_size", 11)
	remove_btn.pressed.connect(func(): _request_zone(false))
	row.add_child(_with_info(remove_btn, "Take the selected cells back out of the zone. They go back to holding whatever arrives first."))

	var open_btn := Button.new()
	open_btn.text = "Open zone window"
	open_btn.add_theme_font_size_override("font_size", 11)
	open_btn.pressed.connect(func(): nursery_window_requested.emit())
	row.add_child(_with_info(open_btn, "Open the nursery window: how many cells are assigned to each role and tier, what the colony is made of right now, and how many bees of each kind have emerged in the last three minutes. While it is open every zone cell glows in the colour of the role it raises."))

	var tier_row := HBoxContainer.new()
	column.add_child(tier_row)

	var tier_title := Label.new()
	tier_title.text = "Priority:"
	tier_title.add_theme_font_size_override("font_size", 11)
	tier_row.add_child(tier_title)

	for tier in range(3):
		var btn := Button.new()
		btn.text = ["Low", "Medium", "High"][tier]
		btn.add_theme_font_size_override("font_size", 11)
		btn.focus_mode = Control.FOCUS_NONE
		var tier_value: int = tier
		btn.pressed.connect(func(): _request_priority(tier_value))
		tier_row.add_child(btn)
		# tracked so _refresh_cell_popup can light up whichever is in
		# force on the cell being shown
		live_buttons["priority_%d" % tier] = btn

	tier_row.add_child(_info("How much of the queen's laying this cell gets. She shares eggs between the three tiers in proportion to their weights -- by default 1 : 2 : 3 -- so a high cell receives three eggs for every one a low cell receives, and they come out interleaved rather than in streaks. Twelve high forager cells beside three low nurse cells is how you say \"mostly foragers, a few nurses\" once and then leave it alone. The weights themselves are in the settings window."))

## Sealing a cell. A colony with honey in it drinks the honey; this is
## how you set some aside for a hard stretch instead.
func _build_closing_controls(column: VBoxContainer) -> void:
	var row := HBoxContainer.new()
	column.add_child(row)

	var title := Label.new()
	title.text = "Sealing:"
	title.add_theme_font_size_override("font_size", 11)
	row.add_child(title)

	var close_btn := Button.new()
	close_btn.text = "Sealed"
	close_btn.add_theme_font_size_override("font_size", 11)
	close_btn.focus_mode = Control.FOCUS_NONE
	close_btn.pressed.connect(func(): _request_close(true))
	row.add_child(_with_info(close_btn, "Seal the selected cells. Nothing can be added and nothing taken out until you open them again -- the contents are held in reserve. A sealed cell is drawn with a dark bar across it."))
	live_buttons["closed"] = close_btn

	var open_btn := Button.new()
	open_btn.text = "Open"
	open_btn.add_theme_font_size_override("font_size", 11)
	open_btn.focus_mode = Control.FOCUS_NONE
	open_btn.pressed.connect(func(): _request_close(false))
	row.add_child(_with_info(open_btn, "Unseal the selected cells so the colony can use what is in them again."))
	live_buttons["open"] = open_btn

	var fill_btn := Button.new()
	fill_btn.text = "Fill then seal"
	fill_btn.add_theme_font_size_override("font_size", 11)
	fill_btn.focus_mode = Control.FOCUS_NONE
	fill_btn.pressed.connect(func(): _request_fill_close())
	row.add_child(_with_info(fill_btn, "Keep taking deposits but refuse every withdrawal, and seal the cell the moment it is full. Without this a honey cell is sipped from as fast as it is filled and never quite gets to the top, so there is never a full pot to put by. A cell in this state is drawn with a yellow bar."))
	live_buttons["fill_close"] = fill_btn

## Clearing a cell out. This exists because a colony with plenty of
## foragers fills every spare cell with nectar, leaving nothing free for
## pollen or for the queen to lay in -- so emptying a cell is only half
## the job, and "keep it empty afterwards" is the other half.
func _build_empty_controls(column: VBoxContainer) -> void:
	var empty_row := HBoxContainer.new()
	column.add_child(empty_row)

	var title := Label.new()
	title.text = "Empty cell:"
	title.add_theme_font_size_override("font_size", 11)
	empty_row.add_child(title)

	var move_btn := Button.new()
	move_btn.text = "To another cell"
	move_btn.add_theme_font_size_override("font_size", 11)
	move_btn.pressed.connect(func(): _request_empty("move"))
	empty_row.add_child(_with_info(move_btn, "A builder comes and carries the contents to another cell with room for them. If nothing anywhere has room, the load is lost -- so keep an eye on how full the comb is."))

	var discard_btn := Button.new()
	discard_btn.text = "Discard outside"
	discard_btn.add_theme_font_size_override("font_size", 11)
	discard_btn.pressed.connect(func(): _request_empty("discard"))
	empty_row.add_child(_with_info(discard_btn, "Throw the contents out of the hive. Quicker than moving them, but everything in the cell is gone."))

	# This has to write straight through to the cell. It used to be read
	# back from the cell every frame by _refresh_cell_popup while only
	# being applied when one of the buttons above was pressed -- so
	# ticking it was undone a frame later and it looked like the option
	# could not be selected at all.
	var keep_row := HBoxContainer.new()
	column.add_child(keep_row)
	keep_empty_box = CheckBox.new()
	keep_empty_box.text = "Leave empty"
	keep_empty_box.add_theme_font_size_override("font_size", 11)
	keep_empty_box.toggled.connect(func(pressed: bool):
		if active_cell and is_instance_valid(active_cell):
			cell_keep_empty_requested.emit(active_cell, pressed)
			_refresh_cell_popup()
	)
	keep_row.add_child(keep_empty_box)
	keep_row.add_child(_info("On: the cell refuses every deposit once it's been cleared, so it stays free. This is what stops a crowd of foragers cramming nectar into the last spare pot and leaving nowhere for pollen or eggs. Reserving the cell for a resource later clears this again. Off: the cell goes back to taking whatever arrives first."))

## A dropdown for a role that has more than one way to start.
func _make_hatch_menu(entry: Dictionary) -> Control:
	var menu := MenuButton.new()
	menu.text = entry.label
	menu.add_theme_font_size_override("font_size", 11)
	var options: Array = entry.options
	var role_value: int = entry.role
	var popup := menu.get_popup()
	for i in range(options.size()):
		popup.add_item(options[i].label, i)
	popup.id_pressed.connect(func(id: int):
		_request_hatch_role(role_value, options[id].focus, options[id].automine)
	)
	return menu

## --- flower popup -------------------------------------------------

func _build_flower_popup() -> void:
	flower_popup = PopupPanel.new()
	add_child(flower_popup)

	flower_popup_label = Label.new()
	flower_popup_label.add_theme_font_size_override("font_size", 12)
	flower_popup.add_child(flower_popup_label)

## --- obstacle popup -----------------------------------------------
## Clicking a tree or a bank of raised ground says what it is, so the
## things bees have to walk round aren't unexplained scenery.

## --- warning banner -----------------------------------------------
## A nudge, not an interruption: it sits at the top of the screen, the
## game carries on running behind it, and it clears itself after a while
## if the player doesn't dismiss it.

const WARNING_SECONDS := 18.0

func _build_warning_banner() -> void:
	warning_panel = PanelContainer.new()
	warning_panel.set_anchors_preset(Control.PRESET_CENTER_TOP)
	warning_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	warning_panel.offset_top = 48
	warning_panel.custom_minimum_size = Vector2(520, 0)
	warning_panel.visible = false
	add_child(warning_panel)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	warning_panel.add_child(row)

	warning_label = Label.new()
	warning_label.add_theme_font_size_override("font_size", 13)
	warning_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.5))
	warning_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	warning_label.custom_minimum_size = Vector2(450, 0)
	row.add_child(warning_label)

	var close_btn := Button.new()
	close_btn.text = "×"
	close_btn.custom_minimum_size = Vector2(28, 28)
	close_btn.pressed.connect(func(): warning_panel.visible = false)
	row.add_child(close_btn)

func show_warning(text: String) -> void:
	if warnings_muted:
		return
	warning_label.text = text
	warning_panel.visible = true
	warning_timer = WARNING_SECONDS

func set_warnings_muted(value: bool) -> void:
	warnings_muted = value
	if value:
		warning_panel.visible = false

func _build_obstacle_popup() -> void:
	obstacle_popup = PopupPanel.new()
	add_child(obstacle_popup)

	obstacle_popup_label = Label.new()
	obstacle_popup_label.add_theme_font_size_override("font_size", 12)
	obstacle_popup_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	obstacle_popup_label.custom_minimum_size = Vector2(260, 0)
	obstacle_popup.add_child(obstacle_popup_label)

func show_obstacle_popup(obstacle: Node2D, screen_position: Vector2) -> void:
	obstacle_popup_label.text = "%s\n\n%s" % [obstacle.display_name(), obstacle.description()]
	obstacle_popup.position = Vector2i(screen_position + Vector2(12, -10))
	obstacle_popup.popup()

func show_flower_popup(flower: Node2D, screen_position: Vector2) -> void:
	active_flower = flower
	_refresh_flower_popup()
	flower_popup.position = Vector2i(screen_position + Vector2(12, -10))
	flower_popup.popup()

func _refresh_flower_popup() -> void:
	if active_flower == null or not is_instance_valid(active_flower):
		return
	var lines := []
	lines.append(active_flower.species_name)
	lines.append("Nectar: %d / %d   (+%.2f/s)" % [
		int(round(active_flower.nectar_amount)),
		int(active_flower.nectar_capacity),
		active_flower.nectar_recharge_rate,
	])
	lines.append("Pollen: %d / %d   (+%.2f/s)" % [
		int(round(active_flower.pollen_amount)),
		int(active_flower.pollen_capacity),
		active_flower.pollen_recharge_rate,
	])
	if active_flower.occupied_by != null and is_instance_valid(active_flower.occupied_by):
		lines.append("Being worked by bee %d" % active_flower.occupied_by.bee_id)
	else:
		lines.append("No bee here")
	var age: float = active_flower.marker_age()
	if age >= 0.0:
		var fresh := age < GameConfig.tarsal_marker_seconds
		lines.append("Scent mark: %ds old%s" % [int(age), " (bees avoiding)" if (fresh and GameConfig.tarsal_markers_on) else ""])
	flower_popup_label.text = "\n".join(lines)

## --- soil popup ---------------------------------------------------

func _build_soil_popup() -> void:
	soil_popup = PopupPanel.new()
	add_child(soil_popup)

	var column := VBoxContainer.new()
	soil_popup.add_child(column)

	soil_popup_label = Label.new()
	soil_popup_label.add_theme_font_size_override("font_size", 12)
	soil_popup_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	soil_popup_label.custom_minimum_size = Vector2(280, 0)
	column.add_child(soil_popup_label)

	var row := HBoxContainer.new()
	column.add_child(row)

	var mark_btn := Button.new()
	mark_btn.text = "Mark for digging"
	mark_btn.pressed.connect(func(): soil_mark_requested.emit(true); soil_popup.hide())
	row.add_child(_with_info(mark_btn, "Flag every selected block for miners to dig out. Blocks buried behind other soil can be marked too -- miners simply cannot reach them until the ones in front are gone, so a marked seam digs itself inward layer by layer."))

	var clear_btn := Button.new()
	clear_btn.text = "Clear marks"
	clear_btn.pressed.connect(func(): soil_mark_requested.emit(false); soil_popup.hide())
	row.add_child(_with_info(clear_btn, "Take the digging flag off the selected blocks. Any digging already done is kept, so you can put the mark back later without losing the work."))

func show_soil_popup(count: int, reachable: int, screen_position: Vector2) -> void:
	var text := "%d soil block%s selected" % [count, "" if count == 1 else "s"]
	if reachable < count:
		text += "\n%d can be reached right now; the rest are buried and will be dug once the soil in front of them is gone." % reachable
	soil_popup_label.text = text
	soil_popup.position = Vector2i(screen_position + Vector2(12, -10))
	soil_popup.popup()

func show_cell_popup(cell: Node2D, screen_position: Vector2, count: int = 1) -> void:
	active_cell = cell
	selected_cell_count = count
	_refresh_cell_popup()
	cell_popup.position = Vector2i(screen_position + Vector2(12, -10))
	cell_popup.popup()

func _refresh_cell_popup() -> void:
	if active_cell == null or not is_instance_valid(active_cell):
		return
	var lines := []
	if selected_cell_count > 1:
		lines.append("%d cells selected — everything below applies to all of them" % selected_cell_count)
		lines.append("Showing: the first one")
	if not active_cell.is_built:
		lines.append("Unfinished cell -- %d%% built" % int(active_cell.build_fraction() * 100.0))
	else:
		match active_cell.content_type:
			"nectar":
				lines.append("Nectar: %d / %d" % [int(round(active_cell.amount)), int(active_cell.capacity)])
			"pollen":
				lines.append("Pollen: %d / %d" % [int(round(active_cell.amount)), int(active_cell.capacity)])
			"jelly":
				lines.append("Royal jelly: %d / %d" % [int(round(active_cell.amount)), int(active_cell.capacity)])
			"honey":
				if active_cell.is_ripe_honey():
					lines.append("Honey: %d / %d" % [int(round(active_cell.amount)), int(active_cell.capacity)])
				else:
					lines.append("Honey mix: %d / %d -- %d%% fanned dry" % [
						int(round(active_cell.amount)),
						int(active_cell.capacity),
						int(active_cell.ripen_fraction() * 100.0),
					])
					lines.append("Not edible until it is fully dried out.")
			"brood":
				lines.append("%s -- %d%%" % [
					"Developing gyne" if active_cell.brood_is_gyne else "Developing bee",
					int(active_cell.development_percent()),
				])
				if active_cell.brood_is_gyne:
					lines.append("Needs royal jelly, pollen and honey. Nothing else will do.")
				if active_cell.brood_fed_seconds > 0.0:
					lines.append("Fed on %s -- %ds of development left in it" % [
						"honey" if active_cell.fed_on_honey else "nectar",
						int(active_cell.brood_fed_seconds),
					])
				else:
					lines.append("Hungry -- development has stopped. It dies in %ds if nobody feeds it" % int(active_cell.seconds_until_death()))
			"corpse":
				lines.append("A larva starved here. The body blocks the cell.")
				lines.append("Being cleared: %d%% -- a comb worker on cell maintenance has to carry it out" % int(active_cell.clean_fraction() * 100.0))
			_:
				lines.append("Empty")
	var reserved := "any resource"
	if active_cell.keep_empty:
		reserved = "nothing -- kept empty"
	elif active_cell.designated_type == "brood":
		reserved = "raising eggs"
	elif active_cell.designated_type != "":
		reserved = active_cell.designated_type
	lines.append("Takes: %s" % reserved)
	if active_cell.is_nursery_cell():
		lines.append("Nursery zone — %s priority" % ["low", "medium", "high"][clampi(active_cell.nursery_priority, 0, 2)])
	if active_cell.is_closed:
		lines.append("Sealed — nothing goes in or comes out")
	elif active_cell.fill_then_close:
		lines.append("Filling to the top, then sealing. Withdrawals refused meanwhile")
	if active_cell.evict_requested:
		lines.append("Waiting for a builder to carry the contents out")

	var hatch_name := "colony default"
	for entry in hatch_options():
		if entry.role == active_cell.hatch_role:
			hatch_name = entry.label
			if entry.role == 0:
				hatch_name += " (%s)" % active_cell.hatch_focus
			elif entry.role == 5 and active_cell.hatch_automine:
				hatch_name += " (automine)"
			break
	lines.append("Raises: %s%s" % [
		hatch_name,
		" -- every bee" if active_cell.hatch_role_locked else "",
	])
	cell_popup_label.text = "\n".join(lines)

	# reflect the cell's own state without re-firing the signals
	keep_empty_box.set_pressed_no_signal(active_cell.keep_empty)
	hatch_lock_box.set_pressed_no_signal(active_cell.hatch_role_locked)
	gyne_box.set_pressed_no_signal(active_cell.hatch_gyne)
	_light_current_options()

## Lights up whichever popup buttons match the state of the cell being
## shown, so the current reservation, priority tier and seal state are
## visible at a glance instead of only in the text above.
func _light_current_options() -> void:
	var designation: String = active_cell.designated_type
	if active_cell.keep_empty:
		designation = ""
	_set_lit("designation_nectar", designation == "nectar")
	_set_lit("designation_pollen", designation == "pollen")
	_set_lit("designation_honey", designation == "honey")
	_set_lit("designation_jelly", designation == "jelly")
	_set_lit("designation_brood", designation == "brood")
	_set_lit("designation_any", designation == "" and not active_cell.keep_empty)

	for tier in range(3):
		_set_lit("priority_%d" % tier, active_cell.is_nursery_cell() and active_cell.nursery_priority == tier)

	_set_lit("closed", active_cell.is_closed)
	_set_lit("fill_close", active_cell.fill_then_close)
	_set_lit("open", not active_cell.is_closed and not active_cell.fill_then_close)

func _set_lit(key: String, lit: bool) -> void:
	if not live_buttons.has(key):
		return
	var button: Button = live_buttons[key]
	if not is_instance_valid(button):
		return
	if lit:
		UI.mark_as_current(button)
	else:
		UI.clear_current_mark(button)

func _process(_delta: float) -> void:
	Perf.begin("hud")
	if warning_panel.visible:
		warning_timer -= _delta
		if warning_timer <= 0.0:
			warning_panel.visible = false
	if cell_popup.visible:
		_refresh_cell_popup()
	if flower_popup.visible:
		_refresh_flower_popup()
	if selection_panel.visible:
		_refresh_selection_text()
	Perf.end("hud")

func _request_designation(type: String) -> void:
	if active_cell and is_instance_valid(active_cell):
		cell_designation_requested.emit(active_cell, type)
		_refresh_cell_popup()

func _request_hatch_role(role: int, focus: String, use_automine: bool) -> void:
	if active_cell and is_instance_valid(active_cell):
		cell_hatch_role_requested.emit(active_cell, role, focus, use_automine)
		_refresh_cell_popup()

func _request_empty(method: String) -> void:
	if active_cell and is_instance_valid(active_cell):
		cell_empty_requested.emit(active_cell, method, keep_empty_box.button_pressed)
		_refresh_cell_popup()

func _request_zone(in_zone: bool) -> void:
	if active_cell and is_instance_valid(active_cell):
		cell_zone_requested.emit(active_cell, in_zone)
		_refresh_cell_popup()

func _request_priority(tier: int) -> void:
	if active_cell and is_instance_valid(active_cell):
		cell_priority_requested.emit(active_cell, tier)
		_refresh_cell_popup()

func _request_close(closed: bool) -> void:
	if active_cell and is_instance_valid(active_cell):
		cell_close_requested.emit(active_cell, closed)
		_refresh_cell_popup()

func _request_fill_close() -> void:
	if active_cell and is_instance_valid(active_cell):
		cell_fill_close_requested.emit(active_cell)
		_refresh_cell_popup()

# --- discard warning ----------------------------------------------

## "Don't warn me again" is a third button rather than a checkbox.
## AcceptDialog lays out its own message label and doesn't reliably
## position arbitrary child controls beneath it, so an extra button is
## the sturdier choice here.
func _build_discard_dialog() -> void:
	discard_dialog = ConfirmationDialog.new()
	discard_dialog.title = "Nothing else can hold this"
	discard_dialog.ok_button_text = "Discard it"
	discard_dialog.cancel_button_text = "Leave the cell as it is"
	add_child(discard_dialog)

	discard_dialog.add_button("Discard, and stop warning me", true, "discard_always")
	discard_dialog.confirmed.connect(_on_discard_confirmed)
	discard_dialog.custom_action.connect(_on_discard_custom_action)

## Called by main.gd when re-designating a cell would destroy whatever
## is already in it, because no other cell has room.
func show_discard_warning(cell: Node2D, new_type: String, existing_type: String, existing_amount: float) -> void:
	pending_cell = cell
	pending_type = new_type
	discard_dialog.dialog_text = (
		"This cell holds %d %s, and there is no other cell with room for it.\n\n"
		+ "Reserving it for %s will throw that away."
	) % [int(round(existing_amount)), existing_type, new_type]
	discard_dialog.popup_centered()

func _on_discard_confirmed() -> void:
	_apply_discard()

func _on_discard_custom_action(action: StringName) -> void:
	if action == "discard_always":
		Session.warn_on_discard = false
		discard_dialog.hide()
		_apply_discard()

func _apply_discard() -> void:
	if pending_cell and is_instance_valid(pending_cell):
		pending_cell.clear_cell()
		pending_cell.set_designation(pending_type)
	pending_cell = null
	pending_type = ""
	_refresh_cell_popup()

# --- readouts -----------------------------------------------------

## `note` is where the colony is in the year, and how many gynes it has
## got away -- both live beside the day counter because together they are
## the run: how far through, and how much to show for it.
func update_day(day: int, note: String = "") -> void:
	corner_texts["day"] = "Day %d" % day
	if note != "":
		corner_texts["day"] += "\n%s" % note
	_refresh_corner()

## Honey is counted only once it's fully fanned dry -- wet mix still
## drying in a cell isn't a store the colony can use yet. Anything sealed
## into closed cells is called out separately: it's still the colony's,
## but nothing can eat it until the cells are opened again.
func update_storage(nectar: float, pollen: float, honey: float, jelly: float, sealed: float = 0.0) -> void:
	var text := "Nectar: %d   Pollen: %d   Honey: %d   Jelly: %d" % [
		int(round(nectar)), int(round(pollen)), int(round(honey)), int(round(jelly)),
	]
	if sealed > 0.5:
		text += "\n(%d sealed away in closed cells)" % int(round(sealed))
	corner_texts["stores"] = text
	_refresh_corner()

func update_population(foragers: int, nurses: int, builders: int, honey_makers: int) -> void:
	corner_texts["population"] = "Bees: %d foraging, %d nursing, %d comb workers, %d on honey" % [
		foragers, nurses, builders, honey_makers,
	]
	_refresh_corner()

func update_comb(text: String) -> void:
	corner_texts["comb"] = text
	_refresh_corner()

func update_energy(mean_fraction: float) -> void:
	corner_texts["energy"] = "Average energy: %d%%" % int(round(mean_fraction * 100.0))
	_refresh_corner()

## `births_per_sec` is shown per minute instead -- birth events are rare
## enough (one every 90s+ per brood cell) that a per-second figure would
## always read as an unreadable 0.0x.
func update_rates(nectar_per_sec: float, pollen_per_sec: float, births_per_sec: float) -> void:
	corner_texts["rates"] = "Rates (60s avg): Nectar +%.1f/s   Pollen +%.1f/s   Births %.2f/min" % [
		nectar_per_sec, pollen_per_sec, births_per_sec * 60.0,
	]
	_refresh_corner()

## The frame rate readout. Three numbers rather than one, because they
## answer different questions: the average tells you whether the game is
## fast enough, the current frame time tells you what that average is
## made of, and the worst frame in the last second is the one you
## actually felt. Smooth play with an occasional 60ms frame reads as
## choppy while the average still says 60.
func update_fps(average: int, frame_ms: float, worst_ms: float) -> void:
	corner_texts["fps"] = "%d fps   %.1f ms   worst %.0f ms" % [average, frame_ms, worst_ms]
	_refresh_corner()

## `lines` is an array of [text, severity] pairs from main.gd.
func update_signals(lines: Array) -> void:
	shown_signals = lines
	corner_texts["signals"] = "\n".join(lines.map(func(e): return "• %s" % e[0]))
	_refresh_corner()

## Rebuilds the corner from the starred readouts. Only actually does the
## work when the result would look different, so this can be called from
## every setter without thrashing labels every frame.
func _refresh_corner() -> void:
	Perf.begin("corner_refresh")
	var signature := ""
	for key in CORNER_ORDER:
		if Session.pinned_stats.has(key):
			signature += "%s=%s\n" % [key, corner_texts.get(key, "")]
	var show_signals: bool = Session.pinned_stats.has("signals")
	if show_signals:
		for entry in shown_signals:
			signature += "s%d|%s\n" % [entry[1], entry[0]]
	if signature == corner_signature:
		Perf.end("corner_refresh")
		return
	corner_signature = signature

	for child in corner_column.get_children():
		# perf_plot and perf_breakdown are persistent -- see their
		# declaration -- so their own redraw timing survives a rebuild
		# triggered by something unrelated, like the day counter.
		if child == perf_plot or child == perf_breakdown:
			continue
		child.queue_free()

	for key in CORNER_ORDER:
		if not Session.pinned_stats.has(key):
			continue
		var text: String = str(corner_texts.get(key, ""))
		if text == "":
			continue
		var label := Label.new()
		label.text = text
		label.add_theme_font_size_override("font_size", int(CORNER_SIZES.get(key, 12)))
		corner_column.add_child(label)

	# Sits under whichever readouts are starred, same as the plan asked
	# for "under the three fps numbers" in the common case where fps is
	# the only thing starred while chasing a frame-time problem.
	var show_perf: bool = Session.pinned_stats.has("fps")
	perf_plot.visible = show_perf
	perf_breakdown.visible = show_perf
	if show_perf:
		corner_column.move_child(perf_plot, corner_column.get_child_count() - 1)
		corner_column.move_child(perf_breakdown, corner_column.get_child_count() - 1)

	if not show_signals:
		Perf.end("corner_refresh")
		return
	# Each line is a button rather than a label, so it can take you to
	# what it is about. Being told there are hungry larvae and then having
	# to go and find them yourself is most of the work of acting on it.
	for entry in shown_signals:
		var line := Button.new()
		line.text = "• %s" % entry[0]
		line.alignment = HORIZONTAL_ALIGNMENT_LEFT
		line.flat = true
		line.focus_mode = Control.FOCUS_NONE
		line.add_theme_font_size_override("font_size", 12)
		line.add_theme_color_override("font_color", SIGNAL_COLOURS[clampi(entry[1], 0, 2)])
		line.add_theme_color_override("font_hover_color", Color.WHITE)
		var action: String = entry[2] if entry.size() > 2 else ""
		if action != "":
			line.tooltip_text = "Click to select what this is about."
			line.pressed.connect(func(): signal_clicked.emit(action))
		corner_column.add_child(line)
	Perf.end("corner_refresh")

## Called when the player stars or unstars something in either window:
## the corner has to be redrawn even though no number changed. Also the
## one place that keeps Session.perf_enabled in step with the "fps"
## star, so perf.gd's instrumentation only runs while someone could
## actually be looking at it.
func pinned_stats_changed() -> void:
	Session.perf_enabled = Session.pinned_stats.has("fps")
	corner_signature = ""
	_refresh_corner()

## For callers that have written into `corner_texts` directly, rather
## than through one of the update_* setters.
func refresh_corner() -> void:
	_refresh_corner()

func update_selection(bees: Array) -> void:
	shown_bees = bees
	selection_panel.visible = not bees.is_empty()
	if bees.is_empty():
		return

	_rebuild_role_controls(bees)
	_refresh_selection_text()

## The selection panel's controls, rebuilt from scratch whenever the
## selection changes.
##
## Laid out as a short column of labelled rows rather than one long strip
## of buttons. The rows answer, in order, the three things you want to
## know about a selected bee:
##
##   Job      what it is, and what else it could be
##   Doing    the sub-mode of that job, where it has one
##   Orders   the "click a spot" actions that apply to it
##
## with the backup role and the finish-first switch underneath. Roles it
## isn't doing now live inside one dropdown instead of a button each,
## which is what was making the panel wider than the screen.
func _rebuild_role_controls(bees: Array) -> void:
	for child in role_row.get_children():
		child.queue_free()

	var common_role: int = _common_role(bees)
	var first = bees[0] if is_instance_valid(bees[0]) else null
	var any_queen := false
	for b in bees:
		if is_instance_valid(b) and b.is_queen:
			any_queen = true
			break

	var show_queen_build_row: bool = show_queen_build_button and bees.size() == 1 and first != null and first.is_queen
	if show_queen_build_row:
		_build_queen_build_row()
	_build_job_row(common_role, any_queen)
	_build_doing_row(common_role, first)
	# Skipped while the queen's own "Build cell" button is showing --
	# that button is the one build control Challenge 1 wants here, not
	# also the ordinary placement/home-cell controls this row offers.
	if not show_queen_build_row:
		_build_orders_row(common_role, first)
	_build_fallback_row(common_role, first)
	if bees.size() == 1 and first != null:
		_build_favourite_row(first)

## Challenge 1 only -- see set_queen_build_button_visible.
func _build_queen_build_row() -> void:
	var row := _labelled_row("Build")
	var button := Button.new()
	button.text = "Build cell"
	button.custom_minimum_size = Vector2(0, 26)
	button.pressed.connect(func(): queen_build_cell_requested.emit())
	row.add_child(button)

## The star toggle -- only offered for one bee at a time, so "favourite"
## always names one individual rather than a whole selection. Lets the
## player find this bee again later from the colony window's
## Favourites list. See BEE_INDIVIDUALITY_PLAN.md section 7.
func _build_favourite_row(bee) -> void:
	var row := _labelled_row("Mark")
	row.add_child(_toggle_button(
		"★ Favourite" if bee.is_favourite else "☆ Favourite", bee.is_favourite,
		func(): favourite_requested.emit(not bee.is_favourite),
		"Pin this bee by name so you can find it again in the colony window's Favourites list, in a colony of hundreds."
	))

## Job: what the selection is, lit up, plus one dropdown holding every
## role it could be switched to.
func _build_job_row(common_role: int, any_queen: bool) -> void:
	var row := _labelled_row("Job")
	if common_role == -1:
		var mixed := Label.new()
		mixed.text = "mixed selection"
		mixed.add_theme_font_size_override("font_size", 11)
		mixed.add_theme_color_override("font_color", Color(0.8, 0.8, 0.6))
		row.add_child(mixed)
	else:
		row.add_child(_current_role_marker(Roles.label_for(common_role)))

	var items: Array = []
	for role in Roles.ROLES:
		if role.id == common_role:
			continue                       # already doing it
		if role.id == Roles.QUEEN and not any_queen:
			continue                       # queen only
		var key: String = role.key
		if not allowed_role_keys.is_empty() and not allowed_role_keys.has(key):
			continue                       # a Challenge hasn't taught this role yet
		items.append({
			"text": role.label,
			"action": func(): role_requested.emit(key),
		})
	if not items.is_empty():
		row.add_child(_make_role_menu("Change to…", "Switch the selected bees to another job. Sub-modes for that job appear on the Doing row once they are on it.", items))

## Doing: the sub-mode of the current job, where that job has one.
func _build_doing_row(common_role: int, first) -> void:
	var modes: Array = Roles.modes_for(common_role)
	if modes.is_empty() or first == null:
		return
	var row := _labelled_row("Doing")

	# What counts as "the mode this bee is on" differs by role -- a
	# forager's is the resource it collects, a miner's is a switch rather
	# than a choice between modes -- so each role says how to read it.
	for mode in modes:
		var key: String = mode.key
		# Only ever restricts the Forager's nectar/pollen choice -- that's
		# the only mode a Challenge currently teaches in stages. Every
		# other role's modes are unaffected regardless of this list.
		if common_role == Roles.FORAGER and not allowed_mode_keys.is_empty() and not allowed_mode_keys.has(key):
			continue
		var current: bool = _mode_is_active(common_role, first, key)
		var command: String = mode_command(common_role, key)
		row.add_child(_toggle_button(
			mode.label, current,
			func(): role_requested.emit(command),
			mode.tip
		))

## Is `bee` currently on this sub-mode?
func _mode_is_active(role_id: int, bee, mode_key: String) -> bool:
	match role_id:
		Roles.FORAGER:
			return bee.resource_type == mode_key
		Roles.NURSE:
			return bee.nurse_mode == mode_key
		Roles.COMB_WORKER:
			return bee.architect_mode == mode_key
		Roles.MINER:
			return bee.automine       # the miner's only mode is a toggle
	return false

## Orders: the "click this, then click a spot" actions. Grouped together
## because they all behave the same way and all need the hive or meadow
## view, which is worth learning once rather than per button.
func _build_orders_row(common_role: int, first) -> void:
	if common_role != Bee.Role.FORAGER and common_role != Bee.Role.BUILDER and common_role != Bee.Role.MINER:
		return
	var row := _labelled_row("Orders")

	match common_role:
		Bee.Role.FORAGER:
			var has_start: bool = first != null and first.has_forage_start_point()
			row.add_child(_action_button("Clear start" if has_start else "Start here",
				func(): forage_start_point_requested.emit(),
				"Click this, then click a spot in the meadow. The selected foragers head there first on every trip out, so you can split them across different parts of the meadow instead of them all drifting to whichever flower is nearest the entrance."))
			if GameConfig.floral_constancy_on:
				var pref: String = first.preferred_species if first != null else ""
				row.add_child(_action_button(("Flower: %s" % pref) if pref != "" else "Pick a flower",
					func(): floral_preference_requested.emit(),
					"Click this, then click a flower. The selected foragers will only ever visit that species from then on, even walking past a nearer flower of something else -- real bees do this too."))
		Bee.Role.BUILDER:
			row.add_child(_action_button("Build here",
				func(): build_cell_requested.emit(),
				"Click this, then click any open tile -- including ground that has been mined out. Hold Ctrl and keep clicking to queue up several: they are built in the order you click them, and a faint line shows that order while this bee is selected."))
			row.add_child(_action_button("Keep clear",
				func(): keep_clear_requested.emit(),
				"Click this, then click a tile to reserve it as open floor. No comb worker will ever build there, so you can keep a corridor through the comb or a landing area by the entrance. Clicking a reserved tile again releases it. This applies to every comb worker, not just this one, and the reserved tiles show whenever any comb worker is selected."))
			row.add_child(_action_button("Work from here",
				func(): home_cell_requested.emit(),
				"Click this, then click a tile. That tile becomes the selected comb worker's centre of operations: left to itself it fills the space around it outwards in a spiral, rather than always adding to the middle. Applies to this one bee only, even if you have several selected -- use \"Set for all comb workers\" below to change every comb worker at once."))
			row.add_child(_action_button("Set for all comb workers",
				func(): home_cell_all_requested.emit(),
				"Click this, then click a tile. Every comb worker in the colony -- not just the selected ones -- gets that tile as its centre of operations. Use this to redirect the whole team at once; use \"Work from here\" above to give one bee its own spot."))

			# Restocking needs three things chosen, so it gets its own row
			# rather than crowding the general orders.
			if first != null and first.architect_mode == "restock":
				_build_restock_row(first)
		Bee.Role.MINER:
			row.add_child(_action_button("Mine",
				func(): mine_target_requested.emit(),
				"Click this, then click a soil block for the selected miners to dig. Hold Ctrl and keep clicking to queue several: they are dug in the order you click them, and a faint line shows that order while the miner is selected."))
			row.add_child(_action_button("Work from here",
				func(): mine_home_requested.emit(),
				"Click this, then click a tile. The selected miners will always dig whichever soil is nearest that tile, rather than whichever is nearest wherever they finished the last block. Keeps a team working through one face."))

## The restock sub-mode's own row: which cells to keep full, of what, and
## where the contents may come from.
##
## All three act on the current comb selection, which is why there is no
## "click a spot" mode here -- you select cells the ordinary way first,
## then press the button that says what they are for.
func _build_restock_row(first) -> void:
	var row := _labelled_row("Keep full")

	for resource in ["nectar", "pollen", "honey", "jelly"]:
		var value: String = resource
		var current: bool = first != null and first.restock_resource == value
		row.add_child(_toggle_button(
			resource.capitalize(), current,
			func(): restock_targets_requested.emit(value),
			"Select comb first, then press this. Those cells become the ones this comb worker keeps full of %s, fetching it from elsewhere in the hive whenever they run down. This is how you get a resource to sit *somewhere* -- honey beside the brood before winter, pollen within reach of the nursery -- rather than wherever the foragers happened to drop it." % resource
		))

	var source_row := _labelled_row("Take from")
	source_row.add_child(_action_button("Only these",
		func(): restock_sources_requested.emit(true),
		"Select comb first, then press this. The comb worker will draw only on those cells when refilling. Use it to point restocking at the outer comb and leave the rest alone."))
	source_row.add_child(_action_button("Never these",
		func(): restock_sources_requested.emit(false),
		"Select comb first, then press this. The comb worker will never take from those cells. This is what protects a winter store from being redistributed by your own bee."))
	source_row.add_child(_action_button("Clear orders",
		func(): restock_clear_requested.emit(),
		"Forget this comb worker's restocking orders entirely -- the cells it keeps full, and the sources it may use."))

	if first != null and first.has_restock_orders():
		var summary := Label.new()
		summary.text = "%d cells of %s" % [first.restock_targets.size(), first.restock_resource]
		summary.add_theme_font_size_override("font_size", 11)
		summary.add_theme_color_override("font_color", Color(0.6, 0.9, 0.7))
		source_row.add_child(summary)

## The backup role and whether a reassignment waits for the current job.
func _build_fallback_row(common_role: int, first) -> void:
	var row := _labelled_row("If idle")
	if common_role != -1:
		var current: int = first.secondary_role if first != null else -1
		row.add_child(_make_role_menu(
			"When idle: %s" % (Roles.label_for(current) if current != -1 else "nothing"),
			"What this bee does instead of standing around whenever it genuinely has no work of its own -- a non-automine miner with no block marked, say, or a nurse with no brood to tend. It drops the backup role and returns to its own the instant real work turns up.",
			_secondary_items()
		))

	var finish_box := CheckBox.new()
	finish_box.text = "Finish the job first"
	finish_box.add_theme_font_size_override("font_size", 11)
	finish_box.button_pressed = first.finish_task_first if first != null else false
	finish_box.toggled.connect(func(pressed: bool): finish_first_requested.emit(pressed))
	row.add_child(_with_info(finish_box, "On: reassigning this bee waits until it has finished what it is doing -- a forager delivers the load it is carrying, a comb worker finishes the cell it is on -- and the new role takes effect the moment it is free. Off: it drops everything and starts immediately."))

	# The queen's own laying rule sits here rather than in its own row --
	# it is a "what does she do when she can't lay" question, which is
	# the same question this row is about.
	if first != null and first.is_queen and common_role == Bee.Role.EGG_LAYER:
		var any_cell_box := CheckBox.new()
		any_cell_box.text = "Lay in plain comb too"
		any_cell_box.add_theme_font_size_override("font_size", 11)
		any_cell_box.button_pressed = GameConfig.queen_lays_in_any_cell
		any_cell_box.toggled.connect(func(pressed: bool): GameConfig.queen_lays_in_any_cell = pressed)
		row.add_child(_with_info(any_cell_box, "On (the default): once every nursery cell is occupied she lays into any spare undesignated cell, so laying never stalls for want of somewhere to put an egg. Off: she lays only in nursery zone cells and waits when they are full. Turn it off for exact control, and be ready to add zone cells or she stops laying."))

## The "when idle" menu, built from the role table so a new role turns
## up here without anyone remembering to add it.
func _secondary_items() -> Array:
	var items: Array = [{"text": "Nothing", "action": func(): secondary_role_requested.emit("none")}]
	for role in Roles.ROLES:
		if role.id == Roles.QUEEN or role.id == Roles.IDLE:
			continue   # neither is a sensible thing to fall back to
		var key: String = role.key
		items.append({"text": role.label, "action": func(): secondary_role_requested.emit(key)})
	return items

## One row of the panel, with its heading. Returns the box the controls
## go into.
func _labelled_row(title: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	role_row.add_child(row)

	var label := Label.new()
	label.text = "%s:" % title
	label.add_theme_font_size_override("font_size", 11)
	label.add_theme_color_override("font_color", Color(0.68, 0.74, 0.8))
	label.custom_minimum_size = Vector2(48, 0)
	row.add_child(label)
	return row

## A button that shows whether its option is the one currently in force.
## Sub-modes used to be buried in a "Doing: x" dropdown, so the only way
## to see which mode a bee was on was to read the button's own label --
## and the only way to see the alternatives was to open it.
func _toggle_button(label: String, is_current: bool, action: Callable, tip: String) -> Control:
	var button := Button.new()
	button.text = label
	button.add_theme_font_size_override("font_size", 11)
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(action)
	if is_current:
		UI.mark_as_current(button)
	return _with_info(button, tip)

func _action_button(label: String, action: Callable, tip: String) -> Control:
	var button := Button.new()
	button.text = label
	button.add_theme_font_size_override("font_size", 11)
	button.pressed.connect(action)
	return _with_info(button, tip)

func _current_role_marker(label: String) -> Control:
	var button := Button.new()
	button.text = "● %s" % label
	button.focus_mode = Control.FOCUS_NONE
	button.tooltip_text = "This is what the selected bees are doing now."
	return UI.mark_as_current(button)

## -1 means the selection is mixed -- no role is marked as current in
## that case, since there's no single answer to what they're all doing.
func _common_role(bees: Array) -> int:
	var found := false
	var role_value := -1
	for b in bees:
		if not is_instance_valid(b):
			continue
		if not found:
			role_value = b.role
			found = true
		elif b.role != role_value:
			return -1
	return role_value if found else -1

func _make_role_menu(label: String, tip: String, items: Array) -> Control:
	var menu := MenuButton.new()
	menu.text = label
	menu.tooltip_text = tip
	var popup := menu.get_popup()
	for i in range(items.size()):
		popup.add_item(items[i].text, i)
	popup.id_pressed.connect(func(id: int): items[id].action.call())
	return menu

## Re-read every frame so the task line tracks what the bee is doing.
func _refresh_selection_text() -> void:
	shown_bees = shown_bees.filter(func(b): return is_instance_valid(b))
	if shown_bees.is_empty():
		selection_panel.visible = false
		return
	if shown_bees.size() == 1:
		var b = shown_bees[0]
		var line := "%s%s — %s — energy %d%%" % [
			"Queen " if b.is_queen else "Bee ",
			"" if b.is_queen else str(b.bee_id),
			b.role_name_text(),
			int(100.0 * b.energy / max(0.001, GameConfig.energy_capacity)),
		]
		# Name and rolled trait first -- this is what turns "Bee 214" into
		# someone the player can recognise. See BEE_INDIVIDUALITY_PLAN.md.
		if b.bee_name != "":
			line = "%s%s\n%s" % ["★ " if b.is_favourite else "", b.bee_name, line]
		if b.trait_text() != "":
			line += "\n%s" % b.trait_text()
		if b.is_queen:
			line += "\nAge: %.1f days   (does not die of old age)" % b.age_days()
		else:
			line += "\nAge: %.1f days   Left: %.1f days" % [b.age_days(), b.days_remaining()]
		line += "\n%s" % b.carrying_text()
		if GameConfig.floral_constancy_on and b.role == Bee.Role.FORAGER and b.preferred_species != "":
			line += "\nPreferred flower: %s" % b.preferred_species
		if b.bee_fact != "":
			line += "\n\"%s\"" % b.bee_fact
		# the queen's pollen store is the thing that gates egg-laying,
		# so it's worth showing as a running total
		if b.is_queen:
			line += "\nPollen eaten: %d / %d needed for an egg" % [
				int(b.pollen_eaten), int(GameConfig.egg_pollen_cost),
			]
		selection_label.text = line
		task_label.text = "Now: %s" % b.task_description()

		# If it isn't doing anything, say why. A bee standing still looks
		# identical whatever the reason, and "nothing is happening and I
		# can't tell why" is the worst state to leave a player in.
		var stuck: String = b.idle_reason()
		if stuck != "":
			task_label.text += "\n%s" % stuck
			task_label.add_theme_color_override("font_color", Color(1.0, 0.82, 0.45))
		else:
			task_label.add_theme_color_override("font_color", Color(0.75, 0.9, 1.0))
	else:
		selection_label.text = "%d bees selected" % shown_bees.size()
		task_label.text = ""

func set_winter_button_visible(value: bool) -> void:
	if winter_button != null:
		winter_button.visible = value

func set_view_label(in_hive: bool) -> void:
	view_button.text = "Meadow" if in_hive else "Hive"

func set_colony_button_visible(value: bool) -> void:
	if colony_button != null:
		colony_button.visible = value
	if colony_info != null:
		colony_info.visible = value

func set_nursery_button_visible(value: bool) -> void:
	if nursery_button != null:
		nursery_button.visible = value
	if nursery_info != null:
		nursery_info.visible = value

func set_view_button_visible(value: bool) -> void:
	if view_button != null:
		view_button.visible = value
	if view_info != null:
		view_info.visible = value

## See the `allowed_role_keys` field comment. Rebuilds the selection
## panel immediately so a stage unlocking a new role shows it without
## waiting for the next unrelated selection change.
func set_allowed_role_keys(keys: Array) -> void:
	allowed_role_keys = keys
	if not shown_bees.is_empty():
		_rebuild_role_controls(shown_bees)

func set_allowed_mode_keys(keys: Array) -> void:
	allowed_mode_keys = keys
	if not shown_bees.is_empty():
		_rebuild_role_controls(shown_bees)

## Challenge 1's 1.3 replaces the usual "assign Comb worker, then click a
## spot" flow with one direct button in the queen's own panel -- see
## TUTORIAL_PLAN.md. Only ever shown for the queen, one bee selected.
func set_queen_build_button_visible(value: bool) -> void:
	show_queen_build_button = value
	if not shown_bees.is_empty():
		_rebuild_role_controls(shown_bees)
