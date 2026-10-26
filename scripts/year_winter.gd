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
const Conditions = preload("res://scripts/conditions.gd")
const ShortTermGoals = preload("res://scripts/short_term_goals.gd")
## SG-2: the resources whose daily income the short-term goals read, each
## sampled at the day boundary by main.gd::_sample_day_stores.
const GOAL_INCOME_RESOURCES := ["nectar", "pollen", "honey"]

var main: Node2D

## COL-7: season.gd's gyne_lost drives _on_gyne_lost's notice. main.gd wires
## season's other signals as it builds it, after this node, so this one is
## connected once main._ready has finished.
func _ready() -> void:
	_connect_season.call_deferred()

func _connect_season() -> void:
	if main == null or main.season == null:
		return
	if not main.season.gyne_lost.is_connected(_on_gyne_lost):
		main.season.gyne_lost.connect(_on_gyne_lost)

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
	var forecast: Dictionary = _winter_forecast(bees_count)
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

## COL-7: in a Colony Run the notice names the genetic points she earned,
## today's (season.gd::send_gyne added them just before this fired), and
## the run's total.
func _on_gyne_released(total: int) -> void:
	var text: String = "A gyne has left to found a colony of her own. That is %d away this run — the only thing a season is really measured in." % total
	var milestones: Variant = main.colony_milestones
	if milestones != null and milestones.applies():
		text += " She earned %d genetic points, %d this run." % [
			main.season.genetic_points_today(), milestones.genetic_points,
		]
	main.hud.show_warning(text)
	main._update_population_readout()

## COL-7: a gyne sent outside the mating window.
func _on_gyne_lost() -> void:
	main.hud.show_warning(
		"A gyne has left, but outside the mating season, which runs from late spring to early autumn, she found no mate. She does not count as sent out, and earns no genetic points."
	)
	main._update_population_readout()

func _on_signal_clicked(action: String) -> void:
	match action:
		"starving":
			_select_bees_where(func(b: Node2D) -> bool: return b.energy < GameConfig.energy_capacity * minf(GameConfig.starving_energy_level, GameConfig.low_energy_warning_level))
		"hungry":
			_select_bees_where(func(b: Node2D) -> bool: return b.energy < GameConfig.energy_capacity * GameConfig.low_energy_warning_level)
		"hungry_brood":
			_focus_cells(func(c: Polygon2D) -> bool: return c.content_type == "brood" and c.brood_fed_seconds <= 0.0)
		"dead_cells":
			_focus_cells(func(c: Polygon2D) -> bool: return c.needs_cleaning())

func _select_bees_where(test: Callable) -> void:
	for b: Variant in main.selected_bees:
		if is_instance_valid(b):
			b.set_selected(false)
	main.selected_bees.clear()
	for b: Node in get_tree().get_nodes_in_group("bees"):
		if is_instance_valid(b) and test.call(b):
			b.set_selected(true)
			main.selected_bees.append(b)
	main.hud.update_selection(main.selected_bees)
	if not main.selected_bees.is_empty():
		main.camera_view._active_camera().position = main.selected_bees[0].global_position

func _focus_cells(test: Callable) -> void:
	var found: Array = []
	for cell: Variant in main.hive.cells:
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
	for key: Variant in Session.pinned_stats:
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
	var counts: Dictionary = {}
	for entry: Variant in main.emergence_log:
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
	main.gallerin_panel.update_guidance_facts(facts)

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

	# A 4th element, where present, is a category used to sort a signal into
	# the Colony/Nursery drawers' "needing attention" blocks. The 3rd element
	# is the corner-strip click action; the catalogue preserves their distinct
	# meanings and the optional array shape HUD already consumes.
	var lines := ProblemMessages.signal_lines({
		"bees": bees, "queen": main.queen, "day": main.day,
		"starving": facts.starving, "hungry": facts.hungry,
		"waiting_for_work": facts.waiting_for_work,
		"travelling_for_work": facts.travelling_for_work,
		"no_available_work": facts.no_available_work,
		"foragers": facts.foragers, "nurses": facts.nurses,
		"comb_workers": facts.comb_workers, "hungry_brood": facts.hungry_brood,
		"free_cells": facts.free_cells, "dead_cells": facts.blocked_cells,
		"brood_cells": facts.brood_cells,
		"blocked_cells": facts.blocked_cells, "blocked_work": facts.blocked_work,
		"missing_nurse_workforce": facts.missing_nurse_workforce,
		"missing_comb_workforce": facts.missing_comb_workforce,
		"missing_required_workforce": facts.missing_required_workforce,
		"pollen": main.hive.total("pollen"), "nectar": main.hive.total("nectar"),
		"honey": main.hive.total_honey(), "rain_intensity": Session.rain_intensity,
	})

	main.hud.update_signals(lines)
	_refresh_short_term_goals(facts)
	_refresh_panels(bees, facts, counts)
	Perf.end("signals")

## SG-2 (plans/now/short-term-goals.md): offers, advances and pays the
## short-term goals, on this one-second refresh and never per frame, in a
## Colony Run or a Scenario. A Challenge keeps its own stage goals: the early
## return above covers a running one, and the level check one that has
## finished. Every added fact is read from its one authority in conditions.gd.
## A resource whose one-day window is not full yet is left out of both income
## maps, which short_term_goals.gd reads as unknown rather than zero. The
## state is main's; this file holds none.
func _refresh_short_term_goals(facts: Dictionary) -> void:
	if Session.starting_level in [1, 2]:
		return
	var goal_facts: Dictionary = facts.duplicate()
	var net: Dictionary = {}
	var gross: Dictionary = {}
	for resource: String in GOAL_INCOME_RESOURCES:
		var income: Dictionary = Conditions.income_window(main, resource, 1)
		if income.is_empty():
			continue
		net[resource] = float(income.net)
		gross[resource] = float(income.collected)
	goal_facts["net_daily_income"] = net
	goal_facts["gross_daily_income"] = gross
	goal_facts["built_cells"] = Conditions.built_cell_count(main)
	goal_facts["winter_coming"] = Session.winter_coming
	goal_facts["winter_here"] = Session.winter_here
	goal_facts["winter_ready"] = Conditions.met(main, {"winter_on_track": true})
	var thresholds := {
		"few_free_cells": int(GameConfig.goal_few_free_cells),
		"many_waiting_bees": int(GameConfig.goal_many_waiting_bees),
		"few_waiting_bees": int(GameConfig.goal_few_waiting_bees),
	}
	var state: Dictionary = main.short_term_goals
	var day: int = main.day
	# 0 means no refresh yet this run: its first is not a day boundary.
	var at_day_change: bool = main.short_term_goal_day != 0 and main.short_term_goal_day != day
	main.short_term_goal_day = day
	ShortTermGoals.withdraw_lapsed(state, goal_facts)
	var offered: Dictionary = state.get("offered", {})
	for id: String in offered.keys():
		var entry: Dictionary = offered[id]
		if not ShortTermGoals.progress(entry, goal_facts, state, day, thresholds, at_day_change).done:
			continue
		var reward: float = ShortTermGoals.finish(state, id, day)
		main.hive.pay_reward(str(entry.resource), reward)
	for entry: Dictionary in ShortTermGoals.available(goal_facts, state, day, thresholds,
			GameConfig.goal_reward_fraction, GameConfig.goal_reward_floor):
		ShortTermGoals.accept(state, entry)

func _refresh_panels(bees: Array, facts: Dictionary, counts: Dictionary) -> void:
	var energy_share: float = 0.0
	for b: Variant in bees:
		energy_share += clampf(b.energy / max(0.001, GameConfig.energy_capacity), 0.0, 1.0)

	# brood_count and gyne_count need the brood cells themselves (for
	# brood_is_gyne), which facts doesn't carry -- hungry_brood and
	# free_cells come from facts instead of a second walk.
	var brood_cells: Array = main.hive.cells_holding("brood")
	var brood_count: int = brood_cells.size()
	var gyne_count: int = 0
	for cell: Variant in brood_cells:
		if cell.brood_is_gyne:
			gyne_count += 1
	var hungry_brood: int = facts.hungry_brood
	var free_cells: int = facts.free_cells

	var mean_energy: float = energy_share / max(1, bees.size())
	var comb_text: String = "Comb — %d cells, %d free · brood %d (%d gynes), %d hungry" % [
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
		for key: Variant in main.nursery_panel.corner_texts.keys():
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
	for b: Variant in bees:
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
	for key: String in ["nectar", "pollen"]:
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
	for window: Node in main.get_tree().get_nodes_in_group("left_window"):
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
