extends GamePanel
## Foraging ecology plan Slice 1 (FORAGING_ECOLOGY_PLAN.md): a read-only
## window onto the trip-level detail foraging_stats.gd now tracks --
## Overview, Species, Recruitment, exactly the brief's three sections
## and nothing more yet. No heatmap, no patch-memory display -- those
## are explicitly later slices. Pattern copied from colony_panel.gd: a
## code-built PanelContainer, refreshed once a second by year_winter.gd
## while open, closed by default.
##
## Reads only foraging_stats.gd's counters and DiagnosticLog's existing
## event counts -- never scans the bee list itself, same "counters only"
## requirement the brief puts on foraging_stats.gd.

const UI = preload("res://scripts/ui.gd")

var overview_label: Label
var recruitment_label: Label
var species_column: VBoxContainer
var species_empty_label: Label
var gate_hint_label: Label

func _ready() -> void:
	setup_layer("foraging", "foraging_panel")
	build_left_window(340)
	build_scroll_body()

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 3)
	scroll_container.add_child(column)

	var title := Label.new()
	title.text = "Foraging"
	title.theme_type_variation = "Heading"
	column.add_child(title)

	gate_hint_label = Label.new()
	gate_hint_label.text = "Turn on Auto scouting or Auto-recruitment to start scoring trips -- with both off, nothing here has anything to show yet."
	gate_hint_label.theme_type_variation = "Tiny"
	gate_hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	gate_hint_label.custom_minimum_size = Vector2(310, 0)
	gate_hint_label.add_theme_color_override("font_color", UiTheme.color("text_secondary"))
	column.add_child(gate_hint_label)

	var overview := _section(column, "Overview", false)
	overview_label = Label.new()
	overview_label.theme_type_variation = "Small"
	overview_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	overview_label.custom_minimum_size = Vector2(310, 0)
	overview.add_child(overview_label)

	var species_section := _section(column, "Species", false)
	species_column = VBoxContainer.new()
	species_column.add_theme_constant_override("separation", 2)
	species_section.add_child(species_column)
	species_empty_label = Label.new()
	species_empty_label.text = "No scored trips yet."
	species_empty_label.theme_type_variation = "Small"
	species_empty_label.add_theme_color_override("font_color", UiTheme.color("text_secondary"))
	species_column.add_child(species_empty_label)

	var recruitment := _section(column, "Recruitment", false)
	recruitment_label = Label.new()
	recruitment_label.theme_type_variation = "Small"
	recruitment_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	recruitment_label.custom_minimum_size = Vector2(310, 0)
	recruitment.add_child(recruitment_label)
	connect_left_window_reflow()

## Same collapsible-section pattern as colony_panel.gd -- open by default
## here since this panel is short enough not to need remembering state.
func _section(column: VBoxContainer, title: String, open_by_default: bool) -> VBoxContainer:
	var header := Button.new()
	header.alignment = HORIZONTAL_ALIGNMENT_LEFT
	header.theme_type_variation = "Small"
	header.focus_mode = Control.FOCUS_NONE
	for state in ["normal", "hover", "pressed", "focus", "disabled"]:
		header.add_theme_stylebox_override(state, UiTheme.button_stylebox(state))
	column.add_child(header)

	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 2)
	body.visible = open_by_default
	column.add_child(body)

	header.text = "%s  %s" % ["▾" if body.visible else "▸", title]
	header.pressed.connect(func():
		body.visible = not body.visible
		header.text = "%s  %s" % ["▾" if body.visible else "▸", title]
		call_deferred("_apply_left_window_rect")
	)
	return body

## Called once a second by year_winter.gd, same as colony_panel.refresh --
## reads main.foraging_stats plus DiagnosticLog's own running counts.
func refresh(stats: Node) -> void:
	if not panel.visible:
		return

	gate_hint_label.visible = stats.trips_recorded == 0

	var avg_search_flight: float = stats.total_search_flight_seconds / stats.trips_recorded if stats.trips_recorded > 0 else 0.0
	var avg_handling: float = stats.total_handling_seconds / stats.trips_recorded if stats.trips_recorded > 0 else 0.0
	var avg_trip: float = stats.total_trip_seconds / stats.trips_recorded if stats.trips_recorded > 0 else 0.0
	var avg_flowers: float = float(stats.total_flowers_visited) / stats.trips_recorded if stats.trips_recorded > 0 else 0.0
	var empty_rate: float = 100.0 * stats.empty_returns / stats.trips_recorded if stats.trips_recorded > 0 else 0.0

	overview_label.text = "Trips scored: %d\nFlowers visited: %d (avg %.1f/trip)\nAvg trip time: %.0fs -- search+flight %.0fs, handling %.0fs\nEmpty returns: %d (%.0f%%)" % [
		stats.trips_recorded, stats.total_flowers_visited, avg_flowers,
		avg_trip, avg_search_flight, avg_handling,
		stats.empty_returns, empty_rate,
	]

	_rebuild_species(stats.species_breakdown())

	recruitment_label.text = "Recruitment matches: %d\nForagers settled: %d\nScouting settled: %d\nOrientation flights: %d\nForager returns triggered: %d" % [
		DiagnosticLog.event_count("recruitment_match"),
		DiagnosticLog.event_count("forager_settled"),
		DiagnosticLog.event_count("scouting_settled"),
		DiagnosticLog.event_count("orientation_flight"),
		DiagnosticLog.event_count("forager_return"),
	]

## Rebuilt from scratch each refresh, same reasoning as colony_panel's
## favourites/needing-attention lists -- which species have any trips at
## all changes over the run, there's no fixed key set to update in place.
func _rebuild_species(rows: Array) -> void:
	for child in species_column.get_children():
		if child != species_empty_label:
			child.queue_free()

	species_empty_label.visible = rows.is_empty()
	for row in rows:
		var label := Label.new()
		label.theme_type_variation = "Small"
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.custom_minimum_size = Vector2(310, 0)
		var species_name: String = row.species if row.species != "" else "no preference"
		var avg_trip: float = row.trip_seconds / row.trips if row.trips > 0 else 0.0
		var empty_rate: float = 100.0 * row.empty_returns / row.trips if row.trips > 0 else 0.0
		label.text = "%s / %s -- %d trips, %.1f flowers/trip, avg %.0fs/trip, %.0f%% empty" % [
			row.resource_type.capitalize(), species_name, row.trips,
			float(row.flowers_visited) / row.trips if row.trips > 0 else 0.0,
			avg_trip, empty_rate,
		]
		species_column.add_child(label)
