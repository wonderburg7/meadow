"""PP-3: Gyne rearing and royal jelly are owned gates in Colony Runs.

The run-availability assertions boot the production scripts in Godot.  The
source checks keep the order guard and both nurse action rows tied to those
same skills, while the scenario fixture records the non-Colony contract.
"""

from __future__ import annotations

import json
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "tools"))

import godot_compile_check as gcc  # noqa: E402

ROYAL_JELLY = "skill.brood.royal_jelly"
GYNE_REARING = "skill.brood.gyne_rearing"

SCRIPT = """extends SceneTree
var _frame := 0

func _process(_delta: float) -> bool:
	_frame += 1
	if _frame == 3:
		var Skills = load(\"res://scripts/skills.gd\")
		var RunAvailability = load(\"res://scripts/run_availability.gd\")
		var colony: Dictionary = RunAvailability.sheet_for({\"run_type\": \"colony\"})
		var scenario: Dictionary = RunAvailability.sheet_for({\"name\": \"PP-3 scenario\"})
		for skill in [Skills.GYNE_REARING, Skills.ROYAL_JELLY_SKILL]:
			print(\"PP3 %s|%s\" % [colony.starting.has(skill), scenario.starting.has(skill)])
	return _frame >= 4
"""


class GyneGateTest(unittest.TestCase):
    def test_catalogue_and_order_gate_use_the_same_skills(self):
        actions = (ROOT / "scripts" / "actions.gd").read_text(encoding="utf-8")
        for action in ("nurse_store_jelly", "nurse_make_jelly"):
            block = actions.split('"id": "%s"' % action, 1)[1].split("\n\t},", 1)[0]
            self.assertIn('"skill": "%s"' % ROYAL_JELLY, block)
        roles = (ROOT / "scripts" / "roles.gd").read_text(encoding="utf-8")
        self.assertIn('"key": "jelly", "skill": "%s"' % ROYAL_JELLY, roles)
        orders = (ROOT / "scripts" / "orders_zones.gd").read_text(encoding="utf-8")
        guard = orders.split("func _on_cell_gyne_requested", 1)[1].split("func _on_cell_keep_empty_requested", 1)[0]
        self.assertIn('not Session.progression.is_owned("%s")' % GYNE_REARING, guard)
        self.assertIn("_warn_gyne_rearing_required()", guard)

    def test_colony_buys_both_skills_and_a_scenario_starts_with_them(self):
        godot = gcc.find_godot()
        if not godot:
            self.skipTest("no Godot executable found -- this test needs a real boot")
        gcc.ensure_writable_user_dir()
        if not gcc.engine_can_boot(godot):
            self.skipTest("the installed Godot engine cannot initialise headlessly here")
        if not gcc.prepare_cache(godot):
            self.skipTest("the shared Godot import cache cannot be prepared from the current primary checkout")
        with tempfile.TemporaryDirectory() as folder:
            script = Path(folder) / "pp3.gd"
            script.write_text(SCRIPT, encoding="utf-8")
            finished = subprocess.run(
                [godot, "--headless", "--disable-crash-handler", "--path", str(ROOT),
                 "--script", str(script)],
                capture_output=True, text=True, encoding="utf-8", errors="replace", timeout=180,
            )
        output = gcc.combined_output(finished)
        self.assertEqual(gcc.failing_lines(output), [], output[-2000:])
        self.assertEqual([line[4:] for line in output.splitlines() if line.startswith("PP3 ")],
                         ["false|true", "false|true"], output[-2000:])

    def test_scenario_fixture_starts_with_both_skills(self):
        fixture = json.loads((ROOT / "test_scenarios" / "pp3_gyne_gate.json").read_text(encoding="utf-8"))
        owned = [a["condition"]["skill_owned"] for a in fixture["actions"] if a.get("do") == "assert"]
        self.assertEqual(owned, [GYNE_REARING, ROYAL_JELLY])


if __name__ == "__main__":
    unittest.main()
