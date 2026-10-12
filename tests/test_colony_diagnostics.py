"""Exercise the shipping GDScript diagnostic pass with compact colony fixtures."""

import json
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "tools"))
import godot_compile_check as gcc  # noqa: E402


SCRIPT = r'''extends SceneTree

class Cell:
	extends RefCounted
	var brood_fed_seconds: float = 0.0
	var keep_empty: bool = false

class Hive:
	extends Node
	var buckets: Dictionary = {}
	func cells_holding(content: String) -> Array:
		return buckets.get(content, [])

class Colony:
	extends Node2D
	var hive: Hive = Hive.new()

class Bee:
	extends RefCounted
	var energy: float = 100.0
	var waiting: bool = false
	var travelling: bool = false
	var no_work: bool = false
	func is_waiting_for_work() -> bool:
		return waiting
	func is_travelling_for_work() -> bool:
		return travelling
	func has_no_available_work() -> bool:
		return no_work

func _process(_delta: float) -> bool:
	var diagnostics: GDScript = load("res://scripts/colony_diagnostics.gd")
	var roles: GDScript = load("res://scripts/roles.gd")
	var cases: Array = [
		{"name": "empty", "brood": 0, "corpses": 0, "nurses": 0, "comb": 0},
		{"name": "staffed", "brood": 2, "corpses": 1, "nurses": 1, "comb": 1},
		{"name": "blocked", "brood": 2, "corpses": 2, "nurses": 0, "comb": 0},
		{"name": "partly_staffed", "brood": 2, "corpses": 2, "nurses": 1, "comb": 0},
		{"name": "waiting_with_work", "brood": 0, "corpses": 0, "nurses": 0, "comb": 0, "waiting": true},
		{"name": "no_work", "brood": 0, "corpses": 0, "nurses": 0, "comb": 0, "waiting": true, "no_work": true},
		{"name": "travelling", "brood": 0, "corpses": 0, "nurses": 0, "comb": 0, "travelling": true},
	]
	for item in cases:
		var colony := Colony.new()
		var brood: Array = []
		var corpses: Array = []
		for i in range(item.brood):
			brood.append(Cell.new())
		for i in range(item.corpses):
			corpses.append(Cell.new())
		colony.hive.buckets = {"brood": brood, "corpse": corpses, "": [Cell.new()]}
		var counts: Dictionary = {
			roles.count_key(roles.NURSE): item.nurses,
			roles.count_key(roles.COMB_WORKER): item.comb,
		}
		var bee := Bee.new()
		bee.waiting = item.get("waiting", false)
		bee.travelling = item.get("travelling", false)
		bee.no_work = item.get("no_work", false)
		var facts: Dictionary = diagnostics.compute(colony, [bee], counts)
		print("DIAGNOSTIC " + JSON.stringify({"name": item.name, "facts": facts}))
		colony.free()
	return true
'''


class ColonyDiagnosticsTest(unittest.TestCase):
    def test_empty_staffed_and_blocked_colonies(self):
        godot = gcc.find_godot()
        if not godot:
            self.skipTest("no Godot executable found -- this test needs a real boot")
        gcc.ensure_writable_user_dir()
        if not gcc.engine_can_boot(godot):
            self.skipTest("the installed Godot engine cannot initialise headlessly here")
        self.assertTrue(gcc.prepare_cache(godot), "could not prepare the Godot import cache")
        with tempfile.TemporaryDirectory(dir=ROOT / "tests") as directory:
            script = Path(directory) / "diagnostics_test.gd"
            script.write_text(SCRIPT, encoding="utf-8")
            try:
                finished = subprocess.run(
                    [godot, "--headless", "--disable-crash-handler", "--path", str(ROOT),
                     "--script", str(script)],
                    capture_output=True, text=True, encoding="utf-8", errors="replace", timeout=15,
                )
            except subprocess.TimeoutExpired as error:
                self.fail("Godot timed out:\n" + str(error.stdout) + str(error.stderr))
        output = gcc.combined_output(finished)
        self.assertEqual(gcc.failing_lines(output), [], output[-3000:])
        self.assertEqual(finished.returncode, 0, output[-3000:])
        facts = {
            row["name"]: row["facts"]
            for line in output.splitlines() if line.startswith("DIAGNOSTIC ")
            for row in [json.loads(line.removeprefix("DIAGNOSTIC "))]
        }
        self.assertEqual(set(facts), {"empty", "staffed", "blocked", "partly_staffed", "waiting_with_work", "no_work", "travelling"})
        expected = {
            "empty": (0, 0, 0, 0, 0),
            "staffed": (0, 0, 0, 1, 0),
            "blocked": (1, 1, 2, 2, 4),
            "partly_staffed": (0, 1, 1, 2, 2),
        }
        keys = ("missing_nurse_workforce", "missing_comb_workforce",
                "missing_required_workforce", "blocked_cells", "blocked_work")
        for name, values in expected.items():
            with self.subTest(name=name):
                self.assertEqual(tuple(facts[name][key] for key in keys), values)
                self.assertTrue(all(facts[name][key] >= 0 for key in keys))

        self.assertEqual(
            tuple(facts["waiting_with_work"][key] for key in ("waiting_for_work", "travelling_for_work", "no_available_work")),
            (1, 0, 0),
        )
        self.assertEqual(
            tuple(facts["no_work"][key] for key in ("waiting_for_work", "travelling_for_work", "no_available_work")),
            (1, 0, 1),
        )
        self.assertEqual(
            tuple(facts["travelling"][key] for key in ("waiting_for_work", "travelling_for_work", "no_available_work")),
            (0, 1, 0),
        )

    def test_one_hz_snapshot_passes_named_facts(self):
        source = (ROOT / "scripts" / "year_winter.gd").read_text(encoding="utf-8")
        refresh = source.split("func _refresh_signals(", 1)[1].split("func _refresh_panels(", 1)[0]
        self.assertIn("ColonyDiagnostics.compute(main, bees, counts)", refresh)
        for key in ("blocked_cells", "blocked_work", "missing_nurse_workforce",
                    "missing_comb_workforce", "missing_required_workforce", "waiting_for_work",
                    "travelling_for_work", "no_available_work"):
            self.assertIn('"%s": facts.%s' % (key, key), refresh)


if __name__ == "__main__":
    unittest.main()
