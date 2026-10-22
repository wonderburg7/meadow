"""CQ-S0: every golden save survives a load and a re-save unchanged.

Runs tests/save_roundtrip_test.gd in a headless Godot. It replays each golden
in tests/fixtures/saves/ onto a fresh world by the load route and the
in-place restore route (Challenge 2's checkpoint in place only), re-saves it in
the same frame and compares the two as canonical JSON. It also loads and
re-saves tests/fixtures/save_v1.json, save_v2.json and a v6 save made from the
early golden. Any difference that is not a named known difference fails.

A static check keeps each golden carrying what it was captured for, so a
recapture that misses (say) the brood cannot quietly weaken the harness.

What each golden is: early -- a Colony Run's lone queen on day 2; mid -- day
4 with brood, bodies on the floor, a restock order, a queued mine, bee bread
and Fermenting honey workers; winter -- the first spring after winter's bill
(winter is paid in one go, COL-6, so no save is ever made inside one);
challenge2 -- Challenge 2 at stage 2.7; orientation -- orientation flight on,
with a bee switched into Forager just before the save. The mid golden has no
drones yet: today only an unmated queen lays them, and a scenario cannot make
one. They wait for a follow-up gameplay slice that lets a mated queen lay drone
eggs (Dave, 22 Oct 2026: real queens choose to lay drone eggs); cq_s0_mid is
recaptured with drones once it lands. Until then tests/col9_drones_test.gd
round-trips the drone fields.

The goldens are captured on master by the matching
test_scenarios/cq_s0_<name>_capture.json, each ending in a save_run:

    python tools/run_scenario.py test_scenarios/cq_s0_mid_capture.json

then copying the run's save, scenario_saves/cq-s0-<name>.json in that run's
private user folder (.headless_user/<run id>/Godot/app_userdata/Meadow/), to
tests/fixtures/saves/cq_s0_<name>.json. A recapture is a deliberate change to
the fixtures, made when the save format changes; this test never captures.

Requires a real Godot executable -- the round trip skips where none is
installed.

Run with: python -m unittest tests.test_save_roundtrip
"""

from __future__ import annotations

import json
import subprocess
import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "tools"))

import godot_compile_check as gcc  # noqa: E402

TEST_SCRIPT = "res://tests/save_roundtrip_test.gd"
SAVES = ROOT / "tests" / "fixtures" / "saves"
FORMAT_VERSION = 7   # save_game.gd FORMAT_VERSION
ROLE_FORAGER = 0     # roles.gd FORAGER
TIMEOUT_SECONDS = 300


def _golden(name: str) -> dict:
    return json.loads((SAVES / ("cq_s0_%s.json" % name)).read_text(encoding="utf-8"))


class GoldenContentsTest(unittest.TestCase):
    """What each golden was captured to hold."""

    def test_every_golden_is_the_current_format(self):
        for name in ("early", "mid", "winter", "challenge2", "orientation"):
            with self.subTest(golden=name):
                self.assertEqual(_golden(name)["version"], FORMAT_VERSION)

    def test_early_is_a_colony_run_on_its_first_days(self):
        save = _golden("early")
        self.assertLessEqual(save["clock"]["day"], 3)
        self.assertTrue(any(b["queen"] for b in save["bees"]))

    def test_mid_holds_brood_bodies_queues_and_bee_bread(self):
        save = _golden("mid")
        self.assertTrue(any(c["content"] == "brood" for c in save["cells"]), "no brood")
        self.assertTrue(save["hive"]["bodies"], "no bodies on the floor")
        self.assertTrue(any(b["restock_targets"] for b in save["bees"]), "no restock order")
        self.assertTrue(any(b["mine_queue"] for b in save["bees"]), "no mine queue")
        self.assertTrue(any(c["content"] == "bee_bread" for c in save["cells"]), "no bee bread")

    def test_winter_is_saved_after_a_winter_was_paid(self):
        session = _golden("winter")["session"]
        self.assertGreater(session["winter_ends_day"], 0.0)
        self.assertGreater(session["winter_starts_day"], 0.0)

    def test_challenge2_is_a_challenge_2_save(self):
        self.assertEqual(_golden("challenge2")["starting_level"], 2)

    def test_orientation_has_a_fresh_forager_with_orientation_flight_on(self):
        save = _golden("orientation")
        self.assertTrue(save["settings"]["orientation_flight_on"])
        self.assertTrue(any(b["role"] == ROLE_FORAGER and not b["queen"] and b["trips_scored"] == 0
                            for b in save["bees"]))


class SaveRoundTripTest(unittest.TestCase):
    def test_every_golden_round_trips_by_both_routes(self):
        godot = gcc.find_godot()
        if not godot:
            self.skipTest("no Godot executable found -- this test needs a real boot")
        gcc.ensure_writable_user_dir()
        if not gcc.engine_can_boot(godot):
            self.skipTest("the installed Godot engine cannot initialise headlessly here")
        self.assertTrue(gcc.prepare_cache(godot), "could not prepare the Godot import cache")
        finished = subprocess.run(
            [godot, "--headless", "--disable-crash-handler", "--path", str(ROOT), "--script", TEST_SCRIPT],
            capture_output=True, text=True, encoding="utf-8", errors="replace", timeout=TIMEOUT_SECONDS,
        )
        output = gcc.combined_output(finished)
        report = "\n".join(line for line in output.splitlines() if line.startswith("CQS0"))
        self.assertEqual(gcc.failing_lines(output), [], "script errors:\n" + output[-3000:])
        self.assertFalse(any(line.startswith("CQS0 FAIL") for line in output.splitlines()), report)
        self.assertIn("CQS0 PASS", output, "the test script did not report a pass:\n" + output[-3000:])
        self.assertEqual(finished.returncode, 0, "Godot exited with code %d" % finished.returncode)
        for case in ("early:load", "early:in_place", "mid:load", "mid:in_place", "winter:load",
                     "winter:in_place", "challenge2:in_place", "orientation:load",
                     "orientation:in_place", "v1:resaved", "v2:resaved", "v6:load", "v6:resaved"):
            with self.subTest(case=case):
                self.assertIn("CQS0 OK %s" % case, report.splitlines(),
                          "no result for %s:\n%s" % (case, report))
        for label in ("v1", "v2", "v6"):
            self.assertIn("CQS0 RECORD %s:" % label, report)


if __name__ == "__main__":
    unittest.main()
