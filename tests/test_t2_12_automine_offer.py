"""T2-12: "Dig on its own" is offered only once Automation is owned.

Static part: the HUD's mode column and Raises menu both ask the Availability
rule (which names the Automation skill for the Miner's automine mode).
Run part: tests/t2_12_automine_offer_test.gd in a headless Godot: without
Automation the selected miner's Job panel has no "Dig on its own" toggle and
the cell's Raises menu has no "Miner — Dig on its own"; with Automation owned
both are offered.
"""

from __future__ import annotations

import subprocess
import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "tools"))

import godot_compile_check as gcc  # noqa: E402

TEST_SCRIPT = "res://tests/t2_12_automine_offer_test.gd"


def _read(rel: str) -> str:
    return (ROOT / rel).read_text(encoding="utf-8")


class AutomineOfferStaticTest(unittest.TestCase):
    def test_automine_mode_names_the_automation_skill(self):
        roles = _read("scripts/roles.gd")
        self.assertIn('{"key": "automine", "skill": "skill.hive_mind.automation"', roles)

    def test_job_panel_toggle_waits_for_the_skill(self):
        hud = _read("scripts/hud_command_rows.gd")
        self.assertIn(
            "common_role == Roles.COMB_WORKER or common_role == Roles.MINER) and not Availability.mode_query(",
            hud,
        )

    def test_raises_menu_filters_by_the_skill(self):
        hud = _read("scripts/hud.gd")
        start = hud.index("func _fill_hatch_menu")
        body = hud[start:hud.index("\nconst WARNING_SECONDS", start)]
        self.assertIn('Availability.mode_query(role_value, mode, null, Session.progression).available', body)


class AutomineOfferRunTest(unittest.TestCase):
    def test_offer_follows_automation(self):
        godot = gcc.find_godot()
        if not godot:
            self.skipTest("no Godot executable found -- this test needs a real boot")
        gcc.ensure_writable_user_dir()
        if not gcc.engine_can_boot(godot):
            self.skipTest("the installed Godot engine cannot initialise headlessly here")
        self.assertTrue(gcc.prepare_cache(godot), "could not prepare the Godot import cache")
        finished = subprocess.run(
            [godot, "--headless", "--disable-crash-handler", "--path", str(ROOT),
             "--script", TEST_SCRIPT],
            capture_output=True, text=True, encoding="utf-8", errors="replace", timeout=120,
        )
        output = gcc.combined_output(finished)
        failures = [line for line in output.splitlines() if line.startswith("T2_12 FAIL")]
        self.assertEqual(failures, [], "\n".join(failures))
        self.assertIn("T2_12 PASS", output, output[-1500:])


if __name__ == "__main__":
    unittest.main()
