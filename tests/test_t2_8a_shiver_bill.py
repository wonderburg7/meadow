"""T2-8a: winter's bill multiplied without Shiver Cluster, and the warning.

season.gd::winter_bill multiplies the bill by
GameConfig.winter_unclustered_multiplier while the colony does not own
skill.hive_mind.shiver_cluster. Until T2-8b adds that node to skills.gd,
season.gd::owns_shiver_cluster (through progression.gd::is_owned_or_absent)
answers owned, so nothing in play changes.

To see the unowned path before the node exists, the headless script points
season.gd's shiver_cluster_skill at a skill the catalogue does have and the
run does not own, the one seam the code leaves for it. Everything else runs
the shipping code: the bill, _winter_losses (with stand-in bees, as
tests/test_col6_winter_skip.py does), problem_messages.gd's strip lines and
winter_panel.gd's window. Requires a real Godot.
"""

from __future__ import annotations

import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "tools"))

import godot_compile_check as gcc  # noqa: E402

SEASON = ROOT / "scripts" / "season.gd"

# A bill of exactly 1.0 per bee per day while owned (energy_burn_rate,
# winter_burn_factor and seconds_per_day all 1), so an unowned one is 2.0.
SCRIPT = """extends SceneTree
var _frame := 0

func _bee(name: String, caste: String, age: float) -> Dictionary:
	return {"name": name, "is_queen": caste == "queen", "is_gyne": caste == "gyne",
		"is_drone": caste == "drone", "age_seconds": age}

func _losses(season: Node, bees: Array, held: float) -> String:
	var names: PackedStringArray = PackedStringArray()
	for bee in season._winter_losses(bees, held, 1.0):
		names.append(bee["name"])
	return ",".join(names)

func _state(day: float) -> Dictionary:
	return {"bees": [], "queen": null, "day": day, "starving": 0, "hungry": 0,
		"foragers": 1, "nurses": 1, "comb_workers": 1, "hungry_brood": 0,
		"free_cells": 1, "dead_cells": 0, "brood_cells": 0, "pollen": 1000.0,
		"nectar": 1000.0, "honey": 1000.0, "rain_intensity": 0.0}

func _strip(messages, day: float) -> String:
	var found: PackedStringArray = PackedStringArray()
	for line in messages.signal_lines(_state(day)):
		if str(line[0]).contains("Shiver Cluster"):
			found.append("%s|%d" % [line[0], int(line[1])])
	return ";".join(found)

# Runs once, on the third frame, and quits on the fourth even if a script
# error stopped it part-way (the missing lines then fail the test).
func _process(_delta: float) -> bool:
	_frame += 1
	if _frame == 3:
		_check()
	return _frame >= 4

func _check() -> void:
	var config: Node = root.get_node("GameConfig")
	var session: Node = root.get_node("Session")
	config.energy_burn_rate = 1.0
	config.winter_burn_factor = 1.0
	config.seconds_per_day = 1.0
	config.winter_unclustered_multiplier = 2.0
	config.winter_unclustered_warning_days = 3.0
	var Season = load("res://scripts/season.gd")
	var Skills = load("res://scripts/skills.gd")
	var messages = load("res://scripts/problem_messages.gd")
	var season: Node = Season.new()
	var bees: Array = [
		_bee("queen", "queen", 500.0), _bee("worker_old", "worker", 400.0),
		_bee("worker_mid", "worker", 200.0), _bee("worker_young", "worker", 10.0),
	]
	session.winter_coming = true
	session.winter_here = false
	session.winter_starts_day = 20.0

	# The node absent: owned, so the bill and everything else is as before.
	var progression = load("res://scripts/progression.gd").new()
	session.progression = progression
	print("T2_8A ABSENT_EXISTS %s" % Skills.has(Season.SHIVER_CLUSTER))
	print("T2_8A ABSENT_OWNED %s" % Season.owns_shiver_cluster())
	print("T2_8A ABSENT_BILL %s" % season.winter_bill(4, 1.0))
	print("T2_8A ABSENT_LOSSES 4: %s" % _losses(season, bees, 4.0))
	print("T2_8A ABSENT_STRIP %s" % _strip(messages, 18.0))

	# Unowned: a skill the catalogue has and this run does not own.
	var stand_in: String = ""
	for skill_id in Skills.ids():
		if not Skills.is_baseline(skill_id):
			stand_in = skill_id
			break
	Season.shiver_cluster_skill = stand_in
	print("T2_8A UNOWNED_OWNED %s" % Season.owns_shiver_cluster())
	print("T2_8A UNOWNED_BILL %s" % season.winter_bill(4, 1.0))
	for held in [8.0, 4.0, 2.0, 1.0]:
		print("T2_8A UNOWNED_LOSSES %s: %s" % [held, _losses(season, bees, held)])
	for day in [16.0, 17.0, 19.5]:
		print("T2_8A UNOWNED_STRIP %s: %s" % [day, _strip(messages, day)])
	# Out of the tree: its _ready needs main.gd. refresh only needs the labels.
	var panel = load("res://scripts/winter_panel.gd").new()
	panel.headline = Label.new()
	panel.detail = Label.new()
	panel.verdict = Label.new()
	panel.refresh({"bees": 4, "required_energy": season.winter_bill(4),
		"held_energy": 0.0, "days_left": 15.0})
	print("T2_8A UNOWNED_PANEL %s" % panel.detail.text.contains("Shiver Cluster"))

	# Owned through progression: back to the base bill, no warning.
	progression.grant_temporary(stand_in)
	print("T2_8A OWNED_OWNED %s" % Season.owns_shiver_cluster())
	print("T2_8A OWNED_BILL %s" % season.winter_bill(4, 1.0))
	print("T2_8A OWNED_STRIP %s" % _strip(messages, 18.0))
	panel.refresh({"bees": 4, "required_energy": season.winter_bill(4),
		"held_energy": 0.0, "days_left": 15.0})
	print("T2_8A OWNED_PANEL %s" % panel.detail.text.contains("Shiver Cluster"))

	session.progression = null
	Season.shiver_cluster_skill = Season.SHIVER_CLUSTER
	session.winter_coming = false
	for label in [panel.headline, panel.detail, panel.verdict]:
		label.free()
	panel.free()
	season.free()
"""


def _run_script(test: unittest.TestCase) -> dict[str, str]:
    godot = gcc.find_godot()
    if not godot:
        test.skipTest("no Godot executable found -- this test needs a real boot")
    gcc.ensure_writable_user_dir()
    if not gcc.engine_can_boot(godot):
        test.skipTest("the installed Godot engine cannot initialise headlessly here")
    test.assertTrue(gcc.prepare_cache(godot), "could not prepare the Godot import cache")
    with tempfile.TemporaryDirectory() as folder:
        script = Path(folder) / "t2_8a_shiver_bill.gd"
        script.write_text(SCRIPT, encoding="utf-8")
        finished = subprocess.run(
            [godot, "--headless", "--disable-crash-handler", "--path", str(ROOT),
             "--script", str(script)],
            capture_output=True, text=True, encoding="utf-8", errors="replace", timeout=180,
        )
    output = gcc.combined_output(finished)
    test.assertEqual(gcc.failing_lines(output), [], "script errors:\n" + output[-2000:])
    # "T2_8A KEY value" or "T2_8A KEY amount: value"; an amount is keyed as %g.
    seen = {}
    for line in output.splitlines():
        if not line.startswith("T2_8A "):
            continue
        key, _, value = line[len("T2_8A "):].partition(" ")
        if ": " in value:
            amount, _, value = value.partition(": ")
            key += " %g" % float(amount)
        seen[key] = value.strip()
    test.assertTrue(seen, "the script printed nothing:\n" + output[-2000:])
    return seen


class ShiverBillTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.seen = None

    def results(self) -> dict[str, str]:
        if ShiverBillTest.seen is None:
            ShiverBillTest.seen = _run_script(self)
        return ShiverBillTest.seen

    def test_with_the_node_absent_nothing_changes(self):
        seen = self.results()
        self.assertEqual(seen["ABSENT_EXISTS"], "false")
        self.assertEqual(seen["ABSENT_OWNED"], "true")
        self.assertEqual(float(seen["ABSENT_BILL"]), 4.0)
        self.assertEqual(seen["ABSENT_LOSSES 4"], "")
        self.assertEqual(seen["ABSENT_STRIP"], "")

    def test_an_unowned_bill_is_the_owned_bill_times_the_multiplier(self):
        seen = self.results()
        self.assertEqual(seen["UNOWNED_OWNED"], "false")
        self.assertEqual(float(seen["UNOWNED_BILL"]), 8.0)
        self.assertEqual(seen["OWNED_OWNED"], "true")
        self.assertEqual(float(seen["OWNED_BILL"]), 4.0)

    def test_the_unowned_shortfall_takes_the_oldest_workers_first_and_the_queen_last(self):
        seen = self.results()
        # Four bees at 2.0 each unowned: 8 carries all of them, 4 only two.
        self.assertEqual(seen["UNOWNED_LOSSES 8"], "")
        self.assertEqual(seen["UNOWNED_LOSSES 4"], "worker_old,worker_mid")
        self.assertEqual(seen["UNOWNED_LOSSES 2"], "worker_old,worker_mid,worker_young")
        self.assertEqual(seen["UNOWNED_LOSSES 1"], "worker_old,worker_mid,worker_young,queen")

    def test_the_warning_appears_only_while_unowned_and_in_the_last_days(self):
        seen = self.results()
        self.assertEqual(seen["UNOWNED_STRIP 16"], "", "warned four days out")
        self.assertEqual(
            seen["UNOWNED_STRIP 17"],
            "Winter in 3 days, and without Shiver Cluster the colony burns 2 times its stores through it|2",
        )
        self.assertEqual(
            seen["UNOWNED_STRIP 19.5"],
            "Winter in 1 day, and without Shiver Cluster the colony burns 2 times its stores through it|2",
        )
        self.assertEqual(seen["OWNED_STRIP"], "")

    def test_the_winter_window_says_so_while_unowned(self):
        seen = self.results()
        self.assertEqual(seen["UNOWNED_PANEL"], "true")
        self.assertEqual(seen["OWNED_PANEL"], "false")


class ShiverBillSourceTest(unittest.TestCase):
    def test_the_multiplier_lives_in_the_one_copy_of_the_formula(self):
        season = SEASON.read_text(encoding="utf-8").replace("\r\n", "\n")
        bill = season.split("\nfunc winter_bill(", 1)[1].split("\n## ", 1)[0]
        self.assertIn("GameConfig.winter_unclustered_multiplier", bill)
        self.assertIn("owns_shiver_cluster()", bill)
        self.assertEqual(season.count("winter_unclustered_multiplier"), 2,
                         "the multiplier is applied somewhere besides winter_bill")


if __name__ == "__main__":
    unittest.main()
