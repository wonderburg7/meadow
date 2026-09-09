extends CanvasLayer
## Top-left readouts (day, stores, bee count), the view switcher, the
## game-speed controls, the selection tray and its command tray that
## appear when bees are selected, and the popup for inspecting a single
## comb cell.
##
## Every control carries a small "i" badge whose tooltip explains what
## it does -- see `_info()`. Kept separate from main.gd so the
## simulation wiring stays readable.

const UI = preload("res://scripts/ui.gd")
const UiTheme = preload("res://scripts/ui_theme.gd")
const Bee = preload("res://scripts/bee.gd")
const Roles = preload("res://scripts/roles.gd")
const Availability = preload("res://scripts/availability.gd")
const PerfPlot = preload("res://scripts/perf_plot.gd")
const PerfBreakdown = preload("res://scripts/perf_breakdown.gd")
const UiIcon = preload("res://scripts/ui_icon.gd")
const UiLayout = preload("res://scripts/ui_layout.gd")
const UiPanelLayout = preload("res://scripts/ui_panel_layout.gd")

signal role_requested(role_name: String)
signal view_toggle_requested()
signal colony_panel_requested()
signal foraging_panel_requested()
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
## The colony's own selected bee carries the cell's contents out herself,
## rather than waiting for a comb worker to notice -- Slice 18, for
## Challenge 1's queen, who can never take Role.BUILDER. General-purpose:
## works for any selected bee, not just Challenge 1's queen.
signal cell_empty_by_bee_requested(cell: Node2D)
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
## Sets the priority tier on the selected nursery cells: 0 low, 1 medium,
## 2 high.
signal cell_priority_requested(cell: Node2D, tier: int)
## Seals the selected cells, or opens them back up.
signal cell_close_requested(cell: Node2D, closed: bool)
## Fill the cell to the top and then seal it, refusing withdrawals in the
## meantime so it can actually get there.
signal cell_fill_close_requested(cell: Node2D)
## Opens the nursery window.
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
## The command tray's "Follow bee" toggle -- only offered for a single
## selected bee. `following` true starts continuous camera tracking;
## false stops it. Also emitted with `bee` null and `following` false
## on every selection change, so camera_view.gd never keeps tracking a
## bee the player has since deselected.
signal follow_bee_toggled(bee: Node2D, following: bool)
## The queen panel's "Lay in plain comb too" checkbox -- a second place to
## flip the same GameConfig.queen_lays_in_any_cell the settings window
## offers. hud.gd doesn't write GameConfig directly (see CLAUDE.md rule 2);
## main.gd routes this to debug_panel.gd, which does.
signal queen_lay_any_cell_toggled(value: bool)

## The bottom row's occupied height changed (selection_panel_top()).
## Colony, Foraging and Nursery listen so an already-open window reflows
## instead of only sizing itself once in open() (UI-T-2, Dave 8 Sep 2026).
signal bottom_row_changed()

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

## Play and two levels of fast forward, using numbers rather than
## stacked arrows: "▶▶▶" and "▶▶▶▶" are hard to tell apart at a glance
## and each one is wider than the last, which is what was eating the top
## bar. A number is one character at any speed. Pause is its own
## explicit button (see _build_top_right_bar), not an entry here.
## 8x is dev-only (UI_PLAN.md section 2's "(8x)") -- see Session.show_speed_8x.
const SPEEDS := [
	{"label": "1", "scale": 1.0, "tip": "Normal speed."},
	{"label": "2", "scale": 2.0, "tip": "Double speed. Good for waiting out brood development or comb building."},
	{"label": "4", "scale": 4.0, "tip": "Quadruple speed. The quickest way to reach the next day."},
	{"label": "8", "scale": 8.0, "dev_only": true, "tip": "Eight times speed. For skipping a stretch you have already seen -- a winter run-up, or waiting on a big dig. Watch the energy readout rather than the bees at this speed; there is more happening per second than you can follow."},
]

## Kept apart from the speed multipliers themselves so the pause button
## (which stops the sim rather than scaling it) reads as its own control
## -- see UI_PLAN.md section 2's "pause, 1x/2x/4x/(8x)".
const PAUSE_TIP := "Pause. The whole colony freezes; you can still look around and give orders."

## The role a bee can be switched to, and the sub-modes of each, both
## come from Roles now. The keys main.gd matches on are built from the
## role key and the mode key -- "comb_worker_build", "nurse_jelly" --
## so adding a mode to the table is all it takes.
static func mode_command(role_id: int, mode_key: String) -> String:
	return "%s_%s" % [Roles.key_for(role_id), mode_key]

## Shared horizontal gap for every join in the top-right bar's row1/row2/
## settings-cog group: row separation, and the gap before the settings
## cog. One constant so nothing in the group can drift out of sync --
## also used as the gap left between the bar and the settings cog that
## debug_panel.gd owns, on top of however wide the cog button actually is
## right now.
## Int-typed (not float, unlike most sizing constants here) because
## add_theme_constant_override's "separation" wants an int -- a float
## constant there produces a narrowing-conversion warning on every use.
const TOP_BAR_BUTTON_GAP := 8
## The 1x/2x/4x/(8x) speed-button trio's own tighter inner separation --
## a deliberate visual exception to TOP_BAR_BUTTON_GAP (confirmed with
## Dave): the trio reads as one control, not several. Int-typed for the
## same reason as TOP_BAR_BUTTON_GAP above.
const SPEED_GROUP_GAP := 2
## Used only until debug_panel.gd reports the cog's real width (see
## set_settings_button_width) -- close to the cog's own custom_minimum_size
## so there's no visible jump on the first frame.
const SETTINGS_BUTTON_DEFAULT_WIDTH := 72.0
## All primary controls in the top-right bar use this measured height.
## Keeping it in one place prevents a new text or icon button from making a
## row visibly uneven at a different UI scale.
const TOP_BAR_CONTROL_HEIGHT := 56.0
## Every row-2 window/view button (colony/nursery/foraging/winter/view)
## and the settings cog share this width, matching TOP_BAR_CONTROL_HEIGHT
## for height -- see _icon_button.
const TOP_BAR_BUTTON_WIDTH := 72.0
## Vertical separation between the top-right bar's two rows -- a distinct
## constant from TOP_BAR_BUTTON_GAP (which is horizontal), shared with the
## goal shelf's offset_top calculation so the two can never disagree.
const TOP_BAR_ROW_SEPARATION := 4.0
## Fixed gap between the top-right bar's second row and the goal shelf
## below it, once the shelf's offset is derived rather than hardcoded.
const GOAL_SHELF_GAP := 12.0

## Set by main.gd right after construction, matching the other systems'
## back-reference -- only used to read main.challenge_runner's state for
## the selected-bee activity line.
var main: Node2D

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
	"recruit_gap": "",
}
## Order the starred readouts appear in. Covers both the colony window's
## STAT_ROWS and the nursery window's, since both pin into the same
## corner and the order they appear in shouldn't depend on which window
## the player happened to star them from.
const CORNER_ORDER := [
	"fps",
	"day", "winter", "stores", "population", "comb", "energy", "rates",
	"recruit_gap",
	"nursery_zone", "nursery_mix", "nursery_output",
]
## Font size per readout -- the day is the headline, the rest is detail.
const CORNER_SIZES := {
	"fps": 12,
	"day": 22, "winter": 15, "stores": 16, "population": 13, "comb": 12,
	"energy": 13, "rates": 12, "recruit_gap": 12,
	"nursery_zone": 12, "nursery_mix": 12, "nursery_output": 12,
}
## What is currently drawn, so the column is only rebuilt when it would
## actually look different rather than every frame.
var corner_signature: String = ""

var pause_label: Label
## Explicit pause control in the top-right bar's first row, separate
## from the speed multiplier buttons -- see UI_PLAN.md section 2.
var pause_button: Button
var view_button: Button
## The icon inside view_button, and its text label -- both swap between
## the meadow and hive shape/word in set_view_label, since the button
## always shows the *other* view (never both), per section 2.
var view_icon: UiIcon
var view_button_label: Label
var winter_button: Button
var colony_button: Button
var nursery_button: Button
var foraging_button: Button
## Every button built by _icon_button, so _apply_interface_label_visibility
## can show/hide each one's text label together and restore its full
## width -- winter_button is deliberately absent, it has no icon yet.
var _labeled_buttons: Array = []
## The "i" badges next to colony_button/nursery_button/view_button --
## kept so the visibility setters below can hide the explanation
## alongside the control it explains, rather than leaving an orphaned
## info badge for a button that isn't there.
var colony_info: Button
var nursery_info: Button
var view_info: Button
## The Challenge goal shelf (UI_PLAN.md section 5): current goal leads,
## the goal just completed is shown struck through underneath it, and a
## compact progress bar appears only for a goal with a countable target.
## See set_challenge_goal.
var goal_shelf: VBoxContainer
var completed_goal_label: RichTextLabel
var current_goal_label: Label
var goal_progress_row: HBoxContainer
var goal_progress_bar: ProgressBar
var goal_progress_label: Label
## Restricts the Job row's "Change to..." dropdown / the Doing row's
## sub-modes to just these keys. Empty means no restriction -- only a
## Challenge (see challenge_runner.gd) ever sets these to something
## non-empty. See set_allowed_role_keys/set_allowed_mode_keys.
##
## allowed_mode_keys holds Forager's mode keys bare ("nectar", "pollen")
## but every other role's modes namespaced as "<role_key>_<mode_key>"
## ("nurse_feed", "comb_worker_both", ...) -- Nurse and Comb worker both
## have a mode keyed "both" (see roles.gd), so a bare key would let one
## role's unlock leak into the other's. See _build_doing_row.
var allowed_role_keys: Array = []
var allowed_mode_keys: Array = []
## Restricts the cell popup's "Reserve for" row to just these designation
## keys ("nectar", "pollen", "honey", "jelly", "brood", "any" for
## Unreserve). Empty means no restriction. See set_allowed_designation_keys.
var allowed_designation_keys: Array = []
## Challenge 1 only -- see set_queen_build_button_visible.
var show_queen_build_button: bool = false
## Hides the cell popup's "Keep for every bee" row / the soil popup's
## mark/clear buttons until a Challenge has taught them. Both default to
## visible so starter modes/open world/Challenge 1 are unaffected.
var hatch_lock_visible: bool = true
var soil_marking_visible: bool = true
## The top-right corner: two rows (pause/speed controls, then
## colony/nursery/winter/view icons -- UI_PLAN.md section 2), kept
## anchored clear of whatever debug_panel.gd's settings cog currently
## measures -- see set_settings_button_width.
var top_right_bar: VBoxContainer
## The bottom-left selection tray (UI_PLAN.md section 5): four ranked
## fields -- identity/job, energy/load, activity, trait/quote -- each
## independently hideable via the tray's own cog. See
## _apply_selection_field_visibility.
var selection_panel: PanelContainer
var identity_label: Label
var energy_label: Label
var activity_label: Label
var trait_label: Label
## Which kind of "not a bee" thing the panel is showing, if any --
## "flower"/"obstacle"/"death"/"soil", or "" for the ordinary bee/multi-
## bee fields. Folded in from four separate mouse-anchored popups
## (UI_BUGFIX_PLAN.md Slice 5, Dave's 22 Aug call): a content swap, not
## a second region, so whichever of a bee selection or an object summary
## happened most recently is what shows. See show_object_summary.
var active_summary_kind: String = ""
## The flower currently summarised, if active_summary_kind == "flower"
## -- kept live (unlike the other three kinds) because its nectar/pollen
## amounts tick up while the panel is open; see _refresh_flower_summary.
var active_flower: Node2D = null
## Only shown for a soil summary -- see show_object_summary and
## set_soil_marking_visible.
## The selection panel's own content column -- kept as a member so
## _apply_selection_tray_width can re-cap its width without a fresh build.
var selection_column: VBoxContainer
var soil_summary_row: BoxContainer
var soil_mark_btn: Button
var soil_clear_btn: Button
var speed_buttons: Array = []
var shown_bees: Array = []
## Challenge-owned command restrictions are passed in as bee references.
## Their summary remains useful, but the command tray is suppressed whenever
## a locked bee is in the selection. Empty outside the locked tutorial beat.
var command_locked_bees: Array = []

## The bottom-centre command tray (UI_PLAN.md section 5): three ranked
## columns -- Job (change role), Focus (the current sub-mode) and Orders
## (click-a-spot actions/restocking) -- wrapping in height rather than
## overflowing width (see _update_command_tray_width); "More…" reveals
## the rest (queen's Build-cell, Follow bee, backup role, finish-first,
## favourite) underneath. Each column hides itself when it has nothing
## to show for the current selection (see _rebuild_role_controls).
var command_tray: PanelContainer
## Holds the tray's content column and caps it to command_tray_max_height
## without shrinking the PanelContainer below its content (which
## Control.set_size cannot do -- see _resize_command_tray).
var command_scroll: ScrollContainer
## command_scroll's one child. A ScrollContainer reports ~0 for
## get_combined_minimum_size() on the axis it scrolls, so
## _resize_command_tray measures this instead -- see _build_command_tray.
var command_content: VBoxContainer
var command_columns: Container
var job_column_wrapper: VBoxContainer
var job_column: VBoxContainer
var focus_column_wrapper: VBoxContainer
var focus_column: VBoxContainer
var orders_column_wrapper: VBoxContainer
var orders_column: VBoxContainer
var more_button: Button
var more_panel: VBoxContainer
## Remembered for this session only, same spirit as colony_panel.gd's
## section_open (UI_PLAN.md section 11) -- not persisted.
var more_panel_open: bool = false

## The command tray's cell content -- shares the tray with the Job/Focus/
## Orders columns, mutually exclusive with them. Cell actions belong here;
## the state those actions apply to is summarised in the bottom-left panel.
## See show_cell_popup/update_selection and UI_BUGFIX_PLAN.md Slice 9.
var cell_group: VBoxContainer
var cell_primary_columns: Container
var cell_more_button: Button
var cell_more_panel: Container
var cell_more_open: bool = false
## The wrapped "Raises:" controls are built while their cell group is hidden.
## Keep this reference so showing the group can run its first visible layout.
var hatch_row: HFlowContainer
var active_cell: Node2D = null
var keep_empty_box: CheckBox
## Visible only while active_cell holds something to carry -- see
## _refresh_cell_popup. Slice 18.
var empty_by_bee_btn: Button
var hatch_lock_box: CheckBox
var gyne_box: CheckBox
var gyne_row: HBoxContainer
## The "Keep for every bee" row, so set_hatch_lock_visible can hide it as
## a whole rather than reaching into its children.
var lock_row: HBoxContainer
## One entry per hatch_options() choice, so _refresh_cell_popup can hide
## the ones for a role the current Challenge hasn't unlocked yet.
var hatch_option_controls: Array = []
## How many cells the popup's buttons will act on. 1 unless the player
## has a multi-cell selection.
var selected_cell_count: int = 1

## Slice 2 of CHATGPT_EFFICIENCY_IMPLEMENTATION_PLAN.md: the popups below
## used to rebuild every render frame regardless of whether anything
## shown had changed. Every player-triggered edit already calls its
## _refresh_*() directly (request handlers, show_cell_popup,
## update_selection), so `_process` below only needs to catch changes
## that happen without going through hud.gd -- a bulk nursery-panel edit,
## a forager filling the open cell, a bee's ticking age/energy/task text.
## The cell popup refreshes the moment its cell's display_epoch or
## identity changes; everything (including the ticking numeric fields
## all three popups show) is also caught on POPUP_REFRESH_CADENCE, well
## under a human's ~100ms change-blindness threshold.
const POPUP_REFRESH_CADENCE := 0.1
var _popup_cadence_elapsed: float = 0.0
var _cell_popup_last_cell: Node2D = null
var _cell_popup_last_count: int = -1
var _cell_popup_last_epoch: int = -1

var warning_panel: PanelContainer
var warning_label: Label
var warning_timer: float = 0.0
## Set by challenge_runner.gd for the length of a Challenge -- see
## TUTORIAL_PLAN.md's "Don't include the warning messages" note. Every
## other caller of show_warning is unaffected outside a Challenge.
var warnings_muted: bool = false
## One throttle for every show_warning() producer, keyed by their `key`
## argument, so a correctly-throttled event can't wipe another one still
## on screen -- see UI-Q-1 in plans/now/ui.md. Empty/default key means no
## throttling, matching the untouched call sites (transactional copy the
## player asked for, not an ambient warning).
var _warning_last_shown: Dictionary = {}

## Guaranteed on-screen time for whichever message is showing, regardless
## of what arrives next -- see UI-Q-3 in plans/now/ui-bottom-row.md. A
## strictly higher-severity arrival still pre-empts immediately; anything
## else waits in _pending_warning until this window closes.
const MIN_DWELL_SECONDS := 6.0
var _warning_shown_at: float = -INF
var _warning_severity: int = -1
## The one message waiting behind the current one, or empty. A later
## arrival while something is already pending simply replaces it -- same
## last-call-wins rule show_warning always had, just deferred.
var _pending_warning: Dictionary = {}

## The at-a-glance problem strip, as [text, severity] pairs, kept so the
## corner can be rebuilt without main.gd having to resend it.
var shown_signals: Array = []

## Severity colours for the at-a-glance strip: 0 is background
## information, 1 is worth looking at, 2 is losing you something now.
## These resolve through UiTheme so Light and High Contrast do not inherit
## the bright-on-dark literals that the original HUD used.
func _signal_color(severity: int) -> Color:
	if severity <= 0:
		return UiTheme.color("text_secondary")
	if severity == 1:
		return UiTheme.color("warning")
	return UiTheme.color("danger")

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
	# CanvasLayer (self) isn't a Control, so nothing above this in the
	# tree carries a theme for it to inherit -- without this, the corner
	# readouts always draw in Godot's built-in default font regardless
	# of Session.ui_typeface. UiTheme.build_theme() returns the one
	# shared, live-mutated Theme resource, so this stays in sync with
	# every other panel's typeface/colour/scale without a refresh call.
	corner_column.theme = UiTheme.build_theme()
	add_child(corner_column)

	perf_plot = PerfPlot.new()
	perf_plot.custom_minimum_size = Vector2(140, 40)
	perf_plot.visible = false
	corner_column.add_child(perf_plot)
	perf_breakdown = PerfBreakdown.new()
	perf_breakdown.visible = false
	corner_column.add_child(perf_breakdown)

	pause_label = _make_label(Vector2(16, 300), "Heading")
	pause_label.text = "PAUSED"
	pause_label.visible = false

	_build_top_right_bar()
	_apply_interface_label_visibility()
	_build_goal_shelf()
	_build_selection_panel()
	_build_command_tray()
	_build_warning_banner()
	_build_discard_dialog()
	get_viewport().size_changed.connect(_on_viewport_size_changed)

## Re-caps the selection and command trays to the new viewport width
## (UI_PLAN.md UI-B) -- a window resize is the only thing allowed to change
## either tray's width; bee/cell/flower content must not.
func _on_viewport_size_changed() -> void:
	_apply_selection_tray_width()
	call_deferred("_resize_command_tray")

func _make_label(pos: Vector2, variation: String = "Body") -> Label:
	var l := Label.new()
	l.position = pos
	l.theme = UiTheme.build_theme()
	l.theme_type_variation = variation
	add_child(l)
	return l

func _info(text: String) -> Button:
	return UI.info_badge(text)

func _with_info(control: Control, tip: String) -> HBoxContainer:
	return UI.with_info(control, tip)

## The five states a plain Godot Button actually looks up -- see
## colony_panel.gd's identical helper.
func _style_button(button: BaseButton) -> BaseButton:
	for state in ["normal", "hover", "pressed", "focus", "disabled"]:
		button.add_theme_stylebox_override(state, UiTheme.button_stylebox(state))
	return button

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
##
## TOP_BAR_BUTTON_GAP is added twice: the cog itself (debug_panel.gd)
## already sits TOP_BAR_BUTTON_GAP in from the viewport's own right edge,
## so reserving only `width + GAP` here lands this bar's edge exactly on
## the cog's left edge -- zero visible gap between them (Dave's 29 Aug
## report: the row of speed buttons touching the cog). The second GAP is
## the actual visible air between the bar's content and the cog.
##
## Two rows (UI_PLAN.md section 2): the transport row (pause, speed
## multipliers) first, then the window/view icon row (colony, nursery,
## winter, meadow/hive switch) underneath -- each row is its own tight
## HBoxContainer inside a VBoxContainer, rather than one long row, so
## neither has to fit more controls across than it comfortably can.
func _build_top_right_bar() -> void:
	var bar := VBoxContainer.new()
	top_right_bar = bar
	bar.theme = UiTheme.build_theme()
	bar.add_theme_constant_override("separation", int(TOP_BAR_ROW_SEPARATION))
	bar.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	bar.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	bar.offset_right = -(SETTINGS_BUTTON_DEFAULT_WIDTH + TOP_BAR_BUTTON_GAP * 2.0)
	bar.offset_top = 8  # fixed-inset
	add_child(bar)

	var row1 := HBoxContainer.new()
	row1.alignment = BoxContainer.ALIGNMENT_END
	row1.add_theme_constant_override("separation", TOP_BAR_BUTTON_GAP)
	bar.add_child(row1)

	pause_button = Button.new()
	_style_button(pause_button)
	pause_button.text = "❚❚"
	pause_button.tooltip_text = PAUSE_TIP
	pause_button.custom_minimum_size = Vector2(56, TOP_BAR_CONTROL_HEIGHT)
	pause_button.theme_type_variation = "Small"
	pause_button.focus_mode = Control.FOCUS_NONE
	pause_button.toggle_mode = true
	pause_button.pressed.connect(func(): speed_requested.emit(0.0))
	row1.add_child(pause_button)

	# The speed buttons sit in their own tight group with no gaps, which
	# reads as one control rather than several and gives 8x somewhere to
	# go without pushing everything else off the row when it's enabled.
	var speed_group := HBoxContainer.new()
	speed_group.add_theme_constant_override("separation", SPEED_GROUP_GAP)
	row1.add_child(speed_group)

	for entry in SPEEDS:
		var dev_only: bool = entry.get("dev_only", false)
		var btn := Button.new()
		_style_button(btn)
		btn.text = entry.label
		btn.tooltip_text = entry.tip
		btn.custom_minimum_size = Vector2(48, TOP_BAR_CONTROL_HEIGHT)
		btn.theme_type_variation = "Small"
		btn.focus_mode = Control.FOCUS_NONE
		btn.toggle_mode = true
		# Built either way rather than skipped, so the settings window's
		# "Show 8x speed button" toggle can show/hide it live (see
		# refresh_speed_visibility) instead of only taking effect on the
		# next scene reload.
		btn.visible = not dev_only or Session.show_speed_8x
		var scale_value: float = entry.scale
		btn.pressed.connect(func(): speed_requested.emit(scale_value))
		speed_group.add_child(btn)
		speed_buttons.append({"button": btn, "scale": scale_value, "dev_only": dev_only})

	row1.add_child(_info("Game speed, as a multiple of normal. These change how fast the simulation runs; they do not change how much a bee gathers per in-game second."))

	var row2 := HBoxContainer.new()
	row2.alignment = BoxContainer.ALIGNMENT_END
	row2.add_theme_constant_override("separation", TOP_BAR_BUTTON_GAP)
	bar.add_child(row2)

	# Row-2 buttons carry a short on-hover tooltip on the button itself now
	# (Dave's 29 Aug ask -- "Opens Nursery Panel", not a paragraph); the
	# full explanation stays on each button's own "i" info badge, unchanged.
	colony_button = _icon_button("bee", "Colony", TOP_BAR_BUTTON_WIDTH, "Opens the Colony window.")
	colony_button.pressed.connect(func(): colony_panel_requested.emit())
	row2.add_child(colony_button)
	colony_info = _info("Open the colony overview: how many bees are on each job, what is in the comb, how the brood is doing, and how any of that has changed over time. Click a role in it to select every bee doing that job at once.")
	row2.add_child(colony_info)

	nursery_button = _icon_button("hex", "Nursery", TOP_BAR_BUTTON_WIDTH, "Opens the Nursery window.")
	nursery_button.pressed.connect(func(): nursery_window_requested.emit())
	row2.add_child(nursery_button)
	nursery_info = _info("Open the nursery window: which cells are set to raise which role, what the colony is made of now, and how many of each kind have emerged recently. While it is open the reserved cells glow on the comb.")
	row2.add_child(nursery_info)

	# Icon-plus-label, same shape as colony/nursery/view now (UI-N) -- at
	# TOP_BAR_BUTTON_WIDTH there isn't room for "Foraging" as full text, so
	# it gets the icon+tooltip treatment instead of truncating ad hoc.
	foraging_button = _icon_button("flower", "Foraging", TOP_BAR_BUTTON_WIDTH, "Opens the Foraging window.")
	foraging_button.pressed.connect(func(): foraging_panel_requested.emit())
	row2.add_child(foraging_button)
	row2.add_child(_info("Open the foraging window: trip timing (search+flight versus handling), flowers visited per trip, empty-return rate, and the same breakdown split by species, plus recruitment/scouting counts. Only fills in once Auto scouting or Auto-recruitment is on -- that is what scores a trip today."))

	# Only appears once a winter has been scheduled -- until then there is
	# nothing for it to say, and a permanently dead button is worse than
	# no button. Same icon+label treatment as the rest of the row (UI-N).
	winter_button = _icon_button("snow", "Winter", TOP_BAR_BUTTON_WIDTH, "Opens the Winter forecast.")
	winter_button.visible = Session.winter_coming
	winter_button.pressed.connect(func(): winter_window_requested.emit())
	row2.add_child(winter_button)

	# Only the *other* view's icon and word ever show (UI_PLAN.md section
	# 2's Meadow/Hive exclusivity rule) -- set_view_label swaps both.
	view_button = _icon_button("hive", "Hive", TOP_BAR_BUTTON_WIDTH, "Switch to the Hive view.")
	view_icon = view_button.get_child(0).get_child(0)
	view_button_label = view_button.get_child(0).get_child(1)
	view_button.pressed.connect(func(): view_toggle_requested.emit())
	row2.add_child(view_button)
	view_info = _info("Switch between the meadow (flowers and foragers) and the hive interior (comb, queen, brood) -- or press Tab. Both keep simulating whichever one you are looking at.")
	row2.add_child(view_info)

## A small icon-plus-label button for the top-right bar's window/view
## row. The icon is a procedural UiIcon (UI_PLAN.md section 8's
## placeholder-art rule) rather than a sprite; the label stays alongside
## it rather than replacing it outright, since a rough drawn shape isn't
## yet legible enough to stand alone. Both live inside the Button
## itself, with mouse_filter set to IGNORE, so the whole button area
## stays clickable rather than only the space around them.
func _icon_button(shape: String, label: String, min_width: float, tip: String) -> Button:
	var btn := Button.new()
	_style_button(btn)
	btn.custom_minimum_size = Vector2(min_width, TOP_BAR_CONTROL_HEIGHT)
	btn.tooltip_text = tip
	btn.focus_mode = Control.FOCUS_NONE

	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 4)
	row.set_anchors_preset(Control.PRESET_FULL_RECT)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn.add_child(row)

	var icon := UiIcon.new()
	icon.shape = shape
	icon.custom_minimum_size = Vector2(16, 16)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(icon)

	var text := Label.new()
	text.text = label
	text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text.theme_type_variation = "Body"
	row.add_child(text)

	# Icon-only width: button_stylebox's own content margins (8 left/right,
	# ui_theme.gd) plus the icon itself, no room reserved for the label.
	_labeled_buttons.append({"button": btn, "label": text, "full_width": min_width, "icon_width": 32.0})

	return btn

## Session.show_interface_labels (off by default -- Dave's 22 Aug icon-only
## call): shows/hides each top-bar button's text label together and shrinks
## the button to icon-only width when hidden. Called once after the row is
## built and again whenever the setting changes.
func _apply_interface_label_visibility() -> void:
	for entry in _labeled_buttons:
		entry.label.visible = Session.show_interface_labels
		var width: float = entry.full_width if Session.show_interface_labels else entry.icon_width
		entry.button.custom_minimum_size.x = width

## The goal shelf (UI_PLAN.md section 5): sits directly under the
## top-right button row, anchored and widened the same way -- see
## set_settings_button_width. Hidden outside a Challenge;
## challenge_runner.gd is the only caller of set_challenge_goal.
func _build_goal_shelf() -> void:
	goal_shelf = VBoxContainer.new()
	goal_shelf.theme = UiTheme.build_theme()
	goal_shelf.visible = false
	# The shelf overlaps the second top-bar row while a Challenge is active.
	# It is display-only, so every part must pass pointer input through to
	# the controls underneath instead of leaving only their exposed edge live.
	goal_shelf.mouse_filter = Control.MOUSE_FILTER_IGNORE
	goal_shelf.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	goal_shelf.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	goal_shelf.offset_right = -(SETTINGS_BUTTON_DEFAULT_WIDTH + TOP_BAR_BUTTON_GAP * 2.0)
	goal_shelf.offset_top = top_right_bar.offset_top + TOP_BAR_CONTROL_HEIGHT * 2.0 + TOP_BAR_ROW_SEPARATION + GOAL_SHELF_GAP
	goal_shelf.custom_minimum_size = Vector2(320, 0)
	goal_shelf.add_theme_constant_override("separation", 1)
	add_child(goal_shelf)

	# Secondary: the goal just completed, struck through and faded, per
	# section 5. A RichTextLabel rather than a Label since Label has no
	# strikethrough of its own -- BBCode's [s] tag is the plain way to get
	# one without hand-drawing a line.
	completed_goal_label = RichTextLabel.new()
	completed_goal_label.bbcode_enabled = true
	completed_goal_label.fit_content = true
	completed_goal_label.scroll_active = false
	completed_goal_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	completed_goal_label.custom_minimum_size = Vector2(320, 0)
	# RichTextLabel has no Label-based theme_type_variation to draw on, so
	# this scales directly rather than joining the Small/Body/Heading set.
	completed_goal_label.add_theme_font_size_override("normal_font_size", int(round(12 * Session.text_scale)))
	completed_goal_label.add_theme_color_override("default_color", Color(UiTheme.color("warning"), 0.55))
	completed_goal_label.visible = false
	goal_shelf.add_child(completed_goal_label)

	# Primary: the current goal.
	current_goal_label = Label.new()
	current_goal_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	current_goal_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	current_goal_label.custom_minimum_size = Vector2(320, 0)
	current_goal_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	current_goal_label.theme_type_variation = "Body"
	current_goal_label.add_theme_color_override("font_color", UiTheme.color("warning"))
	goal_shelf.add_child(current_goal_label)

	# Tertiary: numeric progress, only for a goal with a countable target.
	goal_progress_row = HBoxContainer.new()
	goal_progress_row.visible = false
	goal_progress_row.alignment = BoxContainer.ALIGNMENT_END
	goal_progress_row.add_theme_constant_override("separation", 6)
	goal_progress_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	goal_shelf.add_child(goal_progress_row)

	goal_progress_bar = ProgressBar.new()
	goal_progress_bar.custom_minimum_size = Vector2(160, 8)
	goal_progress_bar.show_percentage = false
	goal_progress_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	goal_progress_row.add_child(goal_progress_bar)

	goal_progress_label = Label.new()
	goal_progress_label.theme_type_variation = "Small"
	goal_progress_label.add_theme_color_override("font_color", UiTheme.color("text_secondary"))
	goal_progress_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	goal_progress_row.add_child(goal_progress_label)

## Called by debug_panel.gd whenever its settings cog's actual width
## changes (including the first layout pass), so this bar sits exactly
## as far from the corner as the cog needs and no further -- see the
## comment on _build_top_right_bar.
func set_settings_button_width(width: float) -> void:
	if top_right_bar == null:
		return
	top_right_bar.offset_right = -(width + TOP_BAR_BUTTON_GAP * 2.0)
	goal_shelf.offset_right = -(width + TOP_BAR_BUTTON_GAP * 2.0)

## Shown under the top-right button row for the length of a Challenge --
## see TUTORIAL_PLAN.md and UI_PLAN.md section 5. `text` is the current
## goal (empty hides the whole shelf). `completed_text`, when given,
## shows the goal just finished, struck through and faded, underneath
## it. `progress_current`/`progress_target` add a compact bar and count,
## shown only when `progress_target` is a real target -- both default to
## -1.0 ("no countable target") rather than 0.0, since 0 is itself a
## valid amount of progress.
func set_challenge_goal(text: String, completed_text: String = "", progress_current: float = -1.0, progress_target: float = -1.0) -> void:
	goal_shelf.visible = not text.is_empty()
	current_goal_label.text = text

	completed_goal_label.visible = not completed_text.is_empty()
	if not completed_text.is_empty():
		completed_goal_label.text = "[s]%s[/s]" % completed_text

	var has_progress: bool = progress_target > 0.0
	goal_progress_row.visible = has_progress
	if has_progress:
		goal_progress_bar.max_value = progress_target
		goal_progress_bar.value = clampf(progress_current, 0.0, progress_target)
		goal_progress_label.text = "%d / %d" % [int(round(progress_current)), int(round(progress_target))]

func set_speed_display(speed_scale: float) -> void:
	pause_button.button_pressed = is_equal_approx(speed_scale, 0.0)
	for entry in speed_buttons:
		entry.button.button_pressed = is_equal_approx(entry.scale, speed_scale)

## Four ranked labels (UI_PLAN.md section 5) rather than the old two --
## identity/job leads, energy/load and activity follow, trait/quote is
## last. The cog sits in its own row, apart from the ranked fields, so
## it never moves as fields are shown or hidden.
func _build_selection_panel() -> void:
	selection_panel = PanelContainer.new()
	selection_panel.theme = UiTheme.build_theme()
	selection_panel.add_theme_stylebox_override("panel", UiTheme.panel_stylebox())
	# anchored to the bottom-left so it stays put when the window resizes
	selection_panel.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	selection_panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	selection_panel.offset_left = UiLayout.SELECTION_TRAY_LEFT_MARGIN
	selection_panel.offset_bottom = -UiLayout.BOTTOM_ROW_MARGIN
	selection_panel.visible = false
	add_child(selection_panel)

	selection_column = VBoxContainer.new()
	selection_panel.add_child(selection_column)
	var column := selection_column
	_apply_selection_tray_width()

	# The cog sits on the same line as the identity label (Dave's 29 Aug
	# ask) rather than a row of its own above it -- that row used to be
	# empty air except for the cog, pushing every field down and making
	# the panel taller than it needed to be for no reason.
	var header := HBoxContainer.new()
	column.add_child(header)

	# Fixed, viewport-derived width (UiLayout.selection_tray_width) rather
	# than sizing from label text -- see _apply_selection_tray_width. Every
	# label below autowraps within it so a long line never stretches the
	# panel (UI_PLAN.md UI-B).
	identity_label = Label.new()
	identity_label.theme_type_variation = "Small"
	identity_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	identity_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(identity_label)
	header.add_child(_build_selection_cog())

	energy_label = Label.new()
	energy_label.theme_type_variation = "Small"
	energy_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	energy_label.add_theme_color_override("font_color", UiTheme.color("success"))
	column.add_child(energy_label)

	# what the bee is doing right this second
	activity_label = Label.new()
	activity_label.theme_type_variation = "Small"
	activity_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	activity_label.add_theme_color_override("font_color", UiTheme.readable_accent(UiTheme.color("accent_nectar")))
	column.add_child(activity_label)

	trait_label = Label.new()
	trait_label.theme_type_variation = "Small"
	trait_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	trait_label.add_theme_color_override("font_color", UiTheme.readable_accent(UiTheme.color("accent_wax")))
	column.add_child(trait_label)

	# Only shown for a soil summary -- see show_object_summary. Stacked
	# vertically (rather than side by side) so the two buttons can never
	# push the panel past its fixed width at a large text scale.
	soil_summary_row = VBoxContainer.new()
	soil_summary_row.visible = false
	column.add_child(soil_summary_row)

	soil_mark_btn = Button.new()
	_style_button(soil_mark_btn)
	soil_mark_btn.text = "Mark for digging"
	# Wrap and clip rather than raise the column's minimum width past the
	# space _apply_selection_tray_width has given it (Dave, 8 Sep 2026, C-18).
	soil_mark_btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	soil_mark_btn.clip_text = true
	soil_mark_btn.pressed.connect(func(): soil_mark_requested.emit(true))
	soil_summary_row.add_child(_with_info(soil_mark_btn, "Flag every selected block for miners to dig out. Blocks buried behind other soil can be marked too -- miners simply cannot reach them until the ones in front are gone, so a marked seam digs itself inward layer by layer."))

	soil_clear_btn = Button.new()
	_style_button(soil_clear_btn)
	soil_clear_btn.text = "Clear marks"
	soil_clear_btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	soil_clear_btn.clip_text = true
	soil_clear_btn.pressed.connect(func(): soil_mark_requested.emit(false))
	soil_summary_row.add_child(_with_info(soil_clear_btn, "Take the digging flag off the selected blocks. Any digging already done is kept, so you can put the mark back later without losing the work."))

	_apply_selection_field_visibility()

## The tray's own configuration cog (UI_PLAN.md section 5) -- a plain
## gear glyph, same placeholder-art approach as debug_panel.gd's
## settings cog. Its popup stays open across clicks
## (hide_on_checkable_item_selection = false) so several fields can be
## toggled in one go.
func _build_selection_cog() -> Control:
	var menu := MenuButton.new()
	_style_button(menu)
	menu.text = "⚙"
	menu.theme_type_variation = "Body"
	# Keep the cog aligned with the first identity line when that label wraps
	# to show role and age below it (UI-P-8).
	menu.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	# A fixed width so this single glyph cannot raise the selection column's
	# minimum width above the space _apply_selection_tray_width gives it at
	# a large text scale (Dave, 8 Sep 2026, C-18).
	menu.custom_minimum_size.x = 24.0
	menu.tooltip_text = "Choose which fields this panel shows for the selected bee."
	menu.focus_mode = Control.FOCUS_NONE
	var popup := menu.get_popup()
	popup.hide_on_checkable_item_selection = false
	popup.add_check_item("Identity & job", 0)
	popup.add_check_item("Energy & load", 1)
	popup.add_check_item("Activity", 2)
	popup.add_check_item("Trait & quote", 3)
	popup.set_item_checked(0, Session.show_selection_identity)
	popup.set_item_checked(1, Session.show_selection_energy)
	popup.set_item_checked(2, Session.show_selection_activity)
	popup.set_item_checked(3, Session.show_selection_trait)
	popup.id_pressed.connect(func(id: int): _on_selection_field_toggled(id, popup))
	return menu

func _on_selection_field_toggled(id: int, popup: PopupMenu) -> void:
	var checked: bool = not popup.is_item_checked(id)
	popup.set_item_checked(id, checked)
	match id:
		0: Session.show_selection_identity = checked
		1: Session.show_selection_energy = checked
		2: Session.show_selection_activity = checked
		3: Session.show_selection_trait = checked
	Session.save_preferences()
	_apply_selection_field_visibility()

func _apply_selection_field_visibility() -> void:
	identity_label.visible = Session.show_selection_identity
	energy_label.visible = Session.show_selection_energy
	activity_label.visible = Session.show_selection_activity
	trait_label.visible = Session.show_selection_trait

## The command tray (UI_PLAN.md section 5): a wrapping row of role-action
## buttons, ranked by how often they're used for the current selection
## rather than alphabetically or by internal role-mode order, with
## "More…" revealing the rest underneath. Its centred width and left edge
## come from ui_layout.gd, while the summary panel and Dr Gallerin fill the
## side bands. See _update_command_tray_width.
func _build_command_tray() -> void:
	command_tray = PanelContainer.new()
	command_tray.theme = UiTheme.build_theme()
	command_tray.add_theme_stylebox_override("panel", UiTheme.panel_stylebox())
	command_tray.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	# Grow rightwards from the centred left edge _update_command_tray_width
	# sets, so its own minimum size cannot drag it over the summary panel.
	command_tray.grow_horizontal = Control.GROW_DIRECTION_END
	command_tray.grow_vertical = Control.GROW_DIRECTION_BEGIN
	# Matches the summary panel's own bottom offset, which is why the two
	# sit level.
	command_tray.offset_bottom = -UiLayout.BOTTOM_ROW_MARGIN
	command_tray.visible = false
	add_child(command_tray)

	command_scroll = ScrollContainer.new()
	# The tray's width is owned by _update_command_tray_width; this must
	# never grow a horizontal bar of its own.
	command_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	command_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	command_tray.add_child(command_scroll)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 4)
	command_scroll.add_child(column)
	command_content = column

	# Three ranked columns rather than one flowing row, per Dave's 22 Aug
	# call -- each one wraps onto more rows internally rather than the
	# whole tray growing wider than its cap (see _update_command_tray_width),
	# which is still what lets the bottom row grow taller, not wider, at
	# high text scale (UI_PLAN.md section 2's bottom-row rule).
	# Let whole Job/Focus/Orders groups move onto another row when a narrow
	# viewport cannot accommodate all three.  A fixed HBox would preserve its
	# children's combined minimum width and spill into the summary panel.
	command_columns = HFlowContainer.new()
	command_columns.add_theme_constant_override("separation", 16)
	column.add_child(command_columns)

	var job_group := _build_tray_column("Job")
	job_column_wrapper = job_group[0]
	job_column = job_group[1]
	var focus_group := _build_tray_column("Focus")
	focus_column_wrapper = focus_group[0]
	focus_column = focus_group[1]
	var orders_group := _build_tray_column("Orders")
	orders_column_wrapper = orders_group[0]
	orders_column = orders_group[1]

	more_button = Button.new()
	_style_button(more_button)
	more_button.text = "More…"
	more_button.theme_type_variation = "Small"
	more_button.focus_mode = Control.FOCUS_NONE
	more_button.toggle_mode = true
	more_button.visible = false
	more_button.pressed.connect(func():
		more_panel_open = more_button.button_pressed
		more_panel.visible = more_panel_open
		call_deferred("_resize_command_tray")
	)
	column.add_child(more_button)

	# Holds the rest: job change, backup role, finish-first, favourite --
	# built the same way the tray's primary rows used to be, just into
	# this container instead. See _labelled_row.
	more_panel = VBoxContainer.new()
	more_panel.add_theme_constant_override("separation", 3)
	more_panel.visible = false
	column.add_child(more_panel)

	_build_cell_group(column)

## One of the command tray's three ranked columns: a small header label
## plus the content VBox rows get added to. Returns [wrapper, content] --
## the wrapper is what _rebuild_role_controls shows/hides depending on
## whether the column has anything to say for the current selection, so
## an empty column doesn't sit there as a blank gap.
func _build_tray_column(title: String) -> Array:
	var wrapper := VBoxContainer.new()
	wrapper.add_theme_constant_override("separation", 3)
	wrapper.custom_minimum_size = Vector2(100, 0)
	wrapper.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	command_columns.add_child(wrapper)

	var header := Label.new()
	header.text = title
	header.theme_type_variation = "Small"
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.add_theme_color_override("font_color", UiTheme.color("text_secondary"))
	wrapper.add_child(header)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 3)
	wrapper.add_child(content)

	return [wrapper, content]

# --- cell popup ---------------------------------------------------

## Popup buttons whose appearance tracks the state of the cell being
## shown, keyed by what they represent. Lit up in _refresh_cell_popup, so
## "which priority is this cell on" and "is this one sealed" are readable
## without hunting through the text above.
var live_buttons: Dictionary = {}

## Builds the tray's cell content into `parent` (command_tray's own
## column, alongside command_columns and more_panel) rather than a
## separate floating popup -- folded in per UI_BUGFIX_PLAN.md Slice 4/5,
## Dave's 22 Aug call. Built once, like command_columns' rows aren't --
## its four sections are refreshed in place by _refresh_cell_popup
## rather than torn down and rebuilt per cell selection, since a cell's
## controls (which designation, which sections are open) don't change
## shape the way a bee's role-dependent rows do.
func _build_cell_group(parent: VBoxContainer) -> void:
	cell_group = VBoxContainer.new()
	cell_group.add_theme_constant_override("separation", 2)
	cell_group.visible = false
	parent.add_child(cell_group)

	# The frequent actions form one low, wide row, mirroring the selected-
	# bee Job/Focus/Orders composition. The state they act on belongs in the
	# bottom-left summary panel; repeating it here was what made the centre
	# tray unnecessarily tall.
	cell_primary_columns = HFlowContainer.new()
	cell_primary_columns.add_theme_constant_override("separation", 16)
	cell_group.add_child(cell_primary_columns)

	var row := HFlowContainer.new()
	_build_cell_action_column(cell_primary_columns, "Reserve for").add_child(row)

	var nectar_btn := Button.new()
	_style_button(nectar_btn)
	nectar_btn.text = "Nectar"
	nectar_btn.focus_mode = Control.FOCUS_NONE
	nectar_btn.pressed.connect(func(): _request_designation("nectar"))
	live_buttons["designation_nectar"] = nectar_btn
	row.add_child(_with_info(nectar_btn, "Reserve this cell for nectar. Foragers carrying pollen will walk past it."))

	var pollen_btn := Button.new()
	_style_button(pollen_btn)
	pollen_btn.text = "Pollen"
	pollen_btn.focus_mode = Control.FOCUS_NONE
	pollen_btn.pressed.connect(func(): _request_designation("pollen"))
	live_buttons["designation_pollen"] = pollen_btn
	row.add_child(_with_info(pollen_btn, "Reserve this cell for pollen. Foragers carrying nectar will walk past it."))

	var honey_btn := Button.new()
	_style_button(honey_btn)
	honey_btn.text = "Honey"
	honey_btn.focus_mode = Control.FOCUS_NONE
	honey_btn.pressed.connect(func(): _request_designation("honey"))
	live_buttons["designation_honey"] = honey_btn
	row.add_child(_with_info(honey_btn, "Reserve this cell for honey. Honey makers spit their chewed nectar mix into cells like this one and then fan it dry."))

	var jelly_btn := Button.new()
	_style_button(jelly_btn)
	jelly_btn.text = "Jelly"
	jelly_btn.focus_mode = Control.FOCUS_NONE
	jelly_btn.pressed.connect(func(): _request_designation("jelly"))
	live_buttons["designation_jelly"] = jelly_btn
	row.add_child(_with_info(jelly_btn, "Reserve this cell for royal jelly. Nurses on the royal jelly sub-mode store what they make here, and draw on it when feeding gyne larvae."))

	var egg_btn := Button.new()
	_style_button(egg_btn)
	egg_btn.text = "Eggs"
	egg_btn.focus_mode = Control.FOCUS_NONE
	egg_btn.pressed.connect(func(): _request_designation("brood"))
	live_buttons["designation_brood"] = egg_btn
	row.add_child(_with_info(egg_btn, "Reserve this cell as a nursery. The queen lays here first, and foragers won't fill it with stores. Reserving enough of these is what stops laying stalling for want of a free cell."))

	var auto_btn := Button.new()
	_style_button(auto_btn)
	auto_btn.text = "Unreserve"
	auto_btn.focus_mode = Control.FOCUS_NONE
	auto_btn.pressed.connect(func(): _request_designation(""))
	live_buttons["designation_any"] = auto_btn
	row.add_child(_with_info(auto_btn, "Remove the reservation. The cell takes whichever resource arrives first, and reserves itself for that from then on."))

	_build_nursery_controls(_build_cell_action_column(cell_primary_columns, "Nursery"))

	cell_more_button = Button.new()
	_style_button(cell_more_button)
	cell_more_button.text = "More…"
	cell_more_button.theme_type_variation = "Small"
	cell_more_button.focus_mode = Control.FOCUS_NONE
	cell_more_button.toggle_mode = true
	cell_more_button.pressed.connect(func():
		cell_more_open = cell_more_button.button_pressed
		cell_more_panel.visible = cell_more_open
		call_deferred("_resize_command_tray")
	)
	cell_group.add_child(cell_more_button)

	cell_more_panel = HFlowContainer.new()
	cell_more_panel.add_theme_constant_override("separation", 16)
	cell_more_panel.visible = false
	cell_group.add_child(cell_more_panel)

	_build_empty_controls(_build_cell_action_column(cell_more_panel, "Emptying"))
	_build_closing_controls(_build_cell_action_column(cell_more_panel, "Sealing"))

## A stable logical column in the cell tray. These are headings rather than
## independent accordions: the whole row is meant to scan like the selected-
## bee Job/Focus/Orders row, with only the lower-frequency row behind More….
func _build_cell_action_column(parent: Container, title: String) -> VBoxContainer:
	var wrapper := VBoxContainer.new()
	wrapper.add_theme_constant_override("separation", 3)
	wrapper.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(wrapper)

	var header := Label.new()
	header.text = title
	header.theme_type_variation = "Small"
	header.add_theme_color_override("font_color", UiTheme.color("text_secondary"))
	wrapper.add_child(header)

	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 2)
	wrapper.add_child(body)
	return body

## The nursery: how hard the queen favours a reserved cell, and what it
## raises. Reserving the cell itself is done from the "Reserve for" column's
## Eggs/Unreserve buttons -- this column used to duplicate that with its own
## "Nursery zone" Add/Remove pair, which UI-C removed (UI_PLAN.md).
func _build_nursery_controls(column: VBoxContainer) -> void:
	var tier_row := HBoxContainer.new()
	column.add_child(tier_row)

	var tier_title := Label.new()
	tier_title.text = "Priority:"
	tier_title.theme_type_variation = "Small"
	tier_row.add_child(tier_title)

	for tier in range(3):
		var btn := Button.new()
		_style_button(btn)
		btn.text = ["Low", "Medium", "High"][tier]
		btn.theme_type_variation = "Small"
		btn.focus_mode = Control.FOCUS_NONE
		var tier_value: int = tier
		btn.pressed.connect(func(): _request_priority(tier_value))
		tier_row.add_child(btn)
		# tracked so _refresh_cell_popup can light up whichever is in
		# force on the cell being shown
		live_buttons["priority_%d" % tier] = btn

	tier_row.add_child(_info("How much of the queen's laying this cell gets. She shares eggs between the three tiers in proportion to their weights -- by default 1 : 2 : 3 -- so a high cell receives three eggs for every one a low cell receives, and they come out interleaved rather than in streaks. Twelve high forager cells beside three low nurse cells is how you say \"mostly foragers, a few nurses\" once and then leave it alone. The weights themselves are in the settings window."))

	var open_row := HBoxContainer.new()
	column.add_child(open_row)
	var open_btn := Button.new()
	_style_button(open_btn)
	open_btn.text = "Open nursery window"
	open_btn.theme_type_variation = "Small"
	open_btn.pressed.connect(func(): nursery_window_requested.emit())
	open_row.add_child(_with_info(open_btn, "Open the nursery window: how many cells are assigned to each role and tier, what the colony is made of right now, and how many bees of each kind have emerged in the last three minutes. While it is open every reserved cell glows in the colour of the role it raises."))

	# Which role a bee raised here comes out as.
	hatch_row = HFlowContainer.new()
	column.add_child(hatch_row)
	var hatch_title := Label.new()
	hatch_title.text = "Raises:"
	hatch_title.theme_type_variation = "Small"
	hatch_row.add_child(hatch_title)
	hatch_row.add_child(_info("Set what a bee raised in this cell becomes when it emerges. Roles that have a sub-mode -- a forager's resource, whether a miner starts automining -- offer it here, so the new bee arrives already set up."))

	hatch_option_controls.clear()
	for entry in hatch_options():
		if not allowed_role_keys.is_empty() and (entry.role == -1 or not allowed_role_keys.has(Roles.key_for(entry.role))):
			continue
		var options: Array = entry.options
		var control: Control
		if options.size() == 1:
			var btn := Button.new()
			_style_button(btn)
			btn.text = entry.label
			btn.theme_type_variation = "Small"
			var role_value: int = entry.role
			var only: Dictionary = options[0]
			btn.pressed.connect(func(): _request_hatch_role(role_value, only.focus, only.automine))
			hatch_row.add_child(btn)
			control = btn
		else:
			control = _make_hatch_menu(entry)
			hatch_row.add_child(control)
		hatch_option_controls.append({"role": entry.role, "control": control})

	# Whether that role sticks for every future bee, or applies once.
	lock_row = HBoxContainer.new()
	column.add_child(lock_row)
	hatch_lock_box = CheckBox.new()
	_style_button(hatch_lock_box)
	hatch_lock_box.text = "Keep for every bee"
	hatch_lock_box.theme_type_variation = "Small"
	hatch_lock_box.toggled.connect(func(pressed: bool):
		if active_cell and is_instance_valid(active_cell):
			cell_hatch_lock_requested.emit(active_cell, pressed)
			_refresh_cell_popup()
	)
	lock_row.add_child(hatch_lock_box)

	# Whether the queen lays a gyne here rather than a worker.
	gyne_row = HBoxContainer.new()
	column.add_child(gyne_row)
	gyne_box = CheckBox.new()
	_style_button(gyne_box)
	gyne_box.text = "Raise a gyne (a future queen)"
	gyne_box.theme_type_variation = "Small"
	gyne_box.toggled.connect(func(pressed: bool):
		if active_cell and is_instance_valid(active_cell):
			cell_gyne_requested.emit(active_cell, pressed)
			_refresh_cell_popup()
	)
	gyne_row.add_child(gyne_box)
	gyne_row.add_child(_info("A gyne is a future queen. She costs the queen several times as much pollen to lay, takes four times as long to develop, and can only be fed on royal jelly with pollen and honey -- so you need nurses producing jelly before one will grow at all. She can do any worker job in the meantime, though she is bigger, slower and hungrier than a worker."))
	lock_row.add_child(_info("On: every bee this cell ever raises comes out in the chosen role, so you can earmark a cell as a builder nursery once and forget about it. Off: the role applies to the next bee only and then clears, so a one-off choice doesn't quietly govern the cell forever."))

## Sealing a cell. A colony with honey in it drinks the honey; this is
## how you set some aside for a hard stretch instead.
func _build_closing_controls(column: VBoxContainer) -> void:
	var row := HBoxContainer.new()
	column.add_child(row)

	var title := Label.new()
	title.text = "Sealing:"
	title.theme_type_variation = "Small"
	row.add_child(title)

	var close_btn := Button.new()
	_style_button(close_btn)
	close_btn.text = "Sealed"
	close_btn.theme_type_variation = "Small"
	close_btn.focus_mode = Control.FOCUS_NONE
	close_btn.pressed.connect(func(): _request_close(true))
	row.add_child(_with_info(close_btn, "Seal the selected cells. Nothing can be added and nothing taken out until you open them again -- the contents are held in reserve. A sealed cell is drawn with a dark bar across it."))
	live_buttons["closed"] = close_btn

	var open_btn := Button.new()
	_style_button(open_btn)
	open_btn.text = "Open"
	open_btn.theme_type_variation = "Small"
	open_btn.focus_mode = Control.FOCUS_NONE
	open_btn.pressed.connect(func(): _request_close(false))
	row.add_child(_with_info(open_btn, "Unseal the selected cells so the colony can use what is in them again."))
	live_buttons["open"] = open_btn

	var fill_btn := Button.new()
	_style_button(fill_btn)
	fill_btn.text = "Fill then seal"
	fill_btn.theme_type_variation = "Small"
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
	title.theme_type_variation = "Small"
	empty_row.add_child(title)

	var move_btn := Button.new()
	_style_button(move_btn)
	move_btn.text = "To another cell"
	move_btn.theme_type_variation = "Small"
	move_btn.pressed.connect(func(): _request_empty("move"))
	empty_row.add_child(_with_info(move_btn, "A builder comes and carries the contents to another cell with room for them. If nothing anywhere has room, the load is lost -- so keep an eye on how full the comb is."))

	var discard_btn := Button.new()
	_style_button(discard_btn)
	discard_btn.text = "Discard outside"
	discard_btn.theme_type_variation = "Small"
	discard_btn.pressed.connect(func(): _request_empty("discard"))
	empty_row.add_child(_with_info(discard_btn, "Throw the contents out of the hive. Quicker than moving them, but everything in the cell is gone."))

	# The two buttons above wait for a comb worker to pick the job up --
	# no help to a colony that doesn't have one yet, the queen included,
	# since Challenge 1 never lets her take Role.BUILDER. This one sends
	# the selected bee to do it herself, right now, with no role change.
	empty_by_bee_btn = Button.new()
	_style_button(empty_by_bee_btn)
	empty_by_bee_btn.text = "Empty this cell"
	empty_by_bee_btn.theme_type_variation = "Small"
	empty_by_bee_btn.pressed.connect(func():
		if active_cell and is_instance_valid(active_cell):
			cell_empty_by_bee_requested.emit(active_cell)
			_refresh_cell_popup()
	)
	empty_row.add_child(_with_info(empty_by_bee_btn, "The selected bee carries the contents out herself, right now -- no comb worker needed and no change to her role."))

	# This has to write straight through to the cell. It used to be read
	# back from the cell every frame by _refresh_cell_popup while only
	# being applied when one of the buttons above was pressed -- so
	# ticking it was undone a frame later and it looked like the option
	# could not be selected at all.
	var keep_row := HBoxContainer.new()
	column.add_child(keep_row)
	keep_empty_box = CheckBox.new()
	_style_button(keep_empty_box)
	keep_empty_box.text = "Leave empty"
	keep_empty_box.theme_type_variation = "Small"
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
	_style_button(menu)
	menu.text = entry.label
	menu.theme_type_variation = "Small"
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

## --- warning banner -----------------------------------------------
## A nudge, not an interruption: it sits at the top of the screen, the
## game carries on running behind it, and it clears itself after a while
## if the player doesn't dismiss it.

const WARNING_SECONDS := 18.0

func _build_warning_banner() -> void:
	warning_panel = PanelContainer.new()
	warning_panel.theme = UiTheme.build_theme()
	warning_panel.add_theme_stylebox_override("panel", UiTheme.panel_stylebox())
	warning_panel.set_anchors_preset(Control.PRESET_CENTER_TOP)
	warning_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	warning_panel.offset_top = 48  # fixed-inset
	warning_panel.custom_minimum_size = Vector2(520, 0)
	warning_panel.visible = false
	add_child(warning_panel)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	warning_panel.add_child(row)

	warning_label = Label.new()
	warning_label.theme_type_variation = "Body"
	warning_label.add_theme_color_override("font_color", UiTheme.color("warning"))
	warning_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	warning_label.custom_minimum_size = Vector2(450, 0)
	row.add_child(warning_label)

	var close_btn := Button.new()
	_style_button(close_btn)
	close_btn.text = "×"
	close_btn.custom_minimum_size = Vector2(28, 28)
	close_btn.pressed.connect(_dismiss_warning)
	row.add_child(close_btn)

## `key`/`min_gap` let a producer ask the channel to drop its own repeats
## without needing to remember a timestamp itself -- pass both, or neither
## for copy that should never be throttled (transactional confirmations,
## one-off notices). `severity` defaults to 0 (background information); a
## message arriving with severity no higher than what's already showing,
## inside that message's MIN_DWELL_SECONDS, queues instead of replacing it
## -- see UI-Q-3 in plans/now/ui-bottom-row.md.
func show_warning(text: String, key: String = "", min_gap: float = 0.0, severity: int = 0) -> void:
	if warnings_muted:
		return
	if key != "":
		var last_shown: float = _warning_last_shown.get(key, -INF)
		if Session.sim_time - last_shown < min_gap:
			return
		_warning_last_shown[key] = Session.sim_time

	if warning_panel.visible and severity <= _warning_severity \
			and Session.sim_time - _warning_shown_at < MIN_DWELL_SECONDS:
		_pending_warning = {"text": text, "severity": severity}
		return

	_show_warning_now(text, severity)

func _show_warning_now(text: String, severity: int) -> void:
	warning_label.text = text
	warning_panel.visible = true
	warning_timer = WARNING_SECONDS
	_warning_shown_at = Session.sim_time
	_warning_severity = severity
	_pending_warning = {}

func _dismiss_warning() -> void:
	warning_panel.visible = false
	if not _pending_warning.is_empty():
		_show_warning_now(_pending_warning.get("text", ""), _pending_warning.get("severity", 0))

func set_warnings_muted(value: bool) -> void:
	warnings_muted = value
	if value:
		warning_panel.visible = false
		_pending_warning = {}

## --- object summary (flower / obstacle / death / soil) -------------
## Folded into the bottom-left selection panel from four separate
## mouse-anchored popups (UI_BUGFIX_PLAN.md Slice 5, Dave's 22 Aug
## call). A content swap: whichever of a bee selection or an object
## summary happened most recently is what the panel shows. Leaves
## shown_bees/command_tray alone -- a bee can stay selected (and its
## command tray stay up) while this panel shows something else the
## player clicked to look at. See input_selection.gd's call sites.
func show_object_summary(kind: String, data) -> void:
	active_summary_kind = kind
	active_flower = data if kind == "flower" else null
	soil_summary_row.visible = kind == "soil"
	match kind:
		"flower":
			_refresh_flower_summary()
		"obstacle":
			_show_obstacle_summary(data)
		"soil":
			_show_soil_summary(data.count, data.reachable)
		"death":
			_show_death_summary(data.death_info)
	selection_panel.visible = true

## Kept live (unlike the other three kinds) because a flower's
## nectar/pollen amounts tick up while the panel is open -- see the
## _process call below.
func _refresh_flower_summary() -> void:
	if active_flower == null or not is_instance_valid(active_flower):
		return
	identity_label.text = active_flower.species_name
	energy_label.text = "Nectar: %d / %d   (+%.2f/s)\nPollen: %d / %d   (+%.2f/s)" % [
		int(round(active_flower.nectar_amount)),
		int(active_flower.nectar_capacity),
		active_flower.effective_nectar_rate(),
		int(round(active_flower.pollen_amount)),
		int(active_flower.pollen_capacity),
		active_flower.effective_pollen_rate(),
	]
	if active_flower.occupied_by != null and is_instance_valid(active_flower.occupied_by):
		activity_label.text = "Being worked by bee %d" % active_flower.occupied_by.bee_id
	else:
		activity_label.text = "No bee here"
	var age_days: float = active_flower.age_seconds / GameConfig.seconds_per_day
	var lifespan_days: float = active_flower.lifespan_seconds / GameConfig.seconds_per_day
	var season_line: String
	if not GameConfig.seasons_on:
		season_line = "Season: seasons off"
	else:
		var strength: float = active_flower.season_strength()
		season_line = "Season: in season (%d%%)" % int(round(strength * 100.0)) if strength > GameConfig.out_of_season_strength else "Season: out of season"
	var summary_lines: Array = ["Age: %.1f of %.1f days" % [age_days, lifespan_days], season_line]

	var age: float = active_flower.marker_age()
	if age >= 0.0 and age < GameConfig.tarsal_marker_seconds:
		summary_lines.append("Scent mark: %ds old%s" % [int(age), " (bees avoiding)" if GameConfig.tarsal_markers_on else ""])
	# else: the marker remains a timestamp on the flower for simulation
	# bookkeeping, but it is no longer useful player-facing information
	# once bees have stopped reacting to it.
	trait_label.text = "\n".join(summary_lines)

## Clicking a tree or a bank of raised ground says what it is, so the
## things bees have to walk round aren't unexplained scenery.
func _show_obstacle_summary(obstacle: Node2D) -> void:
	identity_label.text = obstacle.display_name()
	energy_label.text = ""
	activity_label.text = obstacle.description()
	trait_label.text = ""

func _show_soil_summary(count: int, reachable: int) -> void:
	identity_label.text = "%d soil block%s selected" % [count, "" if count == 1 else "s"]
	energy_label.text = ""
	if reachable < count:
		activity_label.text = "%d can be reached right now; the rest are buried and will be dug once the soil in front of them is gone." % reachable
	else:
		activity_label.text = ""
	trait_label.text = ""
	soil_mark_btn.visible = soil_marking_visible
	soil_clear_btn.visible = soil_marking_visible

## Clicking (or drag-selecting) a death mark shows what happened to the
## bee who died there. Built from death_marker.gd's death_info snapshot
## rather than a live bee -- see that file's header comment -- so this
## is a one-shot summary, not a persistent selection like
## update_selection() below.
func _show_death_summary(info: Dictionary) -> void:
	var title: String = "Queen" if info.get("is_queen", false) else ("Gyne" if info.get("is_gyne", false) else "Bee %d" % info.get("bee_id", 0))
	if info.get("bee_name", "") != "":
		title = "%s%s" % ["★ " if info.get("is_favourite", false) else "", info.get("bee_name")]
	identity_label.text = title
	energy_label.text = ""
	activity_label.text = "%s -- died of %s\nLived %.1f days" % [
		info.get("role_text", ""), info.get("cause", "unknown causes"), info.get("age_days", 0.0),
	]
	var trait_lines := []
	if info.get("trait_text", "") != "":
		trait_lines.append(info.get("trait_text"))
	if info.get("preferred_species", "") != "":
		trait_lines.append("Preferred flower: %s" % info.get("preferred_species"))
	if info.get("bee_fact", "") != "":
		trait_lines.append("\"%s\"" % info.get("bee_fact"))
	trait_label.text = "\n".join(trait_lines)

## Cell state now uses the bottom-left summary, while its actions share the
## command tray with Job/Focus/Orders and are mutually exclusive with those
## bee controls. Leaves the bee columns' own content untouched underneath
## (just hidden), so reselecting a bee restores exactly what it showed before.
func show_cell_popup(cell: Node2D, count: int = 1) -> void:
	active_cell = cell
	selected_cell_count = count
	active_summary_kind = "cell"
	active_flower = null
	soil_summary_row.visible = false
	selection_panel.visible = true
	command_columns.visible = false
	more_button.visible = false
	more_panel.visible = false
	cell_group.visible = true
	# FlowContainer skips sorting while hidden. Its first visible sort updates
	# the cached wrapped height, so every row stays inside the hit-test rect.
	hatch_row.queue_sort()
	command_tray.visible = true
	_refresh_cell_popup()
	call_deferred("_resize_command_tray")
	bottom_row_changed.emit()

func _refresh_cell_popup() -> void:
	if active_cell == null or not is_instance_valid(active_cell):
		_cell_popup_last_cell = active_cell
		_cell_popup_last_count = selected_cell_count
		_cell_popup_last_epoch = -1
		return
	identity_label.text = "%d cells selected\nShowing the first cell; every action applies to all" % selected_cell_count \
		if selected_cell_count > 1 else "Cell selected"

	var content_lines := []
	if selected_cell_count > 1:
		content_lines.append("Bulk selection")
	if not active_cell.is_built:
		content_lines.append("Unfinished — %d%% built" % int(active_cell.build_fraction() * 100.0))
	else:
		match active_cell.content_type:
			"nectar":
				content_lines.append("Nectar: %d / %d" % [int(round(active_cell.amount)), int(active_cell.capacity)])
			"pollen":
				content_lines.append("Pollen: %d / %d" % [int(round(active_cell.amount)), int(active_cell.capacity)])
			"jelly":
				content_lines.append("Royal jelly: %d / %d" % [int(round(active_cell.amount)), int(active_cell.capacity)])
			"honey":
				if active_cell.is_ripe_honey():
					content_lines.append("Honey: %d / %d" % [int(round(active_cell.amount)), int(active_cell.capacity)])
				else:
					content_lines.append("Honey mix: %d / %d — %d%% fanned dry" % [
						int(round(active_cell.amount)),
						int(active_cell.capacity),
						int(active_cell.ripen_fraction() * 100.0),
					])
					content_lines.append("Not edible until fully dried")
			"brood":
				content_lines.append("%s — %d%%" % [
					"Developing gyne" if active_cell.brood_is_gyne else "Developing bee",
					int(active_cell.development_percent()),
				])
				if active_cell.brood_is_gyne:
					content_lines.append("Needs royal jelly, pollen and honey")
				if active_cell.brood_fed_seconds > 0.0:
					content_lines.append("Fed on %s — %ds of development left" % [
						"honey" if active_cell.fed_on_honey else "nectar",
						int(active_cell.brood_fed_seconds),
					])
				else:
					content_lines.append("Hungry — development stopped; dies in %ds" % int(active_cell.seconds_until_death()))
			"corpse":
				content_lines.append("A dead larva blocks this cell")
				content_lines.append("Being cleared: %d%%" % int(active_cell.clean_fraction() * 100.0))
			_:
				content_lines.append("Empty")
	energy_label.text = "\n".join(content_lines)

	var state_lines := []
	var reserved := "any resource"
	if active_cell.keep_empty:
		reserved = "nothing — kept empty"
	elif active_cell.designated_type == "brood":
		reserved = "raising eggs"
	elif active_cell.designated_type != "":
		reserved = active_cell.designated_type
	state_lines.append("Takes: %s" % reserved)
	if active_cell.is_nursery_cell():
		state_lines.append("Nursery — %s priority" % ["low", "medium", "high"][clampi(active_cell.nursery_priority, 0, 2)])
	if active_cell.is_closed:
		state_lines.append("Sealed — nothing goes in or comes out")
	elif active_cell.fill_then_close:
		state_lines.append("Filling to the top, then sealing")
	if active_cell.evict_requested:
		state_lines.append("Waiting for a comb worker to empty it")
	activity_label.text = "\n".join(state_lines)

	var hatch_name := "colony default"
	for entry in hatch_options():
		if entry.role == active_cell.hatch_role:
			hatch_name = entry.label
			if entry.role == 0:
				hatch_name += " (%s)" % active_cell.hatch_focus
			elif entry.role == 5 and active_cell.hatch_automine:
				hatch_name += " (automine)"
			break
	trait_label.text = "Raises: %s%s" % [
		hatch_name,
		" — every bee" if active_cell.hatch_role_locked else "",
	]

	# Only worth offering while there is actually something to carry --
	# matches command_empty_cell's own guard in bee.gd.
	empty_by_bee_btn.visible = active_cell.content_type != "" \
		and active_cell.content_type != "brood" and active_cell.content_type != "corpse"

	# reflect the cell's own state without re-firing the signals
	keep_empty_box.set_pressed_no_signal(active_cell.keep_empty)
	hatch_lock_box.set_pressed_no_signal(active_cell.hatch_role_locked)
	gyne_box.set_pressed_no_signal(active_cell.hatch_gyne)
	_light_current_options()
	_apply_cell_popup_gating()

	_cell_popup_last_cell = active_cell
	_cell_popup_last_count = selected_cell_count
	_cell_popup_last_epoch = active_cell.display_epoch

## Hides whichever "Reserve for" buttons and hatch-role choices a
## Challenge hasn't taught yet, and the "Keep for every bee" row until
## its own stage unlocks it. allowed_designation_keys/allowed_role_keys
## empty means unrestricted -- outside a Challenge every control here
## stays visible, same convention as the bee-selection panel's role row.
func _apply_cell_popup_gating() -> void:
	for suffix in ["nectar", "pollen", "honey", "jelly", "brood", "any"]:
		var btn: Button = live_buttons.get("designation_%s" % suffix)
		if btn != null:
			btn.visible = allowed_designation_keys.is_empty() or allowed_designation_keys.has(suffix)
	for entry in hatch_option_controls:
		var role: int = entry.role
		entry.control.visible = allowed_role_keys.is_empty() or (role != -1 and allowed_role_keys.has(Roles.key_for(role)))
	if gyne_row != null:
		gyne_row.visible = allowed_role_keys.is_empty()
	if lock_row != null:
		lock_row.visible = hatch_lock_visible

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
		var dwell_elapsed := Session.sim_time - _warning_shown_at >= MIN_DWELL_SECONDS
		if not _pending_warning.is_empty() and dwell_elapsed:
			_show_warning_now(_pending_warning.get("text", ""), _pending_warning.get("severity", 0))
		elif warning_timer <= 0.0:
			warning_panel.visible = false

	_popup_cadence_elapsed -= _delta
	var cadence_due := _popup_cadence_elapsed <= 0.0
	if cadence_due:
		_popup_cadence_elapsed = POPUP_REFRESH_CADENCE

	if cell_group.visible:
		var stale: bool = active_cell != _cell_popup_last_cell \
			or selected_cell_count != _cell_popup_last_count \
			or (is_instance_valid(active_cell) and active_cell.display_epoch != _cell_popup_last_epoch)
		if cadence_due or stale:
			_refresh_cell_popup()
	if selection_panel.visible and cadence_due:
		if active_summary_kind == "flower":
			_refresh_flower_summary()
		elif active_summary_kind == "":
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
	discard_dialog.theme = UiTheme.build_theme()
	discard_dialog.add_theme_stylebox_override("panel", UiTheme.panel_stylebox())
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
		Session.save_preferences()
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

## How many foragers currently read above the "offer a mentor" threshold
## or below the "go and seek one" threshold, against how many are actually
## being judged (past recruit_grace_trips, not still mid-scout) -- see
## year_winter.gd::_refresh_recruit_gap. Placeholder home for this reading
## until a dedicated foraging window exists (see UI_PLAN.md).
func update_recruit_gap(text: String) -> void:
	corner_texts["recruit_gap"] = text
	_refresh_corner()

## The frame rate readout. Three numbers rather than one, because they
## answer different questions: the average tells you whether the game is
## fast enough, the current frame time tells you what that average is
## made of, and the worst frame in the last second is the one you
## actually felt. Smooth play with an occasional 60ms frame reads as
## choppy while the average still says 60. Game speed is folded in too --
## a slow reading at 4x speed means something different from the same
## reading at 1x, and this was previously left to be inferred from
## whichever speed button looked pressed.
func update_fps(average: int, frame_ms: float, worst_ms: float, game_speed: float) -> void:
	var speed_text: String = "paused" if is_equal_approx(game_speed, 0.0) else "%.1fx" % game_speed
	corner_texts["fps"] = "%d fps   %s   %.1f ms   worst %.0f ms" % [average, speed_text, frame_ms, worst_ms]
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

	Perf.begin("corner_rebuild_free")
	for child in corner_column.get_children():
		# perf_plot and perf_breakdown are persistent -- see their
		# declaration -- so their own redraw timing survives a rebuild
		# triggered by something unrelated, like the day counter.
		if child == perf_plot or child == perf_breakdown:
			continue
		child.queue_free()
	Perf.end("corner_rebuild_free")

	Perf.begin("corner_rebuild_labels")
	for key in CORNER_ORDER:
		if not Session.pinned_stats.has(key):
			continue
		var text: String = str(corner_texts.get(key, ""))
		if text == "":
			continue
		var label := Label.new()
		label.text = text
		# Each readout keeps its own headline/detail weighting (see
		# CORNER_SIZES) rather than collapsing onto the four shared
		# variations, so it scales directly instead.
		label.add_theme_font_size_override("font_size", int(round(CORNER_SIZES.get(key, 12) * Session.text_scale)))
		corner_column.add_child(label)
	Perf.end("corner_rebuild_labels")

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
	Perf.begin("corner_rebuild_signals")
	for entry in shown_signals:
		var line := Button.new()
		_style_button(line)
		line.text = "• %s" % entry[0]
		line.alignment = HORIZONTAL_ALIGNMENT_LEFT
		line.flat = true
		line.focus_mode = Control.FOCUS_NONE
		line.theme_type_variation = "Body"
		line.add_theme_color_override("font_color", _signal_color(int(entry[1])))
		line.add_theme_color_override("font_hover_color", UiTheme.color("text_primary"))
		line.add_theme_color_override("font_pressed_color", UiTheme.color("text_primary"))
		var action: String = entry[2] if entry.size() > 2 else ""
		if action != "":
			line.tooltip_text = "Click to select what this is about."
			line.pressed.connect(func(): signal_clicked.emit(action))
		corner_column.add_child(line)
	Perf.end("corner_rebuild_signals")
	Perf.end("corner_refresh")

## Bottom edge of the live top-left readout block. Left-side windows ask the
## HUD for this instead of guessing a fixed height for a changing column.
func corner_bottom() -> float:
	return corner_column.position.y + corner_column.size.y

## The y the bottom row starts at, for the left-side windows to stop
## above. Zero when nothing is selected, so a window gets the full height
## back the moment the summary panel closes. Mirrors corner_bottom().
func selection_panel_top() -> float:
	if selection_panel == null or not selection_panel.visible:
		return 0.0
	return selection_panel.position.y

## Called when the player stars or unstars something in either window:
## the corner has to be redrawn even though no number changed. Also the
## one place that keeps Session.perf_enabled in step with the "fps"
## star, so perf.gd's instrumentation only runs while someone could
## actually be looking at it.
func pinned_stats_changed() -> void:
	Session.perf_enabled = Session.pinned_stats.has("fps")
	corner_signature = ""
	_refresh_corner()

## Called by debug_panel.gd when "Show 8x speed button" is toggled, so the
## button appears or disappears in the running bar straight away rather
## than only on the next scene reload -- same "huds" group dispatch
## set_settings_button_width already uses.
func refresh_speed_visibility() -> void:
	for entry in speed_buttons:
		if entry.dev_only:
			entry.button.visible = Session.show_speed_8x

## For callers that have written into `corner_texts` directly, rather
## than through one of the update_* setters.
func refresh_corner() -> void:
	_refresh_corner()

func update_selection(bees: Array) -> void:
	# Any selection change stops camera-follow -- see the field comment
	# on follow_bee_toggled.
	follow_bee_toggled.emit(null, false)
	var previously_shown_count: int = shown_bees.size()
	shown_bees = bees
	# A bee selection always wins over whatever object summary the panel
	# might currently be showing -- see show_object_summary.
	active_summary_kind = ""
	soil_summary_row.visible = false
	var panel_was_visible := selection_panel.visible
	var tray_was_visible := command_tray.visible
	selection_panel.visible = not bees.is_empty()
	bottom_row_changed.emit()
	command_tray.visible = not bees.is_empty() and not _selection_has_command_lock(bees)
	if panel_was_visible and not selection_panel.visible:
		DiagnosticLog.log_selection_panels_hidden("update_selection.selection_panel", previously_shown_count, bees.size())
	if tray_was_visible and not command_tray.visible:
		DiagnosticLog.log_selection_panels_hidden("update_selection.command_tray", previously_shown_count, bees.size())
	# Same thing for the tray itself -- a bee selection always wins over
	# a cell selection's content, see show_cell_popup.
	cell_group.visible = false
	command_columns.visible = true
	if bees.is_empty():
		call_deferred("_resize_command_tray")
		return

	_rebuild_role_controls(bees)
	_refresh_selection_text()
	call_deferred("_resize_command_tray")

func _selection_has_command_lock(bees: Array) -> bool:
	command_locked_bees = command_locked_bees.filter(func(b): return is_instance_valid(b))
	for bee in bees:
		if command_locked_bees.has(bee):
			return true
	return false

## The command tray's controls, rebuilt from scratch whenever the
## selection changes.
##
## Job, Focus and Orders are the three always-visible columns (Dave's 22
## Aug call): Job is the role and "Change to…" dropdown, Focus is the
## current sub-mode, Orders is the click-a-spot actions and restocking.
## Follow bee, the backup role, finish-first and Favourite are used far less
## often and live under More…; Challenge 1's Build cell command stays primary.
func _rebuild_role_controls(bees: Array) -> void:
	for child in job_column.get_children():
		child.queue_free()
	for child in focus_column.get_children():
		child.queue_free()
	for child in orders_column.get_children():
		child.queue_free()
	for child in more_panel.get_children():
		child.queue_free()

	var common_role: int = _common_role(bees)
	var common_working_role: int = _common_working_role(bees)
	var first = bees[0] if is_instance_valid(bees[0]) else null
	var any_queen := false
	for b in bees:
		if is_instance_valid(b) and b.is_queen:
			any_queen = true
			break

	var show_queen_build_row: bool = show_queen_build_button and bees.size() == 1 and first != null and first.is_queen
	if show_queen_build_row:
		_build_queen_build_row(job_column)
	_build_doing_row(common_working_role, first)
	# Skipped while the queen's own "Build cell" button is showing --
	# that button is the one build control Challenge 1 wants here, not
	# also the ordinary placement/home-cell controls this row offers.
	if not show_queen_build_row:
		_build_orders_row(common_role, first)
	_build_follow_control(bees, first)

	_build_job_row(common_role, any_queen)
	_build_fallback_row(common_role, first)
	if bees.size() == 1 and first != null:
		_build_favourite_row(first)

	job_column_wrapper.visible = job_column.get_child_count() > 0
	focus_column_wrapper.visible = focus_column.get_child_count() > 0
	orders_column_wrapper.visible = orders_column.get_child_count() > 0
	more_button.visible = more_panel.get_child_count() > 0
	more_button.button_pressed = more_button.visible and more_panel_open
	more_panel.visible = more_button.button_pressed
	_update_command_tray_width()

## Challenge 1 only -- see set_queen_build_button_visible. It is a primary
## Job-column action so the manual placement lesson never hides behind More….
func _build_queen_build_row(column: VBoxContainer) -> void:
	var button := Button.new()
	_style_button(button)
	button.text = "Build cell"
	button.custom_minimum_size = Vector2(0, 26)
	button.theme_type_variation = "Small"
	button.pressed.connect(func(): queen_build_cell_requested.emit())
	column.add_child(button)

## Continuous camera tracking (UI_PLAN.md section 15 slice 3) -- only
## offered for a single selected bee, same condition as Favourite. The
## button always starts unpressed on a fresh selection; see
## update_selection's follow_bee_toggled(null, false) emit. Doesn't fit
## Job/Focus/Orders, so it lives under More… like Build cell above.
func _build_follow_control(bees: Array, first) -> void:
	if bees.size() != 1 or first == null:
		return
	var button := Button.new()
	_style_button(button)
	button.text = "Follow bee"
	button.theme_type_variation = "Small"
	button.focus_mode = Control.FOCUS_NONE
	button.toggle_mode = true
	button.toggled.connect(func(pressed: bool): follow_bee_toggled.emit(first, pressed))
	more_panel.add_child(_with_info(button, "Keeps the camera centred on this bee as it moves. Switches off the moment you select something else."))

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
## role it could be switched to. Builds into the Job column, not
## more_panel, per Dave's 22 Aug three-column call.
func _build_job_row(common_role: int, any_queen: bool) -> void:
	var row := _column_row(job_column)
	if common_role == -1:
		var mixed := Label.new()
		mixed.text = "mixed selection"
		mixed.theme_type_variation = "Small"
		mixed.add_theme_color_override("font_color", UiTheme.color("text_secondary"))
		row.add_child(mixed)
	elif allowed_role_keys.is_empty() or allowed_role_keys.has(Roles.key_for(common_role)):
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

	# What counts as "the mode this bee is on" differs by role -- a
	# forager's is the resource it collects, a miner's is a switch rather
	# than a choice between modes -- so each role says how to read it.
	for mode in modes:
		var key: String = mode.key
		# Availability.mode_gate_key owns the bare-vs-namespaced formula --
		# see the allowed_mode_keys field comment for why it's namespaced
		# for every role but Forager (Nurse and Comb worker both have a
		# mode keyed "both").
		var gate_key: String = Availability.mode_gate_key(common_role, key)
		if not allowed_mode_keys.is_empty() and not allowed_mode_keys.has(gate_key):
			continue
		var current: bool = _mode_is_active(common_role, first, key)
		var command: String = mode_command(common_role, key)
		focus_column.add_child(_toggle_button(
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

	match common_role:
		Bee.Role.FORAGER:
			var has_start: bool = first != null and first.has_forage_start_point()
			orders_column.add_child(_action_button("Clear start" if has_start else "Start here",
				func(): forage_start_point_requested.emit(),
				"Click this, then click a spot in the meadow. The selected foragers head there first on every trip out, so you can split them across different parts of the meadow instead of them all drifting to whichever flower is nearest the entrance."))
			if GameConfig.floral_constancy_on:
				var pref: String = first.preferred_species if first != null else ""
				orders_column.add_child(_action_button(("Flower: %s" % pref) if pref != "" else "Pick a flower",
					func(): floral_preference_requested.emit(),
					"Click this, then click a flower. The selected foragers will only ever visit that species from then on, even walking past a nearer flower of something else -- real bees do this too."))
		Bee.Role.BUILDER:
			orders_column.add_child(_action_button("Build here",
				func(): build_cell_requested.emit(),
				"Click this, then click any open tile -- including ground that has been mined out. Hold Ctrl and keep clicking to queue up several: they are built in the order you click them, and a faint line shows that order while this bee is selected."))
			orders_column.add_child(_action_button("Keep clear",
				func(): keep_clear_requested.emit(),
				"Click this, then click a tile to reserve it as open floor. No comb worker will ever build there, so you can keep a corridor through the comb or a landing area by the entrance. Clicking a reserved tile again releases it. This applies to every comb worker, not just this one, and the reserved tiles show whenever any comb worker is selected."))
			orders_column.add_child(_action_button("Work from here",
				func(): home_cell_requested.emit(),
				"Click this, then click a tile. That tile becomes the selected comb worker's centre of operations: left to itself it fills the space around it outwards in a spiral, rather than always adding to the middle. Applies to this one bee only, even if you have several selected -- use \"Set for all comb workers\" below to change every comb worker at once."))
			orders_column.add_child(_action_button("Set for all comb workers",
				func(): home_cell_all_requested.emit(),
				"Click this, then click a tile. Every comb worker in the colony -- not just the selected ones -- gets that tile as its centre of operations. Use this to redirect the whole team at once; use \"Work from here\" above to give one bee its own spot."))

			# Restocking needs three things chosen, so it gets its own
			# batch of buttons rather than crowding the general orders.
			if first != null and first.architect_mode == "restock":
				_build_restock_row(first)
		Bee.Role.MINER:
			orders_column.add_child(_action_button("Mine",
				func(): mine_target_requested.emit(),
				"Click this, then click a soil block for the selected miners to dig. Hold Ctrl and keep clicking to queue several: they are dug in the order you click them, and a faint line shows that order while the miner is selected."))
			orders_column.add_child(_action_button("Work from here",
				func(): mine_home_requested.emit(),
				"Click this, then click a tile. The selected miners will always dig whichever soil is nearest that tile, rather than whichever is nearest wherever they finished the last block. Keeps a team working through one face."))

## The restock sub-mode's own buttons: which cells to keep full, of what,
## and where the contents may come from.
##
## All three act on the current comb selection, which is why there is no
## "click a spot" mode here -- you select cells the ordinary way first,
## then press the button that says what they are for.
func _build_restock_row(first) -> void:
	for resource in ["nectar", "pollen", "honey", "jelly"]:
		var value: String = resource
		var current: bool = first != null and first.restock_resource == value
		orders_column.add_child(_toggle_button(
			resource.capitalize(), current,
			func(): restock_targets_requested.emit(value),
			"Select comb first, then press this. Those cells become the ones this comb worker keeps full of %s, fetching it from elsewhere in the hive whenever they run down. This is how you get a resource to sit *somewhere* -- honey beside the brood before winter, pollen within reach of the nursery -- rather than wherever the foragers happened to drop it." % resource
		))

	orders_column.add_child(_action_button("Only these",
		func(): restock_sources_requested.emit(true),
		"Select comb first, then press this. The comb worker will draw only on those cells when refilling. Use it to point restocking at the outer comb and leave the rest alone."))
	orders_column.add_child(_action_button("Never these",
		func(): restock_sources_requested.emit(false),
		"Select comb first, then press this. The comb worker will never take from those cells. This is what protects a winter store from being redistributed by your own bee."))
	orders_column.add_child(_action_button("Clear orders",
		func(): restock_clear_requested.emit(),
		"Forget this comb worker's restocking orders entirely -- the cells it keeps full, and the sources it may use."))

	if first != null and first.has_restock_orders():
		var summary := Label.new()
		summary.text = "%d cells of %s" % [first.restock_targets.size(), first.restock_resource]
		summary.theme_type_variation = "Small"
		summary.add_theme_color_override("font_color", UiTheme.color("success"))
		orders_column.add_child(summary)

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
	_style_button(finish_box)
	finish_box.text = "Finish the job first"
	finish_box.theme_type_variation = "Small"
	finish_box.button_pressed = first.finish_task_first if first != null else false
	finish_box.toggled.connect(func(pressed: bool): finish_first_requested.emit(pressed))
	row.add_child(_with_info(finish_box, "On: reassigning this bee waits until it has finished what it is doing -- a forager delivers the load it is carrying, a comb worker finishes the cell it is on -- and the new role takes effect the moment it is free. Off: it drops everything and starts immediately."))

	# The queen's own laying rule sits here rather than in its own row --
	# it is a "what does she do when she can't lay" question, which is
	# the same question this row is about.
	if first != null and first.is_queen and common_role == Bee.Role.EGG_LAYER:
		var any_cell_box := CheckBox.new()
		_style_button(any_cell_box)
		any_cell_box.text = "Lay in plain comb too"
		any_cell_box.theme_type_variation = "Small"
		any_cell_box.button_pressed = GameConfig.queen_lays_in_any_cell
		any_cell_box.toggled.connect(func(pressed: bool): queen_lay_any_cell_toggled.emit(pressed))
		row.add_child(_with_info(any_cell_box, "On (the default): once every nursery cell is occupied she lays into any spare undesignated cell, so laying never stalls for want of somewhere to put an egg. Off: she lays only in cells reserved for eggs and waits when they are full. Turn it off for exact control, and be ready to reserve more cells for eggs or she stops laying."))

## The "when idle" menu, built from the role table so a new role turns
## up here without anyone remembering to add it.
func _secondary_items() -> Array:
	var items: Array = [{"text": "Nothing", "action": func(): secondary_role_requested.emit("none")}]
	for role in Roles.ROLES:
		if role.id == Roles.QUEEN or role.id == Roles.IDLE:
			continue   # neither is a sensible thing to fall back to
		var key: String = role.key
		if not allowed_role_keys.is_empty() and not allowed_role_keys.has(key):
			continue   # a Challenge hasn't taught this role yet
		items.append({"text": role.label, "action": func(): secondary_role_requested.emit(key)})
	return items

## One row of the More… panel, with its heading. Returns the box the
## controls go into.
## A bare row appended to one of the tray's Job/Focus/Orders columns --
## no title label, since the column's own header already says what it
## is. Same shape as _labelled_row below, minus the label.
func _column_row(parent: Container) -> HFlowContainer:
	# Role marker/menu pairs must wrap rather than impose their summed minimum
	# width on the entire command tray (UI-P-8).
	var row := HFlowContainer.new()
	row.add_theme_constant_override("separation", 4)
	parent.add_child(row)
	return row

func _labelled_row(title: String) -> HFlowContainer:
	# "When idle" and its companion controls live in More…; make the row
	# flow for the same narrow-window guarantee as the primary rows.
	var row := HFlowContainer.new()
	row.add_theme_constant_override("separation", 4)
	more_panel.add_child(row)

	var label := Label.new()
	label.text = "%s:" % title
	label.theme_type_variation = "Small"
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
	_style_button(button)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.text = label
	button.theme_type_variation = "Small"
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(action)
	if is_current:
		UI.mark_as_current(button)
	return _with_info(button, tip)

func _action_button(label: String, action: Callable, tip: String) -> Control:
	var button := Button.new()
	_style_button(button)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.text = label
	button.theme_type_variation = "Small"
	button.pressed.connect(action)
	return _with_info(button, tip)

func _current_role_marker(label: String) -> Control:
	var button := Button.new()
	_style_button(button)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
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

## Same as _common_role, but reads current_working_role() -- a bee's
## secondary role while it's actively doing that job, not just its
## primary role. See _build_doing_row's use of this: a bee foraging
## entirely through a backup role still needs to be offered its sub-mode.
func _common_working_role(bees: Array) -> int:
	var found := false
	var role_value := -1
	for b in bees:
		if not is_instance_valid(b):
			continue
		var working: int = b.current_working_role()
		if not found:
			role_value = working
			found = true
		elif working != role_value:
			return -1
	return role_value if found else -1

func _make_role_menu(label: String, tip: String, items: Array) -> Control:
	var menu := MenuButton.new()
	_style_button(menu)
	menu.text = label
	menu.tooltip_text = tip
	var popup := menu.get_popup()
	for i in range(items.size()):
		popup.add_item(items[i].text, i)
	popup.id_pressed.connect(func(id: int): items[id].action.call())
	return menu

## Re-read every frame so the activity field tracks what the bee is
## doing. Fields are grouped per UI_PLAN.md section 5's ranking --
## identity/job, energy/load, activity, trait/quote -- each its own
## label so _apply_selection_field_visibility can hide any one of them.
func _refresh_selection_text() -> void:
	var previously_shown_count: int = shown_bees.size()
	shown_bees = shown_bees.filter(func(b): return is_instance_valid(b))
	if shown_bees.is_empty():
		if selection_panel.visible:
			DiagnosticLog.log_selection_panels_hidden("_refresh_selection_text.selection_panel", previously_shown_count, 0)
		if command_tray.visible:
			DiagnosticLog.log_selection_panels_hidden("_refresh_selection_text.command_tray", previously_shown_count, 0)
		selection_panel.visible = false
		command_tray.visible = false
		bottom_row_changed.emit()
		return
	if shown_bees.size() == 1:
		var b = shown_bees[0]

		var identity := "%s%s — %s" % [
			"Queen " if b.is_queen else "Bee ",
			"" if b.is_queen else str(b.bee_id),
			b.role_name_text(),
		]
		# Name first -- this is what turns "Bee 214" into someone the
		# player can recognise. See BEE_INDIVIDUALITY_PLAN.md.
		if b.bee_name != "":
			identity = "%s%s\n%s" % ["★ " if b.is_favourite else "", b.bee_name, identity]
		if b.is_queen:
			identity += "\nAge: %.1f days   (does not die of old age)" % b.age_days()
		else:
			identity += "\nAge: %.1f days   Left: %.1f days" % [b.age_days(), b.days_remaining()]
		identity_label.text = identity

		energy_label.text = "Energy %d%%\n%s" % [
			int(100.0 * b.energy / max(0.001, GameConfig.energy_capacity)),
			b.carrying_text(),
		]

		var challenge_runner = main.challenge_runner if main != null else null
		var waiting_for_instruction = (
			challenge_runner != null and challenge_runner.active
			and b.is_queen
			and (b.state == Bee.State.IDLING or b.state == Bee.State.NURSE_IDLE or b.player_driven)
		)
		var activity: String
		var stuck: String = ""
		if waiting_for_instruction:
			var instruction: String = challenge_runner.current_stage_instruction()
			activity = "Now: waiting for instruction"
			if instruction != "":
				activity += " -- %s" % instruction
			activity_label.add_theme_color_override("font_color", UiTheme.readable_accent(UiTheme.color("accent_nectar")))
		else:
			activity = "Now: %s" % b.task_description()
			# If it isn't doing anything, say why. A bee standing still looks
			# identical whatever the reason, and "nothing is happening and I
			# can't tell why" is the worst state to leave a player in.
			stuck = b.idle_reason()
			if stuck != "":
				activity += "\n%s" % stuck
				activity_label.add_theme_color_override("font_color", UiTheme.color("warning"))
			else:
				activity_label.add_theme_color_override("font_color", UiTheme.readable_accent(UiTheme.color("accent_nectar")))
		if GameConfig.floral_constancy_on and b.role == Bee.Role.FORAGER and b.preferred_species != "":
			activity += "\nPreferred flower: %s" % b.preferred_species
		# the queen's pollen store is the thing that gates egg-laying,
		# so it's worth showing as a running total
		if b.is_queen:
			activity += "\nPollen eaten: %d / %d needed for an egg" % [
				int(b.pollen_eaten), int(GameConfig.egg_pollen_cost),
			]
		activity_label.text = activity

		# "trait" is a reserved GDScript word (used for the language's own
		# trait/mixin feature), so this can't be called that even though
		# it holds a bee's rolled trait line.
		var trait_line: String = b.trait_text()
		if b.bee_fact != "":
			trait_line += ("\n" if trait_line != "" else "") + "\"%s\"" % b.bee_fact
		trait_label.text = trait_line
	else:
		identity_label.text = "%d bees selected" % shown_bees.size()
		energy_label.text = ""
		activity_label.text = ""
		trait_label.text = ""
	_update_command_tray_width()

## Sets the selection panel's width for the current viewport
## (UiLayout.selection_tray_width -- since UI-H, whatever room is left up
## to the command tray's reserved zone, not a fixed per-breakpoint number)
## -- called at build time and again from _on_viewport_size_changed, never
## from content. See _build_selection_panel and the durable rule in
## UI_PLAN.md UI-B.
func _apply_selection_tray_width() -> void:
	var rect := UiLayout.summary_panel_rect(get_viewport().get_visible_rect().size)
	UiPanelLayout.apply(selection_panel, null, rect, UiLayout.BOTTOM_ROW_MARGIN)
	if selection_column != null:
		# Cap the column to the space inside the panel's own border and
		# content margins, not the panel's outer width, so its content
		# cannot raise the column's minimum width above what the panel has
		# to give it.
		selection_column.custom_minimum_size.x = maxf(0.0, rect.size.x - UiLayout.panel_chrome().x)

## The command tray is centred at half the viewport until its two side bands
## reach their minimum widths. The summary panel and Gallerin bubble derive
## their widths from that same edge, preserving their shared 16px gaps.
## Setting the width on command_columns rather than command_tray itself makes
## columns wrap onto more rows instead of the whole tray growing wider.
func _update_command_tray_width() -> void:
	if command_tray == null or not command_tray.visible:
		return
	var viewport_width: float = get_viewport().get_visible_rect().size.x
	# Position the tray's explicit centred edge here so it updates on every
	# viewport resize; ui_panel_layout.gd::apply() owns the width itself.
	command_tray.offset_left = UiLayout.command_tray_left_edge(viewport_width)
	command_columns.custom_minimum_size.x = 0.0
	if cell_primary_columns != null:
		cell_primary_columns.custom_minimum_size.x = 0.0
	if cell_more_panel != null:
		cell_more_panel.custom_minimum_size.x = 0.0

## Content changes can alter the wrapped rows after their visibility changes.
## Recompute on the deferred layout pass, then cap the bottom-left tray so it
## always leaves the same gap from the top and bottom viewport edges.
func _resize_command_tray() -> void:
	if command_tray == null or not command_tray.visible:
		return
	# Width first: command_columns is an HFlowContainer, so its wrapped row
	# count -- and therefore the tray's real minimum height -- depends on
	# the width it is given. Measuring height at the old width was what put
	# the tray's top edge too low and spilled `More…` off the bottom edge
	# (Dave, 8 Sep 2026, C-11/C-12).
	_update_command_tray_width()
	command_scroll.custom_minimum_size.y = 0.0
	var rect := UiLayout.command_tray_rect(get_viewport().get_visible_rect().size)
	UiPanelLayout.apply(command_tray, command_scroll, rect, UiLayout.BOTTOM_ROW_MARGIN)

func set_winter_button_visible(value: bool) -> void:
	if winter_button != null:
		winter_button.visible = value

## Only the *other* view's icon and word ever show -- never both, never
## neither -- per UI_PLAN.md section 2.
func set_view_label(in_hive: bool) -> void:
	view_button_label.text = "Meadow" if in_hive else "Hive"
	view_icon.shape = "flower" if in_hive else "hive"
	view_button.tooltip_text = "Switch to the Meadow view." if in_hive else "Switch to the Hive view."
	view_icon.queue_redraw()

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

func set_foraging_button_visible(value: bool) -> void:
	if foraging_button != null:
		foraging_button.visible = value

## See the `allowed_role_keys` field comment. Rebuilds the selection
## panel immediately so a stage unlocking a new role shows it without
## waiting for the next unrelated selection change.
func set_allowed_role_keys(keys: Array) -> void:
	allowed_role_keys = keys
	if not shown_bees.is_empty():
		_rebuild_role_controls(shown_bees)
	if active_cell != null and is_instance_valid(active_cell) and cell_group != null and cell_group.visible:
		_apply_cell_popup_gating()

## The Challenge runner owns the lock decision; HUD only applies it to the
## two already-separate pieces of selection UI. Re-applying the current
## selection makes a stage transition lift the tray immediately.
func set_command_locked_bees(bees: Array) -> void:
	command_locked_bees = bees
	if not shown_bees.is_empty():
		update_selection(shown_bees)

func set_allowed_mode_keys(keys: Array) -> void:
	allowed_mode_keys = keys
	if not shown_bees.is_empty():
		_rebuild_role_controls(shown_bees)

## See the allowed_designation_keys field comment. Re-applies immediately
## if the cell popup is currently open, same as set_allowed_role_keys
## does for the bee-selection panel.
func set_allowed_designation_keys(keys: Array) -> void:
	allowed_designation_keys = keys
	if active_cell != null and is_instance_valid(active_cell) and cell_group != null and cell_group.visible:
		_apply_cell_popup_gating()

func set_hatch_lock_visible(value: bool) -> void:
	hatch_lock_visible = value
	if lock_row != null:
		lock_row.visible = value

func set_soil_marking_visible(value: bool) -> void:
	soil_marking_visible = value
	if soil_mark_btn != null:
		soil_mark_btn.visible = value
	if soil_clear_btn != null:
		soil_clear_btn.visible = value

## Challenge 1's 1.3 replaces the usual "assign Comb worker, then click a
## spot" flow with one direct button in the queen's own panel -- see
## TUTORIAL_PLAN.md. Only ever shown for the queen, one bee selected.
func set_queen_build_button_visible(value: bool) -> void:
	show_queen_build_button = value
	if not shown_bees.is_empty():
		_rebuild_role_controls(shown_bees)
