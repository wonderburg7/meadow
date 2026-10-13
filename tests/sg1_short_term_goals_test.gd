extends SceneTree

const Goals = preload("res://scripts/short_term_goals.gd")
const THRESHOLDS := {"few_free_cells": 3, "many_waiting_bees": 5, "few_waiting_bees": 1}
var failures: int = 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var base := _facts()
	_check(Goals.available(base, {}, 1, THRESHOLDS, 0.25).is_empty(), "no trigger, no offer")
	var cases := [
		["pollen_surplus", {"net_daily_income": {"pollen": 0.0}}],
		["clear_blocked_work", {"blocked_work": 1}],
		["make_room", {"free_cells": 3}],
		["feed_every_larva", {"hungry_brood": 1}],
		["put_waiting_bees_to_work", {"waiting_for_work": 5}],
		["honey_for_winter", {"winter_coming": true, "winter_ready": false}],
	]
	for case in cases:
		var facts := base.duplicate(true)
		facts.merge(case[1], true)
		var offers: Array = Goals.available(facts, {}, 1, THRESHOLDS, 0.25)
		_check(offers.size() == 1 and offers[0].id == case[0], "trigger for " + case[0])
		if offers.is_empty():
			continue
		var state := {}
		Goals.accept(state, offers[0])
		_check(Goals.available(facts, state, 1, THRESHOLDS, 0.25).is_empty(), "no duplicate " + case[0])
		Goals.dismiss(state, case[0], 1)
		_check(Goals.available(facts, state, 1, THRESHOLDS, 0.25).is_empty(), "dismissed today " + case[0])
		_check(Goals.available(facts, state, 2, THRESHOLDS, 0.25).size() == 1, "dismissed may return tomorrow " + case[0])
	var all := base.duplicate(true)
	all.merge({"net_daily_income": {"pollen": 0.0}, "blocked_cells": 1, "free_cells": 0,
		"hungry_brood": 1, "waiting_for_work": 8, "winter_coming": true, "winter_ready": false}, true)
	var state := {}
	var two: Array = Goals.available(all, state, 5, THRESHOLDS, 0.25)
	_check(two.size() == 2, "two offers at most")
	for entry in two:
		Goals.accept(state, entry)
	_check(Goals.available(all, state, 5, THRESHOLDS, 0.25).is_empty(), "two active slots full")
	Goals.dismiss(state, two[1].id, 5)
	_check(Goals.available(all, state, 5, THRESHOLDS, 0.25).is_empty(), "dismissed slot stays empty today")
	_check(is_equal_approx(two[0].reward, 2.5), "gross daily pollen income sets reward")
	all.gross_daily_income.pollen = 1000.0
	_check(is_equal_approx(Goals.finish(state, two[0].id, 5), 2.5), "reward fixed at offer")
	_check(Goals.available(all, state, 5, THRESHOLDS, 0.25).size() == 1, "finished today excluded")
	var pollen := {"id": "pollen_surplus"}
	var steady := _facts()
	var clock := {}
	_check(not Goals.progress(pollen, steady, clock, 1, THRESHOLDS).done, "midday surplus is not a full day")
	_check(not Goals.progress(pollen, steady, clock, 2, THRESHOLDS, true).done, "start at day boundary")
	_check(Goals.progress(pollen, steady, clock, 3, THRESHOLDS, true).done, "surplus for whole day")
	steady.net_daily_income.pollen = 0.0
	_check(not Goals.progress(pollen, steady, clock, 3, THRESHOLDS).done, "interruption resets day")
	steady.net_daily_income.pollen = 1.0
	_check(not Goals.progress(pollen, steady, clock, 4, THRESHOLDS, true).done, "surplus restarts")
	var larvae := {"id": "feed_every_larva"}
	_check(not Goals.progress(larvae, steady, clock, 4, THRESHOLDS, true).done, "fed larvae clock starts")
	_check(Goals.progress(larvae, steady, clock, 5, THRESHOLDS, true).done, "fed larvae whole day")
	var room := {"id": "make_room", "built_cells_target": 13}
	steady.built_cells = 12
	_check(not Goals.progress(room, steady, {}, 2, THRESHOLDS).done, "room build target pending")
	steady.built_cells = 13
	_check(Goals.progress(room, steady, {}, 2, THRESHOLDS).done, "room build target met")
	_check(Goals.progress({"id": "clear_blocked_work"}, steady, {}, 2, THRESHOLDS).done, "blocked work cleared")
	_check(Goals.progress({"id": "put_waiting_bees_to_work"}, steady, {}, 2, THRESHOLDS).done, "waiting bees reduced")
	_check(Goals.progress({"id": "honey_for_winter"}, steady, {}, 2, THRESHOLDS).done, "winter ready")
	if failures == 0:
		print("SG1 PASS")
	quit(1 if failures > 0 else 0)


func _facts() -> Dictionary:
	return {"net_daily_income": {"pollen": 1.0},
		"gross_daily_income": {"pollen": 10.0, "honey": 8.0, "nectar": 12.0},
		"blocked_cells": 0, "blocked_work": 0, "free_cells": 9,
		"built_cells": 10, "hungry_brood": 0, "waiting_for_work": 0,
		"winter_coming": false, "winter_ready": true}


func _check(ok: bool, label: String) -> void:
	if not ok:
		failures += 1
		print("SG1 FAIL " + label)
