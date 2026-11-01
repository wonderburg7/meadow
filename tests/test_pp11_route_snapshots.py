"""PP-11: a run's snapshots log the three stores Gyne rearing's path spends
beyond honey, nectar and pollen -- bee bread, royal jelly and Pollinator
Points -- so a seed that holds plenty of honey yet never affords Gyne rearing
shows which of them holds it back.

The static half checks both whitelists (diagnostic_probes.gd's
SNAPSHOT_FIELDS, which the game reads, and tools/headless/profiles.py's,
which validates a scenario before launch) carry the fields, that the probe
reads the values gyne_rearing_affordable passes, and that the reference arc
asks for them. The run half boots a short fixture written to a temporary
file: it stocks one cell each of bee bread and royal jelly, and every
snapshot must report those amounts and a numeric Pollinator Points total.

The route half is static: the reference arc earns Pollinator points by
buying it, grants no skill, sets no store or setting mid-run, and keeps the
config_overrides it had before PP-11 (the limits in the PP-11 section of
plans/now/pollination.md). Whether the route reaches Gyne rearing is
measured by `python tools/pacing_gates.py`, not here.
"""

from __future__ import annotations

import json
import re
import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "tools"))

from analyze_session import load_entries  # noqa: E402
from godot_compile_check import find_godot  # noqa: E402
from headless.profiles import SNAPSHOT_FIELDS, validate_diagnostics  # noqa: E402
from run_scenario import run_once  # noqa: E402

FIELDS = ("resources.stored_bee_bread", "resources.stored_royal_jelly", "resources.pollinator_points")
PROBES = ROOT / "scripts" / "headless" / "diagnostic_probes.gd"
ARC = ROOT / "test_scenarios" / "alpha_arc_test.json"
BEE_BREAD = 40.0
JELLY = 12.0

FIXTURE = {
    "cells": 6, "nectar_foragers": 0, "pollen_foragers": 0,
    "nurses": 0, "builders": 0, "miners": 0, "honey_makers": 0,
    "weather": False, "disease": False, "rival_hive": False, "winter": False,
    "random_seed": 1111,
    "diagnostics": {"profile": "custom", "snapshots": {
        "every_sim_seconds": 5, "fields": ["population.total"] + list(FIELDS)}},
    "actions": [
        {"do": "set_cell_contents", "cell": {"built_index": 1}, "resource": "bee_bread", "amount": BEE_BREAD},
        {"do": "set_cell_contents", "cell": {"built_index": 2}, "resource": "jelly", "amount": JELLY},
        {"do": "wait", "seconds": 20},
    ],
    "stop": {"when_actions_resolved": True, "max_days": 1},
}


class WhitelistsCarryTheFields(unittest.TestCase):
    def test_both_whitelists_carry_the_fields(self):
        source = PROBES.read_text(encoding="utf-8")
        listed = re.search(r"SNAPSHOT_FIELDS := \[([^\]]*)\]", source)
        self.assertIsNotNone(listed, "diagnostic_probes.gd has no SNAPSHOT_FIELDS list")
        for field in FIELDS:
            self.assertIn('"%s"' % field, listed.group(1))
            self.assertIn(field, SNAPSHOT_FIELDS)
            self.assertIn('"%s":' % field, source, "%s has no match arm" % field)

    def test_probe_reads_the_values_gyne_rearing_affordable_passes(self):
        source = PROBES.read_text(encoding="utf-8")
        self.assertIn('"stored_bee_bread", world.hive.total("bee_bread")', source)
        self.assertIn('"stored_royal_jelly", world.hive.total("jelly")', source)
        self.assertIn('"pollinator_points", pollinator_points(world)', source)
        self.assertIn("var points := pollinator_points(world)", source)

    def test_a_scenario_may_ask_for_them(self):
        selection = validate_diagnostics({"profile": "custom", "snapshots": {
            "every_sim_seconds": 10, "fields": list(FIELDS)}})
        self.assertEqual(list(FIELDS), selection["snapshots"]["fields"])

    def test_the_reference_arc_logs_them(self):
        fields = json.loads(ARC.read_text(encoding="utf-8"))["diagnostics"]["snapshots"]["fields"]
        for field in FIELDS:
            self.assertIn(field, fields)


class ARunLogsTheFields(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        godot_path = find_godot()
        if not godot_path:
            raise unittest.SkipTest("no Godot executable found -- this test needs a real headless boot")
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "pp11_route_snapshots.json"
            path.write_text(json.dumps(FIXTURE), encoding="utf-8")
            session_file = run_once(path, godot_path, timeout=300, fixed_fps=30)
        if session_file is None:
            raise AssertionError("scenario run produced no session log")
        entries = load_entries(session_file)
        cls.rejected = [e for e in entries if e.get("type") == "action" and e.get("result") == "rejected"]
        cls.snapshots = [e for e in entries if e.get("type") == "snapshot"]

    def test_the_fixture_ran_cleanly(self):
        self.assertEqual([], self.rejected, "a fixture action was rejected")
        self.assertTrue(self.snapshots, "the run logged no snapshots")

    def test_every_snapshot_logs_the_stores_and_points(self):
        for entry in self.snapshots:
            resources = entry.get("resources", {})
            self.assertAlmostEqual(BEE_BREAD, float(resources["stored_bee_bread"]), places=3)
            self.assertAlmostEqual(JELLY, float(resources["stored_royal_jelly"]), places=3)
            self.assertIsInstance(resources["pollinator_points"], (int, float))
            self.assertGreaterEqual(float(resources["pollinator_points"]), 0.0)


# The overrides alpha_arc_test.json carried before PP-11. A new entry, or a
# changed value, would redefine what the pacing rows measure.
ARC_OVERRIDES = {"energy_burn_rate": 0.17, "nectar_recharge_rate": 0.5,
                 "pollen_recharge_rate": 0.1, "winter_burn_factor": 0.15}


class RouteStaysInItsLimits(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.arc = json.loads(ARC.read_text(encoding="utf-8"))
        cls.verbs = [action["do"] for action in cls.arc["actions"]]

    def test_it_buys_pollinator_points(self):
        bought = {a.get("skill") for a in self.arc["actions"] if a["do"] == "buy_skill"}
        self.assertIn("skill.foraging.pollinator_points", bought)
        self.assertIn("skill.brood.royal_jelly", bought)

    def test_it_grants_nothing_and_injects_nothing(self):
        for verb in ("grant_skill", "set_config", "set_cell_contents"):
            self.assertNotIn(verb, self.verbs)
        self.assertNotIn("skill_grants", self.arc)

    def test_its_overrides_are_unchanged(self):
        self.assertEqual(ARC_OVERRIDES, self.arc["config_overrides"])


if __name__ == "__main__":
    unittest.main()
