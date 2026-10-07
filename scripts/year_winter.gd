extends Node
## The winter forecast, the season/day readout, the problem-strip signals
## and the panels they feed, and the history/rate sampling behind the
## colony window's plots. Split out of main.gd 14 Aug 2026 -- see
## MAIN_SPLIT_PLAN.md. Holds no state; reads and writes main's fields
## through the `main` reference.
##
## `begin_winter_countdown` is part of main.gd's public surface:
## debug_panel.gd finds main via the "world" group and calls
## `worlds[0].begin_winter_countdown()` directly, so main.gd keeps a
## one-line wrapper for it.

const ProblemMessages = preload("res://scripts/problem_messages.gd")
const ColonyDiagnostics = preload("res://scripts/colony_diagnostics.gd")

var main: Node2D

## COL-6: the bill and the stores are season.gd's, the figures the skipped
## winter is charged with, so the window shows exactly what winter will take.
func _winter_forecast(bees_count: int) -> Dictionary:
	var required: float = main.season.winter_bill(bees_count)
	var held: float = main.season.winter_stores()
	var days_left: float = max(0.0, Session.winter_starts_day - main.day)
	return {
		"bees": bees_count,
		"required_energy": required,
		"held_energy": held,
		"days_left": days_left,
	}

## Part of main.gd's public surface -- debug_panel.gd calls
## `worlds[0].begin_winter_countdown()`.
func begin_winter_countdown() -> void:
	var level: Dictionary = main.Levels.get_level(Session.starting_level)
	if not level.get("winter", true):
		return
	Session.winter_coming = true
	Session.winter_starts_day = main.day + GameConfig.winter_countdown_days
	_close_other_left_windows(main.winter_panel)
	main.winter_panel.open()
	main.hud.set_winter_button_visible(true)
	main.hud.show_warning(
		"Winter will arrive on day %d. The Winter window on the left shows what the colony will need to last it out, and how far short it is. Every bee you add between now and then is another mouth to feed through it."
		% int(Session.winter_starts_day),
		"", 0.0, main.hud.SEVERITY_NOTICE
	)

func _refresh_winter(bees_count: int) -> void:
	if not Session.winter_coming:
		return
	var forecast = _winter_forecast(bees_count)
	main.winter_panel.refresh(forecast)
	main.hud.corner_texts["winter"] = main.winter_panel.corner_text
	main.hud.refresh_corner()

func _season_text() -> String:
	var parts: Array = []
	if Session.winter_here:
		parts.append("Winter, %d days left" % int(max(0.0, Session.winter_ends_day - main.day)))
	elif GameConfig.seasons_on:
		var through: float = main.Flower.season_fraction()
		var season_name: String = "Early season"
		if through > 0.66:
			season_name = "Late season"
		elif through > 0.33:
			season_name = "Midsummer"
		parts.append(season_name)
	if Session.gynes_released > 0:
		parts.append("%d gynes away" % Session.gynes_released)
	return "  ".join(parts)

func _on_winter_started() -> void:
	main.hud.show_warning(
		"Winter has arrived. The foragers are staying in, nothing more is coming from the meadow, and the colony is living on what is in the comb. It lasts %d days."
		% int(GameConfig.winter_length_days)
	)

func _on_winter_survived(losses: int) -> void:
	if losses > 0:
		main.hud.show_warning(
			"Spring. The colony came through the winter, %d bees lighter. Foraging can start again."
			% losses
		)
	else:
		main.hud.show_warning("Spring, and not a bee lost. Foraging can start again.")

func _on_gyne_released(total: int) -> void:
	main.hud.show_warning(
		"A gyne has left to found a colony of her own. That is %d away this run — the only thing a season is really measured in."
		% total
	)
	main._update_population_readout()

func _on_signal_clicked(action: String) -> void:
	match action:
		"starving":
			_select_bees_where(func(b): return b.energy < GameConfig.energy_capacity * 0.15)
		"hungry":
			_select_bees_where(func(b): return b.energy < GameConfig.energy_capacity * GameConfig.low_energy_warning_level)
		"hungry_brood":
			_focus_cells(func(c): return c.content_type == "brood" and c.brood_fed_seconds <= 0.0)
		"dead_cells":
			_focus_cells(func(c): return c.needs_cleaning())

func _select_bees_where(test: Callable) -> void:
	for b in main.selected_bees:
		if is_instance_valid(b):
			b.set_selected(false)
	main.selected_bees.clear()
	for b in get_tree().get_nodes_in_group("bees"):
		if is_instance_valid(b) and test.call(b):
			b.set_selected(true)
			main.selected_bees.append(b)
	main.hud.update_selection(main.selected_bees)
	if not main.selected_bees.is_empty():
		main.camera_view._active_camera().position = main.selected_bees[0].global_position

func _focus_cells(test: Callable) -> void:
	var found: Array = []
	for cell in main.hive.cells:
		if is_instance_valid(cell) and test.call(cell):
			found.append(cell)
	if found.is_empty():
		return
	if not main.in_hive_view:
		main.in_hive_view = true
		main.camera_view._apply_view()
	main.input_selection._select_cells(found, false)
	main.camera_view._active_camera().position = found[0].global_position

func _nursery_stat_pinned() -> bool:
	for key in Session.pinned_stats:
		if str(key).begins_with("nursery_"):
			return true
	return false

func _sample_history(delta: float) -> void:
	main.history_timer -= delta
	if main.history_timer > 0.0:
		return
	main.history_timer = max(1.0, GameConfig.history_sample_seconds)
	_trim_emergence_log()
	main.history_samples.append({
		"t": Session.sim_time,
		"bees": get_tree().get_nodes_in_group("bees").size(),
		"nectar": main.hive.total("nectar"),
		"pollen": main.hive.total("pollen"),
		"honey": main.hive.total_honey(),
	})
	while main.history_samples.size() > int(GameConfig.history_points):
		main.history_samples.pop_front()

func _emergence_counts() -> Dictionary:
	_trim_emergence_log()
	var counts = {}
	for entry in main.emergence_log:
		counts[entry.key] = int(counts.get(entry.key, 0)) + 1
	return counts

func _trim_emergence_log() -> void:
	var cutoff: float = Session.sim_time - GameConfig.emergence_window_seconds
	while not main.emergence_log.is_empty() and float(main.emergence_log[0].t) < cutoff:
		main.emergence_log.pop_front()

func _refresh_signals(delta: float) -> void:
	Perf.begin("signals")
	main.signal_timer -= delta
	if main.signal_timer > 0.0:
		Perf.end("signals")
		return
	main.signal_timer = 1.0

	var bees: Array = get_tree().get_nodes_in_group("bees")
	var counts: Dictionary = main._role_counts()
	var facts: Dictionary = ColonyDiagnostics.compute(main, bees, counts)

	# A Challenge already tells the player what's wrong and what to do
	# about it, one stage at a time, through Dr Gallerin -- this generic
	# strip has no notion of what's been unlocked yet, so it would flag
	# things the tutorial hasn't taught a fix for (no nurses before 2.7,
	# a bee running low while the player is still learning the controls),
	# which cuts against "no lethal pressure, nothing irreversible".
	# Cleared explicitly rather than left showing whatever it last said
	# just before start().
	if main.challenge_runner.active:
		main.hud.update_signals([])
		_refresh_panels(bees, facts, counts)
		Perf.end("signals")
		return

	# Not part of ColonyDiagnostics.compute -- used only here, so left as a
	# single direct read rather than moved.
	var dead_cells: int = main.hive.cells_holding("corpse").size()

	# A 4th element, where present, is a category used to sort a signal into
	# the Colony/Nursery drawers' "needing attention" blocks. The 3rd element
	# is the corner-strip click action; the catalogue preserves their distinct
	# meanings and the optional array shape HUD already consumes.
	var lines := ProblemMessages.signal_lines({
		"bees": bees, "queen": main.queen, "day": main.day,
		"starving": facts.starving, "hungry": facts.hungry,
		"foragers": facts.foragers, "nurses": facts.nurses,
		"comb_workers": facts.comb_workers, "hungry_brood": facts.hungry_brood,
		"free_cells": facts.free_cells, "dead_cells": dead_cells,
		"brood_cells": main.hive.cells_holding("brood").size(),
		"pollen": main.hive.total("pollen"), "nectar": main.hive.total("nectar"),
		"honey": main.hive.total_honey(), "rain_intensity": Session.rain_intensity,
	})

	main.hud.update_signals(lines)
	_refresh_panels(bees, facts, counts)
	Perf.end("signals")

func _refresh_panels(bees: Array, facts: Dictionary, counts: Dictionary) -> void:
	var energy_share = 0.0
	for b in bees:
		energy_share += clampf(b.energy / max(0.001, GameConfig.energy_capacity), 0.0, 1.0)

	# brood_count and gyne_count need the brood cells themselves (for
	# brood_is_gyne), which facts doesn't carry -- hungry_brood and
	# free_cells come from facts instead of a second walk.
	var brood_cells: Array = main.hive.cells_holding("brood")
	var brood_count: int = brood_cells.size()
	var gyne_count = 0
	for cell in brood_cells:
		if cell.brood_is_gyne:
			gyne_count += 1
	var hungry_brood: int = facts.hungry_brood
	var free_cells: int = facts.free_cells

	var mean_energy: float = energy_share / max(1, bees.size())
	var comb_text = "Comb — %d cells, %d free · brood %d (%d gynes), %d hungry" % [
		main.hive.cells.size(), free_cells, brood_count, gyne_count, hungry_brood,
	]
	if main.season != null:
		var health: String = main.season.disease_text()
		if health != "":
			comb_text += "\n%s" % health
	main.hud.update_comb(comb_text)
	main.hud.update_energy(mean_energy)
	_refresh_recruit_gap(bees)

	if main.colony_panel.is_open():
		main.colony_panel.refresh(counts, main.hud.corner_texts, main.history_samples, main.hud.shown_signals)

	if main.foraging_panel.is_open():
		main.foraging_panel.refresh(main.foraging_stats)

	if main.nursery_panel.is_open() or _nursery_stat_pinned():
		main.nursery_panel.refresh(
			main.hive.zone_summary(), counts, _emergence_counts(), GameConfig.emergence_window_seconds,
			main.hive.brood_stage_counts(), main.hud.shown_signals
		)
		for key in main.nursery_panel.corner_texts.keys():
			main.hud.corner_texts[key] = main.nursery_panel.corner_texts[key]
		main.hud.refresh_corner()
	main.orders_zones._apply_zone_glow()
	_refresh_winter(facts.bees_count)

## How many foragers currently sit above the "offer" threshold (mentor-
## eligible) or below the "seek" threshold (would wait at the door hoping
## for one), against how many are actually being judged. Mirrors
## BeeForaging.go_to_exit's own gating exactly -- past recruit_grace_trips,
## and not still mid-scout (a scouting bee always seeks regardless of her
## rate, so she isn't "judged" against the thresholds the way a settled
## forager is) -- so this reads as "what the recruitment logic itself
## would decide right now", not a looser approximation of it. Built to
## answer NEXTSTEPS.md's balance question directly: are the threshold
## numbers realistic against what bees actually collect, and roughly what
## fraction end up on each side.
func _refresh_recruit_gap(bees: Array) -> void:
	if not (GameConfig.scouting_on or GameConfig.auto_recruitment_on):
		main.hud.update_recruit_gap("Recruiting — turn on Auto scouting or Auto-recruitment to see this.")
		return

	var counts: Dictionary = {
		"nectar": {"scored": 0, "above": 0, "below": 0},
		"pollen": {"scored": 0, "above": 0, "below": 0},
	}
	for b in bees:
		if not is_instance_valid(b) or b.role != main.Bee.Role.FORAGER or b.is_scouting:
			continue
		if b.trips_scored < GameConfig.recruit_grace_trips:
			continue
		var bucket: Dictionary = counts[b.resource_type]
		bucket.scored += 1
		var upper: float = GameConfig.recruit_upper_threshold_nectar if b.resource_type == "nectar" else GameConfig.recruit_upper_threshold_pollen
		var lower: float = GameConfig.recruit_lower_threshold_nectar if b.resource_type == "nectar" else GameConfig.recruit_lower_threshold_pollen
		if b.avg_collection_rate > upper:
			bucket.above += 1
		elif b.avg_collection_rate < lower:
			bucket.below += 1

	var parts: Array = []
	for key in ["nectar", "pollen"]:
		var c: Dictionary = counts[key]
		if c.scored == 0:
			parts.append("%s: none scored yet" % key.capitalize())
		else:
			parts.append("%s: %d/%d above offer, %d/%d below seek" % [
				key.capitalize(), c.above, c.scored, c.below, c.scored,
			])
	main.hud.update_recruit_gap("Recruiting — %s" % " · ".join(parts))

func _toggle_panel(panel: GamePanel) -> void:
	if panel == main.nursery_panel:
		_on_nursery_window_requested()
		return
	if panel.is_open():
		panel.close()
		return
	_close_other_left_windows(panel)
	panel.open()

func _close_other_left_windows(opening: GamePanel) -> void:
	for window in main.get_tree().get_nodes_in_group("left_window"):
		if window != opening and window.is_open():
			window.close()

func _on_nursery_window_requested() -> void:
	if main.nursery_panel.is_open():
		main.nursery_panel.close()
		return
	_close_other_left_windows(main.nursery_panel)
	main.nursery_panel.open()
	main.orders_zones._apply_zone_glow()
	main.nursery_panel.refresh(
		main.hive.zone_summary(),
		main._role_counts(),
		_emergence_counts(),
		GameConfig.emergence_window_seconds,
		main.hive.brood_stage_counts(),
		main.hud.shown_signals
	)

func _sample_rates() -> void:
	main.rate_samples.append({
		"t": Session.sim_time,
		"nectar": main.hive.lifetime_nectar_collected,
		"pollen": main.hive.lifetime_pollen_collected,
		"births": main.hive.lifetime_births,
	})
	while main.rate_samples.size() > 7:
		main.rate_samples.pop_front()
	if main.rate_samples.size() < 2:
		return
	var oldest: Dictionary = main.rate_samples[0]
	var newest: Dictionary = main.rate_samples[main.rate_samples.size() - 1]
	var span: float = newest.t - oldest.t
	if span <= 0.0:
		return
	main.hud.update_rates(
		(newest.nectar - oldest.nectar) / span,
		(newest.pollen - oldest.pollen) / span,
		(newest.births - oldest.births) / span,
	)
