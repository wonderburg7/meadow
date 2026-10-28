"""RR-19: comb workers seal and unseal cells over time.

Runs tests/rr19_sealing_test.gd in a headless Godot at a fixed 60 fps. Seal
on a full cell leaves it open, its stores usable, until comb workers have
spent GameConfig.cell_seal_seconds on it, then it is closed; Open takes
cell_unseal_seconds; "Fill then seal" caps a cell filled with converted honey,
one already full of jelly, and a brood cell, each refusing withdrawals while
it waits; with no comb worker free nothing changes; winter's bill still opens
and recloses a sealed cell at once; Seal on a closed cell changes nothing.

The static half checks the settings rows, the action row, the two appended
bee states and the save fields, and that test_scenarios/rr19_sealing_stocked.json
stocks a honey, a jelly and a brood cell and saves them as "C127 stocked" for
Dave's hands-on check.

Run with: python -m unittest tests.test_rr19_sealing
"""

from __future__ import annotations

import json
import re
import subprocess
import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SCRIPTS = ROOT / "scripts"
sys.path.insert(0, str(ROOT / "tools"))

import godot_compile_check as gcc  # noqa: E402

TEST_SCRIPT = "res://tests/rr19_sealing_test.gd"
STOCKED = ROOT / "test_scenarios" / "rr19_sealing_stocked.json"
TIMEOUT_SECONDS = 300


def _read(name: str) -> str:
    return (SCRIPTS / name).read_text(encoding="utf-8")


class RR19SealingRunTest(unittest.TestCase):
    def test_comb_workers_cap_and_uncap_cells_over_time(self):
        godot = gcc.find_godot()
        if not godot:
            self.skipTest("no Godot executable found -- this test needs a real boot")
        gcc.ensure_writable_user_dir()
        if not gcc.engine_can_boot(godot):
            self.skipTest("the installed Godot engine cannot initialise headlessly here")
        self.assertTrue(gcc.prepare_cache(godot), "could not prepare the Godot import cache")
        finished = subprocess.run(
            [godot, "--headless", "--disable-crash-handler", "--fixed-fps", "60",
             "--path", str(ROOT), "--script", TEST_SCRIPT],
            capture_output=True, text=True, encoding="utf-8", errors="replace",
            timeout=TIMEOUT_SECONDS,
        )
        output = gcc.combined_output(finished)
        script_errors = gcc.failing_lines(output)
        failures = [line for line in output.splitlines() if line.startswith("RR19 FAIL")]
        self.assertEqual(script_errors, [], "script errors:\n" + "\n".join(script_errors))
        self.assertEqual(failures, [], "\n".join(failures))
        self.assertIn("RR19 PASS", output, "the test script did not report a pass:\n" + output[-2000:])
        self.assertEqual(finished.returncode, 0, "Godot exited with code %d" % finished.returncode)


class RR19SealingSourceTest(unittest.TestCase):
    def test_both_times_are_balance_values_with_settings_rows(self):
        config = _read("game_config.gd")
        self.assertRegex(config, r"(?m)^var cell_seal_seconds: float = 15\.0$")
        self.assertRegex(config, r"(?m)^var cell_unseal_seconds: float = 5\.0$")
        catalogue = _read("settings_catalogue.gd")
        self.assertIn('"key": "cell_seal_seconds"', catalogue)
        self.assertIn('"key": "cell_unseal_seconds"', catalogue)

    def test_the_sealing_row_comes_right_after_eviction(self):
        actions = _read("actions.gd")
        row = re.search(r'"id": "comb_seal_cell".*?"band": (\d+).*?"find": "(\w+)"', actions, re.S)
        self.assertIsNotNone(row, "actions.gd has no comb_seal_cell row")
        self.assertEqual(row.group(1), "2")   # right after eviction, band 1
        self.assertEqual(row.group(2), "find_cell_needing_sealing")
        self.assertIn("static func find_cell_needing_sealing(bee: Node2D) -> bool:", _read("bee_building.gd"))

    def test_the_two_states_are_appended(self):
        enums = _read("bee_enums.gd")
        states = enums.split("enum State {", 1)[1].split("}", 1)[0]
        names = re.findall(r"\b[A-Z][A-Z_]+\b", re.sub(r"#.*", "", states))
        self.assertEqual(names[-2:], ["TO_SEAL_CELL", "SEALING"])

    def test_the_player_orders_go_through_a_comb_worker(self):
        orders = _read("orders_zones.gd")
        handlers = orders.split("func _on_cell_close_requested(", 1)[1].split("func _restock_comb_workers(", 1)[0]
        self.assertNotIn("set_closed", handlers)
        self.assertNotIn("set_fill_then_close", handlers)
        self.assertIn("request_seal()", handlers)
        self.assertIn("request_open()", handlers)
        self.assertIn("request_fill_then_seal()", handlers)

    def test_winter_still_closes_at_once(self):
        season = _read("season.gd")
        bill = season.split("func _pay_from_stores(", 1)[1].split("\nfunc ", 1)[0]
        self.assertIn("cell.set_closed(true)", bill)
        self.assertNotIn("request_seal", bill)

    def test_the_flags_are_saved(self):
        self.assertIn('"pending_seal": cell.pending_seal,', _read("save_game.gd"))
        self.assertIn('"pending_open": cell.pending_open,', _read("save_game.gd"))
        self.assertIn(
            'cell.restore_seal_flags(bool(entry.get("pending_seal", false)), bool(entry.get("pending_open", false)))',
            _read("saving.gd"))

    def test_the_stocked_scenario_saves_honey_jelly_and_brood(self):
        scenario = json.loads(STOCKED.read_text(encoding="utf-8"))
        stocked = {action.get("resource") for action in scenario["actions"]
                   if action.get("do") == "set_cell_contents"}
        self.assertTrue({"honey", "jelly", "brood"} <= stocked, stocked)
        self.assertEqual(scenario["actions"][-1], {"do": "save_run", "name": "C127 stocked"})


if __name__ == "__main__":
    unittest.main()
