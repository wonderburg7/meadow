extends SceneTree
## C-140: a check save made in a scenario run loads, outside one, with the
## scenario's level row, so its Colony Run and weather rules still hold.

func _process(_delta: float) -> bool:
	_run()
	return true

func _run() -> void:
	var SaveGame: GDScript = load("res://scripts/save_game.gd")
	var Levels: GDScript = load("res://scripts/levels.gd")
	var failures: PackedStringArray = PackedStringArray()
	var session: Node = root.get_node("Session")
	var old_level: int = session.starting_level
	var old_override: Dictionary = Levels.scenario_override

	# What the saved file hands back: the row through JSON, so whole numbers
	# arrive as floats, as a real load reads them.
	var row := {"run_type": "colony", "weather": true, "winter": true, "cells": 8}
	var data: Dictionary = JSON.parse_string(JSON.stringify({"starting_level": Levels.SCENARIO_LEVEL_ID, "scenario_level": row}))
	Levels.scenario_override = {}
	session.starting_level = 0
	SaveGame.apply_starting_level(data)
	_expect(failures, session.starting_level == Levels.SCENARIO_LEVEL_ID, "the scenario level id was not put back")
	var level: Dictionary = Levels.get_level(Levels.SCENARIO_LEVEL_ID)
	_expect(failures, str(level.get("run_type", "")) == "colony", "the loaded scenario level is not a Colony Run")
	_expect(failures, Levels.weather_enabled(Levels.SCENARIO_LEVEL_ID), "the loaded scenario level has no weather")
	_expect(failures, typeof(level.get("cells")) == TYPE_INT and int(level.cells) == 8, "a whole number came back as a float")

	# Any other level leaves the override alone.
	Levels.scenario_override = {}
	SaveGame.apply_starting_level({"starting_level": 8, "scenario_level": row})
	_expect(failures, Levels.scenario_override.is_empty(), "a non-scenario save set the scenario level")

	session.starting_level = old_level
	Levels.scenario_override = old_override
	if failures.is_empty():
		print("C140 PASS")
		quit(0)
	else:
		for failure in failures:
			print("C140 FAIL ", failure)
		quit(1)

func _expect(failures: PackedStringArray, ok: bool, what: String) -> void:
	if not ok:
		failures.append(what)
