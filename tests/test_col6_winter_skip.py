"""COL-6: winter is skipped and resolved in one step.

Runs test_scenarios/col6_winter_skip_test.json in a headless Godot: a short
3-day season, so winter arrives on day 4, and a 10-day winter, so spring
starts on day 14. The fixture itself is the stocked colony (a winter burn so
low the comb covers it many times over); the under-stocked colony is the same
fixture with winter's burn raised until the comb carries only a few bees, plus
a post-winter step that sets the lifespan to one day so every surviving worker
dies of old age and the log records how old it was.

From the session log, the stocked run shows winter crossed in one tick (the
clock jumps by winter's length between two snapshots a moment apart, nobody
dies and the population is unchanged) and the under-stocked run shows the
oldest workers gone, all at the same instant, the queen kept, and every
survivor younger than every worker the bill took. Also checks the source:
season.gd owns the bill and year_winter.gd's forecast reads it. Requires a
real Godot for the scenario tests.
"""

from __future__ import annotations

import json
import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "tools"))

from analyze_session import load_entries  # noqa: E402
from godot_compile_check import find_godot  # noqa: E402
from run_scenario import run_once  # noqa: E402

FIXTURE = ROOT / "test_scenarios" / "col6_winter_skip_test.json"
SEASON = ROOT / "scripts" / "season.gd"
YEAR_WINTER = ROOT / "scripts" / "year_winter.gd"
# Enough to leave the comb able to carry only a few of the eleven bees.
UNDERSTOCKED_BURN = 6.0


def function_body(source: str, name: str) -> str:
    """One GDScript function's text, up to the next top-level line."""
    body = source.replace("\r\n", "\n").split("\nfunc %s(" % name, 1)[1]
    lines = body.split("\n")
    kept = [lines[0]]
    for line in lines[1:]:
        if line and not line[0].isspace():
            break
        kept.append(line)
    return "\n".join(kept)


def _fixture() -> dict:
    return json.loads(FIXTURE.read_text(encoding="utf-8"))


def _run(scenario: dict, test: unittest.TestCase) -> list[dict]:
    godot_path = find_godot()
    if not godot_path:
        test.skipTest("no Godot executable found -- this test needs a real headless boot")
    with tempfile.TemporaryDirectory() as folder:
        path = Path(folder) / "col6_winter_skip_run.json"
        path.write_text(json.dumps(scenario, indent=2), encoding="utf-8")
        session_file = run_once(path, godot_path, timeout=240, fixed_fps=30)
    test.assertIsNotNone(session_file, "scenario run produced no session log")
    entries = load_entries(session_file)
    actions = [e for e in entries if e.get("type") == "action"]
    bad = [e for e in actions if e.get("result") != "accepted"]
    test.assertEqual(bad, [], "actions not accepted: %s" % bad)
    return entries


def _winter_jump(entries: list[dict], settings: dict) -> tuple[dict, dict]:
    """The two consecutive snapshots either side of the skipped winter."""
    winter_seconds = settings["winter_length_days"] * settings["seconds_per_day"]
    snapshots = [e for e in entries if e.get("type") == "snapshot"]
    for before, after in zip(snapshots, snapshots[1:]):
        if after["game_time"] - before["game_time"] >= winter_seconds:
            return before, after
    raise AssertionError("no snapshot pair spans winter's length")


class WinterSkipSourceTest(unittest.TestCase):
    def test_season_owns_the_bill_and_the_forecast_reads_it(self):
        season = SEASON.read_text(encoding="utf-8")
        bill = function_body(season, "winter_bill")
        for term in ("GameConfig.energy_burn_rate", "GameConfig.winter_burn_factor",
                     "GameConfig.seconds_per_day"):
            self.assertIn(term, bill)
        forecast = function_body(YEAR_WINTER.read_text(encoding="utf-8"), "_winter_forecast")
        self.assertIn("main.season.winter_bill(bees_count)", forecast)
        self.assertIn("main.season.winter_stores()", forecast)
        self.assertNotIn("winter_burn_factor", forecast)


class WinterSkipRunTest(unittest.TestCase):
    def test_stocked_colony_crosses_winter_in_one_tick(self):
        scenario = _fixture()
        settings = scenario["config_overrides"]
        entries = _run(scenario, self)
        before, after = _winter_jump(entries, settings)
        winter_days = settings["winter_length_days"]
        jumped = after["game_time"] - before["game_time"] - winter_days * settings["seconds_per_day"]
        # One snapshot interval of played time, not winter's two hundred seconds.
        self.assertLess(jumped, 2.0 * scenario["snapshot_seconds"] + 1.0)
        # Winter arrives on day 4; the snapshot before it may still be day 3.
        self.assertGreaterEqual(after["day"] - before["day"], winter_days)
        self.assertEqual(after["day"], settings["season_length_days"] + winter_days + 1)
        self.assertEqual(before["population"]["total"], after["population"]["total"])
        deaths = [e for e in entries if e.get("type") == "death"]
        self.assertEqual(deaths, [], "a stocked colony lost bees: %s" % deaths)
        played = [e for e in entries if e.get("type") == "snapshot"
                  and e.get("environment", {}).get("winter_here")]
        self.assertEqual(played, [], "winter was played, not skipped")
        summary = next(e for e in entries if e.get("type") == "summary")
        self.assertTrue(summary["queen_alive"])

    def test_understocked_colony_loses_its_oldest_workers_and_keeps_its_queen(self):
        scenario = _fixture()
        settings = scenario["config_overrides"]
        settings["winter_burn_factor"] = UNDERSTOCKED_BURN
        # After spring starts, every surviving worker dies of old age, so the
        # log records each survivor's age.
        scenario["actions"].insert(0, {"do": "set_config", "key": "bee_lifespan_days", "value": 1.0,
                                       "when": {"day_at_least": 15}})
        entries = _run(scenario, self)
        before, after = _winter_jump(entries, settings)
        deaths = [e for e in entries if e.get("type") == "death"]
        winter = [e for e in deaths if before["game_time"] < e["game_time"] <= after["game_time"]]
        self.assertTrue(winter, "an under-stocked colony lost nobody")
        self.assertEqual({e["cause"] for e in winter}, {"starvation"})
        self.assertEqual(len({e["game_time"] for e in winter}), 1, "winter's losses spread over time")
        self.assertFalse(any(e["is_queen"] or e["is_gyne"] for e in winter))
        self.assertEqual(after["population"]["total"], before["population"]["total"] - len(winter))
        self.assertGreaterEqual(after["population"]["total"], 2, "no worker came through")

        # Nobody aged through the skipped days: a survivor's age when winter
        # was paid is its age at death less the time played since.
        paid_at = winter[0]["game_time"]
        skipped = settings["winter_length_days"] * settings["seconds_per_day"]
        survivors = [e for e in deaths if e["game_time"] > paid_at and e["cause"] == "old age"]
        self.assertTrue(survivors, "no survivor died of old age after winter")
        survivor_ages = [e["stats"]["age_seconds"] - (e["game_time"] - paid_at - skipped)
                         for e in survivors]
        taken_ages = [e["stats"]["age_seconds"] for e in winter]
        self.assertLessEqual(max(survivor_ages), min(taken_ages) + 1.0,
                             "a younger worker went before an older one")
        summary = next(e for e in entries if e.get("type") == "summary")
        self.assertTrue(summary["queen_alive"])


if __name__ == "__main__":
    unittest.main()
