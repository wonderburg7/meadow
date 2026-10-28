extends RefCounted
## Builds the selected bees’ command rows for the HUD.

const UI = preload("res://scripts/ui.gd")
const UiTheme = preload("res://scripts/ui_theme.gd")
const Bee = preload("res://scripts/bee.gd")
const Roles = preload("res://scripts/roles.gd")
const Availability = preload("res://scripts/availability.gd")
const ColonyPanel = preload("res://scripts/colony_panel.gd")

var hud

func _init(owner) -> void:
	hud = owner

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
	_detach_and_free_children(hud.job_column)
	_detach_and_free_children(hud.focus_column)
	_detach_and_free_children(hud.orders_column)
	_detach_and_free_children(hud.more_panel)
	hud.gyne_send_button = null

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

	var show_queen_build_row: bool = hud.show_queen_build_button and bees.size() == 1 and first != null and first.is_queen
	if show_queen_build_row:
		_build_queen_build_row(hud.job_column)
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
	var job_has_content: bool = hud.job_column.get_child_count() > 0
	hud.job_column_header.visible = job_has_content
	hud.job_column.visible = job_has_content
	var focus_has_content: bool = hud.focus_column.get_child_count() > 0
	hud.focus_column_header.visible = focus_has_content
	hud.focus_column.visible = focus_has_content
	var orders_has_content: bool = hud.orders_column.get_child_count() > 0
	hud.orders_column_header.visible = orders_has_content
	hud.orders_column.visible = orders_has_content
	hud.more_button.visible = hud.more_panel.get_child_count() > 0
	hud.more_button.button_pressed = hud.more_button.visible and hud.more_panel_open
	hud.more_panel.visible = hud.more_button.button_pressed
	hud._update_command_tray_width()

## Every run -- see set_queen_build_button_visible. It is a primary
## Job-column action so the manual placement lesson never hides behind More….
func _build_queen_build_row(column: VBoxContainer) -> void:
	var button := Button.new()
	hud._style_button(button)
	button.text = "Build cell"
	button.custom_minimum_size = Vector2(0, 26)
	button.theme_type_variation = "Small"
	button.pressed.connect(func(): hud.placement_tool_requested.emit("queen_build_cell"))
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
	hud._style_button(button)
	button.text = "Follow bee"
	button.theme_type_variation = "Small"
	button.focus_mode = Control.FOCUS_NONE
	button.toggle_mode = true
	button.toggled.connect(func(pressed: bool): hud.follow_bee_toggled.emit(first, pressed))
	hud.more_panel.add_child(hud._with_info(button, "Keeps the camera centred on this bee as it moves. Switches off the moment you select something else."))

## Job: what the selection is, lit up, plus one dropdown holding every
## role it could be switched to. Builds into the Job column, not
## more_panel, per Dave's 22 Aug three-column call.
func _build_job_row(common_role: int, any_queen: bool, queen_bee = null) -> void:
	var row := _column_row(hud.job_column)
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
	elif hud.allowed_role_keys.is_empty() or hud.allowed_role_keys.has(Roles.key_for(common_role)):
		row.add_child(_current_role_marker(Roles.label_for(common_role)))

	var items: Array = []
	for role in Roles.ROLES:
		if role.id == common_role:
			continue                       # already doing it
		if role.id == Roles.QUEEN and not any_queen:
			continue                       # queen only
		var key: String = role.key
		if not hud._role_offered(role.id, queen_bee):
			continue                       # not taught yet, or its skill not bought (the queen's free roles aside)
		items.append({
			"text": role.label,
			"action": func(): hud.role_requested.emit(key),
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
		if not hud.allowed_mode_keys.is_empty() and not hud.allowed_mode_keys.has(gate_key):
			continue
		# BB-1: Fermenting is offered only once Bee bread is owned. T2-12: the
		# Miner's "Dig on its own" waits for Automation the same way.
		# T3-2: Stocking likewise waits for Restocking.
		if (common_role == Roles.HONEY or common_role == Roles.COMB_WORKER or common_role == Roles.MINER) and not Availability.mode_query(common_role, key, null, Session.progression).available:
			continue
		var current: bool = _mode_is_active(common_role, first, key)
		var command: String = hud.mode_command(common_role, key)
		hud.focus_column.add_child(_toggle_button(
			mode.label, current,
			func(): hud.role_requested.emit(command),
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
	var row := _column_row(hud.focus_column)
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
	if not hud.shown_bees.is_empty():
		_rebuild_role_controls(hud.shown_bees)

## COL-7: no gyne leaves by herself; a single selected gyne is sent from
## here. The button is greyed out until she is ready, and her readout says
## why, as an idle bee's does -- _refresh_selection_text keeps both current
## on its own cadence while the panel is visible, never per frame. The
## press is the only thing that sends her (season.gd::send_gyne).
func _build_gyne_send_row(bees: Array, first) -> void:
	if bees.size() != 1 or first == null or not first.is_gyne or first.is_queen:
		return
	var row := _column_row(hud.focus_column)
	row.name = "gyne_send_row"
	var button := Button.new()
	hud._style_button(button)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.text = "Send her to found a colony"
	button.theme_type_variation = "Small"
	button.pressed.connect(func(): _send_gyne(first))
	hud.gyne_send_button = button
	_refresh_gyne_send_button(first)
	row.add_child(hud._with_info(button, "She leaves the hive for good to found a colony of her own. Sent between late spring and early autumn she finds a mate, counts as sent out and earns genetic points, the most in mid summer. Sent outside that window she finds no mate and is lost, and does not count."))

func _send_gyne(gyne) -> void:
	if hud.main != null and hud.main.season != null:
		hud.main.season.send_gyne(gyne)

## Why the shown gyne can't be sent yet, or "" if she can: season.gd's
## answer, the same one send_gyne checks.
func _gyne_not_ready_reason(gyne) -> String:
	if hud.main == null or hud.main.season == null:
		return "Only a gyne can be sent to found a colony."
	return hud.main.season.gyne_not_ready_reason(gyne)

func _refresh_gyne_send_button(gyne) -> void:
	if hud.gyne_send_button == null or not is_instance_valid(hud.gyne_send_button):
		return
	hud.gyne_send_button.disabled = _gyne_not_ready_reason(gyne) != ""

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
			hud.orders_column.add_child(_action_button("Clear start" if has_start else "Start here",
				func(): hud.placement_tool_requested.emit("forage_start"),
				"Click this, then click a spot in the meadow. The selected foragers head there first on every trip out, so you can split them across different parts of the meadow instead of them all drifting to whichever flower is nearest the entrance."))
			if GameConfig.floral_constancy_on:
				var pref: String = first.preferred_species if first != null else ""
				hud.orders_column.add_child(_action_button(("Flower: %s" % pref) if pref != "" else "Pick a flower",
					func(): hud.placement_tool_requested.emit("floral_preference"),
					"Click this, then click a flower. The selected foragers will only ever visit that species from then on, even walking past a nearer flower of something else -- real bees do this too."))
		Bee.Role.BUILDER:
			hud.orders_column.add_child(_action_button("Build here",
				func(): hud.placement_tool_requested.emit("build_cell"),
				"Click this, then click any open tile -- including ground that has been mined out. Hold Ctrl and keep clicking to queue up several: they are built in the order you click them, and a faint line shows that order while this bee is selected."))
			hud.orders_column.add_child(_action_button("Keep clear",
				func(): hud.placement_tool_requested.emit("keep_clear"),
				"Click this, then click a tile to reserve it as open floor. No comb worker will ever build there, so you can keep a corridor through the comb or a landing area by the entrance. Clicking a reserved tile again releases it. This applies to every comb worker, not just this one, and the reserved tiles show whenever any comb worker is selected."))
			hud.orders_column.add_child(_action_button("Work from here",
				func(): hud.placement_tool_requested.emit("home_cell"),
				"Click this, then click a tile. That tile becomes the selected comb worker's centre of operations: left to itself it fills the space around it outwards in a spiral, rather than always adding to the middle. Applies to this one bee only, even if you have several selected -- use \"Set for all comb workers\" below to change every comb worker at once."))
			hud.orders_column.add_child(_action_button("Set for all comb workers",
				func(): hud.placement_tool_requested.emit("home_cell_all"),
				"Click this, then click a tile. Every comb worker in the colony -- not just the selected ones -- gets that tile as its centre of operations. Use this to redirect the whole team at once; use \"Work from here\" above to give one bee its own spot."))

			# Restocking needs three things chosen, so it gets its own
			# batch of buttons rather than crowding the general orders.
			# T3-2: the keep-full controls appear only with Restocking.
			if first != null and first.architect_mode == "restock" and Availability.mode_query(Roles.COMB_WORKER, "restock", null, Session.progression).available:
				_build_restock_row(first)
		Bee.Role.MINER:
			hud.orders_column.add_child(_action_button("Mine",
				func(): hud.placement_tool_requested.emit("mine_target"),
				"Click this, then click a soil block for the selected miners to dig. Hold Ctrl and keep clicking to queue several: they are dug in the order you click them, and a faint line shows that order while the miner is selected."))
			hud.orders_column.add_child(_action_button("Work from here",
				func(): hud.placement_tool_requested.emit("mine_home"),
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
		hud.orders_column.add_child(_toggle_button(
			resource.capitalize(), current,
			func(): hud.restock_targets_requested.emit(value),
			"Select comb first, then press this. Those cells become the ones this comb worker keeps full of %s, fetching it from elsewhere in the hive whenever they run down. This is how you get a resource to sit *somewhere* -- honey beside the brood before winter, pollen within reach of the nursery -- rather than wherever the foragers happened to drop it." % resource
		))

	hud.orders_column.add_child(_action_button("Only these",
		func(): hud.restock_sources_requested.emit(true),
		"Select comb first, then press this. The comb worker will draw only on those cells when refilling. Use it to point restocking at the outer comb and leave the rest alone."))
	hud.orders_column.add_child(_action_button("Never these",
		func(): hud.restock_sources_requested.emit(false),
		"Select comb first, then press this. The comb worker will never take from those cells. This is what protects a winter store from being redistributed by your own bee."))
	hud.orders_column.add_child(_action_button("Clear orders",
		func(): hud.restock_clear_requested.emit(),
		"Forget this comb worker's restocking orders entirely -- the cells it keeps full, and the sources it may use."))

	if first != null and first.has_restock_orders():
		var summary := Label.new()
		summary.text = "%d cells of %s" % [first.restock_targets.size(), first.restock_resource]
		summary.theme_type_variation = "Small"
		UiTheme.bind_color(summary, "font_color", "success")
		hud.orders_column.add_child(summary)

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
	var laying_taught: bool = hud.allowed_role_keys.is_empty() or hud.allowed_role_keys.has("laying")
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
		hud._style_button(finish_box)
		finish_box.text = "Finish the job first"
		finish_box.theme_type_variation = "Small"
		finish_box.button_pressed = first.finish_task_first if first != null else false
		finish_box.toggled.connect(func(pressed: bool): hud.finish_first_requested.emit(pressed))
		row.add_child(hud._with_info(finish_box, "On: reassigning this bee waits until it has finished what it is doing -- a forager delivers the load it is carrying, a comb worker finishes the cell it is on -- and the new role takes effect the moment it is free. Off: it drops everything and starts immediately."))

	# The queen's own laying rule sits here rather than in its own row --
	# it is a "what does she do when she can't lay" question, which is
	# the same question this row is about.
	if show_plain_comb:
		var any_cell_box := CheckBox.new()
		hud._style_button(any_cell_box)
		any_cell_box.text = "Lay in plain comb too"
		any_cell_box.theme_type_variation = "Small"
		any_cell_box.button_pressed = GameConfig.queen_lays_in_any_cell
		any_cell_box.toggled.connect(func(pressed: bool): hud.queen_lay_any_cell_toggled.emit(pressed))
		row.add_child(hud._with_info(any_cell_box, "On (the default): once every nursery cell is occupied she lays into any spare undesignated cell, so laying never stalls for want of somewhere to put an egg. Off: she lays only in cells reserved for eggs and waits when they are full. Turn it off for exact control, and be ready to reserve more cells for eggs or she stops laying."))

## WP-3: owned, the single Backup choice becomes the first bee's ordered
## list, with a line saying so when the selection does not agree; changes go
## to every selected bee (orders_zones.gd::_on_backup_order_requested).
func _build_backup_order(row: HFlowContainer) -> void:
	var first: Variant = hud.shown_bees[0] if not hud.shown_bees.is_empty() and is_instance_valid(hud.shown_bees[0]) else null
	if first == null:
		return
	var order: Array = first.backup_list()
	var mixed := false
	for b: Variant in hud.shown_bees:
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
		if role.id != Roles.QUEEN and role.id != Roles.IDLE and hud._role_offered(role.id):
			addable.append(role.id)
	var focus := _backup_focus
	_backup_focus = ""
	column.add_child(ColonyPanel.build_backup_editor(order, addable, _on_backup_editor_changed, focus))
	row.add_child(column)

func _on_backup_editor_changed(keys: Array, focus: String) -> void:
	_backup_focus = focus
	hud.backup_order_requested.emit(keys)

## The "when idle" menu, built from the role table so a new role turns
## up here without anyone remembering to add it.
func _secondary_items() -> Array:
	var items: Array = [{"text": "Nothing", "action": func(): hud.secondary_role_requested.emit("none")}]
	for role in Roles.ROLES:
		if role.id == Roles.QUEEN or role.id == Roles.IDLE:
			continue   # neither is a sensible thing to fall back to
		var key: String = role.key
		if not hud._role_offered(role.id):
			continue   # not taught yet, or its skill not bought
		items.append({"text": role.label, "action": func(): hud.secondary_role_requested.emit(key)})
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
	hud.more_panel.add_child(row)

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
	hud._style_button(button)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.text = label
	button.theme_type_variation = "Small"
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(action)
	if is_current:
		UI.mark_as_current(button)
	return hud._with_info(button, tip)

func _action_button(label: String, action: Callable, tip: String) -> Control:
	var button := Button.new()
	hud._style_button(button)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.text = label
	button.theme_type_variation = "Small"
	button.pressed.connect(action)
	return hud._with_info(button, tip)

func _current_role_marker(label: String) -> Control:
	var button := Button.new()
	hud._style_button(button)
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
	hud._style_button(menu)
	menu.flat = false # MenuButton defaults to flat, which skips its normal stylebox
	menu.text = label
	# See _current_role_marker: a bare Button/MenuButton is Body-sized, and
	# every other control in the tray is Small (HC-13).
	menu.theme_type_variation = "Small"
	menu.tooltip_text = tip
	var popup := menu.get_popup()
	hud._theme_popup_on_open(popup)
	for i in range(items.size()):
		popup.add_item(items[i].text, i)
	popup.id_pressed.connect(func(id: int): items[id].action.call())
	return menu

