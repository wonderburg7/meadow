extends SceneTree
## SG-2 (plans/now/short-term-goals.md): the short-term goals offered,
## finished and paid by the running game, and saved with the run.
##
## Each case builds the real Main scene, paused so nothing simulates on its
## own, then moves the day on by hand: the stores and the lifetime counters
## change the way a day's foraging changes them, main.gd::_sample_day_stores
## takes its day-boundary sample, and year_winter.gd::_refresh_signals -- the
## one-second refresh the game runs -- offers, advances and pays the goals.
##
## colony     -- test_scenarios/sg2_short_term_goals.json's Colony Run: no
##               goal before the income window fills; the pollen goal offered
##               while pollen income is at or below zero, paying a quarter of
##               the day's gross pollen income when a whole day of surplus
##               finishes it; "Lay in honey for winter" finishing days before
##               the countdown's last day while the CR-2 winter milestone
##               waits; offered and finished goals through a save and an
##               in-place restore; a save without the field restoring none.
## challenge1, challenge2 -- the same pollen shortfall offers nothing.

const BOOT_FRAMES := 10
const SCENARIO := "res://test_scenarios/sg2_short_term_goals.json"
## Reads no autoload, so it can be preloaded (as sg1_short_term_goals_test.gd does).
const Goals = preload("res://scripts/short_term_goals.gd")

## Loaded on the first frame: each names an autoload, which a --script
## SceneTree cannot compile against before they exist.
var SaveGame: GDScript
var Levels: GDScript
var Conditions: GDScript
var _cases: Array = ["colony", "challenge1", "challenge2"]
var _case := ""
var _main: Node
var _phase := "boot"
var _frame := 0
var _old_level := 0
var _save_path := ""
var _failures: PackedStringArray = PackedStringArray()


func _process(_delta: float) -> bool:
	_frame += 1
	match _phase:
		"boot":
			SaveGame = load("res://scripts/save_game.gd")
			Levels = load("res://scripts/levels.gd")
			Conditions = load("res://scripts/conditions.gd")
			_old_level = root.get_node("Session").starting_level
			_save_path = "user://sg2_goals_%d.json" % OS.get_process_id()
			_phase = "next"
		"next":
			if _cases.is_empty():
				_finish()
				return true
			_case = _cases.pop_front()
			_start(_case)
		"settle":
			if _frame >= BOOT_FRAMES:
				match _case:
					"colony":
						_colony_case()
					_:
						_challenge_case()
				_free_world()
				_phase = "next"
	return false


func _start(case_name: String) -> void:
	var session: Node = root.get_node("Session")
	session.menu_pending = false
	session.load_pending = false
	session.winter_coming = false
	session.winter_here = false
	session.winter_starts_day = 0.0
	session.winter_ends_day = 0.0
	if case_name == "colony":
		var level: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(SCENARIO))
		level.erase("random_seed")
		Levels.scenario_override = level
		session.starting_level = Levels.SCENARIO_LEVEL_ID
	else:
		Levels.scenario_override = {}
		session.starting_level = 1 if case_name == "challenge1" else 2
	paused = true
	_main = load("res://scenes/Main.tscn").instantiate()
	root.add_child(_main)
	current_scene = _main
	_frame = 0
	_phase = "settle"


func _free_world() -> void:
	if is_instance_valid(_main):
		_main.queue_free()
	_main = null
	current_scene = null

# --- the day, moved on by hand ----------------------------------------

## One day boundary: what came in over the day, then the boundary sample
## main.gd takes before day_changed.
func _next_day(pollen_in: float, pollen_kept: float, honey_made: float = 0.0) -> void:
	_main.hive.record_collection("pollen", pollen_in)
	_main.hive.record_collection("honey", honey_made)
	if pollen_kept > 0.0:
		_check(is_equal_approx(_main.hive.deposit("pollen", pollen_kept), pollen_kept), "the comb took the day's pollen")
	_main.day += 1
	_main._sample_day_stores()


## The game's own one-second refresh, run now.
func _refresh() -> void:
	_main.signal_timer = 0.0
	_main.year_winter._refresh_signals(0.01)


func _offered() -> Dictionary:
	return _main.short_term_goals.get("offered", {})


func _finished() -> Dictionary:
	return _main.short_term_goals.get("finished", {})

# --- the Colony Run -------------------------------------------------

func _colony_case() -> void:
	_main.day_store_totals.clear()
	_main.short_term_goals = {}
	_main._sample_day_stores()
	_refresh()
	_check(_offered().is_empty(), "no goal is offered before a day's income is known")

	# A day on which 40 pollen came in and none of it stayed: no pollen income.
	_next_day(40.0, 0.0)
	var income: Dictionary = Conditions.income_window(_main, "pollen", 1)
	_check(not income.is_empty() and float(income.net) <= 0.0 and is_equal_approx(float(income.collected), 40.0),
		"the day's pollen income reads net %s, gross %s" % [income.get("net"), income.get("collected")])
	_refresh()
	_check(_offered().has("pollen_surplus"), "the pollen goal is offered with no pollen income (offered: %s)" % [_offered().keys()])
	if not _offered().has("pollen_surplus"):
		return
	var reward: float = float(_offered().pollen_surplus.reward)
	_check(is_equal_approx(reward, 0.25 * 40.0), "the pollen goal pays a quarter of the day's gross income (%s)" % reward)

	# A day of surplus starts the whole-day clock; the next boundary with the
	# surplus still there finishes the goal and pays it.
	_next_day(40.0, 30.0)
	_refresh()
	_check(_offered().has("pollen_surplus") and not _finished().has("pollen_surplus"), "one boundary of surplus is not yet a whole day")
	_next_day(40.0, 30.0)
	var pollen_before: float = _main.hive.total("pollen")
	var waiting: Dictionary = _offered().duplicate(true)
	_refresh()
	_check(_finished().has("pollen_surplus"), "a whole day of pollen surplus finishes the goal")
	var paid_pollen := 0.0
	for id: String in waiting:
		if _finished().has(id) and str(waiting[id].resource) == "pollen":
			paid_pollen += float(waiting[id].reward)
	var rise: float = _main.hive.total("pollen") - pollen_before
	_check(paid_pollen >= reward and absf(rise - paid_pollen) < 0.01,
		"the reward went into the stores (pollen rose %.2f, rewards %.2f)" % [rise, paid_pollen])

	_winter_part()
	_winter_lapse()
	_save_part()
	_reward_rules()


## The reward available() returns is the one paid: a quarter of gross income,
## at least the floor, and nothing at all when the fraction is zero. An
## unknown pollen rate shows no progress.
func _reward_rules() -> void:
	var facts := {"net_daily_income": {"pollen": 0.0}, "gross_daily_income": {"pollen": 4.0}}
	var thresholds := {"few_free_cells": 0, "many_waiting_bees": 99, "few_waiting_bees": 0}
	var floored: Array = Goals.available(facts, {}, 2, thresholds, 0.25, 5.0)
	_check(floored.size() == 1 and is_equal_approx(float(floored[0].reward), 5.0), "a small income's reward is raised to the floor")
	var off: Array = Goals.available(facts, {}, 2, thresholds, 0.0, 5.0)
	_check(off.size() == 1 and is_zero_approx(float(off[0].reward)), "a reward fraction of zero pays nothing, floor or not")
	var clock := {"held_since": {"pollen_surplus": 1}}
	var unknown: Dictionary = Goals.progress({"id": "pollen_surplus"}, {"net_daily_income": {}}, clock, 3, thresholds, true)
	_check(not unknown.done and int(unknown.current) == 0 and clock.held_since.has("pollen_surplus"),
		"an unknown pollen rate shows no progress and keeps the clock")


## "Lay in honey for winter" finishes on any countdown day; the CR-2
## milestone still waits for the last.
func _winter_part() -> void:
	var session: Node = root.get_node("Session")
	_main.short_term_goals = {}
	_next_day(40.0, 30.0, 20.0)
	session.winter_coming = true
	session.winter_here = false
	session.winter_starts_day = float(_main.day + 5)
	_refresh()
	_check(_offered().has("honey_for_winter"), "winter coming and not ready offers the winter goal (offered: %s)" % [_offered().keys()])
	if not _offered().has("honey_for_winter"):
		return
	_check(is_equal_approx(float(_offered().honey_for_winter.reward), 0.25 * 20.0), "the winter goal pays a quarter of the day's honey made")
	var bees: int = _main.get_tree().get_nodes_in_group("bees").size()
	var forecast: Dictionary = _main.year_winter._winter_forecast(bees)
	var short: float = float(forecast.required_energy) - float(forecast.held_energy)
	var factor: float = root.get_node("GameConfig").honey_energy_factor
	var honey: float = short / factor + 5.0
	_check(is_equal_approx(_main.hive.pay_reward("honey", honey), honey), "the comb holds winter's honey")
	var honey_before: float = _main.hive.total("honey")
	_refresh()
	_check(_finished().has("honey_for_winter"), "the winter goal finishes five days before winter")
	_check(_main.hive.total("honey") - honey_before > 0.0, "the winter goal paid honey")
	_check(not Conditions.met(_main, {"winter_ready": true}), "the CR-2 winter verdict waits for the countdown's last day")
	_main.colony_milestones.evaluate()
	_check(_main.colony_milestones.day_met("winter_ready") < 0, "the CR-2 winter milestone is not met five days out")
	session.winter_starts_day = float(_main.day + 1)
	_main.colony_milestones.evaluate()
	_check(_main.colony_milestones.day_met("winter_ready") == _main.day, "the CR-2 winter milestone is met on the last day")
	session.winter_coming = false


## (Dave, 26 Oct 2026) An unfinished winter offer leaves quietly when winter
## arrives and when the countdown ends: not finished, not dismissed, unpaid.
func _winter_lapse() -> void:
	var session: Node = root.get_node("Session")
	var kept: Dictionary = _main.short_term_goals.duplicate(true)
	for ending: String in ["winter arrives", "the countdown ends"]:
		_main.short_term_goals = {}
		Goals.accept(_main.short_term_goals, {"id": "honey_for_winter", "label": "Lay in honey for winter",
			"resource": "honey", "offered_day": _main.day, "reward": 5.0})
		session.winter_coming = ending == "winter arrives"
		session.winter_here = ending == "winter arrives"
		var honey_before: float = _main.hive.total("honey")
		_refresh()
		_check(not _offered().has("honey_for_winter") and not _finished().has("honey_for_winter")
			and not _main.short_term_goals.get("dismissed", {}).has("honey_for_winter")
			and is_equal_approx(_main.hive.total("honey"), honey_before),
			"the winter offer leaves quietly, unpaid, when %s (%s, honey %.2f -> %.2f)" % [ending,
				_canonical(_main.short_term_goals), honey_before, _main.hive.total("honey")])
	session.winter_coming = false
	session.winter_here = false
	_main.short_term_goals = kept


## Offered and finished goals survive a save and an in-place restore; a save
## without the field restores none.
func _save_part() -> void:
	_next_day(40.0, 0.0)
	_refresh()
	var before: Dictionary = _main.short_term_goals.duplicate(true)
	_check(not _offered().is_empty() and not _finished().is_empty(), "goals on offer and finished to save (%s)" % _canonical(before))
	_check(SaveGame.save(_main, _save_path), "the run saved")
	var data: Dictionary = SaveGame.read(_save_path)
	_check(data.has("short_term_goals"), "the save holds the goals")
	_main.short_term_goals = {}
	_main.hive.record_collection("honey", 7.0)
	_main.saving._restore(data)
	_check(_main.day_store_totals.is_empty() and is_zero_approx(_main.hive.lifetime_honey_made),
		"an in-place restore starts the income window afresh, as a load does")
	_check(_canonical(_main.short_term_goals) == _canonical(before),
		"offered and finished goals come back from the save (%s, saved %s)" % [_canonical(_main.short_term_goals), _canonical(before)])
	data.erase("short_term_goals")
	_main.saving._restore(data)
	_check(_main.short_term_goals.is_empty(), "a save without goals restores none")
	if FileAccess.file_exists(_save_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(_save_path))


func _canonical(value: Variant) -> String:
	return JSON.stringify(JSON.parse_string(JSON.stringify(value)), "", true)

# --- the Challenges -------------------------------------------------

func _challenge_case() -> void:
	_check(_main.challenge_runner.active, "%s is running" % _case)
	_main.day_store_totals.clear()
	_main._sample_day_stores()
	_next_day(40.0, 0.0)
	var income: Dictionary = Conditions.income_window(_main, "pollen", 1)
	_check(not income.is_empty() and float(income.net) <= 0.0, "%s has the pollen shortfall that offers the goal elsewhere" % _case)
	_refresh()
	_check(_main.short_term_goals.is_empty(), "no goal is offered in %s" % _case)
	# A finished Challenge still keeps its own goals.
	_main.challenge_runner.active = false
	_refresh()
	_check(_main.short_term_goals.is_empty(), "no goal is offered in %s once it is no longer running" % _case)

# --- the end ----------------------------------------------------------

func _check(ok: bool, label: String) -> void:
	if ok:
		print("SG2 OK " + label)
	else:
		_failures.append(label)


func _finish() -> void:
	Levels.scenario_override = {}
	root.get_node("Session").starting_level = _old_level
	paused = false
	if _failures.is_empty():
		print("SG2 PASS")
		quit(0)
	else:
		for failure: String in _failures:
			print("SG2 FAIL " + failure)
		quit(1)
