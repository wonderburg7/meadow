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

var main: Node2D

func _winter_forecast() -> Dictionary:
	var bees: int = get_tree().get_nodes_in_group("bees").size()
	var seconds_of_winter: float = GameConfig.winter_length_days * GameConfig.seconds_per_day
	var required: float = (
		bees * GameConfig.energy_burn_rate * GameConfig.winter_burn_factor * seconds_of_winter
	)
	var held: float = (
		main.hive.total("nectar") + main.hive.total_honey() * GameConfig.honey_energy_factor
	)
	var days_left: float = max(0.0, Session.winter_starts_day - main.day)
	return {
		"bees": bees,
		"required_energy": required,
		"held_energy": held,
		"days_left": days_left,
	}

## Part of main.gd's public surface -- debug_panel.gd calls
## `worlds[0].begin_winter_countdown()`.
func begin_winter_countdown() -> void:
	var level: Dictionary = main.Levels.LEVELS.get(Session.starting_level, {})
	if not level.get("winter", true):
		return
	Session.winter_coming = true
	Session.winter_starts_day = main.day + GameConfig.winter_countdown_days
	main.winter_panel.open()
	main.hud.set_winter_button_visible(true)
	main.hud.show_warning(
		"Winter will arrive on day %d. The forecast in the top right shows what the colony will need to last it out, and how far short it is. Every bee you add between now and then is another mouth to feed through it."
		% int(Session.winter_starts_day)
	)

func _refresh_winter() -> void:
	if not Session.winter_coming:
		return
	var forecast = _winter_forecast()
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
		_refresh_panels(bees)
		Perf.end("signals")
		return

	var lines: Array = []

	var starving = 0
	var hungry = 0
	var foragers = 0
	var nurses = 0
	var comb_workers = 0
	for b in bees:
		if b.energy < GameConfig.energy_capacity * 0.15:
			starving += 1
		elif b.energy < GameConfig.energy_capacity * GameConfig.low_energy_warning_level:
			hungry += 1
		match b.role:
			main.Bee.Role.FORAGER:
				foragers += 1
			main.Bee.Role.NURSERY:
				nurses += 1
			main.Bee.Role.BUILDER:
				comb_workers += 1

	var hungry_brood = 0
	var dead_cells = 0
	var free_cells = 0
	for cell in main.hive.cells:
		if not is_instance_valid(cell):
			continue
		if cell.needs_cleaning():
			dead_cells += 1
		elif cell.content_type == "brood" and cell.brood_fed_seconds <= 0.0:
			hungry_brood += 1
		elif cell.is_empty() and not cell.keep_empty:
			free_cells += 1

	if starving > 0:
		lines.append(["%d bees are about to starve" % starving, 2, "starving"])
	if hungry_brood > 0:
		lines.append(["%d larvae are going hungry" % hungry_brood, 2, "hungry_brood"])
	if dead_cells > 0:
		lines.append(["%d cells blocked by dead larvae" % dead_cells, 2, "dead_cells"])
	if main.day >= int(GameConfig.pollen_warning_first_day) and main.hive.total("pollen") < GameConfig.egg_pollen_cost * 0.5:
		lines.append(["Almost no pollen — the queen cannot lay", 2])
	if main.hive.total("nectar") < 40.0 and main.hive.total_honey() < 10.0:
		lines.append(["Food is running out", 2])
	if nurses == 0 and main.hive.cells_holding("brood").size() > 0:
		lines.append(["No nurses — brood will not develop at all", 2, ""])
	if free_cells == 0:
		lines.append(["No free cells — nowhere to store or lay", 1])
	if hungry > 0:
		lines.append(["%d bees running low on energy" % hungry, 1, "hungry"])
	if foragers == 0:
		lines.append(["No foragers — nothing is coming in", 1, ""])
	if comb_workers == 0 and dead_cells > 0:
		lines.append(["No comb workers to clear the blocked cells", 1, "dead_cells"])
	if Session.rain_intensity > GameConfig.rain_forage_limit:
		lines.append(["Raining hard — foragers are grounded", 1])
	elif Session.rain_intensity > 0.05:
		lines.append(["Raining — nectar is watered down and flying costs more", 0])

	main.hud.update_signals(lines)
	_refresh_panels(bees)
	Perf.end("signals")

func _refresh_panels(bees: Array) -> void:
	var counts = main._role_counts()
	var energy_share = 0.0
	for b in bees:
		energy_share += clampf(b.energy / max(0.001, GameConfig.energy_capacity), 0.0, 1.0)

	var brood_count = 0
	var gyne_count = 0
	var hungry_brood = 0
	var free_cells = 0
	for cell in main.hive.cells:
		if not is_instance_valid(cell):
			continue
		if cell.content_type == "brood":
			brood_count += 1
			if cell.brood_is_gyne:
				gyne_count += 1
			if cell.brood_fed_seconds <= 0.0:
				hungry_brood += 1
		elif cell.is_empty() and not cell.keep_empty:
			free_cells += 1

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

	if main.colony_panel.is_open():
		main.colony_panel.refresh(counts, main.hud.corner_texts, main.history_samples)

	if main.nursery_panel.is_open() or _nursery_stat_pinned():
		main.nursery_panel.refresh(
			main.hive.zone_summary(), counts, _emergence_counts(), GameConfig.emergence_window_seconds
		)
		for key in main.nursery_panel.corner_texts.keys():
			main.hud.corner_texts[key] = main.nursery_panel.corner_texts[key]
		main.hud.refresh_corner()
	main.orders_zones._apply_zone_glow()
	_refresh_winter()

func _toggle_panel(panel: CanvasLayer) -> void:
	if panel == main.nursery_panel:
		_on_nursery_window_requested()
		return
	if main.nursery_panel.is_open():
		main.nursery_panel.close()
	panel.toggle()

func _on_nursery_window_requested() -> void:
	if main.nursery_panel.is_open():
		main.nursery_panel.close()
		return
	if main.colony_panel.is_open():
		main.colony_panel.toggle()
	main.nursery_panel.open()
	if not main.in_hive_view:
		main.in_hive_view = true
	main.camera_view._apply_view()
	main.nursery_panel.refresh(
		main.hive.zone_summary(),
		main._role_counts(),
		_emergence_counts(),
		GameConfig.emergence_window_seconds
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
