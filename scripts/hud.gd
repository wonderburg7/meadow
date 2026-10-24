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
const SkillTreePanel = preload("res://scripts/skill_tree_panel.gd")
const PollinationPop = preload("res://scripts/pollination_pop.gd")
const UiLayout = preload("res://scripts/ui_layout.gd")
const UiPanelLayout = preload("res://scripts/ui_panel_layout.gd")
const Shapes = preload("res://scripts/shapes.gd")
const Stages = preload("res://scripts/challenge_stages.gd")
const BeeNursery = preload("res://scripts/bee_nursery.gd")
const ColonyPanel = preload("res://scripts/colony_panel.gd")

# --- signals ------------------------------------------------------
signal role_requested(role_name: String)
## GP-2: a star on a Goals line was pressed; colony_milestones.gd listens.
signal goal_star_toggled(id: String)
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
signal clear_fermented_requested
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
## PP-5: nurses feed a hungry larva in this cell before any unmarked one.
signal cell_feed_first_requested(cell: Node2D, feed_first: bool)
## "Click a spot" modes -- main.gd arms the named tool from
## input_selection.gd::PLACEMENT_TOOLS and consumes the next click in the
## relevant view instead of treating it as a normal select/drag. "Work from
## here" for comb workers (`home_cell`) applies to one bee only, even if several
## are selected; `home_cell_all` is the colony-wide version. `queen_build_cell`
## is the direct button in the queen's panel (see
## set_queen_build_button_visible).
signal placement_tool_requested(tool_id: String)
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
## The "Clear the mark" button on a kept-clear tile summary (HR-1).
signal keep_clear_clear_requested()
## "none" clears it. Only offered for bees whose primary role actually
## checks a secondary -- see the note on _rebuild_role_controls.
signal secondary_role_requested(role_key: String)
## WP-3: the whole ordered backup list as role keys, for every selected bee.
signal backup_order_requested(role_keys: Array)
## Whether reassigning the selected bees waits for their current job.
signal finish_first_requested(value: bool)
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

# --- role controls ------------------------------------------------
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
		# BB-1: Honey's one mode, Fermenting, is not offered here -- a cell
		# raises a plain honey maker (a hatch-cell Fermenting option is out
		# of BB-1's scope).
		if role.modes.is_empty() or role.id == Roles.HONEY:
			options.append({"label": role.label, "focus": "nectar", "automine": false})
		else:
			for mode in role.modes:
				options.append({
					"label": "%s — %s" % [role.label, mode.label],
					"mode": mode.key,
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

# --- shared layout constants --------------------------------------
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

# --- fields -------------------------------------------------------
## Set by main.gd right after construction, matching the other systems'
## back-reference -- only used to read main.challenge_runner's state for
## the selected-bee activity line.
var main: Node2D

## --- stage marker direction overlay ---------------------------------
## This is intentionally an overlay rather than another persistent panel.
## Its CanvasLayer is above Dr Gallerin (layer 15), so an arrow which has
## been routed around a panel cannot then be drawn underneath that panel.
const MARKER_ARROW_LAYER := 16
const MARKER_ARROW_RADIUS := 18.0
const MARKER_ARROW_EDGE_INSET := 24.0
const MARKER_ARROW_HYSTERESIS := 2.0
const MARKER_ARROW_SCAN_STEP := 4.0
var marker_arrow_overlay: CanvasLayer
var stage_marker_arrow: Polygon2D
var _stage_marker_global_position := Vector2.ZERO
var _stage_marker_visible: bool = false
var _stage_marker_in_hive: bool = false
var _marker_exclusion_rects: Array[Rect2] = []

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
## GP-1: the Colony Run's Goals drop-down. The header button folds the
## shelf; `colony_goal_entries` holds what set_colony_goals was last given
## (each with an `id`, so GP-2 can star it). Both stay empty in a Challenge.
var goals_header: Button
var long_term_goal_label: Label
var colony_goal_entries: Array = []
## GP-2: a star on each line (child of the label) and the box that holds the
## starred lines while the drop-down is collapsed. `goal_star_ids` maps a
## label's star to the goal id its line currently shows.
var goal_stars: Array = []
var goal_star_ids: Dictionary = {}
var favourites_box: VBoxContainer
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
## The stage gate apply_gates was last handed, so _role_offered can ask
## Availability.role_query without reaching into main.gd. Null until then,
## which role_query reads as "no stage restriction".
var _stage_gate = null
## Restricts the cell popup's "Reserve for" row to just these designation
## keys ("nectar", "pollen", "honey", "jelly", "brood", "any" for
## Unreserve). Empty means no restriction. See set_allowed_designation_keys.
var allowed_designation_keys: Array = []
## Every run -- see set_queen_build_button_visible.
var show_queen_build_button: bool = true
## Stage-gated controls (F2s). `_gate_controls` maps an
## Availability.UI_GATES control name to a Callable returning that control
## -- a Callable, not the node, because some controls are rebuilt -- and
## `_gate_open` holds the state apply_gates last computed for it. A name
## absent from `_gate_open` reads as open, so starter modes, open world and
## Challenge 1 are unaffected. See apply_gates and _is_gate_open.
var _gate_controls: Dictionary = {}
var _gate_open: Dictionary = {}
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
## The header's ☆/★ toggle (HC-10) and the single bee it currently names,
## if any -- see _build_favourite_star and _set_favourite_star.
var favourite_star_btn: Button
var _favourite_star_bee = null
## The header's settings cog (HC-11) and the selection kind its popup is
## currently built for -- "bee", "multiple", or any other string, which
## SELECTION_FIELD_TABLE has no entry for and so hides the cog. See
## _build_selection_cog and _set_summary_cog_kind.
var selection_cog_btn: MenuButton
var _summary_cog_kind: String = ""
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
## Only shown for a soil summary -- see show_object_summary and the
## "miner" row of Availability.UI_GATES.
## The selection panel's own content column -- kept as a member so
## _apply_selection_tray_width can re-cap its width without a fresh build.
var selection_column: VBoxContainer
var soil_summary_row: BoxContainer
var keep_clear_summary_row: BoxContainer
var soil_mark_btn: Button
var soil_clear_btn: Button
## The _with_info() rows soil_mark_btn/soil_clear_btn sit in. A
## VBoxContainer/HBoxContainer's cross- and main-axis children don't take
## SIZE_EXPAND_FILL as licence to claim their parent's width on their
## own here -- _apply_selection_tray_width has to hand each one an
## explicit custom_minimum_size.x floor, the same way it already does for
## selection_column, or the buttons collapse to their own tiny autowrap
## minimum (HC-2, "soil panel's two buttons collapsed to about 10px
## wide", Dave, 9 Sep 2026).
var soil_mark_wrapper: HBoxContainer
var soil_clear_wrapper: HBoxContainer
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
## HC-8 -- guards _resettle_command_tray against a superseded chain: a
## reselection that lands before an older selection's settle loop finishes
## must stop that older chain from later overwriting the newer, correct
## size with its own stale one.
var _command_tray_resettle_generation: int = 0
## The wrapper itself stays visible always, so a hidden column still claims
## its GridContainer slot -- see _tray_column_share and the header/content
## pair below, which are what actually hide when a column has nothing to
## show for the current selection.
var job_column_wrapper: VBoxContainer
var job_column_header: Label
var job_column: VBoxContainer
var focus_column_wrapper: VBoxContainer
var focus_column_header: Label
var focus_column: VBoxContainer
var orders_column_wrapper: VBoxContainer
var orders_column_header: Label
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
var clear_fermented_btn: Button
var hatch_lock_box: CheckBox
var gyne_box: CheckBox
var gyne_row: HBoxContainer
## PP-5: the "Feed first" box, shown only once Priority cells is owned.
var feed_first_box: CheckBox
var feed_first_row: HBoxContainer
## COL-7: a single selected gyne's "Send her to found a colony" button, built
## by _build_gyne_send_row and kept current by _refresh_selection_text.
## Null whenever no gyne is shown.
var gyne_send_button: Button = null
## The "Keep for every bee" row, so the "hatch_lock" gate can hide it as
## a whole rather than reaching into its children.
var lock_row: HBoxContainer
## One entry per hatch_options() choice, so _refresh_cell_popup can hide
## the ones for a role the current Challenge hasn't unlocked yet.
var hatch_option_controls: Array = []
## Shown in place of the Raises options while a Challenge stage has unlocked
## none of them, so the row never reads as a title with nothing under it.
var hatch_locked_note: Label
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
const SEVERITY_INFO := 0
const SEVERITY_NOTICE := 1
const SEVERITY_DANGER := 2
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
## arrival only replaces it when it is at least as important.
var _pending_warning: Dictionary = {}

# --- problem strip ------------------------------------------------
## The at-a-glance problem strip, as [text, severity] pairs, kept so the
## corner can be rebuilt without main.gd having to resend it.
var shown_signals: Array = []

## Most lines the corner strip shows; any more collapse into one
## non-interactive "+N more" line (GP-4). The Colony and Nursery windows
## still list every line.
const SIGNAL_LINE_CAP := 4

## Ids of lines the player removed with the x. Presentation state only, not
## saved; an id is forgotten as soon as a refresh no longer reports it.
var removed_signal_ids: Array = []

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

# --- _ready and construction --------------------------------------
var discard_dialog: ConfirmationDialog
var discard_always_button: Button
var pending_cell: Node2D = null
## What confirm_discard runs if the player agrees; empty while the dialog
## is asking about a cell.
var _pending_discard_action: Callable = Callable()
## The Saves window (SV-2), created by main.gd (RR-2) and parented to it like
## every other GamePanel. Only the settings window's "Saves…" opens it (SA-1).
var saves_panel: CanvasLayer
## The read-only skill tree (AP-3), created and opened from here the same way.
var skill_tree_panel: CanvasLayer
## PP-2: the rising "+1" over a flower that earned a Pollinator Point.
var pollination_pop: Node2D
var skills_button: Button
var pending_type: String = ""

func _ready() -> void:
	process_mode = PROCESS_MODE_ALWAYS
	layer = 9
	# Deferred: main is still adding its own children while this runs.
	# Built by main.gd before the menu's early return (RR-2); this only
	# lets it follow the corner and bottom row now that they exist.
	saves_panel = main.saves_panel
	saves_panel.connect_hud_reflow()
	skill_tree_panel = SkillTreePanel.new()
	main.add_child.call_deferred(skill_tree_panel)
	# PP-2: drawn in the meadow, so it lives under main rather than this layer.
	pollination_pop = PollinationPop.new()
	main.add_child.call_deferred(pollination_pop)
	if main.pollination != null:
		main.pollination.points_earned.connect(pollination_pop.show_at)
		main.pollination.points_earned.connect(func(_flower): _refresh_stores_text())
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
	# HO-6: the column and its text must not swallow clicks meant for a bee
	# drawn beneath; the signal buttons below keep their own STOP filter.
	corner_column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(corner_column)

	perf_plot = PerfPlot.new()
	perf_plot.custom_minimum_size = Vector2(140, 40)
	perf_plot.visible = false
	perf_plot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	corner_column.add_child(perf_plot)
	perf_breakdown = PerfBreakdown.new()
	perf_breakdown.visible = false
	perf_breakdown.mouse_filter = Control.MOUSE_FILTER_IGNORE
	corner_column.add_child(perf_breakdown)

	# Last child of corner_column, so pausing only appends a line instead of
	# drawing over whichever readout reaches a fixed y.
	pause_label = Label.new()
	pause_label.theme_type_variation = "Heading"
	pause_label.text = "PAUSED"
	pause_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pause_label.visible = false
	corner_column.add_child(pause_label)

	_build_top_right_bar()
	_apply_interface_label_visibility()
	_build_goal_shelf()
	_build_selection_panel()
	_build_command_tray()
	_build_warning_banner()
	_build_discard_dialog()
	_build_stage_marker_arrow()
	get_viewport().size_changed.connect(_on_viewport_size_changed)

## Re-caps the selection and command trays to the new viewport width
## (UI_PLAN.md UI-B) -- a window resize is the only thing allowed to change
## either tray's width; bee/cell/flower content must not.
func _on_viewport_size_changed() -> void:
	_apply_corner_line_width()
	_apply_selection_tray_width()
	call_deferred("_resize_command_tray")
	_update_stage_marker_arrow()

func _build_stage_marker_arrow() -> void:
	marker_arrow_overlay = CanvasLayer.new()
	marker_arrow_overlay.name = "stage_marker_arrow_overlay"
	marker_arrow_overlay.layer = MARKER_ARROW_LAYER
	marker_arrow_overlay.process_mode = PROCESS_MODE_ALWAYS
	add_child(marker_arrow_overlay)

	stage_marker_arrow = Polygon2D.new()
	stage_marker_arrow.name = "stage_marker_arrow"
	# A three-sided Shapes circle starts with its point at +X. Rotating the
	# node therefore aims it directly along the true screen-space bearing.
	stage_marker_arrow.polygon = Shapes.circle_points(MARKER_ARROW_RADIUS, 3)
	stage_marker_arrow.color = Stages.MARKER_COLOUR
	stage_marker_arrow.visible = false
	marker_arrow_overlay.add_child(stage_marker_arrow)

## Called only by challenge_runner.gd. `in_hive` is presentation state from
## the runner, not a HUD inference about where the marker belongs.
func set_stage_marker(global_position: Vector2, marker_visible: bool, in_hive: bool) -> void:
	_stage_marker_global_position = global_position
	_stage_marker_visible = marker_visible
	_stage_marker_in_hive = in_hive

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

# --- speed controls -----------------------------------------------
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
	row1.name = "top_bar_row1"
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
	row2.name = "top_bar_row2"
	row2.alignment = BoxContainer.ALIGNMENT_END
	row2.add_theme_constant_override("separation", TOP_BAR_BUTTON_GAP)
	bar.add_child(row2)

	# Row-2 buttons carry a short on-hover tooltip on the button itself now
	# (Dave's 29 Aug ask -- "Opens Nursery Panel", not a paragraph); the
	# full explanation stays on each button's own "i" info badge, unchanged.
	colony_button = _icon_button("bee", "Colony", TOP_BAR_BUTTON_WIDTH, "Opens the Colony window.")
	colony_button.pressed.connect(func(): colony_panel_requested.emit())
	colony_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row2.add_child(colony_button)
	colony_info = _info("Open the colony overview: how many bees are on each job, what is in the comb, how the brood is doing, and how any of that has changed over time. Click a role in it to select every bee doing that job at once.")
	row2.add_child(colony_info)
	_register_gated_control("colony_button", func(): return colony_button)
	_register_gated_control("colony_info", func(): return colony_info)

	nursery_button = _icon_button("hex", "Nursery", TOP_BAR_BUTTON_WIDTH, "Opens the Nursery window.")
	nursery_button.pressed.connect(func(): nursery_window_requested.emit())
	nursery_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row2.add_child(nursery_button)
	nursery_info = _info("Open the nursery window: which cells are set to raise which role, what the colony is made of now, and how many of each kind have emerged recently. While it is open the reserved cells glow on the comb.")
	row2.add_child(nursery_info)
	_register_gated_control("nursery_button", func(): return nursery_button)
	_register_gated_control("nursery_info", func(): return nursery_info)

	# Icon-plus-label, same shape as colony/nursery/view now (UI-N) -- at
	# TOP_BAR_BUTTON_WIDTH there isn't room for "Foraging" as full text, so
	# it gets the icon+tooltip treatment instead of truncating ad hoc.
	foraging_button = _icon_button("flower", "Foraging", TOP_BAR_BUTTON_WIDTH, "Opens the Foraging window.")
	foraging_button.pressed.connect(func(): foraging_panel_requested.emit())
	foraging_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row2.add_child(foraging_button)
	_register_gated_control("foraging_button", func(): return foraging_button)
	row2.add_child(_info("Open the foraging window: trip timing (search+flight versus handling), flowers visited per trip, empty-return rate, and the same breakdown split by species, plus recruitment/scouting counts. Only fills in once Auto scouting or Auto-recruitment is on -- that is what scores a trip today."))

	# Only appears once a winter has been scheduled -- until then there is
	# nothing for it to say, and a permanently dead button is worse than
	# no button. Same icon+label treatment as the rest of the row (UI-N).
	winter_button = _icon_button("snow", "Winter", TOP_BAR_BUTTON_WIDTH, "Opens the Winter forecast.")
	winter_button.visible = Session.winter_coming
	winter_button.pressed.connect(func(): winter_window_requested.emit())
	winter_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row2.add_child(winter_button)

	# AP-3 (icon AP-5), just left of View (progression.md 8.5). Hidden in a
	# Challenge by its UI_GATES row (AP-7), as 8.5 asks.
	skills_button = _icon_button("arrow_up", "Skills", TOP_BAR_BUTTON_WIDTH, "Opens the skill tree.")
	# SK-1: a full-screen view, not a left window, so it leaves those alone.
	skills_button.pressed.connect(func(): skill_tree_panel.toggle())
	skills_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row2.add_child(skills_button)
	_register_gated_control("skills_button", func(): return skills_button)

	# Only the *other* view's icon and word ever show (UI_PLAN.md section
	# 2's Meadow/Hive exclusivity rule) -- set_view_label swaps both.
	view_button = _icon_button("hive", "Hive", TOP_BAR_BUTTON_WIDTH, "Switch to the Hive view.")
	view_icon = view_button.get_child(0).get_child(0)
	view_button_label = view_button.get_child(0).get_child(1)
	view_button.pressed.connect(func(): view_toggle_requested.emit())
	view_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row2.add_child(view_button)
	view_info = _info("Switch between the meadow (flowers and foragers) and the hive interior (comb, queen, brood) -- or press Tab. Both keep simulating whichever one you are looking at.")
	row2.add_child(view_info)
	_register_gated_control("view_button", func(): return view_button)
	_register_gated_control("view_info", func(): return view_info)

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

# --- Challenge goal readout ---------------------------------------
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

	# GP-1: the Goals header, the only part of the shelf that takes clicks.
	goals_header = Button.new()
	goals_header.flat = true
	goals_header.visible = false
	goals_header.size_flags_horizontal = Control.SIZE_SHRINK_END
	goals_header.theme_type_variation = "Body"
	goals_header.mouse_filter = Control.MOUSE_FILTER_STOP
	goals_header.pressed.connect(_on_goals_header_pressed)
	goal_shelf.add_child(goals_header)

	# GP-2: starred lines, shown while the drop-down is collapsed.
	favourites_box = VBoxContainer.new()
	favourites_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	favourites_box.add_theme_constant_override("separation", 1)
	favourites_box.visible = false
	goal_shelf.add_child(favourites_box)

	# GP-1: the long-term line, above the milestone.
	long_term_goal_label = Label.new()
	long_term_goal_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	long_term_goal_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	long_term_goal_label.custom_minimum_size = Vector2(320, 0)
	long_term_goal_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	long_term_goal_label.theme_type_variation = "Body"
	long_term_goal_label.visible = false
	UiTheme.bind_color(long_term_goal_label, "font_color", "text_primary")
	goal_shelf.add_child(long_term_goal_label)
	_add_goal_star(long_term_goal_label)

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
	completed_goal_label.add_theme_font_size_override("normal_font_size", UiTheme.font_px(12))
	completed_goal_label.add_theme_color_override("default_color", Color(UiTheme.color("warning"), 0.55))
	completed_goal_label.visible = false
	goal_shelf.add_child(completed_goal_label)
	_add_goal_star(completed_goal_label)

	# Primary: the current goal.
	current_goal_label = Label.new()
	current_goal_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	current_goal_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	current_goal_label.custom_minimum_size = Vector2(320, 0)
	current_goal_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	current_goal_label.theme_type_variation = "Body"
	UiTheme.bind_color(current_goal_label, "font_color", "warning")
	goal_shelf.add_child(current_goal_label)
	_add_goal_star(current_goal_label)

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
	UiTheme.bind_color(goal_progress_label, "font_color", "text_secondary")
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
	# A Challenge's shelf has no header and no long-term line (GP-1).
	colony_goal_entries = []
	goals_header.visible = false
	long_term_goal_label.visible = false
	favourites_box.visible = false
	for star in goal_stars:
		star.visible = false
	current_goal_label.visible = true
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

## GP-1: the Colony Run's Goals drop-down. `entries` are dictionaries of
## `id` ("long_term" or a milestone id), `text`, and `done` (true for the
## last goal met, drawn struck through). Called by colony_milestones.gd
## only; a Challenge keeps set_challenge_goal. Which lines show follows
## Session.goals_collapsed: collapsed leaves the header alone.
func set_colony_goals(entries: Array) -> void:
	colony_goal_entries = entries.duplicate(true)
	var long_text := ""
	var next_text := ""
	var done_text := ""
	var long_id := ""
	var next_id := ""
	var done_id := ""
	for entry in entries:
		if bool(entry.get("extra", false)):
			continue
		if str(entry.id) == "long_term":
			long_text = str(entry.text)
			long_id = "long_term"
		elif bool(entry.get("done", false)):
			done_text = str(entry.text)
			done_id = str(entry.id)
		else:
			next_text = str(entry.text)
			next_id = str(entry.id)
	_set_goal_star(long_term_goal_label, long_id, entries)
	_set_goal_star(current_goal_label, next_id, entries)
	_set_goal_star(completed_goal_label, done_id, entries)
	_rebuild_favourites(entries)
	long_term_goal_label.text = long_text
	current_goal_label.text = next_text
	completed_goal_label.text = "[s]%s[/s]" % done_text if not done_text.is_empty() else ""
	goal_progress_row.visible = false
	goals_header.visible = true
	goal_shelf.visible = true
	_apply_goals_collapsed()

func _apply_goals_collapsed() -> void:
	if not goals_header.visible:
		return
	goals_header.text = "Goals [+]" if Session.goals_collapsed else "Goals [-]"
	var open: bool = not Session.goals_collapsed
	long_term_goal_label.visible = open and not long_term_goal_label.text.is_empty()
	current_goal_label.visible = open and not current_goal_label.text.is_empty()
	completed_goal_label.visible = open and not completed_goal_label.text.is_empty()
	favourites_box.visible = not open and favourites_box.get_child_count() > 0

## GP-2: a small star as a child of a goal line. Its look and its goal id are
## set by set_colony_goals; pressing it only reports the id.
func _add_goal_star(label: Control) -> void:
	var star := Button.new()
	star.flat = true
	star.text = "☆"
	star.visible = false
	star.focus_mode = Control.FOCUS_NONE
	star.theme_type_variation = "Small"
	star.custom_minimum_size = Vector2(26, 20)
	star.tooltip_text = "Keep this goal on screen when the Goals list is collapsed."
	star.mouse_filter = Control.MOUSE_FILTER_STOP
	star.pressed.connect(func(): _on_goal_star_pressed(star))
	# On the right, where the right-aligned line ends (Dave, 24 Oct 2026),
	# with the line's text kept clear of it by a right margin.
	star.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	star.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	var room := StyleBoxEmpty.new()
	room.content_margin_right = star.custom_minimum_size.x
	label.add_theme_stylebox_override("normal", room)
	label.add_child(star)
	goal_stars.append(star)
	goal_star_ids[star] = ""

func _set_goal_star(label: Control, id: String, entries: Array) -> void:
	var star: Button = null
	for candidate in goal_stars:
		if candidate.get_parent() == label:
			star = candidate
	if star == null:
		return
	goal_star_ids[star] = id
	var starred := false
	for entry in entries:
		if str(entry.id) == id and bool(entry.get("starred", false)):
			starred = true
	star.text = "★" if starred else "☆"
	star.visible = not id.is_empty() and id != "all_met"

func _on_goal_star_pressed(star: Button) -> void:
	var id: String = str(goal_star_ids.get(star, ""))
	if not id.is_empty():
		goal_star_toggled.emit(id)

## GP-2: the collapsed view -- one line for each starred goal, a met one
## struck through. Rebuilt whenever the entries are, never per frame.
func _rebuild_favourites(entries: Array) -> void:
	for child in favourites_box.get_children():
		favourites_box.remove_child(child)
		child.queue_free()
	for entry in entries:
		if not bool(entry.get("starred", false)):
			continue
		var line := RichTextLabel.new()
		line.bbcode_enabled = true
		line.fit_content = true
		line.scroll_active = false
		line.mouse_filter = Control.MOUSE_FILTER_IGNORE
		line.custom_minimum_size = Vector2(320, 0)
		line.add_theme_font_size_override("normal_font_size", UiTheme.font_px(14))
		var done: bool = bool(entry.get("done", false))
		line.add_theme_color_override("default_color", Color(UiTheme.color("warning"), 0.55 if done else 1.0))
		var text: String = str(entry.text).replace("[", "[lb]")
		line.text = "[right]%s[/right]" % ("[s]%s[/s]" % text if done else text)
		favourites_box.add_child(line)

func _on_goals_header_pressed() -> void:
	Session.goals_collapsed = not Session.goals_collapsed
	Session.save_preferences()
	_apply_goals_collapsed()

func set_speed_display(speed_scale: float) -> void:
	pause_button.button_pressed = is_equal_approx(speed_scale, 0.0)
	for entry in speed_buttons:
		entry.button.button_pressed = is_equal_approx(entry.scale, speed_scale)

# --- bottom row ---------------------------------------------------
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
	# Named so LAY-6's control_rect/even_columns/no_collapsed_controls
	# assertions can address it and its descendants by a stable
	# get_node_or_null path from the "selection_panel" root
	# (scripts/scenario_actions.gd::_resolve_scoped_path).
	selection_column.name = "selection_column"
	selection_panel.add_child(selection_column)
	var column := selection_column
	_apply_selection_tray_width()

	# The cog sits on the same line as the identity label (Dave's 29 Aug
	# ask) rather than a row of its own above it -- that row used to be
	# empty air except for the cog, pushing every field down and making
	# the panel taller than it needed to be for no reason.
	var header := HBoxContainer.new()
	# Named for the same reason selection_column is: the star and cog
	# assertions below it need a stable path (HC-13).
	header.name = "summary_header"
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
	header.add_child(_build_favourite_star())
	header.add_child(_build_selection_cog())

	energy_label = Label.new()
	energy_label.theme_type_variation = "Small"
	energy_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UiTheme.bind_color(energy_label, "font_color", "success")
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
	soil_summary_row.name = "soil_summary_row"
	soil_summary_row.visible = false
	column.add_child(soil_summary_row)

	soil_mark_btn = Button.new()
	soil_mark_btn.name = "soil_mark_btn"
	_style_button(soil_mark_btn)
	soil_mark_btn.text = "Mark for digging"
	# Wrap rather than raise the column's minimum width past the space
	# _apply_selection_tray_width has given it (Dave, 8 Sep 2026, C-18).
	soil_mark_btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	soil_mark_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	soil_mark_btn.pressed.connect(func(): soil_mark_requested.emit(true))
	soil_mark_wrapper = _with_info(soil_mark_btn, "Flag every selected block for miners to dig out. Blocks buried behind other soil can be marked too -- miners simply cannot reach them until the ones in front are gone, so a marked seam digs itself inward layer by layer.")
	soil_mark_wrapper.name = "soil_mark_wrapper"
	soil_summary_row.add_child(soil_mark_wrapper)
	_register_gated_control("soil_mark_btn", func(): return soil_mark_btn)

	soil_clear_btn = Button.new()
	soil_clear_btn.name = "soil_clear_btn"
	_style_button(soil_clear_btn)
	soil_clear_btn.text = "Clear marks"
	soil_clear_btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	soil_clear_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	soil_clear_btn.pressed.connect(func(): soil_mark_requested.emit(false))
	soil_clear_wrapper = _with_info(soil_clear_btn, "Take the digging flag off the selected blocks. Any digging already done is kept, so you can put the mark back later without losing the work.")
	soil_clear_wrapper.name = "soil_clear_wrapper"
	soil_summary_row.add_child(soil_clear_wrapper)
	_register_gated_control("soil_clear_btn", func(): return soil_clear_btn)

	# Only shown for a kept-clear tile summary (HR-1); same stacking as above.
	keep_clear_summary_row = VBoxContainer.new()
	keep_clear_summary_row.name = "keep_clear_summary_row"
	keep_clear_summary_row.visible = false
	column.add_child(keep_clear_summary_row)

	var keep_clear_btn := Button.new()
	keep_clear_btn.name = "keep_clear_btn"
	_style_button(keep_clear_btn)
	keep_clear_btn.text = "Clear the mark"
	keep_clear_btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	keep_clear_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	keep_clear_btn.pressed.connect(func(): keep_clear_clear_requested.emit())
	keep_clear_summary_row.add_child(keep_clear_btn)

	_set_summary_cog_kind("")

## The star and the cog sit side by side in the summary panel's header, so
## they are one control pair and take one size (HC-13). Each used to set
## only its own width, leaving each button as tall as its own glyph's font
## metrics asked for -- and "☆" and "⚙" do not agree, so the star rendered
## shorter than the cog beside it (Dave, 10 Sep 2026, C-35).
const SUMMARY_HEADER_BUTTON_SIZE := Vector2(24.0, 24.0)

## The star toggle beside the cog (HC-10, moved from the command tray's
## More… panel -- see _set_favourite_star). Built once, like the cog, and
## only offered for one bee at a time, so "favourite" always names one
## individual rather than a whole selection. Lets the player find this bee
## again later from the colony window's Favourites list. See
## BEE_INDIVIDUALITY_PLAN.md section 7.
func _build_favourite_star() -> Control:
	favourite_star_btn = Button.new()
	# Named so LAY-6's control_rect assertions can address the star and the
	# cog by a stable path and compare their heights (HC-13).
	favourite_star_btn.name = "favourite_star_btn"
	_style_button(favourite_star_btn)
	favourite_star_btn.text = "☆"
	favourite_star_btn.theme_type_variation = "Body"
	# Keep the star aligned with the first identity line when that label
	# wraps, same as the cog just to its right.
	favourite_star_btn.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	# A fixed size so this single glyph cannot raise the selection column's
	# minimum width above the space _apply_selection_tray_width gives it at
	# a large text scale (Dave, 8 Sep 2026, C-18), and so the star matches
	# the cog's height rather than its own glyph's (HC-13).
	favourite_star_btn.custom_minimum_size = SUMMARY_HEADER_BUTTON_SIZE
	favourite_star_btn.tooltip_text = "Pin this bee by name so you can find it again in the colony window's Favourites list, in a colony of hundreds."
	favourite_star_btn.focus_mode = Control.FOCUS_NONE
	favourite_star_btn.visible = false
	favourite_star_btn.pressed.connect(func():
		if _favourite_star_bee != null and is_instance_valid(_favourite_star_bee):
			favourite_requested.emit(not _favourite_star_bee.is_favourite)
	)
	return favourite_star_btn

## Shows the star for exactly the one selected bee and hides it for
## anything else -- a cell, a soil block, a flower, an obstacle, a death
## mark, a multiple selection or nothing at all. Called on every selection
## change and on the same periodic refresh that keeps the identity label
## current, so a bee dying while selected clears the star the same way it
## clears the name (see _refresh_selection_text).
func _set_favourite_star(bee) -> void:
	_favourite_star_bee = bee
	favourite_star_btn.visible = bee != null
	if bee != null:
		favourite_star_btn.text = "★" if bee.is_favourite else "☆"

## Each selection kind's toggleable fields (HC-11), keyed the same way
## show_object_summary/show_cell_popup/_refresh_selection_text name a kind,
## plus "multiple" for more than one bee. A kind absent here -- cell, soil,
## flower, obstacle, death, or nothing selected -- has no line worth
## toggling (Dave, 9 Sep 2026, about cell and soil; the other three never
## respected these toggles either), so its cog is hidden entirely rather
## than opening a menu that does nothing. "control" names a
## _field_control() case; "key" is the exact existing Session property, so
## the bee panel's four toggles keep their current keys and defaults
## (requirement 4).
const SELECTION_FIELD_TABLE := {
	"bee": [
		{"label": "Identity & job", "control": "identity", "key": "show_selection_identity"},
		{"label": "Energy & load", "control": "energy", "key": "show_selection_energy"},
		{"label": "Activity", "control": "activity", "key": "show_selection_activity"},
		{"label": "Trait & quote", "control": "trait", "key": "show_selection_trait"},
	],
	"multiple": [
		{"label": "Identity & job", "control": "identity", "key": "show_selection_identity"},
	],
}

func _field_control(field_name: String) -> Control:
	match field_name:
		"identity": return identity_label
		"energy": return energy_label
		"activity": return activity_label
		"trait": return trait_label
	return null

## The tray's own configuration cog (UI_PLAN.md section 5) -- a plain
## gear glyph, same placeholder-art approach as debug_panel.gd's
## settings cog. Its popup stays open across clicks
## (hide_on_checkable_item_selection = false) so several fields can be
## toggled in one go. Built once, like the star; see _set_summary_cog_kind
## for the per-kind popup content and visibility.
func _build_selection_cog() -> Control:
	selection_cog_btn = MenuButton.new()
	selection_cog_btn.name = "selection_cog_btn"
	_style_button(selection_cog_btn)
	selection_cog_btn.flat = false # MenuButton defaults to flat, which skips its normal stylebox
	selection_cog_btn.text = "⚙"
	selection_cog_btn.theme_type_variation = "Body"
	# Keep the cog aligned with the first identity line when that label wraps
	# to show role and age below it (UI-P-8).
	selection_cog_btn.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	# A fixed size so this single glyph cannot raise the selection column's
	# minimum width above the space _apply_selection_tray_width gives it at
	# a large text scale (Dave, 8 Sep 2026, C-18), and so the cog matches
	# the star's height rather than its own glyph's (HC-13).
	selection_cog_btn.custom_minimum_size = SUMMARY_HEADER_BUTTON_SIZE
	selection_cog_btn.tooltip_text = "Choose which fields this panel shows for the selected bee."
	selection_cog_btn.focus_mode = Control.FOCUS_NONE
	var popup := selection_cog_btn.get_popup()
	_theme_popup_on_open(popup)
	popup.hide_on_checkable_item_selection = false
	popup.id_pressed.connect(func(id: int): _on_selection_field_toggled(id, popup))
	return selection_cog_btn

## HO-11: a MenuButton's popup is its own window and takes none of the HUD
## theme, so it opened in Godot's small default font. Each popup reads the
## shared theme's font, size and colours as it opens, so it follows a change
## to text scale, typeface or contrast without a refresh hook.
func _theme_popup_on_open(popup: PopupMenu) -> void:
	popup.about_to_popup.connect(func():
		var theme := UiTheme.active_theme()
		if theme.has_font("font", "Button"):
			popup.add_theme_font_override("font", theme.get_font("font", "Button"))
		else:
			popup.remove_theme_font_override("font")
		popup.add_theme_font_size_override("font_size", theme.get_font_size("font_size", "Button"))
		popup.add_theme_color_override("font_color", UiTheme.color("text_primary"))
		popup.add_theme_color_override("font_hover_color", UiTheme.color("text_primary"))
		popup.add_theme_color_override("font_disabled_color", UiTheme.color("disabled"))
		popup.add_theme_stylebox_override("panel", UiTheme.panel_stylebox())
	)

## Rebuilds the cog's popup from SELECTION_FIELD_TABLE for the given
## selection kind, and hides the cog entirely when that kind has no
## toggleable fields. Called everywhere the panel's content kind changes --
## show_object_summary, show_cell_popup, update_selection's empty-selection
## branch, and both branches of _refresh_selection_text -- the same call
## sites as _set_favourite_star.
func _set_summary_cog_kind(kind: String) -> void:
	_summary_cog_kind = kind
	var fields: Array = SELECTION_FIELD_TABLE.get(kind, [])
	selection_cog_btn.visible = not fields.is_empty()
	var popup := selection_cog_btn.get_popup()
	popup.clear()
	for i in fields.size():
		var field: Dictionary = fields[i]
		popup.add_check_item(field["label"], i)
		popup.set_item_checked(i, Session.get(field["key"]))
	_apply_selection_field_visibility()

func _on_selection_field_toggled(id: int, popup: PopupMenu) -> void:
	var fields: Array = SELECTION_FIELD_TABLE.get(_summary_cog_kind, [])
	if id < 0 or id >= fields.size():
		return
	var checked: bool = not popup.is_item_checked(id)
	popup.set_item_checked(id, checked)
	Session.set(fields[id]["key"], checked)
	Session.save_preferences()
	_apply_selection_field_visibility()

## The one place that decides whether each of the four ranked labels is
## seen. A kind the table covers (bee, multiple) hides a field the player
## switched off in the cog; a kind it does not cover (cell, soil, flower,
## obstacle, death) offers no toggle and shows whatever the _show_*_summary
## functions set. Either way an empty label is never visible: an empty Godot
## Label still reports a full line of font height as its minimum, so the
## three blank fields a soil, obstacle or death summary leaves behind were a
## band of dead space that grew with the text-size setting (Dave, 10 Sep
## 2026, HC-13). The test lives here rather than in the four _show_*_summary
## functions so a summary kind added later cannot reintroduce the band.
func _apply_selection_field_visibility() -> void:
	var fields: Array = SELECTION_FIELD_TABLE.get(_summary_cog_kind, [])
	var toggled_on := {}
	for field in fields:
		toggled_on[field["control"]] = bool(Session.get(field["key"]))
	for field_name in ["identity", "energy", "activity", "trait"]:
		var label := _field_control(field_name) as Label
		if label == null:
			continue
		# A field the table lists takes its toggle; a field it omits is
		# hidden for a kind that has a table entry (the "multiple" summary
		# offers identity alone) and shown for a kind that has none.
		var wanted: bool = toggled_on.get(field_name, fields.is_empty())
		label.visible = wanted and label.text != ""
	# The panel's height is a snapshot of its content's minimum, taken by
	# UiPanelLayout.apply, so hiding a label only reclaims its band once
	# that snapshot is retaken. Until HC-13 all four labels were visible
	# whatever they held, the snapshot was permanently the four-line worst
	# case, and that is the dead space itself.
	# Deferred, not immediate: Godot lays a container out on the frame after
	# its content changes, so measuring here would measure the labels as
	# they were before this call. Same reason update_selection defers
	# _resize_command_tray.
	call_deferred("_resize_selection_panel_to_content")

## Retakes the summary panel's height for the content now visible in it, and
## tells the left-side windows only when the height actually moved -- this
## runs on _refresh_selection_text's 0.1s cadence, and bottom_row_changed is
## not worth emitting ten times a second for a panel that has not shifted.
func _resize_selection_panel_to_content() -> void:
	if selection_panel == null or selection_column == null:
		return
	var previous_top: float = selection_panel.offset_top
	_apply_selection_tray_width()
	if not is_equal_approx(selection_panel.offset_top, previous_top):
		bottom_row_changed.emit()

# --- command tray -------------------------------------------------
## Gap between the tray's ranked columns, both the HFlowContainer's own
## separation and the even-width split _update_command_tray_width computes
## around it -- one constant so the two can never disagree.
const TRAY_COLUMN_SEPARATION := 16.0

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
	# Named (like command_content/command_columns below) so LAY-6's
	# control_rect/even_columns/no_collapsed_controls assertions can address
	# the tray's contents by a stable get_node_or_null path from the
	# "command_tray" root (scripts/scenario_actions.gd::_resolve_scoped_path).
	command_scroll.name = "command_scroll"
	# The tray's width is owned by _update_command_tray_width; this must
	# never grow a horizontal bar of its own.
	command_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	command_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	command_tray.add_child(command_scroll)

	var column := VBoxContainer.new()
	column.name = "command_content"
	column.add_theme_constant_override("separation", 4)
	# A ScrollContainer stretches a child to its own width only when the
	# child sets SIZE_EXPAND horizontally; without it Godot 4 lays the
	# child out at its own minimum width, which bunched Job/Focus/Orders
	# onto separate rows against the tray's left edge (Dave, C-18, 9 Sep 2026).
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	command_scroll.add_child(column)
	command_content = column
	# SR-4 -- the tray follows its content's minimum height whenever that
	# changes, not only while _resettle_command_tray's chain is running.
	column.minimum_size_changed.connect(_on_command_content_minimum_size_changed)

	# Three ranked columns rather than one flowing row, per Dave's 22 Aug
	# call -- each one wraps onto more rows internally rather than the
	# whole tray growing wider than its cap (see _update_command_tray_width),
	# which is still what lets the bottom row grow taller, not wider, at
	# high text scale (UI_PLAN.md section 2's bottom-row rule).
	# Still an HFlowContainer, not a GridContainer: at 800x600 a single
	# column's own content (the "Change to…" menu plus its role marker) is
	# wider than a genuine third, and a GridContainer's fixed column count
	# has no way to relieve that except by pushing the whole tray wider
	# than its cap. HFlowContainer's wrap-to-a-new-row is still what keeps
	# that case bounded; _tray_column_share below now applies unconditionally
	# instead of only when it happens to be wide enough (Dave, 10 Sep 2026:
	# pixel-equal columns whenever three actually fit on the row).
	command_columns = HFlowContainer.new()
	command_columns.name = "command_columns"
	command_columns.add_theme_constant_override("separation", int(TRAY_COLUMN_SEPARATION))
	column.add_child(command_columns)

	var job_group := _build_tray_column("Job")
	job_column_wrapper = job_group[0]
	job_column_header = job_group[2]
	job_column = job_group[1]
	var focus_group := _build_tray_column("Focus")
	focus_column_wrapper = focus_group[0]
	focus_column_header = focus_group[2]
	focus_column = focus_group[1]
	var orders_group := _build_tray_column("Orders")
	orders_column_wrapper = orders_group[0]
	orders_column_header = orders_group[2]
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
## plus the content VBox rows get added to. Returns [wrapper, content,
## header] -- _rebuild_role_controls shows/hides the header and content,
## not the wrapper, depending on whether the column has anything to say for
## the current selection, so a hidden column still holds its GridContainer
## slot (Dave, 10 Sep 2026: pixel-equal columns, unconditionally) rather
## than handing its third to its neighbours.
func _build_tray_column(title: String) -> Array:
	# Named to match the job_column_wrapper/job_column field pair the
	# caller assigns this pair's return into (same for focus/orders), so
	# LAY-6's assertions can address either one by a stable path under the
	# "command_tray" root -- see scenario_actions.gd::_resolve_scoped_path.
	var slug: String = title.to_lower()
	var wrapper := VBoxContainer.new()
	wrapper.name = "%s_column_wrapper" % slug
	wrapper.add_theme_constant_override("separation", 3)
	wrapper.custom_minimum_size = Vector2(100, 0)
	wrapper.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	command_columns.add_child(wrapper)

	var header := Label.new()
	header.text = title
	header.theme_type_variation = "Small"
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiTheme.bind_color(header, "font_color", "text_secondary")
	wrapper.add_child(header)

	var content := VBoxContainer.new()
	content.name = "%s_column" % slug
	content.add_theme_constant_override("separation", 3)
	wrapper.add_child(content)

	return [wrapper, content, header]

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
	cell_group.name = "cell_group"
	cell_group.add_theme_constant_override("separation", 2)
	cell_group.visible = false
	parent.add_child(cell_group)

	# The frequent actions form one low, wide row, mirroring the selected-
	# bee Job/Focus/Orders composition. The state they act on belongs in the
	# bottom-left summary panel; repeating it here was what made the centre
	# tray unnecessarily tall.
	cell_primary_columns = HFlowContainer.new()
	cell_primary_columns.name = "cell_primary_columns"
	cell_primary_columns.add_theme_constant_override("separation", int(TRAY_COLUMN_SEPARATION))
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

	# BB-1: shown once Bee bread is bought (_apply_cell_popup_gating).
	var bee_bread_btn := Button.new()
	_style_button(bee_bread_btn)
	bee_bread_btn.text = "Bee bread"
	bee_bread_btn.focus_mode = Control.FOCUS_NONE
	bee_bread_btn.pressed.connect(func(): _request_designation("bee_bread"))
	live_buttons["designation_bee_bread"] = bee_bread_btn
	row.add_child(_with_info(bee_bread_btn, "Reserve this cell for bee bread. Honey makers on Fermenting pack pollen and ripe honey in here. Once the cell is full it seals itself and ripens over about two days."))

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

	_build_priority_controls(_build_cell_action_column(cell_primary_columns, "Priority"))
	_build_raises_controls(_build_cell_action_column(cell_primary_columns, "Raises"))

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
	# Named like _build_tray_column's job/focus/orders pair, so LAY-6's
	# assertions (and UI-X-2's hatch menus below) can address this column
	# by a stable path under the "command_tray" root -- see
	# scenario_actions.gd::_resolve_scoped_path.
	var slug: String = title.to_lower().replace(" ", "_")
	var wrapper := VBoxContainer.new()
	wrapper.name = "%s_column_wrapper" % slug
	wrapper.add_theme_constant_override("separation", 3)
	wrapper.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(wrapper)

	var header := Label.new()
	header.text = title
	header.theme_type_variation = "Small"
	UiTheme.bind_color(header, "font_color", "text_secondary")
	wrapper.add_child(header)

	var body := VBoxContainer.new()
	body.name = "%s_column" % slug
	body.add_theme_constant_override("separation", 2)
	wrapper.add_child(body)
	return body

## The nursery: how hard the queen favours a reserved cell, and what it
## raises. Reserving the cell itself is done from the "Reserve for" column's
## Eggs/Unreserve buttons -- this column used to duplicate that with its own
## "Nursery zone" Add/Remove pair, which UI-C removed (UI_PLAN.md).
func _build_priority_controls(column: VBoxContainer) -> void:
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

## What a bee raised in this cell becomes: the role, its lock, and whether
## it raises a gyne. Split from _build_priority_controls by UI-X-3 so the
## cell tray's Nursery column fits in three narrower columns instead of one
## tall one.
func _build_raises_controls(column: VBoxContainer) -> void:
	# Which role a bee raised here comes out as.
	hatch_row = HFlowContainer.new()
	hatch_row.name = "hatch_row"
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
		hatch_option_controls.append({"role": entry.role, "control": control, "options": options})

	# Challenge 2's first stage unlocks no role a cell can raise, and the
	# row showed "Raises:" and nothing else (Dave, 19 Sep 2026).
	hatch_locked_note = Label.new()
	hatch_locked_note.text = "Nothing to choose yet -- a later stage unlocks this."
	hatch_locked_note.theme_type_variation = "Small"
	hatch_locked_note.visible = false
	hatch_row.add_child(hatch_locked_note)

	# Whether that role sticks for every future bee, or applies once.
	lock_row = HBoxContainer.new()
	column.add_child(lock_row)
	_register_gated_control("lock_row", func(): return lock_row)
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

	# PP-5: nurses come to the larva here before any unmarked one.
	feed_first_row = HBoxContainer.new()
	feed_first_row.name = "feed_first_row"
	column.add_child(feed_first_row)
	feed_first_box = CheckBox.new()
	_style_button(feed_first_box)
	feed_first_box.text = "Feed first"
	feed_first_box.theme_type_variation = "Small"
	feed_first_box.toggled.connect(func(pressed: bool):
		if active_cell and is_instance_valid(active_cell):
			cell_feed_first_requested.emit(active_cell, pressed)
			_refresh_cell_popup()
	)
	feed_first_row.add_child(feed_first_box)
	feed_first_row.add_child(_info("Nurses feed a hungry larva in a marked cell before any unmarked one, whatever food it takes, so scarce food goes where you want it. Marked larvae share it among themselves the way unmarked ones do: the hungriest first."))

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
	empty_row.add_child(_with_info(move_btn, "A builder comes and carries the contents to another cell with room for them. Fermented nectar is always thrown out instead. If nothing anywhere has room, the load is lost -- so keep an eye on how full the comb is."))

	var discard_btn := Button.new()
	_style_button(discard_btn)
	discard_btn.text = "Discard outside"
	discard_btn.theme_type_variation = "Small"
	discard_btn.pressed.connect(func(): _request_empty("discard"))
	empty_row.add_child(_with_info(discard_btn, "Throw the contents out of the hive. Quicker than moving them, but everything in the cell is gone."))

	# NF-5: only offered while the popup's cell holds fermented nectar.
	clear_fermented_btn = Button.new()
	_style_button(clear_fermented_btn)
	clear_fermented_btn.text = "Discard all sour nectar"
	clear_fermented_btn.theme_type_variation = "Small"
	clear_fermented_btn.pressed.connect(func():
		clear_fermented_requested.emit()
		_refresh_cell_popup()
	)
	empty_row.add_child(_with_info(clear_fermented_btn, "Comb workers will carry every fermented cell's nectar out of the hive. Only the cells that are sour now: nectar that ferments later is not included."))

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
## The trailing ellipsis is the whole tell that this is a menu and not a
## one-press button -- the same convention the tray's "Change to…" menu
## already uses (HC-3, then HC-13 for C-34). The popup entries keep their
## own full labels; only the closed control gains it.
func _make_hatch_menu(entry: Dictionary) -> Control:
	var menu := MenuButton.new()
	_style_button(menu)
	menu.flat = false # MenuButton defaults to flat, which skips its normal stylebox
	menu.text = "%s…" % entry.label
	menu.theme_type_variation = "Small"
	var options: Array = entry.options
	var role_value: int = entry.role
	menu.name = "hatch_%s_menu" % Roles.key_for(role_value)
	var popup := menu.get_popup()
	_theme_popup_on_open(popup)
	_fill_hatch_menu(popup, role_value, options)
	popup.id_pressed.connect(func(id: int):
		_request_hatch_role(role_value, options[id].focus, options[id].automine)
	)
	return menu

## --- flower popup -------------------------------------------------

## --- warning banner -----------------------------------------------
## A nudge, not an interruption: it sits at the top of the screen, the
## game carries on running behind it, and it clears itself after a while
## if the player doesn't dismiss it.

## A Raises menu offers only the modes its Challenge stage has unlocked, by
## the same gate key the bee's own mode row uses (Availability.mode_gate_key).
## Item ids stay the option's index, so id_pressed still reads options[id].
## Before this the menu listed every mode, so unlocking nectar Foragers at
## Challenge 2's 2.1 would also have let the player raise the pollen Forager
## that 2.2 asks for (19 Sep 2026). Returns how many items it offers.
func _fill_hatch_menu(popup: PopupMenu, role_value: int, options: Array) -> int:
	popup.clear()
	for i in range(options.size()):
		var mode: String = options[i].get("mode", "")
		var gate_key: String = Availability.mode_gate_key(role_value, mode)
		if mode != "" and not allowed_mode_keys.is_empty() and not allowed_mode_keys.has(gate_key):
			continue
		# T2-12: a mode that names an unowned skill (Dig on its own, Stocking)
		# is not offered, as the bee's own mode row hides it.
		if mode != "" and not Availability.mode_query(role_value, mode, null, Session.progression).available:
			continue
		popup.add_item(options[i].label, i)
	return popup.item_count

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
	UiTheme.bind_color(warning_label, "font_color", "warning")
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
		if _pending_warning.is_empty() or severity >= _pending_warning.get("severity", SEVERITY_INFO):
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
	keep_clear_summary_row.visible = kind == "keep_clear"
	_set_favourite_star(null)
	_set_summary_cog_kind(kind)
	match kind:
		"flower":
			_refresh_flower_summary()
		"obstacle":
			_show_obstacle_summary(data)
		"soil":
			_show_soil_summary(data.count, data.reachable)
		"death":
			_show_death_summary(data.death_info)
		"keep_clear":
			_show_keep_clear_summary()
	# _set_summary_cog_kind above ran before these four wrote their text, so
	# the empty-label test has to be re-run now that there is text to test
	# (HC-13). Selection-driven, not per-frame.
	_apply_selection_field_visibility()
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
		summary_lines.append("Scent mark: %ds old%s" % [int(age), " (bees avoiding)" if GameConfig.tarsal_markers_on or (Session.progression != null and Session.progression.is_behaviour_enabled("tarsal_markers_on")) else ""])
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
	soil_mark_btn.visible = _is_gate_open("soil_mark_btn")
	soil_clear_btn.visible = _is_gate_open("soil_clear_btn")

## Clicking a tile the player has marked "keep clear" says so, and offers
## the way to undo it (HR-1).
func _show_keep_clear_summary() -> void:
	identity_label.text = "Kept clear"
	energy_label.text = ""
	activity_label.text = "No cell will be built on this tile; comb workers leave it empty."
	trait_label.text = ""

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
	keep_clear_summary_row.visible = false
	_set_favourite_star(null)
	_set_summary_cog_kind("cell")
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

func _cell_content_lines(cell, count: int) -> Array:
	var content_lines := []
	if count > 1:
		content_lines.append("Bulk selection")
	if not cell.is_built:
		content_lines.append("Unfinished — %d%% built" % int(cell.build_fraction() * 100.0))
	else:
		match cell.content_type:
			"nectar":
				content_lines.append("Nectar: %d / %d" % [int(round(cell.amount)), int(cell.capacity)])
			"pollen":
				content_lines.append("Pollen: %d / %d" % [int(round(cell.amount)), int(cell.capacity)])
			"jelly":
				content_lines.append("Royal jelly: %d / %d" % [int(round(cell.amount)), int(cell.capacity)])
			"bee_bread":
				if cell.is_ripe_bee_bread():
					content_lines.append("Bee bread: %d — ripe" % int(round(cell.amount)))
				elif cell.is_bee_bread_sealed():
					content_lines.append("Bee bread: %d — sealed, %d%% ripened" % [
						int(round(cell.amount)), int(cell.bee_bread_ripen_fraction() * 100.0),
					])
					content_lines.append("Not usable until it ripens")
				else:
					content_lines.append("Bee bread: %d / %d — seals when full" % [int(round(cell.amount)), int(cell.capacity)])
			"honey":
				if cell.is_ripe_honey():
					content_lines.append("Honey: %d / %d" % [int(round(cell.amount)), int(cell.capacity)])
				else:
					content_lines.append("Honey mix: %d / %d — %d%% fanned dry" % [
						int(round(cell.amount)),
						int(cell.capacity),
						int(cell.ripen_fraction() * 100.0),
					])
					content_lines.append("Not edible until fully dried")
			"brood":
				content_lines.append("%s — %d%%" % [
					"Developing gyne" if cell.brood_is_gyne else "Developing bee",
					int(cell.development_percent()),
				])
				if cell.brood_is_gyne:
					content_lines.append("Needs royal jelly, pollen and honey")
				if cell.brood_fed_seconds > 0.0:
					content_lines.append("Fed on %s — %ds of development left" % [
						"honey" if cell.fed_on_honey else "nectar",
						int(cell.brood_fed_seconds),
					])
				else:
					content_lines.append("Hungry — development stopped; dies in %ds" % int(cell.seconds_until_death()))
			"corpse":
				content_lines.append("A dead larva blocks this cell")
				content_lines.append("Being cleared: %d%%" % int(cell.clean_fraction() * 100.0))
			_:
				content_lines.append("Empty")
	return content_lines

func _cell_state_lines(cell) -> Array:
	var state_lines := []
	var reserved := "any resource"
	if cell.keep_empty:
		reserved = "nothing — kept empty"
	elif cell.designated_type == "brood":
		reserved = "raising eggs"
	elif cell.designated_type != "":
		reserved = cell.designated_type
	state_lines.append("Takes: %s" % reserved)
	if cell.is_nursery_cell():
		state_lines.append("Nursery — %s priority" % ["low", "medium", "high"][clampi(cell.nursery_priority, 0, 2)])
	if cell.priority_cell and BeeNursery.priority_cells_owned():
		state_lines.append("Fed first — nurses come here before unmarked brood")
	if cell.is_closed:
		state_lines.append("Sealed — nothing goes in or comes out")
	elif cell.fill_then_close:
		state_lines.append("Filling to the top, then sealing")
	if cell.evict_requested:
		state_lines.append("Waiting for a comb worker to empty it")
	return state_lines

func _cell_hatch_text(cell) -> String:
	var hatch_name := "colony default"
	for entry in hatch_options():
		if entry.role == cell.hatch_role:
			hatch_name = entry.label
			if entry.role == 0:
				hatch_name += " (%s)" % cell.hatch_focus
			elif entry.role == 5 and cell.hatch_automine:
				hatch_name += " (automine)"
			break
	return "Raises: %s%s" % [
		hatch_name,
		" — every bee" if cell.hatch_role_locked else "",
	]

func _refresh_cell_popup() -> void:
	if active_cell == null or not is_instance_valid(active_cell):
		_cell_popup_last_cell = active_cell
		_cell_popup_last_count = selected_cell_count
		_cell_popup_last_epoch = -1
		return
	identity_label.text = "%d cells selected\nShowing the first cell; every action applies to all" % selected_cell_count \
		if selected_cell_count > 1 else "Cell selected"

	energy_label.text = "\n".join(_cell_content_lines(active_cell, selected_cell_count))

	activity_label.text = "\n".join(_cell_state_lines(active_cell))

	trait_label.text = _cell_hatch_text(active_cell)

	# Only worth offering while there is actually something to carry --
	# matches command_empty_cell's own guard in bee.gd.
	empty_by_bee_btn.visible = active_cell.content_type != "" \
		and active_cell.content_type != "brood" and active_cell.content_type != "corpse"

	clear_fermented_btn.visible = active_cell.is_fermented()

	# reflect the cell's own state without re-firing the signals
	keep_empty_box.set_pressed_no_signal(active_cell.keep_empty)
	hatch_lock_box.set_pressed_no_signal(active_cell.hatch_role_locked)
	gyne_box.set_pressed_no_signal(active_cell.hatch_gyne)
	feed_first_box.set_pressed_no_signal(active_cell.priority_cell)
	_light_current_options()
	_apply_cell_popup_gating()
	# Same ordering as show_object_summary: the cog kind was set before this
	# function wrote the four labels (HC-13).
	_apply_selection_field_visibility()

	_cell_popup_last_cell = active_cell
	_cell_popup_last_count = selected_cell_count
	_cell_popup_last_epoch = active_cell.display_epoch

## Hides whichever "Reserve for" buttons and hatch-role choices a
## Challenge hasn't taught yet, and the "Keep for every bee" row until
## its own stage unlocks it. allowed_designation_keys/allowed_role_keys
## empty means unrestricted -- outside a Challenge every control here
## stays visible, same convention as the bee-selection panel's role row.
func _apply_cell_popup_gating() -> void:
	for suffix in ["nectar", "pollen", "honey", "jelly", "bee_bread", "brood", "any"]:
		var btn: Button = live_buttons.get("designation_%s" % suffix)
		if btn != null:
			var staged: bool = allowed_designation_keys.is_empty() or allowed_designation_keys.has(suffix)
			btn.visible = staged and Availability.designation_owned(suffix, Session.progression)
	var any_raise_option := false
	for entry in hatch_option_controls:
		var role: int = entry.role
		entry.control.visible = (role == -1 and allowed_role_keys.is_empty()) or (role != -1 and _role_offered(role))
		if entry.control is MenuButton:
			var offered: int = _fill_hatch_menu((entry.control as MenuButton).get_popup(), role, entry.options)
			entry.control.visible = entry.control.visible and offered > 0
		any_raise_option = any_raise_option or entry.control.visible
	if hatch_locked_note != null:
		hatch_locked_note.visible = not any_raise_option
	if gyne_row != null:
		gyne_row.visible = allowed_role_keys.is_empty()
	if feed_first_row != null:
		feed_first_row.visible = BeeNursery.priority_cells_owned()
	if lock_row != null:
		lock_row.visible = _is_gate_open("lock_row")

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
	_set_lit("designation_bee_bread", designation == "bee_bread")
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
	_update_stage_marker_arrow()
	if warning_panel.visible:
		warning_timer -= _delta
		if warning_timer <= 0.0:
			if not _pending_warning.is_empty():
				_show_warning_now(_pending_warning.get("text", ""), _pending_warning.get("severity", SEVERITY_INFO))
			else:
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

## The runner supplies the marker's global point and world. This transform is
## the camera-aware world-to-canvas conversion; CanvasLayer children use the
## resulting viewport coordinates directly.
func _stage_marker_screen_position() -> Vector2:
	var root: Node2D = main.hive_root if _stage_marker_in_hive else main.meadow_root
	return root.get_global_transform_with_canvas() * root.to_local(_stage_marker_global_position)

func _update_stage_marker_arrow() -> void:
	if stage_marker_arrow == null:
		return
	if not _stage_marker_visible or main == null or main.in_hive_view != _stage_marker_in_hive:
		stage_marker_arrow.visible = false
		return
	var viewport_size := get_viewport().get_visible_rect().size
	var marker_screen := _stage_marker_screen_position()
	# A two-pixel hysteresis stops an exactly-edge marker alternating between
	# its world glyph and the edge arrow as camera rounding changes by a pixel.
	if marker_screen.x >= -MARKER_ARROW_HYSTERESIS and marker_screen.x <= viewport_size.x + MARKER_ARROW_HYSTERESIS \
			and marker_screen.y >= -MARKER_ARROW_HYSTERESIS and marker_screen.y <= viewport_size.y + MARKER_ARROW_HYSTERESIS:
		stage_marker_arrow.visible = false
		return

	var safe_edge := Rect2(
		Vector2.ONE * MARKER_ARROW_EDGE_INSET,
		viewport_size - Vector2.ONE * MARKER_ARROW_EDGE_INSET * 2.0)
	# Rect2 has no closest-point helper in Godot 4, so clamp each axis into
	# the safe edge instead. Calling a method that does not exist is a parse
	# error, not a runtime one, so it took main.gd's whole compile down with
	# it and the HUD never built (Dave's 12 Sep report: every panel gone).
	var edge_point := Vector2(
		clampf(marker_screen.x, safe_edge.position.x, safe_edge.end.x),
		clampf(marker_screen.y, safe_edge.position.y, safe_edge.end.y))
	_refresh_marker_exclusion_rects(viewport_size)
	stage_marker_arrow.position = _slide_arrow_along_edge(edge_point, safe_edge)
	stage_marker_arrow.rotation = (marker_screen - viewport_size * 0.5).angle()
	stage_marker_arrow.visible = true

## ui_layout.gd owns each persistent panel's geometry. The live controls give
## their current, content-hugging height; their owner rectangles keep this
## overlay tied to the same layout contract on resize and future reflow.
func _refresh_marker_exclusion_rects(viewport_size: Vector2) -> void:
	_marker_exclusion_rects.clear()
	_append_marker_panel_exclusion(selection_panel, UiLayout.summary_panel_rect(viewport_size))
	_append_marker_panel_exclusion(command_tray, UiLayout.command_tray_rect(viewport_size))
	var gallerin_bubble: Control = null
	if main != null and main.gallerin_panel != null:
		gallerin_bubble = main.gallerin_panel.bubble
	_append_marker_panel_exclusion(gallerin_bubble, UiLayout.gallerin_rect(viewport_size))
	if corner_column != null and corner_column.visible:
		_marker_exclusion_rects.append(corner_column.get_global_rect().grow(MARKER_ARROW_RADIUS))

func _append_marker_panel_exclusion(panel: Control, owner_rect: Rect2) -> void:
	if panel == null or not panel.visible or owner_rect.size.x <= 0.0 or owner_rect.size.y <= 0.0:
		return
	_marker_exclusion_rects.append(panel.get_global_rect().grow(MARKER_ARROW_RADIUS))

func _slide_arrow_along_edge(edge_point: Vector2, edge_bounds: Rect2) -> Vector2:
	if not _marker_arrow_obscured(edge_point):
		return edge_point
	var horizontal_edge := is_equal_approx(edge_point.y, edge_bounds.position.y) \
		or is_equal_approx(edge_point.y, edge_bounds.end.y)
	var limit: float = edge_bounds.size.x if horizontal_edge else edge_bounds.size.y
	for step in range(int(MARKER_ARROW_SCAN_STEP), int(limit + MARKER_ARROW_SCAN_STEP), int(MARKER_ARROW_SCAN_STEP)):
		for direction in [-1.0, 1.0]:
			var candidate := edge_point
			if horizontal_edge:
				candidate.x = clampf(edge_point.x + step * direction, edge_bounds.position.x, edge_bounds.end.x)
			else:
				candidate.y = clampf(edge_point.y + step * direction, edge_bounds.position.y, edge_bounds.end.y)
			if not _marker_arrow_obscured(candidate):
				return candidate
	return edge_point # At the minimum supported viewport no clear edge exists.

func _marker_arrow_obscured(point: Vector2) -> bool:
	for panel_rect in _marker_exclusion_rects:
		if panel_rect.has_point(point):
			return true
	return false

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
## the sturdier choice here. Kept as discard_always_button so a
## confirmation that always asks (a Saves-window Delete) can hide it.
func _build_discard_dialog() -> void:
	discard_dialog = ConfirmationDialog.new()
	discard_dialog.theme = UiTheme.build_theme()
	discard_dialog.add_theme_stylebox_override("panel", UiTheme.panel_stylebox())
	discard_dialog.title = "Nothing else can hold this"
	discard_dialog.ok_button_text = "Discard it"
	discard_dialog.cancel_button_text = "Leave the cell as it is"
	add_child(discard_dialog)

	discard_always_button = discard_dialog.add_button("Discard, and stop warning me", true, "discard_always")
	discard_dialog.confirmed.connect(_on_discard_confirmed)
	discard_dialog.custom_action.connect(_on_discard_custom_action)

## Called by main.gd when re-designating a cell would destroy whatever
## is already in it, because no other cell has room.
func show_discard_warning(cell: Node2D, new_type: String, existing_type: String, existing_amount: float) -> void:
	_pending_discard_action = Callable()
	discard_dialog.title = "Nothing else can hold this"
	discard_dialog.ok_button_text = "Discard it"
	discard_dialog.cancel_button_text = "Leave the cell as it is"
	pending_cell = cell
	pending_type = new_type
	discard_always_button.visible = true
	discard_dialog.dialog_text = (
		"This cell holds %d %s, and there is no other cell with room for it.\n\n"
		+ "Reserving it for %s will throw that away."
	) % [int(round(existing_amount)), existing_type, new_type]
	discard_dialog.popup_centered()

## The same Session.warn_on_discard confirmation, for anything else that
## throws something away (SV-2's Saves window). Callers that honour
## warn_on_discard check it first; "Discard, and stop warning me" turns it
## off for every use alike. A caller that asks every time (SA-1: deleting a
## saved run) passes offer_stop_warning = false, which hides that button.
func confirm_discard(title: String, text: String, ok_text: String, cancel_text: String, action: Callable, offer_stop_warning: bool = true) -> void:
	pending_cell = null
	discard_always_button.visible = offer_stop_warning
	_pending_discard_action = action
	discard_dialog.title = title
	discard_dialog.ok_button_text = ok_text
	discard_dialog.cancel_button_text = cancel_text
	discard_dialog.dialog_text = text
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
	if _pending_discard_action.is_valid():
		var action := _pending_discard_action
		_pending_discard_action = Callable()
		action.call()
		return
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
	_day_shown = day
	_day_note = note
	corner_texts["day"] = "Day %d" % day
	if note != "":
		corner_texts["day"] += "\n%s" % note
	if weather_note != "":
		corner_texts["day"] += "\n%s" % weather_note
	_refresh_corner()

## FC-2: the first crisis's line under the day -- the forecast while the
## heavy rain is due, then the rain, then its passing (main.gd's
## _show_first_crisis_note). "" removes it. The day and season note are kept
## so the line can change between days.
var weather_note: String = ""
var _day_shown: int = 1
var _day_note: String = ""

func set_weather_note(text: String) -> void:
	if text == weather_note:
		return
	weather_note = text
	update_day(_day_shown, _day_note)

## Honey is counted only once it's fully fanned dry -- wet mix still
## drying in a cell isn't a store the colony can use yet. Anything sealed
## into closed cells is called out separately: it's still the colony's,
## but nothing can eat it until the cells are opened again.
## PP-2: Pollinator Points join the line once the colony owns the skill that
## earns them; before that there are none to show.
func update_storage(nectar: float, pollen: float, honey: float, jelly: float, sealed: float = 0.0) -> void:
	var text := "Nectar: %d   Pollen: %d   Honey: %d   Jelly: %d" % [
		int(round(nectar)), int(round(pollen)), int(round(honey)), int(round(jelly)),
	]
	if sealed > 0.5:
		text += "\n(%d sealed away in closed cells)" % int(round(sealed))
	_comb_stores_text = text
	_refresh_stores_text()

## The comb's figures from update_storage, kept so a point earned between
## two storage changes can redraw the readout on its own.
var _comb_stores_text: String = ""

func _refresh_stores_text() -> void:
	var text := _comb_stores_text
	if main.pollination != null and Session.progression != null \
			and Session.progression.is_behaviour_enabled(main.pollination.BEHAVIOUR):
		var line_end := text.find("\n")
		var points := "   Points: %d" % main.pollination.points
		text = text + points if line_end < 0 else text.insert(line_end, points)
	corner_texts["stores"] = text
	_refresh_corner()

func update_population(nectar_foragers: int, pollen_foragers: int, nurses: int, builders: int, miners: int, honey_makers: int) -> void:
	corner_texts["population"] = "Bees: %d nectar foragers, %d pollen foragers, %d nursing, %d comb workers, %d mining, %d on honey" % [
		nectar_foragers, pollen_foragers, nurses, builders, miners, honey_makers,
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

## `lines` is an array of [text, severity, action, category, id] from main.gd.
func update_signals(lines: Array) -> void:
	shown_signals = lines
	var reported: Array = lines.map(func(e): return str(e[4]))
	removed_signal_ids = removed_signal_ids.filter(func(id): return reported.has(id))
	corner_texts["signals"] = "\n".join(lines.map(func(e): return "• %s" % e[0]))
	_refresh_corner()

## True in a Colony Run, where red lines stay on screen with the strip unstarred.
func _red_always_shows() -> bool:
	return main != null and main.colony_milestones != null and main.colony_milestones.applies()

## The lines the corner strip draws: no severity-0 line, none the player
## removed, and only the red ones when the strip is unstarred in a Colony Run.
func strip_lines() -> Array:
	var starred: bool = Session.pinned_stats.has("signals")
	if not starred and not _red_always_shows():
		return []
	var out: Array = []
	for entry in shown_signals:
		var severity := int(entry[1])
		if severity <= 0 or removed_signal_ids.has(str(entry[4])):
			continue
		if not starred and severity < 2:
			continue
		out.append(entry)
	return out

func _remove_signal(id: String) -> void:
	if not removed_signal_ids.has(id):
		removed_signal_ids.append(id)
	_refresh_corner()

func _corner_signature(strip: Array) -> String:
	var signature := "scale=%s typeface=%s\n" % [Session.text_scale, Session.ui_typeface]
	for key in CORNER_ORDER:
		if Session.pinned_stats.has(key):
			signature += "%s=%s\n" % [key, corner_texts.get(key, "")]
	for entry in strip:
		signature += "s%d|%s|%s\n" % [entry[1], entry[0], entry[2]]
	return signature

func _rebuild_corner_labels() -> void:
	for key in CORNER_ORDER:
		if not Session.pinned_stats.has(key):
			continue
		var text: String = str(corner_texts.get(key, ""))
		if text == "":
			continue
		var label := Label.new()
		label.text = text
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		# Each readout keeps its own headline/detail weighting (see
		# CORNER_SIZES) rather than collapsing onto the four shared
		# variations, so it scales directly instead.
		label.add_theme_font_size_override("font_size", UiTheme.font_px(CORNER_SIZES.get(key, 12)))
		corner_column.add_child(label)

## One clickable problem line plus its dismiss button, added to the corner.
func _add_signal_row(entry: Array) -> void:
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	row.add_theme_constant_override("separation", 2)
	var line := Button.new()
	_style_button(line)
	line.text = "• %s" % entry[0]
	line.alignment = HORIZONTAL_ALIGNMENT_LEFT
	line.flat = true
	line.focus_mode = Control.FOCUS_NONE
	line.theme_type_variation = "Body"
	line.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	line.add_theme_color_override("font_color", _signal_color(int(entry[1])))
	line.add_theme_color_override("font_hover_color", UiTheme.color("text_primary"))
	line.add_theme_color_override("font_pressed_color", UiTheme.color("text_primary"))
	var action: String = str(entry[2])
	if action != "":
		line.tooltip_text = "Click to select what this is about."
		line.pressed.connect(func(): signal_clicked.emit(action))
	row.add_child(line)
	var remove := Button.new()
	_style_button(remove)
	remove.text = "×"
	remove.flat = true
	remove.focus_mode = Control.FOCUS_NONE
	remove.theme_type_variation = "Body"
	remove.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	remove.tooltip_text = "Remove this warning until the problem clears and comes back."
	remove.add_theme_color_override("font_color", _signal_color(int(entry[1])))
	var id: String = str(entry[4])
	remove.pressed.connect(func(): _remove_signal(id))
	row.add_child(remove)
	corner_column.add_child(row)
	_fit_corner_line(line)

func _rebuild_corner_signals(strip: Array) -> void:
	for entry in strip.slice(0, SIGNAL_LINE_CAP):
		_add_signal_row(entry)
	if strip.size() > SIGNAL_LINE_CAP:
		var more := Label.new()
		more.text = "• +%d more -- open the Colony window" % (strip.size() - SIGNAL_LINE_CAP)
		more.mouse_filter = Control.MOUSE_FILTER_IGNORE
		more.theme_type_variation = "Body"
		more.add_theme_color_override("font_color", UiTheme.color("text_secondary"))
		corner_column.add_child(more)

## Rebuilds the corner from the starred readouts. Only actually does the
## work when the result would look different, so this can be called from
## every setter without thrashing labels every frame.
func _refresh_corner() -> void:
	Perf.begin("corner_refresh")
	# Text scale is part of what the corner looks like: its labels carry
	# font-size overrides, which UiTheme.refresh() cannot reach, so without
	# it a text-size change never rebuilt them (19 Sep 2026).
	var strip := strip_lines()
	var show_signals: bool = not strip.is_empty()
	var signature := _corner_signature(strip)
	if signature == corner_signature:
		Perf.end("corner_refresh")
		return
	corner_signature = signature

	Perf.begin("corner_rebuild_free")
	for child in corner_column.get_children():
		# perf_plot and perf_breakdown are persistent -- see their
		# declaration -- so their own redraw timing survives a rebuild
		# triggered by something unrelated, like the day counter.
		if child == perf_plot or child == perf_breakdown or child == pause_label:
			continue
		child.queue_free()
	Perf.end("corner_rebuild_free")

	Perf.begin("corner_rebuild_labels")
	_rebuild_corner_labels()
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
		corner_column.move_child(pause_label, corner_column.get_child_count() - 1)
		Perf.end("corner_refresh")
		return
	# Each line is a button rather than a label, so it can take you to
	# what it is about. Being told there are hungry larvae and then having
	# to go and find them yourself is most of the work of acting on it.
	Perf.begin("corner_rebuild_signals")
	_rebuild_corner_signals(strip)
	Perf.end("corner_rebuild_signals")
	corner_column.move_child(pause_label, corner_column.get_child_count() - 1)
	Perf.end("corner_refresh")

## Width a problem line may take: the viewport minus the corner's margins.
func _corner_line_width() -> float:
	return maxf(0.0, get_viewport().get_visible_rect().size.x - corner_column.position.x * 2.0)

## Re-wraps the strip's lines after a viewport resize. Not per frame.
func _apply_corner_line_width() -> void:
	for child in corner_column.get_children():
		if child is Button:
			_fit_corner_line(child)

## Caps a problem line at the corner width without forcing it: a line that
## fits keeps its natural width (so it is not a click target across the top
## of the screen); a longer one wraps at the cap. Needs the button in the
## tree so its theme font resolves.
func _fit_corner_line(line: Button) -> void:
	line.autowrap_mode = TextServer.AUTOWRAP_OFF
	line.custom_minimum_size.x = 0.0
	var cap := _corner_line_width()
	if line.get_minimum_size().x > cap:
		line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		line.custom_minimum_size.x = cap

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
	keep_clear_summary_row.visible = false
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
		_set_favourite_star(null)
		_set_summary_cog_kind("")
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

## HC-16 -- a plain queue_free() left the old row parented -- and still
## counted by every nested HFlowContainer's wrap/height computation -- until
## Godot's own idle pass actually freed it, one to several frames after the
## new rows were already added alongside it. That is what made a
## reselection's settle unpredictable rather than merely slow: measuring
## while stale and fresh rows briefly coexisted found a real but
## meaningless number, and each old row's actual removal changed that
## number again later, arriving on no schedule a caller could wait out.
## remove_child() detaches it from the layout immediately -- so it stops
## being counted this same frame, before any new row is added -- while the
## node itself is freed only on queue_free()'s usual deferred pass, since
## this can run inside the very signal one of these rows (a role-menu
## PopupMenu's id_pressed) is still emitting, and freeing a node
## synchronously mid-signal is unsafe.
static func _detach_and_free_children(container: Node) -> void:
	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()

## The command tray's controls, rebuilt from scratch whenever the
## selection changes.
##
## Job, Focus and Orders are the three always-visible columns (Dave's 22
## Aug call): Job is the role and "Change to…" dropdown, Focus is the
## current sub-mode, Orders is the click-a-spot actions and restocking.
## Follow bee, the backup role, finish-first and Favourite are used far less
## often and live under More…; Challenge 1's Build cell command stays primary.
func _rebuild_role_controls(bees: Array) -> void:
	_detach_and_free_children(job_column)
	_detach_and_free_children(focus_column)
	_detach_and_free_children(orders_column)
	_detach_and_free_children(more_panel)
	gyne_send_button = null

	var common_role: int = _common_role(bees)
	var common_working_role: int = _common_working_role(bees)
	var first = bees[0] if is_instance_valid(bees[0]) else null
	var any_queen := false
	var queen_bee = null
	for b in bees:
		if is_instance_valid(b) and b.is_queen:
			any_queen = true
			queen_bee = b
			break

	var show_queen_build_row: bool = show_queen_build_button and bees.size() == 1 and first != null and first.is_queen
	if show_queen_build_row:
		_build_queen_build_row(job_column)
	_build_doing_row(common_working_role, first)
	_build_mating_row(bees, first)
	_build_gyne_send_row(bees, first)
	# Skipped while the queen's own "Build cell" button is showing --
	# that button is the one build control Challenge 1 wants here, not
	# also the ordinary placement/home-cell controls this row offers.
	if not show_queen_build_row:
		_build_orders_row(common_role, first)
	_build_follow_control(bees, first)

	_build_job_row(common_role, any_queen, queen_bee)
	_build_fallback_row(common_role, first)

	# The wrapper itself stays visible (see job_column_wrapper's field
	# comment) so it keeps its GridContainer slot; only the header and
	# content are hidden when the column has nothing to show for the
	# current selection, so a soil block (Orders only) doesn't make the
	# columns hop sideways the moment a bee is picked instead.
	var job_has_content: bool = job_column.get_child_count() > 0
	job_column_header.visible = job_has_content
	job_column.visible = job_has_content
	var focus_has_content: bool = focus_column.get_child_count() > 0
	focus_column_header.visible = focus_has_content
	focus_column.visible = focus_has_content
	var orders_has_content: bool = orders_column.get_child_count() > 0
	orders_column_header.visible = orders_has_content
	orders_column.visible = orders_has_content
	more_button.visible = more_panel.get_child_count() > 0
	more_button.button_pressed = more_button.visible and more_panel_open
	more_panel.visible = more_button.button_pressed
	_update_command_tray_width()

## Every run -- see set_queen_build_button_visible. It is a primary
## Job-column action so the manual placement lesson never hides behind More….
func _build_queen_build_row(column: VBoxContainer) -> void:
	var button := Button.new()
	_style_button(button)
	button.text = "Build cell"
	button.custom_minimum_size = Vector2(0, 26)
	button.theme_type_variation = "Small"
	button.pressed.connect(func(): placement_tool_requested.emit("queen_build_cell"))
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

## Job: what the selection is, lit up, plus one dropdown holding every
## role it could be switched to. Builds into the Job column, not
## more_panel, per Dave's 22 Aug three-column call.
func _build_job_row(common_role: int, any_queen: bool, queen_bee = null) -> void:
	var row := _column_row(job_column)
	# Named so LAY-6's control_rect assertion on the "Change to…" menu has a
	# stable path (see the row.add_child(_make_role_menu(..., "change_to_menu"))
	# call below and scenario_actions.gd::_resolve_scoped_path).
	row.name = "job_row"
	if common_role == -1:
		var mixed := Label.new()
		mixed.text = "mixed selection"
		mixed.theme_type_variation = "Small"
		UiTheme.bind_color(mixed, "font_color", "text_secondary")
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
		if not _role_offered(role.id, queen_bee):
			continue                       # not taught yet, or its skill not bought (the queen's free roles aside)
		items.append({
			"text": role.label,
			"action": func(): role_requested.emit(key),
		})
	if not items.is_empty():
		row.add_child(_make_role_menu("Change to…", "Switch the selected bees to another job. Sub-modes for that job appear on the Doing row once they are on it.", items, "change_to_menu"))

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
		# BB-1: Fermenting is offered only once Bee bread is owned. T2-12: the
		# Miner's "Dig on its own" waits for Automation the same way.
		# T3-2: Stocking likewise waits for Restocking.
		if (common_role == Roles.HONEY or common_role == Roles.COMB_WORKER or common_role == Roles.MINER) and not Availability.mode_query(common_role, key, null, Session.progression).available:
			continue
		var current: bool = _mode_is_active(common_role, first, key)
		var command: String = mode_command(common_role, key)
		focus_column.add_child(_toggle_button(
			mode.label, current,
			func(): role_requested.emit(command),
			mode.tip
		))

## COL-11: a single selected unmated queen chooses, at any time until she
## mates, between laying drones in the hive and nuptial flights -- the same
## two choices as the succession window (decision 12 of
## plans/now/colony-run.md). The flight mode is not saved yet (SI-1 holds
## the save files), so after a load this row is how the player puts her back
## on flights. Built with the rest of the panel, never per frame; a press
## rebuilds the panel so the lit button follows her mode. Once she has mated
## the row goes at the next rebuild, and a press before then does nothing.
func _build_mating_row(bees: Array, first) -> void:
	if bees.size() != 1 or first == null or not first.is_queen or first.is_mated:
		return
	var row := _column_row(focus_column)
	row.name = "mating_row"
	var label := Label.new()
	label.text = "Mating:"
	label.theme_type_variation = "Small"
	UiTheme.bind_color(label, "font_color", "text_secondary")
	row.add_child(label)
	row.add_child(_toggle_button(
		"Lay drones in the hive", not first.nuptial_flights,
		func(): _set_nuptial_flights(first, false),
		"She stays in the hive and lays. She has not mated, so every egg hatches as a drone, who eats but does no work."
	))
	row.add_child(_toggle_button(
		"Nuptial flights", first.nuptial_flights,
		func(): _set_nuptial_flights(first, true),
		"Once a day she leaves the hive for part of the day to find a mate, laying nothing while she is away. Her chance is best in mid summer and nothing outside late spring to early autumn. Once she has mated she lays workers again."
	))

func _set_nuptial_flights(queen, on: bool) -> void:
	if queen != null and is_instance_valid(queen):
		queen.set_nuptial_flights(on)
	if not shown_bees.is_empty():
		_rebuild_role_controls(shown_bees)

## COL-7: no gyne leaves by herself; a single selected gyne is sent from
## here. The button is greyed out until she is ready, and her readout says
## why, as an idle bee's does -- _refresh_selection_text keeps both current
## on its own cadence while the panel is visible, never per frame. The
## press is the only thing that sends her (season.gd::send_gyne).
func _build_gyne_send_row(bees: Array, first) -> void:
	if bees.size() != 1 or first == null or not first.is_gyne or first.is_queen:
		return
	var row := _column_row(focus_column)
	row.name = "gyne_send_row"
	var button := Button.new()
	_style_button(button)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.text = "Send her to found a colony"
	button.theme_type_variation = "Small"
	button.pressed.connect(func(): _send_gyne(first))
	gyne_send_button = button
	_refresh_gyne_send_button(first)
	row.add_child(_with_info(button, "She leaves the hive for good to found a colony of her own. Sent between late spring and early autumn she finds a mate, counts as sent out and earns genetic points, the most in mid summer. Sent outside that window she finds no mate and is lost, and does not count."))

func _send_gyne(gyne) -> void:
	if main != null and main.season != null:
		main.season.send_gyne(gyne)

## Why the shown gyne can't be sent yet, or "" if she can: season.gd's
## answer, the same one send_gyne checks.
func _gyne_not_ready_reason(gyne) -> String:
	if main == null or main.season == null:
		return "Only a gyne can be sent to found a colony."
	return main.season.gyne_not_ready_reason(gyne)

func _refresh_gyne_send_button(gyne) -> void:
	if gyne_send_button == null or not is_instance_valid(gyne_send_button):
		return
	gyne_send_button.disabled = _gyne_not_ready_reason(gyne) != ""

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
		Roles.HONEY:
			return bee.fermenting     # so is honey's (BB-1)
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
				func(): placement_tool_requested.emit("forage_start"),
				"Click this, then click a spot in the meadow. The selected foragers head there first on every trip out, so you can split them across different parts of the meadow instead of them all drifting to whichever flower is nearest the entrance."))
			if GameConfig.floral_constancy_on:
				var pref: String = first.preferred_species if first != null else ""
				orders_column.add_child(_action_button(("Flower: %s" % pref) if pref != "" else "Pick a flower",
					func(): placement_tool_requested.emit("floral_preference"),
					"Click this, then click a flower. The selected foragers will only ever visit that species from then on, even walking past a nearer flower of something else -- real bees do this too."))
		Bee.Role.BUILDER:
			orders_column.add_child(_action_button("Build here",
				func(): placement_tool_requested.emit("build_cell"),
				"Click this, then click any open tile -- including ground that has been mined out. Hold Ctrl and keep clicking to queue up several: they are built in the order you click them, and a faint line shows that order while this bee is selected."))
			orders_column.add_child(_action_button("Keep clear",
				func(): placement_tool_requested.emit("keep_clear"),
				"Click this, then click a tile to reserve it as open floor. No comb worker will ever build there, so you can keep a corridor through the comb or a landing area by the entrance. Clicking a reserved tile again releases it. This applies to every comb worker, not just this one, and the reserved tiles show whenever any comb worker is selected."))
			orders_column.add_child(_action_button("Work from here",
				func(): placement_tool_requested.emit("home_cell"),
				"Click this, then click a tile. That tile becomes the selected comb worker's centre of operations: left to itself it fills the space around it outwards in a spiral, rather than always adding to the middle. Applies to this one bee only, even if you have several selected -- use \"Set for all comb workers\" below to change every comb worker at once."))
			orders_column.add_child(_action_button("Set for all comb workers",
				func(): placement_tool_requested.emit("home_cell_all"),
				"Click this, then click a tile. Every comb worker in the colony -- not just the selected ones -- gets that tile as its centre of operations. Use this to redirect the whole team at once; use \"Work from here\" above to give one bee its own spot."))

			# Restocking needs three things chosen, so it gets its own
			# batch of buttons rather than crowding the general orders.
			# T3-2: the keep-full controls appear only with Restocking.
			if first != null and first.architect_mode == "restock" and Availability.mode_query(Roles.COMB_WORKER, "restock", null, Session.progression).available:
				_build_restock_row(first)
		Bee.Role.MINER:
			orders_column.add_child(_action_button("Mine",
				func(): placement_tool_requested.emit("mine_target"),
				"Click this, then click a soil block for the selected miners to dig. Hold Ctrl and keep clicking to queue several: they are dug in the order you click them, and a faint line shows that order while the miner is selected."))
			orders_column.add_child(_action_button("Work from here",
				func(): placement_tool_requested.emit("mine_home"),
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
		UiTheme.bind_color(summary, "font_color", "success")
		orders_column.add_child(summary)

## The backup role and whether a reassignment waits for the current job.
##
## Each of the three controls is offered only where the Challenge has taught
## the thing it acts on (HC-13). Outside a Challenge allowed_role_keys is
## empty, every test below is true and the row reads exactly as it always
## did -- the same convention _apply_cell_popup_gating states. Challenge 1
## used to show the queen both checkboxes from her first frame, before it
## had taught her either idea (Dave, 10 Sep 2026).
var _backup_focus: String = ""

func _build_fallback_row(common_role: int, first) -> void:
	# _secondary_items always leads with "Nothing", so a second entry is
	# what says a real alternative role exists to be reassigned to. Where
	# there is none, "Finish the job first" is a rule about an event that
	# cannot happen yet.
	var secondary_items: Array = _secondary_items()
	var reassignment_offered: bool = secondary_items.size() > 1
	var show_idle_menu: bool = common_role != -1
	# "laying" is the queen role's key in roles.gd::ROLES -- Challenge 1
	# unlocks it at stage 1.16 and Challenge 2 at 2.1, which is exactly
	# where "Lay in plain comb too" starts to mean something.
	var queen_selected: bool = first != null and first.is_queen and common_role == Bee.Role.EGG_LAYER
	var laying_taught: bool = allowed_role_keys.is_empty() or allowed_role_keys.has("laying")
	var show_plain_comb: bool = queen_selected and laying_taught
	var show_order: bool = Bee.work_priorities_owned() and first != null and not first.is_queen and not first.is_drone
	# Nothing to put in it, so no empty labelled row is left behind.
	if not show_idle_menu and not reassignment_offered and not show_plain_comb and not show_order:
		return

	var row := _labelled_row("If idle")
	if show_order:
		_build_backup_order(row)
	elif show_idle_menu:
		var current: int = first.secondary_role if first != null else -1
		row.add_child(_make_role_menu(
			"When idle: %s" % (Roles.label_for(current) if current != -1 else "nothing"),
			"What this bee does instead of standing around whenever it genuinely has no work of its own -- a non-automine miner with no block marked, say, or a nurse with no brood to tend. It drops the backup role and returns to its own the instant real work turns up.",
			secondary_items
		))

	if reassignment_offered:
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
	if show_plain_comb:
		var any_cell_box := CheckBox.new()
		_style_button(any_cell_box)
		any_cell_box.text = "Lay in plain comb too"
		any_cell_box.theme_type_variation = "Small"
		any_cell_box.button_pressed = GameConfig.queen_lays_in_any_cell
		any_cell_box.toggled.connect(func(pressed: bool): queen_lay_any_cell_toggled.emit(pressed))
		row.add_child(_with_info(any_cell_box, "On (the default): once every nursery cell is occupied she lays into any spare undesignated cell, so laying never stalls for want of somewhere to put an egg. Off: she lays only in cells reserved for eggs and waits when they are full. Turn it off for exact control, and be ready to reserve more cells for eggs or she stops laying."))

## WP-3: owned, the single Backup choice becomes the first bee's ordered
## list, with a line saying so when the selection does not agree; changes go
## to every selected bee (orders_zones.gd::_on_backup_order_requested).
func _build_backup_order(row: HFlowContainer) -> void:
	var first: Variant = shown_bees[0] if not shown_bees.is_empty() and is_instance_valid(shown_bees[0]) else null
	if first == null:
		return
	var order: Array = first.backup_list()
	var mixed := false
	for b: Variant in shown_bees:
		if is_instance_valid(b) and not b.is_queen and not b.is_drone and b.backup_list() != order:
			mixed = true
			break
	var column := VBoxContainer.new()
	column.name = "backup_order_column"
	column.add_theme_constant_override("separation", 2)
	var title := Label.new()
	title.text = "Falls back on, in order:"
	title.theme_type_variation = "Small"
	title.tooltip_text = "What each selected bee tries, first to last, when its own job has no work. It drops the backup job and returns to its own the instant real work turns up."
	column.add_child(title)
	if mixed:
		var note := Label.new()
		note.text = "Mixed selection: showing the first bee's order. A change here sets it for all of them."
		note.theme_type_variation = "Tiny"
		note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		note.custom_minimum_size = Vector2(220, 0)
		column.add_child(note)
	var addable: Array = []
	for role: Dictionary in Roles.ROLES:
		if role.id != Roles.QUEEN and role.id != Roles.IDLE and _role_offered(role.id):
			addable.append(role.id)
	var focus := _backup_focus
	_backup_focus = ""
	column.add_child(ColonyPanel.build_backup_editor(order, addable, _on_backup_editor_changed, focus))
	row.add_child(column)

func _on_backup_editor_changed(keys: Array, focus: String) -> void:
	_backup_focus = focus
	backup_order_requested.emit(keys)

## The "when idle" menu, built from the role table so a new role turns
## up here without anyone remembering to add it.
func _secondary_items() -> Array:
	var items: Array = [{"text": "Nothing", "action": func(): secondary_role_requested.emit("none")}]
	for role in Roles.ROLES:
		if role.id == Roles.QUEEN or role.id == Roles.IDLE:
			continue   # neither is a sensible thing to fall back to
		var key: String = role.key
		if not _role_offered(role.id):
			continue   # not taught yet, or its skill not bought
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
	# A bare Button in this file means Body-sized since HC-9 taught the base
	# type to follow Session.text_scale, so every tray control has to say
	# "Small" out loud or it renders 2px larger than its neighbours (HC-13).
	button.theme_type_variation = "Small"
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

## node_name is optional and only given where a fixture needs to address
## this specific menu by a stable path (LAY-6's "change_to_menu") -- label
## text isn't usable for that since _build_fallback_row's call rebuilds its
## menu with a different label ("When idle: <role>") each time.
func _make_role_menu(label: String, tip: String, items: Array, node_name: String = "") -> Control:
	var menu := MenuButton.new()
	if node_name != "":
		menu.name = node_name
	_style_button(menu)
	menu.flat = false # MenuButton defaults to flat, which skips its normal stylebox
	menu.text = label
	# See _current_role_marker: a bare Button/MenuButton is Body-sized, and
	# every other control in the tray is Small (HC-13).
	menu.theme_type_variation = "Small"
	menu.tooltip_text = tip
	var popup := menu.get_popup()
	_theme_popup_on_open(popup)
	for i in range(items.size()):
		popup.add_item(items[i].text, i)
	popup.id_pressed.connect(func(id: int): items[id].action.call())
	return menu

## Identity block: name (starred if a favourite), role, age. Name first --
## this is what turns "Bee 214" into someone the player can recognise. See
## BEE_INDIVIDUALITY_PLAN.md.
func _selection_identity_text(b) -> String:
	var identity := "%s%s — %s" % [
		"Queen " if b.is_queen else "Bee ",
		"" if b.is_queen else str(b.bee_id),
		b.role_name_text(),
	]
	if b.bee_name != "":
		identity = "%s%s\n%s" % ["★ " if b.is_favourite else "", b.bee_name, identity]
	if b.is_queen:
		identity += "\nAge: %.1f days   (does not die of old age)" % b.age_days()
	else:
		identity += "\nAge: %.1f days   Left: %.1f days" % [b.age_days(), b.days_remaining()]
	return identity

func _selection_energy_text(b) -> String:
	return "Energy %d%%\n%s" % [
		int(100.0 * b.energy / max(0.001, GameConfig.energy_capacity)),
		b.carrying_text(),
	]

## Activity block. `instruction_runner` is the Challenge runner when the
## queen is waiting for an instruction, else null; `stuck` is the bee's
## idle_reason() (empty while the runner is waiting).
func _selection_activity_text(b, instruction_runner, stuck: String) -> String:
	var activity: String
	if instruction_runner != null:
		var instruction: String = instruction_runner.current_stage_instruction()
		activity = "Now: waiting for instruction"
		if instruction != "":
			activity += " -- %s" % instruction
	else:
		activity = "Now: %s" % b.task_description()
		if stuck != "":
			activity += "\n%s" % stuck
	if GameConfig.floral_constancy_on and b.role == Bee.Role.FORAGER and b.preferred_species != "":
		activity += "\nPreferred flower: %s" % b.preferred_species
	# the queen's pollen store is the thing that gates egg-laying,
	# so it's worth showing as a running total
	if b.is_queen:
		activity += "\nPollen eaten: %d / %d needed for an egg" % [
			int(b.pollen_eaten), int(GameConfig.egg_pollen_cost),
		]
	if b.is_gyne and not b.is_queen and not b.is_dying:
		var not_ready: String = _gyne_not_ready_reason(b)
		if not_ready != "":
			activity += "\n%s" % not_ready
	return activity

## "trait" is a reserved GDScript word (used for the language's own
## trait/mixin feature), so the local can't be called that even though it
## holds a bee's rolled trait line.
func _selection_trait_text(b) -> String:
	var trait_line: String = b.trait_text()
	# BB-2: what she was raised on, and what it gave her.
	var outcome_line: String = b.brood_outcome_text()
	if outcome_line != "":
		trait_line += ("\n" if trait_line != "" else "") + outcome_line
	if b.bee_fact != "":
		trait_line += ("\n" if trait_line != "" else "") + "\"%s\"" % b.bee_fact
	return trait_line

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
		_set_favourite_star(null)
		_set_summary_cog_kind("")
		bottom_row_changed.emit()
		return
	if shown_bees.size() == 1:
		var b = shown_bees[0]
		_set_favourite_star(b)
		_set_summary_cog_kind("bee")

		identity_label.text = _selection_identity_text(b)
		energy_label.text = _selection_energy_text(b)

		var challenge_runner = main.challenge_runner if main != null else null
		var waiting_for_instruction: bool = (
			challenge_runner != null and challenge_runner.active
			and b.is_queen
			and (b.state == Bee.State.IDLING or b.state == Bee.State.NURSE_IDLE or b.player_driven)
		)
		# If it isn't doing anything, say why. A bee standing still looks
		# identical whatever the reason, and "nothing is happening and I
		# can't tell why" is the worst state to leave a player in.
		var stuck: String = "" if waiting_for_instruction else b.idle_reason()
		if stuck != "":
			UiTheme.bind_color(activity_label, "font_color", "warning")
		else:
			activity_label.add_theme_color_override("font_color", UiTheme.readable_accent(UiTheme.color("accent_nectar")))
		# COL-7: a gyne who can't be sent yet says why, and her send button
		# follows.
		if b.is_gyne and not b.is_queen and not b.is_dying:
			_refresh_gyne_send_button(b)
		activity_label.text = _selection_activity_text(b, challenge_runner if waiting_for_instruction else null, stuck)
		trait_label.text = _selection_trait_text(b)
	else:
		identity_label.text = "%d bees selected" % shown_bees.size()
		energy_label.text = ""
		activity_label.text = ""
		trait_label.text = ""
		_set_favourite_star(null)
		_set_summary_cog_kind("multiple")
	# Both branches set their labels after _set_summary_cog_kind, so the
	# empty-label test runs once here rather than twice above (HC-13).
	_apply_selection_field_visibility()
	_update_command_tray_width()

## Sets the selection panel's width for the current viewport
## (UiLayout.selection_tray_width -- since UI-H, whatever room is left up
## to the command tray's reserved zone, not a fixed per-breakpoint number)
## -- called at build time and again from _on_viewport_size_changed, never
## from content. See _build_selection_panel and the durable rule in
## UI_PLAN.md UI-B.
func _apply_selection_tray_width() -> void:
	var rect := UiLayout.summary_panel_rect(get_viewport().get_visible_rect().size)
	# Width first, then height. Every label in this column autowraps, so its
	# minimum height is only meaningful once it knows how wide it is --
	# measured at the old width, a one-line label reports the height of a
	# column of single words. Same ordering, and the same reason, as
	# _resize_command_tray (Dave, 8 Sep 2026, C-11/C-12).
	if selection_column != null:
		# Cap the column to the space inside the panel's own border and
		# content margins, not the panel's outer width, so its content
		# cannot raise the column's minimum width above what the panel has
		# to give it.
		selection_column.custom_minimum_size.x = maxf(0.0, rect.size.x - UiLayout.panel_chrome().x)
		# soil_summary_row (and, in turn, the mark/clear button rows inside
		# it) sit two and three VBoxContainer/HBoxContainer levels below
		# selection_column and don't inherit its width just from being
		# nested inside it -- each level needs the same explicit floor, or
		# the soil buttons collapse to their own tiny autowrap minimum
		# (see the soil_mark_wrapper/soil_clear_wrapper field comment).
		if soil_summary_row != null:
			soil_summary_row.custom_minimum_size.x = selection_column.custom_minimum_size.x
		if soil_mark_wrapper != null:
			soil_mark_wrapper.custom_minimum_size.x = selection_column.custom_minimum_size.x
		if soil_clear_wrapper != null:
			soil_clear_wrapper.custom_minimum_size.x = selection_column.custom_minimum_size.x
		# soil_mark_btn/soil_clear_btn's own SIZE_EXPAND_FILL (set where
		# they're built) still doesn't claim the row's width on its own --
		# an autowrap Button's minimum size doesn't tell HBoxContainer's
		# stretch pass it wants more, so without this floor it renders at
		# its own tiny autowrap minimum even once the row around it is the
		# full 424px above. Floored to the row's width minus the info
		# badge and its separation (UI.with_info), not a fixed number, so
		# it still shrinks -- and still wraps -- at a narrow viewport.
		var soil_button_floor: float = maxf(0.0, selection_column.custom_minimum_size.x - UI.BADGE_SIZE - 3.0)
		if soil_mark_btn != null:
			soil_mark_btn.custom_minimum_size.x = soil_button_floor
		if soil_clear_btn != null:
			soil_clear_btn.custom_minimum_size.x = soil_button_floor
	_match_summary_header_button_heights()
	UiPanelLayout.apply(selection_panel, null, rect, UiLayout.BOTTOM_ROW_MARGIN)

## The star and the cog are one control pair, so they take one height: the
## taller of the two minimums, given to both. SUMMARY_HEADER_BUTTON_SIZE is
## the floor and not the answer on its own -- "☆" and "⚙" resolve to
## different fallback fonts on some systems, and a fallback's metrics can
## ask for more height than the floor, which is how the star came out
## shorter than the cog beside it (Dave, 10 Sep 2026, C-35). Both are reset
## to the floor first so a smaller text scale can bring the pair back down
## rather than ratcheting it up. Lives here because _apply_selection_tray_width
## is already what runs at build time, on a viewport change and, since
## HC-13, whenever the panel's visible content changes.
func _match_summary_header_button_heights() -> void:
	if favourite_star_btn == null or selection_cog_btn == null:
		return
	favourite_star_btn.custom_minimum_size.y = SUMMARY_HEADER_BUTTON_SIZE.y
	selection_cog_btn.custom_minimum_size.y = SUMMARY_HEADER_BUTTON_SIZE.y
	var tallest: float = maxf(
		favourite_star_btn.get_combined_minimum_size().y,
		selection_cog_btn.get_combined_minimum_size().y)
	favourite_star_btn.custom_minimum_size.y = tallest
	selection_cog_btn.custom_minimum_size.y = tallest

## The one statement of what the command tray's Job/Focus/Orders columns
## should each measure: a flat third of the inner width, less this column's
## share of the two separations between them. Both _update_command_tray_width
## and tests/fixtures/layout_panels.json's 2px even_columns tolerance are
## checking this same number, so they cannot drift apart the way the old
## 80px tolerance let them (Dave, 10 Sep 2026: pixel-equal columns,
## unconditionally -- no "only when they fit" fallback).
func _tray_column_share(inner_width: float) -> float:
	return floor((inner_width - 2.0 * TRAY_COLUMN_SEPARATION) / 3.0)

## Splits `inner` evenly across `wrappers` with a TRAY_COLUMN_SEPARATION gap
## between each. Used for the cell popup's action columns, whose count
## varies with what the selected cell shows; the command tray's own
## fixed three-way split reads _tray_column_share directly instead (see
## _update_command_tray_width) because it is never asked to divide by
## anything but three.
func _apply_even_column_widths(wrappers: Array) -> void:
	# A hidden wrapper (an empty cell-popup column) must not claim a share
	# of the width it never draws into, or the visible columns are left
	# narrower than the space they actually have.
	var visible_wrappers := wrappers.filter(func(w): return w.visible)
	if visible_wrappers.is_empty():
		return
	# Measured against UiLayout.panel_chrome(), the same function
	# ui_panel_layout.gd::apply() budgets the scroll from, so the even-width
	# split and the scroll budget cannot disagree by two border widths.
	var inner: float = UiLayout.command_tray_width(get_viewport().get_visible_rect().size.x) - UiLayout.panel_chrome().x
	var count := visible_wrappers.size()
	var width: float = floor((inner - float(count - 1) * TRAY_COLUMN_SEPARATION) / float(count))
	for wrapper in visible_wrappers:
		wrapper.custom_minimum_size.x = width

## The command tray is centred at half the viewport until its two side bands
## reach their minimum widths. The summary panel and Gallerin bubble derive
## their widths from that same edge, preserving their shared 16px gaps.
## Job/Focus/Orders divide the tray's inner width into three equal thirds via
## _tray_column_share, every wrapper's minimum set to the same number so the
## GridContainer's SIZE_EXPAND_FILL wrappers render at that width rather than
## each other's natural content size (which is what LAY-6 measured as
## 170/100/127px, Dave, C-18, 9 Sep 2026). The wrapper's own visibility is
## never toggled -- _rebuild_role_controls hides its header/content instead
## -- so an empty column still holds its GridContainer slot and its third
## of the width, rather than the remaining columns shifting sideways as the
## selection changes.
func _update_command_tray_width() -> void:
	if command_tray == null or not command_tray.visible:
		return
	var viewport_width: float = get_viewport().get_visible_rect().size.x
	# Position the tray's explicit centred edge here so it updates on every
	# viewport resize; ui_panel_layout.gd::apply() owns the width itself.
	command_tray.offset_left = UiLayout.command_tray_left_edge(viewport_width)
	command_columns.custom_minimum_size.x = 0.0
	var inner: float = UiLayout.command_tray_width(viewport_width) - UiLayout.panel_chrome().x
	var column_width: float = _tray_column_share(inner)
	for wrapper in [job_column_wrapper, focus_column_wrapper, orders_column_wrapper]:
		wrapper.custom_minimum_size.x = column_width
	if cell_primary_columns != null:
		cell_primary_columns.custom_minimum_size.x = 0.0
		_apply_even_column_widths(cell_primary_columns.get_children())
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
	_command_tray_resettle_generation += 1
	_resettle_command_tray(_command_tray_resettle_generation, NAN, 0, 0)

## HC-8 -- content.get_combined_minimum_size().y is not settled on the frame
## its content last changed. Driving the headless scenario runner through a
## long selection, a short one and a re-toggle of `More…` showed it goes
## further than a single stale frame: a reselection while `More…` is
## sticky-open frees the old role's rows (queue_free, itself deferred) while
## the new rows' own nested HFlowContainers each need their own deferred
## sort pass to report a true wrapped height, so the measured minimum kept
## changing for several passes after the rebuild (one traced run: 213 ->
## 291 -> 295 -> 268 for one selection, 386 -> 444 for the next). A single
## extra apply() would still have frozen the tray short of its content in
## the worst case this found; re-applying until several consecutive reads
## agree closes most of that gap. It is not a complete fix -- Dave, 10 Sep
## 2026, chose to ship this bounded improvement over the open-ended cost of
## chasing an exact settle point through Godot's own layout-notification
## timing, so a residual few pixels of drift can still remain in a case this
## slice's check does not cover. Re-applying is the one place this is
## corrected, rather than at each caller. The generation guard stops a
## reselection that lands mid-chain from later being overwritten by the
## superseded chain it interrupted, once that older chain's own reads
## finally settle.
const COMMAND_TRAY_SETTLE_STABLE_STREAK := 4
const COMMAND_TRAY_SETTLE_PASS_LIMIT := 20

func _resettle_command_tray(generation: int, previous_content_min_y: float, stable_streak: int, pass_count: int) -> void:
	if generation != _command_tray_resettle_generation:
		return
	if command_tray == null or not command_tray.visible:
		return
	_apply_command_tray_rect()
	var content_min_y := command_content.get_combined_minimum_size().y
	var streak: int = (stable_streak + 1) if content_min_y == previous_content_min_y else 0
	if pass_count < COMMAND_TRAY_SETTLE_PASS_LIMIT and streak < COMMAND_TRAY_SETTLE_STABLE_STREAK:
		call_deferred("_resettle_command_tray", generation, content_min_y, streak, pass_count + 1)

## One application of the tray's rectangle at the content's current
## minimum height -- what each settle pass and each content minimum-size
## change does.
func _apply_command_tray_rect() -> void:
	command_scroll.custom_minimum_size.y = 0.0
	var rect := UiLayout.command_tray_rect(get_viewport().get_visible_rect().size)
	UiPanelLayout.apply(command_tray, command_scroll, rect, UiLayout.BOTTOM_ROW_MARGIN)

## SR-4 -- every pass of the settle chain above runs inside the one
## deferred-call flush that started it (call_deferred from a deferred call
## lands in the same flush), so its "four reads agree" streak can complete
## before the content has finished re-wrapping. After a resize to 800x600
## the content's minimum height went 111 -> 233 inside that flush, the
## chain stopped at 233, and the autowrapped rows then grew it to 271 on
## the same frame with nothing left to re-apply the tray: 38px of content
## below the tray's bottom edge. Godot emits minimum_size_changed for each
## of those later changes, so re-applying here keeps the tray matched to
## its content whenever that changes, whichever pass of the chain is
## running or not. apply() only moves the tray's own offsets and the
## scroll's minimum height, which never alter the content's width, so this
## cannot feed back into another change of its own.
func _on_command_content_minimum_size_changed() -> void:
	if command_tray == null or not command_tray.visible:
		return
	_apply_command_tray_rect()

## Not a stage gate: Session.winter_coming decides it (saving.gd,
## year_winter.gd), so it stays outside Availability.UI_GATES.
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

## See the `allowed_role_keys` field comment. Rebuilds the selection
## panel immediately so a stage unlocking a new role shows it without
## waiting for the next unrelated selection change.
func set_allowed_role_keys(keys: Array) -> void:
	allowed_role_keys = keys
	refresh_role_gating()

## BS-3: whether the Job row, the "when idle" menu and the Raises row may
## offer `role_id`: Availability.role_query over the stage gate and the run's
## skills. A role the stage has taught but whose skill is not bought yet
## stays hidden until it is.
func _role_offered(role_id: int, bee = null) -> bool:
	return Availability.role_query(role_id, _stage_gate, Session.progression, bee).available

## Re-applies role availability to whatever is open: the selection's role
## rows and the cell popup's Raises row. Called on a stage change and by the
## skill tree after a purchase, never per frame.
func refresh_role_gating() -> void:
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
	if active_cell != null and is_instance_valid(active_cell) and cell_group != null and cell_group.visible:
		_apply_cell_popup_gating()

## See the allowed_designation_keys field comment. Re-applies immediately
## if the cell popup is currently open, same as set_allowed_role_keys
## does for the bee-selection panel.
func set_allowed_designation_keys(keys: Array) -> void:
	allowed_designation_keys = keys
	if active_cell != null and is_instance_valid(active_cell) and cell_group != null and cell_group.visible:
		_apply_cell_popup_gating()

## Every run offers the queen a direct build button; Challenge 1's 1.3 replaces the usual "assign Comb worker, then click a
## spot" flow with one direct button in the queen's own panel -- see
## TUTORIAL_PLAN.md. Only ever shown for the queen, one bee selected.
## Not a stage gate: it follows the selection, not
## a stage_gate key, so it stays outside Availability.UI_GATES.
func set_queen_build_button_visible(value: bool) -> void:
	show_queen_build_button = value
	if not shown_bees.is_empty():
		_rebuild_role_controls(shown_bees)

# --- stage gates --------------------------------------------------

## The one entry point for stage-gated HUD visibility (F2s). Walks
## Availability.UI_GATES: each registered control is shown or hidden whole,
## and the designation keys whose gate is open become the cell popup's
## allow-list. A control not built yet is skipped and picks its state up
## when it registers. Called on stage entry and on
## stage_gate.unlocked_changed, never per frame.
func apply_gates(stage_gate) -> void:
	_stage_gate = stage_gate
	var designations: Array = []
	for key in Availability.UI_GATES:
		var row: Dictionary = Availability.UI_GATES[key]
		var open: bool = stage_gate.is_unlocked(key)
		for control_name in row.get("controls", []):
			_gate_open[control_name] = open
			_apply_gate_to_control(control_name)
		if open:
			designations.append_array(row.get("designations", []))
	set_allowed_designation_keys(designations)

## Called as each gated control is built. Only a closed gate is applied
## here, so a control built after apply_gates starts hidden if it should be
## and is otherwise left as its builder made it. The control also takes its
## table name as its node name, so a scenario fixture can find it as
## "hud/**/<name>" or "command_tray/**/<name>".
func _register_gated_control(control_name: String, getter: Callable) -> void:
	_gate_controls[control_name] = getter
	var control = getter.call()
	if control != null and is_instance_valid(control):
		control.name = control_name
	if not _is_gate_open(control_name):
		_apply_gate_to_control(control_name)

func _apply_gate_to_control(control_name: String) -> void:
	var getter: Callable = _gate_controls.get(control_name, Callable())
	if not getter.is_valid():
		return
	var control = getter.call()
	if control != null and is_instance_valid(control):
		control.visible = _is_gate_open(control_name)

## For a refresh path that re-sets a gated control's visibility itself.
func _is_gate_open(control_name: String) -> bool:
	return _gate_open.get(control_name, true)
